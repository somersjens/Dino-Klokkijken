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
        ZStack {
            ResultScenery(worldID: result.level.worldID)
            GeometryReader { geometry in
                let compact = geometry.size.height < 720
                let dinoSize: CGFloat = compact ? 150 : 180
                VStack(spacing: 0) {
                    ResultLevelBadge(levelID: result.level.id)
                        .padding(.top, compact ? 4 : 8)
                    Spacer(minLength: compact ? 4 : 10)
                    stage(dinoSize: dinoSize, compact: compact)
                    if result.level.isBoss && result.victory == .perfect {
                        Label("dino.perfectBoss", systemImage: "sparkles")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(DinoStyle.deepGreen)
                            .padding(.top, 6)
                    }
                    if !succeeded {
                        Text(LocalizedStringKey(result.level.isBoss ? (player.profile.normalLevelsComplete(in: result.level.worldID) ? "dino.needFive" : "dino.needPerfectOrRoute") : "dino.needThree"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                            .padding(.horizontal, 8)
                    }
                    Spacer(minLength: compact ? 8 : 12)
                    actions(compact: compact)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, compact ? 6 : 8)
                .frame(width: min(460, geometry.size.width), height: geometry.size.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .foregroundStyle(DinoStyle.ink)
        .task(id: result.level.id) { await playReward() }
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

    private func stage(dinoSize: CGFloat, compact: Bool) -> some View {
        let rockHeight = dinoSize * 0.98
        let burst = dinoSize * 2.05
        let starSize: CGFloat = compact ? 40 : 50
        return ZStack(alignment: .bottom) {
            ResultSunburst(strength: succeeded ? (starsRevealed > 0 ? 1 : 0.78) : 0.3)
                .frame(width: burst, height: burst)
                .offset(y: -(rockHeight * 0.78 + dinoSize * 0.42 - burst / 2))
            ResultRock()
                .frame(width: dinoSize * 1.95, height: rockHeight)
            if !result.level.isBoss {
                ResultStarReward(count: result.stars, revealed: starsRevealed, size: starSize)
                    .offset(y: -rockHeight * 0.34)
            }
            character(size: dinoSize)
                .offset(y: -rockHeight * 0.78)
        }
        .frame(maxWidth: .infinity)
        .frame(height: dinoSize + rockHeight * 0.5, alignment: .bottom)
        .overlay {
            if confetti {
                ResultConfetti()
                    .frame(width: dinoSize * 2.6, height: dinoSize * 2.3)
                    .offset(y: -dinoSize * 0.35)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }

    private func character(size: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) {
            if sharedCompanion {
                DinoCompanionAnchor(placement: .result, size: size)
            } else {
                DinoCharacter(state: succeeded ? .celebrating : .thinking, size: size, performsBackflip: perfect)
            }
            if result.level.isBoss && succeeded {
                Image(systemName: "trophy.fill").font(.system(size: size * 0.32))
                    .foregroundStyle(Color(dinoHex: 0xF0B429))
                    .shadow(color: DinoStyle.ink.opacity(0.2), radius: 4, y: 4).offset(x: 16, y: 6)
            }
        }
    }

    private func actions(compact: Bool) -> some View {
        VStack(spacing: compact ? 8 : 10) {
            if nextAvailable {
                Button(action: next) {
                    Label { Text(LocalizedStringKey(result.level.isBoss ? "dino.worldComplete" : "dino.next")) }
                        icon: { Image(systemName: "arrow.right") }
                }
                .buttonStyle(DinoButtonStyle(compact: compact)).accessibilityIdentifier("result.next")
            }
            Button(action: retry) { Label("dino.playAgain", systemImage: "arrow.clockwise") }
                .buttonStyle(DinoButtonStyle(color: succeeded ? Color(dinoHex: 0x1A6A62) : DinoStyle.green, compact: compact))
                .accessibilityIdentifier("result.retry")
            Button(action: map) { Label("dino.map", systemImage: "map.fill") }
                .buttonStyle(DinoButtonStyle(color: .white, compact: compact, inkLabel: true))
                .accessibilityIdentifier("result.map")
        }
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

/// Rays and a hot core behind Dino, the way the concept lights him from the back.
private struct ResultSunburst: View {
    var strength: Double
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let reach = min(size.width, size.height) * 0.48
            for index in 0..<18 {
                var ray = context
                ray.translateBy(x: center.x, y: center.y)
                ray.rotate(by: .degrees(Double(index) * 20))
                let wide = index.isMultiple(of: 3)
                let length = reach * (wide ? 0.96 : index.isMultiple(of: 2) ? 0.72 : 0.5)
                let rect = CGRect(x: wide ? -11 : -5, y: -length, width: wide ? 22 : 10, height: length)
                ray.fill(Path(roundedRect: rect, cornerRadius: wide ? 12 : 7),
                         with: .linearGradient(Gradient(colors: [
                            Color(dinoHex: 0xFFFCEC).opacity(0.95 * strength),
                            Color(dinoHex: 0xFFE28A).opacity(0.55 * strength),
                            Color(dinoHex: 0xFFD56A).opacity(0)
                         ]), startPoint: CGPoint(x: rect.midX, y: rect.maxY), endPoint: CGPoint(x: rect.midX, y: rect.minY)))
            }
            let core = CGRect(x: center.x - reach * 0.42, y: center.y - reach * 0.42, width: reach * 0.84, height: reach * 0.84)
            context.fill(Path(ellipseIn: core), with: .radialGradient(Gradient(colors: [
                Color.white.opacity(0.95 * strength),
                Color(dinoHex: 0xFFF3C0).opacity(0.9 * strength),
                Color(dinoHex: 0xFFD56A).opacity(0.28 * strength),
                .clear
            ]), center: center, startRadius: 4, endRadius: reach * 0.42))
        }
        .animation(.easeOut(duration: 0.45), value: strength)
        .accessibilityHidden(true)
    }
}

private struct ResultLevelBadge: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let levelID: Int
    var body: some View {
        ZStack {
            leafCluster.offset(x: -118, y: 2)
            leafCluster.scaleEffect(x: -1, y: 1).offset(x: 118, y: 2)
            leafCluster.scaleEffect(0.72).offset(y: -34)
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(dinoHex: 0x8C5A2B))
                    .offset(y: 7)
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [Color(dinoHex: 0xF6D27A), Color(dinoHex: 0xE7B14E), Color(dinoHex: 0xC88838)],
                                         startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(dinoHex: 0xFFF0C4).opacity(0.7), lineWidth: 2)
                    .padding(5)
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(dinoHex: highContrast ? 0x3A2412 : 0xA86B30), lineWidth: highContrast ? 3 : 2)
                levelTitle
            }
            .frame(width: 236, height: 68)
            .shadow(color: Color(dinoHex: 0x6A4A22).opacity(0.28), radius: 0, y: 5)
        }
        .frame(height: 92)
        .accessibilityElement(children: .combine)
    }

    private var levelTitle: some View {
        let title = Text("dino.levelNumber \(levelID)")
            .font(.system(size: 30, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        return ZStack {
            title.foregroundStyle(Color(dinoHex: 0x1F7A34)).offset(x: 0, y: 2)
            title.foregroundStyle(Color(dinoHex: 0x1F7A34)).offset(x: 1.2, y: 0)
            title.foregroundStyle(Color(dinoHex: 0x1F7A34)).offset(x: -1.2, y: 0)
            title.foregroundStyle(.white)
        }
        .padding(.horizontal, 28)
    }

    private var leafCluster: some View {
        ZStack {
            Circle().fill(Color(dinoHex: 0x3E9A3C)).frame(width: 22, height: 22)
            JungleLeaf().fill(Color(dinoHex: 0x7ED24A)).frame(width: 34, height: 18).rotationEffect(.degrees(-30)).offset(x: 8, y: -10)
            JungleLeaf().fill(Color(dinoHex: 0x2F7A32)).frame(width: 30, height: 16).rotationEffect(.degrees(20)).offset(x: -6, y: 6)
        }
    }
}

private struct ResultRock: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                lawn(w: w, h: h, front: false)
                leaves(w: w, h: h, front: false)
                ResultBoulderShape()
                    .fill(LinearGradient(colors: [Color(dinoHex: 0xC8CDC4), Color(dinoHex: 0x8B9388), Color(dinoHex: 0x5E665E)],
                                         startPoint: .top, endPoint: .bottom))
                    .overlay(ResultBoulderShape().stroke(Color.white.opacity(0.22), lineWidth: 1))
                Ellipse()
                    .fill(Color(dinoHex: 0x5A6258).opacity(0.35))
                    .frame(width: w * 0.5, height: h * 0.08)
                    .position(x: w / 2, y: h * 0.24)
                Ellipse()
                    .fill(LinearGradient(colors: [Color(dinoHex: 0xF4F6F0), Color(dinoHex: 0xC2C8BC), Color(dinoHex: 0x9AA396)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(Ellipse().stroke(Color.white.opacity(0.55), lineWidth: 1.5))
                    .frame(width: w * 0.42, height: h * 0.16)
                    .position(x: w / 2, y: h * 0.16)
                Ellipse().fill(Color.white.opacity(0.45))
                    .frame(width: w * 0.14, height: h * 0.045)
                    .position(x: w * 0.4, y: h * 0.14)
                speck(w: w, h: h)
                moss(w: w, h: h)
                leaves(w: w, h: h, front: true)
                lawn(w: w, h: h, front: true)
            }
        }
        .accessibilityHidden(true)
    }

    private func lawn(w: CGFloat, h: CGFloat, front: Bool) -> some View {
        ZStack {
            if front {
                Ellipse().fill(Color(dinoHex: 0x67B34A))
                    .frame(width: w * 1.05, height: h * 0.22)
                    .position(x: w / 2, y: h * 0.9)
                Ellipse().fill(Color(dinoHex: 0x8ED25E).opacity(0.85))
                    .frame(width: w * 0.72, height: h * 0.1)
                    .position(x: w / 2, y: h * 0.86)
                ForEach(0..<11, id: \.self) { index in
                    let x = w * (0.08 + CGFloat(index) * 0.084)
                    blade(height: h * (0.1 + CGFloat(index % 3) * 0.035), light: index.isMultiple(of: 2))
                        .position(x: x, y: h * (0.8 - CGFloat(index % 3) * 0.02))
                }
                Circle().fill(Color.white).frame(width: 7, height: 7).position(x: w * 0.12, y: h * 0.9)
                Circle().fill(Color(dinoHex: 0xFFE27A)).frame(width: 3, height: 3).position(x: w * 0.12, y: h * 0.9)
                Circle().fill(Color(dinoHex: 0xB7B2A4)).frame(width: 8, height: 6).position(x: w * 0.9, y: h * 0.92)
            } else {
                Ellipse().fill(Color(dinoHex: 0x3E6E32).opacity(0.28))
                    .frame(width: w * 0.78, height: h * 0.1)
                    .blur(radius: 2)
                    .position(x: w / 2, y: h * 0.78)
            }
        }
    }

    private func blade(height: CGFloat, light: Bool) -> some View {
        Capsule()
            .fill(Color(dinoHex: light ? 0xA6DE6A : 0x3F8C38))
            .frame(width: 3.5, height: height)
    }

    private func speck(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.28)).frame(width: w * 0.035, height: w * 0.035).position(x: w * 0.38, y: h * 0.4)
            Circle().fill(Color(dinoHex: 0x4E564C).opacity(0.35)).frame(width: w * 0.028, height: w * 0.028).position(x: w * 0.62, y: h * 0.46)
            Circle().fill(Color.white.opacity(0.2)).frame(width: w * 0.02, height: w * 0.02).position(x: w * 0.5, y: h * 0.52)
        }
    }

    private func moss(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Capsule().fill(Color(dinoHex: 0x7EBE58)).frame(width: w * 0.13, height: h * 0.04)
                .rotationEffect(.degrees(-14)).position(x: w * 0.34, y: h * 0.2)
            Capsule().fill(Color(dinoHex: 0x4E9A42)).frame(width: w * 0.09, height: h * 0.032)
                .rotationEffect(.degrees(10)).position(x: w * 0.64, y: h * 0.19)
        }
    }

    private func leaves(w: CGFloat, h: CGFloat, front: Bool) -> some View {
        ZStack {
            if front {
                leaf(w * 0.2, h * 0.16, 28).position(x: w * 0.9, y: h * 0.48)
                leaf(w * 0.16, h * 0.13, -36).position(x: w * 0.1, y: h * 0.52)
                leaf(w * 0.12, h * 0.1, 8).position(x: w * 0.82, y: h * 0.68)
            } else {
                leaf(w * 0.24, h * 0.2, -42).position(x: w * 0.06, y: h * 0.34)
                leaf(w * 0.22, h * 0.18, 32).position(x: w * 0.94, y: h * 0.3)
                leaf(w * 0.13, h * 0.1, -16).position(x: w * 0.26, y: h * 0.12)
                leaf(w * 0.12, h * 0.09, 18).position(x: w * 0.76, y: h * 0.1)
            }
        }
    }

    private func leaf(_ width: CGFloat, _ height: CGFloat, _ turn: Double) -> some View {
        DinoFoliageLeaf()
            .fill(LinearGradient(colors: [Color(dinoHex: 0xD4EE78), Color(dinoHex: 0x3E9438)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: width, height: height)
            .rotationEffect(.degrees(turn))
    }
}

/// Narrower at the crown and at the ground, widest through the middle.
private struct ResultBoulderShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.34, y: h * 0.2))
        path.addCurve(to: CGPoint(x: w * 0.66, y: h * 0.2),
                      control1: CGPoint(x: w * 0.42, y: h * 0.1),
                      control2: CGPoint(x: w * 0.58, y: h * 0.1))
        path.addCurve(to: CGPoint(x: w * 0.94, y: h * 0.46),
                      control1: CGPoint(x: w * 0.86, y: h * 0.24),
                      control2: CGPoint(x: w * 0.99, y: h * 0.34))
        path.addCurve(to: CGPoint(x: w * 0.7, y: h * 0.74),
                      control1: CGPoint(x: w * 0.9, y: h * 0.6),
                      control2: CGPoint(x: w * 0.82, y: h * 0.74))
        path.addCurve(to: CGPoint(x: w * 0.3, y: h * 0.74),
                      control1: CGPoint(x: w * 0.56, y: h * 0.8),
                      control2: CGPoint(x: w * 0.44, y: h * 0.8))
        path.addCurve(to: CGPoint(x: w * 0.06, y: h * 0.46),
                      control1: CGPoint(x: w * 0.16, y: h * 0.74),
                      control2: CGPoint(x: w * 0.08, y: h * 0.6))
        path.addCurve(to: CGPoint(x: w * 0.34, y: h * 0.2),
                      control1: CGPoint(x: w * 0.02, y: h * 0.34),
                      control2: CGPoint(x: w * 0.14, y: h * 0.24))
        path.closeSubpath()
        return path
    }
}

