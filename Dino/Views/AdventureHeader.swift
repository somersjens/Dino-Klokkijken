import SwiftUI
import UIKit
import CoreText

/// One world-themed HUD shared by the map and the running level.
struct AdventureHeader: View {
    @EnvironmentObject private var player: DinoPlayer
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsPersonalizer = false
    @State private var availableWidth: CGFloat = 390
    var personalizerChanged: (Bool) -> Void = { _ in }
    var sharedCompanion = false
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
    var viewportHeight: CGFloat = 900
    var viewportWidth: CGFloat? = nil
    var maximumScale: CGFloat = 1.9
    var control: Control = .pause
    var questionCounter: String?
    var practiceStreak: Int?
    var practiceRecord = 0
    var practiceQuestionNumber: Int?
    var practiceConfiguration: DinoPracticeConfiguration?
    var help: () -> Void = {}
    var focusLevel: (() -> Void)?
    var openStars: (() -> Void)?
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
            let scale = headerScale(width: geometry.size.width)
            let designWidth = min(390, geometry.size.width)
            let metrics = HUDMetrics(width: designWidth, compact: compact,
                                     level: practiceStreak ?? level, stars: stars, questionCounter: questionCounter,
                                     titles: localizedTitles)
            HStack(spacing: metrics.gap) {
                portrait(metrics)
                HStack(spacing: 0) {
                    if let focusLevel {
                        Button(action: focusLevel) { levelCell(metrics) }
                            .buttonStyle(HUDPressStyle())
                            .accessibilityIdentifier("header.level")
                    } else {
                        levelCell(metrics)
                    }
                    divider(metrics)
                    if let openStars, questionCounter == nil {
                        Button(action: openStars) { progressCell(metrics) }
                            .buttonStyle(HUDPressStyle())
                            .accessibilityIdentifier("header.stars")
                    } else {
                        progressCell(metrics)
                    }
                    divider(metrics)
                    helpButton(metrics)
                    divider(metrics)
                    controlButton(metrics)
                }
                .padding(.trailing, metrics.spacious ? 18 : 8)
            }
            .foregroundStyle(highContrast ? palette.contrastInk : palette.ink)
            .padding(.leading, metrics.leadingMargin)
            .padding(.trailing, metrics.trailingMargin)
            .padding(.top, compact ? 6 : 12)
            .padding(.bottom, compact ? 8 : 16)
            .frame(width: designWidth, height: compact ? 82 : 128, alignment: .leading)
            .background {
                HStack(spacing: 0) {
                    Color.clear.frame(width: metrics.leadingMargin + metrics.portraitFootprint * 0.48)
                    HUDPlate(palette: palette, highContrast: highContrast)
                        .frame(height: metrics.plate)
                        .accessibilityIdentifier("header.world.\(worldID)")
                        .background(alignment: .trailing) {
                            HUDTrailingLeaves(palette: palette).frame(width: metrics.plate * 0.48, height: metrics.plate * 0.96)
                                .offset(x: 7)
                        }
                        .padding(.trailing, metrics.trailingMargin)
                }.offset(y: compact ? -1 : -2)
            }
            .overlay(alignment: .bottom) {
                if let practiceConfiguration {
                    HUDPracticeSubtitle(configuration: practiceConfiguration, palette: palette,
                                        compact: compact, spacious: metrics.spacious, highContrast: highContrast)
                        .padding(.leading, metrics.leadingMargin + metrics.portraitFootprint * 0.48)
                        .padding(.trailing, metrics.trailingMargin)
                        .offset(y: (compact ? 9 : -6) + HUDPracticeSubtitle.addedHeight(compact: compact, spacious: metrics.spacious))
                }
            }
            .padding(.top, compact && practiceConfiguration != nil ? 4 : 0)
            .padding(.bottom, practiceConfiguration == nil ? 0 : compact ? 26 : 11)
            // Scale the complete composition, including its rim, leaves and badges.
            // Extra tablet width surrounds the HUD instead of stretching its cells.
            .scaleEffect(scale, anchor: .top)
            .frame(width: geometry.size.width, height: headerHeight * scale, alignment: .top)
        }
        .frame(height: headerHeight * headerScale(width: viewportWidth ?? availableWidth))
        .readGeometry(for: CGFloat.self) { $0.size.width } action: { availableWidth = $0 }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: worldID)
        .sheet(isPresented: $showsPersonalizer) {
            DinoPersonalizer().environmentObject(player).gameEnvironment()
                .presentationDetents([.large]).presentationDragIndicator(.visible)
        }
        .onValueChange(of: showsPersonalizer) { shown in personalizerChanged(shown) }
    }

    private var headerHeight: CGFloat {
        (compact ? 82 : 128) + (practiceConfiguration == nil ? 0 : compact ? 30 : 11)
    }

    private func headerScale(width: CGFloat) -> CGFloat {
        guard !compact else { return 1 }
        // Preserve phone tap targets; shorter tablet windows reserve room for play.
        return min(maximumScale, max(1, width / 390), max(1, viewportHeight / 480))
    }

    private func portrait(_ metrics: HUDMetrics) -> some View {
        let size = metrics.avatar
        return Button { showsPersonalizer = true } label: {
            ZStack {
                HUDPortraitLeaves(diameter: size, palette: palette)
                    .frame(width: metrics.portraitFootprint, height: metrics.portraitFootprint)
                    .mask(HUDLeafClearance(plateHeight: metrics.plate).fill(style: FillStyle(eoFill: true)))
                if sharedCompanion {
                    DinoCompanionAnchor(placement: .game, size: size)
                } else {
                    Circle().fill(LinearGradient(colors: [palette.portraitLight, palette.accent],
                                                startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(Circle().strokeBorder(palette.outline, lineWidth: 2))
                        .frame(width: size, height: size)
                    DinoBustImage(appearance: player.profile.dinoAppearance ?? .standard, diameter: size)
                        .clipShape(Circle())
                    Circle().strokeBorder(palette.rim, lineWidth: 4)
                        .frame(width: size, height: size)
                    DinoBustImage(appearance: player.profile.dinoAppearance ?? .standard, diameter: size)
                        .frame(width: metrics.portraitFootprint, height: metrics.portraitFootprint)
                        .mask(DinoBustOverflowMask(diameter: size))
                        .shadow(color: DinoStyle.ink.opacity(0.14), radius: 0.7, y: 0.7)
                }
            }
            .frame(width: metrics.portraitFootprint, height: metrics.portraitFootprint)
            .frame(width: metrics.portraitSlot, height: metrics.portraitFootprint, alignment: .leading)
            .shadow(color: palette.outline.opacity(0.18), radius: 3, y: 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(HUDPressStyle())
        .accessibilityIdentifier("header.dino")
    }

    private func levelCell(_ metrics: HUDMetrics) -> some View {
        VStack(spacing: metrics.labelGap) {
            title(practiceStreak == nil ? "dino.levelLabel" : "dino.practice.streak", metrics: metrics)
            number("\(practiceStreak ?? level)", metrics: metrics)
                .accessibilityIdentifier(practiceStreak == nil ? "header.levelCount" : "practice.streak")
        }
        .frame(width: metrics.cellWidth, height: metrics.cell)
        .overlay(alignment: .top) {
            if practiceStreak != nil {
                HUDRecordBadge(value: String(practiceRecord), trophy: true, palette: palette,
                               compact: compact, spacious: metrics.spacious, highContrast: highContrast)
                    .frame(maxWidth: metrics.cellWidth + 8)
                    .offset(y: compact ? -15 : metrics.spacious ? -23 : -21)
                    .accessibilityIdentifier("practice.bestStreak")
            }
        }
        .contentShape(Rectangle())
        .accessibilityIdentifier(practiceStreak == nil ? "header.level" : "header.streak")
    }

    private func progressCell(_ metrics: HUDMetrics) -> some View {
        VStack(spacing: metrics.labelGap) {
            title(questionCounter == nil ? "dino.starsLabel" : "dino.questionsLabel", metrics: metrics)
            number(questionCounter ?? "\(stars)", metrics: metrics)
                .accessibilityIdentifier(practiceQuestionNumber != nil ? "practice.questionNumber" : questionCounter == nil ? "header.starCount" : "header.questionCounter")
        }
        .frame(width: metrics.cellWidth, height: metrics.cell)
        .overlay(alignment: .top) {
            if let practiceQuestionNumber, let thousands = DinoPracticeCounter(value: practiceQuestionNumber).thousands {
                HUDRecordBadge(value: thousands, trophy: false, palette: palette,
                               compact: compact, spacious: metrics.spacious, highContrast: highContrast)
                    .offset(y: compact ? -16 : metrics.spacious ? -23 : -19)
                    .accessibilityIdentifier("practice.questionThousands")
            }
        }
        .contentShape(Rectangle())
        .accessibilityIdentifier(questionCounter == nil ? "header.stars" : "header.questions")
    }

    private func helpButton(_ metrics: HUDMetrics) -> some View {
        Button(action: help) {
            VStack(spacing: metrics.labelGap) {
                title(control == .settings ? "dino.practice.shortTitle" : "dino.example", metrics: metrics)
                if control == .settings {
                    HUDLevelGrid(palette: palette, highContrast: highContrast)
                        .frame(width: metrics.mapIcon, height: metrics.mapIcon)
                        .frame(width: metrics.icon, height: metrics.icon)
                } else {
                    HUDActionIcon(symbol: "questionmark", size: metrics.icon, palette: palette, highContrast: highContrast)
                }
            }
            .frame(width: metrics.cellWidth, height: metrics.cell)
            .contentShape(Rectangle())
        }
        .buttonStyle(HUDPressStyle())
        .accessibilityIdentifier(control == .settings ? "header.practice" : "question.example")
    }

    private func controlButton(_ metrics: HUDMetrics) -> some View {
        Button(action: action) {
            VStack(spacing: metrics.labelGap) {
                title(control.labelKey, metrics: metrics)
                if control == .settings {
                    Image(systemName: control.icon)
                        .resizable().scaledToFit()
                        .foregroundStyle(LinearGradient(colors: [highContrast ? palette.contrastInk : palette.iconLight,
                                                               highContrast ? palette.contrastInk : palette.ink],
                                                        startPoint: .top, endPoint: .bottom))
                        .shadow(color: .white.opacity(0.9), radius: 0, y: -1)
                        .shadow(color: palette.ink.opacity(0.2), radius: 1, y: 2)
                        // SF Symbols include padding around their painted shape.
                        .frame(width: metrics.mapIcon * 1.1, height: metrics.mapIcon * 1.1)
                        .frame(width: metrics.icon, height: metrics.icon)
                } else {
                    HUDActionIcon(symbol: control.icon, size: metrics.icon, palette: palette, highContrast: highContrast)
                }
            }
            .frame(width: metrics.cellWidth, height: metrics.cell)
            .contentShape(Rectangle())
        }
        .buttonStyle(HUDPressStyle())
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
            .offset(x: HUDNumberAlignment.offset(for: value, fontSize: metrics.number), y: metrics.numberOffset)
            .padding(.horizontal, 3)
    }

    private func divider(_ metrics: HUDMetrics) -> some View {
        Capsule().fill(highContrast ? palette.outline : palette.divider)
            .frame(width: highContrast ? 2 : 1, height: metrics.cell * 0.74)
            .padding(.horizontal, metrics.gap)
            .accessibilityHidden(true)
    }
}

/// A medal attached to the HUD rim, using the chapter plaque's paper and outline.
private struct HUDRecordBadge: View {
    let value: String
    let trophy: Bool
    let palette: HUDPalette
    let compact: Bool
    let spacious: Bool
    let highContrast: Bool
    private var fontSize: CGFloat {
        trophy ? (compact ? 11 : spacious ? 18 : 14) : (compact ? 8 : spacious ? 12 : 9)
    }

    var body: some View {
        HStack(spacing: trophy ? 4 : 3) {
            if trophy {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(LinearGradient(colors: [Color(dinoHex: 0xD4AF5D), Color(dinoHex: 0x876128)],
                                                    startPoint: .top, endPoint: .bottom))
                    .accessibilityHidden(true)
            }
            Text(verbatim: value).foregroundStyle(highContrast ? palette.contrastInk : palette.ink)
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                .offset(x: HUDNumberAlignment.offset(for: value, fontSize: fontSize))
        }
        .font(.system(size: fontSize, weight: .heavy, design: .rounded))
        .padding(.horizontal, trophy ? (compact ? 6 : 8) : (compact ? 4 : 6))
        .padding(.vertical, trophy ? (compact ? 2 : 3) : 2)
        .background {
            Capsule().fill(palette.outline.opacity(0.18)).offset(y: 1.5)
            Capsule().fill(LinearGradient(colors: [.white, palette.paperBottom], startPoint: .top, endPoint: .bottom))
                .overlay(Capsule().strokeBorder(highContrast ? palette.outline : palette.borderLight, lineWidth: trophy ? 1.5 : 1))
        }
    }
}

/// A chapter-style plaque attached to the lower edge of the practice HUD.
private struct HUDPracticeSubtitle: View {
    let configuration: DinoPracticeConfiguration
    let palette: HUDPalette
    let compact: Bool
    let spacious: Bool
    let highContrast: Bool
    private static let enlargement: CGFloat = 1.2

    static func addedHeight(compact: Bool, spacious: Bool) -> CGFloat {
        let marker: CGFloat = compact ? 18 : spacious ? 24 : 21
        return (marker + 10) * enlargement - (marker + 6)
    }

    private var markerTitle: String {
        switch configuration.order {
        case .specific(let type): return String(type.number)
        case .ascending: return L("dino.practice.ascending")
        case .mix: return L("dino.practice.mix")
        }
    }

    var body: some View {
        HStack(spacing: (compact ? 5 : 8) * Self.enlargement) {
            Group {
                switch configuration.order {
                case .specific(let type):
                    Text(verbatim: String(type.number)).monospacedDigit()
                        .offset(x: HUDNumberAlignment.offset(for: String(type.number), fontSize: (compact ? 10 : spacious ? 14 : 12) * Self.enlargement))
                case .ascending: Image(systemName: "arrow.up.right")
                case .mix: Image(systemName: "shuffle")
                }
            }
            .font(.system(size: (compact ? 10 : spacious ? 14 : 12) * Self.enlargement, weight: .heavy, design: .rounded))
            .frame(width: (compact ? 18 : spacious ? 24 : 21) * Self.enlargement,
                   height: (compact ? 18 : spacious ? 24 : 21) * Self.enlargement)
            .background(palette.accent.opacity(0.22), in: Circle())
            .overlay(Circle().strokeBorder(palette.borderLight, lineWidth: 0.8 * Self.enlargement))
            Text(LocalizedStringKey(configuration.time.titleKey))
                .font(.system(size: (compact ? 10 : spacious ? 15 : 12) * Self.enlargement, weight: .heavy, design: .rounded))
                .lineLimit(1).fixedSize()
        }
        .foregroundStyle(highContrast ? palette.contrastInk : palette.ink)
        .padding(.leading, 8 * Self.enlargement)
        .padding(.trailing, (compact ? 10 : 14) * Self.enlargement)
        .padding(.vertical, 5 * Self.enlargement)
        .background {
            Capsule().fill(palette.outline.opacity(0.35)).offset(y: 2 * Self.enlargement)
            Capsule().fill(LinearGradient(colors: [palette.paperTop, palette.paperBottom], startPoint: .top, endPoint: .bottom))
                .overlay(Capsule().strokeBorder(palette.outline, lineWidth: (highContrast ? 2 : 1.5) * Self.enlargement))
                .overlay(Capsule().strokeBorder(.white.opacity(0.7), lineWidth: 0.7 * Self.enlargement).padding(2 * Self.enlargement))
        }
        .accessibilityIdentifier("practice.hudSubtitle")
    }
}

/// Center the visible weight of narrow 1s while retaining fixed digit widths.
@MainActor
private enum HUDNumberAlignment {
    private static let referenceSize: CGFloat = 100
    private static let referenceFont: UIFont = {
        let descriptor = UIFont.monospacedDigitSystemFont(ofSize: referenceSize, weight: .heavy).fontDescriptor
        return UIFont(descriptor: descriptor.withDesign(.rounded) ?? descriptor, size: referenceSize)
    }()
    private static var corrections: [String: CGFloat] = [:]

    static func offset(for value: String, fontSize: CGFloat) -> CGFloat {
        guard value.contains("1") else { return 0 }
        if let correction = corrections[value] { return correction * fontSize }

        let line = CTLineCreateWithAttributedString(NSAttributedString(string: value,
            attributes: [.font: referenceFont, .foregroundColor: UIColor.white]))
        let advance = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        let padding: CGFloat = 2
        let width = Int(ceil(advance + padding * 2))
        let height = Int(ceil(bounds.height + padding * 2))
        guard width > 0, height > 0,
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue),
              let data = context.data else { return 0 }

        context.setFillColor(gray: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        context.textPosition = CGPoint(x: padding, y: padding - bounds.minY)
        CTLineDraw(line, context)
        let pixels = data.assumingMemoryBound(to: UInt8.self)
        var ink: Double = 0
        var weightedX: Double = 0
        for y in 0..<height {
            for x in 0..<width {
                let alpha = Double(pixels[y * context.bytesPerRow + x])
                ink += alpha
                weightedX += alpha * (Double(x) + 0.5)
            }
        }
        guard ink > 0 else { return 0 }
        let center = CGFloat(weightedX / ink) - padding
        // Keep the adjustment subtle for mixed counters such as 1/10.
        let correction = min(0.06, max(-0.06, (advance / 2 - center) / referenceSize))
        corrections[value] = correction
        return correction * fontSize
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

    // Shrink the map artwork without moving labels or reducing tap targets.
    var mapIcon: CGFloat { icon * 0.9 }

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
        label = nominalLabel * min(1, availableWidth / max(1, widestTitle)) * 0.86

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

/// Derives the HUD ornament, text and icons from the same world colors.
struct HUDPalette {
    let ink: Color
    let contrastInk: Color
    let iconLight: Color
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
        // Darken each world's hue to keep small labels readable on the paper.
        let textInk = Self.mix(edge, 0x102535, amount: 0.32)
        ink = Color(dinoHex: textInk)
        contrastInk = Color(dinoHex: Self.mix(textInk, 0x102535, amount: 0.40))
        iconLight = Color(dinoHex: Self.mix(textInk, colors.accent, amount: 0.25))
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
    @Environment(\.displayScale) private var displayScale
    let palette: HUDPalette
    let highContrast: Bool

    var body: some View {
        GeometryReader { geometry in
            // Align straight edges and spacing to physical pixels at every size.
            let gap = (1.4 * displayScale).rounded() / displayScale
            let side = ((geometry.size.width - gap) * displayScale / 2).rounded(.down) / displayScale
            VStack(spacing: gap) {
                HStack(spacing: gap) { tile(bright: true, side: side); tile(bright: false, side: side) }
                HStack(spacing: gap) { tile(bright: false, side: side); tile(bright: true, side: side) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }.accessibilityHidden(true)
    }

    private func tile(bright: Bool, side: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: side * 0.23)
            .fill(LinearGradient(colors: highContrast ? [palette.contrastInk, palette.contrastInk]
                                    : bright ? [palette.iconLight, palette.ink] : [palette.ink, palette.contrastInk],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(RoundedRectangle(cornerRadius: side * 0.23)
                .strokeBorder(highContrast ? palette.contrastInk : palette.ink, lineWidth: 1 / displayScale))
            .frame(width: side, height: side)
    }
}

private struct HUDActionIcon: View {
    let symbol: String
    let size: CGFloat
    let palette: HUDPalette
    let highContrast: Bool
    private var isHelp: Bool { symbol == "questionmark" }

    var body: some View {
        RoundedRectangle(cornerRadius: isHelp ? size / 2 : size * 0.29)
            .strokeBorder(highContrast ? palette.contrastInk : palette.ink, lineWidth: highContrast ? 2.5 : 1.8)
            .overlay {
                Image(systemName: symbol).font(.system(size: size * 0.58, weight: .heavy, design: .rounded))
                    .foregroundStyle(highContrast ? palette.contrastInk : palette.ink)
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
        DinoFoliageLeaf()
            .fill(LinearGradient(colors: dark
                                 ? [palette.leafDarkLight, palette.outline, palette.leafDark]
                                 : [palette.leafLight, palette.accent, palette.outline],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(DinoFoliageFold().fill(LinearGradient(colors: [.white.opacity(dark ? 0.05 : 0.2), .clear],
                                                       startPoint: .topTrailing, endPoint: .bottomLeading)))
            .overlay(DinoFoliageLeaf().stroke(palette.veins.opacity(dark ? 0.45 : 0.8), lineWidth: 0.8))
            .overlay(DinoFoliageVeins().stroke(palette.veins.opacity(dark ? 0.45 : 0.7),
                                           style: StrokeStyle(lineWidth: 0.6, lineCap: .round)))
            .shadow(color: palette.outline.opacity(0.12), radius: 0.6, y: 0.5)
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
