import CoreGraphics
import Foundation

enum DinoAnswerArtwork {
    static let wrongAssets = ["27-1", "28-2", "29-3", "30-4", "31-5", "32-6", "33-7", "33-8"]
        .map { "ChatGPT-afbeelding 24 okt 2026, 21_14_\($0)" }
    static let correctAssets = ["42-1", "44-2", "44-3", "45-4", "46-5", "46-6", "47-7", "48-8"]
        .map { "ChatGPT-afbeelding 24 okt 2026, 21_15_\($0)" }
}

/// Color regions follow the original illustration, including bright spike highlights.
enum DinoAvatarMask {
    /// The unchanged idle head, following the jaw while excluding both fists.
    static let standingHead: CGPath = {
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 1, y: 0))
        path.addLine(to: CGPoint(x: 1, y: 0.415))
        path.addLine(to: CGPoint(x: 0.72, y: 0.415))
        path.addCurve(to: CGPoint(x: 0.573, y: 0.469), control1: CGPoint(x: 0.650, y: 0.452), control2: CGPoint(x: 0.625, y: 0.469))
        path.addCurve(to: CGPoint(x: 0.438, y: 0.440), control1: CGPoint(x: 0.519, y: 0.468), control2: CGPoint(x: 0.473, y: 0.449))
        path.addCurve(to: CGPoint(x: 0.425, y: 0.449), control1: CGPoint(x: 0.432, y: 0.445), control2: CGPoint(x: 0.429, y: 0.449))
        path.addLine(to: CGPoint(x: 0, y: 0.449))
        path.closeSubpath()
        return path
    }()

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
        var tailLeft = 1.0
        var tailBottom = 0.0
        let upperSpikes: CGPath
        let eyes: CGPath
        let mouth: CGPath
        var protectsFaceBeforeCloth = false
        var decorations: CGPath? = nil

        func part(hue: Double, saturation: Double, lightness: Double, x: Double, y: Double) -> DinoAppearance.Part? {
            guard saturation > 0.08 else { return nil }
            let point = CGPoint(x: x, y: y)
            if (0.075..<0.18).contains(hue), decorations?.contains(point) == true { return nil }
            if protectsFaceBeforeCloth, hue < 0.18 || hue > 0.95,
               eyes.contains(point) || (lightness < 0.60 && mouth.contains(point)) { return nil }
            if hue < 0.055 || hue > 0.95 {
                return y < bandanaBottom || ((x < tailRight || x > tailLeft) && y < tailBottom) ? .bandana : nil
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

    static func spriteRegions(for asset: String) -> SpriteRegions? {
        deepFallPoses[asset] ?? stumblePoses[asset] ?? applausePoses[asset] ?? answerPoses[asset] ?? openingPoses[asset] ?? poses[asset]
    }

    /// The face moves down toward the hands; protect its eyes and tongue in
    /// every drawing instead of applying the standing portrait's cloth mask.
    private static let stumblePoses: [String: SpriteRegions] = {
        let eyes: [[(Double, Double, Double, Double)]] = [
            [(532, 286, 138, 138), (752, 243, 110, 124)],
            [(696, 391, 148, 142), (929, 366, 110, 136)],
            [(695, 505, 150, 143), (936, 451, 116, 141)],
            [(714, 640, 162, 169), (965, 694, 134, 159)],
            [(750, 583, 142, 142), (973, 531, 116, 137)],
            [(698, 441, 142, 138), (923, 407, 114, 132)],
            [(532, 286, 138, 138), (752, 243, 110, 124)],
            [(532, 286, 138, 138), (752, 243, 110, 124)]
        ]
        let mouths: [(Double, Double, Double, Double)] = [
            (594, 455, 250, 171), (699, 607, 246, 137), (661, 702, 251, 154),
            (677, 819, 219, 161), (732, 746, 260, 130), (744, 589, 233, 152),
            (594, 455, 250, 171), (594, 455, 250, 171)
        ]
        let spikeBounds: [(Double, Double, Double, Double)] = [
            (406, 12, 252, 223), (553, 53, 260, 250), (578, 181, 252, 220),
            (681, 323, 331, 149), (655, 273, 296, 197), (587, 127, 268, 211),
            (406, 12, 252, 223), (406, 12, 252, 223)
        ]
        let cloth = [0.35, 0.43, 0.52, 0.55, 0.56, 0.41, 0.35, 0.35]
        var poses = Dictionary(uniqueKeysWithValues: (0..<8).map { index in
            (String(format: "dino-stumble-%02d", index + 1),
             SpriteRegions(bandanaBottom: cloth[index], tailRight: 0.52,
                           tailBottom: cloth[index] + 0.015,
                           upperSpikes: eyeContours([spikeBounds[index]]),
                           eyes: eyeContours(eyes[index]), mouth: eyeContours([mouths[index]]),
                           protectsFaceBeforeCloth: true))
        })
        poses["dino-stumble-06a"] = SpriteRegions(bandanaBottom: 0.40, tailRight: 0.52, tailBottom: 0.41,
            upperSpikes: eyeContours([(587, 107, 283, 225)]),
            eyes: eyeContours([(715, 430, 140, 140), (947, 393, 110, 137)]),
            mouth: eyeContours([(766, 571, 232, 151)]), protectsFaceBeforeCloth: true)
        poses["dino-stumble-06b"] = SpriteRegions(bandanaBottom: 0.35, tailRight: 0.44, tailBottom: 0.39,
            upperSpikes: eyeContours([(486, 43, 288, 222)]),
            eyes: eyeContours([(642, 328, 142, 140), (870, 283, 114, 137)]),
            mouth: eyeContours([(708, 491, 226, 136)]), protectsFaceBeforeCloth: true)
        return poses
    }()

    /// The deeper fall reaches the muzzle and belly. Its head, mouth and
    /// cloth travel much farther than the old hand-supported landing.
    private static let deepFallPoses: [String: SpriteRegions] = {
        let names = ["01", "02", "03", "03a", "04", "05", "06", "06a", "07", "08"]
        let eyes: [[(Double, Double, Double, Double)]] = [
            [(527,280,145,145),(750,238,115,128)],
            [(666,367,155,175),(908,388,120,171)],
            [(681,413,171,172),(932,427,126,172)],
            [(764,688,174,181),(1012,724,130,177)],
            [(722,767,165,178),(956,804,123,172)],
            [(741,730,170,149),(999,786,116,159)],
            [(674,431,177,160),(940,421,170,181)],
            [(638,389,167,150),(890,348,133,172)],
            [(528,277,145,142),(749,236,116,128)],
            [(526,280,145,142),(748,237,116,129)]
        ]
        let mouths: [(Double, Double, Double, Double)] = [
            (594,455,250,160),(646,572,230,170),(676,611,254,190),
            (732,854,265,205),(680,950,212,145),(746,955,250,184),
            (693,580,326,217),(680,560,325,150),(590,450,260,155),(590,450,260,160)
        ]
        let spikes: [(Double, Double, Double, Double)] = [
            (407,15,270,220),(575,65,300,220),(610,108,300,225),
            (680,325,350,245),(681,411,330,218),(730,403,350,207),
            (577,33,330,239),(500,40,350,230),(408,8,275,225),(406,14,275,225)
        ]
        let cloth = [0.35,0.36,0.40,0.57,0.63,0.62,0.41,0.40,0.35,0.35]
        let stars = eyeContours([(645,285,560,260)])
        return Dictionary(uniqueKeysWithValues: names.indices.map { i in
            ("dino-stumble-deep-" + names[i],
             SpriteRegions(bandanaBottom: cloth[i], tailRight: 0.60, tailBottom: cloth[i] + 0.04,
                           upperSpikes: eyeContours([spikes[i]]), eyes: eyeContours(eyes[i]),
                           mouth: eyeContours([mouths[i]]), protectsFaceBeforeCloth: true,
                           decorations: names[i] == "05" ? stars : nil))
        })
    }()

    /// Keep the clapping accents gold and protect the eyes and mouth in all eight drawings.
    private static let applausePoses: [String: SpriteRegions] = {
        let accents: [[CGRect]] = [
            [],
            [CGRect(x: 943, y: 444, width: 82, height: 104), CGRect(x: 973, y: 536, width: 87, height: 59)],
            [CGRect(x: 843, y: 552, width: 72, height: 88), CGRect(x: 864, y: 632, width: 80, height: 53),
             CGRect(x: 863, y: 703, width: 62, height: 56), CGRect(x: 463, y: 614, width: 76, height: 73),
             CGRect(x: 455, y: 701, width: 75, height: 52)],
            [CGRect(x: 926, y: 516, width: 82, height: 93), CGRect(x: 949, y: 623, width: 74, height: 56)],
            [CGRect(x: 924, y: 468, width: 82, height: 99), CGRect(x: 952, y: 559, width: 85, height: 55)],
            [CGRect(x: 888, y: 490, width: 86, height: 97), CGRect(x: 909, y: 586, width: 86, height: 57),
             CGRect(x: 496, y: 594, width: 79, height: 71), CGRect(x: 493, y: 683, width: 73, height: 55)],
            [CGRect(x: 923, y: 475, width: 78, height: 97), CGRect(x: 953, y: 565, width: 79, height: 55)],
            []
        ]
        return Dictionary(uniqueKeysWithValues: (1...8).map { frame in
            let atRest = frame == 1 || frame == 8
            var shift = CGAffineTransform(translationX: -45.0 / 1254, y: -5.0 / 1254)
            let decorations = CGMutablePath()
            for rect in accents[frame - 1] {
                decorations.addRect(rect.applying(CGAffineTransform(scaleX: 1 / 1254, y: 1 / 1254)))
            }
            let regions = SpriteRegions(bandanaBottom: 0.34, tailRight: 0.32, tailBottom: 0.41,
                upperSpikes: atRest ? upperSpikes : upperSpikes.copy(using: &shift) ?? upperSpikes,
                eyes: atRest ? eyes : frame < 5 ? eyeContours([(488, 300, 153, 151), (721, 247, 129, 143)]) : CGMutablePath(),
                mouth: atRest ? mouthInterior : eyeContours([(560, 465, 260, 155)]),
                protectsFaceBeforeCloth: true, decorations: decorations)
            return (String(format: "dino_applaus_frame_%02d", frame), regions)
        })
    }()

    /// Trace the moving face in the new answer drawings, including the dizzy
    /// eyes and tilted mouth. Their gold stars retain their painted color.
    private static let answerPoses: [String: SpriteRegions] = {
        let eyes: [[(Double, Double, Double, Double)]] = [
            [(534, 286, 134, 132), (758, 242, 102, 120)],
            [(566, 302, 110, 130), (770, 250, 102, 112)],
            [(534, 322, 114, 126), (746, 238, 118, 112)],
            [(578, 342, 134, 136), (766, 250, 134, 116)],
            [(610, 286, 134, 132), (854, 354, 102, 136)],
            [(534, 302, 138, 116), (762, 258, 106, 120)],
            [(518, 286, 134, 128), (750, 250, 102, 124)],
            [(534, 286, 134, 132), (758, 242, 102, 120)],
            [(534, 286, 134, 132), (758, 242, 102, 120)],
            [(578, 310, 138, 132), (814, 266, 102, 124)],
            [(518, 278, 138, 132), (738, 214, 106, 116)],
            [(530, 274, 134, 128), (730, 198, 106, 116)],
            [(530, 282, 138, 128), (750, 222, 106, 112)],
            [(538, 286, 138, 132), (766, 246, 102, 116)],
            [(534, 286, 134, 132), (758, 242, 102, 120)],
            [(534, 286, 134, 132), (758, 242, 102, 120)]
        ]
        let mouths: [(Double, Double, Double, Double)] = [
            (602, 456, 235, 122), (624, 462, 222, 107), (626, 492, 225, 75),
            (698, 480, 204, 122), (630, 436, 220, 145), (604, 458, 234, 112),
            (590, 450, 238, 112), (602, 456, 235, 122),
            (602, 456, 235, 122), (644, 478, 235, 136), (602, 444, 242, 128),
            (635, 410, 232, 159), (610, 440, 242, 145), (612, 454, 235, 126),
            (602, 456, 235, 122), (602, 456, 235, 122)
        ]
        let shifts: [(Double, Double)] = [
            (0, 0), (14, 0), (0, 25), (60, 65), (70, -5), (0, 0), (-10, 0), (0, 0),
            (0, 0), (42, 10), (-10, -12), (0, -15), (0, -10), (0, 0), (0, 0), (0, 0)
        ]
        let cloth = [0.35, 0.36, 0.38, 0.46, 0.34, 0.36, 0.35, 0.35,
                     0.35, 0.37, 0.36, 0.36, 0.36, 0.35, 0.35, 0.35]
        let stars = CGMutablePath()
        for rect in [CGRect(x: 300, y: 45, width: 300, height: 285),
                     CGRect(x: 600, y: 0, width: 140, height: 120),
                     CGRect(x: 845, y: 130, width: 265, height: 235)] {
            stars.addRect(rect.applying(CGAffineTransform(scaleX: 1 / 1254, y: 1 / 1254)))
        }
        return Dictionary(uniqueKeysWithValues: (DinoAnswerArtwork.wrongAssets + DinoAnswerArtwork.correctAssets).enumerated().map { index, asset in
            var shift = CGAffineTransform(translationX: shifts[index].0 / 1254, y: shifts[index].1 / 1254)
            return (asset, SpriteRegions(bandanaBottom: cloth[index],
                upperSpikes: upperSpikes.copy(using: &shift) ?? upperSpikes,
                eyes: eyeContours(eyes[index]), mouth: eyeContours([mouths[index]]), protectsFaceBeforeCloth: true,
                decorations: index == 3 ? stars : nil))
        })
    }()

    private static let openingPoses: [String: SpriteRegions] = {
        let eyes: [[(Double, Double, Double, Double)]] = [
            [(532, 286, 135, 135), (752, 243, 108, 121)],
            [(657, 477, 138, 136), (897, 458, 104, 130)],
            [(519, 262, 135, 130), (730, 209, 110, 108)],
            [(532, 281, 136, 133), (752, 236, 108, 122)],
            [(531, 269, 137, 130), (746, 215, 112, 113)],
            [(565, 341, 134, 130), (788, 306, 105, 124)],
            [(557, 393, 142, 140), (793, 356, 111, 129)],
            [(532, 286, 135, 135), (752, 243, 108, 121)]
        ]
        let mouths: [(Double, Double, Double, Double)] = [
            (596, 457, 245, 165), (719, 650, 250, 145), (588, 423, 240, 158),
            (594, 447, 250, 171), (602, 425, 245, 170), (622, 512, 248, 158),
            (620, 575, 268, 173), (594, 457, 248, 173)
        ]
        let shifts: [(Double, Double)] = [(0, 4), (165, 164), (-10, -6), (0, 0), (0, 0), (46, 49), (46, 79), (0, 4)]
        let cloth = [0.35, 0.47, 0.34, 0.35, 0.35, 0.40, 0.44, 0.35]
        return Dictionary(uniqueKeysWithValues: (0..<8).map { index in
            var shift = CGAffineTransform(translationX: shifts[index].0 / 1254, y: shifts[index].1 / 1254)
            let regions = SpriteRegions(bandanaBottom: cloth[index],
                upperSpikes: upperSpikes.copy(using: &shift) ?? upperSpikes,
                eyes: eyeContours(eyes[index]), mouth: eyeContours([mouths[index]]), protectsFaceBeforeCloth: true)
            return (String(format: "dino-opening-jump-%02d", index + 1), regions)
        })
    }()

    /// Coordinates trace each animation illustration in a 1254 × 1254 reference space.
    private static let poses: [String: SpriteRegions] = [
        "dino-world-jump-01": SpriteRegions(
            bandanaBottom: 0.34,
            upperSpikes: contours([[.move(504, 150), .line(501, 16), .line(569, 16), .line(656, 106), .line(600, 126)],
                                   [.move(423, 218), .line(413, 116), .line(494, 110), .line(528, 159)]]),
            eyes: eyeContours([(532, 273, 142, 156), (743, 225, 124, 149)]),
            mouth: eyeContours([(603, 446, 219, 140)])),
        "dino-world-jump-02": SpriteRegions(
            bandanaBottom: 0.36,
            upperSpikes: contours([[.move(650, 239), .line(659, 135), .line(728, 132), .line(821, 251)],
                                   [.move(573, 283), .line(564, 192), .line(625, 188), .line(668, 256)]]),
            eyes: eyeContours([(636, 432, 149, 148), (862, 448, 112, 144)]),
            mouth: eyeContours([(661, 624, 210, 149)])),
        "dino-world-jump-03": SpriteRegions(
            bandanaBottom: 0.34,
            upperSpikes: contours([[.move(728, 210), .line(753, 80), .line(825, 89), .line(890, 219)],
                                   [.move(657, 235), .line(664, 110), .line(739, 92), .line(771, 194)]]),
            eyes: eyeContours([(659, 375, 147, 140), (881, 418, 119, 144)]),
            mouth: eyeContours([(641, 540, 163, 167)])),
        "dino-world-jump-06": SpriteRegions(
            bandanaBottom: 0.35,
            upperSpikes: contours([[.move(650, 227), .line(665, 90), .line(738, 98), .line(818, 233)],
                                   [.move(560, 285), .line(548, 151), .line(609, 142), .line(667, 234)]]),
            eyes: eyeContours([(600, 396, 142, 149), (805, 411, 122, 150)]),
            mouth: eyeContours([(638, 586, 201, 134)])),
        "dino-world-jump-07": SpriteRegions(
            bandanaBottom: 0.40,
            upperSpikes: contours([[.move(648, 263), .line(648, 147), .line(719, 153), .line(794, 273)],
                                   [.move(557, 300), .line(548, 207), .line(613, 194), .line(659, 263)]]),
            eyes: eyeContours([(608, 483, 145, 147), (838, 458, 114, 150)]),
            mouth: eyeContours([(664, 673, 165, 119)])),
        "dino-pirouette-01": SpriteRegions(
            bandanaBottom: 0.39,
            upperSpikes: contours([
                [.move(548, 182), .curve(576, 67, 532, 112, 543, 57), .curve(704, 131, 618, 61, 674, 103), .curve(548, 182, 643, 145, 594, 162)],
                [.move(460, 255), .curve(463, 157, 442, 222, 439, 178), .curve(555, 169, 489, 141, 524, 149), .curve(460, 255, 524, 191, 493, 227)]
            ]),
            eyes: eyeContours([(564, 357, 130, 135), (800, 320, 99, 134)]),
            mouth: contours([[.move(620, 538), .curve(797, 584, 663, 578, 742, 593), .curve(901, 548, 839, 578, 880, 564),
                              .curve(810, 660, 887, 598, 852, 647), .curve(735, 668, 789, 679, 752, 679), .curve(620, 538, 679, 645, 648, 587)]])),
        "dino-pirouette-02": SpriteRegions(
            bandanaBottom: 0.41,
            upperSpikes: contours([
                [.move(607, 218), .curve(648, 80, 599, 141, 610, 68), .curve(777, 170, 693, 71, 751, 123), .curve(607, 218, 712, 185, 657, 203)],
                [.move(505, 310), .curve(510, 167, 474, 236, 473, 167), .curve(615, 191, 542, 145, 583, 165), .curve(505, 310, 575, 232, 535, 274)]
            ]),
            eyes: eyeContours([(677, 399, 130, 128), (920, 365, 87, 122)]),
            mouth: contours([[.move(745, 577), .curve(899, 638, 785, 621, 849, 638), .curve(971, 608, 934, 636, 956, 619),
                              .curve(886, 712, 946, 657, 923, 699), .curve(827, 716, 864, 729, 842, 727), .curve(745, 577, 778, 685, 762, 629)]])),
        "dino-pirouette-03": SpriteRegions(
            bandanaBottom: 0.35, tailRight: 0.43, tailBottom: 0.40,
            upperSpikes: contours([
                [.move(575, 190), .curve(599, 65, 561, 122, 570, 54), .curve(739, 135, 640, 54, 711, 94), .curve(575, 190, 678, 148, 620, 174)],
                [.move(490, 283), .curve(489, 156, 455, 224, 455, 153), .curve(585, 180, 521, 133, 560, 151), .curve(490, 283, 544, 214, 517, 251)]
            ]),
            eyes: eyeContours([(673, 341, 120, 124), (877, 307, 66, 110)]),
            mouth: contours([[.move(734, 505), .curve(888, 540, 776, 536, 837, 544), .curve(976, 511, 932, 539, 958, 522),
                              .curve(887, 604, 952, 553, 923, 591), .curve(823, 607, 864, 620, 839, 615), .curve(734, 505, 775, 584, 753, 542)]])),
        "dino-pirouette-04": SpriteRegions(
            bandanaBottom: 0.34, tailRight: 0.43, tailBottom: 0.39,
            upperSpikes: contours([[.move(604, 164), .curve(617, 58, 578, 104, 581, 53), .curve(752, 130, 659, 50, 719, 92), .curve(604, 164, 700, 139, 651, 148)], [.move(532, 280), .curve(516, 139, 483, 202, 466, 142), .curve(615, 164, 551, 118, 590, 140), .curve(532, 280, 580, 196, 552, 240)]]),
            eyes: eyeContours([(697, 300, 118, 122), (872, 266, 62, 100)]),
            mouth: contours([[.move(767, 450), .curve(907, 485, 804, 480, 862, 490), .curve(947, 469, 926, 482, 937, 474), .curve(881, 548, 936, 508, 915, 538), .curve(827, 550, 859, 563, 844, 560), .curve(767, 450, 792, 524, 779, 484)]])),
        "dino-pirouette-05": SpriteRegions(
            bandanaBottom: 0.32, tailRight: 0.45, tailBottom: 0.36,
            upperSpikes: contours([[.move(580, 161), .curve(585, 45, 552, 101, 551, 41), .curve(733, 130, 635, 36, 694, 93), .curve(580, 161, 675, 142, 626, 150)], [.move(512, 252), .curve(518, 128, 476, 181, 477, 131), .curve(592, 159, 548, 109, 575, 132), .curve(512, 252, 562, 195, 531, 226)]]),
            eyes: eyeContours([(794, 239, 86, 128)]),
            mouth: contours([[.move(838, 415), .curve(919, 433, 859, 429, 896, 435), .curve(945, 419, 931, 429, 940, 422), .curve(906, 502, 940, 456, 924, 491), .curve(884, 520, 901, 515, 892, 526), .curve(838, 415, 853, 496, 848, 450)]])),
        "dino-pirouette-06": SpriteRegions(
            bandanaBottom: 0.35, tailRight: 0.45, tailBottom: 0.37,
            upperSpikes: contours([[.move(637, 135), .curve(647, 26, 610, 74, 613, 20), .curve(780, 105, 693, 21, 748, 73), .curve(637, 135, 721, 111, 678, 121)], [.move(557, 241), .curve(556, 101, 517, 167, 511, 109), .curve(646, 135, 585, 80, 620, 104), .curve(557, 241, 615, 174, 580, 210)]]),
            eyes: eyeContours([(813, 265, 84, 125)]),
            mouth: contours([[.move(860, 430), .curve(933, 447, 879, 445, 913, 451), .curve(951, 434, 945, 444, 950, 438), .curve(928, 500, 950, 460, 942, 485), .curve(906, 526, 922, 521, 915, 531), .curve(860, 430, 880, 506, 868, 468)]])),
        "dino-pirouette-06a": SpriteRegions(
            bandanaBottom: 0.36, tailRight: 0.45, tailBottom: 0.40,
            upperSpikes: contours([
                [.move(614, 144), .line(616, 31), .line(683, 31), .line(763, 119), .line(692, 158)],
                [.move(554, 241), .line(513, 168), .line(519, 103), .line(571, 103), .line(638, 165)]
            ]),
            eyes: eyeContours([(902, 277, 25, 77)]), mouth: contours([])),
        "dino-pirouette-07": SpriteRegions(
            bandanaBottom: 0.40,
            upperSpikes: contours([[.move(578, 165), .curve(628, 50, 578, 104, 601, 38), .curve(712, 151, 674, 42, 703, 111), .curve(578, 165, 660, 167, 618, 167)], [.move(616, 258), .curve(641, 137, 591, 209, 602, 143), .curve(735, 238, 681, 126, 729, 183), .curve(616, 258, 692, 257, 656, 260)]]),
            eyes: eyeContours([]),
            mouth: contours([])),
        "dino-pirouette-07a": SpriteRegions(
            bandanaBottom: 0.40,
            upperSpikes: contours([
                [.move(561, 171), .line(580, 90), .line(628, 48), .line(687, 74), .line(712, 168)],
                [.move(610, 267), .line(604, 179), .line(649, 139), .line(712, 167), .line(738, 253)]
            ]), eyes: eyeContours([]), mouth: contours([])),
        "dino-pirouette-08": SpriteRegions(
            bandanaBottom: 0.40,
            upperSpikes: contours([[.move(554, 160), .curve(634, 48, 561, 94, 598, 27), .curve(712, 184, 693, 26, 728, 103), .curve(554, 160, 648, 186, 599, 171)], [.move(639, 271), .curve(655, 153, 608, 212, 613, 153), .curve(741, 262, 701, 140, 743, 205), .curve(639, 271, 712, 286, 673, 290)]]),
            eyes: eyeContours([]),
            mouth: contours([])),
        "dino-pirouette-08a": SpriteRegions(
            bandanaBottom: 0.30, tailLeft: 0.55, tailBottom: 0.40,
            upperSpikes: contours([
                [.move(491, 145), .line(538, 77), .line(609, 53), .line(684, 75), .line(679, 177), .line(634, 201)],
                [.move(624, 178), .line(696, 144), .line(754, 159), .line(794, 223), .line(774, 278), .line(704, 251)]
            ]), eyes: eyeContours([(391, 297, 50, 103)]),
            mouth: eyeContours([(362, 435, 60, 95)])),
        "dino-pirouette-09": SpriteRegions(
            bandanaBottom: 0.30, tailLeft: 0.56, tailBottom: 0.40,
            upperSpikes: contours([[.move(514, 140), .curve(607, 49, 533, 79, 565, 28), .curve(662, 183, 660, 28, 673, 112), .curve(514, 140, 605, 160, 559, 146)], [.move(640, 168), .curve(743, 114, 672, 118, 712, 100), .curve(764, 266, 788, 134, 789, 212), .curve(640, 168, 723, 218, 685, 187)]]),
            eyes: eyeContours([(327, 278, 48, 96), (415, 272, 101, 125)]),
            mouth: contours([[.move(346, 459), .curve(476, 431, 386, 461, 445, 447), .curve(447, 502, 465, 463, 457, 487), .curve(398, 539, 436, 523, 420, 544), .curve(365, 520, 380, 540, 371, 529), .curve(346, 459, 351, 500, 348, 478)]])),
        "dino-pirouette-10": SpriteRegions(
            bandanaBottom: 0.28, tailLeft: 0.55, tailBottom: 0.40,
            upperSpikes: contours([[.move(525, 130), .curve(623, 47, 547, 74, 584, 27), .curve(680, 174, 677, 28, 690, 100), .curve(525, 130, 616, 148, 570, 135)], [.move(648, 178), .curve(758, 132, 683, 125, 729, 116), .curve(781, 269, 802, 152, 805, 207), .curve(648, 178, 735, 222, 697, 198)]]),
            eyes: eyeContours([(332, 251, 65, 98), (438, 284, 120, 123)]),
            mouth: contours([[.move(310, 462), .curve(471, 438, 355, 470, 431, 458), .curve(444, 510, 460, 474, 450, 497), .curve(386, 545, 429, 534, 407, 550), .curve(343, 528, 365, 546, 352, 539), .curve(310, 462, 324, 512, 316, 486)]])),
        "dino-pirouette-10a": SpriteRegions(
            bandanaBottom: 0.37, tailLeft: 0.64, tailBottom: 0.41,
            upperSpikes: contours([
                [.move(554, 185), .line(576, 115), .line(644, 75), .line(701, 92), .line(728, 190)],
                [.move(686, 202), .line(744, 157), .line(801, 161), .line(840, 230), .line(807, 297)]
            ]), eyes: eyeContours([(388, 326, 84, 118), (536, 366, 114, 135)]),
            mouth: contours([[.move(410, 543), .curve(609, 520, 473, 566, 549, 551),
                              .curve(566, 623, 640, 549, 604, 594), .curve(482, 650, 536, 645, 505, 658),
                              .curve(410, 543, 451, 626, 425, 581)]])),
        "dino-pirouette-11": SpriteRegions(
            bandanaBottom: 0.36, tailLeft: 0.63, tailBottom: 0.40,
            upperSpikes: contours([[.move(559, 215), .curve(653, 94, 569, 147, 611, 73), .curve(711, 238, 707, 69, 728, 172), .curve(559, 215, 659, 226, 609, 211)], [.move(687, 222), .curve(790, 177, 723, 166, 759, 154), .curve(806, 326, 843, 200, 827, 270), .curve(687, 222, 765, 283, 726, 248)]]),
            eyes: eyeContours([(393, 335, 87, 116), (573, 368, 104, 130)]),
            mouth: contours([[.move(415, 537), .curve(604, 521, 466, 553, 549, 546), .curve(635, 537, 627, 524, 638, 530), .curve(551, 610, 616, 569, 581, 600), .curve(487, 622, 529, 628, 505, 630), .curve(415, 537, 442, 600, 426, 562)]])),
        "dino-pirouette-12": SpriteRegions(
            bandanaBottom: 0.36,
            upperSpikes: contours([
                [.move(580, 150), .curve(616, 32, 578, 84, 584, 22), .curve(734, 125, 665, 23, 710, 76), .curve(580, 150, 675, 134, 625, 140)],
                [.move(495, 225), .curve(502, 122, 475, 175, 482, 133), .curve(589, 143, 532, 107, 566, 124), .curve(495, 225, 555, 164, 524, 201)]
            ]),
            eyes: eyeContours([(529, 333, 122, 125), (762, 314, 110, 123)]),
            mouth: contours([[.move(566, 502), .curve(695, 565, 604, 548, 648, 565), .curve(857, 498, 775, 565, 825, 540),
                              .curve(757, 630, 831, 578, 798, 618), .curve(695, 638, 738, 644, 716, 645), .curve(566, 502, 625, 611, 594, 555)]])),
        "dino-pirouette-13": SpriteRegions(
            bandanaBottom: 0.34,
            upperSpikes: contours([
                [.move(516, 147), .curve(534, 27, 501, 81, 501, 15), .curve(652, 94, 575, 20, 624, 57), .curve(516, 147, 605, 107, 558, 127)],
                [.move(433, 232), .curve(440, 120, 405, 178, 409, 132), .curve(525, 137, 466, 103, 501, 118), .curve(433, 232, 491, 173, 462, 208)]
            ]),
            eyes: eyeContours([(548, 296, 124, 126), (769, 262, 91, 111)]),
            mouth: contours([[.move(604, 454), .curve(757, 507, 646, 498, 704, 510), .curve(847, 487, 803, 509, 828, 498),
                              .curve(772, 568, 826, 530, 806, 556), .curve(709, 578, 750, 587, 728, 585), .curve(604, 454, 655, 560, 627, 510)]])),
        "dino-pirouette-14": SpriteRegions(
            bandanaBottom: 0.37,
            upperSpikes: contours([
                [.move(531, 158), .curve(551, 22, 510, 91, 516, 17), .curve(688, 96, 595, 16, 654, 58), .curve(531, 158, 637, 115, 581, 138)],
                [.move(445, 239), .curve(454, 120, 416, 180, 423, 128), .curve(543, 139, 481, 101, 516, 116), .curve(445, 239, 509, 170, 476, 205)]
            ]),
            eyes: eyeContours([(537, 298, 131, 139), (762, 268, 99, 133)]),
            mouth: contours([[.move(596, 480), .curve(758, 529, 640, 520, 704, 533), .curve(869, 493, 807, 526, 847, 506),
                              .curve(786, 613, 857, 550, 826, 597), .curve(722, 627, 767, 634, 741, 636), .curve(596, 480, 658, 603, 622, 536)]])),
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
        case line(Double, Double)
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
                case let .line(x, y): path.addLine(to: point(x, y))
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
    enum Resolution: String { case standard, original }

    /// The supplied head moves independently of the hands. Remove that head
    /// before caching the moving layer; DinoCharacter draws the exact idle head above it.
    static func applauseBody(_ colored: CGImage, original: CGImage, asset: String) -> CGImage? {
        guard asset.hasPrefix("dino_applaus_frame_"), !asset.hasSuffix("_01"), !asset.hasSuffix("_08") else { return colored }
        let width = colored.width, height = colored.height
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        var source = [UInt8](repeating: 0, count: width * height * 4)
        source.withUnsafeMutableBytes { buffer in
            let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: colorSpace, bitmapInfo: bitmapInfo)!
            context.interpolationQuality = .high
            context.draw(original, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        var pixels = [UInt8](colored.dataProvider!.data! as Data)
        let accents = DinoAvatarMask.spriteRegions(for: asset)?.decorations
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                let px = Double(x) / Double(width), py = Double(y) / Double(height)
                let r = Double(source[i]), g = Double(source[i + 1]), b = Double(source[i + 2])
                // Keep complete fingertips above the chin without retaining the
                // cream jaw or red mouth. Classify original green before recoloring.
                let fingers = py >= 550.0 / 1254 && (550.0 / 1254...950.0 / 1254).contains(px)
                    && g > r * 1.03 && g > b * 1.1
                if py >= 650.0 / 1254 || fingers || accents?.contains(CGPoint(x: px, y: py)) == true { continue }
                pixels[i] = 0; pixels[i + 1] = 0; pixels[i + 2] = 0; pixels[i + 3] = 0
            }
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                       bytesPerRow: width * 4, space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                       provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }

    static func recolored(_ source: CGImage, appearance: DinoAppearance, asset: String,
                          resolution: Resolution = .standard) -> CGImage? {
        let width = resolution == .original ? source.width : min(768, source.width)
        let height = source.height * width / source.width
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let references = DinoAppearance.Part.allCases.map { HSL(hex: DinoAppearance.standard[$0]) }
        let targets = DinoAppearance.Part.allCases.map { HSL(hex: appearance[$0]) }
        let unchanged = DinoAppearance.Part.allCases.map { appearance[$0] == DinoAppearance.standard[$0] }
        let regions = DinoAvatarMask.spriteRegions(for: asset)
        let sourcePalette = answerPalettes[asset] ?? palettes[asset] ?? idlePalette
        let letteringBounds = appearance.usesBlackBandanaLettering ? (deepFallLetteringBounds[asset] ?? answerLetteringBounds[asset] ?? bandanaLetteringBounds[asset]) : nil
        let letteringInk = HSL(hex: appearance.bandanaLetteringHex).rgb
        let success = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width * 4,
                                          space: colorSpace, bitmapInfo: bitmapInfo) else { return false }
            context.interpolationQuality = .high
            context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
            let bytes = buffer.bindMemory(to: UInt8.self)
            // Calibrate the actual display raster, not a smaller test thumbnail.
            // The fall drawings differ in hue as well as exposure and saturation.
            let fallPalette = asset.hasPrefix("dino-stumble-")
                ? measuredFallPalette(bytes, width: width, height: height, asset: asset, regions: regions) : nil
            for y in 0..<height {
                if Task.isCancelled { return false }
                for x in 0..<width {
                    let index = (y * width + x) * 4
                    let alpha = Double(bytes[index + 3]) / 255
                    guard alpha > 0.01 else { continue }
                    let pixel = HSL(red: min(1, Double(bytes[index]) / 255 / alpha),
                                    green: min(1, Double(bytes[index + 1]) / 255 / alpha),
                                    blue: min(1, Double(bytes[index + 2]) / 255 / alpha))
                    if let letteringBounds,
                       letteringBounds.contains(CGPoint(x: Double(x) / Double(width) * 1254,
                                                        y: Double(y) / Double(height) * 1254)),
                       regions?.eyes.contains(CGPoint(x: Double(x) / Double(width), y: Double(y) / Double(height))) != true {
                        let rgb = pixel.rgb
                        // The white print mixes into red cloth at its edges.
                        // Recover that coverage, then blend charcoal into the chosen
                        // cloth color so pale bandanas have no white/red fringe.
                        let white = min(rgb.0, rgb.1, rgb.2)
                        let isPrint = pixel.hue < 0.055 || pixel.hue > 0.95
                            || max(rgb.0, rgb.1, rgb.2) - white < 0.12
                        let coverage = isPrint ? min(1, max(0, (white - 0.30) / 0.60)) : 0
                        if coverage > 0 {
                            let cloth = targets[0].rgb
                            bytes[index] = UInt8(((cloth.0 * (1 - coverage) + letteringInk.0 * coverage) * alpha * 255).rounded())
                            bytes[index + 1] = UInt8(((cloth.1 * (1 - coverage) + letteringInk.1 * coverage) * alpha * 255).rounded())
                            bytes[index + 2] = UInt8(((cloth.2 * (1 - coverage) + letteringInk.2 * coverage) * alpha * 255).rounded())
                            continue
                        }
                    }
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
                    let sourceTone = fallPalette?.tones[partIndex] ?? sourcePalette[partIndex]
                    let idleTone = fallPalette != nil && width > 384 ? idleDisplayPalette[partIndex] : idlePalette[partIndex]
                    let normalizedLightness = sourceTone.matchLightness(pixel.lightness, to: idleTone)
                    let normalizedSaturation = min(1, pixel.saturation * idleTone.saturation / sourceTone.saturation)
                    let replacement: (Double, Double, Double)
                    if unchanged[partIndex] {
                        // Preserve the source's shading variation while matching
                        // the ordinary Dino's actual hue, including default colors.
                        let shift = fallPalette.map { idleDisplayHues[partIndex] - $0.hues[partIndex] } ?? 0
                        let hue = pixel.hue + shift
                        replacement = HSL(hue: hue - floor(hue), saturation: normalizedSaturation,
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

    /// Tight print regions in each 1254-point illustration exclude the eyes,
    /// highlights and transparent background, even when the head is tilted.
    static let answerLetteringBounds: [String: CGRect] = {
        let rects = [
            CGRect(x: 545, y: 85, width: 275, height: 140),
            CGRect(x: 555, y: 90, width: 280, height: 140),
            CGRect(x: 545, y: 100, width: 275, height: 150),
            CGRect(x: 525, y: 115, width: 290, height: 170),
            CGRect(x: 600, y: 100, width: 315, height: 170),
            CGRect(x: 555, y: 90, width: 280, height: 145),
            CGRect(x: 545, y: 85, width: 275, height: 145),
            CGRect(x: 545, y: 85, width: 275, height: 140),
            CGRect(x: 545, y: 85, width: 275, height: 140),
            CGRect(x: 590, y: 100, width: 280, height: 145),
            CGRect(x: 535, y: 80, width: 280, height: 140),
            CGRect(x: 540, y: 65, width: 280, height: 145),
            CGRect(x: 545, y: 80, width: 280, height: 140),
            CGRect(x: 555, y: 85, width: 280, height: 145),
            CGRect(x: 545, y: 85, width: 275, height: 140),
            CGRect(x: 545, y: 85, width: 275, height: 140)
        ]
        let answers = Dictionary(uniqueKeysWithValues: zip(DinoAnswerArtwork.wrongAssets + DinoAnswerArtwork.correctAssets, rects))
        let applause = (1...8).map { frame in
            (String(format: "dino_applaus_frame_%02d", frame), CGRect(x: 500, y: 80, width: 300, height: 150))
        }
        return answers.merging(Dictionary(uniqueKeysWithValues: applause)) { existing, _ in existing }
    }()

    static let deepFallLetteringBounds: [String: CGRect] = {
        let names = ["01", "02", "03", "03a", "04", "05", "06", "06a", "07", "08"]
        let bounds = [CGRect(x:545,y:90,width:285,height:150), CGRect(x:736,y:194,width:280,height:124),
                      CGRect(x:761,y:241,width:285,height:130), CGRect(x:855,y:512,width:290,height:142),
                      CGRect(x:794,y:600,width:292,height:135), CGRect(x:876,y:552,width:275,height:155),
                      CGRect(x:748,y:239,width:330,height:138), CGRect(x:685,y:198,width:300,height:146),
                      CGRect(x:545,y:87,width:290,height:150), CGRect(x:545,y:90,width:285,height:150)]
        return Dictionary(uniqueKeysWithValues: zip(names.map { "dino-stumble-deep-" + $0 }, bounds))
    }()

    private static let bandanaLetteringBounds: [String: CGRect] = [
        "dino-stumble-01": CGRect(x: 545, y: 90, width: 280, height: 140),
        "dino-stumble-02": CGRect(x: 701, y: 169, width: 287, height: 128),
        "dino-stumble-03": CGRect(x: 714, y: 309, width: 290, height: 130),
        "dino-stumble-04": CGRect(x: 829, y: 485, width: 277, height: 126),
        "dino-stumble-05": CGRect(x: 779, y: 411, width: 285, height: 136),
        "dino-stumble-06": CGRect(x: 740, y: 272, width: 285, height: 115),
        "dino-stumble-06a": CGRect(x: 750, y: 245, width: 270, height: 118),
        "dino-stumble-06b": CGRect(x: 655, y: 143, width: 274, height: 126),
        "dino-stumble-07": CGRect(x: 545, y: 90, width: 280, height: 140),
        "dino-stumble-08": CGRect(x: 545, y: 90, width: 280, height: 140),
        "dino-opening-jump-01": CGRect(x: 545, y: 90, width: 275, height: 135),
        "dino-opening-jump-02": CGRect(x: 688, y: 292, width: 290, height: 128),
        "dino-opening-jump-03": CGRect(x: 528, y: 74, width: 280, height: 134),
        "dino-opening-jump-04": CGRect(x: 543, y: 88, width: 275, height: 136),
        "dino-opening-jump-05": CGRect(x: 545, y: 87, width: 275, height: 135),
        "dino-opening-jump-06": CGRect(x: 580, y: 155, width: 280, height: 128),
        "dino-opening-jump-07": CGRect(x: 578, y: 191, width: 290, height: 138),
        "dino-opening-jump-08": CGRect(x: 545, y: 90, width: 275, height: 135),
        "dino-world-jump-01": CGRect(x: 552, y: 88, width: 243, height: 107),
        "dino-world-jump-02": CGRect(x: 714, y: 270, width: 238, height: 105),
        "dino-world-jump-03": CGRect(x: 763, y: 237, width: 238, height: 110),
        "dino-world-jump-06": CGRect(x: 679, y: 228, width: 240, height: 112),
        "dino-world-jump-07": CGRect(x: 672, y: 311, width: 267, height: 111),
        "dino-pirouette-01": CGRect(x: 580, y: 150, width: 252, height: 105),
        "dino-pirouette-02": CGRect(x: 696, y: 207, width: 243, height: 90),
        "dino-pirouette-03": CGRect(x: 681, y: 157, width: 220, height: 104),
        "dino-pirouette-04": CGRect(x: 700, y: 135, width: 195, height: 100),
        "dino-pirouette-08a": CGRect(x: 392, y: 165, width: 60, height: 62),
        "dino-pirouette-09": CGRect(x: 350, y: 139, width: 155, height: 94),
        "dino-pirouette-10": CGRect(x: 390, y: 120, width: 195, height: 117),
        "dino-pirouette-10a": CGRect(x: 439, y: 203, width: 231, height: 120),
        "dino-pirouette-11": CGRect(x: 433, y: 208, width: 246, height: 109),
        "dino-pirouette-12": CGRect(x: 568, y: 161, width: 245, height: 83),
        "dino-pirouette-13": CGRect(x: 559, y: 112, width: 236, height: 104),
        "dino-pirouette-14": CGRect(x: 560, y: 118, width: 246, height: 110),
        "dino-idle": CGRect(x: 550, y: 90, width: 238, height: 106),
        "dino-thumbs-up-08": CGRect(x: 525, y: 85, width: 250, height: 117),
        "dino-wrong-answer-04": CGRect(x: 526, y: 89, width: 252, height: 137),
        "dino-backflip-01": CGRect(x: 702, y: 205, width: 258, height: 98),
        "dino-backflip-03": CGRect(x: 326, y: 131, width: 210, height: 160),
        "dino-backflip-07": CGRect(x: 638, y: 233, width: 256, height: 106),
        "dino-backflip-08": CGRect(x: 520, y: 102, width: 237, height: 109)
    ]

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
    private static let idleDisplayPalette = [
        Tone(0.26471, 0.48039, 0.59216, 0.86441), Tone(0.09804, 0.19412, 0.34706, 0.54167),
        Tone(0.23333, 0.37451, 0.51176, 0.67593), Tone(0.55294, 0.79020, 0.88431, 0.71429)
    ]
    private static let idleDisplayHues = [0.00109, 0.36232, 0.24105, 0.10859]

    private final class FallPalette: NSObject {
        let tones: [Tone]
        let hues: [Double]
        init(tones: [Tone], hues: [Double]) { self.tones = tones; self.hues = hues }
    }
    private static let fallPaletteCache = NSCache<NSString, FallPalette>()

    private static func measuredFallPalette(_ pixels: UnsafeMutableBufferPointer<UInt8>, width: Int, height: Int,
                                            asset: String, regions: DinoAvatarMask.SpriteRegions?) -> FallPalette {
        let key = "\(asset)-\(width)-\(height)" as NSString
        if let cached = fallPaletteCache.object(forKey: key) { return cached }
        var lightness = [[Double]](repeating: [], count: 4)
        var saturation = lightness, hues = lightness
        // At most 384² samples; cache independently of the player's colors.
        let step = max(1, width / 384)
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let index = (y * width + x) * 4
                guard pixels[index + 3] > 250 else { continue }
                let alpha = Double(pixels[index + 3]) / 255
                let pixel = HSL(red: min(1, Double(pixels[index]) / 255 / alpha),
                                green: min(1, Double(pixels[index + 1]) / 255 / alpha),
                                blue: min(1, Double(pixels[index + 2]) / 255 / alpha))
                guard let part = DinoAvatarMask.part(hue: pixel.hue, saturation: pixel.saturation, lightness: pixel.lightness,
                    x: Double(x) / Double(width), y: Double(y) / Double(height), regions: regions),
                      let partIndex = DinoAppearance.Part.allCases.firstIndex(of: part) else { continue }
                lightness[partIndex].append(pixel.lightness)
                saturation[partIndex].append(pixel.saturation)
                hues[partIndex].append(pixel.hue > 0.8 ? pixel.hue - 1 : pixel.hue)
            }
        }
        var tones = [Tone](), medians = [Double]()
        for part in 0..<4 {
            let lights = lightness[part].sorted(), sats = saturation[part].sorted(), hue = hues[part].sorted()
            guard !lights.isEmpty else {
                tones.append(idlePalette[part]); medians.append(idleDisplayHues[part]); continue
            }
            func quantile(_ p: Double) -> Double { lights[Int(Double(lights.count - 1) * p)] }
            tones.append(Tone(quantile(0.1), quantile(0.5), quantile(0.9), sats[sats.count / 2]))
            medians.append(hue[hue.count / 2])
        }
        let palette = FallPalette(tones: tones, hues: medians)
        fallPaletteCache.setObject(palette, forKey: key)
        return palette
    }
    private static let answerPalettes: [String: [Tone]] = [
        "ChatGPT-afbeelding 24 okt 2026, 21_14_27-1": [Tone(0.32016, 0.52372, 0.57087, 0.95726), Tone(0.10474, 0.19565, 0.38538, 0.55556), Tone(0.26087, 0.42292, 0.54941, 0.62281), Tone(0.60784, 0.82609, 0.90711, 0.72414)],
        "ChatGPT-afbeelding 24 okt 2026, 21_14_28-2": [Tone(0.31028, 0.51581, 0.56917, 0.93043), Tone(0.10870, 0.19763, 0.36561, 0.47264), Tone(0.25889, 0.41700, 0.54941, 0.59184), Tone(0.60672, 0.81225, 0.89921, 0.69565)],
        "ChatGPT-afbeelding 24 okt 2026, 21_14_29-3": [Tone(0.31818, 0.51383, 0.56719, 0.92500), Tone(0.11858, 0.20158, 0.41468, 0.49580), Tone(0.26482, 0.42292, 0.55138, 0.58974), Tone(0.62846, 0.83004, 0.90354, 0.72500)],
        "ChatGPT-afbeelding 24 okt 2026, 21_14_30-4": [Tone(0.30588, 0.51779, 0.60277, 0.94017), Tone(0.11067, 0.19565, 0.37549, 0.49020), Tone(0.25294, 0.41107, 0.53755, 0.57346), Tone(0.59486, 0.81225, 0.89921, 0.65957)],
        "ChatGPT-afbeelding 24 okt 2026, 21_14_31-5": [Tone(0.31818, 0.51581, 0.56522, 0.92437), Tone(0.11462, 0.20356, 0.34387, 0.45763), Tone(0.25397, 0.41897, 0.54348, 0.57991), Tone(0.59091, 0.81028, 0.89526, 0.67010)],
        "ChatGPT-afbeelding 24 okt 2026, 21_14_32-6": [Tone(0.31028, 0.51976, 0.56719, 0.94714), Tone(0.10119, 0.18182, 0.37255, 0.53488), Tone(0.25296, 0.41700, 0.55138, 0.59740), Tone(0.59881, 0.81621, 0.90551, 0.69565)],
        "ChatGPT-afbeelding 24 okt 2026, 21_14_33-7": [Tone(0.29249, 0.50395, 0.56126, 0.93249), Tone(0.10474, 0.17984, 0.35913, 0.51648), Tone(0.24308, 0.40675, 0.53755, 0.57895), Tone(0.57905, 0.79644, 0.89526, 0.66071)],
        "ChatGPT-afbeelding 24 okt 2026, 21_14_33-8": [Tone(0.29644, 0.50395, 0.57312, 0.92432), Tone(0.09289, 0.17391, 0.33399, 0.51852), Tone(0.23715, 0.38933, 0.51976, 0.59391), Tone(0.57510, 0.79644, 0.88735, 0.67347)],
        "ChatGPT-afbeelding 24 okt 2026, 21_15_42-1": [Tone(0.31818, 0.51772, 0.57115, 0.94142), Tone(0.10079, 0.19763, 0.38142, 0.56098), Tone(0.27075, 0.42688, 0.55731, 0.63090), Tone(0.60672, 0.81818, 0.90119, 0.70833)],
        "ChatGPT-afbeelding 24 okt 2026, 21_15_44-2": [Tone(0.30357, 0.50988, 0.55754, 0.96596), Tone(0.09881, 0.18972, 0.35516, 0.52941), Tone(0.26285, 0.42490, 0.55929, 0.64286), Tone(0.60079, 0.80906, 0.89921, 0.70732)],
        "ChatGPT-afbeelding 24 okt 2026, 21_15_44-3": [Tone(0.31028, 0.51779, 0.56917, 0.94340), Tone(0.10870, 0.19565, 0.37549, 0.52174), Tone(0.27273, 0.41502, 0.54314, 0.60265), Tone(0.61660, 0.82609, 0.90119, 0.73626)],
        "ChatGPT-afbeelding 24 okt 2026, 21_15_45-4": [Tone(0.30040, 0.50593, 0.56719, 0.92661), Tone(0.10196, 0.18577, 0.32609, 0.49550), Tone(0.26877, 0.41107, 0.53953, 0.59064), Tone(0.60277, 0.81818, 0.89130, 0.71717)],
        "ChatGPT-afbeelding 24 okt 2026, 21_15_46-5": [Tone(0.32353, 0.52372, 0.56324, 0.95652), Tone(0.10474, 0.18182, 0.37255, 0.51515), Tone(0.26285, 0.41304, 0.53755, 0.61039), Tone(0.60079, 0.81423, 0.89526, 0.71429)],
        "ChatGPT-afbeelding 24 okt 2026, 21_15_46-6": [Tone(0.31423, 0.51779, 0.57510, 0.93056), Tone(0.11067, 0.19170, 0.36957, 0.49451), Tone(0.27273, 0.42688, 0.54941, 0.58475), Tone(0.60474, 0.81225, 0.89723, 0.68085)],
        "ChatGPT-afbeelding 24 okt 2026, 21_15_47-7": [Tone(0.30830, 0.50988, 0.57510, 0.92453), Tone(0.10079, 0.19246, 0.36255, 0.49123), Tone(0.25882, 0.40909, 0.53755, 0.60190), Tone(0.59091, 0.80435, 0.89328, 0.66990)],
        "ChatGPT-afbeelding 24 okt 2026, 21_15_48-8": [Tone(0.30040, 0.50198, 0.57312, 0.92373), Tone(0.10277, 0.18577, 0.34325, 0.50000), Tone(0.24704, 0.40316, 0.53557, 0.61081), Tone(0.59486, 0.80830, 0.89328, 0.68750)],
    ]
    private static let palettes: [String: [Tone]] = [
        "dino_applaus_frame_01": [Tone(0.32213, 0.51779, 0.57115, 0.94167), Tone(0.10079, 0.19763, 0.38142, 0.56098), Tone(0.27075, 0.42688, 0.55731, 0.63090), Tone(0.60474, 0.81818, 0.90119, 0.70787)],
        "dino_applaus_frame_02": [Tone(0.34325, 0.52767, 0.62205, 0.90950), Tone(0.09921, 0.18924, 0.35573, 0.58140), Tone(0.27075, 0.42292, 0.53360, 0.61345), Tone(0.55138, 0.75889, 0.86759, 0.59322)],
        "dino_applaus_frame_03": [Tone(0.33730, 0.52778, 0.61858, 0.91189), Tone(0.10474, 0.19763, 0.37698, 0.55556), Tone(0.26680, 0.42688, 0.54348, 0.61086), Tone(0.53175, 0.74704, 0.86759, 0.57025)],
        "dino_applaus_frame_04": [Tone(0.34387, 0.52767, 0.63439, 0.90717), Tone(0.10359, 0.19721, 0.35968, 0.55556), Tone(0.27273, 0.41897, 0.53953, 0.61039), Tone(0.56972, 0.77075, 0.86364, 0.62162)],
        "dino_applaus_frame_05": [Tone(0.33992, 0.52590, 0.61660, 0.91379), Tone(0.09325, 0.18254, 0.34921, 0.57895), Tone(0.26482, 0.43083, 0.52767, 0.60870), Tone(0.55336, 0.76285, 0.86561, 0.59649)],
        "dino_applaus_frame_06": [Tone(0.33992, 0.53162, 0.63294, 0.91000), Tone(0.10672, 0.19246, 0.33399, 0.57009), Tone(0.26389, 0.43281, 0.53162, 0.61017), Tone(0.55159, 0.76285, 0.86561, 0.60000)],
        "dino_applaus_frame_07": [Tone(0.34190, 0.53162, 0.62451, 0.91262), Tone(0.09684, 0.19170, 0.36653, 0.56989), Tone(0.27075, 0.42688, 0.52964, 0.61086), Tone(0.57708, 0.77866, 0.86166, 0.63793)],
        "dino_applaus_frame_08": [Tone(0.32213, 0.51779, 0.57115, 0.94167), Tone(0.10079, 0.19763, 0.38142, 0.56098), Tone(0.27075, 0.42688, 0.55731, 0.63090), Tone(0.60474, 0.81818, 0.90119, 0.70787)],
        "dino-pirouette-06a": [Tone(0.31818, 0.50198, 0.56126, 0.90598), Tone(0.12846, 0.22925, 0.32609, 0.42169), Tone(0.24704, 0.39328, 0.49407, 0.59596), Tone(0.58135, 0.67787, 0.79365, 0.46914)],
        "dino-pirouette-07a": [Tone(0.33794, 0.49209, 0.56917, 0.90909), Tone(0.16206, 0.25099, 0.38889, 0.36691), Tone(0.25000, 0.39526, 0.50395, 0.56190), Tone(0.60980, 0.69565, 0.80237, 0.51190)],
        "dino-pirouette-08a": [Tone(0.36561, 0.51976, 0.56746, 0.91228), Tone(0.15613, 0.24506, 0.38538, 0.38843), Tone(0.30159, 0.46047, 0.54348, 0.53509), Tone(0.63834, 0.76181, 0.86166, 0.62295)],
        "dino-pirouette-10a": [Tone(0.29842, 0.52174, 0.58498, 0.94470), Tone(0.11706, 0.22134, 0.40316, 0.42342), Tone(0.27668, 0.44466, 0.54348, 0.55745), Tone(0.63834, 0.77470, 0.88340, 0.64602)],
        "dino-opening-jump-01": [Tone(0.31225, 0.53162, 0.57510, 0.95575), Tone(0.10870, 0.20158, 0.39961, 0.55056), Tone(0.27075, 0.43849, 0.57115, 0.62771), Tone(0.62846, 0.82806, 0.90514, 0.75281)],
        "dino-opening-jump-02": [Tone(0.31818, 0.53162, 0.57115, 0.94760), Tone(0.11508, 0.20319, 0.43849, 0.50909), Tone(0.25296, 0.42292, 0.55159, 0.59664), Tone(0.58498, 0.78854, 0.88583, 0.64151)],
        "dino-opening-jump-03": [Tone(0.32411, 0.51976, 0.56522, 0.94845), Tone(0.12253, 0.20553, 0.46245, 0.53043), Tone(0.27668, 0.42688, 0.54941, 0.61290), Tone(0.63439, 0.81818, 0.89723, 0.75472)],
        "dino-opening-jump-04": [Tone(0.31621, 0.51581, 0.56471, 0.93443), Tone(0.10474, 0.19048, 0.36667, 0.47619), Tone(0.25692, 0.41897, 0.55336, 0.60976), Tone(0.61265, 0.81028, 0.90000, 0.68932)],
        "dino-opening-jump-05": [Tone(0.30237, 0.51186, 0.57480, 0.93407), Tone(0.12055, 0.20200, 0.40392, 0.47826), Tone(0.27866, 0.42460, 0.54348, 0.60360), Tone(0.60079, 0.81423, 0.89723, 0.70370)],
        "dino-opening-jump-06": [Tone(0.30830, 0.50593, 0.55754, 0.93833), Tone(0.11155, 0.18254, 0.35771, 0.49495), Tone(0.25692, 0.42490, 0.55336, 0.60577), Tone(0.59486, 0.77668, 0.88583, 0.63478)],
        "dino-opening-jump-07": [Tone(0.31818, 0.52372, 0.57341, 0.94760), Tone(0.12055, 0.19960, 0.37450, 0.48276), Tone(0.24506, 0.42095, 0.55929, 0.61739), Tone(0.61462, 0.78854, 0.88735, 0.66667)],
        "dino-opening-jump-08": [Tone(0.29249, 0.51186, 0.56719, 0.94760), Tone(0.10474, 0.18972, 0.38340, 0.51020), Tone(0.25099, 0.41107, 0.54150, 0.61607), Tone(0.60672, 0.81496, 0.89370, 0.72043)],
        "dino-pirouette-01": [Tone(0.22727, 0.50198, 0.57371, 0.93548), Tone(0.10672, 0.19565, 0.36508, 0.51163), Tone(0.23320, 0.40316, 0.54348, 0.61386), Tone(0.59881, 0.80040, 0.89921, 0.68317)],
        "dino-pirouette-02": [Tone(0.26087, 0.52174, 0.57312, 0.94048), Tone(0.10277, 0.19763, 0.39921, 0.48571), Tone(0.25692, 0.42885, 0.56151, 0.56731), Tone(0.62598, 0.80632, 0.90157, 0.67619)],
        "dino-pirouette-03": [Tone(0.27559, 0.51581, 0.57341, 0.94819), Tone(0.09486, 0.18775, 0.33597, 0.47500), Tone(0.28854, 0.44071, 0.56471, 0.54386), Tone(0.62648, 0.77866, 0.88538, 0.63158)],
        "dino-pirouette-04": [Tone(0.30237, 0.50791, 0.56917, 0.90638), Tone(0.09684, 0.18182, 0.34127, 0.50562), Tone(0.27668, 0.43056, 0.54150, 0.57282), Tone(0.61462, 0.75296, 0.88189, 0.59664)],
        "dino-pirouette-05": [Tone(0.28770, 0.49012, 0.56324, 0.93103), Tone(0.09486, 0.19643, 0.31818, 0.57282), Tone(0.26877, 0.42885, 0.52964, 0.60976), Tone(0.60079, 0.71542, 0.85771, 0.53741)],
        "dino-pirouette-06": [Tone(0.28656, 0.49803, 0.56324, 0.94737), Tone(0.08103, 0.19170, 0.30512, 0.54286), Tone(0.24308, 0.42490, 0.52569, 0.63235), Tone(0.58103, 0.70158, 0.84190, 0.56579)],
        "dino-pirouette-07": [Tone(0.31818, 0.46640, 0.56126, 0.91489), Tone(0.13636, 0.23913, 0.35573, 0.45455), Tone(0.25099, 0.38735, 0.51383, 0.61194), Tone(0.65020, 0.70553, 0.79644, 0.49515)],
        "dino-pirouette-08": [Tone(0.34722, 0.50000, 0.56863, 0.91579), Tone(0.14427, 0.23715, 0.38142, 0.41791), Tone(0.28571, 0.43281, 0.52964, 0.55251), Tone(0.65217, 0.75494, 0.84585, 0.60000)],
        "dino-pirouette-09": [Tone(0.29842, 0.50000, 0.57312, 0.92275), Tone(0.10474, 0.19960, 0.34325, 0.50877), Tone(0.26877, 0.43083, 0.52372, 0.58744), Tone(0.57510, 0.71344, 0.86759, 0.54667)],
        "dino-pirouette-10": [Tone(0.31423, 0.49802, 0.57708, 0.93860), Tone(0.11265, 0.22727, 0.35913, 0.48276), Tone(0.27470, 0.44269, 0.53162, 0.56731), Tone(0.60474, 0.73320, 0.86220, 0.56716)],
        "dino-pirouette-11": [Tone(0.27470, 0.50395, 0.57708, 0.93013), Tone(0.10672, 0.19763, 0.48617, 0.51111), Tone(0.22332, 0.40316, 0.53162, 0.62051), Tone(0.59449, 0.79249, 0.89130, 0.68224)],
        "dino-pirouette-12": [Tone(0.25692, 0.52372, 0.58498, 0.93043), Tone(0.14625, 0.23214, 0.43676, 0.45455), Tone(0.26680, 0.43478, 0.55138, 0.59111), Tone(0.63834, 0.82016, 0.89921, 0.76344)],
        "dino-pirouette-13": [Tone(0.27273, 0.52569, 0.58893, 0.94444), Tone(0.11067, 0.19960, 0.38690, 0.52239), Tone(0.28854, 0.42490, 0.55336, 0.60909), Tone(0.61660, 0.82213, 0.90316, 0.75000)],
        "dino-pirouette-14": [Tone(0.26389, 0.50198, 0.58498, 0.89076), Tone(0.10913, 0.20040, 0.50198, 0.51685), Tone(0.25889, 0.39130, 0.51383, 0.66990), Tone(0.59486, 0.80632, 0.88340, 0.76238)],
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
