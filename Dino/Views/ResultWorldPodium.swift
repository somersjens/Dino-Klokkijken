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
        case 9: (light, face, shade, edge, accent, glow) = (0xF7E4BC, 0xCBB085, 0x9B815E, 0x76644E, 0x7EBAB6, 0xDAF2D8)
        case 10: (light, face, shade, edge, accent, glow) = (0xF1EBD7, 0xC6C9BA, 0x8C9BA2, 0x61768B, 0xD4B676, 0xE4EEFF)
        default: (light, face, shade, edge, accent, glow) = (0xEEE6C5, 0xBAB894, 0x7C8966, 0x526344, 0x8FC348, 0xFFF6B9)
        }
    }
}

/// The rewards are positioned on the actual stone, with no separate surface or material mask.
enum ResultPodiumGeometry {
    static let width: CGFloat = 1000
    static let height: CGFloat = 455
    static let rewardY: CGFloat = 292
    static let starWidth: CGFloat = 0.235
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

    private var outline: Path {
        switch theme {
        case 3: return polygon([(146, 78), (304, 32), (690, 25), (856, 71), (926, 158), (955, 278), (983, 345), (938, 417), (747, 447), (221, 444), (62, 412), (22, 334), (74, 178)])
        case 5: return polygon([(156, 70), (298, 24), (616, 19), (827, 53), (893, 111), (981, 256), (949, 369), (828, 432), (559, 451), (226, 438), (79, 392), (24, 288), (83, 153)])
        case 6, 8:
            return Path { path in
                path.move(to: p(150, 64)); path.addQuadCurve(to: p(850, 64), control: p(500, -21))
                path.addLine(to: p(923, 116)); path.addLine(to: p(923, 336)); path.addLine(to: p(970, 363))
                path.addLine(to: p(970, 411)); path.addQuadCurve(to: p(30, 411), control: p(500, 496))
                path.addLine(to: p(30, 363)); path.addLine(to: p(77, 336)); path.addLine(to: p(77, 116)); path.closeSubpath()
            }
        case 4, 10:
            return polygon([(142, 70), (310, 27), (694, 23), (858, 65), (922, 119), (912, 340), (962, 371), (953, 418), (807, 445), (192, 445), (45, 416), (37, 371), (88, 339), (78, 125)])
        default:
            return Path { path in
                path.move(to: p(154, 70)); path.addCurve(to: p(837, 59), control1: p(284, 0), control2: p(724, 0))
                path.addCurve(to: p(978, 298), control1: p(902, 83), control2: p(957, 205))
                path.addQuadCurve(to: p(922, 405), control: p(1012, 353))
                path.addCurve(to: p(100, 419), control1: p(823, 474), control2: p(214, 464))
                path.addQuadCurve(to: p(25, 301), control: p(5, 390))
                path.addQuadCurve(to: p(154, 70), control: p(45, 166)); path.closeSubpath()
            }
        }
    }

    private var top: Path {
        Path { path in
            path.move(to: p(151, 72)); path.addCurve(to: p(839, 62), control1: p(302, 6), control2: p(700, 4))
            path.addQuadCurve(to: p(882, 101), control: p(885, 81))
            path.addCurve(to: p(187, 108), control1: p(732, 127), control2: p(341, 130))
            path.addQuadCurve(to: p(151, 72), control: p(129, 96)); path.closeSubpath()
        }
    }

    func draw() {
        // Each material is drawn across the complete object. Stars share its real surface.
        context.drawLayer { shadow in
            shadow.addFilter(.shadow(color: c(palette.edge).opacity(0.22), radius: 10, y: 10))
            shadow.fill(outline, with: .color(c(palette.shade)))
        }
        context.drawLayer { clipped in
            clipped.clip(to: outline)
            ResultPodiumPainter(context: clipped, palette: palette).body()
        }
        context.drawLayer { ornaments in
            let painter = ResultPodiumPainter(context: ornaments, palette: palette)
            if [1, 2, 4].contains(theme) { painter.moss() }
            if theme == 9 { painter.coastalRope() }
            if theme == 10 { painter.royalDrapes() }
        }
    }

