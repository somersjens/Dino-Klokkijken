import CoreGraphics
import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum DinoAnswerArtwork {
    static let wrongAsset = "dino-answer-wrong"
    // DinoCharacter already uses the idle drawing at both ends of the clap.
    static let clapAssets = ["dino-idle"]
        + (1...6).map { String(format: "dino-answer-clap-%02d", $0) }
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
        deepFallPoses[asset] ?? applausePoses[asset] ?? answerPoses[asset] ?? openingPoses[asset] ?? poses[asset]
    }

    /// The deeper fall reaches the muzzle and belly. Its head, mouth and
    /// cloth travel much farther than the old hand-supported landing.
    private static let deepFallPoses: [String: SpriteRegions] = {
        let names = (1...10).map { String(format: "%02d", $0) }
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
        return Dictionary(uniqueKeysWithValues: names.indices.dropFirst().map { i in
            ("dino-result-fall-" + names[i],
             SpriteRegions(bandanaBottom: cloth[i], tailRight: 0.60, tailBottom: cloth[i] + 0.04,
                           upperSpikes: eyeContours([spikes[i]]), eyes: eyeContours(eyes[i]),
                           mouth: eyeContours([mouths[i]]), protectsFaceBeforeCloth: true,
                           decorations: i == 5 ? stars : nil))
        })
    }()

    /// Locate the painted clap accents for removal and protect eyes and mouths.
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
        return Dictionary(uniqueKeysWithValues: (2...7).map { frame in
            var shift = CGAffineTransform(translationX: -45.0 / 1254, y: -5.0 / 1254)
            let decorations = CGMutablePath()
            for rect in accents[frame - 1] {
                decorations.addRect(rect.applying(CGAffineTransform(scaleX: 1 / 1254, y: 1 / 1254)))
            }
            let regions = SpriteRegions(bandanaBottom: 0.34, tailRight: 0.32, tailBottom: 0.41,
                upperSpikes: upperSpikes.copy(using: &shift) ?? upperSpikes,
                eyes: frame < 5 ? eyeContours([(488, 300, 153, 151), (721, 247, 129, 143)]) : CGMutablePath(),
                mouth: eyeContours([(560, 465, 260, 155)]),
                protectsFaceBeforeCloth: true, decorations: decorations)
            return (DinoAnswerArtwork.clapAssets[frame - 1], regions)
        })
    }()

    /// The one confused expression still used for a wrong answer.
    private static let answerPoses: [String: SpriteRegions] = {
        var shift = CGAffineTransform(translationX: 14.0 / 1254, y: 0)
        return [DinoAnswerArtwork.wrongAsset: SpriteRegions(bandanaBottom: 0.36,
            upperSpikes: upperSpikes.copy(using: &shift) ?? upperSpikes,
            eyes: eyeContours([(566, 302, 110, 130), (770, 250, 102, 112)]),
            mouth: eyeContours([(624, 462, 222, 107)]), protectsFaceBeforeCloth: true)]
    }()

    /// Preserve the face and bandana contours throughout the opening jump.
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
        "dino-world-jump-crouch": SpriteRegions(
            bandanaBottom: 0.34,
            upperSpikes: contours([[.move(504, 150), .line(501, 16), .line(569, 16), .line(656, 106), .line(600, 126)],
                                   [.move(423, 218), .line(413, 116), .line(494, 110), .line(528, 159)]]),
            eyes: eyeContours([(532, 273, 142, 156), (743, 225, 124, 149)]),
            mouth: eyeContours([(603, 446, 219, 140)])),
        "dino-world-jump-takeoff": SpriteRegions(
            bandanaBottom: 0.36,
            upperSpikes: contours([[.move(650, 239), .line(659, 135), .line(728, 132), .line(821, 251)],
                                   [.move(573, 283), .line(564, 192), .line(625, 188), .line(668, 256)]]),
            eyes: eyeContours([(636, 432, 149, 148), (862, 448, 112, 144)]),
            mouth: eyeContours([(661, 624, 210, 149)])),
        "dino-world-jump-airborne": SpriteRegions(
            bandanaBottom: 0.34,
            upperSpikes: contours([[.move(728, 210), .line(753, 80), .line(825, 89), .line(890, 219)],
                                   [.move(657, 235), .line(664, 110), .line(739, 92), .line(771, 194)]]),
            eyes: eyeContours([(659, 375, 147, 140), (881, 418, 119, 144)]),
            mouth: eyeContours([(641, 540, 163, 167)])),
        "dino-world-jump-landing": SpriteRegions(
            bandanaBottom: 0.35,
            upperSpikes: contours([[.move(650, 227), .line(665, 90), .line(738, 98), .line(818, 233)],
                                   [.move(560, 285), .line(548, 151), .line(609, 142), .line(667, 234)]]),
            eyes: eyeContours([(600, 396, 142, 149), (805, 411, 122, 150)]),
            mouth: eyeContours([(638, 586, 201, 134)])),
        "dino-world-jump-recover": SpriteRegions(
            bandanaBottom: 0.40,
            upperSpikes: contours([[.move(648, 263), .line(648, 147), .line(719, 153), .line(794, 273)],
                                   [.move(557, 300), .line(548, 207), .line(613, 194), .line(659, 263)]]),
            eyes: eyeContours([(608, 483, 145, 147), (838, 458, 114, 150)]),
            mouth: eyeContours([(664, 673, 165, 119)])),
        "dino-result-pirouette-01": SpriteRegions(
            bandanaBottom: 0.39,
            upperSpikes: contours([
                [.move(548, 182), .curve(576, 67, 532, 112, 543, 57), .curve(704, 131, 618, 61, 674, 103), .curve(548, 182, 643, 145, 594, 162)],
                [.move(460, 255), .curve(463, 157, 442, 222, 439, 178), .curve(555, 169, 489, 141, 524, 149), .curve(460, 255, 524, 191, 493, 227)]
            ]),
            eyes: eyeContours([(564, 357, 130, 135), (800, 320, 99, 134)]),
            mouth: contours([[.move(620, 538), .curve(797, 584, 663, 578, 742, 593), .curve(901, 548, 839, 578, 880, 564),
                              .curve(810, 660, 887, 598, 852, 647), .curve(735, 668, 789, 679, 752, 679), .curve(620, 538, 679, 645, 648, 587)]])),
        "dino-result-pirouette-02": SpriteRegions(
            bandanaBottom: 0.41,
            upperSpikes: contours([
                [.move(607, 218), .curve(648, 80, 599, 141, 610, 68), .curve(777, 170, 693, 71, 751, 123), .curve(607, 218, 712, 185, 657, 203)],
                [.move(505, 310), .curve(510, 167, 474, 236, 473, 167), .curve(615, 191, 542, 145, 583, 165), .curve(505, 310, 575, 232, 535, 274)]
            ]),
            eyes: eyeContours([(677, 399, 130, 128), (920, 365, 87, 122)]),
            mouth: contours([[.move(745, 577), .curve(899, 638, 785, 621, 849, 638), .curve(971, 608, 934, 636, 956, 619),
                              .curve(886, 712, 946, 657, 923, 699), .curve(827, 716, 864, 729, 842, 727), .curve(745, 577, 778, 685, 762, 629)]])),
        "dino-result-pirouette-03": SpriteRegions(
            bandanaBottom: 0.35, tailRight: 0.43, tailBottom: 0.40,
            upperSpikes: contours([
                [.move(575, 190), .curve(599, 65, 561, 122, 570, 54), .curve(739, 135, 640, 54, 711, 94), .curve(575, 190, 678, 148, 620, 174)],
                [.move(490, 283), .curve(489, 156, 455, 224, 455, 153), .curve(585, 180, 521, 133, 560, 151), .curve(490, 283, 544, 214, 517, 251)]
            ]),
            eyes: eyeContours([(673, 341, 120, 124), (877, 307, 66, 110)]),
            mouth: contours([[.move(734, 505), .curve(888, 540, 776, 536, 837, 544), .curve(976, 511, 932, 539, 958, 522),
                              .curve(887, 604, 952, 553, 923, 591), .curve(823, 607, 864, 620, 839, 615), .curve(734, 505, 775, 584, 753, 542)]])),
        "dino-result-pirouette-04": SpriteRegions(
            bandanaBottom: 0.34, tailRight: 0.43, tailBottom: 0.39,
            upperSpikes: contours([[.move(604, 164), .curve(617, 58, 578, 104, 581, 53), .curve(752, 130, 659, 50, 719, 92), .curve(604, 164, 700, 139, 651, 148)], [.move(532, 280), .curve(516, 139, 483, 202, 466, 142), .curve(615, 164, 551, 118, 590, 140), .curve(532, 280, 580, 196, 552, 240)]]),
            eyes: eyeContours([(697, 300, 118, 122), (872, 266, 62, 100)]),
            mouth: contours([[.move(767, 450), .curve(907, 485, 804, 480, 862, 490), .curve(947, 469, 926, 482, 937, 474), .curve(881, 548, 936, 508, 915, 538), .curve(827, 550, 859, 563, 844, 560), .curve(767, 450, 792, 524, 779, 484)]])),
        "dino-result-pirouette-05": SpriteRegions(
            bandanaBottom: 0.32, tailRight: 0.45, tailBottom: 0.36,
            upperSpikes: contours([[.move(580, 161), .curve(585, 45, 552, 101, 551, 41), .curve(733, 130, 635, 36, 694, 93), .curve(580, 161, 675, 142, 626, 150)], [.move(512, 252), .curve(518, 128, 476, 181, 477, 131), .curve(592, 159, 548, 109, 575, 132), .curve(512, 252, 562, 195, 531, 226)]]),
            eyes: eyeContours([(794, 239, 86, 128)]),
            mouth: contours([[.move(838, 415), .curve(919, 433, 859, 429, 896, 435), .curve(945, 419, 931, 429, 940, 422), .curve(906, 502, 940, 456, 924, 491), .curve(884, 520, 901, 515, 892, 526), .curve(838, 415, 853, 496, 848, 450)]])),
        "dino-result-pirouette-06": SpriteRegions(
            bandanaBottom: 0.35, tailRight: 0.45, tailBottom: 0.37,
            upperSpikes: contours([[.move(637, 135), .curve(647, 26, 610, 74, 613, 20), .curve(780, 105, 693, 21, 748, 73), .curve(637, 135, 721, 111, 678, 121)], [.move(557, 241), .curve(556, 101, 517, 167, 511, 109), .curve(646, 135, 585, 80, 620, 104), .curve(557, 241, 615, 174, 580, 210)]]),
            eyes: eyeContours([(813, 265, 84, 125)]),
            mouth: contours([[.move(860, 430), .curve(933, 447, 879, 445, 913, 451), .curve(951, 434, 945, 444, 950, 438), .curve(928, 500, 950, 460, 942, 485), .curve(906, 526, 922, 521, 915, 531), .curve(860, 430, 880, 506, 868, 468)]])),
        "dino-result-pirouette-07": SpriteRegions(
            bandanaBottom: 0.36, tailRight: 0.45, tailBottom: 0.40,
            upperSpikes: contours([
                [.move(614, 144), .line(616, 31), .line(683, 31), .line(763, 119), .line(692, 158)],
                [.move(554, 241), .line(513, 168), .line(519, 103), .line(571, 103), .line(638, 165)]
            ]),
            eyes: eyeContours([(902, 277, 25, 77)]), mouth: contours([])),
        "dino-result-pirouette-08": SpriteRegions(
            bandanaBottom: 0.40,
            upperSpikes: contours([[.move(578, 165), .curve(628, 50, 578, 104, 601, 38), .curve(712, 151, 674, 42, 703, 111), .curve(578, 165, 660, 167, 618, 167)], [.move(616, 258), .curve(641, 137, 591, 209, 602, 143), .curve(735, 238, 681, 126, 729, 183), .curve(616, 258, 692, 257, 656, 260)]]),
            eyes: eyeContours([]),
            mouth: contours([])),
        "dino-result-pirouette-09": SpriteRegions(
            bandanaBottom: 0.40,
            upperSpikes: contours([
                [.move(561, 171), .line(580, 90), .line(628, 48), .line(687, 74), .line(712, 168)],
                [.move(610, 267), .line(604, 179), .line(649, 139), .line(712, 167), .line(738, 253)]
            ]), eyes: eyeContours([]), mouth: contours([])),
        "dino-result-pirouette-10": SpriteRegions(
            bandanaBottom: 0.40,
            upperSpikes: contours([[.move(554, 160), .curve(634, 48, 561, 94, 598, 27), .curve(712, 184, 693, 26, 728, 103), .curve(554, 160, 648, 186, 599, 171)], [.move(639, 271), .curve(655, 153, 608, 212, 613, 153), .curve(741, 262, 701, 140, 743, 205), .curve(639, 271, 712, 286, 673, 290)]]),
            eyes: eyeContours([]),
            mouth: contours([])),
        "dino-result-pirouette-11": SpriteRegions(
            bandanaBottom: 0.30, tailLeft: 0.55, tailBottom: 0.40,
            upperSpikes: contours([
                [.move(491, 145), .line(538, 77), .line(609, 53), .line(684, 75), .line(679, 177), .line(634, 201)],
                [.move(624, 178), .line(696, 144), .line(754, 159), .line(794, 223), .line(774, 278), .line(704, 251)]
            ]), eyes: eyeContours([(391, 297, 50, 103)]),
            mouth: eyeContours([(362, 435, 60, 95)])),
        "dino-result-pirouette-12": SpriteRegions(
            bandanaBottom: 0.30, tailLeft: 0.56, tailBottom: 0.40,
            upperSpikes: contours([[.move(514, 140), .curve(607, 49, 533, 79, 565, 28), .curve(662, 183, 660, 28, 673, 112), .curve(514, 140, 605, 160, 559, 146)], [.move(640, 168), .curve(743, 114, 672, 118, 712, 100), .curve(764, 266, 788, 134, 789, 212), .curve(640, 168, 723, 218, 685, 187)]]),
            eyes: eyeContours([(327, 278, 48, 96), (415, 272, 101, 125)]),
            mouth: contours([[.move(346, 459), .curve(476, 431, 386, 461, 445, 447), .curve(447, 502, 465, 463, 457, 487), .curve(398, 539, 436, 523, 420, 544), .curve(365, 520, 380, 540, 371, 529), .curve(346, 459, 351, 500, 348, 478)]])),
        "dino-result-pirouette-13": SpriteRegions(
            bandanaBottom: 0.28, tailLeft: 0.55, tailBottom: 0.40,
            upperSpikes: contours([[.move(525, 130), .curve(623, 47, 547, 74, 584, 27), .curve(680, 174, 677, 28, 690, 100), .curve(525, 130, 616, 148, 570, 135)], [.move(648, 178), .curve(758, 132, 683, 125, 729, 116), .curve(781, 269, 802, 152, 805, 207), .curve(648, 178, 735, 222, 697, 198)]]),
            eyes: eyeContours([(332, 251, 65, 98), (438, 284, 120, 123)]),
            mouth: contours([[.move(310, 462), .curve(471, 438, 355, 470, 431, 458), .curve(444, 510, 460, 474, 450, 497), .curve(386, 545, 429, 534, 407, 550), .curve(343, 528, 365, 546, 352, 539), .curve(310, 462, 324, 512, 316, 486)]])),
        "dino-result-pirouette-14": SpriteRegions(
            bandanaBottom: 0.37, tailLeft: 0.64, tailBottom: 0.41,
            upperSpikes: contours([
                [.move(554, 185), .line(576, 115), .line(644, 75), .line(701, 92), .line(728, 190)],
                [.move(686, 202), .line(744, 157), .line(801, 161), .line(840, 230), .line(807, 297)]
            ]), eyes: eyeContours([(388, 326, 84, 118), (536, 366, 114, 135)]),
            mouth: contours([[.move(410, 543), .curve(609, 520, 473, 566, 549, 551),
                              .curve(566, 623, 640, 549, 604, 594), .curve(482, 650, 536, 645, 505, 658),
                              .curve(410, 543, 451, 626, 425, 581)]])),
        "dino-result-pirouette-15": SpriteRegions(
            bandanaBottom: 0.36, tailLeft: 0.63, tailBottom: 0.40,
            upperSpikes: contours([[.move(559, 215), .curve(653, 94, 569, 147, 611, 73), .curve(711, 238, 707, 69, 728, 172), .curve(559, 215, 659, 226, 609, 211)], [.move(687, 222), .curve(790, 177, 723, 166, 759, 154), .curve(806, 326, 843, 200, 827, 270), .curve(687, 222, 765, 283, 726, 248)]]),
            eyes: eyeContours([(393, 335, 87, 116), (573, 368, 104, 130)]),
            mouth: contours([[.move(415, 537), .curve(604, 521, 466, 553, 549, 546), .curve(635, 537, 627, 524, 638, 530), .curve(551, 610, 616, 569, 581, 600), .curve(487, 622, 529, 628, 505, 630), .curve(415, 537, 442, 600, 426, 562)]])),
        "dino-result-pirouette-16": SpriteRegions(
            bandanaBottom: 0.36,
            upperSpikes: contours([
                [.move(580, 150), .curve(616, 32, 578, 84, 584, 22), .curve(734, 125, 665, 23, 710, 76), .curve(580, 150, 675, 134, 625, 140)],
                [.move(495, 225), .curve(502, 122, 475, 175, 482, 133), .curve(589, 143, 532, 107, 566, 124), .curve(495, 225, 555, 164, 524, 201)]
            ]),
            eyes: eyeContours([(529, 333, 122, 125), (762, 314, 110, 123)]),
            mouth: contours([[.move(566, 502), .curve(695, 565, 604, 548, 648, 565), .curve(857, 498, 775, 565, 825, 540),
                              .curve(757, 630, 831, 578, 798, 618), .curve(695, 638, 738, 644, 716, 645), .curve(566, 502, 625, 611, 594, 555)]])),
        "dino-result-pirouette-17": SpriteRegions(
            bandanaBottom: 0.34,
            upperSpikes: contours([
                [.move(516, 147), .curve(534, 27, 501, 81, 501, 15), .curve(652, 94, 575, 20, 624, 57), .curve(516, 147, 605, 107, 558, 127)],
                [.move(433, 232), .curve(440, 120, 405, 178, 409, 132), .curve(525, 137, 466, 103, 501, 118), .curve(433, 232, 491, 173, 462, 208)]
            ]),
            eyes: eyeContours([(548, 296, 124, 126), (769, 262, 91, 111)]),
            mouth: contours([[.move(604, 454), .curve(757, 507, 646, 498, 704, 510), .curve(847, 487, 803, 509, 828, 498),
                              .curve(772, 568, 826, 530, 806, 556), .curve(709, 578, 750, 587, 728, 585), .curve(604, 454, 655, 560, 627, 510)]])),
        "dino-result-pirouette-18": SpriteRegions(
            bandanaBottom: 0.37,
            upperSpikes: contours([
                [.move(531, 158), .curve(551, 22, 510, 91, 516, 17), .curve(688, 96, 595, 16, 654, 58), .curve(531, 158, 637, 115, 581, 138)],
                [.move(445, 239), .curve(454, 120, 416, 180, 423, 128), .curve(543, 139, 481, 101, 516, 116), .curve(445, 239, 509, 170, 476, 205)]
            ]),
            eyes: eyeContours([(537, 298, 131, 139), (762, 268, 99, 133)]),
            mouth: contours([[.move(596, 480), .curve(758, 529, 640, 520, 704, 533), .curve(869, 493, 807, 526, 847, 506),
                              .curve(786, 613, 857, 550, 826, 597), .curve(722, 627, 767, 634, 741, 636), .curve(596, 480, 658, 603, 622, 536)]])),
        "dino-result-backflip-crouch": SpriteRegions(
            bandanaBottom: 0.35,
            upperSpikes: contours([
                [.move(654, 203), .curve(703, 74, 650, 143, 678, 69), .curve(814, 173, 737, 72, 796, 125), .curve(654, 203, 755, 175, 701, 192)],
                [.move(542, 282), .curve(550, 166, 520, 230, 529, 186), .curve(657, 170, 578, 131, 625, 148), .curve(542, 282, 624, 207, 578, 252)]
            ]),
            eyes: eyeContours([(661, 386, 134, 132), (899, 365, 93, 124)]),
            mouth: contours([[.move(716, 551), .curve(819, 623, 752, 589, 778, 618), .curve(913, 630, 852, 635, 893, 635),
                              .curve(861, 693, 900, 655, 879, 688), .curve(815, 691, 846, 703, 832, 699), .curve(716, 551, 772, 678, 742, 622)]])),
        "dino-result-backflip-airborne": SpriteRegions(
            bandanaBottom: 0.28, tailRight: 0.28, tailBottom: 0.50,
            upperSpikes: contours([
                [.move(309, 213), .curve(328, 105, 292, 174, 299, 101), .curve(417, 143, 353, 94, 396, 121), .curve(309, 213, 374, 163, 340, 190)],
                [.move(247, 307), .curve(211, 212, 209, 276, 178, 236), .curve(307, 199, 235, 193, 273, 195), .curve(247, 307, 284, 230, 260, 266)]
            ]),
            eyes: eyeContours([(395, 336, 131, 126), (565, 239, 98, 106)]),
            mouth: contours([[.move(506, 479), .curve(580, 491, 534, 487, 555, 492), .curve(694, 447, 623, 486, 669, 461),
                              .curve(652, 530, 692, 482, 678, 516), .curve(600, 548, 636, 544, 617, 553), .curve(506, 479, 557, 545, 524, 512)]])),
        "dino-result-backflip-landing": SpriteRegions(
            bandanaBottom: 0.405,
            upperSpikes: contours([
                [.move(615, 244), .curve(662, 111, 603, 176, 633, 104), .curve(764, 201, 700, 108, 741, 155), .curve(615, 244, 703, 208, 661, 223)],
                [.move(518, 346), .curve(535, 197, 498, 281, 505, 216), .curve(618, 211, 554, 176, 592, 188), .curve(518, 346, 589, 253, 550, 300)]
            ]),
            eyes: eyeContours([(613, 425, 126, 127), (850, 387, 95, 123)]),
            mouth: contours([[.move(661, 598), .curve(764, 658, 687, 632, 725, 655), .curve(878, 660, 807, 665, 851, 665),
                              .curve(838, 719, 865, 689, 855, 711), .curve(773, 733, 817, 743, 797, 743), .curve(661, 598, 719, 718, 688, 660)]])),
        "dino-result-backflip-recover": SpriteRegions(
            bandanaBottom: 0.365,
            upperSpikes: contours([
                [.move(466, 164), .curve(490, 31, 456, 106, 465, 23), .curve(610, 89, 528, 19, 578, 55), .curve(466, 164, 565, 110, 515, 137)],
                [.move(385, 236), .curve(395, 135, 360, 191, 371, 152), .curve(484, 143, 417, 114, 462, 123), .curve(385, 236, 448, 176, 416, 207)]
            ]),
            eyes: eyeContours([(517, 294, 129, 119), (734, 247, 95, 111)]),
            mouth: contours([[.move(592, 453), .curve(700, 490, 618, 479, 660, 490), .curve(799, 481, 741, 493, 776, 489),
                              .curve(756, 554, 794, 515, 777, 543), .curve(690, 565, 734, 571, 708, 575), .curve(592, 453, 641, 550, 612, 501)]])),
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

    /// Mirror once while preparing sprites; every native flight and SwiftUI pose then shares the same facing.
    static func facingRight(_ source: CGImage) -> CGImage? {
        guard let context = CGContext(data: nil, width: source.width, height: source.height, bitsPerComponent: 8,
            bytesPerRow: source.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.translateBy(x: CGFloat(source.width), y: 0)
        context.scaleBy(x: -1, y: 1)
        context.draw(source, in: CGRect(x: 0, y: 0, width: source.width, height: source.height))
        return context.makeImage()
    }

    /// Jungle outfits have leaf spines and a gold crown in place of the main Dino's bandana.
    /// Classify the original paint before applying choices, so every pose retains its own shading.
    static func recoloredJungle(_ source: CGImage, appearance: DinoAppearance, asset: String = "jungle-idle") -> CGImage? {
        guard appearance.mainAppearance != .standard else { return source }
        let width = source.width, height = source.height
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let format = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let parts: [DinoAppearance.Part] = [.bandana, .spikes, .body, .belly]
        let references = [0xDAA33D, 0x247C35, 0x94BF46, 0xF0D995].map { HSL(hex: UInt32($0)) }
        let targets = parts.map { HSL(hex: appearance[$0]) }
        let regions = JungleRegions(asset: DinoJungleArtwork.asset(for: asset))
        pixels.withUnsafeMutableBytes { buffer in
            let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: space, bitmapInfo: format)!
            context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
            let bytes = buffer.bindMemory(to: UInt8.self)
            let crown = jungleMetalMask(bytes, width: width, height: height, asset: DinoJungleArtwork.asset(for: asset), regions: regions)
            let clock = jungleMetalMask(bytes, width: width, height: height, asset: DinoJungleArtwork.asset(for: asset), regions: regions, isClock: true)
            let spots = jungleBodySpots(bytes,width:width,height:height,asset:DinoJungleArtwork.asset(for:asset))
            for index in stride(from: 0, to: bytes.count, by: 4) {
                let alpha = Double(bytes[index + 3]) / 255
                guard alpha > 0.06 else { continue }
                let pixel = HSL(red: Double(bytes[index]) / 255 / alpha,
                                green: Double(bytes[index + 1]) / 255 / alpha,
                                blue: Double(bytes[index + 2]) / 255 / alpha)
                let point = CGPoint(x: Double(index / 4 % width) * 512 / Double(width),
                                    y: Double(index / 4 / width) * 512 / Double(height))
                // Geometry identifies complete materials, including their gloss
                // and shadows. The dial and ink retain their neutral source art.
                if regions.ink.contains(point), pixel.hue < 0.15 { continue }
                let palm = regions.skin.contains(point)
                if regions.clockFace.contains(point), !palm, pixel.hue < 0.18 { continue }
                let part: Int
                let warm = pixel.hue < 0.18 || pixel.saturation < 0.10
                if !palm, crown[index / 4] != 0 || clock[index / 4] != 0 || (warm && (regions.clockRim.contains(point) || regions.suspension.contains(point,using:.evenOdd))) {
                    part = 0
                } else if point.y < regions.leafBase, abs(point.x-regions.crownSeed.x) < 135, pixel.saturation > 0.12 {
                    part = 1
                } else if (0.18...0.50).contains(pixel.hue), pixel.saturation > 0.12 {
                    part = pixel.hue > 0.27 && spots[index / 4] == 0 && !regions.faceSkin.contains(point) ? 1 : 2
                } else if (0.055..<0.18).contains(pixel.hue), pixel.saturation > 0.10 {
                    part = !palm && regions.gold.contains(point) && pixel.hue < 0.118 ? 0 : 3
                } else { continue }
                guard appearance[parts[part]] != DinoAppearance.standard[parts[part]] else { continue }
                let reference = references[part], target = targets[part]
                let lightness = pixel.lightness <= reference.lightness
                    ? target.lightness * pixel.lightness / max(0.001, reference.lightness)
                    : target.lightness + (1 - target.lightness) * (pixel.lightness - reference.lightness) / max(0.001, 1 - reference.lightness)
                let rgb = HSL(hue: target.hue, saturation: min(1, pixel.saturation * target.saturation / max(0.001, reference.saturation)),
                              lightness: min(1, max(0, lightness))).rgb
                for (channel, value) in [rgb.0, rgb.1, rgb.2].enumerated() {
                    bytes[index + channel] = UInt8((min(1, max(0, value)) * alpha * 255).rounded())
                }
            }
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                       space: space, bitmapInfo: CGBitmapInfo(rawValue: format), provider: provider, decode: nil,
                       shouldInterpolate: true, intent: .defaultIntent)
    }

    /// A source-locked head layer. The lower back leaf, shoulder garland,
    /// clock and moving hands can never enter the portrait foreground.
    static func jungleHeadOverflow(_ source: CGImage, asset: String, mirrored: Bool = true) -> CGImage? {
        let name = DinoJungleArtwork.asset(for:asset)
        let width = source.width, height = source.height
        let regions = JungleRegions(asset:name)
        let path = CGMutablePath()
        path.move(to:.zero)
        for point in [CGPoint(x:512,y:0),CGPoint(x:512,y:212),CGPoint(x:390,y:220),
                      CGPoint(x:369,y:228),CGPoint(x:335,y:235),CGPoint(x:310,y:244),
                      CGPoint(x:266,y:253),CGPoint(x:220,y:253),CGPoint(x:164,y:238),
                      CGPoint(x:135,y:213),CGPoint(x:0,y:213)] { path.addLine(to:point) }
        path.closeSubpath()
        var transform = DinoJungleArtwork.headRegistration(for:name)
        let head = path.copy(using:&transform)!
        let format = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        let space = CGColorSpace(name:CGColorSpace.sRGB)!
        var pixels = [UInt8](repeating:0,count:width*height*4)
        pixels.withUnsafeMutableBytes { buffer in
            let context = CGContext(data:buffer.baseAddress,width:width,height:height,bitsPerComponent:8,
                bytesPerRow:width*4,space:space,bitmapInfo:format)!
            context.draw(source,in:CGRect(x:0,y:0,width:width,height:height))
            let bytes = buffer.bindMemory(to:UInt8.self)
            for y in 0..<height {
                for x in 0..<width {
                    let u = (Double(x)+0.5)/Double(width)
                    let point = CGPoint(x:(mirrored ? 1-u : u)*512,y:(Double(y)+0.5)*512/Double(height))
                    if !head.contains(point) || regions.skin.contains(point) {
                        let i = (y*width+x)*4
                        for channel in 0..<4 { bytes[i+channel] = 0 }
                    }
                }
            }
        }
        guard let provider = CGDataProvider(data:Data(pixels) as CFData) else { return nil }
        return CGImage(width:width,height:height,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:width*4,
            space:space,bitmapInfo:CGBitmapInfo(rawValue:format),provider:provider,decode:nil,shouldInterpolate:true,intent:.defaultIntent)
    }

    private final class JungleMaterialMask: NSObject {
        let values: [UInt8]
        init(_ values: [UInt8]) { self.values = values }
    }
    private static let jungleMaterialCache: NSCache<NSString,JungleMaterialMask> = {
        let cache = NSCache<NSString,JungleMaterialMask>()
        cache.totalCostLimit = 24*1024*1024
        return cache
    }()

    /// Small green spots completely surrounded by lime skin belong to that
    /// skin. Leaves adjoin other leaves, metal or transparency instead.
    private static func jungleBodySpots(_ bytes: UnsafeMutableBufferPointer<UInt8>, width: Int, height: Int,
                                         asset: String) -> [UInt8] {
        let key = "spots-\(asset)-\(width)-\(height)" as NSString
        if let cached = jungleMaterialCache.object(forKey:key) { return cached.values }
        var green = [UInt8](repeating:0,count:width*height), body = green
        for i in green.indices {
            let p = i*4, alpha = Double(bytes[p+3])/255
            guard alpha > 0.5 else { continue }
            let color = HSL(red:Double(bytes[p])/255/alpha,green:Double(bytes[p+1])/255/alpha,blue:Double(bytes[p+2])/255/alpha)
            if color.saturation > 0.12 {
                if (0.27...0.50).contains(color.hue) { green[i] = 1 }
                else if (0.175..<0.27).contains(color.hue) { body[i] = 1 }
            }
        }
        let source = green
        var result = [UInt8](repeating:0,count:width*height)
        for start in green.indices where green[start] != 0 {
            var pending = [start], component: [Int] = []
            green[start] = 0
            while let i = pending.popLast() {
                component.append(i)
                let x = i % width, y = i / width
                for next in [x > 0 ? i-1 : -1,x+1 < width ? i+1 : -1,y > 0 ? i-width : -1,y+1 < height ? i+width : -1] {
                    if next >= 0 && green[next] != 0 { green[next] = 0; pending.append(next) }
                }
            }
            guard component.count >= 6*width*height/(512*512),component.count <= 600*width*height/(512*512) else { continue }
            let xs = component.map {$0 % width}, ys = component.map {$0 / width}
            let ratio = Double(xs.max()!-xs.min()!+1)/Double(ys.max()!-ys.min()!+1)
            guard (0.5...2.0).contains(ratio) else { continue }
            var neighbors = Set<Int>()
            let step = max(1,width/256)
            for i in component {
                let x = i % width, y = i / width
                for next in [x >= step ? i-step : -1,x+step < width ? i+step : -1,y >= step ? i-width*step : -1,y+step < height ? i+width*step : -1] {
                    if next >= 0 && source[next] == 0 { neighbors.insert(next) }
                }
            }
            if !neighbors.isEmpty && Double(neighbors.filter {body[$0] != 0}.count)/Double(neighbors.count) > 0.72 {
                for i in component { result[i] = 1 }
            }
        }
        jungleMaterialCache.setObject(JungleMaterialMask(result),forKey:key,cost:result.count)
        return result
    }

    /// A connected material, rather than a hue cutoff through individual gold
    /// highlights. Eyes and the lime center leaf cannot join this component.
    private static func jungleMetalMask(_ bytes: UnsafeMutableBufferPointer<UInt8>, width: Int, height: Int,
                                         asset: String, regions: JungleRegions, isClock: Bool = false) -> [UInt8] {
        let key = "\(asset)-\(width)-\(height)-\(isClock)" as NSString
        if let cached = jungleMaterialCache.object(forKey:key) { return cached.values }
        var candidates = [UInt8](repeating:0,count:width*height)
        for y in 0..<height {
            let py = Double(y)*512/Double(height)
            for x in 0..<width {
                let p = CGPoint(x:Double(x)*512/Double(width),y:py)
                if isClock {
                    guard regions.clockRim.contains(p) || regions.suspension.contains(p,using:.evenOdd), !regions.clockFace.contains(p), !regions.skin.contains(p) else { continue }
                } else {
                    guard regions.crown.contains(p), !regions.ink.contains(p), !(asset == "jungle-fallen" && p.x > 330) else { continue }
                }
                let i = (y*width+x)*4, alpha = Double(bytes[i+3])/255
                guard alpha > 0.06 else { continue }
                let color = HSL(red:Double(bytes[i])/255/alpha,green:Double(bytes[i+1])/255/alpha,blue:Double(bytes[i+2])/255/alpha)
                let upperLeaf = !isClock && py < regions.leafBase && color.hue >= 0.14 && color.saturation > 0.12
                if !upperLeaf && (color.hue < 0.18 || color.saturation < 0.10) && color.lightness > 0.09 { candidates[y*width+x] = 1 }
            }
        }
        let dialBounds = regions.clockFace.isEmpty ? regions.clockRim.boundingBox : regions.clockFace.boundingBox
        let seedX: Double = isClock ? dialBounds.midX : asset == "jungle-fallen" ? 160 : regions.crownSeed.x
        let seedY = isClock ? dialBounds.maxY+5 : regions.crownSeed.y
        var best: [Int] = [], bestScore = 0.0
        for start in candidates.indices where candidates[start] != 0 {
            var pending = [start], component: [Int] = [], distance = Double.infinity
            candidates[start] = 0
            while let i = pending.popLast() {
                component.append(i)
                let x = i % width, y = i / width
                let dx = Double(x)*512/Double(width)-seedX, dy = Double(y)*512/Double(height)-seedY
                distance = min(distance,dx*dx+dy*dy)
                for next in [x > 0 ? i-1 : -1,x+1 < width ? i+1 : -1,y > 0 ? i-width : -1,y+1 < height ? i+width : -1] {
                    if next >= 0 && candidates[next] != 0 { candidates[next] = 0; pending.append(next) }
                }
            }
            let score = Double(component.count)/(1+distance/625)
            if score > bestScore { bestScore = score; best = component }
        }
        var result = [UInt8](repeating:0,count:width*height)
        for i in best { result[i] = 1 }
        // Small reflected green/gray flecks are still part of the surrounding
        // metal. Large holes (the emerald and the dial) keep their own material.
        if let minX = best.map({$0 % width}).min(), let maxX = best.map({$0 % width}).max(),
           let minY = best.map({$0 / width}).min(), let maxY = best.map({$0 / width}).max() {
            var visited = result
            for y in minY...maxY {
                for x in minX...maxX {
                    let start = y*width+x
                    guard visited[start] == 0 else { continue }
                    var pending = [start], hole: [Int] = [], edge = false
                    visited[start] = 1
                    while let i = pending.popLast() {
                        hole.append(i)
                        let px = i % width, py = i / width
                        if px == minX || px == maxX || py == minY || py == maxY { edge = true }
                        for next in [px > minX ? i-1 : -1,px < maxX ? i+1 : -1,py > minY ? i-width : -1,py < maxY ? i+width : -1] {
                            if next >= 0 && visited[next] == 0 { visited[next] = 1; pending.append(next) }
                        }
                    }
                    if !edge && hole.count <= 90*width*height/(512*512) {
                        for i in hole { result[i] = 1 }
                    }
                }
            }
        }
        jungleMaterialCache.setObject(JungleMaterialMask(result),forKey:key,cost:result.count)
        return result
    }

    /// Measured in the unreflected 512px paintings. Only warm source pixels use
    /// these regions; green leaves crossing a strap retain their own material.
    private struct JungleRegions {
        let gold: CGPath
        let ink: CGPath
        let skin: CGPath
        let clockFace: CGPath
        let crown: CGPath
        let clockRim: CGPath
        let suspension: CGPath
        let preciseGold: Bool
        let leafBase: CGFloat
        let crownSeed: CGPoint
        let faceSkin: CGPath

        init(asset: String) {
            // Crown search extent, center-leaf base, iris regions, and strap centerlines.
            typealias Spec = (CGFloat, CGFloat, [[CGFloat]], [[CGFloat]])
            let spec: Spec
            preciseGold = asset == DinoJungleArtwork.openingAsset
            switch asset {
            case DinoJungleArtwork.openingAsset:
                spec = (165, 96, [[185,132,25,43],[249,134,26,45]],
                        [[163,265,185,288],[322,251,265,291],[160,326,174,329],[269,338,294,347]])
            case "jungle-crouch": spec = (210, 145, [[126,203,39,67],[187,200,60,73]], [[155,326,202,352],[288,277,255,350],[166,389,310,388]])
            case "jungle-takeoff": spec = (150, 72, [[172,100,37,65],[228,103,52,65]], [[187,235,205,250],[280,238,250,266],[173,293,309,307]])
            case "jungle-airborne": spec = (173, 85, [], [[182,232,204,242],[260,236,237,260]])
            case "jungle-landing": spec = (224, 147, [], [[177,320,221,345],[322,287,265,350],[183,390,315,383]])
            case "jungle-recover": spec = (168, 87, [[146,133,40,63],[203,132,58,68]], [[177,273,205,293],[302,251,254,302],[178,336,310,341]])
            case "jungle-stumble": spec = (187, 112, [[106,155,42,65],[158,150,67,73]], [[156,298,188,320],[277,258,240,334],[157,366,297,341]])
            case "jungle-fallen": spec = (352, 266, [], [[310,355,350,381],[350,381,343,442]])
            case "jungle-push-up": spec = (230, 155, [[98,207,44,59],[149,191,61,67]], [[191,344,208,352],[290,281,247,364],[260,396,334,382]])
            case "jungle-turn-01", "jungle-turn-08": spec = (170, 91, [[160,128,44,62],[219,127,58,66]], [[164,284,192,294],[282,269,243,305],[153,347,298,359]])
            case "jungle-turn-02": spec = (191, 102, [[157,139,39,62]], [[178,287,170,294],[253,283,193,311],[192,351,278,371]])
            case "jungle-turn-03": spec = (198, 109, [[149,143,18,47]], [[175,275,218,309],[218,309,145,350]])
            case "jungle-turn-04": spec = (161, 109, [], [[199,256,232,273],[279,273,322,248],[194,294,172,320],[309,295,336,321]])
            case "jungle-turn-05": spec = (158, 83, [], [[320,242,267,268],[267,268,310,314]])
            case "jungle-turn-06": spec = (166, 82, [[312,112,29,69]], [[285,253,321,266],[243,299,315,307]])
            case "jungle-turn-07": spec = (185, 102, [[260,126,52,65],[320,125,38,63]], [[268,283,308,300],[355,285,348,302],[213,349,298,355]])
            default: spec = (165, 96, [[174,121,40,71],[238,122,58,76]], [[175,264,204,287],[323,252,251,295],[162,330,306,350]])
            }
            leafBase = spec.1
            crownSeed = CGPoint(x:spec.2.isEmpty ? 235 : spec.2.map { $0[0]+$0[2]/2 }.reduce(0,+)/CGFloat(spec.2.count),y:spec.0-35)
            let gold = CGMutablePath(), ink = CGMutablePath(), clockFace = CGMutablePath(), clockRim = CGMutablePath()
            crown = CGPath(rect: CGRect(x: 0,y: 0,width: 512,height: spec.0),transform: nil)
            // Measured inner dials. Occluding hands are excluded separately.
            let dial: CGRect
            switch asset {
            case "jungle-crouch": dial = CGRect(x:176,y:350,width:75,height:79)
            case "jungle-takeoff": dial = CGRect(x:169,y:251,width:76,height:77)
            case "jungle-airborne": dial = CGRect(x:174,y:252,width:60,height:54)
            case "jungle-landing": dial = CGRect(x:204,y:360,width:75,height:73)
            case "jungle-recover": dial = CGRect(x:176,y:308,width:75,height:77)
            case "jungle-stumble": dial = CGRect(x:161,y:322,width:77,height:73)
            case "jungle-push-up": dial = CGRect(x:186,y:360,width:73,height:64)
            case "jungle-turn-01": dial = CGRect(x:164,y:269,width:82,height:82)
            case "jungle-turn-02": dial = CGRect(x:138,y:273,width:48,height:77)
            case "jungle-turn-03", "jungle-turn-04", "jungle-turn-05", "jungle-fallen": dial = .zero
            case "jungle-turn-06": dial = CGRect(x:317,y:267,width:47,height:81)
            case "jungle-turn-07": dial = CGRect(x:299,y:265,width:72,height:85)
            case "jungle-turn-08": dial = CGRect(x:153,y:268,width:80,height:82)
            case "jungle-clap-contact", "jungle-clap-contact-2": dial = CGRect(x:179,y:297,width:85,height:81)
            case DinoJungleArtwork.openingAsset: dial = CGRect(x:178,y:278,width:88,height:91)
            default: dial = CGRect(x:179,y:279,width:85,height:86)
            }
            if !dial.isEmpty {
                clockFace.addEllipse(in: dial)
                clockRim.addEllipse(in: dial.insetBy(dx: -11,dy: -10))
                // The suspension ring is one metal piece above the bezel.
                gold.addEllipse(in: CGRect(x:dial.midX-14,y:dial.minY-32,width:28,height:30))
            }
            let suspension = CGMutablePath()
            if ["jungle-idle","jungle-wrong","jungle-clap-open","jungle-clap-open-2","jungle-clap-contact","jungle-clap-contact-2",DinoJungleArtwork.openingAsset].contains(asset) {
                let center = CGPoint(x:dial.midX+5,y:dial.minY-19)
                suspension.addEllipse(in:CGRect(x:center.x-11,y:center.y-12,width:22,height:24))
                suspension.addEllipse(in:CGRect(x:center.x-6,y:center.y-7,width:12,height:14))
            }
            self.suspension = suspension
            if asset == "jungle-turn-03" { clockRim.addRect(CGRect(x:124,y:297,width:25,height:63)) }
            for eye in spec.2 {
                let rect = CGRect(x:eye[0],y:eye[1],width:eye[2],height:eye[3])
                ink.addEllipse(in: preciseGold ? rect : rect.insetBy(dx:rect.width*0.18,dy:rect.height*0.10))
            }
            for line in spec.3 {
                let strap = CGMutablePath()
                strap.move(to: CGPoint(x: line[0], y: line[1]))
                strap.addLine(to: CGPoint(x: line[2], y: line[3]))
                gold.addPath(strap.copy(strokingWithWidth: preciseGold ? 12 : 17, lineCap: .round, lineJoin: .round, miterLimit: 1))
            }
            // Palms and fingertips can cover the clock and its straps. Their
            // warm paint still belongs to the skin in every reaction pose.
            let palms: [[CGFloat]]
            switch asset {
            case "jungle-clap-open", "jungle-clap-open-2": palms = [[139,228,52,70],[273,228,48,74]]
            case "jungle-clap-contact", "jungle-clap-contact-2": palms = [[190,234,53,72]]
            case "jungle-crouch": palms = [[112,329,73,74],[269,333,67,72]]
            case "jungle-takeoff": palms = [[132,137,66,73],[336,161,66,67]]
            case "jungle-airborne": palms = [[143,190,49,62],[237,230,60,70],[123,272,68,78],[198,289,65,86]]
            case "jungle-landing": palms = [[142,325,64,66],[273,322,65,71]]
            case "jungle-recover": palms = [[113,290,74,74],[274,284,72,78]]
            case "jungle-stumble": palms = [[169,258,77,76]]
            default: palms = []
            }
            let skin = CGMutablePath()
            for palm in palms { skin.addRect(CGRect(x: palm[0], y: palm[1], width: palm[2], height: palm[3])) }
            let face = CGMutablePath()
            face.move(to:CGPoint(x:180,y:119))
            for point in [CGPoint(x:195,y:107),CGPoint(x:250,y:109),CGPoint(x:286,y:117),
                          CGPoint(x:316,y:139),CGPoint(x:336,y:166),CGPoint(x:337,y:202),
                          CGPoint(x:324,y:227),CGPoint(x:299,y:243),CGPoint(x:269,y:250),
                          CGPoint(x:221,y:249),CGPoint(x:183,y:238),CGPoint(x:153,y:219),
                          CGPoint(x:140,y:199),CGPoint(x:141,y:183),CGPoint(x:157,y:172),CGPoint(x:166,y:152)] { face.addLine(to:point) }
            face.closeSubpath()
            var registration = DinoJungleArtwork.headRegistration(for:asset)
            faceSkin = asset.hasPrefix("jungle-turn-") || asset == "jungle-fallen" ? CGMutablePath() : face.copy(using:&registration)!
            self.gold = gold; self.ink = ink; self.skin = skin; self.clockFace = clockFace; self.clockRim = clockRim
        }
    }

    /// The supplied head moves independently of the hands. Remove that head
    /// before caching the moving layer; DinoCharacter draws the exact idle head above it.
    /// Clear the painted gold accents too, so the view can animate its own soft ripples.
    static func applauseBody(_ colored: CGImage, original: CGImage, asset: String) -> CGImage? {
        guard asset.hasPrefix("dino-answer-clap-") else { return colored }
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
                // Classify the source rather than the personalized pixels: a
                // yellow Dino must keep its hands, including beside an accent.
                let paintedAccent = accents?.contains(CGPoint(x: px, y: py)) == true
                    && r > g * 0.92 && g > b * 1.15
                // Keep complete fingertips above the chin without retaining the
                // cream jaw or red mouth. Classify original green before recoloring.
                let fingers = py >= 550.0 / 1254 && (550.0 / 1254...950.0 / 1254).contains(px)
                    && g > r * 1.03 && g > b * 1.1
                if !paintedAccent && (py >= 650.0 / 1254 || fingers) { continue }
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
            let fallPalette = asset.hasPrefix("dino-result-fall-")
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
        let applause = DinoAnswerArtwork.clapAssets.dropFirst().map {
            ($0, CGRect(x: 500, y: 80, width: 300, height: 150))
        }
        return Dictionary(uniqueKeysWithValues: applause).merging([
            DinoAnswerArtwork.wrongAsset: CGRect(x: 555, y: 90, width: 280, height: 140)
        ]) { existing, _ in existing }
    }()

    static let deepFallLetteringBounds: [String: CGRect] = {
        let names = (1...10).map { String(format: "%02d", $0) }
        let bounds = [CGRect(x:545,y:90,width:285,height:150), CGRect(x:736,y:194,width:280,height:124),
                      CGRect(x:761,y:241,width:285,height:130), CGRect(x:855,y:512,width:290,height:142),
                      CGRect(x:794,y:600,width:292,height:135), CGRect(x:876,y:552,width:275,height:155),
                      CGRect(x:748,y:239,width:330,height:138), CGRect(x:685,y:198,width:300,height:146),
                      CGRect(x:545,y:87,width:290,height:150), CGRect(x:545,y:90,width:285,height:150)]
        return Dictionary(uniqueKeysWithValues: zip(names.map { "dino-result-fall-" + $0 }, bounds).dropFirst())
    }()

    private static let bandanaLetteringBounds: [String: CGRect] = [
        "dino-opening-jump-01": CGRect(x: 545, y: 90, width: 275, height: 135),
        "dino-opening-jump-02": CGRect(x: 688, y: 292, width: 290, height: 128),
        "dino-opening-jump-03": CGRect(x: 528, y: 74, width: 280, height: 134),
        "dino-opening-jump-04": CGRect(x: 543, y: 88, width: 275, height: 136),
        "dino-opening-jump-05": CGRect(x: 545, y: 87, width: 275, height: 135),
        "dino-opening-jump-06": CGRect(x: 580, y: 155, width: 280, height: 128),
        "dino-opening-jump-07": CGRect(x: 578, y: 191, width: 290, height: 138),
        "dino-opening-jump-08": CGRect(x: 545, y: 90, width: 275, height: 135),
        "dino-world-jump-crouch": CGRect(x: 552, y: 88, width: 243, height: 107),
        "dino-world-jump-takeoff": CGRect(x: 714, y: 270, width: 238, height: 105),
        "dino-world-jump-airborne": CGRect(x: 763, y: 237, width: 238, height: 110),
        "dino-world-jump-landing": CGRect(x: 679, y: 228, width: 240, height: 112),
        "dino-world-jump-recover": CGRect(x: 672, y: 311, width: 267, height: 111),
        "dino-result-pirouette-01": CGRect(x: 580, y: 150, width: 252, height: 105),
        "dino-result-pirouette-02": CGRect(x: 696, y: 207, width: 243, height: 90),
        "dino-result-pirouette-03": CGRect(x: 681, y: 157, width: 220, height: 104),
        "dino-result-pirouette-04": CGRect(x: 700, y: 135, width: 195, height: 100),
        "dino-result-pirouette-11": CGRect(x: 392, y: 165, width: 60, height: 62),
        "dino-result-pirouette-12": CGRect(x: 350, y: 139, width: 155, height: 94),
        "dino-result-pirouette-13": CGRect(x: 390, y: 120, width: 195, height: 117),
        "dino-result-pirouette-14": CGRect(x: 439, y: 203, width: 231, height: 120),
        "dino-result-pirouette-15": CGRect(x: 433, y: 208, width: 246, height: 109),
        "dino-result-pirouette-16": CGRect(x: 568, y: 161, width: 245, height: 83),
        "dino-result-pirouette-17": CGRect(x: 559, y: 112, width: 236, height: 104),
        "dino-result-pirouette-18": CGRect(x: 560, y: 118, width: 246, height: 110),
        "dino-idle": CGRect(x: 550, y: 90, width: 238, height: 106),
        "dino-result-backflip-crouch": CGRect(x: 702, y: 205, width: 258, height: 98),
        "dino-result-backflip-airborne": CGRect(x: 326, y: 131, width: 210, height: 160),
        "dino-result-backflip-landing": CGRect(x: 638, y: 233, width: 256, height: 106),
        "dino-result-backflip-recover": CGRect(x: 520, y: 102, width: 237, height: 109)
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
        "dino-answer-wrong": [Tone(0.31028, 0.51581, 0.56917, 0.93043), Tone(0.10870, 0.19763, 0.36561, 0.47264), Tone(0.25889, 0.41700, 0.54941, 0.59184), Tone(0.60672, 0.81225, 0.89921, 0.69565)],
    ]
    private static let palettes: [String: [Tone]] = [
        "dino-answer-clap-01": [Tone(0.34325, 0.52767, 0.62205, 0.90950), Tone(0.09921, 0.18924, 0.35573, 0.58140), Tone(0.27075, 0.42292, 0.53360, 0.61345), Tone(0.55138, 0.75889, 0.86759, 0.59322)],
        "dino-answer-clap-02": [Tone(0.33730, 0.52778, 0.61858, 0.91189), Tone(0.10474, 0.19763, 0.37698, 0.55556), Tone(0.26680, 0.42688, 0.54348, 0.61086), Tone(0.53175, 0.74704, 0.86759, 0.57025)],
        "dino-answer-clap-03": [Tone(0.34387, 0.52767, 0.63439, 0.90717), Tone(0.10359, 0.19721, 0.35968, 0.55556), Tone(0.27273, 0.41897, 0.53953, 0.61039), Tone(0.56972, 0.77075, 0.86364, 0.62162)],
        "dino-answer-clap-04": [Tone(0.33992, 0.52590, 0.61660, 0.91379), Tone(0.09325, 0.18254, 0.34921, 0.57895), Tone(0.26482, 0.43083, 0.52767, 0.60870), Tone(0.55336, 0.76285, 0.86561, 0.59649)],
        "dino-answer-clap-05": [Tone(0.33992, 0.53162, 0.63294, 0.91000), Tone(0.10672, 0.19246, 0.33399, 0.57009), Tone(0.26389, 0.43281, 0.53162, 0.61017), Tone(0.55159, 0.76285, 0.86561, 0.60000)],
        "dino-answer-clap-06": [Tone(0.34190, 0.53162, 0.62451, 0.91262), Tone(0.09684, 0.19170, 0.36653, 0.56989), Tone(0.27075, 0.42688, 0.52964, 0.61086), Tone(0.57708, 0.77866, 0.86166, 0.63793)],
        "dino-result-pirouette-07": [Tone(0.31818, 0.50198, 0.56126, 0.90598), Tone(0.12846, 0.22925, 0.32609, 0.42169), Tone(0.24704, 0.39328, 0.49407, 0.59596), Tone(0.58135, 0.67787, 0.79365, 0.46914)],
        "dino-result-pirouette-09": [Tone(0.33794, 0.49209, 0.56917, 0.90909), Tone(0.16206, 0.25099, 0.38889, 0.36691), Tone(0.25000, 0.39526, 0.50395, 0.56190), Tone(0.60980, 0.69565, 0.80237, 0.51190)],
        "dino-result-pirouette-11": [Tone(0.36561, 0.51976, 0.56746, 0.91228), Tone(0.15613, 0.24506, 0.38538, 0.38843), Tone(0.30159, 0.46047, 0.54348, 0.53509), Tone(0.63834, 0.76181, 0.86166, 0.62295)],
        "dino-result-pirouette-14": [Tone(0.29842, 0.52174, 0.58498, 0.94470), Tone(0.11706, 0.22134, 0.40316, 0.42342), Tone(0.27668, 0.44466, 0.54348, 0.55745), Tone(0.63834, 0.77470, 0.88340, 0.64602)],
        "dino-opening-jump-01": [Tone(0.31225, 0.53162, 0.57510, 0.95575), Tone(0.10870, 0.20158, 0.39961, 0.55056), Tone(0.27075, 0.43849, 0.57115, 0.62771), Tone(0.62846, 0.82806, 0.90514, 0.75281)],
        "dino-opening-jump-02": [Tone(0.31818, 0.53162, 0.57115, 0.94760), Tone(0.11508, 0.20319, 0.43849, 0.50909), Tone(0.25296, 0.42292, 0.55159, 0.59664), Tone(0.58498, 0.78854, 0.88583, 0.64151)],
        "dino-opening-jump-03": [Tone(0.32411, 0.51976, 0.56522, 0.94845), Tone(0.12253, 0.20553, 0.46245, 0.53043), Tone(0.27668, 0.42688, 0.54941, 0.61290), Tone(0.63439, 0.81818, 0.89723, 0.75472)],
        "dino-opening-jump-04": [Tone(0.31621, 0.51581, 0.56471, 0.93443), Tone(0.10474, 0.19048, 0.36667, 0.47619), Tone(0.25692, 0.41897, 0.55336, 0.60976), Tone(0.61265, 0.81028, 0.90000, 0.68932)],
        "dino-opening-jump-05": [Tone(0.30237, 0.51186, 0.57480, 0.93407), Tone(0.12055, 0.20200, 0.40392, 0.47826), Tone(0.27866, 0.42460, 0.54348, 0.60360), Tone(0.60079, 0.81423, 0.89723, 0.70370)],
        "dino-opening-jump-06": [Tone(0.30830, 0.50593, 0.55754, 0.93833), Tone(0.11155, 0.18254, 0.35771, 0.49495), Tone(0.25692, 0.42490, 0.55336, 0.60577), Tone(0.59486, 0.77668, 0.88583, 0.63478)],
        "dino-opening-jump-07": [Tone(0.31818, 0.52372, 0.57341, 0.94760), Tone(0.12055, 0.19960, 0.37450, 0.48276), Tone(0.24506, 0.42095, 0.55929, 0.61739), Tone(0.61462, 0.78854, 0.88735, 0.66667)],
        "dino-opening-jump-08": [Tone(0.29249, 0.51186, 0.56719, 0.94760), Tone(0.10474, 0.18972, 0.38340, 0.51020), Tone(0.25099, 0.41107, 0.54150, 0.61607), Tone(0.60672, 0.81496, 0.89370, 0.72043)],
        "dino-result-pirouette-01": [Tone(0.22727, 0.50198, 0.57371, 0.93548), Tone(0.10672, 0.19565, 0.36508, 0.51163), Tone(0.23320, 0.40316, 0.54348, 0.61386), Tone(0.59881, 0.80040, 0.89921, 0.68317)],
        "dino-result-pirouette-02": [Tone(0.26087, 0.52174, 0.57312, 0.94048), Tone(0.10277, 0.19763, 0.39921, 0.48571), Tone(0.25692, 0.42885, 0.56151, 0.56731), Tone(0.62598, 0.80632, 0.90157, 0.67619)],
        "dino-result-pirouette-03": [Tone(0.27559, 0.51581, 0.57341, 0.94819), Tone(0.09486, 0.18775, 0.33597, 0.47500), Tone(0.28854, 0.44071, 0.56471, 0.54386), Tone(0.62648, 0.77866, 0.88538, 0.63158)],
        "dino-result-pirouette-04": [Tone(0.30237, 0.50791, 0.56917, 0.90638), Tone(0.09684, 0.18182, 0.34127, 0.50562), Tone(0.27668, 0.43056, 0.54150, 0.57282), Tone(0.61462, 0.75296, 0.88189, 0.59664)],
        "dino-result-pirouette-05": [Tone(0.28770, 0.49012, 0.56324, 0.93103), Tone(0.09486, 0.19643, 0.31818, 0.57282), Tone(0.26877, 0.42885, 0.52964, 0.60976), Tone(0.60079, 0.71542, 0.85771, 0.53741)],
        "dino-result-pirouette-06": [Tone(0.28656, 0.49803, 0.56324, 0.94737), Tone(0.08103, 0.19170, 0.30512, 0.54286), Tone(0.24308, 0.42490, 0.52569, 0.63235), Tone(0.58103, 0.70158, 0.84190, 0.56579)],
        "dino-result-pirouette-08": [Tone(0.31818, 0.46640, 0.56126, 0.91489), Tone(0.13636, 0.23913, 0.35573, 0.45455), Tone(0.25099, 0.38735, 0.51383, 0.61194), Tone(0.65020, 0.70553, 0.79644, 0.49515)],
        "dino-result-pirouette-10": [Tone(0.34722, 0.50000, 0.56863, 0.91579), Tone(0.14427, 0.23715, 0.38142, 0.41791), Tone(0.28571, 0.43281, 0.52964, 0.55251), Tone(0.65217, 0.75494, 0.84585, 0.60000)],
        "dino-result-pirouette-12": [Tone(0.29842, 0.50000, 0.57312, 0.92275), Tone(0.10474, 0.19960, 0.34325, 0.50877), Tone(0.26877, 0.43083, 0.52372, 0.58744), Tone(0.57510, 0.71344, 0.86759, 0.54667)],
        "dino-result-pirouette-13": [Tone(0.31423, 0.49802, 0.57708, 0.93860), Tone(0.11265, 0.22727, 0.35913, 0.48276), Tone(0.27470, 0.44269, 0.53162, 0.56731), Tone(0.60474, 0.73320, 0.86220, 0.56716)],
        "dino-result-pirouette-15": [Tone(0.27470, 0.50395, 0.57708, 0.93013), Tone(0.10672, 0.19763, 0.48617, 0.51111), Tone(0.22332, 0.40316, 0.53162, 0.62051), Tone(0.59449, 0.79249, 0.89130, 0.68224)],
        "dino-result-pirouette-16": [Tone(0.25692, 0.52372, 0.58498, 0.93043), Tone(0.14625, 0.23214, 0.43676, 0.45455), Tone(0.26680, 0.43478, 0.55138, 0.59111), Tone(0.63834, 0.82016, 0.89921, 0.76344)],
        "dino-result-pirouette-17": [Tone(0.27273, 0.52569, 0.58893, 0.94444), Tone(0.11067, 0.19960, 0.38690, 0.52239), Tone(0.28854, 0.42490, 0.55336, 0.60909), Tone(0.61660, 0.82213, 0.90316, 0.75000)],
        "dino-result-pirouette-18": [Tone(0.26389, 0.50198, 0.58498, 0.89076), Tone(0.10913, 0.20040, 0.50198, 0.51685), Tone(0.25889, 0.39130, 0.51383, 0.66990), Tone(0.59486, 0.80632, 0.88340, 0.76238)],
        "dino-result-backflip-crouch": [Tone(0.27470, 0.49405, 0.57510, 0.91379), Tone(0.09881, 0.17787, 0.37698, 0.58824),
                              Tone(0.24008, 0.39328, 0.52569, 0.64286), Tone(0.56719, 0.76482, 0.86811, 0.61739)],
        "dino-result-backflip-airborne": [Tone(0.27470, 0.46627, 0.58300, 0.91919), Tone(0.08167, 0.16733, 0.31621, 0.53191),
                              Tone(0.26285, 0.39526, 0.55138, 0.63359), Tone(0.56324, 0.70751, 0.89723, 0.52866)],
        "dino-result-backflip-landing": [Tone(0.26087, 0.50000, 0.57708, 0.93249), Tone(0.11660, 0.21765, 0.41304, 0.56098),
                              Tone(0.23913, 0.40119, 0.53557, 0.65487), Tone(0.54941, 0.75889, 0.87945, 0.65574)],
        "dino-result-backflip-recover": [Tone(0.25494, 0.48024, 0.56471, 0.90698), Tone(0.08929, 0.17729, 0.37352, 0.59259),
                              Tone(0.23518, 0.36759, 0.49012, 0.67045), Tone(0.55336, 0.79249, 0.87795, 0.74074)],
    ]
}

