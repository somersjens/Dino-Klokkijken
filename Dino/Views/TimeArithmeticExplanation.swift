import SwiftUI

/// Hours and minutes sit beside the ordinary clock, the difference level with the bar, then the totals.
struct DinoTimeArithmeticExplanation: View {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
    var showsMidnightNote = false
    @State private var stage = Stage.resting
    @State private var activeWork: DinoClockArithmetic?
    @State private var splitProgress: CGFloat = 0
    @State private var resultProgress: CGFloat = 0

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
    private var operationInk: Color { subtracting ? DinoTimeDirection.earlier : DinoStyle.deepGreen }
    private var operationFill: Color { subtracting ? DinoTimeDirection.earlier : DinoStyle.green }
    private var secondaryInk: Color { highContrast ? DinoStyle.ink : DinoStyle.muted }
    private var blue: Color { Color(dinoHex: 0x2E6B9A) }
    private var layoutWidth: CGFloat { min(600, width) }
    private var layoutScale: CGFloat { min(1, layoutWidth / 320) }
    private var digitFont: CGFloat { (layoutWidth < 360 ? 18 : 20) * layoutScale }
    private var blockHeight: CGFloat { digitFont + 16 * layoutScale }
    private func boxWidth(slots: Int) -> CGFloat { digitFont * 0.92 * CGFloat(max(slots, 2)) + 20 * layoutScale }
    private var columnSlots: Int {
        max(digitSlots(work.hours, addend: work.differenceHours),
            digitSlots(work.minutes, addend: work.differenceMinutes))
    }
    private var columnWidth: CGFloat { boxWidth(slots: columnSlots) }
    private var edgeInset: CGFloat { 4 * layoutScale }
    private var signWidth: CGFloat { 11 * layoutScale }
    private var signGap: CGFloat { 6 * layoutScale }
    /// Both outer columns reserve their complete width, sign, and a clear gap beside the instruction.
    private var centerWidth: CGFloat {
        layoutWidth - 2 * (edgeInset + columnWidth + signGap + signWidth + 12 * layoutScale)
    }
    private var shownClockFont: CGFloat {
        min(clockFont, centerWidth / 4.2)
    }
    /// Space under the bar so the lower blocks and their arrows fit before the answer clock.
    private var tail: CGFloat { shownClockFont * 0.85 + blockHeight + 12 * layoutScale }
    private var resultVisible: Bool { explains && showsResult && stage >= .corrected }
    private var playID: String { "\(explains)-\(showsResult)-\(work.adding)-\(work.start.digitalText)-\(work.differenceHours)-\(work.differenceMinutes)" }

    private var hourFix: Int {
        work.hours.sums.dropFirst().reduce(0) { partial, sum in
            let magnitude = sum.terms.last ?? 0
            return partial + (sum.operation == .add ? magnitude : -magnitude)
        }
    }
    private var minuteFix: Int {
        guard let sum = work.minutes.sums.dropFirst().last else { return 0 }
        let magnitude = sum.terms.last ?? 0
        return sum.operation == .add ? magnitude : -magnitude
    }

