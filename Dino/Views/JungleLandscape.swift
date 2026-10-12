import SwiftUI

/// Each ten-level section can supply its own palette. The last part blends into
/// the next section's palette, so adjoining worlds share the same horizon.
struct WorldLandscapePalette {
    var ground: UInt32
    var distant: UInt32
    var foliage: UInt32
    var shade: UInt32
    var rock: UInt32

    static let jungle = Self(ground: 0xDDEEB6, distant: 0xABCFA0, foliage: 0x6FAE52,
                             shade: 0x2E7356, rock: 0x96AB7B)
    // A quiet horizon preview; replace this with the eventual world's palette.
    static let nextHorizon = Self(ground: 0xDEEEDC, distant: 0xB1D4D0, foliage: 0x8DBAA8,
                                  shade: 0x578F8B, rock: 0xA9C5BE)

    func color(_ key: KeyPath<Self, UInt32>, toward next: Self, progress: CGFloat) -> Color {
        let a = self[keyPath: key], b = next[keyPath: key]
        let t = Double(min(1, max(0, progress)))
        func channel(_ shift: UInt32) -> Double {
            let start = Double((a >> shift) & 255), end = Double((b >> shift) & 255)
            return (start + (end - start) * t) / 255
        }
        return Color(red: channel(16), green: channel(8), blue: channel(0))
    }
}

/// All landscape artwork is drawn from paths, ellipses and rounded rectangles.
/// One static canvas keeps the long scrolling map inexpensive to render.
struct WorldMapLandscape: View {
    var palette = WorldLandscapePalette.jungle
    var nextPalette = WorldLandscapePalette.nextHorizon
    var routeOffset: CGFloat = 0

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let left = max(0, (w - 650) / 2)
            let right = w - left
            let height = size.height - routeOffset
            let scale = min(1.35, max(0.82, w / 390))
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                Gradient(stops: [
                    .init(color: Color(dinoHex: 0xE7F1BD), location: 0),
                    .init(color: Color(dinoHex: palette.ground), location: 0.38),
                    .init(color: Color(dinoHex: 0xD4E6AD), location: 0.72),
                    .init(color: Color(dinoHex: nextPalette.ground), location: 1)
                ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))

            let sky = JunglePainter(context: context)
            sky.ellipse(CGRect(x: w * 0.70, y: 12, width: 92, height: 92), color: Color(dinoHex: 0xFFF4C4).opacity(0.75))
            sky.hill(x: -w * 0.45, y: 75, width: w, height: 340, color: Color(dinoHex: 0xB4D69D).opacity(0.30))
            sky.hill(x: w * 0.65, y: 130, width: w * 0.7, height: 330, color: Color(dinoHex: 0xAACF93).opacity(0.22))
            sky.bush(at: CGPoint(x: left - 12, y: 64), size: 0.85)
            sky.bush(at: CGPoint(x: right + 18, y: 85), size: 1.0)
            sky.vine(from: CGPoint(x: left + 13, y: 0), length: 122, bend: 20)
            sky.vine(from: CGPoint(x: right - 16, y: 0), length: 94, bend: -20)
            var routeContext = context
            routeContext.translateBy(x: 0, y: routeOffset)
            let painter = JunglePainter(context: routeContext)

            // Rolling clearings alternate sides of the trail instead of repeating
            // a decorative wallpaper behind every level.
            for index in 0..<7 {
                let y = CGFloat(index) * 310 - 80
                let blend = transition(at: y, height: height)
                let left = index.isMultiple(of: 2)
                let distant = palette.color(\.distant, toward: nextPalette, progress: blend)
                let foliage = palette.color(\.foliage, toward: nextPalette, progress: blend)
                painter.hill(x: left ? -w * 0.3 : w * 0.44, y: y, width: w * 0.95,
                             height: 290, color: distant.opacity(0.45))
                painter.hill(x: left ? w * 0.6 : -w * 0.52, y: y + 115, width: w * 0.92,
                             height: 230, color: foliage.opacity(0.17))
                // Small grasses and stone clusters sit inside the clearing.
                for tuft in 0..<5 {
                    let x = w * (CGFloat(tuft) * 0.20 + 0.035)
                    painter.grass(at: CGPoint(x: x, y: y + 210 + CGFloat(tuft % 2) * 32),
                                  size: 9 * scale, color: foliage.opacity(0.5))
                }
            }

