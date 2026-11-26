import SwiftUI

struct DinoStarsOverview: View {
    var landscape = false
    @EnvironmentObject private var player: DinoPlayer
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dinoHighContrast) private var highContrast
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var textScale = 1.0

    var body: some View {
        GeometryReader { geometry in
            let layout = StarsLayout(size: geometry.size, landscape: landscape, accessibilityText: dynamicTypeSize.isAccessibilitySize)
            ScrollView {
                VStack(spacing: 16 * layout.scale) {
                    Text("dino.starsLabel")
                        .font(.system(size: 26 * layout.scale * textScale, weight: .heavy, design: .rounded))
                    VStack(spacing: 16 * layout.scale) {
                        // Keep offscreen worlds available to accessibility as well.
                        Grid(horizontalSpacing: 12 * layout.scale, verticalSpacing: 10 * layout.scale) {
                            ForEach(0..<layout.rowCount, id: \.self) { row in
                                GridRow {
                                    ForEach(0..<layout.columns, id: \.self) { column in
                                        let index = row * layout.columns + column
                                        if index < DinoWorldCatalog.worlds.count {
                                            worldRow(DinoWorldCatalog.worlds[index], layout: layout)
                                        }
                                    }
                                }
                            }
                        }
                        actions(layout: layout)
                    }
                    .padding(layout.margin)
                    .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 28 * layout.scale))
                }
                .padding(layout.margin).padding(.top, 12 * layout.scale)
                .frame(maxWidth: StarsLayout.maximumWidth).frame(maxWidth: .infinity)
                .background {
                    GeometryReader { content in
                        Color.clear.preference(key: StarsContentHeightKey.self, value: ceil(content.size.height))
                    }
                }
            }
            .bouncesOnlyWhenNeeded()
            .accessibilityIdentifier("stars.overview")
        }
        .background(JungleBackground(quiet: true))
        .foregroundStyle(DinoStyle.ink)
    }

    private func actions(layout: StarsLayout) -> some View {
        VStack(spacing: 10 * layout.scale) {
            totalCard(layout: layout)
            returnButton(layout: layout)
        }.frame(maxWidth: .infinity)
    }

    private func totalCard(layout: StarsLayout) -> some View {
        HStack(spacing: 12 * layout.scale) {
            Text("dino.stars.total")
            Spacer(minLength: 0)
            starCount(player.profile.totalStars, scale: layout.scale)
        }
        .font(.system(size: 20 * layout.scale * textScale, weight: .heavy, design: .rounded))
        .padding(.horizontal, 20 * layout.scale)
        .frame(minHeight: 60 * layout.scale)
        .background(.white.opacity(highContrast ? 1 : 0.95), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18)
            .strokeBorder(DinoStyle.ink.opacity(highContrast ? 1 : 0.1), lineWidth: highContrast ? 3 : 1.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stars.total")
    }

    private func returnButton(layout: StarsLayout) -> some View {
        Button { dismiss() } label: {
            Label("dino.practice.backToLevels", systemImage: "map.fill")
                .font(.system(size: 17 * layout.scale * textScale, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 8)
                .frame(minHeight: 60 * layout.scale)
        }
        .buttonStyle(DinoSecondaryButtonStyle(spacious: layout.scale > 1.15))
        .accessibilityIdentifier("stars.close")
    }

    private func worldRow(_ world: DinoWorld, layout: StarsLayout) -> some View {
        let stars = world.levels.reduce(0) { $0 + player.profile.record($1).stars }
        let unlocked = player.profile.isWorldUnlocked(world.id)
        let tint = Color(dinoHex: world.ground)
        let scale = layout.scale
        return HStack(spacing: 10 * scale) {
            Text(world.id, format: .number)
                .font(.system(size: 14 * scale * textScale, weight: .heavy, design: .rounded))
                .frame(minWidth: 32 * scale, minHeight: 32 * scale)
                .padding(2 * max(0, textScale - 1))
                .background(tint, in: Circle())
            Text(LocalizedStringKey(world.titleKey))
                .font(.system(size: 15 * scale * textScale, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Group {
                if unlocked {
                    starCount(stars, scale: scale)
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(highContrast ? DinoStyle.ink : DinoStyle.muted)
                }
            }
            .font(.system(size: 15 * scale * textScale, weight: .semibold, design: .rounded))
            .frame(minWidth: 40 * scale, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, minHeight: 44 * scale)
        .padding(.leading, 12 * scale).padding(.trailing, 20 * scale).padding(.vertical, 8 * scale)
        .background(tint.opacity(0.5), in: RoundedRectangle(cornerRadius: 18 * scale))
        .overlay(RoundedRectangle(cornerRadius: 18 * scale)
            .stroke(highContrast ? DinoStyle.ink.opacity(0.6) : .clear, lineWidth: highContrast ? 1.5 : 0))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stars.world.\(world.id)")
    }

    private func starCount(_ count: Int, scale: CGFloat) -> some View {
        HStack(spacing: 6 * scale) {
            Text(count, format: .number.grouping(.never)).monospacedDigit()
            DinoRewardStar(size: 22 * scale * textScale)
        }.fixedSize()
    }
}

private struct StarsLayout {
    static let maximumWidth: CGFloat = 1000
    let size: CGSize
    let landscape: Bool
    let accessibilityText: Bool

    // Scale against the actual sheet/window so rotation and narrow iPad windows
    // follow the same rules as phones. Width alone keeps content fitting stable
    // when the sheet adjusts its height to the measured content.
    var scale: CGFloat { min(1.4, max(1, size.width / 560)) }
    var margin: CGFloat { 16 * scale }
    var columns: Int { min(size.width, Self.maximumWidth) >= (landscape ? 500 : 700) && !accessibilityText ? 2 : 1 }
    var rowCount: Int { (DinoWorldCatalog.worlds.count + columns - 1) / columns }
}

private struct StarsContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

extension DinoStarsOverview {
    func starsPresentation(maximumHeight: CGFloat) -> some View {
        modifier(StarsPresentation(maximumHeight: maximumHeight))
    }
}

private struct StarsPresentation: ViewModifier {
    let maximumHeight: CGFloat
    @State private var contentHeight: CGFloat = 860

    private var fittedHeight: CGFloat { min(contentHeight, max(120, maximumHeight)) }

    func body(content: Content) -> some View {
        presentation(content)
            .onPreferenceChange(StarsContentHeightKey.self) { height in
                guard height > 0, height != contentHeight else { return }
                contentHeight = height
            }
    }

    @ViewBuilder private func presentation(_ content: Content) -> some View {
        if #available(iOS 18, *) {
            content.presentationSizing(StarsPresentationSizing(contentHeight: fittedHeight))
                .presentationDetents([.height(fittedHeight)])
                .presentationCompactAdaptation(.none)
                .presentationCornerRadius(28)
        } else if #available(iOS 16.4, *) {
            content.presentationDetents([.height(fittedHeight)])
                .presentationCompactAdaptation(.none)
        } else {
            content.presentationDetents([.height(fittedHeight)])
        }
    }
}

@available(iOS 18, *)
private struct StarsPresentationSizing: PresentationSizing {
    let contentHeight: CGFloat

    func proposedSize(for root: PresentationSizingRoot, context: PresentationSizingContext) -> ProposedViewSize {
        let page = PagePresentationSizing.page.proposedSize(for: root, context: context)
        return ProposedViewSize(width: page.width, height: min(page.height ?? contentHeight, contentHeight))
    }
}
