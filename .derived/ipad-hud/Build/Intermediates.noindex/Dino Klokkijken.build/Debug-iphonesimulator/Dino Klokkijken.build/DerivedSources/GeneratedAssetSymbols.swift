import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
extension ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = ColorResource(name: "AccentColor", bundle: resourceBundle)

    /// The "LaunchBackground" asset catalog color resource.
    static let launchBackground = ColorResource(name: "LaunchBackground", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
extension ImageResource {

    /// The "boss-castle" asset catalog image resource.
    static let bossCastle = ImageResource(name: "boss-castle", bundle: resourceBundle)

    /// The "boss-clock-city" asset catalog image resource.
    static let bossClockCity = ImageResource(name: "boss-clock-city", bundle: resourceBundle)

    /// The "boss-clock-village" asset catalog image resource.
    static let bossClockVillage = ImageResource(name: "boss-clock-village", bundle: resourceBundle)

    /// The "boss-crystal-cave" asset catalog image resource.
    static let bossCrystalCave = ImageResource(name: "boss-crystal-cave", bundle: resourceBundle)

    /// The "boss-desert" asset catalog image resource.
    static let bossDesert = ImageResource(name: "boss-desert", bundle: resourceBundle)

    /// The "boss-jungle" asset catalog image resource.
    static let bossJungle = ImageResource(name: "boss-jungle", bundle: resourceBundle)

    /// The "boss-pirates" asset catalog image resource.
    static let bossPirates = ImageResource(name: "boss-pirates", bundle: resourceBundle)

    /// The "boss-sleep-valley" asset catalog image resource.
    static let bossSleepValley = ImageResource(name: "boss-sleep-valley", bundle: resourceBundle)

    /// The "boss-time-machine" asset catalog image resource.
    static let bossTimeMachine = ImageResource(name: "boss-time-machine", bundle: resourceBundle)

    /// The "boss-volcano" asset catalog image resource.
    static let bossVolcano = ImageResource(name: "boss-volcano", bundle: resourceBundle)

    /// The "dino-answer-clap-01" asset catalog image resource.
    static let dinoAnswerClap01 = ImageResource(name: "dino-answer-clap-01", bundle: resourceBundle)

    /// The "dino-answer-clap-02" asset catalog image resource.
    static let dinoAnswerClap02 = ImageResource(name: "dino-answer-clap-02", bundle: resourceBundle)

    /// The "dino-answer-clap-03" asset catalog image resource.
    static let dinoAnswerClap03 = ImageResource(name: "dino-answer-clap-03", bundle: resourceBundle)

    /// The "dino-answer-clap-04" asset catalog image resource.
    static let dinoAnswerClap04 = ImageResource(name: "dino-answer-clap-04", bundle: resourceBundle)

    /// The "dino-answer-clap-05" asset catalog image resource.
    static let dinoAnswerClap05 = ImageResource(name: "dino-answer-clap-05", bundle: resourceBundle)

    /// The "dino-answer-clap-06" asset catalog image resource.
    static let dinoAnswerClap06 = ImageResource(name: "dino-answer-clap-06", bundle: resourceBundle)

    /// The "dino-answer-wrong" asset catalog image resource.
    static let dinoAnswerWrong = ImageResource(name: "dino-answer-wrong", bundle: resourceBundle)

    /// The "dino-idle" asset catalog image resource.
    static let dinoIdle = ImageResource(name: "dino-idle", bundle: resourceBundle)

    /// The "dino-opening-jump-01" asset catalog image resource.
    static let dinoOpeningJump01 = ImageResource(name: "dino-opening-jump-01", bundle: resourceBundle)

    /// The "dino-opening-jump-02" asset catalog image resource.
    static let dinoOpeningJump02 = ImageResource(name: "dino-opening-jump-02", bundle: resourceBundle)

    /// The "dino-opening-jump-03" asset catalog image resource.
    static let dinoOpeningJump03 = ImageResource(name: "dino-opening-jump-03", bundle: resourceBundle)

    /// The "dino-opening-jump-04" asset catalog image resource.
    static let dinoOpeningJump04 = ImageResource(name: "dino-opening-jump-04", bundle: resourceBundle)

    /// The "dino-opening-jump-05" asset catalog image resource.
    static let dinoOpeningJump05 = ImageResource(name: "dino-opening-jump-05", bundle: resourceBundle)

    /// The "dino-opening-jump-06" asset catalog image resource.
    static let dinoOpeningJump06 = ImageResource(name: "dino-opening-jump-06", bundle: resourceBundle)

    /// The "dino-opening-jump-07" asset catalog image resource.
    static let dinoOpeningJump07 = ImageResource(name: "dino-opening-jump-07", bundle: resourceBundle)

    /// The "dino-opening-jump-08" asset catalog image resource.
    static let dinoOpeningJump08 = ImageResource(name: "dino-opening-jump-08", bundle: resourceBundle)

    /// The "dino-result-backflip-airborne" asset catalog image resource.
    static let dinoResultBackflipAirborne = ImageResource(name: "dino-result-backflip-airborne", bundle: resourceBundle)

    /// The "dino-result-backflip-crouch" asset catalog image resource.
    static let dinoResultBackflipCrouch = ImageResource(name: "dino-result-backflip-crouch", bundle: resourceBundle)

    /// The "dino-result-backflip-landing" asset catalog image resource.
    static let dinoResultBackflipLanding = ImageResource(name: "dino-result-backflip-landing", bundle: resourceBundle)

    /// The "dino-result-backflip-recover" asset catalog image resource.
    static let dinoResultBackflipRecover = ImageResource(name: "dino-result-backflip-recover", bundle: resourceBundle)

    /// The "dino-result-fall-02" asset catalog image resource.
    static let dinoResultFall02 = ImageResource(name: "dino-result-fall-02", bundle: resourceBundle)

    /// The "dino-result-fall-03" asset catalog image resource.
    static let dinoResultFall03 = ImageResource(name: "dino-result-fall-03", bundle: resourceBundle)

    /// The "dino-result-fall-04" asset catalog image resource.
    static let dinoResultFall04 = ImageResource(name: "dino-result-fall-04", bundle: resourceBundle)

    /// The "dino-result-fall-05" asset catalog image resource.
    static let dinoResultFall05 = ImageResource(name: "dino-result-fall-05", bundle: resourceBundle)

    /// The "dino-result-fall-06" asset catalog image resource.
    static let dinoResultFall06 = ImageResource(name: "dino-result-fall-06", bundle: resourceBundle)

    /// The "dino-result-fall-07" asset catalog image resource.
    static let dinoResultFall07 = ImageResource(name: "dino-result-fall-07", bundle: resourceBundle)

    /// The "dino-result-fall-08" asset catalog image resource.
    static let dinoResultFall08 = ImageResource(name: "dino-result-fall-08", bundle: resourceBundle)

    /// The "dino-result-fall-09" asset catalog image resource.
    static let dinoResultFall09 = ImageResource(name: "dino-result-fall-09", bundle: resourceBundle)

    /// The "dino-result-fall-10" asset catalog image resource.
    static let dinoResultFall10 = ImageResource(name: "dino-result-fall-10", bundle: resourceBundle)

    /// The "dino-result-pirouette-01" asset catalog image resource.
    static let dinoResultPirouette01 = ImageResource(name: "dino-result-pirouette-01", bundle: resourceBundle)

    /// The "dino-result-pirouette-02" asset catalog image resource.
    static let dinoResultPirouette02 = ImageResource(name: "dino-result-pirouette-02", bundle: resourceBundle)

    /// The "dino-result-pirouette-03" asset catalog image resource.
    static let dinoResultPirouette03 = ImageResource(name: "dino-result-pirouette-03", bundle: resourceBundle)

    /// The "dino-result-pirouette-04" asset catalog image resource.
    static let dinoResultPirouette04 = ImageResource(name: "dino-result-pirouette-04", bundle: resourceBundle)

    /// The "dino-result-pirouette-05" asset catalog image resource.
    static let dinoResultPirouette05 = ImageResource(name: "dino-result-pirouette-05", bundle: resourceBundle)

    /// The "dino-result-pirouette-06" asset catalog image resource.
    static let dinoResultPirouette06 = ImageResource(name: "dino-result-pirouette-06", bundle: resourceBundle)

    /// The "dino-result-pirouette-07" asset catalog image resource.
    static let dinoResultPirouette07 = ImageResource(name: "dino-result-pirouette-07", bundle: resourceBundle)

    /// The "dino-result-pirouette-08" asset catalog image resource.
    static let dinoResultPirouette08 = ImageResource(name: "dino-result-pirouette-08", bundle: resourceBundle)

    /// The "dino-result-pirouette-09" asset catalog image resource.
    static let dinoResultPirouette09 = ImageResource(name: "dino-result-pirouette-09", bundle: resourceBundle)

    /// The "dino-result-pirouette-10" asset catalog image resource.
    static let dinoResultPirouette10 = ImageResource(name: "dino-result-pirouette-10", bundle: resourceBundle)

    /// The "dino-result-pirouette-11" asset catalog image resource.
    static let dinoResultPirouette11 = ImageResource(name: "dino-result-pirouette-11", bundle: resourceBundle)

    /// The "dino-result-pirouette-12" asset catalog image resource.
    static let dinoResultPirouette12 = ImageResource(name: "dino-result-pirouette-12", bundle: resourceBundle)

    /// The "dino-result-pirouette-13" asset catalog image resource.
    static let dinoResultPirouette13 = ImageResource(name: "dino-result-pirouette-13", bundle: resourceBundle)

    /// The "dino-result-pirouette-14" asset catalog image resource.
    static let dinoResultPirouette14 = ImageResource(name: "dino-result-pirouette-14", bundle: resourceBundle)

    /// The "dino-result-pirouette-15" asset catalog image resource.
    static let dinoResultPirouette15 = ImageResource(name: "dino-result-pirouette-15", bundle: resourceBundle)

    /// The "dino-result-pirouette-16" asset catalog image resource.
    static let dinoResultPirouette16 = ImageResource(name: "dino-result-pirouette-16", bundle: resourceBundle)

    /// The "dino-result-pirouette-17" asset catalog image resource.
    static let dinoResultPirouette17 = ImageResource(name: "dino-result-pirouette-17", bundle: resourceBundle)

    /// The "dino-result-pirouette-18" asset catalog image resource.
    static let dinoResultPirouette18 = ImageResource(name: "dino-result-pirouette-18", bundle: resourceBundle)

    /// The "dino-world-jump-airborne" asset catalog image resource.
    static let dinoWorldJumpAirborne = ImageResource(name: "dino-world-jump-airborne", bundle: resourceBundle)

    /// The "dino-world-jump-crouch" asset catalog image resource.
    static let dinoWorldJumpCrouch = ImageResource(name: "dino-world-jump-crouch", bundle: resourceBundle)

    /// The "dino-world-jump-landing" asset catalog image resource.
    static let dinoWorldJumpLanding = ImageResource(name: "dino-world-jump-landing", bundle: resourceBundle)

    /// The "dino-world-jump-recover" asset catalog image resource.
    static let dinoWorldJumpRecover = ImageResource(name: "dino-world-jump-recover", bundle: resourceBundle)

    /// The "dino-world-jump-takeoff" asset catalog image resource.
    static let dinoWorldJumpTakeoff = ImageResource(name: "dino-world-jump-takeoff", bundle: resourceBundle)

    /// The "reward-star" asset catalog image resource.
    static let rewardStar = ImageResource(name: "reward-star", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AccentColor" asset catalog color.
    static var accent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accent)
#else
        .init()
#endif
    }

    /// The "LaunchBackground" asset catalog color.
    static var launchBackground: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .launchBackground)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AccentColor" asset catalog color.
    static var accent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accent)
