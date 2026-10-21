import Foundation

/// Shared clock mathematics. Rendering, questions and validation all use this value.
struct ClockTime: Codable, Equatable, Hashable, Sendable {
    let hour: Int
    let minute: Int

    init(hour: Int, minute: Int = 0) {
        self.hour = ((hour % 24) + 24) % 24
        self.minute = min(59, max(0, minute))
    }

    init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour: components.hour ?? 0, minute: components.minute ?? 0)
    }

    var hourAngle: Double { Double(hour % 12) * 30 + Double(minute) * 0.5 }
    var minuteAngle: Double { Double(minute) * 6 }
    var digitalText: String { String(format: "%02d:%02d", hour, minute) }

    func digitalReading(notation: DigitalHourNotation, languageCode: String) -> DigitalClockReading {
        let minuteText = String(format: "%02d", minute)
        guard notation == .twelve else {
            return DigitalClockReading(hour: String(format: "%02d", hour), minute: minuteText, period: nil)
        }
        var calendar = Calendar(identifier: .gregorian)
        let locale = Locale(identifier: languageCode)
        calendar.locale = locale
        let date = calendar.date(from: DateComponents(calendar: calendar, hour: hour, minute: minute)) ?? Date()
        func part(_ format: String) -> String {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.calendar = calendar
            formatter.dateFormat = format
            return formatter.string(from: date)
        }
        return DigitalClockReading(hour: part("hh"), minute: part("mm"), period: part("a"))
    }
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

    /// Interactive clock controls keep hours in 1...12 and carry minutes across the hour.
    func shiftingMinutes(by delta: Int) -> ClockTime {
        let shifted = adding(minutes: delta)
        return ClockTime(hour: (shifted.hour + 11) % 12 + 1, minute: shifted.minute)
    }

    /// Follow the shortest movement of the minute hand, including across twelve.
    func settingMinute(_ newMinute: Int) -> ClockTime {
        var delta = newMinute - minute
        if delta < -30 { delta += 60 }
        else if delta > 30 { delta -= 60 }
        return shiftingMinutes(by: delta)
    }
}

struct DigitalClockReading: Equatable, Sendable {
    var hour: String
    var minute: String
    var period: String?
    var text: String {
        guard let period else { return "\(hour):\(minute)" }
        return "\(hour):\(minute) \(period)"
    }
}

/// Select a touched hand without changing the selection for taps elsewhere on the dial.
enum ClockHandSelection {
    static func minutes(at point: CGPoint, hourAngle: Double, minuteAngle: Double,
                        preferredMinutes: Bool) -> Bool {
        guard hypot(point.x, point.y) > 0.10 else { return preferredMinutes }
        func distance(angle: Double, length: Double) -> Double {
            let radians = angle * .pi / 180
            let dx = sin(radians), dy = -cos(radians)
            let projection = min(length, max(0, point.x * dx + point.y * dy))
            return hypot(point.x - projection * dx, point.y - projection * dy)
        }
        let hour = distance(angle: hourAngle, length: 0.23)
        let minute = distance(angle: minuteAngle, length: 0.34)
        // Overlapping hands retain the selected hand; the exposed minute tip remains selectable.
        guard min(hour, minute) <= 0.075, abs(hour - minute) > 0.015 else { return preferredMinutes }
        return minute < hour
    }
}

/// Coordinates are relative to the centre of a face with diameter 1.
enum ClockHandHintGeometry {
    struct Pointer {
        let start: CGPoint
        let tip: CGPoint
        let badge: CGPoint
        var arrowWings: [CGPoint] {
            let direction = atan2(tip.y - start.y, tip.x - start.x)
            return [-Double.pi / 5, Double.pi / 5].map { offset in
                CGPoint(x: tip.x - cos(direction + offset) * 0.045,
                        y: tip.y - sin(direction + offset) * 0.045)
            }
        }
    }