extension DinoSpriteColorRenderer {
    /// Geometry is measured in the 443.5px sheet cells, then mapped to normalized
    /// source coordinates. Raster labels are cached independently of color choices.
    struct DesertRig {
        var headDX = 0.0, headDY = 0.0, headScale = 1.0
        var dy = 0.0397
        var dx = 0.0
        var clock = CGRect(x: 211, y: 222, width: 100, height: 112)
        var eyes: [CGRect] = [CGRect(x:84,y:88,width:39,height:61), CGRect(x:148,y:89,width:51,height:70)]
        var dorsal: [(Double,Double)] = [(234,39),(239,80),(240,152),(227,191),(250,209),(284,244),(311,289),(350,293),(366,244),(341,168),(289,67)]
        var belly: [(Double,Double)] = [(157,252),(191,247),(213,278),(205,324),(188,366),(143,369),(113,352),(102,308)]
        var hands: [CGRect] = []
        var toes: [CGRect] = [CGRect(x:83,y:379,width:72,height:35),CGRect(x:173,y:383,width:62,height:35),CGRect(x:266,y:377,width:70,height:35)]
        var rear = false
        var flip = false
        var hasClock = true
        var dorsalLeftCount = 7
        var isTurn = false
        var frontRockPoints: [(Double,Double)]? = nil
        var tailStemPoints: [(Double,Double)]? = nil
        var tailClub = CGRect(x:351,y:234,width:80,height:95)
        var scarfTop = 185.0, scarfBottom = 335.0
        var chinPoints: [(Double,Double)]? = nil
        var scarfPoints: [(Double,Double)]? = nil
        var brows: [CGRect] = []
        var mouthPoints: [(Double,Double)]? = nil
        var harness: [[(Double,Double)]] = [
            [(197,226),(209,219),(214,276),(198,286)],
            [(315.3,283.2),(343.9,297.9),(343.9,314.4),(317,299.7)]
        ]
        init(asset: String) {
            let name = DinoDesertArtwork.asset(for: asset)
            switch name {
            case "desert-idle", "desert-opening-idle": dy = 0.0333
            case "desert-crouch":
                tailClub = CGRect(x:350,y:210,width:100,height:125)
                harness = [[(226,244),(242,245),(252,286),(239,302)],[(319,278),(355,290),(358,317),(321,311)]]
                scarfTop = 210; scarfBottom = 345
                headDX = -6; headDY = 28; headScale = 0.95
                eyes = [CGRect(x:79,y:111,width:34,height:54),CGRect(x:141,y:112,width:46,height:61)]
                clock = CGRect(x:239,y:228,width:87,height:104)
                hands = [CGRect(x:26,y:263,width:82,height:47),CGRect(x:130,y:280,width:83,height:57)]
                belly = [(111,300),(156,314),(211,321),(215,364),(173,390),(119,373),(94,342)]
            case "desert-landing":
                harness = [[(212,229),(227,220),(236,270),(220,283)],[(319,272),(349,284),(352,308),(318,302)]]
                headDX = 10; headDY = -7; headScale = 0.95
                eyes = [CGRect(x:94,y:79,width:33,height:54),CGRect(x:157,y:83,width:43,height:64)]
                clock = CGRect(x:230,y:228,width:97,height:100)
                hands = [CGRect(x:29,y:270,width:77,height:49),CGRect(x:134,y:279,width:73,height:58)]
            case "desert-wrong":
                hands = [CGRect(x:27,y:228,width:75,height:68),CGRect(x:156,y:230,width:76,height:79)]
            case "desert-clap-open", "desert-clap-open-2":
                hands = [CGRect(x:38,y:213,width:78,height:91),CGRect(x:134,y:215,width:73,height:92)]
            case "desert-clap-contact", "desert-clap-contact-2":
                hands = [CGRect(x:86,y:214,width:93,height:102)]
            case "desert-takeoff":
                frontRockPoints = [(243.4,59.2),(265.1,50.5),(280.6,48.8),(283.3,68.7),(272.9,89.5),(265.9,98.2),(259,75.6)]
                dorsalLeftCount = 5; tailClub = CGRect(x:327,y:286,width:80,height:75)
                harness = [[(202,221),(215,217),(215,280),(201,286)],[(289,289),(304,289),(303,306),(291,303)]]
                scarfTop = 170; scarfBottom = 285
                dy = 0.015; headDX = 45; headDY = -26; headScale = 0.95
                eyes = [CGRect(x:132,y:56,width:35,height:45),CGRect(x:182,y:60,width:41,height:59)]
                clock = CGRect(x:212,y:227,width:78,height:96)
                dorsal = [(264,43),(265,112),(252,169),(294,205),(298,294),(341,291),(346,203),(310,97)]
                hands = [CGRect(x:43,y:145,width:94,height:85),CGRect(x:236,y:143,width:89,height:92)]
                belly = [(130,231),(187,232),(220,253),(220,320),(193,358),(139,337),(119,282)]
                toes = [CGRect(x:150,y:377,width:57,height:39),CGRect(x:220,y:385,width:68,height:39)]
            case "desert-airborne":
                frontRockPoints = [(294.5,80.8),(317.8,79.1),(336.9,82.6),(331.7,102.5),(317.8,121.5),(304.9,125)]
                dorsalLeftCount = 5; tailClub = CGRect(x:175,y:340,width:70,height:85)
                harness = []
                scarfTop = 160; scarfBottom = 250
                dy = 0.015; headDX = 77; headDY = -24; headScale = 0.94
                eyes = []; clock = CGRect(x:244,y:216,width:69,height:106)
                dorsal = [(283,43),(290,112),(282,169),(303,208),(313,300),(354,302),(371,201),(335,90)]
                belly = [(132,236),(203,228),(249,276),(239,333),(214,357),(155,350),(116,304)]
                hands = [CGRect(x:66,y:176,width:91,height:67),CGRect(x:155,y:195,width:99,height:72)]
                toes = [CGRect(x:65,y:244,width:153,height:97)]
            case "desert-stumble":
                frontRockPoints = [(245,111),(268,100),(290,100),(290,120),(276,146),(268,156),(260,132)]
                dorsalLeftCount = 6; tailClub = CGRect(x:347,y:268,width:90,height:85)
                chinPoints = [(109,219),(129,232),(158,235),(186,224),(194,210),(208,201),(224,208),(227,222),(214,239),(193,252),(155,258),(127,248)]
                harness = []
                scarfTop = 220; scarfBottom = 350
                dy = 0.004; headDX = 34; headDY = 46; headScale = 0.95
                eyes = [CGRect(x:115,y:127,width:34,height:47),CGRect(x:173,y:132,width:44,height:58)]
                clock = CGRect(x:246,y:260,width:84,height:98)
                hands = [CGRect(x:2,y:211,width:106,height:82),CGRect(x:117,y:249,width:105,height:72)]
                belly = [(141,316),(199,309),(239,350),(224,388),(167,382),(134,350)]
                toes = [CGRect(x:86,y:350,width:69,height:44),CGRect(x:284,y:397,width:68,height:33)]
                dorsal = [(262,105),(271,170),(264,210),(280,253),(316,282),(345,310),(373,300),(352,207),(302,115)]
            case "desert-fallen":
                tailStemPoints = [(318,365),(341,324),(351,293),(374,289),(391,304),(376,346),(338,381)]
                dorsalLeftCount = 5; tailClub = CGRect(x:330,y:228,width:85,height:82)
                chinPoints = [(98,299),(120,309),(143,320),(169,321),(190,308),(197,291),(193,280),(204,273),(220,279),(226,294),(218,316),(202,332),(175,340),(137,337),(112,329)]
                harness = [[(305.7,317.9),(334.3,319.7),(337.8,333.5),(309.2,331.8)],[(280.6,395.8),(251.2,417.4),(243.4,412.4),(264.2,389)]]
                scarfTop = 295; scarfBottom = 425
                dy = -0.004; headDX = 11; headDY = 134; headScale = 0.9
                eyes = [CGRect(x:88,y:215,width:37,height:49),CGRect(x:145,y:219,width:46,height:61)]
                clock = CGRect(x:250,y:303,width:80,height:85)
                hands = [CGRect(x:16,y:386,width:171,height:49)]
                toes = [CGRect(x:362,y:359,width:73,height:53)]
                dorsal = [(224,151),(232,216),(229,259),(251,296),(330,306),(346,263),(305,182)]
            case "desert-push-up":
                tailStemPoints = [(310,326),(332,291),(350,254),(369,237),(391,246),(383,278),(358,320),(321,344)]
                dorsalLeftCount = 5; tailClub = CGRect(x:340,y:180,width:80,height:82)
                chinPoints = [(60,231),(83,245),(120,253),(161,249),(181,235),(188,215),(178,202),(159,204),(155,219),(137,235),(109,237),(87,230)]
                harness = [[(315.7,259.7),(341.7,267.5),(344.3,279.7),(319.2,275.3)],[(287.1,329.9),(260.3,364.6),(252.5,369.7),(249.9,360.1),(275,329.9)]]
                scarfTop = 220; scarfBottom = 360
                dy = 0.055; dx = -0.04; headDX = -13; headDY = 57; headScale = 0.96
                eyes = [CGRect(x:62,y:132,width:38,height:54),CGRect(x:120,y:137,width:48,height:62)]
                clock = CGRect(x:220,y:239,width:91,height:103)
                hands = [CGRect(x:22,y:361,width:215,height:63)]
                dorsal = [(214,88),(222,155),(219,205),(249,233),(302,297),(335,290),(321,202),(264,109)]
            case let n where n.hasPrefix("desert-turn-"):
                dy = 0.025
                isTurn = true
                let i = Int(n.suffix(2)) ?? 1
                dy = [0.035,0.043,0.043,0.045,0.041,0.041,0.035,0.035][i-1]
                flip = (5...7).contains(i)
                hasClock = i <= 3 || i == 8
                headDX = -15; headDY = 22; headScale = 0.9
                clock = CGRect(x:195,y:231,width:99,height:108)
                dorsal = [(210,58),(215,124),(207,182),(221,213),(242,226),(270,255),(294,295),(344,295),(354,240),(313,136),(256,64)]
                belly = [(104,260),(154,244),(191,251),(208,284),(184,369),(140,369),(105,342)]
                if i == 2 || i == 6 {
                    frontRockPoints = [(184,100),(211,81),(239,65),(246,90),(237,116),(219,138),(204,119),(196,110)]
                    dorsalLeftCount = 6
                    belly = [(102,281),(145,286),(162,323),(154,363),(127,376),(105,351)]
                    eyes = [CGRect(x:92,y:101,width:38,height:61)]
                    headDX = -10; headDY = 17; headScale = 0.94
                    clock = CGRect(x:121,y:235,width:99,height:111)
                    harness = [[(240,278),(299,293),(302,316),(244,303)]]
                    dorsal = [(206,67),(203,128),(185,187),(218,208),(257,252),(296,300),(351,302),(352,229),(306,120),(250,75)]
                }
                if i == 3 || i == 5 {
                    dorsalLeftCount = 6; tailClub = CGRect(x:276,y:220,width:102,height:120)
                    belly = [(171,319),(215,330),(275,316),(279,350),(238,373),(184,366)]
                    eyes = []; headDX = 70; headDY = 16; headScale = 0.9
                    clock = CGRect(x:93,y:234,width:53,height:107)
                    dorsal = [(165,65),(157,125),(166,168),(153,215),(177,257),(221,299),(286,310),(335,286),(350,228),(310,129),(238,62)]
                }
                if i == 3 || i == 5 {
                    harness = [[(143,285),(214,300),(218,321),(143,306)]]
                    belly = [(200,348),(249,347),(296,328),(326,312),(319,348),(279,372),(235,373),(202,363)]
                }
                if i == 6 || i == 7 {
                    belly = i == 6 ? [(128.5,307),(110.5,303),(107.5,329),(117.5,352),(130.5,360)] : [(144.5,273),(103.5,290),(113.5,344),(142.5,365),(162.5,360),(166.5,333)]
                    harness = i == 6 ? [[(296.5,297),(179.5,231),(158.5,233),(159.5,249),(280.5,319),(290.5,318)]] : [[(322.5,286),(222.5,220),(204.5,227),(207.5,239),(315.5,309),(322.5,302)]]
                }
                if i == 4 {
                    harness = [[(135,230),(152,262),(152,300),(139,314),(118,270)],[(303,230),(285,264),(285,302),(302,316),(323,272)]]
                    rear = true; eyes = []; headDX = 80
                    dorsal = [(153,87),(288,87),(325,228),(290,283),(250,304),(196,303),(154,277),(123,220)]
                }
                if i == 1 || i == 8 {
                    let shift = i == 8 ? 20.0 : 0
                    frontRockPoints = [(183,97),(196,77),(223,57),(230,77),(227,113),(213,135),(205,118),(196,103)].map { ($0.0+shift,$0.1) }
                }
                if i == 7 {frontRockPoints = [(184,100),(211,81),(239,65),(246,90),(237,116),(219,138),(204,119),(196,110)]}
                if i == 8 { headDX = 0; headDY = 12; headScale = 0.97; clock = CGRect(x:221,y:237,width:101,height:109) }

            default: break
            }
            // Trace the painted cream seam in each moving source. Its shaded
            // edge belongs to the same material as the bright cheek; a per-pixel
            // cream threshold left blue flecks along this curved boundary.
            let chinContour: [(Double,Double)]?
            switch name {
            case "desert-push-up":
                chinContour = [(158,269),(173,267),(187,273),(198,286),(201,300),(196,313),(181,325),(159,333),(133,338),(104,338),(81,335),(59,328),(42,318),(30,304),(47,311),(66,316),(91,320),(116,318),(137,307),(149,291),(158,279)]
            case "desert-fallen":
                chinContour = [(184,328),(198,326),(212,332),(222,344),(225,357),(217,370),(201,380),(176,388),(150,393),(124,392),(99,389),(77,381),(62,372),(55,360),(80,369),(107,376),(139,377),(162,370),(177,356),(184,340)]
            case "desert-stumble":
                chinContour = [(233,243),(247,243),(260,251),(268,264),(269,278),(259,289),(239,298),(213,302),(190,301),(171,297),(150,290),(134,278),(156,284),(177,285),(204,281),(223,271),(232,257)]
            default: chinContour = nil
            }
            if let chinContour {
                chinPoints = chinContour.map { (($0.0 / 512 - dx) * 443.5, ($0.1 / 512 - dy) * 443.5) }
            }
            func cell(_ points: [(Double,Double)]) -> [(Double,Double)] {
                points.map { (($0.0 / 512 - dx) * 443.5, ($0.1 / 512 - dy) * 443.5) }
            }
            func cellRect(_ r: CGRect) -> CGRect {
                CGRect(x:(r.minX/512-dx)*443.5,y:(r.minY/512-dy)*443.5,width:r.width/512*443.5,height:r.height/512*443.5)
            }
            switch name {
            case "desert-fallen":
                belly = cell([(234,404),(258,407),(266,435),(249,453),(220,453),(206,435)])
                scarfPoints = cell([(96,391),(141,397),(184,390),(219,374),(242,354),(252,339),(261,347),(265,365),(257,385),(238,405),(212,424),(193,433),(194,476),(179,490),(126,486),(121,446),(109,429),(96,416)])
                mouthPoints = cell([(103,363),(110,353),(124,347),(140,347),(154,350),(164,361),(162,369),(141,371),(121,371)])
                toes = [CGRect(x:447,y:434,width:31,height:30),CGRect(x:448,y:461,width:27,height:26),CGRect(x:27,y:469,width:30,height:27),CGRect(x:55,y:463,width:28,height:30),CGRect(x:83,y:470,width:30,height:27),CGRect(x:174,y:469,width:28,height:28),CGRect(x:204,y:465,width:30,height:31),CGRect(x:233,y:469,width:32,height:29)].map(cellRect)
                brows = [cellRect(CGRect(x:76,y:234,width:48,height:26)),cellRect(CGRect(x:150,y:233,width:51,height:25))]
                hands = [cellRect(CGRect(x:26,y:458,width:91,height:45)),cellRect(CGRect(x:169,y:458,width:99,height:47))]
            case "desert-push-up":
                belly = cell([(175,374),(204,369),(212,405),(208,435),(189,447),(174,428)])
                scarfPoints = cell([(77,336),(124,341),(169,334),(207,316),(232,289),(241,275),(250,287),(258,303),(254,321),(231,345),(208,362),(176,380),(174,434),(151,445),(132,435),(129,389),(108,386),(86,369)])
                mouthPoints = cell([(79,301),(88,294),(104,292),(119,295),(128,302),(125,310),(112,315),(97,315),(84,310)])
                brows = [cellRect(CGRect(x:52,y:180,width:37,height:24)),cellRect(CGRect(x:121,y:181,width:59,height:25))]
            case "desert-stumble":
                scarfPoints = cell([(150,302),(191,307),(231,299),(266,283),(288,265),(297,268),(308,285),(307,304),(282,325),(249,342),(207,350),(215,388),(200,401),(165,395),(158,370),(139,378),(126,365),(130,347),(143,334)])
                mouthPoints = cell([(148,271),(156,260),(171,251),(188,251),(203,259),(212,273),(210,278),(178,278),(154,277)])
                brows = [cellRect(CGRect(x:137,y:149,width:39,height:27)),cellRect(CGRect(x:216,y:150,width:43,height:32))]
            default: break
            }
            if !rear {
                let chain = Array(dorsal.prefix(dorsalLeftCount))
                dorsal = [(chain[0].0,0)] + chain + [(500,chain.last!.1),(500,0)]
            }
        }
        func point(_ x: Double, _ y: Double, head: Bool = false) -> CGPoint {
            CGPoint(x:(flip ? 443.5 - (head ? x * headScale + headDX : x) : (head ? x * headScale + headDX : x))/443.5 + dx,
                    y:(head ? y * headScale + headDY : y)/443.5 + dy)
        }
        func polygon(_ points: [(Double,Double)], head: Bool = false) -> CGPath {
            let p=CGMutablePath();p.addLines(between:points.map { point($0.0,$0.1,head:head) });p.closeSubpath();return p
        }
        func ellipse(_ r: CGRect, head: Bool = false) -> CGPath {
            let p=CGMutablePath(); let a=point(r.minX,r.minY,head:head), b=point(r.maxX,r.maxY,head:head)
            p.addEllipse(in:CGRect(x:min(a.x,b.x),y:min(a.y,b.y),width:abs(b.x-a.x),height:abs(b.y-a.y))); return p
        }
        var head: CGPath { polygon([(0,0),(235,0),(242,72),(242,117),(244,154),(234,181),(216,202),(185,213),(144,213),(106,205),(70,187),(0,182)],head:true) }
        var frontRock: CGPath {
            if let frontRockPoints {return polygon(frontRockPoints)}
            if isTurn {return CGMutablePath()}
            return polygon([(202,61),(210,52),(240,40),(249,56),(248,83),(238,109),(233,99),(224,80),(212,68)],head:true)
        }
        var scarf: CGPath {
            if let scarfPoints {return polygon(scarfPoints)}
            let path=CGMutablePath()
            path.addPath(polygon([(101,209),(150,216),(191,202),(225,184),(241,193),(247,212),(233,234),(207,247),(171,257),(126,264),(103,258),(96,245),(97,227)],head:true))
            path.addPath(polygon([(104,255),(154,255),(161,320),(106,320)],head:true))
            return path
        }
        var chin: CGPath { if let chinPoints {return polygon(chinPoints)};return polygon([(45,158),(95,158),(150,150),(215,145),(230,175),(218,204),(183,220),(140,224),(100,218),(66,200)],head:true) }
        var horns: [CGPath] { [polygon([(103,24),(132,20),(151,71),(143,91),(121,98),(107,82)],head:true),polygon([(155,58),(164,12),(187,8),(205,54),(201,70),(180,76)],head:true)] }
    }

