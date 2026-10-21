import SwiftUI
import UIKit

private struct MapArtworkReleasedKey: EnvironmentKey {
    static let defaultValue: (Int) -> Void = { _ in }
}

private extension EnvironmentValues {
    var mapArtworkReleased: (Int) -> Void {
        get { self[MapArtworkReleasedKey.self] }
        set { self[MapArtworkReleasedKey.self] = newValue }
    }
}

struct WorldMap: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var player: DinoPlayer
    @EnvironmentObject private var friends: FriendsManager
    var openLevel: (LevelConfiguration) -> Void
    var openSettings: () -> Void
    var openPractice: () -> Void
    var openFriends: () -> Void
    var hudHeightChanged: (CGFloat) -> Void = { _ in }
    var animatesOpening = true
    var openingFinished: () -> Void = {}
    var worldTransition: DinoWorldTransition? = nil
    @State private var landscapeRouteOffset: CGFloat = 320
    @State private var worldsAboveHUD: Set<Int> = [1]
    @State private var selectedFriend: FriendSelection?
    @State private var showsStars = false
    @State private var focusRequest = 0
    @State private var arrivedFocusRequest = 0
    @State private var readyWorlds: Set<Int> = []
    @State private var hintedLevel: Int?
    @State private var celebrationID: UUID?
    @State private var initialArtworkReady = false
    @State private var initialPositionReady = false
    @State private var openingImage: UIImage?
    @State private var preparedWorlds: Set<Int> = []
    @State private var introRevealed = false
    @State private var introFinished = false
    @State private var animationEpoch = Date()
    @State private var worldJumpStartedAt: Date?
    @State private var worldJumpFinished = false
    @State private var worldJumpImages: [String: UIImage] = [:]

    private var standingLevel: Int {
        guard let worldTransition else { return player.profile.mapLevel }
        return worldJumpFinished ? worldTransition.destinationLevel : worldTransition.sourceLevel
    }
    private var showsMapDino: Bool {
        (introFinished || !animatesOpening) && (worldTransition == nil || worldJumpFinished)
    }
    private var mapInteractive: Bool { initialPositionReady && (introFinished || !animatesOpening) && (worldTransition == nil || worldJumpFinished) }
    private var worldJumpReady: Bool {
        guard let worldTransition else { return false }
        return initialPositionReady && !worldJumpImages.isEmpty &&
            readyWorlds.contains((worldTransition.sourceLevel - 1) / 10 + 1) &&
            readyWorlds.contains((worldTransition.destinationLevel - 1) / 10 + 1)
    }
    private var openingReady: Bool {
        let world = (player.profile.mapLevel - 1) / 10 + 1
        let required = Set(max(1, world - 2)...min(10, world + 2))
        return initialPositionReady && required.isSubset(of: preparedWorlds)
    }

    private var guidedLevel: Int? { player.needsFirstLevelHint ? player.profile.mapLevel : hintedLevel }

    var body: some View {
        GeometryReader { geometry in
            let landscape = geometry.size.width > geometry.size.height
            let compact = verticalSizeClass == .compact
            // Use the actual first layout, including iPad scale. Measuring an
            // initial 128pt placeholder used to shift the whole scroll content.
            let floatingHUDHeight = (compact ? 82.0 : 128.0) * (compact ? 1 : min(1.9, max(1, geometry.size.width / 390), max(1, geometry.size.height / 480)))
            let viewportObserver = MapViewportObserver(centersLevel: standingLevel > 1,
                restoresPosition: !initialPositionReady,
                topClearance: floatingHUDHeight + geometry.safeAreaInsets.top,
                focusRequest: focusRequest, reduceMotion: reduceMotion,
                artworkReady: readyWorlds.contains((standingLevel - 1) / 10 + 1),
                ready: { initialPositionReady = true },
                focused: { arrivedFocusRequest = $0 })
            let routeTopClearance = max(0, min(200, (min(600, geometry.size.width) - 36) * 0.37) - 82)
            ZStack {
                Color(dinoHex: DinoWorldCatalog.worlds.last!.ground).ignoresSafeArea()
                if initialArtworkReady {
                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(spacing: 0) {
                                VStack(spacing: 0) {
                                    VStack(spacing: 8) {
                                        mapHeading
                                            .scaleEffect(landscape ? 0.82 : 1)
                                            .frame(height: landscape ? 174 : 190, alignment: .top)
                                            .padding(.top, landscape ? 0 : -16)
                                        friendsShortcut.opacity(friends.authenticated ? 0 : 1)
                                            .allowsHitTesting(!friends.authenticated).accessibilityHidden(friends.authenticated)
                                        bossShortcut
                                    }.padding(.horizontal, 18).padding(.bottom, 2)
                                        .frame(maxWidth: 600).frame(maxWidth: .infinity)
                                        .readGeometry(for: CGFloat.self) { $0.size.height } action: { landscapeRouteOffset = $0 }
                                    mapRoute(topClearance: routeTopClearance, viewportObserver: viewportObserver)
                                }.padding(.top, floatingHUDHeight + geometry.safeAreaInsets.top)
                                    .background {
                                        MapScenery(worldID: 1, viewportHeight: geometry.size.height) {
                                            WorldMapLandscape(routeOffset: landscapeRouteOffset + floatingHUDHeight + geometry.safeAreaInsets.top + routeTopClearance,
                                                              viewportHeight: geometry.size.height, cachesTerrain: true)
                                                .equatable()
                                        }
                                    }
                                    .readGeometry(for: Bool.self) {
                                        $0.frame(in: .named("adventure.map.viewport")).minY <= floatingHUDHeight + 24
                                    } action: { updateVisibleWorld(1, aboveHUD: $0) }
                                ForEach(DinoWorldCatalog.worlds.dropFirst()) { world in
                                    WorldChapter(world: world, topClearance: routeTopClearance,
                                                 viewportHeight: geometry.size.height, hintedLevel: guidedLevel,
                                                 viewportObserver: viewportObserver, showsDino: showsMapDino,
                                                 standingLevel: standingLevel, worldTransition: worldTransition,
                                                 worldJumpStartedAt: worldJumpStartedAt, worldJumpFinished: worldJumpFinished,
                                                 topClearanceForJump: floatingHUDHeight + geometry.safeAreaInsets.top,
                                                 openLevel: selectLevel).equatable()
                                        .readGeometry(for: Bool.self) {
                                            $0.frame(in: .named("adventure.map.viewport")).minY <= floatingHUDHeight + 24
                                        } action: { updateVisibleWorld(world.id, aboveHUD: $0) }
                                }
                                comingSoon(bottomInset: geometry.safeAreaInsets.bottom)
                            }

                        }
                        .accessibilityIdentifier("map.route")
                        .task(id: arrivedFocusRequest) {
                            guard arrivedFocusRequest > 0, arrivedFocusRequest == focusRequest else { return }
                            do {
                                if player.profile.adventureComplete {
                                    celebrationID = UUID()
                                } else {
                                    withAnimation(.easeOut(duration: 0.2)) { hintedLevel = player.profile.nextAdventureLevel }
                                }
                                try await Task.sleep(for: .seconds(5))
                                try Task.checkCancellation()
                                withAnimation(.easeOut(duration: 0.25)) {
                                    hintedLevel = nil
                                    celebrationID = nil
                                }
                            } catch { /* A new tap or leaving the map cancels the previous cue. */ }
                        }
                        .ignoresSafeArea(edges: [.top, .bottom, .horizontal])
                    }.overlay(alignment: .top) {
                        AdventureHeader(level: max(1, player.profile.dinoLevel),
                                        stars: player.profile.totalStars, worldID: worldsAboveHUD.max() ?? 1,
                                        compact: verticalSizeClass == .compact, viewportHeight: geometry.size.height,
                                        viewportWidth: geometry.size.width,
                                        control: .settings, help: openPractice, focusLevel: {
                                            hintedLevel = nil
                                            celebrationID = nil
                                            arrivedFocusRequest = 0
                                            focusRequest += 1
                                        },
                                        openStars: { showsStars = true }, action: openSettings)
                            .readGeometry(for: CGFloat.self) { $0.size.height } action: {
                                hudHeightChanged($0)
                            }
                    }
                    .opacity(initialPositionReady && (introRevealed || !animatesOpening) ? 1 : 0)
                    .allowsHitTesting(mapInteractive)
                    .disabled(!mapInteractive)
                    .accessibilityHidden(!mapInteractive)
                    .environment(\.dinoMapAnimationEpoch, animationEpoch)
                    .environment(\.dinoMapPreparing, !introFinished && animatesOpening)
                    .environment(\.dinoMapArtworkPrepared, {
                        preparedWorlds.insert($0)
                        readyWorlds.insert($0)
                    })
                    .environment(\.mapArtworkReleased, { readyWorlds.remove($0) })
                    .environment(\.dinoMapInitialWorld, (standingLevel - 1) / 10 + 1)
                }
                if let celebrationID {
                    MapCompletionConfetti().id(celebrationID)
                        .allowsHitTesting(false)
                        .accessibilityIdentifier("map.completionConfetti")
                }
            }.coordinateSpace(name: "adventure.map.viewport")
        }
        .overlayPreferenceValue(MapDinoAnchorKey.self) { anchor in
            if animatesOpening && !introFinished {
                GeometryReader { geometry in
                    MapOpeningView(world: DinoWorldCatalog.world((player.profile.mapLevel - 1) / 10 + 1)!,
                        image: openingImage, destination: anchor.map { geometry[$0] }, ready: openingReady,
                        reveal: { introRevealed = true }, finished: {
                            introFinished = true
                            openingFinished()
                        })
                }
                .zIndex(3)
            }
        }
        .overlayPreferenceValue(MapWorldJumpAnchorKey.self) { anchors in
            if let worldTransition, !worldJumpFinished {
                GeometryReader { geometry in
                    if initialPositionReady,
                       let source = anchors[worldTransition.sourceLevel],
                       let destination = anchors[worldTransition.destinationLevel] {
                        MapWorldJumpDino(source: geometry[source], destination: geometry[destination],
                                         startedAt: worldJumpStartedAt, images: worldJumpImages,
                                         idleImage: openingImage, reducedMotion: reduceMotion)
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .task(id: worldJumpReady) {
            guard worldJumpReady, worldJumpStartedAt == nil, !worldJumpFinished else { return }
            do {
                // Allow the result-to-map fade to finish before the anticipation.
                try await Task.sleep(for: .milliseconds(250))
                worldJumpStartedAt = Date()
                try await Task.sleep(for: .seconds(reduceMotion ? 0.05 : DinoAnimation.duration(.worldJump)))
                worldJumpFinished = true
            } catch { /* Leaving the map cancels the journey. */ }
        }
        .task {
            openingImage = await DinoSpriteLoader.shared.idleImage(for: player.profile.dinoAppearance ?? .standard)
            guard !Task.isCancelled else { return }
            // Commit Dino's arrival into the clock garden before constructing
            // the map tree; terrain preparation must not hide that first frame.
            if animatesOpening {
                do { try await Task.sleep(for: .milliseconds(180)) } catch { return }
            }
            initialArtworkReady = true
            if worldTransition != nil {
                worldJumpImages = await DinoSpriteLoader.shared.worldJumpImages(for: player.profile.dinoAppearance ?? .standard)
            }
        }
        .foregroundStyle(DinoStyle.ink)
        .overlay(alignment: .bottomTrailing) {
#if DEBUG
            if ProcessInfo.processInfo.environment["DINO_TEST_MAP_DIAGNOSTICS"] == "1" {
                MapRasterDiagnostics()
            }
#endif
        }
        .sheet(item: $selectedFriend) { friend in
            NavigationStack {
                FriendProfileView(friendID: friend.id)
                    .toolbar { ToolbarItem(placement: .confirmationAction) {
                        Button("dino.done") { selectedFriend = nil }.accessibilityIdentifier("friend.close")
                    } }
            }.environmentObject(friends).gameEnvironment()
        }
        .sheet(isPresented: $showsStars) {
            DinoStarsOverview().gameEnvironment()
                .presentationDetents([.large]).presentationDragIndicator(.visible)
        }
    }

    private func selectLevel(_ level: LevelConfiguration) {
        focusRequest = 0
        arrivedFocusRequest = 0
        hintedLevel = nil
        celebrationID = nil
        openLevel(level)
    }

    private func updateVisibleWorld(_ id: Int, aboveHUD: Bool) {
        // Geometry callbacks only change state when a chapter crosses the HUD.
        guard worldsAboveHUD.contains(id) != aboveHUD else { return }
        if aboveHUD { worldsAboveHUD.insert(id) }
        else { worldsAboveHUD.remove(id) }
    }

    private var mapHeading: some View {
        WorldTitleBanner(world: DinoWorldCatalog.world(1)!, highContrast: highContrast)
            .equatable()
            .accessibilityIdentifier("map.world.1")
    }

    private var friendsShortcut: some View {
        Button(action: openFriends) {
            HStack(spacing: 10) {
                Label("dino.friends.title", systemImage: "person.2.fill")
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .heavy))
            }
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .padding(.horizontal, 24).frame(minHeight: 46)
            .background(LinearGradient(colors: [Color(dinoHex: 0xFFFEEF), Color(dinoHex: 0xF1F2D6)], startPoint: .top, endPoint: .bottom), in: Capsule())
            .background {
                JungleFriendsLeaves().padding(.horizontal, -27).padding(.vertical, -5)
            }
            .overlay(Capsule().strokeBorder(.white.opacity(0.9), lineWidth: 2))
            .shadow(color: DinoStyle.deepGreen.opacity(0.2), radius: 3, y: 4)
        }.buttonStyle(.plain).accessibilityIdentifier("map.friends")
    }

    private var bossShortcut: some View {
        Button { if let boss = DinoLevelCatalog.level(10) { selectLevel(boss) } } label: {
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

    private func mapRoute(topClearance: CGFloat, viewportObserver: MapViewportObserver) -> some View {
        routeNodes(viewportObserver: viewportObserver).padding(.horizontal, 18).frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
            .frame(height: WorldRouteTrail.jungleRouteHeight(topClearance: topClearance))
    }

    private func comingSoon(bottomInset: CGFloat) -> some View {
        VStack(spacing: 18) {
            VStack(spacing: 12) {
                Image(systemName: "sparkles").font(.system(size: 30)).foregroundStyle(Color(dinoHex: 0xB38A40))
                Text("dino.comingSoon").font(.system(size: 28, weight: .heavy, design: .rounded))
                    .accessibilityIdentifier("map.comingSoon")
                Text("dino.afterHundred").font(.system(size: 15, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
            }.padding(24).frame(maxWidth: .infinity, minHeight: WorldRouteTrail.bannerHeight)
                .background {
                    RoundedRectangle(cornerRadius: 34)
                        .fill(LinearGradient(colors: [Color(dinoHex: 0xFFF4D4), Color(dinoHex: 0xE9D5A4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(RoundedRectangle(cornerRadius: 34).strokeBorder(Color(dinoHex: 0xA88B55), lineWidth: 3))
                        .overlay(RoundedRectangle(cornerRadius: 29).inset(by: 6).strokeBorder(Color(dinoHex: 0xFFF5D9), lineWidth: 2))
                        .shadow(color: DinoStyle.ink.opacity(0.16), radius: 0, y: 6)
                }
                .padding(.horizontal, 30)
                .frame(maxWidth: 600)
        }.padding(.top, WorldRouteTrail.bannerTopPadding)
            .padding(.bottom, max(40, bottomInset + 24))
            .frame(maxWidth: .infinity)
            .background { WorldMapEndingLandscape().equatable() }
    }

    private func routeNodes(viewportObserver: MapViewportObserver) -> some View {
        GeometryReader { g in
            let standingLevel = self.standingLevel
            let dinoSize = min(200, g.size.width * 0.37)
            let topClearance = max(0, dinoSize - 82)
            let points = JungleMapLayout.levelPositions.indices.map { routePoint($0, width: g.size.width, topClearance: topClearance) }
            ZStack(alignment: .topLeading) {
                WorldRouteTrail(points: points, exitY: g.size.height, exitX: g.size.width / 2).equatable()
                // Real rows provide accurate scroll anchors; positioned artwork alone does not.
                VStack(spacing: 0) {
                    ForEach(1...10, id: \.self) { id in
                        let index = id - 1
                        let point = points[index]
                        let level = DinoLevelCatalog.level(id)!
                        ZStack {
                            LevelNode(level: level, record: player.profile.record(id),
                                      unlocked: player.profile.isUnlocked(id),
                                      current: standingLevel == id,
                                      bossComplete: player.profile.worldOneComplete,
                                      showsGuide: guidedLevel == id) { selectLevel(level) }
                                .offset(x: point.x - g.size.width / 2)
                            if standingLevel == id || worldTransition?.sourceLevel == id || worldTransition?.destinationLevel == id {
                                ZStack(alignment: .bottom) {
                                    Ellipse().fill(Color(dinoHex: 0x38552D).opacity(0.25))
                                        .frame(width: dinoSize * 0.48, height: dinoSize * 0.12)
                                        .blur(radius: 3).offset(y: -4)
                                        .opacity(standingLevel == id && (worldTransition == nil || worldJumpFinished) ? 1 : 0)
                                    DinoCharacter(state: .happy, size: dinoSize, preparesReactions: false)
                                        .opacity(showsMapDino && standingLevel == id ? 1 : 0)
                                        .anchorPreference(key: MapDinoAnchorKey.self, value: .bounds) { showsMapDino || standingLevel != id ? nil : $0 }
                                        .anchorPreference(key: MapWorldJumpAnchorKey.self, value: .bounds) {
                                            worldTransition?.sourceLevel == id || worldTransition?.destinationLevel == id ? [id: $0] : [:]
                                        }
                                }
                                    .allowsHitTesting(false)
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel(Text(verbatim: "Dino"))
                                    .accessibilityIdentifier("map.dino.\(id)")
                                    .accessibilityHidden(standingLevel != id || !showsMapDino)
                                    .offset(x: point.x - g.size.width / 2,
                                            y: -dinoSize / 2 + 12)
                            }
                            if !friends.friends(at: id).isEmpty {
                                FriendMapAvatars(friends: friends.friends(at: id), openFriend: { selectedFriend = FriendSelection(id: $0) }, openMore: openFriends)
                                    .offset(x: point.x - g.size.width / 2, y: 82)
                            }
                        }.frame(width: g.size.width, height: 175).id("node-\(id)")
                            .background { if standingLevel == id { viewportObserver } }
                    }
                }.padding(.top, topClearance - 17.5)
            }
        }.environment(\.layoutDirection, .leftToRight)
    }

    private func routePoint(_ index: Int, width: CGFloat, topClearance: CGFloat) -> CGPoint {
        CGPoint(x: width * JungleMapLayout.levelPositions[index],
                y: topClearance + JungleMapLayout.firstNodeY + CGFloat(index) * WorldRouteTrail.levelSpacing)
    }

}

private struct MapDinoAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? { nil }
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

private struct MapWorldJumpAnchorKey: PreferenceKey {
    static var defaultValue: [Int: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [Int: Anchor<CGRect>], nextValue: () -> [Int: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}

/// Both anchors remain in the scrolling route; the same clock drives the camera and salto.
private struct MapWorldJumpDino: View {
    let source: CGRect
    let destination: CGRect
    let startedAt: Date?
    let images: [String: UIImage]
    let idleImage: UIImage?
    let reducedMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: startedAt == nil || reducedMotion)) { context in
            let elapsed = startedAt.map { max(0, context.date.timeIntervalSince($0)) } ?? 0
            let progress = reducedMotion && startedAt != nil ? 1 : DinoAnimation.worldJumpProgress(elapsed: elapsed)
            let sample = startedAt == nil ? DinoAnimation.sample(.idle, elapsed: 0)
                : DinoAnimation.sample(.worldJump, elapsed: elapsed, reducedMotion: reducedMotion)
            let size = source.width + (destination.width - source.width) * progress
            let center = CGPoint(x: source.midX + (destination.midX - source.midX) * progress,
                                 y: source.midY + (destination.midY - source.midY) * progress)
            ZStack {
                Ellipse().fill(Color(dinoHex: 0x38552D).opacity(0.25 * (1 + sample.height)))
                    .frame(width: size * 0.48 * (1 + sample.height), height: size * 0.12)
                    .blur(radius: 3)
                    .position(x: center.x, y: center.y + size / 2 - 10)
                if let image = images[sample.pose.asset] ?? idleImage {
                    Image(uiImage: image).resizable().scaledToFit()
                        .frame(width: size, height: size)
                        .offset(x: size * sample.pose.offsetX, y: size * sample.pose.offsetY)
                        .rotationEffect(.degrees(sample.angle - sample.pose.paintedAngle), anchor: UnitPoint(x: 0.5, y: 0.52))
                        .scaleEffect(x: sample.scaleX, y: sample.scaleY, anchor: .bottom)
                        .offset(y: size * sample.height)
                        .position(center)
                }
            }
            .transaction { $0.animation = nil }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "Dino"))
        .accessibilityIdentifier("map.worldJump")
    }
}

/// A probe at the destination keeps the map scroll exactly in step with the sprite.
private struct MapWorldJumpScrollObserver: UIViewRepresentable {
    let startedAt: Date?
    let topClearance: CGFloat
    let reducedMotion: Bool

    func makeUIView(context: Context) -> Probe { Probe() }
    func updateUIView(_ view: Probe, context: Context) { view.configure(self) }
    static func dismantleUIView(_ view: Probe, coordinator: ()) { view.stop() }

    final class Probe: UIView {
        private var configuration: MapWorldJumpScrollObserver?
        private weak var scrollView: UIScrollView?
        private var displayLink: CADisplayLink?
        private var initialOffset: CGFloat?
        private var completed = false

        init() { super.init(frame: .zero); isUserInteractionEnabled = false }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        func configure(_ value: MapWorldJumpScrollObserver) {
            configuration = value
            observe()
        }
        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window == nil { stop() } else { observe() }
        }
        override func layoutSubviews() { super.layoutSubviews(); observe() }

        private func observe() {
            guard window != nil, !completed, configuration?.startedAt != nil, displayLink == nil else { return }
            var ancestor = superview
            while let view = ancestor {
                if let scroll = view as? UIScrollView {
                    scrollView = scroll
                    initialOffset = scroll.contentOffset.y
                    let link = CADisplayLink(target: self, selector: #selector(tick))
                    link.add(to: .main, forMode: .common)
                    displayLink = link
                    tick()
                    return
                }
                ancestor = view.superview
            }
        }

        @objc private func tick() {
            guard let configuration, let startedAt = configuration.startedAt,
                  let scroll = scrollView, let initialOffset else { return }
            let elapsed = max(0, Date().timeIntervalSince(startedAt))
            let minimum = -scroll.adjustedContentInset.top
            let maximum = max(minimum, scroll.contentSize.height - scroll.bounds.height + scroll.adjustedContentInset.bottom)
            let target = convert(bounds, to: scroll).midY - (scroll.bounds.height + configuration.topClearance) / 2
            let destination = min(maximum, max(minimum, target))
            let progress = configuration.reducedMotion ? 1 : DinoAnimation.worldJumpProgress(elapsed: elapsed)
            scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x,
                                           y: initialOffset + (destination - initialOffset) * progress), animated: false)
            if progress >= 1 { completed = true; stop() }
        }

        func stop() { displayLink?.invalidate(); displayLink = nil; scrollView = nil }
    }
}

/// The clock garden is visible from the first frame. The same Dino then travels
/// into the actual map anchor while the prepared landscape opens underneath.
private struct MapOpeningView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let world: DinoWorld
    let image: UIImage?
    let destination: CGRect?
    let ready: Bool
    var reveal: () -> Void
    var finished: () -> Void
    @State private var turns = false
    @State private var progress: CGFloat = 0
    @State private var backdropOpacity = 1.0
    @State private var gardenOpacity = 0.0
    @State private var appearedAt = Date()

    var body: some View {
        GeometryReader { geometry in
            let source = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            ZStack {
                ZStack {
                    Color(dinoHex: 0xE2E9D4).ignoresSafeArea()
                    LinearGradient(colors: [Color(dinoHex: world.ground).mixed(with: .white, by: 0.35),
                                            Color(dinoHex: world.ground), Color(dinoHex: 0xA2C991)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea().opacity(gardenOpacity)
                    ForEach(0..<8, id: \.self) { index in
                        Image(systemName: "leaf.fill")
                            .font(.system(size: CGFloat(100 + index % 3 * 30)))
                            .foregroundStyle(Color(dinoHex: 0x4C865D).opacity(0.12 * gardenOpacity))
                            .rotationEffect(.degrees(Double(index * 53)))
                            .position(x: index.isMultiple(of: 2) ? 5 : geometry.size.width - 5,
                                      y: geometry.size.height * CGFloat(index + 1) / 9)
                    }
                    ZStack {
                        Circle().fill(.white.opacity(0.20)).frame(width: 264, height: 264)
                        Circle().strokeBorder(.white.opacity(0.65), lineWidth: 2).frame(width: 244, height: 244)
                        ForEach(0..<12, id: \.self) { tick in
                            Capsule().fill(DinoStyle.deepGreen.opacity(0.24))
                                .frame(width: 3, height: tick.isMultiple(of: 3) ? 13 : 7)
                                .offset(y: -111).rotationEffect(.degrees(Double(tick) * 30))
                        }
                        ZStack {
                            Capsule().fill(.white.opacity(0.7)).frame(width: 4, height: 88).offset(y: -40)
                        }.frame(width: 244, height: 244)
                            .rotationEffect(.degrees(turns && !reduceMotion ? 335 : -25))
                    }.position(source)
                }.opacity(backdropOpacity)
                if let image {
                    Image(uiImage: image).resizable().scaledToFit()
                        .shadow(color: DinoStyle.deepGreen.opacity(0.16), radius: 8, y: 5)
                        .modifier(MapOpeningFlight(progress: progress, source: source,
                                                   destination: destination ?? CGRect(x: source.x - 95, y: source.y - 95, width: 190, height: 190),
                                                   reducedMotion: reduceMotion))
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.22), value: image != nil)
            .onAppear {
                appearedAt = Date()
                withAnimation(.easeOut(duration: 0.35)) { gardenOpacity = 1 }
                withAnimation(.linear(duration: 3.2).repeatForever(autoreverses: false)) { turns = true }
            }
            .task(id: ready && image != nil && destination != nil) {
                guard ready, image != nil, destination != nil else { return }
                let remaining = max(0, 0.35 - Date().timeIntervalSince(appearedAt))
                do {
                    if remaining > 0 { try await Task.sleep(for: .seconds(remaining)) }
                    try Task.checkCancellation()
                    withAnimation(.easeInOut(duration: reduceMotion ? 0.2 : 0.55)) {
                        backdropOpacity = 0
                        reveal()
                    }
                    withAnimation(.timingCurve(0.25, 0.68, 0.25, 1, duration: reduceMotion ? 0.2 : 0.95)) {
                        progress = 1
                    }
                    try await Task.sleep(for: .seconds(reduceMotion ? 0.23 : 1.0))
                    try Task.checkCancellation()
                    finished()
                } catch { }
            }
        }.accessibilityIdentifier("map.preparing").allowsHitTesting(false)
    }
}

private struct MapOpeningFlight: AnimatableModifier {
    var progress: CGFloat
    let source: CGPoint
    let destination: CGRect
    let reducedMotion: Bool
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    func body(content: Content) -> some View {
        let t = min(1, max(0, progress))
        let side = 190 + (destination.width - 190) * t
        let arc = reducedMotion ? 0 : sin(t * .pi) * 76
        content.frame(width: side, height: side)
            .rotationEffect(.degrees(reducedMotion ? 0 : Double(sin(t * .pi)) * -7))
            .position(x: source.x + (destination.midX - source.x) * t,
                      y: source.y + (destination.midY - source.y) * t - arc)
    }
}

/// The standing row supplies the same native coordinates for restoration and
/// explicit navigation. Long trips jump beneath a snapshot of the old viewport;
/// only the destination scenery is loaded before the snapshot fades away.
private struct MapViewportObserver: UIViewRepresentable {
    let centersLevel: Bool
    let restoresPosition: Bool
    let topClearance: CGFloat
    let focusRequest: Int
    let reduceMotion: Bool
    let artworkReady: Bool
    var ready: () -> Void
    var focused: (Int) -> Void

    func makeUIView(context: Context) -> Probe { Probe(configuration: self) }
    func updateUIView(_ view: Probe, context: Context) { view.configure(self) }
    static func dismantleUIView(_ view: Probe, coordinator: ()) { view.detach() }

    final class Probe: UIView {
        var configuration: MapViewportObserver
        private weak var scrollView: UIScrollView?
        private var displayLink: CADisplayLink?
        private var positioned = false
        private var lastLayout: Layout?
        private var stableFrames = 0
        private var activeFocus = 0
        private var completedFocus = 0
        private var focusOffset: CGFloat?
        private var snapshot: UIView?

        private struct Layout: Equatable {
            let size: CGSize
            let content: CGSize
            let target: CGRect
            let clearance: CGFloat
        }

        init(configuration: MapViewportObserver) {
            self.configuration = configuration
            positioned = !configuration.restoresPosition
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        func configure(_ configuration: MapViewportObserver) {
            self.configuration = configuration
            if configuration.focusRequest == 0 {
                activeFocus = 0
                completedFocus = 0
                removeSnapshot()
            }
            if !positioned || configuration.focusRequest != completedFocus { startObserving() }
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { detach(); return }
            attach()
        }
        override func layoutSubviews() {
            super.layoutSubviews()
            if window != nil { attach() }
        }

        private func attach() {
            guard scrollView == nil else { return }
            var ancestor = superview
            while let view = ancestor {
                if let scroll = view as? UIScrollView {
                    scrollView = scroll
                    if !positioned || configuration.focusRequest != completedFocus { startObserving() }
                    return
                }
                ancestor = view.superview
            }
        }

        func detach() {
            removeSnapshot()
            scrollView = nil
            displayLink?.invalidate()
            displayLink = nil
        }

        private func startObserving() {
            guard displayLink == nil else { return }
            let link = CADisplayLink(target: self, selector: #selector(tick))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        private func removeSnapshot() {
            snapshot?.layer.removeAllAnimations()
            snapshot?.removeFromSuperview()
            snapshot = nil
        }

        private func coverViewport(_ scroll: UIScrollView) {
            guard snapshot == nil, let parent = scroll.superview,
                  let image = scroll.snapshotView(afterScreenUpdates: false) else { return }
            image.frame = scroll.frame
            image.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            image.accessibilityElementsHidden = true
            image.isUserInteractionEnabled = true
            parent.insertSubview(image, aboveSubview: scroll)
            snapshot = image
        }

        @objc private func tick() {
            guard let scroll = scrollView, window != nil else { detach(); return }
            guard scroll.bounds.height > 0, bounds.height > 0,
                  scroll.contentSize.height >= scroll.bounds.height else { return }
            let target = convert(bounds, to: scroll)
            let layout = Layout(size: scroll.bounds.size, content: scroll.contentSize,
                                target: target, clearance: configuration.topClearance)
            let minimum = -scroll.adjustedContentInset.top
            let maximum = max(minimum, scroll.contentSize.height - scroll.bounds.height + scroll.adjustedContentInset.bottom)
            let centered = min(maximum, max(minimum, target.midY - (scroll.bounds.height + configuration.topClearance) / 2))
            if !positioned {
                let desired = configuration.centersLevel ? centered : minimum
                if abs(scroll.contentOffset.y - desired) > 0.5 {
                    scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x, y: desired), animated: false)
                    stableFrames = 0
                } else {
                    stableFrames = layout == lastLayout ? stableFrames + 1 : 0
                }
                lastLayout = layout
                if stableFrames >= 2 {
                    positioned = true
                    configuration.ready()
                }
            } else if configuration.focusRequest > 0, configuration.focusRequest != completedFocus {
                let request = configuration.focusRequest
                if activeFocus != request {
                    activeFocus = request
                    stableFrames = 0
                    snapshot?.layer.removeAllAnimations()
                    snapshot?.alpha = 1
                    // Stop any deceleration or previous scroll before starting a new trip.
                    scroll.setContentOffset(scroll.contentOffset, animated: false)
                    let distance = abs(scroll.contentOffset.y - centered)
                    let shortTrip = distance <= scroll.bounds.height && !configuration.reduceMotion && snapshot == nil
                    if !shortTrip { coverViewport(scroll) }
                    focusOffset = centered
                    scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x, y: centered), animated: shortTrip)
                } else if abs((focusOffset ?? centered) - centered) > 0.5 {
                    // Rotation can change the destination while a trip is in progress.
                    focusOffset = centered
                    stableFrames = 0
                    scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x, y: centered), animated: false)
                }
                // A drag cancels a nearby animated trip. Long trips are covered
                // until their artwork is ready, while the HUD remains available.
                if scroll.isDragging {
                    completedFocus = request
                    removeSnapshot()
                } else {
                    let atDestination = abs(scroll.contentOffset.y - centered) <= 0.5
                    stableFrames = atDestination && layout == lastLayout ? stableFrames + 1 : 0
                    lastLayout = layout
                    if stableFrames >= 2 && configuration.artworkReady {
                        completedFocus = request
                        if let image = snapshot {
                            UIView.animate(withDuration: configuration.reduceMotion ? 0 : 0.22,
                                           animations: { image.alpha = 0 }, completion: { [weak self, weak image] finished in
                                guard finished, let self, self.snapshot === image,
                                      self.configuration.focusRequest == request else { return }
                                image?.removeFromSuperview()
                                self.snapshot = nil
                                self.configuration.focused(request)
                            })
                        } else {
                            configuration.focused(request)
                        }
                    }
                }
            }
            if positioned && configuration.focusRequest == completedFocus {
                displayLink?.invalidate()
                displayLink = nil
            }
        }
    }
}

/// One small cue follows its stone, so scrolling and rotation keep it aligned.
private struct MapLevelPointer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    let levelID: Int
    @State private var visible = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !visible || reduceMotion || scenePhase != .active)) { timeline in
            let wave = reduceMotion ? 0 : (sin(timeline.date.timeIntervalSinceReferenceDate * 2 * .pi / 1.3) + 1) / 2
            ZStack {
                Circle().strokeBorder(Color(dinoHex: 0xFFE29A).opacity(0.85 - wave * 0.35), lineWidth: 3)
                    .padding(-8 - wave * 4)
                    .shadow(color: DinoStyle.ink.opacity(0.25), radius: 2, y: 1)
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 54, weight: .regular))
                    .foregroundStyle(LinearGradient(colors: [.white, Color(dinoHex: 0xFFE5B3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: Color(dinoHex: 0x775A32), radius: 0, x: 1.2, y: 1.2)
                    .shadow(color: Color(dinoHex: 0x775A32), radius: 0, x: -1, y: -1)
                    .shadow(color: DinoStyle.ink.opacity(0.28), radius: 4, y: 4)
                    .rotationEffect(.degrees(-6 + wave * 5))
                    .offset(x: 33 - wave * 5, y: 61 - wave * 7)
            }
        }
        .allowsHitTesting(false)
        .accessibilityIdentifier("map.levelPointer.\(levelID)")
        .onAppear { visible = true }
        .onDisappear { visible = false }
    }
}

