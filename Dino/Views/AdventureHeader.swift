import SwiftUI

/// A calm, aligned HUD. The map opens settings directly; a running level can pause.
struct AdventureHeader: View {
    @EnvironmentObject private var player: DinoPlayer
    @Environment(\.dinoHighContrast) private var highContrast
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
    var compact = false
    var control: Control = .pause
    var action: () -> Void

    private var tileHeight: CGFloat { compact ? 64 : 86 }
    private var avatarSize: CGFloat { compact ? 60 : 82 }
    private var numberSize: CGFloat { compact ? 22 : 25 }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button { showsPersonalizer = true } label: {
                ZStack {
                    Circle().fill(Color(dinoHex: 0xD9EDAD))
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                    DinoAvatar(appearance: player.profile.dinoAppearance ?? .standard, portrait: true)
                        .frame(width: avatarSize + 12, height: avatarSize)
                }.frame(width: avatarSize, height: avatarSize)
                .frame(maxWidth: .infinity).frame(height: tileHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("dino.appearance.title"))
            .accessibilityHint(Text("dino.appearance.open"))
            .accessibilityIdentifier("header.dino")

            VStack(spacing: 3) {
                Text("dino.levelLabel")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1).foregroundStyle(DinoStyle.deepGreen)
                    .frame(height: 18)
                Text(verbatim: "\(level)")
                    .font(.system(size: numberSize, weight: .heavy, design: .rounded))
                    .monospacedDigit().frame(height: 28)
            }
            .frame(maxWidth: .infinity).frame(height: tileHeight)
            .background(Color(dinoHex: 0xE7F0D7), in: RoundedRectangle(cornerRadius: 17))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("dino.levelNumber \(level)"))
            .accessibilityIdentifier("header.level")

            VStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(highContrast ? DinoStyle.deepGreen : DinoStyle.green).frame(height: 18)
                Text(verbatim: "\(stars)")
                    .font(.system(size: numberSize, weight: .heavy, design: .rounded))
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.7).frame(height: 28)
            }
            .frame(maxWidth: .infinity).frame(height: tileHeight)
            .background(Color(dinoHex: 0xE7F0D7), in: RoundedRectangle(cornerRadius: 17))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("dino.stars \(stars)"))
            .accessibilityIdentifier("header.stars")

            Button(action: action) {
                Image(systemName: control.icon)
                    .font(.system(size: 21, weight: .bold))
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(highContrast ? DinoStyle.ink : Color(dinoHex: 0xD8E6C5), lineWidth: highContrast ? 3 : 1.5))
            }.buttonStyle(.plain)
                .accessibilityLabel(Text(LocalizedStringKey(control.labelKey)))
                .accessibilityIdentifier(control.identifier)
        }
        .foregroundStyle(DinoStyle.ink)
        .padding(.horizontal, 18).padding(.top, compact ? 4 : 7).padding(.bottom, compact ? 10 : 14)
        .frame(maxWidth: 440).frame(maxWidth: .infinity)
        .background {
            HeaderEdge().fill(Color(dinoHex: 0xF6FAE9))
                .shadow(color: DinoStyle.deepGreen.opacity(0.06), radius: 6, y: 3)
                .ignoresSafeArea(edges: .top)
        }
        .sheet(isPresented: $showsPersonalizer) {
            DinoPersonalizer().environmentObject(player).gameEnvironment()
                .presentationDetents([.large]).presentationDragIndicator(.visible)
        }
        .onChange(of: showsPersonalizer) { _, shown in personalizerChanged(shown) }
    }
}

/// A shallow organic edge keeps the aligned HUD connected to the landscape.
private struct HeaderEdge: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: .zero)
            p.addLine(to: CGPoint(x: r.width, y: 0))
            p.addLine(to: CGPoint(x: r.width, y: r.height - 4))
            p.addCurve(to: CGPoint(x: r.width * 0.52, y: r.height - 3),
                       control1: CGPoint(x: r.width * 0.85, y: r.height + 2),
                       control2: CGPoint(x: r.width * 0.69, y: r.height - 9))
            p.addCurve(to: CGPoint(x: 0, y: r.height - 5),
                       control1: CGPoint(x: r.width * 0.31, y: r.height + 3),
                       control2: CGPoint(x: r.width * 0.15, y: r.height - 1))
            p.closeSubpath()
        }
    }
}
