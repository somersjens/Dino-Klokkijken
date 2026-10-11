import SwiftUI
import Combine

@MainActor
final class DinoPlayer: ObservableObject {
    @Published private(set) var profile: PlayerProfile
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
    }

    @discardableResult
    func setName(_ name: String, date: Date = Date()) -> Bool {
        guard case .success(let valid) = DinoNameValidator.validated(name) else { return false }
        if valid == profile.name { return true }
        guard profile.nameChangedAt.map({ date.timeIntervalSince($0) >= 86_400 }) ?? true else { return false }
        update { $0.name = valid; $0.nameChangedAt = date }
        return true
    }
    func setTheme(_ theme: ClockTheme) { update { $0.clockTheme = theme } }
    func completeOnboarding(theme: ClockTheme) {
        guard !profile.name.isEmpty else { return }
        update { $0.clockTheme = theme; $0.onboardingComplete = true }
    }
    func markDemonstrated(_ kind: ClockQuestionKind) { update { $0.demonstratedInteractions.insert(kind) } }
    func finish(_ attempt: LevelAttempt) -> DinoLevelResult? {
        guard attempt.isComplete, let level = DinoLevelCatalog.level(attempt.levelID),
              attempt.answers.count == level.questionCount else { return nil }
        var victory = BossVictory.none
        update { victory = $0.recordCompletedAttempt(levelID: level.id, correct: attempt.correctCount) }
        progressChanged?()
        return DinoLevelResult(level: level, correct: attempt.correctCount,
                               stars: level.isBoss ? 0 : StarCalculator.stars(correct: attempt.correctCount),
                               victory: victory)
    }
    func resetProgress() {
        progressReset?()
        update {
            let name = $0.name
            let theme = $0.clockTheme
            let onboarded = $0.onboardingComplete
            let nameChangedAt = $0.nameChangedAt
            $0 = PlayerProfile()
            $0.name = name; $0.clockTheme = theme; $0.onboardingComplete = onboarded
            $0.nameChangedAt = nameChangedAt
        }
    }
    func mergeSharedProgress(_ progress: FriendProgress) {
        var next = profile
        next.mergeSharedProgress(progress)
        guard next != profile else { return }
        profile = next; store.save(next)
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

    init(level: LevelConfiguration, player: DinoPlayer) {
        self.level = level
        self.player = player
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
        introduceIfNeeded()
    }

    var question: ClockQuestion { attempt.current }
    var hasFeedback: Bool { attempt.submittedAnswer != nil }
    var correctFeedback: Bool { attempt.answers.last == true }

    func submit(_ answer: ClockTime) {
        guard demonstration == nil else { return }
        _ = attempt.submit(answer)
    }

    func advance() {
        guard hasFeedback else { return }
        attempt.advance()
        if attempt.isComplete {
            guard result == nil else { return }
            result = player.finish(attempt)
        } else {
            inputHour = question.target.hour == 12 ? 1 : 12
            introduceIfNeeded()
        }
    }

    func dismissDemonstration() {
        if let kind = demonstration { player.markDemonstrated(kind) }
        demonstration = nil
    }

    private func introduceIfNeeded() {
        let kind = question.kind
        if !player.profile.demonstratedInteractions.contains(kind) { demonstration = kind }
    }
}
