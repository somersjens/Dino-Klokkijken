import SwiftUI

struct AnalogClockOutline: InsettableShape {
    var shape: AnalogClockShape
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let bounds = rect.insetBy(dx: insetAmount, dy: insetAmount)
        switch shape {
        case .circle: return Path(ellipseIn: bounds)
        case .square: return Path(roundedRect: bounds, cornerRadius: min(bounds.width, bounds.height) * 0.025)
        case .octagon:
            var path = Path()
            let corner = 1 / (2 + sqrt(2.0))
            let vertices: [CGPoint] = [
                CGPoint(x: corner, y: 0), CGPoint(x: 1 - corner, y: 0),
                CGPoint(x: 1, y: corner), CGPoint(x: 1, y: 1 - corner),
                CGPoint(x: 1 - corner, y: 1), CGPoint(x: corner, y: 1),
                CGPoint(x: 0, y: 1 - corner), CGPoint(x: 0, y: corner)
            ]
            for (index, vertex) in vertices.enumerated() {
                let point = CGPoint(x: bounds.minX + vertex.x * bounds.width, y: bounds.minY + vertex.y * bounds.height)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
            return path
        }
    }

    func inset(by amount: CGFloat) -> Self {
        var result = self
        result.insetAmount += amount
        return result
    }
}

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
            let clockBounds = CGRect(x: center.x - size / 2, y: center.y - size / 2, width: size, height: size)
            let outline = AnalogClockOutline(shape: theme.analogShape)
            context.fill(outline.path(in: clockBounds), with: .color(Color(dinoHex: theme.rimHex)))
            context.fill(outline.inset(by: size * 0.034).path(in: clockBounds), with: .color(Color(dinoHex: theme.faceHex)))
            let markings = Color(dinoHex: theme.markingHex)
            for tick in 0..<60 {
                let major = tick.isMultiple(of: 5)
                var rotated = context
                rotated.translateBy(x: center.x, y: center.y)
                rotated.rotate(by: .degrees(Double(tick) * 6))
                let width = size * (major ? 0.012 : 0.005)
                let height = size * (major ? 0.045 : 0.023)
                rotated.fill(Path(roundedRect: CGRect(x: -width / 2, y: -size * 0.425 - height / 2,
                                                     width: width, height: height), cornerRadius: width / 2),
                             with: .color(markings.opacity(highContrast ? 1 : theme.markingHex == 0xFFFFFF ? (major ? 0.9 : 0.55) : (major ? 0.6 : 0.28))))
            }
            for hour in 1...12 {
                let radians = Double(hour) * .pi / 6
                context.draw(Text(verbatim: theme.analogNumerals.label(for: hour))
                    .font(.system(size: size * 0.08, weight: .bold, design: theme.analogNumerals == .roman ? .serif : .rounded)).foregroundStyle(markings),
                             at: CGPoint(x: center.x + CGFloat(sin(radians)) * size * 0.34,
                                         y: center.y - CGFloat(cos(radians)) * size * 0.34))
            }
            func hand(length: CGFloat, width: CGFloat, color: UInt32, angle: Double) {
                var rotated = context
                rotated.translateBy(x: center.x, y: center.y)
                rotated.rotate(by: .degrees(angle))
                rotated.fill(Path(roundedRect: CGRect(x: -width / 2, y: -length,
                                                     width: width, height: length + size * 0.035),
                                  cornerRadius: theme.hands == .straight ? 1 : width / 2), with: .color(Color(dinoHex: color)))
            }
            hand(length: size * 0.23, width: size * 0.038, color: theme.hourHex, angle: time.hourAngle)
            hand(length: size * 0.34, width: size * 0.024, color: theme.minuteHex, angle: time.minuteAngle)
            circle(size * 0.085, Color(dinoHex: theme.rimHex))
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
    var onMinuteChange: ((ClockTime) -> Void)? = nil
    var minuteStep = 1
    var body: some View {
        ZStack {
            AnalogClockOutline(shape: theme.analogShape).fill(Color(dinoHex: theme.rimHex))
                .shadow(color: Color(dinoHex: theme.rimHex).opacity(0.2), radius: 8, y: 5)
            AnalogClockOutline(shape: theme.analogShape).inset(by: size * 0.034).fill(Color(dinoHex: theme.faceHex))
            AnalogClockOutline(shape: theme.analogShape).inset(by: size * 0.015).stroke(.white.opacity(0.4), lineWidth: size * 0.008)
            AnalogClockTicks(size: size, markingHex: theme.markingHex, highContrast: highContrast)
                .equatable()
            ForEach(1...12, id: \.self) { hour in
                let radians = Double(hour) * .pi / 6
                Text(verbatim: theme.analogNumerals.label(for: hour))
                    .font(.system(size: size * 0.08, weight: .bold, design: theme.analogNumerals == .roman ? .serif : .rounded))
                    .foregroundStyle(Color(dinoHex: theme.markingHex))
                    .position(x: size / 2 + CGFloat(sin(radians)) * size * 0.34,
                              y: size / 2 - CGFloat(cos(radians)) * size * 0.34)
            }
            hand(length: size * 0.23, width: hourWidth, color: Color(dinoHex: theme.hourHex), angle: time.hourAngle)
            hand(length: size * 0.34, width: minuteWidth, color: Color(dinoHex: theme.minuteHex), angle: time.minuteAngle)
            Circle().fill(Color(dinoHex: theme.rimHex)).frame(width: size * 0.085)
            Circle().fill(.white).frame(width: size * 0.025)
        }
        .frame(width: size, height: size)
        .contentShape(AnalogClockOutline(shape: theme.analogShape))
        .gesture(DragGesture(minimumDistance: 0).onChanged { value in
            let x = value.location.x - size / 2
            let y = value.location.y - size / 2
            guard hypot(x, y) > size * 0.10 else { return }
            if let onMinuteChange {
                let next = time.settingMinute(ClockTime.snappedMinute(x: Double(x), y: Double(y), step: minuteStep))
                if next != time { onMinuteChange(next) }
            } else {
                let next = ClockTime.snappedHour(x: Double(x), y: Double(y), minute: time.minute)
                if next != time.hour { onHourChange?(next) }
            }
        }, including: onHourChange == nil && onMinuteChange == nil ? .none : .all)
        .overlay {
            if showHandHints {
                let pointers = ClockHandHintGeometry.pointers(time: time, hourWidth: hourWidth / size, minuteWidth: minuteWidth / size)
                ClockHandHint(number: 1, pointer: pointers[0], ink: theme.hourHex, size: size)
                ClockHandHint(number: 2, pointer: pointers[1], ink: theme.minuteHex, size: size)
            }
        }
        .padding(showHandHints ? size * 0.24 : 0)
        .modifier(ClockAccessibility(time: time, onHourChange: onHourChange, onMinuteChange: onMinuteChange, minuteStep: minuteStep))
    }

    private var hourWidth: CGFloat { size * 0.038 }
    private var minuteWidth: CGFloat { size * 0.024 }
    private func hand(length: CGFloat, width: CGFloat, color: Color, angle: Double) -> some View {
        RoundedRectangle(cornerRadius: theme.hands == .straight ? 1 : width / 2)
            .fill(color)
            .frame(width: width, height: length + size * 0.035)
            .offset(y: -(length - size * 0.035) / 2)
            .rotationEffect(.degrees(angle))
    }
}

