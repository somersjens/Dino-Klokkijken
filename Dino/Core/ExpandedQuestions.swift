import Foundation

enum DinoDayPart: String, CaseIterable, Sendable {
    case night, morning, afternoon, evening
    init(hour: Int) {
        switch hour {
        case 0..<6: self = .night
        case 6..<12: self = .morning
        case 12..<18: self = .afternoon
        default: self = .evening
        }
    }
    var titleKey: String { "dino.dayPart.\(rawValue)" }
    var symbol: String {
        switch self {
        case .night: return "moon.stars.fill"
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        }
    }
}

enum ClockAnswer: Equatable, Hashable, Sendable {
    case time(ClockTime), duration(Int), truth(Bool), dayPart(DinoDayPart)
    case ordering([ClockTime]), pairs([ClockTime]), spoken(SpokenTimeAnswer)
}

enum DinoScheduleActivity: String, CaseIterable, Sendable {
    case drawing, reading, sports, music, building, puzzles
    var titleKey: String { "dino.schedule.activity.\(rawValue)" }
    var symbol: String {
        switch self {
        case .drawing: return "paintpalette.fill"
        case .reading: return "book.fill"
        case .sports: return "soccerball"
        case .music: return "music.note"
        case .building: return "building.2.fill"
        case .puzzles: return "puzzlepiece.fill"
        }
    }
}

/// A train ride: departure, two trains, and the transfer you have to count between them.
struct DinoDaySchedule: Equatable, Sendable {
    let start: ClockTime
    let firstActivity: DinoScheduleActivity
    let firstMinutes: Int
    let breakMinutes: Int
    let secondActivity: DinoScheduleActivity
    let secondMinutes: Int
    var totalMinutes: Int { firstMinutes + breakMinutes + secondMinutes }
    var firstEnd: ClockTime { start.adding(minutes: firstMinutes) }
    var secondStart: ClockTime { firstEnd.adding(minutes: breakMinutes) }
    var end: ClockTime { secondStart.adding(minutes: secondMinutes) }
    var durations: [Int] { [firstMinutes, breakMinutes, secondMinutes] }
}

enum DinoExpandedQuestions {
    static func generate<R: RandomNumberGenerator>(kind: ClockQuestionKind, time: DinoPracticeTime,
                                                   index: Int, previousTarget: ClockTime?, language: String = "nl", using rng: inout R) -> ClockQuestion {
        generate(kind: kind, minutes: time.minutes, minuteStep: time.minuteStep,
                 index: index, previousTarget: previousTarget, language: language, using: &rng)
    }

