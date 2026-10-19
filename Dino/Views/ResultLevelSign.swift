import SwiftUI

/// Independent animatable inputs; the default pose preserves the established composition.
struct DinoResultSignPose: Equatable, Animatable {
    var tilt: Double = 0
    var leftSway: Double = 0
    var rightSway: Double = 0
    var accentGlow: Double = 0
    typealias Data = AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<Double, Double>>
    var animatableData: Data {
        get { .init(.init(tilt, leftSway), .init(rightSway, accentGlow)) }
        set {
            tilt = newValue.first.first; leftSway = newValue.first.second
            rightSway = newValue.second.first; accentGlow = newValue.second.second
        }
    }
}

/// Native replacement for the 3:1 result-sign illustration. Text metrics and outer layout stay shared.
struct DinoResultLevelSign: View, Animatable {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let levelID: Int
    let worldID: Int
    var pose = DinoResultSignPose()
    var animatableData: DinoResultSignPose.Data {
        get { pose.animatableData }
        set { pose.animatableData = newValue }
    }
    private var world: DinoWorld { DinoWorldCatalog.world(worldID) ?? DinoWorldCatalog.worlds[0] }

    var body: some View {
        let palette = ResultSignPalette(themeID: world.themeID)
        let resting = reduceMotion ? DinoResultSignPose() : pose
        GeometryReader { geometry in
            ZStack {
                ZStack {
                    art(.rear, palette: palette, pose: resting, width: geometry.size.width)
                    art(.panel, palette: palette, pose: resting, width: geometry.size.width)
                }
                .shadow(color: Color(dinoHex: palette.shadow).opacity(0.24), radius: 8, y: 8)
                title(ink: highContrast ? 0x122D36 : palette.ink)
                    .font(.system(size: geometry.size.width * 0.1233, weight: .heavy, design: .rounded))
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .padding(.horizontal, geometry.size.width * 0.19)
                    .offset(y: geometry.size.height * 0.01)
                art(.front, palette: palette, pose: resting, width: geometry.size.width)
                    .shadow(color: Color(dinoHex: palette.shadow).opacity(0.16), radius: 2.5, y: 2)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .rotationEffect(.degrees(resting.tilt))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("dino.levelNumber \(levelID)"))
        .accessibilityValue(Text(LocalizedStringKey(world.titleKey)))
    }

    private func art(_ layer: ResultSignLayer, palette: ResultSignPalette,
                     pose: DinoResultSignPose, width: CGFloat) -> some View {
        Canvas(rendersAsynchronously: true) { context, size in
            var c = context
            c.scaleBy(x: size.width / 1000, y: size.height / (1000 / 3))
            ResultSignPainter(context: c, palette: palette, pose: pose).draw(layer)
        }
        .frame(width: width, height: width / 3)
        .allowsHitTesting(false).accessibilityHidden(true)
    }

    private func title(ink: UInt32) -> some View {
        let text = Text("dino.levelNumber \(levelID)")
        return ZStack {
            ForEach(0..<8, id: \.self) { index in
                let angle = Double(index) * .pi / 4
                text.foregroundStyle(Color(dinoHex: ink))
                    .offset(x: cos(angle) * 3, y: sin(angle) * 3 + 2)
                    .accessibilityHidden(true)
            }
            text.foregroundStyle(Color(dinoHex: 0xFFFDE9))
                .shadow(color: Color(dinoHex: ink).opacity(0.5), radius: 0, y: 2)
        }
    }
}

private enum ResultSignLayer { case rear, panel, front }
private enum ResultSignMaterial { case wood, mineral, metal }

private struct ResultSignPalette {
    let themeID: Int
    var material: ResultSignMaterial = .wood
    var light: UInt32 = 0xFFD889
    var face: UInt32 = 0xF6AB45
    var dark: UInt32 = 0xC8752A
    var edge: UInt32 = 0x8C461F
    var ink: UInt32 = 0x235A2B
    var accent: UInt32 = 0x80B924
    var accentLight: UInt32 = 0xC8ED46
    var accentShade: UInt32 = 0x246C2E
    var shadow: UInt32 = 0x294D21
    init(themeID: Int) {
        self.themeID = themeID
        switch themeID {
        case 2:
            material = .mineral
            (light, face, dark, edge, ink) = (0xF4EBFF, 0xC6C5E1, 0x8E96B8, 0x667394, 0x414D70)
            (accentLight, accent, accentShade, shadow) = (0xEAF3E2, 0xA8C8CD, 0x5B789A, 0x394361)
        case 3:
            material = .mineral
            (light, face, dark, edge, ink) = (0xA59A9C, 0x746875, 0x4A4656, 0xA96B43, 0x302D3F)
            (accentLight, accent, accentShade, shadow) = (0xFFE0A0, 0xF49B57, 0xAD4F3B, 0x3F3545)
        case 4:
            (light, face, dark, edge, ink) = (0xFFF1C6, 0xD9BA83, 0xAC8658, 0x85613F, 0x65503A)
            (accentLight, accent, accentShade, shadow) = (0xEBD699, 0xBE8058, 0x736B46, 0x4B573D)
        case 5:
            material = .mineral
            (light, face, dark, edge, ink) = (0xE9FAFF, 0xB5D8E2, 0x749BAE, 0x557A99, 0x354F79)
            (accentLight, accent, accentShade, shadow) = (0xE6D8FF, 0xAFA1D9, 0x586BA5, 0x355D6E)
        case 6:
            material = .metal
            (light, face, dark, edge, ink) = (0xE9FCF9, 0xACD4D7, 0x639AA9, 0x42788C, 0x245D70)
            (accentLight, accent, accentShade, shadow) = (0xC9F5E8, 0x64BFC2, 0x3B758C, 0x355D72)
        case 7:
            material = .mineral
            (light, face, dark, edge, ink) = (0xFFF0BF, 0xEAC88B, 0xC49B62, 0x95663C, 0x6D492B)
            (accentLight, accent, accentShade, shadow) = (0xD2DE8C, 0x719F62, 0x3E765D, 0x835E3C)
        case 8:
            material = .metal
            (light, face, dark, edge, ink) = (0xFFEFBD, 0xD7BA79, 0xAA8A55, 0x727A75, 0x53554D)
            (accentLight, accent, accentShade, shadow) = (0xD5EAE5, 0x7CAAAE, 0x506B7C, 0x4A5B61)
        case 9:
            (light, face, dark, edge, ink) = (0xF6E7C0, 0xC6AE7D, 0x96815D, 0x755B3F, 0x634B35)
            (accentLight, accent, accentShade, shadow) = (0xDAEBD7, 0x78BAB9, 0x417D86, 0x425E5F)
        case 10:
            material = .mineral
            (light, face, dark, edge, ink) = (0xFFF3D2, 0xE1D6B6, 0xB3AC95, 0xBC984E, 0x35557D)
            (accentLight, accent, accentShade, shadow) = (0xD2E2F1, 0x749BC9, 0x3E5B8B, 0x445C7C)
        default: break
        }
    }
}

private struct ResultSignPainter {
    let context: GraphicsContext
    let palette: ResultSignPalette
    let pose: DinoResultSignPose
    private var theme: Int { palette.themeID }
    private func color(_ hex: UInt32) -> Color { Color(dinoHex: hex) }
    private func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    func draw(_ layer: ResultSignLayer) {
        if layer == .panel { board(); return }
        for side in 0..<2 {
            var c = context
            c.translateBy(x: side == 0 ? 126 : 874, y: 170)
            c.scaleBy(x: side == 0 ? 1 : -1, y: 1)
            c.rotate(by: .degrees(side == 0 ? pose.leftSway : pose.rightSway))
            ResultSignPainter(context: c, palette: palette, pose: pose).ornament(front: layer == .front, side: side)
        }
    }

