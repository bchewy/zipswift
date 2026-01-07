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

    init(
        id: UUID = UUID(),
        completionDate: Date,
        elapsedTime: TimeInterval,
        difficulty: Difficulty,
        gridSize: Int
    ) {
        self.id = id
        self.completionDate = completionDate
        self.elapsedTime = elapsedTime
        self.difficulty = difficulty
        self.gridSize = gridSize
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

// Make Difficulty codable for storage
extension Difficulty: Codable {
    enum CodingKeys: String, CodingKey {
        case rawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue {
        case "easy": self = .easy
        case "medium": self = .medium
        case "hard": self = .hard
        default: self = .medium
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .easy: try container.encode("easy")
        case .medium: try container.encode("medium")
        case .hard: try container.encode("hard")
        }
    }
}
