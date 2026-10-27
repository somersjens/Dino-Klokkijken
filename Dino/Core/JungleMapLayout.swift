import Foundation
import CoreGraphics

/// One rhythm for all nine chapter joins, including the jungle's different entry.
enum WorldMapChapterSpacing {
    static let bannerTop: CGFloat = 12
    static let bannerHeight: CGFloat = 212
    static let bannerCenter: CGFloat = 99.5
    static let bannerBottom: CGFloat = 10
    static let firstNode: CGFloat = 80

    static func routeOffset(clearance: CGFloat) -> CGFloat {
        bannerTop + bannerHeight + bannerBottom + clearance
    }

    static func tail(clearance: CGFloat) -> CGFloat {
        let below = bannerHeight - bannerCenter + bannerBottom + clearance + firstNode
        return below + 9 - bannerTop - bannerCenter
    }

    static func routeHeight(clearance: CGFloat) -> CGFloat {
        firstNode + 9 * JungleMapLayout.levelSpacing + tail(clearance: clearance)
    }

    static func sceneSize(width: CGFloat) -> CGSize {
        let clearance = max(0, min(200, (min(600, width) - 36) * 0.37) - 82)
        return CGSize(width: width, height: routeOffset(clearance: clearance) + routeHeight(clearance: clearance))
    }

    static func sceneOffset(width: CGFloat) -> CGFloat {
        routeOffset(clearance: max(0, min(200, (min(600, width) - 36) * 0.37) - 82))
    }
}

/// A destination beside the final stone, measured from the route instead of
/// the screen edge. Its full silhouette is also reserved by scenery planners.
struct WorldBossStage {
    let worldID: Int
    let width: CGFloat
    var scale: CGFloat { min(worldID == 1 ? 1.35 : 1.30, max(0.82, width / 390)) }
    var point: CGPoint {
        let offset: CGFloat = [4, 6, 10].contains(worldID) ? 116 : worldID == 8 ? 120 : 124
        return CGPoint(x: width / 2 + offset * scale, y: worldID == 1 ? 1665 : 1690)
    }
    var clearance: CGRect {
        let rise: CGFloat = worldID == 1 ? 160 : 190
        return CGRect(x: point.x - 80 * scale, y: point.y - rise * scale,
                      width: 160 * scale, height: (rise + 40) * scale)
    }
    var ground: CGRect {
        CGRect(x: point.x - 61 * scale, y: point.y - 9 * scale,
               width: 122 * scale, height: 39 * scale)
    }
}

enum DinoMapViewport {
    /// Prepare actors before they enter view; keep them a little longer on exit
    /// so small back-and-forth drags do not recreate their static masks.
    static func preparesAnimation(frame: CGRect, viewportHeight: CGFloat, retained: Bool = false) -> Bool {
        let margin: CGFloat = retained ? 512 : 256
        return frame.width > 0 && frame.height > 0 &&
            frame.maxY > -margin && frame.minY < viewportHeight + margin
    }

    static func preparedAnimationBounds(frame: CGRect, viewportHeight: CGFloat) -> CGRect {
        animationBounds(frame: frame.offsetBy(dx: 0, dy: 256), viewportHeight: viewportHeight + 512)
    }
    /// Round outwards to small bands: moving boats/workers remain visible,
    /// while their SwiftUI subtree no longer rebuilds for every scroll pixel.
    static func animationBounds(frame: CGRect, viewportHeight: CGFloat) -> CGRect {
        let top = max(0, -frame.minY)
        let bottom = min(frame.height, viewportHeight - frame.minY)
        guard bottom > top, frame.width > 0 else { return .zero }
        let band: CGFloat = 256
        let start = floor(top / band) * band
        let end = min(frame.height, ceil(bottom / band) * band)
        return CGRect(x: 0, y: start, width: frame.width, height: end - start)
    }
}

