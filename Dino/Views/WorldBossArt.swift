import SwiftUI
import UIKit

enum WorldBossClock {
    static func time(in worldID: Int) -> ClockTime {
        switch worldID {
        case 1: return .init(hour: 8)
        case 2: return .init(hour: 7, minute: 30)
        case 3: return .init(hour: 4, minute: 45)
        case 4: return .init(hour: 5, minute: 20)
        case 5: return .init(hour: 2, minute: 17)
        case 6: return .init(hour: 12, minute: 45)
        case 7: return .init(hour: 7, minute: 30)
        case 8: return .init(hour: 6, minute: 25)
        case 9: return .init(hour: 9, minute: 30)
        default: return .init(hour: 10, minute: 25)
        }
    }
}

/// Body and clock faces use the same source coordinates. The supplied rims,
/// chains, straps and fingers stay in front of the shape-based clock faces.
struct WorldBossPainter {
    let context: GraphicsContext

    static func bounds(worldID: Int, at point: CGPoint, size: CGFloat) -> CGRect {
        guard let sprite = WorldBossArtwork.sprite(themeID: worldID) else { return .zero }
        let tall = worldID == 8 || worldID == 10
        let maximumWidth: CGFloat = worldID == 1 ? 132 : worldID == 6 ? 118 : 176
        let scale = min((tall ? 200 : 178) / sprite.sourceBounds.height,
                        maximumWidth / sprite.sourceBounds.width) * size
        let width = sprite.sourceBounds.width * scale, height = sprite.sourceBounds.height * scale
        return CGRect(x: point.x - width / 2, y: point.y + 10 * size - height, width: width, height: height)
    }

    func draw(worldID: Int, at point: CGPoint, size: CGFloat, elapsed: TimeInterval = 0) {
        guard let sprite = WorldBossArtwork.sprite(themeID: worldID) else { return }
        let layer = sourceContext(sprite: sprite, worldID: worldID, at: point, size: size)
        clockFaces(context: layer, sprite: sprite, worldID: worldID, elapsed: elapsed)
        layer.draw(Image(uiImage: sprite.image), in: sprite.sourceBounds)
    }

    /// A small live layer repaints only the transparent clock cutouts. The body
    /// and surrounding world can remain in their existing static bitmap caches.
    func drawClocks(worldID: Int, at point: CGPoint, size: CGFloat, elapsed: TimeInterval) {
        guard let sprite = WorldBossArtwork.sprite(themeID: worldID) else { return }
        clockFaces(context: sourceContext(sprite: sprite, worldID: worldID, at: point, size: size),
                   sprite: sprite, worldID: worldID, elapsed: elapsed)
    }

    private func sourceContext(sprite: WorldBossArtwork.Sprite, worldID: Int, at point: CGPoint, size: CGFloat) -> GraphicsContext {
        let rect = Self.bounds(worldID: worldID, at: point, size: size)
        var layer = context
        layer.translateBy(x: rect.minX, y: rect.minY)
        layer.scaleBy(x: rect.width / sprite.sourceBounds.width, y: rect.height / sprite.sourceBounds.height)
        layer.translateBy(x: -sprite.sourceBounds.minX, y: -sprite.sourceBounds.minY)
        return layer
    }

    private func clockFaces(context: GraphicsContext, sprite: WorldBossArtwork.Sprite, worldID: Int, elapsed: TimeInterval) {
        var layer = context
        // Inverting the original alpha retains hand/strap occlusion and the
        // antialiased inner bezel, including the partially held sash clock.
        layer.clipToLayer { mask in
            mask.blendMode = .normal
            mask.draw(Image(uiImage: sprite.clockMask), in: sprite.sourceBounds)
        }
        for clock in WorldBossArtwork.clocks(themeID: worldID) {
            clock.draw(in: layer, initial: clock.initial ?? WorldBossClock.time(in: worldID), elapsed: elapsed)
        }
    }
}

private enum WorldBossArtwork {
    struct Clock {
        let center: CGPoint
        let radius: CGSize
        var blue = true
        var initial: ClockTime? = nil

        init(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat,
             blue: Bool = true, initial: ClockTime? = nil) {
            center = CGPoint(x: x, y: y); radius = CGSize(width: rx, height: ry)
            self.blue = blue; self.initial = initial
        }

