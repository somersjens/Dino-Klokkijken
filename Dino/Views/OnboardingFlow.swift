import SwiftUI

/// Personalize Dino, then make the analog clock and the digital clock in order.
struct OnboardingFlow: View {
    @ObservedObject private var language = LanguageManager.shared
    @EnvironmentObject private var player: DinoPlayer
    @State private var step = 0
    @State private var theme = ClockTheme.standard

    var body: some View {
        content.modifier(CustomizationTypography())
            .onAppear { theme = player.profile.clockTheme }
    }

    private var content: some View {
        VStack(spacing: 0) {
            Text(LocalizedStringKey(step == 0 ? "dino.appearance.welcome" : step == 1 ? "dino.makeAnalogClock" : "dino.makeDigitalClock"))
                .modifier(CustomizationTitle())
                .multilineTextAlignment(.center).padding(.horizontal, 20).padding(.vertical, 8)
                .accessibilityIdentifier("onboarding.title")
            Group {
                if step == 0 {
                    DinoAppearanceEditor(onNavigate: navigate)
                } else {
                    ClockCustomizer(theme: $theme, page: step == 1 ? .analog : .digital, onNavigate: navigate)
                }
            }.frame(maxHeight: .infinity).clipped()
            footer
        }
        .background(JungleBackground())
        .foregroundStyle(DinoStyle.ink)
    }

    private var footer: some View {
        Group {
            if step < 2 {
                Button {
                    navigate(1)
                } label: {
                    HStack { Text("dino.next"); Image(systemName: "arrow.right") }
                }.buttonStyle(DinoButtonStyle(customization: true)).accessibilityIdentifier("onboarding.next")
            } else {
                Button("dino.useMyClock") { player.completeOnboarding(theme: theme) }
                    .buttonStyle(DinoButtonStyle(customization: true)).accessibilityIdentifier("onboarding.customClock")
            }
        }.padding(16).modifier(CustomizationWidth(footer: true))
    }

    private func navigate(_ offset: Int) {
        let destination = min(2, max(0, step + offset))
        guard destination != step else { return }
        if step == 1 && destination == 2 && theme.analogColorsMatch { theme.resetAnalog() }
        withAnimation { step = destination }
    }
}
