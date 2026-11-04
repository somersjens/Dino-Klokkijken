import SwiftUI

struct QuestionRenderer: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var language = LanguageManager.shared
    @ObservedObject private var deviceHourFormat = DeviceHourFormat.shared
    @ObservedObject var session: DinoSession
    @State private var adjustingMinutes = false
    let theme: ClockTheme
    let width: CGFloat
    let clockSize: CGFloat
    var wideLayout = false
    var compactLayout = false
    var answerClockSize: CGFloat = 210
    var availableHeight: CGFloat = 700
    var horizontalSequence = false
    private var comparing: Bool { session.hasFeedback && !session.correctFeedback }
    private var question: ClockQuestion { session.question }
    private var targetSize: CGFloat { min(clockSize, width - 20) }
    private var analogHandStep: Int { DinoPracticeTime.analogHandStep(session.minuteStep) }
    private var layout: DinoGameLayout {
        DinoGameLayout(width: width, height: availableHeight, kind: question.kind,
                       optionCount: max(question.options.count, question.responses.count))
    }
    private var pairedClocks: Bool { layout.pairedClocks }
    private var analogSettingWidth: CGFloat { width }

    var body: some View {
        VStack(spacing: question.kind == .setAnalog ? 8 : compactLayout ? 14 : 22) {
            switch question.kind {
            case .chooseAnalog, .activity:
                DinoQuestionComposition(layout: layout) {
                    targetCard
                } answers: {
                    analogOptions
                }
            case .chooseDigital:
                digitalReadingQuestion
            case .setAnalog:
                if pairedClocks {
                    pairedAnalogSetting
                } else {
                    targetCard
                    analogInput.id("question.answers")
                    DinoAnalogClockControls(adjustingMinutes: $adjustingMinutes, allowsMinutes: session.allowsMinutes,
                                            minuteStep: analogHandStep, adjust: adjustAnalog)
                        .frame(width: min(320, width))
                        .modifier(AnswerControlVisibility(session: session, reduceMotion: reduceMotion))
                }
            case .setDigital:
                if pairedClocks { pairedDigitalSetting }
                else {
                    analogTarget
                    digitalInput.id("question.answers")
                }
            case .match:
                ClockMatchingBoard(times: question.relatedTimes, options: question.options,
                                   selections: $session.pairSelections, theme: theme, width: width,
                                   hasFeedback: session.hasFeedback, availableHeight: availableHeight,
                                   horizontalLayout: wideLayout)
                    .environment(\.dinoClockReadingAssistance, false)
                    .id("question.answers")
                    .questionAnswerFocus()
            default:
                DinoExpandedQuestionView(session: session, theme: theme, width: width, clockSize: clockSize,
                                         compactLayout: compactLayout || (wideLayout && question.kind == .timeZone),
                                         answerClockSize: answerClockSize,
                                         wideLayout: wideLayout, availableHeight: availableHeight,
                                         horizontalSequence: horizontalSequence)
            }
        }.frame(maxWidth: .infinity)
            .environment(\.dinoClockReadingAssistance, session.showsClockHandHints)
            // The reference face also resizes when its numbered helpers appear.
            // Animate that same artwork together with the digital comparison.
            .animation(reduceMotion ? nil : .easeInOut(duration: DinoQuestionFeedbackTiming.layout),
                       value: question.kind == .setDigital && comparing)
    }

    private var pairedFace: CGFloat { min(clockSize, width * 0.38 - 24) }
    private var pairedHintWidth: CGFloat { width * 0.38 - 20 }
    private var pairedComparisonBounds: CGRect? {
        guard comparing, session.showsClockHandHints else { return nil }
        return ClockHandHintGeometry.bounds(time: session.attempt.submittedAnswer ?? session.inputTime,
                                            shape: theme.analogShape, faceSize: 150)
            .union(ClockHandHintGeometry.bounds(time: question.target, shape: theme.analogShape, faceSize: 150))
    }

    private var pairedAnalogSetting: some View {
        VStack(spacing: 12) {
        DinoClockSettingColumns(width: width, stageHeight: pairedFace + 20) {
            DinoFeedbackReplacement(revealed: comparing) {
                DigitalClock(time: question.target, theme: theme, fontSize: 38)
                    .environment(\.dinoClockReadingAssistance, false)
                    .accessibilityIdentifier("question.targetClock")
            } correction: {
                AnalogClock(time: question.target, theme: theme, size: pairedFace,
                            readingHintWidth: pairedHintWidth, readingHintBounds: pairedComparisonBounds)
                    .frame(width: pairedHintWidth, height: pairedFace).padding(10)
                    .modifier(ClockAnswerOutline(visible: true, correct: true))
                    .accessibilityIdentifier("question.correctClock")
            }
        } input: {
                AnalogClock(time: session.attempt.submittedAnswer ?? session.inputTime, theme: theme, size: pairedFace,
                            onHourChange: session.hasFeedback ? nil : { session.inputHour = $0 },
                            readingHintWidth: pairedHintWidth, readingHintBounds: pairedComparisonBounds,
                            onMinuteChange: session.hasFeedback || !session.allowsMinutes ? nil : { session.setInputTime($0) },
                            minuteStep: analogHandStep, adjustingMinutes: adjustingMinutes,
                            onHandSelection: session.hasFeedback ? nil : { adjustingMinutes = $0 })
                    .frame(width: pairedHintWidth, height: pairedFace).padding(10)
                    .modifier(ClockAnswerOutline(visible: session.hasFeedback, correct: session.correctFeedback))
                    .accessibilityIdentifier("question.analogControl")
        }
        DinoAnalogClockControls(adjustingMinutes: $adjustingMinutes, allowsMinutes: session.allowsMinutes,
                                minuteStep: analogHandStep, horizontalLayout: layout.horizontalControls, adjust: adjustAnalog)
            .frame(width: min(width, layout.horizontalControls ? 520 : 280))
            .modifier(AnswerControlVisibility(session: session, reduceMotion: reduceMotion))
        }
        .id("question.answers").questionAnswerFocus()
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: comparing)
    }

    private var pairedDigitalSetting: some View {
        let stageHeight = min(pairedFace + 20, max(36, availableHeight - 90))
        return DinoClockSettingColumns(width: width, stageHeight: stageHeight) {
            DinoFeedbackReplacement(revealed: comparing) {
                AnalogClock(time: question.target, theme: theme, size: pairedFace,
                            readingHintWidth: width * 0.38 - 20)
                    .accessibilityIdentifier("question.targetClock")
            } correction: {
                DigitalClock(time: question.target, theme: theme, fontSize: 38, feedbackCorrect: true)
                    .accessibilityIdentifier("question.correctClock")
            }
        } input: {
            DigitalClockControl(hour: $session.inputHour, theme: theme, minute: session.inputMinute, fontSize: 38,
                                onMinuteChange: { session.inputMinute = $0 }, minuteStep: session.minuteStep,
                                valueIdentifier: "question.digitalControl",
                                feedbackCorrect: session.hasFeedback ? session.correctFeedback : nil,
                                controlsEnabled: !session.hidesAnswerControls,
                                controlsBelow: true, displayHeight: stageHeight)
        }
        .id("question.answers").questionAnswerFocus()
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: comparing)
    }

    private var analogInput: some View {
        let hourChange: ((Int) -> Void)? = session.hasFeedback ? nil : { session.inputHour = $0 }
        let minuteChange: ((ClockTime) -> Void)? = session.hasFeedback || !session.allowsMinutes ? nil : { session.setInputTime($0) }
        return AnalogClockAnswerComparison(answer: session.attempt.submittedAnswer ?? session.inputTime,
                                           target: question.target, theme: theme, width: analogSettingWidth, clockSize: targetSize,
                                           hasFeedback: session.hasFeedback, correct: session.correctFeedback,
                                           onHourChange: hourChange, onMinuteChange: minuteChange,
                                           minuteStep: analogHandStep, adjustingMinutes: adjustingMinutes,
                                           onHandSelection: session.hasFeedback ? nil : { adjustingMinutes = $0 })
    }

    private var digitalInput: some View {
        let font: CGFloat = width < 350 ? 32 : 38
        let displacement = (width + 14) / 4
        // Scale the existing display, including its field anchors. Its vertical
        // control space stays reserved throughout the answer comparison.
        let _ = deviceHourFormat.notation
        let units: CGFloat = theme.resolvedHourNotation(device: deviceHourFormat.notation) == .twelve ? 4.8 : 4.1
        let scale = min(1, (width - 38) / (2 * font * units))
        return ZStack {
            DigitalClockControl(hour: $session.inputHour,
                                theme: theme, minute: session.inputMinute, fontSize: font,
                                onMinuteChange: { session.inputMinute = $0 },
                                minuteStep: session.minuteStep, valueIdentifier: "question.digitalControl",
                                feedbackCorrect: session.hasFeedback ? session.correctFeedback : nil,
                                controlsEnabled: !session.hidesAnswerControls,
                                feedbackRevealDelay: DinoQuestionFeedbackTiming.inputRevealDelay)
                .scaleEffect(comparing ? scale : 1)
                .offset(x: comparing ? -displacement : 0)
                .animation(reduceMotion ? nil : .easeInOut(duration: DinoQuestionFeedbackTiming.layout)
                    .delay(comparing ? DinoQuestionFeedbackTiming.controlExit : 0), value: comparing)
            DigitalClock(time: question.target, theme: theme, fontSize: font,
                         reservesHandHintSpace: true, feedbackCorrect: true)
                .padding(.bottom, 48)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(theme.digitalReading(question.target, languageCode: language.effective.code))
                .scaleEffect(scale)
                .offset(x: displacement)
                .opacity(comparing ? 1 : 0)
                .allowsHitTesting(false).accessibilityHidden(!comparing)
                .accessibilityIdentifier("question.correctClock")
                .animation(reduceMotion ? nil : .easeOut(duration: DinoQuestionFeedbackTiming.reveal)
                    .delay(comparing ? DinoQuestionFeedbackTiming.inputRevealDelay : 0), value: comparing)
            HStack(spacing: 14) {
                AnswerVerdictMark(correct: false).frame(maxWidth: .infinity)
                AnswerVerdictMark(correct: true).frame(maxWidth: .infinity)
            }
            .offset(y: font * 0.9 + 22)
            .opacity(comparing ? 1 : 0).accessibilityHidden(true)
            .animation(reduceMotion ? nil : .easeOut(duration: DinoQuestionFeedbackTiming.reveal)
                .delay(comparing ? DinoQuestionFeedbackTiming.inputRevealDelay : 0), value: comparing)
        }
        .frame(width: width)
        .questionAnswerFocus()
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: comparing)
    }

    private var targetCard: some View {
        VStack(spacing: 10) {
            if let activity = question.activity {
                Label(LocalizedStringKey(activity.titleKey), systemImage: activity.symbol)
                    .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(DinoStyle.deepGreen)
            }
            DigitalClock(time: question.target, theme: theme, fontSize: width < 350 ? 32 : 38,
                         reservesHandHintSpace: [.chooseAnalog, .setAnalog].contains(question.kind))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(theme.digitalReading(question.target, languageCode: language.effective.code))
                .accessibilityIdentifier("question.targetClock")
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: session.showsClockHandHints)
        }
    }

    private var analogTarget: some View {
        clockStage(height: targetSize) {
            AnalogClock(time: question.target, theme: theme, size: targetSize, readingHintWidth: width)
                .accessibilityIdentifier("question.targetClock")
        }
    }

    private var digitalReadingQuestion: some View {
        let hints = session.showsClockHandHints
        let bounds = hints ? ClockHandHintGeometry.bounds(time: question.target, shape: theme.analogShape, faceSize: 150)
            : CGRect(x: -0.5, y: -0.5, width: 1, height: 1)
        let face = min(targetSize, (layout.contextWidth - 24) / bounds.width)
        return DinoQuestionComposition(layout: layout) {
            AnalogClock(time: question.target, theme: theme, size: face * bounds.height,
                        readingHintWidth: layout.contextWidth - 24,
                        readingHintBounds: hints ? bounds : nil)
                .accessibilityIdentifier("question.targetClock")
        } answers: {
            digitalOptions
        }
    }

    private func clockStage<Content: View>(height: CGFloat, width stageWidth: CGFloat? = nil,
                                          @ViewBuilder content: () -> Content) -> some View {
        content().frame(width: stageWidth ?? width, height: height)
    }

    private var analogOptions: some View {
        let columns = layout.answerColumns()
        let available = min(answerClockSize, (width - CGFloat(columns - 1) * 12) / CGFloat(columns) - 18)
        let cardHeight = max(84, available + 52)
        let size = max(32, available)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns), spacing: 14) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                let wrong = session.hasFeedback && session.rejectedResponses.contains(.time(option))
                let answered = wrong || (session.showsCorrectResponse && .time(option) == question.expectedAnswer)
                answerButton(option: option, index: index) {
                    Group {
                        if question.kind == .chooseAnalog {
                            AnalogChoiceAnswer(time: option, theme: theme,
                                               showsMinuteScale: session.missedFirstAnswer && !answered,
                                               showsExplanation: wrong, fontSize: min(24, max(18, available * 0.14)))
                                .frame(height: cardHeight - 12)
                        } else {
                            AnswerTimeExplanation(time: option, theme: theme, visible: wrong,
                                                  fontSize: min(24, size * 0.19),
                                                  content: AnalogClock(time: option, theme: theme, size: size)
                                                    .allowsHitTesting(false))
                        }
                    }
                        .padding(.horizontal, 8)
                        .padding(.vertical, question.kind == .chooseAnalog ? 6 : 8)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(theme.digitalReading(option, languageCode: language.effective.code))
                }
            }
        }
        .frame(width: width)
        .id("question.answers").questionAnswerFocus()
    }

    private var digitalOptions: some View {
        // Four digital displays need more width than four clock faces, especially with AM/PM.
        let columns = layout.answerColumns()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns), spacing: 14) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                answerButton(option: option, index: index) {
                    DigitalClock(time: option, theme: theme, fontSize: min(31, ((layout.answerWidth - CGFloat(columns - 1) * 12) / CGFloat(columns) - 24) / 4.8))
                        .padding(.vertical, 14).frame(maxWidth: .infinity)
                }
            }
        }
        .frame(width: layout.answerWidth)
        .id("question.answers").questionAnswerFocus()
    }

    private func adjustAnalog(by direction: Int) {
        if adjustingMinutes { session.adjustInputMinutes(by: direction * analogHandStep) }
        else { session.inputHour = ClockTime.shiftedHour(session.inputHour, by: direction) }
    }

    private func answerButton<Content: View>(option: ClockTime, index: Int, @ViewBuilder content: () -> Content) -> some View {
        let response = ClockAnswer.time(option)
        let correct = session.showsCorrectResponse && response == question.expectedAnswer
        let wrong = session.hasFeedback && session.rejectedResponses.contains(response)
        return Button {
            // One transaction moves the tapped choice and its siblings together,
            // including the surrounding layout when reading help needs more room.
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                session.submit(option)
            }
        } label: {
            content().environment(\.dinoClockReadingAssistance, false).frame(maxWidth: .infinity)
                .background(.white, in: RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(correct ? (highContrast ? DinoStyle.deepGreen : DinoStyle.green) : wrong ? DinoStyle.wrong(highContrast) : DinoStyle.ink.opacity(highContrast ? 1 : 0.1), lineWidth: correct || wrong ? 4 : highContrast ? 3 : 1.5))
                .overlay(alignment: .topTrailing) {
                    if correct || wrong {
                        AnswerVerdictMark(correct: correct)
                            .padding(2).background(.white, in: Circle()).offset(x: 5, y: -5)
                    }
                }.shadow(color: DinoStyle.ink.opacity(0.06), radius: 7, y: 4)
        }.buttonStyle(DinoAnswerButtonStyle()).disabled(!session.responseIsEnabled(response)).accessibilityIdentifier("question.option.\(index)")
    }
}

