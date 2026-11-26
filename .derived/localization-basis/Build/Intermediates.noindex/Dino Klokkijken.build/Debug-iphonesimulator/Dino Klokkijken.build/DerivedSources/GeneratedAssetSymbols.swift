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

    /// The "castle-back" asset catalog image resource.
    static let castleBack = ImageResource(name: "castle-back", bundle: resourceBundle)

    /// The "castle-brace" asset catalog image resource.
    static let castleBrace = ImageResource(name: "castle-brace", bundle: resourceBundle)

    /// The "castle-clap-contact" asset catalog image resource.
    static let castleClapContact = ImageResource(name: "castle-clap-contact", bundle: resourceBundle)

    /// The "castle-clap-open" asset catalog image resource.
    static let castleClapOpen = ImageResource(name: "castle-clap-open", bundle: resourceBundle)

    /// The "castle-fallen" asset catalog image resource.
    static let castleFallen = ImageResource(name: "castle-fallen", bundle: resourceBundle)

    /// The "castle-front" asset catalog image resource.
    static let castleFront = ImageResource(name: "castle-front", bundle: resourceBundle)

    /// The "castle-idle" asset catalog image resource.
    static let castleIdle = ImageResource(name: "castle-idle", bundle: resourceBundle)

    /// The "castle-lift" asset catalog image resource.
    static let castleLift = ImageResource(name: "castle-lift", bundle: resourceBundle)

    /// The "castle-opening-idle" asset catalog image resource.
    static let castleOpeningIdle = ImageResource(name: "castle-opening-idle", bundle: resourceBundle)

    /// The "castle-rear-left" asset catalog image resource.
    static let castleRearLeft = ImageResource(name: "castle-rear-left", bundle: resourceBundle)

    /// The "castle-rear-right" asset catalog image resource.
    static let castleRearRight = ImageResource(name: "castle-rear-right", bundle: resourceBundle)

    /// The "castle-recover" asset catalog image resource.
    static let castleRecover = ImageResource(name: "castle-recover", bundle: resourceBundle)

    /// The "castle-side-left" asset catalog image resource.
    static let castleSideLeft = ImageResource(name: "castle-side-left", bundle: resourceBundle)

    /// The "castle-side-right" asset catalog image resource.
    static let castleSideRight = ImageResource(name: "castle-side-right", bundle: resourceBundle)

    /// The "castle-stumble" asset catalog image resource.
    static let castleStumble = ImageResource(name: "castle-stumble", bundle: resourceBundle)

    /// The "castle-wrong" asset catalog image resource.
    static let castleWrong = ImageResource(name: "castle-wrong", bundle: resourceBundle)

    /// The "cave-airborne" asset catalog image resource.
    static let caveAirborne = ImageResource(name: "cave-airborne", bundle: resourceBundle)

    /// The "cave-clap-contact" asset catalog image resource.
    static let caveClapContact = ImageResource(name: "cave-clap-contact", bundle: resourceBundle)

    /// The "cave-clap-open" asset catalog image resource.
    static let caveClapOpen = ImageResource(name: "cave-clap-open", bundle: resourceBundle)

    /// The "cave-clap-release" asset catalog image resource.
    static let caveClapRelease = ImageResource(name: "cave-clap-release", bundle: resourceBundle)

    /// The "cave-crouch" asset catalog image resource.
    static let caveCrouch = ImageResource(name: "cave-crouch", bundle: resourceBundle)

    /// The "cave-fallen" asset catalog image resource.
    static let caveFallen = ImageResource(name: "cave-fallen", bundle: resourceBundle)

    /// The "cave-idle" asset catalog image resource.
    static let caveIdle = ImageResource(name: "cave-idle", bundle: resourceBundle)

    /// The "cave-opening-idle" asset catalog image resource.
    static let caveOpeningIdle = ImageResource(name: "cave-opening-idle", bundle: resourceBundle)

    /// The "cave-push-up" asset catalog image resource.
    static let cavePushUp = ImageResource(name: "cave-push-up", bundle: resourceBundle)

    /// The "cave-recover" asset catalog image resource.
    static let caveRecover = ImageResource(name: "cave-recover", bundle: resourceBundle)

    /// The "cave-stumble" asset catalog image resource.
    static let caveStumble = ImageResource(name: "cave-stumble", bundle: resourceBundle)

    /// The "cave-turn-02" asset catalog image resource.
    static let caveTurn02 = ImageResource(name: "cave-turn-02", bundle: resourceBundle)

    /// The "cave-turn-03" asset catalog image resource.
    static let caveTurn03 = ImageResource(name: "cave-turn-03", bundle: resourceBundle)

    /// The "cave-turn-04" asset catalog image resource.
    static let caveTurn04 = ImageResource(name: "cave-turn-04", bundle: resourceBundle)

    /// The "cave-turn-05" asset catalog image resource.
    static let caveTurn05 = ImageResource(name: "cave-turn-05", bundle: resourceBundle)

    /// The "cave-turn-06" asset catalog image resource.
    static let caveTurn06 = ImageResource(name: "cave-turn-06", bundle: resourceBundle)

    /// The "cave-turn-07" asset catalog image resource.
    static let caveTurn07 = ImageResource(name: "cave-turn-07", bundle: resourceBundle)

    /// The "cave-turn-08" asset catalog image resource.
    static let caveTurn08 = ImageResource(name: "cave-turn-08", bundle: resourceBundle)

    /// The "cave-wrong" asset catalog image resource.
    static let caveWrong = ImageResource(name: "cave-wrong", bundle: resourceBundle)

    /// The "city-airborne" asset catalog image resource.
    static let cityAirborne = ImageResource(name: "city-airborne", bundle: resourceBundle)

    /// The "city-clap-contact" asset catalog image resource.
    static let cityClapContact = ImageResource(name: "city-clap-contact", bundle: resourceBundle)

    /// The "city-clap-open" asset catalog image resource.
    static let cityClapOpen = ImageResource(name: "city-clap-open", bundle: resourceBundle)

    /// The "city-crouch" asset catalog image resource.
    static let cityCrouch = ImageResource(name: "city-crouch", bundle: resourceBundle)

    /// The "city-fallen" asset catalog image resource.
    static let cityFallen = ImageResource(name: "city-fallen", bundle: resourceBundle)

    /// The "city-idle" asset catalog image resource.
    static let cityIdle = ImageResource(name: "city-idle", bundle: resourceBundle)

    /// The "city-opening-idle" asset catalog image resource.
    static let cityOpeningIdle = ImageResource(name: "city-opening-idle", bundle: resourceBundle)

    /// The "city-push-up" asset catalog image resource.
    static let cityPushUp = ImageResource(name: "city-push-up", bundle: resourceBundle)

    /// The "city-stumble" asset catalog image resource.
    static let cityStumble = ImageResource(name: "city-stumble", bundle: resourceBundle)

    /// The "city-turn-02" asset catalog image resource.
    static let cityTurn02 = ImageResource(name: "city-turn-02", bundle: resourceBundle)

    /// The "city-turn-03" asset catalog image resource.
    static let cityTurn03 = ImageResource(name: "city-turn-03", bundle: resourceBundle)

    /// The "city-turn-04" asset catalog image resource.
    static let cityTurn04 = ImageResource(name: "city-turn-04", bundle: resourceBundle)

    /// The "city-turn-05" asset catalog image resource.
    static let cityTurn05 = ImageResource(name: "city-turn-05", bundle: resourceBundle)

    /// The "city-turn-06" asset catalog image resource.
    static let cityTurn06 = ImageResource(name: "city-turn-06", bundle: resourceBundle)

    /// The "city-turn-07" asset catalog image resource.
    static let cityTurn07 = ImageResource(name: "city-turn-07", bundle: resourceBundle)

    /// The "city-turn-08" asset catalog image resource.
    static let cityTurn08 = ImageResource(name: "city-turn-08", bundle: resourceBundle)

    /// The "city-wrong" asset catalog image resource.
    static let cityWrong = ImageResource(name: "city-wrong", bundle: resourceBundle)

    /// The "desert-airborne" asset catalog image resource.
    static let desertAirborne = ImageResource(name: "desert-airborne", bundle: resourceBundle)

    /// The "desert-clap-contact" asset catalog image resource.
    static let desertClapContact = ImageResource(name: "desert-clap-contact", bundle: resourceBundle)

    /// The "desert-clap-contact-2" asset catalog image resource.
    static let desertClapContact2 = ImageResource(name: "desert-clap-contact-2", bundle: resourceBundle)

    /// The "desert-clap-open" asset catalog image resource.
    static let desertClapOpen = ImageResource(name: "desert-clap-open", bundle: resourceBundle)

    /// The "desert-clap-open-2" asset catalog image resource.
    static let desertClapOpen2 = ImageResource(name: "desert-clap-open-2", bundle: resourceBundle)

    /// The "desert-crouch" asset catalog image resource.
    static let desertCrouch = ImageResource(name: "desert-crouch", bundle: resourceBundle)

    /// The "desert-fallen" asset catalog image resource.
    static let desertFallen = ImageResource(name: "desert-fallen", bundle: resourceBundle)

    /// The "desert-idle" asset catalog image resource.
    static let desertIdle = ImageResource(name: "desert-idle", bundle: resourceBundle)

    /// The "desert-landing" asset catalog image resource.
    static let desertLanding = ImageResource(name: "desert-landing", bundle: resourceBundle)

    /// The "desert-opening-idle" asset catalog image resource.
    static let desertOpeningIdle = ImageResource(name: "desert-opening-idle", bundle: resourceBundle)

    /// The "desert-push-up" asset catalog image resource.
    static let desertPushUp = ImageResource(name: "desert-push-up", bundle: resourceBundle)

    /// The "desert-stumble" asset catalog image resource.
    static let desertStumble = ImageResource(name: "desert-stumble", bundle: resourceBundle)

    /// The "desert-takeoff" asset catalog image resource.
    static let desertTakeoff = ImageResource(name: "desert-takeoff", bundle: resourceBundle)

    /// The "desert-turn-01" asset catalog image resource.
    static let desertTurn01 = ImageResource(name: "desert-turn-01", bundle: resourceBundle)

    /// The "desert-turn-02" asset catalog image resource.
    static let desertTurn02 = ImageResource(name: "desert-turn-02", bundle: resourceBundle)

    /// The "desert-turn-03" asset catalog image resource.
    static let desertTurn03 = ImageResource(name: "desert-turn-03", bundle: resourceBundle)

    /// The "desert-turn-04" asset catalog image resource.
    static let desertTurn04 = ImageResource(name: "desert-turn-04", bundle: resourceBundle)

    /// The "desert-turn-05" asset catalog image resource.
    static let desertTurn05 = ImageResource(name: "desert-turn-05", bundle: resourceBundle)

    /// The "desert-turn-06" asset catalog image resource.
    static let desertTurn06 = ImageResource(name: "desert-turn-06", bundle: resourceBundle)

    /// The "desert-turn-07" asset catalog image resource.
    static let desertTurn07 = ImageResource(name: "desert-turn-07", bundle: resourceBundle)

    /// The "desert-turn-08" asset catalog image resource.
    static let desertTurn08 = ImageResource(name: "desert-turn-08", bundle: resourceBundle)

    /// The "desert-wrong" asset catalog image resource.
    static let desertWrong = ImageResource(name: "desert-wrong", bundle: resourceBundle)

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

    /// The "jungle-airborne" asset catalog image resource.
    static let jungleAirborne = ImageResource(name: "jungle-airborne", bundle: resourceBundle)

    /// The "jungle-clap-contact" asset catalog image resource.
    static let jungleClapContact = ImageResource(name: "jungle-clap-contact", bundle: resourceBundle)

    /// The "jungle-clap-contact-2" asset catalog image resource.
    static let jungleClapContact2 = ImageResource(name: "jungle-clap-contact-2", bundle: resourceBundle)

    /// The "jungle-clap-open" asset catalog image resource.
    static let jungleClapOpen = ImageResource(name: "jungle-clap-open", bundle: resourceBundle)

    /// The "jungle-clap-open-2" asset catalog image resource.
    static let jungleClapOpen2 = ImageResource(name: "jungle-clap-open-2", bundle: resourceBundle)

    /// The "jungle-crouch" asset catalog image resource.
    static let jungleCrouch = ImageResource(name: "jungle-crouch", bundle: resourceBundle)

    /// The "jungle-fallen" asset catalog image resource.
    static let jungleFallen = ImageResource(name: "jungle-fallen", bundle: resourceBundle)

    /// The "jungle-idle" asset catalog image resource.
    static let jungleIdle = ImageResource(name: "jungle-idle", bundle: resourceBundle)

    /// The "jungle-landing" asset catalog image resource.
    static let jungleLanding = ImageResource(name: "jungle-landing", bundle: resourceBundle)

    /// The "jungle-opening-idle" asset catalog image resource.
    static let jungleOpeningIdle = ImageResource(name: "jungle-opening-idle", bundle: resourceBundle)

    /// The "jungle-push-up" asset catalog image resource.
    static let junglePushUp = ImageResource(name: "jungle-push-up", bundle: resourceBundle)

    /// The "jungle-recover" asset catalog image resource.
    static let jungleRecover = ImageResource(name: "jungle-recover", bundle: resourceBundle)

    /// The "jungle-stumble" asset catalog image resource.
    static let jungleStumble = ImageResource(name: "jungle-stumble", bundle: resourceBundle)

    /// The "jungle-takeoff" asset catalog image resource.
    static let jungleTakeoff = ImageResource(name: "jungle-takeoff", bundle: resourceBundle)

    /// The "jungle-turn-01" asset catalog image resource.
    static let jungleTurn01 = ImageResource(name: "jungle-turn-01", bundle: resourceBundle)

    /// The "jungle-turn-02" asset catalog image resource.
    static let jungleTurn02 = ImageResource(name: "jungle-turn-02", bundle: resourceBundle)

    /// The "jungle-turn-03" asset catalog image resource.
    static let jungleTurn03 = ImageResource(name: "jungle-turn-03", bundle: resourceBundle)

    /// The "jungle-turn-04" asset catalog image resource.
    static let jungleTurn04 = ImageResource(name: "jungle-turn-04", bundle: resourceBundle)

    /// The "jungle-turn-05" asset catalog image resource.
    static let jungleTurn05 = ImageResource(name: "jungle-turn-05", bundle: resourceBundle)

    /// The "jungle-turn-06" asset catalog image resource.
    static let jungleTurn06 = ImageResource(name: "jungle-turn-06", bundle: resourceBundle)

    /// The "jungle-turn-07" asset catalog image resource.
    static let jungleTurn07 = ImageResource(name: "jungle-turn-07", bundle: resourceBundle)

    /// The "jungle-turn-08" asset catalog image resource.
    static let jungleTurn08 = ImageResource(name: "jungle-turn-08", bundle: resourceBundle)

    /// The "jungle-wrong" asset catalog image resource.
    static let jungleWrong = ImageResource(name: "jungle-wrong", bundle: resourceBundle)

    /// The "machine-airborne" asset catalog image resource.
    static let machineAirborne = ImageResource(name: "machine-airborne", bundle: resourceBundle)

    /// The "machine-brace" asset catalog image resource.
    static let machineBrace = ImageResource(name: "machine-brace", bundle: resourceBundle)

    /// The "machine-clap-contact" asset catalog image resource.
    static let machineClapContact = ImageResource(name: "machine-clap-contact", bundle: resourceBundle)

    /// The "machine-clap-open" asset catalog image resource.
    static let machineClapOpen = ImageResource(name: "machine-clap-open", bundle: resourceBundle)

    /// The "machine-crouch" asset catalog image resource.
    static let machineCrouch = ImageResource(name: "machine-crouch", bundle: resourceBundle)

    /// The "machine-idle" asset catalog image resource.
    static let machineIdle = ImageResource(name: "machine-idle", bundle: resourceBundle)

    /// The "machine-opening-idle" asset catalog image resource.
    static let machineOpeningIdle = ImageResource(name: "machine-opening-idle", bundle: resourceBundle)

    /// The "machine-turn-back" asset catalog image resource.
    static let machineTurnBack = ImageResource(name: "machine-turn-back", bundle: resourceBundle)

    /// The "machine-turn-back-left" asset catalog image resource.
    static let machineTurnBackLeft = ImageResource(name: "machine-turn-back-left", bundle: resourceBundle)

    /// The "machine-turn-back-right" asset catalog image resource.
    static let machineTurnBackRight = ImageResource(name: "machine-turn-back-right", bundle: resourceBundle)

    /// The "machine-turn-front" asset catalog image resource.
    static let machineTurnFront = ImageResource(name: "machine-turn-front", bundle: resourceBundle)

    /// The "machine-turn-front-right" asset catalog image resource.
    static let machineTurnFrontRight = ImageResource(name: "machine-turn-front-right", bundle: resourceBundle)

    /// The "machine-turn-side-left" asset catalog image resource.
    static let machineTurnSideLeft = ImageResource(name: "machine-turn-side-left", bundle: resourceBundle)

    /// The "machine-turn-side-right" asset catalog image resource.
    static let machineTurnSideRight = ImageResource(name: "machine-turn-side-right", bundle: resourceBundle)

    /// The "machine-wrong" asset catalog image resource.
    static let machineWrong = ImageResource(name: "machine-wrong", bundle: resourceBundle)

    /// The "pirate-airborne" asset catalog image resource.
    static let pirateAirborne = ImageResource(name: "pirate-airborne", bundle: resourceBundle)

    /// The "pirate-clap-contact" asset catalog image resource.
    static let pirateClapContact = ImageResource(name: "pirate-clap-contact", bundle: resourceBundle)

    /// The "pirate-clap-open" asset catalog image resource.
    static let pirateClapOpen = ImageResource(name: "pirate-clap-open", bundle: resourceBundle)

    /// The "pirate-crouch" asset catalog image resource.
    static let pirateCrouch = ImageResource(name: "pirate-crouch", bundle: resourceBundle)

    /// The "pirate-fallen" asset catalog image resource.
    static let pirateFallen = ImageResource(name: "pirate-fallen", bundle: resourceBundle)

    /// The "pirate-idle" asset catalog image resource.
    static let pirateIdle = ImageResource(name: "pirate-idle", bundle: resourceBundle)

    /// The "pirate-opening-idle" asset catalog image resource.
    static let pirateOpeningIdle = ImageResource(name: "pirate-opening-idle", bundle: resourceBundle)

    /// The "pirate-push-up" asset catalog image resource.
    static let piratePushUp = ImageResource(name: "pirate-push-up", bundle: resourceBundle)

    /// The "pirate-stumble" asset catalog image resource.
    static let pirateStumble = ImageResource(name: "pirate-stumble", bundle: resourceBundle)

    /// The "pirate-turn-01" asset catalog image resource.
    static let pirateTurn01 = ImageResource(name: "pirate-turn-01", bundle: resourceBundle)

    /// The "pirate-turn-02" asset catalog image resource.
    static let pirateTurn02 = ImageResource(name: "pirate-turn-02", bundle: resourceBundle)

    /// The "pirate-turn-03" asset catalog image resource.
    static let pirateTurn03 = ImageResource(name: "pirate-turn-03", bundle: resourceBundle)

    /// The "pirate-turn-04" asset catalog image resource.
    static let pirateTurn04 = ImageResource(name: "pirate-turn-04", bundle: resourceBundle)

    /// The "pirate-turn-05" asset catalog image resource.
    static let pirateTurn05 = ImageResource(name: "pirate-turn-05", bundle: resourceBundle)

    /// The "pirate-turn-06" asset catalog image resource.
    static let pirateTurn06 = ImageResource(name: "pirate-turn-06", bundle: resourceBundle)

    /// The "pirate-wrong" asset catalog image resource.
    static let pirateWrong = ImageResource(name: "pirate-wrong", bundle: resourceBundle)

    /// The "reward-star" asset catalog image resource.
    static let rewardStar = ImageResource(name: "reward-star", bundle: resourceBundle)

    /// The "valley-airborne" asset catalog image resource.
    static let valleyAirborne = ImageResource(name: "valley-airborne", bundle: resourceBundle)

    /// The "valley-clap-contact" asset catalog image resource.
    static let valleyClapContact = ImageResource(name: "valley-clap-contact", bundle: resourceBundle)

    /// The "valley-clap-open" asset catalog image resource.
    static let valleyClapOpen = ImageResource(name: "valley-clap-open", bundle: resourceBundle)

    /// The "valley-crouch" asset catalog image resource.
    static let valleyCrouch = ImageResource(name: "valley-crouch", bundle: resourceBundle)

    /// The "valley-idle" asset catalog image resource.
    static let valleyIdle = ImageResource(name: "valley-idle", bundle: resourceBundle)

    /// The "valley-opening-idle" asset catalog image resource.
    static let valleyOpeningIdle = ImageResource(name: "valley-opening-idle", bundle: resourceBundle)

    /// The "valley-push-up" asset catalog image resource.
    static let valleyPushUp = ImageResource(name: "valley-push-up", bundle: resourceBundle)

    /// The "valley-stumble" asset catalog image resource.
    static let valleyStumble = ImageResource(name: "valley-stumble", bundle: resourceBundle)

    /// The "valley-turn-01" asset catalog image resource.
    static let valleyTurn01 = ImageResource(name: "valley-turn-01", bundle: resourceBundle)

    /// The "valley-turn-02" asset catalog image resource.
    static let valleyTurn02 = ImageResource(name: "valley-turn-02", bundle: resourceBundle)

    /// The "valley-turn-03" asset catalog image resource.
    static let valleyTurn03 = ImageResource(name: "valley-turn-03", bundle: resourceBundle)

    /// The "valley-turn-04" asset catalog image resource.
    static let valleyTurn04 = ImageResource(name: "valley-turn-04", bundle: resourceBundle)

    /// The "valley-turn-05" asset catalog image resource.
    static let valleyTurn05 = ImageResource(name: "valley-turn-05", bundle: resourceBundle)

    /// The "valley-turn-06" asset catalog image resource.
    static let valleyTurn06 = ImageResource(name: "valley-turn-06", bundle: resourceBundle)

    /// The "valley-turn-07" asset catalog image resource.
    static let valleyTurn07 = ImageResource(name: "valley-turn-07", bundle: resourceBundle)

    /// The "valley-wrong" asset catalog image resource.
    static let valleyWrong = ImageResource(name: "valley-wrong", bundle: resourceBundle)

    /// The "village-airborne" asset catalog image resource.
    static let villageAirborne = ImageResource(name: "village-airborne", bundle: resourceBundle)

    /// The "village-clap-contact" asset catalog image resource.
    static let villageClapContact = ImageResource(name: "village-clap-contact", bundle: resourceBundle)

    /// The "village-clap-open" asset catalog image resource.
    static let villageClapOpen = ImageResource(name: "village-clap-open", bundle: resourceBundle)

    /// The "village-clap-release" asset catalog image resource.
    static let villageClapRelease = ImageResource(name: "village-clap-release", bundle: resourceBundle)

    /// The "village-crouch" asset catalog image resource.
    static let villageCrouch = ImageResource(name: "village-crouch", bundle: resourceBundle)

    /// The "village-fallen" asset catalog image resource.
    static let villageFallen = ImageResource(name: "village-fallen", bundle: resourceBundle)

    /// The "village-idle" asset catalog image resource.
    static let villageIdle = ImageResource(name: "village-idle", bundle: resourceBundle)

    /// The "village-opening-idle" asset catalog image resource.
    static let villageOpeningIdle = ImageResource(name: "village-opening-idle", bundle: resourceBundle)

    /// The "village-push-up" asset catalog image resource.
    static let villagePushUp = ImageResource(name: "village-push-up", bundle: resourceBundle)

    /// The "village-rise-high" asset catalog image resource.
    static let villageRiseHigh = ImageResource(name: "village-rise-high", bundle: resourceBundle)

    /// The "village-rise-low" asset catalog image resource.
    static let villageRiseLow = ImageResource(name: "village-rise-low", bundle: resourceBundle)

    /// The "village-stumble" asset catalog image resource.
    static let villageStumble = ImageResource(name: "village-stumble", bundle: resourceBundle)

    /// The "village-turn-01" asset catalog image resource.
    static let villageTurn01 = ImageResource(name: "village-turn-01", bundle: resourceBundle)

    /// The "village-turn-02" asset catalog image resource.
    static let villageTurn02 = ImageResource(name: "village-turn-02", bundle: resourceBundle)

    /// The "village-turn-03" asset catalog image resource.
    static let villageTurn03 = ImageResource(name: "village-turn-03", bundle: resourceBundle)

    /// The "village-turn-04" asset catalog image resource.
    static let villageTurn04 = ImageResource(name: "village-turn-04", bundle: resourceBundle)

    /// The "village-turn-05" asset catalog image resource.
    static let villageTurn05 = ImageResource(name: "village-turn-05", bundle: resourceBundle)

    /// The "village-turn-06" asset catalog image resource.
    static let villageTurn06 = ImageResource(name: "village-turn-06", bundle: resourceBundle)

    /// The "village-turn-07" asset catalog image resource.
    static let villageTurn07 = ImageResource(name: "village-turn-07", bundle: resourceBundle)

    /// The "village-wrong" asset catalog image resource.
    static let villageWrong = ImageResource(name: "village-wrong", bundle: resourceBundle)

    /// The "volcano-airborne" asset catalog image resource.
    static let volcanoAirborne = ImageResource(name: "volcano-airborne", bundle: resourceBundle)

    /// The "volcano-clap-contact" asset catalog image resource.
    static let volcanoClapContact = ImageResource(name: "volcano-clap-contact", bundle: resourceBundle)

    /// The "volcano-clap-contact-2" asset catalog image resource.
    static let volcanoClapContact2 = ImageResource(name: "volcano-clap-contact-2", bundle: resourceBundle)

    /// The "volcano-clap-open" asset catalog image resource.
    static let volcanoClapOpen = ImageResource(name: "volcano-clap-open", bundle: resourceBundle)

    /// The "volcano-clap-open-2" asset catalog image resource.
    static let volcanoClapOpen2 = ImageResource(name: "volcano-clap-open-2", bundle: resourceBundle)

    /// The "volcano-crouch" asset catalog image resource.
    static let volcanoCrouch = ImageResource(name: "volcano-crouch", bundle: resourceBundle)

    /// The "volcano-fallen" asset catalog image resource.
    static let volcanoFallen = ImageResource(name: "volcano-fallen", bundle: resourceBundle)

    /// The "volcano-idle" asset catalog image resource.
    static let volcanoIdle = ImageResource(name: "volcano-idle", bundle: resourceBundle)

    /// The "volcano-landing" asset catalog image resource.
    static let volcanoLanding = ImageResource(name: "volcano-landing", bundle: resourceBundle)

    /// The "volcano-opening-idle" asset catalog image resource.
    static let volcanoOpeningIdle = ImageResource(name: "volcano-opening-idle", bundle: resourceBundle)

    /// The "volcano-push-up" asset catalog image resource.
    static let volcanoPushUp = ImageResource(name: "volcano-push-up", bundle: resourceBundle)

    /// The "volcano-rise-high" asset catalog image resource.
    static let volcanoRiseHigh = ImageResource(name: "volcano-rise-high", bundle: resourceBundle)

    /// The "volcano-rise-low" asset catalog image resource.
    static let volcanoRiseLow = ImageResource(name: "volcano-rise-low", bundle: resourceBundle)

    /// The "volcano-stumble" asset catalog image resource.
    static let volcanoStumble = ImageResource(name: "volcano-stumble", bundle: resourceBundle)

    /// The "volcano-takeoff" asset catalog image resource.
    static let volcanoTakeoff = ImageResource(name: "volcano-takeoff", bundle: resourceBundle)

    /// The "volcano-turn-01" asset catalog image resource.
    static let volcanoTurn01 = ImageResource(name: "volcano-turn-01", bundle: resourceBundle)

    /// The "volcano-turn-02" asset catalog image resource.
    static let volcanoTurn02 = ImageResource(name: "volcano-turn-02", bundle: resourceBundle)

    /// The "volcano-turn-03" asset catalog image resource.
    static let volcanoTurn03 = ImageResource(name: "volcano-turn-03", bundle: resourceBundle)

    /// The "volcano-turn-04" asset catalog image resource.
    static let volcanoTurn04 = ImageResource(name: "volcano-turn-04", bundle: resourceBundle)

    /// The "volcano-turn-05" asset catalog image resource.
    static let volcanoTurn05 = ImageResource(name: "volcano-turn-05", bundle: resourceBundle)

    /// The "volcano-turn-06" asset catalog image resource.
    static let volcanoTurn06 = ImageResource(name: "volcano-turn-06", bundle: resourceBundle)

    /// The "volcano-turn-07" asset catalog image resource.
    static let volcanoTurn07 = ImageResource(name: "volcano-turn-07", bundle: resourceBundle)

    /// The "volcano-turn-08" asset catalog image resource.
    static let volcanoTurn08 = ImageResource(name: "volcano-turn-08", bundle: resourceBundle)

    /// The "volcano-wrong" asset catalog image resource.
    static let volcanoWrong = ImageResource(name: "volcano-wrong", bundle: resourceBundle)

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

    /// The "castle-back" asset catalog image.
    static var castleBack: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .castleBack)
