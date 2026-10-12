import SwiftUI

/// Start by personalizing Dino, followed by the optional clock choices.
struct OnboardingFlow: View {
    @ObservedObject private var language = LanguageManager.shared
    @EnvironmentObject private var player: DinoPlayer
    @State private var step = 0
    @State private var theme = ClockTheme.standard

    var body: some View {
        ZStack {
            JungleBackground()
            VStack(spacing: 0) {
                HStack {
                    if step == 1 {
                        DinoIconButton(icon: "chevron.left", labelKey: "dino.back") {
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

                if step == 0 {
                    Text("dino.appearance.welcome")
                        .font(.system(size: 29, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center).padding(.horizontal, 20).padding(.vertical, 8)
                    DinoAppearanceEditor().accessibilityIdentifier("onboarding.dino")
                } else {
                    ScrollView {
                        VStack(spacing: 22) {
                            Text("dino.makeClock").font(.system(size: 29, weight: .heavy, design: .rounded))
                            ClockCustomizer(theme: $theme)
                        }.padding(24).frame(maxWidth: 540).frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .foregroundStyle(DinoStyle.ink)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if step == 0 {
                    Button { withAnimation { step = 1 } } label: {
                        HStack { Text("dino.next"); Image(systemName: "arrow.right") }
                    }.buttonStyle(DinoButtonStyle())
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
        .onAppear { theme = player.profile.clockTheme }
    }
}
