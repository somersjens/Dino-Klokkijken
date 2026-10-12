import SwiftUI

@main
struct DinoTimeAdventureApp: App {
    @StateObject private var player = DinoPlayer()
    @StateObject private var language = LanguageManager.shared
    @StateObject private var friends = FriendsManager()
    @StateObject private var settings = DinoSettings()
    @StateObject private var cloudSync = DinoCloudSync()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            DinoRootView().environmentObject(player).environmentObject(friends)
                .environmentObject(settings).environmentObject(cloudSync)
                .environment(\.locale, language.locale)
                .environment(\.layoutDirection, language.effective.layoutDirection)
                .modifier(DinoContrastEnvironment(enabled: settings.highContrastEnabled))
                .background(GameCenterPresentationAnchor(manager: friends).frame(width: 0, height: 0))
                .task { friends.connect(player); cloudSync.connect(player: player, settings: settings) }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { friends.foreground(); cloudSync.synchronize() }
                    else if phase == .background { friends.background(); cloudSync.synchronize() }
                }
        }
    }
}
