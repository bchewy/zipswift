//
//  GameRecord.swift
//  zipswift
//
//  Represents a completed game for history tracking.
//

import Foundation

struct GameRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let completionDate: Date
    let elapsedTime: TimeInterval
    let difficulty: Difficulty
    let gridSize: Int
    let stars: Int

    init(
        id: UUID = UUID(),
        completionDate: Date,
        elapsedTime: TimeInterval,
        difficulty: Difficulty,
        gridSize: Int,
        stars: Int? = nil
    ) {
        self.id = id
        self.completionDate = completionDate
        self.elapsedTime = elapsedTime
        self.difficulty = difficulty
        self.gridSize = gridSize
        self.stars = stars ?? StarRating.stars(for: elapsedTime, difficulty: difficulty)
    }

    var formattedTime: String {
        if elapsedTime < 60 {
            return String(format: "%.1fs", elapsedTime)
        } else {
            let minutes = Int(elapsedTime) / 60
            let seconds = Int(elapsedTime) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: completionDate)
    }

    var difficultyLabel: String {
        switch difficulty {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
}

