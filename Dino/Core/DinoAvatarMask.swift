import CoreGraphics
import Foundation

/// Color regions follow the original illustration, including bright spike highlights.
enum DinoAvatarMask {
    static func part(hue: Double, saturation: Double, lightness: Double,
                     x: Double, y: Double, regions: SpriteRegions? = nil) -> DinoAppearance.Part? {
        if let regions { return regions.part(hue: hue, saturation: saturation, lightness: lightness, x: x, y: y) }
        guard saturation > 0.08 else { return nil } // White lettering, eyes and background.
        if hue < 0.055 || hue > 0.95 {
            return y < 0.335 ? .bandana : nil // Leave the mouth and tongue unchanged.
        }
        if (0.18...0.53).contains(hue) {
            // A spike's yellow-green highlights still belong to the spike, not the body.
            if y < 0.19, x > 0.31, x < 0.53,
               upperSpikes.contains(CGPoint(x: x, y: y)) { return .spikes }
            return hue >= 0.315 ? .spikes : .body
        }
        if (0.075..<0.18).contains(hue) {
            // Protect the rounded eyes and dark mouth interior. The cheeks, lip
            // and chin must keep their yellow skin color, including beside the mouth.
            if y > 0.18, y < 0.34, x > 0.425, x < 0.69,
               eyes.contains(CGPoint(x: x, y: y)) { return nil }
            if lightness < 0.25, y > 0.34, y < 0.45, x > 0.47, x < 0.67,
               mouthInterior.contains(CGPoint(x: x, y: y)) { return nil }
            return .belly
        }
        return nil
    }

    /// Each painted pose has its own face and cloth contours. The airborne head
    /// is tilted, so the idle avatar's coordinate mask cannot be reused for it.
    struct SpriteRegions {
        let bandanaBottom: Double
        var tailRight = 0.0
        var tailBottom = 0.0
        let upperSpikes: CGPath
        let eyes: CGPath
        let mouth: CGPath

        func part(hue: Double, saturation: Double, lightness: Double, x: Double, y: Double) -> DinoAppearance.Part? {
            guard saturation > 0.08 else { return nil }
            let point = CGPoint(x: x, y: y)
            if hue < 0.055 || hue > 0.95 {
                return y < bandanaBottom || (x < tailRight && y < tailBottom) ? .bandana : nil
            }
            if (0.18...0.53).contains(hue) {
                if hue >= 0.315 || upperSpikes.contains(point) { return .spikes }
                return .body
            }
            if (0.075..<0.18).contains(hue) {
                // Keep the tongue's warm highlights, while the bright lip still
                // receives the belly color right up to the mouth's curved edge.
                if eyes.contains(point) || (lightness < 0.60 && mouth.contains(point)) { return nil }
                return .belly
            }
            return nil
        }
    }

    static func spriteRegions(for asset: String) -> SpriteRegions? { poses[asset] }

