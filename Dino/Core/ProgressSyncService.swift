import Foundation

struct LeaderboardValue: Equatable, Sendable {
    let score: Int
    let context: Int
}

@MainActor
protocol ProgressLeaderboardTransport {
    func loadOwnResults() async throws -> [String: LeaderboardValue]
    func submit(score: Int, context: Int, leaderboardID: String) async throws
}

@MainActor
final class ProgressSyncService {
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
                progress.levels[level.id] = result
            }
        }
        merge(progress)
        for id in DinoLeaderboards.allIDs {
            guard allowed(), !Task.isCancelled else { return }
            guard let score = DinoLeaderboards.submissions(current())[id] else { continue }
            let previous = remote[id]
            if previous?.context == DinoLeaderboards.context, let best = previous?.score, best >= score { continue }
            try await transport.submit(score: score, context: DinoLeaderboards.context, leaderboardID: id)
        }
    }
}
