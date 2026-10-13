import SwiftUI

struct DigitalClock: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let time: ClockTime
    let theme: ClockTheme
    var fontSize: CGFloat = 42
    var showHandHints = false
    var body: some View {
        HStack(spacing: theme.numerals == .digital ? fontSize * 0.1 : 0) {
            pair(String(time.digitalText.prefix(2)), number: 1, ink: theme.hourInk)
            if theme.numerals == .digital {
                SevenSegmentDigit(character: ":").frame(width: fontSize * 0.15, height: fontSize * 0.86)
            } else {
                Text(verbatim: ":")
            }
            pair(String(time.digitalText.suffix(2)), number: 2, ink: theme.minuteInk)
        }
        .font(.system(size: fontSize, weight: .bold, design: theme.numerals == .rounded ? .rounded : .monospaced))
        .monospacedDigit()
        .padding(.vertical, theme.numerals == .digital ? fontSize * 0.08 : 0)
        .foregroundStyle(theme.display.isDark ? .white : DinoStyle.ink)
        .padding(.horizontal, fontSize * 0.38).padding(.vertical, fontSize * 0.22)
        .background(Color(dinoHex: theme.display.hex), in: RoundedRectangle(cornerRadius: fontSize * 0.35))
        .overlay(RoundedRectangle(cornerRadius: fontSize * 0.35).stroke(DinoStyle.ink.opacity(highContrast ? 1 : 0.1), lineWidth: highContrast ? 3 : 2))
        .padding(.top, showHandHints ? 48 : 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(time.digitalText)
        .environment(\.layoutDirection, .leftToRight)
    }

    private func pair(_ text: String, number: Int, ink: ClockInk) -> some View {
        Group {
            if theme.numerals == .digital {
                HStack(spacing: fontSize * 0.1) {
                    ForEach(Array(text.enumerated()), id: \.offset) { _, character in
                        SevenSegmentDigit(character: character).frame(width: fontSize * 0.5, height: fontSize * 0.86)
                    }
                }
            } else { Text(verbatim: text) }
        }
        .overlay(alignment: .top) {
            if showHandHints {
                VStack(spacing: 2) {
                    Text(verbatim: "\(number)").font(.system(size: 16, weight: .heavy, design: .rounded))
                        .frame(width: 24, height: 24).background(.white, in: Circle())
                        .overlay(Circle().stroke(Color(dinoHex: ink.hex), lineWidth: 2))
                    Image(systemName: "arrow.down").font(.system(size: 18, weight: .bold))
                }.foregroundStyle(Color(dinoHex: ink.hex))
                    .offset(y: -48 - fontSize * (theme.numerals == .digital ? 0.3 : 0.22))
                    .accessibilityHidden(true)
            }
        }
    }
}

private struct SevenSegmentDigit: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let character: Character
    private let segments: [Character: Set<Int>] = [
        "0": [0, 1, 2, 3, 4, 5], "1": [1, 2], "2": [0, 1, 6, 4, 3],
        "3": [0, 1, 2, 3, 6], "4": [5, 6, 1, 2], "5": [0, 5, 6, 2, 3],
        "6": [0, 5, 4, 3, 2, 6], "7": [0, 1, 2], "8": [0, 1, 2, 3, 4, 5, 6],
        "9": [0, 1, 2, 3, 5, 6]
    ]
    var body: some View {
        GeometryReader { g in
            if character == ":" {
                VStack { Circle(); Spacer(); Circle() }.padding(.vertical, g.size.height * 0.25)
            } else {
                let w = g.size.width
                let h = g.size.height
                let thickness = w * 0.17
                let points: [CGPoint] = [
                    .init(x: w / 2, y: thickness / 2), .init(x: w - thickness / 2, y: h * 0.25),
                    .init(x: w - thickness / 2, y: h * 0.75), .init(x: w / 2, y: h - thickness / 2),
                    .init(x: thickness / 2, y: h * 0.75), .init(x: thickness / 2, y: h * 0.25),
                    .init(x: w / 2, y: h / 2)
                ]
                ForEach(0..<7, id: \.self) { i in
                    Capsule().frame(width: [0, 3, 6].contains(i) ? w * 0.72 : thickness,
                                    height: [0, 3, 6].contains(i) ? thickness : h * 0.37)
                        .opacity(segments[character, default: []].contains(i) ? 1 : highContrast ? 0 : 0.08)
                        .position(points[i])
                }
            }
        }
    }
}

struct DigitalClockControl: View {
    @Binding var hour: Int
    let theme: ClockTheme
    var minute = 0
    var fontSize: CGFloat = 38
    var onMinuteChange: ((Int) -> Void)? = nil
    var minuteStep = 1
    var valueIdentifier = "clock.value"
    var showHandHints = false
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                DinoIconButton(icon: "minus", labelKey: "dino.hourLess") { hour = ClockTime.shiftedHour(hour, by: -1) }
                    .accessibilityIdentifier("clock.hour.less")
                DigitalClock(time: ClockTime(hour: hour, minute: minute), theme: theme, fontSize: fontSize, showHandHints: showHandHints)
                    .accessibilityIdentifier(valueIdentifier)
                DinoIconButton(icon: "plus", labelKey: "dino.hourMore") { hour = ClockTime.shiftedHour(hour, by: 1) }
                    .accessibilityIdentifier("clock.hour.more")
            }
            if let onMinuteChange {
                HStack {
                    DinoIconButton(icon: "minus", labelKey: "dino.minuteLess") { onMinuteChange(ClockTime.shiftedMinute(minute, by: -minuteStep)) }
                        .accessibilityIdentifier("clock.minute.less")
                    Text("dino.minutes").font(.subheadline)
                    DinoIconButton(icon: "plus", labelKey: "dino.minuteMore") { onMinuteChange(ClockTime.shiftedMinute(minute, by: minuteStep)) }
                        .accessibilityIdentifier("clock.minute.more")
                }
            }
        }
    }
}
