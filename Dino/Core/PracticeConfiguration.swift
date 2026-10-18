import Foundation

enum DinoPracticeTime: String, CaseIterable, Sendable {
    case whole, half, quarter, tenMinutes, fiveMinutes, minutes
    var titleKey: String { "dino.practice.time.\(rawValue)" }
    var previewTime: ClockTime { ClockTime(hour: 3, minute: focusMinutes[0]) }
    init?(storageKey: String) { self.init(rawValue: storageKey == "mix" ? "minutes" : storageKey) }
    var minutes: [Int] {
        Array(stride(from: 0, to: 60, by: minuteStep))
    }
    /// The selected family teaches these positions while continuing to review its other multiples.
    var focusMinutes: [Int] {
        switch self {
        case .whole: return [0]
        case .half: return [30]
        case .quarter: return [15, 45]
        case .tenMinutes: return [10, 20, 40, 50]
        case .fiveMinutes: return [5, 10, 20, 25, 35, 40, 50, 55]
        case .minutes: return (1..<60).filter { !$0.isMultiple(of: 5) }
        }
    }
    var minuteStep: Int {
        switch self {
        case .whole: return 60
        case .half: return 30
        case .quarter: return 15
        case .tenMinutes: return 10
        case .fiveMinutes: return 5
        case .minutes: return 1
        }
    }
}

/// Learning progression shared by the practice list, its numbers and ascending sessions.
/// Recognize and read before producing an answer; build clock arithmetic before combining it.
enum DinoPracticeQuestion: String, CaseIterable, Sendable {
    // Recognize a clock, check a statement, then translate and build time phrases.
    case chooseAnalog, chooseDigital, trueFalse, readDigital, spokenTime, sayTime
    // Set clocks, learn 24-hour notation and day parts, then connect and compare times.
    case setDigital, setAnalog, read24Hour, dayPart, match, sortTimes
    // Move hands before calculating; keep later and earlier times together.
    case advanceAnalog, addTime, subtractTime, minutesBetween, timeSequence
    // Combine durations, then learn zone differences before a flight that can use both.
    case daySchedule, timeZone, flightArrival
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
    /// A summary label for older consumers; each outline row resolves its own time family.
    var practiceTimeTitleKey: String { timeFamily.titleKey }

    /// Question types in the order they are asked. One recipe used for the whole level stays a single row.
    var questionOutline: [LevelQuestionOutline] {
        recipes.map { recipe in
            let practice = DinoPracticeQuestion(rawValue: recipe.kind.rawValue)
            return LevelQuestionOutline(practiceNumber: practice?.number,
                                        titleKey: practice?.titleKey ?? "dino.practice.question.\(recipe.kind.rawValue)",
                                        timeTitleKey: time(for: recipe).titleKey)
        }
    }
}

enum DinoPracticeOrder: Equatable, Sendable {
    case specific(DinoPracticeQuestion), ascending, mix

    /// Stable preference key. Question names never overlap the two mixed orders.
    var storageKey: String {
        switch self {
        case .specific(let question): return question.rawValue
        case .ascending: return "ascending"
        case .mix: return "mix"
        }
    }

    init?(storageKey: String) {
        switch storageKey {
        case "ascending": self = .ascending
        case "mix": self = .mix
        default:
            guard let question = DinoPracticeQuestion(rawValue: storageKey) else { return nil }
            self = .specific(question)
        }
    }
}

struct DinoPracticeConfiguration: Equatable, Sendable {
    var time: DinoPracticeTime = .whole
    var order: DinoPracticeOrder = .ascending
    // A practice session uses the ordinary renderer, but never finishes a catalog level.
    var level: LevelConfiguration {
        LevelConfiguration(id: 0, worldID: 1, titleKey: "dino.practice.title",
                           instructionKey: "dino.practice.description", allowedHours: Array(1...12),
                           difficulty: 0, questionCount: 1, isBoss: false,
                           recipes: [.init(kind: .chooseAnalog, optionCount: 2)],
                           allowedMinutes: time.minutes, minuteStep: time.minuteStep)
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

    mutating func next(index: Int, difficultyForKind: (ClockQuestionKind) -> DinoQuestionDifficulty = { _ in .introduction }) -> ClockQuestion {
        let type: DinoPracticeQuestion
        switch configuration.order {
        case .specific(let selected): type = selected
        case .ascending: type = DinoPracticeQuestion.allCases[index % DinoPracticeQuestion.allCases.count]
        case .mix:
            if mixedTypes.isEmpty { mixedTypes = DinoPracticeQuestion.allCases.shuffled(using: &rng) }
            type = mixedTypes.removeLast()
        }
        let question = make(type, index: index, difficulty: difficultyForKind(type.recipe.kind))
        if case .mix = configuration.order, mixedTypes.isEmpty {
            mixedTypes = DinoPracticeQuestion.allCases.shuffled(using: &rng)
        }
        return question
    }

    private mutating func make(_ type: DinoPracticeQuestion, index: Int, difficulty: DinoQuestionDifficulty) -> ClockQuestion {
        let question = DinoQuestionGenerator.generateQuestion(level: configuration.level, recipe: type.recipe,
            index: index, difficulty: difficulty, previousTarget: previousTarget, language: language, using: &rng)
        previousTarget = question.target
        return question
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
