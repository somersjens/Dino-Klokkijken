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
        let ornamentScale = min(1.10, layout.scale)
        let ornamentY = 180 - 70 * ornamentScale
        for side in 0..<2 {
            transformed(at: CGPoint(x: side == 0 ? 54 * layout.scale : size.width - 54 * layout.scale, y: ornamentY),
                        scale: ornamentScale, mirror: side == 1) {
                $0.endcap(front: false, variation: side)
            }
        }
        // Seat the rear posts in the bottom rail; the foreground leaves, stone
        // heels and shells then wrap over it without being sliced by its bevel.
        lowerMoulding(layout: layout)
        // The quiet lettering surface occludes the inward parts of the ornaments.
        // They grow out of the frame instead of sitting over the lettering.
        board(in: layout.titlePanel)
        subtitle(in: layout.subtitle)
        tab(in: layout.tab)
        for side in 0..<2 {
            transformed(at: CGPoint(x: side == 0 ? 54 * layout.scale : size.width - 54 * layout.scale, y: ornamentY),
                        scale: ornamentScale, mirror: side == 1) {
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
        } else if world.id == 5 {
            context.stroke(rim, with: .color(Color(dinoHex: 0xBEE4E4)), lineWidth: 4)
            context.stroke(rim, with: .color(Color(dinoHex: 0xE9FFF5)), lineWidth: 1.2)
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
        }
    }

    private func lowerMoulding(layout: WorldBannerLayout) {
        let r = layout.plate
        // One low, continuous bevel seats the posts without turning upward
        // through the foliage. The outer silhouette supplies the curved corners.
        var lip = Path()
        lip.move(to: CGPoint(x: r.minX + 24, y: r.maxY - 8))
        lip.addCurve(to: CGPoint(x: r.maxX - 24, y: r.maxY - 8),
                     control1: CGPoint(x: r.midX - 35, y: r.maxY - 9),
                     control2: CGPoint(x: r.midX + 35, y: r.maxY - 9))
        lip.addQuadCurve(to: CGPoint(x: r.maxX - 29, y: r.maxY - 2), control: CGPoint(x: r.maxX - 23, y: r.maxY - 2))
        lip.addLine(to: CGPoint(x: r.minX + 29, y: r.maxY - 2))
        lip.addQuadCurve(to: CGPoint(x: r.minX + 24, y: r.maxY - 8), control: CGPoint(x: r.minX + 23, y: r.maxY - 2))
        lip.closeSubpath()
        material(lip, light: palette.tabLight, face: palette.rim, dark: palette.shade)
        var bevel = Path()
        bevel.move(to: CGPoint(x: r.minX + 28, y: r.maxY - 7.5))
        bevel.addQuadCurve(to: CGPoint(x: r.maxX - 28, y: r.maxY - 7.5), control: CGPoint(x: r.midX, y: r.maxY - 9))
        context.stroke(bevel, with: .color(Color(dinoHex: palette.light).opacity(0.8)),
                       style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
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
        case 1, 2, 4, 7:
            let night = world.id == 2 || (world.id == 7 && variation == 1)
            let light: UInt32 = night ? 0xD2E4DC : world.id == 4 ? 0xD7E596 : 0xD1E978
            let face: UInt32 = night ? 0x91B2BF : world.id == 4 ? 0x91B460 : 0x83B742
            let dark: UInt32 = night ? 0x526E98 : 0x386C40
            if !front {
                organicStem(night: night)
                foliage(light: light, face: face, dark: dark, count: 12)
                if world.id == 2 || world.id == 7 {
                    let center = CGPoint(x: -19, y: -42)
                    medallion(at: center, radius: 18, night: night)
                    if night { moon(at: center, radius: 13) }
                    else { sun(at: center, radius: 10) }
                }
                if world.id == 4 {
                    roof(at: CGPoint(x: -25, y: -22))
                    // The little village sign is nailed to the living wooden post.
                    line([CGPoint(x: -41, y: -23), CGPoint(x: -7, y: -23)], color: 0x856E4C, width: 2)
                    bunting(from: CGPoint(x: -40, y: -26), to: CGPoint(x: -7, y: -26))
                    for x: CGFloat in [-40, -7] { rivet(at: CGPoint(x: x, y: -26), radius: 1.5) }
                }
            } else {
                if world.id == 1 || world.id == 4 {
                    leaf(at: CGPoint(x: 1, y: -39), length: 30, width: 23, angle: -65,
                         light: light, face: face, dark: dark)
                }
                leaf(at: CGPoint(x: 5, y: 61), length: 39, width: 27, angle: -68,
                     light: light, face: face, dark: dark)
                leaf(at: CGPoint(x: -15, y: 47), length: 24, width: 19, angle: -150,
                     light: light, face: face, dark: dark)
                if world.id == 1 || world.id == 4 {
                    // The stems terminate inside the calyx of each flower.
                    let flowers: [CGPoint] = world.id == 4
                        ? [CGPoint(x: -27, y: 43), CGPoint(x: -17, y: 51), CGPoint(x: -8, y: 44)]
                        : [CGPoint(x: -19, y: 48)]
                    for (index, point) in flowers.enumerated() {
                        line([CGPoint(x: -9, y: 62), point], color: dark, width: 1.8)
                        blossom(at: point, size: world.id == 4 ? 0.65 : 0.85, pink: index == 1)
                    }
                }
            }
        case 3:
            if !front {
                sideHousing(light: 0xB1A49F, face: 0x79727C, dark: 0x494D60)
                // Basalt ridges share one root and terminate beneath the stone heel.
                for (x, height, width) in [(CGFloat(-32), CGFloat(91), CGFloat(19)), (-14, 112, 27), (2, 82, 20)] {
                    rock(at: CGPoint(x: x, y: 57), width: width, height: height)
                }
                // Short transverse fissures branch from the lava-bearing ridges.
                for (x, y) in [(CGFloat(-25), CGFloat(-12)), (-21, 21), (-6, 3)] {
                    line([CGPoint(x: x - 8, y: y - 3), CGPoint(x: x, y: y), CGPoint(x: x + 3, y: y + 8)],
                         color: 0x4C4F61, width: 1.1, opacity: 0.75)
                    line([CGPoint(x: x - 8, y: y - 4), CGPoint(x: x - 1, y: y - 1)],
                         color: 0xC4ACA0, width: 0.55, opacity: 0.75)
                }
            } else {
                ornamentFoot(light: 0xB6A799, face: 0x7F727A, dark: 0x535468)
                var seam = Path()
                seam.move(to: CGPoint(x: -35, y: 51))
                seam.addCurve(to: CGPoint(x: 6, y: 63), control1: CGPoint(x: -21, y: 44), control2: CGPoint(x: -9, y: 64))
                context.stroke(seam, with: .color(Color(dinoHex: 0xC17653)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                context.stroke(seam, with: .color(Color(dinoHex: 0xFFCD8E)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                line([CGPoint(x: -24, y: 53), CGPoint(x: -19, y: 61), CGPoint(x: -20, y: 67)], color: 0x5F5868, width: 1)
            }
        case 5:
            if !front {
                sideHousing(light: 0xE2F6F1, face: 0x9CC8D9, dark: 0x6B8EB7)
                // All three crystals grow from the same geode bed; their roots
                // are hidden by its curved front edge, including on small widths.
                for (x, height, width, color) in [(CGFloat(-34), CGFloat(86), CGFloat(20), UInt32(0x83C7D5)),
                                                (-15, 111, 25, 0xA9ACDB), (3, 77, 19, 0x8ACFC7)] {
                    shard(at: CGPoint(x: x, y: 55), width: width, height: height, color: color)
                }
                // The light catches actual facet intersections, not floating stars.
                line([CGPoint(x: -16, y: -55), CGPoint(x: -17, y: -39)], color: 0xFFFFFF, width: 1.1, opacity: 0.8)
            } else {
                ornamentFoot(light: 0xEEFCF3, face: 0xA6CDDA, dark: 0x6F91B8)
                // Facets are cut into a closed stone, rather than loose chips.
                polygon([CGPoint(x: -34, y: 49), CGPoint(x: -18, y: 43), CGPoint(x: -10, y: 57), CGPoint(x: -31, y: 65)],
                        light: 0xDFFAF0, face: 0xA4CADD, dark: 0x7D9EC5)
                polygon([CGPoint(x: -18, y: 43), CGPoint(x: -2, y: 48), CGPoint(x: 6, y: 65), CGPoint(x: -10, y: 57)],
                        light: 0xF1FFF9, face: 0xB4D9DF, dark: 0x85AEC8)
                line([CGPoint(x: -31, y: 65), CGPoint(x: -10, y: 57), CGPoint(x: 6, y: 65)], color: 0xEEFFF8, width: 0.9)
            }
        case 6:
            if !front {
                sideHousing(light: 0xE0F5ED, face: 0x8EBCC7, dark: 0x4E7B95)
                for i in 0..<3 { cityFin(at: CGPoint(x: -31 + CGFloat(i) * 17, y: 55), height: CGFloat(80 + (i == 1 ? 28 : 0))) }
                // A conduit returns into the housing at both ends.
                line([CGPoint(x: -31, y: -18), CGPoint(x: -42, y: -18), CGPoint(x: -42, y: 38), CGPoint(x: -28, y: 38)],
                     color: 0x4F899C, width: 5)
                line([CGPoint(x: -31, y: -19), CGPoint(x: -43, y: -19), CGPoint(x: -43, y: 36), CGPoint(x: -28, y: 36)],
                     color: 0xBCE6E0, width: 1.2)
            } else {
                ornamentFoot(light: 0xE0F4E9, face: 0x91BBC4, dark: 0x527E96)
                let r = CGRect(x: -34, y: -9, width: 19, height: 44)
                material(Path(roundedRect: r, cornerRadius: 6), light: 0xDBF5ED, face: 0x8EBDC6, dark: 0x507F93)
                context.stroke(Path(roundedRect: r.insetBy(dx: 2, dy: 2), cornerRadius: 4),
                               with: .color(Color(dinoHex: 0x4F8294)), lineWidth: 0.7)
                for i in 0..<3 { oval(CGRect(x: -29, y: -3 + CGFloat(i) * 11, width: 8, height: 6), light: 0xE2FFF0, face: 0x90E9D7, dark: 0x4D999E) }
                for x: CGFloat in [-28, -4] { rivet(at: CGPoint(x: x, y: 60), radius: 2) }
                for i in 0..<3 {
                    line([CGPoint(x: -31, y: 48 + CGFloat(i) * 3), CGPoint(x: -23, y: 49 + CGFloat(i) * 3)],
                         color: 0x527E96, width: 0.7)
                }
                line([CGPoint(x: -22, y: 37), CGPoint(x: -22, y: 48), CGPoint(x: -6, y: 48)], color: 0x4E7C92, width: 2.5)
                line([CGPoint(x: -23, y: 37), CGPoint(x: -23, y: 47), CGPoint(x: -6, y: 47)], color: 0xBEF0DC, width: 1)
            }
        case 8:
            if !front {
                sideHousing(light: 0xFFE7AD, face: 0xC6A566, dark: 0x80744F)
                // Bearings are seated in the same cast bracket, with a visible
                // shaft between the gears instead of a disconnected wand.
                line([CGPoint(x: -21, y: -45), CGPoint(x: -21, y: 53)], color: 0x806D4A, width: 9)
                line([CGPoint(x: -23, y: -43), CGPoint(x: -23, y: 51)], color: 0xF6DB9A, width: 1.5)
                line([CGPoint(x: -21, y: -3), CGPoint(x: -36, y: -3)], color: 0x9B8152, width: 6)
                gear(at: CGPoint(x: -20, y: -31), radius: 19)
                gear(at: CGPoint(x: -37, y: -3), radius: 14)
                gear(at: CGPoint(x: -20, y: 26), radius: 20)
                line([CGPoint(x: -32, y: -52), CGPoint(x: -32, y: -17), CGPoint(x: -27, y: -14)],
                     color: 0x9A8153, width: 0.9, opacity: 0.8)
            } else {
                ornamentFoot(light: 0xFFE6AA, face: 0xC7A76A, dark: 0x8A7A53)
                clock(at: CGPoint(x: -20, y: -31), radius: 11, time: WorldBossClock.time(in: 8))
                for y: CGFloat in [-57, 60] { rivet(at: CGPoint(x: -17, y: y), radius: 2.7) }
                gear(at: CGPoint(x: -7, y: 52), radius: 10)
            }
        case 9:
            if !front {
                sideHousing(light: 0xF4DFAD, face: 0xC7AB77, dark: 0x907958)
                for x: CGFloat in [-32, -26] {
                    var grain = Path()
                    grain.move(to: CGPoint(x: x, y: -48))
                    grain.addCurve(to: CGPoint(x: x + 3, y: 40), control1: CGPoint(x: x - 6, y: -20), control2: CGPoint(x: x + 8, y: 9))
                    context.stroke(grain, with: .color(Color(dinoHex: 0x9C805B).opacity(0.55)), lineWidth: 0.75)
                }
                rope(from: CGPoint(x: 0, y: -55), to: CGPoint(x: -21, y: -45))
                anchor(at: CGPoint(x: -21, y: -9))
            } else {
                nauticalScroll()
                rope(from: CGPoint(x: -34, y: 46), to: CGPoint(x: 6, y: 67))
                shell(at: CGPoint(x: -22, y: 57))
                // A pearl rests in the shell cup, not beside it in mid-air.
                pearl(at: CGPoint(x: -22, y: 57), radius: 2.4)
            }
        default:
            if !front {
                sideHousing(light: 0xF5E8C9, face: 0xD7C9A5, dark: 0x999E92)
                for i in 0..<2 { turret(at: CGPoint(x: -30 + CGFloat(i) * 20, y: 56), height: CGFloat(92 + i * 13)) }
            } else {
                ornamentFoot(light: 0xF6E4BA, face: 0xC9B67D, dark: 0x92917E)
                // The fabric hangs from a real crossbar and rolls over the heel.
                line([CGPoint(x: -37, y: -28), CGPoint(x: -8, y: -28)], color: 0x8D7B54, width: 4)
                line([CGPoint(x: -37, y: -29), CGPoint(x: -8, y: -29)], color: 0xFBE6A6, width: 1.2)
                pennant(at: CGPoint(x: -23, y: 2))
                crown(at: CGPoint(x: -23, y: -33))
                for x: CGFloat in [-32, -11] { rivet(at: CGPoint(x: x, y: -27), radius: 1.5) }
                for x: CGFloat in [-29, -18] {
                    line([CGPoint(x: x, y: 51), CGPoint(x: x + 2, y: 64)], color: 0x9F946F, width: 0.7, opacity: 0.7)
                }
            }
        }
    }

    private func sideHousing(light: UInt32, face: UInt32, dark: UInt32) {
        var shape = Path()
        shape.move(to: CGPoint(x: 8, y: -57))
        switch world.id {
        case 3, 5:
            shape.addLine(to: CGPoint(x: -15, y: world.id == 5 ? -72 : -67))
            shape.addLine(to: CGPoint(x: -34, y: -58))
            shape.addLine(to: CGPoint(x: -42, y: -30))
            shape.addLine(to: CGPoint(x: -39, y: 12))
        case 10:
            shape.addLines([CGPoint(x: -4, y: -57), CGPoint(x: -4, y: -66), CGPoint(x: -14, y: -66),
                            CGPoint(x: -14, y: -57), CGPoint(x: -23, y: -57), CGPoint(x: -23, y: -67),
                            CGPoint(x: -33, y: -67), CGPoint(x: -33, y: -57), CGPoint(x: -40, y: -57),
                            CGPoint(x: -40, y: -31)])
        case 9:
            shape.addQuadCurve(to: CGPoint(x: -31, y: -56), control: CGPoint(x: -17, y: -67))
            shape.addQuadCurve(to: CGPoint(x: -38, y: -31), control: CGPoint(x: -39, y: -49))
        default:
            shape.addCurve(to: CGPoint(x: -21, y: -67), control1: CGPoint(x: -3, y: -67), control2: CGPoint(x: -13, y: -68))
            shape.addCurve(to: CGPoint(x: -39, y: -31), control1: CGPoint(x: -38, y: -64), control2: CGPoint(x: -39, y: -48))
        }
        shape.addLine(to: CGPoint(x: -37, y: 42))
        shape.addQuadCurve(to: CGPoint(x: 9, y: 70), control: CGPoint(x: -35, y: 72))
        shape.addQuadCurve(to: CGPoint(x: 11, y: 52), control: CGPoint(x: 17, y: 64))
        shape.addQuadCurve(to: CGPoint(x: -15, y: 36), control: CGPoint(x: -15, y: 54))
        shape.addLine(to: CGPoint(x: -14, y: -29))
        shape.addQuadCurve(to: CGPoint(x: 8, y: -43), control: CGPoint(x: -13, y: -43))
        shape.closeSubpath()
        var shadow = context; shadow.translateBy(x: 0.5, y: 2.5)
        shadow.fill(shape, with: .color(Color(dinoHex: dark).opacity(0.25)))
        material(shape, light: light, face: face, dark: dark)
        context.stroke(shape, with: .color(Color(dinoHex: dark).opacity(0.55)), lineWidth: 0.8)
        // The bevel follows the actual contour and is clipped to its material.
        var edge = context; edge.clip(to: shape)
        edge.stroke(shape.offsetBy(dx: 2.2, dy: 2.2), with: .color(Color(dinoHex: light).opacity(0.8)), lineWidth: 1.3)
        var highlight = Path()
        highlight.move(to: CGPoint(x: 3, y: -58))
        highlight.addCurve(to: CGPoint(x: -34, y: -31), control1: CGPoint(x: -27, y: -74), control2: CGPoint(x: -34, y: -50))
        highlight.addLine(to: CGPoint(x: -32, y: 41))
        highlight.addQuadCurve(to: CGPoint(x: 4, y: 66), control: CGPoint(x: -30, y: 66))
        edge.stroke(highlight, with: .color(Color(dinoHex: light).opacity(0.45)), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
    }

    private func ornamentFoot(light: UInt32, face: UInt32, dark: UInt32) {
        var foot = Path()
        foot.move(to: CGPoint(x: -36, y: 43))
        foot.addQuadCurve(to: CGPoint(x: 7, y: 53), control: CGPoint(x: -19, y: 38))
        foot.addQuadCurve(to: CGPoint(x: 10, y: 69), control: CGPoint(x: 14, y: 61))
        foot.addCurve(to: CGPoint(x: -38, y: 59), control1: CGPoint(x: -7, y: 75), control2: CGPoint(x: -34, y: 70))
        foot.addQuadCurve(to: CGPoint(x: -36, y: 43), control: CGPoint(x: -44, y: 50))
        foot.closeSubpath()
        material(foot, light: light, face: face, dark: dark)
        context.stroke(foot, with: .color(Color(dinoHex: dark).opacity(0.6)), lineWidth: 0.7)
        var seam = Path()
        seam.move(to: CGPoint(x: -33, y: 47))
        seam.addQuadCurve(to: CGPoint(x: 6, y: 57), control: CGPoint(x: -16, y: 45))
        context.stroke(seam, with: .color(Color(dinoHex: light).opacity(0.85)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
    }

    private func organicStem(night: Bool) {
        let light: UInt32 = night ? 0xBECFD0 : 0xD9CC92
        let face: UInt32 = night ? 0x829AA7 : 0x9D9860
        let dark: UInt32 = night ? 0x566F8F : 0x506D43
        var stem = Path()
        stem.move(to: CGPoint(x: 11, y: 70))
        stem.addCurve(to: CGPoint(x: -30, y: 39), control1: CGPoint(x: -13, y: 70), control2: CGPoint(x: -31, y: 61))
        stem.addCurve(to: CGPoint(x: -22, y: -42), control1: CGPoint(x: -34, y: 16), control2: CGPoint(x: -20, y: -15))
        stem.addQuadCurve(to: CGPoint(x: 6, y: -60), control: CGPoint(x: -21, y: -61))
        stem.addLine(to: CGPoint(x: 10, y: -50))
        stem.addQuadCurve(to: CGPoint(x: -12, y: -37), control: CGPoint(x: -9, y: -50))
        stem.addCurve(to: CGPoint(x: -16, y: 39), control1: CGPoint(x: -12, y: -12), control2: CGPoint(x: -25, y: 14))
        stem.addQuadCurve(to: CGPoint(x: 10, y: 58), control: CGPoint(x: -13, y: 57))
        stem.closeSubpath()
        material(stem, light: light, face: face, dark: dark)
        var grain = Path()
        grain.move(to: CGPoint(x: 3, y: -55))
        grain.addCurve(to: CGPoint(x: -24, y: 37), control1: CGPoint(x: -35, y: -55), control2: CGPoint(x: -17, y: 8))
        grain.addQuadCurve(to: CGPoint(x: 7, y: 65), control: CGPoint(x: -25, y: 64))
        context.stroke(grain, with: .color(Color(dinoHex: light).opacity(0.85)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        context.stroke(grain.offsetBy(dx: 3, dy: 0), with: .color(Color(dinoHex: dark).opacity(0.55)), lineWidth: 0.7)
    }

    private func medallion(at point: CGPoint, radius: CGFloat, night: Bool) {
        let r = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        oval(r, light: palette.tabLight, face: palette.rim, dark: palette.shade)
        oval(r.insetBy(dx: 3, dy: 3), light: night ? 0xA2AFC6 : 0xF8E4AE,
             face: night ? 0x7183A4 : 0xD7C18B, dark: night ? 0x506A94 : 0x9B9668)
        context.stroke(Path(ellipseIn: r.insetBy(dx: 2, dy: 2)), with: .color(Color(dinoHex: palette.light)), lineWidth: 0.9)
    }

    private func nauticalScroll() {
        var scroll = Path()
        scroll.move(to: CGPoint(x: 8, y: 69))
        scroll.addCurve(to: CGPoint(x: -42, y: 43), control1: CGPoint(x: -18, y: 75), control2: CGPoint(x: -43, y: 62))
        scroll.addCurve(to: CGPoint(x: -18, y: 27), control1: CGPoint(x: -47, y: 20), control2: CGPoint(x: -20, y: 13))
        scroll.addCurve(to: CGPoint(x: -17, y: 44), control1: CGPoint(x: -9, y: 35), control2: CGPoint(x: -11, y: 42))
        scroll.addQuadCurve(to: CGPoint(x: -30, y: 41), control: CGPoint(x: -29, y: 51))
        scroll.addQuadCurve(to: CGPoint(x: 8, y: 54), control: CGPoint(x: -25, y: 60))
        scroll.closeSubpath()
        material(scroll, light: 0xC1E4D4, face: 0x82BAB8, dark: 0x4E8797)
        context.stroke(scroll, with: .color(Color(dinoHex: 0x497D8A).opacity(0.75)), lineWidth: 0.8)
        var curl = Path()
        curl.move(to: CGPoint(x: 3, y: 64))
        curl.addCurve(to: CGPoint(x: -38, y: 41), control1: CGPoint(x: -21, y: 64), control2: CGPoint(x: -38, y: 55))
        curl.addCurve(to: CGPoint(x: -19, y: 32), control1: CGPoint(x: -41, y: 28), control2: CGPoint(x: -25, y: 20))
        context.stroke(curl, with: .color(Color(dinoHex: 0xD6F0DC)), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
    }

    private func foliage(light: UInt32, face: UInt32, dark: UInt32, count: Int = 8) {
        let leaves: [(CGFloat, CGFloat, CGFloat, CGFloat, Double, Bool)] = [
            (1, -38, 43, 27, -36, true), (-9, -36, 46, 30, -74, false),
            (-17, -26, 37, 25, -112, true), (-10, -7, 43, 31, -68, false),
            (-15, 7, 45, 30, -101, true), (-17, 25, 40, 28, -74, false),
            (-14, 35, 44, 29, -123, true), (-4, 48, 37, 28, -151, false),
            (-22, -12, 30, 24, -40, false), (-24, 15, 34, 24, -133, false),
            (0, 33, 35, 24, -29, false), (4, -25, 31, 23, 28, false)
        ]
        for value in leaves.prefix(count) {
            line([CGPoint(x: -20, y: value.1 + 3), CGPoint(x: value.0, y: value.1)], color: dark, width: 2.4)
            line([CGPoint(x: -20, y: value.1 + 2), CGPoint(x: value.0, y: value.1)], color: face, width: 0.9)
        }
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
        layer.fill(leaf, with: .radialGradient(Gradient(stops: [
            .init(color: Color(dinoHex: light), location: 0),
            .init(color: Color(dinoHex: face), location: 0.48),
            .init(color: Color(dinoHex: dark), location: 1)
        ]), center: CGPoint(x: r.minX + width * 0.35, y: r.minY + length * 0.27),
                                             startRadius: 0, endRadius: length * 0.92))
        layer.fill(fold, with: .linearGradient(Gradient(colors: [.white.opacity(0.26), .clear]),
                                             startPoint: CGPoint(x: r.maxX, y: r.minY), endPoint: CGPoint(x: r.minX, y: r.maxY)))
        layer.stroke(leaf, with: .color(Color(dinoHex: light).opacity(0.55)), lineWidth: 0.7)
        layer.stroke(veins, with: .color(Color(dinoHex: light).opacity(0.6)), style: StrokeStyle(lineWidth: 0.55, lineCap: .round))
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
        let control = CGPoint(x: (a.x + b.x) / 2, y: a.y + 13)
        func onCord(_ t: CGFloat) -> CGPoint {
            let u = 1 - t
            return CGPoint(x: u * u * a.x + 2 * u * t * control.x + t * t * b.x,
                           y: u * u * a.y + 2 * u * t * control.y + t * t * b.y)
        }
        var cord = Path(); cord.move(to: a); cord.addQuadCurve(to: b, control: control)
        context.stroke(cord, with: .color(Color(dinoHex: 0x8D805C)), lineWidth: 1)
        for i in 0..<4 {
            let t = (CGFloat(i) + 0.5) / 4
            let center = onCord(t)
            polygon([onCord(t - 0.09), onCord(t + 0.09), CGPoint(x: center.x, y: center.y + 10)],
                    light: 0xF8E9C6, face: i.isMultiple(of: 2) ? 0xDBA283 : 0x82B6A5, dark: 0x8B8268)
            line([CGPoint(x: center.x, y: center.y + 1), CGPoint(x: center.x, y: center.y + 8)], color: 0xFAEBD1, width: 0.55)
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
        for i in 0..<6 {
            let angle = Double(i) * .pi / 3
            let inner = CGPoint(x: point.x + CGFloat(cos(angle)) * radius * 0.45,
                                y: point.y + CGFloat(sin(angle)) * radius * 0.45)
            let outer = CGPoint(x: point.x + CGFloat(cos(angle)) * radius * 0.57,
                                y: point.y + CGFloat(sin(angle)) * radius * 0.57)
            line([inner, outer], color: 0x8C825C, width: 1.2)
            line([CGPoint(x: inner.x - 0.5, y: inner.y - 0.5), CGPoint(x: outer.x - 0.5, y: outer.y - 0.5)],
                 color: 0xFFE8AF, width: 0.5)
        }
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
            let left: CGFloat = 0
            let right = w - left
            let height = size.height - routeOffset
            let scale = min(1.35, max(0.82, w / 390))
            let skyEnd = min(0.32, max(0.08, (routeOffset + 210) / size.height))
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                Gradient(stops: [
                    .init(color: Color(dinoHex: 0x86DDF4), location: 0),
                    .init(color: Color(dinoHex: 0xC5F0EE), location: skyEnd * 0.47),
                    .init(color: Color(dinoHex: 0xEDF5BE), location: skyEnd),
                    .init(color: Color(dinoHex: palette.ground), location: 0.45),
                    .init(color: Color(dinoHex: 0xD4E6AD), location: 0.72),
                    .init(color: Color(dinoHex: nextPalette.ground), location: 1)
                ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))

            let sky = JungleWorldPainter(context: context)
            sky.entrance(width: w, left: left, right: right, height: max(350, routeOffset), scale: scale)
            var routeContext = context
            routeContext.translateBy(x: 0, y: routeOffset)
            let painter = JunglePainter(context: routeContext)
            let detail = JungleWorldPainter(context: routeContext)

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

            detail.undergrowth(width: w, left: left, right: right, height: height, scale: scale)

            // Tall trees, layered crowns and hanging vines frame the entrance.
            detail.tree(at: CGPoint(x: left - 12, y: 355), size: 1.08 * scale, mirror: false)
            detail.tree(at: CGPoint(x: right + 17, y: 420), size: 1.20 * scale, mirror: true)
            detail.shrub(at: CGPoint(x: left + 5, y: 350), size: 0.7 * scale)
            painter.fern(at: CGPoint(x: right - 15, y: 450), size: 0.9 * scale, flipped: true)
            painter.flowers(at: CGPoint(x: left + 38, y: 405), size: scale)

            // A rocky waterfall and a lagoon make the middle of the world a
            // distinct destination. Water stays at the edge of the playable path.
            detail.waterfall(at: CGPoint(x: right - 24 * scale, y: 490), size: scale * 0.87)
            detail.palm(at: CGPoint(x: left + 13, y: 785), size: 0.96 * scale, mirror: false)
            painter.fern(at: CGPoint(x: left + 8, y: 885), size: 1.13 * scale, flipped: false)
            painter.flowers(at: CGPoint(x: right - 42, y: 965), size: 0.9 * scale)

            // Deeper jungle: buttress roots, large leaves, mossy boulders.
            detail.tree(at: CGPoint(x: left - 25, y: 1250), size: 1.02 * scale, mirror: false)
            detail.palm(at: CGPoint(x: right + 4, y: 1370), size: 1.05 * scale, mirror: true)
            detail.rocks(at: CGPoint(x: right - 25, y: 1382), size: 0.92 * scale)
            detail.shrub(at: CGPoint(x: left + 15, y: 1320), size: 0.8 * scale)
            painter.fern(at: CGPoint(x: right - 8, y: 1470), size: 1.2 * scale, flipped: true)
            painter.flowers(at: CGPoint(x: left + 40, y: 1475), size: scale)
            detail.rocks(at: CGPoint(x: left + 14, y: 1635), size: 1.15 * scale)
            detail.shrub(at: CGPoint(x: right - 6, y: 1720), size: 0.65 * scale)

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

/// Richer artwork is scoped to the first map. Shared scenery in other chapters
/// and the quiet question backgrounds continues to use JunglePainter unchanged.
private struct JungleWorldPainter {
    let context: GraphicsContext

    private func layer(at point: CGPoint, size: CGFloat = 1, mirror: Bool = false, draw: (JungleWorldPainter) -> Void) {
        var c = context
        c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: mirror ? -size : size, y: size)
        draw(.init(context: c))
    }

    private func material(_ path: Path, _ colors: [UInt32]) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                startPoint: CGPoint(x: r.minX, y: r.minY),
                                                endPoint: CGPoint(x: r.maxX, y: r.maxY)))
    }

    private func polygon(_ points: [CGPoint], colors: [UInt32]) {
        var path = Path(); path.addLines(points); path.closeSubpath()
        material(path, colors)
    }

    private func stroke(_ points: [CGPoint], color: UInt32, width: CGFloat, opacity: Double = 1) {
        var path = Path(); path.addLines(points)
        context.stroke(path, with: .color(Color(dinoHex: color).opacity(opacity)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func glow(at point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), .clear]),
                                           center: point, startRadius: 0, endRadius: radius))
    }

    func entrance(width: CGFloat, left: CGFloat, right: CGFloat, height: CGFloat, scale: CGFloat) {
        let sun = CGPoint(x: width * 0.72, y: height * 0.25)
        glow(at: sun, radius: 190 * scale, color: 0xFFF8CC, opacity: 0.9)
        glow(at: sun, radius: 52 * scale, color: 0xFFFDE0, opacity: 0.95)
        for (x, y, s) in [(width * 0.22, height * 0.12, CGFloat(1.2)),
                           (width * 0.63, height * 0.07, CGFloat(0.8)),
                           (width * 0.89, height * 0.34, CGFloat(1.05)),
                           (width * 0.12, height * 0.43, CGFloat(0.75))] {
            layer(at: CGPoint(x: x, y: y), size: s * scale) { $0.cloud() }
        }
        let distant = JunglePainter(context: context)
        distant.hill(x: -width * 0.4, y: height * 0.33, width: width, height: 340 * scale,
                     color: Color(dinoHex: 0x7BBDBB).opacity(0.3))
        distant.hill(x: width * 0.47, y: height * 0.35, width: width * 0.9, height: 320 * scale,
                     color: Color(dinoHex: 0x85C7B8).opacity(0.4))
        // The tall falls begin in the open sky and remain visible beside the sign.
        var rear = context; rear.opacity = 0.58
        JungleWorldPainter(context: rear).waterfall(at: CGPoint(x: left - 3 * scale, y: height * 0.76), size: 0.62 * scale)
        waterfall(at: CGPoint(x: right - 34 * scale, y: height * 0.65), size: 0.87 * scale)
        for row in 0..<3 {
            distant.hill(x: -width * 0.15, y: height * 0.74 + CGFloat(row) * 44, width: width * 1.3,
                         height: 155 * scale, color: Color(dinoHex: 0x81B87E).opacity(0.10 + Double(row) * 0.025))
            var c = context; c.opacity = 0.16 + Double(row) * 0.055
            let p = JungleWorldPainter(context: c)
            for i in 0..<8 {
                let x = CGFloat(i) * width / 6 - width * 0.08
                p.shrub(at: CGPoint(x: x, y: height * 0.82 + CGFloat(row) * 44 + CGFloat(i % 3) * 14),
                        size: (0.32 + CGFloat(row) * 0.06) * scale)
            }
        }
        glow(at: CGPoint(x: width * 0.5, y: height + 60), radius: width * 0.62, color: 0xF6FFD0, opacity: 0.55)
        context.drawLayer { rays in
            rays.addFilter(.blur(radius: 7))
            for i in 0..<3 {
                let x = sun.x + CGFloat(i - 1) * 24
                var ray = Path()
                ray.addLines([CGPoint(x: x, y: sun.y), CGPoint(x: x + 10, y: sun.y),
                              CGPoint(x: x - 115, y: height + 290), CGPoint(x: x - 180, y: height + 290)])
                ray.closeSubpath()
                rays.fill(ray, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFFDDE).opacity(0.24), .clear]),
                                                     startPoint: sun, endPoint: CGPoint(x: x - 140, y: height + 290)))
            }
        }
        for side in 0..<2 {
            layer(at: CGPoint(x: side == 0 ? left - 12 : right + 12, y: 25), size: scale, mirror: side == 1) { p in
                p.crown(at: .zero, size: 0.78)
                p.liana(from: CGPoint(x: 26, y: -25), length: 165, bend: 18)
                p.blade(at: CGPoint(x: 3, y: 55), length: 65, width: 22, angle: 129, light: true)
            }
        }
        // Tiny distant birds make the open patch above the chapter feel alive.
        for i in 0..<3 {
            let x = width * 0.42 + CGFloat(i) * 15, y = height * 0.31 - CGFloat(i % 2) * 7
            var bird = Path(); bird.move(to: CGPoint(x: x - 4, y: y))
            bird.addQuadCurve(to: CGPoint(x: x, y: y + 2), control: CGPoint(x: x - 1, y: y - 1))
            bird.addQuadCurve(to: CGPoint(x: x + 4, y: y), control: CGPoint(x: x + 1, y: y - 1))
            context.stroke(bird, with: .color(Color(dinoHex: 0x568B8C).opacity(0.55)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
        }
    }

    private func cloud() {
        var shape = Path()
        for (x, y, w, h): (CGFloat, CGFloat, CGFloat, CGFloat) in [(-62, 1, 72, 23), (-39, -15, 51, 41), (-5, -22, 61, 48), (35, -4, 56, 29)] {
            shape.addEllipse(in: CGRect(x: x, y: y, width: w, height: h))
        }
        context.drawLayer { c in
            c.addFilter(.blur(radius: 2.5))
            c.fill(shape, with: .linearGradient(Gradient(colors: [.white.opacity(0.95), Color(dinoHex: 0xEFFBF3).opacity(0.68), .white.opacity(0)]),
                                               startPoint: CGPoint(x: 0, y: -23), endPoint: CGPoint(x: 0, y: 30)))
        }
    }

    private func blade(at point: CGPoint, length: CGFloat, width: CGFloat, angle: Double, light: Bool) {
        var c = context; c.translateBy(x: point.x, y: point.y); c.rotate(by: .degrees(angle))
        let tip = CGPoint(x: length * 0.12, y: -length)
        let leaf = Path { p in
            p.move(to: .zero)
            p.addCurve(to: tip, control1: CGPoint(x: -width, y: -length * 0.21), control2: CGPoint(x: -width * 0.85, y: -length * 0.81))
            p.addCurve(to: .zero, control1: CGPoint(x: width * 0.92, y: -length * 0.81), control2: CGPoint(x: width * 0.72, y: -length * 0.18))
        }
        var shadow = c; shadow.translateBy(x: 1.3, y: 2)
        shadow.fill(leaf, with: .color(Color(dinoHex: 0x134E35).opacity(0.22)))
        c.fill(leaf, with: .linearGradient(Gradient(colors: (light ? [0xD5EB59, 0x81B93F, 0x30763B] : [0x80B847, 0x398847, 0x175D3E]).map { Color(dinoHex: $0) }),
                                          startPoint: CGPoint(x: -width * 0.6, y: -length * 0.8), endPoint: CGPoint(x: width * 0.7, y: 0)))
        let fold = Path { p in
            p.move(to: .zero); p.addLine(to: tip)
            p.addQuadCurve(to: CGPoint(x: -width * 0.6, y: -length * 0.49), control: CGPoint(x: -width * 0.8, y: -length * 0.65)); p.closeSubpath()
        }
        c.fill(fold, with: .color(Color(dinoHex: 0xEDFA9D).opacity(light ? 0.21 : 0.1)))
        var veins = Path(); veins.move(to: .zero); veins.addLine(to: CGPoint(x: tip.x * 0.96, y: tip.y * 0.94))
        for i in 1...3 {
            let t = CGFloat(i) / 5
            let y = -length * t
            veins.move(to: CGPoint(x: tip.x * t, y: y))
            veins.addQuadCurve(to: CGPoint(x: -width * 0.55, y: y - length * 0.14), control: CGPoint(x: -width * 0.45, y: y - length * 0.03))
            veins.move(to: CGPoint(x: tip.x * t, y: y))
            veins.addQuadCurve(to: CGPoint(x: width * 0.5, y: y - length * 0.12), control: CGPoint(x: width * 0.4, y: y - length * 0.02))
        }
        c.stroke(veins, with: .color(Color(dinoHex: 0xD9ED88).opacity(0.35)), style: StrokeStyle(lineWidth: 0.65, lineCap: .round))
    }

    private func crown(at point: CGPoint, size: CGFloat) {
        layer(at: point, size: size) { p in
            let backing = JunglePainter(context: p.context).foliagePath(in: CGRect(x: -72, y: -42, width: 153, height: 94))
            p.material(backing, [0x639F44, 0x236B40, 0x15573B])
            let leaves: [(CGFloat, CGFloat, CGFloat, CGFloat, Double)] = [
                (-14, 0, 68, 25, -78), (-8, -3, 65, 24, -46), (1, -4, 60, 23, -11),
                (12, 0, 72, 26, 32), (24, 5, 66, 23, 68), (29, 8, 63, 24, 108),
                (-29, 11, 62, 23, -112), (-18, 15, 57, 23, -153),
                (4, 15, 62, 24, 167), (21, 15, 56, 23, 135),
                (-25, -2, 46, 21, -49), (15, -5, 49, 22, 46)
            ]
            for (i, leaf) in leaves.enumerated() {
                p.blade(at: CGPoint(x: leaf.0, y: leaf.1), length: leaf.2, width: leaf.3, angle: leaf.4, light: i % 3 != 0)
            }
        }
    }

    func shrub(at point: CGPoint, size: CGFloat) {
        layer(at: point, size: size) { p in
            p.crown(at: CGPoint(x: -24, y: -7), size: 0.60)
            p.crown(at: CGPoint(x: 27, y: -15), size: 0.66)
            p.crown(at: CGPoint(x: 0, y: 5), size: 0.57)
        }
    }

    func tree(at point: CGPoint, size: CGFloat, mirror: Bool) {
        layer(at: point, size: size, mirror: mirror) { p in
            p.glow(at: CGPoint(x: 12, y: -4), radius: 60, color: 0x4B753C, opacity: 0.17)
            let trunk = Path { t in
                t.move(to: CGPoint(x: -37, y: 7))
                t.addCurve(to: CGPoint(x: 11, y: -220), control1: CGPoint(x: -6, y: -64), control2: CGPoint(x: -9, y: -168))
                t.addLine(to: CGPoint(x: 35, y: -219))
                t.addCurve(to: CGPoint(x: 41, y: 9), control1: CGPoint(x: 14, y: -130), control2: CGPoint(x: 19, y: -29))
                t.addQuadCurve(to: CGPoint(x: 7, y: -10), control: CGPoint(x: 17, y: 6))
                t.addQuadCurve(to: CGPoint(x: -37, y: 7), control: CGPoint(x: -12, y: -4)); t.closeSubpath()
            }
            p.material(trunk, [0xE2B96A, 0xB08549, 0x755632])
            var clipped = p.context; clipped.clip(to: trunk)
            for i in 0..<7 {
                let x = CGFloat(i) * 9 - 22
                var grain = Path(); grain.move(to: CGPoint(x: x, y: 9))
                grain.addCurve(to: CGPoint(x: x + 26, y: -229), control1: CGPoint(x: x + 10, y: -80), control2: CGPoint(x: x + 3, y: -152))
                clipped.stroke(grain, with: .color(Color(dinoHex: i % 2 == 0 ? 0xF4CD80 : 0x694A2C).opacity(0.36)),
                               style: StrokeStyle(lineWidth: i % 2 == 0 ? 3 : 1.4, lineCap: .round))
            }
            for side: CGFloat in [-1, 1] {
                var branch = Path(); branch.move(to: CGPoint(x: 14, y: -135))
                branch.addQuadCurve(to: CGPoint(x: 20 + side * 61, y: -248), control: CGPoint(x: 25 + side * 40, y: -185))
                p.context.stroke(branch, with: .color(Color(dinoHex: 0x9B733E)), style: StrokeStyle(lineWidth: 13, lineCap: .round))
                p.context.stroke(branch.offsetBy(dx: -3, dy: 0), with: .color(Color(dinoHex: 0xD8AB62)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            p.crown(at: CGPoint(x: -24, y: -244), size: 0.83)
            p.crown(at: CGPoint(x: 67, y: -253), size: 0.82)
            p.crown(at: CGPoint(x: 21, y: -276), size: 0.96)
            p.crown(at: CGPoint(x: 18, y: -219), size: 0.70)
            // A heavy looping liana wraps around the trunk before hanging down.
            var loop = Path(); loop.move(to: CGPoint(x: -39, y: -214))
            loop.addCurve(to: CGPoint(x: 69, y: -209), control1: CGPoint(x: -37, y: -112), control2: CGPoint(x: 67, y: -118))
            p.context.stroke(loop, with: .color(Color(dinoHex: 0x205E3C)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            p.context.stroke(loop.offsetBy(dx: -1, dy: -1), with: .color(Color(dinoHex: 0x7B9B47)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            p.liana(from: CGPoint(x: 55, y: -233), length: 144, bend: 20)
            p.shrub(at: CGPoint(x: -4, y: 14), size: 0.47)
        }
    }

    private func liana(from point: CGPoint, length: CGFloat, bend: CGFloat) {
        func onVine(_ t: CGFloat) -> CGPoint {
            CGPoint(x: point.x + sin(t * .pi * 1.45) * bend, y: point.y + t * length)
        }
        var vine = Path(); vine.addLines((0...20).map { onVine(CGFloat($0) / 20) })
        context.stroke(vine, with: .color(Color(dinoHex: 0x316C46)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        context.stroke(vine.offsetBy(dx: -0.8, dy: 0), with: .color(Color(dinoHex: 0x9AB962).opacity(0.55)), lineWidth: 0.8)
        for i in 1...5 {
            blade(at: onVine(CGFloat(i) / 6), length: 20, width: 8, angle: i % 2 == 0 ? 64 : -66, light: i % 2 == 0)
        }
    }

    func palm(at point: CGPoint, size: CGFloat, mirror: Bool) {
        layer(at: point, size: size, mirror: mirror) { p in
            let top = CGPoint(x: 30, y: -176)
            var stem = Path(); stem.move(to: .zero)
            stem.addQuadCurve(to: top, control: CGPoint(x: -9, y: -117))
            p.context.stroke(stem, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xE5BE78), Color(dinoHex: 0x987241), Color(dinoHex: 0x75562F)]),
                                                       startPoint: CGPoint(x: -8, y: -85), endPoint: CGPoint(x: 13, y: -80)),
                             style: StrokeStyle(lineWidth: 15, lineCap: .round))
            for i in 1..<9 {
                let t = CGFloat(i) / 10
                let x = -18 * t * (1 - t) + 30 * t * t
                let y = -234 * t * (1 - t) - 176 * t * t
                p.stroke([CGPoint(x: x - 5, y: y), CGPoint(x: x, y: y + 3), CGPoint(x: x + 6, y: y + 1)],
                         color: 0x684D2E, width: 1.2, opacity: 0.5)
                p.stroke([CGPoint(x: x - 5, y: y - 2), CGPoint(x: x, y: y + 1)], color: 0xF6CF85, width: 1, opacity: 0.7)
            }
            for (i, angle) in [-108.0, 112, -74, 76, -41, 39, -8].enumerated() {
                p.blade(at: top, length: i < 2 ? 111 : 94, width: 28, angle: angle, light: i % 3 != 0)
            }
            p.rock(at: CGPoint(x: -12, y: 4), size: 0.4)
        }
    }

    private func rock(at point: CGPoint, size: CGFloat) {
        layer(at: point, size: size) { p in
            let pts: [CGPoint] = [.init(x: -31, y: 7), .init(x: -25, y: -20), .init(x: -8, y: -36),
                                  .init(x: 16, y: -33), .init(x: 35, y: -12), .init(x: 29, y: 11), .init(x: 0, y: 17)]
            p.polygon(pts, colors: [0xE3DAB4, 0xAEA98B, 0x7C8B75])
            p.polygon([pts[1], pts[2], pts[3], .init(x: 9, y: -14), .init(x: -7, y: -9)], colors: [0xF2E6BE, 0xC6BE99])
            p.polygon([pts[3], pts[4], pts[5], .init(x: 5, y: 13), .init(x: 9, y: -14)], colors: [0xA8A78C, 0x728573])
            p.stroke([.init(x: -14, y: -13), .init(x: -7, y: -9), .init(x: -10, y: 3)], color: 0x78846D, width: 0.9, opacity: 0.4)
            p.blade(at: CGPoint(x: -21, y: -13), length: 17, width: 6, angle: -75, light: true)
            p.blade(at: CGPoint(x: -18, y: -15), length: 19, width: 7, angle: 35, light: true)
        }
    }

    func rocks(at point: CGPoint, size: CGFloat) {
        layer(at: point, size: size) { p in
            p.rock(at: CGPoint(x: -28, y: -3), size: 0.66)
            p.rock(at: CGPoint(x: 10, y: -5), size: 1)
            p.rock(at: CGPoint(x: 44, y: 5), size: 0.44)
        }
    }

    func waterfall(at point: CGPoint, size: CGFloat) {
        layer(at: point, size: size) { p in
            let pool = Path(ellipseIn: CGRect(x: -106, y: 26, width: 230, height: 87))
            p.material(pool, [0x74CFD3, 0x32A9C0, 0xB2E4D7])
            p.context.stroke(pool, with: .color(Color(dinoHex: 0xDBF2CC).opacity(0.8)), lineWidth: 4)
            let cliff = Path { c in
                c.move(to: CGPoint(x: -83, y: 54))
                c.addLines([.init(x: -76, y: -31), .init(x: -58, y: -62), .init(x: -66, y: -164),
                            .init(x: -42, y: -238), .init(x: -18, y: -264), .init(x: 27, y: -258),
                            .init(x: 45, y: -215), .init(x: 75, y: -204), .init(x: 83, y: -140),
                            .init(x: 112, y: -109), .init(x: 105, y: 52)])
                c.closeSubpath()
            }
            p.material(cliff, [0xD1D0A8, 0x8DA89D, 0x668F89])
            p.polygon([.init(x: -42, y: -238), .init(x: -18, y: -264), .init(x: -6, y: -206),
                       .init(x: -26, y: -110), .init(x: -24, y: 45), .init(x: -61, y: 54)], colors: [0xEEE2B9, 0xB0B9A0, 0x8DAA98])
            p.polygon([.init(x: 27, y: -258), .init(x: 45, y: -215), .init(x: 75, y: -204),
                       .init(x: 68, y: -98), .init(x: 90, y: -39), .init(x: 79, y: 54), .init(x: 18, y: 47)],
                      colors: [0x9FB3A4, 0x597F7C, 0x779A88])
            p.polygon([.init(x: 75, y: -204), .init(x: 83, y: -140), .init(x: 112, y: -109),
                       .init(x: 105, y: 52), .init(x: 79, y: 54), .init(x: 86, y: -120)], colors: [0xD3D0AA, 0x8DA28D])
            for i in 0..<6 {
                let y = -191 + CGFloat(i) * 39
                p.stroke([.init(x: 43, y: y), .init(x: 57, y: y + 9), .init(x: 75, y: y + 4)], color: 0x486D69, width: 1.1, opacity: 0.35)
                p.stroke([.init(x: -58, y: y + 18), .init(x: -43, y: y + 23), .init(x: -30, y: y + 17)], color: 0xF3EAC7, width: 1.3, opacity: 0.4)
            }
            for (x, y, s) in [(CGFloat(-9), CGFloat(-255), CGFloat(0.43)), (63, -201, 0.32), (-55, -65, 0.28), (93, -106, 0.32)] {
                p.shrub(at: CGPoint(x: x, y: y), size: s)
            }
            // The upper stream spills over a broad lip, then fans into a second cascade.
            var source = Path(); source.move(to: CGPoint(x: 29, y: -257))
            source.addQuadCurve(to: CGPoint(x: 0, y: -241), control: CGPoint(x: -1, y: -264))
            p.context.stroke(source, with: .color(Color(dinoHex: 0xB8F2ED)), style: StrokeStyle(lineWidth: 15, lineCap: .round))
            let fall = Path { f in
                f.move(to: CGPoint(x: -9, y: -243))
                f.addCurve(to: CGPoint(x: -12, y: -88), control1: CGPoint(x: -8, y: -193), control2: CGPoint(x: -3, y: -133))
                f.addCurve(to: CGPoint(x: -32, y: 48), control1: CGPoint(x: -22, y: -41), control2: CGPoint(x: -16, y: 9))
                f.addQuadCurve(to: CGPoint(x: 29, y: 48), control: CGPoint(x: -2, y: 64))
                f.addCurve(to: CGPoint(x: 12, y: -88), control1: CGPoint(x: 10, y: 1), control2: CGPoint(x: 26, y: -46))
                f.addCurve(to: CGPoint(x: 14, y: -243), control1: CGPoint(x: 18, y: -145), control2: CGPoint(x: 8, y: -192))
                f.closeSubpath()
            }
            p.material(fall, [0xE1FFF7, 0x5CD1ED, 0x83DEF0, 0xD4FFF3])
            var water = p.context; water.clip(to: fall)
            for i in 0..<9 {
                let x = CGFloat(i) * 5 - 21
                var stream = Path(); stream.move(to: CGPoint(x: x, y: -248 + CGFloat(i % 3) * 21))
                stream.addCurve(to: CGPoint(x: x * 1.6, y: 54), control1: CGPoint(x: x + 9, y: -137), control2: CGPoint(x: x - 10, y: -27))
                water.stroke(stream, with: .color(Color(dinoHex: i % 3 == 0 ? 0x2DA9CF : 0xF2FFF9).opacity(i % 3 == 0 ? 0.27 : 0.65)),
                             style: StrokeStyle(lineWidth: i % 2 == 0 ? 2.8 : 1.2, lineCap: .round))
            }
            p.rocks(at: CGPoint(x: -73, y: 65), size: 0.85)
            p.rocks(at: CGPoint(x: 78, y: 70), size: 0.63)
            p.glow(at: CGPoint(x: 0, y: 47), radius: 57, color: 0xEAFFF1, opacity: 0.55)
            for i in 0..<11 {
                let x = CGFloat(i - 5) * 6
                let r = CGRect(x: x - 7, y: 44 + CGFloat(i % 3) * 3, width: 17, height: 6)
                p.context.fill(Path(ellipseIn: r), with: .color(Color(dinoHex: 0xECFFF4).opacity(0.85)))
            }
            for i in 0..<3 {
                var ripple = Path()
                ripple.addArc(center: CGPoint(x: 0, y: 0), radius: CGFloat(27 + i * 17), startAngle: .degrees(14), endAngle: .degrees(167), clockwise: false)
                var c = p.context; c.translateBy(x: 1, y: 64 + CGFloat(i) * 7); c.scaleBy(x: 1, y: 0.24)
                c.stroke(ripple, with: .color(Color(dinoHex: 0xE0FFF0).opacity(0.8)), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
            }
            for i in 0..<8 {
                let x = CGFloat(i % 2 == 0 ? -1 : 1) * CGFloat(12 + i * 4)
                p.context.fill(Path(ellipseIn: CGRect(x: x, y: 33 - CGFloat(i % 4) * 8, width: 2.5, height: 4)), with: .color(.white.opacity(0.7)))
            }
        }
    }

    func undergrowth(width: CGFloat, left: CGFloat, right: CGFloat, height: CGFloat, scale: CGFloat) {
        let simple = JunglePainter(context: context)
        for i in 0..<11 {
            let y = 95 + CGFloat(i) * 166
            let side = i % 2 == 0
            let edge = side ? left : right
            let inward: CGFloat = side ? 1 : -1
            // Low banks create layers of jungle while keeping the route open.
            simple.hill(x: side ? left - 125 * scale : right - 55 * scale, y: y - 30,
                        width: 180 * scale, height: 155 * scale, color: Color(dinoHex: i % 3 == 0 ? 0x92BB60 : 0xAED16F).opacity(0.36))
            shrub(at: CGPoint(x: edge + inward * 7, y: y + 68), size: (0.38 + CGFloat(i % 3) * 0.09) * scale)
            if i % 3 == 0 { rocks(at: CGPoint(x: edge + inward * 33, y: y + 109), size: scale * 0.66) }
            if i % 2 == 0 {
                simple.flowers(at: CGPoint(x: edge + inward * 43, y: y + 57), size: scale * 0.7)
            }
            for j in 0..<4 {
                blade(at: CGPoint(x: edge + inward * CGFloat(5 + j * 8), y: y + 142),
                      length: CGFloat(35 + j * 9) * scale, width: 11 * scale, angle: Double(j * 31 - 48), light: j % 2 == 0)
            }
        }
        // Small sunlit leaves and pebbles break up the large ground surfaces.
        for i in 0..<28 {
            let x = width * (i % 2 == 0 ? 0.13 : 0.87) + CGFloat(i % 3 - 1) * 13
            let y = 170 + CGFloat(i) * 61
            simple.grass(at: CGPoint(x: x, y: y), size: 5 * scale, color: Color(dinoHex: 0x7FA34E).opacity(0.55))
        }
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

/// Moonlit scenery belongs only to chapter two; the shared theme painter keeps
/// the other chapters and their established palettes intact.
private struct SleepValleyPainter {
    let context: GraphicsContext

    private func at(_ point: CGPoint, size: CGFloat = 1, mirror: Bool = false, draw: (SleepValleyPainter) -> Void) {
        var c = context; c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: mirror ? -size : size, y: size)
        draw(.init(context: c))
    }
    private func material(_ path: Path, colors: [UInt32]) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
    }
    private func oval(_ r: CGRect, colors: [UInt32]) {
        context.fill(Path(ellipseIn: r), with: .radialGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                            center: CGPoint(x: r.minX + r.width * 0.3, y: r.minY + r.height * 0.2),
                                                            startRadius: 0, endRadius: max(r.width, r.height) * 0.9))
    }
    private func polygon(_ points: [CGPoint], colors: [UInt32]) {
        var p = Path(); p.addLines(points); p.closeSubpath(); material(p, colors: colors)
    }
    private func line(_ points: [CGPoint], color: UInt32, width: CGFloat, opacity: Double = 1) {
        var p = Path(); p.addLines(points)
        context.stroke(p, with: .color(Color(dinoHex: color).opacity(opacity)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func glow(_ point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), Color(dinoHex: color).opacity(0)]),
                                           center: point, startRadius: 0, endRadius: radius))
    }

    func landscape(in size: CGSize, routeOffset: CGFloat) {
        let w = size.width, h = size.height
        let left: CGFloat = 0, right = w - left
        let scale = min(1.30, max(0.82, w / 390))
        let skyEnd = (routeOffset + 185) / h
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: 0xDCD6F7), location: 0),
            .init(color: Color(dinoHex: 0x7380AC), location: 0.035),
            .init(color: Color(dinoHex: 0x687BA1), location: skyEnd * 0.55),
            .init(color: Color(dinoHex: 0xBBCDCE), location: skyEnd),
            .init(color: Color(dinoHex: 0xC7D8C5), location: 0.39),
            .init(color: Color(dinoHex: 0xBACCC4), location: 0.68),
            .init(color: Color(dinoHex: 0xC1C1D5), location: 0.87),
            .init(color: Color(dinoHex: 0xFFD1A1), location: 1)
        ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
        var c = context; c.translateBy(x: 0, y: routeOffset)
        let p = SleepValleyPainter(context: c)
        let nature = JunglePainter(context: c)
        p.creek(at: CGPoint(x: left - 9, y: 0), length: 1710, scale: scale, mirror: false)
        p.creek(at: CGPoint(x: right + 12, y: 150), length: 1440, scale: scale, mirror: true)
        // Distant cliffs cover the stream's upper end, so it emerges naturally
        // below the waterfall rather than painting over the cascade.
        sky(width: w, left: left, right: right, height: routeOffset + 150, scale: scale)
        for i in 0..<6 {
            let y = CGFloat(i) * 295 + 28
            nature.hill(x: i % 2 == 0 ? -w * 0.40 : w * 0.59, y: y, width: w * 0.85, height: 260,
                        color: Color(dinoHex: i % 2 == 0 ? 0x7A9D92 : 0xB4BFBA).opacity(0.18))
            p.glow(CGPoint(x: w * 0.5, y: y + 110), radius: w * 0.36, color: 0xF4F0CA, opacity: 0.13)
        }
        // Each bend gets a distinct destination, with the largest silhouettes
        // on the opposite side from the playable stone.
        for index in 0..<9 {
            let onRight = index % 4 == 0 || index % 4 == 3
            let x = onRight ? right - 28 * scale : left + 28 * scale
            let y = 181 + CGFloat(index) * 175
            // Clock faces stay readable on both banks; never mirror their text.
            p.garden(at: CGPoint(x: x, y: y), size: scale * 0.88, variation: index)
            let opposite = onRight ? left : right
            p.at(CGPoint(x: opposite, y: y + 69), size: scale, mirror: onRight) { edge in
                edge.plants(at: CGPoint(x: 13, y: 0), size: 0.85)
                edge.rock(at: CGPoint(x: 29, y: 15), size: 0.55)
                if index % 2 == 0 { edge.bellflowers(at: CGPoint(x: 26, y: -6), size: 0.7) }
            }
        }
        p.willow(at: CGPoint(x: right + 19, y: 191), size: scale * 1.06, mirror: true, variation: 0)
        p.willow(at: CGPoint(x: left - 10, y: 635), size: scale * 1.18, mirror: false, variation: 1)
        p.willow(at: CGPoint(x: right + 21, y: 1160), size: scale * 1.10, mirror: true, variation: 2)
        p.willow(at: CGPoint(x: left - 24, y: 1490), size: scale * 1.08, mirror: false, variation: 3)
        p.bridge(at: CGPoint(x: left + 27 * scale, y: 915), size: scale * 0.88)
        for i in 0..<24 {
            let onRight = i % 2 == 0
            let x = onRight ? right - CGFloat(21 + i % 3 * 18) : left + CGFloat(21 + i % 3 * 18)
            let y = 50 + CGFloat(i) * 68
            p.glow(CGPoint(x: x, y: y), radius: 12, color: 0xFFF2B4, opacity: 0.3)
            p.oval(CGRect(x: x - 1.2, y: y - 1.2, width: 2.4, height: 2.4), colors: [0xFFFFE4, 0xF9D99B])
            nature.grass(at: CGPoint(x: x, y: y + 19), size: 5 * scale, color: Color(dinoHex: 0x719987).opacity(0.5))
        }
        // A final bank of lavender mist opens toward the warm next horizon.
        p.mist(at: CGPoint(x: w * 0.48, y: 1715), width: w * 1.15, opacity: 0.14)
    }

    private func sky(width: CGFloat, left: CGFloat, right: CGFloat, height: CGFloat, scale: CGFloat) {
        let moon = CGPoint(x: right - 66 * scale, y: 79 * scale)
        glow(moon, radius: 110 * scale, color: 0xFFE7A0, opacity: 0.4)
        at(moon, size: scale) { p in
            p.oval(CGRect(x: -35, y: -35, width: 70, height: 70), colors: [0xFFF9D5, 0xFFE3A1, 0xEFC78C])
            p.context.stroke(Path(ellipseIn: CGRect(x: -34, y: -34, width: 68, height: 68)), with: .color(Color(dinoHex: 0xFFF9D1)), lineWidth: 1.2)
            for (x, y, r): (CGFloat, CGFloat, CGFloat) in [(-15, -18, 7), (12, -11, 9), (-5, 13, 10), (19, 17, 5), (-20, 2, 4)] {
                p.oval(CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2), colors: [0xF5D595, 0xE9C58F, 0xF8DB9C])
            }
        }
        for i in 0..<35 {
            let x = CGFloat((i * 79 + 23) % 397) / 397 * width
            let y = 22 + CGFloat((i * 47) % 210)
            // Avoid a visible dot pattern across the moon's face.
            if hypot(x - moon.x, y - moon.y) < 45 * scale { continue }
            let r: CGFloat = i % 7 == 0 ? 2.5 : i % 3 == 0 ? 1.2 : 0.65
            glow(CGPoint(x: x, y: y), radius: r * 3, color: 0xFFF1C8, opacity: 0.2)
            if i % 7 == 0 {
                line([CGPoint(x: x - r, y: y), CGPoint(x: x + r, y: y)], color: 0xFFF1C8, width: 0.8, opacity: 0.75)
                line([CGPoint(x: x, y: y - r * 1.3), CGPoint(x: x, y: y + r * 1.3)], color: 0xFFF1C8, width: 0.8, opacity: 0.75)
            } else {
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 1.6, height: r * 1.6)), with: .color(Color(dinoHex: 0xFFF3D3).opacity(0.65)))
            }
        }
        for (x, y, s) in [(width * 0.22, CGFloat(65), CGFloat(1.0)), (width * 0.73, CGFloat(144), CGFloat(0.9)), (width * 0.12, CGFloat(195), CGFloat(0.65))] {
            at(CGPoint(x: x, y: y), size: s * scale) { p in
                var cloud = Path()
                for (cx, cy, cw, ch): (CGFloat, CGFloat, CGFloat, CGFloat) in [(-62, 0, 85, 17), (-39, -12, 48, 28), (-5, -18, 62, 35), (33, -4, 67, 19)] {
                    cloud.addEllipse(in: CGRect(x: cx, y: cy, width: cw, height: ch))
                }
                p.context.drawLayer { c in
                    c.addFilter(.blur(radius: 2.5))
                    c.fill(cloud, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xE6CFE2).opacity(0.58), Color(dinoHex: 0xB8B9D2).opacity(0)]),
                                                       startPoint: CGPoint(x: 0, y: -19), endPoint: CGPoint(x: 0, y: 20)))
                }
            }
        }
        let nature = JunglePainter(context: context)
        for i in 0..<3 {
            nature.hill(x: i % 2 == 0 ? -width * 0.3 : width * 0.49,
                        y: height * 0.36 + CGFloat(i) * 35, width: width * 0.88, height: height * 0.77,
                        color: Color(dinoHex: i == 0 ? 0x5C7E96 : 0x809FA9).opacity(0.28))
        }
        at(CGPoint(x: left - 5, y: height * 0.83), size: scale * 0.82) { $0.distantFalls() }
        at(CGPoint(x: right + 6, y: height * 0.92), size: scale * 0.64, mirror: true) { $0.distantFalls() }
        mist(at: CGPoint(x: width * 0.5, y: height * 0.86), width: width * 1.15, opacity: 0.26)
    }

    private func mist(at point: CGPoint, width: CGFloat, opacity: Double) {
        context.drawLayer { c in
            c.addFilter(.blur(radius: 9))
            for i in 0..<3 {
                let r = CGRect(x: point.x - width * 0.5 + CGFloat(i - 1) * 22,
                               y: point.y + CGFloat(i) * 13, width: width, height: 24 + CGFloat(i) * 7)
                c.fill(Path(ellipseIn: r), with: .color(Color(dinoHex: 0xE7E8F1).opacity(opacity * (1 - Double(i) * 0.2))))
            }
        }
    }

    private func distantFalls() {
        polygon([.init(x: -56, y: 15), .init(x: -43, y: -98), .init(x: -25, y: -144), .init(x: 22, y: -146),
                 .init(x: 41, y: -105), .init(x: 55, y: -84), .init(x: 66, y: 20)], colors: [0xA9B8C5, 0x708FA4, 0x729F9E])
        polygon([.init(x: -25, y: -144), .init(x: -8, y: -137), .init(x: -20, y: 19), .init(x: -54, y: 15)], colors: [0xC2C8CD, 0x8BA7AD])
        var fall = Path(); fall.move(to: CGPoint(x: -2, y: -137))
        fall.addCurve(to: CGPoint(x: -17, y: 18), control1: CGPoint(x: -1, y: -80), control2: CGPoint(x: -13, y: -38))
        fall.addQuadCurve(to: CGPoint(x: 16, y: 18), control: CGPoint(x: 0, y: 27))
        fall.addCurve(to: CGPoint(x: 13, y: -138), control1: CGPoint(x: 9, y: -47), control2: CGPoint(x: 18, y: -84)); fall.closeSubpath()
        material(fall, colors: [0xE5F4F3, 0x8FCAD9, 0xCEE9E1])
        for x: CGFloat in [0, 6] { line([.init(x: x, y: -128), .init(x: x - 3, y: -65), .init(x: x - 7, y: 16)], color: 0xE6F8EE, width: 1.5, opacity: 0.6) }
        plants(at: CGPoint(x: -21, y: -139), size: 0.50)
        plants(at: CGPoint(x: 39, y: -89), size: 0.38)
        glow(CGPoint(x: 0, y: 20), radius: 42, color: 0xE3F5EA, opacity: 0.3)
        mist(at: CGPoint(x: 0, y: 21), width: 138, opacity: 0.25)
    }

    private func leaf(at point: CGPoint, length: CGFloat, width: CGFloat, angle: Double, light: Bool) {
        var c = context; c.translateBy(x: point.x, y: point.y); c.rotate(by: .degrees(angle))
        let shape = Path { p in
            p.move(to: .zero)
            p.addCurve(to: CGPoint(x: length * 0.08, y: -length), control1: CGPoint(x: -width, y: -length * 0.25), control2: CGPoint(x: -width * 0.8, y: -length * 0.73))
            p.addCurve(to: .zero, control1: CGPoint(x: width * 0.8, y: -length * 0.76), control2: CGPoint(x: width * 0.9, y: -length * 0.22))
        }
        c.fill(shape, with: .linearGradient(Gradient(colors: (light ? [0xCBD9A1, 0x8FB48A, 0x517F70] : [0x9CB9A2, 0x548C80, 0x365E64]).map { Color(dinoHex: $0) }),
                                           startPoint: CGPoint(x: -width * 0.5, y: -length), endPoint: CGPoint(x: width, y: 0)))
        var vein = Path(); vein.move(to: .zero); vein.addLine(to: CGPoint(x: length * 0.07, y: -length * 0.88))
        c.stroke(vein, with: .color(Color(dinoHex: 0xE2E8BA).opacity(0.34)), style: StrokeStyle(lineWidth: 0.6, lineCap: .round))
    }

    private func willow(at point: CGPoint, size: CGFloat, mirror: Bool, variation: Int) {
        at(point, size: size, mirror: mirror) { p in
            p.oval(CGRect(x: -47, y: -2, width: 110, height: 24), colors: [0x719283, 0xA3BAA9, 0xBED0BB])
            let trunk = Path { t in
                t.move(to: CGPoint(x: -28, y: 7))
                t.addCurve(to: CGPoint(x: 9, y: -190), control1: CGPoint(x: -1, y: -36), control2: CGPoint(x: -10, y: -135))
                t.addLine(to: CGPoint(x: 27, y: -191))
                t.addCurve(to: CGPoint(x: 35, y: 6), control1: CGPoint(x: 19, y: -109), control2: CGPoint(x: 14, y: -27))
                t.addQuadCurve(to: CGPoint(x: 4, y: -5), control: CGPoint(x: 10, y: 6)); t.closeSubpath()
            }
            p.material(trunk, colors: [0xD4C3A1, 0x9A9886, 0x626E6C])
            var bark = p.context; bark.clip(to: trunk)
            for i in 0..<5 {
                let x = CGFloat(i) * 8 - 12
                var grain = Path(); grain.move(to: CGPoint(x: x, y: 8))
                grain.addCurve(to: CGPoint(x: x + 13, y: -198), control1: CGPoint(x: x + 12, y: -58), control2: CGPoint(x: x - 2, y: -122))
                bark.stroke(grain, with: .color(Color(dinoHex: i % 2 == 0 ? 0xECE0B7 : 0x586A65).opacity(0.4)), style: StrokeStyle(lineWidth: i % 2 == 0 ? 2.5 : 1.2, lineCap: .round))
            }
            for side: CGFloat in [-1, 1] {
                var branch = Path(); branch.move(to: CGPoint(x: 14, y: -112))
                branch.addQuadCurve(to: CGPoint(x: 17 + side * 55, y: -194), control: CGPoint(x: 25 + side * 42, y: -142))
                p.context.stroke(branch, with: .color(Color(dinoHex: 0x8C917E)), style: StrokeStyle(lineWidth: 8, lineCap: .round))
            }
            let crown = JunglePainter(context: p.context).foliagePath(in: CGRect(x: -60, y: -232, width: 159, height: 95))
            p.material(crown, colors: [0xA1BC94, 0x598C7B, 0x3D6A6C])
            // Tapered leafy curtains hang from actual curved branches.
            for row in 0..<2 {
                for strand in 0..<10 {
                    let x = CGFloat(strand) * 15 - 56 + CGFloat(row) * 5
                    let startY = -205 - CGFloat((strand + variation) % 3) * 9 + CGFloat(row) * 18
                    let length = CGFloat(69 + (strand * 17 + variation * 11) % 53)
                    let bend: CGFloat = (strand < 5 ? -1 : 1) * CGFloat(9 + strand % 3 * 3)
                    var twig = Path(); twig.move(to: CGPoint(x: x, y: startY))
                    twig.addQuadCurve(to: CGPoint(x: x + bend, y: startY + length), control: CGPoint(x: x + bend * 1.3, y: startY + length * 0.45))
                    p.context.stroke(twig, with: .color(Color(dinoHex: 0x436E63)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                    for pair in 0..<7 {
                        let t = CGFloat(pair + 1) / 8
                        let origin = CGPoint(x: x + bend * (2.6 * t - 1.6 * t * t), y: startY + length * t)
                        for side in [-1.0, 1.0] {
                            p.leaf(at: origin, length: 15 - t * 4, width: 5 - t, angle: 180 + side * 30,
                                   light: row == 1 && (strand + pair) % 3 != 0)
                        }
                    }
                    p.leaf(at: CGPoint(x: x + bend, y: startY + length - 3), length: 17, width: 4, angle: 180, light: row == 1)
                }
            }
            p.plants(at: CGPoint(x: -16, y: 11), size: 0.75)
        }
    }

    private func plants(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for i in 0..<7 {
                p.leaf(at: CGPoint(x: CGFloat(i % 3) * 5, y: CGFloat(i % 2) * 4), length: CGFloat(28 + i % 3 * 12),
                       width: CGFloat(8 + i % 2 * 3), angle: Double(i * 26 - 78), light: i % 3 == 0)
            }
        }
    }

    private func rock(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            let pts: [CGPoint] = [.init(x: -35, y: 10), .init(x: -30, y: -14), .init(x: -12, y: -35), .init(x: 15, y: -38), .init(x: 37, y: -13), .init(x: 29, y: 12)]
            p.polygon(pts, colors: [0xD0CECD, 0x9CA9AD, 0x687F8C])
            p.polygon([pts[1], pts[2], pts[3], .init(x: 2, y: -16)], colors: [0xDBD6D2, 0xAFB9BD])
            p.polygon([pts[3], pts[4], pts[5], .init(x: -1, y: 9), .init(x: 2, y: -16)], colors: [0x9BA7B2, 0x5F798B])
            p.line([.init(x: -23, y: -13), .init(x: -13, y: -7), .init(x: -9, y: -12)], color: 0x637F88, width: 0.8, opacity: 0.6)
            p.leaf(at: CGPoint(x: -20, y: -17), length: 16, width: 7, angle: -68, light: true)
            p.leaf(at: CGPoint(x: -19, y: -17), length: 18, width: 7, angle: 27, light: true)
        }
    }

    private func mushroom(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.glow(CGPoint(x: 0, y: -10), radius: 55, color: 0xFFE1A0, opacity: 0.33)
            let stem = Path { s in
                s.move(to: CGPoint(x: -7, y: 2)); s.addQuadCurve(to: CGPoint(x: -5, y: -38), control: CGPoint(x: -3, y: -22))
                s.addLine(to: CGPoint(x: 7, y: -38)); s.addQuadCurve(to: CGPoint(x: 9, y: 2), control: CGPoint(x: 4, y: -17)); s.closeSubpath()
            }
            p.material(stem, colors: [0xFFEDB4, 0xEFD296, 0xB19C7B])
            p.oval(CGRect(x: -34, y: -29, width: 68, height: 14), colors: [0xFFF8D3, 0xF0D59C, 0xD0B391])
            for i in 0..<7 {
                p.line([.init(x: 0, y: -25), .init(x: CGFloat(i - 3) * 9, y: -23)], color: 0xA89B89, width: 0.7, opacity: 0.5)
            }
            let cap = Path { c in
                c.move(to: CGPoint(x: -35, y: -25))
                c.addCurve(to: CGPoint(x: -2, y: -62), control1: CGPoint(x: -29, y: -47), control2: CGPoint(x: -19, y: -64))
                c.addCurve(to: CGPoint(x: 35, y: -25), control1: CGPoint(x: 16, y: -65), control2: CGPoint(x: 31, y: -43))
                c.addQuadCurve(to: CGPoint(x: -35, y: -25), control: CGPoint(x: 2, y: -13)); c.closeSubpath()
            }
            p.material(cap, colors: [0xDBB6DA, 0xAA8AC2, 0x786D9E])
            p.context.stroke(cap, with: .color(Color(dinoHex: 0xECE0ED).opacity(0.55)), lineWidth: 0.8)
            for (x, y, r): (CGFloat, CGFloat, CGFloat) in [(-15, -39, 3), (3, -51, 3.5), (19, -34, 4), (-1, -30, 2.5)] {
                p.oval(CGRect(x: x - r, y: y - r * 0.6, width: r * 2, height: r * 1.2), colors: [0xFFF8D2, 0xEAD6AE])
            }
        }
    }

    private func bellflowers(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for i in 0..<3 {
                let x = CGFloat(i - 1) * 16, y = CGFloat(i % 2) * -17 - 27
                var stem = Path(); stem.move(to: CGPoint(x: x, y: 8))
                stem.addQuadCurve(to: CGPoint(x: x + 4, y: y - 17), control: CGPoint(x: x - 12, y: y - 25))
                p.context.stroke(stem, with: .color(Color(dinoHex: 0x6A9581)), style: StrokeStyle(lineWidth: 1.7, lineCap: .round))
                let bell = Path { b in
                    b.move(to: CGPoint(x: x + 3, y: y - 18))
                    b.addCurve(to: CGPoint(x: x - 10, y: y + 3), control1: CGPoint(x: x - 9, y: y - 16), control2: CGPoint(x: x - 6, y: y - 3))
                    b.addQuadCurve(to: CGPoint(x: x - 2, y: y + 3), control: CGPoint(x: x - 5, y: y + 8))
                    b.addQuadCurve(to: CGPoint(x: x + 7, y: y + 4), control: CGPoint(x: x + 2, y: y + 11))
                    b.addQuadCurve(to: CGPoint(x: x + 16, y: y + 1), control: CGPoint(x: x + 12, y: y + 7))
                    b.addQuadCurve(to: CGPoint(x: x + 3, y: y - 18), control: CGPoint(x: x + 10, y: y - 16)); b.closeSubpath()
                }
                p.material(bell, colors: [0xEEE1ED, 0xC0AED2, 0x8C84B4])
                p.line([.init(x: x + 3, y: y + 2), .init(x: x + 3, y: y + 9)], color: 0xF8DEAA, width: 2)
                p.leaf(at: CGPoint(x: x, y: -4), length: 19, width: 6, angle: -63, light: false)
            }
        }
    }

    private func creek(at point: CGPoint, length: CGFloat, scale: CGFloat, mirror: Bool) {
        at(point, mirror: mirror) { p in
            var water = Path(); water.move(to: .zero)
            for i in 0..<6 {
                let y = CGFloat(i) * length / 6
                water.addCurve(to: CGPoint(x: i % 2 == 0 ? 11 * scale : -10 * scale, y: y + length / 6),
                               control1: CGPoint(x: 30 * scale, y: y + length / 18), control2: CGPoint(x: -22 * scale, y: y + length / 8))
            }
            p.context.stroke(water, with: .color(Color(dinoHex: 0x7C9C98).opacity(0.7)), style: StrokeStyle(lineWidth: 63 * scale, lineCap: .round))
            p.context.stroke(water, with: .color(Color(dinoHex: 0x669DAA).opacity(0.85)), style: StrokeStyle(lineWidth: 48 * scale, lineCap: .round))
            p.context.stroke(water, with: .color(Color(dinoHex: 0xDAECE0).opacity(0.5)), style: StrokeStyle(lineWidth: 1.3, lineCap: .round, dash: [12, 31]))
            for i in 0..<18 {
                let y = CGFloat(i) * length / 18 + 17
                let x = CGFloat(i % 3 - 1) * 6
                p.line([.init(x: x - 9, y: y), .init(x: x + 8, y: y - 1)], color: 0xC6E3DC, width: 1.2, opacity: 0.55)
                if i % 4 == 0 {
                    p.oval(CGRect(x: x - 3, y: y - 3, width: 16, height: 7), colors: [0xBED2A0, 0x72A28D])
                    p.line([.init(x: x + 5, y: y), .init(x: x + 10, y: y - 1)], color: 0x4B837C, width: 0.7)
                }
            }
        }
    }

    private func bridge(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.polygon([.init(x: -48, y: -9), .init(x: 41, y: -13), .init(x: 53, y: 15), .init(x: -49, y: 20)], colors: [0xD6B891, 0x9C8169, 0x7D7163])
            for i in 0..<8 {
                let x = CGFloat(i) * 12 - 43
                p.line([.init(x: x, y: -7), .init(x: x + 3, y: 14)], color: 0x695E54, width: 1, opacity: 0.7)
                p.line([.init(x: x + 3, y: -5), .init(x: x + 5, y: 11)], color: 0xF0D1A1, width: 0.8, opacity: 0.6)
            }
            for x: CGFloat in [-43, 43] {
                p.material(Path(roundedRect: CGRect(x: x - 3, y: -30, width: 7, height: 45), cornerRadius: 2), colors: [0xDCC294, 0x8E7B64])
                p.oval(CGRect(x: x - 5, y: -33, width: 11, height: 5), colors: [0xEDCF9C, 0xA58B68])
            }
            var rail = Path(); rail.move(to: CGPoint(x: -43, y: -22))
            rail.addQuadCurve(to: CGPoint(x: 43, y: -24), control: CGPoint(x: 0, y: -9))
            p.context.stroke(rail, with: .color(Color(dinoHex: 0xC3AD82)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }

    private func alarmClock(at point: CGPoint, size: CGFloat, hour: Int) {
        at(point, size: size) { p in
            p.glow(CGPoint(x: 0, y: -15), radius: 43, color: 0xFFE4A7, opacity: 0.25)
            for x: CGFloat in [-19, 19] {
                p.line([.init(x: x, y: -3), .init(x: x * 1.2, y: 5)], color: 0xD7B880, width: 4)
                p.oval(CGRect(x: x - 10, y: -55, width: 20, height: 12), colors: [0xF9DDA5, 0xBFA274])
            }
            p.material(Path(roundedRect: CGRect(x: -34, y: -47, width: 68, height: 45), cornerRadius: 13), colors: [0xD5C6E6, 0xA194C2, 0x7D7EAA])
            let face = Path(roundedRect: CGRect(x: -28, y: -40, width: 56, height: 29), cornerRadius: 7)
            p.material(face, colors: [0x344D62, 0x223C50])
            p.context.stroke(face, with: .color(Color(dinoHex: 0xE6D5AC)), lineWidth: 1.4)
            p.context.draw(Text(verbatim: String(format: "%02d:30", hour)).font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundStyle(Color(dinoHex: 0xFFE9A6)),
                           at: CGPoint(x: 0, y: -25))
            p.line([.init(x: -9, y: -55), .init(x: 9, y: -55)], color: 0xAF9D89, width: 2)
        }
    }

    func garden(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -61, y: -7, width: 122, height: 31), colors: [0xC7D6B9, 0x9DB8A3, 0xAFC5B6])
            switch variation % 3 {
            case 0:
                p.rock(at: CGPoint(x: 8, y: 8), size: 0.83)
                p.mushroom(at: CGPoint(x: -20, y: -4), size: 0.87)
                p.mushroom(at: CGPoint(x: 31, y: 15), size: 0.43)
                p.bellflowers(at: CGPoint(x: 22, y: -24), size: 0.62)
            case 1:
                p.rock(at: CGPoint(x: -3, y: 1), size: 1)
                p.alarmClock(at: CGPoint(x: -1, y: -29), size: 0.88, hour: variation % 2 == 0 ? 7 : 3)
                p.mushroom(at: CGPoint(x: -38, y: 15), size: 0.49)
                p.bellflowers(at: CGPoint(x: 34, y: 0), size: 0.56)
            default:
                p.willow(at: CGPoint(x: 6, y: -3), size: 0.62, mirror: false, variation: variation)
                p.mushroom(at: CGPoint(x: -33, y: 17), size: 0.66)
                p.rock(at: CGPoint(x: 36, y: 17), size: 0.43)
            }
            p.plants(at: CGPoint(x: -37, y: 17), size: 0.73)
            p.plants(at: CGPoint(x: 38, y: 23), size: 0.59)
        }
    }
}