/// A single card area is shared by the face, the optional minute scale and the rejected time.
/// No invisible footer or scale margins reduce the clock before the first mistake.
private struct AnalogChoiceAnswer: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let time: ClockTime
    let theme: ClockTheme
    let showsMinuteScale: Bool
    let showsExplanation: Bool
    let fontSize: CGFloat

    var body: some View {
        AnalogChoiceAnswerLayout(minuteScale: showsMinuteScale ? 1 : 0,
                                 explanation: showsExplanation ? 1 : 0) {
            GeometryReader { geometry in
                // Scale one unchanged drawing so numerals and hands resize together.
                AnalogClock(time: time, theme: theme, size: 240,
                            showMinuteScale: true, minuteScaleVisible: showsMinuteScale)
                    .scaleEffect(geometry.size.width / 240)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            VStack(spacing: 3) {
                Rectangle().fill(DinoStyle.ink.opacity(highContrast ? 0.45 : 0.12))
                    .frame(height: 1).padding(.horizontal, 8)
                DigitalClock(time: time, theme: theme, fontSize: fontSize)
            }
            .padding(.top, 5)
            .frame(maxWidth: .infinity)
            .opacity(showsExplanation ? 1 : 0)
            .accessibilityHidden(!showsExplanation)
        }
        .allowsHitTesting(false)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: showsMinuteScale)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: showsExplanation)
    }
}

