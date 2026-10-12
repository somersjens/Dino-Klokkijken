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
    var questionCounter: String?
    var helpEnabled = true
    var help: () -> Void = {}
    var action: () -> Void

    private var tileHeight: CGFloat { compact ? 52 : 64 }
    private var avatarSize: CGFloat { compact ? 64 : 84 }
    private var numberSize: CGFloat { compact ? 20 : 22 }
    private var labelSize: CGFloat { compact ? 11 : 12 }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Button { showsPersonalizer = true } label: {
                DinoPortrait(appearance: player.profile.dinoAppearance ?? .standard, size: avatarSize, circular: false)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("dino.appearance.title"))
            .accessibilityHint(Text("dino.appearance.open"))
            .accessibilityIdentifier("header.dino")

            VStack(spacing: 3) {
                Text("dino.levelLabel")
                    .font(.system(size: labelSize, weight: .heavy, design: .rounded))
                    .tracking(0.3).foregroundStyle(DinoStyle.deepGreen)
                    .lineLimit(1).minimumScaleFactor(0.85)
                    .frame(height: 18)
                Text(verbatim: "\(level)")
                    .font(.system(size: numberSize, weight: .heavy, design: .rounded))
                    .monospacedDigit().frame(height: 28)
            }
            .frame(maxWidth: .infinity).frame(height: tileHeight)
            .background { tileBackground }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("dino.levelNumber \(level)"))
            .accessibilityIdentifier("header.level")

            VStack(spacing: 3) {
                Text(LocalizedStringKey(questionCounter == nil ? "dino.starsLabel" : "dino.questionsLabel"))
                    .font(.system(size: labelSize, weight: .heavy, design: .rounded))
                    .tracking(0.3).foregroundStyle(DinoStyle.deepGreen)
                    .lineLimit(1).minimumScaleFactor(0.85)
                    .frame(height: 18)
                Text(verbatim: questionCounter ?? "\(stars)")
                    .font(.system(size: numberSize, weight: .heavy, design: .rounded))
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.7).frame(height: 28)
                    .accessibilityIdentifier(questionCounter == nil ? "header.starCount" : "header.questionCounter")
            }
            .frame(maxWidth: .infinity).frame(height: tileHeight)
            .background { tileBackground }
            .accessibilityElement(children: questionCounter == nil ? .ignore : .contain)
            .accessibilityLabel(questionCounter == nil ? Text("dino.stars \(stars)") : Text("dino.questionsLabel"))
            .accessibilityIdentifier(questionCounter == nil ? "header.stars" : "header.questions")

            Button(action: help) {
                VStack(spacing: 3) {
                    Image(systemName: control == .settings ? "book.fill" : "questionmark")
                        .font(.system(size: compact ? 22 : 25, weight: .bold))
                    if control == .settings {
                        Text("dino.practice.shortTitle")
                            .font(.system(size: compact ? 10 : 11, weight: .bold, design: .rounded))
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                }.frame(maxWidth: .infinity).frame(height: tileHeight)
                    .background { tileBackground }
            }.buttonStyle(.plain).disabled(!helpEnabled)
                .opacity(helpEnabled ? 1 : 0.5)
                .accessibilityLabel(Text(LocalizedStringKey(control == .settings ? "dino.practice.title" : "dino.example")))
                .accessibilityIdentifier(control == .settings ? "header.practice" : "question.example")

            Button(action: action) {
                Image(systemName: control.icon)
                    .font(.system(size: compact ? 24 : 27, weight: .bold))
                    .frame(maxWidth: .infinity).frame(height: tileHeight)
                    .background { tileBackground }
            }.buttonStyle(.plain)
                .accessibilityLabel(Text(LocalizedStringKey(control.labelKey)))
                .accessibilityIdentifier(control.identifier)
        }
        .foregroundStyle(DinoStyle.ink)
        .padding(.horizontal, 14).padding(.top, compact ? 4 : 7).padding(.bottom, compact ? 10 : 14)
        .frame(maxWidth: 480).frame(maxWidth: .infinity)
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

    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: 16).fill(Color(dinoHex: 0xE7F0D7))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(highContrast ? DinoStyle.ink : Color(dinoHex: 0xD8E6C5), lineWidth: highContrast ? 3 : 1))
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