#else
        .init()
#endif
    }

    /// The "castle-brace" asset catalog image.
    static var castleBrace: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .castleBrace)
#else
        .init()
#endif
    }

    /// The "castle-clap-contact" asset catalog image.
    static var castleClapContact: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .castleClapContact)
#else
        .init()
#endif
    }

    /// The "castle-clap-open" asset catalog image.
    static var castleClapOpen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .castleClapOpen)
#else
        .init()
#endif
    }

    /// The "castle-fallen" asset catalog image.
    static var castleFallen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .castleFallen)
#else
        .init()
#endif
    }

    /// The "castle-front" asset catalog image.
    static var castleFront: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .castleFront)
#else
        .init()
#endif
    }

    /// The "castle-idle" asset catalog image.
    static var castleIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .castleIdle)
#else
        .init()
#endif
    }

    /// The "castle-lift" asset catalog image.
    static var castleLift: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .castleLift)
#else
        .init()
#endif
    }

    /// The "castle-opening-idle" asset catalog image.
    static var castleOpeningIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .castleOpeningIdle)
#else
        .init()
#endif
    }

    /// The "castle-rear-left" asset catalog image.
    static var castleRearLeft: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .castleRearLeft)
#else
        .init()
#endif
    }

    /// The "castle-rear-right" asset catalog image.
    static var castleRearRight: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .castleRearRight)
