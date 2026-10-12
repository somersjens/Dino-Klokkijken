import Foundation

struct ClockQuestion: Identifiable, Equatable, Sendable {
    let id: Int
    let kind: ClockQuestionKind
    let target: ClockTime
    var options: [ClockTime]
    let activity: DinoActivity?
    /// Other cards on the matching board; the target is visibly selected.
    let companionClocks: [ClockTime]
    var relatedTimes: [ClockTime] = []
    var durationMinutes = 0
    var offsetHours = 0
    var statement: ClockTime? = nil
    var answerChoices: [ClockAnswer] = []
    var answer: ClockAnswer? = nil
    var expectedAnswer: ClockAnswer { answer ?? .time(target) }
    var responses: [ClockAnswer] { answerChoices.isEmpty ? options.map(ClockAnswer.time) : answerChoices }
}

enum DinoQuestionGenerator {
    static func generate<R: RandomNumberGenerator>(level: LevelConfiguration,
                                                   attempt: Int = 0,
                                                   using rng: inout R) -> [ClockQuestion] {
        precondition(!level.allowedHours.isEmpty && level.allowedHours.allSatisfy { (1...12).contains($0) })
        var available = level.allowedHours.shuffled(using: &rng)
        var used = Set<Int>()
        let positionOffset = Int.random(in: 0..<12, using: &rng)
        return (0..<level.questionCount).map { index in
            let recipe = level.recipes[index % level.recipes.count]
            let activity: DinoActivity? = recipe.kind == .activity ? DinoActivity.allCases[index % 5] : nil
            let hour: Int
            if let activity {
                hour = activity.hour
            } else if attempt == 0, let fixed = recipe.firstAttemptHour {
                hour = fixed
            } else {
                if available.allSatisfy({ used.contains($0) }) { used.removeAll() }
                let candidate = available.first { !used.contains($0) } ?? available[0]
                hour = candidate
                available.removeAll { $0 == candidate }
                available.append(candidate)
            }
            used.insert(hour)
            let target = ClockTime(hour: hour)
            var options: [ClockTime] = []
            if recipe.kind.usesOptions {
                precondition([2, 4].contains(recipe.optionCount), "Answer grids must contain two or four choices")
                let distractors = Array(1...12).filter { $0 != hour }.shuffled(using: &rng)
                options = distractors.prefix(recipe.optionCount - 1).map { ClockTime(hour: $0) }
                options.insert(target, at: (positionOffset + index) % recipe.optionCount)
            }
            let companions = Array(1...12).filter { $0 != hour }.shuffled(using: &rng)
                .prefix(2).map { ClockTime(hour: $0) }
            return ClockQuestion(id: index, kind: recipe.kind, target: target,
                                 options: options, activity: activity, companionClocks: companions)
        }
    }
}

enum AnswerValidator {
    static func isCorrect(_ answer: ClockTime, for question: ClockQuestion) -> Bool {
        isCorrect(.time(answer), for: question)
    }
    static func isCorrect(_ answer: ClockAnswer, for question: ClockQuestion) -> Bool {
        if question.kind == .advanceAnalog, case .time(let time) = answer {
            return time.hour % 12 == question.target.hour % 12 && time.minute == question.target.minute
        }
        return answer == question.expectedAnswer
    }
}

enum StarCalculator {
    static func stars(correct: Int) -> Int {
        switch correct {
        case 3: return 1
        case 4: return 2
        case 5...: return 3
        default: return 0
        }
    }
}

enum BossVictory: String, Codable, Sendable {
    case none, normal, perfect
    static func evaluate(correct: Int, normalLevelsComplete: Bool) -> BossVictory {
        if correct == 10 { return .perfect }
        return normalLevelsComplete && correct >= 5 ? .normal : .none
    }
}

/// Prevents double scoring, including rapid taps and taps during feedback.
struct LevelAttempt: Sendable {
    let levelID: Int
    let questions: [ClockQuestion]
    private(set) var answers: [Bool] = []
    private(set) var questionSeconds: [Int] = []
    private(set) var submittedResponse: ClockAnswer?
    var submittedAnswer: ClockTime? {
        if case .time(let time) = submittedResponse { return time }
        return nil
    }
    private(set) var index = 0
    var current: ClockQuestion { questions[min(index, questions.count - 1)] }
    var correctCount: Int { answers.filter { $0 }.count }
    var isComplete: Bool { index == questions.count }

    @discardableResult
    mutating func submit(_ answer: ClockTime, elapsed: TimeInterval? = nil) -> Bool? {
        submit(.time(answer), elapsed: elapsed)
    }
    @discardableResult
    mutating func submit(_ answer: ClockAnswer, elapsed: TimeInterval? = nil) -> Bool? {
        guard !isComplete, submittedResponse == nil else { return nil }
        let correct = AnswerValidator.isCorrect(answer, for: current)
        submittedResponse = answer
        answers.append(correct)
        if let elapsed { questionSeconds.append(DinoQuestionTiming.scoredSeconds(elapsed)) }
        return correct
    }

    mutating func advance() {
        guard submittedResponse != nil, !isComplete else { return }
        index += 1
        submittedResponse = nil
    }
}

/// Continuous time is independent of calendar, time zone and wall-clock changes.
enum DinoQuestionTiming {
    private static let origin = ContinuousClock.now
    static func now() -> TimeInterval {
        let elapsed = origin.duration(to: .now).components
        return Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
    }
    static func scoredSeconds(_ elapsed: TimeInterval) -> Int {
        guard elapsed.isFinite else { return elapsed == .infinity ? 60 : 1 }
        return Int(min(60, max(1, elapsed.rounded(.up))))
    }
    static func text(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

struct TimedLevelResult: Codable, Equatable, Sendable {
    let resultPoints: Int
    let seconds: Int
    // Quality always wins; time breaks ties between equally good results.
    var rankedScore: Int { resultPoints * 1_000 + 601 - seconds }
    func isValid(levelID: Int) -> Bool {
        guard let level = DinoLevelCatalog.level(levelID),
              (level.questionCount...level.questionCount * 60).contains(seconds) else { return false }
        return DinoLeaderboards.decode(levelID: levelID, score: resultPoints, context: DinoLeaderboards.context)?.attempted == true
    }
}

struct TimedLevelAttempt: Codable, Equatable, Sendable {
    let levelID: Int
    let correct: Int
    let questionSeconds: [Int]
    let date: Date
    var seconds: Int { questionSeconds.reduce(0, +) }
}