    private final class DesertLabels: NSObject { let labels:[UInt8]; init(_ labels:[UInt8]) {self.labels=labels} }
    private static let desertMaskCache: NSCache<NSString,DesertLabels> = {
        let c=NSCache<NSString,DesertLabels>();c.totalCostLimit=24*1024*1024;return c
    }()
    /// Labels: 0 protected, 1 cloth, 2 decoration, 3 skin, 4 cream, 5 leather/metal.
    static func desertLabels(_ source: CGImage, asset: String) -> [UInt8] {
        let key="desert-\(asset)-\(source.width)-\(source.height)" as NSString
        if let cached=desertMaskCache.object(forKey:key) {return cached.labels}
        let w=source.width,h=source.height,rig=DesertRig(asset:asset)
        var bytes=[UInt8](repeating:0,count:w*h*4), labels=[UInt8](repeating:0,count:w*h)
        let format=CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        let dorsal=rig.polygon(rig.dorsal), belly=rig.polygon(rig.belly), chin=rig.chin
        let head=rig.head, cloth=rig.scarf, tailClub=rig.ellipse(rig.tailClub), frontRock=rig.frontRock
        let rearClub=rig.ellipse(CGRect(x:176,y:231,width:102,height:103))
        let rearBelly=rig.ellipse(CGRect(x:165,y:289,width:117,height:97))
        let torsoCreamZone = rig.polygon([(65,220),(245,220),(255,420),(60,420)])
        let tailStem = rig.polygon(rig.tailStemPoints ?? [(321,350),(338,312),(360,285),(382,272),(410,290),(388,332),(349,365)])
        let eyes=rig.eyes.map {rig.ellipse($0)}, palms=rig.hands.map {rig.ellipse($0)}, toes=rig.toes.map {rig.ellipse($0)}
        let harness=rig.harness.map {rig.polygon($0)}
        let metal = [rig.ellipse(CGRect(x:rig.clock.midX-31,y:rig.clock.minY-25,width:30,height:28)),rig.ellipse(CGRect(x:rig.clock.midX-2,y:rig.clock.maxY-5,width:20,height:22))]
        bytes.withUnsafeMutableBytes { b in
            let c=CGContext(data:b.baseAddress,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:format)!
            c.draw(source,in:CGRect(x:0,y:0,width:w,height:h))
            let pixels=b.bindMemory(to:UInt8.self)
            let clockMatte = rig.hasClock ? desertClockMatte(pixels,width:w,height:h,rig:rig) : [UInt8](repeating:0,count:w*h)
            let hornMatte = desertClockMatte(pixels,width:w,height:h,rig:rig,isHorn:true)
            var harnessMatte=[UInt8](repeating:0,count:w*h)
            for region in harness {
                let part=desertClockMatte(pixels,width:w,height:h,rig:rig,harnessRegion:region,excluding:clockMatte)
                for n in part.indices where part[n]>0 {harnessMatte[n]=1}
            }
            for n in 0..<w*h {
                let i=n*4,a=Double(pixels[i+3])/255
                guard a>0 else {continue}
                let color=HSL(red:Double(pixels[i])/255/a,green:Double(pixels[i+1])/255/a,blue:Double(pixels[i+2])/255/a)
                let p=CGPoint(x:(Double(n%w)+0.5)/Double(w),y:(Double(n/w)+0.5)/Double(h))
                let hand=palms.contains {$0.contains(p)}
                if (eyes.contains(where:{$0.contains(p)}) && (color.saturation<0.22 || color.lightness<0.52)) || color.lightness<0.15 || (rig.mouthPoints.map({rig.polygon($0).contains(p)}) == true) || (rig.brows.contains(where:{rig.ellipse($0).contains(p)}) && color.hue<0.11 && color.lightness<0.66) {continue}
                if head.contains(p), color.hue<0.065, color.saturation>0.35, color.lightness<0.55, p.y>rig.point(0,130,head:true).y, Double(pixels[i+1])/max(1,Double(pixels[i]))<0.45 {continue}
                if clockMatte[n] == 1, !hand {continue}
                var label: UInt8=3
                if dorsal.contains(p) || frontRock.contains(p) || hornMatte[n]>0 {label=2}
                if tailClub.contains(p) || (tailStem.contains(p) && !asset.contains("turn-") && asset != "desert-airborne") {label=3}
                // Geometry limits the material, chromaticity snaps only its edge
                // to the actual painted cream seam. This includes all relative
                // cream shadows and avoids classifying bright skin as a new material.
                let r=Double(pixels[i])/max(1,Double(pixels[i+3])), g=Double(pixels[i+1])/max(1,Double(pixels[i+3])), b=Double(pixels[i+2])/max(1,Double(pixels[i+3]))
                let cream = b/max(0.001,r)>0.57 && g/max(0.001,r)>0.79
                if (rig.chinPoints != nil && chin.contains(p)) || (belly.contains(p) && !head.contains(p) && ((!asset.contains("turn-") && asset != "desert-fallen") || cream)) || (cream && (chin.contains(p) || (rig.chinPoints == nil && torsoCreamZone.contains(p) && !asset.contains("turn-") && !dorsal.contains(p) && !head.contains(p)) || toes.contains(where:{$0.contains(p)}))) {label=4}
                if !hand && (harnessMatte[n]>0 || clockMatte[n] == 2) {label=5}
                // One connected orange knitted material. Geometry excludes the
                // orange cheek and every hand even in front of the clock/scarf.
                if rig.scarfPoints == nil, p.y>rig.point(0,rig.scarfTop).y, p.y<rig.point(0,rig.scarfBottom).y,
                   (rig.flip ? 1-p.x:p.x)>0.10,(rig.flip ? 1-p.x:p.x)<0.82,
                   (b/max(0.001,r)<0.22 || (cloth.contains(p) && b/max(0.001,r)<0.5)), g/max(0.001,r)>0.32, g/max(0.001,r)<0.86,
                   color.hue>0.065, !hand, label != 2, label != 5 {label=1}
                // Horns are a connected brown material within their own cap,
                // separate from the sandy forehead and all skin spots below.
                if hornMatte[n]>0 {label=2}
                if cloth.contains(p), !hand, (label != 2 || b/max(0.001,r)<0.25), label != 5 {label=1}
                if hand {label=3}
                if rig.rear {
                    label = dorsal.contains(p) ? 2 : 3
                    let club = rearClub
                    if club.contains(p) { label=3 }
                    if rearBelly.contains(p), !club.contains(p) {label=4}
                }
                if hornMatte[n]>0 {label=2}
                if !hand && harnessMatte[n]>0 {label=5}
                if rig.hasClock, !cloth.contains(p), (metal.contains(where:{$0.contains(p)}) || harness.contains(where:{$0.contains(p)}) || clockMatte[n] == 2),
                   (0.095...0.17).contains(color.hue), g/max(0.001,r)>0.60,b/max(0.001,r)<0.65 {label=0}
                if hand && cream && toes.contains(where:{$0.contains(p)}) {label=4}
                labels[n]=label
            }
        }
        desertMaskCache.setObject(DesertLabels(labels),forKey:key,cost:labels.count)
        return labels
    }
    /// The opaque, neutral dial is a connected region inside a pose-specific
    /// search window. Its convex contour includes the dark ticks/hands, and a
    /// measured outset follows the rotated bezel. This never reuses idle clock
    /// coordinates on a moving source or mixes 1254px with 512px measurements.
    private static func desertClockMatte(_ p: UnsafeMutableBufferPointer<UInt8>, width w:Int, height h:Int, rig:DesertRig, isHorn:Bool = false, harnessRegion:CGPath? = nil, excluding:[UInt8]? = nil) -> [UInt8] {
        let capBottom = (rig.point(0,110,head:true).y-rig.dy)*443.5
        let search = isHorn ? CGRect(x:0,y:0,width:443.5,height:capBottom) : rig.clock.insetBy(dx:-32,dy:-30)
        let a=harnessRegion?.boundingBoxOfPath.origin ?? rig.point(search.minX,search.minY)
        let b=harnessRegion.map {CGPoint(x:$0.boundingBoxOfPath.maxX,y:$0.boundingBoxOfPath.maxY)} ?? rig.point(search.maxX,search.maxY)
        let x0=max(0,Int(min(a.x,b.x)*Double(w))),x1=min(w-1,Int(max(a.x,b.x)*Double(w)))
        let y0=max(0,Int(min(a.y,b.y)*Double(h))),y1=min(h-1,Int(max(a.y,b.y)*Double(h)))
        var candidate=[Bool](repeating:false,count:w*h),seen=candidate,best=[Int]()
        var groups=[[Int]]()
        let eyePaths=rig.eyes.map {rig.ellipse($0)}
        let coneZone=rig.polygon([(85,0),(220,0),(220,112),(85,112)],head:true)
        guard x0<x1,y0<y1 else {return [UInt8](repeating:0,count:w*h)}
        for y in y0...y1 {for x in x0...x1 {
            let n=y*w+x,i=n*4,r=Double(p[i]),g=Double(p[i+1]),b=Double(p[i+2])
            if isHorn || harnessRegion != nil {
                let color=HSL(red:r/max(1,Double(p[i+3])),green:g/max(1,Double(p[i+3])),blue:b/max(1,Double(p[i+3])))
                let point=CGPoint(x:(Double(x)+0.5)/Double(w),y:(Double(y)+0.5)/Double(h))
                if let harnessRegion {
                    candidate[n] = p[i+3]>100 && color.hue<0.11 && color.saturation>0.15 && color.lightness<0.70 && g/max(1,r)>0.58 && g/max(1,r)<0.77 && b/max(1,r)<0.55 && harnessRegion.contains(point) && excluding?[n] == 0
                } else {
                    candidate[n] = p[i+3]>100 && color.hue<0.095 && color.saturation>0.25 && color.lightness>0.19 && g/max(1,r)<0.70 && b/max(1,r)<0.50 && (rig.isTurn || coneZone.contains(point)) && !eyePaths.contains(where:{$0.contains(point)}) && !rig.brows.contains(where:{rig.ellipse($0).contains(point)})
                }
            } else {candidate[n] = p[i+3]>100 && b/max(1,r)>0.72 && g/max(1,r)>0.84}
        }}
        for y in y0...y1 {for x in x0...x1 {
            let start=y*w+x
            guard candidate[start],!seen[start] else {continue}
            var q=[start],i=0;seen[start]=true
            while i<q.count {
                let n=q[i];i+=1
                for m in [n%w>0 ? n-1:-1,n%w<w-1 ? n+1:-1,n>=w ? n-w:-1,n<w*(h-1) ? n+w:-1] where m>=0 {
                    if candidate[m] && !seen[m] {seen[m]=true;q.append(m)}
                }
            }
            if q.count>best.count {best=q}
            if isHorn && Double(q.count)>180*pow(Double(w)/443.5,2) {groups.append(q)}
        }}
        guard best.count>Int(50*Double(w)/443.5) else {return [UInt8](repeating:0,count:w*h)}
        if harnessRegion != nil {
            let xs=best.map {$0%w},ys=best.map {$0/w}
            let bw=Double(xs.max()!-xs.min()!+1),bh=Double(ys.max()!-ys.min()!+1)
            let searchArea=harnessRegion!.boundingBoxOfPath.width*harnessRegion!.boundingBoxOfPath.height*443.5*443.5
            guard (max(bw,bh)/max(1,min(bw,bh))>1.6 || searchArea<800), Double(best.count)>50*pow(Double(w)/443.5,2) else {return [UInt8](repeating:0,count:w*h)}
        }
        if !isHorn {groups=[best]}
        var mask=[UInt8](repeating:0,count:w*h)
        for group in groups {
        var points: [CGPoint] = group.map { n in CGPoint(x: Double(n % w) + 0.5, y: Double(n / w) + 0.5) }
        points.sort { a, b in a.x == b.x ? a.y < b.y : a.x < b.x }
        func cross(_ a:CGPoint,_ b:CGPoint,_ c:CGPoint)->Double {(b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)}
        var lower=[CGPoint](),upper=[CGPoint]()
        for point in points {while lower.count>=2 && cross(lower[lower.count-2],lower.last!,point)<=0 {lower.removeLast()};lower.append(point)}
        for point in points.reversed() {while upper.count>=2 && cross(upper[upper.count-2],upper.last!,point)<=0 {upper.removeLast()};upper.append(point)}
        let hull=Array(lower.dropLast())+Array(upper.dropLast()),path=CGMutablePath()
        path.addLines(between:hull);path.closeSubpath()
        let dial=path.copy(strokingWithWidth:2*Double(w)/443.5,lineCap:.round,lineJoin:.round,miterLimit:2)
        let bezel=path.copy(strokingWithWidth:(isHorn || harnessRegion != nil ? 3 : 24)*Double(w)/443.5,lineCap:.round,lineJoin:.round,miterLimit:2)
        let box=bezel.boundingBoxOfPath.integral
        for y in max(0,Int(box.minY))...min(h-1,Int(box.maxY)) {for x in max(0,Int(box.minX))...min(w-1,Int(box.maxX)) {
            let point=CGPoint(x:Double(x)+0.5,y:Double(y)+0.5)
            if path.contains(point) || dial.contains(point) {mask[y*w+x]=1}
            else if bezel.contains(point) {mask[y*w+x]=2}
        }}
        }
        return mask
    }
    static func recoloredDesert(_ source: CGImage, appearance: DinoAppearance, asset: String) -> CGImage? {
        guard !appearance.hasOriginalColors else { return source }
        let w=source.width,h=source.height,labels=desertLabels(source,asset:asset)
        var bytes=[UInt8](repeating:0,count:w*h*4)
        let parts:[DinoAppearance.Part] = [.body,.bandana,.spikes,.body,.belly,.bandana]
        let standard=DinoAppearance.standard(for:.desert)
        let refs=[UInt32(0xE7B56D),0xF89B20,0xB47B43,0xE7B56D,0xF5DEAA,0x97642F].map {HSL(hex:$0)}
        let format=CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        bytes.withUnsafeMutableBytes { b in
            let c=CGContext(data:b.baseAddress,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:format)!
            c.draw(source,in:CGRect(x:0,y:0,width:w,height:h));let p=b.bindMemory(to:UInt8.self)
            for n in 0..<w*h {
                let label=Int(labels[n]),i=n*4,a=Double(p[i+3])/255
                guard label>0,a>0,appearance[parts[label]] != standard[parts[label]] else {continue}
                let v=HSL(red:Double(p[i])/255/a,green:Double(p[i+1])/255/a,blue:Double(p[i+2])/255/a)
                let ref=refs[label],target=HSL(hex:appearance[parts[label]])
                let l = v.lightness <= ref.lightness ? target.lightness*v.lightness/max(0.001,ref.lightness)
                    : target.lightness+(1-target.lightness)*(v.lightness-ref.lightness)/max(0.001,1-ref.lightness)
                let rgb=HSL(hue:target.hue,saturation:min(1,v.saturation*target.saturation/max(0.001,ref.saturation)),lightness:min(1,max(0,l))).rgb
                for (k,value) in [rgb.0,rgb.1,rgb.2].enumerated() {p[i+k]=UInt8((min(1,max(0,value))*a*255).rounded())}
            }
        }
        return desertImage(bytes,width:w,height:h)
    }
    static func desertHeadOverflow(_ source: CGImage, asset: String, mirrored: Bool = true) -> CGImage? {
        let w=source.width,h=source.height,rig=DesertRig(asset:asset),head=rig.head
        let hands=rig.hands.map {rig.ellipse($0)}
        var bytes=[UInt8](repeating:0,count:w*h*4)
        bytes.withUnsafeMutableBytes { b in
            let c=CGContext(data:b.baseAddress,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)!
            c.draw(source,in:CGRect(x:0,y:0,width:w,height:h));let p=b.bindMemory(to:UInt8.self)
            for y in 0..<h {for x in 0..<w {
                let u=(Double(x)+0.5)/Double(w),v=(Double(y)+0.5)/Double(h)
                let point=CGPoint(x:mirrored ? 1-u:u,y:v)
                if !head.contains(point) || hands.contains(where:{$0.contains(point)}) {for k in 0..<4 {p[(y*w+x)*4+k]=0}}
            }}
        }
        return desertImage(bytes,width:w,height:h)
    }
    private static func desertImage(_ bytes:[UInt8],width:Int,height:Int) -> CGImage? {
        guard let provider=CGDataProvider(data:Data(bytes) as CFData) else {return nil}
        return CGImage(width:width,height:height,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:width*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGBitmapInfo(rawValue:CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue),provider:provider,decode:nil,shouldInterpolate:true,intent:.defaultIntent)
    }
}

