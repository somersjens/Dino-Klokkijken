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
            case .flightArrival:
                if isDemonstration || showsFlightWork {
                    DinoFlightArrivalExplanation(work: flightWork, language: code,
                                                 prefix: isDemonstration ? "demo" : "question")
                }
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
            DinoFlightTicket(departure: q.relatedTimes[0], duration: duration, offsetHours: q.offsetHours,
                             arrival: isDemonstration ? q.target : nil,
                             language: code, width: min(600, width), isDemonstration: isDemonstration)
        case .daySchedule:
            if let schedule = q.daySchedule {
                DinoDayScheduleCard(schedule: schedule,
                                    showsAnswer: isDemonstration || session.showsCorrectResponse,
                                    isDemonstration: isDemonstration)
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

    /// A wrong first try keeps the worked flight sum visible, including a later correct retry.
    private var showsFlightWork: Bool {
        !isDemonstration && !session.rejectedResponses.isEmpty
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
                    .accessibilityLabel(isDemonstration ? "+\(duration)" : "↓")
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
                    }.padding(12).frame(maxWidth: .infinity, minHeight: [.minutesBetween, .timeZone].contains(q.kind) && compactLayout ? 62 : 74)
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
                    }.buttonStyle(DinoAnswerButtonStyle()).disabled(session.hasFeedback || isDemonstration)
                        .accessibilityLabel(time.digitalText)
                        .accessibilityValue(position.map { String($0 + 1) } ?? "")
                        .accessibilityAddTraits(position == nil ? [] : .isSelected)
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
                Label("dino.expanded.correctOrder", systemImage: "checkmark.circle.fill").font(.subheadline.bold())
                Text(verbatim: responseText(q.expectedAnswer)).font(.system(size: 15, weight: .bold, design: .rounded))
                    .monospacedDigit().padding(12).modifier(ClockAnswerOutline(visible: true, correct: true))
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
            Label(LocalizedStringKey(correct ? "dino.correctTime" : "dino.yourAnswer"),
                  systemImage: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(correct ? DinoStyle.deepGreen : Color(dinoHex: 0xB54343))
                .multilineTextAlignment(.center)
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
                .accessibilityLabel(Text("dino.confirm")).accessibilityIdentifier("question.confirm")
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
        .accessibilityElement(children: .combine)
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
        .accessibilityElement(children: .contain)
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
                .accessibilityLabel(label)
                .accessibilityHidden(prefix == "demo")
                .accessibilityIdentifier("\(prefix).sequence.step.\(index)")
        }
    }
}

private struct DinoDayScheduleCard: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let schedule: DinoDaySchedule
    let showsAnswer: Bool
    let isDemonstration: Bool
    private var prefix: String { isDemonstration ? "demo" : "question" }
    private let colors = [DinoStyle.deepGreen, Color(dinoHex: 0x986020), Color(dinoHex: 0x377C95)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("dino.schedule.title", systemImage: "calendar")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                Spacer(minLength: 8)
                Image(systemName: "sun.max.fill").foregroundStyle(Color(dinoHex: 0xB87A25))
                    .accessibilityHidden(true)
            }.foregroundStyle(DinoStyle.deepGreen)

            VStack(spacing: 8) {
                GeometryReader { geometry in
                    HStack(spacing: 3) {
                        ForEach(0..<3) { index in
                            Group {
                                if index == 1 { Image(systemName: "pause.fill") }
                                else { Text(verbatim: index == 0 ? "1" : "2") }
                            }
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .frame(width: max(0, geometry.size.width - 6) * CGFloat(schedule.durations[index]) / CGFloat(schedule.totalMinutes), height: 32)
                            .foregroundStyle(colors[index])
                            .background(colors[index].opacity(highContrast ? 0.26 : 0.16), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }.frame(height: 32).accessibilityHidden(true)

                HStack(alignment: .top) {
                    endpoint(title: "dino.expanded.start", value: schedule.start.digitalText, alignment: .leading)
                        .accessibilityIdentifier("\(prefix).schedule.start")
                    Spacer(minLength: 12)
                    endpoint(title: "dino.schedule.finish", value: showsAnswer ? schedule.end.digitalText : "?", alignment: .trailing)
                        .accessibilityIdentifier("\(prefix).schedule.finish")
                }
            }

            VStack(spacing: 7) {
                activityRow(title: schedule.firstActivity.titleKey, symbol: schedule.firstActivity.symbol,
                            minutes: schedule.firstMinutes, index: 0)
                activityRow(title: "dino.schedule.break", symbol: "pause.fill", minutes: schedule.breakMinutes, index: 1)
                activityRow(title: schedule.secondActivity.titleKey, symbol: schedule.secondActivity.symbol,
                            minutes: schedule.secondMinutes, index: 2)
            }
        }
        .padding(16).frame(maxWidth: .infinity)
        .background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24)
            .stroke(highContrast ? DinoStyle.ink : DinoStyle.deepGreen.opacity(0.18), lineWidth: highContrast ? 2 : 1.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(prefix).schedule.card")
    }

    private func endpoint(title: String, value: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(LocalizedStringKey(title))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
            Text(verbatim: value).font(.system(size: 22, weight: .heavy, design: .rounded))
                .monospacedDigit().foregroundStyle(DinoStyle.deepGreen)
        }.accessibilityElement(children: .combine)
    }

    private func activityRow(title: String, symbol: String, minutes: Int, index: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 16, weight: .semibold))
                .frame(width: 24).foregroundStyle(colors[index]).accessibilityHidden(true)
            Text(LocalizedStringKey(title))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            Text(verbatim: "\(minutes) min").font(.system(size: 15, weight: .heavy, design: .rounded))
                .monospacedDigit().fixedSize()
        }
        .padding(.horizontal, 10).padding(.vertical, 9)
        .background(colors[index].opacity(highContrast ? 0.16 : 0.07), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("\(prefix).schedule.\(index == 1 ? "break" : "activity.\(index == 0 ? 1 : 2)")")
    }
}

