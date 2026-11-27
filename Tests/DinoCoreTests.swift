import Foundation
import CoreGraphics
import ImageIO
import Combine

#if !canImport(UIKit)
// The command-line suite exercises settings persistence on macOS. Actual
// playback remains in the iOS app and simulator tests.
@MainActor
final class DinoAnswerFeedback {
    static let shared = DinoAnswerFeedback()
    nonisolated func setSoundEnabled(_ enabled: Bool) {}
}
#endif

private var checks = 0
private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    checks += 1
    guard condition() else { fatalError("FAILED: \(message)") }
}

@main
@MainActor
struct DinoCoreTests {
    static func testGameLayout() {
        for size in [CGSize(width: 1024, height: 724), CGSize(width: 1376, height: 984),
                     CGSize(width: 750, height: 354)] {
            expect(DinoGameLayout.usesSideHUD(in: size), "tablet questions and short landscape windows reserve a left HUD rail")
        }
        for size in [CGSize(width: 768, height: 980), CGSize(width: 834, height: 1150),
                     CGSize(width: 390, height: 763), CGSize(width: 507, height: 1150),
                     CGSize(width: 699, height: 900), CGSize(width: 700, height: 549)] {
            expect(!DinoGameLayout.usesSideHUD(in: size), "narrow portrait and split-view windows retain their question width")
        }
        expect(DinoGameLayout.sideHUDScale(in: CGSize(width: 1024, height: 724)) > 1.6,
               "tablet landscape enlarges the entire HUD to match the lesson")
        expect(DinoGameLayout.sideHUDScale(in: CGSize(width: 1376, height: 984)) == 2.1,
               "large tablets cap HUD magnification to leave room for the question")
        expect(DinoGameLayout.sideHUDScale(in: CGSize(width: 750, height: 354)) == 1,
               "short phone windows retain the compact rail")
        for width in stride(from: 320, through: 1400, by: 37) {
            for height in stride(from: 320, through: 1400, by: 43) {
                let size = CGSize(width: CGFloat(width), height: CGFloat(height))
                let lesson = DinoDemonstrationLayout.fitting(size)
                expect(lesson.width + lesson.padding * 2 <= size.width, "example card fits the window width")
                expect(lesson.height <= size.height, "example card fits the safe-area height")
                expect(lesson.faceSize > 0 && lesson.readingWidth > 0, "example clocks have positive native sizes")
                if lesson.sideBySide {
                    expect(lesson.spacious, "only roomy lessons use two columns")
                }
            }
        }
        let portraitLesson = DinoDemonstrationLayout.fitting(CGSize(width: 834, height: 1150))
        let landscapeLesson = DinoDemonstrationLayout.fitting(CGSize(width: 1194, height: 790))
        let splitLesson = DinoDemonstrationLayout.fitting(CGSize(width: 507, height: 1150))
        let largeLandscapeLesson = DinoDemonstrationLayout.fitting(CGSize(width: 1376, height: 984))
        expect(largeLandscapeLesson.sideBySide, "13-inch landscape uses the lesson viewport after reserving its fixed actions")
        expect(portraitLesson.spacious && !portraitLesson.sideBySide && portraitLesson.faceSize >= 280,
               "portrait iPad gives the clocks a larger, vertical composition")
        expect(landscapeLesson.sideBySide && landscapeLesson.digitalFont > 44,
               "landscape iPad reflows clocks and controls into columns")
        expect(!splitLesson.spacious && splitLesson.width == 380,
               "narrow split view retains the phone composition")
        // These intermediate proposals used to produce a negative diameter/height
        // in the actual time-reading view, even though final device sizes fitted.
        let proposals: [CGFloat] = [-100, -1, 0, 1, 15, 16, 24, 51, 52, 53, 280, 370, 1024, .nan, .infinity, -.infinity]
        for width in proposals {
            for face in [CGFloat(-52), 0, 210, .nan, .infinity] {
                for mode in 0..<3 {
                    for shape in [AnalogClockShape.circle, .square, .octagon] {
                        for language in ["nl", "en"] {
                            for minute in [0, 17, 30, 59] {
                                let clock = DinoTimeReadingClockLayout(width: width, faceSize: face, minute: minute,
                                    language: language, shape: shape, showsGuide: mode == 2, showsSpokenHint: mode == 1)
                                expect([clock.width, clock.diameter, clock.height, clock.center.x, clock.center.y]
                                    .allSatisfy { $0.isFinite && $0 > 0 },
                                       "temporary layout proposals cannot create invalid time-reading frames")
                            }
                        }
                    }
                }
            }
        }
        let reading = DinoTimeReadingClockLayout(width: 370, faceSize: 210, minute: 0, language: "nl",
                                                 shape: .circle, showsGuide: false, showsSpokenHint: false)
        expect(reading.width == 370 && reading.diameter == 210 && reading.height == 234,
               "valid time-reading sizes retain their existing proportions")
        // Sweep continuous window sizes, including narrow split views and short landscape windows.
        for width in stride(from: 280, through: 1400, by: 37) {
            for height in stride(from: 160, through: 1100, by: 43) {
                for kind in ClockQuestionKind.allCases {
                    let layout = DinoGameLayout(width: CGFloat(width), height: CGFloat(height), kind: kind, optionCount: 4)
                    expect(layout.clockSize.isFinite && layout.clockSize > 0, "finite positive clock size")
                    expect(layout.answerWidth > 0 && layout.contextWidth > 0, "positive content widths")
                    expect(!layout.hasSideContext && !layout.pairedClocks, "questions keep context and input in one column")
                    if layout.hasSideContext {
                        expect(layout.contextWidth + layout.answerWidth + layout.spacing <= CGFloat(width) + 0.01,
                               "columns stay inside the available width")
                    }
                    let columns = layout.answerColumns()
                    expect(columns == 2 || columns == 4, "four choices form two rows or one row")
                    expect(layout.answerClockSize + 24 <= (layout.answerWidth - layout.spacing * CGFloat(columns - 1)) / CGFloat(columns) + 0.01,
                           "answer clocks fit their stones")
                }
            }
        }
        expect(DinoGameLayout.contentWidth(availableWidth: 820, playHeight: 900, spacious: true) == 820,
               "tall tablet lessons use the available width")
        expect(DinoGameLayout.contentWidth(availableWidth: 1100, playHeight: 500, spacious: true) == 700,
               "shorter tablet lessons grow within their height budget")
        expect(DinoGameLayout.contentWidth(availableWidth: 820, playHeight: 350, spacious: false) == 620,
               "compact lessons retain their previous width limit")
        for kind in [ClockQuestionKind.chooseDigital, .trueFalse, .readDigital] {
            let phone = DinoGameLayout(width: 370, height: 600, kind: kind, optionCount: 4)
            let tablet = DinoGameLayout(width: 1000, height: 1000, kind: kind, optionCount: 4)
            let short = DinoGameLayout(width: 700, height: 160, kind: kind, optionCount: 4)
            expect(abs(phone.clockSize - 210) < 0.01, "reading clock keeps familiar phone proportions")
            expect(tablet.clockSize >= 400 && tablet.clockSize <= 470,
                   "tablet reading clocks use the available space within their height budget")
            expect(short.clockSize < phone.clockSize, "a preferred clock still yields to short windows")
        }
        let digitalChoice = DinoGameLayout(width: 880, height: 950, kind: .chooseDigital, optionCount: 2)
        expect(digitalChoice.answerWidth == 660 && digitalChoice.clockSize > 400,
               "two digital answers stay compact under a prominent reading clock")
        let analogChoice = DinoGameLayout(width: 880, height: 950, kind: .chooseAnalog, optionCount: 2)
        let fourAcross = DinoGameLayout(width: 880, height: 490, kind: .chooseAnalog, optionCount: 4)
        expect(analogChoice.targetDigitalFont >= 75 && analogChoice.answerReadoutFont >= 42,
               "large analog tiles get a readable target and rejected time")
        expect(fourAcross.answerColumns() == 4 && fourAcross.answerReadoutFont < analogChoice.answerReadoutFont,
               "the rejected time fits the individual card, including four across")
        expect(DinoQuestionClockMetrics.verdictDiameter(in: analogChoice.answerCellWidth) > 40
               && DinoQuestionClockMetrics.verdictDiameter(in: fourAcross.answerCellWidth) <= 30,
               "verdicts stay proportional to the card and fit its corner")
        expect(DinoQuestionClockMetrics.digitalHintScale(font: 38, spacious: false) == 1
               && DinoQuestionClockMetrics.digitalHintScale(font: analogChoice.targetDigitalFont, spacious: true) > 1.5,
               "the numbers follow the larger display while preserving phone proportions")
        expect(ClockHandHintGeometry.badgeScale(faceSize: 320, spacious: true) == 1.65,
               "large analog hints grow within a bounded envelope")
        let journey = DinoGameLayout(width: 880, height: 950, kind: .daySchedule, optionCount: 4)
        expect(journey.contextMagnification > 1 && journey.contextMagnification <= 1.5,
               "illustrated lessons enlarge as a unit")
        expect(DinoQuestionFeedbackTiming.revealDelay >= DinoQuestionFeedbackTiming.layout,
               "new explanation waits for the existing content to finish moving")
        expect(DinoQuestionFeedbackTiming.replacementFadeOut < DinoQuestionFeedbackTiming.revealDelay,
               "old and corrected reference clocks are never crossfaded over one another")
        expect(DinoQuestionFeedbackTiming.inputRevealDelay >= DinoQuestionFeedbackTiming.controlExit + DinoQuestionFeedbackTiming.layout,
               "digital reading pointers wait for the controls to leave and the submitted clock to settle")
        let portrait = DinoGameLayout(width: 370, height: 500, kind: .timeSequence, optionCount: 4)
        let landscape = DinoGameLayout(width: 720, height: 220, kind: .timeSequence, optionCount: 4)
        expect(!portrait.horizontalSequence && landscape.horizontalSequence, "sequence reflows with available aspect ratio")
        expect(portrait.answerColumns() == 2 && landscape.answerColumns() == 4, "choices reflow on phones too")
    }

    static func main() async {
        if CommandLine.arguments.contains("--brazilian-portuguese-localization") {
            testBrazilianPortugueseLocalization()
            print("PASS: \(checks) Brazilian Portuguese localization checks.")
            return
        }
        if CommandLine.arguments.contains("--european-portuguese-localization") {
            testEuropeanPortugueseLocalization()
            print("PASS: \(checks) European Portuguese localization checks.")
            return
        }
        if CommandLine.arguments.contains("--mexican-spanish-localization") {
            testMexicanSpanishLocalization()
            print("PASS: \(checks) Mexican Spanish localization checks.")
            return
        }
        if CommandLine.arguments.contains("--spanish-localization") {
            testSpanishLocalization()
            print("PASS: \(checks) Spanish localization checks.")
            return
        }
        if CommandLine.arguments.contains("--canadian-french-localization") {
            testCanadianFrenchLocalization()
            print("PASS: \(checks) Canadian French localization checks.")
            return
        }
        if CommandLine.arguments.contains("--french-localization") {
            testFrenchLocalization()
            print("PASS: \(checks) French localization checks.")
            return
        }
        if CommandLine.arguments.contains("--urdu-localization") {
            testUrduLocalization()
            print("PASS: \(checks) Pakistani Urdu localization checks.")
            return
        }
        if CommandLine.arguments.contains("--hebrew-localization") {
            testHebrewLocalization()
            print("PASS: \(checks) Hebrew localization checks.")
            return
        }
        if CommandLine.arguments.contains("--traditional-chinese-localization") {
            testChineseLocalization(profile: .traditionalChinese)
            print("PASS: \(checks) Traditional Chinese localization checks.")
            return
        }
        if CommandLine.arguments.contains("--simplified-chinese-localization") {
            testChineseLocalization(profile: .simplifiedChinese)
            print("PASS: \(checks) Simplified Chinese localization checks.")
            return
        }
        if CommandLine.arguments.contains("--japanese-localization") {
            testJapaneseLocalization()
            print("PASS: \(checks) Japanese localization checks.")
            return
        }
        if CommandLine.arguments.contains("--arabic-localization") {
            testArabicLocalization()
            print("PASS: \(checks) Saudi Arabic localization checks.")
            return
        }
        if CommandLine.arguments.contains("--australian-localization") {
            testAustralianLocalization()
            print("PASS: \(checks) Australian English localization checks.")
            return
        }
        if CommandLine.arguments.contains("--canadian-localization") {
            testCanadianLocalization()
            print("PASS: \(checks) Canadian English localization checks.")
            return
        }
        if CommandLine.arguments.contains("--german-localization") {
            testGermanLocalization()
            print("PASS: \(checks) German localization checks.")
            return
        }
        if CommandLine.arguments.contains("--localization") {
            testLocalizationBaseline()
            testLocalizationInfrastructure()
            testSpokenTime()
            print("PASS: \(checks) localization checks.")
            return
        }
        if CommandLine.arguments.contains("--time-machine") {
            testMachineCharacter()
            print("PASS: \(checks) time-machine character checks.")
            return
        }
        if CommandLine.arguments.contains("--characters") {
            testCharacterUnlocks()
            testJungleMotion()
            testDesertCharacter()
            testVolcanoCharacter()
            testVillageCharacter()
            testCaveCharacter()
            testNeonCharacter()
            testDommelCharacter()
            testMachineCharacter()
            testPirateCharacter()
            testCastleCharacter()
            print("PASS: \(checks) character unlock, swap and save checks.")
            return
        }
        if CommandLine.arguments.contains("--minute-rules") {
            testMinuteQuestionRules()
            print("PASS: \(checks) minute question rules checks.")
            return
        }
        if CommandLine.arguments.contains("--game-layout") {
            testGameLayout()
            print("PASS: \(checks) adaptive game layout checks.")
            return
        }
        if CommandLine.arguments.contains("--clock-arithmetic") {
            testClockArithmetic()
            testClockArithmeticDisplay()
            print("PASS: \(checks) clock arithmetic checks.")
            return
        }
        if CommandLine.arguments.contains("--map-viewport") {
            testMapAnimationViewport()
            print("PASS: \(checks) map viewport checks.")
            return
        }
        if CommandLine.arguments.contains("--question-prompts") {
            testQuestionPrompts()
            print("PASS: \(checks) question prompt checks.")
            return
        }
        if CommandLine.arguments.contains("--flight-arrivals") {
            testFlightArrivals()
            testCapitalTimeZones()
            print("PASS: \(checks) flight and shared time-route checks.")
            return
        }
        if CommandLine.arguments.contains("--time-zones") {
            testCapitalTimeZones()
            print("PASS: \(checks) time-zone calculation, animation and layout checks.")
            return
        }
        if CommandLine.arguments.contains("--clock-reading-hints") {
            testHandHintClearance()
            testClockReadingAssistance()
            testSpokenClockReadingHints()
            testHandSelection()
            print("PASS: \(checks) clock reading assistance checks.")
            return
        }
        if CommandLine.arguments.contains("--spoken-clock-guides") {
            testClockReadingAssistance()
            testSpokenClockReadingHints()
            print("PASS: \(checks) spoken clock guide checks.")
            return
        }
        if CommandLine.arguments.contains("--animation-timing") {
            testAssetCatalog()
            testAnimation()
            testVolcanoMotion()
            testVillageMotion()
            testCaveMotion()
            testNeonMotion()
            testDommelMotion()
            testMachineMotion()
            testPirateMotion()
            testCastleMotion()
            print("PASS: \(checks) animation timing and asset checks.")
            return
        }
        if CommandLine.arguments.contains("--animation") {
            testAssetCatalog()
            testAnimation()
            testDinoAvatarMask()
            testDinoSpriteColors()
            testPaleBandanaLettering()
            print("PASS: \(checks) animation, asset and color checks.")
            return
        }
        if CommandLine.arguments.contains("--time-reading") {
            testTimeReadingClock()
            testTimeReadingReview()
            testAnswerRetries()
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
        if CommandLine.arguments.contains("--train-durations") {
            testDaySchedules()
            print("PASS: \(checks) train duration checks.")
            return
        }
        if CommandLine.arguments.contains("--minute-intervals") {
            testMinutesBetweenQuestions()
            print("PASS: \(checks) minute interval and timeline checks.")
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
        testGameLayout()
        testLevelCurriculum()
        testAdaptiveDifficulty()
        testMinuteQuestionRules()
        testQuestionVariation()
        testClocks()
        testBossClockMotion()
        testHandSelection()
        testHandHintClearance()
        testClockReadingAssistance()
        testSpokenClockReadingHints()
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
        testTimeReadingReview()
        testPlausibleChoices()
        testSpokenTime()
        testLocalizationBaseline()
        testLocalizationInfrastructure()
        testGermanLocalization()
        testCanadianLocalization()
        testAustralianLocalization()
        testArabicLocalization()
        testJapaneseLocalization()
        testChineseLocalization(profile: .simplifiedChinese)
        testChineseLocalization(profile: .traditionalChinese)
        testHebrewLocalization()
        testUrduLocalization()
        testFrenchLocalization()
        testCanadianFrenchLocalization()
        testSpanishLocalization()
        testMexicanSpanishLocalization()
        testEuropeanPortugueseLocalization()
        testBrazilianPortugueseLocalization()
        testFlightArrivals()
        testMinutesBetweenQuestions()
        testClockArithmetic()
        testClockArithmeticDisplay()
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
        testCharacterUnlocks()
        testJungleMotion()
        testDesertCharacter()
        testVolcanoCharacter()
        testVillageCharacter()
        testCaveCharacter()
        testNeonCharacter()
        testMachineCharacter()
        testPirateCharacter()
        testCastleCharacter()
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
        expect(DinoTimeWords.time(.init(hour: 3, minute: 1), language: "nl") == "1 over drie", "Dutch clock descriptions omit the minute unit")
        expect(DinoTimeWords.time(.init(hour: 3, minute: 59), language: "nl") == "1 voor vier", "late Dutch minutes refer to the next hour")
        expect(DinoTimeWords.time(.init(hour: 3, minute: 1), language: "en") == "1 past three", "English clock descriptions omit the minute unit")
        expect(DinoTimeWords.time(.init(hour: 3, minute: 59), language: "en") == "1 to four", "late English minutes refer to the next hour")
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
                    if q.kind == .advanceAnalog {
                        expect(q.durationMinutes >= 2 * category.time.minuteStep,
                               "question 13 requires at least two selected time units at every difficulty")
                    }
                    if [.addTime, .subtractTime].contains(q.kind) {
                        expect(!q.options.contains(q.relatedTimes[0]),
                               "addition and subtraction choices never repeat the reference time in any category")
                    }
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
                        let limit = category.difficulty == .introduction ? max(2, category.time.minuteStep) : category.difficulty == .familiar ? 90 : 180
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
            expect(steps.dropLast().allSatisfy { $0.time.minute == 0 },
                   "a half-hour zone shift bridges to a whole hour before counting the remaining hours")
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
        let approaching = CGRect(x: 0, y: 900, width: 390, height: 100)
        expect(DinoMapViewport.preparesAnimation(frame: approaching, viewportHeight: 852), "nearby effects are still prepared")
        expect(!DinoMapViewport.isVisible(frame: approaching, viewportHeight: 852), "prepared offscreen effects do not keep ticking")
        expect(DinoMapViewport.isVisible(frame: approaching.offsetBy(dx: 0, dy: -49), viewportHeight: 852),
               "the first visible pixel enables normal animation")
        expect(!DinoMapViewport.isVisible(frame: .zero, viewportHeight: 852), "unlaid-out effects do not tick")
        for viewport: CGFloat in [568, 852, 1194, 1366] {
            let margin = max(1800, viewport * 3)
            let incoming = CGRect(x: 0, y: viewport + margin - 1, width: 390, height: 2200)
            expect(DinoMapViewport.preparesScenery(frame: incoming, viewportHeight: viewport, retained: false),
                   "terrain prepares at the original three-screen boundary")
            let justOutside = incoming.offsetBy(dx: 0, dy: 2)
            expect(!DinoMapViewport.preparesScenery(frame: justOutside, viewportHeight: viewport, retained: false),
                   "distant chapters are not eagerly constructed")
            expect(DinoMapViewport.preparesScenery(frame: justOutside, viewportHeight: viewport, retained: true),
                   "a reverse drag at the boundary retains prepared scenery")
            expect(!DinoMapViewport.preparesScenery(frame: incoming.offsetBy(dx: 0, dy: viewport + 513),
                                                  viewportHeight: viewport, retained: true),
                   "distant retained chapters are eventually released")
        }
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
            let demonstrationBounds = ClockHandHintGeometry.demonstrationBounds(shape: shape)
            expect(abs(demonstrationBounds.midX) < 0.000_001 && abs(demonstrationBounds.midY) < 0.000_001,
                   "example envelopes keep the clock face centred at every hand position")
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
                    let hourAngle = Double(hour % 12) * 30
                    let hourTip = pointers[0].tip
                    let numeral = ClockHandHintGeometry.point(radius: 0.34, angle: hourAngle)
                    let hourPointer = pointers[0]
                    let route = CGPoint(x: hourTip.x - hourPointer.badge.x, y: hourTip.y - hourPointer.badge.y)
                    let target = CGPoint(x: numeral.x - hourPointer.badge.x, y: numeral.y - hourPointer.badge.y)
                    expect(abs(route.x * target.y - route.y * target.x) < 0.000_001
                           && route.x * target.x + route.y * target.y > 0,
                           "hour pointer aims at the numeral centre, including its side route at \(time.digitalText)")
                    func gap(from point: CGPoint, to label: CGPoint, size: CGSize) -> Double {
                        let dx = abs(point.x - label.x), dy = abs(point.y - label.y)
                        let distance = hypot(dx, dy)
                        let edge = min(dx < 1e-10 ? .infinity : size.width / 2 * distance / dx,
                                       dy < 1e-10 ? .infinity : size.height / 2 * distance / dy)
                        return distance - edge
                    }
                    let hourNumber = time.hour % 12 == 0 ? 12 : time.hour % 12
                    let hourLabelSize = CGSize(width: Double(String(hourNumber).count) * 0.0525, height: 0.0975)
                    let minuteLabelSize = CGSize(width: Double(String(time.minute).count) * 0.042, height: 0.078)
                    let minuteLabel = ClockHandHintGeometry.minuteMark(minute: time.minute, shape: shape,
                                                                     labelSize: minuteLabelSize).label
                    expect(abs(gap(from: hourTip, to: numeral, size: hourLabelSize)
                               - gap(from: pointers[1].tip, to: minuteLabel, size: minuteLabelSize)) < 0.000_001,
                           "both arrow tips stop the same visible distance from their own numeral")
                    expect(hypot(hourTip.x, hourTip.y) < 0.5,
                           "the longer hour arrow reaches the actual hour numeral inside the face")
                    for pointer in pointers {
                        expect(hypot(pointer.badge.x - pointer.tip.x, pointer.badge.y - pointer.tip.y) >= 0.179_999,
                               "both arrows have a visible shaft beyond their badge and arrowhead")
                    }
                    let minuteDirection = ClockHandHintGeometry.point(radius: 1, angle: time.minuteAngle)
                    let minuteTip = pointers[1].tip
                    expect(abs(minuteTip.x * minuteDirection.y - minuteTip.y * minuteDirection.x) < 0.000_001,
                           "minute pointer follows the exact minute, without rounding to a five")
                    let edge = ClockHandHintGeometry.outerRadius(angle: time.minuteAngle, shape: shape)
                    expect(hypot(minuteTip.x, minuteTip.y) > edge + 0.11,
                           "minute pointer leaves breathing room beyond the outside scale")
                    let expectedMinuteBadge = ClockHandHintGeometry.point(radius: edge + 0.345, angle: time.minuteAngle)
                    expect(hypot(pointers[1].badge.x - expectedMinuteBadge.x, pointers[1].badge.y - expectedMinuteBadge.y) < 0.000_001,
                           "minute badge keeps its radial placement at every time")
                    let expectedHourBadge = ClockHandHintGeometry.point(
                        radius: ClockHandHintGeometry.outerRadius(angle: hourAngle, shape: shape) + 0.345, angle: hourAngle)
                    let nearOverlap = hypot(expectedHourBadge.x - expectedMinuteBadge.x, expectedHourBadge.y - expectedMinuteBadge.y) < 0.235
                    let bounds = ClockHandHintGeometry.bounds(time: time, shape: shape, faceSize: 120)
                    expect(demonstrationBounds.insetBy(dx: -0.000_001, dy: -0.000_001).contains(bounds),
                           "the initial example envelope fits every scale, arrow and badge at \(time.digitalText)")
                    let hourBadgeShift = hypot(pointers[0].badge.x - expectedHourBadge.x, pointers[0].badge.y - expectedHourBadge.y)
                    expect(nearOverlap ? hourBadgeShift > 0.05 : hourBadgeShift < 0.000_001,
                           "hour badge sits behind its minute numeral and only moves aside near the minute badge")
                    for pointer in pointers {
                        for hand in [(time.hourAngle, 0.23, 0.038), (time.minuteAngle, 0.34, 0.024)] {
                            let start = ClockHandHintGeometry.point(radius: -0.035, angle: hand.0)
                            let end = ClockHandHintGeometry.point(radius: hand.1, angle: hand.0)
                            for arrowEdge in [pointer.start] + pointer.arrowWings {
                                let clearance = ClockHandHintGeometry.segmentDistance(arrowEdge, pointer.tip, start, end) - hand.2 / 2
                                expect(clearance > 0.015, "reading arrows stay clear of both hands at \(time.digitalText)")
                            }
                        }
                        let radius = 14.5 / 150.0
                        expect(bounds.minX <= pointer.badge.x - radius && bounds.maxX >= pointer.badge.x + radius
                               && bounds.minY <= pointer.badge.y - radius && bounds.maxY >= pointer.badge.y + radius,
                               "complete number badges fit inside the tight layout bounds")
                    }
                    if nearOverlap {
                        for mark in marks {
                            for arrowEdge in [pointers[0].start] + pointers[0].arrowWings {
                                expect(ClockHandHintGeometry.segmentDistance(arrowEdge, pointers[0].tip, mark.label, mark.label) > 0.055,
                                       "the exceptional side route keeps minute labels clear at \(time.digitalText)")
                            }
                        }
                    }
                    for hourStart in [pointers[0].start] + pointers[0].arrowWings {
                        for minuteStart in [pointers[1].start] + pointers[1].arrowWings {
                            expect(ClockHandHintGeometry.segmentDistance(hourStart, pointers[0].tip,
                                                                        minuteStart, pointers[1].tip) > 0.025,
                                   "both arrowheads and shafts remain separate at \(time.digitalText)")
                        }
                    }
                    for pointer in pointers {
                        for point in [pointer.badge, pointer.tip, pointer.start] + pointer.arrowWings {
                            expect(bounds.contains(point), "tight bounds retain both complete arrows")
                        }
                    }
                    expect(abs(bounds.midX) < 0.000_001,
                           "tight hint bounds keep the clock face horizontally centred")
                    expect(hypot(pointers[0].badge.x - pointers[1].badge.x, pointers[0].badge.y - pointers[1].badge.y) > 0.2,
                           "number badges remain separate at \(time.digitalText)")
                }
            }
        }
        let twelve = ClockHandHintGeometry.pointers(time: .init(hour: 12, minute: 0))
        let twelveSeparation = hypot(twelve[0].badge.x - twelve[1].badge.x, twelve[0].badge.y - twelve[1].badge.y)
        let acceptedHourBadge = ClockHandHintGeometry.point(radius: 0.845, angle: -18)
        expect(hypot(twelve[0].badge.x - acceptedHourBadge.x, twelve[0].badge.y - acceptedHourBadge.y) < 0.000_001,
               "extending the blue arrow keeps the accepted position of badge 1 at twelve")
        expect(twelveSeparation > 0.2 && twelveSeparation < 0.3,
               "at twelve the hour badge sits closer to the minute badge without touching it")
        let horizontal = ClockHandHintGeometry.bounds(time: .init(hour: 3, minute: 45), shape: .circle, faceSize: 120)
        expect(horizontal.height < 1.3,
               "sideways arrows do not reserve their worst-case reach above and below the face")
        for hand in ClockInk.allCases.map(\.hex) + [0x000000, 0xFFFFFF, 0xFFFF00] {
            for face in ClockFace.allCases.map(\.hex) {
                let guide = ClockColorContrast.hourGuideHex(hand: hand, face: face)
                expect(ClockColorContrast.ratio(guide, face) >= 3,
                       "hour return cue remains visible on light, colored and black faces")
                expect(guide != hand, "hour return cue differs from the real hand")
            }
        }
    }

    static func testClockReadingAssistance() {
        expect(DinoPracticeQuestion.allCases.filter { $0.recipe.kind.clockHelpStyle == .numberedHands }.map(\.number) == [1, 2, 7, 8],
               "numbered hand arrows are limited to the four requested exercises")
        expect(DinoPracticeQuestion.allCases.filter { $0.recipe.kind.clockHelpStyle == .spokenTime }.map(\.number) == [3, 4, 5],
               "only the three spoken-time exercises use the speech scale")
        let player = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
        let level = LevelConfiguration(id: 1, worldID: 1, titleKey: "dino.level.1", instructionKey: "dino.question.chooseDigital",
            allowedHours: Array(1...12), difficulty: 1, questionCount: 5, isBoss: false,
            recipes: [.init(kind: .chooseDigital, optionCount: 2)])
        let session = DinoSession(level: level, player: player)
        expect(!session.showsClockHandHints, "new level starts without reading arrows")
        session.submit(session.question.expectedAnswer)
        session.advance()
        expect(!session.showsClockHandHints, "a correct answer does not enable reading arrows")
        session.submit(wrongAnswer(for: session.question))
        expect(session.showsClockHandHints, "the first wrong answer immediately enables reading arrows")
        if session.canRetry { session.showAnswer() }
        session.advance()
        expect(!session.showsClockHandHints && !session.hasFeedback, "the next level question starts without reading arrows")
        session.submit(session.question.expectedAnswer)
        session.advance()
        expect(!session.showsClockHandHints, "a later correct answer does not reactivate an earlier question's help")
        expect(!DinoSession(level: level, player: player).showsClockHandHints, "replaying a level resets reading support")

        let configuration = DinoPracticeConfiguration(time: .quarter, order: .specific(.chooseDigital))
        let practice = DinoSession(level: configuration.level, player: player, practice: configuration)
        practice.submit(wrongAnswer(for: practice.question))
        if practice.canRetry { practice.showAnswer() }
        practice.advance()
        expect(!practice.showsClockHandHints && practice.attempt.answers.isEmpty,
               "practice clears reading support when it replaces the current question")
        practice.submit(wrongAnswer(for: practice.question))
        expect(practice.showsClockHandHints, "another wrong question can activate its own reading help")

        let editable = DinoPracticeConfiguration(time: .quarter, order: .specific(.setAnalog))
        let untouched = DinoSession(level: editable.level, player: player, practice: editable)
        untouched.submit(untouched.answerCheck!.answer)
        expect(!untouched.showsClockHandHints && !untouched.hasFeedback,
               "an untouched-input reminder is not a wrong answer and does not enable help")
    }

    static func testSpokenClockReadingHints() {
        let expectedDutch = ["uur", "5", "10", "kwart", "10", "5", "half", "5", "10", "kwart", "10", "5"]
        let expectedEnglish = ["o’clock", "5", "10", "quarter", "20", "25", "half", "25", "20", "quarter", "10", "5"]
        for (language, expected) in [("nl", expectedDutch), ("en", expectedEnglish)] {
            expect(stride(from: 0, to: 60, by: 5).map { SpokenClockReadingHint(minute: $0, language: language).scaleLabel } == expected,
                   "the complete scale uses the minute counts actually named in \(language)")
            for minute in 0..<60 {
                let hint = SpokenClockReadingHint(minute: minute, language: language)
                expect(hint.scaleMinutes.count == 12 && hint.scaleMinutes.filter { $0 == minute }.count == 1,
                       "the actual minute has one scale label, including exact-minute questions")
                expect(hint.scaleMinutes.filter { $0 != minute }.allSatisfy { $0.isMultiple(of: 5) },
                       "the remaining scale labels keep their five-minute positions")
                expect((0...60).contains(hint.startMinute) && (0...60).contains(hint.endMinute)
                       && hint.startMinute <= hint.endMinute && hint.endMinute - hint.startMinute <= 30,
                       "each speech arrow follows one forward interval inside the face")
                expect(hint.endMinute - hint.startMinute == hint.count, "the arrow length equals the spoken offset")
                expect([hint.startMinute, hint.endMinute].contains(minute), "the arrow connects the actual minute to its spoken reference")
                for shape in [AnalogClockShape.circle, .square, .octagon] {
                    for face in [80.0, 150, 240] {
                        let bounds = SpokenClockGuideLayout.verticalBounds(minute: minute, language: language, shape: shape, faceSize: face)
                        expect(bounds.lowerBound.isFinite && bounds.upperBound.isFinite
                               && bounds.lowerBound < -0.5 && bounds.upperBound > 0.5,
                               "compact speech guides keep the whole face and a safety margin")
                        expect(bounds.upperBound - bounds.lowerBound < SpokenClockGuideLayout.extent(shape: shape) * 2,
                               "speech-guide height trims the former square's excess space")
                        let compact = SpokenClockGuideLayout.verticalBounds(minute: minute, language: language,
                            shape: shape, faceSize: face, compact: true)
                        expect(compact.lowerBound <= -0.5 && compact.upperBound >= 0.5
                               && compact.upperBound - compact.lowerBound <= bounds.upperBound - bounds.lowerBound,
                               "answer-clock guides keep the full face with less reserved space")
                        expect(SpokenClockGuideLayout.extent(shape: shape, compact: true) < SpokenClockGuideLayout.extent(shape: shape),
                               "the compact answer guide gives its clock a larger share of the same width")
                    }
                }
            }
        }
        expect(SpokenClockReadingHint(minute: 30, language: "nl").spokenHour(for: 6) == 7, "half zeven circles seven")
        expect(SpokenClockReadingHint(minute: 15, language: "nl").spokenHour(for: 6) == 6, "kwart over zes circles six")
        expect(SpokenClockReadingHint(minute: 30, language: "en").spokenHour(for: 6) == 6, "half past six circles six")
        expect(SpokenClockReadingHint(minute: 45, language: "en").spokenHour(for: 23) == 12, "quarter to midnight circles twelve")
        expect(SpokenClockGuideLayout.arrowRadius + 0.026 < 0.34 - 0.035,
               "the pronunciation arrow and its tip fit inside the hour numerals")
        for shape in [AnalogClockShape.circle, .square, .octagon] {
            expect(SpokenClockGuideLayout.extent(shape: shape) * 2 < 1.75,
                   "the pronunciation scale gives the clock more width after removing the outside arrow")
        }
        let beforeHalf = SpokenClockReadingHint(minute: 20, language: "nl")
        expect(beforeHalf.scaleLabel == "10" && beforeHalf.startMinute == 20 && beforeHalf.endMinute == 30
               && beforeHalf.relation == "voor half", "Dutch twenty connects ten-before-half to half")
        let past = SpokenClockReadingHint(minute: 20, language: "en")
        expect(past.scaleLabel == "20" && past.startMinute == 0 && past.endMinute == 20
               && past.relation == "past", "English twenty counts forward from the whole hour")
        for (minute, start, end, relation) in [(25, 25, 30, "voor half"), (35, 30, 35, "over half"),
                                              (40, 30, 40, "over half"), (45, 45, 60, "voor"), (55, 55, 60, "voor")] {
            let hint = SpokenClockReadingHint(minute: minute, language: "nl")
            expect(hint.startMinute == start && hint.endMinute == end && hint.relation == relation,
                   "Dutch before/after directions match the phrase around half and whole hours")
        }
        let player = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
        for type in [DinoPracticeQuestion.trueFalse, .readDigital, .spokenTime] {
            let config = DinoPracticeConfiguration(time: .tenMinutes, order: .specific(type))
            var generator = DinoPracticeGenerator(configuration: config, seed: 42)
            let question = generator.next(index: 0)
            let session = DinoSession(level: config.level, player: player, practice: config, example: question)
            expect(!session.showsSpokenClockHints && !session.showsClockHandHints, "speech help stays hidden before a miss")
            session.submit(wrongAnswer(for: question))
            expect(session.showsSpokenClockHints && !session.showsClockHandHints,
                   "a spoken-time mistake activates its unnumbered guide and never the hand arrows")
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
        expect(forward.walkMinutes() == [60, 120, 180, 240, 300, 360], "the flight adds each hour separately from 08:15")
        expect(sameZone.walkMinutes() == [30, 90, 150], "a same-zone flight reaches 10:00 before adding each remaining hour")
        for shift in [-175, -115, -35, 0, 5, 30, 35, 55, 85, 115, 145, 175] {
            let start = ClockTime(hour: 23, minute: 40)
            let work = DinoFlightArrivalWork(departure: start, durationMinutes: 240, offsetMinutes: shift - 240,
                                             arrival: start.adding(minutes: shift))
            let sharedSteps = DinoTimeZoneStep.steps(from: start, offsetMinutes: shift)
            expect(work.walkMinutes() == sharedSteps.map(\.addedMinutes), "flights share the train and time-zone route in both directions")
            expect(sharedSteps.last?.time == (shift == 0 ? nil : work.arrival), "the flight route ends at the exact arrival across midnight")
        }
        let rounded = DinoFlightArrivalWork(departure: .init(hour: 23, minute: 40), durationMinutes: 235,
                                            offsetMinutes: -120, arrival: .init(hour: 1, minute: 35))
        expect(rounded.walkMinutes() == [20, 80, 115], "a flight from 23:40 reaches midnight, then 01:00, then 01:35")
        let removed = DinoFlightArrivalWork(departure: .init(hour: 10), durationMinutes: 60,
                                            offsetMinutes: -180, arrival: .init(hour: 8))
        expect(removed.combinedMinutes == -120 && removed.walkMinutes() == [-60, -120], "subtraction removes one hour at a time")
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
        let timelines: [(ClockTime, ClockTime, [Int])] = [
            (.init(hour: 13, minute: 30), .init(hour: 15), [30, 60]),
            (.init(hour: 8), .init(hour: 10, minute: 30), [60, 60, 30]),
            (.init(hour: 13, minute: 45), .init(hour: 15, minute: 15), [15, 60, 15]),
            (.init(hour: 8, minute: 10), .init(hour: 8, minute: 40), [15, 15]),
            (.init(hour: 8), .init(hour: 9), [15, 15, 15, 15]),
            (.init(hour: 8), .init(hour: 8, minute: 45), [15, 15, 15]),
            (.init(hour: 8, minute: 15), .init(hour: 8, minute: 30), [5, 10]),
            (.init(hour: 23, minute: 58), .init(hour: 23, minute: 59), [1])
        ]
        for (start, end, expected) in timelines {
            let timeline = DinoMinuteTimeline(start, end)
            expect(timeline.times.first == start && timeline.times.last == end, "timeline preserves both endpoints")
            expect(timeline.segments == expected, "timeline chooses whole hours, quarters or a useful midpoint")
            expect(timeline.colorGroups.count == expected.count, "each minute block receives a color")
            for first in expected.indices {
                for second in expected.indices {
                    expect((timeline.colorGroups[first] == timeline.colorGroups[second]) == (expected[first] == expected[second]),
                           "equal amounts share a color and different amounts have different colors")
                }
            }
        }
        expect(DinoMinuteTimeline(.init(hour: 8), .init(hour: 10, minute: 30)).colorGroups == [0, 0, 1],
               "both 60-minute blocks are blue and the 30-minute block is green")
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
                let timeline = DinoMinuteTimeline(start, end)
                expect(timeline.segments.allSatisfy { $0 > 0 } && timeline.segments.reduce(0, +) == elapsed,
                       "every timeline uses positive steps that add to the exact interval")
                expect(timeline.times.count <= 5, "at most four steps keep the compact timeline readable")
                expect(q.responses.count == 4 && Set(q.responses).count == 4, "four distinct minute totals")
                expect(q.responses.filter { AnswerValidator.isCorrect($0, for: q) }.count == 1, "exactly one correct minute total")
                expect(q.responses.allSatisfy { if case .duration(let m) = $0 { return m > 0 }; return false }, "every choice is a positive number of minutes")
                crossedHour = crossedHour || start.hour != end.hour
            }
            expect(crossedHour, "minute differences include hour changes for every time family")
        }
    }

    static func testClockArithmeticDisplay() {
        func shown(_ hour: Int, _ minute: Int, _ duration: Int, _ adding: Bool,
                   _ notation: DigitalHourNotation) -> DinoClockArithmeticDisplay {
            .init(work: .init(start: .init(hour: hour, minute: minute), durationMinutes: duration, adding: adding), notation: notation)
        }
        let midnight = shown(23, 50, 20, true, .twentyFour)
        expect(midnight.hourCarry == 1 && midnight.hourWrap == -24,
               "midnight keeps +1 and -24 separate instead of combining them into -23")
        let previousDay = shown(0, 5, 10, false, .twentyFour)
        expect(previousDay.hourCarry == -1 && previousDay.hourWrap == 24,
               "borrowing across midnight keeps -1 and +24 separate")
        let noon = shown(11, 50, 20, true, .twelve)
        expect(noon.startHour == 11 && noon.resultHour == 12 && noon.hourCarry == 1 && noon.hourWrap == 0 && noon.changesPeriod,
               "11:50 AM becomes 12:10 PM without a spurious twelve-hour subtraction")
        let twelveMidnight = shown(23, 50, 20, true, .twelve)
        expect(twelveMidnight.resultHour == 12 && twelveMidnight.hourWrap == 0 && twelveMidnight.changesPeriod,
               "11:50 PM becomes 12:10 AM, not zero o'clock")
        let onePM = shown(12, 30, 60, true, .twelve)
        expect(onePM.startHour == 12 && onePM.hourSubtotal == 13 && onePM.hourWrap == -12 && onePM.resultHour == 1 && !onePM.changesPeriod,
               "12:30 PM to 1:30 PM wraps the displayed hour while staying PM")
        let oneAM = shown(0, 30, 60, true, .twelve)
        expect(oneAM.startHour == 12 && oneAM.hourWrap == -12 && oneAM.resultHour == 1 && !oneAM.changesPeriod,
               "12:30 AM to 1:30 AM uses the same dial correction while staying AM")
        let beforeNoon = shown(12, 5, 10, false, .twelve)
        expect(beforeNoon.resultHour == 11 && beforeNoon.hourCarry == -1 && beforeNoon.hourWrap == 0 && beforeNoon.changesPeriod,
               "12:05 PM minus ten minutes is 11:55 AM")
        let zeroHour = shown(1, 5, 10, false, .twelve)
        expect(zeroHour.resultHour == 12 && zeroHour.hourCarry == -1 && zeroHour.hourWrap == 12 && !zeroHour.changesPeriod,
               "a zero displayed hour becomes 12 without incorrectly flipping AM/PM")
        expect(shown(3, 5, 10, true, .twentyFour).hourEquation == "3 + 0 = 3",
               "arithmetic numbers do not contain placeholder zeroes")
        for startMinute in 0..<1440 {
            let start = ClockTime(hour: startMinute / 60, minute: startMinute % 60)
            for duration in [0, 1, 10, 59, 60, 70, 90, 720, 1440, 1501] {
                for adding in [false, true] {
                    let work = DinoClockArithmetic(start: start, durationMinutes: duration, adding: adding)
                    let expected = start.adding(minutes: adding ? duration : -duration)
                    for notation in DigitalHourNotation.allCases {
                        let display = DinoClockArithmeticDisplay(work: work, notation: notation)
                        let expectedHour = notation == .twelve ? (expected.hour + 11) % 12 + 1 : expected.hour
                        expect(display.resultHour == expectedHour, "displayed result agrees with the real time")
                        expect(display.hourSubtotal + display.hourCarry + display.hourWrap == expectedHour,
                               "each separate hour correction leads to the displayed result")
                        expect(display.minuteSubtotal + display.minuteCorrection == expected.minute,
                               "minute correction leads to the real minute")
                        expect(display.hourWrap.isMultiple(of: notation == .twelve ? 12 : 24),
                               "dial correction respects the chosen clock cycle")
                        expect(display.changesPeriod == (notation == .twelve && start.hour / 12 != expected.hour / 12),
                               "AM/PM follows actual noon/midnight, including long durations")
                    }
                }
            }
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
        expect(DinoPracticeTime.whole.analogHandStep == 60, "whole-hour questions keep minute input disabled")
        for family in DinoPracticeTime.allCases where family != .whole {
            expect(family.analogHandStep == (family == .minutes ? 1 : 5),
                   "analog hands use five-minute steps except for exact-minute questions: \(family)")
        }
        for family in DinoPracticeTime.allCases {
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
                    if [.addTime, .subtractTime].contains(kind) {
                        expect(!q.options.contains(q.relatedTimes[0]),
                               "addition and subtraction examples never offer the reference time")
                    }
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
                        let requested = ClockTime(hour: hour, minute: minute)
                        let question = DinoExpandedQuestions.generate(kind: .read24Hour, minutes: time.minutes,
                            minuteStep: time.minuteStep, index: 0, previousTarget: nil, preferredTarget: requested,
                            difficulty: difficulty, using: &rng)
                        let target = question.target
                        expect(target.hour > 12 && time.minutes.contains(target.minute),
                               "after-noon reading rejects morning and noon targets in every minute family and difficulty")
                        expect((hour <= 12 || target == requested) && question.options.count == difficulty.optionCount,
                               "after-noon choices retain eligible requested times and the full answer grid")
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
            var seenHours: Set<Int> = []
            for index in 0..<(11 * time.minutes.count) {
                let example = DinoDemonstrationExamples.question(kind: .read24Hour, minutes: time.minutes,
                    minuteStep: time.minuteStep, index: index, previousTarget: nil)
                expect(example.target.hour > 12 && time.minutes.contains(example.target.minute),
                       "after-noon examples stay after twelve and on the selected minute grid")
                seenHours.insert(example.target.hour)
            }
            expect(seenHours == Set(13...23), "after-noon examples cycle every eligible hour")
        }
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
        let animationCases: [(ClockTime, Int, [Int])] = [
            (.init(hour: 23, minute: 40), 0, []),
            (.init(hour: 23, minute: 40), 5, [5]),
            (.init(hour: 23, minute: 40), 20, [20]),
            (.init(hour: 23, minute: 40), 115, [20, 80, 115]),
            (.init(hour: 23, minute: 40), -5, [-5]),
            (.init(hour: 23, minute: 40), -40, [-40]),
            (.init(hour: 23, minute: 40), -115, [-40, -100, -115]),
            (.init(hour: 0, minute: 10), -45, [-10, -45]),
            (.init(hour: 23, minute: 50), 45, [10, 45]),
            (.init(hour: 10), 120, [60, 120]),
            (.init(hour: 10), -120, [-60, -120]),
            (.init(hour: 14, minute: 40), 120, [60, 120]),
            (.init(hour: 14, minute: 40), -120, [-60, -120]),
            (.init(hour: 14, minute: 40), 135, [20, 80, 135]),
            (.init(hour: 14, minute: 40), -135, [-40, -100, -135]),
            (.init(hour: 10, minute: 30), 1440, Array(stride(from: 60, through: 1440, by: 60))),
            (.init(hour: 10, minute: 30), -1440, Array(stride(from: -60, through: -1440, by: -60)))
        ]
        for (start, offset, expected) in animationCases {
            let steps = DinoTimeZoneStep.steps(from: start, offsetMinutes: offset)
            expect(steps.map(\.addedMinutes) == expected, "the shared replay reaches the next whole hour in its direction before finishing")
            expect(steps.allSatisfy { $0.time == start.adding(minutes: $0.addedMinutes) },
                   "each difference updates its clock by exactly the same amount across midnight")
        }
        for minute in 0..<60 {
            for offset in [-151, -120, -60, -45, -1, 0, 1, 45, 60, 120, 151] {
                let start = ClockTime(hour: 0, minute: minute)
                let steps = DinoTimeZoneStep.steps(from: start, offsetMinutes: offset)
                expect(offset.isMultiple(of: 60) || steps.dropLast().allSatisfy { $0.time.minute == 0 },
                       "minute shifts use whole-hour stops between the bridge and final remainder")
                expect(steps.last?.addedMinutes == (offset == 0 ? nil : offset), "the shared route finishes at the exact signed shift")
                if offset != 0 && offset.isMultiple(of: 60) {
                    expect(steps.count == abs(offset) / 60 && steps.allSatisfy { $0.time.minute == start.minute },
                           "whole-hour shifts keep their starting minutes and count each hour separately")
                }
                let changes = [0] + steps.map(\.addedMinutes)
                expect(zip(changes, changes.dropFirst()).allSatisfy {
                    abs($1 - $0) <= 60 && (offset > 0 ? $0 < $1 : $0 > $1)
                }, "each step keeps the same direction and never skips more than an hour")
            }
        }
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
                    expect((q.offsetMinutes.isMultiple(of: 60) || walked.dropLast().allSatisfy { $0.time.minute == 0 }) &&
                           walked.last?.time == q.target, "the example uses whole-hour stops before its exact destination time")
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
                             CGSize(width: 600, height: 184), CGSize(width: 760, height: 184),
                             CGSize(width: 640, height: 330), CGSize(width: 840, height: 400)] {
                    let cardSize = size.height >= 330 ? CGSize(width: 200, height: 108) : CGSize(width: 132, height: 80)
                    let viewport = DinoTimeZoneViewport(journey: journey, size: size)
                    let labels = DinoTimeZoneLabelLayout(origin: viewport.point(reference, size: size),
                                                        destination: viewport.point(destination, size: size), size: size,
                                                        offsetMinutes: journey.offsetMinutes, cardSize: cardSize)
                    let height = cardSize.height
                    let a = CGRect(x: labels.origin.x - labels.width / 2, y: labels.origin.y - height / 2, width: labels.width, height: height)
                    let b = CGRect(x: labels.destination.x - labels.width / 2, y: labels.destination.y - height / 2, width: labels.width, height: height)
                    expect(!a.intersects(b), "capital labels never overlap, including narrow worked examples")
                    for capital in [reference, destination] {
                        let point = viewport.point(capital, size: size)
                        expect(!a.insetBy(dx: -12, dy: -12).contains(point) && !b.insetBy(dx: -12, dy: -12).contains(point),
                               "city labels leave both geographic markers visible: \(reference.id) / \(destination.id), \(size)")
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
        for (legs, dutch, english, digital) in [
            ([40, 30, 50], "120 min", "120 min", "02:00"),
            ([40, 30, 70], "1 uur 80 min", "1h 80 min", "02:20"),
            ([80, 30, 95], "2 uur 85 min", "2h 85 min", "03:25"),
            ([60, 60, 60], "3 uur", "3h", "03:00"),
            ([60, 1, 60], "2 uur 01 min", "2h 01 min", "02:01")
        ] {
            let schedule = DinoDaySchedule(start: .init(hour: 8), firstActivity: .drawing,
                                           firstMinutes: legs[0], breakMinutes: legs[1],
                                           secondActivity: .reading, secondMinutes: legs[2])
            expect(schedule.summedDurationText(language: "nl") == dutch, "Dutch sum keeps the hours and minutes as described on each leg")
            expect(schedule.summedDurationText(language: "en") == english, "English sum keeps the hours and minutes as described on each leg")
            expect(DinoTimeWords.digitalDuration(schedule.totalMinutes) == digital, "the digital total carries minutes into hours")
        }
        expect(DinoTimeWords.digitalDuration(10) == "00:10", "a short duration includes leading zeroes")
        expect(DinoTimeWords.digitalDuration(70) == "01:10", "a leg over an hour uses HH:MM")
        expect(DinoTimeWords.digitalDuration(25 * 60) == "25:00", "elapsed hours do not wrap at midnight")
        expect(DinoTimeWords.compactDuration(hours: 2, minutes: 50, language: "en") == "2h 50 min",
               "the train uses short hour and minute units")
        expect(DinoTimeWords.compactDuration(hours: 1, minutes: 0, language: "en", padMinutes: true) == "1h 00 min",
               "a whole hour keeps two minute zeroes when the sum has minute terms")
        expect(DinoTimeWords.compactDuration(hours: 0, minutes: 5, language: "nl", padMinutes: true) == "05 min",
               "single-minute digits keep their leading zero in the worked column")
        expect(DinoTimeWords.compactDuration(hours: 0, minutes: 0, language: "en", padMinutes: true) == "00 min",
               "the replay starts with placeholder minute zeroes")
        for (minute, legs, expected) in [
            (45, [15, 15, 15], [15, 45]),
            (10, [100, 10, 60], [50, 110, 170]),
            (45, [10, 1, 3], [14]),
            (40, [60, 60, 60], [60, 120, 180]),
            (0, [60, 60, 60], [60, 120, 180])
        ] {
            let schedule = DinoDaySchedule(start: .init(hour: 8, minute: minute), firstActivity: .drawing,
                                           firstMinutes: legs[0], breakMinutes: legs[1],
                                           secondActivity: .reading, secondMinutes: legs[2])
            expect(schedule.walkMinutes() == expected, "the train always moves forward and finishes at its exact duration")
            let hasHours = schedule.totalMinutes >= 60
            for language in ["nl", "en"] {
                let zeroHours = language == "nl" ? "0 uur" : "0h"
                let zero = "+" + [hasHours ? zeroHours : nil, schedule.hasMinuteTerms ? "00 min" : nil]
                    .compactMap { $0 }.joined(separator: " ")
                expect(schedule.addedDurationText(0, language: language) == zero,
                       "the replay starts with every applicable unit visible at zero")
                if hasHours && schedule.hasMinuteTerms {
                    expect(schedule.addedDurationText(60, language: language) == (language == "nl" ? "+1 uur 00 min" : "+1h 00 min"),
                           "minute placeholders stay visible while the hours advance")
                }
            }
        }
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
                let walk = schedule.walkMinutes()
                expect((schedule.totalMinutes.isMultiple(of: 60) || walk.dropLast().allSatisfy {
                    schedule.start.adding(minutes: $0).minute == 0
                }) && walk.last == schedule.totalMinutes && zip([0] + walk, walk).allSatisfy { $0 < $1 && $1 - $0 <= 60 },
                       "all generated train replays count at most one hour per step until their exact total")
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
        expect(SpokenTimeCatalog.language(code: "qaa").code == "en", "an unknown language follows the same English fallback as the interface")
        expect(SpokenTimeCatalog.language(code: "en-Latn-XZ").code == "en" && SpokenTimeCatalog.language(code: "EN").code == "en",
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

    static func testLocalizationBaseline() {
        let examples: [(Int, String, String, Int, Int)] = [
            (0, "zeven uur", "seven o’clock", 0, 0),
            (14, "14 over zeven", "14 past seven", 0, 0),
            (15, "kwart over zeven", "quarter past seven", 0, 0),
            (16, "14 voor half acht", "16 past seven", 30, 0),
            (29, "1 voor half acht", "29 past seven", 30, 0),
            (30, "half acht", "half past seven", 30, 0),
            (31, "1 over half acht", "29 to eight", 30, 60),
            (44, "14 over half acht", "16 to eight", 30, 60),
            (45, "kwart voor acht", "quarter to eight", 60, 60),
            (59, "1 voor acht", "1 to eight", 60, 60)
        ]
        for (minute, dutch, english, dutchReference, englishReference) in examples {
            let time = ClockTime(hour: 7, minute: minute)
            for (code, words, reference) in [("nl", dutch, dutchReference), ("en", english, englishReference)] {
                expect(DinoTimeWords.time(time, language: code) == words, "\(code) describes 07:\(minute) as \(words)")
                let hint = SpokenClockReadingHint(minute: minute, language: code)
                expect(hint.referenceMinute == reference && hint.spokenHour(for: time.hour) == (reference == 0 ? 7 : 8),
                       "\(code) shows the same reference hour in the clock hint")
            }
        }
    }

    static func testLocalizationInfrastructure() {
        testLocalizedSpokenTimeChoices()
        expect(AppLanguage.named("nl") == .dutch && AppLanguage.named("en") == .english,
               "stored language preferences retain their original IDs")
        expect(AppLanguage.named("nl_XZ") == .dutch && AppLanguage.named("EN-Latn-XZ") == .english,
               "device region variants still use their generic translations")
        expect(AppLanguage.dutch.resourceCodes == ["nl", "en"] && AppLanguage.english.resourceCodes == ["en"],
               "missing resources fall back in the same order as missing lessons")
        let englishChoices = ["en", "en-GB", "en-US"]
        expect(AppLanguage.match("en_Latn_US", among: englishChoices, code: \.self) == "en-US"
               && AppLanguage.match("en-AU", among: englishChoices, code: \.self) == "en",
               "regional matches win when available")
        let chineseChoices = ["zh", "zh-Hans", "zh-Hant", "zh-Hant-HK"]
        expect(AppLanguage.match("zh-TW", among: chineseChoices, code: \.self) == "zh-Hant"
               && AppLanguage.match("zh-HK", among: chineseChoices, code: \.self) == "zh-Hant-HK"
               && AppLanguage.match("zh-Hant-CN", among: chineseChoices, code: \.self) == "zh-Hant",
               "the script survives both regional inference and explicit overrides")
        expect(AppLanguage.match("zh-TW", among: ["zh", "zh-Hans"], code: \.self) == nil,
               "Traditional Chinese never falls back to Simplified Chinese by region alone")
        expect(DinoSpeechVoicePicker.preferredLanguageIdentifier(for: "en_US") == "en-US"
               && DinoSpeechVoicePicker.matchesLanguageAndScript("zh-HK", "zh-Hant")
               && !DinoSpeechVoicePicker.matchesLanguageAndScript("zh-CN", "zh-Hant"),
               "voices preserve explicitly requested regions and never switch script silently")
        let clock = ClockTime(hour: 17, minute: 5)
        let taiwan = clock.localizedDigitalReading(notation: .twelve, locale: Locale(identifier: "zh-TW"))
        expect(taiwan.hour == "5" && taiwan.minute == "05" && taiwan.periodBeforeClock
               && taiwan.text.hasPrefix(taiwan.period ?? "invalid"), "the local display can put the day period first")
        let arabic = clock.localizedDigitalReading(notation: .twentyFour, locale: Locale(identifier: "ar-SA"))
        expect(arabic.hour == "١٧" && arabic.minute == "٠٥" && arabic.period == nil,
               "the 24-hour clock uses the selected numbering system")
        let finnish = clock.localizedDigitalReading(notation: .twentyFour, locale: Locale(identifier: "fi-FI"))
        expect(finnish.text == "17.05" && finnish.separator == ".", "the display and accessibility use the same local separator")

        let time = DinoQuestionPrompt.Argument(text: "07:30", emphasis: .plain)
        let direction = DinoQuestionPrompt.Argument(text: "later", emphasis: .forward)
        let ordered = DinoQuestionPrompt.interpolated("%2$@ · %1$@ · 100%%", arguments: [time, direction])
        expect(ordered?.map(\.text).joined() == "later · 07:30 · 100%" && ordered?.first == .argument(direction),
               "the translated argument keeps its emphasis when moved")
        expect(DinoQuestionPrompt.interpolated("%3$@ %@", arguments: [time, direction]) == nil
               && DinoQuestionPrompt.interpolated("%@", arguments: [time, direction]) == nil,
               "invalid indices and omitted arguments fall back to the plain instruction")

        let calendar = Calendar(identifier: .gregorian)
        let winter = calendar.date(from: DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: 2026, month: 1, day: 15))!
        let summer = calendar.date(from: DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: 2026, month: 7, day: 15))!
        let london = DinoTimeZoneJourney.capitals.first { $0.id == "london" }!
        let delhi = DinoTimeZoneJourney.capitals.first { $0.id == "newDelhi" }!
        expect(DinoTimeZoneJourney(origin: london, destination: delhi, date: winter).offsetMinutes == 330
               && DinoTimeZoneJourney(origin: london, destination: delhi, date: summer).offsetMinutes == 270,
               "a journey keeps a single reference date when applying a half-hour zone and daylight saving")
    }

    static func testLocalizedSpokenTimeChoices() {
        for language in AppLanguage.all {
            let code = language.code
            var rng = SeededGenerator(seed: 23)
            var prompts: Set<String> = []
            var readings: Set<String> = []
            for hour in 1...12 {
                for minute in 0..<60 {
                    let time = ClockTime(hour: hour, minute: minute)
                    let prompt = language.spokenTime.prompt(for: time, using: &rng)
                    let hint = SpokenClockReadingHint(minute: minute, language: code)
                    let hourSlot = prompt.slots.firstIndex { $0.id == "hour" }
                    let namedHourID = "h\(hint.spokenHour(for: hour) % 12)"
                    let context = "\(code) word tiles at \(time.digitalText)"
                    expect(prompt.slots.count == prompt.correct.choiceIDs.count
                           && hourSlot.map { prompt.correct.choiceIDs[$0] == namedHourID } == true
                           && prompt.accepts(prompt.correct), "\(context) has a playable answer for the highlighted hour")
                    expect(!prompt.phrase.isEmpty && prompts.insert(prompt.phrase).inserted,
                           "\(context) gives this time its own answer phrase")
                    let reading = DinoTimeWords.time(time, language: code)
                    expect(!reading.isEmpty && readings.insert(reading).inserted,
                           "\(context) gives this time its own spoken reading")
                    for (slot, correct) in zip(prompt.slots, prompt.correct.choiceIDs) {
                        let labels = slot.choices.map { prompt.style.displayedWord($0.word) }
                        expect((1...3).contains(labels.count) && !labels.contains("") && Set(labels).count == labels.count
                               && (correct == SpokenTimeChoice.emptyID || slot.choices.contains { $0.id == correct }),
                               "\(context) shows distinct choices and includes every required word")
                    }
                }
            }
        }
    }

    static func spokenPhrase(_ code: String, hour: Int, minute: Int) -> String {
        var rng = SeededGenerator(seed: 1)
        return SpokenTimeCatalog.language(code: code).prompt(for: ClockTime(hour: hour, minute: minute), using: &rng).phrase
    }

    static func testCanadianLocalization() {
        let profile = AppLanguage.canadianEnglish
        let code = profile.code
        expect(AppLanguage.named("en_CA") == profile && AppLanguage.named("en-Latn-CA") == profile,
               "Canadian English resolves to its regional resources")
        expect(profile.resourceCodes == ["en-CA", "en"] && AppLanguage.named("en") == .english,
               "Canadian text shares the English base and saved generic English stays distinct")
        let canadian = DinoSpeechVoice(identifier: "ca", name: "Canadian", language: "en-CA", quality: 1)
        let british = DinoSpeechVoice(identifier: "gb", name: "British", language: "en-GB", quality: 3)
        expect(DinoSpeechVoicePicker.preferredLanguageIdentifier(for: code) == "en-CA"
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [british, canadian]) == canadian
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [british]) == british,
               "a Canadian voice is preferred, with English speech available as a fallback")

        let examples: [(Int, String, Int)] = [
            (0, "Seven o’clock", 0), (1, "One past seven", 0), (5, "Five past seven", 0),
            (14, "Fourteen past seven", 0), (15, "Quarter past seven", 0), (16, "Sixteen past seven", 0),
            (20, "Twenty past seven", 0), (25, "Twenty-five past seven", 0), (29, "Twenty-nine past seven", 0),
            (30, "Half past seven", 0), (31, "Twenty-nine to eight", 60), (35, "Twenty-five to eight", 60),
            (40, "Twenty to eight", 60), (44, "Sixteen to eight", 60), (45, "Quarter to eight", 60),
            (46, "Fourteen to eight", 60), (55, "Five to eight", 60), (59, "One to eight", 60)
        ]
        for (minute, phrase, reference) in examples {
            let time = ClockTime(hour: 7, minute: minute)
            var rng = SeededGenerator(seed: 42)
            let prompt = profile.spokenTime.prompt(for: time, using: &rng)
            let hint = SpokenClockReadingHint(minute: minute, language: code)
            expect(prompt.phrase == phrase && hint.referenceMinute == reference
                   && hint.spokenHour(for: time.hour) == (reference == 0 ? 7 : 8), "Canadian English teaches and marks 07:\(minute) consistently")
        }
        var rng = SeededGenerator(seed: 34)
        var baseRng = SeededGenerator(seed: 34)
        for hour in 0..<24 {
            for minute in 0..<60 {
                let time = ClockTime(hour: hour, minute: minute)
                let prompt = profile.spokenTime.prompt(for: time, using: &rng)
                let base = SpokenTimeCatalog.language(code: "en").prompt(for: time, using: &baseRng)
                expect(prompt == base && DinoTimeWords.time(time, language: code) == DinoTimeWords.time(time, language: "en"),
                       "Canadian and generic English share the same phrase and answer logic at every minute")
            }
        }
        for (hour, minute, clockHour, period) in [(0, 0, "12", "AM"), (0, 5, "12", "AM"), (12, 0, "12", "PM"),
                                                  (12, 5, "12", "PM"), (17, 5, "5", "PM"), (23, 59, "11", "PM")] {
            let time = ClockTime(hour: hour, minute: minute)
            let reading = time.digitalReading(notation: .twelve, languageCode: code)
            expect(reading.hour == clockHour && reading.period == period && reading.separator == ":"
                   && time.digitalReading(notation: .twentyFour, languageCode: code).text == time.digitalText,
                   "the regional display distinguishes a.m., p.m. and the 24-hour clock")
        }
        expect(ClockTime(hour: 23, minute: 55).adding(minutes: 10) == .init(hour: 0, minute: 5)
               && ClockTime(hour: 0, minute: 5).adding(minutes: -10) == .init(hour: 23, minute: 55), "time arithmetic crosses midnight in both directions")
        for type in DinoPracticeQuestion.allCases {
            for time in DinoPracticeTime.allCases {
                var generator = DinoPracticeGenerator(configuration: .init(time: time, order: .specific(type)), seed: 71, language: code)
                for index in 0..<3 {
                    let question = generator.next(index: index)
                    expect(AnswerValidator.isCorrect(question.expectedAnswer, for: question), "every Canadian practice combination accepts its expected answer")
                    if question.kind == .timeZone { expect(question.timeZoneJourney?.origin.id == "ottawa", "Canadian time-zone exercises start in Ottawa") }
                }
            }
        }

        let ottawa = DinoTimeZoneJourney.capitals.first { $0.id == "ottawa" }!
        let utc = TimeZone(secondsFromGMT: 0)!
        for month in 1...12 {
            let date = Calendar(identifier: .gregorian).date(from: .init(timeZone: utc, year: 2026, month: month, day: 15))!
            let expected: [String: Int] = ["halifax": 60, "stJohns": 90]
            for capital in profile.regionalTimeZoneCapitals where expected[capital.id] != nil {
                let journey = DinoTimeZoneJourney(origin: ottawa, destination: capital, date: date)
                expect(journey.offsetMinutes == expected[capital.id] && journey.steps(from: .init(hour: 23, minute: 55)).last?.time ==
                       ClockTime(hour: 23, minute: 55).adding(minutes: journey.offsetMinutes), "the offset and replay agree in month \(month)")
            }
            for difficulty in DinoTimeZoneDifficulty.allCases {
                for step in [1, 5, 10, 15, 30, 60] {
                    let journey = DinoTimeZoneJourney.generate(language: code, difficulty: difficulty, minuteStep: step, date: date, using: &rng)
                    expect(journey.origin.id == "ottawa" && journey.offsetMinutes != 0 && journey.offsetMinutes.isMultiple(of: step),
                           "every Canadian time-zone level has a valid destination from Ottawa in month \(month)")
                }
            }
        }
    }

    static func testChineseLocalization(profile: AppLanguage) {
        let code = profile.code
        let traditional = profile == .traditionalChinese
        let hourCharacter = traditional ? "點" : "点"
        let two = traditional ? "兩" : "两"
        let originID = traditional ? "taipei" : "beijing"
        let expectedCode = traditional ? "zh-Hant" : "zh-Hans"
        let deviceLanguages = traditional ? ["zh-TW", "zh_Hant_TW", "zh-Hant-HK", "zh-Hant-CN"] : ["zh", "zh_CN", "zh-Hans-SG", "zh-Hans-CN"]
        expect(code == expectedCode && deviceLanguages.allSatisfy { AppLanguage.named($0) == profile }
               && !profile.runsRightToLeft && profile.resourceCodes == [expectedCode, "en"],
               "Chinese matches the intended script in settings and the app bundle")
        expect((try? DinoNameValidator.validated("王小雨").get()) == "王小雨"
               && DinoTimeWords.parsedInteger("１２") == 12, "Chinese names and full-width decimal digits work")
        let mainland = DinoSpeechVoice(identifier: "cn", name: "Mandarin", language: "zh-CN", quality: 1)
        let singapore = DinoSpeechVoice(identifier: "sg", name: "Mandarin", language: "zh-SG", quality: 2)
        let cantonese = DinoSpeechVoice(identifier: "hk", name: "Cantonese", language: "yue-HK", quality: 3)
        let taiwan = DinoSpeechVoice(identifier: "tw", name: "Mandarin", language: "zh-TW", quality: 3)
        let voices = [singapore, mainland, taiwan, cantonese]
        if traditional {
            expect(DinoSpeechVoicePicker.preferredLanguageIdentifier(for: code) == "zh-TW"
                   && DinoSpeechVoicePicker.bestVoice(for: code, among: voices) == taiwan
                   && DinoSpeechVoicePicker.bestVoice(for: code, among: [mainland, cantonese]) == nil,
                   "Taiwanese Mandarin is preferred and unavailable speech leaves the written question")
        } else {
            expect(DinoSpeechVoicePicker.preferredLanguageIdentifier(for: code) == "zh-CN"
                   && DinoSpeechVoicePicker.bestVoice(for: code, among: voices) == mainland
                   && DinoSpeechVoicePicker.bestVoice(for: code, among: [singapore, taiwan, cantonese]) == singapore
                   && DinoSpeechVoicePicker.bestVoice(for: code, among: [taiwan, cantonese]) == nil,
                   "the voice picker prefers mainland Mandarin and falls back within the matching script")
        }

        let minutes: [(Int, String)] = [
            (0, ""), (1, "零一分"), (5, "零五分"), (14, "十四分"), (15, "十五分"), (16, "十六分"),
            (20, "二十分"), (25, "二十五分"), (29, "二十九分"), (30, "半"), (31, "三十一分"),
            (35, "三十五分"), (40, "四十分"), (44, "四十四分"), (45, "四十五分"), (46, "四十六分"),
            (55, "五十五分"), (59, "五十九分")
        ]
        for (minute, ending) in minutes {
            expect(spokenPhrase(code, hour: 7, minute: minute) == "七" + hourCharacter + ending, "Mandarin reading for 7:\(minute)")
        }
        expect(spokenPhrase(code, hour: 8, minute: 0) == "八" + hourCharacter
               && spokenPhrase(code, hour: 2, minute: 2) == two + hourCharacter + "零二分", "hour and minute counters use the correct form of two")

        let hours = ["十二", "一", two, "三", "四", "五", "六", "七", "八", "九", "十", "十一"]
        var rng = SeededGenerator(seed: 42)
        for hour in 0..<24 {
            for minute in 0..<60 {
                let time = ClockTime(hour: hour, minute: minute)
                let prompt = profile.spokenTime.prompt(for: time, using: &rng)
                let hint = SpokenClockReadingHint(minute: minute, language: code)
                let namedHour = hour.isMultiple(of: 12) ? 12 : hour % 12
                let slotIDs = minute == 0 ? ["hour"] : ["hour", "minutes"]
                expect(prompt.phrase == DinoTimeWords.time(time, language: code)
                       && prompt.phrase.hasPrefix(hours[hour % 12] + hourCharacter) && prompt.slots.map(\.id) == slotIDs
                       && hint.spokenHour(for: hour) == namedHour && hint.referenceMinute == 0
                       && hint.count == minute && hint.scaleLabel == String(minute),
                       "word tiles and the visual hint read minutes from the current hour")
                let question = spokenQuestion(prompt: prompt, time: time)
                expect(AnswerValidator.isCorrect(question.expectedAnswer, for: question), "the Mandarin reading scores")
                for (index, slot) in prompt.slots.enumerated() {
                    expect(slot.choices.count == 3 && Set(slot.choices.map(\.word)).count == 3
                           && slot.choices.contains { $0.id == prompt.correct.choiceIDs[index] }, "the three tiles are visibly distinct")
                    for choice in slot.choices where choice.id != prompt.correct.choiceIDs[index] {
                        var wrong = prompt.correct.choiceIDs
                        wrong[index] = choice.id
                        expect(!AnswerValidator.isCorrect(.spoken(.init(choiceIDs: wrong)), for: question),
                               "a different Mandarin tile scores as a different time")
                    }
                }
            }
        }

        let digital: [(Int, Int, String, String, String, String)] = [
            (0, 0, "00:00", "上午12:00", "零点", "凌晨十二点"),
            (0, 5, "00:05", "上午12:05", "零点零五分", "凌晨十二点零五分"),
            (12, 0, "12:00", "下午12:00", "十二点", "下午十二点"),
            (12, 5, "12:05", "下午12:05", "十二点零五分", "下午十二点零五分"),
            (17, 5, "17:05", "下午5:05", "十七点零五分", "下午五点零五分"),
            (23, 59, "23:59", "下午11:59", "二十三点五十九分", "晚上十一点五十九分"),
            (7, 30, "07:30", "上午7:30", "七点三十分", "上午七点半")
        ]
        for (hour, minute, twentyFour, twelve, words, withDayPart) in digital {
            let clock = ClockTime(hour: hour, minute: minute)
            let local = clock.digitalReading(notation: .twelve, languageCode: code)
            expect(local.text == twelve && local.periodBeforeClock && local.separator == ":"
                   && clock.digitalReading(notation: .twentyFour, languageCode: code).text == twentyFour
                   && DinoTimeWords.digitalTimeInWords(clock, language: code) == words.replacingOccurrences(of: "点", with: hourCharacter)
                   && DinoTimeWords.time(clock, language: code, dayPart: true) == withDayPart.replacingOccurrences(of: "点", with: hourCharacter),
                   "clock notation, day part and Mandarin reading agree for \(twentyFour)")
        }
        expect(DinoTimeWords.spokenDuration(125, language: code) == (traditional ? "兩小時5分鐘" : "两小时5分钟")
               && DinoTimeWords.duration(65, language: code) == (traditional ? "1小時5分" : "1小时5分")
               && DinoTimeWords.zoneHours(150, language: code) == "2.5",
               "duration and time-zone offsets use their local units")
        expect(ClockTime(hour: 23, minute: 55).adding(minutes: 10) == .init(hour: 0, minute: 5)
               && ClockTime(hour: 0, minute: 5).adding(minutes: -10) == .init(hour: 23, minute: 55),
               "adding and subtracting cross midnight")

        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        func localizedStrings(from file: String) -> [String: String] {
            let data = try! Data(contentsOf: root.appendingPathComponent(file))
            let catalog = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            let entries = catalog["strings"] as! [String: [String: Any]]
            return entries.compactMapValues { entry in
                let languages = entry["localizations"] as? [String: [String: Any]]
                let unit = languages?[code]?["stringUnit"] as? [String: String]
                expect(unit?["state"] == "translated" && unit?["value"] != nil, "all strings in \(file) are translated")
                return unit?["value"]
            }
        }
        let strings = localizedStrings(from: "Localizable.xcstrings")
        expect(localizedStrings(from: "InfoPlist.xcstrings")["CFBundleDisplayName"] == (traditional ? "恐龍學看鐘" : "恐龙学看钟"), "iOS has a localized app name")
        if traditional {
            expect(strings["dino.timeZone.city.taipei"] == "台北"
                   && strings["dino.digital"] == "數位時鐘"
                   && strings["dino.question.sayTime"] == "選卡片，拼出時鐘上的時間",
                   "Taiwanese copy uses local terms")
        }
        for type in DinoPracticeQuestion.allCases {
            for time in DinoPracticeTime.allCases {
                var generator = DinoPracticeGenerator(configuration: .init(time: time, order: .specific(type)), seed: 71, language: code)
                for index in 0..<3 {
                    let question = generator.next(index: index)
                    let prompt = DinoQuestionPrompt.make(question: question, language: code, instructionKey: question.kind.instructionKey)
                    let text = prompt.spoken { strings[$0] ?? $0 }
                    expect(!text.contains("dino.") && !text.contains("$@") && !text.contains("%@"), "the Chinese title resolves for \(type) and \(time)")
                    if let format = prompt.formatKey {
                        expect(DinoQuestionPrompt.interpolated(strings[format] ?? format, arguments: prompt.arguments) != nil,
                               "the translated template supplies all arguments")
                    }
                    expect(AnswerValidator.isCorrect(question.expectedAnswer, for: question), "the generated answer scores")
                    if question.kind == .timeZone {
                        expect(question.timeZoneJourney?.origin.id == originID, "Chinese time-zone practice starts in the local city")
                    }
                    if question.kind == .sayTime, let solution = question.spokenPrompt?.phrase {
                        expect(!text.contains(solution), "the spoken instructions leave the solution to the player")
                    }
                }
            }
        }
        let capitals = Dictionary(uniqueKeysWithValues: (DinoTimeZoneJourney.capitals + profile.regionalTimeZoneCapitals).map { ($0.id, $0) })
        let origin = capitals[originID]!
        let utc = TimeZone(secondsFromGMT: 0)!
        for month in 1...12 {
            let date = Calendar(identifier: .gregorian).date(from: .init(timeZone: utc, year: 2026, month: month, day: 15))!
            let dateText = DinoTimeZoneJourney.displayedDate(language: code, date: date)
            expect(dateText == "\(month)月15日", "the atlas date uses Chinese month-day order")
            for difficulty in DinoTimeZoneDifficulty.allCases {
                for step in [1, 5, 10, 15, 30, 60] {
                    let journey = DinoTimeZoneJourney.generate(language: code, difficulty: difficulty, minuteStep: step, date: date, using: &rng)
                    expect(journey.origin == origin && journey.offsetMinutes != 0 && journey.offsetMinutes.isMultiple(of: step)
                           && strings[journey.destination.nameKey] != nil, "every time-zone difficulty has a localized destination from the local city")
                }
            }
            for (id, offset) in ["tokyo": 60, "hanoi": -60, "manila": 0, "newDelhi": -150] {
                let journey = DinoTimeZoneJourney(origin: origin, destination: capitals[id]!, date: date)
                let start = ClockTime(hour: 0, minute: 5)
                expect(journey.offsetMinutes == offset
                       && (journey.steps(from: start).last?.time ?? start) == start.adding(minutes: offset),
                       "time-zone replay uses the correct offset from the local city")
            }
            if month == 1 || month == 7 {
                let london = DinoTimeZoneJourney(origin: origin, destination: capitals["london"]!, date: date)
                expect(london.offsetMinutes == (month == 1 ? -480 : -420), "London observes seasonal time changes")
            }
        }
    }

    static func testSpanishLocalization() {
        let profile = AppLanguage.spanish
        let code = profile.code
        expect(AppLanguage.named("es") == profile && AppLanguage.named("es_Latn_ES") == profile
               && profile.resourceCodes == ["es", "en"] && !profile.runsRightToLeft,
               "Spain uses generic Spanish resources and the Spanish locale")
        expect((try? DinoNameValidator.validated("Iñés").get()) == "Iñés", "Spanish accents and ñ are accepted")
        let spain = DinoSpeechVoice(identifier: "es", name: "Spanish", language: "es-ES", quality: 1)
        let mexico = DinoSpeechVoice(identifier: "mx", name: "Mexican Spanish", language: "es-MX", quality: 2)
        let english = DinoSpeechVoice(identifier: "en", name: "English", language: "en-GB", quality: 2)
        expect(DinoSpeechVoicePicker.preferredLanguageIdentifier(for: code) == "es-ES"
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [mexico, spain]) == spain
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [english, mexico]) == mexico
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [english]) == nil,
               "speech prefers Spain, then another Spanish voice or the written question")

        let examples: [(Int, String)] = [
            (0, "las siete en punto"), (1, "las siete y un minuto"), (5, "las siete y cinco"),
            (14, "las siete y catorce"), (15, "las siete y cuarto"), (16, "las siete y dieciséis"),
            (20, "las siete y veinte"), (25, "las siete y veinticinco"), (29, "las siete y veintinueve"),
            (30, "las siete y media"), (31, "las ocho menos veintinueve"), (35, "las ocho menos veinticinco"),
            (40, "las ocho menos veinte"), (44, "las ocho menos dieciséis"), (45, "las ocho menos cuarto"),
            (46, "las ocho menos catorce"), (55, "las ocho menos cinco"), (59, "las ocho menos un minuto")
        ]
        for (minute, phrase) in examples {
            expect(spokenPhrase(code, hour: 7, minute: minute) == phrase, "Spanish reading at 07:\(minute)")
        }
        expect(spokenPhrase(code, hour: 8, minute: 0) == "las ocho en punto"
               && spokenPhrase(code, hour: 11, minute: 45) == "las doce menos cuarto"
               && spokenPhrase(code, hour: 12, minute: 45) == "la una menos cuarto",
               "Spanish names the right hour and uses the singular article for one")

        var rng = SeededGenerator(seed: 33)
        for hour in 0..<24 {
            for minute in 0..<60 {
                let time = ClockTime(hour: hour, minute: minute)
                let prompt = profile.spokenTime.prompt(for: time, using: &rng)
                let hint = SpokenClockReadingHint(minute: minute, language: code)
                let readsNextHour = minute > 30
                let namedHour = (hour + (readsNextHour ? 1 : 0) + 11) % 12 + 1
                expect(prompt.phrase == DinoTimeWords.time(time, language: code)
                       && hint.spokenHour(for: hour) == namedHour
                       && hint.referenceMinute == (readsNextHour ? 60 : 0)
                       && hint.count == (readsNextHour ? 60 - minute : minute),
                       "Spanish tiles and clock hint point to the same time")
                let fixedExpression = minute == 0 || minute == 30
                expect(prompt.accepts(prompt.correct)
                       && prompt.slots.map(\.id) == (fixedExpression ? ["hour", "expression"] : ["hour", "direction", "minutes"]),
                       "Spanish separates y and menos for minute counts")
                for (index, slot) in prompt.slots.enumerated() {
                    let words = slot.choices.map(\.word)
                    expect(slot.id == "direction" ? words == ["y", "menos"] : Set(words).count == 3,
                           "Spanish choices are distinct")
                    for choice in slot.choices where choice.id != prompt.correct.choiceIDs[index] {
                        var wrong = prompt.correct.choiceIDs
                        wrong[index] = choice.id
                        expect(!prompt.accepts(.init(choiceIDs: wrong)), "a different Spanish tile changes the answer")
                    }
                }
            }
        }

        let digital: [(ClockTime, String, String, String)] = [
            (.init(hour: 0), "las cero horas", "a.m.", "de la madrugada"),
            (.init(hour: 0, minute: 5), "las cero horas y cinco", "a.m.", "de la madrugada"),
            (.init(hour: 12), "las doce", "p.m.", "de la tarde"),
            (.init(hour: 12, minute: 5), "las doce y cinco", "p.m.", "de la tarde"),
            (.init(hour: 17, minute: 5), "las diecisiete y cinco", "p.m.", "de la tarde"),
            (.init(hour: 23, minute: 59), "las veintitrés y cincuenta y nueve", "p.m.", "de la noche")
        ]
        for (clock, words, period, part) in digital {
            let twelve = clock.digitalReading(notation: .twelve, languageCode: code)
            let full = clock.digitalReading(notation: .twentyFour, languageCode: code)
            expect(full.text == "\(clock.hour):\(String(format: "%02d", clock.minute))" && full.period == nil
                   && twelve.period?.filter({ !$0.isWhitespace }) == period
                   && !twelve.periodBeforeClock && twelve.minute == full.minute
                   && DinoTimeWords.digitalTimeInWords(clock, language: code) == words
                   && DinoTimeWords.dayPartSuffix(clock, language: code) == part,
                   "Spanish notation, day part and reading at \(clock.digitalText)")
        }
        expect(DinoTimeWords.time(.init(hour: 12, minute: 5), language: code, dayPart: true)
               == "las doce y cinco del mediodía", "Spanish uses mediodía when naming twelve at noon")
        expect(DinoTimeWords.spokenDuration(61, language: code) == "una hora y un minuto"
               && DinoTimeWords.duration(125, language: code) == "2\u{00A0}h\u{00A0}5\u{00A0}min"
               && DinoTimeWords.zoneDifference(-30, language: code) == "−0,5\u{00A0}h"
               && DinoTimeWords.digitalDuration(65, language: code) == "01:05", "Spanish durations and offsets")
        expect(ClockTime(hour: 23, minute: 55).adding(minutes: 10) == .init(hour: 0, minute: 5)
               && ClockTime(hour: 0, minute: 5).adding(minutes: -10) == .init(hour: 23, minute: 55),
               "Spanish clock arithmetic crosses the day boundary")

        let strings = localizedCatalog("Localizable.xcstrings", code: code)
        expect(localizedCatalog("InfoPlist.xcstrings", code: code)["CFBundleDisplayName"] == "Dino y el reloj"
               && strings["dino.timeZone.city.madrid"] == "Madrid"
               && strings["dino.timeZone.city.lisbon"] == "Lisboa", "Spanish app and city names")
        testLocalizedPracticeQuestions(code: code, strings: strings)

        let capitals = Dictionary(uniqueKeysWithValues: DinoTimeZoneJourney.capitals.map { ($0.id, $0) })
        let madrid = capitals["madrid"]!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let winter = calendar.date(from: .init(year: 2026, month: 1, day: 15, hour: 12))!
        let summer = calendar.date(from: .init(year: 2026, month: 7, day: 15, hour: 12))!
        expect(DinoTimeZoneJourney.displayedDate(language: code, date: winter) == "15 de enero", "Spanish atlas date")
        for (date, city, offset) in [(winter, "lisbon", -60), (summer, "athens", 60), (summer, "paris", 0),
                                     (winter, "ankara", 120), (summer, "ankara", 60),
                                     (winter, "newDelhi", 270), (summer, "newDelhi", 210)] {
            let journey = DinoTimeZoneJourney(origin: madrid, destination: capitals[city]!, date: date)
            let clock = ClockTime(hour: offset > 0 ? 23 : 0, minute: 5)
            expect(journey.offsetMinutes == offset
                   && (journey.steps(from: clock).last?.time ?? clock) == clock.adding(minutes: offset),
                   "Madrid replay uses the real offset for \(city)")
        }
        for month in 0..<12 {
            let date = calendar.date(byAdding: .month, value: month, to: winter)!
            for difficulty in DinoTimeZoneDifficulty.allCases {
                for step in [1, 5, 10, 15, 30, 60] {
                    let destinations = DinoTimeZoneJourney.destinations(from: madrid, difficulty: difficulty,
                                                                        minuteStep: step, date: date)
                    let journey = DinoTimeZoneJourney.generate(language: code, difficulty: difficulty, minuteStep: step,
                                                               date: date, using: &rng)
                    expect(destinations.count >= 2 && destinations.allSatisfy { strings[$0.nameKey] != nil }
                           && journey.origin == madrid && destinations.contains(journey.destination),
                           "Madrid has translated destinations at every difficulty and minute step")
                }
            }
        }
    }

    static func testMexicanSpanishLocalization() {
        let profile = AppLanguage.mexicanSpanish
        let code = profile.code
        expect(AppLanguage.named("es-MX") == profile && AppLanguage.named("es_Latn_MX") == profile
               && AppLanguage.named("es") == .spanish && AppLanguage.named("es-ES") == .spanish
               && profile.resourceCodes == ["es-MX", "es", "en"] && !profile.runsRightToLeft,
               "Mexican Spanish has a distinct regional profile and an inherited Spanish bundle")
        expect((try? DinoNameValidator.validated("Xóchitl Muñoz").get()) == "Xóchitl Muñoz",
               "Mexican names can use accents and ñ")
        let mexico = DinoSpeechVoice(identifier: "mx", name: "Paulina", language: "es-MX", quality: 1)
        let spain = DinoSpeechVoice(identifier: "es", name: "Mónica", language: "es-ES", quality: 3)
        let english = DinoSpeechVoice(identifier: "en", name: "English", language: "en-GB", quality: 2)
        expect(DinoSpeechVoicePicker.preferredLanguageIdentifier(for: code) == "es-MX"
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [spain, mexico]) == mexico
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [english, spain]) == spain
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [english]) == nil,
               "speech prefers Mexico and falls back to Spanish or the written question")

        let examples: [(Int, String)] = [
            (0, "las siete en punto"), (1, "las siete y un minuto"), (5, "las siete y cinco"),
            (14, "las siete y catorce"), (15, "las siete y cuarto"), (16, "las siete y dieciséis"),
            (20, "las siete y veinte"), (25, "las siete y veinticinco"), (29, "las siete y veintinueve"),
            (30, "las siete y media"), (31, "veintinueve para las ocho"), (35, "veinticinco para las ocho"),
            (40, "veinte para las ocho"), (44, "dieciséis para las ocho"), (45, "cuarto para las ocho"),
            (46, "catorce para las ocho"), (55, "cinco para las ocho"), (59, "un minuto para las ocho")
        ]
        for (minute, phrase) in examples {
            expect(spokenPhrase(code, hour: 7, minute: minute) == phrase, "Mexican Spanish reading at 07:\(minute)")
        }
        expect(spokenPhrase(code, hour: 8, minute: 0) == "las ocho en punto"
               && spokenPhrase(code, hour: 23, minute: 45) == "cuarto para las doce"
               && spokenPhrase(code, hour: 12, minute: 45) == "cuarto para la una",
               "Mexican Spanish crosses midnight and distinguishes la una from las doce")

        var rng = SeededGenerator(seed: 52)
        for hour in 0..<24 {
            for minute in 0..<60 {
                let time = ClockTime(hour: hour, minute: minute)
                let prompt = profile.spokenTime.prompt(for: time, using: &rng)
                let hint = SpokenClockReadingHint(minute: minute, language: code)
                let countsDown = minute > 30
                let namedHour = (hour + (countsDown ? 1 : 0) + 11) % 12 + 1
                expect(prompt.phrase == DinoTimeWords.time(time, language: code)
                       && hint.spokenHour(for: hour) == namedHour
                       && hint.referenceMinute == (countsDown ? 60 : 0)
                       && hint.count == (countsDown ? 60 - minute : minute),
                       "Mexican Spanish tiles and the arc name the same hour")
                expect(prompt.accepts(prompt.correct) && prompt.slots.map(\.choices.count) == [3, 3]
                       && prompt.slots.map(\.id) == (countsDown ? ["remainingMinutes", "hour"] : ["hour", "pastMinutes"]),
                       "Mexican Spanish switches to minutes first after the half hour")
                for (index, slot) in prompt.slots.enumerated() {
                    expect(Set(slot.choices.map(\.word)).count == 3, "Mexican Spanish choices are distinct")
                    for choice in slot.choices where choice.id != prompt.correct.choiceIDs[index] {
                        var wrong = prompt.correct.choiceIDs
                        wrong[index] = choice.id
                        expect(!prompt.accepts(.init(choiceIDs: wrong)), "a different tile changes the time")
                    }
                }
            }
        }

        let digital: [(ClockTime, String, String, String)] = [
            (.init(hour: 0), "las cero horas", "a.m.", "de la madrugada"),
            (.init(hour: 0, minute: 5), "las cero horas con cinco minutos", "a.m.", "de la madrugada"),
            (.init(hour: 1, minute: 1), "la una con un minuto", "a.m.", "de la madrugada"),
            (.init(hour: 12), "las doce horas", "p.m.", "de la tarde"),
            (.init(hour: 12, minute: 5), "las doce horas con cinco minutos", "p.m.", "de la tarde"),
            (.init(hour: 17, minute: 5), "las diecisiete horas con cinco minutos", "p.m.", "de la tarde"),
            (.init(hour: 23, minute: 59), "las veintitrés horas con cincuenta y nueve minutos", "p.m.", "de la noche")
        ]
        for (clock, words, period, part) in digital {
            let twelve = clock.digitalReading(notation: .twelve, languageCode: code)
            let full = clock.digitalReading(notation: .twentyFour, languageCode: code)
            expect(full.text == "\(clock.hour):\(String(format: "%02d", clock.minute))" && full.period == nil
                   && twelve.period?.filter({ !$0.isWhitespace }) == period
                   && !twelve.periodBeforeClock && twelve.separator == ":" && twelve.minute == full.minute
                   && DinoTimeWords.digitalTimeInWords(clock, language: code) == words
                   && DinoTimeWords.dayPartSuffix(clock, language: code) == part,
                   "Mexican Spanish formats time and day parts at \(clock.digitalText)")
        }
        expect(DinoTimeWords.time(.init(hour: 12, minute: 5), language: code, dayPart: true) == "las doce y cinco del mediodía"
               && DinoTimeWords.time(.init(hour: 23, minute: 59), language: code, dayPart: true) == "un minuto para las doce de la noche",
               "Mexican Spanish disambiguates the two readings of twelve")
        expect(DinoTimeWords.spokenDuration(61, language: code) == "una hora y un minuto"
               && DinoTimeWords.duration(125, language: code) == "2\u{00A0}h\u{00A0}5\u{00A0}min"
               && DinoTimeWords.zoneDifference(-30, language: code) == "−0.5\u{00A0}h"
               && DinoTimeWords.digitalDuration(65, language: code) == "01:05", "Mexican durations and decimal offsets")
        expect(ClockTime(hour: 23, minute: 55).adding(minutes: 10) == .init(hour: 0, minute: 5)
               && ClockTime(hour: 0, minute: 5).adding(minutes: -10) == .init(hour: 23, minute: 55),
               "clock arithmetic crosses midnight both ways")

        let strings = localizedCatalog("Localizable.xcstrings", code: code)
        expect(localizedCatalog("InfoPlist.xcstrings", code: code)["CFBundleDisplayName"] == "Dino y el reloj"
               && strings["dino.settings"] == "Configuración" && strings["dino.timeZone.city.mexicoCity"] == "Ciudad de México"
               && strings["dino.timeZone.city.cancun"] == "Cancún", "the app name, settings and Mexican cities are localized")
        for kind in [ClockQuestionKind.addTime, .subtractTime] {
            for (hour, reading) in [(1, "la una con un minuto"), (2, "las dos horas con un minuto")] {
                let start = ClockTime(hour: hour, minute: 1)
                let question = ClockQuestion(id: 0, kind: kind, target: start, options: [], activity: nil,
                                             companionClocks: [], relatedTimes: [start], durationMinutes: 5)
                let prompt = DinoQuestionPrompt.make(question: question, language: code, instructionKey: kind.instructionKey)
                let sentence = prompt.spoken { strings[$0] ?? $0 }
                expect(sentence.hasPrefix("El reloj marca \(reading)."), "Mexican arithmetic reads singular and plural hours naturally")
            }
        }
        testLocalizedPracticeQuestions(code: code, strings: strings)

        let cities = Dictionary(uniqueKeysWithValues: (DinoTimeZoneJourney.capitals + profile.regionalTimeZoneCapitals).map { ($0.id, $0) })
        let origin = cities[profile.timeZoneOrigin]!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let winter = calendar.date(from: .init(year: 2026, month: 1, day: 15, hour: 12))!
        let summer = calendar.date(from: .init(year: 2026, month: 7, day: 15, hour: 12))!
        expect(DinoTimeZoneJourney.displayedDate(language: code, date: winter) == "15 de enero", "Mexican atlas date")
        for (date, city, offset) in [(winter, "cancun", 60), (summer, "hermosillo", -60),
                                     (winter, "tijuana", -120), (summer, "tijuana", -60),
                                     (winter, "panamaCity", 60), (summer, "newDelhi", 690)] {
            let journey = DinoTimeZoneJourney(origin: origin, destination: cities[city]!, date: date)
            let clock = ClockTime(hour: offset > 0 ? 23 : 0, minute: 5)
            expect(journey.offsetMinutes == offset
                   && (journey.steps(from: clock).last?.time ?? clock) == clock.adding(minutes: offset),
                   "Mexico City replay applies the actual offset for \(city)")
        }
        for month in 0..<12 {
            let date = calendar.date(byAdding: .month, value: month, to: winter)!
            for difficulty in DinoTimeZoneDifficulty.allCases {
                for step in [1, 5, 10, 15, 30, 60] {
                    let destinations = DinoTimeZoneJourney.destinations(from: origin, difficulty: difficulty, minuteStep: step,
                                                                        date: date, regionalCapitals: profile.regionalTimeZoneCapitals)
                    let journey = DinoTimeZoneJourney.generate(language: code, difficulty: difficulty, minuteStep: step,
                                                               date: date, using: &rng)
                    expect(destinations.count >= 2 && destinations.allSatisfy { strings[$0.nameKey] != nil }
                           && journey.origin == origin && destinations.contains(journey.destination),
                           "Mexico City has localized destinations on every difficulty and time grid")
                }
            }
        }
    }

    static func testEuropeanPortugueseLocalization() {
        let profile = AppLanguage.europeanPortuguese
        let code = profile.code
        expect(AppLanguage.named("pt-PT") == profile && AppLanguage.named("pt_Latn_PT") == profile
               && AppLanguage.named("pt-BR") == .brazilianPortuguese && profile.resourceCodes == ["pt-PT", "en"]
               && !profile.runsRightToLeft && profile.voiceLocale == "pt-PT",
               "European Portuguese has its own bundle, region and preferred voice")
        expect((try? DinoNameValidator.validated("Inês Gonçalves").get()) == "Inês Gonçalves",
               "European Portuguese diacritics are accepted in names")
        let localVoice = DinoSpeechVoice(identifier: "pt", name: "Português", language: "pt-PT", quality: 1)
        let brazilianVoice = DinoSpeechVoice(identifier: "br", name: "Português", language: "pt-BR", quality: 3)
        let englishVoice = DinoSpeechVoice(identifier: "en", name: "English", language: "en-GB", quality: 3)
        expect(DinoSpeechVoicePicker.bestVoice(for: code, among: [brazilianVoice, localVoice]) == localVoice
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [englishVoice, brazilianVoice]) == brazilianVoice
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [englishVoice]) == nil,
               "voice selection prefers Portugal, then Portuguese, then written text")

        let minuteExamples: [(Int, String)] = [
            (0, "sete em ponto"), (1, "sete e um minuto"), (5, "sete e cinco"),
            (14, "sete e catorze"), (15, "sete e um quarto"), (16, "sete e dezasseis"),
            (20, "sete e vinte"), (25, "sete e vinte e cinco"), (29, "sete e vinte e nove"),
            (30, "sete e meia"), (31, "oito menos vinte e nove"), (35, "oito menos vinte e cinco"),
            (40, "oito menos vinte"), (44, "oito menos dezasseis"), (45, "oito menos um quarto"),
            (46, "oito menos catorze"), (55, "oito menos cinco"), (59, "oito menos um minuto")
        ]
        for (minute, phrase) in minuteExamples {
            expect(DinoTimeWords.time(.init(hour: 7, minute: minute), language: code) == phrase,
                   "Portuguese word reading for 07:\(minute)")
        }
        expect(DinoTimeWords.time(.init(hour: 8), language: code) == "oito em ponto"
               && DinoTimeWords.time(.init(hour: 1), language: code) == "uma hora em ponto"
               && DinoTimeWords.time(.init(hour: 2), language: code) == "duas em ponto"
               && DinoTimeWords.time(.init(hour: 12, minute: 45), language: code) == "uma menos um quarto",
               "Portuguese hour cards agree with hora and wrap through one")
        var rng = SeededGenerator(seed: 96)
        for hour in 0..<24 {
            for minute in 0..<60 {
                let time = ClockTime(hour: hour, minute: minute)
                let prompt = profile.spokenTime.prompt(for: time, using: &rng)
                let hint = SpokenClockReadingHint(minute: minute, language: code)
                let beforeNextHour = minute > 30
                let named = (hour + (beforeNextHour ? 1 : 0) + 11) % 12 + 1
                let region: DinoTimeReading.Region = minute == 0 ? .whole : minute == 30 ? .half : beforeNextHour ? .to : .past
                expect(hint.spokenHour(for: hour) == named && hint.referenceMinute == (beforeNextHour ? 60 : 0)
                       && hint.count == (beforeNextHour ? 60 - minute : minute)
                       && DinoTimeReading.region(minute: minute, language: code) == region
                       && prompt.slots.map(\.id) == (minute == 0 || minute == 30
                           ? ["hour", "expression"] : ["hour", "direction", "minutes"])
                       && prompt.phrase == DinoTimeWords.time(time, language: code)
                       && prompt.accepts(prompt.correct), "Portuguese words, score and clock hint for \(time.digitalText)")
                for (slotIndex, slot) in prompt.slots.enumerated() {
                    if slot.id == "direction" {
                        expect(slot.choices.map(\.word) == ["e", "menos"], "Portuguese direction is a separate choice")
                    } else {
                        expect(Set(slot.choices.map(\.word)).count == 3, "Portuguese cards have distinct labels")
                    }
                    for choice in slot.choices where choice.id != prompt.correct.choiceIDs[slotIndex] {
                        var wrong = prompt.correct.choiceIDs
                        wrong[slotIndex] = choice.id
                        expect(!prompt.accepts(.init(choiceIDs: wrong)), "a different Portuguese card changes the time")
                    }
                }
            }
        }

        let digital: [(ClockTime, String, String, String)] = [
            (.init(hour: 0), "meia-noite", "AM", "da madrugada"),
            (.init(hour: 0, minute: 5), "meia-noite e cinco minutos", "AM", "da madrugada"),
            (.init(hour: 1, minute: 1), "uma hora e um minuto", "AM", "da madrugada"),
            (.init(hour: 12), "meio-dia", "PM", "da tarde"),
            (.init(hour: 12, minute: 5), "meio-dia e cinco minutos", "PM", "da tarde"),
            (.init(hour: 17, minute: 5), "dezassete horas e cinco minutos", "PM", "da tarde"),
            (.init(hour: 21, minute: 22), "vinte e uma horas e vinte e dois minutos", "PM", "da noite"),
            (.init(hour: 23, minute: 59), "vinte e três horas e cinquenta e nove minutos", "PM", "da noite")
        ]
        for (clock, words, period, part) in digital {
            let twelve = clock.digitalReading(notation: .twelve, languageCode: code)
            let full = clock.digitalReading(notation: .twentyFour, languageCode: code)
            expect(full.text == clock.digitalText && full.period == nil && twelve.period == period
                   && twelve.separator == ":" && !twelve.periodBeforeClock && twelve.minute == full.minute
                   && DinoTimeWords.digitalTimeInWords(clock, language: code) == words
                   && DinoTimeWords.dayPartSuffix(clock, language: code) == part,
                   "Portuguese 12- and 24-hour display, speech and day part for \(clock.digitalText)")
        }
        expect(DinoTimeWords.spokenDuration(61, language: code) == "uma hora e um minuto"
               && DinoTimeWords.duration(125, language: code) == "2\u{00A0}h\u{00A0}5\u{00A0}min"
               && DinoTimeWords.zoneDifference(-30, language: code) == "−0,5\u{00A0}h"
               && ClockTime(hour: 23, minute: 55).adding(minutes: 10) == .init(hour: 0, minute: 5)
               && ClockTime(hour: 0, minute: 5).adding(minutes: -10) == .init(hour: 23, minute: 55),
               "Portuguese duration, decimal offset and time arithmetic across midnight")

        let strings = localizedCatalog("Localizable.xcstrings", code: code)
        expect(localizedCatalog("InfoPlist.xcstrings", code: code)["CFBundleDisplayName"] == "O Relógio do Dino"
               && strings["dino.settings"] == "Definições" && strings["dino.timeZone.city.lisbon"] == "Lisboa"
               && strings["dino.stars %lld"] == "%lld estrelas", "Portuguese app, city and interface text")
        testLocalizedPracticeQuestions(code: code, strings: strings)

        let cities = Dictionary(uniqueKeysWithValues: DinoTimeZoneJourney.capitals.map { ($0.id, $0) })
        let origin = cities[profile.timeZoneOrigin]!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let winter = calendar.date(from: .init(year: 2026, month: 1, day: 15, hour: 12))!
        let summer = calendar.date(from: .init(year: 2026, month: 7, day: 15, hour: 12))!
        expect(DinoTimeZoneJourney.displayedDate(language: code, date: winter) == "15 de janeiro", "Portuguese atlas date")
        for (date, city, offset) in [(winter, "madrid", 60), (summer, "london", 0), (winter, "brasilia", -180),
                                     (summer, "brasilia", -240), (winter, "newDelhi", 330), (summer, "newDelhi", 270)] {
            let journey = DinoTimeZoneJourney(origin: origin, destination: cities[city]!, date: date)
            let clock = ClockTime(hour: offset > 0 ? 23 : 0, minute: 5)
            expect(journey.offsetMinutes == offset && (journey.steps(from: clock).last?.time ?? clock) == clock.adding(minutes: offset),
                   "Lisbon time zone and replay match \(city) at \(date)")
        }
        for month in 0..<12 {
            let date = calendar.date(byAdding: .month, value: month, to: winter)!
            for difficulty in DinoTimeZoneDifficulty.allCases {
                for step in [1, 5, 10, 15, 30, 60] {
                    let destinations = DinoTimeZoneJourney.destinations(from: origin, difficulty: difficulty, minuteStep: step, date: date)
                    let journey = DinoTimeZoneJourney.generate(language: code, difficulty: difficulty, minuteStep: step,
                                                               date: date, using: &rng)
                    expect(destinations.count >= 2 && destinations.allSatisfy { strings[$0.nameKey] != nil }
                           && journey.origin == origin && destinations.contains(journey.destination),
                           "Lisbon offers localized destinations at every difficulty and time grid")
                }
            }
        }
    }

    static func testBrazilianPortugueseLocalization() {
        let profile = AppLanguage.brazilianPortuguese
        let code = profile.code
        expect(AppLanguage.named("pt_BR") == profile && AppLanguage.named("pt-Latn-BR") == profile
               && AppLanguage.named("pt-PT") == .europeanPortuguese && profile.resourceCodes == ["pt-BR", "pt-PT", "en"]
               && !profile.runsRightToLeft && profile.voiceLocale == "pt-BR", "Brazil has its own bundle, region and voice")
        expect((try? DinoNameValidator.validated("João Gonçalves").get()) == "João Gonçalves", "Brazilian diacritics in names")
        let brazil = DinoSpeechVoice(identifier: "br", name: "Português", language: "pt-BR", quality: 1)
        let portugal = DinoSpeechVoice(identifier: "pt", name: "Português", language: "pt-PT", quality: 3)
        let english = DinoSpeechVoice(identifier: "en", name: "English", language: "en-GB", quality: 3)
        expect(DinoSpeechVoicePicker.bestVoice(for: code, among: [portugal, brazil]) == brazil
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [english, portugal]) == portugal
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [english]) == nil,
               "speech prefers Brazil, then Portuguese, then the written question")

        let examples: [(Int, String)] = [
            (0, "sete em ponto"), (1, "sete e um minuto"), (5, "sete e cinco"), (14, "sete e catorze"),
            (15, "sete e quinze"), (16, "sete e dezesseis"), (20, "sete e vinte"), (25, "sete e vinte e cinco"),
            (29, "sete e vinte e nove"), (30, "sete e meia"), (31, "vinte e nove para as oito"),
            (35, "vinte e cinco para as oito"), (40, "vinte para as oito"), (44, "dezesseis para as oito"),
            (45, "quinze para as oito"), (46, "catorze para as oito"), (55, "cinco para as oito"),
            (59, "um minuto para as oito")
        ]
        for (minute, phrase) in examples {
            expect(DinoTimeWords.time(.init(hour: 7, minute: minute), language: code) == phrase,
                   "Brazilian Portuguese analog words for 07:\(minute)")
        }
        expect(DinoTimeWords.time(.init(hour: 8), language: code) == "oito em ponto"
               && DinoTimeWords.time(.init(hour: 12, minute: 45), language: code) == "quinze para uma"
               && DinoTimeWords.time(.init(hour: 1, minute: 30), language: code) == "uma e meia"
               && DinoTimeWords.time(.init(hour: 1, minute: 45), language: code) == "quinze para as duas",
               "Brazilian hours agree with hora and use the article where needed")

        var rng = SeededGenerator(seed: 101)
        for hour in 0..<24 {
            for minute in 0..<60 {
                let time = ClockTime(hour: hour, minute: minute)
                let prompt = profile.spokenTime.prompt(for: time, using: &rng)
                let hint = SpokenClockReadingHint(minute: minute, language: code)
                let remaining = minute > 30
                let region: DinoTimeReading.Region = minute == 0 ? .whole : minute == 30 ? .half : remaining ? .to : .past
                expect(hint.spokenHour(for: hour) == (hour + (remaining ? 1 : 0) + 11) % 12 + 1
                       && hint.referenceMinute == (remaining ? 60 : 0) && hint.count == (remaining ? 60 - minute : minute)
                       && DinoTimeReading.region(minute: minute, language: code) == region
                       && prompt.slots.map(\.id) == (remaining ? ["remainingMinutes", "hour"] : ["hour", "pastMinutes"])
                       && prompt.phrase == DinoTimeWords.time(time, language: code), "Brazilian words and hint for \(time.digitalText)")
                let first = prompt.slots[0].choices, second = prompt.slots[1].choices
                expect(Set(first.map(\.word)).count == 3 && Set(second.map(\.word)).count == 3
                       && first.flatMap { first in second.map { SpokenTimeAnswer(choiceIDs: [first.id, $0.id]) } }
                           .filter(prompt.accepts) == [prompt.correct], "Brazilian word tiles have exactly one correct combination")
            }
        }

        let digital: [(ClockTime, String, String, String)] = [
            (.init(hour: 0), "meia-noite", "AM", "da madrugada"),
            (.init(hour: 0, minute: 5), "meia-noite e cinco minutos", "AM", "da madrugada"),
            (.init(hour: 1, minute: 1), "uma hora e um minuto", "AM", "da madrugada"),
            (.init(hour: 7, minute: 5), "sete horas e cinco minutos", "AM", "da manhã"),
            (.init(hour: 12), "meio-dia", "PM", "da tarde"),
            (.init(hour: 12, minute: 5), "meio-dia e cinco minutos", "PM", "da tarde"),
            (.init(hour: 17, minute: 5), "dezessete horas e cinco minutos", "PM", "da tarde"),
            (.init(hour: 21, minute: 22), "vinte e uma horas e vinte e dois minutos", "PM", "da noite"),
            (.init(hour: 23, minute: 59), "vinte e três horas e cinquenta e nove minutos", "PM", "da noite")
        ]
        for (clock, words, period, part) in digital {
            let twelve = clock.digitalReading(notation: .twelve, languageCode: code)
            let full = clock.digitalReading(notation: .twentyFour, languageCode: code)
            expect(full.text == clock.digitalText && full.period == nil && twelve.period == period
                   && twelve.separator == ":" && !twelve.periodBeforeClock && twelve.minute == full.minute
                   && DinoTimeWords.digitalTimeInWords(clock, language: code) == words
                   && DinoTimeWords.dayPartSuffix(clock, language: code) == part, "Brazilian clock notation and speech for \(clock.digitalText)")
        }
        expect(DinoTimeWords.spokenDuration(61, language: code) == "uma hora e um minuto"
               && DinoTimeWords.duration(125, language: code) == "2\u{00A0}h\u{00A0}5\u{00A0}min"
               && DinoTimeWords.zoneDifference(-30, language: code) == "−0,5\u{00A0}h"
               && ClockTime(hour: 23, minute: 55).adding(minutes: 10) == .init(hour: 0, minute: 5)
               && ClockTime(hour: 0, minute: 5).adding(minutes: -10) == .init(hour: 23, minute: 55),
               "Brazilian duration, decimal offset and arithmetic across midnight")

        let strings = localizedCatalog("Localizable.xcstrings", code: code)
        expect(localizedCatalog("InfoPlist.xcstrings", code: code)["CFBundleDisplayName"] == "O Relógio do Dino"
               && strings["dino.settings"] == "Ajustes" && strings["dino.timeZone.city.brasilia"] == "Brasília"
               && strings["dino.train.one"] == "Trem 1" && strings["dino.stars %lld"] == "%lld estrelas",
               "Brazilian app name, settings, city, train and plural")
        testLocalizedPracticeQuestions(code: code, strings: strings)

        let cities = Dictionary(uniqueKeysWithValues: (DinoTimeZoneJourney.capitals + profile.regionalTimeZoneCapitals).map { ($0.id, $0) })
        let origin = cities[profile.timeZoneOrigin]!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let january = calendar.date(from: .init(year: 2026, month: 1, day: 15, hour: 12))!
        let july = calendar.date(from: .init(year: 2026, month: 7, day: 15, hour: 12))!
        expect(DinoTimeZoneJourney.displayedDate(language: code, date: january) == "15 de janeiro", "Brazilian atlas date")
        for (date, city, offset) in [(january, "manaus", -60), (july, "rioBranco", -120), (january, "washington", -120),
                                     (july, "washington", -60), (january, "london", 180), (july, "london", 240),
                                     (january, "newDelhi", 510)] {
            let journey = DinoTimeZoneJourney(origin: origin, destination: cities[city]!, date: date)
            let clock = ClockTime(hour: offset > 0 ? 23 : 0, minute: 5)
            expect(journey.offsetMinutes == offset && journey.steps(from: clock).last?.time == clock.adding(minutes: offset),
                   "Brasília time-zone offset and replay for \(city)")
        }
        for month in 0..<12 {
            let date = calendar.date(byAdding: .month, value: month, to: january)!
            for difficulty in DinoTimeZoneDifficulty.allCases {
                for step in [1, 5, 10, 15, 30, 60] {
                    let destinations = DinoTimeZoneJourney.destinations(from: origin, difficulty: difficulty, minuteStep: step,
                        date: date, regionalCapitals: profile.regionalTimeZoneCapitals)
                    let journey = DinoTimeZoneJourney.generate(language: code, difficulty: difficulty, minuteStep: step,
                                                               date: date, using: &rng)
                    expect(destinations.count >= 3 && destinations.allSatisfy { strings[$0.nameKey] != nil }
                           && journey.origin == origin && destinations.contains(journey.destination),
                           "Brasília offers localized destinations on every difficulty and time grid")
                }
            }
        }
    }

    static func testFrenchLocalization() {
        let profile = AppLanguage.french
        let code = profile.code
        expect(AppLanguage.named("fr") == profile && AppLanguage.named("fr_Latn_FR") == profile
               && profile.resourceCodes == ["fr", "en"] && !profile.runsRightToLeft,
               "French uses its own catalog and retains a generic preference code")
        expect((try? DinoNameValidator.validated("Élodie").get()) == "Élodie", "French accents are valid in names")
        let france = DinoSpeechVoice(identifier: "fr", name: "French", language: "fr-FR", quality: 1)
        let canada = DinoSpeechVoice(identifier: "ca", name: "French Canadian", language: "fr-CA", quality: 2)
        let english = DinoSpeechVoice(identifier: "en", name: "English", language: "en-GB", quality: 2)
        expect(DinoSpeechVoicePicker.preferredLanguageIdentifier(for: code) == "fr-FR"
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [canada, france]) == france
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [english, canada]) == canada
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [english]) == nil,
               "speech prefers France, then another French voice or the written question")

        let examples: [(Int, String)] = [
            (0, "sept heures"), (1, "sept heures une"), (5, "sept heures cinq"), (14, "sept heures quatorze"),
            (15, "sept heures et quart"), (16, "sept heures seize"), (20, "sept heures vingt"),
            (21, "sept heures vingt et une"), (25, "sept heures vingt-cinq"), (29, "sept heures vingt-neuf"),
            (30, "sept heures et demie"), (31, "sept heures trente et une"), (35, "sept heures trente-cinq"),
            (40, "huit heures moins vingt"), (44, "sept heures quarante-quatre"),
            (45, "huit heures moins le quart"), (46, "sept heures quarante-six"),
            (50, "huit heures moins dix"), (55, "huit heures moins cinq"), (59, "sept heures cinquante-neuf")
        ]
        for (minute, phrase) in examples {
            expect(spokenPhrase(code, hour: 7, minute: minute) == phrase, "French reading at 07:\(minute)")
        }
        expect(spokenPhrase(code, hour: 8, minute: 0) == "huit heures"
               && spokenPhrase(code, hour: 11, minute: 45) == "douze heures moins le quart"
               && spokenPhrase(code, hour: 12, minute: 45) == "une heure moins le quart",
               "the spoken hour wraps across twelve and one")

        var rng = SeededGenerator(seed: 33)
        for hour in 0..<24 {
            for minute in 0..<60 {
                let time = ClockTime(hour: hour, minute: minute)
                let prompt = profile.spokenTime.prompt(for: time, using: &rng)
                let hint = SpokenClockReadingHint(minute: minute, language: code)
                let usesNextHour = [40, 45, 50, 55].contains(minute)
                let namedHour = (hour + (usesNextHour ? 1 : 0) + 11) % 12 + 1
                expect(prompt.phrase == DinoTimeWords.time(time, language: code)
                       && hint.referenceMinute == (usesNextHour ? 60 : 0)
                       && hint.count == (usesNextHour ? 60 - minute : minute)
                       && hint.spokenHour(for: hour) == namedHour,
                       "French tiles and the hint point to the same time")
                expect(prompt.accepts(prompt.correct) && prompt.slots.first?.id == "hour",
                       "the phrase begins with the named hour and scores")
                for (index, slot) in prompt.slots.enumerated() {
                    let correct = prompt.correct.choiceIDs[index]
                    expect(Set(slot.choices.map(\.word)).count == 3 && slot.choices.contains { $0.id == correct },
                           "each French row shows three distinct choices")
                    for alternative in slot.choices where alternative.id != correct {
                        var wrong = prompt.correct.choiceIDs
                        wrong[index] = alternative.id
                        expect(!prompt.accepts(.init(choiceIDs: wrong)), "a different French tile changes the answer")
                    }
                }
            }
        }

        let digital: [(ClockTime, String, String, String)] = [
            (.init(hour: 0), "minuit", "AM", "de la nuit"),
            (.init(hour: 0, minute: 5), "minuit cinq", "AM", "de la nuit"),
            (.init(hour: 12), "midi", "PM", "de l’après-midi"),
            (.init(hour: 12, minute: 5), "midi cinq", "PM", "de l’après-midi"),
            (.init(hour: 17, minute: 5), "dix-sept heures cinq", "PM", "de l’après-midi"),
            (.init(hour: 21, minute: 31), "vingt et une heures trente et une", "PM", "du soir"),
            (.init(hour: 23, minute: 59), "vingt-trois heures cinquante-neuf", "PM", "du soir")
        ]
        for (clock, words, period, part) in digital {
            let twelve = clock.digitalReading(notation: .twelve, languageCode: code)
            let full = clock.digitalReading(notation: .twentyFour, languageCode: code)
            expect(full.text == clock.digitalText && full.period == nil && twelve.period == period
                   && !twelve.periodBeforeClock && twelve.minute == full.minute
                   && DinoTimeWords.digitalTimeInWords(clock, language: code) == words
                   && DinoTimeWords.dayPartSuffix(clock, language: code) == part,
                   "French notation, day part and reading at \(clock.digitalText)")
        }
        expect(DinoTimeWords.spokenDuration(61, language: code) == "une heure et une minute"
               && DinoTimeWords.spokenDuration(0, language: code) == "0 minute"
               && DinoTimeWords.duration(125, language: code) == "2\u{00A0}h\u{00A0}5\u{00A0}min"
               && DinoTimeWords.zoneDifference(-30, language: code) == "−0,5\u{00A0}h"
               && DinoTimeWords.digitalDuration(65, language: code) == "01:05", "French durations and offsets")
        expect(ClockTime(hour: 23, minute: 55).adding(minutes: 10) == .init(hour: 0, minute: 5)
               && ClockTime(hour: 0, minute: 5).adding(minutes: -10) == .init(hour: 23, minute: 55),
               "French clock arithmetic crosses the day boundary")

        let strings = localizedCatalog("Localizable.xcstrings", code: code)
        expect(localizedCatalog("InfoPlist.xcstrings", code: code)["CFBundleDisplayName"] == "Dino donne l’heure"
               && strings["dino.timeZone.city.paris"] == "Paris", "French app and origin names")
        testLocalizedPracticeQuestions(code: code, strings: strings)

        let capitals = Dictionary(uniqueKeysWithValues: DinoTimeZoneJourney.capitals.map { ($0.id, $0) })
        let origin = capitals["paris"]!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let winter = calendar.date(from: .init(year: 2026, month: 1, day: 15, hour: 12))!
        let summer = calendar.date(from: .init(year: 2026, month: 7, day: 15, hour: 12))!
        expect(DinoTimeZoneJourney.displayedDate(language: code, date: winter) == "15 janvier", "French atlas date")
        for (date, city, offset) in [(winter, "london", -60), (summer, "athens", 60), (summer, "berlin", 0),
                                     (winter, "ankara", 120), (summer, "ankara", 60),
                                     (winter, "newDelhi", 270), (summer, "newDelhi", 210)] {
            let journey = DinoTimeZoneJourney(origin: origin, destination: capitals[city]!, date: date)
            let clock = ClockTime(hour: offset > 0 ? 23 : 0, minute: 5)
            let end = journey.steps(from: clock).last?.time ?? clock
            expect(journey.offsetMinutes == offset && end == clock.adding(minutes: offset),
                   "Paris replay uses the real offset for \(city)")
        }
        for month in 0..<12 {
            let date = calendar.date(byAdding: .month, value: month, to: winter)!
            for difficulty in DinoTimeZoneDifficulty.allCases {
                for step in [1, 5, 10, 15, 30, 60] {
                    let destinations = DinoTimeZoneJourney.destinations(from: origin, difficulty: difficulty,
                                                                        minuteStep: step, date: date)
                    let journey = DinoTimeZoneJourney.generate(language: code, difficulty: difficulty, minuteStep: step,
                                                               date: date, using: &rng)
                    expect(destinations.count >= 2 && destinations.allSatisfy { strings[$0.nameKey] != nil }
                           && journey.origin == origin && destinations.contains(journey.destination),
                           "Paris has translated destinations at every difficulty and minute step")
                }
            }
        }
    }

    static func localizedCatalog(_ file: String, code: String) -> [String: String] {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try! Data(contentsOf: root.appendingPathComponent(file))
        let catalog = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        let entries = catalog["strings"] as! [String: [String: Any]]
        return entries.compactMapValues { entry in
            let languages = entry["localizations"] as? [String: [String: Any]]
            let localization = languages?[code]
            let plural = (localization?["variations"] as? [String: Any])?["plural"] as? [String: [String: Any]]
            let unit = (localization?["stringUnit"] ?? plural?["other"]?["stringUnit"]) as? [String: String]
            expect(unit?["state"] == "translated" && unit?["value"] != nil, "\(code) covers every entry in \(file)")
            return unit?["value"]
        }
    }

    static func testLocalizedPracticeQuestions(code: String, strings: [String: String]) {
        for type in DinoPracticeQuestion.allCases {
            for time in DinoPracticeTime.allCases {
                var generator = DinoPracticeGenerator(configuration: .init(time: time, order: .specific(type)),
                                                       seed: 71, language: code)
                for index in 0..<3 {
                    let question = generator.next(index: index)
                    let prompt = DinoQuestionPrompt.make(question: question, language: code, instructionKey: question.kind.instructionKey)
                    let text = prompt.spoken { strings[$0] ?? $0 }
                    expect(!text.contains("dino.") && !text.contains("%@") && !text.contains("$@")
                           && AnswerValidator.isCorrect(question.expectedAnswer, for: question),
                           "\(code) title and scoring for \(type) with \(time)")
                    if let key = prompt.formatKey {
                        expect(DinoQuestionPrompt.interpolated(strings[key] ?? key, arguments: prompt.arguments) != nil,
                               "\(code) templates retain each argument and its emphasis")
                    }
                    if let solution = question.spokenPrompt?.phrase {
                        expect(!text.contains(solution), "the \(code) word-tile prompt keeps the answer hidden")
                    }
                    if [.readDigital, .read24Hour].contains(question.kind) {
                        let words = question.responses.compactMap { response -> String? in
                            guard case .time(let clock) = response else { return nil }
                            return question.kind == .read24Hour ? DinoTimeWords.digitalTimeInWords(clock, language: code)
                                : DinoTimeWords.time(clock, language: code)
                        }
                        expect(Set(words).count == question.responses.count, "\(code) time choices sound distinct")
                    }
                }
            }
        }
    }

    static func testCanadianFrenchLocalization() {
        let profile = AppLanguage.canadianFrench
        let code = profile.code
        expect(AppLanguage.named("fr_CA") == profile && AppLanguage.named("fr-Latn-CA") == profile
               && AppLanguage.named("fr-FR") == .french && AppLanguage.named("fr") == .french
               && profile.resourceCodes == ["fr-CA", "fr", "en"] && !profile.runsRightToLeft,
               "Canadian French has its own saved preference and inherits generic French")
        let canada = DinoSpeechVoice(identifier: "ca", name: "Canadian French", language: "fr-CA", quality: 1)
        let france = DinoSpeechVoice(identifier: "fr", name: "French", language: "fr-FR", quality: 3)
        let english = DinoSpeechVoice(identifier: "en", name: "English", language: "en-CA", quality: 2)
        expect(DinoSpeechVoicePicker.preferredLanguageIdentifier(for: code) == "fr-CA"
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [france, canada]) == canada
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [english, france]) == france
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [english]) == nil,
               "speech prefers Canadian French, then another French voice or the written question")

        var rng = SeededGenerator(seed: 34)
        var franceRNG = rng
        for hour in 0..<24 {
            for minute in 0..<60 {
                let time = ClockTime(hour: hour, minute: minute)
                let prompt = profile.spokenTime.prompt(for: time, using: &rng)
                let francePrompt = AppLanguage.french.spokenTime.prompt(for: time, using: &franceRNG)
                let hint = SpokenClockReadingHint(minute: minute, language: code)
                let franceHint = SpokenClockReadingHint(minute: minute, language: "fr")
                expect(prompt == francePrompt && hint.referenceMinute == franceHint.referenceMinute
                       && hint.count == franceHint.count && hint.spokenHour(for: hour) == franceHint.spokenHour(for: hour)
                       && DinoTimeWords.digitalTimeInWords(time, language: code) == DinoTimeWords.digitalTimeInWords(time, language: "fr"),
                       "Canadian and generic French share the phrase, answers and hint at \(time.digitalText)")
            }
        }
        for (hour, minute, twelveHour, period) in [(0, 0, "12", "a.m."), (0, 5, "12", "a.m."), (7, 5, "7", "a.m."),
                                                  (12, 0, "12", "p.m."), (12, 5, "12", "p.m."),
                                                  (17, 5, "5", "p.m."), (23, 59, "11", "p.m.")] {
            let time = ClockTime(hour: hour, minute: minute)
            let twelve = time.digitalReading(notation: .twelve, languageCode: code)
            let full = time.digitalReading(notation: .twentyFour, languageCode: code)
            expect(twelve.hour == twelveHour && twelve.period == period && !twelve.periodBeforeClock
                   && twelve.minute == full.minute && full.period == nil && full.text == time.digitalText,
                   "Canadian French uses local 12-hour periods and preserves the 24-hour lesson display")
        }
        expect(DinoTimeWords.spokenDuration(61, language: code) == "une heure et une minute"
               && DinoTimeWords.zoneDifference(90, language: code) == "+1,5\u{00A0}h"
               && ClockTime(hour: 23, minute: 55).adding(minutes: 10) == .init(hour: 0, minute: 5)
               && ClockTime(hour: 0, minute: 5).adding(minutes: -10) == .init(hour: 23, minute: 55),
               "Canadian French displays durations, decimal offsets and arithmetic over midnight")

        let strings = localizedCatalog("Localizable.xcstrings", code: code)
        expect(localizedCatalog("InfoPlist.xcstrings", code: code)["CFBundleDisplayName"] == "Dino donne l’heure"
               && strings["dino.activity.breakfast"] == "Déjeuner" && strings["dino.activity.lunch"] == "Dîner"
               && strings["dino.timeZone.city.stJohns"] == "St. John’s"
               && strings["dino.question.chooseDigital"] == "Quelle heure est-il?", "Canadian French regional text")
        testLocalizedPracticeQuestions(code: code, strings: strings)

        let regionalCapitals = profile.regionalTimeZoneCapitals
        let capitals = Dictionary(uniqueKeysWithValues: (DinoTimeZoneJourney.capitals + regionalCapitals).map { ($0.id, $0) })
        let origin = capitals["ottawa"]!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let winter = calendar.date(from: .init(year: 2026, month: 1, day: 15, hour: 12))!
        let summer = calendar.date(from: .init(year: 2026, month: 7, day: 15, hour: 12))!
        expect(DinoTimeZoneJourney.displayedDate(language: code, date: winter) == "15 janvier", "Canadian French atlas date")
        for (date, city, offset) in [(winter, "halifax", 60), (summer, "stJohns", 90), (summer, "washington", 0),
                                     (winter, "regina", -60), (summer, "regina", -120)] {
            let journey = DinoTimeZoneJourney(origin: origin, destination: capitals[city]!, date: date)
            let clock = ClockTime(hour: offset > 0 ? 23 : 0, minute: 5)
            let end = journey.steps(from: clock).last?.time ?? clock
            expect(journey.offsetMinutes == offset && end == clock.adding(minutes: offset),
                   "Ottawa replay uses the real offset for \(city)")
        }
        for month in 0..<12 {
            let date = calendar.date(byAdding: .month, value: month, to: winter)!
            for difficulty in DinoTimeZoneDifficulty.allCases {
                for step in [1, 5, 10, 15, 30, 60] {
                    let destinations = DinoTimeZoneJourney.destinations(from: origin, difficulty: difficulty,
                                                                        minuteStep: step, date: date, regionalCapitals: regionalCapitals)
                    let journey = DinoTimeZoneJourney.generate(language: code, difficulty: difficulty, minuteStep: step,
                                                               date: date, using: &rng)
                    expect(destinations.allSatisfy { strings[$0.nameKey] != nil }
                           && journey.origin == origin && destinations.contains(journey.destination)
                           && journey.offsetMinutes.isMultiple(of: step),
                           "Ottawa has translated destinations at every difficulty and minute step")
                }
            }
        }
    }

    static func testUrduLocalization() {
        let profile = AppLanguage.pakistaniUrdu
        let code = profile.code
        expect(["ur-PK", "ur_PK", "ur-Arab-PK", "ur-IN"].allSatisfy { AppLanguage.named($0) == profile }
               && AppLanguage.named("ur-Latn-PK") == nil && profile.runsRightToLeft
               && profile.resourceCodes == ["ur", "en"], "Urdu resolves by script with a Pakistani default")
        expect((try? DinoNameValidator.validated("عائشہ خان").get()) == "عائشہ خان"
               && DinoTimeWords.parsedInteger("۱۲") == 12, "Urdu names and Urdu decimal digits are accepted")
        let pakistan = DinoSpeechVoice(identifier: "pk", name: "Urdu", language: "ur-PK", quality: 1)
        let india = DinoSpeechVoice(identifier: "in", name: "Urdu", language: "ur-IN", quality: 3)
        let arabic = DinoSpeechVoice(identifier: "ar", name: "Arabic", language: "ar-SA", quality: 3)
        expect(DinoSpeechVoicePicker.preferredLanguageIdentifier(for: code) == "ur-PK"
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [arabic, india, pakistan]) == pakistan
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [arabic, india]) == india
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [arabic]) == nil,
               "Urdu speech ranks regional Urdu voices and falls back to written questions")

        let examples: [(Int, String)] = [
            (0, "سات بجے"), (1, "سات بج کر ایک منٹ"), (5, "سات بج کر پانچ منٹ"),
            (14, "سات بج کر چودہ منٹ"), (15, "سوا سات بجے"), (16, "سات بج کر سولہ منٹ"),
            (20, "سات بج کر بیس منٹ"), (25, "سات بج کر پچیس منٹ"), (29, "سات بج کر انتیس منٹ"),
            (30, "ساڑھے سات بجے"), (31, "سات بج کر اکتیس منٹ"), (35, "سات بج کر پینتیس منٹ"),
            (40, "سات بج کر چالیس منٹ"), (44, "سات بج کر چوالیس منٹ"), (45, "پونے آٹھ بجے"),
            (46, "سات بج کر چھیالیس منٹ"), (55, "سات بج کر پچپن منٹ"), (59, "سات بج کر انسٹھ منٹ")
        ]
        for (minute, phrase) in examples {
            expect(spokenPhrase(code, hour: 7, minute: minute) == phrase, "Urdu time at 7:\(minute)")
        }
        expect(spokenPhrase(code, hour: 8, minute: 0) == "آٹھ بجے"
               && spokenPhrase(code, hour: 1, minute: 30) == "ڈیڑھ بجے"
               && spokenPhrase(code, hour: 2, minute: 30) == "ڈھائی بجے"
               && spokenPhrase(code, hour: 12, minute: 45) == "پونے ایک بجے",
               "Urdu handles the two irregular half hours and quarters across twelve")

        var rng = SeededGenerator(seed: 42)
        for hour in 0..<24 {
            for minute in 0..<60 {
                let time = ClockTime(hour: hour, minute: minute)
                let prompt = profile.spokenTime.prompt(for: time, using: &rng)
                let hint = SpokenClockReadingHint(minute: minute, language: code)
                let reference = minute == 45 ? 60 : 0
                let namedHour = (hour + (minute == 45 ? 1 : 0) + 11) % 12 + 1
                let slots: [String] = switch minute {
                case 0, 30: ["hour"]
                case 15, 45: ["quarter", "hour"]
                default: ["hour", "minutes"]
                }
                expect(prompt.phrase == DinoTimeWords.time(time, language: code) && prompt.slots.map(\.id) == slots
                       && hint.spokenHour(for: hour) == namedHour && hint.referenceMinute == reference
                       && hint.startMinute == min(minute, reference) && hint.endMinute == max(minute, reference),
                       "Urdu tiles and visual explanation describe the same time")
                let question = spokenQuestion(prompt: prompt, time: time)
                expect(AnswerValidator.isCorrect(question.expectedAnswer, for: question), "the Urdu phrase scores")
                for (index, slot) in prompt.slots.enumerated() {
                    expect(slot.choices.count == 3 && Set(slot.choices.map(\.word)).count == 3
                           && slot.choices.contains { $0.id == prompt.correct.choiceIDs[index] },
                           "each Urdu row shows distinct choices and the correct tile")
                    for choice in slot.choices where choice.id != prompt.correct.choiceIDs[index] {
                        var wrong = prompt.correct.choiceIDs
                        wrong[index] = choice.id
                        expect(!AnswerValidator.isCorrect(.spoken(.init(choiceIDs: wrong)), for: question),
                               "a different Urdu tile is marked incorrect")
                    }
                }
            }
        }

        let digital: [(ClockTime, String, String, String)] = [
            (.init(hour: 0), "صفر بجے", "رات بارہ بجے", "AM"),
            (.init(hour: 0, minute: 5), "صفر بج کر پانچ منٹ", "رات بارہ بج کر پانچ منٹ", "AM"),
            (.init(hour: 12), "بارہ بجے", "دوپہر بارہ بجے", "PM"),
            (.init(hour: 12, minute: 5), "بارہ بج کر پانچ منٹ", "دوپہر بارہ بج کر پانچ منٹ", "PM"),
            (.init(hour: 17, minute: 5), "سترہ بج کر پانچ منٹ", "دوپہر پانچ بج کر پانچ منٹ", "PM"),
            (.init(hour: 23, minute: 59), "تیئیس بج کر انسٹھ منٹ", "شام گیارہ بج کر انسٹھ منٹ", "PM")
        ]
        for (clock, formal, colloquial, period) in digital {
            let twelve = clock.digitalReading(notation: .twelve, languageCode: code)
            let full = clock.digitalReading(notation: .twentyFour, languageCode: code)
            expect(full.text == clock.digitalText && full.period == nil && twelve.period == period
                   && !twelve.periodOnLeft(inRightToLeftInterface: profile.runsRightToLeft) && twelve.minute == full.minute
                   && DinoTimeWords.digitalTimeInWords(clock, language: code) == formal
                   && DinoTimeWords.time(clock, language: code, dayPart: true) == colloquial,
                   "Urdu notation and both readings for \(clock.digitalText)")
        }
        expect(DinoTimeWords.spokenDuration(61, language: code) == "ایک گھنٹہ اور ایک منٹ"
               && DinoTimeWords.duration(125, language: code) == "2 گھنٹے 5 منٹ"
               && DinoTimeWords.duration(60, language: code) == "1 گھنٹہ"
               && DinoTimeWords.zoneDifference(-30, language: code) == "\u{2066}−0.5\u{2069} گھنٹے"
               && DinoTimeWords.digitalDuration(65, language: code) == "01:05", "Urdu durations and signed offsets")
        expect(ClockTime(hour: 23, minute: 55).adding(minutes: 10) == .init(hour: 0, minute: 5)
               && ClockTime(hour: 0, minute: 5).adding(minutes: -10) == .init(hour: 23, minute: 55),
               "Urdu clock arithmetic wraps in both directions")

        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        func localizedStrings(in file: String) -> [String: String] {
            let data = try! Data(contentsOf: root.appendingPathComponent(file))
            let catalog = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            let entries = catalog["strings"] as! [String: [String: Any]]
            return entries.compactMapValues { entry in
                let languages = entry["localizations"] as? [String: [String: Any]]
                let unit = languages?[code]?["stringUnit"] as? [String: String]
                expect(unit?["state"] == "translated" && unit?["value"] != nil, "Urdu covers every entry in \(file)")
                return unit?["value"]
            }
        }
        let strings = localizedStrings(in: "Localizable.xcstrings")
        expect(localizedStrings(in: "InfoPlist.xcstrings")["CFBundleDisplayName"] == "ڈائنو کی گھڑی"
               && strings["dino.timeZone.city.islamabad"] == "اسلام آباد", "Urdu app and origin names")
        for type in DinoPracticeQuestion.allCases {
            for time in DinoPracticeTime.allCases {
                var generator = DinoPracticeGenerator(configuration: .init(time: time, order: .specific(type)),
                                                       seed: 71, language: code)
                for index in 0..<3 {
                    let question = generator.next(index: index)
                    let prompt = DinoQuestionPrompt.make(question: question, language: code, instructionKey: question.kind.instructionKey)
                    let text = prompt.spoken { strings[$0] ?? $0 }
                    expect(!text.contains("dino.") && !text.contains("$@") && !text.contains("%@")
                           && AnswerValidator.isCorrect(question.expectedAnswer, for: question),
                           "Urdu title and scoring for \(type) with \(time)")
                    if let key = prompt.formatKey {
                        expect(DinoQuestionPrompt.interpolated(strings[key] ?? key, arguments: prompt.arguments) != nil,
                               "Urdu templates use all arguments")
                    }
                    if let solution = question.spokenPrompt?.phrase {
                        expect(!text.contains(solution), "reading out Urdu tile instructions keeps the answer hidden")
                    }
                    if [.readDigital, .read24Hour].contains(question.kind) {
                        let choices = question.responses.compactMap { response -> String? in
                            guard case .time(let clock) = response else { return nil }
                            return question.kind == .read24Hour ? DinoTimeWords.digitalTimeInWords(clock, language: code)
                                : DinoTimeWords.time(clock, language: code)
                        }
                        expect(Set(choices).count == question.responses.count, "each Urdu time choice reads differently")
                    }
                }
            }
        }

        let capitals = Dictionary(uniqueKeysWithValues: (DinoTimeZoneJourney.capitals + profile.regionalTimeZoneCapitals).map { ($0.id, $0) })
        let origin = capitals["islamabad"]!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let winter = calendar.date(from: .init(year: 2026, month: 1, day: 15, hour: 12))!
        let summer = calendar.date(from: .init(year: 2026, month: 7, day: 15, hour: 12))!
        expect(DinoTimeZoneJourney.displayedDate(language: code, date: winter) == "15 جنوری", "Urdu atlas date")
        for destination in [capitals["muscat"]!, origin, capitals["dhaka"]!] {
            let reference = ClockTime(hour: 1)
            let journey = DinoTimeZoneJourney(origin: origin, destination: destination, date: winter)
            let question = ClockQuestion(id: 0, kind: .timeZone, target: reference.adding(minutes: journey.offsetMinutes),
                                         options: [], activity: nil, companionClocks: [], relatedTimes: [reference],
                                         timeZoneJourney: journey)
            let prompt = DinoQuestionPrompt.make(question: question, language: code, instructionKey: question.kind.instructionKey)
            let text = prompt.spoken { strings[$0] ?? $0 }
            expect(text.hasPrefix("اسلام آباد میں وقت: ایک بجے۔"), "Urdu time zones present a one-o'clock label without plural agreement")
        }
        for (date, city, offset) in [(winter, "london", -300), (summer, "london", -240),
                                     (winter, "dhaka", 60), (winter, "muscat", -60),
                                     (summer, "kabul", -30), (summer, "newDelhi", 30)] {
            let journey = DinoTimeZoneJourney(origin: origin, destination: capitals[city]!, date: date)
            let clock = ClockTime(hour: offset > 0 ? 23 : 0, minute: 5)
            expect(journey.offsetMinutes == offset && journey.steps(from: clock).last?.time == clock.adding(minutes: offset),
                   "Islamabad replay uses the real offset for \(city)")
        }
        for month in 0..<12 {
            let date = calendar.date(byAdding: .month, value: month, to: winter)!
            for difficulty in DinoTimeZoneDifficulty.allCases {
                for step in [1, 5, 10, 15, 30, 60] {
                    let destinations = DinoTimeZoneJourney.destinations(from: origin, difficulty: difficulty, minuteStep: step,
                        date: date, regionalCapitals: profile.regionalTimeZoneCapitals, regionalMinimum: profile.regionalTimeZoneMinimum)
                    let journey = DinoTimeZoneJourney.generate(language: code, difficulty: difficulty, minuteStep: step,
                                                               date: date, using: &rng)
                    expect(destinations.count >= 2 && destinations.allSatisfy { strings[$0.nameKey] != nil }
                           && journey.origin == origin && destinations.contains(journey.destination),
                           "Islamabad has several translated destinations for every level, clock step and month")
                }
            }
        }
    }

    static func testHebrewLocalization() {
        let profile = AppLanguage.hebrew
        let code = profile.code
        let hebrewVoice = DinoSpeechVoice(identifier: "he", name: "Hebrew", language: "he-IL", quality: 1)
        let arabicVoice = DinoSpeechVoice(identifier: "ar", name: "Arabic", language: "ar-SA", quality: 3)
        expect(["he-IL", "he_IL", "he-Hebr-IL", "iw-IL"].allSatisfy { AppLanguage.named($0) == profile }
               && AppLanguage.named("he-Latn-IL") == nil && profile.runsRightToLeft
               && profile.resourceCodes == ["he", "en"], "Hebrew uses its native script and bundle")
        expect((try? DinoNameValidator.validated("נועה לוי").get()) == "נועה לוי",
               "Hebrew player names retain their letters and spaces")
        expect(DinoSpeechVoicePicker.preferredLanguageIdentifier(for: code) == "he-IL"
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [arabicVoice, hebrewVoice]) == hebrewVoice
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [arabicVoice]) == nil,
               "Hebrew speech uses a matching voice when installed")

        let examples: [(Int, String)] = [
            (0, "שבע"), (1, "שבע ודקה אחת"), (2, "שבע ושתי דקות"), (5, "שבע וחמש דקות"),
            (14, "שבע וארבע עשרה דקות"), (15, "שבע ורבע"), (16, "שבע ושש עשרה דקות"),
            (20, "שבע ועשרים דקות"), (25, "שבע ועשרים וחמש דקות"), (29, "שבע ועשרים ותשע דקות"),
            (30, "שבע וחצי"), (31, "עשרים ותשע דקות לשמונה"), (35, "עשרים וחמש דקות לשמונה"),
            (40, "עשרים דקות לשמונה"), (44, "שש עשרה דקות לשמונה"), (45, "רבע לשמונה"),
            (46, "ארבע עשרה דקות לשמונה"), (55, "חמש דקות לשמונה"), (59, "דקה אחת לשמונה")
        ]
        for (minute, reading) in examples {
            expect(spokenPhrase(code, hour: 7, minute: minute) == reading, "Hebrew reading for 7:\(minute)")
        }
        expect(spokenPhrase(code, hour: 8, minute: 0) == "שמונה"
               && spokenPhrase(code, hour: 11, minute: 45) == "רבע לשתים עשרה"
               && spokenPhrase(code, hour: 12, minute: 59) == "דקה אחת לאחת",
               "Hebrew names the next hour across twelve and one")

        var rng = SeededGenerator(seed: 42)
        for hour in 0..<24 {
            for minute in 0..<60 {
                let clock = ClockTime(hour: hour, minute: minute)
                let prompt = profile.spokenTime.prompt(for: clock, using: &rng)
                let hint = SpokenClockReadingHint(minute: minute, language: code)
                let remaining = minute > 30
                let namedHour = (hour + (remaining ? 1 : 0) + 11) % 12 + 1
                let slotIDs = remaining ? ["remaining", "hour"] : minute == 0 ? ["hour"] : ["hour", "minutes"]
                expect(prompt.phrase == DinoTimeWords.time(clock, language: code) && prompt.slots.map(\.id) == slotIDs
                       && hint.spokenHour(for: hour) == namedHour && hint.referenceMinute == (remaining ? 60 : 0)
                       && hint.count == (remaining ? 60 - minute : minute)
                       && hint.startMinute == (remaining ? minute : 0) && hint.endMinute == (remaining ? 60 : minute),
                       "Hebrew word order and clock hint use the same hour and minute count")
                let question = spokenQuestion(prompt: prompt, time: clock)
                expect(AnswerValidator.isCorrect(question.expectedAnswer, for: question), "the Hebrew reading scores")
                for (index, slot) in prompt.slots.enumerated() {
                    expect(slot.choices.count == 3 && Set(slot.choices.map(\.word)).count == 3
                           && slot.choices.contains { $0.id == prompt.correct.choiceIDs[index] },
                           "the correct tile is available among distinct choices")
                    for wrong in slot.choices where wrong.id != prompt.correct.choiceIDs[index] {
                        var picks = prompt.correct.choiceIDs
                        picks[index] = wrong.id
                        expect(!AnswerValidator.isCorrect(.spoken(.init(choiceIDs: picks)), for: question),
                               "swapping a Hebrew tile changes the answer")
                    }
                }
            }
        }

        let digital: [(ClockTime, String, String, String)] = [
            (.init(hour: 0), "חצות", "שתים עשרה בלילה", "12:00"),
            (.init(hour: 0, minute: 5), "אפס וחמש דקות", "שתים עשרה וחמש דקות בלילה", "12:05"),
            (.init(hour: 12), "שתים עשרה בדיוק", "שתים עשרה אחר הצהריים", "12:00"),
            (.init(hour: 12, minute: 5), "שתים עשרה וחמש דקות", "שתים עשרה וחמש דקות אחר הצהריים", "12:05"),
            (.init(hour: 17, minute: 5), "שבע עשרה וחמש דקות", "חמש וחמש דקות אחר הצהריים", "5:05"),
            (.init(hour: 23, minute: 59), "עשרים ושלוש וחמישים ותשע דקות", "דקה אחת לשתים עשרה בערב", "11:59"),
        ]
        for (clock, formal, colloquial, twelve) in digital {
            let localized = clock.digitalReading(notation: .twelve, languageCode: code)
            let twentyFour = clock.digitalReading(notation: .twentyFour, languageCode: code)
            expect(twentyFour.hour == String(clock.hour) && twentyFour.minute == String(format: "%02d", clock.minute)
                   && twentyFour.separator == ":" && twentyFour.period == nil
                   && localized.text.hasPrefix(twelve) && localized.period?.isEmpty == false && !localized.periodBeforeClock
                   && DinoTimeWords.digitalTimeInWords(clock, language: code) == formal
                   && DinoTimeWords.time(clock, language: code, dayPart: true) == colloquial,
                   "Hebrew notation, day part and speech agree for \(clock.digitalText)")
        }
        expect(DinoTimeWords.spokenDuration(121, language: code) == "שעתיים ודקה אחת"
               && DinoTimeWords.spokenDuration(62, language: code) == "שעה אחת ושתי דקות"
               && DinoTimeWords.compactDuration(hours: 1, minutes: 5, language: code) == "1 ש׳ 5 דק׳"
               && DinoTimeWords.zoneDifference(-150, language: code) == "\u{2066}−2.5\u{2069} ש׳"
               && DinoTimeWords.digitalDuration(65, language: code) == "01:05",
               "duration units and signed hour offsets preserve their meaning in Hebrew")
        expect(ClockTime(hour: 23, minute: 55).adding(minutes: 10) == .init(hour: 0, minute: 5)
               && ClockTime(hour: 0, minute: 5).adding(minutes: -10) == .init(hour: 23, minute: 55),
               "Hebrew clock arithmetic crosses the day boundary")

        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        func localizedStrings(from file: String) -> [String: String] {
            let data = try! Data(contentsOf: root.appendingPathComponent(file))
            let catalog = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            let entries = catalog["strings"] as! [String: [String: Any]]
            return entries.compactMapValues { entry in
                let languages = entry["localizations"] as? [String: [String: Any]]
                let unit = languages?[code]?["stringUnit"] as? [String: String]
                expect(unit?["state"] == "translated" && unit?["value"] != nil, "Hebrew covers every string in \(file)")
                return unit?["value"]
            }
        }
        let strings = localizedStrings(from: "Localizable.xcstrings")
        expect(localizedStrings(from: "InfoPlist.xcstrings")["CFBundleDisplayName"] == "השעון של דינו"
               && strings["dino.timeZone.city.jerusalem"] == "ירושלים", "Hebrew app and origin names are localized")
        for type in DinoPracticeQuestion.allCases {
            for time in DinoPracticeTime.allCases {
                var generator = DinoPracticeGenerator(configuration: .init(time: time, order: .specific(type)),
                                                       seed: 71, language: code)
                for index in 0..<3 {
                    let question = generator.next(index: index)
                    let prompt = DinoQuestionPrompt.make(question: question, language: code, instructionKey: question.kind.instructionKey)
                    let text = prompt.spoken { strings[$0] ?? $0 }
                    expect(!text.contains("dino.") && !text.contains("$@") && !text.contains("%@")
                           && AnswerValidator.isCorrect(question.expectedAnswer, for: question),
                           "Hebrew question title and answer resolve for \(type) and \(time)")
                    if let format = prompt.formatKey {
                        expect(DinoQuestionPrompt.interpolated(strings[format] ?? format, arguments: prompt.arguments) != nil,
                               "each Hebrew question template uses all the arguments")
                    }
                    if let solution = question.spokenPrompt?.phrase {
                        expect(!text.contains(solution), "spoken instructions leave the tiles to the player")
                    }
                    if [.readDigital, .read24Hour].contains(question.kind) {
                        let choices = question.responses.compactMap { response -> String? in
                            guard case .time(let clock) = response else { return nil }
                            return question.kind == .read24Hour ? DinoTimeWords.digitalTimeInWords(clock, language: code)
                                : DinoTimeWords.time(clock, language: code)
                        }
                        expect(Set(choices).count == question.responses.count, "every Hebrew time choice reads differently")
                    }
                }
            }
        }

        let capitals = Dictionary(uniqueKeysWithValues: (DinoTimeZoneJourney.capitals + profile.regionalTimeZoneCapitals).map { ($0.id, $0) })
        let origin = capitals["jerusalem"]!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let winter = calendar.date(from: .init(year: 2026, month: 1, day: 15, hour: 12))!
        let spring = calendar.date(from: .init(year: 2026, month: 3, day: 28, hour: 12))!
        let summer = calendar.date(from: .init(year: 2026, month: 7, day: 15, hour: 12))!
        expect(DinoTimeZoneJourney.displayedDate(language: code, date: winter) == "15 בינואר",
               "the atlas uses a localized civil date")
        for (date, city, offset) in [(winter, "london", -120), (spring, "london", -180), (summer, "london", -120),
                                     (winter, "riyadh", 60), (summer, "riyadh", 0), (summer, "newDelhi", 150)] {
            let journey = DinoTimeZoneJourney(origin: origin, destination: capitals[city]!, date: date)
            let clock = ClockTime(hour: offset > 0 ? 23 : 0, minute: 5)
            expect(journey.offsetMinutes == offset
                   && (journey.steps(from: clock).last?.time ?? clock) == clock.adding(minutes: offset),
                   "Jerusalem time-zone replay applies the correct seasonal offset")
        }
        for day in 0..<365 {
            let date = calendar.date(byAdding: .day, value: day, to: winter)!
            for difficulty in DinoTimeZoneDifficulty.allCases {
                for step in [1, 5, 10, 15, 30, 60] {
                    let journey = DinoTimeZoneJourney.generate(language: code, difficulty: difficulty, minuteStep: step,
                                                               date: date, using: &rng)
                    expect(journey.origin == origin && journey.offsetMinutes != 0 && journey.offsetMinutes.isMultiple(of: step)
                           && strings[journey.destination.nameKey] != nil,
                           "all time-zone difficulties keep a localized destination from Jerusalem throughout the year")
                }
            }
        }
    }

    static func testJapaneseLocalization() {
        let profile = AppLanguage.japanese
        let code = profile.code
        expect(AppLanguage.named("ja_JP") == profile && AppLanguage.named("ja-Jpan-JP") == profile
               && AppLanguage.named("ja-Latn-JP") == nil && !profile.runsRightToLeft
               && profile.resourceCodes == ["ja", "en"], "Japanese uses the native script and bundle")
        expect((try? DinoNameValidator.validated("山田 はな").get()) == "山田 はな"
               && DinoTimeWords.parsedInteger("１２") == 12, "Japanese names and full-width decimal digits work")
        let japanese = DinoSpeechVoice(identifier: "ja", name: "Japanese", language: "ja-JP", quality: 1)
        let english = DinoSpeechVoice(identifier: "en", name: "English", language: "en", quality: 3)
        expect(DinoSpeechVoicePicker.preferredLanguageIdentifier(for: code) == "ja-JP"
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [english, japanese]) == japanese
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [english]) == nil,
               "the Japanese lesson uses a Japanese voice when available")

        let examples: [(Int, String)] = [
            (0, ""), (1, "いっぷん"), (5, "ごふん"), (14, "じゅうよんぷん"), (15, "じゅうごふん"),
            (16, "じゅうろっぷん"), (20, "にじゅっぷん"), (25, "にじゅうごふん"), (29, "にじゅうきゅうふん"),
            (30, "はん"), (31, "さんじゅういっぷん"), (35, "さんじゅうごふん"), (40, "よんじゅっぷん"),
            (44, "よんじゅうよんぷん"), (45, "よんじゅうごふん"), (46, "よんじゅうろっぷん"),
            (55, "ごじゅうごふん"), (59, "ごじゅうきゅうふん")
        ]
        for (minute, ending) in examples {
            let phrase = ending.isEmpty ? "しちじ" : "しちじ \(ending)"
            expect(spokenPhrase(code, hour: 7, minute: minute) == phrase, "Japanese reading for 7:\(minute)")
        }
        expect(spokenPhrase(code, hour: 8, minute: 0) == "はちじ"
               && spokenPhrase(code, hour: 4, minute: 8) == "よじ はっぷん"
               && spokenPhrase(code, hour: 9, minute: 3) == "くじ さんぷん", "irregular readings stay together with their counters")
        var rng = SeededGenerator(seed: 42)
        for hour in 0..<24 {
            for minute in 0..<60 {
                let clock = ClockTime(hour: hour, minute: minute)
                let prompt = profile.spokenTime.prompt(for: clock, using: &rng)
                let hint = SpokenClockReadingHint(minute: minute, language: code)
                let expectedHour = hour.isMultiple(of: 12) ? 12 : hour % 12
                expect(prompt.phrase == DinoTimeWords.time(clock, language: code)
                       && prompt.slots.map(\.id) == (minute == 0 ? ["hour"] : ["hour", "minutes"])
                       && hint.spokenHour(for: hour) == expectedHour && hint.referenceMinute == 0
                       && hint.count == minute && hint.scaleLabel == String(minute),
                       "Japanese words and visual hint describe elapsed minutes from the current hour")
                let question = spokenQuestion(prompt: prompt, time: clock)
                expect(AnswerValidator.isCorrect(question.expectedAnswer, for: question), "the correct Japanese phrase scores")
                for (index, slot) in prompt.slots.enumerated() {
                    expect(Set(slot.choices.map(\.word)).count == 3
                           && slot.choices.contains { $0.id == prompt.correct.choiceIDs[index] }, "three distinct Japanese options")
                    for choice in slot.choices where choice.id != prompt.correct.choiceIDs[index] {
                        var ids = prompt.correct.choiceIDs
                        ids[index] = choice.id
                        expect(!AnswerValidator.isCorrect(.spoken(.init(choiceIDs: ids)), for: question),
                               "a different tile gives a different time")
                    }
                }
            }
        }

        let digital: [(Int, Int, String, String, String)] = [
            (0, 0, "0:00", "午前0:00", "れいじ"), (0, 5, "0:05", "午前0:05", "れいじ ごふん"),
            (12, 0, "12:00", "午後0:00", "じゅうにじ"), (12, 5, "12:05", "午後0:05", "じゅうにじ ごふん"),
            (17, 5, "17:05", "午後5:05", "じゅうしちじ ごふん"), (23, 59, "23:59", "午後11:59", "にじゅうさんじ ごじゅうきゅうふん")
        ]
        for (hour, minute, twentyFour, twelve, words) in digital {
            let clock = ClockTime(hour: hour, minute: minute)
            let local = clock.digitalReading(notation: .twelve, languageCode: code)
            expect(local.text == twelve && local.periodBeforeClock && local.separator == ":"
                   && clock.digitalReading(notation: .twentyFour, languageCode: code).text == twentyFour
                   && DinoTimeWords.digitalTimeInWords(clock, language: code) == words, "Japanese format and digital reading for \(twentyFour)")
        }
        expect(profile.spokenTime.promptNotation == .twentyFour, "the word exercise keeps noon as 12")
        expect(DinoTimeWords.spokenDuration(65, language: code) == "1時間5分"
               && DinoTimeWords.duration(65, language: code) == "1時間5分"
               && DinoTimeWords.compactDuration(hours: 1, minutes: 5, language: code, padMinutes: true) == "1時間05分"
               && DinoTimeWords.minutes(1, language: code) == "1分", "duration units preserve their meaning and spacing")
        expect(ClockTime(hour: 23, minute: 55).adding(minutes: 10) == .init(hour: 0, minute: 5)
               && ClockTime(hour: 0, minute: 5).adding(minutes: -10) == .init(hour: 23, minute: 55),
               "time arithmetic wraps at midnight")

        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        func japaneseStrings(from file: String) -> [String: String] {
            let data = try! Data(contentsOf: root.appendingPathComponent(file))
            let catalog = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            let entries = catalog["strings"] as! [String: [String: Any]]
            var localized: [String: String] = [:]
            for (key, entry) in entries {
                let languages = entry["localizations"] as? [String: [String: Any]]
                let unit = languages?[code]?["stringUnit"] as? [String: String]
                expect(unit?["state"] == "translated" && unit?["value"] != nil, "\(key) has a Japanese value in \(file)")
                localized[key] = unit?["value"]
            }
            return localized
        }
        let strings = japaneseStrings(from: "Localizable.xcstrings")
        expect(japaneseStrings(from: "InfoPlist.xcstrings")["CFBundleDisplayName"] == "ディノのとけい", "the iOS app name is Japanese")
        for type in DinoPracticeQuestion.allCases {
            for time in DinoPracticeTime.allCases {
                var generator = DinoPracticeGenerator(configuration: .init(time: time, order: .specific(type)), seed: 71, language: code)
                for index in 0..<3 {
                    let question = generator.next(index: index)
                    let prompt = DinoQuestionPrompt.make(question: question, language: code, instructionKey: question.kind.instructionKey)
                    let text = prompt.spoken { strings[$0] ?? $0 }
                    expect(!text.contains("dino.") && !text.contains("$@") && !text.contains("%@"),
                           "the Japanese instruction resolves for \(type) and \(time)")
                    if let format = prompt.formatKey {
                        expect(DinoQuestionPrompt.interpolated(strings[format] ?? format, arguments: prompt.arguments) != nil,
                               "the Japanese template supplies all question arguments")
                    }
                    expect(AnswerValidator.isCorrect(question.expectedAnswer, for: question), "Japanese practice accepts its expected result")
                    if question.kind == .timeZone {
                        expect(question.timeZoneJourney?.origin.id == "tokyo", "Japanese time-zone questions start in Tokyo")
                    }
                    if question.kind == .sayTime, let solution = question.spokenPrompt?.phrase {
                        expect(!text.contains(solution), "the spoken instruction leaves the solution to the player")
                    }
                }
            }
        }
        let capitals = DinoTimeZoneJourney.capitals + profile.regionalTimeZoneCapitals
        let tokyo = capitals.first { $0.id == "tokyo" }!
        let utc = TimeZone(secondsFromGMT: 0)!
        for month in 1...12 {
            let date = Calendar(identifier: .gregorian).date(from: .init(timeZone: utc, year: 2026, month: month, day: 15))!
            expect(DinoTimeZoneJourney.displayedDate(language: code, date: date) == "\(month)月15日", "dates use the Japanese month-day order")
            for difficulty in DinoTimeZoneDifficulty.allCases {
                for step in [1, 5, 10, 15, 30, 60] {
                    let journey = DinoTimeZoneJourney.generate(language: code, difficulty: difficulty, minuteStep: step, date: date, using: &rng)
                    expect(journey.origin == tokyo && journey.offsetMinutes != 0 && journey.offsetMinutes.isMultiple(of: step)
                           && strings[journey.destination.nameKey] != nil, "every difficulty uses a suitable, localized destination from Tokyo")
                }
            }
            let offsets = ["beijing": -60, "manila": -60, "hanoi": -120, "newDelhi": -210, "seoul": 0]
            for (id, difference) in offsets {
                let city = capitals.first { $0.id == id }!
                let journey = DinoTimeZoneJourney(origin: tokyo, destination: city, date: date)
                let start = ClockTime(hour: 0, minute: 5)
                expect(journey.offsetMinutes == difference
                       && (journey.steps(from: start).last?.time ?? start) == start.adding(minutes: difference),
                       "real Tokyo offsets and replay agree")
            }
            if month == 1 || month == 7 {
                let city = capitals.first { $0.id == "wellington" }!
                let journey = DinoTimeZoneJourney(origin: tokyo, destination: city, date: date)
                expect(journey.offsetMinutes == (month == 1 ? 240 : 180), "Wellington observes seasonal time changes")
            }
        }
    }

    static func testArabicLocalization() {
        let profile = AppLanguage.saudiArabic
        let code = profile.code
        expect(AppLanguage.named("ar_SA") == profile && AppLanguage.named("ar-Arab-SA") == profile
               && AppLanguage.named("ar-Latn-SA") == nil && profile.runsRightToLeft && profile.resourceCodes == ["ar", "en"],
               "Saudi Arabic follows the Arabic script and uses the Arabic bundle")
        expect((try? DinoNameValidator.validated("عَبْد الله").get()) == "عَبْد الله",
               "a player name retains Arabic letters and marks")
        expect(DinoTimeWords.parsedInteger("١٢٣") == 123 && DinoTimeWords.parsedInteger("۱۲۳") == 123
               && DinoTimeWords.parsedInteger("123") == 123 && DinoTimeWords.parsedInteger("Ⅻ") == nil
               && DinoTimeWords.parsedInteger("١٢ن") == nil,
               "numeric entry accepts decimal keypad digits and rejects nondecimal characters")
        let localVoice = DinoSpeechVoice(identifier: "sa", name: "Arabic", language: "ar-SA", quality: 1)
        let regionalVoice = DinoSpeechVoice(identifier: "eg", name: "Arabic", language: "ar-EG", quality: 3)
        let englishVoice = DinoSpeechVoice(identifier: "en", name: "English", language: "en-GB", quality: 3)
        expect(DinoSpeechVoicePicker.preferredLanguageIdentifier(for: code) == "ar-SA"
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [regionalVoice, localVoice]) == localVoice
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [regionalVoice, englishVoice]) == regionalVoice
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [englishVoice]) == nil,
               "prefer the Saudi voice, fall back to Arabic, and keep the written question if no Arabic voice exists")

        let examples: [(Int, Int, String, Int, Int)] = [
            (7, 0, "الساعة السابعة تمامًا", 0, 7),
            (7, 1, "الساعة السابعة ودقيقة واحدة", 0, 7),
            (7, 5, "الساعة السابعة وخمس دقائق", 0, 7),
            (7, 14, "الساعة السابعة وأربع عشرة دقيقة", 0, 7),
            (7, 15, "الساعة السابعة والربع", 0, 7),
            (7, 16, "الساعة السابعة وست عشرة دقيقة", 0, 7),
            (7, 20, "الساعة السابعة وعشرون دقيقة", 0, 7),
            (7, 25, "الساعة السابعة وخمس وعشرون دقيقة", 0, 7),
            (7, 29, "الساعة السابعة وتسع وعشرون دقيقة", 0, 7),
            (7, 30, "الساعة السابعة والنصف", 0, 7),
            (7, 31, "الساعة الثامنة إلا تسعًا وعشرين دقيقة", 60, 8),
            (7, 35, "الساعة الثامنة إلا خمسًا وعشرين دقيقة", 60, 8),
            (7, 40, "الساعة الثامنة إلا عشرين دقيقة", 60, 8),
            (7, 44, "الساعة الثامنة إلا ست عشرة دقيقة", 60, 8),
            (7, 45, "الساعة الثامنة إلا ربعًا", 60, 8),
            (7, 46, "الساعة الثامنة إلا أربع عشرة دقيقة", 60, 8),
            (7, 55, "الساعة الثامنة إلا خمس دقائق", 60, 8),
            (7, 59, "الساعة الثامنة إلا دقيقة واحدة", 60, 8),
            (8, 0, "الساعة الثامنة تمامًا", 0, 8)
        ]
        for (hour, minute, wording, referenceMinute, referenceHour) in examples {
            let time = ClockTime(hour: hour, minute: minute)
            let hint = SpokenClockReadingHint(minute: minute, language: code)
            expect(spokenPhrase(code, hour: hour, minute: minute) == wording
                   && DinoTimeWords.time(time, language: code) == wording && hint.referenceMinute == referenceMinute
                   && hint.spokenHour(for: hour) == referenceHour, "the phrase and minute guide agree at \(hour):\(minute)")
        }
        var rng = SeededGenerator(seed: 35)
        for hour in 0..<24 {
            for minute in 0..<60 {
                let time = ClockTime(hour: hour, minute: minute)
                let prompt = profile.spokenTime.prompt(for: time, using: &rng)
                let hint = SpokenClockReadingHint(minute: minute, language: code)
                let expectedReference = minute > 30 ? 60 : 0
                expect(prompt.slots.count == 2 && prompt.slots.first?.id == "hour"
                       && prompt.slots.allSatisfy { $0.choices.count == 3 && Set($0.choices.map(\.word)).count == 3 }
                       && prompt.phrase == DinoTimeWords.time(time, language: code)
                       && hint.referenceMinute == expectedReference
                       && hint.spokenHour(for: hour) == ((hour + (minute > 30 ? 1 : 0) + 11) % 12 + 1),
                       "every Arabic clock has distinct hour-first stones and the right hour anchor")
                let combinations = prompt.slots[0].choices.flatMap { hour in
                    prompt.slots[1].choices.map { SpokenTimeAnswer(choiceIDs: [hour.id, $0.id]) }
                }
                expect(combinations.filter(prompt.accepts) == [prompt.correct],
                       "each Arabic stone combination has one intended answer")
            }
        }

        let boundaries: [(Int, Int, String, String, String)] = [
            (0, 0, "٠٠:٠٠", "١٢:٠٠", "ص"), (0, 5, "٠٠:٠٥", "١٢:٠٥", "ص"),
            (12, 0, "١٢:٠٠", "١٢:٠٠", "م"), (12, 5, "١٢:٠٥", "١٢:٠٥", "م"),
            (17, 5, "١٧:٠٥", "٥:٠٥", "م"), (23, 59, "٢٣:٥٩", "١١:٥٩", "م")
        ]
        for (hour, minute, twentyFour, twelve, period) in boundaries {
            let time = ClockTime(hour: hour, minute: minute)
            let ordinary = time.digitalReading(notation: .twelve, languageCode: code)
            expect(time.digitalReading(notation: .twentyFour, languageCode: code).text == twentyFour
                   && ordinary.text == twelve + ordinary.periodSpacing + period && ordinary.period == period,
                   "Arabic digital times maintain hour, minute and day period")
        }
        expect(DinoTimeWords.spokenDuration(1, language: code) == "دقيقة واحدة"
               && DinoTimeWords.spokenDuration(2, language: code) == "دقيقتان"
               && DinoTimeWords.spokenDuration(5, language: code) == "خمس دقائق"
               && DinoTimeWords.spokenDuration(65, language: code) == "ساعة واحدة وخمس دقائق"
               && DinoTimeWords.spokenDuration(71, language: code) == "ساعة واحدة وإحدى عشرة دقيقة"
               && DinoTimeWords.zoneHours(90, language: code) == "١٫٥",
               "Arabic durations distinguish singular, dual, plural and fractional hours")
        expect(DinoTimeWords.time(.init(hour: 0), language: code, dayPart: true).hasSuffix("ليلًا")
               && DinoTimeWords.time(.init(hour: 7), language: code, dayPart: true).hasSuffix("صباحًا")
               && DinoTimeWords.time(.init(hour: 12), language: code, dayPart: true).hasSuffix("بعد الظهر")
               && DinoTimeWords.time(.init(hour: 23), language: code, dayPart: true).hasSuffix("مساءً"),
               "the four day parts use the configured lesson schedule")
        expect(ClockTime(hour: 23, minute: 55).adding(minutes: 10) == .init(hour: 0, minute: 5)
               && ClockTime(hour: 0, minute: 5).adding(minutes: -10) == .init(hour: 23, minute: 55),
               "adding and subtracting across midnight keep the numeric answer")

        for type in DinoPracticeQuestion.allCases {
            for family in DinoPracticeTime.allCases {
                var generator = DinoPracticeGenerator(configuration: .init(time: family, order: .specific(type)), seed: 71, language: code)
                for index in 0..<3 {
                    let question = generator.next(index: index)
                    expect(AnswerValidator.isCorrect(question.expectedAnswer, for: question), "Arabic \(type) accepts its answer for \(family)")
                    if question.kind.usesOptions {
                        expect(question.responses.filter { AnswerValidator.isCorrect($0, for: question) }.count == 1,
                               "Arabic \(type) has only one correct choice")
                    }
                    if question.kind == .timeZone {
                        expect(question.timeZoneJourney?.origin.id == "riyadh", "Arabic journeys start in Riyadh")
                    }
                }
                if type.recipe.kind.isExpanded {
                    let example = DinoDemonstrationExamples.question(kind: type.recipe.kind, minutes: family.minutes,
                        minuteStep: family.minuteStep, index: 0, previousTarget: nil, language: code)
                    expect(AnswerValidator.isCorrect(example.expectedAnswer, for: example), "Arabic examples use their live question rules")
                }
            }
        }

        let utc = TimeZone(secondsFromGMT: 0)!
        let calendar = Calendar(identifier: .gregorian)
        func date(_ month: Int) -> Date {
            calendar.date(from: .init(timeZone: utc, year: 2026, month: month, day: 15, hour: 12))!
        }
        let riyadh = profile.regionalTimeZoneCapitals.first { $0.id == "riyadh" }!
        let cities = DinoTimeZoneJourney.capitals + profile.regionalTimeZoneCapitals
        for (id, january, july) in [("cairo", -60, 0), ("abuDhabi", 60, 60), ("muscat", 60, 60),
                                   ("tehran", 30, 30), ("islamabad", 120, 120), ("ankara", 0, 0)] {
            let destination = cities.first { $0.id == id }!
            expect(DinoTimeZoneJourney(origin: riyadh, destination: destination, date: date(1)).offsetMinutes == january
                   && DinoTimeZoneJourney(origin: riyadh, destination: destination, date: date(7)).offsetMinutes == july,
                   "Riyadh to \(id) has the correct signed offset in both seasons")
        }
        expect(DinoTimeZoneJourney.displayedDate(language: code, date: date(1)) == "١٥ يناير",
               "the atlas displays the civil date in Arabic")
        for month in 1...12 {
            for difficulty in DinoTimeZoneDifficulty.allCases {
                for family in DinoPracticeTime.allCases {
                    let step = family.minuteStep
                    let journey = DinoTimeZoneJourney.generate(language: code, difficulty: difficulty, minuteStep: step,
                                                               date: date(month), using: &rng)
                    expect(journey.origin == riyadh && journey.offsetMinutes != 0 && journey.offsetMinutes.isMultiple(of: step),
                           "all Saudi zone levels have a reachable destination every month")
                }
            }
        }
    }

    static func testAustralianLocalization() {
        let profile = AppLanguage.australianEnglish
        let code = profile.code
        expect(AppLanguage.named("en_AU") == profile && AppLanguage.named("en-Latn-AU") == profile
               && AppLanguage.named("en-NZ") == .english && AppLanguage.named("en-CA") == .canadianEnglish
               && profile.resourceCodes == ["en-AU", "en"] && profile.teaches24HourConversion,
               "only Australian English selects the Australian profile and conversion lesson")
        let australian = DinoSpeechVoice(identifier: "au", name: "Australian", language: "en-AU", quality: 1)
        let british = DinoSpeechVoice(identifier: "gb", name: "British", language: "en-GB", quality: 3)
        expect(DinoSpeechVoicePicker.preferredLanguageIdentifier(for: code) == "en-AU"
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [british, australian]) == australian
               && DinoSpeechVoicePicker.bestVoice(for: code, among: [british]) == british,
               "prefer an Australian voice and fall back to another suitable English voice")

        let examples: [(Int, Int, String, Int, Int)] = [
            (7, 0, "Seven o’clock", 0, 7), (7, 1, "One past seven", 0, 7), (7, 5, "Five past seven", 0, 7),
            (7, 14, "Fourteen past seven", 0, 7), (7, 15, "Quarter past seven", 0, 7),
            (7, 16, "Sixteen past seven", 0, 7), (7, 20, "Twenty past seven", 0, 7), (7, 25, "Twenty-five past seven", 0, 7),
            (7, 29, "Twenty-nine past seven", 0, 7), (7, 30, "Half past seven", 0, 7),
            (7, 31, "Twenty-nine to eight", 60, 8), (7, 35, "Twenty-five to eight", 60, 8),
            (7, 40, "Twenty to eight", 60, 8), (7, 44, "Sixteen to eight", 60, 8), (7, 45, "Quarter to eight", 60, 8),
            (7, 46, "Fourteen to eight", 60, 8), (7, 55, "Five to eight", 60, 8), (7, 59, "One to eight", 60, 8),
            (8, 0, "Eight o’clock", 0, 8)
        ]
        for (hour, minute, phrase, reference, spokenHour) in examples {
            let hint = SpokenClockReadingHint(minute: minute, language: code)
            expect(spokenPhrase(code, hour: hour, minute: minute) == phrase && hint.referenceMinute == reference
                   && hint.spokenHour(for: hour) == spokenHour, "Australian phrase and explanation agree at \(hour):\(minute)")
        }
        var rng = SeededGenerator(seed: 34)
        var baseRng = SeededGenerator(seed: 34)
        for hour in 0..<24 {
            for minute in 0..<60 {
                let time = ClockTime(hour: hour, minute: minute)
                let prompt = profile.spokenTime.prompt(for: time, using: &rng)
                let base = AppLanguage.english.spokenTime.prompt(for: time, using: &baseRng)
                expect(prompt == base && DinoTimeWords.time(time, language: code) == DinoTimeWords.time(time, language: "en"),
                       "Australian English shares the answer tiles and clock wording across all minutes")
            }
        }
        let boundaries: [(Int, Int, String, String)] = [
            (0, 0, "12:00", "am"), (0, 5, "12:05", "am"), (12, 0, "12:00", "pm"),
            (12, 5, "12:05", "pm"), (17, 5, "5:05", "pm"), (23, 59, "11:59", "pm")
        ]
        for (hour, minute, clock, period) in boundaries {
            let time = ClockTime(hour: hour, minute: minute)
            let twelve = time.digitalReading(notation: .twelve, languageCode: code)
            let twentyFour = time.digitalReading(notation: .twentyFour, languageCode: code)
            expect(twelve.period == period && !twelve.periodBeforeClock
                   && ["\u{00a0}", "\u{202f}"].contains(twelve.periodSpacing)
                   && twelve.text == clock + twelve.periodSpacing + period
                   && twentyFour.text == time.digitalText && twentyFour.period == nil,
                   "both Australian digital clock formats distinguish midday and midnight")
        }
        expect(ClockTime(hour: 23, minute: 55).adding(minutes: 10) == .init(hour: 0, minute: 5)
               && ClockTime(hour: 0, minute: 5).adding(minutes: -10) == .init(hour: 23, minute: 55),
               "time arithmetic crosses midnight in both directions")
        for type in DinoPracticeQuestion.allCases {
            for time in DinoPracticeTime.allCases {
                var generator = DinoPracticeGenerator(configuration: .init(time: time, order: .specific(type)), seed: 71, language: code)
                for index in 0..<3 {
                    let question = generator.next(index: index)
                    expect(AnswerValidator.isCorrect(question.expectedAnswer, for: question),
                           "Australian \(type) accepts its expected answer for \(time)")
                    if question.kind.usesOptions {
                        expect(question.responses.filter { AnswerValidator.isCorrect($0, for: question) }.count == 1,
                               "Australian \(type) has exactly one correct choice for \(time)")
                    }
                    if question.kind == .timeZone {
                        expect(question.timeZoneJourney?.origin.id == "canberra", "Australian time-zone exercises start in Canberra")
                    }
                }
            }
        }

        let canberra = DinoTimeZoneJourney.capitals.first { $0.id == "canberra" }!
        let cities = Dictionary(uniqueKeysWithValues: profile.regionalTimeZoneCapitals.map { ($0.id, $0) })
        let utc = TimeZone(secondsFromGMT: 0)!
        let calendar = Calendar(identifier: .gregorian)
        func date(_ month: Int, _ day: Int = 15) -> Date {
            calendar.date(from: .init(timeZone: utc, year: 2026, month: month, day: day, hour: 12))!
        }
        expect(DinoTimeZoneJourney.displayedDate(language: code, date: date(1)) == "15 January", "the date puts the day before the month")
        let seasons = [(date(1), [-60, -30, -90, -180, 0]), (date(7), [0, -30, -30, -120, 60])]
        for (season, offsets) in seasons {
            for (city, offset) in zip(["brisbane", "adelaide", "darwin", "perth", "noumea"], offsets) {
                let journey = DinoTimeZoneJourney(origin: canberra, destination: cities[city]!, date: season)
                let midnight = ClockTime(hour: 0)
                expect(journey.offsetMinutes == offset
                       && journey.steps(from: midnight).last?.time == (offset == 0 ? nil : midnight.adding(minutes: offset)),
                       "Canberra to \(city) agrees with the seasonal offset and the replay across midnight")
            }
            for (step, includesAdelaide) in [(30, true), (60, false)] {
                let destinations = DinoTimeZoneJourney.destinations(from: canberra, difficulty: .regional,
                    minuteStep: step, date: season, regionalCapitals: profile.regionalTimeZoneCapitals,
                    regionalMinimum: profile.regionalTimeZoneMinimum)
                expect(destinations.contains(cities["adelaide"]!) == includesAdelaide,
                       "Adelaide appears if the exercise allows half-hour offsets")
            }
        }
        for (day, nearby) in [(date(4, 4), "brisbane"), (date(4, 5), "noumea"),
                              (date(10, 3), "noumea"), (date(10, 4), "brisbane")] {
            let journey = DinoTimeZoneJourney.generate(language: code, difficulty: .nearby, date: day, using: &rng)
            expect(journey.origin.id == "canberra" && journey.destination.id == nearby,
                   "nearby questions change city on the Canberra daylight-saving transition")
        }
        for month in 1...12 {
            for difficulty in DinoTimeZoneDifficulty.allCases {
                for family in DinoPracticeTime.allCases {
                    let step = family.minuteStep
                    let journey = DinoTimeZoneJourney.generate(language: code, difficulty: difficulty,
                                                               minuteStep: step, date: date(month), using: &rng)
                    expect(journey.origin.id == "canberra" && journey.offsetMinutes != 0 && journey.offsetMinutes.isMultiple(of: step),
                           "every time-zone level has a valid destination from Canberra in month \(month)")
                }
            }
        }
    }

    static func testGermanLocalization() {
        let code = AppLanguage.german.code
        let language = SpokenTimeCatalog.language(code: code)
        expect(AppLanguage.named("de-DE") == .german && AppLanguage.named("de_DE") == .german,
               "German Germany resolves to the shipped bundle and lesson")
        expect(AppLanguage.named("de-AT") == .german && AppLanguage.named("de-CH") == .german,
               "regional German uses the same standard German bundle until individually supported")
        expect(DinoSpeechVoicePicker.preferredLanguageIdentifier(for: code) == "de-DE"
               && !DinoSpeechVoicePicker.matchesLanguageAndScript("nl-NL", "de-DE"), "German requests a German voice")

        let examples: [(Int, String, Int, Int)] = [
            (0, "sieben Uhr", 0, 7), (1, "sieben Uhr eins", 0, 7), (5, "fünf nach sieben", 0, 7),
            (14, "sieben Uhr vierzehn", 0, 7), (15, "Viertel nach sieben", 0, 7),
            (16, "sieben Uhr sechzehn", 0, 7), (20, "zwanzig nach sieben", 0, 7),
            (25, "fünf vor halb acht", 30, 8), (29, "sieben Uhr neunundzwanzig", 0, 7),
            (30, "halb acht", 30, 8), (31, "sieben Uhr einunddreißig", 0, 7),
            (35, "fünf nach halb acht", 30, 8), (40, "zwanzig vor acht", 60, 8),
            (44, "sieben Uhr vierundvierzig", 0, 7), (45, "Viertel vor acht", 60, 8),
            (46, "sieben Uhr sechsundvierzig", 0, 7), (55, "fünf vor acht", 60, 8),
            (59, "sieben Uhr neunundfünfzig", 0, 7)
        ]
        for (minute, phrase, reference, hour) in examples {
            let time = ClockTime(hour: 7, minute: minute)
            let hint = SpokenClockReadingHint(minute: minute, language: code)
            expect(DinoTimeWords.time(time, language: code) == phrase, "07:\(minute) is \(phrase)")
            expect(hint.referenceMinute == reference && hint.spokenHour(for: time.hour) == hour,
                   "07:\(minute) points to the same hour and minute anchor as the phrase")
        }
        expect(DinoTimeWords.time(.init(hour: 8), language: code) == "acht Uhr", "08:00 starts a new hour")
        expect(DinoTimeWords.time(.init(hour: 1), language: code) == "ein Uhr"
               && DinoTimeWords.time(.init(hour: 1, minute: 1), language: code) == "ein Uhr eins"
               && DinoTimeWords.time(.init(hour: 1, minute: 5), language: code) == "fünf nach eins", "ein and eins follow their position")
        for (hour, minute, phrase) in [(0, 0, "null Uhr"), (0, 5, "null Uhr fünf"), (12, 0, "zwölf Uhr"),
                                       (12, 5, "zwölf Uhr fünf"), (17, 5, "siebzehn Uhr fünf"),
                                       (23, 59, "dreiundzwanzig Uhr neunundfünfzig")] {
            expect(DinoTimeWords.digitalTimeInWords(.init(hour: hour, minute: minute), language: code) == phrase,
                   "the 24-hour question speaks the complete hour")
        }
        expect(ClockTime(hour: 23, minute: 55).adding(minutes: 10) == .init(hour: 0, minute: 5)
               && ClockTime(hour: 0, minute: 5).adding(minutes: -10) == .init(hour: 23, minute: 55),
               "German date rollover works in both directions")
        let digital = ClockTime(hour: 17, minute: 5)
        expect(digital.digitalReading(notation: .twentyFour, languageCode: code).text == "17:05", "German 24-hour display")
        let twelve = digital.digitalReading(notation: .twelve, languageCode: code)
        expect(twelve.hour == "5" && twelve.minute == "05" && twelve.period?.isEmpty == false, "explicit 12-hour mode includes its day period")
        expect(DinoTimeWords.spokenDuration(61, language: code) == "eine Stunde und eine Minute"
               && DinoTimeWords.spokenDuration(122, language: code) == "2 Stunden und 2 Minuten", "German time units inflect independently")
        var rng = SeededGenerator(seed: 42)
        for hour in 0..<24 {
            for minute in 0..<60 {
                let clock = ClockTime(hour: hour, minute: minute)
                let prompt = language.prompt(for: clock, using: &rng)
                let question = spokenQuestion(prompt: prompt, time: clock)
                let description = DinoTimeWords.time(clock, language: code)
                expect(prompt.phrase == description.prefix(1).uppercased() + description.dropFirst(),
                       "German tiles and the clock description name the same time")
                expect(AnswerValidator.isCorrect(.spoken(prompt.correct), for: question), "the canonical German phrase scores correctly")
                for (index, slot) in prompt.slots.enumerated() {
                    let correct = prompt.correct.choiceIDs[index]
                    expect(Set(slot.choices.map(\.word)).count == slot.choices.count && slot.choices.contains { $0.id == correct },
                           "German answer tiles are distinct and include the correct word")
                    for wrong in slot.choices where wrong.id != correct {
                        var ids = prompt.correct.choiceIDs
                        ids[index] = wrong.id
                        expect(!AnswerValidator.isCorrect(.spoken(.init(choiceIDs: ids)), for: question), "one wrong tile changes the answer")
                    }
                }
            }
        }

        let catalogURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Localizable.xcstrings")
        let catalog = try! JSONSerialization.jsonObject(with: Data(contentsOf: catalogURL)) as! [String: Any]
        let strings = catalog["strings"] as! [String: [String: Any]]
        func localized(_ key: String) -> String {
            let languages = strings[key]?["localizations"] as? [String: [String: Any]]
            return (languages?["de"]?["stringUnit"] as? [String: String])?["value"] ?? key
        }
        for type in DinoPracticeQuestion.allCases {
            for time in DinoPracticeTime.allCases {
                var generator = DinoPracticeGenerator(configuration: .init(time: time, order: .specific(type)), seed: 71, language: code)
                for index in 0..<3 {
                    let question = generator.next(index: index)
                    let prompt = DinoQuestionPrompt.make(question: question, language: code, instructionKey: question.kind.instructionKey)
                    let text = prompt.spoken(localizing: localized)
                    expect(!text.contains("dino.") && !text.contains("$@") && !text.contains("%@"), "German title resolves for \(type) and \(time)")
                    if let format = prompt.formatKey {
                        expect(DinoQuestionPrompt.interpolated(localized(format), arguments: prompt.arguments) != nil,
                               "the German translation supplies each reordered question argument")
                    }
                    expect(AnswerValidator.isCorrect(question.expectedAnswer, for: question), "the German question accepts its expected result")
                    if question.kind == .timeZone { expect(question.timeZoneJourney?.origin.id == "berlin", "German time zone questions start in Berlin") }
                }
            }
        }
        let berlin = DinoTimeZoneJourney.capitals.first { $0.id == "berlin" }!
        let delhi = DinoTimeZoneJourney.capitals.first { $0.id == "newDelhi" }!
        let utc = TimeZone(secondsFromGMT: 0)!
        for (month, offset) in [(1, 270), (7, 210)] {
            let date = Calendar(identifier: .gregorian).date(from: .init(timeZone: utc, year: 2026, month: month, day: 15))!
            expect(DinoTimeZoneJourney(origin: berlin, destination: delhi, date: date).offsetMinutes == offset,
                   "Berlin to New Delhi preserves the half hour and German summer time")
            for difficulty in [DinoTimeZoneDifficulty.nearby, .regional, .worldwide] {
                for step in [1, 5, 10, 15, 30, 60] {
                    expect(!DinoTimeZoneJourney.destinations(from: berlin, difficulty: difficulty, minuteStep: step, date: date).isEmpty,
                           "Berlin has destinations for \(difficulty), step \(step), and month \(month)")
                }
            }
        }
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
            (14, DinoTimeReading.Region.past, "14 over twaalf"),
            (16, .beforeHalf, "14 voor half een"), (29, .beforeHalf, "1 voor half een"),
            (30, .half, "half een"), (31, .afterHalf, "1 over half een"),
            (44, .afterHalf, "14 over half een"), (46, .to, "14 voor een")
        ] {
            expect(DinoTimeReading.region(minute: minute, language: "nl") == region,
                   "Dutch color boundaries also handle individual minutes")
            expect(DinoTimeWords.time(.init(hour: 12, minute: minute), language: "nl") == phrase,
                   "Dutch individual-minute wording follows the half-hour groups across twelve")
        }
    }

    static func testTimeReadingReview() {
        let player = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
        for language in ["nl", "en"] {
            for minute in [0, 1, 14, 16, 29, 31, 44, 59] {
                for difficulty in [DinoQuestionDifficulty.introduction, .challenge] {
                    var rng = SeededGenerator(seed: UInt64(minute + 1))
                    let question = DinoExpandedQuestions.generate(kind: .readDigital, minutes: Array(0..<60),
                        minuteStep: 1, index: 0, previousTarget: nil, preferredTarget: .init(hour: 12, minute: minute),
                        language: language, difficulty: difficulty, using: &rng)
                    let config = DinoPracticeConfiguration(time: .minutes, order: .specific(.readDigital))
                    func session() -> DinoSession {
                        DinoSession(level: config.level, player: player, practice: config, example: question, language: language)
                    }
                    let correct = session()
                    expect(!correct.showsTimeReadingExplanation, "speech help starts hidden")
                    correct.submit(question.expectedAnswer)
                    expect(!correct.showsTimeReadingExplanation && !correct.showsWorkedExplanation && correct.shouldAutoAdvance,
                           "a first correct reading answer advances without an extra review screen")
                    let wrong = question.options.filter { $0 != question.target }
                    let missed = session()
                    missed.submit(wrong[0])
                    expect(missed.showsTimeReadingExplanation && !missed.showsWorkedExplanation,
                           "a wrong reading answer immediately shows just the speech guide")
                    expect(missed.showsCorrectResponse == (question.options.count == 2),
                           "a two-choice reading miss immediately reveals the green correct answer")
                    expect(missed.attempt.answers == [false] && !missed.shouldAutoAdvance,
                           "a wrong answer retains its original lost point")
                    if wrong.count > 1 {
                        missed.submit(wrong[1])
                        missed.submit(question.expectedAnswer)
                        expect(missed.correctFeedback && missed.shouldAutoAdvance && !missed.showsWorkedExplanation,
                               "a correct reading retry advances without a second explanation phase")
                    }
                }
            }
        }
        for kind in [DinoPracticeQuestion.readDigital, .spokenTime] {
            let fresh = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
            let config = DinoPracticeConfiguration(time: .tenMinutes, order: .specific(kind))
            let live = DinoSession(level: config.level, player: fresh, practice: config)
            expect(live.question.options.count == 2, "a new reading exercise begins with two options")
            live.submit(live.question.responses.first { $0 != live.question.expectedAnswer }!)
            if kind == .spokenTime {
                expect(live.canRetry && live.showsSpokenClockHints && !live.showsCorrectResponse,
                       "both spoken-clock options receive help while the correct choice stays selectable")
                live.submit(live.question.expectedAnswer)
                expect(live.correctFeedback && live.shouldAutoAdvance, "the correct spoken-clock retry advances normally")
            } else {
                expect(live.showsCorrectResponse && !live.canRetry, "two-choice text reading reveals the correct stone immediately")
            }
            live.advance()
            expect(live.question.id == 1 && !live.hasFeedback && !live.showsSpokenClockHints,
                   "one Next action starts the next question and clears its helpers")
        }
    }

    static func testMinuteQuestionRules() {
        for kind in [ClockQuestionKind.setAnalog, .advanceAnalog, .setDigital, .chooseAnalog] {
            for hour in 0..<24 {
                for minute in [0, 1, 29, 30, 58, 59] {
                    let target = ClockTime(hour: hour, minute: minute)
                    let q = ClockQuestion(id: 0, kind: kind, target: target, options: [], activity: nil, companionClocks: [])
                    for offset in -2...2 {
                        let analog = [.setAnalog, .advanceAnalog].contains(kind)
                        expect(AnswerValidator.isCorrect(target.adding(minutes: offset), for: q)
                               == (analog ? abs(offset) <= 1 : offset == 0),
                               "only analog setting accepts one minute either side, including hour and day boundaries")
                    }
                    expect(!AnswerValidator.isCorrect(target.adding(minutes: 60), for: q),
                           "analog tolerance never accepts a wrong hour")
                }
            }
        }
        for category in DinoQuestionCategory.all {
            var generator = DinoPracticeGenerator(configuration: .init(time: category.time, order: .specific(category.type)), seed: 761)
            for index in 0..<12 {
                let q = generator.next(index: index, difficultyForKind: { _ in category.difficulty })
                if [.addTime, .subtractTime, .advanceAnalog, .timeSequence, .minutesBetween].contains(q.kind) {
                    expect(q.durationMinutes > 1, "minute calculations always use multiple minutes at every difficulty")
                }
                if let schedule = q.daySchedule {
                    expect([schedule.firstMinutes, schedule.breakMinutes, schedule.secondMinutes].allSatisfy { $0 > 1 },
                           "all train and transfer durations use multiple minutes")
                }
                let span = [.chooseAnalog, .chooseDigital, .readDigital, .spokenTime, .trueFalse, .match].contains(q.kind) ? 720 : 1440
                for (position, first) in q.options.enumerated() {
                    for second in q.options.dropFirst(position + 1) {
                        let delta = abs(first.minutesOfDay % span - second.minutesOfDay % span)
                        expect(min(delta, span - delta) > 1, "every pair of time choices is more than one minute apart")
                    }
                }
                let totals = q.responses.compactMap { answer -> Int? in
                    if case .duration(let value) = answer { return value }; return nil
                }
                for (position, first) in totals.enumerated() {
                    expect(first > 1, "minute totals never offer a single minute")
                    expect(totals.dropFirst(position + 1).allSatisfy { abs(first - $0) > 1 },
                           "every pair of duration choices is more than one minute apart")
                }
                if q.kind.usesOptions {
                    let count = q.kind == .trueFalse ? 2 : q.kind == .dayPart ? 4 : category.difficulty.optionCount
                    expect(q.responses.count == count && Set(q.responses).count == count,
                           "spacing preserves the full answer grid at every difficulty")
                }
                expect(AnswerValidator.isCorrect(q.expectedAnswer, for: q), "minute rules retain the correct answer")
            }
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
                            expect((2 * time.minuteStep...240).contains(q.durationMinutes) && q.durationMinutes.isMultiple(of: time.minuteStep),
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
                        expect(!q.options.contains(q.relatedTimes.last!), "the last sequence term is never an answer option")
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
                if kind == .advanceAnalog && time.minuteStep < 30 {
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
        expect(openingAssets == DinoOpeningJump.assets + ["dino-idle"], "all eight original opening poses play once in order")
        expect(DinoOpeningJump.poseStarts.map { DinoOpeningJump.sample(elapsed: $0).pose.asset } == DinoOpeningJump.assets,
               "native contents keyframes use the same pose boundaries as the flight sampler")
        expect(DinoWelcomeJump.poseStarts.map { DinoWelcomeJump.pose(elapsed: $0).asset } == DinoWelcomeJump.assets,
               "welcome starts in the exact idle image and uses its separate tracked preparation")
        expect(DinoWelcomeJump.assets.first == "dino-idle" && !DinoWelcomeJump.assets.contains("dino-opening-jump-01"),
               "the recolored near-idle illustration cannot flash between the logo and crouch")
        let welcomeFlight = DinoWelcomeFlight(source: CGPoint(x: 201, y: 400), sourceSide: 373,
                                             destination: CGRect(x: 132, y: 550, width: 148, height: 148))
        func tracked(_ point: CGPoint, at time: Double) -> CGPoint {
            let state = DinoWelcomeJump.tracking(elapsed: time, flight: welcomeFlight)
            let source = DinoWelcomeJump.sourceHead(for: state.pose.asset)
            let relative = CGPoint(x: point.x - source.center.x, y: point.y - source.center.y)
                .applying(DinoWelcomeJump.sourceCorrection(for: state.pose.asset)).applying(state.transform)
            return CGPoint(x: state.position.x + relative.x, y: state.position.y + relative.y)
        }
        var previousWelcomeHead = DinoWelcomeJump.tracking(elapsed: 0, flight: welcomeFlight).position
        for step in 0...Int(ceil(DinoWelcomeJump.duration * 120)) {
            let time = Double(step) / 120
            let state = DinoWelcomeJump.tracking(elapsed: time, flight: welcomeFlight)
            let source = DinoWelcomeJump.sourceHead(for: state.pose.asset)
            for (painted, target) in [(source.leftEye, state.head.leftEye), (source.rightEye, state.head.rightEye), (source.nose, state.head.nose)] {
                let actual = tracked(painted, at: time)
                expect(hypot(actual.x - target.x, actual.y - target.y) < 1e-10,
                       "both painted eyes and nostrils follow the same tracked face through drawing changes")
            }
            let transform = state.transform
            expect(transform.a.isFinite && transform.b.isFinite && transform.c.isFinite && transform.d.isFinite
                   && transform.a * transform.d - transform.b * transform.c > 0.5,
                   "head registration remains finite and cannot mirror or collapse the face")
            if time <= DinoWelcomeJump.takeoff {
                expect(hypot(state.position.x - previousWelcomeHead.x, state.position.y - previousWelcomeHead.y) < 0.025,
                       "the head bends and rises continuously instead of jumping two hundred painted pixels in one frame")
                if time <= DinoWelcomeJump.crouchBottom {
                    expect(state.position.y >= previousWelcomeHead.y, "the tracked bend moves down without a reversal")
                } else {
                    expect(state.position.y <= previousWelcomeHead.y + 0.0005, "the tracked push-off moves back up without a second dip")
                }
            }
            if time >= DinoWelcomeJump.takeoff && time < DinoWelcomeJump.landing {
                expect(state.pose.asset == "dino-opening-jump-03", "the tracked push-off leads into the same fixed flight pose")
            }
            previousWelcomeHead = state.position
        }
        for boundary in DinoWelcomeJump.poseStarts[1...2] {
            let before = DinoWelcomeJump.tracking(elapsed: boundary - 1e-7, flight: welcomeFlight)
            let after = DinoWelcomeJump.tracking(elapsed: boundary + 1e-7, flight: welcomeFlight)
            expect(hypot(before.position.x - after.position.x, before.position.y - after.position.y) < 1e-6,
                   "changing to the crouch or flight drawing cannot teleport the tracked head")
        }
        let welcomeLowHead = DinoWelcomeJump.tracking(elapsed: DinoWelcomeJump.crouchBottom, flight: welcomeFlight).position
        let originalLowHead = DinoWelcomeJump.sourceHead(for: "dino-opening-jump-02").center
        expect(abs(welcomeLowHead.y - originalLowHead.y) < 4.0 / 1254,
               "the tracked bend retains the original deep crouch instead of stopping above the board")
        expect(DinoWelcomeJump.takeoff >= 0.55 && DinoWelcomeJump.takeoff <= 0.70,
               "the deeper bend and push-off retain readable movement time without adding more drawings")
        let welcomeFlights = [welcomeFlight,
            DinoWelcomeFlight(source: CGPoint(x: 437, y: 160), sourceSide: 230,
                              destination: CGRect(x: 250, y: 220, width: 90, height: 90)),
            DinoWelcomeFlight(source: CGPoint(x: 410, y: 520), sourceSide: 592,
                              destination: CGRect(x: 450, y: 650, width: 240, height: 240)),
            DinoWelcomeFlight(source: CGPoint(x: 590, y: 380), sourceSide: 592,
                              destination: CGRect(x: 350, y: 480, width: 250, height: 250))]
        for flight in welcomeFlights {
            func worldHead(_ time: Double) -> DinoWelcomeJump.Head {
                DinoWelcomeJump.tracking(elapsed: time, flight: flight).head
                    .applying(flight.worldTransform(elapsed: time))
            }
            for key in [DinoWelcomeJump.crouchBottom, DinoWelcomeJump.takeoff, DinoWelcomeJump.flightHandoff] {
                let epsilon = 0.000001
                let before = worldHead(key - epsilon), on = worldHead(key), after = worldHead(key + epsilon)
                for (a, b, c) in [(before.leftEye, on.leftEye, after.leftEye),
                                  (before.rightEye, on.rightEye, after.rightEye), (before.nose, on.nose, after.nose)] {
                    let velocityChange = hypot((c.x - b.x) - (b.x - a.x), (c.y - b.y) - (b.y - a.y)) / epsilon
                    expect(velocityChange < 0.1,
                           "the visible face keeps its velocity through the bottom, takeoff and flight handoff on phones and tablets")
                }
            }
            var previous = worldHead(DinoWelcomeJump.crouchBottom).center
            var descending = false
            for step in 1...120 {
                let time = DinoWelcomeJump.crouchBottom
                    + Double(step) / 120 * (DinoWelcomeJump.flightHandoff - DinoWelcomeJump.crouchBottom)
                let head = worldHead(time).center
                if head.y > previous.y { descending = true }
                else {
                    expect(!descending,
                           "the visible head rises once without a second dip; low landscape arcs may pass their apex during handoff")
                }
                if flight.sourceSide == welcomeFlight.sourceSide {
                    expect(head.y < previous.y,
                           "the portrait push-off keeps rising through takeoff and handoff without a pause")
                }
                previous = head
            }
            let released = worldHead(DinoWelcomeJump.flightHandoff)
            let painted = flight.paintedHead(elapsed: DinoWelcomeJump.flightHandoff)
            expect(hypot(released.center.x - painted.center.x, released.center.y - painted.center.y) < 1e-9,
                   "the velocity handoff reaches the unmodified flight artwork exactly")
        }
        for fps in [30.0, 60.0] {
            for phase in [0.0, 0.25, 0.5, 0.75] {
                var seen = [String]()
                for step in 0...Int((DinoWelcomeJump.duration + 0.1) * fps) {
                    let asset = DinoWelcomeJump.pose(elapsed: (Double(step) + phase) / fps).asset
                    if seen.last != asset { seen.append(asset) }
                }
                expect(seen == DinoWelcomeJump.assets + ["dino-idle"],
                       "native tracked preparation, flight and recovery play in order at both refresh rates")
            }
        }
        for time in [DinoWelcomeJump.landing, DinoWelcomeJump.landing + 0.13, DinoWelcomeJump.duration] {
            let pose = DinoWelcomeJump.pose(elapsed: time)
            expect(abs(opaqueFootline(pose.asset) + pose.offsetY - idleFootline) < 1.0 / 1254,
                   "head tracking retains the original painted contact footline and final idle handoff")
        }
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
        let crouchDuration = DinoOpeningJump.takeoff - DinoOpeningJump.poseStarts[1]
        expect((0.04...0.06).contains(crouchDuration),
               "the original deep crouch stays readable without the old 105 ms pause before takeoff")
        for elapsed in DinoOpeningJump.poseStarts.filter({ $0 < DinoOpeningJump.takeoff || $0 >= DinoOpeningJump.landing }) {
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
            expect(hold >= 0.04 - 0.000001 && hold <= 0.18,
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
        // Landscape must retain the visible HUD origin for all four outcomes.
        // Sample the actual journey used by the UI at both common refresh rates.
        for size in [CGSize(width: 1024, height: 724), CGSize(width: 1194, height: 790),
                     CGSize(width: 1376, height: 984), CGSize(width: 750, height: 354)] {
            let origin = CGRect(x: 24, y: size.height * 0.32, width: 92, height: 92)
            let side = min(400, size.height * 0.48)
            let target = CGRect(x: size.width * 0.28 - side / 2, y: size.height * 0.50 - side / 2,
                                width: side, height: side)
            for clip in DinoResultJourney.clips {
                let takeoff = DinoAnimation.travelDelay(clip)
                let landing = DinoAnimation.travelDuration(clip)
                let heightScale = DinoResultJourney.heightScale(clip: clip, origin: origin, target: target)
                expect((0...1).contains(heightScale), "the landscape arc only reduces lift, without changing timing")
                for step in 0...600 {
                    let time = takeoff + (landing - takeoff) * Double(step) / 600
                    let frame = DinoResultJourney.frame(clip: clip, elapsed: time, origin: origin, target: target)
                    let sample = DinoAnimation.sample(clip, elapsed: time)
                    let top = frame.minY + min(0, sample.pose.offsetY) * frame.width
                        + sample.height * frame.width * heightScale
                    expect(top >= 15.9, "even the full lifted drawing buffer clears the landscape top edge")
                }
                for time in [0, takeoff / 2, takeoff] {
                    expect(DinoResultJourney.frame(clip: clip, elapsed: time, origin: origin, target: target) == origin,
                           "all outcomes prepare in the visible portrait, without an offscreen landscape reset")
                }
                for time in [landing, DinoAnimation.duration(clip), DinoAnimation.duration(clip) + 1] {
                    expect(DinoResultJourney.frame(clip: clip, elapsed: time, origin: origin, target: target) == target,
                           "contact, recovery and final pose stay registered to the podium")
                }
                for fps in [30.0, 60.0] {
                    var previous = origin
                    for step in 0...Int(ceil(DinoAnimation.duration(clip) * fps)) {
                        let time = Double(step) / fps
                        let frame = DinoResultJourney.frame(clip: clip, elapsed: time, origin: origin, target: target)
                        expect(CGRect(origin: .zero, size: size).contains(frame),
                               "landscape shows the entire journey buffer, including the fall")
                        expect(hypot(frame.midX - previous.midX, frame.midY - previous.midY) < 55
                               && abs(frame.width - previous.width) < 65,
                               "every outcome travels continuously without skipping to the destination")
                        previous = frame
                    }
                }
                // A destination remeasurement must not replace the origin.
                let time = (takeoff + landing) / 2
                let before = DinoResultJourney.frame(clip: clip, elapsed: time, origin: origin, target: target)
                let updated = DinoResultJourney.frame(clip: clip, elapsed: time, origin: origin,
                    target: target.offsetBy(dx: 1, dy: 1))
                expect(hypot(updated.midX - before.midX, updated.midY - before.midY) < 1.5,
                       "a small layout update cannot truncate the running animation")
            }
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
                       "one-star playback shows all eight original opening poses once and settles into idle at 30 and 60 fps")
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
                        if question.kind == .timeSequence {
                            expect(!question.options.contains(question.relatedTimes.last!),
                                   "every difficulty excludes the last sequence term from its answer choices")
                        }
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
            let matchingPlayer = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
            let matchingConfig = DinoPracticeConfiguration(time: family, order: .specific(.match))
            var matchingFeedback = 0
            let matching = DinoSession(level: matchingConfig.level, player: matchingPlayer, practice: matchingConfig,
                                       answerFeedback: { _ in matchingFeedback += 1 })
            for _ in 0..<2 {
                let questionID = matching.question.id
                let answered = matching.practiceAnswered
                for index in matching.question.relatedTimes.indices {
                    expect(matching.answerCheck?.enabled == true && matching.answerCheck?.requirement == .connectClocks,
                           "empty and partial matching boards keep a tappable reminder")
                    for _ in 0..<3 { matching.submit(matching.answerCheck!.answer); matching.advance() }
                    expect(!matching.hasFeedback && matching.question.id == questionID && matching.practiceAnswered == answered
                           && matchingFeedback == answered,
                           "incomplete connections never score, advance or play wrong-answer feedback")
                    matching.pairSelections[index] = matching.question.relatedTimes[index]
                }
                expect(matching.answerCheck?.requirement == nil, "connecting every clock clears the reminder")
                matching.pairSelections.removeValue(forKey: 0)
                expect(matching.answerCheck?.requirement == .connectClocks, "disconnecting a clock restores the requirement")
                matching.pairSelections[0] = matching.question.relatedTimes[0]
                matching.submit(matching.answerCheck!.answer)
                expect(matching.correctFeedback && matching.practiceAnswered == answered + 1 && matchingFeedback == answered + 1,
                       "a completed matching board scores exactly once")
                matching.advance()
                expect(matching.pairSelections.isEmpty && matching.answerCheck?.requirement == .connectClocks,
                       "the next board starts with a fresh connection requirement")
            }
            let sortingPlayer = DinoPlayer(store: DinoProgressStore(defaults: InMemoryKeyValueStore()))
            let sortingConfig = DinoPracticeConfiguration(time: family, order: .specific(.sortTimes))
            var sortingFeedback = 0
            let sorting = DinoSession(level: sortingConfig.level, player: sortingPlayer, practice: sortingConfig,
                                      answerFeedback: { _ in sortingFeedback += 1 })
            for _ in 0..<2 {
                let questionID = sorting.question.id
                let answered = sorting.practiceAnswered
                guard case .ordering(let order) = sorting.question.expectedAnswer else { fatalError("Expected clock order") }
                for time in order {
                    expect(sorting.answerCheck?.enabled == true && sorting.answerCheck?.requirement == .selectClocks,
                           "empty and partial sorting selections keep a tappable reminder")
                    for _ in 0..<3 { sorting.submit(sorting.answerCheck!.answer); sorting.advance() }
                    expect(!sorting.hasFeedback && sorting.question.id == questionID && sorting.practiceAnswered == answered
                           && sortingFeedback == answered,
                           "incomplete sorting selections never score, advance or play wrong-answer feedback")
                    sorting.selectedOrder.append(time)
                }
                expect(sorting.answerCheck?.requirement == nil, "selecting every clock clears the reminder")
                sorting.selectedOrder.removeLast()
                expect(sorting.answerCheck?.requirement == .selectClocks, "deselecting a clock restores the requirement")
                sorting.selectedOrder.append(order.last!)
                sorting.submit(sorting.answerCheck!.answer)
                expect(sorting.correctFeedback && sorting.practiceAnswered == answered + 1 && sortingFeedback == answered + 1,
                       "a complete clock order scores exactly once")
                sorting.advance()
                expect(sorting.selectedOrder.isEmpty && sorting.answerCheck?.requirement == .selectClocks,
                       "each sorting question requires a fresh selection")
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
            let explainsMiss = [DinoPracticeQuestion.dayPart, .timeSequence, .addTime, .subtractTime,
                                .flightArrival, .timeZone, .daySchedule].contains(type)
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
            expect(!session.shouldAutoAdvance && !session.showsWorkedExplanation,
                   "unanswered questions wait for the player")
            let firstCorrect = DinoSession(level: config.level, player: player, practice: config, example: question)
            firstCorrect.submit(question.expectedAnswer)
            expect(firstCorrect.shouldAutoAdvance && !firstCorrect.showsWorkedExplanation,
                   "a first correct answer advances without another explanation phase")
            session.showAnswer()
            expect(!session.answerRevealed && !session.canRetry, "unanswered questions cannot reveal their answer")
            let wrong = question.responses.filter { $0 != question.expectedAnswer }
            now += 3
            session.submit(wrong[0])
            let allowsRetry = question.responses.count > 2 || type == .spokenTime
            expect(session.canRetry == allowsRetry && session.showsCorrectResponse != allowsRetry, "only multiple choice with more than two options allows retries")
            expect(session.missedFirstAnswer && session.showsWorkedExplanation == (explainsMiss && !allowsRetry) && !session.shouldAutoAdvance,
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
                let addsExplanationAfterRetry = explainsMiss && type != .timeSequence
                expect(session.correctFeedback && !session.canRetry && session.showsCorrectResponse &&
                       session.showsWorkedExplanation == addsExplanationAfterRetry && session.shouldAutoAdvance == !addsExplanationAfterRetry,
                       "a correct retry advances unless \(type) adds a worked explanation")
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
            expect(revealed.showsWorkedExplanation == explainsMiss && !revealed.shouldAutoAdvance,
                   "Show answer waits for Next, with a worked explanation only when \(type) provides one")

            if allowsRetry {
                let eliminated = DinoSession(level: config.level, player: player, practice: config, example: question)
                for choice in wrong { eliminated.submit(choice) }
                if type == .spokenTime {
                    expect(eliminated.canRetry && !eliminated.answerRevealed && eliminated.showsSpokenClockHints,
                           "after all wrong clock guesses the remaining clock can still be chosen with its helper")
                    eliminated.submit(question.expectedAnswer)
                    expect(eliminated.correctFeedback && eliminated.shouldAutoAdvance && eliminated.attempt.answers == [false],
                           "the correct clock advances while preserving the first lost point")
                    continue
                }
                expect(eliminated.answerRevealed && eliminated.showsCorrectResponse && eliminated.showsWorkedExplanation == explainsMiss
                       && !eliminated.canRetry && !eliminated.correctFeedback && !eliminated.shouldAutoAdvance && eliminated.attempt.answers == [false],
                       "ruling out every wrong choice reveals the last answer without another tap")
                expect(question.responses.allSatisfy { !eliminated.responseIsEnabled($0) }, "the remaining choice closes with the others")
                eliminated.submit(question.expectedAnswer)
                expect(!eliminated.correctFeedback && eliminated.attempt.answers == [false], "the revealed last choice cannot be scored afterwards")
            }
        }

        let sequenceConfig = DinoPracticeConfiguration(time: .minutes, order: .specific(.timeSequence))
        for difficulty in [DinoQuestionDifficulty.introduction, .familiar] {
            var generator = DinoPracticeGenerator(configuration: sequenceConfig, seed: 42)
            let question = generator.next(index: 0, difficultyForKind: { _ in difficulty })
            let sequence = DinoSession(level: sequenceConfig.level, player: player, practice: sequenceConfig, example: question)
            expect(question.responses.count == (difficulty == .introduction ? 2 : 4), "sequence regression covers two and four choices")
            sequence.submit(question.responses.first { $0 != question.expectedAnswer }!)
            expect(sequence.missedFirstAnswer && !sequence.shouldAutoAdvance, "the first sequence miss shows the helper and waits")
            if question.responses.count == 2 {
                expect(sequence.showsWorkedExplanation && !sequence.canRetry, "a two-choice miss keeps its explanation until Next")
                sequence.submit(question.expectedAnswer)
                expect(!sequence.correctFeedback && !sequence.shouldAutoAdvance && sequence.showsWorkedExplanation,
                       "a closed two-choice question still waits for Next")
            } else {
                expect(sequence.canRetry && !sequence.showsWorkedExplanation, "four-choice hints appear during the open retry")
                sequence.submit(question.expectedAnswer)
                expect(sequence.correctFeedback && sequence.shouldAutoAdvance && !sequence.showsWorkedExplanation && sequence.missedFirstAnswer,
                       "the correct sequence retry advances while keeping the existing helper until the transition")
            }
            expect(sequence.attempt.answers == [false] && sequence.practiceAnswered == 1 && sequence.practiceCorrect == 0,
                   "sequence retries preserve the first lost point and count the question once")
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

    static func testJungleMotion() {
        let clips: [DinoAnimation.Clip] = [.idle, .thumbsUp, .wrongAnswer, .stumble, .openingJump, .backflip, .pirouette, .worldJump]
        for clip in clips {
            let duration = DinoAnimation.duration(clip)
            let settled = DinoJungleAnimation.sample(clip, elapsed: duration)
            expect(settled.pose.asset == "jungle-idle" && settled.previousPose == nil,
                   "completed jungle reactions settle on one opaque idle painting")
            for step in 0...Int(ceil((duration + 0.1) * 120)) {
                let elapsed = Double(step) / 120
                let sample = DinoJungleAnimation.sample(clip, elapsed: elapsed)
                expect(sample.angle.isFinite && sample.height.isFinite && (0...1).contains(sample.poseBlend),
                       "jungle motion stays finite with bounded continuous opacity")
                expect(DinoJungleArtwork.assets.contains(sample.pose.asset), "every displayed jungle pose is prepared before playback")
                if let previous = sample.previousPose {
                    expect(DinoJungleArtwork.assets.contains(previous.asset), "dissolve predecessors are also prepared")
                    let a = DinoJungleAnimation.anchor(previous.asset)
                    let b = DinoJungleAnimation.anchor(sample.pose.asset)
                    expect(hypot(a.x + previous.offsetX - b.x - sample.pose.offsetX,
                                 a.y + previous.offsetY - b.y - sample.pose.offsetY) < 0.000001,
                           "adjacent jungle paintings share one face anchor throughout every transition")
                }
                let shared = DinoAnimation.sample(clip, elapsed: elapsed)
                expect(sample.angle == shared.angle && sample.height == shared.height,
                       "jungle clips retain the main character's flight path and reward choreography")
            }
        }
        for (clip, boundary) in [(DinoAnimation.Clip.backflip, 0.20), (.worldJump, 1.10), (.wrongAnswer, DinoAnimation.answerGestureStart)] {
            let before = DinoJungleAnimation.sample(clip, elapsed: boundary - 0.00001)
            let after = DinoJungleAnimation.sample(clip, elapsed: boundary + 0.00001)
            expect(before.previousPose != nil && after.previousPose != nil && abs(before.poseBlend - after.poseBlend) < 0.05,
                   "pose changes dissolve continuously instead of switching paintings in one frame")
        }
        let turnKeys = DinoJungleAnimation.keys(for: .pirouette).filter { $0.asset.hasPrefix("jungle-turn-") }
        expect(turnKeys.count == 8 && Set(turnKeys.map(\.asset)).count == 8,
               "each jungle turn view appears once, without repeated compressed poses")
        for pair in zip(turnKeys, turnKeys.dropFirst()) {
            expect(pair.1.time - pair.0.time > 0.06, "each turn view has time to read clearly")
        }
        let beforeLanding = DinoJungleAnimation.sample(.openingJump,
            elapsed: DinoAnimation.leadIn(.openingJump) + DinoOpeningJump.landing - 0.05)
        expect(beforeLanding.pose.asset == "jungle-takeoff", "the reaching feet stay airborne until actual contact")
        let flight = DinoWelcomeFlight(source: CGPoint(x: 190, y: 300), sourceSide: 360,
            destination: CGRect(x: 90, y: 460, width: 170, height: 170), character: .jungle)
        for boundary in [DinoWelcomeJump.crouchBottom, DinoWelcomeJump.flightHandoff, DinoWelcomeJump.landing,
                         DinoWelcomeJump.landing + 0.10, DinoWelcomeJump.duration] {
            let before = DinoWelcomeJump.tracking(elapsed: boundary - 0.00001, flight: flight).head.center
            let after = DinoWelcomeJump.tracking(elapsed: boundary + 0.00001, flight: flight).head.center
            expect(hypot(after.x - before.x, after.y - before.y) < 0.001,
                   "the jungle welcome's tracked face never teleports at takeoff, landing or recovery")
        }
        expect(DinoWelcomeJump.assets(for: .jungle) == ["dino-idle"],
               "the jungle welcome prepares one consistent detailed drawing")
        for geometry in [flight,
            DinoWelcomeFlight(source: CGPoint(x: 410,y: 520), sourceSide: 592,
                destination: CGRect(x: 240,y: 740,width: 190,height: 190),character: .jungle),
            DinoWelcomeFlight(source: CGPoint(x: 590,y: 200), sourceSide: 330,
                destination: CGRect(x: 490,y: 370,width: 170,height: 170),character: .jungle)] {
            for step in 0...Int(ceil(DinoWelcomeJump.duration * 120)) {
                let elapsed = Double(step) / 120
                let tracked = DinoWelcomeJump.tracking(elapsed: elapsed, flight: geometry)
                expect(tracked.pose.asset == "dino-idle" && DinoWelcomeJump.pose(elapsed: elapsed, character: .jungle).asset == "dino-idle",
                       "the jungle face and lighting never change drawings during the bend, launch or landing")
                let matrix = tracked.transform.concatenating(geometry.transform(elapsed: elapsed))
                let xScale = hypot(matrix.a,matrix.b), yScale = hypot(matrix.c,matrix.d)
                expect(xScale > 0 && abs(xScale-yScale) < 1e-8 && abs(matrix.a*matrix.c+matrix.b*matrix.d) < 1e-8,
                       "the welcome preserves facial proportions without stretching or skewing its detailed pixels")
            }
        }
        let highURL = URL(fileURLWithPath: "Assets.xcassets/\(DinoJungleArtwork.openingAsset).imageset/\(DinoJungleArtwork.openingAsset).png")
        let high = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(highURL as CFURL,nil)!,0,nil)!
        expect(high.width >= 1254 && high.height >= 1254 && high.alphaInfo != .none,
               "the large jungle welcome uses a detailed transparent source instead of enlarging a sprite-sheet cell")
        let url = URL(fileURLWithPath: "Assets.xcassets/jungle-idle.imageset/jungle-idle.png")
        let original = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
        let mirrored = DinoSpriteColorRenderer.facingRight(original)!
        let restored = DinoSpriteColorRenderer.facingRight(mirrored)!
        expect(original.width == mirrored.width && original.height == mirrored.height
               && restored.width == original.width, "reflection preserves the sprite's registration canvas")
    }

    static func testCharacterUnlocks() {
        var profile = PlayerProfile()
        expect(profile.activeCharacter == .main && profile.collectionCharacters == Array(DinoIdentity.allCases.dropFirst()),
               "new players have ten boss slots and the main dinosaur stays outside the collection")
        expect(DinoIdentity.desert.unlockLevel == 20 && DinoIdentity.valley.unlockLevel == 70,
               "collection tiles follow the playable world's order rather than illustration export IDs")
        expect(!profile.selectCharacter(.jungle), "the jungle character cannot be selected before winning its world")
        profile.recordCompletedAttempt(levelID: 10, correct: 9)
        expect(!profile.isCharacterUnlocked(.jungle), "earning boss stars without the route is not a world victory")
        profile.recordCompletedAttempt(levelID: 10, correct: 10)
        expect(profile.selectCharacter(.jungle) && profile.activeCharacter == .jungle, "a perfect shortcut unlocks the first character")
        expect(profile.collectionCharacters[0] == .main && !profile.collectionCharacters.contains(.jungle),
               "the outgoing main dinosaur takes exactly the selected boss's slot")
        expect(profile.collectionCharacters.count == 10 && Set(profile.collectionCharacters).count == 10,
               "swaps preserve ten unique collection tiles")
        let saved = try! JSONDecoder().decode(PlayerProfile.self, from: JSONEncoder().encode(profile))
        expect(saved.activeCharacter == .jungle && saved.collectionCharacters == profile.collectionCharacters,
               "active character and exact slot arrangement survive save decoding")
        expect(profile.selectCharacter(.main) && profile.collectionCharacters[0] == .jungle,
               "choosing the main dinosaur returns the jungle boss to that same tile")
        profile.recordCompletedAttempt(levelID: 20, correct: 10)
        expect(profile.selectCharacter(.desert), "the desert guardian unlocks at chapter two, independently of theme seven")
        expect(!profile.selectCharacter(.volcano), "unimplemented characters remain locked")
        var scrambled = PlayerProfile()
        for level in [10, 20, 30, 40] { scrambled.recordCompletedAttempt(levelID: level, correct: 10) }
        scrambled.dinoAppearance = .standard(for: .desert)
        scrambled.characterSlots = [.volcano, .main, .jungle, .village, .cave, .city, .valley, .machine, .pirates, .castle]
        expect(scrambled.activeCharacter == .desert
               && Array(scrambled.menuCharacters.prefix(4)) == [.main, .jungle, .volcano, .village],
               "any slot swap still shows start, 10, 30 and 40 while the desert dinosaur is selected")
        var normal = PlayerProfile()
        for level in 1...9 { normal.recordCompletedAttempt(levelID: level, correct: 3) }
        normal.recordCompletedAttempt(levelID: 10, correct: 6)
        expect(normal.isCharacterUnlocked(.jungle), "a normal world victory unlocks the same character")
        let store = DinoProgressStore(defaults: InMemoryKeyValueStore())
        var first = PlayerProfile()
        first.dinoAppearance = DinoAppearance(body: 0xF48EB6)
        store.save(first)
        let player = DinoPlayer(store: store)
        var rng = SeededGenerator(seed: 42)
        let questions = DinoQuestionGenerator.generate(level: DinoLevelCatalog.level(10)!, using: &rng)
        var attempt = LevelAttempt(levelID: 10, questions: questions)
        while !attempt.isComplete {
            _ = attempt.submit(attempt.current.answer ?? .time(attempt.current.target))
            attempt.advance()
        }
        expect(player.finish(attempt)?.victory == .perfect && player.profile.pendingCharacterUnlock == .jungle,
               "a first boss victory stages the transformation without changing the result character")
        expect(player.profile.activeCharacter == .main, "the original dinosaur performs the start of the world salto")
        player.completeCharacterUnlock()
        expect(player.profile.activeCharacter == .jungle && player.profile.pendingCharacterUnlock == nil,
               "landing commits the unlocked character once")
        expect(DinoPlayer(store: store).profile.activeCharacter == .jungle, "the new character survives a cold start")
        player.selectCharacter(.main)
        _ = player.finish(attempt)
        expect(player.profile.activeCharacter == .main && player.profile.pendingCharacterUnlock == nil,
               "replaying level ten does not overwrite a later character choice")
        player.selectCharacter(.jungle)
        player.resetProgress()
        expect(player.profile.activeCharacter == .main && !player.profile.isCharacterUnlocked(.jungle)
               && player.profile.dinoAppearance?.body == 0xF48EB6,
               "progress reset relocks the collection and preserves the main dinosaur's colors")
        for pose in Set(DinoAnimation.spriteAssets + DinoAnimation.worldJumpAssets) {
            let name = DinoJungleArtwork.asset(for: pose)
            expect(FileManager.default.fileExists(atPath: "Assets.xcassets/\(name).imageset/\(name).png"),
                   "every shared animation pose has jungle artwork: \(pose)")
        }
        let url = URL(fileURLWithPath: "Assets.xcassets/jungle-idle.imageset/jungle-idle.png")
        let image = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
        let defaultArt = DinoSpriteColorRenderer.recoloredJungle(image, appearance: DinoAppearance(character: .jungle))!
        let pinkArt = DinoSpriteColorRenderer.recoloredJungle(image, appearance: DinoAppearance(body: 0xF48EB6, character: .jungle))!
        func pixels(_ image: CGImage) -> [UInt8] {
            var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
            bytes.withUnsafeMutableBytes { buffer in
                let context = CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                    bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)!
                context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            }
            return bytes
        }
        let originalPixels = pixels(image), defaultPixels = pixels(defaultArt), pinkPixels = pixels(pinkArt)
        expect(defaultPixels == originalPixels, "default jungle colors preserve the original generated artwork")
        expect(pinkPixels != originalPixels, "body customization recolors the jungle character")
        expect(stride(from: 3, to: originalPixels.count, by: 4).allSatisfy { originalPixels[$0] == pinkPixels[$0] },
               "jungle color choices retain every silhouette alpha value")
        let creamOnly = pixels(DinoSpriteColorRenderer.recoloredJungle(image,
            appearance: DinoAppearance(belly: 0xC5AFE8, character: .jungle))!)
        let crownOnly = pixels(DinoSpriteColorRenderer.recoloredJungle(image,
            appearance: DinoAppearance(bandana: 0x6424C8, character: .jungle))!)
        let leavesOnly = pixels(DinoSpriteColorRenderer.recoloredJungle(image,
            appearance: DinoAppearance(spikes: 0x7622DC, character: .jungle))!)
        func pixel(_ bytes: [UInt8], _ x: Int, _ y: Int) -> [UInt8] {
            let index = (y * image.width + x) * 4
            return Array(bytes[index..<index+3])
        }
        for (x, y) in [(200,235), (210,246), (230,420), (230,431), (230,440), (283,470)] {
            expect(pixel(creamOnly,x,y) != pixel(originalPixels,x,y), "cream highlights and shadows, including toes, use the belly choice")
            expect(pixel(crownOnly,x,y) == pixel(originalPixels,x,y), "cream skin never acquires a stripe from the crown choice")
        }
        for (x,y) in [(253,34), (259,59)] {
            expect(pixel(leavesOnly,x,y) != pixel(originalPixels,x,y), "the lime center feather belongs to the leaf color")
            expect(pixel(pinkPixels,x,y) == pixel(originalPixels,x,y), "the center feather never acquires body-color patches")
        }
        for (x, y) in [(355, 336), (353, 405), (293, 177)] {
            expect(pixel(pinkPixels, x, y) != pixel(originalPixels, x, y)
                   && pixel(leavesOnly, x, y) == pixel(originalPixels, x, y)
                   && pixel(creamOnly, x, y) == pixel(originalPixels, x, y),
                   "jungle cheek, arm and thigh spots follow the skin color")
        }
        expect(pixel(leavesOnly, 367, 350) != pixel(originalPixels, 367, 350)
               && pixel(pinkPixels, 367, 350) == pixel(originalPixels, 367, 350),
               "the leaf beside the spotted arm follows the leaf color")
        for asset in DinoJungleArtwork.assets {
            let url = URL(fileURLWithPath: "Assets.xcassets/\(asset).imageset/\(asset).png")
            let source = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL,nil)!,0,nil)!
            let original = pixels(source)
            let recolored = pixels(DinoSpriteColorRenderer.recoloredJungle(source,
                appearance: DinoAppearance(bandana: 0xDF2731, spikes: 0x7622DC, body: 0x45A7E6, belly: 0xC5AFE8, character: .jungle), asset: asset)!)
            expect(stride(from: 3, to: original.count, by: 4).allSatisfy { original[$0] == recolored[$0] },
                   "every jungle pose retains its original silhouette after recoloring")
        }
        for (asset, points) in [("jungle-clap-contact", [(210,264),(220,276)]),
                                ("jungle-clap-open", [(167,260),(293,260)]),
                                ("jungle-stumble", [(215,297)])] {
            let url = URL(fileURLWithPath: "Assets.xcassets/\(asset).imageset/\(asset).png")
            let source = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL,nil)!,0,nil)!
            let original = pixels(source)
            let crown = pixels(DinoSpriteColorRenderer.recoloredJungle(source,
                appearance: DinoAppearance(bandana: 0xDF2731, character: .jungle), asset: asset)!)
            let skin = pixels(DinoSpriteColorRenderer.recoloredJungle(source,
                appearance: DinoAppearance(belly: 0xC5AFE8, character: .jungle), asset: asset)!)
            for (x,y) in points {
                expect(pixel(crown,x,y) == pixel(original,x,y) && pixel(skin,x,y) != pixel(original,x,y),
                       "fingertips covering gold accessories keep the skin color")
            }
        }
        for (index, contact) in DinoAnimation.correctAnswerClapContacts.enumerated() {
            let sample = DinoAnimation.sample(.thumbsUp, elapsed: contact + 0.01)
            expect(DinoJungleArtwork.asset(for: sample.pose.asset) == (index == 0 ? "jungle-clap-contact" : "jungle-clap-contact-2"),
                   "the jungle palms meet exactly on each shared clap beat")
        }
        for (x,y) in [(181,115),(201,102),(237,62),(216,259),(221,277),(180,297),(220,372)] {
            expect(pixel(creamOnly,x,y) == pixel(originalPixels,x,y)
                   && pixel(leavesOnly,x,y) == pixel(originalPixels,x,y)
                   && pixel(crownOnly,x,y) != pixel(originalPixels,x,y),
                   "crown, suspension and bezel remain one metal material across glints and shadows")
        }
        for (x,y) in [(210,310),(240,320),(220,345)] {
            expect(pixel(creamOnly,x,y) == pixel(originalPixels,x,y)
                   && pixel(crownOnly,x,y) == pixel(originalPixels,x,y),
                   "the clock face and hands never receive colored speckles")
        }
        for asset in ["jungle-idle","jungle-wrong","jungle-clap-open","jungle-clap-open-2","jungle-clap-contact","jungle-clap-contact-2"] {
            let url = URL(fileURLWithPath:"Assets.xcassets/\(asset).imageset/\(asset).png")
            let source = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL,nil)!,0,nil)!
            let head = pixels(DinoSpriteColorRenderer.jungleHeadOverflow(source,asset:asset,mirrored:false)!)
            for y in 270..<source.height {
                for x in 0..<source.width {
                    expect(head[(y*source.width+x)*4+3] == 0,
                           "no torso, clock or lower leaf may enter the portrait foreground in any answer pose")
                }
            }
            expect(head[(250*source.width+350)*4+3] == 0,
                   "the unwanted lower back leaf is absent from the foreground")
            expect(head[(34*source.width+253)*4+3] > 0,
                   "the head mask preserves the full crown above the circle")
            if asset == "jungle-clap-contact" || asset == "jungle-clap-contact-2" {
                expect(head[(264*source.width+210)*4+3] == 0,
                       "clapping fingertips are excluded even when raised against the chin")
            } else if asset == "jungle-clap-open" || asset == "jungle-clap-open-2" {
                expect(head[(250*source.width+165)*4+3] == 0,
                       "the raised open palm cannot cross the rim via the head foreground")
            }
        }
        let heroName = DinoJungleArtwork.openingAsset
        let heroURL = URL(fileURLWithPath: "Assets.xcassets/\(heroName).imageset/\(heroName).png")
        let hero = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(heroURL as CFURL,nil)!,0,nil)!
        let heroOriginal = pixels(hero)
        let heroCrown = pixels(DinoSpriteColorRenderer.recoloredJungle(hero,
            appearance: DinoAppearance(bandana: 0xDF2731,character: .jungle),asset: heroName)!)
        let heroSkin = pixels(DinoSpriteColorRenderer.recoloredJungle(hero,
            appearance: DinoAppearance(belly: 0xC5AFE8,character: .jungle),asset: heroName)!)
        func heroPixel(_ data: [UInt8],_ x: Int,_ y: Int) -> [UInt8] {
            let i = (y * hero.width + x) * 4
            return Array(data[i..<i+3])
        }
        for (x,y) in [(520,575),(560,600),(560,990),(555,1035),(380,1130),(829,1160)] {
            expect(heroPixel(heroCrown,x,y) == heroPixel(heroOriginal,x,y)
                   && heroPixel(heroSkin,x,y) != heroPixel(heroOriginal,x,y),
                   "high-resolution cream skin and dial never acquire gold-colored speckles")
        }
        expect(heroPixel(heroCrown,510,755) == heroPixel(heroOriginal,510,755)
               && heroPixel(heroSkin,510,755) == heroPixel(heroOriginal,510,755),
               "the clock dial keeps neutral original paint for every color selection")
        for (x,y) in [(480,380),(640,385)] {
            expect(heroPixel(heroCrown,x,y) == heroPixel(heroOriginal,x,y)
                   && heroPixel(heroSkin,x,y) == heroPixel(heroOriginal,x,y),
                   "the detailed welcome keeps its original brown irises")
        }
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
        let jungle = Set(preloaded.map { DinoJungleArtwork.asset(for: $0) })
        let playableBosses = DinoIdentity.allCases.filter(\.usesBossArtwork)
        let bossPoses = Set(playableBosses.flatMap(\.artworkAssets))
        let openings = Set(playableBosses.map(\.openingAsset))
        let expected = sprites.union(bosses).union(jungle).union(bossPoses).union(openings).union(["reward-star"])
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
            let side = asset == "dino-idle" || asset.hasPrefix("dino-opening-jump-") || openings.contains(asset) ? 1254
                : bosses.contains(asset) ? 640 : bossPoses.contains(asset) ? 512 : asset == "reward-star" ? 384 : 768
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
        func renderedArguments(_ prompt: DinoQuestionPrompt, _ language: String) -> [DinoQuestionPrompt.Argument] {
            prompt.segments { localized($0, language) }.compactMap {
                guard case .argument(let argument) = $0 else { return nil }
                return argument
            }
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
        expect(sentence(englishMatch, "en") == "Which clock shows three o’clock?", "question 1 names the clock time")
        expect(englishMatch.arguments.allSatisfy { $0.emphasis == .plain }, "clock times use the title's base color")
        expect(sentence(prompt(matching, "nl"), "nl") == "Welke klok geeft drie uur aan?", "Dutch question 1 names the time")
        let two = question(kind: .chooseAnalog, target: ClockTime(hour: 3), options: Array(four.prefix(2)))
        expect(sentence(prompt(two, "en"), "en") == "Which clock shows three o’clock?", "two choices use the same concise question")
        let single = question(kind: .chooseAnalog, target: ClockTime(hour: 3))
        expect(sentence(prompt(single, "nl"), "nl") == "Welke klok geeft drie uur aan?", "an example without choices does not invent a count")

        let spoken = question(kind: .spokenTime, target: ClockTime(hour: 3), options: four)
        expect(sentence(prompt(spoken, "en"), "en") == "Which of the clocks shows:\nthree o’clock", "a spoken time appears on its own line")
        let claim = question(kind: .trueFalse, target: ClockTime(hour: 4), statement: ClockTime(hour: 3))
        expect(sentence(prompt(claim, "nl"), "nl") == "Klopt de tijd met de klok?\ndrie uur", "Dutch question 3 puts the claimed time below the question")
        expect(sentence(prompt(claim, "en"), "en") == "Does the time match the clock?\nthree o’clock", "English question 3 puts the claimed time below the question")
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
        expect(sentence(addedTitle, "nl") == "Het is drie uur. Hoe laat is het over 1 uur en 30 minuten?",
               "adding time repeats the start and the step")
        expect(addedTitle.arguments.map(\.emphasis) == [.plain, .forward, .plain], "only over is green; the time and duration stay plain")
        expect(!sentence(addedTitle, "nl").contains("vier"), "the later time is not spoken")

        let earlier = question(kind: .subtractTime, target: ClockTime(hour: 2), related: [ClockTime(hour: 4)], duration: 120)
        let earlierTitle = prompt(earlier, "en")
        expect(sentence(earlierTitle, "en") == "It is four o’clock. What time was it 2 hours ago?", "going back names the step")
        expect(earlierTitle.arguments.map(\.emphasis) == [.plain, .plain, .backward], "only earlier is red; the time and duration stay plain")
        expect(!sentence(earlierTitle, "en").contains("two"), "the earlier result is not spoken")
        let twoMinutesAgo = question(kind: .subtractTime, target: ClockTime(hour: 4),
                                     related: [ClockTime(hour: 4, minute: 2)], duration: 2)
        expect(sentence(prompt(twoMinutesAgo, "nl"), "nl") == "Het is 2 over vier. Hoe laat was het 2 minuten geleden?",
               "question 15 places geleden after the duration")
        let twoHoursAhead = question(kind: .addTime, target: ClockTime(hour: 6),
                                    related: [ClockTime(hour: 4)], duration: 120)
        expect(sentence(prompt(twoHoursAhead, "nl"), "nl") == "Het is vier uur. Hoe laat is het over 2 uur?",
               "question 14 places over before the duration")
        for language in ["nl", "en"] {
            for minute in 0..<60 {
                let description = DinoTimeWords.time(ClockTime(hour: 6, minute: minute), language: language)
                expect(!description.contains("minu"), "clock descriptions omit minute units at every position")
            }
            expect(DinoTimeWords.minutes(10, language: language).contains("minu"), "elapsed minutes retain their unit")
        }

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
        expect(renderedArguments(prompt(washingtonQuestion, "nl"), "nl").last?.text == "eerder",
               "Dutch zones describe an earlier local time rather than a slow clock")
        expect(renderedArguments(prompt(parisQuestion, "nl"), "nl").last?.text == "later",
               "Dutch zones describe a later local time rather than a fast clock")
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
                        expect(DinoQuestionPrompt.interpolated(format, arguments: title.arguments) != nil,
                               "\(kind) supplies every argument required by its \(language) translation")
                        expect(!text.isEmpty && !text.contains("%@") && !text.contains("dino."), "every question has a complete localized title")
                        expect(!text.contains(DinoTimeWords.dayPartSuffix(time, language: language)), "titles omit redundant day-part suffixes")
                        for argument in renderedArguments(title, language) where argument.emphasis != .plain {
                            let allowed = language == "nl" ? ["vooruit", "over", "geleden", "later", "eerder", "voor", "achter"]
                                : ["forward", "later", "ago", "ahead", "behind"]
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
                ? "Welke klok geeft twaalf uur aan?" : "Which clock shows twelve o’clock?"),
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

extension DinoCoreTests {
    static func testDesertCharacter() {
        expect(DinoWorldCatalog.world(2)?.themeID == 7 && DinoWorldCatalog.world(7)?.themeID == 2, "Sandtail follows the swapped live theme catalog")
        expect(DinoIdentity.desert.rawValue == 2 && DinoIdentity.desert.bossAsset == "boss-desert" && DinoIdentity.desert.unlockLevel == 20, "Sandtail keeps its stable save identity and chapter slot")
        var p=PlayerProfile()
        p.recordCompletedAttempt(levelID:10,correct:10)
        p.recordCompletedAttempt(levelID:20,correct:9)
        expect(!p.isCharacterUnlocked(.desert), "desert boss stars alone retain existing completion rules")
        for level in 11...19 {p.recordCompletedAttempt(levelID:level,correct:3)}
        expect(p.isCharacterUnlocked(.desert), "ordinary desert victory plus route unlocks Sandtail")
        expect(p.selectCharacter(.desert), "an unlocked desert guardian is selectable")
        expect(p.dinoAppearance == .standard(for:.desert), "first default selection uses the actual orange sand and cream palette")
        expect(p.collectionCharacters[1] == .main && p.mapResident(in:2) == .main, "outgoing main Dino occupies exactly desert slot two")
        p.dinoAppearance?.body = 0x1263EA
        expect(p.selectCharacter(.main) && p.collectionCharacters[1] == .desert, "selecting the outgoing resident returns Sandtail to the same slot")
        expect(p.mapResident(in:2) == .desert && DinoAppearance.standard(for:.desert).body == 0xE7B56D, "a returned Sandtail uses its own default colors independently of active blue")
        let saved=try! JSONDecoder().decode(PlayerProfile.self,from:JSONEncoder().encode(p))
        expect(saved == p && saved.collectionCharacters == p.collectionCharacters, "all desert colors and exact slot arrangement survive serialization")
        p.resetProgress()
        expect(!p.isCharacterUnlocked(.desert) && p.activeCharacter == .main && p.characterSlots == nil && p.pendingCharacterUnlock == nil, "reset relocks Sandtail and clears pending swaps")
        let store=DinoProgressStore(defaults:InMemoryKeyValueStore())
        var first=PlayerProfile();first.recordCompletedAttempt(levelID:10,correct:10);first.dinoAppearance = .standard(for:.jungle);first.characterSlots = [.main] + Array(DinoIdentity.allCases.dropFirst(2));store.save(first)
        let player=DinoPlayer(store:store)
        var rng=SeededGenerator(seed:42)
        let level=DinoLevelCatalog.level(20)!
        var attempt=LevelAttempt(levelID:20,questions:DinoQuestionGenerator.generate(level:level,using:&rng))
        while !attempt.isComplete {_ = attempt.submit(attempt.current.answer ?? .time(attempt.current.target));attempt.advance()}
        expect(player.finish(attempt)?.victory == .perfect && player.profile.pendingCharacterUnlock == .desert && player.profile.activeCharacter == .jungle, "level twenty stages a pending desert transformation without changing the result actor")
        let restarted=DinoPlayer(store:store)
        expect(restarted.profile.pendingCharacterUnlock == .desert, "pending desert unlock survives closing during the result/transition")
        restarted.completeCharacterUnlock()
        expect(restarted.profile.activeCharacter == .desert && restarted.profile.pendingCharacterUnlock == nil && restarted.profile.collectionCharacters[1] == .jungle, "resumed landing swaps the jungle actor into desert slot")
        restarted.completeCharacterUnlock()
        expect(DinoPlayer(store:store).profile.activeCharacter == .desert, "unlock completion is idempotent and persists")
        restarted.selectCharacter(.main);_ = restarted.finish(attempt)
        expect(restarted.profile.activeCharacter == .main && restarted.profile.pendingCharacterUnlock == nil, "repeated desert victories preserve manual choices")
        expect(DinoWorldTransition(after:10) == nil, "last-world handling never invents level 101")
        // The recovery entry point deliberately does not require a next chapter.
        var terminal=restarted.profile;terminal.pendingCharacterUnlock = .desert;store.save(terminal)
        let noTransition=DinoPlayer(store:store);noTransition.completeCharacterUnlock()
        expect(noTransition.profile.activeCharacter == .desert, "pending recovery works without any transition object or next level")
        for clip: DinoAnimation.Clip in [.idle,.thumbsUp,.wrongAnswer,.stumble,.openingJump,.backflip,.pirouette,.worldJump] {
            for tick in 0...360 {
                let t=Double(tick)/120
                let sample=DinoBossAnimation.sample(clip,character:.desert,elapsed:t)
                expect(DinoDesertArtwork.assets.contains(sample.pose.asset), "every actually displayed desert pose is included in preparation")
                expect(sample.previousPose == nil && sample.poseBlend == 1, "desert playback never freezes between translucent bodies")
                expect(sample.height.isFinite && sample.angle.isFinite && sample.pose.offsetX.isFinite, "desert result motion remains finite")
            }
            let end=DinoBossAnimation.sample(clip,character:.desert,elapsed:DinoAnimation.duration(clip)+1)
            expect(end.pose.asset == "desert-idle" && end.previousPose == nil, "every desert animation ends on a single opaque canonical idle")
        }
        for contact in DinoAnimation.correctAnswerClapContacts {
            expect(DinoBossAnimation.sample(.thumbsUp,character:.desert,elapsed:contact).pose.asset.contains("contact"), "both clap sounds/effects meet visible desert palms")
        }
        for step in 0...100 {
            let visible=DinoBossAnimation.unlockOpacity(progress:Double(step)/100,character:.desert)
            expect(visible.source + visible.unlocked == 1 && (visible.source == 0 || visible.unlocked == 0),
                   "the desert reveal always displays one opaque actor rather than two ghosted identities")
        }
        let flight=DinoWelcomeFlight(source:CGPoint(x:195,y:400),sourceSide:420,destination:CGRect(x:80,y:600,width:150,height:150),character:.desert)
        for t in [DinoWelcomeJump.crouchBottom,DinoWelcomeJump.takeoff,DinoWelcomeJump.flightHandoff,DinoWelcomeJump.landing] {
            let a=DinoWelcomeJump.tracking(elapsed:t-0.00001,flight:flight).head
            let b=DinoWelcomeJump.tracking(elapsed:t+0.00001,flight:flight).head
            expect(hypot(a.center.x-b.center.x,a.center.y-b.center.y)<0.2, "desert opening eyes remain continuous at bend takeoff flight handoff and landing")
        }
        expect(DinoWelcomeJump.assets(for:.desert) == ["dino-idle"], "large desert launch keeps one sharp drawing throughout")
        let blueJungle=DinoAppearance(body:0x1263EA,character:.jungle)
        let blueDesert=blueJungle.selecting(.desert),nativeDesert=DinoAppearance.standard(for:.desert)
        expect(blueDesert.body == 0x1263EA && blueDesert.bandana == nativeDesert.bandana && blueDesert.spikes == nativeDesert.spikes && blueDesert.belly == nativeDesert.belly,
               "only chosen material colors carry over; untouched channels use the new character's native palette")
        expect(blueDesert.selecting(.jungle) == blueJungle, "partial custom colors survive a round trip without importing another character's defaults")
        expect(DinoIdentity.jungle.standingFootline == 484.0/512 && DinoIdentity.desert.standingFootline == 1211.0/1254,
               "a swapped jungle resident uses its measured soles rather than desert canvas coordinates")
        func pixels(_ image:CGImage)->[UInt8] {
            var result=[UInt8](repeating:0,count:image.width*image.height*4)
            result.withUnsafeMutableBytes {b in
                let c=CGContext(data:b.baseAddress,width:image.width,height:image.height,bitsPerComponent:8,bytesPerRow:image.width*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)!
                c.draw(image,in:CGRect(x:0,y:0,width:image.width,height:image.height))
            };return result
        }
        // The boss can be attempted early. Finishing the route afterwards is
        // also a real world completion, with the same pending/recovery contract.
        var early=PlayerProfile();early.recordCompletedAttempt(levelID:10,correct:10)
        early.recordCompletedAttempt(levelID:20,correct:6)
        for id in 11...18 {early.recordCompletedAttempt(levelID:id,correct:3)}
        store.save(early)
        let routeFinisher=DinoPlayer(store:store),last=DinoLevelCatalog.level(19)!
        var finalRoute=LevelAttempt(levelID:19,questions:DinoQuestionGenerator.generate(level:last,using:&rng))
        while !finalRoute.isComplete {_ = finalRoute.submit(finalRoute.current.answer ?? .time(finalRoute.current.target));finalRoute.advance()}
        _ = routeFinisher.finish(finalRoute)
        expect(routeFinisher.profile.worldComplete(2) && routeFinisher.profile.pendingCharacterUnlock == .desert,
               "an early boss pass followed by the last route lesson stages the desert unlock too")
        for (i,axis) in DinoDesertArtwork.turnAxes.enumerated() {
            let key = DinoBossAnimation.keys(for:.pirouette,character:.desert).first { $0.asset == String(format:"desert-turn-%02d",i+1) }!
            let sample=DinoBossAnimation.sample(.pirouette,character:.desert,elapsed:key.time+0.001)
            expect(abs(1-axis/443.5+sample.pose.offsetX-(1-229/443.5))<0.00001,
                   "each prepared pirouette view rotates around the measured hip axis after one mirror")
        }
        let custom=DinoAppearance(bandana:0xB329D4,spikes:0x21B966,body:0x2196EB,belly:0xFF80B5,character:.desert)
        for asset in DinoDesertArtwork.assets.sorted() + [DinoDesertArtwork.openingAsset] {
            let url=URL(fileURLWithPath:"Assets.xcassets/\(asset).imageset/\(asset).png")
            let image=CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL,nil)!,0,nil)!
            let original=pixels(image), unchanged=pixels(DinoSpriteColorRenderer.recoloredDesert(image,appearance:.standard(for:.desert),asset:asset)!), recolored=pixels(DinoSpriteColorRenderer.recoloredDesert(image,appearance:custom,asset:asset)!)
            expect(original == unchanged, "original desert palette is byte-for-byte unchanged: \(asset)")
            expect(original != recolored, "each used desert pose supports personalization: \(asset)")
            let labels=DinoSpriteColorRenderer.desertLabels(image,asset:asset)
            let seamProbes: [String:[(Int,Int,UInt8)]] = [
                "desert-push-up": [(175,300,4),(118,329,4),(150,196,0)],
                "desert-fallen": [(205,350,4),(145,387,4),(174,246,0),(150,460,1)],
                "desert-stumble": [(247,267,4),(219,293,3),(243,167,0)]
            ]
            for (x,y,label) in seamProbes[asset] ?? [] {
                expect(labels[y*image.width+x] == label,
                       "moving desert cheek shadows, knitted fringe and protected eyebrows retain their measured material: \(asset) at \(x),\(y)")
            }
            if asset == "desert-idle" {
                let rig=DinoSpriteColorRenderer.DesertRig(asset:asset)
                for (x,y,label) in [(120.0,80.0,UInt8(2)),(135,100,3),(230,130,3),(170,225,1),(170,365,4),(262,280,0)] {
                    let point=rig.point(x,y)
                    expect(labels[Int(point.y*Double(image.height))*image.width+Int(point.x*Double(image.width))] == label,
                           "horn roots forehead skin spots cloth gloss belly shade and dial keep their own material")
                }
            }
            if asset == "desert-idle" || asset == DinoDesertArtwork.openingAsset {
                for (x, y, label) in [(205, 100, UInt8(3)), (252, 100, 2), (394, 346, 2), (441, 319, 3), (375, 359, 5)] {
                    let index = (y * image.height / 512) * image.width + x * image.width / 512
                    expect(labels[index] == label, "desert forehead, rocks, tail and leather follow their own materials at either resolution")
                }
            }
            if asset == "desert-idle" || asset.contains("clap") || asset == "desert-wrong" || asset == "desert-crouch" || asset == "desert-landing" || asset.contains("turn-") {
                var bottom=0
                for y in 0..<image.height {for x in 0..<image.width where original[(y*image.width+x)*4+3]>240 {bottom=max(bottom,y)}}
                expect(abs(Double(bottom)/Double(image.height)-1211.0/1254)<0.006,
                       "each planted pose retains the registered sole line rather than auto-cropping per cell")
            }
            var alphaEqual=true,protectedEqual=true
            for n in labels.indices {
                if original[n*4+3] != recolored[n*4+3] {alphaEqual=false}
                if labels[n] == 0 && original[n*4..<n*4+4] != recolored[n*4..<n*4+4] {protectedEqual=false}
            }
            expect(alphaEqual && protectedEqual, "recolor preserves all alpha and protected eye/mouth/dial bytes: \(asset)")
            let mirrored=pixels(DinoSpriteColorRenderer.facingRight(image)!)
            for (x,y) in [(0,0),(image.width/3,image.height/4),(image.width/2,image.height/2)] {
                let a=(y*image.width+x)*4,b=(y*image.width+image.width-1-x)*4
                expect(original[a..<a+4] == mirrored[b..<b+4], "single mirror maps consistent pixel centers: \(asset)")
            }
            if asset == "desert-idle" || asset.contains("clap") || asset == "desert-wrong" {
                let head=pixels(DinoSpriteColorRenderer.desertHeadOverflow(image,asset:asset,mirrored:false)!)
                let rig=DinoSpriteColorRenderer.DesertRig(asset:asset)
                var noEscape=true
                for y in 0..<image.height {for x in 0..<image.width where head[(y*image.width+x)*4+3]>0 {
                    let point=CGPoint(x:(Double(x)+0.5)/Double(image.width),y:(Double(y)+0.5)/Double(image.height))
                    if point.y>0.55 || rig.hands.contains(where:{rig.ellipse($0).contains(point)}) {noEscape=false}
                }}
                expect(noEscape,"isolated desert head excludes all moving hands shoulders clock and lower ornaments: \(asset)")
            }
        }
    }
}

extension DinoCoreTests {
    static func testVolcanoCharacter() {
        expect(DinoWorldCatalog.world(3)?.themeID == 3 && DinoIdentity.volcano.rawValue == 3 && DinoIdentity.volcano.bossAsset == "boss-volcano" && DinoIdentity.volcano.unlockLevel == 30, "Magma is chapter/theme/save 3, level 30, not an artwork-array guess")
        var p=PlayerProfile()
        p.recordCompletedAttempt(levelID:10,correct:10)
        p.recordCompletedAttempt(levelID:20,correct:10)
        p.recordCompletedAttempt(levelID:30,correct:9)
        expect(!p.isCharacterUnlocked(.volcano), "volcano boss stars alone retain existing completion rules")
        for level in 21...29 {p.recordCompletedAttempt(levelID:level,correct:3)}
        expect(p.isCharacterUnlocked(.volcano), "ordinary volcano victory plus route unlocks Magma")
        expect(p.selectCharacter(.volcano), "an unlocked volcano guardian is selectable")
        expect(p.dinoAppearance == .standard(for:.volcano), "first default selection uses the actual orange, red and cream palette")
        expect(p.collectionCharacters[2] == .main && p.mapResident(in:3) == .main, "outgoing main Dino occupies exactly volcano slot three")
        p.dinoAppearance?.body = 0x1263EA
        expect(p.selectCharacter(.main) && p.collectionCharacters[2] == .volcano, "selecting the outgoing resident returns Magma to the same slot")
        expect(p.mapResident(in:3) == .volcano && DinoAppearance.standard(for:.volcano).body == 0xFF783E, "a returned Magma uses its own default colors independently of active blue")
        let saved=try! JSONDecoder().decode(PlayerProfile.self,from:JSONEncoder().encode(p))
        expect(saved == p && saved.collectionCharacters == p.collectionCharacters, "all volcano colors and exact slot arrangement survive serialization")
        p.resetProgress()
        expect(!p.isCharacterUnlocked(.volcano) && p.activeCharacter == .main && p.characterSlots == nil && p.pendingCharacterUnlock == nil, "reset relocks Magma and clears pending swaps")
        let store=DinoProgressStore(defaults:InMemoryKeyValueStore())
        var first=PlayerProfile();first.recordCompletedAttempt(levelID:10,correct:10);first.recordCompletedAttempt(levelID:20,correct:10);first.dinoAppearance = .standard(for:.jungle);first.characterSlots = [.main] + Array(DinoIdentity.allCases.dropFirst(2));store.save(first)
        let player=DinoPlayer(store:store)
        var rng=SeededGenerator(seed:42)
        let level=DinoLevelCatalog.level(30)!
        var attempt=LevelAttempt(levelID:30,questions:DinoQuestionGenerator.generate(level:level,using:&rng))
        while !attempt.isComplete {_ = attempt.submit(attempt.current.answer ?? .time(attempt.current.target));attempt.advance()}
        expect(player.finish(attempt)?.victory == .perfect && player.profile.pendingCharacterUnlock == .volcano && player.profile.activeCharacter == .jungle, "level thirty stages a pending volcano transformation without changing the result actor")
        let restarted=DinoPlayer(store:store)
        expect(restarted.profile.pendingCharacterUnlock == .volcano, "pending volcano unlock survives closing during the result/transition")
        restarted.completeCharacterUnlock()
        expect(restarted.profile.activeCharacter == .volcano && restarted.profile.pendingCharacterUnlock == nil && restarted.profile.collectionCharacters[2] == .jungle, "resumed landing swaps the jungle actor into volcano slot")
        restarted.completeCharacterUnlock()
        expect(DinoPlayer(store:store).profile.activeCharacter == .volcano, "unlock completion is idempotent and persists")
        restarted.selectCharacter(.main);_ = restarted.finish(attempt)
        expect(restarted.profile.activeCharacter == .main && restarted.profile.pendingCharacterUnlock == nil, "repeated volcano victories preserve manual choices")
        expect(DinoWorldTransition(after:10) == nil, "last-world handling never invents level 101")
        // The recovery entry point deliberately does not require a next chapter.
        var terminal=restarted.profile;terminal.pendingCharacterUnlock = .volcano;store.save(terminal)
        let noTransition=DinoPlayer(store:store);noTransition.completeCharacterUnlock()
        expect(noTransition.profile.activeCharacter == .volcano, "pending recovery works without any transition object or next level")

        var early=PlayerProfile()
        early.recordCompletedAttempt(levelID:10,correct:10);early.recordCompletedAttempt(levelID:20,correct:10)
        early.recordCompletedAttempt(levelID:30,correct:9)
        for id in 21...28 {early.recordCompletedAttempt(levelID:id,correct:3)}
        let routeStore=DinoProgressStore(defaults:InMemoryKeyValueStore());routeStore.save(early)
        let routePlayer=DinoPlayer(store:routeStore),routeLevel=DinoLevelCatalog.level(29)!
        var lastLesson=LevelAttempt(levelID:29,questions:DinoQuestionGenerator.generate(level:routeLevel,using:&rng))
        while !lastLesson.isComplete {_ = lastLesson.submit(lastLesson.current.answer ?? .time(lastLesson.current.target));lastLesson.advance()}
        let routeResult=routePlayer.finish(lastLesson)!
        expect(routeResult.hasPendingCharacterUnlock(in:routePlayer.profile),"finishing world three on level 29 routes into its character arrival rather than replaying the cleared boss")
        expect(routePlayer.profile.worldComplete(3) && routePlayer.profile.pendingCharacterUnlock == .volcano,"Magma also unlocks when the last route lesson follows an earlier boss pass")
        let restoredColors=DinoAppearance(bandana:0xA528DB,spikes:0x19B76B,body:0x218BEA,belly:0xFF85B9,character:.volcano).selecting(.main).selecting(.volcano)
        expect(restoredColors.body == 0x218BEA,"explicit player colors survive changing identities")
        testVolcanoMotion()
        let custom=DinoAppearance(bandana:0xA528DB,spikes:0x19B76B,body:0x218BEA,belly:0xFF85B9,character:.volcano)
        func pixels(_ im:CGImage)->[UInt8] {var b=[UInt8](repeating:0,count:im.width*im.height*4);b.withUnsafeMutableBytes {p in let c=CGContext(data:p.baseAddress,width:im.width,height:im.height,bitsPerComponent:8,bytesPerRow:im.width*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGBitmapInfo.byteOrder32Big.rawValue|CGImageAlphaInfo.premultipliedLast.rawValue)!;c.draw(im,in:CGRect(x:0,y:0,width:im.width,height:im.height))};return b}
        for asset in DinoVolcanoArtwork.assets.sorted()+[DinoVolcanoArtwork.openingAsset] {
            let url=URL(fileURLWithPath:"Assets.xcassets/\(asset).imageset/\(asset).png")
            let image=CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL,nil)!,0,nil)!
            if asset==DinoVolcanoArtwork.openingAsset {expect(image.width>=1254 && image.height>=1254,"Magma welcome uses real restored detail")}
            let original=pixels(image),native=pixels(DinoSpriteColorRenderer.recoloredVolcano(image,appearance:.standard(for:.volcano),asset:asset)!),colored=pixels(DinoSpriteColorRenderer.recoloredVolcano(image,appearance:custom,asset:asset)!)
            expect(original==native && original != colored,"native palette is untouched and every pose supports customization")
            let labels=DinoSpriteColorRenderer.volcanoLabels(image,asset:asset)
            if asset == "volcano-idle" {
                for (x,y,label) in [(175,130,UInt8(4)),(200,247,4),(294,167,3),(224,325,0),(283,288,0)] {expect(labels[y*image.width+x] == label,"Magma horns, chin shadows, skin spots and separate dials keep their measured materials")}
            }
            if asset == "volcano-idle" || asset == DinoVolcanoArtwork.openingAsset {
                for (x, y, label) in [(148, 174, UInt8(2)), (305, 176, 3), (229, 359, 4), (153, 357, 4)] {
                    let index = (y * image.height / 512) * image.width + x * image.width / 512
                    expect(labels[index] == label, "Magma keeps side frill, skin, belly shadow and claw separate at either resolution")
                }
            }
            if asset == "volcano-turn-02" {
                for (x,y,label) in [(186,283,UInt8(0)),(145,318,0),(209,292,3)] {expect(labels[y*image.width+x] == label,"Magma profile clocks use their own measured positions and preserve the arm in front")}
            }
            let shadowedGlass:[String:(Int,Int)] = ["volcano-push-up":(185,419),"volcano-rise-low":(203,400),"volcano-stumble":(290,342),"volcano-fallen":(176,456)]
            if let (x,y)=shadowedGlass[asset] {expect(labels[y*image.width+x] == 0,"shadowed clock glass remains neutral rather than inheriting a selected material color")}
            if asset == "volcano-rise-low" {expect(labels[274*image.width+402] == 3,"the low recovery tail tip remains skin, outside its own frill mask")}
            if asset == "volcano-turn-03" {for (x,y,label) in [(159,163,UInt8(0)),(174,181,3),(160,230,4)] {expect(labels[y*image.width+x] == label,"rear-left view protects its visible eye, skin spots and cream chin")}}
            if asset == "volcano-turn-05" {for (x,y,label) in [(382,160,UInt8(0)),(385,193,3),(383,233,4)] {expect(labels[y*image.width+x] == label,"rear-right view protects its visible eye, skin spots and cream chin")}}
            expect(FileManager.default.fileExists(atPath:"Assets.xcassets/volcano-materials.dataset/magma-materials.bin"),"Magma ships prepared material mattes, avoiding analysis during a reaction")
            var alpha=true,protected=true
            for n in labels.indices {if original[n*4+3] != colored[n*4+3] {alpha=false};if labels[n]==0 && original[n*4..<n*4+4] != colored[n*4..<n*4+4] {protected=false}}
            expect(alpha && protected,"Magma recoloring preserves alpha and neutral eyes mouth and three dials")
            let mirror=pixels(DinoSpriteColorRenderer.facingRight(image)!)
            for (x,y) in [(0,0),(image.width/3,image.height/4),(image.width/2,image.height/2)] {let a=(y*image.width+x)*4,b=(y*image.width+image.width-1-x)*4;expect(original[a..<a+4]==mirror[b..<b+4],"Magma mirrors exactly once about pixel centres")}
            let head=pixels(DinoSpriteColorRenderer.volcanoHeadOverflow(image,asset:asset,mirrored:false)!),rig=DinoSpriteColorRenderer.VolcanoRig(asset:asset)
            var contained=true
            for y in 0..<image.height {for x in 0..<image.width where head[(y*image.width+x)*4+3]>0 {let p=CGPoint(x:(Double(x)+0.5)*512/Double(image.width),y:(Double(y)+0.5)*512/Double(image.height));if !rig.head.contains(p) || rig.hands.contains(where:{CGPath(ellipseIn:$0,transform:nil).contains(p)}) {contained=false}}}
            expect(contained,"Magma isolated heads exclude every measured hand and lower-body region")
            if asset == "volcano-idle" {
                var uncropped=true
                for y in 0..<image.height {for x in 0..<image.width where head[(y*image.width+x)*4+3]>0 {if !DinoVolcanoArtwork.portraitCrop.contains(CGPoint(x:1-(Double(x)+0.5)/Double(image.width),y:(Double(y)+0.5)/Double(image.height))) {uncropped=false}}}
                expect(uncropped,"Magma's own friend-avatar crop contains its entire measured frill and muzzle")
            }
            if asset != DinoVolcanoArtwork.openingAsset && !asset.contains("airborne") && !asset.contains("takeoff") && !asset.contains("stumble") {
                var bottom=0
                for y in 0..<image.height {for x in 0..<image.width where original[(y*image.width+x)*4+3]>240 {bottom=max(bottom,y)}}
                let displayed=clipsForGroundProbe(asset:asset)
                expect(abs(Double(bottom)/Double(image.height)+displayed-DinoVolcanoArtwork.footline)<0.006,"Magma planted poses share the measured ground line after their own registration")
            }
        }
    }
}

extension DinoCoreTests {
    static func testVolcanoMotion() {
        let recovery=["volcano-push-up","volcano-rise-low","volcano-rise-high","volcano-idle"]
        let recoveryKeys=DinoBossAnimation.keys(for:.stumble,character:.volcano)
        var previousEye:CGPoint?
        for asset in recovery {
            let key=recoveryKeys.last(where:{$0.asset==asset})!
            let pose=DinoBossAnimation.sample(.stumble,character:.volcano,elapsed:key.time+0.001).pose
            let measured=DinoVolcanoArtwork.recoveryHeadCenters[asset]!
            let point=CGPoint(x:measured.x-pose.offsetX*512,y:measured.y+pose.offsetY*512)
            if let previousEye {expect(point.y<previousEye.y && hypot(point.x-previousEye.x,point.y-previousEye.y)<46,"Magma rises in measured grounded stages, without the old 100px head jump")}
            previousEye=point
        }
        expect(DinoVolcanoArtwork.recoveryEyeDistances.max()!/DinoVolcanoArtwork.recoveryEyeDistances.min()!<1.09,"recovery keeps the measured eye spacing without affine face stretching")
        let clips:[DinoAnimation.Clip]=[.idle,.thumbsUp,.wrongAnswer,.stumble,.openingJump,.backflip,.pirouette,.worldJump]
        for clip in clips {
            for tick in 0...420 {
                let sample=DinoBossAnimation.sample(clip,character:.volcano,elapsed:Double(tick)/120)
                expect(DinoVolcanoArtwork.assets.contains(sample.pose.asset),"every displayed Magma pose is prepared")
                expect(sample.previousPose == nil && sample.poseBlend == 1,"Magma never renders two translucent bodies")
                expect([sample.height,sample.angle,sample.pose.offsetX,sample.pose.offsetY].allSatisfy {$0.isFinite},"Magma motion is finite")
            }
            let end=DinoBossAnimation.sample(clip,character:.volcano,elapsed:DinoAnimation.duration(clip)+1)
            expect(end.pose.asset == "volcano-idle" && end.previousPose == nil,"each Magma clip settles on one opaque canonical idle")
        }
        for contact in DinoAnimation.correctAnswerClapContacts {expect(DinoBossAnimation.sample(.thumbsUp,character:.volcano,elapsed:contact).pose.asset.contains("contact"),"both clap contacts use touching Magma palms")}
        for step in 0...100 {let o=DinoBossAnimation.unlockOpacity(progress:Double(step)/100,character:.volcano);expect(o.source+o.unlocked == 1 && (o.source==0 || o.source==1),"Magma unlock swaps a single opaque actor")}
        expect(DinoWelcomeJump.assets(for:.volcano) == ["dino-idle"],"Magma's large welcome holds one detailed painting")
        for size in [CGSize(width:390,height:844),CGSize(width:844,height:390),CGSize(width:834,height:1194),CGSize(width:1194,height:834)] {
            let f=DinoWelcomeFlight(source:CGPoint(x:size.width/2,y:size.height*0.4),sourceSide:min(size.width,480),destination:CGRect(x:40,y:size.height*0.7,width:150,height:150),character:.volcano)
            for t in [DinoWelcomeJump.crouchBottom,DinoWelcomeJump.takeoff,DinoWelcomeJump.flightHandoff,DinoWelcomeJump.landing] {
                let a=f.paintedHead(elapsed:t-0.00001),b=f.paintedHead(elapsed:t+0.00001)
                expect(hypot(a.center.x-b.center.x,a.center.y-b.center.y)<0.2,"Magma eyes remain continuous across preparation takeoff handoff and landing")
            }
        }
    }
}

extension DinoCoreTests {
    private static func clipsForGroundProbe(asset:String)->Double {
        for clip:DinoAnimation.Clip in [.idle,.thumbsUp,.wrongAnswer,.openingJump,.backflip,.stumble,.pirouette] {
            if let key=DinoBossAnimation.keys(for:clip,character:.volcano).first(where:{$0.asset==asset}) {return DinoBossAnimation.sample(clip,character:.volcano,elapsed:key.time+0.001).pose.offsetY}
        }
        return 0
    }
}

extension DinoCoreTests {
    @MainActor static func testVillageCharacter() {
        let world = DinoWorldCatalog.world(4)!
        let identity = DinoIdentity.village
        expect(world.themeID == 4 && world.bossLevel == 40 && world.bossKey == "dino.world.4.boss", "Klokdorp uses its catalog theme and boss")
        expect(DinoIdentity.boss(in: world.id) == identity && identity.rawValue == 4 && identity.unlockLevel == 40 &&
               identity.bossAsset == "boss-clock-village", "Tik-Tak owns stable save value 4 and the Klokdorp boss")
        let legacy = try! JSONDecoder().decode(PlayerProfile.self, from: JSONEncoder().encode(PlayerProfile()))
        expect(legacy.collectionCharacters[3] == identity && !legacy.isCharacterUnlocked(identity), "older saves keep Tik-Tak in locked slot four")

        var before = legacy
        for boss in [10, 20, 30] { before.recordCompletedAttempt(levelID: boss, correct: 10) }
        expect(before.selectCharacter(.volcano), "start Klokdorp with a different playable boss")
        before.dinoAppearance?[.body] = 0x1965E1
        before.recordCompletedAttempt(levelID: 40, correct: 9)
        expect(!before.isCharacterUnlocked(identity), "a nine-answer pass without the route keeps his slot locked")
        for id in 31...38 { before.recordCompletedAttempt(levelID: id, correct: 3) }

        let store = DinoProgressStore(defaults: InMemoryKeyValueStore())
        store.save(before)
        let player = DinoPlayer(store: store)
        var rng = SeededGenerator(seed: 22)
        func finish(_ id: Int, on player: DinoPlayer) -> DinoLevelResult {
            let level = DinoLevelCatalog.level(id)!
            var attempt = LevelAttempt(levelID: id, questions: DinoQuestionGenerator.generate(level: level, using: &rng))
            while !attempt.isComplete {
                _ = attempt.submit(attempt.current.answer ?? .time(attempt.current.target))
                attempt.advance()
            }
            return player.finish(attempt)!
        }
        let lateLesson = finish(39, on: player)
        expect(lateLesson.hasPendingCharacterUnlock(in: player.profile) && player.profile.activeCharacter == .volcano,
               "the final ordinary lesson after an early boss pass stages the unlock while retaining the result actor")
        expect(DinoWorldTransition(after: 4)?.destinationLevel == 41, "Klokdorp arrives at Crystal Cave")
        let resumed = DinoPlayer(store: store)
        expect(resumed.profile.pendingCharacterUnlock == .village, "closing before the arrival preserves the pending identity")
        resumed.completeCharacterUnlock()
        expect(resumed.profile.activeCharacter == .village && resumed.profile.pendingCharacterUnlock == nil
               && resumed.profile.collectionCharacters[3] == .volcano, "arrival activates Tik-Tak and swaps Magma into slot four")
        let resident = resumed.profile.mapResident(in: 4)!
        expect(DinoAppearance.standard(for: resident).body == 0xFF783E && resumed.profile.dinoAppearance?.body == 0x1965E1,
               "the map resident gets its native orange while the active skin retains the selected blue")
        resumed.completeCharacterUnlock()
        resumed.selectCharacter(.volcano)
        expect(resumed.profile.collectionCharacters[3] == .village && resumed.profile.mapResident(in: 4) == .village,
               "manual selection returns Tik-Tak to his original collection and map slot")
        _ = finish(40, on: resumed)
        expect(resumed.profile.activeCharacter == .volcano && resumed.profile.pendingCharacterUnlock == nil, "replays preserve manual selection")
        expect(DinoPlayer(store: store).profile == resumed.profile, "identity, palette and slot order survive a relaunch")

        store.save(before)
        let perfect = DinoPlayer(store: store)
        expect(finish(40, on: perfect).victory == .perfect && perfect.profile.pendingCharacterUnlock == .village,
               "ten correct answers stage the same unlock without completing the route")
        expect(DinoWorldTransition(after: DinoWorldCatalog.worlds.last!.id) == nil, "the last map has no level 101")
        perfect.completeCharacterUnlock()
        expect(perfect.profile.activeCharacter == .village, "pending completion works independently of the map journey")
        perfect.setDinoAppearance(.standard(for: .village))
        expect(perfect.profile.activeCharacter == .village && perfect.profile.dinoAppearance?.hasOriginalColors == true,
               "resetting colors keeps the active identity")
        perfect.resetProgress()
        let reset = DinoPlayer(store: store).profile
        expect(reset.activeCharacter == .main && reset.pendingCharacterUnlock == nil && reset.characterSlots == nil &&
               !reset.isCharacterUnlocked(.village), "persisted progress reset clears the unlock and slot swap")
        testVillageMotion()
        testVillageMattes()
    }

    static func testVillageMotion() {
        let identity = DinoIdentity.village
        let clips: [DinoAnimation.Clip] = [.idle, .thumbsUp, .wrongAnswer, .stumble, .openingJump, .backflip, .pirouette, .worldJump]
        var used = Set<String>()
        for clip in clips {
            let duration = DinoAnimation.duration(clip)
            let samples = (0...Int(ceil(120 * duration))).map {
                DinoBossAnimation.sample(clip, character: identity, elapsed: Double($0) / 120)
            }
            used.formUnion(samples.map(\.pose.asset))
            expect(samples.allSatisfy { $0.previousPose == nil && $0.poseBlend == 1 && $0.height.isFinite && $0.angle.isFinite },
                   "\(clip) always uses one opaque registered painting")
            let end = DinoBossAnimation.sample(clip, character: identity, elapsed: duration)
            expect(end.pose.asset == "village-idle" && abs(end.height) < 0.001 && abs(end.angle.truncatingRemainder(dividingBy: 360)) < 0.001,
                   "\(clip) settles in the canonical idle pose")
        }
        expect(used == identity.artworkAssets, "every shipped village sprite is actually displayed")
        for contact in DinoAnimation.correctAnswerClapContacts {
            expect(DinoBossAnimation.sample(.thumbsUp, character: identity, elapsed: contact).pose.asset == "village-clap-contact",
                   "both visible claps meet their shared sound/effect time")
        }
        let head = DinoWelcomeJump.idleHead(for: identity)
        expect(head.leftEye.x > head.rightEye.x && abs(head.leftEye.x - (1 - DinoVillageArtwork.headLandmarks[0].x)) < 1e-9,
               "the opening's prepared eye landmarks use the same single reflection as the artwork")
        expect(DinoWelcomeJump.assets(for: identity) == ["dino-idle"], "the large opening retains one detailed pose throughout")
    }

    static func testVillageMattes() {
        func rgba(_ source: CGImage) -> [UInt8] {
            let width = source.width, height = source.height
            var pixels = [UInt8](repeating: 0, count: width * height * 4)
            pixels.withUnsafeMutableBytes { bytes in
                let context = CGContext(data: bytes.baseAddress, width: width, height: height, bitsPerComponent: 8,
                    bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)!
                context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
            }
            return pixels
        }
        let native = DinoAppearance.standard(for: .village)
        let colors = DinoAppearance(bandana: 0x9B50E2, spikes: 0x309956, body: 0x3086DF, belly: 0xE46296, character: .village)
        // Measure each hub in its registered 512² source canvas. A rear
        // angle moves the clock to the opposite side of the silhouette.
        let hubs: [String: (Int, Int)] = [
            "village-idle": (102, 130), "village-clap-open": (111, 130),
            "village-clap-contact": (112, 130), "village-clap-release": (110, 131),
            "village-wrong": (110, 129), "village-crouch": (90, 197),
            "village-airborne": (121, 135), "village-stumble": (91, 150),
            "village-fallen": (101, 170), "village-rise-low": (101, 172),
            "village-push-up": (105, 172), "village-rise-high": (103, 173),
            "village-turn-01": (113, 140), "village-turn-02": (137, 135), "village-turn-03": (175, 137),
            "village-turn-04": (394, 143), "village-turn-05": (393, 144), "village-turn-06": (371, 137),
            "village-turn-07": (127, 139)
        ]
        expect(Set(hubs.keys) == DinoVillageArtwork.assets, "every pose has an independently measured clock")
        for name in DinoVillageArtwork.assets.sorted() + [DinoVillageArtwork.openingAsset] {
            let url = URL(fileURLWithPath: "Assets.xcassets/\(name).imageset/\(name).png")
            let source = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
            let original = rgba(source)
            let defaults = DinoSpriteColorRenderer.recoloredBoss(source, appearance: native, asset: name)!
            let changed = rgba(DinoSpriteColorRenderer.recoloredBoss(source, appearance: colors, asset: name)!)
            let labels = DinoSpriteColorRenderer.villageLabels(source, asset: name)!
            let mirror = DinoSpriteColorRenderer.facingRight(source)!
            let hat = rgba(DinoSpriteColorRenderer.bossHeadOverflow(mirror, character: .village, asset: name)!)
            let width = source.width, height = source.height
            expect(original == rgba(defaults) && original != changed, "\(name) preserves original colors and supports customization")
            var alphaMatches = true, protectedMatches = true, maskMatches = true
            var lowestOpaque = 0, firstHat = height, lastHat = 0
            for n in labels.indices {
                let sourceIndex = n * 4
                let x = n % width, y = n / width
                let flippedIndex = (y * width + width - 1 - x) * 4
                let originalAlpha = original[sourceIndex + 3]
                if originalAlpha != changed[sourceIndex + 3] { alphaMatches = false }
                if labels[n] & 7 == 0 {
                    for channel in 0..<3 where original[sourceIndex + channel] != changed[sourceIndex + channel] { protectedMatches = false }
                }
                if hat[flippedIndex + 3] != (labels[n] & 8 == 0 ? 0 : originalAlpha) { maskMatches = false }
                if originalAlpha >= 230 { lowestOpaque = max(lowestOpaque, y) }
                if hat[flippedIndex + 3] > 0 {
                    firstHat = min(firstHat, y)
                    lastHat = max(lastHat, y)
                }
            }
            expect(alphaMatches && protectedMatches, "\(name) keeps source alpha and protected paint across recoloring")
            expect(maskMatches && lastHat > firstHat && lastHat - firstHat < height / 4,
                   "\(name) overlays the mirrored hat pixels only")
            if let (x, y) = hubs[name] {
                let center = y * width + x
                expect(labels[center] == 0 && original[center * 4 + 3] > 240,
                       "\(name) has a complete opaque clock dial and keeps its neutral cap out of the hat matte")
            }
            if ["village-stumble", "village-fallen", "village-rise-low", "village-push-up"].contains(name) {
                let palm = 459 * width + 375
                expect(original[palm * 4 + 3] >= 240 && labels[palm] & 8 == 0,
                       "\(name) supports weight at the fixed hand contact below the portrait layer")
            }
            if name != DinoVillageArtwork.openingAsset && name != "village-airborne" {
                expect(abs(Double(lowestOpaque) / Double(height) - identityFootline) < 0.018, "\(name) retains its measured planted ground line")
            }
            if name == "village-idle" {
                let points: [(Int, Int, UInt8)] = [(201, 139, 0), (267, 142, 0), (101, 130, 0), (294, 48, 1),
                    (228, 75, 2), (132, 366, 3), (365, 326, 4), (232, 353, 5), (160, 448, 5)]
                for (x, y, label) in points {
                    expect(labels[y * width + x] & 7 == label, "\(x),\(y) stays in its traced material")
                }
            }
            if name == "village-idle" || name == DinoVillageArtwork.openingAsset {
                for (x, y, label) in [(340, 150, UInt8(3)), (315, 145, 4), (430, 311, 3)] {
                    let index = (y * height / 512) * width + x * width / 512
                    expect(labels[index] & 7 == label, "village head and tail spikes include their tips while the cheek remains skin")
                }
            }
        }
    }

    private static var identityFootline: Double { DinoIdentity.village.standingFootline }
}

extension DinoCoreTests {
    @MainActor static func testCaveCharacter() {
        let identity = DinoIdentity.cave
        let world = DinoWorldCatalog.world(5)!
        expect(world.themeID == 5 && world.bossLevel == 50 && world.bossKey == "dino.world.5.boss"
               && DinoIdentity.boss(in: world.id) == identity && identity.rawValue == 5
               && identity.bossAsset == "boss-crystal-cave", "Prisma uses the fifth saved identity and the Crystal Cave boss")
        let legacy = try! JSONDecoder().decode(PlayerProfile.self, from: JSONEncoder().encode(PlayerProfile()))
        expect(legacy.collectionCharacters[4] == identity && !legacy.isCharacterUnlocked(identity),
               "old saves retain the locked Prisma tile")
        var before = legacy
        for boss in [10, 20, 30, 40] { before.recordCompletedAttempt(levelID: boss, correct: 10) }
        expect(before.selectCharacter(.village), "enter Crystal Cave with Tik-Tak")
        before.dinoAppearance?[.body] = 0x1965E1

        var rng = SeededGenerator(seed: 51)
        func finish(_ id: Int, count: Int, on player: DinoPlayer) -> DinoLevelResult {
            let level = DinoLevelCatalog.level(id)!
            let questions = DinoQuestionGenerator.generate(level: level, using: &rng)
            var attempt = LevelAttempt(levelID: id, questions: questions)
            for (index, question) in questions.enumerated() {
                _ = attempt.submit(index < count ? question.expectedAnswer : .duration(-1))
                attempt.advance()
            }
            return player.finish(attempt)!
        }

        let store = DinoProgressStore(defaults: InMemoryKeyValueStore())
        store.save(before)
        let player = DinoPlayer(store: store)
        _ = finish(50, count: 9, on: player)
        expect(!player.profile.isCharacterUnlocked(identity) && player.profile.pendingCharacterUnlock == nil,
               "nine correct without the complete route leaves Prisma locked")
        for id in 41...48 { _ = finish(id, count: 5, on: player) }
        let lateLesson = finish(49, count: 5, on: player)
        expect(lateLesson.hasPendingCharacterUnlock(in: player.profile) && player.profile.activeCharacter == .village,
               "ordinary route completion can stage the unlock while preserving the result actor")
        expect(DinoWorldTransition(after: 5)?.sourceLevel == 50 && DinoWorldTransition(after: 5)?.destinationLevel == 51,
               "Prisma crosses from the boss stone into chapter six")

        let resumed = DinoPlayer(store: store)
        expect(resumed.profile.pendingCharacterUnlock == identity, "an interrupted arrival survives relaunch")
        resumed.completeCharacterUnlock()
        expect(resumed.profile.activeCharacter == identity && resumed.profile.collectionCharacters[4] == .village
               && resumed.profile.pendingCharacterUnlock == nil, "arrival activates Prisma and swaps the fifth tile")
        let resident = resumed.profile.mapResident(in: 5)!
        expect(resident == .village && DinoAppearance.standard(for: resident).body == 0xF2AB51
               && resumed.profile.dinoAppearance?.body == 0x1965E1, "resident and active actor use their own colors")
        resumed.setDinoAppearance(.standard(for: identity))
        expect(resumed.profile.dinoAppearance?.hasOriginalColors == true && resumed.profile.activeCharacter == identity,
               "restoring Prisma's source palette keeps the identity")
        resumed.selectCharacter(.village)
        expect(resumed.profile.mapResident(in: 5) == identity && resumed.profile.collectionCharacters[4] == identity,
               "Prisma can return to the original slot")
        expect(DinoPlayer(store: store).profile == resumed.profile, "manual selection and colors persist")
        resumed.resetProgress()
        let reset = DinoPlayer(store: store).profile
        expect(reset.activeCharacter == .main && reset.characterSlots == nil && !reset.isCharacterUnlocked(identity),
               "reset removes Prisma progression and the slot swap")

        store.save(before)
        let perfect = DinoPlayer(store: store)
        let result = finish(50, count: 10, on: perfect)
        expect(result.victory == .perfect && result.hasPendingCharacterUnlock(in: perfect.profile),
               "perfect boss victory unlocks Prisma without the normal levels")
        expect(DinoWorldTransition(after: 10) == nil, "the final world has no level 101")
        perfect.completeCharacterUnlock()
        expect(perfect.profile.activeCharacter == identity, "pending activation can complete without a journey")
        testCaveMotion()
        testCaveMattes()
    }

    static func testCaveMotion() {
        let clips: [DinoAnimation.Clip] = [.idle, .thumbsUp, .wrongAnswer, .stumble, .openingJump, .backflip, .pirouette, .worldJump]
        var used = Set<String>()
        for clip in clips {
            let duration = DinoAnimation.duration(clip)
            for tick in 0...Int(ceil(120 * duration)) {
                let sample = DinoBossAnimation.sample(clip, character: .cave, elapsed: Double(tick) / 120)
                used.insert(sample.pose.asset)
                expect(sample.previousPose == nil && sample.poseBlend == 1 && sample.height.isFinite && sample.angle.isFinite,
                       "Prisma displays a single painting throughout \(clip)")
            }
            for reducedMotion in [false, true] {
                let end = DinoBossAnimation.sample(clip, character: .cave, elapsed: duration, reducedMotion: reducedMotion)
                expect(end.pose.asset == "cave-idle" && abs(end.height) < 0.001, "Prisma returns to the ground and idle after \(clip)")
            }
        }
        expect(used == DinoCaveArtwork.assets, "every Prisma pose is used")
        let turnKeys = DinoBossAnimation.keys(for: .pirouette, character: .cave)
        for (name, hip) in zip(DinoCaveArtwork.turnAssets, DinoCaveArtwork.turnHipX) {
            let key = turnKeys.first { $0.asset == name }!
            let frame = DinoBossAnimation.sample(.pirouette, character: .cave, elapsed: key.time)
            let alignedAxis = 1 - hip / 512 + frame.pose.offsetX
            expect(abs(alignedAxis - (1 - DinoCaveArtwork.idleHipX / 512)) < 1e-9,
                   "Prisma rotates about one registered hip axis")
        }
        for t in DinoAnimation.correctAnswerClapContacts {
            expect(DinoBossAnimation.sample(.thumbsUp, character: .cave, elapsed: t).pose.asset == "cave-clap-contact",
                   "both clap sounds coincide with touching Prisma palms")
        }
        expect(DinoWelcomeJump.assets(for: .cave) == ["dino-idle"], "the welcome holds one detailed painting")
        let head = DinoWelcomeJump.idleHead(for: .cave)
        expect(abs(head.leftEye.x - (1 - DinoCaveArtwork.headLandmarks[0].x)) < 1e-9 && head.leftEye.x > head.rightEye.x,
               "preparation mirrors the face coordinates once")
        for size in [CGSize(width: 390, height: 844), CGSize(width: 1194, height: 834)] {
            let flight = DinoWelcomeFlight(source: CGPoint(x: size.width / 2, y: size.height * 0.4), sourceSide: min(size.width, 480),
                destination: CGRect(x: 40, y: size.height * 0.7, width: 150, height: 150), character: .cave)
            for time in [DinoWelcomeJump.crouchBottom, DinoWelcomeJump.takeoff, DinoWelcomeJump.flightHandoff, DinoWelcomeJump.landing] {
                let a = flight.paintedHead(elapsed: time - 0.00001), b = flight.paintedHead(elapsed: time + 0.00001)
                expect(hypot(a.center.x - b.center.x, a.center.y - b.center.y) < 0.2, "Prisma's welcome follows a continuous screen path")
            }
        }
    }

    static func testCaveMattes() {
        func rgba(_ image: CGImage) -> [UInt8] {
            var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
            pixels.withUnsafeMutableBytes {
                let context = CGContext(data: $0.baseAddress, width: image.width, height: image.height, bitsPerComponent: 8,
                    bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)!
                context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            }
            return pixels
        }
        let colors = DinoAppearance(bandana: 0xAA43DE, spikes: 0x41AA53, body: 0xED8055, belly: 0xE15198, character: .cave)
        for name in DinoCaveArtwork.assets.union([DinoCaveArtwork.openingAsset]) {
            let url = URL(fileURLWithPath: "Assets.xcassets/\(name).imageset/\(name).png")
            let source = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
            let n = source.width, original = rgba(source)
            let labels = DinoSpriteColorRenderer.caveLabels(source, asset: name)!
            let colored = DinoSpriteColorRenderer.recoloredBoss(source, appearance: colors, asset: name)!
            let result = rgba(colored)
            let mirrored = DinoSpriteColorRenderer.facingRight(colored)!
            let crown = rgba(DinoSpriteColorRenderer.caveHead(mirrored, asset: name, mirrored: true)!)
            var changed = Set<UInt8>()
            var alphaAndMaskMatch = true, protected = true, sole = 0, visibleCrownPixels = 0
            for i in labels.indices where original[i * 4 + 3] > 0 {
                let p = i * 4, x = i % n, y = i / n
                let mirroredAlpha = crown[(y * n + n - x - 1) * 4 + 3]
                alphaAndMaskMatch = alphaAndMaskMatch && original[p + 3] == result[p + 3]
                    && mirroredAlpha == (labels[i] & 8 == 0 ? 0 : original[p + 3])
                if mirroredAlpha >= 240 { visibleCrownPixels += 1 }
                if original[p + 3] >= 240 { sole = max(sole, y) }
                let didChange = result[p..<(p + 3)] != original[p..<(p + 3)]
                if labels[i] & 7 == 0 { protected = protected && !didChange }
                if didChange { changed.insert(labels[i] & 7) }
            }
            expect(alphaAndMaskMatch && protected, "\(name) retains alpha and protected eyes/dial while the crown uses mirrored pixel centres")
            expect(visibleCrownPixels > n && changed.contains(2) && changed.contains(4), "\(name) has a mounted crown, crystals and skin")
            if name != "cave-airborne" {
                expect(abs(Double(sole + 1) / Double(n) - DinoCaveArtwork.footline) < 0.014,
                       "\(name) is registered to the same support line")
            }
            if name == "cave-idle" || name == DinoCaveArtwork.openingAsset {
                func label(x: Double, y: Double) -> UInt8 { labels[Int(y * Double(n) / 512) * n + Int(x * Double(n) / 512)] }
                expect(label(x: 216, y: 73) & 7 == 3, "the central crystal's lit facet shares its violet material")
                expect(label(x: 204, y: 318) & 7 == 0 && label(x: 186, y: 297) & 7 == 1,
                       "Prisma's dial and gold rim have independent regions at either resolution")
                expect(label(x: 122, y: 368) & 8 == 0 && label(x: 291, y: 269) & 8 == 0
                       && label(x: 203, y: 62) & 8 != 0, "only crown facets can overflow the portrait")
                expect(changed.isSuperset(of: [1, 2, 3, 4, 5, 6, 7]), "all Prisma materials can be personalized")
            }
        }
    }

    @MainActor static func testNeonCharacter() {
        let character = DinoIdentity.city
        let world = DinoWorldCatalog.world(6)!
        expect(world.themeID == 6 && world.bossLevel == 60 && world.bossKey == "dino.world.6.boss"
               && character.rawValue == 6 && character.bossAsset == "boss-clock-city"
               && DinoIdentity.boss(in: world.id) == character, "Neon belongs to Klokstad and the sixth saved slot")
        var profile = try! JSONDecoder().decode(PlayerProfile.self, from: JSONEncoder().encode(PlayerProfile()))
        expect(profile.collectionCharacters[5] == character && !profile.isCharacterUnlocked(character), "a legacy profile reserves Neon's locked slot")
        for id in [10, 20, 30, 40, 50] { profile.recordCompletedAttempt(levelID: id, correct: 10) }
        expect(profile.selectCharacter(.cave), "Prisma can enter Klokstad")
        profile.dinoAppearance?[.body] = 0xB32049
        var rng = SeededGenerator(seed: 61)
        func finish(_ id: Int, correct: Int, player: DinoPlayer) -> DinoLevelResult {
            let level = DinoLevelCatalog.level(id)!
            let questions = DinoQuestionGenerator.generate(level: level, using: &rng)
            var attempt = LevelAttempt(levelID: id, questions: questions)
            for (index, question) in questions.enumerated() {
                _ = attempt.submit(index < correct ? question.expectedAnswer : .duration(-1))
                attempt.advance()
            }
            return player.finish(attempt)!
        }

        let store = DinoProgressStore(defaults: InMemoryKeyValueStore())
        store.save(profile)
        let player = DinoPlayer(store: store)
        expect(finish(60, correct: 9, player: player).victory == .none && player.profile.pendingCharacterUnlock == nil,
               "a partial boss pass without the route leaves Neon locked")
        for id in 51...58 { _ = finish(id, correct: 5, player: player) }
        let lastLesson = finish(59, correct: 5, player: player)
        expect(lastLesson.hasPendingCharacterUnlock(in: player.profile) && player.profile.activeCharacter == .cave,
               "completing the route after the boss stages the same unlock from an ordinary result")
        expect(DinoWorldTransition(after: 6)?.sourceLevel == 60 && DinoWorldTransition(after: 6)?.destinationLevel == 61,
               "Neon's journey leads from Klokstad to the first Sleep Valley level")
        let resumed = DinoPlayer(store: store)
        expect(resumed.profile.pendingCharacterUnlock == character, "the pending identity survives an interrupted journey")
        resumed.completeCharacterUnlock()
        expect(resumed.profile.activeCharacter == character && resumed.profile.pendingCharacterUnlock == nil
               && resumed.profile.collectionCharacters[5] == .cave, "recovery activates Neon and swaps the sixth slot")
        let resident = resumed.profile.mapResident(in: 6)!
        expect(resident == .cave && DinoAppearance.standard(for: resident).body == 0x93AEBE
               && resumed.profile.dinoAppearance?.body == 0xB32049, "the resident keeps its own palette while the active customization carries over")
        resumed.setDinoAppearance(.standard(for: character))
        expect(resumed.profile.activeCharacter == character && resumed.profile.dinoAppearance?.hasOriginalColors == true,
               "original colors restore Neon's native palette with the identity selected")
        resumed.selectCharacter(.cave)
        expect(resumed.profile.mapResident(in: 6) == character && DinoPlayer(store: store).profile == resumed.profile,
               "Neon returns to slot six and the swap is saved")
        resumed.resetProgress()
        let reset = DinoPlayer(store: store).profile
        expect(reset.activeCharacter == .main && reset.characterSlots == nil && reset.pendingCharacterUnlock == nil
               && !reset.isCharacterUnlocked(character), "reset locks Neon and removes the pending unlock and collection swap")

        store.save(profile)
        let perfect = DinoPlayer(store: store)
        expect(finish(60, correct: 10, player: perfect).hasPendingCharacterUnlock(in: perfect.profile),
               "perfect boss victory stages Neon even with the ordinary route unfinished")
        // The shared completion path can also run when a world has no next level.
        expect(DinoWorldTransition(after: 10) == nil, "no transition targets level 101")
        perfect.completeCharacterUnlock()
        expect(perfect.profile.activeCharacter == character, "pending activation can finish without a transition")
        testNeonMotion()
        testNeonMattes()
    }

    static func testNeonMotion() {
        var used = Set<String>()
        let character = DinoIdentity.city
        let clips: [DinoAnimation.Clip] = [.idle, .thumbsUp, .wrongAnswer, .stumble, .openingJump, .backflip, .pirouette, .worldJump]
        for clip in clips {
            let end = DinoAnimation.duration(clip)
            let samples = (0...Int(ceil(end * 120))).map {
                DinoBossAnimation.sample(clip, character: character, elapsed: Double($0) / 120)
            }
            expect(samples.allSatisfy { $0.previousPose == nil && $0.poseBlend == 1 && $0.height.isFinite && $0.angle.isFinite },
                   "Neon has one fully composed figure throughout \(clip)")
            used.formUnion(samples.map(\.pose.asset))
            for reducedMotion in [false, true] {
                let rest = DinoBossAnimation.sample(clip, character: character, elapsed: end, reducedMotion: reducedMotion)
                expect(rest.pose.asset == "city-idle" && abs(rest.height) < 0.001 && rest.previousPose == nil,
                       "Neon finishes \(clip) planted in the canonical rest pose")
            }
        }
        expect(used == DinoCityArtwork.assets, "every Neon gameplay pose is displayed")
        let clap = DinoAnimation.correctAnswerClapContacts
        for t in clap {
            expect(DinoBossAnimation.sample(.thumbsUp, character: character, elapsed: t).pose.asset == "city-clap-contact",
                   "both effects align with the clasped palms")
        }
        expect(DinoBossAnimation.sample(.thumbsUp, character: character, elapsed: (clap[0] + clap[1]) / 2).pose.asset == "city-clap-open",
               "the palms visibly reopen between contacts")
        let placement = DinoCityArtwork.portraitPlacement
        let palm = DinoCityArtwork.clapContact
        let palmX = (palm.x - 0.5) * placement.scale + placement.x
        let palmY = (palm.y - 0.5) * placement.scale + placement.y
        expect(hypot(palmX, palmY) < 0.47, "the joined palms and the effect center are visible inside the HUD rim")
        let turn = DinoBossAnimation.keys(for: .pirouette, character: character).filter { $0.asset.hasPrefix("city-turn-") }
        expect(turn.map(\.asset) == DinoCityArtwork.turnAssets && zip(turn, turn.dropFirst()).allSatisfy { $1.time - $0.time > 0.06 },
               "the pirouette uses sequential views at a readable order and cadence")
        let head = DinoWelcomeJump.idleHead(for: character)
        expect(head.leftEye.x == 1 - DinoCityArtwork.headLandmarks[0].x && head.leftEye.y == DinoCityArtwork.headLandmarks[0].y,
               "the welcome's feature coordinates reflect only once")
        expect(DinoWelcomeJump.assets(for: character) == ["dino-idle"], "the entire welcome holds one illustration")
        expect(DinoBossAnimation.assets(for: .openingJump, character: character) == ["city-idle"],
               "the one-star takeoff and landing retain the same drawing")
        let brace = DinoAnimation.leadIn(.stumble) + DinoAnimation.stumblePushStart
        let push = DinoBossAnimation.sample(.stumble, character: character, elapsed: brace)
        expect(push.pose.asset == "city-push-up" && abs(1 - 197.5 / 512 + push.pose.offsetX - (1 - 203.0 / 512)) < 1e-9,
               "the two planted recovery poses share a palm midpoint after mirroring")
        for p in [0.0, 0.58, 0.679, 0.68, 0.8, 1] {
            let alpha = DinoBossAnimation.unlockOpacity(progress: p, character: character)
            expect(alpha.source + alpha.unlocked == 1 && [0.0, 1.0].contains(alpha.unlocked), "the city unlock shows one character at a time")
        }
    }

    static func testNeonMattes() {
        func rgba(_ image: CGImage) -> [UInt8] {
            var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
            pixels.withUnsafeMutableBytes { buffer in
                let context = CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                                        bitsPerComponent: 8, bytesPerRow: image.width * 4,
                                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                        bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)!
                context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            }
            return pixels
        }
        let standard = DinoAppearance.standard(for: .city)
        let contrasted = DinoAppearance(bandana: 0x9C47EC, spikes: 0x3BAD4F, body: 0xCD4552, belly: 0xEF80BD, character: .city)
        let poseChecks = ["city-idle", "city-clap-open", "city-clap-contact", "city-wrong"]
        for name in DinoCityArtwork.assets.union([DinoCityArtwork.openingAsset]) {
            let url = URL(fileURLWithPath: "Assets.xcassets/\(name).imageset/\(name).png")
            let source = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
            let n = source.width, original = rgba(source)
            let labels = DinoSpriteColorRenderer.cityLabels(source, asset: name)!
            let painted = DinoSpriteColorRenderer.recoloredBoss(source, appearance: contrasted, asset: name)!
            let result = rgba(painted)
            let mirrored = DinoSpriteColorRenderer.facingRight(painted)!
            let cap = rgba(DinoSpriteColorRenderer.cityHead(mirrored, asset: name, mirrored: true)!)
            expect(DinoSpriteColorRenderer.recoloredBoss(source, appearance: standard, asset: name) === source,
                   "\(name) uses the original painting for native colors")
            var colors = Set<UInt8>()
            var alphaMatches = true, protectionMatches = true, capMatches = true, sole = 0
            var capPixels = 0
            for i in labels.indices {
                let alpha = original[i * 4 + 3], label = labels[i], p = i * 4
                let x = i % n, y = i / n
                let capAlpha = cap[(y * n + n - x - 1) * 4 + 3]
                alphaMatches = alphaMatches && alpha == result[p + 3]
                capMatches = capMatches && capAlpha == (label & 8 != 0 ? alpha : 0)
                if capAlpha > 0 { capPixels += 1 }
                if alpha >= 240 { sole = max(sole, y) }
                if alpha > 0 && result[p..<(p + 3)] != original[p..<(p + 3)] {
                    colors.insert(label & 7)
                    protectionMatches = protectionMatches && label & 7 != 0
                }
            }
            expect(alphaMatches && protectionMatches && capMatches && capPixels > n,
                   "\(name) preserves source alpha and protected paint and isolates the mirrored crest")
            expect(colors.isSuperset(of: [1, 2, 3, 4]), "\(name) has separate regions for metal, membranes, skin and light surfaces")
            if name != "city-airborne" {
                expect(abs(Double(sole + 1) / Double(n) - DinoCityArtwork.footline) < 0.012, "\(name) retains the planted contact line")
            }
            if poseChecks.contains(name) || name == DinoCityArtwork.openingAsset {
                func label(_ x: Double, _ y: Double) -> UInt8 {
                    labels[Int(y * Double(n) / 512) * n + Int(x * Double(n) / 512)]
                }
                expect(label(134, 277) & 7 == 0 && label(339, 281) & 7 == 0,
                       "\(name) protects both clock faces")
                expect(label(302, 129) & 8 != 0 && label(220, 210) & 8 == 0
                       && label(240, 308) & 24 == 0 && label(134, 246) & 24 == 0,
                       "\(name) keeps the brim effect on the crest and excludes palms and clocks")
                if name == "city-idle" || name == DinoCityArtwork.openingAsset {
                    expect(label(154, 279) & 7 == 1 && label(135, 245) & 7 == 1 && label(89, 325) & 7 == 2
                           && label(303, 128) & 7 == 3 && label(214, 247) & 7 == 4 && label(180, 468) & 7 == 4
                           && label(264, 193) & 7 == 0, "Neon's dark crest markings, dial, metal, wings, chin, toes and eye have their own materials")
                    let channels: [(DinoAppearance.Part, UInt8)] = [(.bandana, 1), (.spikes, 2), (.body, 3), (.belly, 4)]
                    for (part, expected) in channels {
                        var single = standard
                        single[part] = contrasted[part]
                        let tinted = rgba(DinoSpriteColorRenderer.recoloredBoss(source, appearance: single, asset: name)!)
                        var changedLabels = Set<UInt8>()
                        for i in labels.indices where original[i * 4 + 3] > 0 {
                            let p = i * 4
                            if tinted[p..<(p + 3)] != original[p..<(p + 3)] { changedLabels.insert(labels[i] & 7) }
                        }
                        expect(changedLabels == [expected], "\(name) changes only \(part) when adjusting one channel")
                    }
                }
            }
        }
    }
}

extension DinoCoreTests {
    @MainActor static func testDommelCharacter() {
        let dommel = DinoIdentity.valley
        let world = DinoWorldCatalog.world(7)!
        expect(world.themeID == 2 && world.bossLevel == 70 && world.bossKey == "dino.world.2.boss"
               && dommel.rawValue == 7 && dommel.bossAsset == "boss-sleep-valley"
               && DinoIdentity.boss(in: 7) == dommel, "Dommel maps to Slaapvallei, level 70 and saved identity 7")
        var profile = PlayerProfile()
        expect(profile.collectionCharacters[6] == dommel && !profile.selectCharacter(dommel), "the seventh slot starts locked")
        for id in [10, 20, 30, 40, 50, 60] { profile.recordCompletedAttempt(levelID: id, correct: 10) }
        expect(profile.selectCharacter(.city), "Neon can enter Slaapvallei")
        profile.dinoAppearance?[.body] = 0xB32049
        let store = DinoProgressStore(defaults: InMemoryKeyValueStore())
        store.save(profile)
        let player = DinoPlayer(store: store)
        var rng = SeededGenerator(seed: 71)
        func finish(_ id: Int, _ correct: Int, for player: DinoPlayer) -> DinoLevelResult {
            let level = DinoLevelCatalog.level(id)!
            let questions = DinoQuestionGenerator.generate(level: level, using: &rng)
            var attempt = LevelAttempt(levelID: id, questions: questions)
            for (index, question) in questions.enumerated() {
                _ = attempt.submit(index < correct ? question.expectedAnswer : .duration(-1))
                attempt.advance()
            }
            return player.finish(attempt)!
        }
        expect(finish(70, 9, for: player).victory == .none && player.profile.pendingCharacterUnlock == nil,
               "nine boss answers require the usual completed route")
        for id in 61...68 { _ = finish(id, 5, for: player) }
        let result = finish(69, 5, for: player)
        expect(result.hasPendingCharacterUnlock(in: player.profile) && player.profile.activeCharacter == .city,
               "finishing the route stages Dommel without changing the result actor")
        let journey = DinoWorldTransition(after: 7)
        expect(journey?.sourceLevel == 70 && journey?.destinationLevel == 71, "the world journey starts from Dommel's stone")
        let resumed = DinoPlayer(store: store)
        expect(resumed.profile.pendingCharacterUnlock == dommel, "the pending identity survives closing the app")
        resumed.completeCharacterUnlock()
        let resident = resumed.profile.mapResident(in: 7)
        expect(resumed.profile.activeCharacter == dommel && resumed.profile.pendingCharacterUnlock == nil
               && resident == .city && resumed.profile.collectionCharacters[6] == .city,
               "recovery consumes the pending unlock and swaps the seventh resident")
        expect(DinoAppearance.standard(for: resident!).body == 0x35A8B9 && resumed.profile.dinoAppearance?.body == 0xB32049,
               "the stationary resident uses its own colors")
        resumed.setDinoAppearance(.standard(for: dommel))
        expect(resumed.profile.activeCharacter == dommel && resumed.profile.dinoAppearance?.hasOriginalColors == true,
               "restoring the palette preserves Dommel")
        resumed.selectCharacter(.city)
        expect(resumed.profile.mapResident(in: 7) == dommel && DinoPlayer(store: store).profile == resumed.profile,
               "swapping Dommel back onto the map persists")
        resumed.resetProgress()
        let reset = DinoPlayer(store: store).profile
        expect(reset.activeCharacter == .main && reset.pendingCharacterUnlock == nil && reset.characterSlots == nil
               && reset.collectionCharacters[6] == dommel && !reset.isCharacterUnlocked(dommel),
               "a progress reset restores the locked slot and its own resident")

        store.save(profile)
        let perfect = DinoPlayer(store: store)
        expect(finish(70, 10, for: perfect).hasPendingCharacterUnlock(in: perfect.profile), "a perfect boss result stages Dommel immediately")
        expect(DinoWorldTransition(after: 10) == nil, "the last world has no synthetic destination")
        perfect.completeCharacterUnlock()
        expect(perfect.profile.activeCharacter == dommel, "the shared unlock activates directly when returning without a world journey")
        testDommelMotion()
        testDommelMattes()
    }

    static func testDommelMotion() {
        let clips: [DinoAnimation.Clip] = [.idle, .thumbsUp, .wrongAnswer, .stumble, .openingJump, .backflip, .pirouette, .worldJump]
        var sampled = Set<String>()
        for clip in clips {
            let end = DinoAnimation.duration(clip)
            for tick in 0...Int(ceil(end * 120)) {
                let frame = DinoBossAnimation.sample(clip, character: .valley, elapsed: Double(tick) / 120)
                sampled.insert(frame.pose.asset)
                expect(frame.poseBlend == 1 && frame.previousPose == nil && frame.morph == nil,
                       "Dommel animates as a single opaque drawing")
            }
            let rest = DinoBossAnimation.sample(clip, character: .valley, elapsed: end)
            expect(rest.pose.asset == DinoValleyArtwork.idle && rest.height == 0,
                   "Dommel returns to standing at the exact end of \(clip)")
        }
        expect(sampled == DinoValleyArtwork.assets, "all and only Dommel's runtime poses are sampled")
        for time in DinoAnimation.correctAnswerClapContacts {
            expect(DinoBossAnimation.sample(.thumbsUp, character: .valley, elapsed: time).pose.asset == "valley-clap-contact",
                   "each clap effect coincides with the painted palm seam")
        }
        expect(DinoBossAnimation.sample(.thumbsUp, character: .valley, elapsed: 0.47).pose.asset == "valley-clap-open",
               "the paws visibly separate between contacts")
        let rotation = DinoBossAnimation.assets(for: .pirouette, character: .valley)
        expect(Array(rotation.dropFirst().dropLast()) == DinoValleyArtwork.turnAssets, "turn views read in yaw order")
        let reflection = DinoWelcomeJump.idleHead(for: .valley)
        expect(abs(reflection.leftEye.x + DinoValleyArtwork.headLandmarks[0].x - 1) < 0.00001 &&
               reflection.leftEye.y == DinoValleyArtwork.headLandmarks[0].y, "head tracking reflects source X exactly once")
        let flight = DinoWelcomeFlight(source: CGPoint(x: 210, y: 400), sourceSide: 360,
                                       destination: CGRect(x: 115, y: 500, width: 140, height: 140), character: .valley)
        let landing = flight.worldTransform(elapsed: DinoWelcomeJump.duration)
        let canvasCenter = CGPoint(x: 0.5, y: 0.5).applying(landing)
        expect(flight.footline == DinoValleyArtwork.footline && abs(canvasCenter.x - flight.destination.midX) < 0.01
               && abs(canvasCenter.y - flight.destination.midY) < 0.01, "the measured sole pivot ends on the map sprite's same canvas")
        let handoff = DinoWelcomeJump.flightHandoff
        let before = DinoWelcomeJump.tracking(elapsed: handoff - 0.0001, flight: flight).position
            .applying(flight.worldTransform(elapsed: handoff - 0.0001))
        let after = flight.paintedHead(elapsed: handoff + 0.0001).center
        expect(hypot(before.x - after.x, before.y - after.y) < 0.2, "the native flight handoff does not jump between head positions")
        for tick in 0...Int(ceil(DinoWelcomeJump.duration * 120)) {
            expect(DinoWelcomeJump.pose(elapsed: Double(tick) / 120, character: .valley).asset == "dino-idle",
                   "the welcome uses the same registered artwork through the crouch and flight")
        }
    }

    static func testDommelMattes() {
        func rgba(_ image: CGImage) -> [UInt8] {
            var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
            pixels.withUnsafeMutableBytes { buffer in
                let context = CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                                        bitsPerComponent: 8, bytesPerRow: image.width * 4,
                                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                        bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)!
                context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            }
            return pixels
        }
        let url = URL(fileURLWithPath: "Documentation/SleepValleyCharacterPrompts.json")
        let document = try! JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
        let rigs = document["poses"] as! [String: [String: Any]]
        let original = DinoAppearance.standard(for: .valley)
        let edited = DinoAppearance(bandana: 0xB32475, spikes: 0x42DF70, body: 0xFE843F, belly: 0x65B2DE, character: .valley)
        for asset in DinoValleyArtwork.assets.union([DinoValleyArtwork.openingAsset]) {
            let reference = rigs[asset]!
            let url = URL(fileURLWithPath: "Assets.xcassets/\(asset).imageset/\(asset).png")
            let source = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
            let labels = DinoSpriteColorRenderer.valleyLabels(source, asset: asset)!
            let tinted = DinoSpriteColorRenderer.recoloredBoss(source, appearance: edited, asset: asset)!
            let prepared = DinoSpriteColorRenderer.facingRight(tinted)!
            let cap = DinoSpriteColorRenderer.valleyHead(prepared, asset: asset, mirrored: true)!
            let a = rgba(source), b = rgba(tinted), c = rgba(cap)
            let width = source.width
            var valid = true, sole = 0, capBottom = 0, total = 0
            var colored = Set<UInt8>()
            for i in labels.indices {
                let p = i * 4, alpha = a[p + 3], y = i / width, x = i % width
                let label = labels[i], capAlpha = c[(y * width + width - 1 - x) * 4 + 3]
                valid = valid && b[p + 3] == alpha && capAlpha == (label & 8 != 0 ? alpha : 0)
                if a[p..<(p + 3)] != b[p..<(p + 3)] { colored.insert(label & 7) }
                if alpha >= 200 { sole = max(sole, y + 1) }
                if capAlpha > 0 { total += 1; capBottom = max(capBottom, y) }
            }
            expect(valid && !colored.contains(0) && colored.isSuperset(of: [1, 2, 3, 4]),
                   "\(asset) keeps alpha and separates materials from protected paint")
            expect(total > width && Double(capBottom) / Double(width) < (reference["hatLimitY"] as! Double) / 512,
                   "\(asset) only overflows with the fitted cap and pompom")
            expect(abs(Double(sole) * 512 / Double(width) - (reference["footline"] as! Double)) < 2,
                   "\(asset) preserves its registered ground or flight contact")
            expect(DinoSpriteColorRenderer.recoloredBoss(source, appearance: original, asset: asset) === source,
                   "\(asset) retains original color and texture at defaults")
            func label(at point: [Double]) -> UInt8 {
                let x = Int(point[0] * Double(width) / 512), y = Int(point[1] * Double(width) / 512)
                return labels[y * width + x]
            }
            if let glass = reference["glass"] as? [Double] {
                expect(label(at: glass) == 0, "\(asset) keeps the complete dial and hand pivot protected")
            }
            if let palm = reference["hand"] as? [Double] {
                expect(label(at: palm) & 24 == 0, "\(asset) excludes its raised paws from the head layers")
            }
            if asset == DinoValleyArtwork.idle {
                for (part, expected): (DinoAppearance.Part, Set<UInt8>) in [
                    (.bandana, [1]), (.spikes, [2]), (.body, [3]), (.belly, [4, 5])
                ] {
                    var one = original
                    one[part] = edited[part]
                    let bytes = rgba(DinoSpriteColorRenderer.recoloredBoss(source, appearance: one, asset: asset)!)
                    var changed = Set<UInt8>()
                    for i in labels.indices where a[(i * 4)..<(i * 4 + 3)] != bytes[(i * 4)..<(i * 4 + 3)] {
                        changed.insert(labels[i] & 7)
                    }
                    expect(changed == expected, "the \(part) picker changes only its assigned material")
                }
            }
        }
    }
}

extension DinoCoreTests {
    @MainActor static func testPirateCharacter() {
        let pirate = DinoIdentity.pirates
        let world = DinoWorldCatalog.world(9)!
        expect(pirate.rawValue == 9 && pirate.bossAsset == "boss-pirates" && pirate.unlockLevel == 90
               && world.themeID == 9 && world.bossKey == "dino.world.9.boss" && DinoIdentity.boss(in: world.id) == pirate,
               "Kapitein Zandloper is world 9's boss and keeps the ninth saved identity")
        let journey = DinoWorldTransition(after: 9)
        expect(journey?.sourceLevel == 90 && journey?.destinationLevel == 91
               && DinoWorldTransition(after: 10) == nil, "the final route follows the catalog without a synthetic level")

        var profile = PlayerProfile()
        expect(profile.collectionCharacters[8] == pirate && !profile.selectCharacter(pirate),
               "the ninth collection slot is locked before the victory")
        for id in stride(from: 10, through: 80, by: 10) {
            profile.recordCompletedAttempt(levelID: id, correct: 10)
        }
        expect(profile.selectCharacter(.valley), "a different boss can play before the unlock")
        profile.dinoAppearance?[.body] = 0xCA3D89
        let store = DinoProgressStore(defaults: InMemoryKeyValueStore())
        store.save(profile)
        let player = DinoPlayer(store: store)
        var seed = SeededGenerator(seed: 90)
        func finish(_ levelID: Int, correct: Int, player: DinoPlayer) -> DinoLevelResult {
            let level = DinoLevelCatalog.level(levelID)!
            let questions = DinoQuestionGenerator.generate(level: level, using: &seed)
            var attempt = LevelAttempt(levelID: levelID, questions: questions)
            for (index, question) in questions.enumerated() {
                _ = attempt.submit(index < correct ? question.expectedAnswer : .duration(-1))
                attempt.advance()
            }
            return player.finish(attempt)!
        }
        expect(finish(90, correct: 9, player: player).victory == .none
               && !player.profile.isCharacterUnlocked(pirate), "nine correct answers still require route stars")
        for id in 81...88 { _ = finish(id, correct: 3, player: player) }
        let lateRoute = finish(89, correct: 3, player: player)
        expect(lateRoute.hasPendingCharacterUnlock(in: player.profile) && player.profile.activeCharacter == .valley,
               "the final ordinary lesson can stage a world transition without replacing the result actor")
        let restarted = DinoPlayer(store: store)
        expect(restarted.profile.pendingCharacterUnlock == pirate, "the pending character survives interruption")
        restarted.completeCharacterUnlock()
        restarted.completeCharacterUnlock()
        expect(restarted.profile.activeCharacter == pirate && restarted.profile.pendingCharacterUnlock == nil
               && restarted.profile.collectionCharacters[8] == .valley && restarted.profile.mapResident(in: 9) == .valley,
               "recovery activates the pirate and swaps the outgoing resident exactly once")
        expect(restarted.profile.dinoAppearance?.body == 0xCA3D89 &&
               DinoAppearance.standard(for: restarted.profile.mapResident(in: 9)!).body == 0x78C4DF,
               "the outgoing map resident uses its own palette")
        restarted.setDinoAppearance(.standard(for: pirate))
        expect(restarted.profile.dinoAppearance?.hasOriginalColors == true && restarted.profile.activeCharacter == pirate,
               "original colors preserve the selected pirate")
        restarted.selectCharacter(.valley)
        expect(restarted.profile.mapResident(in: 9) == pirate && DinoPlayer(store: store).profile == restarted.profile,
               "the manual swap persists and restores the pirate to his home")
        restarted.resetProgress()
        let reset = DinoPlayer(store: store).profile
        expect(reset.activeCharacter == .main && reset.collectionCharacters[8] == pirate
               && reset.pendingCharacterUnlock == nil && !reset.isCharacterUnlocked(pirate),
               "reset restores the locked ninth slot")
        store.save(profile)
        let shortcut = DinoPlayer(store: store)
        expect(finish(90, correct: 10, player: shortcut).hasPendingCharacterUnlock(in: shortcut.profile),
               "a perfect match unlocks the pirate without the route")
        shortcut.completeCharacterUnlock()
        expect(shortcut.profile.activeCharacter == pirate, "the pending pirate can activate without a journey")
        testPirateMotion()
        testPirateMattes()
    }

    static func testPirateMotion() {
        let character = DinoIdentity.pirates
        var drawn = Set<String>()
        for clip: DinoAnimation.Clip in [.idle, .thumbsUp, .wrongAnswer, .stumble, .openingJump, .backflip, .pirouette, .worldJump] {
            let end = DinoAnimation.duration(clip)
            for tick in 0...Int(ceil(end * 120)) {
                let sample = DinoBossAnimation.sample(clip, character: character, elapsed: Double(tick) / 120)
                drawn.insert(sample.pose.asset)
                expect(sample.previousPose == nil && sample.poseBlend == 1 && sample.morph == nil,
                       "the pirate shows a single source pose at each sample")
            }
            let final = DinoBossAnimation.sample(clip, character: character, elapsed: end)
            expect(final.pose.asset == DinoPirateArtwork.idle && final.height == 0 && final.angle == 0
                   && final.scaleX == 1 && final.scaleY == 1, "the pirate ends each clip in opaque standing idle")
        }
        expect(drawn == DinoPirateArtwork.assets, "all shipped pirate poses are sampled")
        let contact = DinoAnimation.correctAnswerClapContacts
        for elapsed in contact {
            expect(DinoBossAnimation.sample(.thumbsUp, character: character, elapsed: elapsed).pose.asset == "pirate-clap-contact",
                   "the effect occurs during visible palm contact")
        }
        expect(DinoBossAnimation.sample(.thumbsUp, character: character, elapsed: (contact[0] + contact[1]) / 2)
            .pose.asset == "pirate-clap-open", "the palms separate between the two claps")
        expect(Array(DinoBossAnimation.assets(for: .pirouette, character: character).dropFirst().dropLast())
               == DinoPirateArtwork.turnAssets, "the spin follows the measured yaw order")
        let held = DinoAnimation.leadIn(.stumble)
        for elapsed in stride(from: held + DinoAnimation.stumbleLanding + 0.001,
                              to: held + DinoAnimation.stumbleHandRelease, by: 1.0 / 120) {
            let sample = DinoBossAnimation.sample(.stumble, character: character, elapsed: elapsed)
            expect(sample.pose.asset == "pirate-fallen" && sample.pose.offsetY == 0 && sample.pose.offsetX == 0
                   && sample.height == 0 && sample.angle == 0, "both palms stay fixed through the supported phase")
        }
        let opening = DinoWelcomeJump.idleHead(for: character)
        let source = DinoPirateArtwork.headLandmarks[0]
        expect(abs(opening.leftEye.x + source.x - 1) < 1e-6 && opening.leftEye.y == source.y, "the head rig reflects exactly once")
        expect(DinoWelcomeJump.assets(for: character) == ["dino-idle"], "only one full-size opening sprite is prepared")
        for size in [CGSize(width: 402, height: 874), CGSize(width: 1194, height: 834)] {
            let flight = DinoWelcomeFlight(source: CGPoint(x: size.width / 2, y: size.height * 0.54),
                sourceSide: min(size.width, 520), destination: CGRect(x: 90, y: size.height * 0.65, width: 138, height: 138),
                character: character)
            for t in [DinoWelcomeJump.crouchBottom, DinoWelcomeJump.takeoff, DinoWelcomeJump.flightHandoff, DinoWelcomeJump.landing] {
                let before = DinoWelcomeJump.tracking(elapsed: t - 0.00001, flight: flight).head.center
                let after = DinoWelcomeJump.tracking(elapsed: t + 0.00001, flight: flight).head.center
                expect(hypot(before.x - after.x, before.y - after.y) < 0.15, "native launch tracks through each boundary")
            }
            let final = flight.worldTransform(elapsed: DinoWelcomeJump.duration)
            let actual = CGPoint(x: 0.5, y: 0.5).applying(final)
            expect(hypot(actual.x - flight.destination.midX, actual.y - flight.destination.midY) < 0.01,
                   "the opening sprite meets the small map sprite without a translation")
        }
    }

    static func testPirateMattes() {
        let character = DinoIdentity.pirates
        let original = DinoAppearance.standard(for: character)
        let strong = DinoAppearance(bandana: 0xDB40E8, spikes: 0x24CC52, body: 0xFB5C2F, belly: 0x1F6ABC, character: character)
        let document = try! JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: "Documentation/PirateCharacterPrompts.json"))) as! [String: Any]
        let rig = document["poses"] as! [String: [String: Any]]
        func bytes(_ image: CGImage) -> [UInt8] {
            var result = [UInt8](repeating: 0, count: image.width * image.height * 4)
            result.withUnsafeMutableBytes { buffer in
                let context = CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                    bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)!
                context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            }
            return result
        }
        let assets = character.artworkAssets.union([character.openingAsset])
        expect(Set(rig.keys) == assets, "the rig documents every rendered pirate asset")
        for asset in assets.sorted() {
            let url = URL(fileURLWithPath: "Assets.xcassets/\(asset).imageset/\(asset).png")
            let source = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
            let width = source.width
            let matte = DinoSpriteColorRenderer.pirateLabels(source, asset: asset)!
            let tinted = DinoSpriteColorRenderer.recoloredBoss(source, appearance: strong, asset: asset)!
            let head = DinoSpriteColorRenderer.pirateHead(DinoSpriteColorRenderer.facingRight(tinted)!, asset: asset, mirrored: true)!
            let a = bytes(source), b = bytes(tinted), h = bytes(head)
            var alphaValid = true, headValid = true, sole = 0
            var changed = Set<UInt8>()
            for i in matte.indices {
                let offset = i * 4, y = i / width, x = i % width
                let alpha = a[offset + 3], headAlpha = h[(y * width + width - 1 - x) * 4 + 3]
                alphaValid = alphaValid && alpha == b[offset + 3]
                headValid = headValid && headAlpha == (matte[i] & 8 != 0 ? alpha : 0)
                if alpha >= 200 { sole = max(sole, y + 1) }
                if a[offset..<(offset + 3)] != b[offset..<(offset + 3)] { changed.insert(matte[i] & 7) }
            }
            expect(alphaValid && headValid && changed == [1, 2, 3, 4], "\(asset) preserves alpha, paint channels and reflected hat isolation")
            expect(sole == rig[asset]!["footline"] as! Int, "\(asset) matches its registered contact")
            expect(DinoSpriteColorRenderer.recoloredBoss(source, appearance: original, asset: asset) === source,
                   "\(asset) uses the stock pigment at default settings")
            func point(_ position: [Double]) -> Int { Int(position[1]) * width + Int(position[0]) }
            let watch = rig[asset]!["watch"] as! [Double]
            let pivot = point(watch)
            expect(matte[pivot] == 0 && a[pivot * 4 + 3] == 255, "\(asset) has an opaque, protected clock pivot")
            let dialSamples = [[watch[0], watch[1] - watch[3] * 0.55],
                               [watch[0], watch[1] + watch[3] * 0.55],
                               [watch[0] + watch[2] * 0.55, watch[1]]]
            expect(dialSamples.allSatisfy { matte[point($0)] == 0 },
                   "\(asset) keeps the visible dial and the minute hand out of the color channels")
            let finial = point(rig[asset]!["sailBall"] as! [Double])
            expect(matte[finial] == 2, "\(asset) treats the sail finial as metal and keeps it out of the portrait")
            for eye in rig[asset]!["eyes"] as! [[Double]] {
                expect(matte[point(eye)] & 7 == 0, "\(asset) protects the painted pupil")
            }
            for palm in rig[asset]!["palms"] as? [[Double]] ?? [] {
                expect(matte[point(palm)] & 24 == 0, "\(asset) keeps the palms out of both head layers")
            }
            if asset == DinoPirateArtwork.idle {
                for (index, part) in DinoAppearance.Part.allCases.enumerated() {
                    var one = original
                    one[part] = strong[part]
                    let rendered = bytes(DinoSpriteColorRenderer.recoloredBoss(source, appearance: one, asset: asset)!)
                    let materials = Set(matte.indices.compactMap { n -> UInt8? in
                        let i = n * 4
                        return a[i..<(i + 3)] != rendered[i..<(i + 3)] ? matte[n] & 7 : nil
                    })
                    expect(materials == [UInt8(index + 1)], "only the selected pirate material changes")
                }
            }
        }
    }
}

extension DinoCoreTests {
    @MainActor static func testMachineCharacter() {
        let machine = DinoIdentity.machine
        let world = DinoWorldCatalog.world(8)!
        expect(world.themeID == 8 && world.bossLevel == 80 && machine.rawValue == 8 &&
               machine.bossAsset == "boss-time-machine" && DinoIdentity.boss(in: world.id) == machine,
               "Professor Pendulum uses the reserved world-eight save identity and map art")
        var profile = PlayerProfile()
        for earlier in 1...7 {
            profile.recordCompletedAttempt(levelID: earlier * 10, correct: 10)
        }
        expect(profile.collectionCharacters[7] == machine && !profile.selectCharacter(machine),
               "the eighth slot is visible and locked until the regular victory")
        expect(profile.selectCharacter(.valley), "use a different boss as the outgoing actor")
        profile.dinoAppearance?[.body] = 0xD54E3E
        let store = DinoProgressStore(defaults: InMemoryKeyValueStore())
        store.save(profile)

        var random = SeededGenerator(seed: 80)
        @discardableResult
        func finish(_ id: Int, correct: Int, player: DinoPlayer) -> DinoLevelResult {
            let level = DinoLevelCatalog.level(id)!
            let questions = DinoQuestionGenerator.generate(level: level, using: &random)
            var attempt = LevelAttempt(levelID: id, questions: questions)
            for (index, question) in questions.enumerated() {
                _ = attempt.submit(index < correct ? question.expectedAnswer : .duration(-1))
                attempt.advance()
            }
            return player.finish(attempt)!
        }

        let player = DinoPlayer(store: store)
        expect(finish(80, correct: 9, player: player).victory == .none &&
               player.profile.pendingCharacterUnlock == nil && !player.profile.isCharacterUnlocked(machine),
               "nine boss answers alone leave Professor Pendulum locked")
        for lesson in 71...78 { finish(lesson, correct: 5, player: player) }
        expect(finish(79, correct: 5, player: player).hasPendingCharacterUnlock(in: player.profile) &&
               player.profile.activeCharacter == .valley,
               "the final lesson after an earlier boss pass stages the unlock without changing the result actor")
        expect(DinoWorldTransition(after: 8)?.sourceLevel == 80 && DinoWorldTransition(after: 8)?.destinationLevel == 81,
               "the arrival travels from the right boss stone to the first pirate lesson")

        let resumed = DinoPlayer(store: store)
        expect(resumed.profile.pendingCharacterUnlock == machine && resumed.profile.activeCharacter == .valley,
               "a pending victory and its outgoing actor survive an interrupted transition")
        resumed.completeCharacterUnlock()
        expect(resumed.profile.activeCharacter == machine && resumed.profile.pendingCharacterUnlock == nil &&
               resumed.profile.collectionCharacters[7] == .valley && resumed.profile.mapResident(in: 8) == .valley,
               "consuming the arrival activates Pendulum and swaps the actual eighth slot")
        expect(resumed.profile.dinoAppearance?.body == 0xD54E3E &&
               DinoAppearance.standard(for: resumed.profile.mapResident(in: 8)!).body == 0x78C4DF,
               "the map resident keeps its own native palette while the active selection keeps the custom channel")
        resumed.setDinoAppearance(.standard(for: machine))
        expect(resumed.profile.dinoAppearance?.hasOriginalColors == true && resumed.profile.activeCharacter == machine,
               "restoring source colors preserves the identity")
        resumed.selectCharacter(.valley)
        expect(resumed.profile.mapResident(in: 8) == machine && DinoPlayer(store: store).profile == resumed.profile,
               "a manual return of Pendulum to his slot persists")
        finish(80, correct: 10, player: resumed)
        expect(resumed.profile.pendingCharacterUnlock == nil && resumed.profile.activeCharacter == .valley,
               "a replay respects the manual choice")
        resumed.resetProgress()
        let reset = DinoPlayer(store: store).profile
        expect(reset.activeCharacter == .main && reset.pendingCharacterUnlock == nil && reset.characterSlots == nil &&
               reset.collectionCharacters[7] == machine && !reset.isCharacterUnlocked(machine),
               "reset restores the locked slot and removes the saved swap")

        store.save(profile)
        let perfect = DinoPlayer(store: store)
        expect(finish(80, correct: 10, player: perfect).hasPendingCharacterUnlock(in: perfect.profile),
               "a perfect boss victory immediately stages the character")
        expect(DinoWorldTransition(after: DinoWorldCatalog.worlds.last!.id) == nil,
               "final-world completion requests no level beyond the catalog")
        perfect.completeCharacterUnlock()
        expect(perfect.profile.activeCharacter == machine, "direct recovery needs no destination level")

        testMachineMotion()
        testMachineMattes()
    }

    static func testMachineMotion() {
        let machine = DinoIdentity.machine
        let clips: [DinoAnimation.Clip] = [.idle, .thumbsUp, .wrongAnswer, .stumble, .openingJump, .backflip, .pirouette, .worldJump]
        var sampled = Set<String>()
        for clip in clips {
            let end = DinoAnimation.duration(clip)
            for tick in 0...Int(ceil(end * 120)) {
                let frame = DinoBossAnimation.sample(clip, character: machine, elapsed: Double(tick) / 120)
                sampled.insert(frame.pose.asset)
                expect(frame.poseBlend == 1 && frame.previousPose == nil && frame.morph == nil,
                       "\(clip) presents one fully opaque Pendulum pose")
            }
            for reducedMotion in [false, true] {
                let rest = DinoBossAnimation.sample(clip, character: machine, elapsed: end, reducedMotion: reducedMotion)
                expect(rest.pose.asset == DinoMachineArtwork.idle && rest.height == 0 && rest.scaleY == 1 &&
                       rest.scaleX == 1 && rest.angle == 0 && rest.pose.offsetY == 0,
                       "\(clip) settles at precisely the standing anchor")
            }
        }
        expect(sampled == DinoMachineArtwork.assets, "every shipped play pose is actually used")
        for time in DinoAnimation.correctAnswerClapContacts {
            expect(DinoBossAnimation.sample(.thumbsUp, character: machine, elapsed: time).pose.asset == "machine-clap-contact",
                   "both clap effects coincide with a painted palm seam")
        }
        expect(DinoBossAnimation.sample(.thumbsUp, character: machine, elapsed: 0.47).pose.asset == "machine-clap-open",
               "the hands visibly reopen in between")
        expect(Array(DinoBossAnimation.assets(for: .pirouette, character: machine).dropFirst().dropLast()) == DinoMachineArtwork.turnAssets,
               "the turn plays each yaw view once in geometric order")
        let stumbleLead = DinoAnimation.leadIn(.stumble)
        for step in 0..<96 {
            let progress = Double(step) / 96
            let support = stumbleLead + DinoAnimation.stumbleLanding +
                (DinoAnimation.stumbleHandRelease - DinoAnimation.stumbleLanding) * progress
            let sample = DinoBossAnimation.sample(.stumble, character: machine, elapsed: support)
            expect(sample.pose.asset == "machine-brace" && sample.height == 0 && sample.angle == 0 &&
                   sample.scaleX == 1 && sample.scaleY >= 0.955,
                   "the support phase keeps the same palm positions and floor pivot")
        }
        let handoff = DinoWelcomeJump.flightHandoff
        let flight = DinoWelcomeFlight(source: CGPoint(x: 211, y: 394), sourceSide: 351,
                                       destination: CGRect(x: 113, y: 502, width: 140, height: 140), character: machine)
        let tracked = DinoWelcomeJump.tracking(elapsed: handoff - 0.0001, flight: flight)
        let before = tracked.position.applying(flight.worldTransform(elapsed: handoff - 0.0001))
        let after = flight.paintedHead(elapsed: handoff + 0.0001).center
        let centered = CGPoint(x: 0.5, y: 0.5).applying(flight.worldTransform(elapsed: DinoWelcomeJump.duration))
        expect(hypot(before.x - after.x, before.y - after.y) < 0.2 &&
               hypot(centered.x - flight.destination.midX, centered.y - flight.destination.midY) < 0.01,
               "the native takeoff follows the tracked head and lands at the map canvas")
        expect(flight.footline == machine.standingFootline &&
               abs(DinoWelcomeJump.idleHead(for: machine).leftEye.x + DinoMachineArtwork.headLandmarks[0].x - 1) < 0.00001,
               "the measured sole is the pivot and source X is reflected once")
        expect(DinoWelcomeJump.assets(for: machine) == ["dino-idle"] &&
               DinoWelcomeJump.pose(elapsed: handoff, character: machine).asset == "dino-idle",
               "one detailed original slot covers the full native welcome")
    }

    static func testMachineMattes() {
        let url = URL(fileURLWithPath: "Documentation/TimeMachineCharacterPrompts.json")
        let document = try! JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
        let rigs = document["poses"] as! [String: [String: Any]]
        let original = DinoAppearance.standard(for: .machine)
        let edited = DinoAppearance(bandana: 0xD61B4B, spikes: 0x55DF65, body: 0x2196F3, belly: 0xFAD548, character: .machine)
        func rgba(_ image: CGImage) -> [UInt8] {
            var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
            pixels.withUnsafeMutableBytes { buffer in
                let context = CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                                        bitsPerComponent: 8, bytesPerRow: image.width * 4,
                                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                        bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)!
                context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            }
            return pixels
        }

        for asset in DinoMachineArtwork.assets.union([DinoMachineArtwork.openingAsset]) {
            let url = URL(fileURLWithPath: "Assets.xcassets/\(asset).imageset/\(asset).png")
            let source = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
            let labels = DinoSpriteColorRenderer.machineLabels(source, asset: asset)!
            let tinted = DinoSpriteColorRenderer.recoloredBoss(source, appearance: edited, asset: asset)!
            let mirrored = DinoSpriteColorRenderer.facingRight(tinted)!
            let hat = DinoSpriteColorRenderer.machineHead(mirrored, asset: asset, mirrored: true)!
            let a = rgba(source), b = rgba(tinted), c = rgba(hat)
            let width = source.width
            let rig = rigs[asset]!
            var valid = true
            var changed = Set<UInt8>()
            var sole = 0
            var hatPixels = 0
            var lowestHatPixel = 0

            for i in labels.indices {
                let x = i % width, y = i / width, p = i * 4
                let capAlpha = c[(y * width + width - 1 - x) * 4 + 3]
                valid = valid && b[p + 3] == a[p + 3] && capAlpha == (labels[i] & 8 != 0 ? a[p + 3] : 0)
                if a[p + 3] >= 200 { sole = y + 1 }
                if capAlpha > 0 {
                    hatPixels += 1
                    lowestHatPixel = y + 1
                }
                if a[p..<(p + 3)] != b[p..<(p + 3)] { changed.insert(labels[i] & 7) }
            }

            func label(_ point: [Double]) -> UInt8 {
                let x = Int(point[0] * Double(width) / 627), y = Int(point[1] * Double(width) / 627)
                return labels[y * width + x]
            }

            expect(valid && hatPixels > width && !changed.contains(0) && changed.isSuperset(of: [1, 3, 4, 5]),
                   "\(asset) keeps every alpha pixel, mirrors its isolated hat and protects the neutral pixels")
            let hatBounds = rig["hatBounds"] as! [Double]
            expect(abs(Double(lowestHatPixel) * 627 / Double(width) - hatBounds[3]) < 1,
                   "\(asset) keeps its separate hat layer inside the measured brim")
            expect(abs(Double(sole) * 627 / Double(width) - (rig["sole"] as! Double)) < 1,
                   "\(asset) uses its measured sole boundary")
            if asset != "machine-airborne" {
                expect(abs(Double(sole) / Double(width) - DinoMachineArtwork.footline) < 0.005,
                       "\(asset) contacts the common ground plane")
            }
            for dial in rig["dials"] as! [[Double]] {
                expect(label(dial) & 7 == 0, "\(asset) preserves each visible clock face")
            }
            for palm in (rig["palms"] as? [[Double]] ?? []) + ((rig["hand"] as? [Double]).map { [$0] } ?? []) {
                expect(label(palm) & 24 == 0, "\(asset) excludes the hands from the hat and portrait head layers")
            }
            expect(DinoSpriteColorRenderer.recoloredBoss(source, appearance: original, asset: asset) === source,
                   "\(asset) uses the unmodified original RGB when no color is selected")
            if asset == DinoMachineArtwork.idle {
                for (part, expected): (DinoAppearance.Part, Set<UInt8>) in [
                    (.bandana, [1, 2, 7]), (.spikes, [3]), (.body, [4]), (.belly, [5, 6])
                ] {
                    var custom = original
                    custom[part] = edited[part]
                    let pixels = rgba(DinoSpriteColorRenderer.recoloredBoss(source, appearance: custom, asset: asset)!)
                    let materials = Set(labels.indices.compactMap { index -> UInt8? in
                        let rgb = (index * 4)..<(index * 4 + 3)
                        return a[rgb] == pixels[rgb] ? nil : labels[index] & 7
                    })
                    expect(materials == expected, "\(part) only recolors its assigned materials")
                }
            }
        }
    }
}

extension DinoCoreTests {
    @MainActor static func testCastleCharacter() {
        let king = DinoIdentity.castle
        let world = DinoWorldCatalog.world(10)!
        expect(world.themeID == 10 && world.bossKey == "dino.world.10.boss" &&
               king.rawValue == 10 && king.bossAsset == "boss-castle" &&
               king.unlockLevel == world.bossLevel && DinoIdentity.boss(in: world.id) == king,
               "Chronos uses the reserved castle save identity, art and tenth slot")
        var oldProfile = PlayerProfile()
        for world in DinoWorldCatalog.worlds.dropLast() {
            oldProfile.recordCompletedAttempt(levelID: world.bossLevel, correct: 10)
        }
        expect(oldProfile.collectionCharacters[9] == king && !oldProfile.selectCharacter(king),
               "the last resident is locked before completing the castle")
        expect(oldProfile.selectCharacter(.pirates), "use a customized boss as the outgoing character")
        oldProfile.dinoAppearance?[.body] = 0xE94A91
        let store = DinoProgressStore(defaults: InMemoryKeyValueStore())
        store.save(oldProfile)

        var random = SeededGenerator(seed: 100)
        @discardableResult
        func finish(_ id: Int, correct: Int, for player: DinoPlayer) -> DinoLevelResult {
            let level = DinoLevelCatalog.level(id)!
            let questions = DinoQuestionGenerator.generate(level: level, using: &random)
            var attempt = LevelAttempt(levelID: id, questions: questions)
            for (index, question) in questions.enumerated() {
                _ = attempt.submit(index < correct ? question.expectedAnswer : .duration(-1))
                attempt.advance()
            }
            return player.finish(attempt)!
        }

        let player = DinoPlayer(store: store)
        expect(finish(100, correct: 9, for: player).victory == .none &&
               player.profile.pendingCharacterUnlock == nil && !player.profile.isCharacterUnlocked(king),
               "a near-perfect score alone leaves Chronos locked")
        for id in 91...98 { finish(id, correct: 5, for: player) }
        expect(finish(99, correct: 5, for: player).hasPendingCharacterUnlock(in: player.profile) &&
               player.profile.activeCharacter == .pirates && player.profile.mapLevel == 100,
               "the last ordinary lesson can stage the terminal unlock after an earlier boss pass")
        let transition = DinoWorldTransition(after: 10, terminalUnlock: true)
        expect(transition?.sourceLevel == 100 && transition?.destinationLevel == 100 &&
               DinoWorldTransition(after: 10) == nil && DinoLevelCatalog.level(101) == nil,
               "the terminal introduction lands on the final stone without requiring level 101")

        let resumed = DinoPlayer(store: store)
        expect(resumed.profile.pendingCharacterUnlock == king && resumed.profile.activeCharacter == .pirates,
               "closing before the landing saves the pending castle identity and the old result actor")
        resumed.completeCharacterUnlock()
        resumed.completeCharacterUnlock()
        expect(resumed.profile.activeCharacter == king && resumed.profile.pendingCharacterUnlock == nil &&
               resumed.profile.mapResident(in: 10) == .pirates && resumed.profile.collectionCharacters[9] == .pirates,
               "the swap consumes the pending unlock once and places the former actor in slot ten")
        expect(resumed.profile.dinoAppearance?.body == 0xE94A91 &&
               DinoAppearance.standard(for: resumed.profile.mapResident(in: 10)!).body == 0x178FDB,
               "the outgoing map resident has its own default blue skin")
        resumed.setDinoAppearance(.standard(for: king))
        expect(resumed.profile.dinoAppearance?.hasOriginalColors == true && resumed.profile.activeCharacter == king,
               "restoring the castle palette preserves Chronos")
        resumed.selectCharacter(.pirates)
        finish(100, correct: 10, for: resumed)
        expect(resumed.profile.pendingCharacterUnlock == nil && resumed.profile.activeCharacter == .pirates &&
               resumed.profile.collectionCharacters[9] == king && DinoPlayer(store: store).profile == resumed.profile,
               "a manual swap persists and survives a replay of the final boss")
        resumed.resetProgress()
        let reset = DinoPlayer(store: store).profile
        expect(reset.activeCharacter == .main && reset.pendingCharacterUnlock == nil && reset.characterSlots == nil &&
               reset.collectionCharacters[9] == king && !reset.isCharacterUnlocked(king),
               "reset locks the tenth slot and removes the active identity")

        oldProfile.recordCompletedAttempt(levelID: 100, correct: 10)
        store.save(oldProfile)
        let existing = DinoPlayer(store: store)
        expect(existing.profile.isCharacterUnlocked(king) && existing.profile.activeCharacter == .pirates &&
               existing.profile.pendingCharacterUnlock == nil, "earlier finished saves can select Chronos from their existing collection")
        existing.selectCharacter(king)
        expect(DinoPlayer(store: store).profile.activeCharacter == king, "raw value ten is saved and restored")

        testCastleMotion()
        testCastleMattes()
    }

    static func testCastleMotion() {
        let king = DinoIdentity.castle
        let clips: [DinoAnimation.Clip] = [.idle, .thumbsUp, .wrongAnswer, .stumble, .openingJump, .backflip, .pirouette, .worldJump]
        var observed = Set<String>()
        for clip in clips {
            let end = DinoAnimation.duration(clip)
            for tick in 0...Int(ceil(end * 120)) {
                let sample = DinoBossAnimation.sample(clip, character: king, elapsed: Double(tick) / 120)
                observed.insert(sample.pose.asset)
                expect(sample.previousPose == nil && sample.poseBlend == 1 && sample.morph == nil,
                       "\(clip) uses one opaque Chronos pose")
            }
            for reduced in [true, false] {
                let end = DinoBossAnimation.sample(clip, character: king, elapsed: end, reducedMotion: reduced)
                expect(end.pose.asset == DinoCastleArtwork.idle && end.height == 0 && end.angle == 0 &&
                       end.scaleX == 1 && end.scaleY == 1, "\(clip) returns to the same fully planted pose")
            }
        }
        expect(observed == king.artworkAssets, "every Chronos sprite is sampled")
        for time in DinoAnimation.correctAnswerClapContacts {
            expect(DinoBossAnimation.sample(.thumbsUp, character: king, elapsed: time).pose.asset == "castle-clap-contact",
                   "both air ripples appear at visible flipper contact")
        }
        expect(DinoBossAnimation.sample(.thumbsUp, character: king, elapsed: 0.46).pose.asset == "castle-clap-open",
               "flippers visibly part between contacts")
        let palm = DinoCastleArtwork.clapContact
        expect(hypot((palm.x - 0.5) * king.portraitScale + king.portraitOffsetX,
                     (palm.y - 0.5) * king.portraitScale + king.portraitOffsetY) < 0.4,
               "the clap contact falls inside the HUD circle")
        let landing = DinoAnimation.travelDuration(.stumble)
        let push = DinoAnimation.leadIn(.stumble) + DinoAnimation.stumblePushStart
        let release = DinoAnimation.leadIn(.stumble) + DinoAnimation.stumbleHandRelease
        for tick in 0..<48 {
            let t = landing + (release - landing) * Double(tick) / 48
            let sample = DinoBossAnimation.sample(.stumble, character: king, elapsed: t)
            expect(sample.pose.asset == (t < push ? "castle-fallen" : "castle-lift") &&
                   sample.pose.offsetY == 0 && sample.angle == 0,
                   "the weight-bearing flippers stay planted until hand release")
        }
        expect(Array(DinoBossAnimation.assets(for: .pirouette, character: king).dropFirst().dropLast())
               == DinoCastleArtwork.turnAssets, "the turn follows the measured viewing angles")
        expect(DinoWelcomeJump.assets(for: king) == ["dino-idle"], "the welcome uses one high-resolution painting")
        let source = DinoCastleArtwork.headLandmarks[0]
        expect(abs(DinoWelcomeJump.idleHead(for: king).leftEye.x + source.x - 1) < 1e-10,
               "the source iris reflects once")
        let flight = DinoWelcomeFlight(source: CGPoint(x: 205, y: 340), sourceSide: 285,
                                       destination: CGRect(x: 126, y: 550, width: 132, height: 132), character: king)
        let t = DinoWelcomeJump.flightHandoff
        let prior = flight.paintedHead(elapsed: t - 0.0001).center
        let next = flight.paintedHead(elapsed: t + 0.0001).center
        let destination = CGPoint(x: 0.5, y: 0.5).applying(flight.worldTransform(elapsed: DinoWelcomeJump.duration))
        expect(hypot(prior.x - next.x, prior.y - next.y) < 0.2 &&
               hypot(destination.x - flight.destination.midX, destination.y - flight.destination.midY) < 0.01 &&
               flight.footline == king.standingFootline, "welcome head, sole and destination are registered across flight")
    }

    static func testCastleMattes() {
        let king = DinoIdentity.castle
        let path = URL(fileURLWithPath: "Documentation/CastleCharacterPrompts.json")
        let document = try! JSONSerialization.jsonObject(with: Data(contentsOf: path)) as! [String: Any]
        let rigs = document["poses"] as! [String: [String: Any]]
        let original = DinoAppearance.standard(for: king)
        let edited = DinoAppearance(bandana: 0xDF2F54, spikes: 0x4FD254, body: 0xD76B19, belly: 0xA46CF0, character: king)
        func rgba(_ image: CGImage) -> [UInt8] {
            var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
            pixels.withUnsafeMutableBytes { buffer in
                let context = CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                                        bitsPerComponent: 8, bytesPerRow: image.width * 4,
                                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                        bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)!
                context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            }
            return pixels
        }
        expect(Set(rigs.keys) == king.artworkAssets.union([king.openingAsset]), "every final sprite has its own rig measurements")
        for (asset, rig) in rigs {
            let url = URL(fileURLWithPath: "Assets.xcassets/\(asset).imageset/\(asset).png")
            let source = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
            let labels = DinoSpriteColorRenderer.castleLabels(source, asset: asset)!
            let tinted = DinoSpriteColorRenderer.recoloredBoss(source, appearance: edited, asset: asset)!
            let unchanged = DinoSpriteColorRenderer.recoloredBoss(source, appearance: original, asset: asset)!
            let sourcePixels = rgba(source), recoloredPixels = rgba(tinted)
            expect(source === unchanged && source.width == (rig["renderedSize"] as! Int),
                   "original colors preserve the native bitmap and size")
            let mirrored = DinoSpriteColorRenderer.facingRight(tinted)!
            let crown = DinoSpriteColorRenderer.castleHead(mirrored, asset: asset, mirrored: true)!
            let flipped = rgba(mirrored), cap = rgba(crown), w = source.width
            var preserved = true
            var maskMatches = true
            var changed = Set<UInt8>()
            for index in labels.indices {
                let i = index * 4
                let reflected = (index / w * w + w - 1 - index % w) * 4
                let label = labels[index] & 7
                let changedRGB = (0..<3).contains { sourcePixels[i + $0] != recoloredPixels[i + $0] }
                if changedRGB { changed.insert(label) }
                preserved = preserved && sourcePixels[i+3] == recoloredPixels[i+3] &&
                    (!changedRGB || label > 0) && recoloredPixels[i+3] == flipped[reflected+3]
                maskMatches = maskMatches && cap[reflected+3] == (labels[index] & 8 == 0 ? 0 : flipped[reflected+3])
            }
            expect(preserved && maskMatches && changed.isSuperset(of: [1, 2, 3, 4]),
                   "\(asset) preserves source alpha and protected pigments and reflects exactly its painted crown")
            if let dial = rig["dial"] as? [Double], let shift = rig["shift"] as? [Double] {
                let scale = rig["scale"] as! Double
                let x = Int((dial[0] * scale + shift[0]) * Double(w) / 627)
                let y = Int((dial[1] * scale + shift[1]) * Double(w) / 627)
                expect(labels[y*w+x] == 24 && sourcePixels[(y*w+x)*4+3] == 255,
                       "the crown dial hub is completely opaque and protected in \(asset)")
            }
            if asset.hasPrefix("castle-clap-") || asset == "castle-wrong" {
                let landmarks = rig["eyes"] as! [[Double]]
                let shift = rig["shift"] as! [Double]
                let scale = rig["scale"] as! Double
                let excludesEyes = landmarks.allSatisfy {
                    let x = Int(($0[0] * scale + shift[0]) * Double(w) / 627)
                    let y = Int(($0[1] * scale + shift[1]) * Double(w) / 627)
                    return cap[(y*w + w-1-x)*4+3] == 0
                }
                expect(excludesEyes && cap[(w*3/4*w*4)..<cap.count].allSatisfy { $0 == 0 },
                       "no eye, flipper, cape or shoulder can escape the crown layer in \(asset)")
            }
        }
        func registeredContacts(_ name: String) -> [CGPoint] {
            let rig = rigs[name]!
            let shift = rig["shift"] as! [Double], scale = rig["scale"] as! Double
            return (rig["contacts"] as! [[Double]]).map {
                CGPoint(x: $0[0] * scale + shift[0], y: $0[1] * scale + shift[1])
            }
        }
        let support = zip(registeredContacts("castle-fallen"), registeredContacts("castle-lift"))
        expect(support.allSatisfy { hypot($0.0.x - $0.1.x, $0.0.y - $0.1.y) < 5 },
               "both weight-bearing flippers stay registered to the fallen pose")
    }
}
