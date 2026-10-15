import AVFoundation
import UIKit

/// Short, gentle tones respect silent mode and mix with other audio.
@MainActor
final class DinoAnswerFeedback {
    static let shared = DinoAnswerFeedback()
    private var correctPlayer: AVAudioPlayer?
    private var incorrectPlayer: AVAudioPlayer?
    private let haptics = UINotificationFeedbackGenerator()
    private let correctTone = DinoAnswerFeedback.tone(frequencies: [659.25, 880])
    private let incorrectTone = DinoAnswerFeedback.tone(frequencies: [330, 261.63])

    func prepare(sound: Bool, vibration: Bool) {
        if vibration { haptics.prepare() }
        guard sound, correctPlayer == nil || incorrectPlayer == nil else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            if correctPlayer == nil { correctPlayer = try makePlayer(data: correctTone) }
            if incorrectPlayer == nil { incorrectPlayer = try makePlayer(data: incorrectTone) }
        } catch { /* Try again on the next answer if audio is temporarily unavailable. */ }
    }

    func play(correct: Bool, sound: Bool, vibration: Bool) {
        if vibration { haptics.notificationOccurred(correct ? .success : .warning) }
        guard sound else { return }
        prepare(sound: true, vibration: false)
        correctPlayer?.stop()
        incorrectPlayer?.stop()
        let player = correct ? correctPlayer : incorrectPlayer
        player?.currentTime = 0
        player?.play()
    }

    private func makePlayer(data: Data) throws -> AVAudioPlayer {
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
