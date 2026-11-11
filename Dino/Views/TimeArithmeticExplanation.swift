import SwiftUI

/// Hours and minutes sit beside the ordinary clock, the difference level with the bar, then the totals.
struct DinoTimeArithmeticExplanation: View {
    @Environment(\.dinoDemonstrationLayout) private var demonstrationLayout
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var deviceHourFormat = DeviceHourFormat.shared
    let work: DinoClockArithmetic
    let theme: ClockTheme
    let language: String
    let width: CGFloat
    var clockFont: CGFloat = 32
    let prefix: String
    let startIdentifier: String
    let resultIdentifier: String
    var captionIdentifier: String? = nil
    var explains = false
    var showsResult = false
    var demonstrates = false
    @State private var stage = Stage.resting
    @State private var activeWork: DinoClockArithmetic?
    @State private var activeNotation: DigitalHourNotation?
    @State private var splitProgress: CGFloat = 0
    @State private var resultProgress: CGFloat = 0
    @State private var clockHeight: CGFloat = 0
    @State private var differenceHeight: CGFloat = 0
    @State private var revealedStep = 0

    private enum Stage: Int, Comparable {
        case resting, split, corrected
        static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    /// row −1 is the question clock (hours) and the difference bar (minutes).
    /// row 0 is the side totals. row 1 is the final clock.
    private struct FieldAnchor: Hashable {
        var row: Int
        var hours: Bool
    }

    private struct FieldAnchorsKey: PreferenceKey {
        static var defaultValue: [FieldAnchor: Anchor<CGRect>] = [:]
        static func reduce(value: inout [FieldAnchor: Anchor<CGRect>], nextValue: () -> [FieldAnchor: Anchor<CGRect>]) {
            value.merge(nextValue(), uniquingKeysWith: { $1 })
        }
    }

    private var subtracting: Bool { !work.adding }
    private var operation: DinoClockOperation { subtracting ? .subtract : .add }
    private var operationInk: Color { DinoTimeDirection.color(later: !subtracting, highContrast: highContrast) }
    private var blue: Color { DinoStyle.ink }
    private var layoutWidth: CGFloat { min(demonstrationLayout.spacious ? 760 : 600, width) }
    private var layoutScale: CGFloat { demonstrationLayout.spacious ? 1.25 : min(1, layoutWidth / 320) }
    private var digitFont: CGFloat { (layoutWidth < 360 ? 18 : 20) * layoutScale }
    private var blockHeight: CGFloat { digitFont + 16 * layoutScale }
    private func boxWidth(slots: Int) -> CGFloat { digitFont * 0.92 * CGFloat(max(slots, 2)) + 20 * layoutScale }
    private var notation: DigitalHourNotation { theme.resolvedHourNotation(device: deviceHourFormat.notation) }
    private var display: DinoClockArithmeticDisplay { .init(work: work, notation: notation) }
    private var startReading: DigitalClockReading { work.start.digitalReading(notation: notation, languageCode: language) }
    private var resultReading: DigitalClockReading { work.result.digitalReading(notation: notation, languageCode: language) }
    private var columnSlots: Int {
        max(2, [display.startHour, display.hourSubtotal, display.minuteSubtotal,
                work.start.minute, work.differenceHours, work.differenceMinutes]
            .map { String(abs($0)).count + ($0 < 0 ? 1 : 0) }.max() ?? 2)
    }
    private var columnWidth: CGFloat { boxWidth(slots: columnSlots) }
    private var edgeInset: CGFloat { signGap + signWidth + 8 * layoutScale }
    private var signWidth: CGFloat { 11 * layoutScale }
    private var signGap: CGFloat { 6 * layoutScale }
    private func columnX(hours: Bool) -> CGFloat {
        hours ? edgeInset + columnWidth / 2 : layoutWidth - edgeInset - columnWidth / 2
    }
    /// Mirror the number columns around the clock, leaving outer room for the right-hand sign.
    private var centerWidth: CGFloat {
        layoutWidth - 2 * (edgeInset + columnWidth + 12 * layoutScale)
    }
    private var shownClockFont: CGFloat {
        min(clockFont, centerWidth / (notation == .twelve ? 5.1 : 4.2))
    }
    private var columnStep: CGFloat {
        max((clockHeight + differenceHeight) / 2 + 10, blockHeight + 28 * layoutScale)
    }
    private var totalsTopPadding: CGFloat {
        max(0, columnStep - (differenceHeight + blockHeight) / 2 - 10)
    }
    private var resultVisible: Bool { explains && showsResult && stage >= .corrected }
    private var playID: String { "\(notation.rawValue)-\(explains)-\(showsResult)-\(work.adding)-\(work.start.digitalText)-\(work.differenceHours)-\(work.differenceMinutes)" }

