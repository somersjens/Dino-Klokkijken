import SwiftUI
import UIKit
import Combine

/// Answer stones share a line count and font size. Break at the most even word boundary.
struct DinoAnswerTextLayout {
    let titles: [String]
    let fontSize: CGFloat

    init(titles: [String], width: CGFloat, fontSize: CGFloat = 17) {
        let base = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        let font = UIFont(descriptor: base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor,
                          size: fontSize)
        func measure(_ text: String) -> CGFloat {
            (text as NSString).size(withAttributes: [.font: font]).width
        }
        let available = max(1, width - 2)
        let usesTwoLines = titles.contains { measure($0) > available }
        self.titles = titles.map { title in
            let words = title.split(whereSeparator: \.isWhitespace).map(String.init)
            guard usesTwoLines, words.count > 1 else { return title }
            let split = (1..<words.count).min { lhs, rhs in
                func difference(at index: Int) -> CGFloat {
                    abs(measure(words[..<index].joined(separator: " "))
                        - measure(words[index...].joined(separator: " ")))
                }
                return difference(at: lhs) < difference(at: rhs)
            }!
            return words[..<split].joined(separator: " ") + "\n" + words[split...].joined(separator: " ")
        }
        let longestLine = self.titles.flatMap { $0.components(separatedBy: "\n") }.map(measure).max() ?? 0
        self.fontSize = fontSize * min(1, available / max(1, longestLine))
    }
}

private struct DinoMapPreparingKey: EnvironmentKey { static let defaultValue = false }
private struct DinoMapInitialWorldKey: EnvironmentKey { static let defaultValue = 1 }
private struct DinoMapArtworkPreparedKey: EnvironmentKey { static let defaultValue: (Int) -> Void = { _ in } }
private struct DinoMapAnimationEpochKey: EnvironmentKey { static let defaultValue: Date? = nil }
private struct DinoMapDefersAnimationsKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var dinoMapDefersAnimations: Bool {
        get { self[DinoMapDefersAnimationsKey.self] }
        set { self[DinoMapDefersAnimationsKey.self] = newValue }
    }
    var dinoMapPreparing: Bool {
        get { self[DinoMapPreparingKey.self] }
        set { self[DinoMapPreparingKey.self] = newValue }
    }
    var dinoMapInitialWorld: Int {
        get { self[DinoMapInitialWorldKey.self] }
        set { self[DinoMapInitialWorldKey.self] = newValue }
    }
    var dinoMapArtworkPrepared: (Int) -> Void {
        get { self[DinoMapArtworkPreparedKey.self] }
        set { self[DinoMapArtworkPreparedKey.self] = newValue }
    }
    var dinoMapAnimationEpoch: Date? {
        get { self[DinoMapAnimationEpochKey.self] }
        set { self[DinoMapAnimationEpochKey.self] = newValue }
    }
}

/// A paused TimelineView still draws its first frame and every attached mask.
/// Defer the entire subtree, retaining its layout, until it approaches the screen.
struct MapAnimationVisibility: ViewModifier {
    @Environment(\.dinoMapDefersAnimations) private var deferred
    let viewportHeight: CGFloat
    var alwaysVisible = false
    @State private var nearby = false

    func body(content: Content) -> some View {
        Color.clear.overlay {
            if nearby || alwaysVisible || !deferred { content }
        }
        .readGeometry(for: Bool.self) { geometry in
            DinoMapViewport.preparesAnimation(frame: geometry.frame(in: .named("adventure.map.viewport")),
                                              viewportHeight: viewportHeight, retained: nearby)
        } action: { value in
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { nearby = value }
        }
    }
}

/// Keep expensive static drawing out of scrolling. The native animation layers
/// remain independent; an unchanged bitmap never clears between scroll frames.
struct PreparedMapArtwork<Content: View>: View {
    @Environment(\.displayScale) private var displayScale
    @Environment(\.dinoMapArtworkPrepared) private var prepared
    let worldID: Int
    let size: CGSize
    let routeOffset: CGFloat
    let ground: UInt32?
    var tileContent: ((CGRect) -> Content)? = nil
    @ViewBuilder var content: () -> Content
    @State private var rendered: (key: String, image: UIImage)?
    @State private var nativeFallback = false

