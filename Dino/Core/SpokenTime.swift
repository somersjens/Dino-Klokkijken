import Foundation
import CoreGraphics

/// The minute count and reference point used when saying a time, rather than elapsed minutes.
struct SpokenClockReadingHint: Equatable, Sendable {
    let minute: Int
    let language: String

    private var lesson: SpokenTimeLanguage { SpokenTimeCatalog.language(code: language) }
    private var rule: SpokenTimeRule { lesson.rule(minute) }
    var referenceMinute: Int { rule.referenceMinute }

    func spokenHour(for hour: Int) -> Int {
        let named = hour + rule.namedHourOffset
        return ((named - 1) % 12 + 12) % 12 + 1
    }

    var count: Int { abs(minute - referenceMinute) }
    var startMinute: Int { min(minute, referenceMinute) }
    var endMinute: Int { max(minute, referenceMinute) }
    /// Keep the actual minute on the scale, including an exact-minute question.
    var scaleMinutes: [Int] {
        var minutes = Array(stride(from: 0, to: 60, by: 5))
        minutes[DinoTimeReading.labelPosition(minute: minute) / 5] = minute
        return minutes
    }
    var relation: String { rule.relation }
    var scaleLabel: String { rule.scaleLabel ?? DinoTimeWords.number(count, language: language) }
}

/// SwiftUI can probe a view with zero width before its final placement.
/// Insets must never turn that temporary proposal into a negative clock frame.
struct DinoTimeReadingClockLayout {
    let width: CGFloat
    let diameter: CGFloat
    let height: CGFloat
    let center: CGPoint

    init(width proposedWidth: CGFloat, faceSize: CGFloat, minute: Int, language: String,
         shape: AnalogClockShape, showsGuide: Bool, showsSpokenHint: Bool) {
        let width = proposedWidth.isFinite ? max(1, proposedWidth) : 1
        let face = faceSize.isFinite ? max(1, faceSize) : 1
        let extent = SpokenClockGuideLayout.extent(shape: shape) * 2
        let diameter: CGFloat
        let height: CGFloat
        if showsGuide {
            diameter = max(1, width * 0.34)
            height = width * 1.14
        } else if showsSpokenHint {
            diameter = min(max(1, width - 16), face * extent)
            let drawingFace = diameter / extent
            let bounds = SpokenClockGuideLayout.verticalBounds(minute: minute, language: language,
                                                               shape: shape, faceSize: drawingFace)
            height = drawingFace * (bounds.upperBound - bounds.lowerBound) + 24
        } else {
            diameter = min(face, max(1, width - 52))
            height = diameter + 24
        }
        self.width = width
        self.diameter = diameter
        self.height = height
        center = CGPoint(x: width / 2, y: showsGuide ? width * 0.59 : height / 2)
    }
}

enum SpokenClockGuideLayout {
    static func extent(shape: AnalogClockShape, compact: Bool = false) -> Double {
        compact ? 0.84 : 0.86
    }

    static func scaleFontSize(faceSize: Double) -> Double { max(7, faceSize * 0.064) }

    static let arrowRadius = 0.275
    static func ringDiameter(faceSize: Double) -> Double {
        max(scaleFontSize(faceSize: faceSize) * 1.3, faceSize * 0.10) + 2 * max(2, faceSize * 0.014)
    }

    /// Only the rim scale needs outside space; the guide sits entirely inside the face.
    static func verticalBounds(minute: Int, language: String, shape: AnalogClockShape, faceSize: Double,
                               compact: Bool = false) -> ClosedRange<Double> {
        let face = max(1, faceSize)
        let hint = SpokenClockReadingHint(minute: minute, language: language)
        let font = scaleFontSize(faceSize: face)
        var lower = -0.5, upper = 0.5
        for scaleMinute in hint.scaleMinutes {
            let label = SpokenClockReadingHint(minute: scaleMinute, language: language).scaleLabel
            let numeric = label.allSatisfy(\.isNumber)
            let selected = scaleMinute == minute
            let diameter = ringDiameter(faceSize: face)
            // Conservative font metrics; the Canvas uses the exact measured text rectangle.
            let width = selected && numeric ? max(diameter, Double(label.count) * font * 0.72 + 2 * max(2, face * 0.014))
                : Double(label.count) * font * 0.72
            let height = selected && numeric ? width : font * 1.3
            let mark = ClockHandHintGeometry.minuteMark(minute: scaleMinute, shape: shape,
                labelSize: CGSize(width: width / face, height: height / face), gap: max(2 / face, 0.018))
            lower = min(lower, mark.label.y - height / (2 * face))
            upper = max(upper, mark.label.y + height / (2 * face) + (selected && !numeric ? 3 / face : 0))
        }
        let margin = compact ? max(3 / face, 0.025) : max(5 / face, 0.035)
        return (lower - margin)...(upper + margin)
    }
}

