import Foundation

/// One visible pose at a time: smooth motion without fading different faces together.
enum DinoAnimation {
    enum Clip: String { case idle, thumbsUp, wrongAnswer, backflip }
    struct Pose {
        let asset: String
        var paintedAngle = 0.0
        var offsetX = 0.0
        var offsetY = 0.0
    }
    struct Sample {
        let pose: Pose
        var angle = 0.0
        var height = 0.0
        var scaleX = 1.0
        var scaleY = 1.0
    }

    static let correctAnswerDelay = 0.72
    static let spriteAssets = ["dino-idle", "dino-thumbs-up-08", "dino-wrong-answer-04",
                               "dino-backflip-01", "dino-backflip-03", "dino-backflip-07", "dino-backflip-08"]
    static func duration(_ clip: Clip) -> Double {
        switch clip {
        case .idle: 0
        case .thumbsUp: 0.52
        case .wrongAnswer: 0.5
        case .backflip: 1.62
        }
    }

    static func sample(_ clip: Clip, elapsed: Double, reducedMotion: Bool = false) -> Sample {
        let t = max(0, elapsed)
        switch clip {
        case .idle:
            return Sample(pose: Pose(asset: "dino-idle"))
        case .thumbsUp:
            // The other supplied thumbs poses change the face and hands too much for a short reaction.
            let emphasis = reducedMotion ? 0 : 0.035 * pulse(t, start: 0, end: 0.38)
            return Sample(pose: Pose(asset: "dino-thumbs-up-08"), scaleX: 1 + emphasis, scaleY: 1 + emphasis)
        case .wrongAnswer:
            // One gentle shrug, then keep the same pose until the child chooses Next.
            let p = min(t / duration(.wrongAnswer), 1)
            let tilt = reducedMotion || p == 1 ? 0 : 2 * sin(2 * .pi * p) * sin(.pi * p)
            return Sample(pose: Pose(asset: "dino-wrong-answer-04"), angle: tilt)
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

    private static func smooth(_ value: Double) -> Double {
        let p = min(max(value, 0), 1)
        return p * p * (3 - 2 * p)
    }
    private static func pulse(_ t: Double, start: Double, end: Double) -> Double {
        guard t > start, t < end else { return 0 }
        return sin(.pi * (t - start) / (end - start))
    }
}
