import SwiftUI

/// Every section meets its neighbour at the same centre line and vertical tangent.
/// The sign is drawn over the trail, rather than leaving a blank break in it.
struct WorldRouteTrail: View {
    let points: [CGPoint]
    var entryY: CGFloat? = nil
    let exitY: CGFloat

    private var path: Path {
        guard let first = points.first, let last = points.last else { return Path() }
        return Path { path in
            if let entryY {
                // Extend the strokes beyond the section, including the offset shadow.
                path.move(to: CGPoint(x: last.x, y: entryY - 12))
                path.addCurve(to: first,
                              control1: CGPoint(x: last.x, y: entryY + (first.y - entryY) * 0.50),
                              control2: CGPoint(x: first.x, y: first.y - 88))
            } else { path.move(to: first) }
            for pair in zip(points, points.dropFirst()) {
                path.addCurve(to: pair.1, control1: CGPoint(x: pair.0.x, y: pair.0.y + 88),
                              control2: CGPoint(x: pair.1.x, y: pair.1.y - 88))
            }
            path.addLine(to: CGPoint(x: last.x, y: exitY + 12))
        }
    }

    var body: some View {
        // Paths avoid allocating a second full-height Canvas texture per world.
        ZStack(alignment: .topLeading) {
            path.stroke(Color(dinoHex: 0x78995D).opacity(0.21), style: StrokeStyle(lineWidth: 46, lineCap: .butt)).offset(y: 5)
            path.stroke(Color(dinoHex: 0xC9BB83), style: StrokeStyle(lineWidth: 40, lineCap: .butt))
            path.stroke(Color(dinoHex: 0xF4E6B6), style: StrokeStyle(lineWidth: 34, lineCap: .butt))
            path.stroke(Color(dinoHex: 0xFFF9D8).opacity(0.95), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 12]))
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Chapter lettering and description share one sculpted, theme-specific sign.
struct WorldTitleBanner: View {
    let world: DinoWorld
    var highContrast = false

    var body: some View {
        GeometryReader { geometry in
            let layout = WorldBannerLayout(width: geometry.size.width)
            let palette = WorldBannerPalette(worldID: world.id)
            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    WorldBannerPainter(context: context, world: world).draw(in: size)
                }.allowsHitTesting(false).accessibilityHidden(true)
                Text("dino.worldNumber \(world.id)")
                    .textCase(.uppercase)
                    .font(.system(size: 12, weight: .heavy, design: .rounded)).tracking(1.3)
                    .foregroundStyle(Color(dinoHex: palette.tabInk))
                    .frame(width: layout.tab.width - 20, height: layout.tab.height)
                    .position(x: layout.tab.midX, y: layout.tab.midY)
                Text(LocalizedStringKey(world.titleKey))
                    .font(.system(size: 33, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(dinoHex: highContrast ? (world.id == 3 ? 0xFFFFFF : 0x153C48) : palette.ink))
                    .shadow(color: Color(dinoHex: palette.titleShadow).opacity(0.55), radius: 0, y: 1.4)
                    .lineLimit(world.id == 7 ? 2 : 1).minimumScaleFactor(0.58)
                    .multilineTextAlignment(.center).lineSpacing(-1)
                    .frame(width: layout.titleWidth, height: 82)
                    .position(x: layout.titlePanel.midX, y: layout.titlePanel.midY)
                Text(LocalizedStringKey(world.skillKey))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(dinoHex: palette.subtitleInk))
                    .lineLimit(2).minimumScaleFactor(0.82)
                    .multilineTextAlignment(.center).lineSpacing(-1)
                    .frame(width: layout.subtitle.width - 36, height: 27)
                    .position(x: layout.subtitle.midX + 10, y: layout.subtitle.midY)
            }
        }.frame(height: 212)
            .accessibilityElement(children: .combine)
    }
}

private struct WorldBannerLayout {
    let width: CGFloat
    let scale: CGFloat
    let plate: CGRect
    let titlePanel: CGRect
    let tab: CGRect
    let subtitle: CGRect
    let titleWidth: CGFloat
    init(width: CGFloat) {
        self.width = width
        scale = min(1.26, max(0.82, width / 354))
        plate = CGRect(x: 29 * scale, y: 42, width: width - 58 * scale, height: 142)
        titlePanel = CGRect(x: 62 * scale, y: 58, width: width - 124 * scale, height: 83)
        tab = CGRect(x: width / 2 - 62, y: 20, width: 124, height: 32)
        subtitle = CGRect(x: 70 * scale, y: 146, width: width - 140 * scale, height: 29)
        titleWidth = width - 146 * scale
    }
}

private struct WorldBannerPalette {
    var ink: UInt32 = 0x294959
    var titleShadow: UInt32 = 0xDAB867
    var light: UInt32 = 0xFFF4D1
    var face: UInt32 = 0xF2E7BE
    var dark: UInt32 = 0xC9B17C
    var rim: UInt32 = 0xA78650
    var accent: UInt32 = 0x79A45E
    var shade: UInt32 = 0x38694B
    var tabInk: UInt32 = 0x573D29
    var tabLight: UInt32 = 0xFFE5AB
    var tabFace: UInt32 = 0xEABD7B
    var subtitleLight: UInt32 = 0xFFFADE
    var subtitleFace: UInt32 = 0xE9E8BB
    var subtitleDark: UInt32 = 0xB6C18A
    var subtitleInk: UInt32 = 0x345346
    init(worldID: Int) {
        switch worldID {
        case 1: ink = 0x235C34; accent = 0x7BB341; shade = 0x2C653A
        case 2:
            accent = 0x9FACC9; shade = 0x586F92; light = 0xF5F0FF; face = 0xE5DBF0; dark = 0xB4AACB; rim = 0x978EAA
            tabLight = 0xEFE8FF; tabFace = 0xCBBEE0; tabInk = 0x53617E
            subtitleLight = 0xF6F2FC; subtitleFace = 0xE6E0F2; subtitleDark = 0xB4AEC8; subtitleInk = 0x52627D
        case 3:
            ink = 0xFFF1CA; titleShadow = 0x40343F; light = 0x9B8791; face = 0x716371; dark = 0x494957; rim = 0xBE8351; accent = 0xF5A064; shade = 0x585363
            tabLight = 0xFFDEAC; tabFace = 0xD79B67
            subtitleLight = 0xFFEBCB; subtitleFace = 0xE8B98E; subtitleDark = 0xBD8667; subtitleInk = 0x6C443C
        case 4: accent = 0xC0835B; shade = 0x6B7852; subtitleFace = 0xF0DAB0; subtitleDark = 0xCDAE79; subtitleInk = 0x6C5542
        case 5:
            ink = 0x455984; accent = 0x83CFCB; shade = 0x527A9F; light = 0xEFFAFF; face = 0xCCE5F0; dark = 0x98B4CE; rim = 0x77A0B9
            tabLight = 0xE5F9F4; tabFace = 0xA9D8DE; tabInk = 0x41647A
            subtitleLight = 0xF0FCFB; subtitleFace = 0xD3EDF1; subtitleDark = 0xA1CADB; subtitleInk = 0x41617F
        case 6:
            ink = 0x256879; accent = 0x63C7CC; shade = 0x3A7185; light = 0xE4F9F6; face = 0xBBDCDD; dark = 0x81ADB8; rim = 0x6798A9
            tabLight = 0xD3EDF0; tabFace = 0x93C6CC; tabInk = 0x2A6679
            subtitleLight = 0xEBFBFA; subtitleFace = 0xC0E2E4; subtitleDark = 0x88B5C1; subtitleInk = 0x2E6278
        case 7:
            accent = 0x9CB68E; shade = 0x5D7790; subtitleLight = 0xF7E9BC; subtitleFace = 0xECE5D0; subtitleDark = 0xB9BBD5; subtitleInk = 0x4A6172
        case 8:
            accent = 0xD6B46A; shade = 0x747D86; rim = 0xA88B55; tabFace = 0xD4B579
            subtitleLight = 0xFCEDCA; subtitleFace = 0xE6D1A0; subtitleDark = 0xBBA36F; subtitleInk = 0x5B5D56
        case 9:
            ink = 0x674731; accent = 0x72BABC; shade = 0x667D75; face = 0xEFDEB3; dark = 0xC5A878; rim = 0x967147
            tabFace = 0xDBAF70; subtitleLight = 0xFFF1CF; subtitleFace = 0xEAD1A0; subtitleDark = 0xC4A575; subtitleInk = 0x705038
        default:
            ink = 0x36577A; accent = 0x8EADD0; shade = 0x536E99; face = 0xEEE6C7; rim = 0xB59455
            tabFace = 0xE2C482
            subtitleLight = 0x8EACD0; subtitleFace = 0x5D7CA9; subtitleDark = 0x3E577D; subtitleInk = 0xFFF4D7
        }
    }
}

private struct WorldBannerPainter {
    let context: GraphicsContext
    let world: DinoWorld
    private var palette: WorldBannerPalette { .init(worldID: world.id) }

