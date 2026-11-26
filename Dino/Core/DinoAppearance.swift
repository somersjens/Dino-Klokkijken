import Foundation
import CoreGraphics

/// Stable identities reserve one collection slot per world. Raw values follow chapter order, independently of theme and artwork IDs.
enum DinoIdentity: Int, Codable, CaseIterable, Sendable {
    case main = 0, jungle, desert, volcano, village, cave, city, valley, machine, pirates, castle

    var isPlayable: Bool { self == .main || usesBossArtwork }
    var usesBossArtwork: Bool {
        switch self {
        case .jungle, .desert, .volcano, .village, .cave, .city, .valley, .machine, .pirates, .castle: true
        default: false
        }
    }
    var worldID: Int? { self == .main ? nil : rawValue }
    static func boss(in world: Int) -> DinoIdentity? {
        guard let identity = DinoIdentity(rawValue: world), identity != .main, identity.isPlayable else { return nil }
        return identity
    }
    func asset(for pose: String) -> String {
        switch self {
        case .jungle: return DinoJungleArtwork.asset(for: pose)
        case .desert: return DinoDesertArtwork.asset(for: pose)
        case .volcano: return DinoVolcanoArtwork.asset(for: pose)
        case .village: return DinoVillageArtwork.asset(for: pose)
        case .cave: return DinoCaveArtwork.asset(for: pose)
        case .city: return DinoCityArtwork.asset(for: pose)
        case .valley: return DinoValleyArtwork.asset(for: pose)
        case .machine: return DinoMachineArtwork.asset(for: pose)
        case .pirates: return DinoPirateArtwork.asset(for: pose)
        case .castle: return DinoCastleArtwork.asset(for: pose)
        default: return pose
        }
    }
    var artworkAssets: Set<String> {
        switch self {
        case .jungle: DinoJungleArtwork.assets
        case .desert: DinoDesertArtwork.assets
        case .volcano: DinoVolcanoArtwork.assets
        case .village: DinoVillageArtwork.assets
        case .cave: DinoCaveArtwork.assets
        case .city: DinoCityArtwork.assets
        case .valley: DinoValleyArtwork.assets
        case .machine: DinoMachineArtwork.assets
        case .pirates: DinoPirateArtwork.assets
        case .castle: DinoCastleArtwork.assets
        default: []
        }
    }
    var openingAsset: String {
        switch self {
        case .volcano: DinoVolcanoArtwork.openingAsset
        case .desert: DinoDesertArtwork.openingAsset
        case .village: DinoVillageArtwork.openingAsset
        case .cave: DinoCaveArtwork.openingAsset
        case .city: DinoCityArtwork.openingAsset
        case .valley: DinoValleyArtwork.openingAsset
        case .machine: DinoMachineArtwork.openingAsset
        case .pirates: DinoPirateArtwork.openingAsset
        case .castle: DinoCastleArtwork.openingAsset
        default: DinoJungleArtwork.openingAsset
        }
    }
    private var portraitPlacement: (scale: Double, x: Double, y: Double) {
        switch self {
        case .volcano: (DinoVolcanoArtwork.portraitScale, DinoVolcanoArtwork.portraitOffsetX, DinoVolcanoArtwork.portraitOffsetY)
        case .desert: (1.72, -0.28, 0.22)
        case .jungle: (DinoJungleArtwork.portraitScale, DinoJungleArtwork.portraitOffsetX, DinoJungleArtwork.portraitOffsetY)
        case .village: DinoVillageArtwork.portraitPlacement
        case .cave: DinoCaveArtwork.portraitPlacement
        case .city: DinoCityArtwork.portraitPlacement
        case .valley: DinoValleyArtwork.portraitPlacement
        case .machine: DinoMachineArtwork.portraitPlacement
        case .pirates: DinoPirateArtwork.portraitPlacement
        case .castle: DinoCastleArtwork.portraitPlacement
        default: (1 / 0.62, -0.065, 0.339)
        }
    }
    var portraitScale: Double { portraitPlacement.scale }
    var portraitOffsetX: Double { portraitPlacement.x }
    var portraitOffsetY: Double { portraitPlacement.y }
    /// Visible sole boundary in each canonical source canvas, before mirroring.
    /// Collection residents stand on their own feet, independently of active art.
    var standingFootline: Double {
        switch self {
        case .volcano: DinoVolcanoArtwork.footline
        case .jungle: 484.0 / 512
        case .village: DinoVillageArtwork.footline
        case .cave: DinoCaveArtwork.footline
        case .city: DinoCityArtwork.footline
        case .valley: DinoValleyArtwork.footline
        case .machine: DinoMachineArtwork.footline
        case .pirates: DinoPirateArtwork.footline
        case .castle: DinoCastleArtwork.footline
        default: 1211.0 / 1254
        }
    }
    var usesPaintedFootline: Bool { self == .machine || self == .pirates || self == .castle }
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
            switch identity {
            case .volcano: "dino.appearance.volcano.\(rawValue)"
            case .desert: "dino.appearance.desert.\(rawValue)"
            case .village: "dino.appearance.village.\(rawValue)"
            case .cave: "dino.appearance.cave.\(rawValue)"
            case .city: "dino.appearance.city.\(rawValue)"
            case .valley: "dino.appearance.valley.\(rawValue)"
            case .machine: "dino.appearance.machine.\(rawValue)"
            case .pirates: "dino.appearance.pirates.\(rawValue)"
            case .castle: "dino.appearance.castle.\(rawValue)"
            default: labelKey
            }
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
        if identity == .castle {
            return DinoAppearance(bandana: 0xECA523, spikes: 0x163AB4, body: 0x2365AA,
                                  belly: 0xF8E2BE, character: .castle)
        }
        if identity == .machine {
            return DinoAppearance(bandana: 0x5751A5, spikes: 0xDEA1D9, body: 0xB673C5,
                                  belly: 0xF5DFB7, character: .machine)
        }
        if identity == .pirates {
            return DinoAppearance(bandana: 0xDE2928, spikes: 0xF5B632, body: 0x178FDB, belly: 0xEDE1C0, character: .pirates)
        }
        if identity == .valley {
            return DinoAppearance(bandana: 0xA478D7, spikes: 0xF7C46E, body: 0x78C4DF, belly: 0xF5E2BC, character: .valley)
        }
        if identity == .city {
            return DinoAppearance(bandana: 0xF5B739, spikes: 0xFFCE6C, body: 0x35A8B9, belly: 0xF8E3AD, character: .city)
        }
        if identity == .cave {
            return DinoAppearance(bandana: 0xEAA932, spikes: 0x29C9EE, body: 0x93AEBE, belly: 0xE6D5B7, character: .cave)
        }
        if identity == .village {
            return DinoAppearance(bandana: 0x277CC5, spikes: 0xAC6C37, body: 0xF2AB51, belly: 0xFBE5B4, character: .village)
        }
        if identity == .volcano {
            return DinoAppearance(bandana: 0xDB3526, spikes: 0xD93725, body: 0xFF783E, belly: 0xF8D99A, character: .volcano)
        }
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

/// Magma: chapter/theme/save identity 3. All geometry is in normalized,
/// top-left SOURCE coordinates. Preparation mirrors exactly once to face right.
enum DinoVolcanoArtwork {
    static let openingAsset = "volcano-opening-idle"
    static let portraitScale = 1.62
    /// Prepared (right-facing) bounds enclosing the complete frill and muzzle.
    static let portraitCrop = CGRect(x:0.20,y:0.02,width:0.66,height:0.53)
    static let portraitOffsetX = -0.13
    static let portraitOffsetY = 0.30
    static let footline = 477.0 / 512
    static let recoveryHeadCenters: [String:CGPoint] = [
        "volcano-push-up":CGPoint(x:180.45,y:269.2),"volcano-rise-low":CGPoint(x:194.85,y:251.65),
        "volcano-rise-high":CGPoint(x:204.35,y:211.55),"volcano-idle":CGPoint(x:207.05,y:169.85)
    ]
    static let recoveryEyeDistances: [Double] = [60.3,58.5,60.1,62.7]
    static let turnAxes: [Double] = [249,234,238,257,293,289,275,242]
    static let turnFootlines: [Double] = [478,478,476,476,478,480,479,479]
    static let clapContact = CGPoint(x:1-224.0/512,y:307.0/512)
    static let headLandmarks = [CGPoint(x:175.7/512,y:168.3/512),CGPoint(x:238.4/512,y:171.4/512),CGPoint(x:182.05/512,y:198.4/512)]
    static let assets: Set<String> = Set([
        "volcano-idle", "volcano-wrong", "volcano-clap-open", "volcano-clap-contact",
        "volcano-clap-open-2", "volcano-clap-contact-2", "volcano-crouch", "volcano-takeoff",
        "volcano-airborne", "volcano-landing", "volcano-stumble", "volcano-fallen", "volcano-push-up", "volcano-rise-low", "volcano-rise-high"
    ] + (1...8).map { String(format:"volcano-turn-%02d",$0) })
    static func asset(for pose: String) -> String {
        if pose == "volcano-recover" { return "volcano-idle" }
        if pose.hasPrefix("volcano-") { return pose }
        let semantic = DinoJungleArtwork.asset(for:pose).replacingOccurrences(of:"jungle-",with:"volcano-")
        return semantic == "volcano-recover" ? "volcano-idle" : semantic
    }
}

/// Burgemeester Tik-Tak. Source paintings face left, with a top-left origin.
/// The renderer mirrors the paintings and their registered features together.
enum DinoVillageArtwork {
    static let openingAsset = "village-opening-idle"
    static let footline = 466.0 / 512
    static let portraitPlacement = (scale: 1.66, x: -0.065, y: 0.236)
    static let portraitCrop = CGRect(x: 0.29, y: 0.026, width: 0.43, height: 0.46)
    static let clapContact = CGPoint(x: 0.555, y: 0.542)
    static let headLandmarks = [CGPoint(x: 201.0 / 512, y: 139.0 / 512), CGPoint(x: 267.0 / 512, y: 142.0 / 512),
                                CGPoint(x: 207.0 / 512, y: 171.0 / 512)]
    static let turnAssets = (1...7).map { String(format: "village-turn-%02d", $0) }
    static let assets: Set<String> = Set([
        "village-idle", "village-wrong", "village-clap-open", "village-clap-contact",
        "village-clap-release", "village-crouch", "village-airborne",
        "village-stumble", "village-fallen", "village-rise-low", "village-push-up", "village-rise-high"
    ] + turnAssets)

