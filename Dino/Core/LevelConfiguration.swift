import Foundation

enum ClockQuestionKind: String, Codable, CaseIterable, Sendable {
    case chooseAnalog, chooseDigital, activity, setAnalog, setDigital, match
    case readDigital, spokenTime, trueFalse, dayPart, read24Hour, sortTimes, timeSequence
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
    var usesOptions: Bool { ![.setAnalog, .setDigital, .match, .advanceAnalog, .sortTimes].contains(self) }
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
    var allowedMinutes: [Int] = [0]
    var minuteStep: Int = 60
    var icon: String { isBoss ? "trophy.fill" : recipes[0].kind.symbol }
}

struct DinoWorld: Identifiable, Sendable {
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
        switch id {
        case 1: return [0]
        case 2: return [30]
        case 3: return [15, 45]
        case 4, 7, 9: return Array(stride(from: 0, to: 60, by: 5))
        default: return Array(0..<60)
        }
    }
    var minuteStep: Int {
        switch id {
        case 1: return 60
        case 2: return 30
        case 3: return 15
        case 4, 7, 9: return 5
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

enum DinoLevelCatalog {
    static let levels: [LevelConfiguration] = (1...100).map { id in
        let worldID = (id - 1) / 10 + 1
        let position = (id - 1) % 10 + 1
        let world = DinoWorldCatalog.world(worldID)!
        if worldID > 1 {
            let kinds: [ClockQuestionKind]
            switch worldID {
            case 2, 3, 4, 5:
                kinds = [.chooseAnalog, .chooseAnalog, .chooseDigital, .spokenTime,
                         .trueFalse, .setAnalog, .setDigital, .match, .spokenTime]
            case 6:
                kinds = [.readDigital, .chooseDigital, .readDigital, .setDigital,
                         .spokenTime, .trueFalse, .sortTimes, .setDigital, .timeSequence]
            case 7:
                kinds = [.dayPart, .read24Hour, .dayPart, .read24Hour,
                         .match, .sortTimes, .read24Hour, .match, .timeSequence]
            case 8:
                kinds = [.match, .match, .chooseDigital, .setAnalog,
                         .setDigital, .trueFalse, .match, .match, .spokenTime]
            case 9:
                kinds = [.elapsedTime, .addTime, .elapsedTime, .advanceAnalog,
                         .subtractTime, .schoolEnd, .timeSequence, .flightArrival, .elapsedTime]
            default:
                kinds = [.chooseAnalog, .spokenTime, .readDigital, .setAnalog,
                         .read24Hour, .match, .elapsedTime, .addTime, .sortTimes]
            }
            let boss = position == 10
            let selected = boss ? kinds + [worldID == 9 ? .elapsedTime : .setDigital] : [kinds[position - 1]]
            let recipes = selected.map { kind in
                QuestionRecipe(kind: kind, optionCount: kind.usesOptions ? (position == 1 && !kind.isExpanded ? 2 : 4) : 0)
            }
            return LevelConfiguration(id: id, worldID: worldID,
                                      titleKey: boss ? world.bossKey : world.skillKey,
                                      instructionKey: recipes[0].kind.instructionKey,
                                      allowedHours: Array(1...12), difficulty: position,
                                      questionCount: boss ? 10 : 5, isBoss: boss, recipes: recipes,
                                      allowedMinutes: world.minutes, minuteStep: world.minuteStep)
        }
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
