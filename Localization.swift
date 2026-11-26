import SwiftUI
import Combine
import ObjectiveC
import UIKit

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
    var locale: Locale {
        let profile = effective
        return Locale(identifier: profile.interfaceLocale ?? profile.code)
    }
    var layoutDirection: LayoutDirection {
#if DEBUG
        if UserDefaults.standard.bool(forKey: "NSForceRightToLeftWritingDirection")
            || UserDefaults.standard.bool(forKey: "AppleTextDirection") { return .rightToLeft }
#endif
        return effective.runsRightToLeft ? .rightToLeft : .leftToRight
    }

    private static let resourceBundles: [String: Bundle] = {
        let codes = Set(AppLanguage.all.flatMap(\.resourceCodes))
        return Dictionary(uniqueKeysWithValues: codes.compactMap { code in
            guard let url = Bundle.main.url(forResource: code, withExtension: "lproj"),
                  let bundle = Bundle(url: url) else { return nil }
            return (code, bundle)
        })
    }()

    private func apply() {
        let bundles = effective.resourceCodes.compactMap { Self.resourceBundles[$0] }
        Bundle.setGameResources(bundles)
    }
    func select(_ language: AppLanguage) {
        withAnimation(.easeInOut(duration: 0.2)) { override = language }
    }
    func resetPreference() {
        override = nil
        defaults.synchronize()
    }
}

func L(_ key: String) -> String { L(key: key) }
func L(key: String) -> String {
    _ = LanguageManager.shared
    return Bundle.main.localizedString(forKey: key, value: key, table: nil)
}

private var languageBundleKey: UInt8 = 0
private final class LanguageBundle: Bundle, @unchecked Sendable {
    private static let missing = "\u{F8FF}DinoMissingLocalization\u{F8FF}"

    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if tableName != "InfoPlist",
           let bundles = objc_getAssociatedObject(self, &languageBundleKey) as? [Bundle] {
            for bundle in bundles {
                let translation = bundle.localizedString(forKey: key, value: Self.missing, table: tableName)
                if !translation.contains(Self.missing) { return translation }
            }
            return value.flatMap { $0.isEmpty ? nil : $0 } ?? key
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}
extension Bundle {
    private static let installLanguageBundle: Void = { object_setClass(Bundle.main, LanguageBundle.self) }()
    static func setGameResources(_ bundles: [Bundle]) {
        _ = installLanguageBundle
        objc_setAssociatedObject(Bundle.main, &languageBundleKey,
                                 bundles.isEmpty ? nil : bundles, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

private struct GameEnvironment: ViewModifier {
    @ObservedObject private var language = LanguageManager.shared
    func body(content: Content) -> some View {
        content.environment(\.locale, language.locale).environment(\.layoutDirection, language.layoutDirection)
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

    @State private var query = ""
    private var showsSearch: Bool { AppLanguage.all.count > 12 }
    private var options: [AppLanguage] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return AppLanguage.all }
        return AppLanguage.all.filter {
            $0.displayName.localizedStandardContains(term)
                || $0.code.localizedStandardContains(term)
                || (language.locale.localizedString(forIdentifier: $0.code)?.localizedStandardContains(term) ?? false)
        }
    }

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
                    if showsSearch {
                        TextField("dino.language.search", text: $query)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("language.search")
                    }
                    LazyVStack(spacing: 0) {
                        row(title: Text("dino.language.system"), flag: nil, selected: language.override == nil,
                            identifier: "language.system", spacious: spacious, action: language.resetPreference)
                        ForEach(options) { option in
                            divider
                            row(title: Text(verbatim: option.displayName), flag: option.flag,
                                selected: option == language.override, identifier: "language.option." + option.code,
                                spacious: spacious) { language.select(option) }
                        }
                    }.background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 22))
                }
                .padding(.horizontal, spacious ? 28 : 16)
                .padding(.top, 28)
                .padding(.bottom, 24)
                .frame(maxWidth: 560).frame(maxWidth: .infinity)
            }.bouncesOnlyWhenNeeded()
                .accessibilityIdentifier("language.picker")
        }.foregroundStyle(DinoStyle.ink)
            .background(JungleBackground(quiet: true))
            .gameEnvironment()
            .presentationDetents(showsSearch ? [.large] : [.height(390), .large])
            .presentationDragIndicator(.visible)
    }

    private var divider: some View {
        Rectangle().fill(DinoStyle.ink.opacity(highContrast ? 0.5 : 0.08))
            .frame(height: 1).padding(.horizontal, 16).accessibilityHidden(true)
    }

    private func row(title: Text, flag: String?, selected: Bool,
                     identifier: String, spacious: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Group {
                    if let flag { Text(verbatim: flag) }
                    else { Image(systemName: "globe") }
                }
                .font(.system(size: spacious ? 34 : 28))
                .accessibilityHidden(true)
                title.font(.system(size: spacious ? 22 : 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: spacious ? 26 : 22, weight: .semibold))
                    .foregroundStyle(selected ? DinoStyle.deepGreen : DinoStyle.muted)
                    .accessibilityHidden(true)
            }.padding(.horizontal, 16).frame(minHeight: spacious ? 76 : 60).contentShape(Rectangle())
        }.buttonStyle(DinoPlainButtonStyle())
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityIdentifier(identifier)
    }

    @ViewBuilder func languagePresentation() -> some View {
        if #available(iOS 18, *), !showsSearch {
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
        return ProposedViewSize(width: min(page.width ?? 560, 560), height: min(page.height ?? 390, 390))
    }
}
