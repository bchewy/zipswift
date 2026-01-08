//
//  WidgetDataManager.swift
//  zipswift
//
//  Manages shared data between the app and widget using App Groups.
//

import Foundation
import WidgetKit

struct WidgetSharedData: Codable {
    var dailyStreak: Int
    var todayBestTime: TimeInterval?
    var hasCompletedToday: Bool
    var lastUpdate: Date
    var accentColorName: String

    static var empty: WidgetSharedData {
        WidgetSharedData(
            dailyStreak: 0,
            todayBestTime: nil,
            hasCompletedToday: false,
            lastUpdate: Date(),
            accentColorName: "blue"
        )
    }
}

@Observable
class WidgetDataManager {
    static let shared = WidgetDataManager()

    private let appGroupIdentifier = "group.com.zipswift.shared"
    private let dataKey = "widget_shared_data"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    func updateWidgetData() {
        let settings = SettingsManager.shared

        let data = WidgetSharedData(
            dailyStreak: settings.dailyStreak,
            todayBestTime: settings.todayBestTime,
            hasCompletedToday: settings.hasDailyCompletedToday(),
            lastUpdate: Date(),
            accentColorName: settings.accentColor.rawValue
        )

        saveData(data)
        reloadWidgets()
    }

    func loadData() -> WidgetSharedData {
        guard let defaults = sharedDefaults,
              let jsonData = defaults.data(forKey: dataKey),
              let data = try? JSONDecoder().decode(WidgetSharedData.self, from: jsonData) else {
            return .empty
        }
        return data
    }

    private func saveData(_ data: WidgetSharedData) {
        guard let defaults = sharedDefaults,
              let jsonData = try? JSONEncoder().encode(data) else {
            return
        }
        defaults.set(jsonData, forKey: dataKey)
    }

    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

extension SettingsManager {
    var todayBestTime: TimeInterval? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())
        return dailyBestTimes[todayString]
    }
}