    var body: some View {
        VStack(spacing: 10) {
            DigitalClock(time: work.start, theme: theme, fontSize: shownClockFont, notation: .twentyFour)
                .anchorPreference(key: FieldAnchorsKey.self, value: .bounds) { [FieldAnchor(row: -1, hours: true): $0] }
                .accessibilityIdentifier(startIdentifier)
            differenceBar
                .anchorPreference(key: FieldAnchorsKey.self, value: .bounds) { [FieldAnchor(row: -1, hours: false): $0] }
            if explains && stage >= .split {
                Color.clear.frame(height: tail)
                // Keep the answer row's size while retrying; revealing it only fades in the content.
                ZStack {
                    DigitalClock(time: work.start, theme: theme, fontSize: shownClockFont, notation: .twentyFour)
                        .hidden()
                        .accessibilityHidden(true)
                    if resultVisible {
                        DigitalClock(time: work.result, theme: theme, fontSize: shownClockFont, notation: .twentyFour)
                            .anchorPreference(key: FieldAnchorsKey.self, value: .bounds) { [FieldAnchor(row: 1, hours: true): $0] }
                            .accessibilityLabel(Text(verbatim: work.result.digitalText))
                            .accessibilityIdentifier(resultIdentifier)
                            .transition(.opacity)
                    }
                }
                if showsMidnightNote && work.crossesMidnight {
                    Text("dino.expanded.midnightHint")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .opacity(resultVisible ? 1 : 0)
                        .accessibilityHidden(!resultVisible)
                        .accessibilityIdentifier("\(prefix).timeArithmetic.midnight")
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
                    placedColumns(clock: clock, bar: bar, width: geometry.size.width)
                        .transition(.opacity)
                    splitGuides(clock: clock, bar: bar, width: geometry.size.width)
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
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(prefix).timeArithmetic")
        .id("\(prefix).timeArithmetic")
        .task(id: playID) { await play() }
    }

    private var differenceBar: some View {
        HStack(spacing: 8) {
            Image(systemName: subtracting ? "minus.circle.fill" : "plus.circle.fill")
                .font(.system(size: 19 * layoutScale, weight: .bold))
            Text(verbatim: DinoTimeWords.duration(work.differenceHours * 60 + work.differenceMinutes, language: language))
                .font(.system(size: 19 * layoutScale, weight: .bold, design: .rounded))
                .foregroundStyle(DinoStyle.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(operationInk)
        .padding(.horizontal, 12 * layoutScale).padding(.vertical, 7 * layoutScale)
        .background(operationFill.opacity(0.28), in: Capsule())
        .overlay(Capsule().strokeBorder(operationInk.opacity(highContrast ? 1 : 0.35), lineWidth: highContrast ? 2 : 1))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(captionIdentifier ?? "\(prefix).timeChange.difference")
    }

    /// Starting values align with the clock; addends align with the bar, with room below for the rules.
    private func placedColumns(clock: CGRect, bar: CGRect, width: CGFloat) -> some View {
        let step = max(bar.midY - clock.midY, blockHeight + 28 * layoutScale)
        let hourX = edgeInset + columnWidth / 2
        let minuteX = width - edgeInset - columnWidth / 2
        return ZStack {
            columnPieces(work.hours, addend: work.differenceHours, hours: true,
                         x: hourX, clockY: clock.midY, barY: bar.midY, step: step)
            columnPieces(work.minutes, addend: work.differenceMinutes, hours: false,
                         x: minuteX, clockY: clock.midY, barY: bar.midY, step: step)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func columnPieces(_ column: DinoClockColumnWork, addend: Int, hours: Bool,
                              x: CGFloat, clockY: CGFloat, barY: CGFloat, step: CGFloat) -> some View {
        let opening = column.sums.first?.terms.first ?? column.passthrough ?? 0
        let raw = column.sums.first?.result ?? opening
        let slots = columnSlots
        let changed = (hours ? hourFix : minuteFix) != 0
        let inward: CGFloat = hours ? 1 : -1
        let ruleExtension = signWidth + signGap + 8 * layoutScale
        let ruleY = barY + step / 2
        return ZStack {
            block(opening, slots: slots, emphasis: .plain)
                .position(x: x, y: clockY)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: column.sums.first?.equation ?? "\(clockDigits(opening, padded: true)) \(operation.symbol) \(clockDigits(addend, padded: true))"))
                .accessibilityIdentifier("\(prefix).timeArithmetic.\(hours ? "hours" : "minutes")")
            block(addend, slots: slots, emphasis: .plain)
                .position(x: x, y: barY)
            Capsule().fill(blue)
                .frame(width: boxWidth(slots: slots) + ruleExtension, height: 2)
                .position(x: x + inward * ruleExtension / 2, y: ruleY)
            signMark(operation)
                .position(x: x + inward * (columnWidth / 2 + signGap + signWidth / 2),
                          y: ruleY - signWidth / 2 - 5 * layoutScale)
            block(raw, slots: slots, emphasis: changed ? .bridge : .final)
                .anchorPreference(key: FieldAnchorsKey.self, value: .bounds) { [FieldAnchor(row: 0, hours: hours): $0] }
                .position(x: x, y: barY + step)
        }
    }

    private func block(_ value: Int, slots: Int, emphasis: DigitalClockReadout.Emphasis) -> some View {
        HStack(spacing: 0) {
            if value < 0 { Text(verbatim: "−") }
            Text(verbatim: clockDigits(abs(value), padded: abs(value) < 100))
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
            DigitalClockOutline(shape: theme.digitalShape)
                .strokeBorder(border(emphasis), lineWidth: emphasis == .plain && !highContrast ? 2 : 2.5)
        }
    }

    private func signMark(_ sign: DinoClockOperation) -> some View {
        Image(systemName: sign == .subtract ? "minus" : "plus")
            .font(.system(size: 12 * layoutScale, weight: .black))
            .foregroundStyle(blue)
            .frame(width: signWidth, height: signWidth)
            .accessibilityHidden(true)
    }

    private func border(_ emphasis: DigitalClockReadout.Emphasis) -> Color {
        switch emphasis {
        case .plain: return DinoStyle.ink.opacity(highContrast ? 1 : 0.12)
        case .bridge: return highContrast ? DinoStyle.ink : Color(dinoHex: 0x154A86)
        case .final: return highContrast ? DinoStyle.ink : DinoStyle.deepGreen
        }
    }

    private func digitSlots(_ column: DinoClockColumnWork, addend: Int) -> Int {
        let opening = column.sums.first?.terms.first ?? column.passthrough ?? 0
        let raw = column.sums.first?.result ?? opening
        return max(2, [opening, addend, raw].map { value in
            (abs(value) < 100 ? 2 : String(abs(value)).count) + (value < 0 ? 1 : 0)
        }.max() ?? 2)
    }

    private func splitGuides(clock: CGRect, bar: CGRect, width: CGFloat) -> some View {
        let leftEdge = edgeInset + columnWidth + 4 * layoutScale
        let rightEdge = width - leftEdge
        return ZStack {
            outwardArrow(from: CGPoint(x: clock.minX - 2, y: clock.midY),
                         to: CGPoint(x: leftEdge, y: clock.midY), identifier: "start.hours")
            outwardArrow(from: CGPoint(x: clock.maxX + 2, y: clock.midY),
                         to: CGPoint(x: rightEdge, y: clock.midY), identifier: "start.minutes")
            outwardArrow(from: CGPoint(x: bar.minX - 2, y: bar.midY),
                         to: CGPoint(x: leftEdge, y: bar.midY), identifier: "difference.hours")
            outwardArrow(from: CGPoint(x: bar.maxX + 2, y: bar.midY),
                         to: CGPoint(x: rightEdge, y: bar.midY), identifier: "difference.minutes")
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
            let changed = hourFix != 0 || minuteFix != 0
            GuideArrow(from: CGPoint(x: hours.maxX, y: hours.midY),
                       to: CGPoint(x: clock.minX + clock.width * 0.3, y: clock.minY),
                       label: hourFix == 0 ? nil : signed(hourFix),
                       color: arrowColor(hourFix, changed: changed && hourFix != 0),
                       progress: resultProgress)
                .accessibilityIdentifier("\(prefix).timeArithmetic.arrow.result.hours")
            GuideArrow(from: CGPoint(x: minutes.minX, y: minutes.midY),
                       to: CGPoint(x: clock.maxX - clock.width * 0.3, y: clock.minY),
                       label: minuteFix == 0 ? nil : signed(minuteFix),
                       color: arrowColor(minuteFix, changed: changed && minuteFix != 0),
                       progress: resultProgress)
                .accessibilityIdentifier("\(prefix).timeArithmetic.arrow.result.minutes")
        }
    }

    private func arrowColor(_ delta: Int, changed: Bool) -> Color {
        guard changed else { return blue }
        return delta < 0 ? DinoTimeDirection.earlier : DinoStyle.deepGreen
    }

    private func signed(_ value: Int) -> String {
        value < 0 ? "−\(abs(value))" : "+\(value)"
    }

    private func clockDigits(_ value: Int, padded: Bool) -> String {
        if padded && abs(value) < 100 { return String(format: "%02d", abs(value)) }
        return String(abs(value))
    }

    private var digitDesign: Font.Design {
        switch theme.numerals {
        case .rounded: return .rounded
        case .classic: return .serif
        default: return .monospaced
        }
    }

    @MainActor private func play() async {
        if activeWork != work || !explains {
            var reset = Transaction()
            reset.disablesAnimations = true
            withTransaction(reset) {
                activeWork = work
                stage = .resting
                splitProgress = 0
                resultProgress = 0
            }
        }
        guard explains else { return }
        if stage == .resting {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.55)) {
                stage = .split
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
        guard !Task.isCancelled, showsResult, stage < .corrected else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.55)) { stage = .corrected }
        if !reduceMotion {
            do { try await Task.sleep(nanoseconds: 80_000_000) }
            catch { return }
        }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.55)) { resultProgress = 1 }
    }
}

/// An elbow from a side total into the final clock: across, then down.
private struct GuideArrow: View {
    let from: CGPoint
    let to: CGPoint
    let label: String?
    let color: Color
    let progress: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            ArithmeticArrowShaft(from: from, to: to, elbow: true)
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 2.25, lineCap: .round, lineJoin: .round))
            ArithmeticArrowTip(tip: to, direction: .down)
                .fill(color)
                .opacity(progress)
            if let label {
                Text(verbatim: label)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.92), in: Capsule())
                    .overlay(Capsule().stroke(color.opacity(0.45), lineWidth: 1))
                    // Attach the correction to the vertical segment, on its outer side.
                    .position(x: to.x + (from.x < to.x ? -24 : 24), y: (from.y + to.y) / 2)
                    .opacity(progress)
            }
        }
        .accessibilityHidden(true)
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
