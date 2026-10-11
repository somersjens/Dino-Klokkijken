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
            sky.bush(at: CGPoint(x: left - 45, y: 64), size: 0.85)
            sky.bush(at: CGPoint(x: right + 50, y: 85), size: 1.0)
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
            painter.waterfall(at: CGPoint(x: right - 55 * scale, y: 620), size: scale)
            painter.palm(at: CGPoint(x: left + 13, y: 785), size: 0.96 * scale, flipped: false)
            painter.fern(at: CGPoint(x: left + 8, y: 885), size: 1.13 * scale, flipped: false)
            painter.flowers(at: CGPoint(x: right - 42, y: 965), size: 0.9 * scale)

            // Deeper jungle: buttress roots, large leaves, mossy boulders.
            painter.tree(at: CGPoint(x: left - 25, y: 1250), size: 1.02 * scale, leaning: 1)
            painter.palm(at: CGPoint(x: right + 4, y: 1370), size: 1.05 * scale, flipped: true)
            painter.rocks(at: CGPoint(x: right - 25, y: 1130), size: 1.2 * scale)
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
            painter.ruin(at: CGPoint(x: left + 55, y: 1845), size: scale, flipped: false)
            painter.ruin(at: CGPoint(x: right - 55, y: 1880), size: scale * 0.83, flipped: true)
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

    func bush(at point: CGPoint, size: CGFloat) {
        ellipse(CGRect(x: point.x - 74 * size, y: point.y - 12 * size, width: 148 * size, height: 28 * size), color: dark.opacity(0.12))
        for i in 0..<7 {
            leaf(at: point, length: CGFloat([76, 106, 98, 130, 93, 112, 78][i]) * size,
                 width: 28 * size, angle: Double(i * 27 - 82), color: [dark, green, light][i % 3])
        }
    }

    func fern(at point: CGPoint, size: CGFloat, flipped: Bool, opacity: Double = 1) {
        var c = context
        c.opacity = opacity
        let p = JunglePainter(context: c)
        let direction: CGFloat = flipped ? -1 : 1
        for frond in 0..<5 {
            let reach = CGFloat(frond - 2) * 27 * size * direction
            let height = CGFloat(93 - abs(frond - 2) * 17) * size
            var stem = Path()
            stem.move(to: point)
            stem.addQuadCurve(to: CGPoint(x: point.x + reach, y: point.y - height),
                              control: CGPoint(x: point.x + reach * 0.15, y: point.y - height * 0.7))
            c.stroke(stem, with: .color(dark), style: StrokeStyle(lineWidth: 2 * size, lineCap: .round))
            for pair in 1..<7 {
                let t = CGFloat(pair) / 7
                let origin = CGPoint(x: point.x + reach * t * t, y: point.y - height * (2 * t - t * t))
                for side in [-1.0, 1.0] {
                    p.leaf(at: origin, length: (22 - t * 10) * size, width: 7 * size,
                           angle: side * 60 + Double(reach / size) * 0.3, color: frond.isMultiple(of: 2) ? dark : green, vein: false)
                }
            }
        }
    }

    func tree(at base: CGPoint, size: CGFloat, leaning: CGFloat) {
        let crown = CGPoint(x: base.x + leaning * 18 * size, y: base.y - 260 * size)
        var trunk = Path()
        trunk.move(to: CGPoint(x: base.x - 35 * size, y: base.y))
        trunk.addQuadCurve(to: CGPoint(x: crown.x - 13 * size, y: crown.y),
                           control: CGPoint(x: base.x + 16 * size, y: base.y - 70 * size))
        trunk.addLine(to: CGPoint(x: crown.x + 19 * size, y: crown.y))
        trunk.addQuadCurve(to: CGPoint(x: base.x + 47 * size, y: base.y + 4 * size),
                           control: CGPoint(x: base.x - 5 * size, y: base.y - 55 * size))
        trunk.closeSubpath()
        context.fill(trunk, with: .color(Color(dinoHex: 0x8B9D62)))
        var bark = Path()
        bark.move(to: CGPoint(x: base.x + 6 * size, y: base.y - 20 * size))
        bark.addQuadCurve(to: crown, control: CGPoint(x: base.x + 2 * size, y: base.y - 155 * size))
        context.stroke(bark, with: .color(Color(dinoHex: 0xB3BD7E)), style: StrokeStyle(lineWidth: 7 * size, lineCap: .round))
        for i in 0..<6 {
            let x = crown.x + CGFloat(i % 3 - 1) * 43 * size
            let y = crown.y + CGFloat(i / 3) * 31 * size
            ellipse(CGRect(x: x - 58 * size, y: y - 42 * size, width: 116 * size, height: 76 * size), color: i < 3 ? dark : green)
            ellipse(CGRect(x: x - 48 * size, y: y - 38 * size, width: 77 * size, height: 31 * size), color: light.opacity(0.37))
        }
        bush(at: CGPoint(x: base.x - leaning * 19 * size, y: base.y + 8), size: size * 0.58)
    }

    func palm(at base: CGPoint, size: CGFloat, flipped: Bool) {
        let direction: CGFloat = flipped ? -1 : 1
        let top = CGPoint(x: base.x + direction * 38 * size, y: base.y - 172 * size)
        var stem = Path()
        stem.move(to: base)
        stem.addQuadCurve(to: top, control: CGPoint(x: base.x - direction * 8 * size, y: base.y - 118 * size))
        context.stroke(stem, with: .color(Color(dinoHex: 0x899559)), style: StrokeStyle(lineWidth: 17 * size, lineCap: .round))
        context.stroke(stem, with: .color(Color(dinoHex: 0xC0B77A)), style: StrokeStyle(lineWidth: 8 * size, lineCap: .round))
        for i in 0..<7 {
            leaf(at: top, length: CGFloat(i.isMultiple(of: 2) ? 120 : 103) * size,
                 width: 24 * size, angle: Double(i * 37 - 115), color: i.isMultiple(of: 2) ? dark : green)
        }
        ellipse(CGRect(x: top.x - 12 * size, y: top.y - 3 * size, width: 17 * size, height: 19 * size), color: Color(dinoHex: 0xB29D68))
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

    func rocks(at point: CGPoint, size: CGFloat) {
        for i in 0..<3 {
            let x = point.x + CGFloat(i - 1) * 24 * size
            let y = point.y + CGFloat(i % 2) * 9 * size
            let r = CGRect(x: x - 24 * size, y: y - 29 * size, width: 48 * size, height: 34 * size)
            context.fill(Path(roundedRect: r, cornerRadius: 13 * size), with: .color(Color(dinoHex: i == 1 ? 0x8C9F78 : 0xA4B58C)))
            ellipse(CGRect(x: r.minX + 3 * size, y: r.minY - 2 * size, width: 39 * size, height: 12 * size), color: light)
        }
    }

    func waterfall(at point: CGPoint, size: CGFloat) {
        let cliff = CGRect(x: point.x - 35 * size, y: point.y - 90 * size, width: 115 * size, height: 180 * size)
        context.fill(Path(roundedRect: cliff, cornerRadius: 28 * size), with: .color(Color(dinoHex: 0x8EAA86)))
        for i in 0..<4 {
            let r = CGRect(x: cliff.minX + CGFloat(i % 2) * 26 * size, y: cliff.minY + CGFloat(i) * 39 * size,
                           width: 96 * size, height: 31 * size)
            context.fill(Path(roundedRect: r, cornerRadius: 13 * size), with: .color(Color(dinoHex: i.isMultiple(of: 2) ? 0xA6BC92 : 0x789B7D)))
        }
        ellipse(CGRect(x: point.x - 77 * size, y: point.y + 60 * size, width: 190 * size, height: 105 * size), color: Color(dinoHex: 0xB0D5BB))
        ellipse(CGRect(x: point.x - 67 * size, y: point.y + 61 * size, width: 175 * size, height: 79 * size), color: Color(dinoHex: 0x79BFBB))
        ellipse(CGRect(x: point.x - 38 * size, y: point.y + 76 * size, width: 130 * size, height: 42 * size), color: Color(dinoHex: 0xA0D8CD))
        let water = CGRect(x: point.x - 4 * size, y: cliff.minY + 7 * size, width: 39 * size, height: 185 * size)
        context.fill(Path(roundedRect: water, cornerRadius: 15 * size),
                     with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xB9E8D4), Color(dinoHex: 0xE4F4D9)]),
                                           startPoint: CGPoint(x: 0, y: water.minY), endPoint: CGPoint(x: 0, y: water.maxY)))
        for i in 0..<3 {
            let r = CGRect(x: water.minX + CGFloat(i) * 12 * size + 4, y: water.minY + 15,
                           width: 3 * size, height: (110 + CGFloat(i % 2) * 40) * size)
            context.fill(Path(roundedRect: r, cornerRadius: 2), with: .color(.white.opacity(0.65)))
        }
        for i in 0..<5 {
            ellipse(CGRect(x: point.x - 18 * size + CGFloat(i) * 13 * size, y: point.y + 86 * size - CGFloat(i % 2) * 8,
                           width: 24 * size, height: 16 * size), color: Color(dinoHex: 0xE4F4D9))
        }
        bush(at: CGPoint(x: cliff.maxX, y: cliff.minY + 9), size: size * 0.6)
        rocks(at: CGPoint(x: point.x + 46 * size, y: point.y + 144 * size), size: size * 0.62)
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

    func ruin(at point: CGPoint, size: CGFloat, flipped: Bool) {
        for i in 0..<3 {
            let r = CGRect(x: point.x - 19 * size + CGFloat(i % 2) * 4 * size,
                           y: point.y - CGFloat(i + 1) * 26 * size, width: 37 * size, height: 24 * size)
            context.fill(Path(roundedRect: r, cornerRadius: 6 * size), with: .color(Color(dinoHex: i.isMultiple(of: 2) ? 0xB1BD91 : 0x9CAA85)))
            context.fill(Path(roundedRect: CGRect(x: r.minX + 5, y: r.minY + 3, width: r.width - 10, height: 4), cornerRadius: 2), with: .color(.white.opacity(0.22)))
        }
        fern(at: CGPoint(x: point.x + (flipped ? 10 : -10), y: point.y + 8), size: size * 0.45, flipped: flipped)
    }
}