    private func material(_ path: Path, light: UInt32, face: UInt32, dark: UInt32) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: light), location: 0),
            .init(color: Color(dinoHex: face), location: 0.46),
            .init(color: Color(dinoHex: dark), location: 1)
        ]), startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
    }
    private func line(_ points: [CGPoint], color: UInt32, width: CGFloat = 1, opacity: Double = 1) {
        var path = Path(); path.addLines(points)
        context.stroke(path, with: .color(Color(dinoHex: color).opacity(opacity)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func polygon(_ points: [CGPoint], light: UInt32, face: UInt32, dark: UInt32) {
        var path = Path(); path.addLines(points); path.closeSubpath()
        material(path, light: light, face: face, dark: dark)
    }
    private func oval(_ r: CGRect, light: UInt32, face: UInt32, dark: UInt32) {
        let center = CGPoint(x: r.minX + r.width * 0.3, y: r.minY + r.height * 0.2)
        context.fill(Path(ellipseIn: r), with: .radialGradient(Gradient(colors: [Color(dinoHex: light), Color(dinoHex: face), Color(dinoHex: dark)]),
                                                               center: center, startRadius: 0, endRadius: max(r.width, r.height) * 0.8))
    }
    private func glow(at point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), .clear]), center: point, startRadius: 0, endRadius: radius))
    }
    private func transformed(at point: CGPoint, scale: CGFloat = 1, mirror: Bool = false, draw: (WorldBannerPainter) -> Void) {
        var layer = context
        layer.translateBy(x: point.x, y: point.y); layer.scaleBy(x: mirror ? -scale : scale, y: scale)
        draw(.init(context: layer, world: world))
    }

    func draw(in size: CGSize) {
        let layout = WorldBannerLayout(width: size.width)
        // One continuous silhouette owns the chapter tab, shoulders and base.
        foundation(layout: layout)
        connectedRim(layout: layout)
        for side in 0..<2 {
            transformed(at: CGPoint(x: side == 0 ? 54 * layout.scale : size.width - 54 * layout.scale, y: side == 0 ? 105 : 109),
                        scale: layout.scale, mirror: side == 1) {
                $0.endcap(front: false, variation: side)
            }
        }
        // The quiet lettering surface occludes the inward parts of the ornaments.
        // They grow out of the frame instead of sitting over the lettering.
        board(in: layout.titlePanel)
        subtitle(in: layout.subtitle)
        tab(in: layout.tab)
        for side in 0..<2 {
            transformed(at: CGPoint(x: side == 0 ? 54 * layout.scale : size.width - 54 * layout.scale, y: side == 0 ? 105 : 109),
                        scale: layout.scale, mirror: side == 1) {
                // Only small edge details cross the face; never redraw the whole
                // assembly or cover the inset description panel.
                $0.endcap(front: true, variation: side)
            }
        }
    }

    private func outline(plate r: CGRect, tab t: CGRect, inset: CGFloat = 0) -> Path {
        let r = r.insetBy(dx: inset, dy: inset)
        let t = t.insetBy(dx: inset, dy: inset)
        let corner = max(16, 28 - inset)
        return Path { p in
            p.move(to: CGPoint(x: r.minX + corner, y: r.minY))
            p.addLine(to: CGPoint(x: t.minX - 9, y: r.minY))
            p.addCurve(to: CGPoint(x: t.minX + 12, y: t.minY),
                       control1: CGPoint(x: t.minX + 1, y: r.minY),
                       control2: CGPoint(x: t.minX - 4, y: t.minY))
            p.addLine(to: CGPoint(x: t.maxX - 12, y: t.minY))
            p.addCurve(to: CGPoint(x: t.maxX + 9, y: r.minY),
                       control1: CGPoint(x: t.maxX + 4, y: t.minY),
                       control2: CGPoint(x: t.maxX - 1, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX - corner, y: r.minY))
            p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + corner), control: CGPoint(x: r.maxX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - corner))
            p.addQuadCurve(to: CGPoint(x: r.maxX - corner, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX + corner, y: r.maxY))
            p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - corner), control: CGPoint(x: r.minX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.minY + corner))
            p.addQuadCurve(to: CGPoint(x: r.minX + corner, y: r.minY), control: CGPoint(x: r.minX, y: r.minY))
            p.closeSubpath()
        }
    }

    private func foundation(layout: WorldBannerLayout) {
        let shape = outline(plate: layout.plate, tab: layout.tab)
        var shadow = context; shadow.translateBy(x: 0, y: 6)
        shadow.fill(shape, with: .color(Color(dinoHex: palette.shade).opacity(0.29)))
        material(shape, light: palette.tabLight, face: palette.dark, dark: palette.rim)
        context.stroke(shape, with: .color(Color(dinoHex: palette.shade).opacity(0.6)), lineWidth: 1.2)
        context.stroke(outline(plate: layout.plate, tab: layout.tab, inset: 3),
                       with: .linearGradient(Gradient(colors: [Color(dinoHex: palette.light), Color(dinoHex: palette.rim)]),
                                             startPoint: CGPoint(x: 0, y: 20), endPoint: CGPoint(x: layout.width, y: 184)), lineWidth: 2)
        context.stroke(outline(plate: layout.plate, tab: layout.tab, inset: 8),
                       with: .color(Color(dinoHex: palette.shade).opacity(0.22)), lineWidth: 1)
    }

    private func connectedRim(layout: WorldBannerLayout) {
        let r = layout.plate
        let rim = outline(plate: r, tab: layout.tab, inset: 6)
        if [1, 2, 4, 7].contains(world.id) {
            context.stroke(rim, with: .color(Color(dinoHex: palette.shade).opacity(0.72)),
                           style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
            context.stroke(rim, with: .color(Color(dinoHex: palette.accent).opacity(0.85)), lineWidth: 1)
            // A few leaves sprout from the shared top branch, joining the two fans.
            for side in 0..<2 {
                let x = side == 0 ? r.minX + 52 : r.maxX - 52
                transformed(at: CGPoint(x: x, y: r.minY + 7), scale: 0.56, mirror: side == 1) {
                    $0.leaf(at: .zero, length: 27, width: 17, angle: -76,
                            light: palette.light, face: palette.accent, dark: palette.shade)
                }
            }
        } else if world.id == 3 {
            context.stroke(rim, with: .color(Color(dinoHex: 0x6A606A)), lineWidth: 5)
            context.stroke(rim, with: .color(Color(dinoHex: 0xEEBA7A)), lineWidth: 1.3)
            for x in stride(from: r.minX + 26, to: r.maxX - 14, by: 28) {
                line([CGPoint(x: x, y: r.maxY - 14), CGPoint(x: x + 3, y: r.maxY - 4)], color: 0x77707D, width: 1)
            }
        } else if world.id == 5 {
            context.stroke(rim, with: .color(Color(dinoHex: 0xBEE4E4)), lineWidth: 4)
            context.stroke(rim, with: .color(Color(dinoHex: 0xE9FFF5)), lineWidth: 1.2)
            for x in stride(from: r.minX + 31, to: r.maxX - 20, by: 34) {
                polygon([CGPoint(x: x, y: r.maxY - 13), CGPoint(x: x + 14, y: r.maxY - 15),
                         CGPoint(x: x + 23, y: r.maxY - 7), CGPoint(x: x + 6, y: r.maxY - 6)],
                        light: 0xE9FFF5, face: 0xA8CED8, dark: 0x8FAAC8)
            }
        } else if world.id == 6 || world.id == 8 {
            context.stroke(rim, with: .color(Color(dinoHex: palette.rim)), lineWidth: 4)
            context.stroke(rim, with: .color(Color(dinoHex: palette.tabLight)), lineWidth: 1.3)
            for x in [r.minX + 16, r.maxX - 16] {
                for y in [r.minY + 17, r.maxY - 17] { rivet(at: CGPoint(x: x, y: y), radius: 2.1) }
            }
        } else if world.id == 9 {
            context.stroke(rim, with: .color(Color(dinoHex: 0x967247)), lineWidth: 4.6)
            context.stroke(rim, with: .color(Color(dinoHex: 0xEACF94)), lineWidth: 2.8)
            context.stroke(rim, with: .color(Color(dinoHex: 0xB58D58)), style: StrokeStyle(lineWidth: 2.6, dash: [1, 3]))
        } else {
            context.stroke(rim, with: .color(Color(dinoHex: 0xCDB170)), lineWidth: 4)
            context.stroke(rim, with: .color(Color(dinoHex: 0xFFF0BC)), lineWidth: 1.1)
            for x in stride(from: r.minX + 27, to: r.maxX - 22, by: 34) {
                line([CGPoint(x: x, y: r.maxY - 14), CGPoint(x: x, y: r.maxY - 4)], color: 0xA6A28B, width: 0.7)
            }
        }
    }

    private func board(in r: CGRect) {
        let shape = Path(roundedRect: r, cornerRadius: 18)
        // Recess the name surface into the continuous frame.
        context.fill(Path(roundedRect: r.insetBy(dx: -2, dy: -2), cornerRadius: 20),
                     with: .color(Color(dinoHex: palette.shade).opacity(0.28)))
        material(shape, light: palette.light, face: palette.face, dark: palette.dark)
        context.stroke(shape, with: .color(Color(dinoHex: palette.rim).opacity(0.6)), lineWidth: 1)
        context.stroke(Path(roundedRect: r.insetBy(dx: 2, dy: 2), cornerRadius: 16),
                       with: .linearGradient(Gradient(colors: [Color(dinoHex: palette.light), Color(dinoHex: palette.rim).opacity(0.5)]),
                                             startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)), lineWidth: 0.8)
        if [1, 4, 8, 9].contains(world.id) {
            for i in 0..<4 {
                var grain = Path()
                let y = r.minY + 16 + CGFloat(i) * 21
                grain.move(to: CGPoint(x: r.minX + 18, y: y))
                grain.addCurve(to: CGPoint(x: r.maxX - 18, y: y + 2),
                               control1: CGPoint(x: r.midX - 40, y: y - 6), control2: CGPoint(x: r.midX + 33, y: y + 6))
                context.stroke(grain, with: .color(Color(dinoHex: palette.rim).opacity(0.12)), lineWidth: 0.75)
            }
            for x in [r.minX + 24, r.maxX - 24] {
                context.stroke(Path(ellipseIn: CGRect(x: x - 3, y: r.maxY - 21, width: 6, height: 2)),
                               with: .color(Color(dinoHex: palette.rim).opacity(0.3)), lineWidth: 0.7)
            }
        } else if [5, 6].contains(world.id) {
            for i in 0..<3 {
                line([CGPoint(x: r.minX + 19, y: r.minY + 14 + CGFloat(i) * 3),
                      CGPoint(x: r.maxX - 25, y: r.minY + 14 + CGFloat(i) * 3)], color: 0xFFFFFF, width: 0.65, opacity: 0.20)
            }
        }
        if world.id == 9 {
            let rope = Path(roundedRect: r.insetBy(dx: 8, dy: 8), cornerRadius: 21)
            context.stroke(rope, with: .color(Color(dinoHex: 0xB78B4D)), lineWidth: 3.2)
            context.stroke(rope, with: .color(Color(dinoHex: 0xFCE3A6)), style: StrokeStyle(lineWidth: 1.5, dash: [2, 3]))
        }
        if world.id == 2 {
            context.stroke(Path(roundedRect: r.insetBy(dx: 9, dy: 9), cornerRadius: 20),
                           with: .color(Color(dinoHex: 0xF8F0DA).opacity(0.8)), style: StrokeStyle(lineWidth: 0.9, dash: [2, 4]))
        }
    }

    private func tab(in r: CGRect) {
        let inset = r.insetBy(dx: 5, dy: 3)
        let shape = Path(roundedRect: inset, cornerRadius: 8)
        material(shape, light: palette.tabLight, face: palette.tabFace, dark: palette.rim)
        context.stroke(shape, with: .color(Color(dinoHex: palette.tabLight).opacity(0.75)), lineWidth: 0.8)
        for x in [inset.minX + 5, inset.maxX - 5] { rivet(at: CGPoint(x: x, y: inset.midY), radius: 1.3) }
    }

    private func subtitle(in r: CGRect) {
        // A compact inset in the shared base leaves the side ornaments unobscured.
        let shape = Path(roundedRect: r, cornerRadius: 9)
        context.fill(Path(roundedRect: r.insetBy(dx: -1, dy: -1), cornerRadius: 10),
                     with: .color(Color(dinoHex: palette.shade).opacity(0.28)))
        material(shape, light: palette.subtitleLight, face: palette.subtitleFace, dark: palette.subtitleDark)
        context.stroke(shape, with: .linearGradient(Gradient(colors: [Color(dinoHex: palette.shade).opacity(0.55),
                                                                      Color(dinoHex: palette.subtitleLight)]),
                                                   startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)),
                       lineWidth: 0.9)
        var hem = Path()
        hem.move(to: CGPoint(x: r.minX + 9, y: r.maxY - 3))
        hem.addQuadCurve(to: CGPoint(x: r.maxX - 9, y: r.maxY - 3), control: CGPoint(x: r.midX, y: r.maxY - 2))
        context.stroke(hem, with: .color(Color(dinoHex: palette.subtitleLight).opacity(0.65)),
                       style: StrokeStyle(lineWidth: 0.6, dash: world.id == 2 ? [1.5, 3] : []))
        clock(at: CGPoint(x: r.minX + 15, y: r.midY), radius: 8, time: WorldBossClock.time(in: world.id))
        if [6, 8, 10].contains(world.id) {
            for x in [r.minX + 6, r.maxX - 6] { rivet(at: CGPoint(x: x, y: r.minY + 5), radius: 1.1) }
        }
    }

    private func endcap(front: Bool, variation: Int) {
        switch world.id {
        case 1:
            if !front {
                foliage(light: 0xB7D967, face: 0x73AB3C, dark: 0x2F683A)
                vine(from: CGPoint(x: -25, y: -43), to: CGPoint(x: -25, y: 55), color: 0x648843)
            } else {
                leaf(at: CGPoint(x: -11, y: -40), length: 29, width: 19, angle: -78, light: 0xD1E98C, face: 0x8DBD42, dark: 0x4C7D36)
                leaf(at: CGPoint(x: -14, y: 36), length: 31, width: 20, angle: -107, light: 0xAED269, face: 0x5F9B41, dark: 0x316C3A)
                blossom(at: CGPoint(x: -17, y: 53), size: 0.7, pink: false)
            }
        case 2:
            if !front {
                foliage(light: 0xCDE3CF, face: 0x94B9B5, dark: 0x557C91, count: 6)
                vine(from: CGPoint(x: -28, y: -42), to: CGPoint(x: -31, y: 49), color: 0x9AAEB8)
                moon(at: CGPoint(x: -12, y: -43), radius: 18)
                let stars: [(CGFloat, CGFloat, CGFloat)] = [(-32, -58, 3), (-35, -15, 4), (-25, 37, 3)]
                for (x, y, r) in stars {
                    star(at: CGPoint(x: x, y: y), radius: r)
                }
            } else {
                leaf(at: CGPoint(x: -15, y: 35), length: 28, width: 19, angle: -92, light: 0xD8E9DC, face: 0xA5C6C0, dark: 0x6D929F)
                for i in 0..<3 { pearl(at: CGPoint(x: -25 + CGFloat(i) * 5, y: 45 + CGFloat(i % 2) * 4), radius: 2.5) }
            }
        case 3:
            if !front {
                let rocks: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(-29, 28, 22, 73), (-9, 26, 26, 90), (-40, 40, 20, 55), (6, 35, 24, 56)]
                for (x, y, w, h) in rocks {
                    rock(at: CGPoint(x: x, y: y), width: w, height: h)
                }
                glow(at: CGPoint(x: -28, y: 28), radius: 29, color: 0xFFB26C, opacity: 0.3)
            } else {
                rock(at: CGPoint(x: -19, y: 39), width: 23, height: 36)
                for i in 0..<3 { shard(at: CGPoint(x: -33 + CGFloat(i) * 8, y: 54), width: 10, height: CGFloat(20 + i * 8), color: 0xD98E5D) }
                rivet(at: CGPoint(x: -4, y: -24), radius: 2)
            }
        case 4:
            if !front {
                foliage(light: 0xD0DF9A, face: 0x94B36C, dark: 0x50794B, count: 6)
                roof(at: CGPoint(x: -20, y: -18))
                bunting(from: CGPoint(x: -39, y: -39), to: CGPoint(x: 9, y: -44))
            } else {
                leaf(at: CGPoint(x: -13, y: 34), length: 28, width: 20, angle: -97, light: 0xC2DC86, face: 0x8CAE5D, dark: 0x5A7C42)
                for i in 0..<3 { blossom(at: CGPoint(x: -30 + CGFloat(i) * 12, y: 47 + CGFloat(i % 2) * 7), size: 0.65, pink: i == 1) }
            }
        case 5:
            if !front {
                glow(at: CGPoint(x: -21, y: -6), radius: 48, color: 0xA2F5E4, opacity: 0.32)
                for i in 0..<6 {
                    transformed(at: CGPoint(x: -26 + CGFloat(i % 3) * 14, y: 39 + CGFloat(i / 3) * 11)) { p in
                        var c = p.context; c.rotate(by: .degrees(Double(i - 2) * 7))
                        WorldBannerPainter(context: c, world: world).shard(at: .zero, width: CGFloat(16 + i % 2 * 4),
                                                                         height: CGFloat(66 + (i * 17) % 29), color: i.isMultiple(of: 2) ? 0x80C6D0 : 0xA6A3D8)
                    }
                }
            } else {
                shard(at: CGPoint(x: -25, y: 53), width: 17, height: 29, color: 0xA5DCCC)
                shard(at: CGPoint(x: -11, y: 55), width: 13, height: 22, color: 0xA9AFE0)
                star(at: CGPoint(x: -31, y: -33), radius: 4); star(at: CGPoint(x: -6, y: 25), radius: 3)
            }
        case 6:
            if !front {
                for i in 0..<3 { cityFin(at: CGPoint(x: -32 + CGFloat(i) * 15, y: 42), height: CGFloat(70 + i % 2 * 21)) }
                line([CGPoint(x: -32, y: -26), CGPoint(x: -45, y: -26), CGPoint(x: -45, y: 26),
                      CGPoint(x: -31, y: 26)], color: 0x69BDC4, width: 4)
                for y: CGFloat in [-26, 26] { pearl(at: CGPoint(x: -32, y: y), radius: 3) }
            } else {
                let r = CGRect(x: -35, y: -15, width: 19, height: 43)
                material(Path(roundedRect: r, cornerRadius: 6), light: 0xDBF5ED, face: 0x8EBDC6, dark: 0x507F93)
                for i in 0..<3 { oval(CGRect(x: -30, y: -9 + CGFloat(i) * 11, width: 8, height: 6), light: 0xE2FFF0, face: 0x90E9D7, dark: 0x4D999E) }
                for y: CGFloat in [-23, 36] { rivet(at: CGPoint(x: -12, y: y), radius: 2.6) }
                line([CGPoint(x: -29, y: 37), CGPoint(x: -16, y: 37), CGPoint(x: -16, y: 49), CGPoint(x: -5, y: 49)], color: 0x91D5CF, width: 2)
            }
        case 7:
            if !front {
                foliage(light: variation == 0 ? 0xDAE697 : 0xCCDBE6, face: variation == 0 ? 0x9DBA6C : 0x91AAC1,
                        dark: variation == 0 ? 0x587F51 : 0x506E98, count: 7)
                if variation == 0 { sun(at: CGPoint(x: -12, y: -41), radius: 17) }
                else { moon(at: CGPoint(x: -14, y: -42), radius: 18); star(at: CGPoint(x: -35, y: -11), radius: 3) }
            } else {
                leaf(at: CGPoint(x: -15, y: 38), length: 28, width: 21, angle: -97,
                     light: variation == 0 ? 0xCDD995 : 0xC3D6DF, face: variation == 0 ? 0x91AA66 : 0x819FBC,
                     dark: variation == 0 ? 0x527751 : 0x486B8D)
                for i in 0..<3 { glow(at: CGPoint(x: -29 + CGFloat(i) * 11, y: 54 + CGFloat(i % 2) * 5), radius: 5, color: 0xFFF2B3, opacity: 0.6) }
            }
        case 8:
            if !front {
                line([CGPoint(x: -21, y: -55), CGPoint(x: -21, y: 40), CGPoint(x: -38, y: 40)], color: 0x927345, width: 7)
                line([CGPoint(x: -23, y: -52), CGPoint(x: -23, y: 38)], color: 0xE8CA88, width: 1.5)
                gear(at: CGPoint(x: -23, y: -30), radius: 19)
                gear(at: CGPoint(x: -38, y: 1), radius: 13)
                gear(at: CGPoint(x: -22, y: 28), radius: 16)
                for y: CGFloat in [-49, 48] { rivet(at: CGPoint(x: -21, y: y), radius: 3) }
            } else {
                clock(at: CGPoint(x: -23, y: -30), radius: 11, time: WorldBossClock.time(in: 8))
                gear(at: CGPoint(x: -9, y: 45), radius: 10)
                for i in 0..<2 { star(at: CGPoint(x: -39 + CGFloat(i) * 25, y: -57 + CGFloat(i) * 67), radius: 3.5) }
            }
        case 9:
            if !front {
                rope(from: CGPoint(x: -20, y: -48), to: CGPoint(x: -28, y: 47))
                for i in 0..<3 {
                    var wave = Path()
                    wave.move(to: CGPoint(x: -46, y: 28 + CGFloat(i) * 10))
                    wave.addCurve(to: CGPoint(x: 3, y: 27 + CGFloat(i) * 10), control1: CGPoint(x: -27, y: 6 + CGFloat(i) * 10),
                                  control2: CGPoint(x: -17, y: 42 + CGFloat(i) * 10))
                    context.stroke(wave, with: .color(Color(dinoHex: i == 1 ? 0x8DCECA : 0x6FAEAC)),
                                   style: StrokeStyle(lineWidth: 6, lineCap: .round))
                }
                anchor(at: CGPoint(x: -23, y: -9))
            } else {
                rope(from: CGPoint(x: -35, y: 25), to: CGPoint(x: -15, y: 53))
                shell(at: CGPoint(x: -26, y: 49))
                pearl(at: CGPoint(x: -10, y: 52), radius: 3)
            }
        default:
            if !front {
                for i in 0..<2 { turret(at: CGPoint(x: -32 + CGFloat(i) * 19, y: 39), height: CGFloat(70 + i * 14)) }
                foliage(light: 0xEFDA9D, face: 0xC6AB67, dark: 0x94794F, count: 4)
            } else {
                pennant(at: CGPoint(x: -24, y: 14))
                crown(at: CGPoint(x: -24, y: -26))
                for y: CGFloat in [-40, 42] { pearl(at: CGPoint(x: -12, y: y), radius: 2.7) }
            }
        }
    }

    private func foliage(light: UInt32, face: UInt32, dark: UInt32, count: Int = 8) {
        let leaves: [(CGFloat, CGFloat, CGFloat, CGFloat, Double, Bool)] = [
            (-2, -14, 49, 26, -24, true), (-7, -8, 47, 25, -59, false),
            (-5, 9, 43, 28, -101, true), (-4, 28, 47, 27, -136, false),
            (1, 31, 43, 25, -164, true), (-16, -12, 38, 22, -40, false),
            (-15, 13, 38, 24, -108, false), (-10, 32, 37, 23, -151, false)
        ]
        for value in leaves.prefix(count) {
            leaf(at: CGPoint(x: value.0, y: value.1), length: value.2, width: value.3, angle: value.4,
                 light: value.5 ? face : light, face: value.5 ? dark : face, dark: dark)
        }
    }
    private func leaf(at point: CGPoint, length: CGFloat, width: CGFloat, angle: Double, light: UInt32, face: UInt32, dark: UInt32) {
        var layer = context; layer.translateBy(x: point.x, y: point.y); layer.rotate(by: .degrees(angle))
        let r = CGRect(x: -width / 2, y: -length, width: width, height: length)
        // Shared with the player portrait: silhouette, asymmetric fold and curved veins.
        let leaf = DinoFoliageLeaf().path(in: CGRect(origin: .zero, size: r.size)).offsetBy(dx: r.minX, dy: r.minY)
        let fold = DinoFoliageFold().path(in: CGRect(origin: .zero, size: r.size)).offsetBy(dx: r.minX, dy: r.minY)
        let veins = DinoFoliageVeins().path(in: CGRect(origin: .zero, size: r.size)).offsetBy(dx: r.minX, dy: r.minY)
        var shadow = layer; shadow.translateBy(x: 0.7, y: 1.4)
        shadow.fill(leaf, with: .color(Color(dinoHex: dark).opacity(0.25)))
        layer.fill(leaf, with: .linearGradient(Gradient(colors: [Color(dinoHex: light), Color(dinoHex: face), Color(dinoHex: dark)]),
                                             startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
        layer.fill(fold, with: .linearGradient(Gradient(colors: [.white.opacity(0.26), .clear]),
                                             startPoint: CGPoint(x: r.maxX, y: r.minY), endPoint: CGPoint(x: r.minX, y: r.maxY)))
        layer.stroke(leaf, with: .color(Color(dinoHex: light).opacity(0.55)), lineWidth: 0.7)
        layer.stroke(veins, with: .color(Color(dinoHex: light).opacity(0.75)), style: StrokeStyle(lineWidth: 0.7, lineCap: .round))
    }
    private func vine(from a: CGPoint, to b: CGPoint, color: UInt32) {
        var path = Path(); path.move(to: a)
        path.addCurve(to: b, control1: CGPoint(x: a.x - 24, y: a.y + 34), control2: CGPoint(x: b.x + 19, y: b.y - 24))
        context.stroke(path, with: .color(Color(dinoHex: color)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        context.stroke(path, with: .color(Color(dinoHex: 0xDBE4B4).opacity(0.7)), style: StrokeStyle(lineWidth: 0.65, lineCap: .round))
    }
    private func blossom(at point: CGPoint, size: CGFloat, pink: Bool) {
        for i in 0..<5 {
            let a = Double(i) * .pi * 2 / 5
            oval(CGRect(x: point.x + CGFloat(cos(a)) * 5 * size - 4 * size, y: point.y + CGFloat(sin(a)) * 5 * size - 4 * size, width: 8 * size, height: 8 * size),
                 light: 0xFFF9E7, face: pink ? 0xEFC6CB : 0xF5EFD9, dark: pink ? 0xC894A6 : 0xCFC9AC)
        }
        oval(CGRect(x: point.x - 3 * size, y: point.y - 3 * size, width: 6 * size, height: 6 * size),
             light: 0xFFF0A8, face: 0xEEC866, dark: 0xB2944A)
    }
    private func rivet(at point: CGPoint, radius: CGFloat) {
        oval(CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2),
             light: palette.tabLight, face: palette.rim, dark: palette.shade)
        line([CGPoint(x: point.x - radius * 0.4, y: point.y), CGPoint(x: point.x + radius * 0.4, y: point.y)],
             color: palette.shade, width: 0.5, opacity: 0.7)
    }
    private func pearl(at point: CGPoint, radius: CGFloat) {
        oval(CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2),
             light: 0xFFFAE2, face: 0xD6E3D9, dark: 0x819DB1)
    }
    private func star(at point: CGPoint, radius: CGFloat) {
        polygon((0..<8).map { i in
            let a = Double(i) * .pi / 4 - .pi / 2, r = i.isMultiple(of: 2) ? radius : radius * 0.3
            return CGPoint(x: point.x + CGFloat(cos(a)) * r, y: point.y + CGFloat(sin(a)) * r)
        }, light: 0xFFF9D9, face: 0xF0D394, dark: 0xC5B477)
    }
    private func moon(at point: CGPoint, radius: CGFloat) {
        glow(at: point, radius: radius * 1.6, color: 0xFDE5AF, opacity: 0.25)
        let r = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        var cut = Path(ellipseIn: r)
        cut.addEllipse(in: r.offsetBy(dx: radius * 0.48, dy: -radius * 0.28).insetBy(dx: radius * 0.08, dy: radius * 0.08))
        var moon = context; moon.clip(to: Path(ellipseIn: r)); moon.clip(to: cut, style: FillStyle(eoFill: true))
        WorldBannerPainter(context: moon, world: world).material(Path(ellipseIn: r), light: 0xFFF5CC, face: 0xE3C687, dark: 0xA89877)
        for i in 0..<3 { pearl(at: CGPoint(x: point.x - radius * 0.43 + CGFloat(i % 2) * 3, y: point.y - radius * 0.35 + CGFloat(i) * 5), radius: 1.3) }
    }
    private func sun(at point: CGPoint, radius: CGFloat) {
        glow(at: point, radius: radius * 1.7, color: 0xFFE5A6, opacity: 0.28)
        for i in 0..<12 {
            let a = Double(i) * .pi / 6
            line([CGPoint(x: point.x + CGFloat(cos(a)) * (radius + 3), y: point.y + CGFloat(sin(a)) * (radius + 3)),
                  CGPoint(x: point.x + CGFloat(cos(a)) * (radius + 7), y: point.y + CGFloat(sin(a)) * (radius + 7))],
                 color: 0xE6C278, width: 1.8)
        }
        oval(CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2),
             light: 0xFFF3B6, face: 0xE8C875, dark: 0xB49D60)
        context.stroke(Path(ellipseIn: CGRect(x: point.x - radius + 3, y: point.y - radius + 3, width: radius * 2 - 6, height: radius * 2 - 6)),
                       with: .color(Color(dinoHex: 0xFFF2C3).opacity(0.7)), lineWidth: 1)
    }
    private func rock(at point: CGPoint, width: CGFloat, height: CGFloat) {
        let pts = [CGPoint(x: point.x - width / 2, y: point.y), CGPoint(x: point.x - width * 0.62, y: point.y - height * 0.53),
                   CGPoint(x: point.x - width * 0.25, y: point.y - height), CGPoint(x: point.x + width * 0.26, y: point.y - height * 0.91),
                   CGPoint(x: point.x + width * 0.53, y: point.y - height * 0.24), CGPoint(x: point.x + width / 2, y: point.y)]
        polygon(pts, light: 0xB7A59E, face: 0x817780, dark: 0x575A6C)
        polygon([pts[2], CGPoint(x: point.x - 1, y: point.y - height * 0.41), pts[0], pts[1]], light: 0xB5A49E, face: 0x9A8B8E, dark: 0x767280)
        let lava = [CGPoint(x: point.x - 2, y: point.y - height * 0.84), CGPoint(x: point.x - 5, y: point.y - height * 0.55),
                    CGPoint(x: point.x + 2, y: point.y - height * 0.38), CGPoint(x: point.x - 1, y: point.y - height * 0.1)]
        line(lava, color: 0xD7815A, width: 4); line(lava, color: 0xFFD294, width: 1.7)
    }
    private func shard(at point: CGPoint, width: CGFloat, height: CGFloat, color: UInt32) {
        let top = CGPoint(x: point.x + width * 0.13, y: point.y - height)
        let left = CGPoint(x: point.x - width * 0.48, y: point.y - height * 0.78)
        let right = CGPoint(x: point.x + width * 0.48, y: point.y - height * 0.79)
        polygon([CGPoint(x: point.x - width / 2, y: point.y), left, top, right, CGPoint(x: point.x + width / 2, y: point.y)],
                light: 0xE7FFF0, face: color, dark: 0x5D7CA2)
        polygon([left, top, CGPoint(x: point.x + 1, y: point.y - 2), CGPoint(x: point.x - width / 2, y: point.y)],
                light: 0xEEFFF1, face: color, dark: 0x9ABECF)
        line([top, CGPoint(x: point.x + 1, y: point.y - 3)], color: 0xEFFFF1, width: 0.8, opacity: 0.9)
        line([left, right], color: 0xD8FAE9, width: 0.6, opacity: 0.7)
    }
    private func roof(at point: CGPoint) {
        material(Path(roundedRect: CGRect(x: point.x - 11, y: point.y, width: 25, height: 35), cornerRadius: 4),
                 light: 0xF6E2B7, face: 0xD8C093, dark: 0xAB986D)
        polygon([CGPoint(x: point.x - 18, y: point.y + 2), CGPoint(x: point.x, y: point.y - 19), CGPoint(x: point.x + 19, y: point.y + 2)],
                light: 0xEFBF9E, face: 0xBF866A, dark: 0x8B6957)
        line([CGPoint(x: point.x - 15, y: point.y + 2), CGPoint(x: point.x, y: point.y - 14), CGPoint(x: point.x + 16, y: point.y + 2)],
             color: 0xF5DCAC, width: 1.3)
        material(Path(roundedRect: CGRect(x: point.x - 4, y: point.y + 7, width: 9, height: 12), cornerRadius: 2),
                 light: 0xE2EDDC, face: 0xA7C9C7, dark: 0x6E9B9A)
        line([CGPoint(x: point.x, y: point.y + 8), CGPoint(x: point.x, y: point.y + 18)], color: 0xF7E4BC, width: 1)
        line([CGPoint(x: point.x - 4, y: point.y + 13), CGPoint(x: point.x + 4, y: point.y + 13)], color: 0xF7E4BC, width: 1)
    }
    private func bunting(from a: CGPoint, to b: CGPoint) {
        var cord = Path(); cord.move(to: a); cord.addQuadCurve(to: b, control: CGPoint(x: (a.x + b.x) / 2, y: a.y + 13))
        context.stroke(cord, with: .color(Color(dinoHex: 0x8D805C)), lineWidth: 1)
        for i in 0..<4 {
            let x = a.x + 8 + CGFloat(i) * 11, y = a.y + 3 + CGFloat(i % 2) * 3
            polygon([CGPoint(x: x - 4, y: y), CGPoint(x: x + 5, y: y + 1), CGPoint(x: x + 1, y: y + 12)],
                    light: 0xF8E9C6, face: i.isMultiple(of: 2) ? 0xDBA283 : 0x82B6A5, dark: 0x8B8268)
            line([CGPoint(x: x, y: y + 2), CGPoint(x: x + 1, y: y + 9)], color: 0xFAEBD1, width: 0.55)
        }
    }
    private func cityFin(at point: CGPoint, height: CGFloat) {
        let r = CGRect(x: point.x - 8, y: point.y - height, width: 16, height: height)
        material(Path(roundedRect: r, cornerRadius: 4), light: 0xD9F2EA, face: 0x87B7C4, dark: 0x547A96)
        line([CGPoint(x: r.minX + 3, y: r.maxY - 4), CGPoint(x: r.minX + 3, y: r.minY + 5)], color: 0xD6F6E8, width: 1.2)
        for i in 0..<4 { line([CGPoint(x: r.minX + 7, y: r.minY + 11 + CGFloat(i) * 11), CGPoint(x: r.maxX - 3, y: r.minY + 11 + CGFloat(i) * 11)], color: 0xAAF2D9, width: 2.3) }
        rivet(at: CGPoint(x: point.x, y: r.maxY - 7), radius: 2)
    }
    private func gear(at point: CGPoint, radius: CGFloat) {
        let pts = (0..<48).map { i -> CGPoint in
            let a = Double(i) * .pi / 24, r = i % 4 < 2 ? radius : radius * 0.78
            return CGPoint(x: point.x + CGFloat(cos(a)) * r, y: point.y + CGFloat(sin(a)) * r)
        }
        polygon(pts.map { CGPoint(x: $0.x, y: $0.y + 2) }, light: 0xBFA368, face: 0xA88C58, dark: 0x716C55)
        polygon(pts, light: 0xFFE8AA, face: 0xD9B76C, dark: 0xA08E5B)
        context.stroke(Path(ellipseIn: CGRect(x: point.x - radius * 0.6, y: point.y - radius * 0.6, width: radius * 1.2, height: radius * 1.2)),
                       with: .color(Color(dinoHex: 0xF9E0A2)), lineWidth: 1.3)
        oval(CGRect(x: point.x - radius * 0.4, y: point.y - radius * 0.4, width: radius * 0.8, height: radius * 0.8),
             light: 0xDCD8B4, face: 0xA8B4A9, dark: 0x697F85)
        rivet(at: point, radius: 2.4)
    }
    private func clock(at point: CGPoint, radius: CGFloat, time: ClockTime) {
        oval(CGRect(x: point.x - radius - 2, y: point.y - radius - 2, width: radius * 2 + 4, height: radius * 2 + 4),
             light: palette.tabLight, face: palette.rim, dark: palette.shade)
        oval(CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2),
             light: 0xFFFEEC, face: 0xF0EACD, dark: 0xD2CFAF)
        for i in 0..<12 {
            let a = Double(i) * .pi / 6
            line([CGPoint(x: point.x + CGFloat(sin(a)) * radius * 0.79, y: point.y - CGFloat(cos(a)) * radius * 0.79),
                  CGPoint(x: point.x + CGFloat(sin(a)) * radius * 0.9, y: point.y - CGFloat(cos(a)) * radius * 0.9)],
                 color: 0x537B7F, width: i.isMultiple(of: 3) ? 0.9 : 0.5)
        }
        for (angle, reach, weight) in [(Double(time.hour % 12) * .pi / 6 + Double(time.minute) * .pi / 360, CGFloat(0.48), CGFloat(1.2)),
                                       (Double(time.minute) * .pi / 30, CGFloat(0.68), CGFloat(0.9))] {
            line([point, CGPoint(x: point.x + CGFloat(sin(angle)) * radius * reach, y: point.y - CGFloat(cos(angle)) * radius * reach)],
                 color: 0x345E6B, width: weight)
        }
        pearl(at: point, radius: 1.1)
    }
    private func rope(from a: CGPoint, to b: CGPoint) {
        var path = Path(); path.move(to: a)
        path.addCurve(to: b, control1: CGPoint(x: a.x - 22, y: a.y + 22), control2: CGPoint(x: b.x + 17, y: b.y - 18))
        context.stroke(path, with: .color(Color(dinoHex: 0x9D7B4F)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
        context.stroke(path, with: .color(Color(dinoHex: 0xE6CC95)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        context.stroke(path, with: .color(Color(dinoHex: 0xB19465)), style: StrokeStyle(lineWidth: 4, dash: [1.2, 3]))
        context.stroke(path, with: .color(Color(dinoHex: 0xFFF0BA).opacity(0.75)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
    }
    private func anchor(at point: CGPoint) {
        var path = Path()
        path.move(to: CGPoint(x: point.x, y: point.y - 27)); path.addLine(to: CGPoint(x: point.x, y: point.y + 23))
        path.move(to: CGPoint(x: point.x - 12, y: point.y - 7)); path.addLine(to: CGPoint(x: point.x + 12, y: point.y - 7))
        path.move(to: CGPoint(x: point.x - 17, y: point.y + 7))
        path.addCurve(to: CGPoint(x: point.x + 17, y: point.y + 7), control1: CGPoint(x: point.x - 16, y: point.y + 30), control2: CGPoint(x: point.x + 16, y: point.y + 30))
        context.stroke(path, with: .color(Color(dinoHex: 0x4B757D)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
        context.stroke(path, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xB4D6C5), Color(dinoHex: 0x77A7A4)]), startPoint: CGPoint(x: point.x - 15, y: point.y - 30),
                                                 endPoint: CGPoint(x: point.x + 15, y: point.y + 30)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        context.stroke(Path(ellipseIn: CGRect(x: point.x - 5, y: point.y - 38, width: 10, height: 10)),
                       with: .color(Color(dinoHex: 0x7EA9A6)), lineWidth: 3)
        for side: CGFloat in [-1, 1] { polygon([CGPoint(x: point.x + side * 18, y: point.y + 5), CGPoint(x: point.x + side * 11, y: point.y + 10),
                                              CGPoint(x: point.x + side * 19, y: point.y + 14)], light: 0xD3E5D2, face: 0x8DB3AB, dark: 0x597D80) }
    }
    private func shell(at point: CGPoint) {
        var path = Path(); path.move(to: CGPoint(x: point.x, y: point.y + 7))
        path.addCurve(to: CGPoint(x: point.x - 12, y: point.y - 8), control1: CGPoint(x: point.x - 9, y: point.y + 3), control2: CGPoint(x: point.x - 15, y: point.y - 4))
        path.addQuadCurve(to: CGPoint(x: point.x + 12, y: point.y - 8), control: CGPoint(x: point.x, y: point.y - 20))
        path.addCurve(to: CGPoint(x: point.x, y: point.y + 7), control1: CGPoint(x: point.x + 15, y: point.y - 4), control2: CGPoint(x: point.x + 9, y: point.y + 3))
        path.closeSubpath(); material(path, light: 0xFFF1D8, face: 0xE6C6A8, dark: 0xBA9781)
        for i in -2...2 { line([CGPoint(x: point.x, y: point.y + 5), CGPoint(x: point.x + CGFloat(i) * 4, y: point.y - 9 + CGFloat(abs(i)) * 2)],
                              color: 0xFFF0D6, width: 0.8) }
    }
    private func turret(at point: CGPoint, height: CGFloat) {
        let r = CGRect(x: point.x - 9, y: point.y - height, width: 18, height: height)
        material(Path(roundedRect: r, cornerRadius: 4), light: 0xF7EACD, face: 0xD8CCAD, dark: 0xA9AA96)
        for i in 1..<5 {
            let y = r.minY + CGFloat(i) * height / 5
            line([CGPoint(x: r.minX + 1, y: y), CGPoint(x: r.maxX - 1, y: y)], color: 0xA7A792, width: 0.65)
            line([CGPoint(x: point.x + CGFloat(i % 2) * 4 - 2, y: y), CGPoint(x: point.x + CGFloat(i % 2) * 4 - 2, y: y + height / 5)], color: 0xB8B39B, width: 0.6)
        }
        for i in 0..<3 {
            material(Path(roundedRect: CGRect(x: r.minX - 2 + CGFloat(i) * 7, y: r.minY - 6, width: 6, height: 12), cornerRadius: 1.5),
                     light: 0xFFF0D2, face: 0xDFD3B3, dark: 0xBAB399)
        }
        rivet(at: CGPoint(x: point.x, y: r.minY + 18), radius: 2)
    }
    private func pennant(at point: CGPoint) {
        polygon([CGPoint(x: point.x - 13, y: point.y - 27), CGPoint(x: point.x + 12, y: point.y - 27), CGPoint(x: point.x + 10, y: point.y + 36),
                 CGPoint(x: point.x, y: point.y + 26), CGPoint(x: point.x - 12, y: point.y + 36)],
                light: 0xAEC5E1, face: 0x6A89B8, dark: 0x3E5885)
        line([CGPoint(x: point.x - 10, y: point.y - 24), CGPoint(x: point.x - 10, y: point.y + 31)], color: 0xEBD397, width: 1)
        line([CGPoint(x: point.x + 8, y: point.y - 24), CGPoint(x: point.x + 7, y: point.y + 31)], color: 0xEBD397, width: 1)
        polygon([CGPoint(x: point.x, y: point.y - 12), CGPoint(x: point.x + 4, y: point.y - 4), CGPoint(x: point.x, y: point.y + 4),
                 CGPoint(x: point.x - 4, y: point.y - 4)], light: 0xFBE6B3, face: 0xD4B675, dark: 0xA38B5C)
        line([CGPoint(x: point.x + 1, y: point.y + 10), CGPoint(x: point.x + 3, y: point.y + 24)], color: 0xBDD1E8, width: 1, opacity: 0.5)
    }
    private func crown(at point: CGPoint) {
        polygon([CGPoint(x: point.x - 13, y: point.y + 7), CGPoint(x: point.x - 15, y: point.y - 14), CGPoint(x: point.x - 7, y: point.y - 6),
                 CGPoint(x: point.x, y: point.y - 20), CGPoint(x: point.x + 7, y: point.y - 6), CGPoint(x: point.x + 15, y: point.y - 14),
                 CGPoint(x: point.x + 13, y: point.y + 7)], light: 0xFFF0B6, face: 0xDBBC74, dark: 0xAD9358)
        line([CGPoint(x: point.x - 12, y: point.y + 4), CGPoint(x: point.x + 12, y: point.y + 4)], color: 0xFFEDAE, width: 2)
        for x: CGFloat in [-7, 0, 7] { oval(CGRect(x: point.x + x - 2, y: point.y - 2, width: 4, height: 5), light: 0xCBF3D3, face: 0x77B6AF, dark: 0x4E817E) }
    }
}

// Shared foliage geometry keeps the banners and HUD portrait in one art style.
struct DinoFoliageFold: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.width * 0.66, y: 0),
                              control: CGPoint(x: rect.width * 0.43, y: rect.height * 0.42))
            path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                          control1: CGPoint(x: rect.width * 1.18, y: rect.height * 0.35),
                          control2: CGPoint(x: rect.width * 0.93, y: rect.height * 0.73))
            path.closeSubpath()
        }
    }
}

