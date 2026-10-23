import SwiftUI

private struct SequenceClockAnchors: PreferenceKey {
    static var defaultValue: [Int: Anchor<CGRect>] { [:] }

    static func reduce(value: inout [Int: Anchor<CGRect>], nextValue: () -> [Int: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

struct DinoExpandedQuestionView: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var session: DinoSession
    @ObservedObject private var language = LanguageManager.shared
    @ObservedObject private var deviceHourFormat = DeviceHourFormat.shared
    let theme: ClockTheme
    let width: CGFloat
    let clockSize: CGFloat
    var isDemonstration = false
    var compactLayout = false
    @State private var movingMinutes = false
    private var q: ClockQuestion { session.question }
    private var code: String { language.effective.code }
    private var duration: String { DinoTimeWords.duration(q.durationMinutes, language: code) }
    /// Reading a 24-hour clock stays in 24-hour digits. Every other digital time follows the player.
    private func shownDigital(_ time: ClockTime) -> String {
        let _ = deviceHourFormat.notation
        return theme.digitalReading(time, languageCode: code, notation: q.kind == .read24Hour ? .twentyFour : nil)
    }

    var body: some View {
        let _ = deviceHourFormat.notation
        VStack(spacing: q.kind == .timeZone && compactLayout ? 12 : 18) {
            if q.kind != .advanceAnalog {
                VStack(spacing: 12) { context }
                    .frame(maxWidth: min(q.kind == .timeZone ? 760 : 600, width))
                    .frame(maxWidth: .infinity)
            }
            switch q.kind {
            case .sortTimes: sorting
            case .sayTime:
                SpokenTimeQuestion(session: session, theme: theme, width: width,
                                   isDemonstration: isDemonstration, compact: compactLayout)
            case .advanceAnalog: analogAdvance
            case .timeSequence:
                if !isDemonstration { responses }
            case .minutesBetween:
                if isDemonstration, q.relatedTimes.count == 2 {
                    DinoMinutesBetweenExplanation(difference: DinoMinuteDifference(q.relatedTimes[0], q.relatedTimes[1]),
                                                  language: code)
                } else if !isDemonstration { responses }
            case .flightArrival, .daySchedule:
                if !isDemonstration { responses }
            case .timeZone:
                if !isDemonstration { responses }
            case .dayPart:
                if isDemonstration { demonstrationAnswer }
                else {
                    responses
                    DinoDayPartLine(time: q.target, width: min(600, width), isDemonstration: false,
                                    schedule: session.dayPartSchedule)
                        .opacity(session.showsWorkedExplanation ? 1 : 0)
                        .accessibilityHidden(!session.showsWorkedExplanation)
                }
            default:
                if isDemonstration { demonstrationAnswer }
                else { responses }
            }
        }.frame(width: width).multilineTextAlignment(.center)
    }

    @ViewBuilder private var context: some View {
        switch q.kind {
        case .readDigital, .read24Hour, .dayPart:
            DigitalClock(time: q.target, theme: theme, fontSize: 38, notation: q.kind == .read24Hour ? .twentyFour : nil)
                .accessibilityIdentifier(isDemonstration ? "demo.targetClock" : "question.targetClock")
        case .spokenTime:
            EmptyView()
        case .trueFalse:
            AnalogClock(time: q.target, theme: theme, size: min(180, clockSize))
                .accessibilityIdentifier(isDemonstration ? "demo.targetClock" : "question.targetClock")
        case .sortTimes:
            if isDemonstration {
                Text("dino.expanded.sameDay").font(.subheadline).multilineTextAlignment(.center)
                    .accessibilityIdentifier("demo.sort.hint")
            }
        case .timeSequence:
            timeSequence
        case .minutesBetween:
            if q.relatedTimes.count == 2 {
                DinoMinutesBetweenCard(start: q.relatedTimes[0], end: q.relatedTimes[1],
                                       minutes: q.durationMinutes, theme: theme, width: min(600, width),
                                       showsAnswer: isDemonstration || session.showsCorrectResponse,
                                       isDemonstration: isDemonstration, language: code,
                                       compact: compactLayout || (isDemonstration && width < 340))
            }
        case .timeZone:
            if let journey = q.timeZoneJourney, let referenceTime = q.relatedTimes.first {
                DinoTimeZoneLesson(journey: journey, referenceTime: referenceTime, answer: q.target,
                                   showsAnswer: isDemonstration || session.showsCorrectResponse,
                                   isDemonstration: isDemonstration, compactLayout: compactLayout && width >= 600,
                                   theme: theme, width: min(760, width),
                                   explainsLive: session.showsWorkedExplanation)
            }
        case .addTime, .subtractTime:
            DigitalClock(time: q.relatedTimes[0], theme: theme, fontSize: timeChangeClockFont)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: shownDigital(q.relatedTimes[0])))
                .accessibilityIdentifier(isDemonstration ? "demo.targetClock" : "question.targetClock")
            timeChange
        case .flightArrival:
            DinoFlightTicket(work: flightWork, showsWork: isDemonstration || session.showsWorkedExplanation,
                             minuteStep: session.minuteStep, language: code, width: min(600, width),
                             isDemonstration: isDemonstration, theme: theme)
        case .daySchedule:
            if let schedule = q.daySchedule {
                DinoTrainJourneyCard(schedule: schedule,
                                     showsAnswer: isDemonstration || session.showsCorrectResponse,
                                     countsTotal: isDemonstration || session.missedFirstAnswer,
                                     isDemonstration: isDemonstration, language: code, theme: theme)
            }
        default:
            // SwiftUI can update an outgoing view after the shared session has advanced.
            EmptyView()
        }
    }

    private var timeChange: some View {
        let subtracting = q.kind == .subtractTime
        let ink = subtracting ? DinoTimeDirection.earlier : DinoStyle.deepGreen
        let fill = subtracting ? DinoTimeDirection.earlier : DinoStyle.green
        return Label {
            Text(verbatim: "\(duration) \(L(key: subtracting ? "dino.expanded.earlier" : "dino.expanded.later"))")
        } icon: { Image(systemName: subtracting ? "minus.circle.fill" : "plus.circle.fill") }
            .font(.system(size: 19, weight: .bold, design: .rounded))
            .foregroundStyle(ink)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(fill.opacity(0.28), in: Capsule())
            .overlay(Capsule().strokeBorder(ink.opacity(highContrast ? 1 : 0.35), lineWidth: highContrast ? 2 : 1))
            .accessibilityIdentifier("\(isDemonstration ? "demo" : "question").timeChange.difference")
    }

    private var timeChangeClockFont: CGFloat { isDemonstration ? 32 : min(48, width * 0.14) }

    private var flightWork: DinoFlightArrivalWork {
        DinoFlightArrivalWork(departure: q.relatedTimes[0], durationMinutes: q.durationMinutes,
                              offsetHours: q.offsetHours, arrival: q.target)
    }

