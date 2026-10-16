import SwiftUI
import UIKit

private enum PersonalizationPage: Int, CaseIterable {
    case dino, analog, digital
    var labelKey: String {
        switch self {
        case .dino: return "dino.personalize.dino"
        case .analog: return "dino.personalize.analog"
        case .digital: return "dino.personalize.digital"
        }
    }
    var identifier: String {
        switch self {
        case .dino: return "dino"
        case .analog: return "analog"
        case .digital: return "digital"
        }
    }
}

struct DinoPersonalizer: View {
    @ObservedObject private var language = LanguageManager.shared
    @EnvironmentObject private var player: DinoPlayer
    @Environment(\.dismiss) private var dismiss
    @State private var page = PersonalizationPage.dino
    @State private var theme = ClockTheme.standard

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(PersonalizationPage.allCases, id: \.self) { choice in
                        Button { withAnimation { page = choice } } label: {
                            Text(LocalizedStringKey(choice.labelKey)).modifier(CustomizationText())
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(page == choice ? DinoStyle.green.opacity(0.22) : .white.opacity(0.7),
                                            in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(page == choice ? DinoStyle.deepGreen : DinoStyle.ink.opacity(0.12), lineWidth: page == choice ? 2 : 1))
                                .contentShape(Rectangle())
                        }.buttonStyle(.plain)
                            .accessibilityIdentifier("personalize.page." + choice.identifier)
                            .accessibilityAddTraits(page == choice ? .isSelected : [])
                    }
                }.padding(.horizontal, 16).padding(.top, 32).padding(.bottom, 8)
                    .frame(maxWidth: 520).frame(maxWidth: .infinity)
                TabView(selection: $page) {
                    DinoAppearanceEditor().tag(PersonalizationPage.dino)
                    ClockCustomizer(theme: $theme, page: .analog).tag(PersonalizationPage.analog)
                    ClockCustomizer(theme: $theme, page: .digital).tag(PersonalizationPage.digital)
                }.tabViewStyle(.page(indexDisplayMode: .never)).frame(maxHeight: .infinity).clipped()
                Button("dino.done") {
                    player.completeClockCustomization(theme: theme)
                    dismiss()
                }.buttonStyle(DinoButtonStyle(customization: true)).accessibilityIdentifier("personalize.done")
                    .padding(16).frame(maxWidth: 540).frame(maxWidth: .infinity)
            }
            .modifier(CustomizationTypography())
            .background(JungleBackground(quiet: true))
            .toolbar(.hidden, for: .navigationBar)
        }.foregroundStyle(DinoStyle.ink)
            .onAppear { page = .dino; theme = player.profile.clockTheme }
            .onChange(of: theme) { _, updated in player.setTheme(updated) }
            .onDisappear { player.completeClockCustomization(theme: theme) }
    }
}

/// The welcome flow and HUD use the same immediately saved color choices.
struct DinoAppearanceEditor: View {
    @EnvironmentObject private var player: DinoPlayer
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    var onNavigate: ((Int) -> Void)?
    private var appearance: DinoAppearance { player.profile.dinoAppearance ?? .standard }
    private var compact: Bool { verticalSizeClass == .compact }
    private let swatches: [(name: String, hex: UInt32)] = [
        ("red", 0xED2429), ("orange", 0xF59A32), ("yellow", 0xFBE4AB),
        ("green", 0x88C231), ("darkGreen", 0x246B37), ("blue", 0x459CDF),
        ("purple", 0xA77BE0), ("pink", 0xF48EB6)
    ]

    var body: some View {
        VStack(spacing: 0) {
            preview
            ScrollView {
                VStack(spacing: CustomizationLayout.restoreSpacing) {
                    VStack(spacing: CustomizationLayout.sectionSpacing) {
                        ForEach(DinoAppearance.Part.allCases, id: \.self) { part in
                            colorChoice(part)
                        }
                    }
                    Button {
                        player.setDinoAppearance(.standard)
                    } label: {
                        Label("dino.appearance.reset", systemImage: "arrow.counterclockwise")
                            .modifier(CustomizationText())
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }.buttonStyle(.plain).foregroundStyle(DinoStyle.deepGreen)
                        .accessibilityIdentifier("personalize.resetColors")
                }.modifier(CustomizationOptionsCard())
            }.clipped()
        }
    }

    private var preview: some View {
        ZStack { DinoAvatar(appearance: appearance) }
            .frame(width: compact ? 88 : 180, height: compact ? 88 : 180)
            .shadow(color: DinoStyle.deepGreen.opacity(0.10), radius: 8, y: 5)
            .accessibilityElement(children: .ignore)
            .accessibilityHidden(false)
            .accessibilityLabel(Text("dino.appearance.preview"))
            .accessibilityIdentifier("personalize.preview")
            .modifier(PersonalizationPreviewNavigation(onNavigate: onNavigate))
            .padding(.vertical, CustomizationLayout.previewPadding)
            .frame(maxWidth: .infinity)
    }

    private func colorChoice(_ part: DinoAppearance.Part) -> some View {
        CustomizationSection(title: part.labelKey, identifier: "personalize.\(part.rawValue).label") {
            HStack(spacing: 0) {
                ForEach(swatches, id: \.name) { swatch in
                    Button { setColor(swatch.hex, for: part) } label: {
                        Circle().fill(Color(dinoHex: swatch.hex))
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(DinoStyle.ink.opacity(0.18), lineWidth: 1))
                            .overlay {
                                if appearance[part] == swatch.hex {
                                    Circle().stroke(DinoStyle.ink, lineWidth: 2).padding(-3)
                                    Image(systemName: "checkmark").font(.system(size: 11, weight: .heavy))
                                        .foregroundStyle(swatch.hex == 0x246B37 || swatch.hex == 0xED2429 ? .white : DinoStyle.ink)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .accessibilityLabel(Text(LocalizedStringKey("dino.appearance.color." + swatch.name)))
                        .accessibilityAddTraits(appearance[part] == swatch.hex ? .isSelected : [])
                        .accessibilityIdentifier("personalize.\(part.rawValue).\(swatch.name)")
                }
                ColorPicker(selection: colorBinding(part), supportsOpacity: false) {
                    Text(LocalizedStringKey(part.labelKey))
                }.labelsHidden()
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .accessibilityIdentifier("personalize.color.\(part.rawValue)")
            }
        }
    }

    private func colorBinding(_ part: DinoAppearance.Part) -> Binding<Color> {
        Binding(get: { Color(dinoHex: appearance[part]) }, set: { color in
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            guard UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return }
            func channel(_ component: CGFloat) -> UInt32 {
                UInt32((min(1, max(0, component)) * 255).rounded())
            }
            let rgb = channel(red) << 16 | channel(green) << 8 | channel(blue)
            setColor(rgb, for: part)
        })
    }
    private func setColor(_ hex: UInt32, for part: DinoAppearance.Part) {
        var updated = appearance
        updated[part] = hex
        player.setDinoAppearance(updated)
    }
}
