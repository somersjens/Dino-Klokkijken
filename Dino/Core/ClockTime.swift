import Foundation
import CoreGraphics

/// Scenery clocks share one speed contract; boss hands run twice as fast.
enum WorldClockMotion {
    static let cityMinuteRevolution: TimeInterval = 24
    static let bossMinuteRevolution: TimeInterval = cityMinuteRevolution / 2

    struct Phase {
        let initial: ClockTime
        let elapsed: TimeInterval
        let minuteRevolution: TimeInterval

        private var minutes: Double {
            let cycle = minuteRevolution * 24
            return Double(initial.minutesOfDay)
                + max(0, elapsed).truncatingRemainder(dividingBy: cycle) * 60 / minuteRevolution
        }
        var minuteAngle: Double { (minutes * 6).truncatingRemainder(dividingBy: 360) }
        var hourAngle: Double { (minutes * 0.5).truncatingRemainder(dividingBy: 360) }
        var reading: ClockTime {
            let minute = Int(minutes) % 1440
            return .init(hour: minute / 60, minute: minute % 60)
        }
    }
}

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
    struct MinuteMark {
        let minute: Int
        let tickStart: CGPoint
        let tickEnd: CGPoint
        let label: CGPoint
    }

    static func outerRadius(angle: Double, shape: AnalogClockShape) -> Double {
        let radians = angle * .pi / 180
        let x = abs(sin(radians)), y = abs(cos(radians))
        switch shape {
        case .circle: return 0.5
        case .square: return 0.5 / max(x, y)
        case .octagon: return 0.5 / max(x, y, (x + y) / sqrt(2))
        }
    }

    static func minuteMarks(shape: AnalogClockShape) -> [MinuteMark] {
        stride(from: 0, to: 60, by: 5).map { minute in
            minuteMark(minute: minute, shape: shape,
                       labelSize: CGSize(width: Double(String(minute).count) * 0.042, height: 0.078))
        }
    }

    /// The label sits beyond its tick by the same visible gap at every angle.
    /// Using the measured text rectangle keeps two digits and words off the rim.
    static func minuteMark(minute: Int, shape: AnalogClockShape, labelSize: CGSize,
                           gap: Double = 0.018) -> MinuteMark {
        let angle = Double(minute) * 6
        let edge = outerRadius(angle: angle, shape: shape)
        let start = point(radius: edge + 0.008, angle: angle)
        let end = point(radius: edge + 0.026, angle: angle)
        return MinuteMark(minute: minute, tickStart: start, tickEnd: end,
                          label: labelCenter(from: end, toward: point(radius: 1, angle: angle),
                                             labelSize: labelSize, gap: gap))
    }

    static func labelCenter(from start: CGPoint, toward direction: CGPoint, labelSize: CGSize,
                            gap: Double) -> CGPoint {
        let length = max(1e-12, hypot(direction.x, direction.y))
        let unit = CGPoint(x: direction.x / length, y: direction.y / length)
        let horizontal = abs(unit.x) < 1e-10 ? Double.infinity : (labelSize.width / 2 + gap) / abs(unit.x)
        let vertical = abs(unit.y) < 1e-10 ? Double.infinity : (labelSize.height / 2 + gap) / abs(unit.y)
        let distance = min(horizontal, vertical)
        return CGPoint(x: start.x + unit.x * distance, y: start.y + unit.y * distance)
    }

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

    static func pointers(time: ClockTime, shape: AnalogClockShape = .circle) -> [Pointer] {
        // Both arrows stop outside the scale; the hour still names the completed hour.
        let hourAngle = Double(time.hour % 12) * 30
        func tip(at angle: Double) -> CGPoint {
            point(radius: outerRadius(angle: angle, shape: shape) + 0.165, angle: angle)
        }
        func pointer(tip: CGPoint, angle: Double) -> Pointer {
            let badge = point(radius: outerRadius(angle: angle, shape: shape) + 0.345, angle: angle)
            let distance = hypot(badge.x - tip.x, badge.y - tip.y)
            return Pointer(start: CGPoint(x: badge.x + (tip.x - badge.x) * 0.09 / distance,
                                          y: badge.y + (tip.y - badge.y) * 0.09 / distance),
                           tip: tip, badge: badge)
        }
        let hourTip = tip(at: hourAngle)
        let straightHour = pointer(tip: hourTip, angle: hourAngle)
        let minute = pointer(tip: tip(at: time.minuteAngle), angle: time.minuteAngle)
        let badgeSeparation = hypot(straightHour.badge.x - minute.badge.x, straightHour.badge.y - minute.badge.y)
        if badgeSeparation >= 0.235 { return [straightHour, minute] }

        // Keep the badges close while aiming the side route at the actual hour
        // numeral. The tip stays outside the scale, on that same approach line.
        let numeral = point(radius: 0.34, angle: hourAngle)
        let hours = [-18.0, 18, -22, 22, -26, 26, -30, 30, -35, 35, -45, 45].map { offset in
            let angle = hourAngle + offset
            let badge = point(radius: outerRadius(angle: angle, shape: shape) + 0.345, angle: angle)
            var inside = 0.0, outside = 1.0
            for _ in 0..<30 {
                let fraction = (inside + outside) / 2
                let position = CGPoint(x: numeral.x + (badge.x - numeral.x) * fraction,
                                       y: numeral.y + (badge.y - numeral.y) * fraction)
                let direction = atan2(position.x, -position.y) * 180 / .pi
                if hypot(position.x, position.y) < outerRadius(angle: direction, shape: shape) + 0.165 {
                    inside = fraction
                } else {
                    outside = fraction
                }
            }
            let tip = CGPoint(x: numeral.x + (badge.x - numeral.x) * outside,
                              y: numeral.y + (badge.y - numeral.y) * outside)
            return pointer(tip: tip, angle: angle)
        }
        let marks = minuteMarks(shape: shape)
        var best = [hours[0], minute]
        var bestScore = -Double.infinity
        for hour in hours {
            var labelClearance = Double.infinity
            for mark in marks {
                for edge in [hour.start] + hour.arrowWings {
                    labelClearance = min(labelClearance, segmentDistance(edge, hour.tip, mark.label, mark.label) - 0.046)
                }
            }
            let separation = hypot(hour.badge.x - minute.badge.x, hour.badge.y - minute.badge.y)
            var routeSeparation = Double.infinity
            for hourStart in [hour.start] + hour.arrowWings {
                for minuteStart in [minute.start] + minute.arrowWings {
                    routeSeparation = min(routeSeparation, segmentDistance(hourStart, hour.tip, minuteStart, minute.tip))
                }
            }
            let arrowLength = hypot(hour.badge.x - hour.tip.x, hour.badge.y - hour.tip.y)
            let score = min(labelClearance, 0.025) - max(0, 0.235 - separation) * 3
                - max(0, 0.035 - routeSeparation) * 3 - max(0, 0.18 - arrowLength) * 10
            if score > bestScore { bestScore = score; best = [hour, minute] }
        }
        return best
    }

    /// Reserve only the scale and the two arrows present at this time.
    /// Badge and stroke margins match the scaled artwork, including small faces.
    static func bounds(time: ClockTime, shape: AnalogClockShape, faceSize: Double) -> CGRect {
        let scale = max(1, faceSize)
        let badgeRadius = 14.5 / max(150, scale) + 0.012
        let strokeRadius = 3.75 / max(150, scale) + 0.012
        var bounds = CGRect(x: -0.5, y: -0.5, width: 1, height: 1)
        for mark in minuteMarks(shape: shape) {
            let label = CGRect(x: mark.label.x - 0.052, y: mark.label.y - 0.048,
                               width: 0.104, height: 0.096)
            bounds = bounds.union(label)
        }
        for pointer in pointers(time: time, shape: shape) {
            bounds = bounds.union(CGRect(x: pointer.badge.x - badgeRadius, y: pointer.badge.y - badgeRadius,
                                         width: badgeRadius * 2, height: badgeRadius * 2))
            for point in [pointer.start, pointer.tip] + pointer.arrowWings {
                bounds = bounds.union(CGRect(x: point.x - strokeRadius, y: point.y - strokeRadius,
                                             width: strokeRadius * 2, height: strokeRadius * 2))
            }
        }
        // Keep the face horizontally centred while trimming top/bottom separately.
        let horizontal = max(-bounds.minX, bounds.maxX)
        return CGRect(x: -horizontal, y: bounds.minY, width: horizontal * 2, height: bounds.height)
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
            guard dx != 0 || dy != 0 else { return hypot(p.x - a.x, p.y - a.y) }
            let t = min(1, max(0, ((p.x - a.x) * dx + (p.y - a.y) * dy) / (dx * dx + dy * dy)))
            return hypot(p.x - a.x - t * dx, p.y - a.y - t * dy)
        }
        return min(distance(a, c, d), distance(b, c, d), distance(c, a, b), distance(d, a, b))
    }
}