    private var timeSequence: some View {
        VStack(spacing: isDemonstration ? 6 : 4) {
            ForEach(Array(q.relatedTimes.enumerated()), id: \.offset) { index, time in
                DigitalClock(time: time, theme: theme, fontSize: sequenceClockFont)
                    .anchorPreference(key: SequenceClockAnchors.self, value: .bounds) { [index: $0] }
                    .accessibilityIdentifier("\(sequencePrefix).sequence.clock.\(index)")
                Image(systemName: "arrow.down")
                    .font(.system(size: isDemonstration ? 17 : 15, weight: .bold))
                    .foregroundStyle(DinoStyle.deepGreen)
                    .accessibilityIdentifier("\(sequencePrefix).sequence.arrow.\(index)")
            }
            Group {
                if isDemonstration {
                    DigitalClock(time: q.target, theme: theme, fontSize: sequenceClockFont)
                        .accessibilityIdentifier("demo.answer")
                } else {
                    Text("?").font(.system(size: sequenceClockFont, weight: .heavy, design: .rounded))
                        .accessibilityIdentifier("question.sequence.unknown")
                }
            }
            .anchorPreference(key: SequenceClockAnchors.self, value: .bounds) { [q.relatedTimes.count: $0] }
        }
        .frame(maxWidth: .infinity)
        .overlayPreferenceValue(SequenceClockAnchors.self) { anchors in
            if isDemonstration || session.showsWorkedExplanation {
                GeometryReader { geometry in
                    // Side jumps never shift the clocks. The question mark stays without an arc.
                    let count = isDemonstration ? q.relatedTimes.count + 1 : q.relatedTimes.count
                    SequencePatternArcs(frames: (0..<count).compactMap { anchors[$0].map { geometry[$0] } },
                                        label: "+\(duration)", prefix: sequencePrefix)
                }.allowsHitTesting(false)
            }
        }
    }

    private var sequencePrefix: String { isDemonstration ? "demo" : "question" }
    private var sequenceClockFont: CGFloat { isDemonstration ? 32 : min(width >= 600 ? 42 : 36, width * 0.10) }

    private func timeCard(_ time: ClockTime, title: String) -> some View {
        VStack(spacing: 8) {
            Text(LocalizedStringKey(title)).font(.system(size: 13, weight: .bold, design: .rounded))
            DigitalClock(time: time, theme: theme, fontSize: width < 340 ? 25 : 30)
        }
    }

    private var demonstrationAnswer: some View {
        VStack(spacing: q.kind == .dayPart ? 10 : 14) {
            Image(systemName: "arrow.down").font(.system(size: 22, weight: .bold))
                .foregroundStyle(q.kind == .subtractTime ? DinoTimeDirection.earlier : DinoStyle.green).accessibilityHidden(true)
            if q.kind == .dayPart {
                DinoDayPartLine(time: q.target, width: width, schedule: session.dayPartSchedule)
            } else {
                Group {
                    if q.kind == .spokenTime {
                        AnalogClock(time: q.target, theme: theme, size: min(170, width))
                    } else if case .time(let time) = q.expectedAnswer,
                              ![.readDigital, .read24Hour].contains(q.kind) {
                        DigitalClock(time: time, theme: theme, fontSize: timeChangeClockFont)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(Text(verbatim: shownDigital(time)))
                    } else {
                        Text(verbatim: responseText(q.expectedAnswer))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            // Reserve four lines so refreshing a longer 24-hour answer
                            // cannot move the action buttons or recenter the example card.
                            .frame(height: q.kind == .read24Hour ? 120 : nil)
                    }
                }.accessibilityIdentifier("demo.answer")
            }
        }.frame(maxWidth: .infinity)
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
                        } else if q.kind == .read24Hour, case .time(let time) = response {
                            timeDescription(time)
                        } else {
                            Text(verbatim: responseText(response))
                                .font(.system(size: 17, weight: .bold, design: .rounded)).multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }.padding(12).frame(maxWidth: .infinity, minHeight: [.minutesBetween, .timeZone].contains(q.kind) && compactLayout ? 62 : 74)
                        .modifier(ClockAnswerOutline(visible: correct || wrong, correct: correct))
                        .background(.white, in: RoundedRectangle(cornerRadius: 22))
                        .overlay(alignment: .topTrailing) {
                            if correct || wrong {
                                AnswerVerdictMark(correct: correct)
                                    .padding(2).background(.white, in: Circle()).offset(x: 4, y: -4)
                            }
                        }
                }.buttonStyle(DinoAnswerButtonStyle()).disabled(!session.responseIsEnabled(response))
                    .accessibilityIdentifier("question.option.\(index)")
            }
        }.id("question.answers").questionAnswerFocus()
    }

    private func timeDescription(_ time: ClockTime) -> some View {
        VStack(spacing: 9) {
            Text(verbatim: DinoTimeWords.time(time, language: code))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(DinoStyle.ink)
                .fixedSize(horizontal: false, vertical: true)
            Label {
                Text(verbatim: DinoTimeWords.dayPartSuffix(time, language: code, schedule: session.dayPartSchedule))
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: DinoDayPart(hour: time.hour, schedule: session.dayPartSchedule).symbol)
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 12))
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: DinoTimeWords.time(time, language: code, dayPart: true,
                                                             schedule: session.dayPartSchedule)))
    }

    private func responseText(_ response: ClockAnswer) -> String {
        switch response {
        case .time(let time):
            if [.readDigital, .read24Hour].contains(q.kind) {
                return DinoTimeWords.time(time, language: code, dayPart: q.kind == .read24Hour, schedule: session.dayPartSchedule)
            }
            return shownDigital(time)
        case .duration(let minutes):
            return q.kind == .minutesBetween ? DinoTimeWords.minutes(minutes, language: code)
                : DinoTimeWords.duration(minutes, language: code)
        case .truth(let value): return L(key: value ? "dino.expanded.true" : "dino.expanded.false")
        case .dayPart(let part): return L(key: part.titleKey)
        case .ordering(let times), .pairs(let times): return times.map(shownDigital).joined(separator: " → ")
        case .spoken(let spoken): return q.spokenPrompt?.phrase(for: spoken) ?? ""
        }
    }

    private var sorting: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(q.options.enumerated()), id: \.offset) { index, time in
                    let position = session.selectedOrder.firstIndex(of: time)
                    let wrongPosition = session.hasFeedback && position.map { !sortPositionIsCorrect($0, time: time) } == true
                    Button {
                        if let position { session.selectedOrder.remove(at: position) }
                        else { session.selectedOrder.append(time) }
                    } label: {
                        let clockSize = min(width >= 600 ? 180 : 96, (width - 48) / 2)
                        let badge: CGFloat = 26
                        // Center the number in the open corner beside a round face.
                        let badgeInset = clockSize * 0.105 - badge / 2
                        VStack(spacing: 8) {
                            AnalogClock(time: time, theme: theme, size: clockSize).allowsHitTesting(false)
                                .overlay(alignment: .topLeading) {
                                    if let position {
                                        Text(verbatim: "\(position + 1)")
                                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                                            .foregroundStyle(DinoStyle.ink)
                                            .frame(width: badge, height: badge)
                                            .background(wrongPosition ? DinoStyle.orange : DinoStyle.green, in: Circle())
                                            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                                            .offset(x: badgeInset, y: badgeInset)
                                            .accessibilityHidden(true)
                                    }
                                }
                            Text(verbatim: shownDigital(time)).font(.system(size: 17, weight: .bold, design: .rounded)).monospacedDigit()
                        }.padding(12).frame(maxWidth: .infinity).background(.white, in: RoundedRectangle(cornerRadius: 22))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(position == nil ? .clear : wrongPosition ? DinoStyle.deepOrange : DinoStyle.deepGreen, lineWidth: 3))
                    }.buttonStyle(DinoAnswerButtonStyle()).disabled(session.hasFeedback || isDemonstration)
                        .accessibilityIdentifier("\(isDemonstration ? "demo" : "question").sort.\(index)")
                        .accessibilityValue(Text(verbatim: position.map {
                            let number = String($0 + 1)
                            return session.hasFeedback ? "\(number), \(L(key: wrongPosition ? "dino.expanded.false" : "dino.expanded.true"))" : number
                        } ?? ""))
                }
            }.id("question.answers")
            VStack(spacing: 12) {
                sortAnswerSlot(correct: false)
                if !isDemonstration { sortAnswerSlot(correct: true) }
            }
            .questionAnswerFocus()
        }
    }

    private func sortPositionIsCorrect(_ position: Int, time: ClockTime) -> Bool {
        guard case .ordering(let order) = q.expectedAnswer, order.indices.contains(position) else { return false }
        return order[position] == time
    }

    /// Measure a complete sequence before the first tap, including wrapped lines.
    /// The draft and correction then fill their own slots without moving Confirm.
    private func sortAnswerSlot(correct: Bool) -> some View {
        let revealed = correct ? session.hasFeedback && !session.correctFeedback : !session.selectedOrder.isEmpty
        let text = correct ? responseText(q.expectedAnswer) : session.selectedOrder.map(shownDigital).joined(separator: " → ")
        return Text(verbatim: responseText(q.expectedAnswer))
            .hidden()
            .overlay {
                Text(verbatim: text)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(revealed ? 1 : 0)
                    .accessibilityHidden(!revealed)
                    .accessibilityIdentifier(correct ? "question.sort.correct" : isDemonstration ? "demo.answer" : "question.sort.selection")
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .monospacedDigit().multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(12)
            .modifier(ClockAnswerOutline(visible: revealed && (correct || session.hasFeedback), correct: correct || session.correctFeedback))
    }

    private var advanceComparing: Bool { session.hasFeedback && !session.correctFeedback }
    private var analogHandStep: Int { DinoPracticeTime.analogHandStep(session.minuteStep) }

    /// The clock the player turns. The start face above it is exactly half this size.
    private var playFace: CGFloat {
        let cap = compactLayout ? min(148, clockSize) : clockSize
        return min(cap, max(112, width - 16))
    }

    private var analogAdvance: some View {
        let hourChange: ((Int) -> Void)? = session.hasFeedback ? nil : { session.inputHour = $0 }
        let minuteChange: ((ClockTime) -> Void)? = session.hasFeedback || !session.allowsMinutes ? nil : { session.setInputTime($0) }
        let shown = session.attempt.submittedAnswer ?? session.inputTime
        return VStack(spacing: 12) {
            DinoAnalogAdvanceLayout(start: DinoAnalogAdvanceExample.face(q.relatedTimes[0]), theme: theme,
                                    durationMinutes: q.durationMinutes, language: code, playSize: playFace) {
                ZStack {
                    AnalogClock(time: shown, theme: theme, size: playFace,
                                onHourChange: hourChange, onMinuteChange: minuteChange, minuteStep: analogHandStep,
                                adjustingMinutes: movingMinutes,
                                onHandSelection: session.hasFeedback ? nil : { movingMinutes = $0 })
                        .padding(4)
                        .modifier(ClockAnswerOutline(visible: session.hasFeedback, correct: session.correctFeedback))
                        .overlay(alignment: .topTrailing) {
                            if advanceComparing { AnswerVerdictMark(correct: false).offset(x: 4, y: -4) }
                        }
                        .scaleEffect(advanceComparing ? advanceComparisonScale : 1)
                        .offset(y: advanceComparing ? -advanceResultOffset : 0)
                        .accessibilityIdentifier("question.analogControl")
                    AnalogClock(time: DinoAnalogAdvanceExample.face(q.target), theme: theme, size: playFace)
                        .padding(4)
                        .modifier(ClockAnswerOutline(visible: true, correct: true))
                        .overlay(alignment: .topTrailing) { AnswerVerdictMark(correct: true).offset(x: 4, y: -4) }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(DinoAnalogAdvanceExample.face(q.target).digitalText)
                        .scaleEffect(advanceComparisonScale * (advanceComparing || reduceMotion ? 1 : 0.94))
                        .offset(y: advanceResultOffset)
                        .opacity(advanceComparing ? 1 : 0)
                        .accessibilityHidden(!advanceComparing).allowsHitTesting(false)
                        .accessibilityIdentifier("question.correctClock")
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.16).delay(0.2), value: advanceComparing)
                }
                .frame(width: playFace + 8, height: advanceStageHeight)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: advanceComparing)
            }
            .questionAnswerFocus()
            DinoAnalogClockControls(adjustingMinutes: $movingMinutes, allowsMinutes: session.allowsMinutes,
                                    minuteStep: analogHandStep, adjust: adjust)
                .frame(maxWidth: min(320, width))
                .modifier(AnswerControlVisibility(session: session, reduceMotion: reduceMotion))
        }.id("question.answers")
    }

    /// Wrong and right faces share the space of the clock being turned, so the row does not grow.
    private var advanceComparisonScale: CGFloat {
        let face = playFace + 8
        return min(1, (face - 12) / (2 * face))
    }
    private var advanceResultOffset: CGFloat { ((playFace + 8) * advanceComparisonScale + 12) / 2 }
    private var advanceStageHeight: CGFloat { playFace + 8 }

    private func adjust(_ direction: Int) {
        guard !session.hasFeedback else { return }
        if movingMinutes { session.adjustInputMinutes(by: direction * analogHandStep) }
        else { session.inputHour = ClockTime.shiftedHour(session.inputHour, by: direction) }
    }
}

