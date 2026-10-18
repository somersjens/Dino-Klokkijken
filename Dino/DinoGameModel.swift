import SwiftUI
import Combine

@MainActor
final class DinoPlayer: ObservableObject {
    @Published private(set) var profile: PlayerProfile
    @Published private(set) var practiceRecords: [String: DinoPracticeRecord]
    @Published private(set) var hasSelectedLevel: Bool
    @Published private(set) var resetGeneration = UUID()
    let profileChanges = PassthroughSubject<PlayerProfile, Never>()
    private let store: DinoProgressStore
    var progressChanged: (() -> Void)?
    var progressReset: (() -> Void)?
    init(store: DinoProgressStore? = nil) {
        let resolved: DinoProgressStore
#if DEBUG
        // UI tests get a private defaults suite, never the player's real save.
        if let suite = ProcessInfo.processInfo.environment["DINO_TEST_SUITE"],
           let defaults = UserDefaults(suiteName: suite) {
            resolved = DinoProgressStore(defaults: defaults)
        } else { resolved = store ?? DinoProgressStore() }
#else
        resolved = store ?? DinoProgressStore()
#endif
        self.store = resolved
        var loadedHasSelectedLevel = resolved.hasSelectedLevel
        var loaded = resolved.load()
        if !loadedHasSelectedLevel && (loaded.dinoLevel > 0 || loaded.levels.values.contains { $0.attempts > 0 }) {
            resolved.markLevelSelected()
            loadedHasSelectedLevel = true
        }
        hasSelectedLevel = loadedHasSelectedLevel
        let previousTheme = loaded.clockTheme
        loaded.clockTheme = previousTheme.applyingFixedStyles()
        profile = loaded
        practiceRecords = resolved.loadPracticeRecords()
        if loaded.clockTheme != previousTheme { resolved.save(loaded) }
#if DEBUG
        if ProcessInfo.processInfo.environment["DINO_TEST_SUITE"] != nil,
           let raw = ProcessInfo.processInfo.environment["DINO_TEST_PRACTICE_ANSWERS"],
           let answered = Int(raw), answered >= 0 {
            practiceRecords[DinoPracticeRecord.key(time: .whole, question: .chooseAnalog)] =
                DinoPracticeRecord(bestStreak: 12, questionsAnswered: answered)
        }
        if ProcessInfo.processInfo.environment["DINO_TEST_SUITE"] != nil,
           let raw = ProcessInfo.processInfo.environment["DINO_TEST_COMPLETED_LEVEL"],
           let completedLevel = Int(raw), (1...100).contains(completedLevel) {
            // A complete, isolated progress fixture for scrolling from a late world.
            profile.onboardingComplete = true
            for level in DinoLevelCatalog.levels.prefix(completedLevel) {
                profile.recordCompletedAttempt(levelID: level.id, correct: level.questionCount)
            }
        }
        if ProcessInfo.processInfo.environment["DINO_TEST_SUITE"] != nil,
           let raw = ProcessInfo.processInfo.environment["DINO_TEST_COMPLETED_WORLDS"],
           let count = Int(raw), (0...10).contains(count) {
            // Isolated UI-test fixture only; ordinary saves never take this path.
            profile.onboardingComplete = true
            for world in DinoWorldCatalog.worlds.prefix(count) {
                profile.recordCompletedAttempt(levelID: world.bossLevel, correct: 10)
            }
        }
#endif
    }

    private func update(_ mutation: (inout PlayerProfile) -> Void) {
        var next = profile
        mutation(&next)
        guard next != profile else { return }
        profile = next
        store.save(next)
        profileChanges.send(next)
    }

