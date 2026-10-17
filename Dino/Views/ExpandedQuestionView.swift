import SwiftUI

private struct SequenceClockAnchors: PreferenceKey {
    static var defaultValue: [Int: Anchor<CGRect>] { [:] }

    static func reduce(value: inout [Int: Anchor<CGRect>], nextValue: () -> [Int: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

struct DinoExpandedQuestionView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var session: DinoSession
    @ObservedObject private var language = LanguageManager.shared
    let theme: ClockTheme
    let width: CGFloat
    let clockSize: CGFloat
    var isDemonstration = false
    var compactLayout = false
    @State private var movingMinutes = false
    private var q: ClockQuestion { session.question }
    private var code: String { language.effective.code }
    private var duration: String { DinoTimeWords.duration(q.durationMinutes, language: code) }

    var body: some View {
        VStack(spacing: q.kind == .timeZone && compactLayout ? 12 : 18) {
            if q.kind != .advanceAnalog {
                VStack(spacing: 12) { context }
                    .frame(maxWidth: min(q.kind == .timeZone ? 760 : 600, width))
                    .frame(maxWidth: .infinity)
            }
            switch q.kind {
            case .sortTimes: sorting
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
                                   explainsLive: showsTimeZoneWalk)
            }
        case .addTime, .subtractTime:
            DigitalClock(time: q.relatedTimes[0], theme: theme, fontSize: min(48, width * 0.14))
                .accessibilityIdentifier(isDemonstration ? "demo.targetClock" : "question.targetClock")
            timeChange
        case .flightArrival:
            DinoFlightTicket(work: flightWork, showsWork: isDemonstration || showsFlightWork,
                             minuteStep: session.minuteStep, language: code, width: min(600, width),
                             isDemonstration: isDemonstration)
        case .daySchedule:
            if let schedule = q.daySchedule {
                DinoTrainJourneyCard(schedule: schedule,
                                     showsAnswer: isDemonstration || session.showsCorrectResponse,
                                     countsTotal: showsTrainSum, minuteStep: session.minuteStep,
                                     isDemonstration: isDemonstration, language: code)
            }
        default:
            // SwiftUI can update an outgoing view after the shared session has advanced.
            EmptyView()
        }
    }

    private var timeChange: some View {
        Label {
            Text(verbatim: "\(duration) \(L(key: q.kind == .subtractTime ? "dino.expanded.earlier" : "dino.expanded.later"))")
        } icon: { Image(systemName: q.kind == .subtractTime ? "minus.circle.fill" : "plus.circle.fill") }
            .font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(DinoStyle.deepGreen)
    }

    /// After a miss, the two known jumps appear before the player continues.
    private var showsSequencePattern: Bool {
        !isDemonstration && (session.retryAnsweredCorrectly || session.answerRevealed)
    }

    /// A wrong first try, then the right answer or Show answer, replays the hour walk.
    private var showsTimeZoneWalk: Bool {
        !isDemonstration && (session.retryAnsweredCorrectly || session.answerRevealed)
    }

    /// Plays once the player stays on the question: a correct retry, or Show answer.
    /// A correct first answer moves on by itself, so the walk is not started for that brief moment.
    private var showsFlightWork: Bool {
        !isDemonstration && !session.shouldAutoAdvance && (session.correctFeedback || session.answerRevealed)
    }

    /// A wrong first answer stays on screen, so the three ride times can be summed before the next try.
    private var showsTrainSum: Bool {
        !isDemonstration && session.hasFeedback && !session.shouldAutoAdvance
    }

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
            if isDemonstration || showsSequencePattern {
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
                        .fixedSize(horizontal: false, vertical: true)
                        // Reserve four lines so refreshing a longer day-part answer
                        // cannot move the action buttons or recenter the example card.
                        .frame(height: q.kind == .read24Hour ? 120 : nil)
                }
            }
        }.frame(maxWidth: .infinity)
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
        }.id("question.answers")
    }

    private func responseText(_ response: ClockAnswer) -> String {
        switch response {
        case .time(let time):
            if [.readDigital, .read24Hour].contains(q.kind) { return DinoTimeWords.time(time, language: code, dayPart: q.kind == .read24Hour) }
            return time.digitalText
        case .duration(let minutes):
            return q.kind == .minutesBetween ? DinoTimeWords.minutes(minutes, language: code)
                : DinoTimeWords.duration(minutes, language: code)
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
                                            .background(DinoStyle.green, in: Circle())
                                            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                                            .offset(x: badgeInset, y: badgeInset)
                                            .accessibilityHidden(true)
                                    }
                                }
                            Text(verbatim: time.digitalText).font(.system(size: 17, weight: .bold, design: .rounded)).monospacedDigit()
                        }.padding(12).frame(maxWidth: .infinity).background(.white, in: RoundedRectangle(cornerRadius: 22))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(position == nil ? .clear : DinoStyle.deepGreen, lineWidth: 3))
                    }.buttonStyle(DinoAnswerButtonStyle()).disabled(session.hasFeedback || isDemonstration)
                        .accessibilityIdentifier("\(isDemonstration ? "demo" : "question").sort.\(index)")
                }
            }.id("question.answers")
            if !session.selectedOrder.isEmpty {
                Text(verbatim: session.selectedOrder.map(\.digitalText).joined(separator: " → "))
                    .font(.system(size: 15, weight: .bold, design: .rounded)).monospacedDigit().multilineTextAlignment(.center)
                    .padding(12).modifier(ClockAnswerOutline(visible: session.hasFeedback, correct: session.correctFeedback))
                    .accessibilityIdentifier(isDemonstration ? "demo.answer" : "question.sort.selection")
            }
            if session.hasFeedback && !session.correctFeedback {
                Text(verbatim: responseText(q.expectedAnswer)).font(.system(size: 15, weight: .bold, design: .rounded))
                    .monospacedDigit().padding(12).modifier(ClockAnswerOutline(visible: true, correct: true))
                    .accessibilityIdentifier("question.sort.correct")
            }
            if !isDemonstration {
                confirm(.ordering(session.selectedOrder), enabled: session.selectedOrder.count == 4)
            }
        }
    }

    private var advanceComparing: Bool { session.hasFeedback && !session.correctFeedback }

    private var advanceFace: CGFloat {
        let limit: CGFloat = advanceComparing ? 96 : (compactLayout ? 112 : 148)
        return min(limit, max(72, (width - 96) / 2))
    }

    private var analogAdvance: some View {
        let hourChange: ((Int) -> Void)? = session.hasFeedback || movingMinutes ? nil : { session.inputHour = $0 }
        let minuteChange: ((ClockTime) -> Void)? = session.hasFeedback || !movingMinutes ? nil : { session.setInputTime($0) }
        let shown = session.attempt.submittedAnswer ?? session.inputTime
        return VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 6) {
                AnalogClock(time: DinoAnalogAdvanceExample.face(q.relatedTimes[0]), theme: theme, size: advanceFace)
                    .accessibilityIdentifier("question.startClock")
                DinoAdvanceDifference(minutes: q.durationMinutes, language: code, prefix: "question")
                if advanceComparing {
                    VStack(spacing: 8) {
                        advanceResult(shown, correct: false, identifier: "question.analogControl")
                        advanceResult(DinoAnalogAdvanceExample.face(q.target), correct: true, identifier: "question.correctClock")
                    }
                } else {
                    AnalogClock(time: shown, theme: theme, size: advanceFace,
                                onHourChange: hourChange, onMinuteChange: minuteChange, minuteStep: session.minuteStep)
                        .padding(4)
                        .modifier(ClockAnswerOutline(visible: session.hasFeedback, correct: session.correctFeedback))
                        .accessibilityIdentifier("question.analogControl")
                }
            }
            VStack(spacing: 12) {
                DinoAnalogClockControls(adjustingMinutes: $movingMinutes, allowsMinutes: session.allowsMinutes,
                                        minuteStep: session.minuteStep, adjust: adjust)
                Button { session.submit(.time(session.inputTime)) } label: {
                    Label("dino.clock.check", systemImage: "checkmark")
                        .lineLimit(1).minimumScaleFactor(0.75)
                }.buttonStyle(DinoButtonStyle())
                    .accessibilityIdentifier("question.confirm")
            }
            .frame(maxWidth: min(380, width))
            .opacity(session.hasFeedback ? 0 : 1)
            .allowsHitTesting(!session.hasFeedback)
            .accessibilityHidden(session.hasFeedback)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: session.hasFeedback)
        }.id("question.answers")
    }

    private func advanceResult(_ time: ClockTime, correct: Bool, identifier: String) -> some View {
        VStack(spacing: 4) {
            AnalogClock(time: time, theme: theme, size: advanceFace)
                .padding(4)
                .modifier(ClockAnswerOutline(visible: true, correct: correct))
                .accessibilityIdentifier(identifier)
            AnswerVerdictMark(correct: correct, size: 22)
        }
    }

    private func adjust(_ direction: Int) {
        if movingMinutes { session.adjustInputMinutes(by: direction * session.minuteStep) }
        else { session.inputHour = ClockTime.shiftedHour(session.inputHour, by: direction) }
    }
    @ViewBuilder private func confirm(_ answer: ClockAnswer, enabled: Bool) -> some View {
        if !session.hasFeedback {
            Button { session.submit(answer) } label: { Image(systemName: "checkmark").font(.title2.bold()) }
                .buttonStyle(DinoButtonStyle()).frame(maxWidth: 260).disabled(!enabled)
                .accessibilityIdentifier("question.confirm")
        }
    }
}