private struct AnalogChoiceAnswerLayout: Layout {
    var minuteScale: CGFloat
    var explanation: CGFloat
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { .init(minuteScale, explanation) }
        set { minuteScale = newValue.first; explanation = newValue.second }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions(by: CGSize(width: 160, height: 160))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let footer = subviews[1].sizeThatFits(.init(width: bounds.width, height: nil))
        let clockHeight = max(0, bounds.height - footer.height * explanation)
        let scaleExtent = 1 + 0.28 * minuteScale
        let face = max(0, min(bounds.width, clockHeight) / scaleExtent)
        subviews[0].place(at: CGPoint(x: bounds.midX, y: bounds.minY + clockHeight / 2), anchor: .center,
                          proposal: .init(width: face, height: face))
        subviews[1].place(at: CGPoint(x: bounds.midX, y: bounds.maxY), anchor: .bottom,
                          proposal: .init(width: bounds.width, height: footer.height))
    }
}

/// The clock occupies the card's center until this particular answer needs its explanation.
struct AnswerTimeExplanation<Content: View>: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let time: ClockTime
    let theme: ClockTheme
    let visible: Bool
    var fontSize: CGFloat = 24
    var notation: DigitalHourNotation? = nil
    var explanationText: String? = nil
    let content: Content

    var body: some View {
        CenteredAnswerExplanationLayout(reveal: visible ? 1 : 0) {
            content
            VStack(spacing: 3) {
                Rectangle()
                    .fill(DinoStyle.ink.opacity(highContrast ? 0.45 : 0.12))
                    .frame(height: 1)
                    .padding(.horizontal, 8)
                Group {
                    if let explanationText {
                        Text(verbatim: explanationText)
                            .font(.system(size: fontSize, weight: .bold, design: .rounded))
                            .foregroundStyle(DinoStyle.ink)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        DigitalClock(time: time, theme: theme, fontSize: fontSize, notation: notation)
                    }
                }
            }
            .padding(.top, 4)
            .frame(maxWidth: .infinity)
            .opacity(visible ? 1 : 0)
            .accessibilityHidden(!visible)
            .animation(reduceMotion ? nil : .easeOut(duration: DinoQuestionFeedbackTiming.reveal)
                .delay(visible ? DinoQuestionFeedbackTiming.revealDelay : 0), value: visible)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: DinoQuestionFeedbackTiming.layout), value: visible)
    }
}