/// Positions the complete silhouettes beside the actual cubic trail. Art can
/// overlap other scenery, but crowns, roots and pools keep clear of the road.
struct JungleMapLayout {
    static let levelSpacing: CGFloat = 175
    static let firstNodeY: CGFloat = 70
    static let chapterPositions: [CGFloat] = [0.28, 0.5, 0.72, 0.5, 0.28, 0.5, 0.72, 0.5, 0.28, 0.5]
    /// A broad right bend opens into a longer left sweep, then returns to centre.
    static let levelPositions: [CGFloat] = [0.5, 0.67, 0.72, 0.59, 0.38, 0.27, 0.29, 0.34, 0.38, 0.5]

    /// Shared by the drawn trail and scenery clearance. Carry the direction
    /// through each stone; only actual bends and the two endpoints turn vertical.
    /// Harmonic tangents keep each segment within its two level positions.
    static func routeControlOffsets(forSegment index: Int, width: CGFloat) -> (outgoing: CGFloat, incoming: CGFloat) {
        func tangent(at node: Int) -> CGFloat {
            guard node > 0, node < levelPositions.count - 1 else { return 0 }
            let before = levelPositions[node] - levelPositions[node - 1]
            let after = levelPositions[node + 1] - levelPositions[node]
            guard before * after > 0 else { return 0 }
            return 2 * before * after / (before + after)
        }
        return (tangent(at: index) * width / 3, tangent(at: index + 1) * width / 3)
    }
    /// Vertical room under the boss before the next world's banner. Matches WorldRouteTrail.chapterTail.
    static func bossReturnSpan(for width: CGFloat) -> CGFloat {
        let inner = min(width, 600) - 36
        let clearance = max(0, min(200, inner * 0.37) - 82)
        return 100 + clearance
    }
    let width: CGFloat
    var artScale: CGFloat { min(1.35, max(0.82, width / 390)) }

    enum Kind {
        case tree, palm, waterfall, shrub, rocks, fern, flowers, plant, grass
        case mushrooms, log, ruins, snake, fallingLeaves

        var animated: Bool { self == .snake || self == .fallingLeaves }
        var occludesWildlife: Bool { !animated && self != .waterfall && self != .mushrooms && self != .log }

        /// Conservative local bands include leaf tips, vines and contact shadows.
        var footprint: [CGRect] {
            switch self {
            case .tree:
                return [CGRect(x: -116, y: -350, width: 278, height: 190),
                        CGRect(x: -48, y: -240, width: 150, height: 175),
                        CGRect(x: -54, y: -170, width: 130, height: 230)]
            case .palm:
                return [CGRect(x: -105, y: -290, width: 270, height: 240),
                        CGRect(x: -40, y: -180, width: 90, height: 205)]
            case .waterfall:
                return [CGRect(x: -65, y: -292, width: 165, height: 102),
                        CGRect(x: -86, y: -205, width: 216, height: 155),
                        CGRect(x: -85, y: -62, width: 220, height: 118),
                        CGRect(x: -130, y: 26, width: 265, height: 90)]
            case .shrub: return [CGRect(x: -91, y: -65, width: 191, height: 115)]
            case .rocks: return [CGRect(x: -53, y: -48, width: 114, height: 80)]
            case .fern: return [CGRect(x: -77, y: -101, width: 154, height: 107)]
            case .flowers: return [CGRect(x: -27, y: -25, width: 54, height: 40)]
            case .plant: return [CGRect(x: -68, y: -92, width: 141, height: 103)]
            case .grass: return [CGRect(x: -12, y: -17, width: 25, height: 21)]
            case .mushrooms: return [CGRect(x: -40, y: -48, width: 88, height: 66)]
            case .log: return [CGRect(x: -64, y: -42, width: 132, height: 74)]
            case .ruins: return [CGRect(x: -72, y: -122, width: 144, height: 148)]
            case .snake: return [CGRect(x: -70, y: -24, width: 140, height: 66)]
            case .fallingLeaves: return [CGRect(x: -44, y: -18, width: 88, height: 192)]
            }
        }
    }

