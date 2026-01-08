//
//  DailyChallengeView.swift
//  zipswift
//
//  Daily challenge view with special styling and streak display.
//

import SwiftUI
import UIKit

struct DailyChallengeView: View {
    @State private var gameState: GameState
    @State private var elapsedTime: TimeInterval = 0
    @State private var timerTask: Task<Void, Never>?
    @State private var showWinOverlay = false
    @State private var finalTime: TimeInterval = 0
    @State private var previousPathCount = 1
    @State private var previousTarget = 2
    @State private var countdownText = ""
    @State private var countdownTimer: Task<Void, Never>?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    private let dailyChallenge: DailyChallenge
    private let audioManager = AudioManager.shared
    private var settings: SettingsManager { SettingsManager.shared }

    init() {
        let challenge = DailyChallenge()
        self.dailyChallenge = challenge
        self._gameState = State(initialValue: GameState(level: challenge.level))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 20) {
                    HStack {
                        if settings.dailyStreak > 0 {
                            Label("\(settings.dailyStreak)", systemImage: "flame.fill")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Next puzzle in")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(countdownText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                    }
                    .padding(.horizontal, 16)

                    if settings.hasDailyCompletedToday() {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Daily Complete")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(20)
                    }

                    TimerView(elapsedTime: elapsedTime)

                    if let bestTime = settings.dailyBestTime(for: dailyChallenge.dateString) {
                        Text("Today's Best: \(formatTime(bestTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(settings.accentColor.color, lineWidth: 3)
                            .padding(.horizontal, 12)

                        GridView(
                            gameState: gameState,
                            onInvalidMove: triggerInvalidMoveHaptic
                        )
                        .padding(.horizontal, 16)
                    }

                    Spacer()

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

                    Text("Daily Challenge")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
                .padding(.vertical, 16)

                if showWinOverlay {
                    DailyWinOverlayView(
                        elapsedTime: finalTime,
                        streak: settings.dailyStreak,
                        onDismiss: { dismiss() }
                    )
                }
            }
            .navigationTitle("Daily Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: resetGame) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
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
            .onAppear {
                startCountdownTimer()
            }
            .onDisappear {
                stopTimer()
                countdownTimer?.cancel()
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

    private func resetGame() {
        stopTimer()
        gameState.reset()
        elapsedTime = 0
        finalTime = 0
        previousPathCount = 1
        previousTarget = 2
        withAnimation {
            showWinOverlay = false
        }
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                if let start = gameState.timerStart {
                    elapsedTime = Date().timeIntervalSince(start)
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func startCountdownTimer() {
        countdownText = dailyChallenge.formattedCountdown
        countdownTimer = Task { @MainActor in
            while !Task.isCancelled {
                countdownText = dailyChallenge.formattedCountdown
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
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

    private func handleWin() {
        stopTimer()
        finalTime = elapsedTime
        triggerSuccessHaptic()
        audioManager.playDailyCompletionSound()

        settings.recordDailyCompletion(
            dateString: dailyChallenge.dateString,
            time: finalTime
        )

        // Submit to Game Center
        GameCenterManager.shared.submitDailyTime(finalTime)

        withAnimation {
            showWinOverlay = true
        }
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

struct DailyWinOverlayView: View {
    let elapsedTime: TimeInterval
    let streak: Int
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var confettiTrigger = false
    @State private var showShareSheet = false

    private var settings: SettingsManager { SettingsManager.shared }

    private var accentColor: Color {
        settings.accentColor.color
    }

    private var starCount: Int {
        StarRating.stars(for: elapsedTime, difficulty: .medium)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                ConfettiView(
                    trigger: confettiTrigger,
                    screenSize: geometry.size
                )
                .ignoresSafeArea()

                if showContent {
                    VStack(spacing: 24) {
                        Text("Daily Complete!")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        if streak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("\(streak) day streak!")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }
                        }

                        Text(formattedTime)
                            .font(.system(size: 48, weight: .semibold, design: .monospaced))
                            .foregroundColor(accentColor)

                        StarRatingView(stars: starCount, animated: true, size: 32)

                        HStack(spacing: 12) {
                            Button(action: shareResult) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
                                }
                                .font(.headline)
                                .foregroundColor(accentColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(accentColor, lineWidth: 2)
                                )
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
        }
        .onAppear {
            confettiTrigger = true
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                showContent = true
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
    }

    private var formattedTime: String {
        if elapsedTime < 60 {
            return String(format: "%.1fs", elapsedTime)
        } else {
            let minutes = Int(elapsedTime) / 60
            let seconds = Int(elapsedTime) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private var shareItems: [Any] {
        var items: [Any] = []

        let text = ShareHelper.generateShareText(
            elapsedTime: elapsedTime,
            difficulty: .medium,
            stars: starCount,
            isDaily: true,
            dailyStreak: streak
        )
        items.append(text)

        if let image = ShareHelper.generateShareImage(
            elapsedTime: elapsedTime,
            difficulty: .medium,
            stars: starCount,
            isDaily: true,
            dailyStreak: streak
        ) {
            items.append(image)
        }

        return items
    }

    private func shareResult() {
        triggerHaptic()
        showShareSheet = true
    }

    private func triggerHaptic() {
        guard settings.hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
}

#Preview {
    DailyChallengeView()
}
