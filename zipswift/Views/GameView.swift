//
//  GameView.swift
//  zipswift
//
//  Main game screen with timer, grid, undo button, and how-to-play panel.
//

import SwiftUI
import UIKit

struct GameView: View {
    @State private var gameState: GameState
    @State private var elapsedTime: TimeInterval = 0
    @State private var timerTask: Task<Void, Never>?
    @State private var showWinOverlay = false
    @State private var finalTime: TimeInterval = 0
    @State private var currentDifficulty: Difficulty
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showDailyChallenge = false
    @State private var previousPathCount = 1
    @State private var previousTarget = 2

    @Environment(\.scenePhase) private var scenePhase

    private let historyManager = GameHistoryManager.shared
    private let audioManager = AudioManager.shared
    private var settings: SettingsManager { SettingsManager.shared }

    init() {
        // Use default difficulty from settings
        let defaultDiff = SettingsManager.shared.defaultDifficulty
        self._currentDifficulty = State(initialValue: defaultDiff)
        let level = LevelGenerator.generateLevel(difficulty: defaultDiff)
        self._gameState = State(initialValue: GameState(level: level))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                // Header with timer and buttons
                HStack {
                    // History button
                    Button(action: { showHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                    }

                    // Settings button
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.title3)
                    }

                    // Daily Challenge button
                    Button(action: { showDailyChallenge = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.title3)
                            if settings.dailyStreak > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "flame.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    Text("\(settings.dailyStreak)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }

                    Spacer()

                    // Difficulty picker
                    Menu {
                        Button(action: { changeDifficulty(to: .easy) }) {
                            Label {
                                Text("Easy")
                            } icon: {
                                Image("DifficultyEasy")
                            }
                        }
                        Button(action: { changeDifficulty(to: .medium) }) {
                            Label {
                                Text("Medium")
                            } icon: {
                                Image("DifficultyMedium")
                            }
                        }
                        Button(action: { changeDifficulty(to: .hard) }) {
                            Label {
                                Text("Hard")
                            } icon: {
                                Image("DifficultyHard")
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(currentDifficulty.iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text(difficultyLabel)
                                .font(.subheadline)
                        }
                    }

                    Spacer()

                    // New game button
                    Button(action: generateNewGame) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text("New")
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Timer display
                TimerView(elapsedTime: elapsedTime)

                // Best time indicator
                if settings.showBestTime, let bestTime = historyManager.bestTime(for: currentDifficulty) {
                    Text("Best: \(formatTime(bestTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Game grid
                GridView(
                    gameState: gameState,
                    onInvalidMove: triggerInvalidMoveHaptic
                )
                .padding(.horizontal, 16)

                Spacer()

                // Undo button
                Button(action: {
                    gameState.undo()
                }) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Undo")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(settings.accentColor.color)
                    .cornerRadius(10)
                }
                .disabled(gameState.path.count <= 1)
                .opacity(gameState.path.count <= 1 ? 0.5 : 1.0)

                // How to play panel
                BottomPanelView()
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)

            // Win overlay
            if showWinOverlay {
                WinOverlayView(
                    elapsedTime: finalTime,
                    onPlayAgain: generateNewGame
                )
            }
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $showDailyChallenge) {
            DailyChallengeView()
        }
        .tint(settings.accentColor.color)
        .onChange(of: gameState.isComplete) { _, isComplete in
            if isComplete {
                handleWin()
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
        .onChange(of: gameState.timerStart) { _, newValue in
            if newValue != nil {
                startTimer()
            }
        }
        .onChange(of: gameState.path.count) { oldCount, newCount in
            // Play pop sound when adding cells (not when undoing)
            if newCount > oldCount && newCount > previousPathCount {
                audioManager.playPopSound()
            }
            previousPathCount = newCount
        }
        .onChange(of: gameState.currentTarget) { oldTarget, newTarget in
            // Play node sound when reaching a new numbered node (not when undoing)
            if newTarget > oldTarget && newTarget > previousTarget {
                audioManager.playNodeSound()
            }
            previousTarget = newTarget
        }
    }

    private var difficultyLabel: String {
        switch currentDifficulty {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
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

    // MARK: - Game Management

    private func changeDifficulty(to difficulty: Difficulty) {
        currentDifficulty = difficulty
        generateNewGame()
    }

    private func generateNewGame() {
        withAnimation {
            showWinOverlay = false
        }
        stopTimer()

        let newLevel = LevelGenerator.generateLevel(difficulty: currentDifficulty)
        gameState = GameState(level: newLevel)
        elapsedTime = 0
        finalTime = 0
        previousPathCount = 1
        previousTarget = 2
    }

    // MARK: - Timer Management

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                if let start = gameState.timerStart {
                    elapsedTime = Date().timeIntervalSince(start)
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            stopTimer()
        case .active:
            if gameState.timerStart != nil && !gameState.isComplete {
                startTimer()
            }
        default:
            break
        }
    }

    // MARK: - Win Handling

    private func handleWin() {
        stopTimer()
        finalTime = elapsedTime
        triggerSuccessHaptic()
        audioManager.playCompletionSound()

        // Save game to history
        let record = GameRecord(
            completionDate: Date(),
            elapsedTime: finalTime,
            difficulty: currentDifficulty,
            gridSize: gameState.level.size
        )
        historyManager.save(record)

        withAnimation {
            showWinOverlay = true
        }
    }

    // MARK: - Haptic Feedback

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

// MARK: - Timer View

struct TimerView: View {
    let elapsedTime: TimeInterval

    var body: some View {
        Text(formattedTime)
            .font(.system(size: 32, weight: .medium, design: .monospaced))
            .foregroundColor(.primary)
    }

    private var formattedTime: String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    GameView()
}
