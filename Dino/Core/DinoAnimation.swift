import Foundation

/// Sample continuous motion independently of the sparse, supplied pose art.
enum DinoAnimation {
    enum Clip: String { case idle, thumbsUp, backflip }
    struct Pose {
        let asset: String
        let paintedAngle: Double
        var offsetX = 0.0
        var offsetY = 0.0
    }
    struct Sample {
        let first: Pose
        let second: Pose
        let blend: Double
        let angle: Double
        let height: Double
        let scaleX: Double
        let scaleY: Double
    }
    static let correctAnswerDelay = 0.72
    static func duration(_ clip: Clip) -> Double {
        switch clip { case .idle: 0; case .thumbsUp: 0.62; case .backflip: 1.85 }
    }
    static func sample(_ clip: Clip, elapsed: Double, reducedMotion: Bool = false) -> Sample {
        let idle = Pose(asset: "dino-idle", paintedAngle: 0)
        guard clip != .idle else {
            return Sample(first: idle, second: idle, blend: 0, angle: 0, height: 0, scaleX: 1, scaleY: 1)
        }
        let prefix = clip == .backflip ? "dino-backflip" : "dino-thumbs-up"
        // Measured alpha centroids keep the spin pivot steady. Ground poses keep feet aligned.
        let centersX = [0.524, 0.525, 0.517, 0.505, 0.531, 0.518, 0.515, 0.513]
        let shiftsY = [0.016, 0.061, 0.069, 0.075, 0.030, 0.023, 0.023, -0.009]
        let poses = (1...8).map { index in
            Pose(asset: String(format: "%@-%02d", prefix, index),
                 paintedAngle: clip == .backflip ? (index == 3 ? -45 : index == 4 ? -180 : 0) : 0,
                 offsetX: clip == .backflip ? 0.5 - centersX[index - 1] : 0,
                 offsetY: clip == .backflip ? shiftsY[index - 1] : 0)
        }
        if reducedMotion {
            return Sample(first: poses[7], second: poses[7], blend: 0, angle: 0, height: 0, scaleX: 1, scaleY: 1)
        }
        let t = max(0, elapsed)
        let times: [Double] = clip == .backflip
            ? [0, 0.24, 0.40, 0.76, 1.07, 1.24, 1.38, 1.61]
            : [0, 0.06, 0.12, 0.18, 0.25, 0.32, 0.39, 0.47]
        let index = times.lastIndex { t >= $0 } ?? 0
        let previous = max(0, index - 1)
        let blend = index == 0 ? 1 : smooth((t - times[index]) / (clip == .backflip ? 0.065 : 0.045))
        if clip == .thumbsUp {
            return Sample(first: poses[previous], second: poses[index], blend: blend,
                          angle: 0, height: -0.025 * sin(.pi * min(t / 0.62, 1)), scaleX: 1, scaleY: 1)
        }
        // Correct each pose's painted angle; the whole turn follows one continuous curve.
        let flight = min(max((t - 0.26) / 1.04, 0), 1)
        let angle = -360 * smooth((t - 0.29) / 0.94)
        let height = -0.42 * pow(sin(.pi * flight), 1.2)
        let crouch = 0.09 * pulse(t, start: 0.02, end: 0.24)
        let landing = 0.11 * pulse(t, start: 1.30, end: 1.60)
        return Sample(first: poses[previous], second: poses[index], blend: blend, angle: angle,
                      height: height, scaleX: 1 + (crouch + landing) * 0.45, scaleY: 1 - crouch - landing)
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