struct DinoFoliageVeins: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: rect.width * x, y: rect.height * y)
            }
            path.move(to: point(0.5, 0.97))
            path.addQuadCurve(to: point(0.66, 0.06), control: point(0.43, 0.42))
            for (center, left, right) in [(0.72, 0.58, 0.57), (0.52, 0.39, 0.38), (0.32, 0.23, 0.23)] {
                path.move(to: point(0.51, center))
                path.addQuadCurve(to: point(0.19, left), control: point(0.31, center - 0.025))
                path.move(to: point(0.54, center))
                path.addQuadCurve(to: point(0.85, right), control: point(0.72, center - 0.015))
            }
        }
    }
}

struct DinoFoliageLeaf: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addCurve(to: CGPoint(x: rect.width * 0.66, y: 0),
                          control1: CGPoint(x: -rect.width * 0.28, y: rect.height * 0.62),
                          control2: CGPoint(x: rect.width * 0.14, y: rect.height * 0.08))
            path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                          control1: CGPoint(x: rect.width * 1.18, y: rect.height * 0.35),
                          control2: CGPoint(x: rect.width * 0.93, y: rect.height * 0.73))
            path.closeSubpath()
        }
    }
}


/// Each ten-level section can supply its own palette. The last part blends into
/// the next section's palette, so adjoining worlds share the same horizon.
struct WorldLandscapePalette {
    var ground: UInt32
    var distant: UInt32
    var foliage: UInt32
    var shade: UInt32
    var rock: UInt32

    static let jungle = Self(ground: 0xDDEEB6, distant: 0xABCFA0, foliage: 0x6FAE52,
                             shade: 0x2E7356, rock: 0x96AB7B)
    static let nextHorizon = Self(ground: 0xDCD6F7, distant: 0xB2B4D7, foliage: 0x9CCBB8,
                                  shade: 0x596A99, rock: 0xA9A5BE)

    func color(_ key: KeyPath<Self, UInt32>, toward next: Self, progress: CGFloat) -> Color {
        let a = self[keyPath: key], b = next[keyPath: key]
        let t = Double(min(1, max(0, progress)))
        func channel(_ shift: UInt32) -> Double {
            let start = Double((a >> shift) & 255), end = Double((b >> shift) & 255)
            return (start + (end - start) * t) / 255
        }
        return Color(red: channel(16), green: channel(8), blue: channel(0))
    }
}

/// All landscape artwork is drawn from paths, ellipses and rounded rectangles.
/// One static canvas keeps the long scrolling map inexpensive to render.
struct WorldMapLandscape: View {
    var palette = WorldLandscapePalette.jungle
    var nextPalette = WorldLandscapePalette.nextHorizon
    var routeOffset: CGFloat = 0

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let left = max(0, (w - 650) / 2)
            let right = w - left
            let height = size.height - routeOffset
            let scale = min(1.35, max(0.82, w / 390))
            let skyEnd = min(0.32, max(0.08, (routeOffset + 210) / size.height))
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                Gradient(stops: [
                    .init(color: Color(dinoHex: 0x98DFF1), location: 0),
                    .init(color: Color(dinoHex: 0xC6EDF0), location: skyEnd * 0.47),
                    .init(color: Color(dinoHex: 0xE7F1BD), location: skyEnd),
                    .init(color: Color(dinoHex: palette.ground), location: 0.45),
                    .init(color: Color(dinoHex: 0xD4E6AD), location: 0.72),
                    .init(color: Color(dinoHex: nextPalette.ground), location: 1)
                ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))

            let sky = JunglePainter(context: context)
            sky.entrance(width: w, left: left, right: right, height: max(350, routeOffset), scale: scale)
            sky.bush(at: CGPoint(x: left - 12, y: 64), size: 0.85)
            sky.bush(at: CGPoint(x: right + 18, y: 85), size: 1.0)
            sky.vine(from: CGPoint(x: left + 13, y: 0), length: 122, bend: 20)
            sky.vine(from: CGPoint(x: right - 16, y: 0), length: 94, bend: -20)
            var routeContext = context
            routeContext.translateBy(x: 0, y: routeOffset)
            let painter = JunglePainter(context: routeContext)

            // Rolling clearings alternate sides of the trail instead of repeating
            // a decorative wallpaper behind every level.
            for index in 0..<7 {
                let y = CGFloat(index) * 310 - 80
                let blend = transition(at: y, height: height)
                let left = index.isMultiple(of: 2)
                let distant = palette.color(\.distant, toward: nextPalette, progress: blend)
                let foliage = palette.color(\.foliage, toward: nextPalette, progress: blend)
                painter.hill(x: left ? -w * 0.3 : w * 0.44, y: y, width: w * 0.95,
                             height: 290, color: distant.opacity(0.45))
                painter.hill(x: left ? w * 0.6 : -w * 0.52, y: y + 115, width: w * 0.92,
                             height: 230, color: foliage.opacity(0.17))
                // Small grasses and stone clusters sit inside the clearing.
                for tuft in 0..<5 {
                    let x = w * (CGFloat(tuft) * 0.20 + 0.035)
                    painter.grass(at: CGPoint(x: x, y: y + 210 + CGFloat(tuft % 2) * 32),
                                  size: 9 * scale, color: foliage.opacity(0.5))
                }
            }

            // Tall trees, layered crowns and hanging vines frame the entrance.
            painter.tree(at: CGPoint(x: left - 6, y: 305), size: 1.18 * scale, leaning: 1)
            painter.tree(at: CGPoint(x: right + 14, y: 370), size: 1.30 * scale, leaning: -1)
            painter.vine(from: CGPoint(x: left + 30, y: 0), length: 160, bend: 28)
            painter.vine(from: CGPoint(x: right - 28, y: 10), length: 190, bend: -32)
            painter.bush(at: CGPoint(x: left + 5, y: 320), size: 1.0 * scale)
            painter.fern(at: CGPoint(x: right - 15, y: 450), size: 0.9 * scale, flipped: true)
            painter.flowers(at: CGPoint(x: left + 38, y: 405), size: scale)

            // A rocky waterfall and a lagoon make the middle of the world a
            // distinct destination. Water stays at the edge of the playable path.
            painter.waterfall(at: CGPoint(x: right - 35 * scale, y: 525), size: scale)
            painter.palm(at: CGPoint(x: left + 13, y: 785), size: 0.96 * scale, flipped: false)
            painter.fern(at: CGPoint(x: left + 8, y: 885), size: 1.13 * scale, flipped: false)
            painter.flowers(at: CGPoint(x: right - 42, y: 965), size: 0.9 * scale)

            // Deeper jungle: buttress roots, large leaves, mossy boulders.
            painter.tree(at: CGPoint(x: left - 25, y: 1250), size: 1.02 * scale, leaning: 1)
            painter.palm(at: CGPoint(x: right + 4, y: 1370), size: 1.05 * scale, flipped: true)
            painter.rocks(at: CGPoint(x: right - 25, y: 1382), size: 0.92 * scale)
            painter.bush(at: CGPoint(x: left + 15, y: 1320), size: 1.05 * scale)
            painter.fern(at: CGPoint(x: right - 8, y: 1470), size: 1.2 * scale, flipped: true)
            painter.flowers(at: CGPoint(x: left + 40, y: 1475), size: scale)
            painter.rocks(at: CGPoint(x: left + 14, y: 1635), size: 1.15 * scale)
            painter.bush(at: CGPoint(x: right - 6, y: 1720), size: 0.8 * scale)

