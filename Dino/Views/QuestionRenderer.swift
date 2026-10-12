import SwiftUI

struct QuestionRenderer: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @ObservedObject var session: DinoSession
    let theme: ClockTheme
    let width: CGFloat
    let clockSize: CGFloat
    private var question: ClockQuestion { session.question }
    private var dinoSize: CGFloat { min(140, width * 0.34) }
    private var targetSize: CGFloat { min(clockSize, width - dinoSize * 1.42) }

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
                clockStage(height: targetSize) {
                    AnalogClock(time: ClockTime(hour: session.inputHour), theme: theme, size: targetSize,
                                onHourChange: session.hasFeedback ? nil : { session.inputHour = $0 })
                        .accessibilityIdentifier("question.analogControl")
                }.id("question.answers")
                HStack(spacing: 14) {
                    DinoIconButton(icon: "arrow.counterclockwise", labelKey: "dino.hourLess") {
                        session.inputHour = ClockTime.shiftedHour(session.inputHour, by: -1)
                    }
                    Image(systemName: "hand.draw.fill").font(.title2).foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                    DinoIconButton(icon: "arrow.clockwise", labelKey: "dino.hourMore") {
                        session.inputHour = ClockTime.shiftedHour(session.inputHour, by: 1)
                    }
                }.disabled(session.hasFeedback)
                confirmButton
            case .setDigital:
                analogTarget
                DigitalClockControl(hour: $session.inputHour, theme: theme, fontSize: width < 350 ? 32 : 38)
                    .disabled(session.hasFeedback)
                    .id("question.answers")
                confirmButton
            case .match:
                matchingBoard
                Image(systemName: "arrow.down").font(.system(size: 22, weight: .heavy)).foregroundStyle(DinoStyle.green)
                digitalOptions
            }
        }.frame(maxWidth: .infinity)
            .animation(.easeInOut(duration: 0.2), value: session.hasFeedback)
    }

    private var targetCard: some View {
        VStack(spacing: 10) {
            if let activity = question.activity {
                Label(LocalizedStringKey(activity.titleKey), systemImage: activity.symbol)
                    .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(DinoStyle.deepGreen)
            }
            clockStage(height: 64, showsDino: question.kind != .setAnalog) {
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

    /// The clock owns the center. The fixed companion overlay never participates in layout.
    private func clockStage<Content: View>(height: CGFloat, showsDino: Bool = true,
                                          @ViewBuilder content: () -> Content) -> some View {
        content().frame(width: width, height: showsDino ? max(height, dinoSize) : height)
            .overlay(alignment: .trailing) {
                if showsDino && !(session.hasFeedback && !session.correctFeedback) {
                    DinoCompanionAnchor(placement: .game, size: dinoSize)
                        .offset(x: dinoSize * 0.18).allowsHitTesting(false).transition(.identity)
                }
            }
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
        Button { session.submit(ClockTime(hour: session.inputHour)) } label: {
            Image(systemName: "checkmark").font(.system(size: 25, weight: .heavy))
        }.buttonStyle(DinoButtonStyle()).frame(maxWidth: 260).disabled(session.hasFeedback)
            .accessibilityLabel(Text("dino.confirm")).accessibilityIdentifier("question.confirm")
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
