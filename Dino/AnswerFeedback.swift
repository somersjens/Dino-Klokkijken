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
    private lazy var correctTone = Self.tone(frequencies: [659.25, 880])
    private lazy var incorrectTone = Self.tone(frequencies: [330, 261.63])

    func prepare() {
        queue.async { [self] in preparePlayers() }
    }

    func play(correct: Bool) {
        queue.async { [self] in
            preparePlayers()
            correctPlayer?.stop()
            incorrectPlayer?.stop()
            let player = correct ? correctPlayer : incorrectPlayer
            player?.currentTime = 0
            player?.play()
        }
    }

    private func preparePlayers() {
        dispatchPrecondition(condition: .onQueue(queue))
        guard correctPlayer == nil || incorrectPlayer == nil else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            if correctPlayer == nil { correctPlayer = try makePlayer(data: correctTone) }
            if incorrectPlayer == nil { incorrectPlayer = try makePlayer(data: incorrectTone) }
        } catch { /* Try again on the next answer if audio is temporarily unavailable. */ }
    }

    private func makePlayer(data: Data) throws -> AVAudioPlayer {
        dispatchPrecondition(condition: .onQueue(queue))
        let player = try AVAudioPlayer(data: data)
        player.volume = 0.45
        player.prepareToPlay()
        return player
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