/// Start clock above the clock the player turns, at half its size, joined by the duration.
struct DinoAnalogAdvanceLayout<Play: View>: View {
    let start: ClockTime
    let theme: ClockTheme
    let durationMinutes: Int
    let language: String
    let playSize: CGFloat
    var prefix = "question"
    var startIdentifier = "question.startClock"
    @ViewBuilder var play: () -> Play

    var body: some View {
        VStack(spacing: 0) {
            AnalogClock(time: start, theme: theme, size: playSize * 0.5)
                .accessibilityIdentifier(startIdentifier)
            DinoAdvanceDifference(minutes: durationMinutes, language: language, prefix: prefix)
            play()
        }
        .frame(maxWidth: .infinity)
    }
}

struct DinoAdvanceDifference: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let minutes: Int
    let language: String
    var prefix = "question"
    /// Added time sits to the right of the centered arrow. Removed time sits to the left.
    var subtracting = false

    var body: some View {
        let combined = minutes / 60 > 0 && minutes % 60 > 0
        let ink = DinoStyle.deepGreen
        let duration = "\(subtracting ? "−" : "+")\(DinoTimeWords.duration(minutes, language: language))"
        // Equal empty halves keep the arrow on the clock center. The label is only an overlay,
        // so its width cannot pull the arrow sideways.
        HStack(spacing: 8) {
            Color.clear.frame(maxWidth: .infinity)
                .overlay(alignment: .trailing) { if subtracting { durationLabel(duration, combined: combined, ink: ink) } }
            Image(systemName: "arrow.down")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(ink)
                .frame(width: 18)
                .accessibilityHidden(true)
            Color.clear.frame(maxWidth: .infinity)
                .overlay(alignment: .leading) { if !subtracting { durationLabel(duration, combined: combined, ink: ink) } }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: duration))
        .accessibilityIdentifier("\(prefix).advance.difference")
    }

    private func durationLabel(_ duration: String, combined: Bool, ink: Color) -> some View {
        Text(verbatim: duration)
            .font(.system(size: combined ? 13 : 15, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .foregroundStyle(ink)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(DinoStyle.green.opacity(highContrast ? 0.45 : 0.28), in: Capsule())
            .overlay(Capsule().strokeBorder(ink.opacity(highContrast ? 1 : 0.4), lineWidth: highContrast ? 2 : 1.25))
            .fixedSize()
    }
}

/// Retract controls in their own space; never dissolve them over the answer or
/// collapse their layout while the question is centered in the scroll view.
struct AnswerControlVisibility: ViewModifier {
    @ObservedObject var session: DinoSession
    var reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .mask(alignment: .top) {
                Rectangle().scaleEffect(x: 1, y: session.hidesAnswerControls ? 0 : 1, anchor: .top)
            }
            .allowsHitTesting(!session.hasFeedback)
            .accessibilityHidden(session.hasFeedback)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: session.hidesAnswerControls)
    }
}

