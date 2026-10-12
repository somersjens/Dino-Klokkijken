import SwiftUI

struct WorldMap: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @EnvironmentObject private var player: DinoPlayer
    @EnvironmentObject private var friends: FriendsManager
    var openLevel: (LevelConfiguration) -> Void
    var openSettings: () -> Void
    var openCompletion: () -> Void
    var openFriends: () -> Void
    @State private var landscapeRouteOffset: CGFloat = 320
    @State private var selectedFriend: FriendSelection?

    var body: some View {
        ZStack {
            Color(dinoHex: WorldLandscapePalette.nextHorizon.ground).ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            VStack(spacing: 18) {
                                mapHeading
                                Button(action: openFriends) {
                                    Label("dino.friends.title", systemImage: "person.2.fill")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .padding(.horizontal, 18).frame(minHeight: 44)
                                        .background(.white.opacity(0.75), in: Capsule())
                                }.buttonStyle(.plain).accessibilityIdentifier("map.friends")
                                bossShortcut
                            }.padding(.horizontal, 18).padding(.bottom, 12)
                                .frame(maxWidth: 600).frame(maxWidth: .infinity)
                                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { landscapeRouteOffset = $0 }
                            mapRoute
                            if player.profile.worldOneComplete {
                                Button(action: openCompletion) {
                                    Label("dino.worldComplete", systemImage: "trophy.fill")
                                }.buttonStyle(DinoButtonStyle(color: DinoStyle.green))
                                    .padding(.horizontal, 18).frame(maxWidth: 600).frame(maxWidth: .infinity)
                            }
                        }.padding(.bottom, 24)
                            .background { WorldMapLandscape(routeOffset: landscapeRouteOffset) }
                    }
                    .onAppear {
                        if player.profile.dinoLevel > 0 {
                            proxy.scrollTo("node-\(player.profile.dinoLevel)", anchor: .center)
                        }
                    }
                }
            }.safeAreaInset(edge: .top, spacing: 0) {
                AdventureHeader(name: player.profile.name, level: max(1, player.profile.dinoLevel),
                                stars: player.profile.totalStars, compact: verticalSizeClass == .compact,
                                control: .settings, action: openSettings)
            }
        }
        .foregroundStyle(DinoStyle.ink)
        .sheet(item: $selectedFriend) { friend in
            NavigationStack {
                FriendProfileView(friendID: friend.id)
                    .toolbar { ToolbarItem(placement: .confirmationAction) {
                        Button("dino.done") { selectedFriend = nil }.accessibilityIdentifier("friend.close")
                    } }
            }.environmentObject(friends).gameEnvironment()
        }
    }

    private var mapHeading: some View {
        VStack(spacing: 8) {
            Text("dino.worldOne").font(.system(size: 11, weight: .heavy, design: .rounded)).tracking(3)
                .foregroundStyle(DinoStyle.deepGreen).padding(.top, 27)
            Text("dino.jungle").font(.system(size: 38, weight: .heavy, design: .rounded))
            Label("dino.wholeHours", systemImage: "clock")
                .font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
        }.frame(maxWidth: .infinity)
    }

    private var bossShortcut: some View {
        Button { if let boss = DinoLevelCatalog.level(10) { openLevel(boss) } } label: {
            HStack(spacing: 13) {
                Image(systemName: "trophy.fill").font(.system(size: 26)).foregroundStyle(DinoStyle.green)
                    .frame(width: 52, height: 52).background(DinoStyle.ink, in: RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 4) {
                    Text("dino.bossName").font(.system(size: 17, weight: .heavy, design: .rounded))
                    Text("dino.bossShortcut").font(.system(size: 12, weight: .medium, design: .rounded))
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 15, weight: .heavy))
            }.padding(12).background(.white.opacity(highContrast ? 1 : 0.8), in: RoundedRectangle(cornerRadius: 23))
                .overlay(RoundedRectangle(cornerRadius: 23).stroke(highContrast ? DinoStyle.ink : DinoStyle.green.opacity(0.5), lineWidth: highContrast ? 3 : 1.5))
                .shadow(color: DinoStyle.ink.opacity(0.05), radius: 10, y: 4)
        }.buttonStyle(.plain).accessibilityIdentifier("map.bossShortcut")
    }

    private var mapRoute: some View {
        ZStack(alignment: .top) {
            routeNodes.padding(.horizontal, 18).frame(maxWidth: 600)
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 19, weight: .bold)).foregroundStyle(Color(dinoHex: 0x578F8B))
                    .frame(width: 46, height: 46).background(.white.opacity(0.65), in: Circle())
                Text("dino.worldTwoSoon")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                Text("dino.nextAdventure")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
            }.padding(20).background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 29))
                .padding(.top, 2045)
                .accessibilityIdentifier("map.nextWorld")
        }.frame(height: 2230)
    }

    private var routeNodes: some View {
        GeometryReader { g in
            let points = (0...10).map { routePoint($0, width: g.size.width) }
            let dinoSize = min(144, g.size.width * 0.37)
            ZStack(alignment: .topLeading) {
                Path { p in
                    p.move(to: points[10])
                    p.addCurve(to: CGPoint(x: g.size.width * 0.53, y: 2210),
                               control1: CGPoint(x: g.size.width * 0.8, y: 2000),
                               control2: CGPoint(x: g.size.width * 0.2, y: 2070))
                }
                .stroke(Color(dinoHex: 0xF4E6B6).opacity(0.7), style: StrokeStyle(lineWidth: 34, lineCap: .round))
                routePath(points).stroke(Color(dinoHex: 0x78995D).opacity(0.21), style: StrokeStyle(lineWidth: 46, lineCap: .round))
                    .offset(y: 5)
                routePath(points).stroke(Color(dinoHex: 0xC9BB83), style: StrokeStyle(lineWidth: 40, lineCap: .round))
                routePath(points).stroke(Color(dinoHex: 0xF4E6B6), style: StrokeStyle(lineWidth: 34, lineCap: .round))
                routePath(points).stroke(Color(dinoHex: 0xFFF9D8).opacity(0.95), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 12]))
                // Real rows provide accurate scroll anchors; positioned artwork alone does not.
                VStack(spacing: 0) {
                    ForEach(0...10, id: \.self) { index in
                        let point = points[index]
                        ZStack {
                            Group {
                                if index == 0 {
                                    Circle().fill(.white.opacity(0.9)).frame(width: 54, height: 54)
                                        .overlay(Circle().stroke(DinoStyle.green.opacity(0.55), lineWidth: 3))
                                        .overlay(Circle().fill(DinoStyle.green.opacity(0.2)).frame(width: 18, height: 18))
                                        .accessibilityLabel(Text("dino.startPoint"))
                                        .accessibilityIdentifier("map.start")
                                } else if let level = DinoLevelCatalog.level(index) {
                                    LevelNode(level: level, record: player.profile.record(index),
                                              unlocked: player.profile.isUnlocked(index),
                                              current: player.profile.dinoLevel == index,
                                              bossComplete: player.profile.worldOneComplete) { openLevel(level) }
                                }
                            }.offset(x: point.x - g.size.width / 2, y: index == 0 ? 0 : index == 10 ? 13 : 16)
                            if player.profile.dinoLevel == index {
                                DinoCharacter(state: .happy, size: dinoSize)
                                    .allowsHitTesting(false)
                                    .accessibilityIdentifier("map.dino.\(index)")
                                    .offset(x: point.x - g.size.width / 2,
                                            y: -dinoSize / 2 - (index == 10 ? 38 : 24))
                            }
                            if index > 0, !friends.friends(at: index).isEmpty {
                                FriendMapAvatars(friends: friends.friends(at: index), openFriend: { selectedFriend = FriendSelection(id: $0) }, openMore: openFriends)
                                    .offset(x: point.x - g.size.width / 2, y: 82)
                            }
                        }.frame(width: g.size.width, height: 175).id("node-\(index)")
                    }
                }.padding(.top, 72.5)
            }
        }.frame(height: 2020).environment(\.layoutDirection, .leftToRight)
    }

    private func routePoint(_ index: Int, width: CGFloat) -> CGPoint {
        let positions: [CGFloat] = [0.28, 0.28, 0.5, 0.72, 0.5, 0.28, 0.5, 0.72, 0.5, 0.28, 0.5]
        return CGPoint(x: width * positions[index], y: 160 + CGFloat(index) * 175)
    }
    private func routePath(_ points: [CGPoint]) -> Path {
        Path { p in
            p.move(to: points[0])
            for i in 1..<points.count {
                let previous = points[i - 1], next = points[i]
                p.addCurve(to: next, control1: CGPoint(x: previous.x, y: previous.y + 88),
                           control2: CGPoint(x: next.x, y: next.y - 88))
            }
        }
    }
}