#else
        .init()
#endif
    }

    /// The "LaunchBackground" asset catalog color.
    static var launchBackground: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .launchBackground)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

    /// The "LaunchBackground" asset catalog color.
    static var launchBackground: SwiftUI.Color { .init(.launchBackground) }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

    /// The "LaunchBackground" asset catalog color.
    static var launchBackground: SwiftUI.Color { .init(.launchBackground) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "boss-castle" asset catalog image.
    static var bossCastle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bossCastle)
#else
        .init()
#endif
    }

    /// The "boss-clock-city" asset catalog image.
    static var bossClockCity: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bossClockCity)
#else
        .init()
#endif
    }

    /// The "boss-clock-village" asset catalog image.
    static var bossClockVillage: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bossClockVillage)
#else
        .init()
#endif
    }

    /// The "boss-crystal-cave" asset catalog image.
    static var bossCrystalCave: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bossCrystalCave)
#else
        .init()
#endif
    }

    /// The "boss-desert" asset catalog image.
    static var bossDesert: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bossDesert)
#else
        .init()
#endif
    }

    /// The "boss-jungle" asset catalog image.
    static var bossJungle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bossJungle)
#else
        .init()
#endif
    }

    /// The "boss-pirates" asset catalog image.
    static var bossPirates: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bossPirates)