/// Jumps sit beside the clocks. Only the last curve ends in a triangle on its endpoint.
private struct SequencePatternArcs: View {
    let frames: [CGRect]
    let label: String
    let prefix: String

    var body: some View {
        let points = frames.map { CGPoint(x: $0.maxX + 1, y: $0.midY) }
        ZStack(alignment: .topLeading) {
            ForEach(0..<max(points.count - 1, 0), id: \.self) { index in
                arc(from: points[index], to: points[index + 1],
                    pointed: index == points.count - 2, index: index)
            }
        }
    }

    private func arc(from start: CGPoint, to end: CGPoint, pointed: Bool, index: Int) -> some View {
        let outerX = max(start.x, end.x) + 26
        let baseX = end.x + (pointed ? 9 : 0)
        let lineEnd = CGPoint(x: baseX, y: end.y)
        return ZStack(alignment: .topLeading) {
            Path { path in
                path.move(to: start)
                path.addCurve(to: lineEnd,
                              control1: CGPoint(x: outerX, y: start.y),
                              control2: CGPoint(x: outerX, y: lineEnd.y))
            }
            .stroke(DinoStyle.deepGreen, style: StrokeStyle(lineWidth: 2.25, lineCap: pointed ? .butt : .round))
            if pointed {
                Path { path in
                    path.move(to: end)
                    path.addLine(to: CGPoint(x: baseX, y: end.y - 4.5))
                    path.addLine(to: CGPoint(x: baseX, y: end.y + 4.5))
                    path.closeSubpath()
                }.fill(DinoStyle.deepGreen)
            }
            Text(verbatim: label)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(DinoStyle.deepGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(DinoStyle.green.opacity(0.28), in: Capsule())
                .overlay(Capsule().stroke(DinoStyle.deepGreen.opacity(0.35), lineWidth: 1))
                .fixedSize()
                .offset(x: outerX + 6, y: (start.y + end.y) / 2 - 12)
                .accessibilityHidden(prefix == "demo")
                .accessibilityIdentifier("\(prefix).sequence.step.\(index)")
        }
    }
}

/// Vertical journey: departure, two trains, the transfer between them, and the arrival to find.
private struct DinoTrainJourneyCard: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let schedule: DinoDaySchedule
    let showsAnswer: Bool
    let countsTotal: Bool
    let isDemonstration: Bool
    let language: String
    let theme: ClockTheme
    /// Examples are born with the total already open, so refreshing one does not replay the reveal.
    @State private var showsTotal: Bool
    private var prefix: String { isDemonstration ? "demo" : "question" }

    private let ride = Color(dinoHex: 0x6A4300)
    private let rideFill = Color(dinoHex: 0xFFF4C8)
    private let rideChip = Color(dinoHex: 0xFFD56A)
    private let transferInk = Color(dinoHex: 0x154A86)
    private let transferFill = Color(dinoHex: 0xE7F1FB)
    private let transferChip = Color(dinoHex: 0xD3E6F8)

    init(schedule: DinoDaySchedule, showsAnswer: Bool, countsTotal: Bool, isDemonstration: Bool, language: String, theme: ClockTheme) {
        self.schedule = schedule
        self.showsAnswer = showsAnswer
        self.countsTotal = countsTotal
        self.isDemonstration = isDemonstration
        self.language = language
        self.theme = theme
        _showsTotal = State(initialValue: isDemonstration && countsTotal)
    }
    private let arrivalFill = Color(dinoHex: 0xE7F7DC)
    private let arrivalChip = Color(dinoHex: 0xD5F0C2)
    private let totalInk = Color(dinoHex: 0x5E6A70)

    var body: some View {
        VStack(spacing: 2) {
            leg(symbol: "building.columns.fill", title: "dino.train.departure",
                value: theme.digitalReading(schedule.start, languageCode: language), ink: DinoStyle.deepGreen, fill: arrivalFill, chip: arrivalChip,
                identifier: "\(prefix).schedule.start")
            connector
            if countsTotal {
                // The combined total opens only after a wrong answer, so the card stays tight until then.
                durationGroup
                if showsTotal {
                    connector
                    totalRow
                }
            } else {
                trainOne
                connector
                transfer
                connector
                trainTwo
            }
            connector
            arrival
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(highContrast ? DinoStyle.ink : DinoStyle.deepGreen.opacity(0.16), lineWidth: highContrast ? 2 : 1.5))
        .shadow(color: DinoStyle.deepGreen.opacity(0.08), radius: 16, y: 6)
        .accessibilityIdentifier("\(prefix).schedule.card")
        .onValueChange(of: countsTotal) { show in
            guard show, !isDemonstration else { return }
            if reduceMotion {
                showsTotal = true
            } else {
                withAnimation(.easeOut(duration: 0.24).delay(0.08)) { showsTotal = true }
            }
        }
    }

