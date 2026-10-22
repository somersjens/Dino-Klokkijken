import Foundation
import Combine

/// Device preferences stay local, including the opt-in for cloud progress.
@MainActor
final class DinoSettings: ObservableObject {
    @Published var soundEffectsEnabled: Bool { didSet { save(soundEffectsEnabled, key: "soundEffects") } }
    @Published var speakQuestionTitles: Bool { didSet { save(speakQuestionTitles, key: "speakQuestionTitle") } }
    @Published var hapticsEnabled: Bool { didSet { save(hapticsEnabled, key: "haptics") } }
    @Published var highContrastEnabled: Bool { didSet { save(highContrastEnabled, key: "highContrast") } }
    @Published var icloudSyncEnabled: Bool { didSet { save(icloudSyncEnabled, key: "icloudSync") } }
    @Published var practiceTime: DinoPracticeTime { didSet { defaults.set(practiceTime.rawValue, forKey: "dino.settings.practiceTime") } }
    @Published var practiceOrder: DinoPracticeOrder { didSet { defaults.set(practiceOrder.storageKey, forKey: "dino.settings.practiceOrder") } }
    @Published var dayPartSchedule: DinoDayPartSchedule { didSet { defaults.set(dayPartSchedule.storageKey, forKey: "dino.settings.dayParts") } }
    @Published private(set) var cloudDeviceID: String
    private let defaults: KeyValueStore

    init(defaults: KeyValueStore? = nil) {
        let resolved: KeyValueStore
#if DEBUG
        if let suite = ProcessInfo.processInfo.environment["DINO_TEST_SUITE"],
           let testDefaults = UserDefaults(suiteName: suite) { resolved = defaults ?? testDefaults }
        else { resolved = defaults ?? UserDefaults.standard }
#else
        resolved = defaults ?? UserDefaults.standard
#endif
        self.defaults = resolved
        if let saved = resolved.string(forKey: "dino.settings.cloudDeviceID"), UUID(uuidString: saved) != nil {
            cloudDeviceID = saved
        } else {
            let freshID = UUID().uuidString
            cloudDeviceID = freshID
            resolved.set(freshID, forKey: "dino.settings.cloudDeviceID")
        }
        soundEffectsEnabled = resolved.object(forKey: "dino.settings.soundEffects") as? Bool ?? true
        speakQuestionTitles = resolved.object(forKey: "dino.settings.speakQuestionTitle") as? Bool ?? false
        hapticsEnabled = resolved.object(forKey: "dino.settings.haptics") as? Bool ?? true
        highContrastEnabled = resolved.object(forKey: "dino.settings.highContrast") as? Bool ?? false
        icloudSyncEnabled = resolved.object(forKey: "dino.settings.icloudSync") as? Bool ?? false
        practiceTime = DinoPracticeTime(storageKey: resolved.string(forKey: "dino.settings.practiceTime") ?? "") ?? .whole
        practiceOrder = DinoPracticeOrder(storageKey: resolved.string(forKey: "dino.settings.practiceOrder") ?? "") ?? .ascending
        dayPartSchedule = resolved.string(forKey: "dino.settings.dayParts").flatMap(DinoDayPartSchedule.init(storageKey:)) ?? .standard
    }

    private func save(_ value: Bool, key: String) { defaults.set(value, forKey: "dino.settings." + key) }

    func resetPreferences() {
        soundEffectsEnabled = true
        speakQuestionTitles = false
        hapticsEnabled = true
        highContrastEnabled = false
        icloudSyncEnabled = false
        practiceTime = .whole
        practiceOrder = .ascending
        dayPartSchedule = .standard
        cloudDeviceID = UUID().uuidString
        defaults.set(cloudDeviceID, forKey: "dino.settings.cloudDeviceID")
        (defaults as? UserDefaults)?.synchronize()
    }
}