    private func body() {
        fill(outline, palette.face, palette.shade)
        materialDetails()
        grain()
        // Broad reflected light softens the facets without blurring their material edges.
        context.fill(outline, with: .radialGradient(Gradient(colors: [c(palette.light).opacity(0.18), .clear]),
            center: p(338, 151), startRadius: 0, endRadius: 640))
        fill(top, palette.light, mix(palette.light, palette.face, 0.42))
        surfaceDetails()
        // Reflected light along the rim connects the top plane to the body.
        var rim = Path(); rim.move(to: p(171, 100))
        rim.addCurve(to: p(862, 104), control1: p(356, 134), control2: p(702, 128))
        stroke(rim, palette.light, 3, opacity: 0.7)
        context.fill(outline, with: .linearGradient(Gradient(colors: [.clear, c(palette.edge).opacity(0.17)]),
            startPoint: p(500, 320), endPoint: p(500, 465)))
    }

    private func materialDetails() {
        switch theme {
        case 1, 2: naturalStone()
        case 3: volcanicStone()
        case 4, 10: masonry()
        case 5: quartz()
        case 6, 8: machinery()
        case 7, 9: sandstone()
        default: break
        }
    }

    private func naturalStone() {
        let facets: [[(CGFloat, CGFloat)]] = [
            [(14, 299), (153, 74), (239, 125), (176, 274), (89, 413)],
            [(153, 74), (460, 100), (386, 191), (176, 274), (239, 125)],
            [(176, 274), (386, 191), (430, 440), (89, 413)],
            [(460, 100), (684, 112), (738, 245), (597, 454), (430, 440), (386, 191)],
            [(684, 112), (848, 78), (919, 209), (738, 245)],
            [(738, 245), (919, 209), (988, 323), (904, 420), (597, 454)]
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
        if theme == 2 {
            // Tiny carved constellations stay on the shoulders, away from the stars.
            for right in [false, true] {
                let x: CGFloat = right ? 895 : 105
                line([(x - 15, 210), (x + 10, 237), (x - 5, 270), (x + 13, 295)], palette.accent, 2, opacity: 0.65)
                for (dx, y) in [(-15.0, 210.0), (10, 237), (-5, 270), (13, 295)] { oval(x + dx, y, 6, 6, 0xE0F3D8, opacity: 0.8) }
            }
        }
    }

    private func sandstone() {
        for i in 0..<7 {
            let y = CGFloat(104 + i * 48)
            var layer = Path(); layer.move(to: p(0, y))
            layer.addCurve(to: p(1000, y + 3), control1: p(280, y + 31), control2: p(723, y - 22))
            layer.addLine(to: p(1000, y + 52)); layer.addCurve(to: p(0, y + 51), control1: p(712, y + 30), control2: p(309, y + 86)); layer.closeSubpath()
            fill(layer, mix(palette.light, palette.face, i.isMultiple(of: 2) ? 0.28 : 0.61), mix(palette.face, palette.shade, 0.22))
            var seam = Path(); seam.move(to: p(8, y + 4)); seam.addCurve(to: p(992, y + 8), control1: p(283, y + 35), control2: p(718, y - 17))
            stroke(seam, palette.light, 2, opacity: 0.48)
        }
        if theme == 7 {
            // Wind-cut shelves and an ammonite embedded in the exposed sandstone.
            line([(96, 168), (145, 180), (173, 172)], palette.shade, 3, opacity: 0.35)
            fossil(x: 133, y: 278, radius: 37)
            fossil(x: 870, y: 205, radius: 25)
        }
        if theme == 9 {
            for (x, y) in [(93.0, 294.0), (915, 260), (866, 378), (140, 366)] {
                oval(x, y, 14, 9, palette.shade, opacity: 0.35)
                oval(x, y - 2, 10, 4, palette.light, opacity: 0.5)
            }
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
            [(25, 288), (157, 71), (276, 121), (209, 313), (79, 392)],
            [(157, 71), (480, 41), (407, 179), (276, 121)],
            [(276, 121), (407, 179), (385, 432), (209, 313)],
            [(480, 41), (724, 93), (671, 254), (529, 451), (385, 432), (407, 179)],
            [(724, 93), (831, 54), (981, 256), (831, 302), (671, 254)],
            [(831, 302), (981, 256), (949, 369), (828, 432), (529, 451), (671, 254)]
        ]
        for (i, points) in faces.enumerated() {
            let tint = i == 2 || i == 4 ? palette.accent : palette.light
            fill(polygon(points), mix(tint, palette.face, 0.22 + Double(i % 3) * 0.18), mix(palette.face, palette.shade, 0.40))
        }
        let veins: [[(CGFloat, CGFloat)]] = [[(157, 71), (276, 121), (209, 313), (158, 409)], [(831, 54), (724, 93), (831, 302), (828, 432)]]
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
        let step = polygon([(30, 416), (165, 431), (826, 431), (969, 416), (965, 437), (819, 450), (181, 450), (30, 437)])
        fill(step, palette.light, palette.shade)
        line([(48, 428), (189, 441), (814, 441), (950, 428)], theme == 10 ? palette.accent : palette.light, 4, opacity: 0.9)
        // A dressed cornice and its shadow make this a built plinth, rather than a tinted boulder.
        fill(polygon([(81, 100), (198, 112), (809, 112), (922, 100), (924, 122), (811, 133), (192, 133), (78, 122)]), palette.light, palette.face)
        line([(94, 126), (205, 137), (801, 137), (910, 126)], palette.edge, 4, opacity: 0.25)
    }

    private func machinery() {
        // Stepped footing, curved front, inset service panels and machined edge bands.
        fill(polygon([(79, 116), (193, 143), (808, 143), (922, 116), (922, 346), (808, 380), (192, 380), (79, 346)]), palette.face, palette.shade)
        for x in [CGFloat(66), 874] {
            let path = Path(roundedRect: CGRect(x: x, y: 164, width: 60, height: 176), cornerRadius: 17)
            fill(path, palette.shade, palette.edge)
            stroke(path, palette.light, 2, opacity: 0.5)
            if theme == 6 {
                for i in 0..<6 { line([(x + 13, CGFloat(196 + i * 23)), (x + 47, CGFloat(196 + i * 23))], palette.face, 5, opacity: 0.85) }
            } else {
                gauge(x + 30, 219, radius: 22)
                for i in 0..<3 { oval(x + CGFloat(16 + i * 14), 295, 5, 5, palette.accent, opacity: 0.9) }
            }
        }
        for y in [CGFloat(111), 440] {
            var band = Path(); band.move(to: p(40, y - 24)); band.addQuadCurve(to: p(960, y - 24), control: p(500, y + 46))
            stroke(band, palette.edge, 13, opacity: 0.7)
            stroke(band.offsetBy(dx: 0, dy: -4), palette.light, 7, opacity: 0.9)
            if theme == 8 { stroke(band.offsetBy(dx: 0, dy: 5), palette.accent, 2.5, opacity: 0.75) }
        }
        for x in [CGFloat(111), 218, 782, 889] { for y in [CGFloat(153), 352] { rivet(x, y, radius: 6) } }
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

    private func surfaceDetails() {
        context.drawLayer { layer in
            layer.clip(to: top)
            let painter = ResultPodiumPainter(context: layer, palette: palette)
            switch theme {
            case 6, 8:
                // Elliptical calibration ring follows the standing plane's perspective.
                let ring = Path(ellipseIn: CGRect(x: 174, y: 27, width: 664, height: 90))
                painter.stroke(ring, palette.shade, 2, opacity: 0.48)
                for i in 0..<25 {
                    let a = CGFloat(i) / 24 * .pi
                    let x = 504 + cos(a) * 317, y = 71 + sin(a) * 39
                    painter.line([(x, y), (x - cos(a) * 12, y - sin(a) * 3)], palette.edge, i.isMultiple(of: 4) ? 3 : 1.5, opacity: 0.55)
                }
            case 9:
                painter.fill(top, 0xE6C58B, 0xAE8858)
                for i in 0..<9 {
                    let x = CGFloat(155 + i * 86)
                    painter.line([(x, 10), (x - 21, 134)], 0x8D704E, 3, opacity: 0.55)
                    painter.line([(x + 4, 10), (x - 17, 134)], 0xFFE7B0, 2, opacity: 0.55)
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
            let x = CGFloat((i * 173 + 51) % 997), y = CGFloat(119 + (i * 83) % 322)
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
            // Thin colonies follow the rim, with a different footprint on each shoulder.
            // Village stone has sparse growth; the valley has a lower, cooler cushion.
            art.translateBy(x: right ? 12 : 0, y: theme == 4 ? 27 : (theme == 2 ? 19 : 7))
            art.scaleBy(x: right ? 0.88 : 1, y: theme == 4 ? 0.58 : (theme == 2 ? 0.76 : 1))
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

    private func coastalRope() {
        for right in [false, true] {
            let x: CGFloat = right ? 896 : 104
            line([(x, 129), (x, 246)], 0x806649, 19, opacity: 0.3)
            line([(x, 124), (x, 242)], 0xE7D5A4, 13)
            for i in 0..<13 { line([(x - 5, CGFloat(132 + i * 8)), (x + 5, CGFloat(126 + i * 8))], 0xA99064, 2) }
            oval(x, 142, 30, 28, 0xC5AD7B)
            for dx in [CGFloat(-7), 4] { line([(x + dx, 132), (x + dx + 4, 151)], 0xF6E5B8, 4) }
        }
        var rope = Path(); rope.move(to: p(109, 111)); rope.addQuadCurve(to: p(891, 111), control: p(500, 133))
        stroke(rope.offsetBy(dx: 0, dy: 4), 0x7B674D, 9, opacity: 0.25)
        stroke(rope, 0xE5D3A3, 9); stroke(rope.offsetBy(dx: 0, dy: -2), 0xFFF0C2, 2, opacity: 0.75)
    }

    private func royalDrapes() {
        for right in [false, true] {
            let x: CGFloat = right ? 902 : 98
            let flag = polygon([(x - 18, 133), (x + 18, 137), (x + 18, 278), (x, 264), (x - 18, 281)])
            fill(flag, 0x8EAED3, 0x385C90)
            line([(x - 14, 142), (x - 14, 270), (x, 256), (x + 14, 269), (x + 14, 145)], 0xE1C17D, 1.5)
            fill(polygon([(x - 10, 201), (x - 12, 184), (x - 4, 190), (x, 180), (x + 4, 190), (x + 12, 184), (x + 10, 201)]), 0xFFE4A0, 0xC49A52)
            line([(x - 20, 133), (x + 20, 137)], palette.accent, 5)
        }
    }

    func surround(foreground: Bool) {
        if foreground { groundFinish(); return }
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
            for i in 0..<4 { leaf(x: CGFloat(58 + i * 13), y: 412, length: CGFloat(83 + i * 23), angle: Double(-48 + i * 29)) }
            mushroom(74, 408, height: right ? 79 : 104)
            mushroom(20, 430, height: 53)
        case 3:
            column(48, 413, width: 100, height: right ? 246 : 216)
            column(-15, 440, width: 76, height: 131)
            glow(61, 401, 73, 0xFF9D58, opacity: 0.20)
        case 4:
            planter(48, 408, width: 132)
            if !right { lantern(58, 278, height: 148, metal: false) }
        case 5:
            crystal(44, 432, height: right ? 226 : 192, purple: right)
            crystal(-14, 444, height: 119, purple: !right)
        case 6:
            lantern(52, 422, height: right ? 231 : 252, metal: true)
            fill(polygon([(-8, 429), (23, 407), (82, 407), (112, 429), (100, 446), (2, 446)]), palette.light, palette.shade)
        case 7:
            fill(polygon([(-30, 426), (1, 344), (67, 318), (116, 385), (111, 427)]), 0xF4D499, 0xB58D58)
            desertSprig(42, 359, height: right ? 104 : 139)
        case 8:
            pipe([(22, 422), (22, 284), (83, 260), (83, 159)])
            gear(52, 351, radius: right ? 69 : 83)
            gauge(79, 194, radius: 36)
            glow(84, 151, 28, palette.accent, opacity: 0.23)
        case 9:
            line([(44, 425), (44, 255)], 0x6A6552, 33)
            line([(37, 420), (37, 256)], 0xBB9D6A, 23)
            for y in [CGFloat(272), 284, 299] { line([(24, y), (58, y + 5)], 0xE3D1A3, 7) }
            oval(44, 253, 38, 14, 0xDCC18D)
            shell(5, 429, radius: 36)
        case 10:
            royalStandard(44, 411, height: right ? 230 : 253)
            fill(polygon([(-13, 417), (19, 391), (77, 391), (104, 417), (99, 439), (-9, 439)]), palette.light, palette.shade)
        default: break
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
                shadow.fill(Path(ellipseIn: CGRect(x: -2, y: 436, width: 191, height: 22)),
                            with: .color(c(palette.edge).opacity(0.10)))
            }
            switch theme {
            case 1:
                // The jungle's foreground already supplies the detailed, rooted leaf clusters.
                painter.pebble(206, 444, width: 33)
            case 2:
                painter.leaf(x: 65, y: 440, length: 124, angle: -21)
                painter.leaf(x: 68, y: 439, length: 139, angle: 10)
                painter.mushroom(79, 447, height: 55); painter.mushroom(125, 455, height: 35)
                for i in 0..<4 { painter.glow(CGFloat(26 + i * 40), CGFloat(377 + (i * 29) % 65), 6, 0xDCF3B5, opacity: 0.8) }
            case 3:
                painter.column(110, 452, width: 72, height: 68); painter.pebble(190, 451, width: 39)
            case 4:
                painter.flower(63, 450, height: 45, pink: true); painter.flower(105, 458, height: 37, pink: false)
                painter.pebble(185, 452, width: 33)
            case 5:
                painter.crystal(93, 457, height: 67, purple: !right)
                painter.pebble(172, 456, width: 38)
            case 6:
                for i in 0..<3 {
                    painter.fill(Path(roundedRect: CGRect(x: CGFloat(58 + i * 37), y: CGFloat(445 + i * 3), width: 28, height: 9), cornerRadius: 3), palette.light, palette.face)
                }
            case 7:
                painter.desertSprig(109, 454, height: 47); painter.pebble(177, 456, width: 42)
            case 8:
                painter.gear(104, 451, radius: 34); painter.rivet(178, 459, radius: 7)
            case 9:
                painter.shell(98, 454, radius: 28); painter.shell(173, 462, radius: 18)
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

    private func royalStandard(_ x: CGFloat, _ y: CGFloat, height: CGFloat) {
        line([(x, y), (x, y - height)], 0x9C875E, 6)
        oval(x, y - height - 6, 16, 19, 0xE8CA85)
        let cloth = polygon([(x + 3, y - height + 13), (x + 72, y - height + 22), (x + 72, y - height + 135), (x + 38, y - height + 116), (x + 3, y - height + 142)])
        fill(cloth, 0x92B0D4, 0x3C6095)
        line([(x + 10, y - height + 24), (x + 10, y - height + 124), (x + 38, y - height + 105), (x + 65, y - height + 122), (x + 65, y - height + 30)], 0xE4C88B, 2.5)
        sparkle(x + 38, y - height + 68, 17, 0xF2D793)
    }

    private func sparkle(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, _ hex: UInt32) {
        fill(polygon([(x, y - radius), (x + radius * 0.22, y - radius * 0.22), (x + radius, y), (x + radius * 0.22, y + radius * 0.22), (x, y + radius), (x - radius * 0.22, y + radius * 0.22), (x - radius, y), (x - radius * 0.22, y - radius * 0.22)]), 0xFFFFFF, hex)
    }
}
