//
//  AudioManager.swift
//  zipswift
//
//  Manages game audio with synthesized satisfying sounds.
//  Uses AVAudioEngine to generate tones programmatically.
//

import AVFoundation
import Foundation

class AudioManager {
    static let shared = AudioManager()

    private var audioEngine: AVAudioEngine?
    private var playerNodes: [AVAudioPlayerNode] = []

    // Check settings for sound enabled state
    private var isSoundEnabled: Bool {
        SettingsManager.shared.soundEnabled
    }

    // Sound frequencies (in Hz) - using C major scale for positive feel
    private let popFrequency: Float = 880      // A5 - bright pop
    private let nodeFrequencies: [Float] = [523.25, 659.25, 783.99]  // C5, E5, G5 - major chord
    private let fanfareFrequencies: [Float] = [523.25, 587.33, 659.25, 698.46, 783.99, 880.0, 987.77, 1046.50]  // C major scale up to C6

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

    /// Play a short pop sound when visiting a cell
    func playPopSound() {
        guard isSoundEnabled else { return }
        playTone(frequency: popFrequency, duration: 0.05, volume: 0.3, attack: 0.01, decay: 0.04)
    }

    /// Play a pleasant ding when reaching a numbered node
    func playNodeSound() {
        guard isSoundEnabled else { return }
        // Play a quick ascending arpeggio (C-E-G)
        for (index, freq) in nodeFrequencies.enumerated() {
            let delay = Double(index) * 0.05
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: 0.15, volume: 0.4, attack: 0.01, decay: 0.14)
            }
        }
    }

    /// Play a celebratory fanfare when completing the level
    func playCompletionSound() {
        guard isSoundEnabled else { return }
        // Play ascending C major scale with slight acceleration
        for (index, freq) in fanfareFrequencies.enumerated() {
            let delay = Double(index) * 0.08
            let duration: Float = index == fanfareFrequencies.count - 1 ? 0.4 : 0.12
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: duration, volume: 0.5, attack: 0.01, decay: duration - 0.02)
            }
        }
    }

    /// Play a special celebratory fanfare for daily challenge completion
    func playDailyCompletionSound() {
        guard isSoundEnabled else { return }
        let specialFanfare: [Float] = [
            523.25, 659.25, 783.99,  // C-E-G chord
            880.0, 987.77, 1046.50,  // A-B-C ascending
            1318.51, 1567.98, 2093.0 // E6-G6-C7 triumphant ending
        ]

        for (index, freq) in specialFanfare.enumerated() {
            let delay = Double(index) * 0.1
            let duration: Float = index >= specialFanfare.count - 3 ? 0.5 : 0.15
            let volume: Float = index >= specialFanfare.count - 3 ? 0.6 : 0.5
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: duration, volume: volume, attack: 0.01, decay: duration - 0.02)
            }
        }
    }

    /// Play achievement unlock sound
    func playAchievementSound() {
        guard isSoundEnabled else { return }
        let achievementTones: [Float] = [
            659.25, 783.99, 987.77, 1318.51
        ]

        for (index, freq) in achievementTones.enumerated() {
            let delay = Double(index) * 0.08
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: freq, duration: 0.2, volume: 0.45, attack: 0.01, decay: 0.18)
            }
        }
    }

    /// Toggle sound on/off
    func toggleSound() {
        SettingsManager.shared.soundEnabled.toggle()
    }

    var soundEnabled: Bool {
        isSoundEnabled
    }

    // MARK: - Tone Generation

    private func playTone(frequency: Float, duration: Float, volume: Float, attack: Float, decay: Float) {
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
            // Generate sine wave
            let time = Float(frame) / Float(sampleRate)
            var sample = sin(2.0 * .pi * frequency * time)

            // Apply envelope (attack-sustain-decay)
            var envelope: Float = 1.0
            if frame < attackFrames {
                // Attack phase
                envelope = Float(frame) / Float(attackFrames)
            } else if frame >= attackFrames + sustainFrames {
                // Decay phase
                let decayProgress = Float(frame - attackFrames - sustainFrames) / Float(decayFrames)
                envelope = 1.0 - decayProgress
            }

            sample *= envelope * volume
            floatData[frame] = sample
        }

        // Create and configure player node
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
