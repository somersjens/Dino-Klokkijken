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
    private var perfect: Bool { result.correct == result.level.questionCount }

    var body: some View {
        GeometryReader { geometry in
            let layout = ResultLayout(size: geometry.size, needsMessage: !succeeded)
            ZStack {
                ResultScenery(worldID: result.level.worldID)
                VStack(spacing: 0) {
                    ResultLevelBadge(levelID: result.level.id)
                        .frame(width: layout.signWidth, height: layout.signHeight)
                        .padding(.top, layout.topInset)
                        .zIndex(1)
                    Spacer(minLength: 0)
                    stage(layout: layout)
                    resultCaption
                        .padding(.top, 4)
                    Spacer(minLength: 8)
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
        .shadow(color: .white.opacity(0.75), radius: 2, y: 1)
    }

    /// The backflip finishes on the rock first. Earned stars then drop in one by one,
    /// and a three-star landing sends confetti out from behind Dino.
    private func playReward() async {
        guard !result.level.isBoss else { return }
        if reduceMotion {
            starsRevealed = result.stars
            confetti = result.stars >= 3
            return
        }
        let landing = perfect ? 1.26 : (succeeded ? 0.4 : 0.15)
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
            ResultSunburst(strength: succeeded ? (starsRevealed > 0 ? 1 : 0.78) : 0.3)
                .frame(width: layout.podiumWidth * 1.38, height: layout.podiumWidth * 1.38)
                .position(x: layout.stageWidth / 2, y: layout.dinoCenterY + layout.dinoSize * 0.05)
            ResultRock()
                .frame(width: layout.podiumWidth, height: layout.podiumHeight)
                .position(x: layout.podiumCenterX, y: layout.stageHeight - layout.podiumHeight / 2 + layout.podiumLift)
            Ellipse()
                .fill(Color(dinoHex: 0x304627).opacity(0.24))
                .frame(width: layout.dinoSize * 0.55, height: layout.dinoSize * 0.055)
                .blur(radius: 3)
                .position(x: layout.podiumCenterX, y: layout.stageHeight - layout.podiumHeight * 0.73 + layout.podiumLift)
            character(size: layout.dinoSize)
                .position(x: layout.stageWidth / 2, y: layout.dinoCenterY)
            if !result.level.isBoss {
                ResultStarReward(count: result.stars, revealed: starsRevealed, size: layout.starSize)
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
                DinoCharacter(state: succeeded ? .celebrating : .thinking, size: size, performsBackflip: perfect)
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
    var podiumWidth: CGFloat { min(stageWidth, dinoSize * 1.85) }
    var podiumHeight: CGFloat { podiumWidth * 0.50 }
    var podiumCenterX: CGFloat { stageWidth / 2 + dinoSize * 0.04 }
    var podiumLift: CGFloat { -dinoSize * 0.035 }
    var stageHeight: CGFloat { min(availableHeight, dinoSize + podiumHeight * 0.66) }
    var dinoCenterY: CGFloat { stageHeight - podiumHeight * 0.73 - dinoSize * 0.47 }
    var starSize: CGFloat { min(podiumWidth * 0.21, 122) }
    var rewardCenterY: CGFloat { stageHeight - podiumHeight * 0.37 + podiumLift }
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

/// Hills, sky and side dressing use the same world colors as the map.
private struct ResultScenery: View {
    let worldID: Int
    private var theme: WorldThemeColors {
        WorldThemeColors(DinoWorldCatalog.world(worldID) ?? DinoWorldCatalog.worlds[0])
    }
    private var sky: (top: UInt32, mid: UInt32, night: Bool) {
        switch worldID {
        case 2: return (0x2A2458, 0x6E629C, true)
        case 3: return (0xFFB07A, 0xE56A48, false)
        case 4: return (0xB7E4FF, 0xE7F3C4, false)
        case 5: return (0x163E4C, 0x4E9AA6, false)
        case 6: return (0x8EC8EE, 0xD5EEF8, false)
        case 7: return (0x332E5C, 0x7E74A8, true)
        case 8: return (0xC9B6E4, 0xE6D7BE, false)
        case 9: return (0x6EBFDE, 0xF3E2B0, false)
        case 10: return (0x8EADD0, 0xD5D0C4, false)
        default: return (0xB9E7FF, 0xE7F6C8, false)
        }
    }

    var body: some View {
        let colors = theme
        let look = sky
        return GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            ZStack {
                if worldID == 1 {
                    Image("result-jungle-grounded")
                        .resizable().scaledToFill()
                        .frame(width: width, height: height)
                        .clipped()
                } else {
                    LinearGradient(colors: [Color(dinoHex: look.top), Color(dinoHex: look.mid), Color(dinoHex: colors.ground)],
                                   startPoint: .top, endPoint: .bottom)
                    if look.night {
                        moon.position(x: width * 0.78, y: height * 0.16)
                        nightStars(width: width, height: height)
                    } else if worldID == 3 {
                        Circle().fill(Color(dinoHex: 0xFFD0A0).opacity(0.55))
                            .frame(width: width * 0.5).blur(radius: 18)
                            .position(x: width * 0.5, y: height * 0.28)
                    }
                    hill(centerX: width * 0.5, width: width * 1.2, height: height * 0.26,
                         color: Color(dinoHex: colors.distant).opacity(0.85), y: height * 0.56)
                    hill(centerX: width * 0.32, width: width * 0.85, height: height * 0.22,
                         color: Color(dinoHex: colors.accent).opacity(0.55), y: height * 0.64)
                    hill(centerX: width * 0.5, width: width * 1.25, height: height * 0.36,
                         color: Color(dinoHex: colors.ground), y: height * 0.84)
                    worldAccent(width: width, height: height, colors: colors)
                    if worldID == 1 || worldID == 4 {
                        HStack(spacing: 18) {
                            flower(Color(dinoHex: colors.accent))
                            flower(.white)
                            Spacer()
                            flower(.white)
                            flower(Color(dinoHex: colors.accent))
                        }
                        .padding(.horizontal, 16)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 18)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var moon: some View {
        ZStack {
            Circle().fill(Color(dinoHex: 0xFFF6D4)).frame(width: 54, height: 54)
            Circle().fill(Color(dinoHex: 0x2A2458).opacity(0.9)).frame(width: 44, height: 44).offset(x: 12, y: -4)
        }
    }

    private func nightStars(width: CGFloat, height: CGFloat) -> some View {
        Canvas { context, _ in
            for index in 0..<8 {
                let x = width * (0.12 + CGFloat(index % 4) * 0.18)
                let y = height * (0.08 + CGFloat(index / 4) * 0.1 + CGFloat(index % 3) * 0.03)
                let rect = CGRect(x: x, y: y, width: 3, height: 3)
                context.fill(Path(ellipseIn: rect), with: .color(Color(dinoHex: 0xFFF6D4).opacity(0.85)))
            }
        }
    }

    @ViewBuilder private func worldAccent(width: CGFloat, height: CGFloat, colors: WorldThemeColors) -> some View {
        switch worldID {
        case 5:
            crystal(x: width * 0.08, y: height * 0.3, scale: 1)
            crystal(x: width * 0.92, y: height * 0.26, scale: 0.85)
        case 6:
            skyline(width: width, y: height * 0.62, color: Color(dinoHex: colors.shade))
            Ellipse().fill(Color(dinoHex: colors.accent).opacity(0.55))
                .frame(width: width * 1.1, height: height * 0.12)
                .position(x: width / 2, y: height * 0.78)
        case 8:
            gear(x: width * 0.1, y: height * 0.24, diameter: 46)
            gear(x: width * 0.9, y: height * 0.22, diameter: 34)
        case 9:
            Ellipse().fill(Color(dinoHex: colors.accent).opacity(0.7))
                .frame(width: width * 1.2, height: height * 0.16)
                .position(x: width / 2, y: height * 0.72)
        case 10:
            tower(x: width * 0.08, y: height * 0.48)
            tower(x: width * 0.92, y: height * 0.5)
        case 3:
            hill(centerX: width * 0.14, width: width * 0.38, height: height * 0.2,
                 color: Color(dinoHex: colors.shade), y: height * 0.5)
            hill(centerX: width * 0.88, width: width * 0.34, height: height * 0.16,
                 color: Color(dinoHex: colors.shade), y: height * 0.52)
        default:
            bush(x: width * 0.08, y: height * 0.24, fill: Color(dinoHex: colors.shade), light: Color(dinoHex: colors.accent))
            bush(x: width * 0.93, y: height * 0.22, fill: Color(dinoHex: colors.shade), light: Color(dinoHex: colors.accent))
        }
    }

    private func hill(centerX: CGFloat, width: CGFloat, height: CGFloat, color: Color, y: CGFloat) -> some View {
        Ellipse().fill(color).frame(width: width, height: height).position(x: centerX, y: y)
    }

    private func bush(x: CGFloat, y: CGFloat, fill: Color, light: Color) -> some View {
        ZStack {
            Circle().fill(fill).frame(width: 54, height: 54).offset(x: -16, y: 8)
            Circle().fill(light).frame(width: 62, height: 62)
            Circle().fill(light.opacity(0.75)).frame(width: 36, height: 36).offset(x: 18, y: -8)
        }
        .position(x: x, y: y)
    }

    private func flower(_ color: Color) -> some View {
        ZStack {
            Circle().fill(color).frame(width: 9, height: 9)
            Circle().fill(Color(dinoHex: 0xFFE27A)).frame(width: 4, height: 4)
        }
    }

    private func crystal(x: CGFloat, y: CGFloat, scale: CGFloat) -> some View {
        CrystalShard().fill(LinearGradient(colors: [Color(dinoHex: 0xE9FFFC), Color(dinoHex: 0x7ED8D4), Color(dinoHex: 0x3E7C9A)],
                                            startPoint: .top, endPoint: .bottom))
            .frame(width: 36 * scale, height: 78 * scale)
            .shadow(color: Color(dinoHex: 0x7ED8D4).opacity(0.5), radius: 8)
            .position(x: x, y: y)
    }

    private func skyline(width: CGFloat, y: CGFloat, color: Color) -> some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach([28, 46, 34, 58, 24], id: \.self) { height in
                RoundedRectangle(cornerRadius: 3).fill(color.opacity(0.85)).frame(width: 16, height: CGFloat(height))
            }
        }
        .position(x: width * 0.5, y: y)
    }

    private func gear(x: CGFloat, y: CGFloat, diameter: CGFloat) -> some View {
        ZStack {
            Circle().stroke(Color(dinoHex: 0xC4A15A), lineWidth: 8).frame(width: diameter, height: diameter)
            Circle().fill(Color(dinoHex: 0x8A7040)).frame(width: diameter * 0.28, height: diameter * 0.28)
            ForEach(0..<6, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2).fill(Color(dinoHex: 0xE2C98A))
                    .frame(width: 8, height: 12)
                    .offset(y: -diameter * 0.46)
                    .rotationEffect(.degrees(Double(index) * 60))
            }
        }
        .position(x: x, y: y)
    }

    private func tower(x: CGFloat, y: CGFloat) -> some View {
        VStack(spacing: 0) {
            TriangleRoof().fill(Color(dinoHex: 0x7E93B0)).frame(width: 36, height: 16)
            Rectangle().fill(Color(dinoHex: 0xD9D3C6)).frame(width: 28, height: 48)
        }
        .position(x: x, y: y)
    }
}

private struct CrystalShard: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX * 0.82, y: rect.height * 0.38))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.18, y: rect.height * 0.42))
        path.closeSubpath()
        return path
    }
}

