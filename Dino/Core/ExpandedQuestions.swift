import Foundation

enum DinoDayPart: String, CaseIterable, Sendable {
    case night, morning, afternoon, evening
    init(hour: Int, schedule: DinoDayPartSchedule = .standard) {
        self = schedule.part(at: hour)
    }
    var titleKey: String { "dino.dayPart.\(rawValue)" }
    func next() -> DinoDayPart {
        switch self {
        case .night: return .morning
        case .morning: return .afternoon
        case .afternoon: return .evening
        case .evening: return .night
        }
    }
    func previous() -> DinoDayPart {
        switch self {
        case .night: return .evening
        case .morning: return .night
        case .afternoon: return .morning
        case .evening: return .afternoon
        }
    }
    var symbol: String {
        switch self {
        case .night: return "moon.stars.fill"
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        }
    }
}

/// The four parts of the day, in clock order, covering every hour exactly once.
/// A part may cross midnight: night from 22:00 until 06:00 is one part.
struct DinoDayPartSchedule: Equatable, Sendable {
    var night: Int
    var morning: Int
    var afternoon: Int
    var evening: Int

    static let standard = DinoDayPartSchedule(night: 0, morning: 6, afternoon: 12, evening: 18)

    struct Segment: Equatable, Sendable {
        let part: DinoDayPart
        /// Inclusive start hour on the 00:00–24:00 line.
        let start: Int
        /// Exclusive end hour, at most 24.
        let end: Int

        func contains(_ time: ClockTime) -> Bool {
            let minute = time.minutesOfDay
            return minute >= start * 60 && minute < end * 60
        }
    }

    func start(of part: DinoDayPart) -> Int {
        switch part {
        case .night: return night
        case .morning: return morning
        case .afternoon: return afternoon
        case .evening: return evening
        }
    }

    mutating func setStart(_ part: DinoDayPart, _ hour: Int) {
        switch part {
        case .night: night = hour
        case .morning: morning = hour
        case .afternoon: afternoon = hour
        case .evening: evening = hour
        }
    }

    /// The hour this part ends. Midnight at the end of the clock is 24.
    func endClock(of part: DinoDayPart) -> Int {
        let next = start(of: part.next())
        return next == 0 ? 24 : next
    }

    func length(of part: DinoDayPart) -> Int {
        (start(of: part.next()) - start(of: part) + 24) % 24
    }

    var isValid: Bool {
        let starts = [night, morning, afternoon, evening]
        guard starts.allSatisfy({ (0..<24).contains($0) }), Set(starts).count == 4 else { return false }
        let toMorning = forward(night, morning)
        let toAfternoon = forward(night, afternoon)
        let toEvening = forward(night, evening)
        return toMorning < toAfternoon && toAfternoon < toEvening
    }

    func part(at hour: Int) -> DinoDayPart {
        let hour = ((hour % 24) + 24) % 24
        for part in DinoDayPart.allCases where forward(start(of: part), hour) < length(of: part) {
            return part
        }
        return .night
    }

    /// One boundary at a time, each set straight to its hour in `target`, as the settings menus allow.
    func edits(to target: DinoDayPartSchedule) -> [(part: DinoDayPart, hour: Int)]? {
        if self == target { return [] }
        guard isValid, target.isValid else { return nil }
        var queue: [(DinoDayPartSchedule, [(DinoDayPart, Int)])] = [(self, [])]
        var seen: Set<String> = [storageKey]
        var head = 0
        while head < queue.count {
            let (current, path) = queue[head]
            head += 1
            for part in DinoDayPart.allCases {
                let hour = target.start(of: part)
                guard current.start(of: part) != hour, current.validStarts(for: part).contains(hour) else { continue }
                var next = current
                next.setStart(part, hour)
                guard seen.insert(next.storageKey).inserted else { continue }
                let steps = path + [(part: part, hour: hour)]
                if next == target { return steps }
                queue.append((next, steps))
            }
        }
        return nil
    }

    /// Start hours that keep every part at least one hour long, in clock order.
    func validStarts(for part: DinoDayPart) -> [Int] {
        let anchor = start(of: part.previous())
        return (0..<24).filter { hour in
            var copy = self
            copy.setStart(part, hour)
            return copy.isValid
        }.sorted { forward(anchor, $0) < forward(anchor, $1) }
    }

