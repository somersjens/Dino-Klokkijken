import SwiftUI

private struct SpaciousQuestionKey: EnvironmentKey { static let defaultValue = false }
private struct ClockReadingAssistanceKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var dinoSpaciousQuestion: Bool {
        get { self[SpaciousQuestionKey.self] }
        set { self[SpaciousQuestionKey.self] = newValue }
    }

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

/// The ordinary hour face pairs with the second half of a 24-hour day outside its rim.
struct Dino24HourReadingClock: View {
    let time: ClockTime
    let theme: ClockTheme
    let width: CGFloat

    private var face: CGFloat { min(200, width / 1.5) }

    var body: some View {
        ZStack {
            AnalogClock(time: time, theme: theme, size: face)
                .environment(\.dinoClockReadingAssistance, false)
                .accessibilityIdentifier("demo.24Hour.analog")
            ForEach(1...12, id: \.self) { hour in
                let angle = Double(hour) * .pi / 6
                let edge = theme.analogShape == .square
                    ? 0.5 / max(abs(sin(angle)), abs(cos(angle))) : 0.5
                let radius = face * (edge + 0.14)
                Text(verbatim: String(format: "%02d", (hour + 12) % 24))
                    .font(.system(size: face * 0.075, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(DinoStyle.ink)
                    .position(x: width / 2 + sin(angle) * radius,
                              y: width / 2 - cos(angle) * radius)
                    .accessibilityIdentifier("demo.24Hour.hour.\((hour + 12) % 24)")
            }
        }
        .frame(width: width, height: width)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("demo.24Hour.clock")
    }
}

struct AnalogClock: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dinoClockReadingAssistance) private var readingAssistance
    @Environment(\.dinoSpaciousQuestion) private var spaciousQuestion
    @GestureState private var touchingClock = false
    @State private var draggingMinutes: Bool?
    @State private var revealedReadingGuide: String?
    let time: ClockTime
    let theme: ClockTheme
    var size: CGFloat = 230
    var onHourChange: ((Int) -> Void)? = nil
    var showHandHints = false
    /// An outer overlay. The caller fits its scale only while the numbers are visible.
    var showMinuteScale = false
    var minuteScaleVisible = true
    /// The surrounding question can offer spare width without adding vertical whitespace.
    var readingHintWidth: CGFloat? = nil
    /// Compared clocks share these bounds so their faces keep the same scale and baseline.
    var readingHintBounds: CGRect? = nil
    /// Reference clocks can use their final assisted size before the first mistake.
    var reservesHandHintSpace = false
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
    private var readingGuide: String? {
        if let spokenHintLanguage { return "spoken|\(spokenHintLanguage)" }
        if let spokenHourHintLanguage { return "hour|\(spokenHourHintLanguage)" }
        return displaysHandHints ? "hands" : nil
    }
    private var guideOpacity: Double {
        reduceMotion || (readingGuide != nil && revealedReadingGuide == readingGuide) ? 1 : 0
    }
    private var drawingSize: CGFloat {
        if spokenHintLanguage != nil { return size / (SpokenClockGuideLayout.extent(shape: theme.analogShape, compact: compactSpokenHint) * 2) }
        if (readingAssistance || reservesHandHintSpace) && !showHandHints {
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
        let handHintBounds = displaysHandHints || reservesHandHintSpace
            ? readingHintBounds ?? ClockHandHintGeometry.bounds(time: time, shape: theme.analogShape, faceSize: size, spacious: spaciousQuestion) : nil
        let minuteScaleBounds = CGRect(x: -0.64, y: -0.64, width: 1.28, height: 1.28)
        ZStack {
            dialArtwork
            if let language = spokenHintLanguage ?? spokenHourHintLanguage {
                let hour = SpokenClockReadingHint(minute: time.minute, language: language).spokenHour(for: time.hour)
                let radians = Double(hour) * .pi / 6
                let diameter = SpokenClockGuideLayout.ringDiameter(faceSize: size)
                Circle().stroke(.white.opacity(0.9), lineWidth: 3.4)
                    .overlay(Circle().stroke(DinoStyle.ink, lineWidth: 1.4))
                    .frame(width: diameter, height: diameter)
                    .position(x: size / 2 + sin(radians) * size * 0.34,
                              y: size / 2 - cos(radians) * size * 0.34)
                    .opacity(guideOpacity)
            }
            if displaysHandHints {
                ClockHourReturnGuide(time: time, theme: theme, size: size)
                    .opacity(guideOpacity).transition(.identity)
            }
            handArtwork
            if let language = spokenHintLanguage {
                ClockSpokenMinuteGuide(time: time, language: language, theme: theme, size: size)
                    .opacity(guideOpacity)
            }
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
                    .opacity(guideOpacity)
            } else if let handHintBounds {
                let pointers = ClockHandHintGeometry.pointers(time: time, shape: theme.analogShape)
                ZStack {
                    ClockMinuteReadingScale(shape: theme.analogShape, size: size, bounds: handHintBounds)
                    ClockHandHint(number: 1, pointer: pointers[0], ink: theme.hourHex, size: size, bounds: handHintBounds)
                    ClockHandHint(number: 2, pointer: pointers[1], ink: theme.minuteHex, size: size, bounds: handHintBounds)
                }
                .opacity(guideOpacity).transition(.identity)
            } else if showMinuteScale && minuteScaleVisible {
                ClockMinuteReadingScale(shape: theme.analogShape, size: size, bounds: minuteScaleBounds,
                                        ink: Color(dinoHex: theme.minuteHex), paddedDigits: true,
                                        outlineInk: ClockColorContrast.ratio(theme.minuteHex, 0xFFFFFF) < 3 ? DinoStyle.ink : nil)
                    .transition(.opacity)
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
        .task(id: readingGuide) {
            revealedReadingGuide = nil
            guard let guide = readingGuide else { return }
            if !reduceMotion {
                do { try await Task.sleep(for: .seconds(DinoQuestionFeedbackTiming.revealDelay)) }
                catch { return }
            }
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : .easeOut(duration: DinoQuestionFeedbackTiming.reveal)) {
                revealedReadingGuide = guide
            }
        }
    }

    // As in type 1: keep numerals, ticks and hands in one constant coordinate system.
    // Animate their transform instead of asking SwiftUI to crossfade changing font sizes.
    private static let artworkSize: CGFloat = 240

    private func artwork<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(width: Self.artworkSize, height: Self.artworkSize)
            .scaleEffect(drawingSize / Self.artworkSize)
            .frame(width: drawingSize, height: drawingSize)
    }

