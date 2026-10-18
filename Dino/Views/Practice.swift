import SwiftUI

struct DinoPracticeView: View {
    @EnvironmentObject private var player: DinoPlayer
    @EnvironmentObject private var settings: DinoSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dinoHighContrast) private var highContrast
    @State private var session: DinoSession?

    private var configuration: DinoPracticeConfiguration {
        DinoPracticeConfiguration(time: settings.practiceTime, order: settings.practiceOrder)
    }

    var body: some View {
        GeometryReader { geometry in
            options(spacious: geometry.size.width >= 650)
        }
    }

    private func options(spacious: Bool) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 14) {
                    Text("dino.practice.time").font(.system(size: spacious ? 25 : 20, weight: .bold, design: .rounded)).frame(maxWidth: .infinity)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(DinoPracticeTime.allCases, id: \.self) { time in
                            timeChoice(time, spacious: spacious)
                        }
                    }
                }.padding(spacious ? 20 : 14).background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 28))
                LazyVStack(spacing: 10) {
                    Text("dino.practice.questionType").font(.system(size: spacious ? 25 : 20, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity).padding(.bottom, 6)
                    ForEach(Array(DinoPracticeQuestion.allCases.enumerated()), id: \.element) { index, type in
                        choice(title: type.titleKey, symbol: type.recipe.kind.symbol, number: index + 1,
                               order: .specific(type), identifier: "practice.type.\(type.rawValue)",
                               record: player.practiceRecord(time: configuration.time, question: type).bestStreak, spacious: spacious)
                    }
                    Divider().padding(.vertical, 4)
                    choice(title: "dino.practice.ascending", symbol: "arrow.up.right", order: .ascending,
                           identifier: "practice.order.ascending",
                           record: player.practiceRecord(time: configuration.time, order: .ascending).bestStreak, spacious: spacious)
                    choice(title: "dino.practice.mix", symbol: "shuffle", order: .mix, identifier: "practice.order.mix",
                           record: player.practiceRecord(time: configuration.time, order: .mix).bestStreak, spacious: spacious)
                }.padding(16).background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 28))
            }.padding(spacious ? 24 : 16).padding(.top, 12).frame(maxWidth: 800).frame(maxWidth: .infinity)
        }.accessibilityIdentifier("practice.options")
            .background(JungleBackground(quiet: true)).foregroundStyle(DinoStyle.ink)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Button {
                        session = DinoSession(level: configuration.level, player: player, practice: configuration,
                                              language: LanguageManager.shared.effective.code,
                                              answerFeedback: { [settings] correct in
                            DinoAnswerFeedback.shared.play(correct: correct, sound: settings.soundEffectsEnabled, vibration: settings.hapticsEnabled)
                        })
                    } label: { Label("dino.practice.start", systemImage: "play.fill") }
                        .buttonStyle(DinoButtonStyle(compact: true)).accessibilityIdentifier("practice.start")
                    Button("dino.practice.backToLevels") { dismiss() }
                        .buttonStyle(DinoSecondaryButtonStyle()).accessibilityIdentifier("practice.close")
                }.padding(spacious ? 24 : 16).frame(maxWidth: 760).frame(maxWidth: .infinity)
                    .background(DinoStyle.paper.opacity(0.97))
            }
            .fullScreenCover(item: $session) { active in
                DinoPracticeGame(session: active, exit: { session = nil }).gameEnvironment()
            }
    }

    private func timeChoice(_ time: DinoPracticeTime, spacious: Bool) -> some View {
        let selected = configuration.time == time
        return Button { settings.practiceTime = time } label: {
            VStack(spacing: 8) {
                // Static previews draw in one canvas instead of laying out 60 tick views per clock.
                PracticeClockPreview(time: time.previewTime, theme: player.profile.clockTheme)
                    .aspectRatio(1, contentMode: .fit).frame(maxWidth: spacious ? 122 : 90)
                    .accessibilityHidden(true)
                Text(LocalizedStringKey(time.titleKey))
                    .font(.system(size: spacious ? 17 : 13, weight: .bold, design: .rounded))
                    .lineLimit(2).minimumScaleFactor(0.85).frame(height: 30)
            }.padding(.horizontal, 6).padding(.vertical, 10).frame(maxWidth: .infinity)
                .background(selected ? DinoStyle.green.opacity(0.22) : .white.opacity(0.5), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(selected ? DinoStyle.deepGreen : highContrast ? DinoStyle.ink : .white, lineWidth: 2))
        }.buttonStyle(.plain)
            .accessibilityIdentifier("practice.time.\(time.rawValue)")
    }

    private func choice(title: String, symbol: String, number: Int? = nil, order: DinoPracticeOrder,
                        identifier: String, record: Int? = nil, spacious: Bool = false) -> some View {
        let selected = configuration.order == order
        let tint = Color(dinoHex: [0xEDF5E5, 0xEAF3F8, 0xF4EFF8, 0xFBF2E3][((number ?? 1) - 1) % 4])
        return Button {
            settings.practiceOrder = order
        } label: {
            HStack(spacing: 10) {
                if let number {
                    Text(verbatim: "\(number)").font(.system(size: 14, weight: .heavy, design: .rounded))
                        .frame(width: 32, height: 32).background(DinoStyle.green.opacity(0.16), in: Circle())
                } else {
                    Image(systemName: symbol).frame(width: 32, height: 32)
                }
                Text(LocalizedStringKey(title)).font(.system(size: spacious ? 18 : 15, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if let record {
                    Label { Text(verbatim: "\(record)").monospacedDigit() } icon: { Image(systemName: "trophy.fill") }
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(highContrast ? DinoStyle.ink : Color(dinoHex: 0x92702E))
                        .fixedSize().accessibilityIdentifier("\(identifier).record")
                }
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22)).foregroundStyle(selected ? DinoStyle.deepGreen : DinoStyle.muted)
            }.frame(minHeight: spacious ? 52 : 44).padding(.horizontal, 12).padding(.vertical, 8)
                .background(selected ? DinoStyle.green.opacity(0.20) : tint, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(selected ? DinoStyle.deepGreen : highContrast ? DinoStyle.ink.opacity(0.6) : .clear,
                            lineWidth: selected || highContrast ? 1.5 : 0))
        }.buttonStyle(.plain)
            .accessibilityIdentifier(identifier)
    }

}

private struct DinoPracticeGame: View {
    @ObservedObject var session: DinoSession
    let exit: () -> Void
    var body: some View {
        DinoGameView(session: session, onExit: exit, onResult: { _ in })
            .overlayPreferenceValue(DinoCompanionPreference.self) { anchors in
                GeometryReader { geometry in
                    DinoCompanionLayer(destination: anchors[.game].map { geometry[$0] },
                                       clip: session.hasFeedback ? (session.correctFeedback ? .thumbsUp : .wrongAnswer) : .idle,
                                       isResult: false)
                }.allowsHitTesting(false)
            }.preferredColorScheme(.light)
    }
}
