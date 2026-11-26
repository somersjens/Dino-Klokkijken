import SwiftUI
import UIKit

/// Reuses the original illustration, retaining its texture, shading and facial details.
struct DinoAvatar: View {
    let appearance: DinoAppearance
    var portrait = false
    var asset = "dino-idle"
    @State private var rendered: (key: RenderKey, image: UIImage)?

    private var renderKey: RenderKey { RenderKey(appearance: appearance, portrait: portrait, asset: asset) }

    private var standardImage: UIImage? {
        guard portrait || asset != "dino-idle" else { return UIImage(named: asset) }
        return DinoAvatarRenderer.render(original: UIImage(named: asset)?.cgImage,
                                         appearance: .standard, portrait: portrait, asset: asset)
    }

    private var image: UIImage? {
        if let rendered, rendered.key == renderKey { return rendered.image }
        if let cached = DinoAvatarRenderer.cached(appearance: appearance, portrait: portrait, asset: asset) { return cached }
        if appearance == .standard { return standardImage }
        if let rendered, rendered.key.appearance.identity == appearance.identity,
           rendered.key.asset == asset, rendered.key.portrait == portrait {
            return rendered.image
        }
        // A cold launch has no rendered state or memory cache yet. Prepare this
        // first image before drawing; showing the standard art would flash the
        // wrong colors. Subsequent picker changes still use the async task below.
        return DinoAvatarRenderer.render(original: appearance.identity.usesBossArtwork ? nil : UIImage(named: asset)?.cgImage,
                                         appearance: appearance, portrait: portrait, asset: asset)
    }

    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFit() }
            else { Color.clear }
        }
        .accessibilityHidden(true)
        .task(id: renderKey) {
            let key = renderKey
            if let cached = DinoAvatarRenderer.cached(appearance: appearance, portrait: portrait, asset: asset) {
                rendered = (key, cached)
                return
            }
            if appearance == .standard, !portrait, asset == "dino-idle" {
                rendered = nil
                return
            }
            let original = appearance.identity.usesBossArtwork ? nil : UIImage(named: asset)?.cgImage
            // The system color picker can emit many changes while a finger moves.
            do { try await Task.sleep(for: .milliseconds(35)) } catch { return }
            let job = Task.detached(priority: .userInitiated) {
                DinoAvatarRenderer.render(original: original, appearance: key.appearance, portrait: key.portrait, asset: key.asset)
            }
            let image = await withTaskCancellationHandler {
                await job.value
            } onCancel: {
                job.cancel()
            }
            guard !Task.isCancelled else { return }
            if let image { rendered = (key, image) }
        }
    }

    private struct RenderKey: Hashable {
        let appearance: DinoAppearance
        let portrait: Bool
        let asset: String
    }
}