    private var dialArtwork: some View {
        let face = Self.artworkSize
        return artwork {
            ZStack {
                AnalogClockOutline(shape: theme.analogShape).fill(Color(dinoHex: theme.rimHex))
                    .shadow(color: Color(dinoHex: theme.rimHex).opacity(0.2), radius: 8, y: 5)
                AnalogClockOutline(shape: theme.analogShape).inset(by: face * 0.034).fill(Color(dinoHex: theme.faceHex))
                AnalogClockOutline(shape: theme.analogShape).inset(by: face * 0.015).stroke(.white.opacity(0.4), lineWidth: face * 0.008)
                AnalogClockTicks(size: face, markingHex: theme.markingHex, highContrast: highContrast).equatable()
                ForEach(1...12, id: \.self) { hour in
                    let radians = Double(hour) * .pi / 6
                    Text(verbatim: theme.analogNumerals.label(for: hour))
                        .font(.system(size: face * 0.08, weight: .bold, design: theme.analogNumerals == .roman ? .serif : .rounded))
                        .foregroundStyle(Color(dinoHex: theme.markingHex))
                        .position(x: face / 2 + CGFloat(sin(radians)) * face * 0.34,
                                  y: face / 2 - CGFloat(cos(radians)) * face * 0.34)
                }
            }
        }
    }

    private var handArtwork: some View {
        let face = Self.artworkSize
        return artwork {
            ZStack {
                hand(length: face * 0.23, width: face * 0.038, color: Color(dinoHex: theme.hourHex), angle: displayedHourAngle ?? time.hourAngle)
                hand(length: face * 0.34, width: face * 0.024, color: Color(dinoHex: theme.minuteHex), angle: displayedMinuteAngle ?? time.minuteAngle)
            }
        }
    }

    private func hand(length: CGFloat, width: CGFloat, color: Color, angle: Double) -> some View {
        let tail = Self.artworkSize * 0.035
        return RoundedRectangle(cornerRadius: theme.hands == .straight ? 1 : width / 2)
            .fill(color)
            .frame(width: width, height: length + tail)
            .offset(y: -(length - tail) / 2)
            .rotationEffect(.degrees(angle))
    }
}

