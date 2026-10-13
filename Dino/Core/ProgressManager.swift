import Foundation

/// Versioned player storage with an injectable UserDefaults boundary.
final class DinoProgressStore {
    static let profileKey = "dino.profile.v1"
    static let legacyNameKey = "profile.playerName"
    static let resetKey = "dino.profile.reset.v1"
    static let practiceKey = "dino.practice.records.v1"
    private let defaults: KeyValueStore

    init(defaults: KeyValueStore = UserDefaults.standard) { self.defaults = defaults }

    func load() -> PlayerProfile {
        if let data = defaults.object(forKey: Self.profileKey) as? Data,
           let decoded = try? JSONDecoder().decode(PlayerProfile.self, from: data), decoded.version == 1 {
            return validated(decoded)
        }
        var fresh = PlayerProfile()
        fresh.progressResetAt = defaults.object(forKey: Self.resetKey) as? Date
        fresh.name = PlayerProfile.sanitizedName(defaults.string(forKey: Self.legacyNameKey) ?? "")
        return fresh
    }

    func save(_ profile: PlayerProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: Self.profileKey)
        defaults.set(profile.name, forKey: Self.legacyNameKey)
    }

    func loadPracticeRecords() -> [String: DinoPracticeRecord] {
        guard let data = defaults.object(forKey: Self.practiceKey) as? Data,
              let records = try? JSONDecoder().decode([String: DinoPracticeRecord].self, from: data) else { return [:] }
        return records.filter { DinoPracticeRecord.validKeys.contains($0.key) }.mapValues {
            DinoPracticeRecord(bestStreak: max(0, $0.bestStreak), questionsAnswered: max(0, $0.questionsAnswered))
        }
    }

    func savePracticeRecords(_ records: [String: DinoPracticeRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: Self.practiceKey)
    }

    func resetPracticeRecords() { defaults.removeObject(forKey: Self.practiceKey) }

    func removeAllData(resetAt date: Date) {
        defaults.removeAllObjects()
        // Only a deletion timestamp remains, preventing older cloud saves from returning.
        defaults.set(date, forKey: Self.resetKey)
        (defaults as? UserDefaults)?.synchronize()
    }

    private func validated(_ profile: PlayerProfile) -> PlayerProfile {
        var result = profile
        result.name = PlayerProfile.sanitizedName(result.name)
        result.levels = result.levels.filter { key, _ in Int(key).flatMap(DinoLevelCatalog.level) != nil }
        for (key, var value) in result.levels {
            let level = DinoLevelCatalog.level(Int(key)!)!
            value.bestCorrect = min(level.questionCount, max(0, value.bestCorrect))
            value.stars = level.isBoss ? 0 : min(3, max(0, value.stars))
            value.attempts = max(0, value.attempts)
            result.levels[key] = value
        }
        result.bossResults = result.bossResults.filter { (0...10).contains($0.correct) }
        if result.perfectBossVictory { result.worldOneComplete = true }
        result.completedWorlds = result.completedWorlds.map { Set($0.filter { (2...10).contains($0) }) }
        result.perfectWorlds = result.perfectWorlds.map { Set($0.filter { (2...10).contains($0) }) }
        return result
    }
}