/// Shared inks so each number on the ticket matches the same number in the worked sum.
private enum DinoFlightInk {
    static let departure = Color(dinoHex: 0x154A86)
    static let duration = Color(dinoHex: 0x9A3412)
    static let zone = Color(dinoHex: 0x0E6A78)
    static let combined = Color(dinoHex: 0x6B3FA0)
    static let arrival = DinoStyle.deepGreen
}

private struct DinoFlightTicket: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let departure: ClockTime
    let duration: String
    let offsetHours: Int
    let arrival: ClockTime?
    let language: String
    let width: CGFloat
    let isDemonstration: Bool
    private var prefix: String { isDemonstration ? "demo" : "question" }
    private var secondaryInk: Color { highContrast ? DinoStyle.ink : DinoStyle.muted }
    private var pathWidth: CGFloat { min(100, max(44, width * 0.2)) }
    private var timeSize: CGFloat { width < 300 ? 27 : 34 }

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
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        fieldLabel("dino.expanded.departure", color: DinoFlightInk.departure)
                        Color.clear.frame(width: pathWidth).accessibilityHidden(true)
                        fieldLabel("dino.expanded.arrival", color: arrival == nil ? secondaryInk : DinoFlightInk.arrival)
                    }
                    HStack(alignment: .center, spacing: 8) {
                        timeChip(departure.digitalText, color: DinoFlightInk.departure,
                                 identifier: "\(prefix).targetClock")
                        flightPath.frame(width: pathWidth)
                        if let arrival {
                            timeChip(arrival.digitalText, color: DinoFlightInk.arrival,
                                     identifier: "demo.answer")
                        } else {
                            Text(verbatim: "?")
                                .font(.system(size: timeSize, weight: .heavy, design: .rounded))
                                .foregroundStyle(secondaryInk)
                                .frame(maxWidth: .infinity, minHeight: timeSize + 8)
                                .background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(secondaryInk.opacity(0.45),
                                                  style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                                .accessibilityLabel(Text("dino.expanded.unknownArrival"))
                                .accessibilityIdentifier("\(prefix).flight.unknown")
                        }
                    }
                }

                VStack(spacing: 8) {
                    factRow(title: "dino.expanded.flightDuration", systemImage: "clock", value: duration,
                            color: DinoFlightInk.duration, identifier: "\(prefix).flight.duration")
                    if offsetHours != 0 {
                        factRow(title: "dino.expanded.flightZoneDifference", systemImage: "globe",
                                value: DinoTimeWords.hourDifference(offsetHours, language: language),
                                color: DinoFlightInk.zone, identifier: "\(prefix).flight.zone")
                    }
                }

                if offsetHours == 0 {
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
            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.75)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: timeSize + 8)
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
        .padding(12).frame(maxWidth: .infinity)
        .background(color.opacity(highContrast ? 0.14 : 0.10), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }

    private func factLabel(_ title: LocalizedStringKey, systemImage: String, color: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 13, weight: .bold, design: .rounded))
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

/// Duration and the zone difference become one shift, which is then added to the departure.
private struct DinoFlightArrivalExplanation: View {
    let work: DinoFlightArrivalWork
    let language: String
    var prefix = "demo"

    var body: some View {
        VStack(spacing: 8) {
            if work.offsetHours != 0 {
                equation([
                    (work.durationText(language), DinoFlightInk.duration),
                    (" \(work.zoneSign) ", DinoStyle.ink),
                    (work.zoneText(language), DinoFlightInk.zone),
                    (" = ", DinoStyle.ink),
                    (work.combinedText(language), DinoFlightInk.combined)
                ])
                .accessibilityIdentifier("\(prefix).flight.differenceStep")
            }
            equation([
                (work.departure.digitalText, DinoFlightInk.departure),
                (" + ", DinoStyle.ink),
                (work.offsetHours == 0 ? work.durationText(language) : work.combinedText(language),
                 work.offsetHours == 0 ? DinoFlightInk.duration : DinoFlightInk.combined),
                (" = ", DinoStyle.ink),
                (work.arrival.digitalText, DinoFlightInk.arrival)
            ])
            .accessibilityIdentifier("\(prefix).flight.arrivalStep")
        }
        .monospacedDigit().multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(12).frame(maxWidth: .infinity)
        .background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(DinoStyle.deepGreen.opacity(0.16), lineWidth: 1.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(prefix).flight.calculation")
    }

    private func equation(_ parts: [(String, Color)]) -> Text {
        var line = AttributedString()
        for part in parts {
            var run = AttributedString(part.0)
            run.foregroundColor = part.1
            line += run
        }
        line.font = .system(size: 19, weight: .heavy, design: .rounded).monospacedDigit()
        return Text(line)
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
                    Text(verbatim: "\(schedule.start.digitalText) + \(schedule.firstMinutes) min + \(schedule.breakMinutes) min + \(schedule.secondMinutes) min = \(schedule.end.digitalText)")
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
            .foregroundStyle(DinoStyle.ink).accessibilityElement(children: .contain)
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