/// A finite burst drawn in one canvas; reduced motion uses a still celebration.
private struct MapCompletionConfetti: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var startedAt = Date()
    private let colors: [UInt32] = [0x80D64B, 0xFFD45B, 0xF483A2, 0x73CDE5, 0xB9A0ED, 0xFFF5CF]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion || scenePhase != .active)) { timeline in
            let elapsed = max(0, timeline.date.timeIntervalSince(startedAt))
            Canvas { context, size in
                drawConfetti(context: &context, size: size, elapsed: elapsed)
            }
        }
        .ignoresSafeArea()
    }

    private func drawConfetti(context: inout GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        context.opacity = reduceMotion ? 0.9 : min(1, max(0, 5 - elapsed))
        for i in 0..<96 {
            let seed = Double(i)
            let delay = Double(i % 8) * 0.07
            let progress = reduceMotion ? Double(i % 12) / 12 : max(0, elapsed - delay) / 4.2
            let drift: CGFloat = reduceMotion ? 0 : CGFloat(sin(seed * 1.7 + progress * 9)) * 24
            let x = size.width * CGFloat((i * 37) % 101) / 100 + drift
            let y = -30 + (size.height + 80) * CGFloat(progress)
            var piece = context
            piece.translateBy(x: x, y: y)
            piece.rotate(by: .degrees(seed * 47 + (reduceMotion ? 0 : progress * 540)))
            let rect = CGRect(x: -4, y: -6, width: i % 3 == 0 ? 7 : 10, height: i % 3 == 0 ? 7 : 5)
            piece.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(Color(dinoHex: colors[i % colors.count])))
        }
    }
}

