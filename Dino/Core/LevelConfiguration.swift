import Foundation

enum ClockQuestionKind: String, Codable, CaseIterable, Sendable {
    case chooseAnalog, chooseDigital, activity, setAnalog, setDigital, match
    case readDigital, spokenTime, trueFalse, dayPart, pairClocks, read24Hour, sortTimes, timeSequence
    case addTime, advanceAnalog, elapsedTime, subtractTime, schoolEnd, flightArrival, timeZone
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
        case .pairClocks: return "arrow.triangle.branch"
        case .sortTimes: return "list.number"
        case .timeSequence: return "ellipsis"
        case .addTime, .advanceAnalog: return "clock.arrow.2.circlepath"
        case .elapsedTime: return "stopwatch.fill"
        case .subtractTime: return "minus.circle.fill"
        case .schoolEnd: return "book.fill"
        case .flightArrival: return "airplane"
        case .timeZone: return "globe.europe.africa.fill"
        }
    }
    var usesOptions: Bool { ![.setAnalog, .setDigital, .advanceAnalog, .sortTimes, .pairClocks].contains(self) }
    var isExpanded: Bool { ![.chooseAnalog, .chooseDigital, .activity, .setAnalog, .setDigital, .match].contains(self) }
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
    var icon: String { isBoss ? "trophy.fill" : recipes[0].kind.symbol }
}

enum DinoLevelCatalog {
    static let levels: [LevelConfiguration] = (1...10).map { id in
        let recipes: [QuestionRecipe]
        switch id {
        case 1: recipes = [.init(kind: .chooseAnalog, optionCount: 2)]
        case 2: recipes = [.init(kind: .chooseAnalog)]
        case 3: recipes = [.init(kind: .chooseDigital, optionCount: 2)]
        case 4: recipes = [.init(kind: .chooseDigital)]
        case 5: recipes = [.init(kind: .activity)]
        case 6: recipes = [.init(kind: .setAnalog, optionCount: 0)]
        case 7: recipes = [.init(kind: .setDigital, optionCount: 0)]
        case 8: recipes = [.init(kind: .match)]
        case 9: recipes = [
            .init(kind: .chooseAnalog), .init(kind: .chooseDigital),
            .init(kind: .setAnalog, optionCount: 0), .init(kind: .setDigital, optionCount: 0),
            .init(kind: .chooseAnalog, optionCount: 4)
        ]
        default: recipes = [
            .init(kind: .chooseAnalog, firstAttemptHour: 3),
            .init(kind: .chooseAnalog, firstAttemptHour: 8),
            .init(kind: .chooseDigital, firstAttemptHour: 11),
            .init(kind: .chooseDigital, firstAttemptHour: 6),
            .init(kind: .chooseAnalog, optionCount: 4),
            .init(kind: .chooseDigital, optionCount: 4),
            .init(kind: .setAnalog, optionCount: 0),
            .init(kind: .setDigital, optionCount: 0), .init(kind: .match),
            .init(kind: .setAnalog, optionCount: 0)
        ]
        }
        return LevelConfiguration(id: id, worldID: 1, titleKey: "dino.level.\(id)",
                                  instructionKey: recipes[0].kind.instructionKey,
                                  allowedHours: id == 1 ? [3, 6, 9, 12, 1] : Array(1...12),
                                  difficulty: id, questionCount: id == 10 ? 10 : 5,
                                  isBoss: id == 10, recipes: recipes)
    }

    static func level(_ id: Int) -> LevelConfiguration? { levels.first { $0.id == id } }
}