#else
        .init()
#endif
    }

    /// The "castle-recover" asset catalog image.
    static var castleRecover: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .castleRecover)
#else
        .init()
#endif
    }

    /// The "castle-side-left" asset catalog image.
    static var castleSideLeft: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .castleSideLeft)
#else
        .init()
#endif
    }

    /// The "castle-side-right" asset catalog image.
    static var castleSideRight: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .castleSideRight)
#else
        .init()
#endif
    }

    /// The "castle-stumble" asset catalog image.
    static var castleStumble: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .castleStumble)
#else
        .init()
#endif
    }

    /// The "castle-wrong" asset catalog image.
    static var castleWrong: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .castleWrong)
#else
        .init()
#endif
    }

    /// The "cave-airborne" asset catalog image.
    static var caveAirborne: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .caveAirborne)
#else
        .init()
#endif
    }

    /// The "cave-clap-contact" asset catalog image.
    static var caveClapContact: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .caveClapContact)
#else
        .init()
#endif
    }

    /// The "cave-clap-open" asset catalog image.
    static var caveClapOpen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .caveClapOpen)
#else
        .init()
#endif
    }

    /// The "cave-clap-release" asset catalog image.
    static var caveClapRelease: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .caveClapRelease)
#else
        .init()
#endif
    }

    /// The "cave-crouch" asset catalog image.
    static var caveCrouch: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .caveCrouch)
