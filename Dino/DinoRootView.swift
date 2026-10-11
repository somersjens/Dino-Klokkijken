import SwiftUI
import Combine

struct DinoRootView: View {
    @EnvironmentObject private var player: DinoPlayer
    @EnvironmentObject private var friends: FriendsManager
    @State private var session: DinoSession?
    @State private var result: DinoLevelResult?
    @State private var showsSettings = false
    @State private var showsCompletion = false
    @State private var showsBossIntro = false
    @State private var showsFriends = false

    var body: some View {
        Group {
            if !player.profile.onboardingComplete { OnboardingFlow() }
            else if showsCompletion { WorldCompleteView(map: showMap) }
            else if let result {
                DinoResultView(result: result, retry: { start(result.level) }, next: {
                    if result.level.isBoss { showsCompletion = true }
                    else if let next = DinoLevelCatalog.level(result.level.id + 1) {
                        if next.isBoss { showsBossIntro = true } else { start(next) }
                    }
                }, map: showMap)
            } else if let session {
                DinoGameView(session: session, onExit: showMap, onResult: { value in
                    self.result = value; self.session = nil
                }).id(ObjectIdentifier(session))
            } else {
                WorldMap(openLevel: start, openSettings: { showsSettings = true }, openCompletion: { showsCompletion = true }, openFriends: { showsFriends = true })
            }
        }.preferredColorScheme(.light)
            .sheet(isPresented: $showsFriends) {
                DinoFriendsView().environmentObject(friends).gameEnvironment()
            }
            .sheet(isPresented: $showsSettings) {
                DinoSettingsView().environmentObject(player).gameEnvironment()
                    .presentationDetents([.large]).presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showsBossIntro) {
                LevelInfoPanel(level: DinoLevelCatalog.level(10)!) {
                    showsBossIntro = false
                    start(DinoLevelCatalog.level(10)!)
                }.environmentObject(player).gameEnvironment()
                    .presentationDetents([.height(620), .large]).presentationDragIndicator(.visible)
            }
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
                if friends.enabled { friends.refresh(); friends.scheduleSync() }
            }
    }

    private func start(_ level: LevelConfiguration) {
        guard player.profile.isUnlocked(level.id) else { return }
        result = nil; showsCompletion = false
        session = DinoSession(level: level, player: player)
    }
    private func showMap() { session = nil; result = nil; showsCompletion = false }
}