    private var scale: CGFloat { min(2, displayScale) }
    private var key: String { DinoMapArtworkCache.key(worldID: worldID, size: size, offset: routeOffset, scale: scale) }
    var body: some View {
        let cached = rendered?.key == key ? rendered?.image : DinoMapArtworkCache.shared.cached(key)
        Group {
            if let image = cached ?? rendered?.image {
                Image(uiImage: image).resizable().frame(width: size.width, height: size.height)
            } else if nativeFallback { content() }
            else if let ground { Color(dinoHex: ground) }
            else { Color.clear }
        }
        .transaction { $0.animation = nil }
        .task(id: key) {
            guard size.width > 0, size.height > 0 else { return }
            let request = key
            let image = await DinoMapArtworkCache.shared.image(key: request, worldID: worldID,
                size: size, routeOffset: routeOffset, scale: scale, content: content(), tileContent: tileContent)
            guard !Task.isCancelled else { return }
            if let image { rendered = (request, image); nativeFallback = false }
            else { nativeFallback = true; await Task.yield() }
            prepared(worldID)
        }
    }
}

@MainActor
final class DinoMapArtworkCache: ObservableObject {
    static let shared = DinoMapArtworkCache()
    private let images = NSCache<NSString, UIImage>()
    private var pendingBitmaps: [String: Task<UIImage?, Never>] = [:]
    private let directory: URL
    @Published private(set) var rasterizationCount = 0
#if DEBUG
    @Published private(set) var gullPreparedFrames = 0
    @Published private(set) var gullPreparationDetails = ""
    private(set) var lastRasterDetails = "none"
    func recordGullPreparation(frames: Int, milliseconds: Double, onMainThread: Bool) {
        guard ProcessInfo.processInfo.environment["DINO_TEST_MAP_DIAGNOSTICS"] == "1" else { return }
        gullPreparedFrames = frames
        gullPreparationDetails = String(format: "%.1f ms %@", milliseconds, onMainThread ? "main" : "background")
    }
#endif
    private static let revision: String = {
        let executable = Bundle.main.executableURL
        let date = executable.flatMap { try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate }
        return "terrain-v2-\(Int(date?.timeIntervalSince1970 ?? 0))"
    }()
    private init() {
        images.totalCostLimit = 96 * 1024 * 1024
        var revision = Self.revision
#if DEBUG
        if ProcessInfo.processInfo.environment["DINO_TEST_SUITE"] != nil,
           ProcessInfo.processInfo.environment["DINO_TEST_COLD_MAP_ARTWORK"] == "1" {
            revision += "-cold-\(UUID().uuidString)"
        }
#endif
        directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent(revision)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    static func key(worldID: Int, size: CGSize, offset: CGFloat, scale: CGFloat) -> String {
        "\(worldID)-\(Int((size.width * 10).rounded()))-\(Int((size.height * 10).rounded()))-\(Int((offset * 10).rounded()))-\(Int(scale * 10))"
    }
    func cached(_ key: String) -> UIImage? { images.object(forKey: key as NSString) }

    func image<Content: View>(key: String, worldID: Int, size: CGSize, routeOffset: CGFloat,
                             scale: CGFloat, content: Content, tileContent: ((CGRect) -> Content)? = nil) async -> UIImage? {
        // Live layers need their geometry even when the terrain came from disk.
        // Start it ahead of the viewport, rather than on an actor's first frame.
        let preparation = Task.detached(priority: .userInitiated) {
            DinoMapArtworkPreparation.prepare(worldID: worldID, size: size, routeOffset: routeOffset)
        }
        if let cached = cached(key) {
            await preparation.value
            return cached
        }
        let file = directory.appendingPathComponent(key).appendingPathExtension("png")
        let diskImage = await Task.detached(priority: .userInitiated) {
            UIImage(contentsOfFile: file.path)?.preparingForDisplay()
        }.value
        await preparation.value
        guard !Task.isCancelled else { return nil }
        if let diskImage {
            retain(diskImage, key: key)
            return diskImage
        }
        if let cached = cached(key) { return cached }
        if let pending = pendingBitmaps[key] { return await pending.value }
#if DEBUG
        let rasterStarted = ProcessInfo.processInfo.systemUptime
#endif
        let renderer = ImageRenderer(content: content.frame(width: size.width, height: size.height))
        renderer.scale = scale
        renderer.proposedSize = ProposedViewSize(size)
        let image: UIImage?
        if worldID == 10, let tileContent {
            let pending = Task { @MainActor in
                await self.tiledImage(size: size, scale: scale, content: tileContent)
            }
            pendingBitmaps[key] = pending
            image = await pending.value
            pendingBitmaps[key] = nil
        } else {
            image = renderer.uiImage
        }
        guard let image else { return nil }
#if DEBUG
        if ProcessInfo.processInfo.environment["DINO_TEST_MAP_DIAGNOSTICS"] == "1" {
            lastRasterDetails = String(format: "world %d %.1f ms", worldID, (ProcessInfo.processInfo.systemUptime - rasterStarted) * 1000)
            print("MAP_RASTER \(lastRasterDetails)")
        }
#endif
        rasterizationCount += 1
        retain(image, key: key)
        Task.detached(priority: .utility) {
            if let data = image.pngData() { try? data.write(to: file, options: .atomic) }
        }
        return image
    }

    private struct RasterTile: Sendable {
        let image: CGImage
        let top: Int
    }

    /// Keep each native draw small and let the display link run between strips.
    /// Bleed retains shadows/antialiasing; only non-overlapping cores are joined.
    private func tiledImage<Content: View>(size: CGSize, scale: CGFloat,
                                          content: (CGRect) -> Content) async -> UIImage? {
        let height: CGFloat = 192, bleed: CGFloat = 24
        var tiles: [RasterTile] = []
        for index in 0..<Int(ceil(size.height / height)) {
            guard !Task.isCancelled else { return nil }
            let coreTop = CGFloat(index) * height
            let coreHeight = min(height, size.height - coreTop)
            let top = max(0, coreTop - bleed), bottom = min(size.height, coreTop + coreHeight + bleed)
            let bounds = CGRect(x: 0, y: top, width: size.width, height: bottom - top)
            let tile = content(bounds).frame(width: size.width, height: size.height)
                .offset(y: -top)
                .frame(width: size.width, height: bounds.height, alignment: .topLeading).clipped()
            let renderer = ImageRenderer(content: tile)
            renderer.scale = scale
            renderer.proposedSize = ProposedViewSize(width: size.width, height: bounds.height)
            guard let image = renderer.uiImage?.cgImage,
                  let cropped = image.cropping(to: CGRect(x: 0, y: (coreTop - top) * scale,
                    width: ceil(size.width * scale), height: ceil(coreHeight * scale))) else { return nil }
            tiles.append(RasterTile(image: cropped, top: Int((coreTop * scale).rounded())))
            do { try await Task.sleep(for: .milliseconds(16)) } catch { return nil }
        }
        return await Task.detached(priority: .utility) {
            Self.stitch(tiles: tiles, size: size, scale: scale)
        }.value
    }

    nonisolated private static func stitch(tiles: [RasterTile], size: CGSize, scale: CGFloat) -> UIImage? {
        let width = Int(ceil(size.width * scale)), height = Int(ceil(size.height * scale))
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else { return nil }
        context.interpolationQuality = .none
        for tile in tiles {
            context.draw(tile.image, in: CGRect(x: 0, y: height - tile.top - tile.image.height,
                width: tile.image.width, height: tile.image.height))
        }
        guard let image = context.makeImage() else { return nil }
        return UIImage(cgImage: image, scale: scale, orientation: .up)
    }

    private func retain(_ image: UIImage, key: String) {
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        images.setObject(image, forKey: key as NSString, cost: cost)
    }
}

#if DEBUG
struct MapRasterDiagnostics: View {
    @ObservedObject private var cache = DinoMapArtworkCache.shared
    var active = true
    var body: some View {
        VStack(spacing: 0) {
            Text(String(cache.rasterizationCount)).font(.system(size: 1)).foregroundStyle(.clear)
                .frame(width: 1, height: 1).clipped()
                .accessibilityIdentifier("map.rasterizationCount")
            MapFrameGapProbe(active: active).frame(width: 1, height: 1).clipped()
            Text(String(cache.gullPreparedFrames)).font(.system(size: 1)).foregroundStyle(.clear)
                .frame(width: 1, height: 1).clipped()
                .accessibilityIdentifier("map.gullPreparedFrames")
                .accessibilityValue(cache.gullPreparationDetails)
        }
    }
}

/// Measure the first cold traversal too: XCTest's performance warm-up otherwise
/// hides a one-off main-thread stall before its measured iterations begin.
private struct MapFrameGapProbe: UIViewRepresentable {
    let active: Bool
    func makeUIView(context: Context) -> Probe { Probe() }
    func updateUIView(_ view: Probe, context: Context) { view.setActive(active) }
    static func dismantleUIView(_ view: Probe, coordinator: ()) { view.stop() }