struct LevelNode: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let level: LevelConfiguration
    let record: LevelRecord
    let unlocked: Bool
    let current: Bool
    let bossComplete: Bool
    var action: () -> Void
    private var color: Color { !unlocked ? Color(dinoHex: 0xA9B8A0) : level.isBoss ? DinoStyle.ink : DinoStyle.green }
    var body: some View {
        VStack(spacing: 12) {
            Button(action: action) {
                ZStack {
                    if current { Circle().stroke(highContrast ? DinoStyle.deepGreen : DinoStyle.green.opacity(0.5), lineWidth: 3).padding(-9) }
                    Circle().fill(color.opacity(0.55)).offset(y: 6)
                    Circle().fill(LinearGradient(colors: [color.opacity(0.85), color], startPoint: .top, endPoint: .bottom))
                    Circle().stroke(level.isBoss ? DinoStyle.green : highContrast ? DinoStyle.ink : .white.opacity(0.6), lineWidth: level.isBoss ? 5 : 3).padding(3)
                    VStack(spacing: 1) {
                        if level.isBoss { Image(systemName: bossComplete ? "trophy.fill" : "crown.fill").font(.system(size: 24)).foregroundStyle(DinoStyle.green) }
                        if unlocked { Text(verbatim: "\(level.id)").font(.system(size: level.isBoss ? 23 : 30, weight: .heavy, design: .rounded)) }
                        else { Image(systemName: "lock.fill").font(.system(size: 23, weight: .bold)) }
                    }.foregroundStyle(level.isBoss ? .white : DinoStyle.ink)
                }.frame(width: level.isBoss ? 90 : 72, height: level.isBoss ? 90 : 72)
            }
            .buttonStyle(DinoAnswerButtonStyle()).disabled(!unlocked)
            .accessibilityLabel(Text("dino.levelNumber \(level.id)"))
            .accessibilityValue(Text(LocalizedStringKey(unlocked ? "dino.unlocked" : "dino.locked")))
            .accessibilityIdentifier("map.level.\(level.id)")
            if level.isBoss {
                Text("dino.boss").font(.system(size: 11, weight: .heavy, design: .rounded)).tracking(1.5)
            } else {
                DinoStars(count: record.stars, size: 17, showEmpty: record.stars > 0).frame(height: 20)
            }
        }
    }
}

