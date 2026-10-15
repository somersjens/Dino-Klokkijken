import SwiftUI

struct WorldMap: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @EnvironmentObject private var player: DinoPlayer
    @EnvironmentObject private var friends: FriendsManager
    var openLevel: (LevelConfiguration) -> Void
    var openSettings: () -> Void
    var openPractice: () -> Void
    var openCompletion: () -> Void
    var openFriends: () -> Void
    var hudHeightChanged: (CGFloat) -> Void = { _ in }
    @State private var landscapeRouteOffset: CGFloat = 320
    @State private var floatingHUDHeight: CGFloat = 128
    @State private var worldsAboveHUD: Set<Int> = [1]
    @State private var selectedFriend: FriendSelection?

    var body: some View {
        GeometryReader { geometry in
            let landscape = geometry.size.width > geometry.size.height
            let routeTopClearance = max(0, min(200, (min(600, geometry.size.width) - 36) * 0.37) - 82)
            ZStack {
                Color(dinoHex: DinoWorldCatalog.worlds.last!.ground).ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                VStack(spacing: 0) {
                                    VStack(spacing: 12) {
                                        mapHeading
                                            .scaleEffect(landscape ? 0.82 : 1)
                                            .frame(height: landscape ? 174 : 212)
                                            .padding(.top, landscape ? 16 : 32)
                                        Button(action: openFriends) {
                                            HStack(spacing: 10) {
                                                Label("dino.friends.title", systemImage: "person.2.fill")
                                                Image(systemName: "chevron.right").font(.system(size: 12, weight: .heavy))
                                            }
                                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                                            .padding(.horizontal, 24).frame(minHeight: 46)
                                            .background(LinearGradient(colors: [Color(dinoHex: 0xFFFEEF), Color(dinoHex: 0xF1F2D6)], startPoint: .top, endPoint: .bottom), in: Capsule())
                                            .overlay(Capsule().strokeBorder(.white.opacity(0.9), lineWidth: 2))
                                            .shadow(color: DinoStyle.deepGreen.opacity(0.2), radius: 3, y: 4)
                                        }.buttonStyle(.plain).accessibilityIdentifier("map.friends")
                                        bossShortcut
                                    }.padding(.horizontal, 18).padding(.bottom, 12)
                                        .frame(maxWidth: 600).frame(maxWidth: .infinity)
                                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { landscapeRouteOffset = $0 }
                                    mapRoute
                                }.padding(.top, floatingHUDHeight + geometry.safeAreaInsets.top)
                                    .background { WorldMapLandscape(routeOffset: landscapeRouteOffset + floatingHUDHeight + geometry.safeAreaInsets.top + routeTopClearance) }
                                    .onGeometryChange(for: Bool.self) {
                                        $0.frame(in: .named("adventure.map.viewport")).minY <= floatingHUDHeight + 24
                                    } action: { updateVisibleWorld(1, aboveHUD: $0) }
                                ForEach(DinoWorldCatalog.worlds.dropFirst()) { world in
                                    WorldChapter(world: world, topClearance: routeTopClearance, openLevel: openLevel)
                                        .onGeometryChange(for: Bool.self) {
                                            $0.frame(in: .named("adventure.map.viewport")).minY <= floatingHUDHeight + 24
                                        } action: { updateVisibleWorld(world.id, aboveHUD: $0) }
                                }
                                comingSoon
                                if player.profile.adventureComplete {
                                    Button(action: openCompletion) {
                                        Label("dino.worldComplete", systemImage: "trophy.fill")
                                    }.buttonStyle(DinoButtonStyle(color: DinoStyle.green))
                                        .padding(.horizontal, 18).frame(maxWidth: 600).frame(maxWidth: .infinity)
                                }
                            }.padding(.bottom, 24)
                        }
                        .accessibilityIdentifier("map.route")
                        .onAppear {
                            if player.profile.dinoLevel > 0 {
                                proxy.scrollTo("node-\(player.profile.dinoLevel)", anchor: .center)
                            }
                        }
                    }.ignoresSafeArea(edges: [.top, .bottom, .horizontal])
                }.overlay(alignment: .top) {
                    AdventureHeader(level: max(1, player.profile.dinoLevel),
                                    stars: player.profile.totalStars, worldID: worldsAboveHUD.max() ?? 1,
                                    compact: verticalSizeClass == .compact, viewportHeight: geometry.size.height,
                                    control: .settings, help: openPractice, action: openSettings)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                            floatingHUDHeight = $0
                            hudHeightChanged($0)
                        }
                }
            }.coordinateSpace(name: "adventure.map.viewport")
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

    private func updateVisibleWorld(_ id: Int, aboveHUD: Bool) {
        // Geometry callbacks only change state when a chapter crosses the HUD.
        guard worldsAboveHUD.contains(id) != aboveHUD else { return }
        if aboveHUD { worldsAboveHUD.insert(id) }
        else { worldsAboveHUD.remove(id) }
    }

    private var mapHeading: some View {
        WorldTitleBanner(world: DinoWorldCatalog.world(1)!, highContrast: highContrast)
            .accessibilityIdentifier("map.world.1")
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
        routeNodes.padding(.horizontal, 18).frame(maxWidth: 600)
            .frame(maxWidth: .infinity).frame(height: 2050)
    }

    private var comingSoon: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles").font(.system(size: 32)).foregroundStyle(DinoStyle.deepGreen)
            Text("dino.comingSoon").font(.system(size: 28, weight: .heavy, design: .rounded))
                .accessibilityIdentifier("map.comingSoon")
            Text("dino.afterHundred").font(.system(size: 15, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
        }.padding(32).frame(maxWidth: .infinity)
            .background(Color(dinoHex: DinoWorldCatalog.world(10)!.ground))
    }

    private var routeNodes: some View {
        GeometryReader { g in
            let dinoSize = min(200, g.size.width * 0.37)
            let topClearance = max(0, dinoSize - 82)
            let points = (0...10).map { routePoint($0, width: g.size.width, topClearance: topClearance) }
            ZStack(alignment: .topLeading) {
                WorldRouteTrail(points: points, exitY: g.size.height)
                // Real rows provide accurate scroll anchors; positioned artwork alone does not.
                VStack(spacing: 0) {
                    ForEach(0...10, id: \.self) { index in
                        let point = points[index]
                        ZStack {
                            Group {
                                if index == 0 {
                                    startPoint
                                } else if let level = DinoLevelCatalog.level(index) {
                                    LevelNode(level: level, record: player.profile.record(index),
                                              unlocked: player.profile.isUnlocked(index),
                                              current: player.profile.dinoLevel == index,
                                              bossComplete: player.profile.worldOneComplete) { openLevel(level) }
                                }
                            }.offset(x: point.x - g.size.width / 2)
                            if player.profile.dinoLevel == index {
                                ZStack(alignment: .bottom) {
                                    Ellipse().fill(Color(dinoHex: 0x38552D).opacity(0.25))
                                        .frame(width: dinoSize * 0.48, height: dinoSize * 0.12)
                                        .blur(radius: 3).offset(y: -4)
                                    DinoCharacter(state: .happy, size: dinoSize)
                                }
                                    .allowsHitTesting(false)
                                    .accessibilityIdentifier("map.dino.\(index)")
                                    .offset(x: point.x - g.size.width / 2,
                                            y: -dinoSize / 2 + 12)
                            }
                            if index > 0, !friends.friends(at: index).isEmpty {
                                FriendMapAvatars(friends: friends.friends(at: index), openFriend: { selectedFriend = FriendSelection(id: $0) }, openMore: openFriends)
                                    .offset(x: point.x - g.size.width / 2, y: 82)
                            }
                        }.frame(width: g.size.width, height: 175).id("node-\(index)")
                    }
                }.padding(.top, topClearance - 17.5)
            }
        }.frame(height: 2050).environment(\.layoutDirection, .leftToRight)
    }

    private var startPoint: some View {
        JungleLevelStone(unlocked: true, occupied: player.profile.dinoLevel == 0, start: true, highContrast: highContrast)
            .frame(width: 96, height: 96)
            .shadow(color: DinoStyle.deepGreen.opacity(0.18), radius: 12, y: 8)
            .overlay(alignment: .bottom) {
                Text("dino.startPoint").font(.system(size: 13, weight: .heavy, design: .rounded)).fixedSize()
                    .padding(.horizontal, 18).padding(.vertical, 7)
                    .background(Color(dinoHex: 0xFFFBE1), in: Capsule())
                    .overlay(Capsule().stroke(DinoStyle.deepGreen.opacity(0.18), lineWidth: 1.5))
                    .offset(y: 25)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("dino.startPoint")).accessibilityIdentifier("map.start")
    }

    private func routePoint(_ index: Int, width: CGFloat, topClearance: CGFloat) -> CGPoint {
        let positions: [CGFloat] = [0.5, 0.28, 0.5, 0.72, 0.5, 0.28, 0.5, 0.72, 0.5, 0.28, 0.5]
        return CGPoint(x: width * positions[index], y: topClearance + 70 + CGFloat(index) * 175)
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
        Button(action: action) {
                ZStack {
                    if level.worldID == 1 {
                        JungleLevelStone(unlocked: unlocked, occupied: current, boss: level.isBoss, highContrast: highContrast)
                    } else if level.worldID == 2 {
                        SleepValleyLevelStone(unlocked: unlocked, occupied: current, boss: level.isBoss, highContrast: highContrast)
                    } else if level.worldID == 3 {
                        VolcanoLevelStone(unlocked: unlocked, occupied: current, boss: level.isBoss, highContrast: highContrast)
                    } else if level.worldID == 4 {
                        VillageLevelStone(unlocked: unlocked, occupied: current, boss: level.isBoss, highContrast: highContrast)
                    } else if level.worldID == 5 {
                        CrystalLevelStone(unlocked: unlocked, occupied: current, boss: level.isBoss, highContrast: highContrast)
                    } else {
                        if current { Circle().stroke(highContrast ? DinoStyle.deepGreen : DinoStyle.green.opacity(0.5), lineWidth: 3).padding(-9) }
                        Circle().fill(color.opacity(0.55)).offset(y: 6)
                        Circle().fill(LinearGradient(colors: [color.opacity(0.85), color], startPoint: .top, endPoint: .bottom))
                        Circle().stroke(level.isBoss ? DinoStyle.green : highContrast ? DinoStyle.ink : .white.opacity(0.6), lineWidth: level.isBoss ? 5 : 3).padding(3)
                    }
                    VStack(spacing: 1) {
                        if level.isBoss { Image(systemName: bossComplete ? "trophy.fill" : "crown.fill").font(.system(size: 24)).foregroundStyle(DinoStyle.green) }
                        if unlocked { Text(verbatim: "\(level.id)").font(.system(size: level.isBoss ? 23 : 30, weight: .heavy, design: .rounded)) }
                        else { Image(systemName: "lock.fill").font(.system(size: 23, weight: .bold)) }
                    }.foregroundStyle(level.isBoss ? .white : DinoStyle.ink)
                        .opacity(current && (level.worldID == 1 || ((2...5).contains(level.worldID) && !highContrast)) ? 0.55 : 1)
                }.frame(width: level.isBoss ? 90 : 72, height: level.isBoss ? 90 : 72)
            }
            .buttonStyle(DinoAnswerButtonStyle()).disabled(!unlocked)
            .accessibilityLabel(Text("dino.levelNumber \(level.id)"))
            .accessibilityValue(Text(LocalizedStringKey(unlocked ? "dino.unlocked" : "dino.locked")))
            .accessibilityIdentifier("map.level.\(level.id)")
            .overlay(alignment: .bottom) {
                Group {
                    if level.isBoss {
                        Text("dino.boss").font(.system(size: 11, weight: .heavy, design: .rounded)).tracking(1.5)
                    } else {
                        DinoStars(count: record.stars, size: 17, showEmpty: record.stars > 0).frame(height: 20)
                    }
                }.offset(y: 32).allowsHitTesting(false)
            }
    }
}