/// Keep every level's layout and scroll anchor alive, but retain landscape
/// layers only near the viewport. The three-screen margin prepares artwork
/// before it enters view, including during fast scrolling and rotation.
private struct MapScenery<Content: View>: View {
    @Environment(\.dinoMapPreparing) private var preparing
    @Environment(\.dinoMapInitialWorld) private var initialWorld
    @Environment(\.mapArtworkReleased) private var artworkReleased
    let worldID: Int
    let viewportHeight: CGFloat
    @ViewBuilder var content: () -> Content
    @State private var isNearby = false

    var body: some View {
        Color.clear
            .overlay {
                if isNearby {
                    content().onDisappear { artworkReleased(worldID) }
                }
            }
            .readGeometry(for: Bool.self) { geometry in
                // A late saved level must not paint the jungle on the way to
                // its restored offset. Layout anchors remain available.
                if preparing { return abs(worldID - initialWorld) <= 2 }
                let frame = geometry.frame(in: .named("adventure.map.viewport"))
                let margin = max(1800, viewportHeight * 3)
                return frame.maxY >= -margin && frame.minY <= viewportHeight + margin
            } action: { nearby in
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) { isNearby = nearby }
            }
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct LevelNode: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let level: LevelConfiguration
    let record: LevelRecord
    let unlocked: Bool
    let current: Bool
    let bossComplete: Bool
    var showsGuide = false
    var action: () -> Void
    private var color: Color { !unlocked ? Color(dinoHex: 0xA9B8A0) : level.isBoss ? DinoStyle.ink : DinoStyle.green }
    var body: some View {
        Button(action: action) {
                ZStack {
                    let theme = DinoWorldCatalog.world(level.worldID)?.themeID ?? level.worldID
                    if level.worldID == 1 {
                        JungleLevelStone(unlocked: unlocked, occupied: current, boss: level.isBoss, highContrast: highContrast)
                    } else if theme == 2 {
                        SleepValleyLevelStone(unlocked: unlocked, occupied: current, boss: level.isBoss, highContrast: highContrast)
                    } else if level.worldID == 3 {
                        VolcanoLevelStone(unlocked: unlocked, occupied: current, boss: level.isBoss, highContrast: highContrast)
                    } else if level.worldID == 4 {
                        VillageLevelStone(unlocked: unlocked, occupied: current, boss: level.isBoss, highContrast: highContrast)
                    } else if level.worldID == 5 {
                        CrystalLevelStone(unlocked: unlocked, occupied: current, boss: level.isBoss, highContrast: highContrast)
                    } else if level.worldID == 6 {
                        CityLevelStone(unlocked: unlocked, occupied: current, boss: level.isBoss, highContrast: highContrast)
                    } else if theme == 7 {
                        DinoDesertLevelStone(unlocked: unlocked, occupied: current, boss: level.isBoss, highContrast: highContrast)
                    } else if level.worldID == 8 {
                        TimeMachineLevelStone(unlocked: unlocked, occupied: current, boss: level.isBoss, highContrast: highContrast)
                    } else if level.worldID == 9 {
                        PirateLevelStone(unlocked: unlocked, occupied: current, boss: level.isBoss, highContrast: highContrast)
                    } else if level.worldID == 10 {
                        CastleLevelStone(unlocked: unlocked, occupied: current, boss: level.isBoss, highContrast: highContrast)
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
                        .opacity(current && (level.worldID == 1 || ((2...10).contains(level.worldID) && !highContrast)) ? 0.55 : 1)
                }.frame(width: level.isBoss ? 90 : 72, height: level.isBoss ? 90 : 72)
            }
            .buttonStyle(DinoAnswerButtonStyle()).disabled(!unlocked)
            .accessibilityIdentifier("map.level.\(level.id)")
            .overlay(alignment: .bottom) {
                if !level.isBoss {
                    DinoStars(count: record.stars, size: 26, showEmpty: record.stars > 0)
                        .frame(width: 88, height: 30).offset(y: 29).allowsHitTesting(false)
                }
            }
            .overlay {
                if showsGuide {
                    MapLevelPointer(levelID: level.id)
                        .transition(.opacity)
                }
            }
    }
}

/// The occupied jungle stone softens beneath Dino; its rim and hit area stay clear.
private struct JungleLevelStone: View {
    var unlocked: Bool
    var occupied: Bool
    var boss = false
    var highContrast = false

