import SwiftUI
import UIKit

/// The same minute positions explain the complete hour in the example and
/// mark rejected answers beside the live face, without revealing digital times.
struct DinoTimeReadingClock: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let time: ClockTime
    let theme: ClockTheme
    let width: CGFloat
    let faceSize: CGFloat
    let language: String
    var showsGuide = false
    var rejectedTimes: [ClockTime] = []

    private var prefix: String { showsGuide ? "demo" : "question" }
    private var diameter: CGFloat { showsGuide ? width * 0.46 : min(faceSize, width - 52) }
    private var height: CGFloat { showsGuide ? width * 1.14 : diameter + 52 }
    private var center: CGPoint { CGPoint(x: width / 2, y: showsGuide ? width * 0.59 : height / 2) }
    private var minutes: [Int] { Array(stride(from: 0, to: 60, by: 5)) }

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                if showsGuide { guideLines }
                AnalogClock(time: time, theme: theme, size: diameter)
                    .position(center)
                    .accessibilityIdentifier("\(prefix).targetClock")
                if showsGuide {
                    ForEach(minutes, id: \.self) { minute in
                        guideLabel(minute)
                    }
                    if !time.minute.isMultiple(of: 5) {
                        Circle().fill(ink(time.minute)).frame(width: 10, height: 10)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                            .position(mark(time.minute))
                            .accessibilityHidden(true)
                    }
                } else {
                    ForEach(rejectedTimes.sorted { $0.minute < $1.minute }, id: \.self) { rejected in
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 21, height: 21)
                            .background(Color(dinoHex: highContrast ? 0xB54708 : 0xF07818), in: Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                            .position(mark(rejected.minute))
                            .accessibilityLabel(Text(verbatim: "\(DinoTimeWords.time(rejected, language: language)): \(L(key: "dino.expanded.false"))"))
                            .accessibilityIdentifier("question.timeReading.rejected.\(rejected.minute)")
                    }
                }
            }
            .frame(width: width, height: height)
            if showsGuide && !time.minute.isMultiple(of: 5) {
                Text(verbatim: DinoTimeWords.time(time, language: language))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(ink(time.minute))
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("demo.answer")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(prefix).timeReading.clock")
    }

    private func mark(_ minute: Int) -> CGPoint {
        let angle = Double(minute) * 6
        let radius = ClockHandHintGeometry.outerRadius(angle: angle, shape: theme.analogShape) * diameter + (showsGuide ? 9 : 15)
        let offset = ClockHandHintGeometry.point(radius: radius, angle: angle)
        return CGPoint(x: center.x + offset.x, y: center.y + offset.y)
    }

    private func labelCenter(_ minute: Int) -> CGPoint {
        let points: [CGPoint] = [
            .init(x: 0.50, y: 0.11), .init(x: 0.76, y: 0.25), .init(x: 0.885, y: 0.41),
            .init(x: 0.885, y: 0.59), .init(x: 0.885, y: 0.77), .init(x: 0.76, y: 0.93),
            .init(x: 0.50, y: 1.07), .init(x: 0.24, y: 0.93), .init(x: 0.115, y: 0.77),
            .init(x: 0.115, y: 0.59), .init(x: 0.115, y: 0.41), .init(x: 0.24, y: 0.25)
        ]
        let point = points[minute / 5]
        return CGPoint(x: point.x * width, y: point.y * width)
    }

    private func labelWidth(_ minute: Int) -> CGFloat {
        width * ([10, 15, 20, 40, 45, 50].contains(minute) ? 0.23 : 0.25)
    }

    private func guideLabel(_ minute: Int) -> some View {
        let phrase = DinoTimeWords.time(ClockTime(hour: time.hour, minute: minute), language: language)
        let color = ink(minute)
        let selected = time.minute == minute
        return Text(verbatim: phrase)
            .font(.system(size: max(10, min(16, width * 0.037)), weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .lineLimit(3).minimumScaleFactor(0.75)
            .padding(.horizontal, 4)
            .frame(width: labelWidth(minute), height: width * 0.14)
            .background(color.opacity(highContrast ? 0.10 : 0.08), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(selected || highContrast ? 1 : 0.28), lineWidth: selected ? 2.5 : 1))
            .position(labelCenter(minute))
            .accessibilityIdentifier(selected ? "demo.answer" : "demo.timeReading.label.\(minute)")
    }

    private var guideLines: some View {
        Canvas { context, _ in
            // Sample each minute so the colored regions follow square and
            // octagonal player clocks as well as round ones.
            for minute in 0..<60 {
                var sector = Path()
                for step in 0...4 {
                    let angle = (Double(minute) - 0.5 + Double(step) / 4) * 6
                    let radius = ClockHandHintGeometry.outerRadius(angle: angle, shape: theme.analogShape) * diameter + 6
                    let offset = ClockHandHintGeometry.point(radius: radius, angle: angle)
                    let point = CGPoint(x: center.x + offset.x, y: center.y + offset.y)
                    if step == 0 { sector.move(to: point) } else { sector.addLine(to: point) }
                }
                context.stroke(sector, with: .color(ink(minute).opacity(0.16)), lineWidth: 12)
            }
            for minute in minutes {
                let dot = mark(minute)
                let label = labelCenter(minute)
                let dx = dot.x - label.x, dy = dot.y - label.y
                // Stop at the bubble edge, keeping the connector out of the words.
                let fraction = min((labelWidth(minute) / 2 + 1) / max(0.001, abs(dx)),
                                   (width * 0.07 + 1) / max(0.001, abs(dy)))
                var line = Path()
                line.move(to: dot)
                line.addLine(to: CGPoint(x: label.x + dx * fraction, y: label.y + dy * fraction))
                context.stroke(line, with: .color(ink(minute).opacity(0.5)), lineWidth: 1.5)
                let rect = CGRect(x: dot.x - 5, y: dot.y - 5, width: 10, height: 10)
                context.fill(Path(ellipseIn: rect.insetBy(dx: -1.5, dy: -1.5)), with: .color(.white))
                context.fill(Path(ellipseIn: rect), with: .color(ink(minute)))
            }
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }

    private func ink(_ minute: Int) -> Color {
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