/// All visible characters share one preparation job and one retained sprite set.
/// A new color selection cancels obsolete work; opening another menu reuses it.
actor DinoSpriteLoader {
    static let shared = DinoSpriteLoader()
    private var appearance: DinoAppearance?
    private var job: Task<[String: UIImage], Never>?
    private var answerAppearance: DinoAppearance?
    private var answerJob: Task<[String: UIImage], Never>?

    /// The map only needs the standing pose. Keep its first recolor off the
    /// main thread without decoding twenty unused celebration frames at launch.
    func idleImage(for colors: DinoAppearance, resolution: DinoSpriteColorRenderer.Resolution = .standard) async -> UIImage? {
        if let cached = DinoAvatarRenderer.cached(appearance: colors, portrait: false, asset: "dino-idle", resolution: resolution) {
            return cached
        }
        let preparation = Task.detached(priority: .userInitiated) {
            let image = DinoAvatarRenderer.render(original: colors.identity.usesBossArtwork ? nil : UIImage(named: "dino-idle")?.cgImage,
                                      appearance: colors, portrait: false, resolution: resolution)
            if colors.identity.usesBossArtwork, resolution == .standard { _ = DinoAvatarRenderer.bossHead(appearance: colors, asset: "dino-idle") }
            return image
        }
        return await withTaskCancellationHandler { await preparation.value } onCancel: { preparation.cancel() }
    }

    /// Publish and retain the short answer set before preparing result animations.
    /// Otherwise the bitmap cache can evict early clap frames while the full set
    /// is still loading, forcing a synchronous recolor during the first answer.
    func answerImages(for colors: DinoAppearance) async -> [String: UIImage] {
        guard !Task.isCancelled else { return [:] }
        if answerAppearance != colors || answerJob == nil || answerJob?.isCancelled == true {
            answerJob?.cancel()
            if appearance != colors { job?.cancel() }
            answerAppearance = colors
            answerJob = Task.detached(priority: .userInitiated) {
                var images: [String: UIImage] = [:]
                for asset in ["dino-idle"] + DinoAnimation.correctAnswerAssets + DinoAnimation.wrongAnswerAssets {
                    guard !Task.isCancelled else { return [:] }
                    let image = DinoAvatarRenderer.render(original: colors.identity.usesBossArtwork ? nil : UIImage(named: asset)?.cgImage,
                                                          appearance: colors, portrait: false, asset: asset)
                    images[asset] = image
                    if colors.identity.usesBossArtwork {
                        let drawing = colors.identity.asset(for: asset)
                        images[drawing] = image
                        if let head = DinoAvatarRenderer.bossHead(appearance: colors, asset: asset) {
                            images["head-" + asset] = head
                            images["head-" + drawing] = head
                        }
                    }
                }
                return images
            }
        }
        return await answerJob!.value
    }

    func images(for colors: DinoAppearance) async -> [String: UIImage] {
        let answers = await answerImages(for: colors)
        guard !Task.isCancelled else { return [:] }
        if appearance != colors || job == nil || job?.isCancelled == true {
            job?.cancel()
            appearance = colors
            job = Task.detached(priority: .userInitiated) {
                var images = answers
                let assets = colors.identity.usesBossArtwork ? colors.identity.artworkAssets.sorted() : DinoAnimation.spriteAssets
                for asset in assets {
                    guard !Task.isCancelled else { return [:] }
                    if images[asset] != nil { continue }
                    if let cached = DinoAvatarRenderer.cached(appearance: colors, portrait: false, asset: asset) {
                        images[asset] = cached
                    } else {
                        images[asset] = DinoAvatarRenderer.render(original: colors.identity.usesBossArtwork ? nil : UIImage(named: asset)?.cgImage,
                                                                appearance: colors, portrait: false, asset: asset)
                    }
                }
                if colors.identity.usesBossArtwork {
                    for asset in DinoBossAnimation.portraitAssets(for: colors.identity) {
                        guard !Task.isCancelled else { return [:] }
                        images["head-" + asset] = DinoAvatarRenderer.bossHead(appearance: colors, asset: asset)
                    }
                }
                return images
            }
        }
        return await job!.value
    }

    func worldJumpImages(for colors: DinoAppearance) async -> [String: UIImage] {
        let preparation = Task.detached(priority: .userInitiated) { () -> [String: UIImage] in
            var images: [String: UIImage] = [:]
            let poses = colors.identity.usesBossArtwork
                ? DinoBossAnimation.assets(for: .worldJump, character: colors.identity) : DinoAnimation.worldJumpAssets
            for asset in Set(["dino-idle"] + poses) {
                guard !Task.isCancelled else { return [:] }
                images[asset] = DinoAvatarRenderer.render(original: colors.identity.usesBossArtwork ? nil : UIImage(named: asset)?.cgImage,
                                                         appearance: colors, portrait: false, asset: asset)
            }
            if colors.identity.usesBossArtwork { _ = DinoAvatarRenderer.bossHead(appearance: colors, asset: "dino-idle") }
            return images
        }
        return await withTaskCancellationHandler { await preparation.value } onCancel: { preparation.cancel() }
    }

    /// Two background workers prepare the opening's original-size poses. These
    /// copies stay separate from the compact result sprites and are released after landing.
    func openingJumpImages(for colors: DinoAppearance) async -> [String: UIImage] {
        await withTaskGroup(of: (String, UIImage?).self) { group in
            var next = DinoWelcomeJump.assets(for: colors.identity).makeIterator()
            func enqueue(_ asset: String) {
                group.addTask(priority: .userInitiated) {
                    guard !Task.isCancelled else { return (asset, nil) }
                    let image = DinoAvatarRenderer.render(original: colors.identity.usesBossArtwork ? nil : UIImage(named: asset)?.cgImage,
                        appearance: colors, portrait: false, asset: asset, resolution: .original)
                    return (asset, image)
                }
            }
            for _ in 0..<2 { if let asset = next.next() { enqueue(asset) } }
            var images: [String: UIImage] = [:]
            for await (asset, image) in group {
                guard !Task.isCancelled else { group.cancelAll(); return [:] }
                images[asset] = image
                if let asset = next.next() { enqueue(asset) }
            }
            return images
        }
    }
}

