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
    case ordering([ClockTime]), pairs([ClockTime])
}

enum DinoExpandedQuestions {
    static func generate<R: RandomNumberGenerator>(kind: ClockQuestionKind, time: DinoPracticeTime,
                                                   index: Int, previousTarget: ClockTime?, using rng: inout R) -> ClockQuestion {
        generate(kind: kind, minutes: time.minutes, minuteStep: time.minuteStep,
                 index: index, previousTarget: previousTarget, using: &rng)
    }

    static func generate<R: RandomNumberGenerator>(kind: ClockQuestionKind, minutes: [Int], minuteStep: Int,
                                                   index: Int, previousTarget: ClockTime?, preferredTarget: ClockTime? = nil,
                                                   isDemonstration: Bool = false,
                                                   using rng: inout R) -> ClockQuestion {
        let hours = [.readDigital, .spokenTime, .trueFalse].contains(kind) ? Array(1...12) : Array(0...23)
        let pool = hours.flatMap { hour in minutes.map { ClockTime(hour: hour, minute: $0) } }
            .filter { time in
                if kind == .dayPart && !isDemonstration { return time.hour != 6 && time.hour < 22 }
                if kind == .sortTimes { return time.minutesOfDay != 0 }
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
        case .addTime, .advanceAnalog, .schoolEnd:
            q.durationMinutes = duration; q.relatedTimes = [target.adding(minutes: -duration)]
            if kind == .advanceAnalog { q.options = [] }
        case .subtractTime:
            q.durationMinutes = duration; q.relatedTimes = [target.adding(minutes: duration)]
        case .flightArrival:
            q.durationMinutes = 120 + duration; q.relatedTimes = [target.adding(minutes: -q.durationMinutes)]
        case .elapsedTime:
            q.durationMinutes = duration; q.relatedTimes = [target.adding(minutes: -duration), target]
            var durations = Set([duration])
            var distractors: [Int] = []
            while distractors.count < 3 {
                let value = step * Int.random(in: 1...8, using: &rng)
                if durations.insert(value).inserted { distractors.append(value) }
            }
            q.options = []; q.answerChoices = (distractors + [duration]).shuffled(using: &rng).map(ClockAnswer.duration)
            q.answer = .duration(duration)
        case .timeZone:
            q.offsetHours = [-2, -1, 0, 1, 2].randomElement(using: &rng)!
            q.relatedTimes = [target.adding(minutes: -q.offsetHours * 60)]
        default: preconditionFailure("Use the original clock generator for \(kind)")
        }
        return q
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
                         index: Int, previousTarget: ClockTime?) -> ClockQuestion {
        let sequential = [.readDigital, .spokenTime, .trueFalse, .dayPart, .read24Hour].contains(kind)
        let hours = [.readDigital, .spokenTime, .trueFalse].contains(kind) ? 12 : 24
        var rng = SeededGenerator(seed: 20261012 &+ UInt64(index))
        return DinoExpandedQuestions.generate(kind: kind, minutes: minutes, minuteStep: minuteStep,
                                              index: index, previousTarget: previousTarget,
                                              preferredTarget: sequential ? time(index: index, minutes: minutes, hours: hours) : nil,
                                              isDemonstration: true,
                                              using: &rng)
    }
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
    static func duration(_ minutes: Int, language: String) -> String {
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m) min" }
        return m == 0 ? "\(h) \(language == "nl" ? "uur" : "h")" : "\(h) \(language == "nl" ? "uur" : "h") \(m) min"
    }
}