    static func generate<R: RandomNumberGenerator>(kind: ClockQuestionKind, minutes: [Int], minuteStep: Int,
                                                   index: Int, previousTarget: ClockTime?, preferredTarget: ClockTime? = nil,
                                                   isDemonstration: Bool = false,
                                                   language: String = "nl",
                                                   using rng: inout R) -> ClockQuestion {
        let scheduleDurations = kind == .daySchedule
            ? [minuteStep * Int.random(in: 1...2, using: &rng), minuteStep,
               minuteStep * Int.random(in: 1...3, using: &rng)] : []
        let hours = [.readDigital, .spokenTime, .trueFalse, .sayTime].contains(kind) ? Array(1...12) : Array(0...23)
        let spoken = kind == .sayTime ? SpokenTimeCatalog.language(code: language) : nil
        let pool = hours.flatMap { hour in minutes.map { ClockTime(hour: hour, minute: $0) } }
            .filter { time in
                if kind == .sayTime { return spoken!.supports(minute: time.minute) }
                if kind == .dayPart && !isDemonstration { return time.hour != 6 && time.hour < 22 }
                if kind == .sortTimes { return time.minutesOfDay != 0 }
                // Leave room for an earlier time in the same selected minute family.
                if kind == .minutesBetween { return time.minutesOfDay >= 60 + (minutes.min() ?? 0) }
                if kind == .daySchedule {
                    return time.minutesOfDay >= 8 * 60 + scheduleDurations.reduce(0, +)
                        && time.minutesOfDay <= 20 * 60
                }
                return true
            }
        let target = preferredTarget.flatMap { pool.contains($0) ? $0 : nil }
            ?? pool.filter { $0 != previousTarget }.randomElement(using: &rng)!
        let other = pool.filter { $0 != target }.shuffled(using: &rng)
        var choices = Array(other.prefix(3))
        choices.insert(target, at: Int.random(in: 0..<4, using: &rng))
        var q = ClockQuestion(id: index, kind: kind, target: target, options: choices,
                              activity: nil, companionClocks: Array(other.prefix(2)))
        let step = minuteStep
        let duration = step * Int.random(in: 1...3, using: &rng)
        switch kind {
        case .readDigital, .spokenTime, .read24Hour: break
        case .sayTime:
            q.options = []
            q.spokenPrompt = SpokenTimeCatalog.language(code: language).prompt(for: target, using: &rng)
            q.answer = .spoken(q.spokenPrompt!.correct)
        case .trueFalse:
            let truthful = Bool.random(using: &rng)
            q.statement = truthful ? target : other[0]
            q.options = []; q.answerChoices = [.truth(true), .truth(false)]; q.answer = .truth(truthful)
        case .dayPart:
            q.options = []; q.answerChoices = DinoDayPart.allCases.map(ClockAnswer.dayPart)
            q.answer = .dayPart(.init(hour: target.hour))
        case .sortTimes:
            q.options = ([target] + Array(other.prefix(3))).shuffled(using: &rng)
            q.answer = .ordering(q.options.sorted { $0.minutesOfDay < $1.minutesOfDay })
        case .timeSequence:
            q.durationMinutes = duration
            q.relatedTimes = [target.adding(minutes: -3 * duration), target.adding(minutes: -2 * duration), target.adding(minutes: -duration)]
        case .addTime, .advanceAnalog:
            q.durationMinutes = kind == .advanceAnalog ? Self.advanceDuration(minuteStep: step, using: &rng) : duration
            q.relatedTimes = [target.adding(minutes: -q.durationMinutes)]
            if kind == .advanceAnalog { q.options = [] }
        case .subtractTime:
            q.durationMinutes = duration; q.relatedTimes = [target.adding(minutes: duration)]
        case .flightArrival:
            // Whole and half hours stay in one zone. Harder minute families state an hour difference.
            q.offsetHours = Self.flightOffsetHours(minuteStep: minuteStep, using: &rng)
            q.durationMinutes = Self.flightDurationMinutes(offsetHours: q.offsetHours, minuteStep: minuteStep,
                                                           extraSteps: Int.random(in: q.offsetHours == 0 ? 1...3 : 0...2, using: &rng))
            q.relatedTimes = [target.adding(minutes: -(q.durationMinutes + q.offsetHours * 60))]
            if q.offsetHours != 0 {
                let forgotten = target.adding(minutes: -q.offsetHours * 60)
                let reversed = target.adding(minutes: q.offsetHours * 60)
                let nudged = target.adding(minutes: q.offsetHours > 0 ? 60 : -60)
                var seen: Set<ClockTime> = [target]
                var distractors = [forgotten, reversed, nudged].filter { seen.insert($0).inserted }
                for candidate in other where distractors.count < 3 && seen.insert(candidate).inserted {
                    distractors.append(candidate)
                }
                q.options = (distractors + [target]).shuffled(using: &rng)
            }
        case .daySchedule:
            let activities = DinoScheduleActivity.allCases.shuffled(using: &rng)
            let schedule = DinoDaySchedule(start: target.adding(minutes: -scheduleDurations.reduce(0, +)),
                firstActivity: activities[0], firstMinutes: scheduleDurations[0],
                breakMinutes: scheduleDurations[1], secondActivity: activities[1], secondMinutes: scheduleDurations[2])
            q.daySchedule = schedule
            q.durationMinutes = schedule.totalMinutes
            q.relatedTimes = [schedule.start]
            // Include common mistakes, such as forgetting the break or stopping after activity one.
            let candidates = [schedule.firstEnd, target.adding(minutes: -schedule.breakMinutes), schedule.start,
                              target.adding(minutes: -60), target.adding(minutes: 60)] + other
            var seen: Set<ClockTime> = [target]
            let distractors = candidates.filter { minutes.contains($0.minute) && seen.insert($0).inserted }
            q.options = (Array(distractors.prefix(3)) + [target]).shuffled(using: &rng)
        case .minutesBetween:
            let starts = (1...min(180, target.minutesOfDay))
                .map { target.adding(minutes: -$0) }
                .filter { minutes.contains($0.minute) }
            let start = starts.randomElement(using: &rng)!
            let elapsed = target.minutesOfDay - start.minutesOfDay
            q.relatedTimes = [start, target]
            q.durationMinutes = elapsed
            // Nearby minute totals catch conversion and subtraction mistakes.
            let gap = min(15, minuteStep)
            var seen: Set<Int> = [elapsed]
            let distractors = [-gap, gap, -2 * gap, 2 * gap, -60, 60, 3 * gap]
                .map { elapsed + $0 }
                .filter { $0 > 0 && seen.insert($0).inserted }
            q.options = []
            q.answerChoices = (Array(distractors.shuffled(using: &rng).prefix(3)) + [elapsed])
                .shuffled(using: &rng).map(ClockAnswer.duration)
            q.answer = .duration(elapsed)
        case .timeZone:
            q.timeZoneJourney = DinoTimeZoneJourney.generate(language: language,
                difficulty: .init(minuteStep: minuteStep), using: &rng)
            q.offsetHours = q.timeZoneJourney!.offsetHours
            q.relatedTimes = [target.adding(minutes: -q.offsetHours * 60)]
            // Plausible mistakes: the given time and reversing the difference.
            q.options = Array(Set([q.relatedTimes[0], target.adding(minutes: -2 * q.offsetHours * 60),
                                   target.adding(minutes: 60), target.adding(minutes: -60)])
                .subtracting([target])).sorted { $0.minutesOfDay < $1.minutesOfDay }
                .shuffled(using: &rng).prefix(3).map { $0 }
            q.options.insert(target, at: Int.random(in: 0...q.options.count, using: &rng))
        default: preconditionFailure("Use the original clock generator for \(kind)")
        }
        return q
    }

