import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct DinoTimeAdventureApp: App {
    @StateObject private var player = DinoPlayer()
    @StateObject private var language = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            DinoRootView().environmentObject(player)
                .environment(\.locale, language.locale)
                .environment(\.layoutDirection, language.effective.layoutDirection)
        }
    }
}

/// Existing language-picker layout helper retained from Hungry Frog.
enum AppLayout {
    static var isPad: Bool {
#if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad
#else
        false
#endif
    }
    static var landscapeContentWidth: CGFloat { isPad ? 1180 : 980 }
    static var landscapeGutter: CGFloat { isPad ? 28 : 16 }
}
