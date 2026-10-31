import SwiftUI

private struct ClockReadingAssistanceKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var dinoClockReadingAssistance: Bool {
        get { self[ClockReadingAssistanceKey.self] }
        set { self[ClockReadingAssistanceKey.self] = newValue }
    }
}

struct AnalogClockOutline: InsettableShape {
    var shape: AnalogClockShape
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let bounds = rect.insetBy(dx: insetAmount, dy: insetAmount)
        switch shape {
        case .circle: return Path(ellipseIn: bounds)
        case .square: return Path(roundedRect: bounds, cornerRadius: min(bounds.width, bounds.height) * 0.025)
        case .octagon:
            var path = Path()
            let corner = 1 / (2 + sqrt(2.0))
            let vertices: [CGPoint] = [
                CGPoint(x: corner, y: 0), CGPoint(x: 1 - corner, y: 0),
                CGPoint(x: 1, y: corner), CGPoint(x: 1, y: 1 - corner),
                CGPoint(x: 1 - corner, y: 1), CGPoint(x: corner, y: 1),
                CGPoint(x: 0, y: 1 - corner), CGPoint(x: 0, y: corner)
            ]
            for (index, vertex) in vertices.enumerated() {
                let point = CGPoint(x: bounds.minX + vertex.x * bounds.width, y: bounds.minY + vertex.y * bounds.height)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
            return path
        }
    }

    func inset(by amount: CGFloat) -> Self {
        var result = self
        result.insetAmount += amount
        return result
    }
}

/// Noninteractive clocks in the practice picker have no per-tick layout or gestures.
struct PracticeClockPreview: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let time: ClockTime
    let theme: ClockTheme

    var body: some View {
        Canvas { context, bounds in
            let size = min(bounds.width, bounds.height)
            let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
            func circle(_ diameter: CGFloat, _ color: Color) {
                context.fill(Path(ellipseIn: CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2,
                                                   width: diameter, height: diameter)), with: .color(color))
            }
            let clockBounds = CGRect(x: center.x - size / 2, y: center.y - size / 2, width: size, height: size)
            let outline = AnalogClockOutline(shape: theme.analogShape)
            context.fill(outline.path(in: clockBounds), with: .color(Color(dinoHex: theme.rimHex)))
            context.fill(outline.inset(by: size * 0.034).path(in: clockBounds), with: .color(Color(dinoHex: theme.faceHex)))
            let markings = Color(dinoHex: theme.markingHex)
            for tick in 0..<60 {
                let major = tick.isMultiple(of: 5)
                var rotated = context
                rotated.translateBy(x: center.x, y: center.y)
                rotated.rotate(by: .degrees(Double(tick) * 6))
                let width = size * (major ? 0.012 : 0.005)
                let height = size * (major ? 0.045 : 0.023)
                rotated.fill(Path(roundedRect: CGRect(x: -width / 2, y: -size * 0.425 - height / 2,
                                                     width: width, height: height), cornerRadius: width / 2),
                             with: .color(markings.opacity(highContrast ? 1 : theme.markingHex == 0xFFFFFF ? (major ? 0.9 : 0.55) : (major ? 0.6 : 0.28))))
            }
            for hour in 1...12 {
                let radians = Double(hour) * .pi / 6
                context.draw(Text(verbatim: theme.analogNumerals.label(for: hour))
                    .font(.system(size: size * 0.08, weight: .bold, design: theme.analogNumerals == .roman ? .serif : .rounded)).canvasInk(markings),
                             at: CGPoint(x: center.x + CGFloat(sin(radians)) * size * 0.34,
                                         y: center.y - CGFloat(cos(radians)) * size * 0.34))
            }
            func hand(length: CGFloat, width: CGFloat, color: UInt32, angle: Double) {
                var rotated = context
                rotated.translateBy(x: center.x, y: center.y)
                rotated.rotate(by: .degrees(angle))
                rotated.fill(Path(roundedRect: CGRect(x: -width / 2, y: -length,
                                                     width: width, height: length + size * 0.035),
                                  cornerRadius: theme.hands == .straight ? 1 : width / 2), with: .color(Color(dinoHex: color)))
            }
            hand(length: size * 0.23, width: size * 0.038, color: theme.hourHex, angle: time.hourAngle)
            hand(length: size * 0.34, width: size * 0.024, color: theme.minuteHex, angle: time.minuteAngle)
            circle(size * 0.085, Color(dinoHex: theme.rimHex))
            circle(size * 0.025, .white)
        }.allowsHitTesting(false)
    }
}

