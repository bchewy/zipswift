//
//  GameCenterManager.swift
//  zipswift
//
//  Handles Game Center authentication, leaderboards, and achievements.
//

import GameKit
import SwiftUI

@Observable
class GameCenterManager: NSObject {
    static let shared = GameCenterManager()

    var isAuthenticated = false
    var showingAccessPoint = false
    var localPlayer: GKLocalPlayer?

    private override init() {
        super.init()
    }

    // MARK: - Leaderboard IDs

    enum LeaderboardID: String, CaseIterable {
        case bestTimeEasy = "com.zipswift.leaderboard.besttime.easy"
        case bestTimeMedium = "com.zipswift.leaderboard.besttime.medium"
        case bestTimeHard = "com.zipswift.leaderboard.besttime.hard"
        case dailyChallenge = "com.zipswift.leaderboard.daily"
        case totalStars = "com.zipswift.leaderboard.totalstars"

        var displayName: String {
            switch self {
            case .bestTimeEasy: return "Best Time (Easy)"
            case .bestTimeMedium: return "Best Time (Medium)"
            case .bestTimeHard: return "Best Time (Hard)"
            case .dailyChallenge: return "Daily Challenge"
            case .totalStars: return "Total Stars"
            }
        }

        static func forDifficulty(_ difficulty: Difficulty) -> LeaderboardID {
            switch difficulty {
            case .easy: return .bestTimeEasy
            case .medium: return .bestTimeMedium
            case .hard: return .bestTimeHard
            }
        }
    }

    // MARK: - Achievement IDs

    enum AchievementID: String, CaseIterable {
        case firstWin = "com.zipswift.achievement.first_win"
        case games10 = "com.zipswift.achievement.games_10"
        case games50 = "com.zipswift.achievement.games_50"
        case games100 = "com.zipswift.achievement.games_100"
        case speedDemon = "com.zipswift.achievement.speed_demon"
        case perfectionist = "com.zipswift.achievement.perfectionist"
        case streak3 = "com.zipswift.achievement.streak_3"
        case streak7 = "com.zipswift.achievement.streak_7"
        case streak30 = "com.zipswift.achievement.streak_30"
        case hardModeMaster = "com.zipswift.achievement.hard_mode_master"
        case dailyWarrior = "com.zipswift.achievement.daily_warrior"
        case completionist = "com.zipswift.achievement.completionist"
        case nightOwl = "com.zipswift.achievement.night_owl"
        case earlyBird = "com.zipswift.achievement.early_bird"
        case marathon = "com.zipswift.achievement.marathon"
    }

    // MARK: - Authentication

    func authenticatePlayer() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self = self else { return }

            if let error = error {
                print("Game Center authentication error: \(error.localizedDescription)")
                self.isAuthenticated = false
                return
            }

