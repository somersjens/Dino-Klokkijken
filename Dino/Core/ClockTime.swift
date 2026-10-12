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
    var minutesOfDay: Int { hour * 60 + minute }
    func adding(minutes: Int) -> ClockTime {
        let total = ((minutesOfDay + minutes) % 1440 + 1440) % 1440
        return ClockTime(hour: total / 60, minute: total % 60)
    }

    /// A touch clockwise from twelve snaps to the nearest whole hour.
    static func snappedHour(x: Double, y: Double, minute: Int = 0) -> Int {
        let angle = atan2(x, -y) - Double(minute) * .pi / 360
        let tick = (Int((angle / (.pi / 6)).rounded()) + 12) % 12
        return tick == 0 ? 12 : tick
    }

    static func shiftedHour(_ hour: Int, by delta: Int) -> Int {
        ((hour - 1 + delta) % 12 + 12) % 12 + 1
    }

    static func snappedMinute(x: Double, y: Double, step: Int) -> Int {
        precondition(step > 0 && 60.isMultiple(of: step))
        let divisions = 60 / step
        let tick = Int((atan2(x, -y) / (2 * .pi / Double(divisions))).rounded())
        return ((tick % divisions + divisions) % divisions) * step
    }

    static func shiftedMinute(_ minute: Int, by delta: Int) -> Int {
        ((minute + delta) % 60 + 60) % 60
    }
}
