import SwiftUI
import UIKit

private struct DinoHighContrastKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var dinoHighContrast: Bool {
        get { self[DinoHighContrastKey.self] }
        set { self[DinoHighContrastKey.self] = newValue }
    }
}

struct DinoContrastEnvironment: ViewModifier {
    @Environment(\.colorSchemeContrast) private var systemContrast
    let enabled: Bool
    func body(content: Content) -> some View {
        content.environment(\.dinoHighContrast, enabled || systemContrast == .increased)
    }
}

extension Color {
    init(dinoHex: UInt32) {
        self.init(red: Double((dinoHex >> 16) & 255) / 255,
                  green: Double((dinoHex >> 8) & 255) / 255,
                  blue: Double(dinoHex & 255) / 255)
    }
}

enum DinoStyle {
    static let ink = Color(dinoHex: 0x193B53)
    static let green = Color(dinoHex: 0x81D349)
    static let deepGreen = Color(dinoHex: 0x365B20)
    static let paper = Color(dinoHex: 0xF6FAF1)
    static let muted = Color(dinoHex: 0x657E80)
    static let warning = Color(dinoHex: 0x8F2435)
    static let orange = Color(dinoHex: 0xF59A32)
    static let deepOrange = Color(dinoHex: 0xC45E00)

    static func wrong(_ highContrast: Bool) -> Color {
        highContrast ? deepOrange : orange
    }
}

private struct CustomizationTypeScaleKey: EnvironmentKey { static let defaultValue: CGFloat = 1 }
private struct CustomizationMetricsKey: EnvironmentKey { static let defaultValue = CustomizationMetrics() }

/// Use the available window, including iPad split view, rather than the device model.
struct CustomizationMetrics {
    var spacious = false
    var sideBySide = false
    var contentWidth: CGFloat { spacious ? 740 : 520 }
    var footerWidth: CGFloat { spacious ? 760 : 540 }
    var enlargement: CGFloat { spacious ? 1.3 : 1 }
    var previewSize: CGFloat { spacious ? 270 : 180 }
    var swatchSize: CGFloat { spacious ? 40 : 28 }
    var controlHeight: CGFloat { spacious ? 60 : 44 }

    init(size: CGSize = .zero) {
        spacious = size.width >= 650
        sideBySide = size.width >= 900 && size.height < 900
    }
}

/// Shared rhythm for the Dino, analog and digital customization menus.
enum CustomizationLayout {
    static let sectionSpacing: CGFloat = 12
    static let labelSpacing: CGFloat = 12
    static let restoreSpacing: CGFloat = 4
    // A 28-point swatch is centered in a 44-point tap area.
    static let swatchInset: CGFloat = 8
    static let choiceSpacing: CGFloat = 10
    static let previewPadding: CGFloat = 8
}

/// Every option heading shares its typography and distance to the controls below.
struct CustomizationSection<Content: View>: View {
    @Environment(\.customizationMetrics) private var metrics
    let title: String
    let identifier: String
    var controlSpacing: CGFloat = CustomizationLayout.labelSpacing
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: controlSpacing * metrics.enlargement) {
            Text(LocalizedStringKey(title)).modifier(CustomizationText())
                .frame(maxWidth: .infinity).accessibilityIdentifier(identifier)
            content
        }.frame(maxWidth: .infinity)
    }
}

struct CustomizationOptionsCard: ViewModifier {
    @Environment(\.customizationMetrics) private var metrics
    func body(content: Content) -> some View {
        content.dinoCard(padding: metrics.spacious ? 24 : 16)
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 16)
            .frame(maxWidth: metrics.contentWidth).frame(maxWidth: .infinity)
    }
}

struct CustomizationWidth: ViewModifier {
    @Environment(\.customizationMetrics) private var metrics
    var footer = false
    func body(content: Content) -> some View {
        content.frame(maxWidth: footer ? metrics.footerWidth : metrics.contentWidth).frame(maxWidth: .infinity)
    }
}

extension EnvironmentValues {
    var customizationMetrics: CustomizationMetrics {
        get { self[CustomizationMetricsKey.self] }
        set { self[CustomizationMetricsKey.self] = newValue }
    }
    var customizationTypeScale: CGFloat {
        get { self[CustomizationTypeScaleKey.self] }
        set { self[CustomizationTypeScaleKey.self] = newValue }
    }
}