    /// Forward clock turns stay within four hours. Minute practice mixes whole hours with leftover minutes.
    static func advanceDuration<R: RandomNumberGenerator>(minuteStep: Int, using rng: inout R) -> Int {
        if minuteStep >= 60 { return 60 * Int.random(in: 1...4, using: &rng) }
        let roll = Int.random(in: 0..<10, using: &rng)
        if roll < 2 {
            let steps = max(1, min(3, (60 / minuteStep) - 1))
            return minuteStep * Int.random(in: 1...steps, using: &rng)
        }
        if roll < 4 { return 60 * Int.random(in: 1...4, using: &rng) }
        let hours = Int.random(in: 1...3, using: &rng)
        let minutes = Array(stride(from: minuteStep, to: 60, by: minuteStep))
        return hours * 60 + minutes.randomElement(using: &rng)!
    }

    /// Easier flights keep a zero offset. Quarter hours and finer state a whole-hour difference.
    static func flightOffsetHours<R: RandomNumberGenerator>(minuteStep: Int, using rng: inout R) -> Int {
        if minuteStep >= 30 { return 0 }
        let choices = minuteStep >= 10 ? [1, -1, 2, -2] : [2, -2, 3, -3, 4, -4]
        return choices.randomElement(using: &rng)!
    }