    struct Item {
        let kind: Kind
        let preferred: CGPoint
        let size: CGFloat
        var mirrored = false
        var foreground = false
        var variant = 0
        var heightScale: CGFloat = 1
    }

    struct Placement: Identifiable {
        let id: Int
        let item: Item
        let point: CGPoint
        let bounds: CGRect
    }

    struct SceneryTile {
        let bounds: CGRect
        let placements: [Placement]
        let includesBoss: Bool
    }

    /// Immutable coordinates are shared by the static art and small animations.
    /// Scrolling and timeline ticks never rerun the road-clearance solver.
    final class Scene {
        let width: CGFloat
        let placements: [Placement]
        let waterfall: Placement
        let bossPoint: CGPoint
        let snakes: [Placement]
        let leaves: [Placement]
        let sceneryTiles: [SceneryTile]

        init(layout: JungleMapLayout) {
            width = layout.width
            let placed = layout.items.enumerated().map { index, item in
                var point = layout.position(of: item)
                let stage = WorldBossStage(worldID: 1, width: layout.width)
                for band in layout.footprint(of: item) {
                    let occupied = band.offsetBy(dx: point.x, dy: point.y)
                    if occupied.intersects(stage.clearance) {
                        if item.preferred.x > layout.width / 2 {
                            point.x += stage.clearance.maxX - occupied.minX + 8 * stage.scale
                        } else {
                            point.x += stage.clearance.minX - occupied.maxX - 8 * stage.scale
                        }
                    }
                }
                let bounds = layout.footprint(of: item).reduce(CGRect.null) { $0.union($1) }
                    .offsetBy(dx: point.x, dy: point.y)
                return Placement(id: index, item: item, point: point, bounds: bounds)
            }
            placements = placed
            waterfall = placed.first { $0.item.kind == .waterfall }!
            snakes = placed.filter { $0.item.kind == .snake }
            leaves = placed.filter { $0.item.kind == .fallingLeaves }
            let scale = layout.artScale
            bossPoint = WorldBossStage(worldID: 1, width: layout.width).point
            let staticItems = placed.filter { !$0.item.kind.animated }
            let bossBounds = CGRect(x: bossPoint.x - 130 * scale, y: bossPoint.y - 270 * scale,
                                    width: 260 * scale, height: 320 * scale)
            let extent = staticItems.reduce(bossBounds) { $0.union($1.bounds) }
            let first = Int(floor(extent.minY / 512)), last = Int(floor(extent.maxY / 512))
            sceneryTiles = (first...last).map { row in
                let bounds = CGRect(x: 0, y: CGFloat(row) * 512, width: layout.width, height: 512)
                return SceneryTile(bounds: bounds, placements: staticItems.filter { $0.bounds.intersects(bounds) },
                                  includesBoss: bossBounds.intersects(bounds))
            }
        }
    }

    private static let sceneCache: NSCache<NSNumber, Scene> = {
        let cache = NSCache<NSNumber, Scene>()
        cache.countLimit = 8
        return cache
    }()

    func scene() -> Scene {
        let key = NSNumber(value: Double(width))
        if let cached = Self.sceneCache.object(forKey: key) { return cached }
        let result = Scene(layout: self)
        Self.sceneCache.setObject(result, forKey: key)
        return result
    }

