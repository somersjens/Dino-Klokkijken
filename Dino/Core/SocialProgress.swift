import Foundation

/// Two records preserve four full 24-bit RGB colors without quantization.
/// Matching revisions are required; the first record is the commit marker.
struct SharedDinoAppearance: Equatable, Sendable {
    static let primaryID = "dino.appearance.primary.v1"
    static let secondaryID = "dino.appearance.secondary.v1"
    static let leaderboardIDs = [primaryID, secondaryID]
    private static let schema = 1 << 48
    let revision: Int
    let appearance: DinoAppearance

    var primaryContext: Int { Self.schema | Int(appearance.bandana) << 24 | Int(appearance.spikes) }
    var secondaryContext: Int { Self.schema | Int(appearance.body) << 24 | Int(appearance.belly) }

    init(revision: Int, appearance: DinoAppearance) {
        self.revision = revision
        var clean = appearance
        for part in DinoAppearance.Part.allCases { clean[part] = appearance[part] }
        self.appearance = clean
    }

    init?(values: [String: LeaderboardValue]) {
        guard let first = values[Self.primaryID], let second = values[Self.secondaryID],
              first.score > 0, first.score < Int.max, first.score == second.score,
              first.context >> 48 == 1, second.context >> 48 == 1 else { return nil }
        revision = first.score
        appearance = DinoAppearance(bandana: UInt32((first.context >> 24) & 0xFFFFFF),
                                    spikes: UInt32(first.context & 0xFFFFFF),
                                    body: UInt32((second.context >> 24) & 0xFFFFFF),
                                    belly: UInt32(second.context & 0xFFFFFF))
    }
}

struct DinoAppearancePublication: Codable, Equatable {
    var appearance: DinoAppearance
    var revision: Int = 0
    var pending = false
}

struct AchievementProgress: Equatable, Sendable {
    let identifier: String
    let percentComplete: Double
}

enum DinoAchievements {
    static let starMilestones = [50, 100, 150, 200, 250, 300]
    static func stars(_ count: Int) -> String { "dino.achievement.stars.\(count).v1" }
    static func boss(_ worldID: Int) -> String { "dino.achievement.boss.\(worldID).v1" }

    static func progress(_ profile: PlayerProfile, includeScores: Bool) -> [AchievementProgress] {
        var results: [AchievementProgress] = []
        if includeScores && profile.totalStars > 0 {
            results = starMilestones.map {
                AchievementProgress(identifier: stars($0),
                                    percentComplete: min(100, Double(profile.totalStars) * 100 / Double($0)))
            }
        }
        results += DinoWorldCatalog.worlds.filter { profile.worldComplete($0.id) }.map {
            AchievementProgress(identifier: boss($0.id), percentComplete: 100)
        }
        return results
    }
}

struct ScoreSharingChoice: Equatable, Sendable {
    var revision: Int
    var showsScores: Bool
    var pending: Bool
}

/// A newer preference always wins over progress submitted under an older preference.
/// At equal revisions, hiding scores wins over showing them.
struct SharedScoreVisibility: Equatable, Sendable {
    static let leaderboardID = "dino.progress.visibility.v1"
    static let context = 1
    let revision: Int
    let levelID: Int
    let showsScores: Bool
    let allComplete: Bool

    var score: Int {
        revision * 1_024 + (showsScores ? 0 : 512) + levelID * 2 + (allComplete ? 1 : 0)
    }

    init(revision: Int, profile: PlayerProfile, showsScores: Bool) {
        self.revision = revision
        levelID = profile.mapLevel
        self.showsScores = showsScores
        allComplete = profile.adventureComplete
    }

    init?(score: Int, context: Int) {
        guard context == Self.context, score > 0 else { return nil }
        let payload = score % 1_024
        let level = (payload % 512) / 2
        guard score / 1_024 > 0, score / 1_024 < (Int.max - 1_023) / 1_024,
              DinoLevelCatalog.level(level) != nil else { return nil }
        revision = score / 1_024
        levelID = level
        showsScores = payload < 512
        allComplete = payload % 2 == 1
        guard !allComplete || level == DinoLevelCatalog.levels.last?.id else { return nil }
    }
}

/// A projection of the existing save, not a second source of player progress.
struct SharedLevelResult: Equatable, Sendable {
    let levelID: Int
    let attempted: Bool
    let stars: Int
    let bestCorrect: Int
    let bossComplete: Bool
    let perfectBoss: Bool
    var seconds: Int? = nil
    var resultPoints: Int {
        levelID.isMultiple(of: 10)
            ? DinoLeaderboards.bossScore(correct: bestCorrect, stars: stars, complete: bossComplete, perfect: perfectBoss)
            : 1 + stars * 8 + bestCorrect
    }
    var completed: Bool { levelID.isMultiple(of: 10) ? bossComplete : stars > 0 }

