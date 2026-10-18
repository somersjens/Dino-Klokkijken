import Foundation

enum DinoPracticeTime: String, CaseIterable, Sendable {
    case whole, half, quarter, tenMinutes, fiveMinutes, mix
    var titleKey: String { "dino.practice.time.\(rawValue)" }
    var previewTime: ClockTime { ClockTime(hour: 3, minute: self == .mix ? 35 : minutes[0]) }
    var minutes: [Int] {
        switch self {
        case .whole: return [0]
        case .half: return [30]
        case .quarter: return [15, 45]
        case .tenMinutes: return Array(stride(from: 10, to: 60, by: 10))
        case .fiveMinutes: return Array(stride(from: 5, to: 60, by: 5))
        case .mix: return Array(stride(from: 0, to: 60, by: 5))
        }
    }
    var minuteStep: Int {
        switch self {
        case .whole: return 60
        case .half: return 30
        case .quarter: return 15
        case .tenMinutes: return 10
        case .fiveMinutes, .mix: return 5
        }
    }
}

/// Each distinct exercise, ordered by difficulty. Choice counts are an internal variation.
enum DinoPracticeQuestion: String, CaseIterable, Sendable {
    case chooseAnalog, chooseDigital, readDigital, spokenTime, trueFalse, dayPart, match
    case setDigital, setAnalog, read24Hour, sortTimes, timeSequence
    case addTime, advanceAnalog, subtractTime, flightArrival, timeZone, daySchedule, minutesBetween
    var titleKey: String { "dino.practice.question.\(rawValue)" }
    var number: Int { Self.allCases.firstIndex(of: self)! + 1 }
    var recipe: QuestionRecipe {
        let kind = ClockQuestionKind(rawValue: rawValue)!
        return .init(kind: kind, optionCount: kind.usesOptions ? 4 : 0)
    }
}

/// One row on the level card: the practice number, the exercise name, and the clock steps used.
struct LevelQuestionOutline: Equatable, Sendable {
    let practiceNumber: Int?
    let titleKey: String
    let timeTitleKey: String
}

extension LevelConfiguration {
    /// The practice-screen time family for this level, so the card uses the same words as the exercise list.
    var practiceTimeTitleKey: String {
        switch minuteStep {
        case 60: return "dino.practice.time.whole"
        case 30: return "dino.practice.time.half"
        case 15: return "dino.practice.time.quarter"
        case 10: return "dino.practice.time.tenMinutes"
        case 5: return allowedMinutes.contains(0) ? "dino.practice.time.mix" : "dino.practice.time.fiveMinutes"
        default: return "dino.level.time.minute"
        }
    }

    /// Question types in the order they are asked. One recipe used for the whole level stays a single row.
    var questionOutline: [LevelQuestionOutline] {
        recipes.map { recipe in
            let practice = DinoPracticeQuestion(rawValue: recipe.kind.rawValue)
            return LevelQuestionOutline(practiceNumber: practice?.number,
                                        titleKey: practice?.titleKey ?? "dino.practice.question.\(recipe.kind.rawValue)",
                                        timeTitleKey: practiceTimeTitleKey)
        }
    }
}

enum DinoPracticeOrder: Equatable, Sendable {
    case specific(DinoPracticeQuestion), ascending, mix
}

struct DinoPracticeConfiguration: Equatable, Sendable {
    var time: DinoPracticeTime = .whole
    var order: DinoPracticeOrder = .ascending
    // A practice session uses the ordinary renderer, but never finishes a catalog level.
    var level: LevelConfiguration {
        LevelConfiguration(id: 0, worldID: 1, titleKey: "dino.practice.title",
                           instructionKey: "dino.practice.description", allowedHours: Array(1...12),
                           difficulty: 0, questionCount: 1, isBoss: false,
                           recipes: [.init(kind: .chooseAnalog, optionCount: 2)])
    }
}

/// One bounded record per time family and question type or practice order, independent of level scores.
struct DinoPracticeRecord: Codable, Equatable, Sendable {
    var bestStreak = 0
    var questionsAnswered = 0
    var currentStreak = 0

    init(bestStreak: Int = 0, questionsAnswered: Int = 0, currentStreak: Int = 0) {
        self.bestStreak = bestStreak
        self.questionsAnswered = questionsAnswered
        self.currentStreak = currentStreak
    }

