import SwiftUI
import Combine
import GameKit
import UIKit

struct DinoFriend: Identifiable {
    let id: String
    let displayName: String
    var progress = FriendProgress()
    var avatar: UIImage?
}

enum FriendsState: String {
    case inactive, authenticating, signedOut, needsPermission, denied, restricted, loading, ready, unavailable
    var messageKey: String { "dino.friends.state.\(rawValue)" }
}

enum GameCenterFailure: Error { case configuration, unavailable }

@MainActor
final class GameKitProgressTransport: ProgressLeaderboardTransport {
    private(set) var availableTimingLeaderboardIDs: Set<String> = []
    private let player: GKLocalPlayer
    init(player: GKLocalPlayer = .local) { self.player = player }

    func loadOwnResults() async throws -> [String: LeaderboardValue] {
        let boards = try await GKLeaderboard.loadLeaderboards(IDs: DinoLeaderboards.allIDs)
        guard Set(boards.map(\.baseLeaderboardID)) == Set(DinoLeaderboards.allIDs), boards.allSatisfy({ $0.type == .classic }) else { throw GameCenterFailure.configuration }
        var values: [String: LeaderboardValue] = [:]
        for board in boards {
            let (local, _) = try await board.loadEntries(for: [player], timeScope: .allTime)
            if let local {
                values[board.baseLeaderboardID] = LeaderboardValue(score: local.score, context: local.context)
            }
        }
        // Timing boards are additive: old installations retain working progress sync.
        if let timedBoards = try? await GKLeaderboard.loadLeaderboards(IDs: DinoLeaderboards.timedIDs) {
            availableTimingLeaderboardIDs = Set(timedBoards.filter { $0.type == .classic }.map(\.baseLeaderboardID))
            for board in timedBoards where availableTimingLeaderboardIDs.contains(board.baseLeaderboardID) {
                if let (local, _) = try? await board.loadEntries(for: [player], timeScope: .allTime), let local {
                    values[board.baseLeaderboardID] = LeaderboardValue(score: local.score, context: local.context)
                }
            }
        }
        return values
    }
    func submit(score: Int, context: Int, leaderboardID: String) async throws {
        try await GKLeaderboard.submitScore(score, context: context, player: player, leaderboardIDs: [leaderboardID])
    }
}

/// GameKit is the only source of friend identity and relationship information.
/// Friends, photos, and their scores are memory-only and are cleared on every
/// privacy transition; generations prevent late responses repopulating the UI.
@MainActor
final class FriendsManager: NSObject, ObservableObject {
    @Published private(set) var friends: [DinoFriend] = []
    @Published private(set) var state: FriendsState = .inactive
    @Published private(set) var sharing = false
    /// True after the one-time Game Center approval, until the player switches it off.
    @Published private(set) var friendAccess: Bool
    /// Sharing chosen before Game Center finishes signing in.
    @Published private(set) var shareWhenConnected: Bool
    @Published private(set) var syncing = false
    @Published private(set) var syncMessageKey: String?
    @Published private(set) var actionMessageKey: String?
    @Published private(set) var accountConflict = false
    @Published private(set) var enabled: Bool
    @Published private(set) var playerDisplayName: String?
    weak var presentationAnchor: UIViewController?
    private weak var player: DinoPlayer?
    private let defaults: KeyValueStore
    private var gamePlayers: [String: GKPlayer] = [:]
    private var generation = UUID()
    private var refreshTask: Task<Void, Never>?
    private var syncTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?
    private var retryDelay = 5.0
    private var syncAgain = false
    private var progressDirty = true
    private var lastSuccessfulSync: Date?
    private var appActive = true
    private var observers: [AnyCancellable] = []
    private var startedAuthentication = false
    private var authenticatedID: String?
    private var authenticationController: UIViewController?
    private let syncService = ProgressSyncService()
    private static let enabledKey = "dino.social.enabled.v1"
    private static let ownerKey = "dino.social.saveOwner.v1"
    private static let friendAccessKey = "dino.social.friendAccess.v1"
    private static let shareOnConnectKey = "dino.social.shareOnConnect.v1"
    private static func sharingKey(_ id: String) -> String { "dino.social.sharing.v1.\(id)" }

