import Foundation

struct LevelRecord: Codable, Equatable, Sendable {
    var stars = 0
    var bestCorrect = 0
    var attempts = 0
}

struct BossRecord: Codable, Equatable, Sendable {
    let correct: Int
    let victory: BossVictory
    let date: Date
}

struct PlayerProfile: Codable, Equatable, Sendable {
    var version = 1
    var name = ""
    var nameChangedAt: Date?
    var dinoAppearance: DinoAppearance?
    var onboardingComplete = false
    var clockTheme = ClockTheme.standard
    var levels: [String: LevelRecord] = [:]
    var bossResults: [BossRecord] = []
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
    mutating func recordCompletedAttempt(levelID: Int, correct: Int, date: Date = Date()) -> BossVictory {
        guard let level = DinoLevelCatalog.level(levelID), isUnlocked(levelID),
              (0...level.questionCount).contains(correct) else { return .none }
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

    static func sanitizedName(_ input: String) -> String {
        let scalars = input.unicodeScalars.filter {
            !CharacterSet.controlCharacters.contains($0) && $0.properties.generalCategory != .format
        }
        return String(String.UnicodeScalarView(scalars))
            .trimmingCharacters(in: .whitespacesAndNewlines).prefix(20).description
    }

    mutating func resetProgress(date: Date = Date()) {
        levels = [:]; bossResults = []
        perfectBossVictory = false; worldOneComplete = false
        demonstratedInteractions = []
        progressResetAt = date
    }
}
