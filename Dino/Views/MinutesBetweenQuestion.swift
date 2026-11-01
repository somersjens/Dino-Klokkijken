import SwiftUI

/// The original arrow lowers into a worked timeline while both endpoint clocks stay visible.
struct DinoMinutesBetweenCard: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let start: ClockTime
    let end: ClockTime
    let minutes: Int
    let theme: ClockTheme
    let width: CGFloat
    let showsAnswer: Bool
    let isDemonstration: Bool
    let language: String
    var compact = false
    var showsHint = false

    private var prefix: String { isDemonstration ? "demo" : "question" }
    private var clockFont: CGFloat { min(compact ? 28 : 38, (width - 52) / 7.8) }
    private var secondaryInk: Color { highContrast ? DinoStyle.ink : DinoStyle.muted }

    var body: some View {
        VStack(spacing: compact ? 8 : 10) {
            HStack(spacing: 16) {
                endpoint(start, title: "dino.minutesBetween.from", identifier: "start")
                endpoint(end, title: "dino.minutesBetween.until", identifier: "end")
            }

            DinoMinutesBetweenTimeline(timeline: DinoMinuteTimeline(start, end), theme: theme,
                                       language: language, prefix: prefix, showsAnswer: showsAnswer,
                                       showsHint: showsHint, compact: compact)
                .id("\(prefix)-\(start.digitalText)-\(end.digitalText)")

        }
        .padding(12).frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(colors: [.white, DinoStyle.paper], startPoint: .top, endPoint: .bottom))
        }
        .overlay(RoundedRectangle(cornerRadius: 28)
            .strokeBorder(highContrast ? DinoStyle.ink : DinoStyle.deepGreen.opacity(0.16),
                          lineWidth: highContrast ? 2.5 : 1.5))
        .shadow(color: DinoStyle.deepGreen.opacity(0.08), radius: 14, y: 6)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(prefix).minutesBetween.card")
    }

    private func endpoint(_ time: ClockTime, title: String, identifier: String) -> some View {
        VStack(spacing: compact ? 4 : 6) {
            Text(LocalizedStringKey(title))
                .font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(secondaryInk)
            DigitalClock(time: time, theme: theme, fontSize: clockFont)
                .accessibilityIdentifier("\(prefix).minutesBetween.\(identifier)")
        }.frame(maxWidth: .infinity)
    }
}

