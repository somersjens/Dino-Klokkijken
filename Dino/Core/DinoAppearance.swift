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

    /// Keep the original white ink except on genuinely pale or bright cloth.
    var usesBlackBandanaLettering: Bool {
        func linear(_ channel: UInt32) -> Double {
            let value = Double(channel & 255) / 255
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        let luminance = 0.2126 * linear(bandana >> 16)
            + 0.7152 * linear(bandana >> 8) + 0.0722 * linear(bandana)
        return luminance >= 0.70
    }

    /// Charcoal softens the print on pale cloth while retaining clear contrast.
    var bandanaLetteringHex: UInt32 { usesBlackBandanaLettering ? 0x3D3D3D : 0xFFFFFF }

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