struct AnalogClock: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.dinoClockReadingAssistance) private var readingAssistance
    @GestureState private var touchingClock = false
    @State private var draggingMinutes: Bool?
    let time: ClockTime
    let theme: ClockTheme
    var size: CGFloat = 230
    var onHourChange: ((Int) -> Void)? = nil
    var showHandHints = false
    /// The surrounding question can offer spare width without adding vertical whitespace.
    var readingHintWidth: CGFloat? = nil
    /// Compared clocks share these bounds so their faces keep the same scale and baseline.
    var readingHintBounds: CGRect? = nil
    /// A separate, unnumbered guide for speaking a time. Size includes its outer scale.
    var spokenHintLanguage: String? = nil
    /// Answer clocks keep tighter margins around the reading guide.
    var compactSpokenHint = false
    /// The complete phrase example needs the hour ring without a second outer guide.
    var spokenHourHintLanguage: String? = nil
    var onMinuteChange: ((ClockTime) -> Void)? = nil
    var minuteStep = 1
    var adjustingMinutes = false
    var onHandSelection: ((Bool) -> Void)? = nil
    /// Unwrapped demonstration angles preserve the direction when passing twelve.
    var displayedHourAngle: Double? = nil
    var displayedMinuteAngle: Double? = nil
    private var displaysHandHints: Bool { spokenHintLanguage == nil && (showHandHints || readingAssistance) }
    private var drawingSize: CGFloat {
        if spokenHintLanguage != nil { return size / (SpokenClockGuideLayout.extent(shape: theme.analogShape, compact: compactSpokenHint) * 2) }
        if readingAssistance && !showHandHints {
            // The old square reserved the worst-case arrow reach on all four sides.
            // Fit the actual artwork instead, keeping the clock larger after a miss.
            let bounds = readingHintBounds ?? ClockHandHintGeometry.bounds(time: time, shape: theme.analogShape, faceSize: 150)
            return min((readingHintWidth ?? size) / bounds.width, size / bounds.height)
        }
        return size
    }
    private var spokenVerticalBounds: ClosedRange<Double>? {
        spokenHintLanguage.map {
            SpokenClockGuideLayout.verticalBounds(minute: time.minute, language: $0,
                                                 shape: theme.analogShape, faceSize: drawingSize, compact: compactSpokenHint)
        }
    }
    var body: some View {
        let size = drawingSize
        let handHintBounds = displaysHandHints
            ? readingHintBounds ?? ClockHandHintGeometry.bounds(time: time, shape: theme.analogShape, faceSize: size) : nil
        ZStack {
            AnalogClockOutline(shape: theme.analogShape).fill(Color(dinoHex: theme.rimHex))
                .shadow(color: Color(dinoHex: theme.rimHex).opacity(0.2), radius: 8, y: 5)
            AnalogClockOutline(shape: theme.analogShape).inset(by: size * 0.034).fill(Color(dinoHex: theme.faceHex))
            AnalogClockOutline(shape: theme.analogShape).inset(by: size * 0.015).stroke(.white.opacity(0.4), lineWidth: size * 0.008)
            AnalogClockTicks(size: size, markingHex: theme.markingHex, highContrast: highContrast)
                .equatable()
            ForEach(1...12, id: \.self) { hour in
                let radians = Double(hour) * .pi / 6
                Text(verbatim: theme.analogNumerals.label(for: hour))
                    .font(.system(size: size * 0.08, weight: .bold, design: theme.analogNumerals == .roman ? .serif : .rounded))
                    .foregroundStyle(Color(dinoHex: theme.markingHex))
                    .position(x: size / 2 + CGFloat(sin(radians)) * size * 0.34,
                              y: size / 2 - CGFloat(cos(radians)) * size * 0.34)
            }
            if let language = spokenHintLanguage ?? spokenHourHintLanguage {
                let hour = SpokenClockReadingHint(minute: time.minute, language: language).spokenHour(for: time.hour)
                let radians = Double(hour) * .pi / 6
                let diameter = SpokenClockGuideLayout.ringDiameter(faceSize: size)
                Circle().stroke(.white.opacity(0.9), lineWidth: 3.4)
                    .overlay(Circle().stroke(DinoStyle.ink, lineWidth: 1.4))
                    .frame(width: diameter, height: diameter)
                    .position(x: size / 2 + sin(radians) * size * 0.34,
                              y: size / 2 - cos(radians) * size * 0.34)
            }
            if displaysHandHints {
                ClockHourReturnGuide(time: time, theme: theme, size: size)
            }
            hand(length: size * 0.23, width: hourWidth, color: Color(dinoHex: theme.hourHex), angle: displayedHourAngle ?? time.hourAngle)
            hand(length: size * 0.34, width: minuteWidth, color: Color(dinoHex: theme.minuteHex), angle: displayedMinuteAngle ?? time.minuteAngle)
            Circle().fill(Color(dinoHex: theme.rimHex)).frame(width: size * 0.085)
            Circle().fill(.white).frame(width: size * 0.025)
        }
        .frame(width: size, height: size)
        .contentShape(AnalogClockOutline(shape: theme.analogShape))
        .gesture(DragGesture(minimumDistance: 0)
            .updating($touchingClock) { _, active, _ in active = true }
            .onChanged { value in
                let x = value.location.x - size / 2
                let y = value.location.y - size / 2
                guard size > 0, hypot(x, y) > size * 0.10 else { return }
                if draggingMinutes == nil {
                    let minutes: Bool
                    if onHandSelection != nil, onHourChange != nil, onMinuteChange != nil {
                        minutes = ClockHandSelection.minutes(at: CGPoint(x: x / size, y: y / size),
                            hourAngle: displayedHourAngle ?? time.hourAngle,
                            minuteAngle: displayedMinuteAngle ?? time.minuteAngle,
                            preferredMinutes: adjustingMinutes)
                    } else {
                        minutes = onMinuteChange != nil
                    }
                    draggingMinutes = minutes
                    onHandSelection?(minutes)
                }
                if draggingMinutes == true, let onMinuteChange {
                    let next = time.settingMinute(ClockTime.snappedMinute(x: Double(x), y: Double(y), step: minuteStep))
                    if next != time { onMinuteChange(next) }
                } else {
                    let next = ClockTime.snappedHour(x: Double(x), y: Double(y), minute: time.minute)
                    if next != time.hour { onHourChange?(next) }
                }
            }
            .onEnded { _ in draggingMinutes = nil },
            including: onHourChange == nil && onMinuteChange == nil ? .none : .all)
        .onValueChange(of: touchingClock) { active in
            if !active { draggingMinutes = nil }
        }
        .overlay {
            if let language = spokenHintLanguage {
                ClockSpokenReadingScale(time: time, language: language, shape: theme.analogShape, size: size, compact: compactSpokenHint)
            } else if let handHintBounds {
                let pointers = ClockHandHintGeometry.pointers(time: time, shape: theme.analogShape)
                ClockMinuteReadingScale(shape: theme.analogShape, size: size, bounds: handHintBounds)
                ClockHandHint(number: 1, pointer: pointers[0], ink: theme.hourHex, size: size, bounds: handHintBounds,
                              scaleMarks: ClockHandHintGeometry.minuteMarks(shape: theme.analogShape))
                ClockHandHint(number: 2, pointer: pointers[1], ink: theme.minuteHex, size: size, bounds: handHintBounds)
            }
        }
        .padding(.leading, spokenHintLanguage != nil ? size * (SpokenClockGuideLayout.extent(shape: theme.analogShape, compact: compactSpokenHint) - 0.5)
                 : handHintBounds.map { size * (-$0.minX - 0.5) } ?? 0)
        .padding(.trailing, spokenHintLanguage != nil ? size * (SpokenClockGuideLayout.extent(shape: theme.analogShape, compact: compactSpokenHint) - 0.5)
                 : handHintBounds.map { size * ($0.maxX - 0.5) } ?? 0)
        .padding(.top, spokenVerticalBounds.map { size * (-$0.lowerBound - 0.5) }
                 ?? handHintBounds.map { size * (-$0.minY - 0.5) } ?? 0)
        .padding(.bottom, spokenVerticalBounds.map { size * ($0.upperBound - 0.5) }
                 ?? handHintBounds.map { size * ($0.maxY - 0.5) } ?? 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(time.digitalText)
        .accessibilityValue(Text(verbatim: spokenHintLanguage.map { DinoTimeWords.time(time, language: $0) } ?? ""))
    }

    private var hourWidth: CGFloat { drawingSize * 0.038 }
    private var minuteWidth: CGFloat { drawingSize * 0.024 }
    private func hand(length: CGFloat, width: CGFloat, color: Color, angle: Double) -> some View {
        RoundedRectangle(cornerRadius: theme.hands == .straight ? 1 : width / 2)
            .fill(color)
            .frame(width: width, height: length + size * 0.035)
            .offset(y: -(length - size * 0.035) / 2)
            .rotationEffect(.degrees(angle))
    }
}

