import SwiftUI
import UIKit

/// Only examples show the complete phrase ring. Live questions keep their answer stones.
struct DinoTimeReadingClock: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let time: ClockTime
    let theme: ClockTheme
    let width: CGFloat
    let faceSize: CGFloat
    let language: String
    var showsGuide = false
    var showsSpokenHint = false

    private var prefix: String { showsGuide ? "demo" : "question" }
    private var hasLabels: Bool { showsGuide }
    private var diameter: CGFloat {
        hasLabels ? width * 0.34 : showsSpokenHint ? min(width - 16, max(300, faceSize)) : min(faceSize, width - 52)
    }
    private var height: CGFloat {
        if hasLabels { return width * 1.14 }
        if showsSpokenHint {
            let face = diameter / (SpokenClockGuideLayout.extent(shape: theme.analogShape) * 2)
            let bounds = SpokenClockGuideLayout.verticalBounds(minute: time.minute, language: language,
                                                               shape: theme.analogShape, faceSize: face)
            return face * (bounds.upperBound - bounds.lowerBound) + 16
        }
        return diameter + 24
    }
    private var center: CGPoint { CGPoint(x: width / 2, y: hasLabels ? width * 0.59 : height / 2) }
    private var labelTimes: [ClockTime] {
        stride(from: 0, to: 60, by: 5).map { ClockTime(hour: time.hour, minute: $0) }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                if hasLabels { guideLines.transition(.opacity) }
                AnalogClock(time: time, theme: theme, size: diameter,
                            spokenHintLanguage: showsSpokenHint && !hasLabels ? language : nil)
                    .position(center)
                    .accessibilityIdentifier("\(prefix).targetClock")
                if hasLabels {
                    ForEach(labelTimes, id: \.self) { labelTime in
                        guideLabel(labelTime.minute)
                            .transition(.opacity)
                    }
                }
            }
            .frame(width: width, height: height)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(prefix).timeReading.clock")
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: hasLabels)
    }

    private func labelCenter(_ minute: Int) -> CGPoint {
        let points: [CGPoint] = [
            .init(x: 0.50, y: 0.11), .init(x: 0.76, y: 0.25), .init(x: 0.90, y: 0.41),
            .init(x: 0.90, y: 0.59), .init(x: 0.90, y: 0.77), .init(x: 0.76, y: 0.93),
            .init(x: 0.50, y: 1.07), .init(x: 0.24, y: 0.93), .init(x: 0.10, y: 0.77),
            .init(x: 0.10, y: 0.59), .init(x: 0.10, y: 0.41), .init(x: 0.24, y: 0.25)
        ]
        let point = points[DinoTimeReading.labelPosition(minute: minute) / 5]
        return CGPoint(x: point.x * width, y: point.y * width)
    }

    private func labelWidth(_ minute: Int) -> CGFloat {
        width * ([10, 15, 20, 40, 45, 50].contains(DinoTimeReading.labelPosition(minute: minute)) ? 0.20 : 0.25)
    }

    private func guideLabel(_ minute: Int) -> some View {
        let phrase = DinoTimeWords.time(ClockTime(hour: time.hour, minute: minute), language: language)
        let color = ink(minute)
        let selected = time.minute == minute
        let border = color.opacity(selected || highContrast ? 1 : 0.28)
        let background = color.opacity(highContrast ? 0.10 : 0.08)
        return Text(verbatim: phrase)
            .font(.system(size: max(10, min(16, width * 0.037)), weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .lineLimit(3).minimumScaleFactor(0.75)
            .padding(.horizontal, 4)
            .frame(width: labelWidth(minute), height: width * 0.14)
            .background(background, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(border, lineWidth: selected ? 2.5 : 1))
            .position(labelCenter(minute))
            .accessibilityIdentifier(showsGuide && selected ? "demo.answer" : "\(prefix).timeReading.label.\(minute)")
    }

    private var guideLines: some View {
        Canvas { context, _ in
            func positioned(_ point: CGPoint) -> CGPoint {
                CGPoint(x: center.x + point.x * diameter, y: center.y + point.y * diameter)
            }
            for labelTime in labelTimes {
                let minute = labelTime.minute
                let count = SpokenClockReadingHint(minute: minute, language: language).scaleLabel
                let text = Text(verbatim: count)
                    .font(.system(size: SpokenClockGuideLayout.scaleFontSize(faceSize: diameter), weight: .bold, design: .rounded))
                    .monospacedDigit().canvasInk(DinoStyle.ink)
                let resolved = context.resolve(text)
                let measured = resolved.measure(in: CGSize(width: diameter * 2, height: diameter))
                let mark = ClockHandHintGeometry.minuteMark(minute: minute, shape: theme.analogShape,
                    labelSize: CGSize(width: measured.width / diameter, height: measured.height / diameter), gap: max(2 / diameter, 0.018))
                let countCenter = positioned(mark.label)
                let phraseCenter = labelCenter(minute)
                let direction = CGPoint(x: phraseCenter.x - countCenter.x, y: phraseCenter.y - countCenter.y)
                // Two separate strokes leave the scale text and phrase bubble clear.
                let start = ClockHandHintGeometry.labelCenter(from: countCenter, toward: direction, labelSize: measured, gap: 2)
                let end = ClockHandHintGeometry.labelCenter(from: phraseCenter,
                    toward: CGPoint(x: -direction.x, y: -direction.y),
                    labelSize: CGSize(width: labelWidth(minute), height: width * 0.14), gap: 1)
                var connector = Path()
                connector.move(to: start); connector.addLine(to: end)
                context.stroke(connector, with: .color(DinoStyle.ink.opacity(0.45)), lineWidth: 1.2)
                var tick = Path()
                tick.move(to: positioned(mark.tickStart)); tick.addLine(to: positioned(mark.tickEnd))
                context.stroke(tick, with: .color(DinoStyle.ink), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                context.draw(resolved, at: countCenter)
            }
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }

    private func ink(_ minute: Int) -> Color {
        return regionInk(minute)
    }

    private func regionInk(_ minute: Int) -> Color {
        let hex: UInt32
        switch DinoTimeReading.region(minute: minute, language: language) {
        case .whole: hex = 0x287A21
        case .past: hex = 0x0757B8
        case .beforeHalf: hex = 0x7940AD
        case .half: hex = 0xAC285A
        case .afterHalf: hex = 0x08756D
        case .to: hex = 0xB84D0A
        }
        return Color(dinoHex: hex)
    }
}

struct SpokenTimeQuestion: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @ObservedObject var session: DinoSession
    let theme: ClockTheme
    let width: CGFloat
    var isDemonstration = false
    var compact = false
    var wideLayout = false

    private var prompt: SpokenTimePrompt? { session.question.spokenPrompt }
    private var prefix: String { isDemonstration ? "demo" : "question" }
    private var wordBankWidth: CGFloat { width }
    private var tablet: Bool { width >= 600 }

    var body: some View {
        VStack(spacing: tablet ? (compact ? 8 : 12) : 10) {
            if let prompt {
                clock
                sentence(prompt)
                wordBank(prompt)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .id(isDemonstration ? "demo.spoken" : "question.answers")
    }

    private func wordBank(_ prompt: SpokenTimePrompt) -> some View {
        VStack(spacing: tablet && compact ? 6 : 8) {
            let fontSize = optionFontSize(for: prompt)
            ForEach(Array(prompt.slots.enumerated()), id: \.element.id) { index, slot in
                slotRow(slot, index: index, prompt: prompt, fontSize: fontSize)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, tablet ? (compact ? 8 : 12) : 10)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(highContrast ? DinoStyle.ink.opacity(0.7) : DinoStyle.ink.opacity(0.08), lineWidth: highContrast ? 2 : 1.5))
    }

    /// The hint stays until a word is chosen. From then on this line is the sentence so far.
    private func sentence(_ prompt: SpokenTimePrompt) -> some View {
        let showsAnswer = isDemonstration || (session.hasFeedback && !session.correctFeedback)
        let draft = prompt.phrase(for: SpokenTimeAnswer(choiceIDs: prompt.slots.indices.map { slot in
            selection(slot: slot, prompt: prompt) ?? SpokenTimeChoice.emptyID
        }))
        let text = showsAnswer ? prompt.phrase : draft
        return Group {
            if text.isEmpty {
                Text("dino.spoken.hint")
                    .font(.system(size: tablet ? 17 : 15, weight: .medium, design: .rounded))
                    .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
            } else {
                Text(verbatim: text)
                    .font(.system(size: tablet ? 24 : 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(showsAnswer && !isDemonstration ? DinoStyle.deepGreen : DinoStyle.ink)
                    .accessibilityIdentifier(isDemonstration ? "demo.answer" : showsAnswer ? "question.spoken.phrase" : "question.spoken.draft")
            }
        }
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.75)
        .frame(maxWidth: .infinity, minHeight: tablet ? (compact ? 32 : 40) : 56, maxHeight: tablet ? (compact ? 32 : 40) : 56)
        .questionAnswerFocus()
    }

    private var clock: some View {
        DigitalClock(time: session.question.target, theme: theme, fontSize: min(tablet ? (compact ? 38 : 46) : compact ? 36 : 46, width * 0.13))
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("\(prefix).targetClock")
    }

    /// One size for every stone, small enough that the longest word still fits the narrowest row.
    private func optionFontSize(for prompt: SpokenTimePrompt) -> CGFloat {
        let titles = prompt.slots.flatMap(\.choices).map(buttonTitle)
        let longest = titles.max { Self.textWidth($0, size: 100) < Self.textWidth($1, size: 100) } ?? ""
        let columns = max(1, prompt.slots.map(\.choices.count).max() ?? 1)
        let buttonWidth = (wordBankWidth - 24 - 64 - 8 - CGFloat(columns - 1) * 6) / CGFloat(columns)
        let available = max(20, buttonWidth - 8 - 18)
        var size: CGFloat = tablet ? (compact ? 18 : 20) : 16
        while size > 10, Self.textWidth(longest, size: size) > available { size -= 0.5 }
        return size
    }

    private static func textWidth(_ text: String, size: CGFloat) -> CGFloat {
        let base = UIFont.systemFont(ofSize: size, weight: .bold)
        let font = base.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: size) } ?? base
        return (text as NSString).size(withAttributes: [.font: font]).width
    }

    private func slotRow(_ slot: SpokenTimeSlot, index: Int, prompt: SpokenTimePrompt, fontSize: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(verbatim: slot.title)
                .font(.system(size: tablet ? 14 : 12, weight: .bold, design: .rounded))
                .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 64, alignment: .leading)
                .accessibilityIdentifier("\(prefix).spoken.slot.\(index)")
            HStack(spacing: 6) {
                ForEach(Array(slot.choices.enumerated()), id: \.element.id) { choiceIndex, choice in
                    choiceButton(choice, slot: index, choiceIndex: choiceIndex, prompt: prompt, fontSize: fontSize)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func choiceButton(_ choice: SpokenTimeChoice, slot: Int, choiceIndex: Int, prompt: SpokenTimePrompt, fontSize: CGFloat) -> some View {
        let selectedID = selection(slot: slot, prompt: prompt)
        let selected = selectedID == choice.id
        let correctID = prompt.correct.choiceIDs[slot]
        let revealed = !isDemonstration && session.hasFeedback
        let missed = revealed && !session.correctFeedback
        let showCorrect = isDemonstration
            ? choice.id == correctID && correctID != SpokenTimeChoice.emptyID
            : session.correctFeedback
                ? selected
                : missed && choice.id == correctID && correctID != SpokenTimeChoice.emptyID
        let showWrong = missed && selected && choice.id != correctID
        let title = buttonTitle(choice)
        return Button {
            session.chooseSpoken(slot: slot, choiceID: choice.id)
        } label: {
            HStack(spacing: 4) {
                Text(verbatim: title)
                    .lineLimit(1)
                if showWrong || showCorrect || (selected && !revealed) {
                    Image(systemName: showWrong ? "xmark" : "checkmark")
                        .font(.system(size: fontSize * 0.7, weight: .heavy))
                }
            }
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundStyle(DinoStyle.ink)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .frame(height: tablet && !compact ? 48 : 40)
            .background(chipFill(selected: selected, correct: showCorrect, wrong: showWrong), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(chipStroke(selected: selected, correct: showCorrect, wrong: showWrong),
                                                              lineWidth: selected || showCorrect || showWrong ? 2.5 : highContrast ? 2 : 1.5))
        }
        .buttonStyle(DinoAnswerButtonStyle())
        .allowsHitTesting(!isDemonstration && !session.hasFeedback)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("\(prefix).spoken.\(slot).\(choiceIndex)")
    }

    private func selection(slot: Int, prompt: SpokenTimePrompt) -> String? {
        if isDemonstration {
            let correct = prompt.correct.choiceIDs[slot]
            return correct == SpokenTimeChoice.emptyID ? nil : correct
        }
        guard session.spokenChoices.indices.contains(slot) else { return nil }
        return session.spokenChoices[slot]
    }

    private func buttonTitle(_ choice: SpokenTimeChoice) -> String {
        guard let first = choice.word.first else { return choice.word }
        return String(first).uppercased() + choice.word.dropFirst()
    }

    private func chipFill(selected: Bool, correct: Bool, wrong: Bool) -> Color {
        if wrong { return DinoStyle.wrong(highContrast).opacity(0.28) }
        if selected || correct { return DinoStyle.green.opacity(highContrast ? 0.45 : 0.32) }
        return .white
    }

    private func chipStroke(selected: Bool, correct: Bool, wrong: Bool) -> Color {
        if wrong { return DinoStyle.wrong(highContrast) }
        if selected || correct { return DinoStyle.deepGreen }
        return DinoStyle.ink.opacity(highContrast ? 0.8 : 0.16)
    }

}

