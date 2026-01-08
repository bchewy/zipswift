//
//  NumberNodeView.swift
//  zipswift
//
//  Renders numbered cells as black circles with white text and animations.
//

import SwiftUI

struct NumberNodeView: View {
    let number: Int
    let isActive: Bool
    let cellSize: CGFloat
    var wasJustReached: Bool = false

    @State private var ringScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 1.0

    private var accentColor: Color {
        SettingsManager.shared.accentColor.color
    }

    private var reduceMotion: Bool {
        SettingsManager.shared.reduceMotion
    }

    var body: some View {
        ZStack {
            if wasJustReached && !reduceMotion {
                Circle()
                    .stroke(accentColor, lineWidth: 3)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)
            }

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
        .onChange(of: wasJustReached) { _, justReached in
            if justReached && !reduceMotion {
                animateRingPulse()
            }
        }
    }

    private func animateRingPulse() {
        ringScale = 1.0
        ringOpacity = 1.0

        withAnimation(.easeOut(duration: 0.4)) {
            ringScale = 1.8
            ringOpacity = 0.0
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        NumberNodeView(number: 1, isActive: true, cellSize: 60)
        NumberNodeView(number: 2, isActive: false, cellSize: 60)
        NumberNodeView(number: 10, isActive: false, cellSize: 60, wasJustReached: true)
    }
    .padding()
}