            // The boss clearing opens into mist. Low silhouettes and the soft
            // color blend continue below level ten into the next world preview.
            for i in 0..<3 {
                let y = height - 390 + CGFloat(i) * 105
                painter.hill(x: i.isMultiple(of: 2) ? -w * 0.28 : w * 0.5,
                             y: y, width: w * 0.82, height: 195,
                             color: palette.color(\.distant, toward: nextPalette, progress: CGFloat(i + 1) / 3).opacity(0.44))
            }
            painter.rocks(at: CGPoint(x: left + 29, y: 1910), size: scale * 0.9)
            painter.fern(at: CGPoint(x: left + 45, y: 1916), size: scale * 0.45, flipped: false)
            painter.rocks(at: CGPoint(x: right - 28, y: 1940), size: scale * 0.8)
            painter.fern(at: CGPoint(x: right - 43, y: 1945), size: scale * 0.40, flipped: true)
            // The jungle has its own guardian, just like every later chapter.
            let bossPoint = CGPoint(x: right - 79 * scale, y: 1857)
            let bossScene = ThemePainter(context: routeContext, colors: WorldThemeColors(DinoWorldCatalog.world(1)!))
            context.fill(Path(CGRect(x: 0, y: size.height - 240, width: w, height: 240)),
                         with: .linearGradient(Gradient(colors: [Color(dinoHex: nextPalette.ground).opacity(0),
                                                                 Color(dinoHex: nextPalette.ground)]),
                                               startPoint: CGPoint(x: 0, y: size.height - 240),
                                               endPoint: CGPoint(x: 0, y: size.height)))
            bossScene.bossClearing(worldID: 1, at: bossPoint, size: scale)
            bossScene.boss(worldID: 1, at: bossPoint, size: scale * 0.88)
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }

    private func transition(at y: CGFloat, height: CGFloat) -> CGFloat {
        let t = min(1, max(0, (y - (height - 560)) / 560))
        return t * t * (3 - 2 * t)
    }
}

