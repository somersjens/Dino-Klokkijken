import Foundation

/// Shared pose timing, with a fixed head during applause and smooth hand transitions.
enum DinoAnimation {
    enum Clip: String { case idle, thumbsUp, wrongAnswer, backflip, pirouette, worldJump }
    struct Pose {
        let asset: String
        var paintedAngle = 0.0
        var paintedYaw = 0.0
        var offsetX = 0.0
        var offsetY = 0.0
    }
    struct Sample {
        let pose: Pose
        var angle = 0.0
        var yaw = 0.0
        var height = 0.0
        var scaleX = 1.0
        var scaleY = 1.0
        var previousPose: Pose? = nil
        var poseBlend = 1.0
    }

    static let correctAnswerDelay = duration(.thumbsUp) + 0.12
    static let wrongAnswerAssets = [DinoAnswerArtwork.wrongAssets[1]]
    static let correctAnswerAssets = (1...8).map { String(format: "dino_applaus_frame_%02d", $0) }
    // Two claps, followed by the supplied recovery pose before returning to idle.
    // Keep every drawing visible at both 30 and 60 Hz without delaying the next question.
    static let correctAnswerFrameStarts = [0.0, 0.06, 0.14, 0.22, 0.30, 0.38, 0.46, 0.54]
    static let correctAnswerStillAsset = correctAnswerAssets[5]
    // The new drawings change facial proportions as well as head position. Keep
    // the idle head fixed and animate only the supplied hands, torso and accents.
    static let correctAnswerPoses = correctAnswerAssets.enumerated().map { index, asset in
        Pose(asset: asset, offsetY: index == 0 || index == 7 ? 0 : -0.025)
    }
    static let answerGestureStart = 0.08
    static let answerGestureEnd = 0.66
    struct TimedPose {
        let start: Double
        let pose: Pose
    }

    // Seconds after the result fade: read the crouch, launch quickly, let every
    // turn drawing register at a brisk pace, then let the planted recovery breathe.
    static let pirouetteTakeoff = 0.30
    static let pirouetteLanding = 0.965
    static let pirouetteFrames: [TimedPose] = [
        TimedPose(start: 0, pose: Pose(asset: "dino-pirouette-01", offsetX: -0.017, offsetY: -0.017)),
        TimedPose(start: 0.08, pose: Pose(asset: "dino-pirouette-02", offsetX: -0.036, offsetY: -0.018)),
        TimedPose(start: 0.22, pose: Pose(asset: "dino-pirouette-03", paintedYaw: 15, offsetX: -0.023, offsetY: -0.034)),
        TimedPose(start: pirouetteTakeoff, pose: Pose(asset: "dino-pirouette-04", paintedYaw: 30, offsetX: -0.033, offsetY: 0.018)),
        TimedPose(start: 0.36, pose: Pose(asset: "dino-pirouette-05", paintedYaw: 65, offsetX: -0.030, offsetY: 0.019)),
        TimedPose(start: 0.425, pose: Pose(asset: "dino-pirouette-06", paintedYaw: 100, offsetX: -0.051, offsetY: 0.012)),
        TimedPose(start: 0.50, pose: Pose(asset: "dino-pirouette-06a", paintedYaw: 140, offsetX: -0.090, offsetY: 0.006)),
        TimedPose(start: 0.575, pose: Pose(asset: "dino-pirouette-07", paintedYaw: 180, offsetX: -0.029)),
        TimedPose(start: 0.64, pose: Pose(asset: "dino-pirouette-07a", paintedYaw: 202.5, offsetX: -0.053, offsetY: -0.001)),
        TimedPose(start: 0.69, pose: Pose(asset: "dino-pirouette-08", paintedYaw: 225, offsetX: -0.046)),
        TimedPose(start: 0.74, pose: Pose(asset: "dino-pirouette-08a", paintedYaw: 247.5, offsetX: -0.021, offsetY: 0.009)),
        TimedPose(start: 0.79, pose: Pose(asset: "dino-pirouette-09", paintedYaw: 270, offsetX: -0.007, offsetY: 0.017)),
        TimedPose(start: 0.86, pose: Pose(asset: "dino-pirouette-10", paintedYaw: 310, offsetX: 0, offsetY: 0.004)),
        TimedPose(start: 0.915, pose: Pose(asset: "dino-pirouette-10a", paintedYaw: 325, offsetX: -0.041, offsetY: -0.014)),
        TimedPose(start: pirouetteLanding, pose: Pose(asset: "dino-pirouette-11", paintedYaw: 340, offsetX: -0.031, offsetY: -0.012)),
        TimedPose(start: pirouetteLanding + 0.13, pose: Pose(asset: "dino-pirouette-12", paintedYaw: 350, offsetX: -0.019, offsetY: -0.022)),
        TimedPose(start: pirouetteLanding + 0.28, pose: Pose(asset: "dino-pirouette-13", paintedYaw: 360, offsetX: -0.012, offsetY: -0.031)),
        TimedPose(start: pirouetteLanding + 0.45, pose: Pose(asset: "dino-pirouette-14", paintedYaw: 360, offsetX: -0.012, offsetY: -0.029))
    ]
    static let pirouetteAssets = pirouetteFrames.map { $0.pose.asset }
    // Prepare answer reactions first so even a quick first answer finds warm bitmaps.
    static let spriteAssets = ["dino-idle"] + correctAnswerAssets + wrongAnswerAssets
        + ["dino-thumbs-up-08", "dino-wrong-answer-04",
                               "dino-backflip-01", "dino-backflip-03", "dino-backflip-07", "dino-backflip-08"]
        + pirouetteAssets
    static let worldJumpAssets = [1, 2, 3, 6, 7].map { String(format: "dino-world-jump-%02d", $0) }