extension DinoSpriteColorRenderer {
    static func recoloredBoss(_ source: CGImage, appearance: DinoAppearance, asset: String) -> CGImage? {
        switch appearance.identity {
        case .volcano: return recoloredVolcano(source, appearance:appearance, asset:asset)
        case .desert: return recoloredDesert(source, appearance:appearance, asset:asset)
        default: return recoloredJungle(source, appearance:appearance, asset:asset)
        }
    }
    static func bossHeadOverflow(_ source: CGImage, character: DinoIdentity, asset: String, mirrored: Bool = true) -> CGImage? {
        switch character {
        case .volcano: return volcanoHeadOverflow(source,asset:asset,mirrored:mirrored)
        case .desert: return desertHeadOverflow(source,asset:asset,mirrored:mirrored)
        default: return jungleHeadOverflow(source,asset:asset,mirrored:mirrored)
        }
    }
}

extension DinoSpriteColorRenderer {
    /// Magma's rig is measured in a 512px top-left SOURCE canvas. Raster pixel
    /// centres scale into that canvas; mirrored head mattes use 512 - x once.
    struct VolcanoRig {
        let asset: String
        var headTransform = CGAffineTransform.identity
        var clocks: [CGRect] = [CGRect(x:144,y:330,width:51,height:65),CGRect(x:188,y:294,width:66,height:68),CGRect(x:248,y:254,width:62,height:67)]
        var hands: [CGRect] = []
        var sashPoints: [CGPoint] = []
        var rear = false
        var turn = 0
        init(asset: String) {
            self.asset = DinoVolcanoArtwork.asset(for:asset)
            var shift = CGPoint.zero
            switch self.asset {
            case "volcano-wrong": shift = CGPoint(x:6,y:4); hands=[CGRect(x:73,y:266,width:102,height:68),CGRect(x:314,y:277,width:95,height:65)]
            case "volcano-clap-open", "volcano-clap-open-2": shift=CGPoint(x:6,y:4); hands=[CGRect(x:98,y:262,width:85,height:91),CGRect(x:278,y:267,width:76,height:87)]; clocks=[CGRect(x:151,y:330,width:58,height:64),CGRect(x:201,y:300,width:66,height:66),CGRect(x:267,y:253,width:62,height:65)]
            case "volcano-clap-contact", "volcano-clap-contact-2": shift=CGPoint(x:6,y:4); hands=[CGRect(x:170,y:267,width:142,height:89)]; clocks=[CGRect(x:151,y:330,width:58,height:64),CGRect(x:201,y:300,width:66,height:66),CGRect(x:267,y:253,width:62,height:65)]
            case "volcano-crouch", "volcano-landing": shift=CGPoint(x:6,y:16); clocks=[CGRect(x:149,y:341,width:58,height:64),CGRect(x:202,y:310,width:66,height:66),CGRect(x:264,y:268,width:62,height:65)]
            case "volcano-rise-low": shift=CGPoint(x:-12,y:82);clocks=[CGRect(x:175,y:369,width:53,height:59),CGRect(x:208,y:352,width:59,height:65),CGRect(x:248,y:319,width:61,height:64)];hands=[CGRect(x:82,y:412,width:105,height:70),CGRect(x:250,y:413,width:100,height:70)]
            case "volcano-rise-high": shift=CGPoint(x:-3,y:42);clocks=[CGRect(x:167,y:347,width:55,height:64),CGRect(x:206,y:313,width:63,height:69),CGRect(x:255,y:280,width:62,height:66)];hands=[CGRect(x:111,y:326,width:67,height:69),CGRect(x:273,y:326,width:77,height:81)]
            case "volcano-takeoff": shift=CGPoint(x:29,y:-10); clocks=[CGRect(x:170,y:305,width:53,height:62),CGRect(x:219,y:276,width:65,height:67),CGRect(x:279,y:241,width:60,height:64)]; hands=[CGRect(x:92,y:192,width:92,height:91),CGRect(x:304,y:201,width:98,height:80)]
            case "volcano-airborne": shift=CGPoint(x:13,y:-2); clocks=[CGRect(x:151,y:302,width:55,height:64),CGRect(x:198,y:276,width:66,height:68),CGRect(x:263,y:250,width:60,height:60)]; hands=[CGRect(x:112,y:251,width:67,height:76),CGRect(x:285,y:258,width:69,height:67)]
            case "volcano-stumble": shift=CGPoint(x:-29,y:33); headTransform=CGAffineTransform(translationX:207,y:170).rotated(by:-0.12).translatedBy(x:-207,y:-170); clocks=[CGRect(x:176,y:368,width:54,height:61),CGRect(x:218,y:337,width:65,height:66),CGRect(x:273,y:301,width:63,height:69)]; hands=[CGRect(x:56,y:264,width:103,height:77),CGRect(x:244,y:274,width:87,height:76)]
            case "volcano-fallen": shift=CGPoint(x:-47,y:128); clocks=[CGRect(x:146,y:434,width:55,height:38),CGRect(x:186,y:410,width:62,height:58),CGRect(x:226,y:370,width:59,height:64)]; hands=[CGRect(x:52,y:425,width:96,height:47),CGRect(x:239,y:423,width:95,height:50)]
            case "volcano-push-up": shift=CGPoint(x:-26,y:99); clocks=[CGRect(x:155,y:390,width:57,height:50),CGRect(x:198,y:372,width:62,height:64),CGRect(x:237,y:336,width:61,height:67)]; hands=[CGRect(x:80,y:420,width:95,height:50),CGRect(x:244,y:422,width:92,height:50)]
            case let n where n.contains("turn-"):
                turn=Int(n.suffix(2)) ?? 0
                switch turn {
                case 1: shift=CGPoint(x:18,y:-4);clocks=[CGRect(x:151,y:321,width:53,height:64),CGRect(x:198,y:288,width:65,height:67),CGRect(x:258,y:250,width:62,height:64)]
                case 2: hands=[CGRect(x:165,y:280,width:94,height:90)];clocks=[CGRect(x:112,y:312,width:30,height:62),CGRect(x:125,y:285,width:40,height:66),CGRect(x:160,y:249,width:51,height:70)]
                case 3,4,5: rear=true;clocks=[]
                case 6: hands=[CGRect(x:245,y:280,width:110,height:100)];clocks=[CGRect(x:319,y:313,width:54,height:65),CGRect(x:350,y:279,width:41,height:64)];
                case 7: hands=[CGRect(x:151,y:270,width:100,height:90),CGRect(x:338,y:286,width:70,height:87)];clocks=[CGRect(x:225,y:323,width:54,height:63),CGRect(x:275,y:289,width:61,height:67),CGRect(x:325,y:250,width:45,height:63)]
                default: shift=CGPoint(x:12,y:-4);clocks=[CGRect(x:151,y:321,width:53,height:64),CGRect(x:198,y:288,width:65,height:67),CGRect(x:258,y:250,width:62,height:64)]
                }
            default: break
            }
            headTransform = headTransform.concatenating(CGAffineTransform(translationX:shift.x,y:shift.y))
            if hands.isEmpty { hands=[CGRect(x:95,y:283,width:81,height:98),CGRect(x:274,y:288,width:79,height:98)] }
            // The visible sash lies between the three independent bezels. Arm
            // exclusions take priority; spot-colored skin never becomes cloth.
            if rear {
                sashPoints=[CGPoint(x:180,y:244),CGPoint(x:223,y:240),CGPoint(x:346,y:326),CGPoint(x:348,y:360),CGPoint(x:294,y:349),CGPoint(x:177,y:270)]
            } else if let first=clocks.first,let last=clocks.last {
                sashPoints=[CGPoint(x:first.minX-7,y:first.midY-16),CGPoint(x:last.midX+10,y:last.minY-17),CGPoint(x:last.maxX+19,y:last.minY+16),CGPoint(x:first.maxX+12,y:first.maxY+5)]
            }
        }
        func path(_ points: [(Double,Double)], head: Bool = false) -> CGPath {
            let p=CGMutablePath();p.addLines(between:points.map {CGPoint(x:$0.0,y:$0.1)});p.closeSubpath()
            if head {var t=headTransform;return p.copy(using:&t)!};return p
        }
        var head: CGPath {
            if asset == "volcano-rise-low" {return path([(75,60),(395,60),(395,275),(380,292),(355,315),(333,326),(306,317),(290,317),(269,330),(236,340),(198,336),(165,323),(145,308),(122,318),(100,300),(75,275)])}
            if asset == "volcano-rise-high" {return path([(80,30),(420,30),(420,256),(373,277),(333,296),(309,278),(286,278),(268,289),(236,296),(197,292),(167,281),(152,270),(133,291),(102,270),(80,250)])}
            if asset == "volcano-push-up" { return path([(70,65),(390,65),(390,285),(330,310),(304,324),(280,321),(263,333),(246,341),(224,349),(196,349),(172,340),(147,330),(130,322),(120,305),(94,303),(86,250)]) }
            if asset == "volcano-fallen" { return path([(40,100),(370,100),(370,325),(326,349),(301,365),(273,363),(251,358),(235,373),(207,379),(177,376),(146,366),(116,348),(100,332),(70,340),(40,320)]) }
            if asset == "volcano-stumble" { return path([(75,0),(405,0),(405,220),(345,244),(307,258),(273,257),(267,271),(248,284),(224,292),(193,294),(169,284),(141,272),(131,259),(115,254),(94,249),(75,230)]) }
            if turn>1 && turn<8 { return path([(70,0),(430,0),(430,240),(365,249),(320,247),(260,250),(200,250),(150,242),(70,240)]) }
            return path([(75,0),(420,0),(420,220),(365,240),(332,264),(316,251),(307,244),(298,245),(276,254),(236,257),(199,250),(169,237),(154,250),(138,257),(122,246),(75,246)],head:true)
        }
        var extraSash: CGPath {
            if turn == 2 {return path([(219,246),(245,261),(281,300),(293,313),(275,303),(239,277),(217,265)])}
            if turn == 6 {return path([(218,292),(247,303),(270,331),(325,351),(329,370),(280,372),(223,350),(205,333),(207,314)])}
            return CGMutablePath()
        }
        var face: CGPath {
            if asset == "volcano-rise-low" {return path([(147,205),(164,198),(181,179),(231,179),(267,195),(288,221),(306,270),(302,304),(282,326),(242,339),(206,336),(176,327),(148,304),(139,280),(139,247)])}
            if asset == "volcano-rise-high" {return path([(147,181),(164,169),(181,146),(231,143),(268,159),(291,196),(309,236),(305,274),(282,292),(244,304),(208,301),(177,287),(151,270),(139,244),(139,211)])}
            if turn==3 {return path([(157,132),(176,123),(190,137),(190,227),(181,246),(164,242),(145,229),(135,209),(137,184),(148,176),(153,151)])}
            if turn==5 {return path([(374,123),(389,136),(397,176),(407,188),(407,219),(393,239),(374,246),(357,246),(352,218),(360,188),(369,161)])}
            if rear {return CGMutablePath()}
            if turn==2 {return path([(135,121),(176,120),(185,87),(231,103),(265,145),(266,226),(237,249),(190,247),(140,231),(122,205),(122,182)])}
            if turn==6 {return path([(285,98),(333,106),(363,142),(378,182),(397,193),(398,222),(364,250),(306,249),(289,211)])}
            if turn==7 {return path([(208,115),(252,95),(314,97),(348,131),(366,183),(361,229),(334,249),(280,250),(238,239),(209,216)])}
            return path([(139,139),(160,128),(180,99),(233,96),(270,113),(290,146),(303,192),(301,231),(278,251),(241,258),(203,252),(169,237),(145,217),(137,179)],head:true)
        }
        var browHorns: [CGPath] {
            if turn==3 {return [path([(176,58),(186,62),(185,82),(187,101),(185,125),(177,137),(166,130),(159,113),(158,94),(165,70)])]}
            if turn==5 {return [path([(363,58),(374,61),(383,83),(382,110),(376,133),(364,137),(354,126),(351,106),(357,88)])]}
            if rear {return []}
            if turn==2 {return [path([(191,40),(206,61),(217,108),(208,129),(182,130),(177,106),(177,80)])]}
            if turn==6 {return [path([(312,56),(335,51),(337,92),(324,130),(301,135),(292,117),(300,91)])]}
            if turn==7 {return [path([(247,51),(267,68),(271,106),(257,130),(228,136),(213,119),(219,88)]),path([(343,58),(356,78),(354,117),(342,135),(328,128),(333,103)])]}
            return [path([(156,61),(170,65),(170,92),(186,121),(177,140),(161,142),(146,123),(141,98)],head:true),path([(265,54),(280,65),(292,94),(293,122),(279,145),(258,145),(247,128),(254,102)],head:true)]
        }
        var eyes: [CGPath] {
            if turn==3 {return [CGPath(ellipseIn:CGRect(x:152,y:142,width:16,height:46),transform:nil)]}
            if turn==5 {return [CGPath(ellipseIn:CGRect(x:377,y:142,width:14,height:40),transform:nil)]}
            if rear {return []}
            if turn==2 {return [CGPath(ellipseIn:CGRect(x:150,y:142,width:28,height:58),transform:nil)]}
            if turn==6 {return [CGPath(ellipseIn:CGRect(x:339,y:139,width:31,height:61),transform:nil)]}
            if turn==7 {return [CGPath(ellipseIn:CGRect(x:254,y:140,width:39,height:59),transform:nil),CGPath(ellipseIn:CGRect(x:318,y:141,width:30,height:49),transform:nil)]}
            return [CGRect(x:155,y:135,width:43,height:65),CGRect(x:215,y:134,width:56,height:73)].map { r in var t=headTransform;return CGPath(ellipseIn:r,transform:nil).copy(using:&t)! }
        }
    }
    private final class VolcanoLabels: NSObject {let values:[UInt8];init(_ values:[UInt8]){self.values=values}}
    private static let volcanoMaskCache: NSCache<NSString,VolcanoLabels> = {let c=NSCache<NSString,VolcanoLabels>();c.totalCostLimit=24*1024*1024;return c}()
    static func volcanoLabels(_ source: CGImage, asset: String, useArchive: Bool = true) -> [UInt8] {
        let key="magma-v9-\(DinoVolcanoArtwork.asset(for:asset))-\(source.width)-\(source.height)" as NSString
        if useArchive, let hit=volcanoMaskCache.object(forKey:key){return hit.values}
        if useArchive, let baked=VolcanoMaterialArchive.labels(asset:DinoVolcanoArtwork.asset(for:asset),width:source.width,height:source.height) {
            volcanoMaskCache.setObject(VolcanoLabels(baked),forKey:key,cost:baked.count)
            return baked
        }
        let w=source.width,h=source.height,rig=VolcanoRig(asset:asset)
        let head=rig.head,face=rig.face,eyes=rig.eyes,horns=rig.browHorns,extraSash=rig.extraSash
        let hornEdges=horns.map {$0.copy(strokingWithWidth:rig.turn==3 || rig.turn==5 ? 2:14,lineCap:.round,lineJoin:.round,miterLimit:2)}
        let sash=CGMutablePath();sash.addLines(between:rig.sashPoints);sash.closeSubpath()
        let chin = rig.asset == "volcano-stumble"
            ? rig.path([(140,262),(151,260),(163,274),(183,281),(201,275),(221,255),(231,236),(250,234),(263,241),(265,254),(258,272),(245,284),(220,293),(191,299),(165,291),(147,279),(139,269)])
            : rig.path([(145,216),(151,216),(170,228),(195,235),(218,237),(240,232),(254,218),(275,212),(284,219),(282,233),(265,247),(242,255),(207,254),(181,245),(160,234)],head:true)
        let stumbleMouth=CGPath(ellipseIn:CGRect(x:165,y:258,width:35,height:29),transform:nil)
        let clapTips=[CGRect(x:280,y:280,width:25,height:23),CGRect(x:276,y:295,width:24,height:23),CGRect(x:267,y:310,width:25,height:25)].map {CGPath(ellipseIn:$0,transform:nil)}
        let wrongMouth=rig.path([(192,234),(212,233),(235,224),(255,215),(255,231),(248,243),(237,251),(221,256),(207,251),(198,245)])
        let noseHorn: CGPath
        switch rig.turn {
        case 2: noseHorn=rig.path([(152,94),(160,88),(171,84),(178,98),(177,118),(165,135),(153,131),(149,116)])
        case 3: noseHorn=rig.path([(193,85),(199,77),(213,76),(221,84),(213,97),(199,100)])
        case 5: noseHorn=rig.path([(334,78),(347,78),(359,87),(357,101),(344,104),(337,94)])
        case 6: noseHorn=rig.path([(339,91),(355,86),(371,98),(376,120),(368,135),(352,137),(341,123)])
        case 7: noseHorn=rig.path([(274,88),(294,85),(312,99),(322,117),(308,137),(287,134),(274,118)])
        default: noseHorn=rig.path([(188,75),(253,75),(253,142),(188,149)],head:true)
        }
        let hands=rig.hands.map {CGPath(ellipseIn:$0,transform:nil)}
                let metals=rig.clocks.map {CGPath(ellipseIn:$0.insetBy(dx:-3,dy:-5),transform:nil)}
        var bytes=[UInt8](repeating:0,count:w*h*4),labels=[UInt8](repeating:0,count:w*h)
        bytes.withUnsafeMutableBytes { buf in
            let c=CGContext(data:buf.baseAddress,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGBitmapInfo.byteOrder32Big.rawValue|CGImageAlphaInfo.premultipliedLast.rawValue)!
            c.draw(source,in:CGRect(x:0,y:0,width:w,height:h));let p=buf.bindMemory(to:UInt8.self)
            let dialMatte=volcanoDialMatte(p,width:w,height:h,rig:rig)
            for y in 0..<h {for x in 0..<w {
                let n=y*w+x,i=n*4,a=Double(p[i+3])/255;guard a>0 else {continue}
                let point=CGPoint(x:(Double(x)+0.5)*512/Double(w),y:(Double(y)+0.5)*512/Double(h))
                let v=HSL(red:Double(p[i])/255/a,green:Double(p[i+1])/255/a,blue:Double(p[i+2])/255/a)
                let cream=v.hue>0.060 && v.hue<0.19 && Double(p[i+2])/max(1,Double(p[i]))>0.35 && Double(p[i+1])/max(1,Double(p[i]))>0.65
                let red=v.hue<0.055 || v.hue>0.95
                let gold=v.hue>=0.065 && v.hue<0.19
                let onHand=hands.contains {$0.contains(point)} && v.hue<0.055 && v.saturation>0.35
                var label:UInt8=3
                if head.contains(point) && !face.contains(point) && !onHand && (v.hue<0.04 || gold) {label=gold ? 6:2}
                if cream && ((face.contains(point) && point.y > (rig.turn>=2 && rig.turn<=7 ? 205:rig.headTransform.ty+209)) || !head.contains(point)) {label=4}
                if (horns.contains(where:{$0.contains(point)}) || hornEdges.contains(where:{$0.contains(point)})) && cream && Double(p[i+2])/max(1,Double(p[i]))>0.42 {label=4}
                if chin.contains(point) && rig.turn != 2 && rig.turn != 6 && rig.turn != 7 && !rig.rear {label=4}
                if noseHorn.contains(point) && v.hue<0.035 && v.saturation>0.5 && rig.turn != 4 {label=2}
                if (sash.contains(point) || extraSash.contains(point)) && red && !onHand {label=1}
                if metals.contains(where:{$0.contains(point)}) && v.hue>0.05 && v.hue<0.19 && Double(p[i+1])/max(1,Double(p[i]))>0.5 && !onHand {label=5}
                // Hanging loops sit above each separate clock; keep their full
                // highlights and shadows in metal, independent of dial colors.
                for clock in rig.clocks where CGRect(x:clock.midX-10,y:clock.minY-14,width:20,height:18).contains(point) && gold && !onHand {label=5}
                if dialMatte[n]>0 {label=0}
                if (rig.asset == "volcano-clap-open" || rig.asset == "volcano-clap-open-2"), cream {
                    if clapTips.contains(where:{$0.contains(point)}) {label=4}
                }
                if eyes.contains(where:{$0.contains(point)}) && ((Double(p[i+1])/max(1,Double(p[i]))>0.74 && Double(p[i+2])/max(1,Double(p[i]))>0.65) || (Double(p[i])/a<120 && Double(p[i+1])/a<100)) {label=0}
                // Dark nostrils, mouth ink and raised wrong-answer eyebrows are
                // protected within the face, never mistaken for skin shadows.
                if face.contains(point) && v.lightness<0.22 && v.saturation<0.45 {label=0}
                if face.contains(point) && v.lightness<0.22 && point.y > rig.headTransform.ty+188 && point.y < rig.headTransform.ty+248 {label=0}
                if rig.asset == "volcano-wrong" {
                    if wrongMouth.contains(point) {label=0}
                    if CGRect(x:224,y:136,width:45,height:19).contains(point) && v.lightness<0.38 {label=0}
                }
                if rig.asset == "volcano-stumble", stumbleMouth.contains(point) {label=0}
                labels[n]=label
            }}
        }
        labels = cleanedVolcanoLabels(labels,width:w,height:h)
        if useArchive {volcanoMaskCache.setObject(VolcanoLabels(labels),forKey:key,cost:labels.count)}
        return labels
    }
    static func recoloredVolcano(_ source:CGImage,appearance:DinoAppearance,asset:String) -> CGImage? {
        guard !appearance.hasOriginalColors else {return source}
        let w=source.width,h=source.height,labels=volcanoLabels(source,asset:asset)
        var bytes=[UInt8](repeating:0,count:w*h*4)
        let parts:[DinoAppearance.Part]=[.body,.bandana,.spikes,.body,.belly,.bandana,.spikes]
        let refs=[UInt32(0),0xDB3526,0xD93725,0xFF783E,0xF8D99A,0xE9AA34,0xF3BB45].map {HSL(hex:$0)}
        let standard=DinoAppearance.standard(for:.volcano)
        bytes.withUnsafeMutableBytes { b in
            let c=CGContext(data:b.baseAddress,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGBitmapInfo.byteOrder32Big.rawValue|CGImageAlphaInfo.premultipliedLast.rawValue)!
            c.draw(source,in:CGRect(x:0,y:0,width:w,height:h));let p=b.bindMemory(to:UInt8.self)
            for n in 0..<w*h {
                let label=Int(labels[n]),i=n*4,a=Double(p[i+3])/255
                guard label>0,a>0,appearance[parts[label]] != standard[parts[label]] else {continue}
                let pixel=HSL(red:Double(p[i])/255/a,green:Double(p[i+1])/255/a,blue:Double(p[i+2])/255/a)
                let ref=refs[label],target=HSL(hex:appearance[parts[label]])
                let l=pixel.lightness<=ref.lightness ? target.lightness*pixel.lightness/max(0.001,ref.lightness) : target.lightness+(1-target.lightness)*(pixel.lightness-ref.lightness)/max(0.001,1-ref.lightness)
                let rgb=HSL(hue:target.hue,saturation:min(1,pixel.saturation*target.saturation/max(0.001,ref.saturation)),lightness:min(1,max(0,l))).rgb
                for (k,v) in [rgb.0,rgb.1,rgb.2].enumerated(){p[i+k]=UInt8((min(1,max(0,v))*a*255).rounded())}
            }
        }
        return desertImage(bytes,width:w,height:h)
    }
    static func volcanoHeadOverflow(_ source:CGImage,asset:String,mirrored:Bool=true) -> CGImage? {
        let w=source.width,h=source.height,rig=VolcanoRig(asset:asset),head=rig.head
        let hands=rig.hands.map {CGPath(ellipseIn:$0,transform:nil)}
        var bytes=[UInt8](repeating:0,count:w*h*4)
        bytes.withUnsafeMutableBytes { b in
            let c=CGContext(data:b.baseAddress,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGBitmapInfo.byteOrder32Big.rawValue|CGImageAlphaInfo.premultipliedLast.rawValue)!
            c.draw(source,in:CGRect(x:0,y:0,width:w,height:h));let p=b.bindMemory(to:UInt8.self)
            for y in 0..<h {for x in 0..<w {
                let u=(Double(x)+0.5)/Double(w),v=(Double(y)+0.5)/Double(h)
                let point=CGPoint(x:(mirrored ? 1-u:u)*512,y:v*512)
                if !head.contains(point) || hands.contains(where:{$0.contains(point)}) {for k in 0..<4 {p[(y*w+x)*4+k]=0}}
            }}
        }
        // Keep only the connected head silhouette. A mask edge must never
        // retain an isolated tail tip, shoulder fleck or lower clock fragment.
        var seen=[Bool](repeating:false,count:w*h),largest=[Int]()
        for start in 0..<w*h where !seen[start] && bytes[start*4+3]>0 {
            var q=[start],j=0;seen[start]=true
            while j<q.count {let n=q[j];j+=1
                for m in [n%w>0 ? n-1:-1,n%w<w-1 ? n+1:-1,n>=w ? n-w:-1,n<w*(h-1) ? n+w:-1] where m>=0 {
                    if !seen[m] && bytes[m*4+3]>0 {seen[m]=true;q.append(m)}
                }
            }
            if q.count>largest.count {largest=q}
        }
        var keep=[Bool](repeating:false,count:w*h);for n in largest {keep[n]=true}
        for n in 0..<w*h where !keep[n] {for k in 0..<4 {bytes[n*4+k]=0}}
        return desertImage(bytes,width:w,height:h)
    }
}