#else
        .init()
#endif
    }

    /// The "boss-sleep-valley" asset catalog image.
    static var bossSleepValley: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bossSleepValley)
#else
        .init()
#endif
    }

    /// The "boss-time-machine" asset catalog image.
    static var bossTimeMachine: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bossTimeMachine)
#else
        .init()
#endif
    }

    /// The "boss-volcano" asset catalog image.
    static var bossVolcano: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bossVolcano)
#else
        .init()
#endif
    }

    /// The "dino-answer-clap-01" asset catalog image.
    static var dinoAnswerClap01: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoAnswerClap01)
#else
        .init()
#endif
    }

    /// The "dino-answer-clap-02" asset catalog image.
    static var dinoAnswerClap02: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoAnswerClap02)
#else
        .init()
#endif
    }

    /// The "dino-answer-clap-03" asset catalog image.
    static var dinoAnswerClap03: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoAnswerClap03)
#else
        .init()
#endif
    }

    /// The "dino-answer-clap-04" asset catalog image.
    static var dinoAnswerClap04: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoAnswerClap04)
#else
        .init()
#endif
    }

    /// The "dino-answer-clap-05" asset catalog image.
    static var dinoAnswerClap05: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoAnswerClap05)
#else
        .init()
#endif
    }

    /// The "dino-answer-clap-06" asset catalog image.
    static var dinoAnswerClap06: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoAnswerClap06)
