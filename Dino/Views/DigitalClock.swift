import SwiftUI

private enum DigitalControlAnchor: Hashable {
    case digits, display, decrease, increase
}

private struct DigitalControlAnchors: PreferenceKey {
    static var defaultValue: [DigitalControlAnchor: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [DigitalControlAnchor: Anchor<CGRect>],
                       nextValue: () -> [DigitalControlAnchor: Anchor<CGRect>]) {
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
    /// nil for a read-only clock; false underlines hours, true underlines minutes.
    var activeMinutes: Bool? = nil
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
        .font(.system(size: fontSize, weight: .heavy, design: numeralDesign))
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
        .transformAnchorPreference(key: DigitalControlAnchors.self, value: .bounds) { anchors, display in
            if activeMinutes != nil { anchors[.display] = display }
        }
        .padding(.top, showHandHints ? 48 : 0)
        .environment(\.layoutDirection, .leftToRight)
    }

    private var numeralDesign: Font.Design {
        switch theme.numerals {
        case .rounded: return .rounded
        case .digital, .modern: return .monospaced
        case .classic: return .serif
        }
    }

    private func pair(_ text: String, number: Int, ink: UInt32) -> some View {
        Group {
            if theme.numerals == .digital {
                HStack(spacing: fontSize * 0.1) {
                    ForEach(Array(text.enumerated()), id: \.offset) { _, character in
                        SevenSegmentDigit(character: character).frame(width: fontSize * 0.5, height: fontSize * 0.86)
                    }
                }
            } else { Text(verbatim: text) }
        }
        .anchorPreference(key: DigitalControlAnchors.self, value: .bounds) {
            activeMinutes == (number == 2) ? [.digits: $0] : [:]
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
    @Binding var hour: Int
    @Binding var adjustingMinutes: Bool
    let theme: ClockTheme
    var minute = 0
    var fontSize: CGFloat = 38
    var onMinuteChange: ((Int) -> Void)? = nil
    var minuteStep = 1
    var valueIdentifier = "clock.value"
    var showHandHints = false
    var body: some View {
        HStack(spacing: 8) {
            DinoIconButton(icon: "minus", labelKey: adjustingMinutes ? "dino.minuteLess" : "dino.hourLess") { adjust(-1) }
                .accessibilityIdentifier(adjustingMinutes ? "clock.minute.less" : "clock.hour.less")
                .anchorPreference(key: DigitalControlAnchors.self, value: .bounds) { [.decrease: $0] }
            Button {
                if onMinuteChange != nil { adjustingMinutes.toggle() }
            } label: {
                DigitalClock(time: ClockTime(hour: hour, minute: minute), theme: theme, fontSize: fontSize,
                             showHandHints: showHandHints, activeMinutes: adjustingMinutes)
            }
            .buttonStyle(.plain).contentShape(Rectangle())
            // Align the buttons with the display, below its numbered annotations.
            .alignmentGuide(VerticalAlignment.center) { dimensions in
                dimensions[VerticalAlignment.center] + (showHandHints ? 24 : 0)
            }
            .accessibilityIdentifier(valueIdentifier)
            DinoIconButton(icon: "plus", labelKey: adjustingMinutes ? "dino.minuteMore" : "dino.hourMore") { adjust(1) }
                .accessibilityIdentifier(adjustingMinutes ? "clock.minute.more" : "clock.hour.more")
                .anchorPreference(key: DigitalControlAnchors.self, value: .bounds) { [.increase: $0] }
        }
        .backgroundPreferenceValue(DigitalControlAnchors.self) { anchors in
            GeometryReader { geometry in
                if let digits = anchors[.digits], let display = anchors[.display],
                   let decrease = anchors[.decrease], let increase = anchors[.increase] {
                    let field = geometry[digits]
                    let screen = geometry[display]
                    let minus = geometry[decrease]
                    let plus = geometry[increase]
                    let underlineY = screen.maxY + 5
                    let connectorY = max(underlineY, minus.maxY, plus.maxY) + 12
                    Path { path in
                        path.move(to: CGPoint(x: field.minX, y: underlineY))
                        path.addLine(to: CGPoint(x: field.maxX, y: underlineY))
                        path.move(to: CGPoint(x: field.midX, y: underlineY))
                        path.addLine(to: CGPoint(x: field.midX, y: connectorY))
                        path.move(to: CGPoint(x: minus.midX, y: minus.maxY + 2))
                        path.addLine(to: CGPoint(x: minus.midX, y: connectorY))
                        path.addLine(to: CGPoint(x: plus.midX, y: connectorY))
                        path.addLine(to: CGPoint(x: plus.midX, y: plus.maxY + 2))
                    }
                    .stroke(DinoStyle.ink, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .accessibilityIdentifier("\(valueIdentifier).connectors")
                }
            }.allowsHitTesting(false).accessibilityHidden(true)
        }
        .padding(.bottom, 22)
        .environment(\.layoutDirection, .leftToRight)
    }

    private func adjust(_ direction: Int) {
        if adjustingMinutes, let onMinuteChange {
            let shifted = ClockTime(hour: hour, minute: minute)
                .shiftingMinutes(by: direction * (minuteStep < 60 ? minuteStep : 5))
            hour = shifted.hour
            onMinuteChange(shifted.minute)
        } else {
            hour = ClockTime.shiftedHour(hour, by: direction)
        }
    }
}
