import SwiftUI

/// The same small, playful player HUD on the map and during a level.
struct AdventureHeader: View {
    let name: String
    let level: Int
    let stars: Int
    var compact = false
    var pause: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(spacing: 2) {
                ZStack {
                    Circle().fill(Color(dinoHex: 0xD9EDAD))
                    Image("dino-idle").resizable().scaledToFit()
                        .frame(width: 91, height: 91).offset(x: -3, y: 22)
                }
                .frame(width: compact ? 40 : 48, height: compact ? 40 : 48)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.95), lineWidth: 2.5))
                Text(verbatim: name)
                    .font(.system(size: compact ? 11 : 13, weight: .heavy, design: .rounded))
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("header.playerName")

            VStack(spacing: 1) {
                Text("dino.levelLabel")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(DinoStyle.deepGreen)
                Text(verbatim: "\(level)")
                    .font(.system(size: compact ? 21 : 26, weight: .heavy, design: .rounded))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity).frame(height: compact ? 44 : 56)
            .background(Color(dinoHex: 0xE2F0C9), in: RoundedRectangle(cornerRadius: 21))
            .rotationEffect(.degrees(-3))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("dino.levelNumber \(level)"))
            .accessibilityIdentifier("header.level")

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: compact ? 17 : 21, weight: .bold))
                        .foregroundStyle(DinoStyle.green).rotationEffect(.degrees(-12))
                    Text(verbatim: "\(stars)")
                        .font(.system(size: compact ? 21 : 26, weight: .heavy, design: .rounded))
                        .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                }
                Text("dino.starsLabel")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(DinoStyle.deepGreen)
            }
            .frame(maxWidth: .infinity).frame(height: compact ? 44 : 56)
            .background(Color(dinoHex: 0xEFF5DD), in: RoundedRectangle(cornerRadius: 21))
            .rotationEffect(.degrees(3))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("dino.stars \(stars)"))
            .accessibilityIdentifier("header.stars")

            Button(action: pause) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 19, weight: .heavy))
                    .frame(width: 46, height: 46)
                    .background(Color(dinoHex: 0xD2E8A7), in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.9), lineWidth: 2))
                    .rotationEffect(.degrees(5))
                    .shadow(color: DinoStyle.deepGreen.opacity(0.12), radius: 0, y: 3)
            }.buttonStyle(.plain)
                .accessibilityLabel(Text("dino.pause"))
                .accessibilityIdentifier("header.pause")
        }
        .foregroundStyle(DinoStyle.ink)
        .padding(.horizontal, 18).padding(.top, compact ? 4 : 8).padding(.bottom, compact ? 12 : 19)
        .frame(maxWidth: 440).frame(maxWidth: .infinity)
        .background {
            PlayfulHeaderEdge().fill(Color(dinoHex: 0xF6FAE9))
                .shadow(color: DinoStyle.deepGreen.opacity(0.09), radius: 8, y: 5)
                .ignoresSafeArea(edges: .top)
        }
    }
}

/// Soft lobes connect the fixed header to the scenery without a straight divider.
private struct PlayfulHeaderEdge: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: .zero)
            p.addLine(to: CGPoint(x: r.width, y: 0))
            p.addLine(to: CGPoint(x: r.width, y: r.height - 9))
            p.addCurve(to: CGPoint(x: r.width * 0.71, y: r.height - 6),
                       control1: CGPoint(x: r.width * 0.91, y: r.height + 7),
                       control2: CGPoint(x: r.width * 0.81, y: r.height - 17))
            p.addCurve(to: CGPoint(x: r.width * 0.35, y: r.height - 5),
                       control1: CGPoint(x: r.width * 0.59, y: r.height + 9),
                       control2: CGPoint(x: r.width * 0.46, y: r.height - 14))
            p.addCurve(to: CGPoint(x: 0, y: r.height - 10),
                       control1: CGPoint(x: r.width * 0.18, y: r.height + 6),
                       control2: CGPoint(x: r.width * 0.08, y: r.height - 1))
            p.closeSubpath()
        }
    }
}

struct MapPauseCard: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var compact: Bool { verticalSizeClass == .compact }
    var resume: () -> Void
    var settings: () -> Void
    var body: some View {
        VStack(spacing: compact ? 12 : 18) {
            if !compact { DinoCharacter(size: 110) }
            Text("dino.paused").font(.system(size: compact ? 24 : 28, weight: .heavy, design: .rounded))
            Button(action: resume) { Label("dino.keepPlaying", systemImage: "play.fill") }
                .buttonStyle(DinoButtonStyle(compact: compact)).accessibilityIdentifier("map.pause.resume")
            Button(action: settings) { Label("dino.settings", systemImage: "gearshape.fill") }
                .buttonStyle(DinoSecondaryButtonStyle()).accessibilityIdentifier("map.pause.settings")
        }.dinoCard().foregroundStyle(DinoStyle.ink).accessibilityAddTraits(.isModal)
    }
}
