import SwiftUI
import UIKit
import CoreText

/// The title and scenery are native drawing; only the player's recolored Dino is a sprite.
struct MapOpeningView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    let world: DinoWorld
    let image: UIImage?
    let jumpImages: [String: UIImage]
    let destination: CGRect?
    let ready: Bool
    var reveal: () -> Void
    var finished: () -> Void
    @State private var emergence: CGFloat = 0
    @State private var emerged = false
    @State private var departing = false
    @State private var jumpStartedAt: Date?
    @State private var sceneryOpacity = 1.0

    var body: some View {
        GeometryReader { geometry in
            // One square composition stays centred on phones and both iPad orientations.
            let side = min(580, geometry.size.width * 0.91, geometry.size.height * 0.82)
            let origin = CGPoint(x: (geometry.size.width - side) / 2,
                                 y: (geometry.size.height - side) / 2)
            let source = CGPoint(x: geometry.size.width / 2, y: origin.y + side * 0.49)
            let dinoSide = side * 1.02
            let title = OpeningTitleGeometry.cached(first: L("dino.launch.title.firstLine"),
                                                    second: L("dino.launch.title.secondLine"))
            let board = CGRect(x: source.x - side * 0.475, y: origin.y + side * 0.535,
                               width: side * 0.95, height: side * 0.95 * OpeningTitleGeometry.aspect)
            let boardScale = board.width / OpeningTitleGeometry.width
            let headEdge = title.headClearance * boardScale + board.minY
            let hiddenOffset = headEdge + 3 - (source.y - dinoSide / 2 + dinoSide * 0.012)
            ZStack {
                OpeningBackdrop(tint: Color(dinoHex: world.ground))
                    .opacity(sceneryOpacity)
                OpeningClock(size: side * 0.83, paused: reduceMotion || scenePhase != .active)
                    .position(x: source.x, y: origin.y + side * 0.43)
                    .scaleEffect(departing && !reduceMotion ? 1.07 : 1)
                    .opacity(sceneryOpacity)
                OpeningFoliage()
                    .frame(width: side, height: side * 1.13)
                    .position(x: geometry.size.width / 2, y: origin.y + side * 0.565)
                    .opacity(sceneryOpacity)
                if let image {
                    OpeningEmergingDino(image: image, jumpImages: jumpImages,
                        flight: OpeningDinoFlight(source: source, sourceSide: dinoSide,
                            destination: destination ?? CGRect(x: source.x - dinoSide / 2,
                                y: source.y - dinoSide / 2, width: dinoSide, height: dinoSide)),
                        revealMask: OpeningDinoRevealMask(edge: title.revealEdge, board: board, release: 0),
                        hiddenOffset: hiddenOffset, revealed: emergence > 0,
                        jumpStartedAt: jumpStartedAt, reducedMotion: reduceMotion)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .opacity(reduceMotion ? Double(emergence) * sceneryOpacity : 1)
                        // Keep the board's occlusion through takeoff; Dino clears its
                        // top edge naturally instead of popping his feet in front.
                        .zIndex(1)
                        .accessibilityHidden(true)
                }
                OpeningTitleBoard(artwork: title)
                    .frame(width: board.width, height: board.height)
                    .position(x: board.midX, y: board.midY)
                    .offset(y: departing && !reduceMotion ? side * 0.09 : 0)
                    .opacity(sceneryOpacity)
                    .zIndex(2)
            }
            .task(id: image != nil && scenePhase == .active) {
                guard image != nil, scenePhase == .active, !emerged else { return }
                do {
                    // Commit an actually hidden pose before starting the native rise.
                    // The image's own layer keeps moving while the map is prepared.
                    try await Task.sleep(for: .milliseconds(80))
                    try Task.checkCancellation()
                    withAnimation(reduceMotion ? .easeOut(duration: 0.2) : nil) { emergence = 1 }
                    try await Task.sleep(for: .seconds(reduceMotion ? 0.2 : OpeningEmergingDino.duration))
                    try Task.checkCancellation()
                    emerged = true
                } catch { }
            }
            .task(id: ready && emerged && destination != nil && scenePhase == .active) {
                guard ready, emerged, destination != nil, scenePhase == .active else { return }
                // Returning from the background completes an interrupted flight.
                guard jumpStartedAt == nil else { finished(); return }
                do {
                    // A full second in the finished logo pose, after the color reveal.
                    try await Task.sleep(for: .seconds(1))
                    try Task.checkCancellation()
                    jumpStartedAt = Date()
                    if !reduceMotion { try await Task.sleep(for: .seconds(DinoOpeningJump.takeoff)) }
                    try Task.checkCancellation()
                    withAnimation(.easeOut(duration: reduceMotion ? 0.25 : 0.38)) {
                        sceneryOpacity = 0
                        departing = true
                        reveal()
                    }
                    try await Task.sleep(for: .seconds(reduceMotion ? 0.28 : DinoOpeningJump.duration - DinoOpeningJump.takeoff))
                    try Task.checkCancellation()
                    finished()
                } catch { }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("map.preparing")
        .allowsHitTesting(false)
    }
}

/// Emergence, flight, pose changes and occlusion share the render server's clock.
/// Preparing/revealing the SwiftUI map cannot stall Dino halfway through a jump.
private struct OpeningEmergingDino: UIViewRepresentable {
    static let duration = 0.82
    let image: UIImage
    let jumpImages: [String: UIImage]
    let flight: OpeningDinoFlight
    let revealMask: OpeningDinoRevealMask
    let hiddenOffset: CGFloat
    let revealed: Bool
    let jumpStartedAt: Date?
    let reducedMotion: Bool
    func makeUIView(context: Context) -> OpeningDinoArtwork { OpeningDinoArtwork() }
    func updateUIView(_ view: OpeningDinoArtwork, context: Context) {
        view.update(image: image, images: jumpImages, flight: flight, revealMask: revealMask,
                    hiddenOffset: hiddenOffset, revealed: revealed,
                    jumpStartedAt: jumpStartedAt, reducedMotion: reducedMotion)
    }
}

private final class OpeningDinoArtwork: UIView {
    private let sprite = CALayer()
    private let artwork = CALayer()
    private let occlusion = CAShapeLayer()
    private var flight: OpeningDinoFlight?
    private var revealMask: OpeningDinoRevealMask?
    private var hasEmerged = false
    private var hasJumped = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        sprite.opacity = 0
        sprite.anchorPoint = CGPoint(x: 0.5, y: OpeningDinoFlight.footline)
        sprite.shadowColor = UIColor(red: 0.12, green: 0.28, blue: 0.15, alpha: 1).cgColor
        sprite.shadowOpacity = 0.16
        sprite.shadowRadius = 7
        sprite.shadowOffset = CGSize(width: 0, height: 5)
        artwork.contentsGravity = .resizeAspect
        sprite.addSublayer(artwork)
        layer.addSublayer(sprite)
        occlusion.fillColor = UIColor.black.cgColor
        layer.mask = occlusion
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let flight, let revealMask, !hasJumped else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        placeAtSource(flight)
        occlusion.frame = bounds
        occlusion.path = revealMask.path(in: bounds).cgPath
        CATransaction.commit()
    }

    func update(image: UIImage, images: [String: UIImage], flight: OpeningDinoFlight,
                revealMask: OpeningDinoRevealMask, hiddenOffset: CGFloat, revealed: Bool,
                jumpStartedAt: Date?, reducedMotion: Bool) {
        guard !hasJumped else { return }
        self.flight = flight
        self.revealMask = revealMask
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        artwork.contents = image.cgImage
        placeAtSource(flight)
        occlusion.frame = bounds
        occlusion.path = revealMask.path(in: bounds).cgPath
        if revealed, !hasEmerged {
            hasEmerged = true
            sprite.opacity = 1
            if !reducedMotion {
                let rise = CABasicAnimation(keyPath: "transform.translation.y")
                rise.fromValue = hiddenOffset
                rise.toValue = 0
                rise.duration = OpeningEmergingDino.duration
                rise.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.62, 0.3, 1)
                sprite.add(rise, forKey: "opening.emerge")
            }
        }
        if let jumpStartedAt, !reducedMotion {
            hasJumped = true
            jump(image: image, images: images, flight: flight, mask: revealMask, startedAt: jumpStartedAt)
        }
        CATransaction.commit()
    }

    private func placeAtSource(_ flight: OpeningDinoFlight) {
        sprite.bounds = CGRect(x: 0, y: 0, width: flight.sourceSide, height: flight.sourceSide)
        sprite.position = flight.position(elapsed: 0)
        artwork.bounds = sprite.bounds
        artwork.position = CGPoint(x: flight.sourceSide / 2, y: flight.sourceSide / 2)
    }

    private func jump(image: UIImage, images: [String: UIImage], flight: OpeningDinoFlight,
                      mask: OpeningDinoRevealMask, startedAt: Date) {
        guard let idle = image.cgImage else { return }
        let duration = DinoOpeningJump.duration
        // Queue the complete choreography once. Core Animation interpolates the
        // dense geometry at display refresh rate and swaps faces discretely.
        let steps = Int(ceil(duration * 120))
        let times = (0...steps).map { Double($0) / Double(steps) }
        let positions = times.map { NSValue(cgPoint: flight.position(elapsed: $0 * duration)) }
        let transforms = times.map { NSValue(caTransform3D: flight.transform(elapsed: $0 * duration)) }
        let keyTimes = times.map { NSNumber(value: $0) }
        let begin = sprite.convertTime(CACurrentMediaTime(), from: nil) - max(0, Date().timeIntervalSince(startedAt))
        func animation(_ key: String, values: [Any], times: [NSNumber], discrete: Bool = false) -> CAKeyframeAnimation {
            let animation = CAKeyframeAnimation(keyPath: key)
            animation.values = values
            animation.keyTimes = times
            animation.calculationMode = discrete ? .discrete : .linear
            animation.duration = duration
            return animation
        }
        let group = CAAnimationGroup()
        group.animations = [animation("position", values: positions, times: keyTimes),
                            animation("transform", values: transforms, times: keyTimes)]
        group.duration = duration
        group.beginTime = begin
        group.timingFunction = CAMediaTimingFunction(name: .linear)
        sprite.position = flight.position(elapsed: duration)
        sprite.transform = flight.transform(elapsed: duration)
        sprite.add(group, forKey: "opening.flight")

        let poseTimes = (DinoOpeningJump.poseStarts + [duration]).map { NSNumber(value: $0 / duration) }
        let poses = (DinoOpeningJump.poseStarts + [duration]).map { DinoOpeningJump.sample(elapsed: $0).pose }
        let contents = poses.map { images[$0.asset]?.cgImage ?? idle }
        let offsets = poses.map { NSValue(cgPoint: CGPoint(x: flight.sourceSide * (0.5 + $0.offsetX),
                                                          y: flight.sourceSide * (0.5 + $0.offsetY))) }
        let poseGroup = CAAnimationGroup()
        poseGroup.animations = [animation("contents", values: contents, times: poseTimes, discrete: true),
                                animation("position", values: offsets, times: poseTimes, discrete: true)]
        poseGroup.duration = duration
        poseGroup.beginTime = begin
        artwork.contents = image.cgImage
        artwork.position = CGPoint(x: flight.sourceSide / 2, y: flight.sourceSide / 2)
        artwork.add(poseGroup, forKey: "opening.poses")

        let masks = times.map { time -> CGPath in
            var value = mask
            value.release = CGFloat(DinoOpeningJump.travelProgress(elapsed: time * duration))
            return value.path(in: bounds).cgPath
        }
        let reveal = animation("path", values: masks, times: keyTimes)
        reveal.beginTime = begin
        occlusion.path = masks.last
        occlusion.add(reveal, forKey: "opening.clearBoard")
    }
}

