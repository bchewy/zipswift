//
//  AchievementManager.swift
//  zipswift
//
//  Manages achievement state, unlocking, and persistence.
//

import Foundation

@Observable
class AchievementManager {
    static let shared = AchievementManager()

    private let defaults = UserDefaults.standard
    private let storageKey = "achievements_data"
    private let sessionGamesKey = "session_games_count"
    private let dailyCompletionsKey = "daily_completions_count"
    private let difficultiesPlayedKey = "difficulties_played"
    private let hardGamesCountKey = "hard_games_count"

    private(set) var achievements: [Achievement] = []
    private(set) var recentlyUnlocked: Achievement?
    private(set) var sessionGamesCount: Int = 0

    private var difficultiesPlayed: Set<String> = []
    private var hardGamesCount: Int = 0
    private var dailyCompletionsCount: Int = 0

    private init() {
        loadAchievements()
        loadStats()
    }

    func checkAchievements(
        elapsedTime: TimeInterval,
        undoUsed: Bool,
        difficulty: Difficulty,
        isDaily: Bool,
        dailyStreak: Int,
        totalGames: Int
    ) {
        sessionGamesCount += 1
        saveSessionGames()

        if difficulty == .hard {
            hardGamesCount += 1
            saveHardGamesCount()
        }

        difficultiesPlayed.insert(difficultyString(difficulty))
        saveDifficultiesPlayed()

        if isDaily {
            dailyCompletionsCount += 1
            saveDailyCompletions()
        }

        var newlyUnlocked: [Achievement] = []

        if !isUnlocked("first_win") && totalGames >= 1 {
            if let achievement = unlock("first_win") {
                newlyUnlocked.append(achievement)
            }
        }

        if !isUnlocked("games_10") && totalGames >= 10 {
            if let achievement = unlock("games_10") {
                newlyUnlocked.append(achievement)
            }
        }

        if !isUnlocked("games_50") && totalGames >= 50 {
            if let achievement = unlock("games_50") {
                newlyUnlocked.append(achievement)
            }
        }

        if !isUnlocked("games_100") && totalGames >= 100 {
            if let achievement = unlock("games_100") {
                newlyUnlocked.append(achievement)
            }
        }

        if !isUnlocked("speed_demon") && elapsedTime < 30 {
            if let achievement = unlock("speed_demon") {
                newlyUnlocked.append(achievement)
            }
        }

        if !isUnlocked("perfectionist") && !undoUsed {
            if let achievement = unlock("perfectionist") {
                newlyUnlocked.append(achievement)
            }
        }

        if !isUnlocked("streak_3") && dailyStreak >= 3 {
            if let achievement = unlock("streak_3") {
                newlyUnlocked.append(achievement)
            }
        }

        if !isUnlocked("streak_7") && dailyStreak >= 7 {
            if let achievement = unlock("streak_7") {
                newlyUnlocked.append(achievement)
            }
        }

        if !isUnlocked("streak_30") && dailyStreak >= 30 {
            if let achievement = unlock("streak_30") {
                newlyUnlocked.append(achievement)
            }
        }

        if !isUnlocked("hard_mode_master") && hardGamesCount >= 10 {
            if let achievement = unlock("hard_mode_master") {
                newlyUnlocked.append(achievement)
            }
        }

        if !isUnlocked("daily_warrior") && dailyCompletionsCount >= 7 {
            if let achievement = unlock("daily_warrior") {
                newlyUnlocked.append(achievement)
            }
        }

        if !isUnlocked("completionist") && difficultiesPlayed.count >= 3 {
            if let achievement = unlock("completionist") {
                newlyUnlocked.append(achievement)
            }
        }

        let hour = Calendar.current.component(.hour, from: Date())
        if !isUnlocked("night_owl") && hour >= 22 {
            if let achievement = unlock("night_owl") {
                newlyUnlocked.append(achievement)
            }
        }

        if !isUnlocked("early_bird") && hour < 7 {
            if let achievement = unlock("early_bird") {
                newlyUnlocked.append(achievement)
            }
        }

        if !isUnlocked("marathon") && sessionGamesCount >= 5 {
            if let achievement = unlock("marathon") {
                newlyUnlocked.append(achievement)
            }
        }

        recentlyUnlocked = newlyUnlocked.first
    }

    func clearRecentlyUnlocked() {
        recentlyUnlocked = nil
    }

    func resetSessionCount() {
        sessionGamesCount = 0
        saveSessionGames()
    }

    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    var totalCount: Int {
        achievements.count
    }

    private func isUnlocked(_ id: String) -> Bool {
        achievements.first { $0.id == id }?.isUnlocked ?? false
    }

    private func unlock(_ id: String) -> Achievement? {
        guard let index = achievements.firstIndex(where: { $0.id == id }) else { return nil }
        guard !achievements[index].isUnlocked else { return nil }

        achievements[index].isUnlocked = true
        achievements[index].unlockedDate = Date()
        saveAchievements()

        return achievements[index]
    }

    private func difficultyString(_ difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy: return "easy"
        case .medium: return "medium"
        case .hard: return "hard"
        }
    }

    private func loadAchievements() {
        if let data = defaults.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([Achievement].self, from: data) {
            var merged: [Achievement] = []
            for definition in AchievementDefinitions.all {
                if let existing = saved.first(where: { $0.id == definition.id }) {
                    merged.append(existing)
                } else {
                    merged.append(definition)
                }
            }
            achievements = merged
        } else {
            achievements = AchievementDefinitions.all
        }
    }

    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private func loadStats() {
        sessionGamesCount = defaults.integer(forKey: sessionGamesKey)
        hardGamesCount = defaults.integer(forKey: hardGamesCountKey)
        dailyCompletionsCount = defaults.integer(forKey: dailyCompletionsKey)

        if let data = defaults.data(forKey: difficultiesPlayedKey),
           let saved = try? JSONDecoder().decode(Set<String>.self, from: data) {
            difficultiesPlayed = saved
        }
    }

    private func saveSessionGames() {
        defaults.set(sessionGamesCount, forKey: sessionGamesKey)
    }

    private func saveHardGamesCount() {
        defaults.set(hardGamesCount, forKey: hardGamesCountKey)
    }

    private func saveDailyCompletions() {
        defaults.set(dailyCompletionsCount, forKey: dailyCompletionsKey)
    }

    private func saveDifficultiesPlayed() {
        if let data = try? JSONEncoder().encode(difficultiesPlayed) {
            defaults.set(data, forKey: difficultiesPlayedKey)
        }
    }
}