extension DinoSpriteColorRenderer {
    /// Connected ivory glass, then its convex contour, protects all neutral ink.
    /// Each of Magma's three clocks is measured independently in every pose.
    private static func volcanoDialMatte(_ p:UnsafeMutableBufferPointer<UInt8>,width w:Int,height h:Int,rig:VolcanoRig) -> [UInt8] {
        var result=[UInt8](repeating:0,count:w*h)
        let shaded=["volcano-push-up","volcano-rise-low","volcano-fallen","volcano-stumble"].contains(rig.asset)
        let greenRatio=shaded ? 0.68:0.81,blueRatio=shaded ? 0.38:0.59,minimumLight=shaded ? 0.40:0.60
        for clock in rig.clocks {
            let box=clock.insetBy(dx:-4,dy:-4),scale=Double(w)/512
            let x0=max(0,Int(box.minX*scale)),x1=min(w-1,Int(box.maxX*scale))
            let y0=max(0,Int(box.minY*scale)),y1=min(h-1,Int(box.maxY*scale))
            guard x0<x1,y0<y1 else {continue}
            var candidate=[Bool](repeating:false,count:w*h),seen=candidate,best=[Int](),score=0.0
            for y in y0...y1 {for x in x0...x1 {
                let i=(y*w+x)*4,r=Double(p[i]),g=Double(p[i+1]),b=Double(p[i+2])
                candidate[y*w+x] = p[i+3]>120 && b/max(1,r)>blueRatio && g/max(1,r)>greenRatio && r/Double(max(1,p[i+3]))>minimumLight
            }}
            for y in y0...y1 {for x in x0...x1 {
                let start=y*w+x;guard candidate[start],!seen[start] else {continue}
                var q=[start],j=0;seen[start]=true
                while j<q.count {let n=q[j];j+=1
                    for m in [n%w>0 ? n-1:-1,n%w<w-1 ? n+1:-1,n>=w ? n-w:-1,n<w*(h-1) ? n+w:-1] where m>=0 {
                        if candidate[m] && !seen[m] {seen[m]=true;q.append(m)}
                    }
                }
                let cx=q.reduce(0.0){$0+Double($1%w)}/Double(q.count)/scale,cy=q.reduce(0.0){$0+Double($1/w)}/Double(q.count)/scale
                let weight=Double(q.count)/(1+hypot(cx-clock.midX,cy-clock.midY)*0.1)
                if weight>score {score=weight;best=q}
            }}
            guard best.count>Int(20*scale*scale) else {continue}
            var points: [CGPoint] = best.map { n in CGPoint(x:Double(n % w)+0.5,y:Double(n / w)+0.5) }
            points.sort { a,b in a.x == b.x ? a.y < b.y : a.x < b.x }
            func cross(_ a:CGPoint,_ b:CGPoint,_ c:CGPoint)->Double{(b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)}
            var lower=[CGPoint](),upper=[CGPoint]()
            for v in points {while lower.count>=2 && cross(lower[lower.count-2],lower.last!,v)<=0 {lower.removeLast()};lower.append(v)}
            for v in points.reversed() {while upper.count>=2 && cross(upper[upper.count-2],upper.last!,v)<=0 {upper.removeLast()};upper.append(v)}
            let path=CGMutablePath();path.addLines(between:Array(lower.dropLast())+Array(upper.dropLast()));path.closeSubpath()
            let edge=path.copy(strokingWithWidth:1.5*scale,lineCap:.round,lineJoin:.round,miterLimit:2)
            for y in y0...y1 {for x in x0...x1 {
                let point=CGPoint(x:Double(x)+0.5,y:Double(y)+0.5),n=y*w+x,i=n*4
                let r=Double(p[i]),g=Double(p[i+1]),b=Double(p[i+2])
                // Orange fingers retain their own material in front of glass.
                let skin=r>g*(shaded ? 1.55:1.32) && g>b*(shaded ? 1.20:1.12)
                if !skin && (path.contains(point) || edge.contains(point)) {result[n]=1}
            }}
        }
        return result
    }
}