    /// Coordinates trace the six animation illustrations, all 1254 × 1254.
    private static let poses: [String: SpriteRegions] = [
        "dino-thumbs-up-08": SpriteRegions(
            bandanaBottom: 0.36,
            upperSpikes: contours([
                [.move(458, 138), .curve(491, 11, 445, 53, 458, 0), .curve(604, 74, 521, 1, 568, 31), .curve(458, 138, 556, 85, 503, 110)],
                [.move(382, 225), .curve(376, 126, 350, 181, 354, 143), .curve(474, 117, 399, 91, 449, 101), .curve(382, 225, 438, 151, 407, 189)]
            ]),
            eyes: eyeContours([(530, 279, 127, 127), (751, 232, 93, 122)]),
            mouth: contours([[.move(596, 448), .curve(691, 489, 625, 477, 661, 486), .curve(813, 480, 743, 493, 782, 489),
                              .curve(745, 565, 801, 525, 782, 555), .curve(704, 568, 730, 576, 718, 573), .curve(596, 448, 655, 559, 619, 503)]])),
        "dino-backflip-01": SpriteRegions(
            bandanaBottom: 0.35,
            upperSpikes: contours([
                [.move(654, 203), .curve(703, 74, 650, 143, 678, 69), .curve(814, 173, 737, 72, 796, 125), .curve(654, 203, 755, 175, 701, 192)],
                [.move(542, 282), .curve(550, 166, 520, 230, 529, 186), .curve(657, 170, 578, 131, 625, 148), .curve(542, 282, 624, 207, 578, 252)]
            ]),
            eyes: eyeContours([(661, 386, 134, 132), (899, 365, 93, 124)]),
            mouth: contours([[.move(716, 551), .curve(819, 623, 752, 589, 778, 618), .curve(913, 630, 852, 635, 893, 635),
                              .curve(861, 693, 900, 655, 879, 688), .curve(815, 691, 846, 703, 832, 699), .curve(716, 551, 772, 678, 742, 622)]])),
        "dino-backflip-03": SpriteRegions(
            bandanaBottom: 0.28, tailRight: 0.28, tailBottom: 0.50,
            upperSpikes: contours([
                [.move(309, 213), .curve(328, 105, 292, 174, 299, 101), .curve(417, 143, 353, 94, 396, 121), .curve(309, 213, 374, 163, 340, 190)],
                [.move(247, 307), .curve(211, 212, 209, 276, 178, 236), .curve(307, 199, 235, 193, 273, 195), .curve(247, 307, 284, 230, 260, 266)]
            ]),
            eyes: eyeContours([(395, 336, 131, 126), (565, 239, 98, 106)]),
            mouth: contours([[.move(506, 479), .curve(580, 491, 534, 487, 555, 492), .curve(694, 447, 623, 486, 669, 461),
                              .curve(652, 530, 692, 482, 678, 516), .curve(600, 548, 636, 544, 617, 553), .curve(506, 479, 557, 545, 524, 512)]])),
        "dino-backflip-07": SpriteRegions(
            bandanaBottom: 0.405,
            upperSpikes: contours([
                [.move(615, 244), .curve(662, 111, 603, 176, 633, 104), .curve(764, 201, 700, 108, 741, 155), .curve(615, 244, 703, 208, 661, 223)],
                [.move(518, 346), .curve(535, 197, 498, 281, 505, 216), .curve(618, 211, 554, 176, 592, 188), .curve(518, 346, 589, 253, 550, 300)]
            ]),
            eyes: eyeContours([(613, 425, 126, 127), (850, 387, 95, 123)]),
            mouth: contours([[.move(661, 598), .curve(764, 658, 687, 632, 725, 655), .curve(878, 660, 807, 665, 851, 665),
                              .curve(838, 719, 865, 689, 855, 711), .curve(773, 733, 817, 743, 797, 743), .curve(661, 598, 719, 718, 688, 660)]])),
        "dino-backflip-08": SpriteRegions(
            bandanaBottom: 0.365,
            upperSpikes: contours([
                [.move(466, 164), .curve(490, 31, 456, 106, 465, 23), .curve(610, 89, 528, 19, 578, 55), .curve(466, 164, 565, 110, 515, 137)],
                [.move(385, 236), .curve(395, 135, 360, 191, 371, 152), .curve(484, 143, 417, 114, 462, 123), .curve(385, 236, 448, 176, 416, 207)]
            ]),
            eyes: eyeContours([(517, 294, 129, 119), (734, 247, 95, 111)]),
            mouth: contours([[.move(592, 453), .curve(700, 490, 618, 479, 660, 490), .curve(799, 481, 741, 493, 776, 489),
                              .curve(756, 554, 794, 515, 777, 543), .curve(690, 565, 734, 571, 708, 575), .curve(592, 453, 641, 550, 612, 501)]])),
        "dino-wrong-answer-04": SpriteRegions(
            bandanaBottom: 0.385,
            upperSpikes: contours([
                [.move(458, 156), .curve(483, 23, 442, 100, 451, 14), .curve(614, 85, 530, 9, 574, 49), .curve(458, 156, 563, 100, 511, 125)],
                [.move(373, 252), .curve(385, 121, 345, 193, 357, 144), .curve(484, 125, 416, 105, 457, 113), .curve(373, 252, 441, 165, 407, 209)]
            ]),
            eyes: eyeContours([(540, 315, 133, 117), (758, 236, 101, 111)]),
            mouth: contours([[.move(720, 530), .curve(756, 492, 719, 516, 732, 501), .curve(809, 490, 788, 478, 803, 480),
                              .curve(792, 516, 815, 501, 808, 508), .curve(720, 530, 761, 529, 731, 539)]]))
    ]