    var body: some View {
        VStack(spacing: 10) {
            DigitalClock(time: work.start, theme: theme, fontSize: shownClockFont, notation: notation)
                .anchorPreference(key: FieldAnchorsKey.self, value: .bounds) { [FieldAnchor(row: -1, hours: true): $0] }
                .accessibilityIdentifier(startIdentifier)
                .readGeometry(for: CGFloat.self) { $0.size.height } action: { clockHeight = $0 }
            differenceBar
                .anchorPreference(key: FieldAnchorsKey.self, value: .bounds) { [FieldAnchor(row: -1, hours: false): $0] }
                .readGeometry(for: CGFloat.self) { $0.size.height } action: { differenceHeight = $0 }
            if explains && stage >= .split {
                totalsRow
                    .padding(.top, totalsTopPadding)
                    .transition(.opacity)
                if resultVisible {
                    DigitalClock(time: work.result, theme: theme, fontSize: shownClockFont, notation: notation)
                        .anchorPreference(key: FieldAnchorsKey.self, value: .bounds) { [FieldAnchor(row: 1, hours: true): $0] }
                        .accessibilityLabel(Text(verbatim: resultReading.text))
                        .accessibilityIdentifier(resultIdentifier)
                        .padding(.top, 6 * layoutScale)
                        .transition(.opacity)
                    if display.changesPeriod, let start = startReading.period, let end = resultReading.period {
                        Text(verbatim: "\(start) → \(end)")
                            .font(.system(size: 12 * layoutScale, weight: .bold, design: .rounded))
                            .foregroundStyle(blue)
                            .accessibilityIdentifier("\(prefix).timeArithmetic.periodChange")
                            .transition(.opacity)
                    }
                }
            }
        }
        .frame(width: centerWidth)
        .frame(width: layoutWidth)
        .overlayPreferenceValue(FieldAnchorsKey.self) { anchors in
            GeometryReader { geometry in
                if explains && stage >= .split,
                   let clock = anchors[FieldAnchor(row: -1, hours: true)].map({ geometry[$0] }),
                   let bar = anchors[FieldAnchor(row: -1, hours: false)].map({ geometry[$0] }) {
                    placedColumns(clock: clock, bar: bar)
                        .transition(.opacity)
                    splitGuides(clock: clock, bar: bar)
                }
            }
            .allowsHitTesting(false)
        }
        .overlayPreferenceValue(FieldAnchorsKey.self) { anchors in
            GeometryReader { geometry in
                if resultVisible {
                    guides(anchors: anchors, in: geometry)
                }
            }
            .allowsHitTesting(false)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.55), value: stage)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.45), value: revealedStep)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(prefix).timeArithmetic")
        .id("\(prefix).timeArithmetic")
        .task(id: playID) { await play() }
    }

    private var differenceBar: some View {
        ViewThatFits(in: .horizontal) {
            differenceLabel(fontSize: 19 * layoutScale)
            differenceLabel(fontSize: 16 * layoutScale)
            differenceLabel(fontSize: 13 * layoutScale)
            differenceLabel(fontSize: 10 * layoutScale)
            differenceLabel(fontSize: 8 * layoutScale)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(captionIdentifier ?? "\(prefix).timeChange.difference")
    }

    private func differenceLabel(fontSize: CGFloat) -> some View {
        HStack(spacing: fontSize * 0.4) {
            Image(systemName: subtracting ? "minus.circle.fill" : "plus.circle.fill")
            Text(verbatim: DinoTimeWords.duration(work.differenceHours * 60 + work.differenceMinutes, language: language))
        }
        .font(.system(size: fontSize, weight: .bold, design: .rounded))
        .lineLimit(1)
        .foregroundStyle(operationInk)
        .padding(.horizontal, fontSize * 0.6).padding(.vertical, fontSize * 0.36)
        .background(DinoTimeDirection.background(later: !subtracting, highContrast: highContrast), in: Capsule())
        .overlay(Capsule().strokeBorder(operationInk.opacity(highContrast ? 1 : 0.35), lineWidth: highContrast ? 2 : 1))
        .fixedSize()
    }

    private func helperVisible(_ step: Int) -> Bool {
        !demonstrates || revealedStep >= step
    }

    /// Starting values align with the clock; addends align with the bar, with room below for the rules.
    private func placedColumns(clock: CGRect, bar: CGRect) -> some View {
        let hourX = columnX(hours: true)
        let minuteX = columnX(hours: false)
        return ZStack {
            columnPieces(addend: work.differenceHours, hours: true,
                         x: hourX, clockY: clock.midY, barY: bar.midY, step: columnStep)
            columnPieces(addend: work.differenceMinutes, hours: false,
                         x: minuteX, clockY: clock.midY, barY: bar.midY, step: columnStep)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func columnPieces(addend: Int, hours: Bool,
                              x: CGFloat, clockY: CGFloat, barY: CGFloat, step: CGFloat) -> some View {
        let opening = hours ? display.startHour : work.start.minute
        let slots = columnSlots
        let ruleExtension = signWidth + signGap
        let ruleY = barY + step / 2
        return ZStack {
            block(opening, slots: slots)
                .position(x: x, y: clockY)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: hours ? display.hourEquation : display.minuteEquation))
                .accessibilityIdentifier("\(prefix).timeArithmetic.\(hours ? "hours" : "minutes")")
                .opacity(helperVisible(hours ? 1 : 2) ? 1 : 0)
                .accessibilityHidden(!helperVisible(hours ? 1 : 2))
            block(addend, slots: slots)
                .position(x: x, y: barY)
                .opacity(helperVisible(hours ? 3 : 4) ? 1 : 0)
            Capsule().fill(blue)
                .frame(width: boxWidth(slots: slots) + ruleExtension, height: 2)
                .position(x: x + ruleExtension / 2, y: ruleY)
                .opacity(helperVisible(hours ? 3 : 4) ? 1 : 0)
            signMark(operation)
                .position(x: x + columnWidth / 2 + signGap + signWidth / 2,
                          y: ruleY - signWidth / 2 - 5 * layoutScale)
                .opacity(helperVisible(hours ? 3 : 4) ? 1 : 0)
        }
    }

    /// Actual layout content ends at the subtotals until the answer is revealed.
    private var totalsRow: some View {
        HStack(spacing: 0) {
            totalBlock(hours: true)
            Spacer(minLength: 0)
            totalBlock(hours: false)
        }
        .padding(.horizontal, edgeInset)
        .frame(width: layoutWidth)
    }

    private func totalBlock(hours: Bool) -> some View {
        let value = hours ? display.hourSubtotal : display.minuteSubtotal
        return block(value, slots: columnSlots, outlined: false)
            .anchorPreference(key: FieldAnchorsKey.self, value: .bounds) { [FieldAnchor(row: 0, hours: hours): $0] }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: DinoClockArithmetic.format(value)))
            .accessibilityIdentifier("\(prefix).timeArithmetic.total.\(hours ? "hours" : "minutes")")
            .opacity(helperVisible(hours ? 5 : 6) ? 1 : 0)
            .accessibilityHidden(!helperVisible(hours ? 5 : 6))
    }

    private func block(_ value: Int, slots: Int, outlined: Bool = true) -> some View {
        ZStack(alignment: .trailing) {
            // Measure an invisible digit grid in the selected font; every units digit shares its right edge.
            Text(verbatim: String(repeating: "0", count: max(2, slots)))
                .hidden()
                .accessibilityHidden(true)
            HStack(spacing: 0) {
                if value < 0 {
                    Text(verbatim: "−").foregroundStyle(DinoTimeDirection.color(later: false, highContrast: highContrast))
                }
                Text(verbatim: String(abs(value)))
            }
        }
        .font(.system(size: digitFont, weight: .heavy, design: digitDesign))
        .monospacedDigit()
        .foregroundStyle(Color(dinoHex: theme.digitalInkHex))
        .lineLimit(1)
        .fixedSize()
        .frame(width: boxWidth(slots: slots), height: blockHeight)
        .background {
            DigitalClockOutline(shape: theme.digitalShape).fill(Color(dinoHex: theme.displayHex))
        }
        .overlay {
            if outlined {
                DigitalClockOutline(shape: theme.digitalShape)
                    .strokeBorder(DinoStyle.ink.opacity(highContrast ? 1 : 0.12), lineWidth: 2)
            }
        }
    }

    private func signMark(_ sign: DinoClockOperation) -> some View {
        Image(systemName: sign == .subtract ? "minus" : "plus")
            .font(.system(size: 12 * layoutScale, weight: .black))
            .foregroundStyle(DinoTimeDirection.color(later: sign == .add, highContrast: highContrast))
            .frame(width: signWidth, height: signWidth)
            .accessibilityHidden(true)
    }

    private func splitGuides(clock: CGRect, bar: CGRect) -> some View {
        let leftEdge = columnX(hours: true) + columnWidth / 2 + 4 * layoutScale
        let rightEdge = columnX(hours: false) - columnWidth / 2 - 4 * layoutScale
        // DigitalClock reserves 4 points around its painted display; the capsule has no such inset.
        let sourceGap: CGFloat = 6
        return ZStack {
            outwardArrow(from: CGPoint(x: clock.minX + 4 - sourceGap, y: clock.midY),
                         to: CGPoint(x: leftEdge, y: clock.midY), identifier: "start.hours")
                .opacity(helperVisible(1) ? 1 : 0)
            outwardArrow(from: CGPoint(x: clock.maxX - 4 + sourceGap, y: clock.midY),
                         to: CGPoint(x: rightEdge, y: clock.midY), identifier: "start.minutes")
                .opacity(helperVisible(2) ? 1 : 0)
            outwardArrow(from: CGPoint(x: bar.minX - sourceGap, y: bar.midY),
                         to: CGPoint(x: leftEdge, y: bar.midY), identifier: "difference.hours")
                .opacity(helperVisible(3) ? 1 : 0)
            outwardArrow(from: CGPoint(x: bar.maxX + sourceGap, y: bar.midY),
                         to: CGPoint(x: rightEdge, y: bar.midY), identifier: "difference.minutes")
                .opacity(helperVisible(4) ? 1 : 0)
        }
        .accessibilityHidden(true)
    }

    private func outwardArrow(from: CGPoint, to: CGPoint, identifier: String) -> some View {
        ArithmeticArrowShaft(from: from, to: to, elbow: false)
            .trim(from: 0, to: splitProgress)
            .stroke(blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .overlay {
                ArithmeticArrowTip(tip: to, direction: to.x < from.x ? .left : .right)
                    .fill(blue)
                    .opacity(splitProgress)
            }
            .accessibilityIdentifier("\(prefix).timeArithmetic.arrow.\(identifier)")
    }

    @ViewBuilder private func guides(anchors: [FieldAnchor: Anchor<CGRect>], in geometry: GeometryProxy) -> some View {
        if let hours = anchors[FieldAnchor(row: 0, hours: true)].map({ geometry[$0] }),
           let minutes = anchors[FieldAnchor(row: 0, hours: false)].map({ geometry[$0] }),
           let clock = anchors[FieldAnchor(row: 1, hours: true)].map({ geometry[$0] }) {
            // Keep enough horizontal shaft for the correction badge on narrow displays.
            let hourBend = max(hours.maxX + 44 * layoutScale, clock.minX + clock.width * 0.18)
            let minuteBend = min(minutes.minX - 44 * layoutScale, clock.maxX - clock.width * 0.18)
            GuideArrow(from: CGPoint(x: hours.maxX, y: hours.midY),
                       to: CGPoint(x: hourBend, y: clock.minY),
                       label: display.hourCarry == 0 ? nil : signed(display.hourCarry),
                       color: blue,
                       labelColor: arrowColor(display.hourCarry),
                       progress: resultProgress, scale: layoutScale,
                       sideLabel: display.hourWrap == 0 ? nil : signed(display.hourWrap),
                       sideLabelColor: arrowColor(display.hourWrap))
                .accessibilityIdentifier("\(prefix).timeArithmetic.arrow.result.hours")
            GuideArrow(from: CGPoint(x: minutes.minX, y: minutes.midY),
                       to: CGPoint(x: minuteBend, y: clock.minY),
                       label: display.minuteCorrection == 0 ? nil : signed(display.minuteCorrection),
                       color: blue,
                       labelColor: arrowColor(display.minuteCorrection),
                       progress: resultProgress, scale: layoutScale)
                .accessibilityIdentifier("\(prefix).timeArithmetic.arrow.result.minutes")
        }
    }

    private func arrowColor(_ delta: Int) -> Color {
        return DinoTimeDirection.color(later: delta >= 0, highContrast: highContrast)
    }

    private func signed(_ value: Int) -> String {
        value < 0 ? "−\(abs(value))" : "+\(value)"
    }

    private var digitDesign: Font.Design {
        switch theme.numerals {
        case .rounded: return .rounded
        case .classic: return .serif
        default: return .monospaced
        }
    }

    @MainActor private func play() async {
        if activeWork != work || activeNotation != notation || !explains {
            var reset = Transaction()
            reset.disablesAnimations = true
            withTransaction(reset) {
                activeWork = work
                activeNotation = notation
                stage = .resting
                splitProgress = 0
                resultProgress = 0
                revealedStep = 0
            }
        }
        guard explains else { return }
        if demonstrates {
            do {
                if !reduceMotion { try await Task.sleep(for: .seconds(1)) }
                stage = .split
                splitProgress = 1
                for step in 1...6 {
                    try Task.checkCancellation()
                    revealedStep = step
                    if !reduceMotion { try await Task.sleep(for: .milliseconds(650)) }
                }
                guard showsResult else { return }
                stage = .corrected
                resultProgress = 1
            } catch { /* A new example or dismissal cancels the complete sequence. */ }
            return
        }
        if stage == .resting {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.55)) {
                // A closed two-choice question opens its complete layout once.
                // Only the arrow drawing is staggered; the answer row never causes a second expansion.
                stage = showsResult ? .corrected : .split
            }
        }
        if splitProgress == 0 {
            if !reduceMotion {
                do { try await Task.sleep(nanoseconds: 80_000_000) }
                catch { return }
            }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.55)) { splitProgress = 1 }
            if !reduceMotion {
                do { try await Task.sleep(nanoseconds: 600_000_000) }
                catch { return }
            }
        }
        guard !Task.isCancelled, showsResult else { return }
        if stage < .corrected {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.55)) { stage = .corrected }
            if !reduceMotion {
                do { try await Task.sleep(nanoseconds: 80_000_000) }
                catch { return }
            }
        }
        if resultProgress == 0 {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.55)) { resultProgress = 1 }
        }
    }
}