extension DinoSpriteColorRenderer {
    /// Source texture can shift an isolated highlight across a hue boundary.
    /// Resolve small connected material islands from their surrounding region;
    /// neutral eyes, nostrils and dial ink remain explicitly protected.
    private static func cleanedVolcanoLabels(_ input:[UInt8],width w:Int,height h:Int)->[UInt8] {
        var labels=input,seen=[Bool](repeating:false,count:input.count)
        let scale=pow(Double(w)/512,2)
        for start in labels.indices where !seen[start] && input[start] != 0 {
            let label=input[start]
            var q=[start],j=0;seen[start]=true
            var votes=[Int](repeating:0,count:7)
            while j<q.count {let n=q[j];j+=1
                for m in [n%w>0 ? n-1:-1,n%w<w-1 ? n+1:-1,n>=w ? n-w:-1,n<w*(h-1) ? n+w:-1] where m>=0 {
                    if input[m]==label {if !seen[m] {seen[m]=true;q.append(m)}}
                    else if input[m]>0 {votes[Int(input[m])]+=1}
                }
            }
            let limit=Int((label==3 ? 220.0:label==4 ? 36.0:18.0)*scale)
            if q.count<limit, let best=(1..<7).max(by:{votes[$0]<votes[$1]}), votes[best]>0 {
                for n in q {labels[n]=UInt8(best)}
            }
        }
        // A compact categorical edge filter removes salt-and-pepper contour
        // labels without touching the original raster's texture or alpha.
        let before=labels,radius=max(1,Int((Double(w)/512).rounded()))
        for y in radius..<(h-radius) {for x in radius..<(w-radius) {
            let n=y*w+x,label=before[n];guard label>0 else {continue}
            let neighbours=[before[n-1],before[n+1],before[n-w],before[n+w]]
            guard neighbours.contains(where:{$0 != label && $0>0}) else {continue}
            var votes=[Int](repeating:0,count:7)
            for yy in (y-radius)...(y+radius) {for xx in (x-radius)...(x+radius) {votes[Int(before[yy*w+xx])]+=1}}
            if let best=(1..<7).max(by:{votes[$0]<votes[$1]}),votes[best]>votes[Int(label)]+2 {labels[n]=UInt8(best)}
        }}
        return labels
    }
}

