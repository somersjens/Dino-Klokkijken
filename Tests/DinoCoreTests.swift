import Foundation

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
        testAnimation()
        testQuestions()
        testAttempt()
        testProgress()
        testStorage()
        testDinoAppearance()
        testPlayerModel()
        testSettingsAndFeedback()
        testCloudSync()
        let socialChecks = await DinoSocialTests.run()
        print("PASS: \(checks + socialChecks) checks — gameplay, persistence, social progress, privacy guards, offline sync and international names.")
    }

    static func testClocks() {
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
        expect(DinoLevelCatalog.levels.count == 10, "10 levels")
        var observedKinds = Set<ClockQuestionKind>()
        for seed in 0..<300 {
            for level in DinoLevelCatalog.levels {
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
                    } else { expect(q.options.isEmpty, "no options for controls") }
                    if let activity = q.activity { expect(activity.hour == q.target.hour, "explicit activity time") }
                }
                if level.isBoss && seed % 3 == 0 {
                    expect(Array(questions.prefix(4).map { $0.target.hour }) == [3, 8, 11, 6], "first boss prescribed times")
                }
            }
        }
        expect(observedKinds == Set(ClockQuestionKind.allCases), "all six interactions")
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
        expect(direct.worldOneComplete && direct.perfectBossVictory && direct.dinoLevel == 10 && direct.unlockedLevels.count == 10, "perfect opens entire world")
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
        p.clockTheme.face = .blue; p.clockTheme.hands = .playful; p.clockTheme.numerals = .digital
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
    static func testPlayerModel() {
        let memory = InMemoryKeyValueStore()
        let player = DinoPlayer(store: DinoProgressStore(defaults: memory))
        player.setName(" Sam ")
        var theme = ClockTheme.standard
        theme.face = .green; theme.display = .charcoal; theme.hands = .straight
        player.completeOnboarding(theme: theme)
        expect(player.profile.name == "Sam" && player.profile.onboardingComplete, "model onboarding")
        expect(player.profile.clockTheme == theme, "model chosen clocks")
        let level = DinoLevelCatalog.level(1)!
        let session = DinoSession(level: level, player: player)
        expect(session.demonstration == .chooseAnalog, "new interaction demonstration")
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
        expect(restored.name == "Sam" && restored.onboardingComplete && restored.clockTheme == .standard, "reset preserves profile and clocks")
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
        expect(restarted.setName("Luna") && restarted.setName("Nova"), "name can be changed repeatedly")
        restarted.resetProgress()
        expect(restarted.profile.dinoAppearance == appearance && restarted.profile.name == "Nova", "progress reset preserves appearance and name")
        var cloud = PlayerProfile(); cloud.recordCompletedAttempt(levelID: 1, correct: 5)
        restarted.mergeCloudProgress(DinoCloudProgress(cloud))
        expect(restarted.profile.dinoAppearance == appearance, "cloud merge preserves local avatar colors")
        let cloudJSON = String(data: try! JSONEncoder().encode(DinoCloudProgress(restarted.profile)), encoding: .utf8)!
        expect(!cloudJSON.contains("dinoAppearance") && !cloudJSON.contains("bandana"), "avatar colors remain device-local")
        restarted.setDinoAppearance(.standard)
        expect(DinoPlayer(store: store).profile.dinoAppearance == .standard, "restore original colors persists")
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
        let session = DinoSession(level: DinoLevelCatalog.level(1)!, player: player) { feedback.append($0) }
        session.submit(session.question.target)
        expect(feedback.isEmpty, "demonstration never emits answer feedback")
        session.dismissDemonstration()
        session.submit(session.question.target); session.submit(session.question.target)
        expect(feedback == [true], "one success feedback despite repeated taps")
        session.advance()
        session.submit(ClockTime(hour: ClockTime.shiftedHour(session.question.target.hour, by: 1)))
        expect(feedback == [true, false], "wrong answer emits distinct feedback")
        player.resetProgress()
        expect(DinoSettings(defaults: memory).highContrastEnabled, "progress reset preserves preferences")
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
        expect(restored.perfectBossVictory && restored.worldOneComplete && restored.unlockedLevels.count == 10, "perfect boss progress restores on a second device")
        var normalBoss = PlayerProfile()
        for id in 1...9 { normalBoss.recordCompletedAttempt(levelID: id, correct: 3) }
        normalBoss.recordCompletedAttempt(levelID: 10, correct: 5)
        var normalRestored = PlayerProfile(); normalRestored.mergeCloudProgress(DinoCloudProgress(normalBoss))
        expect(normalRestored.worldOneComplete && !normalRestored.perfectBossVictory, "normal boss route survives cloud sync")
        var malformed = DinoCloudProgress(PlayerProfile())
        malformed.levels = ["11": LevelRecord(stars: 3, bestCorrect: 5, attempts: 1), "1": LevelRecord(stars: 3, bestCorrect: 0, attempts: 1)]
        var safe = PlayerProfile(); safe.mergeCloudProgress(malformed)
        expect(safe.levels["11"] == nil && safe.totalStars == 0, "cloud cannot invent stars or unknown levels")
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
    func synchronize() -> Bool { syncs += 1; return succeeds }
}