    func setTheme(_ theme: ClockTheme) {
        var liveTheme = theme.applyingFixedStyles()
        if theme.analogColorsMatch {
            // The editor shows the draft; the game keeps its last visible hands.
            let previous = profile.clockTheme
            liveTheme.face = previous.face
            liveTheme.hourInk = previous.hourInk
            liveTheme.minuteInk = previous.minuteInk
            liveTheme.rimInk = previous.rimInk
            liveTheme.customFaceHex = previous.customFaceHex
            liveTheme.customHourHex = previous.customHourHex
            liveTheme.customMinuteHex = previous.customMinuteHex
            liveTheme.customRimHex = previous.customRimHex
        }
        if theme.digitalColorsMatch {
            // Keep the game's digits visible while an editor corrects matching colors.
            liveTheme.display = profile.clockTheme.display
            liveTheme.customDisplayHex = profile.clockTheme.customDisplayHex
            liveTheme.digitalInkHex = profile.clockTheme.digitalInkHex
        }
        guard liveTheme != profile.clockTheme else { return }
        update { $0.clockTheme = liveTheme }
    }
    func completeClockCustomization(theme: ClockTheme) {
        setTheme(theme.replacingUnreadableClocks())
    }
    func setDinoAppearance(_ appearance: DinoAppearance) {
        guard appearance != (profile.dinoAppearance ?? .standard) else { return }
        update { $0.dinoAppearance = appearance }
    }
    func completeOnboarding(theme: ClockTheme) {
        update { $0.clockTheme = theme.replacingUnreadableClocks().applyingFixedStyles(); $0.onboardingComplete = true }
    }
    func markDemonstrated(_ kind: ClockQuestionKind) { update { $0.demonstratedInteractions.insert(kind) } }
    var needsFirstLevelHint: Bool {
        !hasSelectedLevel && profile.dinoLevel == 0 && !profile.levels.values.contains { $0.attempts > 0 }
    }
    func markLevelSelected() {
        guard !hasSelectedLevel else { return }
        store.markLevelSelected()
        hasSelectedLevel = true
    }
    func finish(_ attempt: LevelAttempt) -> DinoLevelResult? {
        guard attempt.isComplete, let level = DinoLevelCatalog.level(attempt.levelID),
              attempt.answers.count == level.questionCount else { return nil }
        var victory = BossVictory.none
        update { victory = $0.recordCompletedAttempt(levelID: level.id, correct: attempt.correctCount, questionSeconds: attempt.questionSeconds) }
        progressChanged?()
        return DinoLevelResult(level: level, correct: attempt.correctCount,
                               stars: level.isBoss ? 0 : StarCalculator.stars(correct: attempt.correctCount),
                               victory: victory)
    }
    func resetProgress() {
        progressReset?()
        practiceRecords = [:]
        store.resetPracticeRecords()
        update { $0.resetProgress() }
    }
    func resetAllData(at date: Date = Date()) {
        progressReset?()
        store.removeAllData(resetAt: date)
        hasSelectedLevel = false
        var fresh = PlayerProfile()
        fresh.progressResetAt = date
        profile = fresh
        practiceRecords = [:]
        profileChanges.send(fresh)
        resetGeneration = UUID()
    }
    func mergeSharedProgress(_ progress: FriendProgress) {
        var next = profile
        next.mergeSharedProgress(progress)
        guard next != profile else { return }
        profile = next; store.save(next); profileChanges.send(next)
    }
    func mergeCloudProgress(_ progress: DinoCloudProgress) {
        var next = profile
        next.mergeCloudProgress(progress)
        guard next != profile else { return }
        if (next.progressResetAt ?? .distantPast) > (profile.progressResetAt ?? .distantPast) { progressReset?() }
        profile = next; store.save(next); profileChanges.send(next)
    }

    func practiceRecord(time: DinoPracticeTime, question: DinoPracticeQuestion) -> DinoPracticeRecord {
        practiceRecord(time: time, order: .specific(question))
    }

    func practiceRecord(time: DinoPracticeTime, order: DinoPracticeOrder) -> DinoPracticeRecord {
        practiceRecords[DinoPracticeRecord.key(time: time, order: order)] ?? DinoPracticeRecord()
    }

    @discardableResult
    func recordPracticeAnswer(configuration: DinoPracticeConfiguration, question: DinoPracticeQuestion,
                              correct: Bool) -> DinoPracticeRecord {
        let orderKey = DinoPracticeRecord.key(time: configuration.time, order: configuration.order)
        let questionKey = DinoPracticeRecord.key(time: configuration.time, question: question)
        var records = practiceRecords
        // Mixed modes keep their own continuous series and also credit the individual exercise.
        for key in Set([orderKey, questionKey]) {
            var record = records[key] ?? DinoPracticeRecord()
            record.questionsAnswered = min(Int.max - 1, record.questionsAnswered) + 1
            record.currentStreak = correct ? min(Int.max - 1, record.currentStreak) + 1 : 0
            record.bestStreak = max(record.bestStreak, record.currentStreak)
            records[key] = record
        }
        practiceRecords = records
        store.savePracticeRecords(records)
        return records[orderKey]!
    }
}

struct DinoLevelResult {
    let level: LevelConfiguration
    let correct: Int
    let stars: Int
    let victory: BossVictory
}