private struct OpeningDinoRevealMask: Shape {
    let edge: [CGPoint]
    let board: CGRect
    var release: CGFloat
    var animatableData: CGFloat {
        get { release }
        set { release = newValue }
    }
    func path(in rect: CGRect) -> Path {
        let scale = board.width / OpeningTitleGeometry.width
        let drop = min(1, max(0, release * 2.5)) * (rect.height + board.height)
        let firstY = board.minY + (edge.first?.y ?? 0) * scale + drop
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: firstY))
        for point in edge.reversed() {
            path.addLine(to: CGPoint(x: board.minX + point.x * scale, y: board.minY + point.y * scale + drop))
        }
        path.addLine(to: CGPoint(x: 0, y: firstY))
        path.closeSubpath()
        return path
    }
}

/// Geometry is sampled once for native playback, with the painted foot line as
/// the anchor so compression and the final handoff cannot slide along the rock.
private struct OpeningDinoFlight {
    static let footline = CGFloat(1211.0 / 1254)
    let source: CGPoint
    let sourceSide: CGFloat
    let destination: CGRect

    func position(elapsed: Double) -> CGPoint {
        let t = CGFloat(DinoOpeningJump.travelProgress(elapsed: elapsed))
        let side = sourceSide + (destination.width - sourceSide) * t
        let desiredArc = sourceSide * 0.48 + max(0, destination.midY - source.y) * 0.2
        let clearance = max(24, source.y - sourceSide / 2 - 16)
        let arc = -CGFloat(DinoOpeningJump.sample(elapsed: elapsed).height) * min(250, desiredArc, clearance)
        return CGPoint(x: source.x + (destination.midX - source.x) * t,
                       y: source.y + (destination.midY - source.y) * t + (Self.footline - 0.5) * side - arc)
    }
    func transform(elapsed: Double) -> CATransform3D {
        let t = CGFloat(DinoOpeningJump.travelProgress(elapsed: elapsed))
        let scale = 1 + (destination.width / sourceSide - 1) * t
        let sample = DinoOpeningJump.sample(elapsed: elapsed)
        let rotation = CATransform3DMakeRotation(CGFloat(sample.angle * .pi / 180), 0, 0, 1)
        return CATransform3DScale(rotation, scale * sample.scaleX, scale * sample.scaleY, 1)
    }
}

