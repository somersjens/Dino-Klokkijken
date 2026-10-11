import Foundation

/// Versioned player storage with an injectable UserDefaults boundary.
final class DinoProgressStore {
    static let profileKey = "dino.profile.v1"
    static let legacyNameKey = "profile.playerName"
    private let defaults: KeyValueStore

    init(defaults: KeyValueStore = UserDefaults.standard) { self.defaults = defaults }

    func load() -> PlayerProfile {
        if let data = defaults.object(forKey: Self.profileKey) as? Data,
           let decoded = try? JSONDecoder().decode(PlayerProfile.self, from: data), decoded.version == 1 {
            return validated(decoded)
        }
        var fresh = PlayerProfile()
        fresh.name = PlayerProfile.sanitizedName(defaults.string(forKey: Self.legacyNameKey) ?? "")
        return fresh
    }

    func save(_ profile: PlayerProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: Self.profileKey)
        defaults.set(profile.name, forKey: Self.legacyNameKey)
    }

    private func validated(_ profile: PlayerProfile) -> PlayerProfile {
        var result = profile
        result.name = PlayerProfile.sanitizedName(result.name)
        result.onboardingComplete = result.onboardingComplete && !result.name.isEmpty
        result.levels = result.levels.filter { key, _ in Int(key).map { (1...10).contains($0) } ?? false }
        for (key, var value) in result.levels {
            value.bestCorrect = min(key == "10" ? 10 : 5, max(0, value.bestCorrect))
            value.stars = key == "10" ? 0 : min(3, max(0, value.stars))
            value.attempts = max(0, value.attempts)
            result.levels[key] = value
        }
        result.bossResults = result.bossResults.filter { (0...10).contains($0.correct) }
        if result.perfectBossVictory { result.worldOneComplete = true }
        return result
    }
}
