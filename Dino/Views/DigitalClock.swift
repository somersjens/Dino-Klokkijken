import SwiftUI

private enum DigitalClockField: CaseIterable, Hashable {
    case hours, minutes
}

private struct DigitalClockFieldAnchors: PreferenceKey {
    static var defaultValue: [DigitalClockField: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [DigitalClockField: Anchor<CGRect>],
                       nextValue: () -> [DigitalClockField: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

struct DigitalClockOutline: InsettableShape {
    var shape: DigitalClockShape
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let bounds = rect.insetBy(dx: insetAmount, dy: insetAmount)
        switch shape {
        case .oval: return Path(ellipseIn: bounds)
        case .roundedRectangle: return Path(roundedRect: bounds, cornerRadius: bounds.height * 0.24)
        case .rectangle: return Path(bounds)
        }
    }

    func inset(by amount: CGFloat) -> Self {
        var result = self
        result.insetAmount += amount
        return result
    }
}

struct DigitalClock: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let time: ClockTime
    let theme: ClockTheme
    var fontSize: CGFloat = 42
    var showsDisplay = true
    var showHandHints = false
    var exposesControlFields = false
    var body: some View {
        HStack(spacing: theme.numerals == .digital ? fontSize * 0.1 : 0) {
            pair(String(time.digitalText.prefix(2)), number: 1, ink: theme.hourHex)
            if theme.numerals == .digital {
                SevenSegmentDigit(character: ":").frame(width: fontSize * 0.15, height: fontSize * 0.86)
            } else {
                Text(verbatim: ":")
            }
            pair(String(time.digitalText.suffix(2)), number: 2, ink: theme.minuteHex)
        }
        .font(.system(size: fontSize, weight: .heavy, design: theme.numerals.fontDesign))
        .monospacedDigit()
        .padding(.vertical, theme.numerals == .digital ? fontSize * 0.08 : 0)
        .foregroundStyle(Color(dinoHex: theme.digitalInkHex))
        .padding(.horizontal, showsDisplay ? fontSize * (theme.digitalShape == .oval ? 0.62 : 0.38) : 0)
        .padding(.vertical, showsDisplay ? fontSize * 0.22 : 0)
        .background {
            if showsDisplay {
                DigitalClockOutline(shape: theme.digitalShape).fill(Color(dinoHex: theme.displayHex))
            }
        }
        .overlay {
            if showsDisplay {
                DigitalClockOutline(shape: theme.digitalShape)
                    .strokeBorder(DinoStyle.ink.opacity(highContrast ? 1 : 0.1), lineWidth: highContrast ? 3 : 2)
            }
        }
        .padding(.top, showHandHints ? 48 : 0)
        .environment(\.layoutDirection, .leftToRight)
    }

    private func pair(_ text: String, number: Int, ink: UInt32) -> some View {
        DigitalClockDigits(text: text, numerals: theme.numerals, fontSize: fontSize)
            .anchorPreference(key: DigitalClockFieldAnchors.self, value: .bounds) { anchor in
                exposesControlFields ? [number == 2 ? .minutes : .hours: anchor] : [:]
            }
            .overlay(alignment: .top) {
                if showHandHints {
                    ClockHintBadgeArrow(number: number, badge: CGPoint(x: 15, y: 14.5),
                                        tip: CGPoint(x: 15, y: 43.75),
                                        wings: [CGPoint(x: 10.5, y: 38), CGPoint(x: 19.5, y: 38)],
                                        ink: ink, bounds: CGSize(width: 30, height: 48))
                        .offset(y: -48 - fontSize * (theme.numerals == .digital ? 0.3 : 0.22))
                        .accessibilityHidden(true)
                }
            }
    }
}

private extension DigitalNumerals {
    var fontDesign: Font.Design {
        switch self {
        case .rounded: return .rounded
        case .digital, .modern: return .monospaced
        case .classic: return .serif
        }
    }
}

private struct DigitalClockDigits: View {
    let text: String
    let numerals: DigitalNumerals
    let fontSize: CGFloat

