import SwiftUI

struct DinoStarsOverview: View {
    @EnvironmentObject private var player: DinoPlayer
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dinoHighContrast) private var highContrast

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("dino.starsLabel")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                VStack(spacing: 10) {
                    ForEach(DinoWorldCatalog.worlds) { world in
                        worldRow(world)
                    }
                }
                .padding(16)
                .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 28))
            }
            .padding(16).padding(.top, 12)
            .frame(maxWidth: 560).frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("stars.overview")
        .background(JungleBackground(quiet: true))
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Text("dino.stars.total")
                    Spacer(minLength: 0)
                    starCount(player.profile.totalStars)
                }
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .padding(.leading, 16).padding(.trailing, 24).padding(.vertical, 14)
                .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 18))
                .accessibilityIdentifier("stars.total")

                Button { dismiss() } label: {
                    Label("dino.practice.backToLevels", systemImage: "map.fill")
                }
                    .buttonStyle(DinoSecondaryButtonStyle())
                    .accessibilityIdentifier("stars.close")
            }
            .padding(16).frame(maxWidth: 520).frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
        }
        .foregroundStyle(DinoStyle.ink)
    }

    private func worldRow(_ world: DinoWorld) -> some View {
        let stars = world.levels.reduce(0) { $0 + player.profile.record($1).stars }
        let unlocked = player.profile.isWorldUnlocked(world.id)
        let tint = Color(dinoHex: world.ground)
        return HStack(spacing: 10) {
            Text(verbatim: "\(world.id)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .frame(width: 32, height: 32)
                .background(tint, in: Circle())
            Text(LocalizedStringKey(world.titleKey))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Group {
                if unlocked {
                    starCount(stars)
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                }
            }
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .frame(minWidth: 40, alignment: .trailing)
        }
        .frame(minHeight: 44).padding(.leading, 12).padding(.trailing, 24).padding(.vertical, 8)
        .background(tint.opacity(0.5), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18)
            .stroke(highContrast ? DinoStyle.ink.opacity(0.6) : .clear, lineWidth: highContrast ? 1.5 : 0))
        .accessibilityIdentifier("stars.world.\(world.id)")
    }

    private func starCount(_ count: Int) -> some View {
        HStack(spacing: 6) {
            DinoRewardStar(size: 22)
            Text(verbatim: "\(count)").monospacedDigit()
        }.fixedSize()
    }
}