    static func asset(for pose: String) -> String {
        if pose == openingAsset || assets.contains(pose) { return pose }
        switch DinoJungleArtwork.asset(for: pose).dropFirst("jungle-".count) {
        case "clap-open": return "village-clap-open"
        case "clap-contact", "clap-contact-2": return "village-clap-contact"
        case "clap-open-2": return "village-clap-release"
        case "wrong": return "village-wrong"
        case "crouch", "landing": return "village-crouch"
        case "airborne", "takeoff": return "village-airborne"
        case "stumble": return "village-stumble"
        case "fallen": return "village-fallen"
        case "push-up": return "village-push-up"
        case let turn where turn.hasPrefix("turn-"):
            return turnAssets[min(turnAssets.count, max(1, Int(turn.suffix(2)) ?? 1)) - 1]
        default: return "village-idle"
        }
    }
}

/// Prisma. All landmarks are normalized top-left source coordinates.
/// The preparation renderer reflects the raster and landmarks once.
enum DinoCaveArtwork {
    static let openingAsset = "cave-opening-idle"
    static let footline = 472.0 / 512
    static let portraitPlacement = (scale: 1.80, x: -0.145, y: 0.262)
    static let portraitCrop = CGRect(x: 0.32, y: 0.060, width: 0.47, height: 0.47)
    static let headLandmarks = [CGPoint(x: 164.90 / 512, y: 178.26 / 512),
                                CGPoint(x: 220.38 / 512, y: 182.44 / 512),
                                CGPoint(x: 160.72 / 512, y: 207.52 / 512)]
    static let clapContact = CGPoint(x: 1 - 203.54 / 512, y: 286.76 / 512)
    static let turnAssets = (2...8).map { String(format: "cave-turn-%02d", $0) }
    /// Hip axes in the 512-pixel registered source, before reflecting.
    static let idleHipX = 226.46
    static let turnHipX = [245.93, 244.63, 246.54, 246.63, 246.59, 247.08, 245.47]
    static let assets: Set<String> = Set([
        "cave-idle", "cave-wrong", "cave-clap-open", "cave-clap-contact", "cave-clap-release",
        "cave-crouch", "cave-airborne", "cave-stumble", "cave-fallen", "cave-push-up", "cave-recover"
    ] + turnAssets)

