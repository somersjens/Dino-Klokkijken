import SwiftUI
import UIKit

/// One jungle HUD shared by the map and the running level.
struct AdventureHeader: View {
    @EnvironmentObject private var player: DinoPlayer
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsPersonalizer = false
    var personalizerChanged: (Bool) -> Void = { _ in }
    enum Control {
        case settings, pause
        var icon: String { self == .settings ? "gearshape.fill" : "pause.fill" }
        var labelKey: String { self == .settings ? "dino.settings" : "dino.pause" }
        var identifier: String { self == .settings ? "header.settings" : "header.pause" }
    }

    let level: Int
    let stars: Int
    var worldID = 1
    var compact = false
    var control: Control = .pause
    var questionCounter: String?
    var practiceStreak: Int?
    var practiceRecord = 0
    var practiceQuestionNumber: Int?
    var helpEnabled = true
    var help: () -> Void = {}
    var action: () -> Void

    private var palette: HUDPalette { HUDPalette(worldID: worldID) }
    private var titleKeys: [String] {
        [practiceStreak == nil ? "dino.levelLabel" : "dino.practice.streak", questionCounter == nil ? "dino.starsLabel" : "dino.questionsLabel",
         control == .settings ? "dino.practice.shortTitle" : "dino.example", control.labelKey]
    }
    private var localizedTitles: [String] {
        titleKeys.map { String(localized: String.LocalizationValue($0),
                               bundle: LanguageManager.shared.bundle, locale: locale) }
    }

