import Foundation

enum ClockInk: String, Codable, CaseIterable, Sendable {
    case navy, orange, green, purple, red
    var hex: UInt32 {
        switch self {
        case .navy: return 0x193B53
        case .orange: return 0xBC5518
        case .green: return 0x176647
        case .purple: return 0x6945A0
        case .red: return 0xB93848
        }
    }
}

enum ClockFace: String, Codable, CaseIterable, Sendable {
    case black, white, beige, blue, green
    var hex: UInt32 {
        switch self {
        case .black: return 0x000000
        case .white: return 0xFFFFFF
        case .beige: return 0xFFF1D6
        case .blue: return 0xE2F3FD
        case .green: return 0xE5F6DC
        }
    }
}

enum ClockHandStyle: String, Codable, CaseIterable, Sendable {
    case straight, rounded

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        // Keep profiles made with the retired playful hands readable.
        if value == "playful" { self = .rounded; return }
        guard let style = Self(rawValue: value) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown clock hand style")
        }
        self = style
    }
}

enum AnalogClockShape: String, Codable, CaseIterable, Sendable {
    case circle, square, octagon

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        // Existing five-sided clocks become the new eight-sided clock.
        if value == "pentagon" { self = .octagon; return }
        guard let shape = Self(rawValue: value) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown analog clock shape")
        }
        self = shape
    }
}

enum DigitalClockShape: String, Codable, CaseIterable, Sendable {
    case oval, roundedRectangle, rectangle
}

enum DigitalDisplay: String, Codable, CaseIterable, Sendable {
    case black, navy, teal, yellow, white
    // Decode older profiles without changing their saved background color.
    case charcoal, green
    static let allCases: [Self] = [.black, .navy, .teal, .yellow, .white]
    var hex: UInt32 {
        switch self {
        case .black: return 0x000000
        case .white: return 0xFFFFFF
        case .navy: return 0x193B53
        case .teal: return 0x127F88
        case .yellow: return 0xF4C95D
        case .green: return 0xE5F6DC
        case .charcoal: return 0x303A40
        }
    }
    var isDark: Bool { self == .black || self == .navy || self == .teal || self == .charcoal }
}

enum DigitalNumerals: String, Codable, CaseIterable, Sendable {
    case rounded, digital, modern, classic
}

enum DigitalHourNotation: String, Codable, CaseIterable, Sendable {
    case twelve, twentyFour

    /// The 24-hour switch in Settings, or the region default when that switch was never changed.
    static var device: DigitalHourNotation {
        // UI tests pin this so screens that still expect 24-hour labels stay stable.
        let defaults = UserDefaults.standard
        if ProcessInfo.processInfo.environment["DINO_TEST_SUITE"] != nil,
           defaults.object(forKey: "AppleICUForce24HourTime") != nil {
            return defaults.bool(forKey: "AppleICUForce24HourTime") ? .twentyFour : .twelve
        }
        let format = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? ""
        return format.contains("a") ? .twelve : .twentyFour
    }
}

enum AnalogNumerals: String, Codable, CaseIterable, Sendable {
    case normal, roman

    func label(for hour: Int) -> String {
        guard self == .roman, (1...12).contains(hour) else { return String(hour) }
        return ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"][hour - 1]
    }
}