@MainActor
final class DinoSession: ObservableObject, Identifiable {
    nonisolated var id: ObjectIdentifier { ObjectIdentifier(self) }
    let level: LevelConfiguration
    let practice: DinoPracticeConfiguration?
    @Published private(set) var attempt: LevelAttempt
    @Published var inputHour = 12
    @Published var inputMinute = 0
    @Published var selectedOrder: [ClockTime] = []
    @Published var pairSelections: [Int: ClockTime] = [:]
    /// One entry per spoken-time slot. Nil means the player has not chosen yet.
    @Published var spokenChoices: [String?] = []
    @Published private(set) var rejectedResponses: Set<ClockAnswer> = []
    @Published private(set) var answerRevealed = false
    @Published private(set) var retryAnsweredCorrectly = false
    @Published private(set) var practiceAnswered = 0
    @Published private(set) var practiceCorrect = 0

    /// Displayed together for the current question; answers are saved immediately.
    struct PracticeProgress: Equatable {
        var streak = 0
        var bestStreak = 0
        var questionNumber = 1
    }

    @Published private(set) var practiceProgress = PracticeProgress()
    var practiceStreak: Int { practiceProgress.streak }
    var practiceBestStreak: Int { practiceProgress.bestStreak }
    var practiceQuestionNumber: Int { practiceProgress.questionNumber }

    @Published var demonstration: ClockQuestionKind?
    @Published private(set) var result: DinoLevelResult?
    private let player: DinoPlayer
    private let answerFeedback: ((Bool) -> Void)?
    private let now: () -> TimeInterval
    private var questionStartedAt: TimeInterval
    private var practiceGenerator: DinoPracticeGenerator?
    private let exampleMinuteStep: Int?

    init(level: LevelConfiguration, player: DinoPlayer, practice: DinoPracticeConfiguration? = nil, example: ClockQuestion? = nil, exampleMinuteStep: Int? = nil, language: String = "nl", now: @escaping () -> TimeInterval = DinoQuestionTiming.now, answerFeedback: ((Bool) -> Void)? = nil) {
        self.now = now
        questionStartedAt = now()
        self.level = level
        self.practice = practice
        self.exampleMinuteStep = exampleMinuteStep
        self.player = player
        self.answerFeedback = answerFeedback
        if let practice {
            var seed = UInt64.random(in: .min ... .max)
#if DEBUG
            if let raw = ProcessInfo.processInfo.environment["DINO_TEST_SEED"], let fixed = UInt64(raw) { seed = fixed }
#endif
            var generator = DinoPracticeGenerator(configuration: practice, seed: seed, language: language)
            attempt = LevelAttempt(levelID: 0, questions: [example ?? generator.next(index: 0)])
            practiceGenerator = example == nil ? generator : nil
            refreshPracticeProgress()
            resetInputs()
            return
        }
        let questions: [ClockQuestion]
#if DEBUG
        if let raw = ProcessInfo.processInfo.environment["DINO_TEST_SEED"], let seed = UInt64(raw) {
            var rng = SeededGenerator(seed: seed)
            questions = DinoQuestionGenerator.generate(level: level, attempt: player.profile.record(level.id).attempts, language: language, using: &rng)
        } else {
            var rng = SystemRandomNumberGenerator()
            questions = DinoQuestionGenerator.generate(level: level, attempt: player.profile.record(level.id).attempts, language: language, using: &rng)
        }
#else
        var rng = SystemRandomNumberGenerator()
        questions = DinoQuestionGenerator.generate(level: level, attempt: player.profile.record(level.id).attempts, language: language, using: &rng)
#endif
        attempt = LevelAttempt(levelID: level.id, questions: questions)
        resetInputs()
    }

