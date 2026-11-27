import Foundation

/// Matching uses language, script and region. Formatting extensions belong to the formatter.
struct DinoLanguageTag {
    let language: String
    let script: String?
    let explicitScript: String?
    let region: String?

    init(_ identifier: String) {
        let identifier = identifier.replacingOccurrences(of: "_", with: "-")
        let components = Locale.Components(identifier: identifier).languageComponents
        let locale = Locale.Language(identifier: identifier)
        language = locale.maximalIdentifier.split(separator: "-").first.map(String.init)?.lowercased() ?? ""
        let resolvedScript = locale.script?.identifier
        // Apple can identify Urdu's Nastaliq form as Aran and other Urdu resources as Arab.
        script = language == "ur" && resolvedScript == "Aran" ? "Arab" : resolvedScript
        explicitScript = components.script?.identifier
        region = components.region?.identifier
    }

    func matchSpecificity(for requested: Self) -> Int? {
        guard !language.isEmpty, language == requested.language, script == requested.script,
              region == nil || region == requested.region else { return nil }
        return (region == nil ? 0 : 2) + (explicitScript == nil ? 0 : 1)
    }
}

/// A shipped game language. Bundle resources, numeric presentation and speech can vary independently.
struct AppLanguage: Identifiable, Hashable, Sendable {
    let code: String
    let displayName: String
    let flag: String?
    let bundleCode: String
    let inheritedBundles: [String]
    let formatLocale: String
    let dateLocale: String
    let voiceLocale: String
    let timeZoneOrigin: String
    let privacyFragment: String
    let spokenTime: SpokenTimeLanguage
    let timeVocabulary: DinoTimeVocabulary
    var localDigitalClock = true
    var regionalTimeZoneCapitals: [DinoCapital] = []
    var regionalTimeZoneMinimum = 60
    var teaches24HourConversion = false
    var interfaceLocale: String? = nil

