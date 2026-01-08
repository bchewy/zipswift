//
//  LevelPacksView.swift
//  zipswift
//
//  Shows available level packs with lock/unlock status.
//

import SwiftUI

struct LevelPacksView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelectLevel: (LevelDefinition, String, Int) -> Void

    @State private var selectedPack: LevelPack?

    private let progressManager = LevelProgressManager.shared
    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(progressManager.totalPackStars) stars collected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    ForEach(LevelPacks.all) { pack in
                        LevelPackCard(
                            pack: pack,
                            isUnlocked: progressManager.isPackUnlocked(pack),
                            currentStars: progressManager.totalPackStars,
                            completedLevels: progressManager.completedLevelsInPack(pack.id),
                            packStars: progressManager.starsForPack(pack.id)
                        ) {
                            selectedPack = pack
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Level Packs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedPack) { pack in
                LevelSelectView(pack: pack) { level, levelIndex in
                    dismiss()
                    onSelectLevel(level, pack.id, levelIndex)
                }
            }
            .tint(accentColor)
        }
    }
}

struct LevelPackCard: View {
    let pack: LevelPack
    let isUnlocked: Bool
    let currentStars: Int
    let completedLevels: Int
    let packStars: Int
    let onTap: () -> Void

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        Button(action: { if isUnlocked { onTap() } }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pack.name)
                            .font(.headline)
                            .foregroundColor(isUnlocked ? .primary : .secondary)

                        Text(pack.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if isUnlocked {
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text("\(packStars)/\(pack.levelCount * 3)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text("\(completedLevels)/\(pack.levelCount) levels")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                    }
                }

                if !isUnlocked {
                    VStack(spacing: 6) {
                        ProgressView(value: Double(currentStars), total: Double(pack.requiredStars))
                            .tint(accentColor)

                        Text("\(pack.requiredStars - currentStars) more stars needed")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isUnlocked ? accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .opacity(isUnlocked ? 1.0 : 0.7)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }
}

#Preview {
    LevelPacksView { _, _, _ in }
}