    var question: ClockQuestion { attempt.current }
    var hasFeedback: Bool { attempt.submittedResponse != nil }
    var canExitWithoutConfirmation: Bool { practice != nil || question.id == 0 }
    var practiceQuestionType: DinoPracticeQuestion? { DinoPracticeQuestion(rawValue: question.kind.rawValue) }
    var correctFeedback: Bool { retryAnsweredCorrectly || attempt.answers.last == true }
    var canRetry: Bool {
        hasFeedback && !correctFeedback && !answerRevealed && question.kind.usesOptions && question.responses.count > 2
    }
    var showsCorrectResponse: Bool { hasFeedback && !canRetry }
    var shouldAutoAdvance: Bool { hasFeedback && attempt.answers.last == true }
    /// A correct answer is about to show another question with the same buttons.
    var retainsAnswerControls: Bool {
        guard shouldAutoAdvance, let next = upcomingKind else { return false }
        return next == question.kind && question.kind.reusesAnswerControls
    }
    /// Hide the buttons while feedback is on screen, unless the next question brings those same buttons back.
    var hidesAnswerControls: Bool { hasFeedback && !retainsAnswerControls }
    private var upcomingKind: ClockQuestionKind? {
        if let practiceGenerator { return practiceGenerator.upcomingKind(after: question.id) }
        let nextIndex = attempt.index + 1
        guard nextIndex < attempt.questions.count else { return nil }
        return attempt.questions[nextIndex].kind
    }
    var minuteStep: Int { exampleMinuteStep ?? practice?.time.minuteStep ?? level.minuteStep }
    var allowsMinutes: Bool { minuteStep < 60 }
    var inputTime: ClockTime { ClockTime(hour: inputHour, minute: inputMinute) }
    var instructionKey: String {
        if allowsMinutes && question.kind == .setDigital {
            return "dino.practice.\(question.kind.rawValue)"
        }
        return question.kind.instructionKey
    }

    func submit(_ answer: ClockTime) {
        submit(.time(answer))
    }
    func submit(_ answer: ClockAnswer) {
        guard demonstration == nil else { return }
        if hasFeedback {
            guard canRetry, question.responses.contains(answer), !rejectedResponses.contains(answer) else { return }
            let correct = AnswerValidator.isCorrect(answer, for: question)
            if correct { retryAnsweredCorrectly = true }
            else { rejectedResponses.insert(answer) }
            answerFeedback?(correct)
            return
        }
        if let correct = attempt.submit(answer, elapsed: now() - questionStartedAt) {
            if !correct { rejectedResponses.insert(answer) }
            if practice != nil { practiceAnswered += 1; if correct { practiceCorrect += 1 } }
            if practiceGenerator != nil, let practice, let type = practiceQuestionType {
                // Persist immediately, while the HUD keeps this question's
                // counters together until the next question is presented.
                player.recordPracticeAnswer(configuration: practice, question: type, correct: correct)
            }
            answerFeedback?(correct)
        }
    }

    func responseIsEnabled(_ answer: ClockAnswer) -> Bool {
        !hasFeedback || (canRetry && !rejectedResponses.contains(answer))
    }

    func showAnswer() {
        guard demonstration == nil, canRetry else { return }
        answerRevealed = true
    }

    func setInputTime(_ time: ClockTime) {
        if inputHour != time.hour { inputHour = time.hour }
        if inputMinute != time.minute { inputMinute = time.minute }
    }

    func adjustInputMinutes(by delta: Int) {
        setInputTime(inputTime.shiftingMinutes(by: delta))
    }

    func advance() {
        guard hasFeedback && !canRetry else { return }
        if var generator = practiceGenerator {
            attempt = LevelAttempt(levelID: 0, questions: [generator.next(index: question.id + 1)])
            practiceGenerator = generator
            refreshPracticeProgress()
            resetInputs()
            questionStartedAt = now()
            return
        }
        attempt.advance()
        if attempt.isComplete {
            guard result == nil else { return }
            result = player.finish(attempt)
        } else {
            resetInputs()
            questionStartedAt = now()
        }
    }

    private func resetInputs() {
        rejectedResponses = []; answerRevealed = false; retryAnsweredCorrectly = false
        if question.kind == .advanceAnalog, let start = question.relatedTimes.first {
            inputHour = start.hour % 12 == 0 ? 12 : start.hour % 12
            inputMinute = start.minute
        } else {
            inputHour = question.target.hour == 12 ? 1 : 12
            inputMinute = 0
        }
        selectedOrder = []; pairSelections = [:]; spokenChoices = []
    }

    func chooseSpoken(slot: Int, choiceID: String) {
        guard !hasFeedback, let count = question.spokenPrompt?.slots.count, (0..<count).contains(slot) else { return }
        var next = spokenChoices.count == count ? spokenChoices : Array(repeating: nil, count: count)
        guard next[slot] != choiceID else { return }
        next[slot] = choiceID
        spokenChoices = next
    }

    private func refreshPracticeProgress() {
        guard practiceGenerator != nil, let practice else { return }
        let record = player.practiceRecord(time: practice.time, order: practice.order)
        practiceProgress = PracticeProgress(streak: record.currentStreak, bestStreak: record.bestStreak,
                                            questionNumber: min(Int.max - 1, record.questionsAnswered) + 1)
    }

    func dismissDemonstration() {
        if practice == nil, let kind = demonstration { player.markDemonstrated(kind) }
        demonstration = nil
    }
}
