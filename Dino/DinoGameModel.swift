import SwiftUI
import Combine

@MainActor
final class DinoPlayer: ObservableObject {
    @Published private(set) var profile: PlayerProfile
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
final class DinoSession: ObservableObject {
    let level: LevelConfiguration
    @Published private(set) var attempt: LevelAttempt
    @Published var inputHour = 12
    @Published var demonstration: ClockQuestionKind?
    @Published private(set) var result: DinoLevelResult?
    private let player: DinoPlayer
    private let answerFeedback: ((Bool) -> Void)?
    private let now: () -> TimeInterval
    private var questionStartedAt: TimeInterval

    init(level: LevelConfiguration, player: DinoPlayer, now: @escaping () -> TimeInterval = DinoQuestionTiming.now, answerFeedback: ((Bool) -> Void)? = nil) {
        self.now = now
        questionStartedAt = now()
        self.level = level
        self.player = player
        self.answerFeedback = answerFeedback
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
    var hasFeedback: Bool { attempt.submittedAnswer != nil }
    var correctFeedback: Bool { attempt.answers.last == true }

    func submit(_ answer: ClockTime) {
        guard demonstration == nil else { return }
        if let correct = attempt.submit(answer, elapsed: now() - questionStartedAt) { answerFeedback?(correct) }
    }

    func advance() {
        guard hasFeedback else { return }
        attempt.advance()
        if attempt.isComplete {
            guard result == nil else { return }
            result = player.finish(attempt)
        } else {
            inputHour = question.target.hour == 12 ? 1 : 12
            questionStartedAt = now()
        }
    }

    func dismissDemonstration() {
        if let kind = demonstration { player.markDemonstrated(kind) }
        demonstration = nil
    }
}
