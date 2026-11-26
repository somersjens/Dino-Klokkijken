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
        let code = languageCode.replacingOccurrences(of: "_", with: "-")
        if let profile = AppLanguage.all.first(where: { $0.code.caseInsensitiveCompare(code) == .orderedSame }) {
            return profile.voiceLocale
        }
        return code.isEmpty ? AppLanguage.english.voiceLocale : code
    }

    static func bestVoice(for languageCode: String, among voices: [DinoSpeechVoice]) -> DinoSpeechVoice? {
        let preferred = preferredLanguageIdentifier(for: languageCode)
        let matching = voices.filter { matchesLanguageAndScript($0.language, preferred) }
        let spoken = matching.filter { !isNovelty($0) }
        let pool = spoken.isEmpty ? matching : spoken
        return pool.max { lhs, rhs in
            let left = rank(lhs, preferred: preferred)
            let right = rank(rhs, preferred: preferred)
            if left != right { return left < right }
            return lhs.identifier > rhs.identifier
        }
    }

    static func matchesLanguageAndScript(_ left: String, _ right: String) -> Bool {
        let first = DinoLanguageTag(left)
        let second = DinoLanguageTag(right)
        return first.language == second.language && first.script == second.script
    }

    private static func normalized(_ language: String) -> String {
        language.replacingOccurrences(of: "_", with: "-").lowercased()
    }

    /// Quality steps are 100 points apart. The region bonus beats one better tier
    /// from another country, and the Siri bonus stays inside a single quality tier.
    private static func rank(_ voice: DinoSpeechVoice, preferred: String) -> Int {
        var score = voice.quality * 100
        let requested = DinoLanguageTag(preferred)
        let available = DinoLanguageTag(voice.language)
        if normalized(voice.language) == normalized(preferred)
            || (requested.region != nil && requested.region == available.region) { score += 250 }
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
/// Only the direction word gets a color; clock times and durations keep the base color.
struct DinoQuestionPrompt: Equatable, Sendable {
    struct Argument: Equatable, Sendable {
        var text: String
        var emphasis: Emphasis
        var localizationKey: String?
    }

    enum Emphasis: Equatable, Sendable {
        case plain, forward, backward
    }

    var plainKey: String
    var formatKey: String?
    var arguments: [Argument]

    enum Segment: Equatable, Sendable {
        case literal(String)
        case argument(Argument)

        var text: String {
            switch self {
            case .literal(let text): return text
            case .argument(let argument): return argument.text
            }
        }
    }

    func spoken(localizing: (String) -> String) -> String {
        segments(localizing: localizing).map(\.text).joined()
    }

    func segments(localizing: (String) -> String) -> [Segment] {
        guard let formatKey else { return [.literal(localizing(plainKey))] }
        let values = arguments.map { argument in
            var value = argument
            if let key = argument.localizationKey {
                let translation = localizing(key)
                if translation != key { value.text = translation }
            }
            return value
        }
        return Self.interpolated(localizing(formatKey), arguments: values) ?? [.literal(localizing(plainKey))]
    }

    /// The same positional placeholders drive visible emphasis, accessibility and speech.
    static func interpolated(_ format: String, arguments: [Argument]) -> [Segment]? {
        let placeholders = formatPattern.matches(in: format, range: NSRange(format.startIndex..., in: format))
        var segments: [Segment] = []
        var cursor = format.startIndex
        var next = 0
        var used = Set<Int>()
        for match in placeholders {
            guard let range = Range(match.range, in: format) else { continue }
            if cursor < range.lowerBound { segments.append(.literal(String(format[cursor..<range.lowerBound]))) }
            cursor = range.upperBound
            if format[range] == "%%" {
                segments.append(.literal("%"))
                continue
            }
            let index: Int
            if let position = Range(match.range(at: 1), in: format) {
                guard let ordinal = Int(format[position]) else { return nil }
                index = ordinal - 1
            } else {
                index = next
                next += 1
            }
            guard arguments.indices.contains(index) else { return nil }
            used.insert(index)
            segments.append(.argument(arguments[index]))
        }
        guard used.count == arguments.count else { return nil }
        if cursor < format.endIndex { segments.append(.literal(String(format[cursor...]))) }
        return segments
    }

    private static let formatPattern = try! NSRegularExpression(pattern: "%(?:([1-9][0-9]*)\\$)?@|%%")

    static func make(question: ClockQuestion, language: String, instructionKey: String) -> DinoQuestionPrompt {
        let code = AppLanguage.resolved(language).code
        let unchanged = DinoQuestionPrompt(plainKey: instructionKey, formatKey: nil, arguments: [])
        switch question.kind {
        case .chooseAnalog, .activity:
            return formatted("dino.question.chooseClock.short", [clock(question.target, language: code)],
                             plainKey: instructionKey)
        case .spokenTime:
            return formatted("dino.question.spokenTime.format", [clock(question.target, language: code)],
                             plainKey: instructionKey)
        case .trueFalse:
            return formatted("dino.question.trueFalse.format",
                             [clock(question.statement ?? question.target, language: code)], plainKey: instructionKey)
        case .advanceAnalog:
            guard question.durationMinutes > 0 else { return unchanged }
            return formatted("dino.question.advanceAnalog.format",
                             [duration(question.durationMinutes, language: code),
                              word("forward", key: "dino.question.direction.forward", .forward)],
                             plainKey: instructionKey)
        case .addTime:
            guard let start = question.relatedTimes.first, question.durationMinutes > 0 else { return unchanged }
            return formatted("dino.question.addTime.format",
                             [clock(start, language: code, digital: true),
                              word("later", key: "dino.question.direction.later", .forward),
                              duration(question.durationMinutes, language: code)],
                             plainKey: instructionKey)
        case .subtractTime:
            guard let start = question.relatedTimes.first, question.durationMinutes > 0 else { return unchanged }
            return formatted("dino.question.subtractTime.format",
                             [clock(start, language: code, digital: true),
                              duration(question.durationMinutes, language: code),
                              word("ago", key: "dino.question.direction.ago", .backward)],
                             plainKey: instructionKey)
        case .minutesBetween:
            guard question.relatedTimes.count == 2 else { return unchanged }
            return formatted("dino.question.minutesBetween.format",
                             [clock(question.relatedTimes[0], language: code, digital: true), clock(question.relatedTimes[1], language: code, digital: true)],
                             plainKey: instructionKey)
        case .timeSequence:
            guard let latest = question.relatedTimes.last else { return unchanged }
            return formatted("dino.question.timeSequence.format",
                             [clock(latest, language: code, digital: true)],
                             plainKey: instructionKey)
        case .timeZone:
            guard let journey = question.timeZoneJourney, let reference = question.relatedTimes.first else { return unchanged }
            let origin = city(journey.origin, language: code)
            let destination = city(journey.destination, language: code)
            let minutes = journey.offsetMinutes
            if minutes == 0 {
                return formatted("dino.question.timeZone.same.format",
                                 [clock(reference, language: code, digital: true), origin, destination],
                                 plainKey: instructionKey)
            }
            let ahead = minutes > 0
            let shift = duration(abs(minutes), language: code)
            let direction = word(ahead ? "ahead" : "behind",
                                 key: ahead ? "dino.question.direction.ahead" : "dino.question.direction.behind",
                                 ahead ? .forward : .backward)
            return formatted(ahead ? "dino.question.timeZone.ahead.format" : "dino.question.timeZone.behind.format", [
                clock(reference, language: code, digital: true), origin, destination, shift, direction
            ], plainKey: instructionKey)
        case .flightArrival:
            guard let departure = question.relatedTimes.first, question.durationMinutes > 0 else { return unchanged }
            return formatted("dino.question.flightArrival.format",
                             [clock(departure, language: code, digital: true)], plainKey: instructionKey)
        case .sayTime:
            let lesson = SpokenTimeCatalog.language(code: code)
            guard let key = lesson.instructionKey(lesson.rule(question.target.minute)) else { return unchanged }
            return DinoQuestionPrompt(plainKey: key, formatKey: nil, arguments: [])
        case .chooseDigital, .readDigital, .setAnalog, .setDigital, .read24Hour, .dayPart, .match, .sortTimes, .daySchedule:
            // Reading these aloud would say the answer, or would list every choice.
            return unchanged
        }
    }

    private static func formatted(_ key: String, _ arguments: [Argument], plainKey: String) -> DinoQuestionPrompt {
        DinoQuestionPrompt(plainKey: plainKey, formatKey: key, arguments: arguments)
    }

    private static func plain(_ text: String) -> Argument {
        Argument(text: text, emphasis: .plain)
    }

    private static func word(_ text: String, key: String, _ emphasis: Emphasis) -> Argument {
        Argument(text: text, emphasis: emphasis, localizationKey: key)
    }

    private static func city(_ capital: DinoCapital, language: String) -> Argument {
        Argument(text: capital.name(language: language), emphasis: .plain, localizationKey: capital.nameKey)
    }

    private static func clock(_ time: ClockTime, language: String, digital: Bool = false) -> Argument {
        // Analog faces have no day part. Arithmetic, journeys and sequences show
        // their reference digitally, including AM/PM or 24-hour context.
        let includesDayPart = AppLanguage.resolved(language).timeVocabulary.digitalQuestionsIncludeDayPart
        return plain(digital ? DinoTimeWords.digitalTimeInWords(time, language: language, dayPart: includesDayPart)
                             : DinoTimeWords.time(time, language: language))
    }

    private static func duration(_ minutes: Int, language: String) -> Argument {
        plain(DinoTimeWords.spokenDuration(minutes, language: language))
    }
}
