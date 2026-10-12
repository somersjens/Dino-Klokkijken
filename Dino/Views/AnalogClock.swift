import SwiftUI

struct AnalogClock: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let time: ClockTime
    let theme: ClockTheme
    var size: CGFloat = 230
    var onHourChange: ((Int) -> Void)? = nil
    var showHandHints = false
    var onMinuteChange: ((Int) -> Void)? = nil
    var minuteStep = 1
    var body: some View {
        ZStack {
            Circle().fill(Color(dinoHex: theme.rimInk.hex))
                .shadow(color: Color(dinoHex: theme.rimInk.hex).opacity(0.2), radius: 8, y: 5)
            Circle().fill(Color(dinoHex: theme.face.hex)).padding(size * 0.034)
            Circle().stroke(.white.opacity(0.4), lineWidth: size * 0.008).padding(size * 0.015)
            ForEach(0..<60, id: \.self) { tick in
                Capsule().fill(DinoStyle.ink.opacity(highContrast ? 1 : tick.isMultiple(of: 5) ? 0.6 : 0.28))
                    .frame(width: tick.isMultiple(of: 5) ? size * 0.012 : size * 0.005,
                           height: tick.isMultiple(of: 5) ? size * 0.045 : size * 0.023)
                    .offset(y: -size * 0.425)
                    .rotationEffect(.degrees(Double(tick) * 6))
            }
            ForEach(1...12, id: \.self) { hour in
                let radians = Double(hour) * .pi / 6
                Text(verbatim: "\(hour)")
                    .font(.system(size: size * 0.08, weight: .bold, design: .rounded))
                    .foregroundStyle(DinoStyle.ink)
                    .position(x: size / 2 + CGFloat(sin(radians)) * size * 0.34,
                              y: size / 2 - CGFloat(cos(radians)) * size * 0.34)
            }
            hand(length: size * 0.23, width: hourWidth, color: Color(dinoHex: theme.hourInk.hex), angle: time.hourAngle)
            hand(length: size * 0.34, width: minuteWidth, color: Color(dinoHex: theme.minuteInk.hex), angle: time.minuteAngle)
            Circle().fill(Color(dinoHex: theme.rimInk.hex)).frame(width: size * 0.085)
            Circle().fill(.white).frame(width: size * 0.025)
            if showHandHints {
                Image(systemName: "arrow.down").foregroundStyle(Color(dinoHex: theme.minuteInk.hex))
                    .font(.system(size: size * 0.09, weight: .bold)).offset(x: size * 0.10, y: -size * 0.2)
                    .rotationEffect(.degrees(time.minuteAngle))
                Image(systemName: "arrow.down").foregroundStyle(Color(dinoHex: theme.hourInk.hex))
                    .font(.system(size: size * 0.09, weight: .bold)).offset(y: -size * 0.29)
                    .rotationEffect(.degrees(time.hourAngle))
            }
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(DragGesture(minimumDistance: 0).onChanged { value in
            let x = value.location.x - size / 2
            let y = value.location.y - size / 2
            guard hypot(x, y) > size * 0.10 else { return }
            if let onMinuteChange {
                onMinuteChange(ClockTime.snappedMinute(x: Double(x), y: Double(y), step: minuteStep))
            } else {
                onHourChange?(ClockTime.snappedHour(x: Double(x), y: Double(y), minute: time.minute))
            }
        }, including: onHourChange == nil && onMinuteChange == nil ? .none : .all)
        .modifier(ClockAccessibility(time: time, onHourChange: onHourChange, onMinuteChange: onMinuteChange, minuteStep: minuteStep))
    }

    private var hourWidth: CGFloat { size * (theme.hands == .playful ? 0.055 : 0.038) }
    private var minuteWidth: CGFloat { size * (theme.hands == .playful ? 0.036 : 0.024) }
    private func hand(length: CGFloat, width: CGFloat, color: Color, angle: Double) -> some View {
        RoundedRectangle(cornerRadius: theme.hands == .straight ? 1 : width / 2)
            .fill(color)
            .frame(width: width, height: length + size * 0.035)
            .offset(y: -(length - size * 0.035) / 2)
            .rotationEffect(.degrees(angle))
    }
}

private struct ClockAccessibility: ViewModifier {
    let time: ClockTime
    let onHourChange: ((Int) -> Void)?
    let onMinuteChange: ((Int) -> Void)?
    let minuteStep: Int
    @ViewBuilder func body(content: Content) -> some View {
        if let onMinuteChange {
            content.accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("dino.minutes"))
                .accessibilityValue(time.digitalText)
                .accessibilityAdjustableAction { direction in
                    onMinuteChange(ClockTime.shiftedMinute(time.minute, by: direction == .increment ? minuteStep : -minuteStep))
                }
        } else if let onHourChange {
            content.accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("dino.question.setAnalog"))
                .accessibilityValue(time.digitalText)
                .accessibilityAdjustableAction { direction in
                    onHourChange(ClockTime.shiftedHour(time.hour == 0 ? 12 : time.hour, by: direction == .increment ? 1 : -1))
                }
        } else {
            content.accessibilityElement(children: .ignore).accessibilityLabel(Text("dino.analog"))
        }
    }
}
