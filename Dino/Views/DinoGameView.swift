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
            let width = min(520, g.size.width - 36)
            let clockSize = min(210, width * 0.54, max(160, g.size.height * 0.28))
            ZStack {
                JungleBackground(quiet: true)
                VStack(spacing: 0) {
                    AdventureHeader(personalizerChanged: { personalizing = $0 }, name: player.profile.name, level: session.level.id,
                                    stars: player.profile.totalStars, compact: g.size.height < 430) {
                        confirmExit = true
                    }
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 18) {
                                questionProgress
                                if session.level.isBoss { crystals }
                                Text(LocalizedStringKey(session.question.kind.instructionKey))
                                    .font(.system(size: 21, weight: .heavy, design: .rounded))
                                    .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                                    .accessibilityIdentifier("question.title")
                                    .id("question.top")
                                QuestionRenderer(session: session, theme: player.profile.clockTheme, width: width, clockSize: clockSize)
                                    .id(session.attempt.index)
                            }.padding(.vertical, 20).frame(width: width).frame(maxWidth: .infinity)
                        }
                        .onChange(of: session.hasFeedback) { _, visible in
                            if visible && !session.correctFeedback {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo("question.answers", anchor: .center)
                                }
                            }
                        }
                        .onChange(of: session.attempt.index) { _, _ in
                            proxy.scrollTo("question.top", anchor: .top)
                        }
                    }
                }.disabled(confirmExit).accessibilityHidden(confirmExit)
                if let kind = session.demonstration {
                    Color.black.opacity(0.28).ignoresSafeArea()
                    ScrollView {
                        InteractionDemonstration(kind: kind, theme: player.profile.clockTheme, done: session.dismissDemonstration)
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
                    VStack(spacing: 10) {
                        feedback
                        Button { session.advance() } label: {
                            Label("dino.next", systemImage: "arrow.right")
                        }.buttonStyle(DinoButtonStyle(compact: true))
                            .accessibilityIdentifier("question.next")
                    }.padding(12).frame(maxWidth: 520).frame(maxWidth: .infinity)
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
            Text("dino.exitMessage").font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted).multilineTextAlignment(.center)
            Button { confirmExit = false } label: { Label("dino.keepPlaying", systemImage: "play.fill") }
                .buttonStyle(DinoButtonStyle(compact: compact)).accessibilityIdentifier("game.exit.cancel")
            Button(role: .destructive, action: onExit) { Label("dino.exit", systemImage: "rectangle.portrait.and.arrow.right") }
                .buttonStyle(DinoButtonStyle(color: Color(dinoHex: 0xC74343), compact: true))
                .accessibilityIdentifier("game.exit.confirm")
        }.padding(4).dinoCard().accessibilityAddTraits(.isModal)
    }

    private var questionProgress: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("dino.questionProgress").font(.system(size: 13, weight: .bold, design: .rounded))
                    Spacer()
                    Text(verbatim: "\(min(session.attempt.index + 1, session.level.questionCount))/\(session.level.questionCount)")
                        .font(.system(size: 14, weight: .bold, design: .rounded)).monospacedDigit()
                }
                GeometryReader { g in
                    Capsule().fill(DinoStyle.green.opacity(0.12))
                    Capsule().fill(DinoStyle.green)
                        .frame(width: g.size.width * Double(session.attempt.answers.count) / Double(session.level.questionCount))
                }.frame(height: 8)
            }
            DinoIconButton(icon: "questionmark", labelKey: "dino.example") { session.demonstration = session.question.kind }
                .disabled(session.hasFeedback)
        }.padding(12).background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 22))
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

    private var feedback: some View {
        HStack(spacing: 12) {
            DinoCompanionAnchor(placement: .game, size: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text("dino.correctTime").font(.system(size: 16, weight: .bold, design: .rounded))
                Text(verbatim: session.question.target.digitalText).font(.system(size: 24, weight: .heavy, design: .rounded))
            }
            Spacer(minLength: 0)
        }.foregroundStyle(DinoStyle.ink)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color(dinoHex: 0xFBEDEA), in: RoundedRectangle(cornerRadius: 20))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("question.feedback")
    }
}

struct InteractionDemonstration: View {
    let kind: ClockQuestionKind
    let theme: ClockTheme
    var done: () -> Void
    @State private var exampleHour = 3
    var body: some View {
        VStack(spacing: 18) {
            Label("dino.example", systemImage: "sparkles").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(DinoStyle.green)
            Text(LocalizedStringKey(kind.instructionKey)).font(.system(size: 24, weight: .heavy, design: .rounded)).multilineTextAlignment(.center)
            HStack(alignment: .center, spacing: 14) {
                DinoCharacter(state: .thinking, size: 78)
                AnalogClock(time: ClockTime(hour: exampleHour), theme: theme, size: 150,
                            onHourChange: kind == .setAnalog ? { exampleHour = $0 } : nil, showHandHints: true)
            }
            Image(systemName: kind == .setAnalog ? "hand.draw.fill" : "arrow.down")
                .font(.system(size: 25, weight: .bold)).foregroundStyle(DinoStyle.green)
            if kind == .setDigital { DigitalClockControl(hour: $exampleHour, theme: theme, fontSize: 30) }
            else { DigitalClock(time: ClockTime(hour: exampleHour), theme: theme, fontSize: 30) }
            Text(LocalizedStringKey(kind == .setAnalog || kind == .setDigital ? "dino.demoSet" : "dino.demoTap"))
                .font(.system(size: 14, weight: .medium, design: .rounded)).multilineTextAlignment(.center)
            Button(action: done) { Label("dino.ready", systemImage: "checkmark") }
                .buttonStyle(DinoButtonStyle()).accessibilityIdentifier("demo.ready")
        }.dinoCard().foregroundStyle(DinoStyle.ink)
            .onAppear { exampleHour = 3 }
            .task {
                guard kind == .setAnalog || kind == .setDigital else { return }
                do { try await Task.sleep(for: .milliseconds(650)) } catch { return }
                withAnimation(.easeInOut(duration: 0.8)) { exampleHour = 6 }
            }
    }
}