    private enum Segment {
        case move(Double, Double)
        case curve(Double, Double, Double, Double, Double, Double)
    }

    /// Cubic segments list the end point, then their two control points.
    private static func contours(_ outlines: [[Segment]]) -> CGPath {
        let path = CGMutablePath()
        func point(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x / 1254, y: y / 1254) }
        for outline in outlines {
            for segment in outline {
                switch segment {
                case let .move(x, y): path.move(to: point(x, y))
                case let .curve(x, y, x1, y1, x2, y2):
                    path.addCurve(to: point(x, y), control1: point(x1, y1), control2: point(x2, y2))
                }
            }
            path.closeSubpath()
        }
        return path
    }

    private static func eyeContours(_ rectangles: [(Double, Double, Double, Double)]) -> CGPath {
        let path = CGMutablePath()
        for (x, y, width, height) in rectangles {
            path.addEllipse(in: CGRect(x: x / 1254, y: y / 1254, width: width / 1254, height: height / 1254))
        }
        return path
    }

    /// Curves trace the two exposed top spikes in the original 1254-point illustration.
    /// The red bandana is classified first, so overlapping cloth keeps its own color.
    private static let upperSpikes: CGPath = {
        let path = CGMutablePath()
        func point(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x / 1254, y: y / 1254) }
        path.move(to: point(511, 134))
        path.addCurve(to: point(539, 16), control1: point(506, 66), control2: point(509, 8))
        path.addCurve(to: point(649, 81), control1: point(572, 9), control2: point(622, 41))
        path.addCurve(to: point(511, 134), control1: point(604, 83), control2: point(553, 112))
        path.closeSubpath()
        path.move(to: point(426, 229))
        path.addCurve(to: point(418, 116), control1: point(407, 193), control2: point(402, 133))
        path.addCurve(to: point(517, 124), control1: point(436, 99), control2: point(483, 103))
        path.addCurve(to: point(426, 229), control1: point(484, 145), control2: point(447, 191))
        path.closeSubpath()
        return path
    }()

    private static let mouthInterior: CGPath = {
        let path = CGMutablePath()
        func point(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x / 1254, y: y / 1254) }
        path.move(to: point(605, 440))
        path.addCurve(to: point(706, 492), control1: point(630, 472), control2: point(685, 492))
        path.addCurve(to: point(811, 489), control1: point(742, 500), control2: point(789, 499))
        path.addCurve(to: point(764, 550), control1: point(803, 521), control2: point(788, 543))
        path.addCurve(to: point(701, 557), control1: point(744, 568), control2: point(723, 563))
        path.addCurve(to: point(605, 440), control1: point(654, 552), control2: point(623, 504))
        path.closeSubpath()
        return path
    }()

    private static let eyes: CGPath = {
        let path = CGMutablePath()
        func point(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x / 1254, y: y / 1254) }
        path.move(to: point(540, 349))
        path.addCurve(to: point(581, 282), control1: point(536, 319), control2: point(552, 291))
        path.addCurve(to: point(632, 279), control1: point(600, 272), control2: point(621, 270))
        path.addCurve(to: point(661, 342), control1: point(651, 294), control2: point(660, 314))
        path.addCurve(to: point(649, 393), control1: point(663, 364), control2: point(662, 388))
        path.addCurve(to: point(575, 395), control1: point(632, 410), control2: point(598, 406))
        path.addCurve(to: point(540, 349), control1: point(551, 384), control2: point(537, 372))
        path.closeSubpath()
        path.move(to: point(754, 292))
        path.addCurve(to: point(781, 246), control1: point(757, 270), control2: point(768, 248))
        path.addCurve(to: point(818, 242), control1: point(795, 238), control2: point(811, 236))
        path.addCurve(to: point(850, 300), control1: point(835, 259), control2: point(846, 276))
        path.addCurve(to: point(844, 347), control1: point(855, 320), control2: point(855, 340))
        path.addCurve(to: point(795, 354), control1: point(831, 363), control2: point(811, 357))
        path.addCurve(to: point(754, 292), control1: point(768, 343), control2: point(751, 318))
        path.closeSubpath()
        return path
    }()
}

