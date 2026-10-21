import SwiftUI

struct DinoCharacter: View {
    enum State: String { case idle, happy, thinking, sad, celebrating, boss }
    var state: State = .idle
    var size: CGFloat = 150
    var performsBackflip = false
    var performsPirouette = false
    var givesThumbsUp = false
    var exposesAnimationIdentifier = true
    var preparesReactions = true
    @EnvironmentObject private var player: DinoPlayer
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var start = Date()
    @State private var finished = false
    @State private var playbackClip: DinoAnimation.Clip = .idle
    @State private var prepared: (appearance: DinoAppearance, images: [String: UIImage])?

    private var appearance: DinoAppearance { player.profile.dinoAppearance ?? .standard }

    private var clip: DinoAnimation.Clip {
        performsBackflip ? .backflip : performsPirouette ? .pirouette : givesThumbsUp ? .thumbsUp : state == .sad ? .wrongAnswer : .idle
    }

    private var animationIdentifier: String {
        switch clip {
        case .idle: "dino.character"
        case .thumbsUp: "dino.thumbsUp"
        case .wrongAnswer: "dino.wrongAnswer"
        case .backflip: "dino.backflip"
        case .pirouette: "dino.pirouette"
        case .worldJump: "dino.worldJump"
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60,
                                paused: clip == .idle || (playbackClip == clip && finished) || reduceMotion || scenePhase != .active)) { context in
            // A finished answer reaction must not lend its final time or paused
            // schedule to the new jump before the playback task starts.
            let elapsed = playbackClip != clip ? 0 : finished ? DinoAnimation.duration(clip) : context.date.timeIntervalSince(start)
            let sample = DinoAnimation.sample(clip, elapsed: elapsed, reducedMotion: reduceMotion)
            sprite(sample.pose, angle: sample.angle, yaw: sample.yaw)
                .scaleEffect(x: sample.scaleX, y: sample.scaleY, anchor: .bottom)
                .offset(y: size * sample.height)
                // Feedback must never inherit the answer cards' opacity/layout animation.
                .transaction { $0.animation = nil }
        }
        .id(clip)
        .transition(.identity)
        .frame(width: size, height: size)
        .shadow(color: DinoStyle.deepGreen.opacity(0.10), radius: 8, y: 5)
        .accessibilityIdentifier(exposesAnimationIdentifier ? animationIdentifier : "")
        .task(id: appearance) {
            guard preparesReactions || clip != .idle else { return }
            let colors = appearance
            // Prepare every pose between reactions, so a short animation never
            // flashes back to green while its next frame is being recolored.
            do { try await Task.sleep(for: .milliseconds(35)) } catch { return }
            let images = await DinoSpriteLoader.shared.images(for: colors)
            guard !Task.isCancelled, !images.isEmpty else { return }
            prepared = (colors, images)
        }
        .task(id: clip) {
            start = Date(); finished = false; playbackClip = clip
            guard clip != .idle else { return }
            do { try await Task.sleep(for: .seconds(DinoAnimation.duration(clip))) } catch { return }
            finished = true
        }
    }

    @ViewBuilder private func sprite(_ pose: DinoAnimation.Pose, angle: Double, yaw: Double) -> some View {
        let image = Group {
            if let prepared, prepared.appearance == appearance, let image = prepared.images[pose.asset] {
                Image(uiImage: image).resizable().scaledToFit().accessibilityHidden(true)
            } else {
                DinoAvatar(appearance: appearance, asset: pose.asset)
            }
        }.frame(width: size, height: size)
            .offset(x: size * pose.offsetX, y: size * pose.offsetY)
            .rotationEffect(.degrees(angle - pose.paintedAngle),
                            anchor: clip == .backflip ? UnitPoint(x: 0.5, y: 0.52) : .bottom)
        if clip == .pirouette {
            // The supplied views carry the turn. A small residual motion keeps
            // them alive without squeezing Dino into a thin rotating card.
            image.rotation3DEffect(.degrees(min(9, max(-9, yaw - pose.paintedYaw))), axis: (x: 0, y: 1, z: 0),
                                   anchor: UnitPoint(x: 0.5, y: 0.52), perspective: 0.18)
        } else {
            image
        }
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
    var worldID = 1
    var compactPortrait = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var placement = CGRect.zero
    @State private var visible = false
    @State private var atResult = false
    @State private var portraitAmount: CGFloat = 1
    @State private var presentedClip: DinoAnimation.Clip = .idle

    var body: some View {
        Group {
            if destination != nil || isResult {
                // A fixed drawing size lets position and scale animate without restarting the sprite.
                ZStack {
                    DinoCharacter(state: presentedClip == .wrongAnswer ? .sad : .idle, size: 210,
                                  performsBackflip: presentedClip == .backflip, performsPirouette: presentedClip == .pirouette,
                                  givesThumbsUp: presentedClip == .thumbsUp, exposesAnimationIdentifier: false)
                        // Give each reaction fresh playback state as well as a fresh timeline.
                        // Position and scale still belong to this persistent companion layer.
                        .id(presentedClip)
                        .transition(.identity)
                        .modifier(DinoCompanionPresentation(portraitAmount: portraitAmount,
                                                           palette: HUDPalette(worldID: worldID),
                                                           rimRatio: 4 / (compactPortrait ? 52 : 78),
                                                           showsHands: presentedClip != .idle))
                        .accessibilityHidden(true)
                    // Give VoiceOver the portrait bounds rather than the uncropped sprite.
                    Color.clear.frame(width: 210, height: 210)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(verbatim: "Dino"))
                        .accessibilityIdentifier(presentedClip == .idle ? "dino.character" : "dino.\(presentedClip.rawValue)")
                }
                    .frame(width: 210, height: 210)
                    .scaleEffect(placement.width / 210)
                    .position(x: placement.midX, y: placement.midY)
                    .opacity(visible ? 1 : 0)
                    .accessibilityHidden(!visible)
                    .onValueChange(of: destination, initial: true) { target in
                        guard let target else {
                            // Keep the takeoff position while the new result layout reports its anchor.
                            if !isResult { visible = false; atResult = false }
                            return
                        }
                        let arriving = isResult && !atResult
                        atResult = isResult
                        showClip(clip)
                        guard visible, !reduceMotion else {
                            var transaction = Transaction()
                            transaction.disablesAnimations = true
                            withTransaction(transaction) {
                                placement = target; visible = true
                                portraitAmount = isResult ? 0 : 1
                            }
                            return
                        }
                        if arriving {
                            let delay = DinoAnimation.travelDelay(clip)
                            let travel = DinoAnimation.travelDuration(clip) - delay
                            // Unfold the bust into a full character as he leaves the circle.
                            // Keep the same sprite and finish on the existing rock anchor.
                            withAnimation(.easeOut(duration: 0.24).delay(delay)) { portraitAmount = 0 }
                            let journey: Animation = clip == .pirouette
                                ? .timingCurve(0.20, 0.65, 0.35, 1, duration: travel)
                                : .easeInOut(duration: travel)
                            withAnimation(journey.delay(delay)) { placement = target }
                        } else {
                            // Track the portrait or result anchor immediately on layout changes.
                            var transaction = Transaction()
                            transaction.disablesAnimations = true
                            withTransaction(transaction) {
                                placement = target
                                portraitAmount = isResult ? 0 : 1
                            }
                        }
                    }
            }
        }
        .onValueChange(of: clip, initial: true) { next in
            // Hold the last portrait pose while the result scene measures its rock.
            // Start the sprite and its journey together once that destination exists.
            if !isResult || destination != nil { showClip(next) }
        }
    }

    private func showClip(_ next: DinoAnimation.Clip) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { presentedClip = next }
    }
}

