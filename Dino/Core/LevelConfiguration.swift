import Foundation

enum ClockQuestionKind: String, Codable, CaseIterable, Sendable {
    case chooseAnalog, chooseDigital, activity, setAnalog, setDigital, match
    case readDigital, spokenTime, trueFalse, dayPart, read24Hour, sortTimes, sayTime, timeSequence
    case addTime, advanceAnalog, subtractTime, flightArrival, timeZone, daySchedule, minutesBetween
    var instructionKey: String { "dino.question.\(rawValue)" }
    var symbol: String {
        switch self {
        case .chooseAnalog: return "clock.fill"
        case .chooseDigital: return "digitalcrown.horizontal.press.fill"
        case .activity: return "sun.max.fill"
        case .setAnalog: return "hand.draw.fill"
        case .setDigital: return "plusminus.circle.fill"
        case .match: return "link"
        case .readDigital, .read24Hour: return "text.bubble.fill"
        case .spokenTime: return "quote.bubble.fill"
        case .trueFalse: return "checkmark.circle.fill"
        case .dayPart: return "sun.horizon.fill"
        case .sortTimes: return "list.number"
        case .sayTime: return "captions.bubble.fill"
        case .timeSequence: return "ellipsis"
        case .addTime, .advanceAnalog: return "clock.arrow.2.circlepath"
        case .minutesBetween: return "arrow.right.to.line"
        case .subtractTime: return "minus.circle.fill"
        case .flightArrival: return "airplane"
        case .timeZone: return "globe.europe.africa.fill"
        case .daySchedule: return "train.side.front.car"
        }
    }
    var usesOptions: Bool { ![.setAnalog, .setDigital, .match, .advanceAnalog, .sortTimes, .sayTime].contains(self) }
    var isExpanded: Bool { ![.chooseAnalog, .chooseDigital, .activity, .setAnalog, .setDigital, .match].contains(self) }
    /// These controls look the same on every question of this kind, so a correct answer can leave them in place.
    var reusesAnswerControls: Bool {
        switch self {
        case .setAnalog, .advanceAnalog, .setDigital, .match, .sortTimes, .sayTime: return true
        default: return false
        }
    }
}

enum DinoActivity: String, Codable, CaseIterable, Sendable {
    case breakfast, play, lunch, fruit, nest
    var hour: Int {
        switch self {
        case .breakfast: return 8
        case .play: return 10
        case .lunch: return 12
        case .fruit: return 3
        case .nest: return 7
        }
    }
    var symbol: String {
        switch self {
        case .breakfast: return "cup.and.saucer.fill"
        case .play: return "soccerball"
        case .lunch: return "fork.knife"
        case .fruit: return "carrot.fill"
        case .nest: return "moon.stars.fill"
        }
    }
    var titleKey: String { "dino.activity.\(rawValue)" }
}

struct QuestionRecipe: Equatable, Sendable {
    let kind: ClockQuestionKind
    var optionCount: Int = 4
    var firstAttemptHour: Int? = nil
    /// Nil retains the level defaults for free practice and standalone examples.
    var time: DinoPracticeTime? = nil
    var difficulty: DinoQuestionDifficulty? = nil
}

struct LevelConfiguration: Identifiable, Sendable {
    let id: Int
    let worldID: Int
    let titleKey: String
    let instructionKey: String
    let allowedHours: [Int]
    let difficulty: Int
    let questionCount: Int
    let isBoss: Bool
    let recipes: [QuestionRecipe]
    var allowedMinutes: [Int] = [0]
    var minuteStep: Int = 60
    var icon: String { isBoss ? "trophy.fill" : recipes[0].kind.symbol }

    func time(for recipe: QuestionRecipe) -> DinoPracticeTime { recipe.time ?? timeFamily }
    func plannedDifficulty(for recipe: QuestionRecipe) -> DinoQuestionDifficulty { recipe.difficulty ?? .introduction }
    func skill(for recipe: QuestionRecipe) -> DinoQuestionSkill { .init(kind: recipe.kind, time: time(for: recipe)) }