/// The teaching clock groups minutes by the construction used in that language.
enum DinoTimeReading {
    enum Region: String, CaseIterable, Sendable {
        case whole, past, beforeHalf, half, afterHalf, to
    }

    static func labelPosition(minute: Int) -> Int { ((minute + 2) / 5 * 5) % 60 }

    /// Keep twelve readable bubbles. Exact-minute answers replace the nearest
    /// five-minute description, so every chosen answer can be reviewed on the face.
    static func explanationTimes(target: ClockTime, rejected: [ClockTime]) -> [ClockTime] {
        var times = stride(from: 0, to: 60, by: 5).map { ClockTime(hour: target.hour, minute: $0) }
        for time in rejected + [target] where time.hour == target.hour {
            times[labelPosition(minute: time.minute) / 5] = time
        }
        return times
    }

    static func region(minute: Int, language: String) -> Region {
        SpokenTimeCatalog.language(code: language).rule(minute).region
    }

    /// Alternatives stay between this hour and the next. Early lessons also
    /// include quarters so four whole-hour answers never require other hours.
    static func distractors<R: RandomNumberGenerator>(target: ClockTime, minuteStep: Int,
                                                       using rng: inout R) -> [ClockTime] {
        let minutes = stride(from: 0, to: 60, by: min(15, max(1, minuteStep)))
        var chosen: [Int] = []
        for minute in minutes.shuffled(using: &rng) {
            let clear = ([target.minute] + chosen).allSatisfy {
                let difference = abs($0 - minute)
                return min(difference, 60 - difference) >= 5
            }
            if clear { chosen.append(minute) }
        }
        return chosen.map { ClockTime(hour: target.hour, minute: $0) }
    }
}

/// One tappable word. "-" means the player leaves that part of the sentence empty.
struct SpokenTimeChoice: Equatable, Hashable, Sendable {
    static let emptyID = "-"
    let id: String
    /// Spoken word, without a capital. The empty choice shows a dash.
    let word: String
    let accessibility: String
}

struct SpokenTimeSlot: Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    let choices: [SpokenTimeChoice]
}

/// The player's picks, in the same order as the language's slots.
struct SpokenTimeAnswer: Equatable, Hashable, Sendable {
    let choiceIDs: [String]
}

/// The choices and scoring policy for one clock in a locale's lesson.
struct SpokenTimePrompt: Equatable, Sendable {
    let slots: [SpokenTimeSlot]
    let correct: SpokenTimeAnswer
    let style: SpokenPhraseStyle
    let acceptsEquivalentPhrase: Bool

    var phrase: String { phrase(for: correct) }

    func phrase(for answer: SpokenTimeAnswer) -> String {
        let words = zip(slots, answer.choiceIDs).compactMap { slot, id in
            slot.choices.first { $0.id == id }?.word
        }
        return style.phrase(words)
    }

    func accepts(_ answer: SpokenTimeAnswer) -> Bool {
        if answer == correct { return true }
        guard acceptsEquivalentPhrase, answer.choiceIDs.count == slots.count,
              zip(slots, answer.choiceIDs).allSatisfy({ slot, id in
                  id == SpokenTimeChoice.emptyID || slot.choices.contains { $0.id == id }
              }) else { return false }
        let said = phrase(for: answer)
        return !said.isEmpty && said == phrase
    }
}

struct SpokenPhraseStyle: Equatable, Sendable {
    var separator = " "
    var capitalizesFirstWord = false
    var lowercasesFollowingWords = false
    var collapsesAdjacentRepeats = false
    var wrapsCompactWords = false

    static let legacy = Self(capitalizesFirstWord: true, lowercasesFollowingWords: true,
                             collapsesAdjacentRepeats: true)

    func displayedWord(_ word: String) -> String {
        capitalizesFirstWord ? word.prefix(1).uppercased() + word.dropFirst() : word
    }

    func phrase(_ words: [String]) -> String {
        let parts = words.reduce(into: [String]()) { result, word in
            if !collapsesAdjacentRepeats || result.last?.lowercased() != word.lowercased() {
                result.append(word)
            }
        }
        guard let first = parts.first else { return "" }
        let head = displayedWord(first)
        return ([head] + parts.dropFirst().map { lowercasesFollowingWords ? $0.lowercased() : $0 })
            .joined(separator: separator)
    }
}

/// A single minute's construction supplies its words, answer keys and visual explanation.
struct SpokenTimeRule: Sendable {
    let tokens: [String]
    let referenceMinute: Int
    let region: DinoTimeReading.Region
    var relation = ""
    var scaleLabel: String?
    var describesMinuteAsDigits = false
    var acceptsEquivalentPhrase = false