    /// Pieces of the 00:00–24:00 line. A part that crosses midnight appears at both ends.
    func timeline() -> [Segment] {
        var segments: [Segment] = []
        var hour = 0
        while hour < 24 && segments.count < 8 {
            let part = part(at: hour)
            let next = start(of: part.next())
            let end = next == 0 || next <= hour ? 24 : next
            guard end > hour else { break }
            segments.append(Segment(part: part, start: hour, end: end))
            hour = end
        }
        return segments
    }

    var storageKey: String { "\(night),\(morning),\(afternoon),\(evening)" }

    var summary: String {
        DinoDayPart.allCases.map { part in
            "\(Self.hourText(start(of: part)))–\(Self.hourText(endClock(of: part)))"
        }.joined(separator: " · ")
    }

    func clockText(startOf part: DinoDayPart) -> String {
        String(format: "%02d:00", start(of: part))
    }

    func clockText(endOf part: DinoDayPart) -> String {
        String(format: "%02d:00", endClock(of: part))
    }

    static func hourText(_ hour: Int) -> String { String(format: "%02d", hour) }

    init(night: Int, morning: Int, afternoon: Int, evening: Int) {
        self.night = night
        self.morning = morning
        self.afternoon = afternoon
        self.evening = evening
    }

    init?(storageKey: String) {
        let parts = storageKey.split(separator: ",").compactMap { Int($0) }
        guard parts.count == 4 else { return nil }
        self.init(night: parts[0], morning: parts[1], afternoon: parts[2], evening: parts[3])
        guard isValid else { return nil }
    }

    private func forward(_ from: Int, _ to: Int) -> Int { (to - from + 24) % 24 }
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
    var hasMinuteTerms: Bool { durations.contains { !$0.isMultiple(of: 60) } }
    var writtenDuration: (hours: Int, minutes: Int) {
        (durations.reduce(0) { $0 + $1 / 60 }, durations.reduce(0) { $0 + $1 % 60 })
    }

    /// Add the units as written on each leg before carrying sixty minutes into an hour.
    func summedDurationText(language: String) -> String {
        DinoTimeWords.compactDuration(hours: writtenDuration.hours, minutes: writtenDuration.minutes,
                                      language: language, padMinutes: hasMinuteTerms)
    }

    /// Keep both replay units visible from zero whenever the worked sum uses them.
    func addedDurationText(_ appliedMinutes: Int, language: String) -> String {
        var units: [String] = []
        if totalMinutes >= 60 {
            units.append(language == "nl" ? "\(appliedMinutes / 60) uur" : "\(appliedMinutes / 60)h")
        }
        if hasMinuteTerms { units.append(String(format: "%02d min", appliedMinutes % 60)) }
        return "+" + units.joined(separator: " ")
    }

    /// Count forward by whole hours, then add the remaining minutes in one readable step.
    func walkMinutes() -> [Int] {
        guard totalMinutes > 0 else { return [] }
        let wholeHours = totalMinutes / 60 * 60
        var steps = Array(stride(from: 60, through: wholeHours, by: 60))
        if steps.last != totalMinutes { steps.append(totalMinutes) }
        return steps
    }
}

enum DinoExpandedQuestions {
    static func generate<R: RandomNumberGenerator>(kind: ClockQuestionKind, time: DinoPracticeTime,
                                                   index: Int, previousTarget: ClockTime?, language: String = "nl",
                                                   difficulty: DinoQuestionDifficulty = .challenge,
                                                   dayPartSchedule: DinoDayPartSchedule = .standard,
                                                   recentQuestions: [ClockQuestion] = [],
                                                   using rng: inout R) -> ClockQuestion {
        generate(kind: kind, minutes: time.minutes, minuteStep: time.minuteStep,
                 index: index, previousTarget: previousTarget, language: language, difficulty: difficulty,
                 dayPartSchedule: dayPartSchedule, recentQuestions: recentQuestions, using: &rng)
    }

