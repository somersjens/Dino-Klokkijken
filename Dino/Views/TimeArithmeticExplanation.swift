import SwiftUI

/// The colored difference bar stays put. Under it, hours and minutes stack in matching columns.
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
    var showsMidnightNote = false
    @State private var stage = Stage.words

    private enum Stage: Int, Comparable {
        case words, sums, joined
        static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    private struct SumRow {
        var sign: DinoClockOperation?
        var digits: Int
        var emphasis: DigitalClockReadout.Emphasis
        var rule = false
    }

    private var subtracting: Bool { !work.adding }
    private var operationInk: Color { subtracting ? DinoTimeDirection.earlier : DinoStyle.deepGreen }
    private var operationFill: Color { subtracting ? DinoTimeDirection.earlier : DinoStyle.green }
    private var secondaryInk: Color { highContrast ? DinoStyle.ink : DinoStyle.muted }
    private var pieceFont: CGFloat { width < 360 ? 22 : 26 }
    private var boxWidth: CGFloat { pieceFont * 2.15 }
    private var signWidth: CGFloat { 28 }
    private var playID: String { "\(explains)-\(work.adding)-\(work.start.digitalText)-\(work.differenceHours)-\(work.differenceMinutes)" }

    var body: some View {
        VStack(spacing: 16) {
            clock(work.start, identifier: startIdentifier)
            differenceBar
            if explains && stage >= .sums {
                HStack(alignment: .top, spacing: 10) {
                    sumCard(work.hours, title: "dino.expanded.arithmetic.hours", place: "hours",
                            tint: DinoStyle.green.opacity(highContrast ? 0.55 : 0.38),
                            ink: DinoStyle.deepGreen, arrow: "arrow.turn.down.right")
                    sumCard(work.minutes, title: "dino.expanded.arithmetic.minutes", place: "minutes",
                            tint: Color(dinoHex: 0xFBE7A8),
                            ink: Color(dinoHex: 0x8A6A12), arrow: "arrow.turn.down.left")
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            if explains && stage >= .joined {
                joinedTime.transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.88), value: stage)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(prefix).timeArithmetic")
        .id("\(prefix).timeArithmetic")
        .task(id: playID) { await play() }
    }

    private var differenceBar: some View {
        HStack(spacing: 8) {
            Image(systemName: subtracting ? "minus.circle.fill" : "plus.circle.fill")
                .font(.system(size: 19, weight: .bold))
            Text(verbatim: "\(DinoTimeWords.duration(work.differenceHours * 60 + work.differenceMinutes, language: language)) \(L(key: subtracting ? "dino.expanded.earlier" : "dino.expanded.later"))")
                .font(.system(size: 19, weight: .bold, design: .rounded))
        }
        .foregroundStyle(operationInk)
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(operationFill.opacity(0.28), in: Capsule())
        .overlay(Capsule().strokeBorder(operationInk.opacity(highContrast ? 1 : 0.35), lineWidth: highContrast ? 2 : 1))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(captionIdentifier ?? "\(prefix).timeArithmetic.difference")
    }

    private func sumCard(_ column: DinoClockColumnWork, title: LocalizedStringKey, place: String,
                         tint: Color, ink: Color, arrow: String) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 22, height: 22)
                    .background(.white.opacity(0.72), in: Circle())
                Text(title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(highContrast ? DinoStyle.ink : ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(spacing: 7) {
                ForEach(Array(rows(column).enumerated()), id: \.offset) { _, row in
                    if row.rule {
                        HStack(spacing: 8) {
                            Color.clear.frame(width: signWidth, height: 1)
                            Capsule().fill(Color(dinoHex: 0xD9A07A).opacity(highContrast ? 1 : 0.9))
                                .frame(width: boxWidth, height: highContrast ? 2.5 : 2)
                        }
                        .accessibilityHidden(true)
                    } else {
                        HStack(spacing: 8) {
                            signMark(row.sign).frame(width: signWidth, height: 22)
                            DigitalClockReadout(text: clockDigits(row.digits), theme: theme,
                                                fontSize: pieceFont, width: boxWidth, emphasis: row.emphasis)
                        }
                    }
                }
            }
            if stage >= .joined {
                Image(systemName: arrow)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.deepGreen)
                    .accessibilityHidden(true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .strokeBorder(highContrast ? DinoStyle.ink : DinoStyle.deepGreen.opacity(0.12), lineWidth: highContrast ? 2 : 1))
        .shadow(color: DinoStyle.ink.opacity(0.05), radius: 8, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: column.sums.map(\.equation).joined(separator: ", ")))
        .accessibilityIdentifier("\(prefix).timeArithmetic.\(place)")
    }

    /// The sign stays in its own column, so −15 does not push the digits sideways.
    private func signMark(_ sign: DinoClockOperation?) -> some View {
        Group {
            if let sign {
                Image(systemName: sign == .subtract ? "minus" : "plus")
                    .font(.system(size: 18, weight: .black))
                    .scaleEffect(x: sign == .subtract ? 1.45 : 1, y: 1)
                    .foregroundStyle(sign == .subtract ? DinoTimeDirection.earlier : DinoStyle.deepGreen)
            } else {
                Color.clear
            }
        }
        .accessibilityHidden(true)
    }

    private func rows(_ column: DinoClockColumnWork) -> [SumRow] {
        guard !column.sums.isEmpty else {
            return [SumRow(sign: nil, digits: column.passthrough ?? 0, emphasis: .final)]
        }
        var lines: [SumRow] = []
        for (index, sum) in column.sums.enumerated() {
            if index == 0 {
                lines.append(SumRow(sign: nil, digits: max(0, sum.terms[0]), emphasis: .plain))
            }
            for term in sum.terms.dropFirst() {
                lines.append(SumRow(sign: sum.operation, digits: term, emphasis: .plain))
            }
            lines.append(SumRow(sign: nil, digits: 0, emphasis: .plain, rule: true))
            let last = index == column.sums.count - 1
            lines.append(SumRow(sign: sum.result < 0 ? .subtract : nil,
                                digits: abs(sum.result),
                                emphasis: last ? .final : .bridge))
        }
        return lines
    }

    private var joinedTime: some View {
        VStack(spacing: 4) {
            clock(work.result, identifier: resultIdentifier)
            if showsMidnightNote && work.crossesMidnight {
                Text("dino.expanded.midnightHint")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                    .accessibilityIdentifier("\(prefix).timeArithmetic.midnight")
            }
        }
    }

    private func clockDigits(_ value: Int) -> String {
        (0...99).contains(value) ? String(format: "%02d", value) : String(value)
    }

    private func clock(_ time: ClockTime, identifier: String) -> some View {
        DigitalClock(time: time, theme: theme, fontSize: clockFont, notation: .twentyFour)
            .accessibilityIdentifier(identifier)
    }

    private func play() async {
        guard explains else { stage = .words; return }
        if reduceMotion { stage = .joined; return }
        stage = .words
        try? await Task.sleep(nanoseconds: 280_000_000)
        guard !Task.isCancelled else { return }
        stage = .sums
        try? await Task.sleep(nanoseconds: 700_000_000)
        guard !Task.isCancelled else { return }
        stage = .joined
    }
}
