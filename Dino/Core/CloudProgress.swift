import Foundation
import Combine

/// A bounded progress-only payload; names, clock themes and device preferences
/// never leave the device. Best results are merged rather than overwritten.
struct DinoCloudProgress: Codable, Equatable {
    var version = 1
    var resetAt: Date?
    var levels: [String: LevelRecord]
    @KnownQuestionKinds var demonstratedInteractions: Set<ClockQuestionKind>
    var completedWorlds: Set<Int>?
    var perfectWorlds: Set<Int>?

    init(_ profile: PlayerProfile) {
        resetAt = profile.progressResetAt
        levels = profile.levels
        demonstratedInteractions = profile.demonstratedInteractions
        completedWorlds = profile.completedWorlds
        perfectWorlds = profile.perfectWorlds
    }
}

extension PlayerProfile {
    mutating func mergeCloudProgress(_ remote: DinoCloudProgress) {
        guard remote.version == 1 else { return }
        let localReset = progressResetAt ?? .distantPast
        let remoteReset = remote.resetAt ?? .distantPast
        guard remoteReset >= localReset else { return }
        if remoteReset > localReset, let date = remote.resetAt { resetProgress(date: date) }
        for level in DinoLevelCatalog.levels {
            guard let incoming = remote.levels[String(level.id)], incoming.attempts > 0 else { continue }
            var record = record(level.id)
            let best = min(level.questionCount, max(0, incoming.bestCorrect))
            record.bestCorrect = max(record.bestCorrect, best)
            record.stars = level.isBoss ? 0 : max(record.stars, StarCalculator.stars(correct: record.bestCorrect))
            record.attempts = max(record.attempts, incoming.attempts)
            levels[String(level.id)] = record
            if let timing = incoming.bestTimedResult { mergeTiming(timing, levelID: level.id) }
        }
        demonstratedInteractions.formUnion(remote.demonstratedInteractions)
        if let completed = remote.completedWorlds {
            completedWorlds = (completedWorlds ?? []).union(completed.filter { (2...10).contains($0) })
        }
        if let perfect = remote.perfectWorlds {
            perfectWorlds = (perfectWorlds ?? []).union(perfect.filter { (2...10).contains($0) })
        }
        let bossCorrect = record(10).bestCorrect
        perfectBossVictory = perfectBossVictory || bossCorrect == 10
        worldOneComplete = worldOneComplete || perfectBossVictory || (bossCorrect >= 5 && normalLevelsComplete)
    }
}

@MainActor
protocol DinoCloudProgressStore: AnyObject {
    var isAvailable: Bool { get }
    func snapshots() -> [String: Data]
    func set(_ data: Data, forKey key: String)
    func removeObject(forKey key: String)
    func synchronize() -> Bool
}

@MainActor
private final class AppleCloudProgressStore: DinoCloudProgressStore {
    private lazy var store = NSUbiquitousKeyValueStore.default
    var isAvailable: Bool {
#if DEBUG
        // UI tests must never read or write a signed-in user's cloud save.
        if ProcessInfo.processInfo.environment["DINO_TEST_SUITE"] != nil { return false }
#endif
        // KVS queues changes even without an account or network connection.
        // The iCloud Drive identity token must not gate key-value storage.
        return true
    }
    func snapshots() -> [String: Data] { store.dictionaryRepresentation.compactMapValues { $0 as? Data } }
    func set(_ data: Data, forKey key: String) { store.set(data, forKey: key) }
    func removeObject(forKey key: String) { store.removeObject(forKey: key) }
    func synchronize() -> Bool { store.synchronize() }
}

@MainActor
final class DinoCloudSync: ObservableObject {
    enum Status: String {
        case off, active, unavailable
        var messageKey: String { "dino.settings.icloud." + rawValue }
    }
    static let progressKey = "dino.cloud.progress.v1"
    @Published private(set) var status: Status = .off
    private let store: DinoCloudProgressStore
    private weak var player: DinoPlayer?
    private var subscriptions: Set<AnyCancellable> = []
    private var enabled = false
    private var isSynchronizing = false
    private var deviceKey = ""

    init(store: DinoCloudProgressStore? = nil) { self.store = store ?? AppleCloudProgressStore() }

    func connect(player: DinoPlayer, settings: DinoSettings) {
        guard self.player == nil else { return }
        self.player = player
        // Each installation owns a separate key. A first launch cannot overwrite
        // another device's save before the initial iCloud download has finished.
        settings.$cloudDeviceID.sink { [weak self] id in
            self?.deviceKey = Self.progressKey + "." + id
        }.store(in: &subscriptions)
        player.profileChanges
            .map(DinoCloudProgress.init)
            .prepend(DinoCloudProgress(player.profile))
            .removeDuplicates()
            .sink { [weak self] _ in self?.synchronize() }
            .store(in: &subscriptions)
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self, self.enabled else { return }
                if notification.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int == NSUbiquitousKeyValueStoreQuotaViolationChange {
                    self.status = .unavailable
                } else { self.synchronize() }
            }.store(in: &subscriptions)
        settings.$icloudSyncEnabled.sink { [weak self] enabled in
            self?.enabled = enabled
            self?.synchronize()
        }.store(in: &subscriptions)
    }

    func synchronize() { synchronize(profile: player?.profile) }

    func removeAllData(at date: Date) {
        enabled = false
        status = .off
        guard store.isAvailable else { return }
        for key in store.snapshots().keys where key == Self.progressKey || key.hasPrefix(Self.progressKey + ".") {
            store.removeObject(forKey: key)
        }
        var fresh = PlayerProfile()
        fresh.progressResetAt = date
        if let data = try? JSONEncoder().encode(DinoCloudProgress(fresh)) {
            store.set(data, forKey: Self.progressKey)
        }
        // KVS queues the empty reset marker even when synchronization is offline.
        _ = store.synchronize()
    }

    private func synchronize(profile: PlayerProfile?) {
        guard enabled else { status = .off; return }
        guard !isSynchronizing, let player, let profile else { return }
        guard store.isAvailable else { status = .unavailable; return }
        guard store.synchronize() else { status = .unavailable; return }
        isSynchronizing = true
        defer { isSynchronizing = false }
        var merged = profile
        var ownSnapshot: DinoCloudProgress?
        for (key, data) in store.snapshots() where key == Self.progressKey || key.hasPrefix(Self.progressKey + ".") {
            guard let decoded = try? JSONDecoder().decode(DinoCloudProgress.self, from: data), decoded.version == 1 else {
                // Preserve unreadable or newer cloud data instead of overwriting it.
                status = .unavailable; return
            }
            if key == deviceKey { ownSnapshot = decoded }
            merged.mergeCloudProgress(decoded)
        }
        let outgoing = DinoCloudProgress(merged)
        player.mergeCloudProgress(outgoing)
        if outgoing != ownSnapshot, let data = try? JSONEncoder().encode(outgoing) {
            store.set(data, forKey: deviceKey)
        }
        status = .active
    }
}
