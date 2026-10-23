import SwiftUI

struct DinoGameView: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var player: DinoPlayer
    @EnvironmentObject private var settings: DinoSettings
    @StateObject var session: DinoSession
    let onExit: () -> Void
    let onResult: (DinoLevelResult) -> Void
    var onCompanionReaction: (DinoAnimation.Clip) -> Void = { _ in }
    @State private var confirmExit = false
    @State private var personalizing = false
    @State private var showsDayPartSettings = false
    @State private var hudHeight: CGFloat = 128
    @State private var answerFrame: CGRect?

    var body: some View {
        GeometryReader { g in
            let short = g.size.height < 700
            let tablet = g.size.width >= 600
            let wide = g.size.width >= 900 && g.size.width > g.size.height
            let width = min(tablet ? 900 : 520, max(240, g.size.width - (tablet ? 64 : 36)))
            let footerHeight: CGFloat = session.question.kind == .dayPart ? 146 : 80
            let questionViewport = max(0, g.size.height - hudHeight - footerHeight)
            let clockSize = min(tablet ? 260 : 210, width * 0.54, max(160, g.size.height * 0.28))
            let answerClockSize = tablet ? 210 : max(88, (g.size.height - hudHeight - footerHeight - (short ? 198 : 250)) / 2)
            ZStack {
                JungleBackground(quiet: true)
                VStack(spacing: 0) {
                    AdventureHeader(personalizerChanged: { personalizing = $0 }, sharedCompanion: true, level: session.level.id,
                                        stars: player.profile.totalStars, worldID: session.level.worldID,
                                        compact: g.size.height < 430, viewportHeight: g.size.height,
                                        questionCounter: session.practice == nil
                                            ? "\(min(session.attempt.index + 1, session.level.questionCount))/\(session.level.questionCount)"
                                            : DinoPracticeCounter(value: session.practiceQuestionNumber).digits,
                                        practiceStreak: session.practice == nil ? nil : session.practiceStreak,
                                        practiceRecord: session.practiceBestStreak,
                                        practiceQuestionNumber: session.practice == nil ? nil : session.practiceQuestionNumber,
                                        practiceConfiguration: session.practice,
                                        help: showExample, action: pause)
                        .readGeometry(for: CGFloat.self) { $0.size.height } action: { hudHeight = $0 }
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: short ? 10 : 18) {
                                if session.level.isBoss { crystals }
                                DinoQuestionTitle(question: session.question, instructionKey: session.instructionKey,
                                                  announces: session.demonstration == nil && !confirmExit)
                                    .frame(maxWidth: min(680, width))
                                    .frame(maxWidth: .infinity)
                                    .accessibilityIdentifier("question.title")
                                    .id("question.top")
                                QuestionRenderer(session: session, theme: player.profile.clockTheme, width: width, clockSize: clockSize, wideLayout: wide, compactLayout: short, answerClockSize: answerClockSize)
                                    .id(session.question.id)
                            }.padding(.vertical, short ? 12 : 20).frame(width: width)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity)
                                .modifier(ShortScrollCentering(height: questionViewport))
                                .contentShape(Rectangle())
                        }
                        .centersShortContent()
                        .coordinateSpace(name: "game.questionViewport")
                        .onPreferenceChange(QuestionAnswerFrameKey.self) { answerFrame = $0 }
                        .accessibilityIdentifier("game.questions")
                        .onValueChange(of: session.hasFeedback) { visible in
                            guard visible, !session.correctFeedback, let frame = answerFrame else { return }
                            let anchor: UnitPoint?
                            if frame.minY < 0 { anchor = .top }
                            else if frame.maxY > questionViewport { anchor = .bottom }
                            else { anchor = nil }
                            if let anchor {
                                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                                    proxy.scrollTo("question.answerFocus", anchor: anchor)
                                }
                            }
                        }
                        .onValueChange(of: session.question.id) { _ in
                            proxy.scrollTo("question.top", anchor: .top)
                        }
                        .onValueChange(of: session.hasFeedback) { showing in
                            if showing { DinoQuestionSpeech.shared.interrupt() }
                        }
                        .onValueChange(of: wide) { _ in
                            if session.question.kind == .timeZone { proxy.scrollTo("question.top", anchor: .top) }
                        }
                    }
                    answerFooter(height: footerHeight, width: width)
                }.disabled(confirmExit || session.demonstration != nil).accessibilityHidden(confirmExit || session.demonstration != nil)
                if let kind = session.demonstration {
                    Color.black.opacity(0.28).ignoresSafeArea()
                    ScrollView {
                        InteractionDemonstration(kind: kind, theme: player.profile.clockTheme, minuteStep: session.minuteStep,
                                                 practiceTime: session.practice?.time ?? session.question.timeFamily,
                                                 worldMinutes: session.practice == nil ? session.question.timeFamily.minutes : nil,
                                                 width: min(380, max(230, g.size.width - 80)), done: session.dismissDemonstration)
                            .padding(16)
                    }.bouncesOnlyWhenNeeded()
                        .centersShortContent()
                        .frame(maxWidth: 480, maxHeight: g.size.height - 24)
                        .transition(.scale.combined(with: .opacity))
                }
                if confirmExit {
                    Color.black.opacity(0.28).ignoresSafeArea()
                    ScrollView {
                        exitCard(compact: g.size.height < 430).padding(16)
                    }.bouncesOnlyWhenNeeded()
                        .frame(maxWidth: 440, maxHeight: min(520, g.size.height - 16))
                        .transition(.scale(scale: 0.94).combined(with: .opacity))
                }
            }

        }.foregroundStyle(DinoStyle.ink)
            .task {
                DinoAnswerFeedback.shared.prepare(sound: settings.soundEffectsEnabled, vibration: settings.hapticsEnabled)
            }
            .transformPreference(DinoCompanionPreference.self) { anchors in
                if confirmExit || session.demonstration != nil { anchors = [:] }
            }
            .task(id: session.shouldAutoAdvance && session.demonstration == nil && !confirmExit && !personalizing) {
                guard session.shouldAutoAdvance && session.demonstration == nil && !confirmExit && !personalizing else { return }
                do { try await Task.sleep(for: .seconds(DinoAnimation.correctAnswerDelay)) } catch { return }
                guard !Task.isCancelled else { return }
                session.advance()
            }
            .onValueChange(of: session.hasFeedback ? (session.correctFeedback ? DinoAnimation.Clip.thumbsUp : .wrongAnswer) : .idle, initial: true) { reaction in
                onCompanionReaction(reaction)
            }
            .onValueChange(of: session.result != nil) { hasResult in
                if hasResult, let result = session.result { onResult(result) }
            }
            .animation(.easeOut(duration: 0.18), value: confirmExit)
            .sheet(isPresented: $showsDayPartSettings) {
                DinoDayPartScheduleEditor(schedule: settings.dayPartSchedule, returnsToGame: true) { schedule in
                    session.rejudgeDayPart(using: schedule)
                }
                .pagePresentation()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
    }

    private func answerFooter(height: CGFloat, width: CGFloat) -> some View {
        // Reserve the same space before and after answering so the question stays still.
        // A day-part question also reserves the settings button, so closing the question does not move the choices.
        // This row sits outside the scroll view and above the bottom safe area.
        let showsNext = session.hasFeedback && !session.shouldAutoAdvance
        let check = showsNext ? nil : session.answerCheck
        let dayPart = session.question.kind == .dayPart
        return Color.clear.frame(height: height)
            .overlay(alignment: dayPart ? .bottom : .center) {
                VStack(spacing: 8) {
                    if showsNext && session.offersDayPartSettings {
                        Button { showsDayPartSettings = true } label: {
                            Label("dino.dayPart.changeSettings", systemImage: "gearshape.fill")
                        }
                        .buttonStyle(DinoButtonStyle(color: Color(dinoHex: 0xD0D7DC), inkLabel: true))
                        .frame(width: min(420, width))
                        .accessibilityIdentifier("question.dayPart.settings")
                    }
                    if showsNext {
                        Button {
                            if session.canRetry { session.showAnswer() }
                            else { session.advance() }
                        } label: {
                            Label(LocalizedStringKey(session.canRetry ? "dino.showAnswer" : "dino.next"), systemImage: session.canRetry ? "eye" : "arrow.right")
                        }
                        .buttonStyle(DinoButtonStyle())
                        .multilineTextAlignment(.center)
                        .frame(width: min(420, width))
                        .accessibilityIdentifier(session.canRetry ? "question.showAnswer" : "question.next")
                    } else if let check {
                        Button { session.submit(check.answer) } label: {
                            Label(LocalizedStringKey(check.titleKey), systemImage: "checkmark")
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .buttonStyle(DinoButtonStyle())
                        .disabled(!check.enabled)
                        .frame(width: min(420, width))
                        .accessibilityIdentifier("question.confirm")
                    }
                }
                .padding(.bottom, dayPart && (showsNext || check != nil) ? 11 : 0)
                .frame(maxWidth: dayPart ? .infinity : nil)
                .background {
                    if dayPart && (showsNext || check != nil) {
                        Rectangle().fill(.ultraThinMaterial).ignoresSafeArea(edges: .bottom)
                    }
                }
            }
            .background {
                if !dayPart && (showsNext || check != nil) {
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
            Button(role: .destructive, action: onExit) { Label("dino.exit", systemImage: "map.fill") }
                .buttonStyle(DinoButtonStyle(color: Color(dinoHex: 0xC74343), compact: true))
                .accessibilityIdentifier("game.exit.confirm")
        }.padding(4).dinoCard()
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
    @State private var exampleIndex = 0
    @State private var matchingSelections: [Int: ClockTime] = [:]
    private var minutes: [Int] { worldMinutes ?? practiceTime.minutes }
    private var exampleTime: ClockTime { ClockTime(hour: exampleHour, minute: exampleMinute) }
    /// The example shows one pair, so the title names that time without counting answer clocks.
    private var examplePrompt: ClockQuestion {
        ClockQuestion(id: exampleIndex, kind: kind, target: exampleTime, options: [],
                      activity: kind == .activity ? DinoDemonstrationExamples.activity(index: exampleIndex) : nil,
                      companionClocks: [])
    }
    private var matchingQuestion: ClockQuestion {
        let times = (0..<3).map { DinoDemonstrationExamples.time(index: exampleIndex + $0 + 1, minutes: minutes) }
        return ClockQuestion(id: exampleIndex, kind: .match, target: times[0], options: [times[2], times[0], times[1]],
                             activity: nil, companionClocks: Array(times.dropFirst()), relatedTimes: times, answer: .pairs(times))
    }
    var body: some View {
        if kind == .setAnalog {
            DinoAnalogSettingDemonstration(theme: theme, minuteStep: minuteStep, minutes: minutes, width: width, done: done)
        } else if kind == .advanceAnalog {
            DinoAnalogAdvanceDemonstration(theme: theme, minuteStep: minuteStep, minutes: minutes, width: width, done: done)
        } else if kind.isExpanded {
            DinoExpandedDemonstration(kind: kind, time: practiceTime, worldMinutes: worldMinutes,
                                      minuteStep: minuteStep, width: width, theme: theme, done: done)
        } else { originalExample }
    }
    private var originalExample: some View {
        VStack(spacing: 14) {
            Label("dino.example", systemImage: "sparkles").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(DinoStyle.green)
            if kind == .chooseAnalog || kind == .activity {
                DinoQuestionTitle(question: examplePrompt, fontSize: 24, speechScope: "demo")
                    .accessibilityIdentifier("demo.title")
            } else {
                Text(LocalizedStringKey(minuteStep < 60 && kind == .setDigital ? "dino.practice.\(kind.rawValue)" : kind.instructionKey))
                    .font(.system(size: 24, weight: .heavy, design: .rounded)).multilineTextAlignment(.center)
                    .speakQuestionTitle(L(key: minuteStep < 60 && kind == .setDigital ? "dino.practice.\(kind.rawValue)" : kind.instructionKey),
                                        identity: "demo-\(kind.rawValue)-\(exampleIndex)")
                    .accessibilityIdentifier("demo.title")
            }
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
                AnalogClock(time: exampleTime, theme: theme, size: min(170, width / 1.48), showHandHints: true)
                    .accessibilityIdentifier("demo.analog")
                if kind == .setDigital {
                    DigitalClockControl(hour: $exampleHour,
                                        theme: theme, minute: exampleMinute, fontSize: min(38, width * 0.14),
                                        onMinuteChange: { exampleMinute = $0 }, minuteStep: minuteStep,
                                        valueIdentifier: "demo.digital", showHandHints: true)
                    Text("dino.clock.arrowControls").font(.system(size: 14, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                } else {
                    DigitalClock(time: ClockTime(hour: exampleHour, minute: exampleMinute), theme: theme, fontSize: 30, showHandHints: true)
                        .accessibilityIdentifier("demo.digital")
                }
            }
            DinoDemonstrationActions(done: done, another: nextExample)
        }.frame(width: width).dinoCard()
            .background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 28))
            .foregroundStyle(DinoStyle.ink)
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
    }
}

struct DinoAnalogSettingDemonstration: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let theme: ClockTheme
    let minuteStep: Int
    let minutes: [Int]
    let width: CGFloat
    let done: () -> Void
    @State private var exampleIndex = 0
    @State private var time = ClockTime(hour: 9)
    @State private var adjustingMinutes = false
    @State private var demonstratedAction: DinoAnalogSettingExample.Action? = nil
    @State private var confirmed = false
    @State private var manuallyAdjusting = false
    @State private var hourAngle = 270.0
    @State private var minuteAngle = 0.0

    private var handStep: Int { DinoPracticeTime.analogHandStep(minuteStep) }
    private var script: DinoAnalogSettingExample {
        DinoAnalogSettingExample(target: DinoDemonstrationExamples.time(index: exampleIndex, minutes: minutes),
                                 minuteStep: handStep, clockwise: exampleIndex.isMultiple(of: 2))
    }

    var body: some View {
        VStack(spacing: 12) {
            Label("dino.example", systemImage: "sparkles")
                .font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(DinoStyle.green)
            Text("dino.question.setAnalog")
                .font(.system(size: 21, weight: .heavy, design: .rounded)).multilineTextAlignment(.center)
                .speakQuestionTitle(L(key: "dino.question.setAnalog"), identity: "demo-setAnalog-\(exampleIndex)")
                .accessibilityIdentifier("demo.title")
            DigitalClock(time: script.target, theme: theme, fontSize: min(32, width * 0.1))
                .accessibilityIdentifier("demo.digital")
            AnalogClock(time: time, theme: theme, size: min(180, width * 0.57),
                        onHourChange: { hour in
                            stopDemonstration()
                            time = ClockTime(hour: hour, minute: time.minute)
                        },
                        onMinuteChange: minuteStep < 60 ? { next in stopDemonstration(); time = next } : nil,
                        minuteStep: handStep, adjustingMinutes: adjustingMinutes,
                        onHandSelection: { stopDemonstration(); adjustingMinutes = $0 },
                        displayedHourAngle: manuallyAdjusting ? nil : hourAngle,
                        displayedMinuteAngle: manuallyAdjusting ? nil : minuteAngle)
                .padding(6)
                .modifier(ClockAnswerOutline(visible: confirmed, correct: true))
                .accessibilityIdentifier("demo.analog")
            DinoAnalogClockControls(adjustingMinutes: Binding(get: { adjustingMinutes }, set: {
                stopDemonstration()
                adjustingMinutes = $0
            }), allowsMinutes: minuteStep < 60, minuteStep: handStep, prefix: "demo",
                                    demonstratedAction: demonstratedAction) { direction in
                stopDemonstration()
                time = script.applying(.adjust(direction), to: time, adjustingMinutes: adjustingMinutes)
            }
            Button {
                // The script hides the separate ready button. Leaving while it is still
                // playing has to dismiss the example, or the player cannot close it.
                if confirmed || !manuallyAdjusting { done() }
                else { confirmed = time == script.target }
            } label: {
                Label(LocalizedStringKey(confirmed ? "dino.ready" : "dino.clock.check"), systemImage: "checkmark")
                    .lineLimit(1).minimumScaleFactor(0.75)
                    .opacityTextTransition()
            }.buttonStyle(DinoClockControlButtonStyle())
                .padding(.top, 12)
                .accessibilityIdentifier(confirmed ? "demo.ready" : "demo.confirm")
                .overlay(alignment: .bottomTrailing) { if demonstratedAction == .confirm { DinoClockTapCue() } }
            DinoDemonstrationActions(showsReady: false, done: done) {
                // Reset synchronously so the next frame never shows the previous answer.
                exampleIndex = (exampleIndex + 1) % (12 * minutes.count)
                reset()
            }
        }.frame(width: width).dinoCard()
            .background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 28))
            .foregroundStyle(DinoStyle.ink)
            .onAppear { reset() }
            .task(id: exampleIndex) { await demonstrate() }
    }

    private func reset() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            time = script.initialTime
            adjustingMinutes = false
            demonstratedAction = nil
            confirmed = false
            manuallyAdjusting = false
            hourAngle = script.initialHourAngle
            minuteAngle = script.initialMinuteAngle
        }
    }

    private func stopDemonstration() {
        manuallyAdjusting = true
        demonstratedAction = nil
        confirmed = false
    }

    @MainActor private func demonstrate() async {
        let example = script
        do {
            try await Task.sleep(for: .seconds(2))
            for action in example.actions {
                try Task.checkCancellation()
                guard !manuallyAdjusting else { return }
                demonstratedAction = action
                try await Task.sleep(for: .seconds(0.3))
                try Task.checkCancellation()
                guard !manuallyAdjusting else { return }
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                    switch action {
                    case .selectMinutes(let minutes): adjustingMinutes = minutes
                    case .adjust(let direction):
                        time = example.applying(action, to: time, adjustingMinutes: adjustingMinutes)
                        hourAngle = DinoAnalogSettingExample.continuingAngle(time.hourAngle, from: hourAngle, direction: direction)
                        minuteAngle = DinoAnalogSettingExample.continuingAngle(time.minuteAngle, from: minuteAngle, direction: direction)
                    case .confirm: confirmed = time == example.target
                    }
                }
                try await Task.sleep(for: .seconds(action == .confirm ? 0.8 : 0.3))
                demonstratedAction = nil
                try await Task.sleep(for: .seconds(0.2))
            }
        } catch { /* Dismissal and another example cancel the previous script. */ }
    }
}