    // The tokens "@" and "+" name the current and next hour respectively.
    var namedHourOffset: Int { tokens.contains("+") ? 1 : 0 }
}

/// Clock speech for one language. Register it with AppLanguage, or inherit an existing lesson.
struct SpokenTimeLanguage: Sendable {
    let code: String
    /// Twelve at index 0 for a 12-hour lesson, then the remaining hours.
    let hours: [String]
    let slots: [SpokenSlotSpec]
    let minuteWord: @Sendable (Int) -> String
    let rule: @Sendable (Int) -> SpokenTimeRule
    var tileStyle = SpokenPhraseStyle()
    var descriptionStyle = SpokenPhraseStyle()
    var inflectHour: @Sendable (String, SpokenTimeRule) -> String = { word, _ in word }
    var omitsUnusedSlots = false
    var instructionKey: @Sendable (SpokenTimeRule) -> String? = { _ in nil }
    var promptNotation: DigitalHourNotation?

    func supports(minute: Int) -> Bool { (0..<60).contains(minute) }

    func description(for time: ClockTime, number: (Int) -> String) -> String {
        let reading = rule(time.minute)
        let tokens = resolvedTokens(reading, for: time)
        let words = zip(slots, tokens).compactMap { slot, id -> String? in
            guard id != SpokenTimeChoice.emptyID else { return nil }
            switch slot {
            case .hour:
                guard let hour = Self.hourValue(id) else { return nil }
                return inflectHour(hours[hour], reading)
            case .words(let spec):
                if reading.describesMinuteAsDigits, spec.id == "minutes", let count = spec.minuteValue(id) {
                    return number(count)
                }
                return spec.words[id] ?? Self.generatedMinuteValue(id).map(minuteWord)
            }
        }
        return descriptionStyle.phrase(words)
    }

    private func resolvedTokens(_ reading: SpokenTimeRule, for time: ClockTime) -> [String] {
        precondition(reading.tokens.count == slots.count, "\(code) phrase does not match its slots")
        return reading.tokens.map { token in
            switch token {
            case "@": return "h\(time.hour % hours.count)"
            case "+": return "h\((time.hour + 1) % hours.count)"
            default: return token
            }
        }
    }

    func prompt<R: RandomNumberGenerator>(for time: ClockTime, using rng: inout R) -> SpokenTimePrompt {
        precondition(supports(minute: time.minute))
        let reading = rule(time.minute)
        let correctIDs = resolvedTokens(reading, for: time)
        // Three hours in a row, always including the hour the sentence names.
        // The window slides so that hour can sit first, in the middle, or last.
        let namedHour = correctIDs.compactMap(Self.hourValue).first ?? time.hour % hours.count
        let shift = Int.random(in: 0...2, using: &rng)
        let windowStart = (namedHour - shift + hours.count) % hours.count
        let presentedHours = (0..<3).map { (windowStart + $0) % hours.count }

        let used = zip(slots, correctIDs).filter { !omitsUnusedSlots || $0.1 != SpokenTimeChoice.emptyID }
        let built = used.map { spec, correct -> SpokenTimeSlot in
            switch spec {
            case .words(let slot):
                var vocabulary = slot.choiceIDs.filter { $0 != SpokenTimeChoice.emptyID }
                if Self.generatedMinuteValue(correct) != nil && !vocabulary.contains(correct) { vocabulary.append(correct) }
                var kept: [String] = correct == SpokenTimeChoice.emptyID ? [] : [correct]
                var distractors = vocabulary.filter { $0 != correct }
                if slot.ordersByMinute {
                    let target = slot.minuteValue(correct) ?? 0
                    distractors.sort { lhs, rhs in
                        let left = abs((slot.minuteValue(lhs) ?? 99) - target)
                        let right = abs((slot.minuteValue(rhs) ?? 99) - target)
                        return left == right ? lhs < rhs : left < right
                    }
                } else {
                    distractors.shuffle(using: &rng)
                }
                while kept.count < 3, !distractors.isEmpty { kept.append(distractors.removeFirst()) }
                var shown = vocabulary.filter { kept.contains($0) }.compactMap { id -> SpokenTimeChoice? in
                    guard let word = slot.words[id] ?? Self.generatedMinuteValue(id).map(minuteWord) else { return nil }
                    return SpokenTimeChoice(id: id, word: word, accessibility: word)
                }
                if slot.ordersByMinute {
                    shown.sort { (slot.minuteValue($0.id) ?? 0) < (slot.minuteValue($1.id) ?? 0) }
                }
                return SpokenTimeSlot(id: slot.id, title: slot.title, choices: shown)
            case .hour(let title):
                let hourChoices = presentedHours.map { hour in
                    let word = inflectHour(hours[hour], reading)
                    return SpokenTimeChoice(id: "h\(hour)", word: word, accessibility: word)
                }
                return SpokenTimeSlot(id: "hour", title: title, choices: hourChoices)
            }
        }
        return SpokenTimePrompt(slots: built, correct: SpokenTimeAnswer(choiceIDs: used.map { $0.1 }),
                                style: tileStyle, acceptsEquivalentPhrase: reading.acceptsEquivalentPhrase)
    }

