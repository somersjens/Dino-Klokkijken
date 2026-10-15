import SwiftUI

struct QuestionRenderer: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var session: DinoSession
    @State private var adjustingMinutes = false
    let theme: ClockTheme
    let width: CGFloat
    let clockSize: CGFloat
    var wideLayout = false
    var compactLayout = false
    var answerClockSize: CGFloat = 210
    private var comparing: Bool { session.hasFeedback && !session.correctFeedback }
    private var question: ClockQuestion { session.question }
    private var targetSize: CGFloat { min(clockSize, width - 20) }

    var body: some View {
        VStack(spacing: compactLayout ? 14 : 22) {
            switch question.kind {
            case .chooseAnalog, .activity:
                targetCard
                analogOptions
            case .chooseDigital:
                analogTarget
                digitalOptions
            case .setAnalog:
                targetCard
                analogInput.id("question.answers")
                if !session.hasFeedback {
                    if session.allowsMinutes {
                        Picker("dino.practice.hand", selection: $adjustingMinutes) {
                            Text("dino.hours").tag(false)
                            Text("dino.minutes").tag(true)
                        }.pickerStyle(.segmented).frame(maxWidth: 280)
                            .accessibilityIdentifier("question.hand")
                    }
                    HStack(spacing: 14) {
                        DinoIconButton(icon: "arrow.counterclockwise", labelKey: adjustingMinutes ? "dino.minuteLess" : "dino.hourLess") { adjustAnalog(by: -1) }
                            .accessibilityIdentifier("question.analog.less")
                        Image(systemName: "hand.draw.fill").font(.title2).foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                        DinoIconButton(icon: "arrow.clockwise", labelKey: adjustingMinutes ? "dino.minuteMore" : "dino.hourMore") { adjustAnalog(by: 1) }
                            .accessibilityIdentifier("question.analog.more")
                    }
                }
                confirmButton
            case .setDigital:
                analogTarget
                digitalInput.id("question.answers")
                confirmButton
            case .match:
                ClockMatchingBoard(times: question.relatedTimes, options: question.options,
                                   selections: $session.pairSelections, theme: theme, width: width,
                                   hasFeedback: session.hasFeedback)
                    .id("question.answers")
                if !session.hasFeedback {
                    Button { session.submit(.pairs(question.relatedTimes.indices.compactMap { session.pairSelections[$0] })) } label: {
                        Image(systemName: "checkmark").font(.system(size: 25, weight: .heavy))
                    }.buttonStyle(DinoButtonStyle()).frame(maxWidth: 260)
                        .disabled(session.pairSelections.count != question.relatedTimes.count)
                        .accessibilityLabel(Text("dino.confirm")).accessibilityIdentifier("question.confirm")
                }
            default:
                DinoExpandedQuestionView(session: session, theme: theme, width: width, clockSize: clockSize)
            }
        }.frame(maxWidth: .infinity)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.34), value: session.hasFeedback)
    }

    private var analogInput: some View {
        let cellWidth = (width - 14) / 2
        let scale = comparing ? min(1, (cellWidth - 12) / (targetSize + 20)) : 1
        let height = (targetSize + 20) * scale
        let hourChange: ((Int) -> Void)? = session.hasFeedback || adjustingMinutes ? nil : { session.inputHour = $0 }
        let minuteChange: ((ClockTime) -> Void)? = session.hasFeedback || !adjustingMinutes ? nil : { session.setInputTime($0) }
        return HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 10) {
                AnalogClock(time: session.attempt.submittedAnswer ?? session.inputTime, theme: theme, size: targetSize,
                            onHourChange: hourChange,
                            onMinuteChange: minuteChange,
                            minuteStep: session.minuteStep)
                    .accessibilityIdentifier("question.analogControl")
                    .padding(10).modifier(ClockAnswerOutline(visible: session.hasFeedback, correct: session.correctFeedback))
                    .scaleEffect(scale).frame(width: comparing ? cellWidth : width, height: height)
                if comparing { comparisonLabel(correct: false) }
            }
            if comparing {
                VStack(spacing: 10) {
                    AnalogClock(time: question.target, theme: theme, size: targetSize).padding(10)
                        .modifier(ClockAnswerOutline(visible: true, correct: true))
                        .scaleEffect(scale).frame(width: cellWidth, height: height)
                        .accessibilityIdentifier("question.correctClock")
                    comparisonLabel(correct: true)
                }.transition(reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity))
            }
        }.frame(width: width)
    }

    @ViewBuilder private var digitalInput: some View {
        if session.hasFeedback {
            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 10) {
                    DigitalClock(time: session.attempt.submittedAnswer ?? session.inputTime, theme: theme, fontSize: comparing ? min(28, width * 0.075) : 38)
                        .padding(8).modifier(ClockAnswerOutline(visible: true, correct: session.correctFeedback))
                        .accessibilityIdentifier("question.digitalControl")
                    if comparing { comparisonLabel(correct: false) }
                }.frame(maxWidth: .infinity)
                if comparing {
                    VStack(spacing: 10) {
                        DigitalClock(time: question.target, theme: theme, fontSize: min(28, width * 0.075))
                            .padding(8).modifier(ClockAnswerOutline(visible: true, correct: true))
                            .accessibilityIdentifier("question.correctClock")
                        comparisonLabel(correct: true)
                    }.frame(maxWidth: .infinity)
                        .transition(reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity))
                }
            }
        } else {
            DigitalClockControl(hour: $session.inputHour, adjustingMinutes: $session.adjustingDigitalMinutes,
                                theme: theme, minute: session.inputMinute, fontSize: width < 350 ? 32 : 38,
                                onMinuteChange: { session.inputMinute = $0 },
                                minuteStep: session.minuteStep, valueIdentifier: "question.digitalControl")
        }
    }

    private func comparisonLabel(correct: Bool) -> some View {
        Label(LocalizedStringKey(correct ? "dino.correctTime" : "dino.yourAnswer"), systemImage: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(correct ? DinoStyle.deepGreen : Color(dinoHex: 0xB54343))
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
    }

    private var targetCard: some View {
        VStack(spacing: 10) {
            if let activity = question.activity {
                Label(LocalizedStringKey(activity.titleKey), systemImage: activity.symbol)
                    .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(DinoStyle.deepGreen)
            }
            clockStage(height: compactLayout ? 50 : 64) {
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

    private func clockStage<Content: View>(height: CGFloat,
                                          @ViewBuilder content: () -> Content) -> some View {
        content().frame(width: width, height: height)
    }

    private var analogOptions: some View {
        let columns = wideLayout && question.options.count == 4 ? 4 : 2
        let size = min(answerClockSize, width >= 600 ? 210 : 150, (width - CGFloat(columns - 1) * 12) / CGFloat(columns) - 18)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns), spacing: 14) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                answerButton(option: option, index: index) {
                    AnalogClock(time: option, theme: theme, size: size).allowsHitTesting(false).padding(8)
                }
            }
        }.id("question.answers")
    }

    private var digitalOptions: some View {
        let columns = wideLayout && question.options.count == 4 ? 4 : 2
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns), spacing: 14) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                answerButton(option: option, index: index) {
                    DigitalClock(time: option, theme: theme, fontSize: width < 350 ? 25 : 31)
                        .padding(.vertical, 14).frame(maxWidth: .infinity)
                }
            }
        }.id("question.answers")
    }

    private var confirmButton: some View {
        Group {
            if !session.hasFeedback {
                Button { session.submit(session.inputTime) } label: {
                    Image(systemName: "checkmark").font(.system(size: 25, weight: .heavy))
                }.buttonStyle(DinoButtonStyle()).frame(maxWidth: 260)
                    .accessibilityLabel(Text("dino.confirm")).accessibilityIdentifier("question.confirm")
            }
        }
    }

    private func adjustAnalog(by direction: Int) {
        if adjustingMinutes { session.adjustInputMinutes(by: direction * session.minuteStep) }
        else { session.inputHour = ClockTime.shiftedHour(session.inputHour, by: direction) }
    }

    private func answerButton<Content: View>(option: ClockTime, index: Int, @ViewBuilder content: () -> Content) -> some View {
        let response = ClockAnswer.time(option)
        let correct = session.showsCorrectResponse && response == question.expectedAnswer
        let wrong = session.hasFeedback && session.rejectedResponses.contains(response)
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
                .opacity(!highContrast && session.showsCorrectResponse && !correct && !wrong ? 0.55 : 1)
        }.buttonStyle(DinoAnswerButtonStyle()).disabled(!session.responseIsEnabled(response)).accessibilityIdentifier("question.option.\(index)")
    }
}

