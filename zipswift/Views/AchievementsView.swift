//
//  AchievementsView.swift
//  zipswift
//
//  Displays achievement grid with locked/unlocked states.
//

import SwiftUI

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss

    private let achievementManager = AchievementManager.shared
    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("\(achievementManager.unlockedCount)/\(achievementManager.totalCount) Unlocked")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(achievementManager.achievements) { achievement in
                            AchievementBadgeView(achievement: achievement)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .tint(accentColor)
        }
    }
}

struct AchievementBadgeView: View {
    let achievement: Achievement

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? accentColor.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 70, height: 70)

                if achievement.isUnlocked {
                    Image(systemName: achievement.icon)
                        .font(.system(size: 30))
                        .foregroundColor(accentColor)
                } else {
                    Text("?")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }

            if achievement.isUnlocked {
                Text(achievement.name)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let date = achievement.unlockedDate {
                    Text(formatDate(date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text(achievement.unlockHint)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 30)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct AchievementToastView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var isVisible = false

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        VStack {
            Spacer()

            if isVisible {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 50, height: 50)

                        Image(systemName: achievement.icon)
                            .font(.title2)
                            .foregroundColor(accentColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Achievement Unlocked!")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)

                        Text(achievement.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onTapGesture {
                    dismissToast()
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                dismissToast()
            }
        }
    }

    private func dismissToast() {
        withAnimation(.easeOut(duration: 0.2)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

#Preview {
    AchievementsView()
}