    var id: String { code }
    var resourceCodes: [String] { [bundleCode] + inheritedBundles + (bundleCode == "en" ? [] : ["en"]) }
    var runsRightToLeft: Bool { Locale.Language(identifier: code).characterDirection == .rightToLeft }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.code == rhs.code }
    func hash(into hasher: inout Hasher) { hasher.combine(code) }

    // Keep the original preference and bundle codes as the generic NL/EN entries.
    static let english = AppLanguage(code: "en", displayName: "English", flag: "🇬🇧", bundleCode: "en",
        inheritedBundles: [], formatLocale: "en", dateLocale: "en-GB", voiceLocale: "en-GB",
        timeZoneOrigin: "london", privacyFragment: "en", spokenTime: .english, timeVocabulary: .english,
        localDigitalClock: false)
    static let dutch = AppLanguage(code: "nl", displayName: "Nederlands", flag: "🇳🇱", bundleCode: "nl",
        inheritedBundles: [], formatLocale: "nl", dateLocale: "nl-NL", voiceLocale: "nl-NL",
        timeZoneOrigin: "amsterdam", privacyFragment: "nl", spokenTime: .dutch, timeVocabulary: .dutch,
        localDigitalClock: false)
    static let german = AppLanguage(code: "de", displayName: "Deutsch", flag: "🇩🇪", bundleCode: "de",
        inheritedBundles: [], formatLocale: "de-DE", dateLocale: "de-DE", voiceLocale: "de-DE",
        timeZoneOrigin: "berlin", privacyFragment: "en", spokenTime: .german, timeVocabulary: .german)
    static let canadianEnglish = AppLanguage(code: "en-CA", displayName: "English (Canada)", flag: "🇨🇦", bundleCode: "en-CA",
        inheritedBundles: [], formatLocale: "en-CA", dateLocale: "en-CA", voiceLocale: "en-CA",
        timeZoneOrigin: "ottawa", privacyFragment: "en", spokenTime: .english, timeVocabulary: .english,
        regionalTimeZoneCapitals: DinoTimeZoneJourney.canadianCapitals)
    static let australianEnglish = AppLanguage(code: "en-AU", displayName: "English (Australia)", flag: "🇦🇺", bundleCode: "en-AU",
        inheritedBundles: [], formatLocale: "en-AU", dateLocale: "en-AU", voiceLocale: "en-AU",
        timeZoneOrigin: "canberra", privacyFragment: "en", spokenTime: .english, timeVocabulary: .english,
        regionalTimeZoneCapitals: DinoTimeZoneJourney.australianCapitals, regionalTimeZoneMinimum: 30,
        teaches24HourConversion: true)
    static let saudiArabic = AppLanguage(code: "ar", displayName: "العربية (السعودية)", flag: "🇸🇦", bundleCode: "ar",
        inheritedBundles: [], formatLocale: "ar-SA", dateLocale: "ar-SA", voiceLocale: "ar-SA",
        timeZoneOrigin: "riyadh", privacyFragment: "en", spokenTime: .arabic, timeVocabulary: .arabic,
        regionalTimeZoneCapitals: DinoTimeZoneJourney.saudiCapitals, regionalTimeZoneMinimum: 30,
        teaches24HourConversion: true, interfaceLocale: "ar-SA")
    static let japanese = AppLanguage(code: "ja", displayName: "日本語", flag: "🇯🇵", bundleCode: "ja",
        inheritedBundles: [], formatLocale: "ja-JP", dateLocale: "ja-JP", voiceLocale: "ja-JP",
        timeZoneOrigin: "tokyo", privacyFragment: "en", spokenTime: .japanese, timeVocabulary: .japanese,
        regionalTimeZoneCapitals: DinoTimeZoneJourney.asiaPacificCapitals)
    static let simplifiedChinese = AppLanguage(code: "zh-Hans", displayName: "简体中文", flag: "🇨🇳", bundleCode: "zh-Hans",
        inheritedBundles: [], formatLocale: "zh-Hans-CN", dateLocale: "zh-Hans-CN", voiceLocale: "zh-CN",
        timeZoneOrigin: "beijing", privacyFragment: "en", spokenTime: .simplifiedChinese, timeVocabulary: .simplifiedChinese,
        regionalTimeZoneCapitals: DinoTimeZoneJourney.asiaPacificCapitals, regionalTimeZoneMinimum: 30)
    static let traditionalChinese = AppLanguage(code: "zh-Hant", displayName: "繁體中文", flag: "🇹🇼", bundleCode: "zh-Hant",
        inheritedBundles: [], formatLocale: "zh-Hant-TW", dateLocale: "zh-Hant-TW", voiceLocale: "zh-TW",
        timeZoneOrigin: "taipei", privacyFragment: "en", spokenTime: .traditionalChinese, timeVocabulary: .traditionalChinese,
        regionalTimeZoneCapitals: DinoTimeZoneJourney.taiwanCapitals, regionalTimeZoneMinimum: 30,
        interfaceLocale: "zh-Hant-TW")
    static let hebrew = AppLanguage(code: "he", displayName: "עברית", flag: "🇮🇱", bundleCode: "he",
        inheritedBundles: [], formatLocale: "he-IL", dateLocale: "he-IL", voiceLocale: "he-IL",
        timeZoneOrigin: "jerusalem", privacyFragment: "en", spokenTime: .hebrew, timeVocabulary: .hebrew,
        regionalTimeZoneCapitals: DinoTimeZoneJourney.hebrewCapitals, regionalTimeZoneMinimum: 30,
        teaches24HourConversion: true, interfaceLocale: "he-IL")
    static let pakistaniUrdu = AppLanguage(code: "ur", displayName: "اردو", flag: "🇵🇰", bundleCode: "ur",
        inheritedBundles: [], formatLocale: "ur-PK", dateLocale: "ur-PK", voiceLocale: "ur-PK",
        timeZoneOrigin: "islamabad", privacyFragment: "en", spokenTime: .urdu, timeVocabulary: .urdu,
        regionalTimeZoneCapitals: DinoTimeZoneJourney.pakistaniCapitals, regionalTimeZoneMinimum: 30,
        interfaceLocale: "ur-PK")
    static let french = AppLanguage(code: "fr", displayName: "Français (France)", flag: "🇫🇷", bundleCode: "fr",
        inheritedBundles: [], formatLocale: "fr-FR", dateLocale: "fr-FR", voiceLocale: "fr-FR",
        timeZoneOrigin: "paris", privacyFragment: "en", spokenTime: .french, timeVocabulary: .french)
    static let canadianFrench = AppLanguage(code: "fr-CA", displayName: "Français (Canada)", flag: "🇨🇦", bundleCode: "fr-CA",
        inheritedBundles: ["fr"], formatLocale: "fr-CA", dateLocale: "fr-CA", voiceLocale: "fr-CA",
        timeZoneOrigin: "ottawa", privacyFragment: "en", spokenTime: .french, timeVocabulary: .french,
        regionalTimeZoneCapitals: DinoTimeZoneJourney.canadianCapitals)
    static let spanish = AppLanguage(code: "es", displayName: "Español (España)", flag: "🇪🇸", bundleCode: "es",
        inheritedBundles: [], formatLocale: "es-ES", dateLocale: "es-ES", voiceLocale: "es-ES",
        timeZoneOrigin: "madrid", privacyFragment: "en", spokenTime: .spanish, timeVocabulary: .spanish)
    static let mexicanSpanish = AppLanguage(code: "es-MX", displayName: "Español (México)", flag: "🇲🇽", bundleCode: "es-MX",
        inheritedBundles: ["es"], formatLocale: "es-MX", dateLocale: "es-MX", voiceLocale: "es-MX",
        timeZoneOrigin: "mexicoCity", privacyFragment: "en", spokenTime: .mexicanSpanish, timeVocabulary: .mexicanSpanish,
        regionalTimeZoneCapitals: DinoTimeZoneJourney.mexicanCities)
    static let europeanPortuguese = AppLanguage(code: "pt-PT", displayName: "Português (Portugal)", flag: "🇵🇹", bundleCode: "pt-PT",
        inheritedBundles: [], formatLocale: "pt-PT", dateLocale: "pt-PT", voiceLocale: "pt-PT",
        timeZoneOrigin: "lisbon", privacyFragment: "en", spokenTime: .europeanPortuguese, timeVocabulary: .europeanPortuguese)
    static let brazilianPortuguese = AppLanguage(code: "pt-BR", displayName: "Português (Brasil)", flag: "🇧🇷", bundleCode: "pt-BR",
        inheritedBundles: ["pt-PT"], formatLocale: "pt-BR", dateLocale: "pt-BR", voiceLocale: "pt-BR",
        timeZoneOrigin: "brasilia", privacyFragment: "en", spokenTime: .brazilianPortuguese, timeVocabulary: .brazilianPortuguese,
        regionalTimeZoneCapitals: DinoTimeZoneJourney.brazilianCities)
    static let all = [dutch, english, german, canadianEnglish, australianEnglish, saudiArabic, japanese,
                      simplifiedChinese, traditionalChinese, hebrew, pakistaniUrdu, french, canadianFrench, spanish,
                      mexicanSpanish, europeanPortuguese, brazilianPortuguese]
    private static let byCode = Dictionary(uniqueKeysWithValues: all.map { ($0.code, $0) })

    static func named(_ identifier: String) -> Self? {
        if let exact = byCode[identifier] { return exact }
        return match(identifier, among: all, code: \.code)
    }

    static func resolved(_ identifier: String) -> Self { named(identifier) ?? .english }

    static func match<T>(_ identifier: String, among choices: [T], code: KeyPath<T, String>) -> T? {
        if let exact = choices.first(where: { $0[keyPath: code].caseInsensitiveCompare(identifier) == .orderedSame }) {
            return exact
        }
        let requested = DinoLanguageTag(identifier)
        return choices.compactMap { choice in
            DinoLanguageTag(choice[keyPath: code]).matchSpecificity(for: requested).map { ($0, choice) }
        }.max { $0.0 < $1.0 }?.1
    }
}