    /// The two trains and the transfer become one sum, so the arrows between them go away.
    private var durationGroup: some View {
        VStack(spacing: 4) {
            trainOne
            transfer
            trainTwo
        }
        .padding(6)
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(highContrast ? DinoStyle.ink : DinoStyle.ink.opacity(0.45),
                          style: StrokeStyle(lineWidth: highContrast ? 2 : 1.5, dash: [5, 4])))
        .accessibilityIdentifier("\(prefix).schedule.group")
    }

    private var trainOne: some View {
        leg(symbol: "train.side.front.car", title: "dino.train.one",
            value: DinoTimeWords.duration(schedule.firstMinutes, language: language),
            ink: ride, fill: rideFill, chip: rideChip,
            identifier: "\(prefix).schedule.activity.1")
    }

    private var transfer: some View {
        leg(symbol: "figure.walk", title: "dino.train.transfer",
            value: DinoTimeWords.duration(schedule.breakMinutes, language: language),
            ink: transferInk, fill: transferFill, chip: transferChip,
            identifier: "\(prefix).schedule.break")
    }

    private var trainTwo: some View {
        leg(symbol: "train.side.front.car", title: "dino.train.two",
            value: DinoTimeWords.duration(schedule.secondMinutes, language: language),
            ink: ride, fill: rideFill, chip: rideChip,
            identifier: "\(prefix).schedule.activity.2")
    }

    private var connector: some View {
        Image(systemName: "arrow.down")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
            .accessibilityHidden(true)
    }

    /// The finished sum of the two trains and the transfer. It opens once; it does not count up.
    private var totalRow: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(totalInk.opacity(highContrast ? 0.22 : 0.16))
                VStack(spacing: 2) {
                    Capsule().frame(width: 8, height: 1.5)
                    Capsule().frame(width: 8, height: 1.5)
                }
            }
            .foregroundStyle(highContrast ? DinoStyle.ink : totalInk)
            .frame(width: 22, height: 22)
            .accessibilityHidden(true)
            Text("dino.expanded.flightTotalAdded")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer(minLength: 8)
            Text(verbatim: DinoTimeWords.duration(schedule.totalMinutes, language: language))
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.55)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background((highContrast ? DinoStyle.ink : totalInk).opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .layoutPriority(1)
        }
        .foregroundStyle(highContrast ? DinoStyle.ink : totalInk)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background((highContrast ? DinoStyle.ink : totalInk).opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("\(prefix).schedule.total")
    }

    private var arrival: some View {
        HStack(spacing: 8) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 26, height: 26)
                .accessibilityHidden(true)
            Text("dino.train.arrival")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer(minLength: 8)
            arrivalValue
        }
        .foregroundStyle(DinoStyle.deepGreen)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(arrivalFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(highContrast ? DinoStyle.deepGreen : .clear, lineWidth: 1.5))
    }

    private var arrivalValue: some View {
        let text = showsAnswer ? theme.digitalReading(schedule.end, languageCode: language) : "?"
        return Text(verbatim: text)
            .font(.system(size: showsAnswer ? 14 : 18, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .lineLimit(1).minimumScaleFactor(0.6)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .fixedSize(horizontal: true, vertical: false)
            .frame(minWidth: 70, minHeight: 32, maxHeight: 32)
            .background(arrivalChip, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(DinoStyle.deepGreen.opacity(showsAnswer ? 0 : (highContrast ? 1 : 0.75)),
                              style: StrokeStyle(lineWidth: 1.5, dash: showsAnswer ? [] : [5, 4])))
            .accessibilityIdentifier(isDemonstration ? "demo.answer" : "\(prefix).schedule.finish")
    }

    private func leg(symbol: String, title: LocalizedStringKey, value: String,
                     ink: Color, fill: Color, chip: Color, identifier: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 26, height: 26)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer(minLength: 8)
            Text(verbatim: value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.55)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(chip, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .layoutPriority(1)
        }
        .foregroundStyle(ink)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(highContrast ? ink : .clear, lineWidth: 1.5))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }
}

/// Shared inks so each number on the ticket stays distinct from the gray total.
private enum DinoFlightInk {
    static let departure = Color(dinoHex: 0x154A86)
    static let duration = DinoStyle.deepGreen
    static let arrival = DinoStyle.deepGreen
    static let total = Color(dinoHex: 0x5E6A70)
    static let totalFill = Color(dinoHex: 0xE6EAEC)
}

