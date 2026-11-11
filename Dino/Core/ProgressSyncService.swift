import Foundation

struct LeaderboardValue: Equatable, Sendable {
    let score: Int
    let context: Int
}

enum ScoreVisibilityFailure: Error { case invalidRecord, invalidPreference }

@MainActor
enum DinoAppearanceSyncService {
    static func synchronize(transport: ProgressLeaderboardTransport,
                            current: () -> DinoAppearancePublication,
                            resolve: (DinoAppearancePublication) -> Void,
                            allowed: () -> Bool) async throws {
        guard allowed(), !Task.isCancelled else { return }
        let values = try await transport.loadOwnAppearance()
        guard allowed(), !Task.isCancelled else { return }
        let remote = SharedDinoAppearance(values: values)
        var local = current()
        if let remote, !local.pending || remote.appearance == local.appearance {
            resolve(DinoAppearancePublication(appearance: remote.appearance, revision: remote.revision))
            return
        }
        guard values.values.allSatisfy({ (1..<Int.max - 1).contains($0.score) }),
              (0..<Int.max - 1).contains(local.revision) else { throw ScoreVisibilityFailure.invalidRecord }
        var candidate = SharedDinoAppearance(revision: max(1, local.revision), appearance: local.appearance)
        let conflicts = values.contains { id, value in
            value.score > candidate.revision || (value.score == candidate.revision &&
                value.context != (id == SharedDinoAppearance.primaryID ? candidate.primaryContext : candidate.secondaryContext))
        }
        if conflicts {
            candidate = SharedDinoAppearance(revision: max(local.revision, values.values.map(\.score).max() ?? 0) + 1,
                                             appearance: local.appearance)
        }
        local = DinoAppearancePublication(appearance: candidate.appearance, revision: candidate.revision, pending: true)
        resolve(local) // Persist before suspension so a partial upload can resume after relaunch.
        for (id, context) in [(SharedDinoAppearance.secondaryID, candidate.secondaryContext),
                              (SharedDinoAppearance.primaryID, candidate.primaryContext)] {
            guard allowed(), !Task.isCancelled else { return }
            if values[id] == LeaderboardValue(score: candidate.revision, context: context) { continue }
            try await transport.submit(score: candidate.revision, context: context, leaderboardID: id)
        }
        guard allowed(), !Task.isCancelled else { return }
        local.pending = false
        resolve(local)
    }
}

@MainActor
protocol AchievementTransport {
    func loadProgress() async throws -> [String: Double]
    func report(_ progress: [AchievementProgress]) async throws
}

@MainActor
enum AchievementSyncService {
    static func synchronize(transport: AchievementTransport,
                            current: () -> PlayerProfile,
                            includeScores: () -> Bool,
                            allowed: () -> Bool) async throws {
        guard allowed() else { return }
        let remote = try await transport.loadProgress()
        guard allowed(), !Task.isCancelled else { return }
        let updates = DinoAchievements.progress(current(), includeScores: includeScores()).filter {
            $0.percentComplete > (remote[$0.identifier] ?? 0)
        }
        guard !updates.isEmpty, allowed(), !Task.isCancelled else { return }
        try await transport.report(updates)
    }
}

@MainActor
protocol ProgressLeaderboardTransport {
    var availableTimingLeaderboardIDs: Set<String> { get }
    func loadOwnResults() async throws -> [String: LeaderboardValue]
    func loadOwnVisibility() async throws -> LeaderboardValue?
    func loadOwnAppearance() async throws -> [String: LeaderboardValue]
    func submit(score: Int, context: Int, leaderboardID: String) async throws
}

extension ProgressLeaderboardTransport {
    var availableTimingLeaderboardIDs: Set<String> { [] }
    func loadOwnVisibility() async throws -> LeaderboardValue? { nil }
    func loadOwnAppearance() async throws -> [String: LeaderboardValue] { [:] }
}

