import SwiftUI
#if DEBUG
import Darwin
#endif

/// Scrollable player preferences, clock customization and progress reset.
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
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let spacious = geometry.size.width >= 650
                VStack(spacing: 0) {
                    Text("dino.settings")
                        .font(.system(size: spacious ? 34 : 28, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity).padding(.top, 28).padding(.bottom, 18)
                        .accessibilityIdentifier("settings.title")
                    ScrollView {
                        VStack(spacing: spacious ? 20 : 16) {
                            section("dino.language", symbol: "globe") {
                                LanguagePicker()
                                NavigationLink {
                                    MyClocksView().environmentObject(player)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "clock.fill").frame(width: 26)
                                        Text("dino.myClocks")
                                        Spacer(minLength: 4)
                                        Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold))
                                    }.font(.system(size: 17, weight: .bold, design: .rounded))
                                        .padding(16).frame(minHeight: 56)
                                        .background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 18))
                                }.buttonStyle(.plain).accessibilityIdentifier("settings.clocks")
                            }
                            section("dino.settings.play", symbol: "slider.horizontal.3") {
                                VStack(spacing: 0) {
                                    preference("dino.settings.soundEffects", symbol: "speaker.wave.2.fill",
                                               value: $settings.soundEffectsEnabled, identifier: "settings.soundEffects")
                                    rowDivider
                                    preference("dino.settings.haptics", symbol: "iphone.radiowaves.left.and.right",
                                               value: $settings.hapticsEnabled, identifier: "settings.haptics")
                                    rowDivider
                                    preference("dino.settings.highContrast", symbol: "circle.lefthalf.filled",
                                               value: $settings.highContrastEnabled, identifier: "settings.highContrast")
                                }.background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 18))
                            }
                            section("dino.settings.icloudSync", symbol: "icloud.fill") {
                                VStack(alignment: .leading, spacing: 0) {
                                    preference("dino.settings.icloudSync", symbol: "icloud.fill",
                                               value: $settings.icloudSyncEnabled, identifier: "settings.icloudSync")
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("dino.settings.icloudDescription").font(.system(size: 15, design: .rounded))
                                        Text(LocalizedStringKey(cloudSync.status.messageKey))
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                                            .accessibilityIdentifier("settings.icloudStatus")
                                    }.padding(.horizontal, 16).padding(.bottom, 16)
                                }.background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 18))
                            }
                            section("dino.settings.gameCenter", symbol: "person.crop.circle.fill") {
                                VStack(alignment: .leading, spacing: 10) {
                                    if let name = friends.playerDisplayName {
                                        Text(verbatim: name).font(.system(size: 20, weight: .bold, design: .rounded))
                                            .textSelection(.enabled).accessibilityIdentifier("settings.gameCenterName")
                                        Text("dino.settings.gameCenter.nameSource").font(.system(size: 14, design: .rounded))
                                            .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                                    } else {
                                        Text("dino.settings.gameCenter.noAccount").font(.system(size: 15, design: .rounded))
                                            .accessibilityIdentifier("settings.gameCenterSignedOut")
                                    }
                                    Button("dino.settings.gameCenter.open") { showsGameCenter = true }
                                        .buttonStyle(DinoSecondaryButtonStyle()).accessibilityIdentifier("settings.gameCenter")
                                }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                                    .background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 18))
                            }
                            VStack(spacing: 8) {
                                Button { showsPrivacy = true } label: {
                                    Label("dino.friends.privacy", systemImage: "hand.raised.fill")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .frame(maxWidth: .infinity, minHeight: 48)
                                }.buttonStyle(.plain).accessibilityIdentifier("settings.privacy")
                                Button { confirmReset = true } label: {
                                    Label("dino.resetProgress", systemImage: "arrow.counterclockwise")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(DinoStyle.warning).frame(maxWidth: .infinity, minHeight: 48)
                                }.buttonStyle(.plain).accessibilityIdentifier("settings.reset")
                            }.padding(8).background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 24))
                        }.padding(.horizontal, spacious ? 24 : 16).padding(.bottom, 20)
                            .frame(maxWidth: 760).frame(maxWidth: .infinity)
                    }.accessibilityIdentifier("settings.options")
                    Button("dino.done") { dismiss() }
                        .buttonStyle(DinoButtonStyle()).accessibilityIdentifier("settings.done")
                        .padding(.horizontal, spacious ? 24 : 20).padding(.top, 12).padding(.bottom, 18)
                        .frame(maxWidth: 760).frame(maxWidth: .infinity)
                        .background(DinoStyle.paper.opacity(0.97))
                }.background(JungleBackground(quiet: true))
            }
            .toolbar(.hidden, for: .navigationBar)
            .confirmationDialog("dino.resetTitle", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("dino.resetProgress", role: .destructive, action: resetApp)
                    .accessibilityIdentifier("settings.reset.confirm")
                Button("dino.cancel", role: .cancel) {}
            } message: {
                Text("dino.resetMessage")
                Text("dino.settings.icloudResetMessage")
                Text("dino.friends.resetMessage")
            }
            .sheet(isPresented: $showsPrivacy) { DinoSocialPrivacyView() }
            .sheet(isPresented: $showsGameCenter) { DinoFriendsView().gameEnvironment() }
        }.foregroundStyle(DinoStyle.ink)
    }

    private var rowDivider: some View {
        Rectangle().fill(DinoStyle.ink.opacity(highContrast ? 0.5 : 0.08))
            .frame(height: 1).padding(.horizontal, 16).accessibilityHidden(true)
    }

    private func section<Content: View>(_ title: LocalizedStringKey, symbol: String,
                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: symbol).font(.system(size: 18, weight: .bold))
                    .foregroundStyle(DinoStyle.deepGreen).frame(width: 36, height: 36)
                    .background(DinoStyle.green.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                Text(title).font(.system(size: 19, weight: .bold, design: .rounded))
            }
            content()
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(highContrast ? 1 : 0.8), in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(highContrast ? DinoStyle.ink : .white, lineWidth: highContrast ? 2 : 1.5))
    }

    private func resetApp() {
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