/// Material analysis is an authoring step. Shipping the color-independent RLE
/// mattes keeps a cold answer/result from doing connected-component work on the
/// render thread. Geometry remains the source of truth for rebaking and tests.
private enum VolcanoMaterialArchive {
    private struct Entry {let width:Int;let height:Int;let start:Int;let runs:Int}
    private static let archive: (Data,[String:Entry])? = {
        let data:Data?
#if canImport(UIKit)
        data=NSDataAsset(name:"volcano-materials")?.data
#else
        data=try? Data(contentsOf:URL(fileURLWithPath:"Assets.xcassets/volcano-materials.dataset/magma-materials.bin"))
#endif
        guard let data,data.count>=6,Array(data.prefix(4))==[77,71,77,57] else {return nil}
        func u16(_ p:Int)->Int {Int(data[p]) | Int(data[p+1])<<8}
        func u32(_ p:Int)->Int {Int(data[p]) | Int(data[p+1])<<8 | Int(data[p+2])<<16 | Int(data[p+3])<<24}
        var entries=[String:Entry](),cursor=6
        for _ in 0..<u16(4) {
            guard cursor+10<=data.count else {return nil}
            let length=u16(cursor),w=u16(cursor+2),h=u16(cursor+4),runs=u32(cursor+6);cursor+=10
            guard cursor+length+runs*5<=data.count,let name=String(data:data[cursor..<cursor+length],encoding:.utf8) else {return nil}
            cursor+=length;entries[name]=Entry(width:w,height:h,start:cursor,runs:runs);cursor+=runs*5
        }
        return (data,entries)
    }()
    static func labels(asset:String,width:Int,height:Int)->[UInt8]? {
        guard let (data,entries)=archive,let e=entries[asset],e.width==width,e.height==height else {return nil}
        var out=[UInt8]();out.reserveCapacity(width*height)
        for run in 0..<e.runs {
            let p=e.start+run*5,count=Int(data[p]) | Int(data[p+1])<<8 | Int(data[p+2])<<16 | Int(data[p+3])<<24,label=data[p+4]
            guard label<=6,count>0,out.count+count<=width*height else {return nil}
            out.append(contentsOf:repeatElement(label,count:count))
        }
        return out.count==width*height ? out:nil
    }
}