    final class Probe: UILabel {
        private var link: CADisplayLink?
        private var lastFrame: CFTimeInterval?
        private var maximumGap: CFTimeInterval = 0
        private var startedAt: CFTimeInterval = 0
        private weak var mapScroll: UIScrollView?
        override init(frame: CGRect) {
            super.init(frame: frame)
            text = "0"
            font = .systemFont(ofSize: 1)
            textColor = .clear
            isAccessibilityElement = true
            accessibilityIdentifier = "map.maximumFrameGapMilliseconds"
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        func setActive(_ active: Bool) {
            guard active else { stop(); return }
            guard link == nil else { return }
            lastFrame = nil
            maximumGap = 0
            startedAt = CACurrentMediaTime()
            text = "0"
            let displayLink = CADisplayLink(target: self, selector: #selector(frame(_:)))
            displayLink.add(to: .main, forMode: .common)
            link = displayLink
        }
        func stop() { link?.invalidate(); link = nil; lastFrame = nil }
        private func findMapScroll(in view: UIView) -> UIScrollView? {
            if let scroll = view as? UIScrollView, scroll.contentSize.height > 5000 { return scroll }
            for child in view.subviews {
                if let scroll = findMapScroll(in: child) { return scroll }
            }
            return nil
        }
        @objc private func frame(_ displayLink: CADisplayLink) {
            let now = CACurrentMediaTime()
            if let lastFrame, now - lastFrame > maximumGap {
                maximumGap = now - lastFrame
                text = String(format: "%.1f", maximumGap * 1000)
                if mapScroll == nil, let window { mapScroll = findMapScroll(in: window) }
                accessibilityValue = String(format: "elapsed=%.2f offset=%.1f raster=%@", now - startedAt,
                    mapScroll?.contentOffset.y ?? -1, DinoMapArtworkCache.shared.lastRasterDetails)
                if maximumGap > 0.1 { print("MAP_FRAME_GAP \(text ?? "?") ms \(accessibilityValue ?? "")") }
            }
            lastFrame = now
        }
    }
}
#endif

private struct DinoHighContrastKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var dinoHighContrast: Bool {
        get { self[DinoHighContrastKey.self] }
        set { self[DinoHighContrastKey.self] = newValue }
    }
}

struct DinoContrastEnvironment: ViewModifier {
    @Environment(\.colorSchemeContrast) private var systemContrast
    let enabled: Bool
    func body(content: Content) -> some View {
        content.environment(\.dinoHighContrast, enabled || systemContrast == .increased)
    }
}

extension Color {
    init(dinoHex: UInt32) {
        self.init(red: Double((dinoHex >> 16) & 255) / 255,
                  green: Double((dinoHex >> 8) & 255) / 255,
                  blue: Double(dinoHex & 255) / 255)
    }