    private enum CodingKeys: String, CodingKey { case bestStreak, questionsAnswered, currentStreak }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        bestStreak = try values.decode(Int.self, forKey: .bestStreak)
        questionsAnswered = try values.decode(Int.self, forKey: .questionsAnswered)
        // Earlier saves contain only the record and question count.
        currentStreak = try values.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
    }

    static func key(time: DinoPracticeTime, question: DinoPracticeQuestion) -> String {
        key(time: time, order: .specific(question))
    }

    static func key(time: DinoPracticeTime, order: DinoPracticeOrder) -> String {
        let suffix: String
        switch order {
        case .specific(let question): suffix = question.rawValue
        case .ascending: suffix = "ascending"
        case .mix: suffix = "mix"
        }
        return "\(time.rawValue).\(suffix)"
    }

    static let validKeys = Set(DinoPracticeTime.allCases.flatMap { time in
        // Retain saved records of retired exercises without renumbering other records.
        DinoPracticeQuestion.allCases.map { key(time: time, question: $0) }
            + [key(time: time, order: .ascending), key(time: time, order: .mix)]
            + ["\(time.rawValue).activity", "\(time.rawValue).pairClocks", "\(time.rawValue).elapsedTime", "\(time.rawValue).schoolEnd"]
    })
}

/// The large digits wrap every thousand; the small digits carry the thousands.
struct DinoPracticeCounter: Equatable {
    let value: Int
    var digits: String { String(max(0, value) % 1_000) }
    var thousands: String? {
        let count = (max(0, value) / 1_000) % 1_000
        return count == 0 ? nil : "\(count)k"
    }
}

/// Generates one question at a time; even long practice sessions keep bounded memory.
struct DinoPracticeGenerator {
    let configuration: DinoPracticeConfiguration
    private var rng: SeededGenerator
    private var mixedTypes: [DinoPracticeQuestion] = []
    private var previousTarget: ClockTime?
    private let language: String

    init(configuration: DinoPracticeConfiguration, seed: UInt64 = .random(in: .min ... .max), language: String = "nl") {
        self.configuration = configuration
        self.language = language
        rng = SeededGenerator(seed: seed)
    }

    mutating func next(index: Int) -> ClockQuestion {
        let type: DinoPracticeQuestion
        switch configuration.order {
        case .specific(let selected): type = selected
        case .ascending: type = DinoPracticeQuestion.allCases[index % DinoPracticeQuestion.allCases.count]
        case .mix:
            if mixedTypes.isEmpty { mixedTypes = DinoPracticeQuestion.allCases.shuffled(using: &rng) }
            type = mixedTypes.removeLast()
        }
        let question = make(type, index: index)
        if case .mix = configuration.order, mixedTypes.isEmpty {
            mixedTypes = DinoPracticeQuestion.allCases.shuffled(using: &rng)
        }
        return question
    }

    private mutating func make(_ type: DinoPracticeQuestion, index: Int) -> ClockQuestion {
        var recipe = type.recipe
        if recipe.kind.isExpanded {
            let question = DinoExpandedQuestions.generate(kind: recipe.kind, time: configuration.time,
                                                           index: index, previousTarget: previousTarget, language: language, using: &rng)
            previousTarget = question.target
            return question
        }
        if recipe.kind == .chooseAnalog || recipe.kind == .chooseDigital {
            recipe.optionCount = Bool.random(using: &rng) ? 2 : 4
        }
        let pool = (1...12).flatMap { hour in configuration.time.minutes.map { ClockTime(hour: hour, minute: $0) } }
        let targets = pool.filter { $0 != previousTarget }
        let target = targets.randomElement(using: &rng)!
        previousTarget = target
        let otherTimes = pool.filter { $0 != target }.shuffled(using: &rng)
        var options = recipe.kind.usesOptions ? Array(otherTimes.prefix(recipe.optionCount - 1)) : []
        if recipe.kind.usesOptions { options.insert(target, at: Int.random(in: 0..<recipe.optionCount, using: &rng)) }
        let question = ClockQuestion(id: index, kind: recipe.kind, target: target, options: options,
                                    activity: nil, companionClocks: Array(otherTimes.prefix(2)))
        return DinoMatchingQuestions.configure(question, using: &rng)
    }

    /// The kind that `next(index:)` will draw after the question identified by `index`.
    func upcomingKind(after index: Int) -> ClockQuestionKind? {
        switch configuration.order {
        case .specific(let selected):
            return ClockQuestionKind(rawValue: selected.rawValue)
        case .ascending:
            let next = DinoPracticeQuestion.allCases[(index + 1) % DinoPracticeQuestion.allCases.count]
            return ClockQuestionKind(rawValue: next.rawValue)
        case .mix:
            guard let next = mixedTypes.last else { return nil }
            return ClockQuestionKind(rawValue: next.rawValue)
        }
    }
}
