import AVFoundation
import UIKit

/// Short, gentle tones respect silent mode and mix with other audio.
@MainActor
final class DinoAnswerFeedback {
    static let shared = DinoAnswerFeedback()
    private let audio = DinoAnswerAudio()
    private let haptics = UINotificationFeedbackGenerator()

    func prepare(sound: Bool, vibration: Bool) {
        if vibration { haptics.prepare() }
        if sound { audio.prepare() }
    }

    func play(correct: Bool, sound: Bool, vibration: Bool) {
        if vibration { haptics.notificationOccurred(correct ? .success : .warning) }
        if sound { audio.play(correct: correct) }
    }

    /// Menu and control taps. Answer judgments keep their own tones.
    func playSelect() {
        audio.playSelect()
    }

    func playLevelComplete() {
        audio.playLevelComplete()
    }

    @discardableResult
    func playGroundImpact(after delay: Double) -> Int {
        audio.playGroundImpact(after: delay)
    }

    func stopLevelOutcome() {
        audio.stopLevelOutcome()
    }

    /// Takeoff, the flight into the next world, and the landing share one clock.
    func playWorldJourney(takeoff: Double, landing: Double) {
        audio.playWorldJourney(takeoff: takeoff, landing: landing)
    }

    func stopWorldJourney() {
        audio.stopWorldJourney()
    }

    func cancelImpact(_ generation: Int) {
        audio.cancelImpact(generation)
    }

    nonisolated func setSoundEnabled(_ enabled: Bool) {
        audio.setEnabled(enabled)
    }
}

/// Reads the question title with the best installed Apple voice for the selected language.
@MainActor
final class DinoQuestionSpeech {
    static let shared = DinoQuestionSpeech()
    private let synthesizer = AVSpeechSynthesizer()
    private var nextToken = 0
    private var active: [String: Int] = [:]

    @discardableResult
    func claim(owner: String, text: String, languageCode: String) -> Int {
        nextToken += 1
        let token = nextToken
        active[owner] = token
        let spoken = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !spoken.isEmpty, !UIAccessibility.isVoiceOverRunning else {
            synthesizer.stopSpeaking(at: .immediate)
            return token
        }
        configureSession()
        let utterance = AVSpeechUtterance(string: spoken)
        utterance.voice = Self.voice(for: languageCode)
        utterance.prefersAssistiveTechnologySettings = false
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
        return token
    }

    func release(owner: String, token: Int) {
        guard active[owner] == token else { return }
        active[owner] = nil
        stopIfIdle()
    }

    /// Stops the current title without giving the next question's speech back to an older claim.
    func interrupt() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func stopIfIdle() {
        guard active.isEmpty else { return }
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .spokenAudio, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private static func voice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        let installed = AVSpeechSynthesisVoice.speechVoices().map {
            DinoSpeechVoice(identifier: $0.identifier, name: $0.name,
                            language: $0.language, quality: $0.quality.rawValue)
        }
        if let best = DinoSpeechVoicePicker.bestVoice(for: languageCode, among: installed),
           let voice = AVSpeechSynthesisVoice(identifier: best.identifier) {
            return voice
        }
        return AVSpeechSynthesisVoice(language: DinoSpeechVoicePicker.preferredLanguageIdentifier(for: languageCode))
    }
}

/// All audio state stays on this serial queue. AVAudioPlayer can synchronously
/// activate the audio session in prepareToPlay/play and release hardware in stop.
private final class DinoAnswerAudio: @unchecked Sendable {
    private let queue = DispatchQueue(label: "DinoTime.answerAudio", qos: .userInitiated)
    private var correctPlayer: AVAudioPlayer?
    private var incorrectPlayer: AVAudioPlayer?
    private var selectPlayer: AVAudioPlayer?
    private var levelCompletePlayer: AVAudioPlayer?
    private var impactPlayer: AVAudioPlayer?
    private var jumpPlayer: AVAudioPlayer?
    private var landPlayer: AVAudioPlayer?
    private var worldPlayer: AVAudioPlayer?
    private let generationLock = NSLock()
    private var soundEnabled = true
    private var impactGeneration = 0
    private var journeyGeneration = 0
    private var lastSelect = Date.distantPast
    private lazy var correctTone = Self.tone(frequencies: [659.25, 880])
    private lazy var incorrectTone = Self.tone(frequencies: [330, 261.63])

    func setEnabled(_ enabled: Bool) {
        queue.async { [self] in soundEnabled = enabled }
    }

    func prepare() {
        queue.async { [self] in preparePlayers() }
    }

    func play(correct: Bool) {
        queue.async { [self] in
            guard soundEnabled else { return }
            preparePlayers()
            correctPlayer?.stop()
            incorrectPlayer?.stop()
            let player = correct ? correctPlayer : incorrectPlayer
            player?.currentTime = 0
            player?.play()
        }
    }

    func playSelect() {
        queue.async { [self] in
            guard soundEnabled else { return }
            let now = Date()
            guard now.timeIntervalSince(lastSelect) > 0.04 else { return }
            lastSelect = now
            preparePlayers()
            selectPlayer?.currentTime = 0
            selectPlayer?.play()
        }
    }

    func playLevelComplete() {
        queue.async { [self] in
            guard soundEnabled else { return }
            preparePlayers()
            levelCompletePlayer?.currentTime = 0
            levelCompletePlayer?.play()
        }
    }

    @discardableResult
    func playGroundImpact(after delay: Double) -> Int {
        let generation = nextGeneration(\.impactGeneration)
        queue.async { [self] in
            guard soundEnabled, generation == current(\.impactGeneration) else { return }
            preparePlayers()
            queue.asyncAfter(deadline: .now() + delay) { [self] in
                guard generation == current(\.impactGeneration), soundEnabled else { return }
                impactPlayer?.currentTime = 0
                impactPlayer?.play()
            }
        }
        return generation
    }