struct LevelInfoPanel: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @EnvironmentObject private var player: DinoPlayer
    @Environment(\.dismiss) private var dismiss
    let level: LevelConfiguration
    var start: () -> Void
    var close: (() -> Void)? = nil
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if level.isBoss { ClockGate(size: 170, theme: player.profile.clockTheme) }
                else {
                    HStack(spacing: 20) {
                        DinoCharacter(size: 100)
                        Image(systemName: level.icon).font(.system(size: 44, weight: .bold)).foregroundStyle(DinoStyle.green)
                    }
                }
                Text("dino.levelNumber \(level.id)").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                Text(LocalizedStringKey(level.titleKey)).font(.system(size: 28, weight: .heavy, design: .rounded)).multilineTextAlignment(.center)
                if level.isBoss {
                    HStack(spacing: 8) { ForEach(0..<10) { _ in Image(systemName: "diamond.fill").foregroundStyle(DinoStyle.green) } }
                    VStack(spacing: 10) {
                        Label("dino.bossPerfectRule", systemImage: "trophy.fill")
                        Label("dino.bossNormalRule", systemImage: "star.fill")
                    }.font(.system(size: 14, weight: .semibold, design: .rounded)).multilineTextAlignment(.center)
                } else {
                    DinoStars(count: player.profile.record(level.id).stars, size: 28)
                }
                Button(action: start) { Label("dino.play", systemImage: "play.fill") }
                    .buttonStyle(DinoButtonStyle()).accessibilityIdentifier("level.play")
                Button("dino.map") { if let close { close() } else { dismiss() } }.buttonStyle(DinoSecondaryButtonStyle())
                LevelFriendsView(levelID: level.id)
            }.padding(26).frame(maxWidth: 450).frame(maxWidth: .infinity)
        }.background(JungleBackground(quiet: true)).foregroundStyle(DinoStyle.ink)
    }
}