    static func asset(for pose: String) -> String {
        if pose == openingAsset || assets.contains(pose) { return pose }
        switch DinoJungleArtwork.asset(for: pose).dropFirst("jungle-".count) {
        case "wrong": return "cave-wrong"
        case "clap-open": return "cave-clap-open"
        case "clap-contact", "clap-contact-2": return "cave-clap-contact"
        case "clap-open-2": return "cave-clap-release"
        case "crouch", "landing": return "cave-crouch"
        case "takeoff", "airborne": return "cave-airborne"
        case "stumble": return "cave-stumble"
        case "fallen": return "cave-fallen"
        case "push-up": return "cave-push-up"
        case "recover": return "cave-recover"
        case let turn where turn.hasPrefix("turn-") && assets.contains("cave-\(turn)"): return "cave-\(turn)"
        default: return "cave-idle"
        }
    }
}

/// Neon. The registered source faces left. Measurements are top-left source
/// pixels in the 512-pixel registration canvas, independent of raster resolution.
enum DinoCityArtwork {
    static let openingAsset = "city-opening-idle"
    static let footline = 1211.0 / 1254
    static let portraitPlacement = (scale: 2.16, x: -0.075, y: 0.165)
    static let portraitCrop = CGRect(x: 0.31, y: 0.205, width: 0.44, height: 0.44)
    // Palm seam, in the prepared right-facing canvas.
    static let clapContact = CGPoint(x: 1 - 230.0 / 512, y: 322.0 / 512)
    static let turnAssets = (2...8).map { String(format: "city-turn-%02d", $0) }
    static let assets: Set<String> = Set([
        "city-idle", "city-clap-open", "city-clap-contact", "city-wrong",
        "city-airborne", "city-crouch", "city-stumble", "city-fallen", "city-push-up"
    ] + turnAssets)