    func stopLevelOutcome() {
        queue.async { [self] in
            levelCompletePlayer?.stop()
            invalidate(\.impactGeneration)
            impactPlayer?.stop()
        }
    }

    func playWorldJourney(takeoff: Double, landing: Double) {
        let generation = nextGeneration(\.journeyGeneration)
        queue.async { [self] in
            guard soundEnabled, generation == current(\.journeyGeneration) else { return }
            preparePlayers()
            schedule(jumpPlayer, after: takeoff, generation: generation)
            schedule(worldPlayer, after: takeoff + 0.08, generation: generation)
            schedule(landPlayer, after: landing, generation: generation)
        }
    }

    func stopWorldJourney() {
        queue.async { [self] in
            invalidate(\.journeyGeneration)
            jumpPlayer?.stop()
            worldPlayer?.stop()
            landPlayer?.stop()
        }
    }

    private func schedule(_ player: AVAudioPlayer?, after delay: Double, generation: Int) {
        queue.asyncAfter(deadline: .now() + max(0, delay)) { [self] in
            guard generation == current(\.journeyGeneration), soundEnabled else { return }
            player?.currentTime = 0
            player?.play()
        }
    }

    func cancelImpact(_ generation: Int) {
        queue.async { [self] in
            guard current(\.impactGeneration) == generation else { return }
            invalidate(\.impactGeneration)
            impactPlayer?.stop()
        }
    }

    private func nextGeneration(_ keyPath: ReferenceWritableKeyPath<DinoAnswerAudio, Int>) -> Int {
        generationLock.lock()
        self[keyPath: keyPath] += 1
        let generation = self[keyPath: keyPath]
        generationLock.unlock()
        return generation
    }

    private func current(_ keyPath: KeyPath<DinoAnswerAudio, Int>) -> Int {
        generationLock.lock()
        let generation = self[keyPath: keyPath]
        generationLock.unlock()
        return generation
    }

    private func invalidate(_ keyPath: ReferenceWritableKeyPath<DinoAnswerAudio, Int>) {
        generationLock.lock()
        self[keyPath: keyPath] += 1
        generationLock.unlock()
    }

    private func preparePlayers() {
        dispatchPrecondition(condition: .onQueue(queue))
        let ready = correctPlayer != nil && incorrectPlayer != nil && selectPlayer != nil
            && levelCompletePlayer != nil && impactPlayer != nil
            && jumpPlayer != nil && landPlayer != nil && worldPlayer != nil
        guard !ready else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        if correctPlayer == nil { correctPlayer = try? makePlayer(data: correctTone, volume: 0.45) }
        if incorrectPlayer == nil { incorrectPlayer = try? makePlayer(data: incorrectTone, volume: 0.45) }
        if selectPlayer == nil { selectPlayer = try? makePlayer(resource: "select-menu", volume: 0.85) }
        if levelCompletePlayer == nil { levelCompletePlayer = try? makePlayer(resource: "end-of-level", volume: 0.85) }
        if impactPlayer == nil { impactPlayer = try? makePlayer(resource: "zero-stars-fall", volume: 0.85) }
        if jumpPlayer == nil { jumpPlayer = try? makePlayer(resource: "jump-jump", volume: 0.85) }
        if landPlayer == nil { landPlayer = try? makePlayer(resource: "jump-land", volume: 0.85) }
        if worldPlayer == nil { worldPlayer = try? makePlayer(resource: "to-new-world", volume: 0.85) }
    }

    private func makePlayer(data: Data, volume: Float, fileTypeHint: String? = nil) throws -> AVAudioPlayer {
        dispatchPrecondition(condition: .onQueue(queue))
        let player = try AVAudioPlayer(data: data, fileTypeHint: fileTypeHint)
        player.volume = volume
        player.prepareToPlay()
        return player
    }

    private func makePlayer(resource: String, volume: Float) throws -> AVAudioPlayer {
        let data = NSDataAsset(name: resource, bundle: .main)?.data
            ?? Bundle.main.url(forResource: resource, withExtension: "m4a").flatMap { try? Data(contentsOf: $0) }
        guard let data else { throw CocoaError(.fileNoSuchFile) }
        return try makePlayer(data: data, volume: volume, fileTypeHint: AVFileType.m4a.rawValue)
    }

    /// Small PCM WAVs generated once; no external audio files or dependencies.
    private static func tone(frequencies: [Double]) -> Data {
        let sampleRate = 22_050
        let noteSamples = Int(Double(sampleRate) * 0.12)
        let byteCount = noteSamples * frequencies.count * 2
        var data = Data()
        func ascii(_ value: String) { data.append(contentsOf: value.utf8) }
        func word<T: FixedWidthInteger>(_ value: T) {
            var little = value.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }
        ascii("RIFF"); word(UInt32(36 + byteCount)); ascii("WAVEfmt ")
        word(UInt32(16)); word(UInt16(1)); word(UInt16(1))
        word(UInt32(sampleRate)); word(UInt32(sampleRate * 2))
        word(UInt16(2)); word(UInt16(16)); ascii("data"); word(UInt32(byteCount))
        for frequency in frequencies {
            for sample in 0..<noteSamples {
                let time = Double(sample) / Double(sampleRate)
                let envelope = min(1, time / 0.012) * min(1, (0.12 - time) / 0.025)
                word(Int16(sin(2 * .pi * frequency * time) * envelope * 10_000))
            }
        }
        return data
    }
}
