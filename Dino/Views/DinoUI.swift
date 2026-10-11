import SwiftUI

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
}

struct DinoButtonStyle: ButtonStyle {
    var color = DinoStyle.green
    var compact = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 17 : 20, weight: .bold, design: .rounded))
            .foregroundStyle(color == DinoStyle.green ? DinoStyle.ink : .white)
            .padding(.horizontal, compact ? 16 : 24)
            .frame(minHeight: compact ? 48 : 58)
            .frame(maxWidth: .infinity)
            .background(LinearGradient(colors: [color, color.opacity(0.88)], startPoint: .top, endPoint: .bottom),
                        in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.22), lineWidth: 2))
            .shadow(color: color.opacity(0.36), radius: 0, y: configuration.isPressed ? 1 : 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct DinoSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(DinoStyle.ink)
            .padding(.horizontal, 20)
            .frame(minHeight: 52)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(configuration.isPressed ? 0.6 : 0.95), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(DinoStyle.ink.opacity(0.1), lineWidth: 1.5))
    }
}

/// Disabled choices retain their contrast so the child can inspect the answer.
struct DinoAnswerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct DinoIconButton: View {
    let icon: String
    let labelKey: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(DinoStyle.ink)
                .frame(width: 48, height: 48)
                .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 17))
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white, lineWidth: 1.5))
                .shadow(color: DinoStyle.ink.opacity(0.08), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(LocalizedStringKey(labelKey)))
    }
}

struct DinoCard: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(20)
            .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white, lineWidth: 2))
            .shadow(color: DinoStyle.deepGreen.opacity(0.08), radius: 18, y: 8)
    }
}

extension View { func dinoCard() -> some View { modifier(DinoCard()) } }

struct DinoStars: View {
    let count: Int
    var size: CGFloat = 25
    var showEmpty = true
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                if showEmpty || index < count {
                    Image(systemName: "star.fill")
                        .font(.system(size: size, weight: .bold))
                        .foregroundStyle(index < count ? DinoStyle.green : DinoStyle.ink.opacity(0.13))
                        .rotationEffect(.degrees(index == 1 ? 0 : index == 0 ? -12 : 12))
                        .offset(y: index == 1 ? -4 : 0)
                        .shadow(color: index < count ? DinoStyle.deepGreen.opacity(0.18) : .clear, radius: 0, y: 2)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("dino.stars \(count)"))
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
    var quiet = false
    var body: some View {
        GeometryReader { _ in
            ZStack {
                LinearGradient(colors: quiet
                               ? [Color(dinoHex: 0xF0F8E8), DinoStyle.paper]
                               : [Color(dinoHex: 0xDBF4BB), Color(dinoHex: 0xEFF8E2), Color(dinoHex: 0xD0EBAD)],
                               startPoint: .top, endPoint: .bottom)
                JungleVista(quiet: quiet)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