/// Tick marks do not depend on the hands. One retained drawing replaces sixty
/// separately laid-out shapes while preserving their exact sizes and positions.
private struct AnalogClockTicks: View, Equatable {
    let size: CGFloat
    let markingHex: UInt32
    let highContrast: Bool

    var body: some View {
        Canvas { context, _ in
            for tick in 0..<60 {
                let major = tick.isMultiple(of: 5)
                let width = size * (major ? 0.012 : 0.005)
                let height = size * (major ? 0.045 : 0.023)
                let opacity = highContrast ? 1 : markingHex == 0xFFFFFF ? (major ? 0.9 : 0.55) : (major ? 0.6 : 0.28)
                var rotated = context
                rotated.translateBy(x: size / 2, y: size / 2)
                rotated.rotate(by: .degrees(Double(tick) * 6))
                rotated.fill(Path(roundedRect: CGRect(x: -width / 2, y: -size * 0.425 - height / 2,
                                                     width: width, height: height), cornerRadius: width / 2),
                             with: .color(Color(dinoHex: markingHex).opacity(opacity)))
            }
        }.frame(width: size, height: size).allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct ClockHandHint: View {
    let number: Int
    let pointer: ClockHandHintGeometry.Pointer
    let ink: UInt32
    let size: CGFloat
    private func point(_ point: CGPoint) -> CGPoint {
        CGPoint(x: size * (0.74 + point.x), y: size * (0.74 + point.y))
    }

    var body: some View {
        ClockHintBadgeArrow(number: number, badge: point(pointer.badge), tip: point(pointer.tip),
                           wings: pointer.arrowWings.map(point), ink: ink,
                           bounds: CGSize(width: size * 1.48, height: size * 1.48))
    }
}

private struct ClockAccessibility: ViewModifier {
    let time: ClockTime
    let onHourChange: ((Int) -> Void)?
    let onMinuteChange: ((ClockTime) -> Void)?
    let minuteStep: Int
    func body(content: Content) -> some View {
        // Changing the available accessibility action must not replace the
        // visible face when feedback disables dragging during its animation.
        content.accessibilityRepresentation {
            if let onMinuteChange {
                Color.clear.accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("dino.minutes"))
                    .accessibilityValue(time.digitalText)
                    .accessibilityAdjustableAction { direction in
                        onMinuteChange(time.shiftingMinutes(by: direction == .increment ? minuteStep : -minuteStep))
                    }
            } else if let onHourChange {
                Color.clear.accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("dino.question.setAnalog"))
                    .accessibilityValue(time.digitalText)
                    .accessibilityAdjustableAction { direction in
                        onHourChange(ClockTime.shiftedHour(time.hour == 0 ? 12 : time.hour, by: direction == .increment ? 1 : -1))
                    }
            } else {
                Color.clear.accessibilityElement(children: .ignore).accessibilityLabel(Text("dino.analog"))
                    .accessibilityValue(time.digitalText)
            }
        }
    }
}
