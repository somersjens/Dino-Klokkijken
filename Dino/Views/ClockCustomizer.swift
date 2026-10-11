import SwiftUI

struct ClockCustomizer: View {
    @ObservedObject private var language = LanguageManager.shared
    @Binding var theme: ClockTheme
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Label("dino.analog", systemImage: "clock.fill")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                AnalogClock(time: ClockTime(hour: 10, minute: 10), theme: theme, size: 190)
                VStack(alignment: .leading, spacing: 16) {
                    colorChoices(title: "dino.face", selection: $theme.face,
                                 values: ClockFace.allCases, hex: { $0.hex })
                    Picker("dino.hands", selection: $theme.hands) {
                        ForEach(ClockHandStyle.allCases, id: \.self) { style in
                            Text(verbatim: L(key: "dino.hands." + style.rawValue)).tag(style)
                        }
                    }.pickerStyle(.segmented)
                    colorChoices(title: "dino.hourHand", selection: $theme.hourInk,
                                 values: ClockInk.allCases, hex: { $0.hex })
                    colorChoices(title: "dino.minuteHand", selection: $theme.minuteInk,
                                 values: ClockInk.allCases, hex: { $0.hex })
                    colorChoices(title: "dino.rim", selection: $theme.rimInk,
                                 values: ClockInk.allCases, hex: { $0.hex })
                }
            }.dinoCard()

            VStack(spacing: 18) {
                Label("dino.digital", systemImage: "rectangle.fill")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                DigitalClock(time: ClockTime(hour: 10, minute: 10), theme: theme, fontSize: 44)
                colorChoices(title: "dino.display", selection: $theme.display,
                             values: DigitalDisplay.allCases, hex: { $0.hex })
                Picker("dino.numerals", selection: $theme.numerals) {
                    ForEach(DigitalNumerals.allCases, id: \.self) { style in
                        Text(verbatim: L(key: "dino.numerals." + style.rawValue)).tag(style)
                    }
                }.pickerStyle(.segmented)
            }.dinoCard()
        }
        .foregroundStyle(DinoStyle.ink)
    }

    private func colorChoices<T: RawRepresentable & Hashable>(title: String, selection: Binding<T>,
                                                              values: [T], hex: @escaping (T) -> UInt32) -> some View where T.RawValue == String {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(title)).font(.system(size: 14, weight: .semibold, design: .rounded))
            HStack(spacing: 0) {
                ForEach(values, id: \.self) { value in
                    Button { selection.wrappedValue = value } label: {
                        Circle().fill(Color(dinoHex: hex(value)))
                            .overlay(Circle().stroke(DinoStyle.ink.opacity(0.12), lineWidth: 1))
                            .overlay {
                                if selection.wrappedValue == value {
                                    Circle().stroke(DinoStyle.green, lineWidth: 3).padding(-4)
                                    Image(systemName: "checkmark").font(.system(size: 14, weight: .heavy))
                                        .foregroundStyle(hex(value) < 0xAAAAAA ? .white : DinoStyle.ink)
                                }
                            }
                            .frame(width: 34, height: 34).padding(5)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("theme." + title + "." + value.rawValue)
                    .accessibilityLabel(Text(verbatim: L(key: "dino.color." + value.rawValue)))
                    .accessibilityAddTraits(selection.wrappedValue == value ? .isSelected : [])
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MyClocksView: View {
    @ObservedObject private var language = LanguageManager.shared
    @EnvironmentObject private var player: DinoPlayer
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ClockCustomizer(theme: Binding(get: { player.profile.clockTheme }, set: { player.setTheme($0) }))
                Button("dino.standardClock") { player.setTheme(.standard) }.buttonStyle(DinoSecondaryButtonStyle())
            }.padding(20).frame(maxWidth: 520).frame(maxWidth: .infinity)
        }
        .background(JungleBackground(quiet: true))
        .navigationTitle(Text(verbatim: L("dino.myClocks")))
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("dino.done") { dismiss() } } }
    }
}
