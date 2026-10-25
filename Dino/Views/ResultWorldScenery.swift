import SwiftUI

/// Result scenes use the map's theme identity, including the desert/valley order swap.
/// All coordinates scale with the scene; the central reward area stays open.
struct ResultBiomePainter {
    let context: GraphicsContext
    let size: CGSize
    let themeID: Int
    private var w: CGFloat { size.width }
    private var h: CGFloat { size.height }
    private func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * w, y: y * h) }
    private func c(_ hex: UInt32) -> Color { Color(dinoHex: hex) }

    func landscape() {
        switch themeID {
        case 2: valley()
        case 3: volcano()
        case 4: village()
        case 5: cave()
        case 6: city()
        case 8: timeMachine()
        case 9: coast()
        case 10: castle()
        default: break // Jungle and desert retain their dedicated painters.
        }
    }

    private func sky(_ top: UInt32, _ bottom: UInt32) {
        fill(Path(CGRect(origin: .zero, size: size)), top, bottom, from: .zero, to: p(0, 0.78))
        if [4, 6, 9, 10].contains(themeID) {
            for right in [false, true] {
                let x: CGFloat = right ? 0.76 : -0.18
                var cloud = Path(); cloud.move(to: p(x, 0.365))
                cloud.addCurve(to: p(x + 0.49, 0.365), control1: p(x + 0.08, 0.318), control2: p(x + 0.31, 0.331))
                cloud.addQuadCurve(to: p(x, 0.365), control: p(x + 0.24, 0.381)); cloud.closeSubpath()
                context.fill(cloud, with: .color(c(0xF5F1DA).opacity(0.21)))
            }
        }
    }

    private func fill(_ path: Path, _ top: UInt32, _ bottom: UInt32, from: CGPoint, to: CGPoint) {
        context.fill(path, with: .linearGradient(Gradient(colors: [c(top), c(bottom)]), startPoint: from, endPoint: to))
    }

    private func polygon(_ points: [CGPoint]) -> Path {
        Path { path in
            path.addLines(points)
            path.closeSubpath()
        }
    }

    private func line(_ points: [CGPoint], _ hex: UInt32, width: CGFloat, opacity: Double = 1) {
        var path = Path()
        path.addLines(points)
        context.stroke(path, with: .color(c(hex).opacity(opacity)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func oval(_ center: CGPoint, _ width: CGFloat, _ height: CGFloat, _ hex: UInt32, opacity: Double = 1) {
        context.fill(Path(ellipseIn: CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)),
                     with: .color(c(hex).opacity(opacity)))
    }

    private func glow(_ center: CGPoint, radius: CGFloat, hex: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [c(hex).opacity(opacity), .clear]),
                                           center: center, startRadius: 0, endRadius: radius))
    }

    private func ground(_ top: UInt32, _ bottom: UInt32, horizon: CGFloat = 0.66) {
        var path = Path()
        path.move(to: p(-0.1, horizon + 0.02))
        path.addCurve(to: p(1.1, horizon), control1: p(0.25, horizon - 0.05), control2: p(0.75, horizon + 0.03))
        path.addLine(to: p(1.1, 1.1)); path.addLine(to: p(-0.1, 1.1)); path.closeSubpath()
        fill(path, top, bottom, from: p(0, horizon), to: p(0, 1.05))
    }

    private func rollingHill(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ rise: CGFloat, _ hex: UInt32) {
        var path = Path()
        path.move(to: p(x - width, y + rise))
        path.addCurve(to: p(x + width, y + rise), control1: p(x - width * 0.45, y - rise), control2: p(x + width * 0.35, y - rise))
        path.addLine(to: p(x + width, 1)); path.addLine(to: p(x - width, 1)); path.closeSubpath()
        fill(path, hex, hex, from: p(x, y), to: p(x, 1))
    }

    /// Curving channels remain beside Dino, so lava/water never runs through the podium.
    private func channel(right: Bool, _ hex: UInt32, highlight: UInt32, width: CGFloat,
                         source: CGPoint = CGPoint(x: 0.12, y: 0.55)) {
        func q(_ x: CGFloat, _ y: CGFloat) -> CGPoint { p(right ? 1 - x : x, y) }
        let spread = width / w
        // Narrow at the source, widening toward the viewer with irregular banks.
        var bank = Path()
        bank.move(to: q(source.x + 0.003, source.y))
        bank.addCurve(to: q(0.20 + spread * 0.4, 0.66), control1: q(source.x + 0.02, source.y + 0.04), control2: q(0.28, 0.62))
        bank.addCurve(to: q(0.04 + spread * 0.55, 0.79), control1: q(0.18, 0.71), control2: q(0.03, 0.72))
        bank.addCurve(to: q(-0.04 + spread * 0.8, 1.08), control1: q(0.15, 0.88), control2: q(-0.02, 0.95))
        bank.addLine(to: q(-0.04 - spread * 0.8, 1.08))
        bank.addCurve(to: q(0.04 - spread * 0.55, 0.79), control1: q(-0.09, 0.94), control2: q(0.05, 0.87))
        bank.addCurve(to: q(0.20 - spread * 0.4, 0.66), control1: q(-0.04, 0.72), control2: q(0.13, 0.70))
        bank.addCurve(to: q(source.x - 0.003, source.y), control1: q(0.23, 0.62), control2: q(source.x - 0.015, source.y + 0.04))
        bank.closeSubpath()
        context.stroke(bank, with: .color(c(0x292F43).opacity(0.28)), style: StrokeStyle(lineWidth: width * 0.22, lineJoin: .round))
        fill(bank, hex, highlight, from: q(source.x, source.y), to: q(0, 1.08))
        var current = Path()
        current.move(to: q(source.x, source.y))
        current.addCurve(to: q(0.20, 0.66), control1: q(source.x + 0.01, source.y + 0.04), control2: q(0.25, 0.62))
        current.addCurve(to: q(0.04, 0.79), control1: q(0.16, 0.71), control2: q(0, 0.72))
        current.addCurve(to: q(-0.04, 1.08), control1: q(0.10, 0.88), control2: q(-0.04, 0.95))
        context.stroke(current, with: .color(c(highlight).opacity(0.7)), style: StrokeStyle(lineWidth: width * 0.16, lineCap: .round))
    }

    private func stars() {
        for i in 0..<38 {
            let x = CGFloat((i * 37 + 9) % 101) / 100
            let y = 0.07 + CGFloat((i * 19 + 7) % 40) / 100
            oval(p(x, y), i.isMultiple(of: 4) ? 3 : 1.5, i.isMultiple(of: 4) ? 3 : 1.5, 0xFFF5CC, opacity: 0.8)
        }
    }

    private func moon() {
        let at = p(0.79, 0.33), radius = w * 0.045
        glow(at, radius: radius * 3, hex: 0xE4EBC4, opacity: 0.35)
        var clipped = context
        clipped.clip(to: Path(ellipseIn: CGRect(x: at.x - radius * 0.25, y: at.y - radius * 1.23,
                                               width: radius * 1.8, height: radius * 1.8)), options: .inverse)
        clipped.fill(Path(ellipseIn: CGRect(x: at.x - radius, y: at.y - radius, width: radius * 2, height: radius * 2)),
                     with: .color(c(0xFFF3C3)))
    }

    private func valley() {
        sky(0x25294F, 0xA4AFBF); stars(); moon()
        rollingHill(0.04, 0.53, 0.59, 0.12, 0x666F97)
        rollingHill(0.96, 0.56, 0.62, 0.11, 0x809CB0)
        // A single wooded valley descends into the creek, instead of rows of props.
        for i in 0..<15 {
            let x = CGFloat(i) / 14
            let y = 0.59 + sin(x * .pi) * 0.035
            let tree = polygon([p(x - 0.018, y), p(x - 0.012, y - 0.035), p(x, y - 0.065),
                                p(x + 0.014, y - 0.03), p(x + 0.02, y)])
            context.fill(tree, with: .color(c(0x65858E).opacity(0.42)))
        }
        ground(0x9ABBB0, 0x4C7777, horizon: 0.64)
        channel(right: true, 0x6396AF, highlight: 0xBCD9DB, width: w * 0.10,
                source: CGPoint(x: 0.22, y: 0.60))
        bank(right: false, top: 0x7FA69B, bottom: 0x426C72, depth: 0.67)
        bank(right: true, top: 0x92B7A6, bottom: 0x4B7D7F, depth: 0.72)
        willow(at: p(0.06, 0.68), height: w * 0.38)
        willow(at: p(0.95, 0.70), height: w * 0.30)
        for side in 0..<2 {
            for i in 0..<6 {
                let y = 0.72 + CGFloat(i) * 0.047
                let x: CGFloat = side == 0 ? 0.05 + sin(CGFloat(i)) * 0.025 : 0.95 - sin(CGFloat(i)) * 0.025
                mushroom(at: p(x, y), height: w * (0.022 + CGFloat(i % 3) * 0.007))
                glow(p(x + 0.022, y - 0.035), radius: 3, hex: 0xD6E9BB, opacity: 0.65)
            }
        }
        mist(y: 0.61, hex: 0xB8D5CC, opacity: 0.15)
    }

    private func volcano() {
        sky(0x826579, 0xEDB58E)
        glow(p(0.17, 0.47), radius: w * 0.43, hex: 0xFFBC67, opacity: 0.48)
        // Distant calderas and connected ridges establish one volcanic basin.
        ridge([(0, 0.52), (0.12, 0.45), (0.25, 0.50), (0.41, 0.44), (0.58, 0.53), (0.77, 0.46), (1, 0.52)],
              top: 0x9C8190, bottom: 0xC49A98)
        volcanoMountain(at: p(0.09, 0.64), width: w * 0.66, height: h * 0.24)
        volcanoMountain(at: p(0.95, 0.65), width: w * 0.48, height: h * 0.18)
        ground(0x9A8896, 0x454052, horizon: 0.64)
        ridge([(0, 0.67), (0.12, 0.63), (0.27, 0.65), (0.41, 0.68), (0.57, 0.66), (0.79, 0.64), (1, 0.69)],
              top: 0x8F8291, bottom: 0x4A4257)
        channel(right: false, 0xD76B40, highlight: 0xFFD28A, width: w * 0.065, source: CGPoint(x: 0.112, y: 0.544))
        channel(right: true, 0xD97449, highlight: 0xFFD999, width: w * 0.075, source: CGPoint(x: 0.041, y: 0.579))
        for side in 0..<2 {
            bank(right: side == 1, top: 0x827687, bottom: 0x373546, depth: 0.73)
            for i in 0..<5 {
                basalt(at: p(side == 0 ? 0.02 : 0.98, 0.73 + CGFloat(i) * 0.067),
                       width: w * (0.065 + CGFloat(i) * 0.013), height: w * (0.09 + CGFloat(i % 3) * 0.034))
            }
        }
        for i in 0..<18 {
            let x = i.isMultiple(of: 2) ? 0.04 + CGFloat(i % 5) * 0.025 : 0.88 + CGFloat(i % 5) * 0.025
            let at = p(x, 0.45 + CGFloat((i * 13) % 43) / 100)
            glow(at, radius: w * 0.009, hex: 0xFFB553, opacity: 0.24)
            oval(at, 1.7, 2.4, 0xFFD2A0, opacity: 0.75)
        }
        mist(y: 0.63, hex: 0xD5AAA2, opacity: 0.10)
    }

    private func volcanoMountain(at: CGPoint, width: CGFloat, height: CGFloat) {
        func q(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: at.x + x * width, y: at.y - y * height) }
        let path = polygon([q(-0.58, 0), q(-0.35, 0.35), q(-0.13, 0.96), q(0.04, 0.91), q(0.13, 1), q(0.32, 0.42), q(0.56, 0)])
        fill(path, 0x786478, 0xA68C92, from: q(0, 1), to: at)
        fill(polygon([q(0.13, 1), q(0.32, 0.42), q(0.56, 0), q(0.13, 0.05), q(0.04, 0.91)]),
             0x60546C, 0x8E7C8E, from: q(0, 1), to: at)
        oval(q(0, 0.94), width * 0.25, height * 0.045, 0xFFC170)
        line([q(0, 0.92), q(-0.03, 0.73), q(0.07, 0.55), q(0.02, 0.30)], 0xE87948, width: width * 0.026)
        line([q(0, 0.92), q(-0.03, 0.73), q(0.07, 0.55)], 0xFFE0A0, width: width * 0.008)
        for i in 0..<5 {
            oval(q(-0.02 + CGFloat(i) * 0.015, 1.1 + CGFloat(i) * 0.105),
                 width * (0.09 + CGFloat(i) * 0.025), height * 0.12, 0xB2A1AB, opacity: 0.25 - Double(i) * 0.035)
        }
    }

    private func village() {
        sky(0xA8D9E1, 0xECEDCF)
        rollingHill(0.12, 0.54, 0.64, 0.11, 0x9EB8A3)
        rollingHill(0.89, 0.55, 0.66, 0.10, 0xB9C79D)
        // Low garden walls connect the houses, tower and path into a village square.
        ground(0xD9D4B4, 0xA4B28D, horizon: 0.64)
        terrace(y: 0.641, top: 0xD7D2AF, bottom: 0xA6AA8A)
        house(at: p(0.105, 0.655), width: w * 0.255, height: h * 0.112, roof: 0xBA7965)
        house(at: p(0.905, 0.655), width: w * 0.23, height: h * 0.106, roof: 0xC18B65)
        clockTower(at: p(0.73, 0.652), width: w * 0.10, height: h * 0.19, metal: false)
        channel(right: false, 0x84B6B9, highlight: 0xD5E3D1, width: w * 0.065)
        bridge(at: p(0.16, 0.71), width: w * 0.23)
        perspectivePaving(top: 0.67, ink: 0x9F9F84, light: 0xEFE5C7)
        for right in [false, true] {
            bank(right: right, top: 0xADBE91, bottom: 0x789575, depth: 0.74)
            gardenEdge(right: right, stone: 0xC8B68E, foliage: 0x8DA57C)
            for i in 0..<3 {
                let y = 0.74 + CGFloat(i) * 0.105
                let x: CGFloat = right ? 0.95 : 0.045
                planter(at: p(x, y), width: w * (0.045 + CGFloat(i) * 0.023))
            }
        }
        mist(y: 0.63, hex: 0xF6ECC9, opacity: 0.13)
    }

    private func cave() {
        sky(0x152D46, 0x59868B)
        glow(p(0.51, 0.54), radius: w * 0.65, hex: 0x9FCBDD, opacity: 0.29)
        // Vaults share the wall's rock strata and flow into the lower shelves.
        for side in 0..<2 {
            let x: CGFloat = side == 0 ? 0 : 1, direction: CGFloat = side == 0 ? 1 : -1
            let wall = polygon([p(x, 0.12), p(x + direction * 0.14, 0.24), p(x + direction * 0.12, 0.38),
                                p(x + direction * 0.22, 0.56), p(x + direction * 0.17, 0.70), p(x + direction * 0.25, 0.82), p(x, 0.91)])
            fill(wall, 0x354761, 0x526F81, from: p(x, 0.21), to: p(x, 0.84))
            for i in 0..<5 {
                let y = 0.27 + CGFloat(i) * 0.095
                line([p(x, y), p(x + direction * 0.09, y + 0.027), p(x + direction * 0.16, y + 0.055)],
                     0x8BA5AF, width: w * 0.0025, opacity: 0.23)
            }
            for i in 0..<4 {
                let cx = x + direction * (0.026 + CGFloat(i) * 0.047)
                let tooth = polygon([p(cx - 0.026, 0.26), p(cx + 0.029, 0.26), p(cx + 0.008, 0.37 + CGFloat(i % 2) * 0.045)])
                fill(tooth, 0x34455E, 0x7B929F, from: p(cx, 0.26), to: p(cx, 0.43))
            }
        }
        ground(0x71909D, 0x334B61, horizon: 0.66)
        // The pool is cut into a bank, with reflections attached to its far edge.
        var pool = Path(); pool.move(to: p(0.78, 0.67))
        pool.addCurve(to: p(1.05, 0.71), control1: p(0.88, 0.65), control2: p(1.02, 0.66))
        pool.addLine(to: p(1.08, 0.95)); pool.addCurve(to: p(0.78, 0.67), control1: p(0.71, 0.84), control2: p(0.76, 0.74)); pool.closeSubpath()
        context.stroke(pool, with: .color(c(0x344D64).opacity(0.5)), lineWidth: w * 0.017)
        fill(pool, 0x81BBBC, 0x43879B, from: p(0.8, 0.68), to: p(1, 0.92))
        for i in 0..<7 { line([p(0.83, 0.70 + CGFloat(i) * 0.018), p(1.02, 0.70 + CGFloat(i) * 0.02)], 0xB1DFD7, width: 1.2, opacity: 0.3) }
        for right in [false, true] {
            bank(right: right, top: 0x7594A2, bottom: 0x3B536F, depth: 0.73)
            for i in 0..<4 {
                crystals(at: p(right ? 0.97 : 0.03, 0.72 + CGFloat(i) * 0.085), height: w * (0.075 + CGFloat(i % 3) * 0.026))
            }
        }
        mist(y: 0.66, hex: 0x9CC7CC, opacity: 0.10)
    }

    private func city() {
        sky(0x98C2DC, 0xE3E9DB)
        for i in 0..<13 {
            let x = CGFloat(i) * 0.09 - 0.04
            let height = h * (0.08 + CGFloat((i * 7) % 5) * 0.018)
            building(at: p(x, 0.60), width: w * 0.085, height: height, distant: true)
        }
        mist(y: 0.58, hex: 0xD8E6DF, opacity: 0.27)
        ground(0xCBD9D6, 0x778F9F, horizon: 0.645)
        terrace(y: 0.645, top: 0xC8DDDA, bottom: 0x7B9DAA)
        building(at: p(0.055, 0.65), width: w * 0.21, height: h * 0.20, distant: false)
        building(at: p(0.96, 0.65), width: w * 0.22, height: h * 0.225, distant: false)
        clockTower(at: p(0.79, 0.649), width: w * 0.10, height: h * 0.225, metal: true)
        perspectivePaving(top: 0.66, ink: 0x718C9F, light: 0xE7EEE4)
        for right in [false, true] {
            gardenEdge(right: right, stone: 0x8BA8B3, foliage: 0x789D95)
            for i in 0..<3 {
                let depth = CGFloat(i) / 2
                lamp(at: p(right ? 0.96 : 0.035, 0.72 + depth * 0.24), height: w * (0.08 + depth * 0.095))
            }
        }
    }

    private func timeMachine() {
        sky(0x323A5C, 0x9BA4B2); stars()
        // One enclosed machine hall: wall bays, portal, supports and floor conduits connect.
        for right in [false, true] {
            let x: CGFloat = right ? 0.94 : 0.06
            let panel = Path(roundedRect: CGRect(x: w * (right ? 0.86 : -0.04), y: h * 0.31, width: w * 0.18, height: h * 0.37), cornerRadius: w * 0.025)
            fill(panel, 0x747C93, 0x4A566C, from: p(x, 0.31), to: p(x, 0.68))
            line([p(x, 0.34), p(x, 0.65)], 0xC7B187, width: w * 0.011, opacity: 0.65)
        }
        let center = p(0.5, 0.485)
        for i in (0..<3).reversed() {
            let rw = w * (0.65 + CGFloat(i) * 0.16), rh = h * (0.30 + CGFloat(i) * 0.045)
            let ring = Path(ellipseIn: CGRect(x: center.x - rw / 2, y: center.y - rh / 2, width: rw, height: rh))
            context.stroke(ring, with: .color(c(0x46536E).opacity(0.6)), lineWidth: w * 0.025)
            context.stroke(ring.offsetBy(dx: 0, dy: -w * 0.004), with: .color(c(i == 0 ? 0xA0D8D3 : 0xCCB98E).opacity(0.56)), lineWidth: w * 0.006)
        }
        glow(center, radius: w * 0.44, hex: 0x9BD9D5, opacity: 0.22)
        for right in [false, true] {
            let x: CGFloat = right ? 0.87 : 0.13
            line([p(x, 0.56), p(x, 0.68)], 0x536174, width: w * 0.06)
            line([p(x - 0.012, 0.56), p(x - 0.012, 0.68)], 0xC4AE84, width: w * 0.013, opacity: 0.7)
            gear(at: p(x, 0.57), radius: w * 0.085)
        }
        ground(0xA3AFB3, 0x525F74, horizon: 0.675)
        terrace(y: 0.675, top: 0xC6BB9A, bottom: 0x657282)
        for right in [false, true] {
            let x: CGFloat = right ? 0.94 : 0.06, turn: CGFloat = right ? -0.07 : 0.07
            let pipe = [p(x, 0.67), p(x + turn, 0.75), p(x + turn, 0.85), p(x, 0.93), p(x, 1.05)]
            line(pipe, 0x4E596D, width: w * 0.033)
            line(pipe, 0xB79B72, width: w * 0.017)
            line(pipe.map { CGPoint(x: $0.x - w * 0.003, y: $0.y) }, 0xEDD4A1, width: w * 0.003, opacity: 0.75)
        }
    }

    private func coast() {
        sky(0x87CBDD, 0xE9EBD2)
        fill(Path(CGRect(x: 0, y: h * 0.485, width: w, height: h * 0.37)), 0x64ADBB, 0xB2DCD1, from: p(0, 0.485), to: p(0, 0.85))
        for row in 0..<11 {
            let y = 0.50 + CGFloat(row) * 0.021
            let span = 0.025 + CGFloat(row) * 0.008
            for col in 0..<5 {
                let x = CGFloat(col) * 0.24 + CGFloat(row % 2) * 0.08
                var ripple = Path(); ripple.move(to: p(x, y)); ripple.addQuadCurve(to: p(x + span, y), control: p(x + span * 0.5, y - 0.002))
                context.stroke(ripple, with: .color(c(0xE1F0D9).opacity(0.3)), lineWidth: 0.7 + CGFloat(row) * 0.10)
            }
        }
        ship(at: p(0.18, 0.566), width: w * 0.24)
        rollingHill(0.97, 0.56, 0.18, 0.045, 0x7C9E91)
        // The island and beach are one curved coastline; surf follows the same bank.
        var beach = Path(); beach.move(to: p(-0.08, 0.70))
        beach.addCurve(to: p(1.08, 0.67), control1: p(0.23, 0.645), control2: p(0.73, 0.755))
        let surf = beach
        beach.addLine(to: p(1.08, 1.08)); beach.addLine(to: p(-0.08, 1.08)); beach.closeSubpath()
        context.stroke(surf, with: .color(c(0x66ADB2).opacity(0.35)), lineWidth: w * 0.054)
        fill(beach, 0xF0E0B8, 0xCEAD80, from: p(0.5, 0.69), to: p(0.5, 1.04))
        context.stroke(surf.offsetBy(dx: 0, dy: h * 0.008), with: .color(c(0xFFF5D8).opacity(0.8)), lineWidth: w * 0.009)
        bank(right: true, top: 0xD2C58E, bottom: 0xA7B58B, depth: 0.70)
        palm(at: p(0.98, 0.71), height: w * 0.34)
        palm(at: p(0.015, 0.78), height: w * 0.33)
        // Weathered quay follows the shore at the right edge.
        for i in 0..<4 {
            let x = 0.82 + CGFloat(i) * 0.062, y = 0.69 - CGFloat(i) * 0.005
            fill(polygon([p(x, y), p(x + 0.054, y - 0.004), p(x + 0.056, y + 0.016), p(x + 0.002, y + 0.019)]),
                 0xD5BD8C, 0xA28968, from: p(x, y), to: p(x, y + 0.02))
        }
        for side in [false, true] {
            for i in 0..<5 { shell(at: p(side ? 0.96 : 0.04, 0.79 + CGFloat(i) * 0.046), radius: w * (0.010 + CGFloat(i % 2) * 0.004)) }
        }
        mist(y: 0.49, hex: 0xE9EBCF, opacity: 0.18)
    }

    private func castle() {
        sky(0x95AFCD, 0xE5E5D1)
        rollingHill(0.10, 0.54, 0.57, 0.08, 0xA2B4AD)
        rollingHill(0.91, 0.55, 0.61, 0.09, 0xB7C4AD)
        let wall = Path(CGRect(x: -w * 0.02, y: h * 0.505, width: w * 1.04, height: h * 0.165))
        fill(wall, 0xCFD4C5, 0x99A7AB, from: p(0, 0.505), to: p(0, 0.67))
        for row in 0..<5 {
            let y = 0.52 + CGFloat(row) * 0.028
            line([p(0, y), p(1, y)], 0x8195A4, width: 1, opacity: 0.20)
            for col in 0..<9 {
                let x = CGFloat(col) * 0.13 + (row.isMultiple(of: 2) ? 0 : 0.065)
                line([p(x, y), p(x, y + 0.027)], 0x8195A4, width: 1, opacity: 0.16)
            }
        }
        for i in 0..<16 {
            let rect = CGRect(x: CGFloat(i) * w / 15, y: h * 0.483, width: w * 0.038, height: h * 0.03)
            fill(Path(roundedRect: rect, cornerRadius: w * 0.004), 0xDEE1CD, 0xB5C1BA, from: p(0, 0.483), to: p(0, 0.515))
        }
        let gate = Path(roundedRect: CGRect(x: w * 0.405, y: h * 0.547, width: w * 0.19, height: h * 0.14), cornerRadius: w * 0.095)
        context.stroke(gate, with: .color(c(0xDFDFCA)), lineWidth: w * 0.021)
        fill(gate, 0x6E7F8A, 0x465C72, from: p(0.5, 0.55), to: p(0.5, 0.68))
        line([p(0.5, 0.56), p(0.5, 0.68)], 0xB4AA87, width: 2, opacity: 0.55)
        for side in 0..<2 { castleTower(at: p(side == 0 ? 0.12 : 0.88, 0.67), width: w * 0.19, height: h * 0.245) }
        ground(0xDBDDCC, 0xA0ADA8, horizon: 0.665)
        terrace(y: 0.671, top: 0xDFDECB, bottom: 0x9BAAA9)
        perspectivePaving(top: 0.68, ink: 0x8A9DAB, light: 0xF1EDDC)
        for right in [false, true] {
            gardenEdge(right: right, stone: 0xAFBDB7, foliage: 0x7E9D90)
            heraldicPost(at: p(right ? 0.96 : 0.035, 0.765), height: w * 0.18)
            heraldicPost(at: p(right ? 0.98 : 0.015, 0.96), height: w * 0.24)
        }
        mist(y: 0.61, hex: 0xDCE2D3, opacity: 0.10)
    }

    private func ridge(_ points: [(CGFloat, CGFloat)], top: UInt32, bottom: UInt32) {
        var shape = Path(); shape.addLines(points.map { p($0.0, $0.1) })
        shape.addLine(to: p(1.1, 1.08)); shape.addLine(to: p(-0.1, 1.08)); shape.closeSubpath()
        fill(shape, top, bottom, from: p(0, points.first?.1 ?? 0.6), to: p(0, 1.06))
    }

    private func mist(y: CGFloat, hex: UInt32, opacity: Double) {
        let rect = CGRect(x: -w * 0.1, y: h * (y - 0.05), width: w * 1.2, height: h * 0.12)
        context.fill(Path(rect), with: .linearGradient(Gradient(stops: [
            .init(color: .clear, location: 0), .init(color: c(hex).opacity(opacity), location: 0.48), .init(color: .clear, location: 1)
        ]), startPoint: p(0, y - 0.05), endPoint: p(0, y + 0.07)))
    }

    private func bank(right: Bool, top: UInt32, bottom: UInt32, depth: CGFloat) {
        func q(_ x: CGFloat, _ y: CGFloat) -> CGPoint { p(right ? 1 - x : x, y) }
        var path = Path(); path.move(to: q(-0.07, depth - 0.025))
        path.addCurve(to: q(0.16, depth + 0.12), control1: q(0.11, depth - 0.04), control2: q(0.17, depth + 0.04))
        path.addCurve(to: q(0.22, 1.08), control1: q(0.10, depth + 0.26), control2: q(0.17, 0.98))
        path.addLine(to: q(-0.1, 1.08)); path.closeSubpath()
        fill(path, top, bottom, from: q(0.05, depth), to: q(0.05, 1.08))
        for i in 0..<4 {
            let y = depth + 0.05 + CGFloat(i) * 0.073
            var contour = Path(); contour.move(to: q(-0.02, y))
            contour.addQuadCurve(to: q(0.14 + CGFloat(i) * 0.009, y + 0.031), control: q(0.10, y - 0.012))
            context.stroke(contour, with: .color(c(top).opacity(0.4)), lineWidth: 1 + CGFloat(i) * 0.3)
        }
    }

    private func terrace(y: CGFloat, top: UInt32, bottom: UInt32) {
        let base = polygon([p(-0.02, y), p(1.02, y), p(1.02, y + 0.02), p(-0.02, y + 0.02)])
        fill(base, top, bottom, from: p(0, y), to: p(0, y + 0.02))
        line([p(-0.02, y), p(1.02, y)], 0xF0EBD2, width: 1.5, opacity: 0.45)
    }

    private func perspectivePaving(top: CGFloat, ink: UInt32, light: UInt32) {
        for i in 0..<9 {
            let t = CGFloat(i) / 8, y = top + t * t * (1.08 - top)
            line([p(-0.05, y), p(1.05, y)], light, width: 0.8 + t * 1.4, opacity: 0.40)
            if i < 8 {
                let next = top + pow(CGFloat(i + 1) / 8, 2) * (1.08 - top)
                for col in 0..<10 {
                    let far = 0.5 + (CGFloat(col) / 9 - 0.5) * (0.26 + t * 1.6)
                    let near = 0.5 + (CGFloat(col) / 9 - 0.5) * (0.26 + CGFloat(i + 1) / 8 * 1.6)
                    line([p(far, y), p(near, next)], ink, width: 0.8 + t, opacity: 0.20)
                }
            }
        }
    }

    private func gardenEdge(right: Bool, stone: UInt32, foliage: UInt32) {
        func q(_ x: CGFloat, _ y: CGFloat) -> CGPoint { p(right ? 1 - x : x, y) }
        var bed = Path(); bed.move(to: q(-0.04, 0.68))
        bed.addCurve(to: q(0.12, 1.06), control1: q(0.15, 0.73), control2: q(0.12, 0.93))
        bed.addLine(to: q(-0.05, 1.06)); bed.closeSubpath()
        fill(bed, foliage, stone, from: q(0, 0.68), to: q(0, 1.06))
        var rim = Path(); rim.move(to: q(0.01, 0.68)); rim.addCurve(to: q(0.12, 1.06), control1: q(0.16, 0.78), control2: q(0.10, 0.94))
        context.stroke(rim, with: .color(c(stone)), lineWidth: w * 0.016)
        context.stroke(rim.offsetBy(dx: 0, dy: -2), with: .color(c(0xE4E4C8).opacity(0.45)), lineWidth: w * 0.004)
    }

    private func bridge(at: CGPoint, width: CGFloat) {
        let height = width * 0.17
        var arch = Path(); arch.move(to: CGPoint(x: at.x - width / 2, y: at.y))
        arch.addQuadCurve(to: CGPoint(x: at.x + width / 2, y: at.y), control: CGPoint(x: at.x, y: at.y - height * 1.5))
        arch.addLine(to: CGPoint(x: at.x + width / 2, y: at.y + height * 0.65))
        arch.addQuadCurve(to: CGPoint(x: at.x - width / 2, y: at.y + height * 0.65), control: CGPoint(x: at.x, y: at.y - height * 0.2)); arch.closeSubpath()
        fill(arch, 0xE2D4AF, 0x9E9E80, from: CGPoint(x: at.x, y: at.y - height), to: CGPoint(x: at.x, y: at.y + height))
        for i in 0..<7 {
            let t = CGFloat(i) / 6, x = at.x - width / 2 + width * t
            let y = at.y - sin(t * .pi) * height * 0.6
            line([CGPoint(x: x, y: y - height * 0.5), CGPoint(x: x, y: y + 2)], 0xBDAF8D, width: width * 0.028)
        }
    }

    /// This clearing follows the actual podium anchor, including safe areas and tablet spacing.
    /// Its contours continue the world's terrain under the foreground without adding props.
    func connectToPodium(_ frame: CGRect) {
        guard frame.width > 0 else { return }
        let theme = themeID
        let palette: (UInt32, UInt32, UInt32)
        switch theme {
        case 2: palette = (0x93B6A8, 0x456D77, 0xB1CEC2)
        case 3: palette = (0x8B7F91, 0x403D51, 0xAD94A0)
        case 4: palette = (0xCDC8A6, 0x8F9F80, 0xE6DDBA)
        case 5: palette = (0x718E9F, 0x3A526C, 0x9EC3C8)
        case 6: palette = (0xAEC4C8, 0x657F95, 0xD4E4DB)
        case 7: palette = (0xEFD29D, 0xBD9668, 0xFFE7B5)
        case 8: palette = (0x929DAA, 0x526175, 0xC8CFB9)
        case 9: palette = (0xE5CAA0, 0xBF9C75, 0xF7E4BC)
        case 10: palette = (0xC9D0C1, 0x8B9FA6, 0xECE9D2)
        default: palette = (0xB2D458, 0x65913B, 0xD6E887)
        }
        let base = CGPoint(x: frame.midX, y: frame.maxY - frame.height * 0.03)
        let radius = frame.width * 0.71
        // Scale a unit radial gradient, so every edge of the footprint becomes transparent.
        // A wide radial gradient clipped to a shallow oval leaves a visible horizontal band.
        var footing = context
        footing.translateBy(x: base.x, y: base.y)
        footing.scaleBy(x: radius, y: frame.height * 0.18)
        footing.fill(Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2)),
            with: .radialGradient(Gradient(colors: [c(palette.0).opacity(0.35), c(palette.1).opacity(0.06), .clear]),
                center: .zero, startRadius: 0, endRadius: 1))
        if [1, 2, 7, 9].contains(theme) {
            // Perspective fan of subtle turf/sand markings connects the clearing to the horizon.
            for i in 0..<24 {
                let side: CGFloat = i.isMultiple(of: 2) ? -1 : 1
                let t = CGFloat(i / 2) / 11
                let x = base.x + side * frame.width * (0.50 + t * 0.23)
                let y = base.y + frame.height * (0.01 + CGFloat(i % 4) * 0.045)
                line([CGPoint(x: x, y: y), CGPoint(x: x + side * frame.width * 0.018, y: y - frame.height * 0.009)], palette.2, width: 1.2, opacity: 0.35)
            }
        }
    }

    private func basalt(at: CGPoint, width: CGFloat, height: CGFloat) {
        let path = polygon([CGPoint(x: at.x - width * 0.5, y: at.y), CGPoint(x: at.x - width * 0.47, y: at.y - height * 0.72),
                            CGPoint(x: at.x - width * 0.10, y: at.y - height), CGPoint(x: at.x + width * 0.42, y: at.y - height * 0.86),
                            CGPoint(x: at.x + width * 0.52, y: at.y - height * 0.2), CGPoint(x: at.x + width * 0.3, y: at.y)])
        fill(path, 0x7D7786, 0x3B384C, from: CGPoint(x: at.x, y: at.y - height), to: at)
        line([CGPoint(x: at.x - width * 0.10, y: at.y - height), CGPoint(x: at.x + width * 0.04, y: at.y - height * 0.7),
              CGPoint(x: at.x, y: at.y - height * 0.12)], 0x9A8D99, width: width * 0.018, opacity: 0.6)
    }

    private func crystals(at: CGPoint, height: CGFloat) {
        glow(CGPoint(x: at.x, y: at.y - height * 0.4), radius: height * 0.8, hex: 0x8DDADA, opacity: 0.18)
        for i in 0..<3 {
            let x = at.x + CGFloat(i - 1) * height * 0.24
            let top = at.y - height * (i == 1 ? 1 : 0.64)
            let width = height * 0.31
            let path = polygon([CGPoint(x: x - width / 2, y: at.y), CGPoint(x: x - width / 2, y: top + width * 0.6),
                                CGPoint(x: x, y: top), CGPoint(x: x + width / 2, y: top + width * 0.4), CGPoint(x: x + width / 2, y: at.y)])
            fill(path, i == 0 ? 0xD5C9F1 : 0xC0F2E8, i == 0 ? 0x796BA8 : 0x588EAF,
                 from: CGPoint(x: x, y: top), to: CGPoint(x: x, y: at.y))
            line([CGPoint(x: x, y: top), CGPoint(x: x + width * 0.1, y: at.y - width * 0.2)], 0xEBFFF2, width: max(1, width * 0.045), opacity: 0.8)
        }
    }

    private func willow(at: CGPoint, height: CGFloat) {
        let trunk = polygon([CGPoint(x: at.x - height * 0.04, y: at.y), CGPoint(x: at.x + height * 0.02, y: at.y - height * 0.75),
                             CGPoint(x: at.x + height * 0.075, y: at.y - height * 0.77), CGPoint(x: at.x + height * 0.065, y: at.y)])
        fill(trunk, 0x7E8A89, 0x4D6473, from: CGPoint(x: at.x, y: at.y - height), to: at)
        var crown = Path(); crown.move(to: CGPoint(x: at.x - height * 0.48, y: at.y - height * 0.43))
        crown.addCurve(to: CGPoint(x: at.x - height * 0.08, y: at.y - height * 0.88),
                       control1: CGPoint(x: at.x - height * 0.49, y: at.y - height * 0.76), control2: CGPoint(x: at.x - height * 0.27, y: at.y - height * 0.90))
        crown.addCurve(to: CGPoint(x: at.x + height * 0.49, y: at.y - height * 0.39),
                       control1: CGPoint(x: at.x + height * 0.22, y: at.y - height * 0.98), control2: CGPoint(x: at.x + height * 0.51, y: at.y - height * 0.78))
        crown.addQuadCurve(to: CGPoint(x: at.x + height * 0.15, y: at.y - height * 0.62), control: CGPoint(x: at.x + height * 0.20, y: at.y - height * 0.34))
        crown.addQuadCurve(to: CGPoint(x: at.x - height * 0.48, y: at.y - height * 0.43), control: CGPoint(x: at.x - height * 0.21, y: at.y - height * 0.54)); crown.closeSubpath()
        fill(crown, 0x9DBCAD, 0x587F86, from: CGPoint(x: at.x, y: at.y - height), to: at)
        for i in 0..<12 {
            let t = CGFloat(i) / 11, x = at.x + (t - 0.5) * height * 0.83
            let top = at.y - height * (0.55 + sin(t * .pi) * 0.26)
            let length = height * (0.31 + sin(t * .pi) * 0.15)
            var strand = Path(); strand.move(to: CGPoint(x: x, y: top))
            strand.addQuadCurve(to: CGPoint(x: x + height * 0.055, y: top + length), control: CGPoint(x: x + height * 0.10, y: top + length * 0.55))
            context.stroke(strand, with: .color(c(i.isMultiple(of: 3) ? 0xA5C7B3 : 0x83B0A3).opacity(0.86)),
                           style: StrokeStyle(lineWidth: height * 0.021, lineCap: .round))
        }
        oval(CGPoint(x: at.x + height * 0.02, y: at.y), height * 0.23, height * 0.04, 0x527A7C, opacity: 0.35)
    }

    private func mushroom(at: CGPoint, height: CGFloat) {
        glow(CGPoint(x: at.x, y: at.y - height), radius: height * 1.4, hex: 0xB6ECDB, opacity: 0.15)
        line([at, CGPoint(x: at.x, y: at.y - height * 0.7)], 0xD4DDC4, width: height * 0.14)
        var cap = Path()
        cap.move(to: CGPoint(x: at.x - height * 0.48, y: at.y - height * 0.64))
        cap.addQuadCurve(to: CGPoint(x: at.x + height * 0.48, y: at.y - height * 0.64), control: CGPoint(x: at.x, y: at.y - height * 1.6))
        cap.addQuadCurve(to: CGPoint(x: at.x - height * 0.48, y: at.y - height * 0.64), control: CGPoint(x: at.x, y: at.y - height * 0.45))
        fill(cap, 0xDBEEE0, 0x8EBBB6, from: CGPoint(x: at.x, y: at.y - height), to: at)
    }

    private func house(at: CGPoint, width: CGFloat, height: CGFloat, roof: UInt32) {
        let wall = Path(roundedRect: CGRect(x: at.x - width / 2, y: at.y - height, width: width, height: height), cornerRadius: width * 0.025)
        fill(wall, 0xF1E5C5, 0xC4B594, from: CGPoint(x: at.x - width / 2, y: at.y - height), to: at)
        fill(polygon([CGPoint(x: at.x + width * 0.26, y: at.y - height), CGPoint(x: at.x + width / 2, y: at.y - height),
                      CGPoint(x: at.x + width / 2, y: at.y), CGPoint(x: at.x + width * 0.26, y: at.y)]), 0xDBCEAA, 0xAEA58C,
             from: CGPoint(x: at.x, y: at.y - height), to: at)
        let top = polygon([CGPoint(x: at.x - width * 0.61, y: at.y - height * 0.92), CGPoint(x: at.x - width * 0.08, y: at.y - height * 1.36),
                           CGPoint(x: at.x + width * 0.61, y: at.y - height * 0.92)])
        fill(top, roof, 0x987568, from: CGPoint(x: at.x - width * 0.1, y: at.y - height * 1.36), to: CGPoint(x: at.x, y: at.y - height * 0.92))
        context.drawLayer { tiles in
            tiles.clip(to: top)
            for row in 0..<5 {
                let y = at.y - height * (1.32 - CGFloat(row) * 0.085)
                var line = Path(); line.move(to: CGPoint(x: at.x - width, y: y)); line.addLine(to: CGPoint(x: at.x + width, y: y))
                tiles.stroke(line, with: .color(c(0xE1B393).opacity(0.30)), lineWidth: max(0.7, width * 0.006))
            }
        }
        line([CGPoint(x: at.x - width * 0.59, y: at.y - height * 0.90), CGPoint(x: at.x + width * 0.59, y: at.y - height * 0.90)], 0x8B7763, width: width * 0.022, opacity: 0.65)
        for dx in [-0.28, 0.16] {
            let center = CGPoint(x: at.x + width * dx, y: at.y - height * 0.59)
            let window = Path(roundedRect: CGRect(x: center.x - width * 0.085, y: center.y - height * 0.14, width: width * 0.17, height: height * 0.28), cornerRadius: width * 0.035)
            fill(window, 0xA3C4BE, 0x6C969B, from: CGPoint(x: center.x, y: center.y - height * 0.14), to: CGPoint(x: center.x, y: center.y + height * 0.14))
            context.stroke(window, with: .color(c(0xEEE0BA)), lineWidth: width * 0.014)
            line([CGPoint(x: center.x, y: center.y - height * 0.13), CGPoint(x: center.x, y: center.y + height * 0.13)], 0xE7D8B2, width: max(1, width * 0.009))
            line([CGPoint(x: center.x - width * 0.1, y: center.y + height * 0.15), CGPoint(x: center.x + width * 0.1, y: center.y + height * 0.15)], 0xB4AB8A, width: width * 0.022)
        }
        let door = Path(roundedRect: CGRect(x: at.x - width * 0.12, y: at.y - height * 0.35, width: width * 0.18, height: height * 0.38), cornerRadius: width * 0.055)
        fill(door, 0xA58D6D, 0x83755C, from: CGPoint(x: at.x, y: at.y - height * 0.35), to: at)
        line([CGPoint(x: at.x - width * 0.54, y: at.y), CGPoint(x: at.x + width * 0.54, y: at.y)], 0xB5AC8B, width: width * 0.035)
    }

    private func building(at: CGPoint, width: CGFloat, height: CGFloat, distant: Bool) {
        let rect = CGRect(x: at.x - width / 2, y: at.y - height, width: width, height: height)
        fill(Path(roundedRect: rect, cornerRadius: width * 0.06), distant ? 0xA2C4D0 : 0x83B8C4, distant ? 0x9DB5C2 : 0x527F99,
             from: CGPoint(x: at.x, y: rect.minY), to: at)
        if !distant {
            fill(polygon([CGPoint(x: rect.maxX - width * 0.19, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY),
                          CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.maxX - width * 0.19, y: rect.maxY)]),
                 0x789FAE, 0x52768B, from: CGPoint(x: rect.maxX, y: rect.minY), to: at)
            line([CGPoint(x: rect.minX - width * 0.03, y: rect.minY + height * 0.035), CGPoint(x: rect.maxX + width * 0.03, y: rect.minY + height * 0.035)], 0xC9DDD6, width: max(1, width * 0.025), opacity: 0.8)
            line([CGPoint(x: rect.minX, y: rect.maxY - height * 0.04), CGPoint(x: rect.maxX, y: rect.maxY - height * 0.04)], 0xA6C2C5, width: max(1, width * 0.022), opacity: 0.7)
        }
        for row in 0..<(distant ? 4 : 7) {
            for col in 0..<3 {
                let r = CGRect(x: rect.minX + width * (0.12 + CGFloat(col) * 0.28), y: rect.minY + height * (0.08 + CGFloat(row) * 0.12), width: width * 0.14, height: height * 0.055)
                context.fill(Path(roundedRect: r, cornerRadius: 1), with: .color(c(0xE3F2DC).opacity(distant ? 0.28 : 0.75)))
            }
        }
    }

    private func clockTower(at: CGPoint, width: CGFloat, height: CGFloat, metal: Bool) {
        let rect = CGRect(x: at.x - width / 2, y: at.y - height, width: width, height: height)
        fill(Path(roundedRect: rect, cornerRadius: width * 0.12), metal ? 0xA3CFCE : 0xF3DEB4, metal ? 0x547C96 : 0xB2987A,
             from: CGPoint(x: at.x, y: rect.minY), to: at)
        let center = CGPoint(x: at.x, y: rect.minY + width * 0.63)
        oval(center, width * 0.82, width * 0.82, 0x6B747B)
        oval(center, width * 0.65, width * 0.65, 0xFFF1CD)
        for i in 0..<12 {
            let a = CGFloat(i) * .pi / 6
            line([CGPoint(x: center.x + sin(a) * width * 0.26, y: center.y - cos(a) * width * 0.26),
                  CGPoint(x: center.x + sin(a) * width * 0.29, y: center.y - cos(a) * width * 0.29)], 0x7C867C, width: max(0.65, width * 0.013), opacity: 0.7)
        }
        line([CGPoint(x: center.x - width * 0.16, y: center.y), center, CGPoint(x: center.x, y: center.y - width * 0.23)], 0x536473, width: max(1, width * 0.055))
        if !metal {
            fill(polygon([CGPoint(x: at.x - width * 0.65, y: rect.minY), CGPoint(x: at.x, y: rect.minY - width * 0.65),
                          CGPoint(x: at.x + width * 0.65, y: rect.minY)]), 0xC08263, 0x925D55, from: center, to: at)
        }
    }

    private func paving(_ hex: UInt32, opacity: Double) {
        for row in 0..<8 {
            let depth = CGFloat(row) / 7
            let y = 0.71 + depth * depth * 0.34
            line([p(0, y), p(1, y)], hex, width: 1 + depth, opacity: opacity)
            for col in 0..<7 {
                let x = CGFloat(col) / 6 + (row.isMultiple(of: 2) ? 0 : 0.075)
                line([p(x, y), p(x + (x - 0.5) * 0.025, y + 0.025 + depth * 0.03)], hex, width: 1, opacity: opacity * 0.7)
            }
        }
    }

    private func planter(at: CGPoint, width: CGFloat) {
        fill(Path(roundedRect: CGRect(x: at.x - width / 2, y: at.y - width * 0.32, width: width, height: width * 0.40), cornerRadius: width * 0.06),
             0xCE9977, 0x92694F, from: CGPoint(x: at.x, y: at.y - width * 0.32), to: at)
        for i in 0..<5 {
            let x = at.x + CGFloat(i - 2) * width * 0.14
            let y = at.y - width * (i.isMultiple(of: 2) ? 0.45 : 0.6)
            oval(CGPoint(x: x, y: y + width * 0.08), width * 0.30, width * 0.22, 0x6C966A)
            oval(CGPoint(x: x, y: y), width * 0.14, width * 0.14, i.isMultiple(of: 2) ? 0xF5D596 : 0xE9A998)
        }
    }

    private func lamp(at: CGPoint, height: CGFloat) {
        line([at, CGPoint(x: at.x, y: at.y - height)], 0x4E6A7F, width: height * 0.045)
        oval(at, height * 0.15, height * 0.04, 0x61798A)
        glow(CGPoint(x: at.x, y: at.y - height), radius: height * 0.23, hex: 0xFFF1BE, opacity: 0.35)
        oval(CGPoint(x: at.x, y: at.y - height), height * 0.15, height * 0.20, 0xF7E7B4)
        oval(CGPoint(x: at.x, y: at.y - height * 1.1), height * 0.20, height * 0.05, 0x52768B)
    }

    private func gear(at: CGPoint, radius: CGFloat) {
        var path = Path()
        for i in 0..<64 {
            let angle = CGFloat(i) * .pi * 2 / 64
            let r = radius * (i % 4 < 2 ? 1 : 0.85)
            let point = CGPoint(x: at.x + cos(angle) * r, y: at.y + sin(angle) * r)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        fill(path, 0xDAC38A, 0x8F7758, from: CGPoint(x: at.x, y: at.y - radius), to: CGPoint(x: at.x, y: at.y + radius))
        oval(at, radius * 1.32, radius * 1.32, 0x666C7E)
        oval(at, radius * 0.42, radius * 0.42, 0xBFA46F)
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3
            line([CGPoint(x: at.x + cos(angle) * radius * 0.19, y: at.y + sin(angle) * radius * 0.19),
                  CGPoint(x: at.x + cos(angle) * radius * 0.69, y: at.y + sin(angle) * radius * 0.69)], 0xBFA46F, width: radius * 0.13)
        }
    }

    private func palm(at: CGPoint, height: CGFloat) {
        line([at, CGPoint(x: at.x - height * 0.12, y: at.y - height * 0.78)], 0xA98A66, width: height * 0.075)
        let crown = CGPoint(x: at.x - height * 0.12, y: at.y - height * 0.78)
        for i in 0..<7 {
            let angle = CGFloat(i) * .pi / 5 - .pi * 1.1
            let tip = CGPoint(x: crown.x + cos(angle) * height * 0.5, y: crown.y + sin(angle) * height * 0.32)
            var frond = Path()
            frond.move(to: crown)
            frond.addQuadCurve(to: tip, control: CGPoint(x: tip.x, y: tip.y - height * 0.18))
            frond.addQuadCurve(to: crown, control: CGPoint(x: tip.x * 0.55 + crown.x * 0.45, y: tip.y + height * 0.03))
            fill(frond, 0x86B58B, 0x4F8E79, from: crown, to: tip)
        }
    }

    private func ship(at: CGPoint, width: CGFloat) {
        fill(polygon([CGPoint(x: at.x - width * 0.55, y: at.y), CGPoint(x: at.x + width * 0.55, y: at.y),
                      CGPoint(x: at.x + width * 0.32, y: at.y + width * 0.17), CGPoint(x: at.x - width * 0.32, y: at.y + width * 0.17)]),
             0xA67E59, 0x6B6958, from: at, to: CGPoint(x: at.x, y: at.y + width * 0.17))
        line([at, CGPoint(x: at.x, y: at.y - width * 0.76)], 0x7B725D, width: width * 0.035)
        fill(polygon([CGPoint(x: at.x + width * 0.03, y: at.y - width * 0.68), CGPoint(x: at.x + width * 0.38, y: at.y - width * 0.12),
                      CGPoint(x: at.x + width * 0.03, y: at.y - width * 0.09)]), 0xFFF1CE, 0xDDD9B4, from: at, to: CGPoint(x: at.x, y: at.y - width))
        fill(polygon([CGPoint(x: at.x - width * 0.03, y: at.y - width * 0.52), CGPoint(x: at.x - width * 0.32, y: at.y - width * 0.12),
                      CGPoint(x: at.x - width * 0.03, y: at.y - width * 0.12)]), 0xF3E6C4, 0xC5C7AD, from: at, to: CGPoint(x: at.x, y: at.y - width))
    }

    private func shell(at: CGPoint, radius: CGFloat) {
        var path = Path()
        path.move(to: CGPoint(x: at.x, y: at.y + radius * 0.4))
        path.addCurve(to: CGPoint(x: at.x - radius, y: at.y), control1: CGPoint(x: at.x - radius * 0.6, y: at.y + radius * 0.3), control2: CGPoint(x: at.x - radius * 1.2, y: at.y + radius * 0.1))
        path.addQuadCurve(to: CGPoint(x: at.x + radius, y: at.y), control: CGPoint(x: at.x, y: at.y - radius * 1.7))
        path.closeSubpath()
        fill(path, 0xFFF0DA, 0xD6AC99, from: CGPoint(x: at.x, y: at.y - radius), to: at)
        for i in -1...1 { line([CGPoint(x: at.x, y: at.y + radius * 0.3), CGPoint(x: at.x + CGFloat(i) * radius * 0.5, y: at.y - radius * 0.55)], 0xC09987, width: max(0.6, radius * 0.07), opacity: 0.6) }
    }

    private func castleTower(at: CGPoint, width: CGFloat, height: CGFloat) {
        let rect = CGRect(x: at.x - width / 2, y: at.y - height, width: width, height: height)
        fill(Path(roundedRect: rect, cornerRadius: width * 0.08), 0xDEE1CF, 0x8C9CA9, from: CGPoint(x: rect.minX, y: rect.minY), to: CGPoint(x: rect.maxX, y: rect.maxY))
        for i in 0..<4 {
            context.fill(Path(CGRect(x: rect.minX + CGFloat(i) * width * 0.29, y: rect.minY - width * 0.17, width: width * 0.16, height: width * 0.23)), with: .color(c(0xD5DDCE)))
        }
        oval(CGPoint(x: at.x, y: rect.minY + width * 0.42), width * 0.20, width * 0.38, 0x667587)
        heraldicPost(at: CGPoint(x: at.x + width * 0.2, y: at.y - height * 0.12), height: height * 0.60)
        for i in 1..<6 {
            let y = rect.minY + CGFloat(i) * height / 6
            line([CGPoint(x: rect.minX, y: y), CGPoint(x: rect.maxX, y: y)], 0x8294A1, width: 1, opacity: 0.32)
        }
    }

    private func heraldicPost(at: CGPoint, height: CGFloat) {
        line([at, CGPoint(x: at.x, y: at.y - height)], 0x80775D, width: height * 0.025)
        let banner = polygon([CGPoint(x: at.x, y: at.y - height), CGPoint(x: at.x + height * 0.26, y: at.y - height * 0.96),
                              CGPoint(x: at.x + height * 0.26, y: at.y - height * 0.50), CGPoint(x: at.x + height * 0.12, y: at.y - height * 0.57),
                              CGPoint(x: at.x, y: at.y - height * 0.52)])
        fill(banner, 0x7899C8, 0x4B659B, from: CGPoint(x: at.x, y: at.y - height), to: at)
        oval(CGPoint(x: at.x + height * 0.13, y: at.y - height * 0.78), height * 0.09, height * 0.12, 0xEACB89)
    }

}