/// The HUD and the result share one drawing buffer. Only its crop changes on takeoff.
private struct DinoCompanionPresentation: AnimatableModifier {
    var portraitAmount: CGFloat
    let palette: HUDPalette
    let rimRatio: CGFloat
    let showsHands: Bool
    var animatableData: CGFloat {
        get { portraitAmount }
        set { portraitAmount = newValue }
    }

    func body(content: Content) -> some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [palette.portraitLight, palette.accent],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(Circle().strokeBorder(palette.outline, lineWidth: 210 * rimRatio / 2))
                .opacity(portraitAmount)
            content
                .scaleEffect(1 + (1 / (showsHands ? 0.78 : 0.62) - 1) * portraitAmount)
                .offset(x: -210 * (showsHands ? 0.025 : 0.065) * portraitAmount,
                        y: 210 * (showsHands ? 0.14 : 0.339) * portraitAmount)
                .mask(DinoCompanionReveal(portraitAmount: portraitAmount))
            Circle().strokeBorder(palette.rim, lineWidth: 210 * rimRatio)
                .mask {
                    Path { path in
                        path.addRect(CGRect(x: -210, y: -210, width: 630, height: 630))
                        path.addPath(DinoBustOverflowMask(diameter: 210).path(in: CGRect(x: 0, y: 0, width: 210, height: 210)))
                    }.fill(style: FillStyle(eoFill: true))
                }
                .opacity(portraitAmount)
        }.frame(width: 210, height: 210)
    }
}

private struct DinoCompanionReveal: Shape {
    var portraitAmount: CGFloat
    func path(in rect: CGRect) -> Path {
        let expansion = rect.width * 2 * (1 - portraitAmount)
        var path = Path(ellipseIn: rect.insetBy(dx: -expansion, dy: -expansion))
        path.addPath(DinoBustOverflowMask(diameter: rect.width).path(in: rect))
        return path
    }
}