#else
        .init()
#endif
    }

    /// The "cave-fallen" asset catalog image.
    static var caveFallen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .caveFallen)
#else
        .init()
#endif
    }

    /// The "cave-idle" asset catalog image.
    static var caveIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .caveIdle)
#else
        .init()
#endif
    }

    /// The "cave-opening-idle" asset catalog image.
    static var caveOpeningIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .caveOpeningIdle)
#else
        .init()
#endif
    }

    /// The "cave-push-up" asset catalog image.
    static var cavePushUp: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cavePushUp)
#else
        .init()
#endif
    }

    /// The "cave-recover" asset catalog image.
    static var caveRecover: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .caveRecover)
#else
        .init()
#endif
    }

    /// The "cave-stumble" asset catalog image.
    static var caveStumble: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .caveStumble)
#else
        .init()
#endif
    }

    /// The "cave-turn-02" asset catalog image.
    static var caveTurn02: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .caveTurn02)
#else
        .init()
#endif
    }

    /// The "cave-turn-03" asset catalog image.
    static var caveTurn03: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .caveTurn03)
#else
        .init()
#endif
    }

    /// The "cave-turn-04" asset catalog image.
    static var caveTurn04: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .caveTurn04)
#else
        .init()
#endif
    }

    /// The "cave-turn-05" asset catalog image.
    static var caveTurn05: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .caveTurn05)
#else
        .init()
#endif
    }

    /// The "cave-turn-06" asset catalog image.
    static var caveTurn06: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .caveTurn06)
#else
        .init()
#endif
    }

    /// The "cave-turn-07" asset catalog image.
    static var caveTurn07: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .caveTurn07)
#else
        .init()
#endif
    }

    /// The "cave-turn-08" asset catalog image.
    static var caveTurn08: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .caveTurn08)
#else
        .init()
#endif
    }

    /// The "cave-wrong" asset catalog image.
    static var caveWrong: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .caveWrong)
#else
        .init()
#endif
    }

    /// The "city-airborne" asset catalog image.
    static var cityAirborne: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cityAirborne)
#else
        .init()
#endif
    }

    /// The "city-clap-contact" asset catalog image.
    static var cityClapContact: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cityClapContact)
#else
        .init()
#endif
    }

    /// The "city-clap-open" asset catalog image.
    static var cityClapOpen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cityClapOpen)
#else
        .init()
#endif
    }

    /// The "city-crouch" asset catalog image.
    static var cityCrouch: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cityCrouch)
#else
        .init()
#endif
    }

    /// The "city-fallen" asset catalog image.
    static var cityFallen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cityFallen)
#else
        .init()
#endif
    }

    /// The "city-idle" asset catalog image.
    static var cityIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cityIdle)
#else
        .init()
#endif
    }

    /// The "city-opening-idle" asset catalog image.
    static var cityOpeningIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cityOpeningIdle)
#else
        .init()
#endif
    }

    /// The "city-push-up" asset catalog image.
    static var cityPushUp: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cityPushUp)
#else
        .init()
#endif
    }

    /// The "city-stumble" asset catalog image.
    static var cityStumble: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cityStumble)
#else
        .init()
#endif
    }

    /// The "city-turn-02" asset catalog image.
    static var cityTurn02: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cityTurn02)
#else
        .init()
#endif
    }

    /// The "city-turn-03" asset catalog image.
    static var cityTurn03: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cityTurn03)
#else
        .init()
#endif
    }

    /// The "city-turn-04" asset catalog image.
    static var cityTurn04: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cityTurn04)
#else
        .init()
#endif
    }

    /// The "city-turn-05" asset catalog image.
    static var cityTurn05: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cityTurn05)
#else
        .init()
#endif
    }

    /// The "city-turn-06" asset catalog image.
    static var cityTurn06: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cityTurn06)
#else
        .init()
#endif
    }

    /// The "city-turn-07" asset catalog image.
    static var cityTurn07: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cityTurn07)
#else
        .init()
#endif
    }

    /// The "city-turn-08" asset catalog image.
    static var cityTurn08: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cityTurn08)
#else
        .init()
#endif
    }

    /// The "city-wrong" asset catalog image.
    static var cityWrong: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cityWrong)
#else
        .init()
#endif
    }

    /// The "desert-airborne" asset catalog image.
    static var desertAirborne: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertAirborne)
#else
        .init()
#endif
    }

    /// The "desert-clap-contact" asset catalog image.
    static var desertClapContact: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertClapContact)
#else
        .init()
#endif
    }

    /// The "desert-clap-contact-2" asset catalog image.
    static var desertClapContact2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertClapContact2)
#else
        .init()
#endif
    }

    /// The "desert-clap-open" asset catalog image.
    static var desertClapOpen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertClapOpen)
#else
        .init()
#endif
    }

    /// The "desert-clap-open-2" asset catalog image.
    static var desertClapOpen2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertClapOpen2)
#else
        .init()
#endif
    }

    /// The "desert-crouch" asset catalog image.
    static var desertCrouch: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertCrouch)
#else
        .init()
#endif
    }

    /// The "desert-fallen" asset catalog image.
    static var desertFallen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertFallen)
#else
        .init()
#endif
    }

    /// The "desert-idle" asset catalog image.
    static var desertIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertIdle)
#else
        .init()
#endif
    }

    /// The "desert-landing" asset catalog image.
    static var desertLanding: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertLanding)
#else
        .init()
#endif
    }

    /// The "desert-opening-idle" asset catalog image.
    static var desertOpeningIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertOpeningIdle)
#else
        .init()
#endif
    }

    /// The "desert-push-up" asset catalog image.
    static var desertPushUp: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertPushUp)
#else
        .init()
#endif
    }

    /// The "desert-stumble" asset catalog image.
    static var desertStumble: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertStumble)
#else
        .init()
#endif
    }

    /// The "desert-takeoff" asset catalog image.
    static var desertTakeoff: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertTakeoff)
#else
        .init()
#endif
    }

    /// The "desert-turn-01" asset catalog image.
    static var desertTurn01: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertTurn01)
#else
        .init()
#endif
    }

    /// The "desert-turn-02" asset catalog image.
    static var desertTurn02: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertTurn02)
#else
        .init()
#endif
    }

    /// The "desert-turn-03" asset catalog image.
    static var desertTurn03: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertTurn03)
#else
        .init()
#endif
    }

    /// The "desert-turn-04" asset catalog image.
    static var desertTurn04: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertTurn04)
#else
        .init()
#endif
    }

    /// The "desert-turn-05" asset catalog image.
    static var desertTurn05: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertTurn05)
#else
        .init()
#endif
    }

    /// The "desert-turn-06" asset catalog image.
    static var desertTurn06: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertTurn06)
#else
        .init()
#endif
    }

    /// The "desert-turn-07" asset catalog image.
    static var desertTurn07: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertTurn07)
#else
        .init()
#endif
    }

    /// The "desert-turn-08" asset catalog image.
    static var desertTurn08: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertTurn08)
#else
        .init()
#endif
    }

    /// The "desert-wrong" asset catalog image.
    static var desertWrong: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .desertWrong)
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

    /// The "jungle-airborne" asset catalog image.
    static var jungleAirborne: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleAirborne)
#else
        .init()
#endif
    }

    /// The "jungle-clap-contact" asset catalog image.
    static var jungleClapContact: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleClapContact)
#else
        .init()
#endif
    }

    /// The "jungle-clap-contact-2" asset catalog image.
    static var jungleClapContact2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleClapContact2)
#else
        .init()
#endif
    }

    /// The "jungle-clap-open" asset catalog image.
    static var jungleClapOpen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleClapOpen)
#else
        .init()
#endif
    }

    /// The "jungle-clap-open-2" asset catalog image.
    static var jungleClapOpen2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleClapOpen2)
#else
        .init()
#endif
    }

    /// The "jungle-crouch" asset catalog image.
    static var jungleCrouch: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleCrouch)
#else
        .init()
#endif
    }

    /// The "jungle-fallen" asset catalog image.
    static var jungleFallen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleFallen)
#else
        .init()
#endif
    }

    /// The "jungle-idle" asset catalog image.
    static var jungleIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleIdle)
#else
        .init()