private struct OpeningClock: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let size: CGFloat
    let paused: Bool
    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Color(dinoHex: 0xD9F8A0), Color(dinoHex: 0x81D349),
                Color(dinoHex: 0x38852C)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: Color(dinoHex: 0x315B38).opacity(0.17), radius: size * 0.045, y: size * 0.025)
            Circle().strokeBorder(Color(dinoHex: 0xE8FFD1), lineWidth: size * 0.008)
            Circle().inset(by: size * 0.012).strokeBorder(Color(dinoHex: 0x4C9C31).opacity(0.6), lineWidth: size * 0.004)
            OpeningClockFace(paused: paused, highContrast: highContrast).frame(width: size * 0.92, height: size * 0.92)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Core Animation keeps the default clock's hands moving even while the main
/// thread prepares the map's first terrain images. All artwork remains native.
private struct OpeningClockFace: UIViewRepresentable {
    let paused: Bool
    let highContrast: Bool
    func makeUIView(context: Context) -> OpeningClockArtwork { OpeningClockArtwork() }
    func updateUIView(_ view: OpeningClockArtwork, context: Context) {
        view.paused = paused
        view.highContrast = highContrast
    }
}

private final class OpeningClockArtwork: UIView {
    private let hour = CAShapeLayer()
    private let minute = CAShapeLayer()
    private let pin = CAShapeLayer()
    private let pinHighlight = CAShapeLayer()
    private let theme: ClockTheme = {
        var theme = ClockTheme.standard
        theme.customRimHex = 0x367B2B
        return theme
    }()
    var paused = false { didSet { updatePlayback() } }
    var highContrast = false { didSet { if highContrast != oldValue { setNeedsDisplay() } } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        contentMode = .redraw
        isAccessibilityElement = false
        for hand in [hour, minute, pin, pinHighlight] { layer.addSublayer(hand) }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func ink(_ hex: UInt32, alpha: CGFloat = 1) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
                blue: CGFloat(hex & 255) / 255, alpha: alpha)
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let side = bounds.width
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        context.setFillColor(ink(theme.rimHex).cgColor)
        context.fillEllipse(in: bounds)
        context.setFillColor(ink(theme.faceHex).cgColor)
        context.fillEllipse(in: bounds.insetBy(dx: side * 0.034, dy: side * 0.034))
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.4).cgColor)
        context.setLineWidth(side * 0.008)
        context.strokeEllipse(in: bounds.insetBy(dx: side * 0.015, dy: side * 0.015))
        for tick in 0..<60 {
            let major = tick.isMultiple(of: 5)
            context.saveGState()
            context.translateBy(x: center.x, y: center.y)
            context.rotate(by: CGFloat(tick) * .pi / 30)
            let width = side * (major ? 0.012 : 0.005)
            let height = side * (major ? 0.045 : 0.023)
            ink(theme.markingHex, alpha: highContrast ? 1 : major ? 0.6 : 0.28).setFill()
            UIBezierPath(roundedRect: CGRect(x: -width / 2, y: -side * 0.425 - height / 2,
                width: width, height: height), cornerRadius: width / 2).fill()
            context.restoreGState()
        }
        let font = UIFont.systemFont(ofSize: side * 0.08, weight: .bold)
        let rounded = font.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: font.pointSize) } ?? font
        let attributes: [NSAttributedString.Key: Any] = [.font: rounded, .foregroundColor: ink(theme.markingHex)]
        for value in 1...12 {
            let a = CGFloat(value) * .pi / 6
            let label = String(value) as NSString
            let size = label.size(withAttributes: attributes)
            label.draw(at: CGPoint(x: center.x + sin(a) * side * 0.34 - size.width / 2,
                                   y: center.y - cos(a) * side * 0.34 - size.height / 2), withAttributes: attributes)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let side = bounds.width
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (hand, length, width, color) in [(hour, 0.23, 0.038, theme.hourHex), (minute, 0.34, 0.024, theme.minuteHex)] {
            hand.setAffineTransform(.identity)
            hand.frame = bounds
            hand.path = UIBezierPath(roundedRect: CGRect(x: bounds.midX - side * width / 2,
                y: bounds.midY - side * length, width: side * width, height: side * (length + 0.035)),
                cornerRadius: side * width / 2).cgPath
            hand.fillColor = ink(color).cgColor
        }
        pin.frame = bounds
        pin.path = UIBezierPath(ovalIn: bounds.insetBy(dx: side * 0.4575, dy: side * 0.4575)).cgPath
        pin.fillColor = ink(theme.rimHex).cgColor
        pinHighlight.frame = bounds
        pinHighlight.path = UIBezierPath(ovalIn: bounds.insetBy(dx: side * 0.4875, dy: side * 0.4875)).cgPath
        pinHighlight.fillColor = UIColor.white.cgColor
        hour.setAffineTransform(CGAffineTransform(rotationAngle: 305 * .pi / 180))
        minute.setAffineTransform(CGAffineTransform(rotationAngle: 60 * .pi / 180))
        CATransaction.commit()
        updatePlayback()
    }

    override func didMoveToWindow() { super.didMoveToWindow(); updatePlayback() }

    private func updatePlayback() {
        for (hand, angle, duration) in [(hour, 305.0, 60.0), (minute, 60.0, 5.0)] {
            guard !paused, window != nil else { hand.removeAnimation(forKey: "opening.turn"); continue }
            guard hand.animation(forKey: "opening.turn") == nil else { continue }
            let turn = CABasicAnimation(keyPath: "transform.rotation.z")
            turn.fromValue = angle * .pi / 180
            turn.toValue = (angle + 360) * .pi / 180
            turn.duration = duration
            turn.repeatCount = .infinity
            hand.add(turn, forKey: "opening.turn")
        }
    }
}