#else
        .init()
#endif
    }

    /// The "dino-answer-wrong" asset catalog image.
    static var dinoAnswerWrong: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoAnswerWrong)
#else
        .init()
#endif
    }

    /// The "dino-idle" asset catalog image.
    static var dinoIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoIdle)
#else
        .init()
#endif
    }

    /// The "dino-opening-jump-01" asset catalog image.
    static var dinoOpeningJump01: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoOpeningJump01)
#else
        .init()
#endif
    }

    /// The "dino-opening-jump-02" asset catalog image.
    static var dinoOpeningJump02: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoOpeningJump02)
#else
        .init()
#endif
    }

    /// The "dino-opening-jump-03" asset catalog image.
    static var dinoOpeningJump03: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoOpeningJump03)
#else
        .init()
#endif
    }

    /// The "dino-opening-jump-04" asset catalog image.
    static var dinoOpeningJump04: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoOpeningJump04)
#else
        .init()
#endif
    }

    /// The "dino-opening-jump-05" asset catalog image.
    static var dinoOpeningJump05: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoOpeningJump05)
#else
        .init()
#endif
    }

    /// The "dino-opening-jump-06" asset catalog image.
    static var dinoOpeningJump06: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoOpeningJump06)
#else
        .init()
#endif
    }

    /// The "dino-opening-jump-07" asset catalog image.
    static var dinoOpeningJump07: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoOpeningJump07)
#else
        .init()
#endif
    }

    /// The "dino-opening-jump-08" asset catalog image.
    static var dinoOpeningJump08: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoOpeningJump08)
#else
        .init()
#endif
    }

    /// The "dino-result-backflip-airborne" asset catalog image.
    static var dinoResultBackflipAirborne: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultBackflipAirborne)
#else
        .init()
#endif
    }

    /// The "dino-result-backflip-crouch" asset catalog image.
    static var dinoResultBackflipCrouch: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultBackflipCrouch)
#else
        .init()
#endif
    }

    /// The "dino-result-backflip-landing" asset catalog image.
    static var dinoResultBackflipLanding: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultBackflipLanding)
#else
        .init()
#endif
    }

    /// The "dino-result-backflip-recover" asset catalog image.
    static var dinoResultBackflipRecover: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultBackflipRecover)
#else
        .init()
#endif
    }

    /// The "dino-result-fall-02" asset catalog image.
    static var dinoResultFall02: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultFall02)
#else
        .init()
#endif
    }

    /// The "dino-result-fall-03" asset catalog image.
    static var dinoResultFall03: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultFall03)
#else
        .init()
#endif
    }

    /// The "dino-result-fall-04" asset catalog image.
    static var dinoResultFall04: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultFall04)
#else
        .init()
#endif
    }

    /// The "dino-result-fall-05" asset catalog image.
    static var dinoResultFall05: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultFall05)
#else
        .init()