    /// iOS 18 blends in a perceptual space. Earlier systems blend the same sRGB channels.
    func mixed(with other: Color, by fraction: Double) -> Color {
        if #available(iOS 18, *) {
            return mix(with: other, by: fraction)
        }
        let amount = CGFloat(min(1, max(0, fraction)))
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        guard UIColor(self).getRed(&r1, green: &g1, blue: &b1, alpha: &a1),
              UIColor(other).getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return self }
        return Color(red: Double(r1 + (r2 - r1) * amount),
                     green: Double(g1 + (g2 - g1) * amount),
                     blue: Double(b1 + (b2 - b1) * amount),
                     opacity: Double(a1 + (a2 - a1) * amount))
    }
}

enum DinoStyle {
    static let ink = Color(dinoHex: 0x193B53)
    static let green = Color(dinoHex: 0x81D349)
    static let deepGreen = Color(dinoHex: 0x365B20)
    static let paper = Color(dinoHex: 0xF6FAF1)
    static let muted = Color(dinoHex: 0x657E80)
    static let warning = Color(dinoHex: 0x8F2435)
    static let orange = Color(dinoHex: 0xF59A32)
    static let deepOrange = Color(dinoHex: 0xC45E00)
    static let disabledBackground = Color(uiColor: .systemGray5)
    static let disabledSelection = Color(uiColor: .systemGray4)
    static let disabledBorder = Color(uiColor: .systemGray3)

    static func disabledInk(_ highContrast: Bool) -> Color {
        Color(dinoHex: highContrast ? 0x3A3A3C : 0x636366)
    }

    static func wrong(_ highContrast: Bool) -> Color {
        highContrast ? deepOrange : orange
    }
}

private struct CustomizationTypeScaleKey: EnvironmentKey { static let defaultValue: CGFloat = 1 }
private struct CustomizationMetricsKey: EnvironmentKey { static let defaultValue = CustomizationMetrics() }

/// Use the available window, including iPad split view, rather than the device model.
struct CustomizationMetrics {
    var spacious = false
    var sideBySide = false
    var contentWidth: CGFloat { spacious ? 740 : 520 }
    var footerWidth: CGFloat { spacious ? 760 : 540 }
    var enlargement: CGFloat { spacious ? 1.3 : 1 }
    var previewSize: CGFloat { spacious ? 270 : 180 }
    var swatchSize: CGFloat { spacious ? 40 : 28 }
    var controlHeight: CGFloat { spacious ? 60 : 44 }

