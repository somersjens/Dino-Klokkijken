import SwiftUI

/// Scrollable player preferences, clock customization and progress reset.
struct DinoSettingsView: View {
    @ObservedObject private var language = LanguageManager.shared
    @EnvironmentObject private var player: DinoPlayer
    @EnvironmentObject private var settings: DinoSettings
    @EnvironmentObject private var cloudSync: DinoCloudSync
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var confirmReset = false
    @State private var nameError = false
    @State private var showsPrivacy = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
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
                    VStack(alignment: .leading, spacing: 14) {
                        Label("dino.playerName", systemImage: "person.fill").font(.headline)
                        TextField(L("dino.namePlaceholder"), text: $name).font(.title3)
                            .padding(14).background(DinoStyle.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                            .onChange(of: name) { _, _ in nameError = false }
                        Button("dino.saveName") {
                            if player.setName(name) { name = player.profile.name; nameError = false }
                            else { nameError = true }
                        }.buttonStyle(DinoButtonStyle(compact: true))
                            .disabled(PlayerProfile.sanitizedName(name).isEmpty)
                            .opacity(PlayerProfile.sanitizedName(name).isEmpty ? 0.5 : 1)
                        Text("dino.nameLocalOnly").font(.footnote)
                        if nameError { Text("dino.nameInvalid").font(.footnote) }
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
                    Button("dino.resetProgress", role: .destructive) { player.resetProgress() }
                    Button("dino.cancel", role: .cancel) {}
                } message: {
                    Text("dino.resetMessage")
                    if settings.icloudSyncEnabled { Text("dino.settings.icloudResetMessage") }
                    Text("dino.friends.resetMessage")
                }
                .sheet(isPresented: $showsPrivacy) { DinoSocialPrivacyView() }
        }.foregroundStyle(DinoStyle.ink).onAppear { name = player.profile.name }
    }

    private func preference(_ key: LocalizedStringKey, symbol: String, value: Binding<Bool>, identifier: String) -> some View {
        Toggle(isOn: value) {
            Label(key, systemImage: symbol).font(.system(size: 17, weight: .semibold, design: .rounded))
        }.tint(DinoStyle.deepGreen).frame(minHeight: 44)
            .accessibilityIdentifier(identifier)
    }
}
