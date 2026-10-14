import SwiftUI

/// Personalize Dino, then make the analog clock and the digital clock in order.
struct OnboardingFlow: View {
    @ObservedObject private var language = LanguageManager.shared
    @EnvironmentObject private var player: DinoPlayer
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var step = 0
    @State private var theme = ClockTheme.standard

    var body: some View {
        VStack(spacing: 0) {
            Text(LocalizedStringKey(step == 0 ? "dino.appearance.welcome" : step == 1 ? "dino.makeAnalogClock" : "dino.makeDigitalClock"))
                .font(.system(size: verticalSizeClass == .compact ? 24 : 29, weight: .heavy, design: .rounded))
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
        .onAppear { theme = player.profile.clockTheme }
    }

    private var footer: some View {
        Group {
            if step < 2 {
                Button {
                    navigate(1)
                } label: {
                    HStack { Text("dino.next"); Image(systemName: "arrow.right") }
                }.buttonStyle(DinoButtonStyle()).accessibilityIdentifier("onboarding.next")
            } else {
                Button("dino.useMyClock") { player.completeOnboarding(theme: theme) }
                    .buttonStyle(DinoButtonStyle()).accessibilityIdentifier("onboarding.customClock")
            }
        }.padding(16).frame(maxWidth: 540).frame(maxWidth: .infinity)
    }

    private func navigate(_ offset: Int) {
        let destination = min(2, max(0, step + offset))
        guard destination != step else { return }
        if step == 1 && destination == 2 && theme.analogColorsMatch { theme.resetAnalog() }
        withAnimation { step = destination }
    }
}
