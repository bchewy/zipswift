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
            let value: String
            switch defaultDifficulty {
            case .easy: value = "easy"
            case .medium: value = "medium"
            case .hard: value = "hard"
            }
            defaults.set(value, forKey: defaultDifficultyKey)
        }
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
        if let diffString = defaults.string(forKey: defaultDifficultyKey) {
            switch diffString {
            case "easy": self.defaultDifficulty = .easy
            case "hard": self.defaultDifficulty = .hard
            default: self.defaultDifficulty = .medium
            }
        } else {
            self.defaultDifficulty = .medium
        }
    }

    // MARK: - Reset

    func resetToDefaults() {
        soundEnabled = true
        hapticsEnabled = true
        accentColor = .blue
        showBestTime = true
        defaultDifficulty = .medium
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
