import Foundation

struct ClockQuestion: Identifiable, Equatable, Sendable {
    let id: Int
    let kind: ClockQuestionKind
    let target: ClockTime
    let options: [ClockTime]
    let activity: DinoActivity?
    /// Other cards on the matching board; the target is visibly selected.
    let companionClocks: [ClockTime]
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
        answer == question.target
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
    private(set) var submittedAnswer: ClockTime?
    private(set) var index = 0
    var current: ClockQuestion { questions[min(index, questions.count - 1)] }
    var correctCount: Int { answers.filter { $0 }.count }
    var isComplete: Bool { index == questions.count }

    @discardableResult
    mutating func submit(_ answer: ClockTime) -> Bool? {
        guard !isComplete, submittedAnswer == nil else { return nil }
        let correct = AnswerValidator.isCorrect(answer, for: current)
        submittedAnswer = answer
        answers.append(correct)
        return correct
    }

    mutating func advance() {
        guard submittedAnswer != nil, !isComplete else { return }
        index += 1
        submittedAnswer = nil
    }
}
