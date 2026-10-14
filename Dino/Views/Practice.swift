import SwiftUI

struct DinoPracticeView: View {
    @EnvironmentObject private var player: DinoPlayer
    @EnvironmentObject private var settings: DinoSettings
    @Environment(\.dinoHighContrast) private var highContrast
    @State private var configuration = DinoPracticeConfiguration()
    @State private var session: DinoSession?
    @State private var showsAscendingExplanation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 14) {
                    Text("dino.practice.time").font(.title3.bold()).frame(maxWidth: .infinity)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(DinoPracticeTime.allCases, id: \.self) { time in
                            timeChoice(time)
                        }
                    }
                }.padding(14).background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 28))
                LazyVStack(spacing: 10) {
                    Text("dino.practice.questionType").font(.title3.bold())
                        .frame(maxWidth: .infinity).padding(.bottom, 6)
                    ForEach(Array(DinoPracticeQuestion.allCases.enumerated()), id: \.element) { index, type in
                        choice(title: type.titleKey, symbol: type.recipe.kind.symbol, number: index + 1,
                               order: .specific(type), identifier: "practice.type.\(type.rawValue)",
                               record: player.practiceRecord(time: configuration.time, question: type).bestStreak)
                    }
                    Divider().padding(.vertical, 4)
                    HStack(spacing: 4) {
                        choice(title: "dino.practice.ascending", symbol: "arrow.up.right", order: .ascending,
                               identifier: "practice.order.ascending")
                        Button { showsAscendingExplanation = true } label: {
                            Image(systemName: "info.circle").font(.system(size: 21, weight: .semibold))
                                .frame(width: 44, height: 52)
                        }.buttonStyle(.plain).foregroundStyle(DinoStyle.deepGreen)
                            .accessibilityLabel(Text("dino.practice.ascendingInfo"))
                            .accessibilityIdentifier("practice.ascending.info")
                    }
                    choice(title: "dino.practice.mix", symbol: "shuffle", order: .mix, identifier: "practice.order.mix")
                }.padding(16).background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 28))
                Text("dino.practice.description").font(.subheadline).multilineTextAlignment(.center)
                    .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted).frame(maxWidth: .infinity)
            }.padding(16).frame(maxWidth: 560).frame(maxWidth: .infinity)
        }.accessibilityIdentifier("practice.options")
            .background(JungleBackground(quiet: true)).foregroundStyle(DinoStyle.ink)
            .navigationTitle(Text(verbatim: L("dino.practice.title"))).navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button {
                    session = DinoSession(level: configuration.level, player: player, practice: configuration,
                                          answerFeedback: { [settings] correct in
                        DinoAnswerFeedback.shared.play(correct: correct, sound: settings.soundEffectsEnabled, vibration: settings.hapticsEnabled)
                    })
                } label: { Label("dino.practice.start", systemImage: "play.fill") }
                    .buttonStyle(DinoButtonStyle(compact: true)).accessibilityIdentifier("practice.start")
                    .padding(16).frame(maxWidth: 520).frame(maxWidth: .infinity).background(.ultraThinMaterial)
            }
            .alert("dino.practice.ascending", isPresented: $showsAscendingExplanation) {
                Button("dino.done", role: .cancel) {}
            } message: { Text("dino.practice.ascendingDescription") }
            .fullScreenCover(item: $session) { active in
                DinoPracticeGame(session: active, exit: { session = nil }).gameEnvironment()
            }
    }

    private func timeChoice(_ time: DinoPracticeTime) -> some View {
        let selected = configuration.time == time
        return Button { configuration.time = time } label: {
            VStack(spacing: 8) {
                // Static previews draw in one canvas instead of laying out 60 tick views per clock.
                PracticeClockPreview(time: time.previewTime, theme: player.profile.clockTheme)
                    .aspectRatio(1, contentMode: .fit).frame(maxWidth: 90)
                    .accessibilityHidden(true)
                Text(LocalizedStringKey(time.titleKey))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .lineLimit(2).minimumScaleFactor(0.85).frame(height: 30)
            }.padding(.horizontal, 6).padding(.vertical, 10).frame(maxWidth: .infinity)
                .background(selected ? DinoStyle.green.opacity(0.22) : .white.opacity(0.5), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(selected ? DinoStyle.deepGreen : highContrast ? DinoStyle.ink : .white, lineWidth: 2))
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityLabel(Text(LocalizedStringKey(time.titleKey)))
            .accessibilityIdentifier("practice.time.\(time.rawValue)")
    }

    private func choice(title: String, symbol: String, number: Int? = nil, order: DinoPracticeOrder,
                        identifier: String, record: Int? = nil) -> some View {
        let selected = configuration.order == order
        let tint = Color(dinoHex: [0xEDF5E5, 0xEAF3F8, 0xF4EFF8, 0xFBF2E3][((number ?? 1) - 1) % 4])
        return Button {
            configuration.order = order
            if order == .ascending { showsAscendingExplanation = true }
        } label: {
            HStack(spacing: 10) {
                if let number {
                    Text(verbatim: "\(number)").font(.system(size: 14, weight: .heavy, design: .rounded))
                        .frame(width: 32, height: 32).background(DinoStyle.green.opacity(0.16), in: Circle())
                } else {
                    Image(systemName: symbol).frame(width: 32, height: 32)
                }
                Text(LocalizedStringKey(title)).font(.system(size: 15, weight: .semibold, design: .rounded))
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
            }.frame(minHeight: 44).padding(.horizontal, 12).padding(.vertical, 8)
                .background(selected ? DinoStyle.green.opacity(0.20) : tint, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(selected ? DinoStyle.deepGreen : highContrast ? DinoStyle.ink.opacity(0.6) : .clear,
                            lineWidth: selected || highContrast ? 1.5 : 0))
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityLabel(Text(LocalizedStringKey(title)))
            .accessibilityValue(record.map { "\(L("dino.practice.bestStreak")): \($0)" } ?? "")
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