/// An elbow from a side total into the final clock: across, then down.
private struct GuideArrow: View {
    let from: CGPoint
    let to: CGPoint
    let label: String?
    let color: Color
    let labelColor: Color
    let progress: CGFloat
    let scale: CGFloat
    var sideLabel: String? = nil
    var sideLabelColor: Color = .clear

    var body: some View {
        ZStack(alignment: .topLeading) {
            ArithmeticArrowShaft(from: from, to: to, elbow: true)
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 2.25, lineCap: .round, lineJoin: .round))
            ArithmeticArrowTip(tip: to, direction: .down)
                .fill(color)
                .opacity(progress)
            if let label {
                badge(label, color: labelColor)
                    // Anchor the badge's near edge just before the bend, above the horizontal shaft.
                    .frame(width: 0, height: 0, alignment: from.x < to.x ? .trailing : .leading)
                    .position(x: to.x + (from.x < to.x ? -4 : 4) * scale, y: from.y - 14 * scale)
                    .opacity(progress)
            }
            if let sideLabel {
                badge(sideLabel, color: sideLabelColor)
                    .frame(width: 0, height: 0, alignment: .leading)
                    .position(x: to.x + 6 * scale, y: (from.y + to.y) / 2)
                    .opacity(progress)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: [label, sideLabel].compactMap { $0 }.joined(separator: ", ")))
        .accessibilityHidden(label == nil && sideLabel == nil)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(verbatim: text)
            .font(.system(size: 12 * scale, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 5 * scale)
            .padding(.vertical, 2 * scale)
            .background(.white.opacity(0.92), in: Capsule())
            .overlay(Capsule().stroke(color.opacity(0.45), lineWidth: 1))
    }
}