private struct OpeningBackdrop: View {
    let tint: Color
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(dinoHex: 0xE2E9D4)
                LinearGradient(colors: [Color(dinoHex: 0xECF5DD), Color(dinoHex: 0xE2EFD0),
                    tint.mixed(with: Color(dinoHex: 0xD2E8BB), by: 0.88)], startPoint: .top, endPoint: .bottom)
                RadialGradient(colors: [Color(dinoHex: 0xFFFDEE).opacity(0.95), .clear],
                               center: .center, startRadius: 10, endRadius: min(geometry.size.width, geometry.size.height) * 0.8)
                ForEach(0..<6, id: \.self) { index in
                    JungleLeaf().fill(Color(dinoHex: 0x4E8152).opacity(0.055))
                        .frame(width: 110 + CGFloat(index % 3) * 34, height: 185 + CGFloat(index % 2) * 45)
                        .rotationEffect(.degrees(Double(index * 47 - 35)))
                        .position(x: index.isMultiple(of: 2) ? 0 : geometry.size.width,
                                  y: geometry.size.height * CGFloat(index + 1) / 7)
                }
            }
        }.ignoresSafeArea().accessibilityHidden(true)
    }
}

/// Cached Core Text outlines shape both the letters and their surrounding wood.
/// The same vector construction supports every localized title and fallback font.
private final class OpeningTitleGeometry {
    static let width: CGFloat = 1000
    static let aspect: CGFloat = 0.56
    private static let cache = NSCache<NSString, OpeningTitleGeometry>()
    let first: CGPath
    let second: CGPath
    let wood: CGPath
    let face: CGPath
    let revealEdge: [CGPoint]
    let headClearance: CGFloat

