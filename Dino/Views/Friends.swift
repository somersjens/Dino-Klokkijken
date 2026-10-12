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

private enum ParentAction: String, Identifiable {
    case enable, access, invite, share, appleProfile
    var id: String { rawValue }
}

/// A parental gate for external/social actions. It is not legal parental consent.
struct DinoParentGate: View {
    let sharing: Bool
    var explanationKey: String? = nil
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
                    Button(LocalizedStringKey(sharing ? "dino.friends.allowSharing" : "dino.next"), action: proceed)
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
    @EnvironmentObject private var manager: FriendsManager
    @Environment(\.dismiss) private var dismiss
    @State private var parentAction: ParentAction?
    @State private var approvedAction: ParentAction?
    @State private var showsPrivacy = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statusCard
                    if manager.authenticated {
                        Button { parentAction = .invite } label: {
                            Label("dino.friends.invite", systemImage: "person.crop.circle.badge.plus")
                        }.buttonStyle(DinoButtonStyle()).disabled(!manager.canInvite)
                            .accessibilityIdentifier("friends.invite")
                        if !manager.canInvite { Text("dino.friends.inviteRestricted").font(.footnote) }
                        sharingCard
                        if manager.state == .ready && manager.friends.isEmpty {
                            VStack(spacing: 14) {
                                DinoCharacter(size: 100)
                                Text("dino.friends.empty").font(.headline)
                                Text("dino.friends.emptyMessage").font(.subheadline).multilineTextAlignment(.center)
                            }.dinoCard().accessibilityIdentifier("friends.empty")
                        }
                        LazyVStack(spacing: 12) {
                            ForEach(manager.friends) { friend in
                                NavigationLink(value: friend.id) { FriendListRow(friend: friend) }
                                    .buttonStyle(.plain).accessibilityIdentifier("friends.profile.\(friend.id)")
                            }
                        }
                        Button { parentAction = .appleProfile } label: {
                            Label("dino.friends.manage", systemImage: "person.crop.circle")
                        }.buttonStyle(DinoSecondaryButtonStyle())
                        Text("dino.friends.reportHelp").font(.footnote)
                    }
                    if let key = manager.actionMessageKey { Text(LocalizedStringKey(key)).font(.footnote).accessibilityIdentifier("friends.error") }
                    Button("dino.friends.privacy") { showsPrivacy = true }.frame(minHeight: 44)
                    if manager.enabled {
                        Button("dino.friends.disable") { manager.disable() }.frame(minHeight: 44)
                    }
                }.padding(20).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }.background(JungleBackground(quiet: true))
                .navigationTitle(Text(verbatim: L("dino.friends.title")))
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) { Button("dino.done") { dismiss() }.accessibilityIdentifier("friends.close") }
                    if manager.authenticated {
                        ToolbarItem(placement: .topBarLeading) {
                            Button { manager.refresh(); manager.scheduleSync(force: true) } label: { Image(systemName: "arrow.clockwise") }
                                .accessibilityLabel(Text("dino.friends.refresh")).accessibilityIdentifier("friends.refresh")
                        }
                    }
                }
                .navigationDestination(for: String.self) { FriendProfileView(friendID: $0) }
                .sheet(item: $parentAction, onDismiss: performApprovedAction) { action in
                    DinoParentGate(sharing: action == .share) { approvedAction = action; parentAction = nil }
                }
                .sheet(isPresented: $showsPrivacy) { DinoSocialPrivacyView() }
        }.foregroundStyle(DinoStyle.ink)
    }
    private var statusCard: some View {
        VStack(spacing: 14) {
            Label("dino.friends.title", systemImage: "person.2.fill").font(.title2.bold())
            if manager.state == .authenticating || manager.state == .loading { ProgressView().accessibilityLabel(Text("dino.friends.loading")) }
            Text(LocalizedStringKey(manager.state.messageKey)).multilineTextAlignment(.center)
            if !manager.enabled {
                Button("dino.friends.connect") { parentAction = .enable }
                    .buttonStyle(DinoButtonStyle()).accessibilityIdentifier("friends.connect")
            } else if manager.state == .needsPermission {
                Button("dino.friends.load") { parentAction = .access }.buttonStyle(DinoButtonStyle())
            } else if manager.state == .signedOut {
                Button("dino.friends.signIn") { manager.authenticate() }.buttonStyle(DinoSecondaryButtonStyle())
            } else if manager.state == .unavailable {
                Button("dino.retry") { manager.refresh() }.buttonStyle(DinoSecondaryButtonStyle())
            }
        }.dinoCard()
    }
    private var sharingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("dino.friends.sharingTitle").font(.headline)
            if manager.accountConflict { Text("dino.friends.accountConflict").font(.footnote) }
            else if !manager.canShare { Text("dino.friends.sharingRestricted").font(.footnote) }
            else if manager.sharing {
                if manager.syncing { ProgressView(L("dino.friends.syncing")) }
                if let key = manager.syncMessageKey { Text(LocalizedStringKey(key)).font(.footnote) }
                Button("dino.friends.stopSharing") { manager.stopSharing() }.frame(minHeight: 44)
                Text("dino.friends.stopSharingMessage").font(.footnote)
            } else {
                Text("dino.friends.sharingOff").font(.footnote)
                Button("dino.friends.share") { parentAction = .share }.buttonStyle(DinoSecondaryButtonStyle())
            }
        }.dinoCard()
    }
    private func performApprovedAction() {
        guard let action = approvedAction else { return }
        approvedAction = nil
        switch action {
        case .enable: manager.enable()
        case .access: manager.refresh(requestPermission: true)
        case .invite: manager.invite()
        case .share: manager.allowSharing()
        case .appleProfile: manager.showAppleProfile()
        }
    }
}