#endif
    }

    /// The "jungle-landing" asset catalog image.
    static var jungleLanding: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleLanding)
#else
        .init()
#endif
    }

    /// The "jungle-opening-idle" asset catalog image.
    static var jungleOpeningIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleOpeningIdle)
#else
        .init()
#endif
    }

    /// The "jungle-push-up" asset catalog image.
    static var junglePushUp: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .junglePushUp)
#else
        .init()
#endif
    }

    /// The "jungle-recover" asset catalog image.
    static var jungleRecover: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleRecover)
#else
        .init()
#endif
    }

    /// The "jungle-stumble" asset catalog image.
    static var jungleStumble: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleStumble)
#else
        .init()
#endif
    }

    /// The "jungle-takeoff" asset catalog image.
    static var jungleTakeoff: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleTakeoff)
#else
        .init()
#endif
    }

    /// The "jungle-turn-01" asset catalog image.
    static var jungleTurn01: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleTurn01)
#else
        .init()
#endif
    }

    /// The "jungle-turn-02" asset catalog image.
    static var jungleTurn02: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleTurn02)
#else
        .init()
#endif
    }

    /// The "jungle-turn-03" asset catalog image.
    static var jungleTurn03: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleTurn03)
#else
        .init()
#endif
    }

    /// The "jungle-turn-04" asset catalog image.
    static var jungleTurn04: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleTurn04)
#else
        .init()
#endif
    }

    /// The "jungle-turn-05" asset catalog image.
    static var jungleTurn05: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleTurn05)
#else
        .init()
#endif
    }

    /// The "jungle-turn-06" asset catalog image.
    static var jungleTurn06: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleTurn06)
#else
        .init()
#endif
    }

    /// The "jungle-turn-07" asset catalog image.
    static var jungleTurn07: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleTurn07)
#else
        .init()
#endif
    }

    /// The "jungle-turn-08" asset catalog image.
    static var jungleTurn08: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleTurn08)
#else
        .init()
#endif
    }

    /// The "jungle-wrong" asset catalog image.
    static var jungleWrong: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jungleWrong)
#else
        .init()
#endif
    }

    /// The "machine-airborne" asset catalog image.
    static var machineAirborne: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .machineAirborne)
#else
        .init()
#endif
    }

    /// The "machine-brace" asset catalog image.
    static var machineBrace: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .machineBrace)
#else
        .init()
#endif
    }

    /// The "machine-clap-contact" asset catalog image.
    static var machineClapContact: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .machineClapContact)
#else
        .init()
#endif
    }

    /// The "machine-clap-open" asset catalog image.
    static var machineClapOpen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .machineClapOpen)
#else
        .init()
#endif
    }

    /// The "machine-crouch" asset catalog image.
    static var machineCrouch: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .machineCrouch)
#else
        .init()
#endif
    }

    /// The "machine-idle" asset catalog image.
    static var machineIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .machineIdle)
#else
        .init()
#endif
    }

    /// The "machine-opening-idle" asset catalog image.
    static var machineOpeningIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .machineOpeningIdle)
#else
        .init()
#endif
    }

    /// The "machine-turn-back" asset catalog image.
    static var machineTurnBack: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .machineTurnBack)
#else
        .init()
#endif
    }

    /// The "machine-turn-back-left" asset catalog image.
    static var machineTurnBackLeft: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .machineTurnBackLeft)
#else
        .init()
#endif
    }

    /// The "machine-turn-back-right" asset catalog image.
    static var machineTurnBackRight: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .machineTurnBackRight)
#else
        .init()
#endif
    }

    /// The "machine-turn-front" asset catalog image.
    static var machineTurnFront: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .machineTurnFront)
#else
        .init()
#endif
    }

    /// The "machine-turn-front-right" asset catalog image.
    static var machineTurnFrontRight: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .machineTurnFrontRight)
#else
        .init()
#endif
    }

    /// The "machine-turn-side-left" asset catalog image.
    static var machineTurnSideLeft: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .machineTurnSideLeft)
#else
        .init()
#endif
    }

    /// The "machine-turn-side-right" asset catalog image.
    static var machineTurnSideRight: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .machineTurnSideRight)
#else
        .init()
#endif
    }

    /// The "machine-wrong" asset catalog image.
    static var machineWrong: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .machineWrong)
#else
        .init()
#endif
    }

    /// The "pirate-airborne" asset catalog image.
    static var pirateAirborne: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pirateAirborne)
#else
        .init()
#endif
    }

    /// The "pirate-clap-contact" asset catalog image.
    static var pirateClapContact: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pirateClapContact)
#else
        .init()
#endif
    }

    /// The "pirate-clap-open" asset catalog image.
    static var pirateClapOpen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pirateClapOpen)
#else
        .init()
#endif
    }

    /// The "pirate-crouch" asset catalog image.
    static var pirateCrouch: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pirateCrouch)
#else
        .init()
#endif
    }

    /// The "pirate-fallen" asset catalog image.
    static var pirateFallen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pirateFallen)
#else
        .init()
#endif
    }

    /// The "pirate-idle" asset catalog image.
    static var pirateIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pirateIdle)
#else
        .init()
#endif
    }

    /// The "pirate-opening-idle" asset catalog image.
    static var pirateOpeningIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pirateOpeningIdle)
#else
        .init()
#endif
    }

    /// The "pirate-push-up" asset catalog image.
    static var piratePushUp: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .piratePushUp)
#else
        .init()
#endif
    }

    /// The "pirate-stumble" asset catalog image.
    static var pirateStumble: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pirateStumble)
#else
        .init()
#endif
    }

    /// The "pirate-turn-01" asset catalog image.
    static var pirateTurn01: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pirateTurn01)
#else
        .init()
#endif
    }

    /// The "pirate-turn-02" asset catalog image.
    static var pirateTurn02: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pirateTurn02)
#else
        .init()
#endif
    }

    /// The "pirate-turn-03" asset catalog image.
    static var pirateTurn03: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pirateTurn03)
#else
        .init()
#endif
    }

    /// The "pirate-turn-04" asset catalog image.
    static var pirateTurn04: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pirateTurn04)
#else
        .init()
#endif
    }

    /// The "pirate-turn-05" asset catalog image.
    static var pirateTurn05: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pirateTurn05)
#else
        .init()
#endif
    }

    /// The "pirate-turn-06" asset catalog image.
    static var pirateTurn06: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pirateTurn06)
#else
        .init()
#endif
    }

    /// The "pirate-wrong" asset catalog image.
    static var pirateWrong: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pirateWrong)
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

    /// The "valley-airborne" asset catalog image.
    static var valleyAirborne: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .valleyAirborne)
#else
        .init()
#endif
    }

    /// The "valley-clap-contact" asset catalog image.
    static var valleyClapContact: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .valleyClapContact)
#else
        .init()
#endif
    }

    /// The "valley-clap-open" asset catalog image.
    static var valleyClapOpen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .valleyClapOpen)
#else
        .init()
#endif
    }

    /// The "valley-crouch" asset catalog image.
    static var valleyCrouch: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .valleyCrouch)
#else
        .init()
#endif
    }

    /// The "valley-idle" asset catalog image.
    static var valleyIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .valleyIdle)
#else
        .init()
#endif
    }

    /// The "valley-opening-idle" asset catalog image.
    static var valleyOpeningIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .valleyOpeningIdle)
#else
        .init()
#endif
    }

    /// The "valley-push-up" asset catalog image.
    static var valleyPushUp: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .valleyPushUp)
#else
        .init()
#endif
    }

    /// The "valley-stumble" asset catalog image.
    static var valleyStumble: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .valleyStumble)
#else
        .init()
#endif
    }

    /// The "valley-turn-01" asset catalog image.
    static var valleyTurn01: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .valleyTurn01)
#else
        .init()
#endif
    }

    /// The "valley-turn-02" asset catalog image.
    static var valleyTurn02: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .valleyTurn02)
#else
        .init()
#endif
    }

    /// The "valley-turn-03" asset catalog image.
    static var valleyTurn03: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .valleyTurn03)
#else
        .init()
#endif
    }

    /// The "valley-turn-04" asset catalog image.
    static var valleyTurn04: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .valleyTurn04)
#else
        .init()
#endif
    }

    /// The "valley-turn-05" asset catalog image.
    static var valleyTurn05: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .valleyTurn05)
#else
        .init()
#endif
    }

    /// The "valley-turn-06" asset catalog image.
    static var valleyTurn06: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .valleyTurn06)
#else
        .init()
#endif
    }

    /// The "valley-turn-07" asset catalog image.
    static var valleyTurn07: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .valleyTurn07)
#else
        .init()
#endif
    }

    /// The "valley-wrong" asset catalog image.
    static var valleyWrong: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .valleyWrong)
#else
        .init()
#endif
    }

    /// The "village-airborne" asset catalog image.
    static var villageAirborne: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageAirborne)
#else
        .init()
#endif
    }

    /// The "village-clap-contact" asset catalog image.
    static var villageClapContact: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageClapContact)
#else
        .init()
#endif
    }

    /// The "village-clap-open" asset catalog image.
    static var villageClapOpen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageClapOpen)
#else
        .init()
#endif
    }

    /// The "village-clap-release" asset catalog image.
    static var villageClapRelease: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageClapRelease)
#else
        .init()
#endif
    }

    /// The "village-crouch" asset catalog image.
    static var villageCrouch: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageCrouch)
#else
        .init()
#endif
    }

    /// The "village-fallen" asset catalog image.
    static var villageFallen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageFallen)
#else
        .init()
#endif
    }

    /// The "village-idle" asset catalog image.
    static var villageIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageIdle)
#else
        .init()
#endif
    }

    /// The "village-opening-idle" asset catalog image.
    static var villageOpeningIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageOpeningIdle)
#else
        .init()
#endif
    }

    /// The "village-push-up" asset catalog image.
    static var villagePushUp: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villagePushUp)
#else
        .init()
#endif
    }

    /// The "village-rise-high" asset catalog image.
    static var villageRiseHigh: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageRiseHigh)
#else
        .init()
