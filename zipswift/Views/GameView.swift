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
    @State private var currentGridSize: GridSize
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showDailyChallenge = false
    @State private var showAchievements = false
    @State private var showAchievementToast = false
    @State private var showLevelPacks = false
    @State private var showChallengeModes = false
    @State private var showLeaderboards = false
    @State private var activeChallengeMode: ChallengeMode?
    @State private var previousPathCount = 1
    @State private var previousTarget = 2
    @State private var undoUsedThisGame = false
    @State private var hintsUsedThisGame = 0
    @State private var showingHint = false
    @State private var hintCells: [GridPoint] = []
    @State private var currentPackId: String?
    @State private var currentPackLevelIndex: Int?
    @State private var showRestartConfirmation = false
    @State private var isGridCollapsed = false

    @Environment(\.scenePhase) private var scenePhase

    private let historyManager = GameHistoryManager.shared
    private let audioManager = AudioManager.shared
    private let achievementManager = AchievementManager.shared
    private let levelProgressManager = LevelProgressManager.shared
    private let gameCenterManager = GameCenterManager.shared
    private var settings: SettingsManager { SettingsManager.shared }

    init() {
        let defaultDiff = SettingsManager.shared.defaultDifficulty
        let defaultSize = SettingsManager.shared.defaultGridSize
        self._currentDifficulty = State(initialValue: defaultDiff)
        self._currentGridSize = State(initialValue: defaultSize)
        let level = LevelGenerator.generateLevel(difficulty: defaultDiff, gridSize: defaultSize)
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

                    // Achievements button
                    Button(action: { showAchievements = true }) {
                        Image(systemName: "trophy")
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

                    // Level Packs button
                    Button(action: { showLevelPacks = true }) {
                        Image(systemName: "square.grid.3x3")
                            .font(.title3)
                    }

                    // Challenge Modes button
                    Button(action: { showChallengeModes = true }) {
                        Image(systemName: "bolt.fill")
                            .font(.title3)
                    }

                    // Game Center Leaderboards button
                    if gameCenterManager.isAuthenticated {
                        Button(action: { showLeaderboards = true }) {
                            Image(systemName: "chart.bar.fill")
                                .font(.title3)
                        }
                    }

                    Spacer()

                    // Grid size picker
                    Menu {
                        ForEach(GridSize.allCases, id: \.self) { size in
                            Button(action: { changeGridSize(to: size) }) {
                                Text(size.displayName)
                            }
                        }
                    } label: {
                        Text(currentGridSize.shortName)
                            .font(.subheadline)
                    }

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

                // Pack level indicator
                if let packId = currentPackId,
                   let levelIndex = currentPackLevelIndex,
                   let pack = LevelPacks.all.first(where: { $0.id == packId }) {
                    Text("\(pack.name) - Level \(levelIndex + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Best time indicator
                if currentPackId == nil, settings.showBestTime, let bestTime = historyManager.bestTime(for: currentDifficulty) {
                    Text("Best: \(formatTime(bestTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Game grid with swipe to collapse/expand and double-tap to restart
                if !isGridCollapsed {
                    GridView(
                        gameState: gameState,
                        onInvalidMove: triggerInvalidMoveHaptic,
                        hintCells: hintCells
                    )
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .gesture(
                        DragGesture(minimumDistance: 50)
                            .onEnded { value in
                                if value.translation.height > 50 && abs(value.translation.width) < 50 {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isGridCollapsed = true
                                    }
                                    triggerLightHaptic()
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        showRestartConfirmation = true
                        triggerLightHaptic()
                    }
                } else {
                    CollapsedGridView(
                        difficulty: currentDifficulty,
                        onExpand: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isGridCollapsed = false
                            }
                            triggerLightHaptic()
                        }
                    )
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                // Action buttons
                HStack(spacing: 16) {
                    // Hint button
                    Button(action: activateHint) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                            Text("Hint")
                            if hintsUsedThisGame < 3 {
                                Text("(\(3 - hintsUsedThisGame))")
                                    .font(.caption)
                            }
                        }
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(settings.accentColor.color, lineWidth: 2)
                        )
                    }
                    .disabled(hintsUsedThisGame >= 3 || showingHint)
                    .opacity(hintsUsedThisGame >= 3 ? 0.5 : 1.0)

                    // Undo button with long press for undo all
                    Button(action: {
                        undoUsedThisGame = true
                        gameState.undo()
                        triggerLightHaptic()
                    }) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Undo")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(settings.accentColor.color)
                        .cornerRadius(10)
                    }
                    .disabled(gameState.path.count <= 1)
                    .opacity(gameState.path.count <= 1 ? 0.5 : 1.0)
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                undoAll()
                            }
                    )
                }

                // How to play panel
                BottomPanelView()
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)

            // Win overlay
            if showWinOverlay {
                WinOverlayView(
                    elapsedTime: finalTime,
                    difficulty: currentDifficulty,
                    onPlayAgain: generateNewGame
                )
            }

            // Achievement toast
            if showAchievementToast, let achievement = achievementManager.recentlyUnlocked {
                AchievementToastView(achievement: achievement) {
                    showAchievementToast = false
                    achievementManager.clearRecentlyUnlocked()
                }
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
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
        }
        .sheet(isPresented: $showLevelPacks) {
            LevelPacksView { level, packId, levelIndex in
                loadPackLevel(level: level, packId: packId, levelIndex: levelIndex)
            }
        }
        .sheet(isPresented: $showChallengeModes) {
            ChallengeModeSelectView { mode in
                activeChallengeMode = mode
            }
        }
        .fullScreenCover(item: $activeChallengeMode) { mode in
            ChallengeGameView(mode: mode)
        }
        .sheet(isPresented: $showLeaderboards) {
            GameCenterLeaderboardsView()
        }
        .tint(settings.accentColor.color)
        .alert("Restart Puzzle?", isPresented: $showRestartConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Restart", role: .destructive) {
                generateNewGame()
            }
        } message: {
            Text("Start a new puzzle with the same difficulty?")
        }
        .onShake {
            showRestartConfirmation = true
            triggerLightHaptic()
        }
        .keyboardShortcut("r", modifiers: []) { generateNewGame() }
        .keyboardShortcut("u", modifiers: []) { if gameState.path.count > 1 { undoUsedThisGame = true; gameState.undo() } }
        .keyboardShortcut("n", modifiers: []) { generateNewGame() }
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
        .onReceive(NotificationCenter.default.publisher(for: .openDailyChallenge)) { _ in
            showDailyChallenge = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .startEasyGame)) { _ in
            changeDifficulty(to: .easy)
        }
        .onReceive(NotificationCenter.default.publisher(for: .startHardGame)) { _ in
            changeDifficulty(to: .hard)
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

    private func changeGridSize(to size: GridSize) {
        currentGridSize = size
        generateNewGame()
    }

    private func generateNewGame() {
        withAnimation {
            showWinOverlay = false
        }
        stopTimer()

        currentPackId = nil
        currentPackLevelIndex = nil

        let newLevel = LevelGenerator.generateLevel(difficulty: currentDifficulty, gridSize: currentGridSize)
        gameState = GameState(level: newLevel)
        elapsedTime = 0
        finalTime = 0
        previousPathCount = 1
        previousTarget = 2
        undoUsedThisGame = false
        hintsUsedThisGame = 0
        showingHint = false
        hintCells = []
    }

    private func loadPackLevel(level: LevelDefinition, packId: String, levelIndex: Int) {
        withAnimation {
            showWinOverlay = false
        }
        stopTimer()

        currentPackId = packId
        currentPackLevelIndex = levelIndex

        gameState = GameState(level: level)
        elapsedTime = 0
        finalTime = 0
        previousPathCount = 1
        previousTarget = 2
        undoUsedThisGame = false
        hintsUsedThisGame = 0
        showingHint = false
        hintCells = []
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
        let starCount = StarRating.stars(for: finalTime, difficulty: currentDifficulty, hintsUsed: hintsUsedThisGame)
        triggerSuccessHaptic()
        audioManager.playStarCompletionSound(stars: starCount)

        // Save game to history
        let record = GameRecord(
            completionDate: Date(),
            elapsedTime: finalTime,
            difficulty: currentDifficulty,
            gridSize: gameState.level.size,
            stars: starCount
        )
        historyManager.save(record)

        // Save pack level progress if playing a pack level
        if let packId = currentPackId, let levelIndex = currentPackLevelIndex {
            levelProgressManager.recordCompletion(
                packId: packId,
                levelIndex: levelIndex,
                time: finalTime,
                stars: starCount
            )
        }

        // Check achievements
        achievementManager.checkAchievements(
            elapsedTime: finalTime,
            undoUsed: undoUsedThisGame,
            difficulty: currentDifficulty,
            isDaily: false,
            dailyStreak: settings.dailyStreak,
            totalGames: historyManager.totalGamesCount
        )

        if achievementManager.recentlyUnlocked != nil {
            triggerAchievementHaptic()
            audioManager.playAchievementSound()
            showAchievementToast = true
        }

        // Submit to Game Center
        gameCenterManager.submitTime(finalTime, for: currentDifficulty)
        gameCenterManager.submitTotalStars(historyManager.totalStars)
        gameCenterManager.syncAchievements(from: achievementManager.achievements)

        withAnimation {
            showWinOverlay = true
        }
    }

    // MARK: - Hint System

    private func activateHint() {
        guard hintsUsedThisGame < 3 && !showingHint else { return }

        hintsUsedThisGame += 1
        hintCells = gameState.getHintCells(count: 3)
        showingHint = true
        triggerHintHaptic()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                self.hintCells = []
                self.showingHint = false
            }
        }
    }

    // MARK: - Quick Actions

    private func undoAll() {
        guard gameState.path.count > 1 else { return }
        undoUsedThisGame = true
        gameState.reset()
        triggerMediumHaptic()
    }

    // MARK: - Haptic Feedback

    private func triggerLightHaptic() {
        guard settings.hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    private func triggerMediumHaptic() {
        guard settings.hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    private func triggerHintHaptic() {
        guard settings.hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
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

    private func triggerAchievementHaptic() {
        guard settings.hapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Timer View

struct TimerView: View {
    let elapsedTime: TimeInterval

    @State private var timerScale: CGFloat = 1.0
    @State private var hasAnimatedStart = false

    private var reduceMotion: Bool {
        SettingsManager.shared.reduceMotion
    }

    var body: some View {
        Text(formattedTime)
            .font(.system(size: 32, weight: .medium, design: .monospaced))
            .foregroundColor(.primary)
            .scaleEffect(timerScale)
            .onChange(of: elapsedTime) { oldTime, newTime in
                if oldTime == 0 && newTime > 0 && !hasAnimatedStart && !reduceMotion {
                    hasAnimatedStart = true
                    animateTimerStart()
                }
            }
    }

    private var formattedTime: String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func animateTimerStart() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            timerScale = 1.15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                timerScale = 1.0
            }
        }
    }
}

// MARK: - Collapsed Grid View

struct CollapsedGridView: View {
    let difficulty: Difficulty
    let onExpand: () -> Void

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chevron.compact.down")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Puzzle minimized")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: onExpand) {
                HStack {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                    Text("Expand")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(accentColor)
                .cornerRadius(10)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.height < -50 && abs(value.translation.width) < 50 {
                        onExpand()
                    }
                }
        )
    }
}

// MARK: - Shake Detection

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

struct ShakeViewModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
                action()
            }
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        modifier(ShakeViewModifier(action: action))
    }
}

// MARK: - Keyboard Shortcuts

struct KeyboardShortcutModifier: ViewModifier {
    let key: KeyEquivalent
    let modifiers: EventModifiers
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .background(
                Button("") { action() }
                    .keyboardShortcut(key, modifiers: modifiers)
                    .opacity(0)
            )
    }
}

extension View {
    func keyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers = [], action: @escaping () -> Void) -> some View {
        modifier(KeyboardShortcutModifier(key: key, modifiers: modifiers, action: action))
    }
}

#Preview {
    GameView()
}