            // Tall trees, layered crowns and hanging vines frame the entrance.
            painter.tree(at: CGPoint(x: left - 6, y: 305), size: 1.18 * scale, leaning: 1)
            painter.tree(at: CGPoint(x: right + 14, y: 370), size: 1.30 * scale, leaning: -1)
            painter.vine(from: CGPoint(x: left + 30, y: 0), length: 160, bend: 28)
            painter.vine(from: CGPoint(x: right - 28, y: 10), length: 190, bend: -32)
            painter.bush(at: CGPoint(x: left + 5, y: 320), size: 1.0 * scale)
            painter.fern(at: CGPoint(x: right - 15, y: 450), size: 0.9 * scale, flipped: true)
            painter.flowers(at: CGPoint(x: left + 38, y: 405), size: scale)

            // A rocky waterfall and a lagoon make the middle of the world a
            // distinct destination. Water stays at the edge of the playable path.
            painter.waterfall(at: CGPoint(x: right - 35 * scale, y: 525), size: scale)
            painter.palm(at: CGPoint(x: left + 13, y: 785), size: 0.96 * scale, flipped: false)
            painter.fern(at: CGPoint(x: left + 8, y: 885), size: 1.13 * scale, flipped: false)
            painter.flowers(at: CGPoint(x: right - 42, y: 965), size: 0.9 * scale)

            // Deeper jungle: buttress roots, large leaves, mossy boulders.
            painter.tree(at: CGPoint(x: left - 25, y: 1250), size: 1.02 * scale, leaning: 1)
            painter.palm(at: CGPoint(x: right + 4, y: 1370), size: 1.05 * scale, flipped: true)
            painter.rocks(at: CGPoint(x: right - 25, y: 1382), size: 0.92 * scale)
            painter.bush(at: CGPoint(x: left + 15, y: 1320), size: 1.05 * scale)
            painter.fern(at: CGPoint(x: right - 8, y: 1470), size: 1.2 * scale, flipped: true)
            painter.flowers(at: CGPoint(x: left + 40, y: 1475), size: scale)
            painter.rocks(at: CGPoint(x: left + 14, y: 1635), size: 1.15 * scale)
            painter.bush(at: CGPoint(x: right - 6, y: 1720), size: 0.8 * scale)

            // The boss clearing opens into mist. Low silhouettes and the soft
            // color blend continue below level ten into the next world preview.
            for i in 0..<3 {
                let y = height - 390 + CGFloat(i) * 105
                painter.hill(x: i.isMultiple(of: 2) ? -w * 0.28 : w * 0.5,
                             y: y, width: w * 0.82, height: 195,
                             color: palette.color(\.distant, toward: nextPalette, progress: CGFloat(i + 1) / 3).opacity(0.44))
            }
            painter.rocks(at: CGPoint(x: left + 29, y: 1910), size: scale * 0.9)
            painter.fern(at: CGPoint(x: left + 45, y: 1916), size: scale * 0.45, flipped: false)
            painter.rocks(at: CGPoint(x: right - 28, y: 1940), size: scale * 0.8)
            painter.fern(at: CGPoint(x: right - 43, y: 1945), size: scale * 0.40, flipped: true)
            context.fill(Path(CGRect(x: 0, y: size.height - 240, width: w, height: 240)),
                         with: .linearGradient(Gradient(colors: [Color(dinoHex: nextPalette.ground).opacity(0),
                                                                 Color(dinoHex: nextPalette.ground)]),
                                               startPoint: CGPoint(x: 0, y: size.height - 240),
                                               endPoint: CGPoint(x: 0, y: size.height)))
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }

    private func transition(at y: CGFloat, height: CGFloat) -> CGFloat {
        let t = min(1, max(0, (y - (height - 560)) / 560))
        return t * t * (3 - 2 * t)
    }
}

