//
//  ZipSwiftWidget.swift
//  ZipSwiftWidget
//
//  Home screen widgets showing daily streak and challenge stats.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Data

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

    var accentColor: Color {
        switch accentColorName {
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "pink": return .pink
        case "teal": return .teal
        case "red": return .red
        case "indigo": return .indigo
        case "mint": return .mint
        default: return .blue
        }
    }
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    private let appGroupIdentifier = "group.com.zipswift.shared"
    private let dataKey = "widget_shared_data"

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), data: loadData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let data = loadData()
        let currentDate = Date()

        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: currentDate)
        let nextMidnight = calendar.date(byAdding: .day, value: 1, to: midnight)!

        let entry = SimpleEntry(date: currentDate, data: data)
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))

        completion(timeline)
    }

    private func loadData() -> WidgetSharedData {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let jsonData = defaults.data(forKey: dataKey),
              let data = try? JSONDecoder().decode(WidgetSharedData.self, from: jsonData) else {
            return .empty
        }
        return data
    }
}

// MARK: - Timeline Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let data: WidgetSharedData
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: SimpleEntry

    private var accentColor: Color { entry.data.accentColor }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.title2)
                    .foregroundColor(accentColor)

                Spacer()

                if entry.data.dailyStreak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(entry.data.dailyStreak)")
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    .font(.caption)
                }
            }

            Spacer()

            if entry.data.hasCompletedToday {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Best")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if let time = entry.data.todayBestTime {
                        Text(formatTime(time))
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Challenge")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("Tap to play")
                        .font(.headline)
                        .foregroundColor(accentColor)
                }
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
        .widgetURL(URL(string: "zipswift://daily"))
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: SimpleEntry

    private var accentColor: Color { entry.data.accentColor }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.title2)
                        .foregroundColor(accentColor)

                    Text("ZipSwift")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Spacer()

                if entry.data.dailyStreak > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Streak")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(entry.data.dailyStreak) days")
                                .fontWeight(.bold)
                        }
                        .font(.subheadline)
                    }
                }

                if entry.data.hasCompletedToday, let time = entry.data.todayBestTime {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today's Best")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(formatTime(time))
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                    }
                }
            }

            Spacer()

            VStack {
                MiniGridPreview(accentColor: accentColor)
                    .frame(width: 80, height: 80)

                if !entry.data.hasCompletedToday {
                    Text("Tap to play")
                        .font(.caption)
                        .foregroundColor(accentColor)
                } else {
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
        .widgetURL(URL(string: "zipswift://daily"))
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

// MARK: - Mini Grid Preview

struct MiniGridPreview: View {
    let accentColor: Color

    private let gridSize = 3

    var body: some View {
        GeometryReader { geometry in
            let cellSize = min(geometry.size.width, geometry.size.height) / CGFloat(gridSize)

            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.1))

                Canvas { context, _ in
                    for i in 0...gridSize {
                        let x = CGFloat(i) * cellSize
                        var vPath = Path()
                        vPath.move(to: CGPoint(x: x, y: 0))
                        vPath.addLine(to: CGPoint(x: x, y: CGFloat(gridSize) * cellSize))
                        context.stroke(vPath, with: .color(Color.gray.opacity(0.3)), lineWidth: 0.5)

                        let y = CGFloat(i) * cellSize
                        var hPath = Path()
                        hPath.move(to: CGPoint(x: 0, y: y))
                        hPath.addLine(to: CGPoint(x: CGFloat(gridSize) * cellSize, y: y))
                        context.stroke(hPath, with: .color(Color.gray.opacity(0.3)), lineWidth: 0.5)
                    }
                }

                Canvas { context, _ in
                    var path = Path()
                    path.move(to: CGPoint(x: cellSize / 2, y: cellSize / 2))
                    path.addLine(to: CGPoint(x: cellSize * 1.5, y: cellSize / 2))
                    path.addLine(to: CGPoint(x: cellSize * 2.5, y: cellSize / 2))
                    path.addLine(to: CGPoint(x: cellSize * 2.5, y: cellSize * 1.5))

                    context.stroke(
                        path,
                        with: .color(accentColor),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                }

                Circle()
                    .fill(Color.white)
                    .stroke(Color.black, lineWidth: 1)
                    .frame(width: cellSize * 0.5, height: cellSize * 0.5)
                    .overlay(
                        Text("1")
                            .font(.system(size: cellSize * 0.25, weight: .bold))
                    )
                    .position(x: cellSize / 2, y: cellSize / 2)

                Circle()
                    .fill(Color.white)
                    .stroke(Color.black, lineWidth: 1)
                    .frame(width: cellSize * 0.5, height: cellSize * 0.5)
                    .overlay(
                        Text("2")
                            .font(.system(size: cellSize * 0.25, weight: .bold))
                    )
                    .position(x: cellSize * 2.5, y: cellSize * 2.5)
            }
        }
    }
}

// MARK: - Widget Configuration

struct ZipSwiftSmallWidget: Widget {
    let kind: String = "ZipSwiftSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SmallWidgetView(entry: entry)
        }
        .configurationDisplayName("ZipSwift")
        .description("Track your daily streak and challenge progress.")
        .supportedFamilies([.systemSmall])
    }
}

struct ZipSwiftMediumWidget: Widget {
    let kind: String = "ZipSwiftMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MediumWidgetView(entry: entry)
        }
        .configurationDisplayName("ZipSwift Daily")
        .description("View your streak, stats, and daily puzzle preview.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct ZipSwiftWidgetBundle: WidgetBundle {
    var body: some Widget {
        ZipSwiftSmallWidget()
        ZipSwiftMediumWidget()
    }
}

// MARK: - Previews

#Preview("Small Widget", as: .systemSmall) {
    ZipSwiftSmallWidget()
} timeline: {
    SimpleEntry(date: .now, data: WidgetSharedData(
        dailyStreak: 7,
        todayBestTime: 45.5,
        hasCompletedToday: true,
        lastUpdate: Date(),
        accentColorName: "blue"
    ))
    SimpleEntry(date: .now, data: WidgetSharedData(
        dailyStreak: 3,
        todayBestTime: nil,
        hasCompletedToday: false,
        lastUpdate: Date(),
        accentColorName: "purple"
    ))
}

#Preview("Medium Widget", as: .systemMedium) {
    ZipSwiftMediumWidget()
} timeline: {
    SimpleEntry(date: .now, data: WidgetSharedData(
        dailyStreak: 14,
        todayBestTime: 92.3,
        hasCompletedToday: true,
        lastUpdate: Date(),
        accentColorName: "green"
    ))
}