    /// Visible level results rank by stars, then measured time. Missing times come last.
    func ranking(comparedTo other: SharedLevelResult) -> ComparisonResult {
        if stars != other.stars { return stars > other.stars ? .orderedAscending : .orderedDescending }
        let time = seconds ?? Int.max, otherTime = other.seconds ?? Int.max
        if time != otherTime { return time < otherTime ? .orderedAscending : .orderedDescending }
        return .orderedSame
    }
}

enum DinoLeaderboards {
    static let highestLevel = "dino.progress.highest.v1"
    static let totalStars = "dino.progress.stars.v1"
    static let context = 1
    static func level(_ id: Int) -> String { "dino.level.\(id).result.v1" }
    static func timedLevel(_ id: Int) -> String { "dino.level.\(id).timed.v1" }
    // Keep the already configured Game Center boards. New worlds sync through iCloud.
    static var publishedLevels: [LevelConfiguration] { DinoLevelCatalog.levels.filter { $0.worldID == 1 } }
    static var timedIDs: [String] { publishedLevels.map { timedLevel($0.id) } }
    static var allIDs: [String] { publishedLevels.map { level($0.id) } + [highestLevel, totalStars] }

    /// Integer ordering preserves both best stars and best correct answers.
    /// Zero explicitly means no completed attempt was present in the real save.
    /// Missing entries and unknown schema versions must never be decoded as zero.
    static func score(profile: PlayerProfile, levelID: Int) -> Int {
        let record = profile.record(levelID)
        guard let level = DinoLevelCatalog.level(levelID) else { return 0 }
        guard record.attempts > 0 || record.stars > 0 || (level.isBoss && profile.worldComplete(level.worldID)) else { return 0 }
        if level.isBoss {
            let stars = StarCalculator.stars(correct: record.bestCorrect, questionCount: level.questionCount)
            return bossScore(correct: record.bestCorrect, stars: stars,
                             complete: profile.worldComplete(level.worldID),
                             perfect: profile.perfectVictory(in: level.worldID))
        }
        return 1 + record.stars * 8 + record.bestCorrect
    }

    /// Boss scores keep the existing correct/victory bits and add the star count above them.
    static func bossScore(correct: Int, stars: Int, complete: Bool, perfect: Bool) -> Int {
        1 + correct + (complete ? 16 : 0) + (perfect ? 32 : 0) + stars * 64
    }

    static func decode(levelID: Int, score: Int, context: Int) -> SharedLevelResult? {
        guard DinoLevelCatalog.level(levelID) != nil, context == Self.context, score >= 0 else { return nil }
        if score == 0 {
            return SharedLevelResult(levelID: levelID, attempted: false, stars: 0, bestCorrect: 0, bossComplete: false, perfectBoss: false)
        }
        let value = score - 1
        if levelID.isMultiple(of: 10) {
            guard value <= 10 + 16 + 32 + 3 * 64 else { return nil }
            let correct = value & 15, complete = value & 16 != 0, perfect = value & 32 != 0
            guard correct <= 10, !perfect || (complete && correct == 10), !complete || correct >= 5,
                  correct != 10 || perfect else { return nil }
            let stars = StarCalculator.stars(correct: correct, questionCount: 10)
            return SharedLevelResult(levelID: levelID, attempted: true, stars: stars, bestCorrect: correct, bossComplete: complete, perfectBoss: perfect)
        }
        let stars = value / 8, correct = value % 8
        guard correct <= 5, stars <= 3, stars == StarCalculator.stars(correct: correct) else { return nil }
        return SharedLevelResult(levelID: levelID, attempted: true, stars: stars, bestCorrect: correct, bossComplete: false, perfectBoss: false)
    }

    static func timedScore(profile: PlayerProfile, levelID: Int) -> Int? {
        guard let timing = profile.record(levelID).bestTimedResult, timing.isValid(levelID: levelID) else { return nil }
        return timing.rankedScore
    }

    static func decodeTimed(levelID: Int, score: Int, context: Int) -> SharedLevelResult? {
        guard score > 0, let level = DinoLevelCatalog.level(levelID),
              var result = decode(levelID: levelID, score: score / 1_000, context: context), result.attempted else { return nil }
        let seconds = 601 - score % 1_000
        guard (level.questionCount...level.questionCount * 60).contains(seconds) else { return nil }
        result.seconds = seconds
        return result
    }

    static func submissions(_ profile: PlayerProfile) -> [String: Int] {
        var scores = Dictionary(uniqueKeysWithValues: publishedLevels.map { (level($0.id), score(profile: profile, levelID: $0.id)) })
        scores[highestLevel] = profile.dinoLevel
        scores[totalStars] = profile.totalStars
        return scores
    }
}

