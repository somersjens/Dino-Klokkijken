import Foundation
import CoreGraphics
import ImageIO
import Combine

private var checks = 0
private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    checks += 1
    guard condition() else { fatalError("FAILED: \(message)") }
}

@main
@MainActor
struct DinoCoreTests {
    static func main() async {
        testClocks()
        testHandHintClearance()
        testAnimation()
        testQuestions()
        testWorlds()
        testJungleSceneryClearance()
        testAttempt()
        testAnswerRetries()
        testTiming()
        testPractice()
        testPracticeRecords()
        testExpandedQuestions()
        testUnambiguousQuestionTimes()
        testDemonstrationExamples()
        testProgress()
        testStorage()
        testClockThemes()
        testFixedClockStyles()
        testDinoAppearance()
        testDinoAvatarMask()
        testDinoSpriteColors()
        testPaleBandanaLettering()
        testPlayerModel()
        testMapLevelGuidance()
        testLiveClockChanges()
        testUnchangedInputsDoNotPublish()
        testSettingsAndFeedback()
        testCloudSync()
        testFullReset()
        let socialChecks = await DinoSocialTests.run()
        print("PASS: \(checks + socialChecks) checks — gameplay, persistence, social progress, privacy guards, offline sync and international names.")
    }

    static func testJungleSceneryClearance() {
        for width: CGFloat in [320, 375, 390, 402, 430, 600, 744, 834, 1024, 1194, 1366] {
            let layout = JungleMapLayout(width: width)
            let scene = layout.scene()
            for log in scene.placements.filter({ $0.item.kind == .log }) {
                expect(log.item.mirrored == (log.point.x > width / 2),
                       "each fallen log faces its pale cut toward the road")
                let rear = CGPoint(x: log.point.x + (log.item.mirrored ? 48 : -48) * log.item.size,
                                   y: log.point.y + 7 * log.item.size)
                expect(scene.placements.contains { $0.item.kind == .shrub &&
                    abs($0.point.x - rear.x) < 8 && abs($0.point.y - rear.y) < 1 },
                       "a foreground shrub hides the far end of every log")
            }
            expect(scene === layout.scene(), "unchanged viewport reuses resolved jungle coordinates")
            expect(scene.sceneryTiles.flatMap(\.placements).allSatisfy { !$0.item.kind.animated },
                   "static scenery shares a depth layer while animation stays independent")
            expect(scene.sceneryTiles.contains( where: { $0.includesBoss }),
                   "the jungle boss shares the scenery tiles instead of sitting behind every tree")
            let trailWidth = min(width, 600) - 36
            for (index, fraction) in ([CGFloat(0.5)] + JungleMapLayout.chapterPositions).enumerated() {
                let y = JungleMapLayout.firstNodeY + CGFloat(index) * JungleMapLayout.levelSpacing
                let expected = (width - trailWidth) / 2 + trailWidth * fraction
                expect(abs(layout.centerX(at: y) - expected) < 0.01, "jungle placement follows each real level centre")
            }
            for item in layout.items {
                let point = layout.position(of: item)
                for band in layout.footprint(of: item) {
                    // Check more densely than the placement solver, including
                    // corners between samples, curved road edges and level rims.
                    for offset in 0...Int(ceil(band.height)) {
                        let y = point.y + band.minY + min(band.height, CGFloat(offset))
                        let road = layout.centerX(at: y)
                        let clearance = layout.clearance(at: y)
                        let outside = point.x < width / 2
                            ? point.x + band.maxX < road - clearance
                            : point.x + band.minX > road + clearance
                        expect(outside, "every jungle silhouette clears the road at width \(width), y \(y)")
                    }
                }
            }
            let waterfall = layout.position(of: layout.waterfall)
            expect(waterfall.x < layout.centerX(at: 595) && (590...640).contains(waterfall.y),
                   "the waterfall stands on the left bank near level three")
            expect(layout.waterfall.heightScale == 0.78 && layout.waterfall.mirrored &&
                   layout.waterfall.preferred.x < width / 2 - min(width, 720) * 0.4,
                   "level three waterfall is shorter, at the bank and fed from the left")
            for placement in scene.placements where !placement.item.kind.animated && placement.bounds.intersects(CGRect(x: 0, y: -512, width: width, height: 2560)) {
                expect(scene.sceneryTiles.contains { $0.placements.contains { $0.id == placement.id } },
                       "every static object is retained in the shared depth tiles")
            }
            expect(layout.items.filter(\.foreground).count == 2,
                   "the two entrance trees can occlude the upper waterfall pools")
        }
        let phone = JungleMapLayout(width: 402)
        let oldTree = JungleMapLayout.Item(kind: .tree, preferred: CGPoint(x: 110, y: 1250), size: 1.02)
        let moved = phone.position(of: oldTree)
        expect(moved.x < oldTree.preferred.x - 100,
               "the former tree crossing a higher bend is relocated using its crown, not only its trunk")
    }

    static func testPracticeRecords() {
        let defaults = InMemoryKeyValueStore()
        let store = DinoProgressStore(defaults: defaults)
        let player = DinoPlayer(store: store)
        let config = DinoPracticeConfiguration(time: .half, order: .specific(.chooseAnalog))
        let session = DinoSession(level: config.level, player: player, practice: config)
        var displayedProgress: [DinoSession.PracticeProgress] = []
        let observation = session.$practiceProgress.sink { displayedProgress.append($0) }
        defer { observation.cancel() }
        expect(session.practiceQuestionNumber == 1 && session.practiceStreak == 0, "new combination begins at question one without a streak")
        session.submit(session.question.expectedAnswer)
        session.submit(session.question.expectedAnswer)
        expect(session.practiceProgress == .init() && displayedProgress.count == 1,
               "feedback leaves all HUD counters unchanged, including after duplicate submission")
        expect(player.practiceRecord(time: .half, question: .chooseAnalog) == .init(bestStreak: 1, questionsAnswered: 1, currentStreak: 1),
               "the accepted answer is still persisted immediately and exactly once")
        session.advance()
        expect(displayedProgress == [.init(), .init(streak: 1, bestStreak: 1, questionNumber: 2)],
               "streak, record and question number change in one published update at the next question")
        session.submit(session.question.expectedAnswer); session.advance()
        expect(session.practiceStreak == 2 && session.practiceBestStreak == 2, "a new record rises with every consecutive correct answer")
        let pausedPlayer = DinoPlayer(store: store)
        let pausedSession = DinoSession(level: config.level, player: pausedPlayer, practice: config)
        expect(pausedSession.practiceStreak == 2 && pausedSession.practiceBestStreak == 2 && pausedSession.practiceQuestionNumber == 3,
               "active streak survives pausing and a full app relaunch")
        expect(pausedSession.canExitWithoutConfirmation, "practice can always pause directly")
        let carriedStore = DinoProgressStore(defaults: InMemoryKeyValueStore([
            DinoProgressStore.practiceKey: try! JSONEncoder().encode(pausedPlayer.practiceRecords)
        ]))
        let carriedPlayer = DinoPlayer(store: carriedStore)
        let carriedSession = DinoSession(level: config.level, player: carriedPlayer, practice: config)
        carriedSession.submit(carriedSession.question.expectedAnswer)
        expect(carriedSession.practiceStreak == 2 && carriedSession.practiceQuestionNumber == 3 &&
               carriedPlayer.practiceRecord(time: .half, question: .chooseAnalog).currentStreak == 3,
               "resumed feedback holds both counters while immediately saving the extended streak")
        carriedSession.advance()
        expect(carriedSession.practiceStreak == 3 && carriedSession.practiceBestStreak == 3,
               "a correct answer after resuming extends the saved streak and its record")
        let beforeWrong = session.practiceProgress
        let updateCount = displayedProgress.count
        session.submit(wrongAnswer(for: session.question))
        expect(session.practiceProgress == beforeWrong && displayedProgress.count == updateCount &&
               store.loadPracticeRecords()[DinoPracticeRecord.key(time: .half, question: .chooseAnalog)]?.currentStreak == 0,
               "wrong feedback holds both displayed counters while persisting the broken streak")
        session.showAnswer(); session.advance()
        expect(session.practiceStreak == 0 && session.practiceBestStreak == 2 && session.practiceQuestionNumber == 4, "wrong answers reset the streak, retain the record and count as practiced")
        expect(displayedProgress.count == updateCount + 1 && displayedProgress.last == .init(streak: 0, bestStreak: 2, questionNumber: 4),
               "Next resets the streak and advances the counter in the same update")
        expect(player.practiceRecord(time: .whole, question: .chooseAnalog) == DinoPracticeRecord(), "different time families have independent records")
        expect(player.practiceRecord(time: .half, question: .chooseDigital) == DinoPracticeRecord(), "different question types have independent records")
        let restarted = DinoPlayer(store: store)
        let resumed = DinoSession(level: config.level, player: restarted, practice: config)
        expect(resumed.practiceStreak == 0 && resumed.practiceBestStreak == 2 && resumed.practiceQuestionNumber == 4, "a broken streak also stays broken after relaunch")
        resumed.submit(resumed.question.expectedAnswer)
        expect(resumed.practiceStreak == 0 && resumed.practiceQuestionNumber == 4 &&
               store.loadPracticeRecords()[DinoPracticeRecord.key(time: .half, question: .chooseAnalog)]?.currentStreak == 1,
               "new answers persist immediately without separating the two displayed counters")
        resumed.advance()
        expect(resumed.practiceStreak == 1 && resumed.practiceQuestionNumber == 5, "resumed counters also advance together")
        let beforeHelp = restarted.practiceRecords
        let example = DinoSession(level: config.level, player: restarted, practice: config, example: session.question)
        example.submit(example.question.expectedAnswer)
        expect(restarted.practiceRecords == beforeHelp, "interactive examples cannot set records or increase lifetime counters")

        for order in [DinoPracticeOrder.ascending, .mix] {
            let configuration = DinoPracticeConfiguration(time: .quarter, order: order)
            let session = DinoSession(level: configuration.level, player: restarted, practice: configuration)
            let otherOrder: DinoPracticeOrder = order == .ascending ? .mix : .ascending
            let otherRecord = restarted.practiceRecord(time: .quarter, order: otherOrder)
            expect(session.practiceProgress == .init(), "each mixed mode starts with its own record and counter")
            let count = DinoPracticeQuestion.allCases.count
            for index in 0..<count {
                let type = session.practiceQuestionType!
                let savedType = restarted.practiceRecord(time: .quarter, question: type)
                let held = session.practiceProgress
                session.submit(session.question.expectedAnswer)
                session.submit(session.question.expectedAnswer)
                expect(session.practiceProgress == held, "mixed-mode feedback holds the HUD counters together")
                expect(restarted.practiceRecord(time: .quarter, order: order) ==
                       .init(bestStreak: index + 1, questionsAnswered: index + 1, currentStreak: index + 1),
                       "mixed modes persist one continuous record across question types, without counting duplicates")
                expect(restarted.practiceRecord(time: .quarter, question: type).questionsAnswered == savedType.questionsAnswered + 1 &&
                       restarted.practiceRecord(time: .quarter, question: type).currentStreak == savedType.currentStreak + 1,
                       "mixed modes continue crediting the individual question type")
                session.advance()
                expect(session.practiceProgress == .init(streak: index + 1, bestStreak: index + 1, questionNumber: index + 2),
                       "changing question types advances the mixed-mode streak, trophy and question counter together")
            }
            let reloaded = DinoPlayer(store: store)
            let paused = DinoSession(level: configuration.level, player: reloaded, practice: configuration)
            expect(paused.practiceProgress == session.practiceProgress,
                   "mixed-mode streaks, trophies and counters survive pause and app relaunch")
            let beforeExample = restarted.practiceRecords
            let example = DinoSession(level: configuration.level, player: restarted, practice: configuration, example: session.question)
            example.submit(example.question.expectedAnswer)
            expect(restarted.practiceRecords == beforeExample, "examples never update mixed-mode records")
            session.submit(wrongAnswer(for: session.question))
            let afterWrong = restarted.practiceRecords
            session.submit(session.question.expectedAnswer)
            expect(restarted.practiceRecords == afterWrong && session.practiceStreak == count,
                   "a retry cannot restore a mixed-mode streak or change held feedback counters")
            session.showAnswer(); session.advance()
            expect(session.practiceProgress == .init(streak: 0, bestStreak: count, questionNumber: count + 2),
                   "a wrong answer breaks the mixed-mode streak across question types but retains its trophy")
            session.submit(session.question.expectedAnswer); session.advance()
            expect(session.practiceProgress == .init(streak: 1, bestStreak: count, questionNumber: count + 3),
                   "mixed-mode streaks restart after an error while retaining their record")
            expect(restarted.practiceRecord(time: .quarter, order: otherOrder) == otherRecord &&
                   restarted.practiceRecord(time: .whole, order: order) == .init(),
                   "ascending, mix and different time families have independent mode records")
        }

        for (value, digits, thousands) in [(999, "999", nil), (1_000, "0", "1k"), (1_999, "999", "1k"), (999_999, "999", "999k"), (1_000_000, "0", nil)] {
            let counter = DinoPracticeCounter(value: value)
            expect(counter.digits == digits && counter.thousands == thousands, "counter carries thousands without showing four large digits")
        }
        let key = DinoPracticeRecord.key(time: .mix, question: .setAnalog)
        store.savePracticeRecords([key: .init(bestStreak: 20, questionsAnswered: 999), "unknown": .init(bestStreak: 10, questionsAnswered: 10)])
        let nearThousand = DinoPlayer(store: store)
        let thousandConfig = DinoPracticeConfiguration(time: .mix, order: .specific(.setAnalog))
        let thousandSession = DinoSession(level: thousandConfig.level, player: nearThousand, practice: thousandConfig)
        expect(thousandSession.practiceQuestionNumber == 1_000 && nearThousand.practiceRecords.count == 1, "stored counters resume at the thousand boundary and discard unknown combinations")
        store.savePracticeRecords([key: .init(bestStreak: -1, questionsAnswered: -20, currentStreak: -2)])
        expect(store.loadPracticeRecords()[key] == DinoPracticeRecord(), "invalid negative records are sanitized")
        let oldSave = Data("{\"\(key)\":{\"bestStreak\":12,\"questionsAnswered\":80}}".utf8)
        defaults.set(oldSave, forKey: DinoProgressStore.practiceKey)
        expect(store.loadPracticeRecords()[key] == .init(bestStreak: 12, questionsAnswered: 80), "old saves retain their record and question count without inventing a streak")
        restarted.resetProgress()
        expect(restarted.practiceRecords.isEmpty && store.loadPracticeRecords().isEmpty, "progress reset removes practice records")
        nearThousand.resetAllData()
        expect(nearThousand.practiceRecords.isEmpty && store.loadPracticeRecords().isEmpty, "full reset removes practice records")
    }