/// Lightweight, shape-only distant scenery for headings and quieter game screens.
struct JungleVista: View {
    var quiet = false
    var body: some View {
        Canvas { context, size in
            let p = JunglePainter(context: context)
            let w = size.width, h = size.height
            p.ellipse(CGRect(x: w * 0.61, y: 40, width: 115, height: 115), color: Color(dinoHex: 0xFFF5C9).opacity(quiet ? 0.3 : 0.8))
            for i in 0..<3 {
                p.hill(x: i.isMultiple(of: 2) ? -w * 0.4 : w * 0.30,
                       y: h * 0.48 + CGFloat(i) * 65, width: w * 1.1, height: h * 0.65,
                       color: Color(dinoHex: i == 0 ? 0xB6D7AD : 0x9FCB97).opacity(quiet ? 0.10 : 0.34))
            }
            if !quiet {
                p.bush(at: CGPoint(x: -14, y: 110), size: 1.2)
                p.bush(at: CGPoint(x: w + 19, y: 155), size: 1.3)
                p.vine(from: CGPoint(x: w * 0.06, y: 0), length: 175, bend: 20)
                p.vine(from: CGPoint(x: w * 0.94, y: 0), length: 110, bend: -16)
            } else {
                p.fern(at: CGPoint(x: -28, y: h + 24), size: 1.3, flipped: false, opacity: 0.12)
                p.fern(at: CGPoint(x: w + 28, y: h + 24), size: 1.3, flipped: true, opacity: 0.12)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct JunglePainter {
    let context: GraphicsContext
    private let dark = Color(dinoHex: 0x2E7356)
    private let green = Color(dinoHex: 0x6FAE52)
    private let light = Color(dinoHex: 0xA4CD68)

    func ellipse(_ rect: CGRect, color: Color) { context.fill(Path(ellipseIn: rect), with: .color(color)) }

    func hill(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: Color) {
        var path = Path()
        path.move(to: CGPoint(x: x, y: y + height * 0.65))
        path.addCurve(to: CGPoint(x: x + width * 0.50, y: y + height * 0.07),
                      control1: CGPoint(x: x + width * 0.07, y: y + height * 0.07),
                      control2: CGPoint(x: x + width * 0.30, y: y - height * 0.08))
        path.addCurve(to: CGPoint(x: x + width, y: y + height * 0.65),
                      control1: CGPoint(x: x + width * 0.85, y: y + height * 0.12),
                      control2: CGPoint(x: x + width * 1.09, y: y + height * 0.35))
        path.addCurve(to: CGPoint(x: x + width * 0.52, y: y + height),
                      control1: CGPoint(x: x + width * 0.90, y: y + height * 1.10),
                      control2: CGPoint(x: x + width * 0.70, y: y + height))
        path.addCurve(to: CGPoint(x: x, y: y + height * 0.65),
                      control1: CGPoint(x: x + width * 0.22, y: y + height * 1.02),
                      control2: CGPoint(x: x - width * 0.10, y: y + height * 0.95))
        path.closeSubpath()
        context.fill(path, with: .color(color))
    }

    func leaf(at point: CGPoint, length: CGFloat, width: CGFloat, angle: Double, color: Color, vein: Bool = true) {
        var c = context
        c.translateBy(x: point.x, y: point.y)
        c.rotate(by: .degrees(angle))
        var leaf = Path()
        leaf.move(to: .zero)
        leaf.addCurve(to: CGPoint(x: 0, y: -length), control1: CGPoint(x: -width, y: -length * 0.32),
                      control2: CGPoint(x: -width * 0.58, y: -length * 0.89))
        leaf.addCurve(to: .zero, control1: CGPoint(x: width * 0.66, y: -length * 0.83),
                      control2: CGPoint(x: width, y: -length * 0.24))
        c.fill(leaf, with: .color(color))
        if vein {
            var line = Path()
            line.move(to: .zero)
            line.addQuadCurve(to: CGPoint(x: 0, y: -length * 0.84), control: CGPoint(x: width * 0.1, y: -length * 0.45))
            c.stroke(line, with: .color(.white.opacity(0.20)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        }
    }

    /// Scalloped, asymmetrical foliage silhouettes instead of rows of circles.
    private func foliagePath(in r: CGRect) -> Path {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height)
        }
        return Path { p in
            p.move(to: pt(0.07, 0.69))
            p.addCurve(to: pt(0.05, 0.35), control1: pt(-0.04, 0.60), control2: pt(-0.03, 0.40))
            p.addCurve(to: pt(0.27, 0.16), control1: pt(0.02, 0.19), control2: pt(0.15, 0.10))
            p.addCurve(to: pt(0.56, 0.07), control1: pt(0.32, -0.02), control2: pt(0.48, -0.06))
            p.addCurve(to: pt(0.80, 0.19), control1: pt(0.62, -0.01), control2: pt(0.79, 0.01))
            p.addCurve(to: pt(0.96, 0.48), control1: pt(0.97, 0.16), control2: pt(1.05, 0.34))
            p.addCurve(to: pt(0.92, 0.80), control1: pt(1.05, 0.60), control2: pt(1.00, 0.75))
            p.addCurve(to: pt(0.62, 0.93), control1: pt(0.88, 0.98), control2: pt(0.73, 1.03))
            p.addCurve(to: pt(0.31, 0.91), control1: pt(0.50, 1.04), control2: pt(0.36, 1.00))
            p.addCurve(to: pt(0.07, 0.69), control1: pt(0.10, 1.00), control2: pt(0.02, 0.87))
            p.closeSubpath()
        }
    }

    private func foliage(in r: CGRect, color: Color, highlights: Bool = true) {
        context.fill(foliagePath(in: r), with: .color(color))
        if highlights {
            // Small leaf pairs belong to the crown, rather than separate blobs.
            for i in 0..<3 {
                let at = CGPoint(x: r.minX + r.width * (0.27 + CGFloat(i) * 0.21),
                                 y: r.minY + r.height * (0.30 + CGFloat(i % 2) * 0.13))
                leaf(at: at, length: r.width * 0.095, width: r.width * 0.033,
                     angle: Double(-40 + i * 25), color: light.opacity(0.35), vein: false)
                leaf(at: at, length: r.width * 0.075, width: r.width * 0.025,
                     angle: Double(45 + i * 18), color: light.opacity(0.24), vein: false)
            }
        }
    }

    func bush(at point: CGPoint, size: CGFloat) {
        ellipse(CGRect(x: point.x - 58 * size, y: point.y - 5 * size, width: 116 * size, height: 17 * size), color: dark.opacity(0.10))
        foliage(in: CGRect(x: point.x - 57 * size, y: point.y - 46 * size, width: 79 * size, height: 47 * size), color: dark)
        foliage(in: CGRect(x: point.x - 9 * size, y: point.y - 62 * size, width: 67 * size, height: 60 * size), color: Color(dinoHex: 0x4F905B))
        foliage(in: CGRect(x: point.x - 36 * size, y: point.y - 47 * size, width: 75 * size, height: 50 * size), color: green)
        for i in 0..<3 {
            leaf(at: CGPoint(x: point.x + CGFloat(i - 1) * 19 * size, y: point.y - 6 * size),
                 length: CGFloat(25 + i * 4) * size, width: 8 * size,
                 angle: Double(i * 38 - 45), color: light.opacity(0.65))
        }
    }

    func fern(at point: CGPoint, size: CGFloat, flipped: Bool, opacity: Double = 1) {
        var c = context
        c.opacity = opacity
        let p = JunglePainter(context: c)
        let direction: CGFloat = flipped ? -1 : 1
        for frond in 0..<5 {
            let reach = CGFloat(frond - 2) * 30 * size * direction
            let height = CGFloat(88 - abs(frond - 2) * 20) * size
            var stem = Path()
            stem.move(to: point)
            stem.addQuadCurve(to: CGPoint(x: point.x + reach, y: point.y - height),
                              control: CGPoint(x: point.x, y: point.y - height))
            c.stroke(stem, with: .color(dark), style: StrokeStyle(lineWidth: 1.4 * size, lineCap: .round))
            for pair in 1...7 {
                let t = CGFloat(pair) / 8
                let origin = CGPoint(x: point.x + reach * t * t, y: point.y - height * (2 * t - t * t))
                let angle = atan2(2 * reach * t, 2 * height * (1 - t)) * 180 / .pi
                for side in [-1.0, 1.0] {
                    p.leaf(at: origin, length: (18 - t * 12) * size, width: (4.2 - t * 2) * size,
                           angle: Double(angle) + side * 61,
                           color: frond.isMultiple(of: 2) ? dark : green, vein: false)
                }
            }
        }
    }

    func tree(at base: CGPoint, size: CGFloat, leaning: CGFloat) {
        let crown = CGPoint(x: base.x + leaning * 21 * size, y: base.y - 240 * size)
        ellipse(CGRect(x: base.x - 44 * size, y: base.y - 5 * size, width: 88 * size, height: 18 * size), color: dark.opacity(0.12))
        var trunk = Path()
        trunk.move(to: CGPoint(x: base.x - 34 * size, y: base.y + 3 * size))
        trunk.addCurve(to: CGPoint(x: crown.x - 11 * size, y: crown.y + 10 * size),
                       control1: CGPoint(x: base.x - 7 * size, y: base.y - 25 * size),
                       control2: CGPoint(x: base.x - 5 * size, y: base.y - 150 * size))
        trunk.addLine(to: CGPoint(x: crown.x + 13 * size, y: crown.y + 8 * size))
        trunk.addCurve(to: CGPoint(x: base.x + 34 * size, y: base.y + 2 * size),
                       control1: CGPoint(x: base.x + 21 * size, y: base.y - 145 * size),
                       control2: CGPoint(x: base.x + 10 * size, y: base.y - 19 * size))
        trunk.addQuadCurve(to: CGPoint(x: base.x - 34 * size, y: base.y + 3 * size),
                           control: CGPoint(x: base.x, y: base.y - 3 * size))
        trunk.closeSubpath()
        context.fill(trunk, with: .color(Color(dinoHex: 0x92774F)))
        // A fork and tapered roots make the crown and trunk read as one tree.
        for side in [-1.0, 1.0] {
            var branch = Path()
            branch.move(to: CGPoint(x: base.x + 4 * size, y: base.y - 137 * size))
            branch.addQuadCurve(to: CGPoint(x: crown.x + CGFloat(side) * 55 * size, y: crown.y - 8 * size),
                                control: CGPoint(x: crown.x + CGFloat(side) * 26 * size, y: crown.y + 71 * size))
            context.stroke(branch, with: .color(Color(dinoHex: 0x92774F)), style: StrokeStyle(lineWidth: 11 * size, lineCap: .round))
        }
        var bark = Path()
        bark.move(to: CGPoint(x: base.x + 11 * size, y: base.y - 12 * size))
        bark.addQuadCurve(to: CGPoint(x: crown.x + 5 * size, y: crown.y + 56 * size),
                          control: CGPoint(x: base.x + 6 * size, y: base.y - 97 * size))
        context.stroke(bark, with: .color(Color(dinoHex: 0xB59A67)), style: StrokeStyle(lineWidth: 4 * size, lineCap: .round))
        foliage(in: CGRect(x: crown.x - 94 * size, y: crown.y - 42 * size, width: 185 * size, height: 100 * size), color: dark, highlights: false)
        foliage(in: CGRect(x: crown.x - 94 * size, y: crown.y - 34 * size, width: 100 * size, height: 83 * size), color: Color(dinoHex: 0x58955B))
        foliage(in: CGRect(x: crown.x - 20 * size, y: crown.y - 53 * size, width: 118 * size, height: 89 * size), color: green)
        foliage(in: CGRect(x: crown.x - 52 * size, y: crown.y - 4 * size, width: 104 * size, height: 71 * size), color: Color(dinoHex: 0x7CAE61))
        fern(at: CGPoint(x: base.x - leaning * 17 * size, y: base.y + 7 * size), size: size * 0.55, flipped: leaning < 0)
    }

    private func palmFrond(from point: CGPoint, reach: CGFloat, drop: CGFloat, lift: CGFloat, size: CGFloat, color: Color) {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: point.x + x * size, y: point.y + y * size) }
        var frond = Path()
        frond.move(to: point)
        frond.addCurve(to: pt(reach, drop), control1: pt(reach * 0.24, -lift),
                       control2: pt(reach * 0.76, -lift * 0.72))
        frond.addCurve(to: point, control1: pt(reach * 0.80, drop - 5),
                       control2: pt(reach * 0.36, -lift + 25))
        frond.closeSubpath()
        context.fill(frond, with: .color(color))
        var vein = Path()
        vein.move(to: point)
        vein.addCurve(to: pt(reach * 0.96, drop * 0.92), control1: pt(reach * 0.29, -lift * 0.69),
                      control2: pt(reach * 0.71, -lift * 0.42))
        context.stroke(vein, with: .color(light.opacity(0.35)), style: StrokeStyle(lineWidth: 1.2 * size, lineCap: .round))
    }

    func palm(at base: CGPoint, size: CGFloat, flipped: Bool) {
        let direction: CGFloat = flipped ? -1 : 1
        let top = CGPoint(x: base.x + direction * 32 * size, y: base.y - 172 * size)
        var stem = Path()
        stem.move(to: base)
        stem.addQuadCurve(to: top, control: CGPoint(x: base.x - direction * 4 * size, y: base.y - 121 * size))
        context.stroke(stem, with: .color(Color(dinoHex: 0x987E53)), style: StrokeStyle(lineWidth: 13 * size, lineCap: .round))
        var highlight = context
        highlight.translateBy(x: -3 * direction * size, y: 0)
        highlight.stroke(stem, with: .color(Color(dinoHex: 0xBCA06D)), style: StrokeStyle(lineWidth: 4 * size, lineCap: .round))
        let fronds: [(CGFloat, CGFloat, CGFloat)] = [(-104, 36, 44), (107, 37, 40), (-96, 4, 54),
                                                       (85, -12, 48), (-68, -32, 55), (35, -54, 53), (-23, -65, 50)]
        for (i, frond) in fronds.enumerated() {
            palmFrond(from: top, reach: frond.0 * direction, drop: frond.1, lift: frond.2,
                      size: size, color: i < 2 ? dark : i.isMultiple(of: 2) ? green : Color(dinoHex: 0x56955E))
        }
        ellipse(CGRect(x: top.x - 7 * size, y: top.y - 1 * size, width: 12 * size, height: 13 * size), color: Color(dinoHex: 0x90724C))
    }

    func vine(from start: CGPoint, length: CGFloat, bend: CGFloat) {
        var vine = Path()
        vine.move(to: start)
        vine.addCurve(to: CGPoint(x: start.x + bend * 0.55, y: start.y + length),
                      control1: CGPoint(x: start.x + bend, y: start.y + length * 0.2),
                      control2: CGPoint(x: start.x - bend * 0.4, y: start.y + length * 0.7))
        context.stroke(vine, with: .color(dark.opacity(0.7)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        for i in 1...4 {
            leaf(at: CGPoint(x: start.x + bend * 0.3, y: start.y + CGFloat(i) * length / 5),
                 length: 23, width: 8, angle: i.isMultiple(of: 2) ? 65 : -65, color: green)
        }
    }

    /// Rounded corners retain a rock's uneven planes instead of forming a cylinder.
    private func roundedOutline(_ points: [CGPoint], rounding: CGFloat = 0.18) -> Path {
        guard points.count > 2 else { return Path() }
        func between(_ a: CGPoint, _ b: CGPoint, fraction: CGFloat) -> CGPoint {
            CGPoint(x: a.x + (b.x - a.x) * fraction, y: a.y + (b.y - a.y) * fraction)
        }
        return Path { p in
            p.move(to: between(points[0], points[points.count - 1], fraction: rounding))
            for i in points.indices {
                let previous = points[(i + points.count - 1) % points.count]
                let next = points[(i + 1) % points.count]
                p.addLine(to: between(points[i], previous, fraction: rounding))
                p.addQuadCurve(to: between(points[i], next, fraction: rounding), control: points[i])
            }
            p.closeSubpath()
        }
    }

    private func boulder(in r: CGRect, moss: Bool) {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        ellipse(CGRect(x: r.minX, y: r.maxY - r.height * 0.17, width: r.width, height: r.height * 0.28), color: dark.opacity(0.13))
        let stone = roundedOutline([pt(0.05, 0.66), pt(0.09, 0.32), pt(0.30, 0.09), pt(0.57, 0.05),
                                    pt(0.86, 0.24), pt(0.98, 0.61), pt(0.83, 0.86), pt(0.53, 0.97), pt(0.18, 0.90)])
        context.fill(stone, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xB4BDAB), Color(dinoHex: 0x7F9584)]),
                                                  startPoint: pt(0.2, 0), endPoint: pt(0.8, 1)))
        context.fill(roundedOutline([pt(0.60, 0.21), pt(0.91, 0.42), pt(0.88, 0.81), pt(0.54, 0.93), pt(0.44, 0.65)]),
                     with: .color(Color(dinoHex: 0x6A8378).opacity(0.32)))
        if moss {
            let patch = roundedOutline([pt(0.08, 0.48), pt(0.17, 0.26), pt(0.33, 0.14), pt(0.53, 0.21),
                                        pt(0.68, 0.19), pt(0.83, 0.34), pt(0.67, 0.43), pt(0.51, 0.34),
                                        pt(0.40, 0.44), pt(0.27, 0.34), pt(0.15, 0.52)])
            context.fill(patch, with: .color(Color(dinoHex: 0x739759)))
        }
    }