/// A circular bust. Bandana tails and the top spikes sit in front of the rim, with a little more body than the HUD.
struct DinoPortrait: View {
    let appearance: DinoAppearance
    let size: CGFloat
    var circular = true

    private var footprint: CGFloat { size * 68 / 52 }
    /// Slightly higher than the HUD so more of the torso stays inside the circle.
    private let placement = CGFloat(0.28)

    var body: some View {
        if circular {
            ZStack {
                Circle().fill(Color(dinoHex: 0xD9EDAD))
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                    .frame(width: size, height: size)
                DinoBustImage(appearance: appearance, diameter: size, placement: placement)
                    .clipShape(Circle())
                Circle().strokeBorder(.white, lineWidth: 2)
                    .frame(width: size, height: size)
                DinoBustImage(appearance: appearance, diameter: size, placement: placement, headOnly: appearance.identity.usesBossArtwork)
                    .frame(width: footprint, height: footprint)
                    .mask(DinoBustOverflowMask(diameter: size, placement: placement, leafyCrown: appearance.identity.usesBossArtwork))
            }
            .frame(width: footprint, height: footprint)
        } else {
            DinoAvatar(appearance: appearance, portrait: true)
                .frame(width: size, height: size)
                .shadow(color: DinoStyle.deepGreen.opacity(0.10), radius: 2, y: 2)
        }
    }
}

/// Show the neck and upper body; the original recolored sprite remains intact.
struct DinoBustImage: View {
    let appearance: DinoAppearance
    let diameter: CGFloat
    var placement: CGFloat = 0.339
    var headOnly = false
    var body: some View {
        Group {
            if headOnly {
                if let image = DinoAvatarRenderer.bossHead(appearance: appearance, asset: "dino-idle") {
                    Image(uiImage: image).resizable().scaledToFit()
                } else {
                    Color.clear
                }
            } else {
                DinoAvatar(appearance: appearance)
            }
        }
            .frame(width: diameter * (appearance.identity.usesBossArtwork ? appearance.identity.portraitScale : 1 / 0.62),
                   height: diameter * (appearance.identity.usesBossArtwork ? appearance.identity.portraitScale : 1 / 0.62))
            .offset(x: diameter * (appearance.identity.usesBossArtwork ? appearance.identity.portraitOffsetX : -0.065),
                    y: diameter * (appearance.identity.usesBossArtwork ? placement + appearance.identity.portraitOffsetY - 0.339 : placement))
            .frame(width: diameter, height: diameter)
            .accessibilityHidden(true)
    }
}

/// The bandana tails and both top spikes cross the portrait and its rim.
struct DinoBustOverflowMask: Shape {
    let diameter: CGFloat
    var placement: CGFloat = 0.339
    var leafyCrown = false
    func path(in rect: CGRect) -> Path {
        let origin = CGPoint(x: rect.midX - diameter / 2, y: rect.midY - diameter / 2)
        if leafyCrown {
            // Jungle uses a separately masked head image, never a rectangular
            // window onto the animated full body.
            return Path(rect.insetBy(dx:-diameter,dy:-diameter))
        }
        let bandanaLift = (0.339 - placement) * diameter
        var path = Path(CGRect(x: origin.x - diameter * 0.23 / 0.62,
                               y: origin.y + diameter * 0.165 / 0.62 - bandanaLift,
                               width: diameter * 0.355 / 0.62, height: diameter * 0.192 / 0.62 + bandanaLift))
        // Follow the sprite placement; transparent pixels keep the curved silhouette.
        let spriteSize = diameter / 0.62
        let spriteOrigin = CGPoint(x: rect.midX - spriteSize / 2 - diameter * 0.065,
                                   y: rect.midY - spriteSize / 2 + diameter * placement)
        path.addRect(CGRect(x: spriteOrigin.x + spriteSize * 0.31,
                            y: spriteOrigin.y,
                            width: spriteSize * 0.22, height: spriteSize * 0.19))
        return path
    }
}

