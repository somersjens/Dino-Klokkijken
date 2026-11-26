import Foundation

/// Standard Arabic clock language used in the Saudi lesson.
enum DinoArabicTime {
    static let hours = [
        "الثانية عشرة", "الواحدة", "الثانية", "الثالثة", "الرابعة", "الخامسة",
        "السادسة", "السابعة", "الثامنة", "التاسعة", "العاشرة", "الحادية عشرة"
    ]

    static func minutePhrase(_ count: Int, afterExcept: Bool = false) -> String {
        switch count {
        case 1: return "دقيقة واحدة"
        case 2: return afterExcept ? "دقيقتين" : "دقيقتان"
        default:
            let number = feminineNumber(count, accusative: afterExcept)
            return count <= 10 ? "\(number) دقائق" : "\(number) دقيقة"
        }
    }

    static func spokenUnit(_ count: Int, number: String, singular: String, dual: String, plural: String) -> String {
        switch count {
        case 1: return "\(singular) واحدة"
        case 2: return dual
        case 3...10: return "\(feminineNumber(count)) \(plural)"
        case 11...99: return "\(feminineNumber(count)) \(singular)"
        default: return "\(number) \(singular)"
        }
    }

    private static func feminineNumber(_ number: Int, accusative: Bool = false) -> String {
        let units = ["صفر", "واحدة", accusative ? "اثنتين" : "اثنتان", "ثلاث", "أربع",
                     "خمس", "ست", "سبع", "ثماني", "تسع", "عشر"]
        switch number {
        case 0...10: return units[number]
        case 11: return "إحدى عشرة"
        case 12: return accusative ? "اثنتي عشرة" : "اثنتا عشرة"
        case 13...19: return "\(units[number - 10]) عشرة"
        default:
            let tens = ["عشر", "ثلاث", "أربع", "خمس", "ست", "سبع", "ثمان", "تسع"]
            let ending = tens[number / 10 - 2] + (accusative ? "ين" : "ون")
            let remainder = number % 10
            guard remainder != 0 else { return ending }
            let first: String
            switch (remainder, accusative) {
            case (1, true): first = "واحدةً"
            case (3...7, true), (9, true): first = units[remainder] + "ًا"
            case (8, true): first = "ثمانيًا"
            default: first = units[remainder]
            }
            return "\(first) و\(ending)"
        }
    }

    static func past(_ minute: Int) -> String {
        switch minute {
        case 0: return "تمامًا"
        case 15: return "والربع"
        case 30: return "والنصف"
        default: return "و" + minutePhrase(minute)
        }
    }

    static func to(_ minute: Int) -> String {
        minute == 15 ? "إلا ربعًا" : "إلا " + minutePhrase(minute, afterExcept: true)
    }

    static func suffixSlot(_ range: ClosedRange<Int>, title: String, id: String,
                           wording: (Int) -> String) -> SpokenSlotSpec {
        let counts = range.map { ("m\($0)", $0) }
        return .words(.init(id: id, title: title, choiceIDs: counts.map(\.0),
                            words: Dictionary(uniqueKeysWithValues: counts.map { ($0.0, wording($0.1)) }),
                            minuteValues: Dictionary(uniqueKeysWithValues: counts)))
    }
}

extension SpokenTimeLanguage {
    static let arabic = Self(
        code: "ar", hours: DinoArabicTime.hours,
        slots: [
            .hour(title: "الساعة"),
            DinoArabicTime.suffixSlot(0...30, title: "الدقائق", id: "pastMinutes", wording: DinoArabicTime.past),
            DinoArabicTime.suffixSlot(1...29, title: "الدقائق", id: "minutesTo", wording: DinoArabicTime.to)
        ],
        minuteWord: { DinoArabicTime.minutePhrase($0) },
        rule: { minute in
            let beforeNext = minute > 30
            let count = beforeNext ? 60 - minute : minute
            let token = "m\(count)"
            let region: DinoTimeReading.Region = switch minute {
            case 0: .whole
            case 30: .half
            case 31...59: .to
            default: .past
            }
            let label = [0: "تمامًا", 15: "ربع", 30: "نصف"][count]
            return .init(tokens: beforeNext ? ["+", "-", token] : ["@", token, "-"],
                         referenceMinute: beforeNext ? 60 : 0, region: region,
                         relation: minute == 0 ? "" : beforeNext ? "قبل" : "بعد", scaleLabel: label)
        },
        inflectHour: { hour, _ in "الساعة \(hour)" },
        omitsUnusedSlots: true,
        instructionKey: { rule in rule.referenceMinute == 60 ? "dino.question.sayTime.ar.to" : "dino.question.sayTime.ar.past" }
    )
}

extension DinoTimeVocabulary {
    static let arabic = Self(
        dayPartSuffixes: [.night: "ليلًا", .morning: "صباحًا", .afternoon: "بعد الظهر", .evening: "مساءً"],
        spokenHours: { DinoArabicTime.spokenUnit($0, number: $1, singular: "ساعة", dual: "ساعتان", plural: "ساعات") },
        spokenMinutes: { DinoArabicTime.spokenUnit($0, number: $1, singular: "دقيقة", dual: "دقيقتان", plural: "دقائق") },
        joinSpokenUnits: { "\($0) و\($1)" },
        shortHours: { "\($0) س" }, shortMinutes: { "\($0) د" },
        zoneUnit: "س", atlasZoneUnit: "س", shortHoursColumnWidth: 36,
        digitalQuestionsIncludeDayPart: true, decimalZoneHours: true
    )
}