    /// The short lead-in matches the result screen's fade.
    static func leadIn(_ clip: Clip) -> Double { clip == .pirouette ? 0.24 : 0 }

    /// Show the anticipation in the portrait before Dino leaves the circle.
    static func travelDelay(_ clip: Clip) -> Double {
        switch clip {
        case .pirouette: leadIn(clip) + pirouetteTakeoff
        case .backflip, .worldJump: 0.18
        default: 0
        }
    }

    /// The shared companion reaches the rock before the reward stars appear.
    static func travelDuration(_ clip: Clip) -> Double {
        switch clip {
        case .backflip, .worldJump: 1.22
        case .pirouette: leadIn(clip) + pirouetteLanding
        default: 0.42
        }
    }
    static func duration(_ clip: Clip) -> Double {
        switch clip {
        case .idle: 0
        case .thumbsUp: 0.70
        case .wrongAnswer: 0.80
        case .backflip, .worldJump: 1.62
        case .pirouette: leadIn(clip) + pirouetteFrames.last!.start
        }
    }

    /// The map camera and the character share the result salto's takeoff and landing.
    static func worldJumpProgress(elapsed: Double) -> Double {
        let delay = travelDelay(.worldJump)
        return smooth((elapsed - delay) / (travelDuration(.worldJump) - delay))
    }