private struct CenteredAnswerExplanationLayout: Layout {
    var reveal: CGFloat
    var animatableData: CGFloat { get { reveal } set { reveal = newValue } }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.init(width: proposal.width, height: nil)) }
        return CGSize(width: proposal.width ?? sizes.map(\.width).max() ?? 0,
                      height: sizes.reduce(0) { $0 + $1.height })
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let content = subviews[0].sizeThatFits(.init(width: bounds.width, height: nil))
        let footer = subviews[1].sizeThatFits(.init(width: bounds.width, height: nil))
        let centerY = bounds.midY + (content.height - bounds.height) / 2 * reveal
        subviews[0].place(at: CGPoint(x: bounds.midX, y: centerY), anchor: .center,
                          proposal: .init(width: bounds.width, height: content.height))
        subviews[1].place(at: CGPoint(x: bounds.midX, y: bounds.maxY), anchor: .bottom,
                          proposal: .init(width: bounds.width, height: footer.height))
    }
}

/// Keeps the editable clock centered, fitting its reference into the remaining space on the left.
struct DinoClockSettingColumns<Reference: View, Input: View>: View {
    let width: CGFloat
    let stageHeight: CGFloat
    @ViewBuilder var reference: () -> Reference
    @ViewBuilder var input: () -> Input
    private var columnWidth: CGFloat { width * 0.38 }

    var body: some View {
        let referenceWidth = max(0, (width - columnWidth) / 2 - 28)
        let referenceScale = min(1, referenceWidth / columnWidth)
        input().frame(width: columnWidth)
            .frame(width: width)
            .overlay(alignment: .topLeading) {
                DinoQuestionContext(maxHeight: stageHeight) {
                    reference().frame(width: columnWidth)
                }
                .frame(width: columnWidth, height: stageHeight)
                .scaleEffect(referenceScale)
                .frame(width: referenceWidth, height: stageHeight)
            }
    }
}

