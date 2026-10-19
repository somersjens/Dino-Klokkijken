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
        var tailLeft = 1.0
        var tailBottom = 0.0
        let upperSpikes: CGPath
        let eyes: CGPath
        let mouth: CGPath

        func part(hue: Double, saturation: Double, lightness: Double, x: Double, y: Double) -> DinoAppearance.Part? {
            guard saturation > 0.08 else { return nil }
            let point = CGPoint(x: x, y: y)
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

    static func spriteRegions(for asset: String) -> SpriteRegions? { poses[asset] }

    /// Coordinates trace each animation illustration in a 1254 × 1254 reference space.
    private static let poses: [String: SpriteRegions] = [
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
        "dino-pirouette-07": SpriteRegions(
            bandanaBottom: 0.40,
            upperSpikes: contours([[.move(578, 165), .curve(628, 50, 578, 104, 601, 38), .curve(712, 151, 674, 42, 703, 111), .curve(578, 165, 660, 167, 618, 167)], [.move(616, 258), .curve(641, 137, 591, 209, 602, 143), .curve(735, 238, 681, 126, 729, 183), .curve(616, 258, 692, 257, 656, 260)]]),
            eyes: eyeContours([]),
            mouth: contours([])),
        "dino-pirouette-08": SpriteRegions(
            bandanaBottom: 0.40,
            upperSpikes: contours([[.move(554, 160), .curve(634, 48, 561, 94, 598, 27), .curve(712, 184, 693, 26, 728, 103), .curve(554, 160, 648, 186, 599, 171)], [.move(639, 271), .curve(655, 153, 608, 212, 613, 153), .curve(741, 262, 701, 140, 743, 205), .curve(639, 271, 712, 286, 673, 290)]]),
            eyes: eyeContours([]),
            mouth: contours([])),
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
        let letteringBounds = appearance.usesBlackBandanaLettering ? bandanaLetteringBounds[asset] : nil
        let letteringInk = HSL(hex: appearance.bandanaLetteringHex).rgb
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
                    if let letteringBounds,
                       letteringBounds.contains(CGPoint(x: Double(x) / Double(width) * 1254,
                                                        y: Double(y) / Double(height) * 1254)) {
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

    /// Tight print regions in each 1254-point illustration exclude the eyes,
    /// highlights and transparent background, even when the head is tilted.
    private static let bandanaLetteringBounds: [String: CGRect] = [
        "dino-pirouette-01": CGRect(x: 580, y: 150, width: 252, height: 105),
        "dino-pirouette-02": CGRect(x: 696, y: 207, width: 243, height: 90),
        "dino-pirouette-03": CGRect(x: 681, y: 157, width: 220, height: 104),
        "dino-pirouette-04": CGRect(x: 700, y: 135, width: 195, height: 100),
        "dino-pirouette-09": CGRect(x: 350, y: 139, width: 155, height: 94),
        "dino-pirouette-10": CGRect(x: 390, y: 120, width: 195, height: 117),
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
    private static let palettes: [String: [Tone]] = [
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
