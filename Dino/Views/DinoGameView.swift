import SwiftUI

struct DinoGameView: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @EnvironmentObject private var player: DinoPlayer
    @StateObject var session: DinoSession
    let onExit: () -> Void
    let onResult: (DinoLevelResult) -> Void
    var onCompanionReaction: (DinoAnimation.Clip) -> Void = { _ in }
    @State private var confirmExit = false
    @State private var personalizing = false
    @State private var questionContentHeight: CGFloat = 0
    @State private var questionViewportHeight: CGFloat = 0

    var body: some View {
        GeometryReader { g in
            let width = min(520, max(280, g.size.width - 36))
            let dockHeight: CGFloat = g.size.height < 430 ? 64 : 80
            let companionSize = min(min(160, g.size.width * 0.38, g.size.height * 0.25),
                                    max(56, max(0, questionViewportHeight - questionContentHeight) + dockHeight + g.safeAreaInsets.bottom - 12))
            let clockSize = min(210, width * 0.54, max(160, g.size.height * 0.28))
            ZStack {
                JungleBackground(quiet: true)
                VStack(spacing: 0) {
                    AdventureHeader(personalizerChanged: { personalizing = $0 }, level: session.level.id,
                                        stars: player.profile.totalStars, worldID: session.level.worldID,
                                        compact: g.size.height < 430,
                                        questionCounter: session.practice == nil
                                            ? "\(min(session.attempt.index + 1, session.level.questionCount))/\(session.level.questionCount)"
                                            : DinoPracticeCounter(value: session.practiceQuestionNumber).digits,
                                        practiceStreak: session.practice == nil ? nil : session.practiceStreak,
                                        practiceRecord: session.practiceBestStreak,
                                        practiceQuestionNumber: session.practice == nil ? nil : session.practiceQuestionNumber,
                                        practiceConfiguration: session.practice,
                                        helpEnabled: !session.hasFeedback,
                                        help: showExample, action: pause)
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 18) {
                                if session.level.isBoss { crystals }
                                DinoQuestionTitle(question: session.question, instructionKey: session.instructionKey)
                                    .accessibilityIdentifier("question.title")
                                    .id("question.top")
                                QuestionRenderer(session: session, theme: player.profile.clockTheme, width: width, clockSize: clockSize)
                                    .id(session.question.id)
                            }.padding(.vertical, 20).frame(width: width).frame(maxWidth: .infinity)
                                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { questionContentHeight = $0 }
                        }
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { questionViewportHeight = $0 }
                        .onChange(of: session.hasFeedback) { _, visible in
                            if visible && !session.correctFeedback {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo("question.answers", anchor: .center)
                                }
                            }
                        }
                        .onChange(of: session.question.id) { _, _ in
                            proxy.scrollTo("question.top", anchor: .top)
                        }
                    }
                    companionDock(height: dockHeight, size: companionSize)
                }.disabled(confirmExit || session.demonstration != nil).accessibilityHidden(confirmExit || session.demonstration != nil)
                if let kind = session.demonstration {
                    Color.black.opacity(0.28).ignoresSafeArea()
                    ScrollView {
                        InteractionDemonstration(kind: kind, theme: player.profile.clockTheme, minuteStep: session.minuteStep,
                                                 practiceTime: session.practice?.time ?? .whole,
                                                 worldMinutes: session.practice == nil ? session.level.allowedMinutes : nil,
                                                 digitalAdjustingMinutes: session.adjustingDigitalMinutes,
                                                 width: min(380, max(230, g.size.width - 80)), done: session.dismissDemonstration)
                            .padding(16)
                    }.scrollBounceBehavior(.basedOnSize)
                        .defaultScrollAnchor(.center, for: .alignment)
                        .frame(maxWidth: 480, maxHeight: g.size.height - 24)
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
            .overlay(alignment: .bottomTrailing) {
                DinoCompanionAnchor(placement: .game, size: companionSize)
                    .padding(.trailing, 8)
                    .offset(y: g.safeAreaInsets.bottom - 6)
            }

        }.foregroundStyle(DinoStyle.ink)
            .transformPreference(DinoCompanionPreference.self) { anchors in
                if confirmExit || session.demonstration != nil { anchors = [:] }
            }
            .task(id: session.shouldAutoAdvance && !confirmExit && !personalizing) {
                guard session.shouldAutoAdvance && !confirmExit && !personalizing else { return }
                do { try await Task.sleep(for: .seconds(DinoAnimation.correctAnswerDelay)) } catch { return }
                guard !Task.isCancelled else { return }
                session.advance()
            }
            .onChange(of: session.hasFeedback ? (session.correctFeedback ? DinoAnimation.Clip.thumbsUp : .wrongAnswer) : .idle, initial: true) { _, reaction in
                onCompanionReaction(reaction)
            }
            .onChange(of: session.result != nil) { _, hasResult in
                if hasResult, let result = session.result { onResult(result) }
            }
            .animation(.easeOut(duration: 0.18), value: confirmExit)
    }

    private func companionDock(height: CGFloat, size: CGFloat) -> some View {
        // Reserve the same small area before and after answering. An explicit
        // VStack row also clips scrolling answers above the standing companion.
        Color.clear.frame(height: height)
            .overlay {
                if session.hasFeedback && !session.shouldAutoAdvance {
                    HStack(spacing: 8) {
                        Button {
                            if session.canRetry { session.showAnswer() }
                            else { session.advance() }
                        } label: {
                            Label(LocalizedStringKey(session.canRetry ? "dino.showAnswer" : "dino.next"), systemImage: session.canRetry ? "eye" : "arrow.right")
                        }.buttonStyle(DinoButtonStyle(compact: true))
                            .accessibilityIdentifier(session.canRetry ? "question.showAnswer" : "question.next")
                        Color.clear.frame(width: size)
                    }.padding(.horizontal, 12).frame(maxWidth: 700).frame(maxWidth: .infinity)
                }
            }
            .background {
                if session.hasFeedback && !session.shouldAutoAdvance {
                    Rectangle().fill(.ultraThinMaterial).ignoresSafeArea(edges: .bottom)
                }
            }
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
    var digitalAdjustingMinutes = false
    var width: CGFloat = 280
    var done: () -> Void
    @State private var exampleHour = 3
    @State private var exampleMinute = 0
    @State private var exampleIndex = 0
    @State private var adjustingMinutes = false
    @State private var matchingSelections: [Int: ClockTime] = [:]
    private var minutes: [Int] { worldMinutes ?? practiceTime.minutes }
    private var exampleTime: ClockTime { ClockTime(hour: exampleHour, minute: exampleMinute) }
    private var matchingQuestion: ClockQuestion {
        let times = (0..<3).map { DinoDemonstrationExamples.time(index: exampleIndex + $0 + 1, minutes: minutes) }
        return ClockQuestion(id: exampleIndex, kind: .match, target: times[0], options: [times[2], times[0], times[1]],
                             activity: nil, companionClocks: Array(times.dropFirst()), relatedTimes: times, answer: .pairs(times))
    }
    var body: some View {
        if kind.isExpanded {
            DinoExpandedDemonstration(kind: kind, time: practiceTime, worldMinutes: worldMinutes,
                                      minuteStep: minuteStep, width: width, theme: theme, done: done)
        } else { originalExample }
    }
    private var originalExample: some View {
        VStack(spacing: 14) {
            Label("dino.example", systemImage: "sparkles").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(DinoStyle.green)
            Text(LocalizedStringKey(minuteStep < 60 && (kind == .setAnalog || kind == .setDigital) ? "dino.practice.\(kind.rawValue)" : kind.instructionKey))
                .font(.system(size: 24, weight: .heavy, design: .rounded)).multilineTextAlignment(.center)
            if kind == .activity {
                let activity = DinoDemonstrationExamples.activity(index: exampleIndex)
                Label(LocalizedStringKey(activity.titleKey), systemImage: activity.symbol)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            if kind == .match {
                ClockMatchingBoard(times: matchingQuestion.relatedTimes, options: matchingQuestion.options,
                                   selections: $matchingSelections, theme: theme, width: width, isDemonstration: true)
                    .id(exampleIndex)
            } else {
                AnalogClock(time: exampleTime, theme: theme, size: min(170, width / 1.48),
                            onHourChange: kind == .setAnalog && !adjustingMinutes ? { exampleHour = $0 } : nil, showHandHints: true,
                            onMinuteChange: kind == .setAnalog && adjustingMinutes ? { exampleHour = $0.hour; exampleMinute = $0.minute } : nil, minuteStep: minuteStep)
                    .accessibilityIdentifier("demo.analog")
                if kind == .setAnalog && minuteStep < 60 {
                    Picker("dino.practice.hand", selection: $adjustingMinutes) {
                        Text("dino.hours").tag(false)
                        Text("dino.minutes").tag(true)
                    }.pickerStyle(.segmented).frame(maxWidth: 280)
                }
                if kind == .setDigital {
                    DigitalClockControl(hour: $exampleHour, adjustingMinutes: $adjustingMinutes,
                                        theme: theme, minute: exampleMinute, fontSize: min(30, width * 0.095),
                                        onMinuteChange: { exampleMinute = $0 }, minuteStep: minuteStep,
                                        valueIdentifier: "demo.digital", showHandHints: true)
                    Text("dino.clock.switchField").font(.system(size: 14, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                } else {
                    DigitalClock(time: ClockTime(hour: exampleHour, minute: exampleMinute), theme: theme, fontSize: 30, showHandHints: true)
                        .accessibilityIdentifier("demo.digital")
                }
            }
            DinoDemonstrationActions(done: done, another: nextExample)
        }.frame(width: width).dinoCard()
            .background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 28))
            .foregroundStyle(DinoStyle.ink).accessibilityElement(children: .contain).accessibilityAddTraits(.isModal)
            .onAppear { resetExample() }
    }

    private func nextExample() {
        exampleIndex = (exampleIndex + 1) % (kind == .activity ? 5 * minutes.count : 12 * minutes.count)
        resetExample()
    }

    private func resetExample() {
        let time = DinoDemonstrationExamples.time(index: exampleIndex, minutes: minutes)
        exampleHour = kind == .activity ? DinoDemonstrationExamples.activity(index: exampleIndex).hour : time.hour
        exampleMinute = time.minute
        matchingSelections = [:]
        adjustingMinutes = kind == .setDigital ? !digitalAdjustingMinutes : false
    }
}

struct DinoQuestionTitle: View {
    @ObservedObject private var language = LanguageManager.shared
    @Environment(\.dinoHighContrast) private var highContrast
    let question: ClockQuestion
    var instructionKey: String? = nil
    var fontSize: CGFloat = 21

    var body: some View {
        title.font(.system(size: fontSize, weight: .heavy, design: .rounded))
            .multilineTextAlignment(.center).frame(maxWidth: .infinity)
    }

    private var title: Text {
        guard [.spokenTime, .trueFalse].contains(question.kind) else {
            return Text(LocalizedStringKey(instructionKey ?? question.kind.instructionKey))
        }
        let words = DinoTimeWords.time(question.kind == .trueFalse ? (question.statement ?? question.target) : question.target,
                                      language: language.effective.code)
        let parts = L(key: "dino.question.\(question.kind.rawValue).format").components(separatedBy: "%@")
        let highlighted = Text(verbatim: words).foregroundColor(highContrast ? Color(dinoHex: 0x21556B) : Color(dinoHex: 0x377C95))
        return Text("\(parts[0])\(highlighted)\(parts.count > 1 ? parts[1] : "")")
    }
}

struct DinoDemonstrationActions: View {
    let done: () -> Void
    let another: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: done) { Label("dino.ready", systemImage: "checkmark") }
                .buttonStyle(DinoButtonStyle()).accessibilityIdentifier("demo.ready")
            Button(action: another) { Label("dino.example.another", systemImage: "arrow.clockwise") }
                .multilineTextAlignment(.center).buttonStyle(DinoSecondaryButtonStyle())
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(DinoStyle.ink, lineWidth: 2))
                .accessibilityIdentifier("demo.nextExample")
        }
    }
}
