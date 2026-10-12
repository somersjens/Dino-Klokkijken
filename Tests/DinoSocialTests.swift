import Foundation

@MainActor
private final class TestLeaderboards: ProgressLeaderboardTransport {
    enum Failure: Error { case offline }
    var availableTimingLeaderboardIDs: Set<String> = []
    var values: [String: LeaderboardValue] = [:]
    var failLoad = false
    var failSubmission: Int?
    var submitted: [String] = []
    var afterLoad: (() -> Void)?
    var afterSubmit: (() -> Void)?
    func loadOwnResults() async throws -> [String: LeaderboardValue] {
        if failLoad { throw Failure.offline }
        afterLoad?()
        return values
    }
    func submit(score: Int, context: Int, leaderboardID: String) async throws {
        if failSubmission == submitted.count { throw Failure.offline }
        submitted.append(leaderboardID)
        if values[leaderboardID].map({ $0.score < score }) ?? true {
            values[leaderboardID] = LeaderboardValue(score: score, context: context)
        }
        afterSubmit?()
    }
}

@MainActor
enum DinoSocialTests {
    private static var checks = 0
    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        checks += 1
        if !condition() { fatalError("FAILED social: \(message)") }
    }
    static func run() async -> Int {
        testNames()
        testProjections()
        testTimedProjections()
        testLegacyProfileMigration()
        await testSync()
        await testTimedSync()
        return checks
    }
    private static func testNames() {
        for name in ["Sam", "José", "Jo\u{0308}rg", "O’Neil", "Anne-Marie", "محمد", "می\u{200C}نا", "李", "王小明", "さくら", "김민수", "София", "Σοφία", "דניאל", "आरव", "क्\u{200D}षितिज"] {
            guard case .success(let result) = DinoNameValidator.validated(name) else { fatalError("Rejected international name \(name)") }
            expect(result == name.precomposedStringWithCanonicalMapping, "canonical Unicode spelling")
        }
        for name in ["", "ab", String(repeating: "a", count: 21), "Dino🦖", "Sam\u{0000}", "Sa\u{202E}m", "Sa\u{200B}m", "Sa\u{200D}m", "Sаm", "Sαm", "𝕊𝕒𝕞", "Ｓａｍ", "123", "Sam@", "\u{0301}Sam", "FUCK", "f u c k", "fuuuck", "sh1t", "shıt", "scheiiissse", "k l o o t z a k", "сука", "操", "씨발", "قحبة", "भोसड़ी", "Sa \u{0301}m", "Sam" + String(repeating: "\u{0301}", count: 1000)] {
            if case .success = DinoNameValidator.validated(name) { fatalError("Accepted unsafe name \(name)") }
            expect(true, "unsafe name rejected")
        }
        expect(DinoNameValidator.validated("Scunthorpe") == .success("Scunthorpe"), "no profanity substring false positive")
        expect(DinoNameValidator.validated("Cassidy") == .success("Cassidy"), "legitimate name")
        let twenty = String(repeating: "é", count: 20)
        expect(DinoNameValidator.validated(twenty) == .success(twenty), "20 grapheme clusters")
    }
    private static func testProjections() {
        expect(Set(DinoLeaderboards.allIDs).count == 12, "12 unique boards below Apple's limit")
        var profile = PlayerProfile()
        let fresh = FriendProgress.local(profile)
        expect(fresh.nextLevel == 1 && fresh.totalStars == 0 && fresh.maximumStarsSoFar == 0 && fresh.starPercentage == nil, "real new save, no division by zero")
        expect(FriendProgress().totalStars == nil && FriendProgress().nextLevel == nil, "unknown never means zero or guessed map position")
        for score in 0...5 {
            profile.recordCompletedAttempt(levelID: 1, correct: score)
            let projected = FriendProgress.local(profile)
            expect(projected.levels[1]?.stars == profile.record(1).stars, "real per-level stars")
            expect(projected.levels[1]?.bestCorrect == score, "best score updates even with zero stars")
            expect(projected.nextLevel == (score < 3 ? 1 : 2), "first uncompleted level")
        }
        profile.recordCompletedAttempt(levelID: 1, correct: 0)
        expect(FriendProgress.local(profile).totalStars == 3, "worse replay does not double or lower stars")
        expect(FriendProgress.local(profile).starPercentage == 100, "completed levels denominator")
        var partial = FriendProgress.local(profile)
        partial.levels[2] = nil
        expect(partial.nextLevel == nil && partial.totalStars == nil, "missing level prevents guesses and false total")
        for value in [-1, 6, 8, 17, 31, Int.max] {
            expect(DinoLeaderboards.decode(levelID: 1, score: value, context: 1) == nil, "corrupt result rejected")
        }
        expect(DinoLeaderboards.decode(levelID: 1, score: 30, context: 2) == nil, "unknown schema rejected")
        expect(DinoLeaderboards.decode(levelID: 11, score: 0, context: 1) == nil, "unknown level rejected")
        expect(DinoLeaderboards.decode(levelID: 10, score: 17, context: 1) == nil, "invalid boss victory rejected")
        var perfect = PlayerProfile()
        perfect.recordCompletedAttempt(levelID: 10, correct: 10)
        let direct = FriendProgress.local(perfect)
        expect(direct.highestCompletedLevel == 10 && direct.nextLevel == 1 && direct.totalStars == 0, "direct boss does not invent normal stars")
        expect(direct.levels[10]?.bossComplete == true && direct.levels[10]?.stars == 0, "boss has no stars")
        for id in 1...9 { perfect.recordCompletedAttempt(levelID: id, correct: 5) }
        expect(FriendProgress.local(perfect).allComplete && FriendProgress.local(perfect).nextLevel == nil, "all complete has no nonexistent next level")
        for count in [0,1,2,3,4,1000] {
            let group = FriendMapGroup(ids: (0..<count).map(String.init))
            expect(group.visibleIDs.count == min(3, count) && group.additionalCount == max(0, count - 3), "bounded map badges for large friend lists")
        }
        expect(FriendMapGroup(ids: ["a","a","b"]).additionalCount == 0, "duplicate friends not counted")
        for normalComplete in [false, true] {
            for score in 0...10 {
                var boss = PlayerProfile()
                if normalComplete { for id in 1...9 { boss.recordCompletedAttempt(levelID: id, correct: 3) } }
                boss.recordCompletedAttempt(levelID: 10, correct: score)
                let result = FriendProgress.local(boss).levels[10]
                expect(result?.bestCorrect == score && result?.bossComplete == boss.worldOneComplete && result?.perfectBoss == boss.perfectBossVictory, "boss codec boundary matrix")
            }
        }
    }
    private static func testTimedProjections() {
        for level in DinoLevelCatalog.levels {
            for correct in 0...level.questionCount {
                var profile = PlayerProfile()
                if level.id != 1 && !level.isBoss { profile.recordCompletedAttempt(levelID: 10, correct: 10) }
                for perQuestion in [1, 17, 60] {
                    profile.recordCompletedAttempt(levelID: level.id, correct: correct, questionSeconds: Array(repeating: perQuestion, count: level.questionCount))
                    let score = DinoLeaderboards.timedScore(profile: profile, levelID: level.id)!
                    let result = DinoLeaderboards.decodeTimed(levelID: level.id, score: score, context: 1)
                    expect(result?.bestCorrect == correct, "timed codec preserves score")
                    expect(result?.seconds == level.questionCount, "slower equal replay cannot replace best timing")
                }
            }
        }
        for score in [-1, 0, 30_000, 30_601, Int.max] {
            expect(DinoLeaderboards.decodeTimed(levelID: 1, score: score, context: 1) == nil, "invalid timed result rejected")
        }
        var profile = PlayerProfile()
        profile.recordCompletedAttempt(levelID: 1, correct: 3, questionSeconds: [1,1,1,1,1])
        profile.recordCompletedAttempt(levelID: 1, correct: 5) // Legacy result with no measured time.
        expect(FriendProgress.local(profile).levels[1]?.seconds == nil, "old best score never displays the time of a worse attempt")
    }

    private static func testTimedSync() async {
        let transport = TestLeaderboards()
        transport.availableTimingLeaderboardIDs = Set(DinoLeaderboards.timedIDs)
        let service = ProgressSyncService()
        var local = PlayerProfile()
        local.recordCompletedAttempt(levelID: 1, correct: 5, questionSeconds: [8,8,8,8,8])
        try! await service.synchronize(transport: transport, current: { local }, merge: { local.mergeSharedProgress($0) }, allowed: { true })
        expect(transport.values[DinoLeaderboards.timedLevel(1)] != nil && transport.values.count == 13, "only measured games publish a timing")
        local.recordCompletedAttempt(levelID: 1, correct: 5, questionSeconds: [4,4,4,4,4])
        try! await service.synchronize(transport: transport, current: { local }, merge: { local.mergeSharedProgress($0) }, allowed: { true })
        let score = transport.values[DinoLeaderboards.timedLevel(1)]!
        expect(DinoLeaderboards.decodeTimed(levelID: 1, score: score.score, context: score.context)?.seconds == 20, "faster equal-star replay updates Game Center")
        var restored = PlayerProfile()
        try! await service.synchronize(transport: transport, current: { restored }, merge: { restored.mergeSharedProgress($0) }, allowed: { true })
        expect(FriendProgress.local(restored).levels[1]?.seconds == 20, "timing restored on another device")
        let count = transport.submitted.count
        try! await service.synchronize(transport: transport, current: { restored }, merge: { restored.mergeSharedProgress($0) }, allowed: { true })
        expect(count == transport.submitted.count, "timing retries are idempotent")
    }

    private static func testLegacyProfileMigration() {
        let memory = InMemoryKeyValueStore()
        var legacy = PlayerProfile(); legacy.name = "Sam"; legacy.onboardingComplete = true
        legacy.recordCompletedAttempt(levelID: 1, correct: 5)
        var json = try! JSONSerialization.jsonObject(with: JSONEncoder().encode(legacy)) as! [String: Any]
        json.removeValue(forKey: "nameChangedAt")
        memory.set(try! JSONSerialization.data(withJSONObject: json), forKey: DinoProgressStore.profileKey)
        let store = DinoProgressStore(defaults: memory)
        expect(store.load() == legacy, "old version-one save decodes without new optional field")
        let player = DinoPlayer(store: store)
        player.setDinoAppearance(.standard)
        let restarted = DinoPlayer(store: store)
        expect(restarted.profile.record(1).stars == 3 && restarted.profile.name == "Sam",
               "legacy local name remains an unused save field while progress survives")
    }
    private static func testSync() async {
        let transport = TestLeaderboards()
        let service = ProgressSyncService()
        var local = PlayerProfile(); local.recordCompletedAttempt(levelID: 1, correct: 5)
        let original = local
        transport.failLoad = true
        do {
            try await service.synchronize(transport: transport, current: { local }, merge: { local.mergeSharedProgress($0) }, allowed: { true })
            fatalError("Offline load should fail")
        } catch { expect(local == original && transport.submitted.isEmpty, "offline leaves persisted progress intact") }
        transport.failLoad = false; transport.failSubmission = 2
        do {
            try await service.synchronize(transport: transport, current: { local }, merge: { local.mergeSharedProgress($0) }, allowed: { true })
            fatalError("Partial submission should fail")
        } catch { expect(local == original && transport.submitted.count == 2, "partial uploads do not erase progress") }
        transport.failSubmission = nil
        try! await service.synchronize(transport: transport, current: { local }, merge: { local.mergeSharedProgress($0) }, allowed: { true })
        expect(transport.values.count == 12 && transport.values[DinoLeaderboards.totalStars]?.score == 3, "offline retry publishes all real results")
        let submitted = transport.submitted.count
        try! await service.synchronize(transport: transport, current: { local }, merge: { local.mergeSharedProgress($0) }, allowed: { true })
        expect(transport.submitted.count == submitted, "idempotent retry")
        var secondDevice = PlayerProfile(); secondDevice.name = "Luna"; secondDevice.clockTheme.face = .blue
        try! await service.synchronize(transport: transport, current: { secondDevice }, merge: { secondDevice.mergeSharedProgress($0) }, allowed: { true })
        expect(secondDevice.record(1).stars == 3 && secondDevice.name == "Luna" && secondDevice.clockTheme.face == .blue, "cross-device merge preserves identity and clocks")
        secondDevice.recordCompletedAttempt(levelID: 2, correct: 4)
        try! await service.synchronize(transport: transport, current: { secondDevice }, merge: { secondDevice.mergeSharedProgress($0) }, allowed: { true })
        local.recordCompletedAttempt(levelID: 1, correct: 0)
        try! await service.synchronize(transport: transport, current: { local }, merge: { local.mergeSharedProgress($0) }, allowed: { true })
        expect(local.totalStars == 5 && local.record(1).stars == 3 && local.record(2).stars == 2, "devices union best results per unique level")
        var allowed = true
        let revoked = TestLeaderboards(); revoked.values = transport.values; revoked.afterLoad = { allowed = false }
        var untouched = PlayerProfile()
        try! await service.synchronize(transport: revoked, current: { untouched }, merge: { untouched.mergeSharedProgress($0) }, allowed: { allowed })
        expect(untouched.levels.isEmpty && revoked.submitted.isEmpty, "consent/account revoked during load prevents late merge and upload")
        allowed = true
        let midway = TestLeaderboards(); midway.afterSubmit = { allowed = false }
        try! await service.synchronize(transport: midway, current: { local }, merge: { _ in }, allowed: { allowed })
        expect(midway.submitted.count == 1, "revocation stops subsequent submissions")
    }
}