    private static func hourValue(_ id: String) -> Int? {
        id.hasPrefix("h") ? Int(id.dropFirst()) : nil
    }

    fileprivate static func generatedMinuteValue(_ id: String) -> Int? {
        id.hasPrefix("m") ? Int(id.dropFirst()) : nil
    }
}

enum SpokenTimeCatalog {
    static func language(code: String) -> SpokenTimeLanguage { AppLanguage.resolved(code).spokenTime }
}

enum SpokenSlotSpec: Sendable {
    case words(SpokenWordSlot)
    case hour(title: String)
}

struct SpokenWordSlot: Sendable {
    let id: String
    let title: String
    let choiceIDs: [String]
    let words: [String: String]
    var minuteValues: [String: Int] = [:]
    var ordersByMinute: Bool { !minuteValues.isEmpty }

    func minuteValue(_ id: String) -> Int? { minuteValues[id] ?? SpokenTimeLanguage.generatedMinuteValue(id) }
}

extension SpokenTimeLanguage {
    static let french = Self(
        code: "fr", hours: (0..<12).map { frenchClockHour($0 == 0 ? 12 : $0) },
        slots: [
            .hour(title: "Heures"),
            .words(.init(id: "minutes", title: "Minutes", choiceIDs: (1..<60).map { "m\($0)" },
                         words: [:], minuteValues: ["m1": 1])),
            .words(.init(id: "expression", title: "Formule",
                         choiceIDs: ["quarterPast", "half", "quarterTo"],
                         words: ["quarterPast": "et quart", "half": "et demie", "quarterTo": "moins le quart"])),
            .words(.init(id: "remainingMinutes", title: "Minutes",
                         choiceIDs: ["before5", "before10", "before20"],
                         words: ["before5": "moins cinq", "before10": "moins dix", "before20": "moins vingt"]))
        ],
        minuteWord: { frenchClockNumber($0) },
        rule: { minute in
            switch minute {
            case 0:
                return .init(tokens: ["@", "-", "-", "-"], referenceMinute: 0, region: .whole)
            case 15:
                return .init(tokens: ["@", "-", "quarterPast", "-"], referenceMinute: 0, region: .past,
                             scaleLabel: "quart")
            case 30:
                return .init(tokens: ["@", "-", "half", "-"], referenceMinute: 0, region: .half,
                             scaleLabel: "demie")
            case 45:
                return .init(tokens: ["+", "-", "quarterTo", "-"], referenceMinute: 60, region: .to,
                             relation: "moins", scaleLabel: "quart")
            case 40, 50, 55:
                return .init(tokens: ["+", "-", "-", "before\(60 - minute)"], referenceMinute: 60,
                             region: .to, relation: "moins")
            default:
                return .init(tokens: ["@", "m\(minute)", "-", "-"], referenceMinute: 0, region: .past)
            }
        },
        omitsUnusedSlots: true
    )

    private static func frenchClockHour(_ value: Int) -> String {
        "\(frenchClockNumber(value)) \(value == 1 ? "heure" : "heures")"
    }

    private static func frenchClockNumber(_ value: Int) -> String {
        let small = ["zéro", "une", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf",
                     "dix", "onze", "douze", "treize", "quatorze", "quinze", "seize",
                     "dix-sept", "dix-huit", "dix-neuf"]
        guard value >= 20 else { return small[value] }
        let tens = ["vingt", "trente", "quarante", "cinquante"][value / 10 - 2]
        switch value % 10 {
        case 0: return tens
        case 1: return "\(tens) et une"
        default: return "\(tens)-\(small[value % 10])"
        }
    }

    static func frenchDigitalTime(_ time: ClockTime) -> String {
        let hour = switch time.hour {
        case 0: "minuit"
        case 12: "midi"
        default: frenchClockHour(time.hour)
        }
        return time.minute == 0 ? hour : "\(hour) \(frenchClockNumber(time.minute))"
    }