    /// Deliberate groves and bank gardens, with a waterfall clearing left of level 4.
    var items: [Item] {
        func item(_ kind: Kind, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat,
                  mirror: Bool = false, foreground: Bool = false, height: CGFloat = 1) -> Item {
            let groveWidth = min(width, 720)
            return Item(kind: kind, preferred: CGPoint(x: (width - groveWidth) / 2 + groveWidth * x, y: y), size: size * artScale,
                 mirrored: mirror, foreground: foreground, heightScale: height)
        }
        var result: [Item] = [
            item(.tree, 0.08, 220, 1.02, mirror: true, foreground: true),
            item(.tree, 0.94, 235, 1.10, foreground: true),
            item(.plant, 0.15, 112, 0.57, mirror: true),
            item(.shrub, 0.18, 155, 0.38),
            item(.fern, 0.89, 118, 0.55), item(.flowers, 0.83, 170, 0.60),
            item(.shrub, 0.10, 269, 0.50), item(.flowers, 0.12, 285, 0.63),
            item(.rocks, 0.94, 300, 0.62), item(.fern, 0.94, 310, 0.63),
            item(.shrub, 0.08, 345, 0.42),
            item(.palm, 0.93, 605, 0.46, height: 1.12),
            item(.fern, 0.94, 465, 0.64), item(.plant, 0.88, 530, 0.72),
            waterfall,
            item(.rocks, 0.93, 660, 0.70), item(.flowers, 0.86, 676, 0.70),
            item(.shrub, 0.89, 692, 0.48),
            item(.tree, 0.09, 1060, 0.51, mirror: true, height: 1.08),
            item(.shrub, 0.09, 785, 0.57), item(.flowers, 0.18, 800, 0.68),
            item(.plant, 0.07, 838, 0.72, mirror: true),
            item(.shrub, 0.88, 835, 0.48), item(.plant, 0.92, 890, 0.68),
            item(.rocks, 0.10, 1000, 0.60), item(.fern, 0.16, 1035, 0.67),
            item(.flowers, 0.12, 1070, 0.68),
            item(.tree, 0.91, 1310, 0.47, height: 1.16),
            item(.shrub, 0.90, 1140, 0.52), item(.flowers, 0.81, 1155, 0.67),
            item(.plant, 0.94, 1205, 0.70),
            item(.shrub, 0.11, 1240, 0.62), item(.rocks, 0.16, 1270, 0.66),
            item(.fern, 0.12, 1320, 0.77),
            item(.palm, 0.08, 1515, 0.43, mirror: true, height: 0.95),
            item(.shrub, 0.09, 1485, 0.55), item(.flowers, 0.19, 1500, 0.69),
            item(.plant, 0.13, 1550, 0.68, mirror: true),
            item(.rocks, 0.91, 1585, 0.68), item(.shrub, 0.88, 1608, 0.48),
            item(.flowers, 0.83, 1620, 0.63),
            item(.plant, 0.10, 1680, 0.76, mirror: true),
            item(.shrub, 0.12, 1760, 0.58), item(.fern, 0.15, 1810, 0.68),
            item(.rocks, 0.12, 1850, 0.73), item(.flowers, 0.18, 1868, 0.64)
        ]
        result += [
            item(.mushrooms, 0.11, 205, 0.64), item(.shrub, 0.86, 218, 0.35),
            item(.log, 0.89, 365, 0.63, mirror: true), item(.mushrooms, 0.85, 390, 0.57),
            item(.plant, 0.09, 390, 0.45, mirror: true),
            item(.shrub, 0.96, 580, 0.43), item(.flowers, 0.86, 592, 0.52),
            item(.log, 0.13, 735, 0.62),
            item(.mushrooms, 0.17, 752, 0.59), item(.plant, 0.07, 745, 0.45),
            item(.snake, 0.87, 754, 0.66),
            item(.mushrooms, 0.14, 955, 0.61), item(.plant, 0.88, 1005, 0.57),
            item(.shrub, 0.72, 946, 0.34), item(.flowers, 0.70, 925, 0.50),
            item(.rocks, 0.72, 977, 0.40),
            item(.log, 0.89, 1060, 0.68, mirror: true), item(.shrub, 0.85, 1083, 0.36),
            item(.snake, 0.15, 1145, 0.68, mirror: true),
            item(.mushrooms, 0.16, 1205, 0.57), item(.plant, 0.07, 1160, 0.48),
            item(.log, 0.16, 1385, 0.66),
            item(.shrub, 0.08, 1405, 0.45), item(.mushrooms, 0.21, 1423, 0.65),
            item(.snake, 0.83, 1515, 0.67),
            item(.mushrooms, 0.91, 1740, 0.62), item(.flowers, 0.83, 1790, 0.55),
            item(.shrub, 0.10, 1640, 0.39), item(.plant, 0.87, 1865, 0.46)
        ]
        // Alternate tall crowns, low palms and mossy ruins rather than
        // packing several full trees into the same vertical grove.
        let pocketY = min(CGFloat(1470), WorldBossStage(worldID: 1, width: width).clearance.minY - 32 * artScale)
        result += [
            item(.tree, 0.10, 805, 0.44, mirror: true, height: 1.12),
            item(.tree, 0.92, 945, 0.48, height: 0.95),
            item(.tree, 0.09, 1715, 0.43, mirror: true, height: 0.94),
            item(.ruins, 0.87, pocketY, 0.69),
            item(.ruins, 0.12, 1265, 0.47, mirror: true),
            item(.plant, 0.73, pocketY + 27, 0.48),
            item(.flowers, 0.83, pocketY + 24, 0.64),
            item(.fern, 0.89, pocketY - 32, 0.53)
        ]
        // The single pale cut faces the road. The far bark end disappears into
        // a shrub tied to the resolved log position, including on wide tablets.
        for log in result.filter({ $0.kind == .log }) {
            let origin = position(of: log)
            let rearX = origin.x + (log.mirrored ? 48 : -48) * log.size
            result.append(Item(kind: .shrub,
                preferred: CGPoint(x: rearX, y: origin.y + 7 * log.size), size: log.size * 0.52))
        }
        // Small grounded details favour alternating banks, never the centre lane.
        for i in 0..<28 {
            result.append(item(.grass, i.isMultiple(of: 2) ? 0.23 : 0.79,
                               145 + CGFloat(i) * 61, 0.55 + CGFloat(i % 3) * 0.08))
        }
        // The final grove belongs to the actual return below the boss. Its
        // old fixed baselines extended beyond the jungle's clipped chapter.
        let groveStart: CGFloat = 1680
        let chapterEnd = Self.firstNodeY + 9 * Self.levelSpacing + Self.bossReturnSpan(for: width)
        let lastRoot = chapterEnd - 40 * artScale
        for index in result.indices where result[index].preferred.y >= groveStart {
            let source = result[index]
            let progress = min(1, (source.preferred.y - groveStart) / 200)
            let bottom = footprint(of: source).map(\.maxY).max() ?? 0
            let y = min(groveStart + progress * (lastRoot - groveStart), chapterEnd - 16 - bottom)
            result[index] = Item(kind: source.kind, preferred: CGPoint(x: source.preferred.x, y: y),
                                 size: source.size, mirrored: source.mirrored,
                                 foreground: source.foreground, variant: source.variant, heightScale: source.heightScale)
        }
        // Emit leaves from the lower crowns. Their whole drift envelope is
        // placed beside the road just like a static silhouette.
        for tree in result.filter({ $0.kind == .tree }) {
            let origin = position(of: tree)
            let inward: CGFloat = origin.x < width / 2 ? 1 : -1
            result.append(Item(kind: .fallingLeaves,
                preferred: CGPoint(x: origin.x + inward * 43 * tree.size, y: origin.y - 180 * tree.size),
                size: 0.76 * artScale, variant: result.count))
        }
        for i in result.indices where result[i].kind == .snake || result[i].kind == .mushrooms {
            result[i].variant = i % 3
        }
        return result
    }

