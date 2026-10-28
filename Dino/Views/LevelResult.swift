import SwiftUI

struct DinoResultView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var player: DinoPlayer
    let result: DinoLevelResult
    let retry: () -> Void
    let next: () -> Void
    let map: () -> Void
    var sharedCompanion = false
    @State private var starsRevealed = 0
    @State private var confetti = false
    private var succeeded: Bool { result.level.isBoss ? result.victory != .none : result.stars > 0 }
    private var nextAvailable: Bool { result.level.isBoss ? succeeded : player.profile.isUnlocked(result.level.id + 1) }

    var body: some View {
        GeometryReader { geometry in
            let layout = ResultLayout(size: geometry.size, needsMessage: !succeeded, worldID: result.level.worldID)
            ZStack {
                VStack(spacing: 0) {
                    DinoResultLevelSign(levelID: result.level.id, worldID: result.level.worldID)
                        .frame(width: layout.signWidth, height: layout.signHeight)
                        .padding(.top, layout.topInset)
                        .accessibilityIdentifier("result.level")
                        .zIndex(1)
                    resultCaption
                        .padding(.top, 6)
                    Spacer(minLength: 0)
                    stage(layout: layout)
                    Spacer(minLength: 16)
                    actions
                        .frame(width: layout.actionWidth)
                        .padding(.bottom, 14)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .backgroundPreferenceValue(ResultPodiumBoundsKey.self) { anchor in
                GeometryReader { scene in
                    let podium = anchor.map { scene[$0] } ?? .zero
                    ResultScenery(worldID: result.level.worldID,
                                  signFrame: CGRect(x: (geometry.size.width - layout.signWidth) / 2 + geometry.safeAreaInsets.leading,
                                                    y: layout.topInset + geometry.safeAreaInsets.top,
                                                    width: layout.signWidth, height: layout.signHeight),
                                  podiumFrame: podium.offsetBy(dx: geometry.safeAreaInsets.leading, dy: geometry.safeAreaInsets.top))
                }
            }
        }
        .foregroundStyle(DinoStyle.ink)
        .task(id: result.level.id) { await playReward() }
    }

    private var resultCaption: some View {
        VStack(spacing: 5) {
            HStack(spacing: 7) {
                Text(verbatim: "\(result.correct)/\(result.level.questionCount)")
                    .fontWeight(.heavy)
                Text("dino.correctAnswers")
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(Color(dinoHex: 0x244E29))
            if result.level.isBoss && result.victory == .perfect {
                Label("dino.perfectBoss", systemImage: "sparkles")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
            }
            if !succeeded {
                Text(LocalizedStringKey(result.level.isBoss ? (player.profile.normalLevelsComplete(in: result.level.worldID) ? "dino.needFive" : "dino.needPerfectOrRoute") : "dino.needThree"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 330)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            DinoLightMaterial(style: .regular).clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.65), lineWidth: 1))
        .accessibilityIdentifier("result.score")
    }

    /// The jump finishes on the rock first. Earned stars then settle onto the stone one by one,
    /// and a three-star landing sends confetti out from behind Dino.
    private func playReward() async {
        starsRevealed = 0
        confetti = false
        if reduceMotion {
            starsRevealed = result.stars
            confetti = result.stars >= 3
            return
        }
        let clip = result.animationClip
        let landing = clip == .backflip || clip == .pirouette || clip == .openingJump
            ? DinoAnimation.travelDuration(clip) + 0.04 : (succeeded ? 0.4 : 0.15)
        try? await Task.sleep(for: .seconds(landing))
        guard !Task.isCancelled else { return }
        for index in 0..<min(result.stars, 3) {
            starsRevealed = index + 1
            let settles = index == result.stars - 1 ? 0.44 : 0.3
            try? await Task.sleep(for: .seconds(settles))
            guard !Task.isCancelled else { return }
        }
        if result.stars >= 3 { confetti = true }
    }

    private func stage(layout: ResultLayout) -> some View {
        ZStack(alignment: .bottom) {
            ResultSunburst(worldID: result.level.worldID, strength: result.stars > 0 ? (starsRevealed > 0 ? 1 : 0.78) : 0.3)
                .frame(width: layout.podiumWidth * 1.38, height: layout.podiumWidth * 1.38)
                .position(x: layout.stageWidth / 2, y: layout.dinoCenterY + layout.dinoSize * 0.05)
            if result.level.worldID == 1 {
                junglePlanting(layout: layout, foreground: false)
            }
            podiumSurround(layout: layout, foreground: false)
            ResultWorldPodium(worldID: result.level.worldID)
                .anchorPreference(key: ResultPodiumBoundsKey.self, value: .bounds) { $0 }
                .frame(width: layout.podiumWidth, height: layout.podiumHeight)
                .position(x: layout.podiumCenterX, y: layout.stageHeight - layout.podiumHeight / 2 + layout.podiumLift)
            Ellipse()
                .fill(Color(dinoHex: ResultPodiumPalette(worldID: result.level.worldID).edge).opacity(0.24))
                .frame(width: layout.dinoSize * 0.55, height: layout.dinoSize * 0.055)
                .blur(radius: 3)
                .position(x: layout.podiumCenterX, y: layout.contactY)
            character(size: layout.dinoSize)
                .position(x: layout.stageWidth / 2, y: layout.dinoCenterY)
            foregroundDetails(layout: layout)
            ResultStarReward(count: result.stars, revealed: starsRevealed, size: layout.starSize)
                .position(x: layout.podiumCenterX, y: layout.rewardCenterY)
            ResultCelebrationMotes(worldID: result.level.worldID, active: result.stars > 0)
                .allowsHitTesting(false)
            if confetti {
                ResultConfetti()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: layout.stageWidth, height: layout.stageHeight)
    }

    private func foregroundDetails(layout: ResultLayout) -> some View {
        ZStack {
            if result.level.worldID == 1 {
                junglePlanting(layout: layout, foreground: true)
            }
            podiumSurround(layout: layout, foreground: true)
        }
        .frame(width: layout.stageWidth, height: layout.stageHeight)
    }

    private func junglePlanting(layout: ResultLayout, foreground: Bool) -> some View {
        ResultRockPlanting(worldID: result.level.worldID, foreground: foreground)
            .frame(width: layout.podiumWidth * 1.24, height: layout.podiumHeight * 1.6)
            .position(x: layout.podiumCenterX, y: layout.stageHeight - layout.podiumHeight / 2 + layout.podiumLift)
    }

    private func podiumSurround(layout: ResultLayout, foreground: Bool) -> some View {
        ResultPodiumSurround(worldID: result.level.worldID, foreground: foreground)
            .frame(width: layout.podiumWidth * 1.24, height: layout.podiumHeight * 1.6)
            .position(x: layout.podiumCenterX, y: layout.stageHeight - layout.podiumHeight / 2 + layout.podiumLift)
    }

    private func character(size: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) {
            if sharedCompanion {
                DinoCompanionAnchor(placement: .result, size: size)
            } else {
                DinoCharacter(state: succeeded ? .celebrating : .thinking, size: size,
                              performsBackflip: result.animationClip == .backflip,
                              performsPirouette: result.animationClip == .pirouette,
                              performsStumble: result.animationClip == .stumble,
                              performsOpeningJump: result.animationClip == .openingJump)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            if result.level.isBoss && succeeded {
                if DinoWorldCatalog.world(result.level.worldID + 1) != nil {
                    Button(action: next) {
                        Label("dino.nextWorld", systemImage: "arrow.right")
                    }
                    .buttonStyle(ResultAdventureButtonStyle(primary: true))
                    .accessibilityIdentifier("result.next")
                } else {
                    Button(action: map) { Label("dino.map", systemImage: "map.fill") }
                        .buttonStyle(ResultAdventureButtonStyle(primary: true))
                        .accessibilityIdentifier("result.map")
                }
                retryButton
            } else if nextAvailable {
                Button(action: next) {
                    HStack(spacing: 12) {
                        Spacer(minLength: 0)
                        Text("dino.next")
                        Image(systemName: "arrow.right").fontWeight(.heavy)
                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(ResultAdventureButtonStyle(primary: true))
                .accessibilityIdentifier("result.next")
                HStack(spacing: 10) {
                    retryButton
                    mapButton
                }
            } else {
                retryButton
                mapButton
            }
        }
    }

    private var retryButton: some View {
        Button(action: retry) { Label("dino.playAgain", systemImage: "arrow.clockwise") }
            .buttonStyle(ResultAdventureButtonStyle(primary: !nextAvailable))
            .accessibilityIdentifier("result.retry")
    }

    private var mapButton: some View {
        Button(action: map) { Label("dino.map", systemImage: "map.fill") }
            .buttonStyle(ResultAdventureButtonStyle(primary: false))
            .accessibilityIdentifier("result.map")
    }
}

private struct ResultPodiumBoundsKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? { nil }
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        if let next = nextValue() { value = next }
    }
}

/// Reserve space for the controls first, then scale the illustration as one scene.
/// This keeps Dino's feet, the rock and the stars registered on every window size.
private struct ResultLayout {
    let size: CGSize
    let needsMessage: Bool
    let worldID: Int
    var topInset: CGFloat { size.height < 650 ? 0 : 8 }
    var signWidth: CGFloat { min(size.width * 0.96, size.height * 0.56, 500) }
    var signHeight: CGFloat { signWidth * 0.36 }
    var actionWidth: CGFloat { min(size.width - 40, 430) }
    var stageWidth: CGFloat { min(size.width * 1.12, 700) }
    var availableHeight: CGFloat { max(160, size.height - signHeight - topInset - (needsMessage ? 224 : 194)) }
    var dinoSize: CGFloat { min(size.width * 0.73, availableHeight / 1.65, 360) }
    var podiumWidth: CGFloat { min(stageWidth * 0.88, dinoSize * 1.40) }
    var podiumHeight: CGFloat { podiumWidth * ResultPodiumGeometry.height / ResultPodiumGeometry.width }
    var podiumCenterX: CGFloat { stageWidth / 2 + dinoSize * 0.04 }
    var podiumLift: CGFloat { -dinoSize * 0.015 }
    var stageHeight: CGFloat { min(availableHeight, dinoSize + podiumHeight * 0.85 + 20) }
    var contactY: CGFloat { stageHeight - podiumHeight * 0.82 + podiumLift }
    var dinoCenterY: CGFloat { contactY - dinoSize * 0.44 }
    var starSize: CGFloat { podiumWidth * ResultPodiumGeometry.starWidth(worldID: worldID) }
    var rewardCenterY: CGFloat { stageHeight - podiumHeight + podiumLift + podiumHeight * ResultPodiumGeometry.rewardY(worldID: worldID) / ResultPodiumGeometry.height }

}

private struct ResultAdventureButtonStyle: ButtonStyle {
    @Environment(\.dinoHighContrast) private var highContrast
    let primary: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: primary ? 20 : 15, weight: .heavy, design: .rounded))
            .lineLimit(1).minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
            .frame(height: primary ? 56 : 46)
            .foregroundStyle(primary ? Color.white : Color(dinoHex: 0x28502B))
            .background {
                RoundedRectangle(cornerRadius: primary ? 22 : 18)
                    .fill(Color(dinoHex: primary ? 0x22662C : 0x88A361))
                    .offset(y: configuration.isPressed ? 1 : 4)
                RoundedRectangle(cornerRadius: primary ? 22 : 18)
                    .fill(LinearGradient(colors: primary
                        ? (highContrast
                            ? [Color(dinoHex: 0x3E842B), Color(dinoHex: 0x286C28), Color(dinoHex: 0x1D5824)]
                            : [Color(dinoHex: 0x94CE43), Color(dinoHex: 0x50A62E), Color(dinoHex: 0x36832B)])
                        : [Color(dinoHex: 0xFFFFEF), Color(dinoHex: 0xEEF5D9)],
                        startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: primary ? 20 : 16)
                    .stroke(.white.opacity(primary ? 0.50 : 0.85), lineWidth: 1.5)
                    .padding(3)
                RoundedRectangle(cornerRadius: primary ? 22 : 18)
                    .stroke(Color(dinoHex: highContrast ? 0x173F20 : 0x4B812D).opacity(highContrast ? 1 : 0.55), lineWidth: highContrast ? 2.5 : 1)
            }
            .shadow(color: Color(dinoHex: 0x294C1D).opacity(0.18), radius: 8, y: 6)
            .offset(y: configuration.isPressed ? 3 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Jungle, desert and the other biomes each own their landscape geometry.
/// No flattened background image is used by the result scene.
private struct ResultScenery: View {
    let worldID: Int
    let signFrame: CGRect
    let podiumFrame: CGRect
    var windPhase: Double = 0

    var body: some View {
        let palette = ResultLandscapePalette(worldID: worldID)
        ZStack {
            if palette.themeID == 7 {
                Canvas(rendersAsynchronously: true) { context, size in
                    DinoDesertPainter(context: context).rewardLandscape(in: size)
                }
            } else if palette.themeID == 1 {
                ForEach(ResultLandscapeLayer.allCases, id: \.self) { layer in
                    Canvas(rendersAsynchronously: true) { context, size in
                        ResultLandscapePainter(context: context, size: size, palette: palette,
                                               windPhase: windPhase).draw(layer)
                    }
                }
            } else {
                Canvas(rendersAsynchronously: true) { context, size in
                    ResultBiomePainter(context: context, size: size, themeID: palette.themeID).landscape()
                }
            }
            Canvas(rendersAsynchronously: true) { context, size in
                ResultBiomePainter(context: context, size: size, themeID: palette.themeID)
                    .connectToPodium(podiumFrame)
            }
            DinoResultHeaderBackdrop(worldID: worldID, signFrame: signFrame, windPhase: windPhase)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private enum ResultLandscapeLayer: CaseIterable { case sky, distance, meadow, foliage }

/// Ground details share the podium's coordinates on every screen size.
private struct ResultRockPlanting: View {
    let worldID: Int
    var foreground = false
    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            var art = context
            art.scaleBy(x: size.width / 1240, y: size.height / 728)
            art.translateBy(x: 120, y: 136.5)
            let painter = ResultLandscapePainter(context: art, size: CGSize(width: 1000, height: 455),
                                                 palette: ResultLandscapePalette(worldID: worldID))
            if foreground { painter.stoneGroundCover() }
            else { painter.stoneGarden() }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The map's theme identity is separate from world order and scene geometry.
private struct ResultLandscapePalette {
    let themeID: Int
    let night: Bool
    var skyTop: UInt32 = 0x65CEF1
    var skyBottom: UInt32 = 0xDDF4DC
    var hill: UInt32 = 0x64ADAE
    var hillNear: UInt32 = 0x66A76B
    var grassLight: UInt32 = 0xE3F58A
    var grass: UInt32 = 0xA1D33F
    var grassShade: UInt32 = 0x4C922E
    var leafLight: UInt32 = 0xC5EA59
    var leaf: UInt32 = 0x4E9E39
    var leafShade: UInt32 = 0x165C3B
    var bark: UInt32 = 0x785C34

    init(worldID: Int) {
        let world = DinoWorldCatalog.world(worldID) ?? DinoWorldCatalog.worlds[0]
        themeID = world.themeID
        night = themeID == 2
        guard themeID != 1 else { return }
        let colors = WorldThemeColors(world)
        hill = colors.distant
        hillNear = colors.accent
        grass = world.ground
        grassLight = Self.mix(world.ground, 0xFFF7CC, 0.32)
        grassShade = Self.mix(world.ground, colors.shade, 0.54)
        leaf = Self.mix(colors.accent, colors.shade, 0.3)
        leafLight = Self.mix(colors.accent, 0xF1F0B2, 0.30)
        leafShade = colors.shade
        switch themeID {
        case 2: (skyTop, skyBottom) = (0x2B3059, 0x9B99BE)
        case 3: (skyTop, skyBottom) = (0xD66C63, 0xFFE2AD)
        case 4: (skyTop, skyBottom) = (0x9EDBE9, 0xEFF5C5)
        case 5: (skyTop, skyBottom) = (0x174552, 0x7BB6B3)
        case 6: (skyTop, skyBottom) = (0x9CCBE5, 0xE6F0DE)
        case 7: (skyTop, skyBottom) = (0x89C9EB, 0xFFE6B4)
        case 8: (skyTop, skyBottom) = (0xA9A4CF, 0xEEE3CD)
        case 9: (skyTop, skyBottom) = (0x75C5DC, 0xF2EBC5)
        default: (skyTop, skyBottom) = (0x8CA8CB, 0xE7E6CE)
        }
    }

    static func mix(_ a: UInt32, _ b: UInt32, _ amount: Double) -> UInt32 {
        func channel(_ shift: UInt32) -> UInt32 {
            UInt32(Double((a >> shift) & 255) * (1 - amount) + Double((b >> shift) & 255) * amount)
        }
        return channel(16) << 16 | channel(8) << 8 | channel(0)
    }
}

private struct ResultLandscapePainter {
    let context: GraphicsContext
    let size: CGSize
    let palette: ResultLandscapePalette
    var windPhase: Double = 0
    private var w: CGFloat { size.width }
    private var h: CGFloat { size.height }
    private var scale: CGFloat { min(1.8, max(0.7, min(w / 390, h / 800))) }
    private func color(_ hex: UInt32) -> Color { Color(dinoHex: hex) }
    private func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: w * x, y: h * y) }
    private func noise(_ index: Int, seed: UInt64) -> CGFloat {
        var value = UInt64(index) &+ seed
        value = (value ^ (value >> 16)) &* 0x45D9F3B
        value = (value ^ (value >> 16)) &* 0x45D9F3B
        value ^= value >> 16
        return CGFloat(value & 65535) / 65535
    }

    func draw(_ layer: ResultLandscapeLayer) {
        switch layer {
        case .sky: sky()
        case .distance: distance()
        case .meadow: meadow()
        case .foliage: foliage()
        }
    }

    private func sky() {
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
            Gradient(colors: [color(palette.skyTop), color(palette.skyBottom)]),
            startPoint: .zero, endPoint: point(0, 0.72)))
        glow(at: point(0.5, 0.49), radius: w * 0.82,
             colors: [Color(dinoHex: 0xFFF9CE).opacity(palette.night ? 0.20 : 0.75), .clear])
        if palette.night {
            let moon = point(0.80, 0.20), radius = 24 * scale
            glow(at: moon, radius: radius * 3, colors: [color(0xFFF5CC).opacity(0.23), .clear])
            var crescent = context
            crescent.clip(to: Path(ellipseIn: CGRect(x: moon.x - radius * 0.3, y: moon.y - radius * 1.2,
                                                    width: radius * 1.75, height: radius * 1.75)), options: .inverse)
            crescent.fill(Path(ellipseIn: CGRect(x: moon.x - radius, y: moon.y - radius,
                                                 width: radius * 2, height: radius * 2)), with: .color(color(0xFFF6D8)))
            for index in 0..<26 {
                let x = CGFloat((index * 37 + 11) % 101) / 100
                let y = 0.06 + CGFloat((index * 23 + 9) % 43) / 100
                let radius: CGFloat = index.isMultiple(of: 4) ? 1.6 : 0.8
                ellipse(CGRect(x: w * x, y: h * y, width: radius * 2, height: radius * 2), color: color(0xFFF9DF).opacity(0.8))
            }
        } else {
            cloud(at: point(-0.06, 0.32), width: w * 0.43, opacity: 0.88)
            cloud(at: point(0.98, 0.37), width: w * 0.45, opacity: 0.84)
            cloud(at: point(0.62, 0.19), width: w * 0.22, opacity: 0.35)
        }
    }

    private func distance() {
        hill(start: point(-0.18, 0.64), peak: point(0.12, 0.39), end: point(0.64, 0.67),
             top: color(palette.hill).opacity(0.63), bottom: color(palette.skyBottom).opacity(0.8))
        hill(start: point(0.35, 0.67), peak: point(0.90, 0.43), end: point(1.20, 0.67),
             top: color(palette.hill).opacity(0.77), bottom: color(palette.skyBottom))
        hill(start: point(-0.25, 0.72), peak: point(0.04, 0.54), end: point(0.66, 0.73),
             top: color(palette.hillNear).opacity(0.86), bottom: color(palette.grassLight))
        hill(start: point(0.27, 0.75), peak: point(0.92, 0.56), end: point(1.27, 0.74),
             top: color(palette.hillNear).opacity(0.76), bottom: color(palette.grassLight))
        // Connected canopy ribbons follow the foot of the hills and meet the side banks.
        for right in [false, true] {
            func q(_ x: CGFloat, _ y: CGFloat) -> CGPoint { point(right ? 1 - x : x, y) }
            var canopy = Path(); canopy.move(to: q(-0.04, 0.61))
            canopy.addCurve(to: q(0.10, 0.62), control1: q(0.01, 0.58), control2: q(0.07, 0.57))
            canopy.addCurve(to: q(0.23, 0.65), control1: q(0.16, 0.59), control2: q(0.21, 0.60))
            canopy.addQuadCurve(to: q(0.30, 0.72), control: q(0.29, 0.64))
            canopy.addLine(to: q(-0.04, 0.74)); canopy.closeSubpath()
            context.fill(canopy, with: .linearGradient(Gradient(colors: [color(0x5E9C72).opacity(0.42), color(palette.grassLight).opacity(0.34)]),
                startPoint: q(0.1, 0.60), endPoint: q(0.1, 0.74)))
        }
        // Palm silhouettes break up the distant hills without filling the clearing.
        for index in 0..<18 {
            let side = index.isMultiple(of: 2)
            let x: CGFloat = side ? 0.02 + CGFloat(index % 5) * 0.042 : 0.83 + CGFloat(index % 5) * 0.045
            let y: CGFloat = 0.565 + CGFloat(index % 5) * 0.025
            palm(at: point(x, y), height: (22 + CGFloat(index % 4) * 9) * scale, opacity: 0.37)
        }
        glow(at: point(0.50, 0.59), radius: w * 0.52,
             colors: [color(0xFFF9D4).opacity(palette.night ? 0.20 : 0.72), .clear])
    }

    private func meadow() {
        var field = Path()
        field.move(to: point(-0.1, 0.67))
        field.addCurve(to: point(1.1, 0.65), control1: point(0.22, 0.61), control2: point(0.66, 0.72))
        field.addLine(to: point(1.1, 1.1))
        field.addLine(to: point(-0.1, 1.1))
        field.closeSubpath()
        context.fill(field, with: .linearGradient(Gradient(stops: [
            .init(color: color(palette.grassLight), location: 0),
            .init(color: color(palette.grass), location: 0.43),
            .init(color: color(palette.grassShade), location: 1)
        ]), startPoint: point(0.5, 0.65), endPoint: point(0.5, 1.06)))
        context.drawLayer { c in
            c.clip(to: field)
            // Rounded pockets of light replace the broad, flat stripes of the first pass.
            for index in 0..<9 {
                let y = 0.68 + CGFloat(index) * 0.046
                let x = index.isMultiple(of: 2) ? 0.30 : 0.71
                let r = CGRect(x: w * (x - 0.68), y: h * (y - 0.018), width: w * 1.36, height: h * 0.10)
                let light = ResultLandscapePainter(context: c, size: size, palette: palette)
                light.ellipticalGlow(in: r, colors: [color(palette.grassLight).opacity(0.36), .clear])
            }
            c.fill(field, with: .radialGradient(Gradient(colors: [color(palette.grassLight).opacity(0.68), .clear]),
                                               center: point(0.49, 0.72), startRadius: 0, endRadius: w * 0.67))
            // Perspective, changing blade shapes and broken light make a continuous lawn.
            for index in 0..<1250 {
                let x = noise(index, seed: 7141)
                let depth = noise(index, seed: 9377)
                let y: CGFloat = 0.655 + depth * 0.39
                let tuftScale = (0.10 + depth * depth * 0.78) * scale
                let tufts = ResultLandscapePainter(context: c, size: size, palette: palette)
                tufts.grass(at: point(x, y), scale: tuftScale, light: index % 5 < 3,
                            opacity: 0.24 + Double(depth) * 0.45)
            }
            // Tiny warm highlights catch on individual tips, rather than outlining every tuft.
            for index in 0..<180 {
                let x = noise(index, seed: 8301)
                let y = 0.72 + noise(index, seed: 6517) * 0.30
                let r = (0.5 + (y - 0.7) * 2.4) * scale
                c.fill(Path(ellipseIn: CGRect(x: w * x, y: h * y, width: r * 2.8, height: r)),
                       with: .color(color(palette.grassLight).opacity(0.70)))
            }
        }
        // A narrow creek cuts into one continuous grassy bank beside the clearing.
        var creek = Path(); creek.move(to: point(0.075, 0.65))
        creek.addCurve(to: point(0.13, 0.79), control1: point(0.04, 0.70), control2: point(0.18, 0.73))
        creek.addCurve(to: point(0.025, 1.08), control1: point(0.04, 0.90), control2: point(0.10, 0.98))
        creek.addLine(to: point(-0.065, 1.08))
        creek.addCurve(to: point(0.095, 0.79), control1: point(0.02, 0.96), control2: point(0.01, 0.88))
        creek.addCurve(to: point(0.075, 0.65), control1: point(0.14, 0.74), control2: point(0.045, 0.70)); creek.closeSubpath()
        context.stroke(creek, with: .color(color(0x76A659).opacity(0.65)), style: StrokeStyle(lineWidth: 7 * scale, lineJoin: .round))
        context.fill(creek, with: .linearGradient(Gradient(colors: [color(0xA0CCB4), color(0x69A8A6)]), startPoint: point(0.1, 0.66), endPoint: point(0.02, 1.08)))
        for i in 0..<9 {
            let y = 0.76 + CGFloat(i) * 0.03
            var ripple = Path(); ripple.move(to: point(0.075, y)); ripple.addQuadCurve(to: point(0.11, y + 0.005), control: point(0.095, y + 0.008))
            context.stroke(ripple, with: .color(color(0xE6EFD0).opacity(0.40)), lineWidth: 1)
        }
        for index in 0..<20 {
            let side = index.isMultiple(of: 2)
            let x: CGFloat = side ? 0.035 + CGFloat(index % 5) * 0.035 : 0.83 + CGFloat(index % 5) * 0.035
            let y: CGFloat = 0.76 + CGFloat(index % 7) * 0.036
            flower(at: point(x, y), radius: (1.5 + CGFloat(index % 3) * 0.8) * scale)
        }
    }

    private func foliage() {
        // The upper framing shares its materials and clearance with the level sign.
        // This painter owns only the lower garden, so two canopies cannot collide.
        for side in 0..<2 {
            var c = context
            c.translateBy(x: side == 0 ? 0 : w, y: 0)
            c.scaleBy(x: side == 0 ? 1 : -1, y: 1)
            let garden = ResultLandscapePainter(context: c, size: size, palette: palette, windPhase: windPhase)
            // Different-sized overlapping plants build a shaded bank, not a row of oversized leaves.
            let clusters: [(CGFloat, CGFloat, CGFloat, Double)] = [
                (-0.025, 0.752, 68, 12), (0.035, 0.802, 72, -9),
                (-0.045, 0.904, 117, 12), (0.068, 0.948, 79, -20),
                (-0.040, 1.055, 158, 17), (0.165, 1.055, 78, -23)
            ]
            for (index, cluster) in clusters.enumerated() {
                let y = h * cluster.1 + (side == 1 && index < 4 ? 18 * scale : 0)
                let length = cluster.2 * scale * (side == 1 ? 0.94 : 1)
                garden.rosette(at: CGPoint(x: w * cluster.0, y: y), length: length,
                               lean: cluster.3 + (side == 1 ? 7 : 0), seed: index + side * 3)
            }
            garden.fern(at: CGPoint(x: 27 * scale, y: h * 0.87), length: 65 * scale, angle: 28)
            garden.fern(at: CGPoint(x: w * 0.17, y: h * 1.025), length: 90 * scale, angle: 13)
            for index in 0..<7 {
                let x: CGFloat = (17 + CGFloat(index % 3) * 19) * scale
                let y: CGFloat = h * (0.82 + CGFloat(index) * 0.029)
                garden.flower(at: CGPoint(x: x, y: y), radius: (2.3 + CGFloat(index % 3)) * scale)
            }
        }
        // A few small plants continue across the very front without blocking the controls.
        rosette(at: point(0.35, 1.035), length: 35 * scale, lean: -25, seed: 7)
        rosette(at: point(0.71, 1.045), length: 44 * scale, lean: 22, seed: 4)
    }

    func stoneGarden() {
        for right in [false, true] {
            var art = context
            if right { art.translateBy(x: 1000, y: 0); art.scaleBy(x: -1, y: 1) }
            let garden = ResultLandscapePainter(context: art, size: size, palette: palette)
            let root = CGPoint(x: 22, y: right ? 458 : 453)
            for (i, angle) in [-37.0, -4, 24].enumerated() {
                let length = CGFloat([220, 260, 210][i])
                garden.leaf(at: root, length: length, width: length * 0.40,
                            angle: angle + (right ? 5 : 0), bright: i == 1)
            }
        }
    }

    func stoneGroundCover() {
        // These leaves overlap the stone's side facets; their tips stay outside the reward row.
        for right in [false, true] {
            var art = context
            if right { art.translateBy(x: 1000, y: 0); art.scaleBy(x: -1, y: 1) }
            let garden = ResultLandscapePainter(context: art, size: size, palette: palette)
            let root = CGPoint(x: 63, y: right ? 475 : 470)
            for (i, angle) in [-37.0, -10, 14].enumerated() {
                let length = CGFloat([125, 172, 156][i])
                garden.leaf(at: root, length: length, width: length * (i == 0 ? 0.46 : 0.38),
                            angle: angle, bright: i == 2)
            }
            garden.trailingSprig(root: CGPoint(x: right ? 149 : 151, y: right ? 123 : 126),
                                 tip: CGPoint(x: right ? 133 : 111, y: right ? 204 : 226),
                                 bend: right ? -18 : -29, seed: right ? 5 : 2)
            garden.flower(at: CGPoint(x: 59, y: 464), radius: 5)
            garden.flower(at: CGPoint(x: 88, y: 478), radius: 3.5)
        }
        // Individual irregular tufts join the stone to the meadow without a separate grass mat.
        for i in 0..<50 {
            let x = 8 + noise(i, seed: 9821) * 984
            let side = abs(x - 500) / 500
            let y = ResultPodiumGeometry.groundFrontY(themeID: 1) - 16 * pow(side, 8)
                + noise(i, seed: 2731) * 10
            grass(at: CGPoint(x: x, y: y), scale: 0.7 + noise(i, seed: 1913) * 0.65,
                  light: i % 3 != 0, opacity: 0.9)
        }
    }

    private func trailingSprig(root: CGPoint, tip: CGPoint, bend: CGFloat, seed: Int) {
        let control = CGPoint(x: root.x + bend, y: root.y + (tip.y - root.y) * 0.55)
        func node(_ t: CGFloat) -> CGPoint {
            CGPoint(x: (1 - t) * (1 - t) * root.x + 2 * (1 - t) * t * control.x + t * t * tip.x,
                    y: (1 - t) * (1 - t) * root.y + 2 * (1 - t) * t * control.y + t * t * tip.y)
        }
        var stem = Path(); stem.move(to: root); stem.addQuadCurve(to: tip, control: control)
        context.drawLayer { shadow in
            shadow.addFilter(.shadow(color: color(palette.leafShade).opacity(0.24), radius: 1.5, x: 1, y: 2))
            shadow.stroke(stem, with: .color(color(palette.leafShade)),
                          style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
        }
        context.stroke(stem, with: .linearGradient(Gradient(colors: [color(palette.leaf), color(palette.leafShade)]),
                                                   startPoint: root, endPoint: tip),
                       style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        for i in 0..<4 {
            let t = CGFloat(i) * 0.20 + 0.20
            let joint = node(t)
            for side: CGFloat in [-1, 1] {
                let base = CGPoint(x: joint.x + side * 5, y: joint.y + 3)
                var stalk = Path(); stalk.move(to: joint)
                stalk.addQuadCurve(to: base, control: CGPoint(x: base.x, y: joint.y))
                context.stroke(stalk, with: .color(color(palette.leaf)),
                               style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                let length = (CGFloat(31 + (i + seed) % 3 * 3) - t * 16) * (side < 0 ? 1 : 0.88)
                leaf(at: base, length: length, width: length * 0.52,
                     angle: Double(side) * Double(111 + (i + seed) % 3 * 7), bright: (i + seed).isMultiple(of: 3))
            }
        }
        // A terminal leaf closes the branch; every leaf base shares the stem's actual curve.
        leaf(at: node(0.95), length: 18, width: 9, angle: 169, bright: false)
    }

    private func rosette(at origin: CGPoint, length: CGFloat, lean: Double, seed: Int) {
        let shadow = CGRect(x: origin.x - length * 0.47, y: origin.y - length * 0.08,
                            width: length * 1.16, height: length * 0.22)
        ellipticalGlow(in: shadow, colors: [
            color(palette.leafShade).opacity(0.44), .clear
        ])
        let angles: [Double] = [-48, -24, 4, 33, 61, 84, 15, 48]
        for (index, angle) in angles.enumerated() {
            let variation = CGFloat([0.70, 0.90, 1.0, 0.92, 0.76, 0.56, 0.63, 0.55][index])
            let l = length * variation
            let at = CGPoint(x: origin.x + CGFloat((index + seed) % 3 - 1) * length * 0.05,
                             y: origin.y + CGFloat(index % 2) * length * 0.025)
            let drift = windPhase == 0 ? 0 : sin(windPhase + Double(index)) * 1.6
            leaf(at: at, length: l, width: l * (index < 6 ? 0.43 : 0.52),
                 angle: angle + lean + drift, bright: (index + seed).isMultiple(of: 4))
        }
    }

    func leaf(at p: CGPoint, length: CGFloat, width: CGFloat, angle: Double, bright: Bool) {
        var c = context
        c.translateBy(x: p.x, y: p.y)
        c.rotate(by: .degrees(angle))
        let rect = CGRect(x: -width / 2, y: -length, width: width, height: length)
        let bounds = CGRect(origin: .zero, size: rect.size)
        let shape = DinoFoliageLeaf().path(in: bounds).offsetBy(dx: rect.minX, dy: rect.minY)
        let fold = DinoFoliageFold().path(in: bounds).offsetBy(dx: rect.minX, dy: rect.minY)
        let veins = DinoFoliageVeins().path(in: bounds).offsetBy(dx: rect.minX, dy: rect.minY)
        let faceHex = bright ? palette.leaf : ResultLandscapePalette.mix(palette.leaf, palette.leafShade, 0.23)
        let lightHex = bright ? palette.leafLight : ResultLandscapePalette.mix(palette.leafLight, palette.leaf, 0.62)
        let light = color(lightHex)
        c.drawLayer { shadow in
            shadow.addFilter(.blur(radius: max(0.5, width * 0.045)))
            shadow.fill(shape.offsetBy(dx: width * 0.09, dy: length * 0.035),
                        with: .color(color(palette.leafShade).opacity(0.44)))
        }
        // Light rolls across the leaf's width, with a deeper underside at its base.
        c.fill(shape, with: .linearGradient(Gradient(stops: [
            .init(color: color(palette.leafShade), location: 0),
            .init(color: color(faceHex), location: 0.22),
            .init(color: light, location: 0.46),
            .init(color: color(faceHex), location: 0.70),
            .init(color: color(palette.leafShade), location: 1)
        ]), startPoint: CGPoint(x: -width * 0.55, y: -length * 0.66),
            endPoint: CGPoint(x: width * 0.55, y: -length * 0.37)))
        c.fill(shape, with: .linearGradient(Gradient(colors: [
            light.opacity(0.05), .clear, color(palette.leafShade).opacity(0.49)
        ]), startPoint: CGPoint(x: 0, y: -length), endPoint: .zero))
        c.fill(fold, with: .linearGradient(Gradient(colors: [
            color(palette.leafShade).opacity(0.18), light.opacity(0.12), color(palette.leafShade).opacity(0.27)
        ]), startPoint: CGPoint(x: 0, y: -length), endPoint: CGPoint(x: width * 0.44, y: 0)))
        c.fill(shape, with: .radialGradient(Gradient(colors: [
            Color(dinoHex: 0xFFFFCF).opacity(bright ? 0.22 : 0.11), light.opacity(0.10), .clear
        ]), center: CGPoint(x: -width * 0.08, y: -length * 0.69), startRadius: 0, endRadius: width * 0.67))
        c.stroke(veins.offsetBy(dx: 0.6, dy: 0.6), with: .color(color(palette.leafShade).opacity(0.19)),
                 style: StrokeStyle(lineWidth: max(0.35, length * 0.006), lineCap: .round))
        c.stroke(veins, with: .color(light.opacity(0.32)),
                 style: StrokeStyle(lineWidth: max(0.30, length * 0.004), lineCap: .round))
        var rib = Path()
        rib.move(to: CGPoint(x: 0, y: -length * 0.035))
        rib.addQuadCurve(to: CGPoint(x: width * 0.14, y: -length * 0.94),
                         control: CGPoint(x: -width * 0.12, y: -length * 0.51))
        c.stroke(rib, with: .linearGradient(Gradient(colors: [
            light.opacity(0.10), light.opacity(0.69), light.opacity(0.30)
        ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: -length)),
                 style: StrokeStyle(lineWidth: max(0.4, width * 0.022), lineCap: .round))
        c.stroke(shape, with: .color(light.opacity(0.21)), lineWidth: max(0.3, length * 0.0035))
    }

    private func fern(at p: CGPoint, length: CGFloat, angle: Double) {
        var c = context
        c.translateBy(x: p.x, y: p.y)
        c.rotate(by: .degrees(angle))
        let painter = ResultLandscapePainter(context: c, size: size, palette: palette)
        for frond in 0..<5 {
            let reach = CGFloat(frond - 2) * length * 0.28
            let rise = length * (1 - CGFloat(abs(frond - 2)) * 0.16)
            var stem = Path()
            stem.move(to: .zero)
            stem.addQuadCurve(to: CGPoint(x: reach, y: -rise), control: CGPoint(x: 0, y: -rise * 0.84))
            c.stroke(stem, with: .color(color(palette.leafShade)), style: StrokeStyle(lineWidth: max(0.6, length * 0.018), lineCap: .round))
            for index in 1..<8 {
                let t = CGFloat(index) / 8
                let origin = CGPoint(x: reach * t * t, y: -rise * (2 * t - t * t))
                let tangent = atan2(2 * reach * t, 2 * rise * (1 - t)) * 180 / .pi
                for side: Double in [-1, 1] {
                    painter.leaf(at: origin, length: length * (0.24 - t * 0.17), width: length * (0.07 - t * 0.035),
                                 angle: Double(tangent) + side * 60, bright: (index + frond).isMultiple(of: 3))
                }
            }
        }
    }

    func grass(at p: CGPoint, scale s: CGFloat, light: Bool, opacity: Double = 1) {
        let shades = light ? [color(palette.grassLight), color(palette.grass)]
                           : [color(palette.grass), color(palette.grassShade)]
        for index in 0..<5 {
            let x = CGFloat(index - 2) * 2.3 * s
            let height = CGFloat([6, 10, 13, 9, 7][index]) * s
            let bend = CGFloat(index - 2) * 1.5 * s
            let base = CGPoint(x: p.x + x, y: p.y)
            let tip = CGPoint(x: base.x + bend, y: base.y - height)
            var blade = Path()
            blade.move(to: CGPoint(x: base.x - 0.9 * s, y: base.y))
            blade.addQuadCurve(to: tip, control: CGPoint(x: base.x - 0.3 * s, y: base.y - height * 0.68))
            blade.addQuadCurve(to: CGPoint(x: base.x + 1.2 * s, y: base.y),
                               control: CGPoint(x: base.x + bend + 2.8 * s, y: base.y - height * 0.35))
            blade.closeSubpath()
            context.fill(blade, with: .linearGradient(Gradient(colors: shades.map { $0.opacity(opacity) }),
                                                      startPoint: tip, endPoint: base))
        }
    }

    func flower(at p: CGPoint, radius: CGFloat) {
        let stem = Path { path in
            path.move(to: CGPoint(x: p.x, y: p.y + radius * 2.2))
            path.addQuadCurve(to: p, control: CGPoint(x: p.x + radius, y: p.y + radius))
        }
        context.stroke(stem, with: .color(color(palette.leafShade).opacity(0.7)), lineWidth: max(0.6, radius * 0.3))
        for petal in 0..<5 {
            let angle = Double(petal) * .pi * 2 / 5
            let x = p.x + CGFloat(cos(angle)) * radius * 0.7
            let y = p.y + CGFloat(sin(angle)) * radius * 0.7
            let rect = CGRect(x: x - radius * 0.53, y: y - radius * 0.53, width: radius * 1.06, height: radius * 1.06)
            context.fill(Path(ellipseIn: rect.offsetBy(dx: 0.4, dy: 0.7)), with: .color(color(palette.leafShade).opacity(0.24)))
            context.fill(Path(ellipseIn: rect), with: .linearGradient(Gradient(colors: [color(0xFFFFF3), color(0xF6EED0)]),
                                                                     startPoint: CGPoint(x: rect.minX, y: rect.minY), endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
        }
        context.fill(Path(ellipseIn: CGRect(x: p.x - radius * 0.35, y: p.y - radius * 0.35, width: radius * 0.7, height: radius * 0.7)),
                     with: .radialGradient(Gradient(colors: [color(0xFFF5A7), color(0xE5B637)]),
                                           center: CGPoint(x: p.x - radius * 0.11, y: p.y - radius * 0.13), startRadius: 0, endRadius: radius * 0.65))
    }

    private func palm(at p: CGPoint, height: CGFloat, opacity: Double) {
        var c = context
        c.opacity = opacity
        var trunk = Path()
        trunk.move(to: p)
        trunk.addQuadCurve(to: CGPoint(x: p.x + height * 0.14, y: p.y - height),
                           control: CGPoint(x: p.x - height * 0.05, y: p.y - height * 0.6))
        c.stroke(trunk, with: .color(color(palette.leafShade)), style: StrokeStyle(lineWidth: height * 0.07, lineCap: .round))
        let painter = ResultLandscapePainter(context: c, size: size, palette: palette)
        for angle in [-95.0, -60, -24, 20, 58, 92] {
            painter.leaf(at: CGPoint(x: p.x + height * 0.14, y: p.y - height), length: height * 0.55,
                         width: height * 0.18, angle: angle, bright: false)
        }
    }

    private func cloud(at p: CGPoint, width: CGFloat, opacity: Double) {
        context.drawLayer { c in
            c.opacity = opacity
            c.addFilter(.blur(radius: 1.8 * scale))
            for (x, y, s) in [(CGFloat(-0.32), CGFloat(0.08), CGFloat(0.64)), (-0.10, -0.04, 0.76), (0.19, 0.06, 0.66), (0.39, 0.12, 0.44)] {
                let rect = CGRect(x: p.x + x * width - width * s / 2, y: p.y + y * width - width * s * 0.45,
                                  width: width * s, height: width * s * 0.74)
                c.fill(Path(ellipseIn: rect), with: .linearGradient(Gradient(colors: [color(0xFFFFF1), color(palette.skyBottom)]),
                                                                  startPoint: CGPoint(x: rect.midX, y: rect.minY), endPoint: CGPoint(x: rect.midX, y: rect.maxY)))
            }
        }
    }

    private func hill(start: CGPoint, peak: CGPoint, end: CGPoint, top: Color, bottom: Color) {
        var path = Path()
        path.move(to: start)
        path.addCurve(to: peak, control1: CGPoint(x: start.x + (peak.x - start.x) * 0.1, y: peak.y + h * 0.02),
                      control2: CGPoint(x: peak.x - w * 0.10, y: peak.y - h * 0.03))
        path.addCurve(to: end, control1: CGPoint(x: peak.x + w * 0.16, y: peak.y - h * 0.02),
                      control2: CGPoint(x: end.x - w * 0.16, y: end.y - h * 0.02))
        path.addLine(to: CGPoint(x: end.x, y: h * 0.83))
        path.addLine(to: CGPoint(x: start.x, y: h * 0.83))
        path.closeSubpath()
        context.fill(path, with: .linearGradient(Gradient(colors: [top, bottom]), startPoint: peak, endPoint: CGPoint(x: peak.x, y: h * 0.80)))
        context.drawLayer { c in
            c.clip(to: path)
            // Irregular treetops have no circular spots or repeating grid.
            for index in 0..<350 {
                let x = noise(index, seed: 4367)
                let y = peak.y + noise(index, seed: 8707) * (h * 0.80 - peak.y)
                let depth = min(1, max(0, (y / h - 0.40) / 0.35))
                let r = (1.4 + depth * 3.0 + noise(index, seed: 4703) * 1.5) * scale
                let rect = CGRect(x: w * x - r, y: y - r, width: r * 2.0, height: r * 2.3)
                let crown = treetop(in: rect)
                c.fill(crown, with: .linearGradient(Gradient(colors: [
                    color(palette.grassLight).opacity(0.14), color(palette.hillNear).opacity(0.04),
                    color(palette.leafShade).opacity(0.08)
                ]), startPoint: CGPoint(x: rect.minX, y: rect.minY), endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
            }
        }
    }

    private func treetop(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + r.width * x, y: r.minY + r.height * y) }
        return Path { path in
            path.move(to: p(0.08, 0.76))
            path.addCurve(to: p(0.05, 0.40), control1: p(-0.05, 0.68), control2: p(-0.02, 0.47))
            path.addCurve(to: p(0.26, 0.19), control1: p(-0.03, 0.23), control2: p(0.12, 0.15))
            path.addCurve(to: p(0.52, 0.06), control1: p(0.29, -0.02), control2: p(0.46, -0.01))
            path.addCurve(to: p(0.80, 0.20), control1: p(0.63, -0.03), control2: p(0.79, 0.04))
            path.addCurve(to: p(0.96, 0.47), control1: p(0.97, 0.17), control2: p(1.04, 0.35))
            path.addCurve(to: p(0.87, 0.82), control1: p(1.06, 0.61), control2: p(1.0, 0.77))
            path.addCurve(to: p(0.08, 0.76), control1: p(0.74, 1.08), control2: p(0.21, 1.02))
            path.closeSubpath()
        }
    }

    private func glow(at center: CGPoint, radius: CGFloat, colors: [Color]) {
        context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: colors), center: center, startRadius: 0, endRadius: radius))
    }

    private func ellipticalGlow(in rect: CGRect, colors: [Color]) {
        var c = context
        c.translateBy(x: rect.midX, y: rect.midY)
        c.scaleBy(x: rect.width / 2, y: rect.height / 2)
        c.fill(Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2)),
               with: .radialGradient(Gradient(colors: colors), center: .zero, startRadius: 0, endRadius: 1))
    }

    private func ellipse(_ rect: CGRect, color: Color) {
        context.fill(Path(ellipseIn: rect), with: .color(color))
    }
}

/// Wide tapered rays fade out into the scenery, leaving a warm focal light behind Dino.
private struct ResultSunburst: View {
    let worldID: Int
    var strength: Double
    var body: some View {
        let palette = ResultPodiumPalette(worldID: worldID)
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let reach = min(size.width, size.height) * 0.50
            for index in 0..<14 {
                var ray = context
                ray.translateBy(x: center.x, y: center.y)
                ray.rotate(by: .degrees(Double(index) * (360.0 / 14) + 9))
                let length = reach * (index.isMultiple(of: 2) ? 1 : 0.84)
                var wedge = Path()
                wedge.move(to: .zero)
                wedge.addLine(to: CGPoint(x: -length * 0.14, y: -length))
                wedge.addQuadCurve(to: CGPoint(x: length * 0.14, y: -length), control: CGPoint(x: 0, y: -length * 1.03))
                wedge.closeSubpath()
                ray.fill(wedge, with: .linearGradient(Gradient(colors: [
                    Color(dinoHex: palette.glow).opacity(0.22 * strength),
                    Color(dinoHex: palette.glow).opacity(0.09 * strength), .clear
                ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: -length)))
            }
            context.fill(Path(ellipseIn: CGRect(origin: .zero, size: size)), with: .radialGradient(Gradient(colors: [
                Color(dinoHex: palette.glow).opacity(0.52 * strength),
                Color(dinoHex: palette.glow).opacity(0.30 * strength),
                Color(dinoHex: palette.glow).opacity(0.06 * strength), .clear
            ]), center: center, startRadius: 0, endRadius: reach * 0.85))
        }
        .animation(.easeOut(duration: 0.45), value: strength)
        .accessibilityHidden(true)
    }
}

/// Small suspended flecks keep the final composition festive after the confetti has landed.
private struct ResultCelebrationMotes: View {
    let worldID: Int
    let active: Bool
    var body: some View {
        Canvas { context, size in
            guard active else { return }
            let points: [(CGFloat, CGFloat, CGFloat, Double)] = [
                (0.16, 0.22, 8, -16), (0.84, 0.16, 10, 22),
                (0.10, 0.48, 12, -12), (0.89, 0.43, 8, 15),
                (0.23, 0.61, 6, 8), (0.78, 0.63, 7, -10),
                (0.30, 0.12, 3, 0), (0.71, 0.31, 4, 0)
            ]
            for (index, item) in points.enumerated() {
                var spark = context
                spark.translateBy(x: size.width * item.0, y: size.height * item.1)
                spark.rotate(by: .degrees(item.3))
                if index < 6 {
                    let r = item.2
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: -r))
                    path.addQuadCurve(to: CGPoint(x: r * 0.65, y: 0), control: CGPoint(x: r * 0.18, y: -r * 0.16))
                    path.addQuadCurve(to: CGPoint(x: 0, y: r), control: CGPoint(x: r * 0.18, y: r * 0.16))
                    path.addQuadCurve(to: CGPoint(x: -r * 0.65, y: 0), control: CGPoint(x: -r * 0.18, y: r * 0.16))
                    path.addQuadCurve(to: CGPoint(x: 0, y: -r), control: CGPoint(x: -r * 0.18, y: -r * 0.16))
                    spark.fill(path, with: .linearGradient(Gradient(colors: [Color(dinoHex: ResultPodiumPalette(worldID: worldID).glow), Color(dinoHex: ResultPodiumPalette(worldID: worldID).accent)]),
                        startPoint: CGPoint(x: 0, y: -r), endPoint: CGPoint(x: 0, y: r)))
                } else {
                    spark.fill(Path(ellipseIn: CGRect(x: -item.2 / 2, y: -item.2 / 2, width: item.2, height: item.2)), with: .color(.white.opacity(0.9)))
                }
            }
        }.accessibilityHidden(true)
    }
}

private struct ResultStarReward: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let count: Int
    let revealed: Int
    var size: CGFloat
    var body: some View {
        HStack(alignment: .center, spacing: -size * 0.02) {
            ForEach(0..<3, id: \.self) { index in
                star(index)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(min(count, 3))/3"))
        .accessibilityIdentifier("result.stars")
    }

    private func star(_ index: Int) -> some View {
        let shown = index < revealed
        let scale: CGFloat = index == 1 ? 1.08 : 0.96
        return ZStack {
            // Empty slots stay on the stone while only earned gold stars fly in.
            DinoRewardStar(size: size, earned: false, dimmed: true)
                .scaleEffect(scale)
            if index < count {
                DinoRewardStar(size: size, glowing: true, showsSparkle: true)
                    .opacity(shown ? 1 : 0)
                    .scaleEffect(scale * (shown ? 1 : 0.3))
                    .offset(y: shown ? 0 : -size * 0.07)
                    .animation(reduceMotion ? nil : .spring(response: 0.48, dampingFraction: 0.62), value: shown)
            }
        }
        .offset(y: index == 1 ? -size * 0.08 : size * 0.01)
        .rotationEffect(.degrees(index == 1 ? 0 : index == 0 ? -6 : 6))
    }
}

/// A short burst that starts behind Dino and arcs outward once the third star has settled.
private struct ResultConfetti: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var started = Date()
    @State private var finished = false
    private let colors: [UInt32] = [0xFFD24A, 0x7ED24A, 0xFFF6C8, 0xF0B429, 0x5AAA40]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: finished || reduceMotion || scenePhase != .active)) { timeline in
            let elapsed = reduceMotion ? 0.7 : timeline.date.timeIntervalSince(started)
            Canvas { context, size in
                let origin = CGPoint(x: size.width / 2, y: size.height * 0.58)
                for index in 0..<40 {
                    let angle = -.pi * 0.08 - (.pi * 0.84) * Double(index % 20) / 19
                    let delay = index < 20 ? 0 : 0.06
                    let progress = reduceMotion ? 0.55 : min(1, max(0, elapsed - delay) / 1.65)
                    guard progress > 0 else { continue }
                    let speed = 120 + CGFloat(index % 6) * 34
                    let x = origin.x + CGFloat(cos(angle)) * speed * progress * 1.35
                    let y = origin.y + CGFloat(sin(angle)) * speed * progress + 210 * progress * progress
                    var piece = context
                    piece.opacity = progress < 0.72 ? 1 : max(0, 1 - (progress - 0.72) / 0.28)
                    piece.translateBy(x: x, y: y)
                    piece.rotate(by: .degrees(Double(index) * 28 + progress * 220))
                    let color = Color(dinoHex: colors[index % colors.count])
                    if index % 4 == 0 {
                        piece.fill(starPath(radius: index % 8 == 0 ? 8 : 6), with: .color(color))
                    } else if index % 4 == 1 {
                        piece.fill(Path(ellipseIn: CGRect(x: -8, y: -3.5, width: 16, height: 7)), with: .color(color))
                    } else {
                        piece.fill(Path(roundedRect: CGRect(x: -4, y: -6, width: 8, height: 12), cornerRadius: 2), with: .color(color))
                    }
                }
            }
        }
        .task {
            do { try await Task.sleep(for: .seconds(1.8)) } catch { return }
            finished = true
        }
    }

    private func starPath(radius: CGFloat) -> Path {
        var path = Path()
        for point in 0..<10 {
            let angle = CGFloat(point) * .pi / 5 - .pi / 2
            let length = point.isMultiple(of: 2) ? radius : radius * 0.42
            let next = CGPoint(x: cos(angle) * length, y: sin(angle) * length)
            if point == 0 { path.move(to: next) } else { path.addLine(to: next) }
        }
        path.closeSubpath()
        return path
    }
}
