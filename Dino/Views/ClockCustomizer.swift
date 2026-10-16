import SwiftUI
import UIKit

extension TimelineSchedule where Self == PeriodicTimelineSchedule {
    /// These clocks display minutes, so refresh exactly at minute boundaries.
    static var dinoMinute: PeriodicTimelineSchedule {
        .init(from: Date(timeIntervalSinceReferenceDate: floor(Date().timeIntervalSinceReferenceDate / 60) * 60), by: 60)
    }
}

enum ClockCustomizerPage {
    case analog, digital, both
}

struct ClockCustomizer: View {
    @ObservedObject private var language = LanguageManager.shared
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.customizationMetrics) private var metrics
    @Binding var theme: ClockTheme
    var page: ClockCustomizerPage = .both
    var onNavigate: ((Int) -> Void)? = nil
    private var compact: Bool { verticalSizeClass == .compact }
    private var inkSwatches: [(name: String, hex: UInt32)] { ClockInk.allCases.map { ($0.rawValue, $0.hex) } }
    private let digitalInkSwatches: [(name: String, hex: UInt32)] = [
        ("navy", 0x193B53), ("orange", 0xED832B), ("green", 0x299A49),
        ("red", 0xD83D3A), ("white", 0xFFFFFF)
    ]
    private var faceSwatches: [(name: String, hex: UInt32)] { ClockFace.allCases.map { ($0.rawValue, $0.hex) } }
    private var displaySwatches: [(name: String, hex: UInt32)] { DigitalDisplay.allCases.map { ($0.rawValue, $0.hex) } }

    var body: some View {
        Group {
            switch page {
            case .both:
                VStack(spacing: 20) {
                    VStack(spacing: 20) {
                        analogPreview
                        analogOptions
                    }.dinoCard()
                    VStack(spacing: 20) {
                        digitalPreview
                        digitalOptions
                    }.dinoCard()
                }
            case .analog, .digital:
                let horizontal = compact || metrics.sideBySide
                let layout = horizontal ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
                layout {
                    Group {
                        if page == .analog { analogPreview } else { digitalPreview }
                    }.padding(.vertical, CustomizationLayout.previewPadding)
                        .frame(maxWidth: compact ? (page == .analog ? 140 : 185) : metrics.sideBySide ? 320 : .infinity)
                    ScrollView {
                        Group {
                            if page == .analog { analogOptions } else { digitalOptions }
                        }.modifier(CustomizationOptionsCard())
                    }.clipped().id(page == .analog ? "analog" : "digital")
                        .accessibilityIdentifier(page == .analog ? "theme.options.analog" : "theme.options.digital")
                }.frame(maxWidth: compact ? 760 : metrics.sideBySide ? 1100 : .infinity).frame(maxWidth: .infinity)
            }
        }.foregroundStyle(DinoStyle.ink)
            .onAppear { theme = theme.applyingFixedStyles() }
    }

    private var analogPreview: some View {
        TimelineView(.dinoMinute) { context in
            VStack(spacing: 10) {
                AnalogClock(time: ClockTime(date: context.date), theme: theme, size: compact ? 100 : metrics.previewSize)
                    .accessibilityIdentifier("theme.analog.preview")
                    .modifier(PersonalizationPreviewNavigation(onNavigate: onNavigate))
                if theme.analogColorsMatch { ClockColorWarning(analog: true) }
            }
        }.padding(.horizontal, 16).frame(maxWidth: metrics.contentWidth)
    }

    private var digitalPreview: some View {
        TimelineView(.dinoMinute) { context in
            VStack(spacing: 10) {
                DigitalClock(time: ClockTime(date: context.date), theme: theme, fontSize: compact ? 36 : metrics.spacious ? 68 : 48)
                    .accessibilityIdentifier("theme.digital.preview")
                    .modifier(PersonalizationPreviewNavigation(onNavigate: onNavigate))
                if theme.digitalColorsMatch { ClockColorWarning(analog: false) }
            }
        }.padding(.horizontal, 16).frame(maxWidth: metrics.contentWidth)
    }

    private var analogOptions: some View {
        VStack(spacing: CustomizationLayout.restoreSpacing) {
            VStack(spacing: CustomizationLayout.sectionSpacing * metrics.enlargement) {
                analogNumeralChoices
                analogShapeChoices.padding(.bottom, CustomizationLayout.swatchInset)
                colorChoices(title: "dino.hourHand", color: analogColor(\.customHourHex, preset: \.hourInk), values: inkSwatches)
                colorChoices(title: "dino.minuteHand", color: analogColor(\.customMinuteHex, preset: \.minuteInk), values: inkSwatches)
                colorChoices(title: "dino.face", color: faceColor, values: faceSwatches)
                colorChoices(title: "dino.rim", color: analogColor(\.customRimHex, preset: \.rimInk), values: inkSwatches)
                // Re-enable alongside ClockTheme.applyingFixedStyles() if hand styles return.
                // styleChoice(title: "dino.hands", selection: $theme.hands, values: ClockHandStyle.allCases,
                //             keyPrefix: "dino.hands.", identifier: "theme.hands")
            }
            ClockRestoreStyleButton(theme: $theme, analog: true)
        }
    }

    private var digitalOptions: some View {
        VStack(spacing: CustomizationLayout.restoreSpacing) {
            VStack(spacing: CustomizationLayout.sectionSpacing * metrics.enlargement) {
                colorChoices(title: "dino.digitColor", color: $theme.digitalInkHex, values: digitalInkSwatches)
                colorChoices(title: "dino.display", color: displayColor, values: displaySwatches)
                CustomizationSection(title: "dino.numerals", identifier: "theme.numerals.label",
                                     controlSpacing: CustomizationLayout.labelSpacing + CustomizationLayout.swatchInset) {
                    VStack(spacing: CustomizationLayout.choiceSpacing) {
                        ForEach(0..<2, id: \.self) { row in
                            HStack(spacing: CustomizationLayout.choiceSpacing) {
                                ForEach(Array(DigitalNumerals.allCases.dropFirst(row * 2).prefix(2)), id: \.self) { style in
                                    fontChoice(style)
                                }
                            }
                        }
                    }
                }
            }
            ClockRestoreStyleButton(theme: $theme, analog: false)
        }
    }

    private func fontChoice(_ style: DigitalNumerals) -> some View {
        Button { theme.numerals = style } label: {
            GeometryReader { geometry in
                TimelineView(.dinoMinute) { context in
                    DigitalClock(time: ClockTime(date: context.date), theme: fontPreview(style),
                                 fontSize: max(1, min(40, (geometry.size.width - 24) / 3)), showsDisplay: false)
                        .fixedSize().frame(maxWidth: .infinity, maxHeight: .infinity)
                }.accessibilityHidden(true)
            }.frame(height: 72).frame(maxWidth: .infinity)
                .background(theme.numerals == style ? DinoStyle.green.opacity(0.18) : .clear, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.numerals == style ? DinoStyle.deepGreen : DinoStyle.ink.opacity(0.15), lineWidth: theme.numerals == style ? 2 : 1))
        }.buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: L(key: "dino.numerals." + style.rawValue)))
            .accessibilityAddTraits(theme.numerals == style ? .isSelected : [])
            .accessibilityIdentifier("theme.numerals." + style.rawValue)
    }

    private func fontPreview(_ style: DigitalNumerals) -> ClockTheme {
        var preview = ClockTheme.standard
        preview.numerals = style
        preview.digitalInkHex = ClockInk.navy.hex
        return preview
    }

    private func styleChoice<T: RawRepresentable & Hashable>(title: String? = nil, selection: Binding<T>, values: [T],
                                                            keyPrefix: String, identifier: String) -> some View where T.RawValue == String {
        HStack(spacing: 12) {
            if let title {
                Text(LocalizedStringKey(title)).modifier(CustomizationText())
                    .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                    .accessibilityIdentifier(identifier + ".label")
            }
            HStack(spacing: 3) {
                ForEach(values, id: \.self) { value in
                    Button { selection.wrappedValue = value } label: {
                        Text(verbatim: L(key: keyPrefix + value.rawValue))
                            .modifier(CustomizationText()).padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(selection.wrappedValue == value ? DinoStyle.green.opacity(0.22) : .clear,
                                        in: RoundedRectangle(cornerRadius: 10))
                    }.buttonStyle(.plain)
                        .accessibilityIdentifier(identifier + "." + value.rawValue)
                        .accessibilityAddTraits(selection.wrappedValue == value ? .isSelected : [])
                }
            }.padding(3).background(DinoStyle.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 13))
                .frame(maxWidth: 240).accessibilityElement(children: .contain)
                .accessibilityIdentifier(identifier)
        }.frame(maxWidth: .infinity, minHeight: 44)
    }

    private var analogShapeChoices: some View {
        HStack(spacing: 8) {
            ForEach(AnalogClockShape.allCases, id: \.self) { shape in
                shapeChoice(title: "dino.shape." + shape.rawValue, selected: theme.analogShape == shape,
                            identifier: "theme.analogShape." + shape.rawValue) { theme.analogShape = shape } icon: {
                    AnalogClockOutline(shape: shape).stroke(DinoStyle.ink, lineWidth: 2.5).frame(width: 28, height: 28)
                }
            }
        }.accessibilityElement(children: .contain).accessibilityIdentifier("theme.analogShape")
    }

    private var analogNumeralChoices: some View {
        HStack(spacing: 8) {
            ForEach(AnalogNumerals.allCases, id: \.self) { numerals in
                Button { theme.analogNumerals = numerals } label: {
                    Text(verbatim: L(key: "dino.analogNumerals." + numerals.rawValue))
                        .modifier(CustomizationText()).padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(theme.analogNumerals == numerals ? DinoStyle.green.opacity(0.18) : .clear,
                                    in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.analogNumerals == numerals ? DinoStyle.deepGreen : DinoStyle.ink.opacity(0.15),
                                    lineWidth: theme.analogNumerals == numerals ? 2 : 1))
                        .contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .accessibilityIdentifier("theme.analogNumerals." + numerals.rawValue)
                    .accessibilityAddTraits(theme.analogNumerals == numerals ? .isSelected : [])
            }
        }.accessibilityElement(children: .contain).accessibilityIdentifier("theme.analogNumerals")
    }

    private func shapeChoice<Icon: View>(title: String, selected: Bool, identifier: String,
                                         action: @escaping () -> Void, @ViewBuilder icon: () -> Icon) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                icon().frame(height: 30)
                Text(verbatim: L(key: title)).modifier(CustomizationText())
            }.padding(.horizontal, 6).padding(.vertical, 8).frame(maxWidth: .infinity)
                .background(selected ? DinoStyle.green.opacity(0.18) : .clear, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? DinoStyle.deepGreen : DinoStyle.ink.opacity(0.15), lineWidth: selected ? 2 : 1))
        }.buttonStyle(.plain).accessibilityIdentifier(identifier)
            .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func colorChoices(title: String, color: Binding<UInt32>, values: [(name: String, hex: UInt32)]) -> some View {
        CustomizationSection(title: title, identifier: "theme." + title + ".label") {
            HStack(spacing: 0) {
                ForEach(values, id: \.name) { value in
                    Button { color.wrappedValue = value.hex } label: {
                        Circle().fill(Color(dinoHex: value.hex)).frame(width: metrics.swatchSize, height: metrics.swatchSize)
                            .overlay(Circle().stroke(DinoStyle.ink.opacity(0.18), lineWidth: 1))
                            .overlay {
                                if color.wrappedValue == value.hex {
                                    Circle().stroke(DinoStyle.deepGreen, lineWidth: 2).padding(-3)
                                    Image(systemName: "checkmark").font(.system(size: 12, weight: .heavy))
                                        .foregroundStyle(Color(dinoHex: ClockColorContrast.markingHex(on: value.hex)))
                                }
                            }.frame(maxWidth: .infinity, minHeight: metrics.controlHeight).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .accessibilityIdentifier("theme." + title + "." + value.name)
                        .accessibilityLabel(Text(verbatim: L(key: "dino.color." + value.name)))
                        .accessibilityAddTraits(color.wrappedValue == value.hex ? .isSelected : [])
                }
                ColorPicker(selection: systemColor(color), supportsOpacity: false) { Text("dino.customColor") }
                    .labelsHidden().scaleEffect(metrics.spacious ? 1.25 : 1)
                    .frame(maxWidth: .infinity, minHeight: metrics.controlHeight)
                    .accessibilityLabel(Text(verbatim: L(key: title) + ", " + L("dino.customColor")))
                    .accessibilityValue(Text(verbatim: String(format: "#%06X", color.wrappedValue)))
                    .accessibilityIdentifier("theme." + title + ".custom")
            }
        }
    }

    private func systemColor(_ hex: Binding<UInt32>) -> Binding<Color> {
        Binding(get: { Color(dinoHex: hex.wrappedValue) }, set: { color in
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            guard UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return }
            func channel(_ component: CGFloat) -> UInt32 { UInt32((min(1, max(0, component)) * 255).rounded()) }
            hex.wrappedValue = channel(red) << 16 | channel(green) << 8 | channel(blue)
        })
    }

    private func analogColor(_ custom: WritableKeyPath<ClockTheme, UInt32?>, preset: WritableKeyPath<ClockTheme, ClockInk>) -> Binding<UInt32> {
        Binding(get: { theme[keyPath: custom] ?? theme[keyPath: preset].hex }, set: { hex in
            if let ink = ClockInk.allCases.first(where: { $0.hex == hex }) {
                theme[keyPath: preset] = ink; theme[keyPath: custom] = nil
            } else { theme[keyPath: custom] = hex }
        })
    }

    private var faceColor: Binding<UInt32> {
        Binding(get: { theme.faceHex }, set: { hex in
            if let face = ClockFace.allCases.first(where: { $0.hex == hex }) {
                theme.face = face; theme.customFaceHex = nil
            } else { theme.customFaceHex = hex }
        })
    }

    private var displayColor: Binding<UInt32> {
        Binding(get: { theme.displayHex }, set: { hex in
            if let display = DigitalDisplay.allCases.first(where: { $0.hex == hex }) {
                theme.display = display; theme.customDisplayHex = nil
            } else { theme.customDisplayHex = hex }
        })
    }
}

