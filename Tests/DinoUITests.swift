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
        for _ in 0..<6 { if item.isHittable { break }; app.swipeUp() }
        item.tap()
    }

    private func onboard(custom: Bool = false) {
        let name = app.textFields["onboarding.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["onboarding.start"].exists)
        XCTAssertFalse(app.buttons["onboarding.next"].isEnabled)
        name.tap(); name.typeText("Sam")
        tap("onboarding.next")
        if custom { tap("theme.dino.face.blue") }
        tap(custom ? "onboarding.customClock" : "onboarding.standardClock")
        XCTAssertTrue(app.buttons["map.bossShortcut"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["header.playerName"].exists)
    }

    private func openSettings() {
        tap("header.settings")
    }

    private func revealMapNode(_ id: Int) -> XCUIElement {
        let node = app.buttons["map.level.\(id)"]
        for _ in 0..<14 {
            // isHittable alone includes nodes partly covered by the sticky HUD.
            let top = app.buttons["header.settings"].frame.maxY + 20
            if node.isHittable && node.frame.minY > top && node.frame.maxY < app.frame.maxY - 16 { break }
            let movingDown = node.frame.minY <= top
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: movingDown ? 0.45 : 0.72))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: movingDown ? 0.70 : 0.47))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTAssertTrue(node.isHittable, "Node \(id) offscreen")
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

    func testFreeAvatarColorPicker() {
        onboard()
        tap("header.playerName")
        let picker = app.buttons["personalize.color.bandana"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.coordinate(withNormalizedOffset: CGVector(dx: 0.96, dy: 0.5)).tap()
        XCTAssertTrue(app.segmentedControls.buttons["Schuifbalken"].waitForExistence(timeout: 5))
        app.segmentedControls.buttons["Schuifbalken"].tap()
        let blue = app.sliders["sliderBlue"]
        XCTAssertTrue(blue.waitForExistence(timeout: 5))
        blue.adjust(toNormalizedSliderPosition: 0.73)
        saveScreenshot("personalize-free-color-picker")
        app.buttons["sluit"].tap()
        XCTAssertFalse(app.buttons["personalize.bandana.red"].isSelected)
        XCTAssertTrue(app.buttons["personalize.body.green"].isSelected)
        let chosen = picker.value as? String
        XCTAssertNotNil(chosen)
        tap("personalize.done")
        app.terminate(); app.launch()
        tap("header.playerName")
        XCTAssertEqual(app.buttons["personalize.color.bandana"].value as? String, chosen)
        tap("personalize.done")
    }

    func testPersonalizeHeaderColorsAndName() {
        onboard()
        saveScreenshot("personalize-header-default")
        tap("header.playerName")
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
        let name = app.textFields["personalize.name"]
        tap("personalize.name")
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3) + "Luna")
        XCTAssertEqual(name.value as? String, "Luna")
        saveScreenshot("personalize-name-edit")
        tap("personalize.saveName")
        XCTAssertFalse(app.staticTexts["personalize.nameError"].exists)
        XCTAssertEqual(name.value as? String, "Luna")
        tap("personalize.name")
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 4) + "Nova")
        XCTAssertEqual(name.value as? String, "Nova")
        tap("personalize.done")
        XCTAssertTrue(app.buttons["header.playerName"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["header.playerName"].label, "Nova")
        saveScreenshot("personalize-header-custom")
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["header.playerName"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["header.playerName"].label, "Nova")
        tap("header.playerName")
        for (part, color) in [("bandana", "blue"), ("spikes", "purple"), ("body", "pink"), ("belly", "orange")] {
            XCTAssertTrue(app.buttons["personalize.\(part).\(color)"].isSelected)
        }
        tap("personalize.resetColors")
        for (part, color) in [("bandana", "red"), ("spikes", "darkGreen"), ("body", "green"), ("belly", "yellow")] {
            XCTAssertTrue(app.buttons["personalize.\(part).\(color)"].isSelected)
        }
        tap("personalize.done")
        begin(1)
        if app.buttons["demo.ready"].exists { tap("demo.ready") }
        tap("header.playerName")
        tap("personalize.bandana.purple")
        tap("personalize.done")
        XCTAssertTrue(app.staticTexts["1/5"].exists)
        XCTAssertTrue(app.buttons["question.option.0"].exists)
        saveScreenshot("personalize-in-level")
        XCUIDevice.shared.orientation = .landscapeLeft
        tap("header.playerName")
        saveScreenshot("personalize-landscape")
        tap("personalize.done")
        XCTAssertTrue(app.buttons["header.playerName"].waitForExistence(timeout: 5))
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
                let initial = i == 0 ? 12 : question.target.hour == 12 ? 1 : 12
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
        XCTAssertTrue(app.staticTexts["Wereld 1 voltooid!"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Binnenkort"].exists)
        saveScreenshot("normal-world-complete")
    }

    func testDirectPerfectBoss() {
        onboard()
        begin(10)
        play(10, correct: 10)
        XCTAssertTrue(app.staticTexts["Perfecte boss-overwinning!"].exists)
        tap("result.next")
        XCTAssertTrue(app.staticTexts["Wereld 1 voltooid!"].exists)
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
        // Device capture preserves the full viewport after portrait/landscape rotation.
        let capture = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: capture)
        attachment.name = name; attachment.lifetime = .keepAlways
        add(attachment)
        // Also keep simulator screenshots in a local folder for visual QA.
        let deviceFolder = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        let folder = URL(fileURLWithPath: "/tmp/DinoScreenshots/\(deviceFolder)", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let screenshot = capture.image
        let rendered = UIGraphicsImageRenderer(size: screenshot.size).image { _ in
            screenshot.draw(in: CGRect(origin: .zero, size: screenshot.size))
        }
        try? rendered.pngData()?.write(to: folder.appendingPathComponent(name + ".png"))
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
        tap("demo.ready")
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
        XCTAssertTrue(app.staticTexts["Het juiste antwoord"].exists)
        XCTAssertTrue(app.images["dino.wrongAnswer"].exists, "The wrong-answer pose remains until Next")
        let reaction = app.images["dino.wrongAnswer"]
        XCTAssertEqual(app.images.matching(identifier: "dino.wrongAnswer").count, 1)
        XCTAssertGreaterThanOrEqual(reaction.frame.minY, 0)
        XCTAssertLessThanOrEqual(reaction.frame.maxY, app.frame.maxY, "Reaction is visible beside the fixed feedback, even on a small phone")
        XCTAssertEqual(clock.frame.midX, originalCenter, accuracy: 1, "Dino cannot displace the clock after an answer")
        saveScreenshot("wrong-answer-waits")
        tap("question.next")
        XCTAssertTrue(app.staticTexts["2/10"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.images["dino.wrongAnswer"].exists)
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
        XCTAssertTrue(app.descendants(matching: .any)["header.playerName"].waitForExistence(timeout: 5))
    }

    func testJungleHeaderSettingsAndTransition() {
        onboard()
        let player = app.descendants(matching: .any)["header.playerName"]
        let level = app.descendants(matching: .any)["header.level"]
        let stars = app.descendants(matching: .any)["header.stars"]
        XCTAssertEqual(player.label, "Sam")
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
        XCTAssertTrue(app.descendants(matching: .any)["map.nextWorld"].exists)
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
        XCTAssertGreaterThan(marker.frame.height, 110)
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
        app.buttons["header.pause"].tap()
        XCTAssertTrue(app.buttons["game.exit.cancel"].waitForExistence(timeout: 5))
        let coveredAnswer = app.buttons["question.option.0"]
        XCTAssertTrue(!coveredAnswer.exists || !coveredAnswer.isEnabled,
                      "Answer input is disabled while the exit card is open")
        saveScreenshot("exit-portrait")
        tap("game.exit.cancel")
        XCTAssertTrue(app.staticTexts["1/5"].exists)
        XCTAssertEqual(clock.frame.midX, app.frame.midX, accuracy: 1)
        app.buttons["header.pause"].tap()
        tap("game.exit.confirm")
        XCTAssertTrue(marker.waitForExistence(timeout: 5))
    }

    func testPlayCardAndContinuousResultDino() {
        onboard()
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
    }
}