    init(size: CGSize = .zero) {
        spacious = size.width >= 650
        sideBySide = size.width >= 900 && size.height < 900
    }
}

/// Shared rhythm for the Dino, analog and digital customization menus.
enum CustomizationLayout {
    static let sectionSpacing: CGFloat = 12
    static let labelSpacing: CGFloat = 12
    static let restoreSpacing: CGFloat = 4
    // A 28-point swatch is centered in a 44-point tap area.
    static let swatchInset: CGFloat = 8
    static let choiceSpacing: CGFloat = 10
    static let previewPadding: CGFloat = 8
}

/// Every option heading shares its typography and distance to the controls below.
struct CustomizationSection<Content: View>: View {
    @Environment(\.customizationMetrics) private var metrics
    let title: String
    let identifier: String
    var controlSpacing: CGFloat = CustomizationLayout.labelSpacing
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: controlSpacing * metrics.enlargement) {
            Text(LocalizedStringKey(title)).modifier(CustomizationText())
                .frame(maxWidth: .infinity).accessibilityIdentifier(identifier)
            content
        }.frame(maxWidth: .infinity)
    }
}

struct CustomizationOptionsCard: ViewModifier {
    @Environment(\.customizationMetrics) private var metrics
    func body(content: Content) -> some View {
        content.dinoCard(padding: metrics.spacious ? 24 : 16)
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 16)
            .frame(maxWidth: metrics.contentWidth).frame(maxWidth: .infinity)
    }
}

struct CustomizationWidth: ViewModifier {
    @Environment(\.customizationMetrics) private var metrics
    var footer = false
    func body(content: Content) -> some View {
        content.frame(maxWidth: footer ? metrics.footerWidth : metrics.contentWidth).frame(maxWidth: .infinity)
    }
}

extension EnvironmentValues {
    var customizationMetrics: CustomizationMetrics {
        get { self[CustomizationMetricsKey.self] }
        set { self[CustomizationMetricsKey.self] = newValue }
    }
    var customizationTypeScale: CGFloat {
        get { self[CustomizationTypeScaleKey.self] }
        set { self[CustomizationTypeScaleKey.self] = newValue }
    }
}

/// Fit every editor's labels together, including labels on pages that are offscreen.
/// No individual choice may shrink independently when a translated label is longer.
struct CustomizationTypography: ViewModifier {
    @ObservedObject private var language = LanguageManager.shared
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    var optionsInset: CGFloat = 64

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            let metrics = CustomizationMetrics(size: geometry.size)
            content.environment(\.customizationMetrics, metrics)
                .environment(\.customizationTypeScale, scale(for: geometry.size.width, metrics: metrics))
        }
    }

    private func scale(for width: CGFloat, metrics: CustomizationMetrics) -> CGFloat {
        let card = max(1, min(metrics.contentWidth, width) - optionsInset - (metrics.spacious ? 16 : 0))
        var scale = metrics.enlargement
        func fit(_ keys: [String], in available: CGFloat, size: CGFloat = 17, weight: UIFont.Weight = .bold) {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            let font = UIFont(descriptor: base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor, size: size)
            let longest = keys.map { (L(key: $0) as NSString).size(withAttributes: [.font: font]).width }.max() ?? 1
            scale = min(scale, max(1, available) / max(1, longest))
        }
        fit(["dino.shape.circle", "dino.shape.square", "dino.shape.octagon"], in: (card - 16) / 3 - 12)
        fit(["dino.analogNumerals.normal", "dino.analogNumerals.roman",
             "dino.hourNotation.twelve", "dino.hourNotation.twentyFour"], in: (card - 8) / 2 - 16)
        fit(["dino.appearance.bandana", "dino.appearance.spikes", "dino.appearance.body", "dino.appearance.belly",
             "dino.hourHand", "dino.minuteHand", "dino.face", "dino.rim", "dino.digitColor", "dino.display", "dino.numerals"], in: card)
        fit(["dino.appearance.reset", "dino.clock.restoreStyle"], in: card - 28)
        fit(["dino.personalize.dino", "dino.personalize.analog", "dino.personalize.digital"],
            in: (min(metrics.contentWidth, width) - 48) / 3 - 16)
        fit(["dino.next", "dino.useMyClock", "dino.done"], in: min(metrics.footerWidth, width) - 100)
        fit(["dino.appearance.welcome", "dino.makeAnalogClock", "dino.makeDigitalClock"], in: width - 40,
            size: verticalSizeClass == .compact ? 24 : 29, weight: .heavy)
        return scale
    }
}