struct DinoAnalogAdvanceDemonstration: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var language = LanguageManager.shared
    let theme: ClockTheme
    let minuteStep: Int
    let minutes: [Int]
    let width: CGFloat
    let done: () -> Void
    @State private var exampleIndex = 0
    @State private var previousTarget: ClockTime?
    @State private var question = DinoDemonstrationExamples.question(kind: .advanceAnalog, minutes: [0], minuteStep: 60,
                                                                    index: 0, previousTarget: nil)
    @State private var time = ClockTime(hour: 12)
    @State private var adjustingMinutes = false
    @State private var demonstratedAction: DinoAnalogSettingExample.Action? = nil
    @State private var confirmed = false
    @State private var manuallyAdjusting = false
    @State private var hourAngle = 0.0
    @State private var minuteAngle = 0.0

    private var handStep: Int { DinoPracticeTime.analogHandStep(minuteStep) }
    private var script: DinoAnalogAdvanceExample { DinoAnalogAdvanceExample(question: question, minuteStep: handStep) }
    private var playFace: CGFloat { min(160, max(120, width - 24)) }

    var body: some View {
        VStack(spacing: 12) {
            Label("dino.example", systemImage: "sparkles")
                .font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(DinoStyle.green)
            DinoQuestionTitle(question: question, speechScope: "demo")
                .accessibilityIdentifier("demo.title")
            DinoAnalogAdvanceLayout(start: script.start, theme: theme, durationMinutes: question.durationMinutes,
                                    language: language.effective.code, playSize: playFace,
                                    prefix: "demo", startIdentifier: "demo.startClock") {
                AnalogClock(time: time, theme: theme, size: playFace,
                            onHourChange: { hour in
                                stopDemonstration()
                                time = ClockTime(hour: hour, minute: time.minute)
                            },
                            onMinuteChange: minuteStep < 60 ? { next in stopDemonstration(); time = next } : nil,
                            minuteStep: handStep, adjustingMinutes: adjustingMinutes,
                            onHandSelection: { stopDemonstration(); adjustingMinutes = $0 },
                            displayedHourAngle: manuallyAdjusting ? nil : hourAngle,
                            displayedMinuteAngle: manuallyAdjusting ? nil : minuteAngle)
                    .padding(4)
                    .modifier(ClockAnswerOutline(visible: confirmed, correct: true))
                    .accessibilityIdentifier("demo.analog")
            }
            DinoAnalogClockControls(adjustingMinutes: Binding(get: { adjustingMinutes }, set: {
                stopDemonstration()
                adjustingMinutes = $0
            }), allowsMinutes: minuteStep < 60, minuteStep: handStep, prefix: "demo",
                                    demonstratedAction: demonstratedAction) { direction in
                stopDemonstration()
                time = script.applying(.adjust(direction), to: time, adjustingMinutes: adjustingMinutes)
            }
            Button {
                stopDemonstration()
                confirmed = time == script.target
            } label: {
                Label("dino.clock.check", systemImage: "checkmark")
                    .lineLimit(1).minimumScaleFactor(0.75)
            }.buttonStyle(DinoClockControlButtonStyle())
                .accessibilityIdentifier("demo.confirm")
                .overlay(alignment: .bottomTrailing) { if demonstratedAction == .confirm { DinoClockTapCue() } }
            DinoDemonstrationActions(done: done) {
                exampleIndex = (exampleIndex + 1) % 10_000
                previousTarget = question.target
                reset()
            }
        }.frame(width: width).dinoCard()
            .background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 28))
            .foregroundStyle(DinoStyle.ink)
            .onAppear { reset() }
            .task(id: exampleIndex) { await demonstrate() }
    }

    private func reset() {
        question = DinoDemonstrationExamples.question(kind: .advanceAnalog, minutes: minutes, minuteStep: minuteStep,
                                                      index: exampleIndex, previousTarget: previousTarget)
        let example = DinoAnalogAdvanceExample(question: question, minuteStep: handStep)
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            time = example.start
            adjustingMinutes = false
            demonstratedAction = nil
            confirmed = false
            manuallyAdjusting = false
            hourAngle = example.start.hourAngle
            minuteAngle = example.start.minuteAngle
        }
    }

    private func stopDemonstration() {
        manuallyAdjusting = true
        demonstratedAction = nil
        confirmed = false
    }

    @MainActor private func demonstrate() async {
        let example = DinoAnalogAdvanceExample(question: question, minuteStep: handStep)
        do {
            try await Task.sleep(for: .seconds(1.2))
            var movingMinutes = false
            for action in example.actions {
                try Task.checkCancellation()
                guard !manuallyAdjusting else { return }
                demonstratedAction = action
                try await Task.sleep(for: .seconds(0.25))
                try Task.checkCancellation()
                guard !manuallyAdjusting else { return }
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                    switch action {
                    case .selectMinutes(let minutes):
                        adjustingMinutes = minutes
                        movingMinutes = minutes
                    case .adjust(let direction):
                        time = example.applying(action, to: time, adjustingMinutes: movingMinutes)
                        hourAngle = DinoAnalogSettingExample.continuingAngle(time.hourAngle, from: hourAngle, direction: direction)
                        minuteAngle = DinoAnalogSettingExample.continuingAngle(time.minuteAngle, from: minuteAngle, direction: direction)
                    case .confirm: confirmed = time == example.target
                    }
                }
                try await Task.sleep(for: .seconds(action == .confirm ? 0.6 : 0.2))
                demonstratedAction = nil
                try await Task.sleep(for: .seconds(0.12))
            }
        } catch { /* Dismissal and another example cancel the previous script. */ }
    }
}