/// Connect a face and a digital time with two taps or a drag, starting on either side.
struct ClockMatchingBoard: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale
    let times: [ClockTime]
    let options: [ClockTime]
    @Binding var selections: [Int: ClockTime]
    let theme: ClockTheme
    let width: CGFloat
    var hasFeedback = false
    var isDemonstration = false
    @State private var pending: Endpoint?
    @GestureState private var drag: ConnectionDrag?
    @State private var demonstrationStep = -1
    @State private var demonstrationStopped = false

    private enum Endpoint: Equatable {
        case clock(Int), time(Int)
    }
    private struct ConnectionDrag {
        let source: Endpoint
        let location: CGPoint
    }
    private var prefix: String { isDemonstration ? "demo.match" : "question.match" }
    private var leftWidth: CGFloat { width * 0.42 }
    private var rightWidth: CGFloat { leftWidth }
    private var faceSize: CGFloat {
        min(width >= 600 ? min(180, width * 0.20) : 104, leftWidth - 18)
    }
    private var rowHeight: CGFloat { faceSize + 24 }
    private let spacing: CGFloat = 16

    private var hintText: String {
        let key = isDemonstration ? demonstrationHint : "dino.match.hint"
        return String(localized: String.LocalizationValue(key), bundle: LanguageManager.shared.bundle, locale: locale)
            .replacingOccurrences(of: ". ", with: ".\n")
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(verbatim: hintText)
                .font(.system(size: width >= 600 ? 16 : 14, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: min(520, width - 24))
                .frame(width: width)
                .accessibilityIdentifier("\(prefix).hint")
            ZStack {
                Canvas { context, _ in
                    for index in times.indices {
                        if let time = selections[index], let option = options.firstIndex(of: time) {
                            let color = hasFeedback ? (time == times[index] ? DinoStyle.deepGreen : Color(dinoHex: 0xB54343)) : linkColor(index)
                            context.stroke(line(from: index, to: option), with: .color(color),
                                           style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            if hasFeedback, time != times[index], let correct = options.firstIndex(of: times[index]) {
                                context.stroke(line(from: index, to: correct), with: .color(DinoStyle.deepGreen),
                                               style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [5, 4]))
                            }
                        }
                    }
                    if let drag {
                        let color: Color
                        switch drag.source {
                        case .clock(let index): color = linkColor(index)
                        case .time: color = DinoStyle.muted
                        }
                        let path = Path { path in
                            path.move(to: connectionPoint(for: drag.source))
                            path.addLine(to: drag.location)
                        }
                        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    }
                }.allowsHitTesting(false).accessibilityHidden(true)
                VStack(spacing: spacing) {
                    ForEach(times.indices, id: \.self) { index in
                        HStack(spacing: 0) {
                            clockButton(index)
                            Spacer(minLength: 0)
                            timeButton(index)
                        }.frame(height: rowHeight)
                    }
                }
                ForEach(times.indices, id: \.self) { index in
                    if let time = selections[index], let option = options.firstIndex(of: time) {
                        Color.clear.frame(width: 4, height: 4)
                            .position(x: (leftWidth + width - rightWidth) / 2,
                                      y: (rowY(index) + rowY(option)) / 2)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(times[index].digitalText) → \(time.digitalText)")
                            .accessibilityIdentifier("\(prefix).line.\(index)")
                    }
                }.allowsHitTesting(false)
            }.frame(width: width, height: CGFloat(times.count) * rowHeight + CGFloat(max(0, times.count - 1)) * spacing)
                .coordinateSpace(name: "clockMatchingBoard")
        }.environment(\.layoutDirection, .leftToRight)
            .task {
                guard isDemonstration else { return }
                do {
                    try await Task.sleep(for: .seconds(0.8))
                    for index in times.indices {
                        guard !demonstrationStopped, let option = options.firstIndex(of: times[index]) else { return }
                        demonstrationStep = index * 2
                        pending = .clock(index)
                        try await Task.sleep(for: .seconds(1.2))
                        guard !demonstrationStopped else { return }
                        demonstrationStep += 1
                        try await Task.sleep(for: .seconds(0.7))
                        guard !demonstrationStopped else { return }
                        select(.time(option))
                        try await Task.sleep(for: .seconds(1.0))
                    }
                    demonstrationStep = times.count * 2
                } catch { return }
            }
    }

    private var demonstrationHint: String {
        if demonstrationStep >= times.count * 2 { return "dino.match.demo.connected" }
        return demonstrationStep >= 0 && !demonstrationStep.isMultiple(of: 2) ? "dino.match.demo.time" : "dino.match.demo.clock"
    }

    private func clockButton(_ index: Int) -> some View {
        let selected = selections[index]
        let color = hasFeedback && selected != times[index] ? Color(dinoHex: 0xB54343) : linkColor(index)
        return Button { tapped(.clock(index)) } label: {
            AnalogClock(time: times[index], theme: theme, size: faceSize).allowsHitTesting(false)
                .frame(width: leftWidth, height: rowHeight)
                .background(.white, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected(.clock(index)) ? DinoStyle.ink : color,
                                                                                lineWidth: isSelected(.clock(index)) || selected != nil ? 3 : highContrast ? 2 : 0))
                .overlay(alignment: .trailing) { connectionDot(selected == nil ? DinoStyle.muted : color).offset(x: 4) }
                .overlay(alignment: .topTrailing) {
                    if isDemonstration, demonstrationStep == index * 2 { tapCue(1) }
                }
        }.buttonStyle(DinoAnswerButtonStyle()).disabled(hasFeedback)
            .highPriorityGesture(connectionDrag(from: .clock(index)))
            .accessibilityLabel(times[index].digitalText)
            .accessibilityValue(selected?.digitalText ?? L("dino.expanded.choose"))
            .accessibilityAddTraits(pending == .clock(index) ? .isSelected : [])
            .accessibilityIdentifier("\(prefix).clock.\(index)")
    }

    private func timeButton(_ index: Int) -> some View {
        let owner = times.indices.first { selections[$0] == options[index] }
        let color = owner.map { hasFeedback && times[$0] != options[index] ? Color(dinoHex: 0xB54343) : linkColor($0) } ?? DinoStyle.muted
        return Button { tapped(.time(index)) } label: {
            DigitalClock(time: options[index], theme: theme, fontSize: min(width >= 600 ? 40 : 26, width * 0.067))
                .frame(width: rightWidth, height: rowHeight)
                .background(.white, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(isSelected(.time(index)) ? DinoStyle.ink : color,
                                                                                lineWidth: isSelected(.time(index)) || owner != nil ? 3 : highContrast ? 2 : 0))
                .overlay(alignment: .leading) { connectionDot(color).offset(x: -4) }
                .overlay(alignment: .topTrailing) {
                    if isDemonstration, demonstrationStep >= 0, !demonstrationStep.isMultiple(of: 2),
                       demonstrationStep / 2 < times.count, options[index] == times[demonstrationStep / 2] { tapCue(2) }
                }
        }.buttonStyle(DinoAnswerButtonStyle()).disabled(hasFeedback)
            .highPriorityGesture(connectionDrag(from: .time(index)))
            .accessibilityLabel(options[index].digitalText)
            .accessibilityAddTraits(pending == .time(index) ? .isSelected : [])
            .accessibilityIdentifier("\(prefix).time.\(index)")
    }

    private func connectionDot(_ color: Color) -> some View {
        Circle().fill(color).frame(width: 9, height: 9).accessibilityHidden(true)
    }
    private func tapCue(_ number: Int) -> some View {
        HStack(spacing: 3) {
            Text(verbatim: "\(number)")
            Image(systemName: "hand.tap.fill")
        }.font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(DinoStyle.ink)
            .padding(6).background(DinoStyle.green, in: Capsule()).offset(x: 5, y: -8)
            .accessibilityHidden(true)
    }
    private func linkColor(_ index: Int) -> Color {
        Color(dinoHex: [0x377C95, 0x76539A, 0x27734C][index % 3])
    }
    private func rowY(_ index: Int) -> CGFloat { rowHeight / 2 + CGFloat(index) * (rowHeight + spacing) }
    private func isSelected(_ endpoint: Endpoint) -> Bool { pending == endpoint || drag?.source == endpoint }
    private func connectionPoint(for endpoint: Endpoint) -> CGPoint {
        switch endpoint {
        case .clock(let index): return CGPoint(x: leftWidth, y: rowY(index))
        case .time(let index): return CGPoint(x: width - rightWidth, y: rowY(index))
        }
    }
    private func endpoint(at point: CGPoint) -> Endpoint? {
        for index in times.indices {
            let centerY = rowY(index)
            if CGRect(x: 0, y: centerY - rowHeight / 2, width: leftWidth, height: rowHeight).contains(point) {
                return .clock(index)
            }
        }
        for index in options.indices {
            let height = rowHeight
            if CGRect(x: width - rightWidth, y: rowY(index) - height / 2, width: rightWidth, height: height).contains(point) {
                return .time(index)
            }
        }
        return nil
    }
    private func pair(from source: Endpoint?, to destination: Endpoint) -> (Int, Int)? {
        switch (source, destination) {
        case (.clock(let clock), .time(let time)), (.time(let time), .clock(let clock)): return (clock, time)
        default: return nil
        }
    }
    private func connectionDrag(from source: Endpoint) -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .named("clockMatchingBoard"))
            .updating($drag) { value, state, _ in
                guard !hasFeedback else { return }
                state = ConnectionDrag(source: source, location: value.location)
            }
            .onChanged { _ in
                guard !hasFeedback else { return }
                demonstrationStopped = true
                demonstrationStep = -1
                pending = nil
            }
            .onEnded { value in
                guard !hasFeedback, let destination = endpoint(at: value.location),
                      let (clock, option) = pair(from: source, to: destination) else { return }
                connect(clock: clock, to: option)
            }
    }
    private func line(from clock: Int, to time: Int) -> Path {
        Path { path in
            path.move(to: CGPoint(x: leftWidth, y: rowY(clock)))
            path.addLine(to: CGPoint(x: width - rightWidth, y: rowY(time)))
        }
    }
    private func tapped(_ endpoint: Endpoint) {
        demonstrationStopped = true
        demonstrationStep = -1
        select(endpoint)
    }
    private func select(_ endpoint: Endpoint) {
        let connectedClock: Int?
        switch endpoint {
        case .clock(let clock): connectedClock = selections[clock] == nil ? nil : clock
        case .time(let time): connectedClock = times.indices.first { selections[$0] == options[time] }
        }
        if let connectedClock {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                selections.removeValue(forKey: connectedClock)
                pending = nil
            }
            return
        }
        if pending == endpoint { pending = nil; return }
        guard let (clock, option) = pair(from: pending, to: endpoint) else { pending = endpoint; return }
        connect(clock: clock, to: option)
    }
    private func connect(clock: Int, to option: Int) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            for key in selections.keys.filter({ selections[$0] == options[option] }) { selections.removeValue(forKey: key) }
            selections[clock] = options[option]
            pending = nil
        }
    }
}

struct ClockAnswerOutline: ViewModifier {
    @Environment(\.dinoHighContrast) private var highContrast
    let visible: Bool
    let correct: Bool
    func body(content: Content) -> some View {
        content
            .background(.white.opacity(visible ? 0.8 : 0), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22)
                .stroke(correct ? (highContrast ? DinoStyle.deepGreen : DinoStyle.green) : Color(dinoHex: 0xC65A59), lineWidth: visible ? 4 : 0))
    }
}