    static func testClocks() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 3600)!
        expect(ClockTime(date: Date(timeIntervalSince1970: 0), calendar: calendar) == ClockTime(hour: 1),
               "clock previews use the calendar's local time zone")
        expect(ClockTime(date: Date(timeIntervalSince1970: 82_799), calendar: calendar) == ClockTime(hour: 23, minute: 59),
               "current-time conversion keeps minutes through the end of a day")
        expect(ClockTime(date: Date(timeIntervalSince1970: 82_800), calendar: calendar) == ClockTime(hour: 0),
               "current-time conversion rolls over at local midnight")
        expect(ClockTime(hour: 3).hourAngle == 90, "03:00 short hand")
        expect(ClockTime(hour: 3, minute: 30).hourAngle == 105, "03:30 short hand")
        expect(ClockTime(hour: 3, minute: 45).hourAngle == 112.5, "03:45 short hand")
        expect(ClockTime(hour: 12).hourAngle == 0, "12:00 short hand")
        expect(ClockTime(hour: 8, minute: 30).digitalText == "08:30", "HH:mm leading zero")
        for hour in 0...23 {
            for minute in 0...59 {
                let time = ClockTime(hour: hour, minute: minute)
                expect(time.minuteAngle == Double(minute) * 6, "minute angle")
                expect(time.hourAngle == Double(hour % 12) * 30 + Double(minute) / 2, "hour angle")
                expect(time.digitalText.count == 5, "digital format")
            }
        }
        for hour in 1...12 {
            let angle = Double(hour) * .pi / 6
            expect(ClockTime.snappedHour(x: sin(angle) * 100, y: -cos(angle) * 100) == hour, "drag snapping \(hour)")
        }
        expect(ClockTime.shiftedHour(12, by: 1) == 1, "plus wraps")
        expect(ClockTime.shiftedHour(1, by: -1) == 12, "minus wraps")
        expect(ClockTime(hour: 5, minute: 55).shiftingMinutes(by: 5) == ClockTime(hour: 6), "five minutes forward carries into the next hour")
        expect(ClockTime(hour: 6).shiftingMinutes(by: -5) == ClockTime(hour: 5, minute: 55), "five minutes backward borrows from the previous hour")
        for hour in 1...12 {
            expect(ClockTime(hour: hour, minute: 55).settingMinute(0) == ClockTime(hour: ClockTime.shiftedHour(hour, by: 1)), "dragging forward across twelve moves the hour hand")
            expect(ClockTime(hour: hour).settingMinute(55) == ClockTime(hour: ClockTime.shiftedHour(hour, by: -1), minute: 55), "dragging backward across twelve moves the hour hand")
            for step in [1, 5, 10, 15, 30, 60] {
                for minute in 0..<60 {
                    let time = ClockTime(hour: hour, minute: minute)
                    for delta in [-step, step] {
                        let moved = time.shiftingMinutes(by: delta)
                        expect((1...12).contains(moved.hour), "interactive minute controls retain a twelve-hour display")
                        expect(moved.shiftingMinutes(by: -delta) == time, "minute adjustments reverse through every hour boundary")
                        expect((moved.minutesOfDay - time.minutesOfDay - delta) % 720 == 0, "minute adjustments preserve the full time delta")
                    }
                }
            }
        }
    }

    static func testHandHintClearance() {
        let direction = ClockHandHintGeometry.point(radius: 1, angle: 176.5)
        func alongHand(_ radius: Double) -> CGPoint {
            CGPoint(x: direction.x * radius, y: direction.y * radius)
        }
        expect(abs(ClockHandHintGeometry.segmentDistance(alongHand(0.57), alongHand(0.289), alongHand(-0.035), alongHand(0.23)) - 0.059) < 0.000_001,
               "separate collinear arrows and hands do not intersect through floating-point rounding")
        expect(ClockHandHintGeometry.segmentDistance(CGPoint(x: -1, y: 0), CGPoint(x: 1, y: 0),
                                                    CGPoint(x: 0, y: -1), CGPoint(x: 0, y: 1)) == 0,
               "crossing pointer segments still have zero clearance")
        for widths in [(0.038, 0.024), (0.055, 0.036)] {
            for hour in 1...12 {
                for minute in 0..<60 {
                    let time = ClockTime(hour: hour, minute: minute)
                    let pointers = ClockHandHintGeometry.pointers(time: time, hourWidth: widths.0, minuteWidth: widths.1)
                    let hands = [(time.hourAngle, 0.23, widths.0), (time.minuteAngle, 0.34, widths.1)]
                    let difference = abs((time.hourAngle - time.minuteAngle + 540).truncatingRemainder(dividingBy: 360) - 180)
                    for (index, pointer) in pointers.enumerated() {
                        let direction = ClockHandHintGeometry.point(radius: 1, angle: hands[index].0)
                        let alignment = [pointer.start, pointer.tip, pointer.badge].map {
                            abs($0.x * direction.y - $0.y * direction.x)
                        }
                        if difference >= 22 {
                            expect(alignment.allSatisfy { $0 < 0.000_001 },
                                   "arrows and number badges follow their hand at \(time.digitalText)")
                            let arrow = CGPoint(x: pointer.tip.x - pointer.start.x, y: pointer.tip.y - pointer.start.y)
                            expect(arrow.x * direction.x + arrow.y * direction.y < 0,
                                   "aligned arrows point inward toward their hand at \(time.digitalText)")
                        } else {
                            expect(alignment.contains { $0 > 0.01 },
                                   "nearby hands retain the side pointers at \(time.digitalText)")
                        }
                    }
                    for pointer in pointers {
                        for hand in hands {
                            let start = ClockHandHintGeometry.point(radius: -0.035, angle: hand.0)
                            let end = ClockHandHintGeometry.point(radius: hand.1, angle: hand.0)
                            for edge in [pointer.start] + pointer.arrowWings {
                                let clearance = ClockHandHintGeometry.segmentDistance(edge, pointer.tip, start, end) - hand.2 / 2
                                expect(clearance > 0.015, "arrows stay clear of both hands at \(time.digitalText), including their heads")
                            }
                        }
                    }
                    expect(hypot(pointers[0].badge.x - pointers[1].badge.x, pointers[0].badge.y - pointers[1].badge.y) > 0.2,
                           "number badges remain separate at \(time.digitalText)")
                }
            }
        }
    }

    static func checkMatchingQuestion(_ question: ClockQuestion) {
        expect(question.relatedTimes.count == 3 && question.options.count == 3, "matching has three clocks and three times")
        expect(Set(question.relatedTimes) == Set(question.options), "every clock has exactly one matching time")
        expect(Set(question.relatedTimes.map { ($0.hour % 12) * 60 + $0.minute }).count == 3, "matching faces are distinct")
        expect(question.expectedAnswer == .pairs(question.relatedTimes), "matching validates all three pairs")
        expect(!AnswerValidator.isCorrect(.pairs(Array(question.relatedTimes.dropLast())), for: question), "incomplete pairs cannot answer the question")
        expect(!AnswerValidator.isCorrect(.pairs(Array(question.relatedTimes.reversed())), for: question), "wrong pairs cannot answer the question")
    }

    static func testPractice() {
        expect(DinoPracticeQuestion.allCases.count == 19, "practice contains nineteen distinct question types")
        expect(DinoPracticeQuestion.match.number == 7, "matching remains question type seven")
        expect(DinoPracticeQuestion.read24Hour.number == 10 && DinoPracticeQuestion.timeZone.number == 19,
               "question numbers close the gap after the removed duplicate")
        expect(DinoPracticeQuestion(rawValue: "pairClocks") == nil && ClockQuestionKind(rawValue: "pairClocks") == nil,
               "the duplicate pairing exercise is retired from practice and levels")
        expect(Set(DinoPracticeQuestion.allCases.map { $0.recipe.kind }) == Set(ClockQuestionKind.allCases).subtracting([.activity]), "practice omits the duplicate activity type")
        let orders = DinoPracticeQuestion.allCases.map { DinoPracticeOrder.specific($0) } + [.ascending, .mix]
        for time in DinoPracticeTime.allCases {
            for order in orders {
                let configuration = DinoPracticeConfiguration(time: time, order: order)
                var generator = DinoPracticeGenerator(configuration: configuration, seed: 42)
                var replay = DinoPracticeGenerator(configuration: configuration, seed: 42)
                var previous: ClockTime?
                var blockTypes: [ClockQuestionKind] = []
                for index in 0..<120 {
                    let question = generator.next(index: index)
                    expect(question == replay.next(index: index), "practice seed is reproducible")
                    expect(question.id == index && time.minutes.contains(question.target.minute), "practice IDs and selected time granularity")
                    expect(question.target != previous, "practice avoids consecutive duplicate times")
                    previous = question.target
                    if case .specific(let type) = order {
                        expect(question.kind == type.recipe.kind, "specific practice keeps chosen type")
                    }
                    if order == .ascending {
                        let recipe = DinoPracticeQuestion.allCases[index % DinoPracticeQuestion.allCases.count].recipe
                        expect(question.kind == recipe.kind, "ascending cycles through every type indefinitely")
                    }
                    if order == .mix {
                        blockTypes.append(question.kind)
                        if blockTypes.count == DinoPracticeQuestion.allCases.count {
                            expect(DinoPracticeQuestion.allCases.allSatisfy { blockTypes.contains($0.recipe.kind) }, "every mixed block covers all unique types")
                            blockTypes.removeAll()
                        }
                    }
                    expect(Set(question.options).count == question.options.count, "unique practice distractors")
                    expect(question.options.allSatisfy { time.minutes.contains($0.minute) }, "practice options use the selected time family")
                    if question.kind.usesOptions {
                        expect(question.responses.filter { $0 == question.expectedAnswer }.count == 1, "exactly one correct response")
                        expect(Set(question.responses).count == question.responses.count, "unique response choices")
                    }
                    if [.chooseAnalog, .chooseDigital].contains(question.kind) {
                        expect([2, 4].contains(question.options.count), "choice count remains an internal difficulty variation")
                    }
                    if [.setAnalog, .setDigital, .advanceAnalog].contains(question.kind) {
                        expect(question.options.isEmpty, "setting a clock has no options")
                    }
                    if question.kind == .match { checkMatchingQuestion(question) }
                    if let activity = question.activity { expect(activity.hour == question.target.hour, "practice activity time remains consistent") }
                    expect(question.companionClocks.count == 2 && !question.companionClocks.contains(question.target), "matching companions differ from selected clock")
                    expect(AnswerValidator.isCorrect(question.expectedAnswer, for: question), "every practice question can be answered")
                }
            }
            for minute in stride(from: 0, to: 60, by: time.minuteStep) {
                let angle = Double(minute) * .pi / 30
                expect(ClockTime.snappedMinute(x: sin(angle), y: -cos(angle), step: time.minuteStep) == minute, "minute hand snaps across twelve")
                for hour in 1...12 {
                    let hourAngle = ClockTime(hour: hour, minute: minute).hourAngle * .pi / 180
                    expect(ClockTime.snappedHour(x: sin(hourAngle), y: -cos(hourAngle), minute: minute) == hour, "hour dragging preserves its fractional-minute offset")
                }
            }
        }
        expect(ClockTime.shiftedMinute(0, by: -5) == 55 && ClockTime.shiftedMinute(55, by: 5) == 0, "minute controls wrap both directions")
        let store = DinoProgressStore(defaults: InMemoryKeyValueStore())
        let player = DinoPlayer(store: store)
        player.completeOnboarding(theme: .standard)
        let original = player.profile
        var uploads = 0
        player.progressChanged = { uploads += 1 }
        let config = DinoPracticeConfiguration(time: .mix, order: .ascending)
        var now = 100.0
        let session = DinoSession(level: config.level, player: player, practice: config, now: { now })
        session.demonstration = .setAnalog
        session.submit(session.question.target)
        expect(session.practiceAnswered == 0, "help cannot answer a practice question")
        session.dismissDemonstration()
        for index in 0..<1_000 {
            expect(session.question.id == index && session.demonstration == nil, "practice continues past finite levels without forced help")
            session.advance()
            expect(session.question.id == index, "unanswered practice question cannot be skipped")
            let correct = index.isMultiple(of: 2)
            let answer = correct ? session.question.expectedAnswer : wrongAnswer(for: session.question)
            if case .time(let time) = answer {
                session.inputHour = time.hour; session.inputMinute = time.minute
                expect(session.inputTime == time, "submission includes minutes and 24-hour times")
            }
            now += 90
            session.submit(answer)
            session.submit(answer)
            expect(session.practiceAnswered == index + 1, "practice ignores duplicate submissions")
            expect(session.attempt.questionSeconds == [60], "practice answer timing remains bounded")
            session.showAnswer()
            session.advance()
            expect(session.attempt.answers.isEmpty && session.attempt.questions.count == 1, "endless practice retains only current question")
            let expectedMinute = session.question.kind == .advanceAnalog ? session.question.relatedTimes[0].minute : 0
            expect(session.result == nil && session.inputMinute == expectedMinute, "practice never finishes and initializes the appropriate clock")
            expect(session.selectedOrder.isEmpty && session.pairSelections.isEmpty, "board selections reset for every question")
        }
        expect(session.practiceCorrect == 500, "practice keeps a correct running count")
        expect(player.profile == original && store.load() == original && uploads == 0, "practice and help never save progress or upload level scores")
    }


    static func wrongAnswer(for q: ClockQuestion) -> ClockAnswer {
        switch q.expectedAnswer {
        case .time(let time): return .time(time.adding(minutes: 60))
        case .duration(let minutes): return .duration(minutes + 1)
        case .truth(let truth): return .truth(!truth)
        case .dayPart(let part): return .dayPart(DinoDayPart.allCases.first { $0 != part }!)
        case .ordering(let times): return .ordering(Array(times.reversed()))
        case .pairs(let times): return .pairs(Array(times.reversed()))
        }
    }

    static func testDemonstrationExamples() {
        expect(DinoDemonstrationExamples.time(index: 0, minutes: [0]) == ClockTime(hour: 3), "whole-hour example starts at three")
        expect(DinoDemonstrationExamples.time(index: 1, minutes: [0]) == ClockTime(hour: 4), "another whole-hour example advances one hour")
        expect(DinoDemonstrationExamples.time(index: 2, minutes: [0]) == ClockTime(hour: 5), "whole-hour examples keep advancing")
        expect(DinoDemonstrationExamples.time(index: 9, minutes: [0]) == ClockTime(hour: 12), "examples retain twelve instead of zero on a twelve-hour clock")
        expect(DinoDemonstrationExamples.time(index: 10, minutes: [0]) == ClockTime(hour: 1), "examples wrap past twelve")
        expect(DinoDemonstrationExamples.time(index: 1, minutes: [30]) == ClockTime(hour: 4, minute: 30), "half-hour examples retain thirty minutes")
        expect(DinoDemonstrationExamples.time(index: 1, minutes: [15, 45]) == ClockTime(hour: 3, minute: 45), "quarter-hour examples advance to quarter to")
        expect(DinoDemonstrationExamples.time(index: 2, minutes: [15, 45]) == ClockTime(hour: 4, minute: 15), "quarter-hour examples advance to the next hour")
        expect(DinoDemonstrationExamples.time(index: 5, minutes: DinoPracticeTime.tenMinutes.minutes) == ClockTime(hour: 4, minute: 10), "ten-minute examples skip disallowed whole hours")
        let families = DinoPracticeTime.allCases.map { ($0.minutes, $0.minuteStep) }
            + DinoWorldCatalog.worlds.map { ($0.minutes, $0.minuteStep) }
        let player = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
        let profile = player.profile
        let records = player.practiceRecords
        for (minutes, step) in families {
            var previousTime: ClockTime?
            for index in 0..<(12 * minutes.count + 1) {
                let time = DinoDemonstrationExamples.time(index: index, minutes: minutes)
                expect(minutes.contains(time.minute) && (1...12).contains(time.hour), "simple examples always match the selected time family")
                expect(time != previousTime, "another example changes the clock position")
                previousTime = time
            }
            for kind in ClockQuestionKind.allCases where kind.isExpanded {
                var previous: ClockTime?
                for index in 0..<30 {
                    let q = DinoDemonstrationExamples.question(kind: kind, minutes: minutes, minuteStep: step,
                                                              index: index, previousTarget: previous)
                    expect(q.kind == kind && minutes.contains(q.target.minute), "expanded examples retain question type and minute family")
                    expect(q.target != previous, "expanded examples do not repeat their previous target")
                    expect(AnswerValidator.isCorrect(q.expectedAnswer, for: q), "each refreshed example has a valid worked answer")
                    switch kind {
                    case .addTime, .advanceAnalog, .schoolEnd, .flightArrival, .timeSequence:
                        expect(q.relatedTimes.last!.adding(minutes: q.durationMinutes) == q.target, "example addition and sequence answers agree with their context")
                    case .subtractTime:
                        expect(q.relatedTimes[0].adding(minutes: -q.durationMinutes) == q.target, "example subtraction answer agrees with its context")
                    case .elapsedTime:
                        expect(q.relatedTimes[0].adding(minutes: q.durationMinutes) == q.relatedTimes[1], "example duration agrees with both times")
                    case .timeZone:
                        expect(q.relatedTimes[0].adding(minutes: q.offsetHours * 60) == q.target, "example zone answer agrees with the stated offset")
                    default: break
                    }
                    previous = q.target
                    if index < 2 {
                        let config = DinoPracticeConfiguration(time: .whole, order: .specific(DinoPracticeQuestion(rawValue: kind.rawValue)!))
                        let sample = DinoSession(level: config.level, player: player, practice: config, example: q, exampleMinuteStep: step)
                        sample.submit(q.expectedAnswer)
                        expect(sample.correctFeedback && sample.minuteStep == step, "replacement example has fresh answer state and correct controls")
                    }
                }
            }
        }
        expect(player.profile == profile && player.practiceRecords == records, "refreshing and answering examples preserves saved progress and practice records")
        expect(DinoDemonstrationExamples.activity(index: 0).hour == 3, "activity example starts with fruit at three")
        expect(Set((0..<5).map { DinoDemonstrationExamples.activity(index: $0) }).count == 5, "activity examples cycle all real activities")
    }

    static func testUnambiguousQuestionTimes() {
        for time in DinoPracticeTime.allCases {
            var dayParts = DinoPracticeGenerator(configuration: .init(time: time, order: .specific(.dayPart)), seed: 20261015)
            var sorting = DinoPracticeGenerator(configuration: .init(time: time, order: .specific(.sortTimes)), seed: 20261015)
            var seenParts = Set<DinoDayPart>()
            for index in 0..<500 {
                let dayPart = dayParts.next(index: index)
                expect(dayPart.target.hour != 6 && dayPart.target.hour < 22,
                       "day-part questions exclude 06:00–06:59 and 22:00–23:59 in every minute family")
                seenParts.insert(DinoDayPart(hour: dayPart.target.hour))
                let sorted = sorting.next(index: index)
                expect(sorted.options.allSatisfy { $0.minutesOfDay != 0 }, "sorting never includes 00:00")
                expect(Set(sorted.options).count == 4, "filtering midnight preserves four distinct sorting choices")
            }
            expect(seenParts == Set(DinoDayPart.allCases), "unambiguous questions still practice all four day parts")
        }
        for minutes in [[0], [59]] {
            let examples = (0..<24).map {
                DinoDemonstrationExamples.question(kind: .dayPart, minutes: minutes, minuteStep: 1,
                                                   index: $0, previousTarget: nil).target
            }
            for hour in [6, 22, 23] {
                expect(examples.contains(ClockTime(hour: hour, minute: minutes[0])),
                       "day-part examples retain the excluded question hours, including both minute boundaries")
            }
        }
        for time in [ClockTime(hour: 6), ClockTime(hour: 6, minute: 59), ClockTime(hour: 22), ClockTime(hour: 23, minute: 59)] {
            var rng = SeededGenerator(seed: 20261015)
            let question = DinoExpandedQuestions.generate(kind: .dayPart, minutes: [time.minute], minuteStep: 1,
                                                          index: 0, previousTarget: nil, preferredTarget: time, using: &rng)
            expect(question.target != time, "preferred targets cannot bypass the day-part question filter")
        }
    }

    static func testExpandedQuestions() {
        expect(ClockTime(hour: 23, minute: 55).adding(minutes: 10) == ClockTime(hour: 0, minute: 5), "addition crosses midnight")
        expect(ClockTime(hour: 0, minute: 5).adding(minutes: -10) == ClockTime(hour: 23, minute: 55), "subtraction crosses midnight")
        expect(ClockTime(hour: 22).adding(minutes: -180) == ClockTime(hour: 19), "source exercise subtraction")
        expect(DinoTimeWords.time(.init(hour: 0), language: "nl", dayPart: true) == "twaalf uur ’s nachts", "00:00 spoken correctly")
        expect(DinoTimeWords.time(.init(hour: 15, minute: 30), language: "nl", dayPart: true) == "half vier ’s middags", "Dutch half hour refers to next hour")
        expect(DinoTimeWords.time(.init(hour: 23, minute: 45), language: "nl") == "kwart voor twaalf", "quarter before midnight")
        expect(DinoTimeWords.time(.init(hour: 13, minute: 30), language: "en", dayPart: true) == "half past one in the afternoon", "English half-hour wording")
        for (hour, part) in [(0, DinoDayPart.night), (5, .night), (6, .morning), (11, .morning), (12, .afternoon), (17, .afternoon), (18, .evening), (23, .evening)] {
            expect(DinoDayPart(hour: hour) == part, "part-of-day boundaries")
        }
        for time in DinoPracticeTime.allCases {
            for type in DinoPracticeQuestion.allCases where type.recipe.kind.isExpanded {
                let kind = type.recipe.kind
                let example = DinoExpandedQuestions.example(kind: kind, time: time)
                expect(example == DinoExpandedQuestions.example(kind: kind, time: time), "worked example is reproducible")
                expect(AnswerValidator.isCorrect(example.expectedAnswer, for: example), "example has a valid answer")
                var generator = DinoPracticeGenerator(configuration: .init(time: time, order: .specific(type)), seed: 20261012)
                var sawMidnight = false
                for index in 0..<150 {
                    let q = generator.next(index: index)
                    expect(!AnswerValidator.isCorrect(wrongAnswer(for: q), for: q), "wrong typed answer rejected")
                    switch kind {
                    case .addTime, .advanceAnalog, .schoolEnd, .flightArrival:
                        expect(q.relatedTimes[0].adding(minutes: q.durationMinutes) == q.target, "later-time arithmetic")
                        sawMidnight = sawMidnight || q.relatedTimes[0].minutesOfDay > q.target.minutesOfDay
                        if kind == .advanceAnalog {
                            let face = ClockTime(hour: q.target.hour % 12 == 0 ? 12 : q.target.hour % 12, minute: q.target.minute)
                            expect(AnswerValidator.isCorrect(face, for: q), "analog answers accept the matching 12-hour face")
                        }
                    case .subtractTime:
                        expect(q.relatedTimes[0].adding(minutes: -q.durationMinutes) == q.target, "earlier-time arithmetic")
                        sawMidnight = sawMidnight || q.relatedTimes[0].minutesOfDay < q.target.minutesOfDay
                    case .elapsedTime:
                        expect(q.relatedTimes[0].adding(minutes: q.durationMinutes) == q.relatedTimes[1], "duration matches elapsed time")
                        sawMidnight = sawMidnight || q.relatedTimes[0].minutesOfDay > q.relatedTimes[1].minutesOfDay
                    case .timeSequence:
                        expect(q.relatedTimes.count == 3, "three terms in pattern")
                        let all = q.relatedTimes + [q.target]
                        for pair in zip(all, all.dropFirst()) {
                            expect(pair.0.adding(minutes: q.durationMinutes) == pair.1, "every sequence step is identical")
                        }
                    case .timeZone:
                        expect(q.relatedTimes[0].adding(minutes: q.offsetHours * 60) == q.target, "explicit zone difference determines answer")
                    case .sortTimes:
                        guard case .ordering(let ordered) = q.expectedAnswer else { fatalError("sorting answer") }
                        expect(ordered.count == 4 && Set(ordered) == Set(q.options), "sorting uses exactly the displayed clocks")
                        expect(ordered.map(\.minutesOfDay) == ordered.map(\.minutesOfDay).sorted(), "sorting is chronological on one day")
                    case .trueFalse:
                        expect(q.expectedAnswer == .truth(q.statement == q.target), "truth judgement matches statement")
                    case .dayPart:
                        expect(q.expectedAnswer == .dayPart(.init(hour: q.target.hour)), "digital hour determines day part")
                    default: break
                    }
                }
                if time == .whole && [.addTime, .advanceAnalog, .schoolEnd, .flightArrival, .subtractTime, .elapsedTime].contains(kind) {
                    expect(sawMidnight, "generated whole-hour arithmetic covers midnight: \(kind)")
                }
            }
        }
        let player = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
        let before = player.profile
        let configuration = DinoPracticeConfiguration(time: .quarter, order: .specific(.addTime))
        let active = DinoSession(level: configuration.level, player: player, practice: configuration)
        let question = active.question
        for type in DinoPracticeQuestion.allCases where type.recipe.kind.isExpanded {
            let sampleQuestion = DinoExpandedQuestions.example(kind: type.recipe.kind, time: .quarter)
            let sample = DinoSession(level: configuration.level, player: player, practice: configuration, example: sampleQuestion)
            sample.submit(sampleQuestion.expectedAnswer)
            sample.submit(wrongAnswer(for: sampleQuestion))
            expect(sample.hasFeedback && sample.practiceAnswered == 1 && sample.correctFeedback, "interactive example accepts only one answer")
            expect(active.question == question && active.practiceAnswered == 0, "help uses an independent question and score")
        }
        expect(player.profile == before, "interactive examples preserve saved profile")
    }

    static func testAnimation() {
        // Sparse image transitions cannot interrupt the complete turn or ground contact.
        var previous = DinoAnimation.sample(.backflip, elapsed: 0)
        for step in 1...222 {
            let sample = DinoAnimation.sample(.backflip, elapsed: Double(step) / 120)
            expect(sample.angle <= previous.angle && sample.angle >= -360, "single forward backflip")
            expect(abs(sample.angle - previous.angle) < 5, "no skipped rotation at pose changes")
            expect(abs(sample.height - previous.height) < 0.02, "continuous jump arc")
            expect(sample.height <= 0.00001, "bounded animation")
            if (0.20..<1.22).contains(Double(step) / 120) {
                expect(sample.pose.asset == "dino-backflip-03", "one stable airborne pose throughout the turn")
            }
            previous = sample
        }
        expect(previous.angle == -360 && abs(previous.height) < 0.00001, "lands upright at starting height")
        for (clip, asset) in [(DinoAnimation.Clip.backflip, "dino-backflip-08"), (.thumbsUp, "dino-thumbs-up-08"), (.wrongAnswer, "dino-wrong-answer-04")] {
            for step in 0...180 {
                let t = Double(step) / 120
                let reduced = DinoAnimation.sample(clip, elapsed: t, reducedMotion: true)
                expect(reduced.height == 0 && reduced.angle == 0 && reduced.scaleX == 1 && reduced.scaleY == 1 && reduced.pose.asset == asset, "reduced motion remains completely static")
                guard clip != .backflip else { continue }
                let reaction = DinoAnimation.sample(clip, elapsed: t)
                expect(reaction.pose.asset == asset && reaction.height == 0, "one reaction image without pose flicker or jumping")
                expect(abs(reaction.angle) <= 2 && (1...1.04).contains(reaction.scaleX), "subtle bounded reaction")
                if t >= DinoAnimation.duration(clip) {
                    expect(reaction.angle == 0 && reaction.scaleX == 1 && reaction.scaleY == 1, "reaction settles and stays still until next question")
                }
            }
        }
        expect(DinoAnimation.duration(.thumbsUp) < DinoAnimation.correctAnswerDelay && DinoAnimation.correctAnswerDelay < 1, "complete thumbs before quick advance")
    }

    static func testQuestions() {
        expect(DinoLevelCatalog.levels.count == 100, "100 levels")
        var observedKinds = Set<ClockQuestionKind>()
        for seed in 0..<300 {
            for level in DinoLevelCatalog.levels.filter({ $0.worldID == 1 }) {
                var rng = SeededGenerator(seed: UInt64(seed))
                let questions = DinoQuestionGenerator.generate(level: level, attempt: seed % 3, using: &rng)
                expect(questions.count == (level.isBoss ? 10 : 5), "question count")
                expect(Set(questions.map(\.id)).count == questions.count, "unique IDs")
                expect(Set(questions.map { $0.target.hour }).count == questions.count, "no duplicate target within attempt")
                for (index, q) in questions.enumerated() {
                    observedKinds.insert(q.kind)
                    expect((1...12).contains(q.target.hour) && q.target.minute == 0, "whole hours only")
                    expect(q.kind == level.recipes[index % level.recipes.count].kind, "configured type")
                    if q.kind.usesOptions {
                        expect([2, 4].contains(q.options.count), "balanced answer rows, never three choices")
                        expect(q.options.count == level.recipes[index % level.recipes.count].optionCount, "option count")
                        expect(Set(q.options).count == q.options.count, "unique options")
                        expect(q.options.filter { AnswerValidator.isCorrect($0, for: q) }.count == 1, "exactly one correct answer")
                        if index > 0, questions[index - 1].options.count == q.options.count {
                            expect(q.options.firstIndex(of: q.target) != questions[index - 1].options.firstIndex(of: questions[index - 1].target), "correct position changes")
                        }
                    } else if q.kind == .match { checkMatchingQuestion(q) }
                    else { expect(q.options.isEmpty, "no options for controls") }
                    if let activity = q.activity { expect(activity.hour == q.target.hour, "explicit activity time") }
                }
                if level.isBoss && seed % 3 == 0 {
                    expect(Array(questions.prefix(4).map { $0.target.hour }) == [3, 8, 11, 6], "first boss prescribed times")
                }
            }
        }
        expect(observedKinds == Set(DinoLevelCatalog.levels.filter { $0.worldID == 1 }.flatMap { $0.recipes.map(\.kind) }), "jungle catalog interactions")
    }

    static func testWorlds() {
        expect(DinoWorldCatalog.worlds.count == 10, "ten themed worlds")
        expect(DinoLevelCatalog.levels.map(\.id) == Array(1...100) && DinoLevelCatalog.level(101) == nil, "catalog stops at coming soon after 100")
        var profile = PlayerProfile()
        expect(!profile.isUnlocked(11) && !profile.isUnlocked(100), "later worlds start locked")
        for world in DinoWorldCatalog.worlds {
            expect(world.levels.count == 10 && world.normalLevels.count == 9, "nine levels and a boss")
            expect(profile.isUnlocked(world.firstLevel) && profile.isUnlocked(world.bossLevel), "unlocked world has first level and direct boss")
            expect(profile.recordCompletedAttempt(levelID: world.bossLevel, correct: 9) == .none, "nonperfect direct boss needs its own normal route")
            for id in world.normalLevels {
                expect(profile.isUnlocked(id), "normal route unlocks sequentially")
                profile.recordCompletedAttempt(levelID: id, correct: 3)
            }
            expect(profile.recordCompletedAttempt(levelID: world.bossLevel, correct: 5) == .normal, "normal victory is scoped to this world")
            expect(profile.worldComplete(world.id), "each boss completes its own world")
            if world.id < 10 { expect(profile.isUnlocked(world.bossLevel + 1), "next world opens after boss") }
        }
        expect(profile.adventureComplete && profile.dinoLevel == 100 && profile.totalStars == 90, "complete route reaches 100 and totals all 90 normal levels")
        let store = DinoProgressStore(defaults: InMemoryKeyValueStore())
        store.save(profile)
        expect(store.load() == profile, "all 100 level records and world victories survive restart")
        var cloud = PlayerProfile()
        cloud.mergeCloudProgress(DinoCloudProgress(profile))
        expect(cloud.adventureComplete && cloud.dinoLevel == 100 && cloud.totalStars == 90, "all worlds survive cloud merge")
        cloud.resetProgress()
        expect(cloud.dinoLevel == 0 && !cloud.isUnlocked(11) && cloud.totalStars == 0, "reset clears every world")
        var direct = PlayerProfile()
        for world in DinoWorldCatalog.worlds {
            expect(direct.recordCompletedAttempt(levelID: world.bossLevel, correct: 10) == .perfect, "perfect shortcuts work in all worlds")
            expect(world.levels.allSatisfy { direct.isUnlocked($0) }, "perfect unlock is scoped to the winning world")
        }
        expect(direct.adventureComplete && direct.dinoLevel == 100 && direct.totalStars == 0, "boss shortcuts never fabricate stars")
        for seed in 0..<20 {
            for level in DinoLevelCatalog.levels.filter({ $0.worldID > 1 }) {
                var rng = SeededGenerator(seed: UInt64(seed))
                let questions = DinoQuestionGenerator.generate(level: level, using: &rng)
                expect(questions.count == level.questionCount, "new world question count")
                for q in questions {
                    expect(level.allowedMinutes.contains(q.target.minute), "world-specific clock granularity")
                    expect(AnswerValidator.isCorrect(q.expectedAnswer, for: q), "generated expected answer is valid")
                    if q.kind.usesOptions {
                        expect([2, 4].contains(q.responses.count), "full answer rows")
                        expect(Set(q.responses).count == q.responses.count, "distinct responses")
                        expect(q.responses.filter { AnswerValidator.isCorrect($0, for: q) }.count == 1, "one correct response")
                    }
                    if q.kind == .match { checkMatchingQuestion(q) }
                    if q.kind == .elapsedTime {
                        expect(q.relatedTimes[0].adding(minutes: q.durationMinutes) == q.relatedTimes[1], "elapsed duration matches endpoints")
                    }
                }
            }
        }
    }

    static func testAttempt() {
        let level = DinoLevelCatalog.level(1)!
        var rng = SeededGenerator(seed: 4)
        var attempt = LevelAttempt(levelID: 1, questions: DinoQuestionGenerator.generate(level: level, using: &rng))
        attempt.advance()
        expect(attempt.index == 0, "cannot skip an unanswered question")
        for index in 0..<5 {
            let q = attempt.current
            let wrong = ClockTime(hour: ClockTime.shiftedHour(q.target.hour, by: 1))
            let desired = index < 2 ? q.target : wrong
            expect(attempt.submit(desired) == (index < 2), "one point per right answer")
            expect(attempt.submit(q.target) == nil, "second answer rejected")
            expect(attempt.answers.count == index + 1, "no duplicate score")
            attempt.advance()
        }
        expect(attempt.isComplete && attempt.correctCount == 2, "final result after five")
        expect(attempt.submit(attempt.current.target) == nil, "cannot score after completion")
        for score in 0...5 { expect(StarCalculator.stars(correct: score) == [0,0,0,1,2,3][score], "star thresholds") }
    }

    @MainActor
    static func testAnswerRetries() {
        let store = DinoProgressStore(defaults: InMemoryKeyValueStore())
        let player = DinoPlayer(store: store)
        for type in DinoPracticeQuestion.allCases where type.recipe.kind.usesOptions {
            let config = DinoPracticeConfiguration(time: .mix, order: .specific(type))
            var generator = DinoPracticeGenerator(configuration: config, seed: 42)
            var question = generator.next(index: 0)
            // Choose a four-option variation for the original clock questions.
            for index in 1..<20 where question.responses.count <= 2 && type != .trueFalse {
                question = generator.next(index: index)
            }
            var feedback: [Bool] = []
            var now = 10.0
            let session = DinoSession(level: config.level, player: player, practice: config, example: question,
                                      now: { now }, answerFeedback: { feedback.append($0) })
            session.showAnswer()
            expect(!session.answerRevealed && !session.canRetry, "unanswered questions cannot reveal their answer")
            let wrong = question.responses.filter { $0 != question.expectedAnswer }
            now += 3
            session.submit(wrong[0])
            let allowsRetry = question.responses.count > 2
            expect(session.canRetry == allowsRetry && session.showsCorrectResponse != allowsRetry, "only multiple choice with more than two options allows retries")
            expect(!session.responseIsEnabled(wrong[0]), "a rejected option cannot be selected again")
            session.submit(wrong[0])
            expect(feedback == [false], "repeated taps on a rejected answer are ignored")
            if allowsRetry {
                session.advance()
                expect(session.attempt.index == 0, "the player must solve or reveal a failed multiple-choice question before Next")
                expect(session.responseIsEnabled(question.expectedAnswer), "the correct answer stays available without being highlighted")
                now += 100
                session.submit(wrong[1])
                expect(session.rejectedResponses == Set(wrong.prefix(2)) && session.canRetry, "additional wrong choices stay marked while retries remain available")
                session.submit(question.expectedAnswer)
                expect(session.correctFeedback && !session.canRetry && session.showsCorrectResponse && !session.shouldAutoAdvance,
                       "a correct retry reveals the answer and waits for Next")
                expect(feedback == [false, false, true], "retries emit the appropriate answer reaction")
            } else {
                session.submit(question.expectedAnswer)
                expect(!session.correctFeedback && feedback == [false], "two-option questions keep their existing final feedback")
            }
            session.submit(question.expectedAnswer)
            expect(session.attempt.answers == [false] && session.attempt.correctCount == 0 && session.attempt.questionSeconds == [3],
                   "retries never change the first score or the original answer time")
            expect(session.practiceAnswered == 1 && session.practiceCorrect == 0, "practice retries never add a question or a point")
            expect(question.responses.allSatisfy { !session.responseIsEnabled($0) }, "all choices close after correction or final feedback")

            let revealed = DinoSession(level: config.level, player: player, practice: config, example: question)
            revealed.submit(wrong[0]); revealed.showAnswer(); revealed.showAnswer()
            revealed.submit(question.expectedAnswer)
            expect(revealed.answerRevealed == allowsRetry && revealed.showsCorrectResponse && !revealed.canRetry && !revealed.correctFeedback,
                   "Show answer reveals the correct choice and closes retries without awarding points")
        }

        let level = DinoLevelCatalog.level(10)!
        let session = DinoSession(level: level, player: player)
        session.submit(session.question.responses.first { $0 != session.question.expectedAnswer }!)
        session.submit(session.question.expectedAnswer)
        session.advance()
        expect(session.attempt.index == 1 && session.attempt.answers == [false] && session.rejectedResponses.isEmpty &&
               !session.retryAnsweredCorrectly && !session.answerRevealed && !session.hasFeedback,
               "Next clears retry state for the following level question")
        for _ in 1..<level.questionCount { session.submit(session.question.expectedAnswer); session.advance() }
        expect(session.result?.correct == 9 && player.profile.record(10).bestCorrect == 9, "completed levels preserve the lost point after a correct retry")

        let config = DinoPracticeConfiguration(time: .whole, order: .specific(.dayPart))
        for _ in 1...3 { player.recordPracticeAnswer(configuration: config, question: .dayPart, correct: true) }
        let practice = DinoSession(level: config.level, player: player, practice: config)
        practice.submit(practice.question.responses.first { $0 != practice.question.expectedAnswer }!)
        let savedAfterWrong = player.practiceRecords
        practice.submit(practice.question.expectedAnswer)
        expect(player.practiceRecords == savedAfterWrong && practice.practiceStreak == 3 && practice.practiceQuestionNumber == 4,
               "a correct retry neither restores the saved streak nor changes held HUD counters")
        practice.advance()
        expect(practice.practiceStreak == 0 && practice.practiceQuestionNumber == 5 && practice.practiceCorrect == 0 &&
               player.practiceRecord(time: .whole, question: .dayPart).questionsAnswered == 4,
               "practice counts a retried question once and keeps the streak broken")
        practice.setInputTime(ClockTime(hour: 5, minute: 55)); practice.adjustInputMinutes(by: 5)
        expect(practice.inputTime == ClockTime(hour: 6), "session minute controls advance the hour")
        practice.adjustInputMinutes(by: -5)
        expect(practice.inputTime == ClockTime(hour: 5, minute: 55), "session minute controls reverse the hour")
    }

    static func testTiming() {
        for (elapsed, seconds) in [(0.0, 1), (0.9, 1), (1.1, 2), (59.5, 60), (60, 60), (86_400, 60), (-3_600, 1), (Double.infinity, 60), (Double.nan, 1)] {
            expect(DinoQuestionTiming.scoredSeconds(elapsed) == seconds, "bounded timing including long inactivity and clock anomalies")
        }
        let store = DinoProgressStore(defaults: InMemoryKeyValueStore())
        let player = DinoPlayer(store: store)
        var now = 100.0
        let session = DinoSession(level: DinoLevelCatalog.level(1)!, player: player, now: { now })
        expect(session.demonstration == nil, "fresh session starts without help")
        let durations = [0.0, 2.2, 300.0, 5.0, 10.0]
        for duration in durations {
            now += duration
            session.submit(session.question.target)
            now += 10_000 // Feedback and waiting for Next must not count.
            session.submit(session.question.target)
            session.advance()
            expect(session.demonstration == nil, "new questions never force help")
        }
        expect(session.attempt.questionSeconds == [1, 3, 60, 5, 10], "only unanswered time per question, no double taps or feedback")
        expect(player.profile.timedAttempts?.count == 1 && player.profile.timedAttempts?.first?.seconds == 79, "whole game timing is recorded")
        expect(store.load().record(1).bestTimedResult?.seconds == 79, "timing persists after reload")
        var profile = player.profile
        profile.recordCompletedAttempt(levelID: 1, correct: 4, questionSeconds: [1,1,1,1,1])
        expect(profile.record(1).bestTimedResult?.seconds == 79, "fast worse replay cannot borrow old stars")
        profile.recordCompletedAttempt(levelID: 1, correct: 5, questionSeconds: [2,2,2,2,2])
        expect(profile.record(1).bestTimedResult?.seconds == 10 && profile.timedAttempts?.count == 3, "faster equal-quality result wins, each game retained")
        var cloud = PlayerProfile()
        cloud.mergeCloudProgress(DinoCloudProgress(profile))
        expect(cloud.record(1).bestTimedResult?.seconds == 10 && cloud.timedAttempts == nil, "best timing syncs, local history stays local")
        profile.resetProgress()
        expect(profile.timedAttempts == nil && profile.record(1).bestTimedResult == nil, "reset also clears timing")
    }

    static func testProgress() {
        var p = PlayerProfile()
        expect(p.unlockedLevels == [1,10] && p.dinoLevel == 0, "new player map and direct boss")
        p.recordCompletedAttempt(levelID: 1, correct: 2)
        expect(p.record(1).stars == 0 && !p.isUnlocked(2) && p.dinoLevel == 0, "2/5 stays locked")
        p.recordCompletedAttempt(levelID: 1, correct: 3)
        expect(p.record(1).stars == 1 && p.isUnlocked(2) && p.dinoLevel == 1, "3/5 unlock and dino move")
        p.recordCompletedAttempt(levelID: 1, correct: 4)
        expect(p.record(1).stars == 2, "4/5 two stars")
        p.recordCompletedAttempt(levelID: 1, correct: 5)
        p.recordCompletedAttempt(levelID: 1, correct: 0)
        expect(p.record(1).stars == 3 && p.record(1).bestCorrect == 5, "lower replay preserves best")
        let before = p
        p.recordCompletedAttempt(levelID: 7, correct: 5)
        expect(p == before, "locked levels cannot grant progress")
        for id in 2...9 { p.recordCompletedAttempt(levelID: id, correct: 3) }
        expect(p.normalLevelsComplete && p.dinoLevel == 9, "normal route complete")
        expect(p.recordCompletedAttempt(levelID: 10, correct: 4) == .none && !p.worldOneComplete, "4/10 never wins")
        expect(p.recordCompletedAttempt(levelID: 10, correct: 5) == .normal && p.worldOneComplete, "normal 5/10 victory")
        p.recordCompletedAttempt(levelID: 10, correct: 0)
        expect(p.worldOneComplete && p.dinoLevel == 10 && p.record(10).bestCorrect == 5, "world victory stays saved")
        expect(p.bossResults.count == 3 && p.record(10).attempts == 3, "boss history")
        var direct = PlayerProfile()
        expect(direct.recordCompletedAttempt(levelID: 10, correct: 9) == .none && !direct.worldOneComplete && direct.dinoLevel == 0, "9/10 without normal route fails")
        expect(direct.recordCompletedAttempt(levelID: 10, correct: 10) == .perfect, "direct perfect victory")
        expect(direct.worldOneComplete && direct.perfectBossVictory && direct.dinoLevel == 10 && (1...10).allSatisfy(direct.isUnlocked) && direct.isUnlocked(11), "perfect opens entire world and next world entrance")
        expect(direct.totalStars == 0, "skipping never invents earned stars")
        for completed in [false, true] {
            for score in 0...10 {
                let expected: BossVictory = score == 10 ? .perfect : completed && score >= 5 ? .normal : .none
                expect(BossVictory.evaluate(correct: score, normalLevelsComplete: completed) == expected, "boss boundary matrix")
            }
        }
    }

    static func testStorage() {
        expect(PlayerProfile.sanitizedName(" \u{202E}Dino\u{0000}\n ") == "Dino", "control and format removal")
        expect(PlayerProfile.sanitizedName(String(repeating: "🦖", count: 25)).count == 20, "20 characters including emoji")
        let memory = InMemoryKeyValueStore(["profile.playerName": "Sam", "settings.languageOverride": "nl", "settings.musicEnabled": false])
        let store = DinoProgressStore(defaults: memory)
        var p = store.load()
        expect(p.name == "Sam" && !p.onboardingComplete, "preserve old name, show new onboarding")
        p.onboardingComplete = true
        p.clockTheme.face = .blue; p.clockTheme.hands = .rounded; p.clockTheme.numerals = .digital
        p.clockTheme.hourInk = .purple; p.clockTheme.minuteInk = .red; p.clockTheme.display = .green
        p.recordCompletedAttempt(levelID: 1, correct: 5)
        p.recordCompletedAttempt(levelID: 10, correct: 10)
        p.demonstratedInteractions.insert(.setAnalog)
        store.save(p)
        expect(DinoProgressStore(defaults: memory).load() == p, "all profile fields survive new store")
        expect(memory.string(forKey: "settings.languageOverride") == "nl", "language preference preserved")
        expect(memory.object(forKey: "settings.musicEnabled") as? Bool == false, "existing preferences preserved")
        memory.set(Data("bad JSON".utf8), forKey: DinoProgressStore.profileKey)
        expect(store.load().name == "Sam" && store.load().unlockedLevels == [1,10], "corrupt save recovers safely")
        let suite = "dino.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        DinoProgressStore(defaults: defaults).save(p)
        expect(DinoProgressStore(defaults: UserDefaults(suiteName: suite)!).load() == p, "actual disk-backed UserDefaults restart")
        defaults.removePersistentDomain(forName: suite)
    }
    static func testClockThemes() {
        let romanLabels = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
        for hour in 1...12 {
            expect(AnalogNumerals.normal.label(for: hour) == String(hour), "normal clock numerals preserve the hour")
            expect(AnalogNumerals.roman.label(for: hour) == romanLabels[hour - 1], "Roman clock numerals cover all twelve hours")
        }
        expect(ClockTheme.standard.face == .white && ClockTheme.standard.analogNumerals == .normal,
               "white and normal numerals remain the defaults")
        expect(ClockFace.allCases.first == .black && ClockFace.allCases.count == ClockInk.allCases.count,
               "the black face comes before white and matches the number of hand and rim presets")
        for hex: UInt32 in [0x000000, 0x193B53, 0x303A40, 0x0000FF, 0x6945A0] {
            expect(ClockColorContrast.markingHex(on: hex) == 0xFFFFFF, "dark faces use white markings")
        }
        for hex: UInt32 in [0xFFFFFF, 0xFFF1D6, 0xE2F3FD, 0xE5F6DC, 0xFFFF00, 0x00FF00] {
            expect(ClockColorContrast.markingHex(on: hex) == 0x000000, "light faces use black markings")
        }
        let legacy = Data(#"{"face":"blue","hourInk":"purple","minuteInk":"red","rimInk":"green","hands":"playful","display":"green","numerals":"digital"}"#.utf8)
        let migrated = try! JSONDecoder().decode(ClockTheme.self, from: legacy)
        expect(migrated.face == .blue && migrated.hourInk == .purple && migrated.minuteInk == .red && migrated.rimInk == .green,
               "legacy clock palettes survive migration")
        expect(migrated.hands == .rounded && migrated.numerals == .digital && migrated.analogNumerals == .normal, "retired hands migrate to rounded and keep the numeral style")
        expect(migrated.analogShape == .circle && migrated.digitalShape == .roundedRectangle && migrated.digitalInkHex == 0x193B53,
               "legacy light displays keep dark digits and default shapes")
        let oldShape = try! JSONDecoder().decode(ClockTheme.self, from: Data(#"{"analogShape":"pentagon","customFaceHex":526612}"#.utf8))
        expect(oldShape.analogShape == .octagon && oldShape.customFaceHex == 526612, "saved pentagons migrate to octagons and retain custom colors")
        let oldDark = try! JSONDecoder().decode(ClockTheme.self, from: Data(#"{"display":"charcoal"}"#.utf8))
        expect(oldDark.digitalInkHex == 0xFFFFFF, "legacy dark displays keep white digits")
        var theme = ClockTheme.standard
        theme.analogShape = .octagon; theme.digitalShape = .oval; theme.numerals = .classic; theme.analogNumerals = .roman
        theme.customFaceHex = 0x080914; theme.customHourHex = 0xFEDD22; theme.customMinuteHex = 0xC6EFDA
        theme.customRimHex = 0xCA71C5; theme.customDisplayHex = 0x280A37; theme.digitalInkHex = 0xF4F188
        let memory = InMemoryKeyValueStore()
        let store = DinoProgressStore(defaults: memory)
        var profile = PlayerProfile(); profile.clockTheme = theme
        profile.recordCompletedAttempt(levelID: 1, correct: 5)
        store.save(profile)
        expect(DinoProgressStore(defaults: memory).load() == profile, "all custom colors, shapes, fonts and progress survive restart")
        expect(theme.faceHex == 0x080914 && theme.markingHex == 0xFFFFFF && theme.hourHex == 0xFEDD22 && theme.minuteHex == 0xC6EFDA && theme.rimHex == 0xCA71C5,
               "analog custom colors override presets")
        let digitalInk = theme.digitalInkHex
        theme.customDisplayHex = digitalInk
        expect(theme.digitalColorsMatch, "identical custom digital colors need a default clock on completion")
        theme.customDisplayHex = digitalInk - 1
        expect(!theme.digitalColorsMatch && theme.digitalInkHex == digitalInk, "different digital colors are allowed without changing digit ink")
        theme.customDisplayHex = nil; theme.display = .white; theme.digitalInkHex = 0xFFFFFF
        expect(theme.digitalColorsMatch, "matching preset digital colors also need a default clock")
        theme.resetDigital()
        expect(!theme.digitalColorsMatch && theme.customFaceHex == 0x080914 && theme.analogShape == .octagon && theme.analogNumerals == .roman,
               "using the standard digital clock preserves analog choices")
        theme.digitalInkHex = 0xF4F188; theme.digitalShape = .rectangle
        theme.resetAnalog()
        expect(theme.faceHex == 0xFFFFFF && theme.analogShape == .circle && theme.customHourHex == nil && theme.customMinuteHex == nil && theme.customRimHex == nil && theme.hands == .rounded && theme.analogNumerals == .normal,
               "using the standard analog clock resets its custom colors and shape")
        expect(theme.digitalInkHex == 0xF4F188 && theme.digitalShape == .rectangle, "resetting analog preserves digital choices")

        var designed = ClockTheme.standard
        designed.analogShape = .octagon; designed.hands = .straight; designed.analogNumerals = .roman
        designed.digitalShape = .oval; designed.numerals = .classic
        designed.customFaceHex = 0x090B11; designed.customHourHex = 0xFFEEDD
        designed.customMinuteHex = 0xA1EEE9; designed.customRimHex = 0x148B83
        designed.customDisplayHex = 0x112233; designed.digitalInkHex = 0xFFD166
        var restored = designed
        restored.restoreAnalogColors(); restored.restoreDigitalColors()
        expect(restored.faceHex == ClockTheme.standard.faceHex && restored.hourHex == ClockTheme.standard.hourHex &&
               restored.minuteHex == ClockTheme.standard.minuteHex && restored.rimHex == ClockTheme.standard.rimHex &&
               restored.displayHex == ClockTheme.standard.displayHex && restored.digitalInkHex == ClockTheme.standard.digitalInkHex,
               "color helpers recover every original color")
        expect(restored.analogShape == .octagon && restored.hands == .straight && restored.analogNumerals == .roman &&
               restored.digitalShape == .oval && restored.numerals == .classic,
               "restoring colors preserves shapes, hands and numeral styles")
        expect(designed.replacingUnreadableClocks() == designed, "readable clocks retain every customization on completion")
        for hand in [\ClockTheme.customHourHex, \ClockTheme.customMinuteHex] {
            var unreadable = designed
            unreadable[keyPath: hand] = unreadable.faceHex
            expect(unreadable.analogColorsMatch, "either matching hand makes the analog clock unreadable")
            var expected = designed; expected.resetAnalog()
            expect(unreadable.replacingUnreadableClocks() == expected,
                   "an unreadable analog clock becomes standard while the digital clock is preserved")
        }
        var unreadable = designed
        unreadable.digitalInkHex = unreadable.displayHex
        var expected = designed; expected.resetDigital()
        expect(unreadable.replacingUnreadableClocks() == expected,
               "an unreadable digital clock becomes standard while the analog clock is preserved")
        unreadable.customFaceHex = unreadable.hourHex
        expect(unreadable.replacingUnreadableClocks() == .standard, "both unreadable clocks resolve independently")
        let player = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
        player.completeOnboarding(theme: unreadable)
        expect(player.profile.onboardingComplete && player.profile.clockTheme == .standard,
               "matching colors still allow onboarding to complete with default clocks")
    }

    static func testFixedClockStyles() {
        let oldDisplays: [(String, UInt32)] = [("charcoal", 0x303A40), ("green", 0xE5F6DC)]
        for (name, hex) in oldDisplays {
            let legacy = try! JSONDecoder().decode(ClockTheme.self, from: Data("{\"display\":\"\(name)\"}".utf8))
            expect(legacy.displayHex == hex, "retired digital presets keep their saved background colors")
        }
        let black = try! JSONDecoder().decode(ClockTheme.self, from: Data(#"{"display":"black"}"#.utf8))
        expect(black.digitalInkHex == 0xFFFFFF && !black.digitalColorsMatch,
               "a black digital background gets visible white digits when no ink was saved")
        let store = DinoProgressStore(defaults: InMemoryKeyValueStore())
        var old = PlayerProfile()
        old.clockTheme.hands = .straight; old.clockTheme.digitalShape = .oval
        old.clockTheme.analogShape = .octagon; old.clockTheme.analogNumerals = .roman
        old.clockTheme.numerals = .classic; old.clockTheme.customFaceHex = 0x080914
        old.clockTheme.customDisplayHex = 0x234567; old.clockTheme.digitalInkHex = 0xF4F188
        store.save(old)
        let player = DinoPlayer(store: store)
        let expected = old.clockTheme.applyingFixedStyles()
        expect(player.profile.clockTheme == expected && store.load().clockTheme == expected,
               "old hand styles and digital shapes migrate and persist without losing other design choices")
        player.setTheme(old.clockTheme)
        expect(player.profile.clockTheme == expected, "live edits keep rounded hands and the fixed digital shape")
        player.completeOnboarding(theme: old.clockTheme)
        expect(player.profile.clockTheme == expected && player.profile.onboardingComplete,
               "onboarding uses the same fixed styles")
        var reset = expected
        reset.resetAnalog()
        var preserved = ClockTheme.standard
        preserved.customDisplayHex = expected.customDisplayHex; preserved.digitalInkHex = expected.digitalInkHex
        preserved.numerals = .classic
        expect(reset == preserved, "restoring analog style resets shape, numbers and all colors while preserving digital style")
        reset = expected; reset.resetDigital()
        preserved = expected; preserved.display = .navy; preserved.customDisplayHex = nil
        preserved.digitalInkHex = 0xFFFFFF; preserved.numerals = .rounded
        expect(reset == preserved, "restoring digital style resets font and both colors while preserving analog style")
    }

    static func testMapLevelGuidance() {
        let memory = InMemoryKeyValueStore()
        let store = DinoProgressStore(defaults: memory)
        let player = DinoPlayer(store: store)
        expect(player.needsFirstLevelHint && player.profile.nextAdventureLevel == 1, "a fresh installation guides level one")
        player.completeOnboarding(theme: .standard)
        expect(player.needsFirstLevelHint, "finishing onboarding keeps the first-level pointer")
        expect(DinoPlayer(store: store).needsFirstLevelHint, "relaunch before selecting a level preserves the pointer")
        player.markLevelSelected()
        expect(!player.needsFirstLevelHint && player.profile.levels.isEmpty, "opening a level dismisses onboarding without requiring an attempt")
        expect(!DinoPlayer(store: store).needsFirstLevelHint, "an opened then closed level stays acknowledged after relaunch")
        player.resetProgress()
        expect(!player.needsFirstLevelHint, "resetting scores does not replay the installation hint")
        player.resetAllData()
        expect(player.needsFirstLevelHint && DinoPlayer(store: store).needsFirstLevelHint, "erasing all data restores first-install guidance")

        var legacy = PlayerProfile()
        legacy.recordCompletedAttempt(levelID: 1, correct: 0)
        store.save(legacy)
        let migrated = DinoPlayer(store: store)
        expect(!migrated.needsFirstLevelHint, "an existing failed attempt also counts as a previously selected level")
        migrated.resetProgress()
        expect(!DinoPlayer(store: store).needsFirstLevelHint, "migration remembers existing players through a later reset")

        var route = PlayerProfile()
        route.recordCompletedAttempt(levelID: 1, correct: 2)
        expect(route.nextAdventureLevel == 1, "a failed level remains the next playable step")
        for level in DinoLevelCatalog.levels {
            expect(route.nextAdventureLevel == level.id, "guidance targets each of the hundred playable levels")
            route.recordCompletedAttempt(levelID: level.id, correct: level.questionCount)
        }
        expect(route.adventureComplete && route.nextAdventureLevel == nil, "finishing the adventure never points to level 101")
        var shortcut = PlayerProfile()
        for world in DinoWorldCatalog.worlds {
            shortcut.recordCompletedAttempt(levelID: world.bossLevel, correct: 10)
            expect(shortcut.nextAdventureLevel == (world.id == 10 ? nil : world.bossLevel + 1), "boss shortcuts guide the next world's entrance")
        }
        expect(shortcut.adventureComplete, "all perfect boss shortcuts celebrate adventure completion")
    }

    static func testPlayerModel() {
        let memory = InMemoryKeyValueStore()
        let player = DinoPlayer(store: DinoProgressStore(defaults: memory))
        var theme = ClockTheme.standard
        theme.face = .green; theme.display = .charcoal; theme.hands = .rounded
        player.completeOnboarding(theme: theme)
        expect(player.profile.name.isEmpty && player.profile.onboardingComplete, "onboarding completes without entering a local name")
        expect(player.profile.clockTheme == theme, "model chosen clocks")
        expect(DinoPlayer(store: DinoProgressStore(defaults: memory)).profile.onboardingComplete,
               "nameless onboarding stays complete after restarting")
        let level = DinoLevelCatalog.level(1)!
        let session = DinoSession(level: level, player: player)
        expect(session.demonstration == nil, "examples never open automatically")
        session.demonstration = session.question.kind
        session.submit(session.question.target)
        expect(session.attempt.answers.isEmpty, "demonstration cannot score active question")
        session.dismissDemonstration()
        for i in 0..<5 {
            session.submit(session.question.target)
            session.submit(session.question.target)
            if i < 4 { expect(player.profile.record(1).attempts == 0, "no partial save") }
            session.advance()
        }
        expect(session.result?.stars == 3 && player.profile.record(1).attempts == 1, "final model result saved once")
        session.advance()
        expect(player.profile.record(1).attempts == 1, "duplicate finish blocked")
        player.markDemonstrated(.setDigital)
        player.setTheme(.standard)
        expect(DinoProgressStore(defaults: memory).load().clockTheme == .standard, "live theme saved")
        player.resetProgress()
        let restored = DinoProgressStore(defaults: memory).load()
        expect(restored.levels.isEmpty && restored.bossResults.isEmpty && !restored.worldOneComplete, "reset clears only progress")
        expect(restored.name.isEmpty && restored.onboardingComplete && restored.clockTheme == .standard, "reset preserves nameless onboarding and clocks")
    }

    static func testUnchangedInputsDoNotPublish() {
        let player = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
        let session = DinoSession(level: DinoLevelCatalog.level(1)!, player: player)
        var inputUpdates = 0
        let inputSubscription = session.objectWillChange.sink { inputUpdates += 1 }
        session.setInputTime(session.inputTime)
        expect(inputUpdates == 0, "stationary clock drags do not invalidate the game view")
        let next = session.inputTime.shiftingMinutes(by: 5)
        session.setInputTime(next)
        expect(inputUpdates == 1 && session.inputTime == next, "minute changes publish only the changed field")
        session.setInputTime(next)
        expect(inputUpdates == 1, "repeated snapped minute values do not publish again")
        inputSubscription.cancel()

        var profileUpdates = 0
        let profileSubscription = player.profileChanges.sink { _ in profileUpdates += 1 }
        player.markDemonstrated(.setAnalog)
        player.markDemonstrated(.setAnalog)
        expect(profileUpdates == 1, "reopening a known example does not save and publish an unchanged profile")
        profileSubscription.cancel()
    }

    static func testLiveClockChanges() {
        let store = DinoProgressStore(defaults: InMemoryKeyValueStore())
        let player = DinoPlayer(store: store)
        player.completeOnboarding(theme: .standard)
        let session = DinoSession(level: DinoLevelCatalog.level(1)!, player: player)
        session.inputHour = 9
        let questionID = session.question.id
        let input = session.inputTime
        var latest: PlayerProfile?
        let subscription = player.profileChanges.sink { latest = $0 }
        var theme = player.profile.clockTheme
        theme.face = .black; theme.analogShape = .octagon; theme.analogNumerals = .roman
        player.setTheme(theme)
        expect(player.profile.clockTheme == theme && store.load().clockTheme == theme && latest?.clockTheme == theme,
               "clock edits publish and persist immediately")
        expect(session.question.id == questionID && session.inputTime == input && session.attempt.index == 0,
               "live personalization preserves the current question and answer")
        var draft = theme
        draft.digitalInkHex = draft.displayHex
        draft.numerals = .digital; draft.digitalShape = .roundedRectangle; draft.hourInk = .purple
        player.setTheme(draft)
        expect(!player.profile.clockTheme.digitalColorsMatch && player.profile.clockTheme.digitalInkHex == theme.digitalInkHex,
               "matching draft colors cannot make the game clock disappear")
        expect(player.profile.clockTheme.numerals == .digital && player.profile.clockTheme.digitalShape == .roundedRectangle && player.profile.clockTheme.hourInk == .purple,
               "other style edits still apply while duplicate digital colors are being corrected")
        draft.display = .charcoal
        player.setTheme(draft)
        expect(player.profile.clockTheme == draft && store.load().clockTheme == draft,
               "corrected digital colors are applied immediately")
        expect(session.question.id == questionID && session.inputTime == input,
               "digital edits also preserve the running question and input")
        draft.customFaceHex = draft.hourHex
        draft.analogShape = .square; draft.analogNumerals = .normal
        player.setTheme(draft)
        expect(!player.profile.clockTheme.analogColorsMatch && player.profile.clockTheme.face == .black &&
               player.profile.clockTheme.analogShape == .square && player.profile.clockTheme.analogNumerals == .normal,
               "matching analog draft colors keep visible hands while other changes apply live")
        var completed = draft; completed.resetAnalog()
        player.completeClockCustomization(theme: draft)
        expect(player.profile.clockTheme == completed && store.load().clockTheme == completed && latest?.clockTheme == completed,
               "finishing an unreadable analog draft publishes and persists the default analog clock")
        draft = completed
        draft.digitalInkHex = draft.displayHex
        player.completeClockCustomization(theme: draft)
        completed.resetDigital()
        expect(player.profile.clockTheme == completed && store.load().clockTheme == completed,
               "finishing an unreadable digital draft saves the default digital clock")
        expect(session.question.id == questionID && session.inputTime == input && session.attempt.index == 0,
               "default clock fallback preserves the running question, answer and progress")
        subscription.cancel()
    }

    static func testDinoAppearance() {
        let memory = InMemoryKeyValueStore()
        let store = DinoProgressStore(defaults: memory)
        var legacy = PlayerProfile()
        legacy.name = "Sam"; legacy.onboardingComplete = true
        legacy.clockTheme.face = .blue
        legacy.recordCompletedAttempt(levelID: 1, correct: 5)
        var json = try! JSONSerialization.jsonObject(with: JSONEncoder().encode(legacy)) as! [String: Any]
        json.removeValue(forKey: "dinoAppearance")
        memory.set(try! JSONSerialization.data(withJSONObject: json), forKey: DinoProgressStore.profileKey)
        let player = DinoPlayer(store: store)
        expect(player.profile == legacy, "old saves retain name, clocks and progress without avatar colors")
        expect((player.profile.dinoAppearance ?? .standard) == .standard, "old saves use the original dinosaur colors")
        var appearance = DinoAppearance.standard
        appearance.bandana = 0x459CDF; appearance.spikes = 0xA77BE0
        appearance.body = 0xF48EB6; appearance.belly = 0xF59A32
        player.setDinoAppearance(appearance)
        let restarted = DinoPlayer(store: store)
        expect(restarted.profile.dinoAppearance == appearance, "all four custom colors survive restart")
        expect(restarted.profile.name == "Sam" && restarted.profile.clockTheme.face == .blue && restarted.profile.totalStars == 3, "personalization preserves the existing player")
        restarted.resetProgress()
        expect(restarted.profile.dinoAppearance == appearance && restarted.profile.name == "Sam", "progress reset preserves appearance and legacy save fields")
        var cloud = PlayerProfile(); cloud.recordCompletedAttempt(levelID: 1, correct: 5)
        restarted.mergeCloudProgress(DinoCloudProgress(cloud))
        expect(restarted.profile.dinoAppearance == appearance, "cloud merge preserves local avatar colors")
        let cloudJSON = String(data: try! JSONEncoder().encode(DinoCloudProgress(restarted.profile)), encoding: .utf8)!
        expect(!cloudJSON.contains("dinoAppearance") && !cloudJSON.contains("bandana"), "avatar colors remain device-local")
        restarted.setDinoAppearance(.standard)
        expect(DinoPlayer(store: store).profile.dinoAppearance == .standard, "restore original colors persists")
    }

    static func testDinoAvatarMask() {
        // Coordinates and colors come from the original illustration's problem areas.
        for (x, y) in [(595.0, 48.0), (615.0, 61.0)] {
            expect(DinoAvatarMask.part(hue: 0.29, saturation: 0.43, lightness: 0.57,
                                      x: x / 1254, y: y / 1254) == .spikes,
                   "bright front of upper spike uses spike color, not body color")
        }
        expect(DinoAvatarMask.part(hue: 0.22, saturation: 0.66, lightness: 0.64,
                                  x: 646.0 / 1254, y: 83.0 / 1254) == .body,
               "forehead strip beside the spike keeps the body color")
        for (x, y) in [(590.0, 453.0), (616.0, 480.0), (622.0, 488.0), (665.0, 540.0)] {
            expect(DinoAvatarMask.part(hue: 0.11, saturation: 0.60, lightness: 0.75,
                                      x: x / 1254, y: y / 1254) == .belly,
                   "cheek and jaw stay colored without rectangular mouth cutouts")
        }
        expect(DinoAvatarMask.part(hue: 0.09, saturation: 0.80, lightness: 0.25,
                                  x: 608.0 / 1254, y: 350.0 / 1254) == nil,
               "iris retains its original brown color")
        expect(DinoAvatarMask.part(hue: 0.13, saturation: 0.10, lightness: 0.92,
                                  x: 560.0 / 1254, y: 330.0 / 1254) == nil,
               "warm eye reflections remain white without colored speckles")
        expect(DinoAvatarMask.part(hue: 0.09, saturation: 0.82, lightness: 0.08,
                                  x: 800.0 / 1254, y: 505.0 / 1254) == nil,
               "dark mouth interior remains unchanged")
        expect(DinoAvatarMask.part(hue: 0.01, saturation: 0.80, lightness: 0.45,
                                  x: 710.0 / 1254, y: 529.0 / 1254) == nil,
               "tongue is independent of bandana color")
    }

    static func testDinoSpriteColors() {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        let size = 384
        func pixels(_ image: CGImage) -> [UInt8] {
            var bytes = [UInt8](repeating: 0, count: size * size * 4)
            bytes.withUnsafeMutableBytes { buffer in
                let context = CGContext(data: buffer.baseAddress, width: size, height: size, bitsPerComponent: 8,
                                        bytesPerRow: size * 4, space: colorSpace, bitmapInfo: bitmapInfo)!
                context.interpolationQuality = .high
                context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
            }
            return bytes
        }
        func hsl(_ bytes: [UInt8], _ index: Int) -> (h: Double, s: Double, l: Double) {
            let alpha = Double(bytes[index + 3]) / 255
            let r = min(1, Double(bytes[index]) / 255 / alpha)
            let g = min(1, Double(bytes[index + 1]) / 255 / alpha)
            let b = min(1, Double(bytes[index + 2]) / 255 / alpha)
            let high = max(r, g, b), low = min(r, g, b), delta = high - low
            let l = (high + low) / 2
            guard delta > 0.00001 else { return (0, 0, l) }
            let hue = high == r ? (g - b) / delta : high == g ? (b - r) / delta + 2 : (r - g) / delta + 4
            return (((hue / 6 + 1).truncatingRemainder(dividingBy: 1)), delta / (1 - abs(2 * l - 1)), l)
        }
        let appearances = [DinoAppearance.standard,
                           DinoAppearance(bandana: 0xA77BE0, spikes: 0xA77BE0, body: 0xF48EB6),
                           DinoAppearance(bandana: 0x459CDF, spikes: 0xF59A32, body: 0xFF1493, belly: 0x459CDF)]
        for appearance in appearances {
            var idleLightness = [DinoAppearance.Part: [Double]]()
            var idleSaturation = [DinoAppearance.Part: Double]()
            for asset in DinoAnimation.spriteAssets {
                let url = URL(fileURLWithPath: "Assets.xcassets/\(asset).imageset/\(asset).png")
                let source = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
                let original = pixels(source)
                let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                                        bytesPerRow: size * 4, space: colorSpace, bitmapInfo: bitmapInfo)!
                context.interpolationQuality = .high
                context.draw(source, in: CGRect(x: 0, y: 0, width: size, height: size))
                let output = pixels(DinoSpriteColorRenderer.recolored(context.makeImage()!, appearance: appearance, asset: asset)!)
                var lightness = [DinoAppearance.Part: [Double]](), saturation = [DinoAppearance.Part: [Double]]()
                var alphaPreserved = true, facePreserved = true
                let regions = DinoAvatarMask.spriteRegions(for: asset)
                for y in 0..<size {
                    for x in 0..<size {
                        let index = (y * size + x) * 4
                        alphaPreserved = alphaPreserved && original[index + 3] == output[index + 3]
                        guard original[index + 3] > 250 else { continue }
                        let before = hsl(original, index), after = hsl(output, index)
                        if let part = DinoAvatarMask.part(hue: before.h, saturation: before.s, lightness: before.l,
                                                         x: Double(x) / Double(size), y: Double(y) / Double(size), regions: regions) {
                            lightness[part, default: []].append(after.l)
                            saturation[part, default: []].append(after.s)
                        } else {
                            facePreserved = facePreserved && (0..<3).allSatisfy { abs(Int(original[index + $0]) - Int(output[index + $0])) <= 1 }
                        }
                    }
                }
                expect(alphaPreserved, "\(asset) keeps its original transparency")
                expect(facePreserved, "\(asset) preserves eyes, lettering and mouth")
                for part in DinoAppearance.Part.allCases {
                    let l = lightness[part]!.sorted(), s = saturation[part]!.sorted()
                    let quantiles = [0.1, 0.5, 0.9].map { l[Int(Double(l.count - 1) * $0)] }
                    if asset == "dino-idle" {
                        idleLightness[part] = quantiles; idleSaturation[part] = s[s.count / 2]
                    } else {
                        expect(zip(quantiles, idleLightness[part]!).allSatisfy { abs($0 - $1) < 0.015 },
                               "\(asset) matches idle \(part) shadows, base color and highlights: \(quantiles) vs \(idleLightness[part]!)")
                        expect(abs(s[s.count / 2] - idleSaturation[part]!) < 0.025,
                               "\(asset) keeps idle \(part) saturation instead of becoming pastel: \(s[s.count / 2]) vs \(idleSaturation[part]!)")
                    }
                }
            }
        }
    }

    static func testPaleBandanaLettering() {
        // Pose-specific print regions also keep the eye and mouth out of this check.
        let regions: [(String, CGRect)] = [
            ("dino-idle", CGRect(x: 550, y: 90, width: 238, height: 106)),
            ("dino-thumbs-up-08", CGRect(x: 525, y: 85, width: 250, height: 117)),
            ("dino-wrong-answer-04", CGRect(x: 526, y: 89, width: 252, height: 137)),
            ("dino-backflip-01", CGRect(x: 702, y: 205, width: 258, height: 98)),
            ("dino-backflip-03", CGRect(x: 326, y: 131, width: 210, height: 160)),
            ("dino-backflip-07", CGRect(x: 638, y: 233, width: 256, height: 106)),
            ("dino-backflip-08", CGRect(x: 520, y: 102, width: 237, height: 109))
        ]
        expect(DinoAppearance.standard.bandanaLetteringHex == 0xFFFFFF,
               "the original red bandana retains white lettering")
        for color: UInt32 in [0xFFFFFF, 0xFFF4CE] {
            let appearance = DinoAppearance(bandana: color)
            for (asset, region) in regions {
                let url = URL(fileURLWithPath: "Assets.xcassets/\(asset).imageset/\(asset).png")
                let source = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
                let output = DinoSpriteColorRenderer.recolored(source, appearance: appearance, asset: asset)!
                let bytes = [UInt8](output.dataProvider!.data! as Data)
                let scale = CGFloat(output.width) / 1254
                let bounds = region.applying(CGAffineTransform(scaleX: scale, y: scale))
                var softInk = 0
                for y in Int(bounds.minY)...Int(bounds.maxY) {
                    for x in Int(bounds.minX)...Int(bounds.maxX) {
                        let i = y * output.bytesPerRow + x * 4
                        if bytes[i + 3] > 250 && (0..<3).allSatisfy({ (58...65).contains(Int(bytes[i + $0])) }) {
                            softInk += 1
                        }
                    }
                }
                expect(softInk > 50, "\(asset) renders charcoal print instead of hard black on pale cloth")
            }
        }
    }

    static func testSettingsAndFeedback() {
        let memory = InMemoryKeyValueStore()
        let settings = DinoSettings(defaults: memory)
        expect(settings.soundEffectsEnabled && settings.hapticsEnabled, "answer feedback enabled by default")
        expect(!settings.highContrastEnabled && !settings.icloudSyncEnabled, "contrast and cloud opt-in defaults")
        settings.soundEffectsEnabled = false; settings.hapticsEnabled = false
        settings.highContrastEnabled = true; settings.icloudSyncEnabled = true
        let restarted = DinoSettings(defaults: memory)
        expect(!restarted.soundEffectsEnabled && !restarted.hapticsEnabled && restarted.highContrastEnabled && restarted.icloudSyncEnabled, "all four settings survive restart, including false values")
        let player = DinoPlayer(store: DinoProgressStore(defaults: memory))
        var feedback: [Bool] = []
        let session = DinoSession(level: DinoLevelCatalog.level(1)!, player: player, answerFeedback: { feedback.append($0) })
        expect(session.canExitWithoutConfirmation, "first question exits without a confirmation")
        session.demonstration = session.question.kind
        session.submit(session.question.target)
        expect(feedback.isEmpty, "demonstration never emits answer feedback")
        session.dismissDemonstration()
        session.submit(session.question.target); session.submit(session.question.target)
        expect(feedback == [true], "one success feedback despite repeated taps")
        expect(session.canExitWithoutConfirmation, "first question also exits directly while answer feedback is showing")
        session.advance()
        expect(!session.canExitWithoutConfirmation, "later questions keep the exit confirmation")
        session.submit(ClockTime(hour: ClockTime.shiftedHour(session.question.target.hour, by: 1)))
        expect(feedback == [true, false], "wrong answer emits distinct feedback")
        player.resetProgress()
        expect(DinoSettings(defaults: memory).highContrastEnabled, "progress reset preserves preferences")
    }

    static func testFullReset() {
        let memory = InMemoryKeyValueStore(["future.preference": "old", "dino.social.sharing.v1.test": 1,
                                           "settings.languageOverride": "en"])
        let store = DinoProgressStore(defaults: memory)
        var original = PlayerProfile()
        original.name = "Legacy Sam"; original.onboardingComplete = true
        original.clockTheme.face = .blue
        original.dinoAppearance = DinoAppearance(bandana: 0x459CDF, spikes: 0xA77BE0, body: 0xF48EB6, belly: 0xF59A32)
        original.recordCompletedAttempt(levelID: 1, correct: 5, questionSeconds: [4,4,4,4,4])
        original.demonstratedInteractions.insert(.setAnalog)
        store.save(original)
        let player = DinoPlayer(store: store)
        let settings = DinoSettings(defaults: memory)
        settings.soundEffectsEnabled = false; settings.hapticsEnabled = false
        settings.highContrastEnabled = true; settings.icloudSyncEnabled = true
        let previousDevice = settings.cloudDeviceID
        let oldData = try! JSONEncoder().encode(DinoCloudProgress(original))
        let cloud = TestCloudStore()
        cloud.values = [DinoCloudSync.progressKey + ".old-device": oldData, "other.feature": Data([1])]
        let sync = DinoCloudSync(store: cloud); sync.connect(player: player, settings: settings)
        cloud.succeeds = false
        let resetAt = Date(timeIntervalSince1970: 1_800_000_000)
        let generation = player.resetGeneration
        sync.removeAllData(at: resetAt)
        player.resetAllData(at: resetAt)
        settings.resetPreferences()
        expect(player.resetGeneration != generation, "full reset recreates the root and dismisses all previous screens")
        var expected = PlayerProfile(); expected.progressResetAt = resetAt
        expect(player.profile == expected, "full reset clears onboarding, colors, clocks, names, history, timing and demonstration state")
        expect(DinoPlayer(store: store).profile == expected, "cold launch starts with a fresh welcome profile")
        for key in [DinoProgressStore.profileKey, DinoProgressStore.legacyNameKey, "future.preference",
                    "dino.social.sharing.v1.test", "settings.languageOverride"] {
            expect(memory.object(forKey: key) == nil, "all old local app data is erased, including unrecognized preference keys")
        }
        let restarted = DinoSettings(defaults: memory)
        expect(restarted.soundEffectsEnabled && restarted.hapticsEnabled && !restarted.highContrastEnabled && !restarted.icloudSyncEnabled,
               "settings return to fresh-install defaults")
        expect(restarted.cloudDeviceID != previousDevice, "reset generates a new cloud installation identity")
        expect(Set(cloud.values.keys) == [DinoCloudSync.progressKey, "other.feature"], "reset removes all app progress snapshots and leaves unrelated keys alone")
        let marker = try! JSONDecoder().decode(DinoCloudProgress.self, from: cloud.values[DinoCloudSync.progressKey]!)
        expect(marker.resetAt == resetAt && marker.levels.isEmpty && marker.demonstratedInteractions.isEmpty,
               "an offline reset queues only an empty deletion marker")
        cloud.succeeds = true
        cloud.values[DinoCloudSync.progressKey + ".stale-device"] = oldData
        settings.icloudSyncEnabled = true
        expect(player.profile == expected, "a delayed old cloud snapshot cannot restore erased progress or bypass welcome")
        expect(cloud.values[DinoCloudSync.progressKey + "." + settings.cloudDeviceID] != nil,
               "re-enabling sync uses the new installation identity")
    }

    static func testCloudSync() {
        let cloud = TestCloudStore()
        let firstMemory = InMemoryKeyValueStore()
        var original = PlayerProfile(); original.name = "Sam"; original.onboardingComplete = true
        original.recordCompletedAttempt(levelID: 1, correct: 5)
        let firstStore = DinoProgressStore(defaults: firstMemory); firstStore.save(original)
        let first = DinoPlayer(store: firstStore)
        let firstSettings = DinoSettings(defaults: firstMemory)
        let firstSync = DinoCloudSync(store: cloud); firstSync.connect(player: first, settings: firstSettings)
        expect(cloud.reads == 0 && cloud.writes == 0 && cloud.syncs == 0, "cloud off performs no reads, writes or synchronization")
        firstSettings.icloudSyncEnabled = true
        expect(firstSync.status == .active && cloud.writes == 1, "cloud opt-in uploads existing progress")
        let json = String(data: cloud.values.values.first!, encoding: .utf8)!
        expect(!json.contains("Sam") && !json.contains("clockTheme") && !json.contains("soundEffects"), "cloud payload excludes identity, clocks and preferences")

        let firstKey = DinoCloudSync.progressKey + "." + firstSettings.cloudDeviceID
        let firstSnapshot = cloud.values[firstKey]
        let freshSettings = DinoSettings(defaults: InMemoryKeyValueStore())
        freshSettings.icloudSyncEnabled = true
        let fresh = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
        let freshSync = DinoCloudSync(store: cloud)
        cloud.hideSnapshots = true
        freshSync.connect(player: fresh, settings: freshSettings)
        expect(cloud.values[firstKey] == firstSnapshot && cloud.values.count == 2, "new device cannot overwrite an existing save before its initial cloud download")
        cloud.hideSnapshots = false; freshSync.synchronize()
        expect(fresh.profile.totalStars == 3, "delayed initial download restores the existing best progress")
        expect(DinoSettings(defaults: firstMemory).cloudDeviceID == firstSettings.cloudDeviceID, "cloud writer identity survives restart")

        let secondMemory = InMemoryKeyValueStore()
        var local = PlayerProfile(); local.name = "Luna"; local.onboardingComplete = true; local.clockTheme.face = .blue
        let secondStore = DinoProgressStore(defaults: secondMemory); secondStore.save(local)
        let second = DinoPlayer(store: secondStore)
        let secondSettings = DinoSettings(defaults: secondMemory); secondSettings.icloudSyncEnabled = true
        let secondSync = DinoCloudSync(store: cloud); secondSync.connect(player: second, settings: secondSettings)
        expect(second.profile.record(1).stars == 3 && second.profile.name == "Luna" && second.profile.clockTheme.face == .blue, "other device restores progress and retains its identity and clocks")
        let writes = cloud.writes
        secondSync.synchronize()
        expect(cloud.writes == writes, "unchanged sync does not upload again")
        let personalizationReads = cloud.reads, personalizationSyncs = cloud.syncs
        var customTheme = second.profile.clockTheme
        customTheme.analogShape = .octagon
        second.setTheme(customTheme)
        var customDino = DinoAppearance.standard
        customDino.body = 0xF48EB6
        second.setDinoAppearance(customDino)
        expect(cloud.reads == personalizationReads && cloud.syncs == personalizationSyncs && cloud.writes == writes,
               "local clock and Dino color edits do not trigger cloud reads, writes or synchronization")
        let session = DinoSession(level: DinoLevelCatalog.level(2)!, player: second)
        if session.demonstration != nil { session.dismissDemonstration() }
        for _ in 0..<5 { session.submit(session.question.target); session.advance() }
        firstSync.synchronize()
        expect(first.profile.totalStars == 6 && second.profile.totalStars == 6, "new local level survives synchronous cloud callbacks and reaches the other device")
        expect(secondStore.load() == second.profile, "cloud merge is persisted after local completion")
        firstSettings.icloudSyncEnabled = false
        let offReads = cloud.reads, offWrites = cloud.writes, offSyncs = cloud.syncs
        first.markDemonstrated(.setDigital); firstSync.synchronize()
        expect(cloud.reads == offReads && cloud.writes == offWrites && cloud.syncs == offSyncs && firstSync.status == .off, "turning cloud off stops all subsequent cloud access")

        cloud.available = false
        second.resetProgress()
        expect(second.profile.levels.isEmpty && secondSync.status == .unavailable, "offline reset keeps local progress safe")
        let stale = cloud.values
        cloud.available = true; secondSync.synchronize()
        expect(second.profile.levels.isEmpty, "reconnect does not resurrect pre-reset cloud results")
        var remoteResets = 0
        first.progressReset = { remoteResets += 1 }
        firstSettings.icloudSyncEnabled = true
        expect(first.profile.levels.isEmpty && first.profile.name == "Sam" && first.profile.onboardingComplete, "enabled device receives reset without losing onboarding")
        expect(remoteResets == 1, "remote reset also stops optional Game Center sharing")
        cloud.values = stale; firstSync.synchronize()
        expect(first.profile.levels.isEmpty, "late stale update cannot undo a cloud reset")

        let before = first.profile
        cloud.succeeds = false; firstSync.synchronize()
        expect(firstSync.status == .unavailable && first.profile == before, "cloud failure never erases a local save")
        cloud.succeeds = true; cloud.values = [DinoCloudSync.progressKey: Data("broken".utf8)]
        let corruptWrites = cloud.writes
        firstSync.synchronize()
        expect(firstSync.status == .unavailable && first.profile == before && cloud.writes == corruptWrites, "invalid cloud data is preserved without overwriting or corrupting local progress")
        var future = DinoCloudProgress(before); future.version = 2
        cloud.values = [DinoCloudSync.progressKey: try! JSONEncoder().encode(future)]; firstSync.synchronize()
        expect(firstSync.status == .unavailable && cloud.writes == corruptWrites, "newer cloud schema is not overwritten")

        var boss = PlayerProfile(); boss.recordCompletedAttempt(levelID: 10, correct: 10)
        var restored = PlayerProfile(); restored.mergeCloudProgress(DinoCloudProgress(boss))
        expect(restored.perfectBossVictory && restored.worldOneComplete && (1...10).allSatisfy(restored.isUnlocked) && restored.isUnlocked(11), "perfect boss progress restores on a second device")
        var normalBoss = PlayerProfile()
        for id in 1...9 { normalBoss.recordCompletedAttempt(levelID: id, correct: 3) }
        normalBoss.recordCompletedAttempt(levelID: 10, correct: 5)
        var normalRestored = PlayerProfile(); normalRestored.mergeCloudProgress(DinoCloudProgress(normalBoss))
        expect(normalRestored.worldOneComplete && !normalRestored.perfectBossVictory, "normal boss route survives cloud sync")
        var malformed = DinoCloudProgress(PlayerProfile())
        malformed.levels = ["101": LevelRecord(stars: 3, bestCorrect: 5, attempts: 1), "1": LevelRecord(stars: 3, bestCorrect: 0, attempts: 1)]
        var safe = PlayerProfile(); safe.mergeCloudProgress(malformed)
        expect(safe.levels["101"] == nil && safe.totalStars == 0, "cloud cannot invent stars or unknown levels")
    }

}

@MainActor
private final class TestCloudStore: DinoCloudProgressStore {
    var available = true
    var succeeds = true
    var values: [String: Data] = [:]
    var hideSnapshots = false
    var reads = 0, writes = 0, syncs = 0
    var isAvailable: Bool { available }
    func snapshots() -> [String: Data] { reads += 1; return hideSnapshots ? [:] : values }
    func set(_ data: Data, forKey key: String) { writes += 1; values[key] = data }
    func removeObject(forKey key: String) { values.removeValue(forKey: key) }
    func synchronize() -> Bool { syncs += 1; return succeeds }
}