    static func cached(first: String, second: String) -> OpeningTitleGeometry {
        let key = "\(first)\u{0}\(second)" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let result = OpeningTitleGeometry(first: first, second: second)
        cache.countLimit = 12
        cache.setObject(result, forKey: key)
        return result
    }
    private init(first top: String, second bottom: String) {
        first = Self.fitted(top, center: CGPoint(x: 500, y: 170), height: 220, maxWidth: 790, tilt: -0.045)
        second = Self.fitted(bottom, center: CGPoint(x: 500, y: 401), height: 188, maxWidth: 870, tilt: 0.018)
        let letters = first.union(second)
        wood = Self.expanded(letters, radius: 44)
        face = Self.expanded(letters, radius: 31)
        revealEdge = Self.upperEdge(of: Self.expanded(first, radius: 44))
        // Register the highest painted spike, rather than the transparent square.
        headClearance = revealEdge.filter { (405...500).contains($0.x) }.map(\.y).max() ?? 40
    }
    private static func expanded(_ path: CGPath, radius: CGFloat) -> CGPath {
        let outline = path.union(path.copy(strokingWithWidth: radius * 2, lineCap: .round, lineJoin: .round, miterLimit: 1))
        // Counters and small enclosed gaps belong to the wooden face too. Keep
        // only exterior contours, so no pinholes reveal scenery through the wood.
        var contours: [CGMutablePath] = []
        outline.applyWithBlock { pointer in
            let element = pointer.pointee
            if element.type == .moveToPoint { contours.append(CGMutablePath()) }
            guard let contour = contours.last else { return }
            switch element.type {
            case .moveToPoint: contour.move(to: element.points[0])
            case .addLineToPoint: contour.addLine(to: element.points[0])
            case .addQuadCurveToPoint: contour.addQuadCurve(to: element.points[1], control: element.points[0])
            case .addCurveToPoint: contour.addCurve(to: element.points[2], control1: element.points[0], control2: element.points[1])
            case .closeSubpath: contour.closeSubpath()
            @unknown default: break
            }
        }
        func area(_ contour: CGPath) -> CGFloat {
            var result: CGFloat = 0
            var previous = CGPoint.zero
            var start = CGPoint.zero
            contour.flattened(threshold: 1).applyWithBlock { pointer in
                let element = pointer.pointee
                switch element.type {
                case .moveToPoint: previous = element.points[0]; start = previous
                case .addLineToPoint:
                    let next = element.points[0]
                    result += previous.x * next.y - next.x * previous.y
                    previous = next
                case .closeSubpath: result += previous.x * start.y - start.x * previous.y
                default: break
                }
            }
            return result
        }
        let areas = contours.map { area($0) }
        let orientation = areas.max(by: { abs($0) < abs($1) }) ?? 1
        let filled = CGMutablePath()
        for (index, contour) in contours.enumerated() where areas[index] * orientation > 0 { filled.addPath(contour) }
        return filled
    }
    private static func fitted(_ text: String, center: CGPoint, height: CGFloat, maxWidth: CGFloat, tilt: CGFloat) -> CGPath {
        let base = UIFont.systemFont(ofSize: 240, weight: .black)
        let font = base.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: 240) } ?? base
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: font, .kern: -2]))
        let letters = CGMutablePath()
        for run in CTLineGetGlyphRuns(line) as! [CTRun] {
            let count = CTRunGetGlyphCount(run)
            var glyphs = [CGGlyph](repeating: 0, count: count)
            var positions = [CGPoint](repeating: .zero, count: count)
            CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)
            let runFont = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName] as! CTFont
            for index in 0..<count {
                if let glyph = CTFontCreatePathForGlyph(runFont, glyphs[index], nil) {
                    letters.addPath(glyph, transform: CGAffineTransform(a: 1, b: 0, c: 0, d: -1,
                        tx: positions[index].x, ty: -positions[index].y))
                }
            }
        }
        let bounds = letters.boundingBoxOfPath
        guard bounds.width > 0, bounds.height > 0 else { return letters }
        let scale = min(height / bounds.height, maxWidth / bounds.width)
        var fit = CGAffineTransform(a: scale, b: 0, c: 0, d: scale,
                                   tx: center.x - bounds.midX * scale, ty: center.y - bounds.midY * scale)
        let fitted = letters.copy(using: &fit) ?? letters
        var rotation = CGAffineTransform(translationX: center.x, y: center.y)
            .rotated(by: tilt).translatedBy(x: -center.x, y: -center.y)
        return fitted.copy(using: &rotation) ?? fitted
    }
    private static func upperEdge(of path: CGPath) -> [CGPoint] {
        // Sample vector segments once. Per-frame mask animation only moves this
        // short polyline, without re-running font shaping or path operations.
        let step: CGFloat = 4
        var values = [CGFloat](repeating: .greatestFiniteMagnitude, count: 251)
        var current = CGPoint.zero
        var start = CGPoint.zero
        func segment(_ a: CGPoint, _ b: CGPoint) {
            guard abs(b.x - a.x) > 0.001 else { return }
            let lower = max(0, Int(ceil(min(a.x, b.x) / step)))
            let upper = min(250, Int(floor(max(a.x, b.x) / step)))
            guard lower <= upper else { return }
            for index in lower...upper {
                let x = CGFloat(index) * step
                let y = a.y + (b.y - a.y) * (x - a.x) / (b.x - a.x)
                values[index] = min(values[index], y)
            }
        }
        path.flattened(threshold: 0.7).applyWithBlock { element in
            let element = element.pointee
            switch element.type {
            case .moveToPoint: current = element.points[0]; start = current
            case .addLineToPoint: segment(current, element.points[0]); current = element.points[0]
            case .closeSubpath: segment(current, start); current = start
            default: break
            }
        }
        return values.enumerated().map { index, y in
            // Outside the first word, keep the low tail completely behind the
            // logo rather than exposing small, horizontally clipped spike tips.
            CGPoint(x: CGFloat(index) * step, y: y.isFinite && y < 540 ? y : path.boundingBoxOfPath.minY - 36)
        }
    }
}

