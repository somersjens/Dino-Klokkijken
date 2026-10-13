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
    static let nextHorizon = Self(ground: 0xDCD6F7, distant: 0xB2B4D7, foliage: 0x9CCBB8,
                                  shade: 0x596A99, rock: 0xA9A5BE)

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


// MARK: - Shape-drawn chapters

struct WorldThemeColors {
    let ground: UInt32
    let accent: UInt32
    let distant: UInt32
    let shade: UInt32
    init(_ world: DinoWorld) {
        ground = world.ground
        switch world.id {
        case 2: (accent, distant, shade) = (0x9CCBB8, 0xB2B4D7, 0x596A99)
        case 3: (accent, distant, shade) = (0xF47C65, 0xE4A688, 0x706778)
        case 4: (accent, distant, shade) = (0xD98663, 0xAAD9B8, 0x6C8561)
        case 5: (accent, distant, shade) = (0xA493D7, 0x9CCBD0, 0x427D89)
        case 6: (accent, distant, shade) = (0x54BCC5, 0x94C8DC, 0x537D93)
        case 7: (accent, distant, shade) = (0x8CC68C, 0xAA99CC, 0x526894)
        case 8: (accent, distant, shade) = (0xD9B46C, 0xB5A6E6, 0x597D88)
        case 9: (accent, distant, shade) = (0x63C7CB, 0xABDDE1, 0xA47757)
        default: (accent, distant, shade) = (0x789BCF, 0xB9CCA8, 0x8D867A)
        }
    }
}

/// All scenery is native Canvas geometry. Generated concepts are documentation only.
struct ThemedWorldLandscape: View {
    let world: DinoWorld
    var routeOffset: CGFloat = 180