#endif
    }

    /// The "village-rise-low" asset catalog image.
    static var villageRiseLow: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageRiseLow)
#else
        .init()
#endif
    }

    /// The "village-stumble" asset catalog image.
    static var villageStumble: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageStumble)
#else
        .init()
#endif
    }

    /// The "village-turn-01" asset catalog image.
    static var villageTurn01: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageTurn01)
#else
        .init()
#endif
    }

    /// The "village-turn-02" asset catalog image.
    static var villageTurn02: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageTurn02)
#else
        .init()
#endif
    }

    /// The "village-turn-03" asset catalog image.
    static var villageTurn03: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageTurn03)
#else
        .init()
#endif
    }

    /// The "village-turn-04" asset catalog image.
    static var villageTurn04: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageTurn04)
#else
        .init()
#endif
    }

    /// The "village-turn-05" asset catalog image.
    static var villageTurn05: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageTurn05)
#else
        .init()
#endif
    }

    /// The "village-turn-06" asset catalog image.
    static var villageTurn06: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageTurn06)
#else
        .init()
#endif
    }

    /// The "village-turn-07" asset catalog image.
    static var villageTurn07: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageTurn07)
#else
        .init()
#endif
    }

    /// The "village-wrong" asset catalog image.
    static var villageWrong: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .villageWrong)
#else
        .init()
#endif
    }

    /// The "volcano-airborne" asset catalog image.
    static var volcanoAirborne: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoAirborne)
#else
        .init()
#endif
    }

    /// The "volcano-clap-contact" asset catalog image.
    static var volcanoClapContact: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoClapContact)
#else
        .init()
#endif
    }

    /// The "volcano-clap-contact-2" asset catalog image.
    static var volcanoClapContact2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoClapContact2)
#else
        .init()
#endif
    }

    /// The "volcano-clap-open" asset catalog image.
    static var volcanoClapOpen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoClapOpen)
#else
        .init()
#endif
    }

    /// The "volcano-clap-open-2" asset catalog image.
    static var volcanoClapOpen2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoClapOpen2)
#else
        .init()
#endif
    }

    /// The "volcano-crouch" asset catalog image.
    static var volcanoCrouch: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoCrouch)
#else
        .init()
#endif
    }

    /// The "volcano-fallen" asset catalog image.
    static var volcanoFallen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoFallen)
#else
        .init()
#endif
    }

    /// The "volcano-idle" asset catalog image.
    static var volcanoIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoIdle)
#else
        .init()
#endif
    }

    /// The "volcano-landing" asset catalog image.
    static var volcanoLanding: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoLanding)
#else
        .init()
#endif
    }

    /// The "volcano-opening-idle" asset catalog image.
    static var volcanoOpeningIdle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoOpeningIdle)
#else
        .init()
#endif
    }

    /// The "volcano-push-up" asset catalog image.
    static var volcanoPushUp: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoPushUp)
#else
        .init()
#endif
    }

    /// The "volcano-rise-high" asset catalog image.
    static var volcanoRiseHigh: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoRiseHigh)
#else
        .init()
#endif
    }

    /// The "volcano-rise-low" asset catalog image.
    static var volcanoRiseLow: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoRiseLow)
#else
        .init()
#endif
    }

    /// The "volcano-stumble" asset catalog image.
    static var volcanoStumble: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoStumble)
#else
        .init()
#endif
    }

    /// The "volcano-takeoff" asset catalog image.
    static var volcanoTakeoff: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoTakeoff)
#else
        .init()
#endif
    }

    /// The "volcano-turn-01" asset catalog image.
    static var volcanoTurn01: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoTurn01)
#else
        .init()
#endif
    }

    /// The "volcano-turn-02" asset catalog image.
    static var volcanoTurn02: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoTurn02)
#else
        .init()
#endif
    }

    /// The "volcano-turn-03" asset catalog image.
    static var volcanoTurn03: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoTurn03)
#else
        .init()
#endif
    }

    /// The "volcano-turn-04" asset catalog image.
    static var volcanoTurn04: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoTurn04)
#else
        .init()
#endif
    }

    /// The "volcano-turn-05" asset catalog image.
    static var volcanoTurn05: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoTurn05)
#else
        .init()
#endif
    }

    /// The "volcano-turn-06" asset catalog image.
    static var volcanoTurn06: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoTurn06)
#else
        .init()
#endif
    }

    /// The "volcano-turn-07" asset catalog image.
    static var volcanoTurn07: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoTurn07)
#else
        .init()
#endif
    }

    /// The "volcano-turn-08" asset catalog image.
    static var volcanoTurn08: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoTurn08)
#else
        .init()
#endif
    }

    /// The "volcano-wrong" asset catalog image.
    static var volcanoWrong: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volcanoWrong)
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

    /// The "castle-back" asset catalog image.
    static var castleBack: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .castleBack)
#else
        .init()
#endif
    }

    /// The "castle-brace" asset catalog image.
    static var castleBrace: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .castleBrace)
#else
        .init()
#endif
    }

    /// The "castle-clap-contact" asset catalog image.
    static var castleClapContact: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .castleClapContact)
#else
        .init()
#endif
    }

    /// The "castle-clap-open" asset catalog image.
    static var castleClapOpen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .castleClapOpen)
#else
        .init()
#endif
    }

    /// The "castle-fallen" asset catalog image.
    static var castleFallen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .castleFallen)
#else
        .init()
#endif
    }

    /// The "castle-front" asset catalog image.
    static var castleFront: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .castleFront)
#else
        .init()
#endif
    }

    /// The "castle-idle" asset catalog image.
    static var castleIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .castleIdle)
#else
        .init()
#endif
    }

    /// The "castle-lift" asset catalog image.
    static var castleLift: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .castleLift)
#else
        .init()
#endif
    }

    /// The "castle-opening-idle" asset catalog image.
    static var castleOpeningIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .castleOpeningIdle)
#else
        .init()
#endif
    }

    /// The "castle-rear-left" asset catalog image.
    static var castleRearLeft: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .castleRearLeft)
#else
        .init()
#endif
    }

    /// The "castle-rear-right" asset catalog image.
    static var castleRearRight: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .castleRearRight)
#else
        .init()
#endif
    }

    /// The "castle-recover" asset catalog image.
    static var castleRecover: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .castleRecover)
#else
        .init()
#endif
    }

    /// The "castle-side-left" asset catalog image.
    static var castleSideLeft: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .castleSideLeft)
#else
        .init()
#endif
    }

    /// The "castle-side-right" asset catalog image.
    static var castleSideRight: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .castleSideRight)
#else
        .init()
#endif
    }

    /// The "castle-stumble" asset catalog image.
    static var castleStumble: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .castleStumble)
#else
        .init()
#endif
    }

    /// The "castle-wrong" asset catalog image.
    static var castleWrong: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .castleWrong)
#else
        .init()
#endif
    }

    /// The "cave-airborne" asset catalog image.
    static var caveAirborne: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .caveAirborne)
#else
        .init()
#endif
    }

    /// The "cave-clap-contact" asset catalog image.
    static var caveClapContact: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .caveClapContact)
#else
        .init()
#endif
    }

    /// The "cave-clap-open" asset catalog image.
    static var caveClapOpen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .caveClapOpen)
#else
        .init()
#endif
    }

    /// The "cave-clap-release" asset catalog image.
    static var caveClapRelease: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .caveClapRelease)
#else
        .init()
#endif
    }

    /// The "cave-crouch" asset catalog image.
    static var caveCrouch: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .caveCrouch)
#else
        .init()
#endif
    }

    /// The "cave-fallen" asset catalog image.
    static var caveFallen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .caveFallen)
#else
        .init()
#endif
    }

    /// The "cave-idle" asset catalog image.
    static var caveIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .caveIdle)
#else
        .init()
#endif
    }

    /// The "cave-opening-idle" asset catalog image.
    static var caveOpeningIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .caveOpeningIdle)
#else
        .init()
#endif
    }

    /// The "cave-push-up" asset catalog image.
    static var cavePushUp: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cavePushUp)
#else
        .init()
#endif
    }

    /// The "cave-recover" asset catalog image.
    static var caveRecover: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .caveRecover)
#else
        .init()
#endif
    }

    /// The "cave-stumble" asset catalog image.
    static var caveStumble: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .caveStumble)
#else
        .init()
#endif
    }

    /// The "cave-turn-02" asset catalog image.
    static var caveTurn02: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .caveTurn02)
#else
        .init()
#endif
    }

    /// The "cave-turn-03" asset catalog image.
    static var caveTurn03: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .caveTurn03)
#else
        .init()
#endif
    }

    /// The "cave-turn-04" asset catalog image.
    static var caveTurn04: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .caveTurn04)
#else
        .init()
#endif
    }

    /// The "cave-turn-05" asset catalog image.
    static var caveTurn05: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .caveTurn05)
#else
        .init()
#endif
    }

    /// The "cave-turn-06" asset catalog image.
    static var caveTurn06: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .caveTurn06)
#else
        .init()
#endif
    }

    /// The "cave-turn-07" asset catalog image.
    static var caveTurn07: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .caveTurn07)
#else
        .init()
#endif
    }

    /// The "cave-turn-08" asset catalog image.
    static var caveTurn08: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .caveTurn08)
#else
        .init()
#endif
    }

    /// The "cave-wrong" asset catalog image.
    static var caveWrong: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .caveWrong)
#else
        .init()
#endif
    }

    /// The "city-airborne" asset catalog image.
    static var cityAirborne: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cityAirborne)
#else
        .init()
#endif
    }

    /// The "city-clap-contact" asset catalog image.
    static var cityClapContact: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cityClapContact)
#else
        .init()
#endif
    }

    /// The "city-clap-open" asset catalog image.
    static var cityClapOpen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cityClapOpen)
#else
        .init()
#endif
    }

    /// The "city-crouch" asset catalog image.
    static var cityCrouch: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cityCrouch)
#else
        .init()
#endif
    }

    /// The "city-fallen" asset catalog image.
    static var cityFallen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cityFallen)
#else
        .init()
#endif
    }

    /// The "city-idle" asset catalog image.
    static var cityIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cityIdle)
#else
        .init()