#endif
    }

    /// The "dino-result-fall-06" asset catalog image.
    static var dinoResultFall06: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultFall06)
#else
        .init()
#endif
    }

    /// The "dino-result-fall-07" asset catalog image.
    static var dinoResultFall07: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultFall07)
#else
        .init()
#endif
    }

    /// The "dino-result-fall-08" asset catalog image.
    static var dinoResultFall08: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultFall08)
#else
        .init()
#endif
    }

    /// The "dino-result-fall-09" asset catalog image.
    static var dinoResultFall09: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultFall09)
#else
        .init()
#endif
    }

    /// The "dino-result-fall-10" asset catalog image.
    static var dinoResultFall10: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultFall10)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-01" asset catalog image.
    static var dinoResultPirouette01: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultPirouette01)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-02" asset catalog image.
    static var dinoResultPirouette02: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultPirouette02)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-03" asset catalog image.
    static var dinoResultPirouette03: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultPirouette03)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-04" asset catalog image.
    static var dinoResultPirouette04: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultPirouette04)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-05" asset catalog image.
    static var dinoResultPirouette05: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultPirouette05)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-06" asset catalog image.
    static var dinoResultPirouette06: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultPirouette06)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-07" asset catalog image.
    static var dinoResultPirouette07: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultPirouette07)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-08" asset catalog image.
    static var dinoResultPirouette08: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultPirouette08)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-09" asset catalog image.
    static var dinoResultPirouette09: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultPirouette09)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-10" asset catalog image.
    static var dinoResultPirouette10: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultPirouette10)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-11" asset catalog image.
    static var dinoResultPirouette11: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultPirouette11)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-12" asset catalog image.
    static var dinoResultPirouette12: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultPirouette12)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-13" asset catalog image.
    static var dinoResultPirouette13: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultPirouette13)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-14" asset catalog image.
    static var dinoResultPirouette14: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultPirouette14)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-15" asset catalog image.
    static var dinoResultPirouette15: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultPirouette15)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-16" asset catalog image.
    static var dinoResultPirouette16: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultPirouette16)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-17" asset catalog image.
    static var dinoResultPirouette17: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultPirouette17)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-18" asset catalog image.
    static var dinoResultPirouette18: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoResultPirouette18)
#else
        .init()
#endif
    }

    /// The "dino-world-jump-airborne" asset catalog image.
    static var dinoWorldJumpAirborne: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoWorldJumpAirborne)
#else
        .init()
#endif
    }

    /// The "dino-world-jump-crouch" asset catalog image.
    static var dinoWorldJumpCrouch: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoWorldJumpCrouch)
#else
        .init()
#endif
    }

    /// The "dino-world-jump-landing" asset catalog image.
    static var dinoWorldJumpLanding: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoWorldJumpLanding)
#else
        .init()
#endif
    }

    /// The "dino-world-jump-recover" asset catalog image.
    static var dinoWorldJumpRecover: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoWorldJumpRecover)
#else
        .init()
#endif
    }

    /// The "dino-world-jump-takeoff" asset catalog image.
    static var dinoWorldJumpTakeoff: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dinoWorldJumpTakeoff)
#else
        .init()
#endif
    }

    /// The "reward-star" asset catalog image.
    static var rewardStar: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .rewardStar)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "boss-castle" asset catalog image.
    static var bossCastle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bossCastle)
#else
        .init()
#endif
    }

    /// The "boss-clock-city" asset catalog image.
    static var bossClockCity: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bossClockCity)
#else
        .init()
#endif
    }

    /// The "boss-clock-village" asset catalog image.
    static var bossClockVillage: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bossClockVillage)
#else
        .init()
#endif
    }

    /// The "boss-crystal-cave" asset catalog image.
    static var bossCrystalCave: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bossCrystalCave)
#else
        .init()
#endif
    }

    /// The "boss-desert" asset catalog image.
    static var bossDesert: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bossDesert)
#else
        .init()
#endif
    }

    /// The "boss-jungle" asset catalog image.
    static var bossJungle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bossJungle)
#else
        .init()
#endif
    }

    /// The "boss-pirates" asset catalog image.
    static var bossPirates: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bossPirates)
#else
        .init()
#endif
    }

    /// The "boss-sleep-valley" asset catalog image.
    static var bossSleepValley: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bossSleepValley)
#else
        .init()