    var body: some View {
        Canvas { context, size in
            let colors = WorldThemeColors(world)
            let w = size.width
            let left = max(0, (w - 650) / 2)
            let right = w - left
            let scale = min(1.30, max(0.82, w / 390))
            let nextGround = DinoWorldCatalog.world(world.id + 1)?.ground ?? world.ground
            let ground = Color(dinoHex: colors.ground)
            var stops = [
                Gradient.Stop(color: ground, location: 0),
                .init(color: ground, location: 0.75),
                .init(color: Color(dinoHex: nextGround), location: 1)
            ]
            if world.id == 7 {
                stops = [.init(color: Color(dinoHex: 0xF1E8B7), location: 0),
                         .init(color: Color(dinoHex: 0xD4E8BE), location: 0.35),
                         .init(color: Color(dinoHex: 0xBFC5E0), location: 0.68),
                         .init(color: Color(dinoHex: 0xA9BBD4), location: 0.90),
                         .init(color: Color(dinoHex: nextGround), location: 1)]
            }
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .linearGradient(Gradient(stops: stops), startPoint: .zero,
                                               endPoint: CGPoint(x: 0, y: size.height)))
            let sky = ThemePainter(context: context, colors: colors)
            sky.horizon(worldID: world.id, width: w, left: left, right: right, scale: scale)
            var routeContext = context
            routeContext.translateBy(x: 0, y: routeOffset)
            let p = ThemePainter(context: routeContext, colors: colors)
            p.terrain(worldID: world.id, width: w, left: left, right: right, scale: scale)
            // Each clearing has a planted foreground, a destination and smaller
            // supporting props. The central route remains a separate UI layer.
            for index in 0..<9 {
                // Place the largest props on the outside of each bend. This
                // exposes the whole scene without crowding the level buttons.
                let onRight = index % 4 == 0 || index % 4 == 3
                let point = CGPoint(x: onRight ? right - 36 * scale : left + 36 * scale,
                                    y: 180 + CGFloat(index) * 175)
                if [4, 6, 10].contains(world.id) {
                    let positions: [CGFloat] = [0.28, 0.5, 0.72, 0.5, 0.28, 0.5, 0.72, 0.5, 0.28, 0.5]
                    let routeWidth = min(w, 600) - 36
                    let x = (w - routeWidth) / 2 + routeWidth * (positions[index] + (positions[index + 1] - positions[index]) * 0.622)
                    p.approach(from: CGPoint(x: x, y: point.y), to: point,
                               city: world.id == 6, scale: scale)
                }
                p.scene(worldID: world.id, at: point, size: scale * 1.08, variation: index)
                p.edgeGarden(worldID: world.id,
                             at: CGPoint(x: onRight ? left - 6 : right + 6, y: point.y + 82),
                             size: scale, variation: index)
            }
            let bossPoint = CGPoint(x: right - 58 * scale, y: 1690)
            p.bossClearing(worldID: world.id, at: bossPoint, size: scale)
            p.boss(worldID: world.id, at: bossPoint, size: scale * 0.96)
            context.fill(Path(CGRect(x: 0, y: size.height - 180, width: w, height: 180)),
                         with: .linearGradient(Gradient(colors: [Color(dinoHex: nextGround).opacity(0), Color(dinoHex: nextGround)]),
                                               startPoint: CGPoint(x: 0, y: size.height - 180),
                                               endPoint: CGPoint(x: 0, y: size.height)))
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Shape-only art for the boss start card and the next-world reward.
struct WorldThemePreview: View {
    let world: DinoWorld
    var body: some View {
        Canvas { context, size in
            let colors = WorldThemeColors(world)
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(dinoHex: colors.ground)))
            let p = ThemePainter(context: context, colors: colors)
            let scale = min(size.height / 145, size.width / 220)
            p.scene(worldID: world.id, at: CGPoint(x: size.width * 0.23, y: size.height * 0.87),
                    size: scale * 0.87, variation: 0)
            p.bossClearing(worldID: world.id, at: CGPoint(x: size.width * 0.73, y: size.height * 0.90), size: scale)
            p.boss(worldID: world.id, at: CGPoint(x: size.width * 0.72, y: size.height * 0.93), size: scale)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct ThemePainter {
    let context: GraphicsContext
    let colors: WorldThemeColors

    func horizon(worldID: Int, width: CGFloat, left: CGFloat, right: CGFloat, scale: CGFloat) {
        let nature = JunglePainter(context: context)
        nature.hill(x: -width * 0.40, y: 15, width: width * 0.9, height: 210,
                    color: tint(colors.distant, toward: colors.ground, amount: 0.45).opacity(0.32))
        nature.hill(x: width * 0.65, y: 75, width: width * 0.7, height: 240,
                    color: Color(dinoHex: colors.accent).opacity(0.12))
        if worldID == 2 || worldID == 7 {
            glow(at: CGPoint(x: right - 50, y: 64), radius: 55, color: 0xFFF1B8, opacity: 0.17)
            moon(at: CGPoint(x: right - 50, y: 64), size: 0.72)
            for i in 0..<5 {
                star(at: CGPoint(x: left + 20 + CGFloat(i % 2) * 30, y: 18 + CGFloat(i) * 31),
                     radius: i.isMultiple(of: 2) ? 3 : 2, color: 0xFFF1B8)
            }
            sprig(at: CGPoint(x: left - 3, y: 153), size: scale * 0.80, color: 0x8EAEA4)
        } else if worldID == 5 {
            for side: CGFloat in [left - 12, right + 12] {
                crystals(at: CGPoint(x: side, y: 100), size: 0.55 * scale)
                glow(at: CGPoint(x: side, y: 80), radius: 60, color: 0x79D8D0, opacity: 0.14)
            }
        } else if worldID == 8 {
            for x in [left + 6, right - 6] { gear(at: CGPoint(x: x, y: 85), radius: 23 * scale) }
        } else {
            glow(at: CGPoint(x: right - 52, y: 52), radius: 62, color: 0xFFF1B8, opacity: 0.20)
            ellipse(CGRect(x: right - 83, y: 22, width: 62, height: 62), 0xFFF1B8, opacity: 0.60)
            for i in 0..<2 {
                let x = left - 20 + CGFloat(i) * 20
                ellipse(CGRect(x: x, y: 38 + CGFloat(i) * 50, width: 90, height: 19), 0xFFFBE9, opacity: 0.35)
            }
        }
    }

    func terrain(worldID: Int, width: CGFloat, left: CGFloat, right: CGFloat, scale: CGFloat) {
        let nature = JunglePainter(context: context)
        for i in 0..<4 {
            let y = CGFloat(i) * 470 + 100
            nature.hill(x: i.isMultiple(of: 2) ? -width * 0.45 : width * 0.58, y: y,
                        width: width * 0.9, height: 360, color: Color(dinoHex: colors.distant).opacity(0.16))
        }
        if [2, 9, 10].contains(worldID) {
            for side in 0..<2 {
                let edge = side == 0 ? left - 26 : right + 26
                var water = Path()
                water.move(to: CGPoint(x: edge, y: -20))
                for i in 0..<6 {
                    let y = CGFloat(i) * 315
                    water.addCurve(to: CGPoint(x: edge + (i.isMultiple(of: 2) ? 10 : -10) * scale, y: y + 315),
                                   control1: CGPoint(x: edge - 40 * scale, y: y + 80),
                                   control2: CGPoint(x: edge + 30 * scale, y: y + 230))
                }
                let bank: UInt32 = worldID == 9 ? 0xE7C284 : worldID == 10 ? 0xA8C1A4 : 0xA2C5B4
                context.stroke(water, with: .color(Color(dinoHex: bank).opacity(0.75)),
                               style: StrokeStyle(lineWidth: (worldID == 9 ? 140 : 72) * scale, lineCap: .round))
                context.stroke(water, with: .color(Color(dinoHex: worldID == 9 ? 0x70C5CD : 0x92CDD0).opacity(0.70)),
                               style: StrokeStyle(lineWidth: (worldID == 9 ? 113 : 49) * scale, lineCap: .round))
                context.stroke(water, with: .color(Color(dinoHex: 0xC4EBDF).opacity(0.65)),
                               style: StrokeStyle(lineWidth: 2.5 * scale, lineCap: .round, dash: [16, 45]))
            }
        }
        if worldID == 5 {
            for side in 0..<2 {
                let x = side == 0 ? left - 48 : right + 48
                for i in 0..<8 {
                    at(CGPoint(x: x, y: CGFloat(i) * 233 + 40), size: scale) { p in
                        p.rock(at: .zero, size: 1.65, color: 0x809CAC)
                        p.rock(at: CGPoint(x: side == 0 ? 22 : -22, y: 120), size: 1.1, color: 0xA2BDC3)
                    }
                }
            }
        }
        for i in 0..<12 {
            for side in 0..<2 {
                let edge = side == 0 ? left : right
                let inset = CGFloat((i * 17 + side * 11) % 38)
                let point = CGPoint(x: edge + (side == 0 ? inset : -inset), y: 85 + CGFloat(i) * 143)
                at(point, size: scale) { p in
                    if [4, 6, 10].contains(worldID) {
                        for j in 0..<3 {
                            p.rounded(CGRect(x: CGFloat(j) * 14 - 22, y: CGFloat(j % 2) * 5, width: 11, height: 5),
                                      radius: 2, color: worldID == 6 ? 0xA7CBD5 : 0xE0D6B7)
                        }
                    } else if worldID == 3 {
                        p.line([CGPoint(x: -16, y: -5), .zero, CGPoint(x: 9, y: 12), CGPoint(x: 22, y: 14)],
                               color: 0xC39D88, width: 1.3)
                        p.rock(at: CGPoint(x: -10, y: 20), size: 0.23, color: 0x887F8D)
                        if i.isMultiple(of: 3) { p.glow(at: CGPoint(x: 6, y: 5), radius: 12, color: 0xFFCA74, opacity: 0.35) }
                    } else if worldID == 8 {
                        p.line([CGPoint(x: -23, y: 0), CGPoint(x: -5, y: 0), CGPoint(x: -5, y: 15), CGPoint(x: 21, y: 15)],
                               color: 0xC7BF99, width: 3)
                        for x: CGFloat in [-23, 21] { p.ellipse(CGRect(x: x - 2, y: 12, width: 4, height: 4), 0xD9B46C) }
                    } else if worldID == 5 {
                        p.crystals(at: CGPoint(x: 0, y: 15), size: 0.21)
                        p.glow(at: CGPoint(x: 10, y: -3), radius: 19, color: 0xB8F0DE, opacity: 0.20)
                    } else {
                        nature.grass(at: point, size: 7 * scale, color: Color(dinoHex: colors.accent).opacity(0.60))
                    }
                    if [2, 7].contains(worldID) && i > 4 {
                        p.glow(at: CGPoint(x: 14, y: -15), radius: 12, color: 0xFFF1B8, opacity: 0.23)
                        p.ellipse(CGRect(x: 12, y: -17, width: 3, height: 3), 0xFFF1B8)
                    }
                }
            }
        }
    }

    func approach(from start: CGPoint, to destination: CGPoint, city: Bool, scale: CGFloat) {
        let end = CGPoint(x: destination.x, y: destination.y + 12 * scale)
        var path = Path()
        path.move(to: start)
        path.addCurve(to: end,
                      control1: CGPoint(x: start.x + (end.x - start.x) * 0.38, y: start.y + 20 * scale),
                      control2: CGPoint(x: start.x + (end.x - start.x) * 0.68, y: end.y - 13 * scale))
        context.stroke(path, with: .color(Color(dinoHex: city ? 0x94B9C8 : 0xBFC29C).opacity(0.48)),
                       style: StrokeStyle(lineWidth: 13 * scale, lineCap: .round))
        context.stroke(path, with: .color(Color(dinoHex: city ? 0xD0E1E4 : 0xE3DDB9).opacity(0.74)),
                       style: StrokeStyle(lineWidth: 9 * scale, lineCap: .round))
        context.stroke(path, with: .color(Color(dinoHex: 0xFFF1D3).opacity(0.30)),
                       style: StrokeStyle(lineWidth: 1.5 * scale, lineCap: .round, dash: [1, 8]))
    }

    func scene(worldID: Int, at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            p.gardenPatch(at: CGPoint(x: 0, y: 11), width: 132, color: p.colors.accent)
            switch worldID {
            case 2:
                p.tree(at: CGPoint(x: -19, y: 0), size: variation.isMultiple(of: 2) ? 0.90 : 0.65, night: true, willow: true)
                p.mushroom(at: CGPoint(x: 25, y: 10), size: 0.75)
                p.mushroom(at: CGPoint(x: 46, y: 20), size: 0.40)
                if variation % 3 == 1 { p.clockPost(at: CGPoint(x: 28, y: -4), time: .init(hour: 3, minute: 30), size: 0.55) }
                p.sprig(at: CGPoint(x: -32, y: 17), size: 0.65, color: 0x9CCBB8)
                p.blossoms(at: CGPoint(x: 7, y: 28), size: 0.58, color: 0xE8CAE3)
            case 3:
                if variation % 3 == 0 { p.volcano(at: CGPoint(x: -8, y: 0), size: 0.87) }
                else if variation % 3 == 1 {
                    p.pond(at: CGPoint(x: -5, y: -3), size: 0.82, lava: true)
                    p.rock(at: CGPoint(x: -34, y: -24), size: 0.70, color: 0x887F8D)
                } else {
                    p.rock(at: CGPoint(x: -18, y: -6), size: 1.15, color: 0x887F8D)
                    p.clockPost(at: CGPoint(x: 18, y: -12), time: .init(hour: 4, minute: 45), size: 0.67)
                }
                p.rock(at: CGPoint(x: 38, y: 15), size: 0.50, color: 0x96868C)
                p.rock(at: CGPoint(x: 12, y: 24), size: 0.30, color: 0xB69D91)
                p.sprig(at: CGPoint(x: -30, y: 24), size: 0.58, color: 0xC18F6C)
            case 4:
                if variation % 3 == 2 { p.building(at: CGPoint(x: -12, y: 1), size: 0.86, city: false, tower: true) }
                else if variation % 3 == 1 {
                    p.tree(at: CGPoint(x: -30, y: -6), size: 0.65, night: false, willow: false)
                    p.fountain(at: CGPoint(x: 23, y: 13), size: 0.75)
                }
                else {
                    p.building(at: CGPoint(x: -27, y: -11), size: 0.72, city: false)
                    p.building(at: CGPoint(x: 25, y: 6), size: 0.61, city: false)
                }
                p.fence(at: CGPoint(x: -4, y: 29), size: 0.85)
                p.blossoms(at: CGPoint(x: -33, y: 25), size: 0.70, color: 0xEEA8A0)
                p.blossoms(at: CGPoint(x: 43, y: 31), size: 0.52, color: 0xF7D87B)
            case 5:
                p.rock(at: CGPoint(x: -14, y: 1), size: 1.02, color: 0x89A9B8)
                p.glow(at: CGPoint(x: 14, y: -38), radius: 67, color: 0x8EEDD8, opacity: 0.25)
                p.crystals(at: CGPoint(x: 0, y: 10), size: 1.16)
                p.crystals(at: CGPoint(x: 40, y: 25), size: 0.42)
                if variation == 2 { p.clockPost(at: CGPoint(x: 18, y: -47), time: .init(hour: 2, minute: 17), size: 0.65) }
                p.rock(at: CGPoint(x: -37, y: 21), size: 0.30, color: 0x8CA6AF)
                for i in 0..<3 { p.star(at: CGPoint(x: CGFloat(i) * 23 - 25, y: -30 - CGFloat(i % 2) * 62), radius: 3, color: 0xECFFF4) }
            case 6:
                p.building(at: CGPoint(x: -25, y: -16), size: 0.79, city: true, tower: variation.isMultiple(of: 2))
                p.building(at: CGPoint(x: 26, y: 3), size: 0.62, city: true)
                if variation == 2 || variation == 4 { p.tram(at: CGPoint(x: 8, y: 39), size: 0.62) }
                else { p.bench(at: CGPoint(x: 15, y: 35), size: 0.65) }
                p.lamp(at: CGPoint(x: 49, y: 12), size: 0.68, night: false)
                p.planter(at: CGPoint(x: -43, y: 17), size: 0.62, flowers: true)
            case 7:
                p.tree(at: CGPoint(x: -8, y: -2), size: 0.93, night: variation > 2, willow: false)
                p.mushroom(at: CGPoint(x: 32, y: 15), size: 0.63)
                p.sprig(at: CGPoint(x: -34, y: 22), size: 0.75, color: variation > 2 ? 0x8595AC : 0x9CBE83)
                if variation % 3 == 1 { p.clockPost(at: CGPoint(x: 22, y: 10), time: .init(hour: variation > 2 ? 20 : 8), size: 0.66, digital: true) }
                p.blossoms(at: CGPoint(x: 5, y: 28), size: 0.45, color: 0xEAE6B1)
            case 8:
                p.machineBase(at: CGPoint(x: -8, y: 18), size: 0.94)
                if variation % 3 == 0 { p.portal(at: CGPoint(x: -6, y: -2), size: 0.87) }
                else { p.workbench(at: CGPoint(x: -6, y: -2), size: 0.94, variation: variation) }
                p.gear(at: CGPoint(x: -42, y: -21), radius: 22)
                p.hourglass(at: CGPoint(x: 40, y: 25), size: 0.57)
                if variation % 3 == 1 { p.clockPost(at: CGPoint(x: 40, y: -23), time: .init(hour: 6, minute: 25), size: 0.55, digital: true) }
            case 9:
                if variation % 3 == 1 {
                    p.jetty(at: CGPoint(x: -5, y: 20), size: 0.85)
                    p.ship(at: CGPoint(x: -7, y: -1), size: 0.74)
                } else {
                    JunglePainter(context: p.context).palm(at: CGPoint(x: -20, y: 0), size: 0.65, flipped: false)
                    p.chest(at: CGPoint(x: 29, y: 22), size: 0.74)
                    p.hourglass(at: CGPoint(x: 32, y: -3), size: 0.45)
                }
                p.rock(at: CGPoint(x: -34, y: 24), size: 0.27, color: 0xD1B58A)
                p.sprig(at: CGPoint(x: 48, y: 36), size: 0.48, color: 0x80AE89)
            default:
                p.castleTower(at: CGPoint(x: -8, y: 0), size: 0.86)
                p.castleWall(at: CGPoint(x: -33, y: 24), size: 0.72)
                p.planter(at: CGPoint(x: 36, y: 24), size: 0.71, flowers: true)
                p.blossoms(at: CGPoint(x: -34, y: 32), size: 0.65, color: 0xEAA7B5)
                if variation == 3 { p.clockPost(at: CGPoint(x: 37, y: -21), time: .init(hour: 10, minute: 25), size: 0.57, digital: true) }
            }
        }
    }

    func edgeGarden(worldID: Int, at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            p.gardenPatch(at: CGPoint(x: 0, y: 9), width: 168, color: p.colors.distant)
            switch worldID {
            case 2:
                p.tree(at: CGPoint(x: -8, y: -8), size: 1.03, night: true, willow: true)
                p.pond(at: CGPoint(x: 29, y: 17), size: 0.50, lava: false)
                p.blossoms(at: CGPoint(x: 34, y: 24), size: 0.6, color: 0xDAB9DE)
            case 3:
                p.rock(at: CGPoint(x: -18, y: -2), size: 1.25, color: 0x887F8D)
                p.rock(at: CGPoint(x: 28, y: 7), size: 0.78, color: 0xA89391)
                p.glow(at: CGPoint(x: 15, y: 16), radius: 30, color: 0xFFD88B, opacity: 0.22)
                p.sprig(at: CGPoint(x: 5, y: 18), size: 0.9, color: 0xC19174)
            case 4, 10:
                p.tree(at: CGPoint(x: -9, y: -2), size: 0.77, night: false, willow: false)
                p.planter(at: CGPoint(x: 32, y: 22), size: 0.82, flowers: true)
                if worldID == 4 {
                    for x: CGFloat in [-18, 0, 18] { p.volume(CGRect(x: x, y: -85, width: 7, height: 8), color: 0xEDAF87) }
                }
            case 5:
                p.rock(at: CGPoint(x: -16, y: -5), size: 1.4, color: 0x89A9B8)
                p.crystals(at: CGPoint(x: 29, y: 20), size: 0.64)
                p.glow(at: CGPoint(x: 32, y: -12), radius: 39, color: 0xB2F0DD, opacity: 0.17)
            case 6:
                p.planter(at: CGPoint(x: -14, y: -12), size: 1.08, flowers: true)
                p.lamp(at: CGPoint(x: 28, y: 4), size: 0.86, night: false)
                p.bench(at: CGPoint(x: 10, y: 24), size: 0.73)
            case 7:
                p.tree(at: CGPoint(x: -5, y: -4), size: 1.12, night: variation > 3, willow: false)
                p.mushroom(at: CGPoint(x: 39, y: 17), size: 0.58)
                p.sprig(at: CGPoint(x: 24, y: 24), size: 0.8, color: variation > 3 ? 0x8595AC : 0x9CBE83)
            case 8:
                p.gear(at: CGPoint(x: -11, y: -31), radius: 34)
                p.gear(at: CGPoint(x: 28, y: -5), radius: 23)
                p.rounded(CGRect(x: -48, y: -4, width: 67, height: 14), radius: 5, color: 0x91B8B2)
                p.line([CGPoint(x: -38, y: 10), CGPoint(x: -38, y: 25), CGPoint(x: 20, y: 25)], color: 0xC7AC7B, width: 5)
            default:
                p.rock(at: CGPoint(x: -16, y: -1), size: 1.06, color: 0xD8BD93)
                p.sprig(at: CGPoint(x: 27, y: 19), size: 0.9, color: 0x83B39A)
                for i in 0..<3 {
                    let x = CGFloat(i) * 17 - 24
                    p.volume(CGRect(x: x, y: 25, width: 10, height: 7), color: i == 1 ? 0xEFC2AB : 0xF5E8BF)
                    p.line([CGPoint(x: x + 4, y: 26), CGPoint(x: x + 5, y: 31)], color: 0xD9BDA0, width: 1)
                }
            }
        }
    }

    private func fountain(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.shadow(width: 92)
            p.volume(CGRect(x: -44, y: -16, width: 88, height: 27), color: 0xD4D0B6)
            p.volume(CGRect(x: -38, y: -20, width: 76, height: 20), color: 0x8ECBD0)
            p.rounded(CGRect(x: -7, y: -51, width: 14, height: 43), radius: 5, color: 0xE0D6B7)
            p.volume(CGRect(x: -24, y: -55, width: 48, height: 15), color: 0xE7DDC2)
            p.volume(CGRect(x: -20, y: -58, width: 40, height: 9), color: 0x9EDAD8)
            for side: CGFloat in [-1, 1] {
                var stream = Path()
                stream.move(to: CGPoint(x: side * 17, y: -53))
                stream.addQuadCurve(to: CGPoint(x: side * 31, y: -9), control: CGPoint(x: side * 30, y: -39))
                p.context.stroke(stream, with: .color(Color(dinoHex: 0xC9F0E3)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            p.volume(CGRect(x: -7, y: -72, width: 14, height: 18), color: 0xFFF1D3)
            p.line([CGPoint(x: -26, y: -4), CGPoint(x: -11, y: -3)], color: 0xDAF3E6, width: 1.5)
        }
    }

    private func workbench(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -38, y: -73, width: 76, height: 48), radius: 10, color: 0x82AAA9)
            p.rounded(CGRect(x: -34, y: -69, width: 68, height: 38), radius: 8, color: 0xB1D7CA)
            p.clock(at: CGPoint(x: 1, y: -50), time: .init(hour: 6, minute: 25), size: 17, digital: variation.isMultiple(of: 2))
            p.rounded(CGRect(x: -45, y: -25, width: 90, height: 12), radius: 5, color: 0xD9B46C)
            for x: CGFloat in [-34, 27] {
                p.rounded(CGRect(x: x, y: -14, width: 7, height: 24), radius: 2, color: 0xA69069)
                p.volume(CGRect(x: x + 1, y: -65, width: 4, height: 4), color: 0xF5E8B9)
            }
            p.gear(at: CGPoint(x: -26, y: -20), radius: 12)
            p.rounded(CGRect(x: 13, y: -32, width: 23, height: 8), radius: 3, color: 0xB5A6E6)
            p.line([CGPoint(x: 33, y: -61), CGPoint(x: 44, y: -61), CGPoint(x: 44, y: -45)], color: 0xD9B46C, width: 3)
        }
    }