    func rocks(at point: CGPoint, size: CGFloat) {
        boulder(in: CGRect(x: point.x - 47 * size, y: point.y - 27 * size, width: 43 * size, height: 30 * size), moss: false)
        boulder(in: CGRect(x: point.x - 20 * size, y: point.y - 36 * size, width: 55 * size, height: 40 * size), moss: true)
        boulder(in: CGRect(x: point.x + 24 * size, y: point.y - 17 * size, width: 30 * size, height: 23 * size), moss: true)
    }

    func waterfall(at point: CGPoint, size: CGFloat) {
        var c = context
        c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: size, y: size)
        let p = JunglePainter(context: c)
        // The shallow pool lies below the cliff; its uneven bank follows the shore.
        let pool = p.roundedOutline([CGPoint(x: -78, y: 103), CGPoint(x: -63, y: 79), CGPoint(x: -12, y: 66),
                                    CGPoint(x: 55, y: 73), CGPoint(x: 91, y: 96), CGPoint(x: 69, y: 124),
                                    CGPoint(x: 14, y: 135), CGPoint(x: -44, y: 128)], rounding: 0.4)
        c.fill(pool, with: .color(Color(dinoHex: 0xA8C6A1)))
        let waterSurface = p.roundedOutline([CGPoint(x: -68, y: 102), CGPoint(x: -50, y: 82), CGPoint(x: -7, y: 73),
                                            CGPoint(x: 52, y: 81), CGPoint(x: 79, y: 99), CGPoint(x: 58, y: 118),
                                            CGPoint(x: 12, y: 126), CGPoint(x: -36, y: 121)], rounding: 0.4)
        c.fill(waterSurface, with: .color(Color(dinoHex: 0x73B7BD)))
        let cliff = p.roundedOutline([CGPoint(x: -55, y: 77), CGPoint(x: -58, y: 32), CGPoint(x: -47, y: 7),
                                     CGPoint(x: -50, y: -35), CGPoint(x: -31, y: -91), CGPoint(x: -14, y: -113),
                                     CGPoint(x: 45, y: -109), CGPoint(x: 70, y: -79), CGPoint(x: 67, y: -34),
                                     CGPoint(x: 89, y: -11), CGPoint(x: 86, y: 40), CGPoint(x: 70, y: 87),
                                     CGPoint(x: 22, y: 92)], rounding: 0.12)
        c.fill(cliff, with: .color(Color(dinoHex: 0x98AB96)))
        let shadowPlane = p.roundedOutline([CGPoint(x: 40, y: -102), CGPoint(x: 66, y: -71), CGPoint(x: 61, y: -32),
                                            CGPoint(x: 83, y: -9), CGPoint(x: 80, y: 39), CGPoint(x: 65, y: 86),
                                            CGPoint(x: 36, y: 85), CGPoint(x: 44, y: 16)], rounding: 0.12)
        c.fill(shadowPlane, with: .color(Color(dinoHex: 0x7D9786)))
        let lightPlane = p.roundedOutline([CGPoint(x: -31, y: -72), CGPoint(x: -14, y: -99), CGPoint(x: 10, y: -97),
                                           CGPoint(x: -1, y: -12), CGPoint(x: -18, y: 64), CGPoint(x: -32, y: 73)])
        c.fill(lightPlane, with: .color(Color(dinoHex: 0xB2BFA5)))
        for i in 0..<3 {
            var fissure = Path()
            fissure.move(to: CGPoint(x: 41, y: -63 + CGFloat(i) * 46))
            fissure.addLine(to: CGPoint(x: 57, y: -55 + CGFloat(i) * 46))
            fissure.addLine(to: CGPoint(x: 70, y: -57 + CGFloat(i) * 46))
            c.stroke(fissure, with: .color(Color(dinoHex: 0x678678).opacity(0.4)),
                     style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round))
        }
        for i in 0..<3 {
            var crack = Path()
            crack.move(to: CGPoint(x: -35, y: -44 + CGFloat(i) * 40))
            crack.addLine(to: CGPoint(x: -20, y: -37 + CGFloat(i) * 40))
            crack.addLine(to: CGPoint(x: -6, y: -41 + CGFloat(i) * 40))
            c.stroke(crack, with: .color(Color(dinoHex: 0x718E7D).opacity(0.25)),
                     style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
        }
        let mossLip = p.roundedOutline([CGPoint(x: -30, y: -97), CGPoint(x: -15, y: -111),
                                       CGPoint(x: 36, y: -108), CGPoint(x: 50, y: -100), CGPoint(x: 28, y: -99),
                                       CGPoint(x: 16, y: -103), CGPoint(x: -4, y: -97), CGPoint(x: -19, y: -101)])
        c.fill(mossLip, with: .color(Color(dinoHex: 0x81A761)))
        // A small visible stream feeds the lip; water widens as it reaches the pool.
        var source = Path()
        source.move(to: CGPoint(x: 56, y: -116))
        source.addCurve(to: CGPoint(x: 5, y: -107), control1: CGPoint(x: 27, y: -128), control2: CGPoint(x: 26, y: -104))
        c.stroke(source, with: .color(Color(dinoHex: 0x8AC8CB)), style: StrokeStyle(lineWidth: 11, lineCap: .round))
        var fall = Path()
        fall.move(to: CGPoint(x: -8, y: -106))
        fall.addCurve(to: CGPoint(x: 1, y: 83), control1: CGPoint(x: -10, y: -48), control2: CGPoint(x: -1, y: 51))
        fall.addQuadCurve(to: CGPoint(x: 27, y: 84), control: CGPoint(x: 14, y: 95))
        fall.addCurve(to: CGPoint(x: 18, y: -107), control1: CGPoint(x: 26, y: 45), control2: CGPoint(x: 11, y: -44))
        fall.closeSubpath()
        c.fill(fall, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xA5D6D9), Color(dinoHex: 0xDAEFDF)]),
                                             startPoint: CGPoint(x: 0, y: -106), endPoint: CGPoint(x: 0, y: 90)))
        for i in 0..<2 {
            var streak = Path()
            let x = CGFloat(i) * 10 - 2
            streak.move(to: CGPoint(x: x, y: i == 0 ? -85 : -24))
            streak.addCurve(to: CGPoint(x: x + 7, y: i == 0 ? 18 : 72),
                            control1: CGPoint(x: x - 2, y: i == 0 ? -45 : 5),
                            control2: CGPoint(x: x + 2, y: i == 0 ? -11 : 39))
            c.stroke(streak, with: .color(.white.opacity(0.55)), style: StrokeStyle(lineWidth: i == 0 ? 2.3 : 1.4, lineCap: .round))
        }
        for i in 0..<6 {
            p.ellipse(CGRect(x: -8 + CGFloat(i) * 5, y: 83 + CGFloat(i % 3) * 3,
                             width: 10 + CGFloat(i % 2) * 3, height: 5), color: Color(dinoHex: 0xE2F3E6))
        }
        for i in 0..<2 {
            var ripple = Path()
            ripple.addArc(center: CGPoint(x: 10, y: 95), radius: CGFloat(23 + i * 12),
                          startAngle: .degrees(20), endAngle: .degrees(148), clockwise: false)
            var flattened = c
            flattened.translateBy(x: 0, y: 66)
            flattened.scaleBy(x: 1, y: 0.35)
            flattened.stroke(ripple, with: .color(Color(dinoHex: 0xB9DFD4).opacity(0.85)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        p.bush(at: CGPoint(x: 69, y: -103), size: 0.53)
        p.fern(at: CGPoint(x: -32, y: -101), size: 0.32, flipped: false)
        p.boulder(in: CGRect(x: -57, y: 66, width: 40, height: 29), moss: true)
        p.rocks(at: CGPoint(x: 56, y: 127), size: 0.52)
    }

    func grass(at point: CGPoint, size: CGFloat, color: Color) {
        var grass = Path()
        grass.move(to: CGPoint(x: point.x - size, y: point.y))
        grass.addQuadCurve(to: CGPoint(x: point.x - size * 0.7, y: point.y - size), control: CGPoint(x: point.x - size * 0.2, y: point.y))
        grass.move(to: point)
        grass.addQuadCurve(to: CGPoint(x: point.x + size * 0.2, y: point.y - size * 1.3), control: CGPoint(x: point.x - size * 0.1, y: point.y - size * 0.6))
        grass.move(to: CGPoint(x: point.x + size * 0.4, y: point.y))
        grass.addQuadCurve(to: CGPoint(x: point.x + size, y: point.y - size * 0.65), control: CGPoint(x: point.x + size * 0.4, y: point.y - size * 0.4))
        context.stroke(grass, with: .color(color), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }

    func flowers(at point: CGPoint, size: CGFloat) {
        for i in 0..<3 {
            let origin = CGPoint(x: point.x + CGFloat(i - 1) * 16 * size, y: point.y - CGFloat(i % 2) * 13 * size)
            var stem = Path()
            stem.move(to: CGPoint(x: origin.x, y: point.y + 12 * size))
            stem.addLine(to: origin)
            context.stroke(stem, with: .color(dark), lineWidth: 2 * size)
            for petal in 0..<5 {
                let angle = Double(petal) * .pi * 2 / 5
                ellipse(CGRect(x: origin.x + CGFloat(cos(angle)) * 5 * size - 4 * size,
                               y: origin.y + CGFloat(sin(angle)) * 5 * size - 4 * size,
                               width: 8 * size, height: 8 * size), color: Color(dinoHex: i == 1 ? 0xF0BC74 : 0xF3D491))
            }
            ellipse(CGRect(x: origin.x - 3 * size, y: origin.y - 3 * size, width: 6 * size, height: 6 * size), color: Color(dinoHex: 0xFFF5D3))
        }
    }

}