/// Fit every editor's labels together, including labels on pages that are offscreen.
/// No individual choice may shrink independently when a translated label is longer.
struct CustomizationTypography: ViewModifier {
    @ObservedObject private var language = LanguageManager.shared
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    var optionsInset: CGFloat = 64

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            let metrics = CustomizationMetrics(size: geometry.size)
            content.environment(\.customizationMetrics, metrics)
                .environment(\.customizationTypeScale, scale(for: geometry.size.width, metrics: metrics))
        }
    }

    private func scale(for width: CGFloat, metrics: CustomizationMetrics) -> CGFloat {
        let card = max(1, min(metrics.contentWidth, width) - optionsInset - (metrics.spacious ? 16 : 0))
        var scale = metrics.enlargement
        func fit(_ keys: [String], in available: CGFloat, size: CGFloat = 17, weight: UIFont.Weight = .bold) {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            let font = UIFont(descriptor: base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor, size: size)
            let longest = keys.map { (L(key: $0) as NSString).size(withAttributes: [.font: font]).width }.max() ?? 1
            scale = min(scale, max(1, available) / max(1, longest))
        }
        fit(["dino.shape.circle", "dino.shape.square", "dino.shape.octagon"], in: (card - 16) / 3 - 12)
        fit(["dino.analogNumerals.normal", "dino.analogNumerals.roman"], in: (card - 8) / 2 - 16)
        fit(["dino.appearance.bandana", "dino.appearance.spikes", "dino.appearance.body", "dino.appearance.belly",
             "dino.hourHand", "dino.minuteHand", "dino.face", "dino.rim", "dino.digitColor", "dino.display", "dino.numerals"], in: card)
        fit(["dino.appearance.reset", "dino.clock.restoreStyle"], in: card - 28)
        fit(["dino.personalize.dino", "dino.personalize.analog", "dino.personalize.digital"],
            in: (min(metrics.contentWidth, width) - 48) / 3 - 16)
        fit(["dino.next", "dino.useMyClock", "dino.done"], in: min(metrics.footerWidth, width) - 100)
        fit(["dino.appearance.welcome", "dino.makeAnalogClock", "dino.makeDigitalClock"], in: width - 40,
            size: verticalSizeClass == .compact ? 24 : 29, weight: .heavy)
        return scale
    }
}

struct CustomizationText: ViewModifier {
    @Environment(\.customizationTypeScale) private var scale
    var multiline = false