struct FriendProgress: Equatable, Sendable {
    var levels: [Int: SharedLevelResult] = [:]
    private(set) var scoresVisible = true
    private(set) var sharedLevel: Int?
    private var sharedAdventureComplete = false
    private var reportedTotalStars: Int?
    var highestCompletedLevel: Int? {
        guard scoresVisible else { return nil }
        if let sharedLevel { return sharedAdventureComplete ? sharedLevel : sharedLevel - 1 }
        guard !levels.isEmpty else { return nil }
        return levels.values.filter(\.completed).map(\.levelID).max() ?? (levels.count == DinoLevelCatalog.levels.count ? 0 : nil)
    }
    /// Stop at an unknown level; never guess a friend's map position.
    var nextLevel: Int? {
        if let sharedLevel { return sharedAdventureComplete ? nil : sharedLevel }
        guard scoresVisible else { return nil }
        for level in DinoLevelCatalog.levels {
            guard let result = levels[level.id] else { return nil }
            if !result.completed { return level.id }
        }
        return nil
    }
    var allComplete: Bool { sharedAdventureComplete || (scoresVisible && DinoLevelCatalog.levels.allSatisfy { levels[$0.id]?.completed == true }) }
    var totalStars: Int? {
        guard scoresVisible else { return nil }
        if let reportedTotalStars { return reportedTotalStars }
        guard DinoLevelCatalog.levels.allSatisfy({ levels[$0.id] != nil }) else { return nil }
        return levels.values.reduce(0) { $0 + $1.stars }
    }
    var maximumStarsSoFar: Int? {
        guard totalStars != nil else { return nil }
        if let reportedTotalStars,
           levels.count != DinoLevelCatalog.levels.count || levels.values.reduce(0, { $0 + $1.stars }) != reportedTotalStars { return nil }
        return levels.values.filter { $0.completed || $0.stars > 0 }.count * 3
    }
    var starPercentage: Int? {
        guard let stars = totalStars, let maximum = maximumStarsSoFar, maximum > 0 else { return nil }
        return Int((Double(stars) / Double(maximum) * 100).rounded())
    }
    mutating func merge(_ incoming: SharedLevelResult) {
        guard scoresVisible else { return }
        if let existing = levels[incoming.levelID] {
            let oldPoints = existing.attempted ? existing.resultPoints : 0
            let newPoints = incoming.attempted ? incoming.resultPoints : 0
            if oldPoints > newPoints { return }
            if oldPoints == newPoints, (existing.seconds ?? Int.max) <= (incoming.seconds ?? Int.max) { return }
        }
        levels[incoming.levelID] = incoming
    }

    mutating func applyVisibility(_ visibility: SharedScoreVisibility?, fallbackLevel: Int? = nil) {
        scoresVisible = visibility?.showsScores == true
        sharedLevel = visibility?.levelID ?? fallbackLevel
        sharedAdventureComplete = visibility?.allComplete == true
        if !scoresVisible { levels = [:]; reportedTotalStars = nil }
    }

    mutating func applyTotalStars(_ count: Int) {
        guard scoresVisible, (0...DinoLevelCatalog.levels.count * 3).contains(count) else { return }
        reportedTotalStars = count
    }

    static func local(_ profile: PlayerProfile) -> FriendProgress {
        var progress = FriendProgress()
        for level in DinoLevelCatalog.levels {
            if let result = DinoLeaderboards.decode(levelID: level.id, score: DinoLeaderboards.score(profile: profile, levelID: level.id), context: DinoLeaderboards.context) { progress.merge(result) }
            if let score = DinoLeaderboards.timedScore(profile: profile, levelID: level.id),
               let result = DinoLeaderboards.decodeTimed(levelID: level.id, score: score, context: DinoLeaderboards.context) { progress.merge(result) }
        }
        return progress
    }
}

struct FriendMapGroup: Equatable {
    let visibleIDs: [String]
    let additionalCount: Int
    init(ids: [String]) {
        let unique = Array(NSOrderedSet(array: ids)) as? [String] ?? []
        visibleIDs = Array(unique.prefix(3))
        additionalCount = max(0, unique.count - visibleIDs.count)
    }
}

extension PlayerProfile {
    /// Merge only verified Game Center results, with a max operation per unique level.
    /// Attempts/history cannot be reconstructed from a leaderboard; do not invent them.
    mutating func mergeSharedProgress(_ remote: FriendProgress) {
        for level in DinoLevelCatalog.levels {
            guard let result = remote.levels[level.id], result.attempted else { continue }
            var record = record(level.id)
            record.stars = max(record.stars, result.stars)
            record.bestCorrect = max(record.bestCorrect, result.bestCorrect)
            record.attempts = max(record.attempts, 1)
            levels[String(level.id)] = record
            if let seconds = result.seconds { mergeTiming(TimedLevelResult(resultPoints: result.resultPoints, seconds: seconds), levelID: level.id) }
            if level.isBoss {
                if level.worldID == 1 {
                    worldOneComplete = worldOneComplete || result.bossComplete
                    perfectBossVictory = perfectBossVictory || result.perfectBoss
                } else {
                    if result.bossComplete { completedWorlds = (completedWorlds ?? []).union([level.worldID]) }
                    if result.perfectBoss { perfectWorlds = (perfectWorlds ?? []).union([level.worldID]) }
                }
            }
        }
    }
}