private struct DinoFlightTicket: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let work: DinoFlightArrivalWork
    let showsWork: Bool
    let minuteStep: Int
    let language: String
    let width: CGFloat
    let isDemonstration: Bool
    let theme: ClockTheme
    @State private var appliedMinutes = 0
    @State private var walking = false
    /// 0...1 for the practice reveal. Examples show the finished total and ignore this.
    @State private var totalProgress: CGFloat = 0

    private var prefix: String { isDemonstration ? "demo" : "question" }
    private var secondaryInk: Color { highContrast ? DinoStyle.ink : DinoStyle.muted }
    private var pathWidth: CGFloat { min(88, max(36, width * 0.16)) }
    private var timeSize: CGFloat { width < 380 ? 22 : 26 }
    private var totalInk: Color { highContrast ? DinoStyle.ink : DinoFlightInk.total }
    private var factIcon: CGFloat { 28 }
    private var shownArrival: ClockTime { work.departure.adding(minutes: appliedMinutes) }
    private var totalAmount: CGFloat { isDemonstration ? 1 : totalProgress }
    private var totalRowAmount: CGFloat { max(0, min(1, (totalAmount - 0.22) / 0.78)) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "airplane")
                    .font(.system(size: 21, weight: .bold))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)
                Text("dino.expanded.flightTicket")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                Spacer(minLength: 0)
                if width >= 300 {
                    Text(verbatim: "DINO AIR")
                        .font(.system(size: 10, weight: .heavy, design: .rounded)).tracking(1.5)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 20).frame(height: 64)
            .background(DinoStyle.green.opacity(highContrast ? 0.5 : 0.25))

            Rectangle().strokeBorder(DinoStyle.deepGreen.opacity(highContrast ? 0.7 : 0.25),
                                     style: StrokeStyle(lineWidth: 1, dash: [4, 5]))
                .frame(height: 1).padding(.horizontal, 16).accessibilityHidden(true)

            VStack(spacing: 18) {
                HStack(alignment: .center, spacing: 6) {
                    VStack(spacing: 4) {
                        fieldLabel("dino.expanded.departure", color: DinoFlightInk.departure)
                        timeChip(theme.digitalReading(work.departure, languageCode: language), color: DinoFlightInk.departure,
                                 identifier: "\(prefix).targetClock")
                    }.frame(minWidth: 0, maxWidth: .infinity)

                    Group {
                        if showsWork && walking { difference }
                        else { flightPath.frame(width: pathWidth) }
                    }
                    .padding(.top, 20)
                    .fixedSize(horizontal: true, vertical: false)
                    .layoutPriority(1)

                    VStack(spacing: 4) {
                        fieldLabel("dino.expanded.arrival", color: showsWork && walking ? DinoFlightInk.arrival : secondaryInk)
                        if showsWork && walking {
                            timeChip(theme.digitalReading(shownArrival, languageCode: language), color: DinoFlightInk.arrival,
                                     identifier: isDemonstration ? "demo.answer" : "\(prefix).flight.arrival")
                                .numericTextTransition()
                        } else {
                            Text(verbatim: "?")
                                .font(.system(size: timeSize, weight: .heavy, design: .rounded))
                                .foregroundStyle(secondaryInk)
                                .lineLimit(1).minimumScaleFactor(0.45)
                                .padding(.horizontal, 6).padding(.vertical, 5)
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: timeSize + 12)
                                .background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(secondaryInk.opacity(0.45),
                                                  style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                                .accessibilityLabel(Text("dino.expanded.unknownArrival"))
                                .accessibilityIdentifier(isDemonstration ? "demo.answer" : "\(prefix).flight.unknown")
                        }
                    }.frame(minWidth: 0, maxWidth: .infinity)
                }

                VStack(spacing: 8) {
                    factRow(title: "dino.expanded.flightDuration", systemImage: "clock",
                            value: work.durationText(language), color: DinoFlightInk.duration, fill: DinoStyle.green,
                            identifier: "\(prefix).flight.duration")
                    if work.offsetHours != 0 {
                        factRow(title: "dino.expanded.flightZoneDifference", systemImage: "globe",
                                value: DinoTimeWords.hourDifference(work.offsetHours, language: language),
                                color: work.offsetHours < 0 ? DinoTimeDirection.earlier : DinoStyle.deepGreen,
                                fill: work.offsetHours < 0 ? DinoTimeDirection.earlier : DinoStyle.green,
                                identifier: "\(prefix).flight.zone")
                        totalReveal
                    }
                }

                if work.offsetHours == 0 {
                    Text("dino.expanded.flightZone")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("\(prefix).flight.sameZone")
                }

            }.padding(width < 300 ? 16 : 20)
        }
        .foregroundStyle(DinoStyle.ink)
        .background(.white)
        .clipShape(DinoFlightTicketShape())
        .overlay(DinoFlightTicketShape().stroke(highContrast ? DinoStyle.ink : DinoStyle.deepGreen.opacity(0.15),
                                               lineWidth: highContrast ? 3 : 1.5))
        .shadow(color: DinoStyle.deepGreen.opacity(0.08), radius: 18, y: 8)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(prefix).flight.ticket")
        .task(id: walkIdentity) { await play() }
    }

    /// The line draws first. The finished total then settles open beneath it.
    private var totalReveal: some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(totalInk.opacity(highContrast ? 0.55 : 0.35))
                .frame(height: 1)
                .scaleEffect(x: min(1, totalAmount * 1.35), anchor: .center)
                .opacity(min(1, totalAmount * 1.8))
                .accessibilityHidden(true)
            totalShift
                .opacity(totalRowAmount)
                .scaleEffect(x: 0.985 + 0.015 * totalRowAmount, y: 0.86 + 0.14 * totalRowAmount, anchor: .top)
                .offset(y: (1 - totalRowAmount) * -4)
        }
        .padding(.top, 4)
        .clipped()
        .accessibilityHidden(totalRowAmount < 0.9 && !isDemonstration)
    }

    /// Light gray field, a slightly darker circle, and a small dark equals, like the icons above.
    private var totalShift: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                equalsBadge
                Text("dino.expanded.flightTotalAdded")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Text(verbatim: work.combinedText(language))
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(totalInk)
        .padding(.horizontal, 12).padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(totalInk.opacity(highContrast ? 0.14 : 0.10), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: "\(L(key: "dino.expanded.flightTotalAdded")) \(work.combinedText(language))"))
        .accessibilityIdentifier("\(prefix).flight.total")
    }

    /// Two short bars, sized like the clock and globe glyphs, centered in the circle.
    private var equalsBadge: some View {
        ZStack {
            Circle().fill(totalInk.opacity(highContrast ? 0.22 : 0.16))
            VStack(spacing: 2.5) {
                Capsule().frame(width: 10, height: 1.6)
                Capsule().frame(width: 10, height: 1.6)
            }
        }
        .foregroundStyle(totalInk)
        .frame(width: factIcon, height: factIcon)
        .accessibilityHidden(true)
    }

    /// Same capsule as the time-zone walk: the icon carries the sign, the text is the amount so far.
    private var difference: some View {
        let resting = appliedMinutes == 0
        let negative = appliedMinutes < 0
        let ink = resting ? DinoStyle.muted : negative ? DinoTimeDirection.earlier : DinoStyle.deepGreen
        let fill = resting ? DinoStyle.muted : negative ? DinoTimeDirection.earlier : DinoStyle.green
        return HStack(spacing: 4) {
            Image(systemName: negative ? "minus.circle.fill" : "plus.circle.fill")
                .font(.system(size: 15, weight: .bold))
            Text(verbatim: chipNumber)
                .font(.system(size: width < 380 ? 13 : 14, weight: .heavy, design: .rounded))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.45)
                .numericTextTransition()
        }
        .foregroundStyle(ink)
        .padding(.horizontal, 10).padding(.vertical, 7)
        .fixedSize(horizontal: true, vertical: false)
        .layoutPriority(1)
        .background(fill.opacity(resting ? 0.14 : 0.28), in: Capsule())
        .overlay(Capsule().strokeBorder(ink.opacity(resting ? 0.28 : 0.35), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: chipCaption))
        .accessibilityIdentifier("\(prefix).flight.difference")
    }

    private var chipNumber: String {
        appliedMinutes == 0 ? "0" : DinoTimeWords.duration(abs(appliedMinutes), language: language)
    }

    private var chipCaption: String {
        if appliedMinutes == 0 { return "+0" }
        let sign = appliedMinutes > 0 ? "+" : "−"
        return "\(sign)\(DinoTimeWords.duration(abs(appliedMinutes), language: language))"
    }

    private var walkIdentity: String {
        "\(showsWork)-\(work.departure.digitalText)-\(work.combinedMinutes)-\(minuteStep)-\(language)"
    }

    @MainActor private func play() async {
        guard showsWork else {
            appliedMinutes = 0
            walking = false
            if !isDemonstration { totalProgress = 0 }
            return
        }
        let steps = work.walkMinutes(step: minuteStep)
        if isDemonstration || reduceMotion || steps.isEmpty {
            walking = true
            appliedMinutes = reduceMotion || steps.isEmpty ? work.combinedMinutes : 0
            totalProgress = work.offsetHours != 0 ? 1 : 0
            if isDemonstration && !reduceMotion && !steps.isEmpty {
                appliedMinutes = 0
            } else {
                return
            }
        }
        if !isDemonstration {
            appliedMinutes = 0
            walking = true
            totalProgress = 0
        }
        do {
            if !isDemonstration && work.offsetHours != 0 {
                try await Task.sleep(for: .milliseconds(180))
                withAnimation(.easeInOut(duration: 0.72)) { totalProgress = 1 }
            }
            try await Task.sleep(for: .milliseconds(isDemonstration ? 700 : 520))
            for step in steps {
                try Task.checkCancellation()
                let minute = abs(step) % 60 != 0
                withAnimation(.easeInOut(duration: minute ? 0.28 : 0.35)) { appliedMinutes = step }
                if step != steps.last {
                    try await Task.sleep(for: .milliseconds(minute ? 420 : 700))
                }
            }
        } catch { /* A new example or the next question cancels the walk. */ }
    }

    private func fieldLabel(_ key: String, color: Color) -> some View {
        Text(LocalizedStringKey(key))
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
    }

    private func timeChip(_ text: String, color: Color, identifier: String) -> some View {
        Text(verbatim: text)
            .font(.system(size: timeSize, weight: .heavy, design: .rounded))
            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.4)
            .foregroundStyle(color)
            .padding(.horizontal, 6).padding(.vertical, 5)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: timeSize + 12)
            .background(color.opacity(highContrast ? 0.16 : 0.12), in: RoundedRectangle(cornerRadius: 12))
            .accessibilityIdentifier(identifier)
    }

    private func factRow(title: LocalizedStringKey, systemImage: String, value: String,
                         color: Color, fill: Color, identifier: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                factLabel(title, systemImage: systemImage, color: color).fixedSize()
                Spacer(minLength: 0)
                factValue(value, color: color).fixedSize()
            }
            VStack(spacing: 6) {
                factLabel(title, systemImage: systemImage, color: color)
                factValue(value, color: color)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(fill.opacity(0.28), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }

    private func factLabel(_ title: LocalizedStringKey, systemImage: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .frame(width: factIcon, height: factIcon)
                .background(color.opacity(highContrast ? 0.22 : 0.14), in: Circle())
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
        }
        .foregroundStyle(color)
    }

    private func factValue(_ value: String, color: Color) -> some View {
        Text(verbatim: value)
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The route shares the time row, so the dashes cross the middle of the digits.
    private var flightPath: some View {
        ZStack {
            DinoFlightRoute()
                .stroke(DinoStyle.ink.opacity(highContrast ? 0.85 : 0.45),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 5]))
            Image(systemName: "airplane")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DinoStyle.ink)
                .padding(.horizontal, 5).background(.white)
        }
        .frame(height: timeSize + 8)
        .accessibilityHidden(true)
    }
}

/// Horizontal dashes through the vertical middle of the time row.
private struct DinoFlightRoute: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

/// Rounded paper with a small tear notch at either end of the perforation.
private struct DinoFlightTicketShape: Shape {
    func path(in rect: CGRect) -> Path {
        let corner: CGFloat = 28
        let seam = rect.minY + 64.5
        return Path { path in
            path.move(to: CGPoint(x: rect.minX + corner, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - corner, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + corner), control: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: seam - 8))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: seam + 8), control: CGPoint(x: rect.maxX - 16, y: seam))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - corner))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - corner, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + corner, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - corner), control: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: seam + 8))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: seam - 8), control: CGPoint(x: rect.minX + 16, y: seam))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + corner))
            path.addQuadCurve(to: CGPoint(x: rect.minX + corner, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
            path.closeSubpath()
        }
    }
}

