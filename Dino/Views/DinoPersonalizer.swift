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
            GeometryReader { geometry in
                let landscape = geometry.size.width > geometry.size.height
                let arrangement = landscape ? AnyLayout(HStackLayout(spacing: 8)) : AnyLayout(VStackLayout(spacing: 0))
                arrangement {
                    if landscape {
                        VStack(spacing: 12) {
                            Group {
                                switch page {
                                case .dino: DinoAppearanceEditor(showsOptions: false)
                                case .analog: ClockCustomizer(theme: $theme, page: .analog, showsOptions: false)
                                case .digital: ClockCustomizer(theme: $theme, page: .digital, showsOptions: false)
                                }
                            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                            VStack(spacing: 8) {
                                HStack(spacing: 8) {
                                    pageButton(.dino, compact: true)
                                    pageButton(.analog, compact: true)
                                }
                                HStack(spacing: 8) {
                                    doneButton(compact: true)
                                    pageButton(.digital, compact: true)
                                }
                            }
                            .environment(\.customizationTypeScale, 1)
                        }
                        .padding(.vertical, 12).padding(.leading, 12)
                        .frame(width: min(geometry.size.height < 500 ? 232 : 360, geometry.size.width * 0.32))
                    } else {
                        pageButtons(vertical: false)
                            .padding(.horizontal, 16).padding(.top, 32).padding(.bottom, 8)
                            .modifier(CustomizationWidth())
                    }
                    TabView(selection: $page) {
                        DinoAppearanceEditor(showsPreview: !landscape).tag(PersonalizationPage.dino)
                        ClockCustomizer(theme: $theme, page: .analog, showsPreview: !landscape).tag(PersonalizationPage.analog)
                        ClockCustomizer(theme: $theme, page: .digital, showsPreview: !landscape).tag(PersonalizationPage.digital)
                    }.tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
                    if !landscape {
                        doneButton().padding(16).modifier(CustomizationWidth(footer: true))
                    }
                }
                .modifier(CustomizationTypography())
            }
            .background(JungleBackground(quiet: true))
            .toolbar(.hidden, for: .navigationBar)
        }.foregroundStyle(DinoStyle.ink)
            .onAppear { page = .dino; theme = player.profile.clockTheme }
            .onValueChange(of: theme) { updated in player.setTheme(updated) }
            .onDisappear { player.completeClockCustomization(theme: theme) }
    }

    private func doneButton(compact: Bool = false) -> some View {
        Button("dino.done") {
            player.completeClockCustomization(theme: theme)
            dismiss()
        }.buttonStyle(DinoButtonStyle(compact: compact, customization: !compact))
            .accessibilityIdentifier("personalize.done")
    }

    private func pageButtons(vertical: Bool) -> some View {
        let arrangement = vertical ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 8))
        return arrangement {
            ForEach(PersonalizationPage.allCases, id: \.self) { choice in
                pageButton(choice)
            }
        }
    }

    private func pageButton(_ choice: PersonalizationPage, compact: Bool = false) -> some View {
        Button { withAnimation { page = choice } } label: {
            Text(LocalizedStringKey(choice.labelKey)).modifier(CustomizationText())
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: compact ? 48 : 44)
                .background(page == choice ? DinoStyle.green.opacity(0.22) : .white.opacity(0.7),
                            in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(page == choice ? DinoStyle.deepGreen : DinoStyle.ink.opacity(0.12), lineWidth: page == choice ? 2 : 1))
                .contentShape(Rectangle())
        }.buttonStyle(DinoPlainButtonStyle())
            .accessibilityIdentifier("personalize.page." + choice.identifier)
    }

}

