import Foundation

/// Internal teaching steps. Never use these names or values in the player interface.
enum DinoQuestionDifficulty: Int, Codable, CaseIterable, Sendable {
    case introduction, familiar, challenge
    var easier: Self { Self(rawValue: max(0, rawValue - 1))! }
    var harder: Self { Self(rawValue: min(2, rawValue + 1))! }
    var optionCount: Int { self == .introduction ? 2 : 4 }
}

/// 20 exercise types × 6 time families × 3 teaching steps = 360 question categories.
struct DinoQuestionCategory: Hashable, Sendable {
    let type: DinoPracticeQuestion
    let time: DinoPracticeTime
    let difficulty: DinoQuestionDifficulty
    static let all = DinoPracticeQuestion.allCases.flatMap { type in
        DinoPracticeTime.allCases.flatMap { time in
            DinoQuestionDifficulty.allCases.map { Self(type: type, time: time, difficulty: $0) }
        }
    }
}

struct DinoQuestionSkill: Hashable, Sendable {
    let kind: ClockQuestionKind
    let time: DinoPracticeTime
}

struct DinoLearningProgress: Codable, Equatable, Sendable {
    var difficulty: DinoQuestionDifficulty = .introduction
    var consecutiveCorrect = 0
    /// A mistake temporarily overrides the curriculum until the previous step has been recovered.
    var recoveryTarget: DinoQuestionDifficulty? = nil

    mutating func record(correct: Bool, at presented: DinoQuestionDifficulty) {
        if !correct {
            recoveryTarget = DinoQuestionDifficulty(rawValue: max(recoveryTarget?.rawValue ?? 0, presented.rawValue))!
            difficulty = presented.easier
            consecutiveCorrect = 0
        } else {
            guard presented.rawValue >= difficulty.rawValue else { return }
            consecutiveCorrect += 1
            // One welcoming question, then two successes before the full challenge.
            // Recovering after a mistake uses the same short, predictable route.
            if consecutiveCorrect >= (presented == .introduction ? 1 : 2) {
                difficulty = presented.harder
                consecutiveCorrect = 0
                if let recoveryTarget, difficulty.rawValue >= recoveryTarget.rawValue { self.recoveryTarget = nil }
            }
        }
    }

    static func key(kind: ClockQuestionKind, time: DinoPracticeTime) -> String { "\(time.rawValue).\(kind.rawValue)" }
    static let validKeys = Set(DinoPracticeTime.allCases.flatMap { time in
        ClockQuestionKind.allCases.map { key(kind: $0, time: time) }
    })
}

extension LevelConfiguration {
    var timeFamily: DinoPracticeTime {
        switch minuteStep {
        case 60: return .whole
        case 30: return .half
        case 15: return .quarter
        case 10: return .tenMinutes
        case 5: return .fiveMinutes
        default: return .minutes
        }
    }


}

extension DinoPracticeTime {
    func teachingMinutes(_ difficulty: DinoQuestionDifficulty) -> [Int] {
        switch (self, difficulty) {
        case (.whole, _): return [0]
        case (.half, _): return [30]
        case (.quarter, .introduction): return [15, 45]
        case (.tenMinutes, .introduction): return [10, 50]
        case (.fiveMinutes, .introduction): return [5, 55]
        case (.minutes, .introduction): return [1, 2, 58, 59]
        default: return minutes
        }
    }

}

/// Bounded history per skill, shared by free practice and the adventure generator.
/// Difficulty controls support and operations; it never locks a session to a small set of times.
struct DinoQuestionHistory {
    private var questions: [DinoQuestionSkill: [ClockQuestion]] = [:]

    func recent(kind: ClockQuestionKind, time: DinoPracticeTime) -> [ClockQuestion] {
        questions[.init(kind: kind, time: time)] ?? []
    }

    mutating func record(_ question: ClockQuestion) {
        let key = DinoQuestionSkill(kind: question.kind, time: question.timeFamily)
        questions[key, default: []].append(question)
        let limit = max(12, question.timeFamily.minutes.count)
        if questions[key]!.count > limit { questions[key]!.removeFirst() }
    }
}

