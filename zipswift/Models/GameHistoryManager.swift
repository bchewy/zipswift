//
//  GameHistoryManager.swift
//  zipswift
//
//  Manages persistence of game history using UserDefaults.
//

import Foundation

@Observable
class GameHistoryManager {
    private let storageKey: String
    private let userDefaults: UserDefaults

    private(set) var records: [GameRecord] = []

    init(storageKey: String = "zipswift_game_history", userDefaults: UserDefaults = .standard) {
        self.storageKey = storageKey
        self.userDefaults = userDefaults
        loadRecords()
    }

    // MARK: - CRUD Operations

    func save(_ record: GameRecord) {
        records.append(record)
        records.sort { $0.completionDate > $1.completionDate }
        persistRecords()
    }

    func delete(_ record: GameRecord) {
        records.removeAll { $0.id == record.id }
        persistRecords()
    }

    func clearAll() {
        records.removeAll()
        userDefaults.removeObject(forKey: storageKey)
    }

    // MARK: - Statistics

    var totalGamesCount: Int {
        records.count
    }

    func gamesCount(for difficulty: Difficulty) -> Int {
        records.filter { $0.difficulty == difficulty }.count
    }

    func bestTime(for difficulty: Difficulty) -> TimeInterval? {
        records
            .filter { $0.difficulty == difficulty }
            .map { $0.elapsedTime }
            .min()
    }

    func averageTime(for difficulty: Difficulty) -> TimeInterval? {
        let times = records.filter { $0.difficulty == difficulty }.map { $0.elapsedTime }
        guard !times.isEmpty else { return nil }
        return times.reduce(0, +) / Double(times.count)
    }

    func recentRecords(limit: Int = 10) -> [GameRecord] {
        Array(records.prefix(limit))
    }

    func records(for difficulty: Difficulty) -> [GameRecord] {
        records.filter { $0.difficulty == difficulty }
    }

    // MARK: - Star Statistics

    var totalStars: Int {
        records.reduce(0) { $0 + $1.stars }
    }

    var maxPossibleStars: Int {
        records.count * 3
    }

    func totalStars(for difficulty: Difficulty) -> Int {
        records.filter { $0.difficulty == difficulty }.reduce(0) { $0 + $1.stars }
    }

    func bestStars(for difficulty: Difficulty) -> Int {
        records.filter { $0.difficulty == difficulty }.map { $0.stars }.max() ?? 0
    }

    // MARK: - Grid Size Statistics

    func gamesCount(for gridSize: GridSize) -> Int {
        records.filter { $0.gridSize == gridSize.size }.count
    }

    func bestTime(for gridSize: GridSize) -> TimeInterval? {
        records
            .filter { $0.gridSize == gridSize.size }
            .map { $0.elapsedTime }
            .min()
    }

    func bestTime(for difficulty: Difficulty, gridSize: GridSize) -> TimeInterval? {
        records
            .filter { $0.difficulty == difficulty && $0.gridSize == gridSize.size }
            .map { $0.elapsedTime }
            .min()
    }

    // MARK: - Persistence

    private func loadRecords() {
        guard let data = userDefaults.data(forKey: storageKey) else {
            records = []
            return
        }

        do {
            let decoder = JSONDecoder()
            records = try decoder.decode([GameRecord].self, from: data)
            records.sort { $0.completionDate > $1.completionDate }
        } catch {
            print("Failed to load game history: \(error)")
            records = []
        }
    }

    private func persistRecords() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(records)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            print("Failed to save game history: \(error)")
        }
    }
}

// MARK: - Shared Instance

extension GameHistoryManager {
    static let shared = GameHistoryManager()
}