    /// A zone change needs at least two extra flying hours, so two hours aloft never crosses four zones.
    static func flightDurationMinutes(offsetHours: Int, minuteStep: Int, extraSteps: Int) -> Int {
        let base = offsetHours == 0 ? 120 : (abs(offsetHours) + 2) * 60
        return base + minuteStep * extraSteps
    }

    static func example(kind: ClockQuestionKind, time: DinoPracticeTime) -> ClockQuestion {
        var rng = SeededGenerator(seed: 20261012)
        return generate(kind: kind, minutes: time.minutes, minuteStep: time.minuteStep,
                        index: 0, previousTarget: nil, isDemonstration: true, using: &rng)
    }
}

/// Examples follow the selected minute family, independently of the live question.
enum DinoDemonstrationExamples {
    static func time(index: Int, minutes: [Int], hours: Int = 12) -> ClockTime {
        let slots = minutes.sorted()
        precondition(!slots.isEmpty)
        let position = (index % (hours * slots.count) + 3 * slots.count) % (hours * slots.count)
        let hour = position / slots.count
        return ClockTime(hour: hours == 12 && hour == 0 ? 12 : hour, minute: slots[position % slots.count])
    }

    static func activity(index: Int) -> DinoActivity {
        // Start with the familiar three-o'clock fruit example, then cycle real activities.
        let activities: [DinoActivity] = [.fruit, .nest, .breakfast, .play, .lunch]
        return activities[index % activities.count]
    }

    static func question(kind: ClockQuestionKind, minutes: [Int], minuteStep: Int,
                         index: Int, previousTarget: ClockTime?, language: String = "nl") -> ClockQuestion {
        let sequential = [.readDigital, .spokenTime, .trueFalse, .dayPart, .read24Hour].contains(kind)
        let hours = [.readDigital, .spokenTime, .trueFalse].contains(kind) ? 12 : 24
        var rng = SeededGenerator(seed: 20261012 &+ UInt64(index))
        return DinoExpandedQuestions.generate(kind: kind, minutes: minutes, minuteStep: minuteStep,
                                              index: index, previousTarget: previousTarget,
                                              preferredTarget: sequential ? time(index: index, minutes: minutes, hours: hours) : nil,
                                              isDemonstration: true,
                                              language: language,
                                              using: &rng)
    }
}

/// A finite script of the same taps as the live analog controls, without a game session.
struct DinoAnalogSettingExample {
    enum Action: Equatable {
        case selectMinutes(Bool), adjust(Int), confirm
    }
    let target: ClockTime
    let minuteStep: Int
    let initialTime: ClockTime
    let actions: [Action]
    var initialHourAngle: Double { target.hourAngle + 180 }
    var initialMinuteAngle: Double { target.minuteAngle + (minuteStep < 60 ? 180 : 0) }

    init(target: ClockTime, minuteStep: Int, clockwise: Bool = true) {
        precondition(minuteStep == 60 || (minuteStep > 0 && 30.isMultiple(of: minuteStep)))
        self.target = target
        self.minuteStep = minuteStep
        initialTime = ClockTime(hour: ClockTime.shiftedHour(target.hour, by: 6),
                                minute: minuteStep < 60 ? ClockTime.shiftedMinute(target.minute, by: 30) : 0)
        var taps: [Action] = []
        if minuteStep < 60 {
            // Correct minutes first, without crossing twelve. The subsequent hour
            // taps therefore always finish at the target, including 12:xx.
            taps.append(.selectMinutes(true))
            let direction = target.minute < 30 ? -1 : 1
            taps += Array(repeating: .adjust(direction), count: 30 / minuteStep)
            taps.append(.selectMinutes(false))
        }
        taps += Array(repeating: .adjust(clockwise ? 1 : -1), count: 6)
        taps.append(.confirm)
        actions = taps
    }