    private var face: Color { Color(dinoHex: boss ? 0x244F52 : !unlocked ? 0xA5B69B : 0x81D349) }

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

/// Turquoise metal and warm brass edging match the city's station and streetlights.
private struct CityLevelStone: View {
    let unlocked: Bool
    let occupied: Bool
    let boss: Bool
    let highContrast: Bool

    private var face: Color { Color(dinoHex: boss ? 0x376475 : unlocked ? 0xA5D08B : 0xAFBDA8) }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle().fill(Color(dinoHex: 0x568991)).offset(y: 6)
                Circle().fill(LinearGradient(colors: [Color(dinoHex: 0xE3EFE0), Color(dinoHex: 0xA8CFC2), Color(dinoHex: 0x5D98A1)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle().fill(LinearGradient(colors: [Color(dinoHex: boss ? 0x75A6A6 : unlocked ? 0xE7EEC0 : 0xDCE3C8), face],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)).padding(8)
                Circle().strokeBorder(Color(dinoHex: highContrast ? 0x3B6773 : 0xFFF1C7), lineWidth: highContrast ? 3 : 2).padding(3)
                Circle().strokeBorder(Color(dinoHex: 0x598467).opacity(0.35), lineWidth: 1).padding(10)
                Canvas { context, size in
                    for i in 0..<6 {
                        let angle = Double(i) * .pi / 3 + .pi / 6
                        let point = CGPoint(x: size.width * (0.5 + CGFloat(cos(angle)) * 0.435),
                                            y: size.height * (0.5 + CGFloat(sin(angle)) * 0.435))
                        context.fill(Path(ellipseIn: CGRect(x: point.x - 1.7, y: point.y - 1, width: 3.4, height: 3.4)),
                                     with: .color(Color(dinoHex: 0x66948D)))
                        context.fill(Path(ellipseIn: CGRect(x: point.x - 1.4, y: point.y - 1.5, width: 2.8, height: 2.8)),
                                     with: .color(Color(dinoHex: 0xF5DE9F)))
                        context.fill(Path(ellipseIn: CGRect(x: point.x - 0.8, y: point.y - 1.1, width: 1.3, height: 1)),
                                     with: .color(Color(dinoHex: 0xFFF8D6)))
                    }
                }
                if occupied {
                    Circle().fill(Color(dinoHex: 0xFFFAE1).opacity(highContrast ? 0.18 : 0.46)).padding(10)
                    Circle().stroke(Color(dinoHex: 0xFFF6C9).opacity(0.9), lineWidth: 2).padding(-5)
                    Circle().stroke(Color(dinoHex: 0xB9D8B5).opacity(0.25), lineWidth: 5).padding(-10)
                }
            }.shadow(color: Color(dinoHex: 0x587B6B).opacity(0.22), radius: 5, y: 9)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Mossy rims gain a moonlit tint farther down the forest chapter.
private struct DayNightLevelStone: View {
    let unlocked: Bool
    let occupied: Bool
    let boss: Bool
    let highContrast: Bool
    let night: Double

    private func tint(_ day: UInt32, _ moonlight: UInt32) -> Color {
        let amount = min(1, max(0, night))
        func channel(_ shift: UInt32) -> Double {
            (Double((day >> shift) & 255) * (1 - amount) + Double((moonlight >> shift) & 255) * amount) / 255
        }
        return Color(.sRGB, red: channel(16), green: channel(8), blue: channel(0), opacity: 1)
    }
    private var face: Color {
        boss ? Color(dinoHex: 0x415F7D) : unlocked ? tint(0xA8D282, 0xA4CDBE) : tint(0xAFBBA0, 0xA9BCC9)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle().fill(tint(0x828C5B, 0x5B7696)).offset(y: 6)
                Circle().fill(LinearGradient(colors: [tint(0xF0DEAF, 0xD9E1DE), tint(0xC6C496, 0xAABBCB), tint(0x83986A, 0x718BA9)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle().fill(LinearGradient(colors: [boss ? Color(dinoHex: 0x83A4B6) : tint(0xE8EFBF, 0xE2F0DF), face],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)).padding(8)
                Circle().strokeBorder(highContrast ? Color(dinoHex: 0x415E69) : tint(0xFFF3C7, 0xE6FFF0), lineWidth: highContrast ? 3 : 2).padding(3)
                Circle().strokeBorder(tint(0x68854D, 0x5D8393).opacity(0.4), lineWidth: 1).padding(10)
                Canvas { context, size in
                    for i in 0..<8 {
                        let angle = Double(i) * .pi / 4 + 0.17
                        let x = size.width * (0.5 + CGFloat(cos(angle)) * 0.435)
                        let y = size.height * (0.5 + CGFloat(sin(angle)) * 0.435)
                        context.fill(Path(ellipseIn: CGRect(x: x - 2, y: y - 1, width: 4, height: 2.5)),
                                     with: .color(tint(0x88AB65, 0x93B9BA).opacity(unlocked ? 0.85 : 0.45)))
                        context.fill(Path(ellipseIn: CGRect(x: x - 1.5, y: y - 1, width: 2, height: 1)),
                                     with: .color(tint(0xE7EDAD, 0xE2F6E8).opacity(0.9)))
                    }
                }
                if occupied {
                    Circle().fill(tint(0xFFF9DD, 0xF0FBF1).opacity(highContrast ? 0.18 : 0.46)).padding(10)
                    Circle().stroke(tint(0xFFF6C4, 0xE4FFF0).opacity(0.9), lineWidth: 2).padding(-5)
                    Circle().stroke(tint(0xCDDE99, 0xB5D8D8).opacity(0.25), lineWidth: 5).padding(-10)
                }
            }.shadow(color: tint(0x54734A, 0x3E5B7B).opacity(0.23), radius: 5, y: 9)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Machined brass surrounds an illuminated glass inset; Dino softens its center.
private struct TimeMachineLevelStone: View {
    let unlocked: Bool
    let occupied: Bool
    let boss: Bool
    let highContrast: Bool

    var body: some View {
        ZStack {
            Circle().fill(Color(dinoHex: 0x8F8766)).offset(y: 6)
            Circle().fill(LinearGradient(colors: [Color(dinoHex: 0xFFE8AE), Color(dinoHex: 0xD4B16F), Color(dinoHex: 0x9B895D)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().fill(LinearGradient(colors: [Color(dinoHex: boss ? 0x7EAFB8 : unlocked ? 0xDAF4C6 : 0xD7DED0),
                                                  Color(dinoHex: boss ? 0x345F75 : unlocked ? 0x95C5AB : 0xA2B4AC)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)).padding(9)
            Circle().strokeBorder(Color(dinoHex: highContrast ? 0x526E73 : 0xFFF2C4), lineWidth: highContrast ? 3 : 2).padding(3)
            Circle().strokeBorder(Color(dinoHex: 0x587F83).opacity(0.65), lineWidth: 1).padding(9)
            Circle().trim(from: 0.05, to: 0.38).stroke(Color(dinoHex: 0xDAFFFF).opacity(unlocked ? 0.85 : 0.35), style: StrokeStyle(lineWidth: 2, lineCap: .round)).rotationEffect(.degrees(180)).padding(12)
            Canvas { context, size in
                for i in 0..<12 {
                    let angle = Double(i) * .pi / 6
                    let point = CGPoint(x: size.width * (0.5 + CGFloat(sin(angle)) * 0.435),
                                        y: size.height * (0.5 - CGFloat(cos(angle)) * 0.435))
                    if i % 2 == 0 {
                        context.fill(Path(ellipseIn: CGRect(x: point.x - 1.8, y: point.y - 0.7, width: 3.6, height: 3.6)), with: .color(Color(dinoHex: 0x8E7A50)))
                        context.fill(Path(ellipseIn: CGRect(x: point.x - 1.6, y: point.y - 1.6, width: 3.2, height: 3.2)),
                                     with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFF6CC), Color(dinoHex: 0xC49F60)]), startPoint: point, endPoint: .init(x: point.x + 2, y: point.y + 2)))
                    } else {
                        var tick = Path(); tick.move(to: point)
                        tick.addLine(to: .init(x: size.width * (0.5 + CGFloat(sin(angle)) * 0.40), y: size.height * (0.5 - CGFloat(cos(angle)) * 0.40)))
                        context.stroke(tick, with: .color(Color(dinoHex: 0x937F52).opacity(0.8)), lineWidth: 1)
                    }
                }
            }
            if occupied {
                Circle().fill(Color(dinoHex: 0xFFFBE6).opacity(highContrast ? 0.18 : 0.48)).padding(10)
                Circle().stroke(Color(dinoHex: 0xD7FFFF).opacity(0.9), lineWidth: 2).padding(-5)
                Circle().stroke(Color(dinoHex: 0x8EDDDD).opacity(0.25), lineWidth: 5).padding(-10)
            }
        }.shadow(color: Color(dinoHex: 0x697F7B).opacity(0.24), radius: 5, y: 9)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Rope edging and a sandstone rim surround the tide-green pirate stepping stones.
private struct PirateLevelStone: View {
    let unlocked: Bool
    let occupied: Bool
    let boss: Bool
    let highContrast: Bool

    var body: some View {
        ZStack {
            Circle().fill(Color(dinoHex: 0xA58C68)).offset(y: 6)
            Circle().fill(LinearGradient(colors: [Color(dinoHex: 0xFFF0C4), Color(dinoHex: 0xE0BF86), Color(dinoHex: 0xB89C70)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().fill(LinearGradient(colors: [Color(dinoHex: boss ? 0x75AFB8 : unlocked ? 0xE3F3BE : 0xE3E4CA),
                                                  Color(dinoHex: boss ? 0x345F75 : unlocked ? 0x94CDB2 : 0xAABFB0)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)).padding(9)
            Circle().strokeBorder(Color(dinoHex: highContrast ? 0x5C7273 : 0xFFF2CB), lineWidth: highContrast ? 3 : 2).padding(3)
            Circle().strokeBorder(Color(dinoHex: 0xB19564).opacity(0.8), lineWidth: 3).padding(6)
            Circle().strokeBorder(Color(dinoHex: 0xF8E5B4), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [1, 3])).padding(6)
            Circle().strokeBorder(Color(dinoHex: 0x6E9B91).opacity(0.5), lineWidth: 1).padding(10)
            Canvas { context, size in
                for i in 0..<7 {
                    let angle = Double(i) * .pi * 2 / 7 + 0.21
                    let x = size.width * (0.5 + CGFloat(cos(angle)) * 0.46)
                    let y = size.height * (0.5 + CGFloat(sin(angle)) * 0.46)
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.6, height: 1.1)), with: .color(Color(dinoHex: 0xC3A877).opacity(0.7)))
                    context.fill(Path(ellipseIn: CGRect(x: x - 1.8, y: y - 0.5, width: 1.2, height: 1)), with: .color(Color(dinoHex: 0xFFFADE).opacity(0.9)))
                }
            }
            if occupied {
                Circle().fill(Color(dinoHex: 0xFFFBE4).opacity(highContrast ? 0.18 : 0.48)).padding(10)
                Circle().stroke(Color(dinoHex: 0xEEFFF0).opacity(0.95), lineWidth: 2).padding(-5)
                Circle().stroke(Color(dinoHex: 0x9EE2D5).opacity(0.28), lineWidth: 5).padding(-10)
            }
        }.shadow(color: Color(dinoHex: 0x8C916A).opacity(0.25), radius: 5, y: 9)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Pale royal stone, gold edging and blue inlays mark the final ten levels.
private struct CastleLevelStone: View {
    let unlocked: Bool
    let occupied: Bool
    let boss: Bool
    let highContrast: Bool

    var body: some View {
        ZStack {
            Circle().fill(Color(dinoHex: 0x9F9F82)).offset(y: 6)
            Circle().fill(LinearGradient(colors: [Color(dinoHex: 0xFFF1C9), Color(dinoHex: 0xDCC796), Color(dinoHex: 0xAEB49D)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().fill(LinearGradient(colors: [Color(dinoHex: boss ? 0x7CA3C1 : unlocked ? 0xE5F3D4 : 0xE2E6D0),
                                                  Color(dinoHex: boss ? 0x365A7F : unlocked ? 0xA4C9BF : 0xAEBFB5)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)).padding(9)
            Circle().strokeBorder(Color(dinoHex: highContrast ? 0x4D6B7D : 0xFFF7D7), lineWidth: highContrast ? 3 : 2).padding(3)
            Circle().strokeBorder(Color(dinoHex: 0xC8A96C), lineWidth: 2).padding(7)
            Circle().strokeBorder(Color(dinoHex: 0x6D91A5).opacity(0.45), lineWidth: 1).padding(10)
            Canvas { context, size in
                for i in 0..<4 {
                    let angle = Double(i) * .pi / 2
                    let point = CGPoint(x: size.width * (0.5 + CGFloat(sin(angle)) * 0.44),
                                        y: size.height * (0.5 - CGFloat(cos(angle)) * 0.44))
                    let gem = Path { p in
                        p.addLines([.init(x: point.x, y: point.y - 3), .init(x: point.x + 2.3, y: point.y),
                                    .init(x: point.x, y: point.y + 3), .init(x: point.x - 2.3, y: point.y)])
                        p.closeSubpath()
                    }
                    context.fill(gem, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xD0E6EA), Color(dinoHex: 0x638EB8)]), startPoint: .init(x: point.x - 2, y: point.y - 3), endPoint: .init(x: point.x + 2, y: point.y + 3)))
                    context.stroke(gem, with: .color(Color(dinoHex: 0xFFF0BA)), lineWidth: 0.7)
                }
                for i in 0..<8 where i % 2 == 1 {
                    let angle = Double(i) * .pi / 4
                    let x = size.width * (0.5 + CGFloat(sin(angle)) * 0.44)
                    let y = size.height * (0.5 - CGFloat(cos(angle)) * 0.44)
                    context.fill(Path(ellipseIn: CGRect(x: x - 1.3, y: y - 1.3, width: 2.6, height: 2.6)), with: .color(Color(dinoHex: 0xFFF0BB)))
                }
            }
            if occupied {
                Circle().fill(Color(dinoHex: 0xFFFBE7).opacity(highContrast ? 0.18 : 0.48)).padding(10)
                Circle().stroke(Color(dinoHex: 0xF3FFF0).opacity(0.95), lineWidth: 2).padding(-5)
                Circle().stroke(Color(dinoHex: 0xBCDCE3).opacity(0.28), lineWidth: 5).padding(-10)
            }
        }.shadow(color: Color(dinoHex: 0x7C917E).opacity(0.25), radius: 5, y: 9)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Each chapter uses the same shape-drawn route and spacing as the jungle.
private struct WorldChapter: View, Equatable {
    @Environment(\.dinoHighContrast) private var highContrast
    @EnvironmentObject private var player: DinoPlayer
    let world: DinoWorld
    let topClearance: CGFloat
    let viewportHeight: CGFloat
    let hintedLevel: Int?
    let viewportObserver: MapViewportObserver
    let showsDino: Bool
    let standingLevel: Int
    let worldTransition: DinoWorldTransition?
    let worldJumpStartedAt: Date?
    let worldJumpFinished: Bool
    let topClearanceForJump: CGFloat
    var openLevel: (LevelConfiguration) -> Void
    private let titleTopPadding = WorldRouteTrail.bannerTopPadding
    private var routeOffset: CGFloat { WorldRouteTrail.bannerHeight + titleTopPadding + WorldRouteTrail.bannerBottomPadding + topClearance }
    private let positions = WorldRouteTrail.chapterPositions

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.world == rhs.world && lhs.topClearance == rhs.topClearance &&
        lhs.viewportHeight == rhs.viewportHeight && lhs.hintedLevel == rhs.hintedLevel && lhs.showsDino == rhs.showsDino &&
        lhs.standingLevel == rhs.standingLevel && lhs.worldTransition == rhs.worldTransition &&
        lhs.worldJumpStartedAt == rhs.worldJumpStartedAt && lhs.worldJumpFinished == rhs.worldJumpFinished &&
        lhs.topClearanceForJump == rhs.topClearanceForJump &&
        lhs.viewportObserver.restoresPosition == rhs.viewportObserver.restoresPosition &&
        lhs.viewportObserver.topClearance == rhs.viewportObserver.topClearance &&
        lhs.viewportObserver.focusRequest == rhs.viewportObserver.focusRequest &&
        lhs.viewportObserver.reduceMotion == rhs.viewportObserver.reduceMotion &&
        lhs.viewportObserver.artworkReady == rhs.viewportObserver.artworkReady
    }

    var body: some View {
        VStack(spacing: 0) {
            WorldTitleBanner(world: world, highContrast: highContrast)
                .equatable()
                .padding(.horizontal, 18).padding(.top, titleTopPadding).padding(.bottom, WorldRouteTrail.bannerBottomPadding)
                .frame(maxWidth: 600).frame(maxWidth: .infinity)
                .accessibilityIdentifier("map.world.\(world.id)")
            Color.clear.frame(height: topClearance)
            GeometryReader { geometry in
                let standingLevel = self.standingLevel
                let bossComplete = player.profile.worldComplete(world.id)
                ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    ForEach(Array(world.levels.enumerated()), id: \.element) { index, id in
                        let level = DinoLevelCatalog.level(id)!
                        let dinoSize = min(200, geometry.size.width * 0.37)
                        ZStack {
                            LevelNode(level: level, record: player.profile.record(id),
                                      unlocked: player.profile.isUnlocked(id),
                                      current: standingLevel == id,
                                      bossComplete: bossComplete,
                                      showsGuide: hintedLevel == id) { openLevel(level) }
                            if standingLevel == id || worldTransition?.sourceLevel == id || worldTransition?.destinationLevel == id {
                                ZStack(alignment: .bottom) {
                                    Ellipse().fill(Color(dinoHex: 0x38552D).opacity(0.25))
                                        .frame(width: dinoSize * 0.48, height: dinoSize * 0.12)
                                        .blur(radius: 3).offset(y: -4)
                                        .opacity(standingLevel == id && (worldTransition == nil || worldJumpFinished) ? 1 : 0)
                                    DinoCharacter(state: .happy, size: dinoSize, preparesReactions: false)
                                        .opacity(showsDino && standingLevel == id ? 1 : 0)
                                        .anchorPreference(key: MapDinoAnchorKey.self, value: .bounds) { showsDino || standingLevel != id ? nil : $0 }
                                        .anchorPreference(key: MapWorldJumpAnchorKey.self, value: .bounds) {
                                            worldTransition?.sourceLevel == id || worldTransition?.destinationLevel == id ? [id: $0] : [:]
                                        }
                                }
                                    .offset(y: -dinoSize / 2 + 12).allowsHitTesting(false)
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel(Text(verbatim: "Dino"))
                                    .accessibilityIdentifier("map.dino.\(id)")
                                    .accessibilityHidden(standingLevel != id || !showsDino)
                            }
                        }.offset(x: geometry.size.width * (positions[index] - 0.5))
                            .frame(width: geometry.size.width, height: 175)
                            .id("node-\(id)")
                            .background { if standingLevel == id { viewportObserver } }
                            .background {
                                if let worldTransition, id == worldTransition.destinationLevel, !worldJumpFinished {
                                    MapWorldJumpScrollObserver(startedAt: worldJumpStartedAt,
                                                              topClearance: topClearanceForJump, reducedMotion: viewportObserver.reduceMotion)
                                }
                            }
                    }
                }.padding(.top, -7.5)
                }
            }.frame(height: WorldRouteTrail.chapterRouteHeight(topClearance: topClearance, worldID: world.id)).padding(.horizontal, 18)
                .frame(maxWidth: 600).frame(maxWidth: .infinity)
        }.background {
            MapScenery(worldID: world.id, viewportHeight: viewportHeight) {
                ZStack(alignment: .top) {
                    ThemedWorldLandscape(world: world, routeOffset: routeOffset, viewportHeight: viewportHeight, cachesTerrain: true).equatable()
                    if world.id != 5 {
                        GeometryReader { geometry in
                            let points = positions.enumerated().map {
                                CGPoint(x: geometry.size.width * $0.element, y: routeOffset + 80 + CGFloat($0.offset) * 175)
                            }
                            WorldRouteTrail(points: points, entryY: 0, exitY: geometry.size.height).equatable()
                        }
                        .padding(.horizontal, 18).frame(maxWidth: 600).frame(maxWidth: .infinity)
                    }
                    if world.id == 2 { DinoDesertFlights(routeOffset: routeOffset, viewportHeight: viewportHeight) }
                    if world.id == 9 { PirateCoastFlights(routeOffset: routeOffset, viewportHeight: viewportHeight) }
                    if world.id == 5 { CrystalCaveEntranceForeground().equatable() }
                }
            }
        }
            .background(Color(dinoHex: world.ground))
            .environment(\.layoutDirection, .leftToRight)
    }
}

struct LevelInfoPanel: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.dismiss) private var dismiss
    let level: LevelConfiguration
    var start: () -> Void
    var close: (() -> Void)? = nil
    var openPractice: (DinoPracticeConfiguration) -> Void
    private var theme: LevelStartTheme { .init(worldID: level.worldID) }
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                LevelDetailsDisclosure(level: level, theme: theme, highContrast: highContrast, openPractice: openPractice)
                LevelFriendsView(levelID: level.id, theme: theme) {
                    Button(action: start) { Label("dino.play", systemImage: "play.fill") }
                        .buttonStyle(DinoButtonStyle(color: theme.accent, inkLabel: true))
                        .accessibilityIdentifier("level.play")
                }
                Button { if let close { close() } else { dismiss() } } label: {
                    Label("dino.map", systemImage: "map.fill")
                }
                    .buttonStyle(DinoSecondaryButtonStyle())
                    .accessibilityIdentifier("level.map")
            }
            .padding(26).frame(maxWidth: 450).frame(maxWidth: .infinity, alignment: .top)
        }
        .bouncesOnlyWhenNeeded()
        .background(LevelStartBackground(theme: theme)).foregroundStyle(DinoStyle.ink)
    }
}

/// All start-card surfaces follow the selected level, including replays in an earlier world.
struct LevelStartTheme {
    let world: DinoWorld
    let ground: Color
    let accent: Color
    let shade: Color
    let ink: Color
    var paper: Color { ground.mixed(with: .white, by: 0.84) }
    var symbol: String {
        switch world.themeID {
        case 1: return "leaf.fill"
        case 2: return "moon.stars.fill"
        case 3: return "flame.fill"
        case 4: return "house.fill"
        case 5: return "diamond.fill"
        case 6: return "building.2.fill"
        case 7: return "sun.max.fill"
        case 8: return "gearshape.2.fill"
        case 9: return "sailboat.fill"
        default: return "crown.fill"
        }
    }
    init(worldID: Int) {
        world = DinoWorldCatalog.world(worldID) ?? DinoWorldCatalog.worlds[0]
        let colors = WorldThemeColors(world)
        ground = Color(dinoHex: colors.ground)
        accent = Color(dinoHex: colors.accent)
        shade = Color(dinoHex: colors.shade)
        ink = Color(dinoHex: colors.shade).mixed(with: Color(dinoHex: 0x102535), by: 0.36)
    }
}

/// The sign itself grows: the outline is revealed through a clipped height, without a floating transition.
private struct LevelDetailsDisclosure: View {
    let level: LevelConfiguration
    let theme: LevelStartTheme
    let highContrast: Bool
    var openPractice: (DinoPracticeConfiguration) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var open = false
    @State private var retainsDetails = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                if !open { retainsDetails = true }
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.34)) { open.toggle() }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: theme.symbol)
                        .font(.system(size: 20, weight: .bold))
                        .frame(width: 30)
                        .accessibilityHidden(true)
                    Text("dino.levelNumber \(level.id)")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .shadow(color: theme.ground, radius: 0, y: 1)
                        .accessibilityIdentifier("level.number")
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .rotationEffect(.degrees(open ? 90 : 0))
                        .frame(width: 30, height: 30)
                        .background(theme.shade.opacity(0.08), in: Circle())
                        .accessibilityHidden(true)
                }
                .foregroundStyle(theme.ink)
                .padding(.horizontal, 18)
                .frame(minHeight: 64)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("level.details")
            .accessibilityLabel(Text("dino.levelNumber \(level.id)") + Text(", ") + Text("dino.level.details"))
            .accessibilityValue(Text(LocalizedStringKey(open ? "dino.level.detailsOpen" : "dino.level.detailsClosed")))
            .accessibilityHint(Text(LocalizedStringKey(theme.world.titleKey)))
            if retainsDetails {
                VStack(alignment: .leading, spacing: 12) {
                    Rectangle().fill(theme.shade.opacity(0.18)).frame(height: 1)
                    Text("dino.level.details")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.ink)
                    LevelQuestionOutlineList(items: level.questionOutline, theme: theme, openPractice: openPractice)
                }
                .padding(.horizontal, 18).padding(.bottom, 18)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: open ? nil : 0, alignment: .top)
                .clipped()
                .accessibilityHidden(!open)
                .allowsHitTesting(open)
                .transition(.identity)
            }
        }
        .background(LinearGradient(colors: [theme.paper, theme.ground.mixed(with: .white, by: 0.42)],
                                   startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
            .strokeBorder(highContrast ? theme.ink : theme.shade.opacity(0.65), lineWidth: highContrast ? 3 : 2.5))
        .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(.white.opacity(0.8), lineWidth: 1.5)
            .padding(5).allowsHitTesting(false))
        .shadow(color: theme.shade.opacity(0.18), radius: 0, y: 3)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("level.outlineCard")
        .id(level.id)
        .task(id: open) {
            guard !open, retainsDetails else { return }
            // Keep the full text laid out while the clipped height retracts it.
            if !reduceMotion {
                do { try await Task.sleep(nanoseconds: 340_000_000) }
                catch { return }
            }
            guard !Task.isCancelled else { return }
            retainsDetails = false
        }
    }
}