enum ClockColorContrast {
    private static func luminance(_ background: UInt32) -> Double {
        func linear(_ shift: UInt32) -> Double {
            let channel = Double((background >> shift) & 0xFF) / 255
            return channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(16) + 0.7152 * linear(8) + 0.0722 * linear(0)
    }

    static func ratio(_ first: UInt32, _ second: UInt32) -> Double {
        let a = luminance(first), b = luminance(second)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    static func markingHex(on background: UInt32) -> UInt32 {
        // Choose whichever of black and white has the greater contrast.
        return luminance(background) < 0.179 ? 0xFFFFFF : 0x000000
    }

    /// Prefer a light tint of the hour hand, with a darker shade for very light hands.
    static func hourGuideHex(hand: UInt32, face: UInt32) -> UInt32 {
        func mixed(with target: UInt32, amount: Double) -> UInt32 {
            [UInt32(16), 8, 0].reduce(UInt32(0)) { result, shift in
                let source = Double((hand >> shift) & 0xFF)
                let destination = Double((target >> shift) & 0xFF)
                return result | (UInt32((source + (destination - source) * amount).rounded()) << shift)
            }
        }
        for (target, amount): (UInt32, Double) in [(0xFFFFFF, 0.48), (0xFFFFFF, 0.34), (0xFFFFFF, 0.20),
                                                   (0x000000, 0.25), (0x000000, 0.45), (0x000000, 0.65)] {
            let candidate = mixed(with: target, amount: amount)
            if ratio(candidate, face) >= 3 && ratio(candidate, hand) >= 1.5 { return candidate }
        }
        return markingHex(on: face)
    }
}

struct ClockTheme: Codable, Equatable, Sendable {
    var face: ClockFace = .white
    var hourInk: ClockInk = .navy
    var minuteInk: ClockInk = .orange
    var rimInk: ClockInk = .navy
    var hands: ClockHandStyle = .rounded
    var analogNumerals: AnalogNumerals = .normal
    var display: DigitalDisplay = .navy
    var numerals: DigitalNumerals = .rounded
    var analogShape: AnalogClockShape = .circle
    var digitalShape: DigitalClockShape = .roundedRectangle
    var customFaceHex: UInt32?
    var customHourHex: UInt32?
    var customMinuteHex: UInt32?
    var customRimHex: UInt32?
    var customDisplayHex: UInt32?
    var digitalInkHex: UInt32 = 0xFFFFFF
    /// Nil follows the device. A saved choice stays put when the device later changes.
    var hourNotation: DigitalHourNotation? = nil

    var faceHex: UInt32 { customFaceHex ?? face.hex }
    var hourHex: UInt32 { customHourHex ?? hourInk.hex }
    var minuteHex: UInt32 { customMinuteHex ?? minuteInk.hex }
    var rimHex: UInt32 { customRimHex ?? rimInk.hex }
    var displayHex: UInt32 { customDisplayHex ?? display.hex }
    var markingHex: UInt32 { ClockColorContrast.markingHex(on: faceHex) }
    var analogColorsMatch: Bool { hourHex == faceHex || minuteHex == faceHex }
    var digitalColorsMatch: Bool { digitalInkHex == displayHex }

    func resolvedHourNotation(device: DigitalHourNotation = .device) -> DigitalHourNotation {
        hourNotation ?? device
    }

    func hourNotationDiffersFromDevice(device: DigitalHourNotation = .device) -> Bool {
        guard let hourNotation else { return false }
        return hourNotation != device
    }

    /// Keep the stored options for compatibility and later re-enabling of controls.
    /// While those controls are hidden, all player clocks use these fixed styles.
    func applyingFixedStyles() -> ClockTheme {
        var result = self
        result.hands = .rounded
        result.digitalShape = .roundedRectangle
        return result
    }

    mutating func restoreAnalogColors() {
        face = .white; hourInk = .navy; minuteInk = .orange; rimInk = .navy
        customFaceHex = nil; customHourHex = nil; customMinuteHex = nil; customRimHex = nil
    }

    mutating func restoreDigitalColors() {
        display = .navy
        customDisplayHex = nil; digitalInkHex = 0xFFFFFF
    }

    mutating func resetAnalog() {
        restoreAnalogColors()
        hands = .rounded; analogShape = .circle; analogNumerals = .normal
    }

    mutating func resetDigital() {
        restoreDigitalColors()
        numerals = .rounded; digitalShape = .roundedRectangle; hourNotation = nil
    }

    func replacingUnreadableClocks() -> ClockTheme {
        var result = self
        if analogColorsMatch { result.resetAnalog() }
        if digitalColorsMatch { result.resetDigital() }
        return result
    }

    init() {}

    private enum CodingKeys: String, CodingKey {
        case face, hourInk, minuteInk, rimInk, hands, analogNumerals, display, numerals
        case analogShape, digitalShape, customFaceHex, customHourHex, customMinuteHex, customRimHex, customDisplayHex, digitalInkHex, hourNotation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        face = try container.decodeIfPresent(ClockFace.self, forKey: .face) ?? .white
        hourInk = try container.decodeIfPresent(ClockInk.self, forKey: .hourInk) ?? .navy
        minuteInk = try container.decodeIfPresent(ClockInk.self, forKey: .minuteInk) ?? .orange
        rimInk = try container.decodeIfPresent(ClockInk.self, forKey: .rimInk) ?? .navy
        hands = try container.decodeIfPresent(ClockHandStyle.self, forKey: .hands) ?? .rounded
        analogNumerals = try container.decodeIfPresent(AnalogNumerals.self, forKey: .analogNumerals) ?? .normal
        display = try container.decodeIfPresent(DigitalDisplay.self, forKey: .display) ?? .navy
        numerals = try container.decodeIfPresent(DigitalNumerals.self, forKey: .numerals) ?? .rounded
        analogShape = try container.decodeIfPresent(AnalogClockShape.self, forKey: .analogShape) ?? .circle
        digitalShape = try container.decodeIfPresent(DigitalClockShape.self, forKey: .digitalShape) ?? .roundedRectangle
        customFaceHex = try container.decodeIfPresent(UInt32.self, forKey: .customFaceHex)
        customHourHex = try container.decodeIfPresent(UInt32.self, forKey: .customHourHex)
        customMinuteHex = try container.decodeIfPresent(UInt32.self, forKey: .customMinuteHex)
        customRimHex = try container.decodeIfPresent(UInt32.self, forKey: .customRimHex)
        customDisplayHex = try container.decodeIfPresent(UInt32.self, forKey: .customDisplayHex)
        digitalInkHex = try container.decodeIfPresent(UInt32.self, forKey: .digitalInkHex) ?? (display.isDark ? 0xFFFFFF : 0x193B53)
        hourNotation = try container.decodeIfPresent(DigitalHourNotation.self, forKey: .hourNotation)
    }

    static let standard = ClockTheme()
}
