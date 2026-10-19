import SwiftUI
#if DEBUG
import Darwin
#endif

/// One settings list: Game Center, language, preferences and a guarded reset.
struct DinoSettingsView: View {
    @ObservedObject private var language = LanguageManager.shared
    @EnvironmentObject private var player: DinoPlayer
    @EnvironmentObject private var settings: DinoSettings
    @EnvironmentObject private var cloudSync: DinoCloudSync
    @EnvironmentObject private var friends: FriendsManager
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false
    @State private var showsPrivacy = false
    @State private var showsGameCenter = false
    @State private var showsLanguages = false
    @State private var challenge = ResetChallenge.make()
    @State private var resetAnswer = ""
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let spacious = geometry.size.width >= 650
                ZStack {
                    VStack(spacing: 0) {
                        Text("dino.settings")
                            .font(.system(size: spacious ? 34 : 28, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity).padding(.top, 28).padding(.bottom, 18)
                            .accessibilityIdentifier("settings.title")
                        ScrollView {
                            menu.padding(.horizontal, spacious ? 24 : 16).padding(.bottom, 20)
                                .frame(maxWidth: 760).frame(maxWidth: .infinity)
                        }.accessibilityIdentifier("settings.options")
                        Button("dino.done") { dismiss() }
                            .buttonStyle(DinoButtonStyle()).accessibilityIdentifier("settings.done")
                            .padding(.horizontal, spacious ? 24 : 20).padding(.top, 12).padding(.bottom, 18)
                            .frame(maxWidth: 760).frame(maxWidth: .infinity)
                            .background(DinoStyle.paper.opacity(0.97))
                    }
                    if confirmReset {
                        Color.black.opacity(0.28).ignoresSafeArea()
                        ScrollView {
                            resetCard(compact: geometry.size.height < 700)
                                .padding(16)
                        }.bouncesOnlyWhenNeeded()
                            .centersShortContent()
                            .frame(maxWidth: 460)
                    }
                }.background(JungleBackground(quiet: true))
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showsPrivacy) { DinoSocialPrivacyView() }
            .sheet(isPresented: $showsGameCenter) { DinoFriendsView().gameEnvironment() }
            .sheet(isPresented: $showsLanguages) { LanguagePicker() }
        }.foregroundStyle(DinoStyle.ink)
            .onValueChange(of: confirmReset) { shown in
                if shown {
                    challenge = ResetChallenge.make()
                    resetAnswer = ""
                }
            }
    }

    private var menu: some View {
        VStack(spacing: 0) {
            navigationRow(title: "dino.settings.gameCenter", symbol: "person.crop.circle.fill",
                          identifier: "settings.gameCenter") {
                showsGameCenter = true
            } detail: {
                if let name = friends.playerDisplayName {
                    Text(verbatim: name).font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                        .accessibilityIdentifier("settings.gameCenterName")
                } else {
                    Text("dino.settings.gameCenter.noAccount")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                        .accessibilityIdentifier("settings.gameCenterSignedOut")
                }
            }
            rowDivider
            navigationRow(title: "dino.language", symbol: "globe", identifier: "settings.language") {
                showsLanguages = true
            } detail: {
                Text(verbatim: language.effective.flag + "  " + language.effective.displayName)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
            }
            rowDivider
            preference("dino.settings.soundEffects", symbol: "speaker.wave.2.fill",
                       value: $settings.soundEffectsEnabled, identifier: "settings.soundEffects")
            rowDivider
            preference("dino.settings.haptics", symbol: "iphone.radiowaves.left.and.right",
                       value: $settings.hapticsEnabled, identifier: "settings.haptics")
            rowDivider
            preference("dino.settings.highContrast", symbol: "circle.lefthalf.filled",
                       value: $settings.highContrastEnabled, identifier: "settings.highContrast")
            rowDivider
            VStack(alignment: .leading, spacing: 0) {
                preference("dino.settings.icloudSync", symbol: "icloud.fill",
                           value: $settings.icloudSyncEnabled, identifier: "settings.icloudSync")
                Text(LocalizedStringKey(cloudSync.status.messageKey))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                    .padding(.horizontal, 16).padding(.bottom, 12)
                    .accessibilityIdentifier("settings.icloudStatus")
            }
            rowDivider
            navigationRow(title: "dino.friends.privacy", symbol: "hand.raised.fill",
                          identifier: "settings.privacy") { showsPrivacy = true }
            rowDivider
            Button { confirmReset = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise").frame(width: 26)
                    Text("dino.resetProgress")
                    Spacer(minLength: 4)
                }.font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(DinoStyle.warning)
                    .padding(.horizontal, 16).frame(minHeight: 60)
                    .contentShape(Rectangle())
            }.buttonStyle(.plain).accessibilityIdentifier("settings.reset")
        }
        .background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 22))
        .padding(12)
        .background(.white.opacity(highContrast ? 1 : 0.8), in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(highContrast ? DinoStyle.ink : .white,
                                                           lineWidth: highContrast ? 2 : 1.5))
    }

    private var rowDivider: some View {
        Rectangle().fill(DinoStyle.ink.opacity(highContrast ? 0.5 : 0.08))
            .frame(height: 1).padding(.horizontal, 16).accessibilityHidden(true)
    }

    private var solvedReset: Bool {
        Int(resetAnswer.filter(\.isNumber)) == challenge.answer
    }

    private func resetCard(compact: Bool) -> some View {
        VStack(spacing: compact ? 12 : 16) {
            DinoCharacter(size: compact ? 84 : 108)
            Text("dino.resetTitle").font(.system(size: compact ? 24 : 28, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
            Text("dino.resetMessage").font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                .multilineTextAlignment(.center)
            Text("dino.settings.icloudResetMessage").font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                .multilineTextAlignment(.center)
            Text("dino.resetChallenge").font(.system(size: 15, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            Text(verbatim: challenge.prompt)
                .font(.system(size: compact ? 26 : 32, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityIdentifier("settings.reset.equation")
                .accessibilityValue(challenge.token)
            TextField("dino.resetAnswer", text: $resetAnswer)
                .keyboardType(.numberPad)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.vertical, 12)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(DinoStyle.ink.opacity(highContrast ? 1 : 0.15),
                                                                   lineWidth: highContrast ? 2 : 1.5))
                .accessibilityIdentifier("settings.reset.answer")
            Button(action: resetApp) {
                Label("dino.resetProgress", systemImage: "arrow.counterclockwise")
            }.buttonStyle(DinoButtonStyle(color: Color(dinoHex: 0xC74343), compact: true))
                .disabled(!solvedReset)
                .accessibilityIdentifier("settings.reset.confirm")
            Button("dino.cancel") { confirmReset = false }
                .buttonStyle(DinoSecondaryButtonStyle())
                .accessibilityIdentifier("settings.reset.cancel")
        }.padding(4).dinoCard()
    }

    private func resetApp() {
        guard solvedReset else { return }
        let date = Date()
        friends.disable()
        cloudSync.removeAllData(at: date)
        player.resetAllData(at: date)
        settings.resetPreferences()
        language.resetPreference()
        dismiss()
#if DEBUG
        // The development build closes after the reset has been flushed, allowing
        // a genuine cold-launch onboarding test. Release resets the root in place.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            Darwin.exit(EXIT_SUCCESS)
        }
#endif
    }

    private func preference(_ key: LocalizedStringKey, symbol: String, value: Binding<Bool>, identifier: String) -> some View {
        Toggle(isOn: value) {
            Label(key, systemImage: symbol).font(.system(size: 17, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
        }.toggleStyle(SettingsToggleStyle()).padding(.horizontal, 16).padding(.vertical, 10).frame(minHeight: 60)
            .accessibilityIdentifier(identifier)
    }

    private func navigationRow(title: LocalizedStringKey, symbol: String, identifier: String,
                               action: @escaping () -> Void) -> some View {
        navigationRow(title: title, symbol: symbol, identifier: identifier, action: action) { EmptyView() }
    }

    private func navigationRow<Detail: View>(title: LocalizedStringKey, symbol: String, identifier: String,
                                             action: @escaping () -> Void,
                                             @ViewBuilder detail: () -> Detail) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    detail()
                }.frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold))
                    .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
            }.font(.system(size: 17, weight: .semibold, design: .rounded))
                .padding(.horizontal, 16).frame(minHeight: 60)
                .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityIdentifier(identifier)
    }
}

/// A product large enough that confirming a reset takes a calculator.
private struct ResetChallenge {
    let left: Int
    let right: Int
    let extra: Int
    var answer: Int { left * right + extra }
    var prompt: String { "\(left) × \(right) + \(extra)" }
    var token: String { "\(left)x\(right)+\(extra)" }

    static func make() -> ResetChallenge {
        ResetChallenge(left: awkward(237...986), right: awkward(128...874), extra: awkward(2408...9876))
    }

    private static func awkward(_ range: ClosedRange<Int>) -> Int {
        var value = Int.random(in: range)
        while value % 10 == 0 || value % 25 == 0 { value = Int.random(in: range) }
        return value
    }
}

/// The label fills the row and has its own action, including its empty space.
private struct SettingsToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            Button { configuration.isOn.toggle() } label: {
                configuration.label.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }.buttonStyle(.plain)
            Toggle(isOn: configuration.$isOn) { EmptyView() }
                .labelsHidden().toggleStyle(.switch).tint(DinoStyle.deepGreen)
        }
    }
}