    override init() {
        var store: KeyValueStore = UserDefaults.standard
#if DEBUG
        if let suite = ProcessInfo.processInfo.environment["DINO_TEST_SUITE"], let isolated = UserDefaults(suiteName: suite) { store = isolated }
#endif
        defaults = store
        enabled = store.integer(forKey: Self.enabledKey) == 1
        friendAccess = store.object(forKey: Self.friendAccessKey) != nil && store.integer(forKey: Self.friendAccessKey) == 1
        shareWhenConnected = store.integer(forKey: Self.shareOnConnectKey) == 1
        super.init()
        updatePlayerIdentity()
        NotificationCenter.default.publisher(for: .GKPlayerAuthenticationDidChangeNotificationName)
            .receive(on: RunLoop.main).sink { [weak self] _ in self?.authenticationChanged() }.store(in: &observers)
    }

    private var usesUITestFixtures: Bool {
#if DEBUG
        ProcessInfo.processInfo.environment["DINO_TEST_SOCIAL"] == "fixtures" && ProcessInfo.processInfo.environment["DINO_TEST_SUITE"] != nil
#else
        false
#endif
    }
    var authenticated: Bool { enabled && (usesUITestFixtures || GKLocalPlayer.local.isAuthenticated) }
    var canInvite: Bool {
        authenticated && !usesUITestFixtures && !GKLocalPlayer.local.isMultiplayerGamingRestricted && !GKLocalPlayer.local.isPersonalizedCommunicationRestricted
    }
    var canShare: Bool { authenticated && !usesUITestFixtures && !accountConflict && !GKLocalPlayer.local.isUnderage && !GKLocalPlayer.local.isMultiplayerGamingRestricted }

    func connect(_ player: DinoPlayer) {
        guard self.player == nil else { return }
        self.player = player
        player.progressChanged = { [weak self] in self?.progressDirty = true; self?.scheduleSync() }
        player.progressReset = { [weak self] in
            self?.stopSharing()
            self?.defaults.removeObject(forKey: Self.ownerKey)
            self?.accountConflict = false
        }
        if usesUITestFixtures { enabled = true; friendAccess = true; updatePlayerIdentity(); refresh(); return }
        if enabled { authenticate() }
    }

    /// One approval turns on Game Center, friends access and result sharing together.
    func enable() {
        enabled = true; defaults.set(1, forKey: Self.enabledKey)
        friendAccess = true; defaults.set(1, forKey: Self.friendAccessKey)
        shareWhenConnected = true; defaults.set(1, forKey: Self.shareOnConnectKey)
        authenticate()
    }
    func disable() {
        stopSharing()
        enabled = false; defaults.set(0, forKey: Self.enabledKey)
        friendAccess = false; defaults.set(0, forKey: Self.friendAccessKey)
        invalidateFriends(); state = .inactive
        authenticationController?.dismiss(animated: true); authenticationController = nil
    }
    /// Friends access can be switched off immediately. Switching it on happens only after the parental question.
    func setFriendAccess(_ allowed: Bool) {
        friendAccess = allowed
        defaults.set(allowed ? 1 : 0, forKey: Self.friendAccessKey)
        guard enabled else { return }
        if allowed {
            guard authenticated else { return }
            invalidateFriends()
            refresh(requestPermission: true)
        } else {
            invalidateFriends()
            if authenticated { state = .needsPermission }
        }
    }
    func authenticate() {
        guard enabled else { return }
        if GKLocalPlayer.local.isAuthenticated { authenticationChanged(); return }
        guard !startedAuthentication else { state = .signedOut; return }
        startedAuthentication = true; state = .authenticating
        GKLocalPlayer.local.authenticateHandler = { [weak self] controller, error in
            Task { @MainActor in
                guard let self, self.enabled else { return }
                if let controller {
                    self.authenticationController = controller
                    self.presentAuthenticationIfPossible()
                } else {
                    self.authenticationController?.dismiss(animated: true)
                    self.authenticationController = nil
                    self.authenticationChanged()
                    if error != nil && !GKLocalPlayer.local.isAuthenticated { self.state = .signedOut }
                }
            }
        }
    }
    private func authenticationChanged() {
        updatePlayerIdentity()
        guard enabled else { return }
        if usesUITestFixtures { refresh(); return }
        let local = GKLocalPlayer.local
        let id = local.isAuthenticated ? local.gamePlayerID : nil
        if id != authenticatedID {
            invalidateFriends(); syncTask?.cancel(); syncTask = nil; retryTask?.cancel(); retryTask = nil
            syncing = false; sharing = false
            authenticatedID = id
            progressDirty = true; lastSuccessfulSync = nil
        }
        guard let id else { state = .signedOut; return }
        accountConflict = defaults.string(forKey: Self.ownerKey).map { $0 != id } ?? false
        sharing = canShare && defaults.integer(forKey: Self.sharingKey(id)) == 1
        if defaults.integer(forKey: Self.shareOnConnectKey) == 1 {
            defaults.set(0, forKey: Self.shareOnConnectKey)
            shareWhenConnected = false
            if canShare { allowSharing() }
        }
        if friendAccess { refresh(requestPermission: true) }
        else if defaults.object(forKey: Self.friendAccessKey) == nil { refresh(requestPermission: false) }
        else { invalidateFriends(); state = .needsPermission }
        scheduleSync()
    }