/// One continuous track: initially an arrow through the unknown total, then a lower timeline.
struct DinoMinutesBetweenTimeline: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var deviceHourFormat = DeviceHourFormat.shared
    let timeline: DinoMinuteTimeline
    let theme: ClockTheme
    let language: String
    let prefix: String
    let showsAnswer: Bool
    let showsHint: Bool
    var compact = false
    @State private var expansion: CGFloat = 0

    private var segments: [Int] { timeline.segments }
    private var total: Int { segments.reduce(0, +) }
    private var restingY: CGFloat { compact ? 20 : 22 }
    private var restingHeight: CGFloat { compact ? 40 : 44 }
    private var expandedY: CGFloat { compact ? 50 : 54 }
    private var expandedHeight: CGFloat { expandedY + 74 }
    private var trackInk: Color { highContrast ? DinoStyle.deepGreen : Color(dinoHex: 0x9ABF78) }
    private var sum: String {
        "\(segments.map(String.init).joined(separator: " + ")) = \(DinoTimeWords.minutes(total, language: language))"
    }

    private func segmentWidths(length: CGFloat) -> [CGFloat] {
        let minimum = min(56, length / CGFloat(segments.count))
        var widths = segments.map { _ in CGFloat.zero }
        var remaining = Array(segments.indices)
        var available = length
        while !remaining.isEmpty {
            let total = CGFloat(max(1, remaining.reduce(0) { $0 + segments[$1] }))
            let small = remaining.filter { available * CGFloat(segments[$0]) / total < minimum }
            if small.isEmpty {
                for index in remaining { widths[index] = available * CGFloat(segments[index]) / total }
                break
            }
            for index in small { widths[index] = minimum; available -= minimum }
            remaining.removeAll { small.contains($0) }
        }
        return widths
    }

    private func segmentColor(_ index: Int) -> Color {
        let palette: [UInt32] = [0xC9E4FF, 0xD8F1CD, 0xFFE6C5, 0xE7DDF7]
        return Color(dinoHex: palette[timeline.colorGroups[index] % palette.count])
    }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                let inset: CGFloat = compact ? 25 : 30
                let length = max(1, geometry.size.width - inset * 2)
                let widths = segmentWidths(length: length)
                let points = (0..<timeline.times.count).map { index in
                    inset + widths.prefix(index).reduce(0, +)
                }
                let labelWidth = min(inset * 2, (widths.min() ?? length) - 3)
                let lineY = restingY + (expandedY - restingY) * expansion
                ZStack(alignment: .topLeading) {
                    // The span cap stays behind the total as the original track moves down.
                    DinoMinuteSpanCap()
                        .stroke(trackInk, style: StrokeStyle(lineWidth: highContrast ? 2 : 1.5, lineCap: .round))
                        .frame(width: length, height: max(1, lineY - restingY - 10))
                        .position(x: geometry.size.width / 2, y: restingY + max(1, lineY - restingY - 10) / 2)
                        .opacity(expansion).accessibilityHidden(true)

                    Rectangle().fill(trackInk)
                        .frame(width: length, height: 2 + 2 * expansion)
                        .position(x: geometry.size.width / 2, y: lineY)
                        .accessibilityHidden(true)
                    dot.position(x: inset, y: lineY)
                    Path { path in
                        path.move(to: CGPoint(x: inset + length - 6, y: lineY - 5))
                        path.addLine(to: CGPoint(x: inset + length, y: lineY))
                        path.addLine(to: CGPoint(x: inset + length - 6, y: lineY + 5))
                    }
                    .stroke(trackInk, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .opacity(1 - expansion).accessibilityHidden(true)

                    if showsHint {
                        ForEach(Array(timeline.times.enumerated()), id: \.offset) { index, time in
                            if index > 0 { dot.position(x: points[index], y: lineY).opacity(expansion) }
                            Text(verbatim: theme.digitalReading(time, languageCode: language))
                                .font(.system(size: compact ? 12 : 14, weight: .bold, design: .rounded))
                                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
                                .frame(width: labelWidth, height: 20)
                                .position(x: points[index], y: lineY + 16)
                                .opacity(expansion)
                                .accessibilityIdentifier("\(prefix).minutesBetween.stop.\(index)")
                        }
                        ForEach(Array(segments.enumerated()), id: \.offset) { index, minutes in
                            let center = (points[index] + points[index + 1]) / 2
                            DinoMinuteUnderbrace()
                                .stroke(trackInk, style: StrokeStyle(lineWidth: highContrast ? 2 : 1.5, lineCap: .round))
                                .frame(width: max(1, widths[index] - 8), height: 10)
                                .position(x: center, y: lineY + 34)
                                .opacity(expansion).accessibilityHidden(true)
                            Text(verbatim: "\(minutes) min")
                                .font(.system(size: compact ? 13 : 15, weight: .heavy, design: .rounded))
                                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.65)
                                .foregroundStyle(DinoStyle.ink)
                                .frame(width: max(1, widths[index] - 6), height: compact ? 26 : 28)
                                .background(segmentColor(index), in: RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(highContrast ? DinoStyle.ink : .clear, lineWidth: 1.5))
                                .position(x: center, y: lineY + 54)
                                .opacity(expansion)
                                .accessibilityIdentifier("\(prefix).minutesBetween.segment.\(index)")
                        }
                    }
                    totalLabel
                        .position(x: geometry.size.width / 2, y: restingY)
                        .animation(nil, value: showsAnswer)
                }
            }
            .frame(height: restingHeight + (expandedHeight - restingHeight) * expansion)
            .clipped()
            if showsHint && showsAnswer {
                Text(verbatim: sum)
                    .font(.system(size: compact ? 12 : 14, weight: .bold, design: .rounded))
                    .monospacedDigit().multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("\(prefix).minutesBetween.conversion")
            }
        }
        .foregroundStyle(DinoStyle.ink)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(prefix).minutesBetween.\(showsHint ? "timeline" : "interval")")
        .onAppear { setExpanded(showsHint) }
        .onChange(of: showsHint) { setExpanded($0) }
    }

    private func setExpanded(_ expands: Bool) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.55)) {
            expansion = expands ? 1 : 0
        }
    }

    private var dot: some View {
        Circle().fill(DinoStyle.green)
            .overlay(Circle().strokeBorder(DinoStyle.deepGreen, lineWidth: 2))
            .frame(width: 12, height: 12)
            .accessibilityHidden(true)
    }

    private var totalLabel: some View {
        HStack(spacing: 7) {
            Image(systemName: "stopwatch")
                .font(.system(size: 17, weight: .semibold)).accessibilityHidden(true)
            Text(verbatim: showsAnswer ? DinoTimeWords.minutes(total, language: language) : "? min")
                .font(.system(size: compact ? 18 : 20, weight: .heavy, design: .rounded))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.75)
        }
        .foregroundStyle(showsAnswer ? DinoTimeDirection.color(later: true, highContrast: highContrast) : DinoStyle.ink)
        .padding(.horizontal, 16).padding(.vertical, compact ? 7 : 8)
        .background {
            Capsule().fill(DinoStyle.paper)
                .overlay {
                    if showsAnswer { Capsule().fill(DinoTimeDirection.background(later: true, highContrast: highContrast)) }
                }
        }
        .overlay(Capsule().strokeBorder(DinoTimeDirection.color(later: true, highContrast: highContrast).opacity(highContrast ? 1 : 0.5),
                                       style: StrokeStyle(lineWidth: highContrast ? 2.5 : 1.5,
                                                          dash: showsAnswer ? [] : [5, 4])))
        .padding(.horizontal, 24)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: showsAnswer ? DinoTimeWords.minutes(total, language: language) : "? min"))
        .accessibilityIdentifier(prefix == "demo" ? "demo.answer" : "question.minutesBetween.\(showsAnswer ? "answer" : "unknown")")
    }
}

/// Rounded cap joining the two ends of the total interval above the lowered track.
private struct DinoMinuteSpanCap: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = min(16, rect.height)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY),
                          control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                          control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}

/// A shallow, smooth underbrace gathering one interval into its minute block.
private struct DinoMinuteUnderbrace: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        var path = Path()
        path.move(to: point(0, 0))
        path.addCurve(to: point(0.18, 0.55), control1: point(0, 0.55), control2: point(0.08, 0.55))
        path.addLine(to: point(0.38, 0.55))
        path.addCurve(to: point(0.5, 1), control1: point(0.46, 0.55), control2: point(0.5, 0.7))
        path.addCurve(to: point(0.62, 0.55), control1: point(0.5, 0.7), control2: point(0.54, 0.55))
        path.addLine(to: point(0.82, 0.55))
        path.addCurve(to: point(1, 0), control1: point(0.92, 0.55), control2: point(1, 0.55))
        return path
    }
}