        func draw(in context: GraphicsContext, initial: ClockTime, elapsed: TimeInterval) {
            var c = context
            c.translateBy(x: center.x, y: center.y)
            c.scaleBy(x: radius.width, y: radius.height)
            let dial = Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2))
            c.clip(to: dial)
            c.fill(dial, with: .radialGradient(Gradient(colors: [Color(dinoHex: 0xFFFCEE), Color(dinoHex: 0xF3E5BC)]),
                                              center: CGPoint(x: -0.3, y: -0.4), startRadius: 0, endRadius: 1.65))
            c.stroke(dial, with: .color(Color(dinoHex: 0x9B7846).opacity(0.38)), lineWidth: 0.04)
            let ink = Color(dinoHex: blue ? 0x28566B : 0x3D382E)
            for tick in 0..<12 {
                let angle = Double(tick) * .pi / 6
                let major = tick.isMultiple(of: 3)
                let inner: CGFloat = major ? 0.75 : 0.79
                var mark = Path()
                mark.move(to: CGPoint(x: sin(angle) * inner, y: -cos(angle) * inner))
                mark.addLine(to: CGPoint(x: sin(angle) * 0.90, y: -cos(angle) * 0.90))
                c.stroke(mark, with: .color(ink), style: StrokeStyle(lineWidth: major ? 0.055 : 0.035, lineCap: .round))
            }
            let phase = WorldClockMotion.Phase(initial: initial, elapsed: elapsed,
                                               minuteRevolution: WorldClockMotion.bossMinuteRevolution)
            hand(context: c, angle: phase.hourAngle, length: 0.58, width: 0.063, ink: ink)
            hand(context: c, angle: phase.minuteAngle, length: 0.80, width: 0.038, ink: ink)
            c.fill(Path(ellipseIn: CGRect(x: -0.105, y: -0.075, width: 0.21, height: 0.21)),
                   with: .color(Color(dinoHex: 0x5E492D).opacity(0.18)))
            c.fill(Path(ellipseIn: CGRect(x: -0.085, y: -0.085, width: 0.17, height: 0.17)),
                   with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFE09A), Color(dinoHex: 0xB57E2D)]),
                                         startPoint: CGPoint(x: -0.06, y: -0.08), endPoint: CGPoint(x: 0.08, y: 0.08)))
        }

        private func hand(context: GraphicsContext, angle: Double, length: CGFloat, width: CGFloat, ink: Color) {
            var c = context
            c.rotate(by: .degrees(angle))
            var path = Path()
            path.addLines([CGPoint(x: -width * 0.65, y: 0.12), CGPoint(x: -width, y: -length * 0.70),
                           CGPoint(x: 0, y: -length), CGPoint(x: width, y: -length * 0.70),
                           CGPoint(x: width * 0.65, y: 0.12)])
            path.closeSubpath()
            var shadow = c; shadow.translateBy(x: 0.018, y: 0.025)
            shadow.fill(path, with: .color(.black.opacity(0.14)))
            c.fill(path, with: .linearGradient(Gradient(colors: [ink.opacity(0.83), ink]),
                                              startPoint: CGPoint(x: -width, y: -length), endPoint: CGPoint(x: width, y: 0.1)))
        }
    }

    // Measured in the 1254 px transparent exports, independently of their crop.
    // Art IDs follow themes, rather than the new exports' different suffixes.
    static func clocks(themeID: Int) -> [Clock] {
        switch themeID {
        case 1: return [.init(497.5, 776, 95, 105, blue: false)]
        case 2: return [.init(875, 838.5, 67, 74)]
        case 3: return [.init(421, 895, 58, 60, initial: .init(hour: 8, minute: 15)),
                        .init(585.5, 821.5, 62, 64, initial: .init(hour: 4, minute: 45)),
                        .init(745, 720, 59, 59, initial: .init(hour: 1, minute: 15))]
        case 4: return [.init(251, 316.5, 118, 122)]
        case 5: return [.init(546, 779, 95, 92)]
        case 6: return [.init(312.5, 559, 46, 49), .init(848.5, 572, 47, 52)]
        case 7: return [.init(652, 767.5, 118, 132, blue: false)]
        case 8: return [.init(625.5, 175, 58, 54, initial: .init(hour: 10, minute: 10)),
                        .init(717.5, 263.5, 47, 51, initial: .init(hour: 3))]
        case 9: return [.init(228.5, 770.5, 56, 63)]
        case 10: return [.init(653, 194.5, 81, 85)]
        default: return []
        }
    }

    private static let assets = [
        "boss-jungle", "boss-sleep-valley", "boss-volcano",
        "boss-clock-village", "boss-crystal-cave", "boss-clock-city",
        "boss-desert", "boss-time-machine", "boss-pirates", "boss-castle"
    ]
    final class Sprite: NSObject {
        let image: UIImage
        let clockMask: UIImage
        let sourceBounds: CGRect
        init(image: CGImage, clockMask: CGImage, sourceBounds: CGRect) {
            self.image = UIImage(cgImage: image); self.clockMask = UIImage(cgImage: clockMask)
            self.sourceBounds = sourceBounds
        }
    }
    private static let cache: NSCache<NSString, Sprite> = {
        let cache = NSCache<NSString, Sprite>()
        cache.totalCostLimit = 32 * 1024 * 1024
        return cache
    }()

    static func sprite(themeID: Int) -> Sprite? {
        guard assets.indices.contains(themeID - 1) else { return nil }
        let name = assets[themeID - 1]
        if let sprite = cache.object(forKey: name as NSString) { return sprite }
        guard let source = UIImage(named: name)?.cgImage else { return nil }
        let scale = min(1, 640 / CGFloat(max(source.width, source.height)))
        let width = Int((CGFloat(source.width) * scale).rounded())
        let height = Int((CGFloat(source.height) * scale).rounded())
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        var crop = CGRect.zero
        let result: (CGImage, CGImage)? = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue),
                let bytes = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return nil }
            context.interpolationQuality = .high
            context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
            var left = width, top = height, right = 0, bottom = 0
            for y in 0..<height {
                for x in 0..<width where bytes[(y * width + x) * 4 + 3] > 16 {
                    left = min(left, x); right = max(right, x); top = min(top, y); bottom = max(bottom, y)
                }
            }
            guard left <= right, top <= bottom else { return nil }
            crop = CGRect(x: max(0, left - 2), y: max(0, top - 2),
                          width: min(width, right + 3) - max(0, left - 2),
                          height: min(height, bottom + 3) - max(0, top - 2))
            func snapshot() -> CGImage? {
                guard let provider = CGDataProvider(data: Data(bytes: bytes, count: width * height * 4) as CFData) else { return nil }
                return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                    bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue),
                    provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            }
            guard let original = snapshot()?.cropping(to: crop) else { return nil }
            // Copy before updating the buffer: image/mask must own separate bytes.
            for index in stride(from: 0, to: width * height * 4, by: 4) {
                let alpha = 255 - bytes[index + 3]
                for channel in 0..<4 { bytes[index + channel] = alpha }
            }
            guard let mask = snapshot()?.cropping(to: crop) else { return nil }
            return (original, mask)
        }
        guard let (image, mask) = result else { return nil }
        // Clock centers remain in the original 1254-point drawing space even
        // though the bundled artwork is already reduced to its 640-pixel raster.
        let drawingScale = 1254 / CGFloat(width)
        let bounds = crop.applying(CGAffineTransform(scaleX: drawingScale, y: drawingScale))
        let sprite = Sprite(image: image, clockMask: mask, sourceBounds: bounds)
        cache.setObject(sprite, forKey: name as NSString, cost: (image.bytesPerRow + mask.bytesPerRow) * image.height)
        return sprite
    }
}

