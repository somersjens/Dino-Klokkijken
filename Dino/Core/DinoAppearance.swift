import Foundation

/// The player's avatar and every companion pose share these colors. Missing data keeps old saves intact.
struct DinoAppearance: Codable, Equatable, Hashable, Sendable {
    enum Part: String, CaseIterable, Sendable {
        case bandana, spikes, body, belly
        var labelKey: String { "dino.appearance.\(rawValue)" }
    }

    var bandana: UInt32 = 0xED2429
    var spikes: UInt32 = 0x246B37
    var body: UInt32 = 0x88C231
    var belly: UInt32 = 0xFBE4AB
    static let standard = DinoAppearance()

    subscript(_ part: Part) -> UInt32 {
        get {
            switch part {
            case .bandana: bandana
            case .spikes: spikes
            case .body: body
            case .belly: belly
            }
        }
        set {
            let rgb = newValue & 0xFFFFFF
            switch part {
            case .bandana: bandana = rgb
            case .spikes: spikes = rgb
            case .body: body = rgb
            case .belly: belly = rgb
            }
        }
    }
}
