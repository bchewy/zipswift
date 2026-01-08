//
//  HistoryView.swift
//  zipswift
//
//  Statistics dashboard with charts, records, and milestones.
//

import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var historyManager = GameHistoryManager.shared
    @State private var settingsManager = SettingsManager.shared

    private var accentColor: Color {
        settingsManager.accentColor.color
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if historyManager.records.isEmpty {
                        emptyStateView
                    } else {
                        overviewSection
                        streaksSection
                        chartsSection
                        personalRecordsSection
                        milestonesSection
                        recentGamesSection
                    }
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .tint(accentColor)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Games Yet",
            systemImage: "gamecontroller",
            description: Text("Complete a puzzle to see your statistics here.")
        )
        .frame(minHeight: 400)
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Total Games",
                    value: "\(historyManager.totalGamesCount)",
                    icon: "gamecontroller.fill"
                )
                StatCard(
                    title: "Total Stars",
                    value: "\(historyManager.totalStars)",
                    icon: "star.fill",
                    iconColor: .yellow
                )
            }

            HStack(spacing: 12) {
                StatCard(
                    title: "Time Played",
                    value: formatTotalTime(totalTimePlayed),
                    icon: "timer"
                )
                if let avgTime = overallAverageTime {
                    StatCard(
                        title: "Avg Time",
                        value: formatTime(avgTime),
                        icon: "clock"
                    )
                } else {
                    StatCard(
                        title: "Avg Time",
                        value: "--",
                        icon: "clock"
                    )
                }
            }

            if let improvement = improvementPercentage {
                ImprovementBanner(percentage: improvement)
            }
        }
    }

    // MARK: - Streaks Section

    private var streaksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streaks & Activity")
                .font(.headline)

            HStack(spacing: 12) {
                StreakCard(
                    title: "Daily Streak",
                    value: settingsManager.dailyStreak,
                    icon: "flame.fill",
                    iconColor: .orange
                )
                StreakCard(
                    title: "Games Today",
                    value: gamesToday,
                    icon: "calendar",
                    iconColor: accentColor
                )
                StreakCard(
                    title: "This Week",
                    value: gamesThisWeek,
                    icon: "calendar.badge.clock",
                    iconColor: accentColor
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Charts Section

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity")
                .font(.headline)

            GamesPerDayChart(data: gamesPerDayData)
                .frame(height: 120)

            if historyManager.records.count >= 3 {
                Text("Time Trend")
                    .font(.headline)
                    .padding(.top, 8)

                TimeTrendChart(times: recentTimes)
                    .frame(height: 100)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Personal Records Section

    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Records")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                Text("By Difficulty")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(spacing: 8) {
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        if let best = historyManager.bestTime(for: difficulty) {
                            PersonalRecordRow(
                                difficulty: difficulty,
                                time: best,
                                gamesCount: historyManager.gamesCount(for: difficulty)
                            )
                        }
                    }
                }
            }

            if hasGridSizeRecords {
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("By Grid Size")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(spacing: 8) {
                        ForEach(GridSize.allCases, id: \.self) { gridSize in
                            if let best = historyManager.bestTime(for: gridSize) {
                                GridSizeRecordRow(
                                    gridSize: gridSize,
                                    time: best,
                                    gamesCount: historyManager.gamesCount(for: gridSize)
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var hasGridSizeRecords: Bool {
        GridSize.allCases.contains { historyManager.bestTime(for: $0) != nil }
    }

    // MARK: - Milestones Section

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestones")
                .font(.headline)

            VStack(spacing: 8) {
                MilestoneRow(
                    title: "Games Completed",
                    current: historyManager.totalGamesCount,
                    target: nextGamesMilestone
                )
                MilestoneRow(
                    title: "Stars Earned",
                    current: historyManager.totalStars,
                    target: nextStarsMilestone
                )
                MilestoneRow(
                    title: "3-Star Games",
                    current: threeStarCount,
                    target: nextThreeStarMilestone
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Recent Games Section

    private var recentGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Games")
                    .font(.headline)
                Spacer()
                if historyManager.records.count > 5 {
                    Text("\(historyManager.records.count) total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            VStack(spacing: 0) {
                ForEach(historyManager.recentRecords(limit: 5)) { record in
                    GameRecordRow(record: record)
                    if record.id != historyManager.recentRecords(limit: 5).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Computed Properties

    private var gamesToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return historyManager.records.filter {
            Calendar.current.isDate($0.completionDate, inSameDayAs: today)
        }.count
    }

    private var gamesThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return 0
        }
        return historyManager.records.filter { $0.completionDate >= weekStart }.count
    }

    private var totalTimePlayed: TimeInterval {
        historyManager.records.reduce(0.0) { $0 + $1.elapsedTime }
    }

    private var overallAverageTime: TimeInterval? {
        guard !historyManager.records.isEmpty else { return nil }
        return totalTimePlayed / Double(historyManager.records.count)
    }

    private var improvementPercentage: Int? {
        let records = historyManager.records.sorted { $0.completionDate < $1.completionDate }
        guard records.count >= 5 else { return nil }

        let firstFive = records.prefix(5).map { $0.elapsedTime }
        let lastFive = records.suffix(5).map { $0.elapsedTime }

        let firstAvg = firstFive.reduce(0, +) / Double(firstFive.count)
        let lastAvg = lastFive.reduce(0, +) / Double(lastFive.count)

        guard firstAvg > 0 else { return nil }
        let improvement = ((firstAvg - lastAvg) / firstAvg) * 100
        return improvement > 0 ? Int(improvement) : nil
    }

    private var gamesPerDayData: [(String, Int)] {
        var result: [(String, Int)] = []
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "E"

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let count = historyManager.records.filter {
                calendar.isDate($0.completionDate, inSameDayAs: dayStart)
            }.count
            result.append((formatter.string(from: date), count))
        }
        return result
    }

    private var recentTimes: [TimeInterval] {
        historyManager.records
            .sorted { $0.completionDate < $1.completionDate }
            .suffix(10)
            .map { $0.elapsedTime }
    }

    private var threeStarCount: Int {
        historyManager.records.filter { $0.stars >= 3 }.count
    }

    private var nextGamesMilestone: Int {
        let milestones = [10, 25, 50, 100, 250, 500, 1000]
        return milestones.first { $0 > historyManager.totalGamesCount } ?? 1000
    }

    private var nextStarsMilestone: Int {
        let milestones = [25, 50, 100, 250, 500, 1000, 2500]
        return milestones.first { $0 > historyManager.totalStars } ?? 2500
    }

    private var nextThreeStarMilestone: Int {
        let milestones = [5, 10, 25, 50, 100, 250]
        return milestones.first { $0 > threeStarCount } ?? 250
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

    private func formatTotalTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "<1m"
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var iconColor: Color = .secondary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Spacer()
            }
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let title: String
    let value: Int
    let icon: String
    var iconColor: Color = .secondary

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
            Text("\(value)")
                .font(.title2.bold())
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Improvement Banner

struct ImprovementBanner: View {
    let percentage: Int

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        HStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundColor(accentColor)
            Text("You're \(percentage)% faster than your first games!")
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .background(accentColor.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Games Per Day Chart

struct GamesPerDayChart: View {
    let data: [(String, Int)]

    private var accentColor: Color { SettingsManager.shared.accentColor.color }
    private var maxValue: Int { max(data.map { $0.1 }.max() ?? 1, 1) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(data, id: \.0) { item in
                VStack(spacing: 4) {
                    if item.1 > 0 {
                        Text("\(item.1)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    RoundedRectangle(cornerRadius: 4)
                        .fill(item.1 > 0 ? accentColor : Color.gray.opacity(0.3))
                        .frame(height: max(CGFloat(item.1) / CGFloat(maxValue) * 80, item.1 > 0 ? 10 : 4))
                    Text(item.0)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Time Trend Chart

struct TimeTrendChart: View {
    let times: [TimeInterval]

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let minTime = times.min() ?? 0
            let maxTime = times.max() ?? 1
            let range = max(maxTime - minTime, 1)

            Path { path in
                guard times.count > 1 else { return }

                for (index, time) in times.enumerated() {
                    let x = CGFloat(index) / CGFloat(times.count - 1) * width
                    let y = height - ((CGFloat(time) - CGFloat(minTime)) / CGFloat(range) * height * 0.8 + height * 0.1)

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

            ForEach(times.indices, id: \.self) { index in
                let time = times[index]
                let x = CGFloat(index) / CGFloat(max(times.count - 1, 1)) * width
                let y = height - ((CGFloat(time) - CGFloat(minTime)) / CGFloat(range) * height * 0.8 + height * 0.1)

                Circle()
                    .fill(accentColor)
                    .frame(width: 6, height: 6)
                    .position(x: x, y: y)
            }
        }
    }
}

// MARK: - Personal Record Row

struct PersonalRecordRow: View {
    let difficulty: Difficulty
    let time: TimeInterval
    let gamesCount: Int

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        HStack {
            DifficultyBadge(difficulty: difficulty)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(time))
                    .font(.headline)
                    .foregroundColor(accentColor)
                Text("\(gamesCount) games")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
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
}

// MARK: - Grid Size Record Row

struct GridSizeRecordRow: View {
    let gridSize: GridSize
    let time: TimeInterval
    let gamesCount: Int

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        HStack {
            Text(gridSize.shortName)
                .font(.headline)
                .frame(width: 50, alignment: .leading)
            Text(gridSize.displayName.replacingOccurrences(of: gridSize.shortName + " ", with: ""))
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(time))
                    .font(.headline)
                    .foregroundColor(accentColor)
                Text("\(gamesCount) games")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
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
}

// MARK: - Milestone Row

struct MilestoneRow: View {
    let title: String
    let current: Int
    let target: Int

    private var accentColor: Color { SettingsManager.shared.accentColor.color }
    private var progress: Double { min(Double(current) / Double(target), 1.0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(current)/\(target)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(accentColor)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 8)
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
            StarRatingView(stars: record.stars, animated: false, size: 16)
        }
        .padding(.vertical, 8)
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