private struct OpeningTitleBoard: View {
    let artwork: OpeningTitleGeometry
    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / OpeningTitleGeometry.width, y: size.width / OpeningTitleGeometry.width)
            let wood = Path(artwork.wood)
            let face = Path(artwork.face)
            context.drawLayer { shadow in
                shadow.addFilter(.shadow(color: Color(dinoHex: 0x3F3218).opacity(0.27), radius: 15, y: 18))
                shadow.fill(wood.offsetBy(dx: 0, dy: 12), with: .color(Color(dinoHex: 0x5B2B10)))
            }
            context.fill(wood, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xF6BC69),
                Color(dinoHex: 0xA65B20), Color(dinoHex: 0x6D3514)]),
                startPoint: CGPoint(x: 200, y: 0), endPoint: CGPoint(x: 650, y: 540)))
            context.stroke(wood, with: .color(Color(dinoHex: 0x6B3215)), style: StrokeStyle(lineWidth: 4, lineJoin: .round))
            context.fill(face, with: .linearGradient(Gradient(stops: [
                .init(color: Color(dinoHex: 0xE8A552), location: 0),
                .init(color: Color(dinoHex: 0xC97C32), location: 0.35),
                .init(color: Color(dinoHex: 0xA45B24), location: 0.75),
                .init(color: Color(dinoHex: 0xBD7232), location: 1)
            ]), startPoint: CGPoint(x: 300, y: 0), endPoint: CGPoint(x: 600, y: 540)))
            context.stroke(face, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFE0A1),
                Color(dinoHex: 0xD79A56), Color(dinoHex: 0xEEB66F)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: 540)),
                style: StrokeStyle(lineWidth: 3.2, lineJoin: .round))
            context.drawLayer { grain in
                grain.clip(to: face)
                for row in 0..<18 {
                    let y = CGFloat(row) * 33
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: y))
                    line.addCurve(to: CGPoint(x: 1000, y: y + 7),
                        control1: CGPoint(x: 330, y: y - 28), control2: CGPoint(x: 650, y: y + 31))
                    grain.stroke(line, with: .color(Color(dinoHex: 0x7A3D19).opacity(row.isMultiple(of: 3) ? 0.23 : 0.12)), lineWidth: 2.4)
                    grain.stroke(line.offsetBy(dx: 0, dy: 3), with: .color(Color(dinoHex: 0xFFE0A3).opacity(0.14)), lineWidth: 1.2)
                }
            }
            title(artwork.first, in: &context, colors: [0xFFF5A0, 0xFFE14C, 0xFFBE23], edge: 0xB8640A)
            title(artwork.second, in: &context, colors: [0xD5F99A, 0x81D349, 0x4DAA30], edge: 0x2F771F)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: L("dino.launch.title.firstLine") + " " + L("dino.launch.title.secondLine")))
        .accessibilityIdentifier("map.opening.title")
    }
    private func title(_ glyphs: CGPath, in context: inout GraphicsContext, colors: [UInt32], edge: UInt32) {
        let path = Path(glyphs)
        let bounds = path.boundingRect
        context.stroke(path.offsetBy(dx: 0, dy: 12), with: .color(Color(dinoHex: 0x5C2B11).opacity(0.7)),
                       style: StrokeStyle(lineWidth: 12, lineJoin: .round))
        context.fill(path.offsetBy(dx: 0, dy: 9), with: .color(Color(dinoHex: edge)))
        context.stroke(path, with: .color(Color(dinoHex: edge)), style: StrokeStyle(lineWidth: 9, lineJoin: .round))
        context.fill(path, with: .linearGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
            startPoint: CGPoint(x: bounds.midX, y: bounds.minY), endPoint: CGPoint(x: bounds.midX, y: bounds.maxY)))
        context.drawLayer { highlight in
            highlight.clip(to: path)
            highlight.stroke(path.offsetBy(dx: 0, dy: 2.8), with: .color(Color(dinoHex: 0xFFFFCF).opacity(0.75)), lineWidth: 4)
        }
    }
}

