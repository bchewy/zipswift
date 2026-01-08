//
//  SettingsManager.swift
//  zipswift
//
//  Manages user preferences with persistence via UserDefaults.
//

import SwiftUI

enum AccentColorOption: String, CaseIterable, Codable {
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"
    case orange = "orange"
    case green = "green"
    case red = "red"
    case teal = "teal"
    case indigo = "indigo"

    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .orange: return .orange
        case .green: return .green
        case .red: return .red
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

@Observable
class SettingsManager {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    // Keys
    private let soundEnabledKey = "settings_sound_enabled"
    private let hapticsEnabledKey = "settings_haptics_enabled"
    private let accentColorKey = "settings_accent_color"
    private let showBestTimeKey = "settings_show_best_time"
    private let defaultDifficultyKey = "settings_default_difficulty"
    private let defaultGridSizeKey = "settings_default_grid_size"
    private let dailyStreakKey = "settings_daily_streak"
    private let lastDailyDateKey = "settings_last_daily_date"
    private let dailyBestTimesKey = "settings_daily_best_times"

    // MARK: - Sound Settings

    var soundEnabled: Bool {
        didSet {
            defaults.set(soundEnabled, forKey: soundEnabledKey)
        }
    }

    // MARK: - Haptics Settings

    var hapticsEnabled: Bool {
        didSet {
            defaults.set(hapticsEnabled, forKey: hapticsEnabledKey)
        }
    }

    // MARK: - Accent Color

    var accentColor: AccentColorOption {
        didSet {
            defaults.set(accentColor.rawValue, forKey: accentColorKey)
        }
    }

    // MARK: - Gameplay Settings

    var showBestTime: Bool {
        didSet {
            defaults.set(showBestTime, forKey: showBestTimeKey)
        }
    }

    var defaultDifficulty: Difficulty {
        didSet {
            defaults.set(defaultDifficulty.rawValue, forKey: defaultDifficultyKey)
        }
    }

    var defaultGridSize: GridSize {
        didSet {
            defaults.set(defaultGridSize.rawValue, forKey: defaultGridSizeKey)
        }
    }

    // MARK: - Daily Challenge Settings

    var dailyStreak: Int {
        didSet {
            defaults.set(dailyStreak, forKey: dailyStreakKey)
        }
    }

    var lastDailyDate: Date? {
        didSet {
            defaults.set(lastDailyDate, forKey: lastDailyDateKey)
        }
    }

    private(set) var dailyBestTimes: [String: TimeInterval] {
        didSet {
            if let data = try? JSONEncoder().encode(dailyBestTimes) {
                defaults.set(data, forKey: dailyBestTimesKey)
            }
        }
    }

    func recordDailyCompletion(dateString: String, time: TimeInterval) {
        let today = Calendar.current.startOfDay(for: Date())

        if let lastDate = lastDailyDate {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            if Calendar.current.isDate(lastDate, inSameDayAs: yesterday) {
                dailyStreak += 1
            } else if !Calendar.current.isDate(lastDate, inSameDayAs: today) {
                dailyStreak = 1
            }
        } else {
            dailyStreak = 1
        }

        lastDailyDate = today

        if let existingBest = dailyBestTimes[dateString] {
            if time < existingBest {
                dailyBestTimes[dateString] = time
            }
        } else {
            dailyBestTimes[dateString] = time
        }
    }

    func dailyBestTime(for dateString: String) -> TimeInterval? {
        dailyBestTimes[dateString]
    }

    func hasDailyCompletedToday() -> Bool {
        guard let lastDate = lastDailyDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }

    // MARK: - Initialization

    private init() {
        // Load saved values or use defaults
        self.soundEnabled = defaults.object(forKey: soundEnabledKey) as? Bool ?? true
        self.hapticsEnabled = defaults.object(forKey: hapticsEnabledKey) as? Bool ?? true
        self.showBestTime = defaults.object(forKey: showBestTimeKey) as? Bool ?? true

        // Load accent color
        if let colorString = defaults.string(forKey: accentColorKey),
           let color = AccentColorOption(rawValue: colorString) {
            self.accentColor = color
        } else {
            self.accentColor = .blue
        }

        // Load default difficulty
        if let diffString = defaults.string(forKey: defaultDifficultyKey),
           let diff = Difficulty(rawValue: diffString) {
            self.defaultDifficulty = diff
        } else {
            self.defaultDifficulty = .medium
        }

        // Load default grid size
        if let sizeInt = defaults.object(forKey: defaultGridSizeKey) as? Int,
           let gridSize = GridSize(rawValue: sizeInt) {
            self.defaultGridSize = gridSize
        } else {
            self.defaultGridSize = .classic
        }

        // Load daily challenge settings
        self.dailyStreak = defaults.integer(forKey: dailyStreakKey)
        self.lastDailyDate = defaults.object(forKey: lastDailyDateKey) as? Date

        if let data = defaults.data(forKey: dailyBestTimesKey),
           let times = try? JSONDecoder().decode([String: TimeInterval].self, from: data) {
            self.dailyBestTimes = times
        } else {
            self.dailyBestTimes = [:]
        }
    }

    // MARK: - Reset

    func resetToDefaults() {
        soundEnabled = true
        hapticsEnabled = true
        accentColor = .blue
        showBestTime = true
        defaultDifficulty = .medium
        defaultGridSize = .classic
    }
}

// MARK: - App Info

struct AppInfo {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static var fullVersion: String {
        "\(version) (\(build))"
    }
}