struct FriendAvatar: View {
    let friend: DinoFriend
    var size: CGFloat = 44
    var body: some View {
        Group {
            if let image = friend.avatar { Image(uiImage: image).resizable().scaledToFill() }
            else { Image("dino-idle").resizable().scaledToFit().padding(size * 0.06) }
        }.frame(width: size, height: size).background(DinoStyle.paper)
            .clipShape(Circle()).overlay(Circle().stroke(DinoStyle.deepGreen, lineWidth: 1.5))
            .accessibilityHidden(true)
    }
}

private struct FriendListRow: View {
    let friend: DinoFriend
    var body: some View {
        HStack(spacing: 14) {
            FriendAvatar(friend: friend, size: 52)
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: friend.displayName).font(.headline).lineLimit(2)
                if let next = friend.progress.nextLevel { Text("dino.friends.nextLevel \(next)").font(.subheadline) }
                else { Text(LocalizedStringKey(friend.progress.allComplete ? "dino.worldComplete" : "dino.friends.notAvailable")).font(.subheadline) }
                if let stars = friend.progress.totalStars { Text("dino.stars \(stars)").font(.footnote) }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
        }.dinoCard()
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
                        metric("dino.friends.highestKnown", value: friend.progress.highestCompletedLevel.map(String.init))
                        metric("dino.friends.next", value: friend.progress.nextLevel.map(String.init) ?? (friend.progress.allComplete ? L("dino.worldComplete") : nil))
                        metric("dino.friends.totalStars", value: friend.progress.totalStars.map(String.init))
                        metric("dino.friends.maximum", value: friend.progress.maximumStarsSoFar.map(String.init))
                        metric("dino.friends.percentage", value: friend.progress.starPercentage.map { "\($0)%" })
                    }.dinoCard()
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
                                            if !level.isBoss { DinoStars(count: result.stars, size: 18) }
                                            Text(verbatim: "\(result.bestCorrect)/\(level.questionCount)").font(.caption).monospacedDigit()
                                            if let seconds = result.seconds {
                                                Label(DinoQuestionTiming.text(seconds), systemImage: "stopwatch").font(.caption).monospacedDigit()
                                            }
                                        }
                                    }
                                } else { Text("dino.friends.notAvailable").font(.caption) }
                            }.accessibilityElement(children: .combine).accessibilityIdentifier("friend.level.\(level.id)")
                            if level.id != 10 { Divider() }
                        }
                    }.dinoCard()
                    Button("dino.friends.appleProfile") { showsParent = true }.buttonStyle(DinoSecondaryButtonStyle())
                    Text("dino.friends.reportHelp").font(.footnote)
                }.padding(20).frame(maxWidth: 560).frame(maxWidth: .infinity)
            } else {
                ContentUnavailableView(L("dino.friends.notAvailable"), systemImage: "person.crop.circle.badge.questionmark", description: Text("dino.friends.profileUnavailable"))
                    .padding(20).accessibilityIdentifier("friends.profileUnavailable")
            }
        }.background(JungleBackground(quiet: true)).foregroundStyle(DinoStyle.ink)
            .navigationTitle(Text(verbatim: L("dino.friends.profile")))
            .sheet(isPresented: $showsParent, onDismiss: {
                if approved { approved = false; manager.showAppleProfile(friendID: friendID) }
            }) { DinoParentGate(sharing: false) { approved = true; showsParent = false } }
    }
    private func metric(_ key: String, value: String?) -> some View {
        HStack {
            Text(LocalizedStringKey(key)).font(.subheadline)
            Spacer(minLength: 8)
            Text(verbatim: value ?? L("dino.friends.notAvailable")).font(.subheadline.bold()).multilineTextAlignment(.trailing)
        }.accessibilityElement(children: .combine).accessibilityIdentifier("friend.metric.\(key)")
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
                        .buttonStyle(.plain).accessibilityLabel(Text(verbatim: friend.displayName))
                        .accessibilityHint(Text("dino.friends.openProfile"))
                        .accessibilityIdentifier("map.friend.\(id)")
                }
            }
            if group.additionalCount > 0 {
                Button(action: openMore) { Text(verbatim: "+\(group.additionalCount)").font(.caption.bold()).frame(minWidth: 44, minHeight: 44) }
                    .buttonStyle(.plain).accessibilityLabel(Text("dino.friends.more \(group.additionalCount)"))
            }
        }.padding(.horizontal, 3).background(.white.opacity(0.95), in: Capsule())
    }
}

