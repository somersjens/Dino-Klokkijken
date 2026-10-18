import SwiftUI

enum WorldBossClock {
    static func time(in worldID: Int) -> ClockTime {
        switch worldID {
        case 1: return .init(hour: 8)
        case 2: return .init(hour: 7, minute: 30)
        case 3: return .init(hour: 4, minute: 45)
        case 4: return .init(hour: 5, minute: 20)
        case 5: return .init(hour: 2, minute: 17)
        case 6: return .init(hour: 12, minute: 45)
        case 7: return .init(hour: 20)
        case 8: return .init(hour: 6, minute: 25)
        case 9: return .init(hour: 9, minute: 30)
        default: return .init(hour: 10, minute: 25)
        }
    }
}

/// One shape-based character renderer for map clearings and boss start cards.
/// The origin is between the feet; hats and carried companions share this baseline.
struct WorldBossPainter {
    let context: GraphicsContext

    func draw(worldID: Int, at point: CGPoint, size: CGFloat) {
        var layer = context
        layer.translateBy(x: point.x, y: point.y)
        layer.scaleBy(x: size, y: size)
        let p = BossBrush(context: layer)
        p.contactShadow()
        switch worldID {
        case 2: p.dreamsaurus()
        case 5: p.crystalGuardian()
        case 6: p.clockRobot()
        case 7: p.forestOwl()
        default: p.dino(worldID: worldID)
        }
    }
}

private struct BossBrush {
    let context: GraphicsContext
    private let ink: UInt32 = 0x224958
    private let gold: UInt32 = 0xDDAF52

    private func mixed(_ color: UInt32, with other: UInt32, amount: Double) -> Color {
        func c(_ shift: UInt32) -> Double {
            let a = Double((color >> shift) & 255), b = Double((other >> shift) & 255)
            return (a + (b - a) * amount) / 255
        }
        return Color(red: c(16), green: c(8), blue: c(0))
    }

