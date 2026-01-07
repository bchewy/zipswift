//
//  NumberNodeView.swift
//  zipswift
//
//  Renders numbered cells as black circles with white text.
//

import SwiftUI

struct NumberNodeView: View {
    let number: Int
    let isActive: Bool
    let cellSize: CGFloat

    private var accentColor: Color {
        SettingsManager.shared.accentColor.color
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

            if isActive {
                Circle()
                    .stroke(accentColor, lineWidth: 3)
            }

            Text("\(number)")
                .font(.system(size: cellSize * 0.4, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: cellSize * 0.7, height: cellSize * 0.7)
    }
}

#Preview {
    VStack(spacing: 20) {
        NumberNodeView(number: 1, isActive: true, cellSize: 60)
        NumberNodeView(number: 2, isActive: false, cellSize: 60)
        NumberNodeView(number: 10, isActive: false, cellSize: 60)
    }
    .padding()
}