    var body: some View {
        GeometryReader { geometry in
            let metrics = HUDMetrics(width: geometry.size.width, compact: compact,
                                     level: practiceStreak ?? level, stars: stars, questionCounter: questionCounter,
                                     titles: localizedTitles)
            HStack(spacing: metrics.gap) {
                portrait(metrics)
                HStack(spacing: 0) {
                    levelCell(metrics)
                    divider(metrics)
                    progressCell(metrics)
                    divider(metrics)
                    helpButton(metrics)
                    divider(metrics)
                    controlButton(metrics)
                }
                .padding(.trailing, metrics.spacious ? 18 : 8)
            }
            .foregroundStyle(highContrast ? HUDColors.contrastInk : HUDColors.ink)
            .padding(.leading, metrics.leadingMargin)
            .padding(.trailing, metrics.trailingMargin)
            .padding(.top, compact ? 6 : 12)
            .padding(.bottom, compact ? 8 : 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background {
                HStack(spacing: 0) {
                    Color.clear.frame(width: metrics.leadingMargin + metrics.portraitFootprint * 0.48)
                    HUDPlate(palette: palette, highContrast: highContrast)
                        .frame(height: metrics.plate)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("dino.worldNumber \(worldID)"))
                        .accessibilityIdentifier("header.world")
                        .background(alignment: .trailing) {
                            HUDTrailingLeaves(palette: palette).frame(width: metrics.plate * 0.48, height: metrics.plate * 0.96)
                                .offset(x: 7)
                        }
                        .padding(.trailing, metrics.trailingMargin)
                }.offset(y: compact ? -1 : -2)
            }
        }
        .frame(height: compact ? 82 : horizontalSizeClass == .regular ? 160 : 128)
        .frame(maxWidth: 780).frame(maxWidth: .infinity)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: worldID)
        .sheet(isPresented: $showsPersonalizer) {
            DinoPersonalizer().environmentObject(player).gameEnvironment()
                .presentationDetents([.large]).presentationDragIndicator(.visible)
        }
        .onChange(of: showsPersonalizer) { _, shown in personalizerChanged(shown) }
    }

    private func portrait(_ metrics: HUDMetrics) -> some View {
        let size = metrics.avatar
        return Button { showsPersonalizer = true } label: {
            ZStack {
                HUDPortraitLeaves(diameter: size, palette: palette)
                    .frame(width: metrics.portraitFootprint, height: metrics.portraitFootprint)
                    .mask(HUDLeafClearance(plateHeight: metrics.plate).fill(style: FillStyle(eoFill: true)))
                Circle().fill(LinearGradient(colors: [palette.portraitLight, palette.accent],
                                            startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(Circle().strokeBorder(palette.outline, lineWidth: 2))
                    .frame(width: size, height: size)
                HUDDinoBust(appearance: player.profile.dinoAppearance ?? .standard, diameter: size)
                    .clipShape(Circle())
                Circle().strokeBorder(palette.rim, lineWidth: 4)
                    .frame(width: size, height: size)
                HUDDinoBust(appearance: player.profile.dinoAppearance ?? .standard, diameter: size)
                    .frame(width: metrics.portraitFootprint, height: metrics.portraitFootprint)
                    .mask(HUDBandanaTailMask(diameter: size))
                    .shadow(color: DinoStyle.ink.opacity(0.14), radius: 0.7, y: 0.7)
            }
            .frame(width: metrics.portraitFootprint, height: metrics.portraitFootprint)
            .frame(width: metrics.portraitSlot, height: metrics.portraitFootprint, alignment: .leading)
            .shadow(color: palette.outline.opacity(0.18), radius: 3, y: 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(HUDPressStyle())
        .accessibilityLabel(Text("dino.appearance.title"))
        .accessibilityHint(Text("dino.appearance.open"))
        .accessibilityIdentifier("header.dino")
    }

    private func levelCell(_ metrics: HUDMetrics) -> some View {
        VStack(spacing: metrics.labelGap) {
            title(practiceStreak == nil ? "dino.levelLabel" : "dino.practice.streak", metrics: metrics)
            number("\(practiceStreak ?? level)", metrics: metrics)
                .offset(y: practiceStreak == nil ? 0 : -3)
                .accessibilityIdentifier(practiceStreak == nil ? "header.levelCount" : "practice.streak")
        }
        .frame(width: metrics.cellWidth, height: metrics.cell)
        .overlay(alignment: .bottom) {
            if practiceStreak != nil {
                Label { Text(verbatim: "\(practiceRecord)") } icon: { Image(systemName: "trophy.fill") }
                    .font(.system(size: compact ? 8 : metrics.spacious ? 12 : 9, weight: .bold, design: .rounded))
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                    .foregroundStyle(highContrast ? HUDColors.contrastInk : Color(dinoHex: 0x92702E))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("dino.practice.bestStreak"))
                    .accessibilityValue(String(practiceRecord))
                    .accessibilityIdentifier("practice.bestStreak")
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: practiceStreak == nil ? .ignore : .contain)
        .accessibilityLabel(practiceStreak == nil ? Text("dino.levelNumber \(level)") : Text("dino.practice.streak"))
        .accessibilityIdentifier(practiceStreak == nil ? "header.level" : "header.streak")
    }

    private func progressCell(_ metrics: HUDMetrics) -> some View {
        VStack(spacing: metrics.labelGap) {
            title(questionCounter == nil ? "dino.starsLabel" : "dino.questionsLabel", metrics: metrics)
            number(questionCounter ?? "\(stars)", metrics: metrics)
                .offset(y: practiceQuestionNumber == nil ? 0 : -3)
                .accessibilityIdentifier(practiceQuestionNumber != nil ? "practice.questionNumber" : questionCounter == nil ? "header.starCount" : "header.questionCounter")
        }
        .frame(width: metrics.cellWidth, height: metrics.cell)
        .overlay(alignment: .bottom) {
            if let practiceQuestionNumber, let thousands = DinoPracticeCounter(value: practiceQuestionNumber).thousands {
                Text(verbatim: thousands)
                    .font(.system(size: compact ? 8 : metrics.spacious ? 12 : 9, weight: .bold, design: .rounded))
                    .monospacedDigit().accessibilityIdentifier("practice.questionThousands")
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: questionCounter == nil ? .ignore : .contain)
        .accessibilityLabel(questionCounter == nil ? Text("dino.stars \(stars)") : Text("dino.questionsLabel"))
        .accessibilityIdentifier(questionCounter == nil ? "header.stars" : "header.questions")
    }

    private func helpButton(_ metrics: HUDMetrics) -> some View {
        Button(action: help) {
            VStack(spacing: metrics.labelGap) {
                title(control == .settings ? "dino.practice.shortTitle" : "dino.example", metrics: metrics)
                if control == .settings {
                    HUDLevelGrid().frame(width: metrics.icon, height: metrics.icon)
                } else {
                    HUDActionIcon(symbol: "questionmark", size: metrics.icon, highContrast: highContrast)
                }
            }
            .frame(width: metrics.cellWidth, height: metrics.cell)
            .contentShape(Rectangle())
        }
        .buttonStyle(HUDPressStyle()).disabled(!helpEnabled)
        .opacity(helpEnabled ? 1 : 0.45)
        .accessibilityLabel(Text(LocalizedStringKey(control == .settings ? "dino.practice.title" : "dino.example")))
        .accessibilityIdentifier(control == .settings ? "header.practice" : "question.example")
    }

    private func controlButton(_ metrics: HUDMetrics) -> some View {
        Button(action: action) {
            VStack(spacing: metrics.labelGap) {
                title(control.labelKey, metrics: metrics)
                if control == .settings {
                    Image(systemName: control.icon)
                        .resizable().scaledToFit()
                        .foregroundStyle(LinearGradient(colors: [Color(dinoHex: 0x2C6476), DinoStyle.ink],
                                                        startPoint: .top, endPoint: .bottom))
                        .shadow(color: .white.opacity(0.9), radius: 0, y: -1)
                        .shadow(color: DinoStyle.ink.opacity(0.2), radius: 1, y: 2)
                        // SF Symbols include padding around their painted shape.
                        .frame(width: metrics.icon * 1.1, height: metrics.icon * 1.1)
                        .frame(width: metrics.icon, height: metrics.icon)
                } else {
                    HUDActionIcon(symbol: control.icon, size: metrics.icon, highContrast: highContrast)
                }
            }
            .frame(width: metrics.cellWidth, height: metrics.cell)
            .contentShape(Rectangle())
        }
        .buttonStyle(HUDPressStyle())
        .accessibilityLabel(Text(LocalizedStringKey(control.labelKey)))
        .accessibilityIdentifier(control.identifier)
    }

    private func title(_ key: String, metrics: HUDMetrics) -> some View {
        Text(LocalizedStringKey(key))
            .font(.system(size: metrics.label, weight: .heavy, design: .rounded))
            .lineLimit(1).fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity).frame(height: metrics.label + 4)
            .padding(.horizontal, 3)
    }

    private func number(_ value: String, metrics: HUDMetrics) -> some View {
        Text(verbatim: value)
            .font(.system(size: metrics.number, weight: .heavy, design: .rounded))
            .monospacedDigit().lineLimit(1).fixedSize()
            .shadow(color: .white.opacity(0.9), radius: 0, y: 1)
            .frame(height: metrics.icon)
            .offset(y: metrics.numberOffset)
            .padding(.horizontal, 3)
    }

    private func divider(_ metrics: HUDMetrics) -> some View {
        Capsule().fill(highContrast ? palette.outline : palette.divider)
            .frame(width: highContrast ? 2 : 1, height: metrics.cell * 0.74)
            .padding(.horizontal, metrics.gap)
            .accessibilityHidden(true)
    }
}

/// Show the neck and upper body; the original recolored sprite remains intact.
private struct HUDDinoBust: View {
    let appearance: DinoAppearance
    let diameter: CGFloat
    var body: some View {
        DinoAvatar(appearance: appearance)
            .frame(width: diameter / 0.62, height: diameter / 0.62)
            .offset(x: -diameter * 0.065, y: diameter * 0.339)
            .frame(width: diameter, height: diameter)
            .accessibilityHidden(true)
    }
}

/// Only the cloth at the left of the head crosses the white portrait rim.
private struct HUDBandanaTailMask: Shape {
    let diameter: CGFloat
    func path(in rect: CGRect) -> Path {
        let origin = CGPoint(x: rect.midX - diameter / 2, y: rect.midY - diameter / 2)
        return Path(CGRect(x: origin.x - diameter * 0.23 / 0.62,
                           y: origin.y + diameter * 0.165 / 0.62,
                           width: diameter * 0.355 / 0.62, height: diameter * 0.192 / 0.62))
    }
}

/// The ornament sits behind the bar, so bringing the values closer cannot put
/// leaves over a three-digit level number.
private struct HUDLeafClearance: Shape {
    let plateHeight: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        path.addPath(Capsule().path(in: CGRect(x: rect.width * 0.48,
                                             y: (rect.height - plateHeight) / 2,
                                             width: rect.width * 4, height: plateHeight)))
        return path
    }
}

private struct HUDMetrics {
    let spacious: Bool
    let avatar: CGFloat
    let portraitFootprint: CGFloat
    let portraitSlot: CGFloat
    let plate: CGFloat
    let cell: CGFloat
    let cellWidth: CGFloat
    let label: CGFloat
    let number: CGFloat
    let numberOffset: CGFloat
    let icon: CGFloat
    let leadingMargin: CGFloat
    let trailingMargin: CGFloat
    let gap: CGFloat
    let labelGap: CGFloat

    init(width: CGFloat, compact: Bool, level: Int, stars: Int, questionCounter: String?, titles: [String]) {
        spacious = width >= 600 && !compact
        avatar = compact ? 52 : spacious ? 104 : 78
        portraitFootprint = compact ? 68 : spacious ? 132 : 100
        portraitSlot = portraitFootprint - (compact ? 8 : spacious ? 20 : 16)
        plate = compact ? 58 : spacious ? 96 : 78
        cell = compact ? 48 : spacious ? 82 : 66
        leadingMargin = spacious ? 18 : 4
        trailingMargin = spacious ? 18 : 10
        gap = spacious ? 8 : 3
        labelGap = compact ? 2 : 4

        cellWidth = (width - leadingMargin - trailingMargin - portraitSlot - gap * 7
                     - 6 - (spacious ? 18 : 8)) / 4
        let availableWidth = max(20, cellWidth - 6)
        let nominalLabel: CGFloat = spacious ? 16 : compact ? 10 : 11
        let labelBase = UIFont.systemFont(ofSize: nominalLabel, weight: .heavy).fontDescriptor
        let labelFont = UIFont(descriptor: labelBase.withDesign(.rounded) ?? labelBase, size: nominalLabel)
        let widestTitle = titles.map { ($0 as NSString).size(withAttributes: [.font: labelFont]).width }.max() ?? 1
        label = nominalLabel * min(1, availableWidth / max(1, widestTitle)) * 0.98

        // Text point sizes include space above/below the digits. Use cap height
        // to keep the visible digits slightly smaller than the action icons.
        let base = UIFont.monospacedDigitSystemFont(ofSize: 100, weight: .heavy).fontDescriptor
        let reference = UIFont(descriptor: base.withDesign(.rounded) ?? base, size: 100)
        icon = spacious ? 44 : compact ? 28 : 34
        let values = [String(level), questionCounter ?? String(stars)]
        let widestValue = values.map { ($0 as NSString).size(withAttributes: [.font: reference]).width }.max() ?? 1
        let nominalNumber = icon * 0.80 * reference.pointSize / reference.capHeight
        // One shared font handles both values; neither Text scales independently.
        number = min(nominalNumber, availableWidth * reference.pointSize / max(1, widestValue)) * 0.98
        numberOffset = number * (reference.lineHeight / 2 - reference.ascender + reference.capHeight / 2)
            / reference.pointSize
    }
}

private enum HUDColors {
    static let ink = Color(dinoHex: 0x2C6476)
    static let contrastInk = Color(dinoHex: 0x214D60)
}

/// Derives the HUD ornament from the same colors used to draw each world.
private struct HUDPalette {
    let accent: Color
    let outline: Color
    let strongOutline: Color
    let borderLight: Color
    let paperTop: Color
    let paperBottom: Color
    let portraitLight: Color
    let rim: Color
    let divider: Color
    let leafLight: Color
    let leafDarkLight: Color
    let leafDark: Color
    let veins: Color

    init(worldID: Int) {
        let world = DinoWorldCatalog.world(worldID) ?? DinoWorldCatalog.worlds[0]
        let colors = WorldThemeColors(world)
        let edge = Self.mix(colors.accent, colors.shade, amount: 0.6)
        accent = Color(dinoHex: colors.accent)
        outline = Color(dinoHex: edge)
        strongOutline = Color(dinoHex: Self.mix(edge, 0x102535, amount: 0.25))
        borderLight = Color(dinoHex: Self.mix(colors.accent, colors.ground, amount: 0.35))
        paperTop = Color(dinoHex: Self.mix(colors.ground, 0xFFFFFF, amount: 0.86))
        paperBottom = Color(dinoHex: Self.mix(colors.ground, 0xFFFFFF, amount: 0.70))
        portraitLight = Color(dinoHex: Self.mix(colors.ground, colors.accent, amount: 0.18))
        rim = Color(dinoHex: Self.mix(colors.ground, 0xFFFFFF, amount: 0.8))
        divider = Color(dinoHex: Self.mix(colors.accent, colors.ground, amount: 0.5))
        leafLight = Color(dinoHex: Self.mix(colors.accent, colors.ground, amount: 0.5))
        leafDarkLight = Color(dinoHex: Self.mix(colors.accent, colors.shade, amount: 0.25))
        leafDark = Color(dinoHex: colors.shade)
        veins = Color(dinoHex: Self.mix(colors.ground, 0xFFFFFF, amount: 0.35))
    }

    private static func mix(_ first: UInt32, _ second: UInt32, amount: Double) -> UInt32 {
        var result: UInt32 = 0
        for shift in [16, 8, 0] {
            let a = Double((first >> shift) & 255), b = Double((second >> shift) & 255)
            result |= UInt32((a + (b - a) * amount).rounded()) << shift
        }
        return result
    }
}

private struct HUDPlate: View {
    let palette: HUDPalette
    let highContrast: Bool
    var body: some View {
        Capsule()
            .fill(LinearGradient(colors: [palette.borderLight, palette.accent, palette.outline],
                                 startPoint: .top, endPoint: .bottom))
            .overlay {
                Capsule().fill(LinearGradient(colors: [palette.paperTop, palette.paperBottom],
                                               startPoint: .top, endPoint: .bottom))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.9), lineWidth: 2))
                    .padding(4)
            }
            .overlay(Capsule().strokeBorder(highContrast ? palette.strongOutline : palette.outline,
                                            lineWidth: highContrast ? 3 : 1))
            .shadow(color: palette.outline.opacity(0.22), radius: 0, y: 3)
            .shadow(color: palette.outline.opacity(0.13), radius: 5, y: 5)
    }
}

