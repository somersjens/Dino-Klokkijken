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
        var item = app.descendants(matching: .any).matching(identifier: id).firstMatch
        if id == "settings.icloudSync", item.elementType != .switch {
            // The row also contains a separate info button beside its label.
            // Tap the real switch when the test intends to change this setting.
            item = item.switches.firstMatch
        }
        if id.hasPrefix("theme."), id != "theme.done" { revealThemeChoice(id) }
        XCTAssertTrue(item.exists || item.waitForExistence(timeout: 6), "Missing \(id)")
        let settingsMenu = app.scrollViews["settings.options"]
        let isSettingsRow = id.hasPrefix("settings.") && id != "settings.done"
            && !id.hasPrefix("settings.reset.")
        for _ in 0..<(id.hasPrefix("theme.") ? 0 : isSettingsRow ? 12 : 6) {
            let footer = editorFooter
            let inEditor = id.hasPrefix("personalize.")
            let aboveFooter = !inEditor || id == "personalize.done" || id.hasPrefix("personalize.page.")
                || !footer.exists || item.frame.maxY < footer.frame.minY - 24
            if isSettingsRow && settingsMenu.exists {
                let frame = item.frame, viewport = settingsMenu.frame
                if frame.width > 0 && viewport.contains(frame) { break }
                // A short landscape sheet has a fixed footer: swiping the app
                // can miss its list. Scroll the actual list in either direction.
                if frame.minY < viewport.minY { settingsMenu.swipeDown() }
                else { settingsMenu.swipeUp() }
                continue
            }
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
        if id == "settings.icloudSync" {
            let frame = item.frame, root = app.frame
            app.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: frame.midX - root.minX, dy: frame.midY - root.minY)).tap()
        } else if id.hasPrefix("theme.") && id != "theme.done" {
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
        if app.scrollViews["map.route"].exists { waitForMapOpeningToFinish() }
        tap("header.settings")
        XCTAssertTrue(app.staticTexts["settings.title"].waitForExistence(timeout: 5))
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
        let confirm = app.buttons["settings.reset.confirm"]
        XCTAssertFalse(confirm.isEnabled, "an empty answer cannot erase progress")
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        field.typeText("0")
        XCTAssertFalse(confirm.isEnabled, "an incorrect calculation cannot erase progress")
        field.typeText(XCUIKeyboardKey.delete.rawValue)
        field.typeText(String(answer))
        saveScreenshot("reset-answer-keyboard")
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
        if UIDevice.current.userInterfaceIdiom == .pad {
            let dino = app.descendants(matching: .any)["map.dino.1"]
            XCTAssertGreaterThan(dino.frame.minY, app.buttons["header.settings"].frame.maxY,
                                 "The magnified map opens with Dino and the first level in focus")
        } else {
            XCTAssertGreaterThan(world.frame.minY, -20, "a fresh phone map stays scrolled to the top")
            XCTAssertLessThan(world.frame.minY, app.frame.height * 0.45)
        }
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
        for _ in 0..<6 {
            if app.buttons["map.bossShortcut"].isHittable { break }
            app.scrollViews["map.route"].swipeDown()
        }
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
            waitForMapOpeningToFinish()
            tap("header.stars")
            let overview = app.scrollViews["stars.overview"]
            XCTAssertTrue(overview.waitForExistence(timeout: 5))
            for world in 1...10 {
                let firstLevel = (world - 1) * 10 + 1
                let expected = min(10, max(0, completedLevel - firstLevel + 1)) * 3
                let unlocked = world <= completedLevel / 10 + 1
                let row = app.descendants(matching: .any)["stars.world.\(world)"]
                XCTAssertTrue(row.exists)
                XCTAssertEqual(row.staticTexts["\(expected)"].exists, unlocked)
                XCTAssertFalse(app.buttons["stars.world.\(world)"].exists)
            }
            let expectedTotal = completedLevel * 3
            let total = app.descendants(matching: .any)["stars.total"]
            XCTAssertTrue(total.staticTexts["\(expectedTotal)"].exists)
            saveScreenshot("stars-overview-\(completedLevel)")
            revealStarsActions()
            XCTAssertTrue(app.descendants(matching: .any)["stars.world.10"].isHittable)
            XCTAssertTrue(app.buttons["stars.close"].isHittable)
            XCTAssertTrue(total.staticTexts["\(expectedTotal)"].exists)
            saveScreenshot("stars-overview-\(completedLevel)-bottom")
            tap("stars.close")
            XCTAssertTrue(app.buttons["header.stars"].waitForExistence(timeout: 5))
            XCTAssertTrue(overview.waitForNonExistence(timeout: 5))
            XCTAssertTrue(app.buttons["header.stars"].label.hasSuffix(", \(expectedTotal)"))
        }
    }

    func testStarsOverviewEnglishAndTabletLayout() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "24"
        app.launchArguments = ["-settings.languageOverride", "en"]
        app.launch()
        XCTAssertTrue(app.buttons["header.stars"].waitForExistence(timeout: 8))
        waitForMapOpeningToFinish()
        app.buttons["header.stars"].tap()
        let overview = app.scrollViews["stars.overview"]
        XCTAssertTrue(overview.waitForExistence(timeout: 5))
        let total = app.descendants(matching: .any)["stars.total"]
        XCTAssertTrue(total.staticTexts["Total"].exists)
        XCTAssertTrue(total.staticTexts["72"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["stars.world.3"].staticTexts["12"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["stars.world.4"].staticTexts["12"].exists)
        XCTAssertEqual(app.buttons["stars.close"].label, "Back to the level overview")
        revealStarsActions()
        saveScreenshot("stars-overview-english-portrait")
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
            revealStarsActions()
            XCTAssertTrue(app.descendants(matching: .any)["stars.world.10"].isHittable)
            XCTAssertFalse(app.descendants(matching: .any)["stars.world.10"].staticTexts["12"].exists)
            XCTAssertTrue(total.staticTexts["72"].exists)
            saveScreenshot("stars-overview-english-landscape")
        }
        app.buttons["stars.close"].tap()
        XCTAssertTrue(overview.waitForNonExistence(timeout: 5))
    }

    private func revealStarsActions() {
        let overview = app.scrollViews["stars.overview"]
        let close = app.buttons["stars.close"]
        for _ in 0..<8 {
            if close.isHittable && close.frame.maxY <= overview.frame.maxY { return }
            overview.swipeUp()
        }
        XCTAssertTrue(close.isHittable)
    }

    func testStarsOverviewFitsPortraitAndLandscape() {
        onboard()
        tap("header.stars")
        let overview = app.scrollViews["stars.overview"]
        XCTAssertTrue(overview.waitForExistence(timeout: 5))
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            let close = app.buttons["stars.close"]
            let first = app.descendants(matching: .any)["stars.world.1"]
            let second = app.descendants(matching: .any)["stars.world.2"]
            let last = app.descendants(matching: .any)["stars.world.10"]
            let total = app.descendants(matching: .any)["stars.total"]
            for _ in 0..<8 {
                if first.isHittable && first.frame.minY >= overview.frame.minY { break }
                overview.swipeDown()
            }
            XCTAssertGreaterThanOrEqual(first.frame.minX, overview.frame.minX)
            XCTAssertLessThanOrEqual(second.frame.maxX, overview.frame.maxX)
            let twoColumns = abs(first.frame.minY - second.frame.minY) < 1
            if orientation != .portrait && overview.frame.width >= 500 {
                XCTAssertTrue(twoColumns, "Landscape also uses two columns in a phone-sized sheet")
            }
            if UIDevice.current.userInterfaceIdiom == .pad && orientation == .portrait {
                XCTAssertGreaterThan(overview.frame.width, 650)
                XCTAssertGreaterThan(first.frame.height, 70)
            }
            revealStarsActions()
            XCTAssertTrue(last.isHittable)
            XCTAssertTrue(close.isHittable)
            XCTAssertTrue(app.frame.contains(close.frame))
            XCTAssertEqual(total.frame.width, first.frame.width, accuracy: 1)
            XCTAssertEqual(close.frame.width, first.frame.width, accuracy: 1)
            XCTAssertGreaterThan(total.frame.minY, last.frame.maxY,
                                 "The actions follow the world stones inside the list")
            if orientation != .portrait && twoColumns {
                XCTAssertEqual(total.frame.midY, close.frame.midY, accuracy: 1)
                XCTAssertLessThan(total.frame.maxX, close.frame.minX)
            } else {
                XCTAssertGreaterThanOrEqual(close.frame.minY, total.frame.maxY)
            }
            if orientation != .portrait {
                XCTAssertGreaterThanOrEqual(overview.frame.minY, app.frame.minY + 24,
                                     "Landscape retains visible map space above the sheet")
            }
            saveScreenshot("stars-responsive-\(orientation.rawValue)")
        }
        tap("stars.close")
        XCTAssertTrue(overview.waitForNonExistence(timeout: 5))
    }

    func testStarsOverviewLandscapeSwipeDismissal() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launch()
        XCTAssertTrue(app.buttons["header.stars"].waitForExistence(timeout: 8))
        waitForMapOpeningToFinish()
        tap("header.stars")
        let overview = app.scrollViews["stars.overview"]
        XCTAssertTrue(overview.waitForExistence(timeout: 5))
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let start = CGPoint(x: overview.frame.midX, y: overview.frame.minY + 8)
        origin.withOffset(CGVector(dx: start.x, dy: start.y))
            .press(forDuration: 0.1, thenDragTo: origin.withOffset(CGVector(
                dx: start.x, dy: min(app.frame.maxY - 20, start.y + overview.frame.height * 0.8))))
        XCTAssertTrue(overview.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["header.stars"].isHittable)
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
            if !app.descendants(matching: .any)["level.questions"].exists { tap("level.details") }
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
            waitForMapOpeningToFinish()
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
            if id == 54 {
                Thread.sleep(forTimeInterval: 2.5)
                saveScreenshot("city-metro-route-54-motion")
            }
            if id == 60 {
                // Keep the lower city visible while the metro enters its underpass.
                Thread.sleep(forTimeInterval: 3)
                saveScreenshot("city-metro-tunnel-motion")
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

    func testJungleRouteStartsAndEndsInCenter() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.jungle-central-endpoints.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "0"
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launch()
        waitForMapOpeningToFinish()
        let first = app.buttons["map.level.1"]
        XCTAssertTrue(first.waitForExistence(timeout: 8))
        XCTAssertTrue(first.isHittable)
        XCTAssertEqual(first.frame.midX, app.frame.midX, accuracy: 2)
        saveScreenshot("jungle-central-start")
        let boss = revealMapNode(10)
        XCTAssertEqual(boss.frame.midX, app.frame.midX, accuracy: 2)
        XCTAssertLessThan(app.buttons["map.level.9"].frame.midX, boss.frame.midX - 30)
        saveScreenshot("jungle-central-finish")
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
            waitForMapOpeningToFinish()
            let boss = revealMapNode(world * 10)
            let ready = NSPredicate { _, _ in boss.exists && boss.isEnabled }
            expectation(for: ready, evaluatedWith: nil)
            waitForExpectations(timeout: 15)
            XCTAssertTrue(boss.isEnabled)
            XCTAssertGreaterThanOrEqual(boss.frame.width, 44)
            if world == 1 {
                XCTAssertEqual(boss.frame.midX, app.frame.midX, accuracy: 2,
                               "The jungle boss stone shares the centered chapter exit")
                XCTAssertLessThan(app.buttons["map.level.9"].frame.midX, boss.frame.midX - 30,
                                  "The preceding stone keeps its own left-hand bend")
            }
            saveScreenshot("scenery-depth-world-\(world)")
            boss.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(app.buttons["level.play"].waitForExistence(timeout: 5),
                          "Sorted scenery must leave the world \(world) boss playable")
        }
    }

    func testWorldBannersHaveBalancedClearance() {
        let requested = ProcessInfo.processInfo.environment["DINO_TEST_WORLD_IDS"]?
            .split(separator: ",").compactMap { Int($0) }.filter { (2...10).contains($0) } ?? []
        var referenceGap: CGFloat?
        for world in requested.isEmpty ? Array(2...10) : requested {
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
            let gap = first.frame.midY - boss.frame.midY
            if let referenceGap {
                XCTAssertEqual(gap, referenceGap, accuracy: 2, "Every world uses the same distance between boss and next level")
            } else { referenceGap = gap }
            saveScreenshot("world-banner-spacing-\(world)")
        }
    }

    func testComingSoonOnlyAfterLevelHundred() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "10"
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 8))
        waitForMapOpeningToFinish()
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
        let cards = ids.map { app.descendants(matching: .any).matching(identifier: $0).firstMatch }
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
        let questionLabels = app.staticTexts.matching(identifier: "header.questions")
        XCTAssertTrue(questionLabels.matching(NSPredicate(format: "label == %@", "Vraag")).firstMatch.exists)
        XCTAssertFalse(app.descendants(matching: .any)["header.stars"].exists)
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", "1/5")).count, 1)
        // SwiftUI exposes the heading and counter as separate accessibility labels.
        let questionFrame = questionLabels.allElementsBoundByIndex.reduce(CGRect.null) { $0.union($1.frame) }
        let example = app.buttons["question.example"]
        let pause = app.buttons["header.pause"]
        XCTAssertLessThan(questionFrame.maxX, example.frame.minX)
        XCTAssertLessThan(example.frame.maxX, pause.frame.minX)
        XCTAssertGreaterThanOrEqual(questionFrame.minY, pause.frame.minY - 1)
        XCTAssertLessThanOrEqual(questionFrame.maxY, pause.frame.maxY + 1)
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
        XCTAssertTrue(app.buttons["map.bossShortcut"].waitForExistence(timeout: 15))
        waitForMapOpeningToFinish()
        // SwiftUI propagates each button's identifier over the child text IDs.
        // Check the actual displayed numeric text inside those public buttons.
        XCTAssertEqual(app.buttons["header.stars"].staticTexts.matching(NSPredicate(format: "label == %@", "0")).count, 1)
        XCTAssertEqual(app.buttons["header.level"].staticTexts.matching(NSPredicate(format: "label == %@", "1")).count, 1)
        openSettings()
        for (id, value) in [("soundEffects", "1"), ("haptics", "1"), ("speakQuestionTitle", "0"), ("highContrast", "0"), ("icloudSync", "0")] {
            XCTAssertEqual(app.descendants(matching: .any)["settings.\(id)"].switches.firstMatch.value as? String, value)
        }
    }

    private func selectPractice(_ id: String) {
        let option = app.buttons[id]
        let start = app.buttons["practice.start"]
        let scroll = app.scrollViews["practice.options"]
        for _ in 0..<16 {
            let top = scroll.frame.minY + 8
            let bottom = (start.frame.maxX < scroll.frame.minX ? scroll.frame.maxY : min(scroll.frame.maxY, start.frame.minY)) - 8
            let frame = option.exists ? option.frame : .zero
            if option.exists && option.isHittable && frame.minY >= top && frame.maxY <= bottom { break }
            let movingDown = option.exists && frame.minY < top
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: movingDown ? 0.35 : 0.70))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: movingDown ? 0.65 : 0.40)),
                       withVelocity: .slow, thenHoldForDuration: 0.05)
        }
        option.tap()
    }

    func testClockRequiresAChangedTimeBeforeChecking() {
        launchDigitalClockLayoutFixture(force24Hour: true)
        tap("header.practice")
        tap("practice.time.fiveMinutes")
        for kind in [DinoPracticeQuestion.setAnalog, .setDigital, .advanceAnalog] {
            selectPractice("practice.type.\(kind.rawValue)")
            tap("practice.start")
            let confirm = app.buttons["question.confirm"]
            XCTAssertTrue(confirm.waitForExistence(timeout: 5))
            let control = app.descendants(matching: .any)[kind == .setDigital ? "question.digitalControl" : "question.analogControl"]
            let initial = control.label
            let controlFrame = control.frame
            let confirmFrame = confirm.frame
            let reminder = app.descendants(matching: .any)["question.inputReminder"]
            for _ in 0..<3 { confirm.tap() }
            XCTAssertTrue(reminder.waitForExistence(timeout: 3))
            XCTAssertEqual(reminder.label, "Change the time to continue")
            XCTAssertFalse(app.buttons["question.next"].exists)
            XCTAssertFalse(app.descendants(matching: .any)["question.correctClock"].exists)
            XCTAssertEqual(control.label, initial)
            XCTAssertEqual(control.frame.minY, controlFrame.minY, accuracy: 1)
            XCTAssertEqual(confirm.frame.minY, confirmFrame.minY, accuracy: 1)
            let reminderFrame = reminder.frame
            XCTAssertEqual(reminderFrame.midX, confirmFrame.midX, accuracy: 1)
            XCTAssertEqual(reminderFrame.midY, confirmFrame.midY, accuracy: 1)
            XCTAssertEqual(reminderFrame.width, confirmFrame.width, accuracy: 1)
            XCTAssertEqual(reminderFrame.height, confirmFrame.height, accuracy: 1)
            saveScreenshot("input-reminder-\(kind.rawValue)")
            var generator = DinoPracticeGenerator(configuration: .init(time: .fiveMinutes, order: .specific(kind)), seed: seed, language: "en")
            changeClockToWrongTime(kind.recipe.kind, target: generator.next(index: 0).target)
            XCTAssertTrue(reminder.waitForNonExistence(timeout: 3))
            confirm.tap()
            XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
            tap("question.next")
            tap("question.confirm")
            XCTAssertTrue(reminder.waitForExistence(timeout: 3), "The next question requires a new time change")
            tap("header.pause")
        }
    }

    func testSpokenTimeRequiresAtLeastOneTileBeforeChecking() {
        for code in ["en", "nl"] {
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.input-reminder.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
            app.launchArguments = ["-settings.languageOverride", code, "-AppleICUForce24HourTime", "YES"]
            app.launch()
            XCTAssertTrue(app.buttons["header.practice"].waitForExistence(timeout: 10))
            waitForMapOpeningToFinish()
            tap("header.practice")
            selectPractice("practice.type.sayTime")
            tap("practice.start")
            let confirm = app.buttons["question.confirm"]
            XCTAssertTrue(confirm.waitForExistence(timeout: 5))
            let reminder = app.descendants(matching: .any)["question.inputReminder"]
            confirm.tap()
            XCTAssertTrue(reminder.waitForExistence(timeout: 3))
            XCTAssertEqual(reminder.label, code == "en" ? "Press at least 1 tile to continue" : "Kies minstens 1 steen om verder te gaan")
            XCTAssertFalse(app.buttons["question.next"].exists)
            saveScreenshot("input-reminder-tile-\(code)")
            XCTAssertTrue(reminder.waitForNonExistence(timeout: 7), "The reminder fades away without submitting the empty answer")
            XCTAssertFalse(app.buttons["question.next"].exists)
            confirm.tap()
            XCTAssertTrue(reminder.waitForExistence(timeout: 3))
            tap("question.spoken.0.0")
            XCTAssertTrue(reminder.waitForNonExistence(timeout: 3))
            tap("question.spoken.0.0")
            confirm.tap()
            XCTAssertTrue(reminder.waitForExistence(timeout: 3), "Deselecting every tile restores the reminder")
            tap("question.spoken.0.0")
            confirm.tap()
            XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5), "One tile is enough to check an incomplete answer")
            tap("question.next")
            tap("question.confirm")
            XCTAssertTrue(reminder.waitForExistence(timeout: 3), "Each new spoken question requires a new selection")
        }
    }

    /// Choose a wrong hour that also differs from the untouched clock.
    private func changeClockToWrongTime(_ kind: ClockQuestionKind, target: ClockTime? = nil) {
        func clockTime(_ label: String) -> ClockTime {
            let pieces = label.split(separator: ":")
            return ClockTime(hour: Int(pieces[0])!, minute: Int(pieces[1].prefix(2))!)
        }
        let controlID = kind == .setDigital ? "question.digitalControl" : "question.analogControl"
        let control = app.descendants(matching: .any)[controlID]
        XCTAssertTrue(control.waitForExistence(timeout: 5))
        let initial = clockTime(control.label)
        let target = target ?? clockTime(app.descendants(matching: .any)["question.targetClock"].label)
        var hour = ClockTime.shiftedHour(target.hour, by: 1)
        if hour % 12 == initial.hour % 12 { hour = ClockTime.shiftedHour(hour, by: 1) }
        for _ in 0..<((hour - initial.hour + 12) % 12) {
            tap(kind == .setDigital ? "clock.hour.more" : "question.analog.more")
        }
    }

    func testClockAnswerFeedbackKeepsItsStageAndTargetInPlace() {
        openPractice()
        tap("practice.time.fiveMinutes")
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
            var generator = DinoPracticeGenerator(configuration: .init(time: .fiveMinutes, order: .specific(kind)), seed: seed)
            changeClockToWrongTime(kind.recipe.kind, target: generator.next(index: 0).target)
            let titleFrame = title.frame
            let targetFrame = target.frame
            let controlFrame = control.frame
            let submittedValue = control.label
            saveScreenshot("feedback-\(kind.rawValue)-before")
            confirm.tap()
            let correct = app.descendants(matching: .any)["question.correctClock"]
            XCTAssertTrue(correct.waitForExistence(timeout: 5))
            XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
            if kind != .setAnalog || app.frame.width >= 664 {
                XCTAssertEqual(title.frame.minY, titleFrame.minY, accuracy: 1, "Feedback keeps the question heading in place")
            }
            if app.frame.width < 664 {
                if kind == .setAnalog {
                    XCTAssertLessThan(targetFrame.minY - titleFrame.maxY, 32,
                                      "The digital target has no empty pointer row before a mistake")
                    XCTAssertGreaterThan(target.frame.height, targetFrame.height,
                                         "Reading pointers add their space only after a mistake")
                } else {
                    XCTAssertEqual(target.frame.minY, targetFrame.minY, accuracy: 1)
                }
                if kind == .setDigital {
                    // The analog target fits its new pointers inside the same height;
                    // their horizontal reach is part of its accessibility frame.
                    XCTAssertEqual(target.frame.height, targetFrame.height, accuracy: 1)
                    XCTAssertLessThanOrEqual(target.frame.width, app.scrollViews["game.questions"].frame.width)
                } else {
                    XCTAssertEqual(target.frame.width, targetFrame.width, accuracy: 1, "The prompt clock keeps its size")
                }
            }
            XCTAssertEqual(control.label, submittedValue, "The submitted clock keeps its value")
            XCTAssertEqual(app.descendants(matching: .any).matching(identifier: controlID).count, 1)
            XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "question.correctClock").count, 1)
            XCTAssertFalse(app.buttons["question.confirm"].exists)
            if app.frame.width >= 664 {
                XCTAssertLessThan(correct.frame.midX, control.frame.midX)
                XCTAssertEqual(correct.frame.midX, targetFrame.midX, accuracy: 1)
                XCTAssertEqual(control.frame.midX, controlFrame.midX, accuracy: 1)
            } else if kind == .advanceAnalog {
                XCTAssertLessThan(control.frame.midX, correct.frame.midX)
                XCTAssertEqual(control.frame.midY, correct.frame.midY, accuracy: 8)
                let entered = app.descendants(matching: .any)["question.advance.entered"]
                let difference = app.descendants(matching: .any)["question.advance.difference"]
                XCTAssertTrue(entered.exists)
                XCTAssertLessThan(entered.frame.midX, target.frame.midX)
                XCTAssertGreaterThan(difference.frame.midX, target.frame.midX)
                XCTAssertEqual(entered.frame.midY, difference.frame.midY, accuracy: 1)
                XCTAssertEqual(target.frame.midX - entered.frame.maxX,
                               difference.frame.minX - target.frame.midX, accuracy: 1,
                               "The entered change mirrors the assignment beside the shared arrow origin")
                XCTAssertLessThan(entered.frame.maxY, control.frame.minY)
                XCTAssertLessThan(difference.frame.maxY, correct.frame.minY)
            } else {
                if kind == .setDigital {
                    // Numbered pointers extend the accessible readout upward;
                    // its bottom edge follows the actual display baseline.
                    XCTAssertEqual(control.frame.maxY, controlFrame.maxY, accuracy: 4.1,
                                   "The display stays in place within its four-point feedback outline")
                } else {
                    XCTAssertGreaterThanOrEqual(control.frame.midY, controlFrame.midY,
                                                "The submitted clock moves down as reading help opens above it")
                }
                XCTAssertLessThan(control.frame.midX, correct.frame.midX)
            }
            XCTAssertTrue(correct.frame.intersects(app.scrollViews["game.questions"].frame))
            saveScreenshot("feedback-\(kind.rawValue)-after")
            tap("question.next")
            XCTAssertTrue(app.buttons["question.confirm"].waitForExistence(timeout: 5))
            tap("header.pause")
        }
    }

    func testWrongAnswerLayoutAcrossQuestionTypes() {
        continueAfterFailure = true
        defer { continueAfterFailure = false }
        for type in DinoPracticeQuestion.allCases {
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.wrong-layout.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
            app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = type.rawValue
            app.launchEnvironment["DINO_TEST_PRACTICE_CHALLENGE"] = "1"
            app.launch()
            XCTAssertTrue(app.staticTexts["question.title"].waitForExistence(timeout: 10))
            var generator = DinoPracticeGenerator(configuration: .init(time: .minutes, order: .specific(type)), seed: seed)
            let question = generator.next(index: 3, difficultyForKind: { _ in .challenge })
            saveScreenshot("wrong-layout-\(type.rawValue)-before")
            if type == .setDigital {
                XCTAssertTrue(app.buttons["clock.hour.more"].isHittable)
                XCTAssertTrue(app.buttons["clock.minute.less"].isHittable)
            }
            answerPracticeWrong(question)
            let next = app.buttons["question.next"]
            XCTAssertTrue(next.isHittable, "\(type): Next remains reachable after a wrong answer")
            if [.chooseAnalog, .setAnalog].contains(type) {
                let target = app.descendants(matching: .any)["question.targetClock"]
                if target.exists {
                    XCTAssertGreaterThanOrEqual(target.frame.minY, app.staticTexts["question.title"].frame.maxY + 4,
                                                "Reading pointers stay clear of the question title")
                }
            }
            if type == .setDigital {
                for field in ["hour", "minute"] {
                    for direction in ["more", "less"] {
                        XCTAssertFalse(app.buttons["clock.\(field).\(direction)"].exists,
                                       "Adjustment chevrons disappear from answer feedback")
                    }
                }
            }
            let options = app.buttons.allElementsBoundByIndex.filter { $0.identifier.hasPrefix("question.option.") }
            let frames = options.map(\.frame)
            let viewport = app.scrollViews["game.questions"].frame
            for option in options {
                XCTAssertGreaterThanOrEqual(option.frame.minX, viewport.minX - 8)
                XCTAssertLessThanOrEqual(option.frame.maxX, viewport.maxX + 8)
                XCTAssertLessThanOrEqual(option.frame.maxY, viewport.maxY + 4.1,
                                         "\(type): answers stay above Next, allowing their four-point feedback outline")
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.4))
            for (option, frame) in zip(options, frames) {
                XCTAssertEqual(option.frame, frame, "\(type): rejected and untouched answers settle together")
            }
            saveScreenshot("wrong-layout-\(type.rawValue)-after")
        }
    }

    func testSortingRequiresAllClocksBeforeChecking() {
        openPractice()
        selectPractice("practice.type.sortTimes")
        tap("practice.start")
        let confirm = app.buttons["question.confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        XCTAssertTrue(confirm.isEnabled)
        let confirmFrame = confirm.frame
        let reminder = app.descendants(matching: .any)["question.inputReminder"]
        confirm.tap()
        XCTAssertTrue(reminder.waitForExistence(timeout: 3))
        XCTAssertEqual(reminder.label, "Selecteer eerst alle klokken")
        XCTAssertEqual(reminder.frame.midY, confirmFrame.midY, accuracy: 1)
        XCTAssertFalse(app.buttons["question.next"].exists)
        for index in 0..<4 {
            confirm.tap()
            XCTAssertEqual(app.buttons["question.sort.\(index)"].value as? String, "Selecteer eerst alle klokken")
        }
        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.sortTimes)), seed: seed)
        let question = generator.next(index: 0)
        guard case .ordering(let order) = question.expectedAnswer else { return XCTFail("Expected clock order") }
        let indices = order.map { question.options.firstIndex(of: $0)! }
        tap("question.sort.\(indices[0])")
        confirm.tap()
        XCTAssertEqual(app.buttons["question.sort.\(indices[1])"].value as? String, "Selecteer eerst alle klokken")
        XCTAssertEqual(app.buttons["question.sort.\(indices[0])"].value as? String, "1")
        confirm.tap()
        saveScreenshot("sorting-partial-selection-reminder")
        tap("question.sort.\(indices[0])")
        confirm.tap()
        XCTAssertEqual(app.buttons["question.sort.\(indices[0])"].value as? String, "Selecteer eerst alle klokken")
        for index in indices { tap("question.sort.\(index)") }
        XCTAssertTrue(reminder.waitForNonExistence(timeout: 3))
        confirm.tap()
        let nextBoard = NSPredicate { _, _ in
            (self.app.buttons["question.sort.0"].value as? String) == ""
        }
        expectation(for: nextBoard, evaluatedWith: nil)
        waitForExpectations(timeout: 5)
        confirm.tap()
        XCTAssertTrue(reminder.waitForExistence(timeout: 3), "The next question requires a fresh selection")
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
            if kind != .flightArrival {
                for index in question.responses.indices {
                    XCTAssertEqual(app.buttons["question.option.\(index)"].frame.midY, frames[index].midY, accuracy: 1)
                }
            }
            // The flight ticket grows when its first hint appears, then keeps that layout during the explanation.
            let revealedFrames = question.responses.indices.map { app.buttons["question.option.\($0)"].frame }
            if canRetry { tap("question.showAnswer") }
            XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
            // Flight and zone arithmetic keep animating after the reveal.
            RunLoop.current.run(until: Date().addingTimeInterval(1))
            for index in question.responses.indices {
                XCTAssertEqual(app.buttons["question.option.\(index)"].frame.midY, revealedFrames[index].midY, accuracy: 1)
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

    func testMinutesBetweenTimelineAfterFirstMistake() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launch()
        XCTAssertTrue(app.buttons["header.practice"].waitForExistence(timeout: 10))
        waitForMapOpeningToFinish()
        tap("header.practice")
        tap("practice.time.quarter")
        selectPractice("practice.type.minutesBetween")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .quarter, order: .specific(.minutesBetween)), seed: seed)
        let first = generator.next(index: 0)
        tap("question.option.\(first.responses.firstIndex(of: first.expectedAnswer)!)")
        let second = app.staticTexts.matching(identifier: "header.questions")
            .matching(NSPredicate(format: "label == %@", "2")).firstMatch
        XCTAssertTrue(second.waitForExistence(timeout: 8))
        let question = generator.next(index: 1, difficultyForKind: { _ in .familiar })
        XCTAssertEqual(question.responses.count, 4)
        XCTAssertFalse(app.descendants(matching: .any)["question.minutesBetween.timeline"].exists)
        let start = app.descendants(matching: .any)["question.minutesBetween.start"]
        let end = app.descendants(matching: .any)["question.minutesBetween.end"]
        XCTAssertEqual(start.label, question.relatedTimes[0].digitalText)
        XCTAssertEqual(end.label, question.relatedTimes[1].digitalText)
        let wrong = question.responses.firstIndex { $0 != question.expectedAnswer }!
        tap("question.option.\(wrong)")
        XCTAssertTrue(app.buttons["question.showAnswer"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["question.minutesBetween.unknown"].exists)
        assertMinutesBetweenTimeline(question, language: "nl", prefix: "question", showsAnswer: false)
        for index in question.responses.indices where index != wrong {
            XCTAssertTrue(app.buttons["question.option.\(index)"].isHittable)
        }
        assertMinutesBetweenAnswersFit(question)
        saveScreenshot("minutes-between-first-mistake-expanded-timeline")
        tap("question.showAnswer")
        assertMinutesBetweenTimeline(question, language: "nl", prefix: "question", showsAnswer: true)
        assertMinutesBetweenAnswersFit(question)
        saveScreenshot("minutes-between-complete-timeline")
        tap("question.next")
        XCTAssertFalse(app.descendants(matching: .any)["question.minutesBetween.timeline"].exists)
    }

    func testCompactDigitalClocksKeepAMPMOnOneLine() {
        launchDigitalClockLayoutFixture(force24Hour: false)
        tap("header.practice")
        tap("practice.time.quarter")
        selectPractice("practice.type.minutesBetween")
        tap("practice.start")
        assertSingleLineDigitalEndpoints(prefix: "question")
        saveScreenshot("digital-ampm-minutes-between-initial")

        for style in ["rounded", "digital", "modern", "classic"] {
            tap("header.dino")
            tap("personalize.page.digital")
            tap("theme.numerals.\(style)")
            tap("personalize.done")
            assertSingleLineDigitalEndpoints(prefix: "question")
            saveScreenshot("digital-ampm-minutes-between-\(style)")
        }

        tap("question.example")
        assertSingleLineDigitalEndpoints(prefix: "demo")
        saveScreenshot("digital-ampm-minutes-between-example")
        tap("demo.ready")
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
            assertSingleLineDigitalEndpoints(prefix: "question")
            saveScreenshot("digital-ampm-minutes-between-landscape")
        }
    }

    func testDigitalAnswerOutlinesWithBothHourFormats() {
        for force24Hour in [true, false] {
            launchDigitalClockLayoutFixture(force24Hour: force24Hour)
            tap("header.practice")
            selectPractice("practice.type.setDigital")
            tap("practice.start")
            let control = app.descendants(matching: .any)["question.digitalControl"]
            XCTAssertTrue(control.waitForExistence(timeout: 5))
            changeClockToWrongTime(.setDigital)
            let initial = control.label
            tap("question.confirm")
            let answer = app.descendants(matching: .any)["question.correctClock"]
            XCTAssertTrue(answer.waitForExistence(timeout: 5))
            XCTAssertEqual(control.label, initial, "Feedback preserves the submitted time")
            // Reading pointers add height to the accessible clock, so its outer
            // aspect ratio no longer describes the digital display itself.
            XCTAssertEqual(answer.frame.width, control.frame.width, accuracy: 1,
                           "Both complete displays use the same scale")
            if app.frame.width >= 664 {
                XCTAssertLessThan(answer.frame.maxX, control.frame.minX)
            } else {
                XCTAssertLessThan(control.frame.maxX, answer.frame.minX,
                                  "Both outlined displays fit beside one another")
            }
            XCTAssertGreaterThanOrEqual(control.frame.minX, app.frame.minX)
            XCTAssertLessThanOrEqual(answer.frame.maxX, app.frame.maxX)
            XCTAssertEqual(answer.label.contains("AM") || answer.label.contains("PM"), !force24Hour)
            saveScreenshot("digital-answer-outline-\(force24Hour ? "24h" : "ampm")")
        }
    }

    private func launchDigitalClockLayoutFixture(force24Hour: Bool) {
        app.terminate()
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.digital-layout.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launchArguments = ["-settings.languageOverride", "en", "-AppleICUForce24HourTime", force24Hour ? "YES" : "NO"]
        app.launch()
        XCTAssertTrue(app.buttons["header.practice"].waitForExistence(timeout: 10))
        waitForMapOpeningToFinish()
    }

    private func assertSingleLineDigitalEndpoints(prefix: String) {
        let start = app.descendants(matching: .any)["\(prefix).minutesBetween.start"]
        let end = app.descendants(matching: .any)["\(prefix).minutesBetween.end"]
        guard start.waitForExistence(timeout: 5) else {
            saveScreenshot("digital-ampm-missing-\(prefix)-clock")
            XCTFail("Missing digital endpoint: \(app.debugDescription)")
            return
        }
        XCTAssertTrue(end.exists)
        for clock in [start, end] {
            XCTAssertTrue(clock.label.contains("AM") || clock.label.contains("PM"))
            XCTAssertGreaterThan(clock.frame.width, clock.frame.height * 1.9,
                                 "Digits and AM/PM share a single, proportionally fitted row")
        }
        XCTAssertEqual(start.frame.midY, end.frame.midY, accuracy: 1)
        XCTAssertLessThan(start.frame.maxX, end.frame.minX)
    }

    private func checkMinutesBetweenQuestionAndExample(language: String, family: DinoPracticeTime) {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launchArguments = ["-settings.languageOverride", language]
        app.launch()
        XCTAssertTrue(app.buttons["header.practice"].waitForExistence(timeout: 10))
        waitForMapOpeningToFinish()
        tap("header.practice")
        XCTAssertTrue(app.buttons["practice.start"].waitForExistence(timeout: 5))
        tap("practice.time.\(family.rawValue)")
        selectPractice("practice.type.minutesBetween")
        XCTAssertTrue(app.buttons["practice.type.minutesBetween"].label.contains(
            language == "nl" ? "Bereken het verschil in minuten" : "Calculate the difference in minutes"))
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: family, order: .specific(.minutesBetween)), seed: seed)
        let q = generator.next(index: 0)
        let start = app.descendants(matching: .any)["question.minutesBetween.start"]
        let end = app.descendants(matching: .any)["question.minutesBetween.end"]
        XCTAssertEqual(start.label, q.relatedTimes[0].digitalText)
        XCTAssertEqual(end.label, q.relatedTimes[1].digitalText)
        let earlier = DinoTimeWords.time(q.relatedTimes[0], language: language)
        let later = DinoTimeWords.time(q.relatedTimes[1], language: language)
        XCTAssertEqual(app.staticTexts["question.title"].label,
                       language == "nl" ? "Hoeveel minuten zitten er tussen \(earlier) en \(later)?"
                       : "How many minutes are there between \(earlier) and \(later)?")
        XCTAssertTrue(app.descendants(matching: .any)["question.minutesBetween.unknown"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["question.minutesBetween.timeline"].exists)
        XCTAssertFalse(app.staticTexts["Beide tijden zijn op dezelfde dag."].exists)
        XCTAssertFalse(app.staticTexts["Both times are on the same day."].exists)
        XCTAssertFalse(app.descendants(matching: .any)["demo.minutesBetween.calculation"].exists)
        for (index, answer) in q.responses.enumerated() {
            guard case .duration(let minutes) = answer else { return XCTFail("Expected minutes") }
            XCTAssertEqual(app.buttons["question.option.\(index)"].label, DinoTimeWords.minutes(minutes, language: language))
            XCTAssertTrue(app.buttons["question.option.\(index)"].isHittable, "All minute choices fit on screen")
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
            for index in 2..<5 {
                tap("demo.nextExample")
                latest = DinoDemonstrationExamples.question(kind: .minutesBetween, minutes: family.minutes,
                    minuteStep: family.minuteStep, index: index, previousTarget: latest.target)
                assertMinutesBetweenCalculation(latest, language: language)
            }
            saveScreenshot("minutes-between-timeline-refreshed-\(language)")
        }
        tap("demo.ready")
        XCTAssertEqual(start.label, q.relatedTimes[0].digitalText, "Examples preserve the live question")
        let wrong = q.responses.firstIndex { $0 != q.expectedAnswer }!
        tap("question.option.\(wrong)")
        if q.responses.count > 2 {
            XCTAssertTrue(app.buttons["question.showAnswer"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.descendants(matching: .any)["question.minutesBetween.unknown"].exists)
            assertMinutesBetweenTimeline(q, language: language, prefix: "question", showsAnswer: false)
            XCTAssertEqual(start.label, q.relatedTimes[0].digitalText)
            XCTAssertEqual(end.label, q.relatedTimes[1].digitalText)
            for index in q.responses.indices where index != wrong {
                XCTAssertTrue(app.buttons["question.option.\(index)"].isHittable, "Hint leaves remaining answers accessible")
            }
            saveScreenshot("minutes-between-timeline-hint-\(language)")
            tap("question.showAnswer")
        } else {
            XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["question.showAnswer"].exists)
        }
        XCTAssertEqual(app.descendants(matching: .any)["question.minutesBetween.answer"].label,
                       DinoTimeWords.minutes(q.durationMinutes, language: language))
        assertMinutesBetweenTimeline(q, language: language, prefix: "question", showsAnswer: true)
        let subtitles = app.descendants(matching: .any).matching(identifier: "practice.hudSubtitle").allElementsBoundByIndex
        XCTAssertFalse(subtitles.isEmpty)
        XCTAssertGreaterThan(app.staticTexts["question.title"].frame.minY,
                             subtitles.map { $0.frame.maxY }.max() ?? 0,
                             "The question stays below both header labels during feedback")
        saveScreenshot("minutes-between-answer-\(language)")
        tap("question.next")
        let secondQuestion = app.staticTexts.matching(identifier: "header.questions")
            .matching(NSPredicate(format: "label == %@", "2")).firstMatch
        XCTAssertTrue(secondQuestion.waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["question.minutesBetween.timeline"].exists,
                       "The next question starts without a hint")
    }

    private func assertMinutesBetweenAnswersFit(_ question: ClockQuestion) {
        let viewport = app.scrollViews["game.questions"].frame
        let footer = app.buttons["question.showAnswer"].exists
            ? app.buttons["question.showAnswer"].frame : app.buttons["question.next"].frame
        for index in question.responses.indices {
            let answer = app.buttons["question.option.\(index)"].frame
            XCTAssertGreaterThanOrEqual(answer.minY, viewport.minY - 0.5,
                                        "The complete answer stays inside the question viewport")
            XCTAssertLessThanOrEqual(answer.maxY, min(viewport.maxY, footer.minY) + 0.5,
                                     "The bottom answer row stays fully above the footer")
        }
    }

    private func assertMinutesBetweenCalculation(_ question: ClockQuestion, language: String) {
        assertMinutesBetweenTimeline(question, language: language, prefix: "demo", showsAnswer: true)
        XCTAssertFalse(app.staticTexts["Beide tijden zijn op dezelfde dag."].exists)
        XCTAssertFalse(app.staticTexts["Both times are on the same day."].exists)
    }

    private func assertMinutesBetweenTimeline(_ question: ClockQuestion, language: String,
                                             prefix: String, showsAnswer: Bool) {
        let timeline = DinoMinuteTimeline(question.relatedTimes[0], question.relatedTimes[1])
        let card = app.descendants(matching: .any)["\(prefix).minutesBetween.timeline"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        let total = app.descendants(matching: .any)[prefix == "demo" ? "demo.answer" : "question.minutesBetween.\(showsAnswer ? "answer" : "unknown")"]
        var previous: XCUIElement?
        for (index, time) in timeline.times.enumerated() {
            let stop = app.staticTexts["\(prefix).minutesBetween.stop.\(index)"]
            XCTAssertEqual(stop.label, time.digitalText)
            XCTAssertGreaterThan(stop.frame.minY, total.frame.maxY,
                                 "Timeline labels sit below the total interval after the arrow lowers")
            XCTAssertGreaterThanOrEqual(stop.frame.minX, card.frame.minX - 0.5)
            XCTAssertLessThanOrEqual(stop.frame.maxX, card.frame.maxX + 0.5)
            if let previous { XCTAssertLessThan(previous.frame.maxX, stop.frame.minX) }
            previous = stop
        }
        for (index, minutes) in timeline.segments.enumerated() {
            let segment = app.staticTexts["\(prefix).minutesBetween.segment.\(index)"]
            XCTAssertEqual(segment.label, "\(minutes) min", "Every helper block states its full duration")
            let first = app.staticTexts["\(prefix).minutesBetween.stop.\(index)"]
            let last = app.staticTexts["\(prefix).minutesBetween.stop.\(index + 1)"]
            XCTAssertGreaterThan(segment.frame.minY, first.frame.maxY + 12,
                                 "A gathering curl separates the time labels from the minute blocks")
            XCTAssertEqual(segment.frame.midX, (first.frame.midX + last.frame.midX) / 2, accuracy: 1,
                           "Step values are centered between the time labels")
        }
        XCTAssertFalse(app.staticTexts["\(prefix).minutesBetween.conversion"].exists,
                       "The timeline ends with its minute blocks, without a separate sum")
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

    func testOpeningArrivesInLandscapeAndDoesNotReplayAfterClosingLevel() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "3"
        app.launchArguments = ["-settings.languageOverride", "en"]
        let tablet = UIDevice.current.userInterfaceIdiom == .pad
        if tablet { XCUIDevice.shared.orientation = .landscapeLeft }
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        waitForMapOpeningToFinish()
        let target = app.buttons["map.level.4"]
        let dino = app.descendants(matching: .any)["map.dino.4"]
        XCTAssertTrue(target.waitForExistence(timeout: 8))
        XCTAssertTrue(target.isHittable)
        XCTAssertTrue(dino.exists)
        XCTAssertEqual(dino.frame.midX, target.frame.midX, accuracy: 1)
        if tablet { XCTAssertGreaterThan(app.frame.width, app.frame.height) }
        saveScreenshot("opening-english-saved-arrival")
        tap("map.level.4")
        XCTAssertTrue(app.buttons["level.play"].waitForExistence(timeout: 5))
        tap("level.map")
        XCTAssertFalse(app.descendants(matching: .any)["map.preparing"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["map.opening.title"].exists)
        XCTAssertTrue(app.buttons["header.settings"].isHittable)
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

    func testMapLevelCircleKeepsItsFullHitArea() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "5"
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 15))
        waitForMapOpeningToFinish()
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "map.level.")).count, 100)
        let first = revealMapNode(51)
        XCTAssertTrue(first.isEnabled)
        first.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["level.play"].waitForExistence(timeout: 5))
    }

    func testWorldJumpStillLandsOnNextWorld() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.cached-map-jump.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "59"
        app.launchEnvironment["DINO_TEST_RESULT_LEVEL"] = "60"
        app.launchEnvironment["DINO_TEST_RESULT_CORRECT"] = "10"
        app.launch()
        XCTAssertTrue(app.buttons["result.next"].waitForExistence(timeout: 10))
        tap("result.next")
        let dino = app.descendants(matching: .any)["map.dino.61"]
        XCTAssertTrue(dino.waitForExistence(timeout: 20))
        let stone = app.buttons["map.level.61"]
        XCTAssertTrue(stone.isHittable)
        XCTAssertFalse(app.descendants(matching: .any)["map.worldJump"].exists)
        XCTAssertEqual(dino.frame.midX, stone.frame.midX, accuracy: 2)
        // The 12-point foot offset scales with the 72-point stone on iPad.
        let footOffset = stone.frame.width / 6
        XCTAssertEqual(dino.frame.maxY, stone.frame.midY + footOffset, accuracy: 2)
        saveScreenshot("cached-map-world-jump-landed")
    }

    func testGentleMapScrollPerformance() {
        measureGentleMapScroll()
    }

    private func measureGentleMapScroll() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "5"
        app.launchEnvironment["DINO_TEST_MAP_DIAGNOSTICS"] = "1"
        app.launchEnvironment["DINO_TEST_SCROLL_ONLY_GAPS"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 15))
        waitForMapOpeningToFinish()
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.58))
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        measure(metrics: [XCTCPUMetric(application: app), XCTMemoryMetric(application: app)], options: options) {
            for _ in 0..<3 {
                start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
                end.press(forDuration: 0.05, thenDragTo: start, withVelocity: .slow, thenHoldForDuration: 0.1)
            }
        }
        let gap = app.staticTexts["map.maximumFrameGapMilliseconds"]
        XCTAssertTrue(gap.exists)
        print("MAP_GENTLE_SCROLL maximumScrollGapMilliseconds=\(gap.label)")
        XCTAssertTrue(app.buttons["header.settings"].isHittable)
        saveScreenshot("gentle-map-scroll")
    }

    func testCityScrollRenderingBudgetPerformance() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "5"
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 15))
        waitForMapOpeningToFinish()
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        measure(metrics: [XCTCPUMetric(application: app), XCTMemoryMetric(application: app),
                          XCTOSSignpostMetric.scrollingAndDecelerationMetric], options: options) {
            for _ in 0..<2 { app.swipeUp(velocity: .fast) }
            for _ in 0..<2 { app.swipeDown(velocity: .fast) }
        }
        XCTAssertTrue(app.buttons["header.settings"].isHittable)
        saveScreenshot("city-scroll-rendering-budget")
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

    func testSleepValleyToTimeMachineScrollPerformance() {
        app.terminate()
        // Start far enough away that world 8 has not been constructed on launch.
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "4"
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 15))
        waitForMapOpeningToFinish()
        _ = revealMapNode(51)
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        var metrics: [XCTMetric] = [XCTCPUMetric(application: app), XCTMemoryMetric(application: app),
                                    XCTOSSignpostMetric.scrollingAndDecelerationMetric]
        if #available(iOS 26, *) { metrics.append(XCTHitchMetric(application: app)) }
        measure(metrics: metrics, options: options) {
            for _ in 0..<6 { app.swipeUp(velocity: .fast) }
            XCTAssertLessThan(app.buttons["map.level.71"].frame.minY, app.frame.maxY,
                              "The measured gestures must reach the time-machine world")
            for _ in 0..<6 { app.swipeDown(velocity: .fast) }
        }
        XCTAssertTrue(app.buttons["header.settings"].isHittable)
        saveScreenshot("performance-sleep-valley-time-machine-return")
    }

    @MainActor
    func testDeviceThermalCooldown() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["DINO_TEST_THERMAL_COOLDOWN"] == "1",
                          "Opt-in device preparation; not part of the regression suite")
        app.terminate()
        for _ in 0..<30 {
            let state = ProcessInfo.processInfo.thermalState
            print("MAP_DEVICE_COOLDOWN thermal=\(state.rawValue)")
            if state == .nominal || state == .fair { return }
            try await Task.sleep(for: .seconds(10))
        }
        throw XCTSkip("Device remains too warm for a comparable performance measurement")
    }

    func testColdFirstTraversalPerformance() {
        let options = XCTMeasureOptions()
        options.iterationCount = 1
        options.invocationOptions = [.manuallyStart, .manuallyStop]
        var warmup = true
        measure(metrics: [XCTCPUMetric(application: app), XCTMemoryMetric(application: app),
                          XCTOSSignpostMetric.scrollingAndDecelerationMetric], options: options) {
            app.terminate()
            // Keep the app closed while recovering from earlier measurements.
            for _ in 0..<30 {
                let state = ProcessInfo.processInfo.thermalState
                if state == .nominal || state == .fair { break }
                print("MAP_FIRST_TRAVERSAL_COOLDOWN thermal=\(state.rawValue)")
                RunLoop.current.run(until: Date().addingTimeInterval(10))
            }
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.first-traversal.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "5"
            app.launchEnvironment["DINO_TEST_MAP_DIAGNOSTICS"] = "1"
            app.launchEnvironment["DINO_TEST_SCROLL_ONLY_GAPS"] = "1"
            app.launchEnvironment["DINO_TEST_COLD_MAP_ARTWORK"] = "1"
            app.launch()
            XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 15))
            waitForMapOpeningToFinish()
            let thermal = ProcessInfo.processInfo.thermalState
            print("MAP_FIRST_TRAVERSAL_DEVICE warmup=\(warmup) thermal=\(thermal.rawValue) lowPower=\(ProcessInfo.processInfo.isLowPowerModeEnabled)")
            let validTemperature = thermal == .nominal || thermal == .fair
            XCTAssertTrue(validTemperature, "A hot device cannot supply a comparable performance sample")
            startMeasuring()
            for _ in 0..<(warmup ? 2 : 12) { app.swipeUp(velocity: .fast) }
            stopMeasuring()
            if !warmup {
                XCTAssertLessThan(app.buttons["map.level.91"].frame.minY, app.frame.maxY)
                let gap = app.staticTexts["map.maximumFrameGapMilliseconds"]
                print("MAP_FIRST_TRAVERSAL gap=\(gap.label) \(gap.value as? String ?? "") thermalEnd=\(ProcessInfo.processInfo.thermalState.rawValue)")
                let endThermal = ProcessInfo.processInfo.thermalState
                XCTAssertTrue(endThermal == .nominal || endThermal == .fair,
                              "Discard a performance sample if the device overheated during traversal")
                saveScreenshot("cold-first-traversal-castle")
            }
            warmup = false
            app.terminate()
        }
    }

    func testColdMultiWorldFlickTrace() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "5"
        app.launchEnvironment["DINO_TEST_MAP_DIAGNOSTICS"] = "1"
        app.launchEnvironment["DINO_TEST_SCROLL_ONLY_GAPS"] = "1"
        app.launchEnvironment["DINO_TEST_COLD_MAP_ARTWORK"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 15))
        waitForMapOpeningToFinish()
        print("MAP_FLICK_TRACE_READY wall=\(Date().timeIntervalSince1970)")
        let castle = app.buttons["map.level.91"]
        XCTAssertTrue(castle.exists)
        // This is a functional route, not a fixed-gesture benchmark. Flick
        // distance varies with the viewport and simulator gesture delivery.
        var flicks = 0
        for _ in 0..<20 {
            if castle.frame.intersects(app.frame) { break }
            if castle.frame.maxY <= app.frame.minY { app.swipeDown(velocity: .fast) }
            else { app.swipeUp(velocity: .fast) }
            flicks += 1
        }
        XCTAssertTrue(castle.frame.intersects(app.frame),
                      "The cold route must reach the castle within 20 flicks; final frame: \(castle.frame)")
        XCTAssertTrue(app.buttons["header.settings"].isHittable)
        let gap = app.staticTexts["map.maximumFrameGapMilliseconds"]
        print("MAP_FLICK_TRACE swipes=\(flicks) gap=\(gap.label) \(gap.value as? String ?? "")")
        saveScreenshot("cold-flick-trace-castle")
    }

    func testColdMultiWorldFlickPerformance() {
        let options = XCTMeasureOptions()
        options.iterationCount = 1
        options.invocationOptions = [.manuallyStart, .manuallyStop]
        var metrics: [XCTMetric] = [XCTCPUMetric(application: app), XCTMemoryMetric(application: app),
                                    XCTOSSignpostMetric.scrollingAndDecelerationMetric]
        if #available(iOS 26, *) { metrics.append(XCTHitchMetric(application: app)) }
        // XCTest discards a warm-up iteration. Relaunch with a fresh cache for
        // EVERY iteration so the measured traversal also includes new worlds.
        measure(metrics: metrics, options: options) {
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.cold-flick.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "5"
            app.launchEnvironment["DINO_TEST_MAP_DIAGNOSTICS"] = "1"
            app.launchEnvironment["DINO_TEST_SCROLL_ONLY_GAPS"] = "1"
            app.launchEnvironment["DINO_TEST_COLD_MAP_ARTWORK"] = "1"
            app.launch()
            XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 15))
            waitForMapOpeningToFinish()
            print("MAP_FLICK_DEVICE thermal=\(ProcessInfo.processInfo.thermalState.rawValue) lowPower=\(ProcessInfo.processInfo.isLowPowerModeEnabled)")
            startMeasuring()
            for _ in 0..<12 { app.swipeUp(velocity: .fast) }
            XCTAssertLessThan(app.buttons["map.level.91"].frame.minY, app.frame.maxY,
                              "The fast gestures must cross several worlds and reach the castle")
            for _ in 0..<12 { app.swipeDown(velocity: .fast) }
            stopMeasuring()
            let gap = app.staticTexts["map.maximumFrameGapMilliseconds"]
            print("MAP_COLD_FLICK maximumScrollGapMilliseconds=\(gap.label) \(gap.value as? String ?? "")")
        }
        XCTAssertTrue(app.buttons["header.settings"].isHittable)
        saveScreenshot("cold-multi-world-flick-return")
    }

    func testColdScrollAcrossEveryWorld() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launchEnvironment["DINO_TEST_MAP_DIAGNOSTICS"] = "1"
        app.launchEnvironment["DINO_TEST_COLD_MAP_ARTWORK"] = "1"
        app.launch()
        waitForMapOpeningToFinish()
        let gap = app.staticTexts["map.maximumFrameGapMilliseconds"]
        XCTAssertTrue(gap.exists)
        // No warm-up: include first construction of every subsequent world.
        for id in stride(from: 1, through: 91, by: 10) {
            let node = app.buttons["map.level.\(id)"]
            XCTAssertTrue(node.exists)
            XCTAssertGreaterThan(node.frame.width, 0)
            for _ in 0..<12 {
                if node.frame.minY < app.frame.maxY - 16 { break }
                app.swipeUp(velocity: .fast)
            }
            XCTAssertLessThan(node.frame.minY, app.frame.maxY - 16, "The traversal must reach world \((id - 1) / 10 + 1)")
            print("MAP_ALL_WORLDS level=\(id) maximumGap=\(gap.label) \(gap.value as? String ?? "")")
            saveScreenshot("cold-world-first-passage-\(id)")
        }
        _ = revealMapNode(100)
        for _ in 0..<20 { app.swipeDown(velocity: .fast) }
        print("MAP_ALL_WORLDS return maximumGap=\(gap.label) \(gap.value as? String ?? "")")
        // This broad traversal records the remaining stalls as diagnostic data.
        // Keep the existing targeted cold test's 500 ms regression guard; do
        // not imply that every world already meets that unachieved target.
        let milliseconds = Double(gap.label) ?? .infinity
        XCTAssertTrue(milliseconds.isFinite && milliseconds > 0, "The traversal must produce a valid frame-gap measurement")
        XCTAssertTrue(app.buttons["header.settings"].isHittable)
        saveScreenshot("cold-all-worlds-return")
    }

    func testColdSleepValleyScrollKeepsMainThreadResponsive() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "5"
        app.launchEnvironment["DINO_TEST_MAP_DIAGNOSTICS"] = "1"
        app.launchEnvironment["DINO_TEST_COLD_MAP_ARTWORK"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 15))
        waitForMapOpeningToFinish()
        let gap = app.staticTexts["map.maximumFrameGapMilliseconds"]
        XCTAssertTrue(gap.exists)
        // The first visit matters: the pirate coast starts preparing while
        // Sleep Valley is still visible, before a performance test's warm-up.
        for id in [57, 61, 65, 68, 71, 75, 81, 85] {
            _ = revealMapNode(id)
            print("MAP_COLD_SCROLL level=\(id) max=\(gap.label) \(gap.value as? String ?? "")")
        }
        let milliseconds = Double(gap.label) ?? .infinity
        print("MAP_COLD_SCROLL maximumFrameGapMilliseconds=\(milliseconds)")
        let flight = app.staticTexts["map.gullPreparedFrames"]
        print("MAP_GULL_PREPARATION \(flight.value as? String ?? "missing") frames=\(flight.label)")
        XCTAssertGreaterThan(Int(flight.label) ?? 0, 0, "The birds must still receive their complete flight simulation")
        XCTAssertTrue((flight.value as? String ?? "").contains("background"))
        XCTAssertLessThan(milliseconds, 500, "Preparing an upcoming world must never block the scrolling thread for half a second")
        XCTAssertTrue(app.buttons["header.settings"].isHittable)
        saveScreenshot("cold-sleep-valley-scroll-responsive")
    }

    func testQuestionTransitionWhenAnswerChoicesIncrease() {
        for type in [DinoPracticeQuestion.chooseAnalog, .chooseDigital, .spokenTime] {
            verifyQuestionTransition(type: type)
        }
    }

    func testQuestionTransitionWhenAnswerChoicesIncreaseInLandscape() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad)
        XCUIDevice.shared.orientation = .landscapeLeft
        for type in [DinoPracticeQuestion.chooseAnalog, .chooseDigital, .spokenTime] {
            verifyQuestionTransition(type: type)
        }
    }

    private func verifyQuestionTransition(type: DinoPracticeQuestion) {
        app.terminate()
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.question-transition.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = type.rawValue
        app.launch()
        XCTAssertTrue(app.buttons["question.option.1"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["question.option.2"].exists)
        let name = "question-transition-\(type.rawValue)-\(app.frame.width > app.frame.height ? "landscape" : "portrait")"
        saveScreenshot("\(name)-two-options")
        let configuration = DinoPracticeConfiguration(time: .minutes, order: .specific(type))
        var generator = DinoPracticeGenerator(configuration: configuration, seed: seed)
        let first = generator.next(index: 0)
        let next = generator.next(index: 1, difficultyForKind: { _ in .familiar })
        tap("question.option.\(first.responses.firstIndex(of: first.expectedAnswer)!)")
        XCTAssertTrue(app.buttons["question.option.3"].waitForExistence(timeout: 5))
        let title = app.staticTexts["question.title"]
        let titleFrame = title.frame
        let viewport = app.scrollViews["game.questions"]
        let viewportFrame = viewport.frame
        let optionFrames = next.responses.indices.map { app.buttons["question.option.\($0)"].frame }
        for index in next.responses.indices {
            let option = app.buttons["question.option.\(index)"]
            XCTAssertTrue(option.isHittable)
            XCTAssertGreaterThanOrEqual(option.frame.minY, viewportFrame.minY)
            XCTAssertLessThanOrEqual(option.frame.maxY, viewportFrame.maxY)
        }
        RunLoop.current.run(until: Date().addingTimeInterval(0.4))
        XCTAssertEqual(title.frame.minY, titleFrame.minY, accuracy: 1)
        XCTAssertEqual(viewport.frame, viewportFrame)
        for index in next.responses.indices {
            XCTAssertEqual(app.buttons["question.option.\(index)"].frame, optionFrames[index])
        }
        saveScreenshot("\(name)-four-options")
        tap("question.option.\(next.responses.firstIndex { $0 != next.expectedAnswer }!)")
        tap("question.showAnswer")
        tap("question.next")
        XCTAssertFalse(app.buttons["question.option.2"].exists, "A missed question returns to two choices")
        XCTAssertTrue(app.buttons["question.option.1"].isHittable)
        XCTAssertGreaterThanOrEqual(title.frame.minY, viewport.frame.minY,
                                    "The next question starts at the top of its own scroll region")
        saveScreenshot("\(name)-back-to-two-options")
    }

    func testConsecutiveCorrectPracticeAnswersKeepCompanionInPortrait() {
        openPractice()
        selectPractice("practice.type.chooseAnalog")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.chooseAnalog)), seed: seed)
        for index in 0..<3 {
            let question = generator.next(index: index, difficultyForKind: { _ in index == 0 ? .introduction : .familiar })
            assertCompanionInPortrait(app.descendants(matching: .any)["dino.character"])
            let previousTitle = app.staticTexts["question.title"].label
            tap("question.option.\(question.responses.firstIndex(of: question.expectedAnswer)!)")
            let advanced = NSPredicate { _, _ in
                self.app.staticTexts["question.title"].label != previousTitle
                    && self.app.descendants(matching: .any)["dino.character"].exists
            }
            expectation(for: advanced, evaluatedWith: nil)
            waitForExpectations(timeout: 6)
            XCTAssertTrue(app.descendants(matching: .any)["dino.character"].exists,
                          "Each applause finishes before the next answer and leaves a fresh idle companion")
        }
        saveScreenshot("applause-practice-three-correct")
    }

    func testPracticeHUDRecordsAndPersistentCounter() {
        // The cell identifier is inherited by its title and value in SwiftUI.
        let streak = app.staticTexts.matching(identifier: "header.streak")
            .matching(NSPredicate(format: "label MATCHES %@", "[0-9]+"))
        let counter = app.staticTexts.matching(identifier: "header.questions")
            .matching(NSPredicate(format: "label MATCHES %@", "[0-9]+"))
        openPractice()
        XCTAssertFalse(app.staticTexts["Van makkelijk naar moeilijk"].exists)
        selectPractice("practice.type.chooseAnalog")
        XCTAssertEqual(app.staticTexts["practice.type.chooseAnalog.record"].label, "0")
        saveScreenshot("practice-update-overview")
        tap("practice.start")
        XCTAssertTrue(app.descendants(matching: .any)["header.dino"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["header.streak"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["header.questions"].exists)
        XCTAssertTrue(app.staticTexts.matching(identifier: "header.questions")
            .matching(NSPredicate(format: "label CONTAINS %@", "Vraag")).firstMatch.exists)
        XCTAssertEqual(app.descendants(matching: .any)["practice.hudSubtitle"].label, "1 · Hele uren")
        XCTAssertFalse(app.descendants(matching: .any)["practice.currentType"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["header.level"].isHittable)
        XCTAssertEqual(streak.firstMatch.label, "0")
        saveScreenshot("practice-hud-larger-trophy-initial")
        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.chooseAnalog)), seed: seed)
        for index in 0..<2 {
            let question = generator.next(index: index, difficultyForKind: { _ in index == 0 ? .introduction : .familiar })
            if index == 0 {
                let words = DinoTimeWords.time(question.target, language: "nl")
                let count = question.options.count == 4 ? "vier" : "twee"
                XCTAssertEqual(app.staticTexts["question.title"].label, "Welke van de \(count) klokken geeft \(words) aan?")
            }
            tap("question.option.\(question.responses.firstIndex(of: question.expectedAnswer)!)")
            let next = counter
                .matching(NSPredicate(format: "label == %@", String(index + 2))).firstMatch
            XCTAssertTrue(next.waitForExistence(timeout: 6))
            XCTAssertEqual(streak.firstMatch.label, String(index + 1))
            XCTAssertEqual(app.staticTexts["practice.bestStreak"].label, String(index + 1))
        }
        saveScreenshot("practice-update-hud-record")
        saveScreenshot("practice-hud-larger-trophy-record")
        tap("header.pause")
        XCTAssertTrue(app.buttons["practice.start"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["game.exit.confirm"].exists)
        tap("practice.start")
        XCTAssertEqual(streak.firstMatch.label, "2")
        XCTAssertEqual(counter.firstMatch.label, "3")
        saveScreenshot("practice-followup-resumed-streak")
        // A reopened session has a fresh deterministic generator, with saved counters and streak.
        generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.chooseAnalog)), seed: seed)
        let wrongQuestion = generator.next(index: 0, difficultyForKind: { _ in .familiar })
        answerPracticeWrong(wrongQuestion)
        XCTAssertTrue(app.buttons["question.example"].isEnabled, "The example stays available while the answer is showing")
        saveScreenshot("practice-followup-feedback-hud")
        XCTAssertEqual(streak.firstMatch.label, "2", "Feedback keeps the streak and question counters together")
        XCTAssertEqual(counter.firstMatch.label, "3")
        XCTAssertEqual(app.staticTexts["practice.bestStreak"].label, "2")
        RunLoop.current.run(until: Date().addingTimeInterval(1))
        XCTAssertEqual(streak.firstMatch.label, "2")
        XCTAssertEqual(counter.firstMatch.label, "3")
        saveScreenshot("practice-hud-feedback-counters-held")
        tap("question.next")
        XCTAssertEqual(streak.firstMatch.label, "0")
        XCTAssertEqual(counter.firstMatch.label, "4")
        saveScreenshot("practice-hud-counters-advanced-together")
        tap("header.pause")
        XCTAssertEqual(app.staticTexts["practice.type.chooseAnalog.record"].label, "2")
        tap("practice.time.half")
        XCTAssertEqual(app.staticTexts["practice.type.chooseAnalog.record"].label, "0")
        tap("practice.time.whole")
        tap("practice.close")
        app.terminate(); app.launch()
        tap("header.practice")
        selectPractice("practice.type.chooseAnalog")
        tap("practice.start")
        XCTAssertEqual(counter.firstMatch.label, "4")
        XCTAssertEqual(streak.firstMatch.label, "0")
        XCTAssertEqual(app.staticTexts["practice.bestStreak"].label, "2")
        saveScreenshot("practice-update-hud-resumed")
        // Relaunch creates another generator with the fixed test seed.
        var restartedGenerator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.chooseAnalog)), seed: seed)
        let restartedQuestion = restartedGenerator.next(index: 0)
        tap("question.option.\(restartedQuestion.responses.firstIndex(of: restartedQuestion.expectedAnswer)!)")
        XCTAssertTrue(counter.matching(NSPredicate(format: "label == %@", "5")).firstMatch.waitForExistence(timeout: 6))
        XCTAssertEqual(streak.firstMatch.label, "1")
        tap("header.pause")
        tap("practice.close")
        app.terminate(); app.launch()
        tap("header.practice")
        selectPractice("practice.type.chooseAnalog")
        tap("practice.start")
        XCTAssertEqual(streak.firstMatch.label, "1")
        XCTAssertEqual(counter.firstMatch.label, "5")
        saveScreenshot("practice-followup-streak-after-relaunch")
    }

    func testPracticeHUDSubtitleModes() {
        func assertCombinedPlaque(vertical: Bool) {
            let plaque = app.descendants(matching: .any)["practice.hudSubtitle"]
            let record = app.staticTexts["practice.bestStreak"]
            let time = app.staticTexts["practice.hudTime"]
            XCTAssertTrue(plaque.exists)
            XCTAssertTrue(plaque.frame.insetBy(dx: -1, dy: -1).contains(record.frame), "The trophy record shares the type plaque")
            XCTAssertTrue(plaque.frame.insetBy(dx: -1, dy: -1).contains(time.frame))
            if vertical {
                let rail = app.descendants(matching: .any)["header.rail"]
                let plate = app.descendants(matching: .any)["header.railPlate"]
                XCTAssertGreaterThan(plaque.frame.height, plaque.frame.width)
                XCTAssertLessThan(record.frame.midY, time.frame.midY, "The plaque reads from bottom to top")
                XCTAssertEqual(plaque.frame.midY, rail.frame.midY, accuracy: 1)
                XCTAssertGreaterThan(rail.buttons["header.dino"].frame.width, plate.frame.width,
                                     "The portrait stays larger than the compact rail")
                XCTAssertGreaterThan(plate.frame.maxX - plaque.frame.minX, 2, "The subtitle overlaps the HUD rim")
                XCTAssertLessThan(plate.frame.maxX - plaque.frame.minX, 9, "The overlap leaves the HUD contents clear")
                XCTAssertTrue(app.buttons["header.pause"].isHittable)
                XCTAssertTrue(app.buttons["question.example"].isHittable)
                XCTAssertLessThanOrEqual(plaque.frame.maxX, app.scrollViews["game.questions"].frame.minX)
            } else {
                XCTAssertEqual(plaque.frame.midX, app.frame.midX, accuracy: 1, "The whole viewport sets the center, including the portrait")
                XCTAssertGreaterThan(plaque.frame.minY, app.buttons["header.pause"].frame.midY)
                XCTAssertLessThan(plaque.frame.maxY, app.staticTexts["question.title"].frame.minY)
            }
        }

        openPractice()
        tap("practice.start")
        XCTAssertEqual(app.descendants(matching: .any)["practice.hudSubtitle"].label, "Oplopend · Hele uren")
        assertCombinedPlaque(vertical: false)
        saveScreenshot("practice-followup-ascending-subtitle")
        tap("header.pause")
        XCTAssertTrue(app.buttons["practice.start"].waitForExistence(timeout: 5))
        selectPractice("practice.order.mix")
        tap("practice.start")
        XCTAssertEqual(app.descendants(matching: .any)["practice.hudSubtitle"].label, "Mix van alle vraagtypen · Hele uren")
        assertCombinedPlaque(vertical: false)
        saveScreenshot("practice-followup-mix-subtitle")
        for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            let rotated = NSPredicate { _, _ in self.app.frame.width > self.app.frame.height }
            expectation(for: rotated, evaluatedWith: nil)
            waitForExpectations(timeout: 8)
            XCTAssertTrue(app.buttons["header.pause"].waitForExistence(timeout: 5))
            assertCombinedPlaque(vertical: app.descendants(matching: .any)["header.rail"].exists)
            saveScreenshot("practice-combined-hud-landscape-\(orientation.rawValue)")
        }
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
        if !app.descendants(matching: .any)["level.questions"].exists { tap("level.details") }
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
        if !app.descendants(matching: .any)["level.questions"].exists { tap("level.details") }
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
            XCTAssertTrue(app.staticTexts.matching(identifier: "practice.hudTime")
                .matching(NSPredicate(format: "label == %@", "Minuten")).firstMatch.exists)
            XCTAssertFalse(app.staticTexts["introduction"].exists)
            XCTAssertFalse(app.staticTexts["familiar"].exists)
            XCTAssertFalse(app.staticTexts["challenge"].exists)
            if index == 1 { XCTAssertEqual(difficulty, .familiar, "One success leaves the welcoming question behind") }
            if index == 3 { XCTAssertEqual(difficulty, .challenge, "Three successes reach the full challenge") }
            if index == 4 { XCTAssertEqual(difficulty, .familiar, "An error immediately offers a lighter question") }
            let correct = index != 3
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
            changeClockToWrongTime(.setDigital)
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

    func testClockReadingHelpIsLimitedToCurrentQuestionAndTarget() {
        onboard()
        begin(1)
        let target = app.descendants(matching: .any)["question.targetClock"]
        let initialHeight = target.frame.height
        let answerFrames = (0..<2).map { app.buttons["question.option.\($0)"].frame }
        var rng = SeededGenerator(seed: seed)
        let question = DinoQuestionGenerator.generate(level: DinoLevelCatalog.level(1)!, using: &rng)[0]
        let wrong = question.options.firstIndex { $0 != question.target }!
        saveScreenshot("clock-help-before-first-miss")
        tap("question.option.\(wrong)")
        XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
        XCTAssertGreaterThan(target.frame.height, initialHeight + 20, "Reading arrows reserve space above the digital target")
        XCTAssertEqual(target.frame.midX, app.staticTexts["question.title"].frame.midX, accuracy: 1)
        for index in 0..<2 {
            // The verdict badge extends the accessibility bounds by 5.5 points.
            // A reading-helper layout would enlarge the whole answer stone.
            let frame = app.buttons["question.option.\(index)"].frame
            XCTAssertEqual(frame.width, answerFrames[index].width, accuracy: 8,
                           "Answer stones keep their original clock width without reading helpers")
            XCTAssertEqual(frame.height, answerFrames[index].height, accuracy: 8,
                           "Answer stones keep their original clock height without reading helpers")
        }
        saveScreenshot("clock-help-after-first-miss")
        tap("question.next")
        XCTAssertTrue(app.staticTexts["2/5"].waitForExistence(timeout: 5))
        XCTAssertEqual(target.frame.height, initialHeight, accuracy: 2, "The next question starts without the previous question's helpers")
        saveScreenshot("clock-help-next-question")
        tap("header.pause")
        tap("game.exit.confirm")
        begin(1)
        XCTAssertEqual(target.frame.height, initialHeight, accuracy: 2, "A new level attempt starts without reading arrows")
    }

    func testAnalogReadingArrowsKeepTheClockLarge() {
        for (hour, minute) in [(1, 35), (12, 0), (7, 35)] {
            let family: DinoPracticeTime = minute == 0 ? .whole : .fiveMinutes
            let configuration = DinoPracticeConfiguration(time: family, order: .specific(.chooseDigital))
            var selected: (seed: UInt64, first: ClockQuestion, question: ClockQuestion)?
            for sampleSeed in UInt64(0)..<5_000 {
                var generator = DinoPracticeGenerator(configuration: configuration, seed: sampleSeed)
                let first = generator.next(index: 0)
                let question = minute == 0 ? first : generator.next(index: 1, difficultyForKind: { _ in .familiar })
                if question.target.hour % 12 == hour % 12 && question.target.minute == minute {
                    selected = (sampleSeed, first, question)
                    break
                }
            }
            guard let selected else { return XCTFail("Missing arrow-layout sample") }
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.compact-arrows.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_SEED"] = String(selected.seed)
            app.launch()
            openPractice()
            tap("practice.time.\(family.rawValue)")
            selectPractice("practice.type.chooseDigital")
            tap("practice.start")
            if minute != 0 {
                tap("question.option.\(selected.first.options.firstIndex(of: selected.first.target)!)")
                XCTAssertTrue(app.staticTexts.matching(identifier: "header.questions")
                    .matching(NSPredicate(format: "label == %@", "2")).firstMatch.waitForExistence(timeout: 8))
            }
            let clock = app.descendants(matching: .any)["question.targetClock"]
            XCTAssertEqual(clock.label, selected.question.target.digitalText)
            let originalClock = clock.frame
            let originalTitle = app.staticTexts["question.title"].frame
            let answers = selected.question.options.indices.map { app.buttons["question.option.\($0)"].frame }
            tap("question.option.\(selected.question.options.firstIndex { $0 != selected.question.target }!)")
            if app.buttons["question.showAnswer"].exists { tap("question.showAnswer") }
            XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
            saveScreenshot("compact-analog-arrows-\(hour)-\(minute)")
            let hintBounds = ClockHandHintGeometry.bounds(time: selected.question.target, shape: .circle, faceSize: 150)
            XCTAssertGreaterThan(clock.frame.height / hintBounds.height, originalClock.height * 0.75,
                                 "The clock uses spare height to retain at least three quarters of its face size")
            XCTAssertGreaterThan(clock.frame.minY, app.staticTexts["question.title"].frame.maxY)
            XCTAssertLessThanOrEqual(app.staticTexts["question.title"].frame.minY, originalTitle.minY + 2)
            let viewport = app.scrollViews["game.questions"].frame
            XCTAssertGreaterThanOrEqual(app.staticTexts["question.title"].frame.minY, viewport.minY)
            for index in selected.question.options.indices {
                let option = app.buttons["question.option.\(index)"]
                XCTAssertTrue(option.isHittable)
                XCTAssertGreaterThanOrEqual(option.frame.minY, answers[index].minY - 8)
                XCTAssertLessThanOrEqual(option.frame.maxY, viewport.maxY)
            }
        }
    }

    func testClockReadingHelpFitsEditableClocks() {
        openPractice()
        tap("practice.time.quarter")
        for kind in [DinoPracticeQuestion.setDigital, .setAnalog] {
            selectPractice("practice.type.\(kind.rawValue)")
            tap("practice.start")
            var generator = DinoPracticeGenerator(configuration: .init(time: .quarter, order: .specific(kind)), seed: seed)
            changeClockToWrongTime(kind.recipe.kind, target: generator.next(index: 0).target)
            tap("question.confirm")
            let correct = app.descendants(matching: .any)["question.correctClock"]
            XCTAssertTrue(correct.waitForExistence(timeout: 5))
            XCTAssertTrue(app.buttons["question.next"].isHittable)
            if kind == .setAnalog {
                let submitted = app.descendants(matching: .any)["question.analogControl"]
                XCTAssertEqual(submitted.frame.midY, correct.frame.midY, accuracy: 1,
                               "Compared clocks share their scale and vertical alignment")
                XCTAssertEqual(submitted.frame.width, correct.frame.width, accuracy: 1)
                XCTAssertEqual(submitted.frame.height, correct.frame.height, accuracy: 1)
                XCTAssertLessThan(submitted.frame.maxY, app.buttons["question.hand.hours"].frame.minY)
            }
            saveScreenshot("clock-help-\(kind.rawValue)-feedback")
            tap("question.next")
            XCTAssertTrue(app.buttons["question.confirm"].waitForExistence(timeout: 5))
            let control = app.descendants(matching: .any)[kind == .setDigital ? "question.digitalControl" : "question.analogControl"]
            XCTAssertTrue(control.isHittable)
            tap(kind == .setDigital ? "clock.hour.more" : "question.analog.more")
            saveScreenshot("clock-help-\(kind.rawValue)-next")
            tap("header.pause")
        }
    }

    func testFiveMinuteCircleConnectionsEnglish() {
        app.terminate()
        app.launchArguments = ["-settings.languageOverride", "en", "-AppleICUForce24HourTime", "YES"]
        app.launch()
        openPractice()
        chooseExampleTimeFamily("fiveMinutes")
        selectPractice("practice.type.spokenTime")
        tap("practice.start")
        tap("question.example")
        for minute in stride(from: 5, through: 55, by: 5) {
            tap("demo.nextExample")
            let clock = app.descendants(matching: .any)["demo.answer"]
            XCTAssertEqual(clock.value as? String, DinoTimeWords.time(.init(hour: 3, minute: minute), language: "en"))
            if minute == 5 || minute == 55 { saveScreenshot("circular-\(minute)-en") }
        }
        tap("demo.ready")
    }

    func testQuarterCircleConnectionsEnglish() {
        app.terminate()
        app.launchArguments = ["-settings.languageOverride", "en", "-AppleICUForce24HourTime", "YES"]
        app.launch()
        openPractice()
        selectPractice("practice.type.spokenTime")
        chooseExampleTimeFamily("quarter")
        tap("practice.start")
        tap("question.example")
        for minute in [15, 30, 45] {
            tap("demo.nextExample")
            let clock = app.descendants(matching: .any)["demo.answer"]
            XCTAssertEqual(clock.value as? String, DinoTimeWords.time(.init(hour: 3, minute: minute), language: "en"))
            if minute != 30 { saveScreenshot("cardinal-quarter-\(minute)-en") }
        }
        tap("demo.ready")
    }

    func testSpokenClockGuidesDutch() { checkSpokenClockGuides(language: "nl") }

    func testSpokenClockGuidesEnglish() { checkSpokenClockGuides(language: "en") }

    private func checkSpokenClockGuides(language: String) {
        app.terminate()
        app.launchArguments = ["-settings.languageOverride", language, "-AppleICUForce24HourTime", "YES"]
        app.launch()
        openPractice()
        tap("practice.time.tenMinutes")
        for type in [DinoPracticeQuestion.trueFalse, .readDigital, .spokenTime] {
            selectPractice("practice.type.\(type.rawValue)")
            tap("practice.start")
            var generator = DinoPracticeGenerator(configuration: .init(time: .tenMinutes, order: .specific(type)),
                                                   seed: seed, language: language)
            let question = generator.next(index: 0)
            let correctIndex = question.responses.firstIndex(of: question.expectedAnswer)!
            let initialCard = app.buttons["question.option.\(correctIndex)"].frame
            let initialTitle = app.staticTexts["question.title"].frame
            if type == .spokenTime {
                let time = DinoTimeWords.time(question.target, language: language)
                XCTAssertEqual(app.staticTexts["question.title"].label, language == "nl"
                               ? "Welke klok geeft deze tijd aan:\n\(time)" : "Which of the clocks shows:\n\(time)")
                saveScreenshot("spoken-\(language)-before-guide")
            }
            tap("question.option.\(question.responses.firstIndex { $0 != question.expectedAnswer }!)")
            if type == .spokenTime {
                let card = app.buttons["question.option.\(correctIndex)"].frame
                XCTAssertEqual(card.minX, initialCard.minX, accuracy: 1)
                XCTAssertEqual(card.minY, initialCard.minY, accuracy: 1)
                XCTAssertEqual(card.width, initialCard.width, accuracy: 1)
                XCTAssertEqual(card.height, initialCard.height, accuracy: 1)
                XCTAssertEqual(app.staticTexts["question.title"].frame.minY, initialTitle.minY, accuracy: 1)
                XCTAssertFalse(app.descendants(matching: .any)["question.spokenClock"].exists)
                for (index, time) in question.options.enumerated() {
                    let option = app.buttons["question.option.\(index)"]
                    XCTAssertTrue(option.exists, "Every answer clock stays on screen after a miss")
                    XCTAssertTrue((option.value as? String)?.contains(DinoTimeWords.time(time, language: language)) == true,
                                  "Each clock has a guide for its own time")
                }
                XCTAssertTrue(app.buttons["question.option.\(question.options.firstIndex(of: question.target)!)"].isEnabled,
                              "The correct clock remains selectable even with just two choices")
            } else {
                let clock = app.descendants(matching: .any)["question.targetClock"]
                XCTAssertTrue(clock.waitForExistence(timeout: 5))
                XCTAssertEqual(clock.value as? String, DinoTimeWords.time(question.target, language: language))
            }
            if type == .readDigital {
                XCTAssertEqual(app.buttons["question.option.\(question.options.firstIndex(of: question.target)!)"].value as? String,
                               language == "nl" ? "Goed" : "True", "A two-choice miss immediately marks the correct answer green")
                XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.timeReading.label.")).firstMatch.exists,
                               "The complete word ring belongs only in Example")
            }
            XCTAssertFalse(app.staticTexts["question.spokenClock.phrase"].exists)
            saveScreenshot("compact-spoken-\(language)-\(type.rawValue)-after-miss")
            tap("question.example")
            tap("demo.nextExample")
            tap("demo.nextExample")
            XCTAssertFalse(app.staticTexts["demo.spokenClock.phrase"].exists, "Examples do not repeat the time underneath the face")
            if type == .trueFalse {
                XCTAssertEqual(app.descendants(matching: .any)["demo.targetClock"].value as? String,
                               DinoTimeWords.time(.init(hour: 3, minute: 20), language: language))
            } else {
                XCTAssertTrue(app.descendants(matching: .any)["demo.timeReading.clock"].exists)
                XCTAssertEqual(app.staticTexts["demo.answer"].label,
                               DinoTimeWords.time(.init(hour: 3, minute: 20), language: language))
            }
            saveScreenshot("compact-spoken-\(language)-\(type.rawValue)-twenty")
            tap("demo.ready")
            if type == .spokenTime {
                tap("question.option.\(question.options.firstIndex(of: question.target)!)")
            } else { tap("question.next") }
            XCTAssertTrue(app.staticTexts.matching(identifier: "header.questions")
                .matching(NSPredicate(format: "label == %@", "2")).firstMatch.waitForExistence(timeout: 6),
                          "One continuation starts the next question, without another explanation screen")
            tap("header.pause")
        }
        for type in [DinoPracticeQuestion.read24Hour, .dayPart] {
            selectPractice("practice.type.\(type.rawValue)")
            tap("practice.start")
            var generator = DinoPracticeGenerator(configuration: .init(time: .tenMinutes, order: .specific(type)),
                                                   seed: seed, language: language)
            let question = generator.next(index: 0)
            let target = app.descendants(matching: .any)["question.targetClock"]
            let height = target.frame.height
            tap("question.option.\(question.responses.firstIndex { $0 != question.expectedAnswer }!)")
            XCTAssertEqual(target.frame.height, height, accuracy: 2)
            tap("header.pause")
        }
    }

    func testExampleReadingScaleAndCompletedHour() {
        openPractice()
        selectPractice("practice.type.chooseDigital")
        chooseExampleTimeFamily("quarter")
        tap("practice.start")
        func showQuarterToFive(_ screenshot: String) {
            tap("question.example")
            XCTAssertTrue(app.buttons["demo.nextExample"].waitForExistence(timeout: 5))
            let digital = app.descendants(matching: .any)["demo.digital"]
            for expected in ["03:15", "03:30", "03:45", "04:00", "04:15", "04:30", "04:45"] {
                tap("demo.nextExample")
                XCTAssertEqual(digital.label, expected)
            }
            let analog = app.descendants(matching: .any)["demo.analog"]
            XCTAssertEqual(digital.label, "04:45")
            XCTAssertEqual(analog.label, "04:45")
            XCTAssertEqual(analog.frame.midX, digital.frame.midX, accuracy: 1)
            saveScreenshot(screenshot)
            tap("demo.ready")
            XCTAssertTrue(app.staticTexts.matching(identifier: "header.questions")
                .matching(NSPredicate(format: "label == %@", "1")).firstMatch.waitForExistence(timeout: 5))
        }
        showQuarterToFive("example-reading-four-forty-five")
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
        XCTAssertLessThan(app.buttons["demo.nextExample"].frame.maxY, app.buttons["demo.ready"].frame.minY)
        XCTAssertEqual(analog.frame.midX, digital.frame.midX, accuracy: 1)
        let analogFrame = analog.frame
        let digitalFrame = digital.frame
        let nextFrame = app.buttons["demo.nextExample"].frame
        let readyFrame = app.buttons["demo.ready"].frame
        XCTAssertEqual(app.staticTexts["demo.heading"].frame.midX, app.frame.midX, accuracy: 1)
        XCTAssertFalse(app.staticTexts["1 · Uren"].exists)
        XCTAssertFalse(app.staticTexts["2 · Minuten"].exists)
        XCTAssertFalse(app.staticTexts["Deze klokken tonen dezelfde tijd. Tik om te kiezen."].exists)
        saveScreenshot("numbered-example-three")
        for hour in 4...12 {
            tap("demo.nextExample")
            let expected = String(format: "%02d:00", hour)
            XCTAssertEqual(digital.label, expected)
            for (actual, expected) in zip(
                [analog.frame.minX, analog.frame.minY, analog.frame.width, analog.frame.height],
                [analogFrame.minX, analogFrame.minY, analogFrame.width, analogFrame.height]
            ) {
                XCTAssertEqual(actual, expected, accuracy: 0.34, "All arrow directions use the same initial reservation")
            }
            XCTAssertEqual(digital.frame, digitalFrame)
            XCTAssertEqual(app.buttons["demo.nextExample"].frame, nextFrame)
            XCTAssertEqual(app.buttons["demo.ready"].frame, readyFrame)
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
        for family in [DinoPracticeTime.whole, .quarter, .fiveMinutes] {
            // Start each family directly; a swipe during the iPad sheet's return
            // transition can dismiss practice instead of scrolling its time picker.
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.time-zone-atlas.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
            app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = "timeZone"
            app.launchEnvironment["DINO_TEST_PRACTICE_TIME"] = family.rawValue
            app.launchEnvironment.removeValue(forKey: "DINO_TEST_PRACTICE_CHALLENGE")
            app.launch()
            XCTAssertTrue(app.staticTexts["question.title"].waitForExistence(timeout: 10))
            var generator = DinoPracticeGenerator(configuration: .init(time: family, order: .specific(.timeZone)), seed: seed)
            let question = generator.next(index: 0)
            let journey = question.timeZoneJourney!
            let city = journey.destination.name(language: "nl")
            let reference = DinoTimeWords.time(question.relatedTimes[0], language: "nl")
            let amount = DinoTimeWords.spokenDuration(abs(journey.offsetMinutes), language: "nl")
            let direction = journey.offsetMinutes > 0 ? "later" : "eerder"
            XCTAssertEqual(app.staticTexts["question.title"].label,
                           "Het is \(reference) in \(journey.origin.name(language: "nl")). In \(city) is het \(amount) \(direction). Hoe laat is het daar?")
            let origin = app.descendants(matching: .any)["question.timeZone.origin"]
            let destination = app.descendants(matching: .any)["question.timeZone.destination"]
            let map = app.descendants(matching: .any)["question.timeZone.map"]
            XCTAssertTrue(map.waitForExistence(timeout: 5))
            XCTAssertFalse(app.staticTexts["TIJDZONES"].exists)
            XCTAssertFalse(app.staticTexts["Vereenvoudigde tijdzones"].exists)
            XCTAssertFalse(app.staticTexts["24-uursklok"].exists)
            XCTAssertTrue(origin.label.contains("Amsterdam") && origin.label.contains(question.relatedTimes[0].digitalText))
            XCTAssertTrue(destination.label.contains(city) && destination.label.contains("?"))
            XCTAssertFalse(app.buttons["question.timeZone.replay"].exists)
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option.")).count, question.responses.count)
            XCTAssertGreaterThanOrEqual(origin.frame.minX, map.frame.minX)
            XCTAssertLessThanOrEqual(destination.frame.maxX, map.frame.maxX)
            saveScreenshot("time-zone-atlas-\(family.rawValue)-nl")
            if family == .fiveMinutes && UIDevice.current.userInterfaceIdiom == .pad {
                XCUIDevice.shared.orientation = .landscapeLeft
                RunLoop.current.run(until: Date().addingTimeInterval(0.8))
                XCTAssertTrue(map.isHittable)
                let viewport = app.scrollViews["game.questions"].frame
                XCTAssertGreaterThanOrEqual(app.staticTexts["question.title"].frame.minY, viewport.minY)
                XCTAssertLessThanOrEqual(app.buttons["question.option.\(question.responses.count - 1)"].frame.maxY, viewport.maxY)
                saveScreenshot("time-zone-atlas-worldwide-landscape")
                XCUIDevice.shared.orientation = .portrait
            }
            tap("question.example")
            XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 5))
            let example = DinoDemonstrationExamples.question(kind: .timeZone, minutes: family.minutes,
                                                             minuteStep: family.minuteStep, index: 0, previousTarget: nil)
            waitForTimeZoneWalk(example)
            assertTimeZoneReplay(example, prefix: "demo")
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
            if question.responses.count > 2 {
                XCTAssertTrue(destination.label.contains("?"), "An open retry does not reveal the time")
                XCTAssertFalse(app.buttons["question.timeZone.replay"].exists,
                               "The animation stays hidden until the right answer follows")
                tap("question.showAnswer")
            }
            let walked = question.timeZoneJourney!.steps(from: question.relatedTimes[0])
            waitUntilLabel("question.timeZone.targetTime", equals: question.target.digitalText, timeout: timeWalkTimeout(walked.count))
            XCTAssertTrue(destination.label.contains(question.target.digitalText), "Revealing the answer animates the map card")
            assertTimeZoneReplay(question, prefix: "question")
            saveScreenshot("time-zone-in-card-answer-\(family.rawValue)")
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
        let journey = question.timeZoneJourney!
        let reference = DinoTimeWords.time(question.relatedTimes[0], language: "en")
        let amount = DinoTimeWords.spokenDuration(abs(journey.offsetMinutes), language: "en")
        let destination = journey.destination.name(language: "en")
        let direction = journey.offsetMinutes > 0 ? "ahead" : "behind"
        XCTAssertEqual(app.staticTexts["question.title"].label,
                       "It is \(reference) in \(journey.origin.name(language: "en")). \(destination) is \(amount) \(direction). What time is it there?")
        XCTAssertFalse(app.staticTexts["TIME ZONES"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["question.timeZone.origin"].label.contains("London"))
        XCTAssertTrue(app.descendants(matching: .any)["question.timeZone.destination"].label.contains("?"))
        saveScreenshot("time-zone-atlas-whole-en")
        tap("question.example")
        let example = DinoDemonstrationExamples.question(kind: .timeZone, minutes: [0], minuteStep: 60,
                                                         index: 0, previousTarget: nil, language: "en")
        waitForTimeZoneWalk(example, language: "en")
        XCTAssertEqual(app.buttons["demo.timeZone.replay"].label, "Replay the time change")
        assertTimeZoneReplay(example, prefix: "demo", language: "en")
        saveScreenshot("time-zone-in-card-example-en")
    }

    func testTimeZoneCardReplayInBothLanguages() {
        let configuration = DinoPracticeConfiguration(time: .minutes, order: .specific(.timeZone))
        for language in ["nl", "en"] {
            var generator = DinoPracticeGenerator(configuration: configuration, seed: seed, language: language)
            let question = generator.next(index: 3, difficultyForKind: { _ in .challenge })
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.time-zone-card.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
            app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = "timeZone"
            app.launchEnvironment["DINO_TEST_PRACTICE_CHALLENGE"] = "1"
            app.launchArguments = ["-settings.languageOverride", language, "-AppleICUForce24HourTime", "YES"]
            app.launch()
            XCTAssertTrue(app.buttons["question.option.0"].waitForExistence(timeout: 8))
            XCTAssertEqual(app.descendants(matching: .any)["question.timeZone.targetTime"].label, "?")
            XCTAssertFalse(app.buttons["question.timeZone.replay"].exists)
            tap("question.example")
            let example = DinoDemonstrationExamples.question(kind: .timeZone, minutes: configuration.time.minutes,
                                                             minuteStep: configuration.time.minuteStep,
                                                             index: 0, previousTarget: nil, language: language)
            waitForTimeZoneWalk(example, language: language)
            assertTimeZoneReplay(example, prefix: "demo", language: language)
            saveScreenshot("time-zone-in-card-example-\(language)")
            tap("demo.ready")
            XCTAssertEqual(app.descendants(matching: .any)["question.timeZone.targetTime"].label, "?")
            tap("question.option.\(question.responses.firstIndex { $0 != question.expectedAnswer }!)")
            if question.responses.count > 2 {
                XCTAssertEqual(app.descendants(matching: .any)["question.timeZone.targetTime"].label, "?")
                tap("question.showAnswer")
            }
            waitUntilLabel("question.timeZone.targetTime", equals: question.target.digitalText, timeout: 16)
            assertTimeZoneReplay(question, prefix: "question", language: language)
            if UIDevice.current.userInterfaceIdiom == .pad {
                XCUIDevice.shared.orientation = .landscapeLeft
                XCTAssertTrue(app.buttons["question.timeZone.replay"].waitForExistence(timeout: 4))
                let viewport = app.scrollViews["game.questions"].frame
                XCTAssertLessThanOrEqual(app.buttons["question.option.\(question.responses.count - 1)"].frame.maxY, viewport.maxY)
            }
            saveScreenshot("time-zone-in-card-answer-\(language)")
            XCUIDevice.shared.orientation = .portrait
        }
    }

    func testHalfHourTimeZonePreservesMapAndWorkedAnswer() {
        openPractice()
        tap("practice.time.fiveMinutes")
        selectPractice("practice.type.timeZone")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .fiveMinutes, order: .specific(.timeZone)), seed: seed)
        var progress = DinoLearningProgress()
        for index in 0..<16 {
            let difficulty = progress.difficulty
            let question = generator.next(index: index, difficultyForKind: { _ in difficulty })
            let counter = app.staticTexts.matching(identifier: "header.questions")
                .matching(NSPredicate(format: "label == %@", String(index + 1))).firstMatch
            XCTAssertTrue(counter.waitForExistence(timeout: 6))
            if !question.offsetMinutes.isMultiple(of: 60) {
                let destination = app.descendants(matching: .any)["question.timeZone.destination"]
                XCTAssertTrue(destination.label.contains("New Delhi"))
                XCTAssertTrue(destination.label.contains("½ uur later"))
                XCTAssertTrue(app.staticTexts["question.title"].label.contains(DinoTimeWords.spokenDuration(question.offsetMinutes, language: "nl")))
                let wrong = question.responses.firstIndex { $0 != question.expectedAnswer }!
                tap("question.option.\(wrong)")
                tap("question.showAnswer")
                waitUntilLabel("question.timeZone.targetTime", equals: question.target.digitalText, timeout: 12)
                XCTAssertEqual(app.descendants(matching: .any)["question.timeZone.difference"].label,
                               timeZoneDifference(question.offsetMinutes))
                XCTAssertTrue(destination.label.contains(question.target.digitalText))
                saveScreenshot("time-zone-half-hour-worked-answer")
                return
            }
            tap("question.option.\(question.responses.firstIndex(of: question.expectedAnswer)!)")
            progress.record(correct: true, at: difficulty)
        }
        XCTFail("The varied destination selection must reach a half-hour zone within this short session")
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

    func testFlightTotalHintAndReplayInBothLanguages() {
        let configuration = DinoPracticeConfiguration(time: .minutes, order: .specific(.flightArrival))
        for language in ["nl", "en"] {
            var selected: (seed: UInt64, question: ClockQuestion)?
            for sampleSeed in UInt64(0)..<500 {
                var generator = DinoPracticeGenerator(configuration: configuration, seed: sampleSeed, language: language)
                let question = generator.next(index: 3, difficultyForKind: { _ in .challenge })
                let shift = question.durationMinutes + question.offsetMinutes
                if question.offsetMinutes < 0 && (120...180).contains(shift) && shift % 60 > 30 && question.relatedTimes[0].minute != 0 {
                    selected = (sampleSeed, question)
                    break
                }
            }
            guard let selected else { XCTFail("A flight must bridge a departure with minutes to a whole hour"); return }
            let question = selected.question
            let start = question.relatedTimes[0]
            let shift = question.durationMinutes + question.offsetMinutes
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.flight-hint.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
            app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = "flightArrival"
            app.launchEnvironment["DINO_TEST_PRACTICE_CHALLENGE"] = "1"
            app.launchEnvironment["DINO_TEST_SEED"] = String(selected.seed)
            app.launchArguments = ["-settings.languageOverride", language, "-AppleICUForce24HourTime", "YES"]
            app.launch()
            XCTAssertTrue(app.buttons["question.option.0"].waitForExistence(timeout: 8))
            let total = app.descendants(matching: .any)["question.flight.total"]
            let unknown = app.descendants(matching: .any)["question.flight.unknown"]
            let replay = app.buttons["question.flight.replay"]
            XCTAssertTrue(unknown.exists)
            XCTAssertFalse(total.exists)
            XCTAssertFalse(replay.exists)
            let ticket = app.descendants(matching: .any)["question.flight.ticket"]
            let compactHeight = ticket.frame.height
            saveScreenshot("flight-compact-before-miss-\(language)")
            tap("question.option.\(question.responses.firstIndex { $0 != question.expectedAnswer }!)")
            XCTAssertTrue(total.waitForExistence(timeout: 5))
            XCTAssertGreaterThan(ticket.frame.height, compactHeight + 24,
                                 "The total gets its space only after the first wrong answer")
            XCTAssertTrue(total.label.contains(DinoTimeWords.duration(shift, language: language)))
            XCTAssertTrue(unknown.exists, "The first miss reveals the total but keeps the arrival hidden")
            XCTAssertFalse(app.descendants(matching: .any)["question.flight.arrival"].exists)
            XCTAssertFalse(replay.exists)
            XCTAssertTrue(app.buttons["question.showAnswer"].exists)
            XCTAssertLessThanOrEqual(app.buttons["question.option.3"].frame.maxY,
                                     app.scrollViews["game.questions"].frame.maxY + 1,
                                     "The expanded hint keeps the answer choices above the action button")
            saveScreenshot("flight-total-first-miss-\(language)")

            tap("question.example")
            XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 5))
            let exampleReplay = app.buttons["demo.flight.replay"]
            XCTAssertTrue(exampleReplay.exists)
            XCTAssertTrue(app.descendants(matching: .any)["demo.flight.sameZone"].exists)
            XCTAssertFalse(app.descendants(matching: .any)["demo.flight.total"].exists,
                           "A same-zone example needs only the flight duration")
            let exampleDeparture = app.descendants(matching: .any)["demo.targetClock"].label
            exampleReplay.tap()
            XCTAssertEqual(app.descendants(matching: .any)["demo.targetClock"].label, exampleDeparture,
                           "Replay preserves the given departure while the arrival counts up again")
            tap("demo.ready")
            XCTAssertTrue(total.waitForExistence(timeout: 5), "The total hint survives opening an example")
            XCTAssertTrue(unknown.exists)

            tap("question.showAnswer")
            let steps = DinoTimeZoneStep.steps(from: start, offsetMinutes: shift)
            waitUntilLabel("question.flight.arrival", equals: question.target.digitalText, timeout: timeWalkTimeout(steps.count))
            assertFlightChoicesVisible()
            let difference = "+" + DinoTimeWords.duration(shift, language: language)
            XCTAssertEqual(app.descendants(matching: .any)["question.flight.difference"].label, difference)
            XCTAssertTrue(replay.exists && replay.isEnabled)
            XCTAssertTrue(app.descendants(matching: .any)["question.flight.ticket"].frame.contains(replay.frame))
            let optionFrame = app.buttons["question.option.0"].frame
            let totalLabel = total.label
            replay.tap()
            XCTAssertEqual(app.descendants(matching: .any)["question.flight.arrival"].label, start.digitalText)
            XCTAssertEqual(total.label, totalLabel, "Replay preserves the finished total hint")
            replay.tap()
            waitUntilLabel("question.flight.arrival", equals: question.target.digitalText, timeout: timeWalkTimeout(steps.count))
            assertFlightChoicesVisible()
            XCTAssertEqual(app.buttons["question.option.0"].frame.midY, optionFrame.midY, accuracy: 1)
            XCTAssertTrue(app.buttons["question.next"].exists)
            RunLoop.current.run(until: Date().addingTimeInterval(0.4))
            saveScreenshot("flight-logical-route-replay-\(language)")
            tap("question.next")
            XCTAssertTrue(unknown.waitForExistence(timeout: 5))
            XCTAssertFalse(total.exists, "A new question hides the hint again")
            XCTAssertFalse(replay.exists)
        }
    }

    func testFlightHalfHoursWorkedAnswerKeepsAllChoicesVisible() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.flight-half-hour-fit.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launchArguments = ["-settings.languageOverride", "en", "-AppleICUForce24HourTime", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["header.practice"].waitForExistence(timeout: 10))
        waitForMapOpeningToFinish()
        tap("header.practice")
        XCTAssertTrue(app.buttons["practice.start"].waitForExistence(timeout: 5))
        tap("practice.time.half")
        selectPractice("practice.type.flightArrival")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .half, order: .specific(.flightArrival)), seed: seed,
                                              language: "en")
        var progress = DinoLearningProgress()
        for index in 0..<3 {
            let difficulty = progress.difficulty
            let question = generator.next(index: index, difficultyForKind: { _ in difficulty })
            let number = app.staticTexts.matching(identifier: "header.questions")
                .matching(NSPredicate(format: "label == %@", String(index + 1))).firstMatch
            XCTAssertTrue(number.waitForExistence(timeout: 8))
            if index < 2 {
                tap("question.option.\(question.responses.firstIndex(of: question.expectedAnswer)!)")
                progress.record(correct: true, at: difficulty)
                continue
            }
            XCTAssertEqual(question.responses.count, 4)
            let wrong = question.responses.indices.filter { question.responses[$0] != question.expectedAnswer }
            for option in wrong.prefix(2) { tap("question.option.\(option)") }
            if app.buttons["question.showAnswer"].exists { tap("question.showAnswer") }
            XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 6))
            let work = DinoFlightArrivalWork(departure: question.relatedTimes[0], durationMinutes: question.durationMinutes,
                                             offsetMinutes: question.offsetMinutes, arrival: question.target)
            waitUntilLabel("question.flight.arrival", equals: question.target.digitalText,
                           timeout: timeWalkTimeout(work.walkMinutes().count))
            assertFlightChoicesVisible()
            RunLoop.current.run(until: Date().addingTimeInterval(0.8))
            saveScreenshot("flight-half-hours-compact-worked-en")
        }
    }

    func testFlightSameZoneDoesNotShowTotal() {
        let configuration = DinoPracticeConfiguration(time: .minutes, order: .specific(.flightArrival))
        for language in ["nl", "en"] {
            var generator = DinoPracticeGenerator(configuration: configuration, seed: seed, language: language)
            let question = generator.next(index: 0)
            XCTAssertEqual(question.offsetMinutes, 0)
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.flight-same-zone.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
            app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = "flightArrival"
            app.launchEnvironment.removeValue(forKey: "DINO_TEST_PRACTICE_CHALLENGE")
            app.launchEnvironment["DINO_TEST_SEED"] = String(seed)
            app.launchArguments = ["-settings.languageOverride", language, "-AppleICUForce24HourTime", "YES"]
            app.launch()
            XCTAssertTrue(app.buttons["question.option.0"].waitForExistence(timeout: 8))
            let ticket = app.descendants(matching: .any)["question.flight.ticket"]
            let total = app.descendants(matching: .any)["question.flight.total"]
            let height = ticket.frame.height
            XCTAssertTrue(app.descendants(matching: .any)["question.flight.sameZone"].exists)
            XCTAssertFalse(total.exists)
            tap("question.option.\(question.responses.firstIndex { $0 != question.expectedAnswer }!)")
            XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
            waitUntilLabel("question.flight.arrival", equals: question.target.digitalText, timeout: 8)
            XCTAssertFalse(total.exists, "A same-zone flight stays without a total after a wrong answer")
            XCTAssertEqual(ticket.frame.height, height, accuracy: 1, "A same-zone flight keeps its compact height")
            let replay = app.buttons["question.flight.replay"]
            XCTAssertTrue(replay.exists)
            replay.tap()
            waitUntilLabel("question.flight.arrival", equals: question.target.digitalText, timeout: 8)
            XCTAssertFalse(total.exists, "Replay does not introduce a redundant total")
            RunLoop.current.run(until: Date().addingTimeInterval(0.4))
            saveScreenshot("flight-same-zone-without-total-\(language)")
        }
    }

    func testDayScheduleHasTwoActivitiesAndBreak() {
        openPractice()
        tap("practice.time.quarter")
        selectPractice("practice.type.daySchedule")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .quarter, order: .specific(.daySchedule)), seed: seed)
        let introduction = generator.next(index: 0)
        tap("question.option.\(introduction.responses.firstIndex(of: introduction.expectedAnswer)!)")
        let question = generator.next(index: 1, difficultyForKind: { _ in .familiar })
        let schedule = question.daySchedule!
        func element(_ id: String) -> XCUIElement {
            app.descendants(matching: .any).matching(identifier: id).firstMatch
        }
        for (suffix, minutes) in [("activity.1", schedule.firstMinutes), ("break", schedule.breakMinutes), ("activity.2", schedule.secondMinutes)] {
            XCTAssertTrue(element("question.schedule.\(suffix)").waitForExistence(timeout: 5))
            XCTAssertTrue(element("question.schedule.\(suffix)").label.contains(DinoTimeWords.duration(minutes, language: "nl")))
        }
        XCTAssertTrue(element("question.schedule.start").label.contains(schedule.start.digitalText))
        XCTAssertTrue(element("question.schedule.finish").label.contains("?"), "The end time is the question")
        XCTAssertFalse(element("question.schedule.total").exists)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option.")).count, 4)
        saveScreenshot("day-schedule-question")

        tap("question.example")
        XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 5))
        let example = DinoDemonstrationExamples.question(kind: .daySchedule, minutes: [15, 45], minuteStep: 15, index: 0, previousTarget: nil)
        waitUntilLabel("demo.answer", equals: example.target.digitalText, timeout: 8)
        XCTAssertEqual(element("demo.schedule.added").label, "+1 uur 00 min")
        XCTAssertTrue(element("demo.schedule.total").label.contains(example.daySchedule!.summedDurationText(language: "nl")))
        XCTAssertTrue(element("demo.schedule.total").label.contains(DinoTimeWords.digitalDuration(example.daySchedule!.totalMinutes)))
        XCTAssertTrue(element("demo.schedule.group").frame.contains(element("demo.schedule.total").frame))
        for suffix in ["activity.1", "break", "activity.2"] { XCTAssertTrue(element("demo.schedule.\(suffix)").exists) }
        saveScreenshot("day-schedule-example")
        tap("demo.nextExample")
        let next = DinoDemonstrationExamples.question(kind: .daySchedule, minutes: [15, 45], minuteStep: 15, index: 1, previousTarget: example.target)
        waitUntilLabel("demo.answer", equals: next.target.digitalText, timeout: 8)
        tap("demo.ready")
        XCTAssertTrue(element("question.schedule.start").label.contains(schedule.start.digitalText), "Help preserves the live question")
        XCTAssertTrue(app.staticTexts.matching(identifier: "header.questions")
            .matching(NSPredicate(format: "label == %@", "2")).firstMatch.waitForExistence(timeout: 5))

        let wrongIndex = question.options.firstIndex { $0 != question.target }!
        tap("question.option.\(wrongIndex)")
        XCTAssertTrue(element("question.schedule.finish").label.contains("?"), "A retry keeps the end time hidden")
        XCTAssertTrue(element("question.schedule.total").waitForExistence(timeout: 5))
        XCTAssertTrue(element("question.schedule.total").label.contains(schedule.summedDurationText(language: "nl")))
        XCTAssertTrue(element("question.schedule.total").label.contains(DinoTimeWords.digitalDuration(schedule.totalMinutes)))
        for (suffix, minutes) in [("activity.1", schedule.firstMinutes), ("break", schedule.breakMinutes), ("activity.2", schedule.secondMinutes)] {
            XCTAssertTrue(element("question.schedule.\(suffix)").label.contains(DinoTimeWords.compactDuration(
                hours: minutes / 60, minutes: minutes % 60, language: "nl", padMinutes: schedule.hasMinuteTerms)))
            XCTAssertTrue(element("question.schedule.\(suffix)").label.contains(DinoTimeWords.digitalDuration(minutes)))
            XCTAssertEqual(element("question.schedule.\(suffix)").frame.minX,
                           element("question.schedule.start").frame.minX, accuracy: 1,
                           "Departure and journey icons share the same left column")
        }
        XCTAssertTrue(element("question.schedule.group").frame.contains(element("question.schedule.total").frame))
        saveScreenshot("day-schedule-total-inside-group")
        tap("question.showAnswer")
        waitUntilLabel("question.schedule.finish", equals: schedule.end.digitalText, timeout: 8)
        saveScreenshot("day-schedule-answer")
        tap("question.next")
        XCTAssertTrue(app.staticTexts.matching(identifier: "header.questions")
            .matching(NSPredicate(format: "label == %@", "3")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(element("question.schedule.finish").label.contains("?"))
        XCTAssertFalse(element("question.schedule.total").exists)
    }

    func testTrainDurationCarryInBothLanguages() {
        let configuration = DinoPracticeConfiguration(time: .minutes, order: .specific(.daySchedule))
        for language in ["nl", "en"] {
            var selected: (seed: UInt64, question: ClockQuestion)?
            for sampleSeed in UInt64(0)..<10000 {
                var generator = DinoPracticeGenerator(configuration: configuration, seed: sampleSeed, language: language)
                let question = generator.next(index: 3, difficultyForKind: { _ in .challenge })
                let schedule = question.daySchedule!
                if (schedule.firstMinutes.isMultiple(of: 60) || schedule.secondMinutes.isMultiple(of: 60)) &&
                    schedule.hasMinuteTerms && schedule.totalMinutes.isMultiple(of: 60) {
                    selected = (sampleSeed, question)
                    break
                }
            }
            guard let selected, let schedule = selected.question.daySchedule else {
                XCTFail("A train example must carry the written minutes into an hour")
                return
            }
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.train-carry.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
            app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = "daySchedule"
            app.launchEnvironment["DINO_TEST_PRACTICE_CHALLENGE"] = "1"
            app.launchEnvironment["DINO_TEST_SEED"] = String(selected.seed)
            app.launchArguments = ["-settings.languageOverride", language, "-AppleICUForce24HourTime", "YES"]
            app.launch()
            XCTAssertTrue(app.buttons["question.option.0"].waitForExistence(timeout: 8))
            XCTAssertFalse(app.buttons["question.schedule.replay"].exists)
            saveScreenshot("train-duration-values-before-\(language)")
            let wrong = selected.question.responses.firstIndex { $0 != selected.question.expectedAnswer }!
            tap("question.option.\(wrong)")
            let total = app.descendants(matching: .any)["question.schedule.total"]
            XCTAssertTrue(total.waitForExistence(timeout: 5))
            XCTAssertTrue(total.label.contains(schedule.summedDurationText(language: language)))
            XCTAssertTrue(total.label.contains(DinoTimeWords.digitalDuration(schedule.totalMinutes)))
            for (index, suffix) in ["activity.1", "break", "activity.2"].enumerated() {
                let row = app.descendants(matching: .any)["question.schedule.\(suffix)"]
                XCTAssertTrue(row.label.contains(DinoTimeWords.compactDuration(hours: schedule.durations[index] / 60,
                    minutes: schedule.durations[index] % 60, language: language, padMinutes: schedule.hasMinuteTerms)))
                XCTAssertTrue(row.label.contains(DinoTimeWords.digitalDuration(schedule.durations[index])))
            }
            XCTAssertFalse(app.buttons["question.schedule.replay"].exists, "The retry keeps the arrival hidden")
            tap("question.showAnswer")
            waitUntilLabel("question.schedule.finish", equals: schedule.end.digitalText, timeout: 8)
            let difference = "+" + DinoTimeWords.compactDuration(hours: schedule.totalMinutes / 60,
                minutes: schedule.totalMinutes % 60, language: language, padMinutes: schedule.hasMinuteTerms)
            XCTAssertEqual(app.descendants(matching: .any)["question.schedule.added"].label, difference)
            let replay = app.buttons["question.schedule.replay"]
            XCTAssertTrue(replay.exists && replay.isEnabled)
            let arrival = app.descendants(matching: .any)["question.schedule.arrival"]
            XCTAssertTrue(arrival.frame.contains(replay.frame))
            let optionFrame = app.buttons["question.option.0"].frame
            replay.tap()
            XCTAssertEqual(app.descendants(matching: .any)["question.schedule.finish"].label, schedule.start.digitalText)
            XCTAssertEqual(app.descendants(matching: .any)["question.schedule.added"].label,
                           language == "nl" ? "+0 uur 00 min" : "+0h 00 min")
            saveScreenshot("train-replay-zero-units-\(language)")
            replay.tap()
            waitUntilLabel("question.schedule.finish", equals: schedule.end.digitalText, timeout: 8)
            XCTAssertEqual(app.descendants(matching: .any)["question.schedule.added"].label, difference)
            XCTAssertEqual(app.buttons["question.option.0"].frame.midY, optionFrame.midY, accuracy: 1)
            // Save the settled digits rather than a frame in their final numeric transition.
            RunLoop.current.run(until: Date().addingTimeInterval(0.45))
            saveScreenshot("train-duration-carry-\(language)")
        }
    }

    func testExpandedMultipleChoiceExamplesShowOneAnswer() {
        openPractice()
        tap("practice.time.half")
        let types = DinoPracticeQuestion.allCases.filter {
            $0.recipe.kind.isExpanded && $0.recipe.kind.usesOptions && $0 != .trueFalse
        }
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
                waitUntilLabel("demo.timeZone.targetTime", equals: example.target.digitalText, timeout: 8)
            }
            let answers = app.descendants(matching: .any).matching(identifier: type == .timeZone ? "demo.timeZone.targetTime" : "demo.answer")
            XCTAssertEqual(answers.count, 1, "\(type) shows one worked answer")
            XCTAssertFalse(answers.firstMatch.label.isEmpty)
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option.")).count, 0,
                           "\(type) has no distractors in its example")
            XCTAssertFalse(app.staticTexts["demo.explanation"].exists)
            if [.timeSequence, .addTime, .subtractTime].contains(type) {
                saveScreenshot("example-layout-\(type.rawValue)")
            }
            if type == .spokenTime {
                XCTAssertEqual(answers.firstMatch.label, "half vier")
                saveScreenshot("simple-spoken-time-example")
                tap("demo.nextExample")
                XCTAssertEqual(answers.firstMatch.label, "half vijf")
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

    private func timeWalkTimeout(_ stepCount: Int) -> TimeInterval { Double(stepCount) * 2 + 6 }

    private func assertFlightChoicesVisible() {
        let viewport = app.scrollViews["game.questions"].frame
        for index in 0..<4 {
            let option = app.buttons["question.option.\(index)"]
            XCTAssertTrue(option.exists)
            XCTAssertGreaterThanOrEqual(option.frame.minY, viewport.minY - 1)
            XCTAssertLessThanOrEqual(option.frame.maxY, viewport.maxY + 1,
                                     "Every answer stays fully above the action button after the flight explanation opens")
        }
    }

    private func waitUntilLabel(_ identifier: String, equals expected: String, timeout: TimeInterval) {
        let element = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        // Re-resolve a clock that replaces its question mark with animated digits.
        let predicate = NSPredicate { _, _ in
            let current = self.app.descendants(matching: .any).matching(identifier: identifier).firstMatch
            return current.exists && current.label == expected
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        if result != .completed { saveScreenshot("unexpected-label-\(identifier)") }
        XCTAssertEqual(result, .completed,
                       "Expected \(identifier) to read \(expected), found \(element.exists ? element.label : "missing")")
    }

    private func timeZoneDifference(_ offset: Int, language: String = "nl", later: Bool? = nil) -> String {
        let direction = (later ?? (offset > 0)) ? "later" : (language == "nl" ? "eerder" : "earlier")
        return "\(DinoTimeWords.zoneHours(offset)) \(language == "nl" ? "uur" : "h") \(direction)"
    }

    private func waitForTimeZoneWalk(_ question: ClockQuestion, language: String = "nl") {
        let steps = question.timeZoneJourney!.steps(from: question.relatedTimes[0])
        waitUntilLabel("demo.timeZone.targetTime", equals: question.target.digitalText, timeout: timeWalkTimeout(steps.count))
        XCTAssertEqual(app.descendants(matching: .any)["demo.timeZone.referenceTime"].label, question.relatedTimes[0].digitalText)
        XCTAssertEqual(app.descendants(matching: .any)["demo.timeZone.difference"].label, timeZoneDifference(question.offsetMinutes, language: language))
        XCTAssertTrue(app.descendants(matching: .any)["demo.timeZone.destination"].label.contains(question.target.digitalText))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "demo.timeZone.targetTime").count, 1,
                       "One destination clock updates inside the map")
        XCTAssertFalse(app.descendants(matching: .any)["demo.timeZone.steps"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["demo.answer"].exists)
    }

    private func assertTimeZoneReplay(_ question: ClockQuestion, prefix: String, language: String = "nl") {
        let destination = app.descendants(matching: .any)["\(prefix).timeZone.destination"]
        let button = app.buttons["\(prefix).timeZone.replay"]
        XCTAssertTrue(button.exists && button.isEnabled, button.debugDescription)
        let map = app.descendants(matching: .any)["\(prefix).timeZone.map"].frame
        let journey = question.timeZoneJourney!
        let point = DinoTimeZoneViewport(journey: journey, size: map.size).point(journey.destination, size: map.size)
        XCTAssertEqual(button.frame.midX, map.minX + point.x, accuracy: 1, "Replay replaces the selected capital's map pin")
        XCTAssertEqual(button.frame.midY, map.minY + point.y, accuracy: 1)
        XCTAssertEqual(app.staticTexts["\(prefix).timeZone.destinationName"].frame.midX, destination.frame.midX, accuracy: 1,
                       "The city name stays centered when replay is available")
        // Positioned map elements may lack an AX activation point; tap the visible marker's center.
        button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertEqual(app.descendants(matching: .any)["\(prefix).timeZone.targetTime"].label, question.relatedTimes[0].digitalText)
        XCTAssertEqual(app.descendants(matching: .any)["\(prefix).timeZone.difference"].label,
                       timeZoneDifference(0, language: language, later: question.offsetMinutes > 0))
        // Restart again during the opening pause: only the latest run may update the card.
        button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let steps = question.timeZoneJourney!.steps(from: question.relatedTimes[0])
        waitUntilLabel("\(prefix).timeZone.targetTime", equals: question.target.digitalText, timeout: timeWalkTimeout(steps.count))
        XCTAssertEqual(app.descendants(matching: .any)["\(prefix).timeZone.difference"].label,
                       timeZoneDifference(question.offsetMinutes, language: language))
        XCTAssertEqual(app.descendants(matching: .any)["\(prefix).timeZone.referenceTime"].label, question.relatedTimes[0].digitalText)
        XCTAssertFalse(app.descendants(matching: .any)["\(prefix).timeZone.steps"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["\(prefix).timeZone.result"].exists)
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
        XCTAssertFalse(app.buttons["demo.confirm"].exists)
        XCTAssertTrue(app.buttons["demo.ready"].isHittable)
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
        XCTAssertTrue(app.buttons["demo.ready"].isHittable)
        XCTAssertFalse(app.buttons["demo.confirm"].exists)
        waitUntilLabel("demo.analog", equals: "03:00", timeout: 20)
        XCTAssertLessThan(app.buttons["demo.nextExample"].frame.maxY, app.buttons["demo.ready"].frame.minY)
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
        let initialTime = DinoDemonstrationExamples.time(index: 0, minutes: DinoPracticeTime.half.minutes)
        XCTAssertEqual(digital.label, initialTime.digitalText)
        XCTAssertTrue(app.buttons["demo.hand.minutes"].exists)
        XCTAssertLessThan(digital.frame.maxY, analog.frame.minY)
        XCTAssertLessThan(analog.frame.maxY, app.buttons["demo.hand.minutes"].frame.minY)
        XCTAssertTrue(app.buttons["demo.ready"].isHittable)
        XCTAssertFalse(app.buttons["demo.confirm"].exists)
        waitUntilLabel("demo.analog", equals: initialTime.digitalText, timeout: 20)
        XCTAssertEqual(digital.label, initialTime.digitalText)
        saveScreenshot("analog-setting-example-completed-minutes")
        tap("demo.nextExample")
        XCTAssertEqual(digital.label, DinoDemonstrationExamples.time(index: 1, minutes: DinoPracticeTime.half.minutes).digitalText)
        saveScreenshot("analog-setting-example-opposite-minutes")
        tap("demo.ready")
    }

    func testAdvanceAnalogPlacesTheStartClockAboveTheClockYouTurn() {
        openPractice()
        tap("practice.time.fiveMinutes")
        selectPractice("practice.type.advanceAnalog")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .fiveMinutes, order: .specific(.advanceAnalog)), seed: seed)
        let question = generator.next(index: 0)
        let duration = "+\(DinoTimeWords.duration(question.durationMinutes, language: "nl"))"
        XCTAssertEqual(app.staticTexts["question.title"].label,
                       "Zet de wijzers \(DinoTimeWords.spokenDuration(question.durationMinutes, language: "nl")) vooruit.")
        XCTAssertFalse(app.staticTexts["Begintijd"].exists)
        let start = app.descendants(matching: .any)["question.startClock"]
        let difference = app.descendants(matching: .any)["question.advance.difference"]
        let control = app.descendants(matching: .any)["question.analogControl"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertEqual(difference.label, duration)
        XCTAssertLessThan(start.frame.maxY, difference.frame.minY)
        if app.frame.width >= 664 {
            XCTAssertLessThan(start.frame.maxX, control.frame.minX)
            XCTAssertEqual(start.frame.midY, control.frame.midY, accuracy: 1)
            XCTAssertEqual(start.frame.width, control.frame.width - 20, accuracy: 1)
        } else {
            XCTAssertLessThan(difference.frame.maxY, control.frame.minY)
            XCTAssertEqual(start.frame.midX, control.frame.midX, accuracy: 8)
            XCTAssertEqual(start.frame.width * 2, control.frame.width - 8, accuracy: 1,
                           "The start clock is half the clock the player turns")
        }
        tap("question.example")
        let example = DinoDemonstrationExamples.question(kind: .advanceAnalog, minutes: DinoPracticeTime.fiveMinutes.minutes,
                                                         minuteStep: 5, index: 0, previousTarget: nil)
        let demoStart = app.descendants(matching: .any)["demo.startClock"]
        let demoClock = app.descendants(matching: .any)["demo.analog"]
        let demoDifference = app.descendants(matching: .any)["demo.advance.difference"]
        XCTAssertTrue(demoClock.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["demo.title"].label,
                       "Zet de wijzers \(DinoTimeWords.spokenDuration(example.durationMinutes, language: "nl")) vooruit.")
        XCTAssertEqual(demoDifference.label, "+\(DinoTimeWords.duration(example.durationMinutes, language: "nl"))")
        XCTAssertLessThan(demoStart.frame.maxY, demoDifference.frame.minY)
        XCTAssertLessThan(demoDifference.frame.maxY, demoClock.frame.minY)
        XCTAssertEqual(demoStart.frame.midX, demoClock.frame.midX, accuracy: 8)
        // The example's confirmation can add its four-point outline to the accessible frame.
        XCTAssertEqual(demoStart.frame.width * 2, demoClock.frame.width - 8, accuracy: 5)
        XCTAssertTrue(app.buttons["demo.ready"].waitForExistence(timeout: 25))
        saveScreenshot("advance-analog-start-above")
        tap("demo.nextExample")
        tap("demo.analog.less")
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))
        tap("demo.ready")
        XCTAssertTrue(control.exists)
        changeClockToWrongTime(.advanceAnalog, target: question.target)
        tap("question.confirm")
        XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["question.correctClock"].exists)
        XCTAssertEqual(difference.label, duration, "The assigned duration remains visible after answering")
        if app.frame.width < 664 {
            XCTAssertTrue(app.descendants(matching: .any)["question.advance.entered"].exists)
        }
        saveScreenshot("advance-analog-duration-after-answer")
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
            changeClockToWrongTime(question.kind, target: question.target)
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
                           type == .spokenTime ? "Welke klok geeft deze tijd aan:\n\(words)" : "De klok geeft \(words) aan. Klopt dat?")
            XCTAssertFalse(app.staticTexts[words].exists, "The time appears in the title once")
            saveScreenshot("question-title-\(type.rawValue)")
            tap("question.example")
            let example = DinoDemonstrationExamples.question(kind: type.recipe.kind, minutes: [0], minuteStep: 60,
                                                            index: 0, previousTarget: nil)
            let exampleWords = DinoTimeWords.time(example.statement ?? example.target, language: "nl")
            XCTAssertEqual(app.staticTexts["demo.title"].label,
                           type == .spokenTime ? "Welke klok geeft deze tijd aan:\n\(exampleWords)" : "De klok geeft \(exampleWords) aan. Klopt dat?")
            saveScreenshot("question-title-example-\(type.rawValue)")
            tap("demo.ready")
            if type == .trueFalse {
                XCTAssertEqual(Set((0..<2).map { app.buttons["question.option.\($0)"].label }), Set(["Goed", "Fout"]))
            }
            tap("header.pause")
        }
    }

    func testTrueFalseExamplesShowBothChoicesAndCorrectFalseStatements() {
        for language in ["nl", "en"] {
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.true-false-examples.\(UUID().uuidString)"
            app.launchArguments = ["-settings.languageOverride", language, "-AppleICUForce24HourTime", "YES"]
            app.launch()
            openPractice()
            selectPractice("practice.type.trueFalse")
            tap("practice.start")
            let liveTitle = app.staticTexts["question.title"].label
            tap("question.example")
            var truths = Set<Bool>()
            var previousTarget: ClockTime?
            for index in 0..<6 {
                let question = DinoDemonstrationExamples.question(kind: .trueFalse, minutes: [0], minuteStep: 60,
                                                                index: index, previousTarget: previousTarget, language: language)
                previousTarget = question.target
                let truthful = question.expectedAnswer == .truth(true)
                truths.insert(truthful)
                for (option, response) in question.responses.enumerated() {
                    let button = app.buttons["demo.option.\(option)"]
                    XCTAssertTrue(button.exists)
                    XCTAssertFalse(button.isEnabled, "Examples show the answer without submitting a live response")
                    XCTAssertEqual(button.label, language == "nl" ? (option == 0 ? "Goed" : "Fout") : (option == 0 ? "True" : "False"))
                    XCTAssertEqual(button.value as? String, response == question.expectedAnswer ? (language == "nl" ? "Goed" : "True") : "")
                }
                let correction = app.descendants(matching: .any)["demo.correctStatement"]
                if truthful {
                    XCTAssertFalse(correction.exists)
                } else {
                    XCTAssertTrue(correction.waitForExistence(timeout: 5))
                    let words = DinoTimeWords.time(question.target, language: language)
                    XCTAssertEqual(correction.label, language == "nl" ? "Het is \(words)." : "It is \(words).")
                    XCTAssertGreaterThan(correction.frame.minY, app.staticTexts["demo.title"].frame.maxY)
                }
                saveScreenshot("true-false-example-\(language)-\(index)")
                if index < 5 { tap("demo.nextExample") }
            }
            XCTAssertEqual(truths, Set([true, false]))
            tap("demo.ready")
            XCTAssertEqual(app.staticTexts["question.title"].label, liveTitle)
            XCTAssertTrue(app.buttons["question.option.0"].isEnabled)
        }
    }

    func testTrueFalseWrongAnswerRevealsCorrectTimeWithoutMovingClock() {
        verifyTrueFalseTitleCorrection(language: "nl")
    }

    func testTrueFalseTitleCorrectionInEnglish() {
        app.terminate()
        app.launchArguments = ["-settings.languageOverride", "en", "-AppleICUForce24HourTime", "YES"]
        app.launch()
        verifyTrueFalseTitleCorrection(language: "en")
    }

    private func verifyTrueFalseTitleCorrection(language: String) {
        openPractice()
        tap("practice.time.minutes")
        selectPractice("practice.type.trueFalse")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .minutes, order: .specific(.trueFalse)),
                                              seed: seed, language: language)
        var truths = Set<Bool>()
        let correction = app.descendants(matching: .any)["question.correctStatement"]
        let title = app.staticTexts["question.title"]
        let clock = app.descendants(matching: .any)["question.targetClock"]
        for index in 0..<3 {
            let question = generator.next(index: index)
            if case .truth(let truthful) = question.expectedAnswer { truths.insert(truthful) }
            XCTAssertFalse(correction.exists, "The answer must stay hidden before submitting")
            let originalTitle = title.label
            let titleFrame = title.frame
            let clockFrame = clock.frame
            tap("question.option.\(question.responses.firstIndex { $0 != question.expectedAnswer }!)")
            XCTAssertTrue(correction.waitForExistence(timeout: 5))
            let words = DinoTimeWords.time(question.target, language: language)
            XCTAssertEqual(correction.label, language == "nl" ? "Het is \(words)." : "It is \(words).")
            XCTAssertEqual(title.label, originalTitle, "Keep the original statement above its correction")
            XCTAssertGreaterThan(correction.frame.minY, title.frame.maxY)
            XCTAssertLessThan(correction.frame.maxY, clock.frame.minY)
            XCTAssertEqual(title.frame.minY, titleFrame.minY, accuracy: 1)
            XCTAssertEqual(clock.frame.minY, clockFrame.minY, accuracy: 1)
            XCTAssertTrue(app.buttons["question.next"].isHittable)
            XCTAssertFalse(app.buttons["question.showAnswer"].exists)
            saveScreenshot("true-false-correction-\(language)-\(index)")
            tap("question.next")
        }
        XCTAssertEqual(truths, Set([true, false]), "Exercise wrong answers to both true and false statements")
        XCTAssertFalse(correction.exists, "A new question must clear the correction")
        let correctQuestion = generator.next(index: 3)
        let correctTitle = title.label
        tap("question.option.\(correctQuestion.responses.firstIndex(of: correctQuestion.expectedAnswer)!)")
        XCTAssertFalse(correction.exists, "A correct answer must keep its title intact")
        let advanced = NSPredicate { _, _ in
            title.label != correctTitle && self.app.buttons["question.option.0"].isEnabled
        }
        expectation(for: advanced, evaluatedWith: nil)
        waitForExpectations(timeout: 8)
        XCTAssertFalse(correction.exists, "Automatic advance must also clear the correction")
    }

    func testRefinedArithmeticTitlesInDutchAndEnglish() {
        for language in ["nl", "en"] {
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.question-titles.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
            app.launchArguments = ["-settings.languageOverride", language, "-AppleICUForce24HourTime", "NO"]
            app.launch()
            XCTAssertTrue(app.buttons["header.practice"].waitForExistence(timeout: 10))
            waitForMapOpeningToFinish()
            tap("header.practice")
            for type in [DinoPracticeQuestion.addTime, .subtractTime, .timeZone, .flightArrival] {
                selectPractice("practice.type.\(type.rawValue)")
                tap("practice.start")
                var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(type)),
                                                       seed: seed, language: language)
                let question = generator.next(index: 0)
                let title = app.staticTexts["question.title"]
                let reference = question.relatedTimes[0]
                let words = DinoTimeWords.time(reference, language: language)
                XCTAssertTrue(title.label.contains(words))
                XCTAssertFalse(title.label.contains(DinoTimeWords.dayPartSuffix(reference, language: language)),
                               "The reference clock supplies the day-part context")
                if type == .addTime || type == .subtractTime {
                    let duration = DinoTimeWords.spokenDuration(question.durationMinutes, language: language)
                    let expected = language == "nl"
                        ? "Het is \(words). Hoe laat \(type == .addTime ? "is" : "was") het \(duration) \(type == .addTime ? "later" : "eerder")?"
                        : "It is \(words). What time \(type == .addTime ? "will it be" : "was it") \(duration) \(type == .addTime ? "later" : "earlier")?"
                    XCTAssertEqual(title.label, expected)
                    XCTAssertEqual(app.descendants(matching: .any)["question.targetClock"].label, reference.digitalText,
                                   "The arithmetic reference still distinguishes AM and PM in 24-hour digits")
                }
                saveScreenshot("refined-title-\(type.rawValue)-\(language)")
                tap("question.example")
                let example = DinoDemonstrationExamples.question(kind: type.recipe.kind, minutes: [0], minuteStep: 60,
                                                                 index: 0, previousTarget: nil, language: language)
                let demoTitle = app.staticTexts["demo.title"]
                XCTAssertTrue(demoTitle.label.contains(DinoTimeWords.time(example.relatedTimes[0], language: language)))
                XCTAssertFalse(demoTitle.label.contains(DinoTimeWords.dayPartSuffix(example.relatedTimes[0], language: language)))
                saveScreenshot("refined-title-example-\(type.rawValue)-\(language)")
                tap("demo.ready")
                tap("header.pause")
            }
        }
    }

    func testMatchingRequiresAllConnectionsBeforeChecking() {
        openPractice()
        selectPractice("practice.type.match")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.match)), seed: seed)
        let question = generator.next(index: 0)
        let reminder = app.descendants(matching: .any)["question.inputReminder"]
        let confirm = app.buttons["question.confirm"]
        let confirmFrame = confirm.frame
        tap("question.confirm")
        XCTAssertTrue(reminder.waitForExistence(timeout: 3))
        XCTAssertEqual(reminder.label, "Verbind eerst alle klokken")
        XCTAssertEqual(reminder.frame.midY, confirmFrame.midY, accuracy: 1)
        XCTAssertFalse(app.buttons["question.next"].exists)
        for index in 0..<3 {
            // AX queries can outlast the five-second reminder on a busy simulator.
            confirm.tap()
            XCTAssertEqual(app.buttons["question.match.clock.\(index)"].value as? String, "Verbind eerst alle klokken")
        }
        confirm.tap()
        saveScreenshot("matching-missing-connections")
        for index in 0..<3 {
            let option = question.options.firstIndex(of: question.relatedTimes[index])!
            tap("question.match.clock.\(index)")
            tap("question.match.time.\(option)")
            if index < 2 {
                confirm.tap()
                XCTAssertTrue(reminder.waitForExistence(timeout: 3))
                XCTAssertEqual(app.buttons["question.match.clock.\(index + 1)"].value as? String, "Verbind eerst alle klokken")
                XCTAssertEqual(app.buttons["question.match.clock.\(index)"].value as? String, "")
                XCTAssertEqual(app.buttons["question.match.time.\(option)"].value as? String, "")
                if index == 0 {
                    confirm.tap()
                    saveScreenshot("matching-partial-connections-reminder")
                }
            }
        }
        XCTAssertTrue(reminder.waitForNonExistence(timeout: 3))
        tap("question.confirm")
        XCTAssertTrue(app.descendants(matching: .any)["question.match.line.0"].waitForNonExistence(timeout: 5), "The next question starts with no connections")
        tap("question.confirm")
        XCTAssertTrue(reminder.waitForExistence(timeout: 3))
    }

    func testThreePairMatchingAndTapDemonstration() {
        openPractice()
        selectPractice("practice.type.match")
        tap("practice.start")
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.match.clock.")).count, 3)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.match.time.")).count, 3)
        XCTAssertEqual(app.buttons["question.confirm"].label, "Controleer mijn verbindingen")
        XCTAssertTrue(app.buttons["question.confirm"].isEnabled)
        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.match)), seed: seed)
        let q = generator.next(index: 0)
        let left = app.buttons["question.match.clock.0"]
        let right = app.buttons["question.match.time.0"]
        XCTAssertLessThan(left.frame.maxX, right.frame.minX)
        XCTAssertEqual(left.frame.midY, right.frame.midY, accuracy: 1)
        tap("question.match.clock.0")
        let wrong = q.options.firstIndex { $0 != q.relatedTimes[0] }!
        tap("question.match.time.\(wrong)")
        XCTAssertTrue(app.buttons["question.confirm"].isEnabled)
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
        XCTAssertTrue(app.buttons["question.confirm"].isEnabled)
        tap("question.match.time.\(matching)")
        tap("question.match.clock.0")
        for index in 1..<3 {
            tap("question.match.clock.\(index)")
            tap("question.match.time.\(q.options.firstIndex(of: q.relatedTimes[index])!)")
        }
        XCTAssertTrue(app.buttons["question.confirm"].isEnabled)
        tap("question.match.clock.2")
        XCTAssertTrue(app.buttons["question.confirm"].isEnabled)
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
        XCTAssertTrue(app.descendants(matching: .any)["question.match.line.0"].waitForNonExistence(timeout: 5), "The next question starts with no connections")
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
        for index in 0..<3 {
            XCTAssertTrue(clocks[index].label.contains(question.relatedTimes[index].digitalText), "Clock fixture: \(clocks[index].label)")
            XCTAssertTrue(times[index].label.contains(question.options[index].digitalText), "Time fixture: \(times[index].label)")
        }
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
        XCTAssertTrue(app.buttons["question.confirm"].isEnabled)
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
        for index in 0..<3 {
            let target = question.options.firstIndex(of: question.relatedTimes[index])!
            let line = app.descendants(matching: .any)["question.match.line.\(index)"]
            XCTAssertEqual(line.frame.midY, (clocks[index].frame.midY + times[target].frame.midY) / 2,
                           accuracy: 2, "The drag connects clock \(index) to its intended time")
        }
        saveScreenshot("matching-drag-and-tap-ready")
        tap("question.confirm")
        XCTAssertTrue(app.descendants(matching: .any)["question.match.line.0"].waitForNonExistence(timeout: 5), "The next question starts with no connections")
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

    func testCorrectRetriesAdvanceUnlessTheyAddAnExplanation() {
        openPractice()
        func counter(_ identifier: String, value: Int) -> XCUIElement {
            app.staticTexts.matching(identifier: identifier)
                .matching(NSPredicate(format: "label == %@", String(value))).firstMatch
        }
        for type in [DinoPracticeQuestion.chooseAnalog, .minutesBetween, .daySchedule] {
            selectPractice("practice.type.\(type.rawValue)")
            tap("practice.start")
            var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(type)), seed: seed)
            let first = generator.next(index: 0)
            tap("question.option.\(first.responses.firstIndex(of: first.expectedAnswer)!)")
            XCTAssertTrue(counter("header.questions", value: 2).waitForExistence(timeout: 5))
            let question = generator.next(index: 1, difficultyForKind: { _ in .familiar })
            XCTAssertEqual(question.responses.count, 4)
            tap("question.option.\(question.responses.firstIndex { $0 != question.expectedAnswer }!)")
            XCTAssertTrue(app.buttons["question.showAnswer"].waitForExistence(timeout: 5))
            tap("question.option.\(question.responses.firstIndex(of: question.expectedAnswer)!)")
            if type == .daySchedule {
                XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
                RunLoop.current.run(until: Date().addingTimeInterval(1.5))
                XCTAssertTrue(counter("header.questions", value: 2).exists, "The train explanation waits for Next")
                XCTAssertTrue(app.descendants(matching: .any)["question.schedule.total"].exists)
                tap("question.next")
            }
            XCTAssertTrue(counter("header.questions", value: 3).waitForExistence(timeout: 5),
                          "A correct retry without a new explanation advances automatically for \(type)")
            XCTAssertFalse(app.buttons["question.next"].exists)
            XCTAssertFalse(app.buttons["question.showAnswer"].exists)
            XCTAssertTrue(counter("header.streak", value: 0).exists, "A correct retry keeps the lost point")
            tap("header.pause")
        }
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
        let initialExample = DinoDemonstrationExamples.time(index: 0, minutes: DinoPracticeTime.half.minutes)
        XCTAssertEqual(example.label, initialExample.digitalText)
        tap("clock.hour.more")
        XCTAssertEqual(example.label, ClockTime(hour: 4, minute: initialExample.minute).digitalText)
        tap("clock.minute.less")
        XCTAssertEqual(example.label, ClockTime(hour: 4, minute: ClockTime.shiftedMinute(initialExample.minute, by: -30)).digitalText)
        tap("clock.minute.more")
        tap("clock.hour.less")
        XCTAssertEqual(example.label, initialExample.digitalText)
        saveScreenshot("digital-example-independent-arrows")
        tap("demo.nextExample")
        XCTAssertEqual(example.label, DinoDemonstrationExamples.time(index: 1, minutes: DinoPracticeTime.half.minutes).digitalText)
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
        XCTAssertEqual(app.staticTexts["question.title"].label, "Tik de klokken op volgorde van vroeg naar laat")
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
        XCTAssertFalse(app.staticTexts["demo.sequence.hint"].exists)
        let pattern = DinoDemonstrationExamples.question(kind: .timeSequence, minutes: [0], minuteStep: 60,
                                                         index: 0, previousTarget: nil)
        for index in 0..<3 {
            XCTAssertEqual(app.descendants(matching: .any)["demo.sequence.arrow.\(index)"].label,
                           "+\(DinoTimeWords.duration(pattern.durationMinutes, language: "nl"))")
        }
        saveScreenshot("sequence-example-step-arrows")
        tap("demo.ready")
    }

    func testWrongClockChoicesExplainTheirOwnTime() {
        checkWrongClockChoices([.read24Hour, .chooseAnalog], customStyle: true)
    }

    func testTimeReadingAnalogClockDutch() { checkTimeReadingClock(language: "nl") }

    func testTimeReadingAnalogClockEnglish() { checkTimeReadingClock(language: "en") }

    private func checkTimeReadingClock(language: String) {
        app.terminate()
        app.launchArguments = ["-settings.languageOverride", language, "-AppleICUForce24HourTime", "YES"]
        app.launch()
        openPractice()
        let labels = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.timeReading.label."))
        func waitForQuestion(_ value: Int) {
            XCTAssertTrue(app.staticTexts.matching(identifier: "header.questions")
                .matching(NSPredicate(format: "label == %@", String(value))).firstMatch.waitForExistence(timeout: 6))
        }
        for family in [DinoPracticeTime.whole, .minutes] {
            tap("practice.time.\(family.rawValue)")
            selectPractice("practice.type.readDigital")
            tap("practice.start")
            var generator = DinoPracticeGenerator(configuration: .init(time: family, order: .specific(.readDigital)), seed: seed, language: language)
            let first = generator.next(index: 0)
            tap("question.option.\(first.options.firstIndex { $0 != first.target }!)")
            XCTAssertEqual(app.buttons["question.option.\(first.options.firstIndex(of: first.target)!)"].value as? String,
                           language == "nl" ? "Goed" : "True")
            XCTAssertEqual(labels.count, 0)
            tap("question.example")
            XCTAssertTrue(app.descendants(matching: .any)["demo.timeReading.clock"].exists)
            for minute in stride(from: 0, to: 60, by: 5) {
                XCTAssertTrue(app.staticTexts[DinoTimeWords.time(.init(hour: 3, minute: minute), language: language)].exists)
            }
            if family == .minutes {
                tap("demo.nextExample")
                XCTAssertEqual(app.descendants(matching: .any)["demo.targetClock"].label, "03:01")
            }
            saveScreenshot("compact-reading-\(language)-\(family.rawValue)-example")
            tap("demo.ready")
            tap("question.next")
            waitForQuestion(2)
            let second = generator.next(index: 1, difficultyForKind: { _ in .introduction })
            tap("question.option.\(second.options.firstIndex(of: second.target)!)")
            waitForQuestion(3)
            let third = generator.next(index: 2, difficultyForKind: { _ in .familiar })
            XCTAssertEqual(third.options.count, 4)
            tap("question.option.\(third.options.firstIndex { $0 != third.target }!)")
            XCTAssertEqual(labels.count, 0)
            tap("question.option.\(third.options.firstIndex(of: third.target)!)")
            waitForQuestion(4)
            XCTAssertEqual(labels.count, 0)
            XCTAssertFalse(app.buttons["question.next"].exists, "Correct answers do not introduce an extra review step")
            tap("header.pause")
        }
    }

    func testAnalogWrongClockChoicesKeepTheQuestionVisible() {
        checkWrongClockChoices([.chooseAnalog], customStyle: false, stopsAfterFirstMistake: true)
        let viewport = app.scrollViews["game.questions"].frame
        XCTAssertGreaterThanOrEqual(app.staticTexts["question.title"].frame.minY, viewport.minY)
        XCTAssertLessThanOrEqual(app.buttons["question.option.3"].frame.maxY, viewport.maxY)
        var generator = DinoPracticeGenerator(configuration: .init(time: .fiveMinutes, order: .specific(.chooseAnalog)),
                                               seed: seed, language: "en")
        _ = generator.next(index: 0)
        let question = generator.next(index: 1, difficultyForKind: { _ in .familiar })
        tap("question.option.\(question.responses.firstIndex(of: question.expectedAnswer)!)")
        saveScreenshot("analog-minute-scale-correct-retry")
        XCTAssertTrue(app.staticTexts.matching(identifier: "header.questions")
            .matching(NSPredicate(format: "label == %@", "3")).firstMatch.waitForExistence(timeout: 6))
        let nextTarget = app.descendants(matching: .any)["question.targetClock"].firstMatch.frame
        XCTAssertLessThan(nextTarget.height, nextTarget.width * 0.6,
                          "The next question starts without hidden reading-helper space")
        saveScreenshot("analog-minute-scale-reset-next-question")
    }

    private func checkWrongClockChoices(_ kinds: [DinoPracticeQuestion], customStyle: Bool, stopsAfterFirstMistake: Bool = false) {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launchArguments = ["-settings.languageOverride", "en", "-AppleICUForce24HourTime", "NO"]
        app.launch()
        XCTAssertTrue(app.buttons["header.practice"].waitForExistence(timeout: 10))
        waitForMapOpeningToFinish()
        if customStyle {
            tap("header.dino")
            tap("personalize.page.digital")
            tap("theme.numerals.digital")
            tap("theme.dino.display.yellow")
            tap("theme.dino.digitColor.navy")
            tap("personalize.done")
        }
        tap("header.practice")
        tap("practice.time.fiveMinutes")
        for kind in kinds {
            selectPractice("practice.type.\(kind.rawValue)")
            tap("practice.start")
            var generator = DinoPracticeGenerator(configuration: .init(time: .fiveMinutes, order: .specific(kind)),
                                                   seed: seed, language: "en")
            let first = generator.next(index: 0)
            tap("question.option.\(first.responses.firstIndex(of: first.expectedAnswer)!)")
            XCTAssertTrue(app.buttons["question.option.3"].waitForExistence(timeout: 6))
            let question = generator.next(index: 1, difficultyForKind: { _ in .familiar })
            let frames = question.responses.indices.map { app.buttons["question.option.\($0)"].frame }
            let targetFrame = kind == .chooseAnalog ? app.descendants(matching: .any)["question.targetClock"].firstMatch.frame : .zero
            let titleFrame = app.staticTexts["question.title"].frame
            if kind == .chooseAnalog {
                XCTAssertLessThan(targetFrame.height, targetFrame.width * 0.6, "The initial display reserves no hidden reading helpers")
                saveScreenshot("analog-minute-scale-before-answer")
            }
            let wrong = question.responses.indices.filter { question.responses[$0] != question.expectedAnswer }
            for index in wrong.prefix(stopsAfterFirstMistake ? 1 : wrong.count) {
                guard case .time(let time) = question.responses[index] else { return XCTFail("Expected clock choices") }
                let option = app.buttons["question.option.\(index)"]
                tap(option.identifier)

                let reading = kind == .spokenTime ? DinoTimeWords.time(time, language: "en")
                    : time.digitalReading(notation: .twelve,
                                          languageCode: "en").text
                XCTAssertTrue(option.label.contains(reading), "Each rejected choice explains its own time")
                if kind == .spokenTime {
                    XCTAssertFalse(option.label.contains(":"), "Type 5 explains rejected clocks in words")
                }
                XCTAssertFalse(option.isEnabled)
                if [.readDigital, .read24Hour, .chooseAnalog].contains(kind) {
                    for other in question.responses.indices {
                        let otherOption = app.buttons["question.option.\(other)"]
                        // Feedback badges enlarge answered cards' AX bounds. Unanswered
                        // cards retain their decoration and measure actual layout movement.
                        if kind == .chooseAnalog && !otherOption.isEnabled { continue }
                        let frame = otherOption.frame
                        let helpShift = kind == .chooseAnalog
                            ? app.descendants(matching: .any)["question.targetClock"].firstMatch.frame.maxY - targetFrame.maxY : 0
                        XCTAssertEqual(frame.midY, frames[other].midY + helpShift, accuracy: 1)
                        if kind == .chooseAnalog { XCTAssertEqual(frame.height, frames[other].height, accuracy: 1) }
                    }
                }
                if kind == .chooseAnalog {
                    let assistedTarget = app.descendants(matching: .any)["question.targetClock"].firstMatch.frame
                    let assistedTitle = app.staticTexts["question.title"].frame
                    XCTAssertGreaterThan(assistedTarget.height - targetFrame.height, 30,
                                         "Only a mistake adds room for the reading helpers")
                    XCTAssertEqual(assistedTarget.minY - assistedTitle.maxY, targetFrame.minY - titleFrame.maxY,
                                   accuracy: 1, "Reading helpers keep the normal gap below the title")
                    if index == wrong.first { saveScreenshot("analog-first-mistake-smooth-feedback") }
                }
            }
            XCTAssertTrue(app.buttons[stopsAfterFirstMistake ? "question.showAnswer" : "question.next"].exists)
            saveScreenshot("wrong-time-explanation-\(kind.rawValue)")
            if !customStyle { return }
            tap("question.next")
            if [.readDigital, .read24Hour].contains(kind) {
                let choices = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option."))
                XCTAssertTrue(choices.allElementsBoundByIndex.allSatisfy { !$0.label.contains(":") },
                              "The next question hides every rejected-answer clock")
            }
            tap("header.pause")
        }
    }

    func testAfterNoonReadingHintFollowsHourNotation() {
        for notation in [DigitalHourNotation.twentyFour, .twelve] {
            let language = notation == .twentyFour ? "nl" : "en"
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.after-noon.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
            app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = "read24Hour"
            app.launchEnvironment["DINO_TEST_PRACTICE_TIME"] = "fiveMinutes"
            app.launchEnvironment["DINO_TEST_PRACTICE_CHALLENGE"] = nil
            app.launchArguments = ["-settings.languageOverride", language,
                                   "-AppleICUForce24HourTime", notation == .twentyFour ? "YES" : "NO"]
            app.launch()
            var generator = DinoPracticeGenerator(configuration: .init(time: .fiveMinutes, order: .specific(.read24Hour)),
                                                   seed: seed, language: language)
            let first = generator.next(index: 0)
            tap("question.option.\(first.responses.firstIndex(of: first.expectedAnswer)!)")
            XCTAssertTrue(app.buttons["question.option.3"].waitForExistence(timeout: 6))
            let question = generator.next(index: 1, difficultyForKind: { _ in .familiar })
            let target = app.descendants(matching: .any)["question.targetClock"]
            XCTAssertTrue(target.waitForExistence(timeout: 8))
            XCTAssertGreaterThan(question.target.hour, 12)
            XCTAssertEqual(target.label, question.target.digitalReading(notation: notation, languageCode: language).text)
            XCTAssertEqual(app.staticTexts["question.title"].label,
                           language == "nl" ? "Hoe laat is het?" : "What time is it?")
            let converted = app.descendants(matching: .any)["question.afterNoon.convertedClock"]
            let subtraction = app.staticTexts["question.afterNoon.subtractTwelve"]
            let arrow = app.images["question.afterNoon.arrow"]
            XCTAssertFalse(converted.exists)
            XCTAssertFalse(subtraction.exists)
            XCTAssertFalse(arrow.exists)
            let wrong = question.responses.indices.filter { question.responses[$0] != question.expectedAnswer }
            let correctIndex = question.responses.firstIndex(of: question.expectedAnswer)!
            let untouched = app.buttons["question.option.\(correctIndex)"]
            let initialFrame = untouched.frame
            saveScreenshot("after-noon-centered-\(notation.rawValue)")
            tap("question.option.\(wrong[0])")
            if notation == .twentyFour {
                XCTAssertTrue(converted.waitForExistence(timeout: 3))
                XCTAssertEqual(converted.label, question.target.adding(minutes: -720).digitalText)
                XCTAssertTrue(subtraction.exists)
                XCTAssertLessThanOrEqual(subtraction.frame.height, 20, "The smaller −12 capsule stays on one line")
                XCTAssertGreaterThanOrEqual(subtraction.frame.minY, target.frame.minY + 4,
                                            "The caption emerges within the display's top edge")
                XCTAssertLessThanOrEqual(subtraction.frame.maxY, target.frame.maxY - 4)
                XCTAssertTrue(arrow.exists)
                XCTAssertGreaterThan(arrow.frame.minX, target.frame.maxX)
                XCTAssertLessThan(arrow.frame.maxX, converted.frame.minX)
                XCTAssertGreaterThan(converted.frame.minX, target.frame.maxX)
            } else {
                XCTAssertFalse(converted.exists, "A 12-hour display never subtracts twelve again")
                XCTAssertFalse(subtraction.exists)
                XCTAssertFalse(arrow.exists)
            }
            let stable = NSPredicate { _, _ in
                abs(untouched.frame.midY - initialFrame.midY) < 1
            }
            expectation(for: stable, evaluatedWith: untouched)
            waitForExpectations(timeout: 3)
            saveScreenshot("after-noon-first-miss-\(notation.rawValue)")
            if notation == .twentyFour {
                for orientation in [UIDeviceOrientation.landscapeLeft, .portrait] {
                    XCUIDevice.shared.orientation = orientation
                    XCTAssertTrue(converted.exists, "Rotation retains the expanded hint")
                    XCTAssertTrue(subtraction.exists, "Rotation does not restart a delayed caption reveal")
                    XCTAssertTrue(arrow.exists)
                    XCTAssertEqual(converted.label, question.target.adding(minutes: -720).digitalText)
                    XCTAssertEqual(target.label, question.target.digitalText)
                    saveScreenshot("after-noon-rotated-\(orientation.rawValue)")
                }
            }
            tap("question.option.\(wrong[1])")
            saveScreenshot("after-noon-second-miss-\(notation.rawValue)")
            tap("question.showAnswer")
            tap("question.next")
            let next = generator.next(index: 2)
            waitUntilLabel("question.targetClock", equals: next.target.digitalReading(notation: notation, languageCode: language).text,
                           timeout: 6)
            XCTAssertFalse(converted.exists, "The next question clears the conversion hint")
            XCTAssertFalse(subtraction.exists)
        }
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
            XCTAssertFalse(end.exists, "An example starts with only its time and difference")
            XCTAssertFalse(app.descendants(matching: .any)["demo.timeArithmetic.total.hours"].exists,
                           "The totals wait for the individual helper values")
            saveScreenshot("\(kind.rawValue)-example-before-helpers")
            XCTAssertTrue(end.waitForExistence(timeout: 6))
            XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "demo.targetClock").count, 1)
            XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "demo.answer").count, 1)
            XCTAssertNotNil(start.label.range(of: "^[0-9]{2}:[0-9]{2}$", options: .regularExpression))
            XCTAssertNotNil(end.label.range(of: "^[0-9]{2}:[0-9]{2}$", options: .regularExpression))
            XCTAssertEqual(start.frame.width, end.frame.width, accuracy: 1)
            XCTAssertEqual(start.frame.height, end.frame.height, accuracy: 1)
            let bar = app.descendants(matching: .any)["demo.timeChange.difference"]
            let hours = app.descendants(matching: .any)["demo.timeArithmetic.hours"]
            let minutes = app.descendants(matching: .any)["demo.timeArithmetic.minutes"]
            XCTAssertTrue(bar.exists)
            XCTAssertTrue(hours.waitForExistence(timeout: 6))
            XCTAssertTrue(minutes.waitForExistence(timeout: 6))
            XCTAssertEqual(start.frame.midX, end.frame.midX, accuracy: 2)
            XCTAssertLessThan(hours.frame.minY, bar.frame.minY)
            XCTAssertEqual(hours.frame.minY, minutes.frame.minY, accuracy: 4)
            XCTAssertLessThan(bar.frame.maxY, end.frame.minY)
            XCTAssertLessThan(max(hours.frame.maxY, minutes.frame.maxY), end.frame.minY)
            saveScreenshot("\(kind.rawValue)-equal-example-clocks")
            tap("demo.nextExample")
            XCTAssertFalse(end.exists, "Refreshing restarts the complete explanation")
            XCTAssertFalse(app.descendants(matching: .any)["demo.timeArithmetic.total.hours"].exists)
            saveScreenshot("\(kind.rawValue)-refreshed-example-before-helpers")
            XCTAssertTrue(end.waitForExistence(timeout: 6))
            tap("demo.ready")
            tap("header.pause")
        }
    }

    func testArithmeticMidnightCorrectionsStaySeparate() {
        checkArithmeticNotation(type: .addTime, notation: .twentyFour, name: "midnight-carry") { work, display in
            work.start.hour == 23 && display.hourCarry == 1 && display.hourWrap == -24
        }
        checkArithmeticNotation(type: .subtractTime, notation: .twentyFour, name: "midnight-borrow") { work, display in
            work.start.hour == 0 && display.hourCarry == -1 && display.hourWrap == 24
        }
    }

    func testArithmeticSupportsTwelveHourNoonAndMidnight() {
        checkArithmeticNotation(type: .addTime, notation: .twelve, name: "noon-ampm") { work, display in
            work.start.hour < 12 && work.result.hour >= 12 && display.hourCarry == 1
        }
        checkArithmeticNotation(type: .addTime, notation: .twelve, name: "midnight-ampm") { work, display in
            work.start.hour >= 12 && work.result.hour < 12 && display.hourCarry == 1
        }
        checkArithmeticNotation(type: .addTime, notation: .twelve, name: "twelve-to-one-pm") { work, display in
            work.start.hour == 12 && work.result.hour == 13 && display.hourWrap == -12 && !display.changesPeriod
        }
        checkArithmeticNotation(type: .subtractTime, notation: .twelve, name: "borrow-before-noon") { work, display in
            work.start.hour >= 12 && work.result.hour < 12 && display.hourCarry == -1
        }
    }

    private func checkArithmeticNotation(type: DinoPracticeQuestion, notation: DigitalHourNotation, name: String,
                                         matches: (DinoClockArithmetic, DinoClockArithmeticDisplay) -> Bool) {
        let configuration = DinoPracticeConfiguration(time: .minutes, order: .specific(type))
        var fixture: (UInt64, ClockQuestion)?
        for candidate in UInt64(0)..<500 {
            var generator = DinoPracticeGenerator(configuration: configuration, seed: candidate, language: "en")
            let question = generator.next(index: 3, difficultyForKind: { _ in .challenge })
            let work = DinoClockArithmetic(start: question.relatedTimes[0], durationMinutes: question.durationMinutes, adding: type == .addTime)
            if matches(work, .init(work: work, notation: notation)) { fixture = (candidate, question); break }
        }
        guard let (fixtureSeed, question) = fixture else { return XCTFail("No arithmetic fixture for \(name)") }
        let work = DinoClockArithmetic(start: question.relatedTimes[0], durationMinutes: question.durationMinutes, adding: type == .addTime)
        let display = DinoClockArithmeticDisplay(work: work, notation: notation)
        app.terminate()
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.arithmetic.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_SEED"] = String(fixtureSeed)
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = type.rawValue
        app.launchEnvironment["DINO_TEST_PRACTICE_CHALLENGE"] = "1"
        app.launchArguments = ["-settings.languageOverride", "en", "-AppleICUForce24HourTime", notation == .twentyFour ? "YES" : "NO"]
        app.launch()
        let start = app.descendants(matching: .any)["question.targetClock"]
        let result = app.descendants(matching: .any)["question.timeArithmetic.result"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        XCTAssertEqual(start.label, work.start.digitalReading(notation: notation, languageCode: "en").text)
        let wrong = question.responses.firstIndex { $0 != question.expectedAnswer }!
        tap("question.option.\(wrong)")
        XCTAssertTrue(app.buttons["question.showAnswer"].waitForExistence(timeout: 5))
        XCTAssertFalse(result.exists)
        let hours = app.descendants(matching: .any)["question.timeArithmetic.hours"]
        XCTAssertTrue(hours.waitForExistence(timeout: 5))
        XCTAssertEqual(hours.label, display.hourEquation)
        XCTAssertEqual(app.descendants(matching: .any)["question.timeArithmetic.total.hours"].label,
                       DinoClockArithmetic.format(display.hourSubtotal))
        XCTAssertFalse(app.descendants(matching: .any)["question.timeArithmetic.periodChange"].exists)
        saveScreenshot("arithmetic-\(name)-hint")
        tap("question.showAnswer")
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        XCTAssertEqual(result.label, work.result.digitalReading(notation: notation, languageCode: "en").text)
        func signed(_ value: Int) -> String { value < 0 ? "−\(abs(value))" : "+\(value)" }
        let corrections = [display.hourCarry, display.hourWrap].filter { $0 != 0 }.map(signed)
        let arrow = app.descendants(matching: .any)["question.timeArithmetic.arrow.result.hours"]
        XCTAssertTrue(arrow.exists)
        XCTAssertEqual(arrow.label, corrections.joined(separator: ", "))
        let period = app.descendants(matching: .any)["question.timeArithmetic.periodChange"]
        XCTAssertEqual(period.exists, display.changesPeriod)
        if display.changesPeriod {
            let before = work.start.digitalReading(notation: notation, languageCode: "en").period!
            let after = work.result.digitalReading(notation: notation, languageCode: "en").period!
            XCTAssertEqual(period.label, "\(before) → \(after)")
        }
        XCTAssertGreaterThan(result.frame.width, result.frame.height * 1.8, "AM/PM stays on the clock's digit row")
        saveScreenshot("arithmetic-\(name)-result")
    }

    func testTwoChoiceArithmeticRevealsTheCompleteCompactExplanation() {
        openPractice()
        tap("practice.time.fiveMinutes")
        for kind in [DinoPracticeQuestion.addTime, .subtractTime] {
            selectPractice("practice.type.\(kind.rawValue)")
            tap("practice.start")
            var generator = DinoPracticeGenerator(configuration: .init(time: .fiveMinutes, order: .specific(kind)), seed: seed)
            let question = generator.next(index: 0)
            XCTAssertEqual(question.responses.count, 2)
            let result = app.descendants(matching: .any)["question.timeArithmetic.result"]
            XCTAssertFalse(result.exists)
            let wrong = question.responses.firstIndex { $0 != question.expectedAnswer }!
            tap("question.option.\(wrong)")
            XCTAssertTrue(result.waitForExistence(timeout: 5))
            XCTAssertEqual(result.label, question.target.digitalText)
            XCTAssertTrue(app.descendants(matching: .any)["question.timeArithmetic.hours"].exists)
            let total = app.descendants(matching: .any)["question.timeArithmetic.total.hours"]
            XCTAssertTrue(total.exists)
            XCTAssertGreaterThan(result.frame.minY, total.frame.maxY)
            XCTAssertLessThan(result.frame.minY - total.frame.maxY, 26,
                              "The final clock needs only a short arrow gap below the subtotals")
            XCTAssertFalse(app.buttons["question.showAnswer"].exists)
            XCTAssertTrue(app.buttons["question.next"].exists)
            saveScreenshot("\(kind.rawValue)-two-choice-compact-explanation")
            tap("question.next")
            XCTAssertFalse(result.exists, "The complete explanation resets for a new question")
            tap("header.pause")
        }
    }

    func testTimeArithmeticHintAppearsDuringRetryAndResultWaitsUntilClosed() {
        openPractice()
        tap("practice.time.fiveMinutes")
        for kind in [DinoPracticeQuestion.addTime, .subtractTime] {
            selectPractice("practice.type.\(kind.rawValue)")
            tap("practice.start")
            var generator = DinoPracticeGenerator(configuration: .init(time: .fiveMinutes, order: .specific(kind)), seed: seed)
            var progress = DinoLearningProgress()
            for index in 0..<6 {
                let difficulty = progress.difficulty
                let question = generator.next(index: index, difficultyForKind: { _ in difficulty })
                let counter = app.staticTexts.matching(identifier: "header.questions")
                    .matching(NSPredicate(format: "label == %@", String(index + 1))).firstMatch
                XCTAssertTrue(counter.waitForExistence(timeout: 6))
                if question.responses.count == 2 {
                    // Recover after each miss so the next question has four choices again.
                    tap("question.option.\(question.responses.firstIndex(of: question.expectedAnswer)!)")
                    progress.record(correct: true, at: difficulty)
                    continue
                }
                progress.record(correct: false, at: difficulty)
                let hours = app.descendants(matching: .any)["question.timeArithmetic.hours"]
                let minutes = app.descendants(matching: .any)["question.timeArithmetic.minutes"]
                let result = app.descendants(matching: .any)["question.timeArithmetic.result"]
                XCTAssertEqual(question.responses.count, 4)
                XCTAssertFalse(hours.exists, "A fresh question starts without the calculation")
                XCTAssertFalse(result.exists)
                let wrong = question.responses.indices.filter { question.responses[$0] != question.expectedAnswer }
                tap("question.option.\(wrong[0])")
                XCTAssertTrue(app.buttons["question.showAnswer"].waitForExistence(timeout: 5))
                XCTAssertTrue(hours.waitForExistence(timeout: 5))
                XCTAssertTrue(minutes.exists)
                XCTAssertFalse(result.exists, "The final clock must stay hidden during a retry")
                XCTAssertTrue(app.buttons["question.option.\(wrong[1])"].isEnabled)
                let optionCenters = question.responses.indices.map { app.buttons["question.option.\($0)"].frame.midY }
                let startY = app.descendants(matching: .any)["question.targetClock"].frame.minY
                let totals = app.descendants(matching: .any)["question.timeArithmetic.total.hours"]
                XCTAssertTrue(totals.exists)
                let hintGap = question.responses.indices.map { app.buttons["question.option.\($0)"].frame.minY }.min()! - totals.frame.maxY
                XCTAssertLessThan(hintGap, 44, "The hint must end at the subtotals without reserving an empty answer row")
                if index == 1 { saveScreenshot("\(kind.rawValue)-arithmetic-retry-hint") }
                if index == 1 {
                    tap("question.showAnswer")
                } else if index == 3 {
                    tap("question.option.\(question.responses.firstIndex(of: question.expectedAnswer)!)")
                } else {
                    for option in wrong.dropFirst() { tap("question.option.\(option)") }
                }
                XCTAssertTrue(result.waitForExistence(timeout: 5))
                XCTAssertEqual(result.label, question.target.digitalText)
                XCTAssertTrue(hours.exists, "Closing the question keeps the upper explanation")
                XCTAssertTrue(app.buttons["question.next"].exists)
                if index == 1 {
                    saveScreenshot("\(kind.rawValue)-arithmetic-final-arrows")
                    let finalStartY = app.descendants(matching: .any)["question.targetClock"].frame.minY
                    // Measure relative to the start clock, allowing the whole lesson to recenter.
                    // The correct choice gains an outer badge, so compare the unchanged wrong choices.
                    for option in wrong {
                        let growth = app.buttons["question.option.\(option)"].frame.midY - finalStartY
                            - (optionCenters[option] - startY)
                        XCTAssertGreaterThan(growth, result.frame.height + 10,
                                             "The answer choices move down only when the final clock is inserted")
                    }
                }
                tap("question.next")
                XCTAssertFalse(result.exists, "Advancing removes the previous answer")
            }
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

    func testWrongDayPartAnswerCanBeRejudgedFromSettings() throws {
        openPractice()
        selectPractice("practice.type.dayPart")
        tap("practice.start")
        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.dayPart)), seed: seed)
        let question = generator.next(index: 0)
        let wrongIndex = question.responses.firstIndex { $0 != question.expectedAnswer }!
        guard case .dayPart(let picked) = question.responses[wrongIndex] else {
            return XCTFail("Expected a day-part choice")
        }
        let optionFrames = (0..<4).map { app.buttons["question.option.\($0)"].frame }
        XCTAssertFalse(app.buttons["question.dayPart.settings"].exists)
        tap("question.option.\(wrongIndex)")
        XCTAssertTrue(app.buttons["question.showAnswer"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["question.dayPart.settings"].exists, "Settings stay hidden while the question can still be retried")
        tap("question.showAnswer")
        let settingsButton = app.buttons["question.dayPart.settings"]
        let next = app.buttons["question.next"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        XCTAssertEqual(settingsButton.label, "Instellingen wijzigen")
        XCTAssertLessThan(settingsButton.frame.maxY, next.frame.minY)
        XCTAssertEqual(app.buttons["question.option.\(wrongIndex)"].value as? String, "Fout")
        for option in 0..<4 {
            XCTAssertEqual(app.buttons["question.option.\(option)"].frame.midY, optionFrames[option].midY, accuracy: 1)
        }
        tap("question.dayPart.settings")
        let close = app.buttons["settings.dayParts.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        XCTAssertEqual(close.label, "Terug naar het spel")
        let timetable = timetableOwning(hour: question.target.hour, part: picked)
        let steps = try XCTUnwrap(DinoDayPartSchedule.standard.edits(to: timetable))
        for step in steps {
            tap("settings.dayParts.\(step.part.rawValue).from")
            let choice = app.buttons["settings.dayParts.\(step.part.rawValue).from.\(step.hour)"]
            XCTAssertTrue(choice.waitForExistence(timeout: 3), "Missing \(step.part.rawValue) start \(step.hour)")
            choice.tap()
        }
        close.tap()
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        RunLoop.current.run(until: Date().addingTimeInterval(1.2))
        XCTAssertTrue(next.exists, "A rescued answer stays until Next")
        XCTAssertFalse(settingsButton.exists)
        XCTAssertEqual(app.buttons["question.option.\(wrongIndex)"].value as? String, "Goed")
        tap("question.next")
        let streak = app.staticTexts.matching(identifier: "header.streak")
            .matching(NSPredicate(format: "label MATCHES %@", "[0-9]+")).firstMatch
        XCTAssertEqual(streak.label, "1")
    }

    private func timetableOwning(hour: Int, part: DinoDayPart) -> DinoDayPartSchedule {
        let order = DinoDayPart.allCases
        let origin = order.firstIndex(of: part)!
        var starts = [Int](repeating: 0, count: 4)
        for offset in 0..<4 { starts[(origin + offset) % 4] = (hour + offset) % 24 }
        return DinoDayPartSchedule(night: starts[0], morning: starts[1], afternoon: starts[2], evening: starts[3])
    }

    func testTabletExamplesReflowAfterRotation() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else { throw XCTSkip("iPad composition") }
        for type in [DinoPracticeQuestion.chooseDigital, .setDigital, .setAnalog, .readDigital, .read24Hour, .timeSequence, .match, .timeZone, .minutesBetween, .daySchedule, .dayPart, .flightArrival] {
            app.terminate()
            XCUIDevice.shared.orientation = .portrait
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.tablet-example.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
            app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = type.rawValue
            app.launch()
            tap("question.example")
            let ready = app.buttons["demo.ready"]
            XCTAssertTrue(ready.waitForExistence(timeout: 5))
            for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
                XCUIDevice.shared.orientation = orientation
                RunLoop.current.run(until: Date().addingTimeInterval(0.7))
                let viewport = app.scrollViews["demo.content"].frame
                XCTAssertGreaterThan(viewport.width, 620)
                XCTAssertGreaterThanOrEqual(ready.frame.height, 68)
                XCTAssertTrue(ready.isHittable)
                XCTAssertTrue(app.buttons["demo.nextExample"].isHittable)
                XCTAssertLessThan(viewport.maxY, app.buttons["demo.nextExample"].frame.minY)
                if type == .chooseDigital || type == .setDigital {
                    let analog = app.descendants(matching: .any)["demo.analog"].frame
                    let digital = app.descendants(matching: .any)["demo.digital"].frame
                    XCTAssertGreaterThan(analog.width, 320)
                    XCTAssertTrue(viewport.insetBy(dx: -1, dy: -1).contains(analog))
                    XCTAssertTrue(viewport.insetBy(dx: -1, dy: -1).contains(digital))
                    if orientation == .landscapeLeft {
                        XCTAssertLessThan(analog.maxX, digital.minX)
                    } else {
                        XCTAssertLessThan(analog.maxY, digital.minY)
                    }
                }
                saveScreenshot("tablet-example-\(type.rawValue)-\(orientation.rawValue)")
                let fixedActions = ready.frame
                tap("demo.nextExample")
                XCTAssertEqual(ready.frame, fixedActions)
            }
        }
    }

    func testExampleActionsStayFixedAcrossAllQuestionTypes() {
        for type in DinoPracticeQuestion.allCases {
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.example-layout.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
            app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = type.rawValue
            app.launchArguments = ["-settings.languageOverride", "en", "-AppleICUForce24HourTime", "YES"]
            app.launch()
            tap("question.example")
            let another = app.buttons["demo.nextExample"]
            let heading = app.staticTexts["demo.heading"]
            XCTAssertTrue(another.waitForExistence(timeout: 5))
            let nextFrame = another.frame
            let headingFrame = heading.frame
            let lessonFrame = app.scrollViews["demo.content"].frame
            XCTAssertEqual(headingFrame.midX, app.frame.midX, accuracy: 1, "\(type) centres the heading text itself")
            XCTAssertTrue(another.isHittable)
            for _ in 0..<3 {
                tap("demo.nextExample")
                XCTAssertEqual(another.frame, nextFrame, "\(type) reserves its action row before refresh")
                XCTAssertEqual(heading.frame, headingFrame, "\(type) keeps the modal in place")
                let refreshedLesson = app.scrollViews["demo.content"].frame
                // AX can round identical geometry differently at fractional points.
                for (actual, expected) in zip(
                    [refreshedLesson.minX, refreshedLesson.minY, refreshedLesson.width, refreshedLesson.height],
                    [lessonFrame.minX, lessonFrame.minY, lessonFrame.width, lessonFrame.height]
                ) {
                    XCTAssertEqual(actual, expected, accuracy: 0.1, "\(type) keeps the lesson viewport in place")
                }
            }
            app.scrollViews["demo.content"].swipeUp()
            XCTAssertEqual(another.frame, nextFrame, "\(type) scrolls only the explanation")
            XCTAssertTrue(another.isHittable)
            saveScreenshot("stable-example-\(type.rawValue)")
        }
    }

    func testCompactClockExamplesKeepTheirActionsVisible() {
        for type in [DinoPracticeQuestion.setDigital, .setAnalog, .read24Hour, .timeSequence] {
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.compact-example.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
            app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = type.rawValue
            app.launchEnvironment["DINO_TEST_PRACTICE_CHALLENGE"] = type == .timeSequence ? "1" : nil
            app.launchArguments = ["-settings.languageOverride", "en", "-AppleICUForce24HourTime", "YES"]
            app.launch()
            if type == .timeSequence {
                XCTAssertTrue(app.buttons["question.option.3"].waitForExistence(timeout: 8))
                let viewport = app.scrollViews["game.questions"].frame
                for index in 0..<4 {
                    XCTAssertLessThanOrEqual(app.buttons["question.option.\(index)"].frame.maxY, viewport.maxY)
                }
                saveScreenshot("compact-sequence-four-answers")
            }
            tap("question.example")
            let ready = app.buttons["demo.ready"]
            let another = app.buttons["demo.nextExample"]
            XCTAssertTrue(ready.isHittable)
            XCTAssertTrue(another.isHittable)
            XCTAssertLessThan(another.frame.maxY, ready.frame.minY)
            XCTAssertFalse(app.buttons["demo.confirm"].exists)
            let viewport = app.scrollViews["demo.content"].frame
            if type == .setDigital {
                let analog = app.descendants(matching: .any)["demo.analog"].frame
                let digital = app.descendants(matching: .any)["demo.digital"].frame
                XCTAssertGreaterThanOrEqual(analog.minY, viewport.minY)
                XCTAssertLessThanOrEqual(digital.maxY, viewport.maxY)
                XCTAssertTrue(app.scrollViews["demo.content"].buttons["clock.minute.more"].isHittable,
                              app.scrollViews["demo.content"].debugDescription)
            }
            if type == .read24Hour {
                let analog = app.descendants(matching: .any)["demo.24Hour.analog"]
                let digital = app.descendants(matching: .any)["demo.targetClock"]
                XCTAssertEqual(analog.label, digital.label)
                for hour in Array(13...23) + [0] {
                    let label = app.staticTexts["demo.24Hour.hour.\(hour)"]
                    XCTAssertEqual(label.label, String(format: "%02d", hour))
                    XCTAssertGreaterThanOrEqual(label.frame.minX, viewport.minX)
                    XCTAssertLessThanOrEqual(label.frame.maxX, viewport.maxX)
                }
            }
            XCTAssertFalse(app.staticTexts["demo.sequence.hint"].exists)
            XCTAssertFalse(app.staticTexts["demo.arithmetic.hint"].exists)
            saveScreenshot("compact-example-\(type.rawValue)")
            tap("demo.nextExample")
            XCTAssertTrue(ready.isHittable)
            saveScreenshot("compact-example-refreshed-\(type.rawValue)")
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
                changeClockToWrongTime(question.kind, target: question.target)
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

    func testSupportPagesFollowLanguageAndRequireParentGate() {
        for code in ["nl", "en"] {
            launchUsingDeviceLanguage(code, locale: code == "nl" ? "nl_NL" : "en_GB")
            onboard()
            openSettings()
            tap("settings.privacy")
            for (identifier, path) in [("privacy.policy", "privacy"), ("privacy.contact", "contact")] {
                let button = app.buttons[identifier]
                XCTAssertTrue(button.waitForExistence(timeout: 5))
                XCTAssertEqual(button.value as? String, "https://www.hakketjak.com/dino-time/\(path)/#\(code)")
                tap(identifier)
                XCTAssertTrue(app.textFields["friends.parentAnswer"].waitForExistence(timeout: 5))
                XCTAssertFalse(app.buttons["friends.parentContinue"].isEnabled)
                tap("friends.parentCancel")
                XCTAssertTrue(button.waitForExistence(timeout: 5))
            }
            XCTAssertFalse(app.staticTexts[code == "nl"
                ? "Contactgegevens voor deze game zijn nog niet beschikbaar. Je kunt Game Center-profielen rechtstreeks bij Apple melden."
                : "Contact details for this game are not available yet. You can report Game Center profiles directly to Apple."].exists)
            saveScreenshot("support-pages-\(code)")
        }
    }

    func testFriendsOptionalAndParentGate() {
        onboard()
        tap("map.friends")
        let connect = app.buttons["friends.connect"]
        XCTAssertTrue(connect.waitForExistence(timeout: 5))
        XCTAssertEqual(connect.label, "Voeg je eerste vriend toe")
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
        XCTAssertTrue(app.buttons["header.stars"].staticTexts["3"].waitForExistence(timeout: 5))
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

    func testFriendsScreenShowsListAndOpensProfile() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_SOCIAL"] = "fixtures"
        app.launch()
        onboard()
        openSettings()
        tap("settings.gameCenter")
        let profile = app.buttons["friends.profile.test-0"]
        XCTAssertTrue(profile.waitForExistence(timeout: 5))
        saveScreenshot("friends-list")
        profile.tap()
        XCTAssertTrue(app.staticTexts["Sophie"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let info = app.buttons["friends.scoreInfo"]
        for _ in 0..<4 {
            if info.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(info.isHittable)
        XCTAssertFalse(app.buttons["friends.onlineVisibility"].exists)
        XCTAssertEqual(app.switches["friends.share"].label, "Toon mijn score")
        saveScreenshot("friends-permissions")
        tap("friends.scoreInfo")
        let scoreHelp = app.alerts.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "alleen je level"))
        XCTAssertTrue(scoreHelp.firstMatch.waitForExistence(timeout: 5))
        app.alerts.buttons.firstMatch.tap()
        XCTAssertFalse(app.buttons["friends.settings"].exists)
        tap("friends.signOut")
        let disconnect = app.alerts.buttons["friends.disconnect"].firstMatch
        XCTAssertTrue(disconnect.waitForExistence(timeout: 5))
        disconnect.tap()
        XCTAssertTrue(app.buttons["friends.connect"].waitForExistence(timeout: 5))
        XCTAssertFalse(profile.exists)
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
            var answer = right ? question.target : ClockTime(hour: ClockTime.shiftedHour(question.target.hour, by: 1))
            let initialHour = question.target.hour % 12 == 0 ? 1 : 12
            if !right && answer.hour % 12 == initialHour % 12 {
                answer = ClockTime(hour: ClockTime.shiftedHour(answer.hour, by: 1))
            }
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
                       StarCalculator.stars(correct: count, questionCount: level.questionCount) == 2)
        XCTAssertEqual(app.descendants(matching: .any)["dino.openingJump"].exists,
                       StarCalculator.stars(correct: count, questionCount: level.questionCount) == 1)
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
        play(10, correct: 6)
        XCTAssertEqual(app.buttons["result.next"].label, "Naar de volgende wereld")
        XCTAssertFalse(app.buttons["result.map"].exists)
        XCTAssertTrue(app.staticTexts["6/10"].exists)
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
            (self.app.frame.width > self.app.frame.height)
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

    func testTabletWelcomeClockPagesKeepControlsAndActionTogether() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad && app.frame.width >= 760)
        tap("onboarding.next")

        for page in ["analog", "digital"] {
            let preview = app.descendants(matching: .any)["theme.\(page).preview"].firstMatch
            let card = app.otherElements["theme.welcome.optionsCard"].firstMatch
            let action = app.buttons[page == "analog" ? "onboarding.next" : "onboarding.customClock"]
            let reset = app.buttons[page == "analog" ? "theme.resetAnalogStyle" : "theme.resetDigitalStyle"]

            for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
                XCUIDevice.shared.orientation = orientation
                let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    let viewport = self.app.frame
                    let horizontal = viewport.width > viewport.height
                    return horizontal == (orientation == .landscapeLeft) && card.exists && preview.exists && action.isHittable
                }, object: nil)
                wait(for: [ready], timeout: 8)
                XCTAssertTrue(reset.isHittable)
                XCTAssertEqual(action.frame.minX, card.frame.minX, accuracy: 2)
                XCTAssertEqual(action.frame.maxX, card.frame.maxX, accuracy: 2)
                XCTAssertEqual(action.frame.minY - card.frame.maxY, 16, accuracy: 2)
                if orientation == .portrait {
                    let title = app.staticTexts["onboarding.title"]
                    XCTAssertLessThan(preview.frame.minY - title.frame.maxY, 44)
                    XCTAssertLessThanOrEqual(preview.frame.maxY, card.frame.minY)
                } else {
                    XCTAssertLessThan(preview.frame.maxX, card.frame.minX)
                }
                saveScreenshot("welcome-\(page)-\(orientation == .portrait ? "portrait" : "landscape")")
            }
            action.tap()
        }

        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 10))
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
        waitForMapOpeningToFinish()
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
        if tablet && app.frame.width >= 760 {
            let reset = app.buttons["settings.reset"]
            XCTAssertGreaterThanOrEqual(reset.frame.height, 71)
            XCTAssertEqual(done.frame.width, reset.frame.width + 24, accuracy: 2, "Klaar aligns with the outer card")
            XCTAssertLessThan(done.frame.minY - reset.frame.maxY, 50, "Klaar stays next to the settings list")
        } else {
            XCTAssertGreaterThan(done.frame.minY, app.frame.height * 0.7)
        }
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

    func testTabletSettingsFitsCompactSheet() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad && app.frame.width >= 760)
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "1"
        app.launch()
        openSettings()

        let viewport = app.scrollViews["settings.options"].frame
        let title = app.staticTexts["settings.title"].frame
        let reset = app.buttons["settings.reset"].frame
        let done = app.buttons["settings.done"]
        XCTAssertTrue(done.isHittable)
        XCTAssertTrue(viewport.insetBy(dx: -2, dy: -2).contains(done.frame))
        XCTAssertEqual(done.frame.width, reset.width + 24, accuracy: 2)
        XCTAssertEqual(reset.height, 72, accuracy: 2)
        if #available(iOS 18, *) {
            XCTAssertLessThan(viewport.height, app.frame.height - 90)
        }
        XCTAssertLessThan(title.minY - viewport.minY, 70)
        XCTAssertLessThan(viewport.maxY - done.frame.maxY, 65)
        saveScreenshot("tablet-settings-compact-sheet")
    }

    func testSettingsPreferencesPersist() {
        onboard()
        openSettings()
        let sound = app.descendants(matching: .any)["settings.soundEffects"].switches.firstMatch
        let haptics = app.descendants(matching: .any)["settings.haptics"].switches.firstMatch
        let spokenTitle = app.descendants(matching: .any)["settings.speakQuestionTitle"].switches.firstMatch
        let contrast = app.descendants(matching: .any)["settings.highContrast"].switches.firstMatch
        let cloud = app.descendants(matching: .any)["settings.icloudSync"].switches.firstMatch
        XCTAssertTrue(sound.waitForExistence(timeout: 5))
        XCTAssertEqual(sound.value as? String, "1")
        XCTAssertEqual(haptics.value as? String, "1")
        XCTAssertEqual(spokenTitle.value as? String, "0")
        XCTAssertEqual(contrast.value as? String, "0")
        XCTAssertEqual(cloud.value as? String, "0")
        saveScreenshot("settings-preferences")
        tap("settings.soundEffects"); tap("settings.haptics")
        tap("settings.highContrast"); tap("settings.icloudSync")
        XCTAssertEqual(sound.value as? String, "0")
        XCTAssertEqual(haptics.value as? String, "0")
        XCTAssertEqual(spokenTitle.value as? String, "0")
        XCTAssertEqual(contrast.value as? String, "1")
        XCTAssertEqual(cloud.value as? String, "1")
        tap("settings.icloudInfo")
        let cloudHelp = app.staticTexts["settings.icloudStatus"]
        XCTAssertTrue(cloudHelp.waitForExistence(timeout: 5))
        XCTAssertTrue(cloudHelp.label.contains("iCloud"))
        saveScreenshot("settings-high-contrast")
        app.terminate(); app.launch()
        waitForMapOpeningToFinish()
        openSettings()
        XCTAssertTrue(sound.waitForExistence(timeout: 5))
        XCTAssertEqual(sound.value as? String, "0")
        XCTAssertEqual(haptics.value as? String, "0")
        XCTAssertEqual(spokenTitle.value as? String, "0")
        XCTAssertEqual(contrast.value as? String, "1")
        XCTAssertEqual(cloud.value as? String, "1")
        saveScreenshot("settings-restored-before-cloud-toggle")
        tap("settings.icloudSync")
        saveScreenshot("settings-restored-after-cloud-toggle")
        XCTAssertEqual(cloud.value as? String, "0")
        XCUIDevice.shared.orientation = .landscapeLeft
        tap("settings.icloudSync")
        XCTAssertEqual(cloud.value as? String, "1")
        tap("settings.icloudSync")
        XCTAssertEqual(cloud.value as? String, "0")
        saveScreenshot("settings-landscape")
        XCUIDevice.shared.orientation = .portrait
        tap("settings.language")
        tap("language.option.en")
        XCTAssertTrue(app.staticTexts["Sound effects"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Speak the question title"].exists)
        XCTAssertTrue(app.staticTexts["High contrast"].exists)
        saveScreenshot("settings-english")
        app.buttons["Done"].firstMatch.tap()
        begin(10)
        if app.buttons["demo.ready"].exists { tap("demo.ready") }
        var rng = SeededGenerator(seed: seed)
        let question = DinoQuestionGenerator.generate(level: DinoLevelCatalog.level(10)!, attempt: 0, using: &rng)[0]
        let wrong = question.options.firstIndex { $0 != question.target }!
        tap("question.option.\(wrong)")
        XCTAssertTrue(app.descendants(matching: .any)["dino.wrongAnswer"].waitForExistence(timeout: 5))
        if app.buttons["question.showAnswer"].exists {
            XCTAssertEqual(app.buttons["question.showAnswer"].label, "Show answer")
            tap("question.showAnswer")
        } else {
            // With two choices the wrong answer immediately reveals the solution.
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option.")).count, 2)
        }
        XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["question.next"].label, "Next")
        XCTAssertFalse(app.buttons["question.option.0"].isEnabled)
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
        // Rotate the main scene to verify the same companion in the compact HUD.
        tap("header.pause")
        tap("practice.close")
        begin(10)
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscape = NSPredicate { _, _ in (self.app.frame.width > self.app.frame.height) && idle.exists && idle.frame.maxY <= self.app.frame.maxY + 1 }
        expectation(for: landscape, evaluatedWith: nil)
        waitForExpectations(timeout: 8)
        assertCompanionInPortrait(idle)
        XCTAssertGreaterThanOrEqual(idle.frame.width, 52, "The compact HUD keeps a recognizable companion")
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
            if UIDevice.current.userInterfaceIdiom == .phone {
                XCTAssertGreaterThan(viewport.frame.maxY, app.frame.maxY - 150, "The former bottom Dino space is available to questions")
            }
        }
    }

    private func assertStickyAnswerButton(_ button: XCUIElement) {
        XCTAssertTrue(button.isHittable)
        XCTAssertEqual(button.frame.midX, app.frame.midX, accuracy: 1)
        if UIDevice.current.userInterfaceIdiom == .phone {
            XCTAssertGreaterThan(button.frame.minY, app.frame.maxY - 150)
        } else {
            let settings = app.buttons["question.dayPart.settings"]
            let firstAction = settings.exists ? settings : button
            XCTAssertLessThanOrEqual(firstAction.frame.minY - app.scrollViews["game.questions"].frame.maxY, 32,
                                     "The tablet action stays close to its exercise")
        }
        XCTAssertLessThanOrEqual(button.frame.maxY, app.frame.maxY - 8)
        XCTAssertGreaterThanOrEqual(button.frame.width, min(420, app.frame.width - 72))
        XCTAssertLessThanOrEqual(app.scrollViews["game.questions"].frame.maxY, button.frame.minY)
    }

    func testTwoAnalogChoicesKeepReadableFeedbackProportions() throws {
        app.terminate()
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = "chooseAnalog"
        app.launchEnvironment["DINO_TEST_PRACTICE_TIME"] = "whole"
        app.launch()

        let clock = app.descendants(matching: .any)["question.targetClock"].firstMatch
        XCTAssertTrue(clock.waitForExistence(timeout: 8))
        let choices = (0..<2).map { app.buttons["question.option.\($0)"] }
        XCTAssertFalse(app.buttons["question.option.2"].exists)
        XCTAssertGreaterThan(clock.frame.width, choices[0].frame.width * 0.58)

        var generator = DinoPracticeGenerator(configuration: .init(time: .whole, order: .specific(.chooseAnalog)), seed: seed)
        let question = generator.next(index: 0)
        let wrong = try XCTUnwrap(question.responses.firstIndex { $0 != question.expectedAnswer })
        choices[wrong].tap()
        XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
        checkQuestionFits(.chooseAnalog, name: "portrait-feedback")
        saveScreenshot("two-analog-choices-feedback")
    }

    /// Keep the first error visible so recordings include the actual transition, not only Show answer.
    func testReadingFeedbackMotionInPortrait() {
        let requested = ProcessInfo.processInfo.environment["DINO_LAYOUT_TYPES"]?.split(separator: ",").map(String.init)
        for type in [DinoPracticeQuestion.chooseAnalog, .chooseDigital, .trueFalse, .readDigital, .spokenTime, .setDigital]
            where requested == nil || requested!.contains(type.rawValue) {
            app.terminate()
            XCUIDevice.shared.orientation = .portrait
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.feedback-motion.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
            app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = type.rawValue
            app.launchEnvironment["DINO_TEST_PRACTICE_CHALLENGE"] = "1"
            app.launch()
            XCTAssertTrue(app.staticTexts.matching(identifier: "question.title").firstMatch.waitForExistence(timeout: 10))
            checkQuestionFits(type, name: "portrait")
            var generator = DinoPracticeGenerator(configuration: .init(time: .minutes, order: .specific(type)), seed: seed)
            let question = generator.next(index: 3, difficultyForKind: { _ in .challenge })
            if type == .setDigital {
                changeClockToWrongTime(.setDigital, target: question.target)
                tap("question.confirm")
            } else {
                let wrong = question.responses.firstIndex { $0 != question.expectedAnswer }!
                tap("question.option.\(wrong)")
            }
            XCTAssertTrue(app.buttons["question.showAnswer"].exists || app.buttons["question.next"].waitForExistence(timeout: 3))
            checkQuestionFits(type, name: "portrait-feedback")
            let clocks = app.descendants(matching: .any).matching(identifier: "question.targetClock")
            if [.chooseDigital, .trueFalse, .readDigital].contains(type) {
                XCTAssertEqual(clocks.count, 1, "The existing question clock persists when its guide appears")
            }
        }
    }

    func testSpokenReadingFeedbackUsesOnlyItsVisibleHeight() {
        for time in [DinoPracticeTime.whole, .minutes] {
            for type in [DinoPracticeQuestion.trueFalse, .readDigital] {
                app.terminate()
                XCUIDevice.shared.orientation = .portrait
                app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.tight-guide.\(UUID().uuidString)"
                app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
                app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = type.rawValue
                app.launchEnvironment["DINO_TEST_PRACTICE_TIME"] = time.rawValue
                app.launchEnvironment["DINO_TEST_PRACTICE_CHALLENGE"] = "1"
                app.launch()
                XCTAssertTrue(app.staticTexts["question.title"].waitForExistence(timeout: 10))
                checkQuestionFits(type, name: "portrait")
                var generator = DinoPracticeGenerator(configuration: .init(time: time, order: .specific(type)), seed: seed)
                let question = generator.next(index: 3, difficultyForKind: { _ in .challenge })
                answerPracticeWrong(question)
                checkQuestionFits(type, name: "portrait-feedback")
                let clock = app.descendants(matching: .any).matching(identifier: "question.targetClock").firstMatch.frame
                var heading = app.staticTexts["question.title"].frame
                let correction = app.descendants(matching: .any)["question.correctStatement"]
                if correction.exists { heading = heading.union(correction.frame) }
                XCTAssertLessThan(clock.height, clock.width * 0.9,
                                  "The speech scale needs a wide rectangle, not an empty square")
                XCTAssertGreaterThanOrEqual(clock.minY, heading.maxY,
                                           "The tight scale stays below the title")
                XCTAssertLessThanOrEqual(clock.minY - heading.maxY, 32,
                                         "Explanation must not add unused space above the clock")
                saveScreenshot("tight-guide-\(type.rawValue)-\(time.rawValue)")
            }
        }
    }

    func testAllQuestionTypesFitTabletViewport() {
        continueAfterFailure = true
        let requested = ProcessInfo.processInfo.environment["DINO_LAYOUT_TYPES"]?.split(separator: ",").map(String.init)
        let types = DinoPracticeQuestion.allCases.filter { requested == nil || requested!.contains($0.rawValue) }
        for type in types {
            app.terminate()
            XCUIDevice.shared.orientation = .portrait
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.adaptive-layout.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
            app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = type.rawValue
            app.launchEnvironment["DINO_TEST_PRACTICE_CHALLENGE"] = "1"
            app.launch()
            XCTAssertTrue(app.staticTexts["question.title"].waitForExistence(timeout: 10))
            checkQuestionFits(type, name: "portrait")
            XCUIDevice.shared.orientation = .landscapeLeft
            let rotated = NSPredicate { _, _ in self.app.frame.width > self.app.frame.height }
            expectation(for: rotated, evaluatedWith: nil)
            waitForExpectations(timeout: 8)
            checkQuestionFits(type, name: "landscape")
            var generator = DinoPracticeGenerator(configuration: .init(time: .minutes, order: .specific(type)), seed: seed)
            let question = generator.next(index: 3, difficultyForKind: { _ in .challenge })
            answerPracticeWrong(question)
            checkQuestionFits(type, name: "landscape-feedback")
            XCUIDevice.shared.orientation = .portrait
            let portrait = NSPredicate { _, _ in self.app.frame.width < self.app.frame.height }
            expectation(for: portrait, evaluatedWith: nil)
            waitForExpectations(timeout: 8)
            checkQuestionFits(type, name: "portrait-feedback")
        }
    }

    func testMatchingRotatesItsDragEndpointsWithLandscape() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        app.terminate()
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.matching-orientation.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = "match"
        app.launchEnvironment["DINO_TEST_PRACTICE_CHALLENGE"] = "1"
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launch()
        XCTAssertTrue(app.staticTexts["question.title"].waitForExistence(timeout: 10))
        var generator = DinoPracticeGenerator(configuration: .init(time: .minutes, order: .specific(.match)), seed: seed)
        let question = generator.next(index: 3, difficultyForKind: { _ in .challenge })
        let clocks = (0..<3).map { app.buttons["question.match.clock.\($0)"] }
        let times = (0..<3).map { app.buttons["question.match.time.\($0)"] }
        let targets = question.relatedTimes.map { question.options.firstIndex(of: $0)! }
        clocks[0].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: times[targets[0]].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)))
        times[targets[1]].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: clocks[1].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.92)))
        tap("question.match.clock.2")
        tap("question.match.time.\(targets[2])")
        XCTAssertTrue(app.buttons["question.confirm"].isEnabled)
        for orientation in [UIDeviceOrientation.landscapeLeft, .portrait, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            let horizontal = orientation != .portrait
            let rotated = NSPredicate { _, _ in
                horizontal ? self.app.frame.width > self.app.frame.height : self.app.frame.width < self.app.frame.height
            }
            expectation(for: rotated, evaluatedWith: nil); waitForExpectations(timeout: 8)
            RunLoop.current.run(until: Date().addingTimeInterval(0.6))
            for index in 0..<3 {
                let source = clocks[index].frame
                let target = times[targets[index]].frame
                let marker = app.descendants(matching: .any)["question.match.line.\(index)"]
                XCTAssertTrue(marker.exists, "Rotating keeps every connection")
                let start = CGPoint(x: horizontal ? source.midX : source.maxX, y: horizontal ? source.maxY : source.midY)
                let end = CGPoint(x: horizontal ? target.midX : target.minX, y: horizontal ? target.minY : target.midY)
                XCTAssertEqual(marker.frame.midX, (start.x + end.x) / 2, accuracy: 2)
                XCTAssertEqual(marker.frame.midY, (start.y + end.y) / 2, accuracy: 2)
                XCTAssertTrue(clocks[index].isHittable && times[targets[index]].isHittable)
            }
            saveScreenshot("matching-connected-\(orientation.rawValue)")
        }
    }

    func testSequenceMissWaitsWithTwoChoicesAndCorrectRetryAdvancesWithFour() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.sequence-retry.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = "timeSequence"
        app.launchEnvironment.removeValue(forKey: "DINO_TEST_PRACTICE_CHALLENGE")
        app.launch()
        XCTAssertTrue(app.staticTexts["question.title"].waitForExistence(timeout: 10))
        func questionNumber(_ value: Int) -> XCUIElement {
            app.staticTexts.matching(identifier: "header.questions")
                .matching(NSPredicate(format: "label == %@", String(value))).firstMatch
        }
        var generator = DinoPracticeGenerator(configuration: .init(time: .minutes, order: .specific(.timeSequence)), seed: seed)
        let first = generator.next(index: 0)
        XCTAssertEqual(first.responses.count, 2)
        XCTAssertFalse(app.descendants(matching: .any)["question.sequence.step.0"].exists)
        tap("question.option.\(first.responses.firstIndex { $0 != first.expectedAnswer }!)")
        XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["question.sequence.step.0"].exists)
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))
        XCTAssertTrue(questionNumber(1).exists, "A two-choice miss waits for Next with its explanation")
        saveScreenshot("sequence-two-choices-miss-waits")
        tap("question.next")
        XCTAssertTrue(questionNumber(2).waitForExistence(timeout: 5))
        let second = generator.next(index: 1, difficultyForKind: { _ in .introduction })
        tap("question.option.\(second.responses.firstIndex(of: second.expectedAnswer)!)")
        XCTAssertTrue(questionNumber(3).waitForExistence(timeout: 5))
        let third = generator.next(index: 2, difficultyForKind: { _ in .familiar })
        XCTAssertEqual(third.responses.count, 4)
        tap("question.option.\(third.responses.firstIndex { $0 != third.expectedAnswer }!)")
        XCTAssertTrue(app.buttons["question.showAnswer"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["question.sequence.step.0"].exists)
        saveScreenshot("sequence-four-choices-first-miss")
        tap("question.option.\(third.responses.firstIndex(of: third.expectedAnswer)!)")
        XCTAssertTrue(questionNumber(4).waitForExistence(timeout: 6), "A correct retry adds no new explanation and advances automatically")
        XCTAssertFalse(app.buttons["question.next"].exists)
        XCTAssertFalse(app.buttons["question.showAnswer"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["question.sequence.step.0"].exists, "The next question starts without helpers")
    }

    func testVerticalSequenceClocksStayCenteredWithSideHints() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.centered-sequence.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = "timeSequence"
        app.launchEnvironment["DINO_TEST_PRACTICE_CHALLENGE"] = "1"
        app.launchArguments = ["-settings.languageOverride", "en", "-AppleICUForce24HourTime", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["question.option.3"].waitForExistence(timeout: 10))
        func checkClocks(prefix: String) {
            for index in 0..<3 {
                let clock = app.descendants(matching: .any)["\(prefix).sequence.clock.\(index)"]
                XCTAssertEqual(clock.frame.midX, app.frame.midX, accuracy: 1,
                               "The clock column stays centered independently of the side hints")
            }
        }
        checkClocks(prefix: "question")
        let viewport = app.scrollViews["game.questions"].frame
        for index in 0..<4 {
            XCTAssertLessThanOrEqual(app.buttons["question.option.\(index)"].frame.maxY, viewport.maxY)
        }
        var generator = DinoPracticeGenerator(configuration: .init(time: .minutes, order: .specific(.timeSequence)),
                                              seed: seed, language: "en")
        let question = generator.next(index: 3, difficultyForKind: { _ in .challenge })
        tap("question.option.\(question.responses.firstIndex { $0 != question.expectedAnswer }!)")
        XCTAssertTrue(app.buttons["question.showAnswer"].waitForExistence(timeout: 5))
        checkClocks(prefix: "question")
        XCTAssertEqual(app.staticTexts["question.sequence.unknown"].frame.midX, app.frame.midX, accuracy: 1)
        for index in 0..<2 {
            let clock = app.descendants(matching: .any)["question.sequence.clock.\(index)"].frame
            let hint = app.descendants(matching: .any)["question.sequence.step.\(index)"].frame
            XCTAssertGreaterThan(hint.minX, clock.maxX)
            XCTAssertLessThanOrEqual(hint.maxX, viewport.maxX)
        }
        saveScreenshot("sequence-centered-side-hints")
        tap("question.example")
        checkClocks(prefix: "demo")
        XCTAssertEqual(app.descendants(matching: .any)["demo.answer"].frame.midX, app.frame.midX, accuracy: 1)
        saveScreenshot("sequence-centered-example")
        tap("demo.nextExample")
        checkClocks(prefix: "demo")
        saveScreenshot("sequence-centered-example-refreshed")
    }

    func testSequenceTurnsItsArrowsWithLandscape() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        app.terminate()
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.sequence-orientation.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = "timeSequence"
        app.launchEnvironment["DINO_TEST_PRACTICE_CHALLENGE"] = "1"
        app.launch()
        XCTAssertTrue(app.staticTexts["question.title"].waitForExistence(timeout: 10))
        func checkSequence(horizontal: Bool, correction: Bool) {
            RunLoop.current.run(until: Date().addingTimeInterval(0.6))
            let clocks = (0..<3).map { app.descendants(matching: .any)["question.sequence.clock.\($0)"].frame }
            for index in 0..<2 {
                let arrow = app.descendants(matching: .any)["question.sequence.arrow.\(index)"].frame
                if horizontal {
                    XCTAssertLessThan(clocks[index].maxX, arrow.midX)
                    XCTAssertLessThan(arrow.midX, clocks[index + 1].minX)
                    XCTAssertEqual(clocks[index].midY, clocks[index + 1].midY, accuracy: 1)
                } else {
                    XCTAssertLessThan(clocks[index].maxY, arrow.midY)
                    XCTAssertLessThan(arrow.midY, clocks[index + 1].minY)
                }
                if correction {
                    let step = app.descendants(matching: .any)["question.sequence.step.\(index)"]
                    XCTAssertTrue(step.waitForExistence(timeout: 4))
                    if horizontal {
                        XCTAssertLessThan(step.frame.maxY, clocks[index].minY)
                        XCTAssertGreaterThan(step.frame.midX, clocks[index].midX)
                        XCTAssertLessThan(step.frame.midX, clocks[index + 1].midX)
                    } else { XCTAssertGreaterThan(step.frame.minX, clocks[index].maxX) }
                }
            }
            let unknown = app.staticTexts["question.sequence.unknown"].frame
            if horizontal { XCTAssertEqual(unknown.midY, clocks[0].midY, accuracy: 1) }
        }
        checkSequence(horizontal: false, correction: false)
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscape = NSPredicate { _, _ in self.app.frame.width > self.app.frame.height }
        expectation(for: landscape, evaluatedWith: nil); waitForExpectations(timeout: 8)
        checkSequence(horizontal: true, correction: false)
        saveScreenshot("sequence-horizontal-before-answer")
        var generator = DinoPracticeGenerator(configuration: .init(time: .minutes, order: .specific(.timeSequence)), seed: seed)
        let question = generator.next(index: 3, difficultyForKind: { _ in .challenge })
        tap("question.option.\(question.responses.firstIndex { $0 != question.expectedAnswer }!)")
        XCTAssertEqual(question.responses.count, 4)
        XCTAssertTrue(app.buttons["question.showAnswer"].waitForExistence(timeout: 5))
        checkSequence(horizontal: true, correction: true)
        XCTAssertTrue(app.buttons["question.option.\(question.responses.firstIndex(of: question.expectedAnswer)!)"].isEnabled,
                      "The first mistake shows the differences while the remaining answers stay available")
        saveScreenshot("sequence-horizontal-first-mistake-helpers")
        tap("question.showAnswer")
        XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
        checkSequence(horizontal: true, correction: true)
        saveScreenshot("sequence-horizontal-difference-arrows")
        XCUIDevice.shared.orientation = .landscapeRight
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        checkSequence(horizontal: true, correction: true)
        XCUIDevice.shared.orientation = .portrait
        let portrait = NSPredicate { _, _ in self.app.frame.width < self.app.frame.height }
        expectation(for: portrait, evaluatedWith: nil); waitForExpectations(timeout: 8)
        checkSequence(horizontal: false, correction: true)
        saveScreenshot("sequence-portrait-difference-arrows")
    }

    func testLandscapeClockControlsStayCenteredBeforeAndAfterAnswering() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        for type in [DinoPracticeQuestion.setDigital, .setAnalog, .advanceAnalog] {
            app.terminate()
            XCUIDevice.shared.orientation = .portrait
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.centered-clock.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
            app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = type.rawValue
            app.launchEnvironment["DINO_TEST_PRACTICE_CHALLENGE"] = "1"
            app.launch()
            XCTAssertTrue(app.buttons["question.confirm"].waitForExistence(timeout: 10))
            let input = app.descendants(matching: .any)[type == .setDigital ? "question.digitalControl" : "question.analogControl"]
            let reference = app.descendants(matching: .any)[type == .advanceAnalog ? "question.startClock" : "question.targetClock"]
            for answered in [false, true] {
                if answered {
                    tap(type == .setDigital ? "clock.hour.more" : "question.analog.more")
                    tap("question.confirm")
                    XCTAssertTrue(app.buttons["question.next"].waitForExistence(timeout: 5))
                }
                for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight, .portrait] {
                    XCUIDevice.shared.orientation = orientation
                    let horizontal = orientation != .portrait
                    let rotated = NSPredicate { _, _ in
                        horizontal ? self.app.frame.width > self.app.frame.height : self.app.frame.width < self.app.frame.height
                    }
                    expectation(for: rotated, evaluatedWith: nil)
                    waitForExpectations(timeout: 8)
                    RunLoop.current.run(until: Date().addingTimeInterval(0.6))
                    let title = app.staticTexts["question.title"].frame
                    let viewport = app.scrollViews["game.questions"].frame.insetBy(dx: -2, dy: -2)
                    XCTAssertTrue(viewport.contains(input.frame))
                    if answered {
                        let correct = app.descendants(matching: .any)["question.correctClock"]
                        XCTAssertTrue(correct.exists)
                        XCTAssertLessThan(input.frame.maxX, correct.frame.minX)
                        XCTAssertEqual(input.frame.union(correct.frame).midX, title.midX, accuracy: 2)
                        XCTAssertTrue(viewport.contains(correct.frame))
                    } else {
                        XCTAssertEqual(input.frame.midX, title.midX, accuracy: 2)
                        XCTAssertEqual(reference.frame.midX, title.midX, accuracy: 2)
                        XCTAssertLessThanOrEqual(reference.frame.maxY, input.frame.minY)
                        let identifiers = type == .setDigital
                            ? ["clock.hour.less", "clock.hour.more", "clock.minute.less", "clock.minute.more"]
                            : ["question.analog.less", "question.analog.more"]
                        let handSelectors = ["question.hand.hours", "question.hand.minutes"]
                            .map { app.buttons[$0] }.filter(\.exists)
                        let controls = (identifiers.map { app.buttons[$0] } + handSelectors)
                            .reduce(CGRect.null) { $0.union($1.frame) }
                        XCTAssertEqual(controls.midX, title.midX, accuracy: 2)
                    }
                    saveScreenshot("centered-clock-\(type.rawValue)-\(answered ? "answered" : "question")-\(orientation.rawValue)")
                }
            }
        }
    }

    func testTabletAnswerFeedbackStaysAboveFooter() {
        for type in [DinoPracticeQuestion.chooseAnalog, .spokenTime, .read24Hour, .timeZone, .dayPart, .setDigital, .setAnalog, .advanceAnalog] {
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.ipad-feedback.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
            app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = type.rawValue
            app.launchEnvironment["DINO_TEST_PRACTICE_CHALLENGE"] = "1"
            app.launch()
            XCTAssertTrue(app.staticTexts["question.title"].waitForExistence(timeout: 10))
            var generator = DinoPracticeGenerator(configuration: .init(time: .minutes, order: .specific(type)), seed: seed)
            let question = generator.next(index: 3, difficultyForKind: { _ in .challenge })
            if type == .setDigital {
                tap("clock.hour.more")
                tap("question.confirm")
            } else if [.setAnalog, .advanceAnalog].contains(type) {
                tap("question.analog.more")
                tap("question.confirm")
            } else {
                let wrong = question.responses.firstIndex { $0 != question.expectedAnswer }!
                tap("question.option.\(wrong)")
            }
            if app.buttons["question.showAnswer"].exists { tap("question.showAnswer") }
            let next = app.buttons["question.next"]
            XCTAssertTrue(next.waitForExistence(timeout: 5))
            let orientations: [UIDeviceOrientation] = UIDevice.current.userInterfaceIdiom == .pad ? [.portrait, .landscapeLeft] : [.portrait]
            for orientation in orientations {
                XCUIDevice.shared.orientation = orientation
                let rotated = NSPredicate { _, _ in
                    orientation == .portrait ? self.app.frame.width < self.app.frame.height : self.app.frame.width > self.app.frame.height
                }
                expectation(for: rotated, evaluatedWith: nil)
                waitForExpectations(timeout: 8)
                RunLoop.current.run(until: Date().addingTimeInterval(0.5))
                assertStickyAnswerButton(next)
                let viewport = app.scrollViews["game.questions"].frame
                for option in app.buttons.allElementsBoundByIndex.filter({ $0.identifier.hasPrefix("question.option.") }) {
                    XCTAssertLessThanOrEqual(option.frame.maxY, viewport.maxY + 1, "\(type): feedback stays above Continue")
                }
                for identifier in ["question.analogControl", "question.correctClock"] {
                    let clock = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
                    if clock.exists { XCTAssertLessThanOrEqual(clock.frame.maxY, viewport.maxY + 1) }
                }
                if [.setDigital, .setAnalog, .advanceAnalog].contains(type), self.app.frame.width >= 664 {
                    let correct = app.descendants(matching: .any)["question.correctClock"]
                    let input = app.descendants(matching: .any)[type == .setDigital ? "question.digitalControl" : "question.analogControl"]
                    XCTAssertLessThan(input.frame.maxX, correct.frame.minX, "The submitted clock stays left of the correct clock")
                }
                saveScreenshot("ipad-feedback-\(type.rawValue)-\(orientation.rawValue)")
            }
        }
    }

    func testTabletMapZoomKeepsCurrentLevelInFocus() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        app.terminate()
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.ipad-map.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "34"
        app.launch()
        XCTAssertTrue(app.buttons["header.level"].waitForExistence(timeout: 10))
        waitForMapOpeningToFinish()
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            let rotated = NSPredicate { _, _ in
                orientation == .portrait ? self.app.frame.width < self.app.frame.height : self.app.frame.width > self.app.frame.height
            }
            expectation(for: rotated, evaluatedWith: nil)
            waitForExpectations(timeout: 8)
            tap("header.level")
            RunLoop.current.run(until: Date().addingTimeInterval(1))
            let node = app.buttons["map.level.35"]
            let dino = app.descendants(matching: .any)["map.dino.35"]
            XCTAssertTrue(node.isHittable)
            XCTAssertGreaterThanOrEqual(node.frame.width, 85)
            XCTAssertGreaterThanOrEqual(dino.frame.width, 230)
            XCTAssertGreaterThan(dino.frame.minY, app.buttons["header.level"].frame.maxY)
            XCTAssertLessThan(dino.frame.maxY, app.frame.maxY)
            let scroll = app.scrollViews["map.route"]
            XCTAssertEqual(scroll.frame.minX, app.frame.minX, accuracy: 1)
            XCTAssertEqual(scroll.frame.maxX, app.frame.maxX, accuracy: 1)
            saveScreenshot("ipad-map-focus-\(orientation.rawValue)")
        }
    }

    func testTabletMapFocusSurvivesRotationDuringLongTrip() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else { throw XCTSkip("iPad rotation") }
        app.terminate()
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.rotating-map-trip.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "34"
        app.launch()
        waitForMapOpeningToFinish()
        let firstWorld = app.descendants(matching: .any)["header.world.1"].firstMatch
        for _ in 0..<30 {
            if firstWorld.exists { break }
            app.swipeDown(velocity: .fast)
        }
        XCTAssertTrue(firstWorld.exists)
        XCTAssertFalse(app.buttons["map.level.35"].isHittable)

        // Rotate immediately after requesting a long return. The destination
        // and its arrival callback must follow the new viewport.
        tap("header.level")
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        let arrived = NSPredicate { _, _ in
            self.app.frame.width > self.app.frame.height
                && self.app.descendants(matching: .any)["map.levelPointer.35"].exists
                && self.app.buttons["map.level.35"].isHittable
        }
        expectation(for: arrived, evaluatedWith: nil)
        waitForExpectations(timeout: 15)
        let level = app.buttons["map.level.35"]
        XCTAssertGreaterThan(level.frame.minY, app.buttons["header.settings"].frame.maxY)
        XCTAssertLessThan(level.frame.maxY, app.frame.maxY)
        level.tap()
        XCTAssertTrue(app.buttons["level.play"].waitForExistence(timeout: 5))
        saveScreenshot("ipad-rotating-map-trip-arrived")
    }

    private func checkQuestionFits(_ type: DinoPracticeQuestion, name: String) {
        RunLoop.current.run(until: Date().addingTimeInterval(0.8))
        let viewport = app.scrollViews["game.questions"].frame.insetBy(dx: -2, dy: -2)
        let title = app.staticTexts.matching(identifier: "question.title").firstMatch
        XCTAssertTrue(app.frame.contains(title.frame), "\(type) \(name): title stays on screen")
        XCTAssertTrue(viewport.contains(title.frame), "The title belongs to the centered lesson in every orientation")
        let answers = app.buttons.allElementsBoundByIndex.filter {
            $0.identifier.hasPrefix("question.option.") || $0.identifier.hasPrefix("question.sort.")
                || $0.identifier.hasPrefix("question.match.clock.") || $0.identifier.hasPrefix("question.match.time.")
                || $0.identifier.hasPrefix("question.spoken.") || $0.identifier.hasPrefix("question.analog.")
                || $0.identifier.hasPrefix("question.hand.") || $0.identifier.hasPrefix("clock.hour.") || $0.identifier.hasPrefix("clock.minute.")
        }
        for answer in answers {
            if type == .setDigital, name.contains("feedback"),
               answer.identifier.hasPrefix("clock.hour.") || answer.identifier.hasPrefix("clock.minute.") {
                // The comparison deliberately hides editing arrows after submission.
                // Some simulator versions retain those hidden buttons in AX snapshots.
                XCTAssertFalse(answer.isHittable, "Submitted clocks cannot still be edited")
                continue
            }
            XCTAssertTrue(viewport.contains(answer.frame), "\(type) \(name): \(answer.identifier) \(answer.frame) exceeds \(viewport)")
            XCTAssertTrue(answer.isHittable, "\(type) \(name): answer is reachable")
        }
        let options = answers.filter { $0.identifier.hasPrefix("question.option.") }
        if options.count == 4 {
            let centers = options.map { $0.frame.midY }.sorted()
            let rowCount = zip(centers, centers.dropFirst()).filter { abs($0 - $1) > 12 }.count + 1
            XCTAssertTrue(rowCount == 1 || rowCount == 2, "Four choices use one or two rows")
        }
        for identifier in ["question.analogControl", "question.digitalControl", "question.targetClock", "question.correctClock",
                           "question.flight.ticket", "question.schedule.card", "question.minutesBetween.card", "question.sequence.unknown"] {
            let display = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
            if display.exists && !display.frame.isEmpty {
                XCTAssertTrue(viewport.contains(display.frame), "\(type) \(name): \(identifier) \(display.frame) exceeds \(viewport)")
            }
        }
        if [.chooseDigital, .trueFalse, .readDigital].contains(type) {
            let clock = app.descendants(matching: .any).matching(identifier: "question.targetClock").firstMatch
            if name == "portrait", clock.exists {
                let upperSize: CGFloat = app.frame.width >= 700 ? 480 : 260
                XCTAssertLessThanOrEqual(clock.frame.width, upperSize, "The unassisted reading clock has a comfortable upper size")
            }
            if app.frame.height > app.frame.width, !options.isEmpty {
                let group = options.reduce(title.frame) { $0.union($1.frame) }
                XCTAssertEqual(group.midY, viewport.midY, accuracy: 8, "Title, clock and answers form one centered group")
                if clock.exists {
                    let gap = options.map { $0.frame.minY }.min()! - clock.frame.maxY
                    XCTAssertLessThanOrEqual(gap, 32, "Spare height must not separate the clock from its answers")
                }
            }
        }
        for id in ["question.confirm", "question.next", "question.showAnswer"] {
            let action = app.buttons[id]
            if action.exists {
                XCTAssertTrue(action.isHittable)
                XCTAssertGreaterThanOrEqual(action.frame.minY, viewport.maxY - 2)
                XCTAssertLessThanOrEqual(action.frame.maxY, app.frame.maxY)
                if app.frame.width >= 760, app.frame.height >= 700, options.count >= 2 {
                    let tiles = options.reduce(CGRect.null) { $0.union($1.frame) }
                    let settings = app.buttons["question.dayPart.settings"]
                    let actions = settings.exists ? settings.frame.union(action.frame) : action.frame
                    // A verdict badge can extend the tile's accessibility frame by four points.
                    XCTAssertEqual(actions.minX, tiles.minX, accuracy: 5, "The footer aligns with the first answer column")
                    XCTAssertEqual(actions.maxX, tiles.maxX, accuracy: 5, "The footer aligns with the last answer column")
                }
            }
        }
        if app.frame.width > app.frame.height && [.setDigital, .setAnalog, .advanceAnalog].contains(type) {
            let controls = answers.filter { $0.identifier.hasPrefix("question.analog.") || $0.identifier.hasPrefix("question.hand.") || $0.identifier.hasPrefix("clock.") }
                .reduce(CGRect.null) { $0.union($1.frame) }
            let input = app.descendants(matching: .any).matching(identifier: "question.digitalControl").firstMatch
            let center = type == .setDigital && input.exists ? input.frame.midX : title.frame.midX
            if !controls.isNull { XCTAssertEqual(controls.midX, center, accuracy: 2, "Controls align with their clock in the lesson column") }
        }
        saveScreenshot("adaptive-fit-\(type.rawValue)-\(name)")
    }

    func testLandscapeSingleColumnAndPersonalizer() {
        app.terminate()
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.landscape-redesign.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_COMPLETED_WORLDS"] = "0"
        app.launchEnvironment["DINO_TEST_PRACTICE_TYPE"] = "sayTime"
        app.launchEnvironment["DINO_TEST_PRACTICE_CHALLENGE"] = "1"
        app.launch()
        XCTAssertTrue(app.staticTexts["question.title"].waitForExistence(timeout: 10))
        for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight, .portrait] {
            XCUIDevice.shared.orientation = orientation
            RunLoop.current.run(until: Date().addingTimeInterval(1))
            XCTAssertEqual(app.frame.width > app.frame.height, orientation != .portrait, "The test must exercise the actual requested orientation")
            checkQuestionFits(.sayTime, name: "single-column-\(orientation.rawValue)")
            let title = app.staticTexts["question.title"].frame
            let clock = app.descendants(matching: .any)["question.targetClock"].firstMatch.frame
            let stone = app.buttons["question.spoken.0.0"].frame
            XCTAssertEqual(title.midX, clock.midX, accuracy: 2)
            XCTAssertGreaterThanOrEqual(clock.minY, title.maxY - 1)
            XCTAssertGreaterThan(stone.minY, clock.maxY)
            let rail = app.otherElements["header.rail"].firstMatch
            if app.frame.width > app.frame.height && app.frame.height < 500 {
                XCTAssertTrue(rail.exists)
                XCTAssertLessThan(rail.frame.maxX, title.minX)
            } else { XCTAssertFalse(rail.exists) }
            tap("header.dino")
            for page in ["dino", "analog", "digital"] {
                tap("personalize.page." + page)
                let done = app.buttons["personalize.done"]
                XCTAssertTrue(done.isHittable)
                if app.frame.width > app.frame.height {
                    let dino = app.buttons["personalize.page.dino"].frame
                    let analog = app.buttons["personalize.page.analog"].frame
                    let digital = app.buttons["personalize.page.digital"].frame
                    let doneFrame = done.frame
                    XCTAssertEqual(dino.midY, analog.midY, accuracy: 1)
                    XCTAssertEqual(dino.midX, doneFrame.midX, accuracy: 1)
                    XCTAssertEqual(analog.midX, digital.midX, accuracy: 1)
                    XCTAssertEqual(doneFrame.midY, digital.midY, accuracy: 1)
                    XCTAssertGreaterThan(doneFrame.minY, dino.maxY)
                    let previewID = page == "dino" ? "personalize.preview" : "theme.\(page).preview"
                    let preview = app.descendants(matching: .any).matching(identifier: previewID).firstMatch
                    XCTAssertTrue(preview.exists)
                    if app.frame.height < 500 {
                        XCTAssertGreaterThanOrEqual(preview.frame.minY, doneFrame.maxY)
                        let colorID = page == "dino" ? "personalize.bandana" : page == "analog" ? "theme.dino.hourHand" : "theme.dino.digitColor"
                        let label = app.staticTexts[colorID + ".label"]
                        let swatch = app.buttons[colorID + (page == "dino" ? ".red" : ".navy")]
                        XCTAssertTrue(swatch.isHittable)
                        XCTAssertLessThanOrEqual(label.frame.maxX, swatch.frame.minX)
                        XCTAssertEqual(label.frame.midY, swatch.frame.midY, accuracy: 2)
                        if page == "digital" { XCTAssertGreaterThan(preview.frame.height, 56) }
                    } else {
                        XCTAssertLessThan(preview.frame.maxY, dino.minY)
                    }
                    XCTAssertLessThan(preview.frame.maxX, analog.maxX + 10)
                }
                saveScreenshot("landscape-editor-\(page)-\(orientation.rawValue)")
            }
            tap("personalize.done")
        }
    }

    func testLandscapeLevelAndPracticePanels() {
        app.terminate()
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.landscape-panels.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "10"
        app.launch()
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 10))
        waitForMapOpeningToFinish()
        tap("map.level.11")
        let disclosure = app.descendants(matching: .any).matching(identifier: "level.details").firstMatch
        XCTAssertTrue(disclosure.waitForExistence(timeout: 5))
        XCTAssertEqual(disclosure.value as? String, "Open")
        let outline = app.buttons["level.question.0"]
        let play = app.buttons["level.play"]
        XCTAssertTrue(outline.isHittable)
        XCTAssertTrue(play.isHittable)
        XCTAssertTrue(app.buttons["level.map"].isHittable)
        XCTAssertLessThan(outline.frame.maxX, play.frame.minX)
        saveScreenshot("landscape-level-expanded-left")
        tap("level.question.0")
        XCTAssertTrue(app.buttons["practice.start"].waitForExistence(timeout: 6))
        let times = DinoPracticeTime.allCases.map { app.buttons["practice.time.\($0.rawValue)"] }
        XCTAssertEqual(times.count, 6)
        for time in times { XCTAssertTrue(time.isHittable); XCTAssertTrue(app.frame.contains(time.frame)) }
        XCTAssertEqual(times[0].frame.midY, times[2].frame.midY, accuracy: 1)
        XCTAssertEqual(times[3].frame.midY, times[5].frame.midY, accuracy: 1)
        XCTAssertGreaterThan(times[3].frame.minY, times[0].frame.maxY)
        let start = app.buttons["practice.start"], close = app.buttons["practice.close"]
        XCTAssertGreaterThan(start.frame.minY, times[5].frame.maxY)
        XCTAssertGreaterThan(close.frame.minY, start.frame.maxY)
        XCTAssertLessThan(start.frame.maxX, app.scrollViews["practice.options"].frame.minX)
        XCTAssertTrue(start.isHittable); XCTAssertTrue(close.isHittable)
        saveScreenshot("landscape-practice-clocks-left")
        selectPractice("practice.type.flightArrival")
        saveScreenshot("landscape-practice-last-type")
        tap("practice.start")
        if app.buttons["demo.ready"].exists { tap("demo.ready") }
        XCTAssertTrue(app.buttons["header.pause"].waitForExistence(timeout: 6))
        tap("header.pause")
        XCTAssertTrue(app.buttons["practice.close"].waitForExistence(timeout: 6))
        tap("practice.close")
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 6))
        tap("map.level.11"); tap("level.play")
        if app.buttons["demo.ready"].exists { tap("demo.ready") }
        XCTAssertTrue(app.buttons["header.pause"].waitForExistence(timeout: 6))
    }

    func testLandscapeResultHasLargeStageAndReachableActions() {
        for correct in [2, 3, 4, 5] {
            app.terminate()
            XCUIDevice.shared.orientation = .landscapeLeft
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.result-landscape-refinement.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "4"
            app.launchEnvironment["DINO_TEST_RESULT_LEVEL"] = "4"
            app.launchEnvironment["DINO_TEST_RESULT_CORRECT"] = String(correct)
            app.launch()
            XCTAssertTrue(app.buttons["result.retry"].waitForExistence(timeout: 10))
            RunLoop.current.run(until: Date().addingTimeInterval(2.5))
            let character = app.descendants(matching: .any).matching(NSPredicate(format: "identifier IN %@",
                ["dino.stumble", "dino.openingJump", "dino.pirouette", "dino.backflip"])).firstMatch
            XCTAssertTrue(character.exists)
            XCTAssertGreaterThan(character.frame.width, min(300, app.frame.height * 0.50))
            let score = app.descendants(matching: .any)["result.score"].firstMatch
            XCTAssertLessThan(character.frame.maxX, score.frame.minX)
            for identifier in ["result.next", "result.retry", "result.map"] {
                let button = app.buttons[identifier]
                XCTAssertTrue(button.isHittable)
                XCTAssertTrue(app.frame.contains(button.frame))
                XCTAssertGreaterThan(button.frame.minX, character.frame.maxX)
            }
            saveScreenshot("result-landscape-large-stage-\(correct)")
            XCUIDevice.shared.orientation = .portrait
            RunLoop.current.run(until: Date().addingTimeInterval(0.8))
            XCTAssertTrue(app.buttons["result.retry"].isHittable)
            saveScreenshot("result-return-portrait-\(correct)")
        }
    }

    func testLandscapeWaterfallSpring() {
        app.terminate()
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.landscape-spring.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "2"
        app.launch()
        XCTAssertTrue(app.buttons["header.level"].waitForExistence(timeout: 10))
        waitForMapOpeningToFinish()
        for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            RunLoop.current.run(until: Date().addingTimeInterval(0.8))
            XCTAssertTrue(app.buttons["map.level.3"].isHittable)
            saveScreenshot("landscape-waterfall-spring-\(orientation.rawValue)")
        }
    }

    func testLandscapeMapOpeningAndBounds() {
        app.terminate()
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.landscape-opening.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = "10"
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["map.preparing"].waitForExistence(timeout: 8))
        for index in 0..<20 {
            saveScreenshot("landscape-welcome-\(index)")
            RunLoop.current.run(until: Date().addingTimeInterval(0.12))
        }
        waitForMapOpeningToFinish()
        for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            RunLoop.current.run(until: Date().addingTimeInterval(1))
            XCTAssertGreaterThan(app.frame.width, app.frame.height, "The map must actually be in landscape")
            let scroll = app.scrollViews["map.route"].frame
            XCTAssertEqual(scroll.minX, app.frame.minX, accuracy: 1)
            XCTAssertEqual(scroll.maxX, app.frame.maxX, accuracy: 1)
            let hud = app.buttons["header.dino"].frame.union(app.buttons["header.settings"].frame)
            XCTAssertEqual(hud.midX, app.frame.midX, accuracy: 20, "The map HUD stays centered inside the safe viewport")
            let dino = app.descendants(matching: .any)["map.dino.11"].frame
            XCTAssertLessThanOrEqual(dino.width, app.frame.height * 0.55)
            XCTAssertTrue(app.frame.contains(dino))
            saveScreenshot("landscape-full-map-\(orientation.rawValue)")
        }
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
        for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            RunLoop.current.run(until: Date().addingTimeInterval(1))
            let settled = NSPredicate { _, _ in
                (self.app.frame.width > self.app.frame.height)
                    && settings.exists && settings.frame.maxX <= self.app.frame.maxX
            }
            expectation(for: settled, evaluatedWith: nil)
            waitForExpectations(timeout: 8)
            RunLoop.current.run(until: Date().addingTimeInterval(0.7))
            XCTAssertEqual(settings.frame.width / settings.frame.height, portraitRatio, accuracy: 0.04,
                           "HUD cells preserve their proportions on rotation")
            XCTAssertGreaterThanOrEqual(app.buttons["header.dino"].frame.height, 52)
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
                (self.app.frame.width > self.app.frame.height)
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
            let horizontal = tablet && app.frame.width > app.frame.height
            if horizontal {
                XCTAssertEqual(first.frame.midX, right.frame.midX, accuracy: 1)
                XCTAssertLessThan(first.frame.maxY, right.frame.minY)
            } else { XCTAssertEqual(first.frame.midY, right.frame.midY, accuracy: 1) }
            XCTAssertGreaterThanOrEqual(first.frame.height, tablet ? 104 : 108, "Practice clocks fit the available height")
            if tablet {
                XCTAssertLessThanOrEqual(app.buttons["question.match.clock.2"].frame.maxY,
                                         app.scrollViews["game.questions"].frame.maxY)
            }
            let last = horizontal ? app.buttons["question.match.clock.2"] : right
            XCTAssertEqual((first.frame.minX + last.frame.maxX) / 2, app.frame.midX, accuracy: 1)
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
            let options = self.app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "question.option."))
            guard let lastOption = options.allElementsBoundByIndex.last else { return false }
            let viewport = self.app.frame
            return viewport.width > viewport.height && lastOption.frame.maxX <= viewport.maxX + 1
                && lastOption.frame.minX >= viewport.minX
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
            let opensByDefault = app.frame.width >= 700 && app.frame.height >= 550
            XCTAssertEqual(header.value as? String, opensByDefault ? "Open" : "Dicht")
            if opensByDefault { header.tap() }
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
            XCTAssertEqual(header.value as? String, opensByDefault ? "Open" : "Dicht")
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
        let opensByDefault = app.frame.width >= 700 && app.frame.height >= 550
        XCTAssertEqual(header.value as? String, opensByDefault ? "Open" : "Closed")
        if !opensByDefault { header.tap() }
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
            let header = app.buttons["level.details"]
            XCTAssertTrue(header.waitForExistence(timeout: 5))
            let spacious = app.frame.width >= 700 && app.frame.height >= 550
            if spacious {
                XCTAssertEqual(header.value as? String, "Open")
                XCTAssertTrue(app.buttons["level.question.0"].exists)
            } else {
                tap("level.details")
            }
            if level == 11 && index == 0 {
                let sign = app.descendants(matching: .any)["level.outlineCard"].firstMatch
                saveScreenshot("level-outline-before-collapse")
                header.tap()
                let collapsedHeight: CGFloat = spacious ? 76 : 64
                let collapsed = NSPredicate { _, _ in abs(sign.frame.height - collapsedHeight) < 1 }
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
            let subtitle = app.descendants(matching: .any).matching(identifier: "practice.hudSubtitle")
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

    private func launchReviewResult(level: Int, correct: Int, completed: Int = 0) {
        app.terminate()
        app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.world-review.\(UUID().uuidString)"
        app.launchEnvironment["DINO_TEST_REVIEW_DIAGNOSTICS"] = "1"
        app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = completed > 0 ? String(completed) : nil
        app.launchEnvironment["DINO_TEST_RESULT_LEVEL"] = String(level)
        app.launchEnvironment["DINO_TEST_RESULT_CORRECT"] = String(correct)
        app.launch()
        XCTAssertTrue(app.buttons["result.retry"].waitForExistence(timeout: 8))
    }

    func testWorldReviewRequestsAfterArrival() {
        for world in [1, 4, 9, 10] {
            // Include both boss victory routes and the last world without a salto.
            launchReviewResult(level: world * 10, correct: world == 4 ? 6 : 10,
                               completed: world == 1 ? 0 : world * 10 - 1)
            tap(world == 10 ? "result.map" : "result.next")
            let requests = app.staticTexts["map.reviewRequests"]
            let requested = NSPredicate { _, _ in requests.exists && requests.label == "1" }
            expectation(for: requested, evaluatedWith: nil)
            waitForExpectations(timeout: 20)
            XCTAssertFalse(app.descendants(matching: .any)["map.worldJump"].exists)
            XCTAssertTrue(app.descendants(matching: .any)["map.dino.\(min(100, world * 10 + 1))"].exists)
            XCTAssertGreaterThanOrEqual(Double(requests.value as? String ?? "") ?? 0, 1,
                                        "The full one-second delay starts after the map arrival")
            // Sheet dismissal and view updates must not request this arrival again.
            tap("header.settings")
            tap("settings.done")
            RunLoop.current.run(until: Date().addingTimeInterval(1.2))
            XCTAssertEqual(requests.label, "1")
        }
    }

    func testWorldReviewDoesNotRequestForOrdinaryResultsOrRetry() {
        for (level, correct, completed) in [(2, 4, 1), (10, 5, 9), (10, 9, 0)] {
            launchReviewResult(level: level, correct: correct, completed: completed)
            tap("result.map")
            let requests = app.staticTexts["map.reviewRequests"]
            XCTAssertTrue(requests.waitForExistence(timeout: 15))
            waitForMapOpeningToFinish()
            RunLoop.current.run(until: Date().addingTimeInterval(1.2))
            XCTAssertEqual(requests.label, "0")
        }
        launchReviewResult(level: 10, correct: 10)
        tap("result.retry")
        XCTAssertTrue(app.buttons["header.pause"].waitForExistence(timeout: 8))
        // The first question can be left without a confirmation dialog.
        tap("header.pause")
        let requests = app.staticTexts["map.reviewRequests"]
        XCTAssertTrue(requests.waitForExistence(timeout: 15))
        waitForMapOpeningToFinish()
        RunLoop.current.run(until: Date().addingTimeInterval(1.2))
        XCTAssertEqual(requests.label, "0")
    }

    func testWorldReviewRequestCancelsWhenOpeningSettings() {
        launchReviewResult(level: 100, correct: 10, completed: 99)
        tap("result.map")
        app.buttons["header.settings"].tap()
        XCTAssertTrue(app.buttons["settings.done"].waitForExistence(timeout: 5))
        RunLoop.current.run(until: Date().addingTimeInterval(1.2))
        tap("settings.done")
        RunLoop.current.run(until: Date().addingTimeInterval(1.2))
        XCTAssertEqual(app.staticTexts["map.reviewRequests"].label, "0")
    }

    func testWorldResultButtonsAndMapSalto() {
        for world in [1, 4, 9] {
            app.terminate()
            app.launchEnvironment["DINO_TEST_SUITE"] = "dino.ui.world-salto.\(UUID().uuidString)"
            app.launchEnvironment["DINO_TEST_COMPLETED_LEVEL"] = String(world * 10 - 1)
            app.launchEnvironment["DINO_TEST_RESULT_LEVEL"] = String(world * 10)
            app.launchEnvironment["DINO_TEST_RESULT_CORRECT"] = world == 4 ? "6" : "10"
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
            // Tablet map actors have a 200-point source frame; AX stones also include their stars.
            let mapScale = UIDevice.current.userInterfaceIdiom == .pad ? marker.frame.width / 200 : 1
            XCTAssertEqual(marker.frame.maxY, stone.frame.midY + 12 * mapScale, accuracy: 2)
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
            let controls = level.isMultiple(of: 10) && correct >= 6 ? ["result.next", "result.retry"] : ["result.map", "result.retry"]
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
            XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "dino.openingJump").count, stars == 1 ? 1 : 0)
            XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "dino.pirouette").count, stars == 2 ? 1 : 0)
            XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "dino.backflip").count, stars == 3 ? 1 : 0)
            XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "dino.stumble").count, stars == 0 ? 1 : 0)
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
                    waitForMapOpeningToFinish()
                    let starsButton = app.buttons["header.stars"]
                    let ready = NSPredicate { _, _ in starsButton.isEnabled && starsButton.isHittable }
                    expectation(for: ready, evaluatedWith: nil)
                    waitForExpectations(timeout: 10)
                    starsButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                    XCTAssertTrue(app.scrollViews["stars.overview"].waitForExistence(timeout: 5))
                    saveScreenshot("result-redesign-overview-gold-stars")
                    tap("stars.close")
                    XCTAssertTrue(app.buttons["header.stars"].waitForExistence(timeout: 5))
                }
            }
        }
        showResult(level: 10, correct: 4, completed: 9)
        XCTAssertEqual(app.descendants(matching: .any)["result.stars"].label, "0/3")
        XCTAssertFalse(app.buttons["result.next"].exists)
        saveScreenshot("result-redesign-boss-retry")
        showResult(level: 10, correct: 10, completed: 9, language: "en")
        XCTAssertEqual(app.descendants(matching: .any)["result.stars"].label, "3/3")
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

    func testOneStarOpeningJumpFromPortraitToStone() {
        onboard()
        tap("header.dino")
        for (part, color) in [("bandana", "blue"), ("spikes", "purple"), ("body", "pink"), ("belly", "orange")] {
            tap("personalize.\(part).\(color)")
        }
        tap("personalize.done")
        begin(1)
        let portrait = app.descendants(matching: .any)["dino.character"].frame
        XCTAssertLessThan(portrait.midX, app.frame.midX)
        XCTAssertLessThan(portrait.midY, app.frame.midY)
        play(1, correct: 3)
        let jump = app.descendants(matching: .any)["dino.openingJump"]
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "dino.openingJump").count, 1)
        XCTAssertFalse(app.descendants(matching: .any)["dino.backflip"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["dino.pirouette"].exists)
        RunLoop.current.run(until: Date().addingTimeInterval(2))
        XCTAssertEqual(app.descendants(matching: .any)["result.stars"].label, "1/3")
        XCTAssertEqual(jump.frame.midX, app.frame.midX, accuracy: 5)
        XCTAssertGreaterThan(jump.frame.midY, portrait.midY)
        XCTAssertGreaterThan(jump.frame.width, portrait.width)
        XCTAssertGreaterThanOrEqual(jump.frame.minX, app.frame.minX)
        XCTAssertLessThanOrEqual(jump.frame.maxX, app.frame.maxX)
        XCTAssertLessThan(jump.frame.maxY, app.buttons["result.next"].frame.minY)
        saveScreenshot("opening-jump-one-star-landing")
        let landedFrame = jump.frame
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        XCTAssertEqual(jump.frame, landedFrame, "The opening jump settles without sliding or bouncing off the stone")
        tap("result.retry")
        XCTAssertTrue(app.buttons["header.pause"].waitForExistence(timeout: 5))
        XCTAssertFalse(jump.exists)
    }

    func testZeroStarFallFromPortraitToStone() {
        verifyZeroStarFall(customColors: true)
    }

    func testZeroStarFallWithOriginalColors() {
        verifyZeroStarFall(customColors: false)
    }

    private func verifyZeroStarFall(customColors: Bool) {
        onboard()
        if customColors {
            tap("header.dino")
            for (part, color) in [("bandana", "blue"), ("spikes", "purple"), ("body", "pink"), ("belly", "orange")] {
                tap("personalize.\(part).\(color)")
            }
            tap("personalize.done")
        }
        begin(1)
        play(1, correct: 2)
        let dino = app.descendants(matching: .any)["dino.stumble"]
        XCTAssertTrue(dino.waitForExistence(timeout: 5))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "dino.stumble").count, 1)
        XCTAssertFalse(app.descendants(matching: .any)["dino.backflip"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["dino.pirouette"].exists)
        RunLoop.current.run(until: Date().addingTimeInterval(2.6))
        XCTAssertEqual(app.descendants(matching: .any)["result.stars"].label, "0/3")
        XCTAssertEqual(dino.frame.midX, app.frame.midX, accuracy: 5)
        XCTAssertLessThan(dino.frame.maxY, app.buttons["result.retry"].frame.minY)
        XCTAssertFalse(app.buttons["result.next"].exists)
        XCTAssertTrue(app.buttons["result.retry"].isHittable)
        saveScreenshot(customColors ? "zero-star-fall-recovered" : "zero-star-fall-standard-recovered")
        let recoveredFrame = dino.frame
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        XCTAssertEqual(dino.frame, recoveredFrame, "Dino holds his recovered pose on the rock")
        tap("result.retry")
        XCTAssertTrue(app.buttons["header.pause"].waitForExistence(timeout: 5))
        XCTAssertFalse(dino.exists)
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
        let rewardActionGap = app.buttons["result.next"].frame.minY - landed.frame.maxY
        XCTAssertGreaterThan(rewardActionGap, 0)
        if app.frame.width >= 700 {
            XCTAssertLessThan(rewardActionGap, landed.frame.width * 0.5, "The reward and its actions stay together on iPad")
        }
        saveScreenshot("transition-result-dino")
        tap("result.map")
        XCTAssertTrue(app.buttons["header.settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(revealMapNode(2).isEnabled)
        saveScreenshot("personalized-completed-map-companion")
    }
}
