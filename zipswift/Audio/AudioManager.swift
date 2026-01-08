//
//  AudioManager.swift
//  zipswift
//
//  Manages game audio with synthesized satisfying sounds.
//  Uses AVAudioEngine to generate tones programmatically.
//

import AVFoundation
import Foundation

enum AudioTheme: String, CaseIterable, Codable {
    case classic
    case retro
    case minimal
    case playful

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .retro: return "Retro"
        case .minimal: return "Minimal"
        case .playful: return "Playful"
        }
    }

    var description: String {
        switch self {
        case .classic: return "Warm sine waves with major chords"
        case .retro: return "8-bit style square waves"
        case .minimal: return "Soft clicks and subtle tones"
        case .playful: return "Bouncy xylophone-style sounds"
        }
    }

    var icon: String {
        switch self {
        case .classic: return "waveform"
        case .retro: return "arcade.stick"
        case .minimal: return "circle"
        case .playful: return "sparkles"
        }
    }
}

class AudioManager {
    static let shared = AudioManager()

    private var audioEngine: AVAudioEngine?
    private var playerNodes: [AVAudioPlayerNode] = []

    private var isSoundEnabled: Bool {
        SettingsManager.shared.soundEnabled
    }

    private var currentTheme: AudioTheme {
        SettingsManager.shared.audioTheme
    }