    func foreground() {
        appActive = true
        updatePlayerIdentity()
        guard enabled else { return }
        presentAuthenticationIfPossible()
        authenticationChanged()
        scheduleSync(force: true)
    }
    /// Never use a saved local name as a fallback for Apple's account identity.
    private func updatePlayerIdentity() {
        if usesUITestFixtures {
            playerDisplayName = "Game Center Sam"
        } else {
            let local = GKLocalPlayer.local
            playerDisplayName = local.isAuthenticated ? local.displayName : nil
        }
    }
    func background() {
        appActive = false
        invalidateFriends()
        syncTask?.cancel(); syncTask = nil; retryTask?.cancel(); retryTask = nil; syncing = false
    }
    func refresh(requestPermission: Bool = false) {
        guard appActive else { return }
        if usesUITestFixtures { loadUITestFixtures(); return }
        guard authenticated else { if enabled { state = .signedOut }; return }
        let legacyAccess = defaults.object(forKey: Self.friendAccessKey) == nil && !requestPermission
        guard friendAccess || legacyAccess else {
            invalidateFriends(); state = .needsPermission; return
        }
        guard refreshTask == nil else { return }
        // Even an offline refresh cannot leave unverified former friends on screen.
        invalidateFriends()
        let token = generation, account = GKLocalPlayer.local.gamePlayerID
        state = .loading; actionMessageKey = nil
        refreshTask = Task { [weak self] in
            guard let self else { return }
            defer { if self.generation == token { self.refreshTask = nil } }
            do {
                let authorization = try await GKLocalPlayer.local.loadFriendsAuthorizationStatus()
                guard self.valid(token, account) else { return }
                switch authorization {
                case .denied: self.state = .denied; return
                case .restricted: self.state = .restricted; return
                case .notDetermined:
                    guard requestPermission else { self.state = .needsPermission; return }
                case .authorized:
                    if self.defaults.object(forKey: Self.friendAccessKey) == nil {
                        self.friendAccess = true
                        self.defaults.set(1, forKey: Self.friendAccessKey)
                    }
                @unknown default: self.state = .restricted; return
                }
                let players = try await GKLocalPlayer.local.loadFriends()
                guard self.valid(token, account) else { return }
                // Recheck permission after the native prompt and before showing anything.
                guard try await GKLocalPlayer.local.loadFriendsAuthorizationStatus() == .authorized else {
                    self.invalidateFriends(); self.state = .denied; return
                }
                guard self.valid(token, account) else { return }
                var unique: [String: GKPlayer] = [:]
                for friend in players where friend.gamePlayerID != account { unique[friend.gamePlayerID] = friend }
                self.gamePlayers = unique
                self.friends = unique.values.map { DinoFriend(id: $0.gamePlayerID, displayName: $0.displayName) }
                    .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
                self.state = .ready
                guard !unique.isEmpty else { return }
                await self.loadProgress(players: Array(unique.values), token: token, account: account)
                guard self.valid(token, account) else { return }
                // Load photos in bounded batches, rather than N serial requests.
                for offset in stride(from: 0, to: players.count, by: 6) {
                    guard self.valid(token, account) else { return }
                    let batch = Array(players[offset..<min(offset + 6, players.count)])
                    await withTaskGroup(of: (String, UIImage?).self) { group in
                        for native in batch {
                            group.addTask { (native.gamePlayerID, try? await native.loadPhoto(for: .small)) }
                        }
                        for await (id, photo) in group {
                            guard self.valid(token, account) else { group.cancelAll(); return }
                            if let index = self.friends.firstIndex(where: { $0.id == id }) { self.friends[index].avatar = photo }
                        }
                    }
                }
                guard self.valid(token, account) else { return }
                guard try await GKLocalPlayer.local.loadFriendsAuthorizationStatus() == .authorized else {
                    self.invalidateFriends(); self.state = .denied; return
                }
            } catch {
                guard self.valid(token, account) else { return }
                self.invalidateFriends()
                let native = error as NSError
                if native.domain == GKErrorDomain && native.code == GKError.Code.friendListRestricted.rawValue { self.state = .restricted }
                else if native.domain == GKErrorDomain && native.code == GKError.Code.friendListDenied.rawValue { self.state = .denied }
                else { self.state = .unavailable }
            }
        }
    }
    private func loadProgress(players: [GKPlayer], token: UUID, account: String) async {
        do {
            let boards = try await GKLeaderboard.loadLeaderboards(IDs: DinoLeaderboards.publishedLevels.map { DinoLeaderboards.level($0.id) })
            guard valid(token, account) else { return }
            if boards.count != DinoLeaderboards.publishedLevels.count { actionMessageKey = "dino.friends.resultsUnavailable" }
            let timedBoards = (try? await GKLeaderboard.loadLeaderboards(IDs: DinoLeaderboards.timedIDs)) ?? []
            guard valid(token, account) else { return }
            for board in boards + timedBoards where board.type == .classic {
                guard let level = DinoLevelCatalog.levels.first(where: {
                    board.baseLeaderboardID == DinoLeaderboards.level($0.id) || board.baseLeaderboardID == DinoLeaderboards.timedLevel($0.id)
                }) else { continue }
                let isTimed = board.baseLeaderboardID == DinoLeaderboards.timedLevel(level.id)
                // Explicit friends, in batches; never fetch a global ranked list.
                for offset in stride(from: 0, to: players.count, by: 50) {
                    guard valid(token, account) else { return }
                    let batch = Array(players[offset..<min(offset + 50, players.count)])
                    do {
                        let (_, entries) = try await board.loadEntries(for: batch, timeScope: .allTime)
                        guard valid(token, account) else { return }
                        for entry in entries {
                            guard let index = friends.firstIndex(where: { $0.id == entry.player.gamePlayerID }),
                                  let result = isTimed ? DinoLeaderboards.decodeTimed(levelID: level.id, score: entry.score, context: entry.context)
                                    : DinoLeaderboards.decode(levelID: level.id, score: entry.score, context: entry.context) else { continue }
                            friends[index].progress.merge(result)
                        }
                    } catch { if valid(token, account) { actionMessageKey = "dino.friends.resultsUnavailable" } }
                }
            }
        } catch { if valid(token, account) { actionMessageKey = "dino.friends.resultsUnavailable" } }
    }