    static func sample(_ clip: Clip, elapsed: Double, reducedMotion: Bool = false) -> Sample {
        let t = max(0, elapsed - leadIn(clip))
        switch clip {
        case .idle:
            return Sample(pose: Pose(asset: "dino-idle"))
        case .thumbsUp:
            guard !reducedMotion else { return Sample(pose: correctAnswerPoses[5]) }
            guard t < duration(.thumbsUp) else { return sample(.idle, elapsed: 0) }
            let index = correctAnswerFrameStarts.lastIndex { t >= $0 } ?? 0
            // Blend only the moving hands for two refreshes; the head never
            // fades or changes shape. Every authored pose still has a clear hold.
            return Sample(pose: correctAnswerPoses[index],
                          previousPose: index > 0 ? correctAnswerPoses[index - 1] : nil,
                          poseBlend: smooth((t - correctAnswerFrameStarts[index]) / 0.035))
        case .wrongAnswer:
            return wrongAnswerSample(elapsed: t, reducedMotion: reducedMotion)
        case .pirouette:
            let finalPose = pirouetteFrames.last!.pose
            guard !reducedMotion else {
                // The turn is already painted into the final image; no 3D transform is needed.
                return Sample(pose: Pose(asset: finalPose.asset, offsetX: finalPose.offsetX, offsetY: finalPose.offsetY))
            }
            let takeoff = pirouetteTakeoff, landing = pirouetteLanding
            // Compare absolute times so a subtraction rounding error cannot
            // postpone a painted contact pose past the shared journey's landing.
            let index = pirouetteFrames.lastIndex { elapsed >= leadIn(.pirouette) + $0.start } ?? 0
            let pose = pirouetteFrames[index].pose
            let yaw = pirouetteYaw(at: t, frame: index)
            let flight = min(max((t - takeoff) / (landing - takeoff), 0), 1)
            let height = -0.32 * pow(sin(.pi * flight), 1.2)
            // The drawings now carry the crouch and recovery. Keep only a little
            // spring in the landing so the planted feet remain on the same line.
            let landingSquash = 0.025 * pulse(t, start: landing, end: landing + 0.28)
            let squash = 0.025 * pulse(t, start: 0.08, end: takeoff) + landingSquash
            return Sample(pose: pose, yaw: yaw, height: height, scaleX: 1 + squash * 0.35, scaleY: 1 - squash)
        case .worldJump:
            guard !reducedMotion else { return Sample(pose: Pose(asset: "dino-idle")) }
            let pose: Pose
            // Match the opaque foot line of each supplied drawing to idle (y = 1211).
            // The landing and recovery must stay planted while the poses change.
            if t < 0.08 {
                pose = Pose(asset: "dino-world-jump-01", offsetY: -2.0 / 1254)
            } else if t < 0.20 {
                pose = Pose(asset: "dino-world-jump-02", offsetY: 22.0 / 1254)
            } else if t < 1.10 {
                // One tucked drawing carries the complete continuous rotation.
                pose = Pose(asset: "dino-world-jump-03", offsetY: 0.045)
            } else if t < 1.22 {
                pose = Pose(asset: "dino-world-jump-06", offsetY: 70.0 / 1254)
            } else if t < 1.44 {
                pose = Pose(asset: "dino-world-jump-07", offsetY: 64.0 / 1254)
            } else if t < duration(.worldJump) {
                pose = Pose(asset: "dino-world-jump-01", offsetY: -2.0 / 1254)
            } else {
                pose = Pose(asset: "dino-idle")
            }
            let flight = min(max((t - 0.18) / 1.04, 0), 1)
            let angle = 360 * smooth((t - 0.24) / 0.86)
            let height = -0.34 * pow(sin(.pi * flight), 1.2)
            let squash = 0.07 * pulse(t, start: 0.02, end: 0.20) + 0.10 * pulse(t, start: 1.22, end: 1.44)
            return Sample(pose: pose, angle: angle, height: height, scaleX: 1 + squash * 0.4, scaleY: 1 - squash)
        case .backflip:
            let finalPose = Pose(asset: "dino-backflip-08", offsetX: -0.013, offsetY: -0.009)
            guard !reducedMotion else { return Sample(pose: finalPose) }
            let pose: Pose
            if t < 0.20 {
                pose = Pose(asset: "dino-backflip-01", offsetX: -0.024, offsetY: 0.016)
            } else if t < 1.22 {
                // Keep a single tucked pose for the entire rotation: no airborne sprite changes.
                pose = Pose(asset: "dino-backflip-03", paintedAngle: -45, offsetX: -0.017, offsetY: 0.069)
            } else if t < 1.44 {
                pose = Pose(asset: "dino-backflip-07", offsetX: -0.015, offsetY: 0.023)
            } else {
                pose = finalPose
            }
            let flight = min(max((t - 0.18) / 1.06, 0), 1)
            let angle = -360 * smooth((t - 0.27) / 0.94)
            let height = -0.34 * pow(sin(.pi * flight), 1.2)
            let squash = 0.07 * pulse(t, start: 0.02, end: 0.20) + 0.10 * pulse(t, start: 1.24, end: 1.44)
            return Sample(pose: pose, angle: angle, height: height, scaleX: 1 + squash * 0.4, scaleY: 1 - squash)
        }
    }