/// Practice number, exercise name, and time family, in the order the level asks them.
private struct LevelQuestionOutlineList: View {
    let items: [LevelQuestionOutline]
    let theme: LevelStartTheme
    var openPractice: (DinoPracticeConfiguration) -> Void
    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Button {
                    if let configuration = item.practiceConfiguration { openPractice(configuration) }
                } label: {
                    HStack(spacing: 8) {
                        Text(verbatim: item.practiceNumber.map(String.init) ?? "–")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .frame(width: 28, height: 28)
                            .foregroundStyle(theme.ink)
                            .background(theme.accent.opacity(0.2), in: Circle())
                            .accessibilityIdentifier("level.question.\(index).number")
                        Text(LocalizedStringKey(item.titleKey))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(LocalizedStringKey(item.timeTitleKey))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.ink)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 92, alignment: .trailing)
                            .fixedSize(horizontal: false, vertical: true)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(theme.ink.opacity(0.7))
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 4).frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(item.practiceConfiguration == nil)
                .accessibilityElement(children: .combine)
                .accessibilityHint(Text("dino.practice.title"))
                .accessibilityIdentifier("level.question.\(index)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("level.questions")
    }
}

/// Quiet world scenery stays behind the controls rather than repeating the jungle in every chapter.
private struct LevelStartBackground: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let theme: LevelStartTheme

    var body: some View {
        Group {
            if theme.world.themeID == 1 {
                JungleBackground(quiet: true)
            } else {
                ZStack(alignment: .bottom) {
                    LinearGradient(colors: [theme.paper, theme.ground.mixed(with: .white, by: 0.62)],
                                   startPoint: .top, endPoint: .bottom)
                    Canvas { context, size in
                        let w = size.width, h = size.height
                        for index in 0..<3 {
                            let y = h - 64 - CGFloat(index) * 41
                            var ridge = Path()
                            ridge.move(to: CGPoint(x: 0, y: y))
                            if [3, 5].contains(theme.world.themeID) {
                                ridge.addLines([CGPoint(x: w * 0.24, y: y - 60), CGPoint(x: w * 0.43, y: y + 12),
                                                CGPoint(x: w * 0.72, y: y - 40), CGPoint(x: w, y: y + 14)])
                            } else {
                                ridge.addCurve(to: CGPoint(x: w, y: y + 18),
                                    control1: CGPoint(x: w * 0.36, y: y - 56), control2: CGPoint(x: w * 0.62, y: y + 70))
                            }
                            ridge.addLine(to: CGPoint(x: w, y: h)); ridge.addLine(to: CGPoint(x: 0, y: h))
                            ridge.closeSubpath()
                            context.fill(ridge, with: .color(theme.accent.opacity(0.07 + Double(2 - index) * 0.025)))
                        }
                        if theme.world.themeID == 7 {
                            // Two small cacti, drawn in the same sandstone tones as the desert map.
                            for (x, y, scale) in [(w * 0.08, h - 33, 1.0), (w * 0.91, h - 54, 0.72)] {
                                var cactus = Path()
                                cactus.move(to: CGPoint(x: x, y: y)); cactus.addLine(to: CGPoint(x: x, y: y - 58 * scale))
                                cactus.move(to: CGPoint(x: x, y: y - 23 * scale))
                                cactus.addQuadCurve(to: CGPoint(x: x - 17 * scale, y: y - 34 * scale),
                                                    control: CGPoint(x: x - 17 * scale, y: y - 20 * scale))
                                cactus.addLine(to: CGPoint(x: x - 17 * scale, y: y - 43 * scale))
                                cactus.move(to: CGPoint(x: x, y: y - 34 * scale))
                                cactus.addQuadCurve(to: CGPoint(x: x + 15 * scale, y: y - 45 * scale),
                                                    control: CGPoint(x: x + 15 * scale, y: y - 31 * scale))
                                cactus.addLine(to: CGPoint(x: x + 15 * scale, y: y - 51 * scale))
                                context.stroke(cactus, with: .color(theme.shade.opacity(0.18)),
                                               style: StrokeStyle(lineWidth: 9 * scale, lineCap: .round, lineJoin: .round))
                            }
                        }
                    }
                    .opacity(highContrast ? 0.4 : 1)
                    if theme.world.themeID != 7 {
                        HStack {
                            Image(systemName: theme.symbol).rotationEffect(.degrees(-14))
                            Spacer()
                            Image(systemName: theme.symbol).rotationEffect(.degrees(12))
                        }
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(theme.shade.opacity(highContrast ? 0.06 : 0.13))
                        .padding(.horizontal, 20).padding(.bottom, 34)
                    }
                }
            }
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// The start card and game share one scene, so Play never waits for a sheet dismissal.
struct LevelStartOverlay: View {
    let level: LevelConfiguration
    let hudHeight: CGFloat
    var start: () -> Void
    var close: () -> Void
    var openPractice: (DinoPracticeConfiguration) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let top = min(hudHeight + 14, max(14, geometry.size.height - 180))
            ZStack(alignment: .top) {
                Color.black.opacity(0.28).ignoresSafeArea()
                    .onTapGesture(perform: close).transition(.opacity)
                VStack(spacing: 0) {
                    Capsule().fill(LevelStartTheme(worldID: level.worldID).ink.opacity(0.2)).frame(width: 36, height: 5)
                        .frame(maxWidth: .infinity).frame(height: 28).contentShape(Rectangle())
                        .gesture(DragGesture()
                            .onChanged { dragOffset = max(0, $0.translation.height) }
                            .onEnded {
                                if $0.translation.height > 70 || $0.predictedEndTranslation.height > 130 { close() }
                                else { withAnimation(.easeOut(duration: 0.2)) { dragOffset = 0 } }
                            })
                        .accessibilityHidden(true)
                    LevelInfoPanel(level: level, start: start, close: close, openPractice: openPractice)
                }
                .frame(width: min(540, geometry.size.width - 24),
                       height: min(level.isBoss ? 640 : 570, geometry.size.height - top - 16))
                .background(LevelStartTheme(worldID: level.worldID).paper)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: .black.opacity(0.14), radius: 20, y: 8)
                .accessibilityIdentifier("level.startCard")
                .padding(.top, top)
                .offset(y: dragOffset)
                .transition(reduceMotion ? .opacity : .scale(scale: 0.95, anchor: .top).combined(with: .opacity))
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