    static func asset(for pose: String) -> String {
        if pose == openingAsset || assets.contains(pose) { return pose }
        switch DinoJungleArtwork.asset(for: pose) {
        case "jungle-wrong": return "city-wrong"
        case "jungle-clap-open", "jungle-clap-open-2": return "city-clap-open"
        case "jungle-clap-contact", "jungle-clap-contact-2": return "city-clap-contact"
        case "jungle-crouch", "jungle-landing": return "city-crouch"
        case "jungle-takeoff", "jungle-airborne": return "city-airborne"
        case "jungle-stumble": return "city-stumble"
        case "jungle-fallen": return "city-fallen"
        case "jungle-push-up": return "city-push-up"
        case let turn where turn.hasPrefix("jungle-turn-") && turn != "jungle-turn-01":
            return "city-turn-\(turn.suffix(2))"
        default: return "city-idle"
        }
    }

    /// Far iris, near iris and nostril for the neutral welcome illustration.
    static let headLandmarks = [CGPoint(x: 195.0 / 512, y: 185.0 / 512),
                                CGPoint(x: 264.0 / 512, y: 194.0 / 512),
                                CGPoint(x: 219.0 / 512, y: 210.0 / 512)]
    /// Register the tuck's head to the standing flight. Its bent legs still
    /// lift away from the standing sole without raising the entire painting.
    static let tuckOffset = CGPoint(x: (244.0 - 229.5) / 512, y: (189.5 - 160.0) / 512)
    /// Midpoint between the two planted palms, reflected to screen coordinates.
    static let pushUpOffsetX = (197.5 - 203.0) / 512
}

/// Dommel's rig uses the top-left source canvas, before its one reflection.
enum DinoValleyArtwork {
    static let openingAsset = "valley-opening-idle"
    static let footline = 480.0 / 512
    static let portraitPlacement = (scale: 1.91, x: -0.34, y: 0.352)
    static let portraitCrop = CGRect(x: 0.385, y: 0.023, width: 0.47, height: 0.425)
    static let idle = "valley-idle"
    static let turnAssets = (1...7).map { String(format: "valley-turn-%02d", $0) }
    static let assets = Set([idle, "valley-clap-open", "valley-clap-contact", "valley-wrong",
                             "valley-crouch", "valley-airborne", "valley-stumble", "valley-push-up"] + turnAssets)
    static let headLandmarks = [CGPoint(x: 118.70 / 512, y: 141.81 / 512),
                                CGPoint(x: 182.92 / 512, y: 148.87 / 512),
                                CGPoint(x: 118.41 / 512, y: 164.95 / 512)]
    /// Seam between the front paws, in the prepared right-facing canvas.
    static let clapContact = CGPoint(x: 1 - 145.14 / 512, y: 252.91 / 512)

