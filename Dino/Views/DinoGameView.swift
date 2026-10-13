import SwiftUI

struct DinoGameView: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @EnvironmentObject private var player: DinoPlayer
    @StateObject var session: DinoSession
    let onExit: () -> Void
    let onResult: (DinoLevelResult) -> Void
    @State private var confirmExit = false
    @State private var personalizing = false

    var body: some View {
        GeometryReader { g in
            let width = min(520, max(280, g.size.width - 36))
            let clockSize = min(210, width * 0.54, max(160, g.size.height * 0.28))
            ZStack {
                JungleBackground(quiet: true)
                VStack(spacing: 0) {
                    if session.practice != nil { practiceHeader }
                    else {
                        AdventureHeader(personalizerChanged: { personalizing = $0 }, level: session.level.id,
                                        stars: player.profile.totalStars, compact: g.size.height < 430,
                                        questionCounter: "\(min(session.attempt.index + 1, session.level.questionCount))/\(session.level.questionCount)",
                                        helpEnabled: !session.hasFeedback,
                                        help: showExample, action: pause)
                    }
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 18) {
                                if session.practice != nil { questionProgress.id("question.progress") }
                                if session.level.isBoss { crystals }
                                Text(LocalizedStringKey(session.instructionKey))
                                    .font(.system(size: 21, weight: .heavy, design: .rounded))
                                    .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                                    .accessibilityIdentifier("question.title")
                                    .id("question.top")
                                QuestionRenderer(session: session, theme: player.profile.clockTheme, width: width, clockSize: clockSize)
                                    .id(session.question.id)
                            }.padding(.vertical, 20).frame(width: width).frame(maxWidth: .infinity)
                        }
                        .onChange(of: session.hasFeedback) { _, visible in
                            if visible && !session.correctFeedback {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo("question.answers", anchor: .center)
                                }
                            }
                        }
                        .onChange(of: session.question.id) { _, _ in
                            proxy.scrollTo(session.practice == nil ? "question.top" : "question.progress", anchor: .top)
                        }
                    }
                }.disabled(confirmExit || session.demonstration != nil).accessibilityHidden(confirmExit || session.demonstration != nil)
                if let kind = session.demonstration {
                    Color.black.opacity(0.28).ignoresSafeArea()
                    ScrollView {
                        InteractionDemonstration(kind: kind, theme: player.profile.clockTheme, minuteStep: session.minuteStep,
                                                 practiceTime: session.practice?.time ?? .whole,
                                                 worldMinutes: session.practice == nil ? session.level.allowedMinutes : nil,
                                                 width: min(380, max(230, g.size.width - 80)), done: session.dismissDemonstration)
                            .padding(16)
                    }.frame(maxWidth: 480, maxHeight: g.size.height - 24)
                        .transition(.scale.combined(with: .opacity))
                }
                if confirmExit {
                    Color.black.opacity(0.28).ignoresSafeArea()
                    ScrollView {
                        exitCard(compact: g.size.height < 430).padding(16)
                    }.scrollBounceBehavior(.basedOnSize)
                        .frame(maxWidth: 440, maxHeight: min(520, g.size.height - 16))
                        .transition(.scale(scale: 0.94).combined(with: .opacity))
                }
            }
            .safeAreaInset(edge: .bottom) {
                if session.hasFeedback && !session.correctFeedback {
                    Button { session.advance() } label: {
                        Label("dino.next", systemImage: "arrow.right")
                    }.buttonStyle(DinoButtonStyle(compact: true))
                        .accessibilityIdentifier("question.next")
                        .padding(12).frame(maxWidth: 520).frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .disabled(confirmExit).accessibilityHidden(confirmExit)
                }
            }
        }.foregroundStyle(DinoStyle.ink)
            .transformPreference(DinoCompanionPreference.self) { anchors in
                if confirmExit || session.demonstration != nil { anchors = [:] }
            }
            .task(id: session.hasFeedback && session.correctFeedback && !confirmExit && !personalizing) {
                guard session.hasFeedback && session.correctFeedback && !confirmExit && !personalizing else { return }
                do { try await Task.sleep(for: .seconds(DinoAnimation.correctAnswerDelay)) } catch { return }
                guard !Task.isCancelled else { return }
                session.advance()
            }
            .onChange(of: session.result != nil) { _, hasResult in
                if hasResult, let result = session.result { onResult(result) }
            }
            .animation(.easeOut(duration: 0.18), value: confirmExit)
    }

    private func exitCard(compact: Bool) -> some View {
        VStack(spacing: compact ? 12 : 20) {
            if compact {
                Label("dino.exitTitle", systemImage: "door.left.hand.open")
                    .font(.system(size: 22, weight: .heavy, design: .rounded)).multilineTextAlignment(.center)
            } else {
                Image(systemName: "door.left.hand.open").font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(DinoStyle.deepGreen).frame(width: 68, height: 68)
                    .background(DinoStyle.green.opacity(0.18), in: RoundedRectangle(cornerRadius: 23))
                Text("dino.exitTitle").font(.system(size: 25, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
            }
            Text(LocalizedStringKey(session.practice == nil ? "dino.exitMessage" : "dino.practice.exitMessage")).font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted).multilineTextAlignment(.center)
            Button { confirmExit = false } label: { Label("dino.keepPlaying", systemImage: "play.fill") }
                .buttonStyle(DinoButtonStyle(compact: compact)).accessibilityIdentifier("game.exit.cancel")
            Button(role: .destructive, action: onExit) { Label("dino.exit", systemImage: "rectangle.portrait.and.arrow.right") }
                .buttonStyle(DinoButtonStyle(color: Color(dinoHex: 0xC74343), compact: true))
                .accessibilityIdentifier("game.exit.confirm")
        }.padding(4).dinoCard().accessibilityAddTraits(.isModal)
    }

    @ViewBuilder private var questionProgress: some View {
        if let practice = session.practice {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(LocalizedStringKey(practice.time.titleKey)).font(.system(size: 13, weight: .bold, design: .rounded))
                    Spacer()
                    Text(verbatim: "\(L("dino.practice.questionNumber")) \(session.question.id + 1)")
                        .font(.system(size: 14, weight: .bold, design: .rounded)).monospacedDigit()
                        .accessibilityIdentifier("practice.questionNumber")
                }
                Label("\(session.practiceCorrect) / \(session.practiceAnswered)", systemImage: "checkmark.circle.fill")
                    .font(.footnote.bold()).foregroundStyle(DinoStyle.deepGreen)
                    .accessibilityLabel(Text(verbatim: "\(L("dino.practice.correct")): \(session.practiceCorrect) / \(session.practiceAnswered)"))
            }.padding(12).background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 22))
        }
    }

    private var practiceHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "book.fill").font(.title2).foregroundStyle(DinoStyle.deepGreen)
                .frame(width: 48, height: 48).background(DinoStyle.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
            Text("dino.practice.title").font(.system(size: 22, weight: .heavy, design: .rounded))
            Spacer()
            DinoIconButton(icon: "questionmark", labelKey: "dino.example", action: showExample)
                .accessibilityIdentifier("question.example").disabled(session.hasFeedback)
            DinoIconButton(icon: "pause.fill", labelKey: "dino.pause", action: pause)
                .accessibilityIdentifier("header.pause")
        }.padding(.horizontal, 18).padding(.vertical, 12)
            .frame(maxWidth: 520).frame(maxWidth: .infinity)
            .background(DinoStyle.paper.ignoresSafeArea(edges: .top))
    }

    private func showExample() { session.demonstration = session.question.kind }

    private func pause() {
        if session.canExitWithoutConfirmation { onExit() }
        else { confirmExit = true }
    }

    private var crystals: some View {
        HStack(spacing: 8) {
            ForEach(0..<10, id: \.self) { index in
                let answered = index < session.attempt.answers.count
                let good = answered && session.attempt.answers[index]
                Image(systemName: "diamond.fill").font(.system(size: 21, weight: .bold))
                    .foregroundStyle(good ? DinoStyle.green : answered ? Color.gray.opacity(0.55) : DinoStyle.ink.opacity(0.12))
                    .scaleEffect(good ? 1.08 : 1)
            }
        }.environment(\.layoutDirection, .leftToRight)
    }


}