    /// Five questions interleave the selected skills, giving the two newest skills an extra turn.
    /// A boss visits each of its ten distinct skills exactly once.
    var recipeOrder: [Int] {
        if isBoss || recipes.count > 3 { return Array(0..<questionCount).map { $0 % recipes.count } }
        if recipes.count == 1 { return Array(repeating: 0, count: questionCount) }
        if recipes.count == 2 { return (0..<questionCount).map { $0 % 2 } }
        let reinforced = recipes.indices.sorted {
            let lhs = plannedDifficulty(for: recipes[$0]).rawValue, rhs = plannedDifficulty(for: recipes[$1]).rawValue
            return lhs == rhs ? $0 < $1 : lhs < rhs
        }.prefix(2).sorted()
        let order = [0, 1, 2] + reinforced
        return (0..<questionCount).map { order[$0 % order.count] }
    }
    func recipe(at index: Int) -> QuestionRecipe { recipes[recipeOrder[index % questionCount]] }

}

struct DinoWorld: Identifiable, Equatable, Sendable {
    let id: Int
    let ground: UInt32
    var titleKey: String { id == 1 ? "dino.jungle" : "dino.world.\(id).name" }
    var skillKey: String { id == 1 ? "dino.wholeHours" : "dino.world.\(id).skill" }
    var bossKey: String { id == 1 ? "dino.bossName" : "dino.world.\(id).boss" }
    var firstLevel: Int { (id - 1) * 10 + 1 }
    var bossLevel: Int { id * 10 }
    var normalLevels: ClosedRange<Int> { firstLevel...(bossLevel - 1) }
    var levels: ClosedRange<Int> { firstLevel...bossLevel }
    var minutes: [Int] {
        Array(stride(from: 0, to: 60, by: minuteStep))
    }
    var minuteStep: Int {
        switch id {
        case 1: return 60
        case 2: return 30
        case 3: return 15
        case 4: return 10
        case 5: return 5
        default: return 1
        }
    }
}

enum DinoWorldCatalog {
    static let worlds: [DinoWorld] = [
        .init(id: 1, ground: 0xDDEEB6), .init(id: 2, ground: 0xDCD6F7),
        .init(id: 3, ground: 0xFFD1A1), .init(id: 4, ground: 0xC7E8BE),
        .init(id: 5, ground: 0xD8EEF0), .init(id: 6, ground: 0xB8E4F5),
        .init(id: 7, ground: 0xD4DDC4), .init(id: 8, ground: 0xE8E9DA),
        .init(id: 9, ground: 0xF5D698), .init(id: 10, ground: 0xE8DFCC)
    ]
    static var lastLevel: Int { worlds.last!.bossLevel }
    static func world(_ id: Int) -> DinoWorld? { worlds.first { $0.id == id } }
}

/// A fixed teaching route. Time family and planned difficulty belong to each recipe, not to the world.
enum DinoLevelCatalog {
    private static let foundation: [ClockQuestionKind] = [
        .chooseAnalog, .chooseDigital, .trueFalse, .readDigital, .spokenTime,
        .sayTime, .setDigital, .setAnalog, .read24Hour, .dayPart
    ]
    private static let applied: [ClockQuestionKind] = [
        .match, .sortTimes, .advanceAnalog, .addTime, .subtractTime,
        .minutesBetween, .timeSequence, .daySchedule, .timeZone, .flightArrival
    ]
    private static func q(_ kind: ClockQuestionKind, _ time: DinoPracticeTime,
                          _ difficulty: DinoQuestionDifficulty) -> QuestionRecipe {
        .init(kind: kind, optionCount: kind.usesOptions ? 4 : 0, time: time, difficulty: difficulty)
    }

    private static let firstWorld: [[QuestionRecipe]] = [
        [q(.chooseAnalog, .whole, .introduction)],
        [q(.chooseAnalog, .whole, .familiar), q(.chooseDigital, .whole, .introduction)],
        [q(.chooseDigital, .whole, .familiar), q(.trueFalse, .whole, .introduction), q(.chooseAnalog, .whole, .familiar)],
        [q(.readDigital, .whole, .introduction), q(.chooseDigital, .whole, .familiar), q(.trueFalse, .whole, .familiar)],
        [q(.spokenTime, .whole, .introduction), q(.readDigital, .whole, .familiar), q(.chooseAnalog, .whole, .challenge)],
        [q(.sayTime, .whole, .introduction), q(.spokenTime, .whole, .familiar), q(.readDigital, .whole, .challenge)],
        [q(.setDigital, .whole, .introduction), q(.sayTime, .whole, .familiar), q(.chooseDigital, .whole, .challenge)],
        [q(.setAnalog, .whole, .introduction), q(.setDigital, .whole, .familiar), q(.sayTime, .whole, .challenge)],
        [q(.read24Hour, .whole, .introduction), q(.dayPart, .whole, .introduction), q(.setAnalog, .whole, .familiar)],
        foundation.map { q($0, .whole, [.chooseAnalog, .chooseDigital, .readDigital, .sayTime].contains($0) ? .challenge : .familiar) }
    ]