    /// Same gently arched plank, rounded shoulders and lifted middle of the lower edge.
    private var outline: Path {
        Path { path in
            path.move(to: p(140, 93))
            path.addCurve(to: p(500, 68), control1: p(260, 66), control2: p(389, 63))
            path.addCurve(to: p(855, 91), control1: p(620, 62), control2: p(750, 69))
            path.addCurve(to: p(902, 125), control1: p(892, 95), control2: p(905, 104))
            path.addCurve(to: p(908, 232), control1: p(920, 150), control2: p(916, 203))
            path.addCurve(to: p(878, 269), control1: p(904, 252), control2: p(893, 266))
            path.addCurve(to: p(735, 279), control1: p(848, 284), control2: p(795, 281))
            path.addCurve(to: p(500, 268), control1: p(657, 273), control2: p(580, 267))
            path.addCurve(to: p(272, 282), control1: p(417, 267), control2: p(341, 284))
            path.addCurve(to: p(159, 274), control1: p(223, 284), control2: p(181, 281))
            path.addCurve(to: p(109, 242), control1: p(137, 270), control2: p(120, 258))
            path.addCurve(to: p(100, 161), control1: p(96, 217), control2: p(92, 188))
            path.addCurve(to: p(113, 116), control1: p(101, 140), control2: p(105, 123))
            path.addCurve(to: p(140, 93), control1: p(120, 105), control2: p(130, 99))
            path.closeSubpath()
        }
    }

    private func board() {
        // A cast side wall, rolled outer lip and inset face keep the volume readable
        // at phone size. All materials share the original silhouette and text space.
        material(outline.offsetBy(dx: 0, dy: 16), light: palette.dark, face: palette.edge, dark: palette.edge)
        material(outline.offsetBy(dx: 0, dy: 8), light: palette.face, face: palette.dark, dark: palette.edge)
        context.fill(outline, with: .linearGradient(Gradient(stops: [
            .init(color: color(palette.light), location: 0),
            .init(color: color(palette.face), location: 0.25),
            .init(color: color(palette.face), location: 0.62),
            .init(color: color(palette.dark), location: 1)
        ]), startPoint: p(500, 68), endPoint: p(500, 284)))
        let inset = outline.applying(CGAffineTransform(a: 0.983, b: 0, c: 0, d: 0.925, tx: 8.5, ty: 13))
        context.fill(inset, with: .linearGradient(Gradient(stops: [
            .init(color: color(palette.light), location: 0),
            .init(color: color(palette.face), location: 0.31),
            .init(color: color(palette.face), location: 0.72),
            .init(color: color(palette.dark), location: 1)
        ]), startPoint: p(500, 72), endPoint: p(500, 282)))
        context.drawLayer { c in
            c.clip(to: outline)
            c.fill(outline, with: .radialGradient(Gradient(colors: [color(palette.light).opacity(0.38), .clear]),
                                                 center: p(450, 90), startRadius: 0, endRadius: 490))
            let painter = ResultSignPainter(context: c, palette: palette, pose: pose)
            switch palette.material {
            case .wood: painter.woodgrain()
            case .mineral: painter.mineral()
            case .metal: painter.metal()
            }
            c.stroke(inset, with: .linearGradient(Gradient(stops: [
                .init(color: color(palette.light).opacity(0.90), location: 0),
                .init(color: color(palette.light).opacity(0.35), location: 0.34),
                .init(color: color(palette.edge).opacity(0.34), location: 0.72),
                .init(color: color(palette.edge).opacity(0.49), location: 1)
            ]), startPoint: p(420, 72), endPoint: p(500, 284)), lineWidth: 5.5)
        }
        context.stroke(outline, with: .color(color(palette.edge).opacity(0.42)), lineWidth: 1.7)
        edgeHighlights()
        if [6, 8, 10].contains(theme) {
            for x: CGFloat in [134, 866] { for y: CGFloat in [125, 242] { rivet(at: p(x, y), radius: 5.5) } }
        }
    }

