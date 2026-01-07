//
//  GameHistoryTests.swift
//  zipswiftTests
//
//  Tests for game history storage and retrieval.
//

import Testing
import Foundation
@testable import zipswift

struct GameRecordTests {

    @Test func initializesWithAllProperties() {
        let date = Date()
        let record = GameRecord(
            completionDate: date,
            elapsedTime: 45.5,
            difficulty: .medium,
            gridSize: 6
        )

        #expect(record.completionDate == date)
        #expect(record.elapsedTime == 45.5)
        #expect(record.difficulty == .medium)
        #expect(record.gridSize == 6)
    }

    @Test func hasUniqueId() {
        let record1 = GameRecord(
            completionDate: Date(),
            elapsedTime: 30.0,
            difficulty: .easy,
            gridSize: 6
        )
        let record2 = GameRecord(
            completionDate: Date(),
            elapsedTime: 30.0,
            difficulty: .easy,
            gridSize: 6
        )

        #expect(record1.id != record2.id)
    }

    @Test func encodesToJSON() throws {
        let record = GameRecord(
            completionDate: Date(),
            elapsedTime: 60.0,
            difficulty: .hard,
            gridSize: 6
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(record)
        #expect(data.count > 0)
    }

    @Test func decodesFromJSON() throws {
        let originalRecord = GameRecord(
            completionDate: Date(),
            elapsedTime: 45.0,
            difficulty: .medium,
            gridSize: 6
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalRecord)

        let decoder = JSONDecoder()
        let decodedRecord = try decoder.decode(GameRecord.self, from: data)

        #expect(decodedRecord.id == originalRecord.id)
        #expect(decodedRecord.elapsedTime == originalRecord.elapsedTime)
        #expect(decodedRecord.difficulty == originalRecord.difficulty)
        #expect(decodedRecord.gridSize == originalRecord.gridSize)
    }

    @Test func formattedTimeShowsSecondsForShortTimes() {
        let record = GameRecord(
            completionDate: Date(),
            elapsedTime: 45.3,
            difficulty: .medium,
            gridSize: 6
        )

        #expect(record.formattedTime == "45.3s")
    }

    @Test func formattedTimeShowsMinutesForLongTimes() {
        let record = GameRecord(
            completionDate: Date(),
            elapsedTime: 125.0,
            difficulty: .medium,
            gridSize: 6
        )

        #expect(record.formattedTime == "2:05")
    }
}

struct GameHistoryManagerTests {

    // Use a unique key for testing to avoid interfering with real data
    private func makeTestManager() -> GameHistoryManager {
        let manager = GameHistoryManager(storageKey: "test_game_history_\(UUID().uuidString)")
        return manager
    }

    @Test func startsWithEmptyHistory() {
        let manager = makeTestManager()
        #expect(manager.records.isEmpty)
    }

    @Test func savesRecord() {
        let manager = makeTestManager()
        let record = GameRecord(
            completionDate: Date(),
            elapsedTime: 30.0,
            difficulty: .easy,
            gridSize: 6
        )

        manager.save(record)

        #expect(manager.records.count == 1)
        #expect(manager.records.first?.id == record.id)
    }

    @Test func savesMultipleRecords() {
        let manager = makeTestManager()

        for i in 1...5 {
            let record = GameRecord(
                completionDate: Date(),
                elapsedTime: Double(i * 10),
                difficulty: .medium,
                gridSize: 6
            )
            manager.save(record)
        }

        #expect(manager.records.count == 5)
    }

    @Test func recordsAreSortedByDateDescending() {
        let manager = makeTestManager()

        let oldDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let newDate = Date()

        let oldRecord = GameRecord(
            completionDate: oldDate,
            elapsedTime: 30.0,
            difficulty: .easy,
            gridSize: 6
        )
        let newRecord = GameRecord(
            completionDate: newDate,
            elapsedTime: 40.0,
            difficulty: .medium,
            gridSize: 6
        )

        manager.save(oldRecord)
        manager.save(newRecord)

        #expect(manager.records.first?.id == newRecord.id)
        #expect(manager.records.last?.id == oldRecord.id)
    }

    @Test func persistsAcrossInstances() {
        let storageKey = "test_persistence_\(UUID().uuidString)"

        // Save with first instance
        let manager1 = GameHistoryManager(storageKey: storageKey)
        let record = GameRecord(
            completionDate: Date(),
            elapsedTime: 50.0,
            difficulty: .hard,
            gridSize: 6
        )
        manager1.save(record)

        // Load with second instance
        let manager2 = GameHistoryManager(storageKey: storageKey)

        #expect(manager2.records.count == 1)
        #expect(manager2.records.first?.id == record.id)

        // Cleanup
        manager2.clearAll()
    }

    @Test func clearsAllRecords() {
        let manager = makeTestManager()

        for _ in 1...3 {
            let record = GameRecord(
                completionDate: Date(),
                elapsedTime: 30.0,
                difficulty: .easy,
                gridSize: 6
            )
            manager.save(record)
        }

        #expect(manager.records.count == 3)

        manager.clearAll()

        #expect(manager.records.isEmpty)
    }

    @Test func deletesSingleRecord() {
        let manager = makeTestManager()

        let record1 = GameRecord(completionDate: Date(), elapsedTime: 30.0, difficulty: .easy, gridSize: 6)
        let record2 = GameRecord(completionDate: Date(), elapsedTime: 40.0, difficulty: .medium, gridSize: 6)

        manager.save(record1)
        manager.save(record2)

        #expect(manager.records.count == 2)

        manager.delete(record1)

        #expect(manager.records.count == 1)
        #expect(manager.records.first?.id == record2.id)
    }

    @Test func returnsBestTimeForDifficulty() {
        let manager = makeTestManager()

        manager.save(GameRecord(completionDate: Date(), elapsedTime: 60.0, difficulty: .easy, gridSize: 6))
        manager.save(GameRecord(completionDate: Date(), elapsedTime: 45.0, difficulty: .easy, gridSize: 6))
        manager.save(GameRecord(completionDate: Date(), elapsedTime: 50.0, difficulty: .easy, gridSize: 6))
        manager.save(GameRecord(completionDate: Date(), elapsedTime: 30.0, difficulty: .medium, gridSize: 6))

        #expect(manager.bestTime(for: .easy) == 45.0)
        #expect(manager.bestTime(for: .medium) == 30.0)
        #expect(manager.bestTime(for: .hard) == nil)
    }

    @Test func returnsGamesCountForDifficulty() {
        let manager = makeTestManager()

        manager.save(GameRecord(completionDate: Date(), elapsedTime: 30.0, difficulty: .easy, gridSize: 6))
        manager.save(GameRecord(completionDate: Date(), elapsedTime: 40.0, difficulty: .easy, gridSize: 6))
        manager.save(GameRecord(completionDate: Date(), elapsedTime: 50.0, difficulty: .medium, gridSize: 6))

        #expect(manager.gamesCount(for: .easy) == 2)
        #expect(manager.gamesCount(for: .medium) == 1)
        #expect(manager.gamesCount(for: .hard) == 0)
    }

    @Test func returnsTotalGamesCount() {
        let manager = makeTestManager()

        manager.save(GameRecord(completionDate: Date(), elapsedTime: 30.0, difficulty: .easy, gridSize: 6))
        manager.save(GameRecord(completionDate: Date(), elapsedTime: 40.0, difficulty: .medium, gridSize: 6))
        manager.save(GameRecord(completionDate: Date(), elapsedTime: 50.0, difficulty: .hard, gridSize: 6))

        #expect(manager.totalGamesCount == 3)
    }
}
