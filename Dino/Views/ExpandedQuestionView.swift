import SwiftUI

private struct SequenceClockAnchors: PreferenceKey {
    static var defaultValue: [Int: Anchor<CGRect>] { [:] }

    static func reduce(value: inout [Int: Anchor<CGRect>], nextValue: () -> [Int: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

struct DinoExpandedQuestionView: View {
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
            VStack(spacing: 12) { context }
                .frame(maxWidth: min(q.kind == .timeZone ? 760 : 600, width))
                .frame(maxWidth: .infinity)
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
        case .elapsedTime:
            HStack(spacing: 12) {
                timeCard(q.relatedTimes[0], title: "dino.expanded.start")
                Image(systemName: "arrow.right").foregroundStyle(DinoStyle.deepGreen)
                timeCard(q.relatedTimes[1], title: "dino.expanded.end")
            }
            if !isDemonstration { Text("dino.expanded.midnightHint").font(.footnote).multilineTextAlignment(.center) }
        case .timeZone:
            if let journey = q.timeZoneJourney, let referenceTime = q.relatedTimes.first {
                DinoTimeZoneMap(journey: journey, referenceTime: referenceTime,
                                answer: q.target, showsAnswer: isDemonstration || session.showsCorrectResponse,
                                isDemonstration: isDemonstration, compactLayout: compactLayout && width >= 600)
            }
        case .addTime, .subtractTime:
            DigitalClock(time: q.relatedTimes[0], theme: theme, fontSize: min(48, width * 0.14))
                .accessibilityIdentifier(isDemonstration ? "demo.targetClock" : "question.targetClock")
            timeChange
        case .flightArrival:
            DinoFlightTicket(departure: q.relatedTimes[0], duration: duration, width: min(600, width),
                             isDemonstration: isDemonstration)
        case .daySchedule:
            if let schedule = q.daySchedule {
                DinoDayScheduleCard(schedule: schedule,
                                    showsAnswer: isDemonstration || session.showsCorrectResponse,
                                    isDemonstration: isDemonstration)
            }
        case .advanceAnalog, .schoolEnd:
            if q.kind == .schoolEnd { Label("dino.expanded.school", systemImage: "book.fill").font(.headline) }
            timeCard(q.relatedTimes[0], title: "dino.expanded.start")
            timeChange
            if !isDemonstration {
                Text("dino.expanded.midnightHint")
                    .font(.footnote).multilineTextAlignment(.center)
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

    private var timeSequence: some View {
        VStack(spacing: isDemonstration ? 6 : 4) {
            ForEach(Array(q.relatedTimes.enumerated()), id: \.offset) { index, time in
                DigitalClock(time: time, theme: theme, fontSize: sequenceClockFont)
                    .anchorPreference(key: SequenceClockAnchors.self, value: .bounds) { [index: $0] }
                    .accessibilityIdentifier("\(isDemonstration ? "demo" : "question").sequence.clock.\(index)")
                Image(systemName: "arrow.down")
                    .font(.system(size: isDemonstration ? 17 : 15, weight: .bold)).foregroundStyle(DinoStyle.deepGreen)
                    .accessibilityLabel(isDemonstration ? "+\(duration)" : "↓")
                    .accessibilityIdentifier("\(isDemonstration ? "demo" : "question").sequence.arrow.\(index)")
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
        .padding(.trailing, isDemonstration ? 112 : 0)
        .frame(maxWidth: .infinity)
        .overlayPreferenceValue(SequenceClockAnchors.self) { anchors in
            if isDemonstration {
                GeometryReader { geometry in
                    ForEach(q.relatedTimes.indices, id: \.self) { index in
                        if let from = anchors[index], let to = anchors[index + 1] {
                            sequenceStep(from: geometry[from], to: geometry[to])
                        }
                    }
                }.allowsHitTesting(false).accessibilityHidden(true)
            }
        }
    }

    private var sequenceClockFont: CGFloat { isDemonstration ? 32 : min(width >= 600 ? 42 : 36, width * 0.10) }

    private func sequenceStep(from: CGRect, to: CGRect) -> some View {
        let start = CGPoint(x: from.maxX + 5, y: from.midY)
        let end = CGPoint(x: to.maxX + 5, y: to.midY)
        let curveX = max(start.x, end.x) + 32
        return ZStack(alignment: .topLeading) {
            Path { path in
                path.move(to: start)
                path.addCurve(to: end,
                              control1: CGPoint(x: curveX, y: start.y),
                              control2: CGPoint(x: curveX, y: end.y))
                path.move(to: CGPoint(x: end.x + 6, y: end.y - 5))
                path.addLine(to: end)
                path.addLine(to: CGPoint(x: end.x + 7, y: end.y + 3))
            }.stroke(DinoStyle.deepGreen, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            Text(verbatim: "+\(duration)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(DinoStyle.deepGreen)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 70, alignment: .leading)
                .position(x: curveX + 37, y: (start.y + end.y) / 2)
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

    private var analogAdvance: some View {
        let hourChange: ((Int) -> Void)? = session.hasFeedback || movingMinutes ? nil : { session.inputHour = $0 }
        let minuteChange: ((ClockTime) -> Void)? = session.hasFeedback || !movingMinutes ? nil : { session.setInputTime($0) }
        return VStack(spacing: 16) {
            AnalogClockAnswerComparison(answer: session.attempt.submittedAnswer ?? session.inputTime,
                                        target: q.target, theme: theme, width: width, clockSize: min(190, clockSize),
                                        hasFeedback: session.hasFeedback, correct: session.correctFeedback,
                                        onHourChange: hourChange, onMinuteChange: minuteChange,
                                        minuteStep: session.minuteStep)
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

private struct DinoFlightTicket: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let departure: ClockTime
    let duration: String
    let width: CGFloat
    let isDemonstration: Bool
    private var prefix: String { isDemonstration ? "demo" : "question" }
    private var secondaryInk: Color { highContrast ? DinoStyle.ink : DinoStyle.muted }

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
                HStack(spacing: 8) {
                    VStack(spacing: 6) {
                        fieldLabel("dino.expanded.departure")
                        Text(verbatim: departure.digitalText)
                            .font(.system(size: width < 300 ? 27 : 34, weight: .heavy, design: .rounded))
                            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.75)
                            .accessibilityIdentifier("\(prefix).targetClock")
                    }.frame(maxWidth: .infinity)

                    flightPath.frame(width: min(100, width * 0.2))

                    VStack(spacing: 6) {
                        fieldLabel("dino.expanded.arrival")
                        Text(verbatim: "?")
                            .font(.system(size: width < 300 ? 27 : 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(DinoStyle.deepGreen)
                            .frame(maxWidth: .infinity)
                            .background(DinoStyle.green.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel(Text("dino.expanded.unknownArrival"))
                            .accessibilityIdentifier("\(prefix).flight.unknown")
                    }.frame(maxWidth: .infinity)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        durationLabel.fixedSize()
                        Spacer(minLength: 0)
                        durationValue.fixedSize()
                    }
                    VStack(spacing: 6) { durationLabel; durationValue }
                }
                .padding(12).frame(maxWidth: .infinity)
                .background(DinoStyle.paper, in: RoundedRectangle(cornerRadius: 16))
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("\(prefix).flight.duration")

                Text("dino.expanded.flightZone")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
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

    private func fieldLabel(_ key: String) -> some View {
        Text(LocalizedStringKey(key))
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(secondaryInk)
    }

    private var durationLabel: some View {
        Label("dino.expanded.flightDuration", systemImage: "clock")
            .font(.system(size: 13, weight: .bold, design: .rounded))
    }

    private var durationValue: some View {
        Text(verbatim: duration)
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .foregroundStyle(DinoStyle.deepGreen)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var flightPath: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 16))
                path.addLine(to: CGPoint(x: min(100, width * 0.2), y: 16))
            }.stroke(DinoStyle.deepGreen.opacity(highContrast ? 0.8 : 0.35),
                     style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 5]))
            Image(systemName: "airplane")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(DinoStyle.deepGreen)
                .padding(.horizontal, 6).background(.white)
        }.frame(height: 32).accessibilityHidden(true)
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
                if !kind.usesOptions && kind != .sortTimes {
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
