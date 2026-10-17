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