    private init() {
        setupAudioSession()
        setupAudioEngine()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: .mixWithOthers)
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
    }

    // MARK: - Public Methods

    func playPopSound() {
        guard isSoundEnabled else { return }
        switch currentTheme {
        case .classic:
            playTone(frequency: 880, duration: 0.05, volume: 0.3, attack: 0.01, decay: 0.04, waveform: .sine)
        case .retro:
            playTone(frequency: 1200, duration: 0.03, volume: 0.25, attack: 0.005, decay: 0.02, waveform: .square)
        case .minimal:
            playTone(frequency: 1000, duration: 0.02, volume: 0.15, attack: 0.005, decay: 0.015, waveform: .sine)
        case .playful:
            playTone(frequency: 1568, duration: 0.08, volume: 0.35, attack: 0.01, decay: 0.07, waveform: .triangle)
        }
    }

    func playNodeSound() {
        guard isSoundEnabled else { return }
        let freqs: [Float]
        let waveform: Waveform

        switch currentTheme {
        case .classic:
            freqs = [523.25, 659.25, 783.99]
            waveform = .sine
        case .retro:
            freqs = [440, 554.37, 659.25]
            waveform = .square
        case .minimal:
            freqs = [880, 1046.50]
            waveform = .sine
        case .playful:
            freqs = [784, 988, 1175, 1568]
            waveform = .triangle
        }

        for (index, freq) in freqs.enumerated() {
            let delay = Double(index) * (currentTheme == .playful ? 0.03 : 0.05)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                let volume: Float = self?.currentTheme == .retro ? 0.25 : 0.4
                let duration: Float = self?.currentTheme == .minimal ? 0.08 : 0.15
                self?.playTone(frequency: freq, duration: duration, volume: volume, attack: 0.01, decay: duration - 0.01, waveform: waveform)
            }
        }
    }

    func playCompletionSound() {
        guard isSoundEnabled else { return }

        switch currentTheme {
        case .classic:
            playClassicFanfare()
        case .retro:
            playRetroFanfare()
        case .minimal:
            playMinimalFanfare()
        case .playful:
            playPlayfulFanfare()
        }
    }

    func playThreeStarFanfare() {
        guard isSoundEnabled else { return }

        switch currentTheme {
        case .classic:
            playClassicThreeStarFanfare()
        case .retro:
            playRetroThreeStarFanfare()
        case .minimal:
            playMinimalThreeStarFanfare()
        case .playful:
            playPlayfulThreeStarFanfare()
        }
    }

    func playStarCompletionSound(stars: Int) {
        if stars >= 3 {
            playThreeStarFanfare()
        } else {
            playCompletionSound()
        }
    }

    func playDailyCompletionSound() {
        guard isSoundEnabled else { return }
        playThreeStarFanfare()
    }

    func playAchievementSound() {
        guard isSoundEnabled else { return }
        let waveform: Waveform = currentTheme == .retro ? .square : .sine
        let freqs: [Float] = [659.25, 783.99, 987.77, 1318.51]

        for (index, freq) in freqs.enumerated() {
            let delay = Double(index) * 0.08
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: 0.2, volume: 0.45, attack: 0.01, decay: 0.18, waveform: waveform)
            }
        }
    }

    func previewTheme(_ theme: AudioTheme) {
        guard isSoundEnabled else { return }
        let original = currentTheme
        SettingsManager.shared.audioTheme = theme

        let freqs: [Float]
        let waveform: Waveform

        switch theme {
        case .classic:
            freqs = [523.25, 659.25, 783.99]
            waveform = .sine
        case .retro:
            freqs = [440, 554.37, 659.25]
            waveform = .square
        case .minimal:
            freqs = [880, 1046.50]
            waveform = .sine
        case .playful:
            freqs = [784, 988, 1175]
            waveform = .triangle
        }

        for (index, freq) in freqs.enumerated() {
            let delay = Double(index) * 0.05
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: 0.12, volume: 0.4, attack: 0.01, decay: 0.1, waveform: waveform)
            }
        }

        SettingsManager.shared.audioTheme = original
    }

    func toggleSound() {
        SettingsManager.shared.soundEnabled.toggle()
    }

    var soundEnabled: Bool {
        isSoundEnabled
    }

    // MARK: - Theme-Specific Fanfares

    private func playClassicFanfare() {
        let freqs: [Float] = [523.25, 587.33, 659.25, 698.46, 783.99, 880.0, 987.77, 1046.50]
        for (index, freq) in freqs.enumerated() {
            let delay = Double(index) * 0.08
            let duration: Float = index == freqs.count - 1 ? 0.4 : 0.12
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: duration, volume: 0.5, attack: 0.01, decay: duration - 0.02, waveform: .sine)
            }
        }
    }

    private func playRetroFanfare() {
        let freqs: [Float] = [440, 523.25, 659.25, 880]
        for (index, freq) in freqs.enumerated() {
            let delay = Double(index) * 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: 0.15, volume: 0.3, attack: 0.005, decay: 0.14, waveform: .square)
            }
        }
    }

    private func playMinimalFanfare() {
        let freqs: [Float] = [880, 1046.50, 1318.51]
        for (index, freq) in freqs.enumerated() {
            let delay = Double(index) * 0.15
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: 0.2, volume: 0.25, attack: 0.02, decay: 0.18, waveform: .sine)
            }
        }
    }

    private func playPlayfulFanfare() {
        let freqs: [Float] = [784, 988, 1175, 1319, 1568, 1760, 2093]
        for (index, freq) in freqs.enumerated() {
            let delay = Double(index) * 0.06
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: 0.12, volume: 0.4, attack: 0.005, decay: 0.11, waveform: .triangle)
            }
        }
    }

    private func playClassicThreeStarFanfare() {
        let freqs: [Float] = [523.25, 587.33, 659.25, 698.46, 783.99, 880.0, 1046.50, 1318.51, 1567.98, 2093.0]
        for (index, freq) in freqs.enumerated() {
            let delay = Double(index) * 0.1
            let duration: Float = index >= freqs.count - 2 ? 0.5 : 0.12
            let volume: Float = index >= freqs.count - 2 ? 0.6 : 0.5
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: duration, volume: volume, attack: 0.01, decay: duration - 0.02, waveform: .sine)
            }
        }
    }

    private func playRetroThreeStarFanfare() {
        let freqs: [Float] = [440, 523.25, 659.25, 880, 1046.50, 1318.51]
        for (index, freq) in freqs.enumerated() {
            let delay = Double(index) * 0.12
            let volume: Float = index >= freqs.count - 2 ? 0.4 : 0.3
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: 0.18, volume: volume, attack: 0.005, decay: 0.17, waveform: .square)
            }
        }
    }

    private func playMinimalThreeStarFanfare() {
        let freqs: [Float] = [880, 1046.50, 1318.51, 1567.98, 2093.0]
        for (index, freq) in freqs.enumerated() {
            let delay = Double(index) * 0.2
            let volume: Float = index >= freqs.count - 2 ? 0.35 : 0.25
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: 0.25, volume: volume, attack: 0.02, decay: 0.22, waveform: .sine)
            }
        }
    }

    private func playPlayfulThreeStarFanfare() {
        let freqs: [Float] = [784, 988, 1175, 1319, 1568, 1760, 2093, 2349, 2637, 3136]
        for (index, freq) in freqs.enumerated() {
            let delay = Double(index) * 0.05
            let volume: Float = index >= freqs.count - 3 ? 0.5 : 0.4
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: 0.1, volume: volume, attack: 0.005, decay: 0.09, waveform: .triangle)
            }
        }
    }

    // MARK: - Waveform Types

    private enum Waveform {
        case sine
        case square
        case triangle
    }

    // MARK: - Tone Generation

    private func playTone(frequency: Float, duration: Float, volume: Float, attack: Float, decay: Float, waveform: Waveform) {
        guard let engine = audioEngine else { return }

        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(Double(duration) * sampleRate)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return
        }

        buffer.frameLength = frameCount

        guard let floatData = buffer.floatChannelData?[0] else { return }

        let attackFrames = Int(attack * Float(sampleRate))
        let decayFrames = Int(decay * Float(sampleRate))
        let sustainFrames = Int(frameCount) - attackFrames - decayFrames

        for frame in 0..<Int(frameCount) {
            let time = Float(frame) / Float(sampleRate)
            var sample: Float

            switch waveform {
            case .sine:
                sample = sin(2.0 * .pi * frequency * time)
            case .square:
                let sineValue = sin(2.0 * .pi * frequency * time)
                sample = sineValue >= 0 ? 0.8 : -0.8
            case .triangle:
                let period = 1.0 / frequency
                let t = time.truncatingRemainder(dividingBy: period)
                let normalized = t / period
                if normalized < 0.5 {
                    sample = 4.0 * normalized - 1.0
                } else {
                    sample = 3.0 - 4.0 * normalized
                }
            }

            var envelope: Float = 1.0
            if frame < attackFrames {
                envelope = Float(frame) / Float(attackFrames)
            } else if frame >= attackFrames + sustainFrames {
                let decayProgress = Float(frame - attackFrames - sustainFrames) / Float(decayFrames)
                envelope = 1.0 - decayProgress
            }

            sample *= envelope * volume
            floatData[frame] = sample
        }

        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)

        do {
            if !engine.isRunning {
                try engine.start()
            }
            playerNode.scheduleBuffer(buffer, completionHandler: { [weak self, weak engine, weak playerNode] in
                DispatchQueue.main.async {
                    guard let engine = engine, let playerNode = playerNode else { return }
                    engine.detach(playerNode)
                    self?.playerNodes.removeAll { $0 === playerNode }
                }
            })
            playerNode.play()
            playerNodes.append(playerNode)
        } catch {
            print("Failed to play tone: \(error)")
            engine.detach(playerNode)
        }
    }
}