struct InteractionDemonstration: View {
    let kind: ClockQuestionKind
    let theme: ClockTheme
    var minuteStep = 60
    var practiceTime: DinoPracticeTime = .whole
    var worldMinutes: [Int]? = nil
    var width: CGFloat = 280
    var done: () -> Void
    @State private var exampleHour = 3
    @State private var exampleMinute = 0
    @State private var adjustingMinutes = false
    var body: some View {
        if kind.isExpanded {
            DinoExpandedDemonstration(kind: kind, time: practiceTime, worldMinutes: worldMinutes,
                                      minuteStep: minuteStep, width: width, theme: theme, done: done)
        } else { originalExample }
    }
    private var originalExample: some View {
        VStack(spacing: 18) {
            Label("dino.example", systemImage: "sparkles").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(DinoStyle.green)
            Text(LocalizedStringKey(minuteStep < 60 && (kind == .setAnalog || kind == .setDigital) ? "dino.practice.\(kind.rawValue)" : kind.instructionKey))
                .font(.system(size: 24, weight: .heavy, design: .rounded)).multilineTextAlignment(.center)
            AnalogClock(time: ClockTime(hour: exampleHour, minute: exampleMinute), theme: theme, size: 170,
                        onHourChange: kind == .setAnalog && !adjustingMinutes ? { exampleHour = $0 } : nil, showHandHints: true,
                        onMinuteChange: kind == .setAnalog && adjustingMinutes ? { exampleMinute = $0 } : nil, minuteStep: minuteStep)
            if kind == .setAnalog && minuteStep < 60 {
                Picker("dino.practice.hand", selection: $adjustingMinutes) {
                    Text("dino.hours").tag(false)
                    Text("dino.minutes").tag(true)
                }.pickerStyle(.segmented).frame(maxWidth: 280)
            }
            Image(systemName: kind == .setAnalog ? "hand.draw.fill" : "arrow.down")
                .font(.system(size: 25, weight: .bold)).foregroundStyle(DinoStyle.green)
            if kind == .setDigital {
                DigitalClockControl(hour: $exampleHour, theme: theme, minute: exampleMinute, fontSize: 30,
                                    onMinuteChange: minuteStep < 60 ? { exampleMinute = $0 } : nil, minuteStep: minuteStep)
            } else { DigitalClock(time: ClockTime(hour: exampleHour, minute: exampleMinute), theme: theme, fontSize: 30) }
            Text(LocalizedStringKey(kind == .setAnalog || kind == .setDigital ? "dino.demoSet" : "dino.demoTap"))
                .font(.system(size: 14, weight: .medium, design: .rounded)).multilineTextAlignment(.center)
            Button(action: done) { Label("dino.ready", systemImage: "checkmark") }
                .buttonStyle(DinoButtonStyle()).accessibilityIdentifier("demo.ready")
        }.dinoCard()
            .background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 28))
            .foregroundStyle(DinoStyle.ink).accessibilityAddTraits(.isModal)
            .onAppear { exampleHour = 3; exampleMinute = worldMinutes?.first ?? (minuteStep < 60 ? minuteStep : 0) }
            .task {
                guard kind == .setAnalog || kind == .setDigital else { return }
                do { try await Task.sleep(for: .milliseconds(650)) } catch { return }
                withAnimation(.easeInOut(duration: 0.8)) { exampleHour = 6 }
            }
    }
}
