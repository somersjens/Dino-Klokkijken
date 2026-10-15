import SwiftUI

struct DinoExpandedQuestionView: View {
    @ObservedObject var session: DinoSession
    @ObservedObject private var language = LanguageManager.shared
    let theme: ClockTheme
    let width: CGFloat
    let clockSize: CGFloat
    var isDemonstration = false
    @State private var movingMinutes = false
    private var q: ClockQuestion { session.question }
    private var code: String { language.effective.code }
    private var duration: String { DinoTimeWords.duration(q.durationMinutes, language: code) }

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 12) { context }
                .frame(maxWidth: min(600, width))
                .frame(maxWidth: .infinity)
            switch q.kind {
            case .sortTimes: sorting
            case .advanceAnalog: analogAdvance
            default:
                if isDemonstration { demonstrationAnswer }
                else { responses }
            }
        }.frame(width: width).multilineTextAlignment(.center)
    }

    @ViewBuilder private var context: some View {
        switch q.kind {
        case .readDigital, .read24Hour, .dayPart:
            DigitalClock(time: q.target, theme: theme, fontSize: 38)
                .accessibilityIdentifier(isDemonstration ? "demo.targetClock" : "question.targetClock")
        case .spokenTime:
            EmptyView()
        case .trueFalse:
            AnalogClock(time: q.target, theme: theme, size: min(180, clockSize))
                .accessibilityIdentifier(isDemonstration ? "demo.targetClock" : "question.targetClock")
        case .sortTimes:
            Text("dino.expanded.sameDay").font(.subheadline).multilineTextAlignment(.center)
        case .timeSequence:
            HStack(spacing: 6) {
                ForEach(Array(q.relatedTimes.enumerated()), id: \.offset) { index, time in
                    DigitalClock(time: time, theme: theme, fontSize: width < 340 ? 16 : 19)
                    if index < 2 { Image(systemName: "arrow.right").font(.caption.bold()) }
                }
                Text("?").font(.title2.bold())
            }.frame(maxWidth: .infinity)
            if !isDemonstration { Text("dino.expanded.midnightHint").font(.footnote).multilineTextAlignment(.center) }
        case .elapsedTime:
            HStack(spacing: 12) {
                timeCard(q.relatedTimes[0], title: "dino.expanded.start")
                Image(systemName: "arrow.right").foregroundStyle(DinoStyle.deepGreen)
                timeCard(q.relatedTimes[1], title: "dino.expanded.end")
            }
            if !isDemonstration { Text("dino.expanded.midnightHint").font(.footnote).multilineTextAlignment(.center) }
        case .timeZone:
            timeCard(q.relatedTimes[0], title: "dino.expanded.cityA")
            if q.offsetHours == 0 { Text("dino.expanded.sameZone") }
            else {
                Text(verbatim: "\(L("dino.expanded.cityB")): \(DinoTimeWords.duration(abs(q.offsetHours) * 60, language: code)) \(L(key: q.offsetHours > 0 ? "dino.expanded.later" : "dino.expanded.earlier"))")
            }
            if !isDemonstration { Text("dino.expanded.givenOffset").font(.footnote).multilineTextAlignment(.center) }
        case .addTime, .advanceAnalog, .schoolEnd, .flightArrival, .subtractTime:
            if q.kind == .schoolEnd { Label("dino.expanded.school", systemImage: "book.fill").font(.headline) }
            if q.kind == .flightArrival { Label("dino.expanded.flight", systemImage: "airplane").font(.headline) }
            if q.kind == .addTime { Label("dino.expanded.playground", systemImage: "figure.play").font(.headline) }
            timeCard(q.relatedTimes[0], title: q.kind == .flightArrival ? "dino.expanded.departure" : "dino.expanded.start")
            Label {
                Text(verbatim: "\(duration) \(L(key: q.kind == .subtractTime ? "dino.expanded.earlier" : "dino.expanded.later"))")
            } icon: { Image(systemName: q.kind == .subtractTime ? "minus.circle.fill" : "plus.circle.fill") }
                .font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(DinoStyle.deepGreen)
            if !isDemonstration {
                Text(LocalizedStringKey(q.kind == .flightArrival ? "dino.expanded.flightZone" : "dino.expanded.midnightHint"))
                    .font(.footnote).multilineTextAlignment(.center)
            }
        default:
            // SwiftUI can update an outgoing view after the shared session has advanced.
            EmptyView()
        }
    }

    private func timeCard(_ time: ClockTime, title: String) -> some View {
        VStack(spacing: 8) {
            Text(LocalizedStringKey(title)).font(.system(size: 13, weight: .bold, design: .rounded))
            DigitalClock(time: time, theme: theme, fontSize: width < 340 ? 25 : 30)
        }
    }

    private var demonstrationAnswer: some View {
        VStack(spacing: 14) {
            Image(systemName: "arrow.down").font(.system(size: 22, weight: .bold))
                .foregroundStyle(DinoStyle.green).accessibilityHidden(true)
            Group {
                if q.kind == .spokenTime {
                    AnalogClock(time: q.target, theme: theme, size: min(170, width))
                } else if case .time(let time) = q.expectedAnswer,
                          ![.readDigital, .read24Hour].contains(q.kind) {
                    DigitalClock(time: time, theme: theme, fontSize: 32)
                } else {
                    Text(verbatim: responseText(q.expectedAnswer))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                }
            }
        }.frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(responseText(q.expectedAnswer))
            .accessibilityIdentifier("demo.answer")
    }

    private var responses: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(Array(q.responses.enumerated()), id: \.offset) { index, response in
                let correct = session.showsCorrectResponse && response == q.expectedAnswer
                let wrong = session.hasFeedback && session.rejectedResponses.contains(response)
                Button { session.submit(response) } label: {
                    Group {
                        if q.kind == .spokenTime, case .time(let time) = response {
                            AnalogClock(time: time, theme: theme, size: min(width >= 600 ? 210 : 125, (width - 60) / 2)).allowsHitTesting(false)
                        } else {
                            Text(verbatim: responseText(response))
                                .font(.system(size: 17, weight: .bold, design: .rounded)).multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }.padding(12).frame(maxWidth: .infinity, minHeight: 74)
                        .modifier(ClockAnswerOutline(visible: correct || wrong, correct: correct))
                        .background(.white, in: RoundedRectangle(cornerRadius: 22))
                        .overlay(alignment: .topTrailing) {
                            if correct || wrong {
                                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(correct ? DinoStyle.deepGreen : Color(dinoHex: 0xB54343))
                                    .font(.title3).background(.white, in: Circle()).offset(x: 4, y: -4)
                            }
                        }
                }.buttonStyle(DinoAnswerButtonStyle()).disabled(!session.responseIsEnabled(response))
                    .accessibilityLabel(Text(verbatim: responseText(response)))
                    .accessibilityIdentifier("question.option.\(index)")
            }
        }.id("question.answers")
    }

    private func responseText(_ response: ClockAnswer) -> String {
        switch response {
        case .time(let time):
            if [.readDigital, .read24Hour].contains(q.kind) { return DinoTimeWords.time(time, language: code, dayPart: q.kind == .read24Hour) }
            return time.digitalText
        case .duration(let minutes): return DinoTimeWords.duration(minutes, language: code)
        case .truth(let value): return L(key: value ? "dino.expanded.true" : "dino.expanded.false")
        case .dayPart(let part): return L(key: part.titleKey)
        case .ordering(let times), .pairs(let times): return times.map(\.digitalText).joined(separator: " → ")
        }
    }

    private var sorting: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(q.options.enumerated()), id: \.offset) { index, time in
                    let position = session.selectedOrder.firstIndex(of: time)
                    Button {
                        if let position { session.selectedOrder.remove(at: position) }
                        else { session.selectedOrder.append(time) }
                    } label: {
                        VStack(spacing: 8) {
                            AnalogClock(time: time, theme: theme, size: min(width >= 600 ? 180 : 96, (width - 48) / 2)).allowsHitTesting(false)
                            Text(verbatim: time.digitalText).font(.system(size: 17, weight: .bold, design: .rounded)).monospacedDigit()
                        }.padding(12).frame(maxWidth: .infinity).background(.white, in: RoundedRectangle(cornerRadius: 22))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(position == nil ? .clear : DinoStyle.deepGreen, lineWidth: 3))
                            .overlay(alignment: .topLeading) {
                                if let position {
                                    Text(verbatim: "\(position + 1)").font(.headline).frame(width: 28, height: 28)
                                        .background(DinoStyle.green, in: Circle())
                                }
                            }
                    }.buttonStyle(.plain).disabled(session.hasFeedback)
                        .accessibilityLabel(time.digitalText).accessibilityIdentifier("question.sort.\(index)")
                }
            }.id("question.answers")
            if !session.selectedOrder.isEmpty {
                Text(verbatim: session.selectedOrder.map(\.digitalText).joined(separator: " → "))
                    .font(.system(size: 15, weight: .bold, design: .rounded)).monospacedDigit().multilineTextAlignment(.center)
                    .padding(12).modifier(ClockAnswerOutline(visible: session.hasFeedback, correct: session.correctFeedback))
            }
            if session.hasFeedback && !session.correctFeedback {
                Label("dino.expanded.correctOrder", systemImage: "checkmark.circle.fill").font(.subheadline.bold())
                Text(verbatim: responseText(q.expectedAnswer)).font(.system(size: 15, weight: .bold, design: .rounded))
                    .monospacedDigit().padding(12).modifier(ClockAnswerOutline(visible: true, correct: true))
            }
            confirm(.ordering(session.selectedOrder), enabled: session.selectedOrder.count == 4)
        }
    }

    private var analogAdvance: some View {
        let hourChange: ((Int) -> Void)? = session.hasFeedback || movingMinutes ? nil : { session.inputHour = $0 }
        let minuteChange: ((ClockTime) -> Void)? = session.hasFeedback || !movingMinutes ? nil : { session.setInputTime($0) }
        return VStack(spacing: 16) {
            HStack(spacing: 12) {
                AnalogClock(time: session.attempt.submittedAnswer ?? session.inputTime, theme: theme,
                            size: session.hasFeedback && !session.correctFeedback ? min(140, (width - 44) / 2) : min(190, clockSize),
                            onHourChange: hourChange,
                            onMinuteChange: minuteChange, minuteStep: session.minuteStep)
                    .padding(8).modifier(ClockAnswerOutline(visible: session.hasFeedback, correct: session.correctFeedback))
                    .accessibilityIdentifier("question.analogControl")
                if session.hasFeedback && !session.correctFeedback {
                    AnalogClock(time: q.target, theme: theme, size: min(140, (width - 44) / 2)).padding(8)
                        .modifier(ClockAnswerOutline(visible: true, correct: true)).accessibilityIdentifier("question.correctClock")
                }
            }
            if !session.hasFeedback {
                if session.allowsMinutes {
                    Picker("dino.practice.hand", selection: $movingMinutes) {
                        Text("dino.hours").tag(false); Text("dino.minutes").tag(true)
                    }.pickerStyle(.segmented)
                }
                HStack(spacing: 18) {
                    DinoIconButton(icon: "minus", labelKey: movingMinutes ? "dino.minuteLess" : "dino.hourLess") { adjust(-1) }
                    Image(systemName: "hand.draw.fill").font(.title2)
                    DinoIconButton(icon: "plus", labelKey: movingMinutes ? "dino.minuteMore" : "dino.hourMore") { adjust(1) }
                }
            }
            confirm(.time(session.inputTime), enabled: true)
        }.id("question.answers")
    }

    private func adjust(_ direction: Int) {
        if movingMinutes { session.adjustInputMinutes(by: direction * session.minuteStep) }
        else { session.inputHour = ClockTime.shiftedHour(session.inputHour, by: direction) }
    }
    @ViewBuilder private func confirm(_ answer: ClockAnswer, enabled: Bool) -> some View {
        if !session.hasFeedback {
            Button { session.submit(answer) } label: { Image(systemName: "checkmark").font(.title2.bold()) }
                .buttonStyle(DinoButtonStyle()).frame(maxWidth: 260).disabled(!enabled)
                .accessibilityLabel(Text("dino.confirm")).accessibilityIdentifier("question.confirm")
        }
    }
}