/// The start card and game share one scene, so Play never waits for a sheet dismissal.
struct LevelStartOverlay: View {
    let level: LevelConfiguration
    var start: () -> Void
    var close: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.28).ignoresSafeArea()
                    .onTapGesture(perform: close).transition(.opacity)
                VStack(spacing: 0) {
                    Capsule().fill(DinoStyle.ink.opacity(0.15)).frame(width: 36, height: 5)
                        .frame(maxWidth: .infinity).frame(height: 28).contentShape(Rectangle())
                        .gesture(DragGesture()
                            .onChanged { dragOffset = max(0, $0.translation.height) }
                            .onEnded {
                                if $0.translation.height > 70 || $0.predictedEndTranslation.height > 130 { close() }
                                else { withAnimation(.easeOut(duration: 0.2)) { dragOffset = 0 } }
                            })
                        .accessibilityHidden(true)
                    LevelInfoPanel(level: level, start: start, close: close)
                }
                .frame(width: min(540, geometry.size.width - 24),
                       height: min(level.isBoss ? 640 : 430, geometry.size.height - 20))
                .background(Color(dinoHex: 0xF6FAE9))
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: .black.opacity(0.14), radius: 20, y: 8)
                .padding(.bottom, 10)
                .offset(y: dragOffset)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                .accessibilityAddTraits(.isModal)
            }
        }
    }
}

struct ClockGate: View {
    var size: CGFloat = 200
    let theme: ClockTheme
    var body: some View {
        ZStack(alignment: .bottom) {
            UnevenRoundedRectangle(topLeadingRadius: size * 0.45, topTrailingRadius: size * 0.45)
                .fill(LinearGradient(colors: [DinoStyle.deepGreen, DinoStyle.ink], startPoint: .top, endPoint: .bottom))
                .overlay(UnevenRoundedRectangle(topLeadingRadius: size * 0.45, topTrailingRadius: size * 0.45).stroke(DinoStyle.green, lineWidth: 8))
            VStack(spacing: 10) {
                Image(systemName: "crown.fill").font(.system(size: size * 0.15)).foregroundStyle(DinoStyle.green)
                AnalogClock(time: ClockTime(hour: 12), theme: theme, size: size * 0.58)
                HStack(spacing: 8) {
                    ForEach(0..<3) { _ in Image(systemName: "diamond.fill").foregroundStyle(DinoStyle.green).font(.system(size: 12)) }
                }
            }.padding(size * 0.10)
        }.frame(width: size, height: size * 1.15).padding(5).accessibilityHidden(true)
    }
}