            if viewController != nil {
                self.isAuthenticated = false
            } else if GKLocalPlayer.local.isAuthenticated {
                self.isAuthenticated = true
                self.localPlayer = GKLocalPlayer.local
                self.configureAccessPoint()
            } else {
                self.isAuthenticated = false
            }
        }
    }

    private func configureAccessPoint() {
        GKAccessPoint.shared.location = .topLeading
        if #available(iOS 26.0, *) {
            // showHighlights deprecated in iOS 26
        } else {
            GKAccessPoint.shared.showHighlights = true
        }
        showingAccessPoint = true
    }

    func showAccessPoint(_ show: Bool) {
        GKAccessPoint.shared.isActive = show && isAuthenticated
        showingAccessPoint = show && isAuthenticated
    }

    // MARK: - Leaderboards

    func submitScore(_ score: Int, to leaderboard: LeaderboardID) {
        guard isAuthenticated else { return }

        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboard.rawValue]
        ) { error in
            if let error = error {
                print("Failed to submit score: \(error.localizedDescription)")
            }
        }
    }

    func submitTime(_ time: TimeInterval, for difficulty: Difficulty) {
        let centiseconds = Int(time * 100)
        let leaderboard = LeaderboardID.forDifficulty(difficulty)
        submitScore(centiseconds, to: leaderboard)
    }

    func submitDailyTime(_ time: TimeInterval) {
        let centiseconds = Int(time * 100)
        submitScore(centiseconds, to: .dailyChallenge)
    }

    func submitTotalStars(_ stars: Int) {
        submitScore(stars, to: .totalStars)
    }

    // MARK: - Achievements

    func reportAchievement(_ achievementID: AchievementID, percentComplete: Double = 100.0) {
        guard isAuthenticated else { return }

        let achievement = GKAchievement(identifier: achievementID.rawValue)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true

        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("Failed to report achievement: \(error.localizedDescription)")
            }
        }
    }

    func syncAchievements(from localAchievements: [Achievement]) {
        guard isAuthenticated else { return }

        for achievement in localAchievements where achievement.isUnlocked {
            if let gcID = mapToGameCenterAchievement(achievement.id) {
                reportAchievement(gcID)
            }
        }
    }

    private func mapToGameCenterAchievement(_ localID: String) -> AchievementID? {
        switch localID {
        case "first_win": return .firstWin
        case "games_10": return .games10
        case "games_50": return .games50
        case "games_100": return .games100
        case "speed_demon": return .speedDemon
        case "perfectionist": return .perfectionist
        case "streak_3": return .streak3
        case "streak_7": return .streak7
        case "streak_30": return .streak30
        case "hard_mode_master": return .hardModeMaster
        case "daily_warrior": return .dailyWarrior
        case "completionist": return .completionist
        case "night_owl": return .nightOwl
        case "early_bird": return .earlyBird
        case "marathon": return .marathon
        default: return nil
        }
    }

    // MARK: - Present Game Center UI

    @available(iOS, deprecated: 26.0, message: "Use GKAccessPoint for newer APIs when available")
    func presentLeaderboards() {
        guard isAuthenticated else { return }

        let viewController = GKGameCenterViewController(state: .leaderboards)
        viewController.gameCenterDelegate = self

        presentGameCenterViewController(viewController)
    }

    @available(iOS, deprecated: 26.0, message: "Use GKAccessPoint for newer APIs when available")
    func presentAchievements() {
        guard isAuthenticated else { return }

        let viewController = GKGameCenterViewController(state: .achievements)
        viewController.gameCenterDelegate = self

        presentGameCenterViewController(viewController)
    }

    @available(iOS, deprecated: 26.0, message: "Use GKAccessPoint for newer APIs when available")
    func presentDashboard() {
        guard isAuthenticated else { return }

        let viewController = GKGameCenterViewController(state: .dashboard)
        viewController.gameCenterDelegate = self

        presentGameCenterViewController(viewController)
    }

    @available(iOS, deprecated: 26.0, message: "Use GKAccessPoint for newer APIs when available")
    private func presentGameCenterViewController(_ viewController: GKGameCenterViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        var topViewController = rootViewController
        while let presented = topViewController.presentedViewController {
            topViewController = presented
        }

        topViewController.present(viewController, animated: true)
    }
}

// MARK: - GKGameCenterControllerDelegate

@available(iOS, deprecated: 26.0, message: "Use GKAccessPoint for newer APIs when available")
extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}

// MARK: - SwiftUI View for Leaderboards

struct GameCenterLeaderboardsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GameCenterViewControllerRepresentable(onDismiss: { dismiss() })
            .ignoresSafeArea()
    }
}

private struct GameCenterViewControllerRepresentable: UIViewControllerRepresentable {
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> GKGameCenterViewControllerWrapper {
        GKGameCenterViewControllerWrapper(onDismiss: onDismiss)
    }

    func updateUIViewController(_ uiViewController: GKGameCenterViewControllerWrapper, context: Context) {}
}

private class GKGameCenterViewControllerWrapper: UIViewController, GKGameCenterControllerDelegate {
    let onDismiss: () -> Void
    private var gameCenterVC: UIViewController?

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if gameCenterVC == nil {
            presentGameCenter()
        }
    }

    private func presentGameCenter() {
        let gc = GKGameCenterViewController(state: .leaderboards)
        gc.gameCenterDelegate = self
        gameCenterVC = gc
        present(gc, animated: true)
    }

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true) { [weak self] in
            self?.onDismiss()
        }
    }
}