/// The pronunciation scale stays close to the rim; its active value never moves outward.
/// Keep the same clock face and answer-card bounds while making room for the guide.
struct DinoSpokenAnswerClock: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let time: ClockTime
    let theme: ClockTheme
    let language: String
    let faceSize: CGFloat
    let width: CGFloat
    let showsGuide: Bool

    var body: some View {
        let candidate = min(faceSize, width / (SpokenClockGuideLayout.extent(shape: theme.analogShape, compact: true) * 2))
        let bounds = SpokenClockGuideLayout.verticalBounds(minute: time.minute, language: language,
                                                           shape: theme.analogShape, faceSize: candidate, compact: true)
        let guideFace = min(candidate, (faceSize - 8) / (bounds.upperBound - bounds.lowerBound))
        let fittedBounds = SpokenClockGuideLayout.verticalBounds(minute: time.minute, language: language,
                                                                 shape: theme.analogShape, faceSize: guideFace, compact: true)
        let guideOffset = -guideFace * (fittedBounds.lowerBound + fittedBounds.upperBound) / 2
        let hour = SpokenClockReadingHint(minute: time.minute, language: language).spokenHour(for: time.hour)
        let radians = Double(hour) * .pi / 6
        ZStack {
            AnalogClock(time: time, theme: theme, size: faceSize)
                .scaleEffect(showsGuide ? guideFace / faceSize : 1)
                .offset(y: showsGuide ? guideOffset : 0)
                .animation(reduceMotion ? nil : .easeInOut(duration: DinoQuestionFeedbackTiming.layout), value: showsGuide)
            ZStack {
                ClockSpokenReadingScale(time: time, language: language, shape: theme.analogShape,
                                        size: guideFace, compact: true, canvasPadding: 12)
                ClockSpokenMinuteGuide(time: time, language: language, theme: theme, size: guideFace)
                    .frame(width: guideFace, height: guideFace)
                Circle().stroke(.white.opacity(0.9), lineWidth: 3.4)
                    .overlay(Circle().stroke(DinoStyle.ink, lineWidth: 1.4))
                    .frame(width: SpokenClockGuideLayout.ringDiameter(faceSize: guideFace),
                           height: SpokenClockGuideLayout.ringDiameter(faceSize: guideFace))
                    .offset(x: sin(radians) * guideFace * 0.34, y: -cos(radians) * guideFace * 0.34)
            }
            .offset(y: guideOffset)
            .opacity(showsGuide ? 1 : 0)
            .animation(reduceMotion ? nil : .easeOut(duration: DinoQuestionFeedbackTiming.reveal).delay(DinoQuestionFeedbackTiming.revealDelay), value: showsGuide)
            .allowsHitTesting(false).accessibilityHidden(true)
        }
        .frame(width: width, height: faceSize)
        .environment(\.dinoClockReadingAssistance, false)
    }
}

private struct ClockSpokenReadingScale: View {
    let time: ClockTime
    let language: String
    let shape: AnalogClockShape
    let size: CGFloat
    let compact: Bool
    var canvasPadding: CGFloat = 0

    private struct ScaleMark {
        let minute: Int
        let tickStart: CGPoint
        let tickEnd: CGPoint
        let center: CGPoint
        let text: GraphicsContext.ResolvedText
        let outline: CGSize?
        let underlined: Bool
    }