    /// Teach a finer clock with familiar reading skills; introduce calculations on the preceding clock.
    /// Each new combination appears in an ordinary lesson before its first boss assessment.
    private static func timeWorld(_ time: DinoPracticeTime, previous: DinoPracticeTime) -> [[QuestionRecipe]] {
        [
            [q(.chooseAnalog, time, .introduction), q(.chooseAnalog, previous, .challenge), q(.match, previous, .introduction)],
            [q(.chooseDigital, time, .introduction), q(.chooseAnalog, time, .familiar), q(.sortTimes, previous, .introduction)],
            [q(.trueFalse, time, .introduction), q(.chooseDigital, time, .familiar), q(.advanceAnalog, previous, .introduction)],
            [q(.readDigital, time, .introduction), q(.addTime, previous, .introduction), q(.subtractTime, previous, .introduction)],
            [q(.spokenTime, time, .introduction), q(.readDigital, time, .familiar), q(.minutesBetween, previous, .introduction)],
            [q(.sayTime, time, .introduction), q(.spokenTime, time, .familiar), q(.timeSequence, previous, .introduction)],
            [q(.setDigital, time, .introduction), q(.sayTime, time, .familiar), q(.daySchedule, previous, .introduction)],
            [q(.setAnalog, time, .introduction), q(.timeZone, previous, .introduction), q(.flightArrival, previous, .introduction)],
            [q(.read24Hour, time, .introduction), q(.dayPart, time, .introduction), q(.setAnalog, time, .familiar)],
            foundation.map { q($0, time, $0 == .chooseAnalog ? .challenge : .familiar) }
        ]
    }

    private static let seventhWorld: [[QuestionRecipe]] = [
        [q(.match, .minutes, .introduction), q(.chooseAnalog, .minutes, .challenge), q(.match, .whole, .familiar)],
        [q(.sortTimes, .minutes, .introduction), q(.match, .minutes, .familiar), q(.sortTimes, .half, .familiar)],
        [q(.advanceAnalog, .minutes, .introduction), q(.chooseDigital, .minutes, .challenge), q(.advanceAnalog, .quarter, .familiar)],
        [q(.addTime, .minutes, .introduction), q(.subtractTime, .minutes, .introduction), q(.addTime, .tenMinutes, .familiar)],
        [q(.minutesBetween, .minutes, .introduction), q(.readDigital, .minutes, .challenge), q(.minutesBetween, .fiveMinutes, .familiar)],
        [q(.timeSequence, .minutes, .introduction), q(.spokenTime, .minutes, .challenge), q(.timeSequence, .whole, .familiar)],
        [q(.daySchedule, .minutes, .introduction), q(.sayTime, .minutes, .challenge), q(.daySchedule, .half, .familiar)],
        [q(.timeZone, .minutes, .introduction), q(.flightArrival, .minutes, .introduction), q(.timeZone, .quarter, .familiar)],
        [q(.read24Hour, .minutes, .challenge), q(.dayPart, .minutes, .challenge), q(.flightArrival, .fiveMinutes, .familiar)],
        applied.map { q($0, .minutes, .familiar) }
    ]

    private static let eighthWorld: [[QuestionRecipe]] = [
        [q(.setAnalog, .minutes, .familiar), q(.setDigital, .minutes, .familiar), q(.match, .minutes, .challenge)],
        [q(.read24Hour, .minutes, .familiar), q(.dayPart, .minutes, .familiar), q(.sortTimes, .minutes, .familiar)],
        [q(.advanceAnalog, .minutes, .familiar), q(.addTime, .minutes, .familiar), q(.advanceAnalog, .quarter, .challenge)],
        [q(.subtractTime, .minutes, .familiar), q(.minutesBetween, .minutes, .familiar), q(.addTime, .tenMinutes, .challenge)],
        [q(.timeSequence, .minutes, .familiar), q(.daySchedule, .minutes, .familiar), q(.timeSequence, .whole, .challenge)],
        [q(.timeZone, .minutes, .familiar), q(.flightArrival, .minutes, .familiar), q(.daySchedule, .half, .challenge)],
        [q(.chooseAnalog, .minutes, .challenge), q(.chooseDigital, .minutes, .challenge), q(.trueFalse, .minutes, .challenge)],
        [q(.readDigital, .minutes, .challenge), q(.spokenTime, .minutes, .challenge), q(.sayTime, .minutes, .challenge)],
        [q(.setAnalog, .minutes, .challenge), q(.setDigital, .minutes, .challenge)],
        foundation.map { q($0, .minutes, .challenge) }
    ]