    var waterfall: Item {
        let groveWidth = min(width, 720)
        return Item(kind: .waterfall, preferred: CGPoint(x: (width - groveWidth) / 2 + groveWidth * 0.055, y: 610),
                    size: 0.78 * artScale, mirrored: true, heightScale: 0.78)
    }

    func centerX(at y: CGFloat) -> CGFloat {
        let fractions = Self.levelPositions
        let bossY = Self.firstNodeY + CGFloat(fractions.count - 1) * Self.levelSpacing
        if y >= bossY { return bossReturnX(at: y, bossY: bossY, from: fractions[fractions.count - 1]) }
        guard y > Self.firstNodeY else {
            let trailWidth = min(width, 600) - 36
            return (width - trailWidth) / 2 + trailWidth * fractions[0]
        }
        let index = min(fractions.count - 2, Int((y - Self.firstNodeY) / Self.levelSpacing))
        let startY = Self.firstNodeY + CGFloat(index) * Self.levelSpacing
        let trailWidth = min(width, 600) - 36
        let startX = (width - trailWidth) / 2 + trailWidth * fractions[index]
        let endX = (width - trailWidth) / 2 + trailWidth * fractions[index + 1]
        let controls = Self.routeControlOffsets(forSegment: index, width: trailWidth)
        return cubic(startX, startX + controls.outgoing, endX - controls.incoming, endX,
                     (y - startY) / Self.levelSpacing)
    }