private struct ResultStarReward: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let count: Int
    let revealed: Int
    var size: CGFloat
    var body: some View {
        HStack(alignment: .bottom, spacing: size * 0.14) {
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
        return ResultMedalStar(size: size, gold: earned && shown, dim: !earned)
            .scaleEffect(earned ? (shown ? 1 : 0.3) : 0.92)
            .offset(y: earned && !shown ? -size * 1.8 : (index == 1 ? -3 : 0))
            .rotationEffect(.degrees(index == 1 ? 0 : index == 0 ? -4 : 4))
            .animation(reduceMotion ? nil : .spring(response: 0.48, dampingFraction: 0.62), value: shown)
    }
}

/// A thick gold star with a dark underside, the way the concept sets them on the stone.
private struct ResultMedalStar: View {
    var size: CGFloat
    var gold: Bool
    var dim: Bool
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color(dinoHex: 0x5C6848).opacity(gold ? 0.22 : 0.1))
                .frame(width: size * 0.62, height: size * 0.12)
                .offset(y: size * 0.4)
            if gold {
                ResultGoldStarShape()
                    .fill(Color(dinoHex: 0xFFE566))
                    .blur(radius: size * 0.08)
                    .scaleEffect(1.14)
                    .opacity(0.75)
                spark.offset(x: size * 0.4, y: -size * 0.36)
                spark.scaleEffect(0.6).offset(x: -size * 0.42, y: -size * 0.1)
            }
            ResultGoldStarShape()
                .fill(Color(dinoHex: gold ? 0xFFF6D0 : 0xD5D8CC))
                .overlay(ResultGoldStarShape().stroke(Color.white.opacity(gold ? 0.95 : 0.4), lineWidth: max(1.5, size * 0.045)))
            ResultGoldStarShape()
                .fill(Color(dinoHex: gold ? 0xF0BE2E : 0x9AA392))
                .scaleEffect(0.8)
            ResultGoldStarShape()
                .fill(LinearGradient(colors: gold
                                     ? [Color(dinoHex: 0xFFFCE6), Color(dinoHex: 0xFFE45A), Color(dinoHex: 0xFFD448)]
                                     : [Color(dinoHex: 0xF2F0E6), Color(dinoHex: 0xC8CCBC), Color(dinoHex: 0xA8AE9E)],
                                     startPoint: .top, endPoint: .bottom))
                .scaleEffect(0.64)
            ResultGoldStarShape()
                .fill(LinearGradient(colors: [Color.white.opacity(gold ? 0.85 : 0.3), .clear],
                                     startPoint: .top, endPoint: .center))
                .scaleEffect(0.4)
                .offset(y: -size * 0.06)
        }
        .frame(width: size, height: size)
        .opacity(dim ? 0.5 : 1)
    }

    private var spark: some View {
        Circle().fill(Color.white).frame(width: 4, height: 4)
            .shadow(color: Color(dinoHex: 0xFFF6C0), radius: 2)
    }
}

private struct ResultGoldStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.52
        let points = (0..<10).map { index in
            let angle = CGFloat(index) * .pi / 5 - .pi / 2
            let radius = index.isMultiple(of: 2) ? outer : inner
            return CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        }
        let round: CGFloat = 0.42
        func between(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
            CGPoint(x: a.x + (b.x - a.x) * round, y: a.y + (b.y - a.y) * round)
        }
        var path = Path()
        path.move(to: between(points[9], points[0]))
        for index in 0..<10 {
            let tip = points[index]
            let next = points[(index + 1) % 10]
            path.addQuadCurve(to: between(tip, next), control: tip)
        }
        path.closeSubpath()
        return path
    }
}

/// A short burst that starts behind Dino and arcs outward once the third star has settled.
private struct ResultConfetti: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var started = Date()
    private let colors: [UInt32] = [0xFFD24A, 0x7ED24A, 0xFFF6C8, 0xF0B429, 0x5AAA40]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion || scenePhase != .active)) { timeline in
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