#endif
    }

    /// The "boss-time-machine" asset catalog image.
    static var bossTimeMachine: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bossTimeMachine)
#else
        .init()
#endif
    }

    /// The "boss-volcano" asset catalog image.
    static var bossVolcano: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bossVolcano)
#else
        .init()
#endif
    }

    /// The "dino-answer-clap-01" asset catalog image.
    static var dinoAnswerClap01: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoAnswerClap01)
#else
        .init()
#endif
    }

    /// The "dino-answer-clap-02" asset catalog image.
    static var dinoAnswerClap02: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoAnswerClap02)
#else
        .init()
#endif
    }

    /// The "dino-answer-clap-03" asset catalog image.
    static var dinoAnswerClap03: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoAnswerClap03)
#else
        .init()
#endif
    }

    /// The "dino-answer-clap-04" asset catalog image.
    static var dinoAnswerClap04: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoAnswerClap04)
#else
        .init()
#endif
    }

    /// The "dino-answer-clap-05" asset catalog image.
    static var dinoAnswerClap05: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoAnswerClap05)
#else
        .init()
#endif
    }

    /// The "dino-answer-clap-06" asset catalog image.
    static var dinoAnswerClap06: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoAnswerClap06)
#else
        .init()
#endif
    }

    /// The "dino-answer-wrong" asset catalog image.
    static var dinoAnswerWrong: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoAnswerWrong)
#else
        .init()
#endif
    }

    /// The "dino-idle" asset catalog image.
    static var dinoIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoIdle)
#else
        .init()
#endif
    }

    /// The "dino-opening-jump-01" asset catalog image.
    static var dinoOpeningJump01: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoOpeningJump01)
#else
        .init()
#endif
    }

    /// The "dino-opening-jump-02" asset catalog image.
    static var dinoOpeningJump02: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoOpeningJump02)
#else
        .init()
#endif
    }

    /// The "dino-opening-jump-03" asset catalog image.
    static var dinoOpeningJump03: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoOpeningJump03)
#else
        .init()
#endif
    }

    /// The "dino-opening-jump-04" asset catalog image.
    static var dinoOpeningJump04: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoOpeningJump04)
#else
        .init()
#endif
    }

    /// The "dino-opening-jump-05" asset catalog image.
    static var dinoOpeningJump05: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoOpeningJump05)
#else
        .init()
#endif
    }

    /// The "dino-opening-jump-06" asset catalog image.
    static var dinoOpeningJump06: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoOpeningJump06)
#else
        .init()
#endif
    }

    /// The "dino-opening-jump-07" asset catalog image.
    static var dinoOpeningJump07: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoOpeningJump07)
#else
        .init()
#endif
    }

    /// The "dino-opening-jump-08" asset catalog image.
    static var dinoOpeningJump08: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoOpeningJump08)
#else
        .init()
#endif
    }

    /// The "dino-result-backflip-airborne" asset catalog image.
    static var dinoResultBackflipAirborne: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultBackflipAirborne)
#else
        .init()
#endif
    }

    /// The "dino-result-backflip-crouch" asset catalog image.
    static var dinoResultBackflipCrouch: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultBackflipCrouch)
#else
        .init()
#endif
    }

    /// The "dino-result-backflip-landing" asset catalog image.
    static var dinoResultBackflipLanding: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultBackflipLanding)
#else
        .init()
#endif
    }

    /// The "dino-result-backflip-recover" asset catalog image.
    static var dinoResultBackflipRecover: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultBackflipRecover)
#else
        .init()
#endif
    }

    /// The "dino-result-fall-02" asset catalog image.
    static var dinoResultFall02: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultFall02)
#else
        .init()
#endif
    }

    /// The "dino-result-fall-03" asset catalog image.
    static var dinoResultFall03: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultFall03)
#else
        .init()
#endif
    }

    /// The "dino-result-fall-04" asset catalog image.
    static var dinoResultFall04: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultFall04)
#else
        .init()
#endif
    }

    /// The "dino-result-fall-05" asset catalog image.
    static var dinoResultFall05: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultFall05)
#else
        .init()
#endif
    }

    /// The "dino-result-fall-06" asset catalog image.
    static var dinoResultFall06: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultFall06)
#else
        .init()
#endif
    }

    /// The "dino-result-fall-07" asset catalog image.
    static var dinoResultFall07: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultFall07)
#else
        .init()