/// Lightweight, shape-only distant scenery for headings and quieter game screens.
struct JungleVista: View {
    var quiet = false
    var body: some View {
        Canvas { context, size in
            let p = JunglePainter(context: context)
            let w = size.width, h = size.height
            p.ellipse(CGRect(x: w * 0.61, y: 40, width: 115, height: 115), color: Color(dinoHex: 0xFFF5C9).opacity(quiet ? 0.3 : 0.8))
            for i in 0..<3 {
                p.hill(x: i.isMultiple(of: 2) ? -w * 0.4 : w * 0.30,
                       y: h * 0.48 + CGFloat(i) * 65, width: w * 1.1, height: h * 0.65,
                       color: Color(dinoHex: i == 0 ? 0xB6D7AD : 0x9FCB97).opacity(quiet ? 0.10 : 0.34))
            }
            if !quiet {
                p.bush(at: CGPoint(x: -14, y: 110), size: 1.2)
                p.bush(at: CGPoint(x: w + 19, y: 155), size: 1.3)
                p.vine(from: CGPoint(x: w * 0.06, y: 0), length: 175, bend: 20)
                p.vine(from: CGPoint(x: w * 0.94, y: 0), length: 110, bend: -16)
            } else {
                p.fern(at: CGPoint(x: -28, y: h + 24), size: 1.3, flipped: false, opacity: 0.12)
                p.fern(at: CGPoint(x: w + 28, y: h + 24), size: 1.3, flipped: true, opacity: 0.12)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct JunglePainter {
    let context: GraphicsContext
    private let dark = Color(dinoHex: 0x2E7356)
    private let green = Color(dinoHex: 0x6FAE52)
    private let light = Color(dinoHex: 0xA4CD68)

    func ellipse(_ rect: CGRect, color: Color) { context.fill(Path(ellipseIn: rect), with: .color(color)) }

    func entrance(width: CGFloat, left: CGFloat, right: CGFloat, height: CGFloat, scale: CGFloat) {
        let sun = CGPoint(x: width * 0.76, y: height * 0.29)
        context.fill(Path(ellipseIn: CGRect(x: sun.x - 160, y: sun.y - 160, width: 320, height: 320)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: 0xFFF8CF).opacity(0.95), Color(dinoHex: 0xFFF8CF).opacity(0)]),
                                           center: sun, startRadius: 15, endRadius: 160))
        ellipse(CGRect(x: sun.x - 24, y: sun.y - 24, width: 48, height: 48), color: Color(dinoHex: 0xFFFBE3).opacity(0.85))
        // Soft, layered cloud banks keep the sky continuous behind the fixed HUD.
        context.drawLayer { cloud in
            cloud.addFilter(.blur(radius: 3))
            for (x, y, s) in [(width * 0.22, height * 0.19, CGFloat(1)),
                              (width * 0.63, height * 0.43, CGFloat(0.78)),
                              (width * 0.08, height * 0.56, CGFloat(0.64))] {
                for i in 0..<4 {
                    let r = CGRect(x: x + CGFloat(i - 2) * 22 * s, y: y - CGFloat(i % 2) * 11 * s,
                                   width: 64 * s, height: 26 * s)
                    cloud.fill(Path(ellipseIn: r), with: .color(.white.opacity(0.52)))
                }
            }
        }
        hill(x: -width * 0.43, y: height * 0.46, width: width * 0.92, height: 280 * scale,
             color: Color(dinoHex: 0x8ABDB0).opacity(0.35))
        hill(x: width * 0.56, y: height * 0.42, width: width * 0.83, height: 330 * scale,
             color: Color(dinoHex: 0x86B9AD).opacity(0.3))
        // Distant falls sit behind the sign; the near fall continues beside level one.
        var distant = context
        distant.opacity = 0.53
        let backdrop = JunglePainter(context: distant)
        backdrop.waterfall(at: CGPoint(x: right - 12 * scale, y: height * 0.82), size: scale * 0.83)
        backdrop.waterfall(at: CGPoint(x: left - 10 * scale, y: height * 0.70), size: scale * 0.58)
        context.drawLayer { light in
            light.addFilter(.blur(radius: 12))
            for i in 0..<3 {
                var ray = Path()
                let x = sun.x + CGFloat(i - 1) * 28
                ray.addLines([CGPoint(x: x, y: sun.y - 10), CGPoint(x: x + 14, y: sun.y),
                              CGPoint(x: x - 70 + CGFloat(i) * 25, y: height + 420),
                              CGPoint(x: x - 165 + CGFloat(i) * 24, y: height + 420)])
                ray.closeSubpath()
                light.fill(ray, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFF9DB).opacity(0.26), Color(dinoHex: 0xFFF9DB).opacity(0)]),
                                                      startPoint: sun, endPoint: CGPoint(x: sun.x - 100, y: height + 420)))
            }
        }
        for side: CGFloat in [-1, 1] {
            let x = side < 0 ? left + 8 : right - 8
            for i in 0..<4 {
                leaf(at: CGPoint(x: x, y: 10 + CGFloat(i) * 42), length: CGFloat(50 - i * 5) * scale,
                     width: 13 * scale, angle: Double(side) * Double(40 + i * 18),
                     color: i.isMultiple(of: 2) ? green : dark)
            }
        }
    }

    func hill(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: Color) {
        var path = Path()
        path.move(to: CGPoint(x: x, y: y + height * 0.65))
        path.addCurve(to: CGPoint(x: x + width * 0.50, y: y + height * 0.07),
                      control1: CGPoint(x: x + width * 0.07, y: y + height * 0.07),
                      control2: CGPoint(x: x + width * 0.30, y: y - height * 0.08))
        path.addCurve(to: CGPoint(x: x + width, y: y + height * 0.65),
                      control1: CGPoint(x: x + width * 0.85, y: y + height * 0.12),
                      control2: CGPoint(x: x + width * 1.09, y: y + height * 0.35))
        path.addCurve(to: CGPoint(x: x + width * 0.52, y: y + height),
                      control1: CGPoint(x: x + width * 0.90, y: y + height * 1.10),
                      control2: CGPoint(x: x + width * 0.70, y: y + height))
        path.addCurve(to: CGPoint(x: x, y: y + height * 0.65),
                      control1: CGPoint(x: x + width * 0.22, y: y + height * 1.02),
                      control2: CGPoint(x: x - width * 0.10, y: y + height * 0.95))
        path.closeSubpath()
        context.fill(path, with: .color(color))
    }

    func leaf(at point: CGPoint, length: CGFloat, width: CGFloat, angle: Double, color: Color, vein: Bool = true) {
        var c = context
        c.translateBy(x: point.x, y: point.y)
        c.rotate(by: .degrees(angle))
        var leaf = Path()
        leaf.move(to: .zero)
        leaf.addCurve(to: CGPoint(x: 0, y: -length), control1: CGPoint(x: -width, y: -length * 0.32),
                      control2: CGPoint(x: -width * 0.58, y: -length * 0.89))
        leaf.addCurve(to: .zero, control1: CGPoint(x: width * 0.66, y: -length * 0.83),
                      control2: CGPoint(x: width, y: -length * 0.24))
        c.fill(leaf, with: .color(color))
        if vein {
            var line = Path()
            line.move(to: .zero)
            line.addQuadCurve(to: CGPoint(x: 0, y: -length * 0.84), control: CGPoint(x: width * 0.1, y: -length * 0.45))
            c.stroke(line, with: .color(.white.opacity(0.20)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        }
    }

    /// Scalloped, asymmetrical foliage silhouettes instead of rows of circles.
    func foliagePath(in r: CGRect) -> Path {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height)
        }
        return Path { p in
            p.move(to: pt(0.07, 0.69))
            p.addCurve(to: pt(0.05, 0.35), control1: pt(-0.04, 0.60), control2: pt(-0.03, 0.40))
            p.addCurve(to: pt(0.27, 0.16), control1: pt(0.02, 0.19), control2: pt(0.15, 0.10))
            p.addCurve(to: pt(0.56, 0.07), control1: pt(0.32, -0.02), control2: pt(0.48, -0.06))
            p.addCurve(to: pt(0.80, 0.19), control1: pt(0.62, -0.01), control2: pt(0.79, 0.01))
            p.addCurve(to: pt(0.96, 0.48), control1: pt(0.97, 0.16), control2: pt(1.05, 0.34))
            p.addCurve(to: pt(0.92, 0.80), control1: pt(1.05, 0.60), control2: pt(1.00, 0.75))
            p.addCurve(to: pt(0.62, 0.93), control1: pt(0.88, 0.98), control2: pt(0.73, 1.03))
            p.addCurve(to: pt(0.31, 0.91), control1: pt(0.50, 1.04), control2: pt(0.36, 1.00))
            p.addCurve(to: pt(0.07, 0.69), control1: pt(0.10, 1.00), control2: pt(0.02, 0.87))
            p.closeSubpath()
        }
    }

    private func foliage(in r: CGRect, color: Color, highlights: Bool = true) {
        context.fill(foliagePath(in: r), with: .color(color))
        if highlights {
            // Small leaf pairs belong to the crown, rather than separate blobs.
            for i in 0..<3 {
                let at = CGPoint(x: r.minX + r.width * (0.27 + CGFloat(i) * 0.21),
                                 y: r.minY + r.height * (0.30 + CGFloat(i % 2) * 0.13))
                leaf(at: at, length: r.width * 0.095, width: r.width * 0.033,
                     angle: Double(-40 + i * 25), color: light.opacity(0.35), vein: false)
                leaf(at: at, length: r.width * 0.075, width: r.width * 0.025,
                     angle: Double(45 + i * 18), color: light.opacity(0.24), vein: false)
            }
        }
    }

    func bush(at point: CGPoint, size: CGFloat) {
        ellipse(CGRect(x: point.x - 58 * size, y: point.y - 5 * size, width: 116 * size, height: 17 * size), color: dark.opacity(0.10))
        foliage(in: CGRect(x: point.x - 57 * size, y: point.y - 46 * size, width: 79 * size, height: 47 * size), color: dark)
        foliage(in: CGRect(x: point.x - 9 * size, y: point.y - 62 * size, width: 67 * size, height: 60 * size), color: Color(dinoHex: 0x4F905B))
        foliage(in: CGRect(x: point.x - 36 * size, y: point.y - 47 * size, width: 75 * size, height: 50 * size), color: green)
        for i in 0..<3 {
            leaf(at: CGPoint(x: point.x + CGFloat(i - 1) * 19 * size, y: point.y - 6 * size),
                 length: CGFloat(25 + i * 4) * size, width: 8 * size,
                 angle: Double(i * 38 - 45), color: light.opacity(0.65))
        }
    }

    func fern(at point: CGPoint, size: CGFloat, flipped: Bool, opacity: Double = 1) {
        var c = context
        c.opacity = opacity
        let p = JunglePainter(context: c)
        let direction: CGFloat = flipped ? -1 : 1
        for frond in 0..<5 {
            let reach = CGFloat(frond - 2) * 30 * size * direction
            let height = CGFloat(88 - abs(frond - 2) * 20) * size
            var stem = Path()
            stem.move(to: point)
            stem.addQuadCurve(to: CGPoint(x: point.x + reach, y: point.y - height),
                              control: CGPoint(x: point.x, y: point.y - height))
            c.stroke(stem, with: .color(dark), style: StrokeStyle(lineWidth: 1.4 * size, lineCap: .round))
            for pair in 1...7 {
                let t = CGFloat(pair) / 8
                let origin = CGPoint(x: point.x + reach * t * t, y: point.y - height * (2 * t - t * t))
                let angle = atan2(2 * reach * t, 2 * height * (1 - t)) * 180 / .pi
                for side in [-1.0, 1.0] {
                    p.leaf(at: origin, length: (18 - t * 12) * size, width: (4.2 - t * 2) * size,
                           angle: Double(angle) + side * 61,
                           color: frond.isMultiple(of: 2) ? dark : green, vein: false)
                }
            }
        }
    }

    func tree(at base: CGPoint, size: CGFloat, leaning: CGFloat) {
        let crown = CGPoint(x: base.x + leaning * 21 * size, y: base.y - 240 * size)
        ellipse(CGRect(x: base.x - 44 * size, y: base.y - 5 * size, width: 88 * size, height: 18 * size), color: dark.opacity(0.12))
        var trunk = Path()
        trunk.move(to: CGPoint(x: base.x - 34 * size, y: base.y + 3 * size))
        trunk.addCurve(to: CGPoint(x: crown.x - 11 * size, y: crown.y + 10 * size),
                       control1: CGPoint(x: base.x - 7 * size, y: base.y - 25 * size),
                       control2: CGPoint(x: base.x - 5 * size, y: base.y - 150 * size))
        trunk.addLine(to: CGPoint(x: crown.x + 13 * size, y: crown.y + 8 * size))
        trunk.addCurve(to: CGPoint(x: base.x + 34 * size, y: base.y + 2 * size),
                       control1: CGPoint(x: base.x + 21 * size, y: base.y - 145 * size),
                       control2: CGPoint(x: base.x + 10 * size, y: base.y - 19 * size))
        trunk.addQuadCurve(to: CGPoint(x: base.x - 34 * size, y: base.y + 3 * size),
                           control: CGPoint(x: base.x, y: base.y - 3 * size))
        trunk.closeSubpath()
        context.fill(trunk, with: .color(Color(dinoHex: 0x92774F)))
        // A fork and tapered roots make the crown and trunk read as one tree.
        for side in [-1.0, 1.0] {
            var branch = Path()
            branch.move(to: CGPoint(x: base.x + 4 * size, y: base.y - 137 * size))
            branch.addQuadCurve(to: CGPoint(x: crown.x + CGFloat(side) * 55 * size, y: crown.y - 8 * size),
                                control: CGPoint(x: crown.x + CGFloat(side) * 26 * size, y: crown.y + 71 * size))
            context.stroke(branch, with: .color(Color(dinoHex: 0x92774F)), style: StrokeStyle(lineWidth: 11 * size, lineCap: .round))
        }
        var bark = Path()
        bark.move(to: CGPoint(x: base.x + 11 * size, y: base.y - 12 * size))
        bark.addQuadCurve(to: CGPoint(x: crown.x + 5 * size, y: crown.y + 56 * size),
                          control: CGPoint(x: base.x + 6 * size, y: base.y - 97 * size))
        context.stroke(bark, with: .color(Color(dinoHex: 0xB59A67)), style: StrokeStyle(lineWidth: 4 * size, lineCap: .round))
        foliage(in: CGRect(x: crown.x - 94 * size, y: crown.y - 42 * size, width: 185 * size, height: 100 * size), color: dark, highlights: false)
        foliage(in: CGRect(x: crown.x - 94 * size, y: crown.y - 34 * size, width: 100 * size, height: 83 * size), color: Color(dinoHex: 0x58955B))
        foliage(in: CGRect(x: crown.x - 20 * size, y: crown.y - 53 * size, width: 118 * size, height: 89 * size), color: green)
        foliage(in: CGRect(x: crown.x - 52 * size, y: crown.y - 4 * size, width: 104 * size, height: 71 * size), color: Color(dinoHex: 0x7CAE61))
        fern(at: CGPoint(x: base.x - leaning * 17 * size, y: base.y + 7 * size), size: size * 0.55, flipped: leaning < 0)
    }

    private func palmFrond(from point: CGPoint, reach: CGFloat, drop: CGFloat, lift: CGFloat, size: CGFloat, color: Color) {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: point.x + x * size, y: point.y + y * size) }
        var frond = Path()
        frond.move(to: point)
        frond.addCurve(to: pt(reach, drop), control1: pt(reach * 0.24, -lift),
                       control2: pt(reach * 0.76, -lift * 0.72))
        frond.addCurve(to: point, control1: pt(reach * 0.80, drop - 5),
                       control2: pt(reach * 0.36, -lift + 25))
        frond.closeSubpath()
        context.fill(frond, with: .color(color))
        var vein = Path()
        vein.move(to: point)
        vein.addCurve(to: pt(reach * 0.96, drop * 0.92), control1: pt(reach * 0.29, -lift * 0.69),
                      control2: pt(reach * 0.71, -lift * 0.42))
        context.stroke(vein, with: .color(light.opacity(0.35)), style: StrokeStyle(lineWidth: 1.2 * size, lineCap: .round))
    }

    func palm(at base: CGPoint, size: CGFloat, flipped: Bool) {
        let direction: CGFloat = flipped ? -1 : 1
        let top = CGPoint(x: base.x + direction * 32 * size, y: base.y - 172 * size)
        var stem = Path()
        stem.move(to: base)
        stem.addQuadCurve(to: top, control: CGPoint(x: base.x - direction * 4 * size, y: base.y - 121 * size))
        context.stroke(stem, with: .color(Color(dinoHex: 0x987E53)), style: StrokeStyle(lineWidth: 13 * size, lineCap: .round))
        var highlight = context
        highlight.translateBy(x: -3 * direction * size, y: 0)
        highlight.stroke(stem, with: .color(Color(dinoHex: 0xBCA06D)), style: StrokeStyle(lineWidth: 4 * size, lineCap: .round))
        let fronds: [(CGFloat, CGFloat, CGFloat)] = [(-104, 36, 44), (107, 37, 40), (-96, 4, 54),
                                                       (85, -12, 48), (-68, -32, 55), (35, -54, 53), (-23, -65, 50)]
        for (i, frond) in fronds.enumerated() {
            palmFrond(from: top, reach: frond.0 * direction, drop: frond.1, lift: frond.2,
                      size: size, color: i < 2 ? dark : i.isMultiple(of: 2) ? green : Color(dinoHex: 0x56955E))
        }
        ellipse(CGRect(x: top.x - 7 * size, y: top.y - 1 * size, width: 12 * size, height: 13 * size), color: Color(dinoHex: 0x90724C))
    }

    func vine(from start: CGPoint, length: CGFloat, bend: CGFloat) {
        var vine = Path()
        vine.move(to: start)
        vine.addCurve(to: CGPoint(x: start.x + bend * 0.55, y: start.y + length),
                      control1: CGPoint(x: start.x + bend, y: start.y + length * 0.2),
                      control2: CGPoint(x: start.x - bend * 0.4, y: start.y + length * 0.7))
        context.stroke(vine, with: .color(dark.opacity(0.7)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        for i in 1...4 {
            leaf(at: CGPoint(x: start.x + bend * 0.3, y: start.y + CGFloat(i) * length / 5),
                 length: 23, width: 8, angle: i.isMultiple(of: 2) ? 65 : -65, color: green)
        }
    }

    /// Rounded corners retain a rock's uneven planes instead of forming a cylinder.
    private func roundedOutline(_ points: [CGPoint], rounding: CGFloat = 0.18) -> Path {
        guard points.count > 2 else { return Path() }
        func between(_ a: CGPoint, _ b: CGPoint, fraction: CGFloat) -> CGPoint {
            CGPoint(x: a.x + (b.x - a.x) * fraction, y: a.y + (b.y - a.y) * fraction)
        }
        return Path { p in
            p.move(to: between(points[0], points[points.count - 1], fraction: rounding))
            for i in points.indices {
                let previous = points[(i + points.count - 1) % points.count]
                let next = points[(i + 1) % points.count]
                p.addLine(to: between(points[i], previous, fraction: rounding))
                p.addQuadCurve(to: between(points[i], next, fraction: rounding), control: points[i])
            }
            p.closeSubpath()
        }
    }

    private func boulder(in r: CGRect, moss: Bool) {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        ellipse(CGRect(x: r.minX, y: r.maxY - r.height * 0.17, width: r.width, height: r.height * 0.28), color: dark.opacity(0.13))
        let stone = roundedOutline([pt(0.05, 0.66), pt(0.09, 0.32), pt(0.30, 0.09), pt(0.57, 0.05),
                                    pt(0.86, 0.24), pt(0.98, 0.61), pt(0.83, 0.86), pt(0.53, 0.97), pt(0.18, 0.90)])
        context.fill(stone, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xB4BDAB), Color(dinoHex: 0x7F9584)]),
                                                  startPoint: pt(0.2, 0), endPoint: pt(0.8, 1)))
        context.fill(roundedOutline([pt(0.60, 0.21), pt(0.91, 0.42), pt(0.88, 0.81), pt(0.54, 0.93), pt(0.44, 0.65)]),
                     with: .color(Color(dinoHex: 0x6A8378).opacity(0.32)))
        if moss {
            let patch = roundedOutline([pt(0.08, 0.48), pt(0.17, 0.26), pt(0.33, 0.14), pt(0.53, 0.21),
                                        pt(0.68, 0.19), pt(0.83, 0.34), pt(0.67, 0.43), pt(0.51, 0.34),
                                        pt(0.40, 0.44), pt(0.27, 0.34), pt(0.15, 0.52)])
            context.fill(patch, with: .color(Color(dinoHex: 0x739759)))
        }
    }

    func rocks(at point: CGPoint, size: CGFloat) {
        boulder(in: CGRect(x: point.x - 47 * size, y: point.y - 27 * size, width: 43 * size, height: 30 * size), moss: false)
        boulder(in: CGRect(x: point.x - 20 * size, y: point.y - 36 * size, width: 55 * size, height: 40 * size), moss: true)
        boulder(in: CGRect(x: point.x + 24 * size, y: point.y - 17 * size, width: 30 * size, height: 23 * size), moss: true)
    }

    func waterfall(at point: CGPoint, size: CGFloat) {
        var c = context
        c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: size, y: size)
        let p = JunglePainter(context: c)
        // The shallow pool lies below the cliff; its uneven bank follows the shore.
        let pool = p.roundedOutline([CGPoint(x: -78, y: 103), CGPoint(x: -63, y: 79), CGPoint(x: -12, y: 66),
                                    CGPoint(x: 55, y: 73), CGPoint(x: 91, y: 96), CGPoint(x: 69, y: 124),
                                    CGPoint(x: 14, y: 135), CGPoint(x: -44, y: 128)], rounding: 0.4)
        c.fill(pool, with: .color(Color(dinoHex: 0xA8C6A1)))
        let waterSurface = p.roundedOutline([CGPoint(x: -68, y: 102), CGPoint(x: -50, y: 82), CGPoint(x: -7, y: 73),
                                            CGPoint(x: 52, y: 81), CGPoint(x: 79, y: 99), CGPoint(x: 58, y: 118),
                                            CGPoint(x: 12, y: 126), CGPoint(x: -36, y: 121)], rounding: 0.4)
        c.fill(waterSurface, with: .color(Color(dinoHex: 0x73B7BD)))
        let cliff = p.roundedOutline([CGPoint(x: -55, y: 77), CGPoint(x: -58, y: 32), CGPoint(x: -47, y: 7),
                                     CGPoint(x: -50, y: -35), CGPoint(x: -31, y: -91), CGPoint(x: -14, y: -113),
                                     CGPoint(x: 45, y: -109), CGPoint(x: 70, y: -79), CGPoint(x: 67, y: -34),
                                     CGPoint(x: 89, y: -11), CGPoint(x: 86, y: 40), CGPoint(x: 70, y: 87),
                                     CGPoint(x: 22, y: 92)], rounding: 0.12)
        c.fill(cliff, with: .color(Color(dinoHex: 0x98AB96)))
        let shadowPlane = p.roundedOutline([CGPoint(x: 40, y: -102), CGPoint(x: 66, y: -71), CGPoint(x: 61, y: -32),
                                            CGPoint(x: 83, y: -9), CGPoint(x: 80, y: 39), CGPoint(x: 65, y: 86),
                                            CGPoint(x: 36, y: 85), CGPoint(x: 44, y: 16)], rounding: 0.12)
        c.fill(shadowPlane, with: .color(Color(dinoHex: 0x7D9786)))
        let lightPlane = p.roundedOutline([CGPoint(x: -31, y: -72), CGPoint(x: -14, y: -99), CGPoint(x: 10, y: -97),
                                           CGPoint(x: -1, y: -12), CGPoint(x: -18, y: 64), CGPoint(x: -32, y: 73)])
        c.fill(lightPlane, with: .color(Color(dinoHex: 0xB2BFA5)))
        for i in 0..<3 {
            var fissure = Path()
            fissure.move(to: CGPoint(x: 41, y: -63 + CGFloat(i) * 46))
            fissure.addLine(to: CGPoint(x: 57, y: -55 + CGFloat(i) * 46))
            fissure.addLine(to: CGPoint(x: 70, y: -57 + CGFloat(i) * 46))
            c.stroke(fissure, with: .color(Color(dinoHex: 0x678678).opacity(0.4)),
                     style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round))
        }
        for i in 0..<3 {
            var crack = Path()
            crack.move(to: CGPoint(x: -35, y: -44 + CGFloat(i) * 40))
            crack.addLine(to: CGPoint(x: -20, y: -37 + CGFloat(i) * 40))
            crack.addLine(to: CGPoint(x: -6, y: -41 + CGFloat(i) * 40))
            c.stroke(crack, with: .color(Color(dinoHex: 0x718E7D).opacity(0.25)),
                     style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
        }
        let mossLip = p.roundedOutline([CGPoint(x: -30, y: -97), CGPoint(x: -15, y: -111),
                                       CGPoint(x: 36, y: -108), CGPoint(x: 50, y: -100), CGPoint(x: 28, y: -99),
                                       CGPoint(x: 16, y: -103), CGPoint(x: -4, y: -97), CGPoint(x: -19, y: -101)])
        c.fill(mossLip, with: .color(Color(dinoHex: 0x81A761)))
        // A small visible stream feeds the lip; water widens as it reaches the pool.
        var source = Path()
        source.move(to: CGPoint(x: 56, y: -116))
        source.addCurve(to: CGPoint(x: 5, y: -107), control1: CGPoint(x: 27, y: -128), control2: CGPoint(x: 26, y: -104))
        c.stroke(source, with: .color(Color(dinoHex: 0x8AC8CB)), style: StrokeStyle(lineWidth: 11, lineCap: .round))
        var fall = Path()
        fall.move(to: CGPoint(x: -8, y: -106))
        fall.addCurve(to: CGPoint(x: 1, y: 83), control1: CGPoint(x: -10, y: -48), control2: CGPoint(x: -1, y: 51))
        fall.addQuadCurve(to: CGPoint(x: 27, y: 84), control: CGPoint(x: 14, y: 95))
        fall.addCurve(to: CGPoint(x: 18, y: -107), control1: CGPoint(x: 26, y: 45), control2: CGPoint(x: 11, y: -44))
        fall.closeSubpath()
        c.fill(fall, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xA5D6D9), Color(dinoHex: 0xDAEFDF)]),
                                             startPoint: CGPoint(x: 0, y: -106), endPoint: CGPoint(x: 0, y: 90)))
        for i in 0..<2 {
            var streak = Path()
            let x = CGFloat(i) * 10 - 2
            streak.move(to: CGPoint(x: x, y: i == 0 ? -85 : -24))
            streak.addCurve(to: CGPoint(x: x + 7, y: i == 0 ? 18 : 72),
                            control1: CGPoint(x: x - 2, y: i == 0 ? -45 : 5),
                            control2: CGPoint(x: x + 2, y: i == 0 ? -11 : 39))
            c.stroke(streak, with: .color(.white.opacity(0.55)), style: StrokeStyle(lineWidth: i == 0 ? 2.3 : 1.4, lineCap: .round))
        }
        for i in 0..<6 {
            p.ellipse(CGRect(x: -8 + CGFloat(i) * 5, y: 83 + CGFloat(i % 3) * 3,
                             width: 10 + CGFloat(i % 2) * 3, height: 5), color: Color(dinoHex: 0xE2F3E6))
        }
        for i in 0..<2 {
            var ripple = Path()
            ripple.addArc(center: CGPoint(x: 10, y: 95), radius: CGFloat(23 + i * 12),
                          startAngle: .degrees(20), endAngle: .degrees(148), clockwise: false)
            var flattened = c
            flattened.translateBy(x: 0, y: 66)
            flattened.scaleBy(x: 1, y: 0.35)
            flattened.stroke(ripple, with: .color(Color(dinoHex: 0xB9DFD4).opacity(0.85)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        p.bush(at: CGPoint(x: 69, y: -103), size: 0.53)
        p.fern(at: CGPoint(x: -32, y: -101), size: 0.32, flipped: false)
        p.boulder(in: CGRect(x: -57, y: 66, width: 40, height: 29), moss: true)
        p.rocks(at: CGPoint(x: 56, y: 127), size: 0.52)
    }

    func grass(at point: CGPoint, size: CGFloat, color: Color) {
        var grass = Path()
        grass.move(to: CGPoint(x: point.x - size, y: point.y))
        grass.addQuadCurve(to: CGPoint(x: point.x - size * 0.7, y: point.y - size), control: CGPoint(x: point.x - size * 0.2, y: point.y))
        grass.move(to: point)
        grass.addQuadCurve(to: CGPoint(x: point.x + size * 0.2, y: point.y - size * 1.3), control: CGPoint(x: point.x - size * 0.1, y: point.y - size * 0.6))
        grass.move(to: CGPoint(x: point.x + size * 0.4, y: point.y))
        grass.addQuadCurve(to: CGPoint(x: point.x + size, y: point.y - size * 0.65), control: CGPoint(x: point.x + size * 0.4, y: point.y - size * 0.4))
        context.stroke(grass, with: .color(color), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }

    func flowers(at point: CGPoint, size: CGFloat) {
        for i in 0..<3 {
            let origin = CGPoint(x: point.x + CGFloat(i - 1) * 16 * size, y: point.y - CGFloat(i % 2) * 13 * size)
            var stem = Path()
            stem.move(to: CGPoint(x: origin.x, y: point.y + 12 * size))
            stem.addLine(to: origin)
            context.stroke(stem, with: .color(dark), lineWidth: 2 * size)
            for petal in 0..<5 {
                let angle = Double(petal) * .pi * 2 / 5
                ellipse(CGRect(x: origin.x + CGFloat(cos(angle)) * 5 * size - 4 * size,
                               y: origin.y + CGFloat(sin(angle)) * 5 * size - 4 * size,
                               width: 8 * size, height: 8 * size), color: Color(dinoHex: i == 1 ? 0xF0BC74 : 0xF3D491))
            }
            ellipse(CGRect(x: origin.x - 3 * size, y: origin.y - 3 * size, width: 6 * size, height: 6 * size), color: Color(dinoHex: 0xFFF5D3))
        }
    }

}


// MARK: - Shape-drawn chapters

struct WorldThemeColors {
    let ground: UInt32
    let accent: UInt32
    let distant: UInt32
    let shade: UInt32
    init(_ world: DinoWorld) {
        ground = world.ground
        switch world.id {
        case 1: (accent, distant, shade) = (0x8BBE69, 0xACC992, 0x326C55)
        case 2: (accent, distant, shade) = (0x9CCBB8, 0xB2B4D7, 0x596A99)
        case 3: (accent, distant, shade) = (0xF47C65, 0xE4A688, 0x706778)
        case 4: (accent, distant, shade) = (0xD98663, 0xAAD9B8, 0x6C8561)
        case 5: (accent, distant, shade) = (0xA493D7, 0x9CCBD0, 0x427D89)
        case 6: (accent, distant, shade) = (0x54BCC5, 0x94C8DC, 0x537D93)
        case 7: (accent, distant, shade) = (0x8CC68C, 0xAA99CC, 0x526894)
        case 8: (accent, distant, shade) = (0xD9B46C, 0xB5A6E6, 0x597D88)
        case 9: (accent, distant, shade) = (0x63C7CB, 0xABDDE1, 0xA47757)
        default: (accent, distant, shade) = (0x789BCF, 0xB9CCA8, 0x8D867A)
        }
    }
}

/// All scenery is native Canvas geometry. Generated concepts are documentation only.
struct ThemedWorldLandscape: View {
    let world: DinoWorld
    var routeOffset: CGFloat = 180

    var body: some View {
        Canvas { context, size in
            let colors = WorldThemeColors(world)
            let w = size.width
            let left = max(0, (w - 650) / 2)
            let right = w - left
            let scale = min(1.30, max(0.82, w / 390))
            let nextGround = DinoWorldCatalog.world(world.id + 1)?.ground ?? world.ground
            let ground = Color(dinoHex: colors.ground)
            var stops = [
                Gradient.Stop(color: ground, location: 0),
                .init(color: ground, location: 0.75),
                .init(color: Color(dinoHex: nextGround), location: 1)
            ]
            if world.id == 7 {
                stops = [.init(color: ground, location: 0),
                         .init(color: Color(dinoHex: 0xF1E8B7), location: 0.10),
                         .init(color: Color(dinoHex: 0xD4E8BE), location: 0.35),
                         .init(color: Color(dinoHex: 0xBFC5E0), location: 0.68),
                         .init(color: Color(dinoHex: 0xA9BBD4), location: 0.90),
                         .init(color: Color(dinoHex: nextGround), location: 1)]
            }
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .linearGradient(Gradient(stops: stops), startPoint: .zero,
                                               endPoint: CGPoint(x: 0, y: size.height)))
            let sky = ThemePainter(context: context, colors: colors)
            sky.horizon(worldID: world.id, width: w, left: left, right: right, scale: scale)
            var routeContext = context
            routeContext.translateBy(x: 0, y: routeOffset)
            let p = ThemePainter(context: routeContext, colors: colors)
            p.terrain(worldID: world.id, width: w, left: left, right: right, scale: scale)
            // Each clearing has a planted foreground, a destination and smaller
            // supporting props. The central route remains a separate UI layer.
            for index in 0..<9 {
                // Place the largest props on the outside of each bend. This
                // exposes the whole scene without crowding the level buttons.
                let onRight = index % 4 == 0 || index % 4 == 3
                let point = CGPoint(x: onRight ? right - 36 * scale : left + 36 * scale,
                                    y: 180 + CGFloat(index) * 175)
                if [4, 6, 10].contains(world.id) {
                    let positions: [CGFloat] = [0.28, 0.5, 0.72, 0.5, 0.28, 0.5, 0.72, 0.5, 0.28, 0.5]
                    let routeWidth = min(w, 600) - 36
                    let x = (w - routeWidth) / 2 + routeWidth * (positions[index] + (positions[index + 1] - positions[index]) * 0.622)
                    p.approach(from: CGPoint(x: x, y: point.y), to: point,
                               city: world.id == 6, scale: scale)
                }
                p.scene(worldID: world.id, at: point, size: scale * 1.08, variation: index)
                p.edgeGarden(worldID: world.id,
                             at: CGPoint(x: onRight ? left - 6 : right + 6, y: point.y + 82),
                             size: scale, variation: index)
            }
            let bossPoint = CGPoint(x: right - 79 * scale, y: 1728)
            context.fill(Path(CGRect(x: 0, y: size.height - 180, width: w, height: 180)),
                         with: .linearGradient(Gradient(colors: [Color(dinoHex: nextGround).opacity(0), Color(dinoHex: nextGround)]),
                                               startPoint: CGPoint(x: 0, y: size.height - 180),
                                               endPoint: CGPoint(x: 0, y: size.height)))
            p.bossClearing(worldID: world.id, at: bossPoint, size: scale)
            p.boss(worldID: world.id, at: bossPoint, size: scale * 0.88)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Shape-only art for the boss start card and the next-world reward.
struct WorldThemePreview: View {
    let world: DinoWorld
    var body: some View {
        Canvas { context, size in
            let colors = WorldThemeColors(world)
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(dinoHex: colors.ground)))
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                Gradient(colors: [.white.opacity(0.25), Color(dinoHex: colors.shade).opacity(0.08)]),
                startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
            let p = ThemePainter(context: context, colors: colors)
            let heightUnits: CGFloat = [8, 10].contains(world.id) ? 218 : 195
            let scale = min(size.height / heightUnits, size.width / 290)
            p.scene(worldID: world.id, at: CGPoint(x: size.width * 0.21, y: size.height * 0.87),
                    size: scale * 1.12, variation: 0)
            p.bossClearing(worldID: world.id, at: CGPoint(x: size.width * 0.71, y: size.height * 0.92), size: scale)
            p.boss(worldID: world.id, at: CGPoint(x: size.width * 0.70, y: size.height * 0.94), size: scale)
        }.allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(LocalizedStringKey(world.bossKey)))
            .accessibilityValue(Text(verbatim: String(format: "%02d:%02d", WorldBossClock.time(in: world.id).hour,
                                                     WorldBossClock.time(in: world.id).minute)))
    }
}

private struct ThemePainter {
    let context: GraphicsContext
    let colors: WorldThemeColors

    func horizon(worldID: Int, width: CGFloat, left: CGFloat, right: CGFloat, scale: CGFloat) {
        let nature = JunglePainter(context: context)
        nature.hill(x: -width * 0.40, y: 15, width: width * 0.9, height: 210,
                    color: tint(colors.distant, toward: colors.ground, amount: 0.45).opacity(0.32))
        nature.hill(x: width * 0.65, y: 75, width: width * 0.7, height: 240,
                    color: Color(dinoHex: colors.accent).opacity(0.12))
        if worldID == 2 || worldID == 7 {
            glow(at: CGPoint(x: right - 50, y: 64), radius: 55, color: 0xFFF1B8, opacity: 0.17)
            moon(at: CGPoint(x: right - 50, y: 64), size: 0.72)
            for i in 0..<5 {
                star(at: CGPoint(x: left + 20 + CGFloat(i % 2) * 30, y: 18 + CGFloat(i) * 31),
                     radius: i.isMultiple(of: 2) ? 3 : 2, color: 0xFFF1B8)
            }
            sprig(at: CGPoint(x: left - 3, y: 153), size: scale * 0.80, color: 0x8EAEA4)
        } else if worldID == 5 {
            for side: CGFloat in [left - 12, right + 12] {
                crystals(at: CGPoint(x: side, y: 100), size: 0.55 * scale)
                glow(at: CGPoint(x: side, y: 80), radius: 60, color: 0x79D8D0, opacity: 0.14)
            }
        } else if worldID == 8 {
            for x in [left + 6, right - 6] { gear(at: CGPoint(x: x, y: 85), radius: 23 * scale) }
        } else {
            glow(at: CGPoint(x: right - 52, y: 52), radius: 62, color: 0xFFF1B8, opacity: 0.20)
            ellipse(CGRect(x: right - 83, y: 22, width: 62, height: 62), 0xFFF1B8, opacity: 0.60)
            for i in 0..<2 {
                let x = left - 20 + CGFloat(i) * 20
                ellipse(CGRect(x: x, y: 38 + CGFloat(i) * 50, width: 90, height: 19), 0xFFFBE9, opacity: 0.35)
            }
        }
    }

    func terrain(worldID: Int, width: CGFloat, left: CGFloat, right: CGFloat, scale: CGFloat) {
        let nature = JunglePainter(context: context)
        for i in 0..<4 {
            let y = CGFloat(i) * 470 + 100
            nature.hill(x: i.isMultiple(of: 2) ? -width * 0.45 : width * 0.58, y: y,
                        width: width * 0.9, height: 360, color: Color(dinoHex: colors.distant).opacity(0.16))
        }
        if [2, 9, 10].contains(worldID) {
            for side in 0..<2 {
                let edge = side == 0 ? left - 26 : right + 26
                var water = Path()
                water.move(to: CGPoint(x: edge, y: -20))
                for i in 0..<6 {
                    let y = CGFloat(i) * 315
                    water.addCurve(to: CGPoint(x: edge + (i.isMultiple(of: 2) ? 10 : -10) * scale, y: y + 315),
                                   control1: CGPoint(x: edge - 40 * scale, y: y + 80),
                                   control2: CGPoint(x: edge + 30 * scale, y: y + 230))
                }
                let bank: UInt32 = worldID == 9 ? 0xE7C284 : worldID == 10 ? 0xA8C1A4 : 0xA2C5B4
                context.stroke(water, with: .color(Color(dinoHex: bank).opacity(0.75)),
                               style: StrokeStyle(lineWidth: (worldID == 9 ? 140 : 72) * scale, lineCap: .round))
                context.stroke(water, with: .color(Color(dinoHex: worldID == 9 ? 0x70C5CD : 0x92CDD0).opacity(0.70)),
                               style: StrokeStyle(lineWidth: (worldID == 9 ? 113 : 49) * scale, lineCap: .round))
                context.stroke(water, with: .color(Color(dinoHex: 0xC4EBDF).opacity(0.65)),
                               style: StrokeStyle(lineWidth: 2.5 * scale, lineCap: .round, dash: [16, 45]))
            }
        }
        if worldID == 5 {
            for side in 0..<2 {
                let x = side == 0 ? left - 48 : right + 48
                for i in 0..<8 {
                    at(CGPoint(x: x, y: CGFloat(i) * 233 + 40), size: scale) { p in
                        p.rock(at: .zero, size: 1.65, color: 0x809CAC)
                        p.rock(at: CGPoint(x: side == 0 ? 22 : -22, y: 120), size: 1.1, color: 0xA2BDC3)
                    }
                }
            }
        }
        for i in 0..<12 {
            for side in 0..<2 {
                let edge = side == 0 ? left : right
                let inset = CGFloat((i * 17 + side * 11) % 38)
                let point = CGPoint(x: edge + (side == 0 ? inset : -inset), y: 85 + CGFloat(i) * 143)
                at(point, size: scale) { p in
                    if [4, 6, 10].contains(worldID) {
                        for j in 0..<3 {
                            p.rounded(CGRect(x: CGFloat(j) * 14 - 22, y: CGFloat(j % 2) * 5, width: 11, height: 5),
                                      radius: 2, color: worldID == 6 ? 0xA7CBD5 : 0xE0D6B7)
                        }
                    } else if worldID == 3 {
                        p.line([CGPoint(x: -16, y: -5), .zero, CGPoint(x: 9, y: 12), CGPoint(x: 22, y: 14)],
                               color: 0xC39D88, width: 1.3)
                        p.rock(at: CGPoint(x: -10, y: 20), size: 0.23, color: 0x887F8D)
                        if i.isMultiple(of: 3) { p.glow(at: CGPoint(x: 6, y: 5), radius: 12, color: 0xFFCA74, opacity: 0.35) }
                    } else if worldID == 8 {
                        p.line([CGPoint(x: -23, y: 0), CGPoint(x: -5, y: 0), CGPoint(x: -5, y: 15), CGPoint(x: 21, y: 15)],
                               color: 0xC7BF99, width: 3)
                        for x: CGFloat in [-23, 21] { p.ellipse(CGRect(x: x - 2, y: 12, width: 4, height: 4), 0xD9B46C) }
                    } else if worldID == 5 {
                        p.crystals(at: CGPoint(x: 0, y: 15), size: 0.21)
                        p.glow(at: CGPoint(x: 10, y: -3), radius: 19, color: 0xB8F0DE, opacity: 0.20)
                    } else {
                        nature.grass(at: point, size: 7 * scale, color: Color(dinoHex: colors.accent).opacity(0.60))
                    }
                    if [2, 7].contains(worldID) && i > 4 {
                        p.glow(at: CGPoint(x: 14, y: -15), radius: 12, color: 0xFFF1B8, opacity: 0.23)
                        p.ellipse(CGRect(x: 12, y: -17, width: 3, height: 3), 0xFFF1B8)
                    }
                }
            }
        }
    }

    func approach(from start: CGPoint, to destination: CGPoint, city: Bool, scale: CGFloat) {
        let end = CGPoint(x: destination.x, y: destination.y + 12 * scale)
        var path = Path()
        path.move(to: start)
        path.addCurve(to: end,
                      control1: CGPoint(x: start.x + (end.x - start.x) * 0.38, y: start.y + 20 * scale),
                      control2: CGPoint(x: start.x + (end.x - start.x) * 0.68, y: end.y - 13 * scale))
        context.stroke(path, with: .color(Color(dinoHex: city ? 0x94B9C8 : 0xBFC29C).opacity(0.48)),
                       style: StrokeStyle(lineWidth: 13 * scale, lineCap: .round))
        context.stroke(path, with: .color(Color(dinoHex: city ? 0xD0E1E4 : 0xE3DDB9).opacity(0.74)),
                       style: StrokeStyle(lineWidth: 9 * scale, lineCap: .round))
        context.stroke(path, with: .color(Color(dinoHex: 0xFFF1D3).opacity(0.30)),
                       style: StrokeStyle(lineWidth: 1.5 * scale, lineCap: .round, dash: [1, 8]))
    }

    func scene(worldID: Int, at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            p.gardenPatch(at: CGPoint(x: 0, y: 11), width: 132, color: p.colors.accent)
            switch worldID {
            case 1:
                let jungle = JunglePainter(context: p.context)
                jungle.tree(at: CGPoint(x: -17, y: -2), size: 0.53, leaning: 1)
                jungle.rocks(at: CGPoint(x: 23, y: 9), size: 0.55)
                jungle.fern(at: CGPoint(x: 32, y: 23), size: 0.52, flipped: true)
                jungle.vine(from: CGPoint(x: -30, y: -131), length: 97, bend: 17)
            case 2:
                p.tree(at: CGPoint(x: -19, y: 0), size: variation.isMultiple(of: 2) ? 0.90 : 0.65, night: true, willow: true, variation: variation)
                p.mushroom(at: CGPoint(x: 25, y: 10), size: 0.75)
                p.mushroom(at: CGPoint(x: 46, y: 20), size: 0.40)
                if variation % 3 == 1 { p.clockPost(at: CGPoint(x: 28, y: -4), time: .init(hour: 3, minute: 30), size: 0.55) }
                p.sprig(at: CGPoint(x: -32, y: 17), size: 0.65, color: 0x9CCBB8)
                p.blossoms(at: CGPoint(x: 7, y: 28), size: 0.58, color: 0xE8CAE3)
            case 3:
                if variation % 3 == 0 { p.volcano(at: CGPoint(x: -8, y: 0), size: 0.87) }
                else if variation % 3 == 1 {
                    p.pond(at: CGPoint(x: -5, y: -3), size: 0.82, lava: true)
                    p.rock(at: CGPoint(x: -34, y: -24), size: 0.70, color: 0x887F8D)
                } else {
                    p.rock(at: CGPoint(x: -18, y: -6), size: 1.15, color: 0x887F8D)
                    p.clockPost(at: CGPoint(x: 18, y: -12), time: .init(hour: 4, minute: 45), size: 0.67)
                }
                p.rock(at: CGPoint(x: 38, y: 15), size: 0.50, color: 0x96868C)
                p.rock(at: CGPoint(x: 12, y: 24), size: 0.30, color: 0xB69D91)
                p.sprig(at: CGPoint(x: -30, y: 24), size: 0.58, color: 0xC18F6C)
            case 4:
                if variation % 3 == 2 { p.building(at: CGPoint(x: -12, y: 1), size: 0.86, city: false, tower: true) }
                else if variation % 3 == 1 {
                    p.tree(at: CGPoint(x: -30, y: -6), size: 0.65, night: false, willow: false)
                    p.fountain(at: CGPoint(x: 23, y: 13), size: 0.75)
                }
                else {
                    p.building(at: CGPoint(x: -27, y: -11), size: 0.72, city: false, variation: variation)
                    p.building(at: CGPoint(x: 25, y: 6), size: 0.61, city: false, variation: variation + 1)
                }
                p.fence(at: CGPoint(x: -4, y: 29), size: 0.85)
                p.blossoms(at: CGPoint(x: -33, y: 25), size: 0.70, color: 0xEEA8A0)
                p.blossoms(at: CGPoint(x: 43, y: 31), size: 0.52, color: 0xF7D87B)
            case 5:
                p.rock(at: CGPoint(x: -14, y: 1), size: 1.02, color: 0x89A9B8)
                p.glow(at: CGPoint(x: 14, y: -38), radius: 67, color: 0x8EEDD8, opacity: 0.25)
                p.crystals(at: CGPoint(x: 0, y: 10), size: 1.16, variation: variation)
                p.crystals(at: CGPoint(x: 40, y: 25), size: 0.42, variation: variation + 1)
                if variation == 2 { p.clockPost(at: CGPoint(x: 18, y: -47), time: .init(hour: 2, minute: 17), size: 0.65) }
                p.rock(at: CGPoint(x: -37, y: 21), size: 0.30, color: 0x8CA6AF)
                for i in 0..<3 { p.star(at: CGPoint(x: CGFloat(i) * 23 - 25, y: -30 - CGFloat(i % 2) * 62), radius: 3, color: 0xECFFF4) }
            case 6:
                p.building(at: CGPoint(x: -25, y: -16), size: 0.79, city: true, tower: variation.isMultiple(of: 2))
                p.building(at: CGPoint(x: 26, y: 3), size: 0.62, city: true)
                if variation == 2 || variation == 4 { p.tram(at: CGPoint(x: 8, y: 39), size: 0.62) }
                else { p.bench(at: CGPoint(x: 15, y: 35), size: 0.65) }
                p.lamp(at: CGPoint(x: 49, y: 12), size: 0.68, night: false)
                p.planter(at: CGPoint(x: -43, y: 17), size: 0.62, flowers: true)
            case 7:
                p.tree(at: CGPoint(x: -8, y: -2), size: 0.93, night: variation > 3, willow: false, variation: variation)
                p.mushroom(at: CGPoint(x: 32, y: 15), size: 0.63)
                p.sprig(at: CGPoint(x: -34, y: 22), size: 0.75, color: variation > 2 ? 0x8595AC : 0x9CBE83)
                if variation % 3 == 1 { p.clockPost(at: CGPoint(x: 22, y: 10), time: .init(hour: variation > 2 ? 20 : 8), size: 0.66, digital: true) }
                p.blossoms(at: CGPoint(x: 5, y: 28), size: 0.45, color: 0xEAE6B1)
            case 8:
                p.machineBase(at: CGPoint(x: -8, y: 18), size: 0.94)
                if variation % 3 == 0 { p.portal(at: CGPoint(x: -6, y: -2), size: 0.87) }
                else { p.workbench(at: CGPoint(x: -6, y: -2), size: 0.94, variation: variation) }
                p.gear(at: CGPoint(x: -42, y: -21), radius: 22)
                p.hourglass(at: CGPoint(x: 40, y: 25), size: 0.57)
                if variation % 3 == 1 { p.clockPost(at: CGPoint(x: 40, y: -23), time: .init(hour: 6, minute: 25), size: 0.55, digital: true) }
            case 9:
                if variation % 3 == 1 {
                    p.jetty(at: CGPoint(x: -5, y: 20), size: 0.85)
                    p.ship(at: CGPoint(x: -7, y: -1), size: 0.74)
                } else {
                    JunglePainter(context: p.context).palm(at: CGPoint(x: -20, y: 0), size: 0.65, flipped: false)
                    p.chest(at: CGPoint(x: 29, y: 22), size: 0.74)
                    p.hourglass(at: CGPoint(x: 32, y: -3), size: 0.45)
                }
                p.rock(at: CGPoint(x: -34, y: 24), size: 0.27, color: 0xD1B58A)
                p.sprig(at: CGPoint(x: 48, y: 36), size: 0.48, color: 0x80AE89)
            default:
                p.castleTower(at: CGPoint(x: -8, y: 0), size: 0.86)
                p.castleWall(at: CGPoint(x: -33, y: 24), size: 0.72)
                p.planter(at: CGPoint(x: 36, y: 24), size: 0.71, flowers: true)
                p.blossoms(at: CGPoint(x: -34, y: 32), size: 0.65, color: 0xEAA7B5)
                if variation == 3 { p.clockPost(at: CGPoint(x: 37, y: -21), time: .init(hour: 10, minute: 25), size: 0.57, digital: true) }
            }
        }
    }

    func edgeGarden(worldID: Int, at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            p.gardenPatch(at: CGPoint(x: 0, y: 9), width: 168, color: p.colors.distant)
            switch worldID {
            case 2:
                p.tree(at: CGPoint(x: -8, y: -8), size: 1.03, night: true, willow: true, variation: variation + 1)
                p.pond(at: CGPoint(x: 29, y: 17), size: 0.50, lava: false)
                p.blossoms(at: CGPoint(x: 34, y: 24), size: 0.6, color: 0xDAB9DE)
            case 3:
                p.rock(at: CGPoint(x: -18, y: -2), size: 1.25, color: 0x887F8D)
                p.rock(at: CGPoint(x: 28, y: 7), size: 0.78, color: 0xA89391)
                p.glow(at: CGPoint(x: 15, y: 16), radius: 30, color: 0xFFD88B, opacity: 0.22)
                p.sprig(at: CGPoint(x: 5, y: 18), size: 0.9, color: 0xC19174)
            case 4, 10:
                p.tree(at: CGPoint(x: -9, y: -2), size: 0.77, night: false, willow: false, variation: variation)
                p.planter(at: CGPoint(x: 32, y: 22), size: 0.82, flowers: true)
                if worldID == 4 {
                    for x: CGFloat in [-18, 0, 18] { p.volume(CGRect(x: x, y: -85, width: 7, height: 8), color: 0xEDAF87) }
                }
            case 5:
                p.rock(at: CGPoint(x: -16, y: -5), size: 1.4, color: 0x89A9B8)
                p.crystals(at: CGPoint(x: 29, y: 20), size: 0.64)
                p.glow(at: CGPoint(x: 32, y: -12), radius: 39, color: 0xB2F0DD, opacity: 0.17)
            case 6:
                p.planter(at: CGPoint(x: -14, y: -12), size: 1.08, flowers: true)
                p.lamp(at: CGPoint(x: 28, y: 4), size: 0.86, night: false)
                p.bench(at: CGPoint(x: 10, y: 24), size: 0.73)
            case 7:
                p.tree(at: CGPoint(x: -5, y: -4), size: 1.12, night: variation > 3, willow: false, variation: variation + 1)
                p.mushroom(at: CGPoint(x: 39, y: 17), size: 0.58)
                p.sprig(at: CGPoint(x: 24, y: 24), size: 0.8, color: variation > 3 ? 0x8595AC : 0x9CBE83)
            case 8:
                p.gear(at: CGPoint(x: -11, y: -31), radius: 34)
                p.gear(at: CGPoint(x: 28, y: -5), radius: 23)
                p.rounded(CGRect(x: -48, y: -4, width: 67, height: 14), radius: 5, color: 0x91B8B2)
                p.line([CGPoint(x: -38, y: 10), CGPoint(x: -38, y: 25), CGPoint(x: 20, y: 25)], color: 0xC7AC7B, width: 5)
            default:
                p.rock(at: CGPoint(x: -16, y: -1), size: 1.06, color: 0xD8BD93)
                p.sprig(at: CGPoint(x: 27, y: 19), size: 0.9, color: 0x83B39A)
                for i in 0..<3 {
                    let x = CGFloat(i) * 17 - 24
                    p.volume(CGRect(x: x, y: 25, width: 10, height: 7), color: i == 1 ? 0xEFC2AB : 0xF5E8BF)
                    p.line([CGPoint(x: x + 4, y: 26), CGPoint(x: x + 5, y: 31)], color: 0xD9BDA0, width: 1)
                }
            }
        }
    }

    private func fountain(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.shadow(width: 92)
            p.volume(CGRect(x: -44, y: -16, width: 88, height: 27), color: 0xD4D0B6)
            p.volume(CGRect(x: -38, y: -20, width: 76, height: 20), color: 0x8ECBD0)
            p.rounded(CGRect(x: -7, y: -51, width: 14, height: 43), radius: 5, color: 0xE0D6B7)
            p.volume(CGRect(x: -24, y: -55, width: 48, height: 15), color: 0xE7DDC2)
            p.volume(CGRect(x: -20, y: -58, width: 40, height: 9), color: 0x9EDAD8)
            for side: CGFloat in [-1, 1] {
                var stream = Path()
                stream.move(to: CGPoint(x: side * 17, y: -53))
                stream.addQuadCurve(to: CGPoint(x: side * 31, y: -9), control: CGPoint(x: side * 30, y: -39))
                p.context.stroke(stream, with: .color(Color(dinoHex: 0xC9F0E3)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            p.volume(CGRect(x: -7, y: -72, width: 14, height: 18), color: 0xFFF1D3)
            p.line([CGPoint(x: -26, y: -4), CGPoint(x: -11, y: -3)], color: 0xDAF3E6, width: 1.5)
        }
    }

    private func workbench(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -38, y: -73, width: 76, height: 48), radius: 10, color: 0x82AAA9)
            p.rounded(CGRect(x: -34, y: -69, width: 68, height: 38), radius: 8, color: 0xB1D7CA)
            p.clock(at: CGPoint(x: 1, y: -50), time: .init(hour: 6, minute: 25), size: 17, digital: variation.isMultiple(of: 2))
            p.rounded(CGRect(x: -45, y: -25, width: 90, height: 12), radius: 5, color: 0xD9B46C)
            for x: CGFloat in [-34, 27] {
                p.rounded(CGRect(x: x, y: -14, width: 7, height: 24), radius: 2, color: 0xA69069)
                p.volume(CGRect(x: x + 1, y: -65, width: 4, height: 4), color: 0xF5E8B9)
            }
            p.gear(at: CGPoint(x: -26, y: -20), radius: 12)
            p.rounded(CGRect(x: 13, y: -32, width: 23, height: 8), radius: 3, color: 0xB5A6E6)
            p.line([CGPoint(x: 33, y: -61), CGPoint(x: 44, y: -61), CGPoint(x: 44, y: -45)], color: 0xD9B46C, width: 3)
        }
    }

    func bossClearing(worldID: Int, at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.gardenPatch(at: CGPoint(x: 0, y: 7), width: 135, color: p.colors.accent)
            for i in 0..<5 {
                p.rounded(CGRect(x: -48 + CGFloat(i) * 22, y: 11 + CGFloat(i % 2) * 4, width: 14, height: 5),
                          radius: 2, color: [3, 5].contains(worldID) ? 0xA5ADB1 : 0xE0D6B7)
            }
            if [1, 2, 4, 7, 10].contains(worldID) {
                p.sprig(at: CGPoint(x: 44, y: 12), size: 0.60, color: worldID == 7 ? 0x8595AC : 0x9DBE91)
                p.blossoms(at: CGPoint(x: -41, y: 15), size: 0.50, color: worldID == 2 ? 0xDDD0EF : 0xECA6AF)
            } else if worldID == 5 {
                p.glow(at: CGPoint(x: 0, y: -50), radius: 76, color: 0xA8F0DB, opacity: 0.20)
                p.crystals(at: CGPoint(x: -45, y: 10), size: 0.33)
            } else if worldID == 8 { p.machineBase(at: CGPoint(x: 0, y: 6), size: 0.95) }
            else if worldID == 9 { p.jetty(at: CGPoint(x: 0, y: 16), size: 0.82) }
        }
    }

    private func glow(at point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), Color(dinoHex: color).opacity(0)]),
                                           center: point, startRadius: 0, endRadius: radius))
    }
    private func gardenPatch(at point: CGPoint, width: CGFloat, color: UInt32) {
        JunglePainter(context: context).hill(x: point.x - width / 2, y: point.y - 20, width: width, height: 45,
                                            color: tint(color, toward: colors.ground, amount: 0.65).opacity(0.68))
        ellipse(CGRect(x: point.x - width * 0.34, y: point.y - 1, width: width * 0.79, height: 14), colors.shade, opacity: 0.09)
    }
    private func sprig(at point: CGPoint, size: CGFloat, color: UInt32) {
        at(point, size: size) { p in
            let leaves = JunglePainter(context: p.context)
            for i in 0..<5 {
                let angle = Double(i - 2) * 28
                leaves.leaf(at: .zero, length: CGFloat(25 + i % 2 * 11), width: 8, angle: angle,
                            color: p.tint(color, toward: 0x567F78, amount: CGFloat(i) * 0.06))
            }
        }
    }
    private func blossoms(at point: CGPoint, size: CGFloat, color: UInt32) {
        at(point, size: size) { p in
            for i in 0..<3 {
                let x = CGFloat(i - 1) * 16, y = CGFloat(i % 2) * -12
                p.line([CGPoint(x: x, y: 4), CGPoint(x: x, y: y - 16)], color: 0x709B7C, width: 2)
                for petal in 0..<5 {
                    let a = Double(petal) * .pi * 2 / 5
                    p.volume(CGRect(x: x + CGFloat(cos(a)) * 5 - 4, y: y - 20 + CGFloat(sin(a)) * 5, width: 9, height: 8), color: color)
                }
                p.ellipse(CGRect(x: x - 3, y: y - 17, width: 6, height: 6), 0xFFF1B8)
            }
        }
    }
    private func tree(at point: CGPoint, size: CGFloat, night: Bool, willow: Bool, variation: Int = 0) {
        at(point, size: size) { p in
            p.shadow(width: 109)
            let wood: UInt32 = night ? 0x8C929E : 0xA68B63
            let leaf: UInt32 = night ? (willow ? 0x97B7B0 : 0x839AAC) : 0x8DBB86
            var trunk = Path()
            trunk.move(to: CGPoint(x: -16, y: 1))
            trunk.addQuadCurve(to: CGPoint(x: -3, y: -94), control: CGPoint(x: 5, y: -30))
            trunk.addLine(to: CGPoint(x: 13, y: -93))
            trunk.addQuadCurve(to: CGPoint(x: 17, y: 1), control: CGPoint(x: 4, y: -25))
            trunk.closeSubpath()
            p.material(trunk, rect: CGRect(x: -16, y: -94, width: 33, height: 96), color: wood)
            p.line([CGPoint(x: 4, y: -74), CGPoint(x: -26, y: -112)], color: wood, width: 8)
            p.line([CGPoint(x: 7, y: -69), CGPoint(x: 32, y: -109)], color: wood, width: 7)
            for i in 0..<5 {
                let x = CGFloat(i - 2) * 21, y: CGFloat = -128 - CGFloat((i + variation) % 3) * 8
                let r = CGRect(x: x - 26, y: y, width: 55, height: willow ? 58 : 47)
                let crown = JunglePainter(context: p.context).foliagePath(in: r)
                p.material(crown, rect: r, color: leaf)
                if willow {
                    for j in 0..<2 {
                        var tendril = Path()
                        let tx = x + CGFloat(j) * 13
                        tendril.move(to: CGPoint(x: tx, y: y + 27))
                        tendril.addQuadCurve(to: CGPoint(x: tx - 5, y: y + 81), control: CGPoint(x: tx + 8, y: y + 50))
                        p.context.stroke(tendril, with: .color(p.tint(leaf, toward: 0x628C87, amount: 0.30)),
                                         style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    }
                }
            }
            for i in 0..<19 {
                let x = CGFloat((i * 19 + variation * 7) % 101 - 50), y = CGFloat((i * 13) % 33 - 121)
                JunglePainter(context: p.context).leaf(at: CGPoint(x: x, y: y), length: 8 + CGFloat(i % 3) * 2, width: 3,
                    angle: Double(i * 29), color: i.isMultiple(of: 3) ? .white.opacity(0.27) : p.tint(leaf, toward: 0x446A5D, amount: 0.18))
            }
            for i in 0..<3 {
                var bark = Path()
                let x = CGFloat(i) * 5 - 5
                bark.move(to: CGPoint(x: x, y: -61 + CGFloat(i) * 8))
                bark.addQuadCurve(to: CGPoint(x: x - 3, y: -9), control: CGPoint(x: x + 6, y: -31))
                p.context.stroke(bark, with: .color(Color(dinoHex: 0xD9C7A6).opacity(0.55)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
            }
            p.ellipse(CGRect(x: -1, y: -37, width: 4, height: 7), 0x6F817D, opacity: 0.30)
            p.sprig(at: CGPoint(x: -21, y: 9), size: 0.5, color: leaf)
        }
    }
    private func rock(at point: CGPoint, size: CGFloat, color: UInt32, variation: Int = 0) {
        at(point, size: size) { p in
            p.shadow(width: 71)
            let skew = CGFloat(variation % 3 - 1) * 5
            let vertices = [CGPoint(x: -37, y: -3), CGPoint(x: -32 + skew, y: -28), CGPoint(x: -12 - skew, y: -49),
                            CGPoint(x: 17 + skew, y: -43 - skew), CGPoint(x: 34, y: -21), CGPoint(x: 29, y: 0), CGPoint(x: 4, y: 6)]
            var path = Path()
            path.addLines(vertices); path.closeSubpath()
            p.material(path, rect: CGRect(x: -37, y: -49, width: 71, height: 55), color: color)
            p.polygon([vertices[2], vertices[3], CGPoint(x: 7, y: -20), vertices[1]], color: 0xFFFFFF, opacity: 0.15)
            p.polygon([vertices[3], vertices[4], vertices[5], CGPoint(x: 7, y: -20)], color: p.colors.shade, opacity: 0.15)
            p.line([CGPoint(x: -17, y: -13), CGPoint(x: -4, y: -18), CGPoint(x: 5, y: -13)], color: p.colors.shade, width: 1)
            p.line([vertices[1], vertices[2], vertices[3]], color: 0xE6EBDD, width: 0.9)
            for i in 0..<5 {
                let x = CGFloat((i * 11 + variation * 7) % 40 - 21), y = CGFloat((i * 7) % 19 - 25)
                p.ellipse(CGRect(x: x, y: y, width: 1.8, height: 1.4), 0xEDF4DD, opacity: 0.27)
            }
        }
    }
    private func fence(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for y: CGFloat in [-16, -7] { p.line([CGPoint(x: -59, y: y), CGPoint(x: 56, y: y)], color: 0xD9C399, width: 4) }
            for i in 0..<7 {
                let x = CGFloat(i) * 18 - 56
                p.rounded(CGRect(x: x, y: -26, width: 6, height: 29), radius: 3, color: 0xF6E9CA)
            }
        }
    }
    private func planter(at point: CGPoint, size: CGFloat, flowers: Bool) {
        at(point, size: size) { p in
            p.shadow(width: 45)
            p.rounded(CGRect(x: -22, y: -18, width: 44, height: 20), radius: 5, color: 0xD1BCA2)
            p.rounded(CGRect(x: -24, y: -20, width: 48, height: 6), radius: 3, color: 0xE5D7B9)
            p.sprig(at: CGPoint(x: 0, y: -17), size: 0.84, color: 0x92B58D)
            if flowers { p.blossoms(at: CGPoint(x: 0, y: -16), size: 0.70, color: 0xEEACA6) }
        }
    }
    private func clockPost(at point: CGPoint, time: ClockTime, size: CGFloat, digital: Bool = false) {
        at(point, size: size) { p in
            p.shadow(width: 39)
            p.rounded(CGRect(x: -5, y: -72, width: 10, height: 70), radius: 4, color: 0xC7AC7B)
            p.rounded(CGRect(x: -18, y: -3, width: 36, height: 7), radius: 3, color: 0xD9C399)
            p.clock(at: CGPoint(x: 0, y: -72), time: time, size: 26, digital: digital)
            if digital { p.line([CGPoint(x: -24, y: -8), CGPoint(x: 24, y: -8)], color: 0xC7AC7B, width: 3) }
        }
    }
    private func lamp(at point: CGPoint, size: CGFloat, night: Bool) {
        at(point, size: size) { p in
            p.line([.zero, CGPoint(x: 0, y: -80), CGPoint(x: -9, y: -84)], color: 0x678E97, width: 5)
            p.rounded(CGRect(x: -18, y: -85, width: 22, height: 9), radius: 4, color: 0xD9B46C)
            p.ellipse(CGRect(x: -14, y: -80, width: 14, height: 5), 0xFFF1B8)
            p.rounded(CGRect(x: -9, y: -3, width: 18, height: 6), radius: 3, color: 0x789BA1)
            if night { p.glow(at: CGPoint(x: -7, y: -75), radius: 30, color: 0xFFF1B8, opacity: 0.25) }
        }
    }
    private func bench(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.shadow(width: 53)
            p.rounded(CGRect(x: -25, y: -25, width: 50, height: 13), radius: 3, color: 0xC7AC7B)
            p.rounded(CGRect(x: -28, y: -11, width: 56, height: 7), radius: 3, color: 0xD9B46C)
            for x: CGFloat in [-20, 20] { p.line([CGPoint(x: x, y: -4), CGPoint(x: x, y: 4)], color: 0x678E97, width: 3) }
        }
    }
    private func machineBase(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.volume(CGRect(x: -59, y: -14, width: 118, height: 27), color: 0xB7BDC2)
            p.volume(CGRect(x: -59, y: -21, width: 118, height: 27), color: 0xE5D5B4)
            for x: CGFloat in [-42, 0, 42] { p.ellipse(CGRect(x: x - 2, y: -6, width: 4, height: 4), 0x978669) }
            p.line([CGPoint(x: -51, y: -4), CGPoint(x: -61, y: -4), CGPoint(x: -61, y: -45)], color: 0xD9B46C, width: 5)
        }
    }
    private func jetty(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.shadow(width: 122)
            for i in 0..<6 {
                p.rounded(CGRect(x: -57, y: -28 + CGFloat(i) * 6, width: 114, height: 5), radius: 2, color: i.isMultiple(of: 2) ? 0xC9A977 : 0xDABB88)
                p.line([CGPoint(x: -40, y: -26 + CGFloat(i) * 6), CGPoint(x: -19, y: -26 + CGFloat(i) * 6)], color: 0xA78B66, width: 0.7)
            }
            for x: CGFloat in [-48, 48] {
                p.rounded(CGRect(x: x - 4, y: -32, width: 8, height: 40), radius: 3, color: 0xA78B66)
                p.ellipse(CGRect(x: x - 5, y: -35, width: 10, height: 5), 0xE9CE99)
            }
        }
    }
    private func chest(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.shadow(width: 57)
            p.rounded(CGRect(x: -27, y: -31, width: 54, height: 32), radius: 6, color: 0xAE825F)
            p.rounded(CGRect(x: -28, y: -42, width: 56, height: 22), radius: 10, color: 0xC8A077)
            for x: CGFloat in [-20, 16] { p.rounded(CGRect(x: x, y: -38, width: 5, height: 39), radius: 2, color: 0xE8C66D) }
            p.line([CGPoint(x: -25, y: -20), CGPoint(x: 25, y: -20)], color: 0x775F54, width: 2)
            p.rounded(CGRect(x: -6, y: -25, width: 12, height: 13), radius: 3, color: 0xE8C66D)
            p.ellipse(CGRect(x: -1.5, y: -21, width: 3, height: 5), 0x775F54)
        }
    }
    private func castleWall(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -40, y: -29, width: 80, height: 31), radius: 3, color: 0xE2D9C4)
            for i in 0..<5 {
                let x = CGFloat(i) * 17 - 40
                p.rounded(CGRect(x: x, y: -37, width: 10, height: 15), radius: 2, color: 0xF4EBDA)
                p.line([CGPoint(x: x, y: -9), CGPoint(x: x + 11, y: -9)], color: 0xC6C2B7, width: 1)
            }
        }
    }

    private func at(_ point: CGPoint, size: CGFloat, draw: (ThemePainter) -> Void) {
        var c = context
        c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: size, y: size)
        draw(ThemePainter(context: c, colors: colors))
    }
    func ellipse(_ rect: CGRect, _ hex: UInt32, opacity: Double = 1) {
        context.fill(Path(ellipseIn: rect), with: .color(Color(dinoHex: hex).opacity(opacity)))
    }
    private func material(_ path: Path, rect: CGRect, color: UInt32) {
        context.fill(path, with: .linearGradient(Gradient(stops: [
            .init(color: tint(color, toward: 0xFFFFFF, amount: 0.30), location: 0),
            .init(color: Color(dinoHex: color), location: 0.48),
            .init(color: tint(color, toward: colors.shade, amount: 0.28), location: 1)
        ]), startPoint: CGPoint(x: rect.minX, y: rect.minY),
            endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
    }
    private func tint(_ hex: UInt32, toward other: UInt32, amount: CGFloat) -> Color {
        WorldLandscapePalette(ground: hex, distant: hex, foliage: hex, shade: hex, rock: hex)
            .color(\.ground, toward: .init(ground: other, distant: other, foliage: other, shade: other, rock: other), progress: amount)
    }
    private func rounded(_ rect: CGRect, radius: CGFloat, color: UInt32) {
        material(Path(roundedRect: rect, cornerRadius: radius), rect: rect, color: color)
    }
    private func volume(_ rect: CGRect, color: UInt32) {
        context.fill(Path(ellipseIn: rect), with: .radialGradient(Gradient(stops: [
            .init(color: tint(color, toward: 0xFFFFFF, amount: 0.33), location: 0),
            .init(color: Color(dinoHex: color), location: 0.48),
            .init(color: tint(color, toward: colors.shade, amount: 0.30), location: 1)
        ]), center: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY + rect.height * 0.22),
             startRadius: 0, endRadius: max(rect.width, rect.height) * 0.85))
    }
    private func polygon(_ points: [CGPoint], color: UInt32, opacity: Double = 1) {
        guard let first = points.first else { return }
        var path = Path()
        path.move(to: first)
        points.dropFirst().forEach { path.addLine(to: $0) }
        path.closeSubpath()
        context.fill(path, with: .color(Color(dinoHex: color).opacity(opacity)))
    }
    private func line(_ points: [CGPoint], color: UInt32, width: CGFloat) {
        guard let first = points.first else { return }
        var path = Path()
        path.move(to: first)
        points.dropFirst().forEach { path.addLine(to: $0) }
        context.stroke(path, with: .color(Color(dinoHex: color)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func shadow(width: CGFloat = 98) {
        ellipse(CGRect(x: -width / 2, y: -6, width: width, height: 17), colors.shade, opacity: 0.14)
    }

    func star(at point: CGPoint, radius: CGFloat, color: UInt32) {
        let points = (0..<10).map { index -> CGPoint in
            let angle = Double(index) * .pi / 5 - .pi / 2
            let r = index.isMultiple(of: 2) ? radius : radius * 0.46
            return CGPoint(x: point.x + CGFloat(cos(angle)) * r, y: point.y + CGFloat(sin(angle)) * r)
        }
        polygon(points, color: color)
    }
    func moon(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            var crescent = Path()
            crescent.move(to: CGPoint(x: 15, y: -31))
            crescent.addCurve(to: CGPoint(x: 29, y: 23), control1: CGPoint(x: -47, y: -39), control2: CGPoint(x: -51, y: 47))
            crescent.addCurve(to: CGPoint(x: 15, y: -31), control1: CGPoint(x: -10, y: 23), control2: CGPoint(x: -17, y: -13))
            crescent.closeSubpath()
            p.material(crescent, rect: CGRect(x: -34, y: -34, width: 68, height: 68), color: 0xFFF1B8)
            p.star(at: CGPoint(x: 40, y: -15), radius: 6, color: 0xFFF1B8)
        }
    }
    func clock(at point: CGPoint, time: ClockTime, size: CGFloat, digital: Bool = false) {
        ellipse(CGRect(x: point.x - size - 3, y: point.y - size + 3, width: size * 2 + 6, height: size * 2 + 6), colors.shade, opacity: 0.15)
        ellipse(CGRect(x: point.x - size - 3, y: point.y - size - 3, width: size * 2 + 6, height: size * 2 + 6), colors.accent)
        ellipse(CGRect(x: point.x - size, y: point.y - size, width: size * 2, height: size * 2), 0xFFF6DD)
        context.stroke(Path(ellipseIn: CGRect(x: point.x - size + 2, y: point.y - size + 2, width: size * 2 - 4, height: size * 2 - 4)),
                       with: .color(.white.opacity(0.65)), lineWidth: 1)
        for index in 0..<12 {
            let angle = Double(index) * .pi / 6
            let a = CGPoint(x: point.x + CGFloat(sin(angle)) * size * 0.81, y: point.y - CGFloat(cos(angle)) * size * 0.81)
            let b = CGPoint(x: point.x + CGFloat(sin(angle)) * size * 0.91, y: point.y - CGFloat(cos(angle)) * size * 0.91)
            line([a, b], color: colors.shade, width: 1.4)
        }
        for (angle, length, width) in [(time.hourAngle, size * 0.49, CGFloat(3)), (time.minuteAngle, size * 0.73, CGFloat(2))] {
            let radians = angle * .pi / 180
            line([point, CGPoint(x: point.x + CGFloat(sin(radians)) * length, y: point.y - CGFloat(cos(radians)) * length)], color: colors.shade, width: width)
        }
        ellipse(CGRect(x: point.x - 2.5, y: point.y - 2.5, width: 5, height: 5), colors.shade)
        if digital {
            let rect = CGRect(x: point.x - 27, y: point.y + size + 7, width: 54, height: 24)
            rounded(rect, radius: 6, color: colors.shade)
            context.draw(Text(verbatim: time.digitalText).font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(dinoHex: 0xFFF1B8)), at: CGPoint(x: rect.midX, y: rect.midY))
        }
    }
    func pond(at point: CGPoint, size: CGFloat, lava: Bool) {
        at(point, size: size) { p in
            p.ellipse(CGRect(x: -73, y: -28, width: 146, height: 53), p.colors.shade, opacity: 0.14)
            p.volume(CGRect(x: -68, y: -29, width: 136, height: 45), color: lava ? 0xF47C65 : 0x79BBC7)
            p.volume(CGRect(x: -50, y: -26, width: 100, height: 31), color: lava ? 0xFFC857 : 0xA4DDE0)
            p.line([CGPoint(x: -35, y: -14), CGPoint(x: -7, y: -14)], color: lava ? 0xFFF1B8 : 0xE6F9EE, width: 2)
            p.line([CGPoint(x: 6, y: 0), CGPoint(x: 31, y: 0)], color: lava ? 0xFFF1B8 : 0xE6F9EE, width: 2)
            p.rock(at: CGPoint(x: 47, y: 14), size: 0.55, color: lava ? 0x887F8D : 0xA8B9B0)
            p.rock(at: CGPoint(x: 20, y: 17), size: 0.26, color: lava ? 0x96868C : 0xB8C8B4)
            for i in 0..<5 {
                let x = CGFloat(i) * 17 - 43, y = CGFloat(i % 2) * 9 - 16
                var ripple = Path()
                ripple.move(to: CGPoint(x: x, y: y))
                ripple.addQuadCurve(to: CGPoint(x: x + 13, y: y), control: CGPoint(x: x + 6, y: y + 2.5))
                p.context.stroke(ripple, with: .color(Color(dinoHex: lava ? 0xFFE4AD : 0xDBF4E7).opacity(0.60)),
                                 style: StrokeStyle(lineWidth: 1, lineCap: .round))
            }
            if !lava {
                p.volume(CGRect(x: -29, y: -14, width: 17, height: 7), color: 0x91B97E)
                p.polygon([CGPoint(x: -21, y: -12), CGPoint(x: -15, y: -15), CGPoint(x: -15, y: -9)], color: 0xB5E3C8)
                p.blossoms(at: CGPoint(x: -21, y: -12), size: 0.24, color: 0xE3BCCF)
                for i in 0..<4 {
                    let x = CGFloat(i) * 6 - 54
                    p.line([CGPoint(x: x, y: -1), CGPoint(x: x + 3, y: -18 - CGFloat(i % 2) * 9)], color: 0x88A78F, width: 1.3)
                }
            }
        }
    }
    func crystals(at point: CGPoint, size: CGFloat, variation: Int = 0) {
        at(point, size: size) { p in
            p.shadow(width: 96)
            for (index, data) in [(-26.0, 48.0), (0.0, 76.0), (25.0, 54.0)].enumerated() {
                let x = CGFloat(data.0), h = CGFloat(data.1) * (1 + CGFloat((variation + index) % 3 - 1) * 0.16)
                let tint: UInt32 = index == 1 ? 0xA493D7 : index == 0 ? 0x79D8D0 : 0xF1BCD9
                p.polygon([CGPoint(x: x - 13, y: -h * 0.70), CGPoint(x: x, y: -h), CGPoint(x: x + 15, y: -h * 0.72),
                           CGPoint(x: x + 12, y: -6), CGPoint(x: x, y: 0), CGPoint(x: x - 12, y: -8)], color: tint)
                p.polygon([CGPoint(x: x, y: -h), CGPoint(x: x + 15, y: -h * 0.72), CGPoint(x: x + 12, y: -6), CGPoint(x: x, y: 0)],
                          color: p.colors.shade, opacity: 0.23)
                p.polygon([CGPoint(x: x - 13, y: -h * 0.70), CGPoint(x: x, y: -h),
                           CGPoint(x: x, y: -h * 0.55)], color: 0xFFFFFF, opacity: 0.24)
                p.line([CGPoint(x: x - 11, y: -h * 0.69), CGPoint(x: x, y: -h + 2), CGPoint(x: x + 13, y: -h * 0.71)], color: 0xEDFFF0, width: 0.8)
                p.line([CGPoint(x: x - 10, y: -11), CGPoint(x: x, y: -5), CGPoint(x: x + 10, y: -9)], color: 0xF1F5E8, width: 0.8)
                p.line([CGPoint(x: x - 5, y: -h * 0.71), CGPoint(x: x - 5, y: -15)], color: 0xF2FBF6, width: 2)
                p.star(at: CGPoint(x: x - 7, y: -h * 0.65), radius: 3.3, color: 0xF2FBF6)
            }
        }
    }
    private func volcano(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.shadow(width: 135)
            var mountain = Path()
            mountain.move(to: CGPoint(x: -62, y: 0))
            mountain.addQuadCurve(to: CGPoint(x: -20, y: -86), control: CGPoint(x: -37, y: -50))
            mountain.addQuadCurve(to: CGPoint(x: 21, y: -86), control: CGPoint(x: 0, y: -96))
            mountain.addQuadCurve(to: CGPoint(x: 65, y: 0), control: CGPoint(x: 36, y: -48))
            mountain.closeSubpath()
            p.context.fill(mountain, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xD7987A), Color(dinoHex: 0x706778)]),
                                                            startPoint: CGPoint(x: -20, y: -85), endPoint: CGPoint(x: 45, y: 0)))
            p.polygon([CGPoint(x: -20, y: -86), CGPoint(x: -31, y: -48), CGPoint(x: -55, y: -6),
                       CGPoint(x: -30, y: -8), CGPoint(x: -13, y: -47)], color: 0xE4B69B, opacity: 0.35)
            for i in 0..<3 {
                let y = CGFloat(i) * 17 - 49
                p.line([CGPoint(x: 15, y: y), CGPoint(x: 28 + CGFloat(i) * 6, y: y + 5)], color: 0x887786, width: 1.4)
            }
            p.ellipse(CGRect(x: -23, y: -93, width: 46, height: 16), 0x706778)
            p.ellipse(CGRect(x: -15, y: -90, width: 30, height: 10), 0xFFC857)
            p.line([CGPoint(x: 4, y: -81), CGPoint(x: -5, y: -57), CGPoint(x: 8, y: -31), CGPoint(x: 1, y: -8)], color: 0xF47C65, width: 10)
            p.line([CGPoint(x: 4, y: -81), CGPoint(x: -5, y: -57), CGPoint(x: 8, y: -31)], color: 0xFFC857, width: 4)
            p.ellipse(CGRect(x: -10, y: -115, width: 27, height: 14), 0xFFF0D6, opacity: 0.48)
            p.ellipse(CGRect(x: 7, y: -133, width: 34, height: 18), 0xFFF0D6, opacity: 0.33)
        }
    }
    func building(at point: CGPoint, size: CGFloat, city: Bool, tower: Bool = false, variation: Int = 0) {
        at(point, size: size) { p in
            let h: CGFloat = tower ? (city ? 154 : 123) : city ? 110 : 77
            p.shadow()
            p.rounded(CGRect(x: -36, y: -h, width: 72, height: h), radius: city ? 15 : 28,
                      color: city ? 0xA9DAE3 : [UInt32(0xF0DFBA), 0xF3E2C5, 0xE6D9BC][variation % 3])
            p.polygon([CGPoint(x: 20, y: -h), CGPoint(x: 36, y: -h + 12), CGPoint(x: 36, y: -4), CGPoint(x: 20, y: 0)],
                      color: p.colors.shade, opacity: 0.15)
            var roof = Path()
            roof.move(to: CGPoint(x: -43, y: -h + 5))
            roof.addQuadCurve(to: CGPoint(x: 0, y: -h - 23), control: CGPoint(x: -18, y: -h - 33))
            roof.addQuadCurve(to: CGPoint(x: 43, y: -h + 5), control: CGPoint(x: 19, y: -h - 33))
            roof.closeSubpath()
            if city {
                p.rounded(CGRect(x: -41, y: -h - 7, width: 82, height: 14), radius: 6, color: 0x54BCC5)
                p.rounded(CGRect(x: -28, y: -h - 15, width: 56, height: 10), radius: 4, color: 0x91BC96)
                p.sprig(at: CGPoint(x: -13, y: -h - 14), size: 0.35, color: 0x91BC96)
            } else {
                p.material(roof, rect: CGRect(x: -43, y: -h - 28, width: 86, height: 34), color: p.colors.accent)
                p.line([CGPoint(x: -39, y: -h + 4), CGPoint(x: 39, y: -h + 4)], color: 0xB37759, width: 3)
                for i in 0..<4 {
                    let x = CGFloat(i) * 17 - 25
                    p.line([CGPoint(x: x, y: -h - 15 + abs(x) * 0.22),
                            CGPoint(x: x - 2, y: -h + 1)], color: 0xF0B894, width: 1)
                }
                p.rounded(CGRect(x: 21, y: -h - 30, width: 11, height: 21), radius: 3, color: 0xD8B795)
                p.rounded(CGRect(x: 19, y: -h - 32, width: 15, height: 5), radius: 2, color: 0xEDD8B9)
            }
            p.rounded(CGRect(x: -12, y: -30, width: 24, height: 30), radius: 10, color: 0xA47757)
            p.ellipse(CGRect(x: 4, y: -15, width: 3, height: 3), 0xFFE2A1)
            for x: CGFloat in [-6, 0, 6] { p.line([CGPoint(x: x, y: -22), CGPoint(x: x, y: -5)], color: 0xC4A17A, width: 0.7) }
            p.rounded(CGRect(x: -16, y: -1, width: 32, height: 5), radius: 2, color: 0xDED0B2)
            p.rounded(CGRect(x: 25, y: -29, width: 8, height: 11), radius: 3, color: 0xC7A579)
            p.rounded(CGRect(x: 27, y: -27, width: 4, height: 6), radius: 1, color: 0xFFEDB1)
            if tower {
                p.clock(at: CGPoint(x: 0, y: -h + 33), time: .init(hour: city ? 8 : 5, minute: city ? 5 : 20), size: 21, digital: city)
                if city { p.window(at: CGPoint(x: -8, y: -51), size: 1) }
            } else {
                for x in [-22.0, 14.0] {
                    for y in city ? [-80.0, -51.0] : [-53.0] {
                        p.window(at: CGPoint(x: CGFloat(x), y: CGFloat(y)), size: 1)
                    }
                }
            }
            for i in 0..<3 {
                p.line([CGPoint(x: -31, y: -38 + CGFloat(i) * 11), CGPoint(x: -19, y: -38 + CGFloat(i) * 11)],
                       color: city ? 0x88B8C8 : 0xDBC9A9, width: 1)
            }
            if !city && !tower {
                p.ellipse(CGRect(x: -6, y: -h - 12, width: 12, height: 10), 0xFFF0BF)
                p.line([CGPoint(x: 0, y: -h - 12), CGPoint(x: 0, y: -h - 2)], color: 0xD4B88A, width: 1)
                p.line([CGPoint(x: -5, y: -h - 7), CGPoint(x: 5, y: -h - 7)], color: 0xD4B88A, width: 1)
                p.planter(at: CGPoint(x: -24, y: -28), size: 0.38, flowers: true)
                for x: CGFloat in [-28, 32] { p.rounded(CGRect(x: x, y: -56, width: 5, height: 23), radius: 2, color: 0xA2B78E) }
            }
        }
    }
    private func window(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -2, y: -1, width: 20, height: 22), radius: 6, color: 0xD4C4A5)
            p.rounded(CGRect(x: 0, y: 0, width: 16, height: 18), radius: 5, color: 0xFFE9A5)
            p.line([CGPoint(x: 8, y: 0), CGPoint(x: 8, y: 18)], color: 0xFFF5D3, width: 1.4)
            p.line([CGPoint(x: 0, y: 9), CGPoint(x: 16, y: 9)], color: 0xFFF5D3, width: 1.4)
            p.line([CGPoint(x: 3, y: 3), CGPoint(x: 6, y: 5)], color: 0xFFFFFF, width: 1)
            p.rounded(CGRect(x: -3, y: 19, width: 22, height: 3), radius: 1.5, color: 0xE9DABB)
        }
    }
    func tram(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.shadow(width: 122)
            for y: CGFloat in [4, 10] { p.line([CGPoint(x: -69, y: y), CGPoint(x: 69, y: y)], color: 0x8BA8AB, width: 2) }
            p.rounded(CGRect(x: -53, y: -54, width: 106, height: 45), radius: 14, color: 0xFFE08A)
            p.rounded(CGRect(x: -57, y: -60, width: 114, height: 13), radius: 6, color: 0x54BCC5)
            for x in [-37.0, -8.0, 22.0] {
                p.rounded(CGRect(x: CGFloat(x), y: -43, width: 22, height: 22), radius: 5, color: 0xAAD9EB)
            }
            for x in [-36.0, 29.0] {
                p.volume(CGRect(x: CGFloat(x), y: -15, width: 17, height: 17), color: p.colors.shade)
                p.ellipse(CGRect(x: CGFloat(x) + 5, y: -10, width: 7, height: 7), 0xBDD4D2)
            }
            p.line([CGPoint(x: -47, y: -17), CGPoint(x: 47, y: -17)], color: 0xEFAD67, width: 3)
            p.ellipse(CGRect(x: 41, y: -31, width: 6, height: 6), 0xFFF1B8)
        }
    }
    func castleTower(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.shadow(width: 110)
            p.rounded(CGRect(x: -34, y: -123, width: 68, height: 123), radius: 14, color: 0xF0E6D3)
            p.polygon([CGPoint(x: 17, y: -123), CGPoint(x: 34, y: -117), CGPoint(x: 34, y: -5),
                       CGPoint(x: 17, y: 0)], color: 0x8D867A, opacity: 0.16)
            p.rounded(CGRect(x: -41, y: -124, width: 82, height: 14), radius: 4, color: 0xF4EBDA)
            for x in [-35.0, -8.0, 19.0] {
                p.rounded(CGRect(x: CGFloat(x), y: -140, width: 16, height: 24), radius: 3, color: 0xF4EBDA)
            }
            p.line([CGPoint(x: 1, y: -142), CGPoint(x: 1, y: -177)], color: 0xD9B46C, width: 3)
            p.polygon([CGPoint(x: 2, y: -177), CGPoint(x: 31, y: -171), CGPoint(x: 22, y: -157),
                       CGPoint(x: 2, y: -163)], color: 0x789BCF)
            p.clock(at: CGPoint(x: 0, y: -82), time: .init(hour: 10, minute: 25), size: 22)
            p.rounded(CGRect(x: -14, y: -40, width: 28, height: 40), radius: 14, color: 0x789BCF)
            for y in [-49.0, -12.0] {
                p.line([CGPoint(x: -32, y: CGFloat(y)), CGPoint(x: -19, y: CGFloat(y))], color: 0xC6C2B7, width: 1.5)
                p.line([CGPoint(x: 20, y: CGFloat(y) - 8), CGPoint(x: 31, y: CGFloat(y) - 8)], color: 0xC6C2B7, width: 1.5)
            }
            for i in 0..<4 {
                let y = CGFloat(i) * 22 - 114
                p.line([CGPoint(x: -31, y: y), CGPoint(x: -21, y: y)], color: 0xD8CFBA, width: 1)
                p.line([CGPoint(x: 19, y: y + 10), CGPoint(x: 31, y: y + 10)], color: 0xCEC5B3, width: 1)
            }
            p.rounded(CGRect(x: -19, y: -2, width: 38, height: 6), radius: 2, color: 0xD7CAB2)
            p.polygon([CGPoint(x: -28, y: -49), CGPoint(x: -15, y: -49), CGPoint(x: -15, y: -31),
                       CGPoint(x: -22, y: -36), CGPoint(x: -28, y: -31)], color: 0x789BCF)
            p.line([CGPoint(x: -30, y: -51), CGPoint(x: -13, y: -51)], color: 0xD9B46C, width: 2)
        }
    }
    private func gear(at point: CGPoint, radius: CGFloat) {
        for index in 0..<12 {
            let angle = Double(index) * .pi / 6
            var c = context
            c.translateBy(x: point.x, y: point.y)
            c.rotate(by: .radians(angle))
            c.fill(Path(roundedRect: CGRect(x: -5, y: -radius - 4, width: 10, height: 12), cornerRadius: 3),
                   with: .color(Color(dinoHex: 0xD9B46C)))
        }
        var ring = Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
        ring.addEllipse(in: CGRect(x: point.x - radius * 0.51, y: point.y - radius * 0.51, width: radius * 1.02, height: radius * 1.02))
        context.fill(ring, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xF2DDA1), Color(dinoHex: 0xC6A261)]),
                                               startPoint: CGPoint(x: point.x - radius, y: point.y - radius),
                                               endPoint: CGPoint(x: point.x + radius, y: point.y + radius)),
                     style: FillStyle(eoFill: true))
        context.stroke(Path(ellipseIn: CGRect(x: point.x - radius * 0.84, y: point.y - radius * 0.84, width: radius * 1.68, height: radius * 1.68)),
                       with: .color(Color(dinoHex: 0xFFF1C3).opacity(0.6)), lineWidth: 1)
        for index in 0..<4 {
            let angle = Double(index) * .pi / 2 + .pi / 4
            ellipse(CGRect(x: point.x + CGFloat(cos(angle)) * radius * 0.71 - 1.6,
                           y: point.y + CGFloat(sin(angle)) * radius * 0.71 - 1.6, width: 3.2, height: 3.2), 0xA38E68)
        }
    }
    func portal(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.shadow(width: 104)
            p.glow(at: CGPoint(x: 0, y: -55), radius: 67, color: 0xAAEADA, opacity: 0.24)
            let rect = CGRect(x: -38, y: -106, width: 76, height: 107)
            p.rounded(rect, radius: 38, color: 0xD9B46C)
            p.rounded(rect.insetBy(dx: 8, dy: 8), radius: 32, color: 0x7EDDD0)
            p.rounded(rect.insetBy(dx: 16, dy: 15), radius: 26, color: 0xB5A6E6)
            p.context.drawLayer { layer in
                layer.clip(to: Path(roundedRect: rect.insetBy(dx: 16, dy: 15), cornerRadius: 26))
                for i in 0..<3 {
                    var orbit = Path()
                    orbit.addArc(center: CGPoint(x: 0, y: -54), radius: CGFloat(14 + i * 11),
                                 startAngle: .degrees(Double(i * 42)), endAngle: .degrees(Double(i * 42 + 235)), clockwise: false)
                    layer.stroke(orbit, with: .color(Color(dinoHex: 0xD4F4E8).opacity(0.56)),
                                 style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                }
            }
            for x: CGFloat in [-31, 31] {
                for y: CGFloat in [-80, -47, -15] { p.ellipse(CGRect(x: x - 2, y: y, width: 4, height: 4), 0xFFF1C3) }
            }
            p.star(at: CGPoint(x: -11, y: -70), radius: 7, color: 0xFFF1D3)
            p.star(at: CGPoint(x: 13, y: -41), radius: 5, color: 0xFFF1D3)
            p.gear(at: CGPoint(x: 32, y: -13), radius: 19)
            p.rounded(CGRect(x: -44, y: -3, width: 88, height: 10), radius: 4, color: 0xC7AC7B)
        }
    }
    private func hourglass(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.polygon([CGPoint(x: -21, y: -59), CGPoint(x: 21, y: -59), CGPoint(x: 3, y: -32),
                       CGPoint(x: 21, y: -7), CGPoint(x: -21, y: -7), CGPoint(x: -3, y: -32)], color: 0xAAD9EB, opacity: 0.8)
            p.polygon([CGPoint(x: -16, y: -56), CGPoint(x: 16, y: -56), CGPoint(x: 0, y: -37)], color: 0xFFE08A)
            p.polygon([CGPoint(x: -17, y: -10), CGPoint(x: 17, y: -10), CGPoint(x: 0, y: -29)], color: 0xFFE08A)
            for x in [-23.0, 23.0] { p.line([CGPoint(x: CGFloat(x), y: -62), CGPoint(x: CGFloat(x), y: -3)], color: 0xA47757, width: 4) }
            p.rounded(CGRect(x: -28, y: -67, width: 56, height: 9), radius: 4, color: 0xD9B46C)
            p.rounded(CGRect(x: -28, y: -7, width: 56, height: 9), radius: 4, color: 0xD9B46C)
            p.line([CGPoint(x: -15, y: -50), CGPoint(x: -6, y: -37)], color: 0xFFFFFF, width: 1.5)
            p.line([CGPoint(x: -15, y: -17), CGPoint(x: -8, y: -25)], color: 0xFFFFFF, width: 1.2)
            p.line([CGPoint(x: 0, y: -34), CGPoint(x: 0, y: -22)], color: 0xFFE08A, width: 1)
        }
    }
    func ship(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.pond(at: .zero, size: 0.90, lava: false)
            var hull = Path()
            hull.move(to: CGPoint(x: -61, y: -25))
            hull.addQuadCurve(to: CGPoint(x: 49, y: -25), control: CGPoint(x: 0, y: 20))
            hull.addLine(to: CGPoint(x: 62, y: -44))
            hull.addQuadCurve(to: CGPoint(x: -61, y: -44), control: CGPoint(x: 0, y: -32))
            hull.closeSubpath()
            p.context.fill(hull, with: .color(Color(dinoHex: 0xA47757)))
            p.line([CGPoint(x: -55, y: -43), CGPoint(x: 3, y: -37), CGPoint(x: 57, y: -44)], color: 0xE0BE89, width: 3)
            for i in 0..<3 {
                let y = CGFloat(i) * 4 - 28
                p.line([CGPoint(x: -29 + CGFloat(i) * 4, y: y), CGPoint(x: 29 - CGFloat(i) * 4, y: y)], color: 0xC29770, width: 1)
            }
            p.line([CGPoint(x: 0, y: -37), CGPoint(x: 0, y: -139)], color: 0xA47757, width: 5)
            var sail = Path()
            sail.move(to: CGPoint(x: 5, y: -132))
            sail.addQuadCurve(to: CGPoint(x: 48, y: -68), control: CGPoint(x: 56, y: -109))
            sail.addQuadCurve(to: CGPoint(x: 5, y: -70), control: CGPoint(x: 28, y: -60))
            sail.closeSubpath()
            p.context.fill(sail, with: .color(Color(dinoHex: 0xFFF1D3)))
            p.line([CGPoint(x: 0, y: -132), CGPoint(x: -43, y: -42)], color: 0xD4BE95, width: 1.3)
            p.line([CGPoint(x: 8, y: -112), CGPoint(x: 31, y: -86), CGPoint(x: 39, y: -71)], color: 0xE8DAC2, width: 1.5)
            p.clock(at: CGPoint(x: 21, y: -94), time: .init(hour: 9, minute: 30), size: 10)
            p.polygon([CGPoint(x: 0, y: -140), CGPoint(x: 29, y: -132), CGPoint(x: 0, y: -122)], color: 0xEF927B)
            for x in [-36.0, -10.0, 16.0] { p.ellipse(CGRect(x: CGFloat(x), y: -33, width: 11, height: 11), 0xD9B46C) }
        }
    }
    private func mushroom(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rounded(CGRect(x: -8, y: -28, width: 16, height: 31), radius: 6, color: 0xF5E6C7)
            var cap = Path()
            cap.move(to: CGPoint(x: -29, y: -23))
            cap.addQuadCurve(to: CGPoint(x: 29, y: -23), control: CGPoint(x: 0, y: -76))
            cap.addQuadCurve(to: CGPoint(x: -29, y: -23), control: CGPoint(x: 0, y: -12))
            p.context.fill(cap, with: .color(Color(dinoHex: 0xAA99CC)))
            p.material(cap, rect: CGRect(x: -29, y: -51, width: 58, height: 34), color: 0xAA99CC)
            p.line([CGPoint(x: -20, y: -22), CGPoint(x: 0, y: -18), CGPoint(x: 20, y: -22)], color: 0x8C8CA7, width: 1.4)
            p.glow(at: CGPoint(x: 0, y: -31), radius: 24, color: 0xFFF1B8, opacity: 0.10)
            for x in [-13.0, 5.0] { p.ellipse(CGRect(x: CGFloat(x), y: -39, width: 9, height: 7), 0xFFF1B8) }
            p.ellipse(CGRect(x: -3, y: -28, width: 5, height: 4), 0xFFF1B8)
        }
    }

    func boss(worldID: Int, at point: CGPoint, size: CGFloat) {
        WorldBossPainter(context: context).draw(worldID: worldID, at: point, size: size)
    }
}