/// Warm basalt, lava terraces and a distant summit are scoped to world three.
private struct VolcanoWorldPainter {
    let context: GraphicsContext

    private func at(_ point: CGPoint, size: CGFloat = 1, mirror: Bool = false, draw: (VolcanoWorldPainter) -> Void) {
        var c = context; c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: mirror ? -size : size, y: size)
        draw(.init(context: c))
    }
    private func material(_ path: Path, colors: [UInt32]) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
    }
    private func polygon(_ points: [CGPoint], colors: [UInt32]) {
        var p = Path(); p.addLines(points); p.closeSubpath(); material(p, colors: colors)
    }
    private func oval(_ r: CGRect, colors: [UInt32]) {
        context.fill(Path(ellipseIn: r), with: .radialGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                            center: CGPoint(x: r.minX + r.width * 0.32, y: r.minY + r.height * 0.22),
                                                            startRadius: 0, endRadius: max(r.width, r.height) * 0.85))
    }
    private func line(_ points: [CGPoint], color: UInt32, width: CGFloat, opacity: Double = 1) {
        var p = Path(); p.addLines(points)
        context.stroke(p, with: .color(Color(dinoHex: color).opacity(opacity)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func glow(_ point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), Color(dinoHex: color).opacity(0)]),
                                           center: point, startRadius: 0, endRadius: radius))
    }
    private func lava(_ path: Path, width: CGFloat) {
        let r = path.boundingRect
        context.stroke(path, with: .color(Color(dinoHex: 0x4A4353).opacity(0.5)), style: StrokeStyle(lineWidth: width + 7, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFD67A), Color(dinoHex: 0xFF9755), Color(dinoHex: 0xDE6A50)]),
                                                  startPoint: CGPoint(x: r.midX, y: r.minY), endPoint: CGPoint(x: r.midX, y: r.maxY)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(Color(dinoHex: 0xFFE6A1).opacity(0.85)), style: StrokeStyle(lineWidth: max(1, width * 0.3), lineCap: .round, lineJoin: .round))
    }

    func landscape(in size: CGSize, routeOffset: CGFloat) {
        let w = size.width, h = size.height
        let left: CGFloat = 0, right = w - left
        let scale = min(1.30, max(0.82, w / 390))
        let horizon = (routeOffset + 135) / h
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: 0xFFD1A1), location: 0),
            .init(color: Color(dinoHex: 0x9E8CA8), location: 0.035),
            .init(color: Color(dinoHex: 0xDDA08D), location: horizon * 0.55),
            .init(color: Color(dinoHex: 0xFFE0AB), location: horizon),
            .init(color: Color(dinoHex: 0xE7C7A7), location: 0.38),
            .init(color: Color(dinoHex: 0xDEC3A4), location: 0.62),
            .init(color: Color(dinoHex: 0xCCC8A5), location: 0.83),
            .init(color: Color(dinoHex: 0xC7E8BE), location: 1)
        ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
        sky(width: w, left: left, right: right, height: routeOffset + 110, scale: scale)
        var c = context; c.translateBy(x: 0, y: routeOffset)
        let p = VolcanoWorldPainter(context: c)
        let nature = JunglePainter(context: c)
        for i in 0..<6 {
            let y = CGFloat(i) * 290 + 20
            nature.hill(x: i % 2 == 0 ? -w * 0.4 : w * 0.57, y: y, width: w * 0.88, height: 270,
                        color: Color(dinoHex: i % 2 == 0 ? 0x928D87 : 0xACAB85).opacity(0.18))
            p.glow(CGPoint(x: w * 0.5, y: y + 90), radius: w * 0.35, color: 0xFFF1C7, opacity: 0.17)
        }
        // Falls and their cooled banks stay at the map edge, away from the route.
        p.terrace(at: CGPoint(x: left + 3, y: 315), size: scale * 0.88, mirror: false)
        p.terrace(at: CGPoint(x: right + 15, y: 680), size: scale * 1.05, mirror: true)
        p.terrace(at: CGPoint(x: left - 7, y: 1105), size: scale, mirror: false)
        p.terrace(at: CGPoint(x: right + 9, y: 1460), size: scale * 0.94, mirror: true)
        // The smaller rocky destinations, including their clocks, sit in front
        // of the palms so their faces remain readable beneath the leaves.
        p.palm(at: CGPoint(x: left - 6, y: 574), size: scale * 0.94, mirror: false)
        p.palm(at: CGPoint(x: right + 17, y: 1115), size: scale, mirror: true)
        p.palm(at: CGPoint(x: left - 13, y: 1560), size: scale * 0.91, mirror: false)
        for index in 0..<9 {
            let onRight = index % 4 == 0 || index % 4 == 3
            let x = onRight ? right - 31 * scale : left + 31 * scale
            let y = 183 + CGFloat(index) * 175
            p.scene(at: CGPoint(x: x, y: y), size: scale * 0.91, variation: index)
            let edge = onRight ? left : right
            p.at(CGPoint(x: edge, y: y + 90), size: scale, mirror: onRight) { garden in
                garden.rock(at: CGPoint(x: 5, y: 8), size: 0.61)
                garden.plants(at: CGPoint(x: 31, y: 12), size: 0.78)
                if index % 3 == 0 { garden.crystal(at: CGPoint(x: 10, y: -17), size: 0.65) }
            }
        }
        p.bridge(at: CGPoint(x: left + 27 * scale, y: 915), size: scale * 0.85)
        for i in 0..<24 {
            let side = i % 2 == 0
            let x = (side ? left + 48 : right - 48) + CGFloat(i % 3 - 1) * 12
            let y = 50 + CGFloat(i) * 68
            nature.grass(at: CGPoint(x: x, y: y), size: 5 * scale, color: Color(dinoHex: 0x919165).opacity(0.56))
            if i % 3 == 0 {
                p.line([.init(x: x - 5, y: y + 15), .init(x: x, y: y + 18), .init(x: x + 7, y: y + 16)], color: 0xC6AB90, width: 1, opacity: 0.7)
            }
        }
        p.steam(at: CGPoint(x: w * 0.5, y: 1685), width: w * 1.1, opacity: 0.10)
    }

    private func sky(width: CGFloat, left: CGFloat, right: CGFloat, height: CGFloat, scale: CGFloat) {
        let sun = CGPoint(x: width * 0.23, y: 101)
        glow(sun, radius: 145 * scale, color: 0xFFE6AC, opacity: 0.65)
        oval(CGRect(x: sun.x - 24, y: sun.y - 24, width: 48, height: 48), colors: [0xFFF5CE, 0xFFE4AA, 0xF6C391])
        for (x, y, s) in [(width * 0.20, CGFloat(57), CGFloat(0.9)), (width * 0.56, CGFloat(123), CGFloat(0.8)), (width * 0.87, CGFloat(35), CGFloat(0.65))] {
            at(CGPoint(x: x, y: y), size: s * scale) { p in
                var cloud = Path()
                for (cx, cy, cw, ch): (CGFloat, CGFloat, CGFloat, CGFloat) in [(-64, 0, 83, 18), (-39, -15, 51, 32), (-5, -22, 62, 40), (35, -3, 58, 22)] {
                    cloud.addEllipse(in: CGRect(x: cx, y: cy, width: cw, height: ch))
                }
                p.context.drawLayer { c in
                    c.addFilter(.blur(radius: 2))
                    c.fill(cloud, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFE0BC).opacity(0.78), Color(dinoHex: 0xE7B6AC).opacity(0)]),
                                                       startPoint: CGPoint(x: 0, y: -22), endPoint: CGPoint(x: 0, y: 22)))
                }
            }
        }
        var rear = context; rear.opacity = 0.44
        let distant = VolcanoWorldPainter(context: rear)
        for i in 0..<3 {
            let x = CGFloat(i) * width * 0.28 - width * 0.08
            distant.at(CGPoint(x: x, y: height * 0.85 + CGFloat(i % 2) * 24), size: scale * (0.53 + CGFloat(i % 3) * 0.12)) { p in
                p.columns(at: .zero, size: 1, count: 3)
                JunglePainter(context: p.context).hill(x: -80, y: -16, width: 165, height: 47, color: Color(dinoHex: 0xA79799).opacity(0.6))
                p.steam(at: CGPoint(x: 0, y: 5), width: 163, opacity: 0.47)
            }
        }
        // The summit rises above the chapter sign; its slopes remain behind it.
        volcano(at: CGPoint(x: right - 56 * scale, y: height - 70), size: scale * 0.97)
        at(CGPoint(x: left + 12, y: height * 0.86), size: scale * 0.67) { $0.terrace(at: .zero, size: 1, mirror: false) }
        steam(at: CGPoint(x: width * 0.5, y: height * 0.92), width: width * 1.12, opacity: 0.23)
    }

    private func steam(at point: CGPoint, width: CGFloat, opacity: Double) {
        context.drawLayer { c in
            c.addFilter(.blur(radius: 7))
            for i in 0..<3 {
                let r = CGRect(x: point.x - width * 0.5 + CGFloat(i - 1) * 12,
                               y: point.y + CGFloat(i) * 9, width: width, height: 19 + CGFloat(i) * 6)
                c.fill(Path(ellipseIn: r), with: .color(Color(dinoHex: 0xFBE4D1).opacity(opacity * (1 - Double(i) * 0.17))))
            }
        }
    }

    private func volcano(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { base in
            // Merge the mountain's foot into atmospheric haze rather than
            // leaving a straight cut across the distant ground.
            var mountainContext = base.context
            mountainContext.clipToLayer { mask in
                mask.fill(Path(CGRect(x: -180, y: -400, width: 360, height: 445)),
                          with: .linearGradient(Gradient(stops: [
                            .init(color: .white, location: 0),
                            .init(color: .white, location: 0.84),
                            .init(color: .white.opacity(0), location: 1)
                          ]), startPoint: CGPoint(x: 0, y: -400), endPoint: CGPoint(x: 0, y: 35)))
            }
            let p = VolcanoWorldPainter(context: mountainContext)
            p.glow(CGPoint(x: 0, y: -205), radius: 75, color: 0xFFCD83, opacity: 0.35)
            let mountain = Path { m in
                m.addLines([.init(x: -127, y: 9), .init(x: -93, y: -61), .init(x: -75, y: -79), .init(x: -42, y: -177),
                            .init(x: -24, y: -221), .init(x: -7, y: -228), .init(x: 26, y: -221),
                            .init(x: 45, y: -170), .init(x: 62, y: -147), .init(x: 78, y: -92),
                            .init(x: 106, y: -51), .init(x: 133, y: 9)])
                m.closeSubpath()
            }
            p.material(mountain, colors: [0xB39394, 0x777A8C, 0x565E77])
            p.polygon([.init(x: -24, y: -221), .init(x: -7, y: -228), .init(x: -17, y: -139),
                       .init(x: -57, y: -60), .init(x: -72, y: 4), .init(x: -112, y: 9), .init(x: -67, y: -84)],
                      colors: [0xD2AC9A, 0xA18F91, 0x7B7D8D])
            p.polygon([.init(x: 26, y: -221), .init(x: 45, y: -170), .init(x: 78, y: -92),
                       .init(x: 133, y: 9), .init(x: 69, y: 7), .init(x: 28, y: -105)],
                      colors: [0xBD9A97, 0x7A778C, 0x4E5972])
            for i in 0..<5 {
                let y = -151 + CGFloat(i) * 33
                p.line([.init(x: -48 - CGFloat(i) * 8, y: y), .init(x: -30 - CGFloat(i) * 7, y: y + 8),
                        .init(x: -20 - CGFloat(i) * 4, y: y + 5)], color: 0xE0B6A0, width: 1, opacity: 0.42)
                p.line([.init(x: 30 + CGFloat(i) * 8, y: y + 5), .init(x: 52 + CGFloat(i) * 9, y: y + 13)], color: 0x3D4A62, width: 1.2, opacity: 0.45)
            }
            var flow = Path(); flow.addLines([.init(x: 7, y: -215), .init(x: -2, y: -178), .init(x: 12, y: -137), .init(x: 3, y: -96), .init(x: 22, y: -48), .init(x: 16, y: 2)])
            p.lava(flow, width: 9)
            var branch = Path(); branch.addLines([.init(x: -10, y: -218), .init(x: -25, y: -171), .init(x: -31, y: -144), .init(x: -58, y: -104), .init(x: -65, y: -56)])
            p.lava(branch, width: 4)
            var side = Path(); side.addLines([.init(x: 18, y: -211), .init(x: 33, y: -159), .init(x: 58, y: -116), .init(x: 75, y: -62)])
            p.lava(side, width: 3)
            p.oval(CGRect(x: -28, y: -230, width: 57, height: 20), colors: [0xA19594, 0x555B70, 0x424D65])
            p.oval(CGRect(x: -20, y: -225, width: 41, height: 12), colors: [0xFFF0B4, 0xFFBD6D, 0xF58153])
            p.glow(CGPoint(x: 0, y: -224), radius: 34, color: 0xFFD38A, opacity: 0.53)
            p.context.drawLayer { c in
                c.addFilter(.blur(radius: 3))
                for i in 0..<5 {
                    let r = CGRect(x: -16 + CGFloat(i) * 9, y: -250 - CGFloat(i) * 21,
                                   width: 35 + CGFloat(i) * 9, height: 24 + CGFloat(i) * 6)
                    c.fill(Path(ellipseIn: r), with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xF9C69F).opacity(0.53), Color(dinoHex: 0xB6A1AC).opacity(0.17)]),
                                                                 startPoint: CGPoint(x: r.midX, y: r.maxY), endPoint: CGPoint(x: r.midX, y: r.minY)))
                }
            }
            for i in 0..<7 {
                let x = CGFloat(i % 2 == 0 ? -1 : 1) * CGFloat(8 + i * 3)
                let y = -239 - CGFloat(i % 4) * 9
                p.glow(CGPoint(x: x, y: y), radius: 4, color: 0xFFD17E, opacity: 0.4)
                p.oval(CGRect(x: x, y: y, width: 1.5, height: 2.5), colors: [0xFFF1B6, 0xFFB363])
            }
        }
    }

    private func columns(at point: CGPoint, size: CGFloat, count: Int) {
        at(point, size: size) { p in
            for i in 0..<count {
                let x = CGFloat(i) * 27 - CGFloat(count - 1) * 13.5
                let h = CGFloat([83, 114, 102, 127, 91][i % 5])
                p.polygon([.init(x: x - 16, y: 10), .init(x: x - 14, y: -h), .init(x: x + 4, y: -h - 8),
                           .init(x: x + 18, y: -h + 2), .init(x: x + 18, y: 10)], colors: [0xB5A39E, 0x777C8C, 0x505B72])
                p.polygon([.init(x: x + 4, y: -h - 8), .init(x: x + 18, y: -h + 2), .init(x: x + 18, y: 10), .init(x: x + 3, y: 10)],
                          colors: [0x8D8895, 0x4E5B74])
                p.polygon([.init(x: x - 14, y: -h), .init(x: x + 4, y: -h - 8), .init(x: x + 18, y: -h + 2), .init(x: x, y: -h + 8)],
                          colors: [0xD2B9AA, 0x99929B])
                p.line([.init(x: x - 10, y: -h + 9), .init(x: x - 11, y: -h * 0.55)], color: 0xE4BDA5, width: 1.1, opacity: 0.45)
                p.line([.init(x: x - 13, y: -h * 0.46), .init(x: x - 4, y: -h * 0.42), .init(x: x + 4, y: -h * 0.45)], color: 0x394A63, width: 1.1, opacity: 0.5)
            }
        }
    }

    private func terrace(at point: CGPoint, size: CGFloat, mirror: Bool) {
        at(point, size: size, mirror: mirror) { p in
            p.oval(CGRect(x: -86, y: 9, width: 174, height: 45), colors: [0xA29188, 0x7B7A83, 0xA59C8C])
            p.oval(CGRect(x: -75, y: 11, width: 149, height: 33), colors: [0xFFE6A0, 0xFFB35E, 0xE17F55])
            p.glow(CGPoint(x: 0, y: 23), radius: 84, color: 0xFFD080, opacity: 0.3)
            p.columns(at: .zero, size: 1, count: 5)
            var source = Path(); source.move(to: CGPoint(x: 46, y: -117))
            source.addCurve(to: CGPoint(x: 7, y: -107), control1: CGPoint(x: 25, y: -126), control2: CGPoint(x: 24, y: -103))
            p.lava(source, width: 10)
            let fall = Path { f in
                f.move(to: CGPoint(x: -7, y: -107))
                f.addCurve(to: CGPoint(x: -19, y: 15), control1: CGPoint(x: -1, y: -63), control2: CGPoint(x: -15, y: -18))
                f.addQuadCurve(to: CGPoint(x: 24, y: 17), control: CGPoint(x: 1, y: 28))
                f.addCurve(to: CGPoint(x: 17, y: -108), control1: CGPoint(x: 14, y: -26), control2: CGPoint(x: 25, y: -64)); f.closeSubpath()
            }
            p.material(fall, colors: [0xFFE6A0, 0xFFB966, 0xF68C50, 0xFFD27D])
            var molten = p.context; molten.clip(to: fall)
            for i in 0..<6 {
                let x = CGFloat(i) * 6 - 12
                var streak = Path(); streak.move(to: CGPoint(x: x, y: -112 + CGFloat(i % 3) * 11))
                streak.addCurve(to: CGPoint(x: x * 1.5, y: 23), control1: CGPoint(x: x + 6, y: -68), control2: CGPoint(x: x - 5, y: -27))
                molten.stroke(streak, with: .color(Color(dinoHex: i % 2 == 0 ? 0xFFF0AE : 0xE56B46).opacity(0.7)),
                              style: StrokeStyle(lineWidth: i % 2 == 0 ? 2.4 : 1.3, lineCap: .round))
            }
            p.rock(at: CGPoint(x: -53, y: 26), size: 0.62)
            p.rock(at: CGPoint(x: 62, y: 29), size: 0.48)
            p.plants(at: CGPoint(x: -48, y: -98), size: 0.63)
            p.crystal(at: CGPoint(x: 58, y: -80), size: 0.62)
            for i in 0..<4 {
                let x = CGFloat(i) * 23 - 40
                p.line([.init(x: x, y: 29 + CGFloat(i % 2) * 5), .init(x: x + 8, y: 26 + CGFloat(i % 2) * 5),
                        .init(x: x + 18, y: 29 + CGFloat(i % 2) * 5)], color: 0xFFF0B0, width: 1.1, opacity: 0.75)
            }
            p.steam(at: CGPoint(x: 0, y: 32), width: 156, opacity: 0.27)
            for i in 0..<5 {
                let x = CGFloat(i % 2 == 0 ? -1 : 1) * CGFloat(18 + i * 5)
                let y = 2 - CGFloat(i % 3) * 14
                p.glow(CGPoint(x: x, y: y), radius: 5, color: 0xFFD17E, opacity: 0.25)
                p.oval(CGRect(x: x, y: y, width: 1.7, height: 2.4), colors: [0xFFE9A6, 0xFFB76F])
            }
        }
    }

    private func rock(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            let pts: [CGPoint] = [.init(x: -36, y: 10), .init(x: -31, y: -14), .init(x: -13, y: -37),
                                  .init(x: 14, y: -39), .init(x: 37, y: -14), .init(x: 29, y: 13), .init(x: -4, y: 17)]
            p.polygon(pts, colors: [0xBFAAA0, 0x93909B, 0x65718A])
            p.polygon([pts[1], pts[2], pts[3], .init(x: 1, y: -16)], colors: [0xDAC1AC, 0xAAA1A4])
            p.polygon([pts[3], pts[4], pts[5], pts[6], .init(x: 1, y: -16)], colors: [0x8D8B9C, 0x525F79])
            p.line([.init(x: -23, y: -11), .init(x: -12, y: -7), .init(x: -7, y: -13)], color: 0x596781, width: 1, opacity: 0.7)
            p.line([.init(x: 11, y: -5), .init(x: 20, y: -1), .init(x: 29, y: -4)], color: 0xD6A98D, width: 0.8, opacity: 0.65)
        }
    }

    private func leaf(at point: CGPoint, length: CGFloat, width: CGFloat, angle: Double, copper: Bool) {
        var c = context; c.translateBy(x: point.x, y: point.y); c.rotate(by: .degrees(angle))
        let leaf = Path { p in
            p.move(to: .zero)
            p.addCurve(to: CGPoint(x: length * 0.13, y: -length), control1: CGPoint(x: -width, y: -length * 0.21), control2: CGPoint(x: -width * 0.9, y: -length * 0.76))
            p.addCurve(to: .zero, control1: CGPoint(x: width * 0.85, y: -length * 0.83), control2: CGPoint(x: width, y: -length * 0.23))
        }
        c.fill(leaf, with: .linearGradient(Gradient(colors: (copper ? [0xEABD7B, 0xC0835D, 0x886357] : [0xC7D38E, 0x8FA173, 0x516E62]).map { Color(dinoHex: $0) }),
                                          startPoint: CGPoint(x: -width * 0.5, y: -length), endPoint: CGPoint(x: width, y: 0)))
        var veins = Path(); veins.move(to: .zero); veins.addLine(to: CGPoint(x: length * 0.12, y: -length * 0.93))
        for i in 1...3 {
            let t = CGFloat(i) / 5
            for side: CGFloat in [-1, 1] {
                veins.move(to: CGPoint(x: length * 0.12 * t, y: -length * t))
                veins.addQuadCurve(to: CGPoint(x: width * 0.55 * side, y: -length * (t + 0.14)),
                                   control: CGPoint(x: width * 0.42 * side, y: -length * (t + 0.03)))
            }
        }
        c.stroke(veins, with: .color(Color(dinoHex: 0xF0DBA4).opacity(0.36)), style: StrokeStyle(lineWidth: 0.65, lineCap: .round))
    }

    private func plants(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for i in 0..<7 {
                p.leaf(at: CGPoint(x: CGFloat(i % 2) * 5, y: CGFloat(i % 3) * 2),
                       length: CGFloat(26 + i % 3 * 10), width: CGFloat(7 + i % 2 * 3),
                       angle: Double(i * 26 - 78), copper: i % 3 == 0)
            }
            for i in 0..<3 {
                p.oval(CGRect(x: CGFloat(i) * 10 - 7, y: -3 + CGFloat(i % 2) * 3, width: 4, height: 3), colors: [0xFFDE93, 0xD99E66])
            }
        }
    }

    private func palm(at point: CGPoint, size: CGFloat, mirror: Bool) {
        at(point, size: size, mirror: mirror) { p in
            let top = CGPoint(x: 29, y: -142)
            var trunk = Path(); trunk.move(to: .zero)
            trunk.addQuadCurve(to: top, control: CGPoint(x: -5, y: -99))
            p.context.stroke(trunk, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xD9B78A), Color(dinoHex: 0xB18D69), Color(dinoHex: 0x7F6D59)]),
                                                        startPoint: CGPoint(x: -7, y: -70), endPoint: CGPoint(x: 9, y: -64)),
                             style: StrokeStyle(lineWidth: 13, lineCap: .round))
            for i in 1..<8 {
                let t = CGFloat(i) / 9
                let x = -10 * t * (1 - t) + 29 * t * t
                let y = -198 * t * (1 - t) - 142 * t * t
                p.line([.init(x: x - 4, y: y - 1), .init(x: x, y: y + 2), .init(x: x + 5, y: y)], color: 0x735F50, width: 1.1, opacity: 0.65)
                p.line([.init(x: x - 4, y: y - 2), .init(x: x + 3, y: y - 1)], color: 0xE7C898, width: 0.8, opacity: 0.65)
            }
            for (i, angle) in [-112.0, 109, -73, 74, -35, 34, 1].enumerated() {
                p.leaf(at: top, length: i < 2 ? 93 : 81, width: 24, angle: angle, copper: i == 2 || i == 5)
            }
            p.plants(at: CGPoint(x: 2, y: 10), size: 0.7)
        }
    }

    private func crystal(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for i in 0..<3 {
                let x = CGFloat(i - 1) * 11
                let h: CGFloat = i == 1 ? 37 : 24
                p.polygon([.init(x: x - 7, y: 1), .init(x: x - 7, y: -h + 9), .init(x: x, y: -h), .init(x: x + 7, y: -h + 9), .init(x: x + 6, y: 1)],
                          colors: [0xFFE5A6, 0xF5B26B, 0xCD8057])
                p.line([.init(x: x, y: -h + 3), .init(x: x, y: -2)], color: 0xFFE8AC, width: 1, opacity: 0.7)
            }
        }
    }

    private func clock(at point: CGPoint, size: CGFloat, quarterPast: Bool) {
        at(point, size: size) { p in
            p.rock(at: CGPoint(x: 1, y: 9), size: 0.91)
            let housing = Path(roundedRect: CGRect(x: -36, y: -63, width: 72, height: 44), cornerRadius: 11)
            p.material(housing, colors: [0xC2A999, 0x96909A, 0x69738B])
            let display = Path(roundedRect: CGRect(x: -29, y: -56, width: 58, height: 27), cornerRadius: 6)
            p.material(display, colors: [0x41465C, 0x263E51])
            p.context.stroke(display, with: .color(Color(dinoHex: 0xF6D59D)), lineWidth: 1.3)
            p.context.draw(Text(verbatim: quarterPast ? "04:15" : "04:45").font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(dinoHex: 0xFFDB91)), at: CGPoint(x: 0, y: -42))
            for x: CGFloat in [-29, 29] {
                p.oval(CGRect(x: x - 1, y: -24, width: 2, height: 2), colors: [0xFFE7BB, 0xA68A73])
            }
            p.line([.init(x: -26, y: -64), .init(x: -16, y: -60), .init(x: -12, y: -64)], color: 0x65667B, width: 0.8)
        }
    }

    private func bridge(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -69, y: -8, width: 138, height: 29), colors: [0xF7D28A, 0xE69B68, 0xBE8A6D])
            p.polygon([.init(x: -61, y: -11), .init(x: 57, y: -15), .init(x: 65, y: 13), .init(x: -65, y: 18)], colors: [0xDAC0A3, 0xA19895, 0x767C8D])
            for i in 0..<7 {
                let x = CGFloat(i) * 17 - 53
                p.line([.init(x: x, y: -8), .init(x: x + 2, y: 11)], color: 0x59657D, width: 1.3, opacity: 0.75)
                p.line([.init(x: x + 3, y: -6), .init(x: x + 4, y: 9)], color: 0xF2D4AD, width: 0.8, opacity: 0.65)
            }
            for x: CGFloat in [-53, 53] {
                p.material(Path(roundedRect: CGRect(x: x - 7, y: -38, width: 15, height: 49), cornerRadius: 3), colors: [0xC2ABA0, 0x7C7F90, 0x56627A])
                p.oval(CGRect(x: x - 10, y: -42, width: 21, height: 8), colors: [0xE4C5A3, 0x9C9295])
                p.line([.init(x: x - 5, y: -17), .init(x: x + 5, y: -17)], color: 0x505F79, width: 0.9)
            }
            p.line([.init(x: -52, y: -27), .init(x: 52, y: -31)], color: 0x9F999A, width: 6)
            p.line([.init(x: -52, y: -29), .init(x: 52, y: -33)], color: 0xD5B9A0, width: 1.3)
        }
    }

    func scene(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -61, y: -5, width: 122, height: 29), colors: [0xC4BD95, 0xACA88C, 0xD2BDA1])
            switch variation % 3 {
            case 0:
                p.rock(at: CGPoint(x: -10, y: -3), size: 1.02)
                p.columns(at: CGPoint(x: 21, y: -8), size: 0.45, count: 3)
                p.crystal(at: CGPoint(x: -28, y: 9), size: 0.8)
            case 1:
                p.clock(at: CGPoint(x: -2, y: -2), size: 0.96, quarterPast: variation % 2 == 0)
                p.crystal(at: CGPoint(x: 33, y: 14), size: 0.63)
            default:
                p.oval(CGRect(x: -44, y: -14, width: 86, height: 27), colors: [0x7F7B86, 0x616A7D])
                p.oval(CGRect(x: -36, y: -11, width: 70, height: 18), colors: [0xFFE5A0, 0xF5A15D, 0xDE7F53])
                p.glow(CGPoint(x: 0, y: -1), radius: 39, color: 0xFFD291, opacity: 0.26)
                p.rock(at: CGPoint(x: 28, y: 9), size: 0.69)
                p.rock(at: CGPoint(x: -31, y: 9), size: 0.45)
                p.line([.init(x: -19, y: -5), .init(x: -9, y: -2), .init(x: 5, y: -5)], color: 0xFFE6A0, width: 1)
            }
            p.plants(at: CGPoint(x: -39, y: 18), size: 0.7)
            p.plants(at: CGPoint(x: 38, y: 23), size: 0.59)
        }
    }
}

