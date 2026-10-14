import SwiftUI
import Combine

struct DinoRootView: View {
    @EnvironmentObject private var player: DinoPlayer
    @EnvironmentObject private var friends: FriendsManager
    @EnvironmentObject private var settings: DinoSettings
    @State private var session: DinoSession?
    @State private var result: DinoLevelResult?
    @State private var showsSettings = false
    @State private var showsCompletion = false
    @State private var completedWorldID = 1
    @State private var startCard: LevelConfiguration?
    @State private var showsFriends = false
    @State private var showsPractice = false
    @State private var mapHUDHeight: CGFloat = 103
    @State private var gameCompanionClip: DinoAnimation.Clip = .idle

    var body: some View {
        ZStack {
            scene
                .transition(.opacity)
                .disabled(startCard != nil || showsPractice).accessibilityHidden(startCard != nil || showsPractice)
            if let startCard {
                LevelStartOverlay(level: startCard, hudHeight: mapHUDHeight, start: { start(startCard) }, close: closeStartCard)
                    .zIndex(2)
            }
        }
        .overlayPreferenceValue(DinoCompanionPreference.self) { anchors in
            GeometryReader { geometry in
                let anchor = startCard != nil || showsCompletion ? nil : result != nil ? anchors[.result] : anchors[.game]
                DinoCompanionLayer(destination: anchor.map { geometry[$0] },
                                   clip: companionClip, isResult: result != nil && startCard == nil && !showsCompletion)
            }.allowsHitTesting(false)
        }
        .preferredColorScheme(.light)
            .sheet(isPresented: $showsFriends) {
                DinoFriendsView().environmentObject(friends).gameEnvironment()
            }
            .sheet(isPresented: $showsSettings) {
                DinoSettingsView().environmentObject(player).gameEnvironment()
                    .presentationDetents([.large]).presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showsPractice) {
                NavigationStack {
                    DinoPracticeView()
                        .toolbar { ToolbarItem(placement: .confirmationAction) {
                            Button("dino.done") { showsPractice = false }.accessibilityIdentifier("practice.close")
                        } }
                }.gameEnvironment()
            }
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
                if friends.enabled { friends.refresh(); friends.scheduleSync() }
            }
            .onChange(of: player.profile.progressResetAt) { _, _ in showMap() }
    }

    private var companionClip: DinoAnimation.Clip {
        if showsCompletion { return .idle }
        if let result { return result.correct == result.level.questionCount ? .backflip : .idle }
        return gameCompanionClip
    }

    @ViewBuilder private var scene: some View {
        Group {
            if !player.profile.onboardingComplete { OnboardingFlow() }
            else if showsCompletion {
                WorldCompleteView(worldID: completedWorldID, nextWorld: nextWorld, map: showMap)
            }
            else if let result {
                DinoResultView(result: result, retry: { start(result.level) }, next: {
                    if result.level.isBoss { completedWorldID = result.level.worldID; showsCompletion = true }
                    else if let next = DinoLevelCatalog.level(result.level.id + 1) {
                        if next.isBoss { presentStartCard(next) } else { start(next) }
                    }
                }, map: showMap, sharedCompanion: true)
            } else if let session {
                DinoGameView(session: session, onExit: showMap, onResult: { value in
                    withAnimation(.easeOut(duration: 0.24)) {
                        self.result = value; self.session = nil
                    }
                }, onCompanionReaction: { gameCompanionClip = $0 }).id(ObjectIdentifier(session))
            } else {
                WorldMap(openLevel: presentStartCard, openSettings: { showsSettings = true }, openPractice: { showsPractice = true }, openCompletion: { completedWorldID = 10; showsCompletion = true }, openFriends: { showsFriends = true }, hudHeightChanged: { mapHUDHeight = $0 })
            }
        }
    }

    private func start(_ level: LevelConfiguration) {
        guard player.profile.isUnlocked(level.id) else { return }
        let nextSession = DinoSession(level: level, player: player, answerFeedback: { [settings] correct in
            DinoAnswerFeedback.shared.play(correct: correct, sound: settings.soundEffectsEnabled,
                                           vibration: settings.hapticsEnabled)
        })
        withAnimation(.easeOut(duration: 0.24)) {
            startCard = nil; result = nil; showsCompletion = false
            gameCompanionClip = .idle; session = nextSession
        }
    }
    private var nextWorld: (() -> Void)? {
        guard let world = DinoWorldCatalog.world(completedWorldID + 1),
              let level = DinoLevelCatalog.level(world.firstLevel) else { return nil }
        return { start(level) }
    }
    private func presentStartCard(_ level: LevelConfiguration) {
        withAnimation(.easeOut(duration: 0.24)) { startCard = level }
    }
    private func closeStartCard() {
        withAnimation(.easeOut(duration: 0.24)) { startCard = nil }
    }
    private func showMap() {
        withAnimation(.easeOut(duration: 0.24)) {
            session = nil; result = nil; showsCompletion = false; startCard = nil
        }
    }
}
