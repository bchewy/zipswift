//
//  LevelProgressManager.swift
//  zipswift
//
//  Tracks completion and star ratings for level pack levels.
//

import Foundation

@Observable
class LevelProgressManager {
    static let shared = LevelProgressManager()

    private let defaults = UserDefaults.standard
    private let progressKey = "level_pack_progress"

    private(set) var progress: [String: LevelProgress] = [:]

    private init() {
        loadProgress()
    }

    func levelProgress(packId: String, levelIndex: Int) -> LevelProgress? {
        progress[progressKey(packId: packId, levelIndex: levelIndex)]
    }

    func isLevelCompleted(packId: String, levelIndex: Int) -> Bool {
        levelProgress(packId: packId, levelIndex: levelIndex)?.completed ?? false
    }

    func starsForLevel(packId: String, levelIndex: Int) -> Int {
        levelProgress(packId: packId, levelIndex: levelIndex)?.bestStars ?? 0
    }

    func recordCompletion(packId: String, levelIndex: Int, time: TimeInterval, stars: Int) {
        let key = progressKey(packId: packId, levelIndex: levelIndex)
        let existing = progress[key]

        if let existing = existing {
            if stars > existing.bestStars || (stars == existing.bestStars && time < existing.bestTime) {
                progress[key] = LevelProgress(
                    completed: true,
                    bestTime: min(time, existing.bestTime),
                    bestStars: max(stars, existing.bestStars)
                )
            }
        } else {
            progress[key] = LevelProgress(completed: true, bestTime: time, bestStars: stars)
        }

        saveProgress()
    }

    func starsForPack(_ packId: String) -> Int {
        guard let pack = LevelPacks.all.first(where: { $0.id == packId }) else { return 0 }
        var total = 0
        for i in 0..<pack.levelCount {
            total += starsForLevel(packId: packId, levelIndex: i)
        }
        return total
    }

    func completedLevelsInPack(_ packId: String) -> Int {
        guard let pack = LevelPacks.all.first(where: { $0.id == packId }) else { return 0 }
        var count = 0
        for i in 0..<pack.levelCount {
            if isLevelCompleted(packId: packId, levelIndex: i) {
                count += 1
            }
        }
        return count
    }

    var totalPackStars: Int {
        var total = 0
        for pack in LevelPacks.all {
            total += starsForPack(pack.id)
        }
        return total
    }

    func isPackUnlocked(_ pack: LevelPack) -> Bool {
        totalPackStars >= pack.requiredStars
    }

    private func progressKey(packId: String, levelIndex: Int) -> String {
        "\(packId)_level_\(levelIndex)"
    }

    private func loadProgress() {
        guard let data = defaults.data(forKey: progressKey),
              let decoded = try? JSONDecoder().decode([String: LevelProgress].self, from: data) else {
            return
        }
        progress = decoded
    }

    private func saveProgress() {
        if let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: progressKey)
        }
    }
}

struct LevelProgress: Codable {
    let completed: Bool
    let bestTime: TimeInterval
    let bestStars: Int
}
