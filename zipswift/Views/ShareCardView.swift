//
//  ShareCardView.swift
//  zipswift
//
//  Share result card image and text generation.
//

import SwiftUI
import UIKit

struct ShareCardView: View {
    let elapsedTime: TimeInterval
    let difficulty: Difficulty
    let stars: Int
    let isDaily: Bool
    let dailyStreak: Int

    private var accentColor: Color {
        SettingsManager.shared.accentColor.color
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("ZipSwift")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                if isDaily {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text("Daily")
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.2))
                    .cornerRadius(8)
                }
            }

            VStack(spacing: 8) {
                Text(difficultyLabel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(formattedTime)
                    .font(.system(size: 40, weight: .semibold, design: .monospaced))
                    .foregroundColor(accentColor)

                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundColor(i < stars ? .yellow : .gray.opacity(0.3))
                    }
                }
            }

            if dailyStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(dailyStreak) day streak")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Text(dateString)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .frame(width: 280)
    }

    private var difficultyLabel: String {
        switch difficulty {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    private var formattedTime: String {
        if elapsedTime < 60 {
            return String(format: "%.1fs", elapsedTime)
        } else {
            let minutes = Int(elapsedTime) / 60
            let seconds = Int(elapsedTime) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
}

struct ShareHelper {
    static func generateShareText(
        elapsedTime: TimeInterval,
        difficulty: Difficulty,
        stars: Int,
        isDaily: Bool,
        dailyStreak: Int
    ) -> String {
        let difficultyLabel: String = {
            switch difficulty {
            case .easy: return "Easy"
            case .medium: return "Medium"
            case .hard: return "Hard"
            }
        }()

        let timeString: String = {
            if elapsedTime < 60 {
                return String(format: "%.1fs", elapsedTime)
            } else {
                let minutes = Int(elapsedTime) / 60
                let seconds = Int(elapsedTime) % 60
                return String(format: "%d:%02d", minutes, seconds)
            }
        }()

        let starString = String(repeating: "⭐", count: stars)

        var text = "ZipSwift"
        if isDaily {
            text += " Daily Challenge"
        }
        text += " [\(difficultyLabel)] \(starString) \(timeString)"

        if dailyStreak > 0 {
            text += " 🔥\(dailyStreak)"
        }

        text += "\n\n#ZipSwift"

        return text
    }

    @MainActor
    static func generateShareImage(
        elapsedTime: TimeInterval,
        difficulty: Difficulty,
        stars: Int,
        isDaily: Bool,
        dailyStreak: Int
    ) -> UIImage? {
        let view = ShareCardView(
            elapsedTime: elapsedTime,
            difficulty: difficulty,
            stars: stars,
            isDaily: isDaily,
            dailyStreak: dailyStreak
        )

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        return renderer.uiImage
    }
}

#Preview {
    VStack(spacing: 20) {
        ShareCardView(
            elapsedTime: 42.3,
            difficulty: .easy,
            stars: 3,
            isDaily: false,
            dailyStreak: 0
        )

        ShareCardView(
            elapsedTime: 95.7,
            difficulty: .hard,
            stars: 2,
            isDaily: true,
            dailyStreak: 7
        )
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