/// The occupied jungle stone softens beneath Dino; its rim and hit area stay clear.
private struct JungleLevelStone: View {
    var unlocked: Bool
    var occupied: Bool
    var start = false
    var boss = false
    var highContrast = false

    private var face: Color { Color(dinoHex: boss ? 0x244F52 : !unlocked ? 0xA5B69B : start ? 0xD6E99B : 0x81D349) }

    var body: some View {
        GeometryReader { geometry in
            let diameter = geometry.size.width
            ZStack {
                Circle().fill(Color(dinoHex: boss ? 0x173E3E : 0x65884B)).offset(y: 6)
                Circle().fill(LinearGradient(colors: [Color(dinoHex: 0xF5FFCA), face, Color(dinoHex: boss ? 0x30625A : 0x609F39)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle().fill(RadialGradient(colors: [Color(dinoHex: 0xFAFFDA).opacity(0.65), face.opacity(0.35), .clear],
                                            center: .init(x: 0.3, y: 0.2), startRadius: 0, endRadius: diameter * 0.8)).padding(5)
                Circle().strokeBorder(Color(dinoHex: highContrast ? 0x365B20 : 0xF9FFD5), lineWidth: highContrast ? 3 : 2.5).padding(3)
                Circle().strokeBorder(Color(dinoHex: 0x497C36).opacity(0.28), lineWidth: 1).padding(8)
                // A pale glaze fades the surface without making Dino translucent.
                if occupied {
                    Circle().fill(Color(dinoHex: 0xF6F8D5).opacity(highContrast ? 0.22 : 0.48)).padding(7)
                    Circle().stroke(Color(dinoHex: 0xF6FFD4).opacity(0.85), lineWidth: 2).padding(-5)
                    Circle().stroke(DinoStyle.green.opacity(0.25), lineWidth: 4).padding(-10)
                }
                if start {
                    Circle().stroke(Color(dinoHex: 0x729E45).opacity(0.32), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [1, 7])).padding(14)
                }
                Canvas { context, size in
                    for i in 0..<7 {
                        let angle = Double(i) * 0.9 + 0.15
                        let center = CGPoint(x: size.width / 2 + CGFloat(cos(angle)) * size.width * 0.44,
                                             y: size.height / 2 + CGFloat(sin(angle)) * size.height * 0.44)
                        context.fill(Path(ellipseIn: CGRect(x: center.x, y: center.y, width: i % 2 == 0 ? 2 : 1, height: 1)),
                                     with: .color(.white.opacity(0.65)))
                    }
                }
            }.shadow(color: Color(dinoHex: 0x3F6B32).opacity(0.18), radius: 5, y: 9)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Pale moonlit rims and a soft glaze distinguish the valley's occupied stone.
private struct SleepValleyLevelStone: View {
    let unlocked: Bool
    let occupied: Bool
    let boss: Bool
    let highContrast: Bool

    private var face: Color { Color(dinoHex: boss ? 0x3E5676 : unlocked ? 0x9ED2A3 : 0xA5B5B9) }

    var body: some View {
        GeometryReader { geometry in
            let diameter = geometry.size.width
            ZStack {
                Circle().fill(Color(dinoHex: 0x627787)).offset(y: 6)
                Circle().fill(LinearGradient(colors: [Color(dinoHex: 0xE8E5CD), Color(dinoHex: 0xA8B6C6), Color(dinoHex: 0x778AA1)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle().fill(LinearGradient(colors: [Color(dinoHex: boss ? 0x718BAD : unlocked ? 0xD2EDB4 : 0xCBD5CC), face],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)).padding(7)
                Circle().fill(RadialGradient(colors: [Color(dinoHex: 0xFFFFDF).opacity(0.4), .clear],
                                            center: .init(x: 0.27, y: 0.18), startRadius: 0, endRadius: diameter * 0.7)).padding(8)
                Circle().strokeBorder(Color(dinoHex: highContrast ? 0x344B66 : 0xFFF5CE), lineWidth: highContrast ? 3 : 2).padding(3)
                Circle().strokeBorder(Color(dinoHex: 0x526E75).opacity(0.35), lineWidth: 1).padding(9)
                if occupied {
                    Circle().fill(Color(dinoHex: 0xEEF0E3).opacity(highContrast ? 0.18 : 0.46)).padding(9)
                    Circle().stroke(Color(dinoHex: 0xFFF3C2).opacity(0.9), lineWidth: 2).padding(-5)
                    Circle().stroke(Color(dinoHex: 0xFFF2BA).opacity(0.22), lineWidth: 5).padding(-10)
                }
                Canvas { context, size in
                    for i in 0..<8 {
                        let angle = Double(i) * .pi / 4 - .pi / 8
                        let x = size.width * (0.5 + CGFloat(cos(angle)) * 0.435)
                        let y = size.height * (0.5 + CGFloat(sin(angle)) * 0.435)
                        context.fill(Path(ellipseIn: CGRect(x: x - 0.8, y: y - 0.8, width: 1.6, height: 1.6)),
                                     with: .color(Color(dinoHex: 0xFFF9D8).opacity(0.9)))
                    }
                }
            }.shadow(color: Color(dinoHex: 0x415B6D).opacity(0.22), radius: 5, y: 9)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// A basalt shell catches the warm lava light, while the playable face stays clear.
private struct VolcanoLevelStone: View {
    let unlocked: Bool
    let occupied: Bool
    let boss: Bool
    let highContrast: Bool

    private var face: Color { Color(dinoHex: boss ? 0x414A61 : unlocked ? 0xA4CE87 : 0xA7A99F) }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle().fill(Color(dinoHex: 0x505366)).offset(y: 6)
                Circle().fill(LinearGradient(colors: [Color(dinoHex: 0xB8AAA5), Color(dinoHex: 0x7C7F8B), Color(dinoHex: 0x4C546A)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle().fill(LinearGradient(colors: [Color(dinoHex: boss ? 0x6D7288 : unlocked ? 0xE3E7B0 : 0xD6D1B6), face],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)).padding(8)
                Circle().strokeBorder(Color(dinoHex: highContrast ? 0x333F54 : 0xF8D6A0), lineWidth: highContrast ? 3 : 2).padding(3)
                Circle().strokeBorder(Color(dinoHex: 0x485B57).opacity(0.35), lineWidth: 1).padding(10)
                Canvas { context, size in
                    let radius = size.width * 0.44
                    for i in 0..<6 {
                        let angle = Double(i) * .pi / 3 + 0.2
                        func point(_ r: CGFloat, _ a: Double) -> CGPoint {
                            CGPoint(x: size.width / 2 + CGFloat(cos(a)) * r, y: size.height / 2 + CGFloat(sin(a)) * r)
                        }
                        var seam = Path()
                        seam.addLines([point(radius + 2, angle), point(radius, angle + 0.035), point(radius - 2, angle + 0.015)])
                        context.stroke(seam, with: .color(Color(dinoHex: 0xFFC17F).opacity(unlocked ? 0.9 : 0.4)),
                                       style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                    }
                }
                if occupied {
                    Circle().fill(Color(dinoHex: 0xFFF0CE).opacity(highContrast ? 0.18 : 0.44)).padding(10)
                    Circle().stroke(Color(dinoHex: 0xFFF2C3).opacity(0.9), lineWidth: 2).padding(-5)
                    Circle().stroke(Color(dinoHex: 0xFFCE88).opacity(0.22), lineWidth: 5).padding(-10)
                }
            }.shadow(color: Color(dinoHex: 0x4B4B5E).opacity(0.24), radius: 5, y: 9)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Sandstone paving ties the village nodes to its steps and fountain masonry.
private struct VillageLevelStone: View {
    let unlocked: Bool
    let occupied: Bool
    let boss: Bool
    let highContrast: Bool

    private var face: Color { Color(dinoHex: boss ? 0x3D645B : unlocked ? 0xA2CE7C : 0xB2BBA4) }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle().fill(Color(dinoHex: 0x9E956C)).offset(y: 6)
                Circle().fill(LinearGradient(colors: [Color(dinoHex: 0xF9E6BB), Color(dinoHex: 0xD7BE92), Color(dinoHex: 0xA29970)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle().fill(LinearGradient(colors: [Color(dinoHex: boss ? 0x719986 : unlocked ? 0xE5EEBA : 0xDCE0C4), face],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)).padding(8)
                Circle().strokeBorder(Color(dinoHex: highContrast ? 0x59664A : 0xFFF5CE), lineWidth: highContrast ? 3 : 2).padding(3)
                Circle().strokeBorder(Color(dinoHex: 0x688B54).opacity(0.35), lineWidth: 1).padding(10)
                Canvas { context, size in
                    let radius = size.width * 0.44
                    for i in 0..<8 {
                        let angle = Double(i) * .pi / 4 + .pi / 8
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        var seam = Path()
                        seam.addLines([CGPoint(x: center.x + CGFloat(cos(angle)) * (radius - 2), y: center.y + CGFloat(sin(angle)) * (radius - 2)),
                                       CGPoint(x: center.x + CGFloat(cos(angle)) * (radius + 2), y: center.y + CGFloat(sin(angle)) * (radius + 2))])
                        context.stroke(seam, with: .color(Color(dinoHex: 0x9B926B).opacity(0.65)),
                                       style: StrokeStyle(lineWidth: 1, lineCap: .round))
                    }
                    let flecks: [CGPoint] = [.init(x: 0.27, y: 0.12), .init(x: 0.77, y: 0.20), .init(x: 0.18, y: 0.76), .init(x: 0.71, y: 0.88)]
                    for point in flecks {
                        context.fill(Path(ellipseIn: CGRect(x: point.x * size.width, y: point.y * size.height, width: 2, height: 1)),
                                     with: .color(Color(dinoHex: 0xFFF9D8).opacity(0.8)))
                    }
                }
                if occupied {
                    Circle().fill(Color(dinoHex: 0xFFF5DD).opacity(highContrast ? 0.18 : 0.46)).padding(10)
                    Circle().stroke(Color(dinoHex: 0xFFF6CB).opacity(0.9), lineWidth: 2).padding(-5)
                    Circle().stroke(Color(dinoHex: 0xE9DA9B).opacity(0.25), lineWidth: 5).padding(-10)
                }
            }.shadow(color: Color(dinoHex: 0x667D4F).opacity(0.22), radius: 5, y: 9)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// A cool mineral rim and mint face echo the cave's illuminated stone terraces.
private struct CrystalLevelStone: View {
    let unlocked: Bool
    let occupied: Bool
    let boss: Bool
    let highContrast: Bool

    private var face: Color { Color(dinoHex: boss ? 0x475C7C : unlocked ? 0xA1D0B9 : 0xB0BEC0) }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle().fill(Color(dinoHex: 0x697F99)).offset(y: 6)
                Circle().fill(LinearGradient(colors: [Color(dinoHex: 0xE1E6E7), Color(dinoHex: 0xA9B7CD), Color(dinoHex: 0x7586A8)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle().fill(LinearGradient(colors: [Color(dinoHex: boss ? 0x8D9BBF : unlocked ? 0xE0F0CB : 0xDCE4DA), face],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)).padding(8)
                Circle().strokeBorder(Color(dinoHex: highContrast ? 0x445E7A : 0xE2FFF2), lineWidth: highContrast ? 3 : 2).padding(3)
                Circle().strokeBorder(Color(dinoHex: 0x547F81).opacity(0.35), lineWidth: 1).padding(10)
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    func point(_ angle: Double, _ fraction: CGFloat) -> CGPoint {
                        CGPoint(x: center.x + CGFloat(cos(angle)) * size.width * fraction,
                                y: center.y + CGFloat(sin(angle)) * size.height * fraction)
                    }
                    for i in 0..<8 {
                        let angle = Double(i) * .pi / 4 + 0.12
                        var facet = Path()
                        facet.addLines([point(angle - 0.12, 0.44), point(angle, 0.47), point(angle + 0.12, 0.44), point(angle, 0.40)])
                        facet.closeSubpath()
                        let color = Color(dinoHex: i % 2 == 0 ? 0xD6C3EF : 0xB1EAE0)
                        context.fill(facet, with: .color(color.opacity(unlocked ? 0.9 : 0.4)))
                        var glint = Path(); glint.addLines([point(angle - 0.1, 0.44), point(angle, 0.47), point(angle + 0.08, 0.44)])
                        context.stroke(glint, with: .color(Color(dinoHex: 0xF7FFF8).opacity(0.85)),
                                       style: StrokeStyle(lineWidth: 0.75, lineCap: .round))
                    }
                }
                if occupied {
                    Circle().fill(Color(dinoHex: 0xF3F9EF).opacity(highContrast ? 0.18 : 0.46)).padding(10)
                    Circle().stroke(Color(dinoHex: 0xE5FFF2).opacity(0.9), lineWidth: 2).padding(-5)
                    Circle().stroke(Color(dinoHex: 0xB7E5E5).opacity(0.27), lineWidth: 5).padding(-10)
                }
            }.shadow(color: Color(dinoHex: 0x536F84).opacity(0.22), radius: 5, y: 9)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Each chapter uses the same shape-drawn route and spacing as the jungle.
private struct WorldChapter: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @EnvironmentObject private var player: DinoPlayer
    let world: DinoWorld
    let topClearance: CGFloat
    var openLevel: (LevelConfiguration) -> Void
    @State private var routeOffset: CGFloat = 196
    private let positions: [CGFloat] = [0.28, 0.5, 0.72, 0.5, 0.28, 0.5, 0.72, 0.5, 0.28, 0.5]

    var body: some View {
        VStack(spacing: 0) {
            WorldTitleBanner(world: world, highContrast: highContrast)
                .padding(.horizontal, 18).padding(.top, world.id == 5 ? 136 : world.id == 4 ? 126 : world.id == 3 ? 106 : world.id == 2 ? 88 : 18).padding(.bottom, 10)
                .frame(maxWidth: 600).frame(maxWidth: .infinity)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { routeOffset = $0 + topClearance }
                .accessibilityIdentifier("map.world.\(world.id)")
            Color.clear.frame(height: topClearance)
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    ForEach(Array(world.levels.enumerated()), id: \.element) { index, id in
                        let level = DinoLevelCatalog.level(id)!
                        let dinoSize = min(200, geometry.size.width * 0.37)
                        ZStack {
                            LevelNode(level: level, record: player.profile.record(id),
                                      unlocked: player.profile.isUnlocked(id),
                                      current: player.profile.dinoLevel == id,
                                      bossComplete: player.profile.worldComplete(world.id)) { openLevel(level) }
                            if player.profile.dinoLevel == id {
                                ZStack(alignment: .bottom) {
                                    Ellipse().fill(Color(dinoHex: 0x38552D).opacity(0.25))
                                        .frame(width: dinoSize * 0.48, height: dinoSize * 0.12)
                                        .blur(radius: 3).offset(y: -4)
                                    DinoCharacter(state: .happy, size: dinoSize)
                                }
                                    .offset(y: -dinoSize / 2 + 12).allowsHitTesting(false)
                                    .accessibilityIdentifier("map.dino.\(id)")
                            }
                        }.offset(x: geometry.size.width * (positions[index] - 0.5))
                            .frame(width: geometry.size.width, height: 175)
                            .id("node-\(id)")
                    }
                }.padding(.top, -7.5)
                }
            }.frame(height: 1850).padding(.horizontal, 18)
                .frame(maxWidth: 600).frame(maxWidth: .infinity)
        }.background {
            ZStack {
                ThemedWorldLandscape(world: world, routeOffset: routeOffset)
                GeometryReader { geometry in
                    let points = positions.enumerated().map {
                        CGPoint(x: geometry.size.width * $0.element, y: routeOffset + 80 + CGFloat($0.offset) * 175)
                    }
                    WorldRouteTrail(points: points, entryY: 0, exitY: geometry.size.height)
                }.padding(.horizontal, 18).frame(maxWidth: 600).frame(maxWidth: .infinity)
            }.allowsHitTesting(false).accessibilityHidden(true)
        }
            .background(Color(dinoHex: world.ground))
            .environment(\.layoutDirection, .leftToRight)
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
                if level.isBoss {
                    WorldThemePreview(world: DinoWorldCatalog.world(level.worldID)!)
                        .frame(width: 240, height: 160)
                        .accessibilityIdentifier("level.bossArtwork.\(level.worldID)")
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                else {
                    HStack(spacing: 20) {
                        DinoCharacter(size: 72)
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
                LevelFriendsView(levelID: level.id)
                Button("dino.map") { if let close { close() } else { dismiss() } }.buttonStyle(DinoSecondaryButtonStyle())
            }.padding(26).frame(maxWidth: 450).frame(maxWidth: .infinity)
        }.background(JungleBackground(quiet: true)).foregroundStyle(DinoStyle.ink)
    }
}

/// The start card and game share one scene, so Play never waits for a sheet dismissal.
struct LevelStartOverlay: View {
    let level: LevelConfiguration
    let hudHeight: CGFloat
    var start: () -> Void
    var close: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let top = min(hudHeight + 14, max(14, geometry.size.height - 180))
            ZStack(alignment: .top) {
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
                       height: min(level.isBoss ? 640 : 570, geometry.size.height - top - 16))
                .background(Color(dinoHex: 0xF6FAE9))
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: .black.opacity(0.14), radius: 20, y: 8)
                .accessibilityIdentifier("level.startCard")
                .padding(.top, top)
                .offset(y: dragOffset)
                .transition(reduceMotion ? .opacity : .scale(scale: 0.95, anchor: .top).combined(with: .opacity))
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