    static let urdu = Self(
        code: "ur", hours: (0..<12).map { urduNumber($0 == 0 ? 12 : $0) },
        slots: [
            .words(.init(id: "quarter", title: "وقت کا لفظ",
                         choiceIDs: ["quarterPast", "exact", "quarterTo"],
                         words: ["quarterPast": "سوا", "exact": "ٹھیک", "quarterTo": "پونے"])),
            .hour(title: "گھنٹہ"),
            .words(.init(id: "minutes", title: "منٹ",
                         choiceIDs: (1..<60).map { "m\($0)" }, words: [:],
                         minuteValues: ["m1": 1]))
        ],
        minuteWord: { "\(urduNumber($0)) منٹ" },
        rule: { minute in
            switch minute {
            case 0:
                return .init(tokens: ["-", "@", "-"], referenceMinute: 0, region: .whole)
            case 15:
                return .init(tokens: ["quarterPast", "@", "-"], referenceMinute: 0, region: .past)
            case 30:
                return .init(tokens: ["-", "@", "-"], referenceMinute: 0, region: .half)
            case 45:
                return .init(tokens: ["quarterTo", "+", "-"], referenceMinute: 60, region: .to)
            default:
                return .init(tokens: ["-", "@", "m\(minute)"], referenceMinute: 0, region: .past)
            }
        },
        inflectHour: { hour, rule in
            if rule.region == .half {
                switch hour {
                case "ایک": return "ڈیڑھ بجے"
                case "دو": return "ڈھائی بجے"
                default: return "ساڑھے \(hour) بجے"
                }
            }
            return rule.tokens[2] == "-" ? "\(hour) بجے" : "\(hour) بج کر"
        },
        omitsUnusedSlots: true, promptNotation: .twelve
    )

    // The forms from 1 to 59 are used for hours and exact minutes.
    static func urduNumber(_ value: Int) -> String {
        urduNumbers[value]
    }

    private static let urduNumbers = [
        "صفر", "ایک", "دو", "تین", "چار", "پانچ", "چھ", "سات", "آٹھ", "نو",
        "دس", "گیارہ", "بارہ", "تیرہ", "چودہ", "پندرہ", "سولہ", "سترہ", "اٹھارہ", "انیس",
        "بیس", "اکیس", "بائیس", "تیئیس", "چوبیس", "پچیس", "چھبیس", "ستائیس", "اٹھائیس", "انتیس",
        "تیس", "اکتیس", "بتیس", "تینتیس", "چونتیس", "پینتیس", "چھتیس", "سینتیس", "اڑتیس", "انتالیس",
        "چالیس", "اکتالیس", "بیالیس", "تینتالیس", "چوالیس", "پینتالیس", "چھیالیس", "سینتالیس", "اڑتالیس", "انچاس",
        "پچاس", "اکیاون", "باون", "ترپن", "چوّن", "پچپن", "چھپن", "ستاون", "اٹھاون", "انسٹھ"
    ]

    static let hebrew = Self(
        code: "he", hours: (0..<12).map { hebrewNumber($0 == 0 ? 12 : $0) },
        slots: [
            .words(.init(id: "remaining", title: "כמה דקות",
                         choiceIDs: (1..<30).map { $0 == 15 ? "quarterTo" : "m\($0)" },
                         words: ["quarterTo": "רבע"], minuteValues: ["quarterTo": 15])),
            .hour(title: "איזו שעה"),
            .words(.init(id: "minutes", title: "כמה דקות",
                         choiceIDs: (1...30).map(hebrewPastToken),
                         words: Dictionary(uniqueKeysWithValues: (1...30).map { minute in
                             let word = switch minute {
                             case 15: "ורבע"
                             case 30: "וחצי"
                             default: "ו" + hebrewMinutes(minute)
                             }
                             return (hebrewPastToken(minute), word)
                         }), minuteValues: ["quarterPast": 15, "half": 30]))
        ],
        minuteWord: { hebrewMinutes($0) },
        rule: { minute in
            switch minute {
            case 0: return .init(tokens: ["-", "@", "-"], referenceMinute: 0, region: .whole)
            case 30: return .init(tokens: ["-", "@", "half"], referenceMinute: 0, region: .half)
            case 1..<30:
                return .init(tokens: ["-", "@", hebrewPastToken(minute)], referenceMinute: 0, region: .past)
            default:
                let remaining = 60 - minute
                return .init(tokens: [remaining == 15 ? "quarterTo" : "m\(remaining)", "+", "-"],
                             referenceMinute: 60, region: .to)
            }
        },
        inflectHour: { hour, rule in rule.region == .to ? "ל" + hour : hour },
        omitsUnusedSlots: true, promptNotation: .twelve
    )

    private static func hebrewPastToken(_ minute: Int) -> String {
        switch minute {
        case 15: return "quarterPast"
        case 30: return "half"
        default: return "m\(minute)"
        }
    }

    static func hebrewMinutes(_ minute: Int) -> String {
        switch minute {
        case 1: return "דקה אחת"
        case 2: return "שתי דקות"
        default: return "\(hebrewNumber(minute)) דקות"
        }
    }