enum DinoAvatarRenderer {
    // Short portrait reactions retain their own bounded cache. Loading a larger
    // result set cannot evict a prepared head between the two clap contacts.
    private static let headCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 16 * 1024 * 1024
        return cache
    }()
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 32 * 1024 * 1024
        return cache
    }()

    private static func cacheKey(appearance: DinoAppearance, portrait: Bool, asset: String,
                                 resolution: DinoSpriteColorRenderer.Resolution = .standard) -> NSString {
        let drawing = appearance.identity.usesBossArtwork ? appearance.identity.asset(for: asset) : asset
        return "\(appearance.identity.rawValue)-\(drawing)-\(appearance.bandana)-\(appearance.spikes)-\(appearance.body)-\(appearance.belly)-\(portrait)-\(resolution.rawValue)" as NSString
    }

    static func cached(appearance: DinoAppearance, portrait: Bool, asset: String,
                       resolution: DinoSpriteColorRenderer.Resolution = .standard) -> UIImage? {
        cache.object(forKey: cacheKey(appearance: appearance, portrait: portrait, asset: asset, resolution: resolution))
    }

    static func releaseOpeningImages(appearance: DinoAppearance) {
        for asset in DinoWelcomeJump.assets(for: appearance.identity) {
            cache.removeObject(forKey: cacheKey(appearance: appearance, portrait: false, asset: asset, resolution: .original))
        }
    }

    static func bossHead(appearance: DinoAppearance, asset: String) -> UIImage? {
        let key = "head-\(cacheKey(appearance:appearance,portrait:false,asset:asset))" as NSString
        if let cached = headCache.object(forKey:key) { return cached }
        guard let body = render(original:nil,appearance:appearance,portrait:false,asset:asset)?.cgImage,
              let head = DinoSpriteColorRenderer.bossHeadOverflow(body, character:appearance.identity, asset:asset) else { return nil }
        let image = UIImage(cgImage:head)
        headCache.setObject(image,forKey:key,cost:head.bytesPerRow*head.height)
        return image
    }

    static func render(original: CGImage?, appearance: DinoAppearance, portrait: Bool, asset: String = "dino-idle",
                       resolution: DinoSpriteColorRenderer.Resolution = .standard) -> UIImage? {
        if appearance.identity.usesBossArtwork {
            let key = cacheKey(appearance: appearance, portrait: portrait, asset: asset, resolution: resolution)
            if let image = cache.object(forKey: key) { return image }
            let drawing = appearance.identity.asset(for: asset)
            let sourceAsset = resolution == .original && drawing == appearance.identity.asset(for: "dino-idle") ? appearance.identity.openingAsset : drawing
            guard let source = UIImage(named: sourceAsset)?.cgImage,
                  let recolored = DinoSpriteColorRenderer.recoloredBoss(source, appearance:appearance, asset:sourceAsset),
                  let colored = DinoSpriteColorRenderer.facingRight(recolored) else { return nil }
            let output: CGImage
            if portrait, appearance.identity != .jungle {
                let head: CGImage
                let crop: CGRect
                switch appearance.identity {
                case .castle:
                    guard let isolated = DinoSpriteColorRenderer.castleHead(colored, asset: sourceAsset, mirrored: true, includesFace: true) else { return nil }
                    head = isolated
                    crop = DinoCastleArtwork.portraitCrop
                case .pirates:
                    head = DinoSpriteColorRenderer.pirateHead(colored, asset: sourceAsset, mirrored: true, includesFace: true) ?? colored
                    crop = DinoPirateArtwork.portraitCrop
                case .valley:
                    head = DinoSpriteColorRenderer.valleyHead(colored, asset: sourceAsset, mirrored: true, includesFace: true) ?? colored
                    crop = DinoValleyArtwork.portraitCrop
                case .machine:
                    head = DinoSpriteColorRenderer.machineHead(colored, asset: sourceAsset, mirrored: true, includesFace: true) ?? colored
                    crop = DinoMachineArtwork.portraitCrop
                case .city:
                    head = DinoSpriteColorRenderer.cityHead(colored, asset: sourceAsset, mirrored: true, includesFace: true) ?? colored
                    crop = DinoCityArtwork.portraitCrop
                case .cave:
                    head = DinoSpriteColorRenderer.caveHead(colored, asset: sourceAsset, mirrored: true, includesFace: true) ?? colored
                    crop = DinoCaveArtwork.portraitCrop
                case .village:
                    head = DinoSpriteColorRenderer.villageHead(colored, asset: sourceAsset, mirrored: true, includesFace: true) ?? colored
                    crop = DinoVillageArtwork.portraitCrop
                case .volcano:
                    head = DinoSpriteColorRenderer.volcanoHeadOverflow(colored, asset: sourceAsset) ?? colored
                    crop = DinoVolcanoArtwork.portraitCrop
                default:
                    head = DinoSpriteColorRenderer.bossHeadOverflow(colored, character: appearance.identity, asset: sourceAsset) ?? colored
                    crop = CGRect(x: 0.40, y: 0, width: 0.60, height: 0.56)
                }
                output = head.cropping(to:CGRect(x:CGFloat(head.width)*crop.minX,y:CGFloat(head.height)*crop.minY,width:CGFloat(head.width)*crop.width,height:CGFloat(head.height)*crop.height)) ?? head
            } else { output = portrait ? junglePortrait(colored) ?? colored : colored }
            let image = UIImage(cgImage: output)
            cache.setObject(image, forKey: key, cost: output.bytesPerRow * output.height)
            return image
        }
        guard let original else { return nil }
        let key = cacheKey(appearance: appearance, portrait: portrait, asset: asset, resolution: resolution)
        if let cached = cache.object(forKey: key) { return cached }
        let colored: CGImage
        if portrait, let body = cached(appearance: appearance, portrait: false, asset: asset, resolution: resolution)?.cgImage {
            colored = body
        } else if appearance == .standard, asset == "dino-idle" {
            // The default is the untouched original, including all original shades.
            colored = original
        } else {
            guard let result = DinoSpriteColorRenderer.recolored(original, appearance: appearance, asset: asset, resolution: resolution) else { return nil }
            colored = DinoSpriteColorRenderer.applauseBody(result, original: original, asset: asset) ?? result
            if portrait {
                // Share the first recolor with the full character on the map.
                cache.setObject(UIImage(cgImage: result),
                                forKey: cacheKey(appearance: appearance, portrait: false, asset: asset, resolution: resolution),
                                cost: result.width * result.height * 4)
            }
        }
        let output: CGImage
        if portrait {
            output = headPortrait(colored) ?? colored
        } else { output = colored }
        let image = UIImage(cgImage: output)
        cache.setObject(image, forKey: key, cost: output.width * output.height * 4)
        return image
    }

    private static func headPortrait(_ source: CGImage) -> CGImage? {
        let width = CGFloat(source.width), height = CGFloat(source.height)
        let size = Int((width * 0.60).rounded())
        guard let context = CGContext(data: nil, width: size, height: size,
                                      bitsPerComponent: 8, bytesPerRow: size * 4,
                                      space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        // Padding above the spikes centers the entire head within the circle.
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: (x - 0.155) * width, y: CGFloat(size) - (y + 0.055) * height)
        }
        // Follow the underside of the jaw and the back spikes, excluding both hands
        // and the torso rather than ending the head with a rectangular neck cut.
        let head = CGMutablePath()
        head.move(to: point(0, 0))
        head.addLine(to: point(1, 0))
        head.addLine(to: point(1, 0.415))
        head.addLine(to: point(0.72, 0.415))
        head.addCurve(to: point(0.573, 0.469), control1: point(0.650, 0.452), control2: point(0.625, 0.469))
        head.addCurve(to: point(0.438, 0.440), control1: point(0.519, 0.468), control2: point(0.473, 0.449))
        head.addCurve(to: point(0.425, 0.449), control1: point(0.432, 0.445), control2: point(0.429, 0.449))
        head.addLine(to: point(0, 0.449))
        head.closeSubpath()
        context.addPath(head)
        context.clip()
        context.interpolationQuality = .high
        context.draw(source, in: CGRect(x: -0.155 * width, y: CGFloat(size) - 1.055 * height,
                                       width: width, height: height))
        return context.makeImage()
    }

    private static func junglePortrait(_ source: CGImage) -> CGImage? {
        source.cropping(to: CGRect(x: CGFloat(source.width) * 0.13, y: 0,
                                  width: CGFloat(source.width) * 0.64, height: CGFloat(source.height) * 0.54))
    }


}