struct LevelFriendsView: View {
    @EnvironmentObject private var manager: FriendsManager
    @EnvironmentObject private var player: DinoPlayer
    @State private var socialSheet: LevelSocialSheet?
    let levelID: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if manager.authenticated && manager.state == .ready {
                let completed = manager.friends(completed: levelID)
                if !completed.isEmpty {
                    Text("dino.friends.levelResults").font(.system(size: 14, weight: .heavy, design: .rounded))
                }
                ForEach(rankedRows(completed: completed)) { row in
                    if let friend = row.friend { friendResult(friend) }
                    else { ownResult(name: row.name) }
                }
                if completed.isEmpty {
                    let known = manager.friends.allSatisfy { $0.progress.levels[levelID] != nil }
                    let ownCompleted = FriendProgress.local(player.profile).levels[levelID]?.completed == true
                    Label(LocalizedStringKey(known ? (ownCompleted ? "dino.friends.firstHere" : "dino.friends.beFirstHere") : "dino.friends.noResultsHere"),
                          systemImage: known ? "flag.checkered" : "person.2.fill")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(DinoStyle.deepGreen)
                        .accessibilityIdentifier("level.friends.empty")
                }
            } else {
                if manager.authenticated, let name = manager.playerDisplayName { ownResult(name: name) }
                Button { socialSheet = .connection } label: {
                    Label("dino.friends.connect", systemImage: "person.2.fill")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(.plain).foregroundStyle(DinoStyle.deepGreen)
                    .accessibilityIdentifier("level.friends.connect")
            }
        }.frame(maxWidth: .infinity, alignment: .leading).dinoCard()
            .sheet(item: $socialSheet) { sheet in
                switch sheet {
                case .connection:
                    DinoFriendsView().gameEnvironment()
                case .profile(let id):
                    NavigationStack {
                        FriendProfileView(friendID: id)
                            .toolbar { ToolbarItem(placement: .confirmationAction) {
                                Button("dino.done") { socialSheet = nil }.accessibilityIdentifier("friend.close")
                            } }
                    }.gameEnvironment()
                }
            }
    }

    private struct ResultRow: Identifiable {
        let id: String
        let name: String
        let result: SharedLevelResult
        var friend: DinoFriend?
    }

    private func rankedRows(completed: [DinoFriend]) -> [ResultRow] {
        var rows = completed.compactMap { friend -> ResultRow? in
            guard let result = friend.progress.levels[levelID] else { return nil }
            return ResultRow(id: "friend." + friend.id, name: friend.displayName, result: result, friend: friend)
        }
        if let name = manager.playerDisplayName, let result = FriendProgress.local(player.profile).levels[levelID] {
            rows.append(ResultRow(id: "own", name: name, result: result))
        }
        return rows.sorted { lhs, rhs in
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
                    Label(String(result.stars), systemImage: "star.fill").foregroundStyle(DinoStyle.deepGreen)
                    Text(verbatim: result.seconds.map(DinoQuestionTiming.text) ?? "—")
                        .monospacedDigit().frame(minWidth: 44, alignment: .trailing)
                        .accessibilityLabel(Text(verbatim: result.seconds.map { L("dino.friends.time") + " " + DinoQuestionTiming.text($0) } ?? L("dino.friends.timeUnavailable")))
                }
            }.font(.system(size: 13, weight: .bold, design: .rounded))
                .padding(.vertical, 5).frame(minHeight: 44)
                .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityElement(children: .combine)
            .accessibilityIdentifier("level.friend.\(friend.id)")
    }

    private func ownResult(name: String) -> some View {
        let result = FriendProgress.local(player.profile).levels[levelID]
        return HStack(spacing: 12) {
            DinoPortrait(appearance: player.profile.dinoAppearance ?? .standard, size: 52)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("dino.appearance.title"))
                .accessibilityIdentifier("level.ownAvatar")
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(verbatim: name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .lineLimit(2)
                        .accessibilityIdentifier("level.ownName")
                    Spacer(minLength: 0)
                    Text("dino.friends.you").font(.caption.bold()).foregroundStyle(DinoStyle.deepGreen)
                }
                HStack(spacing: 10) {
                    Label(String(result?.stars ?? 0), systemImage: "star.fill")
                        .foregroundStyle(DinoStyle.deepGreen).monospacedDigit()
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("dino.stars \(result?.stars ?? 0)"))
                        .accessibilityIdentifier("level.ownScore")
                    Spacer(minLength: 0)
                    Text(verbatim: result?.seconds.map(DinoQuestionTiming.text) ?? "—")
                        .monospacedDigit().accessibilityIdentifier("level.ownTime")
                        .accessibilityLabel(Text(verbatim: result?.seconds.map {
                            L("dino.friends.time") + " " + DinoQuestionTiming.text($0)
                        } ?? L("dino.friends.timeUnavailable")))
                }.font(.system(size: 13, weight: .semibold, design: .rounded))
            }
        }.padding(12).background(DinoStyle.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct DinoSocialPrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showsParent = false
    @State private var approved = false
    private var policyURL: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "DinoPrivacyPolicyURL") as? String,
              let url = URL(string: value), url.scheme == "https", url.host != nil else { return nil }
        return url
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("dino.friends.privacyBody").font(.body)
                    Text("dino.friends.reportHelp").font(.body)
                    // Developer-owned URLs are configurable; never invent contact details.
                    if let contact = Bundle.main.object(forInfoDictionaryKey: "DinoSafetyContact") as? String, !contact.isEmpty {
                        Text(verbatim: contact).textSelection(.enabled)
                    } else { Text("dino.friends.contactMissing").font(.footnote) }
                    if policyURL != nil {
                        Button("dino.friends.fullPrivacy") { showsParent = true }.frame(minHeight: 44)
                    }
                }.padding(24).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }.background(JungleBackground(quiet: true))
                .navigationTitle(Text(verbatim: L("dino.friends.privacy")))
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("dino.done") { dismiss() } } }
                .sheet(isPresented: $showsParent, onDismiss: {
                    if approved, let url = policyURL { approved = false; openURL(url) }
                }) {
                    DinoParentGate(sharing: false, explanationKey: "dino.friends.externalPolicy") { approved = true; showsParent = false }
                }
        }.foregroundStyle(DinoStyle.ink).gameEnvironment()
    }
}
