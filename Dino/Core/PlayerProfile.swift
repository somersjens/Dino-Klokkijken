import Foundation

/// Saved demonstrations may name a question type that no longer exists.
@propertyWrapper
struct KnownQuestionKinds: Codable, Equatable, Sendable {
    var wrappedValue: Set<ClockQuestionKind>
    init(wrappedValue: Set<ClockQuestionKind> = []) { self.wrappedValue = wrappedValue }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var values: Set<ClockQuestionKind> = []
        while !container.isAtEnd {
            let raw = try container.decode(String.self)
            if let kind = ClockQuestionKind(rawValue: raw) { values.insert(kind) }
        }
        wrappedValue = values
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for kind in wrappedValue.sorted(by: { $0.rawValue < $1.rawValue }) {
            try container.encode(kind.rawValue)
        }
    }
}

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
    // Optional additions keep existing version-one saves readable.
    var completedWorlds: Set<Int>?
    var perfectWorlds: Set<Int>?
    @KnownQuestionKinds var demonstratedInteractions: Set<ClockQuestionKind> = []
    // Optional for compatibility with existing version-one saves.
    var progressResetAt: Date?

    var normalLevelsComplete: Bool { normalLevelsComplete(in: 1) }
    func normalLevelsComplete(in worldID: Int) -> Bool {
        guard let world = DinoWorldCatalog.world(worldID) else { return false }
        return world.normalLevels.allSatisfy { record($0).stars >= 1 }
    }
    func perfectVictory(in worldID: Int) -> Bool {
        guard let world = DinoWorldCatalog.world(worldID) else { return false }
        return (worldID == 1 && perfectBossVictory) || perfectWorlds?.contains(worldID) == true || record(world.bossLevel).bestCorrect == 10
    }
    func worldComplete(_ worldID: Int) -> Bool {
        guard let world = DinoWorldCatalog.world(worldID) else { return false }
        return (worldID == 1 && worldOneComplete) || completedWorlds?.contains(worldID) == true ||
            perfectVictory(in: worldID) || (record(world.bossLevel).bestCorrect >= 5 && normalLevelsComplete(in: worldID))
    }
    func isWorldUnlocked(_ worldID: Int) -> Bool {
        DinoWorldCatalog.world(worldID) != nil && (worldID == 1 || worldComplete(worldID - 1))
    }
    var adventureComplete: Bool { DinoWorldCatalog.worlds.allSatisfy { worldComplete($0.id) } }
    var totalStars: Int { DinoLevelCatalog.levels.filter { !$0.isBoss }.reduce(0) { $0 + record($1.id).stars } }
    /// Highest finished level. Zero means nothing is finished yet.
    var dinoLevel: Int {
        DinoLevelCatalog.levels.last { $0.isBoss ? worldComplete($0.worldID) : record($0.id).stars >= 1 }?.id ?? 0
    }
    var nextAdventureLevel: Int? {
        guard !adventureComplete, let next = DinoLevelCatalog.level(dinoLevel + 1), isUnlocked(next.id) else { return nil }
        return next.id
    }
    /// The stone Dino stands on: the next unlocked level, or the last level once the adventure is finished.
    var mapLevel: Int { nextAdventureLevel ?? max(1, dinoLevel) }
    var unlockedLevels: [Int] { DinoLevelCatalog.levels.map(\.id).filter(isUnlocked) }
    func record(_ id: Int) -> LevelRecord { levels[String(id)] ?? LevelRecord() }

    func isUnlocked(_ id: Int) -> Bool {
        guard let level = DinoLevelCatalog.level(id), let world = DinoWorldCatalog.world(level.worldID),
              isWorldUnlocked(world.id) else { return false }
        return id == world.firstLevel || level.isBoss || perfectVictory(in: world.id) || record(id - 1).stars >= 1
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
                let victory = level.isBoss ? BossVictory.evaluate(correct: correct, normalLevelsComplete: normalLevelsComplete(in: level.worldID)) : .none
                let points = level.isBoss ? 1 + correct + (victory != .none ? 16 : 0) + (victory == .perfect ? 32 : 0)
                    : 1 + StarCalculator.stars(correct: correct) * 8 + correct
                mergeTiming(TimedLevelResult(resultPoints: points, seconds: attempt.seconds), levelID: levelID)
            }
        }
        var previous = record(levelID)
        previous.attempts += 1
        previous.bestCorrect = max(previous.bestCorrect, correct)
        if level.isBoss {
            let victory = BossVictory.evaluate(correct: correct, normalLevelsComplete: normalLevelsComplete(in: level.worldID))
            if level.worldID == 1 {
                bossResults.append(BossRecord(correct: correct, victory: victory, date: date))
                if victory != .none { worldOneComplete = true }
                if victory == .perfect { perfectBossVictory = true }
            } else {
                if victory != .none { completedWorlds = (completedWorlds ?? []).union([level.worldID]) }
                if victory == .perfect { perfectWorlds = (perfectWorlds ?? []).union([level.worldID]) }
            }
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
        completedWorlds = nil; perfectWorlds = nil
        demonstratedInteractions = []
        progressResetAt = date
    }
}
