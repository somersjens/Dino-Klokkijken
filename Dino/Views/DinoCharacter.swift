import SwiftUI

struct DinoCharacter: View {
    enum State: String { case idle, happy, thinking, sad, celebrating, boss }
    var state: State = .idle
    var size: CGFloat = 150
    var performsBackflip = false
    var givesThumbsUp = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var finished = false

    private var clip: DinoAnimation.Clip { performsBackflip ? .backflip : givesThumbsUp ? .thumbsUp : .idle }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: clip == .idle || finished || reduceMotion)) { context in
            let elapsed = finished ? DinoAnimation.duration(clip) : context.date.timeIntervalSince(start)
            let pose = DinoAnimation.sample(clip, elapsed: elapsed, reducedMotion: reduceMotion)
            ZStack {
                sprite(pose.first, angle: pose.angle).opacity(1 - pose.blend)
                sprite(pose.second, angle: pose.angle).opacity(pose.blend).blendMode(.plusLighter)
            }.compositingGroup()
            .scaleEffect(x: pose.scaleX, y: pose.scaleY, anchor: .bottom)
            .offset(y: size * pose.height)
        }
        .frame(width: size, height: size)
        .shadow(color: DinoStyle.deepGreen.opacity(0.10), radius: 8, y: 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("dino.character"))
        .accessibilityAddTraits(.isImage)
        .accessibilityIdentifier(performsBackflip ? "dino.backflip" : givesThumbsUp ? "dino.thumbsUp" : "dino.character")
        .task(id: clip) {
            start = Date(); finished = false
            guard clip != .idle else { return }
            do { try await Task.sleep(for: .seconds(DinoAnimation.duration(clip))) } catch { return }
            finished = true
        }
    }

    private func sprite(_ pose: DinoAnimation.Pose, angle: Double) -> some View {
        Image(pose.asset).resizable().scaledToFit().frame(width: size, height: size)
            .offset(x: size * pose.offsetX, y: size * pose.offsetY)
            .rotationEffect(.degrees(angle - pose.paintedAngle), anchor: UnitPoint(x: 0.5, y: 0.52))
    }
}
