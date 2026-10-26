import SwiftUI

/// One drawing space keeps the landing surface, rewards and surrounding props registered.
/// Theme identity deliberately follows the catalog, rather than the world's route position.
struct ResultPodiumPalette {
    let themeID: Int
    let light: UInt32
    let face: UInt32
    let shade: UInt32
    let edge: UInt32
    let accent: UInt32
    let glow: UInt32

    init(worldID: Int) {
        themeID = (DinoWorldCatalog.world(worldID) ?? DinoWorldCatalog.worlds[0]).themeID
        switch themeID {
        case 2: (light, face, shade, edge, accent, glow) = (0xCEDDDC, 0x879EAA, 0x4C637C, 0x344B68, 0xA3D8C3, 0xBBDDEB)
        case 3: (light, face, shade, edge, accent, glow) = (0xA29AA6, 0x62596C, 0x373244, 0x272738, 0xFFAE63, 0xFFBF83)
        case 4: (light, face, shade, edge, accent, glow) = (0xF6E4BD, 0xCBB58D, 0x988266, 0x6A6250, 0x8EAF66, 0xFFF1BD)
        case 5: (light, face, shade, edge, accent, glow) = (0xDAF8F3, 0x8BC4CC, 0x4B819D, 0x365E7E, 0xBCA8EB, 0xB8F4EB)
        case 6: (light, face, shade, edge, accent, glow) = (0xD9EEEB, 0x80AFBC, 0x456D85, 0x304E66, 0xB5E9DC, 0xD0F3EA)
        case 7: (light, face, shade, edge, accent, glow) = (0xFFE5AF, 0xD2AC74, 0xA37B51, 0x815D40, 0x8FAD79, 0xFFE9AE)
        case 8: (light, face, shade, edge, accent, glow) = (0xFFE6AE, 0xC5A06A, 0x846951, 0x505666, 0x9DDFDC, 0xBDF3EA)
        case 9: (light, face, shade, edge, accent, glow) = (0xF2D09A, 0xC69A60, 0x8E633D, 0x62432C, 0xBFA269, 0xF3DEAA)
        case 10: (light, face, shade, edge, accent, glow) = (0xF1EBD7, 0xC6C9BA, 0x8C9BA2, 0x61768B, 0xD4B676, 0xE4EEFF)
        default: (light, face, shade, edge, accent, glow) = (0xEEE6C5, 0xBAB894, 0x7C8966, 0x526344, 0x8FC348, 0xFFF6B9)
        }
    }
}

/// The rewards are positioned on the actual stone, with no separate surface or material mask.
enum ResultPodiumGeometry {
    static let width: CGFloat = 1000
    static let height: CGFloat = 455
    static func rewardY(worldID: Int) -> CGFloat {
        switch DinoWorldCatalog.world(worldID)?.themeID {
        case 4: return 285
        case 6: return 294
        case 8: return 272
        case 9: return 308
        default: return 292
        }
    }

    static func starWidth(worldID: Int) -> CGFloat {
        switch DinoWorldCatalog.world(worldID)?.themeID {
        case 4: return 0.22
        // Keep the reward's glow and shadow clear of the metal foot and crate rail.
        case 6, 8, 9: return 0.19
        default: return 0.235
        }
    }

    static func groundFrontY(themeID: Int) -> CGFloat {
        switch themeID {
        case 3: return 447
        case 4, 10: return 445
        case 5: return 472
        case 7: return 478
        case 9: return 455
        case 6, 8: return 453.5
        default: return 476
        }
    }
}