    private func paint(_ path: Path, color: UInt32, outline: Bool = false) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(stops: [
            .init(color: mixed(color, with: 0xFFFFFF, amount: 0.34), location: 0),
            .init(color: Color(dinoHex: color), location: 0.40),
            .init(color: mixed(color, with: 0x17384D, amount: 0.32), location: 1)
        ]), startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
        if outline {
            context.stroke(path, with: .color(mixed(color, with: ink, amount: 0.28).opacity(0.48)), lineWidth: 0.65)
        }
    }

    private func oval(_ rect: CGRect, color: UInt32, sheen: Bool = false) {
        let path = Path(ellipseIn: rect)
        let center = CGPoint(x: rect.minX + rect.width * 0.29, y: rect.minY + rect.height * 0.23)
        context.fill(path, with: .radialGradient(Gradient(stops: [
            .init(color: mixed(color, with: 0xFFFFFF, amount: 0.40), location: 0),
            .init(color: Color(dinoHex: color), location: 0.48),
            .init(color: mixed(color, with: 0x17384D, amount: 0.33), location: 1)
        ]), center: center, startRadius: 0, endRadius: max(rect.width, rect.height) * 0.80))
        if sheen {
            var glint = Path()
            glint.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width * 0.36,
                         startAngle: .degrees(205), endAngle: .degrees(254), clockwise: false)
            context.stroke(glint, with: .color(.white.opacity(0.34)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        }
    }

    private func rounded(_ rect: CGRect, radius: CGFloat, color: UInt32) {
        paint(Path(roundedRect: rect, cornerRadius: radius), color: color, outline: true)
    }

    private func polygon(_ points: [CGPoint], color: UInt32) {
        var path = Path(); path.addLines(points); path.closeSubpath()
        paint(path, color: color, outline: true)
    }

    private func stroke(_ path: Path, color: UInt32, width: CGFloat, opacity: Double = 1) {
        context.stroke(path, with: .color(Color(dinoHex: color).opacity(opacity)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func line(_ points: [CGPoint], color: UInt32, width: CGFloat, opacity: Double = 1) {
        var path = Path(); path.addLines(points)
        stroke(path, color: color, width: width, opacity: opacity)
    }

    private func limb(_ path: Path, color: UInt32, width: CGFloat) {
        let r = path.boundingRect
        context.stroke(path, with: .linearGradient(Gradient(colors: [mixed(color, with: 0xFFFFFF, amount: 0.18),
                                                                    mixed(color, with: ink, amount: 0.22)]),
                                                    startPoint: CGPoint(x: r.minX, y: r.minY),
                                                    endPoint: CGPoint(x: r.maxX, y: r.maxY)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    func contactShadow() {
        let rect = CGRect(x: -67, y: -5, width: 136, height: 21)
        context.fill(Path(ellipseIn: rect), with: .radialGradient(
            Gradient(colors: [Color(dinoHex: 0x314A53).opacity(0.25), .clear]),
            center: CGPoint(x: 4, y: 5), startRadius: 4, endRadius: 68))
        context.fill(Path(ellipseIn: CGRect(x: -38, y: -1, width: 78, height: 9)),
                     with: .color(Color(dinoHex: 0x314A53).opacity(0.12)))
    }

    private func eye(at center: CGPoint, size: CGFloat = 1, iris: UInt32 = 0x6D573F, sleepy: Bool = false) {
        if sleepy {
            var arc = Path()
            arc.move(to: CGPoint(x: center.x - 6 * size, y: center.y))
            arc.addQuadCurve(to: CGPoint(x: center.x + 6 * size, y: center.y),
                             control: CGPoint(x: center.x, y: center.y + 5 * size))
            stroke(arc, color: ink, width: 1.8)
            line([CGPoint(x: center.x + 4 * size, y: center.y + 1), CGPoint(x: center.x + 6 * size, y: center.y + 3)], color: ink, width: 1.1)
            return
        }
        oval(CGRect(x: center.x - 8 * size, y: center.y - 13 * size, width: 17 * size, height: 25 * size), color: 0xFDF9E9)
        oval(CGRect(x: center.x - 3 * size, y: center.y - 7 * size, width: 9 * size, height: 16 * size), color: iris)
        oval(CGRect(x: center.x - 1 * size, y: center.y - 4 * size, width: 5 * size, height: 11 * size), color: 0x183B43)
        context.fill(Path(ellipseIn: CGRect(x: center.x - 2 * size, y: center.y - 7 * size, width: 4 * size, height: 5 * size)), with: .color(.white))
        context.fill(Path(ellipseIn: CGRect(x: center.x + 2 * size, y: center.y + 3 * size, width: 1.7 * size, height: 2 * size)), with: .color(.white.opacity(0.8)))
        var lid = Path()
        lid.move(to: CGPoint(x: center.x - 8 * size, y: center.y - 10 * size))
        lid.addQuadCurve(to: CGPoint(x: center.x + 8 * size, y: center.y - 10 * size), control: CGPoint(x: center.x, y: center.y - 17 * size))
        stroke(lid, color: ink, width: 1.1, opacity: 0.55)
    }

    private func smile(at point: CGPoint, width: CGFloat = 26) {
        var path = Path()
        path.move(to: CGPoint(x: point.x - width / 2, y: point.y - 2))
        path.addQuadCurve(to: CGPoint(x: point.x + width / 2, y: point.y - 3), control: CGPoint(x: point.x + 2, y: point.y + 10))
        stroke(path, color: ink, width: 1.8)
        oval(CGRect(x: point.x + width / 2 - 2, y: point.y - 5, width: 3, height: 3), color: ink)
    }

    /// A real dial: hour hand includes the minute fraction, as in the game clocks.
    private func clock(at center: CGPoint, radius: CGFloat, time: ClockTime, metal: UInt32 = 0xDDAF52, dark: Bool = false, fabric: Bool = false) {
        let bevel = radius * 0.10, inset = radius * 0.15
        if !fabric {
            oval(CGRect(x: center.x - radius - bevel, y: center.y - radius,
                        width: radius * 2 + bevel * 2, height: radius * 2 + bevel * 2), color: 0x536968)
        }
        let rim = CGRect(x: center.x - radius, y: center.y - radius - bevel, width: radius * 2, height: radius * 2)
        oval(rim, color: metal, sheen: !fabric)
        let face = CGRect(x: center.x - radius + inset, y: center.y - radius + inset - bevel,
                          width: radius * 2 - inset * 2, height: radius * 2 - inset * 2)
        oval(face, color: dark ? 0x32586B : 0xFFF6D8)
        if fabric {
            context.stroke(Path(ellipseIn: rim.insetBy(dx: 1.2, dy: 1.2)), with: .color(Color(dinoHex: 0xF4E9CE)),
                           style: StrokeStyle(lineWidth: 0.8, lineCap: .round, dash: [1.3, 2]))
        }
        let c = CGPoint(x: center.x, y: center.y - bevel)
        let hands: UInt32 = dark ? 0xF7D785 : 0x2C5159
        for i in 0..<12 {
            let a = Double(i) * .pi / 6
            let inner = radius * (i.isMultiple(of: 3) ? 0.66 : 0.73), outer = radius * 0.80
            line([CGPoint(x: c.x + CGFloat(sin(a)) * inner, y: c.y - CGFloat(cos(a)) * inner),
                  CGPoint(x: c.x + CGFloat(sin(a)) * outer, y: c.y - CGFloat(cos(a)) * outer)],
                 color: hands, width: max(0.35, radius * (i.isMultiple(of: 3) ? 0.0625 : 0.0375)), opacity: 0.65)
        }
        if radius >= 8 {
            for (number, position) in [(12, CGPoint(x: 0, y: -0.53)), (3, CGPoint(x: 0.56, y: 0)),
                                   (6, CGPoint(x: 0, y: 0.55)), (9, CGPoint(x: -0.55, y: 0))] {
                context.draw(Text(verbatim: String(number)).font(.system(size: radius * 0.24, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(dinoHex: hands)), at: CGPoint(x: c.x + position.x * radius, y: c.y + position.y * radius))
            }
        }
        for (degrees, length, weight) in [(Double(time.hour % 12) * 30 + Double(time.minute) * 0.5, radius * 0.43, max(0.55, radius * 0.095)),
                                           (Double(time.minute) * 6, radius * 0.67, max(0.40, radius * 0.06))] {
            let a = degrees * .pi / 180
            let end = CGPoint(x: c.x + CGFloat(sin(a)) * length, y: c.y - CGFloat(cos(a)) * length)
            line([CGPoint(x: c.x + bevel * 0.35, y: c.y + bevel * 0.4), CGPoint(x: end.x + bevel * 0.35, y: end.y + bevel * 0.4)], color: ink, width: weight + bevel * 0.3, opacity: 0.18)
            line([c, end], color: hands, width: weight)
        }
        oval(CGRect(x: c.x - bevel, y: c.y - bevel, width: bevel * 2, height: bevel * 2), color: metal)
        guard !fabric else { return }
        var reflection = Path()
        reflection.move(to: CGPoint(x: face.minX + radius * 0.25, y: face.midY - radius * 0.05))
        reflection.addQuadCurve(to: CGPoint(x: face.midX + bevel, y: face.minY + radius * 0.2),
                                control: CGPoint(x: face.minX + inset, y: face.minY + radius * 0.2))
        context.stroke(reflection, with: .color(.white.opacity(0.56)), style: StrokeStyle(lineWidth: max(0.45, radius * 0.09), lineCap: .round))
    }

    private func display(at center: CGPoint, width: CGFloat, height: CGFloat, time: ClockTime) {
        rounded(CGRect(x: center.x - width / 2 - 2, y: center.y - height / 2 - 2, width: width + 4, height: height + 4), radius: 5, color: 0x9FC4C4)
        rounded(CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height), radius: 4, color: 0x244D61)
        let string = String(format: "%02d:%02d", time.hour, time.minute)
        context.draw(Text(verbatim: string).font(.system(size: height * 0.60, weight: .bold, design: .monospaced))
            .foregroundStyle(Color(dinoHex: 0xFDE4A0)), at: center)
        line([CGPoint(x: center.x - width / 2 + 5, y: center.y - height / 2 + 2),
              CGPoint(x: center.x - 2, y: center.y - height / 2 + 2)], color: 0xB8E5D7, width: 1, opacity: 0.4)
    }

    private func necklace(at center: CGPoint, radius: CGFloat, time: ClockTime, metal: UInt32 = 0xDDAF52) {
        var chain = Path()
        chain.move(to: CGPoint(x: -24, y: -84))
        chain.addQuadCurve(to: CGPoint(x: center.x, y: center.y - radius + 3), control: CGPoint(x: -18, y: -60))
        chain.addQuadCurve(to: CGPoint(x: 25, y: -84), control: CGPoint(x: 18, y: -60))
        stroke(chain, color: 0x725F41, width: 3)
        context.stroke(chain, with: .color(Color(dinoHex: metal)), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 2]))
        rounded(CGRect(x: center.x - 4, y: center.y - radius - 7, width: 8, height: 8), radius: 3, color: metal)
        clock(at: center, radius: radius, time: time, metal: metal)
    }

    private func leaf(at point: CGPoint, length: CGFloat, angle: Double, color: UInt32) {
        var layer = context
        layer.translateBy(x: point.x, y: point.y); layer.rotate(by: .degrees(angle))
        let p = BossBrush(context: layer)
        var path = Path()
        path.move(to: .zero)
        path.addQuadCurve(to: CGPoint(x: 0, y: -length), control: CGPoint(x: -length * 0.43, y: -length * 0.5))
        path.addQuadCurve(to: .zero, control: CGPoint(x: length * 0.37, y: -length * 0.45))
        p.paint(path, color: color, outline: true)
        p.line([.zero, CGPoint(x: 0, y: -length * 0.83)], color: 0xE2EFBD, width: 0.7, opacity: 0.6)
    }

    private func toes(at point: CGPoint, color: UInt32) {
        for i in 0..<3 { oval(CGRect(x: point.x + CGFloat(i) * 7, y: point.y, width: 6, height: 5), color: color) }
    }

    func dino(worldID: Int) {
        let skin: UInt32
        switch worldID {
        case 1: skin = 0x4C9E80
        case 3: skin = 0xC86F4E
        case 4: skin = 0xB38951
        case 8: skin = 0x8976B8
        case 9: skin = 0x4F83A3
        default: skin = 0xBC965D
        }
        costumeBehind(worldID: worldID)
        var tail = Path()
        tail.move(to: CGPoint(x: 18, y: -55))
        tail.addCurve(to: CGPoint(x: 71, y: -68), control1: CGPoint(x: 45, y: -25), control2: CGPoint(x: 65, y: -33))
        tail.addCurve(to: CGPoint(x: 26, y: -19), control1: CGPoint(x: 77, y: -25), control2: CGPoint(x: 59, y: -9))
        tail.closeSubpath(); paint(tail, color: skin, outline: true)
        if worldID == 4 { oval(CGRect(x: 57, y: -73, width: 23, height: 23), color: skin, sheen: true) }
        oval(CGRect(x: -31, y: -95, width: 67, height: 83), color: skin)
        oval(CGRect(x: -21, y: -73, width: 48, height: 57), color: 0xF1DCAB)
        for x: CGFloat in [-32, 9] {
            oval(CGRect(x: x, y: -30, width: 29, height: 34), color: skin)
            rounded(CGRect(x: x - 1, y: -10, width: 33, height: 13), radius: 6, color: skin)
            toes(at: CGPoint(x: x + 5, y: -2), color: 0xF4E7CA)
        }
        costumeBody(worldID: worldID)
        var leftArm = Path()
        leftArm.move(to: CGPoint(x: -28, y: -78))
        leftArm.addQuadCurve(to: CGPoint(x: -39, y: -34), control: CGPoint(x: -51, y: -59))
        limb(leftArm, color: skin, width: 15)
        oval(CGRect(x: -47, y: -39, width: 18, height: 14), color: skin)
        var rightArm = Path()
        rightArm.move(to: CGPoint(x: 29, y: -78))
        rightArm.addQuadCurve(to: CGPoint(x: worldID == 4 ? 47 : 41, y: worldID == 4 ? -64 : -35),
                             control: CGPoint(x: 49, y: -69))
        limb(rightArm, color: skin, width: 15)
        if worldID != 4 { oval(CGRect(x: 33, y: -42, width: 18, height: 15), color: skin) }
        for x: CGFloat in [-43, -38, 37, 42] { line([CGPoint(x: x, y: -32), CGPoint(x: x + 1, y: -29)], color: 0xE4CFAB, width: 1.1, opacity: 0.6) }

        var head = Path()
        head.move(to: CGPoint(x: -33, y: -97))
        head.addCurve(to: CGPoint(x: -25, y: -145), control1: CGPoint(x: -47, y: -116), control2: CGPoint(x: -40, y: -141))
        head.addCurve(to: CGPoint(x: 32, y: -133), control1: CGPoint(x: -2, y: -155), control2: CGPoint(x: 25, y: -152))
        head.addCurve(to: CGPoint(x: 31, y: -94), control1: CGPoint(x: 40, y: -113), control2: CGPoint(x: 45, y: -101))
        head.addQuadCurve(to: CGPoint(x: -33, y: -97), control: CGPoint(x: 0, y: -76))
        head.closeSubpath(); paint(head, color: skin, outline: true)
        oval(CGRect(x: -26, y: -110, width: 72, height: 33), color: skin)
        oval(CGRect(x: -12, y: -90, width: 47, height: 10), color: 0xE4CEA0)
        eye(at: CGPoint(x: -15, y: -128), size: 0.80)
        eye(at: CGPoint(x: 14, y: -126), size: 0.84)
        line([CGPoint(x: -25, y: -142), CGPoint(x: -16, y: -145), CGPoint(x: -9, y: -144)], color: skin, width: 4)
        line([CGPoint(x: 6, y: -141), CGPoint(x: 16, y: -144), CGPoint(x: 22, y: -141)], color: skin, width: 4)
        oval(CGRect(x: 21, y: -105, width: 4, height: 3), color: ink)
        oval(CGRect(x: 34, y: -103, width: 3.5, height: 2.6), color: ink)
        smile(at: CGPoint(x: 8, y: -95), width: 31)
        oval(CGRect(x: -27, y: -103, width: 10, height: 7), color: 0xE0A38E)
        for i in 0..<5 {
            let x = CGFloat(i % 3) * 6 - 32, y = CGFloat(i / 3) * 6 - 92
            oval(CGRect(x: x, y: y, width: 2.5, height: 2), color: skin)
        }
        costumeHead(worldID: worldID)
        carriedClock(worldID: worldID, skin: skin)
    }

    private func costumeBehind(worldID: Int) {
        switch worldID {
        case 1:
            for i in 0..<6 {
                leaf(at: CGPoint(x: 23 + CGFloat(i) * 6, y: -91 + CGFloat(i) * 5),
                     length: CGFloat(24 - i * 2), angle: Double(28 + i * 5), color: 0x356D59)
            }
        case 3:
            oval(CGRect(x: -49, y: -162, width: 99, height: 109), color: 0xE3AC4D)
            oval(CGRect(x: -42, y: -156, width: 85, height: 92), color: 0xF0C56B)
            for i in 0..<9 {
                let a = Double(i) * .pi / 8 + .pi
                oval(CGRect(x: CGFloat(cos(a)) * 40 - 3, y: -109 + CGFloat(sin(a)) * 42 - 3, width: 7, height: 9), color: 0xF9DF9E)
            }
        case 4:
            for i in 0..<5 {
                polygon([CGPoint(x: 22 + CGFloat(i) * 5, y: -81 + CGFloat(i) * 4),
                         CGPoint(x: 27 + CGFloat(i) * 5, y: -96 + CGFloat(i) * 5),
                         CGPoint(x: 35 + CGFloat(i) * 5, y: -76 + CGFloat(i) * 5)], color: 0xC3A773)
            }
        case 8:
            for side: CGFloat in [-1, 1] {
                var wing = Path()
                wing.move(to: CGPoint(x: side * 21, y: -84))
                wing.addQuadCurve(to: CGPoint(x: side * 71, y: -117), control: CGPoint(x: side * 47, y: -107))
                wing.addQuadCurve(to: CGPoint(x: side * 60, y: -51), control: CGPoint(x: side * 69, y: -81))
                wing.addQuadCurve(to: CGPoint(x: side * 23, y: -35), control: CGPoint(x: side * 44, y: -61))
                wing.closeSubpath(); paint(wing, color: 0xAA98CC, outline: true)
                line([CGPoint(x: side * 24, y: -80), CGPoint(x: side * 66, y: -108)], color: 0xDBCCEB, width: 1.6)
                line([CGPoint(x: side * 24, y: -80), CGPoint(x: side * 60, y: -55)], color: 0xDBCCEB, width: 1.1)
            }
        case 9:
            var sail = Path()
            sail.move(to: CGPoint(x: 21, y: -91))
            sail.addQuadCurve(to: CGPoint(x: 41, y: -150), control: CGPoint(x: 31, y: -139))
            sail.addCurve(to: CGPoint(x: 68, y: -43), control1: CGPoint(x: 58, y: -129), control2: CGPoint(x: 60, y: -74))
            sail.addQuadCurve(to: CGPoint(x: 19, y: -40), control: CGPoint(x: 38, y: -52))
            sail.closeSubpath(); paint(sail, color: 0xD98268, outline: true)
            for i in 0..<4 { line([CGPoint(x: 29, y: -51), CGPoint(x: 41 + CGFloat(i) * 5, y: -137 + CGFloat(i) * 22)], color: 0xF4BD8D, width: 1.2) }
        case 10:
            var cape = Path()
            cape.move(to: CGPoint(x: -25, y: -99))
            cape.addQuadCurve(to: CGPoint(x: 31, y: -96), control: CGPoint(x: 0, y: -108))
            cape.addCurve(to: CGPoint(x: 57, y: 1), control1: CGPoint(x: 41, y: -73), control2: CGPoint(x: 53, y: -21))
            cape.addQuadCurve(to: CGPoint(x: -53, y: 1), control: CGPoint(x: 0, y: 11))
            cape.addCurve(to: CGPoint(x: -25, y: -99), control1: CGPoint(x: -46, y: -40), control2: CGPoint(x: -42, y: -84))
            cape.closeSubpath(); paint(cape, color: 0x5E7FB5, outline: true)
            line([CGPoint(x: -27, y: -92), CGPoint(x: -49, y: -1)], color: gold, width: 2)
            line([CGPoint(x: 32, y: -87), CGPoint(x: 53, y: -1)], color: gold, width: 2)
            for side: CGFloat in [-1, 1] { line([CGPoint(x: side * 30, y: -75), CGPoint(x: side * 38, y: -12)], color: 0xA0B3D4, width: 1, opacity: 0.5) }
        default: break
        }
    }

    private func costumeBody(worldID: Int) {
        switch worldID {
        case 1:
            rounded(CGRect(x: -26, y: -85, width: 55, height: 56), radius: 18, color: 0x668460)
            for side: CGFloat in [-1, 1] {
                leaf(at: CGPoint(x: side * 24, y: -79), length: 24, angle: Double(side * 54), color: 0x92B96B)
                leaf(at: CGPoint(x: side * 14, y: -80), length: 21, angle: Double(side * 28), color: 0xADD18B)
            }
            for y: CGFloat in [-76, -32] { line([CGPoint(x: -16, y: y), CGPoint(x: 19, y: y)], color: 0xCDD6A2, width: 1, opacity: 0.65) }
        case 3:
            for i in 0..<5 { oval(CGRect(x: 17 + CGFloat(i % 2) * 5, y: -88 + CGFloat(i) * 8, width: 4.5, height: 3.5), color: 0xE2A05F) }
            for side: CGFloat in [-1, 1] { rounded(CGRect(x: side * 34 - 7, y: -36, width: 14, height: 10), radius: 4, color: 0xB69561) }
            polygon([CGPoint(x: 19, y: -94), CGPoint(x: 32, y: -84), CGPoint(x: -17, y: -25), CGPoint(x: -32, y: -37)], color: 0x955447)
            line([CGPoint(x: 21, y: -91), CGPoint(x: -29, y: -36)], color: 0xE9C47E, width: 1.5)
            line([CGPoint(x: 29, y: -84), CGPoint(x: -17, y: -29)], color: 0xE9C47E, width: 1.5)
            for i in 0..<7 {
                let x = 20 - CGFloat(i) * 7, y = -85 + CGFloat(i) * 8
                line([CGPoint(x: x, y: y), CGPoint(x: x + 5, y: y + 3)], color: 0xBD8B62, width: 0.7)
            }
        case 4, 8, 9:
            let fabric: UInt32 = worldID == 4 ? 0x5C85A9 : worldID == 8 ? 0xF3E4BD : 0xBE755B
            for side: CGFloat in [-1, 1] {
                polygon([CGPoint(x: side * 25, y: -90), CGPoint(x: side * 9, y: -87),
                         CGPoint(x: side * 4, y: -41), CGPoint(x: side * 27, y: -34)], color: fabric)
                line([CGPoint(x: side * 20, y: -86), CGPoint(x: side * 9, y: -72), CGPoint(x: side * 20, y: -63)],
                     color: worldID == 8 ? 0xD1BE95 : 0xE5BF8F, width: 1.2)
            }
            if worldID == 4 {
                polygon([CGPoint(x: -4, y: -88), CGPoint(x: 4, y: -88), CGPoint(x: 8, y: -66),
                         CGPoint(x: 0, y: -59), CGPoint(x: -7, y: -66)], color: gold)
                line([CGPoint(x: 52, y: -116), CGPoint(x: 48, y: -63), CGPoint(x: 43, y: -9)], color: 0x806148, width: 6)
                line([CGPoint(x: 51, y: -109), CGPoint(x: 48, y: -64), CGPoint(x: 45, y: -19)], color: 0xC6A575, width: 1.6)
            }
            if worldID == 9 {
                rounded(CGRect(x: -29, y: -40, width: 60, height: 10), radius: 3, color: 0x705340)
                rounded(CGRect(x: -5, y: -41, width: 13, height: 12), radius: 2, color: gold)
                rounded(CGRect(x: -2, y: -38, width: 7, height: 6), radius: 1, color: 0x705340)
            }
            for y: CGFloat in [-71, -56] { oval(CGRect(x: 21, y: y, width: 3.5, height: 3.5), color: gold) }
        case 10:
            oval(CGRect(x: -28, y: -93, width: 20, height: 15), color: 0xF5E8C8)
            oval(CGRect(x: 9, y: -92, width: 22, height: 15), color: 0xF5E8C8)
            for x: CGFloat in [-22, -15, 14, 22] { oval(CGRect(x: x, y: -86, width: 2, height: 2), color: 0x72563D) }
        default: break
        }
    }

    private func costumeHead(worldID: Int) {
        switch worldID {
        case 1:
            for i in 0..<5 { leaf(at: CGPoint(x: -22 + CGFloat(i) * 11, y: -142), length: CGFloat(16 + i % 2 * 5), angle: Double(i - 2) * 23, color: 0xA8C97B) }
            rounded(CGRect(x: -31, y: -143, width: 63, height: 5), radius: 2, color: 0x806848)
            oval(CGRect(x: -6, y: -147, width: 12, height: 10), color: 0xE7D195, sheen: true)
        case 3:
            for x: CGFloat in [-21, 20] {
                var horn = Path()
                horn.move(to: CGPoint(x: x - 7, y: -136))
                horn.addQuadCurve(to: CGPoint(x: x - 1, y: -164), control: CGPoint(x: x - 11, y: -151))
                horn.addQuadCurve(to: CGPoint(x: x + 7, y: -135), control: CGPoint(x: x + 5, y: -151))
                horn.closeSubpath(); paint(horn, color: 0xF5E4BC, outline: true)
            }
            polygon([CGPoint(x: 21, y: -109), CGPoint(x: 24, y: -122), CGPoint(x: 32, y: -108)], color: 0xF5E4BC)
        case 4:
            rounded(CGRect(x: -31, y: -150, width: 62, height: 7), radius: 3, color: 0x5C85A9)
            rounded(CGRect(x: -20, y: -162, width: 43, height: 15), radius: 5, color: 0x7AA4C5)
            line([CGPoint(x: -17, y: -149), CGPoint(x: 21, y: -149)], color: gold, width: 1.8)
        case 8:
            for center in [CGPoint(x: -15, y: -128), CGPoint(x: 14, y: -126)] {
                let rect = CGRect(x: center.x - 12, y: center.y - 13, width: 24, height: 27)
                context.stroke(Path(ellipseIn: rect), with: .color(Color(dinoHex: 0x7B6147)), lineWidth: 4)
                context.stroke(Path(ellipseIn: rect.insetBy(dx: -0.5, dy: -0.5)), with: .color(Color(dinoHex: gold)), lineWidth: 1.4)
                line([CGPoint(x: center.x - 8, y: center.y - 8), CGPoint(x: center.x - 2, y: center.y - 12)], color: 0xFFFFFF, width: 1.4, opacity: 0.8)
            }
            line([CGPoint(x: -3, y: -129), CGPoint(x: 2, y: -128)], color: gold, width: 2)
            line([CGPoint(x: -29, y: -129), CGPoint(x: -35, y: -133)], color: gold, width: 2)
            wizardHat()
        case 9:
            var hat = Path()
            hat.move(to: CGPoint(x: -42, y: -140))
            hat.addQuadCurve(to: CGPoint(x: -28, y: -161), control: CGPoint(x: -45, y: -158))
            hat.addQuadCurve(to: CGPoint(x: 0, y: -157), control: CGPoint(x: -11, y: -146))
            hat.addQuadCurve(to: CGPoint(x: 29, y: -160), control: CGPoint(x: 15, y: -145))
            hat.addQuadCurve(to: CGPoint(x: 43, y: -140), control: CGPoint(x: 46, y: -156))
            hat.addQuadCurve(to: CGPoint(x: -42, y: -140), control: CGPoint(x: 0, y: -135))
            hat.closeSubpath(); paint(hat, color: 0x9A6550, outline: true)
            line([CGPoint(x: -37, y: -141), CGPoint(x: 0, y: -137), CGPoint(x: 39, y: -141)], color: gold, width: 2)
            oval(CGRect(x: -6, y: -154, width: 12, height: 10), color: gold)
            line([CGPoint(x: 0, y: -152), CGPoint(x: 0, y: -145)], color: 0x896249, width: 1.3)
        case 10:
            polygon([CGPoint(x: -36, y: -142), CGPoint(x: -40, y: -178), CGPoint(x: -26, y: -168),
                     CGPoint(x: -15, y: -188), CGPoint(x: 0, y: -177), CGPoint(x: 15, y: -188),
                     CGPoint(x: 27, y: -169), CGPoint(x: 40, y: -178), CGPoint(x: 36, y: -142)], color: gold)
            rounded(CGRect(x: -36, y: -145, width: 72, height: 8), radius: 3, color: 0xEDCA6F)
            for x: CGFloat in [-30, 30] {
                oval(CGRect(x: x - 3.5, y: -162, width: 7, height: 8), color: 0x64B2AA, sheen: true)
            }
            // The large dial is built into the front of the crown.
            clock(at: CGPoint(x: 0, y: -163), radius: 24, time: WorldBossClock.time(in: 10), metal: 0xE9C36A)
        default: break
        }
    }

    private func carriedClock(worldID: Int, skin: UInt32) {
        switch worldID {
        case 1:
            necklace(at: CGPoint(x: 1, y: -57), radius: 21, time: WorldBossClock.time(in: 1), metal: 0xC5A670)
            for side: CGFloat in [-1, 1] { leaf(at: CGPoint(x: side * 19, y: -46), length: 12, angle: Double(side * 75), color: 0x9BC576) }
        case 3:
            // Clock brooches follow the diagonal sash, with three quarter times.
            clock(at: CGPoint(x: 18, y: -77), radius: 9, time: .init(hour: 1, minute: 15), metal: 0xDDB267)
            clock(at: CGPoint(x: 0, y: -55), radius: 12, time: WorldBossClock.time(in: 3), metal: 0xEDC781)
            clock(at: CGPoint(x: -19, y: -34), radius: 9, time: .init(hour: 8, minute: 15), metal: 0xDDB267)
        case 4:
            rounded(CGRect(x: 48, y: -115, width: 8, height: 8), radius: 3, color: gold)
            clock(at: CGPoint(x: 54, y: -132), radius: 18, time: WorldBossClock.time(in: 4))
            // Fingers pass in front of the shaft, so the staff is visibly held.
            oval(CGRect(x: 41, y: -70, width: 16, height: 14), color: skin)
            for y: CGFloat in [-65, -62] { line([CGPoint(x: 48, y: y), CGPoint(x: 54, y: y)], color: 0xDBC69B, width: 1) }
        case 9:
            parrotWithClock()
        default: break
        }
    }

    private func wizardHat() {
        // A bent cone and broad brim give Pendel a distinct wizard silhouette.
        oval(CGRect(x: -44, y: -154, width: 87, height: 15), color: 0x4B548D)
        var cone = Path()
        cone.move(to: CGPoint(x: -33, y: -149))
        cone.addQuadCurve(to: CGPoint(x: -13, y: -197), control: CGPoint(x: -20, y: -168))
        cone.addQuadCurve(to: CGPoint(x: 21, y: -187), control: CGPoint(x: 3, y: -205))
        cone.addQuadCurve(to: CGPoint(x: 3, y: -182), control: CGPoint(x: 15, y: -186))
        cone.addQuadCurve(to: CGPoint(x: 31, y: -149), control: CGPoint(x: 17, y: -164))
        cone.closeSubpath(); paint(cone, color: 0x6471AA, outline: true)
        line([CGPoint(x: -31, y: -149), CGPoint(x: 0, y: -145), CGPoint(x: 31, y: -149)], color: gold, width: 3)
        line([CGPoint(x: -20, y: -159), CGPoint(x: -13, y: -179)], color: 0xA7ABDA, width: 1.1, opacity: 0.7)
        clock(at: CGPoint(x: 10, y: -158), radius: 11, time: WorldBossClock.time(in: 8), metal: 0xE7C478)
        clock(at: CGPoint(x: -7, y: -174), radius: 8, time: .init(hour: 10, minute: 10), metal: 0xBED9D0)
        clock(at: CGPoint(x: -9, y: -190), radius: 5.5, time: .init(hour: 3), metal: 0xE4B7CC)
    }

    private func parrotWithClock() {
        // Perched on the left shoulder, facing the pendant held in its beak.
        polygon([CGPoint(x: -54, y: -95), CGPoint(x: -64, y: -65), CGPoint(x: -47, y: -80),
                 CGPoint(x: -41, y: -92)], color: 0x548FAB)
        line([CGPoint(x: -56, y: -89), CGPoint(x: -61, y: -69)], color: 0xA7D8CF, width: 1)
        oval(CGRect(x: -60, y: -116, width: 26, height: 40), color: 0xDF7F63)
        oval(CGRect(x: -62, y: -116, width: 19, height: 30), color: 0xE6C463)
        var wing = Path()
        wing.move(to: CGPoint(x: -47, y: -111))
        wing.addQuadCurve(to: CGPoint(x: -35, y: -81), control: CGPoint(x: -27, y: -96))
        wing.addQuadCurve(to: CGPoint(x: -50, y: -94), control: CGPoint(x: -44, y: -81))
        wing.closeSubpath(); paint(wing, color: 0x60A897, outline: true)
        for i in 0..<3 { line([CGPoint(x: -44 + CGFloat(i) * 3, y: -101), CGPoint(x: -38 + CGFloat(i) * 2, y: -88)], color: 0x9FD6BD, width: 0.8) }
        for x: CGFloat in [-47, -40] {
            line([CGPoint(x: x, y: -80), CGPoint(x: x - 1, y: -74), CGPoint(x: x + 3, y: -73)], color: 0x79694E, width: 1.8)
        }
        oval(CGRect(x: -65, y: -132, width: 24, height: 26), color: 0xE48468)
        oval(CGRect(x: -64, y: -126, width: 14, height: 17), color: 0xF4E8C4)
        eye(at: CGPoint(x: -57, y: -119), size: 0.34, iris: 0x637D74)
        var beak = Path()
        beak.move(to: CGPoint(x: -63, y: -122))
        beak.addQuadCurve(to: CGPoint(x: -73, y: -114), control: CGPoint(x: -76, y: -123))
        beak.addQuadCurve(to: CGPoint(x: -66, y: -107), control: CGPoint(x: -73, y: -108))
        beak.addQuadCurve(to: CGPoint(x: -63, y: -122), control: CGPoint(x: -69, y: -113))
        beak.closeSubpath(); paint(beak, color: 0xD5AF58, outline: true)
        // The chain starts inside the hooked beak and ends in the pendant bail.
        var chain = Path()
        chain.move(to: CGPoint(x: -68, y: -112))
        chain.addQuadCurve(to: CGPoint(x: -65, y: -94), control: CGPoint(x: -70, y: -101))
        chain.addQuadCurve(to: CGPoint(x: -60, y: -83), control: CGPoint(x: -60, y: -88))
        stroke(chain, color: 0x826846, width: 1.8)
        context.stroke(chain, with: .color(Color(dinoHex: gold)), style: StrokeStyle(lineWidth: 1.1, lineCap: .round, dash: [1, 1.8]))
        rounded(CGRect(x: -63, y: -83, width: 6, height: 7), radius: 2, color: gold)
        clock(at: CGPoint(x: -60, y: -64), radius: 14, time: WorldBossClock.time(in: 9), metal: 0xE7BD6B)
    }

    func dreamsaurus() {
        let blue: UInt32 = 0x75B5CB
        var tail = Path()
        tail.move(to: CGPoint(x: 28, y: -60))
        tail.addQuadCurve(to: CGPoint(x: 72, y: -55), control: CGPoint(x: 61, y: -19))
        tail.addQuadCurve(to: CGPoint(x: 32, y: -17), control: CGPoint(x: 80, y: -17))
        tail.closeSubpath(); paint(tail, color: blue, outline: true)
        for x: CGFloat in [-12, 30] {
            rounded(CGRect(x: x, y: -30, width: 21, height: 31), radius: 9, color: 0x659BAF)
        }
        oval(CGRect(x: -24, y: -72, width: 87, height: 58), color: blue)
        oval(CGRect(x: -6, y: -49, width: 64, height: 32), color: 0xD2E4CB)
        var neck = Path()
        neck.move(to: CGPoint(x: -17, y: -40))
        neck.addCurve(to: CGPoint(x: -42, y: -128), control1: CGPoint(x: -53, y: -59), control2: CGPoint(x: -41, y: -96))
        neck.addLine(to: CGPoint(x: -24, y: -132))
        neck.addCurve(to: CGPoint(x: 3, y: -56), control1: CGPoint(x: -16, y: -99), control2: CGPoint(x: -27, y: -72))
        neck.closeSubpath(); paint(neck, color: blue, outline: true)
        var neckHighlight = Path()
        neckHighlight.move(to: CGPoint(x: -32, y: -108))
        neckHighlight.addQuadCurve(to: CGPoint(x: -20, y: -56), control: CGPoint(x: -36, y: -75))
        stroke(neckHighlight, color: 0xC5E6DC, width: 3.5, opacity: 0.65)
        oval(CGRect(x: -57, y: -145, width: 48, height: 44), color: blue)
        oval(CGRect(x: -43, y: -123, width: 42, height: 22), color: blue)
        eye(at: CGPoint(x: -41, y: -130), size: 0.65, sleepy: true)
        eye(at: CGPoint(x: -20, y: -129), size: 0.60, sleepy: true)
        smile(at: CGPoint(x: -23, y: -114), width: 20)
        oval(CGRect(x: -49, y: -123, width: 7, height: 5), color: 0xD6B3BB)
        polygon([CGPoint(x: -57, y: -141), CGPoint(x: -42, y: -166), CGPoint(x: -13, y: -154), CGPoint(x: -10, y: -139)], color: 0x9891C5)
        rounded(CGRect(x: -57, y: -145, width: 48, height: 7), radius: 3, color: 0xD9D5ED)
        oval(CGRect(x: -46, y: -169, width: 10, height: 10), color: 0xF2E7C7)
        for x: CGFloat in [-6, 35] {
            rounded(CGRect(x: x, y: -26, width: 23, height: 29), radius: 9, color: blue)
            toes(at: CGPoint(x: x + 2, y: -2), color: 0xE9EBCE)
        }
        // A moon and small embroidered stars keep the blanket in the night theme.
        var blanket = Path()
        blanket.move(to: CGPoint(x: -12, y: -72))
        blanket.addQuadCurve(to: CGPoint(x: 53, y: -69), control: CGPoint(x: 19, y: -89))
        blanket.addCurve(to: CGPoint(x: 58, y: -22), control1: CGPoint(x: 60, y: -59), control2: CGPoint(x: 55, y: -37))
        blanket.addQuadCurve(to: CGPoint(x: -11, y: -21), control: CGPoint(x: 24, y: -12))
        blanket.addQuadCurve(to: CGPoint(x: -12, y: -72), control: CGPoint(x: -3, y: -47))
        blanket.closeSubpath(); paint(blanket, color: 0xA499CA, outline: true)
        stroke(blanket, color: 0xEDE3CE, width: 1.8)
        for x: CGFloat in [-5, 8, 21, 34, 47] {
            line([CGPoint(x: x, y: -19), CGPoint(x: x + 1, y: -13)], color: 0xEDE3CE, width: 1.2)
        }
        let disk = Path(ellipseIn: CGRect(x: 2, y: -68, width: 33, height: 33))
        var cut = disk; cut.addEllipse(in: CGRect(x: 13, y: -74, width: 30, height: 30))
        var embroidery = context; embroidery.clip(to: disk); embroidery.clip(to: cut, style: FillStyle(eoFill: true))
        embroidery.fill(disk, with: .color(Color(dinoHex: 0xF4DFAD)))
        for (x, y): (CGFloat, CGFloat) in [(40, -59), (33, -36), (7, -29)] {
            var star = Path()
            star.addLines([CGPoint(x: x, y: y - 4), CGPoint(x: x + 1, y: y - 1), CGPoint(x: x + 4, y: y),
                           CGPoint(x: x + 1, y: y + 1), CGPoint(x: x, y: y + 4), CGPoint(x: x - 1, y: y + 1),
                           CGPoint(x: x - 4, y: y), CGPoint(x: x - 1, y: y - 1)])
            star.closeSubpath(); context.fill(star, with: .color(Color(dinoHex: 0xEDE4CF)))
        }
    }

    private func crystal(at point: CGPoint, height: CGFloat, color: UInt32) {
        polygon([CGPoint(x: point.x - 7, y: point.y - height * 0.69), CGPoint(x: point.x, y: point.y - height),
                 CGPoint(x: point.x + 8, y: point.y - height * 0.72), CGPoint(x: point.x + 7, y: point.y - 3),
                 CGPoint(x: point.x, y: point.y), CGPoint(x: point.x - 6, y: point.y - 4)], color: color)
        polygon([CGPoint(x: point.x, y: point.y - height), CGPoint(x: point.x + 8, y: point.y - height * 0.72),
                 CGPoint(x: point.x + 7, y: point.y - 3), CGPoint(x: point.x, y: point.y)], color: 0x7394A5)
        line([CGPoint(x: point.x - 3, y: point.y - height * 0.65), CGPoint(x: point.x - 3, y: point.y - 7)], color: 0xF0FFF3, width: 1.1)
    }

    func crystalGuardian() {
        for side: CGFloat in [-1, 1] {
            rounded(CGRect(x: side * 44 - 13, y: -91, width: 26, height: 53), radius: 11, color: 0x6F919E)
            rounded(CGRect(x: side * 49 - 13, y: -52, width: 27, height: 23), radius: 8, color: 0x9BB9BD)
            for i in 0..<3 { line([CGPoint(x: side * 48 + CGFloat(i - 1) * 6, y: -36), CGPoint(x: side * 48 + CGFloat(i - 1) * 6, y: -30)], color: 0x527C88, width: 1) }
        }
        rounded(CGRect(x: -36, y: -99, width: 75, height: 80), radius: 24, color: 0x8FAFB4)
        polygon([CGPoint(x: 16, y: -94), CGPoint(x: 33, y: -86), CGPoint(x: 35, y: -34),
                 CGPoint(x: 20, y: -24), CGPoint(x: 19, y: -52)], color: 0x7698A6)
        polygon([CGPoint(x: -32, y: -87), CGPoint(x: -17, y: -98), CGPoint(x: 11, y: -94), CGPoint(x: -7, y: -82)], color: 0xB1CDD0)
        for x: CGFloat in [-32, 8] {
            rounded(CGRect(x: x, y: -27, width: 29, height: 30), radius: 9, color: 0x759BA7)
            polygon([CGPoint(x: x + 3, y: -16), CGPoint(x: x + 15, y: -20), CGPoint(x: x + 25, y: -13), CGPoint(x: x + 23, y: 0), CGPoint(x: x + 2, y: -2)], color: 0xA7C5C5)
        }
        rounded(CGRect(x: -32, y: -143, width: 64, height: 53), radius: 21, color: 0xAECBCB)
        polygon([CGPoint(x: 18, y: -138), CGPoint(x: 30, y: -126), CGPoint(x: 26, y: -97), CGPoint(x: 18, y: -105)], color: 0x7EA3AC)
        eye(at: CGPoint(x: -14, y: -120), size: 0.81, iris: 0x5C9295)
        eye(at: CGPoint(x: 14, y: -119), size: 0.81, iris: 0x5C9295)
        smile(at: CGPoint(x: 0, y: -103), width: 24)
        for (x, h, color): (CGFloat, CGFloat, UInt32) in [(-17, 21, 0x87D0C3), (0, 36, 0xAC99D2), (17, 25, 0xE2B1CC)] {
            crystal(at: CGPoint(x: x, y: -140), height: h, color: color)
        }
        for side: CGFloat in [-1, 1] {
            crystal(at: CGPoint(x: side * 37, y: -81), height: 28, color: 0x84CABD)
            crystal(at: CGPoint(x: side * 50, y: -75), height: 19, color: 0xADA3DA)
        }
        // The clock bezel is a carved socket in the stone chest.
        polygon([CGPoint(x: -23, y: -72), CGPoint(x: 0, y: -83), CGPoint(x: 24, y: -72),
                 CGPoint(x: 27, y: -47), CGPoint(x: 0, y: -29), CGPoint(x: -26, y: -43)], color: 0x5E8795)
        clock(at: CGPoint(x: 1, y: -57), radius: 22, time: WorldBossClock.time(in: 5), metal: 0x93D5C2)
        for side: CGFloat in [-1, 1] {
            line([CGPoint(x: side * 22, y: -65), CGPoint(x: side * 30, y: -77), CGPoint(x: side * 33, y: -85)], color: 0xB5F4E0, width: 1.3)
            line([CGPoint(x: side * 22, y: -47), CGPoint(x: side * 31, y: -36), CGPoint(x: side * 25, y: -29)], color: 0xB5F4E0, width: 1.3)
        }
    }

    private func bolt(at point: CGPoint, size: CGFloat = 4) {
        oval(CGRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size), color: 0xE3CC94, sheen: true)
        line([CGPoint(x: point.x - size * 0.24, y: point.y), CGPoint(x: point.x + size * 0.24, y: point.y)], color: 0x7E755C, width: 0.6)
    }

    func clockRobot() {
        let teal: UInt32 = 0x4397A7
        for side: CGFloat in [-1, 1] {
            var arm = Path()
            arm.move(to: CGPoint(x: side * 30, y: -85))
            arm.addQuadCurve(to: CGPoint(x: side * 46, y: -40), control: CGPoint(x: side * 56, y: -74))
            limb(arm, color: 0x7C9FA3, width: 12)
            for i in 0..<3 { line([CGPoint(x: side * (41 + CGFloat(i)), y: -72 + CGFloat(i) * 8), CGPoint(x: side * (49 + CGFloat(i)), y: -68 + CGFloat(i) * 8)], color: 0xC8D9C9, width: 1.4) }
            oval(CGRect(x: side * 48 - 10, y: -45, width: 21, height: 19), color: 0xE3BE66, sheen: true)
            oval(CGRect(x: side * 31 - 6, y: -94, width: 14, height: 15), color: 0xDAAF5B)
        }
        rounded(CGRect(x: -35, y: -99, width: 70, height: 77), radius: 19, color: teal)
        rounded(CGRect(x: -27, y: -92, width: 55, height: 59), radius: 15, color: 0x61B4B5)
        for x: CGFloat in [-27, 26] {
            for y: CGFloat in [-88, -36] { bolt(at: CGPoint(x: x, y: y), size: 4.5) }
        }
        rounded(CGRect(x: -12, y: -109, width: 24, height: 15), radius: 5, color: 0x89AFAC)
        rounded(CGRect(x: -39, y: -148, width: 79, height: 52), radius: 20, color: teal)
        rounded(CGRect(x: -33, y: -141, width: 64, height: 38), radius: 14, color: 0xEDD69B)
        rounded(CGRect(x: 29, y: -135, width: 9, height: 27), radius: 4, color: 0x326C81)
        eye(at: CGPoint(x: -14, y: -125), size: 0.61, iris: 0x498C87)
        eye(at: CGPoint(x: 12, y: -125), size: 0.61, iris: 0x498C87)
        smile(at: CGPoint(x: -1, y: -114), width: 20)
        line([CGPoint(x: 0, y: -148), CGPoint(x: -3, y: -162)], color: 0xD6B570, width: 4)
        oval(CGRect(x: -9, y: -171, width: 13, height: 13), color: 0xF5D176, sheen: true)
        for x: CGFloat in [-32, 10] {
            rounded(CGRect(x: x + 3, y: -31, width: 21, height: 24), radius: 7, color: 0x6F9BA4)
            rounded(CGRect(x: x, y: -14, width: 32, height: 18), radius: 7, color: 0xDFBE77)
            line([CGPoint(x: x + 5, y: -1), CGPoint(x: x + 26, y: -1)], color: 0x947D52, width: 1.4)
        }
        display(at: CGPoint(x: 1, y: -67), width: 50, height: 22, time: WorldBossClock.time(in: 6))
        for (x, color): (CGFloat, UInt32) in [(-16, 0xF3D37B), (0, 0xA9DDD0), (16, 0xF1AF89)] {
            oval(CGRect(x: x - 3, y: -45, width: 6, height: 6), color: color, sheen: true)
        }
        for y: CGFloat in [-32, -28] { line([CGPoint(x: -13, y: y), CGPoint(x: 15, y: y)], color: 0x376E80, width: 1) }
    }

    func forestOwl() {
        oval(CGRect(x: -38, y: -127, width: 79, height: 127), color: 0xAF9871)
        oval(CGRect(x: -29, y: -103, width: 61, height: 91), color: 0xDED0AC)
        for side: CGFloat in [-1, 1] {
            var tuft = Path()
            tuft.move(to: CGPoint(x: side * 4, y: -125))
            tuft.addQuadCurve(to: CGPoint(x: side * 33, y: -158), control: CGPoint(x: side * 21, y: -136))
            tuft.addQuadCurve(to: CGPoint(x: side * 36, y: -109), control: CGPoint(x: side * 32, y: -127))
            tuft.closeSubpath(); paint(tuft, color: 0xAF9871, outline: true)
            line([CGPoint(x: side * 22, y: -130), CGPoint(x: side * 28, y: -146)], color: 0xDFD0AF, width: 1.3)
        }
        for side: CGFloat in [-1, 1] {
            oval(CGRect(x: side * 17 - 22, y: -136, width: 44, height: 57), color: 0xF4EACD)
            eye(at: CGPoint(x: side * 17, y: -112), size: 1.0, iris: side == -1 ? 0x8C6C44 : 0x516FA4)
            var wing = Path()
            wing.move(to: CGPoint(x: side * 32, y: -90))
            wing.addCurve(to: CGPoint(x: side * 51, y: -27), control1: CGPoint(x: side * 61, y: -95), control2: CGPoint(x: side * 64, y: -47))
            wing.addQuadCurve(to: CGPoint(x: side * 28, y: -38), control: CGPoint(x: side * 32, y: -13))
            wing.closeSubpath(); paint(wing, color: side == -1 ? 0xD4AE56 : 0x6B8EBF, outline: true)
            for i in 0..<4 {
                var feather = Path()
                let x = side * (35 + CGFloat(i) * 5)
                feather.move(to: CGPoint(x: x, y: -75 + CGFloat(i) * 5))
                feather.addQuadCurve(to: CGPoint(x: x - side * 2, y: -32), control: CGPoint(x: x + side * 5, y: -48))
                stroke(feather, color: side == -1 ? 0xEED496 : 0xA9C2DF, width: 1.2, opacity: 0.75)
            }
        }
        polygon([CGPoint(x: -8, y: -97), CGPoint(x: 10, y: -97), CGPoint(x: 2, y: -81)], color: 0xDEAF4E)
        for i in 0..<8 {
            let x = CGFloat(i % 4) * 10 - 16, y = CGFloat(i / 4) * 11 - 77
            var feather = Path(); feather.move(to: CGPoint(x: x - 3, y: y))
            feather.addQuadCurve(to: CGPoint(x: x + 3, y: y), control: CGPoint(x: x, y: y + 5))
            stroke(feather, color: 0xB9A888, width: 0.9, opacity: 0.6)
        }
        for side: CGFloat in [-1, 1] {
            for i in 0..<3 { line([CGPoint(x: side * 15, y: -3), CGPoint(x: side * 15 + CGFloat(i - 1) * 5, y: 4)], color: 0xB19464, width: 3) }
        }
        // A harness holds the pendant to the breast, rather than beside the owl.
        line([CGPoint(x: -20, y: -84), CGPoint(x: -11, y: -63), CGPoint(x: 0, y: -58),
              CGPoint(x: 12, y: -63), CGPoint(x: 22, y: -85)], color: 0xA48A5D, width: 3)
        clock(at: CGPoint(x: 1, y: -44), radius: 21, time: WorldBossClock.time(in: 7), metal: 0xB6C2A1, dark: true)
        display(at: CGPoint(x: 1, y: -16), width: 31, height: 10, time: WorldBossClock.time(in: 7))
    }
}
