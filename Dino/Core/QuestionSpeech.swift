import Foundation

/// One installed Apple voice the question title can be read with.
struct DinoSpeechVoice: Equatable, Sendable {
    var identifier: String
    var name: String
    var language: String
    /// Matches `AVSpeechSynthesisVoiceQuality`: 1 default, 2 enhanced, 3 premium.
    var quality: Int
}

/// Chooses the best installed Apple voice for the language selected in the app.
/// Netherlands Dutch outranks Belgian Dutch, and British English outranks other English.
/// A matching region stays ahead of a higher-quality voice from another region.
enum DinoSpeechVoicePicker {
    static func preferredLanguageIdentifier(for languageCode: String) -> String {
        switch baseCode(languageCode) {
        case "nl": return "nl-NL"
        case "en": return "en-GB"
        default:
            let trimmed = normalized(languageCode)
            return trimmed.isEmpty ? "en-GB" : trimmed
        }
    }

    static func bestVoice(for languageCode: String, among voices: [DinoSpeechVoice]) -> DinoSpeechVoice? {
        let base = baseCode(languageCode)
        let preferred = preferredLanguageIdentifier(for: base).lowercased()
        let matching = voices.filter { voice in
            let language = normalized(voice.language)
            return language == base || language.hasPrefix(base + "-")
        }
        let spoken = matching.filter { !isNovelty($0) }
        let pool = spoken.isEmpty ? matching : spoken
        return pool.max { lhs, rhs in
            let left = rank(lhs, preferred: preferred)
            let right = rank(rhs, preferred: preferred)
            if left != right { return left < right }
            return lhs.identifier > rhs.identifier
        }
    }

    private static func baseCode(_ languageCode: String) -> String {
        let language = normalized(languageCode)
        return language.split(separator: "-").first.map(String.init) ?? language
    }

    private static func normalized(_ language: String) -> String {
        language.replacingOccurrences(of: "_", with: "-").lowercased()
    }

    /// Quality steps are 100 points apart. The region bonus beats one better tier
    /// from another country, and the Siri bonus stays inside a single quality tier.
    private static func rank(_ voice: DinoSpeechVoice, preferred: String) -> Int {
        var score = voice.quality * 100
        if normalized(voice.language) == preferred { score += 250 }
        let identifier = voice.identifier.lowercased()
        if identifier.contains("siri") || voice.name.lowercased().contains("siri") { score += 30 }
        if identifier.contains("compact") || identifier.contains("eloquence") { score -= 20 }
        return score
    }

    private static func isNovelty(_ voice: DinoSpeechVoice) -> Bool {
        let folded = (voice.identifier + " " + voice.name).lowercased().replacingOccurrences(of: " ", with: "")
        let names = ["badnews", "bahh", "bells", "boing", "bubbles", "cellos", "deranged",
                     "goodnews", "hysterical", "pipeorgan", "trinoids", "whisper", "zarvox"]
        return names.contains { folded.contains($0) }
    }
}

/// The question title repeats the sum only when hearing it does not already give the answer.
/// Only movement gets a color: forward is green and backward is red.
struct DinoQuestionPrompt: Equatable, Sendable {
    struct Argument: Equatable, Sendable {
        var text: String
        var emphasis: Emphasis
    }

    enum Emphasis: Equatable, Sendable {
        case plain, forward, backward
    }

    var plainKey: String
    var formatKey: String?
    var arguments: [Argument]

    func spoken(localizing: (String) -> String) -> String {
        guard let formatKey else { return localizing(plainKey) }
        return Self.apply(localizing(formatKey), arguments: arguments)
    }

    static func apply(_ format: String, arguments: [Argument]) -> String {
        let parts = format.components(separatedBy: "%@")
        var result = ""
        for index in parts.indices {
            result += parts[index]
            if index < arguments.count { result += arguments[index].text }
        }
        return result
    }