    static func pointers(time: ClockTime, hourWidth: Double, minuteWidth: Double) -> [Pointer] {
        let angles = [time.hourAngle, time.minuteAngle]
        let lengths = [0.23, 0.34]
        let widths = [hourWidth, minuteWidth]
        let difference = (time.hourAngle - time.minuteAngle + 540).truncatingRemainder(dividingBy: 360) - 180
        // Follow the hands unless the number badges would sit almost on top of each other.
        if abs(difference) >= 22 {
            return (0..<2).map { index in
                Pointer(start: point(radius: 0.57, angle: angles[index]),
                        tip: point(radius: lengths[index] + widths[index] / 2 + 0.04, angle: angles[index]),
                        badge: point(radius: 0.66, angle: angles[index]))
            }
        }
        let candidates = (0..<2).map { index in
            [-1.0, 1.0].flatMap { side in
                [35.0, 55.0, 75.0].map { spread in
                    let radians = angles[index] * .pi / 180
                    let handPoint = point(radius: lengths[index] * 0.83, angle: angles[index])
                    let gap = widths[index] / 2 + 0.04
                    let tip = CGPoint(x: handPoint.x + cos(radians) * gap * side,
                                      y: handPoint.y + sin(radians) * gap * side)
                    let badge = point(radius: 0.66, angle: angles[index] + spread * side)
                    let distance = hypot(badge.x - tip.x, badge.y - tip.y)
                    let start = CGPoint(x: badge.x + (tip.x - badge.x) * 0.09 / distance,
                                        y: badge.y + (tip.y - badge.y) * 0.09 / distance)
                    return Pointer(start: start, tip: tip, badge: badge)
                }
            }
        }
        var best = [candidates[0][0], candidates[1][0]]
        var bestScore = -Double.infinity
        for hour in candidates[0] {
            for minute in candidates[1] {
                let pointers = [hour, minute]
                var clearance = Double.infinity
                for pointer in pointers {
                    for index in 0..<2 {
                        let handStart = point(radius: -0.035, angle: angles[index])
                        let handEnd = point(radius: lengths[index], angle: angles[index])
                        for start in [pointer.start] + pointer.arrowWings {
                            clearance = min(clearance, segmentDistance(start, pointer.tip, handStart, handEnd) - widths[index] / 2)
                        }
                    }
                }
                let separation = hypot(hour.badge.x - minute.badge.x, hour.badge.y - minute.badge.y)
                var routeSeparation = Double.infinity
                for hourStart in [hour.start] + hour.arrowWings {
                    for minuteStart in [minute.start] + minute.arrowWings {
                        routeSeparation = min(routeSeparation, segmentDistance(hourStart, hour.tip, minuteStart, minute.tip))
                    }
                }
                let score = clearance - max(0, 0.23 - separation) - max(0, 0.04 - routeSeparation)
                if score > bestScore { bestScore = score; best = pointers }
            }
        }
        return best
    }

    static func point(radius: Double, angle: Double) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(x: sin(radians) * radius, y: -cos(radians) * radius)
    }

    static func segmentDistance(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ d: CGPoint) -> Double {
        func cross(_ p: CGPoint, _ q: CGPoint, _ r: CGPoint) -> Double {
            (q.x - p.x) * (r.y - p.y) - (q.y - p.y) * (r.x - p.x)
        }
        func oppositeSides(_ first: Double, _ second: Double) -> Bool {
            // Collinear segments can acquire tiny, opposite signs through rounding.
            let epsilon = 1e-12
            return (first > epsilon && second < -epsilon) || (first < -epsilon && second > epsilon)
        }
        if oppositeSides(cross(a, b, c), cross(a, b, d)) && oppositeSides(cross(c, d, a), cross(c, d, b)) { return 0 }
        func distance(_ p: CGPoint, _ a: CGPoint, _ b: CGPoint) -> Double {
            let dx = b.x - a.x, dy = b.y - a.y
            let t = min(1, max(0, ((p.x - a.x) * dx + (p.y - a.y) * dy) / (dx * dx + dy * dy)))
            return hypot(p.x - a.x - t * dx, p.y - a.y - t * dy)
        }
        return min(distance(a, c, d), distance(b, c, d), distance(c, a, b), distance(d, a, b))
    }
}