struct DinoExpandedDemonstration: View {
    @EnvironmentObject private var player: DinoPlayer
    let kind: ClockQuestionKind
    let time: DinoPracticeTime
    var worldMinutes: [Int]? = nil
    var minuteStep = 60
    let width: CGFloat
    let theme: ClockTheme
    let done: () -> Void
    @State private var sample: DinoSession?
    @State private var exampleIndex = 0

    var body: some View {
        VStack(spacing: 18) {
            Label("dino.example", systemImage: "sparkles").font(.subheadline.bold()).foregroundStyle(DinoStyle.deepGreen)
            if let sample {
                DinoQuestionTitle(question: sample.question, fontSize: 22)
                    .accessibilityIdentifier("demo.title")
                DinoExpandedQuestionView(session: sample, theme: theme, width: width, clockSize: 150, isDemonstration: true)
                    .id(sample.question.id)
                if !kind.usesOptions {
                    Text(verbatim: answer(sample.question)).font(.system(size: 15, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center).accessibilityIdentifier("demo.answer")
                }
            }
            DinoDemonstrationActions(done: done) {
                exampleIndex += 1
                loadExample()
            }
        }.frame(width: width).dinoCard()
            .background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 28))
            .foregroundStyle(DinoStyle.ink).accessibilityElement(children: .contain)
            .onAppear { loadExample() }
    }

    private func loadExample() {
        let configuration = DinoPracticeConfiguration(time: time, order: .specific(DinoPracticeQuestion(rawValue: kind.rawValue)!))
        let question = DinoDemonstrationExamples.question(kind: kind, minutes: worldMinutes ?? time.minutes,
                                                        minuteStep: worldMinutes == nil ? time.minuteStep : minuteStep,
                                                        index: exampleIndex, previousTarget: sample?.question.target)
        sample = DinoSession(level: configuration.level, player: player, practice: configuration,
                             example: question, exampleMinuteStep: worldMinutes == nil ? nil : minuteStep)
    }

    private func answer(_ q: ClockQuestion) -> String {
        let code = LanguageManager.shared.effective.code
        let duration = DinoTimeWords.duration(q.durationMinutes, language: code)
        let answer: String
        switch q.expectedAnswer {
        case .time(let time):
            switch q.kind {
            case .readDigital, .read24Hour, .spokenTime: answer = "\(time.digitalText) = \(DinoTimeWords.time(time, language: code, dayPart: q.kind == .read24Hour))"
            case .addTime, .advanceAnalog, .schoolEnd, .flightArrival: answer = "\(q.relatedTimes[0].digitalText) + \(duration) = \(time.digitalText)"
            case .subtractTime: answer = "\(q.relatedTimes[0].digitalText) − \(duration) = \(time.digitalText)"
            case .timeSequence: answer = "\(q.relatedTimes.last!.digitalText) + \(duration) = \(time.digitalText)"
            case .timeZone: answer = "\(q.relatedTimes[0].digitalText) \(q.offsetHours >= 0 ? "+" : "−") \(abs(q.offsetHours)) h = \(time.digitalText)"
            default: answer = time.digitalText
            }
        case .truth(let correct): answer = "\(DinoTimeWords.time(q.target, language: code)) → \(L(key: correct ? "dino.expanded.true" : "dino.expanded.false"))"
        case .duration(let minutes): answer = "\(q.relatedTimes[0].digitalText) → \(q.relatedTimes[1].digitalText) = \(DinoTimeWords.duration(minutes, language: code))"
        case .dayPart(let part): answer = "\(q.target.digitalText) → \(L(key: part.titleKey))"
        case .ordering(let times): answer = times.map(\.digitalText).joined(separator: " → ")
        case .pairs(let times): answer = times.map { "\(DinoTimeWords.time($0, language: code, dayPart: true)) = \($0.digitalText)" }.joined(separator: "\n")
        }
        return answer
    }
}