/// Only the small clock area ticks; scrolling terrain and dinosaur bodies stay cached.
struct WorldBossClockSurface: View {
    let themeID: Int
    let point: CGPoint
    let scale: CGFloat
    let viewportHeight: CGFloat
    var fixedTime: TimeInterval? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dinoMapAnimationEpoch) private var animationEpoch
    @State private var visible = false

    var body: some View {
        let bounds = WorldBossPainter.bounds(worldID: themeID, at: point, size: scale)
        TimelineView(.animation(minimumInterval: 1.0 / 30,
                                paused: fixedTime != nil || reduceMotion || !visible || scenePhase != .active)) { timeline in
            Canvas { context, _ in
                let elapsed = reduceMotion ? 0 : fixedTime ?? timeline.date.timeIntervalSince(animationEpoch ?? Date(timeIntervalSinceReferenceDate: 0))
                var c = context; c.translateBy(x: -bounds.minX, y: -bounds.minY)
                WorldBossPainter(context: c).drawClocks(worldID: themeID, at: point, size: scale, elapsed: elapsed)
            }
        }
        .readGeometry(for: Bool.self) { geometry in
            let frame = geometry.frame(in: .named("adventure.map.viewport"))
            return frame.maxY > -128 && frame.minY < viewportHeight + 128
        } action: { visible = $0 }
        .frame(width: bounds.width, height: bounds.height)
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}
