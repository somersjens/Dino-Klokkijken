import SwiftUI

struct DinoPracticeView: View {
    @EnvironmentObject private var player: DinoPlayer
    @EnvironmentObject private var settings: DinoSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dinoHighContrast) private var highContrast
    @State private var session: DinoSession?
    @State private var revealedInitialQuestion = false
    var initialQuestion: DinoPracticeQuestion? = nil

    private var configuration: DinoPracticeConfiguration {
        DinoPracticeConfiguration(time: settings.practiceTime, order: settings.practiceOrder)
    }

    var body: some View {
        GeometryReader { geometry in
            let landscape = geometry.size.width > geometry.size.height
            let layout = PracticeLayout(width: landscape ? geometry.size.width * 0.52 : geometry.size.width,
                                        compact: landscape && geometry.size.height < 500)
            options(layout: layout, size: geometry.size, landscape: landscape)
        }
    }

    private func options(layout: PracticeLayout, size: CGSize, landscape: Bool) -> some View {
        ScrollViewReader { proxy in
            Group {
                if landscape {
                    let leftWidth = min(400, (size.width - 40) * 0.44)
                    HStack(spacing: 16) {
                        DinoQuestionContext(maxHeight: max(1, size.height - 24)) {
                            VStack(spacing: 12) {
                                timeGrid(layout: layout)
                                practiceActions(layout: layout, compact: true)
                            }.frame(width: leftWidth)
                        }.frame(width: leftWidth)
                        ScrollView { questionTypes(layout: layout).padding(.vertical, 4) }
                            .bouncesOnlyWhenNeeded()
                            .accessibilityIdentifier("practice.options")
                    }.padding(12)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20 * layout.scale) {
                            timeGrid(layout: layout)
                            questionTypes(layout: layout)
                        }.padding(layout.margin).padding(.top, 12)
                            .frame(maxWidth: PracticeLayout.maximumWidth).frame(maxWidth: .infinity)
                    }
                    .accessibilityIdentifier("practice.options")
                    .safeAreaInset(edge: .bottom) {
                        practiceActions(layout: layout, compact: false)
                            .padding(layout.margin).frame(maxWidth: PracticeLayout.maximumWidth).frame(maxWidth: .infinity)
                            .background(DinoStyle.paper.opacity(0.97))
                    }
                }
            }
            .background(JungleBackground(quiet: true)).foregroundStyle(DinoStyle.ink)
            .fullScreenCover(item: $session) { active in
                DinoPracticeGame(session: active, exit: { session = nil }).gameEnvironment()
            }
            .task {
                guard let initialQuestion, !revealedInitialQuestion else { return }
                revealedInitialQuestion = true
                await Task.yield()
                proxy.scrollTo("practice.type.\(initialQuestion.rawValue)", anchor: .center)
            }
            .task(id: player.profile.dinoAppearance ?? .standard) {
                _ = await DinoSpriteLoader.shared.answerImages(for: player.profile.dinoAppearance ?? .standard)
            }
        }
    }

    private func timeGrid(layout: PracticeLayout) -> some View {
        VStack(spacing: layout.compact ? 8 : 14 * layout.scale) {
            Text("dino.practice.time")
                .font(.system(size: layout.compact ? 17 : 20 * layout.scale, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: layout.compact ? 6 : 10 * layout.scale), count: 3),
                      spacing: layout.compact ? 6 : 10 * layout.scale) {
                ForEach(DinoPracticeTime.allCases, id: \.self) { time in timeChoice(time, layout: layout) }
            }
        }
        .padding(layout.compact ? 8 : 14 * layout.scale)
        .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 28))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("practice.timeGrid")
    }

    private func questionTypes(layout: PracticeLayout) -> some View {
        LazyVStack(spacing: 10 * layout.scale) {
            Text("dino.practice.questionType").font(.system(size: 20 * layout.scale, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity).padding(.bottom, 6 * layout.scale)
            ForEach(DinoPracticeQuestion.allCases, id: \.self) { type in
                choice(title: type.titleKey, symbol: type.recipe.kind.symbol, number: type.number,
                       order: .specific(type), identifier: "practice.type.\(type.rawValue)",
                       record: player.practiceRecord(time: configuration.time, question: type).bestStreak, layout: layout)
                    .id("practice.type.\(type.rawValue)")
            }
            Divider().padding(.vertical, 4 * layout.scale)
            choice(title: "dino.practice.ascending", symbol: "arrow.up.right", order: .ascending,
                   identifier: "practice.order.ascending",
                   record: player.practiceRecord(time: configuration.time, order: .ascending).bestStreak, layout: layout)
            choice(title: "dino.practice.mix", symbol: "shuffle", order: .mix, identifier: "practice.order.mix",
                   record: player.practiceRecord(time: configuration.time, order: .mix).bestStreak, layout: layout)
        }.padding(16 * layout.scale).background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 28))
    }

    private func practiceActions(layout: PracticeLayout, compact: Bool) -> some View {
        VStack(spacing: compact ? 8 : 12 * layout.scale) {
            Button {
                session = DinoSession(level: configuration.level, player: player, practice: configuration,
                                      language: LanguageManager.shared.effective.code,
                                      dayPartSchedule: settings.dayPartSchedule,
                                      answerFeedback: { [settings] correct in
                    DinoAnswerFeedback.shared.play(correct: correct, sound: settings.soundEffectsEnabled,
                                                   vibration: settings.hapticsEnabled)
                })
            } label: {
                Label("dino.practice.start", systemImage: "play.fill")
                    .font(.system(size: 17 * layout.scale, weight: .bold, design: .rounded))
                    .frame(minHeight: 48 * layout.scale)
            }.buttonStyle(DinoButtonStyle(compact: true)).accessibilityIdentifier("practice.start")
            Button { dismiss() } label: {
                Label("dino.practice.backToLevels", systemImage: "map.fill")
                    .font(.system(size: compact ? 15 : 17 * layout.scale, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.85)
                    .padding(.vertical, compact ? 4 : 8)
                    .frame(minHeight: 52 * layout.scale)
            }.buttonStyle(DinoSecondaryButtonStyle()).accessibilityIdentifier("practice.close")
        }
    }

    private func timeChoice(_ time: DinoPracticeTime, layout: PracticeLayout) -> some View {
        let selected = configuration.time == time
        return Button { settings.practiceTime = time } label: {
            VStack(spacing: layout.compact ? 4 : 8 * layout.scale) {
                // Static previews draw in one canvas instead of laying out 60 tick views per clock.
                PracticeClockPreview(time: time.previewTime, theme: player.profile.clockTheme)
                    .aspectRatio(1, contentMode: .fit).frame(maxWidth: layout.compact ? 50 : 90 * layout.scale)
                    .accessibilityHidden(true)
                Text(LocalizedStringKey(time.titleKey))
                    .font(.system(size: layout.compact ? 12 : 13 * layout.scale, weight: .bold, design: .rounded))
                    .lineLimit(2).minimumScaleFactor(0.85).frame(minHeight: layout.compact ? 24 : 30 * layout.scale)
            }.padding(.horizontal, 6 * layout.scale).padding(.vertical, layout.compact ? 4 : 10 * layout.scale).frame(maxWidth: .infinity)
                .background(selected ? DinoStyle.green.opacity(0.22) : .white.opacity(0.5), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(selected ? DinoStyle.deepGreen : highContrast ? DinoStyle.ink : .white, lineWidth: 2))
        }.buttonStyle(DinoPlainButtonStyle())
            .accessibilityIdentifier("practice.time.\(time.rawValue)")
            .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func choice(title: String, symbol: String, number: Int? = nil, order: DinoPracticeOrder,
                        identifier: String, record: Int? = nil, layout: PracticeLayout) -> some View {
        let selected = configuration.order == order
        let tint = Color(dinoHex: [0xEDF5E5, 0xEAF3F8, 0xF4EFF8, 0xFBF2E3][((number ?? 1) - 1) % 4])
        return Button {
            settings.practiceOrder = order
        } label: {
            HStack(spacing: 10 * layout.scale) {
                if let number {
                    Text(verbatim: "\(number)").font(.system(size: 14 * layout.scale, weight: .heavy, design: .rounded))
                        .frame(width: 32 * layout.scale, height: 32 * layout.scale).background(DinoStyle.green.opacity(0.16), in: Circle())
                } else {
                    Image(systemName: symbol).font(.system(size: 18 * layout.scale, weight: .semibold)).frame(width: 32 * layout.scale, height: 32 * layout.scale)
                }
                Text(LocalizedStringKey(title)).font(.system(size: 15 * layout.scale, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if let record {
                    Label { Text(verbatim: "\(record)").monospacedDigit() } icon: { Image(systemName: "trophy.fill") }
                        .font(.system(size: 13 * layout.scale, weight: .semibold, design: .rounded))
                        .foregroundStyle(highContrast ? DinoStyle.ink : Color(dinoHex: 0x92702E))
                        .fixedSize().accessibilityIdentifier("\(identifier).record")
                }
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22 * layout.scale)).foregroundStyle(selected ? DinoStyle.deepGreen : DinoStyle.muted)
            }.frame(minHeight: 44 * layout.scale).padding(.horizontal, 12 * layout.scale).padding(.vertical, 8 * layout.scale)
                .background(selected ? DinoStyle.green.opacity(0.20) : tint, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(selected ? DinoStyle.deepGreen : highContrast ? DinoStyle.ink.opacity(0.6) : .clear,
                            lineWidth: selected || highContrast ? 1.5 : 0))
        }.buttonStyle(DinoPlainButtonStyle())
            .accessibilityIdentifier(identifier)
            .accessibilityAddTraits(selected ? .isSelected : [])
    }

}

/// Scale from the actual sheet width so rotation and Split View use the same proportions.
private struct PracticeLayout {
    static let maximumWidth: CGFloat = 1_000
    let scale: CGFloat
    var compact = false
    var margin: CGFloat { 16 * scale }

    init(width: CGFloat, compact: Bool = false) {
        self.compact = compact
        let available = min(width, Self.maximumWidth)
        scale = compact ? 1 : 1 + min(1, max(0, (available - 400) / 500)) * 0.55
    }
}

private struct DinoPracticeGame: View {
    @ObservedObject var session: DinoSession
    let exit: () -> Void
    var body: some View {
        DinoGameView(session: session, onExit: exit, onResult: { _ in })
            .overlayPreferenceValue(DinoCompanionPreference.self) { anchors in
                GeometryReader { geometry in
                    DinoCompanionLayer(destination: anchors[.game].map { geometry[$0.bounds] },
                                       clip: session.hasFeedback ? (session.correctFeedback ? .thumbsUp : .wrongAnswer) : .idle,
                                       isResult: false, worldID: session.level.worldID,
                                       compactPortrait: geometry.size.height < 430,
                                       reactionID: session.rejectedResponses.count,
                                       dimmingOpacity: anchors[.game]?.dimmingOpacity ?? 0)
                }.allowsHitTesting(false)
            }.lightPalette()
    }
}