    static func asset(for pose: String) -> String {
        if pose == openingAsset || assets.contains(pose) { return pose }
        if pose == "dino-answer-wrong" { return "valley-wrong" }
        if let index = Int(pose.suffix(2)), pose.hasPrefix("dino-answer-clap-") {
            switch index {
            case 1, 3, 4, 6: return "valley-clap-open"
            case 2, 5: return "valley-clap-contact"
            default: break
            }
        }
        return idle
    }
}

/// King Chronos uses normalized top-left source coordinates. The preparation
/// renderer reflects all paintings once. Both idle resolutions share framing.
enum DinoCastleArtwork {
    static let idle = "castle-idle"
    static let openingAsset = "castle-opening-idle"
    static let footline = 592.0 / 627
    static let portraitPlacement = (scale: 1.68, x: -0.215, y: 0.245)
    static let portraitCrop = CGRect(x: 0.40, y: 0.015, width: 0.43, height: 0.51)
    static let headLandmarks = [CGPoint(x: 184.0 / 627, y: 191.0 / 627),
                                CGPoint(x: 265.0 / 627, y: 201.0 / 627),
                                CGPoint(x: 162.0 / 627, y: 225.0 / 627)]
    static let clapContact = CGPoint(x: 1 - (242 * 0.985 - 30) / 627, y: (346 * 0.985 - 7) / 627)
    static let turnAssets = ["castle-front", "castle-side-right", "castle-rear-right", "castle-back",
                             "castle-rear-left", "castle-side-left"]
    /// Hip locations after registration, in the 627-unit source grid.
    static let turnHips: [Double] = [269, 375, 387, 281, 250, 192]
    static let assets = Set([idle, "castle-clap-open", "castle-clap-contact", "castle-wrong",
                             "castle-brace", "castle-stumble", "castle-fallen", "castle-lift", "castle-recover"] + turnAssets)

