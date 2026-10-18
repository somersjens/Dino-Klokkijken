import SwiftUI

/// Sort every destination together by its ground contact, never by its kind.
/// Equal baselines retain their composition order (e.g. a crystal on a ledge).
private final class WorldSceneryDepth {
    private var items: [(depth: CGFloat, draw: () -> Void)] = []
    var minimumDepth: CGFloat? = nil
    var visibleBounds: CGRect? = nil

    init(minimumDepth: CGFloat? = nil, visibleBounds: CGRect? = nil) {
        self.minimumDepth = minimumDepth
        self.visibleBounds = visibleBounds
    }

    func add(at depth: CGFloat, bounds: CGRect? = nil, _ draw: @escaping () -> Void) {
        if let minimumDepth, depth <= minimumDepth { return }
        if let visibleBounds, let bounds, !visibleBounds.intersects(bounds) { return }
        items.append((depth, draw))
    }

    func draw() {
        for item in items.enumerated().sorted(by: {
            $0.element.depth == $1.element.depth ? $0.offset < $1.offset : $0.element.depth < $1.element.depth
        }) { item.element.draw() }
    }
}

/// Every section meets its neighbour at the same centre line and vertical tangent.
/// The sign is drawn over the trail, rather than leaving a blank break in it.
struct WorldRouteTrail: View, Equatable {
    static let levelSpacing = JungleMapLayout.levelSpacing
    static let bannerTopPadding: CGFloat = 12
    static let bannerHeight: CGFloat = 212
    static let bannerFaceCenterY: CGFloat = 99.5
    static let bannerBottomPadding: CGFloat = 10
    static let chapterFirstNodeY: CGFloat = 80
    static func chapterTail(topClearance: CGFloat) -> CGFloat {
        let below = bannerHeight - bannerFaceCenterY + bannerBottomPadding + topClearance + chapterFirstNodeY
        // Boss stones are 90pt, ordinary stones 72pt. Match the clear space
        // between their rims and the banner, including room for Dino below it.
        let above = below + (90 - 72) / 2
        return above - bannerTopPadding - bannerFaceCenterY
    }
    static func chapterRouteHeight(topClearance: CGFloat, worldID: Int) -> CGFloat {
        let tail = worldID == 5 ? CrystalCaveThresholdLayout.exitChapterTail(topClearance: topClearance)
                               : chapterTail(topClearance: topClearance)
        return chapterFirstNodeY + 9 * levelSpacing + tail
    }
    static func jungleRouteHeight(topClearance: CGFloat) -> CGFloat {
        topClearance + 70 + 10 * levelSpacing + chapterTail(topClearance: topClearance)
    }
    static let chapterPositions = JungleMapLayout.chapterPositions
    let points: [CGPoint]
    var entryY: CGFloat? = nil
    let exitY: CGFloat

    private var path: Path {
        guard let first = points.first, let last = points.last else { return Path() }
        return Path { path in
            if let entryY {
                // Extend the strokes beyond the section, including the offset shadow.
                path.move(to: CGPoint(x: last.x, y: entryY - 12))
                path.addCurve(to: first,
                              control1: CGPoint(x: last.x, y: entryY + (first.y - entryY) * 0.50),
                              control2: CGPoint(x: first.x, y: first.y - 88))
            } else { path.move(to: first) }
            for pair in zip(points, points.dropFirst()) {
                path.addCurve(to: pair.1, control1: CGPoint(x: pair.0.x, y: pair.0.y + 88),
                              control2: CGPoint(x: pair.1.x, y: pair.1.y - 88))
            }
            path.addLine(to: CGPoint(x: last.x, y: exitY + 12))
        }
    }

    /// The cave paints its trail in the terrain Canvas so all scenery can share
    /// one depth order above it, including the stone lip across the road.
    func draw(in context: GraphicsContext) {
        let trail = path
        context.stroke(trail.offsetBy(dx: 0, dy: 5), with: .color(Color(dinoHex: 0x78995D).opacity(0.21)),
                       style: StrokeStyle(lineWidth: 46, lineCap: .butt))
        context.stroke(trail, with: .color(Color(dinoHex: 0xC9BB83)), style: StrokeStyle(lineWidth: 40, lineCap: .butt))
        context.stroke(trail, with: .color(Color(dinoHex: 0xF4E6B6)), style: StrokeStyle(lineWidth: 34, lineCap: .butt))
        context.stroke(trail, with: .color(Color(dinoHex: 0xFFF9D8).opacity(0.95)),
                       style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 12]))
    }

    var body: some View {
        // Paths avoid allocating a second full-height Canvas texture per world.
        let trail = path
        ZStack(alignment: .topLeading) {
            trail.stroke(Color(dinoHex: 0x78995D).opacity(0.21), style: StrokeStyle(lineWidth: 46, lineCap: .butt)).offset(y: 5)
            trail.stroke(Color(dinoHex: 0xC9BB83), style: StrokeStyle(lineWidth: 40, lineCap: .butt))
            trail.stroke(Color(dinoHex: 0xF4E6B6), style: StrokeStyle(lineWidth: 34, lineCap: .butt))
            trail.stroke(Color(dinoHex: 0xFFF9D8).opacity(0.95), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 12]))
        }
        // Each section owns exactly its own strip. Allowing the offset shadow
        // above/below it darkens the neighbouring road and exposes a flat cap.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipped()
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Map art uses the same cubic bends as the playable trail. Coordinates here
/// are relative to the first row's section, including the entrance above it.
private struct WorldSceneryLayout {
    let width: CGFloat
    let height: CGFloat
    let routeOffset: CGFloat
    var jungle = false
    var scale: CGFloat { min(1.30, max(0.82, width / 390)) }
    private var routeWidth: CGFloat { min(width, 600) - 36 }
    private var positions: [CGFloat] { jungle ? [0.5] + WorldRouteTrail.chapterPositions : WorldRouteTrail.chapterPositions }
    private var firstY: CGFloat { jungle ? 70 : 80 }

    private func cubic(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat, _ t: CGFloat) -> CGFloat {
        let u = 1 - t
        return u * u * u * a + 3 * u * u * t * b + 3 * u * t * t * c + t * t * t * d
    }

    func centerX(at y: CGFloat) -> CGFloat {
        if jungle { return JungleMapLayout(width: width).centerX(at: y) }
        let lastY = firstY + CGFloat(positions.count - 1) * 175
        if y >= lastY { return width / 2 }
        let startX: CGFloat, endX: CGFloat, startY: CGFloat, endY: CGFloat, c1Y: CGFloat, c2Y: CGFloat
        if y < firstY {
            if jungle { return width / 2 }
            startX = width / 2
            endX = (width - routeWidth) / 2 + routeWidth * positions[0]
            startY = -routeOffset - 12; endY = firstY
            c1Y = -routeOffset + (firstY + routeOffset) * 0.5; c2Y = firstY - 88
        } else {
            let index = min(positions.count - 2, Int((y - firstY) / 175))
            startX = (width - routeWidth) / 2 + routeWidth * positions[index]
            endX = (width - routeWidth) / 2 + routeWidth * positions[index + 1]
            startY = firstY + CGFloat(index) * 175; endY = startY + 175
            c1Y = startY + 88; c2Y = endY - 88
        }
        // The trail's y handles are not evenly spaced, so invert its cubic
        // rather than using a sine or linear estimate of the level positions.
        var low: CGFloat = 0, high: CGFloat = 1
        for _ in 0..<14 {
            let t = (low + high) / 2
            if cubic(startY, c1Y, c2Y, endY, t) < y { low = t } else { high = t }
        }
        let t = (low + high) / 2
        return cubic(startX, startX, endX, endX, t)
    }

    func position(_ point: CGPoint, radius: CGFloat = 0, rise: CGFloat = 0) -> CGPoint {
        let right = point.x > width / 2
        let inset = right ? width - point.x : point.x
        // Special clearings beside the boss already have their own composition.
        if inset > 110 * scale { return point }
        let inward = min(44 * scale, inset * 0.6)
        let distance = 165 * scale - inward
        var x = centerX(at: point.y) + (right ? distance : -distance)
        if radius > 0 {
            // Tall destinations must clear the bend behind their crowns and
            // rooftops as well as the road beside their feet.
            for i in 0...8 {
                let y = point.y - rise + (rise + 30 * scale) * CGFloat(i) / 8
                let boundary = centerX(at: y) + (right ? 1 : -1) * (radius + 48 * scale)
                x = right ? max(x, boundary) : min(x, boundary)
            }
        }
        return CGPoint(x: x, y: point.y)
    }

    private func bankPath(right: Bool, inset: CGFloat, exitsAtSides: Bool = false) -> Path {
        let startY = -routeOffset - 80, endY = height - routeOffset + 80
        let count = Int(ceil((endY - startY) / 8))
        return Path { path in
            for i in 0...count {
                let y = startY + (endY - startY) * CGFloat(i) / CGFloat(count)
                var x = centerX(at: y) + (right ? 1 : -1) * (165 - inset) * scale
                if exitsAtSides {
                    let sectionY = y + routeOffset
                    let entry = min(1, max(0, (sectionY - 16) / 224))
                    let exit = min(1, max(0, (height - 12 - sectionY) / 238))
                    let progress = min(entry, exit)
                    let blend = progress * progress * (3 - 2 * progress)
                    let outside = right ? width + 100 * scale : -100 * scale
                    x = outside + (x - outside) * blend
                }
                let point = CGPoint(x: x, y: y)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
        }
    }

    private func passageEntry(right: Bool, inset: CGFloat, city: Bool) -> (start: CGPoint, c1: CGPoint, c2: CGPoint, end: CGPoint) {
        let outside = right ? width + 110 * scale : -110 * scale
        // The complete bank and quay stay outside until beyond the cave wall.
        let mouthY = -routeOffset + (city ? 72 * scale : 8)
        let end = CGPoint(x: centerX(at: firstY) + (right ? 1 : -1) * (165 - inset) * scale, y: firstY)
        return (CGPoint(x: outside, y: mouthY),
                CGPoint(x: outside + (end.x - outside) * (city ? 0.38 : 0.68),
                        y: mouthY + (city ? (firstY - mouthY) * 0.10 : 0)),
                CGPoint(x: end.x, y: firstY - (firstY - mouthY) * (city ? 0.34 : 0.46)), end)
    }

    /// Join the river at vertical trail tangents, so a broad side entrance
    /// cannot overshoot the first bend and double back into a sharp elbow.
    private func passageBankPath(right: Bool, inset: CGFloat, opensAtStart: Bool, opensAtEnd: Bool, endMouthY: CGFloat? = nil, cityEntrance: Bool = false) -> Path {
        let startY = -routeOffset - 80, endY = height - routeOffset + 80
        let outside = right ? width + 110 * scale : -110 * scale
        let lastY = firstY + CGFloat(positions.count - 1) * 175
        let entryY = opensAtStart ? firstY : startY
        let exitY = opensAtEnd ? lastY - 175 : endY
        func point(_ y: CGFloat) -> CGPoint {
            CGPoint(x: centerX(at: y) + (right ? 1 : -1) * (165 - inset) * scale, y: y)
        }
        return Path { p in
            if opensAtStart {
                let entry = passageEntry(right: right, inset: inset, city: cityEntrance)
                p.move(to: CGPoint(x: outside, y: startY))
                p.addLine(to: entry.start)
                p.addCurve(to: entry.end, control1: entry.c1, control2: entry.c2)
            } else { p.move(to: point(entryY)) }
            let count = Int(ceil((exitY - entryY) / 8))
            for i in 0..<count {
                let aY = entryY + (exitY - entryY) * CGFloat(i) / CGFloat(count)
                let bY = entryY + (exitY - entryY) * CGFloat(i + 1) / CGFloat(count)
                let a = point(aY), b = point(bY), dy = (bY - aY) / 3
                let aSlope = (centerX(at: aY + 0.5) - centerX(at: aY - 0.5))
                let bSlope = (centerX(at: bY + 0.5) - centerX(at: bY - 0.5))
                p.addCurve(to: b, control1: CGPoint(x: a.x + aSlope * dy, y: aY + dy),
                           control2: CGPoint(x: b.x - bSlope * dy, y: bY - dy))
            }
            if opensAtEnd {
                let exit = point(exitY), mouthY = endMouthY ?? height - routeOffset - 8
                p.addCurve(to: CGPoint(x: outside, y: mouthY),
                           control1: CGPoint(x: exit.x, y: exitY + (mouthY - exitY) * 0.48),
                           control2: CGPoint(x: outside + (exit.x - outside) * 0.28, y: mouthY))
                p.addLine(to: CGPoint(x: outside, y: endY))
            }
        }
    }

    private var cityCanalMouthY: CGFloat { firstY + CGFloat(positions.count - 1) * 175 + 12 }

    /// City paving and props follow the actual canal, including its side mouths.
    /// Positive offsets are on the outer bank; negative offsets face the trail.
    func cityCanalPoint(at y: CGFloat, right: Bool, offset: CGFloat = 0) -> CGPoint {
        let sign: CGFloat = right ? 1 : -1
        let outside = right ? width + 110 * scale : -110 * scale
        let exitY = firstY + CGFloat(positions.count - 2) * 175
        func riverX(_ sampleY: CGFloat) -> CGFloat {
            let a: CGPoint, b: CGPoint, c: CGPoint, d: CGPoint
            if sampleY < firstY {
                let entry = passageEntry(right: right, inset: 34, city: true)
                a = entry.start; b = entry.c1; c = entry.c2; d = entry.end
            } else if sampleY > exitY {
                let mouthY = cityCanalMouthY
                let x = centerX(at: exitY) + sign * 131 * scale
                a = CGPoint(x: x, y: exitY)
                b = CGPoint(x: x, y: exitY + (mouthY - exitY) * 0.48)
                c = CGPoint(x: outside + (x - outside) * 0.28, y: mouthY)
                d = CGPoint(x: outside, y: mouthY)
            } else { return centerX(at: sampleY) + sign * 131 * scale }
            if sampleY <= a.y { return a.x }
            if sampleY >= d.y { return d.x }
            var low: CGFloat = 0, high: CGFloat = 1
            for _ in 0..<18 {
                let t = (low + high) / 2
                if cubic(a.y, b.y, c.y, d.y, t) < sampleY { low = t } else { high = t }
            }
            return cubic(a.x, b.x, c.x, d.x, (low + high) / 2)
        }
        let slope = (riverX(y + 1) - riverX(y - 1)) / 2
        let normal = sign * offset / sqrt(1 + slope * slope)
        return CGPoint(x: riverX(y) + normal, y: y - normal * slope)
    }

    private func palette(for worldID: Int) -> (ground: UInt32, rim: UInt32, water: UInt32, light: UInt32) {
        let palette: (ground: UInt32, rim: UInt32, water: UInt32, light: UInt32)
        switch worldID {
        case 1: palette = (0x8FB86C, 0x7FA360, 0x8FB86C, 0xC2D99A)
        case 2: palette = (0x90AAA3, 0x7C9C98, 0x669DAA, 0xDAECE0)
        case 3: palette = (0x928D87, 0x746F7B, 0x928D87, 0xC6BAA2)
        case 4: palette = (0xAAC28D, 0xE1D9B6, 0x6CBCC2, 0xDDF5E4)
        case 5: palette = (0x647C98, 0x8FA7AF, 0x66BDC8, 0xE4FFF0)
        case 6: palette = (0xADC5AA, 0xF0E3BE, 0x7CC8CB, 0xE4F8E5)
        case 7: palette = (0x839B95, 0x8FA9A8, 0x649FB8, 0xC9EEE0)
        case 8: palette = (0x98ABA6, 0x7E9299, 0x8CD1D4, 0xD9FBEE)
        case 9: palette = (0xE8C58B, 0xD6F2DE, 0x39B3CA, 0xF4FFF0)
        default: palette = (0xB5C5A0, 0xD5DFCA, 0x68BDCF, 0xE3FFF0)
        }
        return palette
    }

    func drawBoundaryGround(in context: GraphicsContext, worldID: Int, size: CGSize) {
        let world = DinoWorldCatalog.world(worldID)!
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(dinoHex: world.ground)))
        // The cave meets the village through open terrain; its walls arrive
        // later from the sides instead of exposing a dark horizontal bank cap.
        if worldID == 5 { return }
        let bank = palette(for: worldID)
        let inset = 122 * scale
        for right in [false, true] {
            let edge = width / 2 + (right ? inset : -inset)
            let rect = right ? CGRect(x: edge, y: 0, width: max(0, width - edge), height: size.height)
                             : CGRect(x: 0, y: 0, width: max(0, edge), height: size.height)
            context.fill(Path(rect), with: .color(Color(dinoHex: bank.ground).opacity(worldID == 5 ? 0.88 : 0.22)))
        }
    }

    func drawBanks(in context: GraphicsContext, worldID: Int) {
        let palette = palette(for: worldID)
        let nextID = min(10, worldID + 1)
        let next = self.palette(for: worldID == 4 ? 4 : nextID)
        var bankStops: [Gradient.Stop] = [
            .init(color: Color(dinoHex: palette.ground).opacity(worldID == 5 ? 0.88 : 0.22), location: 0),
            .init(color: Color(dinoHex: palette.ground).opacity(worldID == 5 ? 0.88 : 0.22), location: max(0, (height - 180) / height)),
            .init(color: Color(dinoHex: next.ground).opacity(nextID == 5 && worldID != 4 ? 0.88 : 0.22), location: 1)
        ]
        if worldID == 1 {
            // Jungle banks belong to the clearing, leaving uninterrupted sky above.
            bankStops[0].color = .clear
            bankStops.insert(.init(color: .clear, location: max(0, routeOffset / height)), at: 1)
            bankStops.insert(.init(color: Color(dinoHex: palette.ground).opacity(0.22),
                                   location: min(bankStops[2].location, (routeOffset + 220) / height)), at: 2)
        }
        let bankShading = GraphicsContext.Shading.linearGradient(Gradient(stops: bankStops),
            startPoint: CGPoint(x: 0, y: -routeOffset), endPoint: CGPoint(x: 0, y: height - routeOffset))
        for right in [false, true] {
            let bank = [4, 6].contains(worldID)
                ? passageBankPath(right: right, inset: 43, opensAtStart: worldID == 6, opensAtEnd: true,
                                  endMouthY: worldID == 6 ? cityCanalMouthY : nil, cityEntrance: worldID == 6)
                : bankPath(right: right, inset: 43)
            let outside: CGFloat = right ? width + 400 : -400
            func outerArea(_ boundary: Path) -> Path {
                var area = boundary
                area.addLine(to: CGPoint(x: outside, y: height - routeOffset + 80))
                area.addLine(to: CGPoint(x: outside, y: -routeOffset - 80))
                area.closeSubpath()
                return area
            }
            context.fill(outerArea(bank), with: bankShading)
            guard [4, 6, 9].contains(worldID) else { continue }
            let water = worldID == 9 ? bankPath(right: right, inset: 34, exitsAtSides: true)
                                    : passageBankPath(right: right, inset: 34, opensAtStart: true, opensAtEnd: true,
                                                      endMouthY: worldID == 6 ? cityCanalMouthY : nil, cityEntrance: worldID == 6)
            if worldID == 9 {
                // A solid coastal inlet, with both shoreline ends beyond the
                // sides of the viewport. The sea never fades into the ground.
                context.fill(outerArea(water), with: .linearGradient(
                    Gradient(colors: [Color(dinoHex: 0x63C4D4), Color(dinoHex: palette.water), Color(dinoHex: 0x66CCD1)]),
                    startPoint: CGPoint(x: 0, y: -routeOffset), endPoint: CGPoint(x: 0, y: height - routeOffset)))
                context.stroke(water, with: .color(Color(dinoHex: palette.ground)),
                               style: StrokeStyle(lineWidth: 14 * scale, lineCap: .butt, lineJoin: .round))
                context.stroke(water, with: .color(Color(dinoHex: palette.rim)),
                               style: StrokeStyle(lineWidth: 7 * scale, lineCap: .butt, lineJoin: .round))
                context.stroke(water, with: .color(Color(dinoHex: palette.light)),
                               style: StrokeStyle(lineWidth: 1.8 * scale, lineCap: .round, lineJoin: .round, dash: [17 * scale, 5 * scale, 3 * scale, 9 * scale]))
            } else {
                for (width, color): (CGFloat, UInt32) in [(54, palette.rim), (42, palette.light), (31, palette.water)] {
                    context.stroke(water, with: .color(Color(dinoHex: color)),
                                   style: StrokeStyle(lineWidth: width * scale, lineCap: .round, lineJoin: .round))
                }
                context.stroke(water, with: .color(Color(dinoHex: palette.light)),
                               style: StrokeStyle(lineWidth: 1.3 * scale, lineCap: .round, lineJoin: .round, dash: [11 * scale, 26 * scale, 3 * scale, 22 * scale]))
            }
        }
    }
}

/// A short terrain-only join removes sun/glow colour steps at chapter edges.
/// Water has already left through the sides before these 32pt strips begin.
private struct WorldTerrainTransition: View, Equatable {
    let worldID: Int
    var entering = false
    var body: some View {
        Canvas { context, size in
            WorldSceneryLayout(width: size.width, height: size.height, routeOffset: 0)
                .drawBoundaryGround(in: context, worldID: worldID, size: size)
        }.mask(LinearGradient(colors: entering ? [.white, .clear] : [.clear, .white], startPoint: .top, endPoint: .bottom))
            .frame(height: 32).allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// The final route disappears beneath a full sign instead of being cut by a
/// plain footer rectangle. Terrain continues through the safe-area padding.
struct WorldMapEndingLandscape: View, Equatable {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(dinoHex: 0xE8DFCC)))
            var continuation = context
            continuation.translateBy(x: 0, y: -2000)
            WorldSceneryLayout(width: size.width, height: size.height, routeOffset: -2000)
                .drawBanks(in: continuation, worldID: 10)
            let painter = JunglePainter(context: context)
            for right in [false, true] {
                let x = size.width / 2 + (right ? 1 : -1) * min(265, size.width * 0.42)
                painter.rocks(at: CGPoint(x: x, y: 190), size: 0.55)
                painter.flowers(at: CGPoint(x: x + (right ? -12 : 12), y: 198), size: 0.5)
            }
        }.overlay(alignment: .top) {
            GeometryReader { geometry in
                WorldRouteTrail(points: [CGPoint(x: geometry.size.width / 2, y: -12)], exitY: 108)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Chapter lettering and description share one sculpted, theme-specific sign.
struct WorldTitleBanner: View, Equatable {
    let world: DinoWorld
    var highContrast = false

    var body: some View {
        GeometryReader { geometry in
            let layout = WorldBannerLayout(width: geometry.size.width)
            let palette = WorldBannerPalette(worldID: world.id)
            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    WorldBannerPainter(context: context, world: world).draw(in: size)
                }.allowsHitTesting(false).accessibilityHidden(true)
                Text("dino.worldNumber \(world.id)")
                    .textCase(.uppercase)
                    .font(.system(size: 12, weight: .heavy, design: .rounded)).tracking(1.3)
                    .foregroundStyle(Color(dinoHex: palette.tabInk))
                    .frame(width: layout.tab.width - 20, height: layout.tab.height)
                    .position(x: layout.tab.midX, y: layout.tab.midY)
                Text(LocalizedStringKey(world.titleKey))
                    .font(.system(size: 33, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(dinoHex: highContrast ? (world.id == 3 ? 0xFFFFFF : 0x153C48) : palette.ink))
                    .shadow(color: Color(dinoHex: palette.titleShadow).opacity(0.55), radius: 0, y: 1.4)
                    .lineLimit(world.id == 7 ? 2 : 1).minimumScaleFactor(0.58)
                    .multilineTextAlignment(.center).lineSpacing(-1)
                    .frame(width: layout.titleWidth, height: 82)
                    .position(x: layout.titlePanel.midX, y: layout.titlePanel.midY)
                Text(LocalizedStringKey(world.skillKey))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(dinoHex: palette.subtitleInk))
                    .lineLimit(2).minimumScaleFactor(0.82)
                    .multilineTextAlignment(.center).lineSpacing(-1)
                    .frame(width: layout.subtitle.width - 36, height: 27)
                    .position(x: layout.subtitle.midX + 10, y: layout.subtitle.midY)
            }
        }.frame(height: 212)
    }
}

private struct WorldBannerLayout {
    let width: CGFloat
    let scale: CGFloat
    let plate: CGRect
    let titlePanel: CGRect
    let tab: CGRect
    let subtitle: CGRect
    let titleWidth: CGFloat
    init(width: CGFloat) {
        self.width = width
        scale = min(1.26, max(0.82, width / 354))
        plate = CGRect(x: 29 * scale, y: 42, width: width - 58 * scale, height: 142)
        titlePanel = CGRect(x: 62 * scale, y: WorldRouteTrail.bannerFaceCenterY - 83 / 2, width: width - 124 * scale, height: 83)
        tab = CGRect(x: width / 2 - 62, y: 20, width: 124, height: 32)
        subtitle = CGRect(x: 70 * scale, y: 146, width: width - 140 * scale, height: 29)
        titleWidth = width - 146 * scale
    }
}

private struct WorldBannerPalette {
    var ink: UInt32 = 0x294959
    var titleShadow: UInt32 = 0xDAB867
    var light: UInt32 = 0xFFF4D1
    var face: UInt32 = 0xF2E7BE
    var dark: UInt32 = 0xC9B17C
    var rim: UInt32 = 0xA78650
    var accent: UInt32 = 0x79A45E
    var shade: UInt32 = 0x38694B
    var tabInk: UInt32 = 0x573D29
    var tabLight: UInt32 = 0xFFE5AB
    var tabFace: UInt32 = 0xEABD7B
    var subtitleLight: UInt32 = 0xFFFADE
    var subtitleFace: UInt32 = 0xE9E8BB
    var subtitleDark: UInt32 = 0xB6C18A
    var subtitleInk: UInt32 = 0x345346
    init(worldID: Int) {
        switch worldID {
        case 1: ink = 0x235C34; accent = 0x7BB341; shade = 0x2C653A
        case 2:
            accent = 0x9FACC9; shade = 0x586F92; light = 0xF5F0FF; face = 0xE5DBF0; dark = 0xB4AACB; rim = 0x978EAA
            tabLight = 0xEFE8FF; tabFace = 0xCBBEE0; tabInk = 0x53617E
            subtitleLight = 0xF6F2FC; subtitleFace = 0xE6E0F2; subtitleDark = 0xB4AEC8; subtitleInk = 0x52627D
        case 3:
            ink = 0xFFF1CA; titleShadow = 0x40343F; light = 0x9B8791; face = 0x716371; dark = 0x494957; rim = 0xBE8351; accent = 0xF5A064; shade = 0x585363
            tabLight = 0xFFDEAC; tabFace = 0xD79B67
            subtitleLight = 0xFFEBCB; subtitleFace = 0xE8B98E; subtitleDark = 0xBD8667; subtitleInk = 0x6C443C
        case 4: accent = 0xC0835B; shade = 0x6B7852; subtitleFace = 0xF0DAB0; subtitleDark = 0xCDAE79; subtitleInk = 0x6C5542
        case 5:
            ink = 0x455984; accent = 0x83CFCB; shade = 0x527A9F; light = 0xEFFAFF; face = 0xCCE5F0; dark = 0x98B4CE; rim = 0x77A0B9
            tabLight = 0xE5F9F4; tabFace = 0xA9D8DE; tabInk = 0x41647A
            subtitleLight = 0xF0FCFB; subtitleFace = 0xD3EDF1; subtitleDark = 0xA1CADB; subtitleInk = 0x41617F
        case 6:
            ink = 0x256879; accent = 0x63C7CC; shade = 0x3A7185; light = 0xE4F9F6; face = 0xBBDCDD; dark = 0x81ADB8; rim = 0x6798A9
            tabLight = 0xD3EDF0; tabFace = 0x93C6CC; tabInk = 0x2A6679
            subtitleLight = 0xEBFBFA; subtitleFace = 0xC0E2E4; subtitleDark = 0x88B5C1; subtitleInk = 0x2E6278
        case 7:
            accent = 0x9CB68E; shade = 0x5D7790; subtitleLight = 0xF7E9BC; subtitleFace = 0xECE5D0; subtitleDark = 0xB9BBD5; subtitleInk = 0x4A6172
        case 8:
            accent = 0xD6B46A; shade = 0x747D86; rim = 0xA88B55; tabFace = 0xD4B579
            subtitleLight = 0xFCEDCA; subtitleFace = 0xE6D1A0; subtitleDark = 0xBBA36F; subtitleInk = 0x5B5D56
        case 9:
            ink = 0x674731; accent = 0x72BABC; shade = 0x667D75; face = 0xEFDEB3; dark = 0xC5A878; rim = 0x967147
            tabFace = 0xDBAF70; subtitleLight = 0xFFF1CF; subtitleFace = 0xEAD1A0; subtitleDark = 0xC4A575; subtitleInk = 0x705038
        default:
            ink = 0x36577A; accent = 0x8EADD0; shade = 0x536E99; face = 0xEEE6C7; rim = 0xB59455
            tabFace = 0xE2C482
            subtitleLight = 0x8EACD0; subtitleFace = 0x5D7CA9; subtitleDark = 0x3E577D; subtitleInk = 0xFFF4D7
        }
    }
}

private struct WorldBannerPainter {
    let context: GraphicsContext
    let world: DinoWorld
    private var palette: WorldBannerPalette { .init(worldID: world.id) }

    private func material(_ path: Path, light: UInt32, face: UInt32, dark: UInt32) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: light), location: 0),
            .init(color: Color(dinoHex: face), location: 0.46),
            .init(color: Color(dinoHex: dark), location: 1)
        ]), startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
    }
    private func line(_ points: [CGPoint], color: UInt32, width: CGFloat = 1, opacity: Double = 1) {
        var path = Path(); path.addLines(points)
        context.stroke(path, with: .color(Color(dinoHex: color).opacity(opacity)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func polygon(_ points: [CGPoint], light: UInt32, face: UInt32, dark: UInt32) {
        var path = Path(); path.addLines(points); path.closeSubpath()
        material(path, light: light, face: face, dark: dark)
    }
    private func oval(_ r: CGRect, light: UInt32, face: UInt32, dark: UInt32) {
        let center = CGPoint(x: r.minX + r.width * 0.3, y: r.minY + r.height * 0.2)
        context.fill(Path(ellipseIn: r), with: .radialGradient(Gradient(colors: [Color(dinoHex: light), Color(dinoHex: face), Color(dinoHex: dark)]),
                                                               center: center, startRadius: 0, endRadius: max(r.width, r.height) * 0.8))
    }
    private func glow(at point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), .clear]), center: point, startRadius: 0, endRadius: radius))
    }
    private func transformed(at point: CGPoint, scale: CGFloat = 1, mirror: Bool = false, draw: (WorldBannerPainter) -> Void) {
        var layer = context
        layer.translateBy(x: point.x, y: point.y); layer.scaleBy(x: mirror ? -scale : scale, y: scale)
        draw(.init(context: layer, world: world))
    }

    func draw(in size: CGSize) {
        let layout = WorldBannerLayout(width: size.width)
        // One continuous silhouette owns the chapter tab, shoulders and base.
        foundation(layout: layout)
        connectedRim(layout: layout)
        let ornamentScale = min(1.10, layout.scale)
        let ornamentY = 180 - 70 * ornamentScale
        for side in 0..<2 {
            transformed(at: CGPoint(x: side == 0 ? 54 * layout.scale : size.width - 54 * layout.scale, y: ornamentY),
                        scale: ornamentScale, mirror: side == 1) {
                $0.endcap(front: false, variation: side)
            }
        }
        // Seat the rear posts in the bottom rail; the foreground leaves, stone
        // heels and shells then wrap over it without being sliced by its bevel.
        lowerMoulding(layout: layout)
        // The quiet lettering surface occludes the inward parts of the ornaments.
        // They grow out of the frame instead of sitting over the lettering.
        board(in: layout.titlePanel)
        subtitle(in: layout.subtitle)
        tab(in: layout.tab)
        for side in 0..<2 {
            transformed(at: CGPoint(x: side == 0 ? 54 * layout.scale : size.width - 54 * layout.scale, y: ornamentY),
                        scale: ornamentScale, mirror: side == 1) {
                // Only small edge details cross the face; never redraw the whole
                // assembly or cover the inset description panel.
                $0.endcap(front: true, variation: side)
            }
        }
    }

    private func outline(plate r: CGRect, tab t: CGRect, inset: CGFloat = 0) -> Path {
        let r = r.insetBy(dx: inset, dy: inset)
        let t = t.insetBy(dx: inset, dy: inset)
        let corner = max(16, 28 - inset)
        return Path { p in
            p.move(to: CGPoint(x: r.minX + corner, y: r.minY))
            p.addLine(to: CGPoint(x: t.minX - 9, y: r.minY))
            p.addCurve(to: CGPoint(x: t.minX + 12, y: t.minY),
                       control1: CGPoint(x: t.minX + 1, y: r.minY),
                       control2: CGPoint(x: t.minX - 4, y: t.minY))
            p.addLine(to: CGPoint(x: t.maxX - 12, y: t.minY))
            p.addCurve(to: CGPoint(x: t.maxX + 9, y: r.minY),
                       control1: CGPoint(x: t.maxX + 4, y: t.minY),
                       control2: CGPoint(x: t.maxX - 1, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX - corner, y: r.minY))
            p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + corner), control: CGPoint(x: r.maxX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - corner))
            p.addQuadCurve(to: CGPoint(x: r.maxX - corner, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX + corner, y: r.maxY))
            p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - corner), control: CGPoint(x: r.minX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.minY + corner))
            p.addQuadCurve(to: CGPoint(x: r.minX + corner, y: r.minY), control: CGPoint(x: r.minX, y: r.minY))
            p.closeSubpath()
        }
    }

    private func foundation(layout: WorldBannerLayout) {
        let shape = outline(plate: layout.plate, tab: layout.tab)
        var shadow = context; shadow.translateBy(x: 0, y: 6)
        shadow.fill(shape, with: .color(Color(dinoHex: palette.shade).opacity(0.29)))
        material(shape, light: palette.tabLight, face: palette.dark, dark: palette.rim)
        context.stroke(shape, with: .color(Color(dinoHex: palette.shade).opacity(0.6)), lineWidth: 1.2)
        context.stroke(outline(plate: layout.plate, tab: layout.tab, inset: 3),
                       with: .linearGradient(Gradient(colors: [Color(dinoHex: palette.light), Color(dinoHex: palette.rim)]),
                                             startPoint: CGPoint(x: 0, y: 20), endPoint: CGPoint(x: layout.width, y: 184)), lineWidth: 2)
        context.stroke(outline(plate: layout.plate, tab: layout.tab, inset: 8),
                       with: .color(Color(dinoHex: palette.shade).opacity(0.22)), lineWidth: 1)
    }

    private func connectedRim(layout: WorldBannerLayout) {
        let r = layout.plate
        let rim = outline(plate: r, tab: layout.tab, inset: 6)
        if [1, 2, 4, 7].contains(world.id) {
            context.stroke(rim, with: .color(Color(dinoHex: palette.shade).opacity(0.72)),
                           style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
            context.stroke(rim, with: .color(Color(dinoHex: palette.accent).opacity(0.85)), lineWidth: 1)
            // A few leaves sprout from the shared top branch, joining the two fans.
            for side in 0..<2 {
                let x = side == 0 ? r.minX + 52 : r.maxX - 52
                transformed(at: CGPoint(x: x, y: r.minY + 7), scale: 0.56, mirror: side == 1) {
                    $0.leaf(at: .zero, length: 27, width: 17, angle: -76,
                            light: palette.light, face: palette.accent, dark: palette.shade)
                }
            }
        } else if world.id == 3 {
            context.stroke(rim, with: .color(Color(dinoHex: 0x6A606A)), lineWidth: 5)
            context.stroke(rim, with: .color(Color(dinoHex: 0xEEBA7A)), lineWidth: 1.3)
        } else if world.id == 5 {
            context.stroke(rim, with: .color(Color(dinoHex: 0xBEE4E4)), lineWidth: 4)
            context.stroke(rim, with: .color(Color(dinoHex: 0xE9FFF5)), lineWidth: 1.2)
        } else if world.id == 6 || world.id == 8 {
            context.stroke(rim, with: .color(Color(dinoHex: palette.rim)), lineWidth: 4)
            context.stroke(rim, with: .color(Color(dinoHex: palette.tabLight)), lineWidth: 1.3)
            for x in [r.minX + 16, r.maxX - 16] {
                for y in [r.minY + 17, r.maxY - 17] { rivet(at: CGPoint(x: x, y: y), radius: 2.1) }
            }
        } else if world.id == 9 {
            context.stroke(rim, with: .color(Color(dinoHex: 0x967247)), lineWidth: 4.6)
            context.stroke(rim, with: .color(Color(dinoHex: 0xEACF94)), lineWidth: 2.8)
            context.stroke(rim, with: .color(Color(dinoHex: 0xB58D58)), style: StrokeStyle(lineWidth: 2.6, dash: [1, 3]))
        } else {
            context.stroke(rim, with: .color(Color(dinoHex: 0xCDB170)), lineWidth: 4)
            context.stroke(rim, with: .color(Color(dinoHex: 0xFFF0BC)), lineWidth: 1.1)
        }
    }

    private func lowerMoulding(layout: WorldBannerLayout) {
        let r = layout.plate
        // One low, continuous bevel seats the posts without turning upward
        // through the foliage. The outer silhouette supplies the curved corners.
        var lip = Path()
        lip.move(to: CGPoint(x: r.minX + 24, y: r.maxY - 8))
        lip.addCurve(to: CGPoint(x: r.maxX - 24, y: r.maxY - 8),
                     control1: CGPoint(x: r.midX - 35, y: r.maxY - 9),
                     control2: CGPoint(x: r.midX + 35, y: r.maxY - 9))
        lip.addQuadCurve(to: CGPoint(x: r.maxX - 29, y: r.maxY - 2), control: CGPoint(x: r.maxX - 23, y: r.maxY - 2))
        lip.addLine(to: CGPoint(x: r.minX + 29, y: r.maxY - 2))
        lip.addQuadCurve(to: CGPoint(x: r.minX + 24, y: r.maxY - 8), control: CGPoint(x: r.minX + 23, y: r.maxY - 2))
        lip.closeSubpath()
        material(lip, light: palette.tabLight, face: palette.rim, dark: palette.shade)
        var bevel = Path()
        bevel.move(to: CGPoint(x: r.minX + 28, y: r.maxY - 7.5))
        bevel.addQuadCurve(to: CGPoint(x: r.maxX - 28, y: r.maxY - 7.5), control: CGPoint(x: r.midX, y: r.maxY - 9))
        context.stroke(bevel, with: .color(Color(dinoHex: palette.light).opacity(0.8)),
                       style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
    }

    private func board(in r: CGRect) {
        let shape = Path(roundedRect: r, cornerRadius: 18)
        // Recess the name surface into the continuous frame.
        context.fill(Path(roundedRect: r.insetBy(dx: -2, dy: -2), cornerRadius: 20),
                     with: .color(Color(dinoHex: palette.shade).opacity(0.28)))
        material(shape, light: palette.light, face: palette.face, dark: palette.dark)
        context.stroke(shape, with: .color(Color(dinoHex: palette.rim).opacity(0.6)), lineWidth: 1)
        context.stroke(Path(roundedRect: r.insetBy(dx: 2, dy: 2), cornerRadius: 16),
                       with: .linearGradient(Gradient(colors: [Color(dinoHex: palette.light), Color(dinoHex: palette.rim).opacity(0.5)]),
                                             startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)), lineWidth: 0.8)
        if [1, 4, 8, 9].contains(world.id) {
            for i in 0..<4 {
                var grain = Path()
                let y = r.minY + 16 + CGFloat(i) * 21
                grain.move(to: CGPoint(x: r.minX + 18, y: y))
                grain.addCurve(to: CGPoint(x: r.maxX - 18, y: y + 2),
                               control1: CGPoint(x: r.midX - 40, y: y - 6), control2: CGPoint(x: r.midX + 33, y: y + 6))
                context.stroke(grain, with: .color(Color(dinoHex: palette.rim).opacity(0.12)), lineWidth: 0.75)
            }
            for x in [r.minX + 24, r.maxX - 24] {
                context.stroke(Path(ellipseIn: CGRect(x: x - 3, y: r.maxY - 21, width: 6, height: 2)),
                               with: .color(Color(dinoHex: palette.rim).opacity(0.3)), lineWidth: 0.7)
            }
        } else if [5, 6].contains(world.id) {
            for i in 0..<3 {
                line([CGPoint(x: r.minX + 19, y: r.minY + 14 + CGFloat(i) * 3),
                      CGPoint(x: r.maxX - 25, y: r.minY + 14 + CGFloat(i) * 3)], color: 0xFFFFFF, width: 0.65, opacity: 0.20)
            }
        }
        if world.id == 9 {
            let rope = Path(roundedRect: r.insetBy(dx: 8, dy: 8), cornerRadius: 21)
            context.stroke(rope, with: .color(Color(dinoHex: 0xB78B4D)), lineWidth: 3.2)
            context.stroke(rope, with: .color(Color(dinoHex: 0xFCE3A6)), style: StrokeStyle(lineWidth: 1.5, dash: [2, 3]))
        }
        if world.id == 2 {
            context.stroke(Path(roundedRect: r.insetBy(dx: 9, dy: 9), cornerRadius: 20),
                           with: .color(Color(dinoHex: 0xF8F0DA).opacity(0.8)), style: StrokeStyle(lineWidth: 0.9, dash: [2, 4]))
        }
    }

    private func tab(in r: CGRect) {
        let inset = r.insetBy(dx: 5, dy: 3)
        let shape = Path(roundedRect: inset, cornerRadius: 8)
        material(shape, light: palette.tabLight, face: palette.tabFace, dark: palette.rim)
        context.stroke(shape, with: .color(Color(dinoHex: palette.tabLight).opacity(0.75)), lineWidth: 0.8)
        for x in [inset.minX + 5, inset.maxX - 5] { rivet(at: CGPoint(x: x, y: inset.midY), radius: 1.3) }
    }

    private func subtitle(in r: CGRect) {
        // A compact inset in the shared base leaves the side ornaments unobscured.
        let shape = Path(roundedRect: r, cornerRadius: 9)
        context.fill(Path(roundedRect: r.insetBy(dx: -1, dy: -1), cornerRadius: 10),
                     with: .color(Color(dinoHex: palette.shade).opacity(0.28)))
        material(shape, light: palette.subtitleLight, face: palette.subtitleFace, dark: palette.subtitleDark)
        context.stroke(shape, with: .linearGradient(Gradient(colors: [Color(dinoHex: palette.shade).opacity(0.55),
                                                                      Color(dinoHex: palette.subtitleLight)]),
                                                   startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)),
                       lineWidth: 0.9)
        var hem = Path()
        hem.move(to: CGPoint(x: r.minX + 9, y: r.maxY - 3))
        hem.addQuadCurve(to: CGPoint(x: r.maxX - 9, y: r.maxY - 3), control: CGPoint(x: r.midX, y: r.maxY - 2))
        context.stroke(hem, with: .color(Color(dinoHex: palette.subtitleLight).opacity(0.65)),
                       style: StrokeStyle(lineWidth: 0.6, dash: world.id == 2 ? [1.5, 3] : []))
        if world.id == 2 { moon(at: CGPoint(x: r.minX + 15, y: r.midY), radius: 7) }
        else { clock(at: CGPoint(x: r.minX + 15, y: r.midY), radius: 8, time: WorldBossClock.time(in: world.id)) }
        if [6, 8, 10].contains(world.id) {
            for x in [r.minX + 6, r.maxX - 6] { rivet(at: CGPoint(x: x, y: r.minY + 5), radius: 1.1) }
        }
    }

    private func endcap(front: Bool, variation: Int) {
        switch world.id {
        case 1, 2, 4, 7:
            let night = world.id == 2 || (world.id == 7 && variation == 1)
            let light: UInt32 = night ? 0xD2E4DC : world.id == 4 ? 0xD7E596 : 0xD1E978
            let face: UInt32 = night ? 0x91B2BF : world.id == 4 ? 0x91B460 : 0x83B742
            let dark: UInt32 = night ? 0x526E98 : 0x386C40
            if !front {
                organicStem(night: night)
                foliage(light: light, face: face, dark: dark, count: 12)
                if world.id == 2 || world.id == 7 {
                    let center = CGPoint(x: -19, y: -42)
                    medallion(at: center, radius: 18, night: night)
                    if night { moon(at: center, radius: 13) }
                    else { sun(at: center, radius: 10) }
                }
                if world.id == 4 {
                    roof(at: CGPoint(x: -25, y: -22))
                    // The little village sign is nailed to the living wooden post.
                    line([CGPoint(x: -41, y: -23), CGPoint(x: -7, y: -23)], color: 0x856E4C, width: 2)
                    bunting(from: CGPoint(x: -40, y: -26), to: CGPoint(x: -7, y: -26))
                    for x: CGFloat in [-40, -7] { rivet(at: CGPoint(x: x, y: -26), radius: 1.5) }
                }
            } else {
                if world.id == 1 || world.id == 4 {
                    leaf(at: CGPoint(x: 1, y: -39), length: 30, width: 23, angle: -65,
                         light: light, face: face, dark: dark)
                }
                leaf(at: CGPoint(x: 5, y: 61), length: 39, width: 27, angle: -68,
                     light: light, face: face, dark: dark)
                leaf(at: CGPoint(x: -15, y: 47), length: 24, width: 19, angle: -150,
                     light: light, face: face, dark: dark)
                if world.id == 1 || world.id == 4 {
                    // The stems terminate inside the calyx of each flower.
                    let flowers: [CGPoint] = world.id == 4
                        ? [CGPoint(x: -27, y: 43), CGPoint(x: -17, y: 51), CGPoint(x: -8, y: 44)]
                        : [CGPoint(x: -19, y: 48)]
                    for (index, point) in flowers.enumerated() {
                        line([CGPoint(x: -9, y: 62), point], color: dark, width: 1.8)
                        blossom(at: point, size: world.id == 4 ? 0.65 : 0.85, pink: index == 1)
                    }
                }
            }
        case 3:
            if !front {
                sideHousing(light: 0xB1A49F, face: 0x79727C, dark: 0x494D60)
                // Basalt ridges share one root and terminate beneath the stone heel.
                for (x, height, width) in [(CGFloat(-32), CGFloat(91), CGFloat(19)), (-14, 112, 27), (2, 82, 20)] {
                    rock(at: CGPoint(x: x, y: 57), width: width, height: height)
                }
                // Short transverse fissures branch from the lava-bearing ridges.
                for (x, y) in [(CGFloat(-25), CGFloat(-12)), (-21, 21), (-6, 3)] {
                    line([CGPoint(x: x - 8, y: y - 3), CGPoint(x: x, y: y), CGPoint(x: x + 3, y: y + 8)],
                         color: 0x4C4F61, width: 1.1, opacity: 0.75)
                    line([CGPoint(x: x - 8, y: y - 4), CGPoint(x: x - 1, y: y - 1)],
                         color: 0xC4ACA0, width: 0.55, opacity: 0.75)
                }
            } else {
                ornamentFoot(light: 0xB6A799, face: 0x7F727A, dark: 0x535468)
                var seam = Path()
                seam.move(to: CGPoint(x: -35, y: 51))
                seam.addCurve(to: CGPoint(x: 6, y: 63), control1: CGPoint(x: -21, y: 44), control2: CGPoint(x: -9, y: 64))
                context.stroke(seam, with: .color(Color(dinoHex: 0xC17653)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                context.stroke(seam, with: .color(Color(dinoHex: 0xFFCD8E)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                line([CGPoint(x: -24, y: 53), CGPoint(x: -19, y: 61), CGPoint(x: -20, y: 67)], color: 0x5F5868, width: 1)
            }
        case 5:
            if !front {
                sideHousing(light: 0xE2F6F1, face: 0x9CC8D9, dark: 0x6B8EB7)
                // All three crystals grow from the same geode bed; their roots
                // are hidden by its curved front edge, including on small widths.
                for (x, height, width, color) in [(CGFloat(-34), CGFloat(86), CGFloat(20), UInt32(0x83C7D5)),
                                                (-15, 111, 25, 0xA9ACDB), (3, 77, 19, 0x8ACFC7)] {
                    shard(at: CGPoint(x: x, y: 55), width: width, height: height, color: color)
                }
                // The light catches actual facet intersections, not floating stars.
                line([CGPoint(x: -16, y: -55), CGPoint(x: -17, y: -39)], color: 0xFFFFFF, width: 1.1, opacity: 0.8)
            } else {
                ornamentFoot(light: 0xEEFCF3, face: 0xA6CDDA, dark: 0x6F91B8)
                // Facets are cut into a closed stone, rather than loose chips.
                polygon([CGPoint(x: -34, y: 49), CGPoint(x: -18, y: 43), CGPoint(x: -10, y: 57), CGPoint(x: -31, y: 65)],
                        light: 0xDFFAF0, face: 0xA4CADD, dark: 0x7D9EC5)
                polygon([CGPoint(x: -18, y: 43), CGPoint(x: -2, y: 48), CGPoint(x: 6, y: 65), CGPoint(x: -10, y: 57)],
                        light: 0xF1FFF9, face: 0xB4D9DF, dark: 0x85AEC8)
                line([CGPoint(x: -31, y: 65), CGPoint(x: -10, y: 57), CGPoint(x: 6, y: 65)], color: 0xEEFFF8, width: 0.9)
            }
        case 6:
            if !front {
                sideHousing(light: 0xE0F5ED, face: 0x8EBCC7, dark: 0x4E7B95)
                for i in 0..<3 { cityFin(at: CGPoint(x: -31 + CGFloat(i) * 17, y: 55), height: CGFloat(80 + (i == 1 ? 28 : 0))) }
                // A conduit returns into the housing at both ends.
                line([CGPoint(x: -31, y: -18), CGPoint(x: -42, y: -18), CGPoint(x: -42, y: 38), CGPoint(x: -28, y: 38)],
                     color: 0x4F899C, width: 5)
                line([CGPoint(x: -31, y: -19), CGPoint(x: -43, y: -19), CGPoint(x: -43, y: 36), CGPoint(x: -28, y: 36)],
                     color: 0xBCE6E0, width: 1.2)
            } else {
                ornamentFoot(light: 0xE0F4E9, face: 0x91BBC4, dark: 0x527E96)
                let r = CGRect(x: -34, y: -9, width: 19, height: 44)
                material(Path(roundedRect: r, cornerRadius: 6), light: 0xDBF5ED, face: 0x8EBDC6, dark: 0x507F93)
                context.stroke(Path(roundedRect: r.insetBy(dx: 2, dy: 2), cornerRadius: 4),
                               with: .color(Color(dinoHex: 0x4F8294)), lineWidth: 0.7)
                for i in 0..<3 { oval(CGRect(x: -29, y: -3 + CGFloat(i) * 11, width: 8, height: 6), light: 0xE2FFF0, face: 0x90E9D7, dark: 0x4D999E) }
                for x: CGFloat in [-28, -4] { rivet(at: CGPoint(x: x, y: 60), radius: 2) }
                for i in 0..<3 {
                    line([CGPoint(x: -31, y: 48 + CGFloat(i) * 3), CGPoint(x: -23, y: 49 + CGFloat(i) * 3)],
                         color: 0x527E96, width: 0.7)
                }
                line([CGPoint(x: -22, y: 37), CGPoint(x: -22, y: 48), CGPoint(x: -6, y: 48)], color: 0x4E7C92, width: 2.5)
                line([CGPoint(x: -23, y: 37), CGPoint(x: -23, y: 47), CGPoint(x: -6, y: 47)], color: 0xBEF0DC, width: 1)
            }
        case 8:
            if !front {
                sideHousing(light: 0xFFE7AD, face: 0xC6A566, dark: 0x80744F)
                // Bearings are seated in the same cast bracket, with a visible
                // shaft between the gears instead of a disconnected wand.
                line([CGPoint(x: -21, y: -45), CGPoint(x: -21, y: 53)], color: 0x806D4A, width: 9)
                line([CGPoint(x: -23, y: -43), CGPoint(x: -23, y: 51)], color: 0xF6DB9A, width: 1.5)
                line([CGPoint(x: -21, y: -3), CGPoint(x: -36, y: -3)], color: 0x9B8152, width: 6)
                gear(at: CGPoint(x: -20, y: -31), radius: 19)
                gear(at: CGPoint(x: -37, y: -3), radius: 14)
                gear(at: CGPoint(x: -20, y: 26), radius: 20)
                line([CGPoint(x: -32, y: -52), CGPoint(x: -32, y: -17), CGPoint(x: -27, y: -14)],
                     color: 0x9A8153, width: 0.9, opacity: 0.8)
            } else {
                ornamentFoot(light: 0xFFE6AA, face: 0xC7A76A, dark: 0x8A7A53)
                clock(at: CGPoint(x: -20, y: -31), radius: 11, time: WorldBossClock.time(in: 8))
                for y: CGFloat in [-57, 60] { rivet(at: CGPoint(x: -17, y: y), radius: 2.7) }
                gear(at: CGPoint(x: -7, y: 52), radius: 10)
            }
        case 9:
            if !front {
                sideHousing(light: 0xF4DFAD, face: 0xC7AB77, dark: 0x907958)
                for x: CGFloat in [-32, -26] {
                    var grain = Path()
                    grain.move(to: CGPoint(x: x, y: -48))
                    grain.addCurve(to: CGPoint(x: x + 3, y: 40), control1: CGPoint(x: x - 6, y: -20), control2: CGPoint(x: x + 8, y: 9))
                    context.stroke(grain, with: .color(Color(dinoHex: 0x9C805B).opacity(0.55)), lineWidth: 0.75)
                }
                rope(from: CGPoint(x: 0, y: -55), to: CGPoint(x: -21, y: -45))
                anchor(at: CGPoint(x: -21, y: -9))
            } else {
                nauticalScroll()
                rope(from: CGPoint(x: -34, y: 46), to: CGPoint(x: 6, y: 67))
                shell(at: CGPoint(x: -22, y: 57))
                // A pearl rests in the shell cup, not beside it in mid-air.
                pearl(at: CGPoint(x: -22, y: 57), radius: 2.4)
            }
        default:
            if !front {
                sideHousing(light: 0xF5E8C9, face: 0xD7C9A5, dark: 0x999E92)
                for i in 0..<2 { turret(at: CGPoint(x: -30 + CGFloat(i) * 20, y: 56), height: CGFloat(92 + i * 13)) }
            } else {
                ornamentFoot(light: 0xF6E4BA, face: 0xC9B67D, dark: 0x92917E)
                // The fabric hangs from a real crossbar and rolls over the heel.
                line([CGPoint(x: -37, y: -28), CGPoint(x: -8, y: -28)], color: 0x8D7B54, width: 4)
                line([CGPoint(x: -37, y: -29), CGPoint(x: -8, y: -29)], color: 0xFBE6A6, width: 1.2)
                pennant(at: CGPoint(x: -23, y: 2))
                crown(at: CGPoint(x: -23, y: -33))
                for x: CGFloat in [-32, -11] { rivet(at: CGPoint(x: x, y: -27), radius: 1.5) }
                for x: CGFloat in [-29, -18] {
                    line([CGPoint(x: x, y: 51), CGPoint(x: x + 2, y: 64)], color: 0x9F946F, width: 0.7, opacity: 0.7)
                }
            }
        }
    }

    private func sideHousing(light: UInt32, face: UInt32, dark: UInt32) {
        var shape = Path()
        shape.move(to: CGPoint(x: 8, y: -57))
        switch world.id {
        case 3, 5:
            shape.addLine(to: CGPoint(x: -15, y: world.id == 5 ? -72 : -67))
            shape.addLine(to: CGPoint(x: -34, y: -58))
            shape.addLine(to: CGPoint(x: -42, y: -30))
            shape.addLine(to: CGPoint(x: -39, y: 12))
        case 10:
            shape.addLines([CGPoint(x: -4, y: -57), CGPoint(x: -4, y: -66), CGPoint(x: -14, y: -66),
                            CGPoint(x: -14, y: -57), CGPoint(x: -23, y: -57), CGPoint(x: -23, y: -67),
                            CGPoint(x: -33, y: -67), CGPoint(x: -33, y: -57), CGPoint(x: -40, y: -57),
                            CGPoint(x: -40, y: -31)])
        case 9:
            shape.addQuadCurve(to: CGPoint(x: -31, y: -56), control: CGPoint(x: -17, y: -67))
            shape.addQuadCurve(to: CGPoint(x: -38, y: -31), control: CGPoint(x: -39, y: -49))
        default:
            shape.addCurve(to: CGPoint(x: -21, y: -67), control1: CGPoint(x: -3, y: -67), control2: CGPoint(x: -13, y: -68))
            shape.addCurve(to: CGPoint(x: -39, y: -31), control1: CGPoint(x: -38, y: -64), control2: CGPoint(x: -39, y: -48))
        }
        shape.addLine(to: CGPoint(x: -37, y: 42))
        shape.addQuadCurve(to: CGPoint(x: 9, y: 70), control: CGPoint(x: -35, y: 72))
        shape.addQuadCurve(to: CGPoint(x: 11, y: 52), control: CGPoint(x: 17, y: 64))
        shape.addQuadCurve(to: CGPoint(x: -15, y: 36), control: CGPoint(x: -15, y: 54))
        shape.addLine(to: CGPoint(x: -14, y: -29))
        shape.addQuadCurve(to: CGPoint(x: 8, y: -43), control: CGPoint(x: -13, y: -43))
        shape.closeSubpath()
        var shadow = context; shadow.translateBy(x: 0.5, y: 2.5)
        shadow.fill(shape, with: .color(Color(dinoHex: dark).opacity(0.25)))
        material(shape, light: light, face: face, dark: dark)
        context.stroke(shape, with: .color(Color(dinoHex: dark).opacity(0.55)), lineWidth: 0.8)
        // The bevel follows the actual contour and is clipped to its material.
        var edge = context; edge.clip(to: shape)
        edge.stroke(shape.offsetBy(dx: 2.2, dy: 2.2), with: .color(Color(dinoHex: light).opacity(0.8)), lineWidth: 1.3)
        var highlight = Path()
        highlight.move(to: CGPoint(x: 3, y: -58))
        highlight.addCurve(to: CGPoint(x: -34, y: -31), control1: CGPoint(x: -27, y: -74), control2: CGPoint(x: -34, y: -50))
        highlight.addLine(to: CGPoint(x: -32, y: 41))
        highlight.addQuadCurve(to: CGPoint(x: 4, y: 66), control: CGPoint(x: -30, y: 66))
        edge.stroke(highlight, with: .color(Color(dinoHex: light).opacity(0.45)), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
    }

    private func ornamentFoot(light: UInt32, face: UInt32, dark: UInt32) {
        var foot = Path()
        foot.move(to: CGPoint(x: -36, y: 43))
        foot.addQuadCurve(to: CGPoint(x: 7, y: 53), control: CGPoint(x: -19, y: 38))
        foot.addQuadCurve(to: CGPoint(x: 10, y: 69), control: CGPoint(x: 14, y: 61))
        foot.addCurve(to: CGPoint(x: -38, y: 59), control1: CGPoint(x: -7, y: 75), control2: CGPoint(x: -34, y: 70))
        foot.addQuadCurve(to: CGPoint(x: -36, y: 43), control: CGPoint(x: -44, y: 50))
        foot.closeSubpath()
        material(foot, light: light, face: face, dark: dark)
        context.stroke(foot, with: .color(Color(dinoHex: dark).opacity(0.6)), lineWidth: 0.7)
        var seam = Path()
        seam.move(to: CGPoint(x: -33, y: 47))
        seam.addQuadCurve(to: CGPoint(x: 6, y: 57), control: CGPoint(x: -16, y: 45))
        context.stroke(seam, with: .color(Color(dinoHex: light).opacity(0.85)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
    }

    private func organicStem(night: Bool) {
        let light: UInt32 = night ? 0xBECFD0 : 0xD9CC92
        let face: UInt32 = night ? 0x829AA7 : 0x9D9860
        let dark: UInt32 = night ? 0x566F8F : 0x506D43
        var stem = Path()
        stem.move(to: CGPoint(x: 11, y: 70))
        stem.addCurve(to: CGPoint(x: -30, y: 39), control1: CGPoint(x: -13, y: 70), control2: CGPoint(x: -31, y: 61))
        stem.addCurve(to: CGPoint(x: -22, y: -42), control1: CGPoint(x: -34, y: 16), control2: CGPoint(x: -20, y: -15))
        stem.addQuadCurve(to: CGPoint(x: 6, y: -60), control: CGPoint(x: -21, y: -61))
        stem.addLine(to: CGPoint(x: 10, y: -50))
        stem.addQuadCurve(to: CGPoint(x: -12, y: -37), control: CGPoint(x: -9, y: -50))
        stem.addCurve(to: CGPoint(x: -16, y: 39), control1: CGPoint(x: -12, y: -12), control2: CGPoint(x: -25, y: 14))
        stem.addQuadCurve(to: CGPoint(x: 10, y: 58), control: CGPoint(x: -13, y: 57))
        stem.closeSubpath()
        material(stem, light: light, face: face, dark: dark)
        var grain = Path()
        grain.move(to: CGPoint(x: 3, y: -55))
        grain.addCurve(to: CGPoint(x: -24, y: 37), control1: CGPoint(x: -35, y: -55), control2: CGPoint(x: -17, y: 8))
        grain.addQuadCurve(to: CGPoint(x: 7, y: 65), control: CGPoint(x: -25, y: 64))
        context.stroke(grain, with: .color(Color(dinoHex: light).opacity(0.85)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        context.stroke(grain.offsetBy(dx: 3, dy: 0), with: .color(Color(dinoHex: dark).opacity(0.55)), lineWidth: 0.7)
    }

    private func medallion(at point: CGPoint, radius: CGFloat, night: Bool) {
        let r = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        oval(r, light: palette.tabLight, face: palette.rim, dark: palette.shade)
        oval(r.insetBy(dx: 3, dy: 3), light: night ? 0xA2AFC6 : 0xF8E4AE,
             face: night ? 0x7183A4 : 0xD7C18B, dark: night ? 0x506A94 : 0x9B9668)
        context.stroke(Path(ellipseIn: r.insetBy(dx: 2, dy: 2)), with: .color(Color(dinoHex: palette.light)), lineWidth: 0.9)
    }

    private func nauticalScroll() {
        var scroll = Path()
        scroll.move(to: CGPoint(x: 8, y: 69))
        scroll.addCurve(to: CGPoint(x: -42, y: 43), control1: CGPoint(x: -18, y: 75), control2: CGPoint(x: -43, y: 62))
        scroll.addCurve(to: CGPoint(x: -18, y: 27), control1: CGPoint(x: -47, y: 20), control2: CGPoint(x: -20, y: 13))
        scroll.addCurve(to: CGPoint(x: -17, y: 44), control1: CGPoint(x: -9, y: 35), control2: CGPoint(x: -11, y: 42))
        scroll.addQuadCurve(to: CGPoint(x: -30, y: 41), control: CGPoint(x: -29, y: 51))
        scroll.addQuadCurve(to: CGPoint(x: 8, y: 54), control: CGPoint(x: -25, y: 60))
        scroll.closeSubpath()
        material(scroll, light: 0xC1E4D4, face: 0x82BAB8, dark: 0x4E8797)
        context.stroke(scroll, with: .color(Color(dinoHex: 0x497D8A).opacity(0.75)), lineWidth: 0.8)
        var curl = Path()
        curl.move(to: CGPoint(x: 3, y: 64))
        curl.addCurve(to: CGPoint(x: -38, y: 41), control1: CGPoint(x: -21, y: 64), control2: CGPoint(x: -38, y: 55))
        curl.addCurve(to: CGPoint(x: -19, y: 32), control1: CGPoint(x: -41, y: 28), control2: CGPoint(x: -25, y: 20))
        context.stroke(curl, with: .color(Color(dinoHex: 0xD6F0DC)), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
    }

    private func foliage(light: UInt32, face: UInt32, dark: UInt32, count: Int = 8) {
        let leaves: [(CGFloat, CGFloat, CGFloat, CGFloat, Double, Bool)] = [
            (1, -38, 43, 27, -36, true), (-9, -36, 46, 30, -74, false),
            (-17, -26, 37, 25, -112, true), (-10, -7, 43, 31, -68, false),
            (-15, 7, 45, 30, -101, true), (-17, 25, 40, 28, -74, false),
            (-14, 35, 44, 29, -123, true), (-4, 48, 37, 28, -151, false),
            (-22, -12, 30, 24, -40, false), (-24, 15, 34, 24, -133, false),
            (0, 33, 35, 24, -29, false), (4, -25, 31, 23, 28, false)
        ]
        for value in leaves.prefix(count) {
            line([CGPoint(x: -20, y: value.1 + 3), CGPoint(x: value.0, y: value.1)], color: dark, width: 2.4)
            line([CGPoint(x: -20, y: value.1 + 2), CGPoint(x: value.0, y: value.1)], color: face, width: 0.9)
        }
        for value in leaves.prefix(count) {
            leaf(at: CGPoint(x: value.0, y: value.1), length: value.2, width: value.3, angle: value.4,
                 light: value.5 ? face : light, face: value.5 ? dark : face, dark: dark)
        }
    }
    private func leaf(at point: CGPoint, length: CGFloat, width: CGFloat, angle: Double, light: UInt32, face: UInt32, dark: UInt32) {
        var layer = context; layer.translateBy(x: point.x, y: point.y); layer.rotate(by: .degrees(angle))
        let r = CGRect(x: -width / 2, y: -length, width: width, height: length)
        // Shared with the player portrait: silhouette, asymmetric fold and curved veins.
        let leaf = DinoFoliageLeaf().path(in: CGRect(origin: .zero, size: r.size)).offsetBy(dx: r.minX, dy: r.minY)
        let fold = DinoFoliageFold().path(in: CGRect(origin: .zero, size: r.size)).offsetBy(dx: r.minX, dy: r.minY)
        let veins = DinoFoliageVeins().path(in: CGRect(origin: .zero, size: r.size)).offsetBy(dx: r.minX, dy: r.minY)
        var shadow = layer; shadow.translateBy(x: 0.7, y: 1.4)
        shadow.fill(leaf, with: .color(Color(dinoHex: dark).opacity(0.25)))
        layer.fill(leaf, with: .radialGradient(Gradient(stops: [
            .init(color: Color(dinoHex: light), location: 0),
            .init(color: Color(dinoHex: face), location: 0.48),
            .init(color: Color(dinoHex: dark), location: 1)
        ]), center: CGPoint(x: r.minX + width * 0.35, y: r.minY + length * 0.27),
                                             startRadius: 0, endRadius: length * 0.92))
        layer.fill(fold, with: .linearGradient(Gradient(colors: [.white.opacity(0.26), .clear]),
                                             startPoint: CGPoint(x: r.maxX, y: r.minY), endPoint: CGPoint(x: r.minX, y: r.maxY)))
        layer.stroke(leaf, with: .color(Color(dinoHex: light).opacity(0.55)), lineWidth: 0.7)
        layer.stroke(veins, with: .color(Color(dinoHex: light).opacity(0.6)), style: StrokeStyle(lineWidth: 0.55, lineCap: .round))
    }
    private func blossom(at point: CGPoint, size: CGFloat, pink: Bool) {
        for i in 0..<5 {
            let a = Double(i) * .pi * 2 / 5
            oval(CGRect(x: point.x + CGFloat(cos(a)) * 5 * size - 4 * size, y: point.y + CGFloat(sin(a)) * 5 * size - 4 * size, width: 8 * size, height: 8 * size),
                 light: 0xFFF9E7, face: pink ? 0xEFC6CB : 0xF5EFD9, dark: pink ? 0xC894A6 : 0xCFC9AC)
        }
        oval(CGRect(x: point.x - 3 * size, y: point.y - 3 * size, width: 6 * size, height: 6 * size),
             light: 0xFFF0A8, face: 0xEEC866, dark: 0xB2944A)
    }
    private func rivet(at point: CGPoint, radius: CGFloat) {
        oval(CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2),
             light: palette.tabLight, face: palette.rim, dark: palette.shade)
        line([CGPoint(x: point.x - radius * 0.4, y: point.y), CGPoint(x: point.x + radius * 0.4, y: point.y)],
             color: palette.shade, width: 0.5, opacity: 0.7)
    }
    private func pearl(at point: CGPoint, radius: CGFloat) {
        oval(CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2),
             light: 0xFFFAE2, face: 0xD6E3D9, dark: 0x819DB1)
    }
    private func moon(at point: CGPoint, radius: CGFloat) {
        glow(at: point, radius: radius * 1.6, color: 0xFDE5AF, opacity: 0.25)
        let r = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        var cut = Path(ellipseIn: r)
        cut.addEllipse(in: r.offsetBy(dx: radius * 0.48, dy: -radius * 0.28).insetBy(dx: radius * 0.08, dy: radius * 0.08))
        var moon = context; moon.clip(to: Path(ellipseIn: r)); moon.clip(to: cut, style: FillStyle(eoFill: true))
        WorldBannerPainter(context: moon, world: world).material(Path(ellipseIn: r), light: 0xFFF5CC, face: 0xE3C687, dark: 0xA89877)
        for i in 0..<3 { pearl(at: CGPoint(x: point.x - radius * 0.43 + CGFloat(i % 2) * 3, y: point.y - radius * 0.35 + CGFloat(i) * 5), radius: 1.3) }
    }
    private func sun(at point: CGPoint, radius: CGFloat) {
        glow(at: point, radius: radius * 1.7, color: 0xFFE5A6, opacity: 0.28)
        for i in 0..<12 {
            let a = Double(i) * .pi / 6
            line([CGPoint(x: point.x + CGFloat(cos(a)) * (radius + 3), y: point.y + CGFloat(sin(a)) * (radius + 3)),
                  CGPoint(x: point.x + CGFloat(cos(a)) * (radius + 7), y: point.y + CGFloat(sin(a)) * (radius + 7))],
                 color: 0xE6C278, width: 1.8)
        }
        oval(CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2),
             light: 0xFFF3B6, face: 0xE8C875, dark: 0xB49D60)
        context.stroke(Path(ellipseIn: CGRect(x: point.x - radius + 3, y: point.y - radius + 3, width: radius * 2 - 6, height: radius * 2 - 6)),
                       with: .color(Color(dinoHex: 0xFFF2C3).opacity(0.7)), lineWidth: 1)
    }
    private func rock(at point: CGPoint, width: CGFloat, height: CGFloat) {
        let pts = [CGPoint(x: point.x - width / 2, y: point.y + 5), CGPoint(x: point.x - width * 0.62, y: point.y - height * 0.53),
                   CGPoint(x: point.x - width * 0.25, y: point.y - height), CGPoint(x: point.x + width * 0.26, y: point.y - height * 0.91),
                   CGPoint(x: point.x + width * 0.53, y: point.y - height * 0.24), CGPoint(x: point.x + width / 2, y: point.y + 5)]
        let stone = Path { p in
            for i in pts.indices {
                let previous = pts[(i + pts.count - 1) % pts.count], next = pts[(i + 1) % pts.count], point = pts[i]
                func near(_ neighbour: CGPoint) -> CGPoint {
                    let t = min(0.25, 6 / max(1, hypot(neighbour.x - point.x, neighbour.y - point.y)))
                    return CGPoint(x: point.x + (neighbour.x - point.x) * t, y: point.y + (neighbour.y - point.y) * t)
                }
                if i == 0 { p.move(to: near(previous)) } else { p.addLine(to: near(previous)) }
                p.addQuadCurve(to: near(next), control: point)
            }
            p.closeSubpath()
        }
        material(stone, light: 0xBEADA6, face: 0x8E818C, dark: 0x626277)
        var clipped = context; clipped.clip(to: stone)
        WorldBannerPainter(context: clipped, world: world).polygon([pts[2], CGPoint(x: point.x - 1, y: point.y - height * 0.41), pts[0], pts[1]],
                                                                  light: 0xC4B2A7, face: 0xA29399, dark: 0x827C8D)
        let fissure = Path { p in
            p.move(to: CGPoint(x: point.x - 2, y: point.y - height * 0.84))
            p.addCurve(to: CGPoint(x: point.x - 3, y: point.y - height * 0.53),
                       control1: CGPoint(x: point.x - 2, y: point.y - height * 0.69), control2: CGPoint(x: point.x - 7, y: point.y - height * 0.60))
            p.addCurve(to: CGPoint(x: point.x - 2, y: point.y + 5),
                       control1: CGPoint(x: point.x + 7, y: point.y - height * 0.33), control2: CGPoint(x: point.x - 4, y: point.y - height * 0.15))
        }
        context.stroke(fissure, with: .color(Color(dinoHex: 0xCF8867)), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
        context.stroke(fissure, with: .color(Color(dinoHex: 0xFFE0A7)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
    }
    private func shard(at point: CGPoint, width: CGFloat, height: CGFloat, color: UInt32) {
        let top = CGPoint(x: point.x + width * 0.13, y: point.y - height)
        let left = CGPoint(x: point.x - width * 0.48, y: point.y - height * 0.78)
        let right = CGPoint(x: point.x + width * 0.48, y: point.y - height * 0.79)
        polygon([CGPoint(x: point.x - width / 2, y: point.y), left, top, right, CGPoint(x: point.x + width / 2, y: point.y)],
                light: 0xE7FFF0, face: color, dark: 0x5D7CA2)
        polygon([left, top, CGPoint(x: point.x + 1, y: point.y - 2), CGPoint(x: point.x - width / 2, y: point.y)],
                light: 0xEEFFF1, face: color, dark: 0x9ABECF)
        line([top, CGPoint(x: point.x + 1, y: point.y - 3)], color: 0xEFFFF1, width: 0.8, opacity: 0.9)
        line([left, right], color: 0xD8FAE9, width: 0.6, opacity: 0.7)
    }
    private func roof(at point: CGPoint) {
        material(Path(roundedRect: CGRect(x: point.x - 11, y: point.y, width: 25, height: 35), cornerRadius: 4),
                 light: 0xF6E2B7, face: 0xD8C093, dark: 0xAB986D)
        polygon([CGPoint(x: point.x - 18, y: point.y + 2), CGPoint(x: point.x, y: point.y - 19), CGPoint(x: point.x + 19, y: point.y + 2)],
                light: 0xEFBF9E, face: 0xBF866A, dark: 0x8B6957)
        line([CGPoint(x: point.x - 15, y: point.y + 2), CGPoint(x: point.x, y: point.y - 14), CGPoint(x: point.x + 16, y: point.y + 2)],
             color: 0xF5DCAC, width: 1.3)
        material(Path(roundedRect: CGRect(x: point.x - 4, y: point.y + 7, width: 9, height: 12), cornerRadius: 2),
                 light: 0xE2EDDC, face: 0xA7C9C7, dark: 0x6E9B9A)
        line([CGPoint(x: point.x, y: point.y + 8), CGPoint(x: point.x, y: point.y + 18)], color: 0xF7E4BC, width: 1)
        line([CGPoint(x: point.x - 4, y: point.y + 13), CGPoint(x: point.x + 4, y: point.y + 13)], color: 0xF7E4BC, width: 1)
    }
    private func bunting(from a: CGPoint, to b: CGPoint) {
        let control = CGPoint(x: (a.x + b.x) / 2, y: a.y + 13)
        func onCord(_ t: CGFloat) -> CGPoint {
            let u = 1 - t
            return CGPoint(x: u * u * a.x + 2 * u * t * control.x + t * t * b.x,
                           y: u * u * a.y + 2 * u * t * control.y + t * t * b.y)
        }
        var cord = Path(); cord.move(to: a); cord.addQuadCurve(to: b, control: control)
        context.stroke(cord, with: .color(Color(dinoHex: 0x8D805C)), lineWidth: 1)
        for i in 0..<4 {
            let t = (CGFloat(i) + 0.5) / 4
            let center = onCord(t)
            polygon([onCord(t - 0.09), onCord(t + 0.09), CGPoint(x: center.x, y: center.y + 10)],
                    light: 0xF8E9C6, face: i.isMultiple(of: 2) ? 0xDBA283 : 0x82B6A5, dark: 0x8B8268)
            line([CGPoint(x: center.x, y: center.y + 1), CGPoint(x: center.x, y: center.y + 8)], color: 0xFAEBD1, width: 0.55)
        }
    }
    private func cityFin(at point: CGPoint, height: CGFloat) {
        let r = CGRect(x: point.x - 8, y: point.y - height, width: 16, height: height)
        material(Path(roundedRect: r, cornerRadius: 4), light: 0xD9F2EA, face: 0x87B7C4, dark: 0x547A96)
        line([CGPoint(x: r.minX + 3, y: r.maxY - 4), CGPoint(x: r.minX + 3, y: r.minY + 5)], color: 0xD6F6E8, width: 1.2)
        for i in 0..<4 { line([CGPoint(x: r.minX + 7, y: r.minY + 11 + CGFloat(i) * 11), CGPoint(x: r.maxX - 3, y: r.minY + 11 + CGFloat(i) * 11)], color: 0xAAF2D9, width: 2.3) }
        rivet(at: CGPoint(x: point.x, y: r.maxY - 7), radius: 2)
    }
    private func gear(at point: CGPoint, radius: CGFloat) {
        let pts = (0..<48).map { i -> CGPoint in
            let a = Double(i) * .pi / 24, r = i % 4 < 2 ? radius : radius * 0.78
            return CGPoint(x: point.x + CGFloat(cos(a)) * r, y: point.y + CGFloat(sin(a)) * r)
        }
        polygon(pts.map { CGPoint(x: $0.x, y: $0.y + 2) }, light: 0xBFA368, face: 0xA88C58, dark: 0x716C55)
        polygon(pts, light: 0xFFE8AA, face: 0xD9B76C, dark: 0xA08E5B)
        context.stroke(Path(ellipseIn: CGRect(x: point.x - radius * 0.6, y: point.y - radius * 0.6, width: radius * 1.2, height: radius * 1.2)),
                       with: .color(Color(dinoHex: 0xF9E0A2)), lineWidth: 1.3)
        oval(CGRect(x: point.x - radius * 0.4, y: point.y - radius * 0.4, width: radius * 0.8, height: radius * 0.8),
             light: 0xDCD8B4, face: 0xA8B4A9, dark: 0x697F85)
        for i in 0..<6 {
            let angle = Double(i) * .pi / 3
            let inner = CGPoint(x: point.x + CGFloat(cos(angle)) * radius * 0.45,
                                y: point.y + CGFloat(sin(angle)) * radius * 0.45)
            let outer = CGPoint(x: point.x + CGFloat(cos(angle)) * radius * 0.57,
                                y: point.y + CGFloat(sin(angle)) * radius * 0.57)
            line([inner, outer], color: 0x8C825C, width: 1.2)
            line([CGPoint(x: inner.x - 0.5, y: inner.y - 0.5), CGPoint(x: outer.x - 0.5, y: outer.y - 0.5)],
                 color: 0xFFE8AF, width: 0.5)
        }
        rivet(at: point, radius: 2.4)
    }
    private func clock(at point: CGPoint, radius: CGFloat, time: ClockTime) {
        oval(CGRect(x: point.x - radius - 2, y: point.y - radius - 2, width: radius * 2 + 4, height: radius * 2 + 4),
             light: palette.tabLight, face: palette.rim, dark: palette.shade)
        oval(CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2),
             light: 0xFFFEEC, face: 0xF0EACD, dark: 0xD2CFAF)
        for i in 0..<12 {
            let a = Double(i) * .pi / 6
            line([CGPoint(x: point.x + CGFloat(sin(a)) * radius * 0.79, y: point.y - CGFloat(cos(a)) * radius * 0.79),
                  CGPoint(x: point.x + CGFloat(sin(a)) * radius * 0.9, y: point.y - CGFloat(cos(a)) * radius * 0.9)],
                 color: 0x537B7F, width: i.isMultiple(of: 3) ? 0.9 : 0.5)
        }
        for (angle, reach, weight) in [(Double(time.hour % 12) * .pi / 6 + Double(time.minute) * .pi / 360, CGFloat(0.48), CGFloat(1.2)),
                                       (Double(time.minute) * .pi / 30, CGFloat(0.68), CGFloat(0.9))] {
            line([point, CGPoint(x: point.x + CGFloat(sin(angle)) * radius * reach, y: point.y - CGFloat(cos(angle)) * radius * reach)],
                 color: 0x345E6B, width: weight)
        }
        pearl(at: point, radius: 1.1)
    }
    private func rope(from a: CGPoint, to b: CGPoint) {
        var path = Path(); path.move(to: a)
        path.addCurve(to: b, control1: CGPoint(x: a.x - 22, y: a.y + 22), control2: CGPoint(x: b.x + 17, y: b.y - 18))
        context.stroke(path, with: .color(Color(dinoHex: 0x9D7B4F)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
        context.stroke(path, with: .color(Color(dinoHex: 0xE6CC95)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        context.stroke(path, with: .color(Color(dinoHex: 0xB19465)), style: StrokeStyle(lineWidth: 4, dash: [1.2, 3]))
        context.stroke(path, with: .color(Color(dinoHex: 0xFFF0BA).opacity(0.75)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
    }
    private func anchor(at point: CGPoint) {
        var path = Path()
        path.move(to: CGPoint(x: point.x, y: point.y - 27)); path.addLine(to: CGPoint(x: point.x, y: point.y + 23))
        path.move(to: CGPoint(x: point.x - 12, y: point.y - 7)); path.addLine(to: CGPoint(x: point.x + 12, y: point.y - 7))
        path.move(to: CGPoint(x: point.x - 17, y: point.y + 7))
        path.addCurve(to: CGPoint(x: point.x + 17, y: point.y + 7), control1: CGPoint(x: point.x - 16, y: point.y + 30), control2: CGPoint(x: point.x + 16, y: point.y + 30))
        context.stroke(path, with: .color(Color(dinoHex: 0x4B757D)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
        context.stroke(path, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xB4D6C5), Color(dinoHex: 0x77A7A4)]), startPoint: CGPoint(x: point.x - 15, y: point.y - 30),
                                                 endPoint: CGPoint(x: point.x + 15, y: point.y + 30)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        context.stroke(Path(ellipseIn: CGRect(x: point.x - 5, y: point.y - 38, width: 10, height: 10)),
                       with: .color(Color(dinoHex: 0x7EA9A6)), lineWidth: 3)
        for side: CGFloat in [-1, 1] { polygon([CGPoint(x: point.x + side * 18, y: point.y + 5), CGPoint(x: point.x + side * 11, y: point.y + 10),
                                              CGPoint(x: point.x + side * 19, y: point.y + 14)], light: 0xD3E5D2, face: 0x8DB3AB, dark: 0x597D80) }
    }
    private func shell(at point: CGPoint) {
        var path = Path(); path.move(to: CGPoint(x: point.x, y: point.y + 7))
        path.addCurve(to: CGPoint(x: point.x - 12, y: point.y - 8), control1: CGPoint(x: point.x - 9, y: point.y + 3), control2: CGPoint(x: point.x - 15, y: point.y - 4))
        path.addQuadCurve(to: CGPoint(x: point.x + 12, y: point.y - 8), control: CGPoint(x: point.x, y: point.y - 20))
        path.addCurve(to: CGPoint(x: point.x, y: point.y + 7), control1: CGPoint(x: point.x + 15, y: point.y - 4), control2: CGPoint(x: point.x + 9, y: point.y + 3))
        path.closeSubpath(); material(path, light: 0xFFF1D8, face: 0xE6C6A8, dark: 0xBA9781)
        for i in -2...2 { line([CGPoint(x: point.x, y: point.y + 5), CGPoint(x: point.x + CGFloat(i) * 4, y: point.y - 9 + CGFloat(abs(i)) * 2)],
                              color: 0xFFF0D6, width: 0.8) }
    }
    private func turret(at point: CGPoint, height: CGFloat) {
        let r = CGRect(x: point.x - 9, y: point.y - height, width: 18, height: height)
        material(Path(roundedRect: r, cornerRadius: 4), light: 0xF7EACD, face: 0xD8CCAD, dark: 0xA9AA96)
        for i in 1..<5 {
            let y = r.minY + CGFloat(i) * height / 5
            line([CGPoint(x: r.minX + 1, y: y), CGPoint(x: r.maxX - 1, y: y)], color: 0xA7A792, width: 0.65)
            line([CGPoint(x: point.x + CGFloat(i % 2) * 4 - 2, y: y), CGPoint(x: point.x + CGFloat(i % 2) * 4 - 2, y: y + height / 5)], color: 0xB8B39B, width: 0.6)
        }
        for i in 0..<3 {
            material(Path(roundedRect: CGRect(x: r.minX - 2 + CGFloat(i) * 7, y: r.minY - 6, width: 6, height: 12), cornerRadius: 1.5),
                     light: 0xFFF0D2, face: 0xDFD3B3, dark: 0xBAB399)
        }
        rivet(at: CGPoint(x: point.x, y: r.minY + 18), radius: 2)
    }
    private func pennant(at point: CGPoint) {
        polygon([CGPoint(x: point.x - 13, y: point.y - 27), CGPoint(x: point.x + 12, y: point.y - 27), CGPoint(x: point.x + 10, y: point.y + 36),
                 CGPoint(x: point.x, y: point.y + 26), CGPoint(x: point.x - 12, y: point.y + 36)],
                light: 0xAEC5E1, face: 0x6A89B8, dark: 0x3E5885)
        line([CGPoint(x: point.x - 10, y: point.y - 24), CGPoint(x: point.x - 10, y: point.y + 31)], color: 0xEBD397, width: 1)
        line([CGPoint(x: point.x + 8, y: point.y - 24), CGPoint(x: point.x + 7, y: point.y + 31)], color: 0xEBD397, width: 1)
        polygon([CGPoint(x: point.x, y: point.y - 12), CGPoint(x: point.x + 4, y: point.y - 4), CGPoint(x: point.x, y: point.y + 4),
                 CGPoint(x: point.x - 4, y: point.y - 4)], light: 0xFBE6B3, face: 0xD4B675, dark: 0xA38B5C)
        line([CGPoint(x: point.x + 1, y: point.y + 10), CGPoint(x: point.x + 3, y: point.y + 24)], color: 0xBDD1E8, width: 1, opacity: 0.5)
    }
    private func crown(at point: CGPoint) {
        polygon([CGPoint(x: point.x - 13, y: point.y + 7), CGPoint(x: point.x - 15, y: point.y - 14), CGPoint(x: point.x - 7, y: point.y - 6),
                 CGPoint(x: point.x, y: point.y - 20), CGPoint(x: point.x + 7, y: point.y - 6), CGPoint(x: point.x + 15, y: point.y - 14),
                 CGPoint(x: point.x + 13, y: point.y + 7)], light: 0xFFF0B6, face: 0xDBBC74, dark: 0xAD9358)
        line([CGPoint(x: point.x - 12, y: point.y + 4), CGPoint(x: point.x + 12, y: point.y + 4)], color: 0xFFEDAE, width: 2)
        for x: CGFloat in [-7, 0, 7] { oval(CGRect(x: point.x + x - 2, y: point.y - 2, width: 4, height: 5), light: 0xCBF3D3, face: 0x77B6AF, dark: 0x4E817E) }
    }
}

// Shared foliage geometry keeps the banners and HUD portrait in one art style.
struct DinoFoliageFold: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.width * 0.66, y: 0),
                              control: CGPoint(x: rect.width * 0.43, y: rect.height * 0.42))
            path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                          control1: CGPoint(x: rect.width * 1.18, y: rect.height * 0.35),
                          control2: CGPoint(x: rect.width * 0.93, y: rect.height * 0.73))
            path.closeSubpath()
        }
    }
}

struct DinoFoliageVeins: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: rect.width * x, y: rect.height * y)
            }
            path.move(to: point(0.5, 0.97))
            path.addQuadCurve(to: point(0.66, 0.06), control: point(0.43, 0.42))
            for (center, left, right) in [(0.72, 0.58, 0.57), (0.52, 0.39, 0.38), (0.32, 0.23, 0.23)] {
                path.move(to: point(0.51, center))
                path.addQuadCurve(to: point(0.19, left), control: point(0.31, center - 0.025))
                path.move(to: point(0.54, center))
                path.addQuadCurve(to: point(0.85, right), control: point(0.72, center - 0.015))
            }
        }
    }
}

struct DinoFoliageLeaf: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addCurve(to: CGPoint(x: rect.width * 0.66, y: 0),
                          control1: CGPoint(x: -rect.width * 0.28, y: rect.height * 0.62),
                          control2: CGPoint(x: rect.width * 0.14, y: rect.height * 0.08))
            path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                          control1: CGPoint(x: rect.width * 1.18, y: rect.height * 0.35),
                          control2: CGPoint(x: rect.width * 0.93, y: rect.height * 0.73))
            path.closeSubpath()
        }
    }
}


/// Each ten-level section can supply its own palette. The last part blends into
/// the next section's palette, so adjoining worlds share the same horizon.
struct WorldLandscapePalette: Equatable {
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

/// A small, static fan uses the same folded leaves as the world sign and HUD.
struct JungleFriendsLeaves: View {
    var body: some View {
        Canvas { context, size in
            for side in 0..<2 {
                var c = context
                c.translateBy(x: side == 0 ? 36 : size.width - 36, y: size.height / 2)
                c.scaleBy(x: side == 0 ? 1 : -1, y: 1)
                var stem = Path()
                stem.move(to: CGPoint(x: 5, y: 16))
                stem.addQuadCurve(to: CGPoint(x: -24, y: -16), control: CGPoint(x: -18, y: 13))
                c.stroke(stem, with: .color(Color(dinoHex: 0x396C36)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                for (x, y, angle, length) in [(CGFloat(-2), CGFloat(8), -61.0, CGFloat(35)),
                                             (-8, 0, -103, 36), (-6, -7, -29, 31), (2, 8, -130, 24)] {
                    var leaf = c
                    leaf.translateBy(x: x, y: y)
                    leaf.rotate(by: .degrees(angle))
                    let r = CGRect(x: -10, y: -length, width: 20, height: length)
                    let shape = DinoFoliageLeaf().path(in: CGRect(origin: .zero, size: r.size)).offsetBy(dx: r.minX, dy: r.minY)
                    let fold = DinoFoliageFold().path(in: CGRect(origin: .zero, size: r.size)).offsetBy(dx: r.minX, dy: r.minY)
                    let veins = DinoFoliageVeins().path(in: CGRect(origin: .zero, size: r.size)).offsetBy(dx: r.minX, dy: r.minY)
                    leaf.fill(shape, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xC4DF54), Color(dinoHex: 0x78B33F), Color(dinoHex: 0x326D37)]),
                                                          startPoint: CGPoint(x: -6, y: -length), endPoint: CGPoint(x: 8, y: 0)))
                    leaf.fill(fold, with: .color(.white.opacity(0.16)))
                    leaf.stroke(veins, with: .color(Color(dinoHex: 0xD8ED8A).opacity(0.65)), style: StrokeStyle(lineWidth: 0.6, lineCap: .round))
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// All landscape artwork is drawn from paths, ellipses and rounded rectangles.
/// One continuous canvas includes the overscroll sky; small wildlife and water
/// overlays animate independently of the static scenery.
struct WorldMapLandscape: View, Equatable {
    var palette = WorldLandscapePalette.jungle
    var nextPalette = WorldLandscapePalette.nextHorizon
    var routeOffset: CGFloat = 0
    var viewportHeight: CGFloat = 900

    var body: some View {
        GeometryReader { geometry in
            let headroom = max(900, viewportHeight * 1.5)
            Canvas { canvasContext, _ in
                var context = canvasContext
                context.translateBy(x: 0, y: headroom)
                let size = geometry.size
                let w = size.width
                let left: CGFloat = 0
                let right = w - left
                let height = size.height - routeOffset
                let scale = min(1.35, max(0.82, w / 390))
                let skyEnd = min(0.32, max(0.08, (routeOffset + 210) / size.height))
                // The same gradient, sun glow and canopy paint across y=0. Joining
                // separately painted sky panels exposed the sun's clipped glow.
                context.fill(Path(CGRect(x: 0, y: -headroom, width: w, height: size.height + headroom)), with: .linearGradient(
                    Gradient(stops: [
                        .init(color: Color(dinoHex: 0x86DDF4), location: 0),
                        .init(color: Color(dinoHex: 0xC5F0EE), location: skyEnd * 0.47),
                        .init(color: Color(dinoHex: 0xEDF5BE), location: skyEnd),
                        .init(color: Color(dinoHex: palette.ground), location: 0.45),
                        .init(color: Color(dinoHex: 0xD4E6AD), location: 0.72),
                        .init(color: Color(dinoHex: nextPalette.ground), location: 1)
                    ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))

                let sky = JungleWorldPainter(context: context)
                sky.overscrollClouds(width: w, scale: scale)
                sky.entrance(width: w, left: left, right: right, height: max(350, routeOffset), scale: scale)
                var routeContext = context
                routeContext.translateBy(x: 0, y: routeOffset)
                let scenery = WorldSceneryLayout(width: w, height: size.height, routeOffset: routeOffset, jungle: true)
                scenery.drawBanks(in: routeContext, worldID: 1)
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
                }

                // The boss clearing opens into mist. Low silhouettes and the soft
                // color blend continue below level ten into the next world preview.
                for i in 0..<3 {
                    let y = height - 390 + CGFloat(i) * 105
                    painter.hill(x: i.isMultiple(of: 2) ? -w * 0.28 : w * 0.5,
                                 y: y, width: w * 0.82, height: 195,
                                 color: palette.color(\.distant, toward: nextPalette, progress: CGFloat(i + 1) / 3).opacity(0.44))
                }

            }
            .frame(width: geometry.size.width, height: geometry.size.height + headroom)
            .clipped()
            .offset(y: -headroom)
        }
        .overlay {
            GeometryReader { geometry in
                let w = geometry.size.width
                let scale = min(1.35, max(0.82, w / 390))
                let entranceHeight = max(350, routeOffset)
                JungleFlyingBirds(viewportHeight: viewportHeight)
                    .frame(width: min(530, w * 0.78), height: 64)
                    .position(x: w * 0.5, y: max(182, entranceHeight * 0.33))
                let waterBounds = JungleWaterfallGeometry.flowBounds
                JungleWaterfallFlow(scale: scale * 0.62, opacity: 0.58, viewportHeight: viewportHeight)
                    .position(x: -3 * scale + waterBounds.midX * scale * 0.62,
                              y: entranceHeight * 0.76 + waterBounds.midY * scale * 0.62)
                JungleWaterfallFlow(scale: scale * 0.87, viewportHeight: viewportHeight)
                    .position(x: w - 34 * scale + waterBounds.midX * scale * 0.87,
                              y: entranceHeight * 0.65 + waterBounds.midY * scale * 0.87)
                let scene = JungleMapLayout(width: w).scene()
                ForEach(scene.sceneryTiles.indices, id: \.self) { index in
                    JungleSceneryTile(scene: scene, index: index, viewportHeight: viewportHeight)
                        .equatable()
                        .position(x: w / 2, y: routeOffset + scene.sceneryTiles[index].bounds.midY)
                }
                let waterfall = scene.waterfall.item
                let point = scene.waterfall.point
                let bounds = JungleWaterfallGeometry.bounds(mirrored: waterfall.mirrored, heightScale: waterfall.heightScale)
                JungleWaterfallFlow(scale: waterfall.size, mirrored: waterfall.mirrored,
                                    heightScale: waterfall.heightScale, viewportHeight: viewportHeight)
                    .mask(JungleDepthOcclusion(scene: scene,
                        frame: bounds.applying(CGAffineTransform(scaleX: waterfall.size, y: waterfall.size)).offsetBy(dx: point.x, dy: point.y),
                        behindY: point.y))
                    .position(x: point.x + bounds.midX * waterfall.size,
                              y: routeOffset + point.y + bounds.midY * waterfall.size)
                ForEach(scene.snakes) { placement in
                    JungleWildlife(item: placement.item, viewportHeight: viewportHeight)
                        .mask(JungleDepthOcclusion(scene: scene, frame: placement.bounds, behindY: placement.point.y))
                        .position(x: placement.bounds.midX, y: routeOffset + placement.bounds.midY)
                }
                ForEach(scene.leaves) { placement in
                    JungleWildlife(item: placement.item, viewportHeight: viewportHeight)
                        .mask(JungleDepthOcclusion(scene: scene, frame: placement.bounds, behindY: placement.point.y))
                        .position(x: placement.bounds.midX, y: routeOffset + placement.bounds.midY)
                }
            }.clipped()
        }
        .overlay(alignment: .bottom) { WorldTerrainTransition(worldID: 2).equatable() }
        .allowsHitTesting(false).accessibilityHidden(true)
    }

    private func transition(at y: CGFloat, height: CGFloat) -> CGFloat {
        let t = min(1, max(0, (y - (height - 560)) / 560))
        return t * t * (3 - 2 * t)
    }
}

/// Small static textures cover wildlife and ground details in the correct order.
/// Tiles are prepared ahead of scrolling and retained until the chapter leaves
/// the map's nearby-world window. Scrolling back never replaces them with clear.
private struct JungleSceneryTile: View, Equatable {
    let scene: JungleMapLayout.Scene
    let index: Int
    let viewportHeight: CGFloat
    @State private var prepared = false

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.scene === rhs.scene && lhs.index == rhs.index && lhs.viewportHeight == rhs.viewportHeight
    }

    var body: some View {
        let tile = scene.sceneryTiles[index]
        Color.clear.overlay {
            if prepared {
                Canvas { context, _ in
                    var c = context
                    c.translateBy(x: 0, y: -tile.bounds.minY)
                    let painter = JungleWorldPainter(context: c)
                    let depth = WorldSceneryDepth()
                    for placement in tile.placements {
                        depth.add(at: placement.point.y) { painter.scenery(placement.item, at: placement.point) }
                    }
                    if tile.includesBoss {
                        let scale = min(1.35, max(0.82, tile.bounds.width / 390))
                        let boss = ThemePainter(context: c, colors: WorldThemeColors(DinoWorldCatalog.world(1)!))
                        depth.add(at: scene.bossPoint.y) {
                            boss.bossClearing(worldID: 1, at: scene.bossPoint, size: scale)
                            boss.boss(worldID: 1, at: scene.bossPoint, size: scale * 0.88)
                        }
                    }
                    depth.draw()
                }.clipped()
            }
        }
        .frame(width: tile.bounds.width, height: tile.bounds.height)
        .onGeometryChange(for: Bool.self) { geometry in
            let frame = geometry.frame(in: .named("adventure.map.viewport"))
            let margin = max(768, viewportHeight)
            return frame.maxY > -margin && frame.minY < viewportHeight + margin
        } action: { nearby in
            guard nearby, !prepared else { return }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { prepared = true }
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Animated items remain visible over higher scenery and behind lower roots.
/// The mask is static; timeline frames only redraw the small animal/water layer.
private struct JungleDepthOcclusion: View {
    let scene: JungleMapLayout.Scene
    let frame: CGRect
    let behindY: CGFloat

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
            var c = context
            c.translateBy(x: -frame.minX, y: -frame.minY)
            c.blendMode = .destinationOut
            let p = JungleWorldPainter(context: c)
            for item in scene.placements where !item.item.kind.animated && item.point.y > behindY && item.bounds.intersects(frame) {
                p.scenery(item.item, at: item.point)
            }
            if scene.bossPoint.y > behindY {
                let scale = min(1.35, max(0.82, scene.width / 390))
                WorldBossPainter(context: c).draw(worldID: 1, at: scene.bossPoint, size: scale * 0.88)
            }
        }
    }
}

/// Only visible bank wildlife ticks. Each snake and leaf drift has a small,
/// explicit envelope which participates in the same road-clearance solver.
private struct JungleWildlife: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false
    let item: JungleMapLayout.Item
    let viewportHeight: CGFloat

    var body: some View {
        let bounds = item.kind.footprint[0]
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !visible || reduceMotion || scenePhase != .active)) { timeline in
            Canvas { context, _ in
                var c = context
                c.translateBy(x: -bounds.minX * item.size, y: -bounds.minY * item.size)
                c.scaleBy(x: item.mirrored ? -item.size : item.size, y: item.size)
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                if item.kind == .snake { snake(in: c, time: time) }
                else { leaves(in: c, time: time) }
            }
        }
        .frame(width: bounds.width * item.size, height: bounds.height * item.size)
        .onGeometryChange(for: Bool.self) { geometry in
            let frame = geometry.frame(in: .named("adventure.map.viewport"))
            return frame.maxY > 0 && frame.minY < viewportHeight
        } action: { visible = $0 }
        .allowsHitTesting(false).accessibilityHidden(true)
    }

    private func leaves(in context: GraphicsContext, time: TimeInterval) {
        for i in 0..<4 {
            let seed = Double(i + item.variant)
            let progress = (time / 9.5 + Double(i) * 0.25 + Double(item.variant) * 0.07).truncatingRemainder(dividingBy: 1)
            let x = sin(progress * .pi * 2 + seed) * 18 + sin(time * 0.4 + seed) * 6 + Double(i % 2 == 0 ? -8 : 8)
            let y = -7 + progress * 164
            var c = context
            c.opacity = min(1, min(progress, 1 - progress) * 9) * 0.9
            c.translateBy(x: x, y: y)
            c.rotate(by: .radians(sin(progress * .pi * 2 + seed) * 0.8 + seed))
            let r = CGRect(x: 0, y: 0, width: 8, height: 14)
            c.translateBy(x: -4, y: -7)
            let leaf = DinoFoliageLeaf().path(in: r)
            c.fill(leaf, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xD5DD6A), Color(dinoHex: i % 2 == 0 ? 0x91B64B : 0xB6BE53), Color(dinoHex: 0x5B8744)]),
                                             startPoint: .zero, endPoint: CGPoint(x: 8, y: 14)))
            c.fill(DinoFoliageFold().path(in: r), with: .color(.white.opacity(0.2)))
            c.stroke(DinoFoliageVeins().path(in: r), with: .color(Color(dinoHex: 0xE8EBB0).opacity(0.75)), lineWidth: 0.55)
        }
    }

    private func snake(in context: GraphicsContext, time: TimeInterval) {
        let phase = time * 0.22 + Double(item.variant) * 2.1
        let bodyColors: [UInt32] = [0x79A74F, 0x6CA986, 0xA3B659]
        let outlines: [UInt32] = [0x3F6B3C, 0x3E7764, 0x687B3E]
        let color = bodyColors[item.variant % 3], outline = outlines[item.variant % 3]
        let points = (0...18).map { index -> CGPoint in
            let t = Double(index) / 18
            let angle = phase - (1 - t) * 1.75
            return CGPoint(x: cos(angle) * 44,
                           y: 8 + sin(angle) * 14 + sin(time * 2.4 - t * 7) * 2 * sin(t * .pi))
        }
        var left: [CGPoint] = [], right: [CGPoint] = []
        for i in points.indices {
            let before = points[max(0, i - 1)], after = points[min(18, i + 1)]
            let length = max(0.1, hypot(after.x - before.x, after.y - before.y))
            let radius = 0.5 + CGFloat(i) / 18 * 3.2
            let nx = -(after.y - before.y) / length * radius
            let ny = (after.x - before.x) / length * radius
            left.append(CGPoint(x: points[i].x + nx, y: points[i].y + ny))
            right.append(CGPoint(x: points[i].x - nx, y: points[i].y - ny))
        }
        var body = Path(); body.addLines(left + right.reversed()); body.closeSubpath()
        context.fill(body.offsetBy(dx: 0, dy: 3), with: .color(Color(dinoHex: 0x496B3E).opacity(0.18)))
        context.fill(body, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xBED58C), Color(dinoHex: color)]),
                                               startPoint: CGPoint(x: 0, y: -8), endPoint: CGPoint(x: 0, y: 23)))
        context.stroke(body, with: .color(Color(dinoHex: outline)), style: StrokeStyle(lineWidth: 0.9, lineJoin: .round))
        for i in 0..<18 {
            if i > 4 && i % 3 == 0 {
                let p = points[i]
                context.fill(Path(ellipseIn: CGRect(x: p.x - 1.5, y: p.y - 1.4, width: 3, height: 2)),
                             with: .color(Color(dinoHex: outline).opacity(0.65)))
            }
        }
        let head = points[18], previous = points[17]
        var c = context
        c.translateBy(x: head.x, y: head.y)
        c.rotate(by: .radians(atan2(head.y - previous.y, head.x - previous.x)))
        let face = Path(ellipseIn: CGRect(x: -4, y: -4.4, width: 12, height: 8.8))
        c.fill(face, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xCDE09D), Color(dinoHex: color)]),
                                         startPoint: CGPoint(x: 0, y: -4), endPoint: CGPoint(x: 0, y: 5)))
        c.stroke(face, with: .color(Color(dinoHex: outline)), lineWidth: 0.8)
        for side: CGFloat in [-1, 1] {
            c.fill(Path(ellipseIn: CGRect(x: 2.8, y: side * 2.5 - 0.7, width: 1.6, height: 1.4)), with: .color(Color(dinoHex: 0x244738)))
        }
        if sin(time * 2.2) > 0.7 {
            var tongue = Path()
            tongue.addLines([CGPoint(x: 7, y: 0), CGPoint(x: 12, y: 0), CGPoint(x: 14, y: -1.7)])
            tongue.move(to: CGPoint(x: 12, y: 0)); tongue.addLine(to: CGPoint(x: 14, y: 1.7))
            c.stroke(tongue, with: .color(Color(dinoHex: 0xB87564)), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
        }
    }
}

private struct JungleFlyingBirds: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false
    let viewportHeight: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !visible || reduceMotion || scenePhase != .active)) { timeline in
            Canvas { context, size in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<9 {
                    let seed = Double(i)
                    let flight = (time * (i < 5 ? 0.018 : 0.013) + seed * 0.113).truncatingRemainder(dividingBy: 1)
                    let x = CGFloat(flight) * (size.width + 30) - 15
                    let y = 12 + CGFloat(i % 3) * 17 + CGFloat(sin(time * 0.65 + seed * 1.7)) * 4
                    let span: CGFloat = i < 5 ? 4.8 : 3.5
                    let flap = CGFloat(sin(time * (4.6 + seed * 0.15) + seed * 1.8))
                    let lift = flap * span * 0.65
                    var bird = Path()
                    bird.move(to: CGPoint(x: x - span, y: y - lift))
                    bird.addQuadCurve(to: CGPoint(x: x, y: y + 1.3), control: CGPoint(x: x - span * 0.4, y: y - span * 0.35))
                    bird.addQuadCurve(to: CGPoint(x: x + span, y: y - lift), control: CGPoint(x: x + span * 0.4, y: y - span * 0.35))
                    let edgeFade = min(1, min(flight, 1 - flight) * 18)
                    context.stroke(bird, with: .color(Color(dinoHex: 0x527F87).opacity(edgeFade * (i < 5 ? 0.7 : 0.45))),
                                   style: StrokeStyle(lineWidth: i < 5 ? 1.1 : 0.85, lineCap: .round))
                }
            }
        }
        .onGeometryChange(for: Bool.self) { geometry in
            let frame = geometry.frame(in: .named("adventure.map.viewport"))
            return frame.maxY > 0 && frame.minY < viewportHeight
        } action: { visible = $0 }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Moving marks follow the stream toward the lower end.
/// A dash phase on a scaled or mirrored canvas runs back up the fall on iPad.
private enum DownstreamFlow {
    struct Metrics {
        var length: CGFloat
        var downward: Bool
    }

    static func metrics(_ path: Path) -> Metrics {
        var length: CGFloat = 0
        var first: CGPoint?
        var last: CGPoint?
        var previous: CGPoint?
        func visit(_ point: CGPoint) {
            if first == nil { first = point }
            if let previous { length += hypot(point.x - previous.x, point.y - previous.y) }
            previous = point
            last = point
        }
        path.forEach { element in
            switch element {
            case .move(to: let point):
                previous = point
                if first == nil { first = point }
                last = point
            case .line(to: let point):
                visit(point)
            case .quadCurve(to: let end, control: let control):
                guard let start = previous else { previous = end; return }
                for step in 1...12 {
                    let t = CGFloat(step) / 12, u = 1 - t
                    visit(CGPoint(x: u * u * start.x + 2 * u * t * control.x + t * t * end.x,
                                  y: u * u * start.y + 2 * u * t * control.y + t * t * end.y))
                }
            case .curve(to: let end, control1: let c1, control2: let c2):
                guard let start = previous else { previous = end; return }
                for step in 1...16 {
                    let t = CGFloat(step) / 16, u = 1 - t
                    visit(CGPoint(x: u * u * u * start.x + 3 * u * u * t * c1.x + 3 * u * t * t * c2.x + t * t * t * end.x,
                                  y: u * u * u * start.y + 3 * u * u * t * c1.y + 3 * u * t * t * c2.y + t * t * t * end.y))
                }
            case .closeSubpath:
                break
            }
        }
        return Metrics(length: max(1, length), downward: (last?.y ?? 0) >= (first?.y ?? 0))
    }

    static func marks(_ path: Path, metrics known: Metrics? = nil, in context: GraphicsContext,
                      shading: GraphicsContext.Shading, width: CGFloat, time: TimeInterval,
                      pointsPerSecond: Double, dash: CGFloat, gap: CGFloat) {
        let metrics = known ?? metrics(path)
        let period = max(1, dash + gap)
        let length = max(period, metrics.length)
        let count = max(1, Int(ceil(length / period)))
        let travel = CGFloat(time * pointsPerSecond).truncatingRemainder(dividingBy: length)
        for index in 0..<count {
            var head = travel + CGFloat(index) * period
            if head >= length { head -= length }
            if !metrics.downward { head = length - head }
            let tail = head - dash
            func piece(_ start: CGFloat, _ end: CGFloat) {
                let lower = min(1, max(0, start / length))
                let upper = min(1, max(0, end / length))
                guard upper > lower else { return }
                context.stroke(path.trimmedPath(from: lower, to: upper), with: shading,
                               style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            }
            if tail >= 0 {
                piece(tail, head)
            } else {
                piece(0, max(0, head))
                piece(length + tail, length)
            }
        }
    }
}

private enum JungleWaterfallGeometry {
    static let flowBounds = CGRect(x: -72, y: -248, width: 144, height: 346)

    static func bounds(mirrored: Bool, heightScale: CGFloat) -> CGRect {
        let bounds = mirrored ? CGRect(x: -72, y: -274, width: 174, height: 372) : flowBounds
        return bounds.applying(CGAffineTransform(scaleX: mirrored ? -1 : 1, y: heightScale)).standardized
    }

    static let curtain: Path = {
        Path { f in
            f.move(to: CGPoint(x: -9, y: -243))
            f.addCurve(to: CGPoint(x: -12, y: -88), control1: CGPoint(x: -8, y: -193), control2: CGPoint(x: -3, y: -133))
            f.addCurve(to: CGPoint(x: -32, y: 48), control1: CGPoint(x: -22, y: -41), control2: CGPoint(x: -16, y: 9))
            f.addQuadCurve(to: CGPoint(x: 29, y: 48), control: CGPoint(x: -2, y: 64))
            f.addCurve(to: CGPoint(x: 12, y: -88), control1: CGPoint(x: 10, y: 1), control2: CGPoint(x: 26, y: -46))
            f.addCurve(to: CGPoint(x: 14, y: -243), control1: CGPoint(x: 18, y: -145), control2: CGPoint(x: 8, y: -192))
            f.closeSubpath()
        }
    }()

    static let streams: [Path] = (0..<8).map { i in
        let x = CGFloat(i) * 5 - 17
        var stream = Path()
        stream.move(to: CGPoint(x: x, y: -257))
        stream.addCurve(to: CGPoint(x: x * 1.6, y: 63),
                        control1: CGPoint(x: x + 9, y: -137), control2: CGPoint(x: x - 10, y: -27))
        return stream
    }

    static let streamMetrics = streams.map(DownstreamFlow.metrics)
}

/// A bounded transparent canvas animates water, never the cliffs or map texture.
private struct JungleWaterfallFlow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false
    let scale: CGFloat
    var opacity: Double = 1
    var mirrored = false
    var heightScale: CGFloat = 1
    let viewportHeight: CGFloat

    var body: some View {
        let bounds = JungleWaterfallGeometry.bounds(mirrored: mirrored, heightScale: heightScale)
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !visible || reduceMotion || scenePhase != .active)) { timeline in
            Canvas { context, _ in
                if !reduceMotion {
                    var c = context
                    c.translateBy(x: -bounds.minX * scale, y: -bounds.minY * scale)
                    c.scaleBy(x: mirrored ? -scale : scale, y: scale * heightScale)
                    c.opacity = opacity
                    drawWater(in: c, time: timeline.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .frame(width: bounds.width * scale, height: bounds.height * scale)
        .onGeometryChange(for: Bool.self) { geometry in
            let r = geometry.frame(in: .named("adventure.map.viewport"))
            return r.maxY > 0 && r.minY < viewportHeight && r.maxX > 0
        } action: { visible = $0 }
        .allowsHitTesting(false).accessibilityHidden(true)
    }

    private func drawWater(in context: GraphicsContext, time: TimeInterval) {
        var water = context
        water.clip(to: JungleWaterfallGeometry.curtain)
        // Marks travel toward the pool. Dash phases run back up a scaled iPad canvas.
        for (i, stream) in JungleWaterfallGeometry.streams.enumerated() {
            DownstreamFlow.marks(stream, metrics: JungleWaterfallGeometry.streamMetrics[i], in: water,
                                 shading: .color(Color(dinoHex: i.isMultiple(of: 3) ? 0x2EAACD : 0xF3FFFD).opacity(i.isMultiple(of: 3) ? 0.35 : 0.82)),
                                 width: i.isMultiple(of: 2) ? 2.2 : 1.2,
                                 time: time + Double(i) * 0.15,
                                 pointsPerSecond: i.isMultiple(of: 2) ? 86 : 108, dash: 18, gap: 34)
        }
        if mirrored {
            var source = Path()
            source.move(to: CGPoint(x: 90, y: -263))
            source.addCurve(to: CGPoint(x: 0, y: -241), control1: CGPoint(x: 56, y: -269), control2: CGPoint(x: 9, y: -268))
            DownstreamFlow.marks(source, in: context, shading: .color(.white.opacity(0.8)),
                                 width: 2, time: time, pointsPerSecond: 34, dash: 8, gap: 14)
        }
        // Rings expand from the landing and fade; a few droplets arc into the pool.
        for i in 0..<3 {
            let progress = CGFloat((time * 0.7 + Double(i) / 3).truncatingRemainder(dividingBy: 1))
            let width = 32 + progress * 104
            let ring = CGRect(x: 1 - width / 2, y: 52 + progress * 22, width: width, height: 8 + progress * 15)
            context.stroke(Path(ellipseIn: ring), with: .color(.white.opacity(Double(1 - progress) * 0.65)), lineWidth: 1.4)
        }
        for i in 0..<8 {
            let progress = CGFloat((time * 1.15 + Double(i) / 8).truncatingRemainder(dividingBy: 1))
            let side: CGFloat = i.isMultiple(of: 2) ? -1 : 1
            let x = side * (8 + progress * CGFloat(22 + i * 2))
            let y = 48 - sin(progress * .pi) * CGFloat(12 + i % 3 * 6) + progress * 10
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2.3, height: 3.8)),
                         with: .color(.white.opacity(Double(1 - progress) * 0.8)))
        }
    }
}

/// Richer artwork is scoped to the first map. Shared scenery in other chapters
/// and the quiet question backgrounds continues to use JunglePainter unchanged.
private struct JungleWorldPainter {
    let context: GraphicsContext
    var scenery: WorldSceneryLayout? = nil

    func scenery(_ item: JungleMapLayout.Item, at point: CGPoint) {
        let simple = JunglePainter(context: context)
        switch item.kind {
        case .tree: tree(at: point, size: item.size, mirror: item.mirrored)
        case .palm: palm(at: point, size: item.size, mirror: item.mirrored)
        case .waterfall: waterfall(at: point, size: item.size, mirror: item.mirrored, heightScale: item.heightScale)
        case .shrub: shrub(at: point, size: item.size)
        case .rocks: rocks(at: point, size: item.size)
        case .fern: simple.fern(at: point, size: item.size, flipped: item.mirrored)
        case .flowers: simple.flowers(at: point, size: item.size)
        case .plant: plant(at: point, size: item.size, mirror: item.mirrored)
        case .grass: simple.grass(at: point, size: item.size * 10, color: Color(dinoHex: 0x7FA34E).opacity(0.55))
        case .mushrooms: mushrooms(at: point, size: item.size, variant: item.variant)
        case .log: fallenLog(at: point, size: item.size, mirror: item.mirrored)
        case .snake, .fallingLeaves: break
        }
    }

    private func layer(at point: CGPoint, size: CGFloat = 1, mirror: Bool = false, draw: (JungleWorldPainter) -> Void) {
        let point = scenery?.position(point) ?? point
        var c = context
        c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: mirror ? -size : size, y: size)
        draw(.init(context: c))
    }

    private func material(_ path: Path, _ colors: [UInt32]) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                startPoint: CGPoint(x: r.minX, y: r.minY),
                                                endPoint: CGPoint(x: r.maxX, y: r.maxY)))
    }

    private func polygon(_ points: [CGPoint], colors: [UInt32]) {
        var path = Path(); path.addLines(points); path.closeSubpath()
        material(path, colors)
    }

    private func stroke(_ points: [CGPoint], color: UInt32, width: CGFloat, opacity: Double = 1) {
        var path = Path(); path.addLines(points)
        context.stroke(path, with: .color(Color(dinoHex: color).opacity(opacity)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func glow(at point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), .clear]),
                                           center: point, startRadius: 0, endRadius: radius))
    }

    func entrance(width: CGFloat, left: CGFloat, right: CGFloat, height: CGFloat, scale: CGFloat) {
        let sun = CGPoint(x: width * 0.72, y: height * 0.25)
        glow(at: sun, radius: 190 * scale, color: 0xFFF8CC, opacity: 0.9)
        glow(at: sun, radius: 52 * scale, color: 0xFFFDE0, opacity: 0.95)
        for (x, y, s) in [(width * 0.22, height * 0.12, CGFloat(1.2)),
                           (width * 0.63, height * 0.07, CGFloat(0.8)),
                           (width * 0.89, height * 0.34, CGFloat(1.05)),
                           (width * 0.12, height * 0.43, CGFloat(0.75))] {
            layer(at: CGPoint(x: x, y: y), size: s * scale) { $0.cloud() }
        }
        let distant = JunglePainter(context: context)
        distant.hill(x: -width * 0.4, y: height * 0.33, width: width, height: 340 * scale,
                     color: Color(dinoHex: 0x7BBDBB).opacity(0.3))
        distant.hill(x: width * 0.47, y: height * 0.35, width: width * 0.9, height: 320 * scale,
                     color: Color(dinoHex: 0x85C7B8).opacity(0.4))
        // The tall falls begin in the open sky and remain visible beside the sign.
        var rear = context; rear.opacity = 0.58
        JungleWorldPainter(context: rear).waterfall(at: CGPoint(x: left - 3 * scale, y: height * 0.76), size: 0.62 * scale)
        waterfall(at: CGPoint(x: right - 34 * scale, y: height * 0.65), size: 0.87 * scale)
        // Keep the entrance clearing open; translucent shrub rows formed a
        // blurry band behind Dino instead of readable distant scenery.
        glow(at: CGPoint(x: width * 0.5, y: height + 60), radius: width * 0.62, color: 0xF6FFD0, opacity: 0.55)
        context.drawLayer { rays in
            rays.addFilter(.blur(radius: 7))
            for i in 0..<3 {
                let x = sun.x + CGFloat(i - 1) * 24
                var ray = Path()
                ray.addLines([CGPoint(x: x, y: sun.y), CGPoint(x: x + 10, y: sun.y),
                              CGPoint(x: x - 115, y: height + 290), CGPoint(x: x - 180, y: height + 290)])
                ray.closeSubpath()
                rays.fill(ray, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFFDDE).opacity(0.24), .clear]),
                                                     startPoint: sun, endPoint: CGPoint(x: x - 140, y: height + 290)))
            }
        }
        entranceCanopy(width: width, scale: scale)
    }

    func overscrollClouds(width: CGFloat, scale: CGFloat) {
        for (x, y, s) in [(width * 0.18, CGFloat(-150), CGFloat(0.85)),
                           (width * 0.75, -360, 1.1), (width * 0.38, -620, 0.75)] {
            layer(at: CGPoint(x: x, y: y), size: s * scale) { $0.cloud() }
        }
    }

    func entranceCanopy(width: CGFloat, scale: CGFloat) {
        for side in 0..<2 {
            layer(at: CGPoint(x: side == 0 ? -12 : width + 12, y: 25), size: scale, mirror: side == 1) { p in
                p.crown(at: .zero, size: 0.78)
                p.liana(from: CGPoint(x: 26, y: -25), length: 165, bend: 18)
                p.blade(at: CGPoint(x: 3, y: 55), length: 65, width: 22, angle: 129, light: true)
            }
        }
    }

    private func cloud() {
        var shape = Path()
        for (x, y, w, h): (CGFloat, CGFloat, CGFloat, CGFloat) in [(-62, 1, 72, 23), (-39, -15, 51, 41), (-5, -22, 61, 48), (35, -4, 56, 29)] {
            shape.addEllipse(in: CGRect(x: x, y: y, width: w, height: h))
        }
        context.drawLayer { c in
            c.addFilter(.blur(radius: 2.5))
            c.fill(shape, with: .linearGradient(Gradient(colors: [.white.opacity(0.95), Color(dinoHex: 0xEFFBF3).opacity(0.68), .white.opacity(0)]),
                                               startPoint: CGPoint(x: 0, y: -23), endPoint: CGPoint(x: 0, y: 30)))
        }
    }

    private func blade(at point: CGPoint, length: CGFloat, width: CGFloat, angle: Double, light: Bool) {
        var c = context; c.translateBy(x: point.x, y: point.y); c.rotate(by: .degrees(angle))
        let tip = CGPoint(x: length * 0.12, y: -length)
        let leaf = Path { p in
            p.move(to: .zero)
            p.addCurve(to: tip, control1: CGPoint(x: -width, y: -length * 0.21), control2: CGPoint(x: -width * 0.85, y: -length * 0.81))
            p.addCurve(to: .zero, control1: CGPoint(x: width * 0.92, y: -length * 0.81), control2: CGPoint(x: width * 0.72, y: -length * 0.18))
        }
        var shadow = c; shadow.translateBy(x: 1.3, y: 2)
        shadow.fill(leaf, with: .color(Color(dinoHex: 0x134E35).opacity(0.22)))
        c.fill(leaf, with: .linearGradient(Gradient(colors: (light ? [0xD5EB59, 0x81B93F, 0x30763B] : [0x80B847, 0x398847, 0x175D3E]).map { Color(dinoHex: $0) }),
                                          startPoint: CGPoint(x: -width * 0.6, y: -length * 0.8), endPoint: CGPoint(x: width * 0.7, y: 0)))
        let fold = Path { p in
            p.move(to: .zero); p.addLine(to: tip)
            p.addQuadCurve(to: CGPoint(x: -width * 0.6, y: -length * 0.49), control: CGPoint(x: -width * 0.8, y: -length * 0.65)); p.closeSubpath()
        }
        c.fill(fold, with: .color(Color(dinoHex: 0xEDFA9D).opacity(light ? 0.21 : 0.1)))
        var veins = Path(); veins.move(to: .zero); veins.addLine(to: CGPoint(x: tip.x * 0.96, y: tip.y * 0.94))
        for i in 1...3 {
            let t = CGFloat(i) / 5
            let y = -length * t
            veins.move(to: CGPoint(x: tip.x * t, y: y))
            veins.addQuadCurve(to: CGPoint(x: -width * 0.55, y: y - length * 0.14), control: CGPoint(x: -width * 0.45, y: y - length * 0.03))
            veins.move(to: CGPoint(x: tip.x * t, y: y))
            veins.addQuadCurve(to: CGPoint(x: width * 0.5, y: y - length * 0.12), control: CGPoint(x: width * 0.4, y: y - length * 0.02))
        }
        c.stroke(veins, with: .color(Color(dinoHex: 0xD9ED88).opacity(0.35)), style: StrokeStyle(lineWidth: 0.65, lineCap: .round))
    }

    private func crown(at point: CGPoint, size: CGFloat) {
        layer(at: point, size: size) { p in
            let backing = JunglePainter(context: p.context).foliagePath(in: CGRect(x: -72, y: -42, width: 153, height: 94))
            p.material(backing, [0x639F44, 0x236B40, 0x15573B])
            let leaves: [(CGFloat, CGFloat, CGFloat, CGFloat, Double)] = [
                (-14, 0, 68, 25, -78), (-8, -3, 65, 24, -46), (1, -4, 60, 23, -11),
                (12, 0, 72, 26, 32), (24, 5, 66, 23, 68), (29, 8, 63, 24, 108),
                (-29, 11, 62, 23, -112), (-18, 15, 57, 23, -153),
                (4, 15, 62, 24, 167), (21, 15, 56, 23, 135),
                (-25, -2, 46, 21, -49), (15, -5, 49, 22, 46)
            ]
            for (i, leaf) in leaves.enumerated() {
                p.blade(at: CGPoint(x: leaf.0, y: leaf.1), length: leaf.2, width: leaf.3, angle: leaf.4, light: i % 3 != 0)
            }
        }
    }

    func shrub(at point: CGPoint, size: CGFloat) {
        layer(at: point, size: size) { p in
            p.crown(at: CGPoint(x: -24, y: -7), size: 0.60)
            p.crown(at: CGPoint(x: 27, y: -15), size: 0.66)
            p.crown(at: CGPoint(x: 0, y: 5), size: 0.57)
        }
    }

    func plant(at point: CGPoint, size: CGFloat, mirror: Bool) {
        layer(at: point, size: size, mirror: mirror) { p in
            for (i, angle) in [-63.0, -29, 5, 38, 70].enumerated() {
                p.blade(at: CGPoint(x: CGFloat(i - 2) * 3, y: 0),
                        length: i == 2 ? 87 : 59 + CGFloat(i % 2) * 12,
                        width: i == 2 ? 19 : 16, angle: angle, light: i % 2 == 0)
            }
        }
    }

    private func mushrooms(at point: CGPoint, size: CGFloat, variant: Int) {
        layer(at: point, size: size) { p in
            for (x, y, s) in [(CGFloat(-18), CGFloat(0), CGFloat(0.85)), (12, 3, 1.1), (35, 8, 0.62)] {
                p.layer(at: CGPoint(x: x, y: y), size: s) { m in
                    m.material(Path(roundedRect: CGRect(x: -3, y: -24, width: 6, height: 25), cornerRadius: 2), [0xFFF0CD, 0xC5B783])
                    let cap = Path { c in
                        c.move(to: CGPoint(x: -15, y: -22))
                        c.addQuadCurve(to: CGPoint(x: 15, y: -22), control: CGPoint(x: 0, y: -55))
                        c.addQuadCurve(to: CGPoint(x: -15, y: -22), control: CGPoint(x: 0, y: -14))
                        c.closeSubpath()
                    }
                    m.material(cap, variant == 1 ? [0xEBCB89, 0xB28A57] : [0xEAC18B, 0xBB8059])
                    for (dx, dy) in [(CGFloat(-6), CGFloat(-27)), (3, -31), (8, -25)] {
                        m.context.fill(Path(ellipseIn: CGRect(x: dx, y: dy, width: 3, height: 2.2)), with: .color(Color(dinoHex: 0xFFF1CD).opacity(0.85)))
                    }
                }
            }
        }
    }

    private func fallenLog(at point: CGPoint, size: CGFloat, mirror: Bool) {
        layer(at: point, size: size, mirror: mirror) { p in
            p.context.fill(Path(ellipseIn: CGRect(x: -62, y: 9, width: 128, height: 17)), with: .color(Color(dinoHex: 0x54723E).opacity(0.17)))
            let trunk = Path { t in
                t.move(to: CGPoint(x: -54, y: -14))
                t.addQuadCurve(to: CGPoint(x: 51, y: -10), control: CGPoint(x: -6, y: -16))
                t.addQuadCurve(to: CGPoint(x: 51, y: 24), control: CGPoint(x: 65, y: 7))
                t.addQuadCurve(to: CGPoint(x: -54, y: 18), control: CGPoint(x: -8, y: 22))
                t.addQuadCurve(to: CGPoint(x: -54, y: -14), control: CGPoint(x: -67, y: 2))
                t.closeSubpath()
            }
            p.material(trunk, [0xCDA368, 0x9A744A, 0x745635])
            p.context.stroke(trunk, with: .color(Color(dinoHex: 0x755635)), style: StrokeStyle(lineWidth: 1.3, lineJoin: .round))
            // Only the road-facing cut is visible; the far end recedes into a bush.
            var bark = p.context
            bark.clip(to: trunk)
            for i in 0..<4 {
                var grain = Path()
                grain.addLines([CGPoint(x: -43, y: -7 + CGFloat(i) * 6), CGPoint(x: -12, y: -3 + CGFloat(i) * 6), CGPoint(x: 40, y: -5 + CGFloat(i) * 7)])
                bark.stroke(grain, with: .color(Color(dinoHex: i % 2 == 0 ? 0xE2BB7F : 0x634A31).opacity(0.65)),
                            style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
            }
            let end = Path(ellipseIn: CGRect(x: 39, y: -10, width: 25, height: 34))
            p.material(end, [0xE8CF95, 0xBC985F])
            p.context.stroke(end, with: .color(Color(dinoHex: 0x775B37)), lineWidth: 1.4)
            for i in 0..<3 {
                p.context.stroke(Path(ellipseIn: CGRect(x: 43 + CGFloat(i) * 2.7, y: -5 + CGFloat(i) * 4,
                                                       width: 17 - CGFloat(i) * 5.4, height: 24 - CGFloat(i) * 8)),
                                 with: .color(Color(dinoHex: 0x9B7847).opacity(0.65)), lineWidth: 0.8)
            }
            for (i, x) in [CGFloat(-33), -18, -2].enumerated() {
                p.blade(at: CGPoint(x: x, y: -8), length: 21, width: 7, angle: Double(i * 47 - 57), light: true)
            }
        }
    }

    func tree(at point: CGPoint, size: CGFloat, mirror: Bool) {
        layer(at: point, size: size, mirror: mirror) { p in
            p.glow(at: CGPoint(x: 12, y: -4), radius: 60, color: 0x4B753C, opacity: 0.17)
            let trunk = Path { t in
                t.move(to: CGPoint(x: -37, y: 7))
                t.addCurve(to: CGPoint(x: 11, y: -220), control1: CGPoint(x: -6, y: -64), control2: CGPoint(x: -9, y: -168))
                t.addLine(to: CGPoint(x: 35, y: -219))
                t.addCurve(to: CGPoint(x: 41, y: 9), control1: CGPoint(x: 14, y: -130), control2: CGPoint(x: 19, y: -29))
                t.addQuadCurve(to: CGPoint(x: 7, y: -10), control: CGPoint(x: 17, y: 6))
                t.addQuadCurve(to: CGPoint(x: -37, y: 7), control: CGPoint(x: -12, y: -4)); t.closeSubpath()
            }
            p.material(trunk, [0xE2B96A, 0xB08549, 0x755632])
            var clipped = p.context; clipped.clip(to: trunk)
            for i in 0..<7 {
                let x = CGFloat(i) * 9 - 22
                var grain = Path(); grain.move(to: CGPoint(x: x, y: 9))
                grain.addCurve(to: CGPoint(x: x + 26, y: -229), control1: CGPoint(x: x + 10, y: -80), control2: CGPoint(x: x + 3, y: -152))
                clipped.stroke(grain, with: .color(Color(dinoHex: i % 2 == 0 ? 0xF4CD80 : 0x694A2C).opacity(0.36)),
                               style: StrokeStyle(lineWidth: i % 2 == 0 ? 3 : 1.4, lineCap: .round))
            }
            for side: CGFloat in [-1, 1] {
                var branch = Path(); branch.move(to: CGPoint(x: 14, y: -135))
                branch.addQuadCurve(to: CGPoint(x: 20 + side * 61, y: -248), control: CGPoint(x: 25 + side * 40, y: -185))
                p.context.stroke(branch, with: .color(Color(dinoHex: 0x9B733E)), style: StrokeStyle(lineWidth: 13, lineCap: .round))
                p.context.stroke(branch.offsetBy(dx: -3, dy: 0), with: .color(Color(dinoHex: 0xD8AB62)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            p.crown(at: CGPoint(x: -24, y: -244), size: 0.83)
            p.crown(at: CGPoint(x: 67, y: -253), size: 0.82)
            p.crown(at: CGPoint(x: 21, y: -276), size: 0.96)
            p.crown(at: CGPoint(x: 18, y: -219), size: 0.70)
            // A heavy looping liana wraps around the trunk before hanging down.
            var loop = Path(); loop.move(to: CGPoint(x: -39, y: -214))
            loop.addCurve(to: CGPoint(x: 69, y: -209), control1: CGPoint(x: -37, y: -112), control2: CGPoint(x: 67, y: -118))
            p.context.stroke(loop, with: .color(Color(dinoHex: 0x205E3C)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            p.context.stroke(loop.offsetBy(dx: -1, dy: -1), with: .color(Color(dinoHex: 0x7B9B47)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            p.liana(from: CGPoint(x: 55, y: -233), length: 144, bend: 20)
            p.shrub(at: CGPoint(x: -4, y: 14), size: 0.47)
        }
    }

    private func liana(from point: CGPoint, length: CGFloat, bend: CGFloat) {
        func onVine(_ t: CGFloat) -> CGPoint {
            CGPoint(x: point.x + sin(t * .pi * 1.45) * bend, y: point.y + t * length)
        }
        var vine = Path(); vine.addLines((0...20).map { onVine(CGFloat($0) / 20) })
        context.stroke(vine, with: .color(Color(dinoHex: 0x316C46)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        context.stroke(vine.offsetBy(dx: -0.8, dy: 0), with: .color(Color(dinoHex: 0x9AB962).opacity(0.55)), lineWidth: 0.8)
        for i in 1...5 {
            blade(at: onVine(CGFloat(i) / 6), length: 20, width: 8, angle: i % 2 == 0 ? 64 : -66, light: i % 2 == 0)
        }
    }

    func palm(at point: CGPoint, size: CGFloat, mirror: Bool) {
        layer(at: point, size: size, mirror: mirror) { p in
            let top = CGPoint(x: 30, y: -176)
            var stem = Path(); stem.move(to: .zero)
            stem.addQuadCurve(to: top, control: CGPoint(x: -9, y: -117))
            p.context.stroke(stem, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xE5BE78), Color(dinoHex: 0x987241), Color(dinoHex: 0x75562F)]),
                                                       startPoint: CGPoint(x: -8, y: -85), endPoint: CGPoint(x: 13, y: -80)),
                             style: StrokeStyle(lineWidth: 15, lineCap: .round))
            for i in 1..<9 {
                let t = CGFloat(i) / 10
                let x = -18 * t * (1 - t) + 30 * t * t
                let y = -234 * t * (1 - t) - 176 * t * t
                p.stroke([CGPoint(x: x - 5, y: y), CGPoint(x: x, y: y + 3), CGPoint(x: x + 6, y: y + 1)],
                         color: 0x684D2E, width: 1.2, opacity: 0.5)
                p.stroke([CGPoint(x: x - 5, y: y - 2), CGPoint(x: x, y: y + 1)], color: 0xF6CF85, width: 1, opacity: 0.7)
            }
            for (i, angle) in [-108.0, 112, -74, 76, -41, 39, -8].enumerated() {
                p.blade(at: top, length: i < 2 ? 111 : 94, width: 28, angle: angle, light: i % 3 != 0)
            }
            p.rock(at: CGPoint(x: -12, y: 4), size: 0.4)
        }
    }

    private func rock(at point: CGPoint, size: CGFloat) {
        layer(at: point, size: size) { p in
            let pts: [CGPoint] = [.init(x: -31, y: 7), .init(x: -25, y: -20), .init(x: -8, y: -36),
                                  .init(x: 16, y: -33), .init(x: 35, y: -12), .init(x: 29, y: 11), .init(x: 0, y: 17)]
            p.polygon(pts, colors: [0xE3DAB4, 0xAEA98B, 0x7C8B75])
            p.polygon([pts[1], pts[2], pts[3], .init(x: 9, y: -14), .init(x: -7, y: -9)], colors: [0xF2E6BE, 0xC6BE99])
            p.polygon([pts[3], pts[4], pts[5], .init(x: 5, y: 13), .init(x: 9, y: -14)], colors: [0xA8A78C, 0x728573])
            p.stroke([.init(x: -14, y: -13), .init(x: -7, y: -9), .init(x: -10, y: 3)], color: 0x78846D, width: 0.9, opacity: 0.4)
            p.blade(at: CGPoint(x: -21, y: -13), length: 17, width: 6, angle: -75, light: true)
            p.blade(at: CGPoint(x: -18, y: -15), length: 19, width: 7, angle: 35, light: true)
        }
    }

    func rocks(at point: CGPoint, size: CGFloat) {
        layer(at: point, size: size) { p in
            p.rock(at: CGPoint(x: -28, y: -3), size: 0.66)
            p.rock(at: CGPoint(x: 10, y: -5), size: 1)
            p.rock(at: CGPoint(x: 44, y: 5), size: 0.44)
        }
    }

    func waterfall(at point: CGPoint, size: CGFloat, mirror: Bool = false, heightScale: CGFloat = 1) {
        layer(at: point, size: size, mirror: mirror) { original in
            var compressed = original.context
            compressed.scaleBy(x: 1, y: heightScale)
            let p = JungleWorldPainter(context: compressed)
            let pool = Path(ellipseIn: CGRect(x: -106, y: 26, width: 230, height: 87))
            p.material(pool, [0x74CFD3, 0x32A9C0, 0xB2E4D7])
            p.context.stroke(pool, with: .color(Color(dinoHex: 0xDBF2CC).opacity(0.8)), lineWidth: 4)
            let cliff = Path { c in
                c.move(to: CGPoint(x: -83, y: 54))
                c.addLines([.init(x: -76, y: -31), .init(x: -58, y: -62), .init(x: -66, y: -164),
                            .init(x: -42, y: -238), .init(x: -18, y: -264), .init(x: 27, y: -258),
                            .init(x: 45, y: -215), .init(x: 75, y: -204), .init(x: 83, y: -140),
                            .init(x: 112, y: -109), .init(x: 105, y: 52)])
                c.closeSubpath()
            }
            p.material(cliff, [0xD1D0A8, 0x8DA89D, 0x668F89])
            p.polygon([.init(x: -42, y: -238), .init(x: -18, y: -264), .init(x: -6, y: -206),
                       .init(x: -26, y: -110), .init(x: -24, y: 45), .init(x: -61, y: 54)], colors: [0xEEE2B9, 0xB0B9A0, 0x8DAA98])
            p.polygon([.init(x: 27, y: -258), .init(x: 45, y: -215), .init(x: 75, y: -204),
                       .init(x: 68, y: -98), .init(x: 90, y: -39), .init(x: 79, y: 54), .init(x: 18, y: 47)],
                      colors: [0x9FB3A4, 0x597F7C, 0x779A88])
            p.polygon([.init(x: 75, y: -204), .init(x: 83, y: -140), .init(x: 112, y: -109),
                       .init(x: 105, y: 52), .init(x: 79, y: 54), .init(x: 86, y: -120)], colors: [0xD3D0AA, 0x8DA28D])
            for i in 0..<6 {
                let y = -191 + CGFloat(i) * 39
                p.stroke([.init(x: 43, y: y), .init(x: 57, y: y + 9), .init(x: 75, y: y + 4)], color: 0x486D69, width: 1.1, opacity: 0.35)
                p.stroke([.init(x: -58, y: y + 18), .init(x: -43, y: y + 23), .init(x: -30, y: y + 17)], color: 0xF3EAC7, width: 1.3, opacity: 0.4)
            }
            for (x, y, s) in [(CGFloat(-9), CGFloat(-255), CGFloat(0.43)), (63, -201, 0.32), (-55, -65, 0.28), (93, -106, 0.32)] {
                p.shrub(at: CGPoint(x: x, y: y), size: s)
            }
            // The upper stream spills over a broad lip, then fans into a second cascade.
            var source = Path()
            source.move(to: CGPoint(x: mirror ? 90 : 29, y: mirror ? -263 : -257))
            source.addCurve(to: CGPoint(x: 0, y: -241),
                            control1: CGPoint(x: mirror ? 56 : 16, y: mirror ? -269 : -264),
                            control2: CGPoint(x: 9, y: -268))
            p.context.stroke(source, with: .color(Color(dinoHex: 0xB8F2ED)), style: StrokeStyle(lineWidth: 15, lineCap: .round))
            let fall = JungleWaterfallGeometry.curtain
            p.material(fall, [0xE1FFF7, 0x5CD1ED, 0x83DEF0, 0xD4FFF3])
            var water = p.context; water.clip(to: fall)
            for i in 0..<9 {
                let x = CGFloat(i) * 5 - 21
                var stream = Path(); stream.move(to: CGPoint(x: x, y: -248 + CGFloat(i % 3) * 21))
                stream.addCurve(to: CGPoint(x: x * 1.6, y: 54), control1: CGPoint(x: x + 9, y: -137), control2: CGPoint(x: x - 10, y: -27))
                water.stroke(stream, with: .color(Color(dinoHex: i % 3 == 0 ? 0x2DA9CF : 0xF2FFF9).opacity(i % 3 == 0 ? 0.27 : 0.65)),
                             style: StrokeStyle(lineWidth: i % 2 == 0 ? 2.8 : 1.2, lineCap: .round))
            }
            p.rocks(at: CGPoint(x: -73, y: 65), size: 0.85)
            p.rocks(at: CGPoint(x: 78, y: 70), size: 0.63)
            p.glow(at: CGPoint(x: 0, y: 47), radius: 57, color: 0xEAFFF1, opacity: 0.55)
            for i in 0..<11 {
                let x = CGFloat(i - 5) * 6
                let r = CGRect(x: x - 7, y: 44 + CGFloat(i % 3) * 3, width: 17, height: 6)
                p.context.fill(Path(ellipseIn: r), with: .color(Color(dinoHex: 0xECFFF4).opacity(0.85)))
            }
            for i in 0..<3 {
                var ripple = Path()
                ripple.addArc(center: CGPoint(x: 0, y: 0), radius: CGFloat(27 + i * 17), startAngle: .degrees(14), endAngle: .degrees(167), clockwise: false)
                var c = p.context; c.translateBy(x: 1, y: 64 + CGFloat(i) * 7); c.scaleBy(x: 1, y: 0.24)
                c.stroke(ripple, with: .color(Color(dinoHex: 0xE0FFF0).opacity(0.8)), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
            }
            for i in 0..<8 {
                let x = CGFloat(i % 2 == 0 ? -1 : 1) * CGFloat(12 + i * 4)
                p.context.fill(Path(ellipseIn: CGRect(x: x, y: 33 - CGFloat(i % 4) * 8, width: 2.5, height: 4)), with: .color(.white.opacity(0.7)))
            }
        }
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
    var scenery: WorldSceneryLayout? = nil
    private let dark = Color(dinoHex: 0x2E7356)
    private let green = Color(dinoHex: 0x6FAE52)
    private let light = Color(dinoHex: 0xA4CD68)

    func ellipse(_ rect: CGRect, color: Color) { context.fill(Path(ellipseIn: rect), with: .color(color)) }

    func entrance(width: CGFloat, left: CGFloat, right: CGFloat, height: CGFloat, scale: CGFloat) {
        let sun = CGPoint(x: width * 0.76, y: height * 0.29)
        context.fill(Path(ellipseIn: CGRect(x: sun.x - 160, y: sun.y - 160, width: 320, height: 320)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: 0xFFF8CF).opacity(0.95), Color(dinoHex: 0xFFF8CF).opacity(0)]),
                                           center: sun, startRadius: 15, endRadius: 160))
        ellipse(CGRect(x: sun.x - 24, y: sun.y - 24, width: 48, height: 48), color: Color(dinoHex: 0xFFFBE3).opacity(0.85))
        // Soft, layered cloud banks keep the sky continuous behind the fixed HUD.
        context.drawLayer { cloud in
            cloud.addFilter(.blur(radius: 3))
            for (x, y, s) in [(width * 0.22, height * 0.19, CGFloat(1)),
                              (width * 0.63, height * 0.43, CGFloat(0.78)),
                              (width * 0.08, height * 0.56, CGFloat(0.64))] {
                for i in 0..<4 {
                    let r = CGRect(x: x + CGFloat(i - 2) * 22 * s, y: y - CGFloat(i % 2) * 11 * s,
                                   width: 64 * s, height: 26 * s)
                    cloud.fill(Path(ellipseIn: r), with: .color(.white.opacity(0.52)))
                }
            }
        }
        hill(x: -width * 0.43, y: height * 0.46, width: width * 0.92, height: 280 * scale,
             color: Color(dinoHex: 0x8ABDB0).opacity(0.35))
        hill(x: width * 0.56, y: height * 0.42, width: width * 0.83, height: 330 * scale,
             color: Color(dinoHex: 0x86B9AD).opacity(0.3))
        // Distant falls sit behind the sign; the near fall continues beside level one.
        var distant = context
        distant.opacity = 0.53
        let backdrop = JunglePainter(context: distant)
        backdrop.waterfall(at: CGPoint(x: right - 12 * scale, y: height * 0.82), size: scale * 0.83)
        backdrop.waterfall(at: CGPoint(x: left - 10 * scale, y: height * 0.70), size: scale * 0.58)
        context.drawLayer { light in
            light.addFilter(.blur(radius: 12))
            for i in 0..<3 {
                var ray = Path()
                let x = sun.x + CGFloat(i - 1) * 28
                ray.addLines([CGPoint(x: x, y: sun.y - 10), CGPoint(x: x + 14, y: sun.y),
                              CGPoint(x: x - 70 + CGFloat(i) * 25, y: height + 420),
                              CGPoint(x: x - 165 + CGFloat(i) * 24, y: height + 420)])
                ray.closeSubpath()
                light.fill(ray, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFF9DB).opacity(0.26), Color(dinoHex: 0xFFF9DB).opacity(0)]),
                                                      startPoint: sun, endPoint: CGPoint(x: sun.x - 100, y: height + 420)))
            }
        }
        for side: CGFloat in [-1, 1] {
            let x = side < 0 ? left + 8 : right - 8
            for i in 0..<4 {
                leaf(at: CGPoint(x: x, y: 10 + CGFloat(i) * 42), length: CGFloat(50 - i * 5) * scale,
                     width: 13 * scale, angle: Double(side) * Double(40 + i * 18),
                     color: i.isMultiple(of: 2) ? green : dark)
            }
        }
    }

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
    func foliagePath(in r: CGRect) -> Path {
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
        let point = scenery?.position(point) ?? point
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
        let point = scenery?.position(point) ?? point
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
        let point = scenery?.position(point) ?? point
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
        let point = scenery?.position(point) ?? point
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
        case 1: (accent, distant, shade) = (0x8BBE69, 0xACC992, 0x326C55)
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

/// One set of coordinates for the riverbed, moving water and planted scenery.
private enum SleepValleyLayout {
    struct Willow: Identifiable {
        let id: Int
        let point: CGPoint
        let size: CGFloat
        let mirrored: Bool
        var groundY: CGFloat { id >= 10 ? point.y + 3 * size / 0.62 + 0.01 : point.y }
        var bounds: CGRect {
            CGRect(x: point.x - (mirrored ? 129 : 108) * size, y: point.y - 257 * size,
                   width: 237 * size, height: 278 * size)
        }
    }

    static func garden(_ index: Int, layout: WorldSceneryLayout) -> CGPoint {
        let right = index % 4 == 0 || index % 4 == 3
        let size = layout.scale * 0.88
        return layout.position(CGPoint(x: right ? layout.width - 28 * layout.scale : 28 * layout.scale,
                                       y: 181 + CGFloat(index) * 175), radius: 74 * size, rise: 135 * size)
    }

    static func willows(layout: WorldSceneryLayout) -> [Willow] {
        let s = layout.scale
        var trees = [(CGPoint(x: layout.width + 19, y: 191), s * 1.06, true),
                     (CGPoint(x: -10, y: 635), s * 1.18, false),
                     (CGPoint(x: layout.width + 21, y: 1160), s * 1.10, true),
                     (CGPoint(x: -24, y: 1490), s * 1.08, false)]
            .enumerated().map { index, item in
                Willow(id: index, point: layout.position(item.0), size: item.1, mirrored: item.2)
            }
        for index in [2, 5, 8] {
            let point = garden(index, layout: layout), size = s * 0.88
            trees.append(Willow(id: index + 10, point: CGPoint(x: point.x + 6 * size, y: point.y - 3 * size),
                                 size: size * 0.62, mirrored: false))
        }
        return trees
    }

    static func streamPoint(y: CGFloat, right: Bool, layout: WorldSceneryLayout, offset: CGFloat = 0) -> CGPoint {
        let sign: CGFloat = right ? 1 : -1
        let inset = (135 + sin(y * 0.017 + (right ? 1.4 : 0)) * 7 + offset) * layout.scale
        let x = layout.centerX(at: y) + sign * inset
        let outside = right ? layout.width + 95 * layout.scale : -95 * layout.scale
        let firstY: CGFloat = 80, lastY: CGFloat = right ? 1480 : 1655
        if y >= firstY && y <= lastY { return CGPoint(x: x, y: y) }
        // Join at vertical tangents, so the inlet never doubles back into a cusp.
        let a: CGPoint, b: CGPoint, c: CGPoint, d: CGPoint
        if y < firstY {
            let endX = layout.centerX(at: firstY) + sign * (135 + sin(firstY * 0.017 + (right ? 1.4 : 0)) * 7 + offset) * layout.scale
            a = CGPoint(x: outside, y: -140)
            b = CGPoint(x: outside + (endX - outside) * 0.48, y: -140)
            c = CGPoint(x: endX, y: firstY - 84)
            d = CGPoint(x: endX, y: firstY)
        } else {
            let startX = layout.centerX(at: lastY) + sign * (135 + sin(lastY * 0.017 + (right ? 1.4 : 0)) * 7 + offset) * layout.scale
            let mouthY = max(lastY + 80, layout.height - layout.routeOffset - (right ? 220 : 48))
            a = CGPoint(x: startX, y: lastY)
            b = CGPoint(x: startX, y: lastY + (mouthY - lastY) * 0.48)
            c = CGPoint(x: outside + (startX - outside) * 0.28, y: mouthY)
            d = CGPoint(x: outside, y: mouthY)
        }
        if y <= a.y { return CGPoint(x: a.x, y: y) }
        if y >= d.y { return CGPoint(x: d.x, y: y) }
        func cubic(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat, _ t: CGFloat) -> CGFloat {
            let u = 1 - t
            return u * u * u * a + 3 * u * u * t * b + 3 * u * t * t * c + t * t * t * d
        }
        var low: CGFloat = 0, high: CGFloat = 1
        for _ in 0..<16 {
            let t = (low + high) / 2
            if cubic(a.y, b.y, c.y, d.y, t) < y { low = t } else { high = t }
        }
        return CGPoint(x: cubic(a.x, b.x, c.x, d.x, (low + high) / 2), y: y)
    }

    static func stream(layout: WorldSceneryLayout, right: Bool, start: CGFloat, end: CGFloat, offset: CGFloat = 0) -> Path {
        let count = max(1, Int(ceil((end - start) / 6)))
        return Path { p in
            for i in 0...count {
                let point = streamPoint(y: start + (end - start) * CGFloat(i) / CGFloat(count), right: right, layout: layout, offset: offset)
                if i == 0 { p.move(to: point) } else { p.addLine(to: point) }
            }
        }
    }

    struct Pool {
        let y: CGFloat
        let right: Bool
    }
    static let pools: [Pool] = [.init(y: 305, right: false), .init(y: 605, right: true),
                                .init(y: 980, right: false), .init(y: 1290, right: true), .init(y: 1530, right: false)]

    static func waterWidth(at y: CGFloat, right: Bool) -> CGFloat {
        var widening: CGFloat = 0
        for pool in pools where pool.right == right {
            let d = (y - pool.y) / 76
            widening = max(widening, exp(-d * d) * 0.62)
        }
        return 1 + widening + sin(y * 0.041) * 0.055 + cos(y * 0.073) * 0.025
    }

    /// A normal to the river keeps pads, reeds and ripples on the same shoreline.
    static func waterPoint(y: CGFloat, right: Bool, across: CGFloat, layout: WorldSceneryLayout) -> CGPoint {
        let p = streamPoint(y: y, right: right, layout: layout)
        let slope = (streamPoint(y: y + 1, right: right, layout: layout).x - streamPoint(y: y - 1, right: right, layout: layout).x) / 2
        let offset = across * 27 * layout.scale * waterWidth(at: y, right: right) / sqrt(1 + slope * slope)
        return CGPoint(x: p.x + offset, y: p.y - offset * slope)
    }

    struct WaterLily: Identifiable {
        let id: Int
        let point: CGPoint
        let size: CGFloat
        let flower: Bool
    }

    static func lilies(layout: WorldSceneryLayout) -> [WaterLily] {
        pools.enumerated().flatMap { index, pool in
            (0..<3).map { pad in
                let y = pool.y + CGFloat(pad - 1) * 16
                return WaterLily(id: index * 3 + pad,
                                 point: waterPoint(y: y, right: pool.right, across: CGFloat(pad - 1) * 0.37, layout: layout),
                                 size: layout.scale * (pad == 1 ? 0.85 : 0.61), flower: pad == 1)
            }
        }
    }

    static func riverbank(layout: WorldSceneryLayout, right: Bool, width: CGFloat) -> Path {
        let start = -layout.routeOffset, end = layout.height - layout.routeOffset
        let count = max(1, Int(ceil((end - start) / 6)))
        var points: [CGPoint] = [], opposite: [CGPoint] = []
        for i in 0...count {
            let y = start + (end - start) * CGFloat(i) / CGFloat(count)
            let p = streamPoint(y: y, right: right, layout: layout)
            let slope = (streamPoint(y: y + 1, right: right, layout: layout).x - streamPoint(y: y - 1, right: right, layout: layout).x) / 2
            let radius = width * layout.scale * 0.5 * waterWidth(at: y, right: right)
            let dx = radius / sqrt(1 + slope * slope), dy = -slope * dx
            points.append(CGPoint(x: p.x + dx, y: p.y + dy))
            opposite.append(CGPoint(x: p.x - dx, y: p.y - dy))
        }
        var path = Path(); path.addLines(points + opposite.reversed()); path.closeSubpath()
        return path
    }

    struct Glint: Identifiable {
        let id: Int
        let point: CGPoint
        let depth: CGFloat
    }

    static func crystalGlints(layout: WorldSceneryLayout) -> [Glint] {
        [0, 2, 3, 5, 6, 8].map { index in
            let garden = garden(index, layout: layout), s = layout.scale * 0.88
            let small = index % 3 == 2, crystal: CGFloat = small ? 0.53 : 0.64
            return Glint(id: index,
                         point: CGPoint(x: garden.x + ((small ? 33 : 46) + 6.7 * crystal) * s,
                                        y: garden.y + ((small ? 11 : 12) - 44 * crystal) * s), depth: garden.y)
        }
    }

    struct Cascade: Identifiable {
        let id: Int
        let y: CGFloat
        let right: Bool
        let point: CGPoint

        func localPoint(y: CGFloat, across: CGFloat = 0, layout: WorldSceneryLayout) -> CGPoint {
            let p = waterPoint(y: point.y + y * layout.scale, right: right, across: across, layout: layout)
            return CGPoint(x: (p.x - point.x) / layout.scale, y: (p.y - point.y) / layout.scale)
        }

        func ribbon(from start: CGFloat, to end: CGFloat, layout: WorldSceneryLayout) -> Path {
            let count = max(1, Int(ceil((end - start) / 3)))
            var left: [CGPoint] = [], right: [CGPoint] = []
            for i in 0...count {
                let y = start + (end - start) * CGFloat(i) / CGFloat(count)
                left.append(localPoint(y: y, across: -0.98, layout: layout))
                right.append(localPoint(y: y, across: 0.98, layout: layout))
            }
            var path = Path(); path.addLines(left + right.reversed()); path.closeSubpath()
            return path
        }

        func filament(across: CGFloat, layout: WorldSceneryLayout) -> Path {
            Path { path in
                for i in 0...64 {
                    let y = -105 + CGFloat(i) * 190 / 64
                    let p = localPoint(y: y, across: across, layout: layout)
                    if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
                }
            }
        }

        func bounds(layout: WorldSceneryLayout) -> CGRect {
            var bounds = CGRect.null
            for i in 0...20 {
                let p = localPoint(y: -110 + CGFloat(i) * 10, layout: layout)
                bounds = bounds.union(CGRect(x: p.x - 52, y: p.y - 4, width: 104, height: 8))
            }
            return CGRect(x: point.x + bounds.minX * layout.scale,
                          y: point.y + bounds.minY * layout.scale,
                          width: bounds.width * layout.scale, height: bounds.height * layout.scale)
        }
    }

    static func cascades(layout: WorldSceneryLayout) -> [Cascade] {
        [(CGFloat(390), false), (CGFloat(770), true), (CGFloat(1115), false), (CGFloat(1430), true)]
            .enumerated().map { index, item in
                Cascade(id: index, y: item.0, right: item.1,
                        point: streamPoint(y: item.0, right: item.1, layout: layout))
            }
    }

}

/// The terrain stays cached. Small effect canvases tick only inside the viewport.
private struct SleepValleyLife: View {
    let routeOffset: CGFloat
    let viewportHeight: CGFloat
    var fixedTime: TimeInterval? = nil
    var frozen = false

    var body: some View {
        GeometryReader { geometry in
            let layout = WorldSceneryLayout(width: geometry.size.width, height: geometry.size.height, routeOffset: routeOffset)
            ZStack(alignment: .topLeading) {
                ForEach(0..<Int(ceil(geometry.size.height / 320)), id: \.self) { index in
                    let frame = CGRect(x: 0, y: CGFloat(index) * 320, width: geometry.size.width,
                                       height: min(320, geometry.size.height - CGFloat(index) * 320))
                    SleepValleyLifeSurface(layout: layout, frame: frame, viewportHeight: viewportHeight,
                                           fixedTime: fixedTime, frozen: frozen)
                        .mask(SleepValleyOcclusion(layout: layout, frame: frame, depth: -.infinity))
                        .frame(width: frame.width, height: frame.height).position(x: frame.midX, y: frame.midY)
                }
                ForEach(SleepValleyLayout.willows(layout: layout)) { tree in
                    let frame = tree.bounds.offsetBy(dx: 0, dy: routeOffset)
                    SleepValleyLifeSurface(layout: layout, frame: frame, viewportHeight: viewportHeight,
                                           tree: tree, fixedTime: fixedTime, frozen: frozen)
                        .mask(SleepValleyOcclusion(layout: layout, frame: frame, depth: tree.groundY + routeOffset))
                        .frame(width: frame.width, height: frame.height).position(x: frame.midX, y: frame.midY)
                }
                ForEach(SleepValleyLayout.crystalGlints(layout: layout)) { glint in
                    let frame = CGRect(x: glint.point.x - 15 * layout.scale, y: glint.point.y + routeOffset - 15 * layout.scale,
                                       width: 30 * layout.scale, height: 30 * layout.scale)
                    SleepValleyLifeSurface(layout: layout, frame: frame, viewportHeight: viewportHeight,
                                           glint: glint, fixedTime: fixedTime, frozen: frozen)
                        .mask(SleepValleyOcclusion(layout: layout, frame: frame, depth: glint.depth + routeOffset + 0.01))
                        .frame(width: frame.width, height: frame.height).position(x: frame.midX, y: frame.midY)
                }
                ForEach(SleepValleyLayout.cascades(layout: layout)) { cascade in
                    let frame = cascade.bounds(layout: layout).offsetBy(dx: 0, dy: routeOffset)
                    SleepValleyLifeSurface(layout: layout, frame: frame, viewportHeight: viewportHeight,
                                           cascade: cascade, fixedTime: fixedTime, frozen: frozen)
                        .mask(SleepValleyOcclusion(layout: layout, frame: frame, depth: -.infinity))
                        .frame(width: frame.width, height: frame.height).position(x: frame.midX, y: frame.midY)
                }
            }
        }.clipped().allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct SleepValleyOcclusion: View {
    let layout: WorldSceneryLayout
    let frame: CGRect
    let depth: CGFloat
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
            var c = context
            c.translateBy(x: -frame.minX, y: layout.routeOffset - frame.minY)
            c.blendMode = .destinationOut
            let scene = WorldSceneryDepth(minimumDepth: depth, visibleBounds: frame)
            SleepValleyPainter(context: c, depth: scene, depthOffset: layout.routeOffset).appendScenery(layout: layout)
            let boss = CGPoint(x: layout.width - 79 * layout.scale, y: 1675)
            if boss.y + layout.routeOffset > depth {
                WorldBossPainter(context: c).draw(worldID: 2, at: boss, size: layout.scale * 0.88)
            }
            scene.draw()
            var road = Path()
            let start = frame.minY - layout.routeOffset - 10
            for i in 0...Int(ceil((frame.height + 20) / 6)) {
                let y = start + CGFloat(i) * 6
                let point = CGPoint(x: layout.centerX(at: y), y: y)
                if i == 0 { road.move(to: point) } else { road.addLine(to: point) }
            }
            c.stroke(road, with: .color(.white), style: StrokeStyle(lineWidth: 100, lineCap: .round, lineJoin: .round))
        }
    }
}

private struct SleepValleyLifeSurface: View {
    let layout: WorldSceneryLayout
    let frame: CGRect
    let viewportHeight: CGFloat
    var tree: SleepValleyLayout.Willow? = nil
    var cascade: SleepValleyLayout.Cascade? = nil
    var glint: SleepValleyLayout.Glint? = nil
    var fixedTime: TimeInterval? = nil
    var frozen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false

    var body: some View {
        // Build river geometry outside the timeline; frames only move its highlights.
        let isWater = tree == nil && cascade == nil && glint == nil
        let paths = isWater ? [false, true].map {
            SleepValleyLayout.stream(layout: layout, right: $0, start: -layout.routeOffset,
                                    end: layout.height - layout.routeOffset)
        } : []
        let banks = isWater ? [false, true].map {
            SleepValleyLayout.riverbank(layout: layout, right: $0, width: 54)
        } : []
        TimelineView(.animation(minimumInterval: 1.0 / 20,
                                paused: fixedTime != nil || frozen || reduceMotion || !visible || scenePhase != .active)) { timeline in
            Canvas { context, _ in
                let time = frozen || reduceMotion ? 0 : (fixedTime ?? timeline.date.timeIntervalSinceReferenceDate)
                var c = context; c.translateBy(x: -frame.minX, y: layout.routeOffset - frame.minY)
                if let tree {
                    c.translateBy(x: tree.point.x, y: tree.point.y)
                    c.scaleBy(x: tree.mirrored ? -tree.size : tree.size, y: tree.size)
                    SleepValleyPainter(context: c).willowCanopy(variation: tree.id >= 10 ? tree.id - 10 : tree.id, time: time)
                } else if let glint {
                    SleepValleyEffects(context: c, time: time).crystal(glint, scale: layout.scale)
                } else if let cascade {
                    c.translateBy(x: cascade.point.x, y: cascade.point.y); c.scaleBy(x: layout.scale, y: layout.scale)
                    SleepValleyEffects(context: c, time: time).waterfall(cascade, layout: layout)
                } else {
                    SleepValleyEffects(context: c, time: time).river(paths: paths, banks: banks, layout: layout)
                    SleepValleyEffects(context: c, time: time).valleyMist(layout: layout, frame: frame)
                    SleepValleyEffects(context: c, time: time).fireflies(layout: layout, frame: frame)
                }
            }
        }
        .onGeometryChange(for: Bool.self) { geometry in
            let rect = geometry.frame(in: .named("adventure.map.viewport"))
            return rect.maxY > 0 && rect.minY < viewportHeight
        } action: { visible = $0 }
    }
}

private struct SleepValleyEffects {
    let context: GraphicsContext
    let time: TimeInterval

    private func glow(_ point: CGPoint, radius: CGFloat, opacity: Double, color: UInt32 = 0xFFE7A4) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), .clear]),
                                           center: point, startRadius: 0, endRadius: radius))
    }

    private func star(_ point: CGPoint, radius: CGFloat, opacity: Double) {
        glow(point, radius: radius * 4, opacity: opacity * 0.22)
        var p = Path()
        p.addLines([CGPoint(x: point.x, y: point.y - radius * 1.5), CGPoint(x: point.x + radius * 0.23, y: point.y - radius * 0.23),
                    CGPoint(x: point.x + radius, y: point.y), CGPoint(x: point.x + radius * 0.23, y: point.y + radius * 0.23),
                    CGPoint(x: point.x, y: point.y + radius * 1.5), CGPoint(x: point.x - radius * 0.23, y: point.y + radius * 0.23),
                    CGPoint(x: point.x - radius, y: point.y), CGPoint(x: point.x - radius * 0.23, y: point.y - radius * 0.23)])
        p.closeSubpath(); context.fill(p, with: .color(Color(dinoHex: 0xFFF8D3).opacity(opacity)))
    }

    func river(paths: [Path], banks: [Path], layout: WorldSceneryLayout) {
        let scale = layout.scale
        for (index, path) in paths.enumerated() {
            var c = context
            c.clip(to: banks[index])
            for strand in 0..<4 {
                DownstreamFlow.marks(path.offsetBy(dx: CGFloat(strand - 2) * 7 * scale, dy: 0), in: c,
                                     shading: .color(Color(dinoHex: strand.isMultiple(of: 2) ? 0xD3E9E6 : 0x7ABFCB).opacity(0.23)),
                                     width: (strand == 0 ? 2 : 0.8) * scale,
                                     time: time + Double(index * 21 + strand * 17) / (10 + Double(strand) * 2),
                                     pointsPerSecond: 10 + Double(strand) * 2,
                                     dash: 13 * scale, gap: 97 * scale)
            }
            for pool in SleepValleyLayout.pools where pool.right == (index == 1) {
                let point = SleepValleyLayout.streamPoint(y: pool.y + 9, right: pool.right, layout: layout)
                for ring in 0..<3 {
                    let u = (time / 7.5 + Double(ring) / 3 + Double(index) * 0.37).truncatingRemainder(dividingBy: 1)
                    let width = (15 + CGFloat(u) * 58) * scale
                    let rect = CGRect(x: point.x - width / 2, y: point.y - width * 0.105,
                                      width: width, height: width * 0.21)
                    c.stroke(Path(ellipseIn: rect), with: .color(Color(dinoHex: 0xDCEBE0).opacity((1 - u) * 0.27)),
                             style: StrokeStyle(lineWidth: 0.65 * scale, lineCap: .round, dash: [width * 0.4, width * 0.13]))
                }
            }
        }
    }

    func valleyMist(layout: WorldSceneryLayout, frame: CGRect) {
        for i in 0..<6 {
            let y = CGFloat(i) * 309 + 100 + CGFloat(sin(time * 0.07 + Double(i))) * 5
            guard y + layout.routeOffset + 42 > frame.minY && y + layout.routeOffset - 42 < frame.maxY else { continue }
            var mist = context
            let x = layout.width * (i.isMultiple(of: 2) ? 0.25 : 0.75) + CGFloat(sin(time * 0.05 + Double(i) * 1.7)) * 14
            mist.translateBy(x: x, y: y); mist.scaleBy(x: 1, y: 0.12)
            let radius = min(320, layout.width * 0.66)
            mist.fill(Path(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2)),
                      with: .radialGradient(Gradient(colors: [Color(dinoHex: 0xE1E5EE).opacity(0.11), .clear]),
                                            center: .zero, startRadius: 0, endRadius: radius))
        }
    }

    func waterfall(_ cascade: SleepValleyLayout.Cascade, layout: WorldSceneryLayout) {
        var water = context
        water.clip(to: cascade.ribbon(from: -105, to: 85, layout: layout))
        let shimmer = Gradient(stops: [
            .init(color: Color(dinoHex: 0xE6F5EB).opacity(0), location: 0),
            .init(color: Color(dinoHex: 0xE6F5EB).opacity(0.38), location: 0.20),
            .init(color: Color(dinoHex: 0xF2FAEE).opacity(0.67), location: 0.46),
            .init(color: Color(dinoHex: 0xDAF1E7).opacity(0.30), location: 0.78),
            .init(color: Color(dinoHex: 0xDAF1E7).opacity(0), location: 1)
        ])
        for i in 0..<8 {
            let filament = cascade.filament(across: CGFloat(i) * 0.22 - 0.77, layout: layout)
            DownstreamFlow.marks(filament, in: water,
                                 shading: .linearGradient(shimmer, startPoint: cascade.localPoint(y: -105, layout: layout),
                                                          endPoint: cascade.localPoint(y: 85, layout: layout)),
                                 width: i.isMultiple(of: 2) ? 1.6 : 0.8,
                                 time: time + Double(i * 7) / (i.isMultiple(of: 2) ? 24 : 31),
                                 pointsPerSecond: i.isMultiple(of: 2) ? 24 : 31, dash: 16, gap: 27)
        }
        for i in 0..<3 {
            let progress = (time / 4.3 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
            let q = cascade.localPoint(y: 12 + CGFloat(progress) * 38, layout: layout)
            let width = 21 + 24 * progress
            let rect = CGRect(x: q.x - width / 2, y: q.y - 2, width: width, height: 5 + 5 * progress)
            water.stroke(Path(ellipseIn: rect), with: .color(Color(dinoHex: 0xECF6E9).opacity((1 - progress) * 0.30)),
                         style: StrokeStyle(lineWidth: 0.65, lineCap: .round, dash: [width * 0.45, width * 0.2]))
        }
    }

    func crystal(_ glint: SleepValleyLayout.Glint, scale: CGFloat) {
        let pulse = pow(max(0, sin(time * 0.72 + Double(glint.id) * 2.17)), 8)
        var c = context; c.translateBy(x: glint.point.x, y: glint.point.y)
        c.rotate(by: .degrees(sin(time * 0.27 + Double(glint.id)) * 18))
        SleepValleyEffects(context: c, time: time).star(.zero, radius: (1.2 + pulse * 3.1) * scale, opacity: 0.14 + pulse * 0.8)
    }

    func fireflies(layout: WorldSceneryLayout, frame: CGRect) {
        let s = layout.scale
        for i in 0..<58 {
            let baseY = CGFloat((i * 193 + 37) % 1780) - 130
            guard baseY + layout.routeOffset > frame.minY - 18 && baseY + layout.routeOffset < frame.maxY + 18 else { continue }
            let right = i.isMultiple(of: 2)
            let y = baseY + CGFloat(sin(time * 0.31 + Double(i) * 2.3)) * 5 * s
            let river = SleepValleyLayout.streamPoint(y: y, right: right, layout: layout)
            let x = river.x + CGFloat(sin(time * 0.24 + Double(i) * 1.71)) * 8 * s + CGFloat(i % 5 - 2) * 13 * s
            guard abs(x - layout.centerX(at: y)) > 60 else { continue }
            let pulse = 0.3 + 0.7 * pow((sin(time * (0.65 + Double(i % 4) * 0.12) + Double(i) * 2.1) + 1) / 2, 2)
            let point = CGPoint(x: x, y: y)
            glow(point, radius: (i.isMultiple(of: 4) ? 12 : 7) * s, opacity: pulse * 0.45)
            context.fill(Path(ellipseIn: CGRect(x: x - 0.85 * s, y: y - 0.85 * s, width: 1.7 * s, height: 1.7 * s)),
                         with: .color(Color(dinoHex: 0xFFF6C1).opacity(pulse)))
            if i.isMultiple(of: 5) { star(point, radius: 2.4 * s, opacity: pulse * 0.85) }
        }
        for i in stride(from: 0, to: 35, by: 7) {
            let x = CGFloat((i * 79 + 23) % 397) / 397 * layout.width
            let y = 22 + CGFloat((i * 47) % 210) - layout.routeOffset
            guard y + layout.routeOffset > frame.minY && y + layout.routeOffset < frame.maxY else { continue }
            let moon = CGPoint(x: layout.width - 66 * s, y: 79 * s - layout.routeOffset)
            if hypot(x - moon.x, y - moon.y) < 45 * s { continue }
            let pulse = pow(max(0, sin(time * 0.61 + Double(i) * 1.3)), 4)
            star(CGPoint(x: x, y: y), radius: 2.1 + pulse * 1.2, opacity: pulse * 0.55)
        }
        // Reflections stay on the water, and change independently of the fireflies.
        for i in 0..<32 {
            let y = CGFloat(i * 53 + 59)
            guard y + layout.routeOffset > frame.minY && y + layout.routeOffset < frame.maxY else { continue }
            let p = SleepValleyLayout.streamPoint(y: y, right: i.isMultiple(of: 2), layout: layout, offset: CGFloat(i % 3 - 1) * 8)
            let pulse = pow(max(0, sin(time * 0.9 + Double(i) * 2.41)), 6)
            star(p, radius: (1.7 + pulse * 1.4) * s, opacity: pulse * 0.7)
        }
    }
}

/// Moonlit scenery belongs only to chapter two; the shared theme painter keeps
/// the other chapters and their established palettes intact.
private struct SleepValleyPainter {
    let context: GraphicsContext
    var scenery: WorldSceneryLayout? = nil
    var depth: WorldSceneryDepth? = nil
    var depthOffset: CGFloat = 0
    var animatedWillows = false

    private func at(_ point: CGPoint, size: CGFloat = 1, mirror: Bool = false, radius: CGFloat = 0, rise: CGFloat = 0, draw: @escaping (SleepValleyPainter) -> Void) {
        let point = scenery?.position(point, radius: radius, rise: rise) ?? point
        var c = context; c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: mirror ? -size : size, y: size)
        if let depth {
            let bounds = CGRect(x: point.x - 160 * size, y: depthOffset + point.y - 290 * size,
                                width: 320 * size, height: 340 * size)
            depth.add(at: depthOffset + point.y, bounds: bounds) {
                draw(.init(context: c, animatedWillows: animatedWillows))
            }
        } else { draw(.init(context: c, animatedWillows: animatedWillows)) }
    }
    private func material(_ path: Path, colors: [UInt32]) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
    }
    private func oval(_ r: CGRect, colors: [UInt32]) {
        context.fill(Path(ellipseIn: r), with: .radialGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                            center: CGPoint(x: r.minX + r.width * 0.3, y: r.minY + r.height * 0.2),
                                                            startRadius: 0, endRadius: max(r.width, r.height) * 0.9))
    }
    private func polygon(_ points: [CGPoint], colors: [UInt32]) {
        var p = Path(); p.addLines(points); p.closeSubpath(); material(p, colors: colors)
    }
    private func line(_ points: [CGPoint], color: UInt32, width: CGFloat, opacity: Double = 1) {
        var p = Path(); p.addLines(points)
        context.stroke(p, with: .color(Color(dinoHex: color).opacity(opacity)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func glow(_ point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), Color(dinoHex: color).opacity(0)]),
                                           center: point, startRadius: 0, endRadius: radius))
    }

    func landscape(in size: CGSize, routeOffset: CGFloat, depth: WorldSceneryDepth) {
        let w = size.width, h = size.height
        let left: CGFloat = 0, right = w - left
        let scale = min(1.30, max(0.82, w / 390))
        let skyEnd = (routeOffset + 185) / h
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: 0xCED0E6), location: 0),
            .init(color: Color(dinoHex: 0x697AA4), location: 0.035),
            .init(color: Color(dinoHex: 0x6D83A5), location: skyEnd * 0.55),
            .init(color: Color(dinoHex: 0xAFBFCA), location: skyEnd),
            .init(color: Color(dinoHex: 0xB4C7C4), location: 0.39),
            .init(color: Color(dinoHex: 0xA8BFBB), location: 0.68),
            .init(color: Color(dinoHex: 0xBBC2D2), location: 0.87),
            .init(color: Color(dinoHex: 0xFFD1A1), location: 1)
        ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
        var c = context; c.translateBy(x: 0, y: routeOffset)
        let scenery = WorldSceneryLayout(width: w, height: h, routeOffset: routeOffset)
        scenery.drawBanks(in: c, worldID: 2)
        let p = SleepValleyPainter(context: c, scenery: scenery, depth: depth, depthOffset: routeOffset,
                                   animatedWillows: animatedWillows)
        SleepValleyPainter(context: c).valleyBackdrop(layout: scenery)
        SleepValleyPainter(context: c).riverbeds(layout: scenery)
        // Distant cliffs cover the stream's upper end, so it emerges naturally
        // below the waterfall rather than painting over the cascade.
        sky(width: w, left: left, right: right, height: routeOffset + 150, scale: scale)
        for cascade in SleepValleyLayout.cascades(layout: scenery) {
            SleepValleyPainter(context: c).cascadeWater(cascade, layout: scenery)
        }
        p.appendScenery(layout: scenery)
        // A final bank of lavender mist opens toward the warm next horizon.
        p.mist(at: CGPoint(x: w * 0.48, y: 1715), width: w * 1.15, opacity: 0.14)
    }

    func appendScenery(layout: WorldSceneryLayout) {
        let scale = layout.scale, right = layout.width
        let p = SleepValleyPainter(context: context, scenery: layout, depth: depth, depthOffset: depthOffset,
                                   animatedWillows: animatedWillows)
        let placed = SleepValleyPainter(context: context, depth: depth, depthOffset: depthOffset,
                                        animatedWillows: animatedWillows)
        for lily in SleepValleyLayout.lilies(layout: layout) { placed.waterLily(lily) }
        for right in [false, true] {
            for i in 0..<23 {
                let y = CGFloat(i) * 74 + CGFloat((i * 19) % 27) + 56
                let across: CGFloat = i.isMultiple(of: 4) ? -1.18 : 1.21
                let point = SleepValleyLayout.waterPoint(y: y, right: right, across: across, layout: layout)
                guard abs(point.x - layout.centerX(at: point.y)) > 64 else { continue }
                if i.isMultiple(of: 3) {
                    placed.reeds(at: point, size: scale * (0.61 + CGFloat(i % 2) * 0.12), variation: i)
                } else {
                    placed.mossGarden(at: point, size: scale * 0.62, variation: i)
                }
            }
        }
        for i in 0..<8 {
            let y = CGFloat(i) * 208 + 235, onRight = i.isMultiple(of: 2)
            let point = SleepValleyLayout.streamPoint(y: y, right: onRight, layout: layout, offset: 75)
            placed.terrace(at: point, size: scale * (i.isMultiple(of: 3) ? 0.90 : 0.69), mirror: onRight, variation: i)
        }
        for index in 0..<9 {
            let onRight = index % 4 == 0 || index % 4 == 3
            let x = onRight ? right - 28 * scale : 28 * scale
            let y = 181 + CGFloat(index) * 175
            p.garden(at: CGPoint(x: x, y: y), size: scale * 0.88, variation: index)
            p.at(CGPoint(x: onRight ? 0 : right, y: y + 69), size: scale, mirror: onRight) { edge in
                edge.plants(at: CGPoint(x: 13, y: 0), size: 0.85)
                edge.rock(at: CGPoint(x: 29, y: 15), size: 0.55)
                if index.isMultiple(of: 2) { edge.bellflowers(at: CGPoint(x: 26, y: -6), size: 0.7) }
            }
        }
        for tree in SleepValleyLayout.willows(layout: layout) where tree.id < 10 {
            placed.willow(at: tree.point, size: tree.size, mirror: tree.mirrored, variation: tree.id)
        }
        for cascade in SleepValleyLayout.cascades(layout: layout) { placed.cascadeBanks(cascade, layout: layout) }
        // The crossing spans the actual stream, with its feet planted on both banks.
        placed.bridge(at: SleepValleyLayout.streamPoint(y: 915, right: false, layout: layout), size: scale * 0.88)
        for i in 0..<24 {
            let onRight = i.isMultiple(of: 2)
            let point = layout.position(CGPoint(x: onRight ? right - 22 : 22, y: 69 + CGFloat(i) * 68))
            placed.at(point) { item in
                JunglePainter(context: item.context).grass(at: .zero, size: 5 * scale,
                                                          color: Color(dinoHex: 0x719987).opacity(0.5))
            }
        }
    }

    private func valleyBackdrop(layout: WorldSceneryLayout) {
        let s = layout.scale
        for right in [false, true] {
            for i in 0..<6 {
                let y = CGFloat(i) * 290 - 30
                let edge = SleepValleyLayout.streamPoint(y: y + 90, right: right, layout: layout, offset: 85)
                let outside = right ? layout.width + 130 : -130
                var hill = Path(); hill.move(to: CGPoint(x: outside, y: y - 64))
                hill.addCurve(to: CGPoint(x: edge.x, y: y + 135),
                              control1: CGPoint(x: edge.x + (right ? 75 : -75) * s, y: y - 18),
                              control2: CGPoint(x: edge.x + (right ? -26 : 26) * s, y: y + 45))
                hill.addCurve(to: CGPoint(x: outside, y: y + 310),
                              control1: CGPoint(x: edge.x + (right ? 34 : -34) * s, y: y + 212),
                              control2: CGPoint(x: outside, y: y + 217)); hill.closeSubpath()
                context.fill(hill, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0x527B8A).opacity(0.27),
                                                                                         Color(dinoHex: 0x799F9B).opacity(0.12), .clear]),
                                                         startPoint: CGPoint(x: 0, y: y - 64), endPoint: CGPoint(x: 0, y: y + 310)))
            }
        }
        for layer in 0..<3 {
            for i in 0..<20 {
                let right = i.isMultiple(of: 2)
                let y = CGFloat(i) * 86 + CGFloat(layer * 39) - 10
                let point = SleepValleyLayout.streamPoint(y: y, right: right, layout: layout, offset: CGFloat(72 + layer * 51))
                for tree in 0..<3 {
                    var c = context
                    let size = s * (0.24 + CGFloat(layer) * 0.055 + CGFloat((i + tree) % 3) * 0.04)
                    c.translateBy(x: point.x + CGFloat(tree - 1) * 17 * s,
                                  y: point.y + CGFloat((tree * 7 + i * 3) % 19) * s)
                    c.scaleBy(x: size, y: size)
                    c.opacity = 0.13 + Double(layer) * 0.022
                    SleepValleyPainter(context: c).distantPine(variation: i + layer + tree)
                }
            }
        }
        for i in 0..<5 {
            let y = CGFloat(i) * 337 + 67
            glow(CGPoint(x: layout.centerX(at: y), y: y), radius: 125 * s, color: 0xE1E5DD, opacity: 0.08)
        }
    }

    private func distantPine(variation: Int) {
        let height = CGFloat(122 + variation % 4 * 14)
        var silhouette = Path(); silhouette.move(to: CGPoint(x: 0, y: -height))
        for side: CGFloat in [1, -1] {
            if side < 0 { silhouette.addLine(to: CGPoint(x: -5, y: 7)) }
            let indices = side > 0 ? Array(0..<6) : Array((0..<6).reversed())
            for i in indices {
                let t = CGFloat(i + 1) / 6, y = -height + height * t
                let reach = (11 + t * 30) * side
                silhouette.addQuadCurve(to: CGPoint(x: reach, y: y), control: CGPoint(x: reach * 0.45, y: y - 15))
                silhouette.addQuadCurve(to: CGPoint(x: reach * 0.48, y: y - 4), control: CGPoint(x: reach * 0.78, y: y + 3))
            }
        }
        silhouette.closeSubpath()
        material(silhouette, colors: [0x789AA5, 0x426F80, 0x466E77])
        line([CGPoint(x: 0, y: -height * 0.76), CGPoint(x: 1, y: 10)], color: 0x527A7D, width: 3)
    }

    private func waterLily(_ lily: SleepValleyLayout.WaterLily) {
        at(lily.point, size: lily.size) { p in
            p.context.stroke(Path(ellipseIn: CGRect(x: -17, y: -4, width: 34, height: 9)),
                             with: .color(Color(dinoHex: 0xC0D8CC).opacity(0.30)), lineWidth: 0.7)
            var c = p.context; c.scaleBy(x: 1, y: 0.48)
            var pad = Path(); pad.move(to: .zero)
            pad.addArc(center: .zero, radius: 12, startAngle: .degrees(23), endAngle: .degrees(344), clockwise: false)
            pad.closeSubpath()
            c.fill(pad, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xA8C59C), Color(dinoHex: 0x527F77)]),
                                            startPoint: CGPoint(x: -7, y: -12), endPoint: CGPoint(x: 9, y: 9)))
            c.stroke(pad, with: .color(Color(dinoHex: 0xD3D7A6).opacity(0.55)), lineWidth: 0.7)
            for i in 0..<5 {
                let angle = Double(i) * 1.05 + 0.7
                var vein = Path(); vein.move(to: .zero)
                vein.addLine(to: CGPoint(x: CGFloat(cos(angle)) * 10, y: CGFloat(sin(angle)) * 10))
                c.stroke(vein, with: .color(Color(dinoHex: 0xD2D8AC).opacity(0.28)), lineWidth: 0.5)
            }
            if lily.flower {
                p.glow(CGPoint(x: -2, y: -7), radius: 19, color: 0xF3D7C1, opacity: 0.18)
                for i in 0..<7 {
                    var flower = p.context; flower.translateBy(x: -2, y: -3)
                    flower.rotate(by: .degrees(Double(i - 3) * 21))
                    let petal = Path { shape in
                        shape.move(to: .zero)
                        shape.addCurve(to: CGPoint(x: 0, y: -13), control1: CGPoint(x: -6, y: -4), control2: CGPoint(x: -3, y: -10))
                        shape.addCurve(to: .zero, control1: CGPoint(x: 4, y: -10), control2: CGPoint(x: 6, y: -3))
                    }
                    SleepValleyPainter(context: flower).material(petal, colors: [0xFCF1E0, 0xE2C2D8, 0xA997BC])
                }
                p.oval(CGRect(x: -5, y: -6, width: 7, height: 4), colors: [0xFFF4B9, 0xCDB278])
            }
        }
    }

    private func reeds(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            for i in 0..<5 {
                let x = CGFloat(i - 2) * 4, height = CGFloat(24 + (i * 7 + variation * 3) % 25)
                var stalk = Path(); stalk.move(to: CGPoint(x: x * 0.4, y: 3))
                stalk.addQuadCurve(to: CGPoint(x: x + 4, y: -height), control: CGPoint(x: x - 7, y: -height * 0.59))
                p.context.stroke(stalk, with: .color(Color(dinoHex: i.isMultiple(of: 2) ? 0x648E80 : 0xABC0A1)),
                                 style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                p.leaf(at: CGPoint(x: x * 0.4, y: -2), length: height * 0.73, width: 2.6,
                       angle: Double(i * 19 - 42), light: i.isMultiple(of: 2))
                if (i + variation) % 3 == 0 {
                    p.material(Path(roundedRect: CGRect(x: x + 2, y: -height - 8, width: 3.7, height: 11), cornerRadius: 1.8),
                               colors: [0xD1B59B, 0x8D7F91, 0x657886])
                }
            }
        }
    }

    private func mossGarden(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            p.glow(CGPoint(x: 0, y: 2), radius: 33, color: 0x6E9A86, opacity: 0.27)
            for i in 0..<5 {
                let x = CGFloat(i - 2) * 8, y = CGFloat((i * 7 + variation) % 9)
                p.leaf(at: CGPoint(x: x, y: y), length: CGFloat(15 + (i * 3 + variation) % 13), width: 4.5,
                       angle: Double(i * 28 - 56), light: (i + variation).isMultiple(of: 2))
                if (i + variation) % 3 == 0 {
                    let center = CGPoint(x: x - 3, y: y - 12)
                    for petal in 0..<5 {
                        let a = Double(petal) * .pi * 0.4
                        p.oval(CGRect(x: center.x + CGFloat(cos(a)) * 3 - 1.8,
                                      y: center.y + CGFloat(sin(a)) * 2.6 - 1.7, width: 3.6, height: 3.4),
                               colors: [0xEEE0E2, 0xB8A9CD])
                    }
                    p.oval(CGRect(x: center.x - 1, y: center.y - 1, width: 2, height: 2), colors: [0xFFE8AF, 0xD6BC8F])
                }
            }
        }
    }

    private func sky(width: CGFloat, left: CGFloat, right: CGFloat, height: CGFloat, scale: CGFloat) {
        let moon = CGPoint(x: right - 66 * scale, y: 79 * scale)
        glow(moon, radius: 110 * scale, color: 0xFFE7A0, opacity: 0.4)
        at(moon, size: scale) { p in
            p.oval(CGRect(x: -35, y: -35, width: 70, height: 70), colors: [0xFFF9D5, 0xFFE3A1, 0xEFC78C])
            p.context.stroke(Path(ellipseIn: CGRect(x: -34, y: -34, width: 68, height: 68)), with: .color(Color(dinoHex: 0xFFF9D1)), lineWidth: 1.2)
            for (x, y, r): (CGFloat, CGFloat, CGFloat) in [(-15, -18, 7), (12, -11, 9), (-5, 13, 10), (19, 17, 5), (-20, 2, 4)] {
                p.oval(CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2), colors: [0xF5D595, 0xE9C58F, 0xF8DB9C])
            }
        }
        for i in 0..<35 {
            let x = CGFloat((i * 79 + 23) % 397) / 397 * width
            let y = 22 + CGFloat((i * 47) % 210)
            // Avoid a visible dot pattern across the moon's face.
            if hypot(x - moon.x, y - moon.y) < 45 * scale { continue }
            let r: CGFloat = i % 7 == 0 ? 2.5 : i % 3 == 0 ? 1.2 : 0.65
            glow(CGPoint(x: x, y: y), radius: r * 3, color: 0xFFF1C8, opacity: 0.2)
            if i % 7 == 0 {
                line([CGPoint(x: x - r, y: y), CGPoint(x: x + r, y: y)], color: 0xFFF1C8, width: 0.8, opacity: 0.75)
                line([CGPoint(x: x, y: y - r * 1.3), CGPoint(x: x, y: y + r * 1.3)], color: 0xFFF1C8, width: 0.8, opacity: 0.75)
            } else {
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 1.6, height: r * 1.6)), with: .color(Color(dinoHex: 0xFFF3D3).opacity(0.65)))
            }
        }
        for (x, y, s) in [(width * 0.22, CGFloat(65), CGFloat(1.0)), (width * 0.73, CGFloat(144), CGFloat(0.9)), (width * 0.12, CGFloat(195), CGFloat(0.65))] {
            at(CGPoint(x: x, y: y), size: s * scale) { p in
                var cloud = Path()
                for (cx, cy, cw, ch): (CGFloat, CGFloat, CGFloat, CGFloat) in [(-62, 0, 85, 17), (-39, -12, 48, 28), (-5, -18, 62, 35), (33, -4, 67, 19)] {
                    cloud.addEllipse(in: CGRect(x: cx, y: cy, width: cw, height: ch))
                }
                p.context.drawLayer { c in
                    c.addFilter(.blur(radius: 2.5))
                    c.fill(cloud, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xE6CFE2).opacity(0.58), Color(dinoHex: 0xB8B9D2).opacity(0)]),
                                                       startPoint: CGPoint(x: 0, y: -19), endPoint: CGPoint(x: 0, y: 20)))
                }
            }
        }
        let nature = JunglePainter(context: context)
        for i in 0..<3 {
            nature.hill(x: i % 2 == 0 ? -width * 0.3 : width * 0.49,
                        y: height * 0.36 + CGFloat(i) * 35, width: width * 0.88, height: height * 0.77,
                        color: Color(dinoHex: i == 0 ? 0x5C7E96 : 0x809FA9).opacity(0.28))
        }
        at(CGPoint(x: left - 5, y: height * 0.83), size: scale * 0.82) { $0.distantFalls() }
        at(CGPoint(x: right + 6, y: height * 0.92), size: scale * 0.64, mirror: true) { $0.distantFalls() }
        mist(at: CGPoint(x: width * 0.5, y: height * 0.86), width: width * 1.15, opacity: 0.26)
    }

    private func mist(at point: CGPoint, width: CGFloat, opacity: Double) {
        context.drawLayer { c in
            c.addFilter(.blur(radius: 9))
            for i in 0..<3 {
                let r = CGRect(x: point.x - width * 0.5 + CGFloat(i - 1) * 22,
                               y: point.y + CGFloat(i) * 13, width: width, height: 24 + CGFloat(i) * 7)
                c.fill(Path(ellipseIn: r), with: .color(Color(dinoHex: 0xE7E8F1).opacity(opacity * (1 - Double(i) * 0.2))))
            }
        }
    }

    private func distantFalls() {
        polygon([.init(x: -56, y: 15), .init(x: -43, y: -98), .init(x: -25, y: -144), .init(x: 22, y: -146),
                 .init(x: 41, y: -105), .init(x: 55, y: -84), .init(x: 66, y: 20)], colors: [0xA9B8C5, 0x708FA4, 0x729F9E])
        polygon([.init(x: -25, y: -144), .init(x: -8, y: -137), .init(x: -20, y: 19), .init(x: -54, y: 15)], colors: [0xC2C8CD, 0x8BA7AD])
        var fall = Path(); fall.move(to: CGPoint(x: -2, y: -137))
        fall.addCurve(to: CGPoint(x: -17, y: 18), control1: CGPoint(x: -1, y: -80), control2: CGPoint(x: -13, y: -38))
        fall.addQuadCurve(to: CGPoint(x: 16, y: 18), control: CGPoint(x: 0, y: 27))
        fall.addCurve(to: CGPoint(x: 13, y: -138), control1: CGPoint(x: 9, y: -47), control2: CGPoint(x: 18, y: -84)); fall.closeSubpath()
        material(fall, colors: [0xE5F4F3, 0x8FCAD9, 0xCEE9E1])
        for x: CGFloat in [0, 6] { line([.init(x: x, y: -128), .init(x: x - 3, y: -65), .init(x: x - 7, y: 16)], color: 0xE6F8EE, width: 1.5, opacity: 0.6) }
        plants(at: CGPoint(x: -21, y: -139), size: 0.50)
        plants(at: CGPoint(x: 39, y: -89), size: 0.38)
        glow(CGPoint(x: 0, y: 20), radius: 42, color: 0xE3F5EA, opacity: 0.3)
        mist(at: CGPoint(x: 0, y: 21), width: 138, opacity: 0.25)
    }

    private func leaf(at point: CGPoint, length: CGFloat, width: CGFloat, angle: Double, light: Bool) {
        var c = context; c.translateBy(x: point.x, y: point.y); c.rotate(by: .degrees(angle))
        let shape = Path { p in
            p.move(to: .zero)
            p.addCurve(to: CGPoint(x: length * 0.08, y: -length), control1: CGPoint(x: -width, y: -length * 0.25), control2: CGPoint(x: -width * 0.8, y: -length * 0.73))
            p.addCurve(to: .zero, control1: CGPoint(x: width * 0.8, y: -length * 0.76), control2: CGPoint(x: width * 0.9, y: -length * 0.22))
        }
        c.fill(shape, with: .linearGradient(Gradient(colors: (light ? [0xB8CDB0, 0x81ABA0, 0x46767B] : [0x8CB3AC, 0x4D8185, 0x305C6C]).map { Color(dinoHex: $0) }),
                                           startPoint: CGPoint(x: -width * 0.5, y: -length), endPoint: CGPoint(x: width, y: 0)))
        var vein = Path(); vein.move(to: .zero); vein.addLine(to: CGPoint(x: length * 0.07, y: -length * 0.88))
        c.stroke(vein, with: .color(Color(dinoHex: 0xE2E8BA).opacity(0.34)), style: StrokeStyle(lineWidth: 0.6, lineCap: .round))
    }

    private func willow(at point: CGPoint, size: CGFloat, mirror: Bool, variation: Int) {
        at(point, size: size, mirror: mirror) { p in
            var shadow = p.context; shadow.scaleBy(x: 1, y: 0.23)
            shadow.fill(Path(ellipseIn: CGRect(x: -57, y: -37, width: 114, height: 114)),
                        with: .radialGradient(Gradient(colors: [Color(dinoHex: 0x426B70).opacity(0.35), .clear]),
                                              center: CGPoint(x: 0, y: 20), startRadius: 0, endRadius: 57))
            let trunk = Path { t in
                t.move(to: CGPoint(x: -28, y: 7))
                t.addCurve(to: CGPoint(x: 9, y: -190), control1: CGPoint(x: -1, y: -36), control2: CGPoint(x: -10, y: -135))
                t.addLine(to: CGPoint(x: 27, y: -191))
                t.addCurve(to: CGPoint(x: 35, y: 6), control1: CGPoint(x: 19, y: -109), control2: CGPoint(x: 14, y: -27))
                t.addQuadCurve(to: CGPoint(x: 4, y: -5), control: CGPoint(x: 10, y: 6)); t.closeSubpath()
            }
            p.material(trunk, colors: [0xD4C3A1, 0x9A9886, 0x626E6C])
            var bark = p.context; bark.clip(to: trunk)
            for i in 0..<5 {
                let x = CGFloat(i) * 8 - 12
                var grain = Path(); grain.move(to: CGPoint(x: x, y: 8))
                grain.addCurve(to: CGPoint(x: x + 13, y: -198), control1: CGPoint(x: x + 12, y: -58), control2: CGPoint(x: x - 2, y: -122))
                bark.stroke(grain, with: .color(Color(dinoHex: i % 2 == 0 ? 0xECE0B7 : 0x586A65).opacity(0.4)), style: StrokeStyle(lineWidth: i % 2 == 0 ? 2.5 : 1.2, lineCap: .round))
            }
            let grainPainter = SleepValleyPainter(context: bark)
            for (x, y, width, height): (CGFloat, CGFloat, CGFloat, CGFloat) in [(12, -82, 7, 14), (8, -133, 4, 9)] {
                grainPainter.oval(CGRect(x: x - width / 2, y: y - height / 2, width: width, height: height),
                                  colors: [0x6C7C72, 0x8F9580, 0xB5AE90])
                for ring in 0..<3 {
                    let inset = CGFloat(ring) * 2
                    var grain = Path()
                    grain.addArc(center: CGPoint(x: x, y: y), radius: width + inset,
                                 startAngle: .degrees(124), endAngle: .degrees(243), clockwise: false)
                    bark.stroke(grain, with: .color(Color(dinoHex: 0xDDD1AC).opacity(0.24)), lineWidth: 0.65)
                }
            }
            for side: CGFloat in [-1, 1] {
                var branch = Path(); branch.move(to: CGPoint(x: 14, y: -112))
                branch.addQuadCurve(to: CGPoint(x: 17 + side * 55, y: -194), control: CGPoint(x: 25 + side * 42, y: -142))
                p.context.stroke(branch, with: .color(Color(dinoHex: 0x8C917E)), style: StrokeStyle(lineWidth: 8, lineCap: .round))
            }
            // Keep roots and trunk still; only the crown and its hanging lights sway.
            for i in 0..<3 {
                let x = CGFloat(i - 1) * 20
                var root = Path(); root.move(to: CGPoint(x: 4, y: -12))
                root.addQuadCurve(to: CGPoint(x: x, y: 10), control: CGPoint(x: x * 0.4, y: 1))
                p.context.stroke(root, with: .color(Color(dinoHex: 0x9AAB91)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
            p.glow(CGPoint(x: 18, y: -65), radius: 47, color: 0xFFE1A0, opacity: 0.13)
            if !p.animatedWillows { p.willowCanopy(variation: variation, time: 0) }
            p.plants(at: CGPoint(x: -16, y: 11), size: 0.75)
        }
    }

    /// Uneven boughs and staggered leaves give each crown its own hanging silhouette.
    func willowCanopy(variation: Int, time: TimeInterval) {
        let nature = JunglePainter(context: context)
        for (x, y, w, h): (CGFloat, CGFloat, CGFloat, CGFloat) in [
            (-69, -221, 86, 71), (-31, -242, 79, 79), (18, -233, 80, 88),
            (49, -209, 49, 74), (-58, -199, 97, 65), (-4, -206, 86, 69)
        ] {
            let shape = nature.foliagePath(in: CGRect(x: x, y: y, width: w, height: h))
            material(shape, colors: [0x709B94, 0x3B7075, 0x2B5363])
        }
        for i in 0..<5 {
            let fraction = CGFloat(i) / 4
            let x = -64 + fraction * 151
            let y = -207 - CGFloat(sin(Double(fraction) * .pi)) * 29
            var bough = Path(); bough.move(to: CGPoint(x: 15, y: -182))
            bough.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x * 0.45, y: y - 7))
            context.stroke(bough, with: .color(Color(dinoHex: 0x7C8F7E).opacity(0.75)),
                           style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        }
        for row in 0..<3 {
            let count = row == 0 ? 9 : row == 1 ? 10 : 7
            for strand in 0..<count {
                let seed = Double(variation * 13 + strand * 7 + row * 11) * 0.413
                let fraction = CGFloat(strand) / CGFloat(count - 1)
                let x = -64 + fraction * (row == 2 ? 134 : 151) + CGFloat(sin(seed)) * 4
                let arch = CGFloat(sin(Double(fraction) * .pi))
                let startY = -207 - arch * 29 + CGFloat(row) * 19 + CGFloat(cos(seed * 0.7)) * 6
                let length = CGFloat(73 + (strand * 23 + variation * 17 + row * 31) % 58) - (row == 2 ? 17 : 0)
                let bend = (fraction - 0.45) * 27 + CGFloat(sin(seed * 1.7)) * 8
                let wind = CGFloat(sin(time * 0.57 + seed) - sin(seed)) * (row == 0 ? 2.1 : 3.4)
                func onTwig(_ t: CGFloat) -> CGPoint {
                    CGPoint(x: x + bend * (2 * t - t * t) + wind * t * t + CGFloat(sin(Double(t) * 2.5 + seed) - sin(seed)) * t * 2,
                            y: startY + length * pow(t, 0.94))
                }
                var twig = Path(); twig.move(to: onTwig(0))
                for i in 1...10 { twig.addLine(to: onTwig(CGFloat(i) / 10)) }
                context.stroke(twig, with: .color(Color(dinoHex: 0x3A635F).opacity(0.8)),
                               style: StrokeStyle(lineWidth: row == 0 ? 1.2 : 0.8, lineCap: .round, lineJoin: .round))
                let pairs = 5 + (strand + row) % 3
                for pair in 0..<pairs {
                    for side in [-1.0, 1.0] {
                        let stagger: CGFloat = side < 0 ? 0.10 : 0.48
                        let t = (CGFloat(pair) + stagger) / CGFloat(pairs)
                        let leafSize = (18.5 + CGFloat(sin(seed + Double(pair) * 2)) * 3.5) * (1 - t * 0.24)
                        let flutter = Double(wind) * 1.25 * Double(t)
                        leaf(at: onTwig(t), length: leafSize, width: leafSize * (row == 2 ? 0.31 : 0.27),
                             angle: 178 + side * (22 + Double((strand + pair) % 4) * 5) + flutter,
                             light: row > 0 && (strand * 3 + pair + variation) % 5 < 3)
                    }
                }
                leaf(at: onTwig(0.96), length: 16 + CGFloat(strand % 4), width: 4.1,
                     angle: 183 + Double(wind), light: row > 0 && strand.isMultiple(of: 2))
            }
        }
        for (index, pivot) in [CGPoint(x: -39, y: -168), CGPoint(x: 32, y: -142), CGPoint(x: 69, y: -179)].enumerated() {
            let seed = Double(variation) * 1.7 + Double(index) * 2.4
            let pulse = 0.88 + sin(time * 0.91 + seed) * 0.12
            glow(CGPoint(x: pivot.x, y: pivot.y + 31), radius: 24, color: 0xF8D390, opacity: pulse * 0.14)
            var c = context; c.translateBy(x: pivot.x, y: pivot.y)
            c.rotate(by: .degrees((sin(time * 0.66 + seed) - sin(seed)) * 2.1))
            c.scaleBy(x: index == 1 ? 0.83 : 0.66, y: index == 1 ? 0.83 : 0.66)
            SleepValleyPainter(context: c).lantern(pulse: pulse)
        }
    }

    private func lantern(pulse: Double) {
        var cord = Path(); cord.move(to: .zero)
        cord.addQuadCurve(to: CGPoint(x: 0, y: 27), control: CGPoint(x: 2, y: 11))
        context.stroke(cord, with: .color(Color(dinoHex: 0x6C7868)), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
        glow(CGPoint(x: 0, y: 48), radius: 43, color: 0xFFDA8A, opacity: 0.34 * pulse)
        context.stroke(Path(ellipseIn: CGRect(x: -4, y: 26, width: 8, height: 9)),
                       with: .color(Color(dinoHex: 0xD2B16D)), lineWidth: 1.7)
        let glass = Path(roundedRect: CGRect(x: -9, y: 39, width: 18, height: 24), cornerRadius: 3)
        material(glass, colors: [0xFFFFD5, 0xFFE8A2, 0xEFB45C])
        context.stroke(glass, with: .color(Color(dinoHex: 0xA78857)), lineWidth: 1.5)
        polygon([.init(x: -14, y: 39), .init(x: -7, y: 35), .init(x: 0, y: 30), .init(x: 7, y: 35), .init(x: 14, y: 39)],
                colors: [0xFFE2A1, 0xB59A65, 0x8C7956])
        for x: CGFloat in [-7, 7] {
            line([CGPoint(x: x, y: 39), CGPoint(x: x, y: 63)], color: 0xAE8D53, width: 1.3)
        }
        material(Path(roundedRect: CGRect(x: -12, y: 62, width: 24, height: 4), cornerRadius: 1.5), colors: [0xF1D38F, 0x9E8456])
        line([CGPoint(x: -4, y: 42), CGPoint(x: -4, y: 57)], color: 0xFFFFED, width: 1.1, opacity: 0.8)
        var star = Path()
        for i in 0..<10 {
            let a = Double(i) * .pi / 5 - .pi / 2, r: CGFloat = i.isMultiple(of: 2) ? 5 : 2.4
            let point = CGPoint(x: CGFloat(cos(a)) * r, y: 51 + CGFloat(sin(a)) * r)
            if i == 0 { star.move(to: point) } else { star.addLine(to: point) }
        }
        star.closeSubpath(); context.stroke(star, with: .color(Color(dinoHex: 0xD3A24D)), lineWidth: 0.9)
        glow(CGPoint(x: 0, y: 49), radius: 9, color: 0xFFFFE1, opacity: 0.5 * pulse)
    }

    private func riverbeds(layout: WorldSceneryLayout) {
        let s = layout.scale
        for right in [false, true] {
            let shoulder = SleepValleyLayout.riverbank(layout: layout, right: right, width: 76)
            context.fill(shoulder, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0x688D88).opacity(0.42),
                                                                                       Color(dinoHex: 0x9CB7A7).opacity(0.7)]),
                                                       startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: layout.width, y: 1500)))
            let water = SleepValleyLayout.riverbank(layout: layout, right: right, width: 54)
            context.fill(water, with: .linearGradient(Gradient(stops: [
                .init(color: Color(dinoHex: 0x4C7C94), location: 0),
                .init(color: Color(dinoHex: 0x79ADB5), location: 0.34),
                .init(color: Color(dinoHex: 0x5F96A4), location: 0.67),
                .init(color: Color(dinoHex: 0x95B8B3), location: 1)
            ]), startPoint: CGPoint(x: 0, y: -layout.routeOffset), endPoint: CGPoint(x: layout.width, y: layout.height)))
            var submerged = context; submerged.clip(to: water)
            let river = SleepValleyLayout.stream(layout: layout, right: right, start: -layout.routeOffset,
                                                 end: layout.height - layout.routeOffset)
            submerged.stroke(river.offsetBy(dx: right ? 8 * s : -8 * s, dy: 0),
                             with: .color(Color(dinoHex: 0x2E647C).opacity(0.22)),
                             style: StrokeStyle(lineWidth: 19 * s, lineCap: .round, lineJoin: .round))
            for i in 0..<39 {
                let y = CGFloat(i) * 44 + 43
                let point = SleepValleyLayout.waterPoint(y: y, right: right, across: CGFloat((i * 7) % 11 - 5) / 7, layout: layout)
                let width = CGFloat(3 + i % 4) * s
                submerged.fill(Path(ellipseIn: CGRect(x: point.x - width, y: point.y - 1.6 * s, width: width * 2, height: 3.2 * s)),
                               with: .color(Color(dinoHex: i.isMultiple(of: 2) ? 0xB0C7B8 : 0x4A7A8C).opacity(0.23)))
            }
            for across: CGFloat in [-1, 1] {
                var shoreline = Path()
                for i in 0..<300 {
                    let y = CGFloat(i) * 6 - 80
                    let point = SleepValleyLayout.waterPoint(y: y, right: right, across: across, layout: layout)
                    if i == 0 { shoreline.move(to: point) } else { shoreline.addLine(to: point) }
                }
                context.stroke(shoreline, with: .color(Color(dinoHex: 0xD6DED0).opacity(0.5)),
                               style: StrokeStyle(lineWidth: 0.8 * s, lineCap: .round,
                                                  dash: [13 * s, 7 * s, 3 * s, 21 * s, 5 * s, 12 * s]))
            }
            // Small irregular stone clusters break the waterline instead of forming rails.
            for i in 0..<20 {
                let y = CGFloat(i) * 81 + CGFloat((i * 23) % 31) + 33
                let across: CGFloat = i.isMultiple(of: 3) ? -1.16 : 1.2
                let point = SleepValleyLayout.waterPoint(y: y, right: right, across: across, layout: layout)
                at(point, size: s * CGFloat(0.23 + Double(i % 4) * 0.035), mirror: right) { p in
                    p.rock(at: .zero, size: 1)
                    if i.isMultiple(of: 2) { p.rock(at: CGPoint(x: 28, y: 8), size: 0.52) }
                }
            }
        }
    }

    private func terrace(at point: CGPoint, size: CGFloat, mirror: Bool, variation: Int) {
        at(point, size: size, mirror: mirror) { p in
            p.glow(CGPoint(x: -3, y: 19), radius: 88, color: 0x507586, opacity: 0.14)
            let outline: [CGPoint] = [.init(x: -94, y: -23), .init(x: -63, y: -35), .init(x: -20, y: -41),
                                      .init(x: 26, y: -35), .init(x: 58, y: -22), .init(x: 64, y: 1),
                                      .init(x: 43, y: 25), .init(x: -6, y: 34), .init(x: -58, y: 29), .init(x: -99, y: 10)]
            let stone = p.roundedStone(outline)
            p.material(stone, colors: [0xB2BBC2, 0x7E93A2, 0x526F82])
            var clipped = p.context; clipped.clip(to: stone)
            let face = SleepValleyPainter(context: clipped)
            face.polygon([.init(x: -65, y: -17), .init(x: -29, y: -5), .init(x: -16, y: 34), .init(x: -66, y: 31)],
                         colors: [0x9AA9B3, 0x6C8595])
            face.polygon([.init(x: 18, y: -21), .init(x: 60, y: -10), .init(x: 43, y: 25), .init(x: 5, y: 34)],
                         colors: [0x8D9FAA, 0x547184])
            for i in 0..<4 {
                let x = CGFloat(i) * 33 - 66
                var crack = Path(); crack.move(to: CGPoint(x: x + 4, y: -10))
                crack.addLines([CGPoint(x: x - 3, y: 1), CGPoint(x: x + 1, y: 11), CGPoint(x: x - 5, y: 20)])
                clipped.stroke(crack, with: .color(Color(dinoHex: 0x446376).opacity(0.57)),
                               style: StrokeStyle(lineWidth: 0.8, lineCap: .round, lineJoin: .round))
                face.line([CGPoint(x: x - 1, y: -6), CGPoint(x: x - 7, y: 1)], color: 0xD0D2CC, width: 0.7, opacity: 0.4)
            }
            var moss = Path(); moss.move(to: CGPoint(x: -102, y: -20))
            moss.addCurve(to: CGPoint(x: 63, y: -22), control1: CGPoint(x: -39, y: -57), control2: CGPoint(x: 17, y: -51))
            moss.addCurve(to: CGPoint(x: 27, y: -10), control1: CGPoint(x: 63, y: -7), control2: CGPoint(x: 40, y: -18))
            moss.addCurve(to: CGPoint(x: -19, y: -1), control1: CGPoint(x: 7, y: -1), control2: CGPoint(x: -9, y: -18))
            moss.addCurve(to: CGPoint(x: -102, y: -9), control1: CGPoint(x: -39, y: -16), control2: CGPoint(x: -68, y: 1)); moss.closeSubpath()
            face.material(moss, colors: [0xC2CCAB, 0x95AE96, 0x698F85])
            for i in 0..<4 {
                let x = CGFloat(i) * 28 - 65
                p.mossGarden(at: CGPoint(x: x, y: -21 - CGFloat(i % 2) * 7), size: 0.46, variation: i + variation)
            }
            p.rock(at: CGPoint(x: -58, y: 23), size: 0.36)
            p.reeds(at: CGPoint(x: 43, y: -13), size: 0.44, variation: variation)
        }
    }

    private func cascadeBanks(_ cascade: SleepValleyLayout.Cascade, layout: WorldSceneryLayout) {
        at(cascade.point, size: layout.scale) { p in
            p.rock(at: cascade.localPoint(y: -39, across: -1.43, layout: layout), size: 0.70)
            p.rock(at: cascade.localPoint(y: -32, across: 1.42, layout: layout), size: 0.64)
            p.plants(at: cascade.localPoint(y: -50, across: -1.48, layout: layout), size: 0.43)
            p.bellflowers(at: cascade.localPoint(y: -34, across: 1.53, layout: layout), size: 0.38)
        }
    }

    private func cascadeWater(_ cascade: SleepValleyLayout.Cascade, layout: WorldSceneryLayout) {
        at(cascade.point, size: layout.scale) { p in
            let feed = cascade.ribbon(from: -105, to: -43, layout: layout)
            p.context.fill(feed, with: .linearGradient(Gradient(stops: [
                .init(color: Color(dinoHex: 0x91C4CA).opacity(0), location: 0),
                .init(color: Color(dinoHex: 0xA2D0D3).opacity(0.55), location: 0.55),
                .init(color: Color(dinoHex: 0xBADFD9).opacity(0.75), location: 1)
            ]), startPoint: cascade.localPoint(y: -105, layout: layout), endPoint: cascade.localPoint(y: -43, layout: layout)))
            let fall = cascade.ribbon(from: -43, to: 9, layout: layout)
            p.context.fill(fall, with: .linearGradient(Gradient(stops: [
                .init(color: Color(dinoHex: 0xD1E8E1), location: 0),
                .init(color: Color(dinoHex: 0x82B9C5), location: 0.18),
                .init(color: Color(dinoHex: 0x74AEBE), location: 0.70),
                .init(color: Color(dinoHex: 0xB0D8D8), location: 1)
            ]), startPoint: cascade.localPoint(y: -43, layout: layout), endPoint: cascade.localPoint(y: 9, layout: layout)))
            let outlet = cascade.ribbon(from: 9, to: 85, layout: layout)
            p.context.fill(outlet, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xB0D8D8).opacity(0.72),
                                                                                        Color(dinoHex: 0x91C4CA).opacity(0)]),
                                                       startPoint: cascade.localPoint(y: 9, layout: layout), endPoint: cascade.localPoint(y: 85, layout: layout)))
            var lip = Path()
            for i in 0...16 {
                let q = cascade.localPoint(y: -43, across: -0.95 + CGFloat(i) * 1.90 / 16, layout: layout)
                if i == 0 { lip.move(to: q) } else { lip.addLine(to: q) }
            }
            p.context.stroke(lip, with: .color(Color(dinoHex: 0xEAF4E9).opacity(0.77)),
                             style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
            var veil = p.context; veil.clip(to: fall)
            for i in 0..<7 {
                veil.stroke(cascade.filament(across: CGFloat(i - 3) * 0.25, layout: layout),
                            with: .color(Color(dinoHex: 0xE5F3E9).opacity(i.isMultiple(of: 2) ? 0.38 : 0.22)),
                            style: StrokeStyle(lineWidth: i.isMultiple(of: 2) ? 1.1 : 0.6, lineCap: .round))
            }
            // Foam stays in small patches, leaving the continuing current visible.
            for i in 0..<7 {
                let q = cascade.localPoint(y: 9 + CGFloat(i % 3) * 3, across: CGFloat(i - 3) * 0.22, layout: layout)
                p.oval(CGRect(x: q.x - 2, y: q.y - 0.8, width: 4, height: 1.6), colors: [0xEFF6E9, 0xB7D8D2])
            }
        }
    }

    private func crystals(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.glow(CGPoint(x: 0, y: -13), radius: 38, color: 0xC8B5F3, opacity: 0.2)
            for (x, y, w, h): (CGFloat, CGFloat, CGFloat, CGFloat) in [(-14, 5, 10, 28), (1, 3, 15, 47), (17, 7, 9, 24)] {
                let tip = CGPoint(x: x + w * 0.38, y: y - h)
                let left = CGPoint(x: x - w * 0.48, y: y - h * 0.67)
                let right = CGPoint(x: x + w * 0.58, y: y - h * 0.63)
                p.polygon([.init(x: x - w * 0.43, y: y), left, tip, right, .init(x: x + w * 0.45, y: y)],
                          colors: [0xD8D7FA, 0x999FD6, 0x667EAD])
                p.polygon([tip, .init(x: x + w * 0.04, y: y - h * 0.55), .init(x: x, y: y),
                           .init(x: x + w * 0.45, y: y), right], colors: [0xD4C7EE, 0x7E8BBB, 0x5C739E])
                p.line([left, tip, right], color: 0xE5EDF7, width: 0.9, opacity: 0.8)
            }
        }
    }

    private func plants(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for i in 0..<7 {
                p.leaf(at: CGPoint(x: CGFloat(i % 3) * 5, y: CGFloat(i % 2) * 4), length: CGFloat(28 + i % 3 * 12),
                       width: CGFloat(8 + i % 2 * 3), angle: Double(i * 26 - 78), light: i % 3 == 0)
            }
        }
    }

    private func roundedStone(_ points: [CGPoint]) -> Path {
        func between(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
            CGPoint(x: a.x * 0.76 + b.x * 0.24, y: a.y * 0.76 + b.y * 0.24)
        }
        guard let first = points.first, let last = points.last else { return Path() }
        return Path { p in
            p.move(to: between(first, last))
            for i in points.indices {
                let point = points[i], next = points[(i + 1) % points.count]
                p.addQuadCurve(to: between(point, next), control: point)
                p.addLine(to: between(next, point))
            }
            p.closeSubpath()
        }
    }

    private func rock(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            let points: [CGPoint] = [.init(x: -35, y: 10), .init(x: -30, y: -14), .init(x: -12, y: -35),
                                     .init(x: 15, y: -38), .init(x: 37, y: -13), .init(x: 29, y: 12)]
            let stone = p.roundedStone(points)
            p.material(stone, colors: [0xCBCDD0, 0x94A5B0, 0x5C788C])
            var facets = p.context; facets.clip(to: stone)
            let face = SleepValleyPainter(context: facets)
            face.polygon([points[1], points[2], points[3], .init(x: 4, y: -18), .init(x: -14, y: -9)], colors: [0xD4D1D1, 0xA5B5BB])
            face.polygon([points[3], points[4], points[5], .init(x: 6, y: 10), .init(x: 4, y: -18)], colors: [0x94A7B3, 0x597487])
            var seam = Path(); seam.move(to: CGPoint(x: -13, y: -28))
            seam.addQuadCurve(to: CGPoint(x: 6, y: -12), control: CGPoint(x: -4, y: -22))
            seam.addLine(to: CGPoint(x: 2, y: -3)); seam.addLine(to: CGPoint(x: 10, y: 6))
            facets.stroke(seam, with: .color(Color(dinoHex: 0x526F82).opacity(0.6)),
                          style: StrokeStyle(lineWidth: 0.75, lineCap: .round, lineJoin: .round))
            var moss = Path(); moss.move(to: CGPoint(x: -37, y: -25))
            moss.addCurve(to: CGPoint(x: 28, y: -31), control1: CGPoint(x: -12, y: -43), control2: CGPoint(x: 10, y: -43))
            moss.addCurve(to: CGPoint(x: 1, y: -22), control1: CGPoint(x: 27, y: -18), control2: CGPoint(x: 15, y: -30))
            moss.addCurve(to: CGPoint(x: -32, y: -13), control1: CGPoint(x: -4, y: -10), control2: CGPoint(x: -21, y: -25)); moss.closeSubpath()
            face.material(moss, colors: [0xC1CEA4, 0x8DAA91, 0x628D80])
            for i in 0..<7 {
                let x = CGFloat((i * 13) % 48) - 24, y = CGFloat((i * 7) % 21) - 24
                face.oval(CGRect(x: x, y: y, width: 2.1, height: 0.9), colors: [0xE0DCC5, 0xB1BAAF])
            }
            p.leaf(at: CGPoint(x: -20, y: -23), length: 14, width: 4.8, angle: -65, light: true)
            p.leaf(at: CGPoint(x: -19, y: -23), length: 17, width: 4.8, angle: 29, light: false)
        }
    }

    private func mushroom(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.glow(CGPoint(x: 0, y: -10), radius: 55, color: 0xFFE1A0, opacity: 0.33)
            let stem = Path { s in
                s.move(to: CGPoint(x: -7, y: 2)); s.addQuadCurve(to: CGPoint(x: -5, y: -38), control: CGPoint(x: -3, y: -22))
                s.addLine(to: CGPoint(x: 7, y: -38)); s.addQuadCurve(to: CGPoint(x: 9, y: 2), control: CGPoint(x: 4, y: -17)); s.closeSubpath()
            }
            p.material(stem, colors: [0xFFEDB4, 0xEFD296, 0xB19C7B])
            p.oval(CGRect(x: -34, y: -29, width: 68, height: 14), colors: [0xFFF8D3, 0xF0D59C, 0xD0B391])
            for i in 0..<7 {
                p.line([.init(x: 0, y: -25), .init(x: CGFloat(i - 3) * 9, y: -23)], color: 0xA89B89, width: 0.7, opacity: 0.5)
            }
            let cap = Path { c in
                c.move(to: CGPoint(x: -35, y: -25))
                c.addCurve(to: CGPoint(x: -2, y: -62), control1: CGPoint(x: -29, y: -47), control2: CGPoint(x: -19, y: -64))
                c.addCurve(to: CGPoint(x: 35, y: -25), control1: CGPoint(x: 16, y: -65), control2: CGPoint(x: 31, y: -43))
                c.addQuadCurve(to: CGPoint(x: -35, y: -25), control: CGPoint(x: 2, y: -13)); c.closeSubpath()
            }
            p.material(cap, colors: [0xDBB6DA, 0xAA8AC2, 0x786D9E])
            p.context.stroke(cap, with: .color(Color(dinoHex: 0xECE0ED).opacity(0.55)), lineWidth: 0.8)
            for (x, y, r): (CGFloat, CGFloat, CGFloat) in [(-15, -39, 3), (3, -51, 3.5), (19, -34, 4), (-1, -30, 2.5)] {
                p.oval(CGRect(x: x - r, y: y - r * 0.6, width: r * 2, height: r * 1.2), colors: [0xFFF8D2, 0xEAD6AE])
            }
        }
    }

    private func bellflowers(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for i in 0..<3 {
                let x = CGFloat(i - 1) * 16, y = CGFloat(i % 2) * -17 - 27
                var stem = Path(); stem.move(to: CGPoint(x: x, y: 8))
                stem.addQuadCurve(to: CGPoint(x: x + 4, y: y - 17), control: CGPoint(x: x - 12, y: y - 25))
                p.context.stroke(stem, with: .color(Color(dinoHex: 0x6A9581)), style: StrokeStyle(lineWidth: 1.7, lineCap: .round))
                let bell = Path { b in
                    b.move(to: CGPoint(x: x + 3, y: y - 18))
                    b.addCurve(to: CGPoint(x: x - 10, y: y + 3), control1: CGPoint(x: x - 9, y: y - 16), control2: CGPoint(x: x - 6, y: y - 3))
                    b.addQuadCurve(to: CGPoint(x: x - 2, y: y + 3), control: CGPoint(x: x - 5, y: y + 8))
                    b.addQuadCurve(to: CGPoint(x: x + 7, y: y + 4), control: CGPoint(x: x + 2, y: y + 11))
                    b.addQuadCurve(to: CGPoint(x: x + 16, y: y + 1), control: CGPoint(x: x + 12, y: y + 7))
                    b.addQuadCurve(to: CGPoint(x: x + 3, y: y - 18), control: CGPoint(x: x + 10, y: y - 16)); b.closeSubpath()
                }
                p.material(bell, colors: [0xEEE1ED, 0xC0AED2, 0x8C84B4])
                p.line([.init(x: x + 3, y: y + 2), .init(x: x + 3, y: y + 9)], color: 0xF8DEAA, width: 2)
                p.leaf(at: CGPoint(x: x, y: -4), length: 19, width: 6, angle: -63, light: false)
            }
        }
    }


    private func bridge(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.polygon([.init(x: -48, y: -9), .init(x: 41, y: -13), .init(x: 53, y: 15), .init(x: -49, y: 20)], colors: [0xD6B891, 0x9C8169, 0x7D7163])
            for i in 0..<8 {
                let x = CGFloat(i) * 12 - 43
                p.line([.init(x: x, y: -7), .init(x: x + 3, y: 14)], color: 0x695E54, width: 1, opacity: 0.7)
                p.line([.init(x: x + 3, y: -5), .init(x: x + 5, y: 11)], color: 0xF0D1A1, width: 0.8, opacity: 0.6)
            }
            for x: CGFloat in [-43, 43] {
                p.material(Path(roundedRect: CGRect(x: x - 3, y: -30, width: 7, height: 45), cornerRadius: 2), colors: [0xDCC294, 0x8E7B64])
                p.oval(CGRect(x: x - 5, y: -33, width: 11, height: 5), colors: [0xEDCF9C, 0xA58B68])
            }
            var rail = Path(); rail.move(to: CGPoint(x: -43, y: -22))
            rail.addQuadCurve(to: CGPoint(x: 43, y: -24), control: CGPoint(x: 0, y: -9))
            p.context.stroke(rail, with: .color(Color(dinoHex: 0xC3AD82)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }

    func garden(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size, radius: 74 * size, rise: 135 * size) { p in
            var moss = p.context; moss.scaleBy(x: 1, y: 0.32)
            moss.fill(Path(ellipseIn: CGRect(x: -65, y: -49, width: 130, height: 130)),
                      with: .radialGradient(Gradient(colors: [Color(dinoHex: 0x9CB89F).opacity(0.6), .clear]),
                                            center: CGPoint(x: 0, y: 16), startRadius: 12, endRadius: 65))
            switch variation % 3 {
            case 0:
                p.rock(at: CGPoint(x: 8, y: 8), size: 0.83)
                p.mushroom(at: CGPoint(x: -20, y: -4), size: 0.87)
                p.mushroom(at: CGPoint(x: 31, y: 15), size: 0.43)
                p.bellflowers(at: CGPoint(x: 22, y: -24), size: 0.62)
                p.crystals(at: CGPoint(x: 46, y: 12), size: 0.64)
            case 1:
                p.rock(at: CGPoint(x: -3, y: 1), size: 1)
                p.mushroom(at: CGPoint(x: -1, y: -26), size: 0.89)
                p.mushroom(at: CGPoint(x: -38, y: 15), size: 0.49)
                p.bellflowers(at: CGPoint(x: 34, y: 0), size: 0.56)
            default:
                p.willow(at: CGPoint(x: 6, y: -3), size: 0.62, mirror: false, variation: variation)
                p.mushroom(at: CGPoint(x: -33, y: 17), size: 0.66)
                p.rock(at: CGPoint(x: 36, y: 17), size: 0.43)
                p.crystals(at: CGPoint(x: 33, y: 11), size: 0.53)
            }
            p.plants(at: CGPoint(x: -37, y: 17), size: 0.73)
            p.plants(at: CGPoint(x: 38, y: 23), size: 0.59)
        }
    }
}

/// Shared coordinates keep the molten surfaces attached to their rock sources.
private enum VolcanoWorldLayout {
    enum Kind { case crater, summit }
    struct Source: Identifiable {
        let id: Int
        let kind: Kind
        let point: CGPoint
        let size: CGFloat
        var mirrored = false
        var outlet: CGPoint { position(kind == .summit ? CGPoint(x: 16, y: 32) : CGPoint(x: 17, y: 34)) }

        func position(_ local: CGPoint) -> CGPoint {
            CGPoint(x: point.x + local.x * size * (mirrored ? -1 : 1), y: point.y + local.y * size)
        }

        var bounds: CGRect {
            let local: CGRect
            switch kind {
            case .crater: local = CGRect(x: -105, y: -245, width: 235, height: 295)
            case .summit: local = CGRect(x: -145, y: -395, width: 310, height: 440)
            }
            return frame(local)
        }

        /// Conservative bands include the cone, crater rim and its basal pool.
        /// Smoke and soft shadows may drift above the river; rock may not.
        var terrainBands: [CGRect] {
            let local: [CGRect]
            switch kind {
            case .crater:
                local = [CGRect(x: -36, y: -113, width: 72, height: 34),
                         CGRect(x: -58, y: -82, width: 116, height: 38),
                         CGRect(x: -89, y: -48, width: 180, height: 48),
                         CGRect(x: -100, y: 0, width: 205, height: 47)]
            case .summit:
                // Follow the taper so the narrow crown can sit beside the
                // incoming river while the broad foot fills the outer bend.
                local = [CGRect(x: -38, y: -234, width: 76, height: 24),
                         CGRect(x: -45, y: -210, width: 90, height: 24),
                         CGRect(x: -53, y: -186, width: 106, height: 24),
                         CGRect(x: -61, y: -162, width: 122, height: 24),
                         CGRect(x: -70, y: -138, width: 140, height: 24),
                         CGRect(x: -81, y: -114, width: 162, height: 24),
                         CGRect(x: -94, y: -90, width: 188, height: 24),
                         CGRect(x: -108, y: -66, width: 216, height: 24),
                         CGRect(x: -126, y: -42, width: 252, height: 24),
                         CGRect(x: -144, y: -18, width: 288, height: 24),
                         CGRect(x: -151, y: 6, width: 302, height: 24),
                         CGRect(x: -95, y: 30, width: 190, height: 8)]
            }
            return local.map(frame)
        }

        private func frame(_ local: CGRect) -> CGRect {
            CGRect(x: point.x + (mirrored ? -local.maxX : local.minX) * size,
                   y: point.y + local.minY * size, width: local.width * size, height: local.height * size)
        }
    }

    struct LooseRock {
        let point: CGPoint
        let size: CGFloat
        let variation: Int
        var bounds: CGRect {
            CGRect(x: point.x - 58 * size, y: point.y - 45 * size,
                   width: 116 * size, height: 73 * size)
        }
    }

    struct Tributary: Identifiable {
        let id: Int
        let points: [CGPoint]
        var path: Path { Path { $0.addLines(points) } }
    }

    struct TerrainSlab {
        let points: [CGPoint]
        let variation: Int
        let right: Bool
        var bounds: CGRect { points.reduce(CGRect.null) { $0.union(CGRect(origin: $1, size: .zero)) } }
    }

    /// Portrait phones keep the original entrance. On a wide map the same
    /// short blend becomes a corner, because the bank is much farther from the edge.
    static func isBroad(_ width: CGFloat) -> Bool { width >= 520 }

    /// How far the entrance has joined the trail. Nil on phone widths.
    /// The run-in finishes at the top of the world, so the visible crown
    /// already shares the trail's swirl instead of kinking inward.
    static func broadEntrance(layout: WorldSceneryLayout, sectionY: CGFloat) -> CGFloat? {
        guard isBroad(layout.width) else { return nil }
        let span = max(520, layout.width * 0.72)
        let t = min(1, max(0, (sectionY + span - 36) / span))
        return t * t * (3 - 2 * t)
    }

    static func bankPoint(layout: WorldSceneryLayout, right: Bool, y: CGFloat) -> CGPoint {
        let end = layout.height - layout.routeOffset - 70
        let roadside = layout.centerX(at: y) + (right ? 1 : -1) *
            (74 + sin(y / 53) * 4 + sin(y / 21) * 2) * layout.scale
        let outside = right ? layout.width + 45 : -45
        if let fadeIn = broadEntrance(layout: layout, sectionY: y + layout.routeOffset) {
            let exit = min(1, max(0, (end - y) / 180))
            let fadeOut = exit * exit * (3 - 2 * exit)
            return CGPoint(x: outside + (roadside - outside) * min(fadeIn, fadeOut), y: y)
        }
        let start = -layout.routeOffset + 90
        let fade = min(1, max(0, min((y - start) / 185, (end - y) / 180)))
        return CGPoint(x: outside + (roadside - outside) * fade * fade * (3 - 2 * fade), y: y)
    }

    /// Every block has its own finished silhouette. Fit the entire block on
    /// the bank instead of cutting facets against the curved shoreline.
    static func terrainSlabs(layout: WorldSceneryLayout) -> [TerrainSlab] {
        let s = layout.scale
        // iPad blocks stay a little smaller and begin at the top, so the
        // entrance streams sit in the same basalt as the bends below.
        let unit = isBroad(layout.width) ? s * 0.82 : s
        let start = isBroad(layout.width) ? -layout.routeOffset + 12 : -layout.routeOffset + 150
        let end = layout.height - layout.routeOffset - 120
        var result: [TerrainSlab] = []
        for right in [false, true] {
            for row in 0..<max(1, Int((end - start) / (72 * unit))) {
                let y = start + CGFloat(row) * 72 * unit
                let halfH = (35 + CGFloat(row % 4) * 4) * unit
                let edges = (0...12).map { index in
                    bankPoint(layout: layout, right: right,
                              y: y - halfH + 2 * halfH * CGFloat(index) / 12).x
                }
                let inner = right ? max(0, edges.max()! + 6 * s) : min(layout.width, edges.min()! - 6 * s)
                let available = right ? layout.width - 4 * s - inner : inner - 4 * s
                guard available > 43 * unit else { continue }
                let halfW = min((40 + CGFloat(row % 3) * 5) * unit, (available - 6 * s) / 2)
                let columns = max(1, Int(available / (halfW * 1.8)))
                for column in 0..<columns {
                    let x = right ? inner + halfW + CGFloat(column) * (halfW * 1.8)
                                  : inner - halfW - CGFloat(column) * (halfW * 1.8)
                    guard x - halfW >= 3 * s, x + halfW <= layout.width - 3 * s else { continue }
                    let local: [CGPoint] = [.init(x: -0.94, y: 0.18), .init(x: -0.78, y: -0.55),
                        .init(x: -0.26, y: -0.97), .init(x: 0.35, y: -0.90), .init(x: 1, y: -0.30),
                        .init(x: 0.87, y: 0.60), .init(x: 0.12, y: 0.95), .init(x: -0.72, y: 0.68)]
                    result.append(TerrainSlab(points: local.map { CGPoint(x: x + $0.x * halfW, y: y + $0.y * halfH) },
                                              variation: row * 13 + column * 7, right: right))
                }
            }
        }
        return result
    }

    /// Arc-length samples let a soft tongue of lava travel along a bend.
    /// Geometry is prepared outside the animation closure and shared by tiles.
    struct FlowLine {
        let points: [CGPoint]
        let distances: [CGFloat]
        var length: CGFloat { distances.last ?? 0 }

        init(_ path: Path) {
            var points: [CGPoint] = []
            path.forEach { element in
                switch element {
                case .move(to: let point), .line(to: let point): points.append(point)
                case .quadCurve(to: let end, control: let control):
                    guard let start = points.last else { return }
                    for index in 1...18 {
                        let t = CGFloat(index) / 18, u = 1 - t
                        points.append(CGPoint(x: u*u*start.x + 2*u*t*control.x + t*t*end.x,
                                              y: u*u*start.y + 2*u*t*control.y + t*t*end.y))
                    }
                case .curve(to: let end, control1: let c1, control2: let c2):
                    guard let start = points.last else { return }
                    for index in 1...24 {
                        let t = CGFloat(index) / 24, u = 1 - t
                        points.append(CGPoint(x: u*u*u*start.x + 3*u*u*t*c1.x + 3*u*t*t*c2.x + t*t*t*end.x,
                                              y: u*u*u*start.y + 3*u*u*t*c1.y + 3*u*t*t*c2.y + t*t*t*end.y))
                    }
                case .closeSubpath: break
                }
            }
            var distances: [CGFloat] = points.isEmpty ? [] : [0]
            for index in points.indices.dropFirst() {
                distances.append(distances[index - 1] + hypot(points[index].x - points[index - 1].x,
                                                               points[index].y - points[index - 1].y))
            }
            self.points = points
            self.distances = distances
        }

        func section(from start: CGFloat, to end: CGFloat) -> (path: Path, tail: CGPoint, head: CGPoint)? {
            guard points.count > 1, end > start, end > 0, start < length else { return nil }
            func sample(_ distance: CGFloat) -> (index: Int, point: CGPoint) {
                let distance = min(length, max(0, distance))
                var low = 1, high = distances.count - 1
                while low < high {
                    let mid = (low + high) / 2
                    if distances[mid] < distance { low = mid + 1 } else { high = mid }
                }
                let t = (distance - distances[low - 1]) / max(0.001, distances[low] - distances[low - 1])
                return (low, CGPoint(x: points[low - 1].x + (points[low].x - points[low - 1].x) * t,
                                     y: points[low - 1].y + (points[low].y - points[low - 1].y) * t))
            }
            let tail = sample(start), head = sample(end)
            var path = Path(); path.move(to: tail.point)
            if tail.index < head.index {
                for index in tail.index..<head.index { path.addLine(to: points[index]) }
            }
            path.addLine(to: head.point)
            return (path, tail.point, head.point)
        }
    }

    static func channelLanes(width: CGFloat) -> [CGFloat] {
        if isBroad(width) {
            return [-13, -10, -7.2, -4.6, -2.2, 0, 2.2, 4.6, 7.2, 10, 13]
        }
        return [-9, -6, -3, 0, 3, 6, 9]
    }

    static func channelWidth(lane: CGFloat, scale: CGFloat, width: CGFloat = 390) -> CGFloat {
        if !isBroad(width) {
            return (lane == 0 ? 4.2 : abs(lane) == 3 ? 1.2 : abs(lane) == 6 ? 0.8 : 0.6) * scale
        }
        let magnitude = abs(lane)
        let base: CGFloat
        if magnitude < 0.5 { base = 5.2 }
        else if magnitude <= 2.4 { base = 1.85 }
        else if magnitude <= 5 { base = 1.35 }
        else if magnitude <= 8 { base = 1.05 }
        else { base = 0.85 }
        return base * scale
    }

    static func channelBedWidth(scale: CGFloat, width: CGFloat) -> CGFloat {
        (isBroad(width) ? 44 : 27) * scale
    }

    /// Every slope drains through its visible foot into the nearest side river.
    /// The final control point approaches from the outer bank along the river.
    static func tributaries(layout: WorldSceneryLayout) -> [Tributary] {
        let s = layout.scale
        return sources(layout: layout).map { source in
            let right = source.point.x > layout.width / 2
            let start = source.outlet
            let river = channelPoint(layout: layout, right: right, y: source.point.y)
            var drop = min(148 * s, max(64 * s, abs(start.x - river.x) * 0.42 + 32 * s))
            if source.id == 4 {
                drop = min(drop, 1675 - 150 * s - source.point.y - 8 * s)
            }
            let endY = source.point.y + drop
            let merge = min(30 * s, max(8 * s, (endY - start.y) * 0.35))
            let entry = channelPoint(layout: layout, right: right, y: endY - merge)
            let before = channelPoint(layout: layout, right: right, y: entry.y - 1)
            let after = channelPoint(layout: layout, right: right, y: entry.y + 1)
            let dx = after.x - before.x, dy = after.y - before.y
            let length = max(0.001, hypot(dx, dy))
            let approach = min(24 * s, max(4 * s, (entry.y - start.y) * 0.6))
            let c1 = CGPoint(x: start.x, y: start.y + (entry.y - start.y) * 0.65)
            let c2 = CGPoint(x: entry.x - dx / length * approach, y: entry.y - dy / length * approach)
            var points = (0...48).map { index -> CGPoint in
                let t = CGFloat(index) / 48, u = 1 - t
                return CGPoint(x: u*u*u*start.x + 3*u*u*t*c1.x + 3*u*t*t*c2.x + t*t*t*entry.x,
                               y: u*u*u*start.y + 3*u*u*t*c1.y + 3*u*t*t*c2.y + t*t*t*entry.y)
            }
            for index in 1...16 {
                points.append(channelPoint(layout: layout, right: right, y: entry.y + merge * CGFloat(index) / 16))
            }
            return Tributary(id: source.id, points: points)
        }
    }

    /// Fine rivulets share an outlet instead of ending in an isolated puddle.
    static func slopeFlow(lane: CGFloat = 0) -> Path {
        Path { flow in
            flow.move(to: CGPoint(x: 7 + lane * 9, y: -218))
            flow.addCurve(to: CGPoint(x: 7 + lane * 26, y: -129),
                          control1: CGPoint(x: -8 + lane * 18, y: -184),
                          control2: CGPoint(x: 22 + lane * 25, y: -160))
            if lane == 0 {
                flow.addCurve(to: CGPoint(x: 16, y: 5),
                              control1: CGPoint(x: -9, y: -82), control2: CGPoint(x: 31, y: -38))
                flow.addQuadCurve(to: CGPoint(x: 16, y: 32), control: CGPoint(x: 16, y: 24))
            } else {
                // Smaller rills rejoin at different heights, rather than
                // outlining the cone with five identical curves to the foot.
                let t: CGFloat = abs(lane) > 1 ? (lane < 0 ? 0.38 : 0.22) : (lane < 0 ? 0.82 : 0.66)
                let u = 1 - t
                let join = CGPoint(x: u*u*u*7 - 3*u*u*t*9 + 3*u*t*t*31 + t*t*t*16,
                                   y: -u*u*u*129 - 3*u*u*t*82 - 3*u*t*t*38 + t*t*t*5)
                flow.addCurve(to: join,
                              control1: CGPoint(x: 7 + lane * 34, y: (-129 + join.y) / 2),
                              control2: CGPoint(x: join.x - 1, y: join.y - 15))
            }
        }
    }
    private final class RockField {
        let rocks: [LooseRock]
        init(_ rocks: [LooseRock]) { self.rocks = rocks }
    }
    private static let rockFields: NSCache<NSString, RockField> = {
        let cache = NSCache<NSString, RockField>()
        cache.countLimit = 8
        return cache
    }()

    /// Scatter on dry ground instead of snapping every group to the river bank.
    /// These same silhouettes are reused by the static art and occlusion masks.
    static func looseRocks(layout: WorldSceneryLayout) -> [LooseRock] {
        let key = "\(layout.width):\(layout.height):\(layout.routeOffset)" as NSString
        if let field = rockFields.object(forKey: key) { return field.rocks }
        let s = layout.scale
        let broad = isBroad(layout.width)
        // Wide maps keep boulders closer to phone size so the cones stay the landmarks.
        let stone = broad ? max(0.74, 0.90 - (layout.width - 520) / 2600) : 1
        var exclusions: [CGRect] = []
        let rivers = [false, true].map { channel(layout: layout, right: $0, from: -layout.routeOffset,
                                               to: layout.height - layout.routeOffset) }
        for (index, river) in (rivers + tributaries(layout: layout).map(\.path)).enumerated() {
            var previous: CGPoint? = nil
            river.forEach { element in
                switch element {
                case .move(to: let point): previous = point
                case .line(to: let point):
                    if let start = previous {
                        exclusions.append(CGRect(x: min(start.x, point.x), y: min(start.y, point.y),
                                                 width: abs(start.x - point.x), height: abs(start.y - point.y))
                            .insetBy(dx: (index < 2 ? -18 : -7) * s, dy: (index < 2 ? -18 : -7) * s))
                    }
                    previous = point
                default: break
                }
            }
        }
        for source in sources(layout: layout) {
            exclusions += source.terrainBands.map { $0.insetBy(dx: -8 * s, dy: -8 * s) }
        }
        exclusions.append(CGRect(x: layout.width - 174 * s, y: 1490, width: 190 * s, height: 225))
        // A fixed sequence gives a natural distribution which stays put while scrolling.
        var state: UInt32 = 0xB45A17
        func random() -> CGFloat {
            state = state &* 1_664_525 &+ 1_013_904_223
            return CGFloat(state >> 8) / CGFloat(0x00FF_FFFF)
        }
        var rocks: [LooseRock] = []
        let target = max(110, Int(layout.width / (broad ? 4.6 : 5.6)))
        let top = broad ? -layout.routeOffset + 24 : 112
        let span = max(1, layout.height - layout.routeOffset - (broad ? 250 : 340) - top)
        for attempt in 0..<(target * 160) {
            let point = CGPoint(x: 8 + random() * (layout.width - 16),
                                y: top + random() * span)
            // Boulders establish the terrain; small rubble fills the dry gaps.
            let size: CGFloat
            if attempt < target * 3 { size = 0.32 + random() * 0.40 }
            else if attempt < target * 8 { size = 0.20 + random() * 0.22 }
            else { size = 0.12 + random() * 0.19 }
            let rock = LooseRock(point: point, size: s * stone * size, variation: attempt)
            let frame = rock.bounds
            let clearsRoad = (0...8).allSatisfy { index in
                let y = frame.minY + frame.height * CGFloat(index) / 8
                let road = layout.centerX(at: y)
                return frame.maxX < road - 57 * s || frame.minX > road + 57 * s
            }
            guard clearsRoad, frame.minX >= 3 * s, frame.maxX <= layout.width - 3 * s,
                  !exclusions.contains(where: { $0.intersects(frame) }),
                  !rocks.contains(where: { $0.bounds.insetBy(dx: -4 * s, dy: -5 * s).intersects(frame) }) else { continue }
            rocks.append(rock)
            if rocks.count == target { break }
        }
        rockFields.setObject(RockField(rocks), forKey: key)
        return rocks
    }

    private final class SourceField {
        let sources: [Source]
        init(_ sources: [Source]) { self.sources = sources }
    }
    private static let sourceFields: NSCache<NSString, SourceField> = {
        let cache = NSCache<NSString, SourceField>()
        cache.countLimit = 8
        return cache
    }()

    static func sources(layout: WorldSceneryLayout) -> [Source] {
        let key = "\(layout.width):\(layout.height):\(layout.routeOffset)" as NSString
        if let field = sourceFields.object(forKey: key) { return field.sources }
        let s = layout.scale, w = layout.width
        let firstY = -layout.routeOffset - 80
        let step: CGFloat = 12
        var rows = Array(repeating: [CGRect](), count: Int(ceil((layout.height + 160) / step)) + 1)
        func reserve(_ path: Path, margin: CGFloat) {
            var previous: CGPoint? = nil
            path.forEach { element in
                switch element {
                case .move(to: let point): previous = point
                case .line(to: let point):
                    if let start = previous {
                        let rect = CGRect(x: min(start.x, point.x), y: min(start.y, point.y),
                                          width: abs(start.x - point.x), height: abs(start.y - point.y))
                            .insetBy(dx: -margin, dy: -margin)
                        let first = max(0, Int(floor((rect.minY - firstY) / step)))
                        let last = min(rows.count - 1, Int(ceil((rect.maxY - firstY) / step)))
                        if first <= last { for row in first...last { rows[row].append(rect) } }
                    }
                    previous = point
                default: break
                }
            }
        }
        for right in [false, true] {
            reserve(channel(layout: layout, right: right, from: -layout.routeOffset,
                            to: layout.height - layout.routeOffset), margin: 23 * s)
        }
        var road = Path()
        for index in 0...Int(ceil(layout.height / 6)) {
            let y = -layout.routeOffset + CGFloat(index) * 6
            let point = CGPoint(x: layout.centerX(at: y), y: y)
            if index == 0 { road.move(to: point) } else { road.addLine(to: point) }
        }
        reserve(road, margin: 55 * s)
        let boss = CGRect(x: w - 155 * s, y: 1675 - 150 * s, width: 172 * s, height: 178 * s)
        // On a broad bank the final cone sits higher, leaving room for its
        // tributary to descend before the boss clearing instead of running flat.
        let finalBendY: CGFloat = w >= 600 ? 1380 : 1428
        // Phones stay on the 1.08 cap. Extra iPad width goes into the cones.
        let boost = coneBoost(w)
        let phoneFactors: [CGFloat] = [1.08, 1, 0.94, 0.88, 0.82]
        let factors = boost > 1
            ? [1.08, 1, 0.94, 0.88, 0.80, 0.72].map { $0 * boost } + phoneFactors
            : phoneFactors
        var result: [Source] = []
        for (id, kind, y, right, baseSize): (Int, Kind, CGFloat, Bool, CGFloat) in [
            (0, .summit, 112, true, 0.72), (1, .summit, 430, false, 0.74),
            (2, .summit, 780, true, 0.72), (3, .summit, 1130, false, 0.76),
            (4, .summit, finalBendY, true, 0.72)
        ] {
            var chosen: Source? = nil
            // The closer river leaves broad outer clearings for full-size cones.
            // Search the bend before allowing a small adjustment in their size.
            search: for factor: CGFloat in factors {
                for dy: CGFloat in [0, -24, 24, -48, 48, -72, 72, -96, 96] {
                    for candidate in 0..<45 {
                        let offset = candidate == 0 ? 0 : CGFloat((candidate + 1) / 2) * 9 * s * (candidate % 2 == 0 ? 1 : -1)
                        let anchor: CGFloat = boost > 1 ? (right ? 0.84 : 0.16) : (right ? 0.86 : 0.14)
                        let x = w * anchor + offset
                        let source = Source(id: id, kind: kind, point: CGPoint(x: x, y: y + dy),
                                            size: baseSize * s * factor, mirrored: !right)
                        let bands = source.terrainBands
                        let body = bands.reduce(CGRect.null) { $0.union($1) }
                        let visible = body.intersection(CGRect(x: 0, y: -layout.routeOffset, width: w, height: layout.height))
                        // Broad flanks may continue past the screen edge, while
                        // the crater stays visible in the outside of the bend.
                        guard !visible.isNull, visible.width >= body.width * 0.60,
                              x >= 18 * s, x <= w - 18 * s,
                              !body.intersects(boss),
                              !result.contains(where: { $0.terrainBands.contains(where: { $0.insetBy(dx: -9 * s, dy: -12 * s).intersects(body) }) }) else { continue }
                        let dry = bands.allSatisfy { band in
                            let first = max(0, Int(floor((band.minY - firstY) / step)) - 1)
                            let last = min(rows.count - 1, Int(ceil((band.maxY - firstY) / step)) + 1)
                            guard first <= last else { return false }
                            return (first...last).allSatisfy { row in
                                !rows[row].contains(where: { $0.intersects(band) })
                            }
                        }
                        if dry { chosen = source; break search }
                    }
                }
            }
            if let chosen { result.append(chosen) }
        }
        sourceFields.setObject(SourceField(result), forKey: key)
        return result
    }

    /// Grow cones with spare iPad width. The scenery scale itself stays capped,
    /// so phone maps and the trail keep their present size.
    static func coneBoost(_ width: CGFloat) -> CGFloat {
        let t = min(1, max(0, (width - 520) / 340))
        return 1 + t * 0.55
    }

    static func channelPoint(layout: WorldSceneryLayout, right: Bool, y: CGFloat) -> CGPoint {
        let sectionY = y + layout.routeOffset
        let outside: CGFloat = right ? layout.width + 75 : -75
        let wander = sin(y / 97 + (right ? 1.8 : 0)) * 6 + sin(y / 43) * 3
        let bank = layout.centerX(at: y) + (right ? 1 : -1) * (102 + wander) * layout.scale
        if let fadeIn = broadEntrance(layout: layout, sectionY: sectionY) {
            let exit = min(1, max(0, (layout.height - 110 - sectionY) / 210))
            let fadeOut = exit * exit * (3 - 2 * exit)
            return CGPoint(x: outside + (bank - outside) * min(fadeIn, fadeOut), y: y)
        }
        let entry = right ? (sectionY + 250) / 360 : (sectionY - 110) / 110
        let blend = min(1, max(0, min(entry, (layout.height - 110 - sectionY) / 210)))
        return CGPoint(x: outside + (bank - outside) * blend * blend * (3 - 2 * blend), y: y)
    }

    /// Channels leave through the sides before either chapter boundary.
    static func channel(layout: WorldSceneryLayout, right: Bool, from start: CGFloat, to end: CGFloat, lane: CGFloat = 0) -> Path {
        Path { path in
            let count = max(1, Int(ceil((end - start) / 10)))
            for i in 0...count {
                let y = start + (end - start) * CGFloat(i) / CGFloat(count)
                var point = channelPoint(layout: layout, right: right, y: y)
                if lane != 0 {
                    let before = channelPoint(layout: layout, right: right, y: y - 0.5)
                    let after = channelPoint(layout: layout, right: right, y: y + 0.5)
                    let dx = after.x - before.x, dy = after.y - before.y
                    let length = max(0.001, hypot(dx, dy))
                    let drift = (sin(y / 71 + lane * 0.45) * 0.55 + sin(y / 31 + lane * 0.7) * 0.28) * layout.scale
                    // Side fissures branch and merge along the bank instead of
                    // forming evenly spaced rails beside the central flow.
                    let spread = 0.12 + 0.88 * pow(sin(y / 113 + abs(lane) / layout.scale * 0.21), 2)
                    let offset = (lane + drift) * spread
                    point.x += dy / length * offset
                    point.y -= dx / length * offset
                }
                if i == 0 { path.move(to: point) }
                else { path.addLine(to: point) }
            }
        }
    }
}

/// The right lava inlet crosses the chapter join in one coordinate system.
/// Repainting the 32pt terrain blend preserves both its colour and moving fronts.
private struct SleepVolcanoInlet: View {
    let routeOffset: CGFloat
    let viewportHeight: CGFloat
    let sectionStart: CGFloat
    var fixedTime: TimeInterval? = nil
    var frozen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false

    var body: some View {
        GeometryReader { geometry in
            let clearance = routeOffset - WorldRouteTrail.bannerHeight - WorldRouteTrail.bannerTopPadding - WorldRouteTrail.bannerBottomPadding
            let height = routeOffset + WorldRouteTrail.chapterRouteHeight(topClearance: clearance, worldID: 3)
            let layout = WorldSceneryLayout(width: geometry.size.width, height: height, routeOffset: routeOffset)
            let lanes = VolcanoWorldLayout.channelLanes(width: geometry.size.width)
            let lines = lanes.map { lane in
                VolcanoWorldLayout.FlowLine(VolcanoWorldLayout.channel(layout: layout, right: true,
                    from: -routeOffset - 220, to: height - routeOffset, lane: lane * layout.scale))
            }
            ZStack {
                Canvas { context, _ in
                    var c = context; c.translateBy(x: 0, y: routeOffset - sectionStart)
                    VolcanoWorldPainter(context: c).boundaryFlow(layout: layout, right: true,
                        from: -routeOffset - 220, to: height - routeOffset)
                }
                TimelineView(.animation(minimumInterval: 1.0 / 20,
                                        paused: fixedTime != nil || frozen || reduceMotion || !visible || scenePhase != .active)) { timeline in
                    Canvas { context, _ in
                        var c = context; c.translateBy(x: 0, y: routeOffset - sectionStart)
                        let time = frozen || reduceMotion ? 0 : (fixedTime ?? timeline.date.timeIntervalSinceReferenceDate)
                        VolcanoLifePainter(context: c, time: time, seed: 0)
                            .channels(lines: lines, scale: layout.scale, lanes: lanes,
                                      mapWidth: geometry.size.width, indexOffset: lanes.count)
                    }
                }
            }
        }
        .onGeometryChange(for: Bool.self) { proxy in
            let frame = proxy.frame(in: .named("adventure.map.viewport"))
            return frame.maxY > 0 && frame.minY < viewportHeight
        } action: { visible = $0 }
        .clipped().allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Leave the right inlet visible beneath the terrain fade, rather than painting it twice.
private struct VolcanoInletOpening: View {
    let routeOffset: CGFloat
    var body: some View {
        GeometryReader { geometry in
            let clearance = routeOffset - WorldRouteTrail.bannerHeight - WorldRouteTrail.bannerTopPadding - WorldRouteTrail.bannerBottomPadding
            let height = routeOffset + WorldRouteTrail.chapterRouteHeight(topClearance: clearance, worldID: 3)
            let layout = WorldSceneryLayout(width: geometry.size.width, height: height, routeOffset: routeOffset)
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
                var c = context; c.translateBy(x: 0, y: routeOffset); c.blendMode = .destinationOut
                VolcanoWorldPainter(context: c).boundaryFlow(layout: layout, right: true,
                    from: -routeOffset - 220, to: height - routeOffset)
            }
        }
    }
}

/// Static terrain stays cached; only these small, visible effect surfaces tick.
private struct VolcanoWorldLife: View {
    let routeOffset: CGFloat
    let viewportHeight: CGFloat
    var fixedTime: TimeInterval? = nil
    var frozen = false

    var body: some View {
        GeometryReader { geometry in
            let layout = WorldSceneryLayout(width: geometry.size.width, height: geometry.size.height, routeOffset: routeOffset)
            let sources = VolcanoWorldLayout.sources(layout: layout)
            ZStack(alignment: .topLeading) {
                ForEach(0..<Int(ceil(geometry.size.height / 320)), id: \.self) { index in
                    let frame = CGRect(x: 0, y: CGFloat(index) * 320, width: geometry.size.width,
                                       height: min(320, geometry.size.height - CGFloat(index) * 320))
                    VolcanoLifeSurface(layout: layout, frame: frame, viewportHeight: viewportHeight,
                                       fixedTime: fixedTime, frozen: frozen)
                        .mask(VolcanoDepthOcclusion(layout: layout, frame: frame, depth: -.infinity))
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                }
                ForEach(sources) { source in
                    let frame = source.bounds.offsetBy(dx: 0, dy: routeOffset)
                    VolcanoLifeSurface(layout: layout, frame: frame, viewportHeight: viewportHeight,
                                       source: source, fixedTime: fixedTime, frozen: frozen)
                        .mask(VolcanoDepthOcclusion(layout: layout, frame: frame, depth: source.point.y + routeOffset))
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                }
            }
        }.clipped().allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct VolcanoDepthOcclusion: View {
    let layout: WorldSceneryLayout
    let frame: CGRect
    let depth: CGFloat
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
            var c = context
            c.translateBy(x: -frame.minX, y: layout.routeOffset - frame.minY)
            c.blendMode = .destinationOut
            let scene = WorldSceneryDepth(minimumDepth: depth, visibleBounds: frame)
            VolcanoWorldPainter(context: c, depth: scene, depthOffset: layout.routeOffset).appendScenery(layout: layout)
            let bossPoint = CGPoint(x: layout.width - 79 * layout.scale, y: 1675)
            if bossPoint.y + layout.routeOffset > depth {
                WorldBossPainter(context: c).draw(worldID: 3, at: bossPoint, size: layout.scale * 0.88)
            }
            scene.draw()
            // Keep effects clear of the entire bend, including the level rims.
            var road = Path()
            let start = frame.minY - layout.routeOffset - 10
            let count = max(1, Int(ceil((frame.height + 20) / 8)))
            for i in 0...count {
                let y = start + CGFloat(i) * (frame.height + 20) / CGFloat(count)
                let point = CGPoint(x: layout.centerX(at: y), y: y)
                if i == 0 { road.move(to: point) } else { road.addLine(to: point) }
            }
            c.stroke(road, with: .color(.white), style: StrokeStyle(lineWidth: 106 * layout.scale, lineCap: .round, lineJoin: .round))
        }
    }
}

private struct VolcanoLifeSurface: View {
    let layout: WorldSceneryLayout
    let frame: CGRect
    let viewportHeight: CGFloat
    var source: VolcanoWorldLayout.Source? = nil
    var fixedTime: TimeInterval? = nil
    var frozen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false

    var body: some View {
        let lanes = VolcanoWorldLayout.channelLanes(width: layout.width)
        let channels = source == nil ? [false, true].flatMap { right in
            lanes.map { lane in
                VolcanoWorldLayout.FlowLine(VolcanoWorldLayout.channel(layout: layout, right: right,
                                           from: -layout.routeOffset - (right ? 220 : 0), to: layout.height - layout.routeOffset,
                                           lane: lane * layout.scale))
            }
        } : []
        let tributaries = source == nil ? VolcanoWorldLayout.tributaries(layout: layout).map { VolcanoWorldLayout.FlowLine($0.path) } : []
        let slopes = source?.kind == .summit ? [-1.5, -0.75, 0, 0.75, 1.5].map {
            VolcanoWorldLayout.FlowLine(VolcanoWorldLayout.slopeFlow(lane: $0))
        } : []
        TimelineView(.animation(minimumInterval: 1.0 / 20,
                                paused: fixedTime != nil || frozen || reduceMotion || !visible || scenePhase != .active)) { timeline in
            Canvas { context, _ in
                var c = context
                c.translateBy(x: -frame.minX, y: layout.routeOffset - frame.minY)
                let time = frozen || reduceMotion ? 0 : (fixedTime ?? timeline.date.timeIntervalSinceReferenceDate)
                if let source {
                    c.translateBy(x: source.point.x, y: source.point.y)
                    c.scaleBy(x: source.mirrored ? -source.size : source.size, y: source.size)
                    VolcanoLifePainter(context: c, time: time, seed: source.id).source(source.kind, slopes: slopes)
                } else {
                    let painter = VolcanoLifePainter(context: c, time: time, seed: 0)
                    painter.channels(lines: channels, scale: layout.scale, lanes: lanes, mapWidth: layout.width)
                    painter.tributaries(tributaries, scale: layout.scale)
                }
            }
        }
        .onGeometryChange(for: Bool.self) { proxy in
            let rect = proxy.frame(in: .named("adventure.map.viewport"))
            return rect.maxY > 0 && rect.minY < viewportHeight
        } action: { visible = $0 }
    }
}

private struct VolcanoLifePainter {
    let context: GraphicsContext
    let time: TimeInterval
    let seed: Int

    private func cycle(_ duration: Double, offset: Double = 0) -> Double {
        (time / duration + offset + Double(seed) * 0.137).truncatingRemainder(dividingBy: 1)
    }
    private func halo(at point: CGPoint, radius: CGFloat, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: 0xFFB94E).opacity(opacity), .clear]),
                                           center: point, startRadius: 0, endRadius: radius))
    }
    private func stroke(_ path: Path, width: CGFloat, opacity: Double, dash: [CGFloat] = [], speed: Double = 0) {
        let shading = GraphicsContext.Shading.color(Color(dinoHex: 0xFFF0A6).opacity(opacity))
        if speed > 0, dash.contains(where: { $0 > 0 }) {
            let period = max(1, dash.reduce(0, +))
            var cursor: CGFloat = 0
            var index = 0
            while index < dash.count {
                let mark = dash[index]
                let gap = index + 1 < dash.count ? dash[index + 1] : 0
                if mark > 0 {
                    DownstreamFlow.marks(path, in: context, shading: shading, width: width,
                                         time: time + Double(cursor) / speed,
                                         pointsPerSecond: speed, dash: mark, gap: max(1, period - mark))
                }
                cursor += mark + gap
                index += 2
            }
            return
        }
        context.stroke(path, with: shading, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash))
    }

    private func flowing(_ line: VolcanoWorldLayout.FlowLine, width: CGFloat, speed: Double,
                         spacing: CGFloat, tongue: CGFloat, offset: Double, intensity: Double) {
        guard line.length > 0 else { return }
        let count = max(1, Int(ceil(line.length / spacing)))
        let period = CGFloat(count) * spacing
        for index in 0..<count {
            let head = (CGFloat(time * speed + offset) + CGFloat(index) * spacing)
                .truncatingRemainder(dividingBy: period)
            guard head <= line.length else { continue }
            // Cooler skin behind a hot rounded front makes the movement
            // readable without speeding up the liquid or widening the fissure.
            if let skin = line.section(from: head - tongue - 14, to: head - tongue * 0.35) {
                context.stroke(skin.path, with: .linearGradient(Gradient(colors: [
                    .clear, Color(dinoHex: 0x9E5039).opacity(0.62 * intensity), .clear
                ]), startPoint: skin.tail, endPoint: skin.head),
                    style: StrokeStyle(lineWidth: width * 1.25, lineCap: .round, lineJoin: .round))
            }
            guard let hot = line.section(from: head - tongue, to: head) else { continue }
            let glow = Gradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: Color(dinoHex: 0xFFAD4E).opacity(0.45 * intensity), location: 0.32),
                .init(color: Color(dinoHex: 0xFFE29A).opacity(0.90 * intensity), location: 0.72),
                .init(color: Color(dinoHex: 0xFFF5C7).opacity(intensity), location: 1)
            ])
            context.stroke(hot.path, with: .linearGradient(glow, startPoint: hot.tail, endPoint: hot.head),
                           style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        }
    }

    func channels(lines: [VolcanoWorldLayout.FlowLine], scale: CGFloat, lanes: [CGFloat], mapWidth: CGFloat, indexOffset: Int = 0) {
        for (localIndex, river) in lines.enumerated() {
            let index = localIndex + indexOffset
            let slot = index % lanes.count
            let lane = lanes[slot]
            let central = abs(lane) < 0.5
            let width = mapWidth < 520
                ? (central ? 2.8 : 0.8) * scale
                : VolcanoWorldLayout.channelWidth(lane: lane, scale: scale, width: mapWidth) * (central ? 0.62 : 0.72)
            flowing(river, width: width,
                    speed: 5.8 + Double(slot) * 0.16, spacing: (137 + CGFloat(slot) * 17) * scale,
                    tongue: (central ? 28 : 18) * scale, offset: Double(index) * 43.7,
                    intensity: central ? 1 : 0.64)
        }
    }

    func tributaries(_ feeders: [VolcanoWorldLayout.FlowLine], scale: CGFloat) {
        for (index, feeder) in feeders.enumerated() {
            flowing(feeder, width: 2.2 * scale, speed: 6 * Double(scale), spacing: 113 * scale,
                    tongue: 24 * scale, offset: Double(index) * 31.7, intensity: 0.96)
        }
    }

    func source(_ kind: VolcanoWorldLayout.Kind, slopes: [VolcanoWorldLayout.FlowLine]) {
        switch kind {
        case .crater:
            var flow = Path(); flow.move(to: CGPoint(x: 3, y: -96))
            flow.addCurve(to: CGPoint(x: 17, y: 16), control1: CGPoint(x: -15, y: -55), control2: CGPoint(x: 32, y: -20))
            stroke(flow, width: 1, opacity: 0.48, dash: [43, 68, 13, 82], speed: 5)
            halo(at: CGPoint(x: 0, y: -97), radius: 41, opacity: 0.22 + sin(time * 2.1 + Double(seed)) * 0.05)
            bubbles(at: CGPoint(x: 0, y: -97), spread: 17, count: 3)
            bubbles(at: CGPoint(x: 19, y: 19), spread: 31, count: 3)
            smoke(at: CGPoint(x: 0, y: -104), rise: 121, spread: 28, opacity: 0.54, count: 11)
            sparks(at: CGPoint(x: 0, y: -101), height: 49, spread: 35, count: 10)
        case .summit:
            for (index, slope) in slopes.enumerated() {
                flowing(slope, width: index == 2 ? 2.1 : 0.75, speed: 7,
                        spacing: 101 + CGFloat(index) * 13, tongue: 25,
                        offset: Double(seed) * 17.9 + Double(index) * 29.3,
                        intensity: index == 2 ? 1 : 0.72)
            }
            bubbles(at: CGPoint(x: 0, y: -219), spread: 15, count: 3)
            smoke(at: CGPoint(x: 0, y: -229), rise: 147, spread: 31, opacity: 0.47, count: 12)
            sparks(at: CGPoint(x: 0, y: -224), height: 48, spread: 31, count: 9)
        }
    }

    private func bubbles(at origin: CGPoint, spread: CGFloat, count: Int) {
        for i in 0..<count {
            let t = cycle(2.8 + Double(i % 3) * 0.6, offset: Double(i) * 0.217)
            let x = origin.x + sin(Double(i) * 6.7 + Double(seed)) * spread
            let y = origin.y + cos(Double(i) * 3.1) * 3
            let radius = CGFloat(2.4 + Double(i % 3) * 1.1)
            if t < 0.76 {
                let growth = sin(t / 0.76 * .pi / 2)
                let r = CGRect(x: x - radius * growth, y: y - radius * 1.45 * growth,
                               width: radius * 2 * growth, height: radius * 1.65 * growth)
                context.fill(Path(ellipseIn: r), with: .linearGradient(
                    Gradient(colors: [Color(dinoHex: 0xFFF3BD), Color(dinoHex: 0xFFBD56), Color(dinoHex: 0xE96534)]),
                    startPoint: CGPoint(x: x, y: r.minY), endPoint: CGPoint(x: x, y: r.maxY)))
                var rim = Path(); rim.addArc(center: CGPoint(x: x, y: y - radius * 0.3 * growth), radius: radius * growth * 0.7,
                                             startAngle: .degrees(202), endAngle: .degrees(285), clockwise: false)
                stroke(rim, width: 0.8, opacity: 0.9)
            } else {
                let pop = (t - 0.76) / 0.24
                let r = CGRect(x: x - radius * (1 + pop), y: y - radius * 0.25,
                               width: radius * (2 + pop * 2), height: radius * (0.7 + pop * 0.3))
                context.stroke(Path(ellipseIn: r), with: .color(Color(dinoHex: 0xFFF2B3).opacity(1 - pop)), lineWidth: 0.9)
                for side: CGFloat in [-1, 1] {
                    let dx = side * radius * (1 + pop * 2)
                    let dy = -sin(pop * .pi) * radius * 2
                    context.fill(Path(ellipseIn: CGRect(x: x + dx, y: y + dy, width: 1.4, height: 2.2)),
                                 with: .color(Color(dinoHex: 0xFFE598).opacity(1 - pop)))
                }
            }
        }
    }

    private func smoke(at origin: CGPoint, rise: CGFloat, spread: CGFloat, opacity: Double, count: Int) {
        // Soft lobes grow as they rise; every puff starts inside its own vent.
        for i in 0..<count {
            let t = cycle(6.7 + Double(i % 2) * 1.2, offset: Double(i) / Double(count))
            let center = CGPoint(x: origin.x + t * spread * 1.15 + sin(t * 7 + Double(i)) * spread * t * 0.45,
                                 y: origin.y - t * rise)
            let radius = 7 + t * 20
            let alpha = min(1, t * 9) * pow(1 - t, 0.7) * opacity
            for lobe in 0..<3 {
                let r = CGFloat(radius * (lobe == 1 ? 1.0 : 0.77))
                let x = center.x + CGFloat(lobe - 1) * r * 0.63
                let y = center.y + CGFloat(lobe % 2) * r * 0.34
                context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r * 0.72, width: r * 2, height: r * 1.45)),
                             with: .radialGradient(Gradient(stops: [
                                .init(color: Color(dinoHex: t < 0.18 ? 0xEFC1A0 : 0xB6A2AB).opacity(alpha), location: 0),
                                .init(color: Color(dinoHex: 0x897D95).opacity(alpha * 0.8), location: 0.65),
                                .init(color: Color(dinoHex: 0x9D8E9E).opacity(0), location: 1)
                             ]), center: CGPoint(x: x - r * 0.15, y: y - r * 0.16), startRadius: 0, endRadius: r))
            }
        }
    }

    private func sparks(at origin: CGPoint, height: CGFloat, spread: CGFloat, count: Int) {
        for i in 0..<count {
            let t = cycle(2.4 + Double(i % 3) * 0.31, offset: Double(i) / Double(count))
            let direction = sin(Double(i) * 12.3 + Double(seed))
            let point = CGPoint(x: origin.x + CGFloat(direction * t) * spread,
                                y: origin.y - CGFloat(4 * t * (1 - t)) * height)
            let alpha = min(1, t * 12) * (1 - t)
            halo(at: point, radius: 4.3, opacity: alpha * 0.22)
            context.fill(Path(ellipseIn: CGRect(x: point.x, y: point.y, width: 1.3, height: 2.6)),
                         with: .color(Color(dinoHex: 0xFFE79C).opacity(alpha)))
        }
    }
}

/// Warm basalt, lava terraces and a distant summit are scoped to world three.
private struct VolcanoWorldPainter {
    let context: GraphicsContext
    var scenery: WorldSceneryLayout? = nil
    var depth: WorldSceneryDepth? = nil
    var depthOffset: CGFloat = 0

    private func at(_ point: CGPoint, size: CGFloat = 1, mirror: Bool = false, radius: CGFloat = 0, rise: CGFloat = 0, draw: @escaping (VolcanoWorldPainter) -> Void) {
        let point = scenery?.position(point, radius: radius, rise: rise) ?? point
        var c = context; c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: mirror ? -size : size, y: size)
        if let depth {
            depth.add(at: depthOffset + point.y,
                      bounds: CGRect(x: point.x - 185 * size, y: depthOffset + point.y - 410 * size,
                                     width: 370 * size, height: 480 * size)) { draw(.init(context: c)) }
        } else { draw(.init(context: c)) }
    }
    private func material(_ path: Path, colors: [UInt32]) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
    }
    private func contour(_ points: [CGPoint], radius: CGFloat = 5) -> Path {
        guard points.count > 2 else { return Path() }
        // Keep the basalt facets, with worn corners instead of razor-cut tips.
        func approach(_ corner: CGPoint, from point: CGPoint) -> CGPoint {
            let distance = hypot(point.x - corner.x, point.y - corner.y)
            let t = min(0.3, radius / max(0.01, distance))
            return CGPoint(x: corner.x + (point.x - corner.x) * t, y: corner.y + (point.y - corner.y) * t)
        }
        return Path { path in
            for i in points.indices {
                let corner = points[i]
                let before = approach(corner, from: points[(i + points.count - 1) % points.count])
                let after = approach(corner, from: points[(i + 1) % points.count])
                if i == 0 { path.move(to: before) } else { path.addLine(to: before) }
                path.addQuadCurve(to: after, control: corner)
            }
            path.closeSubpath()
        }
    }
    private func polygon(_ points: [CGPoint], colors: [UInt32]) {
        material(contour(points), colors: colors)
    }
    private func oval(_ r: CGRect, colors: [UInt32]) {
        context.fill(Path(ellipseIn: r), with: .radialGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                            center: CGPoint(x: r.minX + r.width * 0.32, y: r.minY + r.height * 0.22),
                                                            startRadius: 0, endRadius: max(r.width, r.height) * 0.85))
    }
    private func line(_ points: [CGPoint], color: UInt32, width: CGFloat, opacity: Double = 1) {
        var p = Path(); p.addLines(points)
        context.stroke(p, with: .color(Color(dinoHex: color).opacity(opacity)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func glow(_ point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), Color(dinoHex: color).opacity(0)]),
                                           center: point, startRadius: 0, endRadius: radius))
    }
    private func ground(at point: CGPoint, width: CGFloat, height: CGFloat, color: UInt32 = 0x706776, opacity: Double = 0.24) {
        var c = context
        c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: width / 2, y: height / 2)
        c.fill(Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2)),
               with: .radialGradient(Gradient(stops: [
                .init(color: Color(dinoHex: color).opacity(opacity), location: 0),
                .init(color: Color(dinoHex: color).opacity(opacity * 0.7), location: 0.55),
                .init(color: .clear, location: 1)
               ]), center: .zero, startRadius: 0, endRadius: 1))
    }

    private func lava(_ path: Path, width: CGFloat, moving: Bool = false, temperature: ClosedRange<CGFloat>? = nil) {
        let r = path.boundingRect
        context.stroke(path, with: .color(Color(dinoHex: 0xF17A3A).opacity(0.12)), style: StrokeStyle(lineWidth: width + max(3, width * 1.2), lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(Color(dinoHex: 0x4A4353).opacity(0.65)), style: StrokeStyle(lineWidth: width + max(1, width * 0.65), lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFCF69), Color(dinoHex: 0xFF873E), Color(dinoHex: 0xE96736)]),
                                                  startPoint: CGPoint(x: r.midX, y: temperature?.lowerBound ?? r.minY),
                                                  endPoint: CGPoint(x: r.midX, y: temperature?.upperBound ?? r.maxY)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(Color(dinoHex: 0xFFE6A1).opacity(moving ? 0.23 : 0.85)), style: StrokeStyle(lineWidth: max(1, width * (moving ? 0.12 : 0.3)), lineCap: .round, lineJoin: .round))
    }

    func landscape(in size: CGSize, routeOffset: CGFloat, depth: WorldSceneryDepth) {
        let w = size.width, h = size.height
        let left: CGFloat = 0, right = w - left
        let scale = min(1.30, max(0.82, w / 390))
        let horizon = (routeOffset + 135) / h
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: 0xFFD1A1), location: 0),
            .init(color: Color(dinoHex: 0x9E8CA8), location: 0.035),
            .init(color: Color(dinoHex: 0xDDA08D), location: horizon * 0.55),
            .init(color: Color(dinoHex: 0xFFE0AB), location: horizon),
            .init(color: Color(dinoHex: 0xA48A80), location: 0.29),
            .init(color: Color(dinoHex: 0x7C6B70), location: 0.38),
            .init(color: Color(dinoHex: 0x685C68), location: 0.62),
            .init(color: Color(dinoHex: 0x78686B), location: 0.94),
            .init(color: Color(dinoHex: 0x9C9985), location: 0.975),
            .init(color: Color(dinoHex: 0xC7E8BE), location: 1)
        ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
        sky(width: w, left: left, right: right, height: routeOffset + 110, scale: scale)
        var c = context; c.translateBy(x: 0, y: routeOffset)
        let scenery = WorldSceneryLayout(width: w, height: h, routeOffset: routeOffset)
        let p = VolcanoWorldPainter(context: c, scenery: scenery, depth: depth, depthOffset: routeOffset)
        for i in 0..<6 {
            let y = CGFloat(i) * 290 + 20
            p.ground(at: CGPoint(x: i % 2 == 0 ? w * 0.04 : w * 0.96, y: y + 120),
                     width: w * 1.04, height: 310, color: i % 2 == 0 ? 0x807079 : 0x9B837B, opacity: 0.13)
            p.glow(CGPoint(x: w * 0.5, y: y + 90), radius: w * 0.35, color: 0xFFC38A, opacity: 0.07)
        }
        p.ashShoulders(layout: scenery)
        p.riverbeds(layout: scenery)
        p.appendScenery(layout: scenery)
        p.steam(at: CGPoint(x: w * 0.5, y: 1685), width: w * 1.1, opacity: 0.10)
    }

    /// Pale sandy ash keeps the existing light trail and level rims legible,
    /// while the surrounding ground belongs to the basalt landscape.
    private func ashShoulders(layout: WorldSceneryLayout) {
        let start = -layout.routeOffset - 12, end = layout.height - layout.routeOffset + 12
        let count = max(1, Int(ceil((end - start) / 8)))
        var left: [CGPoint] = [], right: [CGPoint] = []
        for index in 0...count {
            let y = start + (end - start) * CGFloat(index) / CGFloat(count)
            let half = (50 + sin(y / 61) * 3 + sin(y / 27) * 1.2) * layout.scale
            let center = layout.centerX(at: y)
            left.append(CGPoint(x: center - half, y: y)); right.append(CGPoint(x: center + half, y: y))
        }
        var shoulder = Path(); shoulder.addLines(left + right.reversed()); shoulder.closeSubpath()
        let h = layout.height
        context.fill(shoulder, with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: 0xE3CFAE), location: 0),
            .init(color: Color(dinoHex: 0xD2B995), location: 0.45),
            .init(color: Color(dinoHex: 0xCCB394), location: 0.94),
            .init(color: Color(dinoHex: 0xC7E8BE), location: 1)
        ]), startPoint: CGPoint(x: 0, y: -layout.routeOffset), endPoint: CGPoint(x: 0, y: h - layout.routeOffset)))
        for index in 0..<190 {
            let y = 8 + CGFloat(index) * 9.2
            guard y < 1700 else { break }
            let side: CGFloat = index % 2 == 0 ? 1 : -1
            let x = layout.centerX(at: y) + side * (31 + CGFloat(index * 7 % 15)) * layout.scale
            let radius = (0.45 + CGFloat(index % 4) * 0.22) * layout.scale
            context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y, width: radius * 2, height: radius)),
                         with: .color(Color(dinoHex: index % 3 == 0 ? 0xF6E0B9 : 0x927C70).opacity(0.32)))
        }
    }

    func appendScenery(layout: WorldSceneryLayout) {
        let placed = VolcanoWorldPainter(context: context, depth: depth, depthOffset: depthOffset)
        for rock in VolcanoWorldLayout.looseRocks(layout: layout) {
            placed.rubble(at: rock.point, size: rock.size, variation: rock.variation)
        }
        for source in VolcanoWorldLayout.sources(layout: layout) {
            // Coordinates have already passed through the shared clearance solver.
            if source.kind == .crater {
                placed.crater(at: source.point, size: source.size, mirror: source.mirrored)
            } else {
                placed.volcano(at: source.point, size: source.size, mirror: source.mirrored)
            }
        }
    }

    func boundaryFlow(layout: WorldSceneryLayout, right: Bool, from start: CGFloat, to end: CGFloat) {
        let temperature = (-layout.routeOffset)...(layout.height - layout.routeOffset)
        let bed = VolcanoWorldLayout.channel(layout: layout, right: right, from: start, to: end)
        context.stroke(bed, with: .color(Color(dinoHex: 0x3E384D).opacity(0.28)),
                       style: StrokeStyle(lineWidth: VolcanoWorldLayout.channelBedWidth(scale: layout.scale, width: layout.width), lineCap: .round, lineJoin: .round))
        for lane in VolcanoWorldLayout.channelLanes(width: layout.width) {
            let path = VolcanoWorldLayout.channel(layout: layout, right: right, from: start, to: end, lane: lane * layout.scale)
            var c = context; c.opacity = lane == 0 ? 1 : abs(lane) < 6 ? 0.78 : 0.55
            VolcanoWorldPainter(context: c).lava(path,
                width: VolcanoWorldLayout.channelWidth(lane: lane, scale: layout.scale, width: layout.width), moving: true, temperature: temperature)
        }
    }

    private func riverbeds(layout: WorldSceneryLayout) {
        for right in [false, true] {
            let start = VolcanoWorldLayout.isBroad(layout.width) ? -layout.routeOffset - 8 : -layout.routeOffset + 90
            let end = layout.height - layout.routeOffset - 70
            let count = max(1, Int((end - start) / 12))
            var bank = Path()
            for i in 0...count {
                let y = start + (end - start) * CGFloat(i) / CGFloat(count)
                let point = VolcanoWorldLayout.bankPoint(layout: layout, right: right, y: y)
                if i == 0 { bank.move(to: point) } else { bank.addLine(to: point) }
            }
            bank.addLine(to: CGPoint(x: right ? layout.width + 250 : -250, y: end))
            bank.addLine(to: CGPoint(x: right ? layout.width + 250 : -250, y: start)); bank.closeSubpath()
            material(bank, colors: [0x82717B, 0x4E495F, 0x5F5365, 0x8E7A74])
        }
        for slab in VolcanoWorldLayout.terrainSlabs(layout: layout) { terrainBlock(slab) }
        let temperature = (-layout.routeOffset)...(layout.height - layout.routeOffset)
        for right in [false, true] {
            let bed = VolcanoWorldLayout.channel(layout: layout, right: right,
                                                from: -layout.routeOffset, to: layout.height - layout.routeOffset)
            context.stroke(bed, with: .color(Color(dinoHex: 0x3E384D).opacity(0.28)),
                           style: StrokeStyle(lineWidth: VolcanoWorldLayout.channelBedWidth(scale: layout.scale, width: layout.width), lineCap: .round, lineJoin: .round))
        }
        // The downstream section lies on the main channel. Paint the latter
        // last, so no outlined end cap can protrude through the confluence.
        let flowScale = VolcanoWorldLayout.isBroad(layout.width) ? 1.22 : 1
        for tributary in VolcanoWorldLayout.tributaries(layout: layout) {
            lava(tributary.path, width: 3.1 * layout.scale * flowScale, moving: true, temperature: temperature)
        }
        for right in [false, true] {
            for lane in VolcanoWorldLayout.channelLanes(width: layout.width) {
                let fissure = VolcanoWorldLayout.channel(layout: layout, right: right,
                    from: -layout.routeOffset, to: layout.height - layout.routeOffset, lane: lane * layout.scale)
                var layer = context
                layer.opacity = lane == 0 ? 1 : abs(lane) < 6 ? 0.78 : 0.55
                VolcanoWorldPainter(context: layer).lava(fissure,
                    width: VolcanoWorldLayout.channelWidth(lane: lane, scale: layout.scale, width: layout.width), moving: true, temperature: temperature)
            }
        }
    }

    private func terrainBlock(_ slab: VolcanoWorldLayout.TerrainSlab) {
        let frame = slab.bounds
        ground(at: CGPoint(x: frame.midX, y: frame.maxY - 7), width: frame.width * 0.98,
               height: frame.height * 0.28, color: 0x302B3D, opacity: 0.27)
        let block = contour(slab.points, radius: 5)
        material(block, colors: slab.variation % 3 == 0 ? [0xA18B88, 0x6A6073, 0x474455] : [0x8B7B83, 0x5D576C, 0x403F53])
        var clipped = context; clipped.clip(to: block)
        let face = VolcanoWorldPainter(context: clipped)
        face.polygon([.init(x: frame.minX, y: frame.midY), .init(x: frame.midX, y: frame.midY + frame.height * 0.12),
                      .init(x: frame.maxX, y: frame.midY - frame.height * 0.12),
                      .init(x: frame.maxX + 3, y: frame.maxY + 3), .init(x: frame.minX - 3, y: frame.maxY + 3)],
                     colors: [0x62566A, 0x383B50])
        context.stroke(block, with: .color(Color(dinoHex: 0xC3AAA0).opacity(0.12)),
                       style: StrokeStyle(lineWidth: 0.7, lineJoin: .round))
    }

    private func rubble(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size, mirror: variation % 2 == 0) { p in
            if variation % 4 == 0 {
                p.basalt(at: CGPoint(x: CGFloat(variation % 7) - 3, y: 0), size: 1)
            } else {
                p.rock(at: CGPoint(x: CGFloat(variation % 7) - 3, y: 0), size: 1)
            }
            if variation % 3 != 1 {
                p.rock(at: CGPoint(x: -33, y: 14), size: 0.38 + CGFloat(variation % 3) * 0.04)
            }
            if variation % 4 == 0 {
                p.rock(at: CGPoint(x: 32, y: 17), size: 0.34)
            }
            p.rock(at: CGPoint(x: -45, y: 20), size: 0.14 + CGFloat(variation % 3) * 0.02)
            if variation % 2 == 0 { p.rock(at: CGPoint(x: 43, y: 21), size: 0.16) }
        }
    }

    private func basalt(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.ground(at: CGPoint(x: 0, y: 13), width: 104, height: 25, opacity: 0.31)
            let block = p.contour([.init(x: -42, y: 7), .init(x: -35, y: -23),
                .init(x: -13, y: -42), .init(x: 19, y: -37), .init(x: 41, y: -12),
                .init(x: 39, y: 17), .init(x: 7, y: 23), .init(x: -27, y: 19)], radius: 3)
            p.material(block, colors: [0xA68E91, 0x6A647B, 0x414B64])
            var clipped = p.context; clipped.clip(to: block)
            let face = VolcanoWorldPainter(context: clipped)
            face.polygon([.init(x: -38, y: -21), .init(x: -13, y: -42), .init(x: 19, y: -37),
                          .init(x: 8, y: -12), .init(x: -19, y: -7)], colors: [0xC2A49D, 0x8E8393])
            face.polygon([.init(x: 19, y: -37), .init(x: 44, y: -12), .init(x: 39, y: 23),
                          .init(x: 1, y: 25), .init(x: 8, y: -12)], colors: [0x777085, 0x394760])
        }
    }

    private func crater(at point: CGPoint, size: CGFloat, mirror: Bool) {
        at(point, size: size, mirror: mirror) { p in
            p.ground(at: CGPoint(x: 0, y: 14), width: 218, height: 67, color: 0x7B6272, opacity: 0.32)
            p.pool(at: CGPoint(x: 20, y: 18), size: 0.74)
            let cone = p.contour([.init(x: -83, y: 8), .init(x: -64, y: -25), .init(x: -45, y: -49),
                                  .init(x: -25, y: -97), .init(x: 22, y: -101), .init(x: 43, y: -62),
                                  .init(x: 62, y: -38), .init(x: 86, y: 15), .init(x: 19, y: 27)], radius: 7)
            p.material(cone, colors: [0xAF8D89, 0x776A7C, 0x45485F])
            var clipped = p.context; clipped.clip(to: cone)
            let face = VolcanoWorldPainter(context: clipped)
            face.polygon([.init(x: -26, y: -103), .init(x: -10, y: -53), .init(x: -33, y: 24), .init(x: -92, y: 20)],
                         colors: [0xC59D8C, 0x8F7881, 0x615D72])
            face.polygon([.init(x: 18, y: -105), .init(x: 30, y: -55), .init(x: 89, y: 25), .init(x: 13, y: 28)],
                         colors: [0x9A7881, 0x4F4D65])
            for i in 0..<5 {
                let x = CGFloat(i - 2) * 18
                let y: CGFloat = -46 + CGFloat(abs(i - 2)) * 11
                face.line([.init(x: x - 10, y: y), .init(x: x, y: y + 8), .init(x: x + 6, y: y + 5),
                           .init(x: x + 10, y: y + 21)], color: 0x3C3E55, width: 1.3, opacity: 0.7)
            }
            var stream = Path(); stream.move(to: CGPoint(x: 3, y: -96))
            stream.addCurve(to: CGPoint(x: 17, y: 16), control1: CGPoint(x: -15, y: -55), control2: CGPoint(x: 32, y: -20))
            face.lava(stream, width: 12)
            p.oval(CGRect(x: -31, y: -107, width: 64, height: 23), colors: [0xD3AC91, 0x736477, 0x403F55])
            p.oval(CGRect(x: -24, y: -103, width: 48, height: 14), colors: [0xFFF0B6, 0xFFC365, 0xE86A37])
            p.glow(CGPoint(x: 0, y: -97), radius: 44, color: 0xFFB85C, opacity: 0.34)
            for (x, y, s): (CGFloat, CGFloat, CGFloat) in [(-62, 14, 0.65), (55, 24, 0.48), (-29, 29, 0.36)] {
                p.rock(at: CGPoint(x: x, y: y), size: s)
            }
            p.crystal(at: CGPoint(x: -51, y: 17), size: 0.55)
            p.plants(at: CGPoint(x: 64, y: 26), size: 0.43)
        }
    }

    private func sky(width: CGFloat, left: CGFloat, right: CGFloat, height: CGFloat, scale: CGFloat) {
        let sun = CGPoint(x: width * 0.23, y: 101)
        glow(sun, radius: 145 * scale, color: 0xFFE6AC, opacity: 0.65)
        oval(CGRect(x: sun.x - 24, y: sun.y - 24, width: 48, height: 48), colors: [0xFFF5CE, 0xFFE4AA, 0xF6C391])
        for (x, y, s) in [(width * 0.20, CGFloat(57), CGFloat(0.9)), (width * 0.56, CGFloat(123), CGFloat(0.8)), (width * 0.87, CGFloat(35), CGFloat(0.65))] {
            at(CGPoint(x: x, y: y), size: s * scale) { p in
                var cloud = Path()
                for (cx, cy, cw, ch): (CGFloat, CGFloat, CGFloat, CGFloat) in [(-64, 0, 83, 18), (-39, -15, 51, 32), (-5, -22, 62, 40), (35, -3, 58, 22)] {
                    cloud.addEllipse(in: CGRect(x: cx, y: cy, width: cw, height: ch))
                }
                p.context.drawLayer { c in
                    c.addFilter(.blur(radius: 2))
                    c.fill(cloud, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFE0BC).opacity(0.78), Color(dinoHex: 0xE7B6AC).opacity(0)]),
                                                       startPoint: CGPoint(x: 0, y: -22), endPoint: CGPoint(x: 0, y: 22)))
                }
            }
        }
        var rear = context; rear.opacity = 0.32
        rear.clipToLayer { mask in
            mask.fill(Path(CGRect(x: -100, y: 0, width: width + 200, height: height + 100)),
                      with: .linearGradient(Gradient(stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: 0.60),
                        .init(color: .clear, location: 1)
                      ]), startPoint: CGPoint(x: 0, y: height * 0.5), endPoint: CGPoint(x: 0, y: height + 20)))
        }
        let distant = VolcanoWorldPainter(context: rear)
        for (x, y, ridgeScale): (CGFloat, CGFloat, CGFloat) in [(-12, height * 0.81, 0.86), (width * 0.43, height * 0.84, 0.73)] {
            distant.at(CGPoint(x: x, y: y), size: ridgeScale * scale) { p in
                let ridge = p.contour([.init(x: -116, y: 18), .init(x: -96, y: -19), .init(x: -71, y: -28),
                                       .init(x: -55, y: -54), .init(x: -27, y: -60), .init(x: -10, y: -46),
                                       .init(x: 18, y: -57), .init(x: 42, y: -51), .init(x: 63, y: -22),
                                       .init(x: 91, y: -15), .init(x: 112, y: 19), .init(x: 12, y: 29)], radius: 12)
                p.material(ridge, colors: [0xCCADA6, 0xAD9CA1, 0xA49AA2])
                p.steam(at: CGPoint(x: 0, y: 9), width: 239, opacity: 0.53)
            }
        }
        steam(at: CGPoint(x: width * 0.5, y: height * 0.92), width: width * 1.12, opacity: 0.23)
    }

    private func steam(at point: CGPoint, width: CGFloat, opacity: Double) {
        context.drawLayer { c in
            c.addFilter(.blur(radius: 7))
            for i in 0..<3 {
                let r = CGRect(x: point.x - width * 0.5 + CGFloat(i - 1) * 12,
                               y: point.y + CGFloat(i) * 9, width: width, height: 19 + CGFloat(i) * 6)
                c.fill(Path(ellipseIn: r), with: .color(Color(dinoHex: 0xFBE4D1).opacity(opacity * (1 - Double(i) * 0.17))))
            }
        }
    }

    private func volcano(at point: CGPoint, size: CGFloat, mirror: Bool = false) {
        at(point, size: size, mirror: mirror) { base in
            // The mountain is solid down to its foot; haze must never reveal
            // the river through the lower slope or weaken its occlusion mask.
            let p = base
            p.ground(at: CGPoint(x: 0, y: 24), width: 320, height: 57, color: 0x3E3B51, opacity: 0.31)
            p.glow(CGPoint(x: 0, y: -205), radius: 75, color: 0xFFCD83, opacity: 0.35)
            let mountain = Path { m in
                m.move(to: CGPoint(x: -136, y: 17))
                m.addQuadCurve(to: CGPoint(x: -133, y: -3), control: CGPoint(x: -151, y: 12))
                m.addCurve(to: CGPoint(x: -79, y: -87), control1: CGPoint(x: -116, y: -28), control2: CGPoint(x: -97, y: -46))
                m.addCurve(to: CGPoint(x: -25, y: -220), control1: CGPoint(x: -54, y: -130), control2: CGPoint(x: -44, y: -205))
                m.addQuadCurve(to: CGPoint(x: 25, y: -220), control: CGPoint(x: 0, y: -233))
                m.addCurve(to: CGPoint(x: 79, y: -91), control1: CGPoint(x: 43, y: -202), control2: CGPoint(x: 55, y: -136))
                m.addCurve(to: CGPoint(x: 136, y: -2), control1: CGPoint(x: 99, y: -53), control2: CGPoint(x: 118, y: -27))
                m.addQuadCurve(to: CGPoint(x: 137, y: 18), control: CGPoint(x: 153, y: 13))
                m.addCurve(to: CGPoint(x: -136, y: 17), control1: CGPoint(x: 63, y: 39), control2: CGPoint(x: -65, y: 38))
                m.closeSubpath()
            }
            p.material(mountain, colors: [0xB39394, 0x777A8C, 0x565E77])
            var facets = p.context; facets.clip(to: mountain)
            let slopes = VolcanoWorldPainter(context: facets)
            let litSlope = Path { s in
                s.move(to: CGPoint(x: -26, y: -232))
                s.addQuadCurve(to: CGPoint(x: -20, y: -134), control: CGPoint(x: -4, y: -195))
                s.addCurve(to: CGPoint(x: -77, y: 26), control1: CGPoint(x: -26, y: -79), control2: CGPoint(x: -69, y: -39))
                s.addLine(to: CGPoint(x: -153, y: 26)); s.closeSubpath()
            }
            slopes.material(litSlope, colors: [0xD2AC9A, 0xA18F91, 0x7B7D8D])
            let shadedSlope = Path { s in
                s.move(to: CGPoint(x: 25, y: -231))
                s.addCurve(to: CGPoint(x: 77, y: 29), control1: CGPoint(x: 18, y: -146), control2: CGPoint(x: 36, y: -43))
                s.addLine(to: CGPoint(x: 159, y: 29)); s.closeSubpath()
            }
            slopes.material(shadedSlope, colors: [0xB29596, 0x7A778C, 0x4E5972])
            for i in 0..<5 {
                let y = -151 + CGFloat(i) * 33
                p.line([.init(x: -48 - CGFloat(i) * 8, y: y), .init(x: -30 - CGFloat(i) * 7, y: y + 8),
                        .init(x: -20 - CGFloat(i) * 4, y: y + 5)], color: 0xE0B6A0, width: 1, opacity: 0.42)
                p.line([.init(x: 30 + CGFloat(i) * 8, y: y + 5), .init(x: 52 + CGFloat(i) * 9, y: y + 13)], color: 0x3D4A62, width: 1.2, opacity: 0.45)
            }
            for lane: CGFloat in [-1.5, -0.75, 0, 0.75, 1.5] {
                slopes.lava(VolcanoWorldLayout.slopeFlow(lane: lane),
                            width: lane == 0 ? 2.6 : abs(lane) < 1 ? 1.1 : 0.75, moving: true)
            }
            p.oval(CGRect(x: -28, y: -230, width: 57, height: 20), colors: [0xA19594, 0x555B70, 0x424D65])
            p.oval(CGRect(x: -20, y: -225, width: 41, height: 12), colors: [0xFFF0B4, 0xFFBD6D, 0xF58153])
            p.glow(CGPoint(x: 0, y: -224), radius: 34, color: 0xFFD38A, opacity: 0.53)

        }
    }

    private func pool(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.ground(at: CGPoint(x: 0, y: 9), width: 196, height: 68, color: 0x8A756D, opacity: 0.29)
            p.ground(at: .zero, width: 183, height: 61, color: 0xFFC480, opacity: 0.45)
            let basin = Path { b in
                b.move(to: CGPoint(x: -74, y: 3))
                b.addCurve(to: CGPoint(x: -26, y: -17), control1: CGPoint(x: -78, y: -12), control2: CGPoint(x: -47, y: -14))
                b.addCurve(to: CGPoint(x: 39, y: -15), control1: CGPoint(x: -5, y: -24), control2: CGPoint(x: 21, y: -10))
                b.addCurve(to: CGPoint(x: 76, y: 6), control1: CGPoint(x: 62, y: -22), control2: CGPoint(x: 87, y: -2))
                b.addCurve(to: CGPoint(x: 29, y: 26), control1: CGPoint(x: 68, y: 21), control2: CGPoint(x: 48, y: 21))
                b.addCurve(to: CGPoint(x: -40, y: 23), control1: CGPoint(x: 4, y: 36), control2: CGPoint(x: -20, y: 19))
                b.addCurve(to: CGPoint(x: -74, y: 3), control1: CGPoint(x: -62, y: 26), control2: CGPoint(x: -78, y: 16))
                b.closeSubpath()
            }
            p.context.stroke(basin.offsetBy(dx: 0, dy: 3), with: .color(Color(dinoHex: 0x656478)),
                             style: StrokeStyle(lineWidth: 10, lineJoin: .round))
            p.context.stroke(basin, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xB6A29A), Color(dinoHex: 0x777586)]),
                                                         startPoint: CGPoint(x: -40, y: -16), endPoint: CGPoint(x: 35, y: 30)),
                             style: StrokeStyle(lineWidth: 7, lineJoin: .round))
            p.material(basin, colors: [0xF28F5B, 0xFFD081, 0xFFE4A0, 0xEEA267])
            for (x, y, length): (CGFloat, CGFloat, CGFloat) in [(-43, 8, 22), (-9, 16, 28), (31, 5, 20)] {
                var ripple = Path(); ripple.move(to: CGPoint(x: x, y: y))
                ripple.addQuadCurve(to: CGPoint(x: x + length, y: y), control: CGPoint(x: x + length / 2, y: y + 4))
                p.context.stroke(ripple, with: .color(Color(dinoHex: 0xFFF1B7).opacity(0.75)), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
            }
        }
    }

    private func rock(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.ground(at: CGPoint(x: 0, y: 12), width: 88, height: 28, opacity: 0.23)
            let stone = Path { s in
                s.move(to: CGPoint(x: -35, y: 7))
                s.addCurve(to: CGPoint(x: -15, y: -34), control1: CGPoint(x: -34, y: -12), control2: CGPoint(x: -25, y: -30))
                s.addQuadCurve(to: CGPoint(x: 17, y: -35), control: CGPoint(x: 1, y: -43))
                s.addCurve(to: CGPoint(x: 33, y: 11), control1: CGPoint(x: 35, y: -25), control2: CGPoint(x: 43, y: -3))
                s.addCurve(to: CGPoint(x: -35, y: 7), control1: CGPoint(x: 15, y: 22), control2: CGPoint(x: -22, y: 21))
                s.closeSubpath()
            }
            p.material(stone, colors: [0xC4ACA2, 0x99929D, 0x65718A])
            var clipped = p.context; clipped.clip(to: stone)
            let face = VolcanoWorldPainter(context: clipped)
            face.polygon([.init(x: -33, y: -17), .init(x: -15, y: -39), .init(x: 16, y: -40), .init(x: 2, y: -13)], colors: [0xDCC2AD, 0xABA2A7])
            face.polygon([.init(x: 17, y: -38), .init(x: 41, y: -12), .init(x: 32, y: 21), .init(x: -2, y: 21), .init(x: 2, y: -13)], colors: [0x9B93A2, 0x5D6A83])
            p.line([.init(x: -23, y: -10), .init(x: -14, y: -7), .init(x: -9, y: -11)], color: 0x63708A, width: 0.8, opacity: 0.6)
            p.line([.init(x: 11, y: -4), .init(x: 19, y: -1), .init(x: 27, y: -3)], color: 0xDDB89D, width: 0.8, opacity: 0.65)
        }
    }

    private func leaf(at point: CGPoint, length: CGFloat, width: CGFloat, angle: Double, copper: Bool) {
        var c = context; c.translateBy(x: point.x, y: point.y); c.rotate(by: .degrees(angle))
        let leaf = Path { p in
            p.move(to: .zero)
            p.addCurve(to: CGPoint(x: length * 0.13, y: -length), control1: CGPoint(x: -width, y: -length * 0.21), control2: CGPoint(x: -width * 0.9, y: -length * 0.76))
            p.addCurve(to: .zero, control1: CGPoint(x: width * 0.85, y: -length * 0.83), control2: CGPoint(x: width, y: -length * 0.23))
        }
        c.fill(leaf, with: .linearGradient(Gradient(colors: (copper ? [0xEABD7B, 0xC0835D, 0x886357] : [0xC7D38E, 0x8FA173, 0x516E62]).map { Color(dinoHex: $0) }),
                                          startPoint: CGPoint(x: -width * 0.5, y: -length), endPoint: CGPoint(x: width, y: 0)))
        var veins = Path(); veins.move(to: .zero); veins.addLine(to: CGPoint(x: length * 0.12, y: -length * 0.93))
        for i in 1...3 {
            let t = CGFloat(i) / 5
            for side: CGFloat in [-1, 1] {
                veins.move(to: CGPoint(x: length * 0.12 * t, y: -length * t))
                veins.addQuadCurve(to: CGPoint(x: width * 0.55 * side, y: -length * (t + 0.14)),
                                   control: CGPoint(x: width * 0.42 * side, y: -length * (t + 0.03)))
            }
        }
        c.stroke(veins, with: .color(Color(dinoHex: 0xF0DBA4).opacity(0.36)), style: StrokeStyle(lineWidth: 0.65, lineCap: .round))
    }

    private func plants(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for i in 0..<7 {
                p.leaf(at: CGPoint(x: CGFloat(i % 2) * 5, y: CGFloat(i % 3) * 2),
                       length: CGFloat(26 + i % 3 * 10), width: CGFloat(7 + i % 2 * 3),
                       angle: Double(i * 26 - 78), copper: i % 3 == 0)
            }
            for i in 0..<3 {
                p.oval(CGRect(x: CGFloat(i) * 10 - 7, y: -3 + CGFloat(i % 2) * 3, width: 4, height: 3), colors: [0xFFDE93, 0xD99E66])
            }
        }
    }

    private func crystal(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for i in 0..<3 {
                let x = CGFloat(i - 1) * 11
                let h: CGFloat = i == 1 ? 37 : 24
                p.polygon([.init(x: x - 7, y: 1), .init(x: x - 7, y: -h + 9), .init(x: x, y: -h), .init(x: x + 7, y: -h + 9), .init(x: x + 6, y: 1)],
                          colors: [0xFFE5A6, 0xF5B26B, 0xCD8057])
                p.line([.init(x: x, y: -h + 3), .init(x: x, y: -2)], color: 0xFFE8AC, width: 1, opacity: 0.7)
            }
        }
    }

    func scene(at point: CGPoint, size: CGFloat, variation: Int) {
        if variation % 3 == 0 {
            volcano(at: point, size: size * 0.48, mirror: variation % 2 == 0)
        } else {
            crater(at: point, size: size * 0.9, mirror: variation % 2 == 0)
        }
    }

}

/// Sunlit plaster, tiled roofs and planted waterways belong only to Dino Dorp.
private struct VillageWorldPainter {
    let context: GraphicsContext
    var scenery: WorldSceneryLayout? = nil
    var depth: WorldSceneryDepth? = nil
    var depthOffset: CGFloat = 0

    private func at(_ point: CGPoint, size: CGFloat = 1, mirror: Bool = false, radius: CGFloat = 0, rise: CGFloat = 0, draw: @escaping (VillageWorldPainter) -> Void) {
        let point = scenery?.position(point, radius: radius, rise: rise) ?? point
        var c = context
        c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: mirror ? -size : size, y: size)
        if let depth {
            depth.add(at: depthOffset + point.y) { draw(.init(context: c)) }
        } else { draw(.init(context: c)) }
    }
    private func material(_ path: Path, _ colors: [UInt32]) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
    }
    private func rounded(_ rect: CGRect, _ radius: CGFloat, _ colors: [UInt32]) {
        material(Path(roundedRect: rect, cornerRadius: radius), colors)
    }
    private func polygon(_ points: [CGPoint], _ colors: [UInt32]) {
        var p = Path(); p.addLines(points); p.closeSubpath(); material(p, colors)
    }
    private func oval(_ r: CGRect, _ colors: [UInt32]) {
        context.fill(Path(ellipseIn: r), with: .radialGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                            center: CGPoint(x: r.minX + r.width * 0.3, y: r.minY + r.height * 0.2),
                                                            startRadius: 0, endRadius: max(r.width, r.height) * 0.85))
    }
    private func line(_ points: [CGPoint], _ color: UInt32, _ width: CGFloat, opacity: Double = 1) {
        var p = Path(); p.addLines(points)
        context.stroke(p, with: .color(Color(dinoHex: color).opacity(opacity)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func glow(_ point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), Color(dinoHex: color).opacity(0)]),
                                           center: point, startRadius: 0, endRadius: radius))
    }

    func landscape(in size: CGSize, routeOffset: CGFloat, depth: WorldSceneryDepth) {
        let w = size.width, h = size.height
        let left: CGFloat = 0, right = w - left
        let scale = min(1.30, max(0.82, w / 390))
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: 0xC7E8BE), location: 0),
            .init(color: Color(dinoHex: 0x88D2E8), location: 0.035),
            .init(color: Color(dinoHex: 0xDDF1D8), location: (routeOffset + 80) / h),
            .init(color: Color(dinoHex: 0xD1E4AE), location: 0.32),
            .init(color: Color(dinoHex: 0xC8DEA8), location: 0.57),
            .init(color: Color(dinoHex: 0xC3DBAD), location: 0.80),
            .init(color: Color(dinoHex: 0xC3DBAD), location: 1)
        ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
        sky(width: w, left: left, right: right, height: routeOffset + 85, scale: scale)
        var c = context; c.translateBy(x: 0, y: routeOffset)
        let scenery = WorldSceneryLayout(width: w, height: h, routeOffset: routeOffset)
        scenery.drawBanks(in: c, worldID: 4)
        let p = VillageWorldPainter(context: c, scenery: scenery, depth: depth, depthOffset: routeOffset)
        let nature = JunglePainter(context: c, scenery: scenery)
        for i in 0..<5 {
            nature.hill(x: i % 2 == 0 ? left - 220 : right - 100, y: CGFloat(i) * 370 + 15,
                        width: 360 * scale, height: 280, color: Color(dinoHex: i % 2 == 0 ? 0xA7C98F : 0xEEF0BC).opacity(0.34))
        }
        // Water and its banks sit behind the village; clocks remain unobstructed.
        p.cascade(at: CGPoint(x: left - 3, y: 850), size: scale * 0.85)
        p.cascade(at: CGPoint(x: right + 5, y: 1190), size: scale * 0.85, mirror: true)
        p.bridge(at: CGPoint(x: left + 12 * scale, y: 900), size: scale * 0.85)
        p.bridge(at: CGPoint(x: right - 10 * scale, y: 1210), size: scale * 0.8)
        for i in 0..<28 {
            let x = i % 2 == 0 ? left + CGFloat(33 + i % 3 * 12) : right - CGFloat(33 + i % 3 * 12)
            let y = 38 + CGFloat(i) * 60
            nature.grass(at: CGPoint(x: x, y: y), size: 6 * scale, color: Color(dinoHex: 0x7FA569).opacity(0.7))
            if i % 3 == 0 { p.flowers(at: CGPoint(x: x + 7, y: y + 12), size: scale * 0.4, pink: i % 2 == 0) }
        }
        let positions = WorldRouteTrail.chapterPositions
        let routeWidth = min(w, 600) - 36
        let shared = ThemePainter(context: c, colors: WorldThemeColors(DinoWorldCatalog.world(4)!))
        for index in 0..<9 {
            let onRight = index % 4 == 0 || index % 4 == 3
            let point = CGPoint(x: onRight ? right - 35 * scale : left + 35 * scale, y: 182 + CGFloat(index) * 175)
            let x = (w - routeWidth) / 2 + routeWidth * (positions[index] + (positions[index + 1] - positions[index]) * 0.622)
            shared.approach(from: CGPoint(x: x, y: point.y), to: scenery.position(point), city: false, scale: scale)
            p.scene(at: point, size: scale * 0.98, variation: index)
            let gardenX = onRight ? left + 5 * scale : right - 5 * scale
            p.garden(at: CGPoint(x: gardenX, y: point.y + 82), size: scale, variation: index)
        }
        // Mossy outcrops follow the final level and continue across the join.
        CrystalCavePainter(context: context).outdoorApproach(width: w, boundaryY: h)
    }

    private func sky(width: CGFloat, left: CGFloat, right: CGFloat, height: CGFloat, scale: CGFloat) {
        let sun = CGPoint(x: width * 0.2, y: 84)
        glow(sun, radius: 150 * scale, color: 0xFFF4BC, opacity: 0.75)
        oval(CGRect(x: sun.x - 22, y: sun.y - 22, width: 44, height: 44), [0xFFFBE0, 0xFFEDB0])
        for i in 0..<4 {
            at(CGPoint(x: width * (0.08 + CGFloat(i) * 0.29), y: 48 + CGFloat(i % 2) * 52), size: scale * (i % 2 == 0 ? 0.85 : 0.65)) { p in
                var cloud = Path()
                for r in [CGRect(x: -53, y: 0, width: 100, height: 20), CGRect(x: -33, y: -18, width: 48, height: 35), CGRect(x: 1, y: -26, width: 51, height: 45), CGRect(x: 31, y: -6, width: 45, height: 26)] { cloud.addEllipse(in: r) }
                p.context.drawLayer { c in
                    c.addFilter(.blur(radius: 1.5))
                    c.fill(cloud, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFFFEB).opacity(0.95), Color(dinoHex: 0xE1F1DC).opacity(0.08)]),
                                                       startPoint: CGPoint(x: 0, y: -28), endPoint: CGPoint(x: 0, y: 22)))
                }
            }
        }
        var far = context; far.opacity = 0.48
        far.clipToLayer { mask in
            mask.fill(Path(CGRect(x: 0, y: 0, width: width, height: height + 70)),
                      with: .linearGradient(Gradient(stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: 0.55),
                        .init(color: .white.opacity(0), location: 1)
                      ]), startPoint: CGPoint(x: 0, y: height * 0.45), endPoint: CGPoint(x: 0, y: height + 70)))
        }
        let p = VillageWorldPainter(context: far)
        for i in 0..<5 {
            p.at(CGPoint(x: left - 30 + CGFloat(i) * (right - left + 60) / 4, y: height * 0.78 + CGFloat(i % 2) * 26), size: scale * 1.1) { cliff in
                cliff.polygon([.init(x: -51, y: 36), .init(x: -42, y: -103), .init(x: -28, y: -119), .init(x: 20, y: -113), .init(x: 43, y: -86), .init(x: 59, y: 36)], [0xC2D9C3, 0x9CBEB5, 0x8EAFB2])
                cliff.polygon([.init(x: -28, y: -119), .init(x: -12, y: -92), .init(x: -16, y: 30), .init(x: -45, y: 35)], [0xD3E4C6, 0xA4C5B8])
                cliff.oval(CGRect(x: -45, y: -128, width: 80, height: 24), [0xC5DFA6, 0x83AF8E])
                if i == 0 || i == 4 {
                    cliff.rounded(CGRect(x: 8, y: -106, width: 12, height: 117), 4, [0xEEFBE7, 0x92DADD, 0xD4F2DB])
                    cliff.line([.init(x: 13, y: -101), .init(x: 13, y: 3)], 0xF2FFEA, 2, opacity: 0.8)
                }
            }
        }
        JunglePainter(context: context).hill(x: -width * 0.16, y: height * 0.68, width: width * 1.32, height: 190,
                                             color: Color(dinoHex: 0xB1D49C).opacity(0.6))
        // A recognisable tower rises above the title, with houses nestled below.
        tower(at: CGPoint(x: right - 90 * scale, y: 202 * scale), size: scale * 0.95)
        cottage(at: CGPoint(x: left + 47 * scale, y: height - 15), size: scale * 0.77, leafRoof: true)
        cottage(at: CGPoint(x: right - 18 * scale, y: height + 12), size: scale * 0.65, leafRoof: false)
        tree(at: CGPoint(x: left - 7, y: height + 19), size: scale * 0.96)
        tree(at: CGPoint(x: right + 20, y: height + 70), size: scale * 1.12)
        for i in 0..<3 {
            let x = width * 0.33 + CGFloat(i) * 18, y = 47 + CGFloat(i % 2) * 8
            var bird = Path(); bird.move(to: CGPoint(x: x - 5, y: y + 2))
            bird.addQuadCurve(to: CGPoint(x: x, y: y + 3), control: CGPoint(x: x - 2, y: y - 2))
            bird.addQuadCurve(to: CGPoint(x: x + 5, y: y), control: CGPoint(x: x + 2, y: y - 2))
            context.stroke(bird, with: .color(Color(dinoHex: 0x5B9299).opacity(0.65)), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
        }
    }

    private func leaf(at point: CGPoint, length: CGFloat, width: CGFloat, angle: Double) {
        at(point) { p in
            var c = p.context; c.rotate(by: .degrees(angle))
            let l = VillageWorldPainter(context: c)
            let shape = Path { path in
                path.move(to: .zero)
                path.addCurve(to: CGPoint(x: 0, y: -length), control1: CGPoint(x: -width, y: -length * 0.18), control2: CGPoint(x: -width * 0.7, y: -length * 0.8))
                path.addCurve(to: .zero, control1: CGPoint(x: width * 0.7, y: -length * 0.84), control2: CGPoint(x: width, y: -length * 0.24))
            }
            l.material(shape, [0xB6D86F, 0x609D64, 0x327A61])
            l.line([.zero, .init(x: 0, y: -length * 0.86)], 0xD8E99A, 0.8, opacity: 0.7)
            for i in 1...3 {
                let y = -length * CGFloat(i) * 0.21
                l.line([.init(x: 0, y: y), .init(x: width * 0.4, y: y - 5)], 0xD0E69B, 0.55, opacity: 0.45)
            }
        }
    }
    private func plants(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for i in 0..<5 { p.leaf(at: .zero, length: 22 + CGFloat(i % 3) * 5, width: 7, angle: Double(i - 2) * 30) }
        }
    }
    private func flowers(at point: CGPoint, size: CGFloat, pink: Bool) {
        at(point, size: size) { p in
            for i in 0..<3 {
                let x = CGFloat(i - 1) * 12, y = -7 - CGFloat(i % 2) * 8
                p.line([.init(x: x, y: 5), .init(x: x, y: y)], 0x639D66, 1.6)
                p.leaf(at: CGPoint(x: x, y: 0), length: 9, width: 3, angle: i % 2 == 0 ? 58 : -58)
                for j in 0..<5 {
                    let a = Double(j) * .pi * 0.4
                    p.oval(CGRect(x: x + CGFloat(cos(a)) * 4 - 3, y: y + CGFloat(sin(a)) * 4 - 3, width: 6, height: 6), pink ? [0xFFE5C9, 0xEC9C9D, 0xD88492] : [0xFFFFE4, 0xFFE9A5])
                }
                p.oval(CGRect(x: x - 2.1, y: y - 2.1, width: 4.2, height: 4.2), [0xFFF3A4, 0xEAB95C])
            }
        }
    }
    private func tree(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -37, y: -5, width: 79, height: 18), [0x93B582, 0xBBD29C])
            p.polygon([.init(x: -11, y: 0), .init(x: -5, y: -60), .init(x: -27, y: -89), .init(x: -20, y: -92), .init(x: 2, y: -69), .init(x: 15, y: -109), .init(x: 22, y: -104), .init(x: 7, y: -55), .init(x: 13, y: 0)], [0xCBA56A, 0x937B50, 0x6B6749])
            p.line([.init(x: -5, y: -4), .init(x: 0, y: -39), .init(x: -1, y: -61)], 0xE5C68A, 1.5, opacity: 0.7)
            for (x, y, s): (CGFloat, CGFloat, CGFloat) in [(-28,-88,0.8),(26,-94,0.88),(-7,-117,0.96),(0,-88,1.05)] {
                p.oval(CGRect(x: x - 28 * s, y: y - 22 * s, width: 58 * s, height: 49 * s), [0xC0D973, 0x7EB365, 0x43885D])
            }
            for i in 0..<13 {
                let x = CGFloat((i * 19) % 84) - 43, y = -81 - CGFloat((i * 13) % 49)
                p.leaf(at: CGPoint(x: x, y: y), length: 17, width: 6, angle: Double(i % 5 - 2) * 32)
            }
            for (x, y): (CGFloat, CGFloat) in [(-27,-96),(22,-103),(5,-79),(-8,-121)] {
                p.oval(CGRect(x: x - 4, y: y - 4, width: 9, height: 10), [0xFFE8A2, 0xF2BA68, 0xD99352])
                p.line([.init(x: x, y: y - 4), .init(x: x + 1, y: y - 7)], 0x6D7950, 1)
            }
            p.plants(at: CGPoint(x: -18, y: 5), size: 0.63)
        }
    }

    private func cottage(at point: CGPoint, size: CGFloat, leafRoof: Bool) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -48, y: -7, width: 100, height: 23), [0x92AB7C, 0xBED29F])
            let body = Path { b in
                b.move(to: CGPoint(x: -37, y: -5))
                b.addCurve(to: CGPoint(x: -26, y: -97), control1: CGPoint(x: -48, y: -30), control2: CGPoint(x: -39, y: -76))
                b.addQuadCurve(to: CGPoint(x: 26, y: -97), control: CGPoint(x: 0, y: -123))
                b.addCurve(to: CGPoint(x: 37, y: -5), control1: CGPoint(x: 40, y: -78), control2: CGPoint(x: 49, y: -30))
                b.addQuadCurve(to: CGPoint(x: -37, y: -5), control: CGPoint(x: 0, y: 11)); b.closeSubpath()
            }
            p.material(body, [0xFFF4D4, 0xEDDAB1, 0xC3B88E])
            p.context.stroke(body, with: .color(Color(dinoHex: 0xAD9E76).opacity(0.45)), lineWidth: 1)
            for (x,y): (CGFloat,CGFloat) in [(-32,-39),(29,-65),(-24,-79),(33,-19)] { p.oval(CGRect(x:x-3,y:y-2,width:6,height:5),[0xD5BE93,0xDDBF93]) }
            p.door(at: CGPoint(x: 0, y: -2), size: 1, teal: leafRoof)
            p.window(at: CGPoint(x: -24, y: -55), size: 0.83)
            p.window(at: CGPoint(x: 24, y: -55), size: 0.83)
            p.rounded(CGRect(x: 22, y: -123, width: 11, height: 29), 2, [0xF4DEB6, 0xC2AC85])
            p.rounded(CGRect(x: 19, y: -125, width: 17, height: 6), 2, [0xFFF0CE, 0xD1BA90])
            if leafRoof {
                let roof = Path { r in
                    r.move(to: CGPoint(x: -41, y: -94))
                    r.addQuadCurve(to: CGPoint(x: 0, y: -128), control: CGPoint(x: -28, y: -127))
                    r.addQuadCurve(to: CGPoint(x: 41, y: -94), control: CGPoint(x: 26, y: -128))
                    r.closeSubpath()
                }
                p.material(roof, [0x91B98A, 0x4F9479, 0x296D60])
                let angles: [Double] = [-125, -155, 180, 155, 125]
                for row in 0..<2 {
                    for i in 0..<5 {
                        p.leaf(at: CGPoint(x: CGFloat(i - 2) * 7, y: -121 + CGFloat(row) * 10),
                               length: 27 + CGFloat(row) * 5, width: 11, angle: angles[i])
                    }
                }
            } else { p.roof(at: CGPoint(x: 0, y: -93), width: 92, height: 38) }
            p.rounded(CGRect(x: -21, y: 0, width: 42, height: 6), 2, [0xF3E3BE, 0xC4B593])
            p.rounded(CGRect(x: -25, y: 5, width: 50, height: 6), 2, [0xE8D8B5, 0xADAA8B])
            p.flowers(at: CGPoint(x: -32, y: 5), size: 0.65, pink: true)
            p.plants(at: CGPoint(x: 37, y: 10), size: 0.77)
        }
    }
    private func roof(at point: CGPoint, width: CGFloat, height: CGFloat) {
        at(point) { p in
            let roof = Path { r in
                r.move(to: CGPoint(x: -width / 2, y: 4))
                r.addQuadCurve(to: CGPoint(x: -12, y: -height), control: CGPoint(x: -width * 0.36, y: -height))
                r.addQuadCurve(to: CGPoint(x: width / 2, y: 4), control: CGPoint(x: width * 0.29, y: -height - 9))
                r.closeSubpath()
            }
            p.material(roof, [0xF8C084, 0xD88961, 0xAC6C50])
            var tiles = p.context; tiles.clip(to: roof)
            let t = VillageWorldPainter(context: tiles)
            for row in 0..<4 {
                for col in 0..<7 {
                    let x = CGFloat(col - 3) * 15 + (row % 2 == 0 ? 0 : 7)
                    let y = -height + CGFloat(row) * 12
                    t.rounded(CGRect(x: x, y: y, width: 14, height: 14), 5, [0xF3B67C, row % 2 == 0 ? 0xDB966B : 0xD38B63, 0xB87454])
                    t.line([.init(x: x + 3, y: y + 3), .init(x: x + 9, y: y + 2)], 0xFFDEAB, 0.8, opacity: 0.8)
                }
            }
            p.line([.init(x: -width / 2, y: 4), .init(x: width / 2, y: 4)], 0x99674E, 3)
            p.line([.init(x: -width / 2 + 3, y: 2), .init(x: width / 2 - 3, y: 2)], 0xF7C99A, 1)
        }
    }
    private func door(at point: CGPoint, size: CGFloat, teal: Bool) {
        at(point, size: size) { p in
            let shape = Path(roundedRect: CGRect(x: -14, y: -37, width: 28, height: 38), cornerRadius: 13)
            p.context.stroke(shape, with: .color(Color(dinoHex: 0xB99A6B)), lineWidth: 6)
            p.material(shape, teal ? [0x6DA08A, 0x3F7D71, 0x396957] : [0xC49A68, 0x9C744C, 0x7C6243])
            for x: CGFloat in [-8, -2, 4, 10] { p.line([.init(x: x, y: -28), .init(x: x, y: -4)], teal ? 0xA0C2A2 : 0xE4BF87, 0.8, opacity: 0.65) }
            p.oval(CGRect(x: 6, y: -17, width: 4, height: 4), [0xFFF0B6, 0xDDB368])
            for y: CGFloat in [-23, -8] { p.rounded(CGRect(x: -13, y: y, width: 5, height: 2), 1, [0x777354, 0x6A654B]) }
        }
    }
    private func window(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.glow(.zero, radius: 23, color: 0xFFECA6, opacity: 0.3)
            p.rounded(CGRect(x: -10, y: -15, width: 20, height: 28), 9, [0xBD9464, 0x8A7952])
            p.rounded(CGRect(x: -7, y: -12, width: 14, height: 22), 6, [0xFFFFD8, 0xFFEBA4, 0xE9C781])
            p.line([.init(x: 0, y: -12), .init(x: 0, y: 10)], 0xE5C18A, 1.7)
            p.line([.init(x: -7, y: 0), .init(x: 7, y: 0)], 0xE5C18A, 1.7)
            p.line([.init(x: -5, y: -8), .init(x: -1, y: -4)], 0xFFFFFF, 1.5, opacity: 0.65)
            p.rounded(CGRect(x: -13, y: 11, width: 26, height: 4), 1.5, [0xEED5A5, 0xB39D74])
        }
    }
    private func tower(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -48, y: -5, width: 96, height: 20), [0x9CAF85, 0xC7D9A5])
            p.rounded(CGRect(x: -32, y: -158, width: 64, height: 159), 23, [0xFFF1CA, 0xE7D0A1, 0xBCAC81])
            for i in 0..<6 {
                let y = -17 - CGFloat(i) * 24
                p.line([.init(x: 20, y: y), .init(x: 29, y: y - 2)], 0xB49F78, 1, opacity: 0.6)
                p.line([.init(x: -28, y: y - 9), .init(x: -20, y: y - 9)], 0xFFF2CB, 1)
            }
            p.door(at: CGPoint(x: 0, y: -2), size: 0.9, teal: true)
            p.window(at: CGPoint(x: -18, y: -54), size: 0.55)
            p.window(at: CGPoint(x: 18, y: -54), size: 0.55)
            p.oval(CGRect(x: -27, y: -140, width: 54, height: 56), [0xF7D594, 0xB88A53, 0x8D754D])
            let clock = ThemePainter(context: p.context, colors: WorldThemeColors(DinoWorldCatalog.world(4)!))
            clock.clock(at: CGPoint(x: 0, y: -114), time: .init(hour: 10, minute: 10), size: 23)
            let roof = Path { r in
                r.move(to: CGPoint(x: -40, y: -155))
                r.addQuadCurve(to: CGPoint(x: 0, y: -188), control: CGPoint(x: -29, y: -184))
                r.addQuadCurve(to: CGPoint(x: 40, y: -155), control: CGPoint(x: 27, y: -187))
                r.closeSubpath()
            }
            p.material(roof, [0xACCC80, 0x5D9C70, 0x397E63])
            let angles: [Double] = [-125, -155, 180, 155, 125]
            for row in 0..<2 { for i in 0..<5 {
                p.leaf(at: CGPoint(x: CGFloat(i - 2) * 7, y: -184 + CGFloat(row) * 10), length: 25 + CGFloat(row) * 3, width: 10,
                       angle: angles[i])
            } }
            p.line([.init(x: 0, y: -173), .init(x: 0, y: -202)], 0xA18150, 2.5)
            p.polygon([.init(x: 1, y: -201), .init(x: 25, y: -196), .init(x: 16, y: -190), .init(x: 1, y: -192)], [0xFFE2A0, 0xE89B62])
            p.oval(CGRect(x: -3, y: -206, width: 6, height: 6), [0xFFF0B1, 0xCEA267])
            p.plants(at: CGPoint(x: -30, y: 6), size: 0.7)
            p.flowers(at: CGPoint(x: 30, y: 7), size: 0.75, pink: true)
            for i in 0..<3 { p.rounded(CGRect(x: -24 - CGFloat(i) * 5, y: CGFloat(i) * 5, width: 48 + CGFloat(i) * 10, height: 5), 1.5, [0xF1DDB6, 0xB7B48E]) }
        }
    }

    private func fence(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for y: CGFloat in [-19, -7] { p.rounded(CGRect(x: -39, y: y, width: 78, height: 5), 1.5, [0xE2BB7C, 0xA47F52]) }
            for x: CGFloat in [-36, -12, 12, 36] {
                p.rounded(CGRect(x: x - 3, y: -29, width: 7, height: 34), 2, [0xF1CC8C, 0xAA8857, 0x7D714F])
                p.oval(CGRect(x: x - 4, y: -31, width: 9, height: 4), [0xFFE1A5, 0xB6935C])
                p.line([.init(x: x + 1, y: -23), .init(x: x + 1, y: -4)], 0xF7D49A, 0.6)
            }
        }
    }
    private func market(at point: CGPoint, size: CGFloat, blue: Bool) {
        at(point, size: size) { p in
            for x: CGFloat in [-32, 32] { p.rounded(CGRect(x: x - 2, y: -65, width: 4, height: 70), 1, [0xE8C28B, 0x9F7C53]) }
            p.rounded(CGRect(x: -37, y: -19, width: 74, height: 24), 3, [0xEAC594, 0xBC9664, 0x977C52])
            for i in 0..<5 { p.line([.init(x: CGFloat(i) * 14 - 29, y: -16), .init(x: CGFloat(i) * 14 - 29, y: 2)], 0xF5D7A6, 0.8) }
            for row in 0..<2 { for i in 0..<8 {
                let x = CGFloat(i) * 8 - 29 + CGFloat(row) * 2, y = -23 - CGFloat(row) * 6
                let colors: [UInt32] = i < 3 ? [0xFFE88C,0xE8B25A] : i < 6 ? [0xF8BE85,0xD7805F] : [0xB4D97B,0x7DA15B]
                p.oval(CGRect(x:x,y:y,width:8,height:8),colors)
            } }
            for i in 0..<8 {
                let x = -40 + CGFloat(i) * 10
                let colors: [UInt32] = i % 2 == 0 ? [0xFFFFE4,0xF4E5BA] : blue ? [0x9ED7DC,0x509DA9] : [0xFFDA8A,0xE2AC58]
                p.polygon([.init(x:x+4,y:-67),.init(x:x+12,y:-67),.init(x:x+10,y:-43),.init(x:x,y:-43)],colors)
                p.rounded(CGRect(x:x,y:-44,width:10,height:9),4,colors)
            }
            p.line([.init(x:-35,y:-67),.init(x:35,y:-67)],0xD5B78B,2)
            p.oval(CGRect(x:-30,y:2,width:14,height:14),[0xA58A5D,0x7D6C4E])
            p.oval(CGRect(x:17,y:2,width:14,height:14),[0xA58A5D,0x7D6C4E])
            p.flowers(at: CGPoint(x: -41,y:9), size:0.6,pink:true)
        }
    }
    private func fountain(at point: CGPoint, size: CGFloat) {
        at(point, size:size) { p in
            p.oval(CGRect(x:-54,y:-12,width:108,height:40),[0x9EAE84,0xC6D5A1])
            p.oval(CGRect(x:-45,y:-23,width:90,height:41),[0xE8CDA4,0xBAA17F,0x968D70])
            for i in 0..<7 {
                let x = CGFloat(i) * 12 - 37, y = 7 - abs(CGFloat(i-3)) * 2
                p.line([.init(x:x,y:y),.init(x:x+1,y:y+7)],0x8C8B70,1)
            }
            p.oval(CGRect(x:-40,y:-23,width:80,height:27),[0xF7E4B7,0xC8B28C])
            p.oval(CGRect(x:-35,y:-21,width:70,height:21),[0xD4F1DF,0x74C3C5,0x5BA9B4])
            p.rounded(CGRect(x:-6,y:-58,width:12,height:49),5,[0xF4E0B4,0xC6B08A,0x9B9475])
            p.oval(CGRect(x:-23,y:-63,width:46,height:17),[0xFCE9BF,0xBAA785])
            p.oval(CGRect(x:-19,y:-63,width:38,height:10),[0xDBF5E5,0x7BC9CA])
            p.oval(CGRect(x:-7,y:-80,width:14,height:18),[0xFFF3C7,0xD8C295,0xAFA17D])
            for side:CGFloat in [-1,1] {
                var stream=Path();stream.move(to:.init(x:side*17,y:-58))
                stream.addQuadCurve(to:.init(x:side*31,y:-9),control:.init(x:side*30,y:-54))
                p.context.stroke(stream,with:.color(Color(dinoHex:0xD9F8EA)),style:StrokeStyle(lineWidth:2.3,lineCap:.round))
                p.oval(CGRect(x:side*31-6,y:-13,width:13,height:4),[0xDDF7E7,0xA8E1D8])
            }
            p.flowers(at:CGPoint(x:-43,y:11),size:0.62,pink:true)
            p.flowers(at:CGPoint(x:43,y:11),size:0.62,pink:false)
        }
    }
    private func rock(at point:CGPoint,size:CGFloat) {
        at(point,size:size) { p in
            p.polygon([.init(x:-23,y:5),.init(x:-18,y:-17),.init(x:-3,y:-27),.init(x:17,y:-19),.init(x:26,y:2),.init(x:8,y:11)], [0xDDD4B6,0xACB3A3,0x7D958E])
            p.polygon([.init(x:-18,y:-17),.init(x:-3,y:-27),.init(x:17,y:-19),.init(x:1,y:-9)], [0xF5E4BD,0xC8CBB1])
            p.line([.init(x:1,y:-9),.init(x:8,y:7)],0x6F8983,0.8,opacity:0.6)
        }
    }
    private func cascade(at point:CGPoint,size:CGFloat,mirror:Bool=false) {
        at(point,size:size,mirror:mirror) { p in
            for i in 0..<4 {
                let x=CGFloat(i)*17-36,y=CGFloat(i%2)*8
                p.rock(at:CGPoint(x:x,y:y-9),size:1.3)
            }
            p.rounded(CGRect(x:-12,y:-27,width:29,height:71),4,[0xD2F1E2,0x8ACFD0,0x57B2BD,0xB0E4DA])
            for i in 0..<4 { p.line([.init(x:CGFloat(i)*7-9,y:-23),.init(x:CGFloat(i)*7-11,y:33+CGFloat(i%2)*8)],0xEEFFF0,i%2==0 ? 2 : 1,opacity:0.8) }
            p.oval(CGRect(x:-31,y:31,width:67,height:20),[0xECFFF0,0xA1DCD4,0x73BDC0])
            for i in 0..<6 { p.oval(CGRect(x:CGFloat(i)*9-25,y:33+CGFloat(i%2)*5,width:10,height:4),[0xF3FFF1,0xCDEFE2]) }
            p.plants(at:CGPoint(x:32,y:5),size:0.8)
            p.flowers(at:CGPoint(x:-35,y:17),size:0.65,pink:false)
        }
    }
    private func bridge(at point:CGPoint,size:CGFloat) {
        at(point,size:size) { p in
            p.polygon([.init(x:-44,y:-13),.init(x:32,y:-21),.init(x:45,y:5),.init(x:-33,y:16)],[0xE5C18B,0xB68D5D,0x987C55])
            for i in 0..<7 {
                let x=CGFloat(i)*11-36
                p.line([.init(x:x,y:-11),.init(x:x+10,y:10)],0x8E7854,1)
                p.line([.init(x:x+3,y:-11),.init(x:x+12,y:8)],0xF4D49B,1)
            }
            for x:CGFloat in [-39,34] {
                for y:CGFloat in [-15,8] {
                    p.rounded(CGRect(x:x,y:y-25,width:6,height:31),2,[0xE6BD81,0x92774F])
                    p.oval(CGRect(x:x-1,y:y-27,width:9,height:5),[0xFFE0A0,0xB5935D])
                }
            }
            p.line([.init(x:-37,y:-30),.init(x:37,y:-37)],0xC49B64,4)
            p.line([.init(x:-37,y:-8),.init(x:37,y:-15)],0xDBB37C,4)
        }
    }
    private func mill(at point:CGPoint,size:CGFloat) {
        at(point,size:size) { p in
            p.cottage(at:CGPoint(x:-13,y:-2),size:0.83,leafRoof:false)
            p.rounded(CGRect(x:12,y:-67,width:12,height:67),3,[0xBE9A67,0x7F704F])
            let center=CGPoint(x:30,y:-25)
            for i in 0..<10 {
                let a=Double(i) * .pi / 5
                let end=CGPoint(x:center.x+CGFloat(cos(a))*29,y:center.y+CGFloat(sin(a))*29)
                p.line([center,end],0xA58152,4)
                p.at(end) { paddle in
                    var c=paddle.context;c.rotate(by:.radians(a))
                    VillageWorldPainter(context:c).rounded(CGRect(x:-3,y:-7,width:9,height:15),1,[0xE1BA7A,0xAA8557,0x7C6B4D])
                }
            }
            p.context.stroke(Path(ellipseIn:CGRect(x:4,y:-51,width:52,height:52)),with:.color(Color(dinoHex:0xD6B078)),lineWidth:4)
            p.context.stroke(Path(ellipseIn:CGRect(x:10,y:-45,width:40,height:40)),with:.color(Color(dinoHex:0x8B754F)),lineWidth:2)
            p.oval(CGRect(x:23,y:-32,width:14,height:14),[0xE7C48B,0x977B51])
            p.oval(CGRect(x:27,y:-28,width:6,height:6),[0xB18E5D,0x756A4E])
            p.plants(at:CGPoint(x:-43,y:12),size:0.73)
        }
    }
    private func garden(at point:CGPoint,size:CGFloat,variation:Int) {
        at(point,size:size) { p in
            p.oval(CGRect(x:-52,y:-14,width:104,height:34),[0xD7DFAB,0xA6C28C])
            if variation%3==0 { p.tree(at:CGPoint(x:0,y:0),size:0.83) }
            else {
                p.plants(at:CGPoint(x:-16,y:0),size:1.1)
                p.rock(at:CGPoint(x:22,y:7),size:0.66)
                p.fence(at:CGPoint(x:0,y:13),size:0.7)
            }
            p.flowers(at:CGPoint(x:23,y:18),size:0.8,pink:variation%2==0)
            p.flowers(at:CGPoint(x:-25,y:11),size:0.6,pink:variation%2 != 0)
        }
    }
    func scene(at point:CGPoint,size:CGFloat,variation:Int) {
        at(point, size: size, radius: 74 * size, rise: 135 * size) { p in
            p.oval(CGRect(x:-77,y:-18,width:154,height:49),[0xE3DFB1,0xBEC993,0xA9BE88])
            for i in 0..<6 {
                p.rounded(CGRect(x:CGFloat(i)*22-61,y:15+CGFloat(i%2)*4,width:19,height:7),2,[0xEFE0B7,0xB7B495])
            }
            switch variation%5 {
            case 0:
                p.tree(at:CGPoint(x:38,y:-23),size:0.7)
                p.cottage(at:CGPoint(x:-19,y:-2),size:0.92,leafRoof:variation>0)
                p.market(at:CGPoint(x:29,y:23),size:0.68,blue:variation==0)
            case 1:
                p.tree(at:CGPoint(x:-32,y:-15),size:0.82)
                p.fountain(at:CGPoint(x:15,y:9),size:0.85)
                p.fence(at:CGPoint(x:-7,y:30),size:0.9)
            case 2:
                p.tower(at:CGPoint(x:-11,y:0),size:0.88)
                p.cottage(at:CGPoint(x:41,y:13),size:0.48,leafRoof:false)
            case 3:
                p.mill(at:CGPoint(x:-4,y:4),size:1.05)
                p.fence(at:CGPoint(x:3,y:30),size:0.88)
            default:
                p.cottage(at:CGPoint(x:-23,y:-8),size:0.86,leafRoof:true)
                p.market(at:CGPoint(x:29,y:21),size:0.78,blue:false)
            }
            p.flowers(at:CGPoint(x:-49,y:24),size:0.7,pink:true)
            p.plants(at:CGPoint(x:51,y:31),size:0.66)
            p.rock(at:CGPoint(x:-62,y:22),size:0.43)
        }
    }
}

/// Threshold artwork borrows the existing chapter tail instead of adding space.
/// The static cave stays cached. Only small lamps, glints and worker canvases tick.
private struct CrystalCaveLife: View {
    let routeOffset: CGFloat
    let viewportHeight: CGFloat
    var fixedTime: TimeInterval? = nil
    var frozen = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewport = CGRect.zero

    private var reduceMotion: Bool { frozen || systemReduceMotion }

    var body: some View {
        GeometryReader { geometry in
            let layout = WorldSceneryLayout(width: geometry.size.width, height: geometry.size.height, routeOffset: routeOffset)
            ZStack(alignment: .topLeading) {
                ForEach(CrystalCaveLifeLayout.lamps(layout: layout)) { lamp in
                    CrystalCaveLamp(lamp: lamp, layout: layout, viewportHeight: viewportHeight, fixedTime: fixedTime, reduceMotion: reduceMotion)
                        .frame(width: 130 * layout.scale, height: 160 * layout.scale)
                        .position(x: lamp.pivot.x, y: lamp.pivot.y + 35 * layout.scale)
                }
                ForEach(0..<22, id: \.self) { index in
                    let glint = CrystalCaveLifeLayout.glint(index: index, layout: layout)
                    CrystalCaveGlint(index: index, point: glint.point, depth: glint.depth,
                                     layout: layout, viewportHeight: viewportHeight, fixedTime: fixedTime, reduceMotion: reduceMotion)
                        .frame(width: 28 * layout.scale, height: 28 * layout.scale)
                        .position(glint.point)
                }
                TimelineView(.animation(minimumInterval: 1.0 / 20,
                                        paused: fixedTime != nil || viewport.isEmpty || reduceMotion || scenePhase != .active)) { timeline in
                    let time = reduceMotion ? 0 : (fixedTime ?? timeline.date.timeIntervalSinceReferenceDate)
                    ForEach(CrystalMinerPatrol.routes.sorted { $0.pose(at: time).y < $1.pose(at: time).y }) { route in
                        let pose = route.pose(at: time)
                        let point = CrystalCaveLifeLayout.worker(pose: pose, right: route.right, layout: layout)
                        let frame = CGRect(x: point.x - 43 * layout.scale, y: point.y - 65 * layout.scale,
                                           width: 86 * layout.scale, height: 82 * layout.scale)
                        if fixedTime != nil || frame.intersects(viewport) {
                            Canvas { context, _ in
                                var c = context; c.translateBy(x: -frame.minX, y: -frame.minY)
                                let painter = CrystalCavePainter(context: c, hangingLamps: false)
                                painter.miner(at: point, size: layout.scale * 0.72, right: route.right,
                                              variation: route.id, pose: pose, time: reduceMotion ? 0 : time)
                                c.blendMode = .destinationOut
                                var scene = WorldSceneryDepth(minimumDepth: point.y, visibleBounds: frame)
                                CrystalCavePainter(context: c, hangingLamps: false).appendScenery(layout: layout, to: &scene)
                                scene.draw()
                            }
                            .frame(width: frame.width, height: frame.height)
                            .position(x: frame.midX, y: frame.midY)
                        }
                    }
                }
            }
            .onGeometryChange(for: CGRect.self) { proxy in
                let frame = proxy.frame(in: .named("adventure.map.viewport"))
                let top = max(0, -frame.minY), bottom = min(proxy.size.height, viewportHeight - frame.minY)
                return bottom > top ? CGRect(x: 0, y: top, width: proxy.size.width, height: bottom - top) : .zero
            } action: { viewport = $0 }
        }
        .clipped().allowsHitTesting(false).accessibilityHidden(true)
    }
}

private enum CrystalCaveLifeLayout {
    struct Lamp: Identifiable {
        let id: Int
        let pivot: CGPoint
        let parentSize: CGFloat
        let lampSize: CGFloat
        let drop: CGFloat
        let depth: CGFloat
    }

    static func lamps(layout: WorldSceneryLayout) -> [Lamp] {
        let s = layout.scale, w = layout.width
        var result: [Lamp] = []
        func add(_ point: CGPoint, size: CGFloat, right: Bool, workshop: Bool = false, offset: CGFloat,
                 solve: Bool = true) {
            let placed = solve ? layout.position(point, radius: (workshop ? 70 : 45) * size,
                                                rise: (workshop ? 183 : 140) * size) : point
            let localX: CGFloat = workshop ? 30 : 28, localY: CGFloat = workshop ? -143 : -116
            result.append(Lamp(id: result.count,
                               pivot: CGPoint(x: placed.x + (right ? -localX : localX) * size,
                                              y: offset + placed.y + localY * size),
                               parentSize: size, lampSize: workshop ? 0.96 : 1.10, drop: workshop ? 34 : 17,
                               depth: offset + placed.y + (workshop ? 29 : 10) * size))
        }
        let lift = CrystalCaveThresholdLayout(width: w).entranceLift
        for right in [false, true] {
            let x = w * (right ? 0.88 : 0.12)
            let side = abs((x - w / 2) / (w / 2))
            let y = (105 + 118 * pow(side, 1.65) + 90) * s
            add(CGPoint(x: x, y: y), size: s * 1.06, right: right, offset: -lift, solve: false)
        }
        for (y, right): (CGFloat, Bool) in [(95, false), (505, true), (1035, false)] {
            add(CGPoint(x: right ? w - 22 * s : 22 * s, y: y), size: s * 0.83, right: right, offset: layout.routeOffset)
        }
        for (y, right): (CGFloat, Bool) in [(335, false), (870, true), (1265, false)] {
            add(CGPoint(x: right ? w - 20 * s : 20 * s, y: y), size: s * 0.87, right: right,
                workshop: true, offset: layout.routeOffset)
        }
        return result
    }

    static func timberClearances(layout: WorldSceneryLayout) -> [CGRect] {
        let s = layout.scale, w = layout.width
        var result: [CGRect] = []
        func add(_ point: CGPoint, size: CGFloat, radius: CGFloat, rise: CGFloat,
                 local: CGRect, right: Bool = false, offset: CGFloat? = nil) {
            let placed = offset == nil ? layout.position(point, radius: radius * size, rise: rise * size) : point
            let x = right ? -local.maxX : local.minX
            result.append(CGRect(x: placed.x + x * size, y: (offset ?? layout.routeOffset) + placed.y + local.minY * size,
                                 width: local.width * size, height: local.height * size))
        }
        for (y, right): (CGFloat, Bool) in [(95,false),(505,true),(1035,false)] {
            add(CGPoint(x: right ? w-22*s : 22*s,y:y),size:s*0.83,radius:45,rise:140,
                local:CGRect(x:-29,y:-158,width:80,height:86),right:right)
        }
        for (y,right): (CGFloat,Bool) in [(335,false),(870,true),(1265,false)] {
            add(CGPoint(x:right ? w-20*s : 20*s,y:y),size:s*0.87,radius:70,rise:183,
                local:CGRect(x:-76,y:-195,width:153,height:236),right:right)
        }
        for (y,right,size): (CGFloat,Bool,CGFloat) in [(610,false,s*0.82),(1370,true,s*0.80)] {
            add(CGPoint(x:right ? w-10*s : 10*s,y:y),size:size,radius:74,rise:150,
                local:CGRect(x:-81,y:-107,width:161,height:168),right:right)
        }
        add(CGPoint(x:15*s,y:1080),size:s*0.80,radius:65,rise:105,
            local:CGRect(x:-64,y:-108,width:128,height:139))
        let lift = CrystalCaveThresholdLayout(width:w).entranceLift
        for right in [false,true] {
            let x = w * (right ? 0.88 : 0.12), side = abs((x-w/2)/(w/2))
            add(CGPoint(x:x,y:(105+118*pow(side,1.65)+90)*s),size:s*1.06,radius:0,rise:0,
                local:CGRect(x:-29,y:-158,width:80,height:86),right:right,offset:-lift)
        }
        add(CGPoint(x:w*0.66,y:244*s),size:s*0.81,radius:0,rise:0,
            local:CGRect(x:-81,y:-107,width:161,height:168),offset:-lift)
        return result
    }

    static func clearTimber(_ point: CGPoint, radius: CGFloat, rise: CGFloat, drop: CGFloat,
                            right: Bool, layout: WorldSceneryLayout) -> CGPoint {
        var point = point
        for zone in timberClearances(layout: layout) {
            let footprint = CGRect(x:point.x-radius,y:point.y-rise,width:radius*2,height:rise+drop)
            if footprint.intersects(zone) {
                point.x = right ? zone.maxX + radius + 8*layout.scale : zone.minX - radius - 8*layout.scale
            }
        }
        return point
    }

    static func mineral(index i: Int, layout: WorldSceneryLayout) -> (point: CGPoint, size: CGFloat, variation: Int) {
        let right = i.isMultiple(of:2), sign: CGFloat = right ? 1 : -1
        let y = layout.routeOffset + 62 + CGFloat(i/2)*64 + (right ? 0 : 39)
        let x = wallX(at:y,right:right,distance:153,layout:layout) + sign*18*layout.scale
        let size = layout.scale * (0.48 + CGFloat(i%4)*0.12)
        let point = clearTimber(CGPoint(x:x,y:y),radius:66*size,rise:136*size,drop:28*size,right:right,layout:layout)
        return (point,size,(i*7+i/4)%6)
    }

    static func worker(pose: CrystalMinerPatrol.Pose, right: Bool, layout: WorldSceneryLayout) -> CGPoint {
        let s = layout.scale, y = CGFloat(pose.y)
        // A separate shoulder leaves the road and the level stones clear.
        let offset = (58 + CGFloat(pose.outward) * (workOffset(at: y, right: right) - 58)) * s
        return CGPoint(x: layout.centerX(at: y) + (right ? offset : -offset), y: layout.routeOffset + y)
    }

    private static func workOffset(at y: CGFloat, right: Bool) -> CGFloat {
        // Two seams lie inside a recess: workers vanish behind the clock rock
        // or the terrace, then emerge along the same detour.
        (right && abs(y - 980) < 1) || (!right && abs(y - 465) < 1) ? 135 : 95
    }

    static func ore(at y: CGFloat, right: Bool, layout: WorldSceneryLayout) -> CGPoint {
        CGPoint(x: layout.centerX(at: y) + (right ? 1 : -1) * (workOffset(at: y, right: right) + 24) * layout.scale,
                y: layout.routeOffset + y - 7 * layout.scale)
    }

    static func wallX(at y: CGFloat, right: Bool, distance: CGFloat, layout: WorldSceneryLayout) -> CGFloat {
        let scale = layout.scale, sign: CGFloat = right ? 1 : -1
        let outside = right ? layout.width + 110 * scale : -110 * scale
        func smooth(_ value: CGFloat) -> CGFloat {
            let t = min(1, max(0, value))
            return t * t * t * (t * (6 * t - 15) + 10)
        }
        let edgeAmount = smooth(y / 160) * smooth((layout.height - y) / 160)
        let bend = layout.width / 2 + (layout.centerX(at: y - layout.routeOffset) - layout.width / 2) * smooth(y / 80)
        let relief = (sin(y / 89 + (right ? 0.9 : 0)) * 11 + sin(y / 43) * 4) * scale * edgeAmount
        let wall = bend + sign * (distance * scale + relief)
        // The sides grow below the entrance crown, after the outdoor clearing.
        let entered = smooth((y - 84 * scale) / (220 * scale))
        return outside + (wall - outside) * entered
    }

    static func glint(index: Int, layout: WorldSceneryLayout) -> (point: CGPoint, depth: CGFloat) {
        let mineral = mineral(index:index*2+index%2,layout:layout)
        let faceHeight: CGFloat = (mineral.variation%2 == 0 ? 99 : 108)*0.74
        return (CGPoint(x:mineral.point.x-5*mineral.size,y:mineral.point.y-faceHeight*mineral.size),
                mineral.point.y+22*mineral.size)
    }

}

/// Local masks are cached for fixed lamps and glints; only a worker's small
/// mask changes as its feet pass behind a lower ledge or timber platform.
private struct CrystalCaveOcclusion: View {
    let layout: WorldSceneryLayout
    let frame: CGRect
    let depth: CGFloat
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
            var c = context; c.translateBy(x: -frame.minX, y: -frame.minY); c.blendMode = .destinationOut
            var scene = WorldSceneryDepth(minimumDepth: depth, visibleBounds: frame)
            CrystalCavePainter(context: c, hangingLamps: false).appendScenery(layout: layout, to: &scene)
            scene.draw()
        }
    }
}

private struct CrystalCaveLamp: View {
    let lamp: CrystalCaveLifeLayout.Lamp
    let layout: WorldSceneryLayout
    let viewportHeight: CGFloat
    var fixedTime: TimeInterval?
    let reduceMotion: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false
    var body: some View {
        let s = layout.scale
        let frame = CGRect(x: lamp.pivot.x - 65 * s, y: lamp.pivot.y - 45 * s, width: 130 * s, height: 160 * s)
        TimelineView(.animation(minimumInterval: 1.0 / 20,
                                paused: fixedTime != nil || !visible || reduceMotion || scenePhase != .active)) { timeline in
            Canvas { context, _ in
                let time = fixedTime ?? timeline.date.timeIntervalSinceReferenceDate
                let angle = reduceMotion ? 0 : sin(time * 1.25 + Double(lamp.id) * 1.7) * 0.055
                var c = context; c.translateBy(x: 65 * s, y: 45 * s); c.rotate(by: .radians(angle))
                CrystalCavePainter(context: c).swingingLamp(size: lamp.parentSize, lampSize: lamp.lampSize, drop: lamp.drop)
            }
        }
        .mask(CrystalCaveOcclusion(layout: layout, frame: frame, depth: lamp.depth))
        .onGeometryChange(for: Bool.self) { proxy in
            let frame = proxy.frame(in: .named("adventure.map.viewport"))
            return frame.maxY > 0 && frame.minY < viewportHeight
        } action: { visible = $0 }
    }
}

private struct CrystalCaveGlint: View {
    let index: Int
    let point: CGPoint
    let depth: CGFloat
    let layout: WorldSceneryLayout
    let viewportHeight: CGFloat
    var fixedTime: TimeInterval?
    let reduceMotion: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false
    var body: some View {
        let s = layout.scale
        TimelineView(.animation(minimumInterval: 1.0 / 15,
                                paused: fixedTime != nil || !visible || reduceMotion || scenePhase != .active)) { timeline in
            Canvas { context, size in
                let time = fixedTime ?? timeline.date.timeIntervalSinceReferenceDate
                let phase = (time + Double(index) * 1.73).truncatingRemainder(dividingBy: 6.8)
                let pulse = reduceMotion ? 0.2 : pow(max(0, sin(min(1, phase / 0.95) * .pi)), 3)
                if pulse > 0.01 {
                    var c = context; c.opacity = pulse
                    CrystalCavePainter(context: c).mineralGlint(at: CGPoint(x: size.width / 2, y: size.height / 2), radius: (1.6 + pulse * 1.2) * s)
                }
            }
        }
        .mask(CrystalCaveOcclusion(layout: layout,
                                  frame: CGRect(x: point.x - 14 * s, y: point.y - 14 * s, width: 28 * s, height: 28 * s), depth: depth))
        .onGeometryChange(for: Bool.self) { proxy in
            let frame = proxy.frame(in: .named("adventure.map.viewport"))
            return frame.maxY > 0 && frame.minY < viewportHeight
        } action: { visible = $0 }
    }
}

private struct CrystalCaveThresholdLayout {
    let width: CGFloat
    var scale: CGFloat { min(1.30, max(0.82, width / 390)) }
    private var topClearance: CGFloat {
        max(0, min(200, (min(width, 600) - 36) * 0.37) - 82)
    }
    // Fit the stone crowns after the boss caption, including on a 320pt phone.
    var entranceLift: CGFloat { min(100 * scale, WorldRouteTrail.chapterTail(topClearance: topClearance) - 85 + 34 * scale) }
    // The inner lining is 146pt wide. Leave 16pt around the map Dino's full frame.
    private static func exitScale(topClearance: CGFloat) -> CGFloat { (82 + topClearance + 16) / 146 }
    var exitScale: CGFloat { Self.exitScale(topClearance: topClearance) }
    // Move the boundary down instead of shrinking the doorway to fit above it.
    // Include the rock hood (-128), its spring offset (-118), and the boss caption.
    static func exitChapterTail(topClearance: CGFloat) -> CGFloat {
        max(WorldRouteTrail.chapterTail(topClearance: topClearance), 85 - 12 + (128 + 118) * exitScale(topClearance: topClearance))
    }
    var exitSpringY: CGFloat { 12 - 118 * exitScale }
    var exitHeadroom: CGFloat { max(Self.headroom, (128 + 118) * exitScale) }
    static let headroom: CGFloat = 256
}

/// The entrance lip covers the trail; the world title stays in front of the rock.
struct CrystalCaveEntranceForeground: View, Equatable {
    var body: some View {
        Canvas { context, size in
            var c = context
            c.translateBy(x: 0, y: CrystalCaveThresholdLayout.headroom)
            // The rest of this roof joins the depth-sorted scenery in world 5.
            c.clip(to: Path(CGRect(x: 0, y: -CrystalCaveThresholdLayout.headroom,
                                  width: size.width, height: CrystalCaveThresholdLayout.headroom)))
            CrystalCavePainter(context: c).entranceForeground(width: size.width)
        }
        .frame(height: 600).clipped().offset(y: -CrystalCaveThresholdLayout.headroom)
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// The departure gate crosses the trail after level 50, before the city.
struct CrystalCaveExitForeground: View, Equatable {
    var body: some View {
        GeometryReader { geometry in
            let headroom = CrystalCaveThresholdLayout(width: geometry.size.width).exitHeadroom
            Canvas { context, size in
                var c = context
                c.translateBy(x: 0, y: headroom)
                CrystalCavePainter(context: c).exitForeground(width: size.width)
            }
            .frame(height: headroom + 360).clipped().offset(y: -headroom)
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// The cave's illuminated facets and rocky enclosure are exclusive to world five.
private struct CrystalCavePainter {
    let context: GraphicsContext
    var scenery: WorldSceneryLayout? = nil
    var hangingLamps = true

    private typealias DepthScene = WorldSceneryDepth

    private func at(_ point: CGPoint, size: CGFloat = 1, mirror: Bool = false, radius: CGFloat = 0, rise: CGFloat = 0,
                    clearTimber: Bool = false, draw: (CrystalCavePainter) -> Void) {
        var point = scenery?.position(point, radius: radius, rise: rise) ?? point
        if clearTimber, let scenery {
            let placed = CrystalCaveLifeLayout.clearTimber(CGPoint(x:point.x,y:point.y+scenery.routeOffset),
                                                          radius:radius+10*size,rise:rise,drop:48*size,
                                                          right:point.x>scenery.width/2,layout:scenery)
            point = CGPoint(x:placed.x,y:placed.y-scenery.routeOffset)
        }
        var c = context
        c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: mirror ? -size : size, y: size)
        draw(.init(context: c, hangingLamps: hangingLamps))
    }
    private func material(_ path: Path, colors: [UInt32]) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
    }
    private func contour(_ points: [CGPoint], radius: CGFloat = 5) -> Path {
        guard points.count > 2 else { return Path() }
        func near(_ p: CGPoint, _ corner: CGPoint) -> CGPoint {
            let t = min(0.28, radius / max(0.01, hypot(p.x - corner.x, p.y - corner.y)))
            return CGPoint(x: corner.x + (p.x - corner.x) * t, y: corner.y + (p.y - corner.y) * t)
        }
        return Path { p in
            for i in points.indices {
                let corner = points[i], previous = points[(i + points.count - 1) % points.count], next = points[(i + 1) % points.count]
                if i == 0 { p.move(to: near(previous, corner)) } else { p.addLine(to: near(previous, corner)) }
                p.addQuadCurve(to: near(next, corner), control: corner)
            }
            p.closeSubpath()
        }
    }
    private func ground(at point: CGPoint, width: CGFloat, height: CGFloat, color: UInt32 = 0x354969, opacity: Double = 0.26) {
        var c = context; c.translateBy(x: point.x, y: point.y); c.scaleBy(x: width / 2, y: height / 2)
        c.fill(Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2)), with: .radialGradient(Gradient(stops: [
            .init(color: Color(dinoHex: color).opacity(opacity), location: 0),
            .init(color: Color(dinoHex: color).opacity(opacity * 0.7), location: 0.5),
            .init(color: .clear, location: 1)
        ]), center: .zero, startRadius: 0, endRadius: 1))
    }
    private func polygon(_ points: [CGPoint], colors: [UInt32]) {
        var p = Path(); p.addLines(points); p.closeSubpath(); material(p, colors: colors)
    }
    private func rounded(_ r: CGRect, radius: CGFloat, colors: [UInt32]) {
        material(Path(roundedRect: r, cornerRadius: radius), colors: colors)
    }
    private func oval(_ r: CGRect, colors: [UInt32]) {
        context.fill(Path(ellipseIn: r), with: .radialGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                            center: CGPoint(x: r.minX + r.width * 0.3, y: r.minY + r.height * 0.2),
                                                            startRadius: 0, endRadius: max(r.width, r.height) * 0.85))
    }
    private func line(_ points: [CGPoint], color: UInt32, width: CGFloat, opacity: Double = 1) {
        var p = Path(); p.addLines(points)
        context.stroke(p, with: .color(Color(dinoHex: color).opacity(opacity)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func glow(_ point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), Color(dinoHex: color).opacity(0)]),
                                           center: point, startRadius: 0, endRadius: radius))
    }
    private func sparkle(at point: CGPoint, radius: CGFloat) {
        glow(point, radius: radius * 4, color: 0xE2FFF8, opacity: 0.35)
        let shape = Path { p in
            p.addLines([.init(x: point.x, y: point.y - radius), .init(x: point.x + radius * 0.25, y: point.y - radius * 0.25),
                        .init(x: point.x + radius, y: point.y), .init(x: point.x + radius * 0.25, y: point.y + radius * 0.25),
                        .init(x: point.x, y: point.y + radius), .init(x: point.x - radius * 0.25, y: point.y + radius * 0.25),
                        .init(x: point.x - radius, y: point.y), .init(x: point.x - radius * 0.25, y: point.y - radius * 0.25)])
            p.closeSubpath()
        }
        context.fill(shape, with: .color(Color(dinoHex: 0xF2FFF7).opacity(0.92)))
    }

    private enum Passage { case arrival, departure }

    private func smooth(_ value: CGFloat) -> CGFloat {
        let t = min(1, max(0, value))
        return t * t * t * (t * (6 * t - 15) + 10)
    }

    /// The same cross-section is drawn on both sides of each chapter boundary.
    private func wallX(at y: CGFloat, right: Bool, distance: CGFloat, layout: WorldSceneryLayout, passage: Passage? = nil) -> CGFloat {
        let scale = layout.scale, sign: CGFloat = right ? 1 : -1
        let joint = layout.width / 2 + sign * distance * scale
        let outside = right ? layout.width + 110 * scale : -110 * scale
        if let passage {
            if passage == .departure {
                let framed = layout.width / 2 + sign * distance * scale * (1 - 0.14 * smooth(y / (170 * scale)))
                return framed + (outside - framed) * smooth((y - 160 * scale) / (180 * scale))
            }
            return outside + (joint - outside) * smooth((y - layout.height + 520) / 520)
        }
        return CrystalCaveLifeLayout.wallX(at: y, right: right, distance: distance, layout: layout)
    }

    private func wallPath(right: Bool, distance: CGFloat, layout: WorldSceneryLayout, passage: Passage? = nil) -> Path {
        let outside = right ? layout.width + 160 : -160
        return Path { path in
            path.move(to: CGPoint(x: outside, y: -10))
            let count = Int(ceil((layout.height + 32) / 8))
            for i in 0...count {
                let y = -8 + (layout.height + 32) * CGFloat(i) / CGFloat(count)
                path.addLine(to: CGPoint(x: wallX(at: y, right: right, distance: distance, layout: layout, passage: passage), y: y))
            }
            path.addLine(to: CGPoint(x: outside, y: layout.height + 24))
            path.closeSubpath()
        }
    }

    private func fillFloor(_ floor: Path, width: CGFloat) {
        context.fill(floor, with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: 0x2D4268), location: 0),
            .init(color: Color(dinoHex: 0x43688F), location: 0.30),
            .init(color: Color(dinoHex: 0x719BA6), location: 0.50),
            .init(color: Color(dinoHex: 0x42668B), location: 0.72),
            .init(color: Color(dinoHex: 0x283E65), location: 1)
        ]), startPoint: .zero, endPoint: CGPoint(x: width, y: 0)))
    }

    /// A whole boulder owns its silhouette; only its internal facets are clipped.
    private func wallBoulder(in rect: CGRect, variation: Int, distant: Bool = false, warm: Bool = false) {
        let v = variation % 5
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        let shoulder = CGFloat(v) * 0.025
        let points: [CGPoint]
        switch v {
        case 0:
            points = [point(0, 0.35), point(0.17, 0.06), point(0.57, 0),
                      point(0.88, 0.16), point(1, 0.58), point(0.91, 0.91),
                      point(0.56, 1), point(0.12, 0.88), point(0.02, 0.66)]
        case 1:
            points = [point(0, 0.49), point(0.10, 0.20), point(0.43, 0),
                      point(0.79, 0.04), point(1, 0.38), point(0.94, 0.84),
                      point(0.67, 1), point(0.19, 0.94), point(0.02, 0.74)]
        case 2:
            points = [point(0, 0.30), point(0.26, 0.04), point(0.69, 0),
                      point(0.94, 0.29), point(1, 0.69), point(0.79, 0.95),
                      point(0.38, 1), point(0.06, 0.82), point(0.03, 0.55)]
        case 3:
            points = [point(0, 0.46), point(0.22, 0.10), point(0.48, 0),
                      point(0.90, 0.13), point(1, 0.52), point(0.86, 0.86),
                      point(0.47, 1), point(0.09, 0.94), point(0.04, 0.69)]
        default:
            points = [point(0, 0.24), point(0.14, 0.02), point(0.62, 0),
                      point(0.83, 0.26), point(1, 0.47), point(0.94, 0.89),
                      point(0.61, 1), point(0.17, 0.96), point(0.02, 0.71)]
        }
        let stone = contour(points, radius: min(rect.width, rect.height) * 0.065)
        context.fill(stone.offsetBy(dx: 0, dy: rect.height * 0.055),
                     with: .color(Color(dinoHex: 0x172C4A).opacity(0.64)))
        let palettes: [[UInt32]] = distant
            ? [[0x526887, 0x354F73, 0x233B5D], [0x5E708F, 0x405678, 0x293D60],
               [0x4D678C, 0x344D73, 0x203758]]
            : [[0x8F9FB5, 0x627B9D, 0x3B567E], [0x8195B0, 0x566F95, 0x324C75],
               [0x9AA9BB, 0x6B829F, 0x425D7E]]
        material(stone, colors: palettes[variation % palettes.count])
        var clipped = context; clipped.clip(to: stone)
        let detail = CrystalCavePainter(context: clipped)
        let fold = point(0.33 + shoulder, 0.34 + CGFloat(v % 2) * 0.09)
        detail.polygon([points[0], points[1], points[2], points[3], fold, point(0.08, 0.64)],
                       colors: distant ? [0x7585A1, 0x516A8D, 0x3E587C] : [0xB3BEC9, 0x8FA4BA, 0x6D87A7])
        detail.polygon([fold, points[3], points[4], points[5], points[6], point(0.58, 0.73)],
                       colors: distant ? [0x3D557B, 0x233B61] : [0x637FA3, 0x354F78])
        detail.line([point(0.19, 0.55), point(0.39, 0.64), point(0.34, 0.84)],
                    color: 0x253E61, width: max(0.7, rect.width * 0.012), opacity: 0.65)
        if v % 2 == 0 {
            detail.line([point(0.70, 0.24), point(0.64, 0.44), point(0.76, 0.55)],
                        color: 0x273E5B, width: max(0.6, rect.width * 0.009), opacity: 0.6)
        }
        if warm {
            detail.context.fill(stone, with: .linearGradient(Gradient(colors: [
                .clear, Color(dinoHex: 0xD2D2AE).opacity(0.22)
            ]), startPoint: point(0, 0.38), endPoint: point(0, 1)))
        }
    }

    /// Staggered courses fill the entire outer bank, including the broad bends.
    private func wallBoulders(layout: WorldSceneryLayout, right: Bool) {
        let s = layout.scale, sign: CGFloat = right ? 1 : -1
        let step = 53 * s
        let rows = Int(ceil((layout.height - layout.routeOffset + 90 * s) / step))
        for row in 0..<rows {
            let base = layout.routeOffset + CGFloat(row) * step
            let height = (92 + CGFloat((row * 7 + (right ? 3 : 0)) % 5) * 7) * s
            // Sample the full height so a projecting corner stays off the trail.
            let edges = (0...6).map { i in
                wallX(at: base - height + CGFloat(i) * height / 6,
                      right: right, distance: 127, layout: layout)
            }
            let inner = right ? edges.max()! : edges.min()!
            let span = right ? layout.width - inner : inner
            guard span > -24 * s else { continue }
            let columns = max(1, Int(ceil((span + 45 * s) / (64 * s))))
            for column in (0..<columns).reversed() {
                let seed = row * 13 + column * 7 + (right ? 19 : 0)
                let width = (88 + CGFloat(seed % 4) * 8) * s
                let stagger = column == 0 ? 0 : CGFloat(row % 3 - 1) * 13 * s
                let x = inner + sign * (CGFloat(column) * 64 * s - 4 * s + stagger)
                let y = base + CGFloat(seed % 5 - 2) * 4 * s
                let blockHeight = height + CGFloat(seed % 3 - 1) * 9 * s
                let rect = CGRect(x: right ? x : x - width, y: y - blockHeight,
                                  width: width, height: blockHeight)
                wallBoulder(in: rect, variation: seed, distant: column > 0)
                if column > 0 && seed%4 == 0 {
                    let growth = s*(0.24+CGFloat(seed%3)*0.055)
                    let root = CGPoint(x:rect.midX,y:rect.minY+rect.height*0.25)
                    let envelope = CGRect(x:root.x-66*growth,y:root.y-136*growth,width:132*growth,height:164*growth)
                    if !CrystalCaveLifeLayout.timberClearances(layout:layout).contains(where: { $0.intersects(envelope) }) {
                        cluster(at:root,size:growth,variation:seed%6)
                    }
                }
            }
        }
    }

    /// The compact doorway reveals the city underneath its inner arch.
    /// Outside the pillars the cave retreats toward the edges of the screen.
    private func exitBoundaryY(x: CGFloat, width: CGFloat, scale: CGFloat) -> CGFloat {
        let threshold = CrystalCaveThresholdLayout(width: width)
        let d = abs(x - width / 2), inner = 82 * threshold.exitScale
        if d <= inner {
            let t = d / inner
            return threshold.exitSpringY - 76 * sqrt(max(0, 1 - t * t)) * threshold.exitScale
        }
        let foot = threshold.exitSpringY + 105 * threshold.exitScale
        let shoulder = max(120 * threshold.exitScale, 57 * scale)
        if d < shoulder {
            return threshold.exitSpringY + (foot - threshold.exitSpringY) * smooth((d - inner) / (shoulder - inner))
        }
        // A shallow, broken footline replaces the descending banks.
        // Both sides meet the city at essentially the same height.
        return (8 + sin(x / (39 * scale)) * 1.8 + sin(x / (17 * scale)) * 0.9) * scale
    }

    private func exitCaveMask(width: CGFloat, height: CGFloat, scale: CGFloat) -> Path {
        Path { p in
            p.move(to: CGPoint(x: 0, y: -160))
            p.addLine(to: CGPoint(x: width, y: -160))
            for i in (0...96).reversed() {
                let x = width * CGFloat(i) / 96
                let y = min(height, exitBoundaryY(x: x, width: width, scale: scale))
                p.addLine(to: CGPoint(x: x, y: y))
            }
            p.closeSubpath()
        }
    }

    /// The gate sits in one cliff face. Its foot stays level across the map;
    /// the individual stone courses build upward into the existing cavern.
    func exitForeground(width: CGFloat) {
        exitArch(width: width)
    }

    func exitWall(width: CGFloat, boundaryY: CGFloat = 0) {
        let threshold = CrystalCaveThresholdLayout(width: width)
        let s = threshold.scale
        var wallContext = context
        wallContext.translateBy(x: 0, y: boundaryY)
        let wall = CrystalCavePainter(context: wallContext)
        for right in [false, true] {
            let span = width / 2 - (right ? 130 : 134) * threshold.exitScale
            let c: GraphicsContext = {
                var transformed = wall.context
                if right { transformed.translateBy(x: width, y: 0); transformed.scaleBy(x: -1, y: 1) }
                return transformed
            }()
            let p = CrystalCavePainter(context: c)
            p.ground(at: CGPoint(x: span * 0.46, y: 14 * s), width: span * 1.35,
                     height: 42 * s, color: 0x4C6875, opacity: 0.23)
            // Each successive course reaches farther toward the gate. The exposed
            // steps are the boulders' own edges, with no shared silhouette mask.
            let reaches: [CGFloat] = right ? [0.23, 0.36, 0.52, 0.67, 0.79, 0.94, 1.07]
                                          : [0.19, 0.34, 0.51, 0.65, 0.81, 0.95, 1.08]
            for row in reaches.indices {
                let reach = span * reaches[row]
                let count = max(1, Int(ceil((reach + 24 * s) / (61 * s))))
                let spacing = (reach + 24 * s) / CGFloat(count)
                for column in 0..<count {
                    let seed = row * 11 + column * 7 + (right ? 23 : 0)
                    let height = (79 + CGFloat(seed % 5) * 7) * s
                    let base = (-300 + CGFloat(row) * 50 + CGFloat(seed % 3) * 3) * s
                    let outer = -24 * s + CGFloat(column) * spacing
                    let edge = column == count - 1 ? reach : outer + spacing + 28 * s
                    p.wallBoulder(in: CGRect(x: outer, y: base - height,
                                            width: edge - outer, height: height),
                                  variation: seed, warm: row >= 5)
                }
            }
            // Two distinct planting compositions grow from joints and shelves.
            // Each mineral root belongs to a ledge or crack, away from the passage.
            if right {
                p.cluster(at: CGPoint(x: span * 0.18, y: -68 * s), size: 0.23 * s, variation: 4)
                p.cluster(at: CGPoint(x: span * 0.77, y: -150 * s), size: 0.28 * s, variation: 4)
                p.exitMineralSeam(at: CGPoint(x: span * 0.39, y: -126 * s), size: 0.61 * s, tint: 3, mirror: true)
                p.exitMineralSeam(at: CGPoint(x: span * 0.43, y: -223 * s), size: 0.47 * s, tint: 4)
                p.moss(at: CGPoint(x: span * 0.91, y: -138 * s), size: 0.36 * s)
                p.hangingVine(at: CGPoint(x: span * 0.89, y: -135 * s), length: 39, mirror: true, scale: 0.43 * s)
                p.moss(at: CGPoint(x: span * 0.62, y: -41 * s), size: 0.61 * s)
                p.hangingVine(at: CGPoint(x: span * 0.66, y: -91 * s), length: 71, mirror: true, scale: 0.53 * s)
                p.plants(at: CGPoint(x: span * 0.87, y: 4 * s), size: 0.45 * s)
                JunglePainter(context: c).fern(at: CGPoint(x: span * 0.13, y: 6 * s), size: 0.37 * s, flipped: true)
                p.moss(at: CGPoint(x: span * 0.81, y: -55 * s), size: 0.33 * s)
                JunglePainter(context: c).flowers(at: CGPoint(x: span * 0.81, y: -56 * s), size: 0.27 * s)
                p.moss(at: CGPoint(x: span * 0.93, y: -81 * s), size: 0.47 * s)
            } else {
                p.cluster(at: CGPoint(x: span * 0.36, y: -143 * s), size: 0.34 * s, variation: 3)
                p.cluster(at: CGPoint(x: span * 0.25, y: -257 * s), size: 0.26 * s, variation: 3)
                p.exitMineralSeam(at: CGPoint(x: span * 0.09, y: -103 * s), size: 0.64 * s, tint: 4)
                p.exitMineralSeam(at: CGPoint(x: span * 0.67, y: -176 * s), size: 0.49 * s, tint: 3)
                p.moss(at: CGPoint(x: span * 0.45, y: -239 * s), size: 0.36 * s)
                p.hangingVine(at: CGPoint(x: span * 0.47, y: -237 * s), length: 47, mirror: false, scale: 0.45 * s)
                p.moss(at: CGPoint(x: span * 0.72, y: -83 * s), size: 0.63 * s)
                p.hangingVine(at: CGPoint(x: span * 0.75, y: -72 * s), length: 78, mirror: false, scale: 0.61 * s)
                p.moss(at: CGPoint(x: span * 0.20, y: -28 * s), size: 0.50 * s)
                JunglePainter(context: c).fern(at: CGPoint(x: span * 0.62, y: 7 * s), size: 0.33 * s, flipped: false)
                JunglePainter(context: c).flowers(at: CGPoint(x: span * 0.76, y: -79 * s), size: 0.34 * s)
                p.plants(at: CGPoint(x: span * 0.92, y: 5 * s), size: 0.36 * s)
            }
            for i in 0..<5 {
                let x = span * (CGFloat(i) + 0.35) / 5
                p.rock(at: CGPoint(x: x, y: (8 + CGFloat((i + (right ? 1 : 0)) % 3)) * s),
                       size: (0.09 + CGFloat((i * 3 + (right ? 1 : 0)) % 4) * 0.025) * s)
            }
        }
        wall.exitShoulders(width: width)
    }

    /// Rock shoulders bridge the two small gaps above the outer gate stones.
    /// They stay outside the inner opening and below the boss caption's centre lane.
    private func exitShoulders(width: CGFloat) {
        let threshold = CrystalCaveThresholdLayout(width: width)
        at(CGPoint(x: width / 2, y: threshold.exitSpringY), size: threshold.exitScale) { p in
            let layers: [[CGPoint]] = [
                [.init(x:-360,y:-268),.init(x:-282,y:-286),.init(x:-199,y:-240),.init(x:-131,y:-195),
                 .init(x:-115,y:-142),.init(x:-177,y:-112),.init(x:-280,y:-120),.init(x:-351,y:-164)],
                [.init(x:349,y:-276),.init(x:264,y:-295),.init(x:188,y:-235),.init(x:117,y:-193),
                 .init(x:108,y:-137),.init(x:180,y:-116),.init(x:296,y:-127),.init(x:356,y:-181)],
                [.init(x:-309,y:-168),.init(x:-237,y:-191),.init(x:-167,y:-172),.init(x:-94,y:-116),
                 .init(x:-112,y:-80),.init(x:-189,y:-64),.init(x:-286,y:-90)],
                [.init(x:319,y:-173),.init(x:252,y:-209),.init(x:173,y:-177),.init(x:97,y:-120),
                 .init(x:116,y:-83),.init(x:212,y:-64),.init(x:305,y:-103)]
            ]
            for (index, points) in layers.enumerated() {
                let stone = p.contour(points, radius: index < 2 ? 9 : 7)
                p.context.fill(stone.offsetBy(dx: 2,dy: 6), with: .color(Color(dinoHex:0x253D5F).opacity(0.65)))
                p.material(stone, colors: index < 2 ? [0x94A3B5,0x6A809F,0x3D5679] : [0xA6B1BB,0x7D8FA5,0x4D6484])
                let clipped: GraphicsContext = {
                    var c = p.context; c.clip(to: stone); return c
                }()
                let facet = CrystalCavePainter(context: clipped)
                let r = stone.boundingRect
                let fold = CGPoint(x:r.midX + (index % 2 == 0 ? -8 : 12),y:r.minY+r.height*0.44)
                facet.polygon([points[0],points[1],points[2],points[3],fold], colors:[0xC0C6C6,0x91A2B5,0x6C829F])
                facet.polygon([fold,points[3],points[4],points[5],points[6]], colors:[0x758BA8,0x4B6488,0x354F73])
                facet.line([.init(x:r.midX-17,y:r.minY+9),fold,.init(x:fold.x-9,y:fold.y+21)],
                           color:0x3B5577,width:1.7,opacity:0.75)
                p.line([points[0],points[1],points[2]],color:0xD3D5CB,width:1.5,opacity:0.42)
            }
            // Minerals grow from the shoulder's top ledge; moss roots in its lower seam.
            p.cluster(at:CGPoint(x:-246,y:-184),size:0.43,variation:3)
            p.moss(at:CGPoint(x:-180,y:-142),size:0.40)
            p.hangingVine(at:CGPoint(x:-177,y:-142),length:39,mirror:false,scale:0.64)
            p.crystal(at:CGPoint(x:198,y:-175),height:42,tint:4)
            p.crystal(at:CGPoint(x:217,y:-168),height:28,tint:5)
            p.moss(at:CGPoint(x:238,y:-166),size:0.40)
            JunglePainter(context:p.context).flowers(at:CGPoint(x:228,y:-166),size:0.30)
        }
    }

    /// Small mineral growth is anchored in an exposed crack, with a mossy lower lip.
    private func exitMineralSeam(at point: CGPoint, size: CGFloat, tint: Int, mirror: Bool = false) {
        at(point,size:size,mirror:mirror) { p in
            p.line([.init(x:-17,y:-20),.init(x:-7,y:-9),.init(x:-10,y:1),.init(x:5,y:11),.init(x:23,y:8)],
                   color:0x2B4568,width:2.3,opacity:0.82)
            p.line([.init(x:-14,y:-18),.init(x:-5,y:-9),.init(x:-8,y:1)],
                   color:tint % 3 == 0 ? 0x8FDBE4 : 0xC1A4E4,width:0.8,opacity:0.65)
            for (x,y,h,angle):(CGFloat,CGFloat,CGFloat,Double) in [(-7,1,28,-18),(3,8,20,16),(13,9,12,30)] {
                var c = p.context;c.translateBy(x:x,y:y);c.rotate(by:.degrees(angle))
                CrystalCavePainter(context:c).crystal(at:.zero,height:h,tint:tint)
            }
            p.moss(at:CGPoint(x:19,y:11),size:0.24)
        }
    }

    /// Overlapping talus binds the lower gate shoulders to the cavern floor.
    /// These rocks stay outside the passage and sit behind the dressed pillars.
    private func exitFootings() {
        for right in [false, true] {
            at(.zero, mirror: !right) { p in
                let offset: CGFloat = right ? 5 : -3
                p.wallBoulder(in: CGRect(x: 145, y: 18 + offset, width: 102, height: 94),
                              variation: right ? 8 : 6, warm: true)
                p.wallBoulder(in: CGRect(x: 129, y: 67 - offset, width: 93, height: 63),
                              variation: right ? 12 : 9, warm: true)
                p.wallBoulder(in: CGRect(x: 108, y: 100 + offset, width: 76, height: 38),
                              variation: right ? 14 : 11, warm: true)
                p.wallBoulder(in: CGRect(x: 196, y: 107 - offset, width: 58, height: 29),
                              variation: right ? 7 : 13, warm: true)
                p.rock(at: CGPoint(x: 101, y: 122 + offset), size: 0.34)
                p.rock(at: CGPoint(x: 177, y: 139 - offset), size: 0.23)
                p.moss(at: CGPoint(x: 146, y: 127 + offset), size: right ? 0.48 : 0.59)
                p.moss(at: CGPoint(x: 211, y: 119 - offset), size: 0.32)
                JunglePainter(context: p.context).fern(at: CGPoint(x: 189, y: 129 - offset),
                                                     size: right ? 0.33 : 0.27, flipped: right)
            }
        }
    }

    /// Preserve the original arch, pillars and ornaments with uniform scaling.
    private func exitArch(width: CGFloat) {
        let threshold = CrystalCaveThresholdLayout(width: width)
        at(CGPoint(x: width / 2, y: threshold.exitSpringY), size: threshold.exitScale) { p in
            // A broken mineral hood embeds the dressed arch in the cavern wall.
            // Its opening matches the masonry, so the road still passes through.
            let hood = Path { a in
                a.addLines([.init(x: -193, y: 108), .init(x: -202, y: 55), .init(x: -185, y: -9),
                            .init(x: -164, y: -58), .init(x: -119, y: -96), .init(x: -65, y: -119),
                            .init(x: -18, y: -128), .init(x: 26, y: -124), .init(x: 71, y: -113),
                            .init(x: 129, y: -83), .init(x: 172, y: -40), .init(x: 193, y: 18),
                            .init(x: 184, y: 107), .init(x: 82, y: 107), .init(x: 82, y: 0)])
                a.addCurve(to: .init(x: -82, y: 0), control1: .init(x: 82, y: -101.33), control2: .init(x: -82, y: -101.33))
                a.addLine(to: .init(x: -82, y: 108)); a.closeSubpath()
            }
            p.material(hood, colors: [0xA3B1BD, 0x677D99, 0x2A4365])
            var stoneContext = p.context; stoneContext.clip(to: hood)
            let stone = CrystalCavePainter(context: stoneContext)
            // Interlocking blocks tie the arch shoulders into the adjoining cliff.
            // Their joints rise toward the crown instead of outlining a separate slab.
            let blocks: [[CGPoint]] = [
                [.init(x: -191,y: 105),.init(x: -198,y: 63),.init(x: -176,y: 30),.init(x: -112,y: 26),.init(x: -109,y: 104)],
                [.init(x: -176,y: 30),.init(x: -185,y: -9),.init(x: -159,y: -53),.init(x: -111,y: -19),.init(x: -111,y: 26)],
                [.init(x: -159,y: -53),.init(x: -163,y: -65),.init(x: -118,y: -99),.init(x: -78,y: -109),.init(x: -108,y: -56),.init(x: -111,y: -19)],
                [.init(x: -78,y: -109),.init(x: -18,y: -128),.init(x: 24,y: -124),.init(x: 27,y: -103),.init(x: -34,y: -103)],
                [.init(x: 184,y: 105),.init(x: 194,y: 57),.init(x: 168,y: 32),.init(x: 110,y: 36),.init(x: 110,y: 104)],
                [.init(x: 168,y: 32),.init(x: 193,y: 18),.init(x: 172,y: -39),.init(x: 132,y: -70),.init(x: 111,y: -12),.init(x: 110,y: 36)],
                [.init(x: 132,y: -70),.init(x: 129,y: -87),.init(x: 71,y: -116),.init(x: 24,y: -124),.init(x: 27,y: -103),.init(x: 102,y: -64),.init(x: 111,y: -12)]
            ]
            for (index, points) in blocks.enumerated() {
                let boulder = stone.contour(points, radius: 6)
                stone.material(boulder, colors: index % 2 == 0 ? [0xA3AEB8,0x7B8B9E,0x455D7A] : [0x96A4B2,0x6B819A,0x3D5675])
                stone.context.stroke(boulder.offsetBy(dx: 0, dy: 1.5), with: .color(Color(dinoHex: 0x304765).opacity(0.62)), lineWidth: 2)
                if let first = points.first, let last = points.last {
                    stone.line([.init(x: first.x + 4,y: first.y - 4),.init(x: last.x + 3,y: last.y - 3)],
                               color: 0xC0C5C0, width: 1.3, opacity: 0.43)
                }
            }
            p.exitFootings()
            p.ground(at: CGPoint(x: 0, y: 100), width: 280, height: 52, color: 0x31455F, opacity: 0.32)
            let frame = Path { a in
                a.move(to: CGPoint(x: -110, y: 98)); a.addLine(to: CGPoint(x: -110, y: 0))
                a.addCurve(to: CGPoint(x: 110, y: 0), control1: CGPoint(x: -110, y: -139), control2: CGPoint(x: 110, y: -139))
                a.addLine(to: CGPoint(x: 110, y: 98)); a.addLine(to: CGPoint(x: 82, y: 98))
                a.addLine(to: CGPoint(x: 82, y: 0))
                a.addCurve(to: CGPoint(x: -82, y: 0), control1: CGPoint(x: 82, y: -101.33), control2: CGPoint(x: -82, y: -101.33))
                a.addLine(to: CGPoint(x: -82, y: 98)); a.closeSubpath()
            }
            p.context.stroke(frame.offsetBy(dx: 0, dy: 4), with: .color(Color(dinoHex: 0x223959).opacity(0.65)),
                             style: StrokeStyle(lineWidth: 7, lineJoin: .round))
            p.material(frame, colors: [0xD9D3BC, 0xA7AEA7, 0x6B7D8C])
            let reveal = Path { a in
                a.move(to: .init(x: -81, y: 97)); a.addLine(to: .init(x: -81, y: 0))
                a.addCurve(to: .init(x: 81, y: 0), control1: .init(x: -81, y: -100), control2: .init(x: 81, y: -100))
                a.addLine(to: .init(x: 81, y: 97))
            }
            p.context.stroke(reveal.offsetBy(dx: 3, dy: 3), with: .color(Color(dinoHex: 0x253C56).opacity(0.65)),
                             style: StrokeStyle(lineWidth: 6, lineJoin: .round))
            p.context.stroke(reveal, with: .color(Color(dinoHex: 0xEEE2BC).opacity(0.75)), lineWidth: 1.5)
            // The inner lining exposes a thick, shadowed tunnel behind the cut stone.
            let soffit = Path { a in
                a.move(to: .init(x: -82, y: 97)); a.addLine(to: .init(x: -82, y: 0))
                a.addCurve(to: .init(x: 82, y: 0), control1: .init(x: -82, y: -101.33), control2: .init(x: 82, y: -101.33))
                a.addLine(to: .init(x: 82, y: 97)); a.addLine(to: .init(x: 73, y: 97))
                a.addLine(to: .init(x: 73, y: 3))
                a.addCurve(to: .init(x: -73, y: 3), control1: .init(x: 73, y: -76), control2: .init(x: -73, y: -76))
                a.addLine(to: .init(x: -73, y: 97)); a.closeSubpath()
            }
            p.material(soffit, colors: [0x213048,0x344056,0x516076])
            p.moss(at: CGPoint(x: -72, y: -101), size: 0.44)
            p.moss(at: CGPoint(x: 69, y: -103), size: 0.35)

            // Wedge-shaped voussoirs follow the arch, rather than forming a fence.
            for i in 0..<9 {
                let a = Double(i) * .pi / 9, b = Double(i + 1) * .pi / 9
                let m = (a + b) / 2
                func point(_ angle: Double, outer: Bool) -> CGPoint {
                    CGPoint(x: CGFloat(cos(angle)) * (outer ? 109 : 82),
                            y: -CGFloat(sin(angle)) * (outer ? 104 : 76))
                }
                let stone = p.contour([point(a, outer: true), point(m, outer: true), point(b, outer: true),
                                       point(b, outer: false), point(m, outer: false), point(a, outer: false)], radius: 1.5)
                p.material(stone, colors: i % 3 == 0 ? [0xE1D7BB, 0xB4B7AA, 0x829194] : [0xD0CFBC, 0x9DA9A5, 0x71828D])
                p.context.stroke(stone, with: .color(Color(dinoHex: 0x536A7C).opacity(0.85)), lineWidth: 1.3)
                p.line([point(a + 0.025, outer: true), point(m, outer: true), point(b - 0.025, outer: true)],
                       color: 0xF5E8C8, width: 1.7, opacity: 0.78)
                if i % 3 == 1 {
                    p.line([point(m, outer: true), CGPoint(x: CGFloat(cos(m)) * 98, y: -CGFloat(sin(m)) * 91),
                            CGPoint(x: CGFloat(cos(m)) * 92 + 4, y: -CGFloat(sin(m)) * 87)],
                           color: 0x74878F, width: 0.9, opacity: 0.65)
                }
            }
            // A small mineral inlay belongs to the crown stone, below the hood.
            p.crystal(at: CGPoint(x: 0, y: -90), height: 12, tint: 3)
            for sign: CGFloat in [-1, 1] {
                for row in 0..<4 {
                    let x = sign < 0 ? -110.0 : 82.0
                    let stone = p.contour([.init(x: x, y: CGFloat(row) * 24 + 1),
                                           .init(x: x + 28, y: CGFloat(row) * 24 + 2),
                                           .init(x: x + 27, y: CGFloat(row + 1) * 24),
                                           .init(x: x + 1, y: CGFloat(row + 1) * 24 - 1)], radius: 2)
                    p.material(stone, colors: row % 2 == 0 ? [0xD4D0B8, 0xA3ADA4, 0x7A8C90] : [0xC5C8B5, 0x8B9F9D, 0x667F8D])
                    p.context.stroke(stone, with: .color(Color(dinoHex: 0x657C86)), lineWidth: 1)
                    p.line([.init(x: x + 3, y: CGFloat(row) * 24 + 3), .init(x: x + 25, y: CGFloat(row) * 24 + 4)],
                           color: 0xEFE3C4, width: 1, opacity: 0.7)
                }
                p.rock(at: CGPoint(x: sign * 109, y: 103), size: 0.53)
                p.moss(at: CGPoint(x: sign * 100, y: -47), size: 0.72)
                p.moss(at: CGPoint(x: sign * 119, y: 99), size: 0.61)
                p.hangingVine(at: CGPoint(x: sign * 116, y: -45), length: 112, mirror: sign > 0, scale: 0.87)
                // Both lamps hang from brackets fixed into the end pillars.
                p.timber(from: CGPoint(x: sign * 100, y: -7), to: CGPoint(x: sign * 128, y: -7), width: 5)
                p.line([.init(x: sign * 118, y: -7), .init(x: sign * 118, y: 17)], color: 0x3B4853, width: 1.8)
                p.lantern(at: CGPoint(x: sign * 118, y: 55), size: 0.88)
                p.glow(CGPoint(x: sign * 118, y: 35), radius: 48, color: 0xFFC164, opacity: 0.25)
                for j in 0..<3 {
                    let flower = CGPoint(x: sign * CGFloat(104 + j * 8), y: CGFloat(j % 2) * 10 - 46)
                    for petal in 0..<5 {
                        let angle = Double(petal) * .pi * 2 / 5
                        p.oval(CGRect(x: flower.x + CGFloat(cos(angle)) * 3 - 2,
                                      y: flower.y + CGFloat(sin(angle)) * 3 - 2, width: 4, height: 4),
                               colors: [0xFFE0DF, 0xE9A3B3])
                    }
                    p.oval(CGRect(x: flower.x - 1.5, y: flower.y - 1.5, width: 3, height: 3), colors: [0xFFF1BC, 0xE2BD70])
                }
            }
        }
    }

    /// Cool cave light gives way to a shaded stone landing and then warm city ground.
    func exitClearing(width: CGFloat, boundaryY: CGFloat) {
        let threshold = CrystalCaveThresholdLayout(width: width)
        let s = threshold.scale
        var c = context; c.translateBy(x: 0, y: boundaryY)
        let ambient = CrystalCavePainter(context: c)
        ambient.ground(at: CGPoint(x: width / 2, y: -38 * s), width: min(width * 1.3, 840),
                       height: 240 * s, color: 0xEBE8C8, opacity: 0.19)
        var land = Path()
        for i in 0...96 {
            let x = width * CGFloat(i) / 96
            let point = CGPoint(x: x, y: exitBoundaryY(x: x, width: width, scale: s))
            if i == 0 { land.move(to: point) } else { land.addLine(to: point) }
        }
        land.addLine(to: CGPoint(x: width, y: 240 * s))
        land.addLine(to: CGPoint(x: 0, y: 240 * s)); land.closeSubpath()
        c.fill(land, with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: 0x879EA2), location: 0),
            .init(color: Color(dinoHex: 0xA9BBB0), location: 0.28),
            .init(color: Color(dinoHex: 0xC9D3B7), location: 0.53),
            .init(color: Color(dinoHex: 0xDCE2BF).opacity(0.7), location: 0.77),
            .init(color: Color(dinoHex: 0xDCE2BF).opacity(0), location: 1)
        ]), startPoint: CGPoint(x: 0, y: -60 * s), endPoint: CGPoint(x: 0, y: 240 * s)))

        var paving = c; paving.clip(to: land)
        let p = CrystalCavePainter(context: paving)
        let mid = width / 2
        // Reach into the tunnel with a broken rear edge, below the open arch.
        let startY = threshold.exitSpringY + 22 * threshold.exitScale
        let endY = 122 * s
        let mouth = 124 * threshold.exitScale + 6 * s
        let outer = min(width * 0.39, 111 * s)
        func halfWidth(_ t: CGFloat) -> CGFloat { mouth + (outer - mouth) * t }
        func point(_ u: CGFloat, _ t: CGFloat) -> CGPoint {
            CGPoint(x: mid + u * halfWidth(t), y: startY + (endY - startY) * t)
        }
        let starts: [CGFloat] = [0.050, 0, 0.075, 0.020, 0.090, 0.040, 0.010, 0.065]
        var perimeter: [CGPoint] = []
        for column in starts.indices {
            let u = -1 + CGFloat(column) * 0.25
            perimeter.append(point(u, starts[column]))
            perimeter.append(point(u + 0.25, starts[column]))
        }
        perimeter += [point(1, 1), point(-1, 1)]
        let landing = p.contour(perimeter, radius: 2 * s)
        p.context.fill(landing.offsetBy(dx: 0, dy: 2 * s), with: .color(Color(dinoHex: 0x607C7D).opacity(0.2)))
        p.material(landing, colors: [0xA4B5AF, 0xCFD1B8, 0xD9D7B9])
        let tileContext: GraphicsContext = {
            var clipped = paving; clipped.clip(to: landing); return clipped
        }()
        let tiles = CrystalCavePainter(context: tileContext)
        let rows: [CGFloat] = [0, 0.12, 0.24, 0.37, 0.52, 0.70, 0.85, 1]
        // The first stones reach different distances into the cave.
        for row in 0..<(rows.count - 1) {
            let front = rows[row + 1] - 0.007
            let stagger: CGFloat = row % 2 == 0 ? 0 : 0.5
            for column in -1..<8 {
                let u = -1 + (CGFloat(column) + stagger) * 0.25
                let back = (row == 0 ? starts[min(7, max(0, column))] : rows[row]) + 0.007
                let stone = tiles.contour([point(u + 0.009, back), point(u + 0.241, back),
                                           point(u + 0.241, front), point(u + 0.009, front)], radius: 1.3 * s)
                let even = (row + column) % 2 == 0
                let cool: [UInt32] = even ? [0xBAC5BB,0x9EAEA6] : [0xC3CAC0,0xAAB7AA]
                let warm: [UInt32] = even ? [0xE4DFC3,0xC5CAB1] : [0xDAD9BD,0xB9C3AA]
                let warmth = Double(smooth((rows[row] - 0.08) / 0.65))
                let colors = zip(cool, warm).map { Color(dinoHex: $0.0).mix(with: Color(dinoHex: $0.1), by: warmth) }
                let bounds = stone.boundingRect
                tiles.context.fill(stone, with: .linearGradient(Gradient(colors: colors),
                    startPoint: CGPoint(x: bounds.minX, y: bounds.minY), endPoint: CGPoint(x: bounds.maxX, y: bounds.maxY)))
                tiles.context.stroke(stone, with: .color(Color(dinoHex: 0x849A91).opacity(0.45)), lineWidth: 0.65 * s)
                tiles.line([point(u + 0.023, back + 0.008), point(u + 0.228, back + 0.008)],
                           color: 0xF3EAD0, width: 0.8 * s, opacity: 0.56)
            }
        }
        // Deep tunnel shade fades across the same stones toward the city light.
        tiles.context.fill(landing, with: .linearGradient(Gradient(colors: [
            Color(dinoHex: 0x263E59).opacity(0.46), .clear
        ]), startPoint: CGPoint(x: mid, y: startY), endPoint: CGPoint(x: mid, y: 28 * s)))
        for side: CGFloat in [-1, 1] {
            let edge = Path { a in a.move(to: point(side, 0)); a.addLine(to: point(side, 1)) }
            p.context.stroke(edge, with: .color(Color(dinoHex: 0x8EA39A)),
                             style: StrokeStyle(lineWidth: 4 * s, lineCap: .round))
            p.context.stroke(edge.offsetBy(dx: -side * 0.6 * s, dy: -0.5 * s),
                             with: .color(Color(dinoHex: 0xDCE0C8)), lineWidth: 1.4 * s)
        }
    }

    private func passageFloor(layout: WorldSceneryLayout, passage: Passage) -> Path {
        if passage == .departure { return exitCaveMask(width: layout.width, height: layout.height, scale: layout.scale) }
        let w = layout.width, h = layout.height
        let edgeY = passage == .arrival ? h - 520 : layout.routeOffset + 240
        let middleY = passage == .arrival ? edgeY + 245 : edgeY - 210
        return Path { p in
            p.move(to: CGPoint(x: -16, y: edgeY))
            p.addCurve(to: CGPoint(x: w * 0.5, y: middleY),
                       control1: CGPoint(x: w * 0.23, y: edgeY), control2: CGPoint(x: w * 0.24, y: middleY))
            p.addCurve(to: CGPoint(x: w + 16, y: edgeY),
                       control1: CGPoint(x: w * 0.76, y: middleY), control2: CGPoint(x: w * 0.77, y: edgeY))
            let outsideY: CGFloat = passage == .arrival ? h + 24 : -24
            p.addLine(to: CGPoint(x: w + 16, y: outsideY))
            p.addLine(to: CGPoint(x: -16, y: outsideY)); p.closeSubpath()
        }
    }

    /// The cavern stays closed until the small, sunlit departure gate.
    func approach(in size: CGSize, routeOffset: CGFloat, leavingCave: Bool) {
        let layout = WorldSceneryLayout(width: size.width, height: size.height, routeOffset: routeOffset)
        let passage: Passage = leavingCave ? .departure : .arrival
        fillFloor(passageFloor(layout: layout, passage: passage), width: size.width)
        var c = context; c.clip(to: passageFloor(layout: layout, passage: passage))
        let cave = CrystalCavePainter(context: c)
        cave.enclosure(layout: layout, passage: passage)
        // Departure minerals belong to complete shelves in exitForeground.
        // Clipping hanging crystals to the terrain contour cut their tips off.
        if passage == .arrival {
            var scene = DepthScene()
            cave.appendOverhangs(layout: layout, passage: passage, to: &scene)
            scene.draw()
        }
    }

    private func enclosure(layout: WorldSceneryLayout, passage: Passage? = nil) {
        let w = layout.width, h = layout.height, scale = layout.scale
        for right in [false, true] {
            let shade = wallPath(right: right, distance: 102, layout: layout, passage: passage)
            context.fill(shade, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0x597699), Color(dinoHex: 0x334D77)]),
                                                        startPoint: CGPoint(x: w / 2, y: 0), endPoint: CGPoint(x: right ? w : 0, y: 0)))
            let face = wallPath(right: right, distance: 131, layout: layout, passage: passage)
            context.fill(face, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0x8498B4), Color(dinoHex: 0x4B6892), Color(dinoHex: 0x2C426A)]),
                                                     startPoint: CGPoint(x: right ? w * 0.64 : w * 0.32, y: 0),
                                                     endPoint: CGPoint(x: right ? w + 50 : -50, y: 0)))
            let outer = wallPath(right: right, distance: 189, layout: layout, passage: passage)
            context.fill(outer, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0x394D78), Color(dinoHex: 0x202F54)]),
                                                        startPoint: CGPoint(x: w / 2, y: 0), endPoint: CGPoint(x: right ? w : 0, y: 0)))
            // Bedding planes stay inside a single continuous wall mass.
            var rockContext = context; rockContext.clip(to: face)
            let rock = CrystalCavePainter(context: rockContext)
            let sign: CGFloat = right ? 1 : -1
            let strataStart = passage == .arrival ? h - 425 : passage == .departure ? 112 : layout.routeOffset + 45
            let strataCount = passage == nil ? 13 : passage == .arrival ? 3 : 4
            for i in 0..<strataCount {
                let y = strataStart + CGFloat(i) * 132
                let edge = wallX(at: y, right: right, distance: 132, layout: layout, passage: passage)
                let layer = contour([.init(x: edge - sign * 5, y: y - 35), .init(x: edge + sign * 96, y: y - 66),
                                     .init(x: edge + sign * 122, y: y + 3), .init(x: edge + sign * 52, y: y + 31),
                                     .init(x: edge - sign * 6, y: y + 17)], radius: 15)
                rock.material(layer, colors: i % 2 == 0 ? [0xA6B5CA, 0x7C90AE, 0x617B9E] : [0x96A8C2, 0x6F86A8, 0x506C92])
                rock.line([.init(x: edge + sign * 8, y: y - 17), .init(x: edge + sign * 29, y: y - 23), .init(x: edge + sign * 62, y: y - 20)], color: 0xD7E4E4, width: 1, opacity: 0.34)
                rock.line([.init(x: edge + sign * 25, y: y + 9), .init(x: edge + sign * 33, y: y + 22), .init(x: edge + sign * 54, y: y + 26)], color: 0x3E577B, width: 1.1, opacity: 0.64)
            }
            if passage == nil {
                wallBoulders(layout: layout, right: right)
                for i in 0..<10 {
                    let y = layout.routeOffset + 124 + CGFloat(i) * 139 + (right ? 38 : 0)
                    guard y < h - 300 else { continue }
                    let x = wallX(at: y, right: right, distance: 157, layout: layout) + sign * 27 * scale
                    rock.line([.init(x: x - sign * 14 * scale, y: y - 25 * scale), .init(x: x + sign * 8 * scale, y: y - 12 * scale),
                               .init(x: x + sign * 2 * scale, y: y + 11 * scale), .init(x: x + sign * 21 * scale, y: y + 20 * scale)],
                              color: i % 2 == 0 ? 0x69CEE1 : 0xB498DC, width: 2 * scale, opacity: 0.66)
                    rock.at(CGPoint(x: x, y: y), size: scale) { vein in
                        for j in 0..<3 {
                            var shard = vein.context; shard.rotate(by: .degrees(Double(j - 1) * 27 + (right ? -18 : 18)))
                            CrystalCavePainter(context: shard).crystal(at: CGPoint(x: CGFloat(j - 1) * 9, y: CGFloat(j % 2) * 6),
                                                                    height: 28 + CGFloat((i + j) % 3) * 16, tint: 3 + (i + j) % 3)
                        }
                    }
                }
            }
        }
    }

    private func appendOverhangs(layout: WorldSceneryLayout, passage: Passage? = nil, to scene: inout DepthScene) {
        let h = layout.height, scale = layout.scale
        for right in [false, true] {
            // Attached ledges and downward growth give the sides a cavern ceiling.
            let overhangStart = passage == .arrival ? h - 285 : passage == .departure ? 110 : layout.routeOffset + 245
            let overhangCount = passage == nil ? 5 : 2
            for i in 0..<overhangCount {
                let y = overhangStart + CGFloat(i) * 286 + (right ? 113 : 0)
                if passage == nil && y >= h - 295 { continue }
                if passage != nil && (y < 70 || y > h - 100) { continue }
                let x = wallX(at: y, right: right, distance: 155, layout: layout, passage: passage)
                scene.add(at: y + 48 * scale) {
                    self.at(CGPoint(x: x, y: y), size: scale, mirror: right) { p in
                        let tooth = p.contour([.init(x: -48, y: -20), .init(x: 22, y: -17), .init(x: 18, y: 8),
                                               .init(x: 4, y: 48), .init(x: -7, y: 21), .init(x: -29, y: 9)], radius: 6)
                        p.material(tooth, colors: [0x91A5BF, 0x5C769C, 0x405C84])
                        if i % 2 == 0 {
                            var hanging = p.context; hanging.translateBy(x: -8, y: 8); hanging.scaleBy(x: 1, y: -1)
                            CrystalCavePainter(context: hanging).crystal(at: .zero, height: 40 + CGFloat(i % 3) * 8, tint: right ? 0 : 1)
                        }
                        p.material(p.contour([.init(x: -50, y: -22), .init(x: 18, y: -19), .init(x: 31, y: -8),
                                               .init(x: 5, y: 6), .init(x: -40, y: 0)], radius: 7), colors: [0xBECDDB, 0x8EA1BB, 0x5B769C])
                    }
                }
            }
        }
    }

    func landscape(in size: CGSize, routeOffset: CGFloat) {
        let w = size.width, h = size.height
        let scale = min(1.30, max(0.82, w / 390))
        let layout = WorldSceneryLayout(width: w, height: h, routeOffset: routeOffset)
        // Green ground belongs above the arch; the dark opening is below its crown.
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(dinoHex: 0xC3DBAD)))
        outdoorApproach(width: w)
        let floor = entranceOpening(width: w, height: h, scale: scale)
        fillFloor(floor, width: w)
        context.fill(floor, with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: 0x172B51).opacity(0.93), location: 0),
            .init(color: Color(dinoHex: 0x27466D).opacity(0.72), location: 0.28),
            .init(color: Color(dinoHex: 0x425D83).opacity(0.35), location: 0.66),
            .init(color: .clear, location: 1)
        ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: routeOffset + 1390)))
        var interior = context; interior.clip(to: floor)
        let light = CrystalCavePainter(context: interior)
        for (y, color): (CGFloat, UInt32) in [(routeOffset + 260, 0xB8EEE9), (routeOffset + 790, 0xD9C6F0), (routeOffset + 1330, 0xB3E8E5)] {
            light.ground(at: CGPoint(x: layout.centerX(at: y - routeOffset), y: y), width: min(w, 650), height: 380, color: color, opacity: 0.29)
        }
        let interiorPainter = CrystalCavePainter(context: interior)
        interiorPainter.enclosure(layout: layout)
        let lift = CrystalCaveThresholdLayout(width: w).entranceLift
        var entrance = context; entrance.translateBy(x: 0, y: -lift)
        CrystalCavePainter(context: entrance).entranceButtresses(width: w, scale: scale)
        exitClearing(width: w, boundaryY: h)
        exitWall(width: w, boundaryY: h)

        let routeWidth = min(w, 600) - 36
        let points = WorldRouteTrail.chapterPositions.enumerated().map {
            CGPoint(x: (w - routeWidth) / 2 + routeWidth * $0.element,
                    y: routeOffset + 80 + CGFloat($0.offset) * WorldRouteTrail.levelSpacing)
        }
        WorldRouteTrail(points: points, entryY: 0, exitY: h).draw(in: context)

        var scene = DepthScene()
        appendScenery(layout: layout, to: &scene)
        scene.draw()
    }

    /// Shared geometry keeps moving workers behind exactly the same foreground.
    func appendScenery(layout: WorldSceneryLayout, to scene: inout WorldSceneryDepth) {
        let w = layout.width, h = layout.height, scale = layout.scale
        let routeOffset = layout.routeOffset
        let lift = CrystalCaveThresholdLayout(width: w).entranceLift
        appendOverhangs(layout: layout, to: &scene)
        appendEntrance(width: w, scale: scale, lift: lift, to: &scene)
        appendEntranceVista(width: w, scale: scale, lift: lift, to: &scene)
        // Each mineral bed has its own complete stone root, clear of the timber.
        for i in 0..<46 {
            let mineral = CrystalCaveLifeLayout.mineral(index:i,layout:layout)
            let x = mineral.point.x, y = mineral.point.y, clusterSize = mineral.size
            guard y < h-265 else { continue }
            scene.add(at:y+22*clusterSize,
                      bounds:CGRect(x:x-84*clusterSize,y:y-150*clusterSize,width:168*clusterSize,height:180*clusterSize)) {
                cluster(at:mineral.point,size:clusterSize,variation:mineral.variation)
                glow(CGPoint(x:x,y:y-25*scale),radius:40*scale,color:i%3 == 0 ? 0x59E7FF : 0xB890FF,opacity:0.18)
            }
        }
        var c = context; c.translateBy(x: 0, y: routeOffset)
        let p = CrystalCavePainter(context: c, scenery: layout, hangingLamps: hangingLamps)
        func bounds(_ point: CGPoint, size: CGFloat, radius: CGFloat, rise: CGFloat, clearTimber: Bool = false) -> CGRect {
            var placed = layout.position(point, radius:radius*size,rise:rise*size)
            if clearTimber {
                let safe = CrystalCaveLifeLayout.clearTimber(CGPoint(x:placed.x,y:placed.y+routeOffset),
                                                           radius:(radius+10)*size,rise:rise*size,drop:48*size,
                                                           right:placed.x>w/2,layout:layout)
                placed = CGPoint(x:safe.x,y:safe.y-routeOffset)
            }
            return CGRect(x: placed.x - (radius + 30) * size, y: routeOffset + placed.y - (rise + 35) * size,
                          width: (radius + 30) * size * 2, height: (rise + 100) * size)
        }
        scene.add(at: routeOffset + 955 + 38 * scale * 0.91,
                  bounds: bounds(CGPoint(x: w - 12 * scale, y: 955), size: scale * 0.91, radius: 68, rise: 300, clearTimber: true)) {
            p.rockTerraces(at: CGPoint(x: w - 12 * scale, y: 955), size: scale * 0.91)
        }
        scene.add(at: routeOffset + 1300 + 38 * scale * 0.78,
                  bounds: bounds(CGPoint(x: 12 * scale, y: 1300), size: scale * 0.78, radius: 68, rise: 300, clearTimber: true)) {
            p.rockTerraces(at: CGPoint(x: 12 * scale, y: 1300), size: scale * 0.78, mirror: true)
        }
        for (y, right): (CGFloat, Bool) in [(95, false), (505, true), (1035, false)] {
            scene.add(at: routeOffset + y + 10 * scale * 0.83,
                      bounds: bounds(CGPoint(x: right ? w - 22 * scale : 22 * scale, y: y), size: scale * 0.83, radius: 45, rise: 140)) {
                p.minePost(at: CGPoint(x: right ? w - 22 * scale : 22 * scale, y: y), size: scale * 0.83, mirror: right)
            }
        }
        scene.add(at: routeOffset + 1080 + 19 * scale * 0.80,
                  bounds: bounds(CGPoint(x: 15 * scale, y: 1080), size: scale * 0.80, radius: 65, rise: 105)) { p.mineStorage(at: CGPoint(x: 15 * scale, y: 1080), size: scale * 0.80) }
        scene.add(at: routeOffset + 610 + 51 * scale * 0.82,
                  bounds: bounds(CGPoint(x: 10 * scale, y: 610), size: scale * 0.82, radius: 74, rise: 150)) { p.minePlatform(at: CGPoint(x: 10 * scale, y: 610), size: scale * 0.82) }
        scene.add(at: routeOffset + 1370 + 51 * scale * 0.80,
                  bounds: bounds(CGPoint(x: w - 10 * scale, y: 1370), size: scale * 0.80, radius: 74, rise: 150)) { p.minePlatform(at: CGPoint(x: w - 10 * scale, y: 1370), size: scale * 0.80, mirror: true) }
        for (y, right): (CGFloat, Bool) in [(335, false), (870, true), (1265, false)] {
            scene.add(at: routeOffset + y + 29 * scale * 0.87,
                      bounds: bounds(CGPoint(x: right ? w - 20 * scale : 20 * scale, y: y), size: scale * 0.87, radius: 70, rise: 183)) {
                p.mineWorkshop(at: CGPoint(x: right ? w - 20 * scale : 20 * scale, y: y), size: scale * 0.87, mirror: right)
            }
        }
        for (variation, y, right): (Int, CGFloat, Bool) in [(0, 205, true), (2, 465, false), (1, 680, true), (3, 935, false), (4, 1190, false), (6, 1430, true)] {
            let foot: CGFloat = 33
            scene.add(at: routeOffset + y + foot * scale * 0.92,
                      bounds: bounds(CGPoint(x: right ? w - 32 * scale : 32 * scale, y: y), size: scale * 0.92, radius: 77, rise: 130, clearTimber: true)) {
                p.scene(at: CGPoint(x: right ? w - 32 * scale : 32 * scale, y: y), size: scale * 0.92, variation: variation)
            }
        }
        for patrol in CrystalMinerPatrol.routes {
            for y in patrol.stops {
                let point = CrystalCaveLifeLayout.ore(at: CGFloat(y), right: patrol.right, layout: layout)
                scene.add(at: point.y + 7 * scale,
                          bounds: CGRect(x: point.x - 27 * scale, y: point.y - 43 * scale,
                                         width: 54 * scale, height: 55 * scale)) {
                    rock(at: point, size: scale * 0.43)
                    crystal(at: CGPoint(x: point.x - 5 * scale, y: point.y - 7 * scale), height: 27 * scale, tint: patrol.right ? 3 : 4)
                    crystal(at: CGPoint(x: point.x + 8 * scale, y: point.y - 2 * scale), height: 18 * scale, tint: patrol.right ? 3 : 4)
                }
            }
        }
        let boss = ThemePainter(context: c, colors: WorldThemeColors(DinoWorldCatalog.world(5)!))
        let bossPoint = CGPoint(x: w - 79 * scale, y: 1675)
        scene.add(at: routeOffset + bossPoint.y,
                  bounds: CGRect(x: bossPoint.x - 90 * scale, y: routeOffset + bossPoint.y - 240 * scale,
                                 width: 180 * scale, height: 300 * scale)) {
            boss.bossClearing(worldID: 5, at: bossPoint, size: scale)
            boss.boss(worldID: 5, at: bossPoint, size: scale * 0.88)
        }
        let archY: CGFloat = 1650
        scene.add(at: routeOffset + archY + 14 * scale * 0.98,
                  bounds: CGRect(x: w - 160 * scale, y: routeOffset + archY - 190 * scale,
                                 width: 160 * scale, height: 220 * scale)) {
            CrystalCavePainter(context: c).arch(at: CGPoint(x: w - 80 * scale, y: archY), size: scale * 0.98)
        }
    }

    /// A raised centre makes a roof (∩), with the cavern continuing underneath.
    private func entranceY(x: CGFloat, width: CGFloat, scale: CGFloat) -> CGFloat {
        let side = abs((x - width / 2) / (width / 2))
        return (105 + 118 * pow(side, 1.65)) * scale
    }

    private func entranceOpening(width: CGFloat, height: CGFloat, scale: CGFloat) -> Path {
        Path { p in
            for i in 0...64 {
                let x = width * CGFloat(i) / 64
                let point = CGPoint(x: x, y: entranceY(x: x, width: width, scale: scale) - CrystalCaveThresholdLayout(width: width).entranceLift)
                if i == 0 { p.move(to: point) } else { p.addLine(to: point) }
            }
            p.addLine(to: CGPoint(x: width, y: height + 24))
            p.addLine(to: CGPoint(x: 0, y: height + 24)); p.closeSubpath()
        }
    }

    /// Both chapters draw the same mossy banks at the join. All growth starts
    /// below the final outdoor level, and the centre remains a sandy approach.
    func outdoorApproach(width: CGFloat, boundaryY: CGFloat = 0) {
        let scale = min(1.30, max(0.82, width / 390))
        at(CGPoint(x: 0, y: boundaryY)) { p in
            for right in [false, true] {
                var c = p.context
                if right { c.translateBy(x: width, y: 0); c.scaleBy(x: -1, y: 1) }
                let bank = CrystalCavePainter(context: c)
                let landform = bank.contour([
                    .init(x: -20, y: -91 * scale), .init(x: width * 0.075, y: -77 * scale),
                    .init(x: width * 0.15, y: -39 * scale), .init(x: width * 0.22, y: 18 * scale),
                    .init(x: width * 0.28, y: 119 * scale), .init(x: width * 0.23, y: 226 * scale),
                    .init(x: -20, y: 300 * scale)], radius: 8 * scale)
                bank.material(landform, colors: [0xB9C3A2, 0x97A69A, 0x758C91])
                var clipped = c; clipped.clip(to: landform)
                let facets = CrystalCavePainter(context: clipped)
                facets.polygon([.init(x: -10, y: -90 * scale), .init(x: width * 0.15, y: -39 * scale),
                                .init(x: width * 0.09, y: 58 * scale), .init(x: -10, y: 93 * scale)], colors: [0xD4D4B3, 0x9EAE9A, 0x758D8B])
                facets.polygon([.init(x: width * 0.15, y: -39 * scale), .init(x: width * 0.25, y: 56 * scale),
                                .init(x: width * 0.19, y: 133 * scale), .init(x: width * 0.09, y: 58 * scale)], colors: [0xAAB6A0, 0x718995])
                for i in 0..<5 {
                    let x = width * (0.015 + CGFloat(i) * 0.042)
                    let y = (-46 + CGFloat(i) * 13 + (right ? CGFloat((i * 7) % 17) : 0)) * scale
                    bank.moss(at: CGPoint(x: x, y: y), size: scale * (0.63 + CGFloat((i + (right ? 1 : 0)) % 3) * 0.20))
                    if i % 2 == 0 {
                        bank.rock(at: CGPoint(x: x + 12 * scale, y: y + 18 * scale), size: scale * 0.35)
                    }
                }
                let greenery = JunglePainter(context: c)
                greenery.fern(at: CGPoint(x: width * 0.22, y: 57 * scale), size: scale * 0.49, flipped: false)
                greenery.fern(at: CGPoint(x: width * 0.07, y: -23 * scale), size: scale * 0.43, flipped: true)
                greenery.flowers(at: CGPoint(x: width * 0.23, y: 46 * scale), size: scale * 0.62)
                greenery.flowers(at: CGPoint(x: width * 0.13, y: -19 * scale), size: scale * 0.45)
            }
        }
    }

    private func moss(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -27, y: -8, width: 54, height: 17), colors: [0x96C563, 0x548B4F, 0x3D6B50])
            for i in 0..<7 {
                var c = p.context; c.rotate(by: .degrees(Double(i - 3) * 25))
                let length = CGFloat(22 + (i * 7) % 19)
                let leaf = Path { l in
                    l.move(to: .zero)
                    l.addCurve(to: .init(x: 0, y: -length), control1: .init(x: -13, y: -9), control2: .init(x: -9, y: -length + 3))
                    l.addCurve(to: .zero, control1: .init(x: 8, y: -length + 8), control2: .init(x: 11, y: -6))
                }
                let f = CrystalCavePainter(context: c)
                f.material(leaf, colors: i % 2 == 0 ? [0xC5DE76, 0x73AD55, 0x3D7850] : [0x92C65C, 0x4C914D, 0x316C4E])
                f.line([.zero, .init(x: 0, y: -length + 5)], color: 0xD0E59A, width: 0.8, opacity: 0.72)
            }
            for i in 0..<3 {
                let x = CGFloat(i * 10 - 12), y = CGFloat(i % 2) * -6 - 7
                p.oval(CGRect(x: x, y: y, width: 5, height: 5), colors: [0xFFE4A5, 0xE8AF72])
            }
        }
    }

    private func hangingVine(at point: CGPoint, length: CGFloat, mirror: Bool, scale: CGFloat) {
        at(point, size: scale, mirror: mirror) { p in
            let h = length / scale
            var vine = Path(); vine.move(to: .zero)
            vine.addCurve(to: CGPoint(x: 6, y: h), control1: CGPoint(x: 18, y: h * 0.36), control2: CGPoint(x: -15, y: h * 0.75))
            p.context.stroke(vine, with: .color(Color(dinoHex: 0x416C4A)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            for i in 0..<Int(h / 11) {
                let t = CGFloat(i + 1) / CGFloat(Int(h / 11) + 1)
                let x = 54 * (1 - t) * (1 - t) * t - 45 * (1 - t) * t * t + 6 * t * t * t
                let y = h * (1.08 * (1 - t) * (1 - t) * t + 2.25 * (1 - t) * t * t + t * t * t)
                let sign: CGFloat = i % 2 == 0 ? 1 : -1
                let leaf = p.contour([.init(x: x, y: y), .init(x: x + sign * 13, y: y - 7),
                                      .init(x: x + sign * 10, y: y + 4), .init(x: x + sign * 3, y: y + 8)], radius: 2)
                p.material(leaf, colors: i % 3 == 0 ? [0xB9D568, 0x689D51] : [0x81B45B, 0x3F7950])
            }
        }
    }

    private func entranceButtresses(width: CGFloat, scale: CGFloat) {
        for right in [false, true] {
            var c = context
            if right { c.translateBy(x: width, y: 0); c.scaleBy(x: -1, y: 1) }
            let p = CrystalCavePainter(context: c)
            let cliff = p.contour([.init(x: -20, y: 137 * scale), .init(x: width * 0.07, y: 128 * scale),
                                   .init(x: width * 0.16, y: 175 * scale), .init(x: width * 0.20, y: 224 * scale),
                                   .init(x: width * 0.15, y: 274 * scale), .init(x: width * 0.24, y: 333 * scale),
                                   .init(x: width * 0.18, y: 410 * scale), .init(x: -20, y: 438 * scale)], radius: 7 * scale)
            p.material(cliff, colors: [0x9AA4AA, 0x667B98, 0x304D75])
            var clipped = c; clipped.clip(to: cliff)
            let f = CrystalCavePainter(context: clipped)
            f.polygon([.init(x: -10, y: 125 * scale), .init(x: width * 0.14, y: 169 * scale),
                       .init(x: width * 0.10, y: 257 * scale), .init(x: -10, y: 294 * scale)], colors: [0xB6BCB3, 0x71859B, 0x4A6489])
            f.polygon([.init(x: width * 0.14, y: 169 * scale), .init(x: width * 0.22, y: 224 * scale),
                       .init(x: width * 0.15, y: 274 * scale), .init(x: width * 0.10, y: 257 * scale)], colors: [0x8B9AAF, 0x405B82])
            f.polygon([.init(x: width * 0.10, y: 257 * scale), .init(x: width * 0.25, y: 333 * scale),
                       .init(x: width * 0.14, y: 363 * scale), .init(x: -10, y: 318 * scale)], colors: [0x7890A9, 0x3F5C83])
            p.line([.init(x: width * 0.11, y: 280 * scale), .init(x: width * 0.07, y: 304 * scale),
                    .init(x: width * 0.09, y: 325 * scale)], color: 0x294568, width: 1.6 * scale)
        }
    }

    private func appendEntrance(width: CGFloat, scale: CGFloat, lift: CGFloat, to scene: inout DepthScene) {
        var c = context; c.translateBy(x: 0, y: -lift)
        let p = CrystalCavePainter(context: c, hangingLamps: hangingLamps)
        scene.add(at: 243 * scale - lift) { p.entranceRim(width: width) }
        for right in [false, true] {
            let x = width * (right ? 0.88 : 0.12)
            let y = entranceY(x: x, width: width, scale: scale) + 90 * scale
            scene.add(at: y + 10 * scale * 1.06 - lift) { p.minePost(at: CGPoint(x: x, y: y), size: scale * 1.06, mirror: right) }
            scene.add(at: (312 + 22 * 0.76) * scale - lift) {
                p.cluster(at: CGPoint(x: width * (right ? 0.93 : 0.07), y: 312 * scale), size: scale * 0.76, variation: right ? 0 : 1)
            }
        }
    }

    private func appendEntranceVista(width: CGFloat, scale: CGFloat, lift: CGFloat, to scene: inout DepthScene) {
        var c = context; c.translateBy(x: 0, y: -lift)
        let p = CrystalCavePainter(context: c, hangingLamps: hangingLamps)
        let x = width * 0.66
        p.glow(CGPoint(x: x, y: 247 * scale), radius: 115 * scale, color: 0x4CCBEB, opacity: 0.24)
        scene.add(at: 395 * scale - lift) {
            var water = Path(); water.move(to: CGPoint(x: x + 17 * scale, y: 166 * scale))
            water.addCurve(to: CGPoint(x: x - 4 * scale, y: 395 * scale),
                           control1: CGPoint(x: x + 36 * scale, y: 238 * scale), control2: CGPoint(x: x - 19 * scale, y: 310 * scale))
            p.context.stroke(water, with: .color(Color(dinoHex: 0x1E638C)), style: StrokeStyle(lineWidth: 27 * scale, lineCap: .round))
            p.context.stroke(water, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xA4F4F5), Color(dinoHex: 0x43B5D8), Color(dinoHex: 0x397BB5)]), startPoint: .init(x: x, y: 166 * scale), endPoint: .init(x: x, y: 395 * scale)), style: StrokeStyle(lineWidth: 17 * scale, lineCap: .round))
            p.context.stroke(water, with: .color(Color(dinoHex: 0xD0FFFD).opacity(0.65)), style: StrokeStyle(lineWidth: 2 * scale, lineCap: .round))
        }
        scene.add(at: (392 + 13 * 0.65) * scale - lift) { p.pool(at: CGPoint(x: x - 4 * scale, y: 392 * scale), size: scale * 0.65) }
        scene.add(at: (390 + 18 * 0.44) * scale - lift) { p.rock(at: CGPoint(x: x + 31 * scale, y: 390 * scale), size: scale * 0.44) }
        scene.add(at: (180 + 22*0.47)*scale-lift) {
            p.rock(at:CGPoint(x:x+105*scale,y:180*scale),size:scale*0.65)
            p.cluster(at:CGPoint(x:x+105*scale,y:173*scale),size:scale*0.47,variation:4)
        }
        scene.add(at: (244 + 51 * 0.81) * scale - lift) { p.minePlatform(at: CGPoint(x: x, y: 244 * scale), size: scale * 0.81) }
        for i in 0..<9 {
            let point = CGPoint(x: width * (0.24 + CGFloat(i) * 0.07), y: (207 + CGFloat((i * 17) % 63)) * scale)
            scene.add(at: point.y - lift) {
                p.glow(point, radius: 8 * scale, color: i % 3 == 0 ? 0xFFBA55 : 0x67DEFF, opacity: 0.30)
                p.oval(CGRect(x: point.x, y: point.y, width: 1.7 * scale, height: 1.7 * scale), colors: [0xE9FFFF, 0x72DDF5])
            }
        }
    }

    func entranceForeground(width: CGFloat) {
        var c = context
        c.translateBy(x: 0, y: -CrystalCaveThresholdLayout(width: width).entranceLift)
        CrystalCavePainter(context: c).entranceRim(width: width)
    }

    private func entranceRim(width: CGFloat) {
        let scale = min(1.30, max(0.82, width / 390))
        // A deep continuous lip hides the road, including its centre dashes.
        var rim = Path()
        for i in 0...64 {
            let x = width * CGFloat(i) / 64
            let point = CGPoint(x: x, y: entranceY(x: x, width: width, scale: scale) + 20 * scale)
            if i == 0 { rim.move(to: point) } else { rim.addLine(to: point) }
        }
        for i in (0...64).reversed() {
            let x = width * CGFloat(i) / 64
            rim.addLine(to: CGPoint(x: x, y: entranceY(x: x, width: width, scale: scale) - 71 * scale))
        }
        rim.closeSubpath()
        material(rim, colors: [0x8998A2, 0x526781, 0x243B60])
        ground(at: CGPoint(x: width / 2, y: 124 * scale), width: min(width, 640), height: 50 * scale,
               color: 0x10233E, opacity: 0.45)
        let count = max(7, Int(width / (58 * scale)))
        for i in 0..<count {
            let left = width * CGFloat(i) / CGFloat(count) - 0.5
            let right = width * CGFloat(i + 1) / CGFloat(count) + 0.5
            let middle = (left + right) / 2
            let a = entranceY(x: left, width: width, scale: scale)
            let b = entranceY(x: right, width: width, scale: scale)
            let m = entranceY(x: middle, width: width, scale: scale)
            let thickness = (62 + CGFloat((i * 7) % 4) * 8) * scale
            let lean = (middle / width - 0.5) * 23 * scale
            let stone = contour([.init(x: left + lean, y: a - thickness + 8 * scale),
                                 .init(x: middle + lean, y: m - thickness - 5 * scale),
                                 .init(x: right + lean, y: b - thickness + 11 * scale), .init(x: right, y: b + 7 * scale),
                                 .init(x: middle + 3 * scale, y: m + (i % 2 == 0 ? 16 : 8) * scale),
                                 .init(x: left, y: a + 5 * scale)], radius: 4 * scale)
            material(stone, colors: i % 3 == 0 ? [0xC6C3B5, 0x8E98A5, 0x4E6486] : [0xB5B8B3, 0x7D8EA4, 0x405779])
            var facets = context; facets.clip(to: stone)
            let rock = CrystalCavePainter(context: facets)
            rock.polygon([.init(x: left, y: a - thickness), .init(x: middle, y: m - thickness - 6 * scale),
                          .init(x: right, y: b - thickness + 3 * scale), .init(x: middle + 4 * scale, y: m - thickness * 0.48),
                          .init(x: left + 5 * scale, y: a - 8 * scale)], colors: [0xD2CDB8, 0x9EA9B1, 0x7F92A7])
            rock.polygon([.init(x: middle + 4 * scale, y: m - thickness * 0.48), .init(x: right, y: b - thickness + 3 * scale),
                          .init(x: right, y: b + 7 * scale), .init(x: middle, y: m + 12 * scale)], colors: [0x8B9BAF, 0x435C81])
            if i % 3 == 1 {
                rock.line([.init(x: middle - 4 * scale, y: m - thickness + 3 * scale),
                           .init(x: middle - 8 * scale, y: m - thickness * 0.52),
                           .init(x: middle, y: m - thickness * 0.31)], color: 0x536983, width: 1.1 * scale, opacity: 0.8)
            }
            context.stroke(stone, with: .color(Color(dinoHex: 0x263E5D).opacity(0.65)), lineWidth: 1.3 * scale)
            line([.init(x: left + 3 * scale, y: a - thickness + 3 * scale),
                  .init(x: middle, y: m - thickness - 2 * scale), .init(x: right - 3 * scale, y: b - thickness + 5 * scale)],
                 color: 0xE3DDC4, width: 1.4 * scale, opacity: 0.65)
            // Warm reflected light catches the underside of the cold rock.
            line([.init(x: left + 2 * scale, y: a + 4 * scale), .init(x: middle, y: m + 9 * scale),
                  .init(x: right - 2 * scale, y: b + 6 * scale)], color: 0xE5AF64, width: 3.4 * scale, opacity: 0.65)
        }
        for right in [false, true] {
            for j in 0..<5 {
                let leafX = width * (right ? 0.985 - CGFloat(j) * 0.055 : 0.015 + CGFloat(j) * 0.055)
                let leafY = entranceY(x: leafX, width: width, scale: scale) - (55 + CGFloat(j % 2) * 9) * scale
                moss(at: CGPoint(x: leafX, y: leafY), size: scale * (0.68 + CGFloat(j % 2) * 0.19))
                hangingVine(at: CGPoint(x: leafX, y: leafY), length: (71 + CGFloat(j % 3) * 21) * scale,
                            mirror: right, scale: scale)
            }
        }
    }

    private func timber(from a: CGPoint, to b: CGPoint, width: CGFloat) {
        let dx = b.x - a.x, dy = b.y - a.y, length = max(1, hypot(dx, dy))
        let nx = -dy / length, ny = dx / length
        let beam = contour([.init(x: a.x + nx * width / 2, y: a.y + ny * width / 2),
                            .init(x: b.x + nx * width / 2, y: b.y + ny * width / 2),
                            .init(x: b.x - nx * width / 2, y: b.y - ny * width / 2),
                            .init(x: a.x - nx * width / 2, y: a.y - ny * width / 2)], radius: 1.5)
        material(beam, colors: [0xBC8D57, 0x83603F, 0x493D35])
        for offset: CGFloat in [-0.25, 0.16] {
            line([.init(x: a.x + dx * 0.06 + nx * width * offset, y: a.y + dy * 0.06 + ny * width * offset),
                  .init(x: b.x - dx * 0.07 + nx * width * offset, y: b.y - dy * 0.07 + ny * width * offset)],
                 color: offset < 0 ? 0xE6B47A : 0x493D35, width: 0.9, opacity: 0.65)
        }
        for t: CGFloat in [0.12, 0.88] {
            oval(CGRect(x: a.x + dx * t - 1.5, y: a.y + dy * t - 1.5, width: 3, height: 3), colors: [0xB5C6C6, 0x4A545B])
        }
    }

    private func minePost(at point: CGPoint, size: CGFloat, mirror: Bool = false) {
        at(point, size: size, mirror: mirror, radius: 45 * size, rise: 140 * size) { p in
            p.ground(at: CGPoint(x: 0, y: 8), width: 71, height: 27)
            p.rock(at: CGPoint(x: -5, y: 8), size: 0.44)
            p.timber(from: CGPoint(x: -5, y: 3), to: CGPoint(x: -5, y: -132), width: 12)
            p.timber(from: CGPoint(x: -15, y: -117), to: CGPoint(x: 35, y: -117), width: 12)
            p.timber(from: CGPoint(x: -2, y: -86), to: CGPoint(x: 24, y: -115), width: 7)
            if p.hangingLamps {
                p.line([.init(x: 28, y: -116), .init(x: 28, y: -96)], color: 0x323C4A, width: 2)
                p.lantern(at: CGPoint(x: 28, y: -52), size: 1.10)
            }
            p.glow(CGPoint(x: 28, y: -77), radius: 62, color: 0xFFB94F, opacity: 0.25)
            p.plants(at: CGPoint(x: -17, y: 10), size: 0.44)
        }
    }

    private func mineWorkshop(at point: CGPoint, size: CGFloat, mirror: Bool = false) {
        at(point, size: size, mirror: mirror, radius: 70 * size, rise: 183 * size) { p in
            p.ground(at: CGPoint(x: 0, y: 18), width: 174, height: 48)
            p.rock(at: CGPoint(x: -25, y: 4), size: 1.46)
            for x: CGFloat in [-48, 46] {
                p.timber(from: CGPoint(x: x, y: 16), to: CGPoint(x: x, y: -158), width: 14)
                p.rock(at: CGPoint(x: x, y: 20), size: 0.43)
            }
            p.timber(from: CGPoint(x: -62, y: -151), to: CGPoint(x: 61, y: -151), width: 17)
            p.timber(from: CGPoint(x: -46, y: -108), to: CGPoint(x: -12, y: -148), width: 9)
            p.timber(from: CGPoint(x: 43, y: -108), to: CGPoint(x: 13, y: -148), width: 9)
            // A braced shelf carries spare planks, ore and a hanging mine lamp.
            p.timber(from: CGPoint(x: -52, y: -52), to: CGPoint(x: 52, y: -56), width: 11)
            p.timber(from: CGPoint(x: -45, y: -17), to: CGPoint(x: -8, y: -52), width: 7)
            for i in 0..<4 {
                let y = CGFloat(-65 - i * 7)
                p.timber(from: CGPoint(x: -35 + CGFloat(i % 2) * 7, y: y), to: CGPoint(x: 26, y: y - 5), width: 6)
            }
            if p.hangingLamps {
                p.line([.init(x: 30, y: -143), .init(x: 30, y: -109)], color: 0x3C4653, width: 2)
                p.lantern(at: CGPoint(x: 30, y: -65), size: 0.96)
            }
            p.mineStorage(at: CGPoint(x: -6, y: 9), size: 0.91)
            p.timber(from: CGPoint(x: -29, y: -14), to: CGPoint(x: -4, y: -112), width: 7)
            p.timber(from: CGPoint(x: -19, y: -8), to: CGPoint(x: 9, y: -103), width: 6)
            p.rock(at:CGPoint(x:76,y:29),size:0.38)
            p.crystal(at:CGPoint(x:76,y:23),height:39,tint:3)
        }
    }

    private func mineStorage(at point: CGPoint, size: CGFloat, mirror: Bool = false) {
        at(point, size: size, mirror: mirror, radius: 65 * size, rise: 105 * size) { p in
            p.ground(at: CGPoint(x: 0, y: 13), width: 153, height: 44)
            p.rock(at: CGPoint(x: -13, y: 5), size: 1.3)
            // Stacked cut timber, with visible end grain and retaining pegs.
            for i in (0..<5).sorted(by: { $0 / 3 > $1 / 3 }) {
                let x: CGFloat = -45 + CGFloat(i % 3) * 17, y: CGFloat = 10 - CGFloat(i / 3) * 14
                p.timber(from: CGPoint(x: x, y: y), to: CGPoint(x: x + 43, y: y - 13), width: 13)
                p.oval(CGRect(x: x - 7, y: y - 6, width: 14, height: 12), colors: [0xE9C58A, 0xB38350])
                p.context.stroke(Path(ellipseIn: CGRect(x: x - 4, y: y - 3.5, width: 8, height: 7)), with: .color(Color(dinoHex: 0x8F633C)), lineWidth: 0.8)
            }
            p.timber(from: CGPoint(x: -49, y: 18), to: CGPoint(x: -49, y: -17), width: 5)
            p.timber(from: CGPoint(x: 11, y: 9), to: CGPoint(x: 11, y: -29), width: 5)
            p.polygon([.init(x: 13, y: -14), .init(x: 50, y: -17), .init(x: 50, y: 12), .init(x: 13, y: 16)], colors: [0xBD9362, 0x79563C])
            for x: CGFloat in [15, 32, 48] { p.line([.init(x: x, y: -12), .init(x: x, y: 11)], color: 0x503F34, width: 1) }
            p.timber(from: CGPoint(x: 14, y: 12), to: CGPoint(x: 49, y: -14), width: 5)
            p.timber(from: CGPoint(x: 12, y: -15), to: CGPoint(x: 51, y: -18), width: 6)
            for i in 0..<4 { p.crystal(at: CGPoint(x: 19 + CGFloat(i) * 8, y: -17), height: 20 + CGFloat(i % 3) * 10, tint: i % 3) }
            p.rock(at:CGPoint(x:57,y:22),size:0.33)
            p.crystal(at:CGPoint(x:57,y:16),height:28,tint:0)
        }
    }

    private func minePlatform(at point: CGPoint, size: CGFloat, mirror: Bool = false) {
        at(point, size: size, mirror: mirror, radius: 74 * size, rise: 150 * size) { p in
            p.ground(at: CGPoint(x: 0, y: 28), width: 169, height: 42)
            for x: CGFloat in [-52, 42] {
                p.timber(from: CGPoint(x: x, y: 51), to: CGPoint(x: x, y: -37), width: 12)
                p.rock(at: CGPoint(x: x, y: 51), size: 0.42)
            }
            p.timber(from: CGPoint(x: -49, y: 44), to: CGPoint(x: 38, y: -24), width: 9)
            p.timber(from: CGPoint(x: 40, y: 44), to: CGPoint(x: -46, y: -24), width: 8)
            p.polygon([.init(x: -69, y: -35), .init(x: 46, y: -43), .init(x: 66, y: -24), .init(x: -54, y: -14)], colors: [0xC29A6B, 0x926745, 0x614B38])
            for i in 0..<10 {
                let x = -62 + CGFloat(i) * 12
                p.line([.init(x: x, y: -35 - CGFloat(i) * 0.7), .init(x: x + 13, y: -16 - CGFloat(i) * 0.8)], color: 0x503D32, width: 1)
            }
            p.timber(from: CGPoint(x: -57, y: -16), to: CGPoint(x: 63, y: -25), width: 10)
            for x: CGFloat in [-54, 58] { p.timber(from: CGPoint(x: x, y: -24), to: CGPoint(x: x, y: -65), width: 6) }
            var rope = Path(); rope.move(to: CGPoint(x: -54, y: -60))
            rope.addQuadCurve(to: CGPoint(x: 58, y: -60), control: CGPoint(x: 0, y: -35))
            p.context.stroke(rope, with: .color(Color(dinoHex: 0xD7AD70)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            p.lantern(at: CGPoint(x: 58, y: -62), size: 0.68)
        }
    }

    private func rock(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.ground(at: CGPoint(x: 0, y: 10), width: 88, height: 30)
            let stone = p.contour([.init(x: -34, y: 5), .init(x: -27, y: -23), .init(x: -10, y: -42),
                                   .init(x: 14, y: -39), .init(x: 32, y: -18), .init(x: 36, y: 5), .init(x: 10, y: 15)], radius: 10)
            p.material(stone, colors: [0xB6C4D2, 0x8A9AB5, 0x5D779C])
            var clipped = p.context; clipped.clip(to: stone)
            let facet = CrystalCavePainter(context: clipped)
            facet.polygon([.init(x: -30, y: -27), .init(x: -9, y: -45), .init(x: 17, y: -42), .init(x: 4, y: -16), .init(x: -22, y: -5)], colors: [0xD6E0E1, 0xAEBFD0, 0x8B9DB8])
            facet.polygon([.init(x: 17, y: -43), .init(x: 38, y: -17), .init(x: 39, y: 10), .init(x: 12, y: 19), .init(x: 4, y: -16)], colors: [0x8E9EBB, 0x516F98])
            p.line([.init(x: -20, y: -4), .init(x: -8, y: -8), .init(x: -2, y: -3)], color: 0x567397, width: 0.8, opacity: 0.65)
        }
    }

    private func crystal(at point: CGPoint, height: CGFloat, tint: Int) {
        at(point) { p in
            let r = height * 0.18
            let colors: [UInt32]
            if tint >= 3 {
                colors = tint % 3 == 0 ? [0xEBFFFF, 0x78EDFA, 0x20C2E8, 0x315FB9]
                    : tint % 3 == 1 ? [0xF8EAFF, 0xD7A9FF, 0xA16DE8, 0x6250AD]
                    : [0xFFF0FE, 0xF0B4F6, 0xCF7CE2, 0x8A56B8]
            } else {
                colors = tint % 3 == 0 ? [0xE5FFF6, 0x9CEDE8, 0x54BBD2, 0x477FAF] : tint % 3 == 1 ? [0xF0EBFF, 0xCCBDF3, 0x9B93D6, 0x706EA8] : [0xFFF0F9, 0xE6C5E8, 0xBC9DCE, 0x8C7CAB]
            }
            p.ground(at: CGPoint(x: 0, y: 1), width: height * 1.2, height: height * 0.36, color: colors[1], opacity: 0.33)
            let tip = CGPoint(x: -r * 0.06, y: -height)
            let left = CGPoint(x: -r, y: -height * 0.76)
            let right = CGPoint(x: r, y: -height * 0.75)
            let root = CGPoint(x: r * 0.12, y: 1)
            let crystal = p.contour([left, tip, right, .init(x: r * 0.87, y: -3), root, .init(x: -r * 0.84, y: -5)], radius: 1.5)
            p.material(crystal, colors: [colors[0], colors[1], colors[2]])
            var clipped = p.context; clipped.clip(to: crystal)
            let face = CrystalCavePainter(context: clipped)
            face.polygon([tip, right, .init(x: r * 0.87, y: 2), root, .init(x: 0, y: -height * 0.73)], colors: [colors[1], colors[2], colors[3]])
            face.polygon([left, tip, .init(x: 0, y: -height * 0.73)], colors: [0xFAFFFD, colors[0], colors[1]])
            face.polygon([.init(x: -r * 1.2, y: -height * 0.48), .init(x: r * 1.2, y: -height * 0.63),
                          .init(x: r * 1.2, y: -height * 0.53), .init(x: -r * 1.2, y: -height * 0.38)], colors: [colors[0], colors[1]])
            p.line([left, tip, right], color: 0xF0FFFC, width: 0.9, opacity: 0.82)
            p.line([.init(x: 0, y: -height * 0.72), .init(x: r * 0.11, y: -5)], color: colors[0], width: 1, opacity: 0.76)
            p.line([.init(x: -r * 0.57, y: -height * 0.67), .init(x: -r * 0.54, y: -height * 0.40)], color: 0xFFFFFF, width: max(0.8, height * 0.018), opacity: 0.72)
        }
    }

    private func cluster(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            p.ground(at: CGPoint(x: 0, y: 9), width: 146, height: 51, color: variation % 2 == 0 ? 0x68C9D6 : 0xA794D7, opacity: 0.31)
            p.material(p.contour([.init(x: -52, y: 3), .init(x: -33, y: -16), .init(x: 12, y: -17),
                                   .init(x: 42, y: -8), .init(x: 55, y: 15), .init(x: 12, y: 22), .init(x: -39, y: 18)], radius: 8), colors: [0xB9CAD3, 0x8298B3, 0x5E799D])
            let heights: [CGFloat] = variation % 2 == 0 ? [39, 67, 99, 76, 43] : [43, 85, 108, 64, 35]
            let roots: [CGFloat] = [5, 2, 4, 9, 11]
            for i in roots.indices.sorted(by: { roots[$0] < roots[$1] }) {
                let x = CGFloat(i - 2) * 17, y = roots[i]
                p.at(CGPoint(x: x, y: y)) { shard in
                    var c = shard.context; c.rotate(by: .degrees([-24.0, -12, 3, 15, 27][i]))
                    let tint = i == 4 ? 2 : variation >= 3 ? 3 + variation % 3 : variation % 2
                    CrystalCavePainter(context: c).crystal(at: .zero, height: heights[i], tint: tint)
                }
            }
            p.rock(at: CGPoint(x: -36, y: 13), size: 0.36)
            p.rock(at: CGPoint(x: 34, y: 17), size: 0.29)
            p.crystal(at: CGPoint(x: -20, y: 17), height: 25, tint: (variation + 1) % 2)
            p.line([.init(x: -8, y: 18), .init(x: 3, y: 20), .init(x: 14, y: 17)], color: 0xDBF0E8, width: 0.9, opacity: 0.65)
            p.sparkle(at: CGPoint(x: -5, y: -heights[2] * 0.74), radius: 2.3)
        }
    }

    private func plants(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for i in 0..<5 {
                var c = p.context; c.rotate(by: .degrees(Double(i - 2) * 31))
                let leaf = Path { l in
                    l.move(to: .zero)
                    l.addCurve(to: .init(x: 0, y: -29 - CGFloat(i % 2) * 9), control1: .init(x: -12, y: -6), control2: .init(x: -8, y: -26))
                    l.addCurve(to: .zero, control1: .init(x: 9, y: -25), control2: .init(x: 12, y: -6))
                }
                let f = CrystalCavePainter(context: c); f.material(leaf, colors: [0xB4DCB4, 0x70B4A1, 0x4B8A92])
                f.line([.zero, .init(x: 0, y: -25)], color: 0xD6ECD1, width: 0.7, opacity: 0.6)
            }
        }
    }
    func swingingLamp(size: CGFloat, lampSize: CGFloat, drop: CGFloat) {
        line([.zero, CGPoint(x: 0, y: drop * size)], color: 0x323C4A, width: 1.7 * size)
        lantern(at: CGPoint(x: 0, y: (drop + 44 * lampSize) * size), size: lampSize * size)
    }

    func mineralGlint(at point: CGPoint, radius: CGFloat) { sparkle(at: point, radius: radius) }

    /// Small helmeted dino miners use articulated feet, arms and a real pickaxe.
    func miner(at point: CGPoint, size: CGFloat, right: Bool, variation: Int,
               pose: CrystalMinerPatrol.Pose, time: TimeInterval) {
        at(point, size: size, mirror: !right) { p in
            let stride = pose.walking ? CGFloat(sin(time * 8.5 + Double(variation) * 2)) : 0
            let bob = pose.walking ? abs(stride) * 1.2 : 0
            let bodyColors: [[UInt32]] = [[0x9CC28D, 0x609574, 0x3C6C60], [0x91C6CA, 0x548D9E, 0x3C627D],
                                          [0xD1AA85, 0xA27660, 0x79534E], [0xB5ACD5, 0x817BA7, 0x555E85]]
            let palette = bodyColors[variation % 4]
            p.ground(at: CGPoint(x: 0, y: 3), width: 38, height: 12, color: 0x102F4C, opacity: 0.40)
            // A tail and a little ore backpack identify the worker from behind.
            p.material(p.contour([.init(x: -8, y: -24-bob), .init(x: -30, y: -12-bob),
                                  .init(x: -19, y: -27-bob), .init(x: -6, y: -35-bob)], radius: 4), colors: palette)
            p.rounded(CGRect(x: -17, y: -32-bob, width: 14, height: 23), radius: 5, colors: [0xC0A47A, 0x776C59])
            for side: CGFloat in [-1, 1] {
                let x = side * 6 + side * stride * 4
                let lift = max(0, side * stride) * 3
                p.line([.init(x: side * 6, y: -13-bob), .init(x: x, y: -3-lift)],
                       color: palette[1], width: 7)
                p.rounded(CGRect(x: x - 5, y: -4-lift, width: 12, height: 7), radius: 3,
                          colors: [0xB3A484, 0x5B5A51, 0x3D4547])
            }
            p.oval(CGRect(x: -11, y: -36-bob, width: 24, height: 28), colors: palette)
            p.rounded(CGRect(x: -9, y: -27-bob, width: 21, height: 16), radius: 5, colors: [0xE1B75C, 0xAD7D3C])
            for x: CGFloat in [-5, 7] {
                p.line([.init(x: x, y: -29-bob), .init(x: x, y: -13-bob)], color: 0xF7D881, width: 2.3)
            }
            p.line([.init(x: -8, y: -17-bob), .init(x: 10, y: -17-bob)], color: 0xFFF0AD, width: 1.4)
            p.oval(CGRect(x: -11, y: -53-bob, width: 27, height: 24), colors: palette)
            p.oval(CGRect(x: 6, y: -43-bob, width: 17, height: 12), colors: [0xCAE0B1, palette[0], palette[1]])
            p.oval(CGRect(x: 7, y: -48-bob, width: 6, height: 8), colors: [0xFFFFEB, 0xE3F5DE])
            p.oval(CGRect(x: 10, y: -46.5-bob, width: 2.7, height: 4.5), colors: [0x24495C, 0x122E44])
            p.line([.init(x: 16, y: -35-bob), .init(x: 20, y: -36-bob)], color: 0x3C675E, width: 1)
            // The hard hat and headlamp stay attached to the bobbing head.
            let helmet = Path { h in
                h.move(to: .init(x: -14, y: -47-bob))
                h.addCurve(to: .init(x: 17, y: -47-bob), control1: .init(x: -15, y: -68-bob), control2: .init(x: 18, y: -68-bob))
                h.closeSubpath()
            }
            p.material(helmet, colors: [0xFFE58A, 0xE8B64D, 0xB57A30])
            p.rounded(CGRect(x: -16, y: -49-bob, width: 36, height: 5), radius: 2, colors: [0xFFE9A1, 0xC68D39])
            p.line([.init(x: 0, y: -59-bob), .init(x: 1, y: -50-bob)], color: 0xFFF2B7, width: 2)
            p.oval(CGRect(x: 11, y: -55-bob, width: 8, height: 8), colors: [0xF9F0CA, 0xA79462])
            p.oval(CGRect(x: 13, y: -53-bob, width: 4.5, height: 4.5), colors: [0xFFFFEA, 0xFFE999])
            p.glow(CGPoint(x: 16, y: -51-bob), radius: 13, color: 0xFFECAC, opacity: 0.24)
            let work = pose.work
            let cycle = (work ?? 0).truncatingRemainder(dividingBy: 1.6) / 1.6
            let swing = work == nil ? -0.18 + Double(stride) * 0.10 : -1.05 + pow(min(1, cycle / 0.62), 2) * 1.20
            var tool = p.context; tool.translateBy(x: 8, y: -27-bob); tool.rotate(by: .radians(swing))
            let t = CrystalCavePainter(context: tool)
            t.line([.init(x: -3, y: 10), .init(x: 24, y: -25)], color: 0x60452F, width: 4)
            t.line([.init(x: -2, y: 9), .init(x: 24, y: -25)], color: 0xD0A36E, width: 1.4)
            t.material(t.contour([.init(x: 11, y: -27), .init(x: 24, y: -32), .init(x: 38, y: -24),
                                  .init(x: 29, y: -25), .init(x: 23, y: -27), .init(x: 13, y: -23)], radius: 1),
                       colors: [0xDCE6DF, 0x8CA7B5, 0x4C677E])
            p.line([.init(x: 8, y: -30-bob), .init(x: 13, y: -23-bob), .init(x: 16, y: -27-bob)],
                   color: palette[1], width: 6)
            if work != nil && cycle > 0.60 && cycle < 0.77 {
                let energy = 1 - abs(cycle - 0.68) / 0.09
                p.sparkle(at: CGPoint(x: 36, y: -36), radius: max(0.4, energy * 2))
                p.line([.init(x: 37, y: -38), .init(x: 41, y: -43)], color: 0xDCFDF4, width: 0.9, opacity: energy)
            }
        }
    }

    private func lantern(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.glow(CGPoint(x: 0, y: -22), radius: 49, color: 0xFFE5A4, opacity: 0.32)
            p.rounded(CGRect(x: -9, y: -33, width: 18, height: 25), radius: 3, colors: [0xBBA26F, 0x8B815D])
            p.rounded(CGRect(x: -6, y: -30, width: 12, height: 18), radius: 2, colors: [0xFFF6CC, 0xF6D28B, 0xE9AE62])
            p.line([.init(x: 0, y: -29), .init(x: 0, y: -12)], color: 0xD4B57D, width: 1)
            p.polygon([.init(x: -12, y: -33), .init(x: 0, y: -40), .init(x: 12, y: -33)], colors: [0xD9C492, 0x8D8766])
            p.rounded(CGRect(x: -12, y: -9, width: 24, height: 4), radius: 1, colors: [0xD3BE8E, 0x96906F])
            p.line([.init(x: -3, y: -40), .init(x: -3, y: -44), .init(x: 3, y: -44), .init(x: 3, y: -40)], color: 0xA7A280, width: 1.3)
        }
    }
    private func pool(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.ground(at: CGPoint(x: 0, y: 8), width: 135, height: 43, color: 0x3D638A, opacity: 0.3)
            let pool = p.contour([.init(x: -51, y: 1), .init(x: -33, y: -12), .init(x: -6, y: -10),
                                  .init(x: 17, y: -17), .init(x: 44, y: -9), .init(x: 53, y: 7),
                                  .init(x: 22, y: 20), .init(x: -13, y: 18), .init(x: -41, y: 16)], radius: 12)
            p.context.stroke(pool.offsetBy(dx: 0, dy: 3), with: .color(Color(dinoHex: 0x4C688D)), style: StrokeStyle(lineWidth: 7, lineJoin: .round))
            p.context.stroke(pool, with: .color(Color(dinoHex: 0xAABDD0)), style: StrokeStyle(lineWidth: 5, lineJoin: .round))
            p.material(pool, colors: [0x609EBE, 0x8DD6DC, 0xC4F2E6])
            for (x, y): (CGFloat, CGFloat) in [(-32, 4), (1, 11), (24, -2)] {
                var ripple = Path(); ripple.move(to: CGPoint(x: x, y: y))
                ripple.addQuadCurve(to: CGPoint(x: x + 16, y: y + 1), control: CGPoint(x: x + 8, y: y + 4))
                p.context.stroke(ripple, with: .color(Color(dinoHex: 0xE2FFF4).opacity(0.7)), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
            }
        }
    }

    /// Broad, overlapping stone shelves give the side wall an unmistakable mass.
    private func rockTerraces(at point: CGPoint, size: CGFloat, mirror: Bool = false) {
        at(point, size: size, mirror: mirror, radius: 68 * size, rise: 300 * size, clearTimber: true) { p in
            for (i, y) in [CGFloat(-231), -164, -91, -14].enumerated() {
                let x: CGFloat = i % 2 == 0 ? -9 : 12
                p.wallBoulder(in: CGRect(x: x - 63, y: y - 65, width: 126 + CGFloat(i % 2) * 15, height: 114),
                              variation: i * 3 + 1)
                p.cluster(at: CGPoint(x: x - 26, y: y - 32), size: 0.36 + CGFloat(i % 2) * 0.08, variation: i + 3)
                if i == 1 || i == 3 { p.plants(at: CGPoint(x: x + 35, y: y + 22), size: 0.36) }
            }
            p.rock(at: CGPoint(x: -38, y: 29), size: 0.63)
            p.crystal(at: CGPoint(x: 35, y: 28), height: 39, tint: 3)
        }
    }

    private func geode(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rock(at: CGPoint(x: 0, y: 0), size: 1.85)
            p.oval(CGRect(x: -35, y: -69, width: 70, height: 64), colors: [0x747399, 0x455C83, 0x374C71])
            p.oval(CGRect(x: -28, y: -64, width: 56, height: 53), colors: [0x6E789D, 0x324D74])
            p.glow(CGPoint(x: 0, y: -39), radius: 32, color: 0xBFA5EB, opacity: 0.44)
            for i in 0..<5 { p.crystal(at: CGPoint(x: CGFloat(i - 2) * 11, y: -15 + CGFloat(i % 2) * 2), height: 22 + CGFloat(i % 3) * 8, tint: i % 3) }
            p.crystal(at: CGPoint(x: -36, y: 1), height: 23, tint: 0)
            p.plants(at: CGPoint(x: 39, y: 10), size: 0.64)
        }
    }
    private func clockStone(at point: CGPoint, size: CGFloat, late: Bool) {
        at(point, size: size) { p in
            p.ground(at: CGPoint(x: 0, y: 10), width: 116, height: 35)
            let shell = p.contour([.init(x: -42, y: 9), .init(x: -43, y: -43), .init(x: -31, y: -63),
                                   .init(x: 24, y: -65), .init(x: 41, y: -49), .init(x: 43, y: -4),
                                   .init(x: 27, y: 15), .init(x: -27, y: 17)], radius: 10)
            p.material(shell, colors: [0xC7D2DB, 0x96A8C0, 0x637FA4])
            p.rounded(CGRect(x: -33, y: -54, width: 66, height: 30), radius: 8, colors: [0x405B7A, 0x29465F])
            p.context.stroke(Path(roundedRect: CGRect(x: -33, y: -54, width: 66, height: 30), cornerRadius: 8), with: .color(Color(dinoHex: 0xB7E4E3)), lineWidth: 1.2)
            p.context.draw(Text(verbatim: late ? "08:43" : "02:17").font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(dinoHex: 0xFFE8B0)), at: CGPoint(x: 0, y: -39))
            p.line([.init(x: -26, y: -58), .init(x: -5, y: -60), .init(x: 15, y: -58)], color: 0xE4F0E9, width: 0.9, opacity: 0.65)
            p.line([.init(x: -34, y: -11), .init(x: -22, y: -6), .init(x: -17, y: -9)], color: 0x5C799E, width: 0.9)
            p.crystal(at: CGPoint(x: 38, y: 13), height: 26, tint: 0)
            p.rock(at: CGPoint(x: -32, y: 13), size: 0.28)
        }
    }
    private func arch(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            let arch = Path { a in
                a.move(to: CGPoint(x: -69, y: 4)); a.addCurve(to: CGPoint(x: 68, y: 4), control1: CGPoint(x: -71, y: -204), control2: CGPoint(x: 77, y: -201))
                a.addLine(to: CGPoint(x: 44, y: 2)); a.addCurve(to: CGPoint(x: -44, y: 2), control1: CGPoint(x: 47, y: -146), control2: CGPoint(x: -47, y: -142))
                a.closeSubpath()
            }
            p.material(arch, colors: [0xA8ADC1, 0x778DA8, 0x536C91])
            p.context.stroke(arch, with: .color(Color(dinoHex: 0x536B8D).opacity(0.65)), lineWidth: 1.5)
            for i in 0..<7 {
                let angle = Double(i) * .pi / 6
                let x = CGFloat(cos(angle)), y = CGFloat(sin(angle))
                p.line([.init(x: x * 65, y: -y * 147), .init(x: x * 45, y: -y * 106)], color: 0x4F6485, width: 1.3)
            }
            p.cluster(at: CGPoint(x: -50, y: 8), size: 0.55, variation: 0)
            p.cluster(at: CGPoint(x: 54, y: 12), size: 0.48, variation: 1)
            p.crystal(at: CGPoint(x: 0, y: -138), height: 42, tint: 1)
            p.plants(at: CGPoint(x: -61, y: 14), size: 0.68)
        }
    }
    func scene(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size, radius: 77 * size, rise: 130 * size, clearTimber: true) { p in
            // The asymmetric shelf shares the wall material and seats every root.
            p.ground(at: CGPoint(x: 0, y: 14), width: 177, height: 54)
            p.material(p.contour([.init(x: -76, y: -9), .init(x: -44, y: -28), .init(x: 14, y: -25),
                                   .init(x: 67, y: -5), .init(x: 73, y: 19), .init(x: 25, y: 33), .init(x: -52, y: 24)], radius: 12),
                       colors: [0xA7BACD, 0x7C94B2, 0x566F94])
            p.line([.init(x: -56, y: 15), .init(x: -27, y: 21), .init(x: -8, y: 19)], color: 0xD0E1E1, width: 1, opacity: 0.5)
            switch variation % 4 {
            case 0:
                p.cluster(at: CGPoint(x: -3, y: 3), size: 1.0, variation: variation)
            case 1:
                p.geode(at: CGPoint(x: -4, y: 3), size: 0.98)
                p.lantern(at: CGPoint(x: 42, y: 22), size: 0.66)
            case 2:
                p.crystal(at: CGPoint(x: -42, y: -3), height: 58, tint: variation > 3 ? 0 : 1)
                p.clockStone(at: CGPoint(x: 8, y: 7), size: 0.94, late: variation > 3)
            default:
                p.wallBoulder(in:CGRect(x:-54,y:-85,width:100,height:111),variation:3)
                p.cluster(at:CGPoint(x:-12,y:-58),size:0.51,variation:4)
                p.rock(at:CGPoint(x:39,y:16),size:0.62)
                p.crystal(at:CGPoint(x:40,y:7),height:34,tint:3)
            }
            if variation % 4 != 3 { p.plants(at: CGPoint(x: -51, y: 22), size: 0.48) }
        }
    }
}

/// Cream stone, copper trim and turquoise domes distinguish Dino Stad.
private struct CityWorldPainter {
    let context: GraphicsContext
    var scenery: WorldSceneryLayout? = nil
    var depth: WorldSceneryDepth? = nil
    var depthOffset: CGFloat = 0

    private func at(_ point: CGPoint, size: CGFloat = 1, mirror: Bool = false, radius: CGFloat = 0, rise: CGFloat = 0, draw: @escaping (CityWorldPainter) -> Void) {
        let point = scenery?.position(point, radius: radius, rise: rise) ?? point
        var c = context; c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: mirror ? -size : size, y: size)
        if let depth {
            depth.add(at: depthOffset + point.y) { draw(.init(context: c)) }
        } else { draw(.init(context: c)) }
    }
    private func material(_ path: Path, colors: [UInt32]) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
    }
    private func rounded(_ r: CGRect, radius: CGFloat, colors: [UInt32]) {
        material(Path(roundedRect: r, cornerRadius: radius), colors: colors)
    }
    private func polygon(_ points: [CGPoint], colors: [UInt32]) {
        var p = Path(); p.addLines(points); p.closeSubpath(); material(p, colors: colors)
    }
    private func oval(_ r: CGRect, colors: [UInt32]) {
        context.fill(Path(ellipseIn: r), with: .radialGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                            center: CGPoint(x: r.minX + r.width * 0.3, y: r.minY + r.height * 0.2),
                                                            startRadius: 0, endRadius: max(r.width, r.height) * 0.85))
    }
    private func line(_ points: [CGPoint], color: UInt32, width: CGFloat, opacity: Double = 1) {
        var p = Path(); p.addLines(points)
        context.stroke(p, with: .color(Color(dinoHex: color).opacity(opacity)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func glow(_ point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), Color(dinoHex: color).opacity(0)]),
                                           center: point, startRadius: 0, endRadius: radius))
    }

    func landscape(in size: CGSize, routeOffset: CGFloat, depth: WorldSceneryDepth) {
        let w = size.width, h = size.height
        let scale = min(1.30, max(0.82, w / 390))
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: 0xACBEB4), location: 0),
            .init(color: Color(dinoHex: 0xC5D1B9), location: 0.055),
            .init(color: Color(dinoHex: 0xE5EBCF), location: (routeOffset + 110) / h),
            .init(color: Color(dinoHex: 0xDFE5BF), location: 0.38),
            .init(color: Color(dinoHex: 0xD1DFBB), location: 0.70),
            .init(color: Color(dinoHex: 0xD4DDC4), location: 1)
        ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
        entrance(width: w, scale: scale)
        CrystalCavePainter(context: context).exitClearing(width: w, boundaryY: 0)
        var c = context; c.translateBy(x: 0, y: routeOffset)
        let scenery = WorldSceneryLayout(width: w, height: h, routeOffset: routeOffset)
        scenery.drawBanks(in: c, worldID: 6)
        let p = CityWorldPainter(context: c, depth: depth, depthOffset: routeOffset)
        p.quays(along: scenery)
        CrystalCavePainter(context: context).approach(in: size, routeOffset: routeOffset, leavingCave: true)
        CrystalCavePainter(context: context).exitWall(width: w)

        let crossings: [(right: Bool, y: CGFloat)] = [(false, 480), (true, 815), (false, 1165), (true, 1505)]
        p.bankDetails(along: scenery, crossings: crossings)
        p.pocketGardens(along: scenery)
        p.canalBoat(along: scenery, right: false, y: 575)

        // Foundations stay beyond the outer quay, even on the tight phone bends.
        let districts: [(right: Bool, y: CGFloat, size: CGFloat, kind: Int)] = [
            (false, 360, 0.58, 1), (false, 450, 0.73, 0), (true, 790, 0.82, 1),
            (false, 1140, 0.84, 2), (true, 1480, 0.73, 0)
        ]
        for district in districts {
            let objectScale = scale * district.size
            let halfWidth: CGFloat = district.kind == 0 ? 76 : district.kind == 1 ? 68 : 61
            let point = p.outerBankFoundation(along: scenery, right: district.right,
                                              y: district.y, halfWidth: halfWidth * objectScale)
            p.district(at: point, size: objectScale, variation: district.kind)
        }
        for crossing in crossings {
            p.canalCrossing(along: scenery, right: crossing.right, y: crossing.y)
        }
        p.bossPlaza(width: w, scale: scale, layout: scenery)
    }

    private func bossPlaza(width: CGFloat, scale: CGFloat, layout: WorldSceneryLayout) {
        let point = CGPoint(x: width - 79 * scale, y: 1687)
        let approach = Path { p in
            p.move(to: CGPoint(x: layout.centerX(at: 1710), y: 1710))
            p.addQuadCurve(to: point, control: CGPoint(x: point.x - 45 * scale, y: 1710))
        }
        for (w, color): (CGFloat, UInt32) in [(18, 0xBAC3A5), (13, 0xF2E4C3)] {
            context.stroke(approach, with: .color(Color(dinoHex: color)), style: StrokeStyle(lineWidth: w * scale, lineCap: .round))
        }
        paving(at: point, width: 135 * scale)
        planter(at: CGPoint(x: point.x - 49 * scale, y: point.y + 12 * scale), size: scale * 0.43)
        flowers(at: CGPoint(x: point.x + 48 * scale, y: point.y + 11 * scale), size: scale * 0.53)
    }

    private func canalPath(along layout: WorldSceneryLayout, right: Bool, offset: CGFloat) -> Path {
        Path { path in
            let start = -layout.routeOffset + 12
            let end = layout.height - layout.routeOffset - 12
            let count = Int(ceil((end - start) / 5))
            for i in 0...count {
                let y = start + (end - start) * CGFloat(i) / CGFloat(count)
                let point = layout.cityCanalPoint(at: y, right: right, offset: offset)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
        }
    }

    private func quays(along layout: WorldSceneryLayout) {
        let s = layout.scale
        for right in [false, true] { for bank: CGFloat in [-1, 1] {
            let promenade = canalPath(along: layout, right: right, offset: bank * 36 * s)
            for (width, color): (CGFloat, UInt32) in [(19, 0xBCC6A4), (13, 0xDFD9BC), (10, 0xF0E4C8)] {
                context.stroke(promenade, with: .color(Color(dinoHex: color)),
                               style: StrokeStyle(lineWidth: width * s, lineCap: .round, lineJoin: .round))
            }
            let coping = canalPath(along: layout, right: right, offset: bank * 24 * s)
            context.stroke(coping, with: .color(Color(dinoHex: 0x769F9A).opacity(0.6)),
                           style: StrokeStyle(lineWidth: 2.7 * s, lineCap: .round, lineJoin: .round))
            context.stroke(coping, with: .color(Color(dinoHex: 0xFFF0CD)),
                           style: StrokeStyle(lineWidth: 1.3 * s, lineCap: .round, lineJoin: .round))
            for i in 0..<91 {
                let y = 105 + CGFloat(i) * 18
                let a = layout.cityCanalPoint(at: y, right: right, offset: bank * 31 * s)
                let b = layout.cityCanalPoint(at: y, right: right, offset: bank * 41 * s)
                line([a, b], color: 0xB9BAA0, width: 0.65 * s, opacity: 0.6)
            }
        } }
    }

    private func outerBankFoundation(along layout: WorldSceneryLayout, right: Bool, y: CGFloat, halfWidth: CGFloat) -> CGPoint {
        var edge: CGFloat = right ? -1000 : layout.width + 1000
        // Check the whole ground footprint, rather than its centre alone.
        for i in 0...14 {
            let point = layout.cityCanalPoint(at: y - 18 * layout.scale + CGFloat(i) * 4 * layout.scale,
                                              right: right, offset: 44 * layout.scale)
            edge = right ? max(edge, point.x) : min(edge, point.x)
        }
        return CGPoint(x: edge + (right ? halfWidth : -halfWidth), y: y)
    }

    private func district(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            p.paving(at: CGPoint(x: 0, y: 9), width: variation == 0 ? 144 : variation == 2 ? 122 : 132)
            switch variation {
            case 0:
                p.station(at: CGPoint(x: 0, y: -2), size: 0.94)
                p.planter(at: CGPoint(x: -53, y: 19), size: 0.48)
                p.flowers(at: CGPoint(x: 47, y: 20), size: 0.55)
            case 1:
                p.building(at: CGPoint(x: -18, y: -8), size: 0.86, tower: false, cafe: true)
                p.palm(at: CGPoint(x: 40, y: 1), size: 0.69)
                p.bench(at: CGPoint(x: 28, y: 20), size: 0.57)
            default:
                p.building(at: CGPoint(x: -8, y: -4), size: 0.9, tower: true)
                p.fountain(at: CGPoint(x: 31, y: 23), size: 0.49)
                p.flowers(at: CGPoint(x: -31, y: 24), size: 0.7)
            }
        }
    }

    private func pocketGardens(along layout: WorldSceneryLayout) {
        let s = layout.scale
        for (i, y): (Int, CGFloat) in [350.0, 600, 965, 1320].enumerated() {
            for right in [false, true] {
                let point = outerBankFoundation(along: layout, right: right, y: y, halfWidth: 48 * s)
                guard point.x > 44 * s, point.x < layout.width - 44 * s else { continue }
                garden(at: point, size: s * 0.72, variation: i)
            }
        }
    }

    private func canalBoat(along layout: WorldSceneryLayout, right: Bool, y: CGFloat) {
        let point = layout.cityCanalPoint(at: y, right: right)
        let a = layout.cityCanalPoint(at: y - 1, right: right)
        let b = layout.cityCanalPoint(at: y + 1, right: right)
        var c = context; c.translateBy(x: point.x, y: point.y)
        c.rotate(by: .radians(Double(-atan2(b.x - a.x, b.y - a.y))))
        let p = CityWorldPainter(context: c)
        p.at(.zero, size: layout.scale * 0.72) { boat in
            for x: CGFloat in [-15, 15] {
                boat.line([.init(x: x, y: -5), .init(x: x, y: 12)], color: 0xE8F9E7, width: 1, opacity: 0.7)
            }
            let hull = Path { h in
                h.move(to: .init(x: 0, y: -26))
                h.addCurve(to: .init(x: 0, y: 24), control1: .init(x: 18, y: -12), control2: .init(x: 14, y: 20))
                h.addCurve(to: .init(x: 0, y: -26), control1: .init(x: -14, y: 20), control2: .init(x: -18, y: -12))
            }
            boat.material(hull, colors: [0xFBE3A3, 0xC39F64, 0xA67F54])
            boat.oval(CGRect(x: -8, y: -14, width: 16, height: 31), colors: [0x578B91, 0x3B6975])
            for seat: CGFloat in [-6, 9] {
                boat.rounded(CGRect(x: -9, y: seat, width: 18, height: 4), radius: 1.5, colors: [0xF6D69B, 0xC29F6A])
            }
            boat.line([.init(x: -11, y: -12), .init(x: 10, y: 16)], color: 0xE8BE79, width: 1.8)
        }
    }

    private func canalCrossing(along layout: WorldSceneryLayout, right: Bool, y: CGFloat) {
        let s = layout.scale
        var left = CGFloat.greatestFiniteMagnitude, rightEdge = -CGFloat.greatestFiniteMagnitude
        // Span the river's full screen-space width beneath the deck and feet.
        // Keep the bridge level, with both landings beyond the water's stone rim.
        for i in 0...10 {
            let sampleY = y + (-6 + CGFloat(i) * 4) * s
            let point = layout.cityCanalPoint(at: sampleY, right: right)
            let a = layout.cityCanalPoint(at: sampleY - 1, right: right)
            let b = layout.cityCanalPoint(at: sampleY + 1, right: right)
            let slope = (b.x - a.x) / 2
            let rim = 27 * s * sqrt(1 + slope * slope)
            left = min(left, point.x - rim)
            rightEdge = max(rightEdge, point.x + rim)
        }
        let centerX = (left + rightEdge) / 2
        let halfSpan = max(54 * s, (rightEdge - left) / 2 + 21 * s)
        let inner = CGPoint(x: centerX + (right ? -halfSpan : halfSpan), y: y + 3 * s)
        let start = CGPoint(x: layout.centerX(at: y + 12 * s), y: y + 12 * s)
        let lane = Path { p in
            p.move(to: start)
            p.addCurve(to: inner, control1: CGPoint(x: start.x + (inner.x - start.x) * 0.45, y: start.y),
                       control2: CGPoint(x: inner.x, y: inner.y))
        }
        for (width, color): (CGFloat, UInt32) in [(17, 0xB6BFA1), (13, 0xF2E4BD), (8, 0xF9EDCF)] {
            context.stroke(lane, with: .color(Color(dinoHex: color)), style: StrokeStyle(lineWidth: width * s, lineCap: .round))
        }
        bridge(at: CGPoint(x: centerX, y: y), size: s, span: halfSpan * 2 / s)
    }

    private func bankDetails(along layout: WorldSceneryLayout, crossings: [(right: Bool, y: CGFloat)]) {
        let s = layout.scale
        for right in [false, true] { for bank: CGFloat in [-1, 1] {
            for i in 0..<15 {
                let y = 300 + CGFloat(i) * 88 + (right ? 34 : 0) + (bank > 0 ? 23 : 0)
                if crossings.contains(where: { $0.right == right && abs($0.y - y) < 55 }) { continue }
                let point = layout.cityCanalPoint(at: y, right: right, offset: bank * 48 * s)
                guard point.x > -15 * s && point.x < layout.width + 15 * s else { continue }
                at(point, size: s * 0.47) { p in
                    // Small planted pockets sit on land beside the continuous paving.
                    switch (i + (right ? 1 : 0) + (bank > 0 ? 2 : 0)) % 4 {
                    case 0:
                        p.paving(at: .zero, width: 32)
                        p.lamp(at: .zero, size: 0.9, banner: false)
                        p.flowers(at: CGPoint(x: 15, y: 5), size: 0.4)
                    case 1:
                        p.paving(at: .zero, width: 60)
                        p.bench(at: .zero, size: 0.78)
                        p.flowers(at: CGPoint(x: -25, y: 7), size: 0.44)
                    case 2:
                        p.planter(at: .zero, size: 0.72, palm: false)
                    default:
                        p.plants(at: .zero, size: 0.75)
                        p.flowers(at: CGPoint(x: 13, y: 5), size: 0.6)
                    }
                }
            }
            // Low mooring posts make both edges legible without hiding the water.
            for i in 0..<25 {
                let y = 280 + CGFloat(i) * 55
                if crossings.contains(where: { $0.right == right && abs($0.y - y) < 43 }) { continue }
                let point = layout.cityCanalPoint(at: y, right: right, offset: bank * 25 * s)
                at(point, size: s) { p in
                    p.oval(CGRect(x: -3, y: -1, width: 6, height: 3), colors: [0x9AAE98, 0xD8D1AF])
                    p.rounded(CGRect(x: -1.7, y: -8, width: 3.4, height: 8), radius: 1.4, colors: [0xA1C5B2, 0x4C8C92])
                    p.oval(CGRect(x: -3, y: -9, width: 6, height: 3), colors: [0xF4D698, 0xB69C69])
                }
            }
        } }
    }

    private func entrance(width: CGFloat, scale: CGFloat) {
        let sun = CGPoint(x: width * 0.23, y: 65 * scale)
        glow(sun, radius: 135 * scale, color: 0xFFF1BF, opacity: 0.7)
        oval(CGRect(x: sun.x - 20, y: sun.y - 20, width: 40, height: 40), colors: [0xFFF9D9, 0xFFEBAD])
        for i in 0..<4 {
            at(CGPoint(x: width * (0.08 + CGFloat(i) * 0.29), y: (42 + CGFloat(i % 2) * 36) * scale), size: scale * 0.75) { p in
                var cloud = Path()
                for r in [CGRect(x: -53, y: 0, width: 115, height: 20), CGRect(x: -29, y: -18, width: 48, height: 34), CGRect(x: 7, y: -25, width: 51, height: 44)] { cloud.addEllipse(in: r) }
                p.context.drawLayer { c in
                    c.addFilter(.blur(radius: 1.5))
                    c.fill(cloud, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFFFEC).opacity(0.94), Color(dinoHex: 0xE6F1DE).opacity(0)]),
                                                       startPoint: CGPoint(x: 0, y: -25), endPoint: CGPoint(x: 0, y: 23)))
                }
            }
        }
        var distant = context; distant.opacity = 0.56
        distant.clipToLayer { mask in
            mask.fill(Path(CGRect(x: 0, y: 0, width: width, height: 340 * scale)),
                      with: .linearGradient(Gradient(stops: [.init(color: .white, location: 0), .init(color: .white, location: 0.35), .init(color: .white.opacity(0), location: 1)]),
                                            startPoint: CGPoint(x: 0, y: 120 * scale), endPoint: CGPoint(x: 0, y: 270 * scale)))
        }
        let far = CityWorldPainter(context: distant)
        for i in 0..<5 {
            far.at(CGPoint(x: CGFloat(i) * width / 4, y: (206 + CGFloat(i % 2) * 23) * scale), size: scale) { p in
                p.cliff(at: .zero, size: 1.6)
                p.building(at: CGPoint(x: -3, y: -76), size: 0.56 + CGFloat(i % 2) * 0.14, tower: i % 2 == 1)
                if i == 1 || i == 3 { p.waterfall(at: CGPoint(x: 29, y: -49), size: 0.75) }
            }
        }
        far.bridge(at: CGPoint(x: width * 0.47, y: 172 * scale), size: 1.65 * scale)
        building(at: CGPoint(x: width * 0.76, y: 197 * scale), size: scale * 0.93, tower: true)
        building(at: CGPoint(x: 25 * scale, y: 282 * scale), size: scale * 0.89, tower: false)
        palm(at: CGPoint(x: -3, y: 259 * scale), size: scale * 0.94)
        palm(at: CGPoint(x: width + 9, y: 302 * scale), size: scale * 1.03)
    }

    private func paving(at point: CGPoint, width: CGFloat) {
        let r = CGRect(x: point.x - width / 2, y: point.y - width * 0.15, width: width, height: width * 0.34)
        oval(r.offsetBy(dx: 0, dy: 4), colors: [0xACB9A1, 0xC7D2AD])
        oval(r, colors: [0xF5E8C9, 0xD9D5B9, 0xBAC5AD])
        var c = context; c.clip(to: Path(ellipseIn: r))
        let p = CityWorldPainter(context: c)
        for row in 0..<3 { for col in 0..<8 {
            p.rounded(CGRect(x: r.minX + CGFloat(col) * width / 7 - CGFloat(row % 2) * width / 14,
                             y: r.minY + CGFloat(row) * width * 0.11, width: width / 7 - 1, height: width * 0.11 - 1),
                      radius: 2, colors: [0xF0E6CD, 0xD3D0B9])
        } }
    }
    private func cliff(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.polygon([.init(x: -41, y: 9), .init(x: -33, y: -55), .init(x: -15, y: -78), .init(x: 18, y: -73), .init(x: 38, y: -44), .init(x: 45, y: 9)], colors: [0xB7BDAF, 0x889FA5, 0x718D9B])
            p.polygon([.init(x: -15, y: -78), .init(x: 4, y: -68), .init(x: -9, y: -25), .init(x: -11, y: 9), .init(x: -35, y: 9)], colors: [0xDED5B7, 0xA5B6AA])
            p.line([.init(x: 14, y: -62), .init(x: 23, y: -38), .init(x: 19, y: -8)], color: 0x617F91, width: 1.1, opacity: 0.6)
            p.oval(CGRect(x: -28, y: -82, width: 55, height: 13), colors: [0xBFD392, 0x86AF7E])
        }
    }
    private func waterfall(at point: CGPoint, size: CGFloat, mirror: Bool = false) {
        at(point, size: size, mirror: mirror) { p in
            p.cliff(at: CGPoint(x: -19, y: -1), size: 1.05)
            p.cliff(at: CGPoint(x: 28, y: 6), size: 0.68)
            p.rounded(CGRect(x: -9, y: -52, width: 27, height: 94), radius: 5, colors: [0xD4F8EA, 0x8AD6D8, 0x5DB7C8, 0xB4E7DA])
            for i in 0..<4 { p.line([.init(x: CGFloat(i) * 6 - 6, y: -47), .init(x: CGFloat(i) * 6 - 7, y: 31 + CGFloat(i % 2) * 6)], color: 0xF1FFF2, width: i % 2 == 0 ? 2 : 1, opacity: 0.85) }
            p.oval(CGRect(x: -31, y: 31, width: 66, height: 19), colors: [0xF0FFF0, 0xADE3D9, 0x77C3C6])
            for i in 0..<4 { p.oval(CGRect(x: CGFloat(i) * 13 - 22, y: 35 + CGFloat(i % 2) * 3, width: 14, height: 3), colors: [0xF7FFF1, 0xCDEFE0]) }
            p.plants(at: CGPoint(x: 26, y: 20), size: 0.7)
        }
    }
    private func bridge(at point: CGPoint, size: CGFloat, span: CGFloat = 112) {
        at(point, size: size) { p in
            let half = span / 2
            let postX = half - 8
            // A light timber footbridge with level rails and stone landings.
            // Only the slim front beam crosses the water; its supports stay ashore.
            p.context.fill(Path(ellipseIn: CGRect(x: -half + 17, y: 20, width: span - 34, height: 19)),
                           with: .linearGradient(Gradient(colors: [Color(dinoHex: 0x3F7C82).opacity(0.23), .clear]),
                                                 startPoint: .init(x: 0, y: 21), endPoint: .init(x: 0, y: 39)))
            for x: CGFloat in [-half + 10, half - 10] {
                p.rounded(CGRect(x: x - 10, y: 14, width: 20, height: 20), radius: 5,
                          colors: [0xEDE0BD, 0xC5C7AA, 0xA4B49D])
                p.line([.init(x: x - 7, y: 25), .init(x: x + 7, y: 25)], color: 0xF8EAC7, width: 1)
                p.rounded(CGRect(x: x - 13, y: -10, width: 26, height: 32), radius: 5,
                          colors: [0xFFF0CD, 0xE6D7B4, 0xC9C8A8])
            }
            // Rear railing uses upright posts and straight, parallel handrails.
            p.line([.init(x: -postX, y: -26), .init(x: postX, y: -26)], color: 0x438B91, width: 3)
            p.line([.init(x: -postX, y: -27), .init(x: postX, y: -27)], color: 0xB1D5C5, width: 0.8)
            p.line([.init(x: -postX, y: -16), .init(x: postX, y: -16)], color: 0x79AAA0, width: 1.1)
            let panels = max(4, Int(span / 18))
            for i in 0...panels {
                let x = -postX + CGFloat(i) * postX * 2 / CGFloat(panels)
                p.line([.init(x: x, y: -25), .init(x: x, y: -7)], color: 0x5E9B97, width: 1.6)
            }
            for x: CGFloat in [-postX, postX] {
                p.rounded(CGRect(x: x - 3.5, y: -31, width: 7, height: 25), radius: 2.5,
                          colors: [0xFFF0CF, 0xC7CBB0])
                p.oval(CGRect(x: x - 4.5, y: -34, width: 9, height: 5), colors: [0xF9DDA3, 0xC1A66D])
            }
            let deck = Path(roundedRect: CGRect(x: -half + 3, y: -8, width: span - 6, height: 31), cornerRadius: 4)
            p.material(deck, colors: [0xFFF0CD, 0xE8CE9E, 0xD1BA8C])
            var deckContext = p.context; deckContext.clip(to: deck)
            let timber = CityWorldPainter(context: deckContext)
            let planks = max(10, Int(span / 8))
            for i in 0...planks {
                let x = -half + 3 + CGFloat(i) * (span - 6) / CGFloat(planks)
                timber.line([.init(x: x, y: -7), .init(x: x, y: 22)], color: 0xB79F75, width: 0.75, opacity: 0.65)
                if i % 3 == 1 {
                    timber.line([.init(x: x + 2, y: -2), .init(x: x + 2, y: 14)], color: 0xFFF5D9, width: 0.7, opacity: 0.7)
                }
            }
            p.rounded(CGRect(x: -half + 3, y: 20, width: span - 6, height: 6), radius: 2,
                      colors: [0x82B9AC, 0x4D9394, 0x3E7D86])
            p.line([.init(x: -half + 5, y: 20), .init(x: half - 5, y: 20)], color: 0xF5E5B9, width: 1.5)
            // Front posts and their brass caps frame the open, walkable deck.
            p.line([.init(x: -postX, y: 5), .init(x: postX, y: 5)], color: 0x438B91, width: 3)
            p.line([.init(x: -postX, y: 4), .init(x: postX, y: 4)], color: 0xBDDCCC, width: 0.8)
            p.line([.init(x: -postX, y: 14), .init(x: postX, y: 14)], color: 0x73A69E, width: 1.1)
            for i in 0...panels {
                let x = -postX + CGFloat(i) * postX * 2 / CGFloat(panels)
                p.line([.init(x: x, y: 6), .init(x: x, y: 22)], color: 0x4D9292, width: 1.6)
            }
            for x: CGFloat in [-postX, postX] {
                p.rounded(CGRect(x: x - 3.5, y: -1, width: 7, height: 26), radius: 2.5,
                          colors: [0xFFF0CD, 0xC9CCAD])
                p.oval(CGRect(x: x - 4.5, y: -4, width: 9, height: 5), colors: [0xF9DDA3, 0xC1A66D])
            }
        }
    }

    private func leaf(at point: CGPoint, length: CGFloat, angle: Double) {
        at(point) { p in
            var c = p.context; c.rotate(by: .degrees(angle))
            let l = CityWorldPainter(context: c)
            let shape = Path { a in
                a.move(to: .zero)
                a.addCurve(to: .init(x: 0, y: -length), control1: .init(x: -length * 0.37, y: -length * 0.16), control2: .init(x: -length * 0.22, y: -length * 0.80))
                a.addCurve(to: .zero, control1: .init(x: length * 0.20, y: -length * 0.78), control2: .init(x: length * 0.34, y: -length * 0.21))
            }
            l.material(shape, colors: [0xC2D979, 0x78B073, 0x438C73])
            l.line([.zero, .init(x: 0, y: -length * 0.88)], color: 0xE0ECA3, width: 0.85, opacity: 0.7)
            for i in 1...3 { l.line([.init(x: 0, y: -length * CGFloat(i) * 0.21), .init(x: length * 0.12, y: -length * CGFloat(i) * 0.21 - 5)], color: 0xD2E69C, width: 0.6, opacity: 0.5) }
        }
    }
    private func plants(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for i in 0..<5 { p.leaf(at: .zero, length: 23 + CGFloat(i % 2) * 8, angle: Double(i - 2) * 32) }
        }
    }
    private func flowers(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for i in 0..<4 {
                let x = CGFloat(i) * 8 - 12, y = -4 - CGFloat(i % 2) * 8
                p.line([.init(x: x, y: 3), .init(x: x, y: y)], color: 0x70A67A, width: 1.2)
                for j in 0..<5 {
                    let a = Double(j) * .pi * 0.4
                    p.oval(CGRect(x: x + CGFloat(cos(a)) * 3 - 2.5, y: y + CGFloat(sin(a)) * 3 - 2.5, width: 5, height: 5), colors: i % 2 == 0 ? [0xFFFFE4, 0xF5E7AE] : [0xFFE9B3, 0xEAB975])
                }
                p.oval(CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3), colors: [0xFFEC8B, 0xD6B365])
            }
        }
    }
    private func planter(at point: CGPoint, size: CGFloat, palm: Bool = false) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -31, y: -2, width: 64, height: 17), colors: [0xA5B594, 0xD4DDB5])
            p.rounded(CGRect(x: -25, y: -16, width: 50, height: 21), radius: 8, colors: [0xF7E6BD, 0xCCBD99, 0xACAD8C])
            for x: CGFloat in [-13, 0, 13] { p.line([.init(x: x, y: -11), .init(x: x, y: 2)], color: 0xB7AC8B, width: 0.8) }
            p.oval(CGRect(x: -23, y: -20, width: 46, height: 11), colors: [0x789873, 0x91AC7D])
            if palm { p.palm(at: CGPoint(x: 0, y: -14), size: 0.77) }
            else {
                p.plants(at: CGPoint(x: -10, y: -14), size: 0.7)
                p.plants(at: CGPoint(x: 11, y: -14), size: 0.68)
            }
            p.flowers(at: CGPoint(x: -5, y: -13), size: 0.9)
        }
    }
    private func palm(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            let trunk = Path { t in
                t.move(to: .init(x: -7, y: 1)); t.addQuadCurve(to: .init(x: -1, y: -91), control: .init(x: 8, y: -48))
                t.addLine(to: .init(x: 9, y: -91)); t.addQuadCurve(to: .init(x: 8, y: 1), control: .init(x: 18, y: -48)); t.closeSubpath()
            }
            p.material(trunk, colors: [0xD7BD7E, 0xAE9764, 0x7F7D56])
            for i in 0..<8 { p.line([.init(x: CGFloat(i % 3) - 1, y: -7 - CGFloat(i) * 10), .init(x: 9 + CGFloat(i % 2), y: -10 - CGFloat(i) * 10)], color: 0xF0D59B, width: 1.3, opacity: 0.7) }
            for i in 0..<7 { p.leaf(at: CGPoint(x: 5, y: -89), length: 40 + CGFloat(i % 3) * 8, angle: Double(i - 3) * 35) }
            p.oval(CGRect(x: -2, y: -93, width: 8, height: 10), colors: [0xE6CB85, 0xB5A06C])
            p.oval(CGRect(x: 6, y: -90, width: 7, height: 9), colors: [0xC7B67A, 0x8E9263])
        }
    }

    private func dome(at point: CGPoint, width: CGFloat) {
        at(point) { p in
            let roof = Path { r in
                r.move(to: .init(x: -width / 2, y: 3))
                r.addCurve(to: .init(x: width / 2, y: 3), control1: .init(x: -width * 0.43, y: -40), control2: .init(x: width * 0.43, y: -40))
                r.closeSubpath()
            }
            p.material(roof, colors: [0xA4DDD5, 0x5AB8BE, 0x338B9E])
            var c = p.context; c.clip(to: roof)
            for i in 0..<7 {
                let x = CGFloat(i - 3) * width / 8
                var rib = Path(); rib.move(to: .init(x: x * 0.3, y: -29))
                rib.addQuadCurve(to: .init(x: x, y: 3), control: .init(x: x * 0.9, y: -18))
                c.stroke(rib, with: .color(Color(dinoHex: 0xD0EEE0).opacity(0.6)), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
            }
            p.rounded(CGRect(x: -width / 2 - 2, y: 1, width: width + 4, height: 6), radius: 2, colors: [0xFBE4AC, 0xCBB17C])
            p.oval(CGRect(x: -4, y: -34, width: 8, height: 8), colors: [0xFFF0B6, 0xD4AE68])
        }
    }
    private func window(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -10, y: -18, width: 20, height: 31), radius: 9, colors: [0xE6CA94, 0xBDA372])
            p.rounded(CGRect(x: -7, y: -15, width: 14, height: 25), radius: 7, colors: [0xC7E9DA, 0x79B9C1, 0x548EA4])
            p.line([.init(x: 0, y: -14), .init(x: 0, y: 10)], color: 0xE8D4AA, width: 1.5)
            p.line([.init(x: -7, y: -2), .init(x: 7, y: -2)], color: 0xE8D4AA, width: 1.5)
            p.line([.init(x: -5, y: -11), .init(x: -2, y: -6)], color: 0xF3FFF3, width: 1.3, opacity: 0.8)
            p.rounded(CGRect(x: -12, y: 11, width: 24, height: 4), radius: 1, colors: [0xFFF0CB, 0xC5B995])
        }
    }
    private func digital(at point: CGPoint, size: CGFloat, time: String) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -34, y: -14, width: 68, height: 29), radius: 7, colors: [0xF5D994, 0xC5A36B])
            p.rounded(CGRect(x: -29, y: -10, width: 58, height: 21), radius: 4, colors: [0x35616B, 0x244956])
            p.context.draw(Text(verbatim: time).font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(dinoHex: 0xFFE5A4)), at: CGPoint(x: 0, y: 0))
            for x: CGFloat in [-30, 30] { p.oval(CGRect(x: x - 0.8, y: -1, width: 1.6, height: 1.6), colors: [0xFFF2C2, 0xD9BD83]) }
        }
    }
    private func building(at point: CGPoint, size: CGFloat, tower: Bool, cafe: Bool = false) {
        at(point, size: size) { p in
            let h: CGFloat = tower ? 166 : 100
            p.oval(CGRect(x: -46, y: -4, width: 92, height: 20), colors: [0xA9B596, 0xCDD6AD])
            p.rounded(CGRect(x: -33, y: -h, width: 66, height: h), radius: 17, colors: [0xFFF3CE, 0xEBDABB, 0xC7C4A2])
            p.polygon([.init(x: 19, y: -h + 4), .init(x: 33, y: -h + 17), .init(x: 33, y: -4), .init(x: 19, y: 0)], colors: [0xD9D0AD, 0xBEC2A2])
            for i in 0..<4 {
                p.line([.init(x: -29, y: -18 - CGFloat(i) * 21), .init(x: -18, y: -18 - CGFloat(i) * 21)], color: 0xC2BA95, width: 0.8, opacity: 0.6)
                p.line([.init(x: 21, y: -31 - CGFloat(i) * 21), .init(x: 29, y: -31 - CGFloat(i) * 21)], color: 0xFDF2D2, width: 1)
            }
            p.rounded(CGRect(x: -12, y: -35, width: 24, height: 36), radius: 11, colors: [0x99C9BC, 0x55999A, 0x417D89])
            p.line([.init(x: 0, y: -29), .init(x: 0, y: -2)], color: 0xD3E4C5, width: 1.2)
            p.oval(CGRect(x: 5, y: -17, width: 3, height: 3), colors: [0xFFE9A3, 0xC8AA70])
            p.rounded(CGRect(x: -20, y: -1, width: 40, height: 6), radius: 2, colors: [0xFAE8C2, 0xC3C3A5])
            p.rounded(CGRect(x: -24, y: 4, width: 48, height: 5), radius: 2, colors: [0xE5D6B4, 0xADB59C])
            if tower {
                let clock = ThemePainter(context: p.context, colors: WorldThemeColors(DinoWorldCatalog.world(6)!))
                clock.clock(at: CGPoint(x: 0, y: -h + 40), time: .init(hour: 10, minute: 30), size: 22)
                p.window(at: CGPoint(x: -17, y: -56), size: 0.65)
                p.window(at: CGPoint(x: 17, y: -56), size: 0.65)
                p.digital(at: CGPoint(x: 0, y: -84), size: 0.85, time: "10:30")
            } else {
                for x: CGFloat in [-18, 18] { p.window(at: CGPoint(x: x, y: -65), size: 0.8) }
                p.rounded(CGRect(x: -29, y: -44, width: 58, height: 7), radius: 2, colors: [0xF4DFB5, 0xB4BC9B])
                for x: CGFloat in [-25, -15, -5, 5, 15, 25] { p.line([.init(x: x, y: -54), .init(x: x, y: -42)], color: 0x6FA6A0, width: 1.2) }
                p.plants(at: CGPoint(x: -25, y: -45), size: 0.38)
                p.flowers(at: CGPoint(x: 21, y: -44), size: 0.55)
                if cafe {
                    for i in 0..<6 {
                        let x = CGFloat(i) * 10 - 30
                        let colors: [UInt32] = i % 2 == 0 ? [0xFFF8DC, 0xEAE0BE] : [0xFFD786, 0xE8B26A]
                        p.polygon([.init(x: x + 4, y: -41), .init(x: x + 13, y: -41), .init(x: x + 10, y: -26), .init(x: x, y: -26)], colors: colors)
                        p.rounded(CGRect(x: x, y: -27, width: 10, height: 6), radius: 3, colors: colors)
                    }
                }
            }
            p.dome(at: CGPoint(x: 0, y: -h), width: 80)
            p.planter(at: CGPoint(x: -36, y: 11), size: 0.55)
            p.planter(at: CGPoint(x: 35, y: 13), size: 0.53)
        }
    }
    private func bench(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for x: CGFloat in [-24, 24] { p.line([.init(x: x, y: -18), .init(x: x, y: 5)], color: 0x4F8B91, width: 3) }
            for y: CGFloat in [-27, -20, -7] { p.rounded(CGRect(x: -30, y: y, width: 60, height: 5), radius: 2, colors: [0xF0D19A, 0xBF9C65]) }
            p.line([.init(x: -32, y: -9), .init(x: -32, y: -17), .init(x: -25, y: -17)], color: 0x4A8890, width: 2.4)
            p.line([.init(x: 32, y: -9), .init(x: 32, y: -17), .init(x: 25, y: -17)], color: 0x4A8890, width: 2.4)
        }
    }
    private func lamp(at point: CGPoint, size: CGFloat, banner: Bool) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -5, y: -69, width: 10, height: 72), radius: 3, colors: [0x9BC9B4, 0x498F95, 0x387B86])
            p.rounded(CGRect(x: -9, y: -3, width: 18, height: 6), radius: 2, colors: [0xE9D4A3, 0xA5B392])
            p.glow(CGPoint(x: 0, y: -72), radius: 24, color: 0xFFE8AE, opacity: 0.38)
            p.oval(CGRect(x: -8, y: -85, width: 16, height: 21), colors: [0xFFF6D2, 0xF9DEA3, 0xDCC083])
            p.rounded(CGRect(x: -10, y: -86, width: 20, height: 4), radius: 2, colors: [0xD4E0BA, 0x528F94])
            if banner {
                p.line([.init(x: 3, y: -62), .init(x: 27, y: -62)], color: 0x6A9D99, width: 2)
                p.polygon([.init(x: 8, y: -61), .init(x: 26, y: -61), .init(x: 26, y: -25), .init(x: 17, y: -18), .init(x: 8, y: -25)], colors: [0xFFE09E, 0xE4AA69])
                p.oval(CGRect(x: 13, y: -48, width: 9, height: 13), colors: [0xFFF2C6, 0xF5D496])
                for x: CGFloat in [12, 17, 22] { p.oval(CGRect(x: x, y: -54, width: 4, height: 5), colors: [0xFFF4D3, 0xF8DEA7]) }
            }
        }
    }
    private func tram(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for y: CGFloat in [9, 20] { p.line([.init(x: -70, y: y), .init(x: 70, y: y)], color: 0x829C9F, width: 2) }
            for x: CGFloat in [-44, -8, 31] { p.oval(CGRect(x: x, y: -2, width: 16, height: 16), colors: [0x6D8F93, 0x365E70]) }
            p.rounded(CGRect(x: -58, y: -50, width: 116, height: 55), radius: 14, colors: [0xFFECA5, 0xF1C363, 0xCF9F52])
            p.rounded(CGRect(x: -61, y: -52, width: 116, height: 8), radius: 4, colors: [0xA8D6C5, 0x5EA3A7])
            p.rounded(CGRect(x: -54, y: -17, width: 109, height: 10), radius: 3, colors: [0x74B8B3, 0x3C8996])
            for x: CGFloat in [-49, -25, 0, 25] {
                p.rounded(CGRect(x: x, y: -42, width: 19, height: 23), radius: 4, colors: [0x3E7B91, 0x7EB7BD, 0xB7D8CE])
                p.line([.init(x: x + 3, y: -37), .init(x: x + 8, y: -32)], color: 0xE8F9E1, width: 1.2, opacity: 0.75)
            }
            p.rounded(CGRect(x: -5, y: -41, width: 17, height: 37), radius: 2, colors: [0xB2C5A4, 0x6DA5A3])
            p.line([.init(x: 3, y: -38), .init(x: 3, y: -6)], color: 0xE2D6A4, width: 1)
            p.line([.init(x: -4, y: -55), .init(x: 5, y: -66), .init(x: 14, y: -55)], color: 0x6C9698, width: 1.7)
            p.oval(CGRect(x: 45, y: -11, width: 7, height: 7), colors: [0xFFFBE0, 0xFCE4A4])
            p.line([.init(x: -47, y: 0), .init(x: 46, y: 0)], color: 0xFFE9A7, width: 1.5)
        }
    }
    private func station(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -69, y: -8, width: 138, height: 19), radius: 5, colors: [0xF6E9C8, 0xC6CEB4, 0xA3B7AD])
            for x: CGFloat in [-54, 54] { p.rounded(CGRect(x: x - 4, y: -97, width: 9, height: 93), radius: 3, colors: [0xF8E5B5, 0xB5C8B0, 0x6D9E9C]) }
            let canopy = Path { c in
                c.move(to: .init(x: -76, y: -98)); c.addCurve(to: .init(x: 76, y: -98), control1: .init(x: -65, y: -140), control2: .init(x: 65, y: -140)); c.closeSubpath()
            }
            p.material(canopy, colors: [0xB1E2D3, 0x65BAC0, 0x378D9E])
            for i in 0..<7 {
                let x = CGFloat(i - 3) * 19
                p.line([.init(x: x * 0.86, y: -122 + abs(x) * 0.16), .init(x: x, y: -99)], color: 0xD4EED9, width: 1, opacity: 0.7)
            }
            p.line([.init(x: -75, y: -98), .init(x: 75, y: -98)], color: 0xE5CE99, width: 4)
            p.tram(at: CGPoint(x: -1, y: 5), size: 0.94)
            p.digital(at: CGPoint(x: 0, y: -80), size: 1, time: "08:05")
        }
    }
    private func fountain(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -41, y: -16, width: 82, height: 37), colors: [0xE8D7B4, 0xB8BFA4, 0x9EAF9E])
            for i in 0..<6 { p.line([.init(x: CGFloat(i) * 12 - 31, y: 3), .init(x: CGFloat(i) * 12 - 31, y: 12)], color: 0x9FAB98, width: 0.8) }
            p.oval(CGRect(x: -35, y: -17, width: 70, height: 22), colors: [0xB9E7D7, 0x6ABFC6, 0x529EAE])
            p.rounded(CGRect(x: -5, y: -52, width: 10, height: 46), radius: 3, colors: [0xF4E3B8, 0xB7C4A6])
            p.oval(CGRect(x: -17, y: -54, width: 34, height: 11), colors: [0xE8F7DE, 0x80CDD0])
            for side: CGFloat in [-1, 1] {
                var water = Path();                 water.move(to: .init(x: side * 3, y: -47))
                water.addQuadCurve(to: .init(x: side * 25, y: -6), control: .init(x: side * 22, y: -24))
                p.context.stroke(water, with: .color(Color(dinoHex: 0xE6FFF0)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                p.oval(CGRect(x: side * 25 - 5, y: -8, width: 11, height: 4), colors: [0xF5FFF0, 0xAFE5D7])
            }
        }
    }
    private func garden(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            p.paving(at: .zero, width: 105)
            p.planter(at: CGPoint(x: -9, y: -5), size: 0.97, palm: variation % 3 == 0)
            if variation % 3 == 1 { p.lamp(at: CGPoint(x: 24, y: 8), size: 0.84, banner: true) }
            else { p.bench(at: CGPoint(x: 23, y: 16), size: 0.65) }
            p.flowers(at: CGPoint(x: -33, y: 17), size: 0.73)
        }
    }
    func scene(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size, radius: 74 * size, rise: 135 * size) { p in
            p.paving(at: CGPoint(x: variation % 4 == 0 ? -18 : 0, y: 12), width: 163)
            switch variation % 4 {
            case 0:
                p.palm(at: CGPoint(x: 43, y: -12), size: 0.86)
                p.station(at: CGPoint(x: -26, y: 0), size: 1)
                p.planter(at: CGPoint(x: -60, y: 21), size: 0.58)
            case 1:
                p.building(at: CGPoint(x: -23, y: -12), size: 0.91, tower: false, cafe: true)
                p.building(at: CGPoint(x: 34, y: 0), size: 0.70, tower: false)
                p.bench(at: CGPoint(x: 6, y: 24), size: 0.76)
            case 2:
                p.palm(at: CGPoint(x: 40, y: 2), size: 0.88)
                p.building(at: CGPoint(x: -10, y: 0), size: 0.87, tower: true)
                p.fountain(at: CGPoint(x: 30, y: 24), size: 0.56)
            default:
                p.planter(at: CGPoint(x: -31, y: -3), size: 0.85, palm: true)
                p.rounded(CGRect(x: -2, y: -93, width: 5, height: 96), radius: 2, colors: [0xB3CDB2, 0x5E9B9D])
                p.digital(at: CGPoint(x: 0, y: -95), size: 0.88, time: "12:45")
                p.fountain(at: CGPoint(x: 2, y: 16), size: 0.9)
                p.lamp(at: CGPoint(x: 52, y: 15), size: 0.76, banner: true)
            }
            p.planter(at: CGPoint(x: 51, y: 27), size: 0.54)
            p.flowers(at: CGPoint(x: -40, y: 27), size: 0.66)
        }
    }
}

/// The forest changes from sunlit greens to moonlit blues along world seven.
private struct DayNightForestPainter {
    let context: GraphicsContext
    var scenery: WorldSceneryLayout? = nil
    var depth: WorldSceneryDepth? = nil
    var depthOffset: CGFloat = 0
    var night: Double = 0

    private func at(_ point: CGPoint, size: CGFloat = 1, mirror: Bool = false, radius: CGFloat = 0, rise: CGFloat = 0, draw: @escaping (DayNightForestPainter) -> Void) {
        let point = scenery?.position(point, radius: radius, rise: rise) ?? point
        var c = context; c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: mirror ? -size : size, y: size)
        if let depth {
            depth.add(at: depthOffset + point.y) { draw(.init(context: c, night: night)) }
        } else { draw(.init(context: c, night: night)) }
    }
    private func tone(_ day: UInt32, _ moonlight: UInt32) -> UInt32 {
        let amount = min(1, max(0, night))
        func channel(_ shift: UInt32) -> UInt32 {
            UInt32((Double((day >> shift) & 255) * (1 - amount) + Double((moonlight >> shift) & 255) * amount).rounded()) << shift
        }
        return channel(16) | channel(8) | channel(0)
    }
    private func darkness(at y: CGFloat) -> Double {
        let value = min(1, max(0, Double((y - 340) / 1100)))
        return value * value * (3 - 2 * value)
    }
    private func material(_ path: Path, colors: [UInt32]) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
    }
    private func polygon(_ points: [CGPoint], colors: [UInt32]) {
        var p = Path(); p.addLines(points); p.closeSubpath(); material(p, colors: colors)
    }
    private func rounded(_ r: CGRect, radius: CGFloat, colors: [UInt32]) {
        material(Path(roundedRect: r, cornerRadius: radius), colors: colors)
    }
    private func oval(_ r: CGRect, colors: [UInt32]) {
        context.fill(Path(ellipseIn: r), with: .radialGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                            center: CGPoint(x: r.minX + r.width * 0.3, y: r.minY + r.height * 0.2),
                                                            startRadius: 0, endRadius: max(r.width, r.height) * 0.85))
    }
    private func line(_ points: [CGPoint], color: UInt32, width: CGFloat, opacity: Double = 1) {
        var p = Path(); p.addLines(points)
        context.stroke(p, with: .color(Color(dinoHex: color).opacity(opacity)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func glow(_ point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), Color(dinoHex: color).opacity(0)]),
                                           center: point, startRadius: 0, endRadius: radius))
    }

    func landscape(in size: CGSize, routeOffset: CGFloat, depth: WorldSceneryDepth) {
        let w = size.width, h = size.height
        let scale = min(1.30, max(0.82, w / 390))
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: 0xD4DDC4), location: 0),
            .init(color: Color(dinoHex: 0x9FD5DF), location: 0.035),
            .init(color: Color(dinoHex: 0xE7E9BE), location: (routeOffset + 130) / h),
            .init(color: Color(dinoHex: 0xD2DDB0), location: (routeOffset + 520) / h),
            .init(color: Color(dinoHex: 0xC5B7B0), location: (routeOffset + 820) / h),
            .init(color: Color(dinoHex: 0x9AA9BE), location: (routeOffset + 1080) / h),
            .init(color: Color(dinoHex: 0x7F95B0), location: (routeOffset + 1470) / h),
            .init(color: Color(dinoHex: 0xE8E9DA), location: 1)
        ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
        entrance(width: w, scale: scale)
        var c = context; c.translateBy(x: 0, y: routeOffset)
        let scenery = WorldSceneryLayout(width: w, height: h, routeOffset: routeOffset)
        scenery.drawBanks(in: c, worldID: 7)
        let p = DayNightForestPainter(context: c, scenery: scenery, depth: depth, depthOffset: routeOffset)
        p.twilight(width: w, scale: scale)
        for side in 0..<2 {
            for i in 0..<13 {
                let y = 35 + CGFloat(i) * 134
                p.at(CGPoint(x: side == 0 ? 0 : w, y: y), size: scale, mirror: side == 1) { bank in
                    bank.at(CGPoint(x: 19 + CGFloat(i % 3) * 10, y: 0)) { local in
                        let garden = DayNightForestPainter(context: local.context, night: p.darkness(at: y))
                        garden.rock(at: .zero, size: 0.65)
                        garden.plants(at: CGPoint(x: 20, y: 12), size: 0.65)
                        if i % 3 == 0 { garden.mushroom(at: CGPoint(x: 8, y: -2), size: 0.58) }
                    }
                }
            }
        }
        // Water, crossings and scattered plants sit behind the clock clearings.
        DayNightForestPainter(context: c, scenery: scenery, depth: depth, depthOffset: routeOffset, night: p.darkness(at: 760)).cascade(at: CGPoint(x: -2, y: 760), size: scale)
        DayNightForestPainter(context: c, scenery: scenery, depth: depth, depthOffset: routeOffset, night: p.darkness(at: 1125)).cascade(at: CGPoint(x: w + 2, y: 1125), size: scale, mirror: true)
        DayNightForestPainter(context: c, scenery: scenery, depth: depth, depthOffset: routeOffset, night: p.darkness(at: 900)).bridge(at: CGPoint(x: 10 * scale, y: 900), size: scale * 0.86)
        DayNightForestPainter(context: c, scenery: scenery, depth: depth, depthOffset: routeOffset, night: p.darkness(at: 1250)).bridge(at: CGPoint(x: w - 10 * scale, y: 1250), size: scale * 0.83)
        for index in 0..<9 {
            let onRight = index % 4 == 0 || index % 4 == 3
            let y = 185 + CGFloat(index) * 175
            let forest = DayNightForestPainter(context: c, scenery: scenery, depth: depth, depthOffset: routeOffset, night: p.darkness(at: y))
            // The last clock clearing sits beside the owl, with its whole display exposed.
            let sceneX = index == 8 ? w - 130 * scale : onRight ? w - 35 * scale : 35 * scale
            forest.scene(at: CGPoint(x: sceneX, y: index == 8 ? y - 15 : y), size: scale * 0.95, variation: index)
            forest.garden(at: CGPoint(x: onRight ? 4 * scale : w - 4 * scale, y: y + 88), size: scale, variation: index)
        }
        let lunar = DayNightForestPainter(context: c, scenery: scenery, depth: depth, depthOffset: routeOffset, night: 1)
        lunar.moon(at: CGPoint(x: w - 70 * scale, y: 1050), size: scale * 0.85)
        for i in 0..<28 {
            let side = i % 2 == 0
            let x = side ? CGFloat(22 + (i * 19) % 66) * scale : w - CGFloat(22 + (i * 17) % 66) * scale
            let y = 990 + CGFloat(i) * 23
            lunar.glow(CGPoint(x: x, y: y), radius: 11, color: 0xFFF0AD, opacity: 0.2)
            lunar.oval(CGRect(x: x, y: y, width: i % 3 == 0 ? 2.4 : 1.3, height: i % 3 == 0 ? 2.4 : 1.3), colors: [0xFFFFCF, 0xE9DA91])
        }
    }

    private func entrance(width: CGFloat, scale: CGFloat) {
        let sun = CGPoint(x: width * 0.40, y: 66 * scale)
        glow(sun, radius: 140 * scale, color: 0xFFF0B4, opacity: 0.78)
        oval(CGRect(x: sun.x - 24, y: sun.y - 24, width: 48, height: 48), colors: [0xFFFFD8, 0xFFE6A4])
        for i in 0..<3 {
            at(CGPoint(x: width * (0.1 + CGFloat(i) * 0.39), y: (34 + CGFloat(i % 2) * 41) * scale), size: scale * 0.75) { p in
                var cloud = Path()
                for r in [CGRect(x: -56, y: 0, width: 117, height: 20), CGRect(x: -32, y: -18, width: 48, height: 35), CGRect(x: 4, y: -26, width: 51, height: 43)] { cloud.addEllipse(in: r) }
                p.context.drawLayer { c in
                    c.addFilter(.blur(radius: 1.8))
                    c.fill(cloud, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFFFE7).opacity(0.92), Color(dinoHex: 0xE4EDCF).opacity(0)]),
                                                       startPoint: CGPoint(x: 0, y: -26), endPoint: CGPoint(x: 0, y: 21)))
                }
            }
        }
        var far = context; far.opacity = 0.5
        far.clipToLayer { mask in
            mask.fill(Path(CGRect(x: 0, y: 0, width: width, height: 330 * scale)),
                      with: .linearGradient(Gradient(stops: [.init(color: .white, location: 0), .init(color: .white, location: 0.35), .init(color: .white.opacity(0), location: 1)]),
                                            startPoint: CGPoint(x: 0, y: 125 * scale), endPoint: CGPoint(x: 0, y: 255 * scale)))
        }
        let distant = DayNightForestPainter(context: far)
        for i in 0..<5 {
            distant.at(CGPoint(x: CGFloat(i) * width / 4, y: (180 + CGFloat(i % 2) * 12) * scale), size: scale) { p in
                p.cliff(at: .zero, size: 1.7)
                for j in 0..<3 { p.canopy(at: CGPoint(x: CGFloat(j - 1) * 21, y: -121 - CGFloat(j % 2) * 9), size: 0.44) }
                if i == 1 || i == 3 { p.cascade(at: CGPoint(x: 18, y: -52), size: 0.80) }
            }
        }
        tree(at: CGPoint(x: -4, y: 294 * scale), size: scale * 1.14, lantern: false)
        tree(at: CGPoint(x: width + 12, y: 315 * scale), size: scale * 1.22, lantern: false)
    }
    private func twilight(width: CGFloat, scale: CGFloat) {
        let sunset = CGPoint(x: width * 0.43, y: 852)
        glow(sunset, radius: width * 0.56, color: 0xFFD4A8, opacity: 0.3)
        glow(CGPoint(x: width * 0.65, y: 970), radius: width * 0.48, color: 0xC6C9EB, opacity: 0.2)
        var far = context; far.opacity = 0.18
        far.clipToLayer { mask in
            mask.fill(Path(CGRect(x: 0, y: 780, width: width, height: 300)),
                      with: .linearGradient(Gradient(stops: [.init(color: .white, location: 0), .init(color: .white, location: 0.3), .init(color: .white.opacity(0), location: 1)]), startPoint: .init(x: 0, y: 790), endPoint: .init(x: 0, y: 1000)))
        }
        let forest = DayNightForestPainter(context: far, night: 0.65)
        for i in 0..<8 {
            forest.tree(at: CGPoint(x: CGFloat(i) * width / 7, y: 970 + CGFloat(i % 3) * 15), size: scale * 0.62, lantern: false)
        }
    }
    private func rock(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.polygon([.init(x: -28, y: 5), .init(x: -23, y: -23), .init(x: -6, y: -40), .init(x: 16, y: -32), .init(x: 31, y: -10), .init(x: 29, y: 8), .init(x: 6, y: 14)], colors: [p.tone(0xC7C7AF, 0xA0AAC1), p.tone(0x94A397, 0x7188A8), p.tone(0x788C86, 0x536D91)])
            p.polygon([.init(x: -23, y: -23), .init(x: -6, y: -40), .init(x: 16, y: -32), .init(x: 0, y: -14)], colors: [p.tone(0xE3DABB, 0xBDC3CF), p.tone(0xB2C0A7, 0x8B9EB8)])
            p.line([.init(x: 0, y: -14), .init(x: 6, y: 10)], color: p.tone(0x6F8882, 0x465E85), width: 0.9, opacity: 0.7)
            p.plants(at: CGPoint(x: -15, y: 8), size: 0.34)
        }
    }
    private func cliff(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.polygon([.init(x: -42, y: 8), .init(x: -33, y: -59), .init(x: -18, y: -76), .init(x: 18, y: -75), .init(x: 38, y: -46), .init(x: 47, y: 8)], colors: [p.tone(0xB6B9A4, 0x98A5BD), p.tone(0x899C95, 0x758DA9), p.tone(0x718F91, 0x536E95)])
            p.polygon([.init(x: -18, y: -76), .init(x: 1, y: -68), .init(x: -11, y: -15), .init(x: -16, y: 7), .init(x: -37, y: 8)], colors: [p.tone(0xDDD2AF, 0xB0B5C6), p.tone(0xA4B3A0, 0x8294AF)])
            p.oval(CGRect(x: -31, y: -82, width: 61, height: 16), colors: [p.tone(0xBAD58E, 0x8BAAB5), p.tone(0x78AB79, 0x527E9C)])
        }
    }
    private func leaf(at point: CGPoint, length: CGFloat, angle: Double) {
        at(point) { p in
            var c = p.context; c.rotate(by: .degrees(angle))
            let l = DayNightForestPainter(context: c, night: p.night)
            let path = Path { a in
                a.move(to: .zero)
                a.addCurve(to: .init(x: 0, y: -length), control1: .init(x: -length * 0.39, y: -length * 0.20), control2: .init(x: -length * 0.27, y: -length * 0.82))
                a.addCurve(to: .zero, control1: .init(x: length * 0.27, y: -length * 0.85), control2: .init(x: length * 0.39, y: -length * 0.25))
            }
            l.material(path, colors: [l.tone(0xC0D97A, 0x9FBED1), l.tone(0x77AD70, 0x5B91AA), l.tone(0x428564, 0x38698D)])
            l.line([.zero, .init(x: 0, y: -length * 0.88)], color: l.tone(0xE0ECA2, 0xBDD5DC), width: 0.8, opacity: 0.7)
            for i in 1...3 { l.line([.init(x: 0, y: -length * CGFloat(i) * 0.21), .init(x: length * 0.13, y: -length * CGFloat(i) * 0.21 - 5)], color: l.tone(0xCAE294, 0xB6CDDC), width: 0.6, opacity: 0.45) }
        }
    }
    private func plants(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for i in 0..<5 { p.leaf(at: .zero, length: 25 + CGFloat(i % 2) * 9, angle: Double(i - 2) * 32) }
        }
    }
    private func flowers(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for i in 0..<3 {
                let x = CGFloat(i - 1) * 10, y = -6 - CGFloat(i % 2) * 8
                p.line([.init(x: x, y: 4), .init(x: x, y: y)], color: p.tone(0x6DA175, 0x6791AC), width: 1.3)
                for j in 0..<5 {
                    let a = Double(j) * .pi * 0.4
                    p.oval(CGRect(x: x + CGFloat(cos(a)) * 3.6 - 2.8, y: y + CGFloat(sin(a)) * 3.6 - 2.8, width: 5.6, height: 5.6), colors: [p.tone(0xFFF8DB, 0xE3DDF1), p.tone(0xE8DCAE, 0xA99CCB)])
                }
                p.oval(CGRect(x: x - 1.6, y: y - 1.6, width: 3.2, height: 3.2), colors: [0xFFF0AB, 0xDDBD7D])
            }
        }
    }

    private func canopy(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for (x, y, s): (CGFloat, CGFloat, CGFloat) in [(-33,0,0.85),(28,-6,0.94),(-4,-22,1.0),(0,8,1.04)] {
                p.oval(CGRect(x: x - 31 * s, y: y - 25 * s, width: 62 * s, height: 53 * s), colors: [p.tone(0xBED575, 0x90ADC1), p.tone(0x7FAE69, 0x5487A6), p.tone(0x427E5E, 0x365F85)])
            }
            for i in 0..<25 {
                let x = CGFloat((i * 19) % 100) - 48, y = CGFloat((i * 13) % 54) - 22
                p.leaf(at: CGPoint(x: x, y: y), length: 17 + CGFloat(i % 3) * 4, angle: Double(i % 7 - 3) * 23)
            }
        }
    }
    private func tree(at point: CGPoint, size: CGFloat, lantern: Bool) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -48, y: -6, width: 100, height: 24), colors: [p.tone(0xA2BA88, 0x738DA8), p.tone(0xC6D4A4, 0x8B9FB7)])
            let trunk = Path { t in
                t.addLines([.init(x: -21, y: 4), .init(x: -11, y: -20), .init(x: -7, y: -83), .init(x: -37, y: -121), .init(x: -31, y: -128),
                            .init(x: -2, y: -101), .init(x: 14, y: -145), .init(x: 23, y: -139), .init(x: 10, y: -93),
                            .init(x: 37, y: -120), .init(x: 43, y: -114), .init(x: 12, y: -76), .init(x: 16, y: -20), .init(x: 31, y: 4)])
                t.closeSubpath()
            }
            p.material(trunk, colors: [p.tone(0xD7B677, 0xA8ADB7), p.tone(0xA18D5C, 0x798CA4), p.tone(0x706E4D, 0x506B8C)])
            for i in 0..<4 {
                let x = CGFloat(i) * 6 - 5
                var grain = Path(); grain.move(to: .init(x: x - 8, y: -3))
                grain.addCurve(to: .init(x: x, y: -87), control1: .init(x: x + 5, y: -32), control2: .init(x: x - 5, y: -61))
                p.context.stroke(grain, with: .color(Color(dinoHex: p.tone(0xF0D39B, 0xC2CCD1)).opacity(0.55)), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
            }
            p.oval(CGRect(x: -3, y: -65, width: 9, height: 16), colors: [p.tone(0x8B7A50, 0x617790), p.tone(0xB39C65, 0x8197AA)])
            p.oval(CGRect(x: -1, y: -62, width: 5, height: 10), colors: [p.tone(0xCCAD73, 0x9FAFBD), p.tone(0x8B7A50, 0x617790)])
            p.canopy(at: CGPoint(x: -3, y: -139), size: 1.04)
            p.plants(at: CGPoint(x: -21, y: 7), size: 0.72)
            if lantern {
                p.line([.init(x: -10, y: -105), .init(x: -27, y: -99), .init(x: -27, y: -75)], color: p.tone(0x6F7553, 0x56718E), width: 2)
                p.lantern(at: CGPoint(x: -27, y: -33), size: 0.87)
                if p.night > 0.45 {
                    for i in 0..<3 {
                        let x = 18 + CGFloat(i) * 13, y = -92 + CGFloat(i % 2) * 16
                        p.line([.init(x: x, y: -123), .init(x: x, y: y - 5)], color: 0xB7C6D1, width: 0.7, opacity: 0.65)
                        p.star(at: CGPoint(x: x, y: y), radius: 4.2)
                    }
                }
            }
        }
    }
    private func mushroom(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.glow(CGPoint(x: 0, y: -18), radius: 32, color: 0xFFF0BA, opacity: 0.08 + p.night * 0.32)
            p.rounded(CGRect(x: -5, y: -34, width: 11, height: 36), radius: 4, colors: [p.tone(0xFFF1C5, 0xE9F3DE), p.tone(0xD7C496, 0xB0CBD2)])
            p.oval(CGRect(x: -26, y: -35, width: 52, height: 13), colors: [p.tone(0xF2D4A0, 0xD9D6E1), p.tone(0xC39B7B, 0x9AA8CA)])
            let cap = Path { c in
                c.move(to: .init(x: -28, y: -32)); c.addCurve(to: .init(x: 28, y: -32), control1: .init(x: -17, y: -70), control2: .init(x: 17, y: -70))
                c.addQuadCurve(to: .init(x: -28, y: -32), control: .init(x: 0, y: -23)); c.closeSubpath()
            }
            p.material(cap, colors: [p.tone(0xF2BF92, 0xD2C4EC), p.tone(0xD59F86, 0xA396CD), p.tone(0xB48479, 0x777FAF)])
            for (x, y, r): (CGFloat, CGFloat, CGFloat) in [(-15,-40,3.5),(8,-47,4),(17,-36,3),(-3,-54,3),(-3,-36,2.5)] {
                p.oval(CGRect(x: x - r, y: y - r * 0.7, width: r * 2, height: r * 1.4), colors: [0xFFF5D2, p.tone(0xF0D7AC, 0xDDDDE5)])
            }
            p.plants(at: CGPoint(x: 12, y: 4), size: 0.36)
        }
    }
    private func log(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -44, y: -39, width: 94, height: 43), radius: 15, colors: [p.tone(0xB69B65, 0x93A2AF), p.tone(0x897B50, 0x617B96), p.tone(0x6B6B48, 0x486486)])
            for i in 0..<5 {
                let y = -32 + CGFloat(i) * 8
                p.line([.init(x: -18, y: y), .init(x: 1, y: y + 2), .init(x: 18, y: y - 1), .init(x: 39, y: y)], color: p.tone(0xDAC18A, 0xB1BFCA), width: 1, opacity: 0.6)
            }
            p.oval(CGRect(x: -52, y: -42, width: 36, height: 48), colors: [p.tone(0xE4CC91, 0xBEC9CD), p.tone(0xB09A69, 0x8AA1B1)])
            p.oval(CGRect(x: -47, y: -36, width: 26, height: 36), colors: [p.tone(0x9E8A5E, 0x718BA5), p.tone(0x625F43, 0x3B577C)])
            p.oval(CGRect(x: -43, y: -31, width: 18, height: 26), colors: [p.tone(0x676347, 0x456184), p.tone(0x4F5940, 0x2F4D73)])
            p.plants(at: CGPoint(x: 8, y: -33), size: 0.62)
            p.flowers(at: CGPoint(x: 32, y: -31), size: 0.63)
            p.mushroom(at: CGPoint(x: -34, y: 11), size: 0.47)
        }
    }
    private func lantern(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.glow(CGPoint(x: 0, y: -24), radius: 39, color: 0xFFE4A3, opacity: 0.16 + p.night * 0.36)
            p.rounded(CGRect(x: -9, y: -37, width: 18, height: 28), radius: 3, colors: [p.tone(0xB9A16D, 0xB7B38B), p.tone(0x8A805C, 0x788B96)])
            p.rounded(CGRect(x: -6, y: -33, width: 12, height: 21), radius: 2, colors: [0xFFF6CC, 0xF9DB98, 0xEAB972])
            p.line([.init(x: 0, y: -32), .init(x: 0, y: -12)], color: 0xD3BC83, width: 1)
            p.polygon([.init(x: -12, y: -37), .init(x: 0, y: -45), .init(x: 12, y: -37)], colors: [0xE5CB91, p.tone(0x92845E, 0x8E9C9E)])
            p.rounded(CGRect(x: -12, y: -10, width: 24, height: 4), radius: 1, colors: [0xD8C18D, p.tone(0x998C63, 0x8D9DA4)])
        }
    }
    private func cascade(at point: CGPoint, size: CGFloat, mirror: Bool = false) {
        at(point, size: size, mirror: mirror) { p in
            p.cliff(at: CGPoint(x: -18, y: 6), size: 1.05)
            p.cliff(at: CGPoint(x: 26, y: 11), size: 0.7)
            p.rounded(CGRect(x: -9, y: -56, width: 28, height: 94), radius: 5, colors: [p.tone(0xDEF7E4, 0xD0E8EB), p.tone(0x8FD4D3, 0x89B9D0), p.tone(0x60B5C4, 0x527CA7), p.tone(0xBCE9DA, 0x93BDD0)])
            for i in 0..<4 { p.line([.init(x: CGFloat(i) * 6 - 6, y: -51), .init(x: CGFloat(i) * 6 - 7, y: 27 + CGFloat(i % 2) * 7)], color: p.tone(0xF1FFF0, 0xDBF0F0), width: i % 2 == 0 ? 2 : 1, opacity: 0.85) }
            p.oval(CGRect(x: -32, y: 28, width: 68, height: 20), colors: [p.tone(0xE8FFEC, 0xD6E7E7), p.tone(0x9BDAD5, 0x8FB6CF), p.tone(0x6DBAC4, 0x648EAF)])
            for i in 0..<4 { p.oval(CGRect(x: CGFloat(i) * 13 - 24, y: 33 + CGFloat(i % 2) * 3, width: 15, height: 3), colors: [0xECFFF1, p.tone(0xBFEBDA, 0xADCBD9)]) }
            p.plants(at: CGPoint(x: 30, y: 14), size: 0.7)
        }
    }
    private func bridge(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.polygon([.init(x: -46, y: -13), .init(x: 34, y: -20), .init(x: 46, y: 8), .init(x: -34, y: 18)], colors: [p.tone(0xE7C690, 0xBCC7CA), p.tone(0xB79765, 0x8399AD), p.tone(0x917E56, 0x607F9E)])
            for i in 0..<7 {
                let x = CGFloat(i) * 12 - 36
                p.line([.init(x: x, y: -11), .init(x: x + 10, y: 12)], color: p.tone(0x86764F, 0x4D6F92), width: 1.2)
                p.line([.init(x: x + 3, y: -11), .init(x: x + 12, y: 9)], color: p.tone(0xF6D9A2, 0xCBD7D9), width: 0.8, opacity: 0.7)
            }
            for x: CGFloat in [-39, 35] {
                p.rounded(CGRect(x: x - 3, y: -37, width: 8, height: 42), radius: 2, colors: [p.tone(0xDFBC81, 0xA5B5BE), p.tone(0x937C52, 0x587A9C)])
                p.oval(CGRect(x: x - 5, y: -39, width: 12, height: 5), colors: [0xE6D9B9, p.tone(0xB29C6D, 0x8CA4B5)])
            }
            p.line([.init(x: -36, y: -30), .init(x: 37, y: -37)], color: p.tone(0xC4A16C, 0x9CB1BE), width: 4)
            p.line([.init(x: -36, y: -16), .init(x: 37, y: -23)], color: p.tone(0xD8B982, 0xABC0C7), width: 2)
        }
    }
    private func star(at point: CGPoint, radius: CGFloat) {
        var points: [CGPoint] = []
        for i in 0..<10 {
            let angle = Double(i) * .pi / 5 - .pi / 2
            let r = i % 2 == 0 ? radius : radius * 0.45
            points.append(.init(x: point.x + CGFloat(cos(angle)) * r, y: point.y + CGFloat(sin(angle)) * r))
        }
        glow(point, radius: radius * 3, color: 0xFFE4A2, opacity: 0.25)
        polygon(points, colors: [0xFFF6C8, 0xE8CE8B])
    }
    private func moon(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.glow(.zero, radius: 71, color: 0xFFF0C0, opacity: 0.29)
            let crescent = Path { m in
                m.move(to: .init(x: 9, y: -29))
                m.addCurve(to: .init(x: 18, y: 25), control1: .init(x: -44, y: -33), control2: .init(x: -44, y: 44))
                m.addCurve(to: .init(x: 9, y: -29), control1: .init(x: -5, y: 21), control2: .init(x: -13, y: -18)); m.closeSubpath()
            }
            p.material(crescent, colors: [0xFFF9D3, 0xE6DBAF])
            for (x, y, r): (CGFloat, CGFloat, CGFloat) in [(-31,-38,3.5),(35,-19,3),(34,33,2.5),(-38,19,2.3)] { p.star(at: .init(x: x, y: y), radius: r) }
        }
    }
    private func clockClearing(at point: CGPoint, size: CGFloat, hour: Int) {
        at(point, size: size) { p in
            p.rock(at: CGPoint(x: 1, y: 5), size: 1.55)
            p.rounded(CGRect(x: -17, y: -54, width: 34, height: 33), radius: 5, colors: [p.tone(0xB39B66, 0x9EACB4), p.tone(0x827C55, 0x647E9D)])
            let center = CGPoint(x: 0, y: -77), radius: CGFloat = 29
            p.oval(CGRect(x: -33, y: -108, width: 66, height: 66), colors: [0xF4DCA0, p.tone(0xBB9B63, 0xB7B29A), p.tone(0x8A7C55, 0x778F9F)])
            p.oval(CGRect(x: -29, y: -106, width: 58, height: 58), colors: [0xFFFFE3, 0xF0ECCF, 0xD7DFC7])
            for i in 0..<60 {
                let a = Double(i) * .pi / 30
                let inner = radius * (i % 5 == 0 ? 0.80 : 0.88)
                p.line([.init(x: center.x + CGFloat(sin(a)) * inner, y: center.y - CGFloat(cos(a)) * inner),
                        .init(x: center.x + CGFloat(sin(a)) * radius * 0.94, y: center.y - CGFloat(cos(a)) * radius * 0.94)], color: 0x5B7282, width: i % 5 == 0 ? 1.3 : 0.6, opacity: i % 5 == 0 ? 0.95 : 0.5)
            }
            let time = ClockTime(hour: hour, minute: 0)
            for (angle, length, width) in [(time.hourAngle, CGFloat(14), CGFloat(3)), (time.minuteAngle, CGFloat(21), CGFloat(2))] {
                let a = angle * .pi / 180
                p.line([center, .init(x: center.x + CGFloat(sin(a)) * length, y: center.y - CGFloat(cos(a)) * length)], color: 0x47627A, width: width)
            }
            p.oval(CGRect(x: -2.3, y: -79.3, width: 4.6, height: 4.6), colors: [0x718897, 0x3F5F79])
            p.rounded(CGRect(x: -31, y: -31, width: 68, height: 30), radius: 7, colors: [p.tone(0xD9BD83, 0xBAC3B5), p.tone(0xA58F62, 0x859EAE)])
            p.rounded(CGRect(x: -26, y: -26, width: 58, height: 20), radius: 4, colors: [0x3E5B65, 0x2A4359])
            p.context.draw(Text(verbatim: String(format: "%02d:00", hour)).font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(dinoHex: 0xFFE9AE)), at: CGPoint(x: 3, y: -16))
            p.flowers(at: CGPoint(x: 34, y: 15), size: 0.65)
            p.mushroom(at: CGPoint(x: -38, y: 13), size: 0.42)
        }
    }
    private func garden(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -50, y: -11, width: 103, height: 36), colors: [p.tone(0xC1D3A0, 0x8FA4BA), p.tone(0xA3BD8C, 0x738DA9)])
            if variation % 3 == 0 { p.tree(at: CGPoint(x: -3, y: 2), size: 0.88, lantern: variation > 2) }
            else {
                p.rock(at: CGPoint(x: 10, y: 6), size: 0.85)
                p.plants(at: CGPoint(x: -19, y: 10), size: 1.0)
                p.mushroom(at: CGPoint(x: 31, y: 13), size: 0.70)
            }
            p.flowers(at: CGPoint(x: -26, y: 17), size: 0.76)
        }
    }
    func scene(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size, radius: 74 * size, rise: 135 * size) { p in
            p.oval(CGRect(x: -75, y: -16, width: 153, height: 46), colors: [p.tone(0xC7D7A8, 0x99ADC0), p.tone(0xA5BC8B, 0x778FAB)])
            p.tree(at: CGPoint(x: 21, y: -7), size: 0.99, lantern: variation > 2 && variation % 4 != 0)
            switch variation % 4 {
            case 0:
                p.clockClearing(at: CGPoint(x: -17, y: 16), size: 0.88, hour: variation < 3 ? 15 : variation < 7 ? 18 : 20)
                p.log(at: CGPoint(x: 39, y: 25), size: 0.49)
                if p.night > 0.2 { p.lantern(at: CGPoint(x: -51, y: 27), size: 0.66) }
            case 1:
                p.log(at: CGPoint(x: -9, y: 14), size: 1.02)
                p.mushroom(at: CGPoint(x: 37, y: 25), size: 0.84)
            case 2:
                p.rock(at: CGPoint(x: -14, y: 14), size: 1.10)
                p.mushroom(at: CGPoint(x: -28, y: 20), size: 0.97)
                p.mushroom(at: CGPoint(x: 8, y: 26), size: 0.63)
                p.lantern(at: CGPoint(x: 40, y: 17), size: 0.70)
            default:
                p.cascade(at: CGPoint(x: -8, y: 21), size: 0.80)
                p.mushroom(at: CGPoint(x: 32, y: 31), size: 0.69)
            }
            p.plants(at: CGPoint(x: -46, y: 24), size: 0.63)
            p.flowers(at: CGPoint(x: 44, y: 30), size: 0.63)
        }
    }
}

/// Brass terraces, glass energy tubes and clockwork belong only to the time machine.
private struct TimeMachinePainter {
    let context: GraphicsContext
    var scenery: WorldSceneryLayout? = nil
    var depth: WorldSceneryDepth? = nil
    var depthOffset: CGFloat = 0

    private func at(_ point: CGPoint, size: CGFloat = 1, mirror: Bool = false, radius: CGFloat = 0, rise: CGFloat = 0, draw: @escaping (TimeMachinePainter) -> Void) {
        let point = scenery?.position(point, radius: radius, rise: rise) ?? point
        var c = context; c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: mirror ? -size : size, y: size)
        if let depth {
            depth.add(at: depthOffset + point.y) { draw(.init(context: c)) }
        } else { draw(.init(context: c)) }
    }
    private func material(_ path: Path, _ colors: [UInt32]) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                startPoint: .init(x: r.minX, y: r.minY), endPoint: .init(x: r.maxX, y: r.maxY)))
    }
    private func rounded(_ r: CGRect, _ radius: CGFloat, _ colors: [UInt32]) {
        material(Path(roundedRect: r, cornerRadius: radius), colors)
    }
    private func polygon(_ points: [CGPoint], _ colors: [UInt32]) {
        var p = Path(); p.addLines(points); p.closeSubpath(); material(p, colors)
    }
    private func oval(_ r: CGRect, _ colors: [UInt32]) {
        context.fill(Path(ellipseIn: r), with: .radialGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                            center: .init(x: r.minX + r.width * 0.32, y: r.minY + r.height * 0.2),
                                                            startRadius: 0, endRadius: max(r.width, r.height)))
    }
    private func line(_ points: [CGPoint], _ color: UInt32, _ width: CGFloat, opacity: Double = 1) {
        var p = Path(); p.addLines(points)
        context.stroke(p, with: .color(Color(dinoHex: color).opacity(opacity)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func glow(_ point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), Color(dinoHex: color).opacity(0)]),
                                           center: point, startRadius: 0, endRadius: radius))
    }
    private func rivet(_ point: CGPoint, radius: CGFloat = 2) {
        oval(CGRect(x: point.x - radius, y: point.y - radius + 1, width: radius * 2, height: radius * 2), [0x856744, 0x625C54])
        oval(CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2), [0xFFF0BE, 0xD3AA60, 0xA27D49])
        line([.init(x: point.x - radius * 0.4, y: point.y), .init(x: point.x + radius * 0.4, y: point.y)], 0x8A794E, 0.6)
    }

    func landscape(in size: CGSize, routeOffset: CGFloat, depth: WorldSceneryDepth) {
        let w = size.width, h = size.height
        let scale = min(1.30, max(0.82, w / 390))
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: 0xE8E9DA), location: 0),
            .init(color: Color(dinoHex: 0xA7D9E9), location: 0.035),
            .init(color: Color(dinoHex: 0xD7E8E2), location: (routeOffset + 40) / h),
            .init(color: Color(dinoHex: 0xF3E5BF), location: (routeOffset + 480) / h),
            .init(color: Color(dinoHex: 0xD9DDD5), location: (routeOffset + 1100) / h),
            .init(color: Color(dinoHex: 0xE8DBC0), location: (routeOffset + 1620) / h),
            .init(color: Color(dinoHex: 0xF5D698), location: 1)
        ]), startPoint: .zero, endPoint: .init(x: 0, y: h)))
        entrance(width: w, scale: scale)
        var c = context; c.translateBy(x: 0, y: routeOffset)
        let scenery = WorldSceneryLayout(width: w, height: h, routeOffset: routeOffset)
        scenery.drawBanks(in: c, worldID: 8)
        let p = TimeMachinePainter(context: c, scenery: scenery, depth: depth, depthOffset: routeOffset)
        // Glass channels and masonry sit behind the individual workshop terraces.
        for side in 0..<2 {
            for i in 0..<11 {
                let y = CGFloat(i) * 158
                p.at(CGPoint(x: side == 0 ? 0 : w, y: y), size: scale, mirror: side == 1) { local in
                    local.rounded(CGRect(x: -25, y: -21, width: 65, height: 103), 13, [0xB7BFBC, 0x7E9299, 0x607983])
                    for row in 0..<3 {
                        let rowY = CGFloat(row) * 26 - 12
                        local.line([.init(x: -16, y: rowY), .init(x: 35, y: rowY - 3)], 0xDEE1CC, 1.3, opacity: 0.65)
                        local.line([.init(x: CGFloat(row % 2) * 21, y: rowY), .init(x: CGFloat(row % 2) * 21, y: rowY + 22)], 0x4B707C, 1, opacity: 0.6)
                    }
                    local.tube(at: CGPoint(x: 28, y: 46), size: 0.63)
                    local.plants(at: CGPoint(x: 6, y: -12), size: 0.68, flowers: i % 3 == 1)
                    if i % 3 == 0 { local.gear(at: CGPoint(x: 7, y: 62), radius: 24, phase: Double(i) * 0.2) }
                }
            }
        }
        p.conduit(at: CGPoint(x: 15 * scale, y: 640), size: scale, mirror: false)
        p.conduit(at: CGPoint(x: w - 15 * scale, y: 1190), size: scale, mirror: true)
        p.bridge(at: CGPoint(x: 30 * scale, y: 950), size: scale * 0.83)
        for index in 0..<9 {
            let onRight = index % 4 == 0 || index % 4 == 3
            let x = index == 8 ? w - 128 * scale : onRight ? w - 61 * scale : 61 * scale
            let y = 185 + CGFloat(index) * 175
            p.scene(at: CGPoint(x: x, y: index == 8 ? y - 15 : y), size: scale * 0.94, variation: index)
            p.at(CGPoint(x: onRight ? 8 * scale : w - 8 * scale, y: y + 73), size: scale) { garden in
                garden.terrace(width: 77)
                garden.plants(at: CGPoint(x: 0, y: -5), size: 0.95, flowers: true)
                if index % 2 == 0 { garden.lamp(at: CGPoint(x: onRight ? 22 : -22, y: 1), size: 0.69) }
            }
        }
        for i in 0..<32 {
            let x = i % 2 == 0 ? CGFloat(28 + (i * 17) % 56) * scale : w - CGFloat(28 + (i * 13) % 56) * scale
            let y = 66 + CGFloat(i) * 50
            p.glow(.init(x: x, y: y), radius: 8, color: 0xBCFFFF, opacity: 0.22)
            p.oval(CGRect(x: x, y: y, width: 1.7, height: 1.7), [0xF1FFFF, 0x7DDCE5])
        }
    }

    private func entrance(width: CGFloat, scale: CGFloat) {
        glow(CGPoint(x: width * 0.52, y: 78 * scale), radius: width * 0.55, color: 0xFFF3CB, opacity: 0.68)
        for i in 0..<5 {
            at(CGPoint(x: width * CGFloat(i) / 4, y: CGFloat(33 + (i % 2) * 37) * scale), size: scale) { p in
                p.context.drawLayer { c in
                    c.addFilter(.blur(radius: 2))
                    var cloud = Path()
                    for r in [CGRect(x: -54, y: 0, width: 113, height: 21), CGRect(x: -34, y: -15, width: 47, height: 34), CGRect(x: 0, y: -26, width: 48, height: 43)] { cloud.addEllipse(in: r) }
                    c.fill(cloud, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFFFF2).opacity(0.9), Color(dinoHex: 0xE6F3E7).opacity(0)]), startPoint: .init(x: 0, y: -26), endPoint: .init(x: 0, y: 21)))
                }
            }
        }
        var far = context; far.opacity = 0.53
        far.clipToLayer { mask in
            mask.fill(Path(CGRect(x: 0, y: 0, width: width, height: 320 * scale)),
                      with: .linearGradient(Gradient(stops: [.init(color: .white, location: 0), .init(color: .white, location: 0.5), .init(color: .white.opacity(0), location: 1)]), startPoint: .init(x: 0, y: 20 * scale), endPoint: .init(x: 0, y: 235 * scale)))
        }
        let distant = TimeMachinePainter(context: far)
        for i in 0..<5 {
            distant.at(CGPoint(x: width * CGFloat(i) / 4, y: CGFloat(106 + (i % 2) * 22) * scale), size: scale * 0.65) { p in
                p.polygon([.init(x: -44, y: -4), .init(x: 44, y: -4), .init(x: 24, y: 42), .init(x: 1, y: 69), .init(x: -22, y: 30)], [0xD2CDCA, 0x96ACBA, 0x829AAA])
                p.terrace(width: 96)
                p.rounded(CGRect(x: -16, y: -66, width: 32, height: 62), 5, [0xF2DCAB, 0xABC1BD, 0x849BA8])
                p.polygon([.init(x: -24, y: -66), .init(x: 0, y: -93), .init(x: 24, y: -66)], [0xFFE2A1, 0xBDAC94])
                p.rounded(CGRect(x: -4, y: -57, width: 8, height: 32), 4, [0xEAFFFF, 0x87CCD7])
                p.plants(at: CGPoint(x: -24, y: -3), size: 0.68, flowers: false)
                p.waterfall(at: CGPoint(x: 26, y: 11), size: 0.8)
            }
        }
        // The open arch frames the arrival; the portal remains visible above the title.
        var arch = Path(); arch.move(to: .init(x: 16 * scale, y: 158 * scale))
        arch.addLine(to: .init(x: 16 * scale, y: 96 * scale))
        arch.addCurve(to: .init(x: width - 16 * scale, y: 96 * scale), control1: .init(x: width * 0.16, y: -12 * scale), control2: .init(x: width * 0.84, y: -12 * scale))
        arch.addLine(to: .init(x: width - 16 * scale, y: 158 * scale))
        context.stroke(arch, with: .color(Color(dinoHex: 0x677F8B)), style: StrokeStyle(lineWidth: 32 * scale, lineCap: .round))
        context.stroke(arch, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xF0D496), Color(dinoHex: 0xBE985C), Color(dinoHex: 0x8D8D7C)]), startPoint: .zero, endPoint: .init(x: width, y: 200 * scale)), style: StrokeStyle(lineWidth: 24 * scale, lineCap: .round))
        context.stroke(arch, with: .color(Color(dinoHex: 0xFFF0BF).opacity(0.8)), style: StrokeStyle(lineWidth: 2 * scale))
        portal(at: CGPoint(x: width * 0.29, y: 151 * scale), size: scale * 0.84)
        orrery(at: CGPoint(x: width - 57 * scale, y: 148 * scale), size: scale * 0.74)
        for side in 0..<2 {
            at(CGPoint(x: side == 0 ? 14 * scale : width - 14 * scale, y: 158 * scale), size: scale) { p in
                p.rounded(CGRect(x: -20, y: -19, width: 40, height: 14), 3, [0xFFE0A0, 0xB39360])
                p.rivet(.init(x: -10, y: -12)); p.rivet(.init(x: 10, y: -12))
                p.gear(at: CGPoint(x: 0, y: -65), radius: 23, phase: Double(side) * 0.3)
                p.terrace(width: 75)
                p.plants(at: CGPoint(x: side == 0 ? -4 : 4, y: -7), size: 1.08, flowers: true)
            }
        }
    }
    private func terrace(width: CGFloat) {
        let r = width / 2
        rounded(CGRect(x: -r, y: -8, width: width, height: 32), 12, [0xC4CCBD, 0x8FA2A5, 0x627D87])
        for i in 0..<5 {
            let x = -r + CGFloat(i) * width / 5
            line([.init(x: x, y: 7), .init(x: x + 2, y: 20)], 0x5C7A83, 1, opacity: 0.7)
        }
        oval(CGRect(x: -r, y: -15, width: width, height: 31), [0xFFF0BF, 0xDFBF7E, 0xA98D61])
        context.stroke(Path(ellipseIn: CGRect(x: -r + 3, y: -12, width: width - 6, height: 25)), with: .color(Color(dinoHex: 0xFFF5CE).opacity(0.7)), lineWidth: 1.2)
        for x in [-r * 0.65, CGFloat(0), r * 0.65] { rivet(.init(x: x, y: 18), radius: 1.8) }
    }
    private func gear(at point: CGPoint, radius: CGFloat, phase: Double = 0) {
        at(point) { p in
            var points: [CGPoint] = []
            for i in 0..<48 {
                let a = Double(i) * .pi / 24 + phase
                let r = radius * (i % 4 == 1 || i % 4 == 2 ? 1 : 0.84)
                points.append(.init(x: CGFloat(cos(a)) * r, y: CGFloat(sin(a)) * r))
            }
            var shadow = p.context; shadow.translateBy(x: 1, y: 3)
            TimeMachinePainter(context: shadow).polygon(points, [0x947D55, 0x6E6C57])
            p.polygon(points, [0xFFE8AD, 0xC8A05F, 0x9D824E])
            p.oval(CGRect(x: -radius * 0.7, y: -radius * 0.7, width: radius * 1.4, height: radius * 1.4), [0xF6D896, 0xA9915A])
            p.oval(CGRect(x: -radius * 0.53, y: -radius * 0.53, width: radius * 1.06, height: radius * 1.06), [0x687F81, 0x465F6C])
            for i in 0..<4 {
                let a = Double(i) * .pi / 2 + phase
                p.line([.zero, .init(x: CGFloat(cos(a)) * radius * 0.57, y: CGFloat(sin(a)) * radius * 0.57)], 0xC5A467, radius * 0.16)
            }
            p.oval(CGRect(x: -radius * 0.23, y: -radius * 0.23, width: radius * 0.46, height: radius * 0.46), [0xFFE5A5, 0xA98851])
            p.rivet(.zero, radius: radius * 0.10)
        }
    }
    private func tube(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.glow(CGPoint(x: 0, y: -30), radius: 48, color: 0x8BF6FA, opacity: 0.24)
            p.rounded(CGRect(x: -14, y: -78, width: 28, height: 82), 10, [0xD4FFFF, 0x58C3D4, 0x3D90AB, 0xAEF4EF])
            p.rounded(CGRect(x: -9, y: -71, width: 18, height: 66), 7, [0xB3F7EE, 0x58BFD2, 0x8AE7EA])
            for i in 0..<7 {
                let x = CGFloat((i * 7) % 13) - 6, y = -65 + CGFloat(i) * 9
                p.oval(CGRect(x: x, y: y, width: 2.5, height: 2.5), [0xF5FFFF, 0xBAF5F0])
                if i % 2 == 0 { p.line([.init(x: -6, y: y + 6), .init(x: 6, y: y + 2)], 0xE8FFFF, 0.8, opacity: 0.65) }
            }
            p.line([.init(x: -8, y: -67), .init(x: -8, y: -13)], 0xF4FFFF, 2, opacity: 0.8)
            for y: CGFloat in [-79, -4] {
                p.rounded(CGRect(x: -21, y: y, width: 42, height: 10), 3, [0xFFE6A3, 0xC7A064, 0x8D825E])
                for x: CGFloat in [-14, 0, 14] { p.rivet(.init(x: x, y: y + 5), radius: 1.5) }
            }
        }
    }
    private func conduit(at point: CGPoint, size: CGFloat, mirror: Bool) {
        at(point, size: size, mirror: mirror) { p in
            p.line([.init(x: -24, y: -68), .init(x: 40, y: -68), .init(x: 58, y: -45), .init(x: 58, y: 20)], 0x677D80, 19)
            p.line([.init(x: -24, y: -70), .init(x: 40, y: -70), .init(x: 57, y: -46), .init(x: 57, y: 20)], 0xCEAD6F, 14)
            p.line([.init(x: -24, y: -73), .init(x: 37, y: -73), .init(x: 53, y: -46), .init(x: 53, y: 18)], 0xFFE1A6, 2)
            p.tube(at: CGPoint(x: 58, y: 17), size: 0.63)
            p.waterfall(at: CGPoint(x: 58, y: 24), size: 0.75)
            p.gear(at: CGPoint(x: 4, y: -37), radius: 26, phase: 0.15)
            p.plants(at: CGPoint(x: 18, y: 9), size: 0.71, flowers: false)
        }
    }
    private func waterfall(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            let water = Path { path in
                path.move(to: .init(x: -13, y: 0)); path.addLine(to: .init(x: 13, y: 0))
                path.addCurve(to: .init(x: 19, y: 76), control1: .init(x: 9, y: 26), control2: .init(x: 6, y: 49))
                path.addLine(to: .init(x: -22, y: 76))
                path.addCurve(to: .init(x: -13, y: 0), control1: .init(x: -9, y: 47), control2: .init(x: -20, y: 27)); path.closeSubpath()
            }
            p.context.fill(water, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xD3FFFF), Color(dinoHex: 0x65CEDF), Color(dinoHex: 0xB7E9E6).opacity(0)]), startPoint: .zero, endPoint: .init(x: 0, y: 80)))
            for i in 0..<4 {
                let x = CGFloat(i) * 6 - 10
                p.line([.init(x: x, y: 5), .init(x: x - 1, y: 31), .init(x: x + 3, y: 57)], 0xEEFFFF, i % 2 == 0 ? 1.8 : 0.8, opacity: 0.8)
            }
            p.glow(.init(x: 0, y: 61), radius: 29, color: 0xEEFFFF, opacity: 0.45)
        }
    }
    private func lamp(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -8, y: -9, width: 16, height: 8), 2, [0xF7D897, 0x8E805E])
            p.line([.zero, .init(x: 0, y: -50)], 0x9E8558, 5)
            p.line([.init(x: -1, y: -3), .init(x: -1, y: -47)], 0xF8D794, 1.5)
            p.glow(.init(x: 0, y: -51), radius: 30, color: 0xFFD98B, opacity: 0.35)
            p.oval(CGRect(x: -9, y: -65, width: 18, height: 27), [0xFFFFE0, 0xFFE7A0, 0xDEA658])
            p.line([.init(x: 0, y: -65), .init(x: -4, y: -51), .init(x: 0, y: -39), .init(x: 4, y: -51), .init(x: 0, y: -65)], 0xA58A53, 1)
            p.polygon([.init(x: -11, y: -64), .init(x: 0, y: -72), .init(x: 11, y: -64)], [0xFFE0A1, 0xAF8D53])
            p.rounded(CGRect(x: -9, y: -39, width: 18, height: 4), 1, [0xFFE2A6, 0xA58955])
        }
    }
    private func plants(at point: CGPoint, size: CGFloat, flowers: Bool) {
        at(point, size: size) { p in
            for i in 0..<8 {
                let a = Double(i) * .pi / 4 - .pi / 2
                let end = CGPoint(x: CGFloat(cos(a)) * (i % 2 == 0 ? 26 : 20), y: -14 + CGFloat(sin(a)) * 19)
                var leaf = Path(); leaf.move(to: .init(x: 0, y: 3))
                leaf.addQuadCurve(to: end, control: .init(x: end.x - 14, y: end.y - 10))
                leaf.addQuadCurve(to: .init(x: 0, y: 3), control: .init(x: end.x + 13, y: end.y + 9)); leaf.closeSubpath()
                p.material(leaf, i % 2 == 0 ? [0xC8DF8C, 0x78B78A, 0x3E8276] : [0x9EC986, 0x589B83, 0x336E68])
                p.line([.init(x: 0, y: 3), end], 0xD8E6AA, 0.7, opacity: 0.5)
            }
            if flowers {
                for i in 0..<3 {
                    let x = CGFloat(i) * 12 - 12, y = CGFloat(i % 2) * 8 - 15
                    for j in 0..<5 {
                        let a = Double(j) * .pi * 2 / 5
                        p.oval(CGRect(x: x + CGFloat(cos(a)) * 4 - 3, y: y + CGFloat(sin(a)) * 4 - 4, width: 6, height: 8), [0xF2C7DD, 0xB781B5])
                    }
                    p.oval(CGRect(x: x - 2, y: y - 2, width: 4, height: 4), [0xFFF1B8, 0xDEBD70])
                }
            }
        }
    }
    private func portal(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.glow(.init(x: 0, y: -73), radius: 94, color: 0x7DDFF4, opacity: 0.38)
            p.rounded(CGRect(x: -47, y: -150, width: 94, height: 157), 44, [0xFFE4A5, 0xD1AA68, 0x8F805D])
            p.rounded(CGRect(x: -40, y: -143, width: 80, height: 147), 38, [0xFFF1BD, 0x9BBDB4, 0x8C794E])
            p.rounded(CGRect(x: -34, y: -137, width: 68, height: 138), 33, [0xC1FFFF, 0x5AD0E7, 0x647BCB, 0x9688D4])
            var glass = p.context
            glass.clip(to: Path(roundedRect: CGRect(x: -32, y: -135, width: 64, height: 135), cornerRadius: 31))
            let core = TimeMachinePainter(context: glass)
            core.glow(.init(x: 0, y: -37), radius: 53, color: 0xE4FFFF, opacity: 0.83)
            for i in 0..<6 {
                let inset = CGFloat(i) * 4
                let r = CGRect(x: -29 + inset, y: -119 + CGFloat(i) * 11, width: 58 - inset * 2, height: 110 - CGFloat(i) * 15)
                glass.stroke(Path(ellipseIn: r), with: .color(Color(dinoHex: i % 2 == 0 ? 0xDFFFFF : 0xB9E2FF).opacity(0.76)), lineWidth: i == 0 ? 2 : 1)
            }
            for i in 0..<18 {
                let x = CGFloat((i * 17) % 54) - 27, y = -125 + CGFloat((i * 23) % 119)
                core.oval(CGRect(x: x, y: y, width: 1.5, height: 1.5), [0xFFFFFF, 0xB6FFFF])
            }
            for i in 0..<9 {
                let a = Double(i) * .pi / 8 + .pi
                p.rivet(.init(x: CGFloat(cos(a)) * 41, y: -104 + CGFloat(sin(a)) * 39), radius: 2.5)
            }
            for x: CGFloat in [-42, 42] {
                p.rounded(CGRect(x: x - 3, y: -94, width: 6, height: 38), 3, [0xE6FFFF, 0x4EC6D5])
                p.rivet(.init(x: x, y: -20), radius: 2.4)
            }
            p.gear(at: CGPoint(x: 0, y: -153), radius: 15, phase: 0.2)
            p.rounded(CGRect(x: -49, y: -6, width: 98, height: 12), 4, [0xFFF0BF, 0xCBA870, 0x9C8B66])
            p.rounded(CGRect(x: -55, y: 5, width: 110, height: 9), 3, [0xE5D9AF, 0xA7A793])
        }
    }
    private func clock(at point: CGPoint, radius: CGFloat, time: ClockTime) {
        at(point) { p in
            p.oval(CGRect(x: -radius - 4, y: -radius - 2, width: (radius + 4) * 2, height: (radius + 4) * 2), [0xFBE5A6, 0xC1A066, 0x857856])
            p.oval(CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), [0xFFFFE4, 0xF5E9BE, 0xDFCEA1])
            for i in 0..<60 {
                let a = Double(i) * .pi / 30
                let inner = radius * (i % 5 == 0 ? 0.78 : 0.88)
                p.line([.init(x: CGFloat(sin(a)) * inner, y: -CGFloat(cos(a)) * inner), .init(x: CGFloat(sin(a)) * radius * 0.94, y: -CGFloat(cos(a)) * radius * 0.94)], 0x536E76, i % 5 == 0 ? 1.4 : 0.5, opacity: i % 5 == 0 ? 1 : 0.65)
            }
            for (a, length, width) in [(time.hourAngle, radius * 0.48, CGFloat(3)), (time.minuteAngle, radius * 0.72, CGFloat(1.8))] {
                let angle = a * .pi / 180
                p.line([.zero, .init(x: CGFloat(sin(angle)) * length, y: -CGFloat(cos(angle)) * length)], 0x365967, width)
            }
            p.rivet(.zero, radius: 2.3)
        }
    }
    private func console(at point: CGPoint, size: CGFloat, time: ClockTime) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -42, y: -50, width: 84, height: 65), 10, [0xE6CD94, 0xADA888, 0x6F8586])
            p.rounded(CGRect(x: -35, y: -42, width: 70, height: 26), 6, [0xD9B574, 0xB69961])
            p.rounded(CGRect(x: -31, y: -38, width: 62, height: 18), 4, [0x385868, 0x244555])
            p.glow(.init(x: 0, y: -29), radius: 28, color: 0xFFE9AC, opacity: 0.1)
            p.context.draw(Text(verbatim: String(format: "%02d:%02d", time.hour, time.minute))
                .font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundStyle(Color(dinoHex: 0xFFE6A3)), at: .init(x: 0, y: -29))
            for x: CGFloat in [-24, -8, 8, 24] {
                p.rounded(CGRect(x: x - 4, y: -9, width: 8, height: 5), 2, [0xF6D696, 0x9B8A64])
                p.rivet(.init(x: x, y: 8), radius: 1.5)
            }
            p.clock(at: CGPoint(x: 0, y: -80), radius: 28, time: time)
            p.line([.init(x: -38, y: -24), .init(x: -48, y: -24), .init(x: -48, y: 9)], 0xA48955, 4)
            p.gear(at: CGPoint(x: -46, y: -48), radius: 15, phase: 0.3)
            p.rounded(CGRect(x: -46, y: 15, width: 92, height: 7), 3, [0xEBD6A7, 0x9C9B80])
        }
    }
    private func orrery(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -31, y: -7, width: 62, height: 14), 5, [0xF8DA9C, 0xB89860, 0x7B7F69])
            p.oval(CGRect(x: -37, y: -15, width: 74, height: 20), [0xFFF0B4, 0xCAA66C, 0x85917D])
            p.glow(.init(x: 0, y: -53), radius: 55, color: 0xBDFBFF, opacity: 0.37)
            p.oval(CGRect(x: -24, y: -80, width: 48, height: 51), [0xF0FFFF, 0x90D8F1, 0xA49DDB, 0x6B8BC1])
            for i in 0..<3 {
                var c = p.context; c.translateBy(x: 0, y: -54); c.rotate(by: .degrees(Double(i) * 60 - 30))
                c.stroke(Path(ellipseIn: CGRect(x: -45, y: -19, width: 90, height: 38)), with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFF1B9), Color(dinoHex: 0xCFA75F), Color(dinoHex: 0x947E55)]), startPoint: .init(x: -45, y: -19), endPoint: .init(x: 45, y: 19)), lineWidth: 3)
                TimeMachinePainter(context: c).oval(CGRect(x: 34, y: -14, width: 10, height: 10), [0xFFF0AD, 0xBD9657])
            }
            p.line([.init(x: 0, y: -23), .init(x: 0, y: -9)], 0xC8A261, 7)
            p.clock(at: CGPoint(x: 0, y: -107), radius: 18, time: .init(hour: 9, minute: 10))
        }
    }
    private func workbench(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for x: CGFloat in [-39, 34] { p.rounded(CGRect(x: x, y: -6, width: 8, height: 28), 2, [0xD3BB87, 0x8D8A6D]) }
            p.rounded(CGRect(x: -47, y: -13, width: 94, height: 12), 3, [0xFFE4AB, 0xBA9A66])
            p.rounded(CGRect(x: -40, y: -68, width: 62, height: 49), 4, [0xD7BA7D, 0x9D8D62])
            p.rounded(CGRect(x: -36, y: -64, width: 54, height: 41), 2, [0x526E83, 0x385B71])
            p.context.stroke(Path(ellipseIn: CGRect(x: -29, y: -57, width: 26, height: 26)), with: .color(Color(dinoHex: 0xE2DBC1)), lineWidth: 0.8)
            p.line([.init(x: -16, y: -55), .init(x: -16, y: -43), .init(x: -7, y: -39)], 0xEEE2B9, 1)
            p.line([.init(x: 2, y: -54), .init(x: 12, y: -54), .init(x: 12, y: -39), .init(x: 1, y: -39)], 0x95D6DB, 1)
            p.line([.init(x: -28, y: -27), .init(x: 10, y: -27)], 0xA9D3D4, 0.8)
            p.gear(at: CGPoint(x: 29, y: -29), radius: 17, phase: 0.3)
            for i in 0..<3 {
                p.rounded(CGRect(x: -31 + CGFloat(i % 2) * 3, y: -20 - CGFloat(i) * 5, width: 24, height: 5), 1, i == 1 ? [0xDDCDA4, 0xA89773] : [0xC0A0A5, 0x8E7989])
            }
            p.tube(at: CGPoint(x: 4, y: -10), size: 0.40)
        }
    }
    private func bridge(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.polygon([.init(x: -43, y: -14), .init(x: 35, y: -21), .init(x: 47, y: 10), .init(x: -34, y: 20)], [0xEDDBAC, 0xC0A77A, 0x8E8E73])
            for i in 0..<7 {
                let x = CGFloat(i) * 12 - 35
                p.line([.init(x: x, y: -12), .init(x: x + 8, y: 15)], 0x9A8E68, 1)
            }
            for x: CGFloat in [-36, 35] {
                p.line([.init(x: x, y: 4), .init(x: x, y: -34)], 0xAB8C52, 5)
                p.rivet(.init(x: x, y: -35), radius: 4)
            }
            p.line([.init(x: -36, y: -28), .init(x: 35, y: -35)], 0xE4C283, 3)
            p.line([.init(x: -36, y: -15), .init(x: 35, y: -22)], 0xD2AE6D, 2)
        }
    }
    func scene(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size, radius: 74 * size, rise: 135 * size) { p in
            p.glow(.init(x: 0, y: -28), radius: 85, color: 0xD3EFE4, opacity: 0.16)
            p.terrace(width: 146)
            switch variation % 4 {
            case 0:
                if variation == 8 { p.orrery(at: CGPoint(x: 0, y: -6), size: 1.05) }
                else { p.portal(at: CGPoint(x: 0, y: -9), size: 0.86) }
                p.gear(at: CGPoint(x: -46, y: -15), radius: 23, phase: 0.2)
                p.lamp(at: CGPoint(x: 51, y: 7), size: 0.78)
            case 1:
                p.tube(at: CGPoint(x: -39, y: -9), size: 0.94)
                p.console(at: CGPoint(x: 8, y: -4), size: 0.94, time: .init(hour: variation == 1 ? 6 : 14, minute: variation == 1 ? 25 : 40))
            case 2:
                p.workbench(at: CGPoint(x: -3, y: -5), size: 1.05)
                p.lamp(at: CGPoint(x: 53, y: 6), size: 0.94)
            default:
                p.orrery(at: CGPoint(x: -14, y: -10), size: 1.02)
                p.tube(at: CGPoint(x: 44, y: -3), size: 0.69)
            }
            p.plants(at: CGPoint(x: -53, y: 6), size: 0.71, flowers: true)
            p.plants(at: CGPoint(x: 43, y: 15), size: 0.64, flowers: variation % 2 == 0)
        }
    }
}

/// A tropical pirate coast keeps the sand route between shallow turquoise bays.
private struct PirateCoastPainter {
    let context: GraphicsContext
    var scenery: WorldSceneryLayout? = nil
    var depth: WorldSceneryDepth? = nil
    var depthOffset: CGFloat = 0

    private func at(_ point: CGPoint, size: CGFloat = 1, mirror: Bool = false, radius: CGFloat = 0, rise: CGFloat = 0, draw: @escaping (PirateCoastPainter) -> Void) {
        let point = scenery?.position(point, radius: radius, rise: rise) ?? point
        var c = context; c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: mirror ? -size : size, y: size)
        if let depth {
            depth.add(at: depthOffset + point.y) { draw(.init(context: c)) }
        } else { draw(.init(context: c)) }
    }
    private func material(_ path: Path, _ colors: [UInt32]) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                startPoint: .init(x: r.minX, y: r.minY), endPoint: .init(x: r.maxX, y: r.maxY)))
    }
    private func polygon(_ points: [CGPoint], _ colors: [UInt32]) {
        var p = Path(); p.addLines(points); p.closeSubpath(); material(p, colors)
    }
    private func rounded(_ r: CGRect, _ radius: CGFloat, _ colors: [UInt32]) {
        material(Path(roundedRect: r, cornerRadius: radius), colors)
    }
    private func oval(_ r: CGRect, _ colors: [UInt32]) {
        context.fill(Path(ellipseIn: r), with: .radialGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                            center: .init(x: r.minX + r.width * 0.3, y: r.minY + r.height * 0.2),
                                                            startRadius: 0, endRadius: max(r.width, r.height)))
    }
    private func line(_ points: [CGPoint], _ color: UInt32, _ width: CGFloat, opacity: Double = 1) {
        var p = Path(); p.addLines(points)
        context.stroke(p, with: .color(Color(dinoHex: color).opacity(opacity)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func glow(_ point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), Color(dinoHex: color).opacity(0)]),
                                           center: point, startRadius: 0, endRadius: radius))
    }

    func landscape(in size: CGSize, routeOffset: CGFloat, depth: WorldSceneryDepth) {
        let w = size.width, h = size.height, scale = min(1.30, max(0.82, size.width / 390))
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: 0xF5D698), location: 0),
            .init(color: Color(dinoHex: 0x92D9EF), location: 0.035),
            .init(color: Color(dinoHex: 0xC2E9E4), location: (routeOffset - 90) / h),
            .init(color: Color(dinoHex: 0xF9E3AF), location: (routeOffset + 170) / h),
            .init(color: Color(dinoHex: 0xF3D597), location: (routeOffset + 850) / h),
            .init(color: Color(dinoHex: 0xF6DBA3), location: (routeOffset + 1570) / h),
            .init(color: Color(dinoHex: 0xE8DFCC), location: 1)
        ]), startPoint: .zero, endPoint: .init(x: 0, y: h)))
        entrance(width: w, scale: scale)
        var c = context; c.translateBy(x: 0, y: routeOffset)
        let scenery = WorldSceneryLayout(width: w, height: h, routeOffset: routeOffset)
        scenery.drawBanks(in: c, worldID: 9)
        let coast = PirateCoastPainter(context: c, scenery: scenery, depth: depth, depthOffset: routeOffset)
        for side in 0..<2 {
            for i in 0..<12 {
                let y = 30 + CGFloat(i) * 144
                coast.at(CGPoint(x: side == 0 ? 0 : w, y: y), size: scale, mirror: side == 1) { p in
                    p.rock(at: CGPoint(x: 10 + CGFloat(i % 3) * 8, y: 0), size: 0.62 + CGFloat(i % 2) * 0.15)
                    p.plants(at: CGPoint(x: 14, y: -4), size: 0.66, flowers: i % 3 == 0)
                    if i % 3 == 1 { p.coral(at: CGPoint(x: 42, y: 36), size: 0.65) }
                    p.shell(at: CGPoint(x: 61 + CGFloat(i % 2) * 5, y: 63), size: 0.42)
                }
            }
        }
        // Crossings and surf sit behind the camp scenes, away from level labels.
        coast.jetty(at: CGPoint(x: 23 * scale, y: 650), size: scale * 0.84)
        coast.jetty(at: CGPoint(x: w - 23 * scale, y: 1185), size: scale * 0.86)
        coast.waterfall(at: CGPoint(x: 12 * scale, y: 960), size: scale * 0.90)
        for index in 0..<9 {
            let onRight = index % 4 == 0 || index % 4 == 3
            let x = index == 8 ? w - 152 * scale : onRight ? w - 62 * scale : 62 * scale
            coast.scene(at: CGPoint(x: x, y: 185 + CGFloat(index) * 175 - (index == 8 ? 15 : 0)), size: scale * 0.94, variation: index)
            coast.at(CGPoint(x: onRight ? 7 * scale : w - 7 * scale, y: 273 + CGFloat(index) * 175), size: scale, mirror: !onRight) { p in
                p.rock(at: .zero, size: 0.88)
                if index % 3 == 0 { p.palm(at: CGPoint(x: 0, y: -4), size: 0.79) }
                p.plants(at: CGPoint(x: 12, y: 5), size: 0.94, flowers: true)
                p.starfish(at: CGPoint(x: 39, y: 19), size: 0.64)
            }
        }
        for i in 0..<32 {
            let x = i % 2 == 0 ? CGFloat(79 + (i * 7) % 18) * scale : w - CGFloat(79 + (i * 13) % 18) * scale
            let y = 39 + CGFloat(i) * 51
            coast.oval(CGRect(x: x, y: y, width: 2 + CGFloat(i % 2), height: 1.5), [0xF9EDC4, 0xDDBB82])
        }
    }

    private func entrance(width: CGFloat, scale: CGFloat) {
        let sun = CGPoint(x: width * 0.24, y: 52 * scale)
        glow(sun, radius: 106 * scale, color: 0xFFF5C5, opacity: 0.65)
        oval(CGRect(x: sun.x - 21 * scale, y: sun.y - 21 * scale, width: 42 * scale, height: 42 * scale), [0xFFFFE4, 0xFFE8AF])
        for i in 0..<5 {
            at(CGPoint(x: width * CGFloat(i) / 4, y: CGFloat(27 + (i % 2) * 32) * scale), size: scale * 0.80) { p in
                p.context.drawLayer { c in
                    c.addFilter(.blur(radius: 2))
                    var cloud = Path()
                    for r in [CGRect(x: -53, y: 0, width: 113, height: 20), CGRect(x: -34, y: -17, width: 48, height: 35), CGRect(x: 1, y: -27, width: 50, height: 44)] { cloud.addEllipse(in: r) }
                    c.fill(cloud, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFFFFF).opacity(0.92), Color(dinoHex: 0xE4F5EC).opacity(0)]), startPoint: .init(x: 0, y: -27), endPoint: .init(x: 0, y: 23)))
                }
            }
        }
        context.fill(Path(CGRect(x: 0, y: 70 * scale, width: width, height: 235 * scale)),
                     with: .linearGradient(Gradient(stops: [.init(color: Color(dinoHex: 0x3DAFCC).opacity(0), location: 0),
                                                           .init(color: Color(dinoHex: 0x55BCD2).opacity(0.60), location: 0.2),
                                                           .init(color: Color(dinoHex: 0x9BD8D7).opacity(0), location: 1)]), startPoint: .init(x: 0, y: 70 * scale), endPoint: .init(x: 0, y: 305 * scale)))
        var far = context; far.opacity = 0.48
        far.clipToLayer { mask in
            mask.fill(Path(CGRect(x: 0, y: 0, width: width, height: 270 * scale)),
                      with: .linearGradient(Gradient(stops: [.init(color: .white, location: 0), .init(color: .white, location: 0.4), .init(color: .white.opacity(0), location: 1)]), startPoint: .init(x: 0, y: 60 * scale), endPoint: .init(x: 0, y: 220 * scale)))
        }
        let distant = PirateCoastPainter(context: far)
        for i in 0..<5 {
            distant.at(CGPoint(x: width * CGFloat(i) / 4, y: CGFloat(130 + (i % 2) * 16) * scale), size: scale * 0.72) { p in
                p.rock(at: .zero, size: 1.65)
                p.plants(at: CGPoint(x: 0, y: -61), size: 0.90, flowers: false)
                if i % 2 == 1 { p.palm(at: CGPoint(x: -7, y: -49), size: 0.44) }
            }
        }
        for i in 0..<16 {
            let x = CGFloat((i * 61) % max(1, Int(width)))
            let y = CGFloat(107 + (i * 17) % 91) * scale
            line([.init(x: x, y: y), .init(x: x + CGFloat(9 + i % 4 * 4) * scale, y: y)], 0xE7FFFF, 1, opacity: 0.47)
        }
        at(CGPoint(x: width * 0.77, y: 170 * scale), size: scale * 1.04) { p in
            var arch = Path()
            arch.addLines([.init(x: -74, y: 6), .init(x: -64, y: -48), .init(x: -43, y: -92), .init(x: -8, y: -99), .init(x: 7, y: -117), .init(x: 36, y: -103), .init(x: 55, y: -59), .init(x: 77, y: 7)])
            arch.closeSubpath()
            arch.addRoundedRect(in: CGRect(x: 8, y: -60, width: 34, height: 82), cornerSize: CGSize(width: 17, height: 23))
            p.context.fill(arch, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xE2D7B8), Color(dinoHex: 0xA9B5AE), Color(dinoHex: 0x6F969F)]), startPoint: .init(x: -40, y: -110), endPoint: .init(x: 55, y: 20)), style: FillStyle(eoFill: true))
            p.polygon([.init(x: -64, y: -48), .init(x: -43, y: -92), .init(x: -8, y: -99), .init(x: -15, y: -55), .init(x: -31, y: -9)], [0xEADAB5, 0xB2B8A9])
            p.line([.init(x: -8, y: -98), .init(x: -15, y: -55), .init(x: -11, y: -33)], 0x8F9F9C, 1.2)
            p.line([.init(x: 37, y: -98), .init(x: 39, y: -72), .init(x: 53, y: -48)], 0x698D96, 1.2)
            p.waterfall(at: CGPoint(x: -35, y: -21), size: 1.15)
            p.plants(at: CGPoint(x: 8, y: -103), size: 0.78, flowers: false)
            p.plants(at: CGPoint(x: 58, y: -17), size: 0.59, flowers: true)
            p.surf(at: CGPoint(x: 0, y: 14), size: 1.34)
        }
        ship(at: CGPoint(x: width * 0.25, y: 162 * scale), size: scale * 0.61)
        palm(at: CGPoint(x: -1 * scale, y: 218 * scale), size: scale * 1.13)
        at(CGPoint(x: width + 7 * scale, y: 238 * scale), size: scale * 1.10, mirror: true) { $0.palm(at: .zero, size: 1) }
        for i in 0..<3 {
            let x = width * (0.36 + CGFloat(i) * 0.16), y = CGFloat(37 + (i % 2) * 19) * scale
            var bird = Path(); bird.move(to: .init(x: x - 7 * scale, y: y))
            bird.addQuadCurve(to: .init(x: x, y: y + 2 * scale), control: .init(x: x - 2 * scale, y: y - 3 * scale))
            bird.addQuadCurve(to: .init(x: x + 7 * scale, y: y), control: .init(x: x + 2 * scale, y: y - 3 * scale))
            context.stroke(bird, with: .color(Color.white.opacity(0.86)), style: StrokeStyle(lineWidth: 1.2 * scale, lineCap: .round))
        }
    }
    private func rock(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            let v: [CGPoint] = [.init(x: -32, y: 2), .init(x: -30, y: -25), .init(x: -11, y: -48), .init(x: 14, y: -43), .init(x: 31, y: -21), .init(x: 28, y: 5), .init(x: 1, y: 12)]
            p.polygon(v, [0xE4D5B4, 0xA7B2AC, 0x73939A])
            p.polygon([v[1], v[2], v[3], .init(x: 0, y: -19)], [0xF2DFB9, 0xBAC0AA])
            p.polygon([v[3], v[4], v[5], .init(x: 0, y: -19)], [0xA7B7AC, 0x6C939B])
            p.line([.init(x: 0, y: -19), .init(x: 3, y: 5)], 0x5D858C, 1, opacity: 0.7)
            p.line([v[1], v[2], v[3]], 0xF5E5C4, 1.2, opacity: 0.8)
            p.plants(at: CGPoint(x: -8, y: -35), size: 0.33, flowers: false)
        }
    }
    private func leaf(from start: CGPoint, to end: CGPoint, width: CGFloat, light: Bool) {
        var p = Path(); p.move(to: start)
        p.addQuadCurve(to: end, control: .init(x: end.x * 0.55 - width, y: min(start.y, end.y) - width * 1.4))
        p.addQuadCurve(to: start, control: .init(x: end.x * 0.65 + width, y: end.y - width * 0.1)); p.closeSubpath()
        material(p, light ? [0xDAEA8C, 0x8EC65C, 0x438F66] : [0xA5D976, 0x5AA66C, 0x2D7A68])
        let mid = CGPoint(x: (start.x + end.x) * 0.5, y: min(start.y, end.y) - width * 0.35)
        var vein = Path(); vein.move(to: start); vein.addQuadCurve(to: end, control: mid)
        context.stroke(vein, with: .color(Color(dinoHex: 0xF0EFAE).opacity(0.65)), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
        for i in 1..<5 {
            let t = CGFloat(i) / 5
            let x = start.x * (1 - t) + end.x * t, y = start.y * (1 - t) + end.y * t - sin(t * .pi) * width * 0.35
            line([.init(x: x, y: y), .init(x: x + width * 0.2, y: y + width * 0.4)], 0xC6DD92, 0.6, opacity: 0.5)
        }
    }
    private func palm(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            var trunk = Path(); trunk.move(to: .init(x: -12, y: 7))
            trunk.addCurve(to: .init(x: 11, y: -115), control1: .init(x: -13, y: -40), control2: .init(x: 4, y: -78))
            trunk.addLine(to: .init(x: 23, y: -116))
            trunk.addCurve(to: .init(x: 10, y: 7), control1: .init(x: 14, y: -70), control2: .init(x: 6, y: -32)); trunk.closeSubpath()
            p.material(trunk, [0xE4BC7E, 0xB68D5B, 0x806C4F])
            for i in 0..<9 {
                let y = CGFloat(i) * 12 - 103, x = 13 - CGFloat(i) * 1.8
                p.line([.init(x: x - 6, y: y), .init(x: x + 5, y: y + 3)], 0x806C50, 1.3, opacity: 0.65)
                p.line([.init(x: x - 5, y: y + 4), .init(x: x + 3, y: y + 6)], 0xF5D19C, 0.9, opacity: 0.6)
            }
            let crown = CGPoint(x: 16, y: -117)
            for (i, end) in [CGPoint(x: -57, y: -90), .init(x: -49, y: -124), .init(x: -21, y: -155), .init(x: 19, y: -162), .init(x: 57, y: -145), .init(x: 81, y: -112), .init(x: 74, y: -78), .init(x: 28, y: -86)].enumerated() {
                p.leaf(from: crown, to: end, width: i % 2 == 0 ? 15 : 12, light: i % 3 == 0)
            }
            for (x, y): (CGFloat, CGFloat) in [(8, -112), (18, -108), (25, -117)] { p.oval(CGRect(x: x - 5, y: y - 5, width: 11, height: 13), [0xC9A06B, 0x816C50]) }
            p.plants(at: CGPoint(x: -5, y: 7), size: 0.66, flowers: true)
        }
    }
    private func plants(at point: CGPoint, size: CGFloat, flowers: Bool) {
        at(point, size: size) { p in
            for i in 0..<7 {
                let a = Double(i) * .pi / 6 - .pi
                let end = CGPoint(x: CGFloat(cos(a)) * 26, y: CGFloat(sin(a)) * 27 - 4)
                p.leaf(from: .zero, to: end, width: 5.5, light: i % 3 == 0)
            }
            if flowers {
                for (x, y): (CGFloat, CGFloat) in [(-14, -7), (0, -17), (17, -8)] {
                    for i in 0..<5 {
                        let a = Double(i) * .pi * 2 / 5
                        p.oval(CGRect(x: x + CGFloat(cos(a)) * 4 - 3.5, y: y + CGFloat(sin(a)) * 4 - 4, width: 7, height: 8), [0xFFC8AE, 0xE98F88, 0xCF7E86])
                    }
                    p.oval(CGRect(x: x - 2, y: y - 2, width: 4, height: 4), [0xFFF0AE, 0xE9C36F])
                }
            }
        }
    }
    private func surf(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -52, y: -7, width: 104, height: 23), [0xD1F8E9, 0x77CFD2, 0x4FB8CD])
            for i in 0..<7 {
                let x = CGFloat(i) * 14 - 45, y = CGFloat(i % 2) * 4
                p.line([.init(x: x - 4, y: y), .init(x: x, y: y + 2), .init(x: x + 8, y: y)], 0xEEFFF3, 1.3, opacity: 0.9)
                p.oval(CGRect(x: x, y: y - 4, width: 2.5, height: 2), [0xFFFFFF, 0xD1F6EC])
            }
        }
    }
    private func waterfall(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rock(at: CGPoint(x: -21, y: 10), size: 0.93)
            p.rock(at: CGPoint(x: 24, y: 9), size: 0.66)
            var water = Path(); water.move(to: .init(x: -14, y: -62)); water.addLine(to: .init(x: 14, y: -62))
            water.addCurve(to: .init(x: 20, y: 29), control1: .init(x: 21, y: -35), control2: .init(x: 7, y: -9))
            water.addLine(to: .init(x: -20, y: 29))
            water.addCurve(to: .init(x: -14, y: -62), control1: .init(x: -8, y: -7), control2: .init(x: -13, y: -35)); water.closeSubpath()
            p.material(water, [0xD2FFFF, 0x86DFE5, 0x45B3D3, 0xD5FFF0])
            for i in 0..<5 {
                let x = CGFloat(i) * 5 - 10
                var stream = Path(); stream.move(to: .init(x: x, y: -58))
                stream.addCurve(to: .init(x: x + 1, y: 24), control1: .init(x: x + 5, y: -35), control2: .init(x: x - 4, y: -8))
                p.context.stroke(stream, with: .color(Color(dinoHex: 0xF1FFFF).opacity(0.85)), style: StrokeStyle(lineWidth: i % 2 == 0 ? 1.7 : 0.7, lineCap: .round))
            }
            p.surf(at: CGPoint(x: 0, y: 27), size: 0.86)
            for i in 0..<5 { p.oval(CGRect(x: CGFloat(i) * 9 - 21, y: 20 - CGFloat(i % 3) * 4, width: 8, height: 9), [0xF8FFF5, 0xA3E5DF]) }
        }
    }
    private func coral(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for i in 0..<5 {
                let x = CGFloat(i) * 7 - 14, y = -CGFloat(13 + (i * 7) % 17)
                p.line([.zero, .init(x: x * 0.65, y: -9), .init(x: x, y: y)], 0xC89AAE, 3.3)
                p.line([.init(x: x * 0.65, y: -9), .init(x: x + 5, y: y + 7)], 0xE8BCC7, 1.8)
                p.oval(CGRect(x: x - 1.7, y: y - 2, width: 3.4, height: 4), [0xF6DCE1, 0xD6ACBE])
            }
        }
    }
    private func shell(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            var shell = Path(); shell.move(to: .init(x: 0, y: 4))
            shell.addQuadCurve(to: .init(x: -17, y: -10), control: .init(x: -13, y: -2))
            shell.addCurve(to: .init(x: 17, y: -10), control1: .init(x: -16, y: -27), control2: .init(x: 18, y: -27))
            shell.addQuadCurve(to: .init(x: 0, y: 4), control: .init(x: 13, y: -2)); shell.closeSubpath()
            p.material(shell, [0xFFF1D6, 0xEBCBB2, 0xC7AA9E])
            for x: CGFloat in [-12, -6, 0, 6, 12] { p.line([.init(x: 0, y: 1), .init(x: x, y: -16 + abs(x) * 0.35)], 0xFFF3DC, 1) }
            p.oval(CGRect(x: -3, y: 0, width: 6, height: 4), [0xF0DFBF, 0xBFAC8E])
        }
    }
    private func starfish(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            var points: [CGPoint] = []
            for i in 0..<10 {
                let a = Double(i) * .pi / 5 - .pi / 2, r: CGFloat = i % 2 == 0 ? 14 : 5
                points.append(.init(x: CGFloat(cos(a)) * r, y: CGFloat(sin(a)) * r * 0.8))
            }
            p.polygon(points, [0xFFC6A1, 0xE7927B, 0xC97E76])
            for i in 0..<5 {
                let a = Double(i) * .pi * 2 / 5 - .pi / 2
                for j in 1..<4 { p.oval(CGRect(x: CGFloat(cos(a)) * CGFloat(j) * 3 - 0.7, y: CGFloat(sin(a)) * CGFloat(j) * 2.4 - 0.7, width: 1.4, height: 1.4), [0xFFE7C6, 0xE9AC8A]) }
            }
        }
    }
    private func post(at point: CGPoint, height: CGFloat) {
        at(point) { p in
            p.rounded(CGRect(x: -4, y: -height, width: 8, height: height + 5), 2, [0xDBB785, 0xAC875D, 0x856D50])
            p.oval(CGRect(x: -5, y: -height - 2, width: 10, height: 5), [0xEDCCA0, 0xB9996D])
            for y: CGFloat in [-height + 7, -height + 10, -height + 13] { p.line([.init(x: -5, y: y), .init(x: 5, y: y + 1)], 0xECD7A8, 1.4) }
            p.line([.init(x: -1, y: -height + 18), .init(x: -2, y: 0)], 0xF0CFA1, 0.8, opacity: 0.6)
        }
    }
    private func jetty(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.surf(at: CGPoint(x: 3, y: 18), size: 1.06)
            p.polygon([.init(x: -52, y: -10), .init(x: 38, y: -22), .init(x: 54, y: 13), .init(x: -40, y: 27)], [0xC99D67, 0xA58055, 0x7E6C4F])
            for i in 0..<9 {
                let x = CGFloat(i) * 11 - 45
                p.polygon([.init(x: x, y: -10 - CGFloat(i) * 1.1), .init(x: x + 10, y: -11 - CGFloat(i) * 1.1), .init(x: x + 21, y: 16 - CGFloat(i) * 1.1), .init(x: x + 11, y: 17 - CGFloat(i) * 1.1)], [0xF1CF96, 0xC69D6A, 0xA9855C])
                p.line([.init(x: x + 5, y: -5 - CGFloat(i)), .init(x: x + 13, y: 9 - CGFloat(i))], 0x9C7E58, 0.7, opacity: 0.7)
                for y: CGFloat in [-5, 11] { p.oval(CGRect(x: x + 7 + y * 0.25, y: y - CGFloat(i), width: 1.5, height: 1.5), [0x7C7460, 0xAEA180]) }
            }
            for y: CGFloat in [-15, 19] {
                p.post(at: CGPoint(x: -42, y: y + 6), height: 32)
                p.post(at: CGPoint(x: 43, y: y - 6), height: 32)
                var rope = Path(); rope.move(to: .init(x: -42, y: y - 19))
                rope.addQuadCurve(to: .init(x: 43, y: y - 31), control: .init(x: 0, y: y - 5))
                p.context.stroke(rope, with: .color(Color(dinoHex: 0xE8D1A0)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            }
        }
    }
    private func barrel(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -14, y: -31, width: 28, height: 34), 9, [0xE5BC7F, 0xB68C59, 0x8B7353])
            for x: CGFloat in [-7, 0, 7] { p.line([.init(x: x, y: -27), .init(x: x + 1, y: 0)], 0x8E714D, 0.8) }
            for y: CGFloat in [-23, -4] { p.rounded(CGRect(x: -14, y: y, width: 28, height: 4), 1, [0xA8B7AB, 0x63848A]) }
            p.oval(CGRect(x: -12, y: -34, width: 24, height: 8), [0xF0CB91, 0xAE895D])
            p.context.stroke(Path(ellipseIn: CGRect(x: -8, y: -32, width: 16, height: 4)), with: .color(Color(dinoHex: 0xA48158)), lineWidth: 0.8)
        }
    }
    private func chest(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -29, y: -24, width: 58, height: 31), 4, [0xD6AA72, 0xA77F54, 0x88694C])
            p.rounded(CGRect(x: -29, y: -47, width: 58, height: 25), 12, [0xE9C488, 0xBE965F, 0x90744E])
            for y: CGFloat in [-39, -31, -15, -5] { p.line([.init(x: -25, y: y), .init(x: 25, y: y)], 0x8D704E, 0.7, opacity: 0.65) }
            for x: CGFloat in [-22, 17] {
                p.rounded(CGRect(x: x, y: -44, width: 5, height: 49), 1, [0xFFE5A5, 0xC5A05F])
                for y: CGFloat in [-36, -13, 0] { p.oval(CGRect(x: x + 1, y: y, width: 2, height: 2), [0xFFF2BF, 0xA68450]) }
            }
            p.line([.init(x: -28, y: -23), .init(x: 28, y: -23)], 0xFFE4A5, 3)
            p.rounded(CGRect(x: -6, y: -28, width: 12, height: 15), 3, [0xFFE7A8, 0xC49E5C])
            p.oval(CGRect(x: -1.6, y: -23, width: 3.2, height: 5), [0x7A7353, 0x655E48])
            for i in 0..<5 { p.oval(CGRect(x: 26 + CGFloat(i) * 4, y: 5 + CGFloat(i % 2) * 3, width: 7, height: 3), [0xFFF0B2, 0xD4AE60]) }
        }
    }
    private func anchor(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.context.stroke(Path(ellipseIn: CGRect(x: -5, y: -47, width: 10, height: 10)), with: .color(Color(dinoHex: 0x7EA6AA)), lineWidth: 3)
            p.line([.init(x: 0, y: -37), .init(x: 0, y: 0)], 0x688F99, 4)
            p.line([.init(x: -12, y: -25), .init(x: 12, y: -25)], 0x96B7B4, 3)
            var hook = Path(); hook.move(to: .init(x: -18, y: -14)); hook.addCurve(to: .init(x: 18, y: -14), control1: .init(x: -15, y: 14), control2: .init(x: 15, y: 14))
            p.context.stroke(hook, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xB0CEC4), Color(dinoHex: 0x557E8D)]), startPoint: .init(x: -18, y: -14), endPoint: .init(x: 18, y: 2)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            for x: CGFloat in [-18, 18] { p.polygon([.init(x: x, y: -18), .init(x: x - 5, y: -9), .init(x: x + 5, y: -10)], [0xB5CEC0, 0x638B98]) }
            p.line([.init(x: -1, y: -36), .init(x: -1, y: -4)], 0xDAE3C8, 0.9, opacity: 0.7)
        }
    }
    private func ship(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.surf(at: CGPoint(x: 0, y: 14), size: 1.28)
            var hull = Path(); hull.move(to: .init(x: -56, y: -7)); hull.addLine(to: .init(x: 58, y: -13))
            hull.addQuadCurve(to: .init(x: -40, y: 24), control: .init(x: 30, y: 51)); hull.closeSubpath()
            p.material(hull, [0xE4BA7E, 0xB3895D, 0x846F51])
            for i in 0..<3 { p.line([.init(x: -40 + CGFloat(i) * 6, y: 3 + CGFloat(i) * 6), .init(x: 44 - CGFloat(i) * 11, y: -1 + CGFloat(i) * 6)], 0x8F704C, 0.8) }
            p.line([.init(x: -55, y: -7), .init(x: 58, y: -13)], 0xFFE4A9, 3)
            for x: CGFloat in [-25, 0, 25] {
                p.oval(CGRect(x: x - 5, y: 1, width: 10, height: 10), [0xFFE0A2, 0xC3A06A])
                p.oval(CGRect(x: x - 3, y: 3, width: 6, height: 6), [0xA5CECD, 0x597F8E])
            }
            p.line([.init(x: -5, y: -7), .init(x: -5, y: -125)], 0xA58457, 4)
            p.line([.init(x: -6, y: -9), .init(x: -6, y: -124)], 0xF1CF95, 1)
            p.line([.init(x: -43, y: -8), .init(x: -5, y: -119), .init(x: 47, y: -14)], 0xDCC99A, 1)
            var sail = Path(); sail.move(to: .init(x: 0, y: -111))
            sail.addQuadCurve(to: .init(x: 49, y: -30), control: .init(x: 42, y: -83))
            sail.addQuadCurve(to: .init(x: 0, y: -42), control: .init(x: 21, y: -33)); sail.closeSubpath()
            p.material(sail, [0xFFFAE1, 0xF1D8A2, 0xDAC293])
            p.line([.init(x: 3, y: -104), .init(x: 11, y: -75), .init(x: 21, y: -43)], 0xCDBE92, 0.9, opacity: 0.6)
            p.polygon([.init(x: -10, y: -105), .init(x: -45, y: -39), .init(x: -10, y: -45)], [0xD3E6DD, 0xA9CDCF, 0x8FB4BD])
            p.polygon([.init(x: -4, y: -126), .init(x: 24, y: -120), .init(x: 8, y: -112), .init(x: -4, y: -114)], [0xF6D88D, 0xDCA76D])
            p.anchor(at: CGPoint(x: -38, y: 2), size: 0.43)
            p.barrel(at: CGPoint(x: 29, y: -9), size: 0.54)
        }
    }
    private func lantern(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.glow(.init(x: 0, y: -18), radius: 29, color: 0xFFE3A3, opacity: 0.32)
            p.rounded(CGRect(x: -8, y: -34, width: 16, height: 29), 4, [0xE5C18B, 0xA68A5C])
            p.rounded(CGRect(x: -5, y: -30, width: 10, height: 22), 3, [0xFFFFDD, 0xFFE5A0, 0xEAB76C])
            p.line([.init(x: 0, y: -29), .init(x: 0, y: -9)], 0xC8A76B, 0.8)
            p.polygon([.init(x: -10, y: -34), .init(x: 0, y: -41), .init(x: 10, y: -34)], [0xFFE2A3, 0xB2925E])
            p.rounded(CGRect(x: -10, y: -7, width: 20, height: 5), 2, [0xE3BE86, 0x9C8158])
        }
    }
    private func hourglass(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -30, y: -3, width: 60, height: 13), [0xE9C88A, 0xB59361])
            var glass = Path(); glass.move(to: .init(x: -18, y: -71)); glass.addLine(to: .init(x: 18, y: -71))
            glass.addCurve(to: .init(x: 5, y: -36), control1: .init(x: 21, y: -51), control2: .init(x: 3, y: -46))
            glass.addCurve(to: .init(x: 19, y: -4), control1: .init(x: 3, y: -24), control2: .init(x: 21, y: -21))
            glass.addLine(to: .init(x: -19, y: -4))
            glass.addCurve(to: .init(x: -5, y: -36), control1: .init(x: -21, y: -21), control2: .init(x: -3, y: -24))
            glass.addCurve(to: .init(x: -18, y: -71), control1: .init(x: -3, y: -46), control2: .init(x: -21, y: -51)); glass.closeSubpath()
            p.material(glass, [0xEDFFFF, 0xB9E4D7, 0x8AC6CB, 0xDAF5DE])
            p.polygon([.init(x: -15, y: -63), .init(x: 15, y: -63), .init(x: 0, y: -38)], [0xFFF1BA, 0xE8C77C])
            p.polygon([.init(x: -16, y: -7), .init(x: 0, y: -25), .init(x: 16, y: -7)], [0xFFF1B3, 0xE2BC70])
            p.line([.init(x: 0, y: -37), .init(x: 0, y: -23)], 0xFFE6A1, 1)
            for x: CGFloat in [-25, 25] { p.rounded(CGRect(x: x - 3, y: -73, width: 6, height: 72), 2, [0xEACA91, 0xB38E5D]) }
            for y: CGFloat in [-77, -6] { p.rounded(CGRect(x: -30, y: y, width: 60, height: 8), 3, [0xFFE5AA, 0xCCA56E, 0xA28C62]) }
            p.line([.init(x: -12, y: -63), .init(x: -11, y: -53), .init(x: -6, y: -44)], 0xFFFFFF, 1.7, opacity: 0.85)
        }
    }
    private func clockBoard(at point: CGPoint, size: CGFloat, hour: Int, minute: Int) {
        at(point, size: size) { p in
            for x: CGFloat in [-25, 25] { p.rounded(CGRect(x: x - 3, y: -17, width: 6, height: 22), 2, [0xC9A16B, 0x927B56]) }
            p.rounded(CGRect(x: -38, y: -49, width: 76, height: 38), 13, [0xFFF0C8, 0xE3CAA1, 0xAB9D85])
            p.rounded(CGRect(x: -32, y: -43, width: 64, height: 26), 8, [0x496674, 0x294D5D])
            p.context.draw(Text(verbatim: String(format: "%02d:%02d", hour, minute)).font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundStyle(Color(dinoHex: 0xFFE7A8)), at: .init(x: 0, y: -30))
            p.rounded(CGRect(x: -6, y: -55, width: 12, height: 7), 3, [0xFFE4A4, 0xC6A06A])
            p.oval(CGRect(x: -3, y: -59, width: 6, height: 6), [0xFFF1B9, 0xD9B77E])
            for x: CGFloat in [-34, 34] { p.oval(CGRect(x: x - 1, y: -31, width: 2, height: 2), [0xFFF6CF, 0xBDA37A]) }
        }
    }
    private func camp(at point: CGPoint, size: CGFloat, hour: Int, minute: Int) {
        at(point, size: size) { p in
            p.rock(at: CGPoint(x: -31, y: -1), size: 0.87)
            for x: CGFloat in [-42, 40] { p.post(at: CGPoint(x: x, y: 5), height: 94) }
            var tent = Path(); tent.move(to: .init(x: -42, y: -84)); tent.addLine(to: .init(x: 40, y: -94))
            tent.addQuadCurve(to: .init(x: 47, y: -52), control: .init(x: 36, y: -62))
            tent.addQuadCurve(to: .init(x: -44, y: -42), control: .init(x: -1, y: -62)); tent.closeSubpath()
            p.material(tent, [0xFFF7D9, 0xF0D79E, 0xD4BF90])
            for i in 0..<5 {
                let x = CGFloat(i) * 16 - 38
                p.line([.init(x: x, y: -83 - CGFloat(i) * 1.8), .init(x: x + 2, y: -51 - CGFloat(i) * 1.8)], 0xFFFFE9, 6, opacity: 0.58)
            }
            p.line([.init(x: -42, y: -84), .init(x: 40, y: -94)], 0xEBD8AC, 2)
            p.barrel(at: CGPoint(x: 43, y: 8), size: 0.75)
            p.lantern(at: CGPoint(x: -42, y: -11), size: 0.70)
            p.clockBoard(at: CGPoint(x: -1, y: 12), size: 1, hour: hour, minute: minute)
        }
    }
    func scene(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size, radius: 74 * size, rise: 135 * size) { p in
            p.surf(at: CGPoint(x: 5, y: 21), size: 1.35)
            p.oval(CGRect(x: -73, y: -10, width: 147, height: 46), [0xFFF0C6, 0xEBC78D, 0xC5BA8C])
            if variation == 8 {
                p.rock(at: CGPoint(x: 1, y: 9), size: 1.58)
                p.hourglass(at: CGPoint(x: -1, y: -11), size: 1.22)
                p.chest(at: CGPoint(x: -43, y: 20), size: 0.55)
                p.lantern(at: CGPoint(x: 46, y: 8), size: 0.77)
            } else {
                switch variation % 4 {
                case 0:
                    p.palm(at: CGPoint(x: 26, y: -8), size: 0.94)
                    p.camp(at: CGPoint(x: -8, y: 1), size: 0.96, hour: 9, minute: variation == 0 ? 0 : 30)
                case 1:
                    p.jetty(at: CGPoint(x: -8, y: 12), size: 0.99)
                    p.ship(at: CGPoint(x: 4, y: -10), size: 0.94)
                    p.barrel(at: CGPoint(x: -42, y: 25), size: 0.72)
                case 2:
                    p.palm(at: CGPoint(x: -27, y: -3), size: 0.83)
                    p.chest(at: CGPoint(x: -8, y: 12), size: 1.02)
                    if variation == 2 { p.hourglass(at: CGPoint(x: 39, y: 7), size: 0.76) }
                    else { p.clockBoard(at: CGPoint(x: 35, y: 4), size: 0.90, hour: 10, minute: 0) }
                default:
                    p.rock(at: CGPoint(x: 15, y: 3), size: 1.19)
                    p.barrel(at: CGPoint(x: -27, y: 13), size: 0.91)
                    p.barrel(at: CGPoint(x: -3, y: 17), size: 0.72)
                    p.anchor(at: CGPoint(x: 24, y: 11), size: 1.08)
                    p.lantern(at: CGPoint(x: -27, y: -15), size: 0.72)
                }
            }
            p.plants(at: CGPoint(x: -50, y: 16), size: 0.75, flowers: true)
            p.shell(at: CGPoint(x: 45, y: 30), size: 0.59)
            p.starfish(at: CGPoint(x: -22, y: 30), size: 0.67)
        }
    }
}

/// The final chapter is a royal garden of blue roofs, pale stone and running water.
private struct CastleWorldPainter {
    let context: GraphicsContext
    var scenery: WorldSceneryLayout? = nil
    var depth: WorldSceneryDepth? = nil
    var depthOffset: CGFloat = 0

    private func at(_ point: CGPoint, size: CGFloat = 1, mirror: Bool = false, radius: CGFloat = 0, rise: CGFloat = 0, draw: @escaping (CastleWorldPainter) -> Void) {
        let point = scenery?.position(point, radius: radius, rise: rise) ?? point
        var c = context; c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: mirror ? -size : size, y: size)
        if let depth {
            depth.add(at: depthOffset + point.y) { draw(.init(context: c)) }
        } else { draw(.init(context: c)) }
    }
    private func material(_ path: Path, _ colors: [UInt32]) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                startPoint: .init(x: r.minX, y: r.minY), endPoint: .init(x: r.maxX, y: r.maxY)))
    }
    private func polygon(_ points: [CGPoint], _ colors: [UInt32]) {
        var p = Path(); p.addLines(points); p.closeSubpath(); material(p, colors)
    }
    private func rounded(_ r: CGRect, _ radius: CGFloat, _ colors: [UInt32]) {
        material(Path(roundedRect: r, cornerRadius: radius), colors)
    }
    private func oval(_ r: CGRect, _ colors: [UInt32]) {
        context.fill(Path(ellipseIn: r), with: .radialGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                            center: .init(x: r.minX + r.width * 0.3, y: r.minY + r.height * 0.2),
                                                            startRadius: 0, endRadius: max(r.width, r.height)))
    }
    private func line(_ points: [CGPoint], _ color: UInt32, _ width: CGFloat, opacity: Double = 1) {
        var p = Path(); p.addLines(points)
        context.stroke(p, with: .color(Color(dinoHex: color).opacity(opacity)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func glow(_ point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), Color(dinoHex: color).opacity(0)]),
                                           center: point, startRadius: 0, endRadius: radius))
    }

    func landscape(in size: CGSize, routeOffset: CGFloat, depth: WorldSceneryDepth) {
        let w = size.width, h = size.height, scale = min(1.30, max(0.82, size.width / 390))
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: 0xE8DFCC), location: 0),
            .init(color: Color(dinoHex: 0xB2D9EC), location: 0.035),
            .init(color: Color(dinoHex: 0xE1E9DA), location: (routeOffset - 100) / h),
            .init(color: Color(dinoHex: 0xEFE4C5), location: (routeOffset + 230) / h),
            .init(color: Color(dinoHex: 0xDFE1C6), location: (routeOffset + 900) / h),
            .init(color: Color(dinoHex: 0xF1E1B9), location: (routeOffset + 1550) / h),
            .init(color: Color(dinoHex: 0xE8DFCC), location: 1)
        ]), startPoint: .zero, endPoint: .init(x: 0, y: h)))
        entrance(width: w, scale: scale)
        var c = context; c.translateBy(x: 0, y: routeOffset)
        let scenery = WorldSceneryLayout(width: w, height: h, routeOffset: routeOffset)
        scenery.drawBanks(in: c, worldID: 10)
        let p = CastleWorldPainter(context: c, scenery: scenery, depth: depth, depthOffset: routeOffset)
        for side in 0..<2 {
            for i in 0..<12 {
                let y = 35 + CGFloat(i) * 145
                p.at(CGPoint(x: side == 0 ? 0 : w, y: y), size: scale, mirror: side == 1) { edge in
                    edge.at(CGPoint(x: 5, y: 0)) { garden in
                        garden.terrace(width: 68)
                        if i % 3 == 0 { garden.cypress(at: CGPoint(x: 0, y: -7), size: 0.77) }
                        else { garden.rock(at: CGPoint(x: -4, y: -6), size: 0.67) }
                        garden.flowers(at: CGPoint(x: 13, y: 1), size: 0.74)
                        if i % 3 == 1 { garden.crystals(at: CGPoint(x: 14, y: -6), size: 0.56) }
                    }
                }
            }
        }
        // Waterfalls and crossings are painted before the larger clock gardens.
        p.waterfall(at: CGPoint(x: 13 * scale, y: 625), size: scale * 0.95)
        p.at(CGPoint(x: w - 12 * scale, y: 1165), size: scale, mirror: true) { $0.waterfall(at: .zero, size: 0.92) }
        p.bridge(at: CGPoint(x: 21 * scale, y: 940), size: scale * 0.88)
        p.bridge(at: CGPoint(x: w - 20 * scale, y: 1350), size: scale * 0.86)
        for index in 0..<9 {
            let onRight = index % 4 == 0 || index % 4 == 3
            let x = index == 8 ? w - 151 * scale : onRight ? w - 63 * scale : 63 * scale
            p.scene(at: CGPoint(x: x, y: 185 + CGFloat(index) * 175 - (index == 8 ? 30 : 0)), size: scale * 0.94, variation: index)
            p.at(CGPoint(x: onRight ? 6 * scale : w - 6 * scale, y: 274 + CGFloat(index) * 175), size: scale) { garden in
                garden.terrace(width: 77)
                garden.planter(at: CGPoint(x: 0, y: -3), size: 0.80)
                if index % 2 == 0 { garden.brazier(at: CGPoint(x: onRight ? 27 : -27, y: 1), size: 0.66) }
            }
        }
        for i in 0..<28 {
            let x = i % 2 == 0 ? CGFloat(72 + (i * 7) % 23) * scale : w - CGFloat(72 + (i * 11) % 23) * scale
            let y = 50 + CGFloat(i) * 58
            p.oval(CGRect(x: x, y: y, width: 3, height: 1.5), [0xFFF2CE, 0xC7BC94])
        }
    }

    private func entrance(width: CGFloat, scale: CGFloat) {
        let sun = CGPoint(x: width * 0.78, y: 52 * scale)
        glow(sun, radius: 135 * scale, color: 0xFFF0B8, opacity: 0.68)
        oval(CGRect(x: sun.x - 23 * scale, y: sun.y - 23 * scale, width: 46 * scale, height: 46 * scale), [0xFFFFDE, 0xFFE2A3])
        for i in 0..<5 {
            at(CGPoint(x: width * CGFloat(i) / 4, y: CGFloat(30 + (i % 2) * 36) * scale), size: scale * 0.83) { p in
                p.context.drawLayer { c in
                    c.addFilter(.blur(radius: 2.2))
                    var cloud = Path()
                    for r in [CGRect(x: -54, y: 0, width: 116, height: 20), CGRect(x: -33, y: -18, width: 48, height: 35), CGRect(x: 2, y: -29, width: 52, height: 46)] { cloud.addEllipse(in: r) }
                    c.fill(cloud, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFFFEE).opacity(0.93), Color(dinoHex: 0xE6ECDD).opacity(0)]), startPoint: .init(x: 0, y: -29), endPoint: .init(x: 0, y: 22)))
                }
            }
        }
        var far = context; far.opacity = 0.42
        far.clipToLayer { mask in
            mask.fill(Path(CGRect(x: 0, y: 0, width: width, height: 300 * scale)),
                      with: .linearGradient(Gradient(stops: [.init(color: .white, location: 0), .init(color: .white, location: 0.42), .init(color: .white.opacity(0), location: 1)]), startPoint: .init(x: 0, y: 40 * scale), endPoint: .init(x: 0, y: 230 * scale)))
        }
        let distant = CastleWorldPainter(context: far)
        for i in 0..<5 {
            distant.at(CGPoint(x: width * CGFloat(i) / 4, y: CGFloat(177 + (i % 2) * 17) * scale), size: scale * 0.75) { p in
                p.rock(at: .zero, size: 2.15)
                p.tower(at: CGPoint(x: 0, y: -70), size: 0.66, time: nil)
                if i % 2 == 0 { p.waterfall(at: CGPoint(x: 23, y: -16), size: 0.92) }
                p.cypress(at: CGPoint(x: -33, y: -55), size: 0.52)
            }
        }
        gate(at: CGPoint(x: width * 0.76, y: 186 * scale), size: scale * 0.73)
        tower(at: CGPoint(x: 45 * scale, y: 199 * scale), size: scale * 0.83, time: .init(hour: 10, minute: 25))
        waterfall(at: CGPoint(x: 10 * scale, y: 215 * scale), size: scale * 1.03)
        cypress(at: CGPoint(x: width - 13 * scale, y: 220 * scale), size: scale * 0.90)
        planter(at: CGPoint(x: 11 * scale, y: 226 * scale), size: scale * 0.95)
    }
    private func masonry(_ rect: CGRect) {
        rounded(rect, 7, [0xFFF1D0, 0xE2D0AC, 0xB6B49D])
        let rows = Int(rect.height / 18)
        for i in 1...max(1, rows) {
            let y = rect.minY + CGFloat(i) * 18
            line([.init(x: rect.minX + 3, y: y), .init(x: rect.maxX - 3, y: y)], 0xB5B39D, 0.8, opacity: 0.62)
            for j in 0..<3 {
                let x = rect.minX + CGFloat(j) * rect.width / 3 + (i % 2 == 0 ? 0 : rect.width / 6)
                if x > rect.minX + 2 { line([.init(x: x, y: y - 17), .init(x: x, y: y - 1)], 0xB4B39D, 0.7, opacity: 0.6) }
            }
            line([.init(x: rect.minX + 4, y: y + 1), .init(x: rect.maxX - 4, y: y + 1)], 0xFFF6D8, 0.7, opacity: 0.55)
        }
    }
    private func terrace(width: CGFloat) {
        masonry(CGRect(x: -width / 2, y: -4, width: width, height: 29))
        oval(CGRect(x: -width / 2, y: -13, width: width, height: 29), [0xFFF0C8, 0xDED2AA, 0xB9B79C])
        context.stroke(Path(ellipseIn: CGRect(x: -width / 2 + 3, y: -10, width: width - 6, height: 23)), with: .color(Color(dinoHex: 0xFFFFE4).opacity(0.76)), lineWidth: 1.2)
    }
    private func roof(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            let roof = Path { r in
                r.move(to: .init(x: -38, y: 0)); r.addLine(to: .init(x: -1, y: -57))
                r.addLine(to: .init(x: 7, y: -55)); r.addLine(to: .init(x: 39, y: 0)); r.closeSubpath()
            }
            p.material(roof, [0xA4BCD9, 0x6589BA, 0x3C5E94])
            var tiles = p.context; tiles.clip(to: roof)
            let local = CastleWorldPainter(context: tiles)
            for row in 0..<7 {
                let y = CGFloat(row) * 8 - 49
                for col in 0..<10 {
                    let x = CGFloat(col) * 10 - 48 + CGFloat(row % 2) * 5
                    var tile = Path(); tile.move(to: .init(x: x, y: y))
                    tile.addQuadCurve(to: .init(x: x + 10, y: y), control: .init(x: x + 5, y: y + 6))
                    tiles.stroke(tile, with: .color(Color(dinoHex: 0xC2D5E1).opacity(0.55)), lineWidth: 0.65)
                    local.line([.init(x: x + 5, y: y + 3), .init(x: x + 5, y: y + 7)], 0x325383, 0.5, opacity: 0.4)
                }
            }
            p.rounded(CGRect(x: -40, y: -1, width: 82, height: 7), 3, [0xFFE9A8, 0xCEA96B, 0xA09268])
            for x: CGFloat in [-29, -10, 10, 29] { p.oval(CGRect(x: x - 1.5, y: 1, width: 3, height: 3), [0xFFF5C4, 0xBA955A]) }
            p.oval(CGRect(x: -4, y: -64, width: 12, height: 12), [0xFFF0AE, 0xD7B470, 0xB09560])
            p.line([.init(x: 2, y: -63), .init(x: 2, y: -87)], 0xD4B16C, 1.6)
            p.polygon([.init(x: 3, y: -87), .init(x: 28, y: -81), .init(x: 18, y: -72), .init(x: 3, y: -76)], [0x98B9DA, 0x4D75AB])
            p.line([.init(x: 5, y: -85), .init(x: 23, y: -81), .init(x: 17, y: -75)], 0xFFE6A4, 0.9)
        }
    }
    private func crown(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.polygon([.init(x: -11, y: -7), .init(x: -4, y: -3), .init(x: 0, y: -13), .init(x: 4, y: -3), .init(x: 11, y: -7), .init(x: 8, y: 6), .init(x: -8, y: 6)], [0xFFF0AE, 0xDAB66C])
            p.line([.init(x: -7, y: 3), .init(x: 7, y: 3)], 0xFFF6C7, 1)
            for x: CGFloat in [-10, 0, 10] { p.oval(CGRect(x: x - 1.3, y: (x == 0 ? -14 : -8), width: 2.6, height: 2.6), [0xFFFFCD, 0xDFBF79]) }
        }
    }
    private func banner(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.polygon([.init(x: -15, y: -40), .init(x: 15, y: -40), .init(x: 15, y: 9), .init(x: 0, y: 23), .init(x: -15, y: 9)], [0x95B3D4, 0x527CB5, 0x385D95])
            p.line([.init(x: -13, y: -38), .init(x: -13, y: 7), .init(x: 0, y: 20), .init(x: 13, y: 7), .init(x: 13, y: -38)], 0xE9C984, 1)
            p.line([.init(x: -19, y: -42), .init(x: 19, y: -42)], 0xD8B371, 3)
            p.crown(at: CGPoint(x: 0, y: -14), size: 0.68)
            p.line([.init(x: 9, y: -4), .init(x: 9, y: 3)], 0xC8D7DF, 0.8, opacity: 0.4)
        }
    }
    private func clock(at point: CGPoint, radius: CGFloat, time: ClockTime) {
        at(point) { p in
            p.oval(CGRect(x: -radius - 4, y: -radius - 3, width: (radius + 4) * 2, height: (radius + 4) * 2), [0xFFF1BB, 0xCFAE72, 0xA58C62])
            p.oval(CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), [0xFFFFE7, 0xF6EBCB, 0xDFD8B6])
            for i in 0..<60 {
                let a = Double(i) * .pi / 30, inner = radius * (i % 5 == 0 ? 0.77 : 0.88)
                p.line([.init(x: CGFloat(sin(a)) * inner, y: -CGFloat(cos(a)) * inner), .init(x: CGFloat(sin(a)) * radius * 0.94, y: -CGFloat(cos(a)) * radius * 0.94)], 0x466477, i % 5 == 0 ? 1.2 : 0.5, opacity: i % 5 == 0 ? 1 : 0.6)
            }
            for (angle, length, width) in [(time.hourAngle, radius * 0.46, CGFloat(2.8)), (time.minuteAngle, radius * 0.72, CGFloat(1.8))] {
                let a = angle * .pi / 180
                p.line([.zero, .init(x: CGFloat(sin(a)) * length, y: -CGFloat(cos(a)) * length)], 0x36546D, width)
            }
            p.oval(CGRect(x: -2.1, y: -2.1, width: 4.2, height: 4.2), [0xE0C28B, 0x9C8A64])
        }
    }
    private func digital(at point: CGPoint, time: ClockTime) {
        at(point) { p in
            p.rounded(CGRect(x: -30, y: -13, width: 60, height: 26), 7, [0xEBD5A3, 0xB2A789])
            p.rounded(CGRect(x: -26, y: -9, width: 52, height: 18), 4, [0x416479, 0x274A62])
            p.context.draw(Text(verbatim: String(format: "%02d:%02d", time.hour, time.minute)).font(.system(size: 13.5, weight: .bold, design: .monospaced)).foregroundStyle(Color(dinoHex: 0xD7F9ED)), at: .zero)
        }
    }
    private func tower(at point: CGPoint, size: CGFloat, time: ClockTime?) {
        at(point, size: size) { p in
            p.masonry(CGRect(x: -29, y: -126, width: 58, height: 130))
            p.rounded(CGRect(x: -33, y: -130, width: 66, height: 10), 3, [0xFFF2D3, 0xD2C5A5])
            p.roof(at: CGPoint(x: 0, y: -133), size: 0.88)
            p.rounded(CGRect(x: -15, y: -30, width: 30, height: 34), 14, [0x7F9EB5, 0x446D91])
            p.line([.init(x: -10, y: 0), .init(x: -10, y: -14)], 0xBCD3D6, 1, opacity: 0.7)
            if let time {
                p.clock(at: CGPoint(x: 0, y: -89), radius: 23, time: time)
                p.digital(at: CGPoint(x: 0, y: -45), time: time)
            } else {
                p.rounded(CGRect(x: -8, y: -109, width: 16, height: 33), 8, [0xFBE9B8, 0x759CB2, 0x42698C])
                p.line([.init(x: 0, y: -107), .init(x: 0, y: -80)], 0xE7C886, 1.2)
                p.banner(at: CGPoint(x: 0, y: -31), size: 0.60)
            }
            p.rounded(CGRect(x: -34, y: 1, width: 68, height: 8), 3, [0xEEE4C5, 0xAEB39E])
            p.ivy(at: CGPoint(x: -26, y: -108), size: 0.87)
            p.flowers(at: CGPoint(x: 25, y: 7), size: 0.63)
        }
    }
    private func gate(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.masonry(CGRect(x: -63, y: -109, width: 126, height: 119))
            for i in 0..<7 { p.rounded(CGRect(x: CGFloat(i) * 19 - 64, y: -120, width: 12, height: 20), 2, [0xFFF2D2, 0xD9CBAB]) }
            p.glow(CGPoint(x: 0, y: -35), radius: 55, color: 0xFFE5A3, opacity: 0.36)
            p.rounded(CGRect(x: -31, y: -79, width: 62, height: 87), 29, [0xF5D791, 0xC3A36C])
            p.rounded(CGRect(x: -25, y: -73, width: 50, height: 80), 24, [0xFFF0B9, 0xE4BF7C, 0xBB9964])
            for x: CGFloat in [-17, -8, 0, 8, 17] { p.line([.init(x: x, y: x == 0 ? -68 : -60), .init(x: x, y: 3)], 0xA98D61, 0.9, opacity: 0.75) }
            p.line([.init(x: -24, y: -21), .init(x: 24, y: -21)], 0xFFE9AA, 2)
            for x: CGFloat in [-6, 6] { p.oval(CGRect(x: x - 2, y: -36, width: 4, height: 6), [0xFFF3C2, 0xB99A61]) }
            p.clock(at: CGPoint(x: 0, y: -108), radius: 22, time: .init(hour: 12, minute: 0))
            for side in 0..<2 {
                let x: CGFloat = side == 0 ? -62 : 62
                p.tower(at: CGPoint(x: x, y: 5), size: side == 0 ? 0.70 : 0.82, time: nil)
            }
            p.rounded(CGRect(x: -42, y: 8, width: 84, height: 8), 2, [0xF8E5B8, 0xBCB398])
            p.rounded(CGRect(x: -48, y: 16, width: 96, height: 7), 2, [0xEAE0BD, 0xA9B29E])
            for x: CGFloat in [-48, 48] { p.brazier(at: CGPoint(x: x, y: 9), size: 0.65) }
            p.flowers(at: CGPoint(x: -53, y: 18), size: 0.89)
            p.flowers(at: CGPoint(x: 54, y: 21), size: 0.78)
        }
    }
    private func rock(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            let v: [CGPoint] = [.init(x: -32, y: 1), .init(x: -29, y: -30), .init(x: -9, y: -49), .init(x: 15, y: -43), .init(x: 31, y: -20), .init(x: 27, y: 6), .init(x: 0, y: 12)]
            p.polygon(v, [0xE2D9BF, 0xB1BBAE, 0x7E9D9F])
            p.polygon([v[1], v[2], v[3], .init(x: 0, y: -18)], [0xEFE0BC, 0xC0C8B1])
            p.polygon([v[3], v[4], v[5], .init(x: 0, y: -18)], [0xB9C4B2, 0x78989D])
            p.line([.init(x: 0, y: -18), .init(x: 4, y: 6)], 0x6E8F93, 0.8, opacity: 0.7)
            p.line([v[1], v[2], v[3]], 0xF7EACA, 1, opacity: 0.8)
        }
    }
    private func leaf(from start: CGPoint, to end: CGPoint, width: CGFloat) {
        var p = Path(); p.move(to: start)
        let mid = CGPoint(x: (start.x + end.x) * 0.5, y: (start.y + end.y) * 0.5)
        p.addQuadCurve(to: end, control: .init(x: mid.x - width, y: mid.y - width))
        p.addQuadCurve(to: start, control: .init(x: mid.x + width, y: mid.y + width)); p.closeSubpath()
        material(p, [0xC3D394, 0x7AAA7E, 0x467E71])
        line([start, end], 0xDFE4AE, 0.6, opacity: 0.6)
    }
    private func flowers(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -31, y: -20, width: 62, height: 30), [0xB4CB91, 0x689E7D, 0x4D7E6B])
            for i in 0..<8 {
                let x = CGFloat((i * 13) % 49) - 24, y = -CGFloat((i * 7) % 19)
                p.leaf(from: .init(x: x, y: y + 5), to: .init(x: x + (i % 2 == 0 ? 10 : -10), y: y - 10), width: 4)
                let colors: [UInt32] = i % 3 == 0 ? [0xFFFFE8, 0xEAE6C1] : [0xFFD8C8, 0xECA2A2, 0xCE8699]
                for j in 0..<5 {
                    let a = Double(j) * .pi * 2 / 5
                    p.oval(CGRect(x: x + CGFloat(cos(a)) * 3 - 2.8, y: y + CGFloat(sin(a)) * 3 - 3, width: 5.6, height: 6), colors)
                }
                p.oval(CGRect(x: x - 1.3, y: y - 1.3, width: 2.6, height: 2.6), [0xFFF2BA, 0xDAB77C])
            }
        }
    }
    private func planter(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -14, y: -15, width: 28, height: 19), 5, [0xF9E8C3, 0xC9C1A4, 0x9DAE9A])
            p.rounded(CGRect(x: -18, y: -20, width: 36, height: 8), 3, [0xFFF5D8, 0xDBD2B2])
            p.line([.init(x: -8, y: -10), .init(x: -6, y: 0)], 0xFFF1CC, 1, opacity: 0.7)
            p.flowers(at: CGPoint(x: 0, y: -22), size: 0.92)
        }
    }
    private func ivy(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            var vine = Path(); vine.move(to: .zero)
            vine.addCurve(to: .init(x: -5, y: 82), control1: .init(x: -16, y: 24), control2: .init(x: 16, y: 51))
            p.context.stroke(vine, with: .color(Color(dinoHex: 0x6B9174)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            for i in 0..<11 {
                let y = CGFloat(i) * 7, x = CGFloat(sin(Double(i) * 0.7)) * 5
                p.leaf(from: .init(x: x, y: y), to: .init(x: x + (i % 2 == 0 ? -11 : 10), y: y - 8), width: 4.8)
                if i % 4 == 0 { p.oval(CGRect(x: x - 6, y: y - 4, width: 4, height: 4), [0xFFFBE0, 0xE7D7C0]) }
            }
        }
    }
    private func cypress(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -4, y: -27, width: 8, height: 33), 3, [0xB8A67B, 0x817D5D])
            var tree = Path(); tree.move(to: .init(x: 0, y: -113))
            tree.addCurve(to: .init(x: 17, y: -20), control1: .init(x: 10, y: -110), control2: .init(x: 26, y: -40))
            tree.addQuadCurve(to: .init(x: -17, y: -20), control: .init(x: 0, y: -5))
            tree.addCurve(to: .init(x: 0, y: -113), control1: .init(x: -28, y: -39), control2: .init(x: -10, y: -108)); tree.closeSubpath()
            p.material(tree, [0xB9CD99, 0x7CA284, 0x4F7A70])
            for i in 0..<17 {
                let y = -97 + CGFloat(i) * 4.5, x = CGFloat((i * 7) % 19) - 9
                p.line([.init(x: x - 2, y: y + 2), .init(x: x, y: y), .init(x: x + 2, y: y + 2)], 0xD3DBA9, 0.9, opacity: 0.45)
            }
            p.flowers(at: CGPoint(x: 0, y: 4), size: 0.57)
        }
    }
    private func crystals(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for (x, y, h): (CGFloat, CGFloat, CGFloat) in [(-13, 0, 26), (0, -3, 40), (13, 2, 28)] {
                p.polygon([.init(x: x - 7, y: y), .init(x: x - 8, y: y - h * 0.68), .init(x: x, y: y - h), .init(x: x + 8, y: y - h * 0.6), .init(x: x + 5, y: y + 2)], [0xEEFFFF, 0xA5D6E6, 0x7B9CCF])
                p.line([.init(x: x, y: y - h), .init(x: x, y: y)], 0xFFFFFF, 0.8, opacity: 0.85)
            }
            p.glow(.init(x: 0, y: -16), radius: 31, color: 0xC2FFFF, opacity: 0.15)
        }
    }
    private func waterfall(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rock(at: CGPoint(x: -19, y: 10), size: 0.96)
            p.rock(at: CGPoint(x: 25, y: 16), size: 0.78)
            var water = Path(); water.move(to: .init(x: -13, y: -57)); water.addLine(to: .init(x: 14, y: -57))
            water.addCurve(to: .init(x: 20, y: 36), control1: .init(x: 17, y: -30), control2: .init(x: 7, y: 8))
            water.addLine(to: .init(x: -22, y: 36))
            water.addCurve(to: .init(x: -13, y: -57), control1: .init(x: -9, y: 6), control2: .init(x: -16, y: -30)); water.closeSubpath()
            p.material(water, [0xE4FFF4, 0x97DFE1, 0x68B5D1, 0xC3E9DD])
            for i in 0..<5 {
                let x = CGFloat(i) * 5 - 10
                var stream = Path(); stream.move(to: .init(x: x, y: -53))
                stream.addCurve(to: .init(x: x + 2, y: 30), control1: .init(x: x + 5, y: -28), control2: .init(x: x - 4, y: 7))
                p.context.stroke(stream, with: .color(Color(dinoHex: 0xF8FFFF).opacity(0.85)), style: StrokeStyle(lineWidth: i % 2 == 0 ? 1.7 : 0.8, lineCap: .round))
            }
            p.oval(CGRect(x: -38, y: 26, width: 78, height: 23), [0xEBFFF0, 0xA5DCD9, 0x70B9CA])
            for i in 0..<6 { p.oval(CGRect(x: CGFloat(i) * 11 - 31, y: 28 + CGFloat(i % 3) * 3, width: 12, height: 4), [0xFCFFF0, 0xC2EADB]) }
            p.flowers(at: CGPoint(x: 29, y: 16), size: 0.63)
        }
    }
    private func brazier(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.masonry(CGRect(x: -9, y: -24, width: 18, height: 27))
            p.oval(CGRect(x: -14, y: -31, width: 28, height: 11), [0xFFE8A6, 0xCCAC70, 0xA28F66])
            p.glow(.init(x: 0, y: -39), radius: 29, color: 0xFFDF99, opacity: 0.35)
            var flame = Path(); flame.move(to: .init(x: -7, y: -28))
            flame.addQuadCurve(to: .init(x: 0, y: -53), control: .init(x: -13, y: -40))
            flame.addQuadCurve(to: .init(x: 7, y: -28), control: .init(x: 14, y: -36)); flame.closeSubpath()
            p.material(flame, [0xFFFFCC, 0xFFE5A1, 0xE7B172])
            p.oval(CGRect(x: -2, y: -38, width: 4, height: 10), [0xFFFFEA, 0xFFF0BA])
        }
    }
    private func fountain(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -52, y: -17, width: 104, height: 34), [0xF7E7BF, 0xC5C4AA, 0xA2B6A7])
            p.oval(CGRect(x: -45, y: -13, width: 90, height: 25), [0xD8FFF0, 0x9BD7D8, 0x6FB8CD])
            p.rounded(CGRect(x: -9, y: -54, width: 18, height: 48), 5, [0xFFF0C6, 0xD5C8A6, 0xABB59F])
            p.oval(CGRect(x: -33, y: -35, width: 66, height: 19), [0xFFF0CB, 0xC4C8B0, 0x91AAA3])
            p.oval(CGRect(x: -28, y: -35, width: 56, height: 11), [0xE7FFF0, 0x8DD3D8])
            p.oval(CGRect(x: -21, y: -62, width: 42, height: 12), [0xFFEACA, 0xB8C2AE])
            p.oval(CGRect(x: -17, y: -62, width: 34, height: 7), [0xDCFFF0, 0x8DCCD4])
            p.oval(CGRect(x: -5, y: -80, width: 10, height: 16), [0xFFF0B5, 0xCBA96C])
            for side: CGFloat in [-1, 1] {
                for i in 0..<3 {
                    let spout = -79 + CGFloat(i) * 13
                    var water = Path(); water.move(to: .init(x: 0, y: spout))
                    water.addQuadCurve(to: .init(x: side * CGFloat(27 + i * 7), y: -6), control: .init(x: side * CGFloat(22 + i * 5), y: spout + (-6 - spout) * 0.42))
                    p.context.stroke(water, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xF3FFFF), Color(dinoHex: 0x89D4DC)]), startPoint: .init(x: 0, y: -79), endPoint: .zero), style: StrokeStyle(lineWidth: i == 0 ? 1.7 : 1, lineCap: .round))
                }
            }
            for i in 0..<7 {
                let x = CGFloat(i) * 12 - 37
                p.line([.init(x: x, y: 1), .init(x: x + 7, y: 2)], 0xF3FFF0, 1, opacity: 0.9)
            }
        }
    }
    private func bridge(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -56, y: 6, width: 114, height: 35), [0xB5E5DC, 0x74BDCF])
            var wall = Path(); wall.addRoundedRect(in: CGRect(x: -54, y: -16, width: 108, height: 53), cornerSize: CGSize(width: 7, height: 7))
            wall.addRoundedRect(in: CGRect(x: -22, y: 9, width: 44, height: 44), cornerSize: CGSize(width: 22, height: 22))
            var facade = p.context
            facade.clip(to: Path(roundedRect: CGRect(x: -54, y: -16, width: 108, height: 53), cornerRadius: 7))
            facade.fill(wall, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xF9E9C6), Color(dinoHex: 0xD1C8AD), Color(dinoHex: 0x98AFA7)]), startPoint: .init(x: -54, y: -16), endPoint: .init(x: 54, y: 37)), style: FillStyle(eoFill: true))
            var arch = Path(); arch.move(to: .init(x: -25, y: 35))
            arch.addCurve(to: .init(x: 25, y: 35), control1: .init(x: -28, y: -6), control2: .init(x: 28, y: -6))
            p.context.stroke(arch, with: .color(Color(dinoHex: 0xFFF2CC)), lineWidth: 6)
            p.polygon([.init(x: -56, y: -19), .init(x: 42, y: -28), .init(x: 57, y: -8), .init(x: -42, y: 4)], [0xF7E7BF, 0xDBCEA8])
            for i in 0..<7 {
                let x = CGFloat(i) * 14 - 45
                p.line([.init(x: x, y: -17 - CGFloat(i)), .init(x: x + 11, y: -2 - CGFloat(i))], 0xC0BA9C, 0.8)
            }
            p.line([.init(x: -49, y: -14), .init(x: 46, y: -24)], 0xFFF3D5, 3)
            for x: CGFloat in [-43, 42] {
                p.masonry(CGRect(x: x - 7, y: -43, width: 14, height: 33))
                p.rounded(CGRect(x: x - 10, y: -47, width: 20, height: 7), 2, [0xFFF0CF, 0xCFC5A6])
                p.oval(CGRect(x: x - 5, y: -58, width: 10, height: 12), [0xFFF0B2, 0xD3AE6D])
            }
            p.planter(at: CGPoint(x: -43, y: -47), size: 0.63)
            p.flowers(at: CGPoint(x: 43, y: -45), size: 0.51)
        }
    }
    private func pavilion(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.terrace(width: 111)
            p.oval(CGRect(x: -45, y: -13, width: 90, height: 26), [0xDEF9E5, 0xA3D5D1, 0x7AB8C8])
            for x: CGFloat in [-25, 25] { p.rounded(CGRect(x: x - 3, y: -101, width: 6, height: 85), 2, [0xF6E9C5, 0xB7B99F]) }
            var glass = Path(); glass.addLines([.init(x: -14, y: -82), .init(x: 14, y: -82), .init(x: 13, y: -67), .init(x: 3, y: -53), .init(x: 14, y: -36), .init(x: 14, y: -24), .init(x: -14, y: -24), .init(x: -14, y: -36), .init(x: -3, y: -53), .init(x: -14, y: -67)]); glass.closeSubpath()
            p.material(glass, [0xE9FFFF, 0xA5DCE0, 0xB8DBD2])
            p.polygon([.init(x: -11, y: -76), .init(x: 11, y: -76), .init(x: 0, y: -55)], [0xFFF0B9, 0xE5C17C])
            p.polygon([.init(x: -12, y: -27), .init(x: 0, y: -42), .init(x: 12, y: -27)], [0xFFF2BF, 0xDCB774])
            p.line([.init(x: 0, y: -54), .init(x: 0, y: -42)], 0xFFE4A5, 1)
            p.line([.init(x: -10, y: -74), .init(x: -9, y: -67), .init(x: -3, y: -57)], 0xFFFFFF, 1.3, opacity: 0.8)
            for y: CGFloat in [-86, -25] { p.rounded(CGRect(x: -20, y: y, width: 40, height: 6), 2, [0xFFE8AC, 0xC8A96E]) }
            for x: CGFloat in [-36, 36] {
                p.rounded(CGRect(x: x - 4, y: -103, width: 8, height: 92), 3, [0xFFF0CF, 0xD7CFAC, 0xB0B8A1])
                for y: CGFloat in [-105, -17] { p.rounded(CGRect(x: x - 7, y: y, width: 14, height: 6), 2, [0xFFF1D0, 0xD6C5A0]) }
            }
            var dome = Path(); dome.move(to: .init(x: -44, y: -106))
            dome.addCurve(to: .init(x: 44, y: -106), control1: .init(x: -40, y: -163), control2: .init(x: 40, y: -163)); dome.closeSubpath()
            p.material(dome, [0xB0C6DA, 0x7393BE, 0x42669D])
            for x: CGFloat in [-22, 0, 22] {
                var rib = Path(); rib.move(to: .init(x: 0, y: -149))
                rib.addQuadCurve(to: .init(x: x, y: -107), control: .init(x: x * 0.75, y: -136))
                p.context.stroke(rib, with: .color(Color(dinoHex: 0xEED296)), lineWidth: 1.5)
            }
            p.rounded(CGRect(x: -46, y: -108, width: 92, height: 8), 3, [0xFFE8AA, 0xCEAF73])
            p.oval(CGRect(x: -6, y: -164, width: 12, height: 15), [0xFFF1B8, 0xCBA76A])
            p.ivy(at: CGPoint(x: -35, y: -104), size: 0.89)
            p.flowers(at: CGPoint(x: 34, y: 5), size: 0.71)
        }
    }
    func scene(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size, radius: 74 * size, rise: 135 * size) { p in
            p.terrace(width: 148)
            if variation == 8 {
                p.gate(at: CGPoint(x: 0, y: -5), size: 0.92)
            } else {
                switch variation % 4 {
                case 0:
                    p.tower(at: CGPoint(x: 0, y: -8), size: 0.94, time: .init(hour: variation == 0 ? 10 : 16, minute: variation == 0 ? 25 : 40))
                    p.planter(at: CGPoint(x: 44, y: 13), size: 0.79)
                    p.brazier(at: CGPoint(x: -48, y: 9), size: 0.75)
                case 1:
                    p.cypress(at: CGPoint(x: -42, y: -4), size: 0.92)
                    p.cypress(at: CGPoint(x: 40, y: -4), size: 0.78)
                    p.fountain(at: CGPoint(x: 0, y: -1), size: 0.98)
                    p.planter(at: CGPoint(x: -48, y: 15), size: 0.67)
                case 2:
                    p.cypress(at: CGPoint(x: 38, y: -11), size: 0.98)
                    p.bridge(at: CGPoint(x: -2, y: 0), size: 1.0)
                    p.banner(at: CGPoint(x: -31, y: -55), size: 0.60)
                    p.crystals(at: CGPoint(x: 41, y: 16), size: 0.67)
                default:
                    p.pavilion(at: CGPoint(x: -3, y: -7), size: 0.94)
                    p.planter(at: CGPoint(x: 45, y: 12), size: 0.70)
                }
            }
            p.flowers(at: CGPoint(x: -51, y: 16), size: 0.73)
            p.flowers(at: CGPoint(x: 45, y: 21), size: 0.61)
        }
    }
}

/// All scenery is native Canvas geometry. Generated concepts are documentation only.
struct ThemedWorldLandscape: View, Equatable {
    let world: DinoWorld
    var routeOffset: CGFloat = 180
    var viewportHeight: CGFloat = 900

    var body: some View {
        Canvas { context, size in
            let depth = WorldSceneryDepth()
            if world.id == 2 {
                SleepValleyPainter(context: context, animatedWillows: true).landscape(in: size, routeOffset: routeOffset, depth: depth)
                var routeContext = context
                routeContext.translateBy(x: 0, y: routeOffset)
                let boss = ThemePainter(context: routeContext, colors: WorldThemeColors(world))
                let scale = min(1.30, max(0.82, size.width / 390))
                let right = size.width
                let point = CGPoint(x: right - 79 * scale, y: 1675)
                depth.add(at: routeOffset + point.y) {
                    boss.bossClearing(worldID: 2, at: point, size: scale)
                    boss.boss(worldID: 2, at: point, size: scale * 0.88)
                }
                depth.draw()
                return
            }
            if world.id == 3 {
                VolcanoWorldPainter(context: context).landscape(in: size, routeOffset: routeOffset, depth: depth)
                var routeContext = context
                routeContext.translateBy(x: 0, y: routeOffset)
                let boss = ThemePainter(context: routeContext, colors: WorldThemeColors(world))
                let scale = min(1.30, max(0.82, size.width / 390))
                let right = size.width
                let point = CGPoint(x: right - 79 * scale, y: 1675)
                depth.add(at: routeOffset + point.y) {
                    boss.bossClearing(worldID: 3, at: point, size: scale)
                    boss.boss(worldID: 3, at: point, size: scale * 0.88)
                }
                depth.draw()
                return
            }
            if world.id == 4 {
                VillageWorldPainter(context: context).landscape(in: size, routeOffset: routeOffset, depth: depth)
                var routeContext = context
                routeContext.translateBy(x: 0, y: routeOffset)
                let boss = ThemePainter(context: routeContext, colors: WorldThemeColors(world))
                let scale = min(1.30, max(0.82, size.width / 390))
                let right = size.width
                let point = CGPoint(x: right - 79 * scale, y: 1675)
                depth.add(at: routeOffset + point.y) {
                    boss.bossClearing(worldID: 4, at: point, size: scale)
                    boss.boss(worldID: 4, at: point, size: scale * 0.88)
                }
                depth.draw()
                return
            }
            if world.id == 5 {
                CrystalCavePainter(context: context, hangingLamps: false).landscape(in: size, routeOffset: routeOffset)
                return
            }
            if world.id == 6 {
                CityWorldPainter(context: context).landscape(in: size, routeOffset: routeOffset, depth: depth)
                var routeContext = context
                routeContext.translateBy(x: 0, y: routeOffset)
                let boss = ThemePainter(context: routeContext, colors: WorldThemeColors(world))
                let scale = min(1.30, max(0.82, size.width / 390))
                let point = CGPoint(x: size.width - 79 * scale, y: 1675)
                depth.add(at: routeOffset + point.y) {
                    boss.boss(worldID: 6, at: point, size: scale * 0.88)
                }
                depth.draw()
                return
            }
            if world.id == 7 {
                DayNightForestPainter(context: context).landscape(in: size, routeOffset: routeOffset, depth: depth)
                var routeContext = context
                routeContext.translateBy(x: 0, y: routeOffset)
                let boss = ThemePainter(context: routeContext, colors: WorldThemeColors(world))
                let scale = min(1.30, max(0.82, size.width / 390))
                let point = CGPoint(x: size.width - 79 * scale, y: 1675)
                depth.add(at: routeOffset + point.y) {
                    boss.bossClearing(worldID: 7, at: point, size: scale)
                    boss.boss(worldID: 7, at: point, size: scale * 0.88)
                }
                depth.draw()
                return
            }
            if world.id == 8 {
                TimeMachinePainter(context: context).landscape(in: size, routeOffset: routeOffset, depth: depth)
                var routeContext = context
                routeContext.translateBy(x: 0, y: routeOffset)
                let boss = ThemePainter(context: routeContext, colors: WorldThemeColors(world))
                let scale = min(1.30, max(0.82, size.width / 390))
                let point = CGPoint(x: size.width - 79 * scale, y: 1675)
                depth.add(at: routeOffset + point.y) {
                    boss.bossClearing(worldID: 8, at: point, size: scale)
                    boss.boss(worldID: 8, at: point, size: scale * 0.88)
                }
                depth.draw()
                return
            }
            if world.id == 9 {
                PirateCoastPainter(context: context).landscape(in: size, routeOffset: routeOffset, depth: depth)
                var routeContext = context
                routeContext.translateBy(x: 0, y: routeOffset)
                let boss = ThemePainter(context: routeContext, colors: WorldThemeColors(world))
                let scale = min(1.30, max(0.82, size.width / 390))
                let point = CGPoint(x: size.width - 79 * scale, y: 1675)
                depth.add(at: routeOffset + point.y) {
                    boss.bossClearing(worldID: 9, at: point, size: scale)
                    boss.boss(worldID: 9, at: point, size: scale * 0.88)
                }
                depth.draw()
                return
            }
            if world.id == 10 {
                CastleWorldPainter(context: context).landscape(in: size, routeOffset: routeOffset, depth: depth)
                var routeContext = context
                routeContext.translateBy(x: 0, y: routeOffset)
                let boss = ThemePainter(context: routeContext, colors: WorldThemeColors(world))
                let scale = min(1.30, max(0.82, size.width / 390))
                let point = CGPoint(x: size.width - 79 * scale, y: 1675)
                depth.add(at: routeOffset + point.y) {
                    boss.bossClearing(worldID: 10, at: point, size: scale)
                    boss.boss(worldID: 10, at: point, size: scale * 0.88)
                }
                depth.draw()
                return
            }
            let colors = WorldThemeColors(world)
            let w = size.width
            let left: CGFloat = 0
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
                stops = [.init(color: ground, location: 0),
                         .init(color: Color(dinoHex: 0xF1E8B7), location: 0.10),
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
                    let positions = WorldRouteTrail.chapterPositions
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
            let bossPoint = CGPoint(x: right - 79 * scale, y: 1675)
            context.fill(Path(CGRect(x: 0, y: size.height - 180, width: w, height: 180)),
                         with: .linearGradient(Gradient(colors: [Color(dinoHex: nextGround).opacity(0), Color(dinoHex: nextGround)]),
                                               startPoint: CGPoint(x: 0, y: size.height - 180),
                                               endPoint: CGPoint(x: 0, y: size.height)))
            p.bossClearing(worldID: world.id, at: bossPoint, size: scale)
            p.boss(worldID: world.id, at: bossPoint, size: scale * 0.88)
        }.clipped()
            .overlay {
                if world.id == 2 { SleepValleyLife(routeOffset: routeOffset, viewportHeight: viewportHeight) }
                if world.id == 3 { VolcanoWorldLife(routeOffset: routeOffset, viewportHeight: viewportHeight) }
                if world.id == 5 { CrystalCaveLife(routeOffset: routeOffset, viewportHeight: viewportHeight) }
            }
            .overlay(alignment: .top) {
                if world.id == 3 {
                    WorldTerrainTransition(worldID: 3, entering: true).equatable()
                        .mask(VolcanoInletOpening(routeOffset: routeOffset))
                } else if world.id != 5 && world.id != 6 {
                    WorldTerrainTransition(worldID: world.id, entering: true).equatable()
                }
            }
            .overlay(alignment: .bottom) {
                if world.id != 4 && world.id != 5 { WorldTerrainTransition(worldID: min(10, world.id + 1)).equatable() }
            }
            .overlay(alignment: .bottom) {
                if world.id == 2 {
                    SleepVolcanoInlet(routeOffset: routeOffset, viewportHeight: viewportHeight, sectionStart: -220)
                        .frame(height: 220)
                }
            }
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Shape-only art for the boss start card and the next-world reward.
struct WorldThemePreview: View {
    let world: DinoWorld
    var body: some View {
        Canvas { context, size in
            let colors = WorldThemeColors(world)
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(dinoHex: colors.ground)))
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                Gradient(colors: [.white.opacity(0.25), Color(dinoHex: colors.shade).opacity(0.08)]),
                startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
            let p = ThemePainter(context: context, colors: colors)
            let heightUnits: CGFloat = [8, 10].contains(world.id) ? 218 : 195
            let scale = min(size.height / heightUnits, size.width / 290)
            p.scene(worldID: world.id, at: CGPoint(x: size.width * 0.21, y: size.height * 0.87),
                    size: scale * 1.12, variation: 0)
            p.bossClearing(worldID: world.id, at: CGPoint(x: size.width * 0.71, y: size.height * 0.92), size: scale)
            p.boss(worldID: world.id, at: CGPoint(x: size.width * 0.70, y: size.height * 0.94), size: scale)
        }.allowsHitTesting(false)
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
            case 1:
                let jungle = JunglePainter(context: p.context)
                jungle.tree(at: CGPoint(x: -17, y: -2), size: 0.53, leaning: 1)
                jungle.rocks(at: CGPoint(x: 23, y: 9), size: 0.55)
                jungle.fern(at: CGPoint(x: 32, y: 23), size: 0.52, flipped: true)
                jungle.vine(from: CGPoint(x: -30, y: -131), length: 97, bend: 17)
            case 2:
                SleepValleyPainter(context: p.context).garden(at: .zero, size: 0.8, variation: variation)
            case 3:
                VolcanoWorldPainter(context: p.context).scene(at: .zero, size: 0.9, variation: variation)
            case 4:
                VillageWorldPainter(context: p.context).scene(at: .zero, size: 0.9, variation: variation)
            case 5:
                CrystalCavePainter(context: p.context).scene(at: .zero, size: 0.9, variation: variation)
            case 6:
                CityWorldPainter(context: p.context).scene(at: .zero, size: 0.9, variation: variation)
            case 7:
                DayNightForestPainter(context: p.context, night: variation > 3 ? 1 : 0)
                    .scene(at: .zero, size: 0.9, variation: variation)
            case 8:
                TimeMachinePainter(context: p.context).scene(at: .zero, size: 0.9, variation: variation)
            case 9:
                PirateCoastPainter(context: p.context).scene(at: .zero, size: 0.9, variation: variation)
            default:
                CastleWorldPainter(context: p.context).scene(at: .zero, size: 0.9, variation: variation)
            }
        }
    }

    func edgeGarden(worldID: Int, at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            p.gardenPatch(at: CGPoint(x: 0, y: 9), width: 168, color: p.colors.distant)
            switch worldID {
            case 2:
                p.tree(at: CGPoint(x: -8, y: -8), size: 1.03, night: true, willow: true, variation: variation + 1)
                p.pond(at: CGPoint(x: 29, y: 17), size: 0.50, lava: false)
                p.blossoms(at: CGPoint(x: 34, y: 24), size: 0.6, color: 0xDAB9DE)
            case 3:
                p.rock(at: CGPoint(x: -18, y: -2), size: 1.25, color: 0x887F8D)
                p.rock(at: CGPoint(x: 28, y: 7), size: 0.78, color: 0xA89391)
                p.glow(at: CGPoint(x: 15, y: 16), radius: 30, color: 0xFFD88B, opacity: 0.22)
                p.sprig(at: CGPoint(x: 5, y: 18), size: 0.9, color: 0xC19174)
            case 4, 10:
                p.tree(at: CGPoint(x: -9, y: -2), size: 0.77, night: false, willow: false, variation: variation)
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
                p.tree(at: CGPoint(x: -5, y: -4), size: 1.12, night: variation > 3, willow: false, variation: variation + 1)
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
            if [1, 2, 4, 7, 10].contains(worldID) {
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
    private func tree(at point: CGPoint, size: CGFloat, night: Bool, willow: Bool, variation: Int = 0) {
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
                let x = CGFloat(i - 2) * 21, y: CGFloat = -128 - CGFloat((i + variation) % 3) * 8
                let r = CGRect(x: x - 26, y: y, width: 55, height: willow ? 58 : 47)
                let crown = JunglePainter(context: p.context).foliagePath(in: r)
                p.material(crown, rect: r, color: leaf)
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
            for i in 0..<19 {
                let x = CGFloat((i * 19 + variation * 7) % 101 - 50), y = CGFloat((i * 13) % 33 - 121)
                JunglePainter(context: p.context).leaf(at: CGPoint(x: x, y: y), length: 8 + CGFloat(i % 3) * 2, width: 3,
                    angle: Double(i * 29), color: i.isMultiple(of: 3) ? .white.opacity(0.27) : p.tint(leaf, toward: 0x446A5D, amount: 0.18))
            }
            for i in 0..<3 {
                var bark = Path()
                let x = CGFloat(i) * 5 - 5
                bark.move(to: CGPoint(x: x, y: -61 + CGFloat(i) * 8))
                bark.addQuadCurve(to: CGPoint(x: x - 3, y: -9), control: CGPoint(x: x + 6, y: -31))
                p.context.stroke(bark, with: .color(Color(dinoHex: 0xD9C7A6).opacity(0.55)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
            }
            p.ellipse(CGRect(x: -1, y: -37, width: 4, height: 7), 0x6F817D, opacity: 0.30)
            p.sprig(at: CGPoint(x: -21, y: 9), size: 0.5, color: leaf)
        }
    }
    private func rock(at point: CGPoint, size: CGFloat, color: UInt32, variation: Int = 0) {
        at(point, size: size) { p in
            p.shadow(width: 71)
            let skew = CGFloat(variation % 3 - 1) * 5
            let vertices = [CGPoint(x: -37, y: -3), CGPoint(x: -32 + skew, y: -28), CGPoint(x: -12 - skew, y: -49),
                            CGPoint(x: 17 + skew, y: -43 - skew), CGPoint(x: 34, y: -21), CGPoint(x: 29, y: 0), CGPoint(x: 4, y: 6)]
            var path = Path()
            path.addLines(vertices); path.closeSubpath()
            p.material(path, rect: CGRect(x: -37, y: -49, width: 71, height: 55), color: color)
            p.polygon([vertices[2], vertices[3], CGPoint(x: 7, y: -20), vertices[1]], color: 0xFFFFFF, opacity: 0.15)
            p.polygon([vertices[3], vertices[4], vertices[5], CGPoint(x: 7, y: -20)], color: p.colors.shade, opacity: 0.15)
            p.line([CGPoint(x: -17, y: -13), CGPoint(x: -4, y: -18), CGPoint(x: 5, y: -13)], color: p.colors.shade, width: 1)
            p.line([vertices[1], vertices[2], vertices[3]], color: 0xE6EBDD, width: 0.9)
            for i in 0..<5 {
                let x = CGFloat((i * 11 + variation * 7) % 40 - 21), y = CGFloat((i * 7) % 19 - 25)
                p.ellipse(CGRect(x: x, y: y, width: 1.8, height: 1.4), 0xEDF4DD, opacity: 0.27)
            }
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
            .init(color: tint(color, toward: 0xFFFFFF, amount: 0.30), location: 0),
            .init(color: Color(dinoHex: color), location: 0.48),
            .init(color: tint(color, toward: colors.shade, amount: 0.28), location: 1)
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
        context.fill(Path(ellipseIn: rect), with: .radialGradient(Gradient(stops: [
            .init(color: tint(color, toward: 0xFFFFFF, amount: 0.33), location: 0),
            .init(color: Color(dinoHex: color), location: 0.48),
            .init(color: tint(color, toward: colors.shade, amount: 0.30), location: 1)
        ]), center: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY + rect.height * 0.22),
             startRadius: 0, endRadius: max(rect.width, rect.height) * 0.85))
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
            for i in 0..<5 {
                let x = CGFloat(i) * 17 - 43, y = CGFloat(i % 2) * 9 - 16
                var ripple = Path()
                ripple.move(to: CGPoint(x: x, y: y))
                ripple.addQuadCurve(to: CGPoint(x: x + 13, y: y), control: CGPoint(x: x + 6, y: y + 2.5))
                p.context.stroke(ripple, with: .color(Color(dinoHex: lava ? 0xFFE4AD : 0xDBF4E7).opacity(0.60)),
                                 style: StrokeStyle(lineWidth: 1, lineCap: .round))
            }
            if !lava {
                p.volume(CGRect(x: -29, y: -14, width: 17, height: 7), color: 0x91B97E)
                p.polygon([CGPoint(x: -21, y: -12), CGPoint(x: -15, y: -15), CGPoint(x: -15, y: -9)], color: 0xB5E3C8)
                p.blossoms(at: CGPoint(x: -21, y: -12), size: 0.24, color: 0xE3BCCF)
                for i in 0..<4 {
                    let x = CGFloat(i) * 6 - 54
                    p.line([CGPoint(x: x, y: -1), CGPoint(x: x + 3, y: -18 - CGFloat(i % 2) * 9)], color: 0x88A78F, width: 1.3)
                }
            }
        }
    }
    func crystals(at point: CGPoint, size: CGFloat, variation: Int = 0) {
        at(point, size: size) { p in
            p.shadow(width: 96)
            for (index, data) in [(-26.0, 48.0), (0.0, 76.0), (25.0, 54.0)].enumerated() {
                let x = CGFloat(data.0), h = CGFloat(data.1) * (1 + CGFloat((variation + index) % 3 - 1) * 0.16)
                let tint: UInt32 = index == 1 ? 0xA493D7 : index == 0 ? 0x79D8D0 : 0xF1BCD9
                p.polygon([CGPoint(x: x - 13, y: -h * 0.70), CGPoint(x: x, y: -h), CGPoint(x: x + 15, y: -h * 0.72),
                           CGPoint(x: x + 12, y: -6), CGPoint(x: x, y: 0), CGPoint(x: x - 12, y: -8)], color: tint)
                p.polygon([CGPoint(x: x, y: -h), CGPoint(x: x + 15, y: -h * 0.72), CGPoint(x: x + 12, y: -6), CGPoint(x: x, y: 0)],
                          color: p.colors.shade, opacity: 0.23)
                p.polygon([CGPoint(x: x - 13, y: -h * 0.70), CGPoint(x: x, y: -h),
                           CGPoint(x: x, y: -h * 0.55)], color: 0xFFFFFF, opacity: 0.24)
                p.line([CGPoint(x: x - 11, y: -h * 0.69), CGPoint(x: x, y: -h + 2), CGPoint(x: x + 13, y: -h * 0.71)], color: 0xEDFFF0, width: 0.8)
                p.line([CGPoint(x: x - 10, y: -11), CGPoint(x: x, y: -5), CGPoint(x: x + 10, y: -9)], color: 0xF1F5E8, width: 0.8)
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
    func building(at point: CGPoint, size: CGFloat, city: Bool, tower: Bool = false, variation: Int = 0) {
        at(point, size: size) { p in
            let h: CGFloat = tower ? (city ? 154 : 123) : city ? 110 : 77
            p.shadow()
            p.rounded(CGRect(x: -36, y: -h, width: 72, height: h), radius: city ? 15 : 28,
                      color: city ? 0xA9DAE3 : [UInt32(0xF0DFBA), 0xF3E2C5, 0xE6D9BC][variation % 3])
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
            for x: CGFloat in [-6, 0, 6] { p.line([CGPoint(x: x, y: -22), CGPoint(x: x, y: -5)], color: 0xC4A17A, width: 0.7) }
            p.rounded(CGRect(x: -16, y: -1, width: 32, height: 5), radius: 2, color: 0xDED0B2)
            p.rounded(CGRect(x: 25, y: -29, width: 8, height: 11), radius: 3, color: 0xC7A579)
            p.rounded(CGRect(x: 27, y: -27, width: 4, height: 6), radius: 1, color: 0xFFEDB1)
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
            if !city && !tower {
                p.ellipse(CGRect(x: -6, y: -h - 12, width: 12, height: 10), 0xFFF0BF)
                p.line([CGPoint(x: 0, y: -h - 12), CGPoint(x: 0, y: -h - 2)], color: 0xD4B88A, width: 1)
                p.line([CGPoint(x: -5, y: -h - 7), CGPoint(x: 5, y: -h - 7)], color: 0xD4B88A, width: 1)
                p.planter(at: CGPoint(x: -24, y: -28), size: 0.38, flowers: true)
                for x: CGFloat in [-28, 32] { p.rounded(CGRect(x: x, y: -56, width: 5, height: 23), radius: 2, color: 0xA2B78E) }
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

    func boss(worldID: Int, at point: CGPoint, size: CGFloat) {
        WorldBossPainter(context: context).draw(worldID: worldID, at: point, size: size)
    }
}