    func bossClearing(worldID: Int, at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.gardenPatch(at: CGPoint(x: 0, y: 7), width: 135, color: p.colors.accent)
            for i in 0..<5 {
                p.rounded(CGRect(x: -48 + CGFloat(i) * 22, y: 11 + CGFloat(i % 2) * 4, width: 14, height: 5),
                          radius: 2, color: [3, 5].contains(worldID) ? 0xA5ADB1 : 0xE0D6B7)
            }
            if [2, 4, 7, 10].contains(worldID) {
                p.sprig(at: CGPoint(x: 44, y: 12), size: 0.60, color: worldID == 7 ? 0x8595AC : 0x9DBE91)
                p.blossoms(at: CGPoint(x: -41, y: 15), size: 0.50, color: worldID == 2 ? 0xDDD0EF : 0xECA6AF)
            } else if worldID == 5 {
                p.glow(at: CGPoint(x: 0, y: -50), radius: 76, color: 0xA8F0DB, opacity: 0.20)
                p.crystals(at: CGPoint(x: -45, y: 10), size: 0.33)
            } else if worldID == 8 { p.machineBase(at: CGPoint(x: 0, y: 6), size: 0.95) }
            else if worldID == 9 { p.jetty(at: CGPoint(x: 0, y: 16), size: 0.82) }
        }
    }

    private func glow(at point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), Color(dinoHex: color).opacity(0)]),
                                           center: point, startRadius: 0, endRadius: radius))
    }
    private func gardenPatch(at point: CGPoint, width: CGFloat, color: UInt32) {
        JunglePainter(context: context).hill(x: point.x - width / 2, y: point.y - 20, width: width, height: 45,
                                            color: tint(color, toward: colors.ground, amount: 0.65).opacity(0.68))
        ellipse(CGRect(x: point.x - width * 0.34, y: point.y - 1, width: width * 0.79, height: 14), colors.shade, opacity: 0.09)
    }
    private func sprig(at point: CGPoint, size: CGFloat, color: UInt32) {
        at(point, size: size) { p in
            let leaves = JunglePainter(context: p.context)
            for i in 0..<5 {
                let angle = Double(i - 2) * 28
                leaves.leaf(at: .zero, length: CGFloat(25 + i % 2 * 11), width: 8, angle: angle,
                            color: p.tint(color, toward: 0x567F78, amount: CGFloat(i) * 0.06))
            }
        }
    }
    private func blossoms(at point: CGPoint, size: CGFloat, color: UInt32) {
        at(point, size: size) { p in
            for i in 0..<3 {
                let x = CGFloat(i - 1) * 16, y = CGFloat(i % 2) * -12
                p.line([CGPoint(x: x, y: 4), CGPoint(x: x, y: y - 16)], color: 0x709B7C, width: 2)
                for petal in 0..<5 {
                    let a = Double(petal) * .pi * 2 / 5
                    p.volume(CGRect(x: x + CGFloat(cos(a)) * 5 - 4, y: y - 20 + CGFloat(sin(a)) * 5, width: 9, height: 8), color: color)
                }
                p.ellipse(CGRect(x: x - 3, y: y - 17, width: 6, height: 6), 0xFFF1B8)
            }
        }
    }
    private func tree(at point: CGPoint, size: CGFloat, night: Bool, willow: Bool) {
        at(point, size: size) { p in
            p.shadow(width: 109)
            let wood: UInt32 = night ? 0x8C929E : 0xA68B63
            let leaf: UInt32 = night ? (willow ? 0x97B7B0 : 0x839AAC) : 0x8DBB86
            var trunk = Path()
            trunk.move(to: CGPoint(x: -16, y: 1))
            trunk.addQuadCurve(to: CGPoint(x: -3, y: -94), control: CGPoint(x: 5, y: -30))
            trunk.addLine(to: CGPoint(x: 13, y: -93))
            trunk.addQuadCurve(to: CGPoint(x: 17, y: 1), control: CGPoint(x: 4, y: -25))
            trunk.closeSubpath()
            p.material(trunk, rect: CGRect(x: -16, y: -94, width: 33, height: 96), color: wood)
            p.line([CGPoint(x: 4, y: -74), CGPoint(x: -26, y: -112)], color: wood, width: 8)
            p.line([CGPoint(x: 7, y: -69), CGPoint(x: 32, y: -109)], color: wood, width: 7)
            for i in 0..<5 {
                let x = CGFloat(i - 2) * 21, y: CGFloat = -128 - CGFloat(i % 2) * 10
                p.volume(CGRect(x: x - 25, y: y, width: 53, height: willow ? 56 : 45), color: leaf)
                if willow {
                    for j in 0..<2 {
                        var tendril = Path()
                        let tx = x + CGFloat(j) * 13
                        tendril.move(to: CGPoint(x: tx, y: y + 27))
                        tendril.addQuadCurve(to: CGPoint(x: tx - 5, y: y + 81), control: CGPoint(x: tx + 8, y: y + 50))
                        p.context.stroke(tendril, with: .color(p.tint(leaf, toward: 0x628C87, amount: 0.30)),
                                         style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    }
                }
            }
            for i in 0..<7 {
                let x = CGFloat((i * 19) % 90 - 45), y = CGFloat((i * 13) % 30 - 116)
                JunglePainter(context: p.context).leaf(at: CGPoint(x: x, y: y), length: 11, width: 3.5,
                    angle: Double(i * 29), color: .white.opacity(0.17))
            }
            p.line([CGPoint(x: 1, y: -62), CGPoint(x: -3, y: -10)], color: 0xD9C7A6, width: 1.4)
            p.sprig(at: CGPoint(x: -21, y: 9), size: 0.5, color: leaf)
        }
    }
    private func rock(at point: CGPoint, size: CGFloat, color: UInt32) {
        at(point, size: size) { p in
            p.shadow(width: 71)
            let vertices = [CGPoint(x: -37, y: -3), CGPoint(x: -32, y: -28), CGPoint(x: -12, y: -49),
                            CGPoint(x: 17, y: -43), CGPoint(x: 34, y: -21), CGPoint(x: 29, y: 0), CGPoint(x: 4, y: 6)]
            var path = Path()
            path.addLines(vertices); path.closeSubpath()
            p.material(path, rect: CGRect(x: -37, y: -49, width: 71, height: 55), color: color)
            p.polygon([vertices[2], vertices[3], CGPoint(x: 7, y: -20), vertices[1]], color: 0xFFFFFF, opacity: 0.15)
            p.polygon([vertices[3], vertices[4], vertices[5], CGPoint(x: 7, y: -20)], color: p.colors.shade, opacity: 0.15)
            p.line([CGPoint(x: -17, y: -13), CGPoint(x: -4, y: -18), CGPoint(x: 5, y: -13)], color: p.colors.shade, width: 1)
        }
    }
    private func fence(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for y: CGFloat in [-16, -7] { p.line([CGPoint(x: -59, y: y), CGPoint(x: 56, y: y)], color: 0xD9C399, width: 4) }
            for i in 0..<7 {
                let x = CGFloat(i) * 18 - 56
                p.rounded(CGRect(x: x, y: -26, width: 6, height: 29), radius: 3, color: 0xF6E9CA)
            }
        }
    }
    private func planter(at point: CGPoint, size: CGFloat, flowers: Bool) {
        at(point, size: size) { p in
            p.shadow(width: 45)
            p.rounded(CGRect(x: -22, y: -18, width: 44, height: 20), radius: 5, color: 0xD1BCA2)
            p.rounded(CGRect(x: -24, y: -20, width: 48, height: 6), radius: 3, color: 0xE5D7B9)
            p.sprig(at: CGPoint(x: 0, y: -17), size: 0.84, color: 0x92B58D)
            if flowers { p.blossoms(at: CGPoint(x: 0, y: -16), size: 0.70, color: 0xEEACA6) }
        }
    }
    private func clockPost(at point: CGPoint, time: ClockTime, size: CGFloat, digital: Bool = false) {
        at(point, size: size) { p in
            p.shadow(width: 39)
            p.rounded(CGRect(x: -5, y: -72, width: 10, height: 70), radius: 4, color: 0xC7AC7B)
            p.rounded(CGRect(x: -18, y: -3, width: 36, height: 7), radius: 3, color: 0xD9C399)
            p.clock(at: CGPoint(x: 0, y: -72), time: time, size: 26, digital: digital)
            if digital { p.line([CGPoint(x: -24, y: -8), CGPoint(x: 24, y: -8)], color: 0xC7AC7B, width: 3) }
        }
    }
    private func lamp(at point: CGPoint, size: CGFloat, night: Bool) {
        at(point, size: size) { p in
            p.line([.zero, CGPoint(x: 0, y: -80), CGPoint(x: -9, y: -84)], color: 0x678E97, width: 5)
            p.rounded(CGRect(x: -18, y: -85, width: 22, height: 9), radius: 4, color: 0xD9B46C)
            p.ellipse(CGRect(x: -14, y: -80, width: 14, height: 5), 0xFFF1B8)
            p.rounded(CGRect(x: -9, y: -3, width: 18, height: 6), radius: 3, color: 0x789BA1)
            if night { p.glow(at: CGPoint(x: -7, y: -75), radius: 30, color: 0xFFF1B8, opacity: 0.25) }
        }
    }
    private func bench(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.shadow(width: 53)
            p.rounded(CGRect(x: -25, y: -25, width: 50, height: 13), radius: 3, color: 0xC7AC7B)
            p.rounded(CGRect(x: -28, y: -11, width: 56, height: 7), radius: 3, color: 0xD9B46C)
            for x: CGFloat in [-20, 20] { p.line([CGPoint(x: x, y: -4), CGPoint(x: x, y: 4)], color: 0x678E97, width: 3) }
        }
    }
    private func machineBase(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.volume(CGRect(x: -59, y: -14, width: 118, height: 27), color: 0xB7BDC2)
            p.volume(CGRect(x: -59, y: -21, width: 118, height: 27), color: 0xE5D5B4)
            for x: CGFloat in [-42, 0, 42] { p.ellipse(CGRect(x: x - 2, y: -6, width: 4, height: 4), 0x978669) }
            p.line([CGPoint(x: -51, y: -4), CGPoint(x: -61, y: -4), CGPoint(x: -61, y: -45)], color: 0xD9B46C, width: 5)
        }
    }
    private func jetty(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.shadow(width: 122)
            for i in 0..<6 {
                p.rounded(CGRect(x: -57, y: -28 + CGFloat(i) * 6, width: 114, height: 5), radius: 2, color: i.isMultiple(of: 2) ? 0xC9A977 : 0xDABB88)
                p.line([CGPoint(x: -40, y: -26 + CGFloat(i) * 6), CGPoint(x: -19, y: -26 + CGFloat(i) * 6)], color: 0xA78B66, width: 0.7)
            }
            for x: CGFloat in [-48, 48] {
                p.rounded(CGRect(x: x - 4, y: -32, width: 8, height: 40), radius: 3, color: 0xA78B66)
                p.ellipse(CGRect(x: x - 5, y: -35, width: 10, height: 5), 0xE9CE99)
            }
        }
    }
    private func chest(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.shadow(width: 57)
            p.rounded(CGRect(x: -27, y: -31, width: 54, height: 32), radius: 6, color: 0xAE825F)
            p.rounded(CGRect(x: -28, y: -42, width: 56, height: 22), radius: 10, color: 0xC8A077)
            for x: CGFloat in [-20, 16] { p.rounded(CGRect(x: x, y: -38, width: 5, height: 39), radius: 2, color: 0xE8C66D) }
            p.line([CGPoint(x: -25, y: -20), CGPoint(x: 25, y: -20)], color: 0x775F54, width: 2)
            p.rounded(CGRect(x: -6, y: -25, width: 12, height: 13), radius: 3, color: 0xE8C66D)
            p.ellipse(CGRect(x: -1.5, y: -21, width: 3, height: 5), 0x775F54)
        }
    }
    private func castleWall(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -40, y: -29, width: 80, height: 31), radius: 3, color: 0xE2D9C4)
            for i in 0..<5 {
                let x = CGFloat(i) * 17 - 40
                p.rounded(CGRect(x: x, y: -37, width: 10, height: 15), radius: 2, color: 0xF4EBDA)
                p.line([CGPoint(x: x, y: -9), CGPoint(x: x + 11, y: -9)], color: 0xC6C2B7, width: 1)
            }
        }
    }

    private func at(_ point: CGPoint, size: CGFloat, draw: (ThemePainter) -> Void) {
        var c = context
        c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: size, y: size)
        draw(ThemePainter(context: c, colors: colors))
    }
    func ellipse(_ rect: CGRect, _ hex: UInt32, opacity: Double = 1) {
        context.fill(Path(ellipseIn: rect), with: .color(Color(dinoHex: hex).opacity(opacity)))
    }
    private func material(_ path: Path, rect: CGRect, color: UInt32) {
        context.fill(path, with: .linearGradient(Gradient(stops: [
            .init(color: tint(color, toward: 0xFFFFFF, amount: 0.20), location: 0),
            .init(color: Color(dinoHex: color), location: 0.48),
            .init(color: tint(color, toward: colors.shade, amount: 0.20), location: 1)
        ]), startPoint: CGPoint(x: rect.minX, y: rect.minY),
            endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
    }
    private func tint(_ hex: UInt32, toward other: UInt32, amount: CGFloat) -> Color {
        WorldLandscapePalette(ground: hex, distant: hex, foliage: hex, shade: hex, rock: hex)
            .color(\.ground, toward: .init(ground: other, distant: other, foliage: other, shade: other, rock: other), progress: amount)
    }
    private func rounded(_ rect: CGRect, radius: CGFloat, color: UInt32) {
        material(Path(roundedRect: rect, cornerRadius: radius), rect: rect, color: color)
    }
    private func volume(_ rect: CGRect, color: UInt32) {
        material(Path(ellipseIn: rect), rect: rect, color: color)
    }
    private func polygon(_ points: [CGPoint], color: UInt32, opacity: Double = 1) {
        guard let first = points.first else { return }
        var path = Path()
        path.move(to: first)
        points.dropFirst().forEach { path.addLine(to: $0) }
        path.closeSubpath()
        context.fill(path, with: .color(Color(dinoHex: color).opacity(opacity)))
    }
    private func line(_ points: [CGPoint], color: UInt32, width: CGFloat) {
        guard let first = points.first else { return }
        var path = Path()
        path.move(to: first)
        points.dropFirst().forEach { path.addLine(to: $0) }
        context.stroke(path, with: .color(Color(dinoHex: color)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func shadow(width: CGFloat = 98) {
        ellipse(CGRect(x: -width / 2, y: -6, width: width, height: 17), colors.shade, opacity: 0.14)
    }

    func star(at point: CGPoint, radius: CGFloat, color: UInt32) {
        let points = (0..<10).map { index -> CGPoint in
            let angle = Double(index) * .pi / 5 - .pi / 2
            let r = index.isMultiple(of: 2) ? radius : radius * 0.46
            return CGPoint(x: point.x + CGFloat(cos(angle)) * r, y: point.y + CGFloat(sin(angle)) * r)
        }
        polygon(points, color: color)
    }
    func moon(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            var crescent = Path()
            crescent.move(to: CGPoint(x: 15, y: -31))
            crescent.addCurve(to: CGPoint(x: 29, y: 23), control1: CGPoint(x: -47, y: -39), control2: CGPoint(x: -51, y: 47))
            crescent.addCurve(to: CGPoint(x: 15, y: -31), control1: CGPoint(x: -10, y: 23), control2: CGPoint(x: -17, y: -13))
            crescent.closeSubpath()
            p.material(crescent, rect: CGRect(x: -34, y: -34, width: 68, height: 68), color: 0xFFF1B8)
            p.star(at: CGPoint(x: 40, y: -15), radius: 6, color: 0xFFF1B8)
        }
    }
    func clock(at point: CGPoint, time: ClockTime, size: CGFloat, digital: Bool = false) {
        ellipse(CGRect(x: point.x - size - 3, y: point.y - size + 3, width: size * 2 + 6, height: size * 2 + 6), colors.shade, opacity: 0.15)
        ellipse(CGRect(x: point.x - size - 3, y: point.y - size - 3, width: size * 2 + 6, height: size * 2 + 6), colors.accent)
        ellipse(CGRect(x: point.x - size, y: point.y - size, width: size * 2, height: size * 2), 0xFFF6DD)
        context.stroke(Path(ellipseIn: CGRect(x: point.x - size + 2, y: point.y - size + 2, width: size * 2 - 4, height: size * 2 - 4)),
                       with: .color(.white.opacity(0.65)), lineWidth: 1)
        for index in 0..<12 {
            let angle = Double(index) * .pi / 6
            let a = CGPoint(x: point.x + CGFloat(sin(angle)) * size * 0.81, y: point.y - CGFloat(cos(angle)) * size * 0.81)
            let b = CGPoint(x: point.x + CGFloat(sin(angle)) * size * 0.91, y: point.y - CGFloat(cos(angle)) * size * 0.91)
            line([a, b], color: colors.shade, width: 1.4)
        }
        for (angle, length, width) in [(time.hourAngle, size * 0.49, CGFloat(3)), (time.minuteAngle, size * 0.73, CGFloat(2))] {
            let radians = angle * .pi / 180
            line([point, CGPoint(x: point.x + CGFloat(sin(radians)) * length, y: point.y - CGFloat(cos(radians)) * length)], color: colors.shade, width: width)
        }
        ellipse(CGRect(x: point.x - 2.5, y: point.y - 2.5, width: 5, height: 5), colors.shade)
        if digital {
            let rect = CGRect(x: point.x - 27, y: point.y + size + 7, width: 54, height: 24)
            rounded(rect, radius: 6, color: colors.shade)
            context.draw(Text(verbatim: time.digitalText).font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(dinoHex: 0xFFF1B8)), at: CGPoint(x: rect.midX, y: rect.midY))
        }
    }
    func pond(at point: CGPoint, size: CGFloat, lava: Bool) {
        at(point, size: size) { p in
            p.ellipse(CGRect(x: -73, y: -28, width: 146, height: 53), p.colors.shade, opacity: 0.14)
            p.volume(CGRect(x: -68, y: -29, width: 136, height: 45), color: lava ? 0xF47C65 : 0x79BBC7)
            p.volume(CGRect(x: -50, y: -26, width: 100, height: 31), color: lava ? 0xFFC857 : 0xA4DDE0)
            p.line([CGPoint(x: -35, y: -14), CGPoint(x: -7, y: -14)], color: lava ? 0xFFF1B8 : 0xE6F9EE, width: 2)
            p.line([CGPoint(x: 6, y: 0), CGPoint(x: 31, y: 0)], color: lava ? 0xFFF1B8 : 0xE6F9EE, width: 2)
            p.rock(at: CGPoint(x: 47, y: 14), size: 0.55, color: lava ? 0x887F8D : 0xA8B9B0)
            p.rock(at: CGPoint(x: 20, y: 17), size: 0.26, color: lava ? 0x96868C : 0xB8C8B4)
        }
    }
    func crystals(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.shadow(width: 96)
            for (index, data) in [(-26.0, 48.0), (0.0, 76.0), (25.0, 54.0)].enumerated() {
                let x = CGFloat(data.0), h = CGFloat(data.1)
                let tint: UInt32 = index == 1 ? 0xA493D7 : index == 0 ? 0x79D8D0 : 0xF1BCD9
                p.polygon([CGPoint(x: x - 13, y: -h * 0.70), CGPoint(x: x, y: -h), CGPoint(x: x + 15, y: -h * 0.72),
                           CGPoint(x: x + 12, y: -6), CGPoint(x: x, y: 0), CGPoint(x: x - 12, y: -8)], color: tint)
                p.polygon([CGPoint(x: x, y: -h), CGPoint(x: x + 15, y: -h * 0.72), CGPoint(x: x + 12, y: -6), CGPoint(x: x, y: 0)],
                          color: p.colors.shade, opacity: 0.23)
                p.polygon([CGPoint(x: x - 13, y: -h * 0.70), CGPoint(x: x, y: -h),
                           CGPoint(x: x, y: -h * 0.55)], color: 0xFFFFFF, opacity: 0.24)
                p.line([CGPoint(x: x - 5, y: -h * 0.71), CGPoint(x: x - 5, y: -15)], color: 0xF2FBF6, width: 2)
                p.star(at: CGPoint(x: x - 7, y: -h * 0.65), radius: 3.3, color: 0xF2FBF6)
            }
        }
    }
    private func volcano(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.shadow(width: 135)
            var mountain = Path()
            mountain.move(to: CGPoint(x: -62, y: 0))
            mountain.addQuadCurve(to: CGPoint(x: -20, y: -86), control: CGPoint(x: -37, y: -50))
            mountain.addQuadCurve(to: CGPoint(x: 21, y: -86), control: CGPoint(x: 0, y: -96))
            mountain.addQuadCurve(to: CGPoint(x: 65, y: 0), control: CGPoint(x: 36, y: -48))
            mountain.closeSubpath()
            p.context.fill(mountain, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xD7987A), Color(dinoHex: 0x706778)]),
                                                            startPoint: CGPoint(x: -20, y: -85), endPoint: CGPoint(x: 45, y: 0)))
            p.polygon([CGPoint(x: -20, y: -86), CGPoint(x: -31, y: -48), CGPoint(x: -55, y: -6),
                       CGPoint(x: -30, y: -8), CGPoint(x: -13, y: -47)], color: 0xE4B69B, opacity: 0.35)
            for i in 0..<3 {
                let y = CGFloat(i) * 17 - 49
                p.line([CGPoint(x: 15, y: y), CGPoint(x: 28 + CGFloat(i) * 6, y: y + 5)], color: 0x887786, width: 1.4)
            }
            p.ellipse(CGRect(x: -23, y: -93, width: 46, height: 16), 0x706778)
            p.ellipse(CGRect(x: -15, y: -90, width: 30, height: 10), 0xFFC857)
            p.line([CGPoint(x: 4, y: -81), CGPoint(x: -5, y: -57), CGPoint(x: 8, y: -31), CGPoint(x: 1, y: -8)], color: 0xF47C65, width: 10)
            p.line([CGPoint(x: 4, y: -81), CGPoint(x: -5, y: -57), CGPoint(x: 8, y: -31)], color: 0xFFC857, width: 4)
            p.ellipse(CGRect(x: -10, y: -115, width: 27, height: 14), 0xFFF0D6, opacity: 0.48)
            p.ellipse(CGRect(x: 7, y: -133, width: 34, height: 18), 0xFFF0D6, opacity: 0.33)
        }
    }
    func building(at point: CGPoint, size: CGFloat, city: Bool, tower: Bool = false) {
        at(point, size: size) { p in
            let h: CGFloat = tower ? (city ? 154 : 123) : city ? 110 : 77
            p.shadow()
            p.rounded(CGRect(x: -36, y: -h, width: 72, height: h), radius: city ? 15 : 28,
                      color: city ? 0xA9DAE3 : 0xF0DFBA)
            p.polygon([CGPoint(x: 20, y: -h), CGPoint(x: 36, y: -h + 12), CGPoint(x: 36, y: -4), CGPoint(x: 20, y: 0)],
                      color: p.colors.shade, opacity: 0.15)
            var roof = Path()
            roof.move(to: CGPoint(x: -43, y: -h + 5))
            roof.addQuadCurve(to: CGPoint(x: 0, y: -h - 23), control: CGPoint(x: -18, y: -h - 33))
            roof.addQuadCurve(to: CGPoint(x: 43, y: -h + 5), control: CGPoint(x: 19, y: -h - 33))
            roof.closeSubpath()
            if city {
                p.rounded(CGRect(x: -41, y: -h - 7, width: 82, height: 14), radius: 6, color: 0x54BCC5)
                p.rounded(CGRect(x: -28, y: -h - 15, width: 56, height: 10), radius: 4, color: 0x91BC96)
                p.sprig(at: CGPoint(x: -13, y: -h - 14), size: 0.35, color: 0x91BC96)
            } else {
                p.material(roof, rect: CGRect(x: -43, y: -h - 28, width: 86, height: 34), color: p.colors.accent)
                p.line([CGPoint(x: -39, y: -h + 4), CGPoint(x: 39, y: -h + 4)], color: 0xB37759, width: 3)
                for i in 0..<4 {
                    let x = CGFloat(i) * 17 - 25
                    p.line([CGPoint(x: x, y: -h - 15 + abs(x) * 0.22),
                            CGPoint(x: x - 2, y: -h + 1)], color: 0xF0B894, width: 1)
                }
                p.rounded(CGRect(x: 21, y: -h - 30, width: 11, height: 21), radius: 3, color: 0xD8B795)
                p.rounded(CGRect(x: 19, y: -h - 32, width: 15, height: 5), radius: 2, color: 0xEDD8B9)
            }
            p.rounded(CGRect(x: -12, y: -30, width: 24, height: 30), radius: 10, color: 0xA47757)
            p.ellipse(CGRect(x: 4, y: -15, width: 3, height: 3), 0xFFE2A1)
            p.rounded(CGRect(x: -16, y: -1, width: 32, height: 5), radius: 2, color: 0xDED0B2)
            if tower {
                p.clock(at: CGPoint(x: 0, y: -h + 33), time: .init(hour: city ? 8 : 5, minute: city ? 5 : 20), size: 21, digital: city)
                if city { p.window(at: CGPoint(x: -8, y: -51), size: 1) }
            } else {
                for x in [-22.0, 14.0] {
                    for y in city ? [-80.0, -51.0] : [-53.0] {
                        p.window(at: CGPoint(x: CGFloat(x), y: CGFloat(y)), size: 1)
                    }
                }
            }
            for i in 0..<3 {
                p.line([CGPoint(x: -31, y: -38 + CGFloat(i) * 11), CGPoint(x: -19, y: -38 + CGFloat(i) * 11)],
                       color: city ? 0x88B8C8 : 0xDBC9A9, width: 1)
            }
        }
    }
    private func window(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -2, y: -1, width: 20, height: 22), radius: 6, color: 0xD4C4A5)
            p.rounded(CGRect(x: 0, y: 0, width: 16, height: 18), radius: 5, color: 0xFFE9A5)
            p.line([CGPoint(x: 8, y: 0), CGPoint(x: 8, y: 18)], color: 0xFFF5D3, width: 1.4)
            p.line([CGPoint(x: 0, y: 9), CGPoint(x: 16, y: 9)], color: 0xFFF5D3, width: 1.4)
            p.line([CGPoint(x: 3, y: 3), CGPoint(x: 6, y: 5)], color: 0xFFFFFF, width: 1)
            p.rounded(CGRect(x: -3, y: 19, width: 22, height: 3), radius: 1.5, color: 0xE9DABB)
        }
    }
    func tram(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.shadow(width: 122)
            for y: CGFloat in [4, 10] { p.line([CGPoint(x: -69, y: y), CGPoint(x: 69, y: y)], color: 0x8BA8AB, width: 2) }
            p.rounded(CGRect(x: -53, y: -54, width: 106, height: 45), radius: 14, color: 0xFFE08A)
            p.rounded(CGRect(x: -57, y: -60, width: 114, height: 13), radius: 6, color: 0x54BCC5)
            for x in [-37.0, -8.0, 22.0] {
                p.rounded(CGRect(x: CGFloat(x), y: -43, width: 22, height: 22), radius: 5, color: 0xAAD9EB)
            }
            for x in [-36.0, 29.0] {
                p.volume(CGRect(x: CGFloat(x), y: -15, width: 17, height: 17), color: p.colors.shade)
                p.ellipse(CGRect(x: CGFloat(x) + 5, y: -10, width: 7, height: 7), 0xBDD4D2)
            }
            p.line([CGPoint(x: -47, y: -17), CGPoint(x: 47, y: -17)], color: 0xEFAD67, width: 3)
            p.ellipse(CGRect(x: 41, y: -31, width: 6, height: 6), 0xFFF1B8)
        }
    }
    func castleTower(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.shadow(width: 110)
            p.rounded(CGRect(x: -34, y: -123, width: 68, height: 123), radius: 14, color: 0xF0E6D3)
            p.polygon([CGPoint(x: 17, y: -123), CGPoint(x: 34, y: -117), CGPoint(x: 34, y: -5),
                       CGPoint(x: 17, y: 0)], color: 0x8D867A, opacity: 0.16)
            p.rounded(CGRect(x: -41, y: -124, width: 82, height: 14), radius: 4, color: 0xF4EBDA)
            for x in [-35.0, -8.0, 19.0] {
                p.rounded(CGRect(x: CGFloat(x), y: -140, width: 16, height: 24), radius: 3, color: 0xF4EBDA)
            }
            p.line([CGPoint(x: 1, y: -142), CGPoint(x: 1, y: -177)], color: 0xD9B46C, width: 3)
            p.polygon([CGPoint(x: 2, y: -177), CGPoint(x: 31, y: -171), CGPoint(x: 22, y: -157),
                       CGPoint(x: 2, y: -163)], color: 0x789BCF)
            p.clock(at: CGPoint(x: 0, y: -82), time: .init(hour: 10, minute: 25), size: 22)
            p.rounded(CGRect(x: -14, y: -40, width: 28, height: 40), radius: 14, color: 0x789BCF)
            for y in [-49.0, -12.0] {
                p.line([CGPoint(x: -32, y: CGFloat(y)), CGPoint(x: -19, y: CGFloat(y))], color: 0xC6C2B7, width: 1.5)
                p.line([CGPoint(x: 20, y: CGFloat(y) - 8), CGPoint(x: 31, y: CGFloat(y) - 8)], color: 0xC6C2B7, width: 1.5)
            }
            for i in 0..<4 {
                let y = CGFloat(i) * 22 - 114
                p.line([CGPoint(x: -31, y: y), CGPoint(x: -21, y: y)], color: 0xD8CFBA, width: 1)
                p.line([CGPoint(x: 19, y: y + 10), CGPoint(x: 31, y: y + 10)], color: 0xCEC5B3, width: 1)
            }
            p.rounded(CGRect(x: -19, y: -2, width: 38, height: 6), radius: 2, color: 0xD7CAB2)
            p.polygon([CGPoint(x: -28, y: -49), CGPoint(x: -15, y: -49), CGPoint(x: -15, y: -31),
                       CGPoint(x: -22, y: -36), CGPoint(x: -28, y: -31)], color: 0x789BCF)
            p.line([CGPoint(x: -30, y: -51), CGPoint(x: -13, y: -51)], color: 0xD9B46C, width: 2)
        }
    }
    private func gear(at point: CGPoint, radius: CGFloat) {
        for index in 0..<12 {
            let angle = Double(index) * .pi / 6
            var c = context
            c.translateBy(x: point.x, y: point.y)
            c.rotate(by: .radians(angle))
            c.fill(Path(roundedRect: CGRect(x: -5, y: -radius - 4, width: 10, height: 12), cornerRadius: 3),
                   with: .color(Color(dinoHex: 0xD9B46C)))
        }
        var ring = Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
        ring.addEllipse(in: CGRect(x: point.x - radius * 0.51, y: point.y - radius * 0.51, width: radius * 1.02, height: radius * 1.02))
        context.fill(ring, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xF2DDA1), Color(dinoHex: 0xC6A261)]),
                                               startPoint: CGPoint(x: point.x - radius, y: point.y - radius),
                                               endPoint: CGPoint(x: point.x + radius, y: point.y + radius)),
                     style: FillStyle(eoFill: true))
        context.stroke(Path(ellipseIn: CGRect(x: point.x - radius * 0.84, y: point.y - radius * 0.84, width: radius * 1.68, height: radius * 1.68)),
                       with: .color(Color(dinoHex: 0xFFF1C3).opacity(0.6)), lineWidth: 1)
        for index in 0..<4 {
            let angle = Double(index) * .pi / 2 + .pi / 4
            ellipse(CGRect(x: point.x + CGFloat(cos(angle)) * radius * 0.71 - 1.6,
                           y: point.y + CGFloat(sin(angle)) * radius * 0.71 - 1.6, width: 3.2, height: 3.2), 0xA38E68)
        }
    }
    func portal(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.shadow(width: 104)
            p.glow(at: CGPoint(x: 0, y: -55), radius: 67, color: 0xAAEADA, opacity: 0.24)
            let rect = CGRect(x: -38, y: -106, width: 76, height: 107)
            p.rounded(rect, radius: 38, color: 0xD9B46C)
            p.rounded(rect.insetBy(dx: 8, dy: 8), radius: 32, color: 0x7EDDD0)
            p.rounded(rect.insetBy(dx: 16, dy: 15), radius: 26, color: 0xB5A6E6)
            p.context.drawLayer { layer in
                layer.clip(to: Path(roundedRect: rect.insetBy(dx: 16, dy: 15), cornerRadius: 26))
                for i in 0..<3 {
                    var orbit = Path()
                    orbit.addArc(center: CGPoint(x: 0, y: -54), radius: CGFloat(14 + i * 11),
                                 startAngle: .degrees(Double(i * 42)), endAngle: .degrees(Double(i * 42 + 235)), clockwise: false)
                    layer.stroke(orbit, with: .color(Color(dinoHex: 0xD4F4E8).opacity(0.56)),
                                 style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                }
            }
            for x: CGFloat in [-31, 31] {
                for y: CGFloat in [-80, -47, -15] { p.ellipse(CGRect(x: x - 2, y: y, width: 4, height: 4), 0xFFF1C3) }
            }
            p.star(at: CGPoint(x: -11, y: -70), radius: 7, color: 0xFFF1D3)
            p.star(at: CGPoint(x: 13, y: -41), radius: 5, color: 0xFFF1D3)
            p.gear(at: CGPoint(x: 32, y: -13), radius: 19)
            p.rounded(CGRect(x: -44, y: -3, width: 88, height: 10), radius: 4, color: 0xC7AC7B)
        }
    }
    private func hourglass(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.polygon([CGPoint(x: -21, y: -59), CGPoint(x: 21, y: -59), CGPoint(x: 3, y: -32),
                       CGPoint(x: 21, y: -7), CGPoint(x: -21, y: -7), CGPoint(x: -3, y: -32)], color: 0xAAD9EB, opacity: 0.8)
            p.polygon([CGPoint(x: -16, y: -56), CGPoint(x: 16, y: -56), CGPoint(x: 0, y: -37)], color: 0xFFE08A)
            p.polygon([CGPoint(x: -17, y: -10), CGPoint(x: 17, y: -10), CGPoint(x: 0, y: -29)], color: 0xFFE08A)
            for x in [-23.0, 23.0] { p.line([CGPoint(x: CGFloat(x), y: -62), CGPoint(x: CGFloat(x), y: -3)], color: 0xA47757, width: 4) }
            p.rounded(CGRect(x: -28, y: -67, width: 56, height: 9), radius: 4, color: 0xD9B46C)
            p.rounded(CGRect(x: -28, y: -7, width: 56, height: 9), radius: 4, color: 0xD9B46C)
            p.line([CGPoint(x: -15, y: -50), CGPoint(x: -6, y: -37)], color: 0xFFFFFF, width: 1.5)
            p.line([CGPoint(x: -15, y: -17), CGPoint(x: -8, y: -25)], color: 0xFFFFFF, width: 1.2)
            p.line([CGPoint(x: 0, y: -34), CGPoint(x: 0, y: -22)], color: 0xFFE08A, width: 1)
        }
    }
    func ship(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.pond(at: .zero, size: 0.90, lava: false)
            var hull = Path()
            hull.move(to: CGPoint(x: -61, y: -25))
            hull.addQuadCurve(to: CGPoint(x: 49, y: -25), control: CGPoint(x: 0, y: 20))
            hull.addLine(to: CGPoint(x: 62, y: -44))
            hull.addQuadCurve(to: CGPoint(x: -61, y: -44), control: CGPoint(x: 0, y: -32))
            hull.closeSubpath()
            p.context.fill(hull, with: .color(Color(dinoHex: 0xA47757)))
            p.line([CGPoint(x: -55, y: -43), CGPoint(x: 3, y: -37), CGPoint(x: 57, y: -44)], color: 0xE0BE89, width: 3)
            for i in 0..<3 {
                let y = CGFloat(i) * 4 - 28
                p.line([CGPoint(x: -29 + CGFloat(i) * 4, y: y), CGPoint(x: 29 - CGFloat(i) * 4, y: y)], color: 0xC29770, width: 1)
            }
            p.line([CGPoint(x: 0, y: -37), CGPoint(x: 0, y: -139)], color: 0xA47757, width: 5)
            var sail = Path()
            sail.move(to: CGPoint(x: 5, y: -132))
            sail.addQuadCurve(to: CGPoint(x: 48, y: -68), control: CGPoint(x: 56, y: -109))
            sail.addQuadCurve(to: CGPoint(x: 5, y: -70), control: CGPoint(x: 28, y: -60))
            sail.closeSubpath()
            p.context.fill(sail, with: .color(Color(dinoHex: 0xFFF1D3)))
            p.line([CGPoint(x: 0, y: -132), CGPoint(x: -43, y: -42)], color: 0xD4BE95, width: 1.3)
            p.line([CGPoint(x: 8, y: -112), CGPoint(x: 31, y: -86), CGPoint(x: 39, y: -71)], color: 0xE8DAC2, width: 1.5)
            p.clock(at: CGPoint(x: 21, y: -94), time: .init(hour: 9, minute: 30), size: 10)
            p.polygon([CGPoint(x: 0, y: -140), CGPoint(x: 29, y: -132), CGPoint(x: 0, y: -122)], color: 0xEF927B)
            for x in [-36.0, -10.0, 16.0] { p.ellipse(CGRect(x: CGFloat(x), y: -33, width: 11, height: 11), 0xD9B46C) }
        }
    }
    private func mushroom(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -8, y: -28, width: 16, height: 31), radius: 6, color: 0xF5E6C7)
            var cap = Path()
            cap.move(to: CGPoint(x: -29, y: -23))
            cap.addQuadCurve(to: CGPoint(x: 29, y: -23), control: CGPoint(x: 0, y: -76))
            cap.addQuadCurve(to: CGPoint(x: -29, y: -23), control: CGPoint(x: 0, y: -12))
            p.context.fill(cap, with: .color(Color(dinoHex: 0xAA99CC)))
            p.material(cap, rect: CGRect(x: -29, y: -51, width: 58, height: 34), color: 0xAA99CC)
            p.line([CGPoint(x: -20, y: -22), CGPoint(x: 0, y: -18), CGPoint(x: 20, y: -22)], color: 0x8C8CA7, width: 1.4)
            p.glow(at: CGPoint(x: 0, y: -31), radius: 24, color: 0xFFF1B8, opacity: 0.10)
            for x in [-13.0, 5.0] { p.ellipse(CGRect(x: CGFloat(x), y: -39, width: 9, height: 7), 0xFFF1B8) }
            p.ellipse(CGRect(x: -3, y: -28, width: 5, height: 4), 0xFFF1B8)
        }
    }

    private func face(center: CGPoint, width: CGFloat, sleepy: Bool = false) {
        for direction: CGFloat in [-1, 1] {
            let eye = CGPoint(x: center.x + direction * width * 0.20, y: center.y - 5)
            if sleepy {
                var arc = Path()
                arc.move(to: CGPoint(x: eye.x - 4, y: eye.y - 1))
                arc.addQuadCurve(to: CGPoint(x: eye.x + 4, y: eye.y - 1), control: CGPoint(x: eye.x, y: eye.y + 4))
                context.stroke(arc, with: .color(Color(dinoHex: 0x284C58)), style: StrokeStyle(lineWidth: 2.3, lineCap: .round))
            } else {
                ellipse(CGRect(x: eye.x - 6, y: eye.y - 9, width: 12, height: 18), 0xFFFBE9)
                ellipse(CGRect(x: eye.x - 3, y: eye.y - 3, width: 6, height: 10), 0x284C58)
                ellipse(CGRect(x: eye.x - 2, y: eye.y - 3, width: 2, height: 3), 0xFFFFFF)
            }
        }
        var smile = Path()
        smile.move(to: CGPoint(x: center.x - 9, y: center.y + 10))
        smile.addQuadCurve(to: CGPoint(x: center.x + 9, y: center.y + 10), control: CGPoint(x: center.x, y: center.y + 21))
        context.stroke(smile, with: .color(Color(dinoHex: 0x284C58)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
    }
    private func dinosaur(color: UInt32) {
        shadow(width: 108)
        var tail = Path()
        tail.move(to: CGPoint(x: 16, y: -31))
        tail.addQuadCurve(to: CGPoint(x: 51, y: -57), control: CGPoint(x: 45, y: -16))
        tail.addQuadCurve(to: CGPoint(x: 20, y: -11), control: CGPoint(x: 61, y: -12))
        tail.closeSubpath()
        material(tail, rect: CGRect(x: 16, y: -57, width: 46, height: 47), color: color)
        for side: CGFloat in [-1, 1] {
            var arm = Path()
            arm.move(to: CGPoint(x: side * 20, y: -43))
            arm.addQuadCurve(to: CGPoint(x: side * 38, y: -26), control: CGPoint(x: side * 36, y: -48))
            context.stroke(arm, with: .color(tint(color, toward: colors.shade, amount: 0.10)),
                           style: StrokeStyle(lineWidth: 11, lineCap: .round))
        }
        volume(CGRect(x: -33, y: -57, width: 64, height: 55), color: color)
        volume(CGRect(x: -22, y: -42, width: 40, height: 35), color: 0xF5E6C7)
        for x in [-28.0, 8.0] { rounded(CGRect(x: CGFloat(x), y: -16, width: 23, height: 17), radius: 8, color: color) }
        volume(CGRect(x: -28, y: -96, width: 59, height: 51), color: color)
        volume(CGRect(x: -28, y: -70, width: 67, height: 31), color: color)
        face(center: CGPoint(x: 1, y: -77), width: 55)
        for x: CGFloat in [-14, 21] {
            ellipse(CGRect(x: x, y: -60, width: 3.5, height: 2.8), 0x775F54, opacity: 0.55)
        }
        for x: CGFloat in [-24, 12] {
            for toe in 0..<2 { volume(CGRect(x: x + CGFloat(toe) * 7, y: -5, width: 6, height: 4), color: 0xF5E6C7) }
        }
        ellipse(CGRect(x: -24, y: -65, width: 8, height: 5), 0xF0B894, opacity: 0.35)
    }
    func boss(worldID: Int, at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            switch worldID {
            case 2:
                p.shadow(width: 115)
                p.volume(CGRect(x: -25, y: -49, width: 79, height: 46), color: 0x9CCBE3)
                for x in [-13.0, 23.0] { p.rounded(CGRect(x: CGFloat(x), y: -18, width: 20, height: 20), radius: 8, color: 0x9CCBE3) }
                var neck = Path()
                neck.move(to: CGPoint(x: -12, y: -30))
                neck.addQuadCurve(to: CGPoint(x: -32, y: -99), control: CGPoint(x: -43, y: -39))
                p.context.stroke(neck, with: .color(Color(dinoHex: 0x9CCBE3)), style: StrokeStyle(lineWidth: 22, lineCap: .round))
                p.volume(CGRect(x: -55, y: -116, width: 48, height: 39), color: 0x9CCBE3)
                p.face(center: CGPoint(x: -32, y: -100), width: 42, sleepy: true)
                p.star(at: CGPoint(x: 18, y: -29), radius: 9, color: 0xFFF1B8)
                p.moon(at: CGPoint(x: 46, y: -76), size: 0.55)
            case 3:
                p.volume(CGRect(x: -43, y: -114, width: 83, height: 73), color: 0xFFC857)
                p.dinosaur(color: 0xD98663)
                for x in [-22.0, 19.0] {
                    p.polygon([CGPoint(x: CGFloat(x) - 7, y: -87), CGPoint(x: CGFloat(x), y: -111),
                               CGPoint(x: CGFloat(x) + 7, y: -85)], color: 0xFFF1D3)
                }
                p.polygon([CGPoint(x: -6, y: -57), CGPoint(x: 0, y: -75), CGPoint(x: 7, y: -57)], color: 0xFFF1D3)
            case 4:
                p.dinosaur(color: 0xC69C62)
                p.rounded(CGRect(x: -25, y: -43, width: 50, height: 27), radius: 8, color: 0x789BCF)
                p.line([CGPoint(x: 35, y: -2), CGPoint(x: 35, y: -77)], color: 0xA47757, width: 4)
                p.clock(at: CGPoint(x: 35, y: -82), time: .init(hour: 5, minute: 20), size: 16)
            case 5:
                p.shadow(width: 114)
                p.rounded(CGRect(x: -33, y: -69, width: 66, height: 62), radius: 20, color: 0x98AFBB)
                p.rounded(CGRect(x: -47, y: -61, width: 24, height: 43), radius: 12, color: 0x98AFBB)
                p.rounded(CGRect(x: 26, y: -61, width: 24, height: 43), radius: 12, color: 0x98AFBB)
                p.rounded(CGRect(x: -26, y: -103, width: 52, height: 43), radius: 16, color: 0xB8CFD4)
                p.face(center: CGPoint(x: 0, y: -85), width: 45)
                p.crystals(at: CGPoint(x: -29, y: -53), size: 0.37)
                p.crystals(at: CGPoint(x: 29, y: -53), size: 0.37)
                p.clock(at: CGPoint(x: 0, y: -34), time: .init(hour: 2, minute: 17), size: 12)
            case 6:
                p.shadow()
                p.rounded(CGRect(x: -29, y: -58, width: 58, height: 49), radius: 14, color: 0x54BCC5)
                p.rounded(CGRect(x: -34, y: -110, width: 68, height: 49), radius: 17, color: 0x54BCC5)
                p.rounded(CGRect(x: -27, y: -102, width: 54, height: 33), radius: 13, color: 0xFFE08A)
                p.face(center: CGPoint(x: 0, y: -89), width: 46)
                p.line([CGPoint(x: 0, y: -110), CGPoint(x: 0, y: -122)], color: 0xD9B46C, width: 4)
                p.volume(CGRect(x: -5, y: -130, width: 10, height: 10), color: 0xFFE08A)
                for x in [-29.0, 11.0] { p.rounded(CGRect(x: CGFloat(x), y: -12, width: 20, height: 16), radius: 7, color: 0xFFE08A) }
                p.context.draw(Text(verbatim: "12:45").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(Color(dinoHex: 0xFFF1B8)),
                               at: CGPoint(x: 0, y: -33))
            case 7:
                p.shadow()
                p.volume(CGRect(x: -33, y: -97, width: 66, height: 94), color: 0xD4C1A1)
                p.volume(CGRect(x: -51, y: -63, width: 35, height: 51), color: 0xE8C66D)
                p.volume(CGRect(x: 18, y: -63, width: 35, height: 51), color: 0x789BCF)
                for x in [-25.0, 0.0] {
                    p.ellipse(CGRect(x: CGFloat(x), y: -90, width: 28, height: 33), 0xFFF1D3)
                    p.volume(CGRect(x: CGFloat(x) + 8, y: -82, width: 13, height: 19), color: 0x526894)
                    p.ellipse(CGRect(x: CGFloat(x) + 9, y: -80, width: 4, height: 5), 0xFFFFFF)
                }
                p.polygon([CGPoint(x: -6, y: -62), CGPoint(x: 8, y: -62), CGPoint(x: 1, y: -49)], color: 0xE8C66D)
                p.clock(at: CGPoint(x: 0, y: -24), time: .init(hour: 20), size: 14)
            case 8:
                p.polygon([CGPoint(x: -18, y: -48), CGPoint(x: -69, y: -87), CGPoint(x: -53, y: -18)], color: 0xB5A6E6)
                p.polygon([CGPoint(x: 19, y: -48), CGPoint(x: 65, y: -86), CGPoint(x: 49, y: -17)], color: 0xB5A6E6)
                p.dinosaur(color: 0xA493D7)
                p.rounded(CGRect(x: -23, y: -45, width: 45, height: 29), radius: 8, color: 0xFFF1D3)
                for x in [-13.0, 13.0] {
                    p.context.stroke(Path(ellipseIn: CGRect(x: CGFloat(x) - 9, y: -90, width: 18, height: 18)),
                                     with: .color(Color(dinoHex: 0xD9B46C)), lineWidth: 2)
                }
                p.hourglass(at: CGPoint(x: 42, y: -5), size: 0.55)
            case 9:
                p.polygon([CGPoint(x: 13, y: -55), CGPoint(x: 36, y: -106), CGPoint(x: 54, y: -48)], color: 0xEF927B)
                p.dinosaur(color: 0x648FB5)
                var hat = Path()
                hat.move(to: CGPoint(x: -37, y: -96))
                hat.addQuadCurve(to: CGPoint(x: 38, y: -96), control: CGPoint(x: 0, y: -142))
                hat.addQuadCurve(to: CGPoint(x: -37, y: -96), control: CGPoint(x: 0, y: -85))
                p.context.fill(hat, with: .color(Color(dinoHex: 0xEF927B)))
                p.hourglass(at: CGPoint(x: 0, y: -101), size: 0.30)
                p.hourglass(at: CGPoint(x: 41, y: -3), size: 0.65)
            default:
                p.polygon([CGPoint(x: -27, y: -67), CGPoint(x: 40, y: -62), CGPoint(x: 54, y: -2), CGPoint(x: -43, y: -2)], color: 0x789BCF)
                p.dinosaur(color: 0xC69C62)
                p.polygon([CGPoint(x: -26, y: -101), CGPoint(x: -27, y: -124), CGPoint(x: -12, y: -113),
                           CGPoint(x: 0, y: -134), CGPoint(x: 13, y: -113), CGPoint(x: 29, y: -124), CGPoint(x: 26, y: -101)], color: 0xE8C66D)
                p.clock(at: CGPoint(x: 0, y: -28), time: .init(hour: 10, minute: 25), size: 15)
            }
            // Small costume and surface details make the bosses individual
            // characters while keeping the shared soft lighting and scale.
            switch worldID {
            case 2:
                for x: CGFloat in [-9, 27] {
                    for i in 0..<2 { p.volume(CGRect(x: x + CGFloat(i) * 6, y: -2, width: 5, height: 3), color: 0xDAEBE9) }
                }
                p.line([CGPoint(x: -32, y: -77), CGPoint(x: -29, y: -57), CGPoint(x: -23, y: -40)],
                       color: 0xC5E4EC, width: 3)
                p.clockPost(at: CGPoint(x: -44, y: 3), time: .init(hour: 7, minute: 30), size: 0.38)
            case 3:
                for x: CGFloat in [-32, 25] {
                    for i in 0..<3 { p.volume(CGRect(x: x, y: -104 + CGFloat(i) * 15, width: 7, height: 8), color: 0xF9DD8D) }
                }
                for i in 0..<3 { p.volume(CGRect(x: 22 + CGFloat(i) * 6, y: -49 + CGFloat(i) * 4, width: 4, height: 4), color: 0xF6C57F) }
            case 4:
                p.volume(CGRect(x: 44, y: -50, width: 22, height: 20), color: 0xC69C62)
                p.polygon([CGPoint(x: -4, y: -41), CGPoint(x: 4, y: -41), CGPoint(x: 7, y: -20), CGPoint(x: 0, y: -14), CGPoint(x: -7, y: -20)], color: 0xE8C66D)
                for x: CGFloat in [-15, 15] { p.line([CGPoint(x: x, y: -39), CGPoint(x: x, y: -19)], color: 0xA7C0D7, width: 1.3) }
            case 5:
                for x: CGFloat in [-24, 5] { p.rounded(CGRect(x: x, y: -11, width: 24, height: 14), radius: 6, color: 0x88A7B4) }
                p.line([CGPoint(x: -22, y: -60), CGPoint(x: -14, y: -47), CGPoint(x: -20, y: -37)], color: 0xC4E4DC, width: 1.5)
                p.line([CGPoint(x: 21, y: -101), CGPoint(x: 14, y: -93), CGPoint(x: 21, y: -83)], color: 0xDAEFE3, width: 1.4)
                p.crystals(at: CGPoint(x: 5, y: -103), size: 0.30)
            case 6:
                for side: CGFloat in [-1, 1] {
                    p.line([CGPoint(x: side * 28, y: -50), CGPoint(x: side * 40, y: -27)], color: 0x789BA1, width: 9)
                    p.volume(CGRect(x: side * 39 - 7, y: -32, width: 14, height: 14), color: 0xFFE08A)
                    p.volume(CGRect(x: side * 23 - 2, y: -54, width: 4, height: 4), color: 0xFFF1C3)
                }
                p.rounded(CGRect(x: -22, y: -45, width: 44, height: 23), radius: 6, color: 0x426F7D)
                p.context.draw(Text(verbatim: "12:45").font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(dinoHex: 0xFFF1B8)), at: CGPoint(x: 0, y: -33))
                for x: CGFloat in [-11, 0, 11] { p.ellipse(CGRect(x: x - 1.5, y: -19, width: 3, height: 3), 0xFFF1B8) }
            case 7:
                for side: CGFloat in [-1, 1] {
                    p.polygon([CGPoint(x: side * 21, y: -90), CGPoint(x: side * 28, y: -108), CGPoint(x: side * 4, y: -96)], color: 0xD4C1A1)
                    for i in 0..<3 {
                        let x = side * (29 + CGFloat(i) * 5)
                        p.line([CGPoint(x: x, y: -52), CGPoint(x: x + side * 2, y: -31)], color: side == -1 ? 0xF5DD99 : 0xA4BADD, width: 1.3)
                    }
                    p.line([CGPoint(x: side * 12, y: -3), CGPoint(x: side * 13, y: 3)], color: 0xAA9A7C, width: 2)
                }
            case 8:
                for side: CGFloat in [-1, 1] {
                    p.line([CGPoint(x: side * 24, y: -52), CGPoint(x: side * 54, y: -76)], color: 0xD9C7EE, width: 1.3)
                    p.line([CGPoint(x: side * 24, y: -52), CGPoint(x: side * 50, y: -28)], color: 0xD9C7EE, width: 1.3)
                }
                p.line([CGPoint(x: -4, y: -82), CGPoint(x: 4, y: -82)], color: 0xD9B46C, width: 2)
                p.line([CGPoint(x: 0, y: -40), CGPoint(x: 0, y: -19)], color: 0xC5AE85, width: 1)
                for y: CGFloat in [-34, -26] { p.volume(CGRect(x: 3, y: y, width: 3, height: 3), color: 0xD9B46C) }
            case 9:
                p.rounded(CGRect(x: -26, y: -22, width: 51, height: 7), radius: 2, color: 0xA47757)
                p.rounded(CGRect(x: -5, y: -24, width: 10, height: 10), radius: 2, color: 0xE8C66D)
                p.line([CGPoint(x: -29, y: -98), CGPoint(x: 0, y: -94), CGPoint(x: 30, y: -98)], color: 0xFFE1A1, width: 2)
                for i in 0..<3 {
                    p.line([CGPoint(x: 30, y: -52), CGPoint(x: 31 + CGFloat(i) * 6, y: -91 + CGFloat(i) * 13)], color: 0xF9B595, width: 1.2)
                }
            default:
                p.line([CGPoint(x: -29, y: -59), CGPoint(x: -41, y: -8)], color: 0xE8C66D, width: 2)
                p.line([CGPoint(x: 33, y: -56), CGPoint(x: 48, y: -8)], color: 0xE8C66D, width: 2)
                for x: CGFloat in [-15, 0, 15] { p.volume(CGRect(x: x - 3, y: -112, width: 6, height: 7), color: x == 0 ? 0xECA6AF : 0xA2D4CD) }
                p.line([CGPoint(x: -13, y: -47), CGPoint(x: -10, y: -39)], color: 0xE8C66D, width: 2)
                p.line([CGPoint(x: 13, y: -47), CGPoint(x: 10, y: -39)], color: 0xE8C66D, width: 2)
            }
        }
    }
}
