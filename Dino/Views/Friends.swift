import SwiftUI

struct FriendSelection: Identifiable { let id: String }

private enum LevelSocialSheet: Identifiable {
    case connection, profile(String)
    var id: String {
        switch self {
        case .connection: "connection"
        case .profile(let id): "profile-" + id
        }
    }
}

/// The App Store page friends open from the level card. Empty until the store link is set.
enum DinoAppDownload {
    static var url: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "DinoAppStoreURL") as? String,
              let url = URL(string: value), url.scheme?.lowercased() == "https",
              let host = url.host, !host.isEmpty else { return nil }
        return url
    }
}

private enum ParentAction: String, Identifiable {
    case enable, access, share, appleProfile
    var id: String { rawValue }
}

/// A parental gate for external/social actions. It is not legal parental consent.
struct DinoParentGate: View {
    let sharing: Bool
    var explanationKey: String? = nil
    var confirmKey: String? = nil
    var proceed: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var answer = ""
    @State private var first = Int.random(in: 12...19)
    @State private var second = Int.random(in: 6...9)
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Label("dino.friends.parentTitle", systemImage: "lock.shield.fill").font(.title2.bold())
                    Text(LocalizedStringKey(explanationKey ?? (sharing ? "dino.friends.sharingDisclosure" : "dino.friends.parentMessage")))
                        .font(.body).multilineTextAlignment(.center)
                    Text(verbatim: "\(first) × \(second) = ?").font(.title.bold())
                    TextField(L("dino.friends.parentAnswer"), text: $answer).keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder).accessibilityIdentifier("friends.parentAnswer")
                    Button(LocalizedStringKey(confirmKey ?? (sharing ? "dino.friends.allowSharing" : "dino.next")), action: proceed)
                        .buttonStyle(DinoButtonStyle()).disabled(Int(answer) != first * second)
                        .accessibilityIdentifier("friends.parentContinue")
                    Button("dino.cancel") { dismiss() }.buttonStyle(DinoSecondaryButtonStyle())
                        .accessibilityIdentifier("friends.parentCancel")
                }.padding(24).frame(maxWidth: 500).frame(maxWidth: .infinity)
            }.background(JungleBackground(quiet: true))
        }.foregroundStyle(DinoStyle.ink).gameEnvironment()
    }
}

