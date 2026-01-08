//
//  Achievement.swift
//  zipswift
//
//  Defines achievement structure and available achievements.
//

import Foundation

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let icon: String
    var isUnlocked: Bool
    var unlockedDate: Date?

    init(id: String, name: String, description: String, icon: String, isUnlocked: Bool = false, unlockedDate: Date? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
    }

    var unlockHint: String {
        switch id {
        case "first_win": return "Complete your first puzzle"
        case "games_10": return "Complete 10 puzzles"
        case "games_50": return "Complete 50 puzzles"
        case "games_100": return "Complete 100 puzzles"
        case "speed_demon": return "Complete a puzzle in under 30 seconds"
        case "perfectionist": return "Complete a puzzle without using undo"
        case "streak_3": return "Maintain a 3-day daily challenge streak"
        case "streak_7": return "Maintain a 7-day daily challenge streak"
        case "streak_30": return "Maintain a 30-day daily challenge streak"
        case "hard_mode_master": return "Complete 10 hard puzzles"
        case "daily_warrior": return "Complete 7 daily challenges"
        case "completionist": return "Complete puzzles on all difficulties"
        case "night_owl": return "Complete a puzzle after 10 PM"
        case "early_bird": return "Complete a puzzle before 7 AM"
        case "marathon": return "Complete 5 puzzles in one session"
        default: return "Keep playing to unlock"
        }
    }
}

enum AchievementDefinitions {
    static let all: [Achievement] = [
        Achievement(id: "first_win", name: "First Steps", description: "Complete your first puzzle", icon: "star.fill"),
        Achievement(id: "games_10", name: "Getting Started", description: "Complete 10 puzzles", icon: "10.circle.fill"),
        Achievement(id: "games_50", name: "Dedicated Player", description: "Complete 50 puzzles", icon: "50.circle.fill"),
        Achievement(id: "games_100", name: "Century Club", description: "Complete 100 puzzles", icon: "100.circle.fill"),
        Achievement(id: "speed_demon", name: "Speed Demon", description: "Complete in under 30s", icon: "bolt.fill"),
        Achievement(id: "perfectionist", name: "Perfectionist", description: "Complete without undo", icon: "checkmark.seal.fill"),
        Achievement(id: "streak_3", name: "On a Roll", description: "3-day streak", icon: "flame"),
        Achievement(id: "streak_7", name: "Week Warrior", description: "7-day streak", icon: "flame.fill"),
        Achievement(id: "streak_30", name: "Monthly Master", description: "30-day streak", icon: "flame.circle.fill"),
        Achievement(id: "hard_mode_master", name: "Hard Mode Master", description: "Complete 10 hard puzzles", icon: "crown.fill"),
        Achievement(id: "daily_warrior", name: "Daily Warrior", description: "Complete 7 daily challenges", icon: "calendar.badge.checkmark"),
        Achievement(id: "completionist", name: "Completionist", description: "Play all difficulties", icon: "checkmark.circle.fill"),
        Achievement(id: "night_owl", name: "Night Owl", description: "Play after 10 PM", icon: "moon.fill"),
        Achievement(id: "early_bird", name: "Early Bird", description: "Play before 7 AM", icon: "sunrise.fill"),
        Achievement(id: "marathon", name: "Marathon Runner", description: "5 games in one session", icon: "figure.run")
    ]
}
