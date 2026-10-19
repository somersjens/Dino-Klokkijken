import SwiftUI
import UIKit

struct SpokenTimeQuestion: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @ObservedObject var session: DinoSession
    let theme: ClockTheme
    let width: CGFloat
    var isDemonstration = false
    var compact = false

    private var prompt: SpokenTimePrompt? { session.question.spokenPrompt }
    private var prefix: String { isDemonstration ? "demo" : "question" }

    var body: some View {
        VStack(spacing: 10) {
            if let prompt {
                clock
                sentence(prompt)
                VStack(spacing: 8) {
                    let fontSize = optionFontSize(for: prompt)
                    ForEach(Array(prompt.slots.enumerated()), id: \.element.id) { index, slot in
                        slotRow(slot, index: index, prompt: prompt, fontSize: fontSize)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white, in: RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(highContrast ? DinoStyle.ink.opacity(0.7) : DinoStyle.ink.opacity(0.08), lineWidth: highContrast ? 2 : 1.5))
                if !isDemonstration { confirm(prompt) }
            }
        }
        .id(isDemonstration ? "demo.spoken" : "question.answers")
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
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
            } else {
                Text(verbatim: text)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(showsAnswer && !isDemonstration ? DinoStyle.deepGreen : DinoStyle.ink)
                    .accessibilityIdentifier(isDemonstration ? "demo.answer" : showsAnswer ? "question.spoken.phrase" : "question.spoken.draft")
            }
        }
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.75)
        .frame(maxWidth: .infinity, minHeight: 28)
    }

    private var clock: some View {
        DigitalClock(time: session.question.target, theme: theme, fontSize: min(compact ? 36 : 46, width * 0.13))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(.white, in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(highContrast ? DinoStyle.ink : .white, lineWidth: highContrast ? 3 : 2))
            .accessibilityIdentifier("\(prefix).targetClock")
    }

    /// One size for every stone, small enough that the longest word still fits the narrowest row.
    private func optionFontSize(for prompt: SpokenTimePrompt) -> CGFloat {
        let titles = prompt.slots.flatMap(\.choices).map(buttonTitle)
        let longest = titles.max { Self.textWidth($0, size: 100) < Self.textWidth($1, size: 100) } ?? ""
        let columns = max(1, prompt.slots.map(\.choices.count).max() ?? 1)
        let buttonWidth = (width - 24 - 64 - 8 - CGFloat(columns - 1) * 6) / CGFloat(columns)
        let available = max(20, buttonWidth - 8 - 18)
        var size: CGFloat = 16
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
                .font(.system(size: 12, weight: .bold, design: .rounded))
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
            .frame(maxWidth: .infinity, minHeight: 40)
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

    private func confirm(_ prompt: SpokenTimePrompt) -> some View {
        Group {
            if !session.hidesAnswerControls {
                Button {
                    let ids = prompt.slots.indices.map { index -> String in
                        guard session.spokenChoices.indices.contains(index) else { return SpokenTimeChoice.emptyID }
                        return session.spokenChoices[index] ?? SpokenTimeChoice.emptyID
                    }
                    session.submit(.spoken(SpokenTimeAnswer(choiceIDs: ids)))
                } label: {
                    Image(systemName: "checkmark").font(.title2.bold())
                }
                .buttonStyle(DinoButtonStyle())
                .frame(maxWidth: 260)
                .allowsHitTesting(!session.hasFeedback)
                .accessibilityHidden(session.hasFeedback)
                .accessibilityIdentifier("question.confirm")
            }
        }
    }
}