    /// Feminine cardinal forms agree with both hour and minute in Hebrew.
    static func hebrewNumber(_ value: Int) -> String {
        let units = ["אפס", "אחת", "שתיים", "שלוש", "ארבע", "חמש", "שש", "שבע", "שמונה", "תשע"]
        let teens = ["עשר", "אחת עשרה", "שתים עשרה", "שלוש עשרה", "ארבע עשרה",
                     "חמש עשרה", "שש עשרה", "שבע עשרה", "שמונה עשרה", "תשע עשרה"]
        let tens = ["", "", "עשרים", "שלושים", "ארבעים", "חמישים"]
        if value < 10 { return units[value] }
        if value < 20 { return teens[value - 10] }
        let remainder = value % 10
        let decade = tens[value / 10]
        return remainder == 0 ? decade : "\(decade) ו\(units[remainder])"
    }

    static let simplifiedChinese = chinese(code: "zh-Hans", hourTitle: "几点", minuteTitle: "几分", hourWord: simplifiedChineseHour)
    static let traditionalChinese = chinese(code: "zh-Hant", hourTitle: "幾點", minuteTitle: "幾分", hourWord: traditionalChineseHour)

    private static func chinese(code: String, hourTitle: String, minuteTitle: String,
                                hourWord: (Int) -> String) -> Self {
        Self(
            code: code, hours: (0..<12).map { hourWord($0 == 0 ? 12 : $0) },
            slots: [
                .hour(title: hourTitle),
                .words(.init(id: "minutes", title: minuteTitle,
                             choiceIDs: (1..<60).map { $0 == 30 ? "half" : "m\($0)" },
                             words: ["half": "半"], minuteValues: ["half": 30]))
            ],
            minuteWord: { chineseClockMinute($0) },
            rule: { minute in
                switch minute {
                case 0: return .init(tokens: ["@", "-"], referenceMinute: 0, region: .whole)
                case 30: return .init(tokens: ["@", "half"], referenceMinute: 0, region: .half)
                default: return .init(tokens: ["@", "m\(minute)"], referenceMinute: 0, region: .past)
                }
            },
            tileStyle: .init(separator: "", wrapsCompactWords: true),
            descriptionStyle: .init(separator: ""),
            omitsUnusedSlots: true, promptNotation: .twentyFour
        )
    }

    static func simplifiedChineseHour(_ hour: Int) -> String {
        (hour == 2 ? "两" : chineseNumber(hour)) + "点"
    }

    static func traditionalChineseHour(_ hour: Int) -> String {
        (hour == 2 ? "兩" : chineseNumber(hour)) + "點"
    }

    static func chineseClockMinute(_ minute: Int) -> String {
        (minute < 10 ? "零" : "") + chineseNumber(minute) + "分"
    }

    /// Spell the clock's hour and minute values, which are always below 60.
    private static func chineseNumber(_ value: Int) -> String {
        let digits = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
        if value < 10 { return digits[value] }
        let tens = value / 10
        let ones = value % 10
        return (tens == 1 ? "" : digits[tens]) + "十" + (ones == 0 ? "" : digits[ones])
    }

    static let japanese = Self(
        code: "ja", hours: (0..<12).map { japaneseHour($0 == 0 ? 12 : $0) },
        slots: [
            .hour(title: "なんじ"),
            .words(.init(id: "minutes", title: "なんぷん",
                         choiceIDs: (1..<60).map { $0 == 30 ? "half" : "m\($0)" },
                         words: ["half": "はん"], minuteValues: ["half": 30]))
        ],
        minuteWord: { japaneseMinute($0) },
        rule: { minute in
            switch minute {
            case 0: return .init(tokens: ["@", "-"], referenceMinute: 0, region: .whole)
            case 30: return .init(tokens: ["@", "half"], referenceMinute: 0, region: .half)
            default: return .init(tokens: ["@", "m\(minute)"], referenceMinute: 0, region: .past)
            }
        },
        tileStyle: .init(wrapsCompactWords: true),
        // The lesson names 12 as the hour. The local 12-hour display uses 午後0 instead.
        omitsUnusedSlots: true, promptNotation: .twentyFour
    )

    static func japaneseHour(_ hour: Int) -> String {
        let readings = ["れい", "いち", "に", "さん", "よ", "ご", "ろく", "しち", "はち", "く"]
        return japaneseTens(hour / 10) + (hour > 0 && hour.isMultiple(of: 10) ? "" : readings[hour % 10]) + "じ"
    }

    static func japaneseMinute(_ minute: Int) -> String {
        if minute == 0 { return "れいふん" }
        let endings = ["", "いっぷん", "にふん", "さんぷん", "よんぷん", "ごふん",
                       "ろっぷん", "ななふん", "はっぷん", "きゅうふん"]
        let tens = japaneseTens(minute / 10)
        if minute.isMultiple(of: 10) { return String(tens.dropLast()) + "っぷん" }
        return tens + endings[minute % 10]
    }