    /// The same vertical-tangent bend the jungle trail draws from the boss back to the centre.
    private func bossReturnX(at y: CGFloat, bossY: CGFloat, from fraction: CGFloat) -> CGFloat {
        let span = Self.bossReturnSpan(for: width)
        let trailWidth = min(width, 600) - 36
        let origin = (width - trailWidth) / 2
        let startX = origin + trailWidth * fraction
        let endX = origin + trailWidth * 0.5
        guard y < bossY + span else { return endX }
        let handle = min(88, span * 0.42)
        let endY = bossY + span
        var lower: CGFloat = 0, upper: CGFloat = 1
        for _ in 0..<16 {
            let t = (lower + upper) / 2
            if cubic(bossY, bossY + handle, endY - handle, endY, t) < y { lower = t }
            else { upper = t }
        }
        return cubic(startX, startX, endX, endX, (lower + upper) / 2)
    }

    /// Horizontal clearance includes the stroked curve, stones and star rows.
    func clearance(at y: CGFloat) -> CGFloat {
        let slope = (centerX(at: y + 0.5) - centerX(at: y - 0.5))
        var result = 24 * sqrt(1 + slope * slope) + 12
        let lastIndex = Self.levelPositions.count - 1
        let index = min(lastIndex, max(0, Int(((y - Self.firstNodeY) / Self.levelSpacing).rounded())))
        let dy = y - (Self.firstNodeY + CGFloat(index) * Self.levelSpacing)
        let radius: CGFloat = index == lastIndex ? 45 : 36
        if abs(dy) <= radius { result = max(result, sqrt(radius * radius - dy * dy) + 12) }
        if (36...65).contains(dy) { result = max(result, 48) }
        return result
    }

    func footprint(of item: Item) -> [CGRect] {
        let transform = CGAffineTransform(scaleX: item.mirrored ? -item.size : item.size, y: item.size * item.heightScale)
        return item.kind.footprint.map { $0.applying(transform).standardized }
    }

    func position(of item: Item) -> CGPoint {
        position(preferred: item.preferred, footprint: footprint(of: item))
    }

    func position(preferred: CGPoint, footprint: [CGRect]) -> CGPoint {
        let right = preferred.x > width / 2
        var x = preferred.x
        for bounds in footprint {
            let count = max(1, Int(ceil(bounds.height / 3)))
            for i in 0...count {
                let y = preferred.y + bounds.minY + bounds.height * CGFloat(i) / CGFloat(count)
                let edge = centerX(at: y) + (right ? clearance(at: y) : -clearance(at: y))
                // Two extra points cover extrema between samples and antialiasing.
                x = right ? max(x, edge - bounds.minX + 2) : min(x, edge - bounds.maxX - 2)
            }
        }
        return CGPoint(x: x, y: preferred.y)
    }

    private func cubic(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat, _ t: CGFloat) -> CGFloat {
        let u = 1 - t
        return u * u * u * a + 3 * u * u * t * b + 3 * u * t * t * c + t * t * t * d
    }
}