struct CustomizationText: ViewModifier {
    @Environment(\.customizationTypeScale) private var scale
    var multiline = false

    func body(content: Content) -> some View {
        content.font(.system(size: 17 * scale, weight: .bold, design: .rounded))
            .multilineTextAlignment(.center).lineLimit(multiline ? nil : 1)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct CustomizationTitle: ViewModifier {
    @Environment(\.customizationTypeScale) private var scale
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    func body(content: Content) -> some View {
        content.font(.system(size: (verticalSizeClass == .compact ? 24 : 29) * scale, weight: .heavy, design: .rounded))
            .multilineTextAlignment(.center).lineLimit(1)
    }
}

/// The welcome flow navigates by dragging its noninteractive Dino or clock preview.
struct PersonalizationPreviewNavigation: ViewModifier {
    var onNavigate: ((Int) -> Void)?

    @ViewBuilder func body(content: Content) -> some View {
        if let onNavigate {
            content.contentShape(Rectangle())
                .simultaneousGesture(DragGesture(minimumDistance: 24).onEnded { value in
                    let movement = value.translation
                    guard abs(movement.width) >= 50, abs(movement.width) > abs(movement.height) * 1.25 else { return }
                    onNavigate(movement.width < 0 ? 1 : -1)
                })
        } else {
            content
        }
    }
}

/// A joined badge and pointer, with black numbers independent of clock colors.
struct ClockHintBadgeArrow: View {
    let number: Int
    let badge: CGPoint
    let tip: CGPoint
    let wings: [CGPoint]
    let ink: UInt32
    let bounds: CGSize

    var body: some View {
        ZStack {
            Canvas { context, _ in
                var arrow = Path()
                // Starting inside the badge removes the gap and the seam at its edge.
                arrow.move(to: badge); arrow.addLine(to: tip)
                for wing in wings {
                    arrow.move(to: tip); arrow.addLine(to: wing)
                }
                func disk(_ radius: CGFloat) -> Path {
                    Path(ellipseIn: CGRect(x: badge.x - radius, y: badge.y - radius,
                                           width: radius * 2, height: radius * 2))
                }
                // Each layer covers both parts, giving one continuous outline.
                context.stroke(arrow, with: .color(.white), style: StrokeStyle(lineWidth: 7.5, lineCap: .round, lineJoin: .round))
                context.fill(disk(14.5), with: .color(.white))
                context.stroke(arrow, with: .color(.black), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                context.fill(disk(13.25), with: .color(.black))
                context.stroke(arrow, with: .color(Color(dinoHex: ink)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                context.fill(disk(12), with: .color(.white))
            }
            Text(verbatim: "\(number)")
                .font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(.black)
                .frame(width: 24, height: 24).position(badge)
        }.frame(width: bounds.width, height: bounds.height)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Clock controls keep the same colors regardless of the player's clock theme.
struct DinoClockControlButtonStyle: ButtonStyle {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.isEnabled) private var isEnabled
    var selected = true
    var expands = false
    var compact = false
    /// Fixed size keeps +1 and +30 on the same button. Nil follows the label.
    var width: CGFloat? = nil
    var height: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 15 : 17, weight: .bold, design: .rounded))
            .foregroundStyle(isEnabled ? (selected ? Color.white : DinoStyle.ink) : DinoStyle.disabledInk(highContrast))
            .lineLimit(1)
            .padding(.horizontal, width == nil ? (compact ? 12 : 18) : 0)
            .frame(width: width, height: height)
            .frame(minHeight: height ?? (compact ? 40 : 48))
            .frame(maxWidth: expands ? .infinity : nil)
            .background(isEnabled ? (selected ? DinoStyle.ink : .white) : DinoStyle.disabledBackground,
                        in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(isEnabled ? DinoStyle.ink.opacity(highContrast || selected ? 1 : 0.22)
                    : highContrast ? DinoStyle.disabledInk(true) : DinoStyle.disabledBorder,
                              lineWidth: highContrast ? 3 : 1.5))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }

    private var cornerRadius: CGFloat { height == nil ? 14 : 18 }
}

struct DinoButtonStyle: ButtonStyle {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.customizationTypeScale) private var customizationScale
    var color = DinoStyle.green
    var compact = false
    var customization = false
    var inkLabel = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: customization ? 17 * customizationScale : compact ? 17 : 20, weight: .bold, design: .rounded))
            .foregroundStyle(inkLabel || color == DinoStyle.green ? DinoStyle.ink : .white)
            .padding(.horizontal, compact ? 16 : 24)
            .frame(minHeight: customization ? max(58, 58 * customizationScale) : compact ? 48 : 58)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [color, color.opacity(highContrast ? 1 : 0.88)], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(inkLabel ? DinoStyle.ink.opacity(highContrast ? 1 : 0.12) : (highContrast ? DinoStyle.ink : .white.opacity(0.22)), lineWidth: highContrast ? 3 : 2))
                    .shadow(color: (inkLabel ? DinoStyle.ink : color).opacity(inkLabel ? 0.22 : 0.36), radius: 0, y: configuration.isPressed ? 1 : 5)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct DinoSecondaryButtonStyle: ButtonStyle {
    @Environment(\.dinoHighContrast) private var highContrast
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(DinoStyle.ink)
            .padding(.horizontal, 20)
            .frame(minHeight: 52)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(highContrast ? 1 : configuration.isPressed ? 0.6 : 0.95), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(DinoStyle.ink.opacity(highContrast ? 1 : 0.1), lineWidth: highContrast ? 3 : 1.5))
    }
}