/// Sunlit plaster, tiled roofs and planted waterways belong only to Dino Dorp.
private struct VillageWorldPainter {
    let context: GraphicsContext

    private func at(_ point: CGPoint, size: CGFloat = 1, mirror: Bool = false, draw: (VillageWorldPainter) -> Void) {
        var c = context
        c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: mirror ? -size : size, y: size)
        draw(.init(context: c))
    }
    private func material(_ path: Path, _ colors: [UInt32]) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
    }
    private func rounded(_ rect: CGRect, _ radius: CGFloat, _ colors: [UInt32]) {
        material(Path(roundedRect: rect, cornerRadius: radius), colors)
    }
    private func polygon(_ points: [CGPoint], _ colors: [UInt32]) {
        var p = Path(); p.addLines(points); p.closeSubpath(); material(p, colors)
    }
    private func oval(_ r: CGRect, _ colors: [UInt32]) {
        context.fill(Path(ellipseIn: r), with: .radialGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                            center: CGPoint(x: r.minX + r.width * 0.3, y: r.minY + r.height * 0.2),
                                                            startRadius: 0, endRadius: max(r.width, r.height) * 0.85))
    }
    private func line(_ points: [CGPoint], _ color: UInt32, _ width: CGFloat, opacity: Double = 1) {
        var p = Path(); p.addLines(points)
        context.stroke(p, with: .color(Color(dinoHex: color).opacity(opacity)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func glow(_ point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), Color(dinoHex: color).opacity(0)]),
                                           center: point, startRadius: 0, endRadius: radius))
    }

    func landscape(in size: CGSize, routeOffset: CGFloat) {
        let w = size.width, h = size.height
        let left: CGFloat = 0, right = w - left
        let scale = min(1.30, max(0.82, w / 390))
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: 0xC7E8BE), location: 0),
            .init(color: Color(dinoHex: 0x88D2E8), location: 0.035),
            .init(color: Color(dinoHex: 0xDDF1D8), location: (routeOffset + 80) / h),
            .init(color: Color(dinoHex: 0xD1E4AE), location: 0.32),
            .init(color: Color(dinoHex: 0xC8DEA8), location: 0.57),
            .init(color: Color(dinoHex: 0xC3DBAD), location: 0.80),
            .init(color: Color(dinoHex: 0xD8EEF0), location: 1)
        ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
        sky(width: w, left: left, right: right, height: routeOffset + 85, scale: scale)
        var c = context; c.translateBy(x: 0, y: routeOffset)
        let p = VillageWorldPainter(context: c)
        let nature = JunglePainter(context: c)
        for i in 0..<5 {
            nature.hill(x: i % 2 == 0 ? left - 220 : right - 100, y: CGFloat(i) * 370 + 15,
                        width: 360 * scale, height: 280, color: Color(dinoHex: i % 2 == 0 ? 0xA7C98F : 0xEEF0BC).opacity(0.34))
        }
        for side in 0..<2 {
            let edge = side == 0 ? left + 2 : right - 2
            p.waterway(at: CGPoint(x: edge, y: 0), size: scale, mirror: side == 1)
        }
        // Water and its banks sit behind the village; clocks remain unobstructed.
        p.cascade(at: CGPoint(x: left - 3, y: 850), size: scale * 0.85)
        p.cascade(at: CGPoint(x: right + 5, y: 1190), size: scale * 0.85, mirror: true)
        p.bridge(at: CGPoint(x: left + 12 * scale, y: 900), size: scale * 0.85)
        p.bridge(at: CGPoint(x: right - 10 * scale, y: 1210), size: scale * 0.8)
        for i in 0..<28 {
            let x = i % 2 == 0 ? left + CGFloat(33 + i % 3 * 12) : right - CGFloat(33 + i % 3 * 12)
            let y = 38 + CGFloat(i) * 60
            nature.grass(at: CGPoint(x: x, y: y), size: 6 * scale, color: Color(dinoHex: 0x7FA569).opacity(0.7))
            if i % 3 == 0 { p.flowers(at: CGPoint(x: x + 7, y: y + 12), size: scale * 0.4, pink: i % 2 == 0) }
        }
        let positions: [CGFloat] = [0.28, 0.5, 0.72, 0.5, 0.28, 0.5, 0.72, 0.5, 0.28, 0.5]
        let routeWidth = min(w, 600) - 36
        let shared = ThemePainter(context: c, colors: WorldThemeColors(DinoWorldCatalog.world(4)!))
        for index in 0..<9 {
            let onRight = index % 4 == 0 || index % 4 == 3
            let point = CGPoint(x: onRight ? right - 35 * scale : left + 35 * scale, y: 182 + CGFloat(index) * 175)
            let x = (w - routeWidth) / 2 + routeWidth * (positions[index] + (positions[index + 1] - positions[index]) * 0.622)
            shared.approach(from: CGPoint(x: x, y: point.y), to: point, city: false, scale: scale)
            p.scene(at: point, size: scale * 0.98, variation: index)
            let gardenX = onRight ? left + 5 * scale : right - 5 * scale
            p.garden(at: CGPoint(x: gardenX, y: point.y + 82), size: scale, variation: index)
        }
        // The planted banks gradually become the cool stone of the next chapter.
        context.fill(Path(CGRect(x: 0, y: h - 180, width: w, height: 180)),
                     with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xD8EEF0).opacity(0), Color(dinoHex: 0xD8EEF0)]),
                                           startPoint: CGPoint(x: 0, y: h - 180), endPoint: CGPoint(x: 0, y: h)))
    }

    private func sky(width: CGFloat, left: CGFloat, right: CGFloat, height: CGFloat, scale: CGFloat) {
        let sun = CGPoint(x: width * 0.2, y: 84)
        glow(sun, radius: 150 * scale, color: 0xFFF4BC, opacity: 0.75)
        oval(CGRect(x: sun.x - 22, y: sun.y - 22, width: 44, height: 44), [0xFFFBE0, 0xFFEDB0])
        for i in 0..<4 {
            at(CGPoint(x: width * (0.08 + CGFloat(i) * 0.29), y: 48 + CGFloat(i % 2) * 52), size: scale * (i % 2 == 0 ? 0.85 : 0.65)) { p in
                var cloud = Path()
                for r in [CGRect(x: -53, y: 0, width: 100, height: 20), CGRect(x: -33, y: -18, width: 48, height: 35), CGRect(x: 1, y: -26, width: 51, height: 45), CGRect(x: 31, y: -6, width: 45, height: 26)] { cloud.addEllipse(in: r) }
                p.context.drawLayer { c in
                    c.addFilter(.blur(radius: 1.5))
                    c.fill(cloud, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xFFFFEB).opacity(0.95), Color(dinoHex: 0xE1F1DC).opacity(0.08)]),
                                                       startPoint: CGPoint(x: 0, y: -28), endPoint: CGPoint(x: 0, y: 22)))
                }
            }
        }
        var far = context; far.opacity = 0.48
        far.clipToLayer { mask in
            mask.fill(Path(CGRect(x: 0, y: 0, width: width, height: height + 70)),
                      with: .linearGradient(Gradient(stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: 0.55),
                        .init(color: .white.opacity(0), location: 1)
                      ]), startPoint: CGPoint(x: 0, y: height * 0.45), endPoint: CGPoint(x: 0, y: height + 70)))
        }
        let p = VillageWorldPainter(context: far)
        for i in 0..<5 {
            p.at(CGPoint(x: left - 30 + CGFloat(i) * (right - left + 60) / 4, y: height * 0.78 + CGFloat(i % 2) * 26), size: scale * 1.1) { cliff in
                cliff.polygon([.init(x: -51, y: 36), .init(x: -42, y: -103), .init(x: -28, y: -119), .init(x: 20, y: -113), .init(x: 43, y: -86), .init(x: 59, y: 36)], [0xC2D9C3, 0x9CBEB5, 0x8EAFB2])
                cliff.polygon([.init(x: -28, y: -119), .init(x: -12, y: -92), .init(x: -16, y: 30), .init(x: -45, y: 35)], [0xD3E4C6, 0xA4C5B8])
                cliff.oval(CGRect(x: -45, y: -128, width: 80, height: 24), [0xC5DFA6, 0x83AF8E])
                if i == 0 || i == 4 {
                    cliff.rounded(CGRect(x: 8, y: -106, width: 12, height: 117), 4, [0xEEFBE7, 0x92DADD, 0xD4F2DB])
                    cliff.line([.init(x: 13, y: -101), .init(x: 13, y: 3)], 0xF2FFEA, 2, opacity: 0.8)
                }
            }
        }
        JunglePainter(context: context).hill(x: -width * 0.16, y: height * 0.68, width: width * 1.32, height: 190,
                                             color: Color(dinoHex: 0xB1D49C).opacity(0.6))
        // A recognisable tower rises above the title, with houses nestled below.
        tower(at: CGPoint(x: right - 90 * scale, y: 202 * scale), size: scale * 0.95)
        cottage(at: CGPoint(x: left + 47 * scale, y: height - 15), size: scale * 0.77, leafRoof: true)
        cottage(at: CGPoint(x: right - 18 * scale, y: height + 12), size: scale * 0.65, leafRoof: false)
        tree(at: CGPoint(x: left - 7, y: height + 19), size: scale * 0.96)
        tree(at: CGPoint(x: right + 20, y: height + 70), size: scale * 1.12)
        for i in 0..<3 {
            let x = width * 0.33 + CGFloat(i) * 18, y = 47 + CGFloat(i % 2) * 8
            var bird = Path(); bird.move(to: CGPoint(x: x - 5, y: y + 2))
            bird.addQuadCurve(to: CGPoint(x: x, y: y + 3), control: CGPoint(x: x - 2, y: y - 2))
            bird.addQuadCurve(to: CGPoint(x: x + 5, y: y), control: CGPoint(x: x + 2, y: y - 2))
            context.stroke(bird, with: .color(Color(dinoHex: 0x5B9299).opacity(0.65)), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
        }
    }

    private func leaf(at point: CGPoint, length: CGFloat, width: CGFloat, angle: Double) {
        at(point) { p in
            var c = p.context; c.rotate(by: .degrees(angle))
            let l = VillageWorldPainter(context: c)
            let shape = Path { path in
                path.move(to: .zero)
                path.addCurve(to: CGPoint(x: 0, y: -length), control1: CGPoint(x: -width, y: -length * 0.18), control2: CGPoint(x: -width * 0.7, y: -length * 0.8))
                path.addCurve(to: .zero, control1: CGPoint(x: width * 0.7, y: -length * 0.84), control2: CGPoint(x: width, y: -length * 0.24))
            }
            l.material(shape, [0xB6D86F, 0x609D64, 0x327A61])
            l.line([.zero, .init(x: 0, y: -length * 0.86)], 0xD8E99A, 0.8, opacity: 0.7)
            for i in 1...3 {
                let y = -length * CGFloat(i) * 0.21
                l.line([.init(x: 0, y: y), .init(x: width * 0.4, y: y - 5)], 0xD0E69B, 0.55, opacity: 0.45)
            }
        }
    }
    private func plants(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for i in 0..<5 { p.leaf(at: .zero, length: 22 + CGFloat(i % 3) * 5, width: 7, angle: Double(i - 2) * 30) }
        }
    }
    private func flowers(at point: CGPoint, size: CGFloat, pink: Bool) {
        at(point, size: size) { p in
            for i in 0..<3 {
                let x = CGFloat(i - 1) * 12, y = -7 - CGFloat(i % 2) * 8
                p.line([.init(x: x, y: 5), .init(x: x, y: y)], 0x639D66, 1.6)
                p.leaf(at: CGPoint(x: x, y: 0), length: 9, width: 3, angle: i % 2 == 0 ? 58 : -58)
                for j in 0..<5 {
                    let a = Double(j) * .pi * 0.4
                    p.oval(CGRect(x: x + CGFloat(cos(a)) * 4 - 3, y: y + CGFloat(sin(a)) * 4 - 3, width: 6, height: 6), pink ? [0xFFE5C9, 0xEC9C9D, 0xD88492] : [0xFFFFE4, 0xFFE9A5])
                }
                p.oval(CGRect(x: x - 2.1, y: y - 2.1, width: 4.2, height: 4.2), [0xFFF3A4, 0xEAB95C])
            }
        }
    }
    private func tree(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -37, y: -5, width: 79, height: 18), [0x93B582, 0xBBD29C])
            p.polygon([.init(x: -11, y: 0), .init(x: -5, y: -60), .init(x: -27, y: -89), .init(x: -20, y: -92), .init(x: 2, y: -69), .init(x: 15, y: -109), .init(x: 22, y: -104), .init(x: 7, y: -55), .init(x: 13, y: 0)], [0xCBA56A, 0x937B50, 0x6B6749])
            p.line([.init(x: -5, y: -4), .init(x: 0, y: -39), .init(x: -1, y: -61)], 0xE5C68A, 1.5, opacity: 0.7)
            for (x, y, s): (CGFloat, CGFloat, CGFloat) in [(-28,-88,0.8),(26,-94,0.88),(-7,-117,0.96),(0,-88,1.05)] {
                p.oval(CGRect(x: x - 28 * s, y: y - 22 * s, width: 58 * s, height: 49 * s), [0xC0D973, 0x7EB365, 0x43885D])
            }
            for i in 0..<13 {
                let x = CGFloat((i * 19) % 84) - 43, y = -81 - CGFloat((i * 13) % 49)
                p.leaf(at: CGPoint(x: x, y: y), length: 17, width: 6, angle: Double(i % 5 - 2) * 32)
            }
            for (x, y): (CGFloat, CGFloat) in [(-27,-96),(22,-103),(5,-79),(-8,-121)] {
                p.oval(CGRect(x: x - 4, y: y - 4, width: 9, height: 10), [0xFFE8A2, 0xF2BA68, 0xD99352])
                p.line([.init(x: x, y: y - 4), .init(x: x + 1, y: y - 7)], 0x6D7950, 1)
            }
            p.plants(at: CGPoint(x: -18, y: 5), size: 0.63)
        }
    }

    private func cottage(at point: CGPoint, size: CGFloat, leafRoof: Bool) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -48, y: -7, width: 100, height: 23), [0x92AB7C, 0xBED29F])
            let body = Path { b in
                b.move(to: CGPoint(x: -37, y: -5))
                b.addCurve(to: CGPoint(x: -26, y: -97), control1: CGPoint(x: -48, y: -30), control2: CGPoint(x: -39, y: -76))
                b.addQuadCurve(to: CGPoint(x: 26, y: -97), control: CGPoint(x: 0, y: -123))
                b.addCurve(to: CGPoint(x: 37, y: -5), control1: CGPoint(x: 40, y: -78), control2: CGPoint(x: 49, y: -30))
                b.addQuadCurve(to: CGPoint(x: -37, y: -5), control: CGPoint(x: 0, y: 11)); b.closeSubpath()
            }
            p.material(body, [0xFFF4D4, 0xEDDAB1, 0xC3B88E])
            p.context.stroke(body, with: .color(Color(dinoHex: 0xAD9E76).opacity(0.45)), lineWidth: 1)
            for (x,y): (CGFloat,CGFloat) in [(-32,-39),(29,-65),(-24,-79),(33,-19)] { p.oval(CGRect(x:x-3,y:y-2,width:6,height:5),[0xD5BE93,0xDDBF93]) }
            p.door(at: CGPoint(x: 0, y: -2), size: 1, teal: leafRoof)
            p.window(at: CGPoint(x: -24, y: -55), size: 0.83)
            p.window(at: CGPoint(x: 24, y: -55), size: 0.83)
            p.rounded(CGRect(x: 22, y: -123, width: 11, height: 29), 2, [0xF4DEB6, 0xC2AC85])
            p.rounded(CGRect(x: 19, y: -125, width: 17, height: 6), 2, [0xFFF0CE, 0xD1BA90])
            if leafRoof {
                let roof = Path { r in
                    r.move(to: CGPoint(x: -41, y: -94))
                    r.addQuadCurve(to: CGPoint(x: 0, y: -128), control: CGPoint(x: -28, y: -127))
                    r.addQuadCurve(to: CGPoint(x: 41, y: -94), control: CGPoint(x: 26, y: -128))
                    r.closeSubpath()
                }
                p.material(roof, [0x91B98A, 0x4F9479, 0x296D60])
                let angles: [Double] = [-125, -155, 180, 155, 125]
                for row in 0..<2 {
                    for i in 0..<5 {
                        p.leaf(at: CGPoint(x: CGFloat(i - 2) * 7, y: -121 + CGFloat(row) * 10),
                               length: 27 + CGFloat(row) * 5, width: 11, angle: angles[i])
                    }
                }
            } else { p.roof(at: CGPoint(x: 0, y: -93), width: 92, height: 38) }
            p.rounded(CGRect(x: -21, y: 0, width: 42, height: 6), 2, [0xF3E3BE, 0xC4B593])
            p.rounded(CGRect(x: -25, y: 5, width: 50, height: 6), 2, [0xE8D8B5, 0xADAA8B])
            p.flowers(at: CGPoint(x: -32, y: 5), size: 0.65, pink: true)
            p.plants(at: CGPoint(x: 37, y: 10), size: 0.77)
        }
    }
    private func roof(at point: CGPoint, width: CGFloat, height: CGFloat) {
        at(point) { p in
            let roof = Path { r in
                r.move(to: CGPoint(x: -width / 2, y: 4))
                r.addQuadCurve(to: CGPoint(x: -12, y: -height), control: CGPoint(x: -width * 0.36, y: -height))
                r.addQuadCurve(to: CGPoint(x: width / 2, y: 4), control: CGPoint(x: width * 0.29, y: -height - 9))
                r.closeSubpath()
            }
            p.material(roof, [0xF8C084, 0xD88961, 0xAC6C50])
            var tiles = p.context; tiles.clip(to: roof)
            let t = VillageWorldPainter(context: tiles)
            for row in 0..<4 {
                for col in 0..<7 {
                    let x = CGFloat(col - 3) * 15 + (row % 2 == 0 ? 0 : 7)
                    let y = -height + CGFloat(row) * 12
                    t.rounded(CGRect(x: x, y: y, width: 14, height: 14), 5, [0xF3B67C, row % 2 == 0 ? 0xDB966B : 0xD38B63, 0xB87454])
                    t.line([.init(x: x + 3, y: y + 3), .init(x: x + 9, y: y + 2)], 0xFFDEAB, 0.8, opacity: 0.8)
                }
            }
            p.line([.init(x: -width / 2, y: 4), .init(x: width / 2, y: 4)], 0x99674E, 3)
            p.line([.init(x: -width / 2 + 3, y: 2), .init(x: width / 2 - 3, y: 2)], 0xF7C99A, 1)
        }
    }
    private func door(at point: CGPoint, size: CGFloat, teal: Bool) {
        at(point, size: size) { p in
            let shape = Path(roundedRect: CGRect(x: -14, y: -37, width: 28, height: 38), cornerRadius: 13)
            p.context.stroke(shape, with: .color(Color(dinoHex: 0xB99A6B)), lineWidth: 6)
            p.material(shape, teal ? [0x6DA08A, 0x3F7D71, 0x396957] : [0xC49A68, 0x9C744C, 0x7C6243])
            for x: CGFloat in [-8, -2, 4, 10] { p.line([.init(x: x, y: -28), .init(x: x, y: -4)], teal ? 0xA0C2A2 : 0xE4BF87, 0.8, opacity: 0.65) }
            p.oval(CGRect(x: 6, y: -17, width: 4, height: 4), [0xFFF0B6, 0xDDB368])
            for y: CGFloat in [-23, -8] { p.rounded(CGRect(x: -13, y: y, width: 5, height: 2), 1, [0x777354, 0x6A654B]) }
        }
    }
    private func window(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.glow(.zero, radius: 23, color: 0xFFECA6, opacity: 0.3)
            p.rounded(CGRect(x: -10, y: -15, width: 20, height: 28), 9, [0xBD9464, 0x8A7952])
            p.rounded(CGRect(x: -7, y: -12, width: 14, height: 22), 6, [0xFFFFD8, 0xFFEBA4, 0xE9C781])
            p.line([.init(x: 0, y: -12), .init(x: 0, y: 10)], 0xE5C18A, 1.7)
            p.line([.init(x: -7, y: 0), .init(x: 7, y: 0)], 0xE5C18A, 1.7)
            p.line([.init(x: -5, y: -8), .init(x: -1, y: -4)], 0xFFFFFF, 1.5, opacity: 0.65)
            p.rounded(CGRect(x: -13, y: 11, width: 26, height: 4), 1.5, [0xEED5A5, 0xB39D74])
        }
    }
    private func tower(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -48, y: -5, width: 96, height: 20), [0x9CAF85, 0xC7D9A5])
            p.rounded(CGRect(x: -32, y: -158, width: 64, height: 159), 23, [0xFFF1CA, 0xE7D0A1, 0xBCAC81])
            for i in 0..<6 {
                let y = -17 - CGFloat(i) * 24
                p.line([.init(x: 20, y: y), .init(x: 29, y: y - 2)], 0xB49F78, 1, opacity: 0.6)
                p.line([.init(x: -28, y: y - 9), .init(x: -20, y: y - 9)], 0xFFF2CB, 1)
            }
            p.door(at: CGPoint(x: 0, y: -2), size: 0.9, teal: true)
            p.window(at: CGPoint(x: -18, y: -54), size: 0.55)
            p.window(at: CGPoint(x: 18, y: -54), size: 0.55)
            p.oval(CGRect(x: -27, y: -140, width: 54, height: 56), [0xF7D594, 0xB88A53, 0x8D754D])
            let clock = ThemePainter(context: p.context, colors: WorldThemeColors(DinoWorldCatalog.world(4)!))
            clock.clock(at: CGPoint(x: 0, y: -114), time: .init(hour: 10, minute: 10), size: 23)
            let roof = Path { r in
                r.move(to: CGPoint(x: -40, y: -155))
                r.addQuadCurve(to: CGPoint(x: 0, y: -188), control: CGPoint(x: -29, y: -184))
                r.addQuadCurve(to: CGPoint(x: 40, y: -155), control: CGPoint(x: 27, y: -187))
                r.closeSubpath()
            }
            p.material(roof, [0xACCC80, 0x5D9C70, 0x397E63])
            let angles: [Double] = [-125, -155, 180, 155, 125]
            for row in 0..<2 { for i in 0..<5 {
                p.leaf(at: CGPoint(x: CGFloat(i - 2) * 7, y: -184 + CGFloat(row) * 10), length: 25 + CGFloat(row) * 3, width: 10,
                       angle: angles[i])
            } }
            p.line([.init(x: 0, y: -173), .init(x: 0, y: -202)], 0xA18150, 2.5)
            p.polygon([.init(x: 1, y: -201), .init(x: 25, y: -196), .init(x: 16, y: -190), .init(x: 1, y: -192)], [0xFFE2A0, 0xE89B62])
            p.oval(CGRect(x: -3, y: -206, width: 6, height: 6), [0xFFF0B1, 0xCEA267])
            p.plants(at: CGPoint(x: -30, y: 6), size: 0.7)
            p.flowers(at: CGPoint(x: 30, y: 7), size: 0.75, pink: true)
            for i in 0..<3 { p.rounded(CGRect(x: -24 - CGFloat(i) * 5, y: CGFloat(i) * 5, width: 48 + CGFloat(i) * 10, height: 5), 1.5, [0xF1DDB6, 0xB7B48E]) }
        }
    }

    private func fence(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for y: CGFloat in [-19, -7] { p.rounded(CGRect(x: -39, y: y, width: 78, height: 5), 1.5, [0xE2BB7C, 0xA47F52]) }
            for x: CGFloat in [-36, -12, 12, 36] {
                p.rounded(CGRect(x: x - 3, y: -29, width: 7, height: 34), 2, [0xF1CC8C, 0xAA8857, 0x7D714F])
                p.oval(CGRect(x: x - 4, y: -31, width: 9, height: 4), [0xFFE1A5, 0xB6935C])
                p.line([.init(x: x + 1, y: -23), .init(x: x + 1, y: -4)], 0xF7D49A, 0.6)
            }
        }
    }
    private func market(at point: CGPoint, size: CGFloat, blue: Bool) {
        at(point, size: size) { p in
            for x: CGFloat in [-32, 32] { p.rounded(CGRect(x: x - 2, y: -65, width: 4, height: 70), 1, [0xE8C28B, 0x9F7C53]) }
            p.rounded(CGRect(x: -37, y: -19, width: 74, height: 24), 3, [0xEAC594, 0xBC9664, 0x977C52])
            for i in 0..<5 { p.line([.init(x: CGFloat(i) * 14 - 29, y: -16), .init(x: CGFloat(i) * 14 - 29, y: 2)], 0xF5D7A6, 0.8) }
            for row in 0..<2 { for i in 0..<8 {
                let x = CGFloat(i) * 8 - 29 + CGFloat(row) * 2, y = -23 - CGFloat(row) * 6
                let colors: [UInt32] = i < 3 ? [0xFFE88C,0xE8B25A] : i < 6 ? [0xF8BE85,0xD7805F] : [0xB4D97B,0x7DA15B]
                p.oval(CGRect(x:x,y:y,width:8,height:8),colors)
            } }
            for i in 0..<8 {
                let x = -40 + CGFloat(i) * 10
                let colors: [UInt32] = i % 2 == 0 ? [0xFFFFE4,0xF4E5BA] : blue ? [0x9ED7DC,0x509DA9] : [0xFFDA8A,0xE2AC58]
                p.polygon([.init(x:x+4,y:-67),.init(x:x+12,y:-67),.init(x:x+10,y:-43),.init(x:x,y:-43)],colors)
                p.rounded(CGRect(x:x,y:-44,width:10,height:9),4,colors)
            }
            p.line([.init(x:-35,y:-67),.init(x:35,y:-67)],0xD5B78B,2)
            p.oval(CGRect(x:-30,y:2,width:14,height:14),[0xA58A5D,0x7D6C4E])
            p.oval(CGRect(x:17,y:2,width:14,height:14),[0xA58A5D,0x7D6C4E])
            p.flowers(at: CGPoint(x: -41,y:9), size:0.6,pink:true)
        }
    }
    private func fountain(at point: CGPoint, size: CGFloat) {
        at(point, size:size) { p in
            p.oval(CGRect(x:-54,y:-12,width:108,height:40),[0x9EAE84,0xC6D5A1])
            p.oval(CGRect(x:-45,y:-23,width:90,height:41),[0xE8CDA4,0xBAA17F,0x968D70])
            for i in 0..<7 {
                let x = CGFloat(i) * 12 - 37, y = 7 - abs(CGFloat(i-3)) * 2
                p.line([.init(x:x,y:y),.init(x:x+1,y:y+7)],0x8C8B70,1)
            }
            p.oval(CGRect(x:-40,y:-23,width:80,height:27),[0xF7E4B7,0xC8B28C])
            p.oval(CGRect(x:-35,y:-21,width:70,height:21),[0xD4F1DF,0x74C3C5,0x5BA9B4])
            p.rounded(CGRect(x:-6,y:-58,width:12,height:49),5,[0xF4E0B4,0xC6B08A,0x9B9475])
            p.oval(CGRect(x:-23,y:-63,width:46,height:17),[0xFCE9BF,0xBAA785])
            p.oval(CGRect(x:-19,y:-63,width:38,height:10),[0xDBF5E5,0x7BC9CA])
            p.oval(CGRect(x:-7,y:-80,width:14,height:18),[0xFFF3C7,0xD8C295,0xAFA17D])
            for side:CGFloat in [-1,1] {
                var stream=Path();stream.move(to:.init(x:side*17,y:-58))
                stream.addQuadCurve(to:.init(x:side*31,y:-9),control:.init(x:side*30,y:-54))
                p.context.stroke(stream,with:.color(Color(dinoHex:0xD9F8EA)),style:StrokeStyle(lineWidth:2.3,lineCap:.round))
                p.oval(CGRect(x:side*31-6,y:-13,width:13,height:4),[0xDDF7E7,0xA8E1D8])
            }
            p.flowers(at:CGPoint(x:-43,y:11),size:0.62,pink:true)
            p.flowers(at:CGPoint(x:43,y:11),size:0.62,pink:false)
        }
    }
    private func waterway(at point: CGPoint, size: CGFloat, mirror: Bool) {
        at(point,size:size,mirror:mirror) { p in
            var stream=Path();stream.move(to:.init(x:-12,y:-30))
            for i in 0..<6 {
                let y=CGFloat(i)*260
                stream.addCurve(to:.init(x:CGFloat(i%2==0 ? 8 : -15),y:y+260), control1:.init(x:38,y:y+60),control2:.init(x:-28,y:y+175))
            }
            p.context.stroke(stream,with:.color(Color(dinoHex:0xA0AD8C).opacity(0.8)),style:StrokeStyle(lineWidth:46,lineCap:.round))
            p.context.stroke(stream,with:.color(Color(dinoHex:0xE1D9B6)),style:StrokeStyle(lineWidth:36,lineCap:.round))
            p.context.stroke(stream,with:.linearGradient(Gradient(colors:[Color(dinoHex:0x9BD7D3),Color(dinoHex:0x6CBCC2),Color(dinoHex:0xB0DED4)]),startPoint:.zero,endPoint:.init(x:0,y:1600)),style:StrokeStyle(lineWidth:27,lineCap:.round))
            p.context.stroke(stream,with:.color(Color(dinoHex:0xDDF5E4).opacity(0.7)),style:StrokeStyle(lineWidth:1.5,lineCap:.round,dash:[8,22,3,40]))
            for i in 0..<15 {
                let y=CGFloat(i)*109+28
                p.rock(at:CGPoint(x:i%2==0 ? 20 : -23,y:y),size:0.38+CGFloat(i%3)*0.1)
                if i%2==0 { p.plants(at:CGPoint(x:28,y:y+11),size:0.45) }
            }
        }
    }
    private func rock(at point:CGPoint,size:CGFloat) {
        at(point,size:size) { p in
            p.polygon([.init(x:-23,y:5),.init(x:-18,y:-17),.init(x:-3,y:-27),.init(x:17,y:-19),.init(x:26,y:2),.init(x:8,y:11)], [0xDDD4B6,0xACB3A3,0x7D958E])
            p.polygon([.init(x:-18,y:-17),.init(x:-3,y:-27),.init(x:17,y:-19),.init(x:1,y:-9)], [0xF5E4BD,0xC8CBB1])
            p.line([.init(x:1,y:-9),.init(x:8,y:7)],0x6F8983,0.8,opacity:0.6)
        }
    }
    private func cascade(at point:CGPoint,size:CGFloat,mirror:Bool=false) {
        at(point,size:size,mirror:mirror) { p in
            for i in 0..<4 {
                let x=CGFloat(i)*17-36,y=CGFloat(i%2)*8
                p.rock(at:CGPoint(x:x,y:y-9),size:1.3)
            }
            p.rounded(CGRect(x:-12,y:-27,width:29,height:71),4,[0xD2F1E2,0x8ACFD0,0x57B2BD,0xB0E4DA])
            for i in 0..<4 { p.line([.init(x:CGFloat(i)*7-9,y:-23),.init(x:CGFloat(i)*7-11,y:33+CGFloat(i%2)*8)],0xEEFFF0,i%2==0 ? 2 : 1,opacity:0.8) }
            p.oval(CGRect(x:-31,y:31,width:67,height:20),[0xECFFF0,0xA1DCD4,0x73BDC0])
            for i in 0..<6 { p.oval(CGRect(x:CGFloat(i)*9-25,y:33+CGFloat(i%2)*5,width:10,height:4),[0xF3FFF1,0xCDEFE2]) }
            p.plants(at:CGPoint(x:32,y:5),size:0.8)
            p.flowers(at:CGPoint(x:-35,y:17),size:0.65,pink:false)
        }
    }
    private func bridge(at point:CGPoint,size:CGFloat) {
        at(point,size:size) { p in
            p.polygon([.init(x:-44,y:-13),.init(x:32,y:-21),.init(x:45,y:5),.init(x:-33,y:16)],[0xE5C18B,0xB68D5D,0x987C55])
            for i in 0..<7 {
                let x=CGFloat(i)*11-36
                p.line([.init(x:x,y:-11),.init(x:x+10,y:10)],0x8E7854,1)
                p.line([.init(x:x+3,y:-11),.init(x:x+12,y:8)],0xF4D49B,1)
            }
            for x:CGFloat in [-39,34] {
                for y:CGFloat in [-15,8] {
                    p.rounded(CGRect(x:x,y:y-25,width:6,height:31),2,[0xE6BD81,0x92774F])
                    p.oval(CGRect(x:x-1,y:y-27,width:9,height:5),[0xFFE0A0,0xB5935D])
                }
            }
            p.line([.init(x:-37,y:-30),.init(x:37,y:-37)],0xC49B64,4)
            p.line([.init(x:-37,y:-8),.init(x:37,y:-15)],0xDBB37C,4)
        }
    }
    private func mill(at point:CGPoint,size:CGFloat) {
        at(point,size:size) { p in
            p.cottage(at:CGPoint(x:-13,y:-2),size:0.83,leafRoof:false)
            p.rounded(CGRect(x:12,y:-67,width:12,height:67),3,[0xBE9A67,0x7F704F])
            let center=CGPoint(x:30,y:-25)
            for i in 0..<10 {
                let a=Double(i) * .pi / 5
                let end=CGPoint(x:center.x+CGFloat(cos(a))*29,y:center.y+CGFloat(sin(a))*29)
                p.line([center,end],0xA58152,4)
                p.at(end) { paddle in
                    var c=paddle.context;c.rotate(by:.radians(a))
                    VillageWorldPainter(context:c).rounded(CGRect(x:-3,y:-7,width:9,height:15),1,[0xE1BA7A,0xAA8557,0x7C6B4D])
                }
            }
            p.context.stroke(Path(ellipseIn:CGRect(x:4,y:-51,width:52,height:52)),with:.color(Color(dinoHex:0xD6B078)),lineWidth:4)
            p.context.stroke(Path(ellipseIn:CGRect(x:10,y:-45,width:40,height:40)),with:.color(Color(dinoHex:0x8B754F)),lineWidth:2)
            p.oval(CGRect(x:23,y:-32,width:14,height:14),[0xE7C48B,0x977B51])
            p.oval(CGRect(x:27,y:-28,width:6,height:6),[0xB18E5D,0x756A4E])
            p.plants(at:CGPoint(x:-43,y:12),size:0.73)
        }
    }
    private func garden(at point:CGPoint,size:CGFloat,variation:Int) {
        at(point,size:size) { p in
            p.oval(CGRect(x:-52,y:-14,width:104,height:34),[0xD7DFAB,0xA6C28C])
            if variation%3==0 { p.tree(at:CGPoint(x:0,y:0),size:0.83) }
            else {
                p.plants(at:CGPoint(x:-16,y:0),size:1.1)
                p.rock(at:CGPoint(x:22,y:7),size:0.66)
                p.fence(at:CGPoint(x:0,y:13),size:0.7)
            }
            p.flowers(at:CGPoint(x:23,y:18),size:0.8,pink:variation%2==0)
            p.flowers(at:CGPoint(x:-25,y:11),size:0.6,pink:variation%2 != 0)
        }
    }
    func scene(at point:CGPoint,size:CGFloat,variation:Int) {
        at(point,size:size) { p in
            p.oval(CGRect(x:-77,y:-18,width:154,height:49),[0xE3DFB1,0xBEC993,0xA9BE88])
            for i in 0..<6 {
                p.rounded(CGRect(x:CGFloat(i)*22-61,y:15+CGFloat(i%2)*4,width:19,height:7),2,[0xEFE0B7,0xB7B495])
            }
            switch variation%5 {
            case 0:
                p.tree(at:CGPoint(x:38,y:-23),size:0.7)
                p.cottage(at:CGPoint(x:-19,y:-2),size:0.92,leafRoof:variation>0)
                p.market(at:CGPoint(x:29,y:23),size:0.68,blue:variation==0)
            case 1:
                p.tree(at:CGPoint(x:-32,y:-15),size:0.82)
                p.fountain(at:CGPoint(x:15,y:9),size:0.85)
                p.fence(at:CGPoint(x:-7,y:30),size:0.9)
            case 2:
                p.tower(at:CGPoint(x:-11,y:0),size:0.88)
                p.cottage(at:CGPoint(x:41,y:13),size:0.48,leafRoof:false)
            case 3:
                p.mill(at:CGPoint(x:-4,y:4),size:1.05)
                p.fence(at:CGPoint(x:3,y:30),size:0.88)
            default:
                p.cottage(at:CGPoint(x:-23,y:-8),size:0.86,leafRoof:true)
                p.market(at:CGPoint(x:29,y:21),size:0.78,blue:false)
            }
            p.flowers(at:CGPoint(x:-49,y:24),size:0.7,pink:true)
            p.plants(at:CGPoint(x:51,y:31),size:0.66)
            p.rock(at:CGPoint(x:-62,y:22),size:0.43)
        }
    }
}