/// Shapes interpolate their coordinates when the surrounding SwiftUI layout moves.
private struct ArithmeticArrowShaft: Shape {
    var from: CGPoint
    var to: CGPoint
    var elbow: Bool

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get { .init(.init(from.x, from.y), .init(to.x, to.y)) }
        set {
            from = CGPoint(x: newValue.first.first, y: newValue.first.second)
            to = CGPoint(x: newValue.second.first, y: newValue.second.second)
        }
    }

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: from)
            if elbow { path.addLine(to: CGPoint(x: to.x, y: from.y)) }
            let dx = elbow ? 0 : (to.x < from.x ? -1.0 : 1.0)
            path.addLine(to: CGPoint(x: to.x - dx * 5, y: to.y - (elbow ? 6 : 0)))
        }
    }
}

private struct ArithmeticArrowTip: Shape {
    enum Direction { case left, right, down }
    var tip: CGPoint
    var direction: Direction

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { .init(tip.x, tip.y) }
        set { tip = CGPoint(x: newValue.first, y: newValue.second) }
    }

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: tip)
            switch direction {
            case .left:
                path.addLine(to: CGPoint(x: tip.x + 6, y: tip.y - 4))
                path.addLine(to: CGPoint(x: tip.x + 6, y: tip.y + 4))
            case .right:
                path.addLine(to: CGPoint(x: tip.x - 6, y: tip.y - 4))
                path.addLine(to: CGPoint(x: tip.x - 6, y: tip.y + 4))
            case .down:
                path.addLine(to: CGPoint(x: tip.x - 5, y: tip.y - 8))
                path.addLine(to: CGPoint(x: tip.x + 5, y: tip.y - 8))
            }
            path.closeSubpath()
        }
    }
}