#endif
    }

    /// The "dino-result-fall-08" asset catalog image.
    static var dinoResultFall08: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultFall08)
#else
        .init()
#endif
    }

    /// The "dino-result-fall-09" asset catalog image.
    static var dinoResultFall09: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultFall09)
#else
        .init()
#endif
    }

    /// The "dino-result-fall-10" asset catalog image.
    static var dinoResultFall10: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultFall10)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-01" asset catalog image.
    static var dinoResultPirouette01: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultPirouette01)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-02" asset catalog image.
    static var dinoResultPirouette02: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultPirouette02)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-03" asset catalog image.
    static var dinoResultPirouette03: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultPirouette03)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-04" asset catalog image.
    static var dinoResultPirouette04: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultPirouette04)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-05" asset catalog image.
    static var dinoResultPirouette05: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultPirouette05)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-06" asset catalog image.
    static var dinoResultPirouette06: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultPirouette06)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-07" asset catalog image.
    static var dinoResultPirouette07: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultPirouette07)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-08" asset catalog image.
    static var dinoResultPirouette08: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultPirouette08)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-09" asset catalog image.
    static var dinoResultPirouette09: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultPirouette09)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-10" asset catalog image.
    static var dinoResultPirouette10: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultPirouette10)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-11" asset catalog image.
    static var dinoResultPirouette11: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultPirouette11)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-12" asset catalog image.
    static var dinoResultPirouette12: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultPirouette12)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-13" asset catalog image.
    static var dinoResultPirouette13: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultPirouette13)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-14" asset catalog image.
    static var dinoResultPirouette14: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultPirouette14)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-15" asset catalog image.
    static var dinoResultPirouette15: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultPirouette15)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-16" asset catalog image.
    static var dinoResultPirouette16: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultPirouette16)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-17" asset catalog image.
    static var dinoResultPirouette17: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultPirouette17)
#else
        .init()
#endif
    }

    /// The "dino-result-pirouette-18" asset catalog image.
    static var dinoResultPirouette18: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoResultPirouette18)
#else
        .init()
#endif
    }

    /// The "dino-world-jump-airborne" asset catalog image.
    static var dinoWorldJumpAirborne: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoWorldJumpAirborne)
#else
        .init()
#endif
    }

    /// The "dino-world-jump-crouch" asset catalog image.
    static var dinoWorldJumpCrouch: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoWorldJumpCrouch)
#else
        .init()
#endif
    }

    /// The "dino-world-jump-landing" asset catalog image.
    static var dinoWorldJumpLanding: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoWorldJumpLanding)
#else
        .init()
#endif
    }

    /// The "dino-world-jump-recover" asset catalog image.
    static var dinoWorldJumpRecover: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoWorldJumpRecover)
#else
        .init()
#endif
    }

    /// The "dino-world-jump-takeoff" asset catalog image.
    static var dinoWorldJumpTakeoff: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dinoWorldJumpTakeoff)
#else
        .init()
#endif
    }

    /// The "reward-star" asset catalog image.
    static var rewardStar: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .rewardStar)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
@available(watchOS, unavailable)
extension ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
@available(watchOS, unavailable)
extension ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

// MARK: - Backwards Deployment Support -

/// A color resource.
struct ColorResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog color resource name.
    fileprivate let name: Swift.String

    /// An asset catalog color resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize a `ColorResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

/// An image resource.
struct ImageResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog image resource name.
    fileprivate let name: Swift.String

    /// An asset catalog image resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize an `ImageResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// Initialize a `NSColor` with a color resource.
    convenience init(resource: ColorResource) {
        self.init(named: NSColor.Name(resource.name), bundle: resource.bundle)!
    }

}

protocol _ACResourceInitProtocol {}
extension AppKit.NSImage: _ACResourceInitProtocol {}

@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension _ACResourceInitProtocol {

    /// Initialize a `NSImage` with an image resource.
    init(resource: ImageResource) {
        self = resource.bundle.image(forResource: NSImage.Name(resource.name))! as! Self
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// Initialize a `UIColor` with a color resource.
    convenience init(resource: ColorResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}

@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// Initialize a `UIImage` with an image resource.
    convenience init(resource: ImageResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    /// Initialize a `Color` with a color resource.
    init(_ resource: ColorResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Image {

    /// Initialize an `Image` with an image resource.
    init(_ resource: ImageResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}
#endif