/// A 24-hour ruler for the day-part example. Each stretch keeps its name, and the clock time marks the answer.
struct DinoDayPartLine: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @ObservedObject private var language = LanguageManager.shared
    let time: ClockTime
    let width: CGFloat
    var isDemonstration = true
    var schedule: DinoDayPartSchedule = .standard
    /// The question marks one moment. The settings overview only shows the stretches.
    var showsSelection = true

    private var prefix: String { isDemonstration ? "demo" : "question" }
    private var active: DinoDayPart { schedule.part(at: time.hour) }
    private var segments: [DinoDayPartSchedule.Segment] { schedule.timeline() }
    private var fraction: CGFloat { CGFloat(time.minutesOfDay) / (24 * 60) }
    private var barHeight: CGFloat { 36 }
    private var nameGap: CGFloat { 4 }

    var body: some View {
        let _ = language.effective.code
        VStack(spacing: 5) {
            names
            ZStack(alignment: .topLeading) {
                bar.padding(.top, showsSelection ? 13 : 0)
                if showsSelection {
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(DinoStyle.deepGreen)
                        .shadow(color: .white, radius: 1)
                        .frame(width: 14, height: 12)
                        .offset(x: fraction * width - 7, y: 1)
                        .accessibilityHidden(true)
                }
            }
            hours
        }
        .frame(width: width)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(showsSelection ? "\(prefix).dayPart.line" : "settings.dayParts.line")
    }

    private var names: some View {
        HStack(alignment: .top, spacing: nameGap) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                let part = segment.part
                let chosen = showsSelection && part == active
                ViewThatFits(in: .horizontal) {
                    nameLabel(part, chosen: chosen, showsName: true)
                    nameLabel(part, chosen: chosen, showsName: false)
                }
                .frame(width: nameWidth(segment))
                .padding(.vertical, 4)
                .background {
                    if chosen {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(DinoStyle.green.opacity(highContrast ? 0.55 : 0.32))
                    }
                }
                .overlay {
                    if chosen {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(DinoStyle.deepGreen, lineWidth: highContrast ? 2 : 1.5)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(L(key: part.titleKey)), \(hourText(schedule.start(of: part)))–\(hourText(schedule.endClock(of: part)))")
                .accessibilityIdentifier(accessibilityID(segment))
                .accessibilityAddTraits(showsSelection && segment.contains(time) ? .isSelected : [])
                .accessibilityHidden(!exposes(segment))
            }
        }
        .frame(height: 44)
    }

    private var bar: some View {
        HStack(spacing: 0) {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                let colors = segment.part.lineColors
                LinearGradient(colors: [colors.top, colors.bottom], startPoint: .top, endPoint: .bottom)
                    .frame(width: width * CGFloat(segment.end - segment.start) / 24)
                    .overlay(alignment: .trailing) {
                        if index < segments.count - 1 {
                            Rectangle().fill(.white.opacity(highContrast ? 1 : 0.92)).frame(width: 2)
                        }
                    }
            }
        }
        .frame(height: barHeight)
        .overlay {
            if showsSelection {
                GeometryReader { geometry in
                    ZStack {
                        Capsule().fill(.white).frame(width: 7, height: geometry.size.height - 8)
                        Capsule().fill(DinoStyle.deepGreen).frame(width: 3, height: geometry.size.height - 12)
                    }
                    .position(x: fraction * geometry.size.width, y: geometry.size.height / 2)
                }
            }
        }
        .clipShape(Capsule())
        .overlay {
            GeometryReader { geometry in
                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    if showsSelection && segment.part == active {
                        let start = geometry.size.width * CGFloat(segment.start) / 24
                        let end = geometry.size.width * CGFloat(segment.end) / 24
                        Capsule()
                            .strokeBorder(.white.opacity(0.95), lineWidth: 2)
                            .frame(width: max(6, end - start - 8), height: geometry.size.height - 8)
                            .position(x: (start + end) / 2, y: geometry.size.height / 2)
                    }
                }
            }
            .allowsHitTesting(false)
        }
        .overlay(Capsule().strokeBorder(highContrast ? DinoStyle.ink : .white.opacity(0.55), lineWidth: highContrast ? 2.5 : 2))
        .shadow(color: DinoStyle.ink.opacity(0.16), radius: 0, y: 3)
        .accessibilityHidden(true)
    }

    private func nameLabel(_ part: DinoDayPart, chosen: Bool, showsName: Bool) -> some View {
        VStack(spacing: 1) {
            Image(systemName: part.symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(part.symbolInk)
                .frame(height: 16)
            if showsName {
                Text(verbatim: L(key: part.titleKey))
                    .font(.system(size: width < 280 ? 12 : 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(chosen ? DinoStyle.deepGreen : DinoStyle.ink)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }

    private var hours: some View {
        ZStack {
            ForEach(hourPositions, id: \.hour) { mark in
                Text(verbatim: hourText(mark.hour))
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(hourInk(mark.hour))
                    .position(x: mark.x, y: 8)
            }
        }
        .frame(width: width, height: 16)
        .accessibilityHidden(true)
    }

    /// Keeps neighboring hours apart. A tight pair moves left so the right edge stays readable.
    private var hourPositions: [(hour: Int, x: CGFloat)] {
        let marks = hourMarks
        guard !marks.isEmpty else { return [] }
        let inset: CGFloat = 12
        let gap: CGFloat = 30
        var xs = marks.map { width * CGFloat($0) / 24 }
        xs[0] = max(xs[0], inset)
        xs[xs.count - 1] = min(xs[xs.count - 1], width - inset)
        if xs.count > 1 {
            for index in stride(from: xs.count - 2, through: 0, by: -1) {
                xs[index] = min(xs[index], xs[index + 1] - gap)
            }
            if xs[0] < inset {
                xs[0] = inset
                for index in 1..<xs.count {
                    xs[index] = max(xs[index], xs[index - 1] + gap)
                }
                xs[xs.count - 1] = min(xs[xs.count - 1], width - inset)
            }
        }
        return zip(marks, xs).map { (hour: $0.0, x: $0.1) }
    }

    private var hourMarks: [Int] {
        var marks: Set<Int> = [0, 24]
        for part in DinoDayPart.allCases {
            marks.insert(schedule.start(of: part))
            marks.insert(schedule.endClock(of: part))
        }
        return marks.sorted()
    }

    private func accessibilityID(_ segment: DinoDayPartSchedule.Segment) -> String {
        if !showsSelection {
            return exposes(segment) ? "settings.dayParts.line.\(segment.part.rawValue)" : "settings.dayParts.line.\(segment.part.rawValue).continued"
        }
        if segment.contains(time) { return isDemonstration ? "demo.answer" : "question.dayPart.answer" }
        if exposes(segment) { return "\(prefix).dayPart.\(segment.part.rawValue)" }
        return "\(prefix).dayPart.\(segment.part.rawValue).continued"
    }

    /// One VoiceOver element per part. The piece under the clock carries the answer.
    private func exposes(_ segment: DinoDayPartSchedule.Segment) -> Bool {
        let primary = segment.start == schedule.start(of: segment.part)
        if !showsSelection { return primary }
        if segment.contains(time) { return true }
        return primary && segment.part != active
    }

    private func nameWidth(_ segment: DinoDayPartSchedule.Segment) -> CGFloat {
        let gaps = nameGap * CGFloat(max(0, segments.count - 1))
        return max(0, (width - gaps) * CGFloat(segment.end - segment.start) / 24)
    }

    private func hourInk(_ hour: Int) -> Color {
        let marksAnswer = showsSelection && (hour == schedule.start(of: active) || hour == schedule.endClock(of: active))
        if marksAnswer { return DinoStyle.deepGreen }
        return highContrast ? DinoStyle.ink : DinoStyle.muted
    }

    private func hourText(_ hour: Int) -> String { String(format: "%02d", hour) }
}

private extension DinoDayPart {
    var lineColors: (top: Color, bottom: Color) {
        switch self {
        case .night: return (Color(dinoHex: 0x35597C), Color(dinoHex: 0x1C3654))
        case .morning: return (Color(dinoHex: 0xFFE7B0), Color(dinoHex: 0xF5C15A))
        case .afternoon: return (Color(dinoHex: 0xC8EE8C), Color(dinoHex: 0x74C83E))
        case .evening: return (Color(dinoHex: 0xFFC98A), Color(dinoHex: 0xF08A2C))
        }
    }
    var symbolInk: Color {
        switch self {
        case .night: return Color(dinoHex: 0x1C3654)
        case .morning: return Color(dinoHex: 0xC47A12)
        case .afternoon: return DinoStyle.deepGreen
        case .evening: return DinoStyle.deepOrange
        }
    }
}

struct DinoExpandedDemonstration: View {
    @EnvironmentObject private var player: DinoPlayer
    @EnvironmentObject private var settings: DinoSettings
    @ObservedObject private var deviceHourFormat = DeviceHourFormat.shared
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
                DinoQuestionTitle(question: sample.question, fontSize: 22, speechScope: "demo")
                    .accessibilityIdentifier("demo.title")
                if [.timeSequence, .addTime, .subtractTime].contains(kind) {
                    Text("dino.expanded.midnightHint").font(.footnote).multilineTextAlignment(.center)
                        .accessibilityIdentifier(kind == .timeSequence ? "demo.sequence.hint" : "demo.arithmetic.hint")
                }
                DinoExpandedQuestionView(session: sample, theme: theme, width: width, clockSize: 150, isDemonstration: true)
                    .id(sample.question.id)
                if !kind.usesOptions && ![.sortTimes, .advanceAnalog, .sayTime].contains(kind) {
                    Text(verbatim: answer(sample.question)).font(.system(size: 15, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center).accessibilityIdentifier("demo.answer")
                }
                if kind == .daySchedule, let schedule = sample.question.daySchedule {
                    let code = LanguageManager.shared.effective.code
                    let parts = [schedule.firstMinutes, schedule.breakMinutes, schedule.secondMinutes]
                        .map { DinoTimeWords.duration($0, language: code) }
                    Text(verbatim: "\(clockText(schedule.start, kind: kind)) + \(parts.joined(separator: " + ")) = \(clockText(schedule.end, kind: kind))")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true).multilineTextAlignment(.center)
                        .accessibilityIdentifier("demo.schedule.calculation")
                }
            }
            DinoDemonstrationActions(done: done) {
                var transaction = Transaction(animation: nil)
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    exampleIndex += 1
                    loadExample()
                }
            }
        }.frame(width: width).dinoCard()
            .background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 28))
            .foregroundStyle(DinoStyle.ink)
            .onAppear { loadExample() }
    }

    private func loadExample() {
        let configuration = DinoPracticeConfiguration(time: time, order: .specific(DinoPracticeQuestion(rawValue: kind.rawValue)!))
        let schedule = settings.dayPartSchedule
        let question = DinoDemonstrationExamples.question(kind: kind, minutes: worldMinutes ?? time.minutes,
                                                        minuteStep: worldMinutes == nil ? time.minuteStep : minuteStep,
                                                        index: exampleIndex, previousTarget: sample?.question.target,
                                                        language: LanguageManager.shared.effective.code,
                                                        dayPartSchedule: schedule)
        let next = DinoSession(level: configuration.level, player: player, practice: configuration,
                               example: question, exampleMinuteStep: worldMinutes == nil ? nil : minuteStep,
                               dayPartSchedule: schedule)
        if case .ordering(let times) = question.expectedAnswer { next.selectedOrder = times }
        sample = next
    }

    private func clockText(_ time: ClockTime, kind: ClockQuestionKind) -> String {
        let _ = deviceHourFormat.notation
        return theme.digitalReading(time, languageCode: LanguageManager.shared.effective.code,
                                    notation: kind == .read24Hour ? .twentyFour : nil)
    }

    private func answer(_ q: ClockQuestion) -> String {
        let code = LanguageManager.shared.effective.code
        let duration = DinoTimeWords.duration(q.durationMinutes, language: code)
        let answer: String
        switch q.expectedAnswer {
        case .time(let time):
            switch q.kind {
            case .readDigital, .read24Hour, .spokenTime: answer = "\(clockText(time, kind: q.kind)) = \(DinoTimeWords.time(time, language: code, dayPart: q.kind == .read24Hour, schedule: settings.dayPartSchedule))"
            case .addTime, .advanceAnalog: answer = "\(clockText(q.relatedTimes[0], kind: q.kind)) + \(duration) = \(clockText(time, kind: q.kind))"
            case .flightArrival:
                let work = DinoFlightArrivalWork(departure: q.relatedTimes[0], durationMinutes: q.durationMinutes,
                                                 offsetHours: q.offsetHours, arrival: time)
                let shift = q.offsetHours == 0 ? work.durationText(code) : work.combinedText(code)
                let sum = "\(clockText(work.departure, kind: q.kind)) + \(shift) = \(clockText(work.arrival, kind: q.kind))"
                answer = q.offsetHours == 0 ? sum : "\(work.differenceLine(language: code))\n\(sum)"
            case .subtractTime: answer = "\(clockText(q.relatedTimes[0], kind: q.kind)) − \(duration) = \(clockText(time, kind: q.kind))"
            case .timeSequence: answer = "\(clockText(q.relatedTimes.last!, kind: q.kind)) + \(duration) = \(clockText(time, kind: q.kind))"
            case .timeZone: answer = "\(clockText(q.relatedTimes[0], kind: q.kind)) \(q.offsetHours >= 0 ? "+" : "−") \(abs(q.offsetHours)) h = \(clockText(time, kind: q.kind))"
            default: answer = clockText(time, kind: q.kind)
            }
        case .truth(let correct): answer = "\(DinoTimeWords.time(q.target, language: code)) → \(L(key: correct ? "dino.expanded.true" : "dino.expanded.false"))"
        case .duration(let minutes): answer = "\(clockText(q.relatedTimes[0], kind: q.kind)) → \(clockText(q.relatedTimes[1], kind: q.kind)) = \(DinoTimeWords.duration(minutes, language: code))"
        case .dayPart(let part): answer = "\(clockText(q.target, kind: q.kind)) → \(L(key: part.titleKey))"
        case .ordering(let times): answer = times.map { clockText($0, kind: q.kind) }.joined(separator: " → ")
        case .pairs(let times): answer = times.map { "\(DinoTimeWords.time($0, language: code, dayPart: true, schedule: settings.dayPartSchedule)) = \(clockText($0, kind: q.kind))" }.joined(separator: "\n")
        case .spoken(let spoken): answer = q.spokenPrompt?.phrase(for: spoken) ?? ""
        }
        return answer
    }
}