    private static func japaneseTens(_ tens: Int) -> String {
        ["", "じゅう", "にじゅう", "さんじゅう", "よんじゅう", "ごじゅう"][tens]
    }

    static let german = Self(
        code: "de", hours: (0..<12).map { germanNumber($0 == 0 ? 12 : $0) },
        slots: [
            .words(.init(id: "minutes", title: "Minuten", choiceIDs: ["m5", "m10", "quarter", "m20"],
                         words: ["quarter": "Viertel"], minuteValues: ["quarter": 15])),
            .words(.init(id: "direction", title: "Richtung", choiceIDs: ["before", "after"],
                         words: ["before": "vor", "after": "nach"])),
            .words(.init(id: "half", title: "Halb", choiceIDs: ["half"], words: ["half": "halb"])),
            .hour(title: "Stunde"),
            .words(.init(id: "closing", title: "Uhr", choiceIDs: ["oclock"], words: ["oclock": "Uhr"])),
            .words(.init(id: "exactMinutes", title: "Minuten", choiceIDs: ["m1", "m15", "m30", "m45", "m59"],
                         words: [:], minuteValues: ["m1": 1]))
        ],
        minuteWord: { germanNumber($0) },
        rule: { minute in
            switch minute {
            case 0:
                return .init(tokens: ["-", "-", "-", "@", "oclock", "-"],
                             referenceMinute: 0, region: .whole, scaleLabel: "Uhr")
            case 5, 10, 15, 20:
                return .init(tokens: [minute == 15 ? "quarter" : "m\(minute)", "after", "-", "@", "-", "-"],
                             referenceMinute: 0, region: .past, relation: "nach", scaleLabel: minute == 15 ? "Viertel" : nil)
            case 25:
                return .init(tokens: ["m5", "before", "half", "+", "-", "-"],
                             referenceMinute: 30, region: .beforeHalf, relation: "vor halb")
            case 30:
                return .init(tokens: ["-", "-", "half", "+", "-", "-"],
                             referenceMinute: 30, region: .half, scaleLabel: "halb")
            case 35:
                return .init(tokens: ["m5", "after", "half", "+", "-", "-"],
                             referenceMinute: 30, region: .afterHalf, relation: "nach halb")
            case 40, 45, 50, 55:
                return .init(tokens: [minute == 45 ? "quarter" : "m\(60 - minute)", "before", "-", "+", "-", "-"],
                             referenceMinute: 60, region: .to, relation: "vor", scaleLabel: minute == 45 ? "Viertel" : nil)
            default:
                return .init(tokens: ["-", "-", "-", "@", "oclock", "m\(minute)"],
                             referenceMinute: 0, region: .whole)
            }
        },
        tileStyle: .init(capitalizesFirstWord: true),
        inflectHour: { word, rule in word == "eins" && rule.tokens.contains("oclock") ? "ein" : word },
        omitsUnusedSlots: true,
        instructionKey: { rule in
            switch rule.region {
            case .whole: return "dino.question.sayTime.digitalWords"
            case .past, .to: return "dino.question.sayTime.aroundHour"
            case .beforeHalf, .half, .afterHalf: return "dino.question.sayTime.aroundHalf"
            }
        }
    )

    static func germanNumber(_ number: Int) -> String {
        let small = ["null", "eins", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun",
                     "zehn", "elf", "zwölf", "dreizehn", "vierzehn", "fünfzehn", "sechzehn", "siebzehn", "achtzehn", "neunzehn"]
        guard number >= 20 else { return small[number] }
        let tens = ["zwanzig", "dreißig", "vierzig", "fünfzig"][number / 10 - 2]
        let ones = number % 10
        return ones == 0 ? tens : (ones == 1 ? "ein" : small[ones]) + "und" + tens
    }

