import Foundation

/// A projection of the existing save, not a second source of player progress.
struct SharedLevelResult: Equatable, Sendable {
    let levelID: Int
    let attempted: Bool
    let stars: Int
    let bestCorrect: Int
    let bossComplete: Bool
    let perfectBoss: Bool
    var completed: Bool { levelID == 10 ? bossComplete : stars > 0 }
}

enum DinoLeaderboards {
    static let highestLevel = "dino.progress.highest.v1"
    static let totalStars = "dino.progress.stars.v1"
    static let context = 1
    static func level(_ id: Int) -> String { "dino.level.\(id).result.v1" }
    static var allIDs: [String] { DinoLevelCatalog.levels.map { level($0.id) } + [highestLevel, totalStars] }

    /// Integer ordering preserves both best stars and best correct answers.
    /// Zero explicitly means no completed attempt was present in the real save.
    /// Missing entries and unknown schema versions must never be decoded as zero.
    static func score(profile: PlayerProfile, levelID: Int) -> Int {
        let record = profile.record(levelID)
        guard record.attempts > 0 || record.stars > 0 || (levelID == 10 && profile.worldOneComplete) else { return 0 }
        if levelID == 10 {
            return 1 + record.bestCorrect + (profile.worldOneComplete ? 16 : 0) + (profile.perfectBossVictory ? 32 : 0)
        }
        return 1 + record.stars * 8 + record.bestCorrect
    }

    static func decode(levelID: Int, score: Int, context: Int) -> SharedLevelResult? {
        guard DinoLevelCatalog.level(levelID) != nil, context == Self.context, score >= 0 else { return nil }
        if score == 0 {
            return SharedLevelResult(levelID: levelID, attempted: false, stars: 0, bestCorrect: 0, bossComplete: false, perfectBoss: false)
        }
        let value = score - 1
        if levelID == 10 {
            guard value <= 58 else { return nil }
            let correct = value & 15, complete = value & 16 != 0, perfect = value & 32 != 0
            guard correct <= 10, !perfect || (complete && correct == 10), !complete || correct >= 5,
                  correct != 10 || perfect else { return nil }
            return SharedLevelResult(levelID: levelID, attempted: true, stars: 0, bestCorrect: correct, bossComplete: complete, perfectBoss: perfect)
        }
        let stars = value / 8, correct = value % 8
        guard correct <= 5, stars <= 3, stars == StarCalculator.stars(correct: correct) else { return nil }
        return SharedLevelResult(levelID: levelID, attempted: true, stars: stars, bestCorrect: correct, bossComplete: false, perfectBoss: false)
    }

    static func submissions(_ profile: PlayerProfile) -> [String: Int] {
        var scores = Dictionary(uniqueKeysWithValues: DinoLevelCatalog.levels.map { (level($0.id), score(profile: profile, levelID: $0.id)) })
        scores[highestLevel] = profile.dinoLevel
        scores[totalStars] = profile.totalStars
        return scores
    }
}

struct FriendProgress: Equatable, Sendable {
    var levels: [Int: SharedLevelResult] = [:]
    var highestCompletedLevel: Int? {
        guard !levels.isEmpty else { return nil }
        return levels.values.filter(\.completed).map(\.levelID).max() ?? (levels.count == DinoLevelCatalog.levels.count ? 0 : nil)
    }
    /// Stop at an unknown level; never guess a friend's map position.
    var nextLevel: Int? {
        for level in DinoLevelCatalog.levels {
            guard let result = levels[level.id] else { return nil }
            if !result.completed { return level.id }
        }
        return nil
    }
    var allComplete: Bool { DinoLevelCatalog.levels.allSatisfy { levels[$0.id]?.completed == true } }
    var totalStars: Int? {
        guard (1...9).allSatisfy({ levels[$0] != nil }) else { return nil }
        return (1...9).reduce(0) { $0 + (levels[$1]?.stars ?? 0) }
    }
    var maximumStarsSoFar: Int? {
        guard totalStars != nil else { return nil }
        return (1...9).filter { levels[$0]?.completed == true }.count * 3
    }
    var starPercentage: Int? {
        guard let stars = totalStars, let maximum = maximumStarsSoFar, maximum > 0 else { return nil }
        return Int((Double(stars) / Double(maximum) * 100).rounded())
    }
    static func local(_ profile: PlayerProfile) -> FriendProgress {
        FriendProgress(levels: Dictionary(uniqueKeysWithValues: DinoLevelCatalog.levels.compactMap { level in
            DinoLeaderboards.decode(levelID: level.id, score: DinoLeaderboards.score(profile: profile, levelID: level.id), context: DinoLeaderboards.context).map { (level.id, $0) }
        }))
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
            if level.isBoss {
                worldOneComplete = worldOneComplete || result.bossComplete
                perfectBossVictory = perfectBossVictory || result.perfectBoss
            }
        }
    }
}
