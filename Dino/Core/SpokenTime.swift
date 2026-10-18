import Foundation

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

/// A language-specific question: which menus to show, and which choice is right for this clock.
struct SpokenTimePrompt: Equatable, Sendable {
    let slots: [SpokenTimeSlot]
    let correct: SpokenTimeAnswer

    var phrase: String { phrase(for: correct) }

    /// Joins the chosen words. Empty choices drop out, so "drie" + "uur" becomes "Drie uur".
    func phrase(for answer: SpokenTimeAnswer) -> String {
        let words = zip(slots, answer.choiceIDs).compactMap { slot, id -> String? in
            guard id != SpokenTimeChoice.emptyID else { return nil }
            return slot.choices.first { $0.id == id }?.word
        }
        guard let first = words.first else { return "" }
        let head = first.prefix(1).uppercased() + first.dropFirst()
        return ([String(head)] + words.dropFirst().map { $0.lowercased() }).joined(separator: " ")
    }
}

/// Clock speech for one language. Add a value to `SpokenTimeCatalog.all` to support another language.
struct SpokenTimeLanguage: Sendable {
    let code: String
    fileprivate let emptyAccessibility: String
    /// Twelve at index 0, then one through eleven.
    fileprivate let hours: [String]
    fileprivate let slots: [SpokenSlotSpec]
    /// One token per slot. "@" is this hour, "+" is the next hour.
    fileprivate let phrases: [Int: [String]]

    func supports(minute: Int) -> Bool { (0..<60).contains(minute) }

    func prompt<R: RandomNumberGenerator>(for time: ClockTime, using rng: inout R) -> SpokenTimePrompt {
        precondition(supports(minute: time.minute))
        var promptSlots = slots
        let tokens: [String]
        if let familiar = phrases[time.minute] {
            tokens = familiar
        } else {
            let minute = time.minute
            let count: Int
            if code == "nl" {
                count = minute < 15 ? minute : minute < 30 ? 30 - minute : minute < 45 ? minute - 30 : 60 - minute
                let wordID = "m\(count)"
                tokens = minute < 15 ? [wordID, "over", "-", "@", "-"]
                    : minute < 30 ? [wordID, "voor", "half", "+", "-"]
                    : minute < 45 ? [wordID, "over", "half", "+", "-"]
                    : [wordID, "voor", "-", "+", "-"]
            } else {
                count = min(minute, 60 - minute)
                tokens = ["m\(count)", minute < 30 ? "past" : "to", minute < 30 ? "@" : "+", "-"]
            }
            if case .words(let slot) = promptSlots[0] {
                var words = slot.words
                let wordID = "m\(count)"
                words[wordID] = Self.minuteNumber(count, language: code)
                promptSlots[0] = .words(.init(id: slot.id, title: slot.title,
                    choiceIDs: slot.choiceIDs + [wordID], words: words))
            }
        }
        precondition(tokens.count == slots.count, "\(code) phrase does not match its slots")
        let thisHour = time.hour % 12
        let nextHour = (time.hour + 1) % 12
        let correctIDs = tokens.map { token -> String in
            switch token {
            case "@": return "h\(thisHour)"
            case "+": return "h\(nextHour)"
            default: return token
            }
        }
        // The named hour and the other hour are the usual mix-up, plus one more choice.
        var hourIndexes: Set<Int> = [thisHour, nextHour]
        let extras = Array(0..<12).filter { !hourIndexes.contains($0) }.shuffled(using: &rng)
        hourIndexes.insert(extras[0])
        let presentedHours = hourIndexes.sorted()

        let built = zip(promptSlots, correctIDs).map { spec, correct -> SpokenTimeSlot in
            switch spec {
            case .words(let slot):
                let vocabulary = slot.choiceIDs.filter { $0 != SpokenTimeChoice.emptyID }
                var kept: [String] = correct == SpokenTimeChoice.emptyID ? [] : [correct]
                var distractors = vocabulary.filter { $0 != correct }.shuffled(using: &rng)
                while kept.count < 3, !distractors.isEmpty { kept.append(distractors.removeFirst()) }
                let shown = [SpokenTimeChoice.emptyID] + vocabulary.filter { kept.contains($0) }
                return SpokenTimeSlot(id: slot.id, title: slot.title, choices: shown.map { choice($0, words: slot.words) })
            case .hour(let title):
                let hourChoices = presentedHours.map { hour in
                    SpokenTimeChoice(id: "h\(hour)", word: self.hours[hour], accessibility: self.hours[hour])
                }
                return SpokenTimeSlot(id: "hour", title: title, choices: [emptyChoice] + hourChoices)
            }
        }
        return SpokenTimePrompt(slots: built, correct: SpokenTimeAnswer(choiceIDs: correctIDs))
    }

