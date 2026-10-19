import Foundation

struct ClockQuestion: Identifiable, Equatable, Sendable {
    let id: Int
    let kind: ClockQuestionKind
    let target: ClockTime
    var options: [ClockTime]
    let activity: DinoActivity?
    /// Two additional faces for the three-pair matching board.
    let companionClocks: [ClockTime]
    var relatedTimes: [ClockTime] = []
    var durationMinutes = 0
    var offsetHours = 0
    var timeZoneJourney: DinoTimeZoneJourney? = nil
    var daySchedule: DinoDaySchedule? = nil
    var statement: ClockTime? = nil
    var spokenPrompt: SpokenTimePrompt? = nil
    var answerChoices: [ClockAnswer] = []
    var answer: ClockAnswer? = nil
    var difficulty: DinoQuestionDifficulty = .introduction
    var timeFamily: DinoPracticeTime = .whole
    var expectedAnswer: ClockAnswer { answer ?? .time(target) }
    var responses: [ClockAnswer] { answerChoices.isEmpty ? options.map(ClockAnswer.time) : answerChoices }
}

enum DinoMatchingQuestions {
    static func configure<R: RandomNumberGenerator>(_ question: ClockQuestion, using rng: inout R) -> ClockQuestion {
        guard question.kind == .match else { return question }
        var question = question
        question.relatedTimes = [question.target] + question.companionClocks
        question.options = question.relatedTimes.shuffled(using: &rng)
        question.answer = .pairs(question.relatedTimes)
        return question
    }
}

enum DinoQuestionGenerator {
    static func generate<R: RandomNumberGenerator>(level: LevelConfiguration,
                                                   attempt: Int = 0,
                                                   language: String = "nl",
                                                   difficulties: [DinoQuestionSkill: DinoQuestionDifficulty] = [:],
                                                   using rng: inout R) -> [ClockQuestion] {
        precondition(!level.allowedHours.isEmpty && level.allowedHours.allSatisfy { (1...12).contains($0) })
        var usedHours = Set<Int>()
        var previous: ClockTime?
        let positionOffset = Int.random(in: 0..<12, using: &rng)
        return (0..<level.questionCount).map { index in
            let recipe = level.recipe(at: index)
            let difficulty = difficulties[level.skill(for: recipe)] ?? level.plannedDifficulty(for: recipe)
            let question = generateQuestion(level: level, recipe: recipe, index: index, attempt: attempt,
                difficulty: difficulty, previousTarget: previous, usedHours: usedHours,
                optionPosition: positionOffset + index, language: language, using: &rng)
            usedHours.insert(question.target.hour)
            previous = question.target
            return question
        }
    }

    static func generateQuestion<R: RandomNumberGenerator>(level: LevelConfiguration, recipe: QuestionRecipe,
        index: Int, attempt: Int = 0, difficulty: DinoQuestionDifficulty, previousTarget: ClockTime?,
        usedHours: Set<Int> = [], optionPosition: Int? = nil, language: String = "nl", using rng: inout R) -> ClockQuestion {
        let family = level.time(for: recipe)
        let minutes = recipe.time == nil ? level.allowedMinutes : family.minutes
        if recipe.kind.isExpanded {
            return DinoExpandedQuestions.generate(kind: recipe.kind, minutes: minutes,
                minuteStep: family.minuteStep, index: index, previousTarget: previousTarget,
                language: language, difficulty: difficulty, using: &rng)
        }
        let activity: DinoActivity? = recipe.kind == .activity ? DinoActivity.allCases[index % 5] : nil
        let pool = level.allowedHours.flatMap { hour in
            minutes.map { ClockTime(hour: hour, minute: $0) }
        }
        let target: ClockTime
        if let activity { target = ClockTime(hour: activity.hour) }
        else if attempt == 0, let fixed = recipe.firstAttemptHour { target = ClockTime(hour: fixed) }
        else {
            var candidates = pool
            if level.worldID == 1 && level.id > 0 {
                let freshHours = pool.filter { !usedHours.contains($0.hour) }
                if !freshHours.isEmpty { candidates = freshHours }
            }
            target = DinoQuestionTeaching.target(pool: candidates, time: family,
                difficulty: difficulty, previous: previousTarget, using: &rng)
        }
        let optionPool = family.minuteStep == 60 ? (1...12).map { ClockTime(hour: $0) } : pool
        let others = DinoQuestionTeaching.distractors(pool: optionPool, target: target, difficulty: difficulty, using: &rng)
        let count = min(recipe.optionCount, difficulty.optionCount)
        var options = recipe.kind.usesOptions ? Array(others.prefix(count - 1)) : []
        if recipe.kind.usesOptions {
            precondition([2, 4].contains(count), "Answer grids must contain two or four choices")
            options.insert(target, at: (optionPosition ?? Int.random(in: 0..<count, using: &rng)) % count)
        }
        var question = ClockQuestion(id: index, kind: recipe.kind, target: target, options: options,
            activity: activity, companionClocks: Array(others.prefix(2)))
        question.difficulty = difficulty
        question.timeFamily = family
        return DinoMatchingQuestions.configure(question, using: &rng)
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
        if question.kind == .sayTime, case .spoken(let spoken) = answer, let prompt = question.spokenPrompt {
            if spoken == prompt.correct { return true }
            // "Vijf" in the minutes row plus "uur" reads the same as the hour "vijf" plus "uur".
            guard question.target.minute == 0 else { return false }
            let said = prompt.phrase(for: spoken)
            return !said.isEmpty && said == prompt.phrase
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
    private(set) var questions: [ClockQuestion]
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

    /// Only the unanswered current question may be adapted. Scored answers and indices stay intact.
    mutating func replaceCurrent(with question: ClockQuestion) {
        guard !isComplete, submittedResponse == nil, question.id == current.id, question.kind == current.kind else { return }
        questions[index] = question
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