struct QuestionAnswerFrameKey: PreferenceKey {
    static var defaultValue: CGRect? { nil }
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

extension View {
    /// Feedback is scrolled into view only when this region is actually clipped.
    func questionAnswerFocus() -> some View {
        background {
            GeometryReader { geometry in
                Color.clear.preference(key: QuestionAnswerFrameKey.self,
                                       value: geometry.frame(in: .named("game.questionViewport")))
            }
        }.id("question.answerFocus")
    }
}

/// The game and its worked example share the exact same hand selector and buttons.
struct DinoAnalogClockControls: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled
    @Namespace private var handSelection
    @Binding var adjustingMinutes: Bool
    let allowsMinutes: Bool
    let minuteStep: Int
    var prefix = "question"
    var horizontalLayout = false
    var demonstratedAction: DinoAnalogSettingExample.Action? = nil
    var adjust: (Int) -> Void

    var body: some View {
        let arrangement = horizontalLayout ? AnyLayout(HStackLayout(spacing: 12)) : AnyLayout(VStackLayout(spacing: 10))
        arrangement {
            if allowsMinutes {
                HStack(spacing: 0) {
                    handButton(minutes: false)
                    handButton(minutes: true)
                }
                .padding(4)
                .background(isEnabled ? .white : DinoStyle.disabledBackground, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isEnabled ? DinoStyle.ink.opacity(highContrast ? 1 : 0.22)
                        : highContrast ? DinoStyle.disabledInk(true) : DinoStyle.disabledBorder,
                        lineWidth: highContrast ? 3 : 1.5))
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("\(prefix).hand")
            }
            HStack(spacing: 12) {
                turnButton(direction: -1)
                turnButton(direction: 1)
            }
        }.frame(maxWidth: .infinity)
    }

    private func handButton(minutes: Bool) -> some View {
        let selected = adjustingMinutes == minutes
        let action = DinoAnalogSettingExample.Action.selectMinutes(minutes)
        return Button { adjustingMinutes = minutes } label: {
            Text(LocalizedStringKey(minutes ? "dino.minutes" : "dino.hours"))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.75).lineLimit(1)
                .foregroundStyle(isEnabled ? (selected ? Color.white : DinoStyle.ink) : DinoStyle.disabledInk(highContrast))
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isEnabled ? DinoStyle.ink : DinoStyle.disabledSelection)
                            .overlay {
                                if !isEnabled {
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(highContrast ? DinoStyle.disabledInk(true) : DinoStyle.disabledBorder,
                                                      lineWidth: highContrast ? 2 : 1)
                                }
                            }
                            .matchedGeometryEffect(id: "selectedHand", in: handSelection)
                    }
                }
        }.buttonStyle(DinoAnswerButtonStyle())
            .accessibilityIdentifier("\(prefix).hand.\(minutes ? "minutes" : "hours")")
            .accessibilityAddTraits(selected ? .isSelected : [])
            .overlay(alignment: .bottomTrailing) { if demonstratedAction == action { DinoClockTapCue() } }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: selected)
    }

    private func turnButton(direction: Int) -> some View {
        let minutes = allowsMinutes && adjustingMinutes
        let cue = demonstratedAction == .adjust(direction)
        return Button { adjust(direction) } label: {
            HStack(spacing: 6) {
                Image(systemName: direction < 0 ? "arrow.counterclockwise" : "arrow.clockwise")
                    .font(.system(size: 20, weight: .bold))
                Text(verbatim: "\(direction < 0 ? "−" : "+")\(minutes ? minuteStep : 1)")
                    .monospacedDigit()
            }
        }.buttonStyle(DinoClockControlButtonStyle(width: 118, height: 56))
            .accessibilityIdentifier("\(prefix).analog.\(direction < 0 ? "less" : "more")")
            .scaleEffect(cue && !reduceMotion ? 0.96 : 1)
            .overlay(alignment: .bottomTrailing) { if cue { DinoClockTapCue() } }
    }
}