    static func generate<R: RandomNumberGenerator>(kind: ClockQuestionKind, minutes: [Int], minuteStep: Int,
                                                   index: Int, previousTarget: ClockTime?, preferredTarget: ClockTime? = nil,
                                                   isDemonstration: Bool = false,
                                                   language: String = "nl",
                                                   difficulty: DinoQuestionDifficulty = .challenge,
                                                   dayPartSchedule: DinoDayPartSchedule = .standard,
                                                   recentQuestions: [ClockQuestion] = [],
                                                   using rng: inout R) -> ClockQuestion {
        let family = DinoPracticeTime.allCases.first { $0.minuteStep == minuteStep } ?? .minutes
        let step = minuteStep
        let arithmeticLimit = difficulty == .introduction ? step : difficulty == .familiar ? 90 : 240
        let sequenceLimit = difficulty == .challenge ? 90 : arithmeticLimit
        let durations = Array(stride(from: step, through: max(step, kind == .timeSequence ? sequenceLimit : arithmeticLimit), by: step))
        let duration = DinoQuestionTeaching.varied(durations, recent: recentQuestions.map(\.durationMinutes), using: &rng)
        let scheduleDurations: [Int]
        if kind == .daySchedule {
            let legLimit = difficulty == .introduction ? max(20, step) : difficulty == .familiar ? 90 : 150
            let legs = Array(stride(from: max(step, ((10 + step - 1) / step) * step), through: max(step, legLimit), by: step))
            let transfers = Array(stride(from: step, through: max(step, 30), by: step))
            scheduleDurations = [
                DinoQuestionTeaching.varied(legs, recent: recentQuestions.compactMap { $0.daySchedule?.firstMinutes }, using: &rng),
                DinoQuestionTeaching.varied(transfers, recent: recentQuestions.compactMap { $0.daySchedule?.breakMinutes }, using: &rng),
                DinoQuestionTeaching.varied(legs, recent: recentQuestions.compactMap { $0.daySchedule?.secondMinutes }, using: &rng)
            ]
        } else { scheduleDurations = [] }
        let zoneJourney = kind == .timeZone ? DinoTimeZoneJourney.generate(language: language,
            difficulty: difficulty == .introduction ? .nearby : difficulty == .familiar ? .regional : .worldwide,
            minuteStep: step, recentDestinations: recentQuestions.compactMap { $0.timeZoneJourney?.destination.id }, using: &rng) : nil
        var flightOffsets = difficulty == .familiar ? [60, -60] : [120, -120, 180, -180, 240, -240]
        // Half-hour differences are occasional, and only used when both clocks stay on the selected grid.
        if difficulty == .challenge && 30.isMultiple(of: step) { flightOffsets += [210, -210] }
        let flightOffset = kind == .flightArrival && difficulty != .introduction
            ? DinoQuestionTeaching.varied(flightOffsets, recent: recentQuestions.map(\.offsetMinutes), using: &rng) : 0
        let flightDuration = kind == .flightArrival
            ? Self.flightDurationMinutes(offsetMinutes: flightOffset, minuteStep: step,
                extraSteps: Int.random(in: 0...max(1, (difficulty == .introduction ? 60 : 180) / step), using: &rng)) : 0
        let shift: Int
        switch kind {
        case .addTime, .advanceAnalog: shift = duration
        case .subtractTime: shift = -duration
        case .timeSequence: shift = 3 * duration
        case .flightArrival: shift = flightDuration + flightOffset
        case .timeZone: shift = zoneJourney!.offsetMinutes
        default: shift = 0
        }
        let hours = [.readDigital, .spokenTime, .trueFalse, .sayTime].contains(kind) ? Array(1...12) : Array(0...23)
        let spoken = kind == .sayTime ? SpokenTimeCatalog.language(code: language) : nil
        let pool = hours.flatMap { hour in minutes.map { ClockTime(hour: hour, minute: $0) } }
            .filter { time in
                if kind == .sayTime { return spoken!.supports(minute: time.minute) }
                // The built-in timetable leaves 06:00 and 22:00–23:59 unasked, because schools disagree there.
                // A timetable chosen in Settings defines those hours, so practice includes them.
                if kind == .dayPart && !isDemonstration && dayPartSchedule == .standard {
                    return time.hour != 6 && time.hour < 22
                }
                if kind == .sortTimes { return time.minutesOfDay != 0 }
                if kind == .minutesBetween { return time.minutesOfDay >= 60 + (minutes.min() ?? 0) }
                if kind == .daySchedule {
                    return time.minutesOfDay >= 6 * 60 + scheduleDurations.reduce(0, +)
                        && time.minutesOfDay <= 22 * 60
                }
                return true
            }
        var targets = pool
        if !isDemonstration && difficulty != .challenge {
            let noMidnight = targets.filter { (0..<1440).contains($0.minutesOfDay - shift) }
            if !noMidnight.isEmpty { targets = noMidnight }
            if difficulty == .introduction && recentQuestions.isEmpty && shift != 0 && abs(shift) < 60 {
                let sameHour = targets.filter { $0.hour == $0.adding(minutes: -shift).hour }
                if !sameHour.isEmpty { targets = sameHour }
            }
        }
        if kind == .dayPart && !recentQuestions.isEmpty {
            // A custom day part can contain just one whole hour. Exclude the
            // previous answer before balancing parts, so that part cannot force a repeat.
            let fresh = targets.filter { $0 != previousTarget }
            if !fresh.isEmpty { targets = fresh }
            let counts = Dictionary(grouping: recentQuestions) { dayPartSchedule.part(at: $0.target.hour) }.mapValues(\.count)
            let minimum = targets.map { counts[dayPartSchedule.part(at: $0.hour), default: 0] }.min()!
            targets = targets.filter { counts[dayPartSchedule.part(at: $0.hour), default: 0] == minimum }
        }
        let target = preferredTarget.flatMap { pool.contains($0) ? $0 : nil }
            ?? DinoQuestionTeaching.target(pool: targets, time: family, difficulty: difficulty, previous: previousTarget,
                recent: recentQuestions.map(\.target), using: &rng)
        let operation: Int
        switch kind {
        case .timeSequence: operation = duration
        default: operation = shift
        }
        let other = kind == .readDigital
            ? DinoTimeReading.distractors(target: target, minuteStep: step, using: &rng)
            : DinoQuestionTeaching.distractors(pool: pool, target: target, kind: kind, difficulty: difficulty,
                                               minuteStep: step, operation: operation, using: &rng)
        let count = difficulty.optionCount
        var choices = Array(other.prefix(count - 1))
        choices.insert(target, at: Int.random(in: 0..<count, using: &rng))
        var q = ClockQuestion(id: index, kind: kind, target: target, options: choices,
                              activity: nil, companionClocks: Array(other.prefix(2)))
        q.difficulty = difficulty
        q.timeFamily = family
        switch kind {
        case .readDigital, .spokenTime, .read24Hour: break
        case .sayTime:
            q.options = []
            q.spokenPrompt = SpokenTimeCatalog.language(code: language).prompt(for: target, using: &rng)
            q.answer = .spoken(q.spokenPrompt!.correct)
        case .trueFalse:
            let recentTruths = recentQuestions.compactMap { question -> Bool? in
                if case .truth(let value) = question.expectedAnswer { return value }; return nil
            }
            let truthful = DinoQuestionTeaching.varied([true, false], recent: recentTruths, using: &rng)
            q.statement = truthful ? target : other[0]
            q.options = []; q.answerChoices = [.truth(true), .truth(false)]; q.answer = .truth(truthful)
        case .dayPart:
            q.options = []; q.answerChoices = DinoDayPart.allCases.map(ClockAnswer.dayPart)
            q.answer = .dayPart(.init(hour: target.hour, schedule: dayPartSchedule))
        case .sortTimes:
            q.options = ([target] + Array(other.prefix(3))).shuffled(using: &rng)
            q.answer = .ordering(q.options.sorted { $0.minutesOfDay < $1.minutesOfDay })
        case .timeSequence:
            q.durationMinutes = duration
            q.relatedTimes = [target.adding(minutes: -3 * duration), target.adding(minutes: -2 * duration), target.adding(minutes: -duration)]
        case .addTime, .advanceAnalog:
            q.durationMinutes = duration
            q.relatedTimes = [target.adding(minutes: -q.durationMinutes)]
            if kind == .advanceAnalog { q.options = [] }
        case .subtractTime:
            q.durationMinutes = duration; q.relatedTimes = [target.adding(minutes: duration)]
        case .flightArrival:
            // Introduce flight duration before combining it with a zone difference.
            q.offsetMinutes = flightOffset
            q.durationMinutes = flightDuration
            q.relatedTimes = [target.adding(minutes: -(q.durationMinutes + q.offsetMinutes))]
            if q.offsetMinutes != 0 {
                let forgotten = target.adding(minutes: -q.offsetMinutes)
                let reversed = target.adding(minutes: q.offsetMinutes)
                let nudged = target.adding(minutes: q.offsetMinutes > 0 ? 60 : -60)
                let slipped = [target.adding(minutes: -step), target.adding(minutes: step)]
                var seen: Set<ClockTime> = [target]
                var distractors = ([forgotten, reversed, nudged] + slipped).filter { seen.insert($0).inserted }
                for candidate in other where distractors.count < count - 1 && seen.insert(candidate).inserted {
                    distractors.append(candidate)
                }
                q.options = (Array(distractors.prefix(count - 1)) + [target]).shuffled(using: &rng)
            }
        case .daySchedule:
            let activities = DinoScheduleActivity.allCases.shuffled(using: &rng)
            let schedule = DinoDaySchedule(start: target.adding(minutes: -scheduleDurations.reduce(0, +)),
                firstActivity: activities[0], firstMinutes: scheduleDurations[0],
                breakMinutes: scheduleDurations[1], secondActivity: activities[1], secondMinutes: scheduleDurations[2])
            q.daySchedule = schedule
            q.durationMinutes = schedule.totalMinutes
            q.relatedTimes = [schedule.start]
            // Stopping after the first activity, skipping the transfer, or leaving before the second activity.
            let candidates = [schedule.firstEnd, target.adding(minutes: -step),
                              target.adding(minutes: -schedule.breakMinutes), target.adding(minutes: step),
                              schedule.secondStart, target.adding(minutes: -schedule.firstMinutes), schedule.start,
                              target.adding(minutes: -60), target.adding(minutes: 60)] + other
            var seen: Set<ClockTime> = [target]
            let distractors = candidates.filter { minutes.contains($0.minute) && seen.insert($0).inserted }
            q.options = (Array(distractors.prefix(count - 1)) + [target]).shuffled(using: &rng)
        case .minutesBetween:
            let maxGap = difficulty == .introduction ? step : difficulty == .familiar ? 90 : 180
            let starts = (1...min(maxGap, target.minutesOfDay))
                .map { target.adding(minutes: -$0) }
                .filter { minutes.contains($0.minute) }
            let elapsedOptions = starts.map { target.minutesOfDay - $0.minutesOfDay }
            let selectedGap = DinoQuestionTeaching.varied(elapsedOptions, recent: recentQuestions.map(\.durationMinutes), using: &rng)
            let start = target.adding(minutes: -selectedGap)
            let elapsed = target.minutesOfDay - start.minutesOfDay
            q.relatedTimes = [start, target]
            q.durationMinutes = elapsed
            // A missed step, a forgotten hour, or the minutes left after a missed borrow.
            let gap = minuteStep
            let minuteGap = abs(target.minute - start.minute)
            let hourGap = abs(target.hour - start.hour) * 60
            var slips = [minuteGap, hourGap, elapsed % 60]
            if start.hour != target.hour || elapsed >= 60 {
                slips += [elapsed + 60, elapsed - 60]
            }
            let nearby = (1...6).flatMap { [elapsed + $0 * gap, elapsed - $0 * gap] }
            var seen: Set<Int> = [elapsed]
            func accept(_ values: [Int]) -> [Int] {
                values.filter { $0 > 0 && $0.isMultiple(of: gap) && seen.insert($0).inserted }
            }
            let primary = accept([elapsed - gap, elapsed + gap, elapsed - 2 * gap, elapsed + 2 * gap])
                .sorted { abs($0 - elapsed) == abs($1 - elapsed) ? $0 < $1 : abs($0 - elapsed) < abs($1 - elapsed) }
            let tricks = accept(slips).sorted { abs($0 - elapsed) == abs($1 - elapsed) ? $0 < $1 : abs($0 - elapsed) < abs($1 - elapsed) }
            let rest = accept(nearby)
            let lead = difficulty == .challenge ? tricks : primary
            let follow = difficulty == .challenge ? primary : tricks
            var distractors: [Int] = []
            for index in 0..<max(lead.count, follow.count) {
                if index < lead.count { distractors.append(lead[index]) }
                if index < follow.count { distractors.append(follow[index]) }
            }
            distractors += rest
            q.options = []
            q.answerChoices = (Array(distractors.prefix(count - 1)) + [elapsed])
                .shuffled(using: &rng).map(ClockAnswer.duration)
            q.answer = .duration(elapsed)
        case .timeZone:
            q.timeZoneJourney = zoneJourney
            q.offsetMinutes = q.timeZoneJourney!.offsetMinutes
            q.relatedTimes = [target.adding(minutes: -q.offsetMinutes)]
            // Plausible mistakes: the given time and reversing the difference.
            q.options = Array(Set([q.relatedTimes[0], target.adding(minutes: -2 * q.offsetMinutes),
                                   target.adding(minutes: 60), target.adding(minutes: -60)])
                .subtracting([target])).sorted { $0.minutesOfDay < $1.minutesOfDay }
                .shuffled(using: &rng).prefix(count - 1).map { $0 }
            q.options.insert(target, at: Int.random(in: 0...q.options.count, using: &rng))
        default: preconditionFailure("Use the original clock generator for \(kind)")
        }
        return q
    }

