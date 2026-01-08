//
//  ChallengeGameView.swift
//  zipswift
//
//  Gameplay view for challenge modes.
//

import SwiftUI
import UIKit

struct ChallengeGameView: View {
    let mode: ChallengeMode
    @Environment(\.dismiss) private var dismiss

    @State private var gameState: GameState
    @State private var elapsedTime: TimeInterval = 0
    @State private var remainingTime: TimeInterval = 60
    @State private var timerTask: Task<Void, Never>?
    @State private var puzzlesCompleted = 0
    @State private var speedRunTimes: [TimeInterval] = []
    @State private var totalSpeedRunTime: TimeInterval = 0
    @State private var showResultOverlay = false
    @State private var previousPathCount = 1
    @State private var previousTarget = 2

    private let audioManager = AudioManager.shared
    private let challengeManager = ChallengeManager.shared
    private var settings: SettingsManager { SettingsManager.shared }

    private var accentColor: Color { settings.accentColor.color }

    init(mode: ChallengeMode) {
        self.mode = mode
        let level = LevelGenerator.generateLevel(difficulty: .medium, gridSize: .classic)
        self._gameState = State(initialValue: GameState(level: level))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text(mode.name)
                            .font(.headline)

                        if mode == .timeAttack {
                            Text("Puzzles: \(puzzlesCompleted)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if mode == .speedRun {
                            Text("Puzzle \(puzzlesCompleted + 1) of 5")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if mode == .noUndo || mode == .zen {
                            Text("Completed: \(puzzlesCompleted)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button(action: generateNewPuzzle) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                    }
                }
                .padding(.horizontal, 16)

                timerDisplay

                Spacer()

                GridView(
                    gameState: gameState,
                    onInvalidMove: triggerInvalidMoveHaptic
                )
                .padding(.horizontal, 16)

                Spacer()

                if mode != .noUndo {
                    Button(action: { gameState.undo() }) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Undo")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(accentColor)
                        .cornerRadius(10)
                    }
                    .disabled(gameState.path.count <= 1)
                    .opacity(gameState.path.count <= 1 ? 0.5 : 1.0)
                }
            }
            .padding(.vertical, 16)

            if showResultOverlay {
                ChallengeResultOverlay(
                    mode: mode,
                    puzzlesCompleted: puzzlesCompleted,
                    totalTime: mode == .speedRun ? totalSpeedRunTime : elapsedTime,
                    onDismiss: { dismiss() }
                )
            }
        }
        .onAppear {
            startChallenge()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: gameState.isComplete) { _, isComplete in
            if isComplete {
                handlePuzzleComplete()
            }
        }
        .onChange(of: gameState.path.count) { oldCount, newCount in
            if newCount > oldCount && newCount > previousPathCount {
                audioManager.playPopSound()
            }
            previousPathCount = newCount
        }
        .onChange(of: gameState.currentTarget) { oldTarget, newTarget in
            if newTarget > oldTarget && newTarget > previousTarget {
                audioManager.playNodeSound()
            }
            previousTarget = newTarget
        }
    }

    @ViewBuilder
    private var timerDisplay: some View {
        switch mode {
        case .timeAttack:
            VStack(spacing: 4) {
                Text(formatTime(remainingTime))
                    .font(.system(size: 48, weight: .semibold, design: .monospaced))
                    .foregroundColor(remainingTime <= 10 ? .red : accentColor)
                Text("remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        case .speedRun:
            VStack(spacing: 4) {
                Text(formatTime(elapsedTime))
                    .font(.system(size: 48, weight: .semibold, design: .monospaced))
                    .foregroundColor(accentColor)
                if !speedRunTimes.isEmpty {
                    Text("Total: \(formatTime(totalSpeedRunTime + elapsedTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        case .noUndo:
            VStack(spacing: 4) {
                Text(formatTime(elapsedTime))
                    .font(.system(size: 48, weight: .semibold, design: .monospaced))
                    .foregroundColor(accentColor)
            }
        case .zen:
            VStack(spacing: 4) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
                Text("Take your time")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        if time < 60 {
            return String(format: "%.1f", time)
        } else {
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private func startChallenge() {
        puzzlesCompleted = 0
        speedRunTimes = []
        totalSpeedRunTime = 0
        elapsedTime = 0
        remainingTime = 60
        previousPathCount = 1
        previousTarget = 2

        if mode == .timeAttack {
            startCountdownTimer()
        } else if mode == .speedRun || mode == .noUndo {
            startElapsedTimer()
        }
    }

    private func startCountdownTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled && remainingTime > 0 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                remainingTime -= 0.1
                if remainingTime <= 0 {
                    endChallenge()
                }
            }
        }
    }

    private func startElapsedTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            let start = Date()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func generateNewPuzzle() {
        elapsedTime = 0
        previousPathCount = 1
        previousTarget = 2
        let newLevel = LevelGenerator.generateLevel(difficulty: .medium, gridSize: .classic)
        gameState = GameState(level: newLevel)

        if mode == .speedRun || mode == .noUndo {
            startElapsedTimer()
        }
    }

    private func handlePuzzleComplete() {
        puzzlesCompleted += 1
        triggerSuccessHaptic()
        audioManager.playNodeSound()

        switch mode {
        case .timeAttack:
            generateNewPuzzle()
        case .noUndo:
            generateNewPuzzle()
        case .speedRun:
            speedRunTimes.append(elapsedTime)
            totalSpeedRunTime += elapsedTime
            if puzzlesCompleted >= 5 {
                endChallenge()
            } else {
                generateNewPuzzle()
            }
        case .zen:
            generateNewPuzzle()
        }
    }

    private func endChallenge() {
        stopTimer()

        let score: ChallengeScore
        switch mode {
        case .timeAttack:
            score = ChallengeScore(mode: mode, score: puzzlesCompleted)
        case .noUndo:
            score = ChallengeScore(mode: mode, score: puzzlesCompleted)
        case .speedRun:
            score = ChallengeScore(mode: mode, score: puzzlesCompleted, timeValue: totalSpeedRunTime)
        case .zen:
            score = ChallengeScore(mode: mode, score: puzzlesCompleted)
        }

        challengeManager.recordScore(score)
        showResultOverlay = true
    }

    private func triggerInvalidMoveHaptic() {
        guard settings.hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    private func triggerSuccessHaptic() {
        guard settings.hapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}

struct ChallengeResultOverlay: View {
    let mode: ChallengeMode
    let puzzlesCompleted: Int
    let totalTime: TimeInterval
    let onDismiss: () -> Void

    @State private var showContent = false

    private var accentColor: Color { SettingsManager.shared.accentColor.color }
    private var highScore: ChallengeScore? { ChallengeManager.shared.highScore(for: mode) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            if showContent {
                VStack(spacing: 24) {
                    Text("Challenge Complete!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    VStack(spacing: 8) {
                        Text(mode.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if mode == .speedRun {
                            Text(formatTime(totalTime))
                                .font(.system(size: 40, weight: .semibold, design: .monospaced))
                                .foregroundColor(accentColor)
                            Text("for 5 puzzles")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(puzzlesCompleted)")
                                .font(.system(size: 48, weight: .semibold, design: .monospaced))
                                .foregroundColor(accentColor)
                            Text(mode.scoreLabel)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let high = highScore {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("Best: \(high.formattedScore)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: onDismiss) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(accentColor)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 20)
                )
                .padding(.horizontal, 40)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                showContent = true
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        if time < 60 {
            return String(format: "%.1fs", time)
        } else {
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    ChallengeGameView(mode: .timeAttack)
}
