import SwiftUI

/// Both endpoints stay visible while the unknown interval becomes the worked answer.
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
    private var clockFont: CGFloat { min(compact ? 31 : 48, (width - 52) / 7.8) }
    private var secondaryInk: Color { highContrast ? DinoStyle.ink : DinoStyle.muted }

    var body: some View {
        VStack(spacing: compact ? 10 : 18) {
            HStack(spacing: 16) {
                endpoint(start, title: "dino.minutesBetween.from", identifier: "start")
                endpoint(end, title: "dino.minutesBetween.until", identifier: "end")
            }

            ZStack {
                HStack(spacing: 0) {
                    Circle().fill(DinoStyle.green)
                        .overlay(Circle().strokeBorder(DinoStyle.deepGreen, lineWidth: 2))
                        .frame(width: 12, height: 12)
                    Rectangle().fill(DinoStyle.deepGreen.opacity(highContrast ? 1 : 0.35))
                        .frame(height: 2)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(DinoStyle.deepGreen)
                }.accessibilityHidden(true)

                HStack(spacing: 9) {
                    Image(systemName: "stopwatch")
                        .font(.system(size: 19, weight: .semibold)).accessibilityHidden(true)
                    Text(verbatim: showsAnswer ? DinoTimeWords.minutes(minutes, language: language) : "? min")
                        .font(.system(size: compact ? 20 : 22, weight: .heavy, design: .rounded))
                        .monospacedDigit().lineLimit(1).minimumScaleFactor(0.75)
                }
                .foregroundStyle(showsAnswer ? DinoTimeDirection.color(later: minutes >= 0, highContrast: highContrast) : DinoStyle.ink)
                .padding(.horizontal, 18).padding(.vertical, compact ? 10 : 13)
                .background {
                    Capsule().fill(DinoStyle.paper)
                        .overlay {
                            if showsAnswer { Capsule().fill(DinoTimeDirection.background(later: minutes >= 0, highContrast: highContrast)) }
                        }
                }
                .overlay(Capsule().strokeBorder(DinoTimeDirection.color(later: minutes >= 0, highContrast: highContrast).opacity(highContrast ? 1 : 0.5),
                                               style: StrokeStyle(lineWidth: highContrast ? 2.5 : 1.5,
                                                                  dash: showsAnswer ? [] : [5, 4])))
                .padding(.horizontal, 24)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: showsAnswer ? DinoTimeWords.minutes(minutes, language: language) : "? min"))
                .accessibilityIdentifier(isDemonstration ? "demo.answer" : "question.minutesBetween.\(showsAnswer ? "answer" : "unknown")")
            }

            if showsHint {
                DinoMinutesBetweenTimeline(timeline: DinoMinuteTimeline(start, end), theme: theme,
                                           language: language, prefix: prefix,
                                           showsAnswer: showsAnswer, compact: compact)
            }
        }
        .padding(compact ? 14 : 18).frame(maxWidth: .infinity)
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
        VStack(spacing: compact ? 6 : 8) {
            Text(LocalizedStringKey(title))
                .font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(secondaryInk)
            DigitalClock(time: time, theme: theme, fontSize: clockFont)
                .accessibilityIdentifier("\(prefix).minutesBetween.\(identifier)")
        }.frame(maxWidth: .infinity)
    }
}

/// A compact addition to the original From / Until card. Labels share the dots' centers.
struct DinoMinutesBetweenTimeline: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @ObservedObject private var deviceHourFormat = DeviceHourFormat.shared
    let timeline: DinoMinuteTimeline
    let theme: ClockTheme
    let language: String
    let prefix: String
    let showsAnswer: Bool
    var compact = false

    private var segments: [Int] { timeline.segments }
    private var sum: String {
        "\(segments.map(String.init).joined(separator: " + ")) = \(DinoTimeWords.minutes(segments.reduce(0, +), language: language))"
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

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                let inset: CGFloat = compact ? 25 : 30
                let length = max(1, geometry.size.width - inset * 2)
                // Preserve proportional lengths where possible, with enough room for every time.
                let widths = segmentWidths(length: length)
                let points = (0..<timeline.times.count).map { index in
                    inset + widths.prefix(index).reduce(0, +)
                }
                let labelWidth = min(inset * 2, (widths.min() ?? length) - 3)
                ZStack(alignment: .topLeading) {
                    Path { path in
                        path.move(to: CGPoint(x: inset, y: 34))
                        path.addLine(to: CGPoint(x: inset + length, y: 34))
                    }
                    .stroke(highContrast ? DinoStyle.ink : DinoStyle.muted.opacity(0.55), lineWidth: 2)
                    .accessibilityHidden(true)

                    ForEach(Array(timeline.times.enumerated()), id: \.offset) { index, time in
                        Text(verbatim: theme.digitalReading(time, languageCode: language))
                            .font(.system(size: compact ? 13 : 16, weight: .bold, design: .rounded))
                            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
                            .frame(width: labelWidth, height: 25)
                            .position(x: points[index], y: 13)
                            .accessibilityIdentifier("\(prefix).minutesBetween.stop.\(index)")
                        Circle().fill(DinoStyle.deepGreen)
                            .frame(width: 10, height: 10)
                            .position(x: points[index], y: 34)
                            .accessibilityHidden(true)
                    }
                    ForEach(Array(segments.enumerated()), id: \.offset) { index, minutes in
                        let revealed = timeline.revealsSegment(index, showsAnswer: showsAnswer)
                        Text(verbatim: revealed ? "\(minutes) min" : "? min")
                            .font(.system(size: compact ? 14 : 17, weight: .heavy, design: .rounded))
                            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.65)
                            .foregroundStyle(DinoStyle.ink)
                            .frame(width: max(1, widths[index] - 5), height: compact ? 32 : 36)
                            .background(index == 0 ? Color(dinoHex: 0xD4E9FC) : Color(dinoHex: 0xD9F2DA),
                                        in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(highContrast ? DinoStyle.ink : .clear, lineWidth: 1.5))
                            .position(x: (points[index] + points[index + 1]) / 2, y: compact ? 62 : 64)
                            .accessibilityIdentifier("\(prefix).minutesBetween.segment.\(index)")
                    }
                }
            }
            .frame(height: compact ? 80 : 84)
            if showsAnswer {
                Text(verbatim: sum)
                    .font(.system(size: compact ? 13 : 15, weight: .bold, design: .rounded))
                    .monospacedDigit().multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("\(prefix).minutesBetween.conversion")
            }
        }
        .foregroundStyle(DinoStyle.ink)
        .padding(8).frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .strokeBorder(highContrast ? DinoStyle.ink : DinoStyle.deepGreen.opacity(0.12), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(prefix).minutesBetween.timeline")
    }
}
