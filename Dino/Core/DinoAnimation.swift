import Foundation
import CoreGraphics

/// Shared pose timing, with two readable claps and continuous, subtle head motion.
enum DinoAnimation {
    enum Clip: String { case idle, thumbsUp, wrongAnswer, stumble, openingJump, backflip, pirouette, worldJump }
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
        var headAngle = 0.0
        var headHeight = 0.0
        var morph: DinoStumbleMotion.Blend? = nil
    }

    static let correctAnswerDelay = duration(.thumbsUp) + 0.12
    static let wrongAnswerAssets = [DinoAnswerArtwork.wrongAsset]
    static let correctAnswerAssets = DinoAnswerArtwork.clapAssets + [DinoAnswerArtwork.clapAssets[0]]
    // Two claps, followed by the supplied recovery pose before returning to idle.
    // Give each contact and reopening time to read as a separate clap.
    static let correctAnswerFrameStarts = [0.0, 0.12, 0.24, 0.36, 0.52, 0.64, 0.76, 0.92]
    static let correctAnswerBlendDuration = 0.055
    static let correctAnswerClapContacts = [2, 5].map { correctAnswerFrameStarts[$0] + correctAnswerBlendDuration }
    static let correctAnswerStillAsset = correctAnswerAssets[5]
    // The new drawings change facial proportions as well as head position. Keep
    // one consistent head drawing and move it continuously around the neck.
    static let correctAnswerPoses = correctAnswerAssets.enumerated().map { index, asset in
        Pose(asset: asset, offsetY: index == 0 || index == 7 ? 0 : -0.025)
    }
    static let answerGestureStart = 0.08
    static let answerGestureEnd = 0.66
    struct TimedPose {
        let start: Double
        let pose: Pose
    }

    // Lose balance in the portrait, fall onto both hands, then push back up.
    // Register the actual opaque soles/palms to idle's foot line (1211/1254).
    static let stumbleTakeoff = 0.12
    static let stumbleLanding = 0.64
    static let stumbleFaceContact = 0.72
    static let stumbleLowest = 0.82
    static let stumblePushStart = 1.12
    // Keep the impact and rest intact, then rise in one brisk half-second effort.
    static let stumbleBraceEnd = 1.19
    static let stumbleHandRelease = 1.38
    static let stumbleFrames = DinoStumbleMotion.frames
    static let stumbleAssets = (2...10).map { String(format: "dino-result-fall-%02d", $0) }

    // Seconds after the result fade: read the crouch, launch quickly, let every
    // turn drawing register at a brisk pace, then let the planted recovery breathe.
    static let pirouetteTakeoff = 0.30
    static let pirouetteLanding = 0.965
    static let pirouetteFrames: [TimedPose] = [
        TimedPose(start: 0, pose: Pose(asset: "dino-result-pirouette-01", offsetX: -0.017, offsetY: -0.017)),
        TimedPose(start: 0.08, pose: Pose(asset: "dino-result-pirouette-02", offsetX: -0.036, offsetY: -0.018)),
        TimedPose(start: 0.22, pose: Pose(asset: "dino-result-pirouette-03", paintedYaw: 15, offsetX: -0.023, offsetY: -0.034)),
        TimedPose(start: pirouetteTakeoff, pose: Pose(asset: "dino-result-pirouette-04", paintedYaw: 30, offsetX: -0.033, offsetY: 0.018)),
        TimedPose(start: 0.36, pose: Pose(asset: "dino-result-pirouette-05", paintedYaw: 65, offsetX: -0.030, offsetY: 0.019)),
        TimedPose(start: 0.425, pose: Pose(asset: "dino-result-pirouette-06", paintedYaw: 100, offsetX: -0.051, offsetY: 0.012)),
        TimedPose(start: 0.50, pose: Pose(asset: "dino-result-pirouette-07", paintedYaw: 140, offsetX: -0.090, offsetY: 0.006)),
        TimedPose(start: 0.575, pose: Pose(asset: "dino-result-pirouette-08", paintedYaw: 180, offsetX: -0.029)),
        TimedPose(start: 0.64, pose: Pose(asset: "dino-result-pirouette-09", paintedYaw: 202.5, offsetX: -0.053, offsetY: -0.001)),
        TimedPose(start: 0.69, pose: Pose(asset: "dino-result-pirouette-10", paintedYaw: 225, offsetX: -0.046)),
        TimedPose(start: 0.74, pose: Pose(asset: "dino-result-pirouette-11", paintedYaw: 247.5, offsetX: -0.021, offsetY: 0.009)),
        TimedPose(start: 0.79, pose: Pose(asset: "dino-result-pirouette-12", paintedYaw: 270, offsetX: -0.007, offsetY: 0.017)),
        TimedPose(start: 0.86, pose: Pose(asset: "dino-result-pirouette-13", paintedYaw: 310, offsetX: 0, offsetY: 0.004)),
        TimedPose(start: 0.915, pose: Pose(asset: "dino-result-pirouette-14", paintedYaw: 325, offsetX: -0.041, offsetY: -0.014)),
        TimedPose(start: pirouetteLanding, pose: Pose(asset: "dino-result-pirouette-15", paintedYaw: 340, offsetX: -0.031, offsetY: -0.012)),
        TimedPose(start: pirouetteLanding + 0.13, pose: Pose(asset: "dino-result-pirouette-16", paintedYaw: 350, offsetX: -0.019, offsetY: -0.022)),
        TimedPose(start: pirouetteLanding + 0.28, pose: Pose(asset: "dino-result-pirouette-17", paintedYaw: 360, offsetX: -0.012, offsetY: -0.031)),
        TimedPose(start: pirouetteLanding + 0.45, pose: Pose(asset: "dino-result-pirouette-18", paintedYaw: 360, offsetX: -0.012, offsetY: -0.029))
    ]
    static let pirouetteAssets = pirouetteFrames.map { $0.pose.asset }
    // Prepare answer reactions first so even a quick first answer finds warm bitmaps.
    static let spriteAssets = ["dino-idle"] + correctAnswerAssets + wrongAnswerAssets
        + ["dino-result-backflip-crouch", "dino-result-backflip-airborne", "dino-result-backflip-landing", "dino-result-backflip-recover"]
        + pirouetteAssets + DinoOpeningJump.assets + stumbleAssets
    static let worldJumpAssets = ["crouch", "takeoff", "airborne", "landing", "recover"].map { "dino-world-jump-" + $0 }

    /// The short lead-in matches the result screen's fade.
    static func leadIn(_ clip: Clip) -> Double {
        clip == .pirouette || clip == .openingJump || clip == .stumble ? 0.24 : 0
    }

    /// Show the anticipation in the portrait before Dino leaves the circle.
    static func travelDelay(_ clip: Clip) -> Double {
        switch clip {
        case .stumble: leadIn(clip) + stumbleTakeoff
        case .openingJump: leadIn(clip) + DinoOpeningJump.takeoff
        case .pirouette: leadIn(clip) + pirouetteTakeoff
        case .backflip, .worldJump: 0.18
        default: 0
        }
    }

    /// The shared companion reaches the rock before the reward stars appear.
    static func travelDuration(_ clip: Clip) -> Double {
        switch clip {
        case .stumble: leadIn(clip) + stumbleLanding
        case .openingJump: leadIn(clip) + DinoOpeningJump.landing
        case .backflip, .worldJump: 1.22
        case .pirouette: leadIn(clip) + pirouetteLanding
        default: 0.42
        }
    }
    static func duration(_ clip: Clip) -> Double {
        switch clip {
        case .idle: 0
        case .thumbsUp: 1.04
        case .wrongAnswer: 0.80
        case .stumble: leadIn(clip) + stumbleFrames.last!.start
        case .openingJump: leadIn(clip) + DinoOpeningJump.duration
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
            // One soft nod per palm contact, with zero speed at both ends.
            // The portrait and torso stay anchored while only the head responds.
            let nod = correctAnswerClapContacts.reduce(0.0) { total, contact in
                let distance = abs(t - contact) / 0.17
                return total + (distance < 1 ? (1 + cos(.pi * distance)) / 2 : 0)
            }
            return Sample(pose: correctAnswerPoses[index],
                          previousPose: index > 0 ? correctAnswerPoses[index - 1] : nil,
                          poseBlend: smooth((t - correctAnswerFrameStarts[index]) / correctAnswerBlendDuration),
                          headAngle: 1.8 * nod, headHeight: 0.006 * nod)
        case .wrongAnswer:
            return wrongAnswerSample(elapsed: t, reducedMotion: reducedMotion)
        case .stumble:
            guard !reducedMotion else { return Sample(pose: stumbleFrames.last!.pose) }
            // Keep the exact portrait bitmap and registration until he actually
            // leaves the circle. The almost-idle fall drawing has a different face.
            guard elapsed >= travelDelay(.stumble) else { return sample(.idle, elapsed: 0) }
            let morph = DinoStumbleMotion.sample(at: t)
            let pose = morph?.drawing ?? stumbleFrames.last!.pose
            let fall = min(1, max(0, (t - stumbleTakeoff) / (stumbleLanding - stumbleTakeoff)))
            return Sample(pose: pose, angle: elapsed > travelDelay(.stumble) && elapsed < travelDuration(.stumble) ? 3 * sin(.pi * fall) : 0, morph: morph)

        case .openingJump:
            var sample = DinoOpeningJump.sample(elapsed: elapsed, reducedMotion: reducedMotion, leadIn: leadIn(clip))
            // Reuse the logo's complete choreography with a smaller arc: the
            // result journey starts near the top edge in the player's portrait.
            sample.height *= 0.28
            return sample
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
                pose = Pose(asset: "dino-world-jump-crouch", offsetY: -2.0 / 1254)
            } else if t < 0.20 {
                pose = Pose(asset: "dino-world-jump-takeoff", offsetY: 22.0 / 1254)
            } else if t < 1.10 {
                // One tucked drawing carries the complete continuous rotation.
                pose = Pose(asset: "dino-world-jump-airborne", offsetY: 0.045)
            } else if t < 1.22 {
                pose = Pose(asset: "dino-world-jump-landing", offsetY: 70.0 / 1254)
            } else if t < 1.44 {
                pose = Pose(asset: "dino-world-jump-recover", offsetY: 64.0 / 1254)
            } else if t < duration(.worldJump) {
                pose = Pose(asset: "dino-world-jump-crouch", offsetY: -2.0 / 1254)
            } else {
                pose = Pose(asset: "dino-idle")
            }
            let flight = min(max((t - 0.18) / 1.04, 0), 1)
            let angle = 360 * smooth((t - 0.24) / 0.86)
            let height = -0.34 * pow(sin(.pi * flight), 1.2)
            let squash = 0.07 * pulse(t, start: 0.02, end: 0.20) + 0.10 * pulse(t, start: 1.22, end: 1.44)
            return Sample(pose: pose, angle: angle, height: height, scaleX: 1 + squash * 0.4, scaleY: 1 - squash)
        case .backflip:
            let finalPose = Pose(asset: "dino-result-backflip-recover", offsetX: -0.013, offsetY: -0.009)
            guard !reducedMotion else { return Sample(pose: finalPose) }
            let pose: Pose
            if t < 0.20 {
                pose = Pose(asset: "dino-result-backflip-crouch", offsetX: -0.024, offsetY: 0.016)
            } else if t < 1.22 {
                // Keep a single tucked pose for the entire rotation: no airborne sprite changes.
                pose = Pose(asset: "dino-result-backflip-airborne", paintedAngle: -45, offsetX: -0.017, offsetY: 0.069)
            } else if t < 1.44 {
                pose = Pose(asset: "dino-result-backflip-landing", offsetX: -0.015, offsetY: 0.023)
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
    // Hold the finished logo pose a little longer, then spend only 50 ms
    // in the deep crouch so the launch does not pause at its lowest point.
    static let poseStarts = [0, 0.09, takeoff, 0.23, 0.40, 0.56, landing, 0.86]
    static func flightProgress(elapsed: Double) -> Double {
        min(1, max(0, (elapsed - takeoff) / (landing - takeoff)))
    }
    static func travelProgress(elapsed: Double) -> Double {
        // A jump keeps its momentum until contact. Easing both ends made the
        // launch float away and put the brakes on before the feet hit the rock.
        flightProgress(elapsed: elapsed)
    }
    static func sample(elapsed: Double, reducedMotion: Bool = false, leadIn: Double = 0) -> DinoAnimation.Sample {
        guard !reducedMotion else { return DinoAnimation.sample(.idle, elapsed: 0) }
        guard elapsed < leadIn + duration else { return DinoAnimation.sample(.idle, elapsed: 0) }
        // Compare absolute boundaries so result-screen lead-in rounding cannot
        // postpone the contact drawing until after the journey reaches the rock.
        let index = poseStarts.lastIndex(where: { elapsed >= leadIn + $0 }) ?? 0
        let t = max(0, elapsed - leadIn)
        // Register planted and reaching feet. The bent airborne feet remain
        // free to rise instead of being dragged down to the ground.
        let registration = [-1.0, 3.0, 0.0, 0.0, 0.0, 46.0, 9.0, -2.0][index] / 1254
        let flight = flightProgress(elapsed: t)
        let recovery = min(1, max(0, (t - landing) / (duration - landing)))
        // The drawings supply the big crouch. A brief, damped compression gives
        // the contact weight without holding Dino in a slow landing pose.
        let settle = elapsed >= leadIn + landing ? 0.05 * sin(recovery * .pi) * (1 - recovery) : 0
        return DinoAnimation.Sample(pose: .init(asset: assets[index], offsetY: registration),
            angle: -5 * sin(.pi * flight), height: -4 * flight * (1 - flight),
            scaleX: 1 + settle * 0.4, scaleY: 1 - settle)
    }
}

/// Track the painted face through a readable bend and push-off. Source drawings
/// register to the same eyes and nostrils before changing; no duplicate idle
/// drawing or extra generated frame interrupts the movement.
enum DinoWelcomeJump {
    static let crouchBottom = 0.28
    // A slightly shorter push-off adds snap; the screen-space velocity match
    // below still carries that impulse smoothly into the unchanged flight.
    static let takeoff = 0.56
    static let flightHandoff = takeoff + 0.10
    static let landing = takeoff + DinoOpeningJump.landing - DinoOpeningJump.takeoff
    static let duration = landing + DinoOpeningJump.duration - DinoOpeningJump.landing
    static let poseStarts = [0, crouchBottom / 2, (crouchBottom + takeoff) / 2, landing, landing + 0.10]
    static let assets = ["dino-idle", "dino-opening-jump-02", "dino-opening-jump-03",
                         "dino-opening-jump-07", "dino-opening-jump-08"]

    struct Head {
        let leftEye: CGPoint
        let rightEye: CGPoint
        let nose: CGPoint
        var center: CGPoint { CGPoint(x: (leftEye.x + rightEye.x) / 2, y: (leftEye.y + rightEye.y) / 2) }

        init(_ left: CGPoint, _ right: CGPoint, _ nose: CGPoint) {
            leftEye = left; rightEye = right; self.nose = nose
        }

        init(pixels left: (Double, Double), _ right: (Double, Double), _ nose: (Double, Double)) {
            self.init(CGPoint(x: left.0 / 1254, y: left.1 / 1254),
                      CGPoint(x: right.0 / 1254, y: right.1 / 1254),
                      CGPoint(x: nose.0 / 1254, y: nose.1 / 1254))
        }

        func applying(_ transform: CGAffineTransform) -> Head {
            Head(leftEye.applying(transform), rightEye.applying(transform), nose.applying(transform))
        }
    }

    struct Tracking {
        let pose: DinoAnimation.Pose
        let head: Head
        var position: CGPoint { head.center }
        var transform: CGAffineTransform { DinoWelcomeJump.transform(from: idleHead, to: head) }
    }

    // Measured iris centroids and the midpoint between both nostrils, in the
    // original 1254-pixel paintings. Recoloring preserves these facial pixels.
    static let idleHead = Head(pixels: (605.76, 355.11), (800.74, 308.01), (803.62, 397.21))
    static func sourceHead(for asset: String) -> Head {
        switch asset {
        case "dino-opening-jump-02": Head(pixels: (731.46, 556.91), (935.30, 538.88), (917.29, 629.87))
        case "dino-opening-jump-03": Head(pixels: (592.44, 336.82), (776.99, 272.03), (778.07, 356.65))
        case "dino-opening-jump-07": Head(pixels: (629.80, 478.09), (835.98, 438.09), (830.02, 531.83))
        case "dino-opening-jump-08": Head(pixels: (601.05, 365.43), (795.27, 320.09), (794.49, 406.66))
        default: idleHead
        }
    }

    private static let lowHead: Head = {
        let center = idleHead.center
        let tilt = CGAffineTransform(rotationAngle: 8 * .pi / 180)
        func moved(_ point: CGPoint) -> CGPoint {
            let relative = CGPoint(x: point.x - center.x, y: point.y - center.y).applying(tilt)
            // Keep the original crouch's depth: the chin reaches the board's
            // upper edge, while the tracked face avoids its sideways lurch.
            return CGPoint(x: 728.0 / 1254 + relative.x, y: 550.0 / 1254 + relative.y)
        }
        return Head(moved(idleHead.leftEye), moved(idleHead.rightEye), moved(idleHead.nose))
    }()

    static func pose(elapsed: Double) -> DinoAnimation.Pose {
        guard elapsed < duration else { return .init(asset: "dino-idle") }
        let index = poseStarts.lastIndex { elapsed >= $0 } ?? 0
        let offsets = [0.0, 3.0, 0.0, 9.0, -2.0]
        return .init(asset: assets[index], offsetY: offsets[index] / 1254)
    }

    static func tracking(elapsed: Double, flight: DinoWelcomeFlight) -> Tracking {
        let pose = pose(elapsed: elapsed)
        let target: Head
        if elapsed < crouchBottom {
            let t = min(1, max(0, elapsed / crouchBottom))
            target = interpolate(idleHead, lowHead, t * t * (3 - 2 * t))
        } else if elapsed < flightHandoff {
            // Match the actual screen-space velocity of the flying painting,
            // including the arc, shrinking and rotation. Merely meeting its
            // local eye position made the two motions change speed at takeoff.
            let span = flightHandoff - crouchBottom
            let t = (elapsed - crouchBottom) / span
            let start = lowHead.applying(flight.worldTransform(elapsed: crouchBottom))
            let end = flight.paintedHead(elapsed: flightHandoff)
            let epsilon = 0.0001
            let before = flight.paintedHead(elapsed: flightHandoff - epsilon)
            let after = flight.paintedHead(elapsed: flightHandoff + epsilon)
            func point(_ a: CGPoint, _ b: CGPoint, _ previous: CGPoint, _ next: CGPoint) -> CGPoint {
                let h = t * t * (3 - 2 * t), tangent = t * t * (t - 1) * span / (2 * epsilon)
                return CGPoint(x: a.x + (b.x - a.x) * h + (next.x - previous.x) * tangent,
                               y: a.y + (b.y - a.y) * h + (next.y - previous.y) * tangent)
            }
            let screenHead = Head(point(start.leftEye, end.leftEye, before.leftEye, after.leftEye),
                                  point(start.rightEye, end.rightEye, before.rightEye, after.rightEye),
                                  point(start.nose, end.nose, before.nose, after.nose))
            // The parent flight layer starts moving before this handoff ends.
            // Compensate its transform so the visible face follows one curve.
            target = screenHead.applying(flight.worldTransform(elapsed: elapsed).inverted())
        } else {
            target = sourceHead(for: pose.asset).applying(CGAffineTransform(translationX: pose.offsetX, y: pose.offsetY))
        }
        return Tracking(pose: pose, head: target)
    }

    static func sourceCorrection(for asset: String) -> CGAffineTransform {
        transform(from: sourceHead(for: asset), to: idleHead)
    }

    static func motion(elapsed: Double) -> DinoAnimation.Sample {
        DinoOpeningJump.sample(elapsed: max(0, elapsed - takeoff + DinoOpeningJump.takeoff))
    }

    static func travelProgress(elapsed: Double) -> Double {
        min(1, max(0, (elapsed - takeoff) / (landing - takeoff)))
    }

    private static func interpolate(_ a: Head, _ b: Head, _ t: Double) -> Head {
        func point(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
            CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
        }
        return Head(point(a.leftEye, b.leftEye), point(a.rightEye, b.rightEye), point(a.nose, b.nose))
    }

    /// Linear part of the affine registration around the eye midpoint. The
    /// third landmark preserves the muzzle placement as the head tilts.
    private static func transform(from source: Head, to target: Head) -> CGAffineTransform {
        let sx = source.rightEye.x - source.leftEye.x, sy = source.rightEye.y - source.leftEye.y
        let tx = source.nose.x - source.center.x, ty = source.nose.y - source.center.y
        let dx = target.rightEye.x - target.leftEye.x, dy = target.rightEye.y - target.leftEye.y
        let ex = target.nose.x - target.center.x, ey = target.nose.y - target.center.y
        let determinant = sx * ty - sy * tx
        return CGAffineTransform(a: (dx * ty - ex * sy) / determinant,
                                 b: (dy * ty - ey * sy) / determinant,
                                 c: (ex * sx - dx * tx) / determinant,
                                 d: (ey * sx - dy * tx) / determinant, tx: 0, ty: 0)
    }
}

/// Shared, testable geometry for the welcome's native layers. The world matrix
/// maps normalized painting coordinates to screen points around the painted feet.
struct DinoWelcomeFlight {
    static let footline = CGFloat(1211.0 / 1254)
    let source: CGPoint
    let sourceSide: CGFloat
    let destination: CGRect

    func position(elapsed: Double) -> CGPoint {
        let t = CGFloat(DinoWelcomeJump.travelProgress(elapsed: elapsed))
        let side = sourceSide + (destination.width - sourceSide) * t
        let desiredArc = sourceSide * 0.48 + max(0, destination.midY - source.y) * 0.2
        let clearance = max(24, source.y - sourceSide / 2 - 16)
        let arc = -CGFloat(DinoWelcomeJump.motion(elapsed: elapsed).height) * min(250, desiredArc, clearance)
        return CGPoint(x: source.x + (destination.midX - source.x) * t,
                       y: source.y + (destination.midY - source.y) * t + (Self.footline - 0.5) * side - arc)
    }

    func transform(elapsed: Double) -> CGAffineTransform {
        let t = CGFloat(DinoWelcomeJump.travelProgress(elapsed: elapsed))
        let scale = 1 + (destination.width / sourceSide - 1) * t
        let sample = DinoWelcomeJump.motion(elapsed: elapsed)
        return CGAffineTransform(rotationAngle: sample.angle * .pi / 180)
            .scaledBy(x: scale * sample.scaleX, y: scale * sample.scaleY)
    }

    func worldTransform(elapsed: Double) -> CGAffineTransform {
        let linear = transform(elapsed: elapsed), origin = position(elapsed: elapsed)
        let anchor = CGPoint(x: sourceSide / 2, y: Self.footline * sourceSide).applying(linear)
        return CGAffineTransform(a: linear.a * sourceSide, b: linear.b * sourceSide,
                                 c: linear.c * sourceSide, d: linear.d * sourceSide,
                                 tx: origin.x - anchor.x, ty: origin.y - anchor.y)
    }

    func paintedHead(elapsed: Double) -> DinoWelcomeJump.Head {
        let pose = DinoWelcomeJump.pose(elapsed: elapsed)
        return DinoWelcomeJump.sourceHead(for: pose.asset)
            .applying(CGAffineTransform(translationX: pose.offsetX, y: pose.offsetY))
            .applying(worldTransform(elapsed: elapsed))
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
        CrystalMinerPatrol(id: 1, right: true, stops: [200, 505, 980, 1375], speed: 18, phaseOffset: 59),
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


/// Corresponding anatomical points keep the painted poses registered while
/// the drawing moves between them. Geometry runs continuously at display rate.
enum DinoStumbleMotion {
    struct Blend {
        let fromIndex: Int
        let toIndex: Int
        let amount: Double
        let points: [CGPoint]
        let time: Double
        var from: DinoAnimation.Pose { frames[fromIndex].pose }
        var to: DinoAnimation.Pose { frames[toIndex].pose }
        var drawingIndex: Int {
            // Bracing retains the low painting; one push-up painting then
            // carries the entire load-bearing part, independently of joint keys.
            if (DinoAnimation.stumblePushStart..<DinoAnimation.stumbleBraceEnd).contains(time) { return 5 }
            if supportsWeight { return 8 }
            return amount < 0.5 ? fromIndex : toIndex
        }
        var supportsWeight: Bool {
            time + 1e-9 >= DinoAnimation.stumbleBraceEnd && time <= DinoAnimation.stumbleHandRelease + 1e-9
        }
        var palms: [CGPoint] { palmIndices.map { points[$0] } }
        var drawing: DinoAnimation.Pose { frames[drawingIndex].pose }
        var drawingVertices: [CGPoint] { vertices(for: drawingIndex, points: points) }
    }

    private static let artworkForKey = [0, 1, 2, 3, 4, 5, 5, 6, 6, 7, 8, 9]
    static let frames: [DinoAnimation.TimedPose] = {
        let names = ["dino-idle"] + (2...10).map { String(format: "dino-result-fall-%02d", $0) }
        let offsets = [0.0, 15, 45, 48, 112, 81, 38, 9, -4, -2]
        let times = [DinoAnimation.stumbleTakeoff, 0.26, 0.46, DinoAnimation.stumbleLanding,
                     DinoAnimation.stumbleFaceContact, DinoAnimation.stumbleLowest,
                     DinoAnimation.stumblePushStart, DinoAnimation.stumbleBraceEnd, DinoAnimation.stumbleHandRelease, 1.48, 1.56, 1.62]
        return artworkForKey.indices.map { key in
            let art = artworkForKey[key]
            return DinoAnimation.TimedPose(start: times[key], pose: .init(asset: names[art], offsetY: offsets[art] / 1254))
        }
    }()

    // The source canvases frame the crouching head more tightly. Register its
    // physical size before interpolation so pushing up does not shrink the face.
    private static let artworkScale = [1.0, 0.94, 0.94, 0.90, 0.90, 0.95, 0.84, 0.90, 0.98, 1.0]

    private static func registered(_ point: CGPoint, pose: Int) -> CGPoint {
        let ground = 1211.0 / 1254, scale = artworkScale[artworkForKey[pose]]
        return CGPoint(x: 0.5 + (point.x - 0.5) * scale,
                       y: ground + (point.y + frames[pose].pose.offsetY - ground) * scale)
    }

    static func plantedRegistration(size: CGSize) -> CGAffineTransform {
        let origin = registered(.zero, pose: 8), scale = artworkScale[artworkForKey[8]]
        return CGAffineTransform(a: scale, b: 0, c: 0, d: scale,
                                 tx: origin.x * size.width, ty: origin.y * size.height)
    }

    static func palmMask(in size: CGSize, overlap: Bool = false) -> CGPath {
        let path = CGMutablePath(), pad = overlap ? 14.0 : 0
        for rect in [CGRect(x: 350, y: 1020, width: 340, height: 168),
                     CGRect(x: 938, y: 1000, width: 315, height: 165)] {
            path.addEllipse(in: rect.insetBy(dx: -pad, dy: -pad)
                .applying(CGAffineTransform(scaleX: size.width / 1254, y: size.height / 1254)))
        }
        return path
    }

    // Face, neck, torso, hips, rear foot, tail, cloth and head contour. Hands
    // change depth order, so only their common ground line constrains the mesh.
    private static let sourceAnchors: [[CGPoint]] = {
        let standing = [(600,350), (800,300), (770,435), (725,530), (700,590), (640,630),
                        (720,820), (660,1000), (470,1175), (190,695), (490,920), (550,50),
                        (430,260), (670,150), (450,395), (915,420)]
        let source = [
            standing,
            [(744,455),(968,473),(902,594),(754,655),(824,714),(700,735),(715,855),(535,855),
             (310,962),(215,385),(485,770),(745,92),(590,310),(840,252),(585,500),(1070,600)],
            [(767,500),(996,513),(970,630),(797,705),(850,785),(730,790),(720,900),(520,880),
             (260,1000),(200,350),(490,780),(800,135),(610,350),(890,300),(620,560),(1110,680)],
            [(852,778),(1077,812),(1030,920),(858,965),(915,1040),(740,930),(660,965),(520,730),
             (230,900),(210,140),(530,680),(850,365),(700,560),(990,580),(700,850),(1160,940)],
            [(805,856),(1018,890),(970,1005),(775,1010),(900,1075),(710,990),(650,950),(480,720),
             (210,870),(200,190),(500,650),(880,450),(650,675),(930,660),(660,890),(1120,1000)],
            [(826,804),(1057,865),(1010,995),(840,1030),(950,1090),(700,990),(570,990),(420,935),
             (150,1020),(165,550),(430,875),(950,435),(740,640),(1000,635),(690,875),(1150,1015)],
            [(763,511),(1042,513),(1000,630),(850,680),(930,780),(760,820),(740,940),(480,990),
             (210,1050),(175,470),(470,900),(805,90),(600,350),(905,300),(610,580),(1140,630)],
            [(721,464),(964,436),(950,565),(870,635),(885,710),(740,730),(730,880),(650,1000),
             (440,1150),(225,590),(480,960),(775,90),(540,360),(825,270),(580,520),(1080,590)],
            standing, standing
        ]
        let boundary = [CGPoint(x: 0, y: 0), CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0),
                        CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5),
                        CGPoint(x: 0, y: 1), CGPoint(x: 0.5, y: 1), CGPoint(x: 1, y: 1)]
        // Palm centres, in the same source coordinates as the body landmarks.
        let palms = [[(555,715),(960,640)], [(640,790),(1110,820)], [(710,820),(1140,820)],
                     [(650,1115),(1100,1110)], [(550,1060),(1180,1040)], [(560,1095),(1150,1090)],
                     [(500,1138),(1110,1110)], [(690,995),(1025,985)], [(550,660),(960,560)], [(550,670),(950,590)]]
        return artworkForKey.indices.map { key in
            let art = artworkForKey[key]
            let anatomy = source[art] + palms[art]
            return anatomy.map { registered(CGPoint(x: Double($0.0) / 1254, y: Double($0.1) / 1254), pose: key) }
                + boundary + [0.1, 0.3, 0.5, 0.7, 0.9].map { CGPoint(x: $0, y: 1211.0 / 1254) }
        }
    }()

    static let palmIndices = [16, 17]
    private static let anchors: [[CGPoint]] = {
        var targets = sourceAnchors
        // First wake and brace from the flat pose; then extend the arms. The
        // drawing and joint targets are separate so the same bitmap can deform.
        targets[7] = zip(sourceAnchors[6], sourceAnchors[8]).map {
            CGPoint(x: $0.x + ($1.x - $0.x) * 0.40, y: $0.y + ($1.y - $0.y) * 0.40)
        }
        for key in 7...8 {
            for palm in palmIndices { targets[key][palm] = sourceAnchors[8][palm] }
        }
        return targets
    }()

    static let columns = 14, rows = 16
    static let grid = (0...rows).flatMap { y in
        (0...columns).map { x in CGPoint(x: Double(x) / Double(columns), y: Double(y) / Double(rows)) }
    }
    static let triangles: [(Int, Int, Int)] = (0..<rows).flatMap { y in
        (0..<columns).flatMap { x -> [(Int, Int, Int)] in
            let a = y * (columns + 1) + x, b = a + 1, c = a + columns + 1, d = c + 1
            return [(a, b, d), (a, d, c)]
        }
    }

    // Moving least squares reproduces translation, scale and rotation exactly.
    // Its coefficients depend only on the source, so the per-frame work is small.
    private static let influences: [[[Double]]] = sourceAnchors.indices.map { pose in
        grid.map { vertex in
            let point = registered(vertex, pose: pose)
            let source = sourceAnchors[pose]
            let distances = source.map { pow($0.x - point.x, 2) + pow($0.y - point.y, 2) }
            if let exact = distances.firstIndex(where: { $0 < 0.00000001 }) {
                return source.indices.map { $0 == exact ? 1 : 0 }
            }
            let weights = distances.enumerated().map { i, distance in
                // Only the load-bearing painting uses wrist constraints. Free
                // hands must not drag the legs as they change depth order.
                palmIndices.contains(i) && artworkForKey[pose] != 6 ? 0 : 1 / max(0.0001, distance)
            }
            let total = weights.reduce(0, +)
            let center = source.indices.reduce(CGPoint.zero) { p, i in
                CGPoint(x: p.x + source[i].x * weights[i] / total, y: p.y + source[i].y * weights[i] / total)
            }
            var a = 0.0, b = 0.0, d = 0.0
            for i in source.indices {
                let x = source[i].x - center.x, y = source[i].y - center.y
                a += weights[i] * x * x; b += weights[i] * x * y; d += weights[i] * y * y
            }
            let determinant = max(0.00000001, a * d - b * b)
            let vx = point.x - center.x, vy = point.y - center.y
            let mx = (vx * d - vy * b) / determinant, my = (vy * a - vx * b) / determinant
            return source.indices.map {
                weights[$0] / total + weights[$0] * (mx * (source[$0].x - center.x) + my * (source[$0].y - center.y))
            }
        }
    }

    static func vertices(for pose: Int, points: [CGPoint]) -> [CGPoint] {
        influences[pose].map { weights in
            points.indices.reduce(CGPoint.zero) { value, i in
                CGPoint(x: value.x + weights[i] * points[i].x, y: value.y + weights[i] * points[i].y)
            }
        }
    }

    static func sample(at time: Double) -> Blend? {
        guard time + 1e-9 >= frames[0].start, time < frames.last!.start - 1e-9 else { return nil }
        let index = frames.lastIndex { time + 1e-9 >= $0.start } ?? 0
        let span = frames[index + 1].start - frames[index].start
        let p = min(1, max(0, (time - frames[index].start) / span))
        if anchors[index] == anchors[index + 1] {
            return Blend(fromIndex: index, toIndex: index + 1, amount: p, points: anchors[index], time: time)
        }
        func speed(_ frame: Int, _ point: Int, _ axis: KeyPath<CGPoint, CGFloat>) -> Double {
            guard frame > 0, frame < frames.count - 1 else { return 0 }
            let before = (anchors[frame][point][keyPath: axis] - anchors[frame - 1][point][keyPath: axis])
                / (frames[frame].start - frames[frame - 1].start)
            let after = (anchors[frame + 1][point][keyPath: axis] - anchors[frame][point][keyPath: axis])
                / (frames[frame + 1].start - frames[frame].start)
            return before * after > 0 ? 2 * before * after / (before + after) : 0
        }
        let p2 = p * p, p3 = p2 * p
        var points = anchors[index].indices.map { point -> CGPoint in
            func coordinate(_ axis: KeyPath<CGPoint, CGFloat>) -> Double {
                (2 * p3 - 3 * p2 + 1) * anchors[index][point][keyPath: axis]
                    + (p3 - 2 * p2 + p) * span * speed(index, point, axis)
                    + (-2 * p3 + 3 * p2) * anchors[index + 1][point][keyPath: axis]
                    + (p3 - p2) * span * speed(index + 1, point, axis)
            }
            return CGPoint(x: coordinate(\.x), y: coordinate(\.y))
        }
        if time + 1e-9 >= DinoAnimation.stumbleBraceEnd && time <= DinoAnimation.stumbleHandRelease + 1e-9 {
            for palm in palmIndices { points[palm] = anchors[8][palm] }
        }
        return Blend(fromIndex: index, toIndex: index + 1, amount: p, points: points, time: time)
    }

    static func transform(_ triangle: (Int, Int, Int), vertices: [CGPoint], size: CGSize) -> CGAffineTransform {
        func pixel(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * size.width, y: p.y * size.height) }
        let a = pixel(grid[triangle.0]), b = pixel(grid[triangle.1]), c = pixel(grid[triangle.2])
        let p = pixel(vertices[triangle.0]), q = pixel(vertices[triangle.1]), r = pixel(vertices[triangle.2])
        let sx = b.x - a.x, sy = b.y - a.y, tx = c.x - a.x, ty = c.y - a.y
        let dx = q.x - p.x, dy = q.y - p.y, ex = r.x - p.x, ey = r.y - p.y
        let determinant = sx * ty - sy * tx
        let aa = (dx * ty - ex * sy) / determinant, cc = (ex * sx - dx * tx) / determinant
        let bb = (dy * ty - ey * sy) / determinant, dd = (ey * sx - dy * tx) / determinant
        return CGAffineTransform(a: aa, b: bb, c: cc, d: dd, tx: p.x - aa * a.x - cc * a.y, ty: p.y - bb * a.x - dd * a.y)
    }
}
