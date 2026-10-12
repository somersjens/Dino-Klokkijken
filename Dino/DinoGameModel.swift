import SwiftUI
import Combine

@MainActor
final class DinoPlayer: ObservableObject {
    @Published private(set) var profile: PlayerProfile
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
        profile = resolved.load()
    }

    private func update(_ mutation: (inout PlayerProfile) -> Void) {
        var next = profile
        mutation(&next)
        profile = next
        store.save(next)
        profileChanges.send(next)
    }

    func setTheme(_ theme: ClockTheme) { update { $0.clockTheme = theme } }
    func setDinoAppearance(_ appearance: DinoAppearance) {
        guard appearance != (profile.dinoAppearance ?? .standard) else { return }
        update { $0.dinoAppearance = appearance }
    }
    func completeOnboarding(theme: ClockTheme) {
        update { $0.clockTheme = theme; $0.onboardingComplete = true }
    }
    func markDemonstrated(_ kind: ClockQuestionKind) { update { $0.demonstratedInteractions.insert(kind) } }
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
        update { $0.resetProgress() }
    }
    func resetAllData(at date: Date = Date()) {
        progressReset?()
        store.removeAllData(resetAt: date)
        var fresh = PlayerProfile()
        fresh.progressResetAt = date
        profile = fresh
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
    @Published private(set) var practiceAnswered = 0
    @Published private(set) var practiceCorrect = 0
    @Published var demonstration: ClockQuestionKind?
    @Published private(set) var result: DinoLevelResult?
    private let player: DinoPlayer
    private let answerFeedback: ((Bool) -> Void)?
    private let now: () -> TimeInterval
    private var questionStartedAt: TimeInterval
    private var practiceGenerator: DinoPracticeGenerator?

    init(level: LevelConfiguration, player: DinoPlayer, practice: DinoPracticeConfiguration? = nil, example: ClockQuestion? = nil, now: @escaping () -> TimeInterval = DinoQuestionTiming.now, answerFeedback: ((Bool) -> Void)? = nil) {
        self.now = now
        questionStartedAt = now()
        self.level = level
        self.practice = practice
        self.player = player
        self.answerFeedback = answerFeedback
        if let practice {
            var seed = UInt64.random(in: .min ... .max)
#if DEBUG
            if let raw = ProcessInfo.processInfo.environment["DINO_TEST_SEED"], let fixed = UInt64(raw) { seed = fixed }
#endif
            var generator = DinoPracticeGenerator(configuration: practice, seed: seed)
            attempt = LevelAttempt(levelID: 0, questions: [example ?? generator.next(index: 0)])
            practiceGenerator = example == nil ? generator : nil
            resetInputs()
            return
        }
        let questions: [ClockQuestion]
#if DEBUG
        if let raw = ProcessInfo.processInfo.environment["DINO_TEST_SEED"], let seed = UInt64(raw) {
            var rng = SeededGenerator(seed: seed)
            questions = DinoQuestionGenerator.generate(level: level, attempt: player.profile.record(level.id).attempts, using: &rng)
        } else {
            var rng = SystemRandomNumberGenerator()
            questions = DinoQuestionGenerator.generate(level: level, attempt: player.profile.record(level.id).attempts, using: &rng)
        }
#else
        var rng = SystemRandomNumberGenerator()
        questions = DinoQuestionGenerator.generate(level: level, attempt: player.profile.record(level.id).attempts, using: &rng)
#endif
        attempt = LevelAttempt(levelID: level.id, questions: questions)
    }

    var question: ClockQuestion { attempt.current }
    var hasFeedback: Bool { attempt.submittedResponse != nil }
    var canExitWithoutConfirmation: Bool { question.id == 0 }
    var correctFeedback: Bool { attempt.answers.last == true }
    var minuteStep: Int { practice?.time.minuteStep ?? 60 }
    var allowsMinutes: Bool { minuteStep < 60 }
    var inputTime: ClockTime { ClockTime(hour: inputHour, minute: inputMinute) }
    var instructionKey: String {
        if allowsMinutes && (question.kind == .setAnalog || question.kind == .setDigital) {
            return "dino.practice.\(question.kind.rawValue)"
        }
        return question.kind.instructionKey
    }

    func submit(_ answer: ClockTime) {
        submit(.time(answer))
    }
    func submit(_ answer: ClockAnswer) {
        guard demonstration == nil else { return }
        if let correct = attempt.submit(answer, elapsed: now() - questionStartedAt) {
            if practice != nil { practiceAnswered += 1; if correct { practiceCorrect += 1 } }
            answerFeedback?(correct)
        }
    }

    func advance() {
        guard hasFeedback else { return }
        if var generator = practiceGenerator {
            attempt = LevelAttempt(levelID: 0, questions: [generator.next(index: question.id + 1)])
            practiceGenerator = generator
            resetInputs()
            questionStartedAt = now()
            return
        }
        attempt.advance()
        if attempt.isComplete {
            guard result == nil else { return }
            result = player.finish(attempt)
        } else {
            inputHour = question.target.hour == 12 ? 1 : 12
            questionStartedAt = now()
        }
    }

    private func resetInputs() {
        if question.kind == .advanceAnalog, let start = question.relatedTimes.first {
            inputHour = start.hour % 12 == 0 ? 12 : start.hour % 12
            inputMinute = start.minute
        } else {
            inputHour = question.target.hour == 12 ? 1 : 12
            inputMinute = 0
        }
        selectedOrder = []; pairSelections = [:]
    }

    func dismissDemonstration() {
        if practice == nil, let kind = demonstration { player.markDemonstrated(kind) }
        demonstration = nil
    }
}