    func applying(_ action: Action, to time: ClockTime, adjustingMinutes: Bool) -> ClockTime {
        Self.applying(action, to: time, adjustingMinutes: adjustingMinutes, minuteStep: minuteStep)
    }

    static func applying(_ action: Action, to time: ClockTime, adjustingMinutes: Bool, minuteStep: Int) -> ClockTime {
        guard case .adjust(let direction) = action else { return time }
        return adjustingMinutes ? time.shiftingMinutes(by: direction * minuteStep)
            : ClockTime(hour: ClockTime.shiftedHour(time.hour, by: direction), minute: time.minute)
    }

    static func continuingAngle(_ angle: Double, from previous: Double, direction: Int) -> Double {
        var delta = (angle - previous).truncatingRemainder(dividingBy: 360)
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        if abs(delta) == 180 { delta = Double(direction) * 180 }
        return previous + delta
    }
}

/// Turns the given clock forward by its duration, using the same hour and minute buttons as the question.
struct DinoAnalogAdvanceExample {
    let minuteStep: Int
    let durationMinutes: Int
    let start: ClockTime
    let target: ClockTime
    let actions: [DinoAnalogSettingExample.Action]

    init(question: ClockQuestion, minuteStep: Int) {
        precondition(minuteStep > 0 && 60.isMultiple(of: minuteStep))
        self.minuteStep = minuteStep
        durationMinutes = question.durationMinutes
        start = Self.face(question.relatedTimes[0])
        target = Self.face(question.target)
        let hours = durationMinutes / 60
        let extra = durationMinutes % 60
        var taps: [DinoAnalogSettingExample.Action] = Array(repeating: .adjust(1), count: hours)
        if extra > 0 {
            taps.append(.selectMinutes(true))
            taps += Array(repeating: .adjust(1), count: extra / minuteStep)
        }
        taps.append(.confirm)
        actions = taps
    }

    func applying(_ action: DinoAnalogSettingExample.Action, to time: ClockTime, adjustingMinutes: Bool) -> ClockTime {
        DinoAnalogSettingExample.applying(action, to: time, adjustingMinutes: adjustingMinutes, minuteStep: minuteStep)
    }

    static func face(_ time: ClockTime) -> ClockTime {
        ClockTime(hour: time.hour % 12 == 0 ? 12 : time.hour % 12, minute: time.minute)
    }
}

/// Subtract clock components with an explicit borrowed hour when minutes require it.
struct DinoMinuteDifference: Equatable, Sendable {
    let earlier: ClockTime
    let later: ClockTime

    init(_ first: ClockTime, _ second: ClockTime) {
        earlier = first.minutesOfDay <= second.minutesOfDay ? first : second
        later = first.minutesOfDay <= second.minutesOfDay ? second : first
    }

    var borrowsHour: Bool { later.minute < earlier.minute }
    var hours: Int { later.hour - earlier.hour - (borrowsHour ? 1 : 0) }
    var minutes: Int { later.minute + (borrowsHour ? 60 : 0) - earlier.minute }
    var totalMinutes: Int { hours * 60 + minutes }
}