    private static func minuteNumber(_ value: Int, language: String) -> String {
        let dutch = ["", "een", "twee", "drie", "vier", "vijf", "zes", "zeven", "acht", "negen", "tien",
                     "elf", "twaalf", "dertien", "veertien", "vijftien", "zestien", "zeventien", "achttien", "negentien",
                     "twintig", "eenentwintig", "tweeëntwintig", "drieëntwintig", "vierentwintig", "vijfentwintig",
                     "zesentwintig", "zevenentwintig", "achtentwintig", "negenentwintig"]
        let english = ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
                       "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen",
                       "twenty", "twenty-one", "twenty-two", "twenty-three", "twenty-four", "twenty-five",
                       "twenty-six", "twenty-seven", "twenty-eight", "twenty-nine"]
        return (language == "nl" ? dutch : english)[value]
    }

    private var emptyChoice: SpokenTimeChoice {
        SpokenTimeChoice(id: SpokenTimeChoice.emptyID, word: "—", accessibility: emptyAccessibility)
    }

    private func choice(_ id: String, words: [String: String]) -> SpokenTimeChoice {
        if id == SpokenTimeChoice.emptyID { return emptyChoice }
        let word = words[id]!
        return SpokenTimeChoice(id: id, word: word, accessibility: word)
    }
}

enum SpokenTimeCatalog {
    /// Dutch stays first: an unknown language code uses it until that language is added here.
    static let all: [SpokenTimeLanguage] = [.dutch, .english]

    static func language(code: String) -> SpokenTimeLanguage {
        let normalized = code.lowercased().replacingOccurrences(of: "_", with: "-")
        let base = normalized.split(separator: "-").first.map(String.init) ?? normalized
        return all.first { $0.code == base } ?? all[0]
    }
}

private enum SpokenSlotSpec: Sendable {
    case words(SpokenWordSlot)
    case hour(title: String)
}

private struct SpokenWordSlot: Sendable {
    let id: String
    let title: String
    let choiceIDs: [String]
    let words: [String: String]
}

private extension SpokenTimeLanguage {
    static let dutch = SpokenTimeLanguage(
        code: "nl",
        emptyAccessibility: "Niets",
        hours: ["twaalf", "een", "twee", "drie", "vier", "vijf", "zes", "zeven", "acht", "negen", "tien", "elf"],
        slots: [
            .words(.init(id: "minutes", title: "Minuten", choiceIDs: ["-", "vijf", "tien", "kwart"],
                         words: ["vijf": "vijf", "tien": "tien", "kwart": "kwart"])),
            .words(.init(id: "direction", title: "Richting", choiceIDs: ["-", "voor", "over"],
                         words: ["voor": "voor", "over": "over"])),
            .words(.init(id: "half", title: "Half", choiceIDs: ["-", "half"],
                         words: ["half": "half"])),
            .hour(title: "Uur"),
            .words(.init(id: "closing", title: "Heel uur", choiceIDs: ["-", "uur"],
                         words: ["uur": "uur"]))
        ],
        phrases: [
            0: ["-", "-", "-", "@", "uur"],
            5: ["vijf", "over", "-", "@", "-"],
            10: ["tien", "over", "-", "@", "-"],
            15: ["kwart", "over", "-", "@", "-"],
            20: ["tien", "voor", "half", "+", "-"],
            25: ["vijf", "voor", "half", "+", "-"],
            30: ["-", "-", "half", "+", "-"],
            35: ["vijf", "over", "half", "+", "-"],
            40: ["tien", "over", "half", "+", "-"],
            45: ["kwart", "voor", "-", "+", "-"],
            50: ["tien", "voor", "-", "+", "-"],
            55: ["vijf", "voor", "-", "+", "-"]
        ]
    )

    static let english = SpokenTimeLanguage(
        code: "en",
        emptyAccessibility: "Nothing",
        hours: ["twelve", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven"],
        slots: [
            .words(.init(id: "minutes", title: "Minutes",
                         choiceIDs: ["-", "five", "ten", "quarter", "twenty", "twentyFive", "half"],
                         words: ["five": "five", "ten": "ten", "quarter": "quarter", "twenty": "twenty",
                                 "twentyFive": "twenty-five", "half": "half"])),
            .words(.init(id: "direction", title: "Direction", choiceIDs: ["-", "past", "to"],
                         words: ["past": "past", "to": "to"])),
            .hour(title: "Hour"),
            .words(.init(id: "closing", title: "O'clock", choiceIDs: ["-", "oclock"],
                         words: ["oclock": "o\u{2019}clock"]))
        ],
        phrases: [
            0: ["-", "-", "@", "oclock"],
            5: ["five", "past", "@", "-"],
            10: ["ten", "past", "@", "-"],
            15: ["quarter", "past", "@", "-"],
            20: ["twenty", "past", "@", "-"],
            25: ["twentyFive", "past", "@", "-"],
            30: ["half", "past", "@", "-"],
            35: ["twentyFive", "to", "+", "-"],
            40: ["twenty", "to", "+", "-"],
            45: ["quarter", "to", "+", "-"],
            50: ["ten", "to", "+", "-"],
            55: ["five", "to", "+", "-"]
        ]
    )
}
