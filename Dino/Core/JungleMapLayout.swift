import Foundation
import CoreGraphics

/// Positions the complete silhouettes beside the actual cubic trail. Art can
/// overlap other scenery, but crowns, roots and pools keep clear of the road.
struct JungleMapLayout {
    static let levelSpacing: CGFloat = 175
    static let firstNodeY: CGFloat = 70
    static let chapterPositions: [CGFloat] = [0.28, 0.5, 0.72, 0.5, 0.28, 0.5, 0.72, 0.5, 0.28, 0.5]
    let width: CGFloat
    var artScale: CGFloat { min(1.35, max(0.82, width / 390)) }

    enum Kind {
        case tree, palm, waterfall, shrub, rocks, fern, flowers, plant, grass
        case mushrooms, log, snake, fallingLeaves

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

    struct CanopyTile {
        let bounds: CGRect
        let placements: [Placement]
    }

    /// Immutable coordinates are shared by the static art and small animations.
    /// Scrolling and timeline ticks never rerun the road-clearance solver.
    final class Scene {
        let placements: [Placement]
        let waterfall: Placement
        let bossPoint: CGPoint
        let ground: [Placement]
        let snakes: [Placement]
        let leaves: [Placement]
        let canopyTiles: [CanopyTile]

        init(layout: JungleMapLayout) {
            let placed = layout.items.enumerated().map { index, item in
                let point = layout.position(of: item)
                let bounds = layout.footprint(of: item).reduce(CGRect.null) { $0.union($1) }
                    .offsetBy(dx: point.x, dy: point.y)
                return Placement(id: index, item: item, point: point, bounds: bounds)
            }
            placements = placed
            waterfall = placed.first { $0.item.kind == .waterfall }!
            ground = placed.filter { !$0.item.kind.animated && !$0.item.kind.occludesWildlife }
            snakes = placed.filter { $0.item.kind == .snake }
            leaves = placed.filter { $0.item.kind == .fallingLeaves }
            let canopy = placed.filter { $0.item.kind.occludesWildlife }
            let extent = canopy.reduce(CGRect.null) { $0.union($1.bounds) }
            let first = Int(floor(extent.minY / 512)), last = Int(floor(extent.maxY / 512))
            canopyTiles = (first...last).map { row in
                let bounds = CGRect(x: 0, y: CGFloat(row) * 512, width: layout.width, height: 512)
                return CanopyTile(bounds: bounds, placements: canopy.filter { $0.bounds.intersects(bounds) })
            }
            let scale = layout.artScale
            bossPoint = layout.position(preferred: CGPoint(x: layout.width - 60 * scale, y: 1840),
                footprint: [CGRect(x: -88 * scale, y: -170 * scale, width: 176 * scale, height: 200 * scale)])
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

    /// Deliberate groves and bank gardens, with a waterfall clearing left of 3.
    var items: [Item] {
        func item(_ kind: Kind, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat,
                  mirror: Bool = false, foreground: Bool = false) -> Item {
            let groveWidth = min(width, 720)
            return Item(kind: kind, preferred: CGPoint(x: (width - groveWidth) / 2 + groveWidth * x, y: y), size: size * artScale,
                 mirrored: mirror, foreground: foreground)
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
            item(.palm, 0.94, 605, 0.79),
            item(.fern, 0.94, 465, 0.64), item(.plant, 0.88, 530, 0.72),
            waterfall,
            item(.rocks, 0.93, 660, 0.70), item(.flowers, 0.86, 676, 0.70),
            item(.shrub, 0.89, 692, 0.48),
            item(.tree, 0.08, 980, 0.82, mirror: true),
            item(.shrub, 0.09, 785, 0.57), item(.flowers, 0.18, 800, 0.68),
            item(.plant, 0.07, 838, 0.72, mirror: true),
            item(.shrub, 0.88, 835, 0.48), item(.plant, 0.92, 890, 0.68),
            item(.rocks, 0.10, 1000, 0.60), item(.fern, 0.16, 1035, 0.67),
            item(.flowers, 0.12, 1070, 0.68),
            item(.tree, 0.93, 1330, 0.86),
            item(.shrub, 0.90, 1140, 0.52), item(.flowers, 0.81, 1155, 0.67),
            item(.plant, 0.94, 1205, 0.70),
            item(.shrub, 0.11, 1240, 0.62), item(.rocks, 0.16, 1270, 0.66),
            item(.fern, 0.12, 1320, 0.77),
            item(.palm, 0.08, 1515, 0.73, mirror: true),
            item(.shrub, 0.09, 1485, 0.55), item(.flowers, 0.19, 1500, 0.69),
            item(.plant, 0.13, 1550, 0.68, mirror: true),
            item(.tree, 0.94, 1760, 0.82),
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
        let fractions = [CGFloat(0.5)] + Self.chapterPositions
        guard y > Self.firstNodeY else { return width / 2 }
        let index = min(9, Int((y - Self.firstNodeY) / Self.levelSpacing))
        guard y < Self.firstNodeY + 10 * Self.levelSpacing else { return width / 2 }
        let startY = Self.firstNodeY + CGFloat(index) * Self.levelSpacing
        var lower: CGFloat = 0, upper: CGFloat = 1
        for _ in 0..<16 {
            let t = (lower + upper) / 2
            if cubic(startY, startY + 88, startY + 87, startY + Self.levelSpacing, t) < y { lower = t }
            else { upper = t }
        }
        let trailWidth = min(width, 600) - 36
        let startX = (width - trailWidth) / 2 + trailWidth * fractions[index]
        let endX = (width - trailWidth) / 2 + trailWidth * fractions[index + 1]
        return cubic(startX, startX, endX, endX, (lower + upper) / 2)
    }

    /// Horizontal clearance includes the stroked curve, stones and star rows.
    func clearance(at y: CGFloat) -> CGFloat {
        let slope = (centerX(at: y + 0.5) - centerX(at: y - 0.5))
        var result = 24 * sqrt(1 + slope * slope) + 12
        let index = min(10, max(0, Int(((y - Self.firstNodeY) / Self.levelSpacing).rounded())))
        let dy = y - (Self.firstNodeY + CGFloat(index) * Self.levelSpacing)
        let radius: CGFloat = index == 0 ? 48 : index == 10 ? 45 : 36
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
