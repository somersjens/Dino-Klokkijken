import Foundation

struct LevelRecord: Codable, Equatable, Sendable {
    var stars = 0
    var bestCorrect = 0
    var attempts = 0
    var bestTimedResult: TimedLevelResult?
}

struct BossRecord: Codable, Equatable, Sendable {
    let correct: Int
    let victory: BossVictory
    let date: Date
}

struct PlayerProfile: Codable, Equatable, Sendable {
    var version = 1
    // Legacy save fields only; visible player identity always comes from Game Center.
    var name = ""
    var nameChangedAt: Date?
    var dinoAppearance: DinoAppearance?
    var onboardingComplete = false
    var clockTheme = ClockTheme.standard
    var levels: [String: LevelRecord] = [:]
    var bossResults: [BossRecord] = []
    var timedAttempts: [TimedLevelAttempt]?
    var perfectBossVictory = false
    var worldOneComplete = false
    var demonstratedInteractions: Set<ClockQuestionKind> = []
    // Optional for compatibility with existing version-one saves.
    var progressResetAt: Date?

    var normalLevelsComplete: Bool { (1...9).allSatisfy { record($0).stars >= 1 } }
    var totalStars: Int { (1...9).reduce(0) { $0 + record($1).stars } }
    /// Zero identifies the blank start point, never a playable level.
    var dinoLevel: Int { worldOneComplete ? 10 : (1...9).last { record($0).stars >= 1 } ?? 0 }
    var unlockedLevels: [Int] { (1...10).filter(isUnlocked) }
    func record(_ id: Int) -> LevelRecord { levels[String(id)] ?? LevelRecord() }

    func isUnlocked(_ id: Int) -> Bool {
        guard (1...10).contains(id) else { return false }
        return id == 1 || id == 10 || perfectBossVictory || record(id - 1).stars >= 1
    }

    @discardableResult
    mutating func recordCompletedAttempt(levelID: Int, correct: Int, date: Date = Date(), questionSeconds: [Int]? = nil) -> BossVictory {
        guard let level = DinoLevelCatalog.level(levelID), isUnlocked(levelID),
              (0...level.questionCount).contains(correct) else { return .none }
        defer {
            if let questionSeconds, questionSeconds.count == level.questionCount,
               questionSeconds.allSatisfy({ (1...60).contains($0) }) {
                let attempt = TimedLevelAttempt(levelID: levelID, correct: correct, questionSeconds: questionSeconds, date: date)
                timedAttempts = (timedAttempts ?? []) + [attempt]
                // This attempt's score, never combine a fast failed replay with a better old score.
                let victory = level.isBoss ? BossVictory.evaluate(correct: correct, normalLevelsComplete: normalLevelsComplete) : .none
                let points = level.isBoss ? 1 + correct + (victory != .none ? 16 : 0) + (victory == .perfect ? 32 : 0)
                    : 1 + StarCalculator.stars(correct: correct) * 8 + correct
                mergeTiming(TimedLevelResult(resultPoints: points, seconds: attempt.seconds), levelID: levelID)
            }
        }
        var previous = record(levelID)
        previous.attempts += 1
        previous.bestCorrect = max(previous.bestCorrect, correct)
        if level.isBoss {
            let victory = BossVictory.evaluate(correct: correct, normalLevelsComplete: normalLevelsComplete)
            bossResults.append(BossRecord(correct: correct, victory: victory, date: date))
            if victory != .none { worldOneComplete = true }
            if victory == .perfect { perfectBossVictory = true }
            levels[String(levelID)] = previous
            return victory
        }
        previous.stars = max(previous.stars, StarCalculator.stars(correct: correct))
        levels[String(levelID)] = previous
        return .none
    }

    mutating func mergeTiming(_ incoming: TimedLevelResult, levelID: Int) {
        guard incoming.isValid(levelID: levelID) else { return }
        var saved = record(levelID)
        if let existing = saved.bestTimedResult, existing.isValid(levelID: levelID), existing.rankedScore >= incoming.rankedScore { return }
        saved.bestTimedResult = incoming
        levels[String(levelID)] = saved
    }

    static func sanitizedName(_ input: String) -> String {
        let scalars = input.unicodeScalars.filter {
            !CharacterSet.controlCharacters.contains($0) && $0.properties.generalCategory != .format
        }
        return String(String.UnicodeScalarView(scalars))
            .trimmingCharacters(in: .whitespacesAndNewlines).prefix(20).description
    }

    mutating func resetProgress(date: Date = Date()) {
        levels = [:]; bossResults = []; timedAttempts = nil
        perfectBossVictory = false; worldOneComplete = false
        demonstratedInteractions = []
        progressResetAt = date
    }
}
