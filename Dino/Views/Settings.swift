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
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("dino.settings.gameCenter", systemImage: "person.crop.circle.fill").font(.headline)
                        if let name = friends.playerDisplayName {
                            Text(verbatim: name).font(.title3.bold()).textSelection(.enabled)
                                .accessibilityIdentifier("settings.gameCenterName")
                            Text("dino.settings.gameCenter.nameSource").font(.footnote)
                                .foregroundStyle(DinoStyle.muted)
                        } else {
                            Text("dino.settings.gameCenter.noAccount").font(.subheadline)
                                .accessibilityIdentifier("settings.gameCenterSignedOut")
                        }
                        Button("dino.settings.gameCenter.open") { showsGameCenter = true }
                            .buttonStyle(DinoSecondaryButtonStyle())
                            .accessibilityIdentifier("settings.gameCenter")
                    }.dinoCard()
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("dino.language", systemImage: "globe").font(.headline)
                            Spacer()
                            LanguagePicker(tint: DinoStyle.ink)
                        }
                        NavigationLink {
                            MyClocksView().environmentObject(player)
                        } label: {
                            HStack {
                                Label("dino.myClocks", systemImage: "clock.fill")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }.font(.headline).padding(.vertical, 12)
                        }.accessibilityIdentifier("settings.clocks")
                    }.dinoCard()
                    VStack(alignment: .leading, spacing: 16) {
                        Label("dino.settings.play", systemImage: "slider.horizontal.3").font(.headline)
                        preference("dino.settings.soundEffects", symbol: "speaker.wave.2.fill",
                                   value: $settings.soundEffectsEnabled, identifier: "settings.soundEffects")
                        Divider()
                        preference("dino.settings.haptics", symbol: "iphone.radiowaves.left.and.right",
                                   value: $settings.hapticsEnabled, identifier: "settings.haptics")
                        Divider()
                        preference("dino.settings.highContrast", symbol: "circle.lefthalf.filled",
                                   value: $settings.highContrastEnabled, identifier: "settings.highContrast")
                    }.dinoCard()
                    VStack(alignment: .leading, spacing: 12) {
                        preference("dino.settings.icloudSync", symbol: "icloud.fill",
                                   value: $settings.icloudSyncEnabled, identifier: "settings.icloudSync")
                        Text("dino.settings.icloudDescription").font(.subheadline)
                        Text(LocalizedStringKey(cloudSync.status.messageKey)).font(.footnote)
                            .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                            .accessibilityIdentifier("settings.icloudStatus")
                    }.dinoCard()
                    Button("dino.friends.privacy") { showsPrivacy = true }.frame(minHeight: 44)
                    Button("dino.map") { dismiss() }.buttonStyle(DinoSecondaryButtonStyle())
                    Button { confirmReset = true } label: {
                        Label("dino.resetProgress", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(dinoHex: 0xA64D4D)).frame(minHeight: 48)
                    }.accessibilityIdentifier("settings.reset")
                }.padding(20).frame(maxWidth: 520).frame(maxWidth: .infinity)
            }.background(JungleBackground(quiet: true))
                .navigationTitle(Text(verbatim: L("dino.settings")))
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("dino.done") { dismiss() } } }
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
        }.tint(DinoStyle.deepGreen).frame(minHeight: 44)
            .accessibilityIdentifier(identifier)
    }
}
