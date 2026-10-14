import XCTest
import UIKit

/// Real taps through the shipped SwiftUI screens, using only a reproducible RNG.
final class DinoUITests: XCTestCase {
    private var app: XCUIApplication!
    private let seed: UInt64 = 42
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_SEED"] = String(seed)
        app.launchArguments = ["-settings.languageOverride", "nl"]
        app.launch()
    }

    private func tap(_ id: String) {
        let item = app.descendants(matching: .any).matching(identifier: id).firstMatch
        XCTAssertTrue(item.exists || item.waitForExistence(timeout: 6), "Missing \(id)")
        for _ in 0..<6 {
            let next = app.buttons["onboarding.next"]
            let aboveFooter = !id.hasPrefix("personalize.") || !next.exists || item.frame.maxY < next.frame.minY - 8
            let insideScreen = id != "question.confirm" || item.frame.maxY < app.frame.maxY - 16
            if item.isHittable && aboveFooter && insideScreen { break }
            if id == "question.confirm" {
                // Scroll beside an interactive clock, so revealing Confirm cannot move its hands.
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.035, dy: 0.75))
                    .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.035, dy: 0.35)))
            } else { app.swipeUp() }
        }
        item.tap()
    }

    private func onboard(custom: Bool = false) {
        XCTAssertTrue(app.buttons["onboarding.next"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["onboarding.next"].isEnabled)
        XCTAssertFalse(app.textFields["onboarding.name"].exists)
        XCTAssertTrue(app.buttons["personalize.bandana.red"].exists)
        tap("onboarding.next")
        if custom { tap("theme.dino.face.blue") }
        tap(custom ? "onboarding.customClock" : "onboarding.standardClock")
        XCTAssertTrue(app.buttons["map.bossShortcut"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["header.dino"].exists)
    }

    private func openSettings() {
        tap("header.settings")
    }

    private func revealMapNode(_ id: Int) -> XCUIElement {
        let node = app.buttons["map.level.\(id)"]
        for _ in 0..<14 {
            // Keep the entire level circle clear of the sticky HUD and footer.
            let top = app.buttons["header.settings"].frame.maxY + 20
            let frame = node.frame
            // Simulator AX can report contradictory activation points for a
            // visible SwiftUI circle. Geometry plus an actual tap is reliable.
            if node.exists && frame.width > 0 && frame.minY > top && frame.maxY < app.frame.maxY - 16 { break }
            let movingDown = frame.minY <= top
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: movingDown ? 0.45 : 0.72))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: movingDown ? 0.70 : 0.47))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTAssertTrue(node.exists, "Missing node \(id)")
        XCTAssertGreaterThan(node.frame.width, 0)
        XCTAssertGreaterThan(node.frame.minY, app.buttons["header.settings"].frame.maxY + 20)
        XCTAssertLessThan(node.frame.maxY, app.frame.maxY - 16)
        return node
    }

    private func begin(_ id: Int) {
        if id == 10 {
            let shortcut = app.buttons["map.bossShortcut"]
            if shortcut.isHittable { shortcut.tap() }
            else {
                revealMapNode(10).tap()
            }
        }
        else {
            revealMapNode(id).tap()
        }
        tap("level.play")
    }

    func testAllTenBossesHaveClockArtwork() {
        let times = ["08:00", "07:30", "04:45", "05:20", "02:17", "12:45", "20:00", "06:25", "09:30", "10:25"]
        for world in 1...10 {
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.bosses.\(UUID().uuidString)"
            // Keep the jungle fresh; later fixtures center the map on the boss
            // being replayed, avoiding dependence on chapter-header AX grouping.
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = String(world == 1 ? 0 : world)
            app.launch()
            XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 8))
            let node = revealMapNode(world * 10)
            saveScreenshot(world == 1 ? "jungle-guardian-map" : "boss-\(world)-map")
            node.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            let artwork = app.descendants(matching: .any)["level.bossArtwork.\(world)"]
            XCTAssertTrue(artwork.waitForExistence(timeout: 5))
            XCTAssertEqual(artwork.value as? String, times[world - 1])
            XCTAssertGreaterThan(artwork.frame.minY, app.buttons["header.settings"].frame.maxY)
            XCTAssertTrue(app.buttons["level.play"].isEnabled)
            if world == 1 { XCTAssertTrue(app.staticTexts["Tiko de Junglewachter"].exists) }
            saveScreenshot("boss-\(world)-start")
        }
    }

    func testNativeWorldChaptersAndMinuteQuestions() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["map.bossShortcut"].exists)
        saveScreenshot("jungle-native-entrance")
        for completed in 1...9 {
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.worlds.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = String(completed)
            app.launch()
            XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 8))
            let first = completed * 10 + 1
            let node = revealMapNode(first)
            XCTAssertTrue(node.isEnabled)
            XCTAssertGreaterThanOrEqual(node.frame.width, 44)
            XCTAssertTrue(app.descendants(matching: .any)["map.world.\(completed + 1)"].exists)
            XCTAssertFalse(app.buttons["map.bossShortcut.\(completed + 1)"].exists)
            saveScreenshot("native-world-\(completed + 1)")
            node.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(app.buttons["level.play"].waitForExistence(timeout: 5))
            tap("level.play")
            XCTAssertTrue(app.buttons["question.option.0"].waitForExistence(timeout: 5))
            let hudWorld = app.descendants(matching: .any)["header.world"]
            XCTAssertEqual(hudWorld.label, "Wereld \(completed + 1)")
            var rng = SeededGenerator(seed: seed)
            let q = DinoQuestionGenerator.generate(level: DinoLevelCatalog.level(first)!, using: &rng)[0]
            if completed == 1 { XCTAssertEqual(q.target.minute, 30) }
            let option = q.responses.firstIndex(of: q.expectedAnswer)!
            tap("question.option.\(option)")
            XCTAssertTrue(app.staticTexts["2/5"].waitForExistence(timeout: 8))
            XCTAssertEqual(hudWorld.label, "Wereld \(completed + 1)")
            saveScreenshot("native-world-\(completed + 1)-question")
        }
    }

    func testComingSoonOnlyAfterLevelHundred() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "10"
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 8))
        let boss = revealMapNode(100)
        XCTAssertTrue(boss.isEnabled)
        XCTAssertFalse(app.buttons["map.level.101"].exists)
        let footer = app.descendants(matching: .any)["map.comingSoon"]
        for _ in 0..<4 { if footer.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(footer.isHittable)
        XCTAssertTrue(app.staticTexts["Coming soon"].exists)
        XCTAssertGreaterThan(footer.frame.minY, boss.frame.maxY)
        XCTAssertFalse(app.staticTexts["Wereld 2 · binnenkort"].exists)
        saveScreenshot("native-world-10-coming-soon")
    }

    private func openPractice() {
        onboard()
        tap("header.practice")
        XCTAssertTrue(app.buttons["practice.start"].waitForExistence(timeout: 5))
        let times = DinoPracticeTime.allCases.map { app.buttons["practice.time.\($0.rawValue)"] }
        XCTAssertTrue(times.allSatisfy { $0.isHittable })
        XCTAssertTrue(times[0].isSelected)
        XCTAssertEqual(Set(times.map(\.identifier)).count, DinoPracticeTime.allCases.count)
        for index in 0..<6 {
            XCTAssertEqual(times[index].frame.midY, times[index < 3 ? 0 : 3].frame.midY, accuracy: 1, "Time types have two rows")
            XCTAssertEqual(times[index].frame.midX, times[index % 3].frame.midX, accuracy: 1, "Time types have three columns")
        }
        XCTAssertGreaterThan(times[3].frame.minY, times[0].frame.maxY)
        XCTAssertFalse(app.buttons["practice.type.chooseAnalog2"].exists)
        XCTAssertFalse(app.buttons["practice.type.chooseDigital4"].exists)
        saveScreenshot("practice-grid-and-types")
    }

    private func answerFirstQuestionWrong(_ levelID: Int, advance: Bool = false) {
        var rng = SeededGenerator(seed: seed)
        let level = DinoLevelCatalog.level(levelID)!
        let first = DinoQuestionGenerator.generate(level: level, using: &rng)[0]
        tap("question.option.\(first.options.firstIndex { $0 != first.target }!)")
        XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
        if advance {
            tap("question.next")
            XCTAssertTrue(app.staticTexts["2/\(level.questionCount)"].waitForExistence(timeout: 5))
        }
    }

    func testHUDThemeFollowsScrollInsteadOfPlayerLevel() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "90"
        app.launch()
        let world = app.descendants(matching: .any)["header.world"]
        let level = app.descendants(matching: .any)["header.level"]
        XCTAssertTrue(world.waitForExistence(timeout: 8))
        let restoredWorld = NSPredicate { _, _ in world.label == "Wereld 9" }
        expectation(for: restoredWorld, evaluatedWith: nil)
        waitForExpectations(timeout: 8)
        XCTAssertEqual(level.label, "Level 90")
        saveScreenshot("hud-world-9-level-90")

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.04)).tap()
        for _ in 0..<45 {
            if world.label == "Wereld 1" { break }
            app.swipeDown(velocity: .fast)
        }
        XCTAssertEqual(world.label, "Wereld 1")
        XCTAssertEqual(level.label, "Level 90")
        // Finish revealing the top, rather than capturing the preceding transition.
        app.swipeDown(velocity: .fast)
        saveScreenshot("hud-world-1-level-90")

        for _ in 0..<14 {
            if world.label == "Wereld 2" { break }
            app.swipeUp(velocity: .slow)
        }
        XCTAssertEqual(world.label, "Wereld 2")
        XCTAssertEqual(level.label, "Level 90")
        saveScreenshot("hud-world-2-level-90")
        for _ in 0..<10 {
            if world.label == "Wereld 1" { break }
            app.swipeDown()
        }
        XCTAssertEqual(world.label, "Wereld 1")
        XCTAssertEqual(level.label, "Level 90")
    }

    func testContextualHUDAndFirstQuestionExit() {
        onboard()
        let ids = ["header.level", "header.stars", "header.practice", "header.settings"]
        let cards = ids.map { app.descendants(matching: .any)[$0] }
        for card in cards {
            XCTAssertEqual(card.frame.height, cards[0].frame.height, accuracy: 1)
            XCTAssertEqual(card.frame.midY, cards[0].frame.midY, accuracy: 1)
            XCTAssertGreaterThanOrEqual(card.frame.width, 44)
        }
        for (left, right) in zip(cards, cards.dropFirst()) { XCTAssertLessThan(left.frame.maxX, right.frame.minX) }
        saveScreenshot("hud-map-practice")
        tap("header.practice")
        XCTAssertTrue(app.buttons["practice.start"].waitForExistence(timeout: 5))
        tap("practice.close")
        openSettings()
        XCTAssertFalse(app.buttons["settings.practice"].exists)
        app.buttons["Klaar"].firstMatch.tap()
        begin(1)
        XCTAssertTrue(app.buttons["header.pause"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["header.questions"].exists)
        XCTAssertEqual(app.descendants(matching: .any)["header.questions"].label, "Vraag")
        XCTAssertFalse(app.descendants(matching: .any)["header.stars"].exists)
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", "1/5")).count, 1)
        let questionCard = app.descendants(matching: .any)["header.questions"]
        let example = app.buttons["question.example"]
        let pause = app.buttons["header.pause"]
        XCTAssertLessThan(questionCard.frame.maxX, example.frame.minX)
        XCTAssertLessThan(example.frame.maxX, pause.frame.minX)
        XCTAssertEqual(questionCard.frame.height, pause.frame.height, accuracy: 1)
        XCTAssertEqual(example.frame.height, pause.frame.height, accuracy: 1)
        saveScreenshot("hud-game-questions")
        tap("question.example")
        XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 5))
        tap("demo.ready")
        tap("header.pause")
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["game.exit.confirm"].exists)
        begin(1)
        answerFirstQuestionWrong(1)
        tap("header.pause")
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["game.exit.confirm"].exists)
        begin(1)
        answerFirstQuestionWrong(1, advance: true)
        tap("header.pause")
        XCTAssertTrue(app.buttons["game.exit.cancel"].waitForExistence(timeout: 5))
        saveScreenshot("hud-later-question-exit")
        tap("game.exit.cancel")
        XCTAssertTrue(app.staticTexts["2/5"].exists)
        tap("header.pause"); tap("game.exit.confirm")
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 5))
    }

    func testFullResetClosesAndRestartsWelcome() {
        onboard(custom: true)
        tap("header.dino")
        tap("personalize.bandana.blue"); tap("personalize.spikes.purple")
        tap("personalize.done")
        begin(1); play(1, correct: 5); tap("result.map")
        openSettings()
        tap("settings.soundEffects"); tap("settings.haptics")
        tap("settings.highContrast"); tap("settings.icloudSync")
        for _ in 0..<6 { if app.buttons["language.picker"].isHittable { break }; app.swipeDown() }
        tap("language.picker"); tap("language.option.en")
        tap("settings.reset")
        XCTAssertTrue(app.buttons["settings.reset.confirm"].waitForExistence(timeout: 5))
        saveScreenshot("reset-all-data-confirmation")
        tap("settings.reset.confirm")
        let closed = NSPredicate { _, _ in self.app.state == .notRunning }
        expectation(for: closed, evaluatedWith: nil)
        waitForExpectations(timeout: 8)
        app.launch()
        XCTAssertTrue(app.buttons["onboarding.next"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["personalize.bandana.red"].isSelected)
        XCTAssertTrue(app.buttons["personalize.spikes.darkGreen"].isSelected)
        saveScreenshot("reset-fresh-welcome")
        tap("onboarding.next"); tap("onboarding.standardClock")
        XCTAssertEqual(app.descendants(matching: .any)["header.stars"].label, "0 sterren")
        XCTAssertEqual(app.descendants(matching: .any)["header.level"].label, "Level 1")
        openSettings()
        for (id, value) in [("soundEffects", "1"), ("haptics", "1"), ("highContrast", "0"), ("icloudSync", "0")] {
            XCTAssertEqual(app.switches["settings.\(id)"].value as? String, value)
        }
        tap("settings.clocks")
        XCTAssertTrue(app.buttons["theme.dino.face.white"].isSelected)
    }

    private func selectPractice(_ id: String) {
        let option = app.buttons[id]
        let start = app.buttons["practice.start"]
        let scroll = app.scrollViews["practice.options"]
        for _ in 0..<16 {
            let top = scroll.frame.minY + 8
            let bottom = min(scroll.frame.maxY, start.frame.minY) - 8
            let frame = option.exists ? option.frame : .zero
            if option.exists && option.isHittable && frame.minY >= top && frame.maxY <= bottom { break }
            let movingDown = option.exists && frame.minY < top
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: movingDown ? 0.35 : 0.70))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: movingDown ? 0.65 : 0.40)),
                       withVelocity: .slow, thenHoldForDuration: 0.05)
        }
        option.tap()
        if id == "practice.order.ascending" { app.alerts.buttons["Klaar"].tap() }
        XCTAssertTrue(option.isSelected, "Practice choice was selected above the fixed start button")
    }

    func testPracticeOpenAndScrollPerformance() {
        onboard()
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        measure(metrics: [XCTClockMetric()], options: options) {
            tap("header.practice")
            XCTAssertTrue(app.buttons["practice.start"].waitForExistence(timeout: 5))
            for _ in 0..<3 { app.swipeUp() }
            for _ in 0..<3 { app.swipeDown() }
            tap("practice.close")
        }
    }

    func testPracticeHUDRecordsAndPersistentCounter() {
        openPractice()
        XCTAssertFalse(app.staticTexts["Van makkelijk naar moeilijk"].exists)
        selectPractice("practice.type.chooseAnalog")
        XCTAssertEqual(app.buttons["practice.type.chooseAnalog"].value as? String, "Hoogste reeks: 0")
        saveScreenshot("practice-update-overview")
        tap("practice.start")
        XCTAssertTrue(app.descendants(matching: .any)["header.dino"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["header.streak"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["header.questions"].exists)
        XCTAssertEqual(app.descendants(matching: .any)["header.questions"].label, "Vraag")
        XCTAssertEqual(app.descendants(matching: .any)["practice.hudSubtitle"].label, "1 · Hele uren")
        XCTAssertFalse(app.descendants(matching: .any)["practice.currentType"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["header.level"].isHittable)
        XCTAssertEqual(app.staticTexts["practice.streak"].label, "0")
        saveScreenshot("practice-hud-larger-trophy-initial")
        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.chooseAnalog)), seed: seed)
        for index in 0..<2 {
            let question = generator.next(index: index)
            tap("question.option.\(question.responses.firstIndex(of: question.expectedAnswer)!)")
            let next = app.staticTexts.matching(identifier: "practice.questionNumber")
                .matching(NSPredicate(format: "label == %@", String(index + 2))).firstMatch
            XCTAssertTrue(next.waitForExistence(timeout: 6))
            XCTAssertEqual(app.staticTexts["practice.streak"].label, String(index + 1))
            XCTAssertEqual(app.descendants(matching: .any)["practice.bestStreak"].value as? String, String(index + 1))
        }
        saveScreenshot("practice-update-hud-record")
        saveScreenshot("practice-hud-larger-trophy-record")
        tap("header.pause")
        XCTAssertTrue(app.buttons["practice.start"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["game.exit.confirm"].exists)
        tap("practice.start")
        XCTAssertEqual(app.staticTexts["practice.streak"].label, "2")
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "3")
        saveScreenshot("practice-followup-resumed-streak")
        // A reopened session has a fresh deterministic generator, with saved counters and streak.
        generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.chooseAnalog)), seed: seed)
        let wrongQuestion = generator.next(index: 0)
        answerPracticeWrong(wrongQuestion)
        XCTAssertFalse(app.buttons["question.example"].isEnabled)
        saveScreenshot("practice-followup-feedback-hud")
        XCTAssertEqual(app.staticTexts["practice.streak"].label, "2", "Feedback keeps the streak and question counters together")
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "3")
        XCTAssertEqual(app.descendants(matching: .any)["practice.bestStreak"].value as? String, "2")
        RunLoop.current.run(until: Date().addingTimeInterval(1))
        XCTAssertEqual(app.staticTexts["practice.streak"].label, "2")
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "3")
        saveScreenshot("practice-hud-feedback-counters-held")
        tap("question.next")
        XCTAssertEqual(app.staticTexts["practice.streak"].label, "0")
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "4")
        saveScreenshot("practice-hud-counters-advanced-together")
        tap("header.pause")
        XCTAssertEqual(app.buttons["practice.type.chooseAnalog"].value as? String, "Hoogste reeks: 2")
        tap("practice.time.half")
        XCTAssertEqual(app.buttons["practice.type.chooseAnalog"].value as? String, "Hoogste reeks: 0")
        tap("practice.close")
        app.terminate(); app.launch()
        tap("header.practice")
        selectPractice("practice.type.chooseAnalog")
        tap("practice.start")
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "4")
        XCTAssertEqual(app.staticTexts["practice.streak"].label, "0")
        XCTAssertEqual(app.descendants(matching: .any)["practice.bestStreak"].value as? String, "2")
        saveScreenshot("practice-update-hud-resumed")
        // Relaunch creates another generator with the fixed test seed.
        var restartedGenerator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.chooseAnalog)), seed: seed)
        let restartedQuestion = restartedGenerator.next(index: 0)
        tap("question.option.\(restartedQuestion.responses.firstIndex(of: restartedQuestion.expectedAnswer)!)")
        XCTAssertTrue(app.staticTexts.matching(identifier: "practice.questionNumber").matching(NSPredicate(format: "label == %@", "5")).firstMatch.waitForExistence(timeout: 6))
        XCTAssertEqual(app.staticTexts["practice.streak"].label, "1")
        tap("header.pause")
        tap("practice.close")
        app.terminate(); app.launch()
        tap("header.practice")
        selectPractice("practice.type.chooseAnalog")
        tap("practice.start")
        XCTAssertEqual(app.staticTexts["practice.streak"].label, "1")
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "5")
        saveScreenshot("practice-followup-streak-after-relaunch")
    }

    func testPracticeHUDSubtitleModes() {
        openPractice()
        tap("practice.start")
        XCTAssertEqual(app.descendants(matching: .any)["practice.hudSubtitle"].label, "Oplopend · Hele uren")
        XCTAssertGreaterThan(app.descendants(matching: .any)["practice.hudSubtitle"].frame.minY, app.buttons["header.pause"].frame.midY)
        saveScreenshot("practice-followup-ascending-subtitle")
        tap("header.pause")
        XCTAssertTrue(app.buttons["practice.start"].waitForExistence(timeout: 5))
        selectPractice("practice.order.mix")
        tap("practice.start")
        XCTAssertEqual(app.descendants(matching: .any)["practice.hudSubtitle"].label, "Mix van alle vraagtypen · Hele uren")
        saveScreenshot("practice-followup-mix-subtitle")
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.buttons["header.pause"].waitForExistence(timeout: 5))
        XCTAssertLessThan(app.descendants(matching: .any)["practice.hudSubtitle"].frame.maxY, app.staticTexts["question.title"].frame.minY)
        saveScreenshot("practice-followup-mix-landscape")
        XCUIDevice.shared.orientation = .portrait
        tap("header.pause")
        XCTAssertFalse(app.buttons["game.exit.confirm"].exists)
    }

    func testPracticeThousandCounterAndAscendingPopup() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_PRACTICE_ANSWERS"] = "998"
        app.launch()
        openPractice()
        selectPractice("practice.order.ascending")
        tap("practice.ascending.info")
        XCTAssertTrue(app.alerts.staticTexts["Alle vraagtypen van makkelijk naar moeilijk, daarna opnieuw."].exists)
        app.alerts.buttons["Klaar"].tap()
        XCTAssertFalse(app.staticTexts["Alle vraagtypen van makkelijk naar moeilijk, daarna opnieuw."].exists)
        // Return to the top through the long, lazily loaded list.
        for _ in 0..<6 { app.scrollViews["practice.options"].swipeDown() }
        selectPractice("practice.type.chooseAnalog")
        tap("practice.start")
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "999")
        XCTAssertFalse(app.descendants(matching: .any)["practice.questionThousands"].exists)
        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.chooseAnalog)), seed: seed)
        answerPracticeWrong(generator.next(index: 0))
        tap("question.next")
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "0")
        XCTAssertEqual(app.descendants(matching: .any)["practice.questionThousands"].label, "1k")
        saveScreenshot("practice-update-hud-thousand")
    }

    func testPracticeSelectionAndEndlessDigitalMinutes() {
        openPractice()
        tap("practice.time.half")
        saveScreenshot("practice-time-and-types")
        selectPractice("practice.type.setDigital")
        saveScreenshot("practice-order-choices")
        tap("practice.start")
        XCTAssertFalse(app.buttons["demo.ready"].exists)
        tap("clock.minute.more")
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "12:30")).firstMatch.exists
                      || app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "01:30")).firstMatch.exists)
        saveScreenshot("practice-digital-minutes")
        for index in 0..<12 {
            XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "\(index + 1)")
            XCTAssertTrue(app.buttons["clock.minute.more"].exists)
            // Initial hours deliberately differ, so this tests feedback and Next indefinitely.
            tap("question.confirm")
            XCTAssertTrue(app.descendants(matching: .any)["question.correctClock"].waitForExistence(timeout: 4))
            if index == 0 { saveScreenshot("practice-digital-comparison") }
            tap("question.next")
            XCTAssertTrue(app.staticTexts["practice.questionNumber"].waitForExistence(timeout: 4))
        }
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "13")
        XCTAssertFalse(app.buttons["result.map"].exists)
        tap("header.pause")
        XCTAssertTrue(app.buttons["practice.start"].waitForExistence(timeout: 5))
    }

    func testNumberedExamplesAdvanceWholeHours() {
        onboard()
        begin(1)
        XCTAssertTrue(app.staticTexts["question.title"].waitForExistence(timeout: 5))
        // Let the start-card transition finish before tapping the incoming HUD.
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        let target = app.descendants(matching: .any)["question.targetClock"]
        let originalTarget = target.label
        tap("question.example")
        XCTAssertTrue(app.buttons["demo.nextExample"].waitForExistence(timeout: 5))
        let digital = app.descendants(matching: .any)["demo.digital"]
        let analog = app.descendants(matching: .any).matching(identifier: "demo.analog").firstMatch
        XCTAssertEqual(digital.label, "03:00")
        XCTAssertEqual(analog.value as? String, "03:00")
        XCTAssertLessThan(app.buttons["demo.ready"].frame.maxY, app.buttons["demo.nextExample"].frame.minY)
        XCTAssertEqual(analog.frame.midX, digital.frame.midX, accuracy: 1)
        XCTAssertFalse(app.staticTexts["1 · Uren"].exists)
        XCTAssertFalse(app.staticTexts["2 · Minuten"].exists)
        XCTAssertFalse(app.staticTexts["Deze klokken tonen dezelfde tijd. Tik om te kiezen."].exists)
        saveScreenshot("numbered-example-three")
        for hour in 4...12 {
            tap("demo.nextExample")
            let expected = String(format: "%02d:00", hour)
            XCTAssertEqual(digital.label, expected)
            XCTAssertEqual(analog.value as? String, expected)
            if hour == 6 || hour == 12 { saveScreenshot("numbered-example-\(hour)") }
        }
        tap("demo.nextExample")
        XCTAssertEqual(digital.label, "01:00")
        tap("demo.ready")
        XCTAssertEqual(target.label, originalTarget, "Refreshing examples preserves the live question")
    }

    func testExamplesRetainPracticeTimeFamily() {
        openPractice()
        selectPractice("practice.type.chooseDigital")
        let families: [(String, [String])] = [
            ("half", ["03:30", "04:30", "05:30"]),
            ("quarter", ["03:15", "03:45", "04:15"]),
            ("tenMinutes", ["03:10", "03:20", "03:30"]),
            ("fiveMinutes", ["03:05", "03:10", "03:15"]),
            ("mix", ["03:00", "03:05", "03:10"])
        ]
        for (family, examples) in families {
            chooseExampleTimeFamily(family)
            tap("practice.start")
            tap("question.example")
            XCTAssertTrue(app.buttons["demo.nextExample"].waitForExistence(timeout: 5))
            let digital = app.descendants(matching: .any)["demo.digital"]
            XCTAssertEqual(digital.label, examples[0])
            saveScreenshot("numbered-example-\(family)")
            for expected in examples.dropFirst() {
                tap("demo.nextExample")
                XCTAssertEqual(digital.label, expected)
            }
            tap("demo.ready")
            XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "1")
            tap("header.pause")
            XCTAssertTrue(app.buttons["practice.start"].waitForExistence(timeout: 5))
        }
    }

    func testExpandedExamplesRefreshTheirQuestionAndAnswer() {
        openPractice()
        tap("practice.time.quarter")
        selectPractice("practice.type.read24Hour")
        tap("practice.start")
        tap("question.example")
        XCTAssertTrue(app.buttons["demo.nextExample"].waitForExistence(timeout: 5))
        let target = app.descendants(matching: .any).matching(identifier: "demo.targetClock").firstMatch
        let answer = app.descendants(matching: .any).matching(identifier: "demo.answer").firstMatch
        XCTAssertEqual(target.label, "03:15")
        XCTAssertTrue(answer.label.contains("kwart over drie"))
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option.")).count, 0)
        tap("demo.nextExample")
        XCTAssertEqual(target.label, "03:45")
        XCTAssertTrue(answer.label.contains("kwart voor vier"))
        tap("demo.ready")
        tap("header.pause")
        chooseExampleTimeFamily("half")
        selectPractice("practice.type.timeZone")
        tap("practice.start")
        tap("question.example")
        XCTAssertTrue(app.buttons["demo.nextExample"].waitForExistence(timeout: 5))
        let q = DinoDemonstrationExamples.question(kind: .timeZone, minutes: [30], minuteStep: 30, index: 0, previousTarget: nil)
        XCTAssertEqual(answer.label, q.target.digitalText)
        tap("demo.nextExample")
        let next = DinoDemonstrationExamples.question(kind: .timeZone, minutes: [30], minuteStep: 30, index: 1, previousTarget: q.target)
        XCTAssertEqual(answer.label, next.target.digitalText)
        XCTAssertNotEqual(answer.label, q.target.digitalText)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option.")).count, 0)
        XCTAssertFalse(app.staticTexts["demo.explanation"].exists)
        saveScreenshot("refreshed-time-zone-example")
        tap("demo.ready")
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "1", "Examples do not count as practice answers")
    }

    func testExpandedMultipleChoiceExamplesShowOneAnswer() {
        openPractice()
        tap("practice.time.half")
        let types = DinoPracticeQuestion.allCases.filter { $0.recipe.kind.isExpanded && $0.recipe.kind.usesOptions }
        for type in types {
            selectPractice("practice.type.\(type.rawValue)")
            tap("practice.start")
            tap("question.example")
            XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 5))
            let answers = app.descendants(matching: .any).matching(identifier: "demo.answer")
            XCTAssertEqual(answers.count, 1, "\(type) shows one worked answer")
            XCTAssertFalse(answers.firstMatch.label.isEmpty)
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option.")).count, 0,
                           "\(type) has no distractors in its example")
            XCTAssertFalse(app.staticTexts["demo.explanation"].exists)
            if type == .spokenTime {
                XCTAssertEqual(answers.firstMatch.label, "03:30")
                saveScreenshot("simple-spoken-time-example")
                tap("demo.nextExample")
                XCTAssertEqual(answers.firstMatch.label, "04:30")
            }
            if type == .elapsedTime { saveScreenshot("simple-duration-example") }
            tap("demo.ready")
            let choices = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option."))
            XCTAssertTrue(choices.firstMatch.waitForExistence(timeout: 5))
            XCTAssertGreaterThan(choices.count, 1, "The live \(type) question keeps its normal answer choices")
            XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "1")
            tap("header.pause")
            XCTAssertTrue(app.buttons["practice.start"].waitForExistence(timeout: 5))
        }
    }

    private func chooseExampleTimeFamily(_ family: String) {
        let option = app.buttons["practice.time.\(family)"]
        for _ in 0..<12 {
            if option.exists && option.isHittable { break }
            app.scrollViews["practice.options"].swipeDown()
        }
        tap("practice.time.\(family)")
    }

    func testPracticeAnalogHandsAndManualExample() {
        openPractice()
        tap("practice.time.half")
        selectPractice("practice.type.setAnalog")
        tap("practice.start")
        tap("question.example")
        XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.images["dino.character"].exists)
        saveScreenshot("practice-example-without-dino")
        tap("demo.ready")
        app.buttons["Minuten"].tap()
        let clock = app.descendants(matching: .any)["question.analogControl"]
        clock.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: clock.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.84)))
        XCTAssertTrue((clock.value as? String)?.hasSuffix(":30") == true, "The minute hand is draggable")
        saveScreenshot("practice-analog-minutes")
        app.buttons["Uren"].tap()
        let config = DinoPracticeConfiguration(time: .half, order: .specific(.setAnalog))
        var generator = DinoPracticeGenerator(configuration: config, seed: seed)
        let target = generator.next(index: 0).target
        let radians = target.hourAngle * .pi / 180
        clock.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: clock.coordinate(withNormalizedOffset: CGVector(dx: 0.5 + sin(radians) * 0.25, dy: 0.5 - cos(radians) * 0.25)))
        XCTAssertEqual(clock.value as? String, target.digitalText)
        tap("question.confirm")
        XCTAssertTrue(app.staticTexts.matching(identifier: "practice.questionNumber").matching(NSPredicate(format: "label == %@", "2")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["demo.ready"].exists)
        tap("header.pause")
    }

    private func answerPracticeWrong(_ question: ClockQuestion) {
        switch question.kind {
        case .sortTimes:
            let reversed = question.options.sorted { $0.minutesOfDay > $1.minutesOfDay }
            for time in reversed { tap("question.sort.\(question.options.firstIndex(of: time)!)") }
            tap("question.confirm")
            XCTAssertTrue(app.staticTexts["Goede volgorde"].waitForExistence(timeout: 5))
        case .pairClocks:
            for index in question.relatedTimes.indices {
                tap("question.pair.\(index)")
                let wrong = question.relatedTimes[(index + 1) % 4]
                tap("question.pairChoice.\(index).\(wrong.hour).\(wrong.minute)")
            }
            tap("question.confirm")
        case .advanceAnalog, .setAnalog, .setDigital:
            tap("question.confirm")
        default:
            let options = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option."))
            XCTAssertEqual(options.count, question.responses.count)
            tap("question.option.\(question.responses.firstIndex { $0 != question.expectedAnswer }!)")
        }
        XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
    }

    func testPracticeAscendingAndMixCoverAllTypes() {
        openPractice()
        tap("practice.time.mix")
        selectPractice("practice.order.ascending")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .mix, order: .ascending), seed: seed)
        for index in 0...DinoPracticeQuestion.allCases.count {
            let question = generator.next(index: index)
            let expectedNumber = String(index / DinoPracticeQuestion.allCases.count + 1)
            XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, expectedNumber)
            if question.kind.isExpanded {
                tap("question.example")
                XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 5))
                XCTAssertFalse(app.images["dino.character"].exists)
                tap("demo.ready")
                XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, expectedNumber, "Example preserves the actual question")
            }
            answerPracticeWrong(question)
            if [.pairClocks, .sortTimes, .advanceAnalog, .timeZone, .read24Hour, .timeSequence].contains(question.kind) {
                saveScreenshot("practice-expanded-\(question.kind.rawValue)")
            }
            tap("question.next")
        }
        tap("header.pause")
        selectPractice("practice.order.mix")
        tap("practice.start")
        generator = DinoPracticeGenerator(configuration: .init(time: .mix, order: .mix), seed: seed)
        for index in 0..<DinoPracticeQuestion.allCases.count {
            let question = generator.next(index: index)
            answerPracticeWrong(question)
            tap("question.next")
        }
        tap("header.pause")
    }

    func testExpandedPracticeExamplesAndBoards() {
        openPractice()
        tap("practice.time.quarter")
        selectPractice("practice.type.pairClocks")
        tap("practice.start")
        XCTAssertFalse(app.buttons["demo.ready"].exists)
        tap("question.example")
        XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.images["dino.character"].exists)
        tap("demo.ready")
        var generator = DinoPracticeGenerator(configuration: .init(time: .quarter, order: .specific(.pairClocks)), seed: seed)
        let question = generator.next(index: 0)
        for index in question.relatedTimes.indices {
            tap("question.pair.\(index)")
            let correct = question.relatedTimes[index]
            tap("question.pairChoice.\(index).\(correct.hour).\(correct.minute)")
        }
        saveScreenshot("practice-expanded-pairs-ready")
        tap("question.confirm")
        XCTAssertTrue(app.staticTexts["practice.questionNumber"].waitForExistence(timeout: 5))
        tap("header.pause")
        selectPractice("practice.type.sortTimes")
        tap("practice.start")
        generator = DinoPracticeGenerator(configuration: .init(time: .quarter, order: .specific(.sortTimes)), seed: seed)
        let sorting = generator.next(index: 0)
        for time in sorting.options.sorted(by: { $0.minutesOfDay < $1.minutesOfDay }) {
            tap("question.sort.\(sorting.options.firstIndex(of: time)!)")
        }
        saveScreenshot("practice-expanded-sorting-ready")
        tap("question.confirm")
        XCTAssertTrue(app.staticTexts["practice.questionNumber"].waitForExistence(timeout: 5))
        tap("header.pause")
    }

    func testManualExamplesAndClockComparison() {
        onboard()
        begin(10)
        XCTAssertFalse(app.buttons["demo.ready"].exists)
        tap("question.example")
        XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 3))
        saveScreenshot("manual-example-centered")
        XCTAssertFalse(app.images["dino.character"].exists, "Example has no companion")
        tap("demo.ready")
        var rng = SeededGenerator(seed: seed)
        let questions = DinoQuestionGenerator.generate(level: DinoLevelCatalog.level(10)!, using: &rng)
        for question in questions {
            if question.kind == .setAnalog || question.kind == .setDigital {
                // The next question always initializes to a different hour than its target.
                tap("question.confirm")
                XCTAssertTrue(app.descendants(matching: .any)["question.correctClock"].waitForExistence(timeout: 4))
                XCTAssertTrue(app.staticTexts["Jouw antwoord"].exists)
                XCTAssertFalse(app.descendants(matching: .any)["question.feedback"].exists)
                saveScreenshot(question.kind == .setAnalog ? "analog-answer-comparison" : "digital-answer-comparison")
                tap("question.next")
            } else {
                tap("question.option.\(question.options.firstIndex(of: question.target)!)")
            }
            if question.id < questions.count - 1 {
                XCTAssertTrue(app.staticTexts["\(question.id + 2)/10"].waitForExistence(timeout: 5))
            }
        }
    }

    func testLevelFriendsRowsWithTimings() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_SOCIAL"] = "fixtures"
        app.launch()
        onboard()
        revealMapNode(1).tap()
        XCTAssertTrue(app.buttons["level.friend.test-0"].waitForExistence(timeout: 5))
        saveScreenshot("friends-level-timing-rows")
        XCTAssertTrue(app.buttons["level.friend.test-0"].label.contains("0:20"))
        XCTAssertTrue(app.buttons["level.friend.test-1"].label.contains("0:35"))
        let orderedIDs = ["test-0", "test-3", "test-1", "test-4", "test-2"]
        for (first, next) in zip(orderedIDs, orderedIDs.dropFirst()) {
            XCTAssertLessThan(app.buttons["level.friend.\(first)"].frame.minY,
                              app.buttons["level.friend.\(next)"].frame.minY,
                              "Most stars first; equal stars use the shortest time")
        }
        XCTAssertLessThan(app.buttons["level.friend.test-2"].frame.minY,
                          app.staticTexts["level.ownName"].frame.minY,
                          "The player's unplayed result also participates in the ranking")
        tap("level.friend.test-0")
        XCTAssertTrue(app.buttons["friend.close"].waitForExistence(timeout: 5))
        tap("friend.close")
        XCTAssertTrue(app.buttons["level.play"].waitForExistence(timeout: 5))
    }

    func testWelcomeDinoAndGameCenterIdentity() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_SOCIAL"] = "fixtures"
        app.launch()
        XCTAssertTrue(app.buttons["onboarding.next"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Maak jouw dino"].exists)
        XCTAssertEqual(app.textFields.count, 0)
        XCTAssertFalse(app.staticTexts["Game Center Sam"].exists)
        for (part, color) in [("bandana", "blue"), ("spikes", "purple"), ("body", "pink"), ("belly", "orange")] {
            tap("personalize.\(part).\(color)")
            XCTAssertTrue(app.buttons["personalize.\(part).\(color)"].isSelected)
        }
        Thread.sleep(forTimeInterval: 0.75)
        saveScreenshot("welcome-dino-colors")
        XCTAssertTrue(app.buttons["onboarding.next"].isHittable)
        tap("onboarding.next")
        tap("onboarding.standardClock")
        XCTAssertTrue(app.buttons["header.dino"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["header.dino"].label, "Mijn dino")
        XCTAssertGreaterThanOrEqual(app.buttons["header.dino"].frame.height, 82)
        let headerLevel = app.descendants(matching: .any)["header.level"]
        let headerStars = app.descendants(matching: .any)["header.stars"]
        XCTAssertLessThan(headerLevel.frame.height, app.buttons["header.dino"].frame.height)
        XCTAssertEqual(headerLevel.frame.midY, headerStars.frame.midY, accuracy: 1)
        XCTAssertGreaterThanOrEqual(app.buttons["header.settings"].frame.width, 44)
        XCTAssertEqual(headerLevel.frame.height, app.buttons["header.settings"].frame.height, accuracy: 1)
        XCTAssertFalse(app.staticTexts["Game Center Sam"].exists)
        saveScreenshot("hud-dino-no-name")
        tap("header.dino")
        for (part, color) in [("bandana", "blue"), ("spikes", "purple"), ("body", "pink"), ("belly", "orange")] {
            XCTAssertTrue(app.buttons["personalize.\(part).\(color)"].isSelected)
        }
        XCTAssertEqual(app.textFields.count, 0)
        XCTAssertFalse(app.staticTexts["Game Center Sam"].exists)
        tap("personalize.done")
        openSettings()
        XCTAssertTrue(app.staticTexts["settings.gameCenterName"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["settings.gameCenterName"].label, "Game Center Sam")
        XCTAssertEqual(app.textFields.count, 0)
        saveScreenshot("settings-game-center-name")
        app.buttons["Klaar"].firstMatch.tap()
        begin(1)
        play(1, correct: 5)
        tap("result.map")
        revealMapNode(1).tap()
        XCTAssertTrue(app.staticTexts["level.ownName"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["level.ownName"].label, "Game Center Sam")
        tap("level.ownName")
        let avatar = app.descendants(matching: .any)["level.ownAvatar"]
        let score = app.descendants(matching: .any)["level.ownScore"]
        XCTAssertTrue(avatar.exists)
        XCTAssertLessThan(avatar.frame.maxX, app.staticTexts["level.ownName"].frame.minX)
        XCTAssertLessThan(avatar.frame.maxX, score.frame.minX)
        XCTAssertEqual(score.label, "3 sterren")
        XCTAssertFalse(app.staticTexts["5/5"].exists)
        let time = app.descendants(matching: .any)["level.ownTime"]
        XCTAssertTrue(time.exists)
        XCTAssertGreaterThan(time.frame.minX, score.frame.maxX)
        XCTAssertTrue(time.label.contains(":"), "Completed result has a measured time")
        saveScreenshot("level-own-game-center-result")
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["header.dino"].waitForExistence(timeout: 5))
        tap("header.dino")
        XCTAssertTrue(app.buttons["personalize.bandana.blue"].isSelected)
        XCTAssertTrue(app.buttons["personalize.spikes.purple"].isSelected)
        XCTAssertEqual(app.textFields.count, 0)
    }

    func testDinoStandsOnCompletedLevel() {
        onboard()
        begin(1)
        play(1, correct: 5)
        tap("result.map")
        let marker = app.descendants(matching: .any)["map.dino.1"]
        XCTAssertTrue(marker.waitForExistence(timeout: 5))
        let node = revealMapNode(1)
        XCTAssertEqual(marker.frame.midX, node.frame.midX, accuracy: 1)
        XCTAssertEqual(marker.frame.maxY, node.frame.midY + 12, accuracy: 5)
        saveScreenshot("map-completed-level-dino")
    }

    func testAvatarColorMaskContours() {
        onboard()
        tap("header.dino")
        for (part, color) in [("bandana", "blue"), ("spikes", "purple"), ("body", "pink"), ("belly", "orange")] {
            tap("personalize.\(part).\(color)")
            XCTAssertTrue(app.buttons["personalize.\(part).\(color)"].isSelected)
        }
        // Let the asynchronous image render finish before capturing its contours.
        Thread.sleep(forTimeInterval: 0.75)
        saveScreenshot("avatar-mask-contours")
        tap("personalize.done")
        XCTAssertTrue(app.buttons["header.dino"].waitForExistence(timeout: 5))
        saveScreenshot("avatar-mask-header")
    }

    func testFreeAvatarColorPicker() {
        onboard()
        tap("header.dino")
        let picker = app.buttons["personalize.color.bandana"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        let sliders = app.segmentedControls.buttons.matching(NSPredicate(format: "label IN %@", ["Schuifbalken", "Sliders"])).firstMatch
        XCTAssertTrue(sliders.waitForExistence(timeout: 5))
        sliders.tap()
        let blue = app.sliders["sliderBlue"]
        XCTAssertTrue(blue.waitForExistence(timeout: 5))
        blue.adjust(toNormalizedSliderPosition: 0.73)
        saveScreenshot("personalize-free-color-picker")
        app.buttons.matching(NSPredicate(format: "label IN %@", ["sluit", "close"])).firstMatch.tap()
        XCTAssertFalse(app.buttons["personalize.bandana.red"].isSelected)
        XCTAssertTrue(app.buttons["personalize.body.green"].isSelected)
        let chosen = picker.value as? String
        XCTAssertNotNil(chosen)
        tap("personalize.done")
        app.terminate(); app.launch()
        tap("header.dino")
        XCTAssertEqual(app.buttons["personalize.color.bandana"].value as? String, chosen)
        tap("personalize.done")
    }

    func testPersonalizeHeaderColors() {
        onboard()
        saveScreenshot("personalize-header-default")
        tap("header.dino")
        XCTAssertTrue(app.buttons["personalize.bandana.red"].waitForExistence(timeout: 5))
        for (part, color) in [("bandana", "red"), ("spikes", "darkGreen"), ("body", "green"), ("belly", "yellow")] {
            XCTAssertTrue(app.buttons["personalize.\(part).\(color)"].isSelected)
            XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "personalize.color.\(part)").firstMatch.exists)
        }
        saveScreenshot("personalize-default")
        for (part, color) in [("bandana", "blue"), ("spikes", "purple"), ("body", "pink"), ("belly", "orange")] {
            tap("personalize.\(part).\(color)")
            XCTAssertTrue(app.buttons["personalize.\(part).\(color)"].isSelected)
        }
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "personalize.preview").firstMatch.isHittable)
        saveScreenshot("personalize-custom-colors")
        XCTAssertFalse(app.textFields["personalize.name"].exists)
        XCTAssertFalse(app.buttons["personalize.saveName"].exists)
        tap("personalize.done")
        XCTAssertTrue(app.buttons["header.dino"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["header.dino"].label, "Mijn dino")
        saveScreenshot("personalize-header-custom")
        app.terminate(); app.launch()
        saveScreenshot("personalize-cold-start")
        XCTAssertTrue(app.buttons["header.dino"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["header.dino"].label, "Mijn dino")
        tap("header.dino")
        for (part, color) in [("bandana", "blue"), ("spikes", "purple"), ("body", "pink"), ("belly", "orange")] {
            XCTAssertTrue(app.buttons["personalize.\(part).\(color)"].isSelected)
        }
        tap("personalize.resetColors")
        for (part, color) in [("bandana", "red"), ("spikes", "darkGreen"), ("body", "green"), ("belly", "yellow")] {
            XCTAssertTrue(app.buttons["personalize.\(part).\(color)"].isSelected)
        }
        tap("personalize.done")
        begin(1)
        XCTAssertTrue(app.buttons["header.pause"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["level.play"].exists)
        if app.buttons["demo.ready"].exists { tap("demo.ready") }
        tap("header.dino")
        tap("personalize.bandana.purple")
        tap("personalize.done")
        XCTAssertTrue(app.staticTexts["1/5"].exists)
        XCTAssertTrue(app.buttons["question.option.0"].exists)
        saveScreenshot("personalize-in-level")
        XCUIDevice.shared.orientation = .landscapeLeft
        tap("header.dino")
        saveScreenshot("personalize-landscape")
        tap("personalize.done")
        XCTAssertTrue(app.buttons["header.dino"].waitForExistence(timeout: 5))
        XCUIDevice.shared.orientation = .portrait
    }

    func testFriendsOptionalAndParentGate() {
        onboard()
        tap("map.friends")
        XCTAssertTrue(app.buttons["friends.connect"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["friends.invite"].exists)
        tap("friends.connect")
        XCTAssertTrue(app.textFields["friends.parentAnswer"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["friends.parentContinue"].isEnabled)
        tap("friends.parentCancel")
        XCTAssertTrue(app.buttons["friends.connect"].exists)
        saveScreenshot("friends-private-default")
        tap("friends.close")
        begin(1)
        play(1, correct: 5)
        tap("result.map")
        let counter = app.descendants(matching: .any).matching(identifier: "header.stars").firstMatch
        XCTAssertEqual(counter.label, "3 sterren")
    }

    func testFriendMapAndProfilesWithTestFixtures() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_SOCIAL"] = "fixtures"
        app.launch()
        onboard()
        let avatar = app.buttons["map.friend.test-0"]
        for _ in 0..<8 { if avatar.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(avatar.isHittable)
        XCTAssertTrue(app.buttons["Nog 2 vrienden"].exists)
        saveScreenshot("friends-map")
        avatar.tap()
        XCTAssertTrue(app.staticTexts["Sophie"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "friend.metric.dino.friends.totalStars").firstMatch.exists)
        saveScreenshot("friends-profile")
        tap("friend.close")
        for _ in 0..<8 { if app.buttons["map.friends"].isHittable { break }; app.swipeDown() }
        tap("map.friends")
        let missing = app.buttons["friends.profile.test-missing"]
        for _ in 0..<8 { if missing.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(missing.isHittable)
        missing.tap()
        XCTAssertTrue(app.staticTexts["Alex"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(identifier: "Niet beschikbaar").firstMatch.exists)
        saveScreenshot("friends-unavailable-results")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        tap("friends.close")
        let node = app.buttons["map.level.1"]
        for _ in 0..<8 { if node.isHittable { break }; app.swipeUp() }
        node.tap()
        XCTAssertTrue(app.buttons["level.friend.test-0"].waitForExistence(timeout: 5))
        tap("level.friend.test-0")
        XCTAssertTrue(app.staticTexts["Sophie"].waitForExistence(timeout: 5))
        tap("friend.close")
        saveScreenshot("friends-level-results")
    }

    private func play(_ id: Int, correct count: Int, attempt: Int = 0) {
        let level = DinoLevelCatalog.level(id)!
        var rng = SeededGenerator(seed: seed)
        let questions = DinoQuestionGenerator.generate(level: level, attempt: attempt, using: &rng)
        for (i, question) in questions.enumerated() {
            let demo = app.buttons["demo.ready"]
            if demo.exists { demo.tap() }
            if i == 0 { saveScreenshot("level-\(id)-question") }
            let right = i < count
            let answer = right ? question.target : ClockTime(hour: ClockTime.shiftedHour(question.target.hour, by: 1))
            switch question.kind {
            case .setAnalog:
                let clock = app.descendants(matching: .any).matching(identifier: "question.analogControl").firstMatch
                XCTAssertTrue(clock.waitForExistence(timeout: 5))
                let angle = Double(answer.hour) * .pi / 6
                clock.coordinate(withNormalizedOffset: CGVector(dx: 0.5 + sin(angle) * 0.34, dy: 0.5 - cos(angle) * 0.34)).tap()
                tap("question.confirm")
            case .setDigital:
                let initial = question.target.hour == 12 ? 1 : 12
                let increments = (answer.hour - initial + 12) % 12
                let plus = app.buttons["Een uur vooruit"]
                XCTAssertTrue(plus.waitForExistence(timeout: 5))
                for _ in 0..<increments { plus.tap() }
                tap("question.confirm")
            default:
                let option = right ? question.options.firstIndex(of: question.target)! : question.options.firstIndex { $0 != question.target }!
                tap("question.option.\(option)")
            }
            if !right {
                tap("question.next")
            }
            // Correct answers advance after feedback; wrong answers require an explicit tap.
            let advanced = NSPredicate { _, _ in
                if i == questions.count - 1 { return self.app.buttons["result.map"].exists }
                return self.app.staticTexts["\(i + 2)/\(questions.count)"].exists
            }
            expectation(for: advanced, evaluatedWith: nil)
            waitForExpectations(timeout: 8)
        }
        XCTAssertTrue(app.buttons["result.map"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["\(count)/\(level.questionCount)"].exists)
        XCTAssertEqual(app.images["dino.backflip"].exists, count == level.questionCount)
    }

    func testEntireNormalWorldAndBoss() {
        onboard()
        XCTAssertFalse(app.buttons["map.level.2"].isEnabled)
        begin(1)
        for id in 1...9 {
            play(id, correct: 5)
            XCTAssertTrue(app.buttons["result.next"].exists)
            if id < 9 { tap("result.next") }
        }
        tap("result.map")
        XCTAssertTrue(app.descendants(matching: .any)["map.dino.9"].exists)
        begin(10)
        play(10, correct: 5)
        tap("result.next")
        XCTAssertTrue(app.staticTexts["Wereld voltooid!"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Slaapvallei"].exists)
        XCTAssertTrue(app.buttons["completion.nextWorld"].exists)
        XCTAssertFalse(app.staticTexts["Coming soon"].exists)
        saveScreenshot("normal-world-complete")
    }

    func testDirectPerfectBoss() {
        onboard()
        begin(10)
        play(10, correct: 10)
        XCTAssertTrue(app.staticTexts["Perfecte boss-overwinning!"].exists)
        tap("result.next")
        XCTAssertTrue(app.staticTexts["Wereld voltooid!"].exists)
        XCTAssertTrue(app.staticTexts["Slaapvallei"].exists)
        XCTAssertFalse(app.staticTexts["Coming soon"].exists)
        tap("completion.nextWorld")
        XCTAssertTrue(app.staticTexts["1/5"].waitForExistence(timeout: 5))
        var rng = SeededGenerator(seed: seed)
        let nextQuestion = DinoQuestionGenerator.generate(level: DinoLevelCatalog.level(11)!, using: &rng)[0]
        let option = nextQuestion.responses.firstIndex(of: nextQuestion.expectedAnswer)!
        tap("question.option.\(option)")
        XCTAssertTrue(app.staticTexts["2/5"].waitForExistence(timeout: 8))
        tap("header.pause"); tap("game.exit.confirm")
        app.terminate(); app.launch()
        XCTAssertFalse(app.textFields["onboarding.name"].exists)
        XCTAssertTrue(app.buttons["map.level.9"].exists)
        XCTAssertTrue(app.buttons["map.level.9"].isEnabled)
        XCTAssertTrue(app.descendants(matching: .any)["map.dino.10"].exists)
        let marker = app.descendants(matching: .any)["map.dino.10"]
        XCTAssertLessThan(marker.frame.height, 220)
        XCTAssertLessThanOrEqual(marker.frame.maxY, app.frame.maxY)
        XCTAssertGreaterThan(marker.frame.minY, 100)
        saveScreenshot("perfect-boss")
    }

    func testZeroStarsUnlockAndReplay() {
        onboard()
        begin(1)
        play(1, correct: 2)
        XCTAssertFalse(app.buttons["result.next"].exists)
        tap("result.retry")
        play(1, correct: 3, attempt: 1)
        XCTAssertTrue(app.buttons["result.next"].exists)
        tap("result.retry")
        play(1, correct: 0, attempt: 2)
        tap("result.map")
        XCTAssertTrue(app.buttons["map.level.2"].isEnabled)
        XCTAssertTrue(app.descendants(matching: .any)["map.dino.1"].exists)
        let marker = app.descendants(matching: .any)["map.dino.1"]
        XCTAssertLessThan(marker.frame.height, 220)
        XCTAssertLessThanOrEqual(marker.frame.maxY, app.frame.maxY)
        XCTAssertGreaterThan(marker.frame.minY, 100)
        saveScreenshot("map-last-completed")
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["map.level.2"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["map.level.2"].isEnabled)
        XCTAssertTrue(app.descendants(matching: .any)["map.dino.1"].exists)
    }

    func testCustomClockAndSettings() {
        onboard(custom: true)
        openSettings()
        tap("settings.clocks")
        let blue = app.buttons["theme.dino.face.blue"]
        XCTAssertTrue(blue.waitForExistence(timeout: 5))
        XCTAssertTrue(blue.isSelected)
        tap("theme.dino.face.green")
        app.buttons["Klaar"].firstMatch.tap()
        app.terminate(); app.launch()
        openSettings()
        tap("settings.clocks")
        XCTAssertTrue(app.buttons["theme.dino.face.green"].isSelected)
        saveScreenshot("custom-clocks")
    }

    func testSettingsPreferencesPersist() {
        onboard()
        openSettings()
        let sound = app.switches["settings.soundEffects"]
        let haptics = app.switches["settings.haptics"]
        let contrast = app.switches["settings.highContrast"]
        let cloud = app.switches["settings.icloudSync"]
        XCTAssertTrue(sound.waitForExistence(timeout: 5))
        XCTAssertEqual(sound.value as? String, "1")
        XCTAssertEqual(haptics.value as? String, "1")
        XCTAssertEqual(contrast.value as? String, "0")
        XCTAssertEqual(cloud.value as? String, "0")
        saveScreenshot("settings-preferences")
        tap("settings.soundEffects"); tap("settings.haptics")
        tap("settings.highContrast"); tap("settings.icloudSync")
        XCTAssertEqual(cloud.value as? String, "1")
        XCTAssertTrue(app.staticTexts["settings.icloudStatus"].exists)
        saveScreenshot("settings-high-contrast")
        app.terminate(); app.launch()
        openSettings()
        XCTAssertTrue(sound.waitForExistence(timeout: 5))
        XCTAssertEqual(sound.value as? String, "0")
        XCTAssertEqual(haptics.value as? String, "0")
        XCTAssertEqual(contrast.value as? String, "1")
        XCTAssertEqual(cloud.value as? String, "1")
        tap("settings.icloudSync")
        XCTAssertEqual(cloud.value as? String, "0")
        XCUIDevice.shared.orientation = .landscapeLeft
        tap("settings.icloudSync"); tap("settings.icloudSync")
        saveScreenshot("settings-landscape")
        XCUIDevice.shared.orientation = .portrait
        for _ in 0..<6 { if app.buttons["language.picker"].isHittable { break }; app.swipeDown() }
        tap("language.picker"); tap("language.option.en")
        XCTAssertEqual(sound.label, "Sound effects")
        XCTAssertEqual(contrast.label, "High contrast")
        saveScreenshot("settings-english")
        app.buttons["Done"].firstMatch.tap()
        begin(10)
        if app.buttons["demo.ready"].exists { tap("demo.ready") }
        var rng = SeededGenerator(seed: seed)
        let question = DinoQuestionGenerator.generate(level: DinoLevelCatalog.level(10)!, attempt: 0, using: &rng)[0]
        let wrong = question.options.firstIndex { $0 != question.target }!
        tap("question.option.\(wrong)")
        XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
        saveScreenshot("settings-high-contrast-answer")
    }

    private func saveScreenshot(_ name: String) {
        autoreleasepool {
            // Store compressed captures directly: retaining decoded screenshots
            // and an extra render buffer for every world can exhaust the runner.
            let png = XCUIScreen.main.screenshot().pngRepresentation
            let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
            attachment.name = name; attachment.lifetime = .keepAlways
            add(attachment)
            let deviceFolder = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
            let folder = URL(fileURLWithPath: "/tmp/DinoScreenshots/\(deviceFolder)", isDirectory: true)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try? png.write(to: folder.appendingPathComponent(name + ".png"))
        }
    }

    func testBossNearMissDoesNotSkipWorld() {
        onboard()
        begin(10)
        play(10, correct: 9)
        XCTAssertFalse(app.buttons["result.next"].exists)
        XCTAssertTrue(app.staticTexts["Haal 10/10, of verdien eerst een ster in alle 9 levels."].exists)
    }

    func testFourChoicesAndPersistentWrongAnswer() {
        onboard()
        begin(10)
        XCTAssertFalse(app.buttons["demo.ready"].exists)
        let options = (0..<4).map { app.buttons["question.option.\($0)"] }
        XCTAssertTrue(options.allSatisfy(\.exists))
        XCTAssertFalse(app.buttons["question.option.4"].exists)
        XCTAssertEqual(options[0].frame.midY, options[1].frame.midY, accuracy: 2)
        XCTAssertEqual(options[2].frame.midY, options[3].frame.midY, accuracy: 2)
        XCTAssertGreaterThan(options[2].frame.midY, options[0].frame.midY)
        let clock = app.descendants(matching: .any)["question.targetClock"]
        let title = app.staticTexts["question.title"]
        XCTAssertEqual(clock.frame.midX, title.frame.midX, accuracy: 1)
        let originalCenter = clock.frame.midX
        var rng = SeededGenerator(seed: seed)
        let first = DinoQuestionGenerator.generate(level: DinoLevelCatalog.level(10)!, using: &rng)[0]
        tap("question.option.\(first.options.firstIndex { $0 != first.target }!)")
        XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
        RunLoop.current.run(until: Date().addingTimeInterval(3))
        XCTAssertTrue(app.staticTexts["1/10"].exists, "Wrong feedback must remain until the child taps Next")
        XCTAssertTrue(app.buttons["question.next"].isHittable)
        XCTAssertTrue(options[3].isHittable, "All four answers remain visible above the feedback")
        XCTAssertFalse(app.descendants(matching: .any)["question.feedback"].exists)
        saveScreenshot("companion-level-wrong-bottom")
        XCTAssertTrue(app.images["dino.wrongAnswer"].exists, "The wrong-answer pose remains until Next")
        let reaction = app.images["dino.wrongAnswer"]
        XCTAssertEqual(app.images.matching(identifier: "dino.wrongAnswer").count, 1)
        XCTAssertGreaterThanOrEqual(reaction.frame.minY, 0)
        XCTAssertLessThanOrEqual(reaction.frame.maxY, app.frame.maxY, "Reaction remains at the bottom of the screen")
        XCTAssertEqual(clock.frame.midX, originalCenter, accuracy: 1, "Dino cannot displace the clock after an answer")
        saveScreenshot("wrong-answer-waits")
        tap("question.next")
        XCTAssertTrue(app.staticTexts["2/10"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.images["dino.wrongAnswer"].exists)
    }

    func testCompanionDockWithCustomColorsAndLargeQuestions() {
        onboard()
        tap("header.dino")
        for (part, color) in [("bandana", "purple"), ("spikes", "purple"), ("body", "pink")] {
            tap("personalize.\(part).\(color)")
        }
        tap("personalize.done")
        tap("header.practice")
        selectPractice("practice.type.chooseAnalog")
        tap("practice.start")
        let idle = app.images["dino.character"]
        XCTAssertTrue(idle.waitForExistence(timeout: 5))
        assertCompanionAtBottom(idle)
        let smallQuestionSize = idle.frame.width
        let beforeScroll = idle.frame
        saveScreenshot("companion-pink-idle-bottom")
        app.swipeUp()
        XCTAssertEqual(idle.frame.midY, beforeScroll.midY, accuracy: 2, "Scrolling the question never scrolls Dino away")
        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.chooseAnalog)), seed: seed)
        answerPracticeWrong(generator.next(index: 0))
        let reaction = app.images["dino.wrongAnswer"]
        XCTAssertTrue(reaction.waitForExistence(timeout: 5))
        assertCompanionAtBottom(reaction)
        let next = app.buttons["question.next"]
        XCTAssertTrue(next.isHittable)
        XCTAssertLessThanOrEqual(next.frame.maxX, reaction.frame.minX + 2, "Dino leaves the Next button clear")
        saveScreenshot("companion-pink-wrong-bottom")
        tap("question.next")
        tap("header.pause")
        selectPractice("practice.type.pairClocks")
        tap("practice.start")
        XCTAssertTrue(idle.waitForExistence(timeout: 5), "Expanded questions also show Dino")
        assertCompanionAtBottom(idle)
        XCTAssertLessThanOrEqual(idle.frame.width, smallQuestionSize + 2, "A larger question keeps the companion compact")
        saveScreenshot("companion-large-pair-question")
        // The practice cover uses its presenter's orientation on iPhone. Rotate
        // the main game scene to verify the same dock at a short viewport height.
        tap("header.pause")
        tap("practice.close")
        begin(10)
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscape = NSPredicate { _, _ in self.app.frame.width > self.app.frame.height && idle.exists && idle.frame.maxY <= self.app.frame.maxY }
        expectation(for: landscape, evaluatedWith: nil)
        waitForExpectations(timeout: 8)
        assertCompanionAtBottom(idle)
        if UIDevice.current.userInterfaceIdiom == .phone {
            XCTAssertLessThan(idle.frame.width, smallQuestionSize, "Short screens shrink Dino while keeping him visible")
        }
        saveScreenshot("companion-question-landscape")
        XCUIDevice.shared.orientation = .portrait
    }

    private func assertCompanionAtBottom(_ companion: XCUIElement) {
        XCTAssertEqual(app.images.matching(identifier: companion.identifier).count, 1)
        XCTAssertGreaterThanOrEqual(companion.frame.minX, 0)
        XCTAssertLessThanOrEqual(companion.frame.maxX, app.frame.maxX + 1)
        XCTAssertLessThanOrEqual(companion.frame.maxY, app.frame.maxY + 1)
        XCTAssertGreaterThanOrEqual(companion.frame.maxY, app.frame.maxY - 24, "Dino stands at the screen's bottom edge")
        XCTAssertGreaterThanOrEqual(companion.frame.width, 56, "Dino stays recognizable on dense questions")
    }

    func testLayoutAndLanguage() {
        onboard()
        saveScreenshot("map-portrait")
        begin(10)
        if app.buttons["demo.ready"].exists { tap("demo.ready") }
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.buttons["header.pause"].waitForExistence(timeout: 5))
        let settled = NSPredicate { _, _ in
            let lastOption = self.app.buttons["question.option.2"]
            return self.app.frame.width > self.app.frame.height && lastOption.exists &&
                lastOption.frame.maxX <= self.app.frame.maxX + 1 && lastOption.frame.minX >= self.app.frame.minX
        }
        expectation(for: settled, evaluatedWith: nil)
        waitForExpectations(timeout: 8)
        // Frame coordinates settle before the simulator's rotation animation ends.
        RunLoop.current.run(until: Date().addingTimeInterval(1))
        saveScreenshot("game-landscape")
        answerFirstQuestionWrong(10, advance: true)
        app.buttons["header.pause"].tap()
        XCTAssertTrue(app.buttons["game.exit.cancel"].waitForExistence(timeout: 5))
        saveScreenshot("exit-landscape")
        app.buttons["Level verlaten"].tap()
        XCUIDevice.shared.orientation = .portrait
        let portraitSettled = NSPredicate { _, _ in
            let gear = self.app.buttons["header.settings"]
            return self.app.frame.width < self.app.frame.height && gear.exists &&
                gear.frame.maxY < 180 && gear.frame.maxX <= self.app.frame.maxX
        }
        expectation(for: portraitSettled, evaluatedWith: nil)
        waitForExpectations(timeout: 8)
        openSettings()
        tap("language.picker")
        XCTAssertTrue(app.buttons["language.option.nl"].exists)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "language.option.")).count, 2)
        let english = app.descendants(matching: .any).matching(identifier: "language.option.en").firstMatch
        for _ in 0..<8 {
            if english.isHittable { break }
            app.swipeDown()
        }
        XCTAssertTrue(english.isHittable)
        english.tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))
        tap("settings.clocks")
        XCTAssertTrue(app.staticTexts["Analog clock"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["dino.hands.straight"].exists)
        saveScreenshot("clocks-english")
        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["header.dino"].waitForExistence(timeout: 5))
    }

    func testJungleHeaderSettingsAndTransition() {
        onboard()
        let player = app.descendants(matching: .any)["header.dino"]
        let level = app.descendants(matching: .any)["header.level"]
        let stars = app.descendants(matching: .any)["header.stars"]
        XCTAssertEqual(player.label, "Mijn dino")
        XCTAssertEqual(level.label, "Level 1")
        XCTAssertEqual(stars.label, "0 sterren")
        XCTAssertFalse(app.staticTexts["0/27"].exists)
        let originalHeaderY = level.frame.midY
        XCTAssertLessThan(player.frame.maxX, level.frame.minX)
        XCTAssertLessThan(level.frame.maxX, stars.frame.minX)
        saveScreenshot("jungle-header-start")
        XCTAssertFalse(app.buttons["header.pause"].exists)
        openSettings()
        XCTAssertTrue(app.staticTexts["Instellingen"].waitForExistence(timeout: 5))
        saveScreenshot("jungle-direct-settings")
        app.buttons["Klaar"].firstMatch.tap()
        for section in 1...5 {
            app.swipeUp()
            saveScreenshot("jungle-section-\(section)")
        }
        for _ in 0..<4 { app.swipeUp() }
        XCTAssertTrue(app.descendants(matching: .any)["map.world.2"].exists)
        XCTAssertEqual(level.frame.midY, originalHeaderY, accuracy: 1)
        saveScreenshot("jungle-world-transition")
        for _ in 0..<10 { app.swipeDown() }
        begin(1)
        play(1, correct: 5)
        tap("result.map")
        XCTAssertEqual(stars.label, "3 sterren")
        XCTAssertEqual(level.label, "Level 1")
        let character = app.descendants(matching: .any)["map.dino.1"]
        let node = app.buttons["map.level.1"]
        XCTAssertEqual(character.frame.midX, node.frame.midX, accuracy: 1)
        XCTAssertEqual(character.frame.maxY, node.frame.midY - 24, accuracy: 3)
        XCTAssertFalse(character.label.contains("Sam"))
        XCTAssertTrue(node.isHittable)
        saveScreenshot("jungle-earned-stars")
    }

    func testStartPointCleanCardAndExitCancel() {
        onboard()
        let marker = app.descendants(matching: .any)["map.dino.0"]
        XCTAssertTrue(marker.exists)
        XCTAssertGreaterThan(marker.frame.height, 95)
        XCTAssertLessThanOrEqual(marker.frame.height, 123)
        let start = app.descendants(matching: .any)["map.start"]
        XCTAssertTrue(start.exists)
        XCTAssertEqual(marker.frame.midX, start.frame.midX, accuracy: 1)
        XCTAssertFalse(marker.label.contains("Sam"))
        XCTAssertFalse(app.buttons["map.level.0"].exists)
        saveScreenshot("map-start")
        revealMapNode(1).tap()
        XCTAssertFalse(app.staticTexts["5 vragen"].exists)
        XCTAssertFalse(app.staticTexts["Kies de analoge klok bij de tijd."].exists)
        saveScreenshot("level-start-card")
        tap("level.play")
        if app.buttons["demo.ready"].exists { tap("demo.ready") }
        let clock = app.descendants(matching: .any)["question.targetClock"]
        XCTAssertEqual(clock.frame.midX, app.frame.midX, accuracy: 1)
        let companion = app.images["dino.character"]
        XCTAssertGreaterThan(companion.frame.width, 95)
        answerFirstQuestionWrong(1, advance: true)
        app.buttons["header.pause"].tap()
        XCTAssertTrue(app.buttons["game.exit.cancel"].waitForExistence(timeout: 5))
        let coveredAnswer = app.buttons["question.option.0"]
        XCTAssertTrue(!coveredAnswer.exists || !coveredAnswer.isEnabled,
                      "Answer input is disabled while the exit card is open")
        saveScreenshot("exit-portrait")
        tap("game.exit.cancel")
        XCTAssertTrue(app.staticTexts["2/5"].exists)
        XCTAssertEqual(clock.frame.midX, app.frame.midX, accuracy: 1)
        app.buttons["header.pause"].tap()
        tap("game.exit.confirm")
        XCTAssertTrue(marker.waitForExistence(timeout: 5))
    }

    func testPlayCardAndContinuousResultDino() {
        onboard()
        tap("header.dino")
        for (part, color) in [("bandana", "blue"), ("spikes", "purple"), ("body", "pink"), ("belly", "orange")] {
            tap("personalize.\(part).\(color)")
        }
        tap("personalize.done")
        saveScreenshot("personalized-map-companion")
        revealMapNode(1).tap()
        let playButton = app.buttons["level.play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 3))
        saveScreenshot("transition-start-card")
        playButton.tap()
        XCTAssertFalse(playButton.exists, "The start card disappears in the same scene change as Play")
        XCTAssertTrue(app.buttons["header.pause"].waitForExistence(timeout: 1))
        if app.buttons["demo.ready"].exists { tap("demo.ready") }
        XCTAssertEqual(app.images.matching(identifier: "dino.character").count, 1)
        saveScreenshot("transition-first-question")
        play(1, correct: 5)
        XCTAssertEqual(app.images.matching(identifier: "dino.backflip").count, 1)
        XCTAssertEqual(app.images.matching(identifier: "dino.thumbsUp").count, 0)
        RunLoop.current.run(until: Date().addingTimeInterval(1.7))
        let landed = app.images["dino.backflip"]
        // The final sprite has a small registration offset inside its centered 210pt slot.
        XCTAssertEqual(landed.frame.midX, app.frame.midX, accuracy: 4)
        XCTAssertEqual(landed.frame.width, 210, accuracy: 1)
        saveScreenshot("transition-result-dino")
        tap("result.map")
        XCTAssertTrue(app.descendants(matching: .any)["map.dino.1"].waitForExistence(timeout: 5))
        saveScreenshot("personalized-completed-map-companion")
    }
}
