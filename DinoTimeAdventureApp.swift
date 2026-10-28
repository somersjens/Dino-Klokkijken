import SwiftUI
import UIKit

/// Keep the device policy explicit for every presented controller and window.
final class DinoOrientationDelegate: NSObject, UIApplicationDelegate {
    override init() {
        super.init()
        DinoInterface.lockLight()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        DinoInterface.lockLight()
        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        window?.overrideUserInterfaceStyle = .light
        return UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait
    }
}

/// The game is drawn for one palette. Dark Mode keeps that same light appearance.
enum DinoInterface {
    static func lockLight() {
        UIWindow.appearance().overrideUserInterfaceStyle = .light
        UITextField.appearance().keyboardAppearance = .light
        UITextView.appearance().keyboardAppearance = .light
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = .light
                lock(window.rootViewController)
            }
        }
    }

    private static func lock(_ controller: UIViewController?) {
        guard let controller else { return }
        controller.overrideUserInterfaceStyle = .light
        for child in controller.children { lock(child) }
        lock(controller.presentedViewController)
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
                .lightPalette()
                .task { friends.connect(player); cloudSync.connect(player: player, settings: settings) }
                .onValueChange(of: scenePhase) { phase in
                    if phase == .active {
                        DinoInterface.lockLight()
                        friends.foreground(); cloudSync.synchronize()
                    }
                    else if phase == .background { friends.background(); cloudSync.synchronize() }
                }
        }
    }
}
