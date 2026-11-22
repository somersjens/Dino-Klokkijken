import Foundation

/// Stable identities reserve one collection slot per world. Only the jungle is playable so far.
enum DinoIdentity: Int, Codable, CaseIterable, Sendable {
    case main = 0, jungle, desert, volcano, village, cave, city, valley, machine, pirates, castle

    var isPlayable: Bool { self == .main || self == .jungle }
    var unlockLevel: Int { rawValue * 10 }
    var bossAsset: String {
        ["dino-idle", "boss-jungle", "boss-desert", "boss-volcano", "boss-clock-village",
         "boss-crystal-cave", "boss-clock-city", "boss-sleep-valley", "boss-time-machine", "boss-pirates", "boss-castle"][rawValue]
    }
}

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
    var character: DinoIdentity?
    var identity: DinoIdentity { character ?? .main }
    var mainAppearance: DinoAppearance {
        var copy = self
        copy.character = nil
        return copy
    }
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

/// The shared choreography addresses poses by their original names; each identity supplies its own artwork.
enum DinoJungleArtwork {
    static let assets: Set<String> = [
        "jungle-idle", "jungle-wrong", "jungle-clap-open", "jungle-clap-contact", "jungle-clap-open-2", "jungle-clap-contact-2",
        "jungle-crouch", "jungle-takeoff", "jungle-airborne", "jungle-landing", "jungle-recover", "jungle-stumble", "jungle-fallen", "jungle-push-up",
        "jungle-turn-01", "jungle-turn-02", "jungle-turn-03", "jungle-turn-04", "jungle-turn-05", "jungle-turn-06", "jungle-turn-07", "jungle-turn-08"
    ]
    static let portraitScale = 1.0 / 0.48
    static let portraitOffsetX = -0.04
    static let portraitOffsetY = 0.43
    static func asset(for pose: String) -> String {
        if pose.hasPrefix("jungle-") { return pose }
        if pose == "dino-answer-wrong" { return "jungle-wrong" }
        if pose.hasPrefix("dino-answer-clap-"), let index = Int(pose.suffix(2)) {
            return ["jungle-clap-open", "jungle-clap-contact", "jungle-clap-open-2", "jungle-clap-open-2",
                    "jungle-clap-contact-2", "jungle-idle"][min(5, max(0, index - 1))]
        }
        if pose.contains("pirouette"), let index = Int(pose.suffix(2)) {
            let frames = ["jungle-idle", "jungle-crouch", "jungle-turn-01", "jungle-turn-01", "jungle-turn-02",
                          "jungle-turn-03", "jungle-turn-04", "jungle-turn-05", "jungle-turn-05", "jungle-turn-06",
                          "jungle-turn-06", "jungle-turn-07", "jungle-turn-08", "jungle-turn-08", "jungle-landing",
                          "jungle-recover", "jungle-idle", "jungle-idle"]
            return frames[min(17, max(0, index - 1))]
        }
        if pose.contains("fall-"), let index = Int(pose.suffix(2)) {
            return index <= 3 ? "jungle-stumble" : index <= 7 ? "jungle-fallen" : index <= 9 ? "jungle-push-up" : "jungle-idle"
        }
        if pose.contains("crouch") { return "jungle-crouch" }
        if pose.contains("airborne") { return "jungle-airborne" }
        if pose.contains("takeoff") { return "jungle-takeoff" }
        if pose.contains("landing") { return "jungle-landing" }
        if pose.contains("recover") { return "jungle-recover" }
        if pose.hasPrefix("dino-opening-jump-"), let index = Int(pose.suffix(2)) {
            return ["jungle-idle", "jungle-crouch", "jungle-takeoff", "jungle-takeoff", "jungle-takeoff",
                    "jungle-landing", "jungle-landing", "jungle-recover"][min(7, max(0, index - 1))]
        }
        return "jungle-idle"
    }
}
