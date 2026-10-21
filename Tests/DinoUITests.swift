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
        app.launchArguments = ["-settings.languageOverride", "nl", "-AppleICUForce24HourTime", "YES"]
        app.launch()
    }

    private func tap(_ id: String) {
        let item = app.descendants(matching: .any).matching(identifier: id).firstMatch
        if id.hasPrefix("theme."), id != "theme.done" { revealThemeChoice(id) }
        XCTAssertTrue(item.exists || item.waitForExistence(timeout: 6), "Missing \(id)")
        for _ in 0..<(id.hasPrefix("theme.") ? 0 : 6) {
            let footer = editorFooter
            let inEditor = id.hasPrefix("personalize.")
            let aboveFooter = !inEditor || id == "personalize.done" || !footer.exists || item.frame.maxY < footer.frame.minY - 24
            let questions = app.scrollViews["game.questions"]
            let stickyConfirm = id == "question.confirm" && questions.exists
                && item.frame.minY >= questions.frame.maxY - 8
            if stickyConfirm {
                // Confirm lives in the sticky footer. Dragging the question would move clocks and pairs.
                if item.isHittable { break }
                RunLoop.current.run(until: Date().addingTimeInterval(0.25))
                continue
            }
            if item.isHittable && aboveFooter { break }
            app.swipeUp()
        }
        if id.hasPrefix("theme.") && id != "theme.done" {
            // Tap the visible choice, avoiding stale AX activation points from
            // preview children after a warning changes the scroll viewport.
            item.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        } else { item.tap() }
    }

    private func revealThemeChoice(_ id: String) {
        let item = app.descendants(matching: .any).matching(identifier: id).firstMatch
        let containingScroll = app.scrollViews.containing(.any, identifier: id).firstMatch
        let visibleEditor = ["theme.options.both", "theme.options.analog", "theme.options.digital"]
            .map { app.scrollViews[$0] }.first { $0.exists && $0.isHittable }
        let scroll = containingScroll.exists ? containingScroll : (visibleEditor ?? app.scrollViews.firstMatch)
        guard scroll.exists else { return }
        for _ in 0..<10 {
            let footer = editorFooter
            let top = max(scroll.frame.minY + 8, app.navigationBars.firstMatch.exists ? app.navigationBars.firstMatch.frame.maxY + 8 : 0)
            let bottom = min(scroll.frame.maxY - 8, footer.exists ? footer.frame.minY - 24 : app.frame.maxY - 40)
            if item.exists && item.isHittable && item.frame.minY >= top && item.frame.maxY <= bottom { return }
            let downward = item.exists && item.frame.minY < top
            let startY = downward ? top + 16 : bottom - 16
            let endY = downward ? bottom - 16 : top + 16
            let origin = app.coordinate(withNormalizedOffset: .zero)
            origin.withOffset(CGVector(dx: scroll.frame.midX, dy: startY)).press(forDuration: 0.05,
                thenDragTo: origin.withOffset(CGVector(dx: scroll.frame.midX, dy: endY)))
        }
    }

    private var editorFooter: XCUIElement {
        ["onboarding.next", "onboarding.customClock", "personalize.done", "theme.done"]
            .map { app.buttons[$0] }.first { $0.exists } ?? app.buttons["onboarding.customClock"]
    }

    private func launchUsingDeviceLanguage(_ code: String, locale: String) {
        app.terminate()
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.\(UUID().uuidString)"
        app.launchArguments = ["-AppleLanguages", "(\(code))", "-AppleLocale", locale, "-AppleICUForce24HourTime", "YES"]
        app.launch()
    }

    private func swipeWelcomePreview(_ identifier: String, forward: Bool) {
        let preview = app.descendants(matching: .any)[identifier]
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        let distance = min(54, preview.frame.width * 0.3)
        let center = preview.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.withOffset(CGVector(dx: forward ? distance : -distance, dy: 0))
            .press(forDuration: 0.05, thenDragTo: center.withOffset(CGVector(dx: forward ? -distance : distance, dy: 0)))
    }

    private func onboard(custom: Bool = false) {
        XCTAssertTrue(app.buttons["onboarding.next"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["onboarding.next"].isEnabled)
        XCTAssertFalse(app.textFields["onboarding.name"].exists)
        XCTAssertTrue(app.buttons["personalize.bandana.red"].exists)
        tap("onboarding.next")
        if custom { tap("theme.dino.face.blue") }
        tap("onboarding.next")
        tap("onboarding.customClock")
        XCTAssertTrue(app.buttons["map.bossShortcut"].waitForExistence(timeout: 5))
        waitForMapOpeningToFinish()
        XCTAssertTrue(app.descendants(matching: .any)["header.dino"].exists)
    }

    private func waitForMapOpeningToFinish() {
        let finished = NSPredicate { _, _ in
            !self.app.descendants(matching: .any)["map.preparing"].exists
        }
        expectation(for: finished, evaluatedWith: nil)
        waitForExpectations(timeout: 15)
    }

    private func openSettings() {
        tap("header.settings")
    }

    private func openClockPage(_ page: String) {
        tap("header.dino")
        tap("personalize.page." + page)
    }

    private func confirmProgressReset() {
        let equation = app.staticTexts["settings.reset.equation"]
        XCTAssertTrue(equation.waitForExistence(timeout: 5))
        let token = equation.value as? String ?? ""
        let halves = token.split(separator: "x")
        XCTAssertEqual(halves.count, 2)
        let tail = halves[1].split(separator: "+")
        XCTAssertEqual(tail.count, 2)
        let answer = (Int(halves[0]) ?? 0) * (Int(tail[0]) ?? 0) + (Int(tail[1]) ?? 0)
        XCTAssertGreaterThan(answer, 10_000)
        let field = app.textFields["settings.reset.answer"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(String(answer))
        let confirm = app.buttons["settings.reset.confirm"]
        let ready = NSPredicate { _, _ in confirm.exists && confirm.isEnabled }
        expectation(for: ready, evaluatedWith: nil)
        waitForExpectations(timeout: 5)
        confirm.tap()
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
        let ready = NSPredicate { _, _ in
            self.app.staticTexts["question.title"].exists
                && self.app.buttons["question.example"].isEnabled
                && !self.app.buttons["level.play"].exists
        }
        expectation(for: ready, evaluatedWith: app)
        waitForExpectations(timeout: 5)
    }

    func testFirstLevelPointerPersistsUntilAnyLevelIsOpened() {
        onboard()
        let pointer = app.descendants(matching: .any)["map.levelPointer.1"]
        XCTAssertTrue(pointer.waitForExistence(timeout: 5))
        let first = app.buttons["map.level.1"]
        let world = app.descendants(matching: .any)["map.world.1"].firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["map.start"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["map.dino.1"].exists)
        XCTAssertGreaterThan(world.frame.minY, -20, "a fresh map stays scrolled to the top")
        XCTAssertLessThan(world.frame.minY, app.frame.height * 0.45)
        XCTAssertGreaterThan(first.frame.minY, app.buttons["header.settings"].frame.maxY)
        saveScreenshot("map-first-level-pointer")
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
            tap("header.level")
            XCTAssertTrue(pointer.waitForExistence(timeout: 5))
            saveScreenshot("map-first-level-pointer-after-rotation")
            XCUIDevice.shared.orientation = .portrait
        }
        // Unlike a header cue, installation guidance must outlive the five-second timeout.
        Thread.sleep(forTimeInterval: 6)
        XCTAssertTrue(pointer.exists)
        app.terminate(); app.launch()
        XCTAssertTrue(pointer.waitForExistence(timeout: 6))
        // The directly accessible boss counts too, without playing or finishing it.
        tap("map.bossShortcut")
        XCTAssertTrue(app.buttons["level.play"].waitForExistence(timeout: 5))
        app.buttons["Levelkaart"].tap()
        XCTAssertTrue(app.buttons["header.level"].waitForExistence(timeout: 5))
        XCTAssertFalse(pointer.exists)
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["header.level"].waitForExistence(timeout: 6))
        XCTAssertFalse(pointer.exists)
    }

    func testLevelHeaderScrollsToNextLevelAndDismissesPointer() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "3"
        app.launch()
        XCTAssertTrue(app.buttons["header.level"].waitForExistence(timeout: 6))
        app.swipeUp(velocity: .fast)
        app.swipeUp(velocity: .fast)
        tap("header.level")
        let pointer = app.descendants(matching: .any)["map.levelPointer.4"]
        XCTAssertTrue(pointer.waitForExistence(timeout: 5))
        saveScreenshot("map-next-level-pointer")
        let next = app.buttons["map.level.4"]
        XCTAssertGreaterThan(next.frame.minY, app.buttons["header.settings"].frame.maxY)
        XCTAssertLessThan(next.frame.maxY + 85, app.frame.maxY)
        XCTAssertTrue(next.isEnabled)
        XCTAssertTrue(pointer.waitForNonExistence(timeout: 7))
        tap("header.level")
        XCTAssertTrue(pointer.waitForExistence(timeout: 5))
        next.tap()
        XCTAssertTrue(app.buttons["level.play"].waitForExistence(timeout: 5))
    }

    func testLevelHeaderReturnsAcrossSeveralWorlds() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "34"
        app.launch()
        waitForMapOpeningToFinish()
        let world = { (id: Int) in self.app.descendants(matching: .any)["header.world.\(id)"].firstMatch }
        XCTAssertTrue(world(4).waitForExistence(timeout: 10))
        let next = app.buttons["map.level.35"]
        let pointer = app.descendants(matching: .any)["map.levelPointer.35"]

        func assertArrived(_ name: String) {
            XCTAssertTrue(pointer.waitForExistence(timeout: 8))
            XCTAssertTrue(world(4).exists)
            XCTAssertTrue(next.isHittable)
            XCTAssertGreaterThan(next.frame.minY, app.buttons["header.settings"].frame.maxY)
            XCTAssertLessThan(next.frame.maxY + 85, app.frame.maxY)
            let position = next.frame.midY
            for _ in 0..<3 {
                XCTAssertEqual(next.frame.midY, position, accuracy: 1, "Arrival must not be followed by a second scroll or layout jump")
            }
            saveScreenshot(name)
        }

        // Scroll to an earlier world, then navigate several worlds forwards.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.04)).tap()
        for _ in 0..<30 {
            if world(1).exists { break }
            app.swipeDown(velocity: .fast)
        }
        XCTAssertTrue(world(1).exists)
        tap("header.level")
        assertArrived("level-navigation-long-forwards")

        // A later world exercises the same trip in the opposite direction.
        for _ in 0..<18 {
            if world(7).exists || world(8).exists || world(9).exists || world(10).exists { break }
            app.swipeUp(velocity: .fast)
        }
        XCTAssertFalse(world(4).exists)
        app.buttons["header.level"].doubleTap()
        assertArrived("level-navigation-long-backwards-repeated-tap")

        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
            tap("header.level")
            assertArrived("level-navigation-landscape")
            XCUIDevice.shared.orientation = .portrait
        }
        next.tap()
        XCTAssertTrue(app.buttons["level.play"].waitForExistence(timeout: 5))
    }

    func testLevelHeaderGuidesAcrossWorldBoundary() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "9"
        app.launch()
        tap("header.level")
        let pointer = app.descendants(matching: .any)["map.levelPointer.91"]
        XCTAssertTrue(pointer.waitForExistence(timeout: 6))
        saveScreenshot("map-next-world-pointer")
        let next = app.buttons["map.level.91"]
        XCTAssertGreaterThan(next.frame.minY, app.buttons["header.settings"].frame.maxY)
        XCTAssertLessThan(next.frame.maxY + 85, app.frame.maxY)
        next.tap()
        XCTAssertTrue(app.buttons["level.play"].waitForExistence(timeout: 5))
    }

    func testLevelHeaderCelebratesCompletedAdventure() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "10"
        app.launch()
        tap("header.level")
        let confetti = app.descendants(matching: .any)["map.completionConfetti"]
        XCTAssertTrue(confetti.waitForExistence(timeout: 6))
        saveScreenshot("map-adventure-complete-confetti")
        XCTAssertTrue(app.buttons["map.level.100"].isEnabled)
        XCTAssertFalse(app.descendants(matching: .any)["map.levelPointer.100"].exists)
        XCTAssertTrue(confetti.waitForNonExistence(timeout: 7))
        tap("header.level")
        XCTAssertTrue(confetti.waitForExistence(timeout: 6))
    }

    func testStarsOverviewWorldCountsAndReturn() {
        for completedLevel in [0, 24, 100] {
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.stars.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
            app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = String(completedLevel)
            app.launch()
            XCTAssertTrue(app.buttons["header.stars"].waitForExistence(timeout: 8))
            tap("header.stars")
            let overview = app.scrollViews["stars.overview"]
            XCTAssertTrue(overview.waitForExistence(timeout: 5))
            for world in 1...10 {
                let firstLevel = (world - 1) * 10 + 1
                let expected = min(9, max(0, completedLevel - firstLevel + 1)) * 3
                let unlocked = world <= completedLevel / 10 + 1
                let row = app.descendants(matching: .any)["stars.world.\(world)"]
                XCTAssertTrue(row.exists)
                XCTAssertEqual(row.staticTexts["\(expected)"].exists, unlocked)
                XCTAssertFalse(app.buttons["stars.world.\(world)"].exists)
            }
            let expectedTotal = (completedLevel - completedLevel / 10) * 3
            let total = app.descendants(matching: .any)["stars.total"]
            XCTAssertTrue(total.staticTexts["\(expectedTotal)"].exists)
            XCTAssertTrue(app.buttons["stars.close"].isHittable)
            saveScreenshot("stars-overview-\(completedLevel)")
            overview.swipeUp()
            XCTAssertTrue(app.descendants(matching: .any)["stars.world.10"].isHittable)
            XCTAssertTrue(app.buttons["stars.close"].isHittable)
            XCTAssertTrue(total.staticTexts["\(expectedTotal)"].exists)
            saveScreenshot("stars-overview-\(completedLevel)-bottom")
            tap("stars.close")
            XCTAssertTrue(app.buttons["header.stars"].waitForExistence(timeout: 5))
            XCTAssertFalse(overview.exists)
            XCTAssertEqual(app.descendants(matching: .any)["header.starCount"].label, "\(expectedTotal)")
        }
    }

    func testStarsOverviewEnglishAndTabletLayout() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "24"
        app.launchArguments = ["-settings.languageOverride", "en"]
        app.launch()
        XCTAssertTrue(app.buttons["header.stars"].waitForExistence(timeout: 8))
        app.buttons["header.stars"].tap()
        let overview = app.scrollViews["stars.overview"]
        XCTAssertTrue(overview.waitForExistence(timeout: 5))
        let total = app.descendants(matching: .any)["stars.total"]
        XCTAssertTrue(total.staticTexts["Total"].exists)
        XCTAssertTrue(total.staticTexts["66"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["stars.world.3"].staticTexts["12"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["stars.world.4"].staticTexts["12"].exists)
        XCTAssertEqual(app.buttons["stars.close"].label, "Back to the level overview")
        saveScreenshot("stars-overview-english-portrait")
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
            XCTAssertTrue(app.buttons["stars.close"].isHittable)
            overview.swipeUp()
            XCTAssertTrue(app.descendants(matching: .any)["stars.world.10"].isHittable)
            XCTAssertFalse(app.descendants(matching: .any)["stars.world.10"].staticTexts["12"].exists)
            XCTAssertTrue(total.staticTexts["66"].exists)
            saveScreenshot("stars-overview-english-landscape")
        }
        app.buttons["stars.close"].tap()
        XCTAssertFalse(overview.exists)
    }

    func testAllTenBossesHaveClockArtwork() {
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
            XCTAssertTrue(app.buttons["level.details"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.descendants(matching: .any)["level.questions"].exists)
            tap("level.details")
            let questions = app.descendants(matching: .any)["level.questions"]
            XCTAssertTrue(questions.waitForExistence(timeout: 5))
            XCTAssertGreaterThan(questions.frame.minY, app.buttons["header.settings"].frame.maxY)
            XCTAssertFalse(app.descendants(matching: .any)["level.bossArtwork.\(world)"].exists)
            XCTAssertTrue(app.staticTexts["Level \(world * 10)"].exists)
            let firstQuestion = app.descendants(matching: .any)["level.question.0"]
            XCTAssertTrue(firstQuestion.exists)
            if world == 1 {
                XCTAssertTrue(firstQuestion.label.contains("Kies de analoge klok"))
                XCTAssertTrue(firstQuestion.label.contains("Hele uren"))
                XCTAssertFalse(app.staticTexts["Tiko de Junglewachter"].exists)
            }
            XCTAssertTrue(app.buttons["level.play"].isEnabled)
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
        // A focused run reuses these same checks without retaining nine chapters'
        // accessibility snapshots in the simulator's UI-test runner.
        let requestedWorlds = ProcessInfo.processInfo.environment["DINO_TEST_WORLD_IDS"]?
            .split(separator: ",").compactMap { Int($0) }.filter { (2...10).contains($0) } ?? []
        let completedCounts = requestedWorlds.isEmpty ? Array(1...9) : Array(Set(requestedWorlds)).sorted().map { $0 - 1 }
        for completed in completedCounts {
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
            var rng = SeededGenerator(seed: seed)
            let q = DinoQuestionGenerator.generate(level: DinoLevelCatalog.level(first)!, using: &rng)[0]
            let firstAnswer = q.kind == .match ? "question.match.clock.0" : "question.option.0"
            XCTAssertTrue(app.buttons[firstAnswer].waitForExistence(timeout: 5))
            let hudWorld = app.descendants(matching: .any)["header.world.\(completed + 1)"]
            XCTAssertTrue(hudWorld.exists)
            if completed == 1 { XCTAssertEqual(q.target.minute, 30) }
            if q.kind == .match {
                connectMatchingQuestion(q, correct: true)
            } else {
                let option = q.responses.firstIndex(of: q.expectedAnswer)!
                tap("question.option.\(option)")
            }
            XCTAssertTrue(app.staticTexts["2/5"].waitForExistence(timeout: 8))
            XCTAssertTrue(hudWorld.exists)
            saveScreenshot("native-world-\(completed + 1)-question")
        }
    }

    func testCityMetroRouteRemainsPlayable() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "5"
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 8))
        waitForMapOpeningToFinish()
        let first = revealMapNode(51)
        XCTAssertTrue(first.isEnabled)
        saveScreenshot("city-metro-entrance")
        first.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["level.play"].waitForExistence(timeout: 5))
        tap("level.play")
        XCTAssertTrue(app.buttons["question.option.0"].waitForExistence(timeout: 5))
        saveScreenshot("city-metro-level-51")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 8))
        waitForMapOpeningToFinish()
        for id in [54, 57, 60] {
            let node = revealMapNode(id)
            XCTAssertGreaterThanOrEqual(node.frame.width, 44)
            saveScreenshot("city-metro-route-\(id)")
            if id == 60 {
                XCTAssertTrue(node.isEnabled)
                node.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                XCTAssertTrue(app.buttons["level.play"].waitForExistence(timeout: 5))
            }
        }
    }

    func testTimeMachineWorkshopRouteRemainsPlayable() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "7"
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 8))
        waitForMapOpeningToFinish()
        let first = revealMapNode(71)
        XCTAssertTrue(first.isEnabled)
        saveScreenshot("time-machine-entrance")
        // No scrolling between these captures: differences belong to machinery.
        Thread.sleep(forTimeInterval: 1.2)
        saveScreenshot("time-machine-entrance-motion")
        first.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["level.play"].waitForExistence(timeout: 5))
        tap("level.play")
        let clock = app.descendants(matching: .any)["question.analogControl"].firstMatch
        XCTAssertTrue(clock.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["question.confirm"].isHittable)
        saveScreenshot("time-machine-level-71")

        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 8))
        waitForMapOpeningToFinish()
        for id in [74, 77, 80] {
            let node = revealMapNode(id)
            XCTAssertGreaterThanOrEqual(node.frame.width, 44)
            saveScreenshot("time-machine-route-\(id)")
            if id == 80 {
                XCTAssertTrue(node.isEnabled)
                node.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                XCTAssertTrue(app.buttons["level.play"].waitForExistence(timeout: 5))
            }
        }
    }

    func testWorldBossSceneryRemainsPlayable() {
        let requested = ProcessInfo.processInfo.environment["DINO_TEST_WORLD_IDS"]?
            .split(separator: ",").compactMap { Int($0) }.filter { (1...10).contains($0) } ?? []
        for world in requested.isEmpty ? Array(1...10) : requested {
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.scenery-depth.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = String(world * 10 - 1)
            app.launch()
            XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 8))
            let boss = revealMapNode(world * 10)
            XCTAssertTrue(boss.isEnabled)
            XCTAssertGreaterThanOrEqual(boss.frame.width, 44)
            saveScreenshot("scenery-depth-world-\(world)")
            boss.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(app.buttons["level.play"].waitForExistence(timeout: 5),
                          "Sorted scenery must leave the world \(world) boss playable")
        }
    }

    func testWorldBannersHaveBalancedClearance() {
        let requested = ProcessInfo.processInfo.environment["DINO_TEST_WORLD_IDS"]?
            .split(separator: ",").compactMap { Int($0) }.filter { (2...10).contains($0) } ?? []
        for world in requested.isEmpty ? [2, 4, 5, 6, 9, 10] : requested {
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.banner-spacing.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = String(world - 1)
            app.launch()
            XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 8))
            let first = revealMapNode((world - 1) * 10 + 1)
            let boss = app.buttons["map.level.\((world - 1) * 10)"]
            // SwiftUI passes the banner identifier to all three text labels.
            // Measure the central title, whose centre matches the sign's face.
            let banner = app.staticTexts.matching(identifier: "map.world.\(world)").element(boundBy: 1)
            XCTAssertTrue(boss.exists && banner.exists)
            let above = banner.frame.minY - boss.frame.maxY
            let below = first.frame.minY - banner.frame.maxY
            XCTAssertGreaterThan(above, 40, "Boss leaves room above world \(world)")
            // Accessibility reports the title's glyph bounds, whose centre can
            // sit a few points below the centre of the fixed banner face.
            XCTAssertEqual(above, below, accuracy: 8,
                           "World \(world) uses the same clear space on both sides of its banner")
            saveScreenshot("world-banner-spacing-\(world)")
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
        if app.buttons["question.showAnswer"].exists { tap("question.showAnswer") }
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
        let world = { (id: Int) in self.app.descendants(matching: .any)["header.world.\(id)"] }
        let levelCount = app.buttons["header.level"]
        XCTAssertTrue(world(10).waitForExistence(timeout: 8))
        XCTAssertTrue(levelCount.label.hasSuffix("90"))
        saveScreenshot("hud-world-10-level-90")

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.04)).tap()
        for _ in 0..<45 {
            if world(1).exists { break }
            app.swipeDown(velocity: .fast)
        }
        XCTAssertTrue(world(1).exists)
        XCTAssertTrue(levelCount.label.hasSuffix("90"))
        // Finish revealing the top, rather than capturing the preceding transition.
        app.swipeDown(velocity: .fast)
        saveScreenshot("hud-world-1-level-90")

        for _ in 0..<14 {
            if world(2).exists { break }
            app.swipeUp(velocity: .slow)
        }
        XCTAssertTrue(world(2).exists)
        XCTAssertTrue(levelCount.label.hasSuffix("90"))
        saveScreenshot("hud-world-2-level-90")
        for _ in 0..<10 {
            if world(1).exists { break }
            app.swipeDown()
        }
        XCTAssertTrue(world(1).exists)
        XCTAssertTrue(levelCount.label.hasSuffix("90"))
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
        XCTAssertTrue(app.descendants(matching: .any)["header.questions"].label.contains("Vraag"))
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
        tap("settings.language")
        tap("language.option.en")
        let reset = app.buttons["settings.reset"]
        for _ in 0..<6 { if reset.isHittable { break }; app.swipeUp() }
        tap("settings.reset")
        XCTAssertTrue(app.staticTexts["settings.reset.equation"].waitForExistence(timeout: 5))
        saveScreenshot("reset-all-data-confirmation")
        confirmProgressReset()
        let closed = NSPredicate { _, _ in self.app.state == .notRunning }
        expectation(for: closed, evaluatedWith: nil)
        waitForExpectations(timeout: 8)
        app.launch()
        XCTAssertTrue(app.buttons["onboarding.next"].waitForExistence(timeout: 5))
        saveScreenshot("reset-fresh-welcome")
        tap("onboarding.next"); tap("onboarding.next"); tap("onboarding.customClock")
        XCTAssertEqual(app.descendants(matching: .any)["header.starCount"].label, "0")
        XCTAssertEqual(app.descendants(matching: .any)["header.levelCount"].label, "1")
        openSettings()
        for (id, value) in [("soundEffects", "1"), ("haptics", "1"), ("highContrast", "0"), ("icloudSync", "0")] {
            XCTAssertEqual(app.descendants(matching: .any)["settings.\(id)"].switches.firstMatch.value as? String, value)
        }
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
    }

    func testClockAnswerFeedbackKeepsItsStageAndTargetInPlace() {
        openPractice()
        for kind in [DinoPracticeQuestion.setDigital, .setAnalog, .advanceAnalog] {
            selectPractice("practice.type.\(kind.rawValue)")
            tap("practice.start")
            let title = app.staticTexts["question.title"]
            let targetID = kind == .advanceAnalog ? "question.startClock" : "question.targetClock"
            let target = app.descendants(matching: .any)[targetID]
            let controlID = kind == .setDigital ? "question.digitalControl" : "question.analogControl"
            let control = app.descendants(matching: .any)[controlID]
            let confirm = app.buttons["question.confirm"]
            XCTAssertTrue(confirm.waitForExistence(timeout: 5))
            XCTAssertTrue(confirm.isHittable)
            let titleFrame = title.frame
            let targetFrame = target.frame
            let controlFrame = control.frame
            let submittedValue = control.label
            saveScreenshot("feedback-\(kind.rawValue)-before")
            confirm.tap()
            let correct = app.descendants(matching: .any)["question.correctClock"]
            XCTAssertTrue(correct.waitForExistence(timeout: 5))
            XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
            XCTAssertEqual(title.frame.minY, titleFrame.minY, accuracy: 1, "Feedback must not recenter the question")
            XCTAssertEqual(target.frame.minY, targetFrame.minY, accuracy: 1)
            XCTAssertEqual(target.frame.width, targetFrame.width, accuracy: 1, "The prompt clock keeps its size")
            XCTAssertEqual(control.label, submittedValue, "The submitted clock keeps its value")
            XCTAssertEqual(app.descendants(matching: .any).matching(identifier: controlID).count, 1)
            XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "question.correctClock").count, 1)
            XCTAssertFalse(app.buttons["question.confirm"].exists)
            if kind == .advanceAnalog {
                XCTAssertLessThan(control.frame.maxY, correct.frame.minY)
            } else {
                XCTAssertEqual(control.frame.midY, controlFrame.midY, accuracy: 1, "The submitted clock does not rise from below")
                XCTAssertLessThan(control.frame.midX, correct.frame.midX)
            }
            XCTAssertTrue(correct.frame.intersects(app.scrollViews["game.questions"].frame))
            saveScreenshot("feedback-\(kind.rawValue)-after")
            tap("question.next")
            XCTAssertTrue(app.buttons["question.confirm"].waitForExistence(timeout: 5))
            tap("header.pause")
        }
    }

    func testSortingReservesDraftAndCorrectionBeforeTheFirstTap() {
        openPractice()
        selectPractice("practice.type.sortTimes")
        tap("practice.start")
        let title = app.staticTexts["question.title"]
        let confirm = app.buttons["question.confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        XCTAssertEqual(confirm.label, "Controleer mijn volgorde")
        let titleY = title.frame.minY
        let confirmY = confirm.frame.minY
        let frames = (0..<4).map { app.buttons["question.sort.\($0)"].frame }
        let indices = (0..<4).sorted {
            app.buttons["question.sort.\($0)"].label > app.buttons["question.sort.\($1)"].label
        }
        saveScreenshot("feedback-sorting-empty")
        for (count, index) in indices.enumerated() {
            tap("question.sort.\(index)")
            XCTAssertEqual(title.frame.minY, titleY, accuracy: 1)
            XCTAssertEqual(confirm.frame.minY, confirmY, accuracy: 1, "Building the sequence must not push Confirm down")
            if count == 0 { saveScreenshot("feedback-sorting-first-selection") }
        }
        confirm.tap()
        XCTAssertTrue(app.staticTexts["question.sort.correct"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
        XCTAssertEqual(title.frame.minY, titleY, accuracy: 1)
        for index in 0..<4 {
            XCTAssertEqual(app.buttons["question.sort.\(index)"].frame.midY, frames[index].midY, accuracy: 1)
        }
        saveScreenshot("feedback-sorting-corrected")
    }

    func testSortingFeedbackKeepsCorrectPositionsGreen() {
        openPractice()
        selectPractice("practice.type.sortTimes")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.sortTimes)), seed: seed)
        let question = generator.next(index: 0)
        let ordered = question.options.sorted { $0.minutesOfDay < $1.minutesOfDay }
        let submitted = [ordered[0], ordered[2], ordered[1], ordered[3]]
        let indices = submitted.map { question.options.firstIndex(of: $0)! }
        for (position, index) in indices.enumerated() {
            tap("question.sort.\(index)")
            XCTAssertEqual(app.buttons["question.sort.\(index)"].value as? String, String(position + 1))
        }
        tap("question.confirm")
        XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
        for (position, index) in indices.enumerated() {
            let verdict = position == 0 || position == 3 ? "Goed" : "Fout"
            XCTAssertEqual(app.buttons["question.sort.\(index)"].value as? String, "\(position + 1), \(verdict)")
            XCTAssertFalse(app.buttons["question.sort.\(index)"].isEnabled)
        }
        XCTAssertTrue(app.staticTexts["question.sort.correct"].exists)
        saveScreenshot("sorting-feedback-mixed-correct-positions")
    }

    func testWorkedAnswersKeepTheOptionsInPlace() {
        openPractice()
        for kind in [DinoPracticeQuestion.daySchedule, .timeZone, .flightArrival] {
            selectPractice("practice.type.\(kind.rawValue)")
            tap("practice.start")
            var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(kind)), seed: seed)
            let question = generator.next(index: 0)
            let scroll = app.scrollViews["game.questions"]
            let lastOption = app.buttons["question.option.\(question.responses.count - 1)"]
            XCTAssertTrue(lastOption.waitForExistence(timeout: 5))
            for _ in 0..<4 {
                if lastOption.isHittable && lastOption.frame.maxY <= scroll.frame.maxY { break }
                scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.8))
                    .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.4)))
            }
            let frames = question.responses.indices.map { app.buttons["question.option.\($0)"].frame }
            let wrongIndex = question.responses.firstIndex { $0 != question.expectedAnswer }!
            tap("question.option.\(wrongIndex)")
            let canRetry = question.responses.count > 2
            XCTAssertTrue(app.buttons[canRetry ? "question.showAnswer" : "question.next"].waitForExistence(timeout: 5))
            for index in question.responses.indices {
                XCTAssertEqual(app.buttons["question.option.\(index)"].frame.midY, frames[index].midY, accuracy: 1)
            }
            if canRetry { tap("question.showAnswer") }
            XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
            // Flight and zone arithmetic keep animating after the reveal.
            RunLoop.current.run(until: Date().addingTimeInterval(1))
            for index in question.responses.indices {
                XCTAssertEqual(app.buttons["question.option.\(index)"].frame.midY, frames[index].midY, accuracy: 1)
            }
            saveScreenshot("feedback-\(kind.rawValue)-worked")
            tap("header.pause")
        }
    }

    func testMinutesBetweenQuestionAndExample() {
        checkMinutesBetweenQuestionAndExample(language: "nl", family: .whole)
    }

    func testMinutesBetweenEnglishQuarterHours() {
        checkMinutesBetweenQuestionAndExample(language: "en", family: .quarter)
    }

    func testMinutesBetweenDutchQuarterHours() {
        checkMinutesBetweenQuestionAndExample(language: "nl", family: .quarter)
    }

    private func checkMinutesBetweenQuestionAndExample(language: String, family: DinoPracticeTime) {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launchArguments = ["-settings.languageOverride", language]
        app.launch()
        tap("header.practice")
        tap("practice.time.\(family.rawValue)")
        selectPractice("practice.type.minutesBetween")
        XCTAssertEqual(app.buttons["practice.type.minutesBetween"].label,
                       language == "nl" ? "Bereken het verschil in minuten" : "Calculate the difference in minutes")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: family, order: .specific(.minutesBetween)), seed: seed)
        let q = generator.next(index: 0)
        let start = app.descendants(matching: .any)["question.minutesBetween.start"]
        let end = app.descendants(matching: .any)["question.minutesBetween.end"]
        XCTAssertEqual(start.label, q.relatedTimes[0].digitalText)
        XCTAssertEqual(end.label, q.relatedTimes[1].digitalText)
        XCTAssertEqual(app.staticTexts["question.title"].label,
                       language == "nl" ? "Hoeveel minuten zitten ertussen?" : "How many minutes are there in between?")
        XCTAssertTrue(app.descendants(matching: .any)["question.minutesBetween.unknown"].exists)
        XCTAssertFalse(app.staticTexts["Beide tijden zijn op dezelfde dag."].exists)
        XCTAssertFalse(app.staticTexts["Both times are on the same day."].exists)
        XCTAssertFalse(app.descendants(matching: .any)["demo.minutesBetween.calculation"].exists)
        for (index, answer) in q.responses.enumerated() {
            guard case .duration(let minutes) = answer else { return XCTFail("Expected minutes") }
            XCTAssertEqual(app.buttons["question.option.\(index)"].label, DinoTimeWords.minutes(minutes, language: language))
            XCTAssertTrue(app.buttons["question.option.\(index)"].isHittable, "All four minute choices fit on screen")
        }
        saveScreenshot("minutes-between-question-\(language)")
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
            XCTAssertTrue(start.waitForExistence(timeout: 5))
            saveScreenshot("minutes-between-landscape")
            XCUIDevice.shared.orientation = .portrait
        }
        tap("question.example")
        let example = DinoDemonstrationExamples.question(kind: .minutesBetween, minutes: family.minutes,
                                                        minuteStep: family.minuteStep, index: 0, previousTarget: nil)
        let demoAnswer = app.descendants(matching: .any)["demo.answer"]
        XCTAssertTrue(demoAnswer.waitForExistence(timeout: 5))
        XCTAssertEqual(demoAnswer.label, DinoTimeWords.minutes(example.durationMinutes, language: language))
        assertMinutesBetweenCalculation(example, language: language)
        saveScreenshot("minutes-between-example-\(language)")
        tap("demo.nextExample")
        let refreshed = DinoDemonstrationExamples.question(kind: .minutesBetween, minutes: family.minutes,
                                                          minuteStep: family.minuteStep, index: 1, previousTarget: example.target)
        XCTAssertEqual(app.descendants(matching: .any)["demo.minutesBetween.end"].label, refreshed.target.digitalText)
        XCTAssertEqual(demoAnswer.label, DinoTimeWords.minutes(refreshed.durationMinutes, language: language))
        assertMinutesBetweenCalculation(refreshed, language: language)
        if family == .quarter {
            var latest = refreshed
            var sawBorrowing = refreshed.relatedTimes[1].minute < refreshed.relatedTimes[0].minute
            for index in 2..<10 where !sawBorrowing {
                tap("demo.nextExample")
                latest = DinoDemonstrationExamples.question(kind: .minutesBetween, minutes: family.minutes,
                    minuteStep: family.minuteStep, index: index, previousTarget: latest.target)
                assertMinutesBetweenCalculation(latest, language: language)
                sawBorrowing = latest.relatedTimes[1].minute < latest.relatedTimes[0].minute
            }
            XCTAssertTrue(sawBorrowing, "A worked example shows how to borrow an hour")
            saveScreenshot("minutes-between-borrowing-\(language)")
        }
        tap("demo.ready")
        XCTAssertEqual(start.label, q.relatedTimes[0].digitalText, "Examples preserve the live question")
        let wrong = q.responses.firstIndex { $0 != q.expectedAnswer }!
        tap("question.option.\(wrong)")
        XCTAssertTrue(app.buttons["question.showAnswer"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["question.minutesBetween.unknown"].exists)
        tap("question.showAnswer")
        XCTAssertEqual(app.descendants(matching: .any)["question.minutesBetween.answer"].label,
                       DinoTimeWords.minutes(q.durationMinutes, language: language))
        XCTAssertGreaterThan(app.staticTexts["question.title"].frame.minY,
                             app.descendants(matching: .any)["practice.hudSubtitle"].frame.maxY,
                             "The question stays below the header during feedback")
        saveScreenshot("minutes-between-answer-\(language)")
        tap("question.next")
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "2")
    }

    private func assertMinutesBetweenCalculation(_ question: ClockQuestion, language: String) {
        let subtraction = app.staticTexts["demo.minutesBetween.subtraction"]
        XCTAssertTrue(subtraction.waitForExistence(timeout: 5))
        XCTAssertEqual(subtraction.label, "\(question.relatedTimes[1].digitalText) − \(question.relatedTimes[0].digitalText)")
        let hours = question.durationMinutes / 60, minutes = question.durationMinutes % 60
        XCTAssertEqual(app.staticTexts["demo.minutesBetween.remainder"].label,
                       "= \(hours) \(language == "nl" ? "uur" : "h") \(minutes) min")
        XCTAssertEqual(app.staticTexts["demo.minutesBetween.conversion"].label,
                       "\(hours) × 60 + \(minutes) = \(DinoTimeWords.minutes(question.durationMinutes, language: language))")
        XCTAssertEqual(app.staticTexts["demo.minutesBetween.borrow"].exists,
                       question.relatedTimes[1].minute < question.relatedTimes[0].minute)
        XCTAssertFalse(app.staticTexts["Beide tijden zijn op dezelfde dag."].exists)
        XCTAssertFalse(app.staticTexts["Both times are on the same day."].exists)
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

    func testJungleContinuousScroll() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "3"
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["map.level.3"].exists)
        saveScreenshot("jungle-continuous-scroll-start")
        // Short, slow drags keep the water, wildlife and tile joins in view.
        // A simulator recording of this test checks intermediate frames too.
        for step in 0..<6 {
            let upward = step.isMultiple(of: 2)
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.54, dy: upward ? 0.72 : 0.48))
                .press(forDuration: 0.05,
                       thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.54, dy: upward ? 0.48 : 0.72)),
                       withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        XCTAssertTrue(app.buttons["header.settings"].isHittable)
        XCTAssertEqual(app.descendants(matching: .any)["header.levelCount"].label, "3")
        saveScreenshot("jungle-continuous-scroll-return")
    }

    func testColdLaunchMapKeepsItsFirstVisiblePosition() {
        for completed in [0, 3, 90] {
            app.terminate()
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
            app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = String(completed)
            app.launch()
            // Also exercise a cold cache with the player's own Dino colors.
            if completed == 3 {
                waitForMapOpeningToFinish()
                tap("header.dino")
                tap("personalize.bandana.blue"); tap("personalize.spikes.purple")
                tap("personalize.done")
            }
            app.terminate()
            app.launch()
            let target = app.buttons["map.level.\(completed + 1)"]
            XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 10))
            waitForMapOpeningToFinish()
            XCTAssertTrue(target.isHittable, "The saved level must be visible in the first usable map frame")
            XCTAssertFalse(app.descendants(matching: .any)["map.preparing"].exists)
            let first = target.frame
            let header = app.buttons["header.settings"].frame
            for _ in 0..<5 {
                XCTAssertEqual(target.frame.midY, first.midY, accuracy: 1, "The map must not jump after becoming visible")
                XCTAssertEqual(app.buttons["header.settings"].frame.midY, header.midY, accuracy: 1)
            }
            saveScreenshot("cold-launch-stable-level-\(completed + 1)")
        }
    }

    func testPreparedMapArtworkStaysStableDuringScrolling() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "34"
        app.launchEnvironment["DINO_TEST_MAP_DIAGNOSTICS"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 15))
        waitForMapOpeningToFinish()
        let count = app.staticTexts["map.rasterizationCount"]
        XCTAssertTrue(count.exists)
        let preparedCount = count.label
        for _ in 0..<4 {
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.53))
            start.press(forDuration: 0.05, thenDragTo: end)
            end.press(forDuration: 0.05, thenDragTo: start)
            XCTAssertEqual(count.label, preparedCount, "Scrolling must reuse the prepared terrain instead of repainting it")
        }
        saveScreenshot("prepared-village-after-repeated-scroll")
    }

    func testMapScrollPerformance() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launch()
        XCTAssertTrue(app.buttons["map.bossShortcut"].waitForExistence(timeout: 8))
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(application: app),
                          XCTMemoryMetric(application: app), XCTOSSignpostMetric.scrollingAndDecelerationMetric],
                options: options) {
            for _ in 0..<4 { app.swipeUp(velocity: .fast) }
            for _ in 0..<4 { app.swipeDown(velocity: .fast) }
        }
        XCTAssertTrue(app.buttons["header.settings"].isHittable)
        saveScreenshot("performance-map-after-fast-scroll")
    }

    func testPracticeHUDRecordsAndPersistentCounter() {
        openPractice()
        XCTAssertFalse(app.staticTexts["Van makkelijk naar moeilijk"].exists)
        selectPractice("practice.type.chooseAnalog")
        XCTAssertEqual(app.descendants(matching: .any)["practice.type.chooseAnalog.record"].label, "0")
        saveScreenshot("practice-update-overview")
        tap("practice.start")
        XCTAssertTrue(app.descendants(matching: .any)["header.dino"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["header.streak"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["header.questions"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["header.questions"].label.contains("Vraag"))
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
            XCTAssertEqual(app.descendants(matching: .any)["practice.bestStreak"].label, String(index + 1))
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
        XCTAssertTrue(app.buttons["question.example"].isEnabled, "The example stays available while the answer is showing")
        saveScreenshot("practice-followup-feedback-hud")
        XCTAssertEqual(app.staticTexts["practice.streak"].label, "2", "Feedback keeps the streak and question counters together")
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "3")
        XCTAssertEqual(app.descendants(matching: .any)["practice.bestStreak"].label, "2")
        RunLoop.current.run(until: Date().addingTimeInterval(1))
        XCTAssertEqual(app.staticTexts["practice.streak"].label, "2")
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "3")
        saveScreenshot("practice-hud-feedback-counters-held")
        tap("question.next")
        XCTAssertEqual(app.staticTexts["practice.streak"].label, "0")
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "4")
        saveScreenshot("practice-hud-counters-advanced-together")
        tap("header.pause")
        XCTAssertEqual(app.descendants(matching: .any)["practice.type.chooseAnalog.record"].label, "2")
        tap("practice.time.half")
        XCTAssertEqual(app.descendants(matching: .any)["practice.type.chooseAnalog.record"].label, "0")
        tap("practice.close")
        app.terminate(); app.launch()
        tap("header.practice")
        selectPractice("practice.type.chooseAnalog")
        tap("practice.start")
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "4")
        XCTAssertEqual(app.staticTexts["practice.streak"].label, "0")
        XCTAssertEqual(app.descendants(matching: .any)["practice.bestStreak"].label, "2")
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

    func testPracticeAscendingAndMixHavePersistentTrophies() {
        // Keep this interaction focused on two answer choices in each mode.
        let testSeed = (1...100).map { UInt64($0) }.first { candidate in
            var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .mix), seed: candidate)
            return generator.next(index: 0).kind.usesOptions && generator.next(index: 1).kind.usesOptions
        }!
        app.terminate()
        app.launchEnvironment["DINO_TEST_SEED"] = String(testSeed)
        app.launch()
        openPractice()
        for (name, order) in [("ascending", DinoPracticeOrder.ascending), ("mix", .mix)] {
            let identifier = "practice.order.\(name)"
            selectPractice(identifier)
            XCTAssertFalse(app.buttons["practice.ascending.info"].exists)
            XCTAssertFalse(app.alerts.firstMatch.exists)
            XCTAssertEqual(app.descendants(matching: .any)["\(identifier).record"].label, "0")
            tap("practice.start")
            var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: order), seed: testSeed)
            for index in 0..<2 {
                let question = generator.next(index: index)
                tap("question.option.\(question.responses.firstIndex(of: question.expectedAnswer)!)")
                XCTAssertTrue(app.staticTexts.matching(identifier: "practice.questionNumber")
                    .matching(NSPredicate(format: "label == %@", String(index + 2))).firstMatch.waitForExistence(timeout: 6))
                XCTAssertEqual(app.staticTexts["practice.streak"].label, String(index + 1))
                XCTAssertEqual(app.descendants(matching: .any)["practice.bestStreak"].label, String(index + 1))
            }
            tap("header.pause")
            selectPractice(identifier)
            XCTAssertEqual(app.descendants(matching: .any)["\(identifier).record"].label, "2")
            saveScreenshot("practice-\(name)-trophy")
            tap("practice.start")
            XCTAssertEqual(app.staticTexts["practice.streak"].label, "2")
            XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "3")
            tap("header.pause")
        }
        tap("practice.close")
        app.terminate(); app.launch()
        tap("header.practice")
        selectPractice("practice.order.ascending")
        XCTAssertEqual(app.descendants(matching: .any)["practice.order.ascending.record"].label, "2")
        selectPractice("practice.order.mix")
        XCTAssertEqual(app.descendants(matching: .any)["practice.order.mix.record"].label, "2")
        saveScreenshot("practice-mode-trophies-after-relaunch")
    }

    func testPracticeThousandCounterWithoutAscendingPopup() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_PRACTICE_ANSWERS"] = "998"
        app.launch()
        openPractice()
        selectPractice("practice.order.ascending")
        XCTAssertFalse(app.buttons["practice.ascending.info"].exists)
        XCTAssertFalse(app.alerts.firstMatch.exists)
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

    func testCurriculumMixedTimesAndBossOutline() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "10"
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 8))
        revealMapNode(11).tap()
        tap("level.details")
        let combinations = app.buttons.matching(NSPredicate(format: "identifier MATCHES %@", "level.question.[0-9]+"))
        XCTAssertEqual(combinations.count, 3)
        XCTAssertTrue(combinations.element(boundBy: 0).label.contains("Halve uren"))
        XCTAssertTrue(combinations.element(boundBy: 1).label.contains("Hele uren"))
        saveScreenshot("curriculum-mixed-time-outline")
        tap("level.play")
        let level = DinoLevelCatalog.level(11)!
        let difficulties = Dictionary(uniqueKeysWithValues: level.recipes.map { (level.skill(for: $0), DinoQuestionDifficulty.introduction) })
        var rng = SeededGenerator(seed: seed)
        let questions = DinoQuestionGenerator.generate(level: level, difficulties: difficulties, using: &rng)
        for index in 0..<2 {
            XCTAssertTrue(app.staticTexts["\(index + 1)/5"].waitForExistence(timeout: 6))
            tap("question.example")
            tap("demo.nextExample")
            let expected = index == 0 ? "03:30" : "04:00"
            XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "demo.analog")
                .matching(NSPredicate(format: "label == %@", expected)).firstMatch.exists,
                          "The example follows this question's time family rather than the world default")
            tap("demo.ready")
            tap("question.option.\(questions[index].responses.firstIndex(of: questions[index].expectedAnswer)!)")
        }
        XCTAssertTrue(app.staticTexts["3/5"].waitForExistence(timeout: 6))
        app.terminate(); app.launch()
        revealMapNode(10).tap()
        tap("level.details")
        let rows = app.buttons.matching(NSPredicate(format: "identifier MATCHES %@", "level.question.[0-9]+"))
        XCTAssertEqual(rows.count, 10)
        XCTAssertEqual(Set(rows.allElementsBoundByIndex.map(\.label)).count, 10,
                       "The boss lists ten distinct time-and-question combinations")
        saveScreenshot("curriculum-ten-distinct-boss-questions")
    }

    func testExactMinutesAndHiddenDifficultyProgression() {
        openPractice()
        tap("practice.time.minutes")
        XCTAssertTrue(app.staticTexts["Minuten"].exists)
        selectPractice("practice.type.chooseDigital")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .minutes, order: .specific(.chooseDigital)), seed: seed)
        var progress = DinoLearningProgress()
        for index in 0..<8 {
            let difficulty = progress.difficulty
            let q = generator.next(index: index, difficultyForKind: { _ in difficulty })
            let counter = app.staticTexts.matching(identifier: "header.questions")
                .matching(NSPredicate(format: "label == %@", String(index + 1))).firstMatch
            XCTAssertTrue(counter.waitForExistence(timeout: 6))
            let options = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option."))
            XCTAssertEqual(options.count, difficulty.optionCount)
            XCTAssertTrue(app.staticTexts.matching(identifier: "practice.hudSubtitle")
                .matching(NSPredicate(format: "label == %@", "Minuten")).firstMatch.exists)
            XCTAssertFalse(app.staticTexts["introduction"].exists)
            XCTAssertFalse(app.staticTexts["familiar"].exists)
            XCTAssertFalse(app.staticTexts["challenge"].exists)
            // Six first-attempt successes reach challenge; an error must immediately offer a lighter question.
            let correct = index != 6
            let answerIndex = q.responses.firstIndex { correct ? $0 == q.expectedAnswer : $0 != q.expectedAnswer }!
            tap("question.option.\(answerIndex)")
            progress.record(correct: correct, at: difficulty)
            if !correct {
                tap("question.showAnswer")
                tap("question.next")
                XCTAssertEqual(progress.difficulty, .familiar)
            }
        }
        XCTAssertTrue(app.staticTexts.matching(identifier: "header.questions")
            .matching(NSPredicate(format: "label == %@", "9")).firstMatch.waitForExistence(timeout: 6))
        tap("header.pause")
        selectPractice("practice.type.setDigital")
        tap("practice.start")
        tap("clock.minute.more")
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@ OR label == %@", "12:01", "01:01")).firstMatch.exists,
                      "Minutes uses one-minute input steps")
        saveScreenshot("practice-exact-minutes-hidden-difficulty")
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
            XCTAssertTrue(app.staticTexts.matching(identifier: "header.questions")
                .matching(NSPredicate(format: "label == %@", "\(index + 1)")).firstMatch.exists)
            XCTAssertTrue(app.buttons["clock.minute.more"].exists)
            // Initial hours deliberately differ, so this tests feedback and Next indefinitely.
            tap("question.confirm")
            XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "question.correctClock").firstMatch.waitForExistence(timeout: 4))
            if index == 0 { saveScreenshot("practice-digital-comparison") }
            tap("question.next")
            XCTAssertTrue(app.staticTexts.matching(identifier: "header.questions")
                .matching(NSPredicate(format: "label == %@", "\(index + 2)")).firstMatch.waitForExistence(timeout: 4))
        }
        XCTAssertTrue(app.staticTexts.matching(identifier: "header.questions")
            .matching(NSPredicate(format: "label == %@", "13")).firstMatch.exists)
        XCTAssertFalse(app.buttons["result.map"].exists)
        tap("header.pause")
        XCTAssertTrue(app.buttons["practice.start"].waitForExistence(timeout: 5))
    }

    func testExampleHintsStayBlackAndConnectedWithWhiteHands() {
        onboard()
        tap("header.dino")
        tap("personalize.page.analog")
        tap("theme.dino.face.black")
        chooseClockCustomColor("hourHand", hex: "FFFFFF")
        chooseClockCustomColor("minuteHand", hex: "FFFFFF")
        tap("personalize.page.digital")
        tap("personalize.done")
        begin(1)
        tap("question.example")
        XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 5))
        let digital = app.descendants(matching: .any)["demo.digital"]
        let analog = app.descendants(matching: .any)["demo.analog"]
        XCTAssertEqual(digital.label, "03:00")
        XCTAssertTrue(analog.exists)
        saveScreenshot("example-connected-white-hand-hints")
        tap("demo.nextExample")
        XCTAssertEqual(digital.label, "04:00")
        saveScreenshot("example-connected-white-hand-hints-four")
        tap("demo.ready")
        XCTAssertTrue(app.staticTexts["1/5"].exists)
        tap("header.dino")
        tap("personalize.page.analog")
        tap("theme.resetAnalogStyle")
        tap("personalize.done")
        tap("question.example")
        XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 5))
        saveScreenshot("example-connected-original-hand-hints")
        tap("demo.ready")
        XCTAssertTrue(app.staticTexts["1/5"].exists)
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

    func testTimeZoneAtlasCapitalsAndAnswerReveal() {
        openPractice()
        selectPractice("practice.type.timeZone")
        for family in [DinoPracticeTime.whole, .quarter, .fiveMinutes] {
            chooseExampleTimeFamily(family.rawValue)
            tap("practice.start")
            var generator = DinoPracticeGenerator(configuration: .init(time: family, order: .specific(.timeZone)), seed: seed)
            let question = generator.next(index: 0)
            let city = question.timeZoneJourney!.destination.name(language: "nl")
            XCTAssertEqual(app.staticTexts["question.title"].label, "Hoe laat is het in \(city)?")
            let origin = app.descendants(matching: .any)["question.timeZone.origin"]
            let destination = app.descendants(matching: .any)["question.timeZone.destination"]
            let map = app.descendants(matching: .any)["question.timeZone.map"]
            XCTAssertTrue(map.waitForExistence(timeout: 5))
            XCTAssertFalse(app.staticTexts["TIJDZONES"].exists)
            XCTAssertFalse(app.staticTexts["Vereenvoudigde tijdzones"].exists)
            XCTAssertFalse(app.staticTexts["24-uursklok"].exists)
            XCTAssertTrue(origin.label.contains("Amsterdam") && origin.label.contains(question.relatedTimes[0].digitalText))
            XCTAssertTrue(destination.label.contains(city) && destination.label.contains("?"))
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option.")).count, 4)
            XCTAssertGreaterThanOrEqual(origin.frame.minX, map.frame.minX)
            XCTAssertLessThanOrEqual(destination.frame.maxX, map.frame.maxX)
            saveScreenshot("time-zone-atlas-\(family.rawValue)-nl")
            if family == .fiveMinutes && UIDevice.current.userInterfaceIdiom == .pad {
                XCUIDevice.shared.orientation = .landscapeLeft
                RunLoop.current.run(until: Date().addingTimeInterval(0.8))
                XCTAssertTrue(map.isHittable)
                let viewport = app.scrollViews["game.questions"].frame
                XCTAssertGreaterThanOrEqual(app.staticTexts["question.title"].frame.minY, viewport.minY)
                XCTAssertLessThanOrEqual(app.buttons["question.option.3"].frame.maxY, viewport.maxY)
                saveScreenshot("time-zone-atlas-worldwide-landscape")
                XCUIDevice.shared.orientation = .portrait
            }
            tap("question.example")
            XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 5))
            let example = DinoDemonstrationExamples.question(kind: .timeZone, minutes: family.minutes,
                                                             minuteStep: family.minuteStep, index: 0, previousTarget: nil)
            waitForTimeZoneWalk(example)
            saveScreenshot("time-zone-atlas-example-\(family.rawValue)")
            tap("demo.nextExample")
            let nextExample = DinoDemonstrationExamples.question(kind: .timeZone, minutes: family.minutes,
                                                                 minuteStep: family.minuteStep, index: 1,
                                                                 previousTarget: example.target)
            waitForTimeZoneWalk(nextExample)
            tap("demo.ready")
            XCTAssertTrue(destination.label.contains("?"), "Examples preserve the unanswered live map")
            let wrongIndex = question.options.firstIndex { $0 != question.target }!
            tap("question.option.\(wrongIndex)")
            XCTAssertTrue(destination.label.contains("?"), "A wrong first attempt does not reveal the time")
            XCTAssertFalse(app.descendants(matching: .any)["question.timeZone.difference"].exists,
                           "The hour walk stays hidden until the right answer follows")
            tap("question.showAnswer")
            XCTAssertTrue(destination.label.contains(question.target.digitalText), "Revealing the answer updates the map")
            let walked = question.timeZoneJourney!.hourSteps(from: question.relatedTimes[0])
            waitUntilLabel("question.timeZone.difference", equals: walked.last!.caption, timeout: Double(walked.count) + 8)
            XCTAssertEqual(app.descendants(matching: .any)["question.timeZone.step.0"].label, question.relatedTimes[0].digitalText)
            XCTAssertEqual(app.descendants(matching: .any)["question.timeZone.result"].label, question.target.digitalText)
            tap("header.pause")
        }
    }

    func testTimeZoneAtlasEnglishUsesLondon() {
        app.terminate()
        app.launchArguments = ["-settings.languageOverride", "en"]
        app.launch()
        openPractice()
        selectPractice("practice.type.timeZone")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.timeZone)), seed: seed, language: "en")
        let question = generator.next(index: 0)
        XCTAssertEqual(app.staticTexts["question.title"].label,
                       "What time is it in \(question.timeZoneJourney!.destination.name(language: "en"))?")
        XCTAssertFalse(app.staticTexts["TIME ZONES"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["question.timeZone.origin"].label.contains("London"))
        XCTAssertTrue(app.descendants(matching: .any)["question.timeZone.destination"].label.contains("?"))
        saveScreenshot("time-zone-atlas-whole-en")
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
        waitUntilLabel("demo.answer", equals: q.target.digitalText, timeout: 8)
        tap("demo.nextExample")
        let next = DinoDemonstrationExamples.question(kind: .timeZone, minutes: [30], minuteStep: 30, index: 1, previousTarget: q.target)
        waitUntilLabel("demo.answer", equals: next.target.digitalText, timeout: 8)
        XCTAssertNotEqual(answer.label, q.target.digitalText)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option.")).count, 0)
        XCTAssertFalse(app.staticTexts["demo.explanation"].exists)
        saveScreenshot("refreshed-time-zone-example")
        tap("demo.ready")
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "1", "Examples do not count as practice answers")
    }

    func testDayScheduleHasTwoActivitiesAndBreak() {
        openPractice()
        tap("practice.time.quarter")
        selectPractice("practice.type.daySchedule")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .quarter, order: .specific(.daySchedule)), seed: seed)
        let question = generator.next(index: 0)
        let schedule = question.daySchedule!
        func element(_ id: String) -> XCUIElement {
            app.descendants(matching: .any).matching(identifier: id).firstMatch
        }
        for (suffix, minutes) in [("activity.1", schedule.firstMinutes), ("break", schedule.breakMinutes), ("activity.2", schedule.secondMinutes)] {
            XCTAssertTrue(element("question.schedule.\(suffix)").waitForExistence(timeout: 5))
            XCTAssertTrue(element("question.schedule.\(suffix)").label.contains("\(minutes) min"))
        }
        XCTAssertTrue(element("question.schedule.start").label.contains(schedule.start.digitalText))
        XCTAssertTrue(element("question.schedule.finish").label.contains("?"), "The end time is the question")
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option.")).count, 4)
        saveScreenshot("day-schedule-question")

        tap("question.example")
        XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 5))
        let example = DinoDemonstrationExamples.question(kind: .daySchedule, minutes: [15, 45], minuteStep: 15, index: 0, previousTarget: nil)
        XCTAssertEqual(element("demo.answer").label, example.target.digitalText)
        XCTAssertTrue(element("demo.schedule.calculation").label.contains("+ \(example.daySchedule!.breakMinutes) min +"))
        for suffix in ["activity.1", "break", "activity.2"] { XCTAssertTrue(element("demo.schedule.\(suffix)").exists) }
        saveScreenshot("day-schedule-example")
        tap("demo.nextExample")
        let next = DinoDemonstrationExamples.question(kind: .daySchedule, minutes: [15, 45], minuteStep: 15, index: 1, previousTarget: example.target)
        XCTAssertEqual(element("demo.answer").label, next.target.digitalText)
        tap("demo.ready")
        XCTAssertTrue(element("question.schedule.start").label.contains(schedule.start.digitalText), "Help preserves the live question")
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "1")

        let wrongIndex = question.options.firstIndex { $0 != question.target }!
        tap("question.option.\(wrongIndex)")
        XCTAssertTrue(element("question.schedule.finish").label.contains("?"), "A retry keeps the end time hidden")
        tap("question.showAnswer")
        XCTAssertTrue(element("question.schedule.finish").label.contains(schedule.end.digitalText))
        saveScreenshot("day-schedule-answer")
        tap("question.next")
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "2")
        XCTAssertTrue(element("question.schedule.finish").label.contains("?"))
    }

    func testExpandedMultipleChoiceExamplesShowOneAnswer() {
        openPractice()
        tap("practice.time.half")
        let types = DinoPracticeQuestion.allCases.filter { $0.recipe.kind.isExpanded && $0.recipe.kind.usesOptions }
        for type in types {
            selectPractice("practice.type.\(type.rawValue)")
            tap("practice.start")
            if [.timeSequence, .addTime, .subtractTime].contains(type) {
                saveScreenshot("question-layout-\(type.rawValue)")
            }
            tap("question.example")
            XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 5))
            if type == .timeZone {
                let example = DinoDemonstrationExamples.question(kind: .timeZone, minutes: [30], minuteStep: 30,
                                                                 index: 0, previousTarget: nil)
                waitUntilLabel("demo.answer", equals: example.target.digitalText, timeout: 8)
            }
            let answers = app.descendants(matching: .any).matching(identifier: "demo.answer")
            XCTAssertEqual(answers.count, 1, "\(type) shows one worked answer")
            XCTAssertFalse(answers.firstMatch.label.isEmpty)
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option.")).count, 0,
                           "\(type) has no distractors in its example")
            XCTAssertFalse(app.staticTexts["demo.explanation"].exists)
            if [.timeSequence, .addTime, .subtractTime].contains(type) {
                saveScreenshot("example-layout-\(type.rawValue)")
            }
            if type == .spokenTime {
                XCTAssertEqual(answers.firstMatch.label, "03:30")
                saveScreenshot("simple-spoken-time-example")
                tap("demo.nextExample")
                XCTAssertEqual(answers.firstMatch.label, "04:30")
            }
            tap("demo.ready")
            let choices = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option."))
            XCTAssertTrue(choices.firstMatch.waitForExistence(timeout: 5))
            XCTAssertGreaterThan(choices.count, 1, "The live \(type) question keeps its normal answer choices")
            XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "1")
            tap("header.pause")
            XCTAssertTrue(app.buttons["practice.start"].waitForExistence(timeout: 5))
        }
    }

    private func waitUntilLabel(_ identifier: String, equals expected: String, timeout: TimeInterval) {
        let element = app.descendants(matching: .any)[identifier]
        let predicate = NSPredicate(format: "exists == 1 AND label == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed,
                       "Expected \(identifier) to read \(expected)")
    }

    private func waitForTimeZoneWalk(_ question: ClockQuestion) {
        let steps = question.timeZoneJourney!.hourSteps(from: question.relatedTimes[0])
        waitUntilLabel("demo.answer", equals: question.target.digitalText, timeout: Double(steps.count) + 8)
        XCTAssertEqual(app.descendants(matching: .any)["demo.timeZone.step.0"].label, question.relatedTimes[0].digitalText)
        XCTAssertEqual(app.descendants(matching: .any)["demo.timeZone.difference"].label, steps.last!.caption)
        XCTAssertTrue(app.descendants(matching: .any)["demo.timeZone.destination"].label.contains(question.target.digitalText))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "demo.answer").count, 1,
                       "One difference chip updates the same result clock")
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
        XCTAssertFalse(app.descendants(matching: .any)["dino.character"].exists)
        saveScreenshot("practice-example-without-dino")
        tap("demo.ready")
        app.buttons["Minuten"].tap()
        let clock = app.descendants(matching: .any)["question.analogControl"]
        clock.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: clock.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.84)))
        saveScreenshot("practice-analog-minutes")
        app.buttons["Uren"].tap()
        let config = DinoPracticeConfiguration(time: .half, order: .specific(.setAnalog))
        var generator = DinoPracticeGenerator(configuration: config, seed: seed)
        let target = generator.next(index: 0).target
        let radians = target.hourAngle * .pi / 180
        clock.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: clock.coordinate(withNormalizedOffset: CGVector(dx: 0.5 + sin(radians) * 0.25, dy: 0.5 - cos(radians) * 0.25)))
        tap("question.confirm")
        XCTAssertTrue(app.staticTexts.matching(identifier: "practice.questionNumber").matching(NSPredicate(format: "label == %@", "2")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["demo.ready"].exists)
        tap("header.pause")
    }

    func testAnalogClockSelectsTheTouchedHandAndUpdatesControls() {
        openPractice()
        tap("practice.time.fiveMinutes")
        selectPractice("practice.type.setAnalog")
        tap("practice.start")
        let clock = app.descendants(matching: .any)["question.analogControl"]
        func time(_ element: XCUIElement) -> ClockTime {
            let parts = element.label.split(separator: ":").map { Int($0)! }
            return ClockTime(hour: parts[0], minute: parts[1])
        }
        func drag(_ element: XCUIElement, from angle: Double, to target: Double, radius: Double) {
            func point(_ degrees: Double) -> XCUICoordinate {
                let radians = degrees * .pi / 180
                return element.coordinate(withNormalizedOffset: CGVector(
                    dx: 0.5 + sin(radians) * radius, dy: 0.5 - cos(radians) * radius))
            }
            point(angle).press(forDuration: 0.15, thenDragTo: point(target))
        }
        let initial = time(clock)
        for _ in 0..<((3 - initial.hour + 12) % 12) { app.buttons["question.analog.more"].tap() }
        XCTAssertEqual(clock.label, "03:00")
        let hours = app.buttons["question.hand.hours"]
        let minutes = app.buttons["question.hand.minutes"]
        XCTAssertEqual(hours.frame.width, minutes.frame.width, accuracy: 1)
        XCTAssertEqual(hours.frame.maxX, minutes.frame.minX, accuracy: 1,
                       "Hours and minutes share one switch without a gap")
        XCTAssertGreaterThanOrEqual(app.buttons["question.confirm"].frame.minY
            - app.buttons["question.analog.more"].frame.maxY, 20)
        XCTAssertTrue(app.buttons["question.hand.hours"].isSelected)
        drag(clock, from: 0, to: 120, radius: 0.31)
        XCTAssertEqual(clock.label, "03:20")
        XCTAssertTrue(app.buttons["question.hand.minutes"].isSelected)
        XCTAssertTrue(app.buttons["question.analog.more"].label.contains("+5"))
        drag(clock, from: 100, to: 160, radius: 0.20)
        XCTAssertEqual(clock.label, "05:20", "The hour drag remains on that hand while crossing the minute hand")
        XCTAssertTrue(app.buttons["question.hand.hours"].isSelected)
        XCTAssertTrue(app.buttons["question.analog.more"].label.contains("+1"))
        tap("question.analog.more")
        XCTAssertEqual(clock.label, "06:20")
        tap("question.analog.less")
        XCTAssertEqual(clock.label, "05:20")
        saveScreenshot("analog-fixed-controls-auto-hand-selection")
        tap("question.example")
        tap("demo.hand.minutes")
        let example = app.descendants(matching: .any)["demo.analog"]
        for _ in 0..<(time(example).minute / 5) { app.buttons["demo.analog.less"].tap() }
        tap("demo.hand.hours")
        for _ in 0..<((3 - time(example).hour + 12) % 12) { app.buttons["demo.analog.more"].tap() }
        XCTAssertEqual(example.label, "03:00")
        drag(example, from: 0, to: 120, radius: 0.31)
        XCTAssertEqual(example.label, "03:20")
        XCTAssertEqual(app.buttons["demo.hand.hours"].frame.width,
                       app.buttons["demo.hand.minutes"].frame.width, accuracy: 1)
        XCTAssertGreaterThanOrEqual(app.buttons["demo.confirm"].frame.minY
            - app.buttons["demo.analog.more"].frame.maxY, 20)
        XCTAssertTrue(app.buttons["demo.hand.minutes"].isSelected)
        saveScreenshot("analog-example-fixed-controls-auto-hand-selection")
    }

    func testAnalogSettingExampleShowsTapsAndRestartsAtOppositeTime() {
        openPractice()
        selectPractice("practice.type.setAnalog")
        tap("practice.start")
        let title = app.staticTexts["question.title"].label
        XCTAssertEqual(title, "Zet beide klokken op dezelfde tijd")
        XCTAssertFalse(app.buttons["question.hand.minutes"].exists)
        let live = app.descendants(matching: .any)["question.analogControl"]
        tap("question.example")
        let digital = app.descendants(matching: .any)["demo.digital"]
        let analog = app.descendants(matching: .any)["demo.analog"]
        XCTAssertEqual(app.staticTexts["demo.title"].label, title)
        XCTAssertEqual(digital.label, "03:00")
        XCTAssertLessThan(digital.frame.maxY, analog.frame.minY)
        XCTAssertFalse(app.buttons["demo.hand.minutes"].exists)
        XCTAssertLessThan(analog.frame.maxY, app.buttons["demo.analog.more"].frame.minY)
        XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 20))
        XCTAssertEqual(digital.label, "03:00", "The digital target stays fixed during all demonstrated taps")
        saveScreenshot("analog-setting-example-completed-whole")
        tap("demo.nextExample")
        XCTAssertEqual(digital.label, "04:00")
        tap("demo.analog.less")
        RunLoop.current.run(until: Date().addingTimeInterval(2))
        tap("demo.ready")
        XCTAssertTrue(live.exists)
        XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "1")
    }

    func testAnalogSettingMinuteExampleUsesSharedControlsAndFixedTarget() {
        openPractice()
        tap("practice.time.half")
        selectPractice("practice.type.setAnalog")
        tap("practice.start")
        XCTAssertEqual(app.staticTexts["question.title"].label, "Zet beide klokken op dezelfde tijd")
        tap("question.hand.minutes")
        let confirm = app.buttons["question.confirm"]
        XCTAssertEqual(confirm.label, "Controleer mijn klok")
        XCTAssertGreaterThanOrEqual(confirm.frame.minY, app.scrollViews["game.questions"].frame.maxY - 1,
                                    "Confirm stays in the sticky footer under the question")
        XCTAssertLessThanOrEqual(confirm.frame.maxY, app.frame.maxY)
        saveScreenshot("analog-setting-question-shared-controls")
        tap("question.example")
        let digital = app.descendants(matching: .any)["demo.digital"]
        let analog = app.descendants(matching: .any)["demo.analog"]
        XCTAssertEqual(digital.label, "03:30")
        XCTAssertTrue(app.buttons["demo.hand.minutes"].exists)
        XCTAssertLessThan(digital.frame.maxY, analog.frame.minY)
        XCTAssertLessThan(analog.frame.maxY, app.buttons["demo.hand.minutes"].frame.minY)
        XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 20))
        XCTAssertEqual(digital.label, "03:30")
        saveScreenshot("analog-setting-example-completed-minutes")
        tap("demo.nextExample")
        XCTAssertEqual(digital.label, "04:30")
        saveScreenshot("analog-setting-example-opposite-minutes")
        tap("demo.ready")
    }

    func testAdvanceAnalogPlacesClocksSideBySideAndDemonstratesTheTurn() {
        openPractice()
        tap("practice.time.fiveMinutes")
        selectPractice("practice.type.advanceAnalog")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .fiveMinutes, order: .specific(.advanceAnalog)), seed: seed)
        let question = generator.next(index: 0)
        let duration = "+\(DinoTimeWords.duration(question.durationMinutes, language: "nl"))"
        XCTAssertEqual(app.staticTexts["question.title"].label, "Zet de wijzers vooruit")
        XCTAssertFalse(app.staticTexts["Begintijd"].exists)
        let start = app.descendants(matching: .any)["question.startClock"]
        let difference = app.descendants(matching: .any)["question.advance.difference"]
        let control = app.descendants(matching: .any)["question.analogControl"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertEqual(difference.label, duration)
        XCTAssertLessThan(start.frame.maxX, difference.frame.minX)
        XCTAssertLessThan(difference.frame.maxX, control.frame.minX)
        XCTAssertEqual(start.frame.midY, control.frame.midY, accuracy: 8)
        tap("question.example")
        let example = DinoDemonstrationExamples.question(kind: .advanceAnalog, minutes: DinoPracticeTime.fiveMinutes.minutes,
                                                         minuteStep: 5, index: 0, previousTarget: nil)
        let demoStart = app.descendants(matching: .any)["demo.startClock"]
        let demoClock = app.descendants(matching: .any)["demo.analog"]
        let demoDifference = app.descendants(matching: .any)["demo.advance.difference"]
        XCTAssertTrue(demoClock.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["demo.title"].label, "Zet de wijzers vooruit")
        XCTAssertEqual(demoDifference.label, "+\(DinoTimeWords.duration(example.durationMinutes, language: "nl"))")
        XCTAssertLessThan(demoStart.frame.maxX, demoDifference.frame.minX)
        XCTAssertLessThan(demoDifference.frame.maxX, demoClock.frame.minX)
        XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 25))
        saveScreenshot("advance-analog-side-by-side")
        tap("demo.nextExample")
        tap("demo.analog.less")
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))
        tap("demo.ready")
        XCTAssertTrue(control.exists)
    }

    private func answerPracticeWrong(_ question: ClockQuestion) {
        switch question.kind {
        case .sortTimes:
            let reversed = question.options.sorted { $0.minutesOfDay > $1.minutesOfDay }
            for time in reversed { tap("question.sort.\(question.options.firstIndex(of: time)!)") }
            tap("question.confirm")
            let correctOrder = app.staticTexts["question.sort.correct"]
            XCTAssertTrue(correctOrder.waitForExistence(timeout: 5))
            if case .ordering(let times) = question.expectedAnswer {
                XCTAssertEqual(correctOrder.label, times.map(\.digitalText).joined(separator: " → "))
            }
            XCTAssertFalse(app.staticTexts["Goede volgorde"].exists)
        case .sayTime:
            let prompt = question.spokenPrompt!
            for (slotIndex, slot) in prompt.slots.enumerated() {
                let correct = prompt.correct.choiceIDs[slotIndex]
                guard let wrong = slot.choices.first(where: { $0.id != correct }),
                      let choiceIndex = slot.choices.firstIndex(where: { $0.id == wrong.id }) else { continue }
                tap("question.spoken.\(slotIndex).\(choiceIndex)")
            }
            XCTAssertEqual(app.buttons["question.confirm"].label, "Controleer mijn antwoord")
            tap("question.confirm")
            XCTAssertTrue(app.descendants(matching: .any)["question.spoken.phrase"].waitForExistence(timeout: 5))
        case .match:
            connectMatchingQuestion(question, correct: false)
        case .advanceAnalog, .setAnalog, .setDigital:
            tap("question.confirm")
        default:
            let options = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option."))
            XCTAssertEqual(options.count, question.responses.count)
            tap("question.option.\(question.responses.firstIndex { $0 != question.expectedAnswer }!)")
        }
        if question.kind.usesOptions && question.responses.count > 2 { tap("question.showAnswer") }
        XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
    }

    private func connectMatchingQuestion(_ question: ClockQuestion, correct: Bool) {
        for index in question.relatedTimes.indices {
            let time = question.relatedTimes[correct ? index : (index + 1) % question.relatedTimes.count]
            tap("question.match.clock.\(index)")
            tap("question.match.time.\(question.options.firstIndex(of: time)!)")
        }
        tap("question.confirm")
    }

    func testQuestionTitlesIncludeTimeInWords() {
        openPractice()
        XCTAssertFalse(app.buttons["practice.type.activity"].exists)
        for type in [DinoPracticeQuestion.spokenTime, .trueFalse] {
            selectPractice("practice.type.\(type.rawValue)")
            tap("practice.start")
            var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(type)), seed: seed)
            let q = generator.next(index: 0)
            let words = DinoTimeWords.time(q.statement ?? q.target, language: "nl")
            XCTAssertEqual(app.staticTexts["question.title"].label,
                           type == .spokenTime ? "Welke klok laat \(words) zien?" : "Het is nu \(words).")
            XCTAssertFalse(app.staticTexts[words].exists, "The time appears in the title once")
            saveScreenshot("question-title-\(type.rawValue)")
            tap("question.example")
            let example = DinoDemonstrationExamples.question(kind: type.recipe.kind, minutes: [0], minuteStep: 60,
                                                            index: 0, previousTarget: nil)
            let exampleWords = DinoTimeWords.time(example.statement ?? example.target, language: "nl")
            XCTAssertEqual(app.staticTexts["demo.title"].label,
                           type == .spokenTime ? "Welke klok laat \(exampleWords) zien?" : "Het is nu \(exampleWords).")
            saveScreenshot("question-title-example-\(type.rawValue)")
            tap("demo.ready")
            if type == .trueFalse {
                XCTAssertEqual(Set((0..<2).map { app.buttons["question.option.\($0)"].label }), Set(["Goed", "Fout"]))
            }
            tap("header.pause")
        }
    }

    func testThreePairMatchingAndTapDemonstration() {
        openPractice()
        selectPractice("practice.type.match")
        tap("practice.start")
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.match.clock.")).count, 3)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.match.time.")).count, 3)
        XCTAssertEqual(app.buttons["question.confirm"].label, "Controleer mijn verbindingen")
        XCTAssertFalse(app.buttons["question.confirm"].isEnabled)
        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.match)), seed: seed)
        let q = generator.next(index: 0)
        let left = app.buttons["question.match.clock.0"]
        let right = app.buttons["question.match.time.0"]
        XCTAssertLessThan(left.frame.maxX, right.frame.minX)
        XCTAssertEqual(left.frame.midY, right.frame.midY, accuracy: 1)
        tap("question.match.clock.0")
        let wrong = q.options.firstIndex { $0 != q.relatedTimes[0] }!
        tap("question.match.time.\(wrong)")
        XCTAssertFalse(app.buttons["question.confirm"].isEnabled)
        // Either endpoint disconnects its pair and clears the pending selection.
        tap("question.match.clock.0")
        XCTAssertFalse(app.descendants(matching: .any)["question.match.line.0"].exists)
        let matching = q.options.firstIndex(of: q.relatedTimes[0])!
        tap("question.match.time.\(matching)")
        tap("question.match.clock.0")
        XCTAssertTrue(app.descendants(matching: .any)["question.match.line.0"].exists)
        // A pending clock must not take over the connected time when it is tapped.
        tap("question.match.clock.1")
        tap("question.match.time.\(matching)")
        XCTAssertFalse(app.buttons["question.confirm"].isEnabled)
        tap("question.match.time.\(matching)")
        tap("question.match.clock.0")
        for index in 1..<3 {
            tap("question.match.clock.\(index)")
            tap("question.match.time.\(q.options.firstIndex(of: q.relatedTimes[index])!)")
        }
        XCTAssertTrue(app.buttons["question.confirm"].isEnabled)
        tap("question.match.clock.2")
        XCTAssertFalse(app.buttons["question.confirm"].isEnabled)
        tap("question.match.clock.2")
        tap("question.match.time.\(q.options.firstIndex(of: q.relatedTimes[2])!)")
        XCTAssertTrue(app.buttons["question.confirm"].isEnabled)
        saveScreenshot("matching-three-pairs-ready")
        tap("question.example")
        XCTAssertTrue(app.buttons["demo.match.clock.0"].waitForExistence(timeout: 5))
        let line = app.descendants(matching: .any)["demo.match.line.0"]
        XCTAssertTrue(line.waitForExistence(timeout: 8), "The example draws a line after the two taps")
        saveScreenshot("matching-example-first-line")
        XCTAssertTrue(app.descendants(matching: .any)["demo.match.line.2"].waitForExistence(timeout: 10))
        saveScreenshot("matching-example-all-lines")
        tap("demo.nextExample")
        tap("demo.ready")
        tap("question.confirm")
        XCTAssertTrue(app.staticTexts.matching(identifier: "practice.questionNumber").matching(NSPredicate(format: "label == %@", "2")).firstMatch.waitForExistence(timeout: 5))
        // Wrong connections still get explicit feedback and Next.
        answerPracticeWrong(generator.next(index: 1))
        saveScreenshot("matching-three-pairs-feedback")
    }

    func testMatchingSupportsDragsAlongsideTaps() {
        openPractice()
        selectPractice("practice.type.match")
        XCTAssertFalse(app.buttons["practice.type.pairClocks"].exists)
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.match)), seed: seed)
        let question = generator.next(index: 0)
        let clocks = (0..<3).map { app.buttons["question.match.clock.\($0)"] }
        let times = (0..<3).map { app.buttons["question.match.time.\($0)"] }
        func drag(_ source: XCUIElement, to destination: XCUIElement, targetY: CGFloat = 0.5) {
            let viewport = app.scrollViews["game.questions"]
            for _ in 0..<8 {
                let centers = (clocks + times).map { $0.frame.midY }
                let destinationY = destination.frame.minY + destination.frame.height * targetY
                let highest = min(centers.min()!, destinationY)
                let lowest = max(centers.max()!, destinationY)
                let top = viewport.frame.minY + 16, bottom = viewport.frame.maxY - 16
                if highest >= top && lowest <= bottom { break }
                let down = highest < top
                viewport.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: down ? 0.35 : 0.70))
                    .press(forDuration: 0.05, thenDragTo: viewport.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: down ? 0.50 : 0.55)),
                           withVelocity: .slow, thenHoldForDuration: 0.05)
            }
            source.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .press(forDuration: 0.1, thenDragTo: destination.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: targetY)))
        }

        let first = question.options.firstIndex(of: question.relatedTimes[0])!
        // A connection can land near the rim of the entire enlarged time card.
        drag(clocks[0], to: times[first], targetY: 0.08)
        XCTAssertTrue(app.descendants(matching: .any)["question.match.line.0"].exists)
        XCTAssertFalse(app.buttons["question.confirm"].isEnabled)
        // A drag can transfer an occupied time; a later tap still disconnects it.
        drag(times[first], to: clocks[1])
        tap("question.match.time.\(first)")

        // Releasing on the same side or in the gap leaves existing pairs intact.
        tap("question.match.clock.0")
        tap("question.match.time.\(first)")
        drag(clocks[0], to: clocks[2])
        let gap = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
            dx: (clocks[0].frame.maxX + times[0].frame.minX) / 2, dy: clocks[0].frame.midY))
        clocks[0].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: gap)

        let second = question.options.firstIndex(of: question.relatedTimes[1])!
        drag(times[second], to: clocks[1])
        tap("question.match.time.\(question.options.firstIndex(of: question.relatedTimes[2])!)")
        tap("question.match.clock.2")
        XCTAssertTrue(app.buttons["question.confirm"].isEnabled)
        saveScreenshot("matching-drag-and-tap-ready")
        tap("question.confirm")
        XCTAssertTrue(app.staticTexts.matching(identifier: "practice.questionNumber").matching(NSPredicate(format: "label == %@", "2")).firstMatch.waitForExistence(timeout: 5))
    }

    func testDigitalMinutesWrapAndAnalogMinutesCarry() {
        openPractice()
        tap("practice.time.fiveMinutes")
        selectPractice("practice.type.setDigital")
        tap("practice.start")
        let digital = app.descendants(matching: .any)["question.digitalControl"]
        let initialHour = Int(digital.label.prefix(2))!
        for _ in 0..<((5 - initialHour + 12) % 12) { app.buttons["clock.hour.more"].tap() }
        for _ in 0..<11 { app.buttons["clock.minute.more"].tap() }
        XCTAssertEqual(digital.label, "05:55")
        tap("clock.minute.more")
        XCTAssertEqual(digital.label, "05:00")
        tap("clock.minute.less")
        XCTAssertEqual(digital.label, "05:55")
        saveScreenshot("digital-minute-wrap-independent-hour")
        tap("question.example")
        let example = app.descendants(matching: .any)["demo.digital"]
        XCTAssertEqual(example.label, "03:05")
        tap("clock.minute.less")
        XCTAssertEqual(example.label, "03:00")
        tap("clock.minute.less")
        XCTAssertEqual(example.label, "03:55")
        tap("clock.minute.more")
        XCTAssertEqual(example.label, "03:00")
        tap("demo.ready")
        XCTAssertEqual(digital.label, "05:55", "Example adjustments preserve the live input")
        tap("header.pause")

        selectPractice("practice.type.setAnalog")
        tap("practice.start")
        let analog = app.descendants(matching: .any)["question.analogControl"]
        func moveHand(to angle: Double) {
            let radians = angle * .pi / 180
            analog.coordinate(withNormalizedOffset: CGVector(dx: 0.5 + sin(radians) * 0.43,
                                                              dy: 0.5 - cos(radians) * 0.43)).tap()
        }
        moveHand(to: 150)
        app.buttons["Minuten"].tap()
        moveHand(to: 180)
        moveHand(to: 330)
        moveHand(to: 0)
        moveHand(to: 330)
        tap("question.analog.more")
        tap("question.analog.less")
        saveScreenshot("analog-minute-hour-carry")
    }

    func testMultipleChoiceRetriesKeepTheLostPoint() {
        openPractice()
        selectPractice("practice.type.dayPart")
        tap("practice.start")
        // The HUD identifies each whole cell, including its title and digits.
        func counter(_ identifier: String) -> XCUIElement {
            app.staticTexts.matching(identifier: identifier)
                .matching(NSPredicate(format: "label MATCHES %@", "[0-9]+")).firstMatch
        }
        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.dayPart)), seed: seed)
        for index in 0..<2 {
            let question = generator.next(index: index)
            let wrong = question.responses.indices.filter { question.responses[$0] != question.expectedAnswer }
            tap("question.option.\(wrong[0])")
            XCTAssertTrue(app.buttons["question.showAnswer"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.buttons["question.showAnswer"].label, "Toon antwoord")
            XCTAssertFalse(app.buttons["question.next"].exists)
            XCTAssertFalse(app.buttons["question.option.\(wrong[0])"].isEnabled)
            tap("question.option.\(wrong[1])")
            XCTAssertFalse(app.buttons["question.option.\(wrong[1])"].isEnabled)
            XCTAssertTrue(app.buttons["question.showAnswer"].exists)
            if index == 0 {
                tap("question.option.\(question.responses.firstIndex(of: question.expectedAnswer)!)")
                XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
                XCTAssertFalse(app.buttons["question.showAnswer"].exists)
                RunLoop.current.run(until: Date().addingTimeInterval(1.2))
                XCTAssertEqual(counter("header.questions").label, "1", "Correct retries wait for Next")
                saveScreenshot("multiple-choice-correct-retry")
            } else {
                tap("question.showAnswer")
                XCTAssertTrue(app.buttons["question.next"].exists)
                saveScreenshot("multiple-choice-show-answer")
            }
            XCTAssertTrue((0..<4).allSatisfy { !app.buttons["question.option.\($0)"].isEnabled })
            tap("question.next")
            XCTAssertEqual(counter("header.streak").label, "0")
            XCTAssertEqual(counter("header.questions").label, String(index + 2))
        }
    }

    func testShowAnswerEnglishAndTwoChoiceFeedback() {
        onboard()
        app.terminate()
        app.launchArguments = ["-settings.languageOverride", "en"]
        app.launch()
        tap("header.practice")
        selectPractice("practice.type.dayPart")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.dayPart)), seed: seed)
        let question = generator.next(index: 0)
        tap("question.option.\(question.responses.firstIndex { $0 != question.expectedAnswer }!)")
        XCTAssertEqual(app.buttons["question.showAnswer"].label, "Show answer")
        tap("question.showAnswer")
        XCTAssertEqual(app.buttons["question.next"].label, "Next")
        saveScreenshot("multiple-choice-show-answer-english")
        tap("header.pause")

        selectPractice("practice.type.trueFalse")
        tap("practice.start")
        generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.trueFalse)), seed: seed)
        let binaryQuestion = generator.next(index: 0)
        tap("question.option.\(binaryQuestion.responses.firstIndex { $0 != binaryQuestion.expectedAnswer }!)")
        XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["question.showAnswer"].exists)
        XCTAssertFalse(app.buttons["question.option.0"].isEnabled)
        XCTAssertFalse(app.buttons["question.option.1"].isEnabled)
    }

    func testDigitalClockHasIndependentHourAndMinuteArrows() {
        openPractice()
        tap("practice.time.half")
        selectPractice("practice.type.setDigital")
        tap("practice.start")
        let clock = app.descendants(matching: .any)["question.digitalControl"]
        let initialHour = Int(clock.label.prefix(2))!
        let hourUp = app.buttons["clock.hour.more"]
        let hourDown = app.buttons["clock.hour.less"]
        let minuteUp = app.buttons["clock.minute.more"]
        let minuteDown = app.buttons["clock.minute.less"]
        for button in [hourUp, hourDown, minuteUp, minuteDown] {
            XCTAssertTrue(button.isHittable)
            XCTAssertGreaterThanOrEqual(button.frame.width + 0.01, 44)
            XCTAssertGreaterThanOrEqual(button.frame.height + 0.01, 44)
        }
        XCTAssertEqual(hourUp.frame.midX, hourDown.frame.midX, accuracy: 1)
        XCTAssertEqual(minuteUp.frame.midX, minuteDown.frame.midX, accuracy: 1)
        XCTAssertLessThan(hourUp.frame.maxY, hourDown.frame.minY)
        XCTAssertLessThan(minuteUp.frame.maxY, minuteDown.frame.minY)
        XCTAssertLessThan(hourUp.frame.maxX, minuteUp.frame.minX)
        let confirm = app.buttons["question.confirm"]
        XCTAssertEqual(confirm.label, "Controleer mijn klok")
        XCTAssertEqual(confirm.frame.midX, clock.frame.midX, accuracy: 2)
        XCTAssertGreaterThanOrEqual(confirm.frame.minX, 12)
        XCTAssertLessThanOrEqual(confirm.frame.maxX, app.frame.maxX - 12)
        XCTAssertGreaterThanOrEqual(confirm.frame.minY, app.scrollViews["game.questions"].frame.maxY - 1)
        XCTAssertGreaterThanOrEqual(confirm.frame.minY - minuteDown.frame.maxY, 20)
        tap("clock.minute.more")
        XCTAssertEqual(clock.label, ClockTime(hour: initialHour, minute: 30).digitalText)
        tap("clock.hour.more")
        XCTAssertEqual(clock.label, ClockTime(hour: ClockTime.shiftedHour(initialHour, by: 1), minute: 30).digitalText)
        tap("clock.minute.less")
        tap("clock.hour.less")
        XCTAssertEqual(clock.label, ClockTime(hour: initialHour).digitalText)
        saveScreenshot("digital-question-independent-arrows")
        tap("question.example")
        let example = app.descendants(matching: .any)["demo.digital"]
        XCTAssertEqual(example.label, "03:30")
        tap("clock.hour.more")
        XCTAssertEqual(example.label, "04:30")
        tap("clock.minute.less")
        XCTAssertEqual(example.label, "04:00")
        tap("clock.minute.more")
        tap("clock.hour.less")
        XCTAssertEqual(example.label, "03:30")
        saveScreenshot("digital-example-independent-arrows")
        tap("demo.nextExample")
        XCTAssertEqual(example.label, "04:30")
        tap("demo.ready")
        XCTAssertEqual(clock.label, ClockTime(hour: initialHour).digitalText,
                       "Example adjustments preserve the live input")
        tap("header.dino")
        tap("personalize.page.digital")
        tap("theme.numerals.digital")
        tap("theme.dino.display.yellow")
        tap("theme.dino.digitColor.navy")
        tap("personalize.done")
        XCTAssertEqual(clock.label, ClockTime(hour: initialHour).digitalText)
        XCTAssertTrue(app.buttons["clock.hour.more"].isHittable)
        XCTAssertTrue(app.buttons["clock.minute.more"].isHittable)
        saveScreenshot("digital-original-display-custom-theme")
    }

    func testPracticeAscendingAndMixCoverAllTypes() {
        openPractice()
        tap("practice.time.minutes")
        selectPractice("practice.order.ascending")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .minutes, order: .ascending), seed: seed)
        for index in 0...DinoPracticeQuestion.allCases.count {
            let question = generator.next(index: index)
            let expectedNumber = String(index + 1)
            XCTAssertTrue(app.staticTexts.matching(identifier: "header.questions").matching(NSPredicate(format: "label == %@", expectedNumber)).firstMatch.waitForExistence(timeout: 5))
            if question.kind.isExpanded {
                tap("question.example")
                XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 5))
                XCTAssertFalse(app.descendants(matching: .any)["dino.character"].exists)
                tap("demo.ready")
                XCTAssertTrue(app.staticTexts.matching(identifier: "header.questions").matching(NSPredicate(format: "label == %@", expectedNumber)).firstMatch.exists, "Example preserves the actual question")
            }
            answerPracticeWrong(question)
            if [.sortTimes, .advanceAnalog, .timeZone, .read24Hour, .timeSequence].contains(question.kind) {
                saveScreenshot("practice-expanded-\(question.kind.rawValue)")
            }
            tap("question.next")
        }
        tap("header.pause")
        selectPractice("practice.order.mix")
        tap("practice.start")
        generator = DinoPracticeGenerator(configuration: .init(time: .minutes, order: .mix), seed: seed)
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
        selectPractice("practice.type.match")
        tap("practice.start")
        XCTAssertFalse(app.buttons["demo.ready"].exists)
        tap("question.example")
        XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["dino.character"].exists)
        tap("demo.ready")
        var generator = DinoPracticeGenerator(configuration: .init(time: .quarter, order: .specific(.match)), seed: seed)
        let question = generator.next(index: 0)
        for index in question.relatedTimes.indices {
            tap("question.match.clock.\(index)")
            tap("question.match.time.\(question.options.firstIndex(of: question.relatedTimes[index])!)")
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

    func testQuestionInstructionsAndWorkedBoards() {
        openPractice()
        selectPractice("practice.type.match")
        tap("practice.start")
        XCTAssertFalse(app.staticTexts["question.match.hint"].exists)
        tap("question.example")
        let matchingHint = app.staticTexts["demo.match.hint"]
        XCTAssertTrue(matchingHint.waitForExistence(timeout: 5))
        XCTAssertEqual(matchingHint.label, "Tik op een klok en daarna op de bijbehorende tijd. Je mag ook met een tijd beginnen.")
        saveScreenshot("matching-description-only-in-example")
        tap("demo.ready")
        tap("header.pause")

        selectPractice("practice.type.sortTimes")
        tap("practice.start")
        XCTAssertEqual(app.staticTexts["question.title"].label, "Van vroeg naar laat")
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Alle klokken horen")).firstMatch.exists)
        tap("question.example")
        XCTAssertTrue(app.staticTexts["demo.sort.hint"].waitForExistence(timeout: 5))
        for example in 0..<2 {
            let choices = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "demo.sort."))
            XCTAssertEqual(choices.count, 4)
            let orderedLabels = (0..<4).map { index -> (Int, String) in
                let clock = app.buttons["demo.sort.\(index)"]
                XCTAssertFalse(clock.isEnabled)
                XCTAssertNotEqual(clock.label, "00:00")
                let position = clock.staticTexts.allElementsBoundByIndex.compactMap { Int($0.label) }.first ?? 0
                return (position, clock.label)
            }.sorted { $0.0 < $1.0 }
            XCTAssertEqual(orderedLabels.map(\.0), [1, 2, 3, 4])
            XCTAssertEqual(orderedLabels.map(\.1), orderedLabels.map(\.1).sorted())
            XCTAssertFalse(app.buttons["question.confirm"].exists)
            XCTAssertTrue(app.staticTexts["demo.answer"].label.contains(" → "))
            if example == 0 { saveScreenshot("sorting-example-already-selected"); tap("demo.nextExample") }
        }
        tap("demo.ready")
        tap("header.pause")

        selectPractice("practice.type.timeSequence")
        tap("practice.start")
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Een dag heeft 24 uur")).firstMatch.exists)
        for index in 0..<3 {
            XCTAssertTrue(app.descendants(matching: .any)["question.sequence.arrow.\(index)"].exists)
        }
        saveScreenshot("sequence-question-vertical")
        tap("question.example")
        XCTAssertTrue(app.staticTexts["demo.sequence.hint"].waitForExistence(timeout: 5))
        let pattern = DinoDemonstrationExamples.question(kind: .timeSequence, minutes: [0], minuteStep: 60,
                                                         index: 0, previousTarget: nil)
        for index in 0..<3 {
            XCTAssertEqual(app.descendants(matching: .any)["demo.sequence.arrow.\(index)"].label,
                           "+\(DinoTimeWords.duration(pattern.durationMinutes, language: "nl"))")
        }
        saveScreenshot("sequence-example-step-arrows")
        tap("demo.ready")
    }

    func testTimeDescriptionsAndArithmeticExampleSizes() {
        openPractice()
        tap("practice.time.fiveMinutes")
        selectPractice("practice.type.read24Hour")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .fiveMinutes, order: .specific(.read24Hour)), seed: seed)
        let question = generator.next(index: 0)
        for (index, response) in question.responses.enumerated() {
            guard case .time(let time) = response else { return XCTFail("Expected a time description") }
            XCTAssertEqual(app.buttons["question.option.\(index)"].label,
                           DinoTimeWords.time(time, language: "nl", dayPart: true))
        }
        saveScreenshot("read24-hour-separated-time-and-day-part")
        tap("header.pause")
        for kind in [DinoPracticeQuestion.addTime, .subtractTime] {
            selectPractice("practice.type.\(kind.rawValue)")
            tap("practice.start")
            XCTAssertTrue(app.descendants(matching: .any)["question.timeChange.difference"].exists)
            saveScreenshot("\(kind.rawValue)-signed-difference")
            tap("question.example")
            let start = app.descendants(matching: .any)["demo.targetClock"]
            let end = app.descendants(matching: .any)["demo.answer"]
            XCTAssertTrue(end.waitForExistence(timeout: 5))
            XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "demo.targetClock").count, 1)
            XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "demo.answer").count, 1)
            XCTAssertNotNil(start.label.range(of: "^[0-9]{2}:[0-9]{2}$", options: .regularExpression))
            XCTAssertNotNil(end.label.range(of: "^[0-9]{2}:[0-9]{2}$", options: .regularExpression))
            XCTAssertEqual(start.frame.width, end.frame.width, accuracy: 1)
            XCTAssertEqual(start.frame.height, end.frame.height, accuracy: 1)
            XCTAssertTrue(app.descendants(matching: .any)["demo.timeChange.difference"].exists)
            saveScreenshot("\(kind.rawValue)-equal-example-clocks")
            tap("demo.ready")
            tap("header.pause")
        }
    }

    func testDayPartExplanationWaitsUntilAMissedQuestionIsClosed() {
        openPractice()
        selectPractice("practice.type.dayPart")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.dayPart)), seed: seed)
        for index in 0..<3 {
            let question = generator.next(index: index)
            let wrong = question.responses.indices.filter { question.responses[$0] != question.expectedAnswer }
            let answer = app.descendants(matching: .any)["question.dayPart.answer"]
            XCTAssertFalse(answer.exists)
            let optionFrames = (0..<4).map { app.buttons["question.option.\($0)"].frame }
            tap("question.option.\(wrong[0])")
            XCTAssertTrue(app.buttons["question.showAnswer"].waitForExistence(timeout: 5))
            XCTAssertFalse(answer.exists, "The timeline must not disclose the answer while retrying")
            if index == 0 {
                tap("question.showAnswer")
            } else if index == 1 {
                tap("question.option.\(question.responses.firstIndex(of: question.expectedAnswer)!)")
            } else {
                for option in wrong.dropFirst() { tap("question.option.\(option)") }
            }
            XCTAssertTrue(answer.waitForExistence(timeout: 5))
            let part = DinoDayPart(hour: question.target.hour)
            let expected = ["night": "Nacht, 00–06", "morning": "Ochtend, 06–12",
                            "afternoon": "Middag, 12–18", "evening": "Avond, 18–24"]
            XCTAssertEqual(answer.label, expected[part.rawValue])
            XCTAssertTrue(app.buttons["question.next"].exists)
            for option in 0..<4 {
                XCTAssertEqual(app.buttons["question.option.\(option)"].frame.midY, optionFrames[option].midY, accuracy: 1)
            }
            saveScreenshot("day-part-explanation-closed-\(index)")
            tap("question.next")
            XCTAssertFalse(answer.exists, "A new question hides the worked answer")
        }
    }

    func testDayPartExampleActionsStayInPlace() {
        openPractice()
        selectPractice("practice.type.read24Hour")
        tap("practice.start")
        tap("question.example")
        let ready = app.buttons["demo.ready"]
        let another = app.buttons["demo.nextExample"]
        XCTAssertTrue(another.waitForExistence(timeout: 5))
        let readyY = ready.frame.minY
        let anotherY = another.frame.minY
        for _ in 0..<22 {
            tap("demo.nextExample")
            XCTAssertEqual(ready.frame.minY, readyY, accuracy: 1, "Longer day-part answers reserve the same space")
            XCTAssertEqual(another.frame.minY, anotherY, accuracy: 1)
        }
        saveScreenshot("day-part-example-stable-actions")
    }

    func testDayPartExampleShowsTheDayLine() {
        openPractice()
        selectPractice("practice.type.dayPart")
        tap("practice.start")
        XCTAssertFalse(app.descendants(matching: .any)["demo.dayPart.night"].exists)
        tap("question.example")
        XCTAssertTrue(app.descendants(matching: .any)["demo.answer"].waitForExistence(timeout: 5))
        let parts = ["night": "Nacht, 00–06", "morning": "Ochtend, 06–12",
                     "afternoon": "Middag, 12–18", "evening": "Avond, 18–24"]
        func expectAnswer(_ part: String, shot: String) {
            XCTAssertEqual(app.descendants(matching: .any)["demo.answer"].label, parts[part])
            for (name, label) in parts {
                let identifier = name == part ? "demo.answer" : "demo.dayPart.\(name)"
                XCTAssertEqual(app.descendants(matching: .any)[identifier].label, label)
            }
            XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "demo.answer").count, 1)
            saveScreenshot(shot)
        }
        expectAnswer("night", shot: "day-part-line-night")
        for _ in 0..<3 { tap("demo.nextExample") }
        expectAnswer("morning", shot: "day-part-line-morning")
        for _ in 0..<6 { tap("demo.nextExample") }
        expectAnswer("afternoon", shot: "day-part-line-afternoon")
        for _ in 0..<6 { tap("demo.nextExample") }
        expectAnswer("evening", shot: "day-part-line-evening")
        tap("demo.ready")
        XCTAssertFalse(app.descendants(matching: .any)["demo.dayPart.night"].exists)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option.")).count, 4)
    }

    func testManualExamplesAndClockComparison() {
        onboard()
        begin(10)
        XCTAssertFalse(app.buttons["demo.ready"].exists)
        tap("question.example")
        XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 3))
        saveScreenshot("manual-example-centered")
        XCTAssertFalse(app.descendants(matching: .any)["dino.character"].exists, "Example has no companion")
        tap("demo.ready")
        var rng = SeededGenerator(seed: seed)
        let questions = DinoQuestionGenerator.generate(level: DinoLevelCatalog.level(10)!, using: &rng)
        for question in questions {
            if question.kind == .setAnalog || question.kind == .setDigital {
                // The next question always initializes to a different hour than its target.
                tap("question.confirm")
                XCTAssertTrue(app.descendants(matching: .any)["question.correctClock"].waitForExistence(timeout: 4))
                XCTAssertFalse(app.descendants(matching: .any)["question.feedback"].exists)
                saveScreenshot(question.kind == .setAnalog ? "analog-answer-comparison" : "digital-answer-comparison")
                tap("question.next")
            } else if question.kind == .match {
                connectMatchingQuestion(question, correct: true)
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
        XCTAssertFalse(app.buttons["level.friend.test-4"].exists, "Only the top three friends show before the fold")
        XCTAssertFalse(app.staticTexts["level.ownName"].exists, "An unfinished level does not pin the player's score")
        XCTAssertTrue(app.buttons["level.friends.share"].exists)
        tap("level.friends.more")
        let orderedIDs = ["test-0", "test-3", "test-1", "test-4", "test-2"]
        for (first, next) in zip(orderedIDs, orderedIDs.dropFirst()) {
            XCTAssertLessThan(app.buttons["level.friend.\(first)"].frame.minY,
                              app.buttons["level.friend.\(next)"].frame.minY,
                              "Most stars first; equal stars use the shortest time")
        }
        let play = app.buttons["level.play"]
        let share = app.buttons["level.friends.share"]
        let map = app.buttons["level.map"]
        XCTAssertLessThan(play.frame.maxY, share.frame.minY, "Play sits above share")
        XCTAssertEqual(share.frame.minY - play.frame.maxY, map.frame.minY - share.frame.maxY, accuracy: 2,
                       "Play, share and the level map keep the same gap")
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
        }
        Thread.sleep(forTimeInterval: 0.75)
        saveScreenshot("welcome-dino-colors")
        XCTAssertTrue(app.buttons["onboarding.next"].isHittable)
        tap("onboarding.next")
        tap("onboarding.next")
        tap("onboarding.customClock")
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
        XCTAssertEqual(app.textFields.count, 0)
    }

    func testDinoStandsOnCompletedLevel() {
        let requestedWorld = ProcessInfo.processInfo.environment["DINO_TEST_WORLD_IDS"]?
            .split(separator: ",").compactMap { Int($0) }.first ?? 1
        let worldID = (1...10).contains(requestedWorld) ? requestedWorld : 1
        let levelID = (worldID - 1) * 10 + 1
        if worldID == 1 { onboard() }
        else {
            app.terminate()
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = String(worldID - 1)
            app.launch()
            XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 8))
        }
        begin(levelID)
        play(levelID, correct: 5)
        tap("result.map")
        let nextID = levelID + 1
        let marker = app.descendants(matching: .any)["map.dino.\(nextID)"]
        XCTAssertTrue(marker.waitForExistence(timeout: 5))
        let node = revealMapNode(nextID)
        XCTAssertEqual(marker.frame.midX, node.frame.midX, accuracy: 1)
        XCTAssertEqual(marker.frame.maxY, node.frame.midY + 12, accuracy: 5)
        saveScreenshot("map-completed-level-dino")
    }

    func testAvatarColorMaskContours() {
        onboard()
        tap("header.dino")
        for (part, color) in [("bandana", "blue"), ("spikes", "purple"), ("body", "pink"), ("belly", "orange")] {
            tap("personalize.\(part).\(color)")
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
        tap("personalize.done")
        app.terminate(); app.launch()
        tap("header.dino")
        XCTAssertTrue(app.buttons["personalize.color.bandana"].waitForExistence(timeout: 5))
        tap("personalize.done")
    }

    func testPersonalizeHeaderColors() {
        onboard()
        saveScreenshot("personalize-header-default")
        tap("header.dino")
        XCTAssertTrue(app.buttons["personalize.bandana.red"].waitForExistence(timeout: 5))
        for (part, color) in [("bandana", "red"), ("spikes", "darkGreen"), ("body", "green"), ("belly", "yellow")] {
            XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "personalize.color.\(part)").firstMatch.exists)
        }
        saveScreenshot("personalize-default")
        for (part, color) in [("bandana", "blue"), ("spikes", "purple"), ("body", "pink"), ("belly", "orange")] {
            tap("personalize.\(part).\(color)")
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
        }
        tap("personalize.resetColors")
        for (part, color) in [("bandana", "red"), ("spikes", "darkGreen"), ("body", "green"), ("belly", "yellow")] {
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
        XCTAssertFalse(app.buttons["map.friends"].exists)
        openSettings()
        tap("settings.gameCenter")
        let missing = app.buttons["friends.profile.test-missing"]
        for _ in 0..<8 { if missing.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(missing.isHittable)
        missing.tap()
        XCTAssertTrue(app.staticTexts["Alex"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(identifier: "Niet beschikbaar").firstMatch.exists)
        saveScreenshot("friends-unavailable-results")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        tap("friends.close")
        tap("settings.done")
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
            case .match:
                connectMatchingQuestion(question, correct: right)
            default:
                let option = question.responses.firstIndex { response in
                    right ? response == question.expectedAnswer : response != question.expectedAnswer
                }
                guard let option else {
                    XCTFail("No selectable answer for \(question.kind)")
                    return
                }
                tap("question.option.\(option)")
            }
            if !right {
                if question.kind.usesOptions && question.responses.count > 2 { tap("question.showAnswer") }
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
        XCTAssertEqual(app.descendants(matching: .any)["dino.backflip"].exists, count == level.questionCount)
        XCTAssertEqual(app.descendants(matching: .any)["dino.pirouette"].exists,
                       !level.isBoss && StarCalculator.stars(correct: count) == 2)
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
        XCTAssertTrue(app.descendants(matching: .any)["map.dino.10"].waitForExistence(timeout: 5))
        begin(10)
        play(10, correct: 5)
        XCTAssertEqual(app.buttons["result.next"].label, "Naar de volgende wereld")
        XCTAssertFalse(app.buttons["result.map"].exists)
        XCTAssertTrue(app.staticTexts["5/10"].exists)
        saveScreenshot("normal-world-complete")
        tap("result.next")
        XCTAssertTrue(app.descendants(matching: .any)["map.dino.11"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts["Wereld voltooid!"].exists)
    }

    func testDirectPerfectBoss() {
        onboard()
        begin(10)
        play(10, correct: 10)
        XCTAssertTrue(app.staticTexts["Perfecte boss-overwinning!"].exists)
        XCTAssertEqual(app.buttons["result.next"].label, "Naar de volgende wereld")
        tap("result.next")
        XCTAssertTrue(app.descendants(matching: .any)["map.dino.11"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts["Wereld voltooid!"].exists)
        begin(11)
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
        XCTAssertTrue(app.descendants(matching: .any)["map.dino.11"].waitForExistence(timeout: 5))
        let marker = app.descendants(matching: .any)["map.dino.11"]
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
        XCTAssertTrue(app.descendants(matching: .any)["map.dino.2"].waitForExistence(timeout: 5))
        let marker = app.descendants(matching: .any)["map.dino.2"]
        XCTAssertLessThan(marker.frame.height, 220)
        XCTAssertLessThanOrEqual(marker.frame.maxY, app.frame.maxY)
        XCTAssertGreaterThan(marker.frame.minY, 100)
        saveScreenshot("map-last-completed")
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["map.level.2"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["map.level.2"].isEnabled)
        XCTAssertTrue(app.descendants(matching: .any)["map.dino.2"].exists)
    }

    private func chooseClockCustomColor(_ title: String, hex: String) {
        tap("theme.dino.\(title).custom")
        let sliders = app.buttons.matching(NSPredicate(format: "label IN %@", ["Sliders", "Schuifbalken", "Schuifregelaars"])).firstMatch
        XCTAssertTrue(sliders.waitForExistence(timeout: 5))
        sliders.tap()
        let field = app.textFields.matching(NSPredicate(format: "value MATCHES %@ AND enabled == YES", "[0-9A-Fa-f]{6}")).firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 6) + hex)
        if UIDevice.current.userInterfaceIdiom == .pad {
            // The iPad color picker is a popover; a tap outside dismisses it.
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.15)).tap()
        } else {
            app.buttons.matching(NSPredicate(format: "label IN %@", ["sluit", "Close", "close"])).firstMatch.tap()
        }
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !self.app.otherElements["UIColorPickerView"].exists
        }, object: nil)
        wait(for: [dismissed], timeout: 5)
    }

    func testWelcomeFreeClockColors() {
        launchUsingDeviceLanguage("en-GB", locale: "en_GB")
        tap("onboarding.next")
        chooseClockCustomColor("face", hex: "090B11")
        chooseClockCustomColor("hourHand", hex: "FFD166")
        chooseClockCustomColor("minuteHand", hex: "A1EEE9")
        chooseClockCustomColor("rim", hex: "148B83")
        tap("theme.analogShape.octagon")
        saveScreenshot("welcome-analog-dark-custom-colors")
        tap("onboarding.next")
        chooseClockCustomColor("digitColor", hex: "FFD166")
        chooseClockCustomColor("display", hex: "FFD166")
        XCTAssertTrue(app.buttons["onboarding.customClock"].isEnabled)
        XCTAssertTrue(app.staticTexts["theme.digital.sameColors"].exists)
        chooseClockCustomColor("display", hex: "112233")
        XCTAssertTrue(app.buttons["onboarding.customClock"].isEnabled)
        saveScreenshot("welcome-digital-custom-colors")
        tap("onboarding.customClock")
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        openClockPage("analog")
        revealThemeChoice("theme.dino.face.custom")
        tap("theme.dino.face.custom")
        let sliders = app.buttons.matching(NSPredicate(format: "label IN %@", ["Sliders", "Schuifbalken", "Schuifregelaars"])).firstMatch
        XCTAssertTrue(sliders.waitForExistence(timeout: 5)); sliders.tap()
        XCTAssertTrue(app.textFields.matching(NSPredicate(format: "value == %@ AND enabled == YES", "090B11")).firstMatch.exists)
    }

    func testAnalogClockDesignAndRomanNumerals() {
        launchUsingDeviceLanguage("en-GB", locale: "en_GB")
        tap("onboarding.next")
        XCTAssertLessThan(app.buttons["theme.dino.face.black"].frame.minX, app.buttons["theme.dino.face.white"].frame.minX)
        let labels = ["theme.dino.hourHand.label", "theme.dino.minuteHand.label", "theme.dino.face.label",
                      "theme.dino.rim.label"]
        for (first, second) in zip(labels, labels.dropFirst()) {
            XCTAssertLessThan(app.staticTexts[first].frame.minY, app.staticTexts[second].frame.minY)
        }
        for title in ["hourHand", "minuteHand", "face", "rim"] {
            let presets = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND NOT identifier ENDSWITH %@", "theme.dino.\(title).", ".custom"))
            XCTAssertEqual(presets.count, 5)
        }
        tap("theme.dino.face.black")
        tap("theme.analogShape.octagon")
        XCTAssertFalse(app.descendants(matching: .any)["theme.hands"].exists)
        revealThemeChoice("theme.analogNumerals")
        XCTAssertFalse(app.staticTexts["theme.analogNumerals.label"].exists)
        tap("theme.analogNumerals.roman")
        let preview = app.descendants(matching: .any)["theme.analog.preview"]
        XCTAssertTrue(preview.staticTexts["XII"].exists)
        XCTAssertTrue(preview.staticTexts["IV"].exists)
        saveScreenshot("welcome-analog-roman-design")
        tap("theme.analogNumerals.normal")
        XCTAssertTrue(preview.staticTexts["12"].exists)
        tap("theme.analogNumerals.roman")
        tap("onboarding.next")
        let finish = app.buttons["onboarding.customClock"]
        XCTAssertTrue(finish.isHittable)
        let footerY = finish.frame.minY
        Thread.sleep(forTimeInterval: 0.6)
        saveScreenshot("welcome-digital-sticky-no-background")
        tap("theme.numerals.classic")
        XCTAssertEqual(finish.frame.minY, footerY, accuracy: 1)
        tap("onboarding.customClock")
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        openClockPage("analog")
        revealThemeChoice("theme.analogNumerals")
        tap("theme.resetAnalogStyle")
        tap("personalize.page.digital")
        revealThemeChoice("theme.numerals.classic")
        tap("personalize.done")
    }

    func testHeaderPersonalizerHasLiveClockPages() {
        onboard()
        tap("header.dino")
        tap("personalize.bandana.blue")
        tap("personalize.page.analog")
        tap("theme.dino.face.black")
        tap("theme.analogShape.octagon")
        tap("theme.analogNumerals.roman")
        saveScreenshot("personalize-analog-roman-page")
        app.swipeLeft()
        tap("theme.dino.digitColor.navy")
        XCTAssertTrue(app.buttons["personalize.done"].isEnabled)
        tap("theme.dino.display.yellow")
        XCTAssertTrue(app.buttons["personalize.done"].isEnabled)
        tap("theme.numerals.classic")
        saveScreenshot("personalize-digital-page")
        tap("personalize.done")
        tap("header.dino")
        tap("personalize.page.analog")
        tap("personalize.done")
        begin(1)
        XCTAssertTrue(app.staticTexts["1/5"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["XII"].firstMatch.exists)
        saveScreenshot("personalize-live-roman-in-level")
        tap("header.dino")
        tap("personalize.page.analog")
        tap("theme.analogNumerals.normal")
        tap("theme.analogShape.square")
        tap("theme.dino.face.white")
        tap("personalize.page.digital")
        tap("theme.numerals.digital")
        tap("theme.dino.display.teal")
        tap("theme.dino.digitColor.white")
        tap("personalize.done")
        XCTAssertTrue(app.staticTexts["1/5"].exists)
        XCTAssertFalse(app.staticTexts["XII"].exists)
        XCTAssertTrue(app.buttons["question.option.0"].exists)
        saveScreenshot("personalize-live-normal-and-digital-in-level")
        tap("header.dino")
        tap("personalize.page.analog")
        tap("personalize.done")
    }

    func testWelcomeClockRestoreOriginalStyle() {
        tap("onboarding.next")
        tap("theme.analogNumerals.roman")
        tap("theme.analogShape.octagon")
        tap("theme.dino.face.blue")
        tap("theme.dino.hourHand.red")
        tap("theme.resetAnalogStyle")
        XCTAssertEqual(app.buttons["theme.resetAnalogStyle"].label, "Herstel oorspronkelijke stijl")
        XCTAssertFalse(app.descendants(matching: .any)["theme.hands"].exists)
        tap("theme.analogNumerals.roman")
        tap("theme.analogShape.octagon")
        tap("theme.dino.face.blue")
        tap("onboarding.next")
        for part in ["digitColor", "display"] {
            let prefix = "theme.dino.\(part)."
            let presets = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND NOT identifier ENDSWITH %@", prefix, ".custom"))
            XCTAssertEqual(presets.count, 5)
            let names = part == "digitColor" ? ["navy", "orange", "green", "red", "white"] : ["black", "navy", "teal", "yellow", "white"]
            let colors = names.map { app.buttons[prefix + $0] }
            for (first, second) in zip(colors, colors.dropFirst()) {
                XCTAssertLessThan(first.frame.minX, second.frame.minX)
            }
        }
        XCTAssertFalse(app.descendants(matching: .any)["theme.digitalShape"].exists)
        tap("theme.dino.display.teal")
        tap("theme.dino.digitColor.orange")
        tap("theme.numerals.classic")
        saveScreenshot("digital-bright-palette-and-numeral-previews")
        tap("theme.resetDigitalStyle")
        XCTAssertEqual(app.buttons["theme.resetDigitalStyle"].label, "Herstel oorspronkelijke stijl")
        saveScreenshot("digital-original-style-restored")
        swipeWelcomePreview("theme.digital.preview", forward: false)
        tap("onboarding.next")
        tap("onboarding.customClock")
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        tap("header.dino")
        tap("personalize.page.analog")
        tap("theme.resetAnalogStyle")
        tap("personalize.done")
    }

    func testCompactClockOptionsAndSafeTabs() {
        let dinoSpacing = app.staticTexts["personalize.spikes.label"].frame.minY - app.staticTexts["personalize.bandana.label"].frame.minY
        let dinoRowCenters = (app.buttons["personalize.bandana.red"].frame.midY + app.buttons["personalize.spikes.red"].frame.midY) / 2
        XCTAssertEqual(app.staticTexts["personalize.spikes.label"].frame.midY, dinoRowCenters, accuracy: 2)
        let dinoRestoreGap = app.buttons["personalize.resetColors"].frame.minY - app.buttons["personalize.belly.red"].frame.maxY
        XCTAssertLessThanOrEqual(dinoRestoreGap, 18, "The restore label stays close to the final color row")
        tap("onboarding.next")
        let numbers = app.descendants(matching: .any)["theme.analogNumerals"]
        let shapes = app.descendants(matching: .any)["theme.analogShape"]
        let hour = app.staticTexts["theme.dino.hourHand.label"]
        let minute = app.staticTexts["theme.dino.minuteHand.label"]
        XCTAssertLessThan(numbers.frame.maxY, shapes.frame.minY)
        XCTAssertLessThan(shapes.frame.maxY, hour.frame.minY)
        XCTAssertLessThanOrEqual(shapes.frame.height, 82)
        XCTAssertEqual(minute.frame.minY - hour.frame.minY, dinoSpacing, accuracy: 2)
        let analogRowCenters = (app.buttons["theme.dino.hourHand.navy"].frame.midY + app.buttons["theme.dino.minuteHand.navy"].frame.midY) / 2
        XCTAssertEqual(minute.frame.midY, analogRowCenters, accuracy: 2)
        XCTAssertFalse(app.staticTexts["theme.analogNumerals.label"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["theme.hands"].exists)
        tap("theme.analogNumerals.roman")
        tap("theme.analogShape.octagon")
        saveScreenshot("analog-compact-options-order")
        tap("onboarding.next")
        let digits = app.staticTexts["theme.dino.digitColor.label"]
        let display = app.staticTexts["theme.dino.display.label"]
        XCTAssertEqual(display.frame.minY - digits.frame.minY, dinoSpacing, accuracy: 2)
        let digitalRowCenters = (app.buttons["theme.dino.digitColor.navy"].frame.midY + app.buttons["theme.dino.display.black"].frame.midY) / 2
        XCTAssertEqual(display.frame.midY, digitalRowCenters, accuracy: 2)
        let numeralTitle = app.staticTexts["theme.numerals.label"]
        XCTAssertEqual(numeralTitle.frame.height, digits.frame.height, accuracy: 0.5)
        XCTAssertEqual(app.buttons["theme.numerals.rounded"].frame.minY - numeralTitle.frame.maxY,
                       UIDevice.current.userInterfaceIdiom == .pad ? 26 : 20, accuracy: 2)
        XCTAssertLessThanOrEqual(app.buttons["theme.resetDigitalStyle"].frame.minY - app.buttons["theme.numerals.classic"].frame.maxY, 18)
        for style in ["rounded", "digital", "modern", "classic"] {
            let choice = app.buttons["theme.numerals." + style]
            XCTAssertTrue(choice.exists)
            XCTAssertFalse(choice.staticTexts[choice.label].exists)
        }
        RunLoop.current.run(until: Date().addingTimeInterval(0.4))
        saveScreenshot("digital-shared-spacing-and-clock-only-styles")
        tap("onboarding.customClock")
        tap("header.dino")
        for page in ["dino", "analog", "digital", "analog"] {
            let button = app.buttons["personalize.page." + page]
            XCTAssertTrue(button.isHittable)
            // The top of each tab must remain tappable below the sheet grabber.
            button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
            XCTAssertTrue(app.buttons["personalize.done"].isHittable)
        }
        saveScreenshot("personalize-tabs-safe-top-margin")
        tap("personalize.done")
        begin(1)
        tap("header.dino")
        tap("personalize.page.analog")
        tap("theme.resetAnalogStyle")
        tap("personalize.done")
        XCTAssertTrue(app.staticTexts["1/5"].exists)
        XCTAssertFalse(app.staticTexts["XII"].exists)
    }

    func testCustomizationButtonsColorsAndTypography() {
        for code in ["nl", "en"] {
            launchUsingDeviceLanguage(code, locale: code == "nl" ? "nl_NL" : "en_GB")
            let labelHeight = app.staticTexts["personalize.bandana.label"].frame.height
            let titleHeight = app.staticTexts["onboarding.title"].frame.height
            for part in ["spikes", "body", "belly"] {
                XCTAssertEqual(app.staticTexts["personalize.\(part).label"].frame.height, labelHeight, accuracy: 0.5)
            }
            saveScreenshot("customization-typography-dino-" + code)
            tap("onboarding.next")
            let normal = app.buttons["theme.analogNumerals.normal"].frame
            let roman = app.buttons["theme.analogNumerals.roman"].frame
            let circle = app.buttons["theme.analogShape.circle"].frame
            let square = app.buttons["theme.analogShape.square"].frame
            let octagon = app.buttons["theme.analogShape.octagon"].frame
            // AX includes the selected outline; allow its one-point edge rounding.
            XCTAssertEqual(normal.minX, circle.minX, accuracy: 2)
            XCTAssertEqual(roman.maxX, octagon.maxX, accuracy: 2)
            XCTAssertEqual(normal.width, roman.width, accuracy: 2)
            XCTAssertEqual(roman.minX - normal.maxX, square.minX - circle.maxX, accuracy: 2)
            XCTAssertEqual(app.staticTexts["onboarding.title"].frame.height, titleHeight, accuracy: 0.5)
            for part in ["hourHand", "minuteHand", "face", "rim"] {
                XCTAssertEqual(app.staticTexts["theme.dino.\(part).label"].frame.height, labelHeight, accuracy: 0.5)
            }
            tap("theme.analogNumerals.roman")
            saveScreenshot("customization-typography-analog-" + code)
            tap("onboarding.next")
            XCTAssertEqual(app.staticTexts["onboarding.title"].frame.height, titleHeight, accuracy: 0.5)
            for part in ["digitColor", "display"] {
                XCTAssertEqual(app.staticTexts["theme.dino.\(part).label"].frame.height, labelHeight, accuracy: 0.5)
                let names = part == "digitColor" ? ["navy", "orange", "green", "red", "white"] : ["black", "navy", "teal", "yellow", "white"]
                let colors = names.map { app.buttons["theme.dino.\(part)." + $0].frame }
                for (first, second) in zip(colors, colors.dropFirst()) { XCTAssertLessThan(first.minX, second.minX) }
            }
            XCTAssertEqual(app.staticTexts["theme.numerals.label"].frame.height, labelHeight, accuracy: 0.5)
            tap("theme.dino.display.teal")
            tap("theme.dino.digitColor.orange")
            saveScreenshot("customization-typography-digital-" + code)
            tap("onboarding.customClock")
            tap("header.dino")
            let gameHeight = app.staticTexts["personalize.bandana.label"].frame.height
            for page in ["analog", "digital"] {
                tap("personalize.page." + page)
                let label = page == "analog" ? "hourHand" : "digitColor"
                XCTAssertEqual(app.staticTexts["theme.dino.\(label).label"].frame.height, gameHeight, accuracy: 0.5)
            }
            saveScreenshot("customization-typography-game-" + code)
            tap("personalize.done")
        }
    }

    private func assertPreviewShowsCurrentTime(_ analog: Bool) {
        let before = Date()
        let preview = app.descendants(matching: .any)[analog ? "theme.analog.preview" : "theme.digital.preview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        if analog { return }
        let time = preview.label.replacingOccurrences(of: ", ", with: "")
        let after = Date()
        let expected = [before, after].map { date in
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            return String(format: "%02d:%02d", components.hour!, components.minute!)
        }
        XCTAssertTrue(expected.contains(time ?? ""), "Preview must show current local time: \(time ?? "missing") vs \(expected)")
    }

    private func assertClockWarningBelowPreview(_ analog: Bool) {
        let warning = app.staticTexts[analog ? "theme.analog.sameColors" : "theme.digital.sameColors"]
        let preview = app.descendants(matching: .any)[analog ? "theme.analog.preview" : "theme.digital.preview"]
        let options = app.scrollViews[analog ? "theme.options.analog" : "theme.options.digital"]
        XCTAssertTrue(warning.waitForExistence(timeout: 5))
        XCTAssertEqual(warning.label, "O nee, nu kun je de tijd niet zien!")
        XCTAssertGreaterThanOrEqual(warning.frame.minY, preview.frame.maxY)
        XCTAssertLessThanOrEqual(warning.frame.maxY, options.frame.minY)
        let footer = editorFooter
        if footer.exists { XCTAssertLessThanOrEqual(options.frame.maxY, footer.frame.minY) }
    }

    func testWelcomeTopTitlesDeviceLanguageAndPreviewSwipes() {
        launchUsingDeviceLanguage("en-GB", locale: "en_GB")
        XCTAssertEqual(app.staticTexts["onboarding.title"].label, "Make your dino")
        XCTAssertFalse(app.buttons["language.picker"].exists)
        saveScreenshot("welcome-device-language-english")
        launchUsingDeviceLanguage("nl-BE", locale: "nl_BE")
        let title = app.staticTexts["onboarding.title"]
        XCTAssertEqual(title.label, "Maak jouw dino")
        XCTAssertLessThan(title.frame.minY, app.frame.minY + 120)
        XCTAssertEqual(title.frame.midX, app.frame.midX, accuracy: 1)
        XCTAssertFalse(app.buttons["onboarding.back"].exists)
        XCTAssertFalse(app.buttons["language.picker"].exists)
        XCTAssertEqual(app.staticTexts["personalize.bandana.label"].frame.midX, app.frame.midX, accuracy: 1)
        saveScreenshot("welcome-top-title-dino")
        swipeWelcomePreview("personalize.preview", forward: true)
        XCTAssertEqual(title.label, "Maak jouw analoge klok")
        XCTAssertLessThan(title.frame.minY, app.frame.minY + 120)
        XCTAssertFalse(app.staticTexts["Vorm"].exists)
        for part in ["hourHand", "minuteHand", "face", "rim"] {
            XCTAssertEqual(app.staticTexts["theme.dino.\(part).label"].frame.midX, app.frame.midX, accuracy: 1)
        }
        tap("theme.dino.face.black")
        saveScreenshot("welcome-top-title-analog")
        swipeWelcomePreview("theme.analog.preview", forward: false)
        XCTAssertEqual(title.label, "Maak jouw dino")
        swipeWelcomePreview("personalize.preview", forward: true)
        swipeWelcomePreview("theme.analog.preview", forward: true)
        XCTAssertEqual(title.label, "Maak jouw digitale klok")
        XCTAssertLessThan(title.frame.minY, app.frame.minY + 120)
        XCTAssertFalse(app.staticTexts["Vorm"].exists)
        tap("theme.dino.display.white")
        assertClockWarningBelowPreview(false)
        saveScreenshot("welcome-top-title-digital-red-warning")
        swipeWelcomePreview("theme.digital.preview", forward: false)
        XCTAssertEqual(title.label, "Maak jouw analoge klok")
        tap("onboarding.next")
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (UIDevice.current.userInterfaceIdiom == .pad ? self.app.frame.width > self.app.frame.height : self.app.frame.width < self.app.frame.height)
        }, object: nil)
        wait(for: [landscape], timeout: 8)
        RunLoop.current.run(until: Date().addingTimeInterval(0.7))
        XCTAssertTrue(app.buttons["onboarding.customClock"].isHittable)
        saveScreenshot("welcome-top-title-landscape")
        tap("onboarding.customClock")
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 5))
    }

    func testPersonalizerGreenFootersAndCenteredOptions() {
        onboard()
        for page in ["dino", "analog", "digital"] {
            tap("header.dino")
            if page != "dino" { tap("personalize.page.\(page)") }
            let done = app.buttons["personalize.done"]
            XCTAssertTrue(done.isHittable)
            XCTAssertGreaterThan(done.frame.minY, app.frame.midY)
            XCTAssertEqual(done.frame.midX, app.frame.midX, accuracy: 1)
            XCTAssertFalse(app.navigationBars.buttons["personalize.done"].exists)
            if page != "dino" {
                let options = app.scrollViews["theme.options.\(page)"]
                XCTAssertLessThanOrEqual(options.frame.maxY, done.frame.minY)
                XCTAssertFalse(app.staticTexts["Vorm"].exists)
                if page == "digital" {
                    tap("theme.dino.display.white")
                    assertClockWarningBelowPreview(false)
                }
            }
            saveScreenshot("personalize-green-footer-" + page)
            tap("personalize.done")
            XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 5))
        }
        begin(1)
        tap("header.dino")
        tap("personalize.page.analog")
        let done = app.buttons["personalize.done"]
        let footerY = done.frame.minY
        tap("theme.analogNumerals.roman")
        XCTAssertEqual(done.frame.minY, footerY, accuracy: 1)
        saveScreenshot("personalize-green-footer-in-level")
        tap("personalize.done")
        XCTAssertTrue(app.staticTexts["1/5"].exists)
    }

    func testClockColorFallbackAndCurrentTime() {
        tap("onboarding.next")
        assertPreviewShowsCurrentTime(true)
        tap("theme.analogShape.octagon")
        chooseClockCustomColor("face", hex: "193B53") // Same as the short hand.
        assertClockWarningBelowPreview(true)
        XCTAssertTrue(app.buttons["onboarding.next"].isEnabled)
        saveScreenshot("welcome-analog-matching-colors")
        tap("onboarding.next")
        assertPreviewShowsCurrentTime(false)
        let notation = app.descendants(matching: .any)["theme.hourNotation"]
        let digits = app.staticTexts["theme.dino.digitColor.label"]
        XCTAssertLessThan(notation.frame.maxY, digits.frame.minY)
        tap("theme.hourNotation.twelve")
        let formatWarning = app.staticTexts["theme.digital.differentNotation"]
        XCTAssertTrue(formatWarning.waitForExistence(timeout: 2))
        XCTAssertEqual(formatWarning.label, "Let op: tijdweergave is anders dan op dit apparaat")
        XCTAssertTrue(app.buttons["onboarding.customClock"].isEnabled)
        let preview = app.descendants(matching: .any)["theme.digital.preview"]
        XCTAssertTrue(preview.label.contains("AM") || preview.label.contains("PM"))
        tap("theme.hourNotation.twentyFour")
        XCTAssertFalse(formatWarning.exists)
        tap("theme.dino.display.white") // Same as the digits.
        tap("theme.numerals.classic")
        assertClockWarningBelowPreview(false)
        XCTAssertTrue(app.buttons["onboarding.customClock"].isEnabled)
        saveScreenshot("welcome-digital-matching-colors")
        tap("onboarding.customClock")
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        begin(1)
        tap("header.dino")
        tap("personalize.page.analog")
        assertPreviewShowsCurrentTime(true)
        XCTAssertFalse(app.buttons["personalize.resetAnalogClock"].exists)
        tap("theme.analogShape.square")
        chooseClockCustomColor("face", hex: "BC5518") // Same as the long hand.
        assertClockWarningBelowPreview(true)
        tap("personalize.page.digital")
        assertPreviewShowsCurrentTime(false)
        XCTAssertFalse(app.descendants(matching: .any)["theme.digitalShape"].exists)
        XCTAssertFalse(app.buttons["personalize.resetDigitalClock"].exists)
        tap("theme.dino.display.white")
        assertClockWarningBelowPreview(false)
        XCTAssertTrue(app.buttons["personalize.done"].isEnabled)
        saveScreenshot("personalize-matching-colors")
        tap("personalize.done")
        XCTAssertTrue(app.staticTexts["1/5"].exists)
        tap("header.dino")
        tap("personalize.page.analog")
        tap("personalize.page.digital")
        XCTAssertFalse(app.descendants(matching: .any)["theme.digitalShape"].exists)
        tap("personalize.done")
        XCTAssertTrue(app.staticTexts["1/5"].exists)
    }

    func testWelcomeClockCustomization() {
        launchUsingDeviceLanguage("en-GB", locale: "en_GB")
        tap("onboarding.next")
        XCTAssertTrue(app.staticTexts["Make your analog clock"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["theme.digital.preview"].exists)
        XCTAssertFalse(app.buttons["Playful"].exists)
        for title in ["hourHand", "minuteHand", "face", "rim"] {
            XCTAssertTrue(app.descendants(matching: .any)["theme.dino.\(title).custom"].exists)
        }
        for shape in ["circle", "square", "octagon"] {
            tap("theme.analogShape.\(shape)")
            saveScreenshot("welcome-analog-\(shape)")
        }
        tap("theme.dino.face.blue")
        tap("onboarding.next")
        XCTAssertTrue(app.staticTexts["Make your digital clock"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["theme.analog.preview"].exists)
        tap("theme.dino.digitColor.white")
        tap("theme.dino.display.white")
        XCTAssertTrue(app.staticTexts["theme.digital.sameColors"].exists)
        XCTAssertTrue(app.buttons["onboarding.customClock"].isEnabled)
        saveScreenshot("welcome-digital-same-colors")
        tap("theme.dino.display.navy")
        XCTAssertFalse(app.staticTexts["theme.digital.sameColors"].exists)
        XCTAssertTrue(app.buttons["onboarding.customClock"].isEnabled)
        XCTAssertFalse(app.descendants(matching: .any)["theme.digitalShape"].exists)
        for font in ["rounded", "digital", "modern", "classic"] {
            tap("theme.numerals.\(font)")
            saveScreenshot("welcome-digital-font-\(font)")
        }
        XCUIDevice.shared.orientation = .landscapeLeft
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(app.buttons["onboarding.customClock"].isHittable)
        tap("theme.numerals.digital")
        tap("theme.numerals.classic")
        saveScreenshot("welcome-digital-landscape")
        XCUIDevice.shared.orientation = .portrait
        swipeWelcomePreview("theme.digital.preview", forward: false)
        XCTAssertTrue(app.staticTexts["Make your analog clock"].waitForExistence(timeout: 5))
        tap("theme.analogShape.octagon")
        tap("theme.dino.face.blue")
        tap("onboarding.next")
        tap("onboarding.customClock")
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        openClockPage("digital")
        XCTAssertFalse(app.descendants(matching: .any)["theme.digitalShape"].exists)
        revealThemeChoice("theme.numerals.classic")
        tap("theme.dino.display.white")
        XCTAssertTrue(app.buttons["personalize.done"].isEnabled)
        tap("theme.dino.digitColor.navy")
        XCTAssertTrue(app.buttons["personalize.done"].isEnabled)
        tap("personalize.done")
    }

    func testCustomClockAndSettings() {
        onboard(custom: true)
        openClockPage("analog")
        let blue = app.buttons["theme.dino.face.blue"]
        XCTAssertTrue(blue.waitForExistence(timeout: 5))
        tap("theme.dino.face.green")
        tap("personalize.done")
        app.terminate(); app.launch()
        openClockPage("analog")
        saveScreenshot("custom-clocks")
    }

    func testAdaptiveWelcomePracticeAndSettingsPresentation() {
        func activate(_ identifier: String) {
            let button = app.buttons[identifier]
            let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                button.exists && button.isHittable
            }, object: nil)
            wait(for: [ready], timeout: 6)
            button.tap()
        }
        func capture(_ name: String) {
            // SwiftUI updates AX frames before the page fade/rotation has finished.
            RunLoop.current.run(until: Date().addingTimeInterval(0.6))
            saveScreenshot(name)
        }
        let tablet = UIDevice.current.userInterfaceIdiom == .pad
        let title = app.staticTexts["onboarding.title"]
        let preview = app.descendants(matching: .any)["personalize.preview"]
        XCTAssertEqual(title.frame.midX, app.frame.midX, accuracy: 1)
        XCTAssertGreaterThanOrEqual(preview.frame.width, tablet ? 250 : 170)
        XCTAssertGreaterThanOrEqual(app.buttons["personalize.bandana.red"].frame.height, tablet ? 58 : 44)
        XCTAssertTrue(app.buttons["personalize.belly.pink"].isHittable)
        capture("adaptive-welcome-dino")
        if tablet {
            XCUIDevice.shared.orientation = .landscapeLeft
            let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                self.app.frame.width > self.app.frame.height
            }, object: nil)
            wait(for: [landscape], timeout: 8)
            if app.frame.height < 900 {
                XCTAssertLessThan(preview.frame.maxX, app.staticTexts["personalize.bandana.label"].frame.minX)
            }
            XCTAssertTrue(app.buttons["personalize.belly.pink"].isHittable)
            XCTAssertTrue(app.buttons["onboarding.next"].isHittable)
            capture("adaptive-welcome-landscape")
            XCUIDevice.shared.orientation = .portrait
            let portrait = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                self.app.frame.width < self.app.frame.height
            }, object: nil)
            wait(for: [portrait], timeout: 8)
        }
        activate("onboarding.next")
        let analog = app.descendants(matching: .any)["theme.analog.preview"]
        XCTAssertGreaterThanOrEqual(analog.frame.width, tablet ? 250 : 170)
        capture("adaptive-welcome-analog")
        activate("onboarding.next")
        XCTAssertTrue(app.buttons["theme.numerals.rounded"].isHittable)
        capture("adaptive-welcome-digital")
        activate("onboarding.customClock")
        activate("header.practice")
        let options = app.scrollViews["practice.options"]
        XCTAssertTrue(options.waitForExistence(timeout: 5))
        if tablet {
            XCTAssertLessThan(options.frame.minY, app.frame.height * 0.15, "The iPad sheet opens near the top")
            XCTAssertGreaterThan(options.frame.width, app.frame.width * 0.7)
            XCTAssertGreaterThan(options.frame.minY, 20, "The map keeps a visible overlap above the sheet")
        }
        XCTAssertTrue(app.buttons["practice.start"].isHittable)
        capture("adaptive-practice-sheet")
        selectPractice("practice.order.mix")
        XCTAssertTrue(app.buttons["practice.start"].isHittable)
        activate("practice.close")
        activate("header.settings")
        let settingsTitle = app.staticTexts["settings.title"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5))
        XCTAssertEqual(settingsTitle.frame.midX, app.frame.midX, accuracy: 1)
        XCTAssertFalse(app.navigationBars.buttons["Klaar"].exists)
        let done = app.buttons["settings.done"]
        XCTAssertTrue(done.isHittable)
        XCTAssertGreaterThan(done.frame.minY, app.frame.height * 0.7)
        activate("settings.language")
        XCTAssertTrue(app.buttons["language.option.en"].isHittable)
        capture("adaptive-settings-dutch")
        activate("language.option.en")
        let englishTitle = NSPredicate { _, _ in settingsTitle.exists && settingsTitle.label == "Settings" }
        expectation(for: englishTitle, evaluatedWith: nil)
        waitForExpectations(timeout: 5)
        capture("adaptive-settings-english")
        activate("settings.language")
        activate("language.option.nl")
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        activate("settings.done")
        let returnedToMap = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !settingsTitle.exists && self.app.buttons["header.settings"].isHittable
        }, object: nil)
        wait(for: [returnedToMap], timeout: 6)
        activate("header.settings")
        settingsTitle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.96)))
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !settingsTitle.exists && self.app.buttons["header.settings"].isHittable
        }, object: nil)
        wait(for: [dismissed], timeout: 6)
    }

    func testSettingsPreferencesPersist() {
        onboard()
        openSettings()
        let sound = app.descendants(matching: .any)["settings.soundEffects"].switches.firstMatch
        let haptics = app.descendants(matching: .any)["settings.haptics"].switches.firstMatch
        let contrast = app.descendants(matching: .any)["settings.highContrast"].switches.firstMatch
        let cloud = app.descendants(matching: .any)["settings.icloudSync"].switches.firstMatch
        XCTAssertTrue(sound.waitForExistence(timeout: 5))
        XCTAssertEqual(sound.value as? String, "1")
        XCTAssertEqual(haptics.value as? String, "1")
        XCTAssertEqual(contrast.value as? String, "0")
        XCTAssertEqual(cloud.value as? String, "0")
        saveScreenshot("settings-preferences")
        tap("settings.soundEffects"); tap("settings.haptics")
        tap("settings.highContrast"); tap("settings.icloudSync")
        XCTAssertEqual(sound.value as? String, "0")
        XCTAssertEqual(haptics.value as? String, "0")
        XCTAssertEqual(contrast.value as? String, "1")
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
        tap("settings.language")
        tap("language.option.en")
        let englishLabels = NSPredicate { _, _ in sound.label == "Sound effects" }
        expectation(for: englishLabels, evaluatedWith: nil)
        waitForExpectations(timeout: 5)
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
        XCTAssertTrue(app.buttons["question.showAnswer"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["question.showAnswer"].label, "Show answer")
        tap("question.showAnswer")
        XCTAssertTrue(app.buttons["question.next"].exists)
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
        // Introduce this skill once; an unseen skill deliberately starts with two choices.
        begin(1)
        var trainingRNG = SeededGenerator(seed: seed)
        let training = DinoQuestionGenerator.generate(level: DinoLevelCatalog.level(1)!, using: &trainingRNG)[0]
        tap("question.option.\(training.options.firstIndex(of: training.target)!)")
        XCTAssertTrue(app.staticTexts["2/5"].waitForExistence(timeout: 5))
        tap("header.pause")
        tap("game.exit.confirm")
        begin(10)
        XCTAssertFalse(app.buttons["demo.ready"].exists)
        let options = (0..<4).map { app.buttons["question.option.\($0)"] }
        saveScreenshot("portrait-four-answer-layout")
        XCTAssertTrue(options.allSatisfy { $0.waitForExistence(timeout: 5) })
        XCTAssertFalse(app.buttons["question.option.4"].exists)
        XCTAssertEqual(options[0].frame.midY, options[1].frame.midY, accuracy: 2)
        XCTAssertEqual(options[2].frame.midY, options[3].frame.midY, accuracy: 2)
        XCTAssertGreaterThan(options[2].frame.midY, options[0].frame.midY)
        func targetClockFrame() -> CGRect {
            app.descendants(matching: .any).matching(identifier: "question.targetClock")
                .allElementsBoundByIndex.map(\.frame).reduce(CGRect.null) { $0.union($1) }
        }
        let title = app.staticTexts["question.title"]
        XCTAssertEqual(targetClockFrame().midX, title.frame.midX, accuracy: 1)
        let originalCenter = targetClockFrame().midX
        var rng = SeededGenerator(seed: seed)
        let first = DinoQuestionGenerator.generate(level: DinoLevelCatalog.level(10)!, using: &rng)[0]
        let wrong = first.options.firstIndex { $0 != first.target }!
        tap("question.option.\(wrong)")
        XCTAssertTrue(app.buttons["question.showAnswer"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["question.showAnswer"].label, "Toon antwoord")
        XCTAssertFalse(app.buttons["question.next"].exists)
        XCTAssertFalse(options[wrong].isEnabled)
        XCTAssertTrue(options.enumerated().filter { $0.offset != wrong }.allSatisfy { $0.element.isEnabled })
        RunLoop.current.run(until: Date().addingTimeInterval(3))
        XCTAssertTrue(app.staticTexts["1/10"].exists, "Wrong feedback must remain until the child taps Next")
        XCTAssertTrue(app.buttons["question.showAnswer"].isHittable)
        XCTAssertTrue(options[3].isHittable, "All four answers remain visible above the feedback")
        XCTAssertFalse(app.descendants(matching: .any)["question.feedback"].exists)
        saveScreenshot("companion-level-wrong-portrait")
        XCTAssertTrue(app.descendants(matching: .any)["dino.wrongAnswer"].exists, "The wrong-answer pose remains until Next")
        let reaction = app.descendants(matching: .any)["dino.wrongAnswer"]
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "dino.wrongAnswer").count, 1)
        XCTAssertGreaterThanOrEqual(reaction.frame.minY, 0)
        assertCompanionInPortrait(reaction)
        XCTAssertEqual(targetClockFrame().midX, originalCenter, accuracy: 1, "Dino cannot displace the clock after an answer")
        saveScreenshot("wrong-answer-waits")
        tap("question.showAnswer")
        XCTAssertTrue(app.buttons["question.next"].exists)
        XCTAssertTrue(options.allSatisfy { !$0.isEnabled })
        tap("question.next")
        XCTAssertTrue(app.staticTexts["2/10"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["dino.wrongAnswer"].exists)
    }

    func testCompanionPortraitWithCustomColorsAndStickyFooter() {
        onboard()
        tap("header.dino")
        for (part, color) in [("bandana", "purple"), ("spikes", "purple"), ("body", "pink")] {
            tap("personalize.\(part).\(color)")
        }
        tap("personalize.done")
        tap("header.practice")
        selectPractice("practice.type.chooseAnalog")
        tap("practice.start")
        let idle = app.descendants(matching: .any)["dino.character"]
        XCTAssertTrue(idle.waitForExistence(timeout: 5))
        assertCompanionInPortrait(idle)
        let smallQuestionSize = idle.frame.width
        let beforeScroll = idle.frame
        saveScreenshot("companion-pink-idle-portrait")
        app.swipeUp()
        XCTAssertEqual(idle.frame.midY, beforeScroll.midY, accuracy: 2, "Scrolling the question never scrolls Dino away")
        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.chooseAnalog)), seed: seed)
        answerPracticeWrong(generator.next(index: 0))
        let reaction = app.descendants(matching: .any)["dino.wrongAnswer"]
        XCTAssertTrue(reaction.waitForExistence(timeout: 5))
        assertCompanionInPortrait(reaction)
        let next = app.buttons["question.next"]
        XCTAssertTrue(next.isHittable)
        assertStickyAnswerButton(next)
        let buttonFrame = next.frame
        app.swipeUp()
        XCTAssertEqual(next.frame, buttonFrame, "The answer button stays fixed while questions scroll")
        saveScreenshot("companion-pink-wrong-portrait")
        tap("question.next")
        tap("header.pause")
        selectPractice("practice.type.match")
        tap("practice.start")
        XCTAssertTrue(idle.waitForExistence(timeout: 5), "Expanded questions also show Dino")
        assertCompanionInPortrait(idle)
        XCTAssertLessThanOrEqual(idle.frame.width, smallQuestionSize + 2, "Dense questions retain the same recognizable companion")
        saveScreenshot("companion-large-pair-question")
        // The practice cover uses its presenter's orientation on iPhone. Rotate
        // the main game scene to verify the same portrait at a short viewport height.
        tap("header.pause")
        tap("practice.close")
        begin(10)
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscape = NSPredicate { _, _ in (UIDevice.current.userInterfaceIdiom == .pad ? self.app.frame.width > self.app.frame.height : self.app.frame.width < self.app.frame.height) && idle.exists && idle.frame.maxY <= self.app.frame.maxY + 1 }
        expectation(for: landscape, evaluatedWith: nil)
        waitForExpectations(timeout: 8)
        assertCompanionInPortrait(idle)
        if UIDevice.current.userInterfaceIdiom == .phone {
            XCTAssertEqual(idle.frame.width, smallQuestionSize, accuracy: 2, "iPhone keeps the portrait companion when the device rotates")
        }
        saveScreenshot("companion-question-landscape")
        XCUIDevice.shared.orientation = .portrait
    }

    private func assertCompanionInPortrait(_ companion: XCUIElement) {
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: companion.identifier).count, 1)
        XCTAssertGreaterThanOrEqual(companion.frame.minX, 0)
        XCTAssertLessThanOrEqual(companion.frame.maxX, app.frame.maxX + 1)
        XCTAssertLessThanOrEqual(companion.frame.maxY, app.frame.maxY + 1)
        XCTAssertGreaterThanOrEqual(companion.frame.width, 52, "Dino fills the HUD portrait")
        let portrait = app.buttons.matching(identifier: "header.dino")
            .matching(NSPredicate(format: "enabled == true")).firstMatch
        XCTAssertTrue(portrait.frame.contains(CGPoint(x: companion.frame.midX, y: companion.frame.midY)))
        XCTAssertLessThan(companion.frame.midX, app.frame.midX, "Dino stays in the upper-left portrait")
        let viewport = app.scrollViews["game.questions"]
        if viewport.exists {
            XCTAssertEqual(viewport.frame.midX, app.frame.midX, accuracy: 1)
            XCTAssertGreaterThanOrEqual(viewport.frame.minY, companion.frame.maxY - 1, "The question starts below the HUD")
            XCTAssertGreaterThan(viewport.frame.maxY, app.frame.maxY - 150, "The former bottom Dino space is available to questions")
        }
    }

    private func assertStickyAnswerButton(_ button: XCUIElement) {
        XCTAssertTrue(button.isHittable)
        XCTAssertEqual(button.frame.midX, app.frame.midX, accuracy: 1)
        XCTAssertGreaterThan(button.frame.minY, app.frame.maxY - 150)
        XCTAssertLessThanOrEqual(button.frame.maxY, app.frame.maxY - 8)
        XCTAssertGreaterThanOrEqual(button.frame.width, min(420, app.frame.width - 72))
        XCTAssertLessThanOrEqual(app.scrollViews["game.questions"].frame.maxY, button.frame.minY)
    }

    func testResponsiveOrientationsAndProportionalHUD() {
        onboard()
        let tablet = UIDevice.current.userInterfaceIdiom == .pad
        let mapScroll = app.scrollViews["map.route"]
        XCTAssertEqual(mapScroll.frame.minX, app.frame.minX, accuracy: 1)
        XCTAssertEqual(mapScroll.frame.maxX, app.frame.maxX, accuracy: 1)
        let mapCompanion = app.descendants(matching: .any)["map.dino.1"]
        XCTAssertTrue(mapCompanion.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(mapCompanion.frame.width, tablet ? 180 : 112)
        saveScreenshot("responsive-map-portrait")
        let settings = app.buttons["header.settings"]
        let portraitRatio = settings.frame.width / settings.frame.height
        let portraitPortraitSize = app.buttons["header.dino"].frame.height
        for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            RunLoop.current.run(until: Date().addingTimeInterval(1))
            let settled = NSPredicate { _, _ in
                (tablet ? self.app.frame.width > self.app.frame.height : self.app.frame.width < self.app.frame.height)
                    && settings.exists && settings.frame.maxX <= self.app.frame.maxX
            }
            expectation(for: settled, evaluatedWith: nil)
            waitForExpectations(timeout: 8)
            RunLoop.current.run(until: Date().addingTimeInterval(0.7))
            XCTAssertEqual(settings.frame.width / settings.frame.height, portraitRatio, accuracy: 0.04,
                           "HUD cells preserve their proportions on rotation")
            XCTAssertGreaterThanOrEqual(app.buttons["header.dino"].frame.height, portraitPortraitSize * 0.75)
            XCTAssertEqual(mapScroll.frame.minX, app.frame.minX, accuracy: 1)
            XCTAssertEqual(mapScroll.frame.maxX, app.frame.maxX, accuracy: 1)
            saveScreenshot("responsive-map-\(orientation == .landscapeLeft ? "left" : "right")")
        }
        XCUIDevice.shared.orientation = .portrait
        let portrait = NSPredicate { _, _ in self.app.frame.width < self.app.frame.height }
        expectation(for: portrait, evaluatedWith: nil)
        waitForExpectations(timeout: 8)
        begin(10)
        let companion = app.descendants(matching: .any)["dino.character"]
        XCTAssertTrue(companion.waitForExistence(timeout: 5))
        let portraitCompanionSize = companion.frame.width
        assertCompanionInPortrait(companion)
        XCTAssertGreaterThanOrEqual(portraitCompanionSize, 78)
        saveScreenshot("responsive-game-portrait")
        for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            let settled = NSPredicate { _, _ in
                (tablet ? self.app.frame.width > self.app.frame.height : self.app.frame.width < self.app.frame.height)
                    && companion.exists && companion.frame.maxX <= self.app.frame.maxX + 1
            }
            expectation(for: settled, evaluatedWith: nil)
            waitForExpectations(timeout: 8)
            RunLoop.current.run(until: Date().addingTimeInterval(0.7))
            assertCompanionInPortrait(companion)
            XCTAssertGreaterThanOrEqual(companion.frame.width, 52)
            XCTAssertTrue(app.staticTexts["1/10"].exists, "Rotation preserves the running question")
            if tablet {
                let options = (0..<4).map { app.buttons["question.option.\($0)"] }.filter { $0.exists }
                XCTAssertTrue([2, 4].contains(options.count))
                XCTAssertTrue(options.allSatisfy { $0.isHittable })
                guard let first = options.first, let last = options.last else { return }
                XCTAssertEqual((first.frame.minX + last.frame.maxX) / 2, app.frame.midX, accuracy: 1)
                XCTAssertEqual(app.staticTexts["question.title"].frame.midX, app.frame.midX, accuracy: 1)
                XCTAssertEqual(app.descendants(matching: .any)["question.targetClock"].frame.midX, app.frame.midX, accuracy: 1)
                for option in options {
                    XCTAssertEqual(option.frame.midY, options[0].frame.midY, accuracy: 1)
                    XCTAssertLessThanOrEqual(option.frame.maxY, app.scrollViews["game.questions"].frame.maxY)
                    XCTAssertLessThanOrEqual(option.frame.maxX, app.frame.maxX)
                    XCTAssertGreaterThanOrEqual(option.frame.minX, app.frame.minX)
                }
            }
            saveScreenshot("responsive-game-\(orientation == .landscapeLeft ? "left" : "right")")
        }
        XCUIDevice.shared.orientation = .portrait
        expectation(for: portrait, evaluatedWith: nil)
        waitForExpectations(timeout: 8)
        answerFirstQuestionWrong(10, advance: true)
        tap("header.pause")
        XCTAssertTrue(app.buttons["game.exit.cancel"].waitForExistence(timeout: 5))
        tap("game.exit.cancel")
        XCTAssertTrue(app.staticTexts["2/10"].exists)
        saveScreenshot("responsive-game-resumed")
    }

    func testCenteredPracticeClocksAndCompanionInPortrait() {
        openPractice()
        selectPractice("practice.type.match")
        tap("practice.start")
        let tablet = UIDevice.current.userInterfaceIdiom == .pad
        let companion = app.descendants(matching: .any)["dino.character"]
        XCTAssertTrue(companion.waitForExistence(timeout: 5))
        func checkBoard(_ name: String) {
            assertCompanionInPortrait(companion)
            let first = app.buttons["question.match.clock.0"]
            let right = app.buttons["question.match.time.0"]
            XCTAssertTrue(first.waitForExistence(timeout: 5))
            XCTAssertEqual(first.frame.width, right.frame.width, accuracy: 1)
            XCTAssertEqual(first.frame.height, right.frame.height, accuracy: 1)
            XCTAssertGreaterThanOrEqual(first.frame.height, tablet ? 170 : 108, "Practice clocks grow with the available width")
            XCTAssertEqual((first.frame.minX + right.frame.maxX) / 2, app.frame.midX, accuracy: 1)
            XCTAssertFalse(app.staticTexts["question.match.hint"].exists, "Matching instructions belong in the example")
            XCTAssertEqual(app.staticTexts["question.title"].frame.midX, app.frame.midX, accuracy: 1)
            saveScreenshot(name)
        }
        checkBoard("centered-practice-portrait")
        if tablet {
            for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight] {
                XCUIDevice.shared.orientation = orientation
                let settled = NSPredicate { _, _ in self.app.frame.width > self.app.frame.height }
                expectation(for: settled, evaluatedWith: nil)
                waitForExpectations(timeout: 8)
                RunLoop.current.run(until: Date().addingTimeInterval(0.7))
                checkBoard("centered-practice-\(orientation == .landscapeLeft ? "left" : "right")")
            }
            XCUIDevice.shared.orientation = .portrait
        }
        // Scroll in the clear connection space, preserving all clock gestures.
        let scroll = app.scrollViews["game.questions"]
        let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.85))
        let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.25))
        start.press(forDuration: 0.05, thenDragTo: end)
        assertCompanionInPortrait(companion)
        tap("header.pause")
        selectPractice("practice.type.sortTimes")
        tap("practice.start")
        XCTAssertTrue(app.buttons["question.sort.0"].waitForExistence(timeout: 5))
        assertCompanionInPortrait(companion)
        XCTAssertGreaterThanOrEqual(app.buttons["question.sort.0"].frame.height, tablet ? 200 : 110)
        saveScreenshot("centered-practice-sorting")
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
            return (UIDevice.current.userInterfaceIdiom == .pad ? self.app.frame.width > self.app.frame.height : self.app.frame.width < self.app.frame.height) && lastOption.exists &&
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
        tap("settings.language")
        XCTAssertTrue(app.buttons["language.option.nl"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "language.option.")).count, 2)
        let english = app.descendants(matching: .any).matching(identifier: "language.option.en").firstMatch
        XCTAssertTrue(english.isHittable)
        english.tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))
        tap("settings.done")
        openClockPage("analog")
        XCTAssertTrue(app.staticTexts["Short hour hand"].waitForExistence(timeout: 5))
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
        let character = app.descendants(matching: .any)["map.dino.2"]
        let node = app.buttons["map.level.2"]
        XCTAssertEqual(character.frame.midX, node.frame.midX, accuracy: 1)
        // Match the shared foot baseline also checked by testDinoStandsOnCompletedLevel.
        XCTAssertEqual(character.frame.maxY, node.frame.midY + 12, accuracy: 3)
        XCTAssertFalse(character.label.contains("Sam"))
        XCTAssertTrue(node.isHittable)
        saveScreenshot("jungle-earned-stars")
    }

    func testLevelStartHeaderExpansionAndWorldThemes() {
        let worlds = UIDevice.current.userInterfaceIdiom == .pad ? [2, 5, 10] : [2, 1, 3, 4, 5, 6, 7, 8, 9, 10]
        for world in worlds {
            let levelID = world == 2 ? 18 : (world - 1) * 10 + 1
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.start-card.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = String(levelID)
            app.launch()
            XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 8))
            revealMapNode(levelID).tap()
            let header = app.buttons["level.details"]
            XCTAssertTrue(header.waitForExistence(timeout: 5))
            XCTAssertEqual(header.label, "Level \(levelID), In dit level")
            XCTAssertEqual(header.value as? String, "Dicht")
            XCTAssertFalse(app.descendants(matching: .any)["level.questions"].exists)
            saveScreenshot("start-card-world-\(world)-closed")
            if world != 2 { continue }

            let sign = app.descendants(matching: .any)["level.outlineCard"].firstMatch
            let closedSign = sign.frame
            let playY = app.buttons["level.play"].frame.minY
            header.tap()
            XCTAssertEqual(header.value as? String, "Open")
            let questions = app.descendants(matching: .any)["level.questions"].firstMatch
            XCTAssertTrue(questions.waitForExistence(timeout: 3))
            XCTAssertEqual(sign.frame.minY, closedSign.minY, accuracy: 1)
            XCTAssertGreaterThan(sign.frame.height, closedSign.height + 100)
            for index in 0..<3 {
                let row = app.descendants(matching: .any)["level.question.\(index)"].firstMatch
                XCTAssertTrue(row.exists)
                XCTAssertGreaterThanOrEqual(row.frame.minY, header.frame.maxY)
                XCTAssertLessThanOrEqual(row.frame.maxY, sign.frame.maxY)
                XCTAssertGreaterThanOrEqual(row.frame.minX, sign.frame.minX)
                XCTAssertLessThanOrEqual(row.frame.maxX, sign.frame.maxX)
            }
            XCTAssertGreaterThan(app.buttons["level.play"].frame.minY, playY + 100)
            XCTAssertTrue(app.buttons["level.play"].isHittable)
            saveScreenshot("start-card-desert-expanded")
            header.tap()
            let collapsed = NSPredicate { _, _ in abs(sign.frame.height - closedSign.height) < 1 }
            expectation(for: collapsed, evaluatedWith: nil)
            waitForExpectations(timeout: 3)
            XCTAssertFalse(questions.exists)
            XCTAssertEqual(sign.frame.height, closedSign.height, accuracy: 1)
            XCTAssertEqual(app.buttons["level.play"].frame.minY, playY, accuracy: 1)
            tap("level.map")
            revealMapNode(levelID).tap()
            XCTAssertEqual(header.value as? String, "Dicht", "Reopening a level starts with its outline tucked away")
            tap("level.play")
            XCTAssertTrue(app.buttons["header.pause"].waitForExistence(timeout: 5))
        }
    }

    func testLevelStartBossOutlineScrollsInEnglish() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "19"
        app.launchArguments = ["-settings.languageOverride", "en"]
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 8))
        revealMapNode(20).tap()
        let header = app.buttons["level.details"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        XCTAssertEqual(header.label, "Level 20, In this level")
        XCTAssertEqual(header.value as? String, "Closed")
        header.tap()
        XCTAssertEqual(header.value as? String, "Open")
        let rows = app.buttons.matching(NSPredicate(format: "identifier MATCHES %@", "level.question.[0-9]+"))
        XCTAssertEqual(rows.count, 10)
        saveScreenshot("start-card-desert-boss-english")
        let scroll = app.scrollViews.containing(.button, identifier: "level.details").firstMatch
        for _ in 0..<5 {
            if app.buttons["level.play"].isHittable { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(app.buttons["level.play"].isHittable)
        XCTAssertTrue(app.descendants(matching: .any)["level.question.9"].firstMatch.isHittable)
        saveScreenshot("start-card-desert-boss-scrolled")
        tap("level.play")
        XCTAssertTrue(app.buttons["header.pause"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["level.details"].exists)
    }

    func testLevelOutlineOpensExactPracticeCombination() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "18"
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 8))
        for (level, index, type, time) in [(11, 0, "chooseAnalog", "half"),
                                         (11, 1, "chooseAnalog", "whole"),
                                         (18, 1, "timeZone", "whole")] {
            revealMapNode(level).tap()
            tap("level.details")
            if level == 11 && index == 0 {
                let header = app.buttons["level.details"]
                let sign = app.descendants(matching: .any)["level.outlineCard"].firstMatch
                saveScreenshot("level-outline-before-collapse")
                header.tap()
                let collapsed = NSPredicate { _, _ in abs(sign.frame.height - 64) < 1 }
                expectation(for: collapsed, evaluatedWith: nil)
                waitForExpectations(timeout: 3)
                XCTAssertFalse(app.buttons["level.question.0"].exists)
                header.tap()
                XCTAssertEqual(header.value as? String, "Open")
                XCTAssertTrue(app.buttons["level.question.0"].exists, "Reopening restores its content")
            }
            tap("level.question.\(index)")
            XCTAssertTrue(app.buttons["practice.start"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["level.details"].exists)
            let choice = app.buttons["practice.type.\(type)"]
            XCTAssertTrue(choice.waitForExistence(timeout: 5))
            XCTAssertTrue(choice.isSelected)
            XCTAssertTrue(choice.isHittable, "The preselected question is revealed automatically")
            // A late question scrolls the lazy time grid out of view. The game
            // subtitle below also verifies the actual time family after Start.
            let timeChoice = app.buttons["practice.time.\(time)"]
            if timeChoice.exists { XCTAssertTrue(timeChoice.isSelected) }
            XCTAssertTrue(app.buttons["practice.start"].isHittable)
            saveScreenshot("level-practice-preselected-\(type)-\(time)")
            tap("practice.start")
            let expectedNumber = type == "timeZone" ? "19" : "1"
            let expectedTime = time == "half" ? "Halve uren" : "Hele uren"
            let subtitle = app.staticTexts.matching(identifier: "practice.hudSubtitle")
            XCTAssertTrue(subtitle.firstMatch.waitForExistence(timeout: 5))
            let labels = subtitle.allElementsBoundByIndex.map(\.label)
            XCTAssertTrue(labels.contains(expectedNumber) || labels.contains("\(expectedNumber) · \(expectedTime)"))
            XCTAssertTrue(labels.contains { $0.contains(expectedTime) })
            tap("header.pause")
            XCTAssertTrue(app.buttons["practice.close"].waitForExistence(timeout: 5))
            tap("practice.close")
            XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 5))
        }
    }

    func testStartPointCleanCardAndExitCancel() {
        onboard()
        let marker = app.descendants(matching: .any)["map.dino.1"]
        XCTAssertTrue(marker.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(marker.frame.height, 95)
        XCTAssertLessThanOrEqual(marker.frame.height, 200)
        let start = app.buttons["map.level.1"]
        XCTAssertTrue(start.exists)
        XCTAssertFalse(app.descendants(matching: .any)["map.start"].exists)
        XCTAssertEqual(marker.frame.midX, start.frame.midX, accuracy: 1)
        XCTAssertFalse(marker.label.contains("Sam"))
        XCTAssertFalse(app.buttons["map.level.0"].exists)
        saveScreenshot("map-start")
        start.tap()
        XCTAssertFalse(app.staticTexts["5 vragen"].exists)
        XCTAssertFalse(app.staticTexts["Kies de analoge klok bij de tijd."].exists)
        saveScreenshot("level-start-card")
        tap("level.play")
        if app.buttons["demo.ready"].exists { tap("demo.ready") }
        let clock = app.descendants(matching: .any)["question.targetClock"]
        XCTAssertEqual(clock.frame.midX, app.frame.midX, accuracy: 1)
        let companion = app.descendants(matching: .any)["dino.character"]
        assertCompanionInPortrait(companion)
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

    /// Isolated result fixtures exercise the real scene, companion and navigation.
    /// Capture every biome at the same reward state, including the reordered valley/desert.
    /// Run this on compact iPhone and iPad to check the scene around the shared controls.
    func testAllWorldResultScenery() {
        let requested = ProcessInfo.processInfo.environment["DINO_TEST_WORLD_IDS"]?
            .split(separator: ",").compactMap { Int($0) }.filter { (1...10).contains($0) } ?? []
        let worlds = requested.isEmpty ? Array(1...10) : Array(Set(requested)).sorted()
        for world in worlds {
            let level = (world - 1) * 10 + 2
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.biome.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = String(level - 1)
            app.launchEnvironment["DINO_TEST_RESULT_LEVEL"] = String(level)
            app.launchEnvironment["DINO_TEST_RESULT_CORRECT"] = "5"
            app.launch()
            XCTAssertTrue(app.buttons["result.map"].waitForExistence(timeout: 8))
            RunLoop.current.run(until: Date().addingTimeInterval(3.9))
            XCTAssertEqual(app.descendants(matching: .any)["result.stars"].label, "3/3")
            XCTAssertTrue(app.staticTexts["5/5"].exists)
            for id in ["result.next", "result.retry", "result.map"] {
                let button = app.buttons[id]
                XCTAssertTrue(button.isHittable, "World \(world): \(id)")
                XCTAssertGreaterThanOrEqual(button.frame.minX, app.frame.minX)
                XCTAssertLessThanOrEqual(button.frame.maxX, app.frame.maxX)
                XCTAssertLessThanOrEqual(button.frame.maxY, app.frame.maxY - 8)
            }
            saveScreenshot("result-biome-world-\(world)")
        }
    }

    func testWorldResultButtonsAndMapSalto() {
        for world in [1, 4, 9] {
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.world-salto.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = String(world * 10 - 1)
            app.launchEnvironment["DINO_TEST_RESULT_LEVEL"] = String(world * 10)
            app.launchEnvironment["DINO_TEST_RESULT_CORRECT"] = world == 4 ? "5" : "10"
            app.launch()
            let next = app.buttons["result.next"]
            let retry = app.buttons["result.retry"]
            XCTAssertTrue(next.waitForExistence(timeout: 8))
            XCTAssertEqual(next.label, "Naar de volgende wereld")
            XCTAssertTrue(retry.isHittable)
            XCTAssertFalse(app.buttons["result.map"].exists)
            XCTAssertFalse(app.staticTexts["Wereld voltooid!"].exists)
            XCTAssertEqual(next.frame.midX, retry.frame.midX, accuracy: 1)
            XCTAssertEqual(next.frame.width, retry.frame.width, accuracy: 1)
            XCTAssertLessThan(next.frame.maxY, retry.frame.minY)
            saveScreenshot("world-\(world)-score-two-buttons")
            tap("result.next")
            let marker = app.descendants(matching: .any)["map.dino.\(world * 10 + 1)"]
            XCTAssertTrue(marker.waitForExistence(timeout: 15))
            XCTAssertFalse(app.descendants(matching: .any)["map.worldJump"].exists)
            XCTAssertFalse(app.buttons["header.pause"].exists)
            let stone = app.buttons["map.level.\(world * 10 + 1)"]
            XCTAssertTrue(stone.isHittable)
            XCTAssertEqual(marker.frame.midX, stone.frame.midX, accuracy: 2)
            XCTAssertEqual(marker.frame.maxY, stone.frame.midY + 12, accuracy: 2)
            XCTAssertGreaterThan(marker.frame.minY, app.descendants(matching: .any)["header.settings"].frame.maxY)
            saveScreenshot("world-\(world)-salto-landed")
        }
        // The last world keeps the normal score and goes back to Coming soon on the map.
        app.terminate()
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.last-world.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "99"
        app.launchEnvironment["DINO_TEST_RESULT_LEVEL"] = "100"
        app.launchEnvironment["DINO_TEST_RESULT_CORRECT"] = "10"
        app.launch()
        XCTAssertTrue(app.buttons["result.map"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["result.next"].exists)
        XCTAssertTrue(app.buttons["result.retry"].isHittable)
        XCTAssertTrue(app.staticTexts["10/10"].exists)
        saveScreenshot("world-10-score-two-buttons")
        tap("result.retry")
        XCTAssertTrue(app.buttons["header.pause"].waitForExistence(timeout: 5))
    }

    func testResultRewardStatesAndNavigation() {
        func showResult(level: Int, correct: Int, completed: Int = 0, language: String = "nl") {
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.result.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = completed > 0 ? String(completed) : nil
            app.launchEnvironment["DINO_TEST_RESULT_LEVEL"] = String(level)
            app.launchEnvironment["DINO_TEST_RESULT_CORRECT"] = String(correct)
            app.launchArguments = ["-settings.languageOverride", language]
            app.launch()
            XCTAssertTrue(app.buttons["result.retry"].waitForExistence(timeout: 8))
            RunLoop.current.run(until: Date().addingTimeInterval(3.9))
            let controls = level.isMultiple(of: 10) && correct >= 5 ? ["result.next", "result.retry"] : ["result.map", "result.retry"]
            for id in controls {
                let button = app.buttons[id]
                XCTAssertTrue(button.isHittable)
                XCTAssertGreaterThanOrEqual(button.frame.minX, app.frame.minX)
                XCTAssertLessThanOrEqual(button.frame.maxX, app.frame.maxX)
                XCTAssertLessThanOrEqual(button.frame.maxY, app.frame.maxY - 8)
            }
        }
        for (correct, stars) in [(2, 0), (3, 1), (4, 2), (5, 3)] {
            showResult(level: 2, correct: correct, completed: 1)
            XCTAssertEqual(app.descendants(matching: .any)["result.stars"].label, "\(stars)/3")
            XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "dino.pirouette").count, stars == 2 ? 1 : 0)
            XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "dino.backflip").count, stars == 3 ? 1 : 0)
            XCTAssertEqual(app.buttons["result.next"].exists, stars > 0)
            XCTAssertTrue(app.staticTexts["\(correct)/5"].exists)
            let score = app.staticTexts["\(correct)/5"]
            let levelSign = app.descendants(matching: .any)["result.level"]
            XCTAssertTrue(levelSign.exists)
            XCTAssertGreaterThan(score.frame.minY, levelSign.frame.maxY,
                                 "The score belongs in the sky directly below the wooden level sign")
            saveScreenshot("result-redesign-\(stars)-stars")
            if stars == 0 {
                tap("result.retry")
                XCTAssertTrue(app.buttons["header.pause"].waitForExistence(timeout: 5))
            } else if stars == 3 {
                tap("result.next")
                XCTAssertTrue(app.buttons["header.pause"].waitForExistence(timeout: 5))
            } else {
                tap("result.map")
                XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 5))
                if stars == 2 {
                    saveScreenshot("result-redesign-map-gold-stars")
                    tap("header.stars")
                    XCTAssertTrue(app.scrollViews["stars.overview"].waitForExistence(timeout: 5))
                    saveScreenshot("result-redesign-overview-gold-stars")
                    tap("stars.close")
                    XCTAssertTrue(app.buttons["header.stars"].waitForExistence(timeout: 5))
                }
            }
        }
        showResult(level: 10, correct: 4, completed: 9)
        XCTAssertFalse(app.descendants(matching: .any)["result.stars"].exists)
        XCTAssertFalse(app.buttons["result.next"].exists)
        saveScreenshot("result-redesign-boss-retry")
        showResult(level: 10, correct: 10, completed: 9, language: "en")
        XCTAssertFalse(app.descendants(matching: .any)["result.stars"].exists)
        XCTAssertTrue(app.buttons["result.next"].isHittable)
        saveScreenshot("result-redesign-boss-perfect-english")
        tap("result.next")
        XCTAssertTrue(app.descendants(matching: .any)["map.dino.11"].waitForExistence(timeout: 15))
        showResult(level: 12, correct: 5, completed: 11)
        XCTAssertTrue(app.buttons["result.next"].isHittable)
        saveScreenshot("result-redesign-night-world")
        // Shared simulators can keep the interface locked in portrait even while
        // the hardware rotates. Opt in after unlocking rotation on the device.
        if UIDevice.current.userInterfaceIdiom == .pad &&
            ProcessInfo.processInfo.environment["DINO_TEST_RESULT_ROTATION"] == "1" {
            app.terminate()
            XCUIDevice.shared.orientation = .landscapeLeft
            app.launch()
            XCTAssertTrue(app.buttons["result.next"].waitForExistence(timeout: 8))
            let landscape = NSPredicate { _, _ in self.app.frame.width > self.app.frame.height }
            expectation(for: landscape, evaluatedWith: nil)
            waitForExpectations(timeout: 8)
            RunLoop.current.run(until: Date().addingTimeInterval(4))
            for id in ["result.next", "result.retry", "result.map"] {
                XCTAssertTrue(app.buttons[id].isHittable)
                XCTAssertLessThanOrEqual(app.buttons[id].frame.maxY, app.frame.maxY - 8)
            }
            saveScreenshot("result-redesign-landscape-verified")
            XCUIDevice.shared.orientation = .portrait
        }
    }

    func testTwoStarPirouetteFromQuestionToStone() {
        onboard()
        tap("header.dino")
        for (part, color) in [("bandana", "blue"), ("spikes", "purple"), ("body", "pink"), ("belly", "orange")] {
            tap("personalize.\(part).\(color)")
        }
        tap("personalize.done")
        begin(1)
        play(1, correct: 4)
        let pirouette = app.descendants(matching: .any)["dino.pirouette"]
        XCTAssertTrue(pirouette.exists)
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "dino.pirouette").count, 1)
        XCTAssertFalse(app.descendants(matching: .any)["dino.backflip"].exists)
        RunLoop.current.run(until: Date().addingTimeInterval(3.5))
        XCTAssertEqual(app.descendants(matching: .any)["result.stars"].label, "2/3")
        XCTAssertEqual(pirouette.frame.midX, app.frame.midX, accuracy: 5)
        XCTAssertLessThan(pirouette.frame.maxY, app.buttons["result.next"].frame.minY)
        saveScreenshot("pirouette-two-star-landing")
        let landedFrame = pirouette.frame
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        XCTAssertEqual(pirouette.frame, landedFrame, "Dino remains still on the stone after landing")
        tap("result.retry")
        XCTAssertTrue(app.buttons["header.pause"].waitForExistence(timeout: 5))
        XCTAssertFalse(pirouette.exists)
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
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "dino.character").count, 1)
        let questionDinoWidth = app.descendants(matching: .any)["dino.character"].frame.width
        saveScreenshot("transition-first-question")
        play(1, correct: 5)
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "dino.backflip").count, 1)
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "dino.thumbsUp").count, 0)
        RunLoop.current.run(until: Date().addingTimeInterval(1.7))
        let landed = app.descendants(matching: .any)["dino.backflip"]
        // The 210pt drawing buffer scales to the responsive result anchor.
        XCTAssertEqual(landed.frame.midX, app.frame.midX, accuracy: 5)
        XCTAssertGreaterThan(landed.frame.width, questionDinoWidth)
        XCTAssertGreaterThanOrEqual(landed.frame.minX, app.frame.minX)
        XCTAssertLessThanOrEqual(landed.frame.maxX, app.frame.maxX)
        XCTAssertLessThan(landed.frame.maxY, app.buttons["result.next"].frame.minY)
        saveScreenshot("transition-result-dino")
        tap("result.map")
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(revealMapNode(2).isEnabled)
        saveScreenshot("personalized-completed-map-companion")
    }
}