    static func asset(for pose: String) -> String {
        if pose == openingAsset || assets.contains(pose) { return pose }
        if pose == "dino-answer-wrong" { return "castle-wrong" }
        if pose.hasPrefix("dino-answer-clap-"), let index = Int(pose.suffix(2)) {
            switch index {
            case 1, 3, 4, 6: return "castle-clap-open"
            case 2, 5: return "castle-clap-contact"
            default: break
            }
        }
        return idle
    }
}

/// Kapitein Zandloper. Top-left original pixel measurements, prior to the
/// preparation mirror. Poses use a registered 512px canvas.
enum DinoPirateArtwork {
    static let idle = "pirate-idle"
    static let openingAsset = "pirate-opening-idle"
    static let footline = 1189.0 / 1254
    static let portraitPlacement = (scale: 1.69, x: -0.105, y: 0.231)
    static let portraitCrop = CGRect(x: 0.22, y: 0.007, width: 0.54, height: 0.49)
    static let headLandmarks = [CGPoint(x: 488.0 / 1254, y: 346.0 / 1254),
                                CGPoint(x: 650.0 / 1254, y: 370.0 / 1254),
                                CGPoint(x: 504.0 / 1254, y: 428.0 / 1254)]
    static let clapContact = CGPoint(x: 1 - 231.91 / 512, y: 263.12 / 512)
    static let turnAssets = (1...6).map { String(format: "pirate-turn-%02d", $0) }
    static let assets = Set([idle, "pirate-clap-open", "pirate-clap-contact", "pirate-wrong",
                             "pirate-crouch", "pirate-airborne", "pirate-stumble", "pirate-fallen", "pirate-push-up"] + turnAssets)

    static func asset(for pose: String) -> String {
        if pose == openingAsset || assets.contains(pose) { return pose }
        if pose == "dino-answer-wrong" { return "pirate-wrong" }
        switch pose {
        case "dino-answer-clap-02", "dino-answer-clap-05": return "pirate-clap-contact"
        case "dino-answer-clap-01", "dino-answer-clap-03", "dino-answer-clap-04", "dino-answer-clap-06": return "pirate-clap-open"
        default: return idle
        }
    }
}

/// Pendel's landmarks use top-left source pixel centres, normalized to the
/// square painting. The renderer reflects that canvas once before display.
enum DinoMachineArtwork {
    static let idle = "machine-idle"
    static let openingAsset = "machine-opening-idle"
    static let footline = 1168.0 / 1254
    static let portraitPlacement = (scale: 1.61, x: -0.11, y: 0.183)
    static let portraitCrop = CGRect(x: 0.28, y: 0.027, width: 0.46, height: 0.49)
    static let headLandmarks = [CGPoint(x: 475.5 / 1254, y: 426.5 / 1254),
                                CGPoint(x: 630.5 / 1254, y: 451.5 / 1254),
                                CGPoint(x: 464.5 / 1254, y: 495.5 / 1254)]
    static let clapContact = CGPoint(x: 1 - 266.15 / 627, y: 352.70 / 627)
    static let turnAssets = ["machine-turn-side-left", "machine-turn-back-left", "machine-turn-back",
                             "machine-turn-back-right", "machine-turn-side-right", "machine-turn-front-right",
                             "machine-turn-front"]
    static let assets = Set([idle, "machine-clap-open", "machine-clap-contact", "machine-wrong",
                             "machine-crouch", "machine-airborne", "machine-brace"] + turnAssets)

    static func asset(for pose: String) -> String {
        if pose == openingAsset || assets.contains(pose) { return pose }
        if pose == "dino-answer-wrong" { return "machine-wrong" }
        if pose.hasPrefix("dino-answer-clap-"), let index = Int(pose.suffix(2)) {
            switch index {
            case 2, 5: return "machine-clap-contact"
            case 1, 3, 4, 6: return "machine-clap-open"
            default: break
            }
        }
        return idle
    }
}
