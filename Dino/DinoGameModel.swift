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
    private var learningProgress: [String: DinoLearningProgress]
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
        learningProgress = resolved.loadLearningProgress()
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
        if ProcessInfo.processInfo.environment["DINO_TEST_SUITE"] != nil,
           let raw = ProcessInfo.processInfo.environment["DINO_TEST_RESULT_LEVEL"], let id = Int(raw),
           let level = DinoLevelCatalog.level(id),
           let rawCorrect = ProcessInfo.processInfo.environment["DINO_TEST_RESULT_CORRECT"], let correct = Int(rawCorrect),
           (0...level.questionCount).contains(correct) {
            profile.onboardingComplete = true
            profile.recordCompletedAttempt(levelID: id, correct: correct)
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
                               stars: StarCalculator.stars(correct: attempt.correctCount, questionCount: level.questionCount),
                               victory: victory)
    }
    func resetProgress() {
        progressReset?()
        practiceRecords = [:]
        store.resetPracticeRecords()
        learningProgress = [:]
        store.resetLearningProgress()
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
        learningProgress = [:]
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

    func questionDifficulty(kind: ClockQuestionKind, time: DinoPracticeTime) -> DinoQuestionDifficulty {
        learningProgress[DinoLearningProgress.key(kind: kind, time: time)]?.difficulty ?? .introduction
    }

    /// Follow the authored lesson unless the combination is unseen or needs support after an error.
    func adventureDifficulty(for recipe: QuestionRecipe, in level: LevelConfiguration) -> DinoQuestionDifficulty {
        let family = level.time(for: recipe)
        let key = DinoLearningProgress.key(kind: recipe.kind, time: family)
        guard let progress = learningProgress[key] else { return .introduction }
        let planned = level.plannedDifficulty(for: recipe)
        return progress.recoveryTarget == nil ? planned
            : DinoQuestionDifficulty(rawValue: min(planned.rawValue, progress.difficulty.rawValue))!
    }

    func learningProgress(for question: ClockQuestion) -> DinoLearningProgress? {
        learningProgress[DinoLearningProgress.key(kind: question.kind, time: question.timeFamily)]
    }

    func recordLearningAnswer(question: ClockQuestion, correct: Bool) {
        let key = DinoLearningProgress.key(kind: question.kind, time: question.timeFamily)
        var progress = learningProgress[key] ?? DinoLearningProgress()
        progress.record(correct: correct, at: question.difficulty)
        learningProgress[key] = progress
        store.saveLearningProgress(learningProgress)
    }

    /// Puts one skill back to the progress saved before a day-part answer was scored.
    func restoreLearningProgress(_ progress: DinoLearningProgress?, for question: ClockQuestion) {
        let key = DinoLearningProgress.key(kind: question.kind, time: question.timeFamily)
        if let progress { learningProgress[key] = progress }
        else { learningProgress.removeValue(forKey: key) }
        store.saveLearningProgress(learningProgress)
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

    /// Puts practice records back to the values saved before a day-part answer was scored.
    func restorePracticeRecords(_ saved: [String: DinoPracticeRecord?]) {
        var records = practiceRecords
        for (key, record) in saved {
            if let record { records[key] = record }
            else { records.removeValue(forKey: key) }
        }
        practiceRecords = records
        store.savePracticeRecords(records)
    }
}

enum DinoAnswerRequirement: String {
    case chooseTile = "dino.answer.chooseTile"
    case changeTime = "dino.answer.changeTime"
}

struct DinoAnswerCheck: Equatable {
    let titleKey: String
    let enabled: Bool
    let answer: ClockAnswer
    var requirement: DinoAnswerRequirement? = nil
}

private struct DayPartScoreSnapshot {
    var learning: DinoLearningProgress?
    var practice: [String: DinoPracticeRecord?]
}

struct DinoLevelResult {
    let level: LevelConfiguration
    let correct: Int
    let stars: Int
    let victory: BossVictory

    var animationClip: DinoAnimation.Clip {
        if correct == level.questionCount { return .backflip }
        if stars == 2 { return .pirouette }
        if stars == 1 { return .openingJump }
        return .stumble
    }
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
    private let isExample: Bool
    private let language: String
    @Published private(set) var dayPartSchedule: DinoDayPartSchedule
    private var questionRNG = SeededGenerator(seed: 0)
    private var nextDifficultyLimit: DinoQuestionDifficulty?
    /// Progress from before this question's first, wrong day-part answer.
    private var dayPartScoreSnapshot: DayPartScoreSnapshot?
    /// A timetable can turn that answer correct after Next is already on screen, so it waits for a tap.
    private var manualAdvanceAfterRejudge = false
    private var initialInputTime = ClockTime(hour: 12)

    init(level: LevelConfiguration, player: DinoPlayer, practice: DinoPracticeConfiguration? = nil, example: ClockQuestion? = nil, exampleMinuteStep: Int? = nil, language: String = "nl", dayPartSchedule: DinoDayPartSchedule = .standard, now: @escaping () -> TimeInterval = DinoQuestionTiming.now, answerFeedback: ((Bool) -> Void)? = nil) {
        self.now = now
        questionStartedAt = now()
        self.level = level
        self.practice = practice
        self.exampleMinuteStep = exampleMinuteStep
        self.isExample = example != nil
        self.language = language
        self.dayPartSchedule = dayPartSchedule
        self.player = player
        self.answerFeedback = answerFeedback
        var seed = UInt64.random(in: .min ... .max)
#if DEBUG
        if let raw = ProcessInfo.processInfo.environment["DINO_TEST_SEED"], let fixed = UInt64(raw) { seed = fixed }
#endif
        if let practice {
            var generator = DinoPracticeGenerator(configuration: practice, seed: seed, language: language,
                                                   dayPartSchedule: dayPartSchedule)
            attempt = LevelAttempt(levelID: 0, questions: [example ?? generator.next(index: 0) {
                player.questionDifficulty(kind: $0, time: practice.time)
            }])
            practiceGenerator = example == nil ? generator : nil
            refreshPracticeProgress()
            resetInputs()
            return
        }
        let difficulties = level.recipes.reduce(into: [DinoQuestionSkill: DinoQuestionDifficulty]()) { result, recipe in
            result[level.skill(for: recipe)] = player.adventureDifficulty(for: recipe, in: level)
        }
        var rng = SeededGenerator(seed: seed)
        let questions = DinoQuestionGenerator.generate(level: level, attempt: player.profile.record(level.id).attempts,
            language: language, difficulties: difficulties, dayPartSchedule: dayPartSchedule, using: &rng)
        attempt = LevelAttempt(levelID: level.id, questions: questions)
        questionRNG = rng
        resetInputs()
    }

    var question: ClockQuestion { attempt.current }
    var hasFeedback: Bool { attempt.submittedResponse != nil }
    var canExitWithoutConfirmation: Bool { practice != nil || question.id == 0 }
    var practiceQuestionType: DinoPracticeQuestion? { DinoPracticeQuestion(rawValue: question.kind.rawValue) }
    /// Only the question on screen. Earlier correct answers stay in `attempt.answers`.
    var correctFeedback: Bool { hasFeedback && (retryAnsweredCorrectly || attempt.answers.last == true) }
    var canRetry: Bool {
        hasFeedback && !correctFeedback && !answerRevealed && question.kind.usesOptions && question.responses.count > 2
    }
    var showsCorrectResponse: Bool { hasFeedback && !canRetry }
    /// A hint may appear while other choices are still open.
    var missedFirstAnswer: Bool { hasFeedback && attempt.answers.last == false }
    /// The worked method starts only after that miss, once the question is closed:
    /// the right choice, Show answer, or every wrong choice ruled out.
    var showsWorkedExplanation: Bool { missedFirstAnswer && !canRetry }
    var shouldAutoAdvance: Bool { hasFeedback && attempt.answers.last == true && !manualAdvanceAfterRejudge }
    /// The first day-part answer was wrong and the question is closed, so its timetable can still be changed.
    var offersDayPartSettings: Bool {
        question.kind == .dayPart && hasFeedback && !canRetry && attempt.answers.last == false
    }
    /// A correct answer is about to show another question with the same buttons.
    var retainsAnswerControls: Bool {
        guard shouldAutoAdvance, let next = upcomingKind else { return false }
        let sameTime = practice != nil || level.time(for: level.recipe(at: attempt.index + 1)) == question.timeFamily
        return next == question.kind && sameTime && question.kind.reusesAnswerControls
    }
    /// Hide the buttons while feedback is on screen, unless the next question brings those same buttons back.
    var hidesAnswerControls: Bool { hasFeedback && !retainsAnswerControls }
    private var upcomingKind: ClockQuestionKind? {
        if let practiceGenerator { return practiceGenerator.upcomingKind(after: question.id) }
        let nextIndex = attempt.index + 1
        guard nextIndex < attempt.questions.count else { return nil }
        return attempt.questions[nextIndex].kind
    }
    var minuteStep: Int { exampleMinuteStep ?? practice?.time.minuteStep ?? question.timeFamily.minuteStep }
    var allowsMinutes: Bool { minuteStep < 60 }
    var inputTime: ClockTime { ClockTime(hour: inputHour, minute: inputMinute) }
    var instructionKey: String {
        if allowsMinutes && question.kind == .setDigital {
            return "dino.practice.\(question.kind.rawValue)"
        }
        return question.kind.instructionKey
    }

    /// The sticky check for questions the player builds, rather than picking from options.
    var answerCheck: DinoAnswerCheck? {
        guard !hidesAnswerControls else { return nil }
        switch question.kind {
        case .setAnalog, .setDigital, .advanceAnalog:
            let answer = ClockAnswer.time(inputTime)
            return DinoAnswerCheck(titleKey: "dino.clock.check", enabled: true, answer: answer,
                                   requirement: submissionRequirement(for: answer))
        case .match:
            let pairs = question.relatedTimes.indices.compactMap { pairSelections[$0] }
            return DinoAnswerCheck(titleKey: "dino.check.connections", enabled: pairs.count == question.relatedTimes.count, answer: .pairs(pairs))
        case .sortTimes:
            return DinoAnswerCheck(titleKey: "dino.check.order", enabled: selectedOrder.count == question.options.count, answer: .ordering(selectedOrder))
        case .sayTime:
            guard let prompt = question.spokenPrompt else { return nil }
            let ids = prompt.slots.indices.map { index -> String in
                guard spokenChoices.indices.contains(index) else { return SpokenTimeChoice.emptyID }
                return spokenChoices[index] ?? SpokenTimeChoice.emptyID
            }
            let answer = ClockAnswer.spoken(SpokenTimeAnswer(choiceIDs: ids))
            return DinoAnswerCheck(titleKey: "dino.check.answer", enabled: true, answer: answer,
                                   requirement: submissionRequirement(for: answer))
        default:
            return nil
        }
    }

    /// An untouched answer is a reminder, never an incorrect attempt or a saved score.
    private func submissionRequirement(for answer: ClockAnswer) -> DinoAnswerRequirement? {
        switch question.kind {
        case .setAnalog, .setDigital, .advanceAnalog:
            guard case .time(let time) = answer else { return .changeTime }
            let unchanged = time.hour % 12 == initialInputTime.hour % 12 && time.minute == initialInputTime.minute
            return unchanged ? .changeTime : nil
        case .sayTime:
            guard case .spoken(let spoken) = answer, let prompt = question.spokenPrompt else { return .chooseTile }
            let hasTile = prompt.slots.enumerated().contains { index, slot in
                spoken.choiceIDs.indices.contains(index) && slot.choices.contains {
                    $0.id != SpokenTimeChoice.emptyID && $0.id == spoken.choiceIDs[index]
                }
            }
            return hasTile ? nil : .chooseTile
        default:
            return nil
        }
    }

    func submit(_ answer: ClockTime) {
        submit(.time(answer))
    }
    func submit(_ answer: ClockAnswer) {
        guard demonstration == nil else { return }
        guard hasFeedback || submissionRequirement(for: answer) == nil else { return }
        if hasFeedback {
            guard canRetry, question.responses.contains(answer), !rejectedResponses.contains(answer) else { return }
            let correct = AnswerValidator.isCorrect(answer, for: question)
            if correct { retryAnsweredCorrectly = true }
            else {
                rejectedResponses.insert(answer)
                // The last remaining choice is the answer, so it needs no extra tap.
                let remaining = question.responses.filter { !rejectedResponses.contains($0) }
                if remaining.count == 1, let last = remaining.first, AnswerValidator.isCorrect(last, for: question) {
                    answerRevealed = true
                }
            }
            answerFeedback?(correct)
            return
        }
        if let correct = attempt.submit(answer, elapsed: now() - questionStartedAt) {
            if question.kind == .dayPart && !correct { dayPartScoreSnapshot = captureDayPartSnapshot() }
            if !correct {
                rejectedResponses.insert(answer)
                nextDifficultyLimit = question.difficulty.easier
            }
            if !isExample { player.recordLearningAnswer(question: question, correct: correct) }
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

    /// Scores the first day-part answer again after the timetable changes. Later questions use the new hours too.
    func rejudgeDayPart(using schedule: DinoDayPartSchedule) {
        guard question.kind == .dayPart, hasFeedback else { return }
        if dayPartSchedule != schedule {
            dayPartSchedule = schedule
            if var generator = practiceGenerator {
                generator.applyDayPartSchedule(schedule)
                practiceGenerator = generator
            }
        }
        guard let revision = attempt.reviseDayPartAnswer(schedule: schedule),
              !revision.wasCorrect, revision.nowCorrect, let snapshot = dayPartScoreSnapshot else { return }
        dayPartScoreSnapshot = nil
        if !isExample {
            player.restoreLearningProgress(snapshot.learning, for: question)
            player.recordLearningAnswer(question: question, correct: true)
            if let practice, let type = practiceQuestionType {
                player.restorePracticeRecords(snapshot.practice)
                player.recordPracticeAnswer(configuration: practice, question: type, correct: true)
            }
        }
        if practice != nil { practiceCorrect += 1 }
        if let submitted = attempt.submittedResponse { rejectedResponses.remove(submitted) }
        nextDifficultyLimit = nil
        manualAdvanceAfterRejudge = true
        answerFeedback?(true)
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
            let limit = nextDifficultyLimit
            let time = generator.configuration.time
            let next = generator.next(index: question.id + 1) { kind in
                let learned = player.questionDifficulty(kind: kind, time: time)
                return DinoQuestionDifficulty(rawValue: min(learned.rawValue, limit?.rawValue ?? 2))!
            }
            attempt = LevelAttempt(levelID: 0, questions: [next])
            nextDifficultyLimit = nil
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
            let recipe = level.recipe(at: attempt.index)
            let learned = player.adventureDifficulty(for: recipe, in: level)
            let difficulty = DinoQuestionDifficulty(rawValue: min(learned.rawValue, nextDifficultyLimit?.rawValue ?? 2))!
            let previous = attempt.questions[attempt.index - 1]
            if difficulty != question.difficulty || question.target == previous.target {
                let usedHours = Set(attempt.questions.enumerated().filter { $0.offset != attempt.index }.map { $0.element.target.hour })
                let replacement = DinoQuestionGenerator.generateQuestion(level: level,
                    recipe: recipe, index: question.id,
                    attempt: player.profile.record(level.id).attempts, difficulty: difficulty,
                    previousTarget: previous.target, usedHours: usedHours,
                    optionPosition: (previous.options.firstIndex(of: previous.target) ?? 0) + 1,
                    language: language, dayPartSchedule: dayPartSchedule,
                    recentQuestions: Array(attempt.questions.prefix(attempt.index)).filter {
                        $0.kind == recipe.kind && $0.timeFamily == level.time(for: recipe)
                    }, using: &questionRNG)
                attempt.replaceCurrent(with: replacement)
            }
            nextDifficultyLimit = nil
            resetInputs()
            questionStartedAt = now()
        }
    }

    private func resetInputs() {
        rejectedResponses = []; answerRevealed = false; retryAnsweredCorrectly = false
        dayPartScoreSnapshot = nil
        manualAdvanceAfterRejudge = false
        if question.kind == .advanceAnalog, let start = question.relatedTimes.first {
            inputHour = start.hour % 12 == 0 ? 12 : start.hour % 12
            inputMinute = start.minute
        } else {
            inputHour = question.target.hour % 12 == 0 ? 1 : 12
            inputMinute = 0
        }
        initialInputTime = inputTime
        selectedOrder = []; pairSelections = [:]; spokenChoices = []
    }

    func chooseSpoken(slot: Int, choiceID: String) {
        guard !hasFeedback, let count = question.spokenPrompt?.slots.count, (0..<count).contains(slot) else { return }
        var next = spokenChoices.count == count ? spokenChoices : Array(repeating: nil, count: count)
        next[slot] = next[slot] == choiceID ? nil : choiceID
        spokenChoices = next
    }

    private func captureDayPartSnapshot() -> DayPartScoreSnapshot {
        var practice: [String: DinoPracticeRecord?] = [:]
        if let practiceConfiguration = self.practice, let type = practiceQuestionType {
            let orderKey = DinoPracticeRecord.key(time: practiceConfiguration.time, order: practiceConfiguration.order)
            let questionKey = DinoPracticeRecord.key(time: practiceConfiguration.time, question: type)
            for key in Set([orderKey, questionKey]) {
                practice[key] = player.practiceRecords[key]
            }
        }
        return DayPartScoreSnapshot(learning: player.learningProgress(for: question), practice: practice)
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