struct DinoQuestionTitle: View {
    @ObservedObject private var language = LanguageManager.shared
    @Environment(\.dinoHighContrast) private var highContrast
    let question: ClockQuestion
    var instructionKey: String? = nil
    var fontSize: CGFloat = 21
    /// False while a demonstration or exit card covers this title, so only the visible title is read.
    var announces = true
    var speechScope = "play"

    var body: some View {
        title.font(.system(size: fontSize, weight: .heavy, design: .rounded))
            .multilineTextAlignment(.center).frame(maxWidth: .infinity)
            .speakQuestionTitle(spokenText, identity: "\(speechScope)-\(question.id)", active: announces)
    }

    private var prompt: DinoQuestionPrompt {
        DinoQuestionPrompt.make(question: question, language: language.effective.code,
                                instructionKey: instructionKey ?? question.kind.instructionKey)
    }

    private var spokenText: String {
        prompt.spoken { L(key: $0) }
    }

    private var title: Text {
        guard let formatKey = prompt.formatKey else {
            return Text(LocalizedStringKey(prompt.plainKey))
        }
        let parts = L(key: formatKey).components(separatedBy: "%@")
        return parts.indices.reduce(Text(verbatim: "")) { partial, index in
            var next = partial
            if !parts[index].isEmpty { next = next + Text(verbatim: parts[index]) }
            if index < prompt.arguments.count {
                let argument = prompt.arguments[index]
                next = next + Text(verbatim: argument.text).foregroundColor(emphasisColor(argument.emphasis))
            }
            return next
        }
    }