/// The cave's illuminated facets and rocky enclosure are exclusive to world five.
private struct CrystalCavePainter {
    let context: GraphicsContext

    private func at(_ point: CGPoint, size: CGFloat = 1, mirror: Bool = false, draw: (CrystalCavePainter) -> Void) {
        var c = context
        c.translateBy(x: point.x, y: point.y)
        c.scaleBy(x: mirror ? -size : size, y: size)
        draw(.init(context: c))
    }
    private func material(_ path: Path, colors: [UInt32]) {
        let r = path.boundingRect
        context.fill(path, with: .linearGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
    }
    private func polygon(_ points: [CGPoint], colors: [UInt32]) {
        var p = Path(); p.addLines(points); p.closeSubpath(); material(p, colors: colors)
    }
    private func rounded(_ r: CGRect, radius: CGFloat, colors: [UInt32]) {
        material(Path(roundedRect: r, cornerRadius: radius), colors: colors)
    }
    private func oval(_ r: CGRect, colors: [UInt32]) {
        context.fill(Path(ellipseIn: r), with: .radialGradient(Gradient(colors: colors.map { Color(dinoHex: $0) }),
                                                            center: CGPoint(x: r.minX + r.width * 0.3, y: r.minY + r.height * 0.2),
                                                            startRadius: 0, endRadius: max(r.width, r.height) * 0.85))
    }
    private func line(_ points: [CGPoint], color: UInt32, width: CGFloat, opacity: Double = 1) {
        var p = Path(); p.addLines(points)
        context.stroke(p, with: .color(Color(dinoHex: color).opacity(opacity)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    private func glow(_ point: CGPoint, radius: CGFloat, color: UInt32, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [Color(dinoHex: color).opacity(opacity), Color(dinoHex: color).opacity(0)]),
                                           center: point, startRadius: 0, endRadius: radius))
    }
    private func sparkle(at point: CGPoint, radius: CGFloat) {
        glow(point, radius: radius * 4, color: 0xE2FFF8, opacity: 0.35)
        let shape = Path { p in
            p.addLines([.init(x: point.x, y: point.y - radius), .init(x: point.x + radius * 0.25, y: point.y - radius * 0.25),
                        .init(x: point.x + radius, y: point.y), .init(x: point.x + radius * 0.25, y: point.y + radius * 0.25),
                        .init(x: point.x, y: point.y + radius), .init(x: point.x - radius * 0.25, y: point.y + radius * 0.25),
                        .init(x: point.x - radius, y: point.y), .init(x: point.x - radius * 0.25, y: point.y - radius * 0.25)])
            p.closeSubpath()
        }
        context.fill(shape, with: .color(Color(dinoHex: 0xF2FFF7).opacity(0.92)))
    }

    func landscape(in size: CGSize, routeOffset: CGFloat) {
        let w = size.width, h = size.height
        let scale = min(1.30, max(0.82, w / 390))
        let horizon = (routeOffset + 130) / h
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(stops: [
            .init(color: Color(dinoHex: 0xD8EEF0), location: 0),
            .init(color: Color(dinoHex: 0x758AB7), location: 0.035),
            .init(color: Color(dinoHex: 0x9FC9D9), location: horizon * 0.5),
            .init(color: Color(dinoHex: 0xD1E6DF), location: horizon),
            .init(color: Color(dinoHex: 0xBED7D5), location: 0.40),
            .init(color: Color(dinoHex: 0xBFD2DC), location: 0.68),
            .init(color: Color(dinoHex: 0xC4DCE4), location: 0.88),
            .init(color: Color(dinoHex: 0xB8E4F5), location: 1)
        ]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
        entrance(width: w, height: routeOffset + 115, scale: scale)
        var c = context; c.translateBy(x: 0, y: routeOffset)
        let p = CrystalCavePainter(context: c)
        for i in 0..<5 {
            let y = 90 + CGFloat(i) * 350
            p.glow(CGPoint(x: w * (i % 2 == 0 ? 0.23 : 0.77), y: y), radius: w * 0.42, color: i % 2 == 0 ? 0xC9F9E4 : 0xDEE0FF, opacity: 0.19)
        }
        for side in 0..<2 {
            p.at(CGPoint(x: side == 0 ? 0 : w, y: 0), size: scale, mirror: side == 1) { bank in
                bank.wall(length: 1720 / scale)
                bank.stream(length: 1710 / scale)
                for i in 0..<12 {
                    let y = 45 + CGFloat(i) * 142 / scale
                    bank.rock(at: CGPoint(x: 42 + CGFloat(i % 3) * 4, y: y), size: 0.48 + CGFloat(i % 2) * 0.18)
                    bank.plants(at: CGPoint(x: 51, y: y + 20), size: 0.48)
                    if i % 3 == 0 { bank.crystal(at: CGPoint(x: 19, y: y - 7), height: 25, tint: side == 0 ? 1 : 0) }
                }
            }
        }
        // Pools, waterfalls and the small crossings stay behind the destinations.
        p.cascade(at: CGPoint(x: 3, y: 760), size: scale)
        p.cascade(at: CGPoint(x: w - 2, y: 1110), size: scale, mirror: true)
        p.bridge(at: CGPoint(x: 10 * scale, y: 885), size: scale * 0.85)
        p.bridge(at: CGPoint(x: w - 8 * scale, y: 1240), size: scale * 0.85)
        for index in 0..<9 {
            let onRight = index % 4 == 0 || index % 4 == 3
            let point = CGPoint(x: onRight ? w - 34 * scale : 34 * scale, y: 184 + CGFloat(index) * 175)
            p.scene(at: point, size: scale * 0.94, variation: index)
            p.garden(at: CGPoint(x: onRight ? 8 * scale : w - 8 * scale, y: point.y + 88), size: scale, variation: index)
        }
        // A rock arch frames the guardian without covering his face or clock.
        p.arch(at: CGPoint(x: w - 80 * scale, y: 1740), size: scale * 0.98)
        context.fill(Path(CGRect(x: 0, y: h - 180, width: w, height: 180)),
                     with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xB8E4F5).opacity(0), Color(dinoHex: 0xB8E4F5)]),
                                           startPoint: CGPoint(x: 0, y: h - 180), endPoint: CGPoint(x: 0, y: h)))
    }

    private func entrance(width: CGFloat, height: CGFloat, scale: CGFloat) {
        let center = CGPoint(x: width * 0.52, y: height * 0.39)
        glow(center, radius: width * 0.63, color: 0xDCF7EB, opacity: 0.64)
        context.drawLayer { c in
            c.addFilter(.blur(radius: 8))
            for i in 0..<3 {
                let x = width * (0.18 + CGFloat(i) * 0.26)
                var beam = Path()
                beam.addLines([.init(x: x - 24, y: 35), .init(x: x + 2, y: 35),
                               .init(x: x + width * 0.15, y: height * 0.86), .init(x: x - 9, y: height * 0.85)])
                beam.closeSubpath()
                c.fill(beam, with: .linearGradient(Gradient(colors: [Color(dinoHex: 0xF2FFF5).opacity(0.04),
                                                                    Color(dinoHex: 0xE8FFF0).opacity(0.23),
                                                                    Color(dinoHex: 0xE8FFF0).opacity(0)]),
                                                   startPoint: CGPoint(x: x, y: 35), endPoint: CGPoint(x: x, y: height * 0.86)))
            }
        }
        var distant = context; distant.opacity = 0.50
        distant.clipToLayer { mask in
            mask.fill(Path(CGRect(x: 0, y: 0, width: width, height: height + 80)),
                      with: .linearGradient(Gradient(stops: [.init(color: .white, location: 0), .init(color: .white, location: 0.55), .init(color: .white.opacity(0), location: 1)]),
                                            startPoint: CGPoint(x: 0, y: 100 * scale), endPoint: CGPoint(x: 0, y: 260 * scale)))
        }
        let far = CrystalCavePainter(context: distant)
        for i in 0..<5 {
            far.at(CGPoint(x: CGFloat(i) * width / 4, y: (178 + CGFloat(i % 2) * 25) * scale), size: scale * 1.0) { p in
                p.polygon([.init(x: -58, y: 35), .init(x: -42, y: -110), .init(x: -30, y: -127), .init(x: 9, y: -138), .init(x: 38, y: -94), .init(x: 59, y: 35)], colors: [0x899FC6, 0x637DA6, 0x557C94])
                p.polygon([.init(x: -30, y: -127), .init(x: 9, y: -138), .init(x: -3, y: -65), .init(x: -18, y: 27), .init(x: -49, y: 32)], colors: [0xBED1DA, 0x8BAEC5])
                p.crystal(at: CGPoint(x: -12, y: -111), height: 39, tint: i % 2)
                if i == 1 || i == 3 {
                    p.rounded(CGRect(x: 14, y: -107, width: 19, height: 122), radius: 4, colors: [0xDFF9ED, 0x8BDADE, 0xBCEDE1])
                    p.line([.init(x: 20, y: -104), .init(x: 19, y: 11)], color: 0xF0FFF5, width: 2, opacity: 0.8)
                    p.glow(CGPoint(x: 23, y: 13), radius: 34, color: 0xD5F9EA, opacity: 0.6)
                }
            }
        }
        // Irregular roof stones form a vault, with a bright opening in the middle.
        let roof = Path { p in
            p.addLines([.init(x: 0, y: 0), .init(x: width, y: 0), .init(x: width, y: 190 * scale),
                        .init(x: width - 37 * scale, y: 118 * scale), .init(x: width - 72 * scale, y: 103 * scale),
                        .init(x: width * 0.74, y: 63 * scale), .init(x: width * 0.60, y: 46 * scale),
                        .init(x: width * 0.44, y: 66 * scale), .init(x: width * 0.28, y: 53 * scale),
                        .init(x: 70 * scale, y: 110 * scale), .init(x: 29 * scale, y: 142 * scale), .init(x: 0, y: 230 * scale)])
            p.closeSubpath()
        }
        context.drawLayer { c in
            c.clipToLayer { mask in
                mask.fill(Path(CGRect(x: 0, y: 0, width: width, height: 250 * scale)),
                          with: .linearGradient(Gradient(colors: [.white.opacity(0), .white]),
                                                startPoint: .zero, endPoint: CGPoint(x: 0, y: 28 * scale)))
            }
            let p = CrystalCavePainter(context: c)
            p.material(roof, colors: [0x657796, 0x4B5E82, 0x364D70])
            for i in 0..<9 {
                let x = CGFloat(i) * width / 8
                let depth = (i < 2 || i > 6 ? 109 : 56) + CGFloat(i % 3) * 15
                p.polygon([.init(x: x - 27 * scale, y: 2), .init(x: x + 25 * scale, y: 3), .init(x: x + 17 * scale, y: depth * scale * 0.60),
                         .init(x: x + 5 * scale, y: depth * scale), .init(x: x - 10 * scale, y: depth * scale * 0.71)], colors: [0x8190A8, 0x526B8D, 0x405878])
                p.line([.init(x: x - 9 * scale, y: 5), .init(x: x + 2 * scale, y: depth * scale * 0.76)], color: 0xA8B4C3, width: 1, opacity: 0.5)
            }
        }
        for side in 0..<2 {
            at(CGPoint(x: side == 0 ? 0 : width, y: 185 * scale), size: scale, mirror: side == 1) { p in
                p.rock(at: CGPoint(x: -20, y: 8), size: 2.4)
                p.rock(at: CGPoint(x: -14, y: 110), size: 2.0)
                p.plants(at: CGPoint(x: 15, y: 134), size: 1.0)
                p.cluster(at: CGPoint(x: 13, y: 121), size: 0.67, variation: side)
            }
        }
        for (fraction, y, height, tint): (CGFloat, CGFloat, CGFloat, Int) in [(0.11, 37, 63, 1), (0.86, 27, 81, 0), (0.69, 40, 35, 2)] {
            var hanging = context
            hanging.translateBy(x: width * fraction, y: y * scale)
            hanging.scaleBy(x: scale, y: -scale)
            CrystalCavePainter(context: hanging).crystal(at: .zero, height: height, tint: tint)
        }
        for i in 0..<12 {
            let x = width * (0.17 + CGFloat((i * 17) % 69) / 100), y = 95 + CGFloat((i * 23) % 137)
            glow(CGPoint(x: x, y: y), radius: 3, color: 0xF5FFE5, opacity: 0.55)
            oval(CGRect(x: x, y: y, width: 1.3, height: 1.3), colors: [0xFFFFE4, 0xDAECE4])
        }
    }

    private func wall(length: CGFloat) {
        let outline = Path { p in
            p.move(to: CGPoint(x: -120, y: -20))
            p.addLine(to: CGPoint(x: 25, y: -20))
            for i in 0..<12 {
                let y = CGFloat(i) * length / 11
                p.addLine(to: CGPoint(x: 27 + CGFloat(i % 3) * 9, y: y))
                p.addLine(to: CGPoint(x: 20 + CGFloat(i % 2) * 11, y: y + 42))
            }
            p.addLine(to: CGPoint(x: -120, y: length + 90)); p.closeSubpath()
        }
        material(outline, colors: [0x8595AD, 0x647C98, 0x58788B])
        for i in 0..<11 {
            let y = CGFloat(i) * length / 10 + 23
            polygon([.init(x: -25, y: y - 55), .init(x: 20, y: y - 40), .init(x: 33, y: y + 32), .init(x: 9, y: y + 61), .init(x: -23, y: y + 42)], colors: [0xA5B3BF, 0x7B93A5, 0x637D95])
            line([.init(x: 25, y: y - 16), .init(x: 10, y: y - 5), .init(x: 17, y: y + 24)], color: 0x435D7F, width: 1.2, opacity: 0.65)
            line([.init(x: -15, y: y - 37), .init(x: 14, y: y - 26)], color: 0xD1D8D2, width: 1, opacity: 0.55)
        }
    }
    private func stream(length: CGFloat) {
        var water = Path(); water.move(to: CGPoint(x: 34, y: -20))
        for i in 0..<6 {
            let y = CGFloat(i) * length / 6
            water.addCurve(to: CGPoint(x: i % 2 == 0 ? 27 : 42, y: y + length / 6),
                           control1: CGPoint(x: 61, y: y + 70), control2: CGPoint(x: 5, y: y + 165))
        }
        context.stroke(water, with: .color(Color(dinoHex: 0x8FA7AF)), style: StrokeStyle(lineWidth: 35, lineCap: .round))
        context.stroke(water, with: .color(Color(dinoHex: 0xA9E4DD)), style: StrokeStyle(lineWidth: 26, lineCap: .round))
        context.stroke(water, with: .color(Color(dinoHex: 0x66BDC8)), style: StrokeStyle(lineWidth: 17, lineCap: .round))
        context.stroke(water, with: .color(Color(dinoHex: 0xE4FFF0).opacity(0.8)), style: StrokeStyle(lineWidth: 1.3, lineCap: .round, dash: [11, 26, 3, 22]))
    }
    private func rock(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -33, y: -6, width: 66, height: 19), colors: [0x8499A1, 0xB1C9C4])
            p.polygon([.init(x: -29, y: 4), .init(x: -23, y: -25), .init(x: -7, y: -42), .init(x: 15, y: -37), .init(x: 30, y: -16), .init(x: 34, y: 4), .init(x: 9, y: 13)], colors: [0xA8B1C1, 0x7C8CA9, 0x586E90])
            p.polygon([.init(x: -23, y: -25), .init(x: -7, y: -42), .init(x: 15, y: -37), .init(x: 2, y: -17), .init(x: -16, y: -8)], colors: [0xD3D2D0, 0xA2B2C1, 0x8C9FB4])
            p.polygon([.init(x: 15, y: -37), .init(x: 30, y: -16), .init(x: 34, y: 4), .init(x: 9, y: 13), .init(x: 2, y: -17)], colors: [0x899DB5, 0x536A8C])
            p.line([.init(x: -17, y: -4), .init(x: -6, y: -7), .init(x: 0, y: -1)], color: 0x536D8C, width: 0.8, opacity: 0.65)
        }
    }
    private func crystal(at point: CGPoint, height: CGFloat, tint: Int) {
        at(point) { p in
            let r = height * 0.19
            let colors: [UInt32] = tint % 3 == 0 ? [0xD4FFF0, 0x8EE5E0, 0x43ADCB, 0x4985B3] : tint % 3 == 1 ? [0xF0E3FF, 0xCDB0F4, 0x9788D4, 0x716FB0] : [0xFFDEF7, 0xE6B7E8, 0xBD8ACE, 0x8E7EAD]
            p.glow(CGPoint(x: 0, y: -height * 0.45), radius: height * 0.65, color: colors[1], opacity: 0.30)
            p.polygon([.init(x: -r, y: -height * 0.69), .init(x: 0, y: -height), .init(x: r, y: -height * 0.72), .init(x: r * 0.86, y: -5), .init(x: 0, y: 0), .init(x: -r * 0.82, y: -7)], colors: [colors[0], colors[1], colors[2]])
            p.polygon([.init(x: 0, y: -height), .init(x: r, y: -height * 0.72), .init(x: r * 0.86, y: -5), .init(x: 0, y: 0)], colors: [colors[1], colors[2], colors[3]])
            p.polygon([.init(x: -r, y: -height * 0.69), .init(x: 0, y: -height), .init(x: 0, y: -height * 0.68), .init(x: -r * 0.82, y: -7)], colors: [0xF1FFF9, colors[0], colors[2]])
            p.polygon([.init(x: -r, y: -height * 0.69), .init(x: 0, y: -height * 0.68), .init(x: r, y: -height * 0.72), .init(x: r * 0.4, y: -height * 0.58)], colors: [colors[0], colors[1]])
            p.line([.init(x: -r + 1, y: -height * 0.69), .init(x: 0, y: -height + 1), .init(x: r - 1, y: -height * 0.72)], color: 0xEEFFF7, width: 1.1, opacity: 0.85)
            p.line([.init(x: 0, y: -height * 0.68), .init(x: 0, y: -5)], color: colors[0], width: 1.3, opacity: 0.85)
            p.line([.init(x: -r * 0.58, y: -height * 0.62), .init(x: -r * 0.54, y: -height * 0.30)], color: 0xFFFFFF, width: max(1, height * 0.023), opacity: 0.78)
            p.sparkle(at: CGPoint(x: -r * 0.53, y: -height * 0.63), radius: max(1.8, height * 0.043))
        }
    }
    private func cluster(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -48, y: -12, width: 100, height: 29), colors: [0xABD4CE, 0x8EACA9])
            for i in 0..<5 {
                let x = CGFloat(i - 2) * 17, height = CGFloat(37 + (i * 23 + variation * 13) % 55)
                p.at(CGPoint(x: x, y: CGFloat(i % 2) * 3)) { shard in
                    var c = shard.context; c.rotate(by: .degrees(Double(i - 2) * 7))
                    CrystalCavePainter(context: c).crystal(at: .zero, height: height, tint: (i + variation) % 3)
                }
            }
            p.rock(at: CGPoint(x: -34, y: 7), size: 0.38)
            p.rock(at: CGPoint(x: 31, y: 13), size: 0.27)
            p.plants(at: CGPoint(x: 41, y: 8), size: 0.58)
        }
    }
    private func plants(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for i in 0..<5 {
                var c = p.context; c.rotate(by: .degrees(Double(i - 2) * 31))
                let leaf = Path { l in
                    l.move(to: .zero)
                    l.addCurve(to: .init(x: 0, y: -29 - CGFloat(i % 2) * 9), control1: .init(x: -12, y: -6), control2: .init(x: -8, y: -26))
                    l.addCurve(to: .zero, control1: .init(x: 9, y: -25), control2: .init(x: 12, y: -6))
                }
                let f = CrystalCavePainter(context: c); f.material(leaf, colors: [0xB4DCB4, 0x70B4A1, 0x4B8A92])
                f.line([.zero, .init(x: 0, y: -25)], color: 0xD6ECD1, width: 0.7, opacity: 0.6)
            }
        }
    }
    private func blossoms(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            for i in 0..<3 {
                let x = CGFloat(i - 1) * 9, y = -5 - CGFloat(i % 2) * 8
                p.line([.init(x: x, y: 3), .init(x: x, y: y)], color: 0x6FA898, width: 1.2)
                for j in 0..<5 {
                    let angle = Double(j) * .pi * 0.4
                    p.oval(CGRect(x: x + CGFloat(cos(angle)) * 3 - 2.5, y: y + CGFloat(sin(angle)) * 3 - 2.5, width: 5, height: 5), colors: [0xF6E6F8, 0xBEACDA])
                }
                p.oval(CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3), colors: [0xFFF4BE, 0xDECEA2])
            }
        }
    }
    private func lantern(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.glow(CGPoint(x: 0, y: -22), radius: 49, color: 0xFFE5A4, opacity: 0.32)
            p.rounded(CGRect(x: -9, y: -33, width: 18, height: 25), radius: 3, colors: [0xBBA26F, 0x8B815D])
            p.rounded(CGRect(x: -6, y: -30, width: 12, height: 18), radius: 2, colors: [0xFFF6CC, 0xF6D28B, 0xE9AE62])
            p.line([.init(x: 0, y: -29), .init(x: 0, y: -12)], color: 0xD4B57D, width: 1)
            p.polygon([.init(x: -12, y: -33), .init(x: 0, y: -40), .init(x: 12, y: -33)], colors: [0xD9C492, 0x8D8766])
            p.rounded(CGRect(x: -12, y: -9, width: 24, height: 4), radius: 1, colors: [0xD3BE8E, 0x96906F])
            p.line([.init(x: -3, y: -40), .init(x: -3, y: -44), .init(x: 3, y: -44), .init(x: 3, y: -40)], color: 0xA7A280, width: 1.3)
        }
    }
    private func cascade(at point: CGPoint, size: CGFloat, mirror: Bool = false) {
        at(point, size: size, mirror: mirror) { p in
            for i in 0..<4 { p.rock(at: CGPoint(x: CGFloat(i) * 19 - 38, y: CGFloat(i % 2) * 7), size: 1.20) }
            p.rounded(CGRect(x: -12, y: -31, width: 32, height: 86), radius: 5, colors: [0xD9FFF1, 0x96DDE0, 0x65B8CD, 0xB5ECE7])
            for i in 0..<4 { p.line([.init(x: CGFloat(i) * 7 - 9, y: -26), .init(x: CGFloat(i) * 7 - 12, y: 40 + CGFloat(i % 2) * 8)], color: 0xE9FFF7, width: i % 2 == 0 ? 2 : 1, opacity: 0.9) }
            p.oval(CGRect(x: -39, y: 39, width: 82, height: 25), colors: [0xE1FFF1, 0x9BDCDD, 0x67B6C2])
            for i in 0..<5 { p.oval(CGRect(x: CGFloat(i) * 12 - 30, y: 45 + CGFloat(i % 2) * 3, width: 14, height: 4), colors: [0xF5FFF8, 0xC3F0E6]) }
            p.crystal(at: CGPoint(x: 30, y: -7), height: 37, tint: 0)
            p.plants(at: CGPoint(x: -26, y: 20), size: 0.76)
        }
    }
    private func bridge(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.polygon([.init(x: -42, y: -13), .init(x: 34, y: -20), .init(x: 45, y: 7), .init(x: -34, y: 19)], colors: [0xBCC0C7, 0x8F9CB2, 0x70849E])
            for i in 0..<6 {
                let x = CGFloat(i) * 13 - 32
                p.line([.init(x: x, y: -11), .init(x: x + 9, y: 11)], color: 0x546C8B, width: 1.3)
                p.line([.init(x: x + 2, y: -11), .init(x: x + 11, y: 9)], color: 0xE0DECE, width: 0.8, opacity: 0.8)
            }
            for x: CGFloat in [-38, 35] {
                p.rounded(CGRect(x: x - 4, y: -37, width: 10, height: 41), radius: 2, colors: [0xBFC3C4, 0x7D90A8, 0x526C8B])
                p.rounded(CGRect(x: x - 6, y: -40, width: 15, height: 5), radius: 1, colors: [0xE0DAC8, 0x91A3B2])
                p.crystal(at: CGPoint(x: x + 1, y: -40), height: 17, tint: 1)
            }
            p.line([.init(x: -37, y: -25), .init(x: 38, y: -32)], color: 0x9DAEBB, width: 4)
        }
    }
    private func geode(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            p.rock(at: CGPoint(x: 0, y: 0), size: 1.85)
            p.oval(CGRect(x: -35, y: -69, width: 70, height: 64), colors: [0x747399, 0x455C83, 0x374C71])
            p.oval(CGRect(x: -28, y: -64, width: 56, height: 53), colors: [0x6E789D, 0x324D74])
            p.glow(CGPoint(x: 0, y: -39), radius: 32, color: 0xBFA5EB, opacity: 0.44)
            for i in 0..<5 { p.crystal(at: CGPoint(x: CGFloat(i - 2) * 11, y: -15 + CGFloat(i % 2) * 2), height: 22 + CGFloat(i % 3) * 8, tint: i % 3) }
            p.crystal(at: CGPoint(x: -36, y: 1), height: 23, tint: 0)
            p.plants(at: CGPoint(x: 39, y: 10), size: 0.64)
        }
    }
    private func clockStone(at point: CGPoint, size: CGFloat, late: Bool) {
        at(point, size: size) { p in
            p.rock(at: CGPoint(x: 0, y: 7), size: 1.36)
            p.rounded(CGRect(x: -39, y: -61, width: 78, height: 45), radius: 12, colors: [0xB6B7C3, 0x8395B0, 0x596F92])
            p.rounded(CGRect(x: -32, y: -55, width: 64, height: 29), radius: 6, colors: [0x384A69, 0x29445C])
            p.glow(CGPoint(x: 0, y: -40), radius: 36, color: 0xFFE3A4, opacity: 0.17)
            p.context.draw(Text(verbatim: late ? "08:43" : "02:17").font(.system(size: 17, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(dinoHex: 0xFFE4A7)), at: CGPoint(x: 0, y: -40))
            p.line([.init(x: -27, y: -57), .init(x: 26, y: -57)], color: 0xDCDAC4, width: 1, opacity: 0.65)
            for x: CGFloat in [-29, 29] { p.oval(CGRect(x: x - 1, y: -22, width: 2, height: 2), colors: [0xF0E4C8, 0xA2A1A1]) }
            p.crystal(at: CGPoint(x: -43, y: 8), height: 38, tint: 1)
            p.crystal(at: CGPoint(x: 44, y: 13), height: 28, tint: 0)
        }
    }
    private func arch(at point: CGPoint, size: CGFloat) {
        at(point, size: size) { p in
            let arch = Path { a in
                a.move(to: CGPoint(x: -69, y: 4)); a.addCurve(to: CGPoint(x: 68, y: 4), control1: CGPoint(x: -71, y: -204), control2: CGPoint(x: 77, y: -201))
                a.addLine(to: CGPoint(x: 44, y: 2)); a.addCurve(to: CGPoint(x: -44, y: 2), control1: CGPoint(x: 47, y: -146), control2: CGPoint(x: -47, y: -142))
                a.closeSubpath()
            }
            p.material(arch, colors: [0xA8ADC1, 0x778DA8, 0x536C91])
            p.context.stroke(arch, with: .color(Color(dinoHex: 0x536B8D).opacity(0.65)), lineWidth: 1.5)
            for i in 0..<7 {
                let angle = Double(i) * .pi / 6
                let x = CGFloat(cos(angle)), y = CGFloat(sin(angle))
                p.line([.init(x: x * 65, y: -y * 147), .init(x: x * 45, y: -y * 106)], color: 0x4F6485, width: 1.3)
            }
            p.cluster(at: CGPoint(x: -50, y: 8), size: 0.55, variation: 0)
            p.cluster(at: CGPoint(x: 54, y: 12), size: 0.48, variation: 1)
            p.crystal(at: CGPoint(x: 0, y: -138), height: 42, tint: 1)
            p.plants(at: CGPoint(x: -61, y: 14), size: 0.68)
        }
    }
    private func garden(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            p.rock(at: CGPoint(x: -8, y: 0), size: 1.05)
            p.cluster(at: CGPoint(x: 20, y: 15), size: 0.62, variation: variation + 1)
            p.plants(at: CGPoint(x: -25, y: 13), size: 0.75)
            p.blossoms(at: CGPoint(x: 41, y: 22), size: 0.65)
        }
    }
    func scene(at point: CGPoint, size: CGFloat, variation: Int) {
        at(point, size: size) { p in
            p.oval(CGRect(x: -71, y: -16, width: 145, height: 44), colors: [0xB2D5CF, 0x96B3B7, 0x8EA4B1])
            p.rock(at: CGPoint(x: -33, y: -3), size: 1.3)
            p.rock(at: CGPoint(x: 35, y: 12), size: 0.75)
            switch variation % 4 {
            case 0: p.cluster(at: CGPoint(x: -9, y: 4), size: 1.1, variation: variation)
            case 1: p.geode(at: CGPoint(x: -4, y: 3), size: 1.03)
            case 2:
                p.cluster(at: CGPoint(x: -31, y: 7), size: 0.67, variation: variation)
                // Draw the display last so crystal facets cannot cover its digits.
                p.clockStone(at: CGPoint(x: 10, y: 4), size: 0.92, late: variation > 3)
            default:
                p.cascade(at: CGPoint(x: 0, y: 4), size: 0.95)
                p.cluster(at: CGPoint(x: 35, y: 28), size: 0.53, variation: variation)
            }
            p.plants(at: CGPoint(x: -48, y: 19), size: 0.74)
            p.blossoms(at: CGPoint(x: 40, y: 24), size: 0.67)
            if variation % 3 == 0 { p.lantern(at: CGPoint(x: -39, y: 24), size: 0.71) }
        }
    }
}

