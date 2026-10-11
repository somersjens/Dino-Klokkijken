import Foundation

/// Own names are device-only. Social names are supplied and moderated by Apple.
/// This bounded, extensible filter is defense in depth, not worldwide moderation.
enum DinoNameValidator {
    enum Failure: Error { case length, characters, mixedScripts, inappropriate }
    static let fallback = "Dino"
    static let safeNames = ["Dino", "Rex", "Luna", "Nova", "Timo"]
    // Exact normalized words avoid substring false positives (e.g. Scunthorpe).
    // Add reviewed localized terms here; never silently claim complete coverage.
    static let blockedWords: Set<String> = [
        "fuck", "fucker", "shit", "bitch", "cunt", "nigger", "nigga", "porn", "sex", "nazi", "hitler",
        "klootzak", "kut", "hoer", "neuken", "tering", "lul", "merde", "putain", "salope", "pute",
        "scheisse", "arschloch", "hurensohn", "mierda", "puta", "cabron", "pendejo", "cazzo", "stronzo",
        "сука", "блядь", "хуй", "пизда", "操", "傻逼", "씨발", "개새끼", "كس", "قحبة", "चूत", "भोसड़ी"
    ]
    private static let normalizedBlockedWords = Set(blockedWords.map(canonical))
    private static let collapsedBlockedWords = Set(normalizedBlockedWords.map(collapse))
    static func validated(_ input: String) -> Result<String, Failure> {
        guard input.utf8.count <= 1024 else { return .failure(.characters) }
        let name = input.precomposedStringWithCanonicalMapping.trimmingCharacters(in: .whitespacesAndNewlines)
        let cjk = matches("^[\\p{Han}\\p{Hiragana}\\p{Katakana}\\p{Hangul}]+$", name)
        guard (cjk ? 1 : 3)...20 ~= name.count else { return .failure(.length) }
        let scalars = Array(name.unicodeScalars)
        let viramas: Set<UInt32> = [0x094D, 0x09CD, 0x0A4D, 0x0ACD, 0x0B4D, 0x0BCD, 0x0C4D, 0x0CCD, 0x0D4D]
        for (i, scalar) in scalars.enumerated() {
            switch scalar.properties.generalCategory {
            case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .otherLetter:
                // Compatibility/decorative alphabets have a different NFKC form.
                guard String(scalar).precomposedStringWithCompatibilityMapping == String(scalar) else { return .failure(.characters) }
            case .nonspacingMark, .spacingMark:
                guard i > 0, scalar.value != 0xFE0F, scalar.value != 0xFE0E,
                      !(0xE0100...0xE01EF).contains(scalar.value),
                      CharacterSet.letters.contains(scalars[i - 1]) || [.nonspacingMark, .spacingMark].contains(scalars[i - 1].properties.generalCategory) else { return .failure(.characters) }
            case .decimalNumber:
                guard (48...57).contains(scalar.value) else { return .failure(.characters) }
            case .spaceSeparator:
                guard scalar.value == 32 else { return .failure(.characters) }
            case .dashPunctuation, .otherPunctuation, .initialPunctuation, .finalPunctuation:
                guard [0x2D, 0x27, 0x2019].contains(scalar.value) else { return .failure(.characters) }
            case .format:
                // Indic virama joiners and Arabic-script word-internal ZWNJ.
                let indic = i > 0 && viramas.contains(scalars[i - 1].value)
                let arabic = scalar.value == 0x200C && i > 0 && i + 1 < scalars.count &&
                    matches("\\p{Arabic}", String(scalars[i - 1])) && matches("\\p{Arabic}", String(scalars[i + 1])) &&
                    CharacterSet.letters.contains(scalars[i - 1])
                guard [0x200C, 0x200D].contains(scalar.value), i > 0, i + 1 < scalars.count,
                      indic || arabic, CharacterSet.letters.contains(scalars[i + 1]) else { return .failure(.characters) }
            default: return .failure(.characters)
            }
        }
        guard name.unicodeScalars.contains(where: CharacterSet.letters.contains) else { return .failure(.characters) }
        let spoofableScripts = ["Latin", "Cyrillic", "Greek"].filter { matches("\\p{\($0)}", name) }
        guard spoofableScripts.count <= 1 else { return .failure(.mixedScripts) }
        let folded = canonical(name)
        let words = name.split(whereSeparator: { $0 == " " || $0 == "-" || $0 == "'" || $0 == "’" }).map { canonical(String($0)) }
        guard !normalizedBlockedWords.contains(folded), !words.contains(where: normalizedBlockedWords.contains),
              !collapsedBlockedWords.contains(collapse(folded)) else { return .failure(.inappropriate) }
        return .success(name)
    }
    private static func matches(_ pattern: String, _ text: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }
    private static func canonical(_ text: String) -> String {
        let replacements: [Character: Character] = ["0":"o", "1":"i", "3":"e", "4":"a", "5":"s", "7":"t", "ı":"i", "ƒ":"f"]
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        return folded.filter { $0.isLetter || $0.isNumber }.map { String(replacements[$0] ?? $0) }.joined()
    }
    private static func collapse(_ text: String) -> String { text.reduce(into: "") { if $0.last != $1 { $0.append($1) } } }
}
