//
//  HistoryView.swift
//  zipswift
//
//  Displays game history with statistics and past games list.
//

import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var historyManager = GameHistoryManager.shared

    private var accentColor: Color {
        SettingsManager.shared.accentColor.color
    }

    var body: some View {
        NavigationStack {
            List {
                // Stats Section
                Section("Statistics") {
                    StatsRow(label: "Total Games", value: "\(historyManager.totalGamesCount)")

                    if let bestEasy = historyManager.bestTime(for: .easy) {
                        StatsRow(label: "Best Easy", value: formatTime(bestEasy))
                    }
                    if let bestMedium = historyManager.bestTime(for: .medium) {
                        StatsRow(label: "Best Medium", value: formatTime(bestMedium))
                    }
                    if let bestHard = historyManager.bestTime(for: .hard) {
                        StatsRow(label: "Best Hard", value: formatTime(bestHard))
                    }
                }

                // Games by Difficulty
                Section("Games Played") {
                    DifficultyStatRow(difficulty: .easy, count: historyManager.gamesCount(for: .easy))
                    DifficultyStatRow(difficulty: .medium, count: historyManager.gamesCount(for: .medium))
                    DifficultyStatRow(difficulty: .hard, count: historyManager.gamesCount(for: .hard))
                }

                // Recent Games
                if !historyManager.records.isEmpty {
                    Section("Recent Games") {
                        ForEach(historyManager.records) { record in
                            GameRecordRow(record: record)
                        }
                        .onDelete(perform: deleteRecords)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                if !historyManager.records.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear All", role: .destructive) {
                            historyManager.clearAll()
                        }
                    }
                }
            }
            .overlay {
                if historyManager.records.isEmpty {
                    ContentUnavailableView(
                        "No Games Yet",
                        systemImage: "gamecontroller",
                        description: Text("Complete a puzzle to see your history here.")
                    )
                }
            }
            .tint(accentColor)
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        if time < 60 {
            return String(format: "%.1fs", time)
        } else {
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private func deleteRecords(at offsets: IndexSet) {
        for index in offsets {
            historyManager.delete(historyManager.records[index])
        }
    }
}

// MARK: - Stats Row

struct StatsRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Difficulty Stat Row

struct DifficultyStatRow: View {
    let difficulty: Difficulty
    let count: Int

    var body: some View {
        HStack {
            Image(difficulty.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            Text(label)
            Spacer()
            Text("\(count)")
                .foregroundColor(.secondary)
        }
    }

    private var label: String {
        switch difficulty {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
}

// MARK: - Game Record Row

struct GameRecordRow: View {
    let record: GameRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    DifficultyBadge(difficulty: record.difficulty)
                    Text(record.formattedTime)
                        .font(.headline)
                }
                Text(record.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Difficulty Badge

struct DifficultyBadge: View {
    let difficulty: Difficulty

    var body: some View {
        HStack(spacing: 4) {
            Image(difficulty.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.primary)
    }

    private var label: String {
        switch difficulty {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
}

#Preview {
    HistoryView()
}
