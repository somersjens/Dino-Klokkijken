import Foundation

/// Internal teaching steps. Never use these names or values in the player interface.
enum DinoQuestionDifficulty: Int, Codable, CaseIterable, Sendable {
    case introduction, familiar, challenge
    var easier: Self { Self(rawValue: max(0, rawValue - 1))! }
    var harder: Self { Self(rawValue: min(2, rawValue + 1))! }
    var optionCount: Int { self == .introduction ? 2 : 4 }
}

/// 20 exercise types × 6 time families × 3 teaching steps = 360 question categories.
struct DinoQuestionCategory: Hashable, Sendable {
    let type: DinoPracticeQuestion
    let time: DinoPracticeTime
    let difficulty: DinoQuestionDifficulty
    static let all = DinoPracticeQuestion.allCases.flatMap { type in
        DinoPracticeTime.allCases.flatMap { time in
            DinoQuestionDifficulty.allCases.map { Self(type: type, time: time, difficulty: $0) }
        }
    }
}

struct DinoQuestionSkill: Hashable, Sendable {
    let kind: ClockQuestionKind
    let time: DinoPracticeTime
}

struct DinoLearningProgress: Codable, Equatable, Sendable {
    var difficulty: DinoQuestionDifficulty = .introduction
    var consecutiveCorrect = 0
    /// A mistake temporarily overrides the curriculum until the previous step has been recovered.
    var recoveryTarget: DinoQuestionDifficulty? = nil

    mutating func record(correct: Bool, at presented: DinoQuestionDifficulty) {
        if !correct {
            recoveryTarget = DinoQuestionDifficulty(rawValue: max(recoveryTarget?.rawValue ?? 0, presented.rawValue))!
            difficulty = presented.easier
            consecutiveCorrect = 0
        } else {
            guard presented.rawValue >= difficulty.rawValue else { return }
            consecutiveCorrect += 1
            if consecutiveCorrect >= 3 {
                difficulty = presented.harder
                consecutiveCorrect = 0
                if let recoveryTarget, difficulty.rawValue >= recoveryTarget.rawValue { self.recoveryTarget = nil }
            }
        }
    }

    static func key(kind: ClockQuestionKind, time: DinoPracticeTime) -> String { "\(time.rawValue).\(kind.rawValue)" }
    static let validKeys = Set(DinoPracticeTime.allCases.flatMap { time in
        ClockQuestionKind.allCases.map { key(kind: $0, time: time) }
    })
}

extension LevelConfiguration {
    var timeFamily: DinoPracticeTime {
        switch minuteStep {
        case 60: return .whole
        case 30: return .half
        case 15: return .quarter
        case 10: return .tenMinutes
        case 5: return .fiveMinutes
        default: return .minutes
        }
    }


}

extension DinoPracticeTime {
    func teachingMinutes(_ difficulty: DinoQuestionDifficulty) -> [Int] {
        switch (self, difficulty) {
        case (.whole, _): return [0]
        case (.half, _): return [30]
        case (.quarter, .introduction): return [15]
        case (.quarter, .familiar): return [15, 30]
        case (.quarter, .challenge): return [45]
        case (.tenMinutes, .introduction): return [10]
        case (.tenMinutes, .familiar): return [20, 40]
        case (.tenMinutes, .challenge): return [50]
        case (.fiveMinutes, .introduction): return [5, 10]
        case (.fiveMinutes, .familiar): return [20, 25, 35, 40]
        case (.fiveMinutes, .challenge): return [50, 55]
        case (.minutes, .introduction): return focusMinutes.filter { $0 < 15 }
        case (.minutes, .familiar): return focusMinutes.filter { (16...39).contains($0) }
        case (.minutes, .challenge): return focusMinutes.filter { $0 > 40 }
        }
    }

    func reviewMinutes(_ difficulty: DinoQuestionDifficulty) -> [Int] {
        if difficulty == .challenge { return minutes }
        switch self {
        case .whole: return [0]
        case .half: return [0]
        case .quarter: return [0, 30]
        case .tenMinutes: return [0, 30]
        case .fiveMinutes: return [0, 15, 30, 45]
        case .minutes: return Array(stride(from: 0, to: 60, by: 5))
        }
    }
}

/// Shared target and distractor rules for adventure and practice, including all six time families.
enum DinoQuestionTeaching {
    static func target<R: RandomNumberGenerator>(pool: [ClockTime], time: DinoPracticeTime,
                                                 difficulty: DinoQuestionDifficulty, previous: ClockTime?, using rng: inout R) -> ClockTime {
        let fresh = pool.filter { $0 != previous }
        var candidates = fresh.isEmpty ? pool : fresh
        if difficulty == .introduction {
            let clearHands = candidates.filter { [3, 6, 9, 0].contains($0.hour % 12) }
            if !clearHands.isEmpty { candidates = clearHands }
        }
        let focus = time.teachingMinutes(difficulty)
        let review = time.reviewMinutes(difficulty)
        let selected = Int.random(in: 0..<4, using: &rng) < 3 ? focus : review
        let preferred = candidates.filter { selected.contains($0.minute) }
        return (preferred.isEmpty ? candidates : preferred).randomElement(using: &rng)!
    }

    static func distractors<R: RandomNumberGenerator>(pool: [ClockTime], target: ClockTime,
                                                       difficulty: DinoQuestionDifficulty, using rng: inout R) -> [ClockTime] {
        let shuffled = pool.filter { $0 != target }.shuffled(using: &rng)
        // Stable partitioning preserves seeded randomness among equally plausible alternatives.
        let close = shuffled.filter { $0.hour == target.hour || $0.minute == target.minute && abs($0.hour - target.hour) == 1 }
        let closeSet = Set(close)
        let far = shuffled.filter { !closeSet.contains($0) }
        switch difficulty {
        case .introduction: return far + close
        case .familiar: return shuffled
        case .challenge: return close + far
        }
    }
}