/// Disabled choices retain their contrast so the child can inspect the answer.
struct DinoAnswerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct DinoIconButton: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let icon: String
    let labelKey: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(DinoStyle.ink)
                .frame(width: 48, height: 48)
                .background(.white.opacity(highContrast ? 1 : 0.9), in: RoundedRectangle(cornerRadius: 17))
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(highContrast ? DinoStyle.ink : .white, lineWidth: highContrast ? 3 : 1.5))
                .shadow(color: DinoStyle.ink.opacity(0.08), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}

struct DinoCard: ViewModifier {
    @Environment(\.dinoHighContrast) private var highContrast
    var padding: CGFloat = 20
    func body(content: Content) -> some View {
        content.padding(padding)
            .background(.white.opacity(highContrast ? 1 : 0.96), in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(highContrast ? DinoStyle.ink : .white, lineWidth: highContrast ? 3 : 2))
            .shadow(color: DinoStyle.deepGreen.opacity(0.08), radius: 18, y: 8)
    }
}

extension View { func dinoCard(padding: CGFloat = 20) -> some View { modifier(DinoCard(padding: padding)) } }

/// Shared reward art keeps the result, map nodes and star totals visually consistent.
struct DinoRewardStar: View {
    @Environment(\.dinoHighContrast) private var highContrast
    var size: CGFloat = 25
    var earned = true
    var dimmed = false
    var glowing = false
    var showsSparkle = false

    var body: some View {
        ZStack {
            if earned && glowing {
                Image("result-star").resizable().scaledToFit()
                    .blur(radius: size * 0.13).opacity(0.65)
                    .scaleEffect(1.12)
            }
            Image("result-star").resizable().scaledToFit()
                .saturation(earned ? 1 : 0)
                .brightness(earned ? 0 : -0.12)
                .shadow(color: Color(dinoHex: 0x653809).opacity(earned ? 0.35 : 0.18),
                        radius: max(0.5, size * 0.03), y: max(0.7, size * 0.05))
                .shadow(color: highContrast ? DinoStyle.ink.opacity(0.65) : .clear, radius: 0.5, y: 0.5)
                .opacity(dimmed ? (highContrast ? 0.75 : 0.48) : 1)
            if earned && showsSparkle {
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.16, weight: .bold))
                    .foregroundStyle(Color(dinoHex: 0xFFFFE4))
                    .shadow(color: Color(dinoHex: 0xFFE24A), radius: 3)
                    .offset(x: -size * 0.20, y: -size * 0.22)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct DinoStars: View {
    let count: Int
    var size: CGFloat = 25
    var showEmpty = true
    var body: some View {
        HStack(spacing: max(1, size * 0.045)) {
            ForEach(0..<3, id: \.self) { index in
                if showEmpty || index < count {
                    DinoRewardStar(size: size, earned: index < count, dimmed: index >= count)
                        .rotationEffect(.degrees(index == 1 ? 0 : index == 0 ? -6 : 6))
                        .offset(y: index == 1 ? -size * 0.10 : 0)
                }
            }
        }
    }
}

struct JungleLeaf: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.minX - rect.width * 0.2, y: rect.minY - rect.height * 0.2))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY),
                       control: CGPoint(x: rect.maxX + rect.width * 0.2, y: rect.maxY + rect.height * 0.2))
        return p
    }
}

