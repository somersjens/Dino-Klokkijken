import SwiftUI

/// Noninteractive clocks in the practice picker have no per-tick layout or gestures.
struct PracticeClockPreview: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let time: ClockTime
    let theme: ClockTheme

    var body: some View {
        Canvas { context, bounds in
            let size = min(bounds.width, bounds.height)
            let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
            func circle(_ diameter: CGFloat, _ color: Color) {
                context.fill(Path(ellipseIn: CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2,
                                                   width: diameter, height: diameter)), with: .color(color))
            }
            circle(size, Color(dinoHex: theme.rimInk.hex))
            circle(size * 0.932, Color(dinoHex: theme.face.hex))
            for tick in 0..<60 {
                let major = tick.isMultiple(of: 5)
                var rotated = context
                rotated.translateBy(x: center.x, y: center.y)
                rotated.rotate(by: .degrees(Double(tick) * 6))
                let width = size * (major ? 0.012 : 0.005)
                let height = size * (major ? 0.045 : 0.023)
                rotated.fill(Path(roundedRect: CGRect(x: -width / 2, y: -size * 0.425 - height / 2,
                                                     width: width, height: height), cornerRadius: width / 2),
                             with: .color(DinoStyle.ink.opacity(highContrast ? 1 : major ? 0.6 : 0.28)))
            }
            for hour in 1...12 {
                let radians = Double(hour) * .pi / 6
                context.draw(Text(verbatim: "\(hour)")
                    .font(.system(size: size * 0.08, weight: .bold, design: .rounded)).foregroundStyle(DinoStyle.ink),
                             at: CGPoint(x: center.x + CGFloat(sin(radians)) * size * 0.34,
                                         y: center.y - CGFloat(cos(radians)) * size * 0.34))
            }
            func hand(length: CGFloat, width: CGFloat, color: ClockInk, angle: Double) {
                var rotated = context
                rotated.translateBy(x: center.x, y: center.y)
                rotated.rotate(by: .degrees(angle))
                rotated.fill(Path(roundedRect: CGRect(x: -width / 2, y: -length,
                                                     width: width, height: length + size * 0.035),
                                  cornerRadius: theme.hands == .straight ? 1 : width / 2), with: .color(Color(dinoHex: color.hex)))
            }
            hand(length: size * 0.23, width: size * (theme.hands == .playful ? 0.055 : 0.038), color: theme.hourInk, angle: time.hourAngle)
            hand(length: size * 0.34, width: size * (theme.hands == .playful ? 0.036 : 0.024), color: theme.minuteInk, angle: time.minuteAngle)
            circle(size * 0.085, Color(dinoHex: theme.rimInk.hex))
            circle(size * 0.025, .white)
        }.allowsHitTesting(false)
    }
}

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
        .overlay {
            if showHandHints {
                // Straight pointers follow each hand; only nearby badges need separation.
                let difference = (time.hourAngle - time.minuteAngle + 540).truncatingRemainder(dividingBy: 360) - 180
                let spread: Double = abs(difference) < 22 ? (difference > 0 ? 15 : -15) : 0
                ClockHandHint(number: 1, angle: time.hourAngle, length: size * 0.23,
                              ink: theme.hourInk, face: theme.face, size: size, calloutAngle: time.hourAngle + spread)
                ClockHandHint(number: 2, angle: time.minuteAngle, length: size * 0.34,
                              ink: theme.minuteInk, face: theme.face, size: size, calloutAngle: time.minuteAngle - spread)
            }
        }
        .padding(showHandHints ? size * 0.24 : 0)
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

private struct ClockHandHint: View {
    let number: Int
    let angle: Double
    let length: CGFloat
    let ink: ClockInk
    let face: ClockFace
    let size: CGFloat
    let calloutAngle: Double

    private func point(radius: CGFloat, angle: Double) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(x: size * 0.74 + CGFloat(sin(radians)) * radius,
                       y: size * 0.74 - CGFloat(cos(radians)) * radius)
    }

    var body: some View {
        let start = point(radius: size * 0.59, angle: calloutAngle)
        let tip = point(radius: length * 0.85, angle: angle)
        ZStack {
            Canvas { context, _ in
                var path = Path()
                path.move(to: start); path.addLine(to: tip)
                let direction = atan2(tip.y - start.y, tip.x - start.x)
                for offset in [-Double.pi / 5, Double.pi / 5] {
                    path.move(to: tip)
                    path.addLine(to: CGPoint(x: tip.x - cos(direction + offset) * 7,
                                            y: tip.y - sin(direction + offset) * 7))
                }
                context.stroke(path, with: .color(Color(dinoHex: face.hex)), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                context.stroke(path, with: .color(Color(dinoHex: ink.hex)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }
            Text(verbatim: "\(number)")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(dinoHex: ink.hex))
                .frame(width: 24, height: 24).background(.white, in: Circle())
                .overlay(Circle().stroke(Color(dinoHex: ink.hex), lineWidth: 2))
                .position(point(radius: size * 0.66, angle: calloutAngle))
        }.frame(width: size * 1.48, height: size * 1.48)
            .allowsHitTesting(false).accessibilityHidden(true)
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
                .accessibilityValue(time.digitalText)
        }
    }
}
