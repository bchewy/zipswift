//
//  ChallengeModeSelectView.swift
//  zipswift
//
//  Challenge mode selection screen.
//

import SwiftUI

struct ChallengeModeSelectView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelectMode: (ChallengeMode) -> Void

    private let challengeManager = ChallengeManager.shared
    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(ChallengeMode.allCases) { mode in
                        ChallengeModeCard(
                            mode: mode,
                            highScore: challengeManager.highScore(for: mode)
                        ) {
                            dismiss()
                            onSelectMode(mode)
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Challenge Modes")
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

struct ChallengeModeCard: View {
    let mode: ChallengeMode
    let highScore: ChallengeScore?
    let onTap: () -> Void

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: mode.icon)
                        .font(.title2)
                        .foregroundColor(accentColor)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(mode.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let score = highScore {
                    HStack {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("Best: \(score.formattedScore)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ChallengeModeSelectView { _ in }
}