    var body: some View {
        // Short faces still use a readable minimum font; words can exceed the nominal scale envelope.
        let extent = SpokenClockGuideLayout.extent(shape: shape, compact: compact) + canvasPadding / size
        let bounds = SpokenClockGuideLayout.verticalBounds(minute: time.minute, language: language,
                                                           shape: shape, faceSize: size, compact: compact)
        Canvas { context, _ in
            let hint = SpokenClockReadingHint(minute: time.minute, language: language)
            func positioned(_ p: CGPoint) -> CGPoint {
                CGPoint(x: size * (extent + p.x), y: size * (p.y - bounds.lowerBound) + canvasPadding)
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
                let outline: CGSize? = selected && numeric ? CGSize(width: side, height: side) : nil
                let dimensions = outline ?? measured
                let mark = ClockHandHintGeometry.minuteMark(minute: minute, shape: shape,
                    labelSize: CGSize(width: dimensions.width / size, height: dimensions.height / size),
                    gap: max(2 / size, 0.018))
                // Every value uses the same short tick and measured text gap.
                let center = positioned(mark.label)
                let tickEnd = positioned(mark.tickEnd)
                return ScaleMark(minute: minute, tickStart: positioned(mark.tickStart), tickEnd: tickEnd,
                                 center: center, text: text, outline: outline, underlined: selected && !numeric)
            }
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
                if mark.underlined {
                    let measured = mark.text.measure(in: CGSize(width: size * 2, height: size))
                    let y = mark.center.y + measured.height / 2 + 1.5
                    var underline = Path()
                    underline.move(to: CGPoint(x: mark.center.x - measured.width / 2, y: y))
                    underline.addLine(to: CGPoint(x: mark.center.x + measured.width / 2, y: y))
                    context.stroke(underline, with: .color(DinoStyle.ink), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
                }
                context.draw(mark.text, at: mark.center)
            }
        }
        // The hidden Canvas also participates in the clock's accessibility bounds.
        // Keep its buffer as tight as the visible scale, rather than reserving a square.
        .frame(width: size * extent * 2, height: size * (bounds.upperBound - bounds.lowerBound) + canvasPadding * 2)
        .offset(y: size * (bounds.lowerBound + bounds.upperBound) / 2)
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// A compact clockwise guide inside the face, using the same radius as the hour-return arrow.
private struct ClockSpokenMinuteGuide: View {
    let time: ClockTime
    let language: String
    let theme: ClockTheme
    let size: CGFloat

    var body: some View {
        Canvas { context, _ in
            let hint = SpokenClockReadingHint(minute: time.minute, language: language)
            guard hint.count > 0 else { return }
            let radius = SpokenClockGuideLayout.arrowRadius
            let width = max(1.2, size * 0.015)
            var startAngle = Double(hint.startMinute) * 6
            var endAngle = Double(hint.endMinute) * 6
            // Leave a visible gap between the rounded arrow tip and the minute hand.
            // Very short intervals keep a small cue, drawn above the hand as a safeguard.
            let clearance = asin(min(1, (size * 0.012 + width / 2 + max(1, size * 0.006)) / (size * radius))) * 180 / .pi
            let trim = min(clearance, (endAngle - startAngle) * 0.8)
            if hint.endMinute == time.minute { endAngle -= trim }
            else { startAngle += trim }
            func positioned(_ angle: Double) -> CGPoint {
                let point = ClockHandHintGeometry.point(radius: radius, angle: angle)
                return CGPoint(x: size * (0.5 + point.x), y: size * (0.5 + point.y))
            }
            var arrow = Path()
            arrow.addArc(center: CGPoint(x: size / 2, y: size / 2), radius: size * radius,
                         startAngle: .degrees(startAngle - 90),
                         endAngle: .degrees(endAngle - 90), clockwise: false)
            let tip = positioned(endAngle)
            let direction = endAngle * .pi / 180
            let wing = min(0.026, (endAngle - startAngle) * .pi / 180 * radius * 0.6) * size
            for offset in [-Double.pi / 5, Double.pi / 5] {
                arrow.move(to: tip)
                arrow.addLine(to: CGPoint(x: tip.x - cos(direction + offset) * wing,
                                         y: tip.y - sin(direction + offset) * wing))
            }
            context.stroke(arrow, with: .color(Color(dinoHex: theme.minuteHex).opacity(0.5)),
                           style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
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
    @Environment(\.dinoSpaciousQuestion) private var spaciousQuestion
    let number: Int
    let pointer: ClockHandHintGeometry.Pointer
    let ink: UInt32
    let size: CGFloat
    let bounds: CGRect
    private func point(_ point: CGPoint) -> CGPoint {
        CGPoint(x: size * (point.x - bounds.minX), y: size * (point.y - bounds.minY))
    }

    var body: some View {
        let scale = ClockHandHintGeometry.badgeScale(faceSize: size, spacious: spaciousQuestion)
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
            .offset(x: size * bounds.midX, y: size * bounds.midY)
    }
}

private struct ClockMinuteReadingScale: View {
    let shape: AnalogClockShape
    let size: CGFloat
    let bounds: CGRect
    var ink: Color = DinoStyle.ink
    var paddedDigits = false
    var outlineInk: Color? = nil

    var body: some View {
        Canvas { context, _ in
            func positioned(_ point: CGPoint) -> CGPoint {
                CGPoint(x: size * (point.x - bounds.minX), y: size * (point.y - bounds.minY))
            }
            for minute in stride(from: 0, to: 60, by: 5) {
                let label = Text(verbatim: paddedDigits ? String(format: "%02d", minute) : String(minute))
                    .font(.system(size: size * 0.064, weight: .bold, design: .rounded))
                    .monospacedDigit()
                let resolved = context.resolve(label.canvasInk(ink))
                let measured = resolved.measure(in: CGSize(width: size * 2, height: size))
                let mark = ClockHandHintGeometry.minuteMark(minute: minute, shape: shape,
                    labelSize: CGSize(width: measured.width / size, height: measured.height / size), gap: max(2 / size, 0.018))
                var tick = Path()
                tick.move(to: positioned(mark.tickStart))
                tick.addLine(to: positioned(mark.tickEnd))
                let center = positioned(mark.label)
                if let outlineInk {
                    // Keep white and pale hand colors readable on the white answer stone.
                    context.stroke(tick, with: .color(outlineInk), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    let outline = context.resolve(label.canvasInk(outlineInk))
                    for step in 0..<8 {
                        let angle = Double(step) * .pi / 4
                        context.draw(outline, at: CGPoint(x: center.x + cos(angle) * 0.5,
                                                         y: center.y + sin(angle) * 0.5))
                    }
                }
                context.stroke(tick, with: .color(ink), style: StrokeStyle(lineWidth: 1, lineCap: .round))
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