    private func emphasisColor(_ emphasis: DinoQuestionPrompt.Emphasis) -> Color {
        switch emphasis {
        case .plain:
            return DinoStyle.ink
        case .clock:
            return highContrast ? Color(dinoHex: 0x21556B) : Color(dinoHex: 0x377C95)
        case .forward:
            return DinoStyle.deepGreen
        case .backward:
            return DinoTimeDirection.earlier
        }
    }
}

extension View {
    /// Reads this title aloud while it is the visible question, and stops when another title takes over.
    func speakQuestionTitle(_ text: String, identity: String, active: Bool = true) -> some View {
        modifier(SpokenQuestionTitle(text: text, identity: identity, active: active))
    }
}

private struct SpokenQuestionTitle: ViewModifier {
    @EnvironmentObject private var settings: DinoSettings
    @ObservedObject private var language = LanguageManager.shared
    var text: String
    var identity: String
    var active: Bool
    private static let owner = "question-title"

    func body(content: Content) -> some View {
        let enabled = active && settings.speakQuestionTitles
        return content.task(id: enabled ? "\(identity)|\(language.effective.code)|\(text)" : "off|\(identity)") {
            guard enabled else { return }
            let token = DinoQuestionSpeech.shared.claim(owner: Self.owner, text: text,
                                                       languageCode: language.effective.code)
            defer { DinoQuestionSpeech.shared.release(owner: Self.owner, token: token) }
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(3600)) }
                catch { break }
            }
        }
    }
}

struct DinoDemonstrationActions: View {
    var showsReady = true
    let done: () -> Void
    let another: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            if showsReady {
                Button(action: done) { Label("dino.ready", systemImage: "checkmark") }
                    .buttonStyle(DinoButtonStyle()).accessibilityIdentifier("demo.ready")
            }
            Button(action: another) { Label("dino.example.another", systemImage: "arrow.clockwise") }
                .multilineTextAlignment(.center).buttonStyle(DinoSecondaryButtonStyle())
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(DinoStyle.ink, lineWidth: 2))
                .accessibilityIdentifier("demo.nextExample")
        }
    }
}