struct DinoFriendsView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @EnvironmentObject private var manager: FriendsManager
    @EnvironmentObject private var player: DinoPlayer
    @Environment(\.dismiss) private var dismiss
    @State private var parentAction: ParentAction?
    @State private var approvedAction: ParentAction?
    @State private var showsScoreInfo = false
    @State private var confirmsSignOut = false
    @State private var shareEpoch = 0

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let spacious = geometry.size.width >= 650 && verticalSizeClass != .compact
                let horizontal = spacious && geometry.size.width > geometry.size.height
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: spacious ? 20 : 14) {
                            header(spacious: spacious)
                            let layout = horizontal ? AnyLayout(HStackLayout(spacing: 24)) : AnyLayout(VStackLayout(spacing: spacious ? 20 : 14))
                            layout {
                                FriendsHero(appearance: player.profile.dinoAppearance ?? .standard,
                                            size: spacious ? 228 : 178)
                                    .frame(maxWidth: horizontal ? 320 : .infinity)
                                menu(spacious: spacious)
                            }
                            if spacious { closeButton(spacious: true).frame(maxWidth: 520) }
                        }
                        .padding(.horizontal, spacious ? 28 : 20).padding(.top, 14).padding(.bottom, 22)
                        .frame(maxWidth: horizontal ? 900 : spacious ? 720 : 540).frame(maxWidth: .infinity)
                        .frame(minHeight: spacious ? geometry.size.height : nil)
                    }
                    .bouncesOnlyWhenNeeded()
                    if !spacious {
                        closeButton(spacious: false)
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            .frame(maxWidth: 540).frame(maxWidth: .infinity)
                            .background(DinoStyle.paper.opacity(0.97))
                    }
                }
            }
            .background {
                LinearGradient(colors: [DinoStyle.paper, Color(dinoHex: 0xE4F1DC)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { FriendProfileView(friendID: $0) }
            .sheet(item: $parentAction, onDismiss: performApprovedAction) { action in
                DinoParentGate(sharing: action == .share,
                               explanationKey: action == .enable ? "dino.friends.connectDisclosure" : nil,
                               confirmKey: action == .enable ? "dino.friends.turnOn" : nil) {
                    approvedAction = action; parentAction = nil
                }
            }
            .alert("dino.friends.share", isPresented: $showsScoreInfo) {
                Button("dino.done", role: .cancel) {}
            } message: {
                Text("dino.friends.scoreInfoMessage")
                if manager.syncMessageKey == "dino.friends.visibilityUnavailable" {
                    Text("dino.friends.visibilityUnavailable")
                } else if manager.syncing || manager.syncMessageKey == "dino.friends.syncPending" {
                    Text("dino.friends.visibilityPending")
                }
            }
            .alert("dino.friends.signOut", isPresented: $confirmsSignOut) {
                Button("dino.cancel", role: .cancel) {}
                Button("dino.friends.disconnect", role: .destructive) { manager.disable() }
                    .accessibilityIdentifier("friends.disconnect")
            } message: {
                Text("dino.friends.signOutMessage")
            }
        }.foregroundStyle(DinoStyle.ink)
    }

    private func menu(spacious: Bool) -> some View {
        VStack(spacing: spacious ? 18 : 14) {
            invitation(spacious: spacious)
            if manager.state == .ready, !manager.friends.isEmpty { friendList }
            connectionStatus
            if manager.enabled { accountControls(spacious: spacious) }
        }
    }

    private func closeButton(spacious: Bool) -> some View {
        Button { dismiss() } label: {
            Label("dino.practice.backToLevels", systemImage: "map.fill")
        }
        .buttonStyle(DinoSecondaryButtonStyle(spacious: spacious))
        .accessibilityIdentifier("friends.close")
    }

    private func header(spacious: Bool) -> some View {
        Text("dino.friends.title")
            .font(spacious ? .system(size: 39, weight: .heavy, design: .rounded) : .system(.largeTitle, design: .rounded).weight(.heavy))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 44)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("friends.title")
    }

    @ViewBuilder private func invitation(spacious: Bool) -> some View {
        if !manager.enabled {
            invitationButton(first: true, spacious: spacious) { parentAction = .enable }
                .accessibilityIdentifier("friends.connect")
        } else if manager.authenticated {
            let first = manager.state == .ready && manager.friends.isEmpty
            if manager.canInvite {
                invitationButton(first: first, spacious: spacious) { manager.invite() }
                    .accessibilityIdentifier("friends.invite")
            } else if first {
                Text("dino.friends.empty")
                    .font(.system(.headline, design: .rounded))
                    .frame(maxWidth: .infinity).dinoCard(padding: 14)
                    .accessibilityIdentifier("friends.empty")
            }
        }
    }

    private func invitationButton(first: Bool, spacious: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(LocalizedStringKey(first ? "dino.friends.empty" : "dino.friends.invite"),
                  systemImage: "person.badge.plus")
                .padding(.vertical, 8)
                .multilineTextAlignment(.center)
        }
        .buttonStyle(DinoButtonStyle(customization: spacious))
        .environment(\.customizationTypeScale, spacious ? 1.3 : 1)
        .padding(5)
        .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 24))
    }

    private var friendList: some View {
        LazyVStack(spacing: 0) {
            HStack {
                rowLabel("dino.friends.yourFriends", icon: "person.2.fill")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .accessibilityAddTraits(.isHeader)
                Text(manager.friends.count, format: .number)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(DinoStyle.deepGreen)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Color(dinoHex: 0xE0F1D5), in: Capsule())
            }
            .accessibilityElement(children: .combine)
            .padding(.bottom, 6)

            ForEach(manager.friends) { friend in
                Divider()
                NavigationLink(value: friend.id) { FriendListRow(friend: friend) }
                    .buttonStyle(DinoPlainButtonStyle())
                    .accessibilityIdentifier("friends.profile.\(friend.id)")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20).padding(.vertical, 14)
        .dinoCard(padding: 0)
    }

    @ViewBuilder private var connectionStatus: some View {
        switch manager.state {
        case .inactive, .ready:
            EmptyView()
        case .authenticating, .loading:
            ProgressView(LocalizedStringKey(manager.state.messageKey))
                .font(.subheadline).frame(maxWidth: .infinity).dinoCard(padding: 14)
        default:
            VStack(spacing: 10) {
                Text(LocalizedStringKey(manager.state.messageKey))
                    .font(.subheadline).multilineTextAlignment(.center)
                if manager.state == .signedOut {
                    Button("dino.friends.signIn") { manager.authenticate() }.buttonStyle(DinoSecondaryButtonStyle())
                } else if manager.state == .needsPermission {
                    Button("dino.friends.load") { parentAction = .access }
                        .buttonStyle(DinoSecondaryButtonStyle())
                        .accessibilityIdentifier("friends.access")
                }
            }.frame(maxWidth: .infinity).dinoCard(padding: 14)
        }
        if let key = manager.actionMessageKey {
            Text(LocalizedStringKey(key)).font(.footnote).multilineTextAlignment(.center)
                .accessibilityIdentifier("friends.error")
        } else if manager.authenticated && !manager.canInvite && manager.friends.isEmpty {
            Text("dino.friends.inviteRestricted").font(.footnote).multilineTextAlignment(.center)
        }
    }

    private func accountControls(spacious: Bool) -> some View {
        VStack(spacing: 0) {
            scoreControl(spacious: spacious)
            if manager.authenticated {
                Divider()
                Button { parentAction = .appleProfile } label: {
                    HStack(spacing: 12) {
                        rowLabel("dino.friends.manage", icon: "gearshape.fill")
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(DinoStyle.muted).accessibilityHidden(true)
                    }
                    .frame(minHeight: spacious ? 64 : 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(DinoPlainButtonStyle())
            }
            Divider()
            Button { confirmsSignOut = true } label: {
                rowLabel("dino.friends.signOut", icon: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(DinoStyle.warning)
                    .frame(minHeight: spacious ? 64 : 52)
                    .contentShape(Rectangle())
            }
            .buttonStyle(DinoPlainButtonStyle())
            .accessibilityIdentifier("friends.signOut")
        }
        .font(.system(size: spacious ? 21 : 16, weight: .semibold, design: .rounded))
        .padding(.horizontal, 20).padding(.vertical, 6)
        .dinoCard(padding: 0)
    }

    private func scoreControl(spacious: Bool) -> some View {
        let sharesScores = manager.sharing || manager.shareWhenConnected
        return HStack(spacing: 8) {
            Image(systemName: "trophy.fill").frame(width: 24).accessibilityHidden(true)
            Text("dino.friends.share")
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            Button { showsScoreInfo = true } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: spacious ? 21 : 18, weight: .semibold))
                    .foregroundStyle(DinoStyle.muted)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(DinoPlainButtonStyle())
            .accessibilityLabel(Text("dino.friends.scoreInfo"))
            .accessibilityIdentifier("friends.scoreInfo")
            Spacer(minLength: 0)
            Toggle("dino.friends.share", isOn: Binding(get: { sharesScores }, set: { allowed in
                guard allowed != sharesScores else { return }
                DinoAnswerFeedback.shared.playSelect()
                if allowed {
                    shareEpoch += 1
                    parentAction = .share
                } else {
                    manager.stopSharing()
                }
            }))
            .labelsHidden()
            .tint(DinoStyle.green)
            .disabled(manager.authenticated && !manager.canShare && !sharesScores)
            .id(shareEpoch)
            .accessibilityIdentifier("friends.share")
        }
        .frame(minHeight: spacious ? 64 : 52)
    }

    private func rowLabel(_ title: LocalizedStringKey, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(title)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func performApprovedAction() {
        guard let action = approvedAction else { return }
        approvedAction = nil
        switch action {
        case .enable: manager.enable()
        case .access: manager.setFriendAccess(true)
        case .share: manager.allowSharing()
        case .appleProfile: manager.showAppleProfile()
        }
    }
}

private struct FriendsHero: View {
    let appearance: DinoAppearance
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            Canvas { context, size in
                let painter = JunglePainter(context: context)
                let w = size.width, h = size.height
                painter.ellipse(CGRect(x: w * 0.67 - 37, y: h * 0.17, width: 74, height: 74),
                                color: Color(dinoHex: 0xFFF1BA))
                painter.hill(x: -w * 0.18, y: h * 0.49, width: w * 0.72, height: h * 0.72,
                             color: Color(dinoHex: 0xDFEFDA))
                painter.hill(x: w * 0.51, y: h * 0.45, width: w * 0.64, height: h * 0.70,
                             color: Color(dinoHex: 0xD7EBD4))
                painter.hill(x: w * 0.06, y: h * 0.78, width: w * 0.88, height: h * 0.48,
                             color: Color(dinoHex: 0xBEE3AD))
            }
            .mask {
                LinearGradient(stops: [
                    .init(color: .clear, location: 0), .init(color: .white, location: 0.20),
                    .init(color: .white, location: 0.80), .init(color: .clear, location: 1)
                ], startPoint: .leading, endPoint: .trailing)
                .mask {
                    LinearGradient(stops: [
                        .init(color: .white, location: 0.94), .init(color: .clear, location: 1)
                    ], startPoint: .top, endPoint: .bottom)
                }
            }
            DinoAvatar(appearance: appearance)
                .frame(width: size, height: size)
                .padding(.bottom, 9)
        }
        .frame(height: size + 12)
        .accessibilityHidden(true)
    }
}