private struct HUDLevelGrid: View {
    var body: some View {
        GeometryReader { geometry in
            let gap: CGFloat = 1.4
            let side = (geometry.size.width - gap) / 2
            VStack(spacing: gap) {
                HStack(spacing: gap) { tile(bright: true, side: side); tile(bright: false, side: side) }
                HStack(spacing: gap) { tile(bright: false, side: side); tile(bright: true, side: side) }
            }
        }.shadow(color: HUDColors.ink.opacity(0.12), radius: 0.5, y: 1)
            .accessibilityHidden(true)
    }

    private func tile(bright: Bool, side: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: side * 0.23)
            .fill(LinearGradient(colors: bright ? [Color(dinoHex: 0x6DA7BA), Color(dinoHex: 0x39768B)]
                                               : [Color(dinoHex: 0x4D849B), Color(dinoHex: 0x28576F)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(RoundedRectangle(cornerRadius: side * 0.23).strokeBorder(.white.opacity(0.55), lineWidth: 0.7))
            .frame(width: side, height: side)
    }
}

private struct HUDActionIcon: View {
    let symbol: String
    let size: CGFloat
    let highContrast: Bool
    private var isHelp: Bool { symbol == "questionmark" }

    var body: some View {
        RoundedRectangle(cornerRadius: isHelp ? size / 2 : size * 0.29)
            .strokeBorder(highContrast ? HUDColors.contrastInk : HUDColors.ink, lineWidth: highContrast ? 2.5 : 1.8)
            .overlay {
                Image(systemName: symbol).font(.system(size: size * 0.58, weight: .heavy, design: .rounded))
                    .foregroundStyle(highContrast ? HUDColors.contrastInk : HUDColors.ink)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Each leaf has its own size and tilt, rather than repeating a radial starburst.
private struct HUDPortraitLeaves: View {
    let diameter: CGFloat
    let palette: HUDPalette
    private static let leaves: [(angle: Double, reach: CGFloat, length: CGFloat, width: CGFloat, tilt: Double, dark: Bool)] = [
        (-158, 0.46, 0.38, 0.27, -18, false),
        (-128, 0.42, 0.40, 0.27, 19, true),
        (-96, 0.465, 0.39, 0.28, -16, false),
        (-62, 0.45, 0.41, 0.29, 22, false),
        (-27, 0.43, 0.39, 0.26, -23, true),
        (12, 0.465, 0.39, 0.28, 18, false),
        (52, 0.42, 0.38, 0.25, -20, true),
        (97, 0.465, 0.37, 0.27, 16, false),
        (134, 0.44, 0.41, 0.29, -14, false),
        (173, 0.44, 0.39, 0.26, 22, true)
    ]

    var body: some View {
        ZStack {
            ForEach(Self.leaves.indices, id: \.self) { index in
                let leaf = Self.leaves[index]
                HUDLeafArt(palette: palette, dark: leaf.dark)
                    .frame(width: diameter * leaf.width, height: diameter * leaf.length)
                    .rotationEffect(.degrees(leaf.tilt))
                    .offset(y: -diameter * leaf.reach)
                    .rotationEffect(.degrees(leaf.angle))
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct HUDTrailingLeaves: View {
    let palette: HUDPalette
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width, height = geometry.size.height
            ZStack {
                HUDLeafArt(palette: palette, dark: true).frame(width: width * 0.60, height: height * 0.46)
                    .rotationEffect(.degrees(27)).position(x: width * 0.53, y: height * 0.25)
                HUDLeafArt(palette: palette, dark: false).frame(width: width * 0.59, height: height * 0.44)
                    .rotationEffect(.degrees(67)).position(x: width * 0.62, y: height * 0.48)
                HUDLeafArt(palette: palette, dark: false).frame(width: width * 0.62, height: height * 0.45)
                    .rotationEffect(.degrees(116)).position(x: width * 0.52, y: height * 0.73)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct HUDLeafArt: View {
    let palette: HUDPalette
    var dark = false
    var body: some View {
        HUDLeaf()
            .fill(LinearGradient(colors: dark
                                 ? [palette.leafDarkLight, palette.outline, palette.leafDark]
                                 : [palette.leafLight, palette.accent, palette.outline],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(HUDLeafFold().fill(LinearGradient(colors: [.white.opacity(dark ? 0.05 : 0.2), .clear],
                                                       startPoint: .topTrailing, endPoint: .bottomLeading)))
            .overlay(HUDLeaf().stroke(palette.veins.opacity(dark ? 0.45 : 0.8), lineWidth: 0.8))
            .overlay(HUDLeafVeins().stroke(palette.veins.opacity(dark ? 0.45 : 0.7),
                                           style: StrokeStyle(lineWidth: 0.6, lineCap: .round)))
            .shadow(color: palette.outline.opacity(0.12), radius: 0.6, y: 0.5)
    }
}

private struct HUDLeafFold: Shape {
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

private struct HUDLeafVeins: Shape {
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

private struct HUDLeaf: Shape {
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

private struct HUDPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
