import SwiftUI

/// Personalize Dino, then make the analog clock and the digital clock in order.
struct OnboardingFlow: View {
    @ObservedObject private var language = LanguageManager.shared
    @EnvironmentObject private var player: DinoPlayer
    @State private var step = 0
    @State private var theme = ClockTheme.standard

    var body: some View {
        content.modifier(CustomizationTypography(welcome: true))
            .onAppear { theme = player.profile.clockTheme }
    }

    private var content: some View {
        OnboardingPages(step: step, theme: $theme, navigate: navigate)
            .background(JungleBackground())
            .foregroundStyle(DinoStyle.ink)
    }

    private func navigate(_ offset: Int) {
        let destination = min(2, max(0, step + offset))
        guard destination != step else { return }
        if step == 1 && destination == 2 && theme.analogColorsMatch { theme.resetAnalog() }
        withAnimation { step = destination }
    }
}

private struct OnboardingPages: View {
    @Environment(\.customizationMetrics) private var metrics
    @EnvironmentObject private var player: DinoPlayer
    let step: Int
    @Binding var theme: ClockTheme
    let navigate: (Int) -> Void

    var body: some View {
        let page: ClockCustomizerPage = step == 1 ? .analog : .digital
        if metrics.spacious {
            if step == 0 {
                DinoAppearanceEditor(onNavigate: navigate,
                                     welcomeChrome: (AnyView(title), AnyView(action)))
            } else {
                ClockCustomizer(theme: $theme, page: page, onNavigate: navigate,
                                welcomeChrome: (AnyView(title), AnyView(action)))
            }
        } else {
            VStack(spacing: 0) {
                title
                Group {
                    if step == 0 {
                        DinoAppearanceEditor(onNavigate: navigate)
                    } else {
                        ClockCustomizer(theme: $theme, page: page, onNavigate: navigate)
                    }
                }.frame(maxHeight: .infinity).clipped()
                action.padding(16).modifier(CustomizationWidth(footer: true))
            }
        }
    }

    private var title: some View {
        Text(LocalizedStringKey(step == 0 ? "dino.appearance.welcome" : step == 1 ? "dino.makeAnalogClock" : "dino.makeDigitalClock"))
            .modifier(CustomizationTitle())
            .multilineTextAlignment(.center).padding(.horizontal, 20).padding(.vertical, 8)
            .accessibilityIdentifier("onboarding.title")
    }

    @ViewBuilder private var action: some View {
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
    }
}
