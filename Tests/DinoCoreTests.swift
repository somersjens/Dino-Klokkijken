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
        if CommandLine.arguments.contains("--time-reading") {
            testTimeReadingClock()
            print("PASS: \(checks) time-reading checks.")
            return
        }
        if CommandLine.arguments.contains("--curriculum") {
            for level in DinoLevelCatalog.levels {
                for (index, recipe) in level.recipes.enumerated() {
                    let count = level.recipeOrder.filter { $0 == index }.count
                    print("\(level.id)\t\(level.worldID)\t\(index + 1)\t\(recipe.kind.rawValue)\t\(level.time(for: recipe).rawValue)\t\(level.plannedDifficulty(for: recipe).rawValue)\t\(count)\t\(level.recipeOrder.map { String($0 + 1) }.joined(separator: ","))")
                }
            }
            return
        }
        if CommandLine.arguments.contains("--curriculum-tests") {
            testLevelCurriculum()
            print("PASS: \(checks) curriculum checks.")
            return
        }
        if CommandLine.arguments.contains("--difficulty") {
            testAdaptiveDifficulty()
            testQuestionVariation()
            print("PASS: \(checks) adaptive difficulty checks.")
            return
        }
        if CommandLine.arguments.contains("--variation") {
            testQuestionVariation()
            print("PASS: \(checks) question variation checks.")
            return
        }
        if CommandLine.arguments.contains("--answer-inputs") {
            testAnswerInputRequirements()
            testRepeatedAnswerControls()
            testPractice()
            print("PASS: \(checks) answer input and practice checks.")
            return
        }
        if CommandLine.arguments.contains("--jungle-scenery") {
            testJungleSceneryClearance()
            print("PASS: \(checks) jungle route and scenery checks.")
            return
        }
        if CommandLine.arguments.contains("--boss-clocks") {
            testBossClockMotion()
            print("PASS: \(checks) boss clock motion checks.")
            return
        }
        testLevelCurriculum()
        testAdaptiveDifficulty()
        testQuestionVariation()
        testClocks()
        testBossClockMotion()
        testHandSelection()
        testHandHintClearance()
        testAssetCatalog()
        testAnimation()
        testCrystalMinerPatrols()
        testQuestions()
        testWorlds()
        testWorldJoinContinuity()
        testLevelQuestionOutline()
        testJungleSceneryClearance()
        testMapAnimationViewport()
        testAttempt()
        testRepeatedAnswerControls()
        testAnswerInputRequirements()
        testAnswerRetries()
        testTiming()
        testPractice()
        testPracticeRecords()
        testExpandedQuestions()
        testTimeReadingClock()
        testPlausibleChoices()
        testSpokenTime()
        testFlightArrivals()
        testMinutesBetweenQuestions()
        testClockArithmetic()
        testDaySchedules()
        testCapitalTimeZones()
        testUnambiguousQuestionTimes()
        testDayPartSchedule()
        testDayPartRejudge()
        testDemonstrationExamples()
        testAnalogSettingExamples()
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
        testQuestionSpeechVoices()
        testQuestionPrompts()
        testCloudSync()
        testFullReset()
        let socialChecks = await DinoSocialTests.run()
        print("PASS: \(checks + socialChecks) checks — gameplay, persistence, social progress, privacy guards, offline sync and international names.")
    }

    static func testLevelCurriculum() {
        let levels = DinoLevelCatalog.levels
        expect(levels.count == 100, "the route retains all one hundred level IDs")
        var introduced = Set<DinoQuestionSkill>()
        var taughtBeforeBoss = Set<DinoQuestionSkill>()
        var tiers = [DinoQuestionSkill: Set<DinoQuestionDifficulty>]()
        for level in levels {
            let skills = level.recipes.map { level.skill(for: $0) }
            expect(Set(skills).count == skills.count, "a listed combination is unique by question type and time family")
            if level.id == 1 { expect(skills.count == 1, "only level one teaches a single combination") }
            else if level.isBoss {
                expect(skills.count == 10 && level.questionCount == 10, "each boss asks ten distinct combinations")
                expect(skills.allSatisfy { taughtBeforeBoss.contains($0) }, "bosses assess combinations introduced in ordinary lessons")
            } else { expect((2...3).contains(skills.count), "every other normal level has two or three combinations") }
            expect(level.recipeOrder.count == level.questionCount, "every question has an authored recipe")
            expect(Set(level.recipeOrder) == Set(level.recipes.indices), "all listed combinations are actually asked")
            if level.isBoss { expect(Set(level.recipeOrder).count == 10, "no boss recipe repeats") }
            else if level.recipes.count > 1 {
                let counts = level.recipes.indices.map { index in level.recipeOrder.filter { $0 == index }.count }
                expect(counts.max()! - counts.min()! <= 1, "five questions are balanced over the selected combinations")
            }
            for recipe in level.recipes {
                let skill = level.skill(for: recipe), difficulty = level.plannedDifficulty(for: recipe)
                expect(recipe.time != nil && recipe.difficulty != nil, "each curriculum recipe explicitly authors both time and difficulty")
                expect(DinoPracticeQuestion(rawValue: recipe.kind.rawValue) != nil, "the route uses the twenty current exercise types")
                if !introduced.contains(skill) { expect(difficulty == .introduction, "a new combination always starts on introduction") }
                if difficulty == .challenge {
                    expect(tiers[skill]?.contains(.familiar) == true, "challenge follows a planned familiar lesson of the same combination")
                }
                let dependencies: [ClockQuestionKind]
                switch recipe.kind {
                case .sortTimes: dependencies = [.match]
                case .advanceAnalog: dependencies = [.setAnalog]
                case .addTime: dependencies = [.advanceAnalog]
                case .subtractTime, .timeSequence: dependencies = [.addTime]
                case .minutesBetween, .daySchedule: dependencies = [.addTime, .subtractTime]
                case .timeZone: dependencies = [.read24Hour]
                case .flightArrival: dependencies = [.addTime, .timeZone]
                default: dependencies = []
                }
                expect(dependencies.allSatisfy { introduced.contains(.init(kind: $0, time: skill.time)) },
                       "arithmetic and time zones follow their prerequisite skills in the same time family")
                introduced.insert(skill)
                tiers[skill, default: []].insert(difficulty)
            }
            if !level.isBoss { taughtBeforeBoss.formUnion(skills) }
            if level.id >= 91 {
                expect(level.recipes.allSatisfy { $0.time == .minutes && $0.difficulty == .challenge },
                       "all last-world questions are authored on exact minutes at maximum difficulty")
            }
        }
        expect(introduced.count == 120, "all twenty types are taught in all six time families")
        expect(Set(levels.suffix(10).flatMap { $0.recipes.map(\.kind) }).count == 20, "the last world assesses every exercise type")

        let memory = InMemoryKeyValueStore(), store = DinoProgressStore(defaults: InMemoryKeyValueStore())
        let player = DinoPlayer(store: store)
        var finalBossTiers: [DinoQuestionDifficulty] = []
        var actualSkills = Set<DinoQuestionSkill>()
        for level in levels {
            let run = DinoSession(level: level, player: player)
            for index in 0..<level.questionCount {
                let recipe = level.recipe(at: index), q = run.question
                expect(q.id == index && q.kind == recipe.kind && q.timeFamily == level.time(for: recipe), "live sessions follow the complete authored sequence")
                expect(q.difficulty == level.plannedDifficulty(for: recipe), "a successful full playthrough reaches each planned difficulty")
                expect(run.minuteStep == q.timeFamily.minuteStep, "answer controls follow the current question, including mixed-time levels")
                actualSkills.insert(.init(kind: q.kind, time: q.timeFamily))
                if level.id == 100 { finalBossTiers.append(q.difficulty) }
                run.submit(q.expectedAnswer); run.advance()
            }
            expect(run.result?.correct == level.questionCount, "new lesson mixes preserve scoring and completion")
        }
        expect(actualSkills.count == 120 && player.profile.adventureComplete, "a real perfect run teaches every combination and completes the adventure")
        expect(player.profile.totalStars == 300 && finalBossTiers == Array(repeating: .challenge, count: 10),
               "the final boss really runs ten maximum-difficulty questions and a perfect boss earns three stars")

        let mixed = DinoSession(level: DinoLevelCatalog.level(11)!, player: player)
        expect(mixed.question.kind == .chooseAnalog && mixed.minuteStep == 30, "mixed-time lesson starts on half hours")
        mixed.submit(mixed.question.expectedAnswer); mixed.advance()
        expect(mixed.question.kind == .chooseAnalog && mixed.minuteStep == 60 && mixed.question.difficulty == .challenge,
               "the same question kind can change time family and baseline difficulty inside one lesson")

        // A mistake temporarily reduces another skill, and persistently reduces the failed skill.
        let finalLevel = DinoLevelCatalog.level(98)!
        let failed = DinoSession(level: finalLevel, player: player)
        expect(failed.question.kind == .sayTime && failed.question.difficulty == .challenge, "late lessons begin at their authored maximum after learning")
        failed.submit(wrongAnswer(for: failed.question)); failed.showAnswer(); failed.advance()
        expect(failed.question.kind == .setAnalog && failed.question.difficulty == .familiar && failed.attempt.answers == [false],
               "a mixed-type error produces an easier next question without changing its planned skill or score")
        let restarted = DinoPlayer(store: store)
        let retry = DinoSession(level: finalLevel, player: restarted)
        expect(retry.question.difficulty == .familiar, "the failed combination remains easier after restarting the app")
        let stored = store.loadLearningProgress()
        let key = DinoLearningProgress.key(kind: .sayTime, time: .minutes)
        expect(stored[key]?.recoveryTarget == .challenge, "the previous level is remembered during recovery")
        for _ in 0..<2 {
            let lesson = DinoSession(level: finalLevel, player: restarted)
            expect(lesson.question.difficulty == .familiar, "recovery does not jump to maximum early")
            lesson.submit(lesson.question.expectedAnswer)
            lesson.submit(lesson.question.expectedAnswer)
        }
        expect(DinoSession(level: finalLevel, player: restarted).question.difficulty == .challenge, "two successful first answers restore the planned maximum")
        expect(finalLevel.recipes.allSatisfy { $0.difficulty == .challenge }, "adaptive support never mutates the authored curriculum")

        let legacy = try! JSONDecoder().decode(DinoLearningProgress.self, from: Data(#"{"difficulty":1,"consecutiveCorrect":2}"#.utf8))
        expect(legacy.difficulty == .familiar && legacy.consecutiveCorrect == 2 && legacy.recoveryTarget == nil, "older hidden-learning saves remain readable")
        memory.set(try! JSONEncoder().encode(stored), forKey: DinoProgressStore.learningKey)
        expect(DinoProgressStore(defaults: memory).loadLearningProgress()[key]?.recoveryTarget == .challenge, "validated loading preserves active recovery")
    }

    static func testAdaptiveDifficulty() {
        expect(DinoQuestionCategory.all.count == 360 && Set(DinoQuestionCategory.all).count == 360,
               "twenty types, six minute families and three internal teaching steps")
        for time in DinoPracticeTime.allCases {
            expect(time.minutes == Array(stride(from: 0, to: 60, by: time.minuteStep)), "each family includes all its multiples, including zero")
        }
        expect(DinoPracticeTime.quarter.minutes == [0, 15, 30, 45], "quarter practice also reviews whole and half hours")
        expect(DinoPracticeTime.minutes.minuteStep == 1 && DinoPracticeTime.minutes.minutes.count == 60, "Minutes practices individual minutes")
        expect(DinoTimeWords.time(.init(hour: 3, minute: 1), language: "nl") == "1 minuut over drie", "single-minute Dutch questions use the singular")
        expect(DinoTimeWords.time(.init(hour: 3, minute: 59), language: "nl") == "1 minuut voor vier", "late Dutch minutes refer to the next hour")
        expect(DinoTimeWords.time(.init(hour: 3, minute: 1), language: "en") == "1 minute past three", "single-minute English questions use the singular")
        expect(DinoTimeWords.time(.init(hour: 3, minute: 59), language: "en") == "1 minute to four", "late English minutes refer to the next hour")
        for language in ["nl", "en"] {
            for category in DinoQuestionCategory.all {
                let configuration = DinoPracticeConfiguration(time: category.time, order: .specific(category.type))
                var generator = DinoPracticeGenerator(configuration: configuration, seed: 105, language: language)
                var replay = generator
                var previous: ClockTime?
                for index in 0..<12 {
                    let q = generator.next(index: index, difficultyForKind: { _ in category.difficulty })
                    expect(q == replay.next(index: index, difficultyForKind: { _ in category.difficulty }), "all 360 categories are reproducible in both languages")
                    expect(q.kind == category.type.recipe.kind && q.timeFamily == category.time && q.difficulty == category.difficulty,
                           "every category retains its independent dimensions")
                    expect(q.id == index && q.target != previous, "adaptive questions retain IDs and avoid consecutive duplicate targets")
                    previous = q.target
                    expect(category.time.minutes.contains(q.target.minute), "teaching steps stay in the selected time family")
                    let optionMinutes = q.kind == .readDigital
                        ? Array(stride(from: 0, to: 60, by: min(15, category.time.minuteStep))) : category.time.minutes
                    expect(q.options.allSatisfy { optionMinutes.contains($0.minute) }
                           && (q.relatedTimes + (q.kind == .readDigital ? [] : q.companionClocks)).allSatisfy { category.time.minutes.contains($0.minute) },
                           "options and arithmetic context remain on the selected grid")
                    expect(AnswerValidator.isCorrect(q.expectedAnswer, for: q) && !AnswerValidator.isCorrect(wrongAnswer(for: q), for: q),
                           "every teaching step has a valid, discriminating answer")
                    if q.kind.usesOptions {
                        expect(Set(q.responses).count == q.responses.count && q.responses.filter { $0 == q.expectedAnswer }.count == 1,
                               "all teaching steps offer unique choices and exactly one correct response")
                        let count = q.kind == .trueFalse ? 2 : q.kind == .dayPart ? 4 : category.difficulty.optionCount
                        expect(q.responses.count == count, "introduction reduces answer load without changing binary or day-part exercises")
                    }
                    switch q.kind {
                    case .read24Hour:
                        let correctTime = DinoTimeWords.time(q.target, language: language)
                        expect(q.options.filter { $0 != q.target }.allSatisfy {
                            DinoTimeWords.time($0, language: language) != correctTime
                        }, "24-hour distractors differ in time words even without the day part")
                    case .addTime, .advanceAnalog:
                        expect(q.relatedTimes[0].adding(minutes: q.durationMinutes) == q.target, "all tiers preserve addition")
                    case .subtractTime:
                        expect(q.relatedTimes[0].adding(minutes: -q.durationMinutes) == q.target, "all tiers preserve subtraction")
                    case .minutesBetween:
                        let limit = category.difficulty == .introduction ? category.time.minuteStep : category.difficulty == .familiar ? 90 : 180
                        expect(q.durationMinutes <= limit && q.relatedTimes[1].minutesOfDay - q.relatedTimes[0].minutesOfDay == q.durationMinutes,
                               "elapsed-time complexity changes independently of the minute grid")
                        expect(q.responses.allSatisfy { if case .duration(let value) = $0 { return value.isMultiple(of: category.time.minuteStep) }; return false },
                               "duration alternatives also retain the selected minute multiples")
                    case .timeSequence:
                        let times = q.relatedTimes + [q.target]
                        expect(zip(times, times.dropFirst()).allSatisfy { $0.adding(minutes: q.durationMinutes) == $1 }, "sequence steps agree in all categories")
                    case .flightArrival:
                        expect(q.relatedTimes[0].adding(minutes: q.durationMinutes + q.offsetMinutes) == q.target, "all flight tiers have consistent tickets")
                        expect((q.offsetMinutes == 0) == (category.difficulty == .introduction), "flights introduce duration before adding zone changes")
                    case .timeZone:
                        expect(q.relatedTimes[0].adding(minutes: q.offsetMinutes) == q.target, "all geographic tiers agree with their displayed offset")
                        if category.difficulty == .introduction { expect(abs(q.offsetMinutes) == 60, "first maps use a single hour") }
                        if category.difficulty == .challenge { expect(abs(q.offsetMinutes) >= 210, "later maps use distant countries in every minute family") }
                    case .daySchedule:
                        expect(q.daySchedule?.end == q.target && q.daySchedule?.totalMinutes == q.durationMinutes, "train tiers include both trains and the transfer")
                    case .sayTime:
                        expect(q.spokenPrompt?.phrase.isEmpty == false && q.spokenPrompt?.correct == { if case .spoken(let answer) = q.expectedAnswer { return answer }; return nil }(),
                               "spoken questions support exact minutes in both languages")
                    case .match: checkMatchingQuestion(q)
                    case .sortTimes:
                        expect(q.options.count == 4, "the sorting board retains four clocks at every tier")
                    default: break
                    }
                }
            }
        }
        for time in DinoPracticeTime.allCases {
            var generator = DinoPracticeGenerator(configuration: .init(time: time, order: .specific(.chooseDigital)), seed: 87)
            var targets = Set<Int>(), options = Set<Int>()
            var minuteCounts: [Int: Int] = [:]
            for index in 0..<1600 {
                let q = generator.next(index: index, difficultyForKind: { _ in .challenge })
                targets.insert(q.target.minute); options.formUnion(q.options.map(\.minute))
                minuteCounts[q.target.minute, default: 0] += 1
            }
            let missingTargets = Set(time.minutes).subtracting(targets)
            let missingOptions = Set(time.minutes).subtracting(options)
            expect(missingTargets.isEmpty && missingOptions.isEmpty,
                   "\(time) targets missing \(missingTargets.sorted()) options missing \(missingOptions.sorted())")
            expect(minuteCounts.values.max()! < 2 * minuteCounts.values.min()!, "all allowed minutes remain well represented")
        }
        var quarters = DinoPracticeGenerator(configuration: .init(time: .quarter, order: .specific(.chooseAnalog)), seed: 11)
        let introductoryMinutes = Set((0..<100).map { quarters.next(index: $0).target.minute })
        expect(introductoryMinutes == [0, 15, 30, 45], "even introduction varies over every quarter position after its first question")
        var rng = SeededGenerator(seed: 30)
        for code in ["nl", "en"] {
            let language = SpokenTimeCatalog.language(code: code)
            for minute in 0..<60 {
                let prompt = language.prompt(for: ClockTime(hour: 11, minute: minute), using: &rng)
                let wordsPresent = zip(prompt.slots, prompt.correct.choiceIDs).allSatisfy { slot, id in
                    id == SpokenTimeChoice.emptyID
                        ? !slot.choices.contains { $0.id == SpokenTimeChoice.emptyID }
                        : slot.choices.contains { $0.id == id }
                }
                expect(!prompt.phrase.isEmpty && wordsPresent, "all sixty spoken minute positions have selectable correct words")
            }
        }

        let memory = InMemoryKeyValueStore()
        let store = DinoProgressStore(defaults: memory)
        let player = DinoPlayer(store: store)
        let configuration = DinoPracticeConfiguration(time: .whole, order: .specific(.chooseAnalog))
        let session = DinoSession(level: configuration.level, player: player, practice: configuration)
        expect(session.question.difficulty == .introduction, "the first encounter introduces the exercise gently")
        session.submit(session.question.expectedAnswer); session.advance()
        expect(session.question.difficulty == .familiar, "one correct first answer moves beyond the welcoming question")
        for _ in 0..<2 { session.submit(session.question.expectedAnswer); session.advance() }
        expect(session.question.difficulty == .challenge, "three successful answers reach the challenging tier")
        session.submit(session.question.responses.first { $0 != session.question.expectedAnswer }!)
        expect(player.questionDifficulty(kind: .chooseAnalog, time: .whole) == .familiar, "a first-attempt error immediately lowers the saved skill")
        let afterWrong = memory.object(forKey: DinoProgressStore.learningKey) as? Data
        session.submit(session.question.expectedAnswer)
        expect(memory.object(forKey: DinoProgressStore.learningKey) as? Data == afterWrong, "a correct retry does not undo the adaptive reduction")
        session.advance()
        expect(session.question.difficulty == .familiar && session.practiceAnswered == 4, "the next live question is easier without adding or removing scores")
        expect(player.questionDifficulty(kind: .chooseDigital, time: .whole) == .introduction && player.questionDifficulty(kind: .chooseAnalog, time: .half) == .introduction,
               "difficulty is independent per exercise and time family")
        let reloaded = DinoPlayer(store: store)
        expect(reloaded.questionDifficulty(kind: .chooseAnalog, time: .whole) == .familiar, "learning survives relaunch")
        let example = DinoSession(level: configuration.level, player: player, practice: configuration, example: session.question)
        example.submit(wrongAnswer(for: example.question)); example.submit(example.question.expectedAnswer)
        expect(memory.object(forKey: DinoProgressStore.learningKey) as? Data == afterWrong, "examples never affect the learner's difficulty")

        // Establish prior mastery, then check both mixed orders and an adventure level.
        for type in DinoPracticeQuestion.allCases {
            var question = ClockQuestion(id: 0, kind: type.recipe.kind, target: ClockTime(hour: 3), options: [], activity: nil, companionClocks: [])
            question.difficulty = .challenge
            for _ in 0..<3 { player.recordLearningAnswer(question: question, correct: true) }
        }
        for order in [DinoPracticeOrder.ascending, .mix] {
            let config = DinoPracticeConfiguration(time: .whole, order: order)
            let mixed = DinoSession(level: config.level, player: player, practice: config)
            let presented = mixed.question.difficulty
            mixed.submit(wrongAnswer(for: mixed.question)); mixed.showAnswer(); mixed.advance()
            expect(mixed.question.difficulty.rawValue <= presented.easier.rawValue, "an error offers immediate relief even when the next mixed exercise differs")
        }
        var mastered = ClockQuestion(id: 0, kind: .chooseAnalog, target: ClockTime(hour: 3), options: [], activity: nil, companionClocks: [])
        mastered.difficulty = .challenge
        for _ in 0..<3 { player.recordLearningAnswer(question: mastered, correct: true) }
        let early = DinoSession(level: DinoLevelCatalog.level(1)!, player: player)
        expect(early.question.difficulty == .introduction, "early adventure lessons keep their introductory ceiling")
        let later = DinoSession(level: DinoLevelCatalog.level(10)!, player: player)
        expect(later.question.difficulty == .challenge, "later adventure levels can challenge a familiar exercise")
        later.submit(wrongAnswer(for: later.question)); later.showAnswer(); later.advance()
        expect(later.question.difficulty == .familiar && later.attempt.answers == [false] && later.attempt.questions.count == 10,
               "adventure adapts its unanswered question while preserving the boss length, ID and first score")
        let beginner = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
        let directBoss = DinoSession(level: DinoLevelCatalog.level(10)!, player: beginner)
        expect(directBoss.question.difficulty == .introduction, "even a direct boss starts a previously unseen type gently")
        for levelID in [12, 22, 32, 42, 63, 97] {
            let level = DinoLevelCatalog.level(levelID)!
            for _ in 0..<6 {
                let learner = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
                for recipe in level.recipes {
                    var known = mastered
                    known = ClockQuestion(id: 0, kind: recipe.kind, target: known.target, options: [], activity: nil, companionClocks: [],
                                          difficulty: .challenge, timeFamily: level.time(for: recipe))
                    for _ in 0..<3 { learner.recordLearningAnswer(question: known, correct: true) }
                }
                let run = DinoSession(level: level, player: learner)
                var previous: ClockTime?
                for index in 0..<level.questionCount {
                    expect(run.question.target != previous, "regenerating an adventure question never repeats the adapted previous target")
                    previous = run.question.target
                    run.submit(index == 2 ? wrongAnswer(for: run.question) : run.question.expectedAnswer)
                    run.showAnswer(); run.advance()
                }
                expect(run.attempt.isComplete && run.attempt.answers.count == level.questionCount && run.attempt.correctCount == level.questionCount - 1,
                       "adaptation across minute worlds preserves question count and first-attempt scores")
            }
        }
        player.resetProgress()
        expect(store.loadLearningProgress().isEmpty && player.questionDifficulty(kind: .chooseAnalog, time: .whole) == .introduction,
               "progress reset clears hidden learning as well as visible records")
        player.recordLearningAnswer(question: mastered, correct: true)
        player.resetAllData()
        expect(store.loadLearningProgress().isEmpty, "full reset also clears hidden learning")

        let legacy = DinoPracticeRecord(bestStreak: 9, questionsAnswered: 24, currentStreak: 2)
        memory.set(try! JSONEncoder().encode(["mix.chooseAnalog": legacy, "whole.mix": legacy]), forKey: DinoProgressStore.practiceKey)
        expect(store.loadPracticeRecords()["minutes.chooseAnalog"] == legacy && store.loadPracticeRecords()["whole.mix"] == legacy,
               "legacy time Mix records migrate while the mixed question order remains intact")
        memory.set("mix", forKey: "dino.settings.practiceTime")
        memory.set("mix", forKey: "dino.settings.practiceOrder")
        let settings = DinoSettings(defaults: memory)
        expect(settings.practiceTime == .minutes && settings.practiceOrder == .mix, "old preferences migrate to exact Minutes without changing question order")
    }

    static func testQuestionVariation() {
        // Every type and teaching step must explore the full selected grid promptly,
        // even when a player keeps making mistakes and remains at introduction.
        for seed: UInt64 in [7, 20261025] {
            for category in DinoQuestionCategory.all {
                var generator = DinoPracticeGenerator(configuration: .init(time: category.time, order: .specific(category.type)), seed: seed)
                var minutes = Set<Int>(), hours = Set<Int>()
                var previous: ClockTime?
                let count = max(12, category.time.minutes.count)
                for index in 0..<count {
                    let question = generator.next(index: index, difficultyForKind: { _ in category.difficulty })
                    minutes.insert(question.target.minute); hours.insert(question.target.hour)
                    expect(question.target != previous, "varied questions do not repeat the preceding answer")
                    previous = question.target
                    if index == 0 && category.difficulty == .introduction {
                        expect([0, 3, 6, 9].contains(question.target.hour % 12), "only the welcoming question prefers clear hour-hand positions")
                    }
                    if let schedule = question.daySchedule {
                        expect(schedule.start.minutesOfDay >= 360 && schedule.end.minutesOfDay <= 1320 && schedule.start.minutesOfDay < schedule.end.minutesOfDay,
                               "every train leg and transfer occurs between 06:00 and 22:00 on one day")
                        expect(schedule.firstMinutes >= 10 && schedule.secondMinutes >= 10 && schedule.breakMinutes <= max(30, category.time.minuteStep),
                               "train legs and transfers have believable durations on the chosen grid")
                    }
                }
                expect(minutes == Set(category.time.minutes), "\(category) explores all minute positions within \(count) questions, got \(minutes.sorted())")
                expect(hours.count >= 4, "\(category) varies hours as well as minute positions")
            }
        }
        // Ascending and shuffled practice retain a separate history for every skill.
        for order in [DinoPracticeOrder.ascending, .mix] {
            var generator = DinoPracticeGenerator(configuration: .init(time: .fiveMinutes, order: order), seed: 81)
            var minutes: [ClockQuestionKind: Set<Int>] = [:]
            for index in 0..<(12 * DinoPracticeQuestion.allCases.count) {
                let question = generator.next(index: index, difficultyForKind: { _ in .familiar })
                minutes[question.kind, default: []].insert(question.target.minute)
            }
            expect(minutes.count == 20 && minutes.values.allSatisfy { $0 == Set(DinoPracticeTime.fiveMinutes.minutes) },
                   "both mixed orders cover every five-minute position in every exercise type")
        }
        for kind in [ClockQuestionKind.addTime, .subtractTime, .advanceAnalog, .timeSequence, .minutesBetween, .flightArrival] {
            var generator = DinoPracticeGenerator(configuration: .init(time: .fiveMinutes, order: .specific(DinoPracticeQuestion(rawValue: kind.rawValue)!)), seed: 35)
            var durations = Set<Int>()
            for index in 0..<24 { durations.insert(generator.next(index: index, difficultyForKind: { _ in .challenge }).durationMinutes) }
            expect(durations.count >= 8, "\(kind) varies calculation durations beyond the old first three steps")
            if [.addTime, .subtractTime, .advanceAnalog].contains(kind) {
                expect(durations.contains { $0 > 60 && !$0.isMultiple(of: 60) }, "challenging arithmetic combines hours and minutes")
            }
        }
        for language in ["nl", "en"] {
            for family in DinoPracticeTime.allCases {
                for type in [DinoPracticeQuestion.timeZone, .flightArrival] {
                    var generator = DinoPracticeGenerator(configuration: .init(time: family, order: .specific(type)), seed: 91, language: language)
                    var halfHours = 0
                    for index in 0..<80 {
                        let q = generator.next(index: index, difficultyForKind: { _ in .challenge })
                        expect(q.offsetMinutes.isMultiple(of: 30) && q.offsetMinutes.isMultiple(of: family.minuteStep),
                               "zone differences are whole or half hours and preserve the chosen time grid")
                        if !q.offsetMinutes.isMultiple(of: 60) { halfHours += 1 }
                    }
                    expect(30.isMultiple(of: family.minuteStep) ? (1...30).contains(halfHours) : halfHours == 0,
                           "half-hour zones occur occasionally and only in compatible time families")
                }
            }
        }
        let london = DinoTimeZoneJourney.capitals.first { $0.id == "london" }!
        let delhi = DinoTimeZoneJourney.capitals.first { $0.id == "newDelhi" }!
        for journey in [DinoTimeZoneJourney(origin: london, destination: delhi), .init(origin: delhi, destination: london)] {
            let start = ClockTime(hour: 23, minute: 45), steps = journey.steps(from: ClockTime(hour: 23, minute: 45))
            expect(abs(journey.offsetMinutes) % 60 == 30, "real half-hour city offsets are not truncated")
            expect(steps.last?.time == start.adding(minutes: journey.offsetMinutes) && steps.last?.addedMinutes == journey.offsetMinutes,
                   "both directions of the worked zone example include the final half hour across midnight")
            expect(abs(steps.last!.addedMinutes - (steps.dropLast().last?.addedMinutes ?? 0)) == 30, "the final animation step is thirty minutes")
        }
        expect(DinoTimeWords.zoneDifference(330, language: "nl") == "+5½ uur" && DinoTimeWords.zoneDifference(-210, language: "en") == "−3½ h",
               "compact labels retain half hours and the direction")
        let work = DinoFlightArrivalWork(departure: .init(hour: 22, minute: 15), durationMinutes: 360, offsetMinutes: -210, arrival: .init(hour: 0, minute: 45))
        expect(work.combinedMinutes == 150 && work.departure.adding(minutes: work.combinedMinutes) == work.arrival,
               "flight calculations preserve a half-hour zone difference across midnight")
        var custom = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.dayPart)), seed: 19,
            dayPartSchedule: .init(night: 0, morning: 1, afternoon: 2, evening: 3))
        var previous: ClockTime?
        for index in 0..<80 {
            let question = custom.next(index: index, difficultyForKind: { _ in .familiar })
            expect(question.target != previous, "a custom one-hour day part cannot force an immediately repeated question")
            previous = question.target
        }
    }

    static func testMapAnimationViewport() {
        for viewport: CGFloat in [568, 852, 1194, 1366] {
            for height: CGFloat in [30, 320, 2200] {
                let incoming = CGRect(x: 0, y: viewport + 200, width: 390, height: height)
                expect(DinoMapViewport.preparesAnimation(frame: incoming, viewportHeight: viewport),
                       "animation and its masks are built before entering any viewport size")
                let distant = incoming.offsetBy(dx: 0, dy: 100)
                expect(!DinoMapViewport.preparesAnimation(frame: distant, viewportHeight: viewport),
                       "upcoming machinery does not build distant masks")
                expect(DinoMapViewport.preparesAnimation(frame: distant, viewportHeight: viewport, retained: true),
                       "small reverse drags reuse a recently prepared animation")
                expect(!DinoMapViewport.preparesAnimation(frame: CGRect(x: 0, y: -height - 513, width: 390, height: height),
                                                        viewportHeight: viewport, retained: true),
                       "far-away surfaces release their masks")
                let visible = CGRect(x: 0, y: viewport - 1, width: 390, height: height)
                expect(DinoMapViewport.preparesAnimation(frame: visible, viewportHeight: viewport),
                       "visible flowing water is never deferred")
            }
        }
        expect(!DinoMapViewport.preparesAnimation(frame: .zero, viewportHeight: 852),
               "unmeasured animation layers do not build an initial drawing")
        let frame = CGRect(x: 0, y: -600, width: 390, height: 2200)
        let bounds = DinoMapViewport.animationBounds(frame: frame, viewportHeight: 800)
        expect(bounds.contains(CGRect(x: 0, y: 600, width: 390, height: 800)), "animation bands include the entire visible map")
        expect(bounds == DinoMapViewport.animationBounds(frame: frame.offsetBy(dx: 0, dy: -1), viewportHeight: 800),
               "one scroll pixel does not rebuild moving map scenery")
        expect(bounds.height < 800 + 512, "animation preparation stays within two small extra bands")
        for scale: CGFloat in [1.2, 1.45, 1.55] {
            let magnified = frame.applying(CGAffineTransform(scaleX: scale, y: scale))
            let local = DinoMapViewport.animationBounds(frame: magnified, viewportHeight: 800 * scale, scale: scale)
            expect(local == bounds, "zoomed map animations retain the same local visible bands")
            expect(!DinoMapViewport.preparedAnimationBounds(frame: magnified, viewportHeight: 800 * scale, scale: scale).isEmpty,
                   "zoomed visible map actors stay prepared")
        }
        for y: CGFloat in [-2200, -3000, 800, 1200] {
            expect(DinoMapViewport.animationBounds(frame: CGRect(x: 0, y: y, width: 390, height: 2200), viewportHeight: 800).isEmpty,
                   "fully offscreen animation stops")
        }
        let edge = DinoMapViewport.animationBounds(frame: CGRect(x: 0, y: 790, width: 390, height: 2200), viewportHeight: 800)
        expect(edge.minY == 0 && edge.maxY >= 10, "a partially visible chapter keeps its first animation band")
        let incoming = DinoMapViewport.preparedAnimationBounds(frame: CGRect(x: 0, y: 900, width: 390, height: 2200), viewportHeight: 800)
        expect(!incoming.isEmpty, "incoming actors prepare before reaching the screen")
        let distant = DinoMapViewport.preparedAnimationBounds(frame: CGRect(x: 0, y: 1200, width: 390, height: 2200), viewportHeight: 800)
        expect(distant.isEmpty, "distant actors do not consume animation frames")
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
            // A clearance solver can pass while pushing every crown offscreen.
            // Require substantial visible tree canopy on both banks, including
            // the final grove and entrance crowns above the route's first row.
            let entranceRise = WorldMapChapterSpacing.sceneOffset(width: width)
            for right in [false, true] {
                let visibleTrees = scene.placements.filter { placement in
                    guard placement.item.kind == .tree, (placement.point.x > width / 2) == right else { return false }
                    let crown = layout.footprint(of: placement.item)[0]
                        .offsetBy(dx: placement.point.x, dy: placement.point.y)
                    let visible = crown.intersection(CGRect(x: 0, y: -entranceRise, width: width, height: 1800 + entranceRise))
                    return !visible.isNull && visible.width >= crown.width * 0.35
                }
                expect(visibleTrees.count >= 3, "both jungle banks retain visible trees at width \(width)")
                expect(visibleTrees.contains { (1200...1720).contains($0.point.y) },
                       "the final jungle bends have visible tree canopy on both banks")
            }
            let bossStage = WorldBossStage(worldID: 1, width: width)
            expect(scene.bossPoint == bossStage.point, "jungle body and clocks share the reserved clearing")
            for placement in scene.placements {
                for band in layout.footprint(of: placement.item) {
                    expect(!band.offsetBy(dx: placement.point.x, dy: placement.point.y).intersects(bossStage.clearance),
                           "jungle foliage and wildlife keep the entire boss visible at width \(width)")
                }
            }
            for world in [1, 3, 4, 5, 6, 8, 10] {
                let stage = WorldBossStage(worldID: world, width: width)
                expect(stage.ground.maxX < width && stage.ground.minX > width / 2,
                       "boss has a complete floor beside the road at width \(width)")
                expect(stage.clearance.contains(stage.ground), "scenery reservation includes the complete floor")
                expect(stage.point.x - width / 2 <= 168, "tablet bosses stay connected to the final level stone")
            }
            expect(scene === layout.scene(), "unchanged viewport reuses resolved jungle coordinates")
            expect(scene.sceneryTiles.flatMap(\.placements).allSatisfy { !$0.item.kind.animated },
                   "static scenery shares a depth layer while animation stays independent")
            expect(scene.sceneryTiles.contains( where: { $0.includesBoss }),
                   "the jungle boss shares the scenery tiles instead of sitting behind every tree")
            let chapterEnd = JungleMapLayout.firstNodeY + 9 * JungleMapLayout.levelSpacing + JungleMapLayout.bossReturnSpan(for: width)
            for placement in scene.placements where !placement.item.kind.animated {
                expect(placement.bounds.maxY <= chapterEnd - 16,
                       "complete jungle roots and leaves stay above the desert edge at width \(width)")
            }
            let trailWidth = min(width, 600) - 36
            let lastY = JungleMapLayout.firstNodeY + 9 * JungleMapLayout.levelSpacing
            expect(abs(layout.centerX(at: lastY) - width/2) < 0.01, "jungle boss stone is centered")
            expect(layout.centerX(at: lastY - JungleMapLayout.levelSpacing) < width/2 - 30,
                   "the stone before the jungle boss stays in the preceding left bend")
            expect(abs(layout.centerX(at: JungleMapLayout.firstNodeY) - width / 2) < 0.01,
                   "the first jungle stone is centered as well as the boss stone")
            expect(JungleMapLayout.levelPositions.min()! < 0.30 &&
                   JungleMapLayout.levelPositions.max()! > 0.70,
                   "the jungle keeps broad alternating bends between its central endpoints")
            expect(scene.placements.contains { placement in
                let bounds = placement.bounds
                let visible = bounds.intersection(CGRect(x: 0, y: 0, width: width, height: chapterEnd))
                return placement.item.kind == .ruins && placement.point.x > width / 2 &&
                    placement.point.y > 1400 && bounds.maxY < bossStage.clearance.minY &&
                    !visible.isNull && visible.width > bounds.width * 0.75
            }, "a visible, low ruin fills the final right-bank pocket above the jungle boss")
            for (index, fraction) in JungleMapLayout.levelPositions.enumerated() {
                let y = JungleMapLayout.firstNodeY + CGFloat(index) * JungleMapLayout.levelSpacing
                let expected = (width - trailWidth) / 2 + trailWidth * fraction
                expect(abs(layout.centerX(at: y) - expected) < 0.01, "jungle placement follows each real level centre")
                let incoming = (layout.centerX(at: y) - layout.centerX(at: y - 0.01)) / 0.01
                let outgoing = (layout.centerX(at: y + 0.01) - layout.centerX(at: y)) / 0.01
                expect(abs(incoming - outgoing) < 0.001, "jungle bends pass smoothly through every level stone")
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
                   "the waterfall stands on the left bank near level four")
            expect(layout.waterfall.heightScale == 0.78 && layout.waterfall.mirrored &&
                   layout.waterfall.preferred.x < width / 2 - min(width, 720) * 0.4,
                   "the jungle waterfall is shorter, at the bank and fed from the left")
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
        let crown = phone.footprint(of: oldTree)[0].offsetBy(dx: moved.x, dy: moved.y)
        expect(stride(from: crown.minY, through: crown.maxY, by: 1).allSatisfy {
            crown.maxX < phone.centerX(at: $0) - phone.clearance(at: $0)
        }, "an oversized crown clears the complete higher bend of the new jungle route")
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
        let key = DinoPracticeRecord.key(time: .minutes, question: .setAnalog)
        store.savePracticeRecords([key: .init(bestStreak: 20, questionsAnswered: 999), "unknown": .init(bestStreak: 10, questionsAnswered: 10)])
        let nearThousand = DinoPlayer(store: store)
        let thousandConfig = DinoPracticeConfiguration(time: .minutes, order: .specific(.setAnalog))
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

    static func testBossClockMotion() {
        let start = ClockTime(hour: 11, minute: 50)
        func phase(_ elapsed: TimeInterval, boss: Bool = true) -> WorldClockMotion.Phase {
            .init(initial: start, elapsed: elapsed, minuteRevolution: boss
                ? WorldClockMotion.bossMinuteRevolution : WorldClockMotion.cityMinuteRevolution)
        }
        expect(WorldClockMotion.bossMinuteRevolution == 12, "boss minute hand takes twelve seconds per revolution")
        expect(phase(0).minuteAngle == start.minuteAngle && phase(0).hourAngle == start.hourAngle,
               "animated clocks start at their specified time")
        for elapsed in stride(from: 0.0, through: 288.0, by: 0.125) {
            expect(abs(phase(elapsed).minuteAngle - phase(elapsed * 2, boss: false).minuteAngle) < 0.000001,
                   "boss minute hand runs at exactly twice the city speed")
            expect(abs(phase(elapsed).hourAngle - phase(elapsed * 2, boss: false).hourAngle) < 0.000001,
                   "boss hour hand follows the same speed ratio")
        }
        expect(phase(2).reading == ClockTime(hour: 12), "clock carries minutes across twelve")
        expect(abs(phase(3).minuteAngle - 30) < 0.000001 && abs(phase(3).hourAngle - 2.5) < 0.000001,
               "hour hand advances smoothly by one twelfth of the minute movement")
        expect(phase(12).minuteAngle == phase(0).minuteAngle, "minute hand closes one full revolution")
        expect(phase(144).hourAngle == phase(0).hourAngle, "hour hand closes one full revolution")
        expect(phase(288).reading == start && phase(288.125).minuteAngle == phase(0.125).minuteAngle,
               "whole-day wrapping is continuous")
        expect(phase(-1).minuteAngle == phase(0).minuteAngle, "a future animation epoch stays at its initial time")
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
        expect(ClockTime(hour: 0, minute: 5).digitalReading(notation: .twelve, languageCode: "en") ==
               DigitalClockReading(hour: "12", minute: "05", period: "AM"), "midnight reads as 12 AM")
        expect(ClockTime(hour: 12).digitalReading(notation: .twelve, languageCode: "nl").text == "12:00 PM", "noon reads as 12 PM")
        expect(ClockTime(hour: 15, minute: 30).digitalReading(notation: .twelve, languageCode: "en").text == "03:30 PM", "afternoon hours keep two digits and PM")
        expect(ClockTime(hour: 23, minute: 59).digitalReading(notation: .twelve, languageCode: "nl").text == "11:59 PM", "late evening stays within twelve hours")
        expect(ClockTime(hour: 9, minute: 7).digitalReading(notation: .twentyFour, languageCode: "nl").text == "09:07", "24-hour notation keeps the leading zero")
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

    static func testHandSelection() {
        func selected(_ x: Double, _ y: Double, time: ClockTime = ClockTime(hour: 3), minutes: Bool) -> Bool {
            ClockHandSelection.minutes(at: CGPoint(x: x, y: y), hourAngle: time.hourAngle,
                                       minuteAngle: time.minuteAngle, preferredMinutes: minutes)
        }
        expect(!selected(0.20, 0, minutes: true), "touching the hour hand switches away from minutes")
        expect(selected(0, -0.31, minutes: false), "touching the minute hand switches away from hours")
        expect(!selected(-0.4, 0, minutes: false) && selected(-0.4, 0, minutes: true),
               "tapping the empty dial retains the selected hand")
        expect(!selected(0, 0, minutes: false) && selected(0, 0, minutes: true),
               "the shared centre does not select another hand")
        expect(!selected(0, -0.20, time: ClockTime(hour: 12), minutes: false),
               "overlapping hands retain the hour selection")
        expect(selected(0, -0.20, time: ClockTime(hour: 12), minutes: true),
               "overlapping hands retain the minute selection")
        expect(selected(0, -0.33, time: ClockTime(hour: 12), minutes: false),
               "the exposed minute tip can be selected when the hands overlap")
        for hour in 1...12 {
            for minute in 0..<60 {
                let time = ClockTime(hour: hour, minute: minute)
                let tip = ClockHandHintGeometry.point(radius: 0.33, angle: time.minuteAngle)
                expect(selected(tip.x, tip.y, time: time, minutes: false),
                       "the long minute tip remains selectable at every clock time")
                let hourPoint = ClockHandHintGeometry.point(radius: 0.20, angle: time.hourAngle)
                expect(!selected(hourPoint.x, hourPoint.y, time: time, minutes: false),
                       "touching the selected hour hand retains it at every clock time")
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
        for shape in AnalogClockShape.allCases {
            let marks = ClockHandHintGeometry.minuteMarks(shape: shape)
            expect(marks.map(\.minute) == Array(stride(from: 0, to: 60, by: 5)),
                   "minute scale starts with zero and counts by five")
            for mark in marks {
                let edge = ClockHandHintGeometry.outerRadius(angle: Double(mark.minute) * 6, shape: shape)
                expect(hypot(mark.tickStart.x, mark.tickStart.y) > edge
                       && hypot(mark.label.x, mark.label.y) > hypot(mark.tickEnd.x, mark.tickEnd.y),
                       "minute ticks and labels sit outside every clock shape")
            }
            for hour in 1...12 {
                for minute in 0..<60 {
                    let time = ClockTime(hour: hour, minute: minute)
                    let pointers = ClockHandHintGeometry.pointers(time: time, shape: shape)
                    let expectedHour = ClockHandHintGeometry.point(radius: 0.412, angle: Double(hour % 12) * 30)
                    expect(hypot(pointers[0].tip.x - expectedHour.x, pointers[0].tip.y - expectedHour.y) < 0.000_001,
                           "hour pointer targets the completed digital hour at \(time.digitalText)")
                    let minuteDirection = ClockHandHintGeometry.point(radius: 1, angle: time.minuteAngle)
                    let minuteTip = pointers[1].tip
                    expect(abs(minuteTip.x * minuteDirection.y - minuteTip.y * minuteDirection.x) < 0.000_001,
                           "minute pointer follows the exact minute, without rounding to a five")
                    let edge = ClockHandHintGeometry.outerRadius(angle: time.minuteAngle, shape: shape)
                    expect(hypot(minuteTip.x, minuteTip.y) > edge + 0.12,
                           "minute pointer leaves breathing room beyond the outside scale")
                    for pointer in pointers {
                        for hand in [(time.hourAngle, 0.23, 0.038), (time.minuteAngle, 0.34, 0.024)] {
                            let start = ClockHandHintGeometry.point(radius: -0.035, angle: hand.0)
                            let end = ClockHandHintGeometry.point(radius: hand.1, angle: hand.0)
                            for arrowEdge in [pointer.start] + pointer.arrowWings {
                                let clearance = ClockHandHintGeometry.segmentDistance(arrowEdge, pointer.tip, start, end) - hand.2 / 2
                                expect(clearance > 0.015, "reading arrows stay clear of both hands at \(time.digitalText)")
                            }
                        }
                        expect(max(abs(pointer.badge.x), abs(pointer.badge.y)) + 0.09 <= ClockHandHintGeometry.extent(shape: shape),
                               "number badges fit inside the reserved example space")
                    }
                    for mark in marks {
                        for arrowEdge in [pointers[0].start] + pointers[0].arrowWings {
                            expect(ClockHandHintGeometry.segmentDistance(arrowEdge, pointers[0].tip, mark.label, mark.label) > 0.055,
                                   "hour arrow passes between the outside minute labels at \(time.digitalText)")
                        }
                    }
                    expect(hypot(pointers[0].badge.x - pointers[1].badge.x, pointers[0].badge.y - pointers[1].badge.y) > 0.2,
                           "number badges remain separate at \(time.digitalText)")
                }
            }
        }
        for hand in ClockInk.allCases.map(\.hex) + [0x000000, 0xFFFFFF, 0xFFFF00] {
            for face in ClockFace.allCases.map(\.hex) {
                let guide = ClockColorContrast.hourGuideHex(hand: hand, face: face)
                expect(ClockColorContrast.ratio(guide, face) >= 3,
                       "hour return cue remains visible on light, colored and black faces")
                expect(guide != hand, "hour return cue differs from the real hand")
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

    static func testFlightArrivals() {
        let forward = DinoFlightArrivalWork(departure: .init(hour: 8, minute: 15), durationMinutes: 240,
                                            offsetMinutes: 120, arrival: .init(hour: 14, minute: 15))
        expect(forward.combinedMinutes == 360, "duration and a later zone become one shift")
        expect(forward.differenceLine(language: "nl") == "4 uur + 2 uur = 6 uur", "Dutch flight sum adds duration and zone first")
        expect(forward.arrivalLine(language: "nl") == "08:15 + 6 uur = 14:15", "Dutch flight sum then adds that shift to the departure")
        expect(forward.differenceLine(language: "en") == "4 h + 2 h = 6 h", "English flight sum adds duration and zone first")
        expect(forward.arrivalLine(language: "en") == "08:15 + 6 h = 14:15", "English flight sum then adds that shift to the departure")
        let backward = DinoFlightArrivalWork(departure: .init(hour: 14), durationMinutes: 300,
                                             offsetMinutes: -180, arrival: .init(hour: 16))
        expect(backward.differenceLine(language: "nl") == "5 uur − 3 uur = 2 uur", "a negative zone is subtracted from the duration")
        expect(backward.arrivalLine(language: "nl") == "14:00 + 2 uur = 16:00", "the remaining shift is added to the departure")
        let sameZone = DinoFlightArrivalWork(departure: .init(hour: 9, minute: 30), durationMinutes: 150,
                                             offsetMinutes: 0, arrival: .init(hour: 12))
        expect(sameZone.arrivalLine(language: "nl") == "09:30 + 2 uur 30 min = 12:00", "one zone uses the duration as the only shift")
        expect(forward.walkMinutes(step: 15) == [60, 120, 180, 240, 300, 360], "a whole-hour shift counts one hour at a time")
        expect(sameZone.walkMinutes(step: 30) == [60, 120, 150], "half hours add the leftover thirty minutes in one step")
        expect(sameZone.walkMinutes(step: 5) == [60, 120, 125, 130, 135, 140, 145, 150],
               "five-minute questions add a fifteen-minute remainder in steps of five")
        expect(sameZone.walkMinutes(step: 15) == [60, 120, 135, 150], "quarter hours add the remainder a quarter at a time")
        let removed = DinoFlightArrivalWork(departure: .init(hour: 10), durationMinutes: 60,
                                            offsetMinutes: -180, arrival: .init(hour: 8))
        expect(removed.combinedMinutes == -120 && removed.walkMinutes(step: 60) == [-60, -120], "time comes off one hour at a time")
        expect(DinoExpandedQuestions.flightDurationMinutes(offsetMinutes: 240, minuteStep: 5, extraSteps: 0) == 360,
               "a four-hour zone change needs at least a six-hour flight")
        expect(DinoTimeWords.hourDifference(2, language: "nl") == "+2 uur" &&
               DinoTimeWords.hourDifference(-1, language: "en") == "−1 h", "the ticket states a signed hour difference")
        expect(ClockTime(hour: 22, minute: 30).adding(minutes: 150 + 2 * 60) == ClockTime(hour: 3), "flight plus zone crosses midnight")

        for family in DinoPracticeTime.allCases {
            var generator = DinoPracticeGenerator(configuration: .init(time: family, order: .specific(.flightArrival)), seed: 18)
            var positive = false, negative = false
            for index in 0..<120 {
                let q = generator.next(index: index, difficultyForKind: { _ in .challenge })
                let shift = q.durationMinutes + q.offsetMinutes
                expect(q.relatedTimes[0].adding(minutes: shift) == q.target, "departure, duration and zone determine the arrival")
                expect(q.options.count == 4 && Set(q.options).count == 4 && q.options.contains(q.target), "four unique flight choices include the arrival")
                expect(q.options.allSatisfy { family.minutes.contains($0.minute) }, "flight choices keep the selected minute family")
                if q.difficulty == .introduction {
                    expect(q.offsetMinutes == 0, "introductory flights keep the same time zone")
                } else {
                    expect((120...240).contains(abs(q.offsetMinutes)) && q.offsetMinutes.isMultiple(of: 30), "challenging flights state a whole-hour difference")
                    expect(q.durationMinutes >= abs(q.offsetMinutes) + 120, "the flight is at least two hours longer than the zone change")
                    let forgotten = q.relatedTimes[0].adding(minutes: q.durationMinutes)
                    expect(q.options.contains(forgotten), "forgetting the time zone remains one of the choices")
                    positive = positive || q.offsetMinutes > 0
                    negative = negative || q.offsetMinutes < 0
                    let work = DinoFlightArrivalWork(departure: q.relatedTimes[0], durationMinutes: q.durationMinutes,
                                                     offsetMinutes: q.offsetMinutes, arrival: q.target)
                    expect(work.afterDuration.adding(minutes: q.offsetMinutes) == q.target, "the example sum reaches the arrival")
                }
            }
            if family.minuteStep < 30 {
                expect(positive && negative, "harder flights use both earlier and later zones")
            }
        }
    }

    static func testMinutesBetweenQuestions() {
        let calculations: [(ClockTime, ClockTime, Int, Int, Bool)] = [
            (.init(hour: 1), .init(hour: 3), 2, 0, false),
            (.init(hour: 5, minute: 15), .init(hour: 7, minute: 45), 2, 30, false),
            (.init(hour: 5, minute: 45), .init(hour: 7, minute: 15), 1, 30, true),
            (.init(hour: 10, minute: 55), .init(hour: 11, minute: 5), 0, 10, true),
            (.init(hour: 0, minute: 59), .init(hour: 1), 0, 1, true),
            (.init(hour: 8, minute: 10), .init(hour: 8, minute: 40), 0, 30, false)
        ]
        for (start, end, hours, minutes, borrows) in calculations {
            let difference = DinoMinuteDifference(start, end)
            expect(difference.earlier == start && difference.later == end, "subtraction keeps the highest time first")
            expect(difference.hours == hours && difference.minutes == minutes, "worked subtraction preserves hours and minutes")
            expect(difference.borrowsHour == borrows, "worked subtraction identifies a borrowed hour")
            expect(difference.totalMinutes == end.minutesOfDay - start.minutesOfDay, "converting remaining hours and minutes gives the exact interval")
            expect(DinoMinuteDifference(end, start) == difference, "the worked sum orders both inputs chronologically")
        }
        let example = ClockQuestion(id: 0, kind: .minutesBetween, target: ClockTime(hour: 3), options: [],
                                    activity: nil, companionClocks: [],
                                    relatedTimes: [ClockTime(hour: 1), ClockTime(hour: 3)],
                                    durationMinutes: 120, answer: .duration(120))
        expect(AnswerValidator.isCorrect(.duration(120), for: example), "one to three o'clock is 120 minutes")
        expect(!AnswerValidator.isCorrect(.duration(2), for: example), "hours are not accepted as a minute total")
        expect(DinoTimeWords.minutes(120, language: "nl") == "120 minuten", "whole hours remain expressed in minutes")
        expect(DinoTimeWords.minutes(1, language: "nl") == "1 minuut", "Dutch minute singular")
        expect(DinoTimeWords.minutes(1, language: "en") == "1 minute", "English minute singular")
        expect(DinoTimeWords.minutes(75, language: "en") == "75 minutes", "English minute totals")
        for family in DinoPracticeTime.allCases {
            var generator = DinoPracticeGenerator(configuration: .init(time: family, order: .specific(.minutesBetween)), seed: 21)
            var crossedHour = false
            for index in 0..<200 {
                let q = generator.next(index: index, difficultyForKind: { _ in .challenge })
                expect(q.relatedTimes.count == 2, "minute difference has exactly two endpoints")
                let start = q.relatedTimes[0], end = q.relatedTimes[1]
                let elapsed = end.minutesOfDay - start.minutesOfDay
                expect((1...180).contains(elapsed), "minute differences run forward within the same day")
                expect(q.target == end && q.durationMinutes == elapsed, "displayed clocks determine the minute total")
                expect(q.relatedTimes.allSatisfy { family.minutes.contains($0.minute) }, "both endpoints follow the selected minute family")
                expect(q.expectedAnswer == .duration(elapsed), "minute totals use duration validation")
                let calculation = DinoMinuteDifference(start, end)
                expect(calculation.totalMinutes == elapsed && (0..<60).contains(calculation.minutes), "every worked example converts the correct remaining time")
                expect(q.responses.count == 4 && Set(q.responses).count == 4, "four distinct minute totals")
                expect(q.responses.filter { AnswerValidator.isCorrect($0, for: q) }.count == 1, "exactly one correct minute total")
                expect(q.responses.allSatisfy { if case .duration(let m) = $0 { return m > 0 }; return false }, "every choice is a positive number of minutes")
                crossedHour = crossedHour || start.hour != end.hour
            }
            expect(crossedHour, "minute differences include hour changes for every time family")
        }
    }

    static func testClockArithmetic() {
        let sketch = DinoClockArithmetic(start: ClockTime(hour: 0, minute: 2), durationMinutes: 5, adding: false)
        expect(sketch.difference == ClockTime(hour: 0, minute: 5), "the duration is written as a time of day")
        expect(sketch.minutes.sums.map(\.equation) == ["2 − 5 = −3", "−3 + 60 = 57"], "minutes borrow through the same digit")
        expect(sketch.hours.sums.map(\.equation) == ["0 − 0 = 0", "0 − 1 = −1", "−1 + 24 = 23"], "midnight reuses the hour that fell short")
        expect(sketch.minutes.sums[1].reusesFirstTerm && sketch.hours.sums[1].reusesFirstTerm, "each second sum starts from the first result")
        expect(sketch.result == ClockTime(hour: 23, minute: 57) && sketch.crossesMidnight, "the two results form the new time")

        let borrow = DinoClockArithmetic(start: ClockTime(hour: 10, minute: 2), durationMinutes: 5, adding: false)
        expect(borrow.hours.sums.map(\.equation) == ["10 − 0 = 10", "10 − 1 = 9"] && borrow.minutes.sums.count == 2,
               "a minute borrow keeps a matching hour step, even through zero")
        expect(borrow.result == ClockTime(hour: 9, minute: 57), "borrowed minutes land on the previous hour")

        let plainAdd = DinoClockArithmetic(start: ClockTime(hour: 10, minute: 20), durationMinutes: 5, adding: true)
        expect(plainAdd.hours.sums.isEmpty && plainAdd.hours.passthrough == 10, "an unchanged hour is not written as a sum")
        expect(plainAdd.minutes.sums.map(\.equation) == ["20 + 5 = 25"], "only the minute sum is shown")
        expect(plainAdd.result == ClockTime(hour: 10, minute: 25), "the kept hour and the new minutes form the time")

        let carry = DinoClockArithmetic(start: ClockTime(hour: 10, minute: 50), durationMinutes: 20, adding: true)
        expect(carry.minutes.sums.map(\.equation) == ["50 + 20 = 70", "70 − 60 = 10"], "extra minutes continue in a second sum")
        expect(carry.hours.sums.map(\.equation) == ["10 + 0 = 10", "10 + 1 = 11"], "the carried hour follows the unchanged hours")
        expect(carry.result == ClockTime(hour: 11, minute: 10), "carried minutes become the next hour")

        let both = DinoClockArithmetic(start: ClockTime(hour: 23, minute: 30), durationMinutes: 90, adding: true)
        expect(both.hours.sums.map(\.equation) == ["23 + 1 = 24", "24 + 1 = 25", "25 − 24 = 1"], "midnight follows the hour and the carried hour separately")
        expect(both.minutes.sums.map(\.equation) == ["30 + 30 = 60", "60 − 60 = 0"], "a full hour of minutes is reduced beside the first sum")
        expect(both.result == ClockTime(hour: 1) && both.crossesMidnight, "both corrections agree on the new time")

        let earlier = DinoClockArithmetic(start: ClockTime(hour: 3, minute: 10), durationMinutes: 90, adding: false)
        expect(earlier.hours.sums.map(\.equation) == ["3 − 1 = 2", "2 − 1 = 1"], "the borrowed hour reuses the hour sum")
        expect(earlier.minutes.sums[0].equation == "10 − 30 = −20" && earlier.result == ClockTime(hour: 1, minute: 40),
               "hours and minutes stay tied to the same duration")

        let wholeHour = DinoClockArithmetic(start: ClockTime(hour: 10), durationMinutes: 60, adding: false)
        expect(wholeHour.minutes.sums.isEmpty && wholeHour.minutes.passthrough == 0, "unchanged minutes are not a sum")
        expect(wholeHour.hours.sums.map(\.equation) == ["10 − 1 = 9"] && wholeHour.result == ClockTime(hour: 9),
               "a whole hour only changes the hour column")

        for hour in 0..<24 {
            for minute in [0, 2, 10, 30, 50, 59] {
                for duration in [1, 15, 59, 60, 61, 90, 120, 240] {
                    for adding in [true, false] {
                        let start = ClockTime(hour: hour, minute: minute)
                        let work = DinoClockArithmetic(start: start, durationMinutes: duration, adding: adding)
                        let signed = adding ? duration : -duration
                        expect(work.difference == ClockTime(hour: duration / 60, minute: duration % 60), "the difference uses 00:00")
                        expect(work.result == start.adding(minutes: signed), "the column results are the new time")
                        expect(work.hours.sums.count <= 3 && work.minutes.sums.count <= 2, "each column stays a short stack of sums")
                        expect(work.hours.sums.isEmpty == (work.hours.passthrough != nil), "a quiet hour is not also a sum")
                        expect(work.minutes.sums.isEmpty == (work.minutes.passthrough != nil), "quiet minutes are not also a sum")
                        for column in [work.hours, work.minutes] {
                            for (index, sum) in column.sums.enumerated() {
                                let zeros = sum.terms.dropFirst().filter { $0 == 0 }
                                let balancingZero = column.sums.count > 1 && index == 0 && zeros == [0]
                                expect(zeros.isEmpty || balancingZero, "only a carried hour may pass through zero")
                                if index > 0 {
                                    expect(sum.reusesFirstTerm && sum.terms[0] == column.sums[index - 1].result,
                                           "the second sum starts with the same digit")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    static func testPractice() {
        expect(DinoPracticeQuestion.allCases.count == 20, "practice contains twenty distinct question types")
        expect(DinoPracticeQuestion.chooseAnalog.number == 1 && DinoPracticeQuestion.chooseDigital.number == 2,
               "practice starts with recognizing and reading a clock")
        expect([DinoPracticeQuestion.trueFalse, .readDigital, .spokenTime].allSatisfy {
            $0.number < DinoPracticeQuestion.sayTime.number
        }, "recognizing time phrases precedes constructing them")
        expect(DinoPracticeQuestion.setDigital.number < DinoPracticeQuestion.setAnalog.number,
               "setting digits precedes independently positioning hands")
        expect(DinoPracticeQuestion.read24Hour.number < DinoPracticeQuestion.dayPart.number
               && DinoPracticeQuestion.dayPart.number < DinoPracticeQuestion.match.number
               && DinoPracticeQuestion.match.number < DinoPracticeQuestion.sortTimes.number,
               "24-hour notation and day parts precede connecting and comparing times")
        expect(DinoPracticeQuestion.advanceAnalog.number + 1 == DinoPracticeQuestion.addTime.number
               && DinoPracticeQuestion.addTime.number + 1 == DinoPracticeQuestion.subtractTime.number,
               "moving hands introduces arithmetic, with later and earlier times consecutive")
        expect(DinoPracticeQuestion.subtractTime.number + 1 == DinoPracticeQuestion.minutesBetween.number
               && DinoPracticeQuestion.minutesBetween.number < DinoPracticeQuestion.timeSequence.number,
               "time differences follow addition and subtraction before repeated time steps")
        expect(DinoPracticeQuestion.timeSequence.number < DinoPracticeQuestion.daySchedule.number
               && DinoPracticeQuestion.daySchedule.number < DinoPracticeQuestion.timeZone.number
               && DinoPracticeQuestion.timeZone.number < DinoPracticeQuestion.flightArrival.number,
               "combined durations and time zones are taught before flights combine them")
        expect(DinoPracticeQuestion(rawValue: "schoolEnd") == nil && ClockQuestionKind(rawValue: "schoolEnd") == nil,
               "the duplicate lesson exercise is retired from practice and levels")
        expect(DinoPracticeQuestion(rawValue: "elapsedTime") == nil && ClockQuestionKind(rawValue: "elapsedTime") == nil,
               "the duplicate elapsed-time exercise is retired from practice and levels")
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
                    let optionMinutes = question.kind == .readDigital
                        ? Array(stride(from: 0, to: 60, by: min(15, time.minuteStep))) : time.minutes
                    expect(question.options.allSatisfy { optionMinutes.contains($0.minute) }, "practice options use the selected time family or time-reading quarter-hour alternatives")
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
        let config = DinoPracticeConfiguration(time: .minutes, order: .ascending)
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
            expect(session.selectedOrder.isEmpty && session.pairSelections.isEmpty && session.spokenChoices.isEmpty, "board selections reset for every question")
        }
        expect(session.practiceCorrect == 500, "practice keeps a correct running count")
        expect(player.profile == original && store.load() == original && uploads == 0, "practice and help never save progress or upload level scores")
    }


    static func wrongAnswer(for q: ClockQuestion) -> ClockAnswer {
        switch q.expectedAnswer {
        case .time(let time):
            var wrong = time.adding(minutes: 60)
            if [.setAnalog, .setDigital, .advanceAnalog].contains(q.kind) {
                let initial = q.kind == .advanceAnalog ? q.relatedTimes[0]
                    : ClockTime(hour: q.target.hour % 12 == 0 ? 1 : 12)
                if wrong.hour % 12 == initial.hour % 12 && wrong.minute == initial.minute {
                    wrong = wrong.adding(minutes: 60)
                }
            }
            return .time(wrong)
        case .duration(let minutes): return .duration(minutes + 1)
        case .truth(let truth): return .truth(!truth)
        case .dayPart(let part): return .dayPart(DinoDayPart.allCases.first { $0 != part }!)
        case .ordering(let times): return .ordering(Array(times.reversed()))
        case .pairs(let times): return .pairs(Array(times.reversed()))
        case .spoken(let spoken):
            var ids = spoken.choiceIDs
            if let prompt = q.spokenPrompt, let hourSlot = prompt.slots.firstIndex(where: { $0.id == "hour" }),
               let other = prompt.slots[hourSlot].choices.first(where: { $0.id != ids[hourSlot] }) {
                ids[hourSlot] = other.id
            } else if let first = ids.indices.first {
                ids[first] = ids[first] == SpokenTimeChoice.emptyID ? "wrong" : SpokenTimeChoice.emptyID
            }
            return .spoken(SpokenTimeAnswer(choiceIDs: ids))
        }
    }

    static func testAnalogSettingExamples() {
        expect(DinoAnalogAdvanceExample.enteredMinutes(from: ClockTime(hour: 2), to: ClockTime(hour: 2, minute: 20)) == 20,
               "the entered deviation is how far the player moved the clock forward")
        expect(DinoAnalogAdvanceExample.enteredMinutes(from: ClockTime(hour: 2, minute: 10), to: ClockTime(hour: 2)) == -10,
               "moving the hands backward is a negative deviation")
        expect(DinoAnalogAdvanceExample.enteredMinutes(from: ClockTime(hour: 12, minute: 50), to: ClockTime(hour: 1, minute: 5)) == 15,
               "the entered deviation follows the hands across twelve")
        expect(DinoPracticeTime.analogHandStep(30) == 15 && DinoPracticeTime.half.analogHandStep == 15,
               "half-hour practice turns the analog hand by quarters")
        expect(DinoPracticeTime.analogHandStep(10) == 5 && DinoPracticeTime.tenMinutes.analogHandStep == 5,
               "ten-minute practice turns the analog hand five minutes at a time")
        for family in DinoPracticeTime.allCases where family != .half && family != .tenMinutes {
            expect(family.analogHandStep == family.minuteStep, "analog hand step matches \(family.rawValue)")
        }
        for family in [DinoPracticeTime.half, .tenMinutes] {
            let question = DinoExpandedQuestions.example(kind: .advanceAnalog, time: family)
            let script = DinoAnalogAdvanceExample(question: question, minuteStep: family.analogHandStep)
            expect(question.durationMinutes.isMultiple(of: family.analogHandStep), "finer analog steps still reach the family turn")
            var clock = script.start
            var movingMinutes = false
            for action in script.actions {
                switch action {
                case .selectMinutes(let minutes): movingMinutes = minutes
                case .adjust: clock = script.applying(action, to: clock, adjustingMinutes: movingMinutes)
                case .confirm: expect(clock == script.target, "quarter and five-minute taps finish the forward clock")
                }
            }
        }
        for step in [1, 5, 10, 15, 30, 60] {
            for hour in 1...12 {
                for minute in stride(from: 0, to: 60, by: step) {
                    let target = ClockTime(hour: hour, minute: minute)
                    for clockwise in [false, true] {
                        let example = DinoAnalogSettingExample(target: target, minuteStep: step, clockwise: clockwise)
                        expect(example.initialTime.hour == ClockTime.shiftedHour(hour, by: 6), "example starts on the opposite hour")
                        expect((example.initialHourAngle - target.hourAngle).truncatingRemainder(dividingBy: 360) == 180,
                               "introductory hour hand is exactly opposite, including the minute offset")
                        if step < 60 {
                            let difference = (example.initialTime.minuteAngle - target.minuteAngle + 360).truncatingRemainder(dividingBy: 360)
                            expect(difference == 180, "introductory minute hand is exactly opposite")
                        }
                        var time = example.initialTime
                        var minutes = false
                        var hourAngle = example.initialHourAngle
                        var minuteAngle = example.initialMinuteAngle
                        for (index, action) in example.actions.enumerated() {
                            switch action {
                            case .selectMinutes(let selected):
                                expect(step < 60, "whole-hour examples never select the minute hand")
                                minutes = selected
                            case .adjust(let direction):
                                let next = example.applying(action, to: time, adjustingMinutes: minutes)
                                expect(next == (minutes ? time.shiftingMinutes(by: direction * step)
                                                : ClockTime(hour: ClockTime.shiftedHour(time.hour, by: direction), minute: time.minute)),
                                       "each demonstrated tap uses the live clock arithmetic")
                                time = next
                                let nextHour = DinoAnalogSettingExample.continuingAngle(next.hourAngle, from: hourAngle, direction: direction)
                                let nextMinute = DinoAnalogSettingExample.continuingAngle(next.minuteAngle, from: minuteAngle, direction: direction)
                                expect(abs(nextHour - hourAngle) <= 30 && abs(nextMinute - minuteAngle) <= 180,
                                       "each tap follows the nearby clock tick, including the transition through twelve")
                                if !minutes { expect(abs(nextHour - hourAngle - Double(direction) * 30) < 0.001,
                                                     "hour taps always animate in the direction of the shown button") }
                                hourAngle = nextHour
                                minuteAngle = nextMinute
                            case .confirm:
                                expect(index == example.actions.count - 1 && time == target, "confirm is last and always submits the correct time")
                            }
                            if step == 60 { expect(time.minute == 0, "whole-hour demonstration leaves the minute hand on twelve") }
                        }
                        expect(time == target, "all analog examples finish at the fixed digital target in either direction")
                    }
                }
            }
        }
        let player = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
        for family in DinoPracticeTime.allCases {
            let configuration = DinoPracticeConfiguration(time: family, order: .specific(.setAnalog))
            let session = DinoSession(level: configuration.level, player: player, practice: configuration)
            expect(session.instructionKey == "dino.question.setAnalog", "question nine uses one instruction for every time family")
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
        expect(DinoDemonstrationExamples.time(index: 6, minutes: DinoPracticeTime.tenMinutes.minutes) == ClockTime(hour: 4), "ten-minute examples include whole hours")
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
                    case .addTime, .advanceAnalog, .timeSequence:
                        expect(q.relatedTimes.last!.adding(minutes: q.durationMinutes) == q.target, "example addition and sequence answers agree with their context")
                    case .flightArrival:
                        expect(q.relatedTimes[0].adding(minutes: q.durationMinutes + q.offsetMinutes) == q.target, "example flight adds duration and the stated zone difference")
                        expect(q.offsetMinutes == 0, "introductory flight examples teach duration in a single time zone")
                        if q.offsetMinutes != 0 {
                            let work = DinoFlightArrivalWork(departure: q.relatedTimes[0], durationMinutes: q.durationMinutes,
                                                             offsetMinutes: q.offsetMinutes, arrival: q.target)
                            expect(work.afterDuration.adding(minutes: q.offsetMinutes) == q.target, "worked flight sum reaches the shown arrival")
                        }
                    case .subtractTime:
                        expect(q.relatedTimes[0].adding(minutes: -q.durationMinutes) == q.target, "example subtraction answer agrees with its context")
                    case .timeZone:
                        expect(q.relatedTimes[0].adding(minutes: q.offsetMinutes) == q.target, "example zone answer agrees with the stated offset")
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
        var rng = SeededGenerator(seed: 20261028)
        var hasSameDayPart = false
        for time in DinoPracticeTime.allCases {
            for difficulty in DinoQuestionDifficulty.allCases {
                for hour in 0..<24 {
                    for minute in time.minutes {
                        let target = ClockTime(hour: hour, minute: minute)
                        let question = DinoExpandedQuestions.generate(kind: .read24Hour, minutes: time.minutes,
                            minuteStep: time.minuteStep, index: 0, previousTarget: nil, preferredTarget: target,
                            difficulty: difficulty, using: &rng)
                        expect(question.target == target && question.options.count == difficulty.optionCount,
                               "24-hour choices retain the requested time and the full answer grid")
                        expect(question.options.filter { $0 == target }.count == 1,
                               "24-hour choices keep exactly one correct answer")
                        let wrong = question.options.filter { $0 != target }
                        for language in ["nl", "en"] {
                            let correctTime = DinoTimeWords.time(target, language: language)
                            expect(wrong.allSatisfy { DinoTimeWords.time($0, language: language) != correctTime },
                                   "24-hour alternatives to \(target.digitalText) have different time words in \(language)")
                        }
                        hasSameDayPart = hasSameDayPart || wrong.contains {
                            DinoDayPart(hour: $0.hour) == DinoDayPart(hour: target.hour)
                        }
                    }
                }
            }
        }
        expect(hasSameDayPart, "24-hour alternatives may still share the correct answer's day part")
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

    static func testDayPartSchedule() {
        let school = DinoDayPartSchedule(night: 23, morning: 7, afternoon: 12, evening: 18)
        expect(school.isValid && school.summary == "23–07 · 07–12 · 12–18 · 18–23", "a school timetable keeps clock order")
        expect(DinoDayPartSchedule(storageKey: school.storageKey) == school, "a timetable stores and reloads")
        expect(DinoDayPartSchedule(storageKey: "0,0,12,18") == nil && DinoDayPartSchedule(storageKey: "nope") == nil,
               "overlapping or unreadable timetables are rejected")
        let standardLine = DinoDayPartSchedule.standard.timeline()
        expect(standardLine.map(\.part) == DinoDayPart.allCases && standardLine.map(\.start) == [0, 6, 12, 18] && standardLine.map(\.end) == [6, 12, 18, 24],
               "the built-in line is four equal stretches")
        let wrapping = DinoDayPartSchedule(night: 22, morning: 6, afternoon: 12, evening: 18)
        let wrappedLine = wrapping.timeline()
        expect(wrappedLine.map(\.part) == [.night, .morning, .afternoon, .evening, .night]
               && wrappedLine.map(\.start) == [0, 6, 12, 18, 22]
               && wrappedLine.map(\.end) == [6, 12, 18, 22, 24],
               "night that starts before midnight appears at both ends of the day line")
        expect(wrapping.endClock(of: .evening) == 22 && wrapping.clockText(endOf: .night) == "06:00", "wrapped night ends in the morning")
        expect(school.validStarts(for: .morning).contains(7) && !school.validStarts(for: .morning).contains(12),
               "a part cannot shrink to nothing or take over the next part")
        for (hour, part) in [(23, DinoDayPart.night), (0, .night), (6, .night), (7, .morning), (11, .morning), (12, .afternoon), (17, .afternoon), (18, .evening), (22, .evening)] {
            expect(school.part(at: hour) == part, "school timetable owns every listed hour")
            expect(DinoTimeWords.dayPartSuffix(ClockTime(hour: hour), language: "nl", schedule: school) ==
                   (part == .night ? "’s nachts" : part == .morning ? "’s ochtends" : part == .afternoon ? "’s middags" : "’s avonds"),
                   "spoken day parts follow the school timetable")
        }
        let example = DinoDemonstrationExamples.question(kind: .dayPart, minutes: [0], minuteStep: 60,
                                                         index: 3, previousTarget: nil, dayPartSchedule: school)
        expect(example.target.hour == 6 && example.expectedAnswer == .dayPart(.night),
               "the worked example uses the school timetable, including 06:00")
        var rng = SeededGenerator(seed: 20261021)
        let asked = DinoExpandedQuestions.generate(kind: .dayPart, minutes: [0], minuteStep: 60,
                                                   index: 0, previousTarget: nil, preferredTarget: ClockTime(hour: 22),
                                                   dayPartSchedule: school, using: &rng)
        expect(asked.target == ClockTime(hour: 22) && asked.expectedAnswer == .dayPart(.evening),
               "a chosen timetable can ask the hours the built-in one skips, and marks them with that timetable")
        var practice = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.dayPart)),
                                             seed: 20261021, dayPartSchedule: school)
        var sawBoundaryHour = false
        for index in 0..<80 {
            let question = practice.next(index: index)
            expect(question.expectedAnswer == .dayPart(school.part(at: question.target.hour)),
                   "practice marks each day-part question with the school timetable")
            if question.target.hour == 6 || question.target.hour >= 22 { sawBoundaryHour = true }
        }
        expect(sawBoundaryHour, "practice with a school timetable includes the previously skipped hours")
        let broken = InMemoryKeyValueStore(["dino.settings.dayParts": "0,0,12,18"])
        expect(DinoSettings(defaults: broken).dayPartSchedule == .standard, "a saved timetable that no longer fits falls back")
        let memory = InMemoryKeyValueStore()
        let player = DinoPlayer(store: DinoProgressStore(defaults: memory))
        let configuration = DinoPracticeConfiguration(time: .whole, order: .specific(.dayPart))
        let session = DinoSession(level: configuration.level, player: player, practice: configuration, dayPartSchedule: school)
        expect(session.dayPartSchedule == school && session.question.expectedAnswer == .dayPart(school.part(at: session.question.target.hour)),
               "a practice session keeps the timetable it started with")
    }

    static func testDayPartRejudge() {
        for hour in 0..<24 {
            for part in DinoDayPart.allCases {
                let timetable = timetableOwning(hour: hour, part: part)
                expect(timetable.isValid && timetable.part(at: hour) == part, "every hour can belong to every day part")
                expect(DinoDayPartSchedule.standard.edits(to: timetable) != nil, "the settings menus can reach that timetable")
            }
        }
        let player = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
        let configuration = DinoPracticeConfiguration(time: .whole, order: .specific(.dayPart))
        let learned = DinoSession(level: configuration.level, player: player, practice: configuration)
        for _ in 0..<3 {
            learned.submit(learned.question.expectedAnswer)
            learned.advance()
        }
        expect(player.questionDifficulty(kind: .dayPart, time: .whole) == .challenge, "three day-part answers reach the highest step")
        let missed = learned.question.responses.first { $0 != learned.question.expectedAnswer }!
        learned.submit(missed)
        expect(!learned.offersDayPartSettings, "the settings button waits until the question is closed")
        learned.showAnswer()
        expect(learned.offersDayPartSettings && learned.attempt.answers.last == false, "a closed miss offers the timetable")
        expect(player.questionDifficulty(kind: .dayPart, time: .whole) == .familiar, "the miss drops back a step")
        expect(player.practiceRecord(time: .whole, question: .dayPart) == DinoPracticeRecord(bestStreak: 3, questionsAnswered: 4, currentStreak: 0),
               "the miss breaks the streak without forgetting the earlier record")
        guard case .dayPart(let picked) = missed else { expect(false, "a day-part choice"); return }
        let corrected = timetableOwning(hour: learned.question.target.hour, part: picked)
        learned.rejudgeDayPart(using: corrected)
        expect(learned.attempt.answers.last == true && learned.correctFeedback && !learned.shouldAutoAdvance,
               "the first answer is right under the new timetable and waits for Next")
        expect(!learned.offersDayPartSettings && !learned.rejectedResponses.contains(missed), "the rescued choice is no longer marked wrong")
        expect(learned.question.expectedAnswer == .dayPart(picked), "the question now expects the first choice")
        expect(player.questionDifficulty(kind: .dayPart, time: .whole) == .challenge, "a rescued answer keeps the step earned before it")
        expect(player.practiceRecord(time: .whole, question: .dayPart) == DinoPracticeRecord(bestStreak: 4, questionsAnswered: 4, currentStreak: 4),
               "the rescued answer continues the streak it had interrupted")
        learned.rejudgeDayPart(using: corrected)
        expect(player.practiceRecord(time: .whole, question: .dayPart).questionsAnswered == 4, "closing the timetable twice does not score the answer again")
        learned.advance()
        expect(learned.dayPartSchedule == corrected && learned.question.expectedAnswer == .dayPart(corrected.part(at: learned.question.target.hour)),
               "the next question uses the timetable chosen during the miss")

        let fresh = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
        let retry = DinoSession(level: configuration.level, player: fresh, practice: configuration)
        let first = retry.question.responses.first { $0 != retry.question.expectedAnswer }!
        let second = retry.question.responses.first { $0 != retry.question.expectedAnswer && $0 != first }!
        retry.submit(first)
        retry.submit(second)
        retry.showAnswer()
        guard case .dayPart(let firstPart) = first else { expect(false, "a day-part choice"); return }
        let other = DinoDayPart.allCases.first { $0 != firstPart }!
        let stillWrong = timetableOwning(hour: retry.question.target.hour, part: other)
        retry.rejudgeDayPart(using: stillWrong)
        expect(retry.attempt.answers.last == false && retry.offersDayPartSettings && retry.dayPartSchedule == stillWrong,
               "a timetable that still excludes the first answer leaves the miss in place")
        expect(retry.question.expectedAnswer == .dayPart(stillWrong.part(at: retry.question.target.hour)), "the revealed answer follows the new timetable")
        expect(fresh.practiceRecord(time: .whole, question: .dayPart).currentStreak == 0, "a timetable that stays wrong keeps the broken streak")
        retry.rejudgeDayPart(using: timetableOwning(hour: retry.question.target.hour, part: firstPart))
        expect(retry.attempt.answers.last == true && !retry.rejectedResponses.contains(first) && retry.rejectedResponses.contains(second),
               "only the first answer is rescored; a later guess stays rejected")
        expect(fresh.practiceRecord(time: .whole, question: .dayPart) == DinoPracticeRecord(bestStreak: 1, questionsAnswered: 1, currentStreak: 1),
               "the first answer, rescued on a second visit, scores once")
    }

    private static func timetableOwning(hour: Int, part: DinoDayPart) -> DinoDayPartSchedule {
        let order = DinoDayPart.allCases
        let origin = order.firstIndex(of: part)!
        var starts = [Int](repeating: 0, count: 4)
        for offset in 0..<4 { starts[(origin + offset) % 4] = (hour + offset) % 24 }
        return DinoDayPartSchedule(night: starts[0], morning: starts[1], afternoon: starts[2], evening: starts[3])
    }

    static func testCapitalTimeZones() {
        let catalog = DinoTimeZoneJourney.capitals
        expect(Set(catalog.map(\.id)).count == catalog.count, "capital identifiers are unique")
        expect(catalog.allSatisfy { TimeZone(identifier: $0.timeZoneID) != nil }, "all capitals use valid IANA zones")
        expect(catalog.first { $0.countryCode == "TUR" }?.id == "ankara", "Turkey uses its capital Ankara")
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let today = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: Date())
        let shown = utc.dateComponents([.year, .month, .day, .hour], from: DinoTimeZoneJourney.referenceDate)
        expect(shown.year == today.year && shown.month == today.month && shown.day == today.day && shown.hour == Optional(12),
               "the map date and the city offset use noon UTC on today")
        expect(utc.component(.month, from: DinoTimeZoneJourney.atlasDate) == 1 &&
               utc.component(.day, from: DinoTimeZoneJourney.atlasDate) == 15,
               "simplified zone bands stay on the winter atlas date")
        expect(catalog.allSatisfy {
            TimeZone(identifier: $0.timeZoneID)!.secondsFromGMT(for: DinoTimeZoneJourney.referenceDate).isMultiple(of: 1_800)
        }, "every capital keeps a whole- or half-hour offset today")
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.setLocalizedDateFormatFromTemplate("dMMMM")
        formatter.locale = Locale(identifier: "nl_NL")
        expect(DinoTimeZoneJourney.displayedDate(language: "nl") == formatter.string(from: DinoTimeZoneJourney.referenceDate),
               "the Dutch map names today's date")
        formatter.locale = Locale(identifier: "en_GB")
        expect(DinoTimeZoneJourney.displayedDate(language: "en") == formatter.string(from: DinoTimeZoneJourney.referenceDate),
               "the English map names today's date")
        for language in ["nl", "en"] {
            for family in DinoPracticeTime.allCases {
                var generator = DinoPracticeGenerator(configuration: .init(time: family, order: .specific(.timeZone)), seed: 19, language: language)
                var seenDestinations = Set<String>()
                var crossesMidnight = false
                for index in 0..<250 {
                    let q = generator.next(index: index, difficultyForKind: { _ in .challenge })
                    guard let journey = q.timeZoneJourney else { fatalError("time-zone task needs two capitals") }
                    expect(journey.origin.id == (language == "nl" ? "amsterdam" : "london"), "chosen language determines the reference capital")
                    expect(journey.origin.countryCode != journey.destination.countryCode && q.offsetMinutes != 0, "two capitals always use different countries and time zones")
                    expect(q.offsetMinutes == journey.offsetMinutes, "map and question use the same real-world offset")
                    expect(q.relatedTimes[0].adding(minutes: journey.offsetMinutes) == q.target, "geographic time-zone calculation survives midnight")
                    let walked = journey.steps(from: q.relatedTimes[0])
                    expect(walked.map { abs($0.addedMinutes) } == stride(from: 0, to: abs(q.offsetMinutes), by: 60).map { min($0 + 60, abs(q.offsetMinutes)) } && walked.last?.time == q.target,
                           "the example counts +1, +2 until the new time and then stops")
                    expect(q.options.count == 4 && Set(q.options).count == 4 && q.options.contains(q.target), "four distinct answer choices include the correct time")
                    expect(q.options.allSatisfy { family.minutes.contains($0.minute) }, "time-zone choices retain the selected minute family")
                    switch q.difficulty {
                    case .introduction: expect(abs(q.offsetMinutes) == 60, "easy maps use a nearby one-hour difference")
                    case .familiar: expect(abs(q.offsetMinutes) <= 180, "medium maps keep regional hour differences")
                    case .challenge: expect(abs(q.offsetMinutes) >= 210, "hard maps include distant capitals")
                    }
                    for size in [CGSize(width: 230, height: 224), CGSize(width: 340, height: 252), CGSize(width: 760, height: 252)] {
                        let viewport = DinoTimeZoneViewport(journey: journey, size: size)
                        for capital in [journey.origin, journey.destination] {
                            let point = viewport.point(capital, size: size)
                            expect(point.x > 10 && point.x < size.width - 10 && point.y > 10 && point.y < size.height - 10,
                                   "automatic map crop keeps both points inside small examples and tablet maps")
                        }
                    }
                    seenDestinations.insert(journey.destination.id)
                    crossesMidnight = crossesMidnight || abs(q.target.minutesOfDay - q.relatedTimes[0].minutesOfDay) != abs(q.offsetMinutes)
                }
                expect(seenDestinations.count >= 4, "each language and difficulty offers varied familiar countries")
                expect(crossesMidnight, "each minute family covers a change of day")
            }
        }
        let origin = catalog.first { $0.id == "amsterdam" }!
        let nearby = DinoTimeZoneJourney(origin: origin, destination: catalog.first { $0.id == "london" }!)
        let distant = DinoTimeZoneJourney(origin: origin, destination: catalog.first { $0.id == "tokyo" }!)
        let size = CGSize(width: 340, height: 252)
        expect(DinoTimeZoneViewport(journey: distant, size: size).longitudeSpan > DinoTimeZoneViewport(journey: nearby, size: size).longitudeSpan * 3,
               "the atlas zooms out for an intercontinental journey")
        let wide = DinoTimeZoneViewport(journey: distant, size: size)
        let land = DinoTimeZoneLand.northernEdge(longitude: wide.longitude, span: wide.longitudeSpan)
        let north = wide.latitude + wide.latitudeSpan / 2
        expect(north <= land + wide.latitudeSpan * (8 / size.height) + 0.05,
               "a wide crop keeps the same shape and does not leave an empty band above the land")
        for reference in catalog.filter({ ["amsterdam", "london"].contains($0.id) }) {
            for destination in catalog where destination.id != reference.id {
                let journey = DinoTimeZoneJourney(origin: reference, destination: destination)
                for size in [CGSize(width: 230, height: 224), CGSize(width: 340, height: 252), CGSize(width: 760, height: 252),
                             CGSize(width: 600, height: 184), CGSize(width: 760, height: 184)] {
                    let viewport = DinoTimeZoneViewport(journey: journey, size: size)
                    let labels = DinoTimeZoneLabelLayout(origin: viewport.point(reference, size: size),
                                                        destination: viewport.point(destination, size: size), size: size,
                                                        offsetMinutes: journey.offsetMinutes)
                    let a = CGRect(x: labels.origin.x - labels.width / 2, y: labels.origin.y - 38, width: labels.width, height: 76)
                    let b = CGRect(x: labels.destination.x - labels.width / 2, y: labels.destination.y - 38, width: labels.width, height: 76)
                    expect(!a.intersects(b), "capital labels never overlap, including narrow worked examples")
                    for capital in [reference, destination] {
                        let point = viewport.point(capital, size: size)
                        expect(!a.insetBy(dx: -12, dy: -12).contains(point) && !b.insetBy(dx: -12, dy: -12).contains(point),
                               "city labels leave both geographic markers visible")
                    }
                    expect(CGRect(origin: .zero, size: size).contains(a) && CGRect(origin: .zero, size: size).contains(b),
                           "both city labels fit fully inside each map size")
                    if journey.offsetMinutes > 0 {
                        expect(b.minX >= a.maxX - 0.5, "a later city card sits to the right of the reference card")
                    } else if journey.offsetMinutes < 0 {
                        expect(a.minX >= b.maxX - 0.5, "an earlier city card sits to the left of the reference card")
                    }
                }
            }
        }
    }

    static func testDaySchedules() {
        let worked = DinoDaySchedule(start: .init(hour: 9, minute: 45), firstActivity: .drawing,
                                     firstMinutes: 40, breakMinutes: 15, secondActivity: .reading, secondMinutes: 35)
        expect(worked.firstEnd == ClockTime(hour: 10, minute: 25) && worked.secondStart == ClockTime(hour: 10, minute: 40),
               "the break starts after activity one and ends before activity two")
        expect(worked.end == ClockTime(hour: 11, minute: 15), "all three durations carry across the hour")
        for time in DinoPracticeTime.allCases {
            var generator = DinoPracticeGenerator(configuration: .init(time: time, order: .specific(.daySchedule)), seed: 20261016)
            var seenActivities = Set<DinoScheduleActivity>()
            for index in 0..<200 {
                let question = generator.next(index: index, difficultyForKind: { _ in .challenge })
                guard let schedule = question.daySchedule else { fatalError("day planning requires a schedule") }
                seenActivities.formUnion([schedule.firstActivity, schedule.secondActivity])
                expect(schedule.firstActivity != schedule.secondActivity, "every schedule has two different activities")
                expect(schedule.durations.allSatisfy { $0 > 0 && $0.isMultiple(of: time.minuteStep) },
                       "both activities and the break respect the selected difficulty")
                expect(schedule.start.minutesOfDay >= 6 * 60 && schedule.end.minutesOfDay <= 22 * 60 &&
                       schedule.start.minutesOfDay < schedule.end.minutesOfDay,
                       "the complete schedule stays within the same daytime")
                expect(schedule.end == question.target && question.relatedTimes == [schedule.start] &&
                       question.durationMinutes == schedule.totalMinutes, "the correct answer includes both activities and the break")
                expect(!AnswerValidator.isCorrect(schedule.firstEnd, for: question) &&
                       !AnswerValidator.isCorrect(schedule.start.adding(minutes: schedule.firstMinutes + schedule.secondMinutes), for: question),
                       "stopping after the first activity and forgetting the break are rejected")
                expect(question.options.count == 4 && Set(question.options).count == 4 && question.options.contains(schedule.end),
                       "the schedule offers four unique times with its answer exactly once")
            }
            expect(seenActivities == Set(DinoScheduleActivity.allCases), "day schedules vary their activities")
        }
    }

    static func testSpokenTime() {
        let dutch = SpokenTimeCatalog.language(code: "nl")
        let english = SpokenTimeCatalog.language(code: "en")
        expect(SpokenTimeCatalog.language(code: "fr").code == "nl", "an unknown language keeps the Dutch clock until it is added")
        expect(SpokenTimeCatalog.language(code: "en-GB").code == "en" && SpokenTimeCatalog.language(code: "EN").code == "en",
               "region codes use the registered language")
        let dutchPhrases = [
            (3, 0, "Drie uur"), (3, 5, "Vijf over drie"), (3, 10, "Tien over drie"), (3, 15, "Kwart over drie"),
            (3, 20, "Tien voor half vier"), (3, 25, "Vijf voor half vier"), (3, 30, "Half vier"),
            (3, 35, "Vijf over half vier"), (3, 40, "Tien over half vier"), (3, 45, "Kwart voor vier"),
            (3, 50, "Tien voor vier"), (3, 55, "Vijf voor vier"),
            (12, 0, "Twaalf uur"), (12, 30, "Half een"), (12, 35, "Vijf over half een"), (11, 45, "Kwart voor twaalf"),
            (8, 45, "Kwart voor negen")
        ]
        let englishPhrases = [
            (3, 0, "Three o\u{2019}clock"), (3, 5, "Five past three"), (3, 10, "Ten past three"),
            (3, 15, "Quarter past three"), (3, 20, "Twenty past three"), (3, 25, "Twenty-five past three"),
            (3, 30, "Half past three"), (3, 35, "Twenty-five to four"), (3, 40, "Twenty to four"),
            (3, 45, "Quarter to four"), (3, 50, "Ten to four"), (3, 55, "Five to four"),
            (12, 0, "Twelve o\u{2019}clock"), (12, 30, "Half past twelve"), (1, 30, "Half past one"),
            (12, 55, "Five to one"), (1, 20, "Twenty past one")
        ]
        for (hour, minute, phrase) in dutchPhrases {
            let got = spokenPhrase("nl", hour: hour, minute: minute)
            expect(got == phrase, "Dutch \(hour):\(minute) expected \(phrase), got \(got)")
        }
        for (hour, minute, phrase) in englishPhrases {
            let got = spokenPhrase("en", hour: hour, minute: minute)
            expect(got == phrase, "English \(hour):\(minute) expected \(phrase), got \(got)")
        }
        var rng = SeededGenerator(seed: 7)
        let quarterTo = dutch.prompt(for: ClockTime(hour: 8, minute: 45), using: &rng)
        let halfFour = english.prompt(for: ClockTime(hour: 3, minute: 20), using: &rng)
        expect(quarterTo.slots.map(\.id) == ["minutes", "direction", "half", "hour", "closing"], "Dutch keeps half as its own choice")
        expect(halfFour.slots.map(\.id) == ["minutes", "direction", "hour", "closing"], "English puts half with the minutes")
        expect(quarterTo.correct.choiceIDs == ["kwart", "voor", "-", "h9", "-"], "quarter to nine is checked by choice, not by the sentence")
        expect(halfFour.correct.choiceIDs == ["twenty", "past", "h3", "-"], "twenty past three does not borrow the Dutch half-hour form")
        expect(quarterTo.phrase(for: SpokenTimeAnswer(choiceIDs: ["tien", "voor", "half", "h9", "-"])) == "Tien voor half negen",
               "the sentence follows the words chosen so far")
        expect(quarterTo.phrase(for: SpokenTimeAnswer(choiceIDs: Array(repeating: "-", count: 5))) == "", "dashes add no words")
        for prompt in [quarterTo, halfFour] {
            let hour = prompt.slots.first { $0.id == "hour" }!
            expect(hour.choices.count == 3 && Set(hour.choices.map(\.id)).count == 3
                   && !hour.choices.contains { $0.id == SpokenTimeChoice.emptyID },
                   "the hour row offers three hours and no empty stone")
            for (slot, correct) in zip(prompt.slots, prompt.correct.choiceIDs) {
                expect(!slot.choices.contains { $0.id == SpokenTimeChoice.emptyID }, "empty rows have no stone")
                expect((1...3).contains(slot.choices.count), "every row shows at most three words")
                if correct != SpokenTimeChoice.emptyID {
                    expect(slot.choices.contains { $0.id == correct }, "every correct word is one of the choices")
                }
            }
        }
        expect(quarterTo.slots[0].choices.map(\.id) == ["vijf", "tien", "kwart"], "Dutch minutes stay the three real words")
        expect(halfFour.slots[0].choices.count == 3 && halfFour.slots[0].choices.contains { $0.id == "twenty" },
               "English minutes keep the right word and two alternatives")
        expect(quarterTo.slots.first { $0.id == "half" }!.choices.map(\.id) == ["half"], "half is only a stone when the row uses it")
        for seed in 0..<24 {
            var hourRng = SeededGenerator(seed: UInt64(seed))
            let five = dutch.prompt(for: ClockTime(hour: 5, minute: 0), using: &hourRng)
            let hours = five.slots.first { $0.id == "hour" }!.choices.map { Int($0.id.dropFirst())! }
            expect(hours == [3, 4, 5] || hours == [4, 5, 6] || hours == [5, 6, 7], "five o'clock offers a neighbouring hour, got \(hours)")
            var noonRng = SeededGenerator(seed: UInt64(seed))
            let noon = english.prompt(for: ClockTime(hour: 12, minute: 0), using: &noonRng)
            let aroundTwelve = noon.slots.first { $0.id == "hour" }!.choices.map(\.id)
            expect(aroundTwelve == ["h10", "h11", "h0"] || aroundTwelve == ["h11", "h0", "h1"] || aroundTwelve == ["h0", "h1", "h2"],
                   "twelve o'clock stays next to eleven and one")
        }
        var fiveRng = SeededGenerator(seed: 4)
        let five = dutch.prompt(for: ClockTime(hour: 5, minute: 0), using: &fiveRng)
        let fiveQuestion = spokenQuestion(prompt: five, time: ClockTime(hour: 5, minute: 0))
        let fromMinutes = SpokenTimeAnswer(choiceIDs: ["vijf", "-", "-", "-", "uur"])
        let fromBoth = SpokenTimeAnswer(choiceIDs: ["vijf", "-", "-", "h5", "uur"])
        expect(five.phrase(for: fromMinutes) == "Vijf uur" && five.phrase(for: fromBoth) == "Vijf uur",
               "a whole hour still reads as the hour when the same word is chosen twice")
        expect(AnswerValidator.isCorrect(.spoken(fromMinutes), for: fiveQuestion), "five plus uur says five o'clock")
        expect(AnswerValidator.isCorrect(.spoken(fromBoth), for: fiveQuestion), "saying five twice still says five o'clock")
        expect(!AnswerValidator.isCorrect(.spoken(SpokenTimeAnswer(choiceIDs: ["tien", "-", "-", "h5", "uur"])), for: fiveQuestion),
               "an extra different minute word is another time")
        expect(!AnswerValidator.isCorrect(.spoken(fromMinutes), for: spokenQuestion(prompt: quarterTo, time: ClockTime(hour: 8, minute: 45))),
               "the same words are not accepted once the clock leaves the whole hour")
        let almost = SpokenTimeAnswer(choiceIDs: ["kwart", "voor", "half", "h9", "-"])
        let question = spokenQuestion(prompt: quarterTo, time: ClockTime(hour: 8, minute: 45))
        expect(AnswerValidator.isCorrect(.spoken(quarterTo.correct), for: question), "the matching choices are correct")
        expect(!AnswerValidator.isCorrect(.spoken(almost), for: question), "adding half changes the time even when the other words match")
        expect(!AnswerValidator.isCorrect(.time(question.target), for: question), "a clock time is not a spoken answer")

        let player = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
        let config = DinoPracticeConfiguration(time: .quarter, order: .specific(.sayTime))
        let session = DinoSession(level: config.level, player: player, practice: config, example: question)
        for (index, id) in quarterTo.correct.choiceIDs.enumerated() where id != SpokenTimeChoice.emptyID {
            session.chooseSpoken(slot: index, choiceID: id)
        }
        session.chooseSpoken(slot: 0, choiceID: "kwart")
        expect(session.spokenChoices[0] == nil, "tapping the chosen stone clears that row")
        session.chooseSpoken(slot: 0, choiceID: "kwart")
        session.submit(.spoken(SpokenTimeAnswer(choiceIDs: quarterTo.correct.choiceIDs)))
        expect(session.correctFeedback && session.shouldAutoAdvance, "a complete spoken answer is checked immediately")
        session.chooseSpoken(slot: 0, choiceID: "-")
        expect(session.spokenChoices[0] == "kwart", "feedback locks the chosen words")

        let live = DinoSession(level: config.level, player: player, practice: config, language: "nl")
        let livePrompt = live.question.spokenPrompt!
        var wrongIDs = livePrompt.correct.choiceIDs
        let hourSlot = livePrompt.slots.firstIndex { $0.id == "hour" }!
        wrongIDs[hourSlot] = livePrompt.slots[hourSlot].choices.first { $0.id != wrongIDs[hourSlot] }!.id
        live.submit(.spoken(SpokenTimeAnswer(choiceIDs: wrongIDs)))
        expect(live.hasFeedback && !live.correctFeedback && !live.canRetry, "a wrong sentence finishes this question")
        live.advance()
        expect(live.question.id == 1 && live.spokenChoices.isEmpty && live.result == nil, "the next spoken question starts with no words selected")

        for time in DinoPracticeTime.allCases {
            for code in ["nl", "en"] {
                var generator = DinoPracticeGenerator(configuration: .init(time: time, order: .specific(.sayTime)), seed: 18, language: code)
                var previous: ClockTime?
                for index in 0..<40 {
                    let generated = generator.next(index: index)
                    let prompt = generated.spokenPrompt!
                    expect(generated.kind == .sayTime && generated.options.isEmpty, "saying the time has no clock choices")
                    expect((1...12).contains(generated.target.hour) && time.minutes.contains(generated.target.minute), "spoken questions use the selected minutes on a twelve-hour clock")
                    expect(generated.target != previous, "spoken questions do not repeat the previous clock")
                    expect(!prompt.phrase.isEmpty && AnswerValidator.isCorrect(generated.expectedAnswer, for: generated), "the generated sentence matches that clock")
                    expect(!AnswerValidator.isCorrect(wrongAnswer(for: generated), for: generated), "one changed word is rejected")
                    expect((prompt.slots.first { $0.id == "half" } != nil) == (code == "nl"), "only Dutch shows the half row")
                    expect(prompt.slots.allSatisfy { slot in
                        !slot.choices.contains { $0.id == SpokenTimeChoice.emptyID } && (1...3).contains(slot.choices.count)
                    }, "each spoken row shows at most three words and no empty stone")
                    let hourChoices = prompt.slots.first { $0.id == "hour" }!.choices.map { Int($0.id.dropFirst())! }
                    let named = prompt.correct.choiceIDs.compactMap { id -> Int? in
                        guard id.hasPrefix("h") else { return nil }
                        return Int(id.dropFirst())
                    }.first!
                    expect(hourChoices.count == 3 && hourChoices.contains(named)
                           && hourChoices[1] == (hourChoices[0] + 1) % 12
                           && hourChoices[2] == (hourChoices[1] + 1) % 12,
                           "hour stones stay on three neighbouring hours")
                    previous = generated.target
                }
            }
        }
    }

    static func spokenPhrase(_ code: String, hour: Int, minute: Int) -> String {
        var rng = SeededGenerator(seed: 1)
        return SpokenTimeCatalog.language(code: code).prompt(for: ClockTime(hour: hour, minute: minute), using: &rng).phrase
    }

    static func spokenQuestion(prompt: SpokenTimePrompt, time: ClockTime) -> ClockQuestion {
        var question = ClockQuestion(id: 0, kind: .sayTime, target: time, options: [], activity: nil, companionClocks: [])
        question.spokenPrompt = prompt
        question.answer = .spoken(prompt.correct)
        return question
    }

    static func testTimeReadingClock() {
        for language in ["nl", "en"] {
            for family in DinoPracticeTime.allCases {
                for difficulty in DinoQuestionDifficulty.allCases {
                    var rng = SeededGenerator(seed: 20261028)
                    for hour in [1, 4, 11, 12] {
                        for minute in family.minutes {
                            let target = ClockTime(hour: hour, minute: minute)
                            let question = DinoExpandedQuestions.generate(kind: .readDigital, minutes: family.minutes,
                                minuteStep: family.minuteStep, index: 0, previousTarget: nil,
                                preferredTarget: target, language: language, difficulty: difficulty, using: &rng)
                            expect(question.target == target, "time-reading targets keep the selected teaching grid")
                            expect(question.options.count == difficulty.optionCount && Set(question.options).count == question.options.count,
                                   "time reading has the required number of unique choices")
                            expect(question.options.allSatisfy { $0.hour == target.hour }, "every time-reading answer belongs to the displayed hour")
                            for (index, option) in question.options.enumerated() {
                                expect(question.options.dropFirst(index + 1).allSatisfy {
                                    let difference = abs($0.minute - option.minute)
                                    return min(difference, 60 - difference) >= 5
                                }, "wrong-answer markers have room to stay individually visible")
                            }
                            expect(question.options.filter { AnswerValidator.isCorrect($0, for: question) } == [target],
                                   "the analog time has exactly one correct description")
                            if family == .whole && difficulty != .introduction {
                                expect(Set(question.options.map(\.minute)) == [0, 15, 30, 45],
                                       "whole hours use quarter past, half past and quarter to as alternatives")
                            }
                            let phrase = DinoTimeWords.time(target, language: language)
                            expect(!phrase.contains(":"), "the teaching clock explains times entirely in words")
                        }
                    }
                }
            }
        }
        let dutch: [DinoTimeReading.Region] = [.whole, .past, .past, .past, .beforeHalf, .beforeHalf,
                                               .half, .afterHalf, .afterHalf, .to, .to, .to]
        let english: [DinoTimeReading.Region] = [.whole, .past, .past, .past, .past, .past,
                                                 .past, .to, .to, .to, .to, .to]
        for (language, expected) in [("nl", dutch), ("en", english)] {
            expect(stride(from: 0, to: 60, by: 5).map { DinoTimeReading.region(minute: $0, language: language) } == expected,
                   "the full example groups all twelve positions by the language's actual phrasing")
        }
        for (minute, region, phrase) in [
            (14, DinoTimeReading.Region.past, "14 minuten over twaalf"),
            (16, .beforeHalf, "14 minuten voor half een"), (29, .beforeHalf, "1 minuut voor half een"),
            (30, .half, "half een"), (31, .afterHalf, "1 minuut over half een"),
            (44, .afterHalf, "14 minuten over half een"), (46, .to, "14 minuten voor een")
        ] {
            expect(DinoTimeReading.region(minute: minute, language: "nl") == region,
                   "Dutch color boundaries also handle individual minutes")
            expect(DinoTimeWords.time(.init(hour: 12, minute: minute), language: "nl") == phrase,
                   "Dutch individual-minute wording follows the half-hour groups across twelve")
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
                var sawAdvanceCombination = false
                var sawAdvanceShort = false
                for index in 0..<150 {
                    let q = generator.next(index: index, difficultyForKind: { _ in .challenge })
                    expect(!AnswerValidator.isCorrect(wrongAnswer(for: q), for: q), "wrong typed answer rejected")
                    switch kind {
                    case .addTime, .advanceAnalog:
                        expect(q.relatedTimes[0].adding(minutes: q.durationMinutes) == q.target, "later-time arithmetic")
                        sawMidnight = sawMidnight || q.relatedTimes[0].minutesOfDay > q.target.minutesOfDay
                        if kind == .advanceAnalog {
                            let face = ClockTime(hour: q.target.hour % 12 == 0 ? 12 : q.target.hour % 12, minute: q.target.minute)
                            expect(AnswerValidator.isCorrect(face, for: q), "analog answers accept the matching 12-hour face")
                            expect((1...240).contains(q.durationMinutes) && q.durationMinutes.isMultiple(of: time.minuteStep),
                                   "forward turns stay within four hours and the selected minute family")
                            if time.minuteStep >= 60 {
                                expect(q.durationMinutes.isMultiple(of: 60), "whole-hour practice moves whole hours")
                            } else if q.durationMinutes < 60 {
                                sawAdvanceShort = true
                            } else if q.durationMinutes % 60 != 0 {
                                sawAdvanceCombination = true
                            }
                            let script = DinoAnalogAdvanceExample(question: q, minuteStep: time.minuteStep)
                            var clock = script.start
                            var movingMinutes = false
                            for action in script.actions {
                                switch action {
                                case .selectMinutes(let minutes): movingMinutes = minutes
                                case .adjust: clock = script.applying(action, to: clock, adjustingMinutes: movingMinutes)
                                case .confirm: expect(clock == script.target, "the example taps finish on the forward clock")
                                }
                            }
                        }
                    case .flightArrival:
                        let shift = q.durationMinutes + q.offsetMinutes
                        expect(q.relatedTimes[0].adding(minutes: shift) == q.target, "flight arrival adds duration and time zone")
                        expect((120...240).contains(abs(q.offsetMinutes)) && q.offsetMinutes.isMultiple(of: 30), "challenging flights combine durations and time zones in every family")
                        let linear = q.relatedTimes[0].minutesOfDay + shift
                        sawMidnight = sawMidnight || linear < 0 || linear >= 24 * 60
                    case .subtractTime:
                        expect(q.relatedTimes[0].adding(minutes: -q.durationMinutes) == q.target, "earlier-time arithmetic")
                        sawMidnight = sawMidnight || q.relatedTimes[0].minutesOfDay < q.target.minutesOfDay
                    case .timeSequence:
                        expect(q.relatedTimes.count == 3, "three terms in pattern")
                        let all = q.relatedTimes + [q.target]
                        for pair in zip(all, all.dropFirst()) {
                            expect(pair.0.adding(minutes: q.durationMinutes) == pair.1, "every sequence step is identical")
                        }
                    case .timeZone:
                        expect(q.relatedTimes[0].adding(minutes: q.offsetMinutes) == q.target, "explicit zone difference determines answer")
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
                if time == .whole && [.addTime, .advanceAnalog, .flightArrival, .subtractTime].contains(kind) {
                    expect(sawMidnight, "generated whole-hour arithmetic covers midnight: \(kind)")
                }
                if kind == .advanceAnalog && time.minuteStep < 60 {
                    expect(sawAdvanceCombination && sawAdvanceShort, "minute practice mixes hour combinations with shorter gaps")
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

    static func testCrystalMinerPatrols() {
        expect(CrystalMinerPatrol.routes.count == 4, "four cave workers")
        expect(CrystalMinerPatrol.routes.filter { $0.stops.last! - $0.stops.first! > 1000 }.count == 2,
               "two workers patrol the length of the cave")
        for route in CrystalMinerPatrol.routes {
            var previous = route.pose(at: 0)
            var down = false, up = false, miningStops = Set<Double>()
            for step in 1...Int(ceil(route.duration * 20)) {
                let pose = route.pose(at: Double(step) / 20)
                expect(pose.y.isFinite && pose.outward.isFinite && (0...1).contains(pose.outward),
                       "finite, bounded mining detour")
                expect((route.stops.first!...route.stops.last!).contains(pose.y), "patrol stays inside its cave route")
                expect(abs(pose.y - previous.y) <= route.speed / 20 + 0.00001 && abs(pose.outward - previous.outward) < 0.05,
                       "continuous walking, stopping and returning, including cycle boundaries")
                if let work = pose.work {
                    expect(!pose.walking && pose.outward == 1 && route.stops.contains(pose.y) && (0..<4.8).contains(work),
                           "pickaxe only swings while stopped at a mineral seam")
                    miningStops.insert(pose.y)
                }
                if pose.walking && pose.outward == 0 { if pose.upward { up = true } else { down = true } }
                previous = pose
            }
            expect(down && up && miningStops == Set(route.stops), "every stop is mined and each route is walked both ways")
            let a = route.pose(at: 13.125), b = route.pose(at: 13.125 + route.duration)
            expect(abs(a.y - b.y) < 0.00001 && abs(a.outward - b.outward) < 0.00001,
                   "a full patrol repeats without teleporting")
        }
    }

    static func testAnimation() {
        for world in 1...9 {
            let transition = DinoWorldTransition(after: world)
            expect(transition?.sourceLevel == world * 10 && transition?.destinationLevel == world * 10 + 1,
                   "world transitions leave the completed boss and land on the next world's first stone")
        }
        expect(DinoWorldTransition(after: 0) == nil && DinoWorldTransition(after: 10) == nil,
               "world transitions cannot leave the catalog or create a level 101")
        var previousJump = DinoAnimation.sample(.worldJump, elapsed: 0)
        var previousProgress = 0.0
        for step in 1...216 {
            let elapsed = Double(step) / 120
            let sample = DinoAnimation.sample(.worldJump, elapsed: elapsed)
            let progress = DinoAnimation.worldJumpProgress(elapsed: elapsed)
            expect(sample.angle >= previousJump.angle && sample.angle <= 360 && sample.angle - previousJump.angle < 6,
                   "the world salto completes one smooth forward rotation")
            expect(sample.height <= 0.00001 && abs(sample.height - previousJump.height) < 0.02,
                   "the world salto follows a continuous bounded arc")
            expect(progress >= previousProgress && progress <= 1 && progress - previousProgress < 0.02,
                   "the camera and map character move with continuous matching progress")
            if (0.20..<1.10).contains(elapsed) {
                expect(sample.pose.asset == "dino-world-jump-airborne", "one airborne illustration prevents flickering during the world salto")
            }
            let reduced = DinoAnimation.sample(.worldJump, elapsed: elapsed, reducedMotion: true)
            expect(reduced.pose.asset == "dino-idle" && reduced.angle == 0 && reduced.height == 0,
                   "reduced motion keeps the world transition character still")
            previousJump = sample; previousProgress = progress
        }
        expect(DinoAnimation.worldJumpProgress(elapsed: DinoAnimation.travelDelay(.worldJump)) == 0 &&
               DinoAnimation.worldJumpProgress(elapsed: DinoAnimation.travelDuration(.worldJump)) == 1,
               "the camera starts at takeoff and arrives exactly at landing")
        expect(previousJump.pose.asset == "dino-idle" && previousJump.angle == 360 && previousProgress == 1,
               "the world salto settles into the normal map pose")
        func opaqueFootline(_ asset: String) -> Double {
            let url = URL(fileURLWithPath: "Assets.xcassets/\(asset).imageset/\(asset).png")
            let image = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
            let width = image.width, height = image.height
            var bytes = [UInt8](repeating: 0, count: width * height * 4)
            bytes.withUnsafeMutableBytes { buffer in
                let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                        bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                        bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)!
                context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            }
            let last = (0..<height).reversed().first { y in
                (0..<width).contains { x in bytes[(y * width + x) * 4 + 3] > 200 }
            }!
            return Double(last + 1) / Double(height)
        }
        let idleFootline = opaqueFootline("dino-idle")
        var openingAssets: [String] = []
        var openingProgress = 0.0
        for step in 0...216 {
            let elapsed = Double(step) / 120
            let sample = DinoOpeningJump.sample(elapsed: elapsed)
            let progress = DinoOpeningJump.travelProgress(elapsed: elapsed)
            expect(progress >= openingProgress && progress <= 1 && progress - openingProgress < 0.02,
                   "opening flight moves continuously toward its saved stone")
            expect(sample.height <= 0 && sample.height >= -1 && abs(sample.angle) <= 5,
                   "opening has a bounded jump arc and subtle tilt")
            if elapsed <= DinoOpeningJump.takeoff || elapsed >= DinoOpeningJump.landing {
                expect(sample.height == 0, "anticipation and landing stay on their ground plane")
            }
            let reduced = DinoOpeningJump.sample(elapsed: elapsed, reducedMotion: true)
            expect(reduced.pose.asset == "dino-idle" && reduced.height == 0 && reduced.angle == 0,
                   "reduced motion uses a still opening character")
            if openingAssets.last != sample.pose.asset { openingAssets.append(sample.pose.asset) }
            openingProgress = progress
        }
        expect(openingAssets == DinoOpeningJump.assets + ["dino-idle"], "all eight supplied opening poses play once in order")
        expect(DinoOpeningJump.poseStarts.map { DinoOpeningJump.sample(elapsed: $0).pose.asset } == DinoOpeningJump.assets,
               "native contents keyframes use the same pose boundaries as the flight sampler")
        expect(zip(DinoOpeningJump.poseStarts, DinoOpeningJump.poseStarts.dropFirst()).allSatisfy { $0 < $1 }
               && DinoOpeningJump.poseStarts.last! < DinoOpeningJump.duration,
               "native pose key times are strictly ordered and leave time for recovery")
        expect(DinoOpeningJump.travelProgress(elapsed: DinoOpeningJump.takeoff) == 0 &&
               DinoOpeningJump.travelProgress(elapsed: DinoOpeningJump.landing) == 1,
               "opening leaves its logo only after the crouch and arrives before recovery")
        let flightDuration = DinoOpeningJump.landing - DinoOpeningJump.takeoff
        for fraction in [0.02, 0.25, 0.75, 0.98] {
            let elapsed = DinoOpeningJump.takeoff + flightDuration * fraction
            let speed = (DinoOpeningJump.travelProgress(elapsed: elapsed + 0.001) -
                         DinoOpeningJump.travelProgress(elapsed: elapsed)) / 0.001
            expect(abs(speed - 1 / flightDuration) < 0.0001,
                   "opening keeps its momentum through takeoff and contact instead of easing to a stop in the air")
        }
        expect(DinoOpeningJump.takeoff <= 0.16 && DinoOpeningJump.duration - DinoOpeningJump.landing <= 0.20,
               "opening's anticipation and contact recovery stay brisk")
        for elapsed in [0.0, 0.10, 0.78, 0.90] {
            let pose = DinoOpeningJump.sample(elapsed: elapsed).pose
            expect(abs(opaqueFootline(pose.asset) + pose.offsetY - idleFootline) < 1.0 / 1254,
                   "opening's planted poses share the map figure's actual painted foot line")
        }
        for elapsed in [0.0, 0.1, 1.2, 1.3, 1.5, 1.8] {
            let pose = DinoAnimation.sample(.worldJump, elapsed: elapsed).pose
            // Ground contact stays within one pixel of the bundled 768-pixel raster.
            expect(abs(opaqueFootline(pose.asset) + pose.offsetY - idleFootline) < 1.0 / 768,
                   "the actual sprite pixels share idle's foot line through takeoff, landing and recovery")
        }
        // Sparse image transitions cannot interrupt the complete turn or ground contact.
        var previous = DinoAnimation.sample(.backflip, elapsed: 0)
        for step in 1...222 {
            let sample = DinoAnimation.sample(.backflip, elapsed: Double(step) / 120)
            expect(sample.angle <= previous.angle && sample.angle >= -360, "single forward backflip")
            expect(abs(sample.angle - previous.angle) < 5, "no skipped rotation at pose changes")
            expect(abs(sample.height - previous.height) < 0.02, "continuous jump arc")
            expect(sample.height <= 0.00001, "bounded animation")
            if (0.20..<1.22).contains(Double(step) / 120) {
                expect(sample.pose.asset == "dino-result-backflip-airborne", "one stable airborne pose throughout the turn")
            }
            previous = sample
        }
        expect(previous.angle == -360 && abs(previous.height) < 0.00001, "lands upright at starting height")
        var previousTurn = DinoAnimation.sample(.pirouette, elapsed: 0)
        var turnAssets = [previousTurn.pose.asset]
        for step in 1...Int((DinoAnimation.duration(.pirouette) + 0.25) * 120) {
            let sample = DinoAnimation.sample(.pirouette, elapsed: Double(step) / 120)
            expect(sample.yaw >= previousTurn.yaw && sample.yaw <= 360 && sample.angle == 0,
                   "pirouette makes one upright turn around the vertical axis")
            expect(abs(sample.yaw - previousTurn.yaw) < 7 && abs(sample.height - previousTurn.height) < 0.02,
                   "pirouette follows a continuous turn and jump arc")
            expect(abs(sample.yaw - sample.pose.paintedYaw) <= 20.001 && sample.height <= 0.00001,
                   "each supplied view turns toward the next without flipping its sprite over")
            if sample.pose.asset != previousTurn.pose.asset {
                expect(abs(sample.pose.paintedYaw - previousTurn.pose.paintedYaw) <= 40,
                       "the generated in-betweens remove the former eighty-degree jump")
            }
            if turnAssets.last != sample.pose.asset { turnAssets.append(sample.pose.asset) }
            previousTurn = sample
        }
        let expectedTurns = (1...18).map { String(format: "dino-result-pirouette-%02d", $0) }
        expect(turnAssets == expectedTurns && DinoAnimation.pirouetteAssets == expectedTurns,
               "all eighteen poses play once and are preloaded, including the four generated in-betweens")
        expect(previousTurn.yaw == 360 && abs(previousTurn.height) < 0.00001 && previousTurn.pose.asset == "dino-result-pirouette-18",
               "pirouette lands in its stable final pose")
        expect(previousTurn.pose.offsetX == -0.012 && previousTurn.pose.offsetY == -0.029,
               "the revised pirouette preserves the exact previous final registration on the stone")
        let landing = DinoAnimation.sample(.pirouette, elapsed: DinoAnimation.travelDuration(.pirouette))
        expect(abs(landing.height) < 0.00001 && landing.pose.asset == "dino-result-pirouette-15",
               "the planted contact drawing begins exactly when the shared character reaches the stone")
        let beforeLanding = DinoAnimation.sample(.pirouette, elapsed: DinoAnimation.travelDuration(.pirouette) - 1.0 / 60)
        expect(beforeLanding.pose.asset == "dino-result-pirouette-14" && beforeLanding.height < 0,
               "the airborne reaching pose carries the descent until contact, without holding planted feet in the air")
        let preparation = [(0.0, "01"), (0.15, "02"), (0.26, "03")]
        for (time, pose) in preparation {
            let sample = DinoAnimation.sample(.pirouette, elapsed: DinoAnimation.leadIn(.pirouette) + time)
            expect(sample.height == 0 && sample.pose.asset == "dino-result-pirouette-\(pose)"
                   && DinoAnimation.leadIn(.pirouette) + time < DinoAnimation.travelDelay(.pirouette),
                   "each preparation pose is visible before the journey leaves the HUD portrait")
        }
        expect(DinoAnimation.travelDelay(.backflip) == 0.18 && DinoAnimation.travelDelay(.idle) == 0,
               "the backflip prepares in the portrait until takeoff while idle has no travel delay")
        expect(DinoAnimation.sample(.pirouette, elapsed: DinoAnimation.travelDuration(.pirouette) + 0.35).pose.asset == "dino-result-pirouette-17",
               "the arms lift through an intermediate pose before the unchanged celebration")
        expect(DinoAnimation.sample(.pirouette, elapsed: DinoAnimation.leadIn(.pirouette) - 0.01).pose.asset == "dino-result-pirouette-01",
               "the result transition gets a standing lead-in before the short preparation poses")
        for (frame, next) in zip(DinoAnimation.pirouetteFrames, DinoAnimation.pirouetteFrames.dropFirst()) {
            let hold = next.start - frame.start
            expect(hold >= 0.05 - 0.000001 && hold <= 0.18,
                   "every active drawing has readable exposure without a quarter-second freeze")
            let boundary = DinoAnimation.leadIn(.pirouette) + next.start
            expect(DinoAnimation.sample(.pirouette, elapsed: boundary).pose.asset == next.pose.asset
                   && DinoAnimation.sample(.pirouette, elapsed: boundary - 0.000001).pose.asset == frame.pose.asset,
                   "the per-pose exposure changes on its exact authored boundary")
            let epsilon = 0.00001
            let before = DinoAnimation.sample(.pirouette, elapsed: boundary - epsilon).yaw
            let at = DinoAnimation.sample(.pirouette, elapsed: boundary).yaw
            let after = DinoAnimation.sample(.pirouette, elapsed: boundary + epsilon).yaw
            expect(abs((at - before) / epsilon - (after - at) / epsilon) < 1,
                   "the continuous turn keeps its speed across exposure boundaries")
        }
        for fps in [30.0, 60.0] {
            for phase in [0.0, 0.25, 0.5, 0.75] {
                var seen = [String]()
                for step in 0...Int((DinoAnimation.duration(.pirouette) + 0.2) * fps) {
                    let pose = DinoAnimation.sample(.pirouette, elapsed: (Double(step) + phase) / fps).pose.asset
                    if seen.last != pose { seen.append(pose) }
                }
                expect(seen == expectedTurns, "all poses remain readable at 30 and 60 fps, regardless of refresh phase")
            }
        }
        let normal = DinoLevelCatalog.level(1)!
        for (correct, clip) in [(0, DinoAnimation.Clip.stumble), (1, .stumble), (2, .stumble), (3, .openingJump), (4, .pirouette), (5, .backflip)] {
            let result = DinoLevelResult(level: normal, correct: correct, stars: StarCalculator.stars(correct: correct), victory: .none)
            expect(result.animationClip == clip, "one star jumps, two stars pirouette and a perfect score backflips")
        }
        let boss = DinoLevelCatalog.level(10)!
        for (correct, stars, clip) in [(4, 0, DinoAnimation.Clip.stumble), (6, 1, .openingJump), (8, 2, .pirouette), (9, 2, .pirouette), (10, 3, .backflip)] {
            let result = DinoLevelResult(level: boss, correct: correct,
                                         stars: StarCalculator.stars(correct: correct, questionCount: 10), victory: .none)
            expect(result.stars == stars && result.animationClip == clip, "boss stars use the same reward animations")
        }
        let stumbleLeadIn = DinoAnimation.leadIn(.stumble)
        let stumbleLanding = DinoAnimation.travelDuration(.stumble)
        for step in 0..<36 {
            let waiting = DinoAnimation.sample(.stumble, elapsed: Double(step) / 100)
            expect(waiting.pose.asset == "dino-idle" && waiting.pose.offsetX == 0 && waiting.pose.offsetY == 0
                   && waiting.angle == 0 && waiting.scaleX == 1 && waiting.scaleY == 1 && waiting.previousPose == nil,
                   "the face, colors and portrait camera remain exactly idle until the fall actually starts")
        }
        expect((0.28...0.34).contains(DinoAnimation.stumblePushStart - DinoAnimation.stumbleLowest),
               "Dino is visibly motionless on the stone before attempting to rise")
        expect((0.17...0.22).contains(DinoAnimation.stumbleHandRelease - DinoAnimation.stumbleBraceEnd),
               "the arms carry a brisk supported push without a slow-motion hold")
        let motionFrames = DinoAnimation.stumbleFrames
        expect((0.45...0.55).contains(motionFrames.last!.start - DinoAnimation.stumblePushStart),
               "the complete rise takes about half a second after the motionless rest")
        let resting = DinoStumbleMotion.sample(at: DinoAnimation.stumbleLowest)!
        for step in 0...29 {
            let still = DinoStumbleMotion.sample(at: DinoAnimation.stumbleLowest + Double(step) / 100)!
            expect(still.drawing.asset == "dino-result-fall-06" && still.points == resting.points
                   && still.drawingVertices == resting.drawingVertices,
                   "the entire collapsed figure really stops, including its face, hands and tail")
        }
        let braced = DinoStumbleMotion.sample(at: DinoAnimation.stumbleBraceEnd)!
        let pushed = DinoStumbleMotion.sample(at: DinoAnimation.stumbleHandRelease)!
        for step in 0...40 {
            let progress = Double(step) / 40
            let push = DinoStumbleMotion.sample(at: DinoAnimation.stumbleBraceEnd
                + progress * (DinoAnimation.stumbleHandRelease - DinoAnimation.stumbleBraceEnd))!
            expect(push.supportsWeight && push.drawing.asset == "dino-result-fall-07" && push.palms == braced.palms,
                   "one painting and exactly planted palms carry the whole weight-bearing push")
        }
        expect(pushed.points[0].y < braced.points[0].y - 0.08 && pushed.points[5].y < braced.points[5].y - 0.04,
               "the head and shoulders rise substantially above the fixed hands")
        expect(DinoAnimation.duration(.stumble) == stumbleLeadIn + motionFrames.last!.start,
               "playback includes the complete supported push, hand release and standing recovery")
        let palms = DinoStumbleMotion.sample(at: DinoAnimation.stumbleLanding)!
        let face = DinoStumbleMotion.sample(at: DinoAnimation.stumbleFaceContact)!
        let low = DinoStumbleMotion.sample(at: DinoAnimation.stumbleLowest)!
        expect(face.from.asset == "dino-result-fall-05" && low.from.asset == "dino-result-fall-06"
               && face.points[2].y > 0.89 && face.points[4].y > 0.94
               && face.points[0].y > palms.points[0].y + 0.06,
               "after the palms land the muzzle and chin visibly sink down to the stone")
        expect(low.points[7].y > face.points[7].y + 0.08,
               "the hips collapse fully instead of stopping in the old push-up pose")
        for (frame, next) in zip(motionFrames, motionFrames.dropFirst()) {
            let early = DinoStumbleMotion.sample(at: frame.start + (next.start - frame.start) * 0.2)!
            let late = DinoStumbleMotion.sample(at: frame.start + (next.start - frame.start) * 0.8)!
            if frame.start == DinoAnimation.stumbleLowest {
                expect(early.points == late.points, "the intentional rest is an actual held body")
            } else {
                expect(zip(early.points, late.points).contains { hypot($0.x - $1.x, $0.y - $1.y) > 0.002 },
                       "active intervals contain continuous body movement")
            }
            for (vertex, source) in zip(early.drawingVertices, DinoStumbleMotion.grid) {
                expect(vertex.x.isFinite && vertex.y.isFinite && source.x.isFinite,
                       "all interpolated mesh coordinates remain finite")
            }
        }
        for frame in motionFrames.dropFirst().dropLast() {
            let epsilon = 0.00001
            let before = DinoStumbleMotion.sample(at: frame.start - epsilon)!.points
            let at = DinoStumbleMotion.sample(at: frame.start)!.points
            let after = DinoStumbleMotion.sample(at: frame.start + epsilon)!.points
            for index in at.indices {
                let incoming = CGPoint(x: (at[index].x - before[index].x) / epsilon,
                                       y: (at[index].y - before[index].y) / epsilon)
                let outgoing = CGPoint(x: (after[index].x - at[index].x) / epsilon,
                                       y: (after[index].y - at[index].y) / epsilon)
                expect(hypot(incoming.x - outgoing.x, incoming.y - outgoing.y) < 0.02,
                       "body landmarks keep continuous speed across painted poses")
            }
        }
        expect(stumbleLanding == stumbleLeadIn + DinoAnimation.stumbleLanding
               && DinoAnimation.travelDelay(.stumble) == stumbleLeadIn + DinoAnimation.stumbleTakeoff,
               "the fall starts in the portrait and contacts the stone on the same clock as the painted hands")
        let contact = DinoAnimation.sample(.stumble, elapsed: stumbleLanding)
        expect(contact.pose.asset == "dino-result-fall-04" && contact.previousPose == nil && contact.height == 0 && contact.angle == 0,
               "the hands catch the fall at contact without an airborne planted pose or a ghost of the standing figure")
        for frame in DinoAnimation.stumbleFrames {
            expect(abs(opaqueFootline(frame.pose.asset) + frame.pose.offsetY - idleFootline) < 1.0 / 768,
                   "every fall and push-up drawing shares the same opaque contact line on the stone")
        }
        for fps in [30.0, 60.0] {
            for phase in [0.0, 0.25, 0.5, 0.75] {
                var seen = [String]()
                for step in 0...Int((DinoAnimation.duration(.stumble) + 0.3) * fps) {
                    let time = (Double(step) + phase) / fps
                    let sample = DinoAnimation.sample(.stumble, elapsed: time)
                    if seen.last != sample.pose.asset { seen.append(sample.pose.asset) }
                    expect(sample.height == 0 && sample.yaw == 0 && abs(sample.angle) <= 3
                           && (0...1).contains(sample.poseBlend),
                           "the fall descends without a celebratory jump, spin or invalid blend")
                    if let morph = sample.morph {
                        let vertices = morph.drawingVertices
                        for triangle in DinoStumbleMotion.triangles {
                            let a = vertices[triangle.0], b = vertices[triangle.1], c = vertices[triangle.2]
                            expect((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x) > 0,
                                   "visible body interpolation never folds or inverts a mesh triangle")
                        }
                        expect(morph.points.suffix(5).allSatisfy { abs($0.y - idleFootline) < 1e-8 },
                               "the continuous recovery keeps its ground controls planted")
                    }
                    if time >= stumbleLanding {
                        expect(sample.angle == 0, "Dino pushes up with his contact line fixed after landing")
                    }
                }
                let expected = motionFrames.map { $0.pose.asset }.reduce(into: [String]()) { assets, asset in
                    if assets.last != asset { assets.append(asset) }
                }
                expect(seen == expected,
                       "the exact idle face leads into the continuous recovery at both refresh rates")
            }
        }
        expect(DinoAnimation.stumbleAssets.allSatisfy { DinoAnimation.spriteAssets.contains($0) },
               "all fall drawings prepare the player's chosen colors before the animation")
        let jumpLeadIn = DinoAnimation.leadIn(.openingJump)
        expect(DinoAnimation.travelDelay(.openingJump) == jumpLeadIn + DinoOpeningJump.takeoff
               && DinoAnimation.travelDuration(.openingJump) == jumpLeadIn + DinoOpeningJump.landing
               && DinoAnimation.duration(.openingJump) == jumpLeadIn + DinoOpeningJump.duration,
               "one-star travel, poses and recovery share the opening jump's timing")
        for (time, asset) in zip(DinoOpeningJump.poseStarts, DinoOpeningJump.assets) {
            let sample = DinoAnimation.sample(.openingJump, elapsed: jumpLeadIn + time)
            expect(sample.pose.asset == asset && DinoAnimation.spriteAssets.contains(asset),
                   "one star reuses every original jump pose at its exact boundary and prepares its chosen colors")
        }
        let jumpLanding = DinoAnimation.sample(.openingJump, elapsed: DinoAnimation.travelDuration(.openingJump))
        expect(jumpLanding.pose.asset == "dino-opening-jump-07" && jumpLanding.height == 0,
               "one-star contact pose is planted exactly when the companion reaches the stone")
        for fps in [30.0, 60.0] {
            for phase in [0.0, 0.25, 0.5, 0.75] {
                var seen = [String]()
                for step in 0...Int((DinoAnimation.duration(.openingJump) + 0.1) * fps) {
                    let sample = DinoAnimation.sample(.openingJump, elapsed: (Double(step) + phase) / fps)
                    expect((-0.280001...0).contains(sample.height) && abs(sample.angle) <= 5 && sample.yaw == 0,
                           "the portrait jump stays in a modest arc without a flip or turn")
                    if seen.last != sample.pose.asset { seen.append(sample.pose.asset) }
                }
                expect(seen == DinoOpeningJump.assets + ["dino-idle"],
                       "one-star playback shows all eight opening poses once and settles into idle at 30 and 60 fps")
            }
        }
        for (clip, asset) in [(DinoAnimation.Clip.backflip, "dino-result-backflip-recover"), (.pirouette, "dino-result-pirouette-18"),
                               (.stumble, "dino-result-fall-10"),
                               (.openingJump, "dino-idle"),
                               (.thumbsUp, DinoAnimation.correctAnswerStillAsset), (.wrongAnswer, DinoAnimation.wrongAnswerAssets[0])] {
            for step in 0...180 {
                let reduced = DinoAnimation.sample(clip, elapsed: Double(step) / 120, reducedMotion: true)
                expect(reduced.height == 0 && reduced.angle == 0 && reduced.yaw == 0 && reduced.scaleX == 1
                       && reduced.scaleY == 1 && reduced.pose.asset == asset && reduced.headAngle == 0 && reduced.headHeight == 0,
                       "reduced motion holds the same clear expression completely still")
            }
        }
        let applauseAssets = ["dino-idle"] + (1...6).map { String(format: "dino-answer-clap-%02d", $0) } + ["dino-idle"]
        expect(DinoAnimation.correctAnswerAssets == applauseAssets, "correct answers share idle at both ends of the six clap drawings")
        for fps in [30.0, 60.0] {
            for phase in [0.0, 0.25, 0.5, 0.75] {
                var seen = [String]()
                for step in 0...Int(ceil(DinoAnimation.duration(.thumbsUp) * fps)) {
                    let reaction = DinoAnimation.sample(.thumbsUp, elapsed: (Double(step) + phase) / fps)
                    if seen.last != reaction.pose.asset { seen.append(reaction.pose.asset) }
                    expect(reaction.angle == 0 && reaction.height == 0 && reaction.scaleX == 1 && reaction.scaleY == 1,
                           "the drawings carry the claps without the former cheering bounce")
                }
                expect(seen == applauseAssets,
                       "every clap drawing plays in order at 30 and 60 fps, then returns to idle")
            }
        }
        for (index, start) in DinoAnimation.correctAnswerFrameStarts.enumerated() {
            expect(DinoAnimation.sample(.thumbsUp, elapsed: start).pose.asset == applauseAssets[index],
                   "each applause drawing starts at its authored time")
            if index > 0 {
                expect(DinoAnimation.sample(.thumbsUp, elapsed: start - 0.000001).pose.asset == applauseAssets[index - 1],
                       "applause never skips a drawing at a frame boundary")
            }
        }
        var headPeaks = 0
        var beforeHead = DinoAnimation.sample(.thumbsUp, elapsed: 0)
        var previousHead = beforeHead
        for step in 1...Int(ceil((DinoAnimation.duration(.thumbsUp) + 0.1) * 600)) {
            let current = DinoAnimation.sample(.thumbsUp, elapsed: Double(step) / 600)
            expect((0...1.80001).contains(current.headAngle) && (0...0.006001).contains(current.headHeight),
                   "applause keeps the head motion small inside the anchored portrait")
            expect(abs(current.headAngle - previousHead.headAngle) < 0.035
                   && abs(current.headHeight - previousHead.headHeight) < 0.00012,
                   "head motion remains continuous across every clap drawing and the return to idle")
            if previousHead.headAngle > beforeHead.headAngle && previousHead.headAngle > current.headAngle { headPeaks += 1 }
            beforeHead = previousHead; previousHead = current
        }
        expect(headPeaks == 2, "applause makes exactly two distinct head nods before settling")
        for (contact, asset) in zip(DinoAnimation.correctAnswerClapContacts, [applauseAssets[2], applauseAssets[5]]) {
            let sample = DinoAnimation.sample(.thumbsUp, elapsed: contact)
            expect(sample.pose.asset == asset && sample.poseBlend > 0.999 && sample.headAngle > 1.79,
                   "each nod peaks when the supplied palms have fully met")
        }
        for time in [0.0, DinoAnimation.duration(.thumbsUp), DinoAnimation.correctAnswerDelay] {
            let sample = DinoAnimation.sample(.thumbsUp, elapsed: time)
            expect(sample.headAngle == 0 && sample.headHeight == 0, "applause starts and finishes at the exact resting head position")
        }
        for asset in applauseAssets {
            expect(DinoAnimation.spriteAssets.contains(asset)
                   && FileManager.default.fileExists(atPath: "Assets.xcassets/\(asset).imageset/\(asset).png")
                   && (asset == "dino-idle" || DinoAvatarMask.spriteRegions(for: asset) != nil),
                   "every applause drawing is available, preloaded and supports personal colors")
        }
        for asset in applauseAssets.dropFirst().dropLast() {
            let url = URL(fileURLWithPath: "Assets.xcassets/\(asset).imageset/\(asset).png")
            let source = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
            let colored = DinoSpriteColorRenderer.recolored(source, appearance: DinoAppearance(body: 0xFF1493), asset: asset)!
            let body = DinoSpriteColorRenderer.applauseBody(colored, original: source, asset: asset)!
            let before = [UInt8](colored.dataProvider!.data! as Data)
            let after = [UInt8](body.dataProvider!.data! as Data)
            let accents = DinoAvatarMask.spriteRegions(for: asset)?.decorations
            var headRemoved = true, bodyPreserved = true, fingertips = 0, removedAccents = 0
            for y in 0..<body.height {
                for x in 0..<body.width {
                    let i = y * body.bytesPerRow + x * 4
                    let px = Double(x) / Double(body.width), py = Double(y) / Double(body.height)
                    let inAccent = accents?.contains(CGPoint(x: px, y: py)) == true
                    if py < 0.35 { headRemoved = headRemoved && after[i + 3] == 0 }
                    if py > 0.55 && !inAccent {
                        bodyPreserved = bodyPreserved && (0...3).allSatisfy { before[i + $0] == after[i + $0] }
                    }
                    if inAccent, before[i + 3] > 50,
                       Double(before[i]) > Double(before[i + 1]) * 0.92,
                       Double(before[i + 1]) > Double(before[i + 2]) * 1.15 {
                        expect(after[i + 3] == 0, "\(asset) removes the painted yellow clap marks, including their soft edges")
                        removedAccents += 1
                    }
                    if (0.44..<0.51).contains(py), after[i + 3] > 220 { fingertips += 1 }
                }
            }
            expect(headRemoved, "\(asset) cannot expose a shifting second head behind the fixed idle head")
            expect(bodyPreserved && fingertips > 100, "\(asset) keeps the supplied hands, complete fingertips and personalized torso")
            expect(removedAccents > 100, "\(asset) replaces the baked-in clap accents with animated ripples")
        }
        let recovered = DinoAnimation.sample(.thumbsUp, elapsed: DinoAnimation.duration(.thumbsUp))
        expect(recovered.pose.asset == "dino-idle" && recovered.pose.offsetX == 0 && recovered.pose.offsetY == 0,
               "applause finishes at the original idle placement before the next question")
        for clip in [DinoAnimation.Clip.wrongAnswer] {
            let asset = DinoAnimation.wrongAnswerAssets[0]
            var seen: [String] = []
            var movingSamples = 0
            var previous = DinoAnimation.sample(clip, elapsed: 0)
            var minAngle = 0.0, maxAngle = 0.0, highest = 0.0
            for step in 0...600 {
                let t = Double(step) / 600
                let reaction = DinoAnimation.sample(clip, elapsed: t)
                if seen.last != reaction.pose.asset { seen.append(reaction.pose.asset) }
                expect(abs(reaction.angle) <= 3.2 && abs(reaction.height) <= 0.032
                       && (1...1.011).contains(reaction.scaleX) && (0.974...1).contains(reaction.scaleY),
                       "answer motion stays subtle inside the fixed portrait")
                expect(abs(reaction.angle - previous.angle) < 0.13
                       && abs(reaction.height - previous.height) < 0.0004
                       && abs(reaction.scaleX - previous.scaleX) < 0.002
                       && abs(reaction.scaleY - previous.scaleY) < 0.002,
                       "the gesture moves continuously through anticipation, emphasis and recovery")
                if reaction.angle != previous.angle || reaction.height != previous.height || reaction.scaleY != previous.scaleY {
                    movingSamples += 1
                }
                minAngle = min(minAngle, reaction.angle); maxAngle = max(maxAngle, reaction.angle)
                highest = min(highest, reaction.height)
                if t == 0 || t >= DinoAnimation.duration(clip) {
                    expect(reaction.pose.asset == "dino-idle" && reaction.pose.offsetX == 0 && reaction.pose.offsetY == 0
                           && reaction.angle == 0 && reaction.height == 0 && reaction.scaleX == 1 && reaction.scaleY == 1,
                           "start and finish use the exact original idle image and placement")
                }
                previous = reaction
            }
            expect(seen == ["dino-idle", asset, "dino-idle"],
                   "one held expression carries the movement, with just entry and exit image changes")
            expect(movingSamples > 300, "the held pose remains animated between image changes")
            expect(minAngle < -1 && maxAngle > 1, "wrong feedback makes one readable left/right shake")
            expect(FileManager.default.fileExists(atPath: "Assets.xcassets/\(asset).imageset/\(asset).png")
                   && DinoAvatarMask.spriteRegions(for: asset) != nil,
                   "the selected supplied artwork retains its personal-color mask")
        }
        expect(DinoAnimation.duration(.thumbsUp) < DinoAnimation.correctAnswerDelay && DinoAnimation.correctAnswerDelay <= 1.25,
               "both readable claps finish before advancing to the next question")
    }

    static func testPlausibleChoices() {
        func dial(_ a: ClockTime, _ b: ClockTime, twelve: Bool) -> Int {
            let span = twelve ? 720 : 1440
            let left = twelve ? (a.hour % 12) * 60 + a.minute : a.minutesOfDay
            let right = twelve ? (b.hour % 12) * 60 + b.minute : b.minutesOfDay
            let delta = abs(left - right)
            return min(delta, span - delta)
        }
        func usesTwelveHourFace(_ kind: ClockQuestionKind) -> Bool {
            ![.read24Hour, .sortTimes, .addTime, .subtractTime, .timeSequence, .flightArrival,
              .daySchedule, .timeZone, .dayPart, .minutesBetween].contains(kind)
        }
        func acceptable(_ wrong: ClockTime, question: ClockQuestion, step: Int) -> Bool {
            let twelve = usesTwelveHourFace(question.kind)
            if dial(wrong, question.target, twelve: twelve) <= 180 { return true }
            if question.kind == .read24Hour {
                let twin = ClockTime(hour: question.target.hour + 12, minute: question.target.minute)
                if dial(wrong, twin, twelve: false) <= 60 { return true }
            }
            if let schedule = question.daySchedule {
                let end = schedule.end
                if [schedule.firstEnd, schedule.secondStart, schedule.start,
                    end.adding(minutes: -schedule.breakMinutes), end.adding(minutes: -schedule.firstMinutes),
                    end.adding(minutes: step), end.adding(minutes: -step),
                    end.adding(minutes: 60), end.adding(minutes: -60)].contains(wrong) { return true }
            }
            if question.kind == .timeZone {
                let zone = [question.relatedTimes[0], question.target.adding(minutes: -2 * question.offsetMinutes),
                            question.target.adding(minutes: 60), question.target.adding(minutes: -60)]
                if zone.contains(wrong) { return true }
            }
            if [.addTime, .subtractTime, .timeSequence, .flightArrival].contains(question.kind),
               let shown = question.relatedTimes.first {
                let change: Int
                switch question.kind {
                case .subtractTime: change = -question.durationMinutes
                case .flightArrival: change = question.durationMinutes + question.offsetMinutes
                default: change = question.durationMinutes
                }
                let hourPart = (change / 60) * 60
                let named = [shown, shown.adding(minutes: -change), shown.adding(minutes: change * 2),
                             shown.adding(minutes: hourPart), shown.adding(minutes: change - hourPart),
                             question.target.adding(minutes: change * 2), question.target.adding(minutes: -change * 2),
                             question.target.adding(minutes: -question.offsetMinutes),
                             question.target.adding(minutes: question.offsetMinutes),
                             question.target.adding(minutes: question.offsetMinutes >= 0 ? 60 : -60)]
                if named.contains(wrong) { return true }
            }
            return false
        }

        for time in DinoPracticeTime.allCases {
            for type in DinoPracticeQuestion.allCases {
                for difficulty in DinoQuestionDifficulty.allCases {
                    var generator = DinoPracticeGenerator(configuration: .init(time: time, order: .specific(type)), seed: 77)
                    for index in 0..<16 {
                        let question = generator.next(index: index, difficultyForKind: { _ in difficulty })
                        let step = time.minuteStep
                        let twelve = usesTwelveHourFace(question.kind)
                        if question.kind == .trueFalse, let statement = question.statement, statement != question.target {
                            expect(acceptable(statement, question: question, step: step),
                                   "\(type) \(time) \(difficulty) false statement \(statement.digitalText) is not a plausible misreading of \(question.target.digitalText)")
                        }
                        if question.kind == .minutesBetween {
                            let elapsed = question.durationMinutes
                            let wrong = question.responses.compactMap { answer -> Int? in
                                if case .duration(let minutes) = answer, minutes != elapsed { return minutes }
                                return nil
                            }
                            let start = question.relatedTimes[0]
                            let minuteGap = abs(start.minute - question.target.minute)
                            let hourGap = abs(start.hour - question.target.hour) * 60
                            expect(wrong.allSatisfy { value in
                                let delta = abs(value - elapsed)
                                return delta <= max(120, step * 3) || value == minuteGap || value == hourGap || value == elapsed % 60
                            }, "\(type) \(time) minute totals stray from \(elapsed): \(wrong)")
                            if wrong.count >= 3 {
                                expect(wrong.contains { abs($0 - elapsed) <= step * 2 },
                                       "\(type) \(time) keeps a near minute total among \(wrong)")
                            }
                            continue
                        }
                        let wrongTimes = (question.options + (question.kind == .match ? question.companionClocks : []))
                            .filter { $0 != question.target }
                        for wrong in wrongTimes where question.kind != .dayPart {
                            expect(acceptable(wrong, question: question, step: step),
                                   "\(type) \(time) \(difficulty) alternative \(wrong.digitalText) is not a plausible confusion for \(question.target.digitalText)")
                        }
                        let choiceTimes = question.options.filter { $0 != question.target }
                        if choiceTimes.count >= 3 && (question.kind.usesOptions || question.kind == .sortTimes) {
                            let close = max(60, step)
                            expect(choiceTimes.contains { dial($0, question.target, twelve: twelve) <= close },
                                   "\(type) \(time) \(difficulty) alternatives \(choiceTimes.map(\.digitalText)) include no nearby trap for \(question.target.digitalText)")
                        }
                    }
                }
            }
        }

        var rng = SeededGenerator(seed: 5)
        let firstLevel = DinoQuestionGenerator.generate(level: DinoLevelCatalog.level(1)!, using: &rng)
        for question in firstLevel where question.kind == .chooseAnalog {
            let wrong = question.options.filter { $0 != question.target }
            expect(wrong.count == 1 && wrong[0].minute == 0, "the first level offers one whole-hour alternative")
            expect(dial(wrong[0], question.target, twelve: true) == 60,
                   "level 1's alternative is a neighboring hour of \(question.target.digitalText), not \(wrong[0].digitalText)")
        }
    }

    static func testQuestions() {
        expect(DinoLevelCatalog.levels.count == 100, "100 levels")
        var observedKinds = Set<ClockQuestionKind>()
        for seed in 0..<100 {
            for level in DinoLevelCatalog.levels.filter({ $0.worldID == 1 }) {
                var rng = SeededGenerator(seed: UInt64(seed))
                let questions = DinoQuestionGenerator.generate(level: level, attempt: seed % 3, using: &rng)
                expect(questions.count == level.questionCount, "question count")
                expect(Set(questions.map(\.id)).count == questions.count, "unique IDs")
                for (index, q) in questions.enumerated() {
                    let recipe = level.recipe(at: index)
                    observedKinds.insert(q.kind)
                    expect((0...23).contains(q.target.hour) && q.target.minute == 0, "jungle teaches whole hours, including 24-hour reading")
                    expect(q.kind == recipe.kind && q.timeFamily == level.time(for: recipe), "configured question and time type")
                    if q.kind.usesOptions {
                        expect([2, 4].contains(q.responses.count), "balanced answer rows, never three choices")
                        expect(Set(q.responses).count == q.responses.count, "unique options")
                        expect(q.responses.filter { AnswerValidator.isCorrect($0, for: q) }.count == 1, "exactly one correct answer")
                    } else if q.kind == .match { checkMatchingQuestion(q) }
                    else if q.kind != .sortTimes { expect(q.options.isEmpty, "no options for controls") }
                }
            }
        }
        expect(observedKinds == Set(DinoLevelCatalog.levels.filter { $0.worldID == 1 }.flatMap { $0.recipes.map(\.kind) }), "jungle catalog interactions")
    }

    static func testWorldJoinContinuity() {
        for width: CGFloat in [320, 393, 402, 600, 834, 1194] {
            let clearance = max(0, min(200, (min(600, width) - 36) * 0.37) - 82)
            let offset = WorldMapChapterSpacing.routeOffset(clearance: clearance)
            let tail = WorldMapChapterSpacing.tail(clearance: clearance)
            let titleY = WorldMapChapterSpacing.bannerTop + WorldMapChapterSpacing.bannerCenter
            let above = tail + titleY - 45
            let below = offset + WorldMapChapterSpacing.firstNode - titleY - 36
            expect(abs(above - below) < 0.01, "all world signs balance boss and first-node rim clearance")
            let expectedGap = tail + offset + WorldMapChapterSpacing.firstNode
            for world in 1...9 {
                let first: CGFloat = world == 1 ? JungleMapLayout.firstNodeY : WorldMapChapterSpacing.firstNode
                let last = first + 9 * JungleMapLayout.levelSpacing
                let end = world == 1 ? last + tail : WorldMapChapterSpacing.routeHeight(clearance: clearance)
                expect(abs(end + offset + WorldMapChapterSpacing.firstNode - last - expectedGap) < 0.01,
                       "every boundary, including the jungle, has the same vertical node spacing")
            }
        }
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
            expect(profile.recordCompletedAttempt(levelID: world.bossLevel, correct: 5) == .none, "5/10 is not a boss star")
            expect(profile.recordCompletedAttempt(levelID: world.bossLevel, correct: 6) == .normal, "normal victory is scoped to this world")
            expect(profile.record(world.bossLevel).stars == 2, "the earlier 9/10 keeps two stars")
            expect(profile.worldComplete(world.id), "each boss completes its own world")
            if world.id < 10 { expect(profile.isUnlocked(world.bossLevel + 1), "next world opens after boss") }
        }
        expect(profile.adventureComplete && profile.dinoLevel == 100 && profile.totalStars == 110, "complete route reaches 100 and keeps every earned star, including bosses")
        let store = DinoProgressStore(defaults: InMemoryKeyValueStore())
        store.save(profile)
        expect(store.load() == profile, "all 100 level records and world victories survive restart")
        var cloud = PlayerProfile()
        cloud.mergeCloudProgress(DinoCloudProgress(profile))
        expect(cloud.adventureComplete && cloud.dinoLevel == 100 && cloud.totalStars == 110, "all worlds survive cloud merge")
        cloud.resetProgress()
        expect(cloud.dinoLevel == 0 && !cloud.isUnlocked(11) && cloud.totalStars == 0, "reset clears every world")
        var direct = PlayerProfile()
        for world in DinoWorldCatalog.worlds {
            expect(direct.recordCompletedAttempt(levelID: world.bossLevel, correct: 10) == .perfect, "perfect shortcuts work in all worlds")
            expect(world.levels.allSatisfy { direct.isUnlocked($0) }, "perfect unlock is scoped to the winning world")
        }
        expect(direct.adventureComplete && direct.dinoLevel == 100 && direct.totalStars == 30, "each perfect boss earns three stars and nothing else")
        for seed in 0..<20 {
            for level in DinoLevelCatalog.levels.filter({ $0.worldID > 1 }) {
                var rng = SeededGenerator(seed: UInt64(seed))
                let questions = DinoQuestionGenerator.generate(level: level, using: &rng)
                expect(questions.count == level.questionCount, "new world question count")
                for q in questions {
                    expect(q.timeFamily.minutes.contains(q.target.minute), "recipe-specific clock granularity")
                    expect(AnswerValidator.isCorrect(q.expectedAnswer, for: q), "generated expected answer is valid")
                    if q.kind.usesOptions {
                        expect([2, 4].contains(q.responses.count), "full answer rows")
                        expect(Set(q.responses).count == q.responses.count, "distinct responses")
                        expect(q.responses.filter { AnswerValidator.isCorrect($0, for: q) }.count == 1, "one correct response")
                    }
                    if q.kind == .match { checkMatchingQuestion(q) }
                    if q.kind == .minutesBetween {
                        expect(q.relatedTimes.count == 2, "world minute differences show two clocks")
                        expect(q.relatedTimes[1].minutesOfDay - q.relatedTimes[0].minutesOfDay == q.durationMinutes, "world minute difference matches both clocks")
                    }
                }
            }
        }
    }

    static func testLevelQuestionOutline() {
        let first = DinoLevelCatalog.level(1)!
        expect(first.questionOutline.count == 1 && first.questionOutline[0].practiceNumber == DinoPracticeQuestion.chooseAnalog.number,
               "the first level lists one whole-hour exercise")
        let mixed = DinoLevelCatalog.level(11)!
        expect(mixed.questionOutline.map(\.practiceNumber) == [DinoPracticeQuestion.chooseAnalog.number, DinoPracticeQuestion.chooseAnalog.number, DinoPracticeQuestion.match.number],
               "the same question type on two time families remains two distinct outline rows")
        expect(mixed.questionOutline.map(\.timeTitleKey) == [DinoPracticeTime.half.titleKey, DinoPracticeTime.whole.titleKey, DinoPracticeTime.whole.titleKey],
               "each outline row labels its own time family")
        for level in DinoLevelCatalog.levels {
            expect(level.questionOutline.count == level.recipes.count, "every planned combination has one row")
            for (index, recipe) in level.recipes.enumerated() {
                expect(level.questionOutline[index].timeTitleKey == level.time(for: recipe).titleKey, "outline times match actual generation")
                expect(level.questionOutline[index].titleKey == DinoPracticeQuestion(rawValue: recipe.kind.rawValue)!.titleKey, "outline names match practice")
                expect(level.questionOutline[index].practiceConfiguration == DinoPracticeConfiguration(
                    time: level.time(for: recipe), order: .specific(DinoPracticeQuestion(rawValue: recipe.kind.rawValue)!)),
                    "each outline row opens practice with the exact question and time family of its own recipe")
            }
        }
        expect(DinoLevelCatalog.level(31)!.practiceTimeTitleKey == DinoPracticeTime.tenMinutes.titleKey, "village introduces ten-minute steps")
        expect(DinoLevelCatalog.level(41)!.practiceTimeTitleKey == DinoPracticeTime.fiveMinutes.titleKey, "cave introduces five-minute steps")
        expect(DinoLevelCatalog.level(51)!.practiceTimeTitleKey == DinoPracticeTime.minutes.titleKey, "city introduces individual minutes")
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
        let bossStars = (0...10).map { StarCalculator.stars(correct: $0, questionCount: 10) }
        expect(bossStars == [0,0,0,0,0,0,1,1,2,2,3], "boss stars start at six and only ten earns three")
    }

    @MainActor
    static func testRepeatedAnswerControls() {
        let store = DinoProgressStore(defaults: InMemoryKeyValueStore())
        let player = DinoPlayer(store: store)
        let practice = DinoPracticeConfiguration(time: .fiveMinutes, order: .specific(.advanceAnalog))
        let session = DinoSession(level: practice.level, player: player, practice: practice, now: { 0 })
        expect(!session.retainsAnswerControls && !session.hidesAnswerControls, "controls stay until an answer arrives")
        session.submit(wrongAnswer(for: session.question))
        expect(session.hidesAnswerControls && !session.retainsAnswerControls, "a wrong answer still dismisses the buttons")
        session.advance()
        session.submit(session.question.expectedAnswer)
        expect(session.retainsAnswerControls && !session.hidesAnswerControls, "the next identical advance question keeps its buttons")

        let ascending = DinoSession(level: practice.level, player: player,
                                    practice: .init(time: .whole, order: .ascending), now: { 0 })
        ascending.submit(ascending.question.expectedAnswer)
        expect(!ascending.retainsAnswerControls && ascending.hidesAnswerControls, "a different following question dismisses its buttons")

        let repeated = LevelConfiguration(id: 6, worldID: 1, titleKey: "dino.level.6", instructionKey: "dino.question.setAnalog",
            allowedHours: Array(1...12), difficulty: 1, questionCount: 5, isBoss: false, recipes: [.init(kind: .setAnalog, optionCount: 0)])
        let level = DinoSession(level: repeated, player: player, now: { 0 })
        for index in 0..<4 {
            expect(level.question.kind == .setAnalog, "a repeated analog exercise keeps the analog controls")
            level.submit(level.question.expectedAnswer)
            expect(level.retainsAnswerControls, "question \(index + 1) is followed by the same buttons")
            level.advance()
        }
        level.submit(level.question.expectedAnswer)
        expect(!level.retainsAnswerControls && level.hidesAnswerControls, "the last question has no following buttons to keep")

        var mixed = DinoPracticeGenerator(configuration: .init(time: .minutes, order: .mix), seed: 11)
        for index in 0..<45 {
            let question = mixed.next(index: index)
            expect(mixed.upcomingKind(after: index) != nil, "every mixed question knows which buttons come next")
            _ = question
        }
    }

    static func testAnswerInputRequirements() {
        for family in DinoPracticeTime.allCases {
            for kind in [DinoPracticeQuestion.setAnalog, .setDigital, .advanceAnalog] {
                let player = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
                let config = DinoPracticeConfiguration(time: family, order: .specific(kind))
                var feedbackCount = 0
                let session = DinoSession(level: config.level, player: player, practice: config,
                                          answerFeedback: { _ in feedbackCount += 1 })
                for _ in 0..<5 {
                    let initial = session.inputTime
                    expect(initial.hourAngle != session.question.target.hourAngle || initial.minuteAngle != session.question.target.minuteAngle,
                           "every editable clock starts away from its target, including after advancing")
                    expect(session.answerCheck?.enabled == true && session.answerCheck?.requirement == .changeTime,
                           "an untouched clock keeps a tappable confirmation with an input reminder")
                    let record = player.practiceRecord(time: family, order: config.order)
                    let answered = session.practiceAnswered
                    let questionID = session.question.id
                    let previousFeedback = feedbackCount
                    for _ in 0..<3 { session.submit(session.answerCheck!.answer); session.advance() }
                    expect(!session.hasFeedback && session.attempt.answers.isEmpty && session.question.id == questionID,
                           "repeated confirmation taps cannot submit or skip an untouched clock")
                    expect(session.practiceAnswered == answered && feedbackCount == previousFeedback
                           && player.practiceRecord(time: family, order: config.order) == record,
                           "blocked clock submissions preserve records and do not play wrong-answer feedback")
                    if family.minuteStep < 60 {
                        session.adjustInputMinutes(by: family.minuteStep)
                        expect(session.answerCheck?.requirement == nil, "a minute-only change is enough to submit")
                        session.setInputTime(initial)
                        expect(session.answerCheck?.requirement == .changeTime, "returning to the starting time requires another change")
                    }
                    session.inputHour = ClockTime.shiftedHour(initial.hour, by: 1)
                    expect(session.answerCheck?.requirement == nil, "hour buttons and hand changes satisfy the clock requirement")
                    session.setInputTime(session.question.target)
                    session.submit(session.answerCheck!.answer)
                    expect(session.correctFeedback && session.practiceAnswered == answered + 1 && feedbackCount == previousFeedback + 1,
                           "a changed clock still scores exactly once")
                    session.advance()
                }
            }
            for code in ["nl", "en"] {
                let player = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
                let config = DinoPracticeConfiguration(time: family, order: .specific(.sayTime))
                let session = DinoSession(level: config.level, player: player, practice: config, language: code)
                expect(session.answerCheck?.requirement == .chooseTile, "spoken questions require a selected tile in both languages")
                for _ in 0..<3 { session.submit(session.answerCheck!.answer); session.advance() }
                expect(!session.hasFeedback && session.question.id == 0 && session.practiceAnswered == 0 && player.practiceRecords.isEmpty,
                       "empty spoken answers cannot advance or affect progress")
                let prompt = session.question.spokenPrompt!
                let first = prompt.slots[0].choices[0]
                session.chooseSpoken(slot: 0, choiceID: first.id)
                expect(session.answerCheck?.requirement == nil, "one selected tile is enough; a complete sentence is not required")
                session.chooseSpoken(slot: 0, choiceID: first.id)
                expect(session.answerCheck?.requirement == .chooseTile, "deselecting the final tile restores the requirement")
                session.submit(.spoken(.init(choiceIDs: Array(repeating: "unknown", count: prompt.slots.count))))
                expect(!session.hasFeedback, "invalid tile IDs cannot bypass the selection requirement")
                session.chooseSpoken(slot: 0, choiceID: first.id)
                session.submit(session.answerCheck!.answer)
                expect(session.hasFeedback && session.practiceAnswered == 1, "a partial answer with one real tile can be checked")
                session.advance()
                expect(session.spokenChoices.isEmpty && session.answerCheck?.requirement == .chooseTile,
                       "the selection requirement resets for the next question")
            }
        }
        // The hands must differ even when a twelve-hour target is represented as 00:00 or 24:00.
        for hour in 0..<24 {
            for kind in [DinoPracticeQuestion.setAnalog, .setDigital] {
                let config = DinoPracticeConfiguration(time: .whole, order: .specific(kind))
                let target = ClockTime(hour: hour)
                let example = ClockQuestion(id: 0, kind: kind.recipe.kind, target: target, options: [], activity: nil, companionClocks: [])
                let player = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
                let session = DinoSession(level: config.level, player: player, practice: config, example: example)
                expect(session.inputTime.hourAngle != target.hourAngle, "no hour representation starts on the target clock face")
            }
        }
    }

    @MainActor
    static func testAnswerRetries() {
        let store = DinoProgressStore(defaults: InMemoryKeyValueStore())
        let player = DinoPlayer(store: store)
        for type in DinoPracticeQuestion.allCases where type.recipe.kind.usesOptions {
            let config = DinoPracticeConfiguration(time: .minutes, order: .specific(type))
            var generator = DinoPracticeGenerator(configuration: config, seed: 42)
            var question = generator.next(index: 0, difficultyForKind: { _ in .challenge })
            // Choose a four-option variation for the original clock questions.
            for index in 1..<20 where question.responses.count <= 2 && type != .trueFalse {
                question = generator.next(index: index, difficultyForKind: { _ in .challenge })
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
            expect(session.missedFirstAnswer && session.showsWorkedExplanation == !allowsRetry,
                   "a hint may follow the first miss, and the worked method waits until the question closes")
            expect(!session.responseIsEnabled(wrong[0]), "a rejected option cannot be selected again")
            session.submit(wrong[0])
            expect(feedback == [false], "repeated taps on a rejected answer are ignored")
            if allowsRetry {
                session.advance()
                expect(session.attempt.index == 0, "the player must solve or reveal a failed multiple-choice question before Next")
                expect(session.responseIsEnabled(question.expectedAnswer), "the correct answer stays available without being highlighted")
                now += 100
                session.submit(wrong[1])
                expect(session.rejectedResponses == Set(wrong.prefix(2)) && session.canRetry && !session.showsWorkedExplanation,
                       "additional wrong choices stay marked while retries remain available")
                session.submit(question.expectedAnswer)
                expect(session.correctFeedback && !session.canRetry && session.showsCorrectResponse && session.showsWorkedExplanation && !session.shouldAutoAdvance,
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
            expect(revealed.showsWorkedExplanation, "a closed miss shows how the question worked")

            if allowsRetry {
                let eliminated = DinoSession(level: config.level, player: player, practice: config, example: question)
                for choice in wrong { eliminated.submit(choice) }
                expect(eliminated.answerRevealed && eliminated.showsCorrectResponse && eliminated.showsWorkedExplanation
                       && !eliminated.canRetry && !eliminated.correctFeedback && eliminated.attempt.answers == [false],
                       "ruling out every wrong choice reveals the last answer without another tap")
                expect(question.responses.allSatisfy { !eliminated.responseIsEnabled($0) }, "the remaining choice closes with the others")
                eliminated.submit(question.expectedAnswer)
                expect(!eliminated.correctFeedback && eliminated.attempt.answers == [false], "the revealed last choice cannot be scored afterwards")
            }
        }

        let level = DinoLevelCatalog.level(10)!
        let session = DinoSession(level: level, player: player)
        session.submit(session.question.responses.first { $0 != session.question.expectedAnswer }!)
        session.submit(session.question.expectedAnswer)
        session.advance()
        expect(session.attempt.index == 1 && session.attempt.answers == [false] && session.rejectedResponses.isEmpty &&
               !session.retryAnsweredCorrectly && !session.answerRevealed && !session.hasFeedback && !session.correctFeedback,
               "Next clears retry state for the following level question")
        let followed = DinoSession(level: level, player: player)
        followed.submit(followed.question.expectedAnswer)
        followed.advance()
        expect(!followed.hasFeedback && !followed.correctFeedback && followed.attempt.answers.last == true,
               "a correct answer does not leave success feedback on the next question")
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
        expect(p.recordCompletedAttempt(levelID: 10, correct: 5) == .none && !p.worldOneComplete && p.record(10).stars == 0, "5/10 earns no star")
        expect(p.recordCompletedAttempt(levelID: 10, correct: 6) == .normal && p.worldOneComplete && p.record(10).stars == 1, "6/10 is one star")
        p.recordCompletedAttempt(levelID: 10, correct: 0)
        expect(p.worldOneComplete && p.dinoLevel == 10 && p.record(10).bestCorrect == 6 && p.record(10).stars == 1, "world victory stays saved")
        expect(p.bossResults.count == 3 && p.record(10).attempts == 3, "boss history")
        var direct = PlayerProfile()
        expect(direct.recordCompletedAttempt(levelID: 10, correct: 9) == .none && !direct.worldOneComplete && direct.dinoLevel == 0 && direct.record(10).stars == 2, "9/10 without the route fails and keeps two stars")
        expect(direct.recordCompletedAttempt(levelID: 10, correct: 10) == .perfect, "direct perfect victory")
        expect(direct.worldOneComplete && direct.perfectBossVictory && direct.dinoLevel == 10 && (1...10).allSatisfy(direct.isUnlocked) && direct.isUnlocked(11), "perfect opens entire world and next world entrance")
        expect(direct.totalStars == 3 && direct.record(10).stars == 3, "only the perfect boss adds its three stars")
        for completed in [false, true] {
            for score in 0...10 {
                let expected: BossVictory = score == 10 ? .perfect : completed && score >= 6 ? .normal : .none
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
        var saved = try! JSONSerialization.jsonObject(with: JSONEncoder().encode(p)) as! [String: Any]
        var kinds = saved["demonstratedInteractions"] as! [String]
        kinds.append(contentsOf: ["elapsedTime", "schoolEnd"])
        saved["demonstratedInteractions"] = kinds
        memory.set(try! JSONSerialization.data(withJSONObject: saved), forKey: DinoProgressStore.profileKey)
        let retired = DinoProgressStore(defaults: memory).load()
        expect(retired.demonstratedInteractions == [.setAnalog] && retired.record(1).bestCorrect == 5,
               "a retired question kind does not discard the saved profile")
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
        expect(migrated.hourNotation == nil && migrated.resolvedHourNotation() == DigitalHourNotation.device && !migrated.hourNotationDiffersFromDevice(),
               "older clocks follow the device until a notation is chosen")
        let savedNotation = try! JSONDecoder().decode(ClockTheme.self, from: Data(#"{"hourNotation":"twelve","numerals":"classic"}"#.utf8))
        let storedNotation = try! JSONDecoder().decode(ClockTheme.self, from: try! JSONEncoder().encode(savedNotation))
        expect(savedNotation.hourNotation == .twelve && savedNotation.numerals == .classic && storedNotation.hourNotation == .twelve,
               "a chosen hour notation survives restart")
        var notation = ClockTheme.standard
        let other: DigitalHourNotation = DigitalHourNotation.device == .twelve ? .twentyFour : .twelve
        notation.hourNotation = other
        expect(notation.hourNotationDiffersFromDevice() && notation.resolvedHourNotation() == other, "a different notation is kept and flagged")
        notation.hourNotation = DigitalHourNotation.device
        expect(!notation.hourNotationDiffersFromDevice(), "matching the device stays quiet")
        notation.resetDigital()
        expect(notation.hourNotation == nil && !notation.hourNotationDiffersFromDevice(), "restoring the digital clock follows the device again")
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
        expect(player.needsFirstLevelHint && player.profile.nextAdventureLevel == 1 && player.profile.mapLevel == 1, "a fresh installation guides level one")
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
        expect(route.nextAdventureLevel == 1 && route.mapLevel == 1, "a failed level remains the next playable step")
        for level in DinoLevelCatalog.levels {
            expect(route.nextAdventureLevel == level.id && route.mapLevel == level.id, "guidance targets each of the hundred playable levels")
            route.recordCompletedAttempt(levelID: level.id, correct: level.questionCount)
        }
        expect(route.adventureComplete && route.nextAdventureLevel == nil && route.mapLevel == 100, "finishing the adventure leaves Dino on level 100")
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

    static func testAssetCatalog() {
        // Include names assembled by animation code, not just string literals.
        var sprites = Set(["dino-idle"] + DinoOpeningJump.assets)
        for clip: DinoAnimation.Clip in [.idle, .thumbsUp, .wrongAnswer, .stumble, .openingJump, .backflip, .pirouette, .worldJump] {
            for reducedMotion in [false, true] {
                for tick in 0...400 {
                    let sample = DinoAnimation.sample(clip, elapsed: Double(tick) / 120, reducedMotion: reducedMotion)
                    sprites.insert(sample.pose.asset)
                    if let previous = sample.previousPose { sprites.insert(previous.asset) }
                }
            }
        }
        let preloaded = Set(DinoAnimation.spriteAssets + DinoAnimation.worldJumpAssets)
        expect(preloaded.isSubset(of: sprites), "every preloaded sprite is actually displayed by an animation")
        let bossSource = try! String(contentsOfFile: "Dino/Views/WorldBossArt.swift", encoding: .utf8)
        let pattern = try! NSRegularExpression(pattern: #""boss-[a-z-]+""#)
        let bosses = Set(pattern.matches(in: bossSource, range: NSRange(bossSource.startIndex..., in: bossSource)).map {
            String(bossSource[Range($0.range, in: bossSource)!].dropFirst().dropLast())
        })
        expect(bosses.count == 10, "all ten world boss illustrations are accounted for")
        let expected = sprites.union(bosses).union(["reward-star"])
        let root = URL(fileURLWithPath: "Assets.xcassets")
        let actual = Set(try! FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "imageset" }.map { $0.deletingPathExtension().lastPathComponent })
        expect(actual == expected, "catalog has all displayed assets and no unused image sets: \(actual.symmetricDifference(expected).sorted())")
        for asset in expected {
            let url = root.appendingPathComponent("\(asset).imageset/\(asset).png")
            guard let data = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let image = CGImageSourceCreateImageAtIndex(data, 0, nil) else {
                fatalError("Missing or invalid asset: \(asset)")
            }
            let side = asset == "dino-idle" || asset.hasPrefix("dino-opening-jump-") ? 1254
                : bosses.contains(asset) ? 640 : asset == "reward-star" ? 384 : 768
            expect(image.width == side && image.height == side, "\(asset) retains its intended iPad raster budget")
            let contents = try! Data(contentsOf: url.deletingLastPathComponent().appendingPathComponent("Contents.json"))
            let manifest = try! JSONSerialization.jsonObject(with: contents) as! [String: Any]
            let images = manifest["images"] as! [[String: Any]]
            expect(images.compactMap { $0["filename"] as? String } == [url.lastPathComponent],
                   "\(asset) catalog entry points to its renamed PNG")
        }
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
        for asset in ["dino-idle", "dino-opening-jump-03"] {
            let url = URL(fileURLWithPath: "Assets.xcassets/\(asset).imageset/\(asset).png")
            let source = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
            let colors = DinoAppearance(bandana: 0x784DCB, spikes: 0xFFE15A, body: 0xF0A12C, belly: 0x81D349)
            let original = DinoSpriteColorRenderer.recolored(source, appearance: colors, asset: asset, resolution: .original)!
            let compact = DinoSpriteColorRenderer.recolored(source, appearance: colors, asset: asset)!
            expect(original.width == source.width && original.height == source.height && original.width == 1254,
                   "the large opening retains all source pixels after personalization")
            expect(compact.width == 768, "ordinary companions keep their compact rendering budget")
        }
        // Exercise the actual 768-pixel display raster as well as a thumbnail.
        // Resampling an already reduced source to 384 pixels can shift a tone
        // quantile by one 8-bit step; the display-raster limit stays unchanged.
        for size in [384, 768] {
        let toneTolerance = 0.015 + (size == 384 ? 1.0 / 255 : 0)
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
            var idleHue = [DinoAppearance.Part: Double]()
            let assets = size == 384 ? DinoAnimation.spriteAssets : ["dino-idle"] + DinoAnimation.stumbleAssets
            for asset in assets {
                let url = URL(fileURLWithPath: "Assets.xcassets/\(asset).imageset/\(asset).png")
                let source = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
                let original = pixels(source)
                let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                                        bytesPerRow: size * 4, space: colorSpace, bitmapInfo: bitmapInfo)!
                context.interpolationQuality = .high
                context.draw(source, in: CGRect(x: 0, y: 0, width: size, height: size))
                let output = pixels(DinoSpriteColorRenderer.recolored(context.makeImage()!, appearance: appearance, asset: asset)!)
                var lightness = [DinoAppearance.Part: [Double]](), saturation = [DinoAppearance.Part: [Double]]()
                var hues = [DinoAppearance.Part: [Double]]()
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
                            hues[part, default: []].append(after.h > 0.8 ? after.h - 1 : after.h)
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
                        let h = hues[part]!.sorted(); idleHue[part] = h[h.count / 2]
                    } else {
                        expect(zip(quantiles, idleLightness[part]!).allSatisfy { abs($0 - $1) < toneTolerance },
                               "\(asset) matches idle \(part) shadows, base color and highlights: \(quantiles) vs \(idleLightness[part]!)")
                        expect(abs(s[s.count / 2] - idleSaturation[part]!) < 0.025,
                               "\(asset) keeps idle \(part) saturation instead of becoming pastel: \(s[s.count / 2]) vs \(idleSaturation[part]!)")
                        if asset.hasPrefix("dino-result-fall-") {
                            let h = hues[part]!.sorted()
                            expect(abs(h[h.count / 2] - idleHue[part]!) < 0.004,
                                   "\(asset) keeps the same \(part) hue as idle at \(size) pixels, including the standard palette")
                        }
                    }
                }
            }
        }
        }
    }

    static func testPaleBandanaLettering() {
        // Pose-specific print regions also keep the eye and mouth out of this check.
        let regions: [(String, CGRect)] = [
            ("dino-idle", CGRect(x: 550, y: 90, width: 238, height: 106)),
            ("dino-result-backflip-crouch", CGRect(x: 702, y: 205, width: 258, height: 98)),
            ("dino-result-backflip-airborne", CGRect(x: 326, y: 131, width: 210, height: 160)),
            ("dino-result-backflip-landing", CGRect(x: 638, y: 233, width: 256, height: 106)),
            ("dino-result-backflip-recover", CGRect(x: 520, y: 102, width: 237, height: 109)),
            ("dino-result-pirouette-01", CGRect(x: 580, y: 150, width: 252, height: 105)),
            ("dino-result-pirouette-04", CGRect(x: 700, y: 135, width: 195, height: 100)),
            ("dino-result-pirouette-13", CGRect(x: 390, y: 120, width: 195, height: 117)),
            ("dino-result-pirouette-11", CGRect(x: 392, y: 165, width: 60, height: 62)),
            ("dino-result-pirouette-14", CGRect(x: 439, y: 203, width: 231, height: 120)),
            ("dino-result-pirouette-12", CGRect(x: 350, y: 139, width: 155, height: 94)),
            ("dino-result-pirouette-18", CGRect(x: 560, y: 118, width: 246, height: 110)),
            ("dino-result-pirouette-15", CGRect(x: 433, y: 208, width: 246, height: 109)),
            ("dino-result-pirouette-02", CGRect(x: 696, y: 207, width: 243, height: 90)),
            ("dino-result-pirouette-03", CGRect(x: 681, y: 157, width: 220, height: 104)),
            ("dino-result-pirouette-16", CGRect(x: 568, y: 161, width: 245, height: 83)),
            ("dino-result-pirouette-17", CGRect(x: 559, y: 112, width: 236, height: 104))
        ] + (DinoSpriteColorRenderer.answerLetteringBounds.merging(DinoSpriteColorRenderer.deepFallLetteringBounds) { first, _ in first }).map { ($0.key, $0.value) }
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

    static func testQuestionPrompts() {
        expect(DinoTimeWords.spokenDuration(60, language: "en") == "1 hour", "one hour is spoken in full")
        expect(DinoTimeWords.spokenDuration(60, language: "nl") == "1 uur", "one Dutch hour is spoken in full")
        expect(DinoTimeWords.spokenDuration(1, language: "en") == "1 minute" &&
               DinoTimeWords.spokenDuration(1, language: "nl") == "1 minuut", "a single minute stays singular")
        expect(DinoTimeWords.spokenDuration(90, language: "en") == "1 hour and 30 minutes" &&
               DinoTimeWords.spokenDuration(90, language: "nl") == "1 uur en 30 minuten", "mixed durations stay speakable")
        expect(DinoTimeWords.spokenDuration(120, language: "en") == "2 hours", "several hours use the plural")
        expect(DinoTimeWords.promptTime(ClockTime(hour: 15), language: "nl") == "drie uur ’s middags",
               "a 24-hour clock does not collapse to the morning")
        expect(DinoTimeWords.promptTime(ClockTime(hour: 3), language: "en") == "three o’clock",
               "a morning hour stays a short phrase")

        // Exercise the shipped translations, including static instructions, rather than copies of the formats.
        let catalogURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Localizable.xcstrings")
        let catalog = try! JSONSerialization.jsonObject(with: Data(contentsOf: catalogURL)) as! [String: Any]
        let strings = catalog["strings"] as! [String: [String: Any]]
        func localized(_ key: String, _ language: String) -> String {
            let localizations = strings[key]?["localizations"] as? [String: [String: Any]]
            let unit = localizations?[language]?["stringUnit"] as? [String: String]
            guard let value = unit?["value"], !value.isEmpty else { fatalError("Missing \(language) question text: \(key)") }
            return value
        }
        func sentence(_ prompt: DinoQuestionPrompt, _ language: String) -> String {
            prompt.spoken { localized($0, language) }
        }
        func prompt(_ question: ClockQuestion, _ language: String) -> DinoQuestionPrompt {
            DinoQuestionPrompt.make(question: question, language: language, instructionKey: question.kind.instructionKey)
        }
        func question(kind: ClockQuestionKind, target: ClockTime, options: [ClockTime] = [],
                      related: [ClockTime] = [], duration: Int = 0, offset: Int = 0,
                      statement: ClockTime? = nil, schedule: DinoDaySchedule? = nil,
                      journey: DinoTimeZoneJourney? = nil) -> ClockQuestion {
            var question = ClockQuestion(id: 1, kind: kind, target: target, options: options, activity: nil, companionClocks: [])
            question.relatedTimes = related
            question.durationMinutes = duration
            question.offsetMinutes = offset * 60
            question.statement = statement
            question.daySchedule = schedule
            question.timeZoneJourney = journey
            return question
        }

        let four = (1...4).map { ClockTime(hour: $0) }
        let matching = question(kind: .chooseAnalog, target: ClockTime(hour: 3), options: four)
        let englishMatch = prompt(matching, "en")
        expect(sentence(englishMatch, "en") == "Which of the four clocks shows three o’clock?", "question 1 names the clock time")
        expect(englishMatch.arguments.allSatisfy { $0.emphasis == .plain }, "clock times use the title's base color")
        expect(sentence(prompt(matching, "nl"), "nl") == "Welke van de vier klokken geeft drie uur aan?", "Dutch question 1 names the time")
        let two = question(kind: .chooseAnalog, target: ClockTime(hour: 3), options: Array(four.prefix(2)))
        expect(sentence(prompt(two, "en"), "en") == "Which of the two clocks shows three o’clock?", "two choices are counted honestly")
        let single = question(kind: .chooseAnalog, target: ClockTime(hour: 3))
        expect(sentence(prompt(single, "nl"), "nl") == "Welke klok geeft drie uur aan?", "an example without choices does not invent a count")

        let spoken = question(kind: .spokenTime, target: ClockTime(hour: 3), options: four)
        expect(sentence(prompt(spoken, "en"), "en") == "Which of the four clocks shows three o’clock?", "a spoken time still asks which clock")
        let claim = question(kind: .trueFalse, target: ClockTime(hour: 4), statement: ClockTime(hour: 3))
        expect(sentence(prompt(claim, "nl"), "nl") == "De klok geeft drie uur aan. Klopt dat?", "a true-or-false title is the claim, not the verdict")
        expect(prompt(claim, "nl").arguments.map(\.emphasis) == [.plain], "the claimed time uses the title's base color")

        for kind in [ClockQuestionKind.chooseDigital, .readDigital, .sayTime, .setAnalog, .setDigital, .read24Hour, .dayPart, .match, .sortTimes] {
            let asked = question(kind: kind, target: ClockTime(hour: 3), options: four, related: four)
            let title = prompt(asked, "en")
            expect(title.formatKey == nil && title.arguments.isEmpty, "\(kind.rawValue) does not read out its answer")
        }

        let forward = question(kind: .advanceAnalog, target: ClockTime(hour: 4), related: [ClockTime(hour: 3)], duration: 60)
        let forwardTitle = prompt(forward, "en")
        expect(sentence(forwardTitle, "en") == "Move the clock hands 1 hour forward.", "moving the hands names the step")
        expect(sentence(prompt(forward, "nl"), "nl") == "Zet de wijzers 1 uur vooruit.", "Dutch hands move forward in words")
        expect(forwardTitle.arguments.map(\.emphasis) == [.plain, .forward], "only the word forward is green")
        expect(!sentence(forwardTitle, "en").contains("four"), "the resulting time stays off the title")

        let added = question(kind: .addTime, target: ClockTime(hour: 16), related: [ClockTime(hour: 15)], duration: 90)
        let addedTitle = prompt(added, "nl")
        expect(sentence(addedTitle, "nl") == "Het is drie uur. Hoe laat is het 1 uur en 30 minuten later?",
               "adding time repeats the start and the step")
        expect(addedTitle.arguments.map(\.emphasis) == [.plain, .plain, .forward], "only later is green; the time and duration stay plain")
        expect(!sentence(addedTitle, "nl").contains("vier"), "the later time is not spoken")

        let earlier = question(kind: .subtractTime, target: ClockTime(hour: 2), related: [ClockTime(hour: 4)], duration: 120)
        let earlierTitle = prompt(earlier, "en")
        expect(sentence(earlierTitle, "en") == "It is four o’clock. What time was it 2 hours earlier?", "going back names the step")
        expect(earlierTitle.arguments.map(\.emphasis) == [.plain, .plain, .backward], "only earlier is red; the time and duration stay plain")
        expect(!sentence(earlierTitle, "en").contains("two"), "the earlier result is not spoken")

        let between = question(kind: .minutesBetween, target: ClockTime(hour: 4),
                               related: [ClockTime(hour: 3), ClockTime(hour: 4)], duration: 60)
        let betweenTitle = prompt(between, "en")
        expect(sentence(betweenTitle, "en") == "How many minutes are there between three o’clock and four o’clock?",
               "the gap question names both clocks")
        expect(betweenTitle.arguments.map(\.emphasis) == [.plain, .plain], "both clocks use the title's base color")
        expect(!sentence(betweenTitle, "en").contains("1 hour"), "the minute answer is not spoken")

        let sequence = question(kind: .timeSequence, target: ClockTime(hour: 5),
                                related: [ClockTime(hour: 2), ClockTime(hour: 3), ClockTime(hour: 4)], duration: 60)
        expect(sentence(prompt(sequence, "nl"), "nl") == "Kijk naar de reeks. Welke tijd komt na vier uur?",
               "the sequence names the last clock without the step")
        expect(prompt(sequence, "en").arguments.map(\.emphasis) == [.plain], "the sequence uses the title's base color")
        expect(!sentence(prompt(sequence, "en"), "en").contains("hour"), "the sequence step stays off the title")

        let schedule = DinoDaySchedule(start: ClockTime(hour: 8), firstActivity: .drawing, firstMinutes: 60,
                                       breakMinutes: 15, secondActivity: .music, secondMinutes: 30)
        let train = question(kind: .daySchedule, target: schedule.end, schedule: schedule)
        let trainTitle = prompt(train, "en")
        expect(trainTitle.formatKey == nil && trainTitle.arguments.isEmpty, "the train title points at the schedule")
        expect(trainTitle.plainKey == "dino.question.daySchedule", "the train keeps one short instruction")

        let london = DinoTimeZoneJourney.capitals.first { $0.id == "london" }!
        let paris = DinoTimeZoneJourney.capitals.first { $0.id == "paris" }!
        let washington = DinoTimeZoneJourney.capitals.first { $0.id == "washington" }!
        let toParis = DinoTimeZoneJourney(origin: london, destination: paris)
        let parisQuestion = question(kind: .timeZone, target: ClockTime(hour: 4), related: [ClockTime(hour: 3)], journey: toParis)
        expect(toParis.offsetMinutes > 0, "Paris is ahead of London in this check")
        let parisShift = DinoTimeWords.spokenDuration(toParis.offsetMinutes, language: "en")
        expect(sentence(prompt(parisQuestion, "en"), "en")
               == "It is three o’clock in London. Paris is \(parisShift) ahead. What time is it there?",
               "a later city names the difference")
        expect(prompt(parisQuestion, "en").arguments.map(\.emphasis) == [.plain, .plain, .plain, .plain, .forward],
               "only ahead is green; the hour difference stays plain")
        let toWashington = DinoTimeZoneJourney(origin: london, destination: washington)
        let washingtonQuestion = question(kind: .timeZone, target: ClockTime(hour: 10), related: [ClockTime(hour: 15)], journey: toWashington)
        expect(toWashington.offsetMinutes < 0, "Washington is behind London in this check")
        expect(prompt(washingtonQuestion, "nl").arguments.last?.emphasis == .backward, "a city behind is red")
        expect(!sentence(prompt(washingtonQuestion, "en"), "en").contains("ten"), "the destination time is not spoken")

        let flight = question(kind: .flightArrival, target: ClockTime(hour: 6), related: [ClockTime(hour: 3)], duration: 120, offset: 1)
        expect(sentence(prompt(flight, "en"), "en") == "The plane leaves at three o’clock. What time does it arrive?",
               "a flight title asks for arrival using only the departure")
        expect(prompt(flight, "en").arguments.map(\.emphasis) == [.plain],
               "flight duration and zone emphasis stay on the ticket")
        let returning = question(kind: .flightArrival, target: ClockTime(hour: 2), related: [ClockTime(hour: 3)], duration: 180, offset: -2)
        expect(prompt(returning, "nl").arguments.map(\.emphasis) == [.plain],
               "Dutch flight titles keep the departure in one color")
        expect(sentence(prompt(returning, "nl"), "nl") == "Het vliegtuig vertrekt om drie uur. Hoe laat komt het aan?",
               "Dutch flight titles use the same short question")
        let sameZone = question(kind: .flightArrival, target: ClockTime(hour: 5), related: [ClockTime(hour: 3)], duration: 120)
        expect(sentence(prompt(sameZone, "en"), "en") == "The plane leaves at three o’clock. What time does it arrive?",
               "a flight without a zone change uses the same short question")
        expect(!sentence(prompt(flight, "en"), "en").contains("six"), "the arrival time is not spoken")

        for language in ["nl", "en"] {
            for hour in 0..<24 {
                let start = ClockTime(hour: hour, minute: 45)
                let end = start.adding(minutes: 30)
                let shortTime = DinoTimeWords.time(start, language: language)
                let shortEnd = DinoTimeWords.time(end, language: language)
                for kind in [ClockQuestionKind.chooseAnalog, .spokenTime, .activity, .trueFalse] {
                    let analog = question(kind: kind, target: start, options: four, statement: start)
                    let title = prompt(analog, language)
                    expect(title.arguments.last?.text == shortTime,
                           "\(kind) omits the day part for an analog face at \(start.digitalText) in \(language)")
                    expect(title.arguments.allSatisfy { $0.emphasis == .plain }, "analog titles have one color")
                }
                let interval = question(kind: .minutesBetween, target: end, related: [start, end], duration: 30)
                expect(prompt(interval, language).arguments.map(\.text) == [shortTime, shortEnd],
                       "short intervals omit both day parts, including across noon and midnight")
                let series = question(kind: .timeSequence, target: end, related: [start], duration: 30)
                expect(prompt(series, language).arguments.map(\.text) == [shortTime],
                       "the sequence's visible clocks provide the 24-hour context")
            }
            for hour in 0..<24 {
                let start = ClockTime(hour: hour, minute: 45)
                let shortTime = DinoTimeWords.time(start, language: language)
                for kind in [ClockQuestionKind.addTime, .subtractTime, .timeZone, .flightArrival] {
                    let calculation = question(kind: kind, target: start.adding(minutes: 90), related: [start],
                                               duration: 90, journey: toParis)
                    expect(prompt(calculation, language).arguments.first?.text == shortTime,
                           "\(kind) uses the visible digital reference for AM/PM at \(start.digitalText)")
                }
                for notation in [DigitalHourNotation.twelve, .twentyFour] {
                    let reading = start.digitalReading(notation: notation, languageCode: language)
                    expect((reading.period != nil) == (notation == .twelve), "the reference clock preserves the selected notation")
                    if notation == .twelve {
                        expect(reading.period == (hour < 12 ? "AM" : "PM"), "midnight is AM and noon is PM in both languages")
                    } else {
                        expect(reading.text == start.digitalText, "24-hour references keep the full hour")
                    }
                }
            }
            for kind in ClockQuestionKind.allCases {
                for hour in 0..<24 {
                    for minute in [0, 1, 15, 30, 45, 59] {
                        let time = ClockTime(hour: hour, minute: minute)
                        let asked = question(kind: kind, target: time.adding(minutes: 90), options: four,
                                             related: [time, time.adding(minutes: 30)], duration: 90,
                                             statement: time, schedule: schedule, journey: toParis)
                        let title = prompt(asked, language)
                        let text = sentence(title, language)
                        let format = localized(title.formatKey ?? title.plainKey, language)
                        expect(format.components(separatedBy: "%@").count - 1 == title.arguments.count,
                               "\(kind) has the exact number of arguments required by its \(language) translation")
                        expect(!text.isEmpty && !text.contains("%@") && !text.contains("dino."), "every question has a complete localized title")
                        expect(!text.contains(DinoTimeWords.dayPartSuffix(time, language: language)), "titles omit redundant day-part suffixes")
                        for argument in title.arguments where argument.emphasis != .plain {
                            let allowed = language == "nl" ? ["vooruit", "later", "eerder", "voor", "achter"]
                                : ["forward", "later", "earlier", "ahead", "behind"]
                            expect(allowed.contains(argument.text), "only a direction word can be colored")
                        }
                    }
                }
            }
            for type in DinoPracticeQuestion.allCases {
                expect(!localized(type.titleKey, language).isEmpty, "every practice type has a name in both languages")
            }
            let noon = question(kind: .chooseAnalog, target: ClockTime(hour: 12), options: Array(four.prefix(2)))
            expect(sentence(prompt(noon, language), language) == (language == "nl"
                ? "Welke van de twee klokken geeft twaalf uur aan?" : "Which of the two clocks shows twelve o’clock?"),
                   "the attached example uses natural clock wording")
            expect(DinoTimeWords.time(ClockTime(hour: 3), language: language, dayPart: true)
                   != DinoTimeWords.time(ClockTime(hour: 15), language: language, dayPart: true),
                   "day-part answer choices still distinguish AM and PM")

        }
    }

    static func testQuestionSpeechVoices() {
        func voice(_ identifier: String, _ name: String, _ language: String, _ quality: Int) -> DinoSpeechVoice {
            DinoSpeechVoice(identifier: identifier, name: name, language: language, quality: quality)
        }
        let dutch = [
            voice("com.apple.voice.compact.nl-NL.Xander", "Xander", "nl-NL", 1),
            voice("com.apple.voice.premium.nl-BE.Ellen", "Ellen", "nl-BE", 3),
            voice("com.apple.eloquence.nl-NL.Ellen", "Ellen", "nl-NL", 2)
        ]
        let chosen = DinoSpeechVoicePicker.bestVoice(for: "nl", among: dutch)
        expect(chosen?.identifier == "com.apple.eloquence.nl-NL.Ellen", "Netherlands Dutch outranks a premium Belgian voice")
        let premiumDutch = dutch + [voice("com.apple.voice.premium.nl-NL.Xander", "Xander", "nl-NL", 3)]
        expect(DinoSpeechVoicePicker.bestVoice(for: "nl", among: premiumDutch)?.identifier == "com.apple.voice.premium.nl-NL.Xander",
               "the highest Netherlands Dutch quality wins inside that region")
        let siri = premiumDutch + [voice("com.apple.ttsbundle.siri_female_nl-NL_premium", "Siri", "nl-NL", 3)]
        expect(DinoSpeechVoicePicker.bestVoice(for: "nl", among: siri)?.name == "Siri",
               "a premium Siri voice is preferred over another premium voice from the same region")
        expect(DinoSpeechVoicePicker.bestVoice(for: "nl", among: [voice("com.apple.voice.premium.nl-BE.Ellen", "Ellen", "nl-BE", 3)])?.language == "nl-BE",
               "Belgian Dutch is used only when no Netherlands voice is installed")
        let english = [
            voice("com.apple.voice.compact.en-GB.Daniel", "Daniel", "en-GB", 1),
            voice("com.apple.voice.premium.en-US.Zoe", "Zoe", "en-US", 3),
            voice("com.apple.speech.synthesis.voice.whisper", "Whisper", "en-GB", 3)
        ]
        expect(DinoSpeechVoicePicker.bestVoice(for: "en", among: english)?.identifier == "com.apple.voice.compact.en-GB.Daniel",
               "British English outranks American English, and novelty voices stay unused")
        expect(DinoSpeechVoicePicker.bestVoice(for: "en", among: [voice("com.apple.voice.premium.en-US.Zoe", "Zoe", "en-US", 3),
                                                                  voice("com.apple.voice.enhanced.en-AU.Karen", "Karen", "en-AU", 2)])?.language == "en-US",
               "without a British voice the best remaining English voice is used")
        expect(DinoSpeechVoicePicker.preferredLanguageIdentifier(for: "nl") == "nl-NL", "Dutch speech asks for Netherlands Dutch")
        expect(DinoSpeechVoicePicker.preferredLanguageIdentifier(for: "en") == "en-GB", "English speech asks for British English")
        expect(DinoSpeechVoicePicker.bestVoice(for: "nl", among: []) == nil, "no installed voice leaves the system fallback in charge")
    }

    static func testSettingsAndFeedback() {
        let memory = InMemoryKeyValueStore()
        let settings = DinoSettings(defaults: memory)
        expect(settings.soundEffectsEnabled && settings.hapticsEnabled, "answer feedback enabled by default")
        expect(!settings.speakQuestionTitles, "question titles stay quiet until a parent turns reading on")
        expect(!settings.highContrastEnabled && !settings.icloudSyncEnabled, "contrast and cloud opt-in defaults")
        expect(settings.practiceTime == .whole && settings.practiceOrder == .ascending, "practice opens on whole hours in ascending order")
        expect(settings.dayPartSchedule == .standard, "day parts open on the built-in timetable")
        settings.soundEffectsEnabled = false; settings.hapticsEnabled = false
        settings.speakQuestionTitles = true
        settings.highContrastEnabled = true; settings.icloudSyncEnabled = true
        settings.practiceTime = .quarter; settings.practiceOrder = .specific(.setAnalog)
        settings.dayPartSchedule = DinoDayPartSchedule(night: 23, morning: 7, afternoon: 12, evening: 18)
        let restarted = DinoSettings(defaults: memory)
        expect(!restarted.soundEffectsEnabled && !restarted.hapticsEnabled && restarted.speakQuestionTitles && restarted.highContrastEnabled && restarted.icloudSyncEnabled, "every preference survives restart, including false values")
        expect(restarted.practiceTime == .quarter && restarted.practiceOrder == .specific(.setAnalog), "the last practice time and exercise stay selected")
        expect(restarted.dayPartSchedule == DinoDayPartSchedule(night: 23, morning: 7, afternoon: 12, evening: 18), "the school day-part timetable survives restart")
        memory.set("retired", forKey: "dino.settings.practiceTime")
        memory.set("retiredExercise", forKey: "dino.settings.practiceOrder")
        let unknown = DinoSettings(defaults: memory)
        expect(unknown.practiceTime == .whole && unknown.practiceOrder == .ascending, "unknown practice choices fall back to the default combination")
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
        settings.speakQuestionTitles = true
        settings.highContrastEnabled = true; settings.icloudSyncEnabled = true
        settings.practiceTime = .fiveMinutes; settings.practiceOrder = .mix
        settings.dayPartSchedule = DinoDayPartSchedule(night: 22, morning: 6, afternoon: 12, evening: 17)
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
        expect(restarted.soundEffectsEnabled && restarted.hapticsEnabled && !restarted.speakQuestionTitles && !restarted.highContrastEnabled && !restarted.icloudSyncEnabled,
               "settings return to fresh-install defaults")
        expect(restarted.practiceTime == .whole && restarted.practiceOrder == .ascending, "a full reset also clears the last practice choice")
        expect(restarted.dayPartSchedule == .standard, "a full reset restores the built-in day-part timetable")
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
        normalBoss.recordCompletedAttempt(levelID: 10, correct: 6)
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