    static let dutch = SpokenTimeLanguage(
        code: "nl",
        hours: ["twaalf", "een", "twee", "drie", "vier", "vijf", "zes", "zeven", "acht", "negen", "tien", "elf"],
        slots: [
            .words(.init(id: "minutes", title: "Minuten", choiceIDs: ["-", "vijf", "tien", "kwart"],
                         words: ["vijf": "vijf", "tien": "tien", "kwart": "kwart"],
                         minuteValues: ["vijf": 5, "tien": 10, "kwart": 15])),
            .words(.init(id: "direction", title: "Richting", choiceIDs: ["-", "voor", "over"],
                         words: ["voor": "voor", "over": "over"])),
            .words(.init(id: "half", title: "Half", choiceIDs: ["-", "half"],
                         words: ["half": "half"])),
            .hour(title: "Uur"),
            .words(.init(id: "closing", title: "Heel uur", choiceIDs: ["-", "uur"],
                         words: ["uur": "uur"]))
        ],
        minuteWord: { dutchMinutes[$0] },
        rule: { minute in
            switch minute {
            case 0:
                return .init(tokens: ["-", "-", "-", "@", "uur"], referenceMinute: 0, region: .whole,
                             scaleLabel: "uur", acceptsEquivalentPhrase: true)
            case 1...15:
                return .init(tokens: [dutchMinuteToken(minute), "over", "-", "@", "-"],
                             referenceMinute: 0, region: .past, relation: "over",
                             scaleLabel: minute == 15 ? "kwart" : nil, describesMinuteAsDigits: !minute.isMultiple(of: 5))
            case 16...29:
                return .init(tokens: [dutchMinuteToken(30 - minute), "voor", "half", "+", "-"],
                             referenceMinute: 30, region: .beforeHalf, relation: "voor half",
                             describesMinuteAsDigits: !minute.isMultiple(of: 5))
            case 30:
                return .init(tokens: ["-", "-", "half", "+", "-"], referenceMinute: 30, region: .half, scaleLabel: "half")
            case 31...44:
                return .init(tokens: [dutchMinuteToken(minute - 30), "over", "half", "+", "-"],
                             referenceMinute: 30, region: .afterHalf, relation: "over half",
                             describesMinuteAsDigits: !minute.isMultiple(of: 5))
            default:
                return .init(tokens: [dutchMinuteToken(60 - minute), "voor", "-", "+", "-"],
                             referenceMinute: 60, region: .to, relation: "voor",
                             scaleLabel: minute == 45 ? "kwart" : nil, describesMinuteAsDigits: !minute.isMultiple(of: 5))
            }
        },
        tileStyle: .legacy
    )

    static let english = SpokenTimeLanguage(
        code: "en",
        hours: ["twelve", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven"],
        slots: [
            .words(.init(id: "minutes", title: "Minutes",
                         choiceIDs: ["-", "five", "ten", "quarter", "twenty", "twentyFive", "half"],
                         words: ["five": "five", "ten": "ten", "quarter": "quarter", "twenty": "twenty",
                                 "twentyFive": "twenty-five", "half": "half"],
                         minuteValues: ["five": 5, "ten": 10, "quarter": 15, "twenty": 20, "twentyFive": 25, "half": 30])),
            .words(.init(id: "direction", title: "Direction", choiceIDs: ["-", "past", "to"],
                         words: ["past": "past", "to": "to"])),
            .hour(title: "Hour"),
            .words(.init(id: "closing", title: "O'clock", choiceIDs: ["-", "oclock"],
                         words: ["oclock": "o\u{2019}clock"]))
        ],
        minuteWord: { englishMinutes[$0] },
        rule: { minute in
            if minute == 0 {
                return .init(tokens: ["-", "-", "@", "oclock"], referenceMinute: 0, region: .whole,
                             scaleLabel: "o’clock", acceptsEquivalentPhrase: true)
            }
            let past = minute <= 30
            let count = past ? minute : 60 - minute
            let token = englishMinuteToken(count)
            let scaleLabel = count == 15 ? "quarter" : count == 30 ? "half" : nil
            return .init(tokens: [token, past ? "past" : "to", past ? "@" : "+", "-"],
                         referenceMinute: past ? 0 : 60, region: past ? .past : .to,
                         relation: past ? "past" : "to", scaleLabel: scaleLabel,
                         describesMinuteAsDigits: scaleLabel == nil)
        },
        tileStyle: .legacy
    )

    private static func dutchMinuteToken(_ count: Int) -> String {
        switch count {
        case 5: return "vijf"
        case 10: return "tien"
        case 15: return "kwart"
        default: return "m\(count)"
        }
    }

    private static func englishMinuteToken(_ count: Int) -> String {
        switch count {
        case 5: return "five"
        case 10: return "ten"
        case 15: return "quarter"
        case 20: return "twenty"
        case 25: return "twentyFive"
        case 30: return "half"
        default: return "m\(count)"
        }
    }

    private static let dutchMinutes = ["", "een", "twee", "drie", "vier", "vijf", "zes", "zeven", "acht", "negen", "tien",
        "elf", "twaalf", "dertien", "veertien", "vijftien", "zestien", "zeventien", "achttien", "negentien", "twintig",
        "eenentwintig", "tweeëntwintig", "drieëntwintig", "vierentwintig", "vijfentwintig",
        "zesentwintig", "zevenentwintig", "achtentwintig", "negenentwintig"]
    private static let englishMinutes = ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
        "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen",
        "twenty", "twenty-one", "twenty-two", "twenty-three", "twenty-four", "twenty-five",
        "twenty-six", "twenty-seven", "twenty-eight", "twenty-nine"]
}