    func allowSharing() {
        guard canShare else {
            if enabled && !authenticated {
                shareWhenConnected = true
                defaults.set(1, forKey: Self.shareOnConnectKey)
            }
            return
        }
        shareWhenConnected = false
        defaults.set(0, forKey: Self.shareOnConnectKey)
        let id = GKLocalPlayer.local.gamePlayerID
        defaults.set(id, forKey: Self.ownerKey)
        defaults.set(1, forKey: Self.sharingKey(id))
        sharing = true; retryDelay = 5
        scheduleSync()
    }
    func stopSharing() {
        shareWhenConnected = false
        defaults.set(0, forKey: Self.shareOnConnectKey)
        if let id = authenticatedID { defaults.set(0, forKey: Self.sharingKey(id)) }
        sharing = false; syncing = false; syncMessageKey = nil
        syncTask?.cancel(); syncTask = nil; retryTask?.cancel(); retryTask = nil
    }
    func scheduleSync(force: Bool = false) {
        guard appActive, sharing, canShare, let player else { return }
        guard force || progressDirty || lastSuccessfulSync.map({ Date().timeIntervalSince($0) >= 300 }) ?? true else { return }
        guard syncTask == nil else { syncAgain = true; return }
        syncAgain = false
        progressDirty = false
        let account = GKLocalPlayer.local.gamePlayerID
        let token = generation
        syncing = true; syncMessageKey = nil
        syncTask = Task { [weak self, weak player] in
            guard let self, let player else { return }
            do {
                try await self.syncService.synchronize(transport: GameKitProgressTransport(), current: { player.profile },
                    merge: { player.mergeSharedProgress($0) }, allowed: { self.sharing && self.canShare && self.validAccount(account) && !Task.isCancelled })
                guard !Task.isCancelled, self.validAccount(account) else { return }
                self.syncing = false; self.syncTask = nil; self.retryDelay = 5
                self.lastSuccessfulSync = Date()
                self.syncMessageKey = "dino.friends.syncDone"
                if self.syncAgain { self.scheduleSync(force: true) }
            } catch {
                guard !Task.isCancelled, self.validAccount(account) else { return }
                self.syncing = false; self.syncTask = nil
                self.progressDirty = true
                self.syncMessageKey = "dino.friends.syncPending"
                self.retryTask = Task { [weak self] in
                    guard let self else { return }
                    do { try await Task.sleep(for: .seconds(self.retryDelay)) } catch { return }
                    self.retryDelay = min(self.retryDelay * 2, 300)
                    self.retryTask = nil
                    guard self.generation == token else { return }
                    self.scheduleSync()
                }
            }
        }
    }
    func invite() {
        guard canInvite, let host = presenter() else { actionMessageKey = "dino.friends.inviteRestricted"; return }
        do { try GKLocalPlayer.local.presentFriendRequestCreator(from: host) }
        catch { actionMessageKey = "dino.friends.inviteFailed" }
    }
    func showAppleProfile(friendID: String? = nil) {
        guard authenticated, let window = presentationAnchor?.view.window else { return }
        let access = GKAccessPoint.shared
        access.parentWindow = window
        // Trigger the official dashboard without a floating overlay over the game.
        if let friendID {
            guard let friend = gamePlayers[friendID] else { return }
            if #available(iOS 18, *) {
                access.trigger(player: friend) { [weak self] in self?.refresh() }
            } else {
                // iOS 16 and 17 can open the friends list; a specific profile arrives in iOS 18.
                access.trigger(state: .localPlayerFriendsList) { [weak self] in self?.refresh() }
            }
        } else { access.trigger(state: .localPlayerProfile) { [weak self] in self?.refresh() } }
    }
    func friend(_ id: String) -> DinoFriend? { friends.first { $0.id == id } }
    func friends(at levelID: Int) -> [DinoFriend] { friends.filter { $0.progress.nextLevel == levelID } }
    func friends(completed levelID: Int) -> [DinoFriend] { friends.filter { $0.progress.levels[levelID]?.completed == true } }

    private func invalidateFriends() {
        generation = UUID(); refreshTask?.cancel(); refreshTask = nil
        friends = []; gamePlayers = [:]
    }
    private func validAccount(_ id: String) -> Bool { authenticated && GKLocalPlayer.local.gamePlayerID == id }
    private func valid(_ token: UUID, _ account: String) -> Bool { appActive && token == generation && validAccount(account) && !Task.isCancelled }
    private func presenter() -> UIViewController? {
        var host = presentationAnchor?.view.window?.rootViewController
        while let presented = host?.presentedViewController { host = presented }
        return host
    }
    func presentAuthenticationIfPossible() {
        guard appActive, enabled, let controller = authenticationController,
              controller.presentingViewController == nil, !controller.isBeingPresented,
              let host = presenter(), host !== controller else { return }
        host.present(controller, animated: true)
    }
    private func loadUITestFixtures() {
#if DEBUG
        guard usesUITestFixtures, enabled else { return }
        let names = ["Sophie", "Thomas", "Emma", "Luna", "Rex"]
        friends = names.enumerated().map { index, name in
            var saved = PlayerProfile()
            saved.recordCompletedAttempt(levelID: 1, correct: 5 - index % 3, questionSeconds: Array(repeating: 4 + index * 3, count: 5))
            return DinoFriend(id: "test-\(index)", displayName: name, progress: .local(saved))
        }
        friends.append(DinoFriend(id: "test-missing", displayName: "Alex"))
        state = .ready
#endif
    }
}

/// An anchor in this window avoids presenting from an unrelated foreground scene.
struct GameCenterPresentationAnchor: UIViewControllerRepresentable {
    let manager: FriendsManager
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = GameCenterAnchorController(); controller.manager = manager
        controller.view.isUserInteractionEnabled = false
        manager.presentationAnchor = controller
        return controller
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { manager.presentationAnchor = uiViewController }
}

private final class GameCenterAnchorController: UIViewController {
    weak var manager: FriendsManager?
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        manager?.presentAuthenticationIfPossible()
    }
}
