import SwiftUI

/// Body colors for the small crystal-cave miners.
enum MapDinoPalette {
    static let bodies: [[UInt32]] = [
        [0x9CC28D, 0x609574, 0x3C6C60], [0x91C6CA, 0x548D9E, 0x3C627D],
        [0xD1AA85, 0xA27660, 0x79534E], [0xB5ACD5, 0x817BA7, 0x555E85]
    ]
    static func body(_ variation: Int) -> [UInt32] { bodies[variation % bodies.count] }
}

/// Native desert art shares the playable route's cubic geometry and depth order.
/// All variation is deterministic, so scrolling never rearranges the landscape.
struct DinoDesertPainter {
    let context: GraphicsContext

    private func at(_ point: CGPoint, size: CGFloat = 1, mirror: Bool = false,
                    draw: (DinoDesertPainter) -> Void) {
        var c = context
        c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: mirror ? -size : size, y: size)
        draw(.init(context: c))
    }

    private func material(_ path: Path, _ colors: [UInt32], opacity: Double = 1) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(colors: colors.map { Color(dinoHex: $0).opacity(opacity) }),
            startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
    }

    private func line(_ points: [CGPoint], _ color: UInt32, _ width: CGFloat = 1, opacity: Double = 1) {
        var p = Path(); p.addLines(points)
        context.stroke(p, with: .color(Color(dinoHex: color).opacity(opacity)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func polygon(_ points: [CGPoint], _ colors: [UInt32], opacity: Double = 1) {
        var p = Path(); p.addLines(points); p.closeSubpath()
        material(p, colors, opacity: opacity)
    }

    private func oval(_ r: CGRect, _ colors: [UInt32], opacity: Double = 1) {
        material(Path(ellipseIn: r), colors, opacity: opacity)
    }

    private func shadow(width: CGFloat, height: CGFloat = 24, x: CGFloat = 10, y: CGFloat = 7) {
        let r = CGRect(x: x - width / 2, y: y - height / 2, width: width, height: height)
        var c = context
        c.translateBy(x: r.midX, y: r.midY); c.scaleBy(x: 1, y: height / width)
        c.fill(Path(ellipseIn: CGRect(x: -width / 2, y: -width / 2, width: width, height: width)),
               with: .radialGradient(Gradient(stops: [
                .init(color: Color(dinoHex: 0x8E542E).opacity(0.27), location: 0),
                .init(color: Color(dinoHex: 0xAD753D).opacity(0.12), location: 0.55),
                .init(color: .clear, location: 1)
               ]), center: .zero, startRadius: 0, endRadius: width / 2))
    }

    private func grain(in shape: Path, seed: Int, count: Int = 70) {
        let r = shape.boundingRect
        var c = context; c.clip(to: shape)
        for i in 0..<count {
            let x = r.minX + r.width * CGFloat((i * 73 + seed * 31 + 19) % 997) / 997
            let y = r.minY + r.height * CGFloat((i * 137 + seed * 47 + 11) % 991) / 991
            let radius: CGFloat = i.isMultiple(of: 5) ? 0.9 : 0.43
            c.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius * 1.8, height: radius)),
                   with: .color(Color(dinoHex: i.isMultiple(of: 3) ? 0xFFF0C0 : 0x915C3E).opacity(i.isMultiple(of: 5) ? 0.23 : 0.15)))
        }
    }

    /// Each band bends and changes thickness; the warm face stays one closed rock.
    private func strata(in shape: Path, width: CGFloat, height: CGFloat, seed: Int, distant: Bool) {
        var c = context; c.clip(to: shape)
        for i in 0..<(distant ? 5 : 9) {
            let y = -height + CGFloat(i) * height / (distant ? 4.5 : 8.5)
            let bend = CGFloat((i * 7 + seed * 3) % 13) - 6
            var seam = Path(); seam.move(to: CGPoint(x: -width, y: y + bend))
            seam.addCurve(to: CGPoint(x: width, y: y - bend * 0.7),
                          control1: CGPoint(x: -width * 0.32, y: y - 5), control2: CGPoint(x: width * 0.29, y: y + bend + 4))
            c.stroke(seam, with: .color(Color(dinoHex: i.isMultiple(of: 3) ? 0x9D603E : 0xF9D09A).opacity(distant ? 0.25 : 0.65)),
                     style: StrokeStyle(lineWidth: i.isMultiple(of: 3) ? 1.0 : 2.3 + CGFloat(i % 2), lineCap: .round))
            c.stroke(seam.offsetBy(dx: 0, dy: 2.4), with: .color(Color(dinoHex: 0xA76744).opacity(distant ? 0.08 : 0.22)), lineWidth: 0.9)
        }
        if !distant { grain(in: shape, seed: seed, count: 125) }
    }

    private func sandApron(width: CGFloat, y: CGFloat = 8) {
        var sand = Path(); sand.move(to: CGPoint(x: -width / 2, y: y + 3))
        sand.addCurve(to: CGPoint(x: width / 2, y: y), control1: CGPoint(x: -width * 0.16, y: y - 7), control2: CGPoint(x: width * 0.25, y: y + 7))
        sand.addQuadCurve(to: CGPoint(x: -width / 2, y: y + 3), control: CGPoint(x: width * 0.04, y: y + 21)); sand.closeSubpath()
        material(sand, [0xF9DCA5, 0xE9BE80], opacity: 0.88)
        var lip = Path(); lip.move(to: CGPoint(x: -width * 0.43, y: y + 2))
        lip.addQuadCurve(to: CGPoint(x: width * 0.35, y: y + 3), control: CGPoint(x: -width * 0.08, y: y - 3))
        context.stroke(lip, with: .color(Color(dinoHex: 0xFFECC0).opacity(0.65)), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
    }

    private func sandDetails(layout: WorldSceneryLayout) {
        let w = layout.width, s = layout.scale
        // Three faint tracks skirt the dunes instead of crossing the playable road.
        for (index, y, right): (Int, CGFloat, Bool) in [(0, 365, true), (1, 920, false), (2, 1475, true)] {
            for step in 0..<9 {
                let py = y + CGFloat(step) * 11 * s
                let x = layout.centerX(at: py) + (right ? 1 : -1) * (83 + CGFloat(step % 2) * 11) * s
                at(CGPoint(x: x, y: py), size: s * 0.47, mirror: step.isMultiple(of: 2)) { p in
                    var c = p.context; c.rotate(by: .degrees(Double(index * 11 - 16)))
                    let q = DinoDesertPainter(context: c)
                    q.oval(CGRect(x: -3, y: -2, width: 6, height: 6), [0xC09A64, 0xD3AE76], opacity: 0.44)
                    for toe in -1...1 {
                        q.line([CGPoint(x: CGFloat(toe) * 2, y: 0), CGPoint(x: CGFloat(toe) * 5, y: -7 + CGFloat(abs(toe)) * 2)], 0xB58F5C, 2.3, opacity: 0.38)
                    }
                }
            }
        }
        for i in 0..<15 {
            let y = CGFloat((i * 197 + 61) % 1570) + 20, x = CGFloat((i * 127 + 19) % max(1, Int(w)))
            guard abs(x - layout.centerX(at: y)) > 76 * s else { continue }
            at(CGPoint(x: x, y: y), size: s * 0.7) { p in
                p.line([CGPoint(x: -12, y: -9), CGPoint(x: -2, y: -5), CGPoint(x: 1, y: 1), CGPoint(x: 12, y: 6)], 0xBF9C65, 0.65, opacity: 0.46)
                p.line([CGPoint(x: -2, y: -5), CGPoint(x: 5, y: -11), CGPoint(x: 14, y: -10)], 0xBF9C65, 0.55, opacity: 0.4)
                p.line([CGPoint(x: 1, y: 1), CGPoint(x: -5, y: 8), CGPoint(x: -3, y: 13)], 0xE5BD80, 0.75)
            }
        }
    }

    func landscape(in size: CGSize, routeOffset: CGFloat, depth: WorldSceneryDepth) {
        let layout = WorldSceneryLayout(width: size.width, height: size.height, routeOffset: routeOffset)
        let w = size.width, h = size.height, s = layout.scale
        material(Path(CGRect(origin: .zero, size: size)), [0xFFE8B9, 0xF6D293, 0xF7D89E, 0xF0C88B])
        // Sunlit ground continues directly from the jungle, including behind the sign.
        for layer in 0..<3 {
            let baseY = 68 + CGFloat(layer) * 69
            for i in 0..<Int(ceil(w / (105 * s))) + 1 {
                let x = CGFloat(i) * 112 * s + (layer == 1 ? -42 : 8) * s
                var c = context; c.opacity = 0.22 + Double(layer) * 0.12
                DinoDesertPainter(context: c).at(CGPoint(x: x, y: baseY + CGFloat((i * 17) % 31)),
                    size: (0.55 + CGFloat(layer) * 0.11) * s) { p in
                    p.mesa(variation: i + layer, distant: true)
                }
            }
        }
        // Broad overlapping dunes and windward edges continue across tablets.
        for row in 0..<Int(ceil(h / 148)) + 1 {
            let y = CGFloat(row) * 148 + 148 + CGFloat(sin(Double(row) * 1.71)) * 19
            let sign: CGFloat = row.isMultiple(of: 2) ? 1 : -1
            let peak = w * (0.22 + CGFloat((row * 7) % 6) * 0.11)
            var dune = Path(); dune.move(to: CGPoint(x: -50, y: y + 60 * sign))
            dune.addCurve(to: CGPoint(x: w + 50, y: y + 20 * sign),
                          control1: CGPoint(x: peak, y: y - 95), control2: CGPoint(x: peak + w * 0.3, y: y + 80))
            let crest = dune
            dune.addLine(to: CGPoint(x: w + 50, y: y + 210)); dune.addLine(to: CGPoint(x: -50, y: y + 210)); dune.closeSubpath()
            // Transparent leeward slopes prevent rectangular caps where dunes meet.
            context.fill(dune, with: .linearGradient(Gradient(stops: [
                .init(color: Color(dinoHex: row.isMultiple(of: 2) ? 0xFFE7B1 : 0xFBDCA2).opacity(0.65), location: 0),
                .init(color: Color(dinoHex: 0xE8B875).opacity(0.18), location: 0.55),
                .init(color: .clear, location: 1)
            ]), startPoint: CGPoint(x: 0, y: y - 50), endPoint: CGPoint(x: 0, y: y + 210)))
            context.stroke(crest, with: .color(Color(dinoHex: 0xFFF2CC).opacity(0.48)), lineWidth: 1.2)
            for ripple in 0..<(3 + row % 3) {
                var r = Path(); let shift = CGFloat(ripple) * 5 + 9
                r.move(to: CGPoint(x: -12, y: y + shift + 34 * sign))
                r.addCurve(to: CGPoint(x: w + 12, y: y + shift + 14 * sign),
                           control1: CGPoint(x: w * 0.33, y: y + shift - 25), control2: CGPoint(x: w * 0.67, y: y + shift + 45))
                context.stroke(r, with: .color(Color(dinoHex: ripple.isMultiple(of: 2) ? 0xD6A566 : 0xFFF1C2).opacity(0.12)), lineWidth: 0.7)
            }
        }
        var route = context; route.translateBy(x: 0, y: routeOffset)
        let p = DinoDesertPainter(context: route)
        p.sandDetails(layout: layout)
        p.appendScenery(layout: layout, depth: depth)
        // The jungle dries into sand at the entry; lower dunes warm into the
        // next world's rock. Lava itself remains in the shared volcanic inlet.
        let end = CGRect(x: 0, y: h - 165, width: w, height: 165)
        context.fill(Path(end), with: .linearGradient(Gradient(colors: [.clear, Color(dinoHex: 0xFFD1A1)]),
            startPoint: CGPoint(x: 0, y: end.minY), endPoint: CGPoint(x: 0, y: h)))
    }

    /// Static drawing and the wind's occlusion mask use exactly the same placements.
    func appendScenery(layout: WorldSceneryLayout, depth: WorldSceneryDepth) {
        let w = layout.width, s = layout.scale, routeOffset = layout.routeOffset
        let p = self
        // Tall formations live on the outside of the bends. Their complete
        // silhouettes, including the crown behind the previous node, clear the road.
        let landmarks: [(CGFloat, Bool, Int, CGFloat, CGFloat, CGFloat)] = [
            (180, true, 0, 0.96, 68, 130),
            (450, false, 1, 1.03, 80, 88),
            (730, true, 2, 0.94, 65, 130),
            (1005, false, 3, 0.90, 65, 112),
            (1360, true, 4, 0.90, 65, 90),
            (1195, false, 5, 0.85, 64, 100)
        ]
        for (y, right, variation, factor, radius, rise) in landmarks {
            let point = layout.position(CGPoint(x: right ? w - 35 * s : 35 * s, y: y),
                                        radius: radius * s * factor, rise: rise * s * factor)
            depth.add(at: point.y + routeOffset, bounds: CGRect(x: point.x - 101 * s * factor, y: point.y + routeOffset - 155 * s * factor, width: 202 * s * factor, height: 216 * s * factor)) { p.scene(at: point, size: s * factor, variation: variation) }
        }
        for i in 0..<22 {
            let y = CGFloat(i) * 79 + 50, right = i % 4 < 2
            let factor = (0.53 + CGFloat((i * 7) % 5) * 0.09) * s
            let point = layout.position(CGPoint(x: right ? w - 10 * s : 10 * s, y: y), radius: 24 * factor, rise: 90 * factor)
            depth.add(at: point.y + routeOffset, bounds: CGRect(x: point.x - 62 * factor, y: point.y + routeOffset - 128 * factor, width: 124 * factor, height: 172 * factor)) {
                p.at(point, size: factor, mirror: !right) { art in
                    if i % 4 == 0 { art.cactus(variation: i) }
                    else if i % 4 == 1 { art.mesa(variation: i) }
                    else { art.dryShrub(variation: i) }
                    art.stones(variation: i)
                }
            }
        }
        // On wide screens the canyon continues beyond the central play column.
        // These outer shelves stay outside the complete route's occupied bounds.
        if w > 660 {
            for side in [false, true] {
                for i in 0..<5 {
                    let point = CGPoint(x: side ? w - 35 * s : 35 * s, y: 190 + CGFloat(i) * 340 + (side ? 57 : 0))
                    depth.add(at: point.y + routeOffset, bounds: CGRect(x: point.x - 145 * s, y: point.y + routeOffset - 180 * s, width: 290 * s, height: 245 * s)) {
                        p.at(point, size: s * (0.95 + CGFloat(i % 2) * 0.17), mirror: side) { edge in
                            edge.mesa(variation: i)
                            edge.at(CGPoint(x: 43, y: 14), size: 0.72) { $0.mesa(variation: i + 1) }
                            edge.at(CGPoint(x: 74, y: 24), size: 0.72) { $0.cactus(variation: i) }
                            edge.at(CGPoint(x: 11, y: 26), size: 0.67) { $0.dryShrub(variation: i) }
                            edge.stones(variation: i)
                        }
                    }
                }
            }
        }
        // Small dry details fill the ground without making a second border.
        for i in 0..<82 {
            let y = CGFloat((i * 137) % 1755) - 60
            let x = CGFloat((i * 83 + 31) % max(1, Int(w)))
            let gap = abs(x - layout.centerX(at: y))
            guard gap > 64 * s else { continue }
            let point = CGPoint(x: x, y: y)
            depth.add(at: y + routeOffset, bounds: CGRect(x: x - 35 * s, y: y + routeOffset - 35 * s, width: 70 * s, height: 70 * s)) {
                p.at(point, size: s * (0.28 + CGFloat(i % 3) * 0.08)) { detail in
                    if i % 5 == 0 { detail.dryShrub(variation: i) }
                    else if i % 9 == 0 { detail.bone(from: CGPoint(x: -13, y: 1), to: CGPoint(x: 11, y: -6), width: 4) }
                    else { detail.stones(variation: i) }
                }
            }
        }
    }

    func scene(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            switch variation % 6 {
            case 0:
                p.naturalArch()
                p.at(CGPoint(x: 48, y: 9), size: 0.65) { $0.cactus(variation: 1) }
                p.at(CGPoint(x: -50, y: 17), size: 0.61) { $0.dryShrub(variation: 3) }
            case 1: p.excavation()
            case 2:
                p.ruin()
                p.at(CGPoint(x: -47, y: 14), size: 0.62) { $0.cactus(variation: 2) }
                p.at(CGPoint(x: 41, y: 29), size: 0.66) { $0.dryShrub(variation: 5) }
            case 3:
                p.abandonedWell()
                p.at(CGPoint(x: -44, y: 8), size: 0.63) { $0.mesa(variation: 3) }
                p.at(CGPoint(x: 43, y: 19), size: 0.6) { $0.dryShrub(variation: 4) }
            case 4:
                p.mesa(variation: 1)
                p.at(CGPoint(x: -34, y: 19), size: 0.78) { $0.ribs() }
                p.at(CGPoint(x: 39, y: 23), size: 0.75) { $0.cactus(variation: 1) }
            default:
                p.sundial()
                p.at(CGPoint(x: -45, y: 15), size: 0.56) { $0.ruin() }
                p.at(CGPoint(x: 45, y: 18), size: 0.6) { $0.dryShrub(variation: 1) }
            }
            p.stones(variation: variation + 3)
        }
    }

    func clearing(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.shadow(width: 165, height: 37)
            p.oval(CGRect(x: -70, y: -3, width: 140, height: 23), [0xFBE4B3, 0xD5A56A, 0xB5814D])
            for i in 0..<7 {
                let a = Double(i) * .pi / 6
                p.at(CGPoint(x: CGFloat(cos(a)) * 62, y: CGFloat(sin(a)) * 11 + 10), size: 0.42) { $0.mesa(variation: i) }
            }
            p.at(CGPoint(x: -55, y: 10), size: 0.61) { $0.dryShrub(variation: 3) }
            p.at(CGPoint(x: 60, y: 0), size: 0.47) { $0.cactus(variation: 2) }
        }
    }

    private func mesa(variation: Int, distant: Bool = false) {
        let h: CGFloat = distant ? 96 + CGFloat((variation * 17) % 43) : 64 + CGFloat(variation % 3) * 19
        let w: CGFloat = distant ? 91 + CGFloat(variation % 3) * 13 : 76
        let lean = CGFloat(variation % 5 - 2) * 2
        shadow(width: w * 1.35, height: 19)
        var rock = Path(); rock.move(to: CGPoint(x: -w * 0.66, y: 7))
        rock.addQuadCurve(to: CGPoint(x: -w * 0.47, y: -h * 0.23), control: CGPoint(x: -w * 0.62, y: -h * 0.12))
        for point in [CGPoint(x: -w * 0.39, y: -h * 0.25), CGPoint(x: -w * 0.34, y: -h * 0.43)] { rock.addLine(to: point) }
        rock.addCurve(to: CGPoint(x: -w * 0.27 + lean, y: -h * 0.91), control1: CGPoint(x: -w * 0.25, y: -h * 0.55), control2: CGPoint(x: -w * 0.34, y: -h * 0.78))
        for point in [CGPoint(x: -w * 0.21 + lean, y: -h + 1), CGPoint(x: -w * 0.06 + lean, y: -h - 2),
                       CGPoint(x: w * 0.02 + lean, y: -h + 1), CGPoint(x: w * 0.18 + lean, y: -h - 3)] { rock.addLine(to: point) }
        rock.addQuadCurve(to: CGPoint(x: w * 0.29, y: -h * 0.79), control: CGPoint(x: w * 0.28 + lean, y: -h * 0.96))
        for point in [CGPoint(x: w * 0.28, y: -h * 0.61), CGPoint(x: w * 0.34, y: -h * 0.57), CGPoint(x: w * 0.33, y: -h * 0.46)] { rock.addLine(to: point) }
        rock.addCurve(to: CGPoint(x: w * 0.53, y: -h * 0.16), control1: CGPoint(x: w * 0.40, y: -h * 0.36), control2: CGPoint(x: w * 0.40, y: -h * 0.20))
        rock.addQuadCurve(to: CGPoint(x: w * 0.64, y: 6), control: CGPoint(x: w * 0.57, y: -h * 0.05)); rock.closeSubpath()
        material(rock, distant ? [0xD7AE93, 0xCDA082, 0xDDB48F] : [0xEDBD89, 0xD28C57, 0xAD704B, 0xD09D69])
        var c = context; c.clip(to: rock)
        let p = DinoDesertPainter(context: c)
        var shadowFace = Path(); shadowFace.move(to: CGPoint(x: 4 + lean, y: -h - 3))
        shadowFace.addCurve(to: CGPoint(x: 10, y: -h * 0.43), control1: CGPoint(x: 18, y: -h * 0.78), control2: CGPoint(x: 1, y: -h * 0.65))
        for point in [CGPoint(x: 28, y: 12), CGPoint(x: w, y: 12), CGPoint(x: w, y: -h - 5)] { shadowFace.addLine(to: point) }; shadowFace.closeSubpath()
        p.material(shadowFace, distant ? [0xC59C83, 0xCCA487] : [0xD09464, 0xAA6948, 0xB47B50], opacity: 0.82)
        strata(in: rock, width: w, height: h, seed: variation, distant: distant)
        if !distant {
            for i in 0..<5 {
                let x = CGFloat(i) * 10 - 23, y = -h * (0.24 + CGFloat(i % 3) * 0.2)
                p.line([CGPoint(x: x, y: y - 10), CGPoint(x: x - 2, y: y + 1), CGPoint(x: x + 2, y: y + 8)], 0x925C40, 0.9, opacity: 0.6)
                p.line([CGPoint(x: x - 2, y: y + 1), CGPoint(x: x - 7, y: y + 3)], 0xA06944, 0.7, opacity: 0.55)
                p.line([CGPoint(x: x - 1.2, y: y - 9), CGPoint(x: x - 3, y: y)], 0xFFDEAB, 0.6, opacity: 0.8)
            }
            // Eroded pockets sit in the rock face, below an actual little lip.
            for i in 0..<3 {
                let x = CGFloat(i) * 14 - 21, y = -h * (0.19 + CGFloat(i % 2) * 0.34)
                p.oval(CGRect(x: x, y: y, width: 6 + CGFloat(i), height: 2.8), [0xAA7048, 0xB78254], opacity: 0.55)
                p.line([CGPoint(x: x - 1, y: y), CGPoint(x: x + 5, y: y - 1)], 0xF4CD98, 0.8)
            }
        }
        p.polygon([CGPoint(x: -w * 0.28 + lean, y: -h * 0.91), CGPoint(x: -w * 0.21 + lean, y: -h + 1),
                   CGPoint(x: w * 0.18 + lean, y: -h - 3), CGPoint(x: w * 0.25, y: -h * 0.92),
                   CGPoint(x: 1, y: -h + 9), CGPoint(x: -18, y: -h + 8)],
                  distant ? [0xE3BE9D, 0xD4A88C] : [0xFFDFAB, 0xE5B37B, 0xBD8657])
        sandApron(width: w * 1.4, y: 5)
    }

    private func naturalArch() {
        shadow(width: 172, height: 31, x: 14)
        var arch = Path(); arch.move(to: CGPoint(x: -74, y: 5))
        arch.addQuadCurve(to: CGPoint(x: -61, y: -40), control: CGPoint(x: -66, y: -16))
        for point in [CGPoint(x: -62, y: -50), CGPoint(x: -57, y: -54)] { arch.addLine(to: point) }
        arch.addCurve(to: CGPoint(x: -45, y: -90), control1: CGPoint(x: -53, y: -69), control2: CGPoint(x: -55, y: -82))
        for point in [CGPoint(x: -38, y: -95), CGPoint(x: -34, y: -103)] { arch.addLine(to: point) }
        arch.addCurve(to: CGPoint(x: 16, y: -117), control1: CGPoint(x: -23, y: -114), control2: CGPoint(x: -2, y: -119))
        for point in [CGPoint(x: 23, y: -113), CGPoint(x: 31, y: -114), CGPoint(x: 45, y: -99)] { arch.addLine(to: point) }
        arch.addCurve(to: CGPoint(x: 63, y: -56), control1: CGPoint(x: 57, y: -91), control2: CGPoint(x: 58, y: -70))
        for point in [CGPoint(x: 61, y: -45), CGPoint(x: 68, y: -33), CGPoint(x: 66, y: -21)] { arch.addLine(to: point) }
        arch.addQuadCurve(to: CGPoint(x: 77, y: 5), control: CGPoint(x: 71, y: -7))
        arch.addLine(to: CGPoint(x: 40, y: 6))
        arch.addCurve(to: CGPoint(x: 23, y: -72), control1: CGPoint(x: 44, y: -23), control2: CGPoint(x: 40, y: -58))
        arch.addCurve(to: CGPoint(x: -23, y: -76), control1: CGPoint(x: 11, y: -86), control2: CGPoint(x: -12, y: -91))
        arch.addCurve(to: CGPoint(x: -38, y: 4), control1: CGPoint(x: -43, y: -59), control2: CGPoint(x: -34, y: -25)); arch.closeSubpath()
        material(arch, [0xF4C58B, 0xD99860, 0xB8754C])
        var c = context; c.clip(to: arch)
        let p = DinoDesertPainter(context: c)
        var side = Path(); side.move(to: CGPoint(x: 19, y: -119))
        side.addCurve(to: CGPoint(x: 38, y: -57), control1: CGPoint(x: 28, y: -99), control2: CGPoint(x: 42, y: -84))
        for point in [CGPoint(x: 57, y: 8), CGPoint(x: 88, y: 8), CGPoint(x: 74, y: -99)] { side.addLine(to: point) }; side.closeSubpath()
        p.material(side, [0xD49864, 0xA86A46, 0xAB714B])
        strata(in: arch, width: 84, height: 118, seed: 19, distant: false)
        var underside = Path(); underside.move(to: CGPoint(x: -39, y: 4))
        underside.addCurve(to: CGPoint(x: -23, y: -76), control1: CGPoint(x: -37, y: -31), control2: CGPoint(x: -43, y: -61))
        underside.addCurve(to: CGPoint(x: 23, y: -72), control1: CGPoint(x: -13, y: -92), control2: CGPoint(x: 11, y: -86))
        p.context.stroke(underside, with: .color(Color(dinoHex: 0xA96B43).opacity(0.72)), style: StrokeStyle(lineWidth: 8, lineCap: .round))
        p.context.stroke(underside.offsetBy(dx: -2, dy: -2), with: .color(Color(dinoHex: 0xFFE3AB).opacity(0.9)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        for (x, y): (CGFloat, CGFloat) in [(-51, -54), (-37, -91), (-8, -107), (26, -98), (53, -44)] {
            p.line([CGPoint(x: x, y: y - 7), CGPoint(x: x - 3, y: y + 3), CGPoint(x: x + 2, y: y + 11)], 0x9F6542, 0.9)
            p.line([CGPoint(x: x - 3, y: y + 3), CGPoint(x: x - 7, y: y + 4)], 0xA8754C, 0.7)
        }
        // Worn horizontal pockets catch light below the wind-carved shoulders.
        for (x, y, width): (CGFloat, CGFloat, CGFloat) in [(-54, -39, 11), (43, -24, 12), (-25, -102, 9)] {
            p.oval(CGRect(x: x, y: y, width: width, height: 3), [0xA56943, 0xC78D59], opacity: 0.7)
            p.line([CGPoint(x: x - 1, y: y), CGPoint(x: x + width - 2, y: y - 1)], 0xFFDC9C, 0.9)
        }
        for (x, y, f): (CGFloat, CGFloat, CGFloat) in [(-57, 6, 0.42), (59, 11, 0.46), (-37, 15, 0.24)] {
            at(CGPoint(x: x, y: y), size: f) { $0.mesa(variation: 2) }
        }
        sandApron(width: 161, y: 11)
    }

    private func cactus(variation: Int) {
        let height: CGFloat = 82 + CGFloat(variation % 3) * 12
        shadow(width: 64, height: 15)
        let silhouette = Path(roundedRect: CGRect(x: -9, y: -height, width: 19, height: height + 3), cornerRadius: 9)
        for side: CGFloat in [-1, 1] {
            if variation % 3 == 2 && side == 1 { continue }
            let top = -height * (side == -1 ? 0.70 : 0.49)
            var arm = Path(); arm.move(to: CGPoint(x: side * 4, y: -height * 0.34))
            arm.addLine(to: CGPoint(x: side * 21, y: -height * 0.34))
            arm.addQuadCurve(to: CGPoint(x: side * 28, y: -height * 0.45), control: CGPoint(x: side * 28, y: -height * 0.34))
            arm.addLine(to: CGPoint(x: side * 28, y: top))
            context.stroke(arm, with: .color(Color(dinoHex: 0x52683A)), style: StrokeStyle(lineWidth: 11, lineCap: .round, lineJoin: .round))
            context.stroke(arm.offsetBy(dx: -1.5, dy: -1), with: .color(Color(dinoHex: 0xA4AB61)), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        }
        // Main column owns its gradient; ribs curve into its rounded crown.
        material(silhouette, [0xB5BB79, 0x87934F, 0x4E683C, 0x3F5837])
        var c = context; c.clip(to: silhouette)
        for i in 0..<5 {
            let x = CGFloat(i) * 4 - 8
            var rib = Path(); rib.move(to: CGPoint(x: 0, y: -height + 1))
            rib.addCurve(to: CGPoint(x: x, y: 3), control1: CGPoint(x: x, y: -height + 8), control2: CGPoint(x: x, y: -height * 0.4))
            c.stroke(rib, with: .color(Color(dinoHex: i.isMultiple(of: 2) ? 0xD2CD88 : 0x455D33).opacity(0.7)), lineWidth: 1)
        }
        for i in 0..<19 {
            let y = -height + 11 + CGFloat(i / 3) * 12, x = CGFloat(i % 3) * 6 - 5
            line([CGPoint(x: x - 2, y: y - 1), CGPoint(x: x + 2, y: y + 2)], 0xEEE0A3, 0.7, opacity: 0.85)
        }
        oval(CGRect(x: -19, y: -2, width: 40, height: 10), [0xF4D297, 0xD2AA6F])
        if variation % 4 == 0 {
            for i in 0..<4 { oval(CGRect(x: -5 + CGFloat(i % 2) * 5, y: -height - 3 + CGFloat(i / 2) * 3, width: 6, height: 5), [0xF6D49B, 0xCF8C5E]) }
        }
    }

    private func dryShrub(variation: Int) {
        shadow(width: 59, height: 10, x: 3, y: 6)
        for i in 0..<17 {
            let angle = Double(i) * 2.39996
            let length = CGFloat(17 + (i * 11 + variation) % 24)
            let end = CGPoint(x: CGFloat(cos(angle)) * length * 0.75, y: -abs(CGFloat(sin(angle))) * length - 4)
            let start = CGPoint(x: CGFloat(i % 3 - 1) * 3, y: 5)
            var stem = Path(); stem.move(to: start)
            stem.addQuadCurve(to: end, control: CGPoint(x: end.x * 0.28, y: end.y * 0.63))
            context.stroke(stem, with: .color(Color(dinoHex: i.isMultiple(of: 3) ? 0xB39B60 : 0x967346)), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
            for j in 1...3 {
                let t = CGFloat(j) / 4
                let x = start.x + (end.x - start.x) * t, y = start.y + (end.y - start.y) * t
                line([CGPoint(x: x - 4, y: y - 3), CGPoint(x: x, y: y), CGPoint(x: x + 3, y: y - 4)], 0xD8B979, 0.7, opacity: 0.85)
            }
        }
    }

    private func stones(variation: Int) {
        for i in 0..<7 {
            let x = CGFloat((i * 23 + variation * 7) % 91) - 45, y = CGFloat((i * 7) % 21) + 6
            let w = CGFloat(5 + (i * 3) % 8)
            oval(CGRect(x: x + 2, y: y + 2, width: w + 4, height: 4), [0xB68A55, 0xD5AB71], opacity: 0.35)
            polygon([CGPoint(x: x, y: y), CGPoint(x: x + 2, y: y - 4), CGPoint(x: x + w - 3, y: y - 5),
                     CGPoint(x: x + w, y: y), CGPoint(x: x + w - 2, y: y + 3), CGPoint(x: x + 1, y: y + 2)], [0xFFE0A5, 0xCD9560, 0xB17C4F])
        }
    }

    private func block(_ r: CGRect, variation: Int = 0) {
        let chip: CGFloat = variation.isMultiple(of: 2) ? 4 : 2
        var stone = Path(); stone.move(to: CGPoint(x: r.minX + 3, y: r.minY))
        stone.addQuadCurve(to: CGPoint(x: r.maxX - chip, y: r.minY - 1), control: CGPoint(x: r.midX, y: r.minY - 1.5))
        for point in [CGPoint(x: r.maxX, y: r.minY + 4), CGPoint(x: r.maxX - 1, y: r.maxY - 2), CGPoint(x: r.maxX - 5, y: r.maxY)] { stone.addLine(to: point) }
        stone.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - 1), control: CGPoint(x: r.midX, y: r.maxY + 1))
        stone.addQuadCurve(to: CGPoint(x: r.minX + 3, y: r.minY), control: CGPoint(x: r.minX - 2, y: r.midY)); stone.closeSubpath()
        material(stone, [0xFFE0A6, 0xDCB075, 0xB58453])
        grain(in: stone, seed: variation + 5, count: 16)
        polygon([CGPoint(x: r.maxX - chip - 1, y: r.minY + 1), CGPoint(x: r.maxX - 2, y: r.minY + 5),
                 CGPoint(x: r.maxX - 3, y: r.maxY - 3), CGPoint(x: r.maxX - 7, y: r.maxY - 2)], [0xD0A06A, 0xB38251], opacity: 0.5)
        line([CGPoint(x: r.minX + 3, y: r.minY + 2), CGPoint(x: r.maxX - 5, y: r.minY + 1)], 0xFFEBC0, 1.1)
        if variation % 3 == 0 {
            line([CGPoint(x: r.minX + 8, y: r.minY + 5), CGPoint(x: r.minX + 6, y: r.minY + 9), CGPoint(x: r.minX + 10, y: r.maxY - 3)], 0xA77A4F, 0.8, opacity: 0.65)
        }
    }

    private func ruin() {
        shadow(width: 151, height: 28)
        // Unequal columns and a missing crown make this a deserted ruin.
        for side: CGFloat in [-1, 1] {
            for i in 0..<(side < 0 ? 5 : 4) {
                at(CGPoint(x: side * 40 + CGFloat(i % 2), y: -CGFloat(i + 1) * 19)) { p in
                    var c = p.context; c.rotate(by: .degrees(Double(i % 3 - 1) * 1.8))
                    DinoDesertPainter(context: c).block(CGRect(x: -12, y: 0, width: 25, height: 18), variation: i)
                }
            }
        }
        for i in 0..<7 {
            if i == 3 { continue }
            let angle = Double(i) * .pi / 8 + .pi * 0.12
            var c = context; c.translateBy(x: CGFloat(cos(angle)) * 40, y: -75 - CGFloat(sin(angle)) * 31)
            c.rotate(by: .radians(-angle + .pi / 2))
            DinoDesertPainter(context: c).block(CGRect(x: -10, y: -13, width: 20, height: 25), variation: i + 1)
        }
        for i in 0..<4 { block(CGRect(x: -61 + CGFloat(i) * 30, y: 1 + CGFloat(i % 2) * 7, width: 25, height: 12), variation: i) }
        // Fallen capitals lie partially buried at the foot of the gate.
        at(CGPoint(x: 45, y: 19), size: 0.8) { p in
            var c = p.context; c.rotate(by: .degrees(13))
            DinoDesertPainter(context: c).block(CGRect(x: -18, y: -14, width: 36, height: 18), variation: 3)
        }
        at(CGPoint(x: 16, y: 19), size: 0.68) { p in
            var c = p.context; c.rotate(by: .degrees(-26))
            DinoDesertPainter(context: c).block(CGRect(x: -10, y: -13, width: 20, height: 25), variation: 6)
        }
        // A worn relief belongs to the column's surviving middle stone.
        for x: CGFloat in [-43, -38, -33] {
            line([CGPoint(x: x, y: -59), CGPoint(x: x - 1, y: -54)], 0xA87C4E, 0.8, opacity: 0.65)
        }
        line([CGPoint(x: -44, y: -51), CGPoint(x: -39, y: -48), CGPoint(x: -33, y: -51)], 0xB38654, 0.7)
        sandApron(width: 143, y: 16)
        at(CGPoint(x: -51, y: 22), size: 0.5) { $0.dryShrub(variation: 1) }
    }

    private func bone(from start: CGPoint, to end: CGPoint, width: CGFloat) {
        var p = Path(); p.move(to: start); p.addLine(to: end)
        context.stroke(p.offsetBy(dx: 1.5, dy: 2), with: .color(Color(dinoHex: 0xAA7E4E).opacity(0.55)), style: StrokeStyle(lineWidth: width + 1, lineCap: .round))
        context.stroke(p, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFF1CE), Color(dinoHex: 0xDCC69A)]), startPoint: start, endPoint: end), style: StrokeStyle(lineWidth: width, lineCap: .round))
        for point in [start, end] {
            for sign: CGFloat in [-1, 1] {
                oval(CGRect(x: point.x - width * 0.42 + sign * width * 0.25, y: point.y - width * 0.52, width: width * 0.85, height: width * 1.05), [0xFFF4D7, 0xDFCAA1, 0xC2A77C])
            }
        }
    }

    private func ribs() {
        shadow(width: 130, height: 25, x: 5)
        bone(from: CGPoint(x: -55, y: -34), to: CGPoint(x: 40, y: -20), width: 5)
        for i in 0..<8 {
            let x = CGFloat(i) * 11 - 48
            var rib = Path(); rib.move(to: CGPoint(x: x, y: -32 + CGFloat(i) * 1.4))
            let tip: CGFloat = i == 6 ? 0 : 8 + CGFloat(i % 3) * 2
            rib.addCurve(to: CGPoint(x: x + 9, y: tip), control1: CGPoint(x: x - 16 - CGFloat(i % 2) * 3, y: -34), control2: CGPoint(x: x - 19, y: -2))
            context.stroke(rib.offsetBy(dx: 2, dy: 2), with: .color(Color(dinoHex: 0xAD8455).opacity(0.6)), style: StrokeStyle(lineWidth: 6.5, lineCap: .round))
            context.stroke(rib, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFF2CF), Color(dinoHex: 0xE7D3AD), Color(dinoHex: 0xC6AD83)]), startPoint: CGPoint(x: x - 10, y: -36), endPoint: CGPoint(x: x + 10, y: 12)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            oval(CGRect(x: x - 3, y: -35 + CGFloat(i) * 1.4, width: 7, height: 5), [0xFFF1CC, 0xD8BE93])
            line([CGPoint(x: x - 3, y: -34 + CGFloat(i) * 1.4), CGPoint(x: x - 1, y: -39 + CGFloat(i) * 1.4)], 0xE8D5B1, 2.2)
            if i == 2 || i == 5 {
                line([CGPoint(x: x - 12, y: -14), CGPoint(x: x - 8, y: -13)], 0xBDA179, 0.7)
            }
        }
    }

    private func skull() {
        var skull = Path(); skull.move(to: CGPoint(x: -26, y: 0))
        skull.addCurve(to: CGPoint(x: -18, y: -30), control1: CGPoint(x: -33, y: -13), control2: CGPoint(x: -29, y: -28))
        skull.addCurve(to: CGPoint(x: 8, y: -27), control1: CGPoint(x: -8, y: -40), control2: CGPoint(x: 1, y: -33))
        skull.addQuadCurve(to: CGPoint(x: 33, y: -14), control: CGPoint(x: 23, y: -22))
        skull.addQuadCurve(to: CGPoint(x: 31, y: -2), control: CGPoint(x: 40, y: -2))
        for point in [CGPoint(x: 11, y: 7), CGPoint(x: -9, y: 5), CGPoint(x: -26, y: 0)] { skull.addLine(to: point) }; skull.closeSubpath()
        material(skull, [0xFFF3D7, 0xEAD1A4, 0xC8AB7D])
        grain(in: skull, seed: 47, count: 39)
        oval(CGRect(x: -22, y: -25, width: 18, height: 16), [0x9E7E57, 0x806344, 0xC0A075])
        oval(CGRect(x: -18, y: -24, width: 10, height: 9), [0x69503A, 0xA38458])
        oval(CGRect(x: 18, y: -14, width: 7, height: 6), [0x8A6947, 0xAE8A59])
        polygon([CGPoint(x: 1, y: -14), CGPoint(x: 11, y: -12), CGPoint(x: 5, y: -5)], [0xA78658, 0xC0A375])
        bone(from: CGPoint(x: -17, y: 8), to: CGPoint(x: 29, y: 10), width: 5)
        for i in 0..<7 {
            let x = CGFloat(i) * 5 + 1
            polygon([CGPoint(x: x, y: 1), CGPoint(x: x + 4, y: 1), CGPoint(x: x + 2, y: 7)], [0xFFF5D9, 0xD4BA8C])
        }
        line([CGPoint(x: -2, y: -31), CGPoint(x: -6, y: -23), CGPoint(x: -2, y: -17)], 0xB99B70, 0.8)
    }

    private func rope(from a: CGPoint, to b: CGPoint) {
        var p = Path(); p.move(to: a)
        p.addQuadCurve(to: b, control: CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 + 13))
        context.stroke(p, with: .color(Color(dinoHex: 0x92643A)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        context.stroke(p.offsetBy(dx: 0, dy: -0.7), with: .color(Color(dinoHex: 0xE2C08C)), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
    }

    private func excavation() {
        shadow(width: 174, height: 49, x: 6, y: 9)
        var pit = Path(); pit.move(to: CGPoint(x: -77, y: -10))
        pit.addCurve(to: CGPoint(x: 19, y: -24), control1: CGPoint(x: -65, y: -31), control2: CGPoint(x: -18, y: -22))
        pit.addCurve(to: CGPoint(x: 78, y: 9), control1: CGPoint(x: 58, y: -27), control2: CGPoint(x: 70, y: -8))
        pit.addCurve(to: CGPoint(x: -6, y: 45), control1: CGPoint(x: 89, y: 29), control2: CGPoint(x: 26, y: 41))
        pit.addCurve(to: CGPoint(x: -77, y: -10), control1: CGPoint(x: -48, y: 53), control2: CGPoint(x: -93, y: 14)); pit.closeSubpath()
        material(pit, [0xD6AC75, 0xF9E0AF, 0xE4BE87]); grain(in: pit, seed: 13, count: 110)
        var soil = context; soil.clip(to: pit)
        soil.stroke(pit.offsetBy(dx: 0, dy: 2.5), with: .color(Color(dinoHex: 0xBB905D).opacity(0.36)), lineWidth: 4)
        at(CGPoint(x: -13, y: -9), size: 0.87) { $0.ribs() }
        at(CGPoint(x: 42, y: 4), size: 0.89) { $0.skull() }
        bone(from: CGPoint(x: -54, y: 19), to: CGPoint(x: -26, y: 23), width: 5)
        bone(from: CGPoint(x: -22, y: 10), to: CGPoint(x: -13, y: 33), width: 4)
        // A discarded brush and trowel tell the story of the empty dig.
        line([CGPoint(x: 47, y: 26), CGPoint(x: 61, y: 15)], 0x8B633D, 3)
        polygon([CGPoint(x: 58, y: 16), CGPoint(x: 66, y: 8), CGPoint(x: 69, y: 15), CGPoint(x: 62, y: 21)], [0x9BACA4, 0x627D79])
        line([CGPoint(x: 25, y: 29), CGPoint(x: 39, y: 22)], 0x9D7045, 2.5)
        polygon([CGPoint(x: 23, y: 28), CGPoint(x: 28, y: 33), CGPoint(x: 20, y: 38), CGPoint(x: 15, y: 33)], [0xE2C58E, 0xB68B54])
        at(CGPoint(x: -66, y: 43), size: 0.53) { $0.dryShrub(variation: 5) }
    }

    private func abandonedWell() {
        shadow(width: 132, height: 27)
        for side: CGFloat in [-1, 1] {
            material(Path(roundedRect: CGRect(x: side * 29 - 3, y: -103, width: 6, height: 96), cornerRadius: 2), [0xC4A06B, 0x8F633F, 0x725035])
            line([CGPoint(x: side * 29, y: -98), CGPoint(x: side * 30, y: -15)], 0xDDC08D, 0.9)
            for i in 0..<2 {
                let x = side * 29 + CGFloat(i) * 2 - 1
                line([CGPoint(x: x, y: -87), CGPoint(x: x - 1, y: -63), CGPoint(x: x + 1, y: -36)], 0x674B32, 0.55, opacity: 0.65)
            }
            oval(CGRect(x: side * 29 - 1, y: -96, width: 2, height: 2), [0x6C5B43, 0xA18C64])
        }
        line([CGPoint(x: -39, y: -100), CGPoint(x: 37, y: -105)], 0x835A36, 9)
        line([CGPoint(x: -39, y: -103), CGPoint(x: 35, y: -108)], 0xD4AE77, 2)
        // Only a few roof timbers remain; there is no water or green planting.
        for i in 0..<4 {
            let x = -31 + CGFloat(i) * 19
            line([CGPoint(x: x - 8, y: -99), CGPoint(x: x + 10, y: -118)], 0xA37848, 5)
        }
        rope(from: CGPoint(x: 2, y: -104), to: CGPoint(x: 4, y: -45))
        for i in 0..<3 {
            line([CGPoint(x: 4, y: -46), CGPoint(x: 2 + CGFloat(i) * 2, y: -42 + CGFloat(i % 2))], 0xBE9B69, 0.7)
        }
        for i in 0..<5 {
            block(CGRect(x: -43 + CGFloat(i) * 17, y: -24, width: 18, height: 24), variation: i)
        }
        oval(CGRect(x: -45, y: -34, width: 90, height: 26), [0xFFDBA0, 0xCAA16B, 0xA87A4D])
        oval(CGRect(x: -32, y: -30, width: 64, height: 16), [0x745238, 0xA68152, 0xD4B17B])
        for i in 0..<6 {
            let x = CGFloat(i) * 13 - 39
            block(CGRect(x: x, y: -30 + abs(CGFloat(i) - 2.5) * 2, width: 14, height: 7), variation: i)
        }
        polygon([CGPoint(x: 34, y: -4), CGPoint(x: 57, y: -7), CGPoint(x: 53, y: 14), CGPoint(x: 37, y: 16)], [0xC4A16E, 0x8B6540])
        for x: CGFloat in [39, 45, 51] { line([CGPoint(x: x, y: -3), CGPoint(x: x - 1, y: 11)], 0xE4C28C, 0.8) }
        var handle = Path(); handle.addArc(center: CGPoint(x: 46, y: -5), radius: 10, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        context.stroke(handle, with: .color(Color(dinoHex: 0x76573A)), lineWidth: 1.6)
        line([CGPoint(x: 46, y: -2), CGPoint(x: 43, y: 4), CGPoint(x: 46, y: 9)], 0x735638, 0.8)
        at(CGPoint(x: -10, y: 22), size: 0.7) { $0.deadwood() }
        at(CGPoint(x: -38, y: 15), size: 0.66) { $0.dryShrub(variation: 2) }
    }

    private func deadwood() {
        shadow(width: 58, height: 8, x: 5, y: 4)
        var branch = Path(); branch.move(to: CGPoint(x: -28, y: 2))
        branch.addQuadCurve(to: CGPoint(x: 27, y: -4), control: CGPoint(x: 0, y: -9))
        context.stroke(branch, with: .color(Color(dinoHex: 0x9D774C)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        context.stroke(branch.offsetBy(dx: 0, dy: -1.2), with: .color(Color(dinoHex: 0xDEC18A)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        for (x, y): (CGFloat, CGFloat) in [(-16, -11), (3, -15), (17, 5)] {
            line([CGPoint(x: x - 3, y: -3), CGPoint(x: x, y: y), CGPoint(x: x + 4, y: y - 3)], 0xA38051, 2.2)
        }
        oval(CGRect(x: 24, y: -6, width: 5, height: 4), [0xE9CE99, 0xA58050])
    }

    /// A quieter composition leaves the middle open for the result's Dino and trophy.
    func rewardLandscape(in size: CGSize) {
        let w = size.width, h = size.height, s = min(1.8, max(0.7, w / 390))
        material(Path(CGRect(origin: .zero, size: size)), [0x9ACDE5, 0xF5E2B9, 0xF5D397, 0xE8B977])
        for i in 0..<6 {
            let x = CGFloat(i) * w / 4 - w / 7
            var c = context; c.opacity = 0.4
            DinoDesertPainter(context: c).at(CGPoint(x: x, y: h * 0.40 + CGFloat(i % 2) * 21), size: s * 0.85) { $0.mesa(variation: i, distant: true) }
        }
        for i in 0..<4 {
            let y = h * (0.47 + CGFloat(i) * 0.16)
            var dune = Path(); dune.move(to: CGPoint(x: -30, y: y))
            dune.addCurve(to: CGPoint(x: w + 30, y: y + 30), control1: CGPoint(x: w * 0.30, y: y - 50), control2: CGPoint(x: w * 0.70, y: y + 80))
            let crest = dune
            for point in [CGPoint(x: w + 30, y: h + 20), CGPoint(x: -30, y: h + 20)] { dune.addLine(to: point) }; dune.closeSubpath()
            material(dune, [0xFFE4AC, 0xEFC78A, 0xE6B778])
            context.stroke(crest, with: .color(Color(dinoHex: 0xFFF1C6).opacity(0.7)), lineWidth: 1.5)
        }
        at(CGPoint(x: w * 0.06, y: h * 0.68), size: s * 0.9) { $0.cactus(variation: 1) }
        at(CGPoint(x: w * 0.94, y: h * 0.64), size: s * 0.62) { $0.ruin() }
        for side in [false, true] {
            at(CGPoint(x: side ? w + 5 : -5, y: h * 0.95), size: s * 1.2, mirror: side) { p in
                p.mesa(variation: 1)
                p.at(CGPoint(x: 30, y: -7), size: 0.9) { $0.dryShrub(variation: 2) }
            }
        }
    }

    func rewardGroundCover(in size: CGSize, foreground: Bool) {
        let s = min(1.8, max(0.7, size.width / 260))
        for side in [false, true] {
            at(CGPoint(x: size.width * (side ? 0.88 : 0.12), y: size.height * (foreground ? 0.88 : 0.71)), size: s * 0.54) { p in
                if !foreground { p.dryShrub(variation: side ? 1 : 3) }
                p.stones(variation: side ? 2 : 6)
            }
        }
    }

    private func sundial() {
        shadow(width: 120, height: 26)
        for i in 0..<3 { block(CGRect(x: -13 + CGFloat(i % 2) * 2, y: -17 - CGFloat(i) * 18, width: 26, height: 19), variation: i) }
        oval(CGRect(x: -47, y: -64, width: 94, height: 35), [0xFFE5AF, 0xD4AA73, 0xAF7F50])
        oval(CGRect(x: -43, y: -65, width: 86, height: 28), [0xFFF1C6, 0xE8CD96])
        grain(in: Path(ellipseIn: CGRect(x: -43, y: -65, width: 86, height: 28)), seed: 71, count: 54)
        for i in 0..<12 {
            let a = Double(i) * .pi / 6
            let x = CGFloat(sin(a)) * 34, y = -51 - CGFloat(cos(a)) * 10
            line([CGPoint(x: x * 0.85, y: -51 + (y + 51) * 0.83), CGPoint(x: x, y: y)], 0x9F794C, i.isMultiple(of: 3) ? 1.7 : 0.8)
        }
        polygon([CGPoint(x: 0, y: -51), CGPoint(x: 23, y: -44), CGPoint(x: 35, y: -47)], [0xA77B4D, 0xAE8354], opacity: 0.55)
        polygon([CGPoint(x: -3, y: -52), CGPoint(x: 1, y: -82), CGPoint(x: 17, y: -47)], [0xD7B37A, 0x987047])
        line([CGPoint(x: -3, y: -52), CGPoint(x: 1, y: -82)], 0xFFE7B2, 1.2)
        block(CGRect(x: -27, y: -8, width: 54, height: 13), variation: 2)
        line([CGPoint(x: -10, y: -44), CGPoint(x: -6, y: -35), CGPoint(x: -8, y: -28), CGPoint(x: -4, y: -22)], 0xB58C5A, 0.8, opacity: 0.75)
        sandApron(width: 67, y: 5)
        at(CGPoint(x: 38, y: 16), size: 0.47) { $0.mesa(variation: 1) }
    }
}

/// Warm stone surrounds a cool mineral centre, like the reference's buried
/// waymarkers. Button size, label and Dino's foot position remain shared.
struct DinoDesertLevelStone: View {
    let unlocked: Bool
    let occupied: Bool
    let boss: Bool
    let highContrast: Bool

    var body: some View {
        ZStack {
            Circle().fill(Color(dinoHex: 0x986B3E)).offset(y: 6)
            Circle().fill(LinearGradient(colors: [Color(dinoHex: 0xFFF0C4), Color(dinoHex: 0xE7B96F), Color(dinoHex: 0xAB7744)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().fill(LinearGradient(colors: [Color(dinoHex: boss ? 0xBCB98C : unlocked ? 0xE4EACD : 0xC9D6D1),
                                                  Color(dinoHex: boss ? 0x8E8653 : unlocked ? 0xA5BEA3 : 0x8AA7A8)], startPoint: .topLeading, endPoint: .bottomTrailing)).padding(8)
            Circle().strokeBorder(Color(dinoHex: highContrast ? 0x78502E : 0xFFF5D8), lineWidth: highContrast ? 3 : 2).padding(3)
            Circle().strokeBorder(Color(dinoHex: 0xD49952), lineWidth: 1.3).padding(7)
            Circle().strokeBorder(Color(dinoHex: 0x557C7C).opacity(0.45), lineWidth: 1).padding(10)
            Canvas { c, size in
                for i in 0..<8 {
                    let angle = Double(i) * .pi / 4 + 0.14
                    let point = CGPoint(x: size.width * (0.5 + CGFloat(cos(angle)) * 0.445), y: size.height * (0.5 + CGFloat(sin(angle)) * 0.445))
                    var crack = Path(); crack.move(to: point)
                    crack.addLine(to: CGPoint(x: point.x - CGFloat(cos(angle)) * 3.5, y: point.y - CGFloat(sin(angle)) * 3.5))
                    c.stroke(crack, with: .color(Color(dinoHex: 0xA87946).opacity(0.65)), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
                }
            }
            if occupied {
                Circle().fill(Color(dinoHex: 0xFFF7DA).opacity(highContrast ? 0.18 : 0.46)).padding(10)
                Circle().stroke(Color(dinoHex: 0xFFF1BF).opacity(0.94), lineWidth: 2).padding(-5)
                Circle().stroke(Color(dinoHex: 0xF4C67D).opacity(0.25), lineWidth: 5).padding(-10)
            }
        }.shadow(color: Color(dinoHex: 0x946236).opacity(0.26), radius: 5, y: 9)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Short independent surfaces keep moving sand out of the full-height map texture.
struct DinoDesertLife: View {
    let routeOffset: CGFloat
    let viewportHeight: CGFloat
    var fixedTime: TimeInterval? = nil
    var frozen = false

    var body: some View {
        GeometryReader { geometry in
            let layout = WorldSceneryLayout(width: geometry.size.width, height: geometry.size.height, routeOffset: routeOffset)
            ZStack(alignment: .topLeading) {
                ForEach(0..<max(1, Int(ceil(geometry.size.height / 280))), id: \.self) { index in
                    let frame = CGRect(x: 0, y: CGFloat(index) * 280, width: geometry.size.width,
                                       height: min(280, geometry.size.height - CGFloat(index) * 280))
                    DinoDesertLifeSurface(layout: layout, frame: frame, viewportHeight: viewportHeight,
                                          fixedTime: fixedTime, frozen: frozen)
                        .mask(DinoDesertWindMask(layout: layout, frame: frame))
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                }
            }
        }.clipped().allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct DinoDesertWindMask: View {
    let layout: WorldSceneryLayout
    let frame: CGRect

    var body: some View {
        Canvas { context, _ in
            let opening = CGRect(x: 0, y: layout.routeOffset + 8 - frame.minY, width: frame.width,
                                 height: max(0, layout.height - layout.routeOffset - 205))
            context.fill(Path(opening), with: .color(.white))
            var c = context
            c.translateBy(x: -frame.minX, y: layout.routeOffset - frame.minY)
            c.blendMode = .destinationOut
            let depth = WorldSceneryDepth(visibleBounds: frame)
            DinoDesertPainter(context: c).appendScenery(layout: layout, depth: depth)
            depth.draw()
            let boss = CGPoint(x: layout.width - 79 * layout.scale, y: 1675)
            DinoDesertPainter(context: c).clearing(at: boss, size: layout.scale)
            WorldBossPainter(context: c).draw(worldID: 7, at: boss, size: layout.scale * 0.88)
            var road = Path()
            let start = frame.minY - layout.routeOffset - 12
            for i in 0...Int(ceil((frame.height + 24) / 6)) {
                let y = start + CGFloat(i) * 6
                let point = CGPoint(x: layout.centerX(at: y), y: y)
                if i == 0 { road.move(to: point) } else { road.addLine(to: point) }
            }
            c.stroke(road, with: .color(.white), style: StrokeStyle(lineWidth: 116, lineCap: .round, lineJoin: .round))
        }
    }
}

private struct DinoDesertLifeSurface: View {
    let layout: WorldSceneryLayout
    let frame: CGRect
    let viewportHeight: CGFloat
    var fixedTime: TimeInterval? = nil
    var frozen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dinoMapAnimationEpoch) private var animationEpoch
    @State private var visible = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 16,
                                paused: fixedTime != nil || frozen || reduceMotion || !visible || scenePhase != .active)) { timeline in
            Canvas { context, _ in
                let time = frozen || reduceMotion ? 0 : (fixedTime ?? timeline.date.timeIntervalSince(animationEpoch ?? Date(timeIntervalSinceReferenceDate: 0)))
                DinoDesertWindPainter(context: context, time: time).draw(frame: frame, scale: layout.scale)
            }
        }
        .readGeometry(for: Bool.self) { geometry in
            let rect = geometry.frame(in: .named("adventure.map.viewport"))
            return rect.maxY > -256 && rect.minY < viewportHeight + 256
        } action: { visible = $0 }
    }
}

private struct DinoDesertWindPainter {
    let context: GraphicsContext
    let time: TimeInterval

    func draw(frame: CGRect, scale: CGFloat) {
        let tile = Int(frame.minY / 280)
        for i in 0..<34 {
            let seed = tile * 53 + i
            let duration = 11.0 + Double(seed % 9)
            let phase = (time / duration + Double((seed * 31) % 101) / 101).truncatingRemainder(dividingBy: 1)
            let envelope = pow(sin(phase * .pi), 2)
            let x = -25 + CGFloat(phase) * (frame.width + 50)
            let y = CGFloat((seed * 73 + 19) % max(1, Int(frame.height))) + CGFloat(sin(time * 0.35 + Double(seed))) * 2.5
            let width = (i.isMultiple(of: 5) ? 4.6 : 1.9) * scale
            var grain = Path(); grain.move(to: CGPoint(x: x, y: y))
            grain.addLine(to: CGPoint(x: x + width, y: y - width * 0.16))
            context.stroke(grain, with: .color(Color(dinoHex: i.isMultiple(of: 3) ? 0xFFF1C8 : 0xB8925D).opacity(envelope * 0.27)),
                           style: StrokeStyle(lineWidth: 0.65 * scale, lineCap: .round))
        }
        for i in 0..<3 {
            let seed = tile * 7 + i
            let phase = (time / (19 + Double(i) * 3) + Double((seed * 23) % 37) / 37).truncatingRemainder(dividingBy: 1)
            let strength = pow(sin(phase * .pi), 3) * 0.22
            let x = CGFloat(phase) * (frame.width + 150) - 75
            let y = CGFloat((seed * 89 + 27) % max(1, Int(frame.height)))
            for ribbon in 0..<3 {
                let dy = CGFloat(ribbon) * 2.4 * scale
                var gust = Path(); gust.move(to: CGPoint(x: x - 37 * scale, y: y + dy))
                gust.addCurve(to: CGPoint(x: x + 39 * scale, y: y - 9 * scale + dy),
                              control1: CGPoint(x: x - 8 * scale, y: y - 7 * scale + dy),
                              control2: CGPoint(x: x + 8 * scale, y: y + 4 * scale + dy))
                context.stroke(gust, with: .linearGradient(Gradient(colors: [.clear, Color(dinoHex: 0xFFF1CB).opacity(strength), .clear]),
                    startPoint: CGPoint(x: x - 37 * scale, y: y), endPoint: CGPoint(x: x + 39 * scale, y: y)),
                    style: StrokeStyle(lineWidth: ribbon == 1 ? 1.3 : 0.65, lineCap: .round))
            }
        }
    }
}

extension DinoDesertPainter {
    /// Broad reptile jaws, a swept-back crest and leathery wings in desert browns.
    func flyingDino(at point: CGPoint, size: CGFloat, facingRight: Bool, variation: Int, time: TimeInterval) {
        at(point, size: size, mirror: !facingRight) { p in
            let body: [UInt32] = [0xC99563, 0x9E6843, 0x65412D]
            let membrane: [UInt32] = [0xD8AD7A, 0xB47A4C, 0x7E4E31]
            let flap = CGFloat(sin(time * 5.6 + Double(variation) * 1.37))
            var shade = p.context; shade.opacity = 0.34; shade.translateBy(x: 3, y: 31)
            DinoDesertPainter(context: shade).shadow(width: 52, height: 8, x: 0, y: 0)
            p.flightWing(lift: flap * 0.72 + 0.22, far: true, colors: membrane)
            var tail = Path(); tail.move(to: CGPoint(x: -9, y: -3))
            tail.addQuadCurve(to: CGPoint(x: -38, y: -7), control: CGPoint(x: -24, y: -1))
            tail.addQuadCurve(to: CGPoint(x: -14, y: 7), control: CGPoint(x: -28, y: 8)); tail.closeSubpath()
            p.material(tail, body)
            for x: CGFloat in [-2, 8] {
                p.line([CGPoint(x: x, y: 5), CGPoint(x: x - 7, y: 12), CGPoint(x: x - 11, y: 10)], body[1], 3.2)
                p.line([CGPoint(x: x - 10, y: 10), CGPoint(x: x - 13, y: 11)], 0xE8D8AF, 1.2)
            }
            p.oval(CGRect(x: -15, y: -9, width: 33, height: 20), body)
            p.oval(CGRect(x: -6, y: -2, width: 22, height: 10), [0xE2C190, body[0]])
            p.flightWing(lift: flap, far: false, colors: membrane)
            p.oval(CGRect(x: 6, y: -18, width: 20, height: 25), body)
            var crest = Path(); crest.move(to: CGPoint(x: 12, y: -16))
            crest.addQuadCurve(to: CGPoint(x: -5, y: -33), control: CGPoint(x: 1, y: -22))
            crest.addQuadCurve(to: CGPoint(x: 23, y: -26), control: CGPoint(x: 13, y: -33))
            crest.addQuadCurve(to: CGPoint(x: 27, y: -17), control: CGPoint(x: 28, y: -22)); crest.closeSubpath()
            p.material(crest, [0xD2A16E, 0xA16D45, 0x71482F])
            p.oval(CGRect(x: 8, y: -25, width: 28, height: 27), body)
            // One rounded upper jaw and a separate lower jaw replace the pointed bill.
            var muzzle = Path(); muzzle.move(to: CGPoint(x: 23, y: -14))
            muzzle.addQuadCurve(to: CGPoint(x: 39, y: -16), control: CGPoint(x: 32, y: -19))
            muzzle.addQuadCurve(to: CGPoint(x: 48, y: -9), control: CGPoint(x: 48, y: -16))
            muzzle.addQuadCurve(to: CGPoint(x: 46, y: 0), control: CGPoint(x: 50, y: -1))
            muzzle.addQuadCurve(to: CGPoint(x: 27, y: 1), control: CGPoint(x: 35, y: 4))
            muzzle.addQuadCurve(to: CGPoint(x: 23, y: -14), control: CGPoint(x: 20, y: -1)); muzzle.closeSubpath()
            p.material(muzzle, [0xDBB581, 0xBD8958, 0x956037])
            p.oval(CGRect(x: 26, y: -3, width: 19, height: 7), [0xC99B68, 0xA37048])
            var mouth = Path(); mouth.move(to: CGPoint(x: 29, y: -2))
            mouth.addQuadCurve(to: CGPoint(x: 45, y: -3), control: CGPoint(x: 37, y: 1))
            p.context.stroke(mouth, with: .color(Color(dinoHex: 0x65412D)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
            for x: CGFloat in [33, 39] {
                p.polygon([CGPoint(x: x, y: -1.7), CGPoint(x: x + 2.5, y: -1.7), CGPoint(x: x + 1.2, y: 1.4)], [0xFFF0C9, 0xE1C395])
            }
            p.oval(CGRect(x: 40, y: -10, width: 3.2, height: 2.1), [0x805235, 0x65412D])
            p.oval(CGRect(x: 23, y: -22, width: 6.5, height: 8.5), [0xFFF5D8, 0xF1DDB9])
            p.oval(CGRect(x: 26, y: -20.3, width: 2.9, height: 4.8), [0x493222, 0x241C16])
            p.oval(CGRect(x: 26.3, y: -20.2, width: 1.1, height: 1.4), [0xFFFFFF, 0xFFFFF1])
            p.line([CGPoint(x: 22, y: -24), CGPoint(x: 28.5, y: -24.8)], body[2], 1.1, opacity: 0.8)
            for spot in [CGPoint(x: 15, y: -8), CGPoint(x: 18, y: -5), CGPoint(x: 12, y: -5)] {
                p.oval(CGRect(x: spot.x, y: spot.y, width: 1.6, height: 1.2), [body[1], body[2]], opacity: 0.65)
            }
        }
    }

    private func flightWing(lift: CGFloat, far: Bool, colors: [UInt32]) {
        let root = CGPoint(x: far ? 4 : -3, y: far ? -4 : 1)
        let tip = CGPoint(x: far ? -22 : -42, y: -8 - lift * (far ? 20 : 27))
        let elbow = CGPoint(x: far ? -11 : -20, y: -9 - lift * 11)
        var wing = Path(); wing.move(to: root)
        wing.addQuadCurve(to: tip, control: elbow)
        wing.addQuadCurve(to: CGPoint(x: far ? -12 : -24, y: 9 - lift * 11),
                          control: CGPoint(x: tip.x + 3, y: tip.y + 11))
        wing.addQuadCurve(to: CGPoint(x: root.x + 3, y: root.y + 6), control: CGPoint(x: -8, y: 5 - lift * 3))
        wing.closeSubpath()
        material(wing, colors, opacity: far ? 0.82 : 1)
        var leadingEdge = Path(); leadingEdge.move(to: root)
        leadingEdge.addQuadCurve(to: tip, control: elbow)
        context.stroke(leadingEdge, with: .color(Color(dinoHex: colors[2]).opacity(0.8)),
                       style: StrokeStyle(lineWidth: far ? 1 : 1.4, lineCap: .round))
        var membrane = context; membrane.clip(to: wing)
        let ribs = DinoDesertPainter(context: membrane)
        for i in 0..<2 {
            let end = CGPoint(x: tip.x + CGFloat(9 + i * 8), y: 8 - lift * CGFloat(14 + i * 4))
            ribs.line([root, end], colors[0], 0.7, opacity: 0.62)
        }
    }
}

/// Like the crystal miners, routes are deterministic and keep moving between
/// visits. Both direction changes happen beyond the canvas, never on the map.
struct DinoDesertFlightRoute: Identifiable {
    let id: Int
    let y: CGFloat
    let speed: CGFloat
    let size: CGFloat
    var startsRight: Bool { id.isMultiple(of: 2) }

    struct Pose {
        let point: CGPoint
        let facingRight: Bool
    }

    static let routes = [
        DinoDesertFlightRoute(id: 0, y: 167, speed: 39, size: 0.77),
        DinoDesertFlightRoute(id: 1, y: 517, speed: 43, size: 0.68),
        DinoDesertFlightRoute(id: 2, y: 867, speed: 37, size: 0.82),
        DinoDesertFlightRoute(id: 3, y: 1217, speed: 42, size: 0.71),
        DinoDesertFlightRoute(id: 4, y: 1567, speed: 40, size: 0.76)
    ]

    func pose(at time: TimeInterval, width: CGFloat, scale: CGFloat) -> Pose {
        let margin = 72 * scale, distance = width + 2 * margin
        let travel = Double(distance / (speed * scale)), leg = travel + 1.2
        let raw = (time + travel * (0.22 + Double(id % 4) * 0.17)).truncatingRemainder(dividingBy: leg * 2)
        let t = raw < 0 ? raw + leg * 2 : raw
        let outbound = t < leg
        let fraction = CGFloat(min(1, max(0, (outbound ? t : t - leg) / travel)))
        let right = outbound == startsRight
        let x = right ? -margin + fraction * distance : width + margin - fraction * distance
        let bob = CGFloat(sin(time * 1.45 + Double(id) * 1.7)) * 4.5 * scale
        let arc = sin(fraction * .pi) * (startsRight ? 7 : -7) * scale
        return Pose(point: CGPoint(x: x, y: y + bob + arc), facingRight: right)
    }
}

/// A separate foreground layer sits above the trail and below the level UI.
/// Only small visible creature canvases update, following the world-5 approach.
struct DinoDesertFlights: View {
    let routeOffset: CGFloat
    let viewportHeight: CGFloat
    var fixedTime: TimeInterval? = nil
    var frozen = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dinoMapAnimationEpoch) private var animationEpoch
    @State private var viewport = CGRect.zero

    var body: some View {
        GeometryReader { geometry in
            let scale = min(1.30, max(0.82, geometry.size.width / 390))
            let reduced = frozen || systemReduceMotion
            TimelineView(.animation(minimumInterval: 1.0 / 20,
                                    paused: fixedTime != nil || reduced || viewport.isEmpty || scenePhase != .active)) { timeline in
                let time = reduced ? 0 : (fixedTime ?? timeline.date.timeIntervalSince(animationEpoch ?? Date(timeIntervalSinceReferenceDate: 0)))
                ZStack(alignment: .topLeading) {
                    ForEach(DinoDesertFlightRoute.routes) { route in
                        let pose = route.pose(at: time, width: geometry.size.width, scale: scale)
                        let point = CGPoint(x: pose.point.x, y: pose.point.y + routeOffset)
                        let creatureSize = route.size * scale
                        let frame = CGRect(x: point.x - 60 * creatureSize, y: point.y - 58 * creatureSize,
                                           width: 120 * creatureSize, height: 108 * creatureSize)
                        if fixedTime != nil || frame.intersects(viewport) {
                            Canvas { context, _ in
                                var c = context; c.translateBy(x: -frame.minX, y: -frame.minY)
                                DinoDesertPainter(context: c).flyingDino(at: point, size: creatureSize,
                                    facingRight: pose.facingRight, variation: route.id, time: time)
                            }
                            .frame(width: frame.width, height: frame.height)
                            .position(x: frame.midX, y: frame.midY)
                        }
                    }
                }
                // Keep viewport discovery full-sized before any creature is visible.
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            }
            .readGeometry(for: CGRect.self) { proxy in
                let frame = proxy.frame(in: .named("adventure.map.viewport"))
                return DinoMapViewport.preparedAnimationBounds(frame: frame, viewportHeight: viewportHeight)
            } action: { viewport = $0 }
        }.clipped().allowsHitTesting(false).accessibilityHidden(true)
    }
}