struct JungleBackground: View {
    @Environment(\.dinoHighContrast) private var highContrast
    var quiet = false
    var body: some View {
        GeometryReader { _ in
            ZStack {
                LinearGradient(colors: quiet
                               ? [Color(dinoHex: 0xF0F8E8), DinoStyle.paper]
                               : [Color(dinoHex: 0xDBF4BB), Color(dinoHex: 0xEFF8E2), Color(dinoHex: 0xD0EBAD)],
                               startPoint: .top, endPoint: .bottom)
                JungleVista(quiet: quiet).opacity(highContrast && quiet ? 0.25 : 1)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension Text {
    /// `Text.foregroundStyle` returns `Text` only on iOS 17, which canvas drawing needs.
    /// Earlier systems use the same color through `foregroundColor`.
    func canvasInk(_ color: Color) -> Text {
        if #available(iOS 17, *) {
            return self.foregroundStyle(color)
        }
        return self.foregroundColor(color)
    }
}

extension Animation {
    /// The same settle used by the journey card. iOS 17 has a duration/bounce spring;
    /// earlier systems use the response/damping spring with the same timing.
    static var dinoSettle: Animation {
        if #available(iOS 17, *) {
            return .spring(duration: 0.5, bounce: 0.16)
        }
        return .spring(response: 0.5, dampingFraction: 0.84)
    }
}

extension View {
    /// Reports layout changes, including movement inside a scroll view.
    /// iOS 18 uses the system callback; earlier systems use a geometry preference.
    func readGeometry<T: Equatable>(for type: T.Type, of transform: @escaping (GeometryProxy) -> T, action: @escaping (T) -> Void) -> some View {
        modifier(GeometryProbe(transform: transform, action: action))
    }

    /// Observes a value. `initial` matches the iOS 17 `onChange` flag.
    func onValueChange<T: Equatable>(of value: T, initial: Bool = false, perform action: @escaping (T) -> Void) -> some View {
        modifier(ValueChangeProbe(value: value, initial: initial, action: action))
    }

    /// Centers content that is shorter than the scroll view, without moving the initial offset of taller content.
    @ViewBuilder func centersShortContent() -> some View {
        if #available(iOS 18, *) {
            self.defaultScrollAnchor(.center, for: .alignment)
        } else {
            self
        }
    }

    @ViewBuilder func bouncesOnlyWhenNeeded() -> some View {
        if #available(iOS 16.4, *) {
            self.scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
    }

    /// Page-sized sheets on iOS 18. Earlier systems keep the large detent already applied by the caller.
    @ViewBuilder func pagePresentation() -> some View {
        if #available(iOS 18, *) {
            self.presentationSizing(.page)
        } else {
            self
        }
    }

    @ViewBuilder func numericTextTransition() -> some View {
        if #available(iOS 17, *) {
            self.contentTransition(.numericText())
        } else {
            self
        }
    }

    @ViewBuilder func opacityTextTransition() -> some View {
        if #available(iOS 17, *) {
            self.contentTransition(.opacity)
        } else {
            self
        }
    }
}

/// Gives short scroll content a centered minimum height before iOS 18's alignment scroll anchor exists.
struct ShortScrollCentering: ViewModifier {
    var height: CGFloat
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 18, *) {
            content
        } else {
            content.frame(minHeight: height, alignment: .center)
        }
    }
}

private struct GeometryProbeKey<T: Equatable>: PreferenceKey {
    static var defaultValue: T? { nil }
    static func reduce(value: inout T?, nextValue: () -> T?) {
        if let next = nextValue() { value = next }
    }
}

private struct GeometryProbe<T: Equatable>: ViewModifier {
    let transform: (GeometryProxy) -> T
    let action: (T) -> Void
    @State private var last: T?

    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 18, *) {
            content.onGeometryChange(for: T.self, of: transform, action: action)
        } else {
            content.background {
                GeometryReader { proxy in
                    Color.clear.preference(key: GeometryProbeKey<T>.self, value: transform(proxy))
                }
                .onPreferenceChange(GeometryProbeKey<T>.self) { value in
                    guard let value, value != last else { return }
                    last = value
                    action(value)
                }
                .transformPreference(GeometryProbeKey<T>.self) { $0 = nil }
            }
        }
    }
}

private struct ValueChangeProbe<T: Equatable>: ViewModifier {
    let value: T
    let initial: Bool
    let action: (T) -> Void

    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 17, *) {
            content.onChange(of: value, initial: initial) { _, newValue in action(newValue) }
        } else {
            content.background {
                Color.clear.frame(width: 0, height: 0)
                    .onAppear { if initial { action(value) } }
                    .onChange(of: value) { newValue in action(newValue) }
            }
        }
    }
}