    private static let ninthWorld: [[QuestionRecipe]] = [
        [q(.advanceAnalog, .minutes, .challenge), q(.addTime, .minutes, .challenge), q(.advanceAnalog, .fiveMinutes, .familiar)],
        [q(.subtractTime, .minutes, .challenge), q(.minutesBetween, .minutes, .challenge), q(.subtractTime, .tenMinutes, .familiar)],
        [q(.timeSequence, .minutes, .challenge), q(.sortTimes, .minutes, .challenge), q(.sortTimes, .half, .challenge)],
        [q(.daySchedule, .minutes, .challenge), q(.addTime, .quarter, .familiar), q(.subtractTime, .half, .familiar)],
        [q(.timeZone, .minutes, .challenge), q(.flightArrival, .minutes, .challenge), q(.timeZone, .quarter, .challenge)],
        [q(.match, .minutes, .challenge), q(.minutesBetween, .fiveMinutes, .challenge), q(.flightArrival, .fiveMinutes, .challenge)],
        [q(.read24Hour, .minutes, .challenge), q(.dayPart, .minutes, .challenge), q(.trueFalse, .minutes, .challenge)],
        [q(.chooseAnalog, .minutes, .challenge), q(.chooseDigital, .minutes, .challenge), q(.readDigital, .minutes, .challenge)],
        [q(.setAnalog, .minutes, .challenge), q(.setDigital, .minutes, .challenge), q(.sayTime, .minutes, .challenge)],
        applied.map { q($0, .minutes, .challenge) }
    ]

    private static let finalKinds: [[ClockQuestionKind]] = [
        [.chooseAnalog, .chooseDigital, .trueFalse],
        [.readDigital, .spokenTime, .sayTime],
        [.setDigital, .setAnalog, .match],
        [.read24Hour, .dayPart, .sortTimes],
        [.advanceAnalog, .addTime, .subtractTime],
        [.minutesBetween, .timeSequence, .daySchedule],
        [.timeZone, .flightArrival, .read24Hour],
        [.sayTime, .setAnalog, .sortTimes],
        [.daySchedule, .timeZone, .flightArrival],
        [.spokenTime, .sayTime, .setAnalog, .read24Hour, .sortTimes, .minutesBetween, .timeSequence, .daySchedule, .timeZone, .flightArrival]
    ]
    private static let finalWorld = finalKinds.map { kinds in kinds.map { q($0, .minutes, .challenge) } }

    static let levels: [LevelConfiguration] = {
        let worlds = [firstWorld, timeWorld(.half, previous: .whole), timeWorld(.quarter, previous: .half),
                      timeWorld(.tenMinutes, previous: .quarter), timeWorld(.fiveMinutes, previous: .tenMinutes),
                      timeWorld(.minutes, previous: .fiveMinutes), seventhWorld, eighthWorld, ninthWorld, finalWorld]
        return worlds.enumerated().flatMap { worldIndex, plan in
            plan.enumerated().map { index, recipes in
                let world = DinoWorldCatalog.world(worldIndex + 1)!
                let id = worldIndex * 10 + index + 1, boss = index == 9
                return LevelConfiguration(id: id, worldID: world.id,
                    titleKey: boss ? world.bossKey : world.skillKey,
                    instructionKey: recipes[0].kind.instructionKey,
                    allowedHours: id == 1 ? [3, 6, 9, 12, 1] : Array(1...12), difficulty: index + 1,
                    questionCount: boss ? 10 : 5, isBoss: boss, recipes: recipes,
                    allowedMinutes: world.minutes, minuteStep: world.minuteStep)
            }
        }
    }()

    static func level(_ id: Int) -> LevelConfiguration? { levels.first { $0.id == id } }
}
