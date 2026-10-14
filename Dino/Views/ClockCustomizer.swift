import SwiftUI
import UIKit

enum ClockCustomizerPage {
    case analog, digital, both
}

struct ClockCustomizer: View {
    @ObservedObject private var language = LanguageManager.shared
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Binding var theme: ClockTheme
    var page: ClockCustomizerPage = .both
    var onNavigate: ((Int) -> Void)? = nil
    private var compact: Bool { verticalSizeClass == .compact }
    private var inkSwatches: [(name: String, hex: UInt32)] { ClockInk.allCases.map { ($0.rawValue, $0.hex) } }
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
                let layout = compact ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
                layout {
                    Group {
                        if page == .analog { analogPreview } else { digitalPreview }
                    }.padding(.vertical, compact ? 4 : 12)
                        .frame(maxWidth: compact ? (page == .analog ? 140 : 185) : .infinity)
                    ScrollView {
                        Group {
                            if page == .analog { analogOptions } else { digitalOptions }
                        }.dinoCard(padding: 16)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .frame(maxWidth: 520).frame(maxWidth: .infinity)
                    }.clipped().id(page == .analog ? "analog" : "digital")
                        .accessibilityIdentifier(page == .analog ? "theme.options.analog" : "theme.options.digital")
                }.frame(maxWidth: compact ? 760 : .infinity).frame(maxWidth: .infinity)
            }
        }.foregroundStyle(DinoStyle.ink)
    }

    private var analogPreview: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 10) {
                AnalogClock(time: ClockTime(date: context.date), theme: theme, size: compact ? 100 : 180)
                    .accessibilityIdentifier("theme.analog.preview")
                    .modifier(PersonalizationPreviewNavigation(onNavigate: onNavigate))
                if theme.analogColorsMatch { ClockColorWarning(analog: true) }
            }
        }.padding(.horizontal, 16).frame(maxWidth: 520)
    }

    private var digitalPreview: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 10) {
                DigitalClock(time: ClockTime(date: context.date), theme: theme, fontSize: compact ? 36 : 48)
                    .accessibilityIdentifier("theme.digital.preview")
                    .modifier(PersonalizationPreviewNavigation(onNavigate: onNavigate))
                if theme.digitalColorsMatch { ClockColorWarning(analog: false) }
            }
        }.padding(.horizontal, 16).frame(maxWidth: 520)
    }

    private var analogOptions: some View {
        VStack(spacing: 16) {
            colorChoices(title: "dino.hourHand", color: analogColor(\.customHourHex, preset: \.hourInk), values: inkSwatches)
            Divider()
            colorChoices(title: "dino.minuteHand", color: analogColor(\.customMinuteHex, preset: \.minuteInk), values: inkSwatches)
            Divider()
            colorChoices(title: "dino.face", color: faceColor, values: faceSwatches)
            Divider()
            colorChoices(title: "dino.rim", color: analogColor(\.customRimHex, preset: \.rimInk), values: inkSwatches)
            Divider()
            analogShapeChoices
            Divider()
            styleChoice(title: "dino.hands", selection: $theme.hands, values: ClockHandStyle.allCases,
                        keyPrefix: "dino.hands.", identifier: "theme.hands")
            Divider()
            styleChoice(title: "dino.analogNumerals", selection: $theme.analogNumerals, values: AnalogNumerals.allCases,
                        keyPrefix: "dino.analogNumerals.", identifier: "theme.analogNumerals")
            Divider()
            ClockRestoreColorsButton(theme: $theme, analog: true)
        }
    }

    private var digitalOptions: some View {
        VStack(spacing: 16) {
            colorChoices(title: "dino.digitColor", color: $theme.digitalInkHex, values: displaySwatches)
            Divider()
            colorChoices(title: "dino.display", color: displayColor, values: displaySwatches)
            Divider()
            digitalShapeChoices
            Divider()
            Text("dino.numerals").font(DinoStyle.editorFont).multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            VStack(spacing: 10) {
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(Array(DigitalNumerals.allCases.dropFirst(row * 2).prefix(2)), id: \.self) { style in
                            fontChoice(style)
                        }
                    }
                }
            }
            Divider()
            ClockRestoreColorsButton(theme: $theme, analog: false)
        }
    }

    private func fontChoice(_ style: DigitalNumerals) -> some View {
        Button { theme.numerals = style } label: {
            VStack(spacing: 6) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    DigitalClock(time: ClockTime(date: context.date), theme: fontPreview(style), fontSize: 22)
                }.accessibilityHidden(true)
                Text(verbatim: L(key: "dino.numerals." + style.rawValue)).font(DinoStyle.editorFont)
            }.padding(.vertical, 10).frame(maxWidth: .infinity)
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
        return preview
    }

    private func styleChoice<T: RawRepresentable & Hashable>(title: String, selection: Binding<T>, values: [T],
                                                            keyPrefix: String, identifier: String) -> some View where T.RawValue == String {
        HStack(spacing: 12) {
            Text(LocalizedStringKey(title)).font(DinoStyle.editorFont)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                .accessibilityIdentifier(identifier + ".label")
            HStack(spacing: 3) {
                ForEach(values, id: \.self) { value in
                    Button { selection.wrappedValue = value } label: {
                        Text(verbatim: L(key: keyPrefix + value.rawValue))
                            .font(DinoStyle.editorFont).padding(.horizontal, 8)
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
        }.frame(minHeight: 44)
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

    private var digitalShapeChoices: some View {
        HStack(spacing: 8) {
            ForEach(DigitalClockShape.allCases, id: \.self) { shape in
                shapeChoice(title: "dino.shape." + shape.rawValue, selected: theme.digitalShape == shape,
                            identifier: "theme.digitalShape." + shape.rawValue) { theme.digitalShape = shape } icon: {
                    DigitalClockOutline(shape: shape).stroke(DinoStyle.ink, lineWidth: 2.5).frame(width: 42, height: 26)
                }
            }
        }.accessibilityElement(children: .contain).accessibilityIdentifier("theme.digitalShape")
    }

    private func shapeChoice<Icon: View>(title: String, selected: Bool, identifier: String,
                                         action: @escaping () -> Void, @ViewBuilder icon: () -> Icon) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                icon().frame(height: 30)
                Text(verbatim: L(key: title)).font(DinoStyle.editorFont)
                    .multilineTextAlignment(.center).lineLimit(2).frame(minHeight: 44)
            }.padding(.vertical, 10).frame(maxWidth: .infinity)
                .background(selected ? DinoStyle.green.opacity(0.18) : .clear, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? DinoStyle.deepGreen : DinoStyle.ink.opacity(0.15), lineWidth: selected ? 2 : 1))
        }.buttonStyle(.plain).accessibilityIdentifier(identifier)
            .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func colorChoices(title: String, color: Binding<UInt32>, values: [(name: String, hex: UInt32)]) -> some View {
        VStack(spacing: 6) {
            Text(LocalizedStringKey(title)).font(DinoStyle.editorFont)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                .accessibilityIdentifier("theme." + title + ".label")
            HStack(spacing: 0) {
                ForEach(values, id: \.name) { value in
                    Button { color.wrappedValue = value.hex } label: {
                        Circle().fill(Color(dinoHex: value.hex)).frame(width: 28, height: 28)
                            .overlay(Circle().stroke(DinoStyle.ink.opacity(0.18), lineWidth: 1))
                            .overlay {
                                if color.wrappedValue == value.hex {
                                    Circle().stroke(DinoStyle.deepGreen, lineWidth: 2).padding(-3)
                                    Image(systemName: "checkmark").font(.system(size: 12, weight: .heavy))
                                        .foregroundStyle(Color(dinoHex: ClockColorContrast.markingHex(on: value.hex)))
                                }
                            }.frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .accessibilityIdentifier("theme." + title + "." + value.name)
                        .accessibilityLabel(Text(verbatim: L(key: "dino.color." + value.name)))
                        .accessibilityAddTraits(color.wrappedValue == value.hex ? .isSelected : [])
                }
                ColorPicker(selection: systemColor(color), supportsOpacity: false) { Text("dino.customColor") }
                    .labelsHidden().frame(maxWidth: .infinity, minHeight: 44)
                    .accessibilityLabel(Text(verbatim: L(key: title) + ", " + L("dino.customColor")))
                    .accessibilityIdentifier("theme." + title + ".custom")
            }
        }.frame(maxWidth: .infinity)
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
            .font(DinoStyle.editorFont)
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(DinoStyle.warning).frame(maxWidth: .infinity)
            .accessibilityIdentifier(analog ? "theme.analog.sameColors" : "theme.digital.sameColors")
    }
}

struct ClockRestoreColorsButton: View {
    @Binding var theme: ClockTheme
    let analog: Bool

    var body: some View {
        Button {
            if analog { theme.restoreAnalogColors() } else { theme.restoreDigitalColors() }
        } label: {
            Label("dino.appearance.reset", systemImage: "arrow.counterclockwise")
                .font(DinoStyle.editorFont).frame(maxWidth: .infinity, minHeight: 44)
        }.buttonStyle(.plain).foregroundStyle(DinoStyle.deepGreen)
            .accessibilityIdentifier(analog ? "theme.restoreAnalogColors" : "theme.restoreDigitalColors")
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
                    .padding(20).frame(maxWidth: 520).frame(maxWidth: .infinity)
            }.accessibilityIdentifier("theme.options.both").clipped()
            Button("dino.done") {
                player.completeClockCustomization(theme: theme)
                dismiss()
            }.buttonStyle(DinoButtonStyle()).accessibilityIdentifier("theme.done")
                .padding(16).frame(maxWidth: 540).frame(maxWidth: .infinity)
        }
        .background(JungleBackground(quiet: true))
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { theme = player.profile.clockTheme }
        .onChange(of: theme) { _, updated in
            player.setTheme(updated)
        }
        .onDisappear { player.completeClockCustomization(theme: theme) }
    }
}
