import SwiftUI
import Combine
import ObjectiveC
import UIKit

struct AppLanguage: Identifiable, Hashable, Sendable {
    let code: String
    let flag: String
    var id: String { code }
    var layoutDirection: LayoutDirection { .leftToRight }
    var displayName: String { code == "nl" ? "Nederlands" : "English" }
    static let english = AppLanguage(code: "en", flag: "🇬🇧")
    static let dutch = AppLanguage(code: "nl", flag: "🇳🇱")
    static let all = [dutch, english]
    static func named(_ code: String) -> AppLanguage? {
        let base = code.lowercased().replacingOccurrences(of: "_", with: "-").split(separator: "-").first
        return all.first { $0.code == base.map(String.init) }
    }
}

/// Retains the existing saved preference and live bundle redirection.
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    private static let overrideKey = "settings.languageOverride"
    private let defaults: UserDefaults
    private var systemLanguageUpdates: AnyCancellable?
    @Published var override: AppLanguage? {
        didSet {
            if let override { defaults.set(override.code, forKey: Self.overrideKey) }
            else { defaults.removeObject(forKey: Self.overrideKey) }
            apply()
        }
    }
    private(set) var bundle: Bundle = .main
    static let englishBundle = lprojBundle(for: "en")

    private init() {
#if DEBUG
        if let suite = ProcessInfo.processInfo.environment["DINO_TEST_SUITE"], let isolated = UserDefaults(suiteName: suite) {
            defaults = isolated
        } else { defaults = .standard }
#else
        defaults = .standard
#endif
        if let saved = defaults.string(forKey: Self.overrideKey) {
            override = AppLanguage.named(saved)
            if let override {
                if saved != override.code { defaults.set(override.code, forKey: Self.overrideKey) }
            } else {
                defaults.removeObject(forKey: Self.overrideKey)
            }
        }
        apply()
        systemLanguageUpdates = NotificationCenter.default.publisher(for: NSLocale.currentLocaleDidChangeNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, self.override == nil else { return }
                self.objectWillChange.send()
                self.apply()
            }
    }
    var effective: AppLanguage {
        override ?? Locale.preferredLanguages.compactMap(AppLanguage.named).first ?? .english
    }
    var locale: Locale { Locale(identifier: effective.code) }
    static func lprojBundle(for code: String) -> Bundle? {
        Bundle.main.path(forResource: code, ofType: "lproj").flatMap(Bundle.init(path:))
    }
    private func apply() {
        bundle = Self.lprojBundle(for: effective.code) ?? Self.englishBundle ?? .main
        Bundle.setLanguage(effective.code)
    }
    func select(_ language: AppLanguage) {
        withAnimation(.easeInOut(duration: 0.2)) { override = language }
    }
    func resetPreference() {
        override = nil
        defaults.synchronize()
    }
}

func L(_ key: String.LocalizationValue) -> String {
    let language = LanguageManager.shared
    return String(localized: key, bundle: language.bundle, locale: language.locale)
}
func L(key: String) -> String {
    let result = LanguageManager.shared.bundle.localizedString(forKey: key, value: key, table: nil)
    return result == key
        ? LanguageManager.englishBundle?.localizedString(forKey: key, value: key, table: nil) ?? key
        : result
}

private var languageBundleKey: UInt8 = 0
private final class LanguageBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let chosen = objc_getAssociatedObject(self, &languageBundleKey) as? Bundle {
            return chosen.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}
extension Bundle {
    private static let installLanguageBundle: Void = { object_setClass(Bundle.main, LanguageBundle.self) }()
    static func setLanguage(_ code: String) {
        _ = installLanguageBundle
        objc_setAssociatedObject(Bundle.main, &languageBundleKey,
                                 LanguageManager.lprojBundle(for: code), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

private struct GameEnvironment: ViewModifier {
    @ObservedObject private var language = LanguageManager.shared
    func body(content: Content) -> some View {
        content.environment(\.locale, language.locale).environment(\.layoutDirection, .leftToRight)
            .lightPalette()
    }
}
extension View {
    func gameEnvironment() -> some View { modifier(GameEnvironment()) }

    /// Sheets and covers do not inherit the window palette, so each presentation sets it again.
    func lightPalette() -> some View {
        preferredColorScheme(.light).toolbarColorScheme(.light, for: .navigationBar)
    }
}

/// A compact language sheet; selecting a language saves it and dismisses the sheet.
struct LanguagePicker: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ObservedObject private var language = LanguageManager.shared
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geometry in
            let spacious = geometry.size.width >= 500 && verticalSizeClass != .compact
            ScrollView {
                VStack(spacing: spacious ? 24 : 20) {
                    Text("dino.language")
                        .font(.system(size: spacious ? 34 : 28, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("language.title")
                    VStack(spacing: 0) {
                        ForEach(Array(AppLanguage.all.enumerated()), id: \.element.id) { index, option in
                            if index > 0 {
                                Rectangle().fill(DinoStyle.ink.opacity(highContrast ? 0.5 : 0.08))
                                    .frame(height: 1).padding(.horizontal, 16).accessibilityHidden(true)
                            }
                            let selected = option == language.effective
                            Button {
                                language.select(option)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Text(verbatim: option.flag).font(.system(size: spacious ? 34 : 28))
                                    Text(verbatim: option.displayName)
                                        .font(.system(size: spacious ? 22 : 17, weight: .bold, design: .rounded))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: spacious ? 26 : 22, weight: .semibold))
                                        .foregroundStyle(selected ? DinoStyle.deepGreen : DinoStyle.muted)
                                }.padding(.horizontal, 16).frame(minHeight: spacious ? 76 : 60).contentShape(Rectangle())
                            }.buttonStyle(DinoPlainButtonStyle())
                                .accessibilityAddTraits(selected ? .isSelected : [])
                                .accessibilityIdentifier("language.option." + option.code)
                        }
                    }.background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 22))
                }
                .padding(.horizontal, spacious ? 28 : 20)
                .padding(.top, 28)
                .padding(.bottom, 24)
                .frame(maxWidth: 560).frame(maxWidth: .infinity)
            }.bouncesOnlyWhenNeeded()
                .accessibilityIdentifier("language.picker")
        }.foregroundStyle(DinoStyle.ink)
            .background(JungleBackground(quiet: true))
            .lightPalette()
            .presentationDetents([.height(320), .large])
            .presentationDragIndicator(.visible)
    }

    @ViewBuilder func languagePresentation() -> some View {
        if #available(iOS 18, *) {
            presentationSizing(LanguagePresentationSizing())
        } else {
            self
        }
    }
}

@available(iOS 18, *)
private struct LanguagePresentationSizing: PresentationSizing {
    func proposedSize(for root: PresentationSizingRoot, context: PresentationSizingContext) -> ProposedViewSize {
        let page = PagePresentationSizing.page.proposedSize(for: root, context: context)
        return ProposedViewSize(width: min(page.width ?? 560, 560), height: min(page.height ?? 320, 320))
    }
}