/// Shared target and distractor rules for adventure and practice, including all six time families.
enum DinoQuestionTeaching {
    static func target<R: RandomNumberGenerator>(pool: [ClockTime], time: DinoPracticeTime,
                                                 difficulty: DinoQuestionDifficulty, previous: ClockTime?,
                                                 recent: [ClockTime] = [], using rng: inout R) -> ClockTime {
        let fresh = pool.filter { $0 != previous }
        var candidates = fresh.isEmpty ? pool : fresh
        if difficulty == .introduction && recent.isEmpty {
            let clearHands = candidates.filter { [3, 6, 9, 0].contains($0.hour % 12) }
            if !clearHands.isEmpty { candidates = clearHands }
            let preferred = candidates.filter { time.teachingMinutes(difficulty).contains($0.minute) }
            if !preferred.isEmpty { candidates = preferred }
        }
        // Balance exact minutes, positions around the dial, then hours. Every tie is random,
        // so the session is varied without becoming a fixed ascending clock exercise.
        if !recent.isEmpty {
            candidates = leastUsed(candidates, recent: recent, key: { $0.minute })
            candidates = leastUsed(candidates, recent: recent, key: { $0.minute / 15 })
            let differentHour = candidates.filter { $0.hour % 12 != previous.map { $0.hour % 12 } }
            if !differentHour.isEmpty { candidates = differentHour }
            candidates = leastUsed(candidates, recent: recent, key: { $0.hour })
        }
        return candidates.randomElement(using: &rng)!
    }

    static func varied<T: Equatable, R: RandomNumberGenerator>(_ values: [T], recent: [T], using rng: inout R) -> T {
        let counts = values.map { value in recent.filter { $0 == value }.count }
        let minimum = counts.min()!
        return values.enumerated().filter { counts[$0.offset] == minimum }.randomElement(using: &rng)!.element
    }

    private static func leastUsed(_ pool: [ClockTime], recent: [ClockTime], key: (ClockTime) -> Int) -> [ClockTime] {
        let counts = Dictionary(grouping: recent, by: key).mapValues(\.count)
        let minimum = pool.map { counts[key($0), default: 0] }.min()!
        return pool.filter { counts[key($0), default: 0] == minimum }
    }

    /// Wrong answers are plausible confusions for this question, ordered from the closest trap.
    /// Introduction leads with that trap; more choices add a second kind of mistake before anything further away.
    static func distractors<R: RandomNumberGenerator>(pool: [ClockTime], target: ClockTime,
                                                       kind: ClockQuestionKind = .chooseAnalog,
                                                       difficulty: DinoQuestionDifficulty,
                                                       minuteStep: Int = 60,
                                                       operation: Int = 0,
                                                       using rng: inout R) -> [ClockTime] {
        let allowed = Set(pool)
        let twelveHour = !allowed.contains { $0.hour == 0 || $0.hour > 12 }
        let step = max(1, minuteStep)
        let bands = mistakeBands(target: target, kind: kind, step: step, operation: operation, twelveHour: twelveHour)
        var seen: Set<ClockTime> = [target]
        let primary = ordered(bands.primary, target: target, twelveHour: twelveHour, allowed: allowed, seen: &seen, using: &rng)
        let tricks = ordered(bands.tricks, target: target, twelveHour: twelveHour, allowed: allowed, seen: &seen, using: &rng)
        let rest = ordered(pool, target: target, twelveHour: twelveHour, allowed: allowed, seen: &seen, using: &rng, shuffleTies: false)
        let lead = difficulty == .challenge ? tricks : primary
        let follow = difficulty == .challenge ? primary : tricks
        var merged: [ClockTime] = []
        for index in 0..<max(lead.count, follow.count) {
            if index < lead.count { merged.append(lead[index]) }
            if index < follow.count { merged.append(follow[index]) }
        }
        return merged + rest
    }

