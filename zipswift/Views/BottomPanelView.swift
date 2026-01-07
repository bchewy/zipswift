//
//  BottomPanelView.swift
//  zipswift
//
//  Collapsible "How to play" panel.
//

import SwiftUI

struct BottomPanelView: View {
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Header button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("How to play")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            // Expandable content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    InstructionRow(
                        icon: "1.circle.fill",
                        text: "Draw a path starting from 1"
                    )
                    InstructionRow(
                        icon: "arrow.up.arrow.down",
                        text: "Move up, down, left, or right"
                    )
                    InstructionRow(
                        icon: "number",
                        text: "Visit numbered cells in order (1, 2, 3...)"
                    )
                    InstructionRow(
                        icon: "square.grid.3x3.fill",
                        text: "Fill every cell exactly once"
                    )
                    InstructionRow(
                        icon: "arrow.uturn.backward",
                        text: "Drag back or tap Undo to backtrack"
                    )
                }
                .padding(16)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct InstructionRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        BottomPanelView()
            .padding()
    }
}