#endif
    }

    /// The "city-opening-idle" asset catalog image.
    static var cityOpeningIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cityOpeningIdle)
#else
        .init()
#endif
    }

    /// The "city-push-up" asset catalog image.
    static var cityPushUp: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cityPushUp)
#else
        .init()
#endif
    }

    /// The "city-stumble" asset catalog image.
    static var cityStumble: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cityStumble)
#else
        .init()
#endif
    }

    /// The "city-turn-02" asset catalog image.
    static var cityTurn02: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cityTurn02)
#else
        .init()
#endif
    }

    /// The "city-turn-03" asset catalog image.
    static var cityTurn03: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cityTurn03)
#else
        .init()
#endif
    }

    /// The "city-turn-04" asset catalog image.
    static var cityTurn04: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cityTurn04)
#else
        .init()
#endif
    }

    /// The "city-turn-05" asset catalog image.
    static var cityTurn05: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cityTurn05)
#else
        .init()
#endif
    }

    /// The "city-turn-06" asset catalog image.
    static var cityTurn06: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cityTurn06)
#else
        .init()
#endif
    }

    /// The "city-turn-07" asset catalog image.
    static var cityTurn07: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cityTurn07)
#else
        .init()
#endif
    }

    /// The "city-turn-08" asset catalog image.
    static var cityTurn08: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cityTurn08)
#else
        .init()
#endif
    }

    /// The "city-wrong" asset catalog image.
    static var cityWrong: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cityWrong)
#else
        .init()
#endif
    }

    /// The "desert-airborne" asset catalog image.
    static var desertAirborne: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertAirborne)
#else
        .init()
#endif
    }

    /// The "desert-clap-contact" asset catalog image.
    static var desertClapContact: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertClapContact)
#else
        .init()
#endif
    }

    /// The "desert-clap-contact-2" asset catalog image.
    static var desertClapContact2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertClapContact2)
#else
        .init()
#endif
    }

    /// The "desert-clap-open" asset catalog image.
    static var desertClapOpen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertClapOpen)
#else
        .init()
#endif
    }

    /// The "desert-clap-open-2" asset catalog image.
    static var desertClapOpen2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertClapOpen2)
#else
        .init()
#endif
    }

    /// The "desert-crouch" asset catalog image.
    static var desertCrouch: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertCrouch)
#else
        .init()
#endif
    }

    /// The "desert-fallen" asset catalog image.
    static var desertFallen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertFallen)
#else
        .init()
#endif
    }

    /// The "desert-idle" asset catalog image.
    static var desertIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertIdle)
#else
        .init()
#endif
    }

    /// The "desert-landing" asset catalog image.
    static var desertLanding: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertLanding)
#else
        .init()
#endif
    }

    /// The "desert-opening-idle" asset catalog image.
    static var desertOpeningIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertOpeningIdle)
#else
        .init()
#endif
    }

    /// The "desert-push-up" asset catalog image.
    static var desertPushUp: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertPushUp)
#else
        .init()
#endif
    }

    /// The "desert-stumble" asset catalog image.
    static var desertStumble: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertStumble)
#else
        .init()
#endif
    }

    /// The "desert-takeoff" asset catalog image.
    static var desertTakeoff: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertTakeoff)
#else
        .init()
#endif
    }

    /// The "desert-turn-01" asset catalog image.
    static var desertTurn01: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertTurn01)
#else
        .init()
#endif
    }

    /// The "desert-turn-02" asset catalog image.
    static var desertTurn02: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertTurn02)
#else
        .init()
#endif
    }

    /// The "desert-turn-03" asset catalog image.
    static var desertTurn03: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertTurn03)
#else
        .init()
#endif
    }

    /// The "desert-turn-04" asset catalog image.
    static var desertTurn04: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertTurn04)
#else
        .init()
#endif
    }

    /// The "desert-turn-05" asset catalog image.
    static var desertTurn05: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertTurn05)
#else
        .init()
#endif
    }

    /// The "desert-turn-06" asset catalog image.
    static var desertTurn06: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertTurn06)
#else
        .init()
#endif
    }

    /// The "desert-turn-07" asset catalog image.
    static var desertTurn07: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertTurn07)
#else
        .init()
#endif
    }

    /// The "desert-turn-08" asset catalog image.
    static var desertTurn08: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertTurn08)
#else
        .init()
#endif
    }

    /// The "desert-wrong" asset catalog image.
    static var desertWrong: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .desertWrong)
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

    /// The "jungle-airborne" asset catalog image.
    static var jungleAirborne: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleAirborne)
#else
        .init()
#endif
    }

    /// The "jungle-clap-contact" asset catalog image.
    static var jungleClapContact: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleClapContact)
#else
        .init()
#endif
    }

    /// The "jungle-clap-contact-2" asset catalog image.
    static var jungleClapContact2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleClapContact2)
#else
        .init()
#endif
    }

    /// The "jungle-clap-open" asset catalog image.
    static var jungleClapOpen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleClapOpen)
#else
        .init()
#endif
    }

    /// The "jungle-clap-open-2" asset catalog image.
    static var jungleClapOpen2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleClapOpen2)
#else
        .init()
#endif
    }

    /// The "jungle-crouch" asset catalog image.
    static var jungleCrouch: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleCrouch)
#else
        .init()
#endif
    }

    /// The "jungle-fallen" asset catalog image.
    static var jungleFallen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleFallen)
#else
        .init()
#endif
    }

    /// The "jungle-idle" asset catalog image.
    static var jungleIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleIdle)
#else
        .init()
#endif
    }

    /// The "jungle-landing" asset catalog image.
    static var jungleLanding: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleLanding)
#else
        .init()
#endif
    }

    /// The "jungle-opening-idle" asset catalog image.
    static var jungleOpeningIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleOpeningIdle)
#else
        .init()
#endif
    }

    /// The "jungle-push-up" asset catalog image.
    static var junglePushUp: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .junglePushUp)
#else
        .init()
#endif
    }

    /// The "jungle-recover" asset catalog image.
    static var jungleRecover: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleRecover)
#else
        .init()
#endif
    }

    /// The "jungle-stumble" asset catalog image.
    static var jungleStumble: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleStumble)
#else
        .init()
#endif
    }

    /// The "jungle-takeoff" asset catalog image.
    static var jungleTakeoff: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleTakeoff)
#else
        .init()
#endif
    }

    /// The "jungle-turn-01" asset catalog image.
    static var jungleTurn01: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleTurn01)
#else
        .init()
#endif
    }

    /// The "jungle-turn-02" asset catalog image.
    static var jungleTurn02: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleTurn02)
#else
        .init()
#endif
    }

    /// The "jungle-turn-03" asset catalog image.
    static var jungleTurn03: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleTurn03)
#else
        .init()
#endif
    }

    /// The "jungle-turn-04" asset catalog image.
    static var jungleTurn04: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleTurn04)
#else
        .init()
#endif
    }

    /// The "jungle-turn-05" asset catalog image.
    static var jungleTurn05: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleTurn05)
#else
        .init()
#endif
    }

    /// The "jungle-turn-06" asset catalog image.
    static var jungleTurn06: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleTurn06)
#else
        .init()
#endif
    }

    /// The "jungle-turn-07" asset catalog image.
    static var jungleTurn07: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleTurn07)
#else
        .init()
#endif
    }

    /// The "jungle-turn-08" asset catalog image.
    static var jungleTurn08: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleTurn08)
#else
        .init()
#endif
    }

    /// The "jungle-wrong" asset catalog image.
    static var jungleWrong: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jungleWrong)
#else
        .init()
#endif
    }

    /// The "machine-airborne" asset catalog image.
    static var machineAirborne: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .machineAirborne)
#else
        .init()
#endif
    }

    /// The "machine-brace" asset catalog image.
    static var machineBrace: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .machineBrace)
#else
        .init()
#endif
    }

    /// The "machine-clap-contact" asset catalog image.
    static var machineClapContact: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .machineClapContact)
#else
        .init()
#endif
    }

    /// The "machine-clap-open" asset catalog image.
    static var machineClapOpen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .machineClapOpen)
#else
        .init()
#endif
    }

    /// The "machine-crouch" asset catalog image.
    static var machineCrouch: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .machineCrouch)
#else
        .init()
#endif
    }

    /// The "machine-idle" asset catalog image.
    static var machineIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .machineIdle)
#else
        .init()
#endif
    }

    /// The "machine-opening-idle" asset catalog image.
    static var machineOpeningIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .machineOpeningIdle)
#else
        .init()
#endif
    }

    /// The "machine-turn-back" asset catalog image.
    static var machineTurnBack: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .machineTurnBack)
#else
        .init()
#endif
    }

    /// The "machine-turn-back-left" asset catalog image.
    static var machineTurnBackLeft: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .machineTurnBackLeft)
#else
        .init()
#endif
    }

    /// The "machine-turn-back-right" asset catalog image.
    static var machineTurnBackRight: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .machineTurnBackRight)
#else
        .init()
#endif
    }

    /// The "machine-turn-front" asset catalog image.
    static var machineTurnFront: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .machineTurnFront)
#else
        .init()
#endif
    }

    /// The "machine-turn-front-right" asset catalog image.
    static var machineTurnFrontRight: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .machineTurnFrontRight)
#else
        .init()
#endif
    }

    /// The "machine-turn-side-left" asset catalog image.
    static var machineTurnSideLeft: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .machineTurnSideLeft)
#else
        .init()
#endif
    }

    /// The "machine-turn-side-right" asset catalog image.
    static var machineTurnSideRight: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .machineTurnSideRight)
#else
        .init()
#endif
    }

    /// The "machine-wrong" asset catalog image.
    static var machineWrong: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .machineWrong)
#else
        .init()
#endif
    }

    /// The "pirate-airborne" asset catalog image.
    static var pirateAirborne: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pirateAirborne)
#else
        .init()
#endif
    }

    /// The "pirate-clap-contact" asset catalog image.
    static var pirateClapContact: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pirateClapContact)
#else
        .init()
#endif
    }

    /// The "pirate-clap-open" asset catalog image.
    static var pirateClapOpen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pirateClapOpen)