/// Pose-independent coloring, shared with bitmap regression checks.
enum DinoSpriteColorRenderer {
    static func recolored(_ source: CGImage, appearance: DinoAppearance, asset: String) -> CGImage? {
        let width = min(768, source.width)
        let height = source.height * width / source.width
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let references = DinoAppearance.Part.allCases.map { HSL(hex: DinoAppearance.standard[$0]) }
        let targets = DinoAppearance.Part.allCases.map { HSL(hex: appearance[$0]) }
        let unchanged = DinoAppearance.Part.allCases.map { appearance[$0] == DinoAppearance.standard[$0] }
        let regions = DinoAvatarMask.spriteRegions(for: asset)
        let sourcePalette = palettes[asset] ?? idlePalette
        let success = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width * 4,
                                          space: colorSpace, bitmapInfo: bitmapInfo) else { return false }
            context.interpolationQuality = .high
            context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
            let bytes = buffer.bindMemory(to: UInt8.self)
            for y in 0..<height {
                if Task.isCancelled { return false }
                for x in 0..<width {
                    let index = (y * width + x) * 4
                    let alpha = Double(bytes[index + 3]) / 255
                    guard alpha > 0.01 else { continue }
                    let pixel = HSL(red: min(1, Double(bytes[index]) / 255 / alpha),
                                    green: min(1, Double(bytes[index + 1]) / 255 / alpha),
                                    blue: min(1, Double(bytes[index + 2]) / 255 / alpha))
                    guard let part = DinoAvatarMask.part(hue: pixel.hue, saturation: pixel.saturation,
                                          lightness: pixel.lightness,
                                          x: Double(x) / Double(width), y: Double(y) / Double(height), regions: regions) else { continue }
                    let partIndex: Int
                    switch part {
                    case .bandana: partIndex = 0
                    case .spikes: partIndex = 1
                    case .body: partIndex = 2
                    case .belly: partIndex = 3
                    }
                    let reference = references[partIndex], target = targets[partIndex]
                    let sourceTone = sourcePalette[partIndex], idleTone = idlePalette[partIndex]
                    let normalizedLightness = sourceTone.matchLightness(pixel.lightness, to: idleTone)
                    let normalizedSaturation = min(1, pixel.saturation * idleTone.saturation / sourceTone.saturation)
                    let replacement: (Double, Double, Double)
                    if unchanged[partIndex] {
                        // Even unchanged colors use the idle artwork's lighting.
                        replacement = HSL(hue: pixel.hue, saturation: normalizedSaturation,
                                          lightness: normalizedLightness).rgb
                    } else {
                        // Apply the chosen color only after removing the pose's
                        // exposure difference, retaining shadows and highlights.
                        let lightness = normalizedLightness <= reference.lightness
                            ? target.lightness * normalizedLightness / max(0.001, reference.lightness)
                            : target.lightness + (1 - target.lightness) * (normalizedLightness - reference.lightness) / max(0.001, 1 - reference.lightness)
                        let saturation = min(1, normalizedSaturation * target.saturation / max(0.001, reference.saturation))
                        replacement = HSL(hue: target.hue, saturation: saturation, lightness: lightness).rgb
                    }
                    bytes[index] = UInt8((min(1, max(0, replacement.0)) * alpha * 255).rounded())
                    bytes[index + 1] = UInt8((min(1, max(0, replacement.1)) * alpha * 255).rounded())
                    bytes[index + 2] = UInt8((min(1, max(0, replacement.2)) * alpha * 255).rounded())
                }
            }
            return true
        }
        guard success, let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                       bytesPerRow: width * 4, space: colorSpace,
                       bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo), provider: provider,
                       decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }

    private struct HSL {
        let hue: Double
        let saturation: Double
        let lightness: Double

        init(hue: Double, saturation: Double, lightness: Double) {
            self.hue = hue; self.saturation = saturation; self.lightness = lightness
        }
        init(hex: UInt32) {
            self.init(red: Double((hex >> 16) & 255) / 255,
                      green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255)
        }
        init(red: Double, green: Double, blue: Double) {
            let maximum = max(red, green, blue), minimum = min(red, green, blue)
            let delta = maximum - minimum
            lightness = (maximum + minimum) / 2
            saturation = delta < 0.00001 ? 0 : delta / (1 - abs(2 * lightness - 1))
            var h: Double = 0
            if delta > 0.00001 {
                if maximum == red { h = ((green - blue) / delta).truncatingRemainder(dividingBy: 6) }
                else if maximum == green { h = (blue - red) / delta + 2 }
                else { h = (red - green) / delta + 4 }
            }
            hue = (h / 6 + 1).truncatingRemainder(dividingBy: 1)
        }
        var rgb: (Double, Double, Double) {
            let c = (1 - abs(2 * lightness - 1)) * saturation
            let h = hue * 6
            let x = c * (1 - abs(h.truncatingRemainder(dividingBy: 2) - 1))
            let m = lightness - c / 2
            let channels: (Double, Double, Double)
            switch h {
            case ..<1: channels = (c, x, 0)
            case ..<2: channels = (x, c, 0)
            case ..<3: channels = (0, c, x)
            case ..<4: channels = (0, x, c)
            case ..<5: channels = (x, 0, c)
            default: channels = (c, 0, x)
            }
            return (channels.0 + m, channels.1 + m, channels.2 + m)
        }
    }

    // Measured from opaque masked PNG pixels in sRGB after unpremultiplying alpha,
    // in DinoAppearance.Part order. Some supplied poses have alpha 253, even inside
    // the character; treating their stored RGB as opaque skews light belly colors.
    // Matching the 10th, 50th and 90th percentiles retains each pose's texture
    // without letting a brighter illustration turn a chosen color pastel.
    private struct Tone {
        let shadows: Double
        let middle: Double
        let highlights: Double
        let saturation: Double

        init(_ shadows: Double, _ middle: Double, _ highlights: Double, _ saturation: Double) {
            self.shadows = shadows; self.middle = middle
            self.highlights = highlights; self.saturation = saturation
        }

        func matchLightness(_ value: Double, to target: Tone) -> Double {
            if value <= shadows { return value * target.shadows / shadows }
            if value <= middle {
                return target.shadows + (value - shadows) * (target.middle - target.shadows) / (middle - shadows)
            }
            if value <= highlights {
                return target.middle + (value - middle) * (target.highlights - target.middle) / (highlights - middle)
            }
            return target.highlights + (value - highlights) * (1 - target.highlights) / (1 - highlights)
        }
    }

    private static let idlePalette = [
        Tone(0.26275, 0.48039, 0.59020, 0.86486), Tone(0.09804, 0.19608, 0.36471, 0.54348),
        Tone(0.23333, 0.37255, 0.50980, 0.67539), Tone(0.55098, 0.79020, 0.88431, 0.71429)
    ]
    private static let palettes: [String: [Tone]] = [
        "dino-thumbs-up-08": [Tone(0.24111, 0.48221, 0.54150, 0.96154), Tone(0.08103, 0.15538, 0.30237, 0.65432),
                              Tone(0.22925, 0.37154, 0.49802, 0.69143), Tone(0.57341, 0.80237, 0.88538, 0.74737)],
        "dino-wrong-answer-04": [Tone(0.23518, 0.52569, 0.58367, 0.93886), Tone(0.09881, 0.17857, 0.33399, 0.50617),
                              Tone(0.26285, 0.43281, 0.55138, 0.55372), Tone(0.59881, 0.82540, 0.90316, 0.69620)],
        "dino-backflip-01": [Tone(0.27470, 0.49405, 0.57510, 0.91379), Tone(0.09881, 0.17787, 0.37698, 0.58824),
                              Tone(0.24008, 0.39328, 0.52569, 0.64286), Tone(0.56719, 0.76482, 0.86811, 0.61739)],
        "dino-backflip-03": [Tone(0.27470, 0.46627, 0.58300, 0.91919), Tone(0.08167, 0.16733, 0.31621, 0.53191),
                              Tone(0.26285, 0.39526, 0.55138, 0.63359), Tone(0.56324, 0.70751, 0.89723, 0.52866)],
        "dino-backflip-07": [Tone(0.26087, 0.50000, 0.57708, 0.93249), Tone(0.11660, 0.21765, 0.41304, 0.56098),
                              Tone(0.23913, 0.40119, 0.53557, 0.65487), Tone(0.54941, 0.75889, 0.87945, 0.65574)],
        "dino-backflip-08": [Tone(0.25494, 0.48024, 0.56471, 0.90698), Tone(0.08929, 0.17729, 0.37352, 0.59259),
                              Tone(0.23518, 0.36759, 0.49012, 0.67045), Tone(0.55336, 0.79249, 0.87795, 0.74074)],
    ]
}