struct ClockColorWarning: View {
    let analog: Bool

    var body: some View {
        Text(LocalizedStringKey(analog ? "dino.analog.sameColors" : "dino.digital.sameColors"))
            .modifier(CustomizationText(multiline: true))
            .foregroundStyle(DinoStyle.warning).frame(maxWidth: .infinity)
            .accessibilityIdentifier(analog ? "theme.analog.sameColors" : "theme.digital.sameColors")
    }
}

struct ClockRestoreStyleButton: View {
    @Binding var theme: ClockTheme
    let analog: Bool

    var body: some View {
        Button {
            if analog { theme.resetAnalog() } else { theme.resetDigital() }
        } label: {
            Label("dino.clock.restoreStyle", systemImage: "arrow.counterclockwise")
                .modifier(CustomizationText()).frame(maxWidth: .infinity, minHeight: 44)
        }.buttonStyle(.plain).foregroundStyle(DinoStyle.deepGreen)
            .accessibilityIdentifier(analog ? "theme.resetAnalogStyle" : "theme.resetDigitalStyle")
    }
}

struct MyClocksView: View {
    @ObservedObject private var language = LanguageManager.shared
    @EnvironmentObject private var player: DinoPlayer
    @Environment(\.dismiss) private var dismiss
    @State private var theme = ClockTheme.standard
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                ClockCustomizer(theme: $theme)
                    .padding(20).modifier(CustomizationWidth())
            }.accessibilityIdentifier("theme.options.both").clipped()
            Button("dino.done") {
                player.completeClockCustomization(theme: theme)
                dismiss()
            }.buttonStyle(DinoButtonStyle(customization: true)).accessibilityIdentifier("theme.done")
                .padding(16).modifier(CustomizationWidth(footer: true))
        }
        .background(JungleBackground(quiet: true))
        .modifier(CustomizationTypography(optionsInset: 80))
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { theme = player.profile.clockTheme }
        .onChange(of: theme) { _, updated in
            player.setTheme(updated)
        }
        .onDisappear { player.completeClockCustomization(theme: theme) }
    }
}