struct DinoAdvanceDifference: View {
    let minutes: Int
    let language: String
    var prefix = "question"

    var body: some View {
        VStack(spacing: 4) {
            Text(verbatim: "+\(DinoTimeWords.duration(minutes, language: language))")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.65)
                .fixedSize(horizontal: false, vertical: true)
            Image(systemName: "arrow.right")
                .font(.system(size: 18, weight: .bold))
                .accessibilityHidden(true)
        }
        .foregroundStyle(DinoStyle.deepGreen)
        .frame(width: 78)
        .accessibilityIdentifier("\(prefix).advance.difference")
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
                .background(DinoStyle.paper, in: Capsule())
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
    let minuteStep: Int
    let isDemonstration: Bool
    let language: String
    @State private var summedMinutes = 0
    @State private var showsTotal = false
    private var prefix: String { isDemonstration ? "demo" : "question" }

    private let ride = Color(dinoHex: 0x1A4E86)
    private let rideFill = Color(dinoHex: 0xE7F1FB)
    private let rideChip = Color(dinoHex: 0xD4E6F8)
    private let transferFill = Color(dinoHex: 0xFFF3DF)
    private let transferChip = Color(dinoHex: 0xFFE0B8)
    private let arrivalFill = Color(dinoHex: 0xE7F7DC)
    private let arrivalChip = Color(dinoHex: 0xD5F0C2)
    private let totalInk = Color(dinoHex: 0x5E6A70)

