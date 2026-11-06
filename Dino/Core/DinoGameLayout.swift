import Foundation

/// A lesson is sized in the safe-area viewport left after the HUD, title and actions.
/// These are content requirements, independent of device names and size classes.
struct DinoGameLayout {
    let width: CGFloat
    let height: CGFloat
    let kind: ClockQuestionKind
    let optionCount: Int
    var spacing: CGFloat { spacious ? 16 : 12 }
    var spacious: Bool { width > 620 }

    static func contentWidth(availableWidth: CGFloat, playHeight: CGFloat, spacious: Bool) -> CGFloat {
        let limit = spacious ? min(880, max(620, playHeight * 1.4)) : 620
        return min(limit, max(1, availableWidth))
    }
    var compact: Bool { height < 400 }
    var horizontal: Bool { width > height * 1.25 }

    // A lesson always reads top to bottom, in either orientation.
    var hasSideContext: Bool { false }
    var contextWidth: CGFloat { width }
    var answerWidth: CGFloat {
        guard spacious else { return width }
        switch kind {
        case .chooseDigital:
            return min(width, optionCount <= 2 ? 660 : 840)
        case .trueFalse:
            return min(width, 620)
        case .addTime, .subtractTime, .flightArrival, .daySchedule, .timeZone, .minutesBetween, .timeSequence:
            return min(width, horizontal && optionCount >= 4 ? 800 : 670)
        case .chooseAnalog, .activity, .spokenTime, .sortTimes, .match, .setAnalog, .setDigital, .advanceAnalog, .sayTime:
            return width
        default:
            return min(width, 800)
        }
    }

    static let matchingCardInset: CGFloat = 12

    var wordBankWidth: CGFloat { min(spacious ? 790 : 560, width) }

    var answerActionWidth: CGFloat? {
        switch kind {
        case .setAnalog, .setDigital, .advanceAnalog:
            return nil
        case .match:
            return width - (horizontal ? 2 * Self.matchingCardInset : 0)
        case .sayTime:
            return wordBankWidth
        default:
            return answerWidth
        }
    }

    /// Printed boards share a larger type and symbol scale while keeping their internal geometry.
    var contextMagnification: CGFloat {
        guard spacious else { return 1 }
        switch kind {
        case .read24Hour, .minutesBetween, .timeZone, .addTime, .subtractTime, .flightArrival, .daySchedule:
            return min(1.5, max(1.25, width / 620))
        default:
            return 1
        }
    }

    var answerCellWidth: CGFloat {
        let columns = answerColumns()
        return (answerWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns)
    }

    var answerReadoutFont: CGFloat {
        min(48, max(18, answerCellWidth * 0.105))
    }

    var targetDigitalFont: CGFloat {
        if kind == .setAnalog { return min(68, max(54, height * 0.12)) }
        return min(84, max(54, answerCellWidth * 0.19), max(54, height * 0.17))
    }

    var editableDigitalFont: CGFloat {
        min(66, max(52, width * 0.075), max(52, height * 0.115))
    }

    private func digitalDisplayHeight(_ font: CGFloat, withHints: Bool) -> CGFloat {
        let guide = withHints ? DinoQuestionClockMetrics.digitalHintHeight(font: font, spacious: true) : 0
        return font * 1.65 + guide + 8
    }

    var answerRows: Int {
        let columns = answerColumns()
        return max(1, (optionCount + columns - 1) / columns)
    }
    var pairedClocks: Bool { false }
    var horizontalSequence: Bool {
        // Leave room for four clock displays and their connecting arrows.
        kind == .timeSequence && horizontal && width >= 520
    }

    func answerColumns(minimumCardWidth: CGFloat = 112) -> Int {
        guard optionCount == 4 else { return min(2, max(1, optionCount)) }
        let fitsRow = (answerWidth - spacing * 3) / 4 >= minimumCardWidth
        return fitsRow && horizontal && !hasSideContext ? 4 : 2
    }

    var horizontalControls: Bool { horizontal && height < 300 && width >= 500 }

    var clockSize: CGFloat {
        let controls: CGFloat
        switch kind {
        case .setAnalog, .advanceAnalog:
            controls = horizontalControls || (spacious && horizontal && kind == .setAnalog) ? 88 : 142
        case .setDigital:
            controls = spacious ? digitalDisplayHeight(editableDigitalFont, withHints: true) + 48 : pairedClocks ? 116 : 200
        default:
            controls = 0
        }
        let reference: CGFloat = pairedClocks ? 0 : kind == .advanceAnalog ? 96
            : kind == .setAnalog ? (spacious ? digitalDisplayHeight(targetDigitalFont, withHints: true) : 118) : 0
        let heightBudget = kind == .advanceAnalog && !pairedClocks
            ? max(64, (height - controls - 48) / 1.5)
            : max(64, height - controls - reference - spacing)
        let widthBudget = pairedClocks ? width * 0.38 - 24 : contextWidth - 32
        let fitted = max(64, min(widthBudget, heightBudget))
        guard [.chooseDigital, .trueFalse, .readDigital, .setAnalog].contains(kind) else { return fitted }
        if spacious && kind != .setAnalog {
            let answerReserve = CGFloat(answerRows) * (124 + spacing)
            return min(fitted, 470, contextWidth * 0.56, max(64, height - answerReserve - 28))
        }
        // Dragging the hands needs extra space for the controls and comparison.
        let preferredFace = (kind == .setAnalog ? 260 : 210) * min(spacious ? 1.4 : 1.2, sqrt(max(1, contextWidth / 370)))
        return min(fitted, preferredFace)
    }

    var answerClockSize: CGFloat {
        let rows = CGFloat(answerRows)
        let contextReserve: CGFloat
        switch kind {
        case .chooseAnalog, .activity:
            contextReserve = spacious ? digitalDisplayHeight(targetDigitalFont, withHints: kind == .chooseAnalog)
                + (kind == .activity ? 36 : 0) : 100
        case .spokenTime:
            contextReserve = 0
        case .sortTimes:
            contextReserve = horizontal ? 80 : 120
        default:
            contextReserve = 100
        }
        let cellHeight = (height - contextReserve - spacing * rows) / rows
        let extraReadout: CGFloat
        if spacious && kind == .activity {
            extraReadout = max(0, answerReadoutFont - 24) * 1.65
        } else if spacious && kind == .sortTimes {
            extraReadout = max(0, answerReadoutFont - 22) * 1.25
        } else {
            extraReadout = 0
        }
        return max(32, min(answerCellWidth - 24, cellHeight - 56 - extraReadout))
    }
}

/// Size feedback against the clock or card it annotates.
enum DinoQuestionClockMetrics {
    static func digitalHintScale(font: CGFloat, spacious: Bool) -> CGFloat {
        let compactScale = min(1, font / 30)
        return spacious ? min(1.8, max(compactScale, font / 44)) : compactScale
    }

    static func digitalHintHeight(font: CGFloat, spacious: Bool) -> CGFloat {
        50 * digitalHintScale(font: font, spacious: spacious)
    }

    static func verdictDiameter(in width: CGFloat) -> CGFloat {
        min(48, max(26, width * 0.12))
    }
}

/// Existing artwork moves first; newly introduced explanation then becomes visible.
enum DinoQuestionFeedbackTiming {
    static let layout = 0.30
    static let revealDelay = 0.32
    static let reveal = 0.18
    static let replacementFadeOut = 0.10
    /// Editable displays first clear their adjustment arrows, then move into comparison.
    static let controlExit = 0.10
    static let inputRevealDelay = controlExit + revealDelay
}
