import SwiftUI

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
                    ForEach(Array(prompt.slots.enumerated()), id: \.element.id) { index, slot in
                        slotRow(slot, index: index, prompt: prompt)
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
        let face = min(compact ? 120 : 148, width * (compact ? 0.34 : 0.4))
        return HStack(spacing: 18) {
            AnalogClock(time: session.question.target, theme: theme, size: face)
                .accessibilityIdentifier("\(prefix).targetClock")
            DigitalClock(time: session.question.target, theme: theme, fontSize: min(40, width * 0.11))
                .accessibilityIdentifier("\(prefix).spoken.digital")
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .background(.white, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(highContrast ? DinoStyle.ink : .white, lineWidth: highContrast ? 3 : 2))
    }

    private func slotRow(_ slot: SpokenTimeSlot, index: Int, prompt: SpokenTimePrompt) -> some View {
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
                    choiceButton(choice, slot: index, choiceIndex: choiceIndex, prompt: prompt)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func choiceButton(_ choice: SpokenTimeChoice, slot: Int, choiceIndex: Int, prompt: SpokenTimePrompt) -> some View {
        let selectedID = selection(slot: slot, prompt: prompt)
        let selected = selectedID == choice.id
        let correctID = prompt.correct.choiceIDs[slot]
        let revealed = !isDemonstration && session.hasFeedback
        let showCorrect = isDemonstration || (revealed && choice.id == correctID)
        let showWrong = revealed && selected && choice.id != correctID
        let title = buttonTitle(choice)
        return Button {
            session.chooseSpoken(slot: slot, choiceID: choice.id)
        } label: {
            HStack(spacing: 4) {
                Text(verbatim: title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                if showWrong || showCorrect || (selected && !revealed) {
                    Image(systemName: showWrong ? "xmark" : "checkmark")
                        .font(.system(size: 11, weight: .heavy))
                }
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(DinoStyle.ink)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(chipFill(selected: selected, correct: showCorrect, wrong: showWrong), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(chipStroke(selected: selected, correct: showCorrect, wrong: showWrong),
                                                              lineWidth: selected || showCorrect || showWrong ? 2.5 : highContrast ? 2 : 1.5))
        }
        .buttonStyle(DinoAnswerButtonStyle())
        .allowsHitTesting(!isDemonstration && !session.hasFeedback)
        .accessibilityLabel(choice.id == SpokenTimeChoice.emptyID ? choice.accessibility : title)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("\(prefix).spoken.\(slot).\(choiceIndex)")
    }

    private func selection(slot: Int, prompt: SpokenTimePrompt) -> String? {
        if isDemonstration { return prompt.correct.choiceIDs[slot] }
        guard session.spokenChoices.indices.contains(slot) else { return nil }
        return session.spokenChoices[slot]
    }

    private func buttonTitle(_ choice: SpokenTimeChoice) -> String {
        if choice.id == SpokenTimeChoice.emptyID { return choice.word }
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
        let complete = prompt.slots.indices.allSatisfy { slot in
            session.spokenChoices.indices.contains(slot) && session.spokenChoices[slot] != nil
        }
        return Group {
            if !session.hidesAnswerControls {
                Button {
                    let ids = prompt.slots.indices.compactMap { index -> String? in
                        session.spokenChoices.indices.contains(index) ? session.spokenChoices[index] : nil
                    }
                    guard ids.count == prompt.slots.count else { return }
                    session.submit(.spoken(SpokenTimeAnswer(choiceIDs: ids)))
                } label: {
                    Image(systemName: "checkmark").font(.title2.bold())
                }
                .buttonStyle(DinoButtonStyle())
                .frame(maxWidth: 260)
                .disabled(!complete)
                .allowsHitTesting(!session.hasFeedback)
                .accessibilityHidden(session.hasFeedback)
                .accessibilityIdentifier("question.confirm")
            }
        }
    }
}