    private func edgeHighlights() {
        var crest = Path()
        crest.move(to: p(145, 99))
        crest.addCurve(to: p(500, 72), control1: p(263, 75), control2: p(385, 67))
        crest.addCurve(to: p(854, 96), control1: p(627, 66), control2: p(761, 73))
        context.stroke(crest.offsetBy(dx: 0, dy: 1.2), with: .color(color(palette.face).opacity(0.7)),
                       style: StrokeStyle(lineWidth: 7, lineCap: .round))
        context.stroke(crest, with: .color(color(palette.light).opacity(0.95)), style: StrokeStyle(lineWidth: 2.8, lineCap: .round))
        for right in [false, true] {
            var c = context
            if right { c.translateBy(x: 1010, y: 0); c.scaleBy(x: -1, y: 1) }
            var shoulder = Path()
            shoulder.move(to: p(137, 108))
            shoulder.addCurve(to: p(110, 174), control1: p(112, 116), control2: p(104, 148))
            shoulder.addCurve(to: p(128, 245), control1: p(107, 204), control2: p(111, 229))
            c.stroke(shoulder, with: .linearGradient(Gradient(colors: [color(palette.light), color(palette.light).opacity(0.12)]),
                                                   startPoint: p(126, 104), endPoint: p(122, 248)),
                     style: StrokeStyle(lineWidth: right ? 2.3 : 3.3, lineCap: .round))
        }
        var lip = Path()
        lip.move(to: p(145, 270))
        lip.addCurve(to: p(275, 286), control1: p(180, 292), control2: p(232, 290))
        lip.addCurve(to: p(500, 274), control1: p(366, 287), control2: p(417, 274))
        lip.addCurve(to: p(740, 285), control1: p(586, 272), control2: p(664, 282))
        lip.addCurve(to: p(880, 274), control1: p(802, 290), control2: p(854, 288))
        context.stroke(lip, with: .color(color(palette.face).opacity(0.30)),
                       style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }

    private func woodgrain() {
        // Tapered, uneven fibres follow the individual planks instead of a striped grid.
        let fibres: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (126, 97, 906, -12, 2.2), (105, 124, 886, -8, 1.5),
            (158, 145, 920, 7, 2.7), (91, 199, 815, -19, 2.0),
            (244, 217, 913, -4, 1.4), (100, 252, 791, -12, 2.3),
            (288, 267, 905, -3, 1.4)
        ]
        for (index, fibre) in fibres.enumerated() {
            let (start, y, end, bow, thickness) = fibre
            let span = end - start
            var grain = Path()
            grain.move(to: p(start, y))
            grain.addCurve(to: p(end, y + 3), control1: p(start + span * 0.30, y + bow), control2: p(start + span * 0.67, y + bow - 10))
            grain.addCurve(to: p(start, y), control1: p(start + span * 0.67, y + bow - 10 + thickness),
                           control2: p(start + span * 0.30, y + bow + thickness * 1.5))
            grain.closeSubpath()
            context.fill(grain, with: .color(color(index.isMultiple(of: 3) ? palette.dark : palette.light).opacity(index.isMultiple(of: 3) ? 0.26 : 0.25)))
        }
        for y: CGFloat in [176, 237] {
            var seam = Path()
            seam.move(to: p(94, y + 10))
            seam.addCurve(to: p(452, y - 12), control1: p(204, y + 2), control2: p(299, y - 21))
            seam.addCurve(to: p(918, y + 8), control1: p(635, y - 19), control2: p(786, y - 4))
            context.stroke(seam.offsetBy(dx: 0, dy: -1.2), with: .color(color(palette.dark).opacity(0.28)),
                           style: StrokeStyle(lineWidth: 9, lineCap: .round))
            context.stroke(seam, with: .color(color(palette.edge).opacity(0.46)), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
            context.stroke(seam.offsetBy(dx: 0, dy: 2.8), with: .color(color(palette.light).opacity(0.64)),
                           style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        }
        for (x, y, width) in [(CGFloat(175), CGFloat(159), CGFloat(18)), (820, 191, 21)] {
            var knot = Path()
            knot.move(to: p(x - width, y + 1))
            knot.addCurve(to: p(x + width, y + 1), control1: p(x - width * 0.35, y - 12), control2: p(x + width * 0.65, y - 10))
            knot.addCurve(to: p(x - width, y + 1), control1: p(x + width * 0.42, y + 11), control2: p(x - width * 0.48, y + 8))
            material(knot, light: palette.face, face: palette.face, dark: palette.dark)
            context.stroke(knot.offsetBy(dx: 0, dy: 1.5), with: .color(color(palette.light).opacity(0.30)), lineWidth: 1.2)
            oval(CGRect(x: x - 3, y: y - 1.3, width: 8, height: 3), light: palette.dark, face: palette.dark, dark: palette.edge)
        }
        // Short end checks and shallow notches follow the planks into their bevel.
        for points in [
            [p(124, 184), p(145, 187), p(157, 182), p(167, 182)],
            [p(892, 191), p(874, 187), p(862, 192)],
            [p(750, 77), p(748, 83), p(759, 87), p(775, 86)],
            [p(376, 73), p(384, 79), p(392, 80)]
        ] {
            var check = Path()
            check.addLines(points)
            context.stroke(check, with: .color(color(palette.dark).opacity(0.64)), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            context.stroke(check.offsetBy(dx: -0.6, dy: 1.5), with: .color(color(palette.light).opacity(0.63)),
                           style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
        }
        var endGrain = Path()
        endGrain.move(to: p(120, 245))
        endGrain.addCurve(to: p(166, 254), control1: p(138, 265), control2: p(150, 265))
        endGrain.addQuadCurve(to: p(185, 242), control: p(175, 240))
        context.stroke(endGrain.offsetBy(dx: 0, dy: -1), with: .color(color(palette.dark).opacity(0.68)),
                       style: StrokeStyle(lineWidth: 4, lineCap: .round))
        context.stroke(endGrain.offsetBy(dx: 0, dy: 1.4), with: .color(color(palette.light).opacity(0.56)),
                       style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
    }

    private func mineral() {
        for index in 0..<6 {
            let x = CGFloat(index) * 146 + 88
            polygon([p(x, 92), p(x + 97, 76), p(x + 150, 126), p(x + 111, 153), p(x + 16, 145)],
                    light: palette.light, face: palette.face, dark: palette.dark, opacity: 0.16)
        }
        for index in 0..<90 {
            let x = CGFloat((index * 179 + 37) % 823) + 91
            let y = CGFloat((index * 83 + 19) % 215) + 68
            let r = CGFloat(index % 3) + 0.8
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 1.5, height: r)),
                         with: .color(color(index.isMultiple(of: 3) ? palette.light : palette.edge).opacity(0.10)))
        }
        if theme == 3 {
            for x: CGFloat in [157, 834] {
                line([p(x, 94), p(x + 15, 119), p(x - 3, 140), p(x + 23, 157)], hex: palette.accent, width: 2.8, opacity: 0.75)
            }
        } else if theme == 10 {
            for x: CGFloat in [273, 716] { line([p(x, 80), p(x + 8, 110)], hex: palette.dark, width: 1.5, opacity: 0.22) }
        }
    }

    private func metal() {
        for index in 0..<24 {
            let y = 80 + CGFloat(index) * 8
            line([p(102, y), p(913, y + 1)], hex: index.isMultiple(of: 2) ? palette.light : palette.edge,
                 width: 0.7, opacity: index.isMultiple(of: 2) ? 0.22 : 0.07)
        }
        for x: CGFloat in [145, 855] {
            line([p(x, 104), p(x, 250)], hex: palette.edge, width: 2.2, opacity: 0.45)
            line([p(x + 3, 104), p(x + 3, 250)], hex: palette.light, width: 1.1, opacity: 0.75)
        }
    }

    private func ornament(front: Bool, side: Int) {
        switch theme {
        case 1:
            // The right shoulder extends farther than the left in the board outline.
            // Its growth therefore has its own attachment, rather than a mirrored rosette.
            var c = context
            if side == 1 { c.translateBy(x: -20, y: 0) }
            ResultSignPainter(context: c, palette: palette, pose: pose)
                .jungleCorner(front: front, right: side == 1)
        case 2:
            if front {
                leaf(at: p(-8, -43), length: 61, width: 24, angle: -108)
                leaf(at: p(-3, 64), length: 56, width: 28, angle: -145)
                chain(from: p(8, 64), to: p(-17, 112))
                star(at: p(-17, 112), radius: 10)
                rivet(at: p(8, 64), radius: 5)
            } else {
                vine()
                foliage(smaller: true)
                moon(at: p(-18, -93), radius: 34)
                branch([p(5, -63), p(-10, -73), p(-18, -78)])
            }
        case 3:
            if front {
                cornerMount(mineral: true)
                crystal(at: p(-10, 98), length: 64, width: 44, tilt: -21, dark: true)
                crystal(at: p(9, 108), length: 48, width: 31, tilt: 19, dark: true)
            } else {
                clusterRoot()
                crystal(at: p(-22, -16), length: 96, width: 50, tilt: -19, dark: true)
                crystal(at: p(12, -33), length: 115, width: 54, tilt: 6, dark: true)
                flame(at: p(-30, -75), height: 60)
                oval(CGRect(x: -49, y: -80, width: 38, height: 17), light: palette.dark, face: palette.edge, dark: palette.shadow)
            }
        case 4:
            if front {
                cornerMount()
                branch([p(-18, 42), p(-10, 58), p(-4, 70)])
                leaf(at: p(-4, 70), length: 60, width: 32, angle: -142)
                var cord = Path()
                cord.move(to: p(-21, -27))
                cord.addQuadCurve(to: p(69, -35), control: p(23, -8))
                context.stroke(cord, with: .color(color(palette.edge)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                for (index, x) in [-13.0, 13, 39].enumerated() {
                    let y: CGFloat = index == 0 ? -23 : index == 1 ? -20 : -23
                    polygon([p(x, y), p(x + 18, y + (index == 2 ? -5 : 0)), p(x + 10, y + 18)], light: palette.light,
                            face: index == 1 ? palette.accent : 0x88B8AC, dark: palette.edge)
                }
                rivet(at: p(-21, -27), radius: 4)
                rivet(at: p(69, -35), radius: 4)
            } else {
                villageRoof()
                leaf(at: p(-20, 67), length: 88, width: 43, angle: -164)
                leaf(at: p(-31, 40), length: 88, width: 36, angle: -83)
            }
        case 5:
            crystalCorner(front: front, right: side == 1)
        case 6:
            if front {
                cornerMount()
                gear(at: p(-12, 73), radius: 34)
                line([p(-35, -30), p(-35, 33), p(12, 33)], hex: palette.accentLight, width: 3)
                rivet(at: p(-35, -31), radius: 5)
                rivet(at: p(12, 33), radius: 4)
            } else {
                material(Path(roundedRect: CGRect(x: -59, y: 9, width: 91, height: 31), cornerRadius: 7),
                         light: palette.light, face: palette.accent, dark: palette.accentShade)
                skyline()
                gear(at: p(-18, -85), radius: 39)
            }
        case 7:
            if front {
                cornerMount(mineral: true)
                leaf(at: p(-2, 67), length: 54, width: 22, angle: -141)
                jewel(at: p(12, -53), radius: 18)
                oval(CGRect(x: -26, y: 65, width: 49, height: 26), light: palette.light, face: palette.face, dark: palette.dark)
            } else {
                palm()
                line([p(-29, -69), p(-30, 95)], hex: palette.edge, width: 8)
                line([p(-31, -69), p(-32, 95)], hex: palette.light, width: 2.5, opacity: 0.65)
            }
        case 8:
            if front {
                cornerMount()
                clock(at: p(-8, -28), radius: 30)
                gear(at: p(-23, 98), radius: 30)
                line([p(-15, 3), p(-23, 71)], hex: palette.edge, width: 5)
                rivet(at: p(-15, 3), radius: 3.3)
                rivet(at: p(-23, 71), radius: 3.3)
            } else {
                gear(at: p(-24, -86), radius: 50)
                gear(at: p(-56, -35), radius: 28)
                line([p(-45, -48), p(-44, 106), p(7, 106)], hex: palette.edge, width: 13)
                line([p(-48, -48), p(-47, 103)], hex: palette.light, width: 3)
                line([p(-24, -86), p(-24, -39), p(14, -39)], hex: palette.edge, width: 9)
            }
        case 9:
            if front {
                rope(from: p(12, -56), to: p(10, 70), bend: -23)
                ropeKnot(at: p(12, -56))
                ropeKnot(at: p(10, 70))
                shell(at: p(7, 76), radius: 38)
                jewel(at: p(12, -56), radius: 12)
            } else {
                rope(from: p(12, -56), to: p(10, 70), bend: -81)
                branch([p(12, -56), p(-9, -48), p(-20, -51)])
                leaf(at: p(-13, -51), length: 87, width: 32, angle: -37)
                leaf(at: p(-13, -51), length: 78, width: 29, angle: -93)
            }
        default:
            if front {
                cornerMount(mineral: true)
                polygon([p(-30, -30), p(9, -26), p(6, 108), p(-13, 96), p(-32, 114)],
                        light: palette.accentLight, face: palette.accent, dark: palette.accentShade)
                line([p(-34, -30), p(13, -26)], hex: palette.edge, width: 6)
                line([p(-34, -32), p(13, -28)], hex: palette.light, width: 2)
                for x: CGFloat in [-30, 9] { rivet(at: p(x, -29), radius: 4) }
                line([p(-13, -18), p(-14, 81)], hex: 0xF8DE96, width: 2.2)
                star(at: p(-13, 11), radius: 11)
            } else {
                tower()
                jewel(at: p(-17, -85), radius: 22)
            }
        }
    }

    private func crystalCorner(front: Bool, right: Bool) {
        var c = context
        if right { c.translateBy(x: -16, y: 0) }
        let painter = ResultSignPainter(context: c, palette: palette, pose: pose)
        if front {
            // A mineral vein is part of the rim, with no separate diamond hovering
            // above it. Its lower end enters the same stone as the crystal roots.
            var vein = Path()
            vein.move(to: p(5, -63))
            vein.addCurve(to: p(-18, -34), control1: p(-7, -61), control2: p(-14, -48))
            vein.addCurve(to: p(-14, 51), control1: p(-25, -10), control2: p(-23, 28))
            vein.addQuadCurve(to: p(14, 87), control: p(-11, 78))
            c.stroke(vein, with: .color(color(palette.accentShade).opacity(0.34)),
                     style: StrokeStyle(lineWidth: 5, lineCap: .round))
            c.stroke(vein.offsetBy(dx: 1, dy: -1), with: .color(color(palette.accentLight).opacity(0.64)),
                     style: StrokeStyle(lineWidth: 1.7, lineCap: .round))
            painter.crystal(at: p(2, 89), length: right ? 63 : 68, width: 35, tilt: -22)
            painter.crystal(at: p(17, 88), length: right ? 49 : 45, width: 27, tilt: 21)
            painter.crystal(at: p(-11, 86), length: 33, width: 20, tilt: -48)
            let root = Path { path in
                path.move(to: p(-23, 83))
                path.addQuadCurve(to: p(-10, 95), control: p(-20, 93))
                path.addQuadCurve(to: p(17, 96), control: p(3, 99))
                path.addQuadCurve(to: p(32, 87), control: p(27, 96))
                path.addQuadCurve(to: p(22, 79), control: p(32, 79))
                path.addQuadCurve(to: p(1, 82), control: p(10, 83))
                path.addQuadCurve(to: p(-23, 83), control: p(-17, 76))
                path.closeSubpath()
            }
            c.fill(root.offsetBy(dx: 0, dy: 2), with: .color(color(palette.accentShade).opacity(0.24)))
            painter.material(root, light: palette.accentLight, face: palette.dark, dark: palette.edge)
            painter.line([p(-13, 87), p(2, 91), p(23, 86)], hex: palette.accentLight, width: 1.1, opacity: 0.55)
        } else {
            painter.polygon([p(-28, -41), p(-7, -62), p(23, -51), p(34, -20), p(2, 3), p(-34, -8)],
                            light: palette.dark, face: palette.edge, dark: palette.accentShade)
            painter.crystal(at: p(-10, -43), length: right ? 81 : 86, width: 39, tilt: -43)
            painter.crystal(at: p(5, -49), length: right ? 97 : 102, width: 48, tilt: 4)
            painter.crystal(at: p(-2, -39), length: 57, width: 29, tilt: -73)
        }
    }

    private func jungleCorner(front: Bool, right: Bool) {
        if front {
            // The upper roots meet the shoulder itself. There is no exposed straight
            // stem crossing the wood or the rim highlight.
            jungleLeaf(at: p(0, -60), length: right ? 80 : 82, width: 46,
                       angle: right ? 72 : 78, curl: 0.30, depth: 0)
            jungleLeaf(at: p(1, -57), length: right ? 63 : 64, width: 33,
                       angle: right ? -158 : -169, curl: -0.06, depth: 0.06)
            // Roots sit on the side edge; connecting stems stay behind the wood.
            jungleLeaf(at: p(-18, 62), length: right ? 64 : 70, width: 43,
                       angle: right ? -142 : -136, curl: 0.13, depth: 0.05)
            jungleLeaf(at: p(-10, 67), length: right ? 48 : 52, width: 31,
                       angle: right ? 149 : 162, curl: -0.12, depth: 0.16)
        } else {
            vine()
            // Individual roots and unequal silhouettes keep the corner botanical,
            // rather than arranging identical leaves as a radial badge.
            let leaves: [(CGPoint, CGFloat, CGFloat, Double, CGFloat, Double)] = right ? [
                (p(1, -61), 97, 53, -8, -0.09, 0.16),
                (p(0, -58), 83, 57, -62, 0.15, 0.07),
                (p(3, -60), 58, 38, 36, -0.10, 0.24),
                (p(-18, -18), 78, 52, -84, 0.18, 0.26),
                (p(-12, 26), 86, 55, -131, -0.12, 0.30),
                (p(-3, 57), 77, 45, -158, 0.09, 0.22)
            ] : [
                (p(2, -61), 94, 52, -22, 0.12, 0.10),
                (p(0, -58), 90, 59, -64, -0.12, 0.24),
                (p(5, -60), 61, 39, 48, 0.13, 0.19),
                (p(-20, -16), 99, 56, -83, -0.12, 0.33),
                (p(-17, 26), 93, 55, -134, 0.10, 0.17),
                (p(-3, 55), 83, 44, -165, -0.10, 0.28)
            ]
            for (root, length, width, angle, curl, depth) in leaves {
                jungleLeaf(at: root, length: length, width: width, angle: angle, curl: curl, depth: depth)
            }
        }
    }

    /// A fuller, softly rolled leaf for the sign's close-up foreground.
    /// Other worlds retain their own finer leaf silhouettes.
    private func jungleLeaf(at: CGPoint, length: CGFloat, width: CGFloat, angle: Double,
                            curl: CGFloat, depth: Double) {
        var c = context
        c.translateBy(x: at.x, y: at.y)
        c.rotate(by: .degrees(angle))
        let tip = p(width * curl, -length)
        let shape = Path { path in
            path.move(to: .zero)
            path.addCurve(to: tip, control1: p(-width * 0.57, -length * 0.16), control2: p(-width * 0.66, -length * 0.78))
            path.addCurve(to: .zero, control1: p(width * 0.61, -length * 0.91), control2: p(width * 0.65, -length * 0.23))
            path.closeSubpath()
        }
        func tone(_ a: UInt32, _ b: UInt32, _ amount: Double) -> Color {
            func channel(_ shift: UInt32) -> UInt32 {
                UInt32(Double((a >> shift) & 255) * (1 - amount) + Double((b >> shift) & 255) * amount)
            }
            return color(channel(16) << 16 | channel(8) << 8 | channel(0))
        }
        let light = tone(palette.accentLight, palette.accent, depth * 0.70)
        let face = tone(palette.accent, palette.accentShade, depth)
        let shade = color(palette.accentShade)
        c.drawLayer { shadow in
            shadow.addFilter(.blur(radius: 2.1))
            shadow.fill(shape.offsetBy(dx: width * 0.07, dy: 3), with: .color(color(palette.shadow).opacity(0.36)))
        }
        c.fill(shape, with: .linearGradient(Gradient(stops: [
            .init(color: shade, location: 0), .init(color: face, location: 0.20),
            .init(color: light, location: 0.43), .init(color: face, location: 0.77),
            .init(color: shade, location: 1)
        ]), startPoint: p(-width * 0.56, -length * 0.59), endPoint: p(width * 0.56, -length * 0.46)))
        var fold = Path()
        fold.move(to: .zero)
        fold.addQuadCurve(to: tip, control: p(-width * 0.12, -length * 0.53))
        fold.addCurve(to: .zero, control1: p(width * 0.61, -length * 0.91), control2: p(width * 0.65, -length * 0.23))
        fold.closeSubpath()
        c.fill(fold, with: .linearGradient(Gradient(colors: [light.opacity(0.11), shade.opacity(0.28)]),
                                         startPoint: tip, endPoint: .zero))
        c.drawLayer { detail in
            detail.clip(to: shape)
            detail.fill(shape, with: .radialGradient(Gradient(colors: [light.opacity(0.38), .clear]),
                                                    center: p(-width * 0.10, -length * 0.70), startRadius: 0, endRadius: width * 0.60))
            var veins = Path()
            for fraction: CGFloat in [0.26, 0.48, 0.69] {
                let u = 1 - fraction
                let root = p(2 * u * fraction * -width * 0.12 + fraction * fraction * tip.x,
                             2 * u * fraction * -length * 0.53 - fraction * fraction * length)
                for side: CGFloat in [-1, 1] {
                    veins.move(to: root)
                    veins.addQuadCurve(to: p(side * width * (fraction > 0.6 ? 0.29 : 0.40), root.y - length * 0.12),
                                       control: p(side * width * 0.22, root.y - length * 0.025))
                }
            }
            detail.stroke(veins, with: .color(shade.opacity(0.28)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
            detail.stroke(veins.offsetBy(dx: -0.4, dy: -0.5), with: .color(light.opacity(0.23)),
                          style: StrokeStyle(lineWidth: 0.65, lineCap: .round))
        }
        var rib = Path()
        rib.move(to: .zero)
        rib.addQuadCurve(to: p(tip.x * 0.95, tip.y * 0.95), control: p(-width * 0.12, -length * 0.53))
        c.stroke(rib, with: .color(shade.opacity(0.51)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        c.stroke(rib.offsetBy(dx: -0.6, dy: -0.5), with: .color(light.opacity(0.55)),
                 style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
        c.stroke(shape, with: .linearGradient(Gradient(colors: [light.opacity(0.82), light.opacity(0.05)]),
                                             startPoint: tip, endPoint: .zero), lineWidth: 1.1)
    }

    private func foliage(smaller: Bool = false) {
        let leaves: [(CGFloat, CGFloat, CGFloat, CGFloat, Double)] = [
            (7, -66, 91, 55, -12), (7, -66, 92, 60, -62),
            (13, -65, 68, 41, 48), (-13, -33, 101, 57, -85),
            (-13, 12, 106, 62, -127), (-2, 56, 89, 52, -166),
            (1, 62, 63, 38, 157)
        ]
        for item in leaves {
            let size: CGFloat = smaller ? 0.82 : 1
            branch([p(7, -64), p(-18, -13), p(item.0, item.1)])
            leaf(at: p(item.0, item.1), length: item.2 * size, width: item.3 * size, angle: item.4)
        }
    }
    private func vine() {
        var path = Path()
        path.move(to: p(13, -68))
        path.addCurve(to: p(-42, 6), control1: p(-22, -69), control2: p(-48, -28))
        path.addCurve(to: p(5, 88), control1: p(-54, 50), control2: p(-12, 77))
        context.stroke(path.offsetBy(dx: 2, dy: 3), with: .color(color(palette.shadow).opacity(0.30)),
                       style: StrokeStyle(lineWidth: 15, lineCap: .round))
        context.stroke(path, with: .linearGradient(Gradient(colors: [color(palette.accent), color(palette.accentShade)]),
                                                  startPoint: p(-42, -60), endPoint: p(7, 90)),
                       style: StrokeStyle(lineWidth: 13, lineCap: .round))
        context.stroke(path.offsetBy(dx: -2, dy: -1), with: .color(color(palette.accentLight).opacity(0.56)),
                       style: StrokeStyle(lineWidth: 3.3, lineCap: .round))
    }
    private func leaf(at: CGPoint, length: CGFloat, width: CGFloat, angle: Double) {
        var c = context
        c.translateBy(x: at.x, y: at.y); c.rotate(by: .degrees(angle))
        let rect = CGRect(x: -width / 2, y: -length, width: width, height: length)
        let shape = DinoFoliageLeaf().path(in: CGRect(origin: .zero, size: rect.size)).offsetBy(dx: rect.minX, dy: rect.minY)
        let fold = DinoFoliageFold().path(in: CGRect(origin: .zero, size: rect.size)).offsetBy(dx: rect.minX, dy: rect.minY)
        let veins = DinoFoliageVeins().path(in: CGRect(origin: .zero, size: rect.size)).offsetBy(dx: rect.minX, dy: rect.minY)
        c.drawLayer { shadow in
            shadow.addFilter(.blur(radius: max(1, width * 0.045)))
            shadow.fill(shape.offsetBy(dx: width * 0.07, dy: length * 0.035),
                        with: .color(color(palette.shadow).opacity(0.34)))
        }
        c.fill(shape, with: .linearGradient(Gradient(stops: [
            .init(color: color(palette.accentShade), location: 0), .init(color: color(palette.accent), location: 0.18),
            .init(color: color(palette.accentLight), location: 0.40), .init(color: color(palette.accent), location: 0.70),
            .init(color: color(palette.accentShade), location: 1)
        ]), startPoint: p(-width * 0.53, -length * 0.62), endPoint: p(width * 0.55, -length * 0.44)))
        c.fill(shape, with: .linearGradient(Gradient(colors: [.clear, color(palette.accentShade).opacity(0.42)]),
                                         startPoint: p(0, -length * 0.7), endPoint: .zero))
        c.fill(fold, with: .linearGradient(Gradient(colors: [color(palette.accentLight).opacity(0.12), color(palette.accentShade).opacity(0.33)]),
                                         startPoint: p(0, -length), endPoint: .zero))
        c.drawLayer { gloss in
            gloss.clip(to: shape)
            gloss.fill(shape, with: .radialGradient(Gradient(colors: [color(palette.accentLight).opacity(0.42), .clear]),
                                                  center: p(-width * 0.13, -length * 0.75), startRadius: 0, endRadius: width * 0.55))
        }
        c.stroke(veins.offsetBy(dx: 0.7, dy: 0.8), with: .color(color(palette.accentShade).opacity(0.48)),
                 style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
        c.stroke(veins, with: .color(color(palette.accentLight).opacity(0.52)),
                 style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
        c.stroke(shape, with: .linearGradient(Gradient(colors: [color(palette.accentLight).opacity(0.88),
                                                                               color(palette.accentLight).opacity(0.08)]),
                                             startPoint: p(-width * 0.28, -length), endPoint: .zero), lineWidth: 1.2)
    }

    private func branch(_ vertices: [CGPoint]) {
        line(vertices, hex: palette.accentShade, width: 5.5)
        line(vertices.map { p($0.x - 0.8, $0.y - 0.6) }, hex: palette.accent, width: 2.4)
    }

    private func chain(from start: CGPoint, to end: CGPoint) {
        var cord = Path()
        cord.move(to: start)
        cord.addQuadCurve(to: end, control: p(start.x - 3, end.y - 8))
        context.stroke(cord.offsetBy(dx: 1, dy: 1), with: .color(color(palette.accentShade).opacity(0.5)),
                       style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
        context.stroke(cord, with: .color(color(0xE5D49A)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        context.stroke(cord, with: .color(color(0xFFF4C6)), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [2, 3]))
    }

    /// Raised end plates overlap both the panel and the roots of the world ornaments.
    private func cornerMount(mineral: Bool = false) {
        let shape = Path { path in
            path.move(to: p(24, -65))
            path.addCurve(to: p(-19, -29), control1: p(-3, -64), control2: p(-17, -49))
            path.addCurve(to: p(-11, 58), control1: p(-27, -5), control2: p(-23, 33))
            path.addCurve(to: p(25, 92), control1: p(-8, 78), control2: p(6, 90))
            path.addLine(to: p(28, 80))
            path.addCurve(to: p(1, 53), control1: p(11, 78), control2: p(4, 66))
            path.addCurve(to: p(-6, -27), control1: p(-10, 28), control2: p(-13, 0))
            path.addCurve(to: p(28, -53), control1: p(-4, -43), control2: p(9, -53))
            path.closeSubpath()
        }
        context.fill(shape.offsetBy(dx: 1.5, dy: 2.5), with: .color(color(palette.shadow).opacity(0.25)))
        material(shape, light: palette.light, face: mineral ? palette.dark : palette.face, dark: palette.edge)
        context.stroke(shape, with: .linearGradient(Gradient(colors: [color(palette.light).opacity(0.85), color(palette.edge).opacity(0.75)]),
                                                   startPoint: p(-20, -60), endPoint: p(15, 95)), lineWidth: 1.2)
        if !mineral {
            rivet(at: p(14, -55), radius: 4)
            rivet(at: p(13, 79), radius: 4)
        }
    }

    private func clusterRoot() {
        polygon([p(-49, -24), p(-25, -47), p(10, -51), p(32, -22), p(29, 26), p(-36, 25)],
                light: palette.dark, face: palette.edge, dark: palette.shadow)
    }

    private func ropeKnot(at: CGPoint) {
        var c = context
        c.translateBy(x: at.x, y: at.y)
        c.rotate(by: .degrees(-26))
        let painter = ResultSignPainter(context: c, palette: palette, pose: pose)
        for x: CGFloat in [-5, 1, 7] {
            painter.oval(CGRect(x: x - 5, y: -9, width: 10, height: 18),
                         light: 0xFFF0C6, face: 0xD5B47D, dark: palette.edge)
        }
    }

    private func crystal(at: CGPoint, length: CGFloat, width: CGFloat, tilt: Double, dark: Bool = false) {
        var c = context
        c.translateBy(x: at.x, y: at.y); c.rotate(by: .degrees(tilt))
        let painter = ResultSignPainter(context: c, palette: palette, pose: pose)
        let light = dark ? UInt32(0xA5A0AC) : palette.accentLight
        let face = dark ? UInt32(0x696574) : palette.accent
        let shade = dark ? UInt32(0x464353) : palette.accentShade
        if !dark {
            let silhouette = Path { path in
                path.addLines([p(-width * 0.48, 0), p(-width * 0.48, -length * 0.76),
                               p(0, -length), p(width * 0.48, -length * 0.74), p(width * 0.48, 0)])
                path.closeSubpath()
            }
            c.fill(silhouette.offsetBy(dx: 1.5, dy: 2), with: .color(color(palette.shadow).opacity(0.23)))
            painter.material(silhouette, light: light, face: face, dark: shade)
            painter.polygon([p(width * 0.06, 0), p(width * 0.06, -length * 0.76),
                             p(width * 0.48, -length * 0.74), p(width * 0.48, 0)],
                            light: face, face: shade, dark: shade, opacity: 0.70)
            painter.polygon([p(-width * 0.48, -length * 0.76), p(0, -length), p(width * 0.06, -length * 0.76)],
                            light: light, face: light, dark: face)
            painter.polygon([p(0, -length), p(width * 0.48, -length * 0.74), p(width * 0.06, -length * 0.76)],
                            light: light, face: face, dark: shade)
            painter.polygon([p(-width * 0.34, -length * 0.12), p(-width * 0.31, -length * 0.69),
                             p(-width * 0.14, -length * 0.75), p(-width * 0.20, -length * 0.18)],
                            light: light, face: light, dark: face, opacity: 0.24)
            painter.line([p(-width * 0.46, -length * 0.17), p(-width * 0.46, -length * 0.75), p(0, -length)],
                         hex: light, width: 1.5, opacity: 0.72)
            painter.line([p(width * 0.06, -length * 0.10), p(width * 0.06, -length * 0.75)],
                         hex: light, width: 0.9, opacity: 0.28)
            if pose.accentGlow > 0 {
                painter.glow(at: p(0, -length * 0.65), radius: width, opacity: min(1, pose.accentGlow) * 0.28)
            }
            return
        }
        painter.polygon([p(-width * 0.48, 0), p(-width * 0.48, -length * 0.76), p(0, -length),
                         p(width * 0.48, -length * 0.73), p(width * 0.5, -3)], light: light, face: face, dark: shade)
        painter.polygon([p(0, 0), p(0, -length), p(width * 0.48, -length * 0.73), p(width * 0.5, -3)],
                        light: face, face: shade, dark: shade, opacity: 0.45)
        painter.line([p(-width * 0.39, -length * 0.12), p(-width * 0.39, -length * 0.71), p(0, -length * 0.94)],
                     hex: light, width: 1.7, opacity: 0.80)
    }
    private func moon(at: CGPoint, radius: CGFloat) {
        glow(at: at, radius: radius * 1.8, opacity: 0.18)
        var c = context
        let outer = Path(ellipseIn: CGRect(x: at.x - radius, y: at.y - radius, width: radius * 2, height: radius * 2))
        c.clip(to: Path(ellipseIn: CGRect(x: at.x - radius * 0.22, y: at.y - radius * 1.18, width: radius * 1.72, height: radius * 1.72)), options: .inverse)
        c.fill(outer, with: .linearGradient(Gradient(colors: [color(0xFFF9D8), color(0xE8CF8D)]),
                                           startPoint: p(at.x, at.y - radius), endPoint: p(at.x, at.y + radius)))
    }
    private func flame(at: CGPoint, height: CGFloat) {
        func shape(_ s: CGFloat) -> Path {
            Path { path in
                path.move(to: p(at.x, at.y + 10))
                path.addCurve(to: p(at.x - 10 * s, at.y - height), control1: p(at.x - 42 * s, at.y - height * 0.18), control2: p(at.x + 8 * s, at.y - height * 0.62))
                path.addCurve(to: p(at.x + 10 * s, at.y - height * 0.47), control1: p(at.x - 20 * s, at.y - height * 0.52), control2: p(at.x + 7 * s, at.y - height * 0.30))
                path.addCurve(to: p(at.x, at.y + 10), control1: p(at.x + 37 * s, at.y - height * 0.15), control2: p(at.x + 29 * s, at.y + 10))
                path.closeSubpath()
            }
        }
        material(shape(1), light: 0xFFECAD, face: 0xF7A353, dark: 0xC35F40)
        glow(at: at, radius: 45, opacity: 0.12 + min(1, max(0, pose.accentGlow)) * 0.25)
    }
    private func villageRoof() {
        material(Path(roundedRect: CGRect(x: -47, y: -92, width: 69, height: 110), cornerRadius: 7),
                 light: palette.light, face: palette.face, dark: palette.dark)
        polygon([p(-61, -85), p(-12, -137), p(40, -85)], light: 0xF2C195, face: 0xBF7C59, dark: 0x805D47)
        line([p(-59, -83), p(-12, -129), p(37, -83)], hex: 0xF5DBA9, width: 3)
        material(Path(roundedRect: CGRect(x: -24, y: -80, width: 23, height: 30), cornerRadius: 5), light: 0xF9EFCA, face: 0x83A99E, dark: 0x597E76)
        line([p(-12, -78), p(-12, -52)], hex: palette.light, width: 1.5)
    }
    private func skyline() {
        for (index, x) in [-57.0, -27, 2].enumerated() {
            let height: CGFloat = [82, 122, 94][index]
            material(Path(roundedRect: CGRect(x: x, y: -height, width: 26, height: height + 25), cornerRadius: 4),
                     light: palette.accentLight, face: palette.accent, dark: palette.accentShade)
            for row in 0..<3 { for col in 0..<2 {
                context.fill(Path(roundedRect: CGRect(x: x + 5 + CGFloat(col) * 10, y: -height + 14 + CGFloat(row) * 18, width: 5, height: 8), cornerRadius: 1),
                             with: .color(color(palette.light).opacity(0.9)))
            } }
        }
    }
    private func palm() {
        let crown = p(-29, -69)
        for (index, angle) in [-92.0, -57, -22, 25, 65, 96].enumerated() {
            leaf(at: crown, length: index == 2 ? 83 : 92, width: 23, angle: angle)
        }
    }
    private func gear(at: CGPoint, radius: CGFloat) {
        var gear = Path()
        for index in 0..<48 {
            let angle = Double(index) * .pi * 2 / 48
            let r = index % 4 == 0 || index % 4 == 3 ? radius * 0.79 : radius
            let point = p(at.x + CGFloat(cos(angle)) * r, at.y + CGFloat(sin(angle)) * r)
            if index == 0 { gear.move(to: point) } else { gear.addLine(to: point) }
        }
        gear.closeSubpath()
        material(gear.offsetBy(dx: 0, dy: 3.5), light: palette.dark, face: palette.edge, dark: palette.shadow)
        material(gear, light: palette.light, face: palette.face, dark: palette.edge)
        context.stroke(gear, with: .color(color(palette.edge).opacity(0.65)), lineWidth: 1.6)
        context.stroke(gear.offsetBy(dx: -0.5, dy: -1), with: .linearGradient(Gradient(colors: [color(palette.light), .clear]),
                                                                           startPoint: p(at.x, at.y - radius), endPoint: p(at.x, at.y + radius)), lineWidth: 1.4)
        context.stroke(Path(ellipseIn: CGRect(x: at.x - radius * 0.66, y: at.y - radius * 0.66, width: radius * 1.32, height: radius * 1.32)),
                       with: .color(color(palette.edge).opacity(0.40)), lineWidth: 1.8)
        oval(CGRect(x: at.x - radius * 0.46, y: at.y - radius * 0.46, width: radius * 0.92, height: radius * 0.92),
             light: palette.accentLight, face: palette.accent, dark: palette.accentShade)
        oval(CGRect(x: at.x - radius * 0.17, y: at.y - radius * 0.17, width: radius * 0.34, height: radius * 0.34),
             light: palette.dark, face: palette.edge, dark: palette.shadow)
    }
    private func clock(at: CGPoint, radius: CGFloat) {
        oval(CGRect(x: at.x - radius - 6, y: at.y - radius - 3, width: radius * 2 + 12, height: radius * 2 + 12),
             light: palette.dark, face: palette.edge, dark: palette.shadow)
        oval(CGRect(x: at.x - radius - 5, y: at.y - radius - 5, width: radius * 2 + 10, height: radius * 2 + 10), light: palette.light, face: palette.face, dark: palette.edge)
        oval(CGRect(x: at.x - radius, y: at.y - radius, width: radius * 2, height: radius * 2), light: 0xFFFAE4, face: 0xEDE4C6, dark: 0xB5AC8D)
        for index in 0..<12 {
            let a = Double(index) * .pi / 6
            line([p(at.x + CGFloat(cos(a)) * radius * 0.73, at.y + CGFloat(sin(a)) * radius * 0.73),
                  p(at.x + CGFloat(cos(a)) * radius * 0.86, at.y + CGFloat(sin(a)) * radius * 0.86)], hex: palette.ink, width: 1.5)
        }
        line([p(at.x - 13, at.y - 9), at, p(at.x + 13, at.y - 17)], hex: palette.ink, width: 3)
        rivet(at: at, radius: 3)
    }
    private func rope(from start: CGPoint, to end: CGPoint, bend: CGFloat) {
        var rope = Path()
        rope.move(to: start); rope.addCurve(to: end, control1: p(start.x + bend, start.y + 27), control2: p(end.x + bend, end.y - 28))
        context.stroke(rope, with: .color(color(palette.edge)), style: StrokeStyle(lineWidth: 10, lineCap: .round))
        context.stroke(rope, with: .color(color(0xD5B47D)), style: StrokeStyle(lineWidth: 7, lineCap: .round))
        context.stroke(rope, with: .color(color(0xF9E4B3)), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 5]))
    }
    private func shell(at: CGPoint, radius: CGFloat) {
        let bottom = p(at.x, at.y + radius * 0.45)
        var fan = Path()
        fan.move(to: bottom)
        for index in 0...8 {
            let angle = Double(index) * .pi / 8 + .pi
            let at = p(at.x + CGFloat(cos(angle)) * radius, at.y + CGFloat(sin(angle)) * radius)
            fan.addLine(to: at)
        }
        fan.closeSubpath()
        material(fan, light: 0xFFF0CE, face: 0xDCC299, dark: 0xA68D70)
        for index in 0...8 {
            let a = Double(index) * .pi / 8 + .pi
            line([bottom, p(at.x + CGFloat(cos(a)) * radius * 0.94, at.y + CGFloat(sin(a)) * radius * 0.94)], hex: 0xFFF4D8, width: 2, opacity: 0.65)
        }
    }
    private func tower() {
        let body = Path(roundedRect: CGRect(x: -47, y: -101, width: 61, height: 146), cornerRadius: 7)
        material(body, light: palette.light, face: palette.face, dark: palette.dark)
        for y: CGFloat in [-75, -51, -27] { line([p(-45, y), p(12, y)], hex: palette.edge, width: 1.2, opacity: 0.4) }
        for x: CGFloat in [-46, -23, 0] {
            material(Path(roundedRect: CGRect(x: x, y: -117, width: 15, height: 25), cornerRadius: 2), light: palette.light, face: palette.face, dark: palette.dark)
        }
        material(Path(roundedRect: CGRect(x: -26, y: -80, width: 16, height: 35), cornerRadius: 8), light: palette.accentLight, face: palette.accent, dark: palette.accentShade)
    }
    private func jewel(at: CGPoint, radius: CGFloat) {
        polygon([p(at.x, at.y - radius), p(at.x + radius * 0.76, at.y), p(at.x, at.y + radius), p(at.x - radius * 0.76, at.y)],
                light: palette.accentLight, face: palette.accent, dark: palette.accentShade)
        line([p(at.x, at.y - radius * 0.8), p(at.x, at.y + radius * 0.7)], hex: palette.light, width: 1.5, opacity: 0.7)
    }
    private func star(at: CGPoint, radius: CGFloat) {
        var path = Path()
        for index in 0..<8 {
            let angle = Double(index) * .pi / 4 - .pi / 2
            let r = radius * (index.isMultiple(of: 2) ? 1 : 0.29)
            let at = p(at.x + CGFloat(cos(angle)) * r, at.y + CGFloat(sin(angle)) * r)
            if index == 0 { path.move(to: at) } else { path.addLine(to: at) }
        }
        path.closeSubpath()
        material(path, light: 0xFFF9D8, face: 0xF7E1A0, dark: 0xCEB771)
    }

    private func material(_ path: Path, light: UInt32, face: UInt32, dark: UInt32) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(stops: [
            .init(color: color(light), location: 0), .init(color: color(face), location: 0.43), .init(color: color(dark), location: 1)
        ]), startPoint: p(r.minX, r.minY), endPoint: p(r.maxX, r.maxY)))
    }
    private func polygon(_ vertices: [CGPoint], light: UInt32, face: UInt32, dark: UInt32, opacity: Double = 1) {
        var path = Path(); path.addLines(vertices); path.closeSubpath()
        var c = context; c.opacity *= opacity
        ResultSignPainter(context: c, palette: palette, pose: pose).material(path, light: light, face: face, dark: dark)
    }
    private func oval(_ rect: CGRect, light: UInt32, face: UInt32, dark: UInt32) {
        context.fill(Path(ellipseIn: rect), with: .radialGradient(Gradient(colors: [color(light), color(face), color(dark)]),
                                                                center: p(rect.minX + rect.width * 0.30, rect.minY + rect.height * 0.24),
                                                                startRadius: 0, endRadius: max(rect.width, rect.height) * 0.85))
    }
    private func rivet(at: CGPoint, radius: CGFloat) {
        oval(CGRect(x: at.x - radius - 1.5, y: at.y - radius - 0.5, width: radius * 2 + 3, height: radius * 2 + 3),
             light: palette.dark, face: palette.edge, dark: palette.shadow)
        oval(CGRect(x: at.x - radius, y: at.y - radius, width: radius * 2, height: radius * 2), light: palette.light, face: palette.dark, dark: palette.edge)
        line([p(at.x - radius * 0.4, at.y), p(at.x + radius * 0.4, at.y)], hex: palette.edge, width: 1)
    }
    private func line(_ vertices: [CGPoint], hex: UInt32, width: CGFloat, opacity: Double = 1) {
        var path = Path(); path.addLines(vertices)
        context.stroke(path, with: .color(color(hex).opacity(opacity)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func glow(at: CGPoint, radius: CGFloat, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: at.x - radius, y: at.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [color(palette.accentLight).opacity(opacity), .clear]), center: at, startRadius: 0, endRadius: radius))
    }
}
