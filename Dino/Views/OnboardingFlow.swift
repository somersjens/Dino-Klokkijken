import SwiftUI

/// Start directly with the name; clock personalization is the optional second step.
struct OnboardingFlow: View {
    @ObservedObject private var language = LanguageManager.shared
    @EnvironmentObject private var player: DinoPlayer
    @State private var step = 0
    @State private var name = ""
    @State private var nameError = false
    @State private var theme = ClockTheme.standard
    @FocusState private var nameFocused: Bool

    var body: some View {
        ZStack {
            JungleBackground()
            VStack(spacing: 0) {
                HStack {
                    if step == 1 {
                        DinoIconButton(icon: "chevron.left", labelKey: "dino.back") {
                            nameFocused = false
                            withAnimation { step = 0 }
                        }
                    } else {
                        Image(systemName: "leaf.fill").font(.title2).foregroundStyle(DinoStyle.deepGreen)
                            .frame(width: 48, height: 48)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(0..<2, id: \.self) { i in
                            Capsule().fill(i == step ? DinoStyle.deepGreen : DinoStyle.green.opacity(0.4))
                                .frame(width: i == step ? 24 : 8, height: 8)
                        }
                    }
                    Spacer()
                    LanguagePicker(tint: DinoStyle.ink)
                }.padding(.horizontal, 20).padding(.vertical, 8)

                ScrollView {
                    VStack(spacing: 22) {
                        if step == 0 { chooseName }
                        else {
                            Text("dino.makeClock").font(.system(size: 29, weight: .heavy, design: .rounded))
                            ClockCustomizer(theme: $theme)
                        }
                    }.padding(24).frame(maxWidth: 540).frame(maxWidth: .infinity)
                }.scrollDismissesKeyboard(.interactively)
            }
        }
        .foregroundStyle(DinoStyle.ink)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if step == 0 {
                    Button(action: saveName) {
                        HStack { Text("dino.next"); Image(systemName: "arrow.right") }
                    }.buttonStyle(DinoButtonStyle())
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                        .accessibilityIdentifier("onboarding.next")
                } else {
                    Button("dino.useMyClock") { player.completeOnboarding(theme: theme) }
                        .buttonStyle(DinoButtonStyle()).accessibilityIdentifier("onboarding.customClock")
                    Button("dino.useStandard") { player.completeOnboarding(theme: .standard) }
                        .buttonStyle(DinoSecondaryButtonStyle()).accessibilityIdentifier("onboarding.standardClock")
                }
            }.padding(16).frame(maxWidth: 540).frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
        }
        .onAppear { name = player.profile.name; theme = player.profile.clockTheme }
    }

    private var chooseName: some View {
        VStack(spacing: 20) {
            Text("dino.title").font(.system(size: 34, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center).minimumScaleFactor(0.8)
            DinoCharacter(state: .happy, size: nameFocused ? 100 : 190)
                .animation(.easeInOut(duration: 0.2), value: nameFocused)
            Text("dino.yourName").font(.system(size: 28, weight: .heavy, design: .rounded))
            TextField(L("dino.namePlaceholder"), text: $name)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center).padding(18)
                .background(.white, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(DinoStyle.green, lineWidth: 2))
                .focused($nameFocused).submitLabel(.next)
                .textContentType(.givenName).autocorrectionDisabled()
                .onChange(of: name) { _, _ in nameError = false }
                .onSubmit { saveName() }
                .accessibilityIdentifier("onboarding.name")
            if nameError {
                Text("dino.nameInvalid").font(.footnote).multilineTextAlignment(.center)
                Button("dino.useSafeName") { name = DinoNameValidator.fallback; saveName() }
                    .buttonStyle(DinoSecondaryButtonStyle())
            }
        }.padding(.top, 8)
    }

    private func saveName() {
        guard player.setName(name) else { nameError = true; return }
        nameFocused = false
        withAnimation { step = 1 }
    }
}