struct DinoClockTapCue: View {
    var body: some View {
        Image(systemName: "hand.tap.fill")
            .font(.system(size: 25, weight: .bold)).foregroundStyle(DinoStyle.ink)
            .padding(8).background(.white, in: Circle())
            .overlay(Circle().stroke(DinoStyle.ink, lineWidth: 2))
            .offset(x: 13, y: 16)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Keep both faces in one stable layout. Inserting a second HStack child while
/// resizing the first face also animated its layout proposal, causing a flash.
struct AnalogClockAnswerComparison: View {
    @Environment(\.dinoClockReadingAssistance) private var readingAssistance
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let answer: ClockTime
    let target: ClockTime
    let theme: ClockTheme
    let width: CGFloat
    let clockSize: CGFloat
    let hasFeedback: Bool
    let correct: Bool
    var onHourChange: ((Int) -> Void)? = nil
    var onMinuteChange: ((ClockTime) -> Void)? = nil
    var minuteStep = 1
    var adjustingMinutes = false
    var onHandSelection: ((Bool) -> Void)? = nil

    private var comparing: Bool { hasFeedback && !correct }
    private var cellWidth: CGFloat { (width - 14) / 2 }
    private var comparisonScale: CGFloat { min(1, (cellWidth - 12) / (clockSize + 20), (stageHeight - 44) / (clockSize + 20)) }
    private var scale: CGFloat { comparing ? comparisonScale : 1 }
    private var stageHeight: CGFloat { clockSize + 20 }
    private var displacement: CGFloat { (width + 14) / 4 }
    private var sharedHintBounds: CGRect? {
        guard comparing && readingAssistance else { return nil }
        return ClockHandHintGeometry.bounds(time: answer, shape: theme.analogShape, faceSize: 150)
            .union(ClockHandHintGeometry.bounds(time: target, shape: theme.analogShape, faceSize: 150))
    }
    // Spend the reserved comparison stage on the faces and their actual arrows,
    // leaving one row underneath for the verdicts instead of scaling a square twice.
    private var hintHeight: CGFloat { sharedHintBounds == nil ? clockSize : (stageHeight - 44) / comparisonScale - 20 }
    private var hintWidth: CGFloat { (cellWidth - 20) / comparisonScale }

    var body: some View {
        ZStack {
            AnalogClock(time: answer, theme: theme, size: sharedHintBounds == nil ? clockSize : hintHeight,
                        onHourChange: onHourChange,
                        readingHintWidth: sharedHintBounds == nil ? nil : hintWidth,
                        readingHintBounds: sharedHintBounds,
                        onMinuteChange: onMinuteChange, minuteStep: minuteStep,
                        adjustingMinutes: adjustingMinutes, onHandSelection: onHandSelection)
                .frame(width: sharedHintBounds == nil ? nil : hintWidth,
                       height: sharedHintBounds == nil ? nil : hintHeight)
                .padding(10).modifier(ClockAnswerOutline(visible: hasFeedback, correct: correct))
                .scaleEffect(scale)
                .accessibilityIdentifier("question.analogControl")
                .offset(x: comparing ? -displacement : 0, y: comparing ? -22 : 0)
            AnalogClock(time: target, theme: theme, size: sharedHintBounds == nil ? clockSize : hintHeight,
                        readingHintWidth: sharedHintBounds == nil ? nil : hintWidth,
                        readingHintBounds: sharedHintBounds)
                .frame(width: sharedHintBounds == nil ? nil : hintWidth,
                       height: sharedHintBounds == nil ? nil : hintHeight)
                .padding(10)
                .modifier(ClockAnswerOutline(visible: true, correct: true))
                .scaleEffect(comparisonScale * (comparing || reduceMotion ? 1 : 0.94))
                .accessibilityIdentifier("question.correctClock")
                .offset(x: displacement, y: -22)
                .opacity(comparing ? 1 : 0).allowsHitTesting(false).accessibilityHidden(!comparing)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.16).delay(0.2), value: comparing)
            HStack(spacing: 14) {
                AnswerVerdictMark(correct: false).frame(maxWidth: .infinity)
                AnswerVerdictMark(correct: true).frame(maxWidth: .infinity)
            }
            .offset(y: stageHeight / 2 - 14)
            .opacity(comparing ? 1 : 0).accessibilityHidden(true)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16).delay(0.2), value: comparing)
        }
        .frame(width: width, height: stageHeight)
        .questionAnswerFocus()
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: comparing)
    }
}

/// Connect a face and a digital time with two taps or a drag, starting on either side.
struct ClockMatchingBoard: View {
    @Environment(\.dinoClockReadingAssistance) private var readingAssistance
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let times: [ClockTime]
    let options: [ClockTime]
    @Binding var selections: [Int: ClockTime]
    let theme: ClockTheme
    let width: CGFloat
    var hasFeedback = false
    var isDemonstration = false
    var availableHeight: CGFloat? = nil
    var horizontalLayout = false
    @State private var pending: Endpoint?
    @GestureState private var drag: ConnectionDrag?
    @State private var demonstrationStep = -1
    @State private var demonstrationStopped = false

    private enum Endpoint: Equatable {
        case clock(Int), time(Int)
    }
    private struct ConnectionDrag {
        let source: Endpoint
        let location: CGPoint
    }
    private var prefix: String { isDemonstration ? "demo.match" : "question.match" }
    private var leftWidth: CGFloat {
        horizontalLayout ? width / CGFloat(max(1, times.count)) - 24 : width * 0.42
    }
    private var rightWidth: CGFloat { leftWidth }
    private var faceSize: CGFloat {
        let preferred = horizontalLayout ? 184 : width >= 600 ? min(164, width * 0.25) : 104
        let fitted = availableHeight.map { height in
            horizontalLayout ? (height - connectionGap) / 2 - 24
                : (height - CGFloat(max(0, times.count - 1)) * spacing) / CGFloat(max(1, times.count)) - 24
        } ?? preferred
        return max(32, min(fitted, leftWidth - 18))
    }
    private var rowHeight: CGFloat { max(faceSize + 24, digitalHeight) }
    private var spacing: CGFloat { width >= 600 ? 12 : 16 }
    private var digitalFont: CGFloat {
        let heightLimit = horizontalLayout
            ? ((availableHeight ?? 480) - connectionGap) / 2 : .infinity
        return min(40, width * 0.067, max(14, (heightLimit - 20) / 1.7))
    }
    private var digitalHeight: CGFloat {
        digitalFont * 1.7 + 20 + (readingAssistance ? 48 * min(1, digitalFont / 30) : 0)
    }
    private var connectionGap: CGFloat { min(96, max(32, (availableHeight ?? 480) * 0.2)) }
    private var boardHeight: CGFloat {
        horizontalLayout ? rowHeight * 2 + connectionGap
            : CGFloat(times.count) * rowHeight + CGFloat(max(0, times.count - 1)) * spacing
    }