enum DinoTimeWords {
    static func time(_ time: ClockTime, language: String, dayPart: Bool = false) -> String {
        let nl = language == "nl"
        let numbers = nl ? ["twaalf", "een", "twee", "drie", "vier", "vijf", "zes", "zeven", "acht", "negen", "tien", "elf"]
                         : ["twelve", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven"]
        let hour = numbers[time.hour % 12], next = numbers[(time.hour + 1) % 12]
        let text: String
        if nl {
            switch time.minute {
            case 0: text = "\(hour) uur"
            case 5: text = "vijf over \(hour)"
            case 10: text = "tien over \(hour)"
            case 15: text = "kwart over \(hour)"
            case 20: text = "tien voor half \(next)"
            case 25: text = "vijf voor half \(next)"
            case 30: text = "half \(next)"
            case 35: text = "vijf over half \(next)"
            case 40: text = "tien over half \(next)"
            case 45: text = "kwart voor \(next)"
            case 50: text = "tien voor \(next)"
            case 55: text = "vijf voor \(next)"
            default: text = "\(time.minute) minuten over \(hour)"
            }
        } else {
            switch time.minute {
            case 0: text = "\(hour) o’clock"
            case 15: text = "quarter past \(hour)"
            case 30: text = "half past \(hour)"
            case 45: text = "quarter to \(next)"
            case 1..<30: text = "\(time.minute) minutes past \(hour)"
            default: text = "\(60 - time.minute) minutes to \(next)"
            }
        }
        guard dayPart else { return text }
        let part = DinoDayPart(hour: time.hour)
        let suffix: String
        switch part {
        case .night: suffix = nl ? "’s nachts" : "at night"
        case .morning: suffix = nl ? "’s ochtends" : "in the morning"
        case .afternoon: suffix = nl ? "’s middags" : "in the afternoon"
        case .evening: suffix = nl ? "’s avonds" : "in the evening"
        }
        return "\(text) \(suffix)"
    }
    static func minutes(_ value: Int, language: String) -> String {
        let unit = language == "nl" ? (value == 1 ? "minuut" : "minuten") : (value == 1 ? "minute" : "minutes")
        return "\(value) \(unit)"
    }
    static func duration(_ minutes: Int, language: String) -> String {
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m) min" }
        return m == 0 ? "\(h) \(language == "nl" ? "uur" : "h")" : "\(h) \(language == "nl" ? "uur" : "h") \(m) min"
    }

    static func hourDifference(_ hours: Int, language: String) -> String {
        let sign = hours >= 0 ? "+" : "−"
        return "\(sign)\(abs(hours)) \(language == "nl" ? "uur" : "h")"
    }
}

/// Flight duration and the time-zone difference are combined first. That one shift is then added to the departure.
struct DinoFlightArrivalWork: Equatable {
    let departure: ClockTime
    let durationMinutes: Int
    let offsetHours: Int
    let arrival: ClockTime

    var combinedMinutes: Int { durationMinutes + offsetHours * 60 }
    /// Time after the flight duration alone, before the zone difference is included.
    var afterDuration: ClockTime { departure.adding(minutes: durationMinutes) }
    var zoneSign: String { offsetHours >= 0 ? "+" : "−" }

    func durationText(_ language: String) -> String {
        DinoTimeWords.duration(durationMinutes, language: language)
    }

    func zoneText(_ language: String) -> String {
        DinoTimeWords.duration(abs(offsetHours) * 60, language: language)
    }

    func combinedText(_ language: String) -> String {
        DinoTimeWords.duration(combinedMinutes, language: language)
    }

    func differenceLine(language: String) -> String {
        "\(durationText(language)) \(zoneSign) \(zoneText(language)) = \(combinedText(language))"
    }

    func arrivalLine(language: String) -> String {
        let shift = offsetHours == 0 ? durationText(language) : combinedText(language)
        return "\(departure.digitalText) + \(shift) = \(arrival.digitalText)"
    }

    /// Whole hours first, then the leftover minutes in the question's own minute steps.
    func walkMinutes(step: Int) -> [Int] {
        let magnitude = abs(combinedMinutes)
        guard magnitude > 0 else { return [] }
        let sign = combinedMinutes > 0 ? 1 : -1
        let hours = magnitude / 60
        let minutes = magnitude % 60
        let minuteStep = max(1, step)
        var steps: [Int] = []
        if hours > 0 { steps.append(contentsOf: (1...hours).map { sign * $0 * 60 }) }
        var covered = 0
        while covered < minutes {
            covered = min(minutes, covered + minuteStep)
            steps.append(sign * (hours * 60 + covered))
        }
        return steps
    }
}