    static func make(question: ClockQuestion, language: String, instructionKey: String) -> DinoQuestionPrompt {
        let code = language.lowercased().hasPrefix("nl") ? "nl" : "en"
        let unchanged = DinoQuestionPrompt(plainKey: instructionKey, formatKey: nil, arguments: [])
        switch question.kind {
        case .chooseAnalog, .activity:
            return clockChoice(question, language: code, countedKey: "dino.question.chooseClock.format",
                               shortKey: "dino.question.chooseClock.short", plainKey: instructionKey)
        case .spokenTime:
            return clockChoice(question, language: code, countedKey: "dino.question.spokenClock.format",
                               shortKey: "dino.question.spokenTime.format", plainKey: instructionKey)
        case .trueFalse:
            return formatted("dino.question.trueFalse.format",
                             [clock(question.statement ?? question.target, language: code)], plainKey: instructionKey)
        case .advanceAnalog:
            guard question.durationMinutes > 0 else { return unchanged }
            return formatted("dino.question.advanceAnalog.format",
                             [forward(question.durationMinutes, language: code),
                              word(code == "nl" ? "vooruit" : "forward", .forward)],
                             plainKey: instructionKey)
        case .addTime:
            guard let start = question.relatedTimes.first, question.durationMinutes > 0 else { return unchanged }
            return formatted("dino.question.addTime.format",
                             [forward(question.durationMinutes, language: code),
                              word("later", .forward),
                              clock(start, language: code, needsDayPart: true)],
                             plainKey: instructionKey)
        case .subtractTime:
            guard let start = question.relatedTimes.first, question.durationMinutes > 0 else { return unchanged }
            return formatted("dino.question.subtractTime.format",
                             [backward(question.durationMinutes, language: code),
                              word(code == "nl" ? "eerder" : "earlier", .backward),
                              clock(start, language: code, needsDayPart: true)],
                             plainKey: instructionKey)
        case .minutesBetween:
            guard question.relatedTimes.count == 2 else { return unchanged }
            return formatted("dino.question.minutesBetween.format",
                             [clock(question.relatedTimes[0], language: code), clock(question.relatedTimes[1], language: code)],
                             plainKey: instructionKey)
        case .timeSequence:
            guard let latest = question.relatedTimes.last else { return unchanged }
            return formatted("dino.question.timeSequence.format",
                             [clock(latest, language: code)],
                             plainKey: instructionKey)
        case .timeZone:
            guard let journey = question.timeZoneJourney, let reference = question.relatedTimes.first else { return unchanged }
            let origin = journey.origin.name(language: code)
            let destination = journey.destination.name(language: code)
            let minutes = journey.offsetMinutes
            if minutes == 0 {
                return formatted("dino.question.timeZone.same.format",
                                 [clock(reference, language: code, needsDayPart: true), plain(origin), plain(destination)],
                                 plainKey: instructionKey)
            }
            let ahead = minutes > 0
            let shift = ahead ? forward(abs(minutes), language: code) : backward(abs(minutes), language: code)
            let direction = word(code == "nl" ? (ahead ? "vooruit" : "achter") : (ahead ? "ahead" : "behind"),
                                 ahead ? .forward : .backward)
            return formatted(ahead ? "dino.question.timeZone.ahead.format" : "dino.question.timeZone.behind.format", [
                clock(reference, language: code, needsDayPart: true), plain(origin), plain(destination), shift, direction, plain(destination)
            ], plainKey: instructionKey)
        case .flightArrival:
            guard let departure = question.relatedTimes.first, question.durationMinutes > 0 else { return unchanged }
            return formatted("dino.question.flightArrival.format",
                             [clock(departure, language: code, needsDayPart: true)], plainKey: instructionKey)
        case .chooseDigital, .readDigital, .sayTime, .setAnalog, .setDigital, .read24Hour, .dayPart, .match, .sortTimes, .daySchedule:
            // Reading these aloud would say the answer, or would list every choice.
            return unchanged
        }
    }

    private static func clockChoice(_ question: ClockQuestion, language: String, countedKey: String,
                                    shortKey: String, plainKey: String) -> DinoQuestionPrompt {
        let time = clock(question.target, language: language)
        guard let count = countWord(question.options.count, language: language) else {
            return formatted(shortKey, [time], plainKey: plainKey)
        }
        return formatted(countedKey, [plain(count), time], plainKey: plainKey)
    }

    private static func countWord(_ count: Int, language: String) -> String? {
        switch (count, language == "nl") {
        case (2, true): return "twee"
        case (4, true): return "vier"
        case (2, false): return "two"
        case (4, false): return "four"
        default: return nil
        }
    }

    private static func formatted(_ key: String, _ arguments: [Argument], plainKey: String) -> DinoQuestionPrompt {
        DinoQuestionPrompt(plainKey: plainKey, formatKey: key, arguments: arguments)
    }

    private static func plain(_ text: String) -> Argument {
        Argument(text: text, emphasis: .plain)
    }

    private static func word(_ text: String, _ emphasis: Emphasis) -> Argument {
        Argument(text: text, emphasis: emphasis)
    }

    private static func clock(_ time: ClockTime, language: String, needsDayPart: Bool = false) -> Argument {
        // Analog faces, short intervals and the visible sequence do not need a day part.
        // Keep it when the starting time determines an absolute 24-hour answer.
        plain(needsDayPart ? DinoTimeWords.promptTime(time, language: language)
              : DinoTimeWords.time(time, language: language))
    }

    private static func forward(_ minutes: Int, language: String) -> Argument {
        Argument(text: DinoTimeWords.spokenDuration(minutes, language: language), emphasis: .forward)
    }

    private static func backward(_ minutes: Int, language: String) -> Argument {
        Argument(text: DinoTimeWords.spokenDuration(minutes, language: language), emphasis: .backward)
    }
}