    var body: some View {
        VStack(spacing: 14) {
            if isDemonstration {
                Text("dino.match.hint")
                    .font(.system(size: width >= 600 ? 16 : 14, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: min(520, width - 24))
                    .frame(width: width)
                    .accessibilityIdentifier("\(prefix).hint")
            }
            ZStack {
                Canvas { context, _ in
                    for index in times.indices {
                        if let time = selections[index], let option = options.firstIndex(of: time) {
                            let color = hasFeedback ? (time == times[index] ? DinoStyle.deepGreen : DinoStyle.wrong(highContrast)) : linkColor(index)
                            context.stroke(line(from: index, to: option), with: .color(color),
                                           style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            if hasFeedback, time != times[index], let correct = options.firstIndex(of: times[index]) {
                                context.stroke(line(from: index, to: correct), with: .color(DinoStyle.deepGreen),
                                               style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [5, 4]))
                            }
                        }
                    }
                    if let drag {
                        let color: Color
                        switch drag.source {
                        case .clock(let index): color = linkColor(index)
                        case .time: color = DinoStyle.muted
                        }
                        let path = Path { path in
                            path.move(to: connectionPoint(for: drag.source))
                            path.addLine(to: drag.location)
                        }
                        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    }
                }.allowsHitTesting(false).accessibilityHidden(true)
                ForEach(times.indices, id: \.self) { index in
                    let frame = cardFrame(.clock(index))
                    clockButton(index).position(x: frame.midX, y: frame.midY)
                }
                ForEach(options.indices, id: \.self) { index in
                    let frame = cardFrame(.time(index))
                    timeButton(index).position(x: frame.midX, y: frame.midY)
                }
                ForEach(times.indices, id: \.self) { index in
                    if let time = selections[index], let option = options.firstIndex(of: time) {
                        let start = connectionPoint(for: .clock(index))
                        let end = connectionPoint(for: .time(option))
                        Color.clear.frame(width: 4, height: 4)
                            .position(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
                            .accessibilityIdentifier("\(prefix).line.\(index)")
                    }
                }.allowsHitTesting(false)
            }.frame(width: width, height: boardHeight)
                .coordinateSpace(name: "clockMatchingBoard")
        }.environment(\.layoutDirection, .leftToRight)
            .task {
                guard isDemonstration else { return }
                do {
                    try await Task.sleep(for: .seconds(0.8))
                    for index in times.indices {
                        guard !demonstrationStopped, let option = options.firstIndex(of: times[index]) else { return }
                        demonstrationStep = index * 2
                        pending = .clock(index)
                        try await Task.sleep(for: .seconds(1.2))
                        guard !demonstrationStopped else { return }
                        demonstrationStep += 1
                        try await Task.sleep(for: .seconds(0.7))
                        guard !demonstrationStopped else { return }
                        select(.time(option))
                        try await Task.sleep(for: .seconds(1.0))
                    }
                    demonstrationStep = times.count * 2
                } catch { return }
            }
    }

    private func clockButton(_ index: Int) -> some View {
        let selected = selections[index]
        let color = hasFeedback && selected != times[index] ? DinoStyle.wrong(highContrast) : linkColor(index)
        return Button { tapped(.clock(index)) } label: {
            AnalogClock(time: times[index], theme: theme, size: faceSize).allowsHitTesting(false)
                .frame(width: leftWidth, height: rowHeight)
                .background(.white, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected(.clock(index)) ? DinoStyle.ink : color,
                                                                                lineWidth: isSelected(.clock(index)) || selected != nil ? 3 : highContrast ? 2 : 0))
                .overlay(alignment: horizontalLayout ? .bottom : .trailing) {
                    connectionDot(selected == nil ? DinoStyle.muted : color)
                        .offset(x: horizontalLayout ? 0 : 4, y: horizontalLayout ? 4 : 0)
                }
                .overlay(alignment: .topTrailing) {
                    if isDemonstration, demonstrationStep == index * 2 { tapCue(1) }
                }
        }.buttonStyle(DinoAnswerButtonStyle()).disabled(hasFeedback)
            .highPriorityGesture(connectionDrag(from: .clock(index)))
            .accessibilityIdentifier("\(prefix).clock.\(index)")
    }

    private func timeButton(_ index: Int) -> some View {
        let owner = times.indices.first { selections[$0] == options[index] }
        let color = owner.map { hasFeedback && times[$0] != options[index] ? DinoStyle.wrong(highContrast) : linkColor($0) } ?? DinoStyle.muted
        return Button { tapped(.time(index)) } label: {
            DigitalClock(time: options[index], theme: theme, fontSize: digitalFont)
                .frame(width: rightWidth, height: rowHeight)
                .background(.white, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(isSelected(.time(index)) ? DinoStyle.ink : color,
                                                                                lineWidth: isSelected(.time(index)) || owner != nil ? 3 : highContrast ? 2 : 0))
                .overlay(alignment: horizontalLayout ? .top : .leading) {
                    connectionDot(color).offset(x: horizontalLayout ? 0 : -4, y: horizontalLayout ? -4 : 0)
                }
                .overlay(alignment: .topTrailing) {
                    if isDemonstration, demonstrationStep >= 0, !demonstrationStep.isMultiple(of: 2),
                       demonstrationStep / 2 < times.count, options[index] == times[demonstrationStep / 2] { tapCue(2) }
                }
        }.buttonStyle(DinoAnswerButtonStyle()).disabled(hasFeedback)
            .highPriorityGesture(connectionDrag(from: .time(index)))
            .accessibilityIdentifier("\(prefix).time.\(index)")
    }

    private func connectionDot(_ color: Color) -> some View {
        Circle().fill(color).frame(width: 9, height: 9).accessibilityHidden(true)
    }
    private func tapCue(_ number: Int) -> some View {
        HStack(spacing: 3) {
            Text(verbatim: "\(number)")
            Image(systemName: "hand.tap.fill")
        }.font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(DinoStyle.ink)
            .padding(6).background(DinoStyle.green, in: Capsule()).offset(x: 5, y: -8)
            .accessibilityHidden(true)
    }
    private func linkColor(_ index: Int) -> Color {
        Color(dinoHex: [0x377C95, 0x76539A, 0x27734C][index % 3])
    }
    private func rowY(_ index: Int) -> CGFloat { rowHeight / 2 + CGFloat(index) * (rowHeight + spacing) }
    private func isSelected(_ endpoint: Endpoint) -> Bool { pending == endpoint || drag?.source == endpoint }
    private func cardFrame(_ endpoint: Endpoint) -> CGRect {
        let index: Int
        let clock: Bool
        switch endpoint {
        case .clock(let value): index = value; clock = true
        case .time(let value): index = value; clock = false
        }
        if horizontalLayout {
            let centerX = width * (CGFloat(index) + 0.5) / CGFloat(max(1, times.count))
            return CGRect(x: centerX - leftWidth / 2, y: clock ? 0 : rowHeight + connectionGap,
                          width: leftWidth, height: rowHeight)
        }
        return CGRect(x: clock ? 0 : width - rightWidth, y: rowY(index) - rowHeight / 2,
                      width: leftWidth, height: rowHeight)
    }
    private func connectionPoint(for endpoint: Endpoint) -> CGPoint {
        let frame = cardFrame(endpoint)
        switch endpoint {
        case .clock: return horizontalLayout ? CGPoint(x: frame.midX, y: frame.maxY) : CGPoint(x: frame.maxX, y: frame.midY)
        case .time: return horizontalLayout ? CGPoint(x: frame.midX, y: frame.minY) : CGPoint(x: frame.minX, y: frame.midY)
        }
    }
    private func endpoint(at point: CGPoint) -> Endpoint? {
        for index in times.indices {
            if cardFrame(.clock(index)).contains(point) {
                return .clock(index)
            }
        }
        for index in options.indices {
            if cardFrame(.time(index)).contains(point) {
                return .time(index)
            }
        }
        return nil
    }
    private func pair(from source: Endpoint?, to destination: Endpoint) -> (Int, Int)? {
        switch (source, destination) {
        case (.clock(let clock), .time(let time)), (.time(let time), .clock(let clock)): return (clock, time)
        default: return nil
        }
    }
    private func connectionDrag(from source: Endpoint) -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .named("clockMatchingBoard"))
            .updating($drag) { value, state, _ in
                guard !hasFeedback else { return }
                state = ConnectionDrag(source: source, location: value.location)
            }
            .onChanged { _ in
                guard !hasFeedback else { return }
                demonstrationStopped = true
                demonstrationStep = -1
                pending = nil
            }
            .onEnded { value in
                guard !hasFeedback, let destination = endpoint(at: value.location),
                      let (clock, option) = pair(from: source, to: destination) else { return }
                connect(clock: clock, to: option)
            }
    }
    private func line(from clock: Int, to time: Int) -> Path {
        Path { path in
            path.move(to: connectionPoint(for: .clock(clock)))
            path.addLine(to: connectionPoint(for: .time(time)))
        }
    }
    private func tapped(_ endpoint: Endpoint) {
        demonstrationStopped = true
        demonstrationStep = -1
        select(endpoint)
    }
    private func select(_ endpoint: Endpoint) {
        let connectedClock: Int?
        switch endpoint {
        case .clock(let clock): connectedClock = selections[clock] == nil ? nil : clock
        case .time(let time): connectedClock = times.indices.first { selections[$0] == options[time] }
        }
        if let connectedClock {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                selections.removeValue(forKey: connectedClock)
                pending = nil
            }
            return
        }
        if pending == endpoint { pending = nil; return }
        guard let (clock, option) = pair(from: pending, to: endpoint) else { pending = endpoint; return }
        connect(clock: clock, to: option)
    }
    private func connect(clock: Int, to option: Int) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            for key in selections.keys.filter({ selections[$0] == options[option] }) { selections.removeValue(forKey: key) }
            selections[clock] = options[option]
            pending = nil
        }
    }
}

struct ClockAnswerOutline: ViewModifier {
    @Environment(\.dinoHighContrast) private var highContrast
    let visible: Bool
    let correct: Bool
    func body(content: Content) -> some View {
        content
            .background(.white.opacity(visible ? 0.8 : 0), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22)
                .stroke(correct ? (highContrast ? DinoStyle.deepGreen : DinoStyle.green) : DinoStyle.wrong(highContrast), lineWidth: visible ? 4 : 0))
    }
}

/// Light-green circle with a dark-blue check for a right answer, orange circle with a cross for a wrong one.
struct AnswerVerdictMark: View {
    @Environment(\.dinoHighContrast) private var highContrast
    var correct: Bool
    var size: CGFloat = 26

    var body: some View {
        Image(systemName: correct ? "checkmark" : "xmark")
            .font(.system(size: size * 0.46, weight: .black))
            .foregroundStyle(correct || !highContrast ? DinoStyle.ink : Color.white)
            .frame(width: size, height: size)
            .background(correct ? DinoStyle.green : DinoStyle.wrong(highContrast), in: Circle())
            .accessibilityHidden(true)
    }
}