@MainActor
final class ProgressSyncService {
    /// Visibility is read before any public results. Scores become visible only after
    /// a successful result sync. A hidden profile uploads only its current level.
    @discardableResult
    func synchronizeSharing(transport: ProgressLeaderboardTransport,
                            current: () -> PlayerProfile,
                            merge: (FriendProgress) -> Void,
                            choice: () -> ScoreSharingChoice,
                            resolve: (ScoreSharingChoice) -> Void,
                            allowed: () -> Bool) async throws -> Bool {
        guard allowed() else { return false }
        let value = try await transport.loadOwnVisibility()
        guard allowed(), !Task.isCancelled else { return false }
        let remote = value.flatMap { SharedScoreVisibility(score: $0.score, context: $0.context) }
        if value != nil && remote == nil { throw ScoreVisibilityFailure.invalidRecord }
        let local = choice()
        if let remote {
            if local.pending {
                if remote.revision >= local.revision {
                    resolve(ScoreSharingChoice(revision: remote.revision + 1, showsScores: local.showsScores, pending: true))
                }
            } else if remote.revision > local.revision || (remote.revision == local.revision && !remote.showsScores) {
                resolve(ScoreSharingChoice(revision: remote.revision, showsScores: remote.showsScores, pending: false))
            }
        }
        guard (1..<((Int.max - 1_023) / 1_024)).contains(choice().revision) else {
            throw ScoreVisibilityFailure.invalidPreference
        }
        if choice().showsScores {
            try await synchronize(transport: transport, current: current, merge: merge,
                                  allowed: { allowed() && choice().showsScores })
        }
        guard allowed(), !Task.isCancelled else { return false }
        let visibility = SharedScoreVisibility(revision: choice().revision, profile: current(), showsScores: choice().showsScores)
        if let remote, remote.score >= visibility.score { return true }
        try await transport.submit(score: visibility.score, context: SharedScoreVisibility.context,
                                   leaderboardID: SharedScoreVisibility.leaderboardID)
        return allowed() && !Task.isCancelled
    }

    /// Durable retry queue = the original persisted profile. Re-read after every
    /// suspension, since a player can finish another level while a request runs.
    /// Consent/account generation is checked before merge and each submission.
    func synchronize(transport: ProgressLeaderboardTransport,
                     current: () -> PlayerProfile,
                     merge: (FriendProgress) -> Void,
                     allowed: () -> Bool) async throws {
        guard allowed() else { return }
        let remote = try await transport.loadOwnResults()
        guard allowed(), !Task.isCancelled else { return }
        var progress = FriendProgress()
        for level in DinoLevelCatalog.levels {
            if let value = remote[DinoLeaderboards.level(level.id)],
               let result = DinoLeaderboards.decode(levelID: level.id, score: value.score, context: value.context) {
                progress.merge(result)
            }
            if let value = remote[DinoLeaderboards.timedLevel(level.id)],
               let result = DinoLeaderboards.decodeTimed(levelID: level.id, score: value.score, context: value.context) { progress.merge(result) }
        }
        merge(progress)
        for id in DinoLeaderboards.allIDs {
            guard allowed(), !Task.isCancelled else { return }
            guard let score = DinoLeaderboards.submissions(current())[id] else { continue }
            let previous = remote[id]
            if previous?.context == DinoLeaderboards.context, let best = previous?.score, best >= score { continue }
            try await transport.submit(score: score, context: DinoLeaderboards.context, leaderboardID: id)
        }
        for level in DinoLevelCatalog.levels {
            guard allowed(), !Task.isCancelled else { return }
            let id = DinoLeaderboards.timedLevel(level.id)
            guard transport.availableTimingLeaderboardIDs.contains(id),
                  let score = DinoLeaderboards.timedScore(profile: current(), levelID: level.id) else { continue }
            if let previous = remote[id], DinoLeaderboards.decodeTimed(levelID: level.id, score: previous.score, context: previous.context) != nil,
               previous.score >= score { continue }
            try await transport.submit(score: score, context: DinoLeaderboards.context, leaderboardID: id)
        }
    }
}
