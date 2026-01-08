//
//  LevelSelectView.swift
//  zipswift
//
//  Shows levels within a pack with star ratings.
//

import SwiftUI

struct LevelSelectView: View {
    @Environment(\.dismiss) private var dismiss

    let pack: LevelPack
    let onSelectLevel: (LevelDefinition, Int) -> Void

    private let progressManager = LevelProgressManager.shared
    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(progressManager.starsForPack(pack.id))/\(pack.levelCount * 3)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(0..<pack.levelCount, id: \.self) { index in
                            LevelButton(
                                levelNumber: index + 1,
                                stars: progressManager.starsForLevel(packId: pack.id, levelIndex: index),
                                isCompleted: progressManager.isLevelCompleted(packId: pack.id, levelIndex: index)
                            ) {
                                dismiss()
                                onSelectLevel(pack.levels[index], index)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle(pack.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .tint(accentColor)
        }
    }
}

struct LevelButton: View {
    let levelNumber: Int
    let stars: Int
    let isCompleted: Bool
    let onTap: () -> Void

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                        .frame(width: 50, height: 50)

                    Text("\(levelNumber)")
                        .font(.headline)
                        .foregroundColor(isCompleted ? accentColor : .primary)
                }

                if stars > 0 {
                    HStack(spacing: 1) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < stars ? "star.fill" : "star")
                                .font(.system(size: 8))
                                .foregroundColor(i < stars ? .yellow : .gray.opacity(0.3))
                        }
                    }
                } else {
                    HStack(spacing: 1) {
                        ForEach(0..<3, id: \.self) { _ in
                            Image(systemName: "star")
                                .font(.system(size: 8))
                                .foregroundColor(.gray.opacity(0.3))
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LevelSelectView(pack: LevelPacks.gettingStarted) { _, _ in }
}
