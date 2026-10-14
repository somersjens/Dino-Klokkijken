import SwiftUI

struct QuestionRenderer: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var session: DinoSession
    @State private var adjustingMinutes = false
    let theme: ClockTheme
    let width: CGFloat
    let clockSize: CGFloat
    private var comparing: Bool { session.hasFeedback && !session.correctFeedback }
    private var question: ClockQuestion { session.question }
    private var targetSize: CGFloat { min(clockSize, width - 20) }

    var body: some View {
        VStack(spacing: 22) {
            switch question.kind {
            case .chooseAnalog, .activity:
                targetCard
                analogOptions
            case .chooseDigital:
                analogTarget
                digitalOptions
            case .setAnalog:
                targetCard
                analogInput.id("question.answers")
                if !session.hasFeedback {
                    if session.allowsMinutes {
                        Picker("dino.practice.hand", selection: $adjustingMinutes) {
                            Text("dino.hours").tag(false)
                            Text("dino.minutes").tag(true)
                        }.pickerStyle(.segmented).frame(maxWidth: 280)
                            .accessibilityIdentifier("question.hand")
                    }
                    HStack(spacing: 14) {
                        DinoIconButton(icon: "arrow.counterclockwise", labelKey: adjustingMinutes ? "dino.minuteLess" : "dino.hourLess") { adjustAnalog(by: -1) }
                            .accessibilityIdentifier("question.analog.less")
                        Image(systemName: "hand.draw.fill").font(.title2).foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                        DinoIconButton(icon: "arrow.clockwise", labelKey: adjustingMinutes ? "dino.minuteMore" : "dino.hourMore") { adjustAnalog(by: 1) }
                            .accessibilityIdentifier("question.analog.more")
                    }
                }
                confirmButton
            case .setDigital:
                analogTarget
                digitalInput.id("question.answers")
                confirmButton
            case .match:
                matchingBoard
                Image(systemName: "arrow.down").font(.system(size: 22, weight: .heavy)).foregroundStyle(DinoStyle.green)
                digitalOptions
            default:
                DinoExpandedQuestionView(session: session, theme: theme, width: width, clockSize: clockSize)
            }
        }.frame(maxWidth: .infinity)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.34), value: session.hasFeedback)
    }

    private var analogInput: some View {
        let cellWidth = (width - 14) / 2
        let scale = comparing ? min(1, (cellWidth - 12) / (targetSize + 20)) : 1
        let height = (targetSize + 20) * scale
        return HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 10) {
                AnalogClock(time: session.attempt.submittedAnswer ?? session.inputTime, theme: theme, size: targetSize,
                            onHourChange: session.hasFeedback || adjustingMinutes ? nil : { session.inputHour = $0 },
                            onMinuteChange: session.hasFeedback || !adjustingMinutes ? nil : { session.inputMinute = $0 },
                            minuteStep: session.minuteStep)
                    .accessibilityIdentifier("question.analogControl")
                    .padding(10).modifier(ClockAnswerOutline(visible: session.hasFeedback, correct: session.correctFeedback))
                    .scaleEffect(scale).frame(width: comparing ? cellWidth : width, height: height)
                if comparing { comparisonLabel(correct: false) }
            }
            if comparing {
                VStack(spacing: 10) {
                    AnalogClock(time: question.target, theme: theme, size: targetSize).padding(10)
                        .modifier(ClockAnswerOutline(visible: true, correct: true))
                        .scaleEffect(scale).frame(width: cellWidth, height: height)
                        .accessibilityIdentifier("question.correctClock")
                    comparisonLabel(correct: true)
                }.transition(reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity))
            }
        }.frame(width: width)
    }

    @ViewBuilder private var digitalInput: some View {
        if session.hasFeedback {
            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 10) {
                    DigitalClock(time: session.attempt.submittedAnswer ?? session.inputTime, theme: theme, fontSize: comparing ? min(28, width * 0.075) : 38)
                        .padding(8).modifier(ClockAnswerOutline(visible: true, correct: session.correctFeedback))
                        .accessibilityIdentifier("question.digitalControl")
                    if comparing { comparisonLabel(correct: false) }
                }.frame(maxWidth: .infinity)
                if comparing {
                    VStack(spacing: 10) {
                        DigitalClock(time: question.target, theme: theme, fontSize: min(28, width * 0.075))
                            .padding(8).modifier(ClockAnswerOutline(visible: true, correct: true))
                            .accessibilityIdentifier("question.correctClock")
                        comparisonLabel(correct: true)
                    }.frame(maxWidth: .infinity)
                        .transition(reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity))
                }
            }
        } else {
            DigitalClockControl(hour: $session.inputHour, theme: theme, minute: session.inputMinute, fontSize: width < 350 ? 32 : 38,
                                onMinuteChange: session.allowsMinutes ? { session.inputMinute = $0 } : nil,
                                minuteStep: session.minuteStep, valueIdentifier: "question.digitalControl")
        }
    }

    private func comparisonLabel(correct: Bool) -> some View {
        Label(LocalizedStringKey(correct ? "dino.correctTime" : "dino.yourAnswer"), systemImage: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(correct ? DinoStyle.deepGreen : Color(dinoHex: 0xB54343))
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
    }

    private var targetCard: some View {
        VStack(spacing: 10) {
            if let activity = question.activity {
                Label(LocalizedStringKey(activity.titleKey), systemImage: activity.symbol)
                    .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(DinoStyle.deepGreen)
            }
            clockStage(height: 64) {
                DigitalClock(time: question.target, theme: theme, fontSize: width < 350 ? 32 : 38)
                    .accessibilityIdentifier("question.targetClock")
            }
        }
    }

    private var analogTarget: some View {
        clockStage(height: targetSize) {
            AnalogClock(time: question.target, theme: theme, size: targetSize)
                .accessibilityIdentifier("question.targetClock")
        }
    }

    private func clockStage<Content: View>(height: CGFloat,
                                          @ViewBuilder content: () -> Content) -> some View {
        content().frame(width: width, height: height)
    }

    private var analogOptions: some View {
        let columns = 2
        let size = min(150, (width - CGFloat(columns - 1) * 12) / CGFloat(columns) - 18)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns), spacing: 14) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                answerButton(option: option, index: index) {
                    AnalogClock(time: option, theme: theme, size: size).allowsHitTesting(false).padding(8)
                }
            }
        }.id("question.answers")
    }

    private var digitalOptions: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 14) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                answerButton(option: option, index: index) {
                    DigitalClock(time: option, theme: theme, fontSize: width < 350 ? 25 : 31)
                        .padding(.vertical, 14).frame(maxWidth: .infinity)
                }
            }
        }.id("question.answers")
    }

    private var matchingBoard: some View {
        VStack(spacing: 8) {
            clockStage(height: 120) {
                VStack(spacing: 6) {
                    AnalogClock(time: question.target, theme: theme, size: 94).allowsHitTesting(false)
                        .accessibilityIdentifier("question.targetClock")
                    Image(systemName: "arrow.up.circle.fill").foregroundStyle(DinoStyle.green).font(.system(size: 20))
                }.padding(9).background(.white, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(DinoStyle.green, lineWidth: 3))
            }
            HStack(spacing: 110) {
                ForEach(question.companionClocks, id: \.self) { time in
                    AnalogClock(time: time, theme: theme, size: 52).allowsHitTesting(false)
                        .padding(4).background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 15)).opacity(0.6)
                }
            }
        }.environment(\.layoutDirection, .leftToRight)
    }

    private var confirmButton: some View {
        Group {
            if !session.hasFeedback {
                Button { session.submit(session.inputTime) } label: {
                    Image(systemName: "checkmark").font(.system(size: 25, weight: .heavy))
                }.buttonStyle(DinoButtonStyle()).frame(maxWidth: 260)
                    .accessibilityLabel(Text("dino.confirm")).accessibilityIdentifier("question.confirm")
            }
        }
    }

    private func adjustAnalog(by direction: Int) {
        if adjustingMinutes { session.inputMinute = ClockTime.shiftedMinute(session.inputMinute, by: direction * session.minuteStep) }
        else { session.inputHour = ClockTime.shiftedHour(session.inputHour, by: direction) }
    }

    private func answerButton<Content: View>(option: ClockTime, index: Int, @ViewBuilder content: () -> Content) -> some View {
        let correct = session.hasFeedback && option == question.target
        let wrong = session.hasFeedback && option == session.attempt.submittedAnswer && !correct
        return Button { session.submit(option) } label: {
            content().frame(maxWidth: .infinity)
                .background(.white, in: RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(correct ? (highContrast ? DinoStyle.deepGreen : DinoStyle.green) : wrong ? Color(dinoHex: 0xC65A59) : DinoStyle.ink.opacity(highContrast ? 1 : 0.1), lineWidth: correct || wrong ? 4 : highContrast ? 3 : 1.5))
                .overlay(alignment: .topTrailing) {
                    if correct || wrong {
                        Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 24, weight: .bold)).foregroundStyle(correct ? (highContrast ? DinoStyle.deepGreen : DinoStyle.green) : Color(dinoHex: 0xC65A59))
                            .background(.white, in: Circle()).offset(x: 5, y: -5)
                    }
                }.shadow(color: DinoStyle.ink.opacity(0.06), radius: 7, y: 4)
                .opacity(!highContrast && session.hasFeedback && !correct && !wrong ? 0.55 : 1)
        }.buttonStyle(DinoAnswerButtonStyle()).disabled(session.hasFeedback).accessibilityIdentifier("question.option.\(index)")
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
                .stroke(correct ? (highContrast ? DinoStyle.deepGreen : DinoStyle.green) : Color(dinoHex: 0xC65A59), lineWidth: visible ? 4 : 0))
    }
}