    /// A zone change needs at least two extra flying hours, so two hours aloft never crosses four zones.
    static func flightDurationMinutes(offsetMinutes: Int, minuteStep: Int, extraSteps: Int) -> Int {
        let base = offsetMinutes == 0 ? 120 : ((abs(offsetMinutes) + 59) / 60 + 2) * 60
        return base + minuteStep * extraSteps
    }

    static func example(kind: ClockQuestionKind, time: DinoPracticeTime,
                        dayPartSchedule: DinoDayPartSchedule = .standard) -> ClockQuestion {
        var rng = SeededGenerator(seed: 20261012)
        return generate(kind: kind, minutes: time.minutes, minuteStep: time.minuteStep,
                        index: 0, previousTarget: nil, isDemonstration: true, difficulty: .introduction,
                        dayPartSchedule: dayPartSchedule, using: &rng)
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
                         index: Int, previousTarget: ClockTime?, language: String = "nl",
                         dayPartSchedule: DinoDayPartSchedule = .standard) -> ClockQuestion {
        let sequential = [.readDigital, .spokenTime, .trueFalse, .dayPart, .read24Hour].contains(kind)
        let hours = [.readDigital, .spokenTime, .trueFalse].contains(kind) ? 12 : 24
        var rng = SeededGenerator(seed: 20261012 &+ UInt64(index))
        return DinoExpandedQuestions.generate(kind: kind, minutes: minutes, minuteStep: minuteStep,
                                              index: index, previousTarget: previousTarget,
                                              preferredTarget: sequential ? time(index: index, minutes: minutes, hours: hours) : nil,
                                              isDemonstration: true,
                                              language: language, difficulty: .introduction,
                                              dayPartSchedule: dayPartSchedule,
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

    /// Minutes the player moved from the given start to the clock they set, on a 12-hour face.
    /// The shorter direction is used, so going back reads as a negative deviation.
    static func enteredMinutes(from start: ClockTime, to answer: ClockTime) -> Int {
        func minutes(_ time: ClockTime) -> Int {
            let shown = face(time)
            return (shown.hour % 12) * 60 + shown.minute
        }
        var delta = minutes(answer) - minutes(start)
        if delta > 6 * 60 { delta -= 12 * 60 }
        if delta <= -6 * 60 { delta += 12 * 60 }
        return delta
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
    static func time(_ time: ClockTime, language: String, dayPart: Bool = false,
                      schedule: DinoDayPartSchedule = .standard) -> String {
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
            case 1..<15: text = "\(minutes(time.minute, language: language)) over \(hour)"
            case 16..<30: text = "\(minutes(30 - time.minute, language: language)) voor half \(next)"
            case 31..<45: text = "\(minutes(time.minute - 30, language: language)) over half \(next)"
            default: text = "\(minutes(60 - time.minute, language: language)) voor \(next)"
            }
        } else {
            switch time.minute {
            case 0: text = "\(hour) o’clock"
            case 15: text = "quarter past \(hour)"
            case 30: text = "half past \(hour)"
            case 45: text = "quarter to \(next)"
            case 1..<30: text = "\(minutes(time.minute, language: language)) past \(hour)"
            default: text = "\(minutes(60 - time.minute, language: language)) to \(next)"
            }
        }
        guard dayPart else { return text }
        return "\(text) \(dayPartSuffix(time, language: language, schedule: schedule))"
    }

    static func dayPartSuffix(_ time: ClockTime, language: String, schedule: DinoDayPartSchedule = .standard) -> String {
        let nl = language == "nl"
        let part = DinoDayPart(hour: time.hour, schedule: schedule)
        switch part {
        case .night: return nl ? "’s nachts" : "at night"
        case .morning: return nl ? "’s ochtends" : "in the morning"
        case .afternoon: return nl ? "’s middags" : "in the afternoon"
        case .evening: return nl ? "’s avonds" : "in the evening"
        }
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

    /// Elapsed hours and minutes; independent of the clock's 12/24-hour notation.
    static func digitalDuration(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    /// Short units also support a written sum whose minutes have not been carried yet.
    static func compactDuration(hours: Int, minutes: Int, language: String, padMinutes: Bool = false) -> String {
        let minuteText = padMinutes ? String(format: "%02d", minutes) : String(minutes)
        guard hours > 0 else { return "\(minuteText) min" }
        let hoursText = language == "nl" ? "\(hours) uur" : "\(hours)h"
        return minutes == 0 && !padMinutes ? hoursText : "\(hoursText) \(minuteText) min"
    }

    /// A clock time for a spoken title. Afternoon and night stay distinct from the morning hour.
    static func promptTime(_ time: ClockTime, language: String) -> String {
        Self.time(time, language: language, dayPart: time.hour == 0 || time.hour > 12)
    }

    /// Hours and minutes in words, so a title can be read aloud.
    static func spokenDuration(_ minutes: Int, language: String) -> String {
        let hours = abs(minutes) / 60
        let mins = abs(minutes) % 60
        let dutch = language == "nl"
        func hoursText(_ value: Int) -> String {
            if dutch { return "\(value) uur" }
            return value == 1 ? "1 hour" : "\(value) hours"
        }
        func minutesText(_ value: Int) -> String {
            if dutch { return value == 1 ? "1 minuut" : "\(value) minuten" }
            return value == 1 ? "1 minute" : "\(value) minutes"
        }
        if hours == 0 { return minutesText(mins) }
        if mins == 0 { return hoursText(hours) }
        return dutch ? "\(hoursText(hours)) en \(minutesText(mins))" : "\(hoursText(hours)) and \(minutesText(mins))"
    }

    static func hourDifference(_ hours: Int, language: String) -> String {
        let sign = hours >= 0 ? "+" : "−"
        return "\(sign)\(abs(hours)) \(language == "nl" ? "uur" : "h")"
    }

    /// Compact hour labels preserve the half hour instead of truncating it.
    static func zoneHours(_ minutes: Int) -> String {
        let hours = abs(minutes) / 60
        return abs(minutes).isMultiple(of: 60) ? "\(hours)" : "\(hours == 0 ? "" : String(hours))½"
    }

    static func zoneDifference(_ minutes: Int, language: String) -> String {
        "\(minutes >= 0 ? "+" : "−")\(zoneHours(minutes)) \(language == "nl" ? "uur" : "h")"
    }
}

/// Flight duration and the time-zone difference are combined first. That one shift is then added to the departure.
struct DinoFlightArrivalWork: Equatable {
    let departure: ClockTime
    let durationMinutes: Int
    let offsetMinutes: Int
    let arrival: ClockTime

    var combinedMinutes: Int { durationMinutes + offsetMinutes }
    /// Time after the flight duration alone, before the zone difference is included.
    var afterDuration: ClockTime { departure.adding(minutes: durationMinutes) }
    var zoneSign: String { offsetMinutes >= 0 ? "+" : "−" }

    func durationText(_ language: String) -> String {
        DinoTimeWords.duration(durationMinutes, language: language)
    }

    func zoneText(_ language: String) -> String {
        DinoTimeWords.duration(abs(offsetMinutes), language: language)
    }

    func combinedText(_ language: String) -> String {
        DinoTimeWords.duration(combinedMinutes, language: language)
    }

    func differenceLine(language: String) -> String {
        "\(durationText(language)) \(zoneSign) \(zoneText(language)) = \(combinedText(language))"
    }

    func arrivalLine(language: String) -> String {
        let shift = offsetMinutes == 0 ? durationText(language) : combinedText(language)
        return "\(departure.digitalText) + \(shift) = \(arrival.digitalText)"
    }

    /// Whole hours, then one short minute correction, as in the time-zone example.
    func walkMinutes() -> [Int] {
        DinoTimeZoneStep.steps(from: departure, offsetMinutes: combinedMinutes).map(\.addedMinutes)
    }
}

enum DinoClockOperation: Equatable, Sendable {
    case add, subtract
    var symbol: String { self == .add ? "+" : "−" }
    func apply(_ lhs: Int, _ rhs: Int) -> Int { self == .add ? lhs + rhs : lhs - rhs }
}

/// One written sum. A follow-up starts with the previous result, the same digit beside it.
struct DinoClockSum: Equatable, Sendable {
    var terms: [Int]
    var operation: DinoClockOperation
    var result: Int
    var reusesFirstTerm: Bool

    var equation: String {
        let body = terms.map(DinoClockArithmetic.format).joined(separator: " \(operation.symbol) ")
        return "\(body) = \(DinoClockArithmetic.format(result))"
    }
}

/// The hour column or the minute column. No sum is stored when that part of the clock does not change.
struct DinoClockColumnWork: Equatable, Sendable {
    var sums: [DinoClockSum]
    var passthrough: Int?
    var result: Int { sums.last?.result ?? passthrough ?? 0 }
}

/// Splits adding or subtracting a duration into the hour sum and the minute sum.
/// A second sum appears only when the first result does not fit on a clock, and it reuses that result.
struct DinoClockArithmetic: Equatable, Sendable {
    var start: ClockTime
    var adding: Bool
    var differenceHours: Int
    var differenceMinutes: Int
    var hours: DinoClockColumnWork
    var minutes: DinoClockColumnWork

    var difference: ClockTime { ClockTime(hour: differenceHours, minute: differenceMinutes) }
    var result: ClockTime { ClockTime(hour: hours.result, minute: minutes.result) }
    var crossesMidnight: Bool { hours.sums.contains { $0.terms.contains(24) } }

    init(start: ClockTime, durationMinutes: Int, adding: Bool) {
        let duration = max(0, durationMinutes)
        self.start = start
        self.adding = adding
        differenceHours = duration / 60
        differenceMinutes = duration % 60

        let minuteOperation: DinoClockOperation = adding ? .add : .subtract
        if differenceMinutes == 0 {
            minutes = DinoClockColumnWork(sums: [], passthrough: start.minute)
        } else {
            let raw = minuteOperation.apply(start.minute, differenceMinutes)
            var sums = [DinoClockSum(terms: [start.minute, differenceMinutes], operation: minuteOperation,
                                     result: raw, reusesFirstTerm: false)]
            if adding && raw >= 60 {
                sums.append(DinoClockSum(terms: [raw, 60], operation: .subtract, result: raw - 60, reusesFirstTerm: true))
            } else if !adding && raw < 0 {
                sums.append(DinoClockSum(terms: [raw, 60], operation: .add, result: raw + 60, reusesFirstTerm: true))
            }
            minutes = DinoClockColumnWork(sums: sums, passthrough: nil)
        }

        let hourOperation: DinoClockOperation = adding ? .add : .subtract
        var adjustments: [Int] = []
        if differenceHours > 0 { adjustments.append(differenceHours) }
        // A minute carry keeps the hour column as long as the minute column, even when the hours themselves are 0.
        if minutes.sums.count == 2 {
            if adjustments.isEmpty { adjustments.append(0) }
            adjustments.append(1)
        }
        var value = start.hour
        var sums: [DinoClockSum] = []
        for adjustment in adjustments {
            let next = hourOperation.apply(value, adjustment)
            sums.append(DinoClockSum(terms: [value, adjustment], operation: hourOperation,
                                     result: next, reusesFirstTerm: !sums.isEmpty))
            value = next
        }
        if adding && value >= 24 {
            sums.append(DinoClockSum(terms: [value, 24], operation: .subtract, result: value - 24, reusesFirstTerm: !sums.isEmpty))
        } else if !adding && value < 0 {
            sums.append(DinoClockSum(terms: [value, 24], operation: .add, result: value + 24, reusesFirstTerm: !sums.isEmpty))
        }
        hours = sums.isEmpty ? DinoClockColumnWork(sums: [], passthrough: start.hour)
                             : DinoClockColumnWork(sums: sums, passthrough: nil)
    }

    static func format(_ value: Int) -> String {
        value < 0 ? "−\(abs(value))" : String(value)
    }
}
