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
        sky(0x25294F, 0xACACCD); stars(); moon()
        rollingHill(0.07, 0.53, 0.55, 0.11, 0x737DA8)
        rollingHill(0.92, 0.56, 0.65, 0.10, 0x8B9EB7)
        ground(0xA8C9BA, 0x4D7B79)
        channel(right: true, 0x6E9EBD, highlight: 0xCFDBE9, width: w * 0.10)
        willow(at: p(0.02, 0.69), height: w * 0.42)
        willow(at: p(0.98, 0.65), height: w * 0.34)
        for i in 0..<16 {
            let right = i.isMultiple(of: 2)
            let at = p(right ? 0.93 : 0.065, 0.72 + CGFloat(i % 8) * 0.043)
            mushroom(at: at, height: w * (0.022 + CGFloat(i % 3) * 0.009))
            glow(CGPoint(x: at.x + 8, y: at.y - 30), radius: 3, hex: 0xFFF6A6, opacity: 0.8)
        }
        for i in 0..<6 {
            oval(p(0.13 + CGFloat(i % 2) * 0.73, 0.74 + CGFloat(i) * 0.035), w * 0.055, h * 0.006, 0xBDD3CB, opacity: 0.18)
        }
    }

    private func volcano() {
        sky(0x8D687D, 0xF3BD91)
        glow(p(0.17, 0.47), radius: w * 0.38, hex: 0xFFBC67, opacity: 0.65)
        volcanoMountain(at: p(0.10, 0.61), width: w * 0.63, height: h * 0.22)
        volcanoMountain(at: p(0.95, 0.63), width: w * 0.46, height: h * 0.17)
        ground(0x918392, 0x423B50)
        channel(right: false, 0xE66D37, highlight: 0xFFDC75, width: w * 0.065, source: CGPoint(x: 0.112, y: 0.544))
        channel(right: true, 0xED743D, highlight: 0xFFE49A, width: w * 0.085, source: CGPoint(x: 0.041, y: 0.579))
        for side in 0..<2 {
            for i in 0..<7 {
                basalt(at: p(side == 0 ? 0.035 : 0.965, 0.69 + CGFloat(i) * 0.055),
                       width: w * (0.09 + CGFloat(i % 3) * 0.025), height: w * (0.11 + CGFloat(i % 4) * 0.045))
            }
        }
        for i in 0..<25 {
            let x = i.isMultiple(of: 2) ? 0.03 + CGFloat(i % 5) * 0.025 : 0.88 + CGFloat(i % 5) * 0.025
            let at = p(x, 0.42 + CGFloat((i * 13) % 47) / 100)
            glow(at, radius: w * 0.012, hex: 0xFFB553, opacity: 0.28)
            oval(at, 2, 3, 0xFFD27E, opacity: 0.8)
        }
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
        sky(0xA6DCE3, 0xE8F0CB)
        rollingHill(0.1, 0.56, 0.6, 0.12, 0x9DBEA7)
        rollingHill(0.9, 0.57, 0.6, 0.09, 0xB8CEA0)
        house(at: p(0.12, 0.64), width: w * 0.25, height: h * 0.11, roof: 0xBD715B)
        house(at: p(0.90, 0.63), width: w * 0.21, height: h * 0.10, roof: 0xC98B61)
        clockTower(at: p(0.73, 0.57), width: w * 0.095, height: h * 0.15, metal: false)
        ground(0xD6D3AE, 0xA5B588)
        channel(right: false, 0x81B8BC, highlight: 0xCEE1CC, width: w * 0.07)
        paving(0xE1D9B9, opacity: 0.6)
        for side in 0..<2 {
            for i in 0..<3 {
                planter(at: p(side == 0 ? 0.06 : 0.94, 0.74 + CGFloat(i) * 0.10), width: w * 0.11)
            }
        }
    }

    private func cave() {
        sky(0x132C47, 0x57848B)
        glow(p(0.5, 0.55), radius: w * 0.7, hex: 0x9FCBDD, opacity: 0.40)
        for side in 0..<2 {
            let x: CGFloat = side == 0 ? 0 : 1
            let direction: CGFloat = side == 0 ? 1 : -1
            let wall = polygon([p(x, 0.15), p(x + direction * 0.15, 0.28), p(x + direction * 0.08, 0.42),
                                p(x + direction * 0.20, 0.58), p(x + direction * 0.12, 0.72), p(x, 0.82)])
            fill(wall, 0x30415D, 0x59677B, from: p(x, 0.2), to: p(x, 0.85))
            for i in 0..<4 {
                let cx = x + direction * (0.025 + CGFloat(i) * 0.055)
                let stalactite = polygon([p(cx - 0.035, 0.28), p(cx + 0.04, 0.28), p(cx + 0.009, 0.40 + CGFloat(i % 2) * 0.06)])
                fill(stalactite, 0x34445C, 0x718795, from: p(cx, 0.28), to: p(cx, 0.45))
            }
        }
        ground(0x718F9A, 0x35485F)
        oval(p(0.87, 0.72), w * 0.45, h * 0.11, 0x4EABB4, opacity: 0.7)
        oval(p(0.88, 0.72), w * 0.32, h * 0.055, 0xB0E3DA, opacity: 0.35)
        for side in 0..<2 {
            for i in 0..<6 {
                crystals(at: p(side == 0 ? 0.04 : 0.96, 0.68 + CGFloat(i) * 0.065),
                         height: w * (0.12 + CGFloat(i % 3) * 0.038))
            }
        }
    }

    private func city() {
        sky(0x8DBDDD, 0xE5E9DA)
        for i in 0..<11 {
            let x = CGFloat(i) * 0.105 - 0.03
            let height = h * (0.10 + CGFloat((i * 7) % 5) * 0.022)
            building(at: p(x, 0.60), width: w * 0.095, height: height, distant: true)
        }
        building(at: p(0.07, 0.69), width: w * 0.19, height: h * 0.23, distant: false)
        building(at: p(0.94, 0.67), width: w * 0.21, height: h * 0.20, distant: false)
        clockTower(at: p(0.79, 0.63), width: w * 0.09, height: h * 0.22, metal: true)
        ground(0xC7D8DB, 0x718B9A)
        paving(0xE1EBE8, opacity: 0.46)
        for side in 0..<2 {
            for i in 0..<3 {
                lamp(at: p(side == 0 ? 0.055 : 0.945, 0.73 + CGFloat(i) * 0.11), height: w * 0.19)
            }
        }
    }

    private func timeMachine() {
        sky(0x343B65, 0xA6A9C0); stars()
        for i in 0..<3 {
            let center = p(0.5, 0.49)
            let rw = w * (0.68 + CGFloat(i) * 0.22)
            let rh = h * (0.27 + CGFloat(i) * 0.06)
            let path = Path(ellipseIn: CGRect(x: center.x - rw / 2, y: center.y - rh / 2, width: rw, height: rh))
            context.stroke(path, with: .color(c(0xDCC590).opacity(0.16 + Double(i) * 0.055)), lineWidth: w * 0.008)
        }
        glow(p(0.5, 0.48), radius: w * 0.4, hex: 0x87D5DC, opacity: 0.3)
        gear(at: p(0.05, 0.55), radius: w * 0.17)
        gear(at: p(0.95, 0.58), radius: w * 0.13)
        ground(0xA5ABB4, 0x535E76)
        paving(0xD4CCA9, opacity: 0.23)
        for side in 0..<2 {
            let x: CGFloat = side == 0 ? 0.065 : 0.935
            line([p(x, 0.72), p(x + (side == 0 ? 0.08 : -0.08), 0.80), p(x, 0.91), p(x, 1.05)], 0x6A5B56, width: w * 0.035)
            line([p(x, 0.72), p(x + (side == 0 ? 0.08 : -0.08), 0.80), p(x, 0.91), p(x, 1.05)], 0xD1AE70, width: w * 0.016)
            gear(at: p(x, 0.89), radius: w * 0.08)
        }
    }

    private func coast() {
        sky(0x76C8E2, 0xEAF0D3)
        fill(Path(CGRect(x: 0, y: h * 0.48, width: w, height: h * 0.35)), 0x5CAFBF, 0xA1DCD4, from: p(0, 0.48), to: p(0, 0.83))
        for i in 0..<24 {
            let x = CGFloat((i * 31) % 100) / 100
            let y = 0.50 + CGFloat((i * 17) % 24) / 100
            line([p(x, y), p(x + 0.06, y)], 0xDBF3DD, width: w * 0.003, opacity: 0.50)
        }
        ship(at: p(0.16, 0.58), width: w * 0.27)
        rollingHill(0.97, 0.55, 0.15, 0.04, 0x749D94)
        ground(0xF6E4B9, 0xD3AF7D, horizon: 0.70)
        // Foamy surf follows the beach rather than cutting through the reward.
        var surf = Path()
        surf.move(to: p(-0.05, 0.72)); surf.addCurve(to: p(1.05, 0.72), control1: p(0.3, 0.63), control2: p(0.7, 0.76))
        context.stroke(surf, with: .color(c(0xFFFFE8).opacity(0.8)), style: StrokeStyle(lineWidth: w * 0.015, lineCap: .round))
        palm(at: p(0.01, 0.77), height: w * 0.42)
        palm(at: p(0.99, 0.74), height: w * 0.34)
        for i in 0..<12 {
            shell(at: p(i.isMultiple(of: 2) ? 0.06 : 0.94, 0.77 + CGFloat(i % 6) * 0.045), radius: w * 0.018)
        }
    }

    private func castle() {
        sky(0x8DAACF, 0xE5E6D0)
        rollingHill(0.13, 0.56, 0.55, 0.09, 0xA3B4AF)
        rollingHill(0.85, 0.57, 0.55, 0.10, 0xBAC5AE)
        let wall = Path(CGRect(x: -w * 0.02, y: h * 0.51, width: w * 1.04, height: h * 0.17))
        fill(wall, 0xC8D0C7, 0x909EA4, from: p(0, 0.51), to: p(0, 0.68))
        for i in 0..<15 {
            let rect = CGRect(x: CGFloat(i) * w / 14, y: h * 0.485, width: w * 0.038, height: h * 0.03)
            context.fill(Path(roundedRect: rect, cornerRadius: w * 0.005), with: .color(c(0xC9D2C9)))
        }
        for side in 0..<2 {
            castleTower(at: p(side == 0 ? 0.12 : 0.88, 0.69), width: w * 0.20, height: h * 0.26)
        }
        ground(0xDCDCC8, 0xA1AAA2)
        paving(0xF0ECDD, opacity: 0.65)
        for side in 0..<2 {
            let x: CGFloat = side == 0 ? 0.04 : 0.96
            for i in 0..<3 { heraldicPost(at: p(x, 0.75 + CGFloat(i) * 0.10), height: w * 0.19) }
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
        line([at, CGPoint(x: at.x + height * 0.06, y: at.y - height * 0.8)], 0x586377, width: height * 0.10)
        for i in 0..<7 {
            let x = at.x + CGFloat(i - 3) * height * 0.12
            let top = at.y - height * (0.72 + (i % 3 == 0 ? 0.15 : 0))
            oval(CGPoint(x: x, y: top), height * 0.34, height * 0.32, i.isMultiple(of: 2) ? 0x719B96 : 0x8DB7A7)
            var strand = Path()
            strand.move(to: CGPoint(x: x, y: top))
            strand.addQuadCurve(to: CGPoint(x: x + height * 0.09, y: top + height * 0.55),
                                control: CGPoint(x: x + height * 0.15, y: top + height * 0.20))
            context.stroke(strand, with: .color(c(0x9FC9B1).opacity(0.85)), style: StrokeStyle(lineWidth: height * 0.035, lineCap: .round))
        }
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
        let wall = Path(roundedRect: CGRect(x: at.x - width / 2, y: at.y - height, width: width, height: height), cornerRadius: width * 0.04)
        fill(wall, 0xF5E8C9, 0xC9B692, from: CGPoint(x: at.x, y: at.y - height), to: at)
        let top = polygon([CGPoint(x: at.x - width * 0.62, y: at.y - height * 0.91), CGPoint(x: at.x - width * 0.03, y: at.y - height * 1.4),
                           CGPoint(x: at.x + width * 0.62, y: at.y - height * 0.91)])
        fill(top, roof, 0x915D55, from: CGPoint(x: at.x, y: at.y - height * 1.4), to: at)
        for x in [-0.27, 0.27] {
            let center = CGPoint(x: at.x + width * x, y: at.y - height * 0.6)
            oval(center, width * 0.19, height * 0.25, 0x7D9F9F)
            line([CGPoint(x: center.x, y: center.y - height * 0.13), CGPoint(x: center.x, y: center.y + height * 0.13)], 0xF3DBB3, width: 2)
        }
        context.fill(Path(roundedRect: CGRect(x: at.x - width * 0.09, y: at.y - height * 0.34, width: width * 0.18, height: height * 0.34), cornerRadius: width * 0.05), with: .color(c(0x9A785A)))
    }

    private func building(at: CGPoint, width: CGFloat, height: CGFloat, distant: Bool) {
        let rect = CGRect(x: at.x - width / 2, y: at.y - height, width: width, height: height)
        fill(Path(roundedRect: rect, cornerRadius: width * 0.06), distant ? 0xA2C4D0 : 0x83B8C4, distant ? 0x9DB5C2 : 0x527F99,
             from: CGPoint(x: at.x, y: rect.minY), to: at)
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

    func podiumSurround(foreground: Bool) {
        // Root line matches ResultRockPlanting's existing back/front frames.
        for side in 0..<2 {
            let at = p(side == 0 ? 0.11 : 0.89, foreground ? 0.93 : 0.91)
            let reach = w * (foreground ? 0.12 : 0.23)
            switch themeID {
            case 2:
                if !foreground { willow(at: at, height: reach) }
                mushroom(at: at, height: reach * 0.55)
                mushroom(at: CGPoint(x: at.x + reach * 0.28, y: at.y + 3), height: reach * 0.32)
            case 3:
                basalt(at: at, width: reach * 0.55, height: reach)
                basalt(at: CGPoint(x: at.x + reach * 0.3, y: at.y + 4), width: reach * 0.5, height: reach * 0.52)
                glow(CGPoint(x: at.x, y: at.y - reach * 0.08), radius: reach * 0.5, hex: 0xFF9E4C, opacity: 0.2)
            case 4: planter(at: at, width: reach * 0.8)
            case 5: crystals(at: at, height: reach)
            case 6:
                if foreground { oval(at, reach * 0.6, reach * 0.18, 0x647E8D) }
                else { lamp(at: at, height: reach) }
            case 8: gear(at: CGPoint(x: at.x, y: at.y - reach * 0.3), radius: reach * 0.42)
            case 9:
                if !foreground {
                    line([at, CGPoint(x: at.x + reach * 0.2, y: at.y - reach * 0.8)], 0xB7956D, width: reach * 0.08)
                    oval(CGPoint(x: at.x, y: at.y - reach * 0.15), reach * 0.7, reach * 0.35, 0xD3BB8D)
                }
                shell(at: CGPoint(x: at.x, y: at.y - reach * 0.15), radius: reach * 0.21)
            case 10:
                if !foreground { heraldicPost(at: at, height: reach) }
                else {
                    fill(Path(roundedRect: CGRect(x: at.x - reach * 0.4, y: at.y - reach * 0.3, width: reach * 0.8, height: reach * 0.35), cornerRadius: reach * 0.05),
                         0xD9DECF, 0x9EABA9, from: CGPoint(x: at.x, y: at.y - reach * 0.3), to: at)
                }
            default: break
            }
        }
    }

    /// These details are clipped to the shared stone silhouette in 1000 × 455 space.
    func podiumDetails() {
        switch themeID {
        case 3:
            for side in 0..<2 {
                let x: CGFloat = side == 0 ? 0.1 : 0.9
                let points = [p(x, 0.36), p(x + 0.025, 0.52), p(x - 0.02, 0.70), p(x + 0.01, 0.94)]
                line(points, 0xCA704F, width: w * 0.006, opacity: 0.7)
                line(points, 0xFFBB78, width: w * 0.002, opacity: 0.75)
            }
        case 5:
            for x in [CGFloat(0.08), 0.19, 0.82, 0.94] {
                line([p(x, 0.27), p(x - 0.04, 0.57), p(x + 0.015, 0.91)], 0xC1F5ED, width: w * 0.003, opacity: 0.65)
            }
        case 6, 8:
            line([p(0.05, 0.32), p(0.95, 0.32)], themeID == 6 ? 0xD3F3E9 : 0xFFE0A0, width: w * 0.008, opacity: 0.6)
            line([p(0.05, 0.89), p(0.95, 0.89)], 0x4F5E70, width: w * 0.009, opacity: 0.50)
            for x in [CGFloat(0.09), 0.22, 0.78, 0.91] {
                for y in [CGFloat(0.38), 0.83] {
                    oval(p(x, y), w * 0.015, w * 0.015, 0x405A68, opacity: 0.6)
                    oval(p(x - 0.001, y - 0.003), w * 0.010, w * 0.010, themeID == 6 ? 0xC8E9DB : 0xE8CD91)
                }
            }
        case 9:
            for i in 0..<5 {
                let y = 0.34 + CGFloat(i) * 0.11
                line([p(0.02, y), p(0.28, y + 0.015), p(0.67, y - 0.01), p(0.98, y + 0.025)], 0xE8D1A4, width: w * 0.0025, opacity: 0.5)
            }
        case 10:
            for y in [CGFloat(0.36), 0.64, 0.91] {
                line([p(0.02, y), p(0.98, y)], 0x6F8492, width: w * 0.002, opacity: 0.35)
            }
            for x in [CGFloat(0.16), 0.4, 0.68, 0.88] { line([p(x, 0.37), p(x, 0.63)], 0x6F8492, width: w * 0.002, opacity: 0.35) }
        default: break
        }
    }
}
