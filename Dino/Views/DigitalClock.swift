import Combine
import SwiftUI
import UIKit

/// Publishes the device hour cycle so every digital clock refreshes when Settings changes it.
final class DeviceHourFormat: ObservableObject {
    static let shared = DeviceHourFormat()
    @Published private(set) var notation = DigitalHourNotation.device
    private var updates: AnyCancellable?

    private init() {
        updates = NotificationCenter.default.publisher(for: NSLocale.currentLocaleDidChangeNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                let next = DigitalHourNotation.device
                if self?.notation != next { self?.notation = next }
            }
    }
}

extension ClockTheme {
    func digitalReading(_ time: ClockTime, languageCode: String, notation override: DigitalHourNotation? = nil) -> String {
        let notation = override ?? resolvedHourNotation(device: DeviceHourFormat.shared.notation)
        return time.digitalReading(notation: notation, languageCode: languageCode).text
    }
}

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
        case .roundedRectangle: return Path(roundedRect: bounds, cornerRadius: max(0, rect.height * 0.24 - insetAmount))
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
    @Environment(\.dinoClockReadingAssistance) private var readingAssistance
    @ObservedObject private var language = LanguageManager.shared
    @ObservedObject private var deviceHourFormat = DeviceHourFormat.shared
    let time: ClockTime
    let theme: ClockTheme
    var fontSize: CGFloat = 42
    var showsDisplay = true
    var showHandHints = false
    var exposesControlFields = false
    /// Lessons that teach the 24-hour clock keep those digits even when the player prefers 12-hour time.
    var notation: DigitalHourNotation? = nil
    var feedbackCorrect: Bool? = nil
    private var displaysHandHints: Bool { showHandHints || readingAssistance }
    private var hintHeight: CGFloat { displaysHandHints ? 48 * min(1, fontSize / 30) : 0 }
    private var reading: DigitalClockReading {
        time.digitalReading(notation: notation ?? theme.resolvedHourNotation(device: deviceHourFormat.notation),
                            languageCode: language.effective.code)
    }
    var body: some View {
        let value = reading
        // Measure each complete, single-line display before choosing its size. Digits,
        // AM/PM and padding always shrink together, in every clock style.
        ZStack {
            ViewThatFits(in: .horizontal) {
                display(value, fontSize: fontSize)
                display(value, fontSize: fontSize * 0.9)
                display(value, fontSize: fontSize * 0.8)
                display(value, fontSize: fontSize * 0.7)
                display(value, fontSize: fontSize * 0.6)
                display(value, fontSize: fontSize * 0.5)
                display(value, fontSize: fontSize * 0.4)
                display(value, fontSize: fontSize * 0.3)
            }
        }
        .padding(.top, hintHeight)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value.text)
    }

    private func display(_ reading: DigitalClockReading, fontSize: CGFloat) -> some View {
        HStack(alignment: .center, spacing: fontSize * 0.12) {
            HStack(spacing: theme.numerals == .digital ? fontSize * 0.1 : 0) {
                pair(reading.hour, number: 1, ink: theme.hourHex, fontSize: fontSize)
                if theme.numerals == .digital {
                    SevenSegmentDigit(character: ":").frame(width: fontSize * 0.15, height: fontSize * 0.86)
                } else {
                    Text(verbatim: ":")
                }
                pair(reading.minute, number: 2, ink: theme.minuteHex, fontSize: fontSize)
            }
            if let period = reading.period {
                Text(verbatim: period)
                    .font(.system(size: fontSize * 0.34, weight: .heavy, design: theme.numerals.fontDesign))
                    .lineLimit(1)
                    .accessibilityHidden(true)
            }
        }
        .font(.system(size: fontSize, weight: .heavy, design: theme.numerals.fontDesign))
        .monospacedDigit()
        .lineLimit(1)
        .padding(.vertical, theme.numerals == .digital ? fontSize * 0.08 : 0)
        .foregroundStyle(Color(dinoHex: theme.digitalInkHex))
        .padding(.horizontal, showsDisplay ? fontSize * horizontalPadding(for: reading) : 0)
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
                if let feedbackCorrect {
                    // The stroke sits entirely outside the display and follows its
                    // exact shape, rather than cutting across its rounded corners.
                    DigitalClockOutline(shape: theme.digitalShape)
                        .inset(by: -2)
                        .stroke(feedbackCorrect ? (highContrast ? DinoStyle.deepGreen : DinoStyle.green) : DinoStyle.wrong(highContrast),
                                lineWidth: 4)
                }
            }
        }
        // Reserve the ring even before feedback so checking cannot move the clock.
        .padding(showsDisplay ? 4 : 0)
        .fixedSize(horizontal: true, vertical: true)
    }

    private func horizontalPadding(for reading: DigitalClockReading) -> CGFloat {
        let oval = theme.digitalShape == .oval
        if reading.period == nil { return oval ? 0.62 : 0.38 }
        return oval ? 0.46 : 0.28
    }

    private func pair(_ text: String, number: Int, ink: UInt32, fontSize: CGFloat) -> some View {
        DigitalClockDigits(text: text, numerals: theme.numerals, fontSize: fontSize)
            .anchorPreference(key: DigitalClockFieldAnchors.self, value: .bounds) { anchor in
                exposesControlFields ? [number == 2 ? .minutes : .hours: anchor] : [:]
            }
            .overlay(alignment: .top) {
                if displaysHandHints {
                    let scale = min(1, fontSize / 30)
                    ClockHintBadgeArrow(number: number, badge: CGPoint(x: 15, y: 14.5),
                                        tip: CGPoint(x: 15, y: 43.75),
                                        wings: [CGPoint(x: 10.5, y: 38), CGPoint(x: 19.5, y: 38)],
                                        ink: ink, bounds: CGSize(width: 30, height: 48))
                        .scaleEffect(scale)
                        .frame(width: 30 * scale, height: 48 * scale)
                        .offset(y: -48 * scale - fontSize * (theme.numerals == .digital ? 0.3 : 0.22))
                        .accessibilityHidden(true)
                }
            }
    }
}

