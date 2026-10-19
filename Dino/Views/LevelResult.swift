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
    @State private var rewardSettled = false
    @State private var confetti = false
    private var succeeded: Bool { result.level.isBoss ? result.victory != .none : result.stars > 0 }
    private var nextAvailable: Bool { result.level.isBoss ? succeeded : player.profile.isUnlocked(result.level.id + 1) }

    var body: some View {
        GeometryReader { geometry in
            let layout = ResultLayout(size: geometry.size, needsMessage: !succeeded)
            ZStack {
                ResultScenery(worldID: result.level.worldID)
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.65), lineWidth: 1))
        .accessibilityIdentifier("result.score")
    }

    /// The jump finishes on the rock first. Earned stars then drop in one by one,
    /// and a three-star landing sends confetti out from behind Dino.
    private func playReward() async {
        starsRevealed = 0
        rewardSettled = false
        confetti = false
        guard !result.level.isBoss else { return }
        if reduceMotion {
            starsRevealed = result.stars
            rewardSettled = true
            confetti = result.stars >= 3
            return
        }
        let clip = result.animationClip
        let landing = clip == .backflip || clip == .pirouette
            ? DinoAnimation.travelDuration(clip) + 0.04 : (succeeded ? 0.4 : 0.15)
        try? await Task.sleep(for: .seconds(landing))
        guard !Task.isCancelled else { return }
        for index in 0..<min(result.stars, 3) {
            starsRevealed = index + 1
            let settles = index == result.stars - 1 ? 0.44 : 0.3
            try? await Task.sleep(for: .seconds(settles))
            guard !Task.isCancelled else { return }
        }
        rewardSettled = true
        if result.stars >= 3 { confetti = true }
    }

    private func stage(layout: ResultLayout) -> some View {
        ZStack(alignment: .bottom) {
            ResultSunburst(strength: succeeded ? (starsRevealed > 0 ? 1 : 0.78) : 0.3)
                .frame(width: layout.podiumWidth * 1.38, height: layout.podiumWidth * 1.38)
                .position(x: layout.stageWidth / 2, y: layout.dinoCenterY + layout.dinoSize * 0.05)
            Ellipse()
                .fill(Color(dinoHex: 0x355D29).opacity(0.25))
                .frame(width: layout.podiumWidth * 0.88, height: layout.podiumHeight * 0.10)
                .blur(radius: 6)
                .position(x: layout.podiumCenterX, y: layout.stageHeight + layout.podiumLift - 7)
            ResultRockPlanting(worldID: result.level.worldID)
                .frame(width: layout.podiumWidth * 1.20, height: layout.podiumHeight * 1.36)
                .position(x: layout.podiumCenterX, y: layout.stageHeight - layout.podiumHeight * 0.68 + layout.podiumLift)
            ResultRock(worldID: result.level.worldID)
                .frame(width: layout.podiumWidth, height: layout.podiumHeight)
                .position(x: layout.podiumCenterX, y: layout.stageHeight - layout.podiumHeight / 2 + layout.podiumLift)
            Ellipse()
                .fill(Color(dinoHex: 0x304627).opacity(0.24))
                .frame(width: layout.dinoSize * 0.55, height: layout.dinoSize * 0.055)
                .blur(radius: 3)
                .position(x: layout.podiumCenterX, y: layout.contactY)
            character(size: layout.dinoSize)
                .position(x: layout.stageWidth / 2, y: layout.dinoCenterY)
            // Taller corner leaves grow in front of the stone, with the reward above them.
            ResultRockPlanting(worldID: result.level.worldID, foreground: true)
                .frame(width: layout.podiumWidth * (result.level.worldID == 2 ? 1.08 : 1.18),
                       height: layout.podiumHeight * (result.level.worldID == 2 ? 0.45 : 0.82))
                .position(x: layout.podiumCenterX,
                          y: layout.stageHeight + layout.podiumLift + 3 - layout.podiumHeight * (result.level.worldID == 2 ? 0.09 : 0.34))
            if !result.level.isBoss {
                ResultStarReward(count: result.stars, revealed: starsRevealed,
                                 settled: rewardSettled, size: layout.starSize)
                    .position(x: layout.podiumCenterX, y: layout.rewardCenterY)
            } else if succeeded {
                Image("result-trophy").resizable().scaledToFit()
                    .frame(width: layout.starSize * 1.65, height: layout.starSize * 1.65)
                    .shadow(color: Color(dinoHex: 0xFFE56A).opacity(0.65), radius: 14)
                    .shadow(color: Color(dinoHex: 0x603E12).opacity(0.25), radius: 3, y: 5)
                    .position(x: layout.podiumCenterX, y: layout.stageHeight - layout.podiumHeight * 0.39 + layout.podiumLift)
                    .accessibilityHidden(true)
            }
            ResultCelebrationMotes(active: succeeded)
                .allowsHitTesting(false)
            if confetti {
                ResultConfetti()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: layout.stageWidth, height: layout.stageHeight)
    }

    private func character(size: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) {
            if sharedCompanion {
                DinoCompanionAnchor(placement: .result, size: size)
            } else {
                DinoCharacter(state: succeeded ? .celebrating : .thinking, size: size,
                              performsBackflip: result.animationClip == .backflip,
                              performsPirouette: result.animationClip == .pirouette)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            if nextAvailable {
                Button(action: next) {
                    HStack(spacing: 12) {
                        Spacer(minLength: 0)
                        Text(LocalizedStringKey(result.level.isBoss ? "dino.worldComplete" : "dino.next"))
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

/// Reserve space for the controls first, then scale the illustration as one scene.
/// This keeps Dino's feet, the rock and the stars registered on every window size.
private struct ResultLayout {
    let size: CGSize
    let needsMessage: Bool
    var topInset: CGFloat { size.height < 650 ? 0 : 8 }
    var signWidth: CGFloat { min(size.width * 0.96, size.height * 0.56, 500) }
    var signHeight: CGFloat { signWidth * 0.36 }
    var actionWidth: CGFloat { min(size.width - 40, 430) }
    var stageWidth: CGFloat { min(size.width * 1.12, 700) }
    var availableHeight: CGFloat { max(160, size.height - signHeight - topInset - (needsMessage ? 224 : 194)) }
    var dinoSize: CGFloat { min(size.width * 0.73, availableHeight / 1.65, 360) }
    var podiumWidth: CGFloat { min(stageWidth * 0.88, dinoSize * 1.62) }
    var podiumHeight: CGFloat { podiumWidth / 2.2 }
    var podiumCenterX: CGFloat { stageWidth / 2 + dinoSize * 0.04 }
    var podiumLift: CGFloat { -dinoSize * 0.015 }
    var stageHeight: CGFloat { min(availableHeight, dinoSize + podiumHeight * 0.85 + 20) }
    var contactY: CGFloat { stageHeight - podiumHeight * 0.82 + podiumLift }
    var dinoCenterY: CGFloat { contactY - dinoSize * 0.44 }
    var starSize: CGFloat { min(podiumWidth * 0.23, 122) }
    var rewardCenterY: CGFloat { stageHeight - podiumHeight * 0.35 + podiumLift }
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

/// Independent native layers can later animate or change palette per world.
/// No flattened background image is used by the result scene.
private struct ResultScenery: View {
    let worldID: Int
    var windPhase: Double = 0

    var body: some View {
        let palette = ResultLandscapePalette(worldID: worldID)
        ZStack {
            if worldID == 2 {
                Canvas(rendersAsynchronously: true) { context, size in
                    DinoDesertPainter(context: context).rewardLandscape(in: size)
                }
            } else {
                ForEach(ResultLandscapeLayer.allCases, id: \.self) { layer in
                    Canvas(rendersAsynchronously: true) { context, size in
                        ResultLandscapePainter(context: context, size: size, palette: palette,
                                               windPhase: windPhase).draw(layer)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private enum ResultLandscapeLayer: CaseIterable { case sky, distance, meadow, foliage }

/// Plants share the stone's own coordinates, so the base never floats above its lawn.
private struct ResultRockPlanting: View {
    let worldID: Int
    var foreground = false
    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            if worldID == 2 {
                DinoDesertPainter(context: context).rewardGroundCover(in: size, foreground: foreground)
                return
            }
            let painter = ResultLandscapePainter(context: context, size: size,
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
        for index in 0..<20 {
            let side = index.isMultiple(of: 2)
            let x: CGFloat = side ? 0.035 + CGFloat(index % 5) * 0.035 : 0.83 + CGFloat(index % 5) * 0.035
            let y: CGFloat = 0.76 + CGFloat(index % 7) * 0.036
            flower(at: point(x, y), radius: (1.5 + CGFloat(index % 3) * 0.8) * scale)
        }
    }

    private func foliage() {
        canopy(mirrored: false)
        canopy(mirrored: true)
        vine(mirrored: false)
        vine(mirrored: true)
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
        let unit = w / 470
        mossMat(in: CGRect(x: w * 0.025, y: h * 0.89, width: w * 0.95, height: h * 0.10), seed: 7727)
        for side in 0..<2 {
            var c = context
            c.translateBy(x: side == 0 ? 0 : w, y: 0)
            c.scaleBy(x: side == 0 ? 1 : -1, y: 1)
            let painter = ResultLandscapePainter(context: c, size: size, palette: palette)
            // These roots share the podium baseline on every device size.
            painter.rosette(at: CGPoint(x: w * 0.14, y: h * 0.90), length: 173 * unit,
                            lean: side == 0 ? -21 : -9, seed: side + 2)
            painter.rosette(at: CGPoint(x: w * 0.065, y: h * 0.98), length: 69 * unit,
                            lean: 31, seed: side + 6)
            painter.fern(at: CGPoint(x: w * 0.10, y: h * 0.97), length: 47 * unit, angle: -28)
            painter.flower(at: CGPoint(x: w * 0.115, y: h * 0.92), radius: 4.2 * unit)
            painter.flower(at: CGPoint(x: w * 0.055, y: h * 0.955), radius: 3.2 * unit)
        }
    }

    func stoneGroundCover() {
        let unit = w / 420
        // Roots stay on the shared ground line; the larger leaves overlap the side faces.
        let mound = CGRect(x: w * 0.04, y: h * 0.84, width: w * 0.92, height: h * 0.12)
        ellipticalGlow(in: mound, colors: [
            color(palette.grassShade).opacity(0.48), color(palette.grass).opacity(0.24), .clear
        ])
        mossMat(in: CGRect(x: w * 0.012, y: h * 0.87, width: w * 0.976, height: h * 0.13), seed: 4283)
        for index in 0..<54 {
            let x = noise(index, seed: 9821)
            let y = h * (0.90 + noise(index, seed: 2731) * 0.07)
            let edge = abs(x - 0.5) * 2
            let s = (0.30 + edge * 0.30 + CGFloat(index % 4) * 0.055) * unit
            grass(at: CGPoint(x: w * x, y: y), scale: s, light: index % 3 != 0, opacity: 0.96)
        }
        for side in 0..<2 {
            var c = context
            c.translateBy(x: side == 0 ? 0 : w, y: 0)
            c.scaleBy(x: side == 0 ? 1 : -1, y: 1)
            let painter = ResultLandscapePainter(context: c, size: size, palette: palette)
            let root = CGPoint(x: w * 0.10, y: h * (side == 0 ? 0.91 : 0.93))
            for (index, angle) in [-40.0, -13, 20, 48, 74].enumerated() {
                let reach = CGFloat([0.14, 0.215, 0.198, 0.16, 0.125][index])
                let length = w * reach * (side == 0 ? 1 : 0.93)
                painter.leaf(at: root, length: length, width: length * 0.52,
                             angle: angle + (side == 0 ? 0 : 6), bright: index == 2)
            }
            // A smaller second spray covers the roots and breaks up the mirrored outline.
            painter.leaf(at: CGPoint(x: root.x + w * 0.035, y: root.y + h * 0.025),
                         length: w * 0.115, width: w * 0.055, angle: 57, bright: true)
            painter.flower(at: CGPoint(x: w * 0.13, y: h * 0.83), radius: 4.0 * unit)
            painter.flower(at: CGPoint(x: w * 0.075, y: h * 0.90), radius: 2.8 * unit)
        }
        for (index, x) in [CGFloat(0.39), 0.58, 0.72].enumerated() {
            let root = CGPoint(x: w * x, y: h * 0.965)
            for angle in [-32.0, 8, 39] {
                leaf(at: root, length: w * (index == 1 ? 0.060 : 0.042),
                     width: w * 0.016, angle: angle, bright: angle == 8)
            }
        }
    }

    private func mossMat(in rect: CGRect, seed: UInt64) {
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        var mat = Path()
        mat.move(to: at(0.015, 0.55))
        for index in 0..<32 {
            let x = CGFloat(index) / 32
            let next = CGFloat(index + 1) / 32
            let y = 0.16 + noise(index, seed: seed) * 0.28
            mat.addQuadCurve(to: at(next, 0.24 + noise(index + 1, seed: seed) * 0.30),
                             control: at((x + next) / 2, y - 0.28))
        }
        mat.addQuadCurve(to: at(0.97, 0.88), control: at(1.025, 0.80))
        for index in stride(from: 31, through: 0, by: -1) {
            let x = CGFloat(index) / 32
            mat.addQuadCurve(to: at(x, 0.81 + noise(index, seed: seed + 241) * 0.17),
                             control: at(x + 0.015, 1.06))
        }
        mat.addQuadCurve(to: at(0.015, 0.55), control: at(-0.02, 0.80))
        mat.closeSubpath()
        ResultMossPainter(context: context, palette: palette).patch(mat, seed: seed, cushions: 12)
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

    private func canopy(mirrored: Bool) {
        var c = context
        c.translateBy(x: mirrored ? w : 0, y: 0)
        c.scaleBy(x: mirrored ? -1 : 1, y: 1)
        let painter = ResultLandscapePainter(context: c, size: size, palette: palette, windPhase: windPhase)
        var branch = Path()
        branch.move(to: CGPoint(x: -35 * scale, y: 130 * scale))
        branch.addCurve(to: CGPoint(x: 145 * scale, y: -30 * scale),
                        control1: CGPoint(x: 35 * scale, y: 43 * scale),
                        control2: CGPoint(x: 64 * scale, y: 23 * scale))
        c.stroke(branch, with: .color(color(palette.leafShade)), style: StrokeStyle(lineWidth: 19 * scale, lineCap: .round))
        c.stroke(branch, with: .linearGradient(Gradient(colors: [color(palette.bark), color(0xBDA56B)]),
                                               startPoint: .zero, endPoint: CGPoint(x: 100, y: 100)),
                 style: StrokeStyle(lineWidth: 12 * scale, lineCap: .round))
        let leaves: [(CGFloat, CGFloat, CGFloat, Double)] = [
            (-12, 12, 91, 155), (13, -15, 110, 124), (53, -20, 93, 158),
            (104, -26, 96, 113), (-18, 63, 82, 148), (15, 24, 85, 185),
            (76, -26, 71, 211), (118, -31, 76, 165), (-13, 102, 63, 133),
            (32, -4, 62, 153), (5, 54, 63, 119), (67, -12, 59, 121)
        ]
        for (index, item) in leaves.enumerated() {
            let drift = sin(windPhase + Double(index) * 0.8) * (windPhase == 0 ? 0 : 2)
            painter.leaf(at: CGPoint(x: item.0 * scale, y: item.1 * scale), length: item.2 * scale,
                         width: item.2 * 0.48 * scale, angle: item.3 + drift, bright: index.isMultiple(of: 2))
        }
    }

    private func vine(mirrored: Bool) {
        var c = context
        c.translateBy(x: mirrored ? w : 0, y: 0)
        c.scaleBy(x: mirrored ? -1 : 1, y: 1)
        let start = CGPoint(x: 14 * scale, y: -10)
        let first = CGPoint(x: 49 * scale, y: h * 0.12)
        let second = CGPoint(x: -7 * scale, y: h * 0.23)
        let end = CGPoint(x: 7 * scale, y: h * 0.34)
        var line = Path()
        line.move(to: start)
        line.addCurve(to: end, control1: first, control2: second)
        c.stroke(line, with: .color(color(palette.leafShade).opacity(0.7)), style: StrokeStyle(lineWidth: 3 * scale, lineCap: .round))
        let painter = ResultLandscapePainter(context: c, size: size, palette: palette)
        for index in 0..<6 {
            // The leaf root lies on the very same cubic as its supporting vine.
            let t = CGFloat(0.32) + CGFloat(index) * 0.112, u = 1 - t
            let root = CGPoint(x: u * u * u * start.x + 3 * u * u * t * first.x + 3 * u * t * t * second.x + t * t * t * end.x,
                               y: u * u * u * start.y + 3 * u * u * t * first.y + 3 * u * t * t * second.y + t * t * t * end.y)
            painter.leaf(at: root, length: 26 * scale,
                         width: 11 * scale, angle: index.isMultiple(of: 2) ? 64 : -72, bright: true)
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
    var strength: Double
    var body: some View {
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
                    Color(dinoHex: 0xFFFBC9).opacity(0.30 * strength),
                    Color(dinoHex: 0xFFFAAE).opacity(0.13 * strength), .clear
                ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: -length)))
            }
            context.fill(Path(ellipseIn: CGRect(origin: .zero, size: size)), with: .radialGradient(Gradient(colors: [
                Color(dinoHex: 0xFFFFE8).opacity(0.90 * strength),
                Color(dinoHex: 0xFFF9AD).opacity(0.60 * strength),
                Color(dinoHex: 0xFFF4A0).opacity(0.12 * strength), .clear
            ]), center: center, startRadius: 0, endRadius: reach * 0.85))
        }
        .animation(.easeOut(duration: 0.45), value: strength)
        .accessibilityHidden(true)
    }
}

private struct ResultRock: View {
    let worldID: Int
    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            var art = context
            art.scaleBy(x: size.width / 1000, y: size.height / 455)
            ResultStonePainter(context: art, palette: ResultLandscapePalette(worldID: worldID))
                .draw(hasMoss: worldID != 2)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The former 2.2:1 sprite's silhouette and top plane, expressed entirely as paths.
/// Drawing coordinates are fixed; the scene scales feet, rock and plants together.
private struct ResultStonePainter {
    let context: GraphicsContext
    let palette: ResultLandscapePalette
    private func color(_ hex: UInt32) -> Color { Color(dinoHex: hex) }
    private func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
    // One mineral palette picks up the clearing's light and reflected ground colour.
    // Individual facets vary in exposure, rather than switching to unrelated greys.
    private var coolLight: Bool { palette.night || palette.themeID == 5 }
    private var light: UInt32 { ResultLandscapePalette.mix(coolLight ? 0xDDE8E3 : 0xEFE3BC, palette.grassLight, 0.17) }
    private var face: UInt32 { ResultLandscapePalette.mix(coolLight ? 0xA2B6B8 : 0xC1B792, palette.hillNear, 0.16) }
    private var shade: UInt32 { ResultLandscapePalette.mix(coolLight ? 0x6E858A : 0x85846B, palette.grassShade, 0.27) }
    private func noise(_ index: Int, seed: UInt64) -> CGFloat {
        var value = UInt64(index) &+ seed
        value = (value ^ (value >> 16)) &* 0x45D9F3B
        value = (value ^ (value >> 16)) &* 0x45D9F3B
        value ^= value >> 16
        return CGFloat(value & 65535) / 65535
    }

    private var silhouette: Path {
        Path { p in
            p.move(to: point(156, 66))
            p.addCurve(to: point(500, 16), control1: point(224, 20), control2: point(377, 11))
            p.addCurve(to: point(834, 58), control1: point(642, 8), control2: point(786, 16))
            p.addCurve(to: point(882, 99), control1: point(863, 67), control2: point(872, 81))
            p.addCurve(to: point(982, 267), control1: point(932, 148), control2: point(975, 228))
            p.addCurve(to: point(985, 310), control1: point(992, 286), control2: point(992, 294))
            p.addCurve(to: point(924, 402), control1: point(969, 348), control2: point(951, 392))
            p.addCurve(to: point(721, 444), control1: point(887, 433), control2: point(800, 440))
            p.addCurve(to: point(361, 448), control1: point(609, 453), control2: point(452, 453))
            p.addCurve(to: point(121, 430), control1: point(245, 447), control2: point(157, 447))
            p.addCurve(to: point(66, 388), control1: point(94, 421), control2: point(80, 406))
            p.addCurve(to: point(22, 321), control1: point(44, 363), control2: point(30, 341))
            p.addCurve(to: point(20, 281), control1: point(17, 312), control2: point(16, 298))
            p.addCurve(to: point(65, 166), control1: point(23, 249), control2: point(43, 201))
            p.addCurve(to: point(156, 66), control1: point(97, 125), control2: point(126, 90))
            p.closeSubpath()
        }
    }

    private var topPlane: Path {
        Path { p in
            p.move(to: point(156, 66))
            p.addCurve(to: point(500, 16), control1: point(224, 20), control2: point(377, 11))
            p.addCurve(to: point(834, 58), control1: point(642, 8), control2: point(786, 16))
            p.addCurve(to: point(882, 99), control1: point(863, 67), control2: point(872, 81))
            p.addQuadCurve(to: point(845, 107), control: point(898, 114))
            p.addCurve(to: point(634, 104), control1: point(774, 105), control2: point(703, 103))
            p.addCurve(to: point(414, 110), control1: point(548, 105), control2: point(489, 112))
            p.addCurve(to: point(197, 104), control1: point(324, 108), control2: point(252, 111))
            p.addQuadCurve(to: point(150, 81), control: point(150, 97))
            p.addQuadCurve(to: point(156, 66), control: point(147, 74))
            p.closeSubpath()
        }
    }

    func draw(hasMoss: Bool) {
        context.drawLayer { clipped in
            clipped.clip(to: silhouette)
            let stone = ResultStonePainter(context: clipped, palette: palette)
            stone.material()
            stone.grain()
            stone.topSurface()
        }
        if hasMoss { caps() }
    }

    private func roundedFacet(_ vertices: [(CGFloat, CGFloat)], rounding: CGFloat = 0.08) -> Path {
        let points = vertices.map { point($0.0, $0.1) }
        func blend(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
            CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
        }
        return Path { p in
            guard let first = points.first, let last = points.last else { return }
            p.move(to: blend(last, first, 1 - rounding))
            for index in points.indices {
                let at = points[index], next = points[(index + 1) % points.count]
                p.addQuadCurve(to: blend(at, next, rounding), control: at)
                p.addLine(to: blend(at, next, 1 - rounding))
            }
            p.closeSubpath()
        }
    }

    private func facet(_ vertices: [(CGFloat, CGFloat)], exposure: Double) {
        let path = roundedFacet(vertices), bounds = path.boundingRect
        let mid = ResultLandscapePalette.mix(shade, face, exposure)
        context.fill(path, with: .radialGradient(Gradient(stops: [
            .init(color: color(ResultLandscapePalette.mix(mid, light, 0.24)), location: 0),
            .init(color: color(mid), location: 0.60),
            .init(color: color(ResultLandscapePalette.mix(mid, shade, 0.20)), location: 1)
        ]), center: point(bounds.minX + bounds.width * 0.34, bounds.minY + bounds.height * 0.20),
            startRadius: 0, endRadius: max(bounds.width, bounds.height) * 1.12))
    }

    private func material() {
        context.fill(silhouette, with: .linearGradient(Gradient(colors: [color(light), color(face), color(shade)]),
                                                       startPoint: point(530, 65), endPoint: point(500, 455)))
        facet([(8, 300), (62, 161), (156, 66), (199, 105), (179, 155), (151, 213), (86, 322), (62, 391)],
              exposure: 0.57)
        facet([(199, 104), (337, 106), (438, 140), (379, 196), (252, 246), (151, 213), (179, 145)],
              exposure: 0.96)
        facet([(151, 213), (252, 246), (379, 196), (348, 332), (232, 399), (219, 450), (111, 438), (62, 389)],
              exposure: 0.70)
        facet([(348, 332), (412, 401), (462, 453), (354, 456), (219, 450), (232, 399)],
              exposure: 0.61)
        facet([(438, 140), (534, 187), (699, 166), (768, 259), (733, 321), (585, 452),
               (462, 453), (412, 401), (348, 332)],
              exposure: 0.86)
        facet([(438, 140), (472, 108), (589, 104), (661, 105), (699, 166), (558, 194), (534, 187)],
              exposure: 1.10)
        facet([(661, 105), (838, 105), (875, 135), (887, 211), (857, 258), (768, 259), (699, 166)],
              exposure: 1.06)
        facet([(838, 105), (882, 99), (988, 266), (993, 312), (928, 409), (914, 351), (857, 258), (887, 211), (875, 135)],
              exposure: 0.94)
        facet([(768, 259), (853, 279), (908, 336), (929, 408), (825, 442), (585, 452), (648, 391), (733, 321)],
              exposure: 0.77)
        // A few connected seams describe one boulder rather than separate outlined tiles.
        seam([(199, 105), (179, 156), (151, 213), (86, 322)], highlight: false)
        seam([(438, 140), (401, 203), (348, 332), (411, 399)], highlight: false)
        seam([(661, 105), (699, 166), (768, 259), (733, 321), (648, 391)], highlight: true)
        seam([(768, 259), (815, 264), (857, 280), (908, 336)], highlight: true)
        context.fill(silhouette, with: .linearGradient(Gradient(stops: [
            .init(color: .clear, location: 0), .init(color: .clear, location: 0.50),
            .init(color: color(palette.grassShade).opacity(0.25), location: 1)
        ]), startPoint: point(500, 0), endPoint: point(500, 455)))
        context.fill(silhouette, with: .radialGradient(Gradient(stops: [
            .init(color: color(light).opacity(0.26), location: 0),
            .init(color: .clear, location: 0.56),
            .init(color: color(shade).opacity(0.12), location: 1)
        ]), center: point(540, 100), startRadius: 0, endRadius: 590))
    }

    private func seam(_ vertices: [(CGFloat, CGFloat)], highlight: Bool) {
        var line = Path()
        line.addLines(vertices.map { point($0.0, $0.1) })
        context.stroke(line, with: .color(color(shade).opacity(highlight ? 0.20 : 0.24)),
                       style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
        context.stroke(line.offsetBy(dx: highlight ? 1.2 : -0.8, dy: -0.8),
                       with: .color(color(light).opacity(highlight ? 0.25 : 0.13)),
                       style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
    }

    private func grain() {
        // Deterministic vector grains: no noise texture, bitmap or per-frame random work.
        for index in 0..<130 {
            let x = noise(index, seed: 2731) * 1000
            let y = 80 + noise(index, seed: 8701) * 375
            let r = 0.6 + noise(index, seed: 6619) * 2.5
            let warm = index.isMultiple(of: 3)
            let rect = CGRect(x: x, y: y, width: r * (warm ? 1.8 : 1.1), height: r * 0.8)
            context.fill(Path(ellipseIn: rect), with: .color(color(warm ? light : shade).opacity(0.10)))
        }
        for index in 0..<15 {
            let x = 100 + noise(index, seed: 7627) * 810
            let y = 130 + noise(index, seed: 9151) * 280
            let r = 1.1 + noise(index, seed: 4421) * 3.4
            let pit = CGRect(x: x - r, y: y - r, width: r * 1.8, height: r * 2.0)
            context.fill(Path(ellipseIn: pit.offsetBy(dx: 0.6, dy: 1.1)), with: .color(color(light).opacity(0.12)))
            context.fill(Path(ellipseIn: pit), with: .color(color(shade).opacity(0.16)))
        }
    }

    private func topSurface() {
        context.fill(topPlane, with: .linearGradient(Gradient(stops: [
            .init(color: color(light), location: 0),
            .init(color: color(ResultLandscapePalette.mix(light, face, 0.20)), location: 0.45),
            .init(color: color(ResultLandscapePalette.mix(light, face, 0.37)), location: 0.78),
            .init(color: color(light), location: 1)
        ]), startPoint: point(380, 10), endPoint: point(495, 114)))
        context.drawLayer { c in
            c.clip(to: topPlane)
            c.drawLayer { clouded in
                clouded.addFilter(.blur(radius: 4))
                for index in 0..<10 {
                    let x = 150 + noise(index, seed: 5413) * 740
                    let y = 24 + noise(index, seed: 7507) * 90
                    let rx = 10 + noise(index, seed: 3727) * 48
                    let rect = CGRect(x: x - rx, y: y - rx * 0.18, width: rx * 2, height: rx * 0.36)
                    clouded.fill(Path(ellipseIn: rect), with: .color(color(index.isMultiple(of: 2) ? light : face).opacity(0.13)))
                }
            }
            for index in 0..<35 {
                let x = 140 + noise(index, seed: 1193) * 750
                let y = 15 + noise(index, seed: 3179) * 95
                let rx = 1 + noise(index, seed: 2251) * 8
                let rect = CGRect(x: x, y: y, width: rx, height: rx * 0.23)
                c.fill(Path(ellipseIn: rect), with: .color(color(index.isMultiple(of: 2) ? light : face).opacity(0.14)))
            }
            for (x, y, width) in [(CGFloat(325), CGFloat(62), CGFloat(108)), (680, 62, 138), (520, 36, 70)] {
                var pit = c
                pit.translateBy(x: x, y: y)
                pit.scaleBy(x: width / 2, y: 6)
                pit.fill(Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2)),
                         with: .radialGradient(Gradient(colors: [color(shade).opacity(0.18), .clear]),
                                               center: .zero, startRadius: 0, endRadius: 1))
            }
        }
        var rim = Path()
        rim.move(to: point(161, 86))
        rim.addCurve(to: point(414, 110), control1: point(181, 113), control2: point(330, 107))
        rim.addCurve(to: point(634, 104), control1: point(489, 112), control2: point(549, 105))
        rim.addQuadCurve(to: point(848, 107), control: point(755, 104))
        context.stroke(rim, with: .color(color(light).opacity(0.40)),
                       style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
    }

    private func caps() {
        let moss = ResultMossPainter(context: context, palette: palette)
        func patch(_ points: [(CGFloat, CGFloat)]) -> Path { roundedFacet(points, rounding: 0.36) }
        let left = patch([(155, 109), (170, 98), (195, 94), (217, 100), (247, 99), (274, 106),
                                 (285, 119), (264, 129), (244, 128), (241, 143), (225, 148), (219, 166),
                                 (205, 175), (195, 168), (199, 147), (187, 142), (180, 131), (161, 137), (149, 129)])
        let right = patch([(725, 108), (748, 100), (771, 106), (789, 99), (812, 105), (833, 105),
                                  (862, 117), (882, 131), (889, 151), (883, 162), (889, 181), (881, 199),
                                  (869, 210), (854, 207), (847, 187), (839, 172), (825, 170), (815, 151),
                                  (795, 147), (778, 141), (756, 143), (739, 135), (723, 127)])
        moss.patch(left.applying(CGAffineTransform(a: 1.45, b: 0, c: 0, d: 1, tx: -99, ty: 0)), seed: 713, cushions: 4)
        moss.patch(right.applying(CGAffineTransform(a: 1.22, b: 0, c: 0, d: 1, tx: -178, ty: 0)), seed: 1337, cushions: 5)
        moss.patch(patch([(220, 92), (231, 84), (252, 81), (263, 86), (279, 83), (289, 92), (279, 99), (249, 97)]), seed: 391, cushions: 2)
        moss.patch(patch([(788, 91), (803, 83), (818, 84), (831, 91), (829, 101), (812, 102)]), seed: 571, cushions: 2)
    }
}

/// Broad, quiet moss cushions use the same greens and level of detail as the foliage.
private struct ResultMossPainter {
    let context: GraphicsContext
    let palette: ResultLandscapePalette
    private func noise(_ index: Int, seed: UInt64) -> CGFloat {
        var value = UInt64(index) &+ seed
        value = (value ^ (value >> 16)) &* 0x45D9F3B
        value = (value ^ (value >> 16)) &* 0x45D9F3B
        value ^= value >> 16
        return CGFloat(value & 65535) / 65535
    }

    func patch(_ path: Path, seed: UInt64, cushions: Int) {
        let bounds = path.boundingRect
        let light = Color(dinoHex: ResultLandscapePalette.mix(palette.grassLight, palette.leafLight, 0.38))
        let face = Color(dinoHex: ResultLandscapePalette.mix(palette.grass, palette.leaf, 0.15))
        let dark = Color(dinoHex: ResultLandscapePalette.mix(palette.grassShade, palette.grass, 0.30))
        let unit = max(0.3, min(bounds.width * 0.012, bounds.height * 0.045))
        context.drawLayer { shadow in
            shadow.addFilter(.blur(radius: unit * 1.6))
            shadow.fill(path.offsetBy(dx: 0, dy: unit * 1.2),
                        with: .color(Color(dinoHex: palette.leafShade).opacity(0.22)))
        }
        context.fill(path, with: .linearGradient(Gradient(stops: [
            .init(color: light, location: 0), .init(color: face, location: 0.48), .init(color: dark, location: 1)
        ]), startPoint: CGPoint(x: bounds.minX, y: bounds.minY), endPoint: CGPoint(x: bounds.maxX * 0.4 + bounds.minX * 0.6, y: bounds.maxY)))
        context.drawLayer { c in
            c.clip(to: path)
            // A handful of large, softly lit cushions replaces thousands of speckles.
            for index in 0..<cushions {
                let width = bounds.width / CGFloat(cushions) * 1.7
                let height = bounds.height * (0.48 + noise(index, seed: seed) * 0.30)
                let x = bounds.minX + bounds.width * (CGFloat(index) + 0.45) / CGFloat(cushions)
                let y = bounds.minY + bounds.height * (0.24 + noise(index, seed: seed &+ 313) * 0.22)
                var cushion = c
                cushion.translateBy(x: x, y: y)
                cushion.scaleBy(x: width / 2, y: height / 2)
                cushion.fill(Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2)),
                             with: .radialGradient(Gradient(colors: [light.opacity(0.25), .clear]),
                                                   center: .zero, startRadius: 0, endRadius: 1))
            }
        }
    }
}

/// Small suspended flecks keep the final composition festive after the confetti has landed.
private struct ResultCelebrationMotes: View {
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
                    spark.fill(path, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFF7A0), Color(dinoHex: 0xFFD02F)]),
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
    let settled: Bool
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
        let earned = index < count
        let shown = index < revealed
        let visible = earned ? shown : settled
        return DinoRewardStar(size: size, earned: earned, dimmed: !earned,
                              glowing: true, showsSparkle: true)
            .opacity(visible ? 1 : 0)
            .scaleEffect((index == 1 ? 1.12 : 0.96) * (earned ? (shown ? 1 : 0.3) : 0.92))
            .offset(y: earned && !shown ? -size * 1.8 : (index == 1 ? -size * 0.12 : size * 0.03))
            .rotationEffect(.degrees(index == 1 ? 0 : index == 0 ? -9 : 9))
            .animation(reduceMotion ? nil : .spring(response: 0.48, dampingFraction: 0.62), value: shown)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: settled)
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

struct WorldCompleteView: View {
    @EnvironmentObject private var player: DinoPlayer
    var worldID = 1
    var nextWorld: (() -> Void)? = nil
    var map: () -> Void
    var body: some View {
        ZStack {
            JungleBackground()
            ScrollView {
                VStack(spacing: 26) {
                    Image(systemName: "sparkles").font(.system(size: 36)).foregroundStyle(DinoStyle.green).padding(.top, 30)
                    Text("dino.worldComplete").font(.system(size: 36, weight: .heavy, design: .rounded)).multilineTextAlignment(.center)
                    DinoCharacter(state: .celebrating, size: 215)
                    Image(systemName: "trophy.fill").font(.system(size: 74)).foregroundStyle(DinoStyle.green)
                    Text(LocalizedStringKey(DinoWorldCatalog.world(worldID)!.titleKey))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                    if player.profile.perfectVictory(in: worldID) { Text("dino.perfectBoss").font(.system(size: 18, weight: .bold, design: .rounded)) }
                    VStack(spacing: 16) {
                        if let next = DinoWorldCatalog.world(worldID + 1) {
                            WorldThemePreview(world: next)
                                .frame(height: 150).clipped().clipShape(RoundedRectangle(cornerRadius: 20))
                                .accessibilityHidden(true)
                            Text(LocalizedStringKey(next.titleKey)).font(.system(size: 24, weight: .heavy, design: .rounded))
                            if let nextWorld {
                                Button("dino.nextWorld", action: nextWorld).buttonStyle(DinoButtonStyle())
                                    .accessibilityIdentifier("completion.nextWorld")
                            }
                        } else {
                            Image(systemName: "sparkles").font(.system(size: 54)).foregroundStyle(DinoStyle.green)
                            Text("dino.comingSoon").font(.system(size: 24, weight: .heavy, design: .rounded))
                            Text("dino.afterHundred").font(.system(size: 14, weight: .semibold, design: .rounded))
                                .multilineTextAlignment(.center)
                        }
                    }.frame(maxWidth: .infinity).dinoCard()
                    Button("dino.map", action: map).buttonStyle(DinoButtonStyle())
                }.padding(26).frame(maxWidth: 460).frame(maxWidth: .infinity)
            }
        }.foregroundStyle(DinoStyle.ink)
    }
}