/// The welcome flow and HUD use the same immediately saved color choices.
struct DinoAppearanceEditor: View {
    @EnvironmentObject private var player: DinoPlayer
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.customizationMetrics) private var metrics
    var onNavigate: ((Int) -> Void)?
    var showsPreview = true
    var showsOptions = true
    private var appearance: DinoAppearance { player.profile.dinoAppearance ?? .standard }
    private var compact: Bool { verticalSizeClass == .compact }
    private let swatches: [(name: String, hex: UInt32)] = [
        ("red", 0xED2429), ("orange", 0xF59A32), ("yellow", 0xFBE4AB),
        ("green", 0x88C231), ("darkGreen", 0x246B37), ("blue", 0x459CDF),
        ("purple", 0xA77BE0), ("pink", 0xF48EB6)
    ]

    var body: some View {
        let layout = metrics.sideBySide ? AnyLayout(HStackLayout(spacing: 16)) : AnyLayout(VStackLayout(spacing: 0))
        layout {
            if showsPreview { preview }
            if showsOptions {
            ScrollView {
                VStack(spacing: CustomizationLayout.restoreSpacing) {
                    VStack(spacing: CustomizationLayout.sectionSpacing * metrics.enlargement) {
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
                    }.buttonStyle(DinoPlainButtonStyle()).foregroundStyle(DinoStyle.deepGreen)
                        .accessibilityIdentifier("personalize.resetColors")
                }.modifier(CustomizationOptionsCard())
            }.clipped().accessibilityIdentifier("personalize.options")
            }
        }.frame(maxWidth: metrics.sideBySide ? 1100 : .infinity).frame(maxWidth: .infinity)
    }

    private var preview: some View {
        ZStack { DinoAvatar(appearance: appearance) }
            .frame(width: compact ? (showsOptions ? 120 : 156) : metrics.previewSize, height: compact ? (showsOptions ? 120 : 156) : metrics.previewSize)
            .shadow(color: DinoStyle.deepGreen.opacity(0.10), radius: 8, y: 5)
            .accessibilityHidden(false)
            .accessibilityIdentifier("personalize.preview")
            .modifier(PersonalizationPreviewNavigation(onNavigate: onNavigate))
            .padding(.vertical, CustomizationLayout.previewPadding)
            .frame(maxWidth: metrics.sideBySide ? (compact ? (showsOptions ? 132 : 188) : 320) : .infinity)
    }

    private func colorChoice(_ part: DinoAppearance.Part) -> some View {
        let arrangement = compact ? AnyLayout(HStackLayout(spacing: 6)) : AnyLayout(VStackLayout(spacing: 12 * metrics.enlargement))
        return arrangement {
            Group {
                if compact {
                    Text(LocalizedStringKey(part.labelKey))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.leading).lineLimit(2).minimumScaleFactor(0.85)
                } else {
                    Text(LocalizedStringKey(part.labelKey)).modifier(CustomizationText())
                }
            }
                .frame(width: compact ? 64 : nil, alignment: compact ? .leading : .center)
                .accessibilityIdentifier("personalize.\(part.rawValue).label")
            HStack(spacing: 0) {
                ForEach(swatches, id: \.name) { swatch in
                    Button { setColor(swatch.hex, for: part) } label: {
                        Circle().fill(Color(dinoHex: swatch.hex))
                            .frame(width: compact ? 24 : metrics.swatchSize, height: compact ? 24 : metrics.swatchSize)
                            .overlay(Circle().stroke(DinoStyle.ink.opacity(0.18), lineWidth: 1))
                            .overlay {
                                if appearance[part] == swatch.hex {
                                    Circle().stroke(DinoStyle.ink, lineWidth: 2).padding(-3)
                                    Image(systemName: "checkmark").font(.system(size: 11, weight: .heavy))
                                        .foregroundStyle(swatch.hex == 0x246B37 || swatch.hex == 0xED2429 ? .white : DinoStyle.ink)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: metrics.controlHeight)
                            .contentShape(Rectangle())
                    }.buttonStyle(DinoPlainButtonStyle())
                        .accessibilityIdentifier("personalize.\(part.rawValue).\(swatch.name)")
                }
                ColorPicker(selection: colorBinding(part), supportsOpacity: false) {
                    Text(LocalizedStringKey(part.labelKey))
                }.labelsHidden()
                    .scaleEffect(metrics.spacious ? 1.25 : 1)
                    .frame(maxWidth: .infinity, minHeight: metrics.controlHeight)
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