    private static func mistakeBands(target: ClockTime, kind: ClockQuestionKind, step: Int,
                                     operation: Int, twelveHour: Bool) -> (primary: [ClockTime], tricks: [ClockTime]) {
        func moved(_ time: ClockTime, by minutes: Int) -> ClockTime {
            let next = time.adding(minutes: minutes)
            guard twelveHour else { return next }
            let hour = next.hour % 12 == 0 ? 12 : next.hour % 12
            return ClockTime(hour: hour, minute: next.minute)
        }
        let hour: (Int, Int) -> ClockTime = { delta, minute in
            if twelveHour {
                let base = target.hour % 12 == 0 ? 12 : target.hour % 12
                return ClockTime(hour: ClockTime.shiftedHour(base, by: delta), minute: minute)
            }
            return ClockTime(hour: target.hour + delta, minute: minute)
        }
        let sameMinute = target.minute
        let neighbors = [hour(-1, sameMinute), hour(1, sameMinute)]
            + (step < 60 ? [moved(target, by: -step), moved(target, by: step)] : [])
        let phrases = phraseTraps(target, hour: hour)
        switch kind {
        case .addTime, .subtractTime, .advanceAnalog, .timeSequence, .flightArrival:
            let shown = moved(target, by: -operation)
            let hourPart = (operation / 60) * 60
            var primary = [moved(target, by: step), moved(target, by: -step)]
            if step < 60 { primary += [moved(target, by: 60), moved(target, by: -60)] }
            var tricks = [
                shown,
                moved(target, by: -2 * operation),
                moved(shown, by: hourPart),
                moved(shown, by: operation - hourPart),
                moved(shown, by: operation * 2)
            ]
            if kind == .timeSequence {
                primary = [moved(target, by: operation), moved(target, by: -operation)] + primary
                tricks = [moved(target, by: 2 * operation), moved(target, by: -2 * operation)]
            }
            if kind == .flightArrival {
                tricks = [shown, moved(shown, by: hourPart), moved(shown, by: operation * 2)]
            }
            return (primary, tricks)
        case .readDigital, .spokenTime, .trueFalse:
            var swapped: [ClockTime] = []
            if let swap = handSwap(target, twelveHour: twelveHour), dialGap(swap, target, twelveHour: twelveHour) <= 180 {
                swapped = [swap]
            }
            return (phrases, neighbors + swapped)
        case .read24Hour:
            let twin = hour(12, sameMinute)
            return ([twin], [hour(11, sameMinute), hour(13, sameMinute)] + phrases + neighbors)
        case .sortTimes:
            return (neighbors, [hour(-2, sameMinute), hour(2, sameMinute)] + phrases)
        default:
            var tricks = [hour(-2, sameMinute), hour(2, sameMinute)] + phrases
            if let swapped = handSwap(target, twelveHour: twelveHour), dialGap(swapped, target, twelveHour: twelveHour) <= 180 {
                tricks.append(swapped)
            }
            return (neighbors, tricks)
        }
    }

    /// "Tien over" versus "tien voor", half-hour names, and quarter past versus quarter to.
    private static func phraseTraps(_ target: ClockTime, hour: (Int, Int) -> ClockTime) -> [ClockTime] {
        let same = target.minute
        guard same != 0 else { return [hour(-1, 30)] }
        var traps: [ClockTime] = []
        if same != 30 {
            let mirrored = (60 - same) % 60
            traps.append(ClockTime(hour: target.hour, minute: mirrored))
            traps.append(hour(same < 30 ? -1 : 1, mirrored))
        } else {
            traps += [hour(1, 0), hour(-1, 0), hour(0, 0), hour(1, same), hour(-1, same)]
        }
        if [20, 25, 35, 40].contains(same) {
            traps.append(ClockTime(hour: target.hour, minute: same < 30 ? same + 20 : same - 20))
        }
        if same >= 20 { traps.append(hour(1, same)) }
        return traps
    }

    /// Minute hand read as the hour, and the hour hand read as minutes. Same-face swaps are omitted.
    private static func handSwap(_ time: ClockTime, twelveHour: Bool) -> ClockTime? {
        guard time.minute.isMultiple(of: 5) else { return nil }
        let mark = time.minute / 5
        let newMinute = (time.hour % 12) * 5
        let faceHour = mark == 0 ? 12 : mark
        let newHour: Int
        if twelveHour {
            newHour = faceHour
        } else if time.hour >= 12 {
            newHour = faceHour == 12 ? 12 : faceHour + 12
        } else {
            newHour = faceHour == 12 ? 0 : faceHour
        }
        let swapped = ClockTime(hour: newHour, minute: newMinute)
        return swapped == time ? nil : swapped
    }

    private static func dialGap(_ a: ClockTime, _ b: ClockTime, twelveHour: Bool) -> Int {
        func minutes(_ time: ClockTime) -> Int {
            twelveHour ? (time.hour % 12) * 60 + time.minute : time.minutesOfDay
        }
        let span = twelveHour ? 720 : 1440
        let delta = abs(minutes(a) - minutes(b))
        return min(delta, span - delta)
    }

    private static func ordered<R: RandomNumberGenerator>(_ times: [ClockTime], target: ClockTime, twelveHour: Bool,
                                                          allowed: Set<ClockTime>, seen: inout Set<ClockTime>,
                                                          using rng: inout R, shuffleTies: Bool = true) -> [ClockTime] {
        var unique: [ClockTime] = []
        var added = Set<ClockTime>()
        for time in times where allowed.contains(time) && seen.contains(time) == false && added.insert(time).inserted {
            unique.append(time)
        }
        let grouped = Dictionary(grouping: unique) { dialGap($0, target, twelveHour: twelveHour) }
        let sorted = grouped.keys.sorted().flatMap { key -> [ClockTime] in
            let group = grouped[key]!
            return shuffleTies ? group.shuffled(using: &rng) : group.sorted { $0.minutesOfDay < $1.minutesOfDay }
        }
        seen.formUnion(sorted)
        return sorted
    }
}
