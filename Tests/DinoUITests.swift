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
        if id.hasPrefix("theme."), id != "theme.done" { revealThemeChoice(id) }
        XCTAssertTrue(item.exists || item.waitForExistence(timeout: 6), "Missing \(id)")
        for _ in 0..<(id.hasPrefix("theme.") ? 0 : 6) {
            let footer = editorFooter
            let inEditor = id.hasPrefix("personalize.")
            let aboveFooter = !inEditor || id == "personalize.done" || !footer.exists || item.frame.maxY < footer.frame.minY - 24
            let insideScreen = id != "question.confirm" || item.frame.maxY < app.frame.maxY - 16
            if item.isHittable && aboveFooter && insideScreen { break }
            if id == "question.confirm" {
                // Scroll beside an interactive clock, so revealing Confirm cannot move its hands.
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.035, dy: 0.75))
                    .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.035, dy: 0.35)))
            } else { app.swipeUp() }
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
        app.launchArguments = ["-AppleLanguages", "(\(code))", "-AppleLocale", locale]
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
        XCTAssertGreaterThan(first.frame.minY, app.buttons["header.settings"].frame.maxY)
        XCTAssertLessThan(first.frame.maxY + 85, app.frame.maxY)
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
                XCTAssertEqual(row.value as? String, unlocked ? "\(expected) sterren" : "Vergrendeld")
                XCTAssertFalse(app.buttons["stars.world.\(world)"].exists)
            }
            let expectedTotal = (completedLevel - completedLevel / 10) * 3
            let total = app.descendants(matching: .any)["stars.total"]
            XCTAssertEqual(total.value as? String, "\(expectedTotal) sterren")
            XCTAssertTrue(app.buttons["stars.close"].isHittable)
            saveScreenshot("stars-overview-\(completedLevel)")
            overview.swipeUp()
            XCTAssertTrue(app.descendants(matching: .any)["stars.world.10"].isHittable)
            XCTAssertTrue(app.buttons["stars.close"].isHittable)
            XCTAssertEqual(total.value as? String, "\(expectedTotal) sterren")
            saveScreenshot("stars-overview-\(completedLevel)-bottom")
            tap("stars.close")
            XCTAssertTrue(app.buttons["header.stars"].waitForExistence(timeout: 5))
            XCTAssertFalse(overview.exists)
            XCTAssertEqual(app.buttons["header.stars"].label, "\(expectedTotal) sterren")
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
        XCTAssertEqual(total.label, "Total")
        XCTAssertEqual(total.value as? String, "66 stars")
        XCTAssertEqual(app.descendants(matching: .any)["stars.world.3"].value as? String, "12 stars")
        XCTAssertEqual(app.descendants(matching: .any)["stars.world.4"].value as? String, "Locked")
        XCTAssertEqual(app.buttons["stars.close"].label, "Back to the level overview")
        saveScreenshot("stars-overview-english-portrait")
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
            XCTAssertTrue(app.buttons["stars.close"].isHittable)
            overview.swipeUp()
            XCTAssertTrue(app.descendants(matching: .any)["stars.world.10"].isHittable)
            XCTAssertEqual(app.descendants(matching: .any)["stars.world.10"].value as? String, "Locked")
            XCTAssertEqual(total.value as? String, "66 stars")
            saveScreenshot("stars-overview-english-landscape")
        }
        app.buttons["stars.close"].tap()
        XCTAssertFalse(overview.exists)
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
            let hudWorld = app.descendants(matching: .any)["header.world"]
            XCTAssertEqual(hudWorld.label, "Wereld \(completed + 1)")
            if completed == 1 { XCTAssertEqual(q.target.minute, 30) }
            if q.kind == .match {
                connectMatchingQuestion(q, correct: true)
            } else {
                let option = q.responses.firstIndex(of: q.expectedAnswer)!
                tap("question.option.\(option)")
            }
            XCTAssertTrue(app.staticTexts["2/5"].waitForExistence(timeout: 8))
            XCTAssertEqual(hudWorld.label, "Wereld \(completed + 1)")
            saveScreenshot("native-world-\(completed + 1)-question")
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
            let banner = app.descendants(matching: .any)["map.world.\(world)"]
            XCTAssertTrue(boss.exists && banner.exists)
            let above = banner.frame.minY - boss.frame.maxY
            let below = first.frame.minY - banner.frame.maxY
            XCTAssertGreaterThan(above, 40, "Boss leaves room above world \(world)")
            XCTAssertEqual(above, below, accuracy: 4,
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
        if first.responses.count > 2 { tap("question.showAnswer") }
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
        for _ in 0..<6 { if app.buttons["language.option.nl"].isHittable { break }; app.swipeDown() }
        tap("language.option.en")
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
        tap("onboarding.next"); tap("onboarding.next"); tap("onboarding.customClock")
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
        XCTAssertTrue(option.isSelected, "Practice choice was selected above the fixed start button")
    }

    func testMinutesBetweenQuestionAndExample() {
        checkMinutesBetweenQuestionAndExample(language: "nl", family: .whole)
    }

    func testMinutesBetweenEnglishQuarterHours() {
        checkMinutesBetweenQuestionAndExample(language: "en", family: .quarter)
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
        saveScreenshot("minutes-between-example-\(language)")
        tap("demo.nextExample")
        let refreshed = DinoDemonstrationExamples.question(kind: .minutesBetween, minutes: family.minutes,
                                                          minuteStep: family.minuteStep, index: 1, previousTarget: example.target)
        XCTAssertEqual(app.descendants(matching: .any)["demo.minutesBetween.end"].label, refreshed.target.digitalText)
        XCTAssertEqual(demoAnswer.label, DinoTimeWords.minutes(refreshed.durationMinutes, language: language))
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
        XCTAssertEqual(app.descendants(matching: .any)["header.level"].label, "Level 3")
        saveScreenshot("jungle-continuous-scroll-return")
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
            XCTAssertEqual(app.buttons[identifier].value as? String, "Hoogste reeks: 0")
            tap("practice.start")
            var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: order), seed: testSeed)
            for index in 0..<2 {
                let question = generator.next(index: index)
                tap("question.option.\(question.responses.firstIndex(of: question.expectedAnswer)!)")
                XCTAssertTrue(app.staticTexts.matching(identifier: "practice.questionNumber")
                    .matching(NSPredicate(format: "label == %@", String(index + 2))).firstMatch.waitForExistence(timeout: 6))
                XCTAssertEqual(app.staticTexts["practice.streak"].label, String(index + 1))
                XCTAssertEqual(app.descendants(matching: .any)["practice.bestStreak"].value as? String, String(index + 1))
            }
            tap("header.pause")
            selectPractice(identifier)
            XCTAssertEqual(app.buttons[identifier].value as? String, "Hoogste reeks: 2")
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
        XCTAssertEqual(app.buttons["practice.order.ascending"].value as? String, "Hoogste reeks: 2")
        selectPractice("practice.order.mix")
        XCTAssertEqual(app.buttons["practice.order.mix"].value as? String, "Hoogste reeks: 2")
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

    func testPracticeSelectionAndEndlessDigitalMinutes() {
        openPractice()
        tap("practice.time.half")
        saveScreenshot("practice-time-and-types")
        selectPractice("practice.type.setDigital")
        saveScreenshot("practice-order-choices")
        tap("practice.start")
        XCTAssertFalse(app.buttons["demo.ready"].exists)
        tap("question.digitalControl")
        tap("clock.minute.more")
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "12:30")).firstMatch.exists
                      || app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "01:30")).firstMatch.exists)
        saveScreenshot("practice-digital-minutes")
        for index in 0..<12 {
            XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "\(index + 1)")
            if index > 0 { tap("question.digitalControl") }
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
        XCTAssertEqual(analog.value as? String, "03:00")
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
            let demoCity = app.descendants(matching: .any)["demo.timeZone.destination"]
            XCTAssertFalse(demoCity.label.contains("?"), "The worked map reveals the destination time")
            saveScreenshot("time-zone-atlas-example-\(family.rawValue)")
            tap("demo.nextExample")
            XCTAssertFalse(demoCity.label.contains("?"))
            tap("demo.ready")
            XCTAssertTrue(destination.label.contains("?"), "Examples preserve the unanswered live map")
            let wrongIndex = question.options.firstIndex { $0 != question.target }!
            tap("question.option.\(wrongIndex)")
            XCTAssertTrue(destination.label.contains("?"), "A wrong first attempt does not reveal the time")
            tap("question.showAnswer")
            XCTAssertTrue(destination.label.contains(question.target.digitalText), "Revealing the answer updates the map")
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
        XCTAssertFalse(app.buttons["question.confirm"].isEnabled)
        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.match)), seed: seed)
        let q = generator.next(index: 0)
        let left = app.buttons["question.match.clock.0"]
        let right = app.buttons["question.match.time.0"]
        XCTAssertLessThan(left.frame.maxX, right.frame.minX)
        XCTAssertEqual(left.frame.midY, right.frame.midY, accuracy: 1)
        tap("question.match.clock.0")
        XCTAssertTrue(left.isSelected)
        let wrong = q.options.firstIndex { $0 != q.relatedTimes[0] }!
        tap("question.match.time.\(wrong)")
        XCTAssertEqual(left.value as? String, q.options[wrong].digitalText)
        XCTAssertFalse(app.buttons["question.confirm"].isEnabled)
        // Either endpoint disconnects its pair and clears the pending selection.
        tap("question.match.clock.0")
        XCTAssertEqual(left.value as? String, "Kies een tijd")
        XCTAssertFalse(left.isSelected)
        XCTAssertFalse(app.descendants(matching: .any)["question.match.line.0"].exists)
        let matching = q.options.firstIndex(of: q.relatedTimes[0])!
        tap("question.match.time.\(matching)")
        tap("question.match.clock.0")
        XCTAssertEqual(left.value as? String, q.relatedTimes[0].digitalText)
        XCTAssertTrue(app.descendants(matching: .any)["question.match.line.0"].exists)
        // A pending clock must not take over the connected time when it is tapped.
        tap("question.match.clock.1")
        tap("question.match.time.\(matching)")
        XCTAssertEqual(left.value as? String, "Kies een tijd")
        XCTAssertEqual(app.buttons["question.match.clock.1"].value as? String, "Kies een tijd")
        XCTAssertFalse(app.buttons["question.match.clock.1"].isSelected)
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
        XCTAssertEqual(app.buttons["question.match.clock.2"].value as? String, "Kies een tijd")
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
        XCTAssertEqual(app.buttons["demo.match.clock.0"].value as? String, "Kies een tijd")
        tap("demo.ready")
        XCTAssertEqual(left.value as? String, q.relatedTimes[0].digitalText, "Example preserves live pairs")
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
        XCTAssertEqual(clocks[0].value as? String, question.relatedTimes[0].digitalText)
        XCTAssertTrue(app.descendants(matching: .any)["question.match.line.0"].exists)
        XCTAssertFalse(app.buttons["question.confirm"].isEnabled)
        // A drag can transfer an occupied time; a later tap still disconnects it.
        drag(times[first], to: clocks[1])
        XCTAssertEqual(clocks[0].value as? String, "Kies een tijd")
        XCTAssertEqual(clocks[1].value as? String, question.relatedTimes[0].digitalText)
        tap("question.match.time.\(first)")
        XCTAssertEqual(clocks[1].value as? String, "Kies een tijd")

        // Releasing on the same side or in the gap leaves existing pairs intact.
        tap("question.match.clock.0")
        tap("question.match.time.\(first)")
        drag(clocks[0], to: clocks[2])
        XCTAssertEqual(clocks[0].value as? String, question.relatedTimes[0].digitalText)
        let gap = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
            dx: (clocks[0].frame.maxX + times[0].frame.minX) / 2, dy: clocks[0].frame.midY))
        clocks[0].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: gap)
        XCTAssertEqual(clocks[0].value as? String, question.relatedTimes[0].digitalText)

        let second = question.options.firstIndex(of: question.relatedTimes[1])!
        drag(times[second], to: clocks[1])
        XCTAssertEqual(clocks[1].value as? String, question.relatedTimes[1].digitalText)
        tap("question.match.time.\(question.options.firstIndex(of: question.relatedTimes[2])!)")
        tap("question.match.clock.2")
        XCTAssertTrue(app.buttons["question.confirm"].isEnabled)
        saveScreenshot("matching-drag-and-tap-ready")
        tap("question.confirm")
        XCTAssertTrue(app.staticTexts.matching(identifier: "practice.questionNumber").matching(NSPredicate(format: "label == %@", "2")).firstMatch.waitForExistence(timeout: 5))
    }

    func testClockMinuteControlsCarryTheHourBothWays() {
        openPractice()
        tap("practice.time.fiveMinutes")
        selectPractice("practice.type.setDigital")
        tap("practice.start")
        let digital = app.buttons["question.digitalControl"]
        let initialHour = Int(digital.label.prefix(2))!
        for _ in 0..<((5 - initialHour + 12) % 12) { app.buttons["clock.hour.more"].tap() }
        tap("question.digitalControl")
        for _ in 0..<11 { app.buttons["clock.minute.more"].tap() }
        XCTAssertEqual(digital.label, "05:55")
        tap("clock.minute.more")
        XCTAssertEqual(digital.label, "06:00")
        tap("clock.minute.less")
        XCTAssertEqual(digital.label, "05:55")
        saveScreenshot("digital-minute-hour-carry")
        tap("question.example")
        let example = app.buttons["demo.digital"]
        XCTAssertEqual(example.label, "03:05")
        tap("demo.digital")
        tap("clock.minute.less")
        XCTAssertEqual(example.label, "03:00")
        tap("clock.minute.less")
        XCTAssertEqual(example.label, "02:55")
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
            analog.coordinate(withNormalizedOffset: CGVector(dx: 0.5 + sin(radians) * 0.34,
                                                              dy: 0.5 - cos(radians) * 0.34)).tap()
        }
        moveHand(to: 150)
        XCTAssertEqual(analog.value as? String, "05:00")
        app.segmentedControls["question.hand"].buttons["Minuten"].tap()
        moveHand(to: 180)
        moveHand(to: 330)
        XCTAssertEqual(analog.value as? String, "05:55")
        moveHand(to: 0)
        XCTAssertEqual(analog.value as? String, "06:00")
        moveHand(to: 330)
        XCTAssertEqual(analog.value as? String, "05:55")
        tap("question.analog.more")
        XCTAssertEqual(analog.value as? String, "06:00")
        tap("question.analog.less")
        XCTAssertEqual(analog.value as? String, "05:55")
        saveScreenshot("analog-minute-hour-carry")
    }

    func testMultipleChoiceRetriesKeepTheLostPoint() {
        openPractice()
        selectPractice("practice.type.dayPart")
        tap("practice.start")
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
                XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, "1", "Correct retries wait for Next")
                saveScreenshot("multiple-choice-correct-retry")
            } else {
                tap("question.showAnswer")
                XCTAssertTrue(app.buttons["question.next"].exists)
                saveScreenshot("multiple-choice-show-answer")
            }
            XCTAssertTrue((0..<4).allSatisfy { !app.buttons["question.option.\($0)"].isEnabled })
            tap("question.next")
            XCTAssertEqual(app.staticTexts["practice.streak"].label, "0")
            XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, String(index + 2))
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

    func testDigitalClockSwitchesFieldsAndExampleUsesOtherField() {
        openPractice()
        tap("practice.time.half")
        selectPractice("practice.type.setDigital")
        tap("practice.start")
        let clock = app.buttons["question.digitalControl"]
        XCTAssertEqual(clock.value as? String, "Uren")
        let initial = clock.label
        tap("question.example")
        let example = app.buttons["demo.digital"]
        XCTAssertEqual(example.value as? String, "Minuten")
        let minus = app.buttons["clock.minute.less"]
        let plus = app.buttons["clock.minute.more"]
        XCTAssertLessThan(minus.frame.maxX, example.frame.minX)
        XCTAssertLessThan(example.frame.maxX, plus.frame.minX)
        XCTAssertLessThan(example.frame.minX - minus.frame.maxX, 12)
        XCTAssertLessThan(plus.frame.minX - example.frame.maxX, 12)
        saveScreenshot("digital-example-minutes-selected")
        tap("demo.digital")
        XCTAssertEqual(example.value as? String, "Uren")
        tap("clock.hour.more")
        XCTAssertEqual(example.label, "04:30")
        saveScreenshot("digital-example-hours-selected")
        tap("demo.ready")
        XCTAssertEqual(clock.label, initial)
        // A tap near the edge of the display also switches the active pair.
        clock.coordinate(withNormalizedOffset: CGVector(dx: 0.08, dy: 0.8)).tap()
        XCTAssertEqual(clock.value as? String, "Minuten")
        tap("clock.minute.more")
        XCTAssertEqual(String(clock.label.suffix(2)), "30")
        saveScreenshot("digital-question-minutes-selected")
        tap("question.example")
        XCTAssertEqual(example.value as? String, "Uren")
        saveScreenshot("digital-example-other-field")
        tap("demo.ready")
        XCTAssertEqual(clock.value as? String, "Minuten")
    }

    func testPracticeAscendingAndMixCoverAllTypes() {
        openPractice()
        tap("practice.time.mix")
        selectPractice("practice.order.ascending")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .mix, order: .ascending), seed: seed)
        for index in 0...DinoPracticeQuestion.allCases.count {
            let question = generator.next(index: index)
            let expectedNumber = String(index + 1)
            XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, expectedNumber)
            if question.kind.isExpanded {
                tap("question.example")
                XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 5))
                XCTAssertFalse(app.images["dino.character"].exists)
                tap("demo.ready")
                XCTAssertEqual(app.staticTexts["practice.questionNumber"].label, expectedNumber, "Example preserves the actual question")
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
        selectPractice("practice.type.match")
        tap("practice.start")
        XCTAssertFalse(app.buttons["demo.ready"].exists)
        tap("question.example")
        XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.images["dino.character"].exists)
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
                XCTAssertTrue(clock.isSelected)
                XCTAssertFalse(clock.isEnabled)
                XCTAssertNotEqual(clock.label, "00:00")
                return (Int(clock.value as? String ?? "") ?? 0, clock.label)
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
        let marker = app.descendants(matching: .any)["map.dino.\(levelID)"]
        XCTAssertTrue(marker.waitForExistence(timeout: 5))
        let node = revealMapNode(levelID)
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
        openSettings(); tap("settings.clocks")
        tap("theme.dino.face.custom")
        let sliders = app.buttons.matching(NSPredicate(format: "label IN %@", ["Sliders", "Schuifbalken", "Schuifregelaars"])).firstMatch
        XCTAssertTrue(sliders.waitForExistence(timeout: 5)); sliders.tap()
        XCTAssertTrue(app.textFields.matching(NSPredicate(format: "value == %@ AND enabled == YES", "090B11")).firstMatch.exists)
    }

    func testAnalogClockDesignAndRomanNumerals() {
        launchUsingDeviceLanguage("en-GB", locale: "en_GB")
        tap("onboarding.next")
        XCTAssertTrue(app.buttons["theme.dino.face.white"].isSelected)
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
        XCTAssertTrue(app.buttons["theme.dino.face.black"].isSelected)
        tap("theme.analogShape.octagon")
        XCTAssertFalse(app.descendants(matching: .any)["theme.hands"].exists)
        revealThemeChoice("theme.analogNumerals")
        XCTAssertFalse(app.staticTexts["theme.analogNumerals.label"].exists)
        tap("theme.analogNumerals.roman")
        XCTAssertTrue(app.buttons["theme.analogNumerals.roman"].isSelected)
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
        openSettings(); tap("settings.clocks")
        XCTAssertTrue(app.buttons["theme.dino.face.black"].isSelected)
        revealThemeChoice("theme.analogNumerals")
        XCTAssertTrue(app.buttons["theme.analogNumerals.roman"].isSelected)
        tap("theme.resetAnalogStyle")
        XCTAssertTrue(app.buttons["theme.dino.face.white"].isSelected)
        XCTAssertTrue(app.buttons["theme.analogNumerals.normal"].isSelected)
        revealThemeChoice("theme.numerals.classic")
        XCTAssertTrue(app.buttons["theme.numerals.classic"].isSelected)
        tap("theme.done")
    }

    func testHeaderPersonalizerHasLiveClockPages() {
        onboard()
        tap("header.dino")
        XCTAssertTrue(app.buttons["personalize.page.dino"].isSelected)
        tap("personalize.bandana.blue")
        tap("personalize.page.analog")
        XCTAssertTrue(app.buttons["personalize.page.analog"].isSelected)
        tap("theme.dino.face.black")
        tap("theme.analogShape.octagon")
        tap("theme.analogNumerals.roman")
        saveScreenshot("personalize-analog-roman-page")
        app.swipeLeft()
        XCTAssertTrue(app.buttons["personalize.page.digital"].isSelected)
        tap("theme.dino.digitColor.navy")
        XCTAssertTrue(app.buttons["personalize.done"].isEnabled)
        tap("theme.dino.display.yellow")
        XCTAssertTrue(app.buttons["personalize.done"].isEnabled)
        tap("theme.numerals.classic")
        saveScreenshot("personalize-digital-page")
        tap("personalize.done")
        tap("header.dino")
        XCTAssertTrue(app.buttons["personalize.page.dino"].isSelected)
        XCTAssertTrue(app.buttons["personalize.bandana.blue"].isSelected)
        tap("personalize.page.analog")
        XCTAssertTrue(app.buttons["theme.dino.face.black"].isSelected)
        XCTAssertTrue(app.buttons["theme.analogShape.octagon"].isSelected)
        XCTAssertTrue(app.buttons["theme.analogNumerals.roman"].isSelected)
        tap("personalize.done")
        begin(1)
        XCTAssertTrue(app.staticTexts["1/5"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["XII"].firstMatch.exists)
        saveScreenshot("personalize-live-roman-in-level")
        tap("header.dino")
        XCTAssertTrue(app.buttons["personalize.page.dino"].isSelected)
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
        XCTAssertTrue(app.buttons["personalize.page.dino"].isSelected)
        tap("personalize.page.analog")
        XCTAssertTrue(app.buttons["theme.analogNumerals.normal"].isSelected)
        XCTAssertTrue(app.buttons["theme.analogShape.square"].isSelected)
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
        XCTAssertTrue(app.buttons["theme.dino.face.white"].isSelected)
        XCTAssertTrue(app.buttons["theme.dino.hourHand.navy"].isSelected)
        XCTAssertTrue(app.buttons["theme.analogShape.circle"].isSelected)
        XCTAssertTrue(app.buttons["theme.analogNumerals.normal"].isSelected)
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
        XCTAssertTrue(app.buttons["theme.dino.display.navy"].isSelected)
        XCTAssertTrue(app.buttons["theme.dino.digitColor.white"].isSelected)
        XCTAssertFalse(app.descendants(matching: .any)["theme.digitalShape"].exists)
        tap("theme.dino.display.teal")
        tap("theme.dino.digitColor.orange")
        tap("theme.numerals.classic")
        saveScreenshot("digital-bright-palette-and-numeral-previews")
        tap("theme.resetDigitalStyle")
        XCTAssertEqual(app.buttons["theme.resetDigitalStyle"].label, "Herstel oorspronkelijke stijl")
        XCTAssertTrue(app.buttons["theme.dino.display.navy"].isSelected)
        XCTAssertTrue(app.buttons["theme.dino.digitColor.white"].isSelected)
        XCTAssertTrue(app.buttons["theme.numerals.rounded"].isSelected)
        saveScreenshot("digital-original-style-restored")
        swipeWelcomePreview("theme.digital.preview", forward: false)
        XCTAssertTrue(app.buttons["theme.analogShape.octagon"].isSelected)
        XCTAssertTrue(app.buttons["theme.analogNumerals.roman"].isSelected)
        XCTAssertTrue(app.buttons["theme.dino.face.blue"].isSelected)
        tap("onboarding.next")
        tap("onboarding.customClock")
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        tap("header.dino")
        tap("personalize.page.analog")
        XCTAssertTrue(app.buttons["theme.analogShape.octagon"].isSelected)
        tap("theme.resetAnalogStyle")
        XCTAssertTrue(app.buttons["theme.analogShape.circle"].isSelected)
        XCTAssertTrue(app.buttons["theme.analogNumerals.normal"].isSelected)
        XCTAssertTrue(app.buttons["theme.dino.face.white"].isSelected)
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
            XCTAssertTrue(button.isSelected)
            XCTAssertTrue(app.buttons["personalize.done"].isHittable)
        }
        saveScreenshot("personalize-tabs-safe-top-margin")
        tap("personalize.done")
        begin(1)
        tap("header.dino")
        tap("personalize.page.analog")
        XCTAssertTrue(app.buttons["theme.analogNumerals.roman"].isSelected)
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
            XCTAssertTrue(app.buttons["theme.analogNumerals.roman"].isSelected)
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
        let time = analog ? preview.value as? String : preview.label
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
        XCTAssertTrue(app.buttons["theme.dino.face.black"].isSelected)
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
        XCTAssertTrue(app.buttons["theme.dino.display.white"].isSelected)
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
            XCTAssertTrue(app.buttons["personalize.page.dino"].isSelected)
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
        XCTAssertTrue(app.buttons["personalize.page.dino"].isSelected)
        tap("personalize.page.analog")
        assertPreviewShowsCurrentTime(true)
        XCTAssertTrue(app.buttons["theme.dino.face.white"].isSelected)
        XCTAssertTrue(app.buttons["theme.analogShape.circle"].isSelected)
        XCTAssertFalse(app.buttons["personalize.resetAnalogClock"].exists)
        tap("theme.analogShape.square")
        chooseClockCustomColor("face", hex: "BC5518") // Same as the long hand.
        assertClockWarningBelowPreview(true)
        tap("personalize.page.digital")
        assertPreviewShowsCurrentTime(false)
        XCTAssertTrue(app.buttons["theme.dino.display.navy"].isSelected)
        XCTAssertTrue(app.buttons["theme.dino.digitColor.white"].isSelected)
        XCTAssertFalse(app.descendants(matching: .any)["theme.digitalShape"].exists)
        XCTAssertTrue(app.buttons["theme.numerals.rounded"].isSelected)
        XCTAssertFalse(app.buttons["personalize.resetDigitalClock"].exists)
        tap("theme.dino.display.white")
        assertClockWarningBelowPreview(false)
        XCTAssertTrue(app.buttons["personalize.done"].isEnabled)
        saveScreenshot("personalize-matching-colors")
        tap("personalize.done")
        XCTAssertTrue(app.staticTexts["1/5"].exists)
        tap("header.dino")
        tap("personalize.page.analog")
        XCTAssertTrue(app.buttons["theme.dino.face.white"].isSelected)
        XCTAssertTrue(app.buttons["theme.analogShape.circle"].isSelected)
        tap("personalize.page.digital")
        XCTAssertTrue(app.buttons["theme.dino.display.navy"].isSelected)
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
            XCTAssertTrue(app.buttons["theme.analogShape.\(shape)"].isSelected)
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
        XCTAssertTrue(app.buttons["theme.dino.digitColor.white"].isSelected)
        XCTAssertFalse(app.descendants(matching: .any)["theme.digitalShape"].exists)
        for font in ["rounded", "digital", "modern", "classic"] {
            tap("theme.numerals.\(font)")
            XCTAssertTrue(app.buttons["theme.numerals.\(font)"].isSelected)
            saveScreenshot("welcome-digital-font-\(font)")
        }
        XCUIDevice.shared.orientation = .landscapeLeft
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(app.buttons["onboarding.customClock"].isHittable)
        tap("theme.numerals.digital")
        XCTAssertTrue(app.buttons["theme.numerals.digital"].isSelected)
        tap("theme.numerals.classic")
        saveScreenshot("welcome-digital-landscape")
        XCUIDevice.shared.orientation = .portrait
        swipeWelcomePreview("theme.digital.preview", forward: false)
        XCTAssertTrue(app.staticTexts["Make your analog clock"].waitForExistence(timeout: 5))
        tap("theme.analogShape.octagon")
        XCTAssertTrue(app.buttons["theme.analogShape.octagon"].isSelected)
        tap("theme.dino.face.blue")
        XCTAssertTrue(app.buttons["theme.dino.face.blue"].isSelected)
        tap("onboarding.next")
        tap("onboarding.customClock")
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        openSettings(); tap("settings.clocks")
        XCTAssertTrue(app.buttons["theme.dino.face.blue"].isSelected)
        XCTAssertTrue(app.buttons["theme.analogShape.octagon"].isSelected)
        XCTAssertFalse(app.descendants(matching: .any)["theme.digitalShape"].exists)
        revealThemeChoice("theme.numerals.classic")
        XCTAssertTrue(app.buttons["theme.numerals.classic"].isSelected)
        tap("theme.dino.display.white")
        XCTAssertTrue(app.buttons["theme.done"].isEnabled)
        tap("theme.dino.digitColor.navy")
        XCTAssertTrue(app.buttons["theme.done"].isEnabled)
        tap("theme.done")
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
        XCTAssertTrue(app.buttons["language.option.nl"].isSelected)
        XCTAssertTrue(app.buttons["language.option.en"].isHittable)
        capture("adaptive-settings-dutch")
        activate("language.option.en")
        XCTAssertEqual(settingsTitle.label, "Settings")
        XCTAssertTrue(app.buttons["language.option.en"].isSelected)
        capture("adaptive-settings-english")
        activate("language.option.nl")
        activate("settings.clocks")
        XCTAssertTrue(app.buttons["theme.done"].waitForExistence(timeout: 5))
        activate("theme.done")
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
        for _ in 0..<6 { if app.buttons["language.option.nl"].isHittable { break }; app.swipeDown() }
        tap("language.option.en")
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
        saveScreenshot("companion-level-wrong-bottom")
        XCTAssertTrue(app.images["dino.wrongAnswer"].exists, "The wrong-answer pose remains until Next")
        let reaction = app.images["dino.wrongAnswer"]
        XCTAssertEqual(app.images.matching(identifier: "dino.wrongAnswer").count, 1)
        XCTAssertGreaterThanOrEqual(reaction.frame.minY, 0)
        XCTAssertLessThanOrEqual(reaction.frame.maxY, app.frame.maxY, "Reaction remains at the bottom of the screen")
        XCTAssertEqual(clock.frame.midX, originalCenter, accuracy: 1, "Dino cannot displace the clock after an answer")
        saveScreenshot("wrong-answer-waits")
        tap("question.showAnswer")
        XCTAssertTrue(app.buttons["question.next"].exists)
        XCTAssertTrue(options.allSatisfy { !$0.isEnabled })
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
        selectPractice("practice.type.match")
        tap("practice.start")
        XCTAssertTrue(idle.waitForExistence(timeout: 5), "Expanded questions also show Dino")
        assertCompanionAtBottom(idle)
        XCTAssertLessThanOrEqual(idle.frame.width, smallQuestionSize + 2, "Dense questions retain the same recognizable companion")
        saveScreenshot("companion-large-pair-question")
        // The practice cover uses its presenter's orientation on iPhone. Rotate
        // the main game scene to verify the same dock at a short viewport height.
        tap("header.pause")
        tap("practice.close")
        begin(10)
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscape = NSPredicate { _, _ in (UIDevice.current.userInterfaceIdiom == .pad ? self.app.frame.width > self.app.frame.height : self.app.frame.width < self.app.frame.height) && idle.exists && idle.frame.maxY <= self.app.frame.maxY + 1 }
        expectation(for: landscape, evaluatedWith: nil)
        waitForExpectations(timeout: 8)
        assertCompanionAtBottom(idle)
        if UIDevice.current.userInterfaceIdiom == .phone {
            XCTAssertEqual(idle.frame.width, smallQuestionSize, accuracy: 2, "iPhone keeps the portrait companion when the device rotates")
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
        XCTAssertGreaterThanOrEqual(companion.frame.width, 88, "Dino stays recognizable on dense questions")
        XCTAssertEqual(companion.frame.midX, app.frame.midX, accuracy: 1, "Dino is centred below the question")
        let viewport = app.scrollViews["game.questions"]
        if viewport.exists {
            XCTAssertEqual(viewport.frame.midX, app.frame.midX, accuracy: 1)
            XCTAssertLessThanOrEqual(viewport.frame.maxY, companion.frame.minY + 1, "The question ends above Dino")
        }
    }

    func testResponsiveOrientationsAndProportionalHUD() {
        onboard()
        let tablet = UIDevice.current.userInterfaceIdiom == .pad
        let mapScroll = app.scrollViews["map.route"]
        XCTAssertEqual(mapScroll.frame.minX, app.frame.minX, accuracy: 1)
        XCTAssertEqual(mapScroll.frame.maxX, app.frame.maxX, accuracy: 1)
        let mapCompanion = app.descendants(matching: .any)["map.dino.0"]
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
        let companion = app.images["dino.character"]
        XCTAssertTrue(companion.waitForExistence(timeout: 5))
        let portraitCompanionSize = companion.frame.width
        assertCompanionAtBottom(companion)
        XCTAssertGreaterThanOrEqual(portraitCompanionSize, tablet ? 104 : 88)
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
            assertCompanionAtBottom(companion)
            XCTAssertGreaterThanOrEqual(companion.frame.width, tablet ? 104 : 88)
            XCTAssertTrue(app.staticTexts["1/10"].exists, "Rotation preserves the running question")
            if tablet {
                let options = (0..<4).map { app.buttons["question.option.\($0)"] }
                XCTAssertTrue(options.allSatisfy { $0.isHittable })
                XCTAssertEqual((options[0].frame.minX + options[3].frame.maxX) / 2, app.frame.midX, accuracy: 1)
                XCTAssertEqual(app.staticTexts["question.title"].frame.midX, app.frame.midX, accuracy: 1)
                XCTAssertEqual(app.descendants(matching: .any)["question.targetClock"].frame.midX, app.frame.midX, accuracy: 1)
                for option in options {
                    XCTAssertEqual(option.frame.midY, options[0].frame.midY, accuracy: 1)
                    XCTAssertLessThanOrEqual(option.frame.maxY, companion.frame.minY)
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

    func testCenteredPracticeClocksAndCompanionBelowQuestions() {
        openPractice()
        selectPractice("practice.type.match")
        tap("practice.start")
        let tablet = UIDevice.current.userInterfaceIdiom == .pad
        let companion = app.images["dino.character"]
        XCTAssertTrue(companion.waitForExistence(timeout: 5))
        func checkBoard(_ name: String) {
            assertCompanionAtBottom(companion)
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
        assertCompanionAtBottom(companion)
        tap("header.pause")
        selectPractice("practice.type.sortTimes")
        tap("practice.start")
        XCTAssertTrue(app.buttons["question.sort.0"].waitForExistence(timeout: 5))
        assertCompanionAtBottom(companion)
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
        let character = app.descendants(matching: .any)["map.dino.1"]
        let node = app.buttons["map.level.1"]
        XCTAssertEqual(character.frame.midX, node.frame.midX, accuracy: 1)
        // Match the shared foot baseline also checked by testDinoStandsOnCompletedLevel.
        XCTAssertEqual(character.frame.maxY, node.frame.midY + 12, accuracy: 3)
        XCTAssertFalse(character.label.contains("Sam"))
        XCTAssertTrue(node.isHittable)
        saveScreenshot("jungle-earned-stars")
    }

    func testStartPointCleanCardAndExitCancel() {
        onboard()
        let marker = app.descendants(matching: .any)["map.dino.0"]
        XCTAssertTrue(marker.exists)
        XCTAssertGreaterThan(marker.frame.height, 95)
        XCTAssertLessThanOrEqual(marker.frame.height, 200)
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