/// A connected fan of individually shaded leaves, with folded faces, fine veins
/// and a shared stem. The title's actual contours leave these visible around it.
private struct OpeningFoliage: View {
    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 1000, y: size.width / 1000)
            for mirror in [false, true] {
                var fan = context
                if mirror { fan.translateBy(x: 1000, y: 0); fan.scaleBy(x: -1, y: 1) }
                var stem = Path()
                stem.move(to: CGPoint(x: 288, y: 1000))
                stem.addCurve(to: CGPoint(x: 237, y: 795), control1: CGPoint(x: 185, y: 975), control2: CGPoint(x: 280, y: 900))
                fan.stroke(stem, with: .color(Color(dinoHex: 0x205D30)), style: StrokeStyle(lineWidth: 13, lineCap: .round))
                fan.stroke(stem.offsetBy(dx: -2, dy: 0), with: .color(Color(dinoHex: 0x8CC85D)),
                           style: StrokeStyle(lineWidth: 5, lineCap: .round))
                let leaves: [(CGFloat, CGFloat, Double, CGFloat, CGFloat)] = [
                    (283, 118, -24, 242, 835), (284, 145, -48, 239, 844),
                    (248, 156, -75, 242, 856), (235, 165, -104, 245, 873),
                    (215, 149, -136, 254, 888), (218, 125, -165, 268, 907),
                    (185, 98, 4, 237, 823)
                ]
                for (index, spec) in leaves.enumerated() {
                    var c = fan
                    c.translateBy(x: spec.3, y: spec.4)
                    c.rotate(by: .degrees(spec.2))
                    leaf(length: spec.0, width: spec.1, light: index.isMultiple(of: 2), in: &c)
                }
            }
            for (x, y, radius, angle) in [(100.0, 405.0, 60.0, -14.0), (912.0, 520.0, 54.0, 14.0), (167.0, 957.0, 42.0, -12.0)] {
                var c = context
                c.translateBy(x: x, y: y)
                c.rotate(by: .degrees(angle))
                var star = Path()
                for index in 0..<10 {
                    let angle = Double(index) * .pi / 5 - .pi / 2
                    let r = index.isMultiple(of: 2) ? radius : radius * 0.49
                    let point = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
                    if index == 0 { star.move(to: point) } else { star.addLine(to: point) }
                }
                star.closeSubpath()
                c.addFilter(.shadow(color: Color(dinoHex: 0x70410C).opacity(0.24), radius: 3, y: 4))
                c.stroke(star, with: .color(Color(dinoHex: 0xD98A12)), style: StrokeStyle(lineWidth: 11, lineJoin: .round))
                c.fill(star, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFFFB1), Color(dinoHex: 0xFFE64A),
                    Color(dinoHex: 0xFFAF16)]), startPoint: CGPoint(x: -radius, y: -radius), endPoint: CGPoint(x: radius, y: radius)))
                c.drawLayer { bevel in
                    bevel.clip(to: star)
                    bevel.stroke(star.offsetBy(dx: 0, dy: 3), with: .color(Color(dinoHex: 0xFFFFD5).opacity(0.8)), lineWidth: 5)
                }
            }
        }.accessibilityHidden(true)
    }
    private func leaf(length: CGFloat, width: CGFloat, light: Bool, in context: inout GraphicsContext) {
        let offset = CGSize(width: -width / 2, height: -length)
        let bounds = CGRect(x: 0, y: 0, width: width, height: length)
        let shape = DinoFoliageLeaf().path(in: bounds).offsetBy(dx: offset.width, dy: offset.height)
        let fold = DinoFoliageFold().path(in: bounds).offsetBy(dx: offset.width, dy: offset.height)
        let veins = DinoFoliageVeins().path(in: bounds).offsetBy(dx: offset.width, dy: offset.height)
        context.drawLayer { shadow in
            shadow.addFilter(.blur(radius: 3))
            shadow.fill(shape.offsetBy(dx: 3, dy: 4), with: .color(Color(dinoHex: 0x17482E).opacity(0.3)))
        }
        context.fill(shape, with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: 0x236C36), location: 0),
            .init(color: Color(dinoHex: light ? 0x79C846 : 0x50A945), location: 0.25),
            .init(color: Color(dinoHex: light ? 0xB6E76D : 0x8ED65B), location: 0.44),
            .init(color: Color(dinoHex: 0x429D3C), location: 0.65),
            .init(color: Color(dinoHex: 0x195C36), location: 1)
        ]), startPoint: CGPoint(x: -width * 0.52, y: -length * 0.65), endPoint: CGPoint(x: width * 0.55, y: -length * 0.38)))
        context.fill(fold, with: .linearGradient(Gradient(colors: [.clear, Color(dinoHex: 0x195D31).opacity(0.38)]),
            startPoint: CGPoint(x: 0, y: -length), endPoint: .zero))
        context.drawLayer { detail in
            detail.clip(to: shape)
            detail.fill(shape, with: .radialGradient(Gradient(colors: [Color(dinoHex: 0xE8FFB3).opacity(0.3), .clear]),
                center: CGPoint(x: -width * 0.17, y: -length * 0.72), startRadius: 0, endRadius: width * 0.64))
            for index in 1...5 {
                let t = CGFloat(index) / 6
                let center = CGPoint(x: width * (0.02 + t * 0.10), y: -length * (0.14 + t * 0.68))
                for sign: CGFloat in [-1, 1] {
                    var vein = Path()
                    vein.move(to: center)
                    vein.addQuadCurve(to: CGPoint(x: center.x + sign * width * 0.39, y: center.y - length * 0.13),
                        control: CGPoint(x: center.x + sign * width * 0.22, y: center.y - length * 0.035))
                    detail.stroke(vein, with: .color(Color(dinoHex: 0xD7F89B).opacity(0.34)),
                                  style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                }
            }
        }
        context.stroke(veins.offsetBy(dx: 1.3, dy: 1), with: .color(Color(dinoHex: 0x225F32).opacity(0.55)),
                       style: StrokeStyle(lineWidth: 2.3, lineCap: .round))
        context.stroke(veins, with: .color(Color(dinoHex: 0xD0EE8B).opacity(0.7)),
                       style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
        context.stroke(shape, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xD2F59A).opacity(0.9),
            Color(dinoHex: 0x245B32).opacity(0.5)]), startPoint: CGPoint(x: -width * 0.3, y: -length), endPoint: .zero),
            lineWidth: 2.2)
    }
}

