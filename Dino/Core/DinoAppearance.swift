import Foundation

/// Stable identities reserve one collection slot per world. Raw values follow chapter order, independently of theme and artwork IDs.
enum DinoIdentity: Int, Codable, CaseIterable, Sendable {
    case main = 0, jungle, desert, volcano, village, cave, city, valley, machine, pirates, castle

    var isPlayable: Bool { self == .main || self == .jungle || self == .desert }
    var usesBossArtwork: Bool { self == .jungle || self == .desert }
    var worldID: Int? { self == .main ? nil : rawValue }
    static func boss(in world: Int) -> DinoIdentity? {
        guard let identity = DinoIdentity(rawValue: world), identity != .main, identity.isPlayable else { return nil }
        return identity
    }
    func asset(for pose: String) -> String {
        switch self {
        case .jungle: return DinoJungleArtwork.asset(for: pose)
        case .desert: return DinoDesertArtwork.asset(for: pose)
        default: return pose
        }
    }
    var artworkAssets: Set<String> {
        self == .desert ? DinoDesertArtwork.assets : self == .jungle ? DinoJungleArtwork.assets : []
    }
    var openingAsset: String { self == .desert ? DinoDesertArtwork.openingAsset : DinoJungleArtwork.openingAsset }
    var portraitScale: Double { self == .desert ? 1.72 : self == .jungle ? DinoJungleArtwork.portraitScale : 1 / 0.62 }
    var portraitOffsetX: Double { self == .desert ? -0.28 : self == .jungle ? DinoJungleArtwork.portraitOffsetX : -0.065 }
    var portraitOffsetY: Double { self == .desert ? 0.22 : self == .jungle ? DinoJungleArtwork.portraitOffsetY : 0.339 }
    /// Visible sole boundary in each canonical source canvas, before mirroring.
    /// Collection residents stand on their own feet, independently of active art.
    var standingFootline: Double { self == .jungle ? 484.0 / 512 : 1211.0 / 1254 }
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
        func labelKey(for identity: DinoIdentity) -> String {
            identity == .desert ? "dino.appearance.desert.\(rawValue)" : labelKey
        }
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
    static func standard(for identity: DinoIdentity) -> DinoAppearance {
        if identity == .desert {
            return DinoAppearance(bandana: 0xF89B20, spikes: 0xB47B43, body: 0xE7B56D, belly: 0xF5DEAA, character: .desert)
        }
        var colors = standard
        colors.character = identity == .main ? nil : identity
        return colors
    }
    /// Preserve chosen channels while native/default channels follow the new
    /// identity. A blue skin choice does not turn untouched desert rocks green.
    func selecting(_ character: DinoIdentity) -> DinoAppearance {
        var copy = self
        let source = Self.standard(for: identity), target = Self.standard(for: character)
        for part in Part.allCases where self[part] == source[part] { copy[part] = target[part] }
        copy.character = character == .main ? nil : character
        return copy
    }
    var hasOriginalColors: Bool { mainAppearance == Self.standard(for: identity).mainAppearance }

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
    /// Dedicated detail restoration for the large launch composition.
    static let openingAsset = "jungle-opening-idle"
    static let assets: Set<String> = [
        "jungle-idle", "jungle-wrong", "jungle-clap-open", "jungle-clap-contact", "jungle-clap-open-2", "jungle-clap-contact-2",
        "jungle-crouch", "jungle-takeoff", "jungle-airborne", "jungle-landing", "jungle-recover", "jungle-stumble", "jungle-fallen", "jungle-push-up",
        "jungle-turn-01", "jungle-turn-02", "jungle-turn-03", "jungle-turn-04", "jungle-turn-05", "jungle-turn-06", "jungle-turn-07", "jungle-turn-08"
    ]
    static let portraitScale = 2.0
    static let portraitOffsetX = -0.09
    static let portraitOffsetY = 0.40
    /// Source-space head measurements shared by motion and portrait isolation.
    static func headLandmarks(for asset: String) -> [CGPoint] {
        let points: [(Double,Double)]
        switch self.asset(for:asset) {
        case "jungle-crouch": points = [(203.8,229.1),(145.4,234.9),(140,276)]
        case "jungle-takeoff": points = [(252.4,134.1),(199.7,127.6),(186,165)]
        case "jungle-landing": points = [(252.4,254.4),(175.4,256.9),(180,297)]
        case "jungle-recover": points = [(228.4,175.3),(167,176.7),(162,220)]
        default: points = [(260.8,155),(198.4,152.2),(187,204)]
        }
        return points.map { CGPoint(x:$0.0,y:$0.1) }
    }
    static func headRegistration(for pose: String) -> CGAffineTransform {
        let a = headLandmarks(for:"jungle-idle"), b = headLandmarks(for:pose)
        let origin = CGPoint(x:(a[0].x+a[1].x)/2,y:(a[0].y+a[1].y)/2)
        let target = CGPoint(x:(b[0].x+b[1].x)/2,y:(b[0].y+b[1].y)/2)
        let dx = a[1].x-a[0].x, dy = a[1].y-a[0].y
        let ex = b[1].x-b[0].x, ey = b[1].y-b[0].y
        let angle = atan2(ey,ex)-atan2(dy,dx), scale = hypot(ex,ey)/hypot(dx,dy)
        let c = cos(angle)*scale, q = sin(angle)*scale
        return CGAffineTransform(a:c,b:q,c:-q,d:c,tx:target.x-c*origin.x+q*origin.y,ty:target.y-q*origin.x-c*origin.y)
    }
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

/// Sandtail uses chapter 2 / theme 7. All measurements are normalized top-left
/// SOURCE coordinates before the single preparation mirror. No jungle geometry.
enum DinoDesertArtwork {
    static let openingAsset = "desert-opening-idle"
    static let assets: Set<String> = Set([
        "desert-idle", "desert-wrong", "desert-clap-open", "desert-clap-contact",
        "desert-clap-open-2", "desert-clap-contact-2", "desert-crouch", "desert-landing",
        "desert-takeoff", "desert-airborne", "desert-stumble", "desert-fallen", "desert-push-up"
    ] + (1...8).map { String(format: "desert-turn-%02d", $0) })
    /// Hip axes measured in the 443.5px source cells, before preparation mirror.
    static let turnAxes: [Double] = [229,233,249,226,194.5,210.5,214.5,229]
    static let headLandmarks = [CGPoint(x: 0.240039, y: 0.294063), CGPoint(x: 0.391133, y: 0.311426), CGPoint(x: 0.246768, y: 0.356904)]
    static func asset(for pose: String) -> String {
        if pose == "desert-recover" { return "desert-idle" }
        if pose.hasPrefix("desert-") { return pose }
        let semantic = DinoJungleArtwork.asset(for: pose).replacingOccurrences(of: "jungle-", with: "desert-")
        return semantic == "desert-recover" ? "desert-idle" : semantic
    }
}