    var body: some View {
        Group {
            if numerals == .digital {
                HStack(spacing: fontSize * 0.1) {
                    ForEach(Array(text.enumerated()), id: \.offset) { _, character in
                        SevenSegmentDigit(character: character)
                            .frame(width: fontSize * 0.5, height: fontSize * 0.86)
                    }
                }
            } else { Text(verbatim: text) }
        }
        .font(.system(size: fontSize, weight: .heavy, design: numerals.fontDesign))
        .monospacedDigit()
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
                let thickness = w * 0.24
                let points: [CGPoint] = [
                    .init(x: w / 2, y: thickness / 2), .init(x: w - thickness / 2, y: h * 0.25),
                    .init(x: w - thickness / 2, y: h * 0.75), .init(x: w / 2, y: h - thickness / 2),
                    .init(x: thickness / 2, y: h * 0.75), .init(x: thickness / 2, y: h * 0.25),
                    .init(x: w / 2, y: h / 2)
                ]
                ForEach(0..<7, id: \.self) { i in
                    Capsule().frame(width: [0, 3, 6].contains(i) ? w * 0.76 : thickness,
                                    height: [0, 3, 6].contains(i) ? thickness : h * 0.39)
                        .opacity(segments[character, default: []].contains(i) ? 1 : highContrast ? 0 : 0.08)
                        .position(points[i])
                }
            }
        }
    }
}

struct DigitalClockControl: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Binding var hour: Int
    let theme: ClockTheme
    var minute = 0
    var fontSize: CGFloat = 38
    var onMinuteChange: ((Int) -> Void)? = nil
    var minuteStep = 1
    var valueIdentifier = "clock.value"
    var showHandHints = false
    var feedbackCorrect: Bool? = nil
    private var time: ClockTime { ClockTime(hour: hour, minute: minute) }

    var body: some View {
        DigitalClock(time: time, theme: theme, fontSize: fontSize, exposesControlFields: true)
            .accessibilityHidden(true)
            .modifier(ClockAnswerOutline(visible: feedbackCorrect != nil, correct: feedbackCorrect == true))
            .padding(.vertical, 48)
            .overlayPreferenceValue(DigitalClockFieldAnchors.self) { anchors in
                GeometryReader { geometry in
                    ForEach(DigitalClockField.allCases, id: \.self) { field in
                        if let anchor = anchors[field] {
                            let center = geometry[anchor].midX
                            arrow(field: field, direction: 1)
                                .position(x: center, y: 22)
                            arrow(field: field, direction: -1)
                                .position(x: center, y: geometry.size.height - 22)
                            if showHandHints {
                                ClockHintBadgeArrow(number: field == .minutes ? 2 : 1,
                                                    badge: CGPoint(x: 15, y: 14.5),
                                                    tip: CGPoint(x: 15, y: 43.75),
                                                    wings: [CGPoint(x: 10.5, y: 38), CGPoint(x: 19.5, y: 38)],
                                                    ink: field == .minutes ? theme.minuteHex : theme.hourHex,
                                                    bounds: CGSize(width: 30, height: 48))
                                    .position(x: center, y: -24)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                }
            }
            .padding(.top, showHandHints ? 48 : 0)
            .disabled(feedbackCorrect != nil)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(time.digitalText)
            .accessibilityIdentifier(valueIdentifier)
            .environment(\.layoutDirection, .leftToRight)
    }

    private func arrow(field: DigitalClockField, direction: Int) -> some View {
        let minutes = field == .minutes
        let labelKey = minutes
            ? (direction > 0 ? "dino.minuteMore" : "dino.minuteLess")
            : (direction > 0 ? "dino.hourMore" : "dino.hourLess")
        let value = String(minutes ? time.digitalText.suffix(2) : time.digitalText.prefix(2))
        return Button { adjust(direction, minutes: minutes) } label: {
            Image(systemName: direction > 0 ? "chevron.up" : "chevron.down")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(DinoStyle.ink.opacity(highContrast ? 1 : 0.75))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(minutes && onMinuteChange == nil)
        .accessibilityLabel(LocalizedStringKey(labelKey))
        .accessibilityValue(value)
        .accessibilityIdentifier("clock.\(minutes ? "minute" : "hour").\(direction > 0 ? "more" : "less")")
    }

    private func adjust(_ direction: Int, minutes: Bool) {
        guard feedbackCorrect == nil else { return }
        if minutes, let onMinuteChange {
            onMinuteChange(ClockTime.shiftedMinute(minute, by: direction * (minuteStep < 60 ? minuteStep : 5)))
        } else if !minutes {
            hour = ClockTime.shiftedHour(hour, by: direction)
        }
    }
}
