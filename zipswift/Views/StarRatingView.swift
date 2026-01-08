//
//  StarRatingView.swift
//  zipswift
//
//  Displays 1-3 stars based on completion time thresholds.
//

import SwiftUI

struct StarRating {
    static func stars(for time: TimeInterval, difficulty: Difficulty) -> Int {
        switch difficulty {
        case .easy:
            if time < 45 { return 3 }
            if time < 90 { return 2 }
            return 1
        case .medium:
            if time < 60 { return 3 }
            if time < 120 { return 2 }
            return 1
        case .hard:
            if time < 90 { return 3 }
            if time < 180 { return 2 }
            return 1
        }
    }

    static func thresholds(for difficulty: Difficulty) -> (threeStar: TimeInterval, twoStar: TimeInterval) {
        switch difficulty {
        case .easy: return (45, 90)
        case .medium: return (60, 120)
        case .hard: return (90, 180)
        }
    }
}

struct StarRatingView: View {
    let stars: Int
    let animated: Bool
    let size: CGFloat

    @State private var visibleStars: [Bool] = [false, false, false]

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    init(stars: Int, animated: Bool = false, size: CGFloat = 32) {
        self.stars = stars
        self.animated = animated
        self.size = size
    }

    var body: some View {
        HStack(spacing: size * 0.25) {
            ForEach(0..<3, id: \.self) { index in
                starImage(for: index)
                    .font(.system(size: size))
                    .foregroundColor(index < stars ? .yellow : .gray.opacity(0.3))
                    .scaleEffect(visibleStars[index] ? 1.0 : 0.5)
                    .opacity(visibleStars[index] ? 1.0 : 0.0)
            }
        }
        .onAppear {
            if animated {
                animateStars()
            } else {
                visibleStars = [true, true, true]
            }
        }
    }

    private func starImage(for index: Int) -> some View {
        Image(systemName: index < stars ? "star.fill" : "star")
    }

    private func animateStars() {
        for i in 0..<3 {
            let delay = Double(i) * 0.2
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    visibleStars[i] = true
                }
            }
        }
    }
}

struct StarRatingCompactView: View {
    let stars: Int
    let maxStars: Int

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    init(stars: Int, maxStars: Int = 3) {
        self.stars = stars
        self.maxStars = maxStars
    }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.caption)
                .foregroundColor(.yellow)
            Text("\(stars)/\(maxStars)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StarRatingView(stars: 3, animated: false)
        StarRatingView(stars: 2, animated: false)
        StarRatingView(stars: 1, animated: false)
        StarRatingCompactView(stars: 2)
    }
}