#else
        .init()
#endif
    }

    /// The "pirate-crouch" asset catalog image.
    static var pirateCrouch: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pirateCrouch)
#else
        .init()
#endif
    }

    /// The "pirate-fallen" asset catalog image.
    static var pirateFallen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pirateFallen)
#else
        .init()
#endif
    }

    /// The "pirate-idle" asset catalog image.
    static var pirateIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pirateIdle)
#else
        .init()
#endif
    }

    /// The "pirate-opening-idle" asset catalog image.
    static var pirateOpeningIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pirateOpeningIdle)
#else
        .init()
#endif
    }

    /// The "pirate-push-up" asset catalog image.
    static var piratePushUp: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .piratePushUp)
#else
        .init()
#endif
    }

    /// The "pirate-stumble" asset catalog image.
    static var pirateStumble: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pirateStumble)
#else
        .init()
#endif
    }

    /// The "pirate-turn-01" asset catalog image.
    static var pirateTurn01: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pirateTurn01)
#else
        .init()
#endif
    }

    /// The "pirate-turn-02" asset catalog image.
    static var pirateTurn02: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pirateTurn02)
#else
        .init()
#endif
    }

    /// The "pirate-turn-03" asset catalog image.
    static var pirateTurn03: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pirateTurn03)
#else
        .init()
#endif
    }

    /// The "pirate-turn-04" asset catalog image.
    static var pirateTurn04: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pirateTurn04)
#else
        .init()
#endif
    }

    /// The "pirate-turn-05" asset catalog image.
    static var pirateTurn05: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pirateTurn05)
#else
        .init()
#endif
    }

    /// The "pirate-turn-06" asset catalog image.
    static var pirateTurn06: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pirateTurn06)
#else
        .init()
#endif
    }

    /// The "pirate-wrong" asset catalog image.
    static var pirateWrong: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pirateWrong)
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

    /// The "valley-airborne" asset catalog image.
    static var valleyAirborne: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .valleyAirborne)
#else
        .init()
#endif
    }

    /// The "valley-clap-contact" asset catalog image.
    static var valleyClapContact: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .valleyClapContact)
#else
        .init()
#endif
    }

    /// The "valley-clap-open" asset catalog image.
    static var valleyClapOpen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .valleyClapOpen)
#else
        .init()
#endif
    }

    /// The "valley-crouch" asset catalog image.
    static var valleyCrouch: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .valleyCrouch)
#else
        .init()
#endif
    }

    /// The "valley-idle" asset catalog image.
    static var valleyIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .valleyIdle)
#else
        .init()
#endif
    }

    /// The "valley-opening-idle" asset catalog image.
    static var valleyOpeningIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .valleyOpeningIdle)
#else
        .init()
#endif
    }

    /// The "valley-push-up" asset catalog image.
    static var valleyPushUp: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .valleyPushUp)
#else
        .init()
#endif
    }

    /// The "valley-stumble" asset catalog image.
    static var valleyStumble: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .valleyStumble)
#else
        .init()
#endif
    }

    /// The "valley-turn-01" asset catalog image.
    static var valleyTurn01: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .valleyTurn01)
#else
        .init()
#endif
    }

    /// The "valley-turn-02" asset catalog image.
    static var valleyTurn02: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .valleyTurn02)
#else
        .init()
#endif
    }

    /// The "valley-turn-03" asset catalog image.
    static var valleyTurn03: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .valleyTurn03)
#else
        .init()
#endif
    }

    /// The "valley-turn-04" asset catalog image.
    static var valleyTurn04: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .valleyTurn04)
#else
        .init()
#endif
    }

    /// The "valley-turn-05" asset catalog image.
    static var valleyTurn05: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .valleyTurn05)
#else
        .init()
#endif
    }

    /// The "valley-turn-06" asset catalog image.
    static var valleyTurn06: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .valleyTurn06)
#else
        .init()
#endif
    }

    /// The "valley-turn-07" asset catalog image.
    static var valleyTurn07: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .valleyTurn07)
#else
        .init()
#endif
    }

    /// The "valley-wrong" asset catalog image.
    static var valleyWrong: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .valleyWrong)
#else
        .init()
#endif
    }

    /// The "village-airborne" asset catalog image.
    static var villageAirborne: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageAirborne)
#else
        .init()
#endif
    }

    /// The "village-clap-contact" asset catalog image.
    static var villageClapContact: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageClapContact)
#else
        .init()
#endif
    }

    /// The "village-clap-open" asset catalog image.
    static var villageClapOpen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageClapOpen)
#else
        .init()
#endif
    }

    /// The "village-clap-release" asset catalog image.
    static var villageClapRelease: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageClapRelease)
#else
        .init()
#endif
    }

    /// The "village-crouch" asset catalog image.
    static var villageCrouch: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageCrouch)
#else
        .init()
#endif
    }

    /// The "village-fallen" asset catalog image.
    static var villageFallen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageFallen)
#else
        .init()
#endif
    }

    /// The "village-idle" asset catalog image.
    static var villageIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageIdle)
#else
        .init()
#endif
    }

    /// The "village-opening-idle" asset catalog image.
    static var villageOpeningIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageOpeningIdle)
#else
        .init()
#endif
    }

    /// The "village-push-up" asset catalog image.
    static var villagePushUp: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villagePushUp)
#else
        .init()
#endif
    }

    /// The "village-rise-high" asset catalog image.
    static var villageRiseHigh: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageRiseHigh)
#else
        .init()
#endif
    }

    /// The "village-rise-low" asset catalog image.
    static var villageRiseLow: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageRiseLow)
#else
        .init()
#endif
    }

    /// The "village-stumble" asset catalog image.
    static var villageStumble: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageStumble)
#else
        .init()
#endif
    }

    /// The "village-turn-01" asset catalog image.
    static var villageTurn01: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageTurn01)
#else
        .init()
#endif
    }

    /// The "village-turn-02" asset catalog image.
    static var villageTurn02: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageTurn02)
#else
        .init()
#endif
    }

    /// The "village-turn-03" asset catalog image.
    static var villageTurn03: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageTurn03)
#else
        .init()
#endif
    }

    /// The "village-turn-04" asset catalog image.
    static var villageTurn04: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageTurn04)
#else
        .init()
#endif
    }

    /// The "village-turn-05" asset catalog image.
    static var villageTurn05: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageTurn05)
#else
        .init()
#endif
    }

    /// The "village-turn-06" asset catalog image.
    static var villageTurn06: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageTurn06)
#else
        .init()
#endif
    }

    /// The "village-turn-07" asset catalog image.
    static var villageTurn07: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageTurn07)
#else
        .init()
#endif
    }

    /// The "village-wrong" asset catalog image.
    static var villageWrong: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .villageWrong)
#else
        .init()
#endif
    }

    /// The "volcano-airborne" asset catalog image.
    static var volcanoAirborne: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoAirborne)
#else
        .init()
#endif
    }

    /// The "volcano-clap-contact" asset catalog image.
    static var volcanoClapContact: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoClapContact)
#else
        .init()
#endif
    }

    /// The "volcano-clap-contact-2" asset catalog image.
    static var volcanoClapContact2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoClapContact2)
#else
        .init()
#endif
    }

    /// The "volcano-clap-open" asset catalog image.
    static var volcanoClapOpen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoClapOpen)
#else
        .init()
#endif
    }

    /// The "volcano-clap-open-2" asset catalog image.
    static var volcanoClapOpen2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoClapOpen2)
#else
        .init()
#endif
    }

    /// The "volcano-crouch" asset catalog image.
    static var volcanoCrouch: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoCrouch)
#else
        .init()
#endif
    }

    /// The "volcano-fallen" asset catalog image.
    static var volcanoFallen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoFallen)
#else
        .init()
#endif
    }

    /// The "volcano-idle" asset catalog image.
    static var volcanoIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoIdle)
#else
        .init()
#endif
    }

    /// The "volcano-landing" asset catalog image.
    static var volcanoLanding: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoLanding)
#else
        .init()
#endif
    }

    /// The "volcano-opening-idle" asset catalog image.
    static var volcanoOpeningIdle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoOpeningIdle)
#else
        .init()
#endif
    }

    /// The "volcano-push-up" asset catalog image.
    static var volcanoPushUp: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoPushUp)
#else
        .init()
#endif
    }

    /// The "volcano-rise-high" asset catalog image.
    static var volcanoRiseHigh: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoRiseHigh)
#else
        .init()
#endif
    }

    /// The "volcano-rise-low" asset catalog image.
    static var volcanoRiseLow: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoRiseLow)
#else
        .init()
#endif
    }

    /// The "volcano-stumble" asset catalog image.
    static var volcanoStumble: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoStumble)
#else
        .init()
#endif
    }

    /// The "volcano-takeoff" asset catalog image.
    static var volcanoTakeoff: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoTakeoff)
#else
        .init()
#endif
    }

    /// The "volcano-turn-01" asset catalog image.
    static var volcanoTurn01: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoTurn01)
#else
        .init()
#endif
    }

    /// The "volcano-turn-02" asset catalog image.
    static var volcanoTurn02: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoTurn02)
#else
        .init()
#endif
    }

    /// The "volcano-turn-03" asset catalog image.
    static var volcanoTurn03: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoTurn03)
#else
        .init()
#endif
    }

    /// The "volcano-turn-04" asset catalog image.
    static var volcanoTurn04: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoTurn04)
#else
        .init()
#endif
    }

    /// The "volcano-turn-05" asset catalog image.
    static var volcanoTurn05: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoTurn05)
#else
        .init()
#endif
    }

    /// The "volcano-turn-06" asset catalog image.
    static var volcanoTurn06: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoTurn06)
#else
        .init()
#endif
    }

    /// The "volcano-turn-07" asset catalog image.
    static var volcanoTurn07: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoTurn07)
#else
        .init()
#endif
    }

    /// The "volcano-turn-08" asset catalog image.
    static var volcanoTurn08: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoTurn08)
#else
        .init()
#endif
    }

    /// The "volcano-wrong" asset catalog image.
    static var volcanoWrong: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volcanoWrong)
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