struct FriendAvatar: View {
    let friend: DinoFriend
    var size: CGFloat = 44
    var body: some View {
        Group {
            if let appearance = friend.appearance {
                DinoAvatar(appearance: appearance, portrait: true).id(appearance)
            }
            else if let image = friend.avatar { Image(uiImage: image).resizable().scaledToFill() }
            else { Image("dino-idle").resizable().scaledToFit().padding(size * 0.06) }
        }.frame(width: size, height: size).background(DinoStyle.paper)
            .clipShape(Circle()).overlay(Circle().stroke(DinoStyle.deepGreen, lineWidth: 1.5))
            .accessibilityHidden(true)
    }
}

private struct FriendListRow: View {
    let friend: DinoFriend
    var body: some View {
        HStack(spacing: 12) {
            FriendAvatar(friend: friend, size: 48)
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: friend.displayName).font(.system(.headline, design: .rounded)).lineLimit(2)
                if let next = friend.progress.nextLevel {
                    Text("dino.levelNumber \(next)").font(.subheadline)
                } else if friend.progress.allComplete {
                    Text("dino.worldComplete").font(.subheadline)
                }
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.forward")
                .font(.footnote.bold()).foregroundStyle(DinoStyle.muted)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

/// Same empty profile as `ContentUnavailableView` on iOS 17, with a plain layout before that.
private struct MissingFriendProfile: View {
    var body: some View {
        if #available(iOS 17, *) {
            ContentUnavailableView(L("dino.friends.notAvailable"), systemImage: "person.crop.circle.badge.questionmark", description: Text("dino.friends.profileUnavailable"))
        } else {
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 48))
                    .foregroundStyle(DinoStyle.muted)
                Text(verbatim: L("dino.friends.notAvailable")).font(.title2.bold()).multilineTextAlignment(.center)
                Text("dino.friends.profileUnavailable").font(.body).multilineTextAlignment(.center).foregroundStyle(DinoStyle.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct FriendProfileView: View {
    @EnvironmentObject private var manager: FriendsManager
    @State private var showsParent = false
    @State private var approved = false
    let friendID: String
    var body: some View {
        ScrollView {
            if let friend = manager.friend(friendID) {
                VStack(spacing: 20) {
                    VStack(spacing: 14) {
                        FriendAvatar(friend: friend, size: 88)
                        Text(verbatim: friend.displayName).font(.title.bold()).multilineTextAlignment(.center)
                        metric("dino.friends.next", value: friend.progress.nextLevel.map(String.init) ?? (friend.progress.allComplete ? L("dino.worldComplete") : nil))
                        if friend.progress.scoresVisible {
                            metric("dino.friends.highestKnown", value: friend.progress.highestCompletedLevel.map(String.init))
                            metric("dino.friends.totalStars", value: friend.progress.totalStars.map(String.init))
                            if let maximum = friend.progress.maximumStarsSoFar {
                                metric("dino.friends.maximum", value: String(maximum))
                            }
                            if let percentage = friend.progress.starPercentage {
                                metric("dino.friends.percentage", value: "\(percentage)%")
                            }
                        } else {
                            Text("dino.friends.scoreHidden")
                                .font(.subheadline).foregroundStyle(DinoStyle.muted)
                                .accessibilityIdentifier("friend.scoresHidden")
                        }
                    }.dinoCard()
                    if friend.progress.scoresVisible {
                        VStack(spacing: 16) {
                            Text("dino.friends.levels").font(.headline)
                            ForEach(DinoLevelCatalog.levels) { level in
                                HStack(spacing: 12) {
                                    Text("dino.levelNumber \(level.id)").font(.headline)
                                    Spacer(minLength: 0)
                                    if let result = friend.progress.levels[level.id] {
                                        VStack(alignment: .trailing, spacing: 8) {
                                            Text(LocalizedStringKey(result.completed ? "dino.friends.completed" : result.attempted ? "dino.friends.incomplete" : "dino.friends.notPlayed"))
                                                .font(.caption)
                                            if result.attempted {
                                                DinoStars(count: result.stars, size: 18)
                                                Text(verbatim: "\(result.bestCorrect)/\(level.questionCount)").font(.caption).monospacedDigit()
                                                if let seconds = result.seconds {
                                                    Label(DinoQuestionTiming.text(seconds), systemImage: "stopwatch").font(.caption).monospacedDigit()
                                                }
                                            }
                                        }
                                    } else { Text("dino.friends.notAvailable").font(.caption) }
                                }.accessibilityIdentifier("friend.level.\(level.id)")
                                if level.id != DinoLevelCatalog.levels.last?.id { Divider() }
                            }
                        }.dinoCard()
                    }
                    Button("dino.friends.appleProfile") { showsParent = true }.buttonStyle(DinoSecondaryButtonStyle())
                    Text("dino.friends.reportHelp").font(.footnote)
                }.padding(20).frame(maxWidth: 560).frame(maxWidth: .infinity)
            } else {
                MissingFriendProfile()
                    .padding(20).accessibilityIdentifier("friends.profileUnavailable")
            }
        }.background(JungleBackground(quiet: true)).foregroundStyle(DinoStyle.ink)
            .navigationTitle(Text(verbatim: L("dino.friends.profile")))
            .toolbar(.visible, for: .navigationBar)
            .sheet(isPresented: $showsParent, onDismiss: {
                if approved { approved = false; manager.showAppleProfile(friendID: friendID) }
            }) { DinoParentGate(sharing: false) { approved = true; showsParent = false } }
    }
    private func metric(_ key: String, value: String?) -> some View {
        HStack {
            Text(LocalizedStringKey(key)).font(.subheadline)
            Spacer(minLength: 8)
            Text(verbatim: value ?? L("dino.friends.notAvailable")).font(.subheadline.bold()).multilineTextAlignment(.trailing)
        }.accessibilityIdentifier("friend.metric.\(key)")
    }
}

struct FriendMapAvatars: View {
    let friends: [DinoFriend]
    var openFriend: (String) -> Void
    var openMore: () -> Void
    var body: some View {
        let group = FriendMapGroup(ids: friends.map(\.id))
        HStack(spacing: 3) {
            ForEach(group.visibleIDs, id: \.self) { id in
                if let friend = friends.first(where: { $0.id == id }) {
                    Button { openFriend(id) } label: { FriendAvatar(friend: friend, size: 28).frame(width: 44, height: 44) }
                        .buttonStyle(DinoPlainButtonStyle())
                        .accessibilityIdentifier("map.friend.\(id)")
                }
            }
            if group.additionalCount > 0 {
                Button(action: openMore) { Text(verbatim: "+\(group.additionalCount)").font(.caption.bold()).frame(minWidth: 44, minHeight: 44) }
                    .buttonStyle(DinoPlainButtonStyle())
                    .accessibilityLabel(Text("dino.friends.more \(group.additionalCount)"))
            }
        }.padding(.horizontal, 3).background(.white.opacity(0.95), in: Capsule())
    }
}

struct LevelFriendsView<Play: View>: View {
    @EnvironmentObject private var manager: FriendsManager
    @EnvironmentObject private var player: DinoPlayer
    @State private var socialSheet: LevelSocialSheet?
    @State private var showsAllFriends = false
    let levelID: Int
    var theme = LevelStartTheme(worldID: 1)
    var spacious = false
    @ViewBuilder var play: () -> Play
    private let menuSpacing: CGFloat = 12
    var body: some View {
        let friends = rankedFriends
        let visibleFriends = showsAllFriends ? friends : Array(friends.prefix(3))
        VStack(spacing: menuSpacing) {
            if hasOwnScore, let name = manager.playerDisplayName {
                ownResult(name: name)
            }
            ForEach(visibleFriends) { row in
                if let friend = row.friend { friendResult(friend) }
            }
            if friends.count > 3 {
                Button { withAnimation(.easeOut(duration: 0.2)) { showsAllFriends.toggle() } } label: {
                    Label(LocalizedStringKey(showsAllFriends ? "dino.friends.showFewerScores" : "dino.friends.showAllScores"),
                          systemImage: showsAllFriends ? "chevron.up" : "chevron.down")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(DinoPlainButtonStyle())
                .foregroundStyle(theme.ink)
                .accessibilityIdentifier("level.friends.more")
            }
            play()
            if manager.authenticated {
                shareButton
            } else {
                Button { socialSheet = .connection } label: {
                    Label("dino.friends.connect", systemImage: "person.2.fill")
                }.buttonStyle(DinoSecondaryButtonStyle(spacious: spacious))
                    .accessibilityIdentifier("level.friends.connect")
            }
        }
        .sheet(item: $socialSheet) { sheet in
            switch sheet {
            case .connection:
                DinoFriendsView().gameEnvironment()
            case .profile(let id):
                NavigationStack {
                    FriendProfileView(friendID: id)
                        .toolbar { ToolbarItem(placement: .confirmationAction) {
                            Button("dino.done") {
                                DinoAnswerFeedback.shared.playSelect()
                                socialSheet = nil
                            }.accessibilityIdentifier("friend.close")
                        } }
                }.gameEnvironment()
            }
        }
    }

    /// A finished level keeps the player's own row above the invite, before any friend has a score here.
    private var hasOwnScore: Bool {
        FriendProgress.local(player.profile).levels[levelID]?.completed == true
    }

    /// Same width and height as the level-card buttons until friend scores need the taller list.
    private var shareButton: some View {
        Group {
            if let url = DinoAppDownload.url {
                ShareLink(item: url, subject: Text("dino.friends.shareGame"), message: Text("dino.friends.shareGame.message")) {
                    Label("dino.friends.shareGame", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(DinoSecondaryButtonStyle(spacious: spacious))
                .accessibilityIdentifier("level.friends.share")
            } else {
                ShareLink(item: L("dino.friends.shareGame.message")) {
                    Label("dino.friends.shareGame", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(DinoSecondaryButtonStyle(spacious: spacious))
                .accessibilityIdentifier("level.friends.share")
            }
        }
    }

    private struct ResultRow: Identifiable {
        let id: String
        let name: String
        let result: SharedLevelResult
        var friend: DinoFriend?
    }

    /// Friend scores only. The player's finished result stays pinned above this list.
    private var rankedFriends: [ResultRow] {
        guard manager.authenticated, manager.state == .ready else { return [] }
        return manager.friends(completed: levelID).compactMap { friend -> ResultRow? in
            guard let result = friend.progress.levels[levelID] else { return nil }
            return ResultRow(id: "friend." + friend.id, name: friend.displayName, result: result, friend: friend)
        }.sorted { lhs, rhs in
            let order = lhs.result.ranking(comparedTo: rhs.result)
            if order != .orderedSame { return order == .orderedAscending }
            let nameOrder = lhs.name.localizedStandardCompare(rhs.name)
            return nameOrder == .orderedSame ? lhs.id < rhs.id : nameOrder == .orderedAscending
        }
    }

    private func friendResult(_ friend: DinoFriend) -> some View {
        Button { socialSheet = .profile(friend.id) } label: {
            HStack(spacing: 10) {
                FriendAvatar(friend: friend, size: 36)
                Text(verbatim: friend.displayName)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .lineLimit(1).minimumScaleFactor(0.8).frame(maxWidth: .infinity, alignment: .leading)
                if let result = friend.progress.levels[levelID] {
                    Label(String(result.stars), systemImage: "star.fill").foregroundStyle(theme.ink)
                    Text(verbatim: result.seconds.map(DinoQuestionTiming.text) ?? "—")
                        .monospacedDigit().frame(minWidth: 44, alignment: .trailing)
                }
            }.font(.system(size: 13, weight: .bold, design: .rounded))
                .padding(.vertical, 5).frame(minHeight: 44)
                .contentShape(Rectangle())
        }.buttonStyle(DinoPlainButtonStyle())
            .accessibilityIdentifier("level.friend.\(friend.id)")
    }

    private func ownResult(name: String) -> some View {
        let result = FriendProgress.local(player.profile).levels[levelID]
        return HStack(spacing: 12) {
            DinoPortrait(appearance: player.profile.dinoAppearance ?? .standard, size: 52)
                .accessibilityIdentifier("level.ownAvatar")
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(verbatim: name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .lineLimit(2)
                        .accessibilityIdentifier("level.ownName")
                    Spacer(minLength: 0)
                    Text("dino.friends.you").font(.caption.bold()).foregroundStyle(theme.ink)
                }
                HStack(spacing: 10) {
                    Label(String(result?.stars ?? 0), systemImage: "star.fill")
                        .foregroundStyle(theme.ink).monospacedDigit()
                        .accessibilityIdentifier("level.ownScore")
                    Spacer(minLength: 0)
                    Text(verbatim: result?.seconds.map(DinoQuestionTiming.text) ?? "—")
                        .monospacedDigit().accessibilityIdentifier("level.ownTime")
                }.font(.system(size: 13, weight: .semibold, design: .rounded))
            }
        }.padding(12).background(theme.accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct DinoSocialPrivacyView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject private var language = LanguageManager.shared
    private enum SupportPage: String, Identifiable {
        case privacy, contact
        var id: String { rawValue }
        var configurationKey: String { self == .privacy ? "DinoPrivacyPolicyURL" : "DinoSafetyContact" }
    }
    @State private var parentPage: SupportPage?
    @State private var approvedURL: URL?
    private func localizedURL(for page: SupportPage) -> URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: page.configurationKey) as? String,
              var components = URLComponents(string: value),
              components.scheme?.lowercased() == "https",
              let host = components.host, !host.isEmpty else { return nil }
        components.fragment = language.effective.code == "nl" ? "nl" : "en"
        return components.url
    }
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let spacious = geometry.size.width >= 650 && verticalSizeClass != .compact
                ScrollView {
                    privacyContent(spacious: spacious)
                        .padding(24).frame(maxWidth: spacious ? 760 : 560).frame(maxWidth: .infinity)
                        .frame(minHeight: spacious ? geometry.size.height : nil)
                }.bouncesOnlyWhenNeeded()
            }.background(JungleBackground(quiet: true))
                .navigationTitle(Text(verbatim: L("dino.friends.privacy")))
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("dino.done") {
                    DinoAnswerFeedback.shared.playSelect()
                    dismiss()
                } } }
                .sheet(item: $parentPage, onDismiss: {
                    if let url = approvedURL { approvedURL = nil; openURL(url) }
                }) { page in
                    DinoParentGate(sharing: false, explanationKey: page == .privacy
                                   ? "dino.friends.externalPolicy" : "dino.friends.externalContact") {
                        approvedURL = localizedURL(for: page)
                        parentPage = nil
                    }
                }
        }.foregroundStyle(DinoStyle.ink).gameEnvironment()
    }

    private func privacyContent(spacious: Bool) -> some View {
        VStack(alignment: .leading, spacing: spacious ? 26 : 20) {
            Text("dino.friends.privacyBody")
            Text("dino.friends.reportHelp")
            // Developer-owned URLs are configurable; never invent contact details.
            if let url = localizedURL(for: .contact) {
                Button("dino.friends.contact") {
                    DinoAnswerFeedback.shared.playSelect()
                    parentPage = .contact
                }.frame(minHeight: 44)
                    .accessibilityIdentifier("privacy.contact")
                    .accessibilityValue(Text(verbatim: url.absoluteString))
            } else if let contact = Bundle.main.object(forInfoDictionaryKey: "DinoSafetyContact") as? String, !contact.isEmpty {
                Text(verbatim: contact).textSelection(.enabled)
            } else { Text("dino.friends.contactMissing").font(.footnote) }
            if let url = localizedURL(for: .privacy) {
                Button("dino.friends.fullPrivacy") {
                    DinoAnswerFeedback.shared.playSelect()
                    parentPage = .privacy
                }.frame(minHeight: 44)
                    .accessibilityIdentifier("privacy.policy")
                    .accessibilityValue(Text(verbatim: url.absoluteString))
            }
        }
        .font(spacious ? .system(size: 21, weight: .medium, design: .rounded) : .body)
        .modifier(PrivacyContentCard(spacious: spacious))
    }
}

private struct PrivacyContentCard: ViewModifier {
    let spacious: Bool
    func body(content: Content) -> some View {
        if spacious {
            content.dinoCard(padding: 28)
        } else {
            content
        }
    }
}
