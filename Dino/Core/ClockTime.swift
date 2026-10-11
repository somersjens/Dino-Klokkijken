import Foundation

/// Shared clock mathematics. Rendering, questions and validation all use this value.
struct ClockTime: Codable, Equatable, Hashable, Sendable {
    let hour: Int
    let minute: Int

    init(hour: Int, minute: Int = 0) {
        self.hour = ((hour % 24) + 24) % 24
        self.minute = min(59, max(0, minute))
    }

    var hourAngle: Double { Double(hour % 12) * 30 + Double(minute) * 0.5 }
    var minuteAngle: Double { Double(minute) * 6 }
    var digitalText: String { String(format: "%02d:%02d", hour, minute) }

    /// A touch clockwise from twelve snaps to the nearest whole hour.
    static func snappedHour(x: Double, y: Double) -> Int {
        let angle = atan2(x, -y)
        let tick = (Int((angle / (.pi / 6)).rounded()) + 12) % 12
        return tick == 0 ? 12 : tick
    }

    static func shiftedHour(_ hour: Int, by delta: Int) -> Int {
        ((hour - 1 + delta) % 12 + 12) % 12 + 1
    }
}