    private static func wrongAnswerSample(elapsed t: Double, reducedMotion: Bool) -> Sample {
        // Register the head against idle; the camera and portrait rim stay fixed.
        let expression = Pose(asset: wrongAnswerAssets[0], offsetX: -14.0 / 1254)
        guard !reducedMotion else { return Sample(pose: expression) }
        guard t < duration(.wrongAnswer) else { return sample(.idle, elapsed: 0) }
        let p = min(1, max(0, (t - answerGestureStart) / (answerGestureEnd - answerGestureStart)))
        let arc = sin(.pi * p)
        let pose = t >= answerGestureStart && t < answerGestureEnd ? expression : Pose(asset: "dino-idle")
        // One gentle left/right shake around the neck. The sine envelope gives
        // both ends zero velocity instead of stopping or reversing abruptly.
        return Sample(pose: pose, angle: -3.2 * sin(2 * .pi * p) * arc * arc,
                      height: 0.004 * arc * arc)
    }

    // Each switch occurs halfway between the adjacent painted angles. A
    // monotone cubic joins those angles with continuous speed, so retiming a
    // drawing never makes the small 3D correction stop, reverse or overshoot.
    private static let pirouetteYawStops = [0.0] + zip(pirouetteFrames, pirouetteFrames.dropFirst()).map {
        ($0.pose.paintedYaw + $1.pose.paintedYaw) / 2
    }
    private static let pirouetteYawSpeeds = pirouetteFrames.indices.map { index -> Double in
        guard index > 0, index < pirouetteFrames.count - 1 else { return 0 }
        let before = (pirouetteYawStops[index] - pirouetteYawStops[index - 1])
            / (pirouetteFrames[index].start - pirouetteFrames[index - 1].start)
        let after = (pirouetteYawStops[index + 1] - pirouetteYawStops[index])
            / (pirouetteFrames[index + 1].start - pirouetteFrames[index].start)
        return before > 0 && after > 0 ? 2 * before * after / (before + after) : 0
    }
    private static func pirouetteYaw(at time: Double, frame index: Int) -> Double {
        guard index < pirouetteFrames.count - 1 else { return 360 }
        let span = pirouetteFrames[index + 1].start - pirouetteFrames[index].start
        let p = min(1, max(0, (time - pirouetteFrames[index].start) / span))
        let p2 = p * p, p3 = p2 * p
        return (2 * p3 - 3 * p2 + 1) * pirouetteYawStops[index]
            + (p3 - 2 * p2 + p) * span * pirouetteYawSpeeds[index]
            + (-2 * p3 + 3 * p2) * pirouetteYawStops[index + 1]
            + (p3 - p2) * span * pirouetteYawSpeeds[index + 1]
    }

    private static func smooth(_ value: Double) -> Double {
        let p = min(max(value, 0), 1)
        return p * p * (3 - 2 * p)
    }
    private static func pulse(_ t: Double, start: Double, end: Double) -> Double {
        guard t > start, t < end else { return 0 }
        return sin(.pi * (t - start) / (end - start))
    }
}

/// A straight jump from the opening logo, using the artist's complete eight-pose
/// sequence. Crouch and recovery stay planted; only the flight travels to the map.
enum DinoOpeningJump {
    static let assets = (1...8).map { String(format: "dino-opening-jump-%02d", $0) }
    static let takeoff = 0.14
    static let landing = 0.76
    static let duration = 0.94
    static let poseStarts = [0, 0.035, takeoff, 0.23, 0.40, 0.56, landing, 0.86]

