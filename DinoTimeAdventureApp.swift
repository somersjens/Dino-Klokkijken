import SwiftUI
import UIKit

/// Keep the device policy explicit for every presented controller and window.
final class DinoOrientationDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait
    }
}

@main
struct DinoTimeAdventureApp: App {
    @UIApplicationDelegateAdaptor(DinoOrientationDelegate.self) private var orientationDelegate
    @StateObject private var player = DinoPlayer()
    @StateObject private var language = LanguageManager.shared
    @StateObject private var friends = FriendsManager()
    @StateObject private var settings = DinoSettings()
    @StateObject private var cloudSync = DinoCloudSync()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            DinoRootView().id(player.resetGeneration).environmentObject(player).environmentObject(friends)
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