private struct TriangleRoof: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
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
                    Color(dinoHex: 0xFFFBC9).opacity(0.42 * strength),
                    Color(dinoHex: 0xFFFAAE).opacity(0.20 * strength), .clear
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

private struct ResultLevelBadge: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let levelID: Int
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("result-sign").resizable().scaledToFit()
                    .shadow(color: Color(dinoHex: 0x294D21).opacity(0.24), radius: 8, y: 8)
                title
                    .font(.system(size: geometry.size.width * 0.137, weight: .heavy, design: .rounded))
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .padding(.horizontal, geometry.size.width * 0.19)
                    .offset(y: -geometry.size.height * 0.035)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("dino.levelNumber \(levelID)"))
    }

    private var title: some View {
        let text = Text("dino.levelNumber \(levelID)")
        return ZStack {
            // Eight samples form an even outline, including the diagonals of the numerals.
            ForEach(0..<8, id: \.self) { index in
                let angle = Double(index) * .pi / 4
                text.foregroundStyle(Color(dinoHex: highContrast ? 0x123A1C : 0x235A2B))
                    .offset(x: cos(angle) * 3, y: sin(angle) * 3 + 2)
                    .accessibilityHidden(true)
            }
            text.foregroundStyle(Color(dinoHex: 0xFFFDE9))
                .shadow(color: Color(dinoHex: 0x163D20).opacity(0.5), radius: 0, y: 2)
        }
    }
}

private struct ResultRock: View {
    var body: some View {
        Image("result-podium").resizable().scaledToFit()
            .accessibilityHidden(true)
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
        return DinoRewardStar(size: size, earned: earned && shown, dimmed: !earned,
                              glowing: true, showsSparkle: true)
            .scaleEffect((index == 1 ? 1.12 : 0.96) * (earned ? (shown ? 1 : 0.3) : 0.92))
            .offset(y: earned && !shown ? -size * 1.8 : (index == 1 ? -size * 0.12 : size * 0.03))
            .rotationEffect(.degrees(index == 1 ? 0 : index == 0 ? -9 : 9))
            .animation(reduceMotion ? nil : .spring(response: 0.48, dampingFraction: 0.62), value: shown)
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