/// One piece of a digital time, drawn with the same display as the full clock.
struct DigitalClockReadout: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let text: String
    let theme: ClockTheme
    var fontSize: CGFloat = 28
    var width: CGFloat? = nil
    var emphasis: Emphasis = .plain

    enum Emphasis { case plain, bridge, final }

    var body: some View {
        DigitalClockDigits(text: text, numerals: theme.numerals, fontSize: fontSize)
            .font(.system(size: fontSize, weight: .heavy, design: theme.numerals.fontDesign))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(Color(dinoHex: theme.digitalInkHex))
            .frame(width: width, height: fontSize * 1.22)
            .padding(.horizontal, width == nil ? fontSize * 0.34 : 0)
            .padding(.vertical, fontSize * 0.12)
            .frame(minWidth: width ?? fontSize * 1.7)
            .background {
                DigitalClockOutline(shape: theme.digitalShape).fill(Color(dinoHex: theme.displayHex))
            }
            .overlay {
                DigitalClockOutline(shape: theme.digitalShape)
                    .strokeBorder(border, lineWidth: emphasis == .plain && !highContrast ? 2 : highContrast ? 2.5 : 3)
            }
            .fixedSize(horizontal: width == nil, vertical: true)
    }

    private var border: Color {
        switch emphasis {
        case .plain: return DinoStyle.ink.opacity(highContrast ? 1 : 0.12)
        case .bridge: return highContrast ? DinoStyle.ink : Color(dinoHex: 0x154A86)
        case .final: return highContrast ? DinoStyle.ink : DinoStyle.deepGreen
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
    @Environment(\.dinoClockReadingAssistance) private var readingAssistance
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled
    @ObservedObject private var language = LanguageManager.shared
    @ObservedObject private var deviceHourFormat = DeviceHourFormat.shared
    @Binding var hour: Int
    let theme: ClockTheme
    var minute = 0
    var fontSize: CGFloat = 38
    var onMinuteChange: ((Int) -> Void)? = nil
    var minuteStep = 1
    var valueIdentifier = "clock.value"
    var showHandHints = false
    var feedbackCorrect: Bool? = nil
    /// False keeps the arrows visible in their disabled colors after checking an answer.
    var controlsEnabled = true
    var notation: DigitalHourNotation? = nil
    var controlsBelow = false
    var displayHeight: CGFloat? = nil
    private var displaysHandHints: Bool { showHandHints || readingAssistance }
    private var time: ClockTime { ClockTime(hour: hour, minute: minute) }
    private var reading: DigitalClockReading {
        time.digitalReading(notation: notation ?? theme.resolvedHourNotation(device: deviceHourFormat.notation),
                            languageCode: language.effective.code)
    }

    @ViewBuilder var body: some View {
        if controlsBelow {
            VStack(spacing: 12) {
                DigitalClock(time: time, theme: theme, fontSize: fontSize, showHandHints: displaysHandHints,
                             notation: notation, feedbackCorrect: feedbackCorrect)
                    .frame(height: displayHeight)
                    .accessibilityIdentifier(valueIdentifier)
                HStack(spacing: 16) {
                    ForEach(DigitalClockField.allCases, id: \.self) { field in
                        VStack(spacing: 4) {
                            Text(LocalizedStringKey(field == .hours ? "dino.hours" : "dino.minutes"))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                            HStack(spacing: 4) {
                                arrow(field: field, direction: -1)
                                arrow(field: field, direction: 1)
                            }
                        }
                    }
                }
                .disabled(!controlsEnabled || feedbackCorrect != nil)
            }
            .environment(\.layoutDirection, .leftToRight)
        } else { legacyControl }
    }

    private var legacyControl: some View {
        DigitalClock(time: time, theme: theme, fontSize: fontSize,
                     showHandHints: readingAssistance && !showHandHints, exposesControlFields: true,
                     notation: notation, feedbackCorrect: feedbackCorrect)
            .environment(\.dinoClockReadingAssistance, false)
            .accessibilityHidden(true)
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
                .disabled(!controlsEnabled)
                .allowsHitTesting(controlsEnabled)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: controlsEnabled)
            }
            .padding(.top, showHandHints ? 48 : 0)
            .disabled(feedbackCorrect != nil)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(reading.text)
            .accessibilityIdentifier(valueIdentifier)
            .environment(\.layoutDirection, .leftToRight)
    }

    private func arrow(field: DigitalClockField, direction: Int) -> some View {
        let minutes = field == .minutes
        let labelKey = minutes
            ? (direction > 0 ? "dino.minuteMore" : "dino.minuteLess")
            : (direction > 0 ? "dino.hourMore" : "dino.hourLess")
        let value = minutes ? reading.minute : reading.hour
        let enabled = isEnabled && controlsEnabled && feedbackCorrect == nil && (!minutes || onMinuteChange != nil)
        return Button { adjust(direction, minutes: minutes) } label: {
            Image(systemName: direction > 0 ? "chevron.up" : "chevron.down")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(enabled ? DinoStyle.ink.opacity(highContrast ? 1 : 0.75) : DinoStyle.disabledInk(highContrast))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(DinoAnswerButtonStyle())
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
