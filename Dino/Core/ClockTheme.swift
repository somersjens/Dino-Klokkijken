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
    case white, beige, blue, green
    var hex: UInt32 {
        switch self {
        case .white: return 0xFFFFFF
        case .beige: return 0xFFF1D6
        case .blue: return 0xE2F3FD
        case .green: return 0xE5F6DC
        }
    }
}

enum ClockHandStyle: String, Codable, CaseIterable, Sendable {
    case straight, rounded, playful
}

enum DigitalDisplay: String, Codable, CaseIterable, Sendable {
    case white, navy, green, charcoal
    var hex: UInt32 {
        switch self {
        case .white: return 0xFFFFFF
        case .navy: return 0x193B53
        case .green: return 0xE5F6DC
        case .charcoal: return 0x303A40
        }
    }
    var isDark: Bool { self == .navy || self == .charcoal }
}

enum DigitalNumerals: String, Codable, CaseIterable, Sendable {
    case rounded, digital, modern
}

struct ClockTheme: Codable, Equatable, Sendable {
    var face: ClockFace = .white
    var hourInk: ClockInk = .navy
    var minuteInk: ClockInk = .orange
    var rimInk: ClockInk = .navy
    var hands: ClockHandStyle = .rounded
    var display: DigitalDisplay = .navy
    var numerals: DigitalNumerals = .rounded
    static let standard = ClockTheme()
}
