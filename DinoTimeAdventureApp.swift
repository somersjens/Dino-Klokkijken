import SwiftUI

@main
struct DinoTimeAdventureApp: App {
    @StateObject private var player = DinoPlayer()
    @StateObject private var language = LanguageManager.shared
    @StateObject private var friends = FriendsManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            DinoRootView().environmentObject(player).environmentObject(friends)
                .environment(\.locale, language.locale)
                .environment(\.layoutDirection, language.effective.layoutDirection)
                .background(GameCenterPresentationAnchor(manager: friends).frame(width: 0, height: 0))
                .task { friends.connect(player) }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { friends.foreground() }
                    else if phase == .background { friends.background() }
                }
        }
    }
}