    var body: some View {
        VStack(spacing: 2) {
            leg(symbol: "building.columns.fill", title: "dino.train.departure",
                value: schedule.start.digitalText, ink: ride, fill: rideFill, chip: rideChip,
                identifier: "\(prefix).schedule.start")
            connector
            leg(symbol: "train.side.front.car", title: "dino.train.one",
                value: DinoTimeWords.duration(schedule.firstMinutes, language: language),
                ink: ride, fill: rideFill, chip: rideChip,
                identifier: "\(prefix).schedule.activity.1")
            connector
            leg(symbol: "figure.walk", title: "dino.train.transfer",
                value: DinoTimeWords.duration(schedule.breakMinutes, language: language),
                ink: DinoStyle.deepOrange, fill: transferFill, chip: transferChip,
                identifier: "\(prefix).schedule.break")
            connector
            leg(symbol: "train.side.front.car", title: "dino.train.two",
                value: DinoTimeWords.duration(schedule.secondMinutes, language: language),
                ink: ride, fill: rideFill, chip: rideChip,
                identifier: "\(prefix).schedule.activity.2")
            VStack(spacing: 0) {
                if showsTotal { totalRow }
            }
            .clipped()
            .animation(.spring(duration: 0.55, bounce: 0.04), value: showsTotal)
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
        .task(id: walkIdentity) { await play() }
    }

    private var connector: some View {
        Image(systemName: "arrow.down")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
            .accessibilityHidden(true)
    }

    /// The two trains and the transfer, counted the same way as a flight duration.
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
            Text(verbatim: DinoTimeWords.duration(summedMinutes, language: language))
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.55)
                .contentTransition(.numericText())
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background((highContrast ? DinoStyle.ink : totalInk).opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .layoutPriority(1)
        }
        .foregroundStyle(highContrast ? DinoStyle.ink : totalInk)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background((highContrast ? DinoStyle.ink : totalInk).opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.top, 4)
        .transition(.move(edge: .top).combined(with: .opacity))
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
        let text = showsAnswer ? schedule.end.digitalText : "?"
        return Text(verbatim: text)
            .font(.system(size: showsAnswer ? 14 : 18, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .lineLimit(1).minimumScaleFactor(0.6)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .frame(minWidth: showsAnswer ? 0 : 52, minHeight: 26)
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

    private var walkIdentity: String {
        "\(countsTotal)-\(schedule.start.digitalText)-\(schedule.totalMinutes)-\(minuteStep)-\(language)"
    }

    private var walkSteps: [Int] {
        DinoFlightArrivalWork(departure: schedule.start, durationMinutes: schedule.totalMinutes,
                              offsetHours: 0, arrival: schedule.end).walkMinutes(step: minuteStep)
    }

    @MainActor private func play() async {
        guard countsTotal else {
            summedMinutes = 0
            showsTotal = false
            return
        }
        let steps = walkSteps
        if reduceMotion || steps.isEmpty {
            showsTotal = true
            summedMinutes = schedule.totalMinutes
            return
        }
        summedMinutes = 0
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) { showsTotal = false }
        do {
            try await Task.sleep(for: .milliseconds(280))
            withAnimation(.spring(duration: 0.55, bounce: 0.04)) { showsTotal = true }
            try await Task.sleep(for: .milliseconds(700))
            for step in steps {
                try Task.checkCancellation()
                let minute = step % 60 != 0
                withAnimation(.easeInOut(duration: minute ? 0.28 : 0.35)) { summedMinutes = step }
                if step != steps.last {
                    try await Task.sleep(for: .milliseconds(minute ? 420 : 700))
                }
            }
        } catch { /* The next question cancels the count. */ }
    }
}

/// Shared inks so each number on the ticket stays distinct from the gray total.
private enum DinoFlightInk {
    static let departure = Color(dinoHex: 0x154A86)
    static let duration = Color(dinoHex: 0x9A3412)
    static let zone = Color(dinoHex: 0x0E6A78)
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
                        timeChip(work.departure.digitalText, color: DinoFlightInk.departure,
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
                            timeChip(shownArrival.digitalText, color: DinoFlightInk.arrival,
                                     identifier: isDemonstration ? "demo.answer" : "\(prefix).flight.arrival")
                                .contentTransition(.numericText())
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
                            value: work.durationText(language), color: DinoFlightInk.duration,
                            identifier: "\(prefix).flight.duration")
                    if work.offsetHours != 0 {
                        factRow(title: "dino.expanded.flightZoneDifference", systemImage: "globe",
                                value: DinoTimeWords.hourDifference(work.offsetHours, language: language),
                                color: DinoFlightInk.zone, identifier: "\(prefix).flight.zone")
                        if totalAmount > 0.01 { totalReveal }
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
        .frame(height: isDemonstration || totalRowAmount >= 1 ? nil : 62 * totalRowAmount, alignment: .top)
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
                .contentTransition(.numericText())
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
                         color: Color, identifier: String) -> some View {
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
        .background(color.opacity(highContrast ? 0.14 : 0.10), in: RoundedRectangle(cornerRadius: 16))
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
                if [.timeSequence, .addTime, .subtractTime].contains(kind) {
                    Text("dino.expanded.midnightHint").font(.footnote).multilineTextAlignment(.center)
                        .accessibilityIdentifier(kind == .timeSequence ? "demo.sequence.hint" : "demo.arithmetic.hint")
                }
                DinoExpandedQuestionView(session: sample, theme: theme, width: width, clockSize: 150, isDemonstration: true)
                    .id(sample.question.id)
                if !kind.usesOptions && ![.sortTimes, .advanceAnalog].contains(kind) {
                    Text(verbatim: answer(sample.question)).font(.system(size: 15, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center).accessibilityIdentifier("demo.answer")
                }
                if kind == .daySchedule, let schedule = sample.question.daySchedule {
                    let code = LanguageManager.shared.effective.code
                    let parts = [schedule.firstMinutes, schedule.breakMinutes, schedule.secondMinutes]
                        .map { DinoTimeWords.duration($0, language: code) }
                    Text(verbatim: "\(schedule.start.digitalText) + \(parts.joined(separator: " + ")) = \(schedule.end.digitalText)")
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
        let question = DinoDemonstrationExamples.question(kind: kind, minutes: worldMinutes ?? time.minutes,
                                                        minuteStep: worldMinutes == nil ? time.minuteStep : minuteStep,
                                                        index: exampleIndex, previousTarget: sample?.question.target,
                                                        language: LanguageManager.shared.effective.code)
        let next = DinoSession(level: configuration.level, player: player, practice: configuration,
                               example: question, exampleMinuteStep: worldMinutes == nil ? nil : minuteStep)
        if case .ordering(let times) = question.expectedAnswer { next.selectedOrder = times }
        sample = next
    }

    private func answer(_ q: ClockQuestion) -> String {
        let code = LanguageManager.shared.effective.code
        let duration = DinoTimeWords.duration(q.durationMinutes, language: code)
        let answer: String
        switch q.expectedAnswer {
        case .time(let time):
            switch q.kind {
            case .readDigital, .read24Hour, .spokenTime: answer = "\(time.digitalText) = \(DinoTimeWords.time(time, language: code, dayPart: q.kind == .read24Hour))"
            case .addTime, .advanceAnalog: answer = "\(q.relatedTimes[0].digitalText) + \(duration) = \(time.digitalText)"
            case .flightArrival:
                let work = DinoFlightArrivalWork(departure: q.relatedTimes[0], durationMinutes: q.durationMinutes,
                                                 offsetHours: q.offsetHours, arrival: time)
                answer = q.offsetHours == 0 ? work.arrivalLine(language: code)
                    : "\(work.differenceLine(language: code))\n\(work.arrivalLine(language: code))"
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