struct ResultWorldPodium: View {
    let worldID: Int
    var body: some View {
        GeometryReader { geometry in
            // The logical stone keeps its exact anchor; drawing space also includes moss and shadows.
            Canvas(rendersAsynchronously: true) { context, size in
                var art = context
                art.scaleBy(x: size.width / 1240, y: size.height / 728)
                art.translateBy(x: 120, y: 136.5)
                ResultPodiumPainter(context: art, palette: .init(worldID: worldID)).draw()
            }
            .frame(width: geometry.size.width * 1.24, height: geometry.size.height * 1.6)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Extra room around the body is real drawing space, so banners and crystal tips never clip.
struct ResultPodiumSurround: View {
    let worldID: Int
    var foreground = false
    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            var art = context
            art.scaleBy(x: size.width / 1240, y: size.height / 728)
            art.translateBy(x: 120, y: 136.5)
            ResultPodiumPainter(context: art, palette: .init(worldID: worldID)).surround(foreground: foreground)
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct ResultPodiumPainter {
    let context: GraphicsContext
    let palette: ResultPodiumPalette
    private var theme: Int { palette.themeID }
    private func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
    private func c(_ hex: UInt32) -> Color { Color(dinoHex: hex) }
    private func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> UInt32 {
        func channel(_ shift: UInt32) -> UInt32 { UInt32(Double((a >> shift) & 255) * (1 - t) + Double((b >> shift) & 255) * t) }
        return channel(16) << 16 | channel(8) << 8 | channel(0)
    }
    private func polygon(_ points: [(CGFloat, CGFloat)]) -> Path {
        Path { path in path.addLines(points.map { p($0.0, $0.1) }); path.closeSubpath() }
    }
    private func fill(_ path: Path, _ top: UInt32, _ bottom: UInt32) {
        let rect = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(colors: [c(top), c(bottom)]),
            startPoint: p(rect.minX + rect.width * 0.3, rect.minY), endPoint: p(rect.midX, rect.maxY)))
    }
    private func stroke(_ path: Path, _ hex: UInt32, _ width: CGFloat, opacity: Double = 1) {
        context.stroke(path, with: .color(c(hex).opacity(opacity)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func line(_ points: [(CGFloat, CGFloat)], _ hex: UInt32, _ width: CGFloat, opacity: Double = 1) {
        var path = Path(); path.addLines(points.map { p($0.0, $0.1) }); stroke(path, hex, width, opacity: opacity)
    }
    private func oval(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ hex: UInt32, opacity: Double = 1) {
        context.fill(Path(ellipseIn: CGRect(x: x - width / 2, y: y - height / 2, width: width, height: height)), with: .color(c(hex).opacity(opacity)))
    }
    private func glow(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, _ hex: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
            with: .radialGradient(Gradient(colors: [c(hex).opacity(opacity), .clear]), center: p(x, y), startRadius: 0, endRadius: radius))
    }
    private func curve(_ points: [(CGFloat, CGFloat)]) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: p(first.0, first.1))
            for item in points.dropFirst() { path.addLine(to: p(item.0, item.1)) }
        }
    }

    /// The same open crown is used by both the cap and the rock silhouette.
    /// In particular, neither shoulder can expose the dark body under a smaller oval cap.
    private var rockCrown: Path {
        Path { path in
            path.move(to: p(98, 130))
            path.addCurve(to: p(152, 66), control1: p(106, 105), control2: p(130, 80))
            path.addCurve(to: p(842, 61), control1: p(302, 1), control2: p(706, 0))
            path.addCurve(to: p(910, 132), control1: p(881, 77), control2: p(898, 108))
        }
    }

    private func appendRockFoot(to path: inout Path) {
        path.addCurve(to: p(947, 471), control1: p(1012, 470), control2: p(995, 471))
        path.addCurve(to: p(69, 474), control1: p(742, 480), control2: p(227, 479))
        path.addCurve(to: p(-3, 465), control1: p(18, 475), control2: p(-13, 475))
    }

    private var machineBodyY: CGFloat { theme == 6 ? 378 : 336 }
    private var machineStepY: CGFloat { theme == 6 ? 386 : 363 }
    private var machineBaseY: CGFloat { theme == 6 ? 426 : 411 }
    private var machineBaseControlY: CGFloat { theme == 6 ? 481 : 496 }

    private var outline: Path {
        switch theme {
        case 3: return polygon([(146, 78), (304, 32), (690, 25), (856, 71), (926, 158), (955, 278), (983, 345), (938, 417), (747, 447), (221, 444), (62, 412), (22, 334), (74, 178)])
        case 5: return polygon([(156, 70), (298, 24), (616, 19), (827, 53), (893, 111), (981, 256), (965, 382), (1002, 450), (844, 469), (559, 472), (208, 469), (27, 452), (62, 391), (24, 288), (83, 153)])
        case 6, 8:
            return Path { path in
                path.move(to: p(150, 64)); path.addQuadCurve(to: p(850, 64), control: p(500, -21))
                path.addLine(to: p(923, 116)); path.addLine(to: p(923, machineBodyY)); path.addLine(to: p(970, machineStepY))
                path.addLine(to: p(970, machineBaseY)); path.addQuadCurve(to: p(30, machineBaseY), control: p(500, machineBaseControlY))
                path.addLine(to: p(30, machineStepY)); path.addLine(to: p(77, machineBodyY)); path.addLine(to: p(77, 116)); path.closeSubpath()
            }
        case 4:
            return polygon([(142, 70), (310, 27), (694, 23), (858, 65), (922, 119), (912, 388), (962, 405), (953, 418), (807, 445), (192, 445), (45, 416), (37, 405), (88, 388), (78, 125)])
        case 7:
            var path = rockCrown
            path.addCurve(to: p(978, 298), control1: p(936, 195), control2: p(959, 245))
            path.addQuadCurve(to: p(922, 405), control: p(1012, 353))
            path.addCurve(to: p(100, 419), control1: p(823, 474), control2: p(214, 464))
            path.addQuadCurve(to: p(25, 301), control: p(5, 390))
            path.addQuadCurve(to: p(98, 130), control: p(47, 194))
            path.closeSubpath()
            return path
        case 9:
            return polygon([(148, 72), (310, 27), (692, 25), (852, 65), (922, 123), (922, 426), (866, 455), (134, 455), (78, 426), (78, 125)])
        case 10:
            return polygon([(142, 70), (310, 27), (694, 23), (858, 65), (922, 119), (912, 340), (962, 371), (953, 418), (807, 445), (192, 445), (45, 416), (37, 371), (88, 339), (78, 125)])
        default:
            var path = rockCrown
            path.addCurve(to: p(963, 339), control1: p(938, 206), control2: p(943, 289))
            // The sides broaden into a load-bearing foot instead of curling
            // back underneath the stone and exposing air above the terrain.
            path.addCurve(to: p(1008, 460), control1: p(976, 390), control2: p(1007, 437))
            appendRockFoot(to: &path)
            path.addCurve(to: p(32, 355), control1: p(2, 446), control2: p(16, 400))
            path.addCurve(to: p(98, 130), control1: p(49, 273), control2: p(69, 172))
            path.closeSubpath()
            return path
        }
    }

    /// This is the actual lower contour, not an ellipse beneath the centre.
    /// Its shadow therefore reaches the feet at both sides as well as the front.
    private var groundEdge: Path {
        switch theme {
        case 3: return curve([(938, 417), (747, 447), (221, 444), (62, 412)])
        case 5: return curve([(1002, 450), (844, 469), (559, 472), (208, 469), (27, 452)])
        case 4, 10: return curve([(953, 418), (807, 445), (192, 445), (45, 416)])
        case 7:
            return Path { path in
                path.move(to: p(922, 405))
                path.addCurve(to: p(100, 419), control1: p(823, 474), control2: p(214, 464))
            }
        case 9: return curve([(922, 426), (866, 455), (134, 455), (78, 426)])
        case 6, 8:
            return Path { path in
                path.move(to: p(970, machineBaseY))
                path.addQuadCurve(to: p(30, machineBaseY), control: p(500, machineBaseControlY))
            }
        default:
            var path = Path(); path.move(to: p(1008, 460))
            appendRockFoot(to: &path)
            return path
        }
    }

    private var top: Path {
        // The cap shares the body's back and shoulder edges. A generic oval leaves
        // exposed wedges on angular stone and disconnected ledges on built podiums.
        switch theme {
        case 3:
            return polygon([(146, 78), (304, 32), (690, 25), (856, 71), (911, 139),
                            (741, 151), (312, 143), (116.48, 119)])
        case 5:
            return polygon([(156, 70), (298, 24), (616, 19), (827, 53), (893, 111),
                            (733, 143), (276, 132), (121.7, 109)])
        case 4, 10:
            return polygon([(142, 70), (310, 27), (694, 23), (858, 65), (922, 119),
                            (809, 133), (192, 133), (78, 125)])
        case 6, 8:
            return Path { path in
                path.move(to: p(150, 64)); path.addQuadCurve(to: p(850, 64), control: p(500, -21))
                path.addLine(to: p(923, 116))
                path.addQuadCurve(to: p(77, 116), control: p(500, 182))
                path.closeSubpath()
            }
        case 9:
            return polygon([(148, 72), (310, 27), (692, 25), (852, 65), (922, 123), (866, 146), (134, 146), (78, 125)])
        default:
            var path = rockCrown
            path.addCurve(to: p(98, 130), control1: p(735, 153), control2: p(285, 157))
            path.closeSubpath()
            return path
        }
    }

    private var topRim: Path {
        switch theme {
        case 3: return curve([(116.48, 119), (312, 143), (741, 151), (911, 139)])
        case 5: return curve([(121.7, 109), (276, 132), (733, 143), (893, 111)])
        case 4, 10: return curve([(78, 125), (192, 133), (809, 133), (922, 119)])
        case 6, 8:
            return Path { path in
                path.move(to: p(77, 116)); path.addQuadCurve(to: p(923, 116), control: p(500, 182))
            }
        case 9: return curve([(78, 125), (134, 146), (866, 146), (922, 123)])
        default:
            return Path { path in
                path.move(to: p(98, 130))
                path.addCurve(to: p(910, 132), control1: p(285, 157), control2: p(735, 153))
            }
        }
    }

    func draw() {
        // The shadow follows the entire ground edge, including the side feet.
        groundShadow()
        context.drawLayer { clipped in
            clipped.clip(to: outline)
            ResultPodiumPainter(context: clipped, palette: palette).body()
        }
        context.drawLayer { ornaments in
            let painter = ResultPodiumPainter(context: ornaments, palette: palette)
            if [1, 2, 4].contains(theme) { painter.moss() }
            if theme == 9 { painter.crateHandles() }
            if theme == 10 { painter.royalDrapes() }
        }
    }

    private func body() {
        fill(outline, palette.face, palette.shade)
        materialDetails()
        if theme != 9 { grain() }
        // Broad reflected light softens the facets without blurring their material edges.
        context.fill(outline, with: .radialGradient(Gradient(colors: [c(palette.light).opacity(0.18), .clear]),
            center: p(338, 151), startRadius: 0, endRadius: 640))
        fill(top, palette.light, mix(palette.light, palette.face, 0.42))
        surfaceDetails()
        // Reflected light along the rim connects the top plane to the body.
        stroke(topRim, palette.light, 3, opacity: 0.7)
        context.fill(outline, with: .linearGradient(Gradient(colors: [.clear, c(palette.edge).opacity(0.12)]),
            startPoint: p(500, 320), endPoint: p(500, 470)))
        if theme == 7 {
            // Wind deposits sand directly into the rock's lowest layers. This
            // belongs to the same silhouette; no separate mound hides a gap.
            let sand: UInt32 = 0xE8C58D
            context.fill(outline, with: .linearGradient(Gradient(colors: [.clear, c(sand).opacity(0.78)]),
                startPoint: p(500, 432), endPoint: p(500, 478)))
        }
    }

    private func groundShadow() {
        context.drawLayer { ground in
            ground.addFilter(.blur(radius: 4))
            ground.stroke(groundEdge.offsetBy(dx: 0, dy: 2), with: .color(c(palette.edge).opacity(0.28)),
                          style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
        }
    }

    private func materialDetails() {
        switch theme {
        case 1, 2: naturalStone()
        case 3: volcanicStone()
        case 4, 10: masonry()
        case 5: quartz()
        case 6, 8: machinery()
        case 7: sandstone()
        case 9: woodenCrate()
        default: break
        }
    }

    private func naturalStone() {
        let facets: [[(CGFloat, CGFloat)]] = [
            [(-60, 520), (-60, 299), (153, 74), (239, 125), (176, 274), (117, 471)],
            [(153, 74), (460, 100), (386, 191), (176, 274), (239, 125)],
            [(176, 274), (386, 191), (430, 520), (117, 471), (-60, 520)],
            [(460, 100), (684, 112), (738, 245), (597, 520), (430, 520), (386, 191)],
            [(684, 112), (848, 78), (919, 209), (738, 245)],
            [(738, 245), (919, 209), (1070, 323), (1070, 520), (597, 520)]
        ]
        for (i, points) in facets.enumerated() {
            let shape = polygon(points), rect = shape.boundingRect
            let lit = mix(palette.light, palette.face, i.isMultiple(of: 2) ? 0.47 : 0.72)
            context.fill(shape, with: .radialGradient(Gradient(stops: [
                .init(color: c(mix(lit, palette.light, 0.15)), location: 0),
                .init(color: c(lit), location: 0.45),
                .init(color: c(mix(palette.face, palette.shade, 0.38)), location: 1)
            ]), center: p(rect.minX + rect.width * 0.36, rect.minY + rect.height * 0.13), startRadius: 0,
                endRadius: max(rect.width, rect.height) * 1.18))
        }
        let seams: [[(CGFloat, CGFloat)]] = [[(239, 125), (176, 274), (113, 358)], [(684, 112), (738, 245), (696, 319)], [(386, 191), (410, 322)]]
        for points in seams {
            line(points, palette.edge, 2, opacity: 0.21)
            line(points.map { ($0.0 + 2, $0.1) }, palette.light, 2, opacity: 0.26)
        }
    }

    private func sandstone() {
        // Every stratum crosses the whole boulder. Adjacent bands use the
        // same boundary, so no base-colour wedges show between the layers.
        for i in 0..<8 {
            let y = CGFloat(104 + i * 48)
            var layer = Path(); layer.move(to: p(-120, y))
            layer.addCurve(to: p(1120, y + 3), control1: p(280, y + 31), control2: p(723, y - 22))
            layer.addLine(to: p(1120, y + 51))
            layer.addCurve(to: p(-120, y + 48), control1: p(723, y + 26), control2: p(280, y + 79))
            layer.closeSubpath()
            fill(layer, mix(palette.light, palette.face, i.isMultiple(of: 2) ? 0.28 : 0.61), mix(palette.face, palette.shade, 0.18))
            var seam = Path(); seam.move(to: p(-120, y))
            seam.addCurve(to: p(1120, y + 3), control1: p(280, y + 31), control2: p(723, y - 22))
            stroke(seam, palette.light, 2, opacity: 0.48)
        }
        if theme == 7 {
            // Wind-cut shelves and an ammonite embedded in the exposed sandstone.
            line([(107, 178), (151, 188), (182, 178)], palette.shade, 3, opacity: 0.28)
            fossil(x: 133, y: 278, radius: 37)
            fossil(x: 870, y: 205, radius: 25)
            // Short erosion seams turn outwards with the solid foot instead
            // of outlining separate rocks behind the podium.
            line([(43, 389), (28, 418), (5, 447)], palette.shade, 2, opacity: 0.22)
            line([(952, 389), (974, 425), (997, 446)], palette.shade, 2, opacity: 0.24)
        }
    }

    private func fossil(x: CGFloat, y: CGFloat, radius: CGFloat) {
        var spiral = Path()
        for i in 0...80 {
            let t = CGFloat(i) / 80, a = t * .pi * 4.6, r = radius * (1 - t * 0.94)
            let at = p(x + cos(a) * r, y + sin(a) * r * 0.8)
            if i == 0 { spiral.move(to: at) } else { spiral.addLine(to: at) }
        }
        stroke(spiral.offsetBy(dx: 1, dy: 2), palette.light, 4, opacity: 0.6)
        stroke(spiral, palette.shade, 3, opacity: 0.5)
    }

    private func woodenCrate() {
        // The lid, side panels and framed front form one timber box.
        fill(polygon([(78, 125), (134, 146), (134, 455), (78, 426)]), 0xC29760, 0x8B603B)
        fill(polygon([(866, 146), (922, 123), (922, 426), (866, 455)]), 0xB88C55, 0x795133)
        fill(polygon([(134, 146), (866, 146), (866, 455), (134, 455)]), 0xD3AB73, 0x9A6B40)
        context.drawLayer { front in
            front.clip(to: Path(CGRect(x: 159, y: 168, width: 682, height: 262)))
            let painter = ResultPodiumPainter(context: front, palette: palette)
            for board in 0..<7 {
                let x = CGFloat(159 + board * 98)
                let rect = CGRect(x: x + 1, y: 168, width: 96, height: 262)
                painter.fill(Path(rect), mix(0xE8C18A, palette.face, 0.20 + Double(board % 3) * 0.12),
                             mix(palette.face, palette.shade, 0.26 + Double(board % 2) * 0.08))
                painter.line([(x + 1, 168), (x + 1, 430)], 0x795333, 2, opacity: 0.65)
                painter.line([(x + 4, 169), (x + 4, 430)], 0xF2D39F, 2, opacity: 0.45)
                painter.woodGrain(in: rect.insetBy(dx: 8, dy: 0), seed: board)
            }
        }
        // Narrow braces stay on the side panels, outside the reward face.
        for right in [false, true] {
            var side = context
            if right { side.translateBy(x: 1000, y: 0); side.scaleBy(x: -1, y: 1) }
            let painter = ResultPodiumPainter(context: side, palette: palette)
            painter.fill(polygon([(84, 159), (96, 164), (128, 397), (116, 390)]), 0xDAB17A, 0x8D603A)
            painter.fill(polygon([(78, 400), (134, 430), (134, 455), (78, 426)]), 0xC99D66, 0x825735)
            for y in [CGFloat(202), 291, 380] {
                painter.line([(81, y), (132, y + 17)], 0x6D4B30, 2, opacity: 0.45)
            }
        }
        for x in [CGFloat(134), 841] {
            let beam = CGRect(x: x, y: 146, width: 25, height: 309)
            fill(Path(beam), 0xE4BC83, 0x9C6D41)
            line([(x + 3, 150), (x + 3, 452)], 0xF8DCAA, 2, opacity: 0.65)
            line([(x + 24, 169), (x + 24, 430)], 0x6D492F, 2, opacity: 0.6)
        }
        for y in [CGFloat(146), 430] {
            fill(Path(CGRect(x: 134, y: y, width: 732, height: y == 146 ? 23 : 25)), 0xE3BA80, 0xAF7D49)
            line([(138, y + 2), (862, y + 2)], 0xF7D8A3, 2, opacity: 0.75)
            line([(159, y + 22), (841, y + 22)], 0x785031, 2, opacity: 0.45)
        }
        for x in [CGFloat(147), 853] {
            for y in [CGFloat(183), 414] {
                let bracket = Path(roundedRect: CGRect(x: x - 7, y: y, width: 14, height: 22), cornerRadius: 3)
                fill(bracket, 0xDDC489, 0x987744)
                rivet(x, y + 10, radius: 3)
            }
        }
    }

    private func woodGrain(in rect: CGRect, seed: Int) {
        for i in 0..<6 {
            let x = rect.minX + CGFloat(i + 1) * rect.width / 7
            var grain = Path(); grain.move(to: p(x, rect.minY - 5))
            grain.addCurve(to: p(x + CGFloat((i + seed) % 3 - 1) * 5, rect.maxY + 5),
                           control1: p(x - 8 + CGFloat(seed % 3) * 3, rect.minY + 75),
                           control2: p(x + 9, rect.maxY - 75))
            stroke(grain, i.isMultiple(of: 2) ? 0x815533 : 0xF3D29A, i.isMultiple(of: 3) ? 1.8 : 1, opacity: 0.24)
        }
        if seed.isMultiple(of: 2) {
            let x = rect.midX + CGFloat(seed % 3 - 1) * 8
            let y = rect.minY + CGFloat(71 + (seed * 31) % 139)
            stroke(Path(ellipseIn: CGRect(x: x - 5, y: y - 12, width: 10, height: 24)), 0x865837, 1.5, opacity: 0.45)
            stroke(Path(ellipseIn: CGRect(x: x - 9, y: y - 18, width: 18, height: 36)), 0xEFCB93, 1, opacity: 0.4)
        }
    }

    private func volcanicStone() {
        for i in 0..<9 {
            let x = CGFloat(i) * 124 - 50, crown = CGFloat([135, 108, 145][i % 3])
            fill(polygon([(x, crown), (x + 65, crown - 24), (x + 124, crown), (x + 113, 460), (x + 9, 460)]),
                 mix(palette.light, palette.face, i.isMultiple(of: 2) ? 0.45 : 0.8), mix(palette.face, palette.shade, 0.72))
            line([(x + 65, crown - 24), (x + 68, 239), (x + 59, 445)], palette.edge, 3, opacity: 0.4)
            line([(x + 68, crown + 10), (x + 70, 216)], palette.light, 2, opacity: 0.28)
        }
        let fissures: [[(CGFloat, CGFloat)]] = [[(72, 177), (116, 223), (88, 290), (137, 349), (125, 418)],
                       [(902, 133), (875, 210), (916, 277), (877, 333), (906, 418)],
                       [(285, 431), (372, 417), (451, 439), (566, 426), (692, 444)]]
        for points in fissures {
            stroke(curve(points), 0xF47F43, 14, opacity: 0.12)
            stroke(curve(points), 0xD56B47, 6, opacity: 0.9)
            stroke(curve(points), 0xFFD492, 2.2, opacity: 0.95)
        }
    }

    private func quartz() {
        let faces: [[(CGFloat, CGFloat)]] = [
            [(-40, 520), (-20, 288), (157, 71), (276, 121), (209, 313), (137, 472)],
            [(157, 71), (480, 41), (407, 179), (276, 121)],
            [(276, 121), (407, 179), (385, 520), (137, 472), (209, 313)],
            [(480, 41), (724, 93), (671, 254), (529, 520), (385, 520), (407, 179)],
            [(724, 93), (831, 54), (981, 256), (831, 302), (671, 254)],
            [(831, 302), (981, 256), (1050, 382), (1050, 520), (529, 520), (671, 254)]
        ]
        for (i, points) in faces.enumerated() {
            let tint = i == 2 || i == 4 ? palette.accent : palette.light
            fill(polygon(points), mix(tint, palette.face, 0.22 + Double(i % 3) * 0.18), mix(palette.face, palette.shade, 0.40))
        }
        let veins: [[(CGFloat, CGFloat)]] = [[(157, 71), (276, 121), (209, 313), (137, 472)], [(831, 54), (724, 93), (831, 302), (874, 466)]]
        for points in veins {
            line(points, 0xD7FFF4, 3.2, opacity: 0.8)
        }
        for (x, y) in [(115.0, 251.0), (868, 187), (881, 353)] { sparkle(x, y, 12, 0xE6FFF6) }
    }

    private func masonry() {
        for row in 0..<4 {
            let y = CGFloat(109 + row * 77)
            let shift: CGFloat = row.isMultiple(of: 2) ? -96 : 19
            for col in 0..<6 {
                let x = shift + CGFloat(col) * 201
                let rect = CGRect(x: x + 3, y: y + 3, width: 194, height: 70)
                let path = Path(roundedRect: rect, cornerRadius: theme == 4 ? 12 : 4)
                let top = mix(palette.light, palette.face, Double((col + row * 3) % 4) * 0.10 + 0.25)
                fill(path, top, mix(palette.face, palette.shade, 0.30))
                line([(rect.minX + 10, rect.minY + 3), (rect.maxX - 11, rect.minY + 3)], palette.light, 2, opacity: 0.6)
            }
        }
        // Both bevels follow the complete stepped silhouette, including its
        // shoulders. No untextured corner triangles remain beside the blocks.
        let bodyY: CGFloat = theme == 4 ? 388 : 340
        let bevelY: CGFloat = theme == 4 ? 414 : 365
        let stepY: CGFloat = theme == 4 ? 405 : 371
        let frontY: CGFloat = theme == 4 ? 426 : 398
        let bevel = polygon([(88, bodyY), (192, bevelY), (807, bevelY), (912, bodyY),
                             (962, stepY), (812, frontY), (187, frontY), (37, stepY)])
        fill(bevel, mix(palette.light, palette.face, 0.28), palette.face)
        line([(37, stepY), (187, frontY), (812, frontY), (962, stepY)], palette.light, 3, opacity: 0.7)
        let step = polygon([(37, stepY), (187, frontY), (812, frontY), (962, stepY),
                            (953, 418), (807, 445), (192, 445), (45, 416)])
        fill(step, palette.light, palette.shade)
        for x in [CGFloat(192), 396, 604, 807] {
            line([(x, frontY + 5), (x, 444)], palette.edge, 1.5, opacity: 0.22)
        }
        line([(49, 413), (194, 440), (805, 440), (949, 415)], theme == 10 ? palette.accent : palette.light, 3, opacity: 0.75)
        // A dressed cornice and its shadow make this a built plinth, rather than a tinted boulder.
        fill(polygon([(81, 100), (198, 112), (809, 112), (922, 100), (924, 122), (811, 133), (192, 133), (78, 122)]), palette.light, palette.face)
        line([(94, 126), (205, 137), (801, 137), (910, 126)], palette.edge, 4, opacity: 0.25)
    }

    private func machinery() {
        // Stepped footing, curved front, inset service panels and machined edge bands.
        let footing = Path { path in
            path.move(to: p(77, machineBodyY))
            path.addQuadCurve(to: p(923, machineBodyY), control: p(500, machineBodyY + 66))
            path.addLine(to: p(970, machineStepY)); path.addLine(to: p(970, machineBaseY))
            path.addQuadCurve(to: p(30, machineBaseY), control: p(500, machineBaseControlY))
            path.addLine(to: p(30, machineStepY)); path.closeSubpath()
        }
        fill(footing, mix(palette.light, palette.face, 0.34), palette.shade)
        for x in [CGFloat(66), 874] {
            let path = Path(roundedRect: CGRect(x: x, y: 164, width: 60, height: 176), cornerRadius: 17)
            fill(path, palette.shade, palette.edge)
            stroke(path, palette.light, 2, opacity: 0.5)
            if theme == 6 {
                for i in 0..<6 { line([(x + 13, CGFloat(196 + i * 23)), (x + 47, CGFloat(196 + i * 23))], palette.face, 5, opacity: 0.85) }
            } else {
                for i in 0..<3 { oval(x + CGFloat(16 + i * 14), 295, 5, 5, palette.accent, opacity: 0.9) }
            }
        }
        if theme == 6 { machineBands() }
        for x in [CGFloat(111), 218, 782, 889] { for y in [CGFloat(153), machineBodyY + 16] { rivet(x, y, radius: 6) } }
        if theme == 8 {
            for x in [CGFloat(260), 740] { line([(x, 163), (x, 192)], palette.light, 3, opacity: 0.6) }
        } else {
            // Art deco sun lines on the city's architectural podium.
            for right in [false, true] {
                let x: CGFloat = right ? 867 : 133, sign: CGFloat = right ? -1 : 1
                for i in 0..<3 { line([(x, 108), (x + sign * CGFloat(24 + i * 16), 139)], palette.light, 3, opacity: 0.7) }
            }
        }
    }

    private func machineBands() {
        var footRim = Path(); footRim.move(to: p(30, machineStepY))
        footRim.addQuadCurve(to: p(970, machineStepY), control: p(500, machineStepY + 85))
        for band in [topRim.offsetBy(dx: 0, dy: 5), footRim] {
            stroke(band, palette.edge, 11, opacity: 0.6)
            stroke(band.offsetBy(dx: 0, dy: -3), palette.light, 6, opacity: 0.85)
            if theme == 8 { stroke(band.offsetBy(dx: 0, dy: 4), palette.accent, 2.5, opacity: 0.75) }
        }
        var lowerRim = Path(); lowerRim.move(to: p(36, machineBaseY - 4))
        lowerRim.addQuadCurve(to: p(964, machineBaseY - 4), control: p(500, machineBaseControlY - 5))
        stroke(lowerRim, palette.light, 3, opacity: 0.55)
    }

    private func surfaceDetails() {
        context.drawLayer { layer in
            layer.clip(to: top)
            let painter = ResultPodiumPainter(context: layer, palette: palette)
            switch theme {
            case 6, 8:
                // Elliptical calibration ring follows the standing plane's perspective.
                let ring = Path(ellipseIn: CGRect(x: 174, y: 30, width: 652, height: 99))
                painter.stroke(ring, palette.shade, 2, opacity: 0.48)
                for i in 0..<25 {
                    let a = CGFloat(i) / 24 * .pi
                    let x = 500 + cos(a) * 311, y = 79 + sin(a) * 43
                    painter.line([(x, y), (x - cos(a) * 12, y - sin(a) * 3)], palette.edge, i.isMultiple(of: 4) ? 3 : 1.5, opacity: 0.55)
                }
            case 9:
                painter.fill(top, 0xEFD09A, 0xC3975F)
                for i in 0..<9 {
                    let x = CGFloat(155 + i * 86)
                    painter.line([(x, 10), (x - 21, 160)], 0x8D704E, 3, opacity: 0.55)
                    painter.line([(x + 4, 10), (x - 17, 160)], 0xFFE7B0, 2, opacity: 0.55)
                    painter.line([(x + 20, 56), (x + 15, 99)], 0x9B7D54, 1, opacity: 0.4)
                    painter.rivet(x + 37, 103, radius: 3)
                }
            case 4, 10:
                for x in [CGFloat(270), 495, 720] { painter.line([(x, 15), (x - 17, 120)], palette.shade, 2, opacity: 0.35) }
            case 3:
                for i in 0..<18 {
                    let x = CGFloat(173 + (i * 97) % 650), y = CGFloat(37 + (i * 23) % 64)
                    painter.oval(x, y, CGFloat(5 + i % 4), 3, palette.edge, opacity: 0.20)
                }
            default:
                layer.drawLayer { mottled in
                    mottled.addFilter(.blur(radius: 5))
                    for i in 0..<9 {
                        let x = CGFloat(177 + (i * 113) % 661), y = CGFloat(38 + (i * 29) % 55)
                        let rect = CGRect(x: x - 35, y: y - 5, width: CGFloat(46 + i % 4 * 13), height: 12)
                        mottled.fill(Path(ellipseIn: rect), with: .color(c(i.isMultiple(of: 2) ? palette.light : palette.face).opacity(0.13)))
                    }
                }
                for i in 0..<20 {
                    let x = CGFloat(178 + (i * 113) % 661), y = CGFloat(36 + (i * 29) % 68)
                    painter.oval(x, y, CGFloat(6 + i % 8), 2, palette.shade, opacity: 0.14)
                }
            }
        }
    }

    private func grain() {
        for i in 0..<160 {
            let x = CGFloat((i * 173 + 51) % 997), y = CGFloat(119 + (i * 83) % 359)
            oval(x, y, CGFloat(1 + i % 4), CGFloat(1 + i % 2), i.isMultiple(of: 3) ? palette.light : palette.edge, opacity: 0.12)
        }
    }

    private func rivet(_ x: CGFloat, _ y: CGFloat, radius: CGFloat) {
        oval(x, y + 2, radius * 2.3, radius * 2.3, palette.edge, opacity: 0.7)
        fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)), palette.light, palette.shade)
        line([(x - radius * 0.4, y + radius * 0.25), (x + radius * 0.4, y - radius * 0.25)], palette.edge, 1.3, opacity: 0.7)
    }

    private func gauge(_ x: CGFloat, _ y: CGFloat, radius: CGFloat) {
        oval(x, y, radius * 2.2, radius * 2.2, palette.light)
        oval(x, y, radius * 1.85, radius * 1.85, palette.edge)
        oval(x, y, radius * 1.58, radius * 1.58, 0xE1E5CB)
        for i in 0..<8 {
            let a = CGFloat(i) * .pi / 5 + .pi * 0.8
            line([(x + cos(a) * radius * 0.61, y + sin(a) * radius * 0.61), (x + cos(a) * radius * 0.70, y + sin(a) * radius * 0.70)], palette.edge, 1.5)
        }
        line([(x, y), (x + radius * 0.40, y - radius * 0.29)], 0xB97852, 3)
        oval(x, y, 5, 5, palette.edge)
    }

    private var foliageColors: (light: UInt32, face: UInt32, shade: UInt32) {
        switch theme {
        case 2: return (0xB5DACA, 0x6DAA92, 0x356F70)
        case 4: return (0xC4DB83, 0x79A34F, 0x3F7043)
        default: return (0xC5EA59, 0x65A43D, 0x285E38)
        }
    }

    private func moss() {
        let colors = foliageColors
        for right in [false, true] {
            var art = context
            if right { art.translateBy(x: 1000, y: 0); art.scaleBy(x: -1, y: 1) }
            if theme == 4 {
                art.translateBy(x: right ? 12 : 0, y: 27)
                art.scaleBy(x: right ? 0.88 : 1, y: 0.58)
            } else {
                // Wrap growth down the outer shoulder, leaving the standing
                // plane open beside Dino's feet. Both texture and tips follow it.
                art.concatenate(CGAffineTransform(a: right ? 0.69 : 0.72, b: -0.25,
                    c: 0, d: theme == 2 ? 0.90 : 1.08, tx: right ? 20 : 12,
                    ty: theme == 2 ? 121 : 102))
            }
            var cap = Path(); cap.move(to: p(126, 98))
            cap.addCurve(to: p(167, 73), control1: p(130, 84), control2: p(149, 72))
            cap.addCurve(to: p(211, 69), control1: p(180, 64), control2: p(196, 65))
            cap.addCurve(to: p(251, 78), control1: p(225, 65), control2: p(244, 71))
            cap.addCurve(to: p(283, 84), control1: p(261, 73), control2: p(277, 78))
            cap.addCurve(to: p(316, 97), control1: p(297, 81), control2: p(316, 87))
            cap.addCurve(to: p(301, 111), control1: p(330, 103), control2: p(315, 112))
            cap.addQuadCurve(to: p(282, 116), control: p(293, 121))
            cap.addQuadCurve(to: p(265, 113), control: p(272, 121))
            cap.addQuadCurve(to: p(244, 121), control: p(253, 127))
            cap.addQuadCurve(to: p(225, 121), control: p(233, 117))
            cap.addQuadCurve(to: p(207, 129), control: p(216, 136))
            cap.addQuadCurve(to: p(188, 127), control: p(196, 121))
            cap.addQuadCurve(to: p(172, 134), control: p(181, 139))
            cap.addQuadCurve(to: p(154, 133), control: p(163, 128))
            cap.addQuadCurve(to: p(138, 141), control: p(148, 148))
            cap.addQuadCurve(to: p(123, 132), control: p(123, 146))
            cap.addQuadCurve(to: p(118, 115), control: p(112, 127))
            cap.addQuadCurve(to: p(126, 98), control: p(117, 105))
            cap.closeSubpath()
            art.drawLayer { shadow in
                shadow.addFilter(.shadow(color: c(colors.shade).opacity(0.27), radius: 3, y: 3))
                shadow.fill(cap, with: .color(c(colors.shade)))
            }
            let painter = ResultPodiumPainter(context: art, palette: palette)
            painter.fill(cap, mix(colors.light, colors.face, 0.68), mix(colors.face, colors.shade, 0.42))
            art.drawLayer { colony in
                colony.clip(to: cap)
                let detail = ResultPodiumPainter(context: colony, palette: palette)
                func variation(_ index: Int, _ salt: Int) -> CGFloat {
                    var value = UInt64(index + salt + (right ? 137 : 0))
                    value = (value ^ (value >> 16)) &* 0x45D9F3B
                    value = (value ^ (value >> 16)) &* 0x45D9F3B
                    return CGFloat((value ^ (value >> 16)) & 65535) / 65535
                }
                // Uneven cushions merge into one soft colony, with fine leafy shoots on top.
                // Independent positions and sizes avoid rows or a tiled surface.
                for i in 0..<48 {
                    let x = 115 + variation(i, 9187) * 215
                    let y = 65 + variation(i, 3721) * 80
                    detail.mossCushion(x: x, y: y, size: 11 + variation(i, 6727) * 18, colors: colors)
                }
                for i in 0..<170 {
                    let x = 116 + variation(i, 9137) * 215
                    let y = 65 + variation(i, 2341) * 80
                    let length = 3 + variation(i, 7867) * 5
                    detail.mossShoot(x: x, y: y, length: length,
                                     angle: Double(variation(i, 4231) * 100 - 50),
                                     light: mix(colors.light, colors.face, 0.35 + Double(variation(i, 3359)) * 0.4),
                                     shade: mix(colors.face, colors.shade, 0.12))
                }
            }
            // Fine tips break the colony's silhouette without big scalloped drips.
            for (i, point) in [(136.0, 95.0), (157, 77), (184, 70), (214, 70), (240, 76),
                               (268, 81), (295, 89), (149, 133), (177, 131), (204, 127),
                               (232, 120), (261, 115), (289, 112)].enumerated() {
                let angle: Double = i < 7 ? Double(-28 + i % 3 * 21) : Double(130 + i % 3 * 17)
                painter.mossShoot(x: point.0, y: point.1, length: CGFloat(7 + i % 4), angle: angle,
                                  light: colors.light, shade: colors.face)
            }
        }
    }

    private func mossCushion(x: CGFloat, y: CGFloat, size: CGFloat,
                             colors: (light: UInt32, face: UInt32, shade: UInt32)) {
        // The flat oval is a lighting footprint in the moss's perspective, with a clear edge.
        var art = context
        art.translateBy(x: x, y: y); art.scaleBy(x: size, y: size * 0.50)
        art.fill(Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2)),
                 with: .radialGradient(Gradient(colors: [
                    c(mix(colors.light, colors.face, 0.60)).opacity(0.65),
                    c(colors.face).opacity(0.15), .clear
                 ]), center: p(-0.16, -0.25), startRadius: 0, endRadius: 1))
    }

    private func mossShoot(x: CGFloat, y: CGFloat, length: CGFloat, angle: Double,
                           light: UInt32, shade: UInt32) {
        var art = context; art.translateBy(x: x, y: y); art.rotate(by: .degrees(angle))
        var shoot = Path(); shoot.move(to: .zero)
        shoot.addQuadCurve(to: p(length * 0.12, -length), control: p(-length * 0.40, -length * 0.52))
        shoot.addQuadCurve(to: .zero, control: p(length * 0.50, -length * 0.42)); shoot.closeSubpath()
        art.fill(shoot, with: .linearGradient(Gradient(colors: [c(light), c(shade)]),
                                             startPoint: p(0, -length), endPoint: .zero))
    }

    private func leaf(x: CGFloat, y: CGFloat, length: CGFloat, angle: Double) {
        var art = context; art.translateBy(x: x, y: y); art.rotate(by: .degrees(angle))
        let width = length * 0.47
        let bounds = CGRect(x: 0, y: 0, width: width, height: length)
        let shape = DinoFoliageLeaf().path(in: bounds).offsetBy(dx: -width / 2, dy: -length)
        let fold = DinoFoliageFold().path(in: bounds).offsetBy(dx: -width / 2, dy: -length)
        let veins = DinoFoliageVeins().path(in: bounds).offsetBy(dx: -width / 2, dy: -length)
        let colors = foliageColors
        art.drawLayer { shadow in
            shadow.addFilter(.shadow(color: c(colors.shade).opacity(0.25), radius: 1.5, x: 1.5, y: 2))
            shadow.fill(shape, with: .color(c(colors.shade)))
        }
        art.fill(shape, with: .linearGradient(Gradient(stops: [
            .init(color: c(colors.shade), location: 0), .init(color: c(colors.face), location: 0.24),
            .init(color: c(colors.light), location: 0.49), .init(color: c(colors.face), location: 0.76),
            .init(color: c(colors.shade), location: 1)
        ]), startPoint: p(-width / 2, -length * 0.65), endPoint: p(width / 2, -length * 0.45)))
        art.fill(fold, with: .color(c(colors.shade).opacity(0.15)))
        art.stroke(veins, with: .color(c(colors.light).opacity(0.48)),
                   style: StrokeStyle(lineWidth: max(0.7, length * 0.008), lineCap: .round))
    }

    private func crateHandles() {
        for right in [false, true] {
            let x: CGFloat = right ? 895 : 105
            var handle = Path(); handle.move(to: p(x, 220))
            handle.addCurve(to: p(x, 291), control1: p(x + (right ? 19 : -19), 226), control2: p(x + (right ? 19 : -19), 282))
            stroke(handle.offsetBy(dx: 1, dy: 3), 0x68492F, 10, opacity: 0.45)
            stroke(handle, 0xDCC28D, 8)
            stroke(handle.offsetBy(dx: right ? 1 : -1, dy: -1), 0xF7DFAB, 2, opacity: 0.7)
            for y in [CGFloat(220), 291] {
                oval(x, y, 16, 12, 0x725034)
                oval(x, y - 1, 10, 7, 0xD1AE6D)
            }
        }
    }

    private func royalDrapes() {
        for right in [false, true] {
            let x: CGFloat = right ? 888 : 112
            let flag = polygon([(x - 27, 136), (x + 27, 140), (x + 27, 322), (x, 301), (x - 27, 325)])
            fill(flag, 0x8EAED3, 0x385C90)
            line([(x - 21, 147), (x - 21, 312), (x, 291), (x + 21, 311), (x + 21, 150)], 0xE1C17D, 2)
            line([(x + 10, 149), (x + 10, 303)], 0xD4E0E7, 5, opacity: 0.14)
            fill(polygon([(x - 15, 240), (x - 18, 215), (x - 6, 224), (x, 209),
                          (x + 6, 224), (x + 18, 215), (x + 15, 240)]), 0xFFE4A0, 0xC49A52)
            line([(x - 31, 136), (x + 31, 140)], palette.accent, 5)
        }
    }

    func surround(foreground: Bool) {
        if foreground {
            if theme == 5 || theme == 8 {
                if theme == 8 { machineBands() }
                for right in [false, true] {
                    var art = context
                    if right { art.translateBy(x: 1000, y: 0); art.scaleBy(x: -1, y: 1) }
                    ResultPodiumPainter(context: art, palette: palette).shoulder(right: right)
                }
            }
            if theme == 7 { desertSand(foreground: true) }
            groundFinish()
            return
        }
        if theme == 7 { desertSand(foreground: false) }
        if theme == 5 || theme == 8 { return }
        for right in [false, true] {
            var art = context
            if right { art.translateBy(x: 1000, y: 0); art.scaleBy(x: -1, y: 1) }
            let painter = ResultPodiumPainter(context: art, palette: palette)
            painter.shoulder(right: right)
        }
    }

    private func shoulder(right: Bool) {
        switch theme {
        case 1: break
        case 2:
            mushroom(44, 466, height: right ? 128 : 154)
            mushroom(14, 471, height: 82)
        case 3:
            column(48, 413, width: 100, height: right ? 246 : 216)
            column(-15, 440, width: 76, height: 131)
            glow(61, 401, 73, 0xFF9D58, opacity: 0.20)
        case 4:
            planter(48, 408, width: 132)
            if !right { lantern(58, 278, height: 148, metal: false) }
        case 5:
            crystal(64, 474, height: right ? 226 : 192, purple: right)
            crystal(6, 479, height: 119, purple: !right)
        case 6:
            lantern(52, 422, height: right ? 231 : 252, metal: true)
            fill(polygon([(-8, 429), (23, 407), (82, 407), (112, 429), (100, 446), (2, 446)]), palette.light, palette.shade)
        case 7:
            desertSprig(-38, 436, height: right ? 87 : 105)
        case 8:
            pipe([(22, 422), (22, 284), (83, 260), (83, 159)])
            gear(52, 351, radius: right ? 69 : 83)
            gauge(79, 194, radius: 36)
            glow(84, 151, 28, palette.accent, opacity: 0.23)
        case 9:
            // Mooring posts stand outside the solid foot, so their shafts and
            // roots do not disappear halfway through a widening stone wall.
            line([(-18, 469), (-18, 255)], 0x6A6552, 33)
            line([(-25, 466), (-25, 256)], 0xBB9D6A, 23)
            for y in [CGFloat(272), 284, 299] { line([(-38, y), (-4, y + 5)], 0xE3D1A3, 7) }
            oval(-18, 253, 38, 14, 0xDCC18D)
            shell(-35, 473, radius: 29)
        case 10: break
        default: break
        }
    }

    private func desertSand(foreground: Bool) {
        // One continuous dune surrounds the round boulder. Its rear shoulders
        // support the curved sides, while the front buries the lowest stone edge.
        var dune = Path()
        if foreground {
            dune.move(to: p(-95, 487))
            dune.addCurve(to: p(104, 395), control1: p(-15, 453), control2: p(39, 396))
            dune.addCurve(to: p(500, 443), control1: p(193, 414), control2: p(347, 448))
            dune.addCurve(to: p(920, 391), control1: p(674, 448), control2: p(829, 413))
            dune.addCurve(to: p(1090, 485), control1: p(989, 396), control2: p(1031, 462))
        } else {
            dune.move(to: p(-95, 487))
            dune.addCurve(to: p(25, 356), control1: p(-60, 428), control2: p(-12, 366))
            dune.addCurve(to: p(500, 428), control1: p(215, 354), control2: p(245, 414))
            dune.addCurve(to: p(978, 359), control1: p(750, 424), control2: p(850, 360))
            dune.addCurve(to: p(1090, 485), control1: p(1032, 377), control2: p(1073, 451))
        }
        dune.addCurve(to: p(-95, 487), control1: p(817, 516), control2: p(209, 518))
        dune.closeSubpath()
        context.fill(dune, with: .linearGradient(Gradient(stops: [
            .init(color: c(foreground ? 0xF2D59F : 0xE8C78C), location: 0),
            .init(color: c(0xEFD29D).opacity(0.95), location: 0.52),
            .init(color: c(0xEFD29D).opacity(0.5), location: 0.83),
            .init(color: .clear, location: 1)
        ]), startPoint: p(500, foreground ? 395 : 356), endPoint: p(500, 510)))
        if foreground {
            var ridge = Path(); ridge.move(to: p(-41, 461))
            ridge.addCurve(to: p(103, 402), control1: p(21, 435), control2: p(54, 401))
            ridge.addCurve(to: p(368, 448), control1: p(175, 425), control2: p(270, 445))
            stroke(ridge, 0xFFE7B5, 2, opacity: 0.6)
            var rightRidge = Path(); rightRidge.move(to: p(696, 445))
            rightRidge.addCurve(to: p(922, 399), control1: p(799, 436), control2: p(862, 409))
            rightRidge.addCurve(to: p(1036, 461), control1: p(969, 414), control2: p(1009, 447))
            stroke(rightRidge, 0xFFE7B5, 2, opacity: 0.5)
            context.drawLayer { sand in
                sand.clip(to: dune)
                let painter = ResultPodiumPainter(context: sand, palette: palette)
                for i in 0..<110 {
                    let x = CGFloat((i * 173 + 21) % 1080) - 40
                    let y = CGFloat(434 + (i * 29) % 64)
                    painter.oval(x, y, CGFloat(1 + i % 3), 1.2, i.isMultiple(of: 3) ? 0xFFF0C3 : 0xB99765,
                                 opacity: Double(510 - y) / 450)
                }
            }
        }
    }

    private func groundFinish() {
        // Small details overlap the foot of the podium, leaving the reward row clear.
        for right in [false, true] {
            var art = context
            if right { art.translateBy(x: 1000, y: 0); art.scaleBy(x: -1, y: 1) }
            let painter = ResultPodiumPainter(context: art, palette: palette)
            art.drawLayer { shadow in
                shadow.addFilter(.blur(radius: 8))
                let y: CGFloat = [1, 2, 5, 7, 9].contains(theme) ? 466 : 436
                shadow.fill(Path(ellipseIn: CGRect(x: -2, y: y, width: 191, height: 22)),
                            with: .color(c(palette.edge).opacity(0.10)))
            }
            switch theme {
            case 1:
                // The jungle's foreground already supplies the detailed, rooted leaf clusters.
                painter.pebble(206, 479, width: 33)
            case 2:
                painter.mushroom(60, 478, height: right ? 112 : 128)
                painter.mushroom(125, 482, height: 68)
                for i in 0..<4 { painter.glow(CGFloat(26 + i * 40), CGFloat(377 + (i * 29) % 65), 6, 0xDCF3B5, opacity: 0.8) }
            case 3:
                painter.column(110, 452, width: 72, height: 68); painter.pebble(190, 451, width: 39)
            case 4:
                painter.flower(63, 450, height: 45, pink: true); painter.flower(105, 458, height: 37, pink: false)
                painter.pebble(185, 452, width: 33)
            case 5:
                painter.crystal(93, 478, height: 67, purple: !right)
                painter.pebble(172, 479, width: 38)
            case 6:
                for i in 0..<3 {
                    painter.fill(Path(roundedRect: CGRect(x: CGFloat(58 + i * 37), y: CGFloat(445 + i * 3), width: 28, height: 9), cornerRadius: 3), palette.light, palette.face)
                }
            case 7:
                painter.desertSprig(98, 474, height: 47); painter.pebble(185, 479, width: 42)
            case 8:
                painter.gear(104, 451, radius: 34); painter.rivet(178, 459, radius: 7)
            case 9:
                painter.shell(98, 474, radius: 28); painter.shell(173, 482, radius: 18)
            case 10:
                painter.pebble(109, 453, width: 51)
                painter.fill(Path(roundedRect: CGRect(x: 158, y: 433, width: 43, height: 24), cornerRadius: 4), palette.light, palette.shade)
            default: break
            }
        }
    }

    private func pebble(_ x: CGFloat, _ y: CGFloat, width: CGFloat) {
        fill(polygon([(x - width / 2, y), (x - width * 0.36, y - width * 0.34), (x + width * 0.09, y - width * 0.49), (x + width * 0.48, y - width * 0.19), (x + width * 0.39, y + 4)]), palette.light, palette.shade)
    }

    private func column(_ x: CGFloat, _ y: CGFloat, width: CGFloat, height: CGFloat) {
        fill(polygon([(x - width / 2, y), (x - width * 0.48, y - height * 0.85), (x - width * 0.05, y - height), (x + width / 2, y - height * 0.87), (x + width * 0.48, y)]), 0x827B8A, 0x343443)
        fill(polygon([(x - width * 0.05, y - height), (x + width / 2, y - height * 0.87), (x + width * 0.48, y), (x + width * 0.06, y)]), 0x625B6D, 0x2D3040)
        line([(x - width * 0.05, y - height + 7), (x + width * 0.06, y - 12)], 0xA59AA6, 2, opacity: 0.55)
    }

    private func crystal(_ x: CGFloat, _ y: CGFloat, height: CGFloat, purple: Bool) {
        let width = height * 0.38
        let shape = polygon([(x - width / 2, y), (x - width * 0.57, y - height * 0.76), (x - width * 0.08, y - height), (x + width * 0.45, y - height * 0.80), (x + width / 2, y - height * 0.04)])
        fill(shape, purple ? 0xE3D7FF : 0xD6FFF3, purple ? 0x827DBA : 0x559EB7)
        fill(polygon([(x - width * 0.08, y - height), (x + width * 0.45, y - height * 0.80), (x + width / 2, y - height * 0.04), (x + width * 0.05, y - 7)]), purple ? 0xB4A5E2 : 0x8DDEDE, purple ? 0x6B6BA3 : 0x47849F)
        line([(x - width * 0.08, y - height + 5), (x + width * 0.05, y - 9)], 0xEBFFF7, 3, opacity: 0.85)
        line([(x - width * 0.46, y - height * 0.75), (x - width * 0.08, y - height + 5), (x + width * 0.37, y - height * 0.79)], 0xF7FFFF, 2, opacity: 0.7)
        sparkle(x - width * 0.08, y - height + 8, 9, 0xF1FFF6)
    }

    private func mushroom(_ x: CGFloat, _ y: CGFloat, height: CGFloat) {
        glow(x, y - height * 0.6, height, 0xB0E4D0, opacity: 0.15)
        line([(x, y), (x + height * 0.02, y - height * 0.61)], 0xB4CDBC, height * 0.14)
        var cap = Path(); cap.move(to: p(x - height * 0.48, y - height * 0.60))
        cap.addQuadCurve(to: p(x + height * 0.48, y - height * 0.60), control: p(x, y - height * 1.43))
        cap.addQuadCurve(to: p(x - height * 0.48, y - height * 0.60), control: p(x, y - height * 0.38)); cap.closeSubpath()
        fill(cap, 0xDBF0D7, 0x73A7A8)
        oval(x, y - height * 0.59, height * 0.85, height * 0.12, 0xCDEED2)
        for i in 0..<3 { oval(x + CGFloat(i - 1) * height * 0.19, y - height * (i == 1 ? 0.91 : 0.76), height * 0.09, height * 0.065, 0xEBF8DA, opacity: 0.8) }
    }

    private func planter(_ x: CGFloat, _ y: CGFloat, width: CGFloat) {
        fill(polygon([(x - width / 2, y - 55), (x + width / 2, y - 55), (x + width * 0.38, y), (x - width * 0.38, y)]), 0xDCA47E, 0x9C6D53)
        line([(x - width * 0.49, y - 49), (x + width * 0.49, y - 49)], 0xF0BC8F, 9)
        for i in 0..<5 { flower(x + CGFloat(i - 2) * width * 0.19, y - 50, height: CGFloat(50 + (i * 19) % 37), pink: i.isMultiple(of: 2)) }
    }

    private func flower(_ x: CGFloat, _ y: CGFloat, height: CGFloat, pink: Bool) {
        line([(x, y), (x + 3, y - height)], 0x5E8A53, 3)
        leaf(x: x, y: y - height * 0.33, length: height * 0.45, angle: -62)
        for i in 0..<5 {
            let a = CGFloat(i) * .pi * 2 / 5
            oval(x + 3 + cos(a) * 8, y - height + sin(a) * 8, 14, 14, pink ? 0xF0AAA4 : 0xF8E3A1)
        }
        oval(x + 3, y - height, 8, 8, 0xE7BA63)
    }

    private func lantern(_ x: CGFloat, _ y: CGFloat, height: CGFloat, metal: Bool) {
        let ink: UInt32 = metal ? 0x42677D : 0x6E725B
        line([(x, y), (x, y - height)], ink, 8)
        oval(x, y, 43, 13, ink)
        let top = y - height
        glow(x, top + 16, 50, 0xFFF2BA, opacity: 0.2)
        fill(polygon([(x - 21, top), (x + 21, top), (x + 15, top + 47), (x - 15, top + 47)]), 0xFFF6CE, 0xD2C98A)
        line([(x - 21, top), (x - 15, top + 47), (x + 15, top + 47), (x + 21, top)], ink, 4)
        fill(polygon([(x - 29, top), (x, top - 24), (x + 29, top)]), metal ? 0x9FC7CA : 0xACB38B, ink)
        oval(x, top - 26, 10, 10, palette.light)
    }

    private func desertSprig(_ x: CGFloat, _ y: CGFloat, height: CGFloat) {
        for i in 0..<6 {
            var blade = Path(); blade.move(to: p(x, y))
            let tipX = x + CGFloat(i - 3) * height * 0.19, tipY = y - height * (i.isMultiple(of: 2) ? 0.67 : 1)
            blade.addQuadCurve(to: p(tipX, tipY), control: p(x + CGFloat(i - 3) * 8, y - height * 0.6))
            blade.addQuadCurve(to: p(x + 6, y), control: p(x + CGFloat(i - 3) * 13 + 12, y - height * 0.4)); blade.closeSubpath()
            fill(blade, 0xCED19A, 0x8F9C68)
        }
    }

    private func pipe(_ points: [(CGFloat, CGFloat)]) {
        line(points, palette.edge, 25); line(points, 0xB78F66, 18); line(points.map { ($0.0 - 3, $0.1 - 2) }, 0xF0CD91, 5, opacity: 0.8)
    }

    private func gear(_ x: CGFloat, _ y: CGFloat, radius: CGFloat) {
        var teeth: [(CGFloat, CGFloat)] = []
        for i in 0..<64 {
            let a = CGFloat(i) * .pi * 2 / 64, r = radius * (i % 4 < 2 ? 1 : 0.85)
            teeth.append((x + cos(a) * r, y + sin(a) * r))
        }
        fill(polygon(teeth), 0xF2D69A, 0x97774F)
        oval(x, y, radius * 1.38, radius * 1.38, palette.edge)
        for i in 0..<6 {
            let a = CGFloat(i) * .pi / 3
            line([(x, y), (x + cos(a) * radius * 0.66, y + sin(a) * radius * 0.66)], 0xCFAC70, radius * 0.13)
        }
        oval(x, y, radius * 0.49, radius * 0.49, 0xDFC18B)
        rivet(x, y, radius: radius * 0.12)
        stroke(Path(ellipseIn: CGRect(x: x - radius * 0.74, y: y - radius * 0.74, width: radius * 1.48, height: radius * 1.48)), 0xFFE4A8, 2, opacity: 0.7)
    }

    private func shell(_ x: CGFloat, _ y: CGFloat, radius: CGFloat) {
        var path = Path(); path.move(to: p(x, y))
        path.addLine(to: p(x - radius, y - radius * 0.46))
        path.addQuadCurve(to: p(x + radius, y - radius * 0.46), control: p(x, y - radius * 1.95)); path.closeSubpath()
        fill(path, 0xFCE8CD, 0xCDAB91)
        for i in 0..<7 {
            let a = -.pi + CGFloat(i) * .pi / 6
            line([(x, y - 2), (x + cos(a) * radius * 0.87, y - radius * 0.43 + sin(a) * radius * 0.70)], 0xB99E84, 1.8, opacity: 0.6)
        }
    }

    private func sparkle(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, _ hex: UInt32) {
        fill(polygon([(x, y - radius), (x + radius * 0.22, y - radius * 0.22), (x + radius, y), (x + radius * 0.22, y + radius * 0.22), (x, y + radius), (x - radius * 0.22, y + radius * 0.22), (x - radius, y), (x - radius * 0.22, y - radius * 0.22)]), 0xFFFFFF, hex)
    }
}