    func body(content: Content) -> some View {
        content.font(.system(size: 17 * scale, weight: .bold, design: .rounded))
            .multilineTextAlignment(.center).lineLimit(multiline ? nil : 1)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct CustomizationTitle: ViewModifier {
    @Environment(\.customizationTypeScale) private var scale
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    func body(content: Content) -> some View {
        content.font(.system(size: (verticalSizeClass == .compact ? 24 : 29) * scale, weight: .heavy, design: .rounded))
            .multilineTextAlignment(.center).lineLimit(1)
    }
}

/// The welcome flow navigates by dragging its noninteractive Dino or clock preview.
struct PersonalizationPreviewNavigation: ViewModifier {
    var onNavigate: ((Int) -> Void)?

    @ViewBuilder func body(content: Content) -> some View {
        if let onNavigate {
            content.contentShape(Rectangle())
                .simultaneousGesture(DragGesture(minimumDistance: 24).onEnded { value in
                    let movement = value.translation
                    guard abs(movement.width) >= 50, abs(movement.width) > abs(movement.height) * 1.25 else { return }
                    onNavigate(movement.width < 0 ? 1 : -1)
                })
        } else {
            content
        }
    }
}

/// A joined badge and pointer, with black numbers independent of clock colors.
struct ClockHintBadgeArrow: View {
    let number: Int
    let badge: CGPoint
    let tip: CGPoint
    let wings: [CGPoint]
    let ink: UInt32
    let bounds: CGSize

    var body: some View {
        ZStack {
            Canvas { context, _ in
                var arrow = Path()
                // Starting inside the badge removes the gap and the seam at its edge.
                arrow.move(to: badge); arrow.addLine(to: tip)
                for wing in wings {
                    arrow.move(to: tip); arrow.addLine(to: wing)
                }
                func disk(_ radius: CGFloat) -> Path {
                    Path(ellipseIn: CGRect(x: badge.x - radius, y: badge.y - radius,
                                           width: radius * 2, height: radius * 2))
                }
                // Each layer covers both parts, giving one continuous outline.
                context.stroke(arrow, with: .color(.white), style: StrokeStyle(lineWidth: 7.5, lineCap: .round, lineJoin: .round))
                context.fill(disk(14.5), with: .color(.white))
                context.stroke(arrow, with: .color(.black), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                context.fill(disk(13.25), with: .color(.black))
                context.stroke(arrow, with: .color(Color(dinoHex: ink)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                context.fill(disk(12), with: .color(.white))
            }
            Text(verbatim: "\(number)")
                .font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(.black)
                .frame(width: 24, height: 24).position(badge)
        }.frame(width: bounds.width, height: bounds.height)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Clock controls keep the same colors regardless of the player's clock theme.
struct DinoClockControlButtonStyle: ButtonStyle {
    @Environment(\.dinoHighContrast) private var highContrast
    var selected = true
    var expands = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(selected ? Color.white : DinoStyle.ink)
            .padding(.horizontal, 18)
            .frame(minHeight: 48)
            .frame(maxWidth: expands ? .infinity : nil)
            .background(selected ? DinoStyle.ink : .white, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .strokeBorder(DinoStyle.ink.opacity(highContrast || selected ? 1 : 0.22),
                              lineWidth: highContrast ? 3 : 1.5))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct DinoButtonStyle: ButtonStyle {
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.customizationTypeScale) private var customizationScale
    var color = DinoStyle.green
    var compact = false
    var customization = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: customization ? 17 * customizationScale : compact ? 17 : 20, weight: .bold, design: .rounded))
            .foregroundStyle(color == DinoStyle.green ? DinoStyle.ink : .white)
            .padding(.horizontal, compact ? 16 : 24)
            .frame(minHeight: customization ? max(58, 58 * customizationScale) : compact ? 48 : 58)
            .frame(maxWidth: .infinity)
            .background(LinearGradient(colors: [color, color.opacity(highContrast ? 1 : 0.88)], startPoint: .top, endPoint: .bottom),
                        in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(highContrast ? DinoStyle.ink : .white.opacity(0.22), lineWidth: highContrast ? 3 : 2))
            .shadow(color: color.opacity(0.36), radius: 0, y: configuration.isPressed ? 1 : 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct DinoSecondaryButtonStyle: ButtonStyle {
    @Environment(\.dinoHighContrast) private var highContrast
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(DinoStyle.ink)
            .padding(.horizontal, 20)
            .frame(minHeight: 52)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(highContrast ? 1 : configuration.isPressed ? 0.6 : 0.95), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(DinoStyle.ink.opacity(highContrast ? 1 : 0.1), lineWidth: highContrast ? 3 : 1.5))
    }
}

/// Disabled choices retain their contrast so the child can inspect the answer.
struct DinoAnswerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct DinoIconButton: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let icon: String
    let labelKey: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(DinoStyle.ink)
                .frame(width: 48, height: 48)
                .background(.white.opacity(highContrast ? 1 : 0.9), in: RoundedRectangle(cornerRadius: 17))
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(highContrast ? DinoStyle.ink : .white, lineWidth: highContrast ? 3 : 1.5))
                .shadow(color: DinoStyle.ink.opacity(0.08), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}

struct DinoCard: ViewModifier {
    @Environment(\.dinoHighContrast) private var highContrast
    var padding: CGFloat = 20
    func body(content: Content) -> some View {
        content.padding(padding)
            .background(.white.opacity(highContrast ? 1 : 0.96), in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(highContrast ? DinoStyle.ink : .white, lineWidth: highContrast ? 3 : 2))
            .shadow(color: DinoStyle.deepGreen.opacity(0.08), radius: 18, y: 8)
    }
}

extension View { func dinoCard(padding: CGFloat = 20) -> some View { modifier(DinoCard(padding: padding)) } }

struct DinoStars: View {
    @Environment(\.dinoHighContrast) private var highContrast
    let count: Int
    var size: CGFloat = 25
    var showEmpty = true
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                if showEmpty || index < count {
                    Image(systemName: "star.fill")
                        .font(.system(size: size, weight: .bold))
                        .foregroundStyle(index < count ? (highContrast ? DinoStyle.deepGreen : DinoStyle.green) : DinoStyle.ink.opacity(highContrast ? 0.5 : 0.13))
                        .rotationEffect(.degrees(index == 1 ? 0 : index == 0 ? -12 : 12))
                        .offset(y: index == 1 ? -4 : 0)
                        .shadow(color: index < count ? DinoStyle.deepGreen.opacity(0.18) : .clear, radius: 0, y: 2)
                }
            }
        }
    }
}

struct JungleLeaf: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.minX - rect.width * 0.2, y: rect.minY - rect.height * 0.2))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY),
                       control: CGPoint(x: rect.maxX + rect.width * 0.2, y: rect.maxY + rect.height * 0.2))
        return p
    }
}

struct JungleBackground: View {
    @Environment(\.dinoHighContrast) private var highContrast
    var quiet = false
    var body: some View {
        GeometryReader { _ in
            ZStack {
                LinearGradient(colors: quiet
                               ? [Color(dinoHex: 0xF0F8E8), DinoStyle.paper]
                               : [Color(dinoHex: 0xDBF4BB), Color(dinoHex: 0xEFF8E2), Color(dinoHex: 0xD0EBAD)],
                               startPoint: .top, endPoint: .bottom)
                JungleVista(quiet: quiet).opacity(highContrast && quiet ? 0.25 : 1)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
