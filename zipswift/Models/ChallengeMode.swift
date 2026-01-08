//
//  ChallengeMode.swift
//  zipswift
//
//  Challenge mode definitions and high score tracking.
//

import Foundation

enum ChallengeMode: String, CaseIterable, Codable, Identifiable {
    case timeAttack
    case noUndo
    case speedRun
    case zen

    var id: String { rawValue }

    var name: String {
        switch self {
        case .timeAttack: return "Time Attack"
        case .noUndo: return "No Undo"
        case .speedRun: return "Speed Run"
        case .zen: return "Zen Mode"
        }
    }

    var description: String {
        switch self {
        case .timeAttack:
            return "Complete as many puzzles as possible in 60 seconds"
        case .noUndo:
            return "Solve puzzles without using undo - plan carefully!"
        case .speedRun:
            return "Best total time across 5 consecutive puzzles"
        case .zen:
            return "Relaxed play with no timer - take your time"
        }
    }

    var icon: String {
        switch self {
        case .timeAttack: return "timer"
        case .noUndo: return "arrow.uturn.backward.circle.badge.ellipsis"
        case .speedRun: return "hare"
        case .zen: return "leaf"
        }
    }

    var scoreLabel: String {
        switch self {
        case .timeAttack: return "puzzles"
        case .noUndo: return "completed"
        case .speedRun: return "total time"
        case .zen: return "puzzles"
        }
    }
}

struct ChallengeScore: Codable, Identifiable {
    let id: UUID
    let mode: ChallengeMode
    let score: Int
    let date: Date
    var timeValue: TimeInterval?

    init(id: UUID = UUID(), mode: ChallengeMode, score: Int, date: Date = Date(), timeValue: TimeInterval? = nil) {
        self.id = id
        self.mode = mode
        self.score = score
        self.date = date
        self.timeValue = timeValue
    }

    var formattedScore: String {
        switch mode {
        case .timeAttack:
            return "\(score) puzzles"
        case .noUndo:
            return "\(score) completed"
        case .speedRun:
            if let time = timeValue {
                if time < 60 {
                    return String(format: "%.1fs", time)
                } else {
                    let minutes = Int(time) / 60
                    let seconds = Int(time) % 60
                    return String(format: "%d:%02d", minutes, seconds)
                }
            }
            return "\(score)"
        case .zen:
            return "\(score) puzzles"
        }
    }
}

@Observable
class ChallengeManager {
    static let shared = ChallengeManager()

    private let defaults = UserDefaults.standard
    private let scoresKey = "challenge_scores"

    private(set) var scores: [ChallengeScore] = []

    private init() {
        loadScores()
    }

    func highScore(for mode: ChallengeMode) -> ChallengeScore? {
        let modeScores = scores.filter { $0.mode == mode }

        switch mode {
        case .speedRun:
            return modeScores.min { ($0.timeValue ?? .infinity) < ($1.timeValue ?? .infinity) }
        default:
            return modeScores.max { $0.score < $1.score }
        }
    }

    func recordScore(_ score: ChallengeScore) {
        scores.append(score)
        saveScores()
    }

    func recentScores(for mode: ChallengeMode, limit: Int = 5) -> [ChallengeScore] {
        scores
            .filter { $0.mode == mode }
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }

    private func loadScores() {
        guard let data = defaults.data(forKey: scoresKey),
              let decoded = try? JSONDecoder().decode([ChallengeScore].self, from: data) else {
            return
        }
        scores = decoded
    }

    private func saveScores() {
        if let data = try? JSONEncoder().encode(scores) {
            defaults.set(data, forKey: scoresKey)
        }
    }
}
