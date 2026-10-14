import SwiftUI

struct DinoCharacter: View {
    enum State: String { case idle, happy, thinking, sad, celebrating, boss }
    var state: State = .idle
    var size: CGFloat = 150
    var performsBackflip = false
    var givesThumbsUp = false
    @EnvironmentObject private var player: DinoPlayer
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var finished = false

    private var appearance: DinoAppearance { player.profile.dinoAppearance ?? .standard }

    private var clip: DinoAnimation.Clip {
        performsBackflip ? .backflip : givesThumbsUp ? .thumbsUp : state == .sad ? .wrongAnswer : .idle
    }

    private var animationIdentifier: String {
        switch clip {
        case .idle: "dino.character"
        case .thumbsUp: "dino.thumbsUp"
        case .wrongAnswer: "dino.wrongAnswer"
        case .backflip: "dino.backflip"
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: clip == .idle || finished || reduceMotion)) { context in
            let elapsed = finished ? DinoAnimation.duration(clip) : context.date.timeIntervalSince(start)
            let sample = DinoAnimation.sample(clip, elapsed: elapsed, reducedMotion: reduceMotion)
            sprite(sample.pose, angle: sample.angle)
                .scaleEffect(x: sample.scaleX, y: sample.scaleY, anchor: .bottom)
                .offset(y: size * sample.height)
                // Feedback must never inherit the answer cards' opacity/layout animation.
                .transaction { $0.animation = nil }
        }
        .frame(width: size, height: size)
        .shadow(color: DinoStyle.deepGreen.opacity(0.10), radius: 8, y: 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("dino.character"))
        .accessibilityAddTraits(.isImage)
        .accessibilityIdentifier(animationIdentifier)
        .task(id: appearance) {
            let colors = appearance
            // Prepare every pose between reactions, so a short animation never
            // flashes back to green while its next frame is being recolored.
            do { try await Task.sleep(for: .milliseconds(35)) } catch { return }
            let originals = DinoAnimation.spriteAssets.compactMap { asset in
                UIImage(named: asset)?.cgImage.map { (asset, $0) }
            }
            let job = Task.detached(priority: .userInitiated) {
                for (asset, original) in originals {
                    guard !Task.isCancelled else { return }
                    _ = DinoAvatarRenderer.render(original: original, appearance: colors, portrait: false, asset: asset)
                }
            }
            await withTaskCancellationHandler { await job.value } onCancel: { job.cancel() }
        }
        .task(id: clip) {
            start = Date(); finished = false
            guard clip != .idle else { return }
            do { try await Task.sleep(for: .seconds(DinoAnimation.duration(clip))) } catch { return }
            finished = true
        }
    }

    private func sprite(_ pose: DinoAnimation.Pose, angle: Double) -> some View {
        DinoAvatar(appearance: appearance, asset: pose.asset).frame(width: size, height: size)
            .offset(x: size * pose.offsetX, y: size * pose.offsetY)
            .rotationEffect(.degrees(angle - pose.paintedAngle),
                            anchor: clip == .backflip ? UnitPoint(x: 0.5, y: 0.52) : .bottom)
    }
}

enum DinoCompanionPlacement { case game, result }

struct DinoCompanionPreference: PreferenceKey {
    static var defaultValue: [DinoCompanionPlacement: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [DinoCompanionPlacement: Anchor<CGRect>],
                       nextValue: () -> [DinoCompanionPlacement: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}

/// Screens provide a destination; the character itself lives above the changing scene.
struct DinoCompanionAnchor: View {
    let placement: DinoCompanionPlacement
    let size: CGFloat
    var body: some View {
        Color.clear.frame(width: size, height: size)
            .anchorPreference(key: DinoCompanionPreference.self, value: .bounds) { [placement: $0] }
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct DinoCompanionLayer: View {
    let destination: CGRect?
    let clip: DinoAnimation.Clip
    let isResult: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var placement = CGRect.zero
    @State private var visible = false
    @State private var atResult = false

    var body: some View {
        Group {
            if destination != nil || isResult {
        // A fixed drawing size lets position and scale animate without restarting the sprite.
        DinoCharacter(state: clip == .wrongAnswer ? .sad : .idle, size: 210,
                      performsBackflip: clip == .backflip, givesThumbsUp: clip == .thumbsUp)
            .scaleEffect(placement.width / 210)
            .position(x: placement.midX, y: placement.midY)
            .opacity(visible ? 1 : 0)
            .accessibilityHidden(!visible)
            .onChange(of: destination, initial: true) { _, target in
                guard let target else {
                    // Keep the takeoff position while the new result layout reports its anchor.
                    if !isResult { visible = false; atResult = false }
                    return
                }
                let arriving = isResult && !atResult
                atResult = isResult
                guard visible, !reduceMotion else {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) { placement = target; visible = true }
                    return
                }
                if arriving {
                    withAnimation(.easeInOut(duration: clip == .backflip ? 1.22 : 0.42)) { placement = target }
                } else {
                    // Track the dock or result anchor immediately; only the journey between screens animates.
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) { placement = target }
                }
            }
            }
        }
    }
}
