//
//  NumberNodeView.swift
//  zipswift
//
//  Renders numbered cells with theme-aware styling and animations.
//

import SwiftUI

struct NumberNodeView: View {
    let number: Int
    let isActive: Bool
    let cellSize: CGFloat
    var wasJustReached: Bool = false

    @State private var ringScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 1.0

    private var theme: VisualTheme {
        SettingsManager.shared.visualTheme
    }

    private var nodeStyle: ThemeNodeStyle {
        theme.nodeStyle
    }

    private var accentColor: Color {
        SettingsManager.shared.accentColor.color
    }

    private var activeColor: Color {
        theme.activeNodeColor
    }

    private var reduceMotion: Bool {
        SettingsManager.shared.reduceMotion
    }

    var body: some View {
        ZStack {
            if wasJustReached && !reduceMotion {
                Circle()
                    .stroke(activeColor, lineWidth: 3)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)
            }

            Circle()
                .fill(isActive ? activeColor : nodeStyle.backgroundColor.color)
                .shadow(color: .black.opacity(nodeStyle.shadowRadius > 0 ? 0.3 : 0), radius: nodeStyle.shadowRadius, x: 0, y: 1)

            if let borderColor = nodeStyle.borderColor {
                Circle()
                    .stroke(isActive ? activeColor : borderColor.color, lineWidth: nodeStyle.borderWidth)
            } else if isActive {
                Circle()
                    .stroke(activeColor, lineWidth: 3)
            }

            Text("\(number)")
                .font(.system(size: cellSize * 0.4, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
        }
        .frame(width: cellSize * 0.7, height: cellSize * 0.7)
        .onChange(of: wasJustReached) { _, justReached in
            if justReached && !reduceMotion {
                animateRingPulse()
            }
        }
    }

    private var textColor: Color {
        if isActive {
            if nodeStyle.backgroundColor == .clear {
                return activeColor
            } else {
                return .white
            }
        } else {
            return nodeStyle.textColor.color
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