    static func flightProgress(elapsed: Double) -> Double {
        min(1, max(0, (elapsed - takeoff) / (landing - takeoff)))
    }
    static func travelProgress(elapsed: Double) -> Double {
        // A jump keeps its momentum until contact. Easing both ends made the
        // launch float away and put the brakes on before the feet hit the rock.
        flightProgress(elapsed: elapsed)
    }
    static func sample(elapsed: Double, reducedMotion: Bool = false) -> DinoAnimation.Sample {
        guard !reducedMotion else { return DinoAnimation.sample(.idle, elapsed: 0) }
        guard elapsed < duration else { return DinoAnimation.sample(.idle, elapsed: 0) }
        let index = poseStarts.lastIndex(where: { elapsed >= $0 }) ?? 0
        // Register planted and reaching feet. The bent airborne feet remain
        // free to rise instead of being dragged down to the ground.
        let registration = [-1.0, 3.0, 0.0, 0.0, 0.0, 46.0, 9.0, -2.0][index] / 1254
        let t = flightProgress(elapsed: elapsed)
        let recovery = min(1, max(0, (elapsed - landing) / (duration - landing)))
        // The drawings supply the big crouch. A brief, damped compression gives
        // the contact weight without holding Dino in a slow landing pose.
        let settle = elapsed >= landing ? 0.05 * sin(recovery * .pi) * (1 - recovery) : 0
        return DinoAnimation.Sample(pose: .init(asset: assets[index], offsetY: registration),
            angle: -5 * sin(.pi * t), height: -4 * t * (1 - t),
            scaleX: 1 + settle * 0.4, scaleY: 1 - settle)
    }
}

struct DinoWorldTransition: Equatable {
    let sourceLevel: Int
    let destinationLevel: Int

    init?(after worldID: Int) {
        guard let source = DinoWorldCatalog.world(worldID),
              let destination = DinoWorldCatalog.world(worldID + 1) else { return nil }
        sourceLevel = source.bossLevel
        destinationLevel = destination.firstLevel
    }
}

/// Continuous patrols with a short detour, a few pickaxe strokes and a return
/// to the same shoulder. Distances are route coordinates, independent of width.
struct CrystalMinerPatrol: Identifiable {
    let id: Int
    let right: Bool
    let stops: [Double]
    let speed: Double
    let phaseOffset: Double

    struct Pose {
        var y: Double
        var outward: Double = 0
        var walking = false
        var upward = false
        var work: Double? = nil
    }

    static let routes = [
        CrystalMinerPatrol(id: 0, right: false, stops: [180, 465, 860, 1440], speed: 19, phaseOffset: 0),
        CrystalMinerPatrol(id: 1, right: true, stops: [200, 505, 980, 1480], speed: 18, phaseOffset: 59),
        CrystalMinerPatrol(id: 2, right: false, stops: [725, 835], speed: 15, phaseOffset: 11),
        CrystalMinerPatrol(id: 3, right: true, stops: [1060, 1210], speed: 15, phaseOffset: 27)
    ]

    private var indices: [Int] { Array(stops.indices) + Array(stops.indices.dropLast().reversed()) }
    var duration: Double { 2 * (stops.last! - stops.first!) / speed + Double((stops.count - 1) * 2) * 8.8 }

    func pose(at time: TimeInterval) -> Pose {
        var t = (time + phaseOffset).truncatingRemainder(dividingBy: duration)
        if t < 0 { t += duration }
        func ease(_ x: Double) -> Double { x * x * (3 - 2 * x) }
        for pair in zip(indices, indices.dropFirst()) {
            let a = stops[pair.0], b = stops[pair.1]
            let travel = abs(b - a) / speed
            if t < travel {
                return Pose(y: a + (b - a) * t / travel, walking: true, upward: b < a)
            }
            t -= travel
            if t < 2 { return Pose(y: b, outward: ease(t / 2), walking: true, upward: b < a) }
            t -= 2
            if t < 4.8 { return Pose(y: b, outward: 1, upward: b < a, work: t) }
            t -= 4.8
            if t < 2 { return Pose(y: b, outward: 1 - ease(t / 2), walking: true, upward: b < a) }
            t -= 2
        }
        return Pose(y: stops[0], walking: true)
    }
}