/// All scenery is native Canvas geometry. Generated concepts are documentation only.
struct ThemedWorldLandscape: View {
    let world: DinoWorld
    var routeOffset: CGFloat = 180

    var body: some View {
        Canvas { context, size in
            if world.id == 2 {
                SleepValleyPainter(context: context).landscape(in: size, routeOffset: routeOffset)
                var routeContext = context
                routeContext.translateBy(x: 0, y: routeOffset)
                let boss = ThemePainter(context: routeContext, colors: WorldThemeColors(world))
                let scale = min(1.30, max(0.82, size.width / 390))
                let right = size.width
                let point = CGPoint(x: right - 79 * scale, y: 1728)
                boss.bossClearing(worldID: 2, at: point, size: scale)
                boss.boss(worldID: 2, at: point, size: scale * 0.88)
                return
            }
            if world.id == 3 {
                VolcanoWorldPainter(context: context).landscape(in: size, routeOffset: routeOffset)
                var routeContext = context
                routeContext.translateBy(x: 0, y: routeOffset)
                let boss = ThemePainter(context: routeContext, colors: WorldThemeColors(world))
                let scale = min(1.30, max(0.82, size.width / 390))
                let right = size.width
                let point = CGPoint(x: right - 79 * scale, y: 1728)
                boss.bossClearing(worldID: 3, at: point, size: scale)
                boss.boss(worldID: 3, at: point, size: scale * 0.88)
                return
            }
            if world.id == 4 {
                VillageWorldPainter(context: context).landscape(in: size, routeOffset: routeOffset)
                var routeContext = context
                routeContext.translateBy(x: 0, y: routeOffset)
                let boss = ThemePainter(context: routeContext, colors: WorldThemeColors(world))
                let scale = min(1.30, max(0.82, size.width / 390))
                let right = size.width
                let point = CGPoint(x: right - 79 * scale, y: 1728)
                boss.bossClearing(worldID: 4, at: point, size: scale)
                boss.boss(worldID: 4, at: point, size: scale * 0.88)
                return
            }
            if world.id == 5 {
                CrystalCavePainter(context: context).landscape(in: size, routeOffset: routeOffset)
                var routeContext = context
                routeContext.translateBy(x: 0, y: routeOffset)
                let boss = ThemePainter(context: routeContext, colors: WorldThemeColors(world))
                let scale = min(1.30, max(0.82, size.width / 390))
                let point = CGPoint(x: size.width - 79 * scale, y: 1728)
                boss.bossClearing(worldID: 5, at: point, size: scale)
                boss.boss(worldID: 5, at: point, size: scale * 0.88)
                return
            }
            let colors = WorldThemeColors(world)
            let w = size.width
            let left: CGFloat = 0
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
                SleepValleyPainter(context: p.context).garden(at: .zero, size: 0.8, variation: variation)
            case 3:
                VolcanoWorldPainter(context: p.context).scene(at: .zero, size: 0.9, variation: variation)
            case 4:
                VillageWorldPainter(context: p.context).scene(at: .zero, size: 0.9, variation: variation)
            case 5:
                CrystalCavePainter(context: p.context).scene(at: .zero, size: 0.9, variation: variation)
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