/// The active count connects to its actual minute, at either end of the reading arc.
private struct ClockSpokenReadingScale: View {
    let time: ClockTime
    let language: String
    let shape: AnalogClockShape
    let size: CGFloat
    let compact: Bool

    private struct ScaleMark {
        let minute: Int
        let tickStart: CGPoint
        let tickEnd: CGPoint
        let center: CGPoint
        let text: GraphicsContext.ResolvedText
        let outline: CGSize?
    }

    var body: some View {
        let extent = SpokenClockGuideLayout.extent(shape: shape, compact: compact)
        Canvas { context, _ in
            let hint = SpokenClockReadingHint(minute: time.minute, language: language)
            func positioned(_ p: CGPoint) -> CGPoint {
                CGPoint(x: size * (extent + p.x), y: size * (extent + p.y))
            }
            var arcOffset = SpokenClockGuideLayout.arrowOffset
            func point(_ minute: Double, offset: Double? = nil) -> CGPoint {
                let angle = minute * 6
                let radius = ClockHandHintGeometry.outerRadius(angle: angle, shape: shape) + (offset ?? arcOffset)
                return positioned(ClockHandHintGeometry.point(radius: radius, angle: angle))
            }
            let marks: [ScaleMark] = hint.scaleMinutes.map { minute in
                let selected = minute == time.minute
                let label = SpokenClockReadingHint(minute: minute, language: language).scaleLabel
                let text = context.resolve(Text(verbatim: label)
                    .font(.system(size: SpokenClockGuideLayout.scaleFontSize(faceSize: size),
                                  weight: selected ? .heavy : .bold, design: .rounded))
                    .monospacedDigit().canvasInk(DinoStyle.ink))
                let measured = text.measure(in: CGSize(width: size * 2, height: size))
                let padding = max(2, size * 0.014)
                let numeric = label.allSatisfy(\.isNumber)
                let side = max(measured.width + padding * 2, SpokenClockGuideLayout.ringDiameter(faceSize: size))
                let outline: CGSize? = selected
                    ? CGSize(width: numeric ? side : measured.width + padding * 2,
                             height: side) : nil
                let dimensions = outline ?? measured
                let mark = ClockHandHintGeometry.minuteMark(minute: minute, shape: shape,
                    labelSize: CGSize(width: dimensions.width / size, height: dimensions.height / size),
                    gap: max(2 / size, 0.018))
                // Every value uses the same short tick and measured text gap.
                let center = positioned(mark.label)
                let tickEnd = positioned(mark.tickEnd)
                return ScaleMark(minute: minute, tickStart: positioned(mark.tickStart), tickEnd: tickEnd,
                                 center: center, text: text, outline: outline)
            }
            // Keep the entire arc outside the ordinary scale text, also when a
            // language uses a longer word such as quarter instead of a number.
            for mark in marks where mark.minute != time.minute {
                let onArc = (hint.startMinute...hint.endMinute).contains(mark.minute)
                    || (mark.minute == 0 && hint.endMinute == 60)
                guard onArc else { continue }
                let textSize = mark.text.measure(in: CGSize(width: size * 2, height: size))
                let cx = mark.center.x - size * extent, cy = mark.center.y - size * extent
                let reach = hypot(abs(cx) + textSize.width / 2, abs(cy) + textSize.height / 2) / size
                let faceEdge = ClockHandHintGeometry.outerRadius(angle: Double(mark.minute) * 6, shape: shape)
                arcOffset = max(arcOffset, reach - faceEdge + max(3 / size, 0.025))
            }
            let first = Double(hint.startMinute), last = Double(hint.endMinute)
            let canDrawArrow = hint.count > 0
            let selected = marks.first { $0.minute == time.minute }
            let atEnd = time.minute == hint.endMinute
            let side = SpokenClockGuideLayout.badgeSide(minute: time.minute, atEnd: atEnd)
            let gap: CGFloat = compact ? 2.5 : 3
            let port: CGPoint? = selected.flatMap { mark in
                mark.outline.map { outline in
                    CGPoint(x: mark.center.x + side.x * (outline.width / 2 + gap),
                            y: mark.center.y + side.y * (outline.height / 2 + gap))
                }
            }
            func tangent(_ minute: Double) -> CGPoint {
                let before = point(minute - 0.05), after = point(minute + 0.05)
                let length = max(0.001, hypot(after.x - before.x, after.y - before.y))
                return CGPoint(x: (after.x - before.x) / length, y: (after.y - before.y) / length)
            }
            // Keep each control point in the first third of the connection.
            // Long handles on a short join can otherwise create a small S-bend.
            func connectionControl(from origin: CGPoint, toward destination: CGPoint, direction: CGPoint) -> CGPoint {
                let dx = destination.x - origin.x, dy = destination.y - origin.y
                var reach = min(max(4, size * 0.045), hypot(dx, dy) / 3)
                for (distance, component) in [(dx, direction.x), (dy, direction.y)] where abs(component) > 0.0001 {
                    reach = min(reach, max(0, distance / component) / 3)
                }
                return CGPoint(x: origin.x + direction.x * reach, y: origin.y + direction.y * reach)
            }
            var arrow = Path()
            if canDrawArrow {
                let trim = min(3.0, Double(hint.count) * 0.25)
                let begin = first + (!atEnd && port != nil ? trim : 0)
                let end = last - (atEnd && port != nil ? trim : 0)
                if !atEnd, let port {
                    let join = point(begin), t = tangent(begin)
                    arrow.move(to: port)
                    arrow.addCurve(to: join,
                        control1: connectionControl(from: port, toward: join, direction: side),
                        control2: connectionControl(from: join, toward: port, direction: CGPoint(x: -t.x, y: -t.y)))
                } else { arrow.move(to: point(begin)) }
                let steps = max(2, Int(ceil((end - begin) * 3)))
                for step in 1...steps {
                    arrow.addLine(to: point(begin + (end - begin) * Double(step) / Double(steps)))
                }
                var tip = point(last), t = tangent(last)
                if atEnd, let port {
                    let join = point(end), joinTangent = tangent(end)
                    arrow.addCurve(to: port,
                        control1: connectionControl(from: join, toward: port, direction: joinTangent),
                        control2: connectionControl(from: port, toward: join, direction: side))
                    tip = port
                    t = CGPoint(x: -side.x, y: -side.y)
                }
                let direction = atan2(t.y, t.x)
                let wing = max(compact ? 4 : 5, size * (compact ? 0.04 : 0.048))
                for sign in [-1.0, 1.0] {
                    arrow.move(to: tip)
                    arrow.addLine(to: CGPoint(x: tip.x - cos(direction + sign * .pi / 5) * wing,
                                             y: tip.y - sin(direction + sign * .pi / 5) * wing))
                }
            }
            context.stroke(arrow, with: .color(.white), style: StrokeStyle(lineWidth: compact ? 4 : 5, lineCap: .round, lineJoin: .round))
            context.stroke(arrow, with: .color(DinoStyle.ink), style: StrokeStyle(lineWidth: compact ? 2 : 2.5, lineCap: .round, lineJoin: .round))

            var leaders = Path()
            if !hint.relation.isEmpty {
                let minute = canDrawArrow ? (first + last) / 2 : hint.relationLeaderMinute
                let attachment = min(Double(hint.endMinute), max(Double(hint.startMinute), minute))
                let bend = point(minute, offset: arcOffset + 0.015)
                let outside = point(minute, offset: arcOffset + 0.06)
                let direction: CGFloat = sin(minute * .pi / 30) >= 0 ? 1 : -1
                let end = CGPoint(x: outside.x + direction * max(3, size * 0.025), y: outside.y)
                leaders.move(to: point(attachment))
                leaders.addLine(to: bend)
                leaders.addLine(to: outside)
                leaders.addLine(to: end)
                let text = context.resolve(Text(verbatim: hint.relation)
                    .font(.system(size: max(7.5, size * 0.064), weight: .bold, design: .rounded)).canvasInk(DinoStyle.ink))
                let measured = text.measure(in: CGSize(width: size * 2, height: size))
                let center = ClockHandHintGeometry.labelCenter(from: end, toward: CGPoint(x: direction, y: 0),
                                                              labelSize: measured, gap: 2)
                context.draw(text, at: center)
            }
            context.stroke(leaders, with: .color(DinoStyle.ink), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
            for mark in marks {
                var tick = Path()
                tick.move(to: mark.tickStart); tick.addLine(to: mark.tickEnd)
                context.stroke(tick, with: .color(DinoStyle.ink), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                if let outline = mark.outline {
                    let ring = Path(ellipseIn: CGRect(x: mark.center.x - outline.width / 2, y: mark.center.y - outline.height / 2,
                                                     width: outline.width, height: outline.height))
                    context.fill(ring, with: .color(.white))
                    context.stroke(ring, with: .color(DinoStyle.ink), lineWidth: 1.4)
                }
                context.draw(mark.text, at: mark.center)
            }
        }
        .frame(width: size * extent * 2, height: size * extent * 2)
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Tick marks do not depend on the hands. One retained drawing replaces sixty
/// separately laid-out shapes while preserving their exact sizes and positions.
private struct AnalogClockTicks: View, Equatable {
    let size: CGFloat
    let markingHex: UInt32
    let highContrast: Bool

    var body: some View {
        Canvas { context, _ in
            for tick in 0..<60 {
                let major = tick.isMultiple(of: 5)
                let width = size * (major ? 0.012 : 0.005)
                let height = size * (major ? 0.045 : 0.023)
                let opacity = highContrast ? 1 : markingHex == 0xFFFFFF ? (major ? 0.9 : 0.55) : (major ? 0.6 : 0.28)
                var rotated = context
                rotated.translateBy(x: size / 2, y: size / 2)
                rotated.rotate(by: .degrees(Double(tick) * 6))
                rotated.fill(Path(roundedRect: CGRect(x: -width / 2, y: -size * 0.425 - height / 2,
                                                     width: width, height: height), cornerRadius: width / 2),
                             with: .color(Color(dinoHex: markingHex).opacity(opacity)))
            }
        }.frame(width: size, height: size).allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct ClockHandHint: View {
    let number: Int
    let pointer: ClockHandHintGeometry.Pointer
    let ink: UInt32
    let size: CGFloat
    let bounds: CGRect
    var scaleMarks: [ClockHandHintGeometry.MinuteMark] = []
    private func point(_ point: CGPoint) -> CGPoint {
        CGPoint(x: size * (point.x - bounds.minX), y: size * (point.y - bounds.minY))
    }

    var body: some View {
        let scale = min(1, size / 150)
        let width = size * bounds.width
        let height = size * bounds.height
        let scaled: (CGPoint) -> CGPoint = { value in
            let positioned = point(value)
            return CGPoint(x: positioned.x / scale, y: positioned.y / scale)
        }
        ClockHintBadgeArrow(number: number, badge: scaled(pointer.badge), tip: scaled(pointer.tip),
                           wings: pointer.arrowWings.map(scaled), ink: ink,
                           bounds: CGSize(width: width / scale, height: height / scale))
            .scaleEffect(scale)
            .frame(width: width, height: height)
            .mask {
                Canvas { context, canvas in
                    var visible = Path(CGRect(origin: .zero, size: canvas))
                    // The extended hour shaft passes the outer minute scale.
                    // Leave a small break around each label so its digits stay clear.
                    for mark in scaleMarks {
                        let center = point(mark.label)
                        let width = size * (CGFloat(String(mark.minute).count) * 0.042 + 0.036)
                        let height = size * 0.114
                        visible.addRect(CGRect(x: center.x - width / 2, y: center.y - height / 2,
                                               width: width, height: height))
                    }
                    context.fill(visible, with: .color(.white), style: FillStyle(eoFill: true))
                }
            }
            .offset(x: size * bounds.midX, y: size * bounds.midY)
    }
}

private struct ClockMinuteReadingScale: View {
    let shape: AnalogClockShape
    let size: CGFloat
    let bounds: CGRect

    var body: some View {
        Canvas { context, _ in
            func positioned(_ point: CGPoint) -> CGPoint {
                CGPoint(x: size * (point.x - bounds.minX), y: size * (point.y - bounds.minY))
            }
            for minute in stride(from: 0, to: 60, by: 5) {
                let label = Text(verbatim: String(minute))
                    .font(.system(size: size * 0.064, weight: .bold, design: .rounded))
                    .monospacedDigit().canvasInk(DinoStyle.ink)
                let resolved = context.resolve(label)
                let measured = resolved.measure(in: CGSize(width: size * 2, height: size))
                let mark = ClockHandHintGeometry.minuteMark(minute: minute, shape: shape,
                    labelSize: CGSize(width: measured.width / size, height: measured.height / size), gap: max(2 / size, 0.018))
                var tick = Path()
                tick.move(to: positioned(mark.tickStart))
                tick.addLine(to: positioned(mark.tickEnd))
                context.stroke(tick, with: .color(DinoStyle.ink), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                let center = positioned(mark.label)
                context.draw(resolved, at: center)
            }
        }
        .frame(width: size * bounds.width, height: size * bounds.height)
        .offset(x: size * bounds.midX, y: size * bounds.midY)
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// One quiet backwards arc links the moving hour hand to the completed hour.
private struct ClockHourReturnGuide: View {
    let time: ClockTime
    let theme: ClockTheme
    let size: CGFloat

    var body: some View {
        Canvas { context, _ in
            guard time.minute > 0 else { return }
            let hour = Double(time.hour % 12) * 30
            let radius = 0.275
            func positioned(_ angle: Double, radius: Double = 0.275) -> CGPoint {
                let point = ClockHandHintGeometry.point(radius: radius, angle: angle)
                return CGPoint(x: size * (0.5 + point.x), y: size * (0.5 + point.y))
            }
            var arc = Path()
            let steps = max(2, time.minute)
            for step in 0...steps {
                let angle = time.hourAngle - Double(step) / Double(steps) * Double(time.minute) * 0.5
                if step == 0 { arc.move(to: positioned(angle)) }
                else { arc.addLine(to: positioned(angle)) }
            }
            let tip = positioned(hour)
            let wing = min(0.026, Double(time.minute) * .pi / 360 * radius * 0.6) * size
            let radians = hour * .pi / 180
            for offset in [-Double.pi / 5, Double.pi / 5] {
                arc.move(to: tip)
                arc.addLine(to: CGPoint(x: tip.x + cos(radians + offset) * wing,
                                       y: tip.y + sin(radians + offset) * wing))
            }
            let ink = Color(dinoHex: ClockColorContrast.hourGuideHex(hand: theme.hourHex, face: theme.faceHex))
            context.stroke(arc, with: .color(ink), style: StrokeStyle(lineWidth: size * 0.015, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}
