//
//  VisualTheme.swift
//  zipswift
//
//  Visual themes for customizing the game appearance.
//

import SwiftUI
import UIKit

enum VisualTheme: String, CaseIterable, Codable, Identifiable {
    case standard
    case neon
    case paper
    case minimal
    case ocean

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: return "Classic"
        case .neon: return "Neon"
        case .paper: return "Paper"
        case .minimal: return "Minimal"
        case .ocean: return "Ocean"
        }
    }

    var description: String {
        switch self {
        case .standard: return "The original ZipSwift look"
        case .neon: return "Glowing colors on dark"
        case .paper: return "Hand-drawn sketch style"
        case .minimal: return "Clean and simple"
        case .ocean: return "Calm ocean waves"
        }
    }

    var requiredStars: Int {
        switch self {
        case .standard: return 0
        case .minimal: return 25
        case .paper: return 50
        case .neon: return 100
        case .ocean: return 200
        }
    }

    var gridBackground: ThemeBackground {
        switch self {
        case .standard:
            return .solid(Color.gray.opacity(0.15))
        case .neon:
            return .solid(Color.black.opacity(0.95))
        case .paper:
            return .solid(Color(red: 0.96, green: 0.94, blue: 0.90))
        case .minimal:
            return .solid(Color.white)
        case .ocean:
            return .gradient([
                Color(red: 0.1, green: 0.4, blue: 0.6),
                Color(red: 0.2, green: 0.5, blue: 0.7)
            ])
        }
    }

    var gridLineColor: Color {
        switch self {
        case .standard: return Color.gray.opacity(0.3)
        case .neon: return Color.cyan.opacity(0.2)
        case .paper: return Color.brown.opacity(0.15)
        case .minimal: return Color.gray.opacity(0.15)
        case .ocean: return Color.white.opacity(0.2)
        }
    }

    var pathStyle: ThemePathStyle {
        switch self {
        case .standard:
            return ThemePathStyle(
                color: nil,
                lineWidth: 8,
                lineCap: .round,
                glowRadius: 0,
                dashPattern: []
            )
        case .neon:
            return ThemePathStyle(
                color: Color.cyan,
                lineWidth: 6,
                lineCap: .round,
                glowRadius: 8,
                dashPattern: []
            )
        case .paper:
            return ThemePathStyle(
                color: Color.brown.opacity(0.7),
                lineWidth: 4,
                lineCap: .round,
                glowRadius: 0,
                dashPattern: [8, 4]
            )
        case .minimal:
            return ThemePathStyle(
                color: Color.gray.opacity(0.6),
                lineWidth: 3,
                lineCap: .round,
                glowRadius: 0,
                dashPattern: []
            )
        case .ocean:
            return ThemePathStyle(
                color: Color.white.opacity(0.9),
                lineWidth: 6,
                lineCap: .round,
                glowRadius: 4,
                dashPattern: []
            )
        }
    }

    var nodeStyle: ThemeNodeStyle {
        switch self {
        case .standard:
            return ThemeNodeStyle(
                backgroundColor: .primary,
                textColor: .background,
                borderColor: nil,
                borderWidth: 0,
                shadowRadius: 2
            )
        case .neon:
            return ThemeNodeStyle(
                backgroundColor: .black,
                textColor: .cyan,
                borderColor: .cyan,
                borderWidth: 2,
                shadowRadius: 6
            )
        case .paper:
            return ThemeNodeStyle(
                backgroundColor: .clear,
                textColor: .brown,
                borderColor: .brown,
                borderWidth: 1.5,
                shadowRadius: 0
            )
        case .minimal:
            return ThemeNodeStyle(
                backgroundColor: .clear,
                textColor: .gray,
                borderColor: .gray,
                borderWidth: 1,
                shadowRadius: 0
            )
        case .ocean:
            return ThemeNodeStyle(
                backgroundColor: .white,
                textColor: .blue,
                borderColor: nil,
                borderWidth: 0,
                shadowRadius: 4
            )
        }
    }

    var activeNodeColor: Color {
        switch self {
        case .standard: return SettingsManager.shared.accentColor.color
        case .neon: return Color(red: 1.0, green: 0.0, blue: 0.6)
        case .paper: return Color.red.opacity(0.7)
        case .minimal: return Color.black
        case .ocean: return Color.yellow
        }
    }
}

enum ThemeBackground {
    case solid(Color)
    case gradient([Color])

    func asBackground() -> AnyShapeStyle {
        switch self {
        case .solid(let color):
            return AnyShapeStyle(color)
        case .gradient(let colors):
            return AnyShapeStyle(LinearGradient(
                colors: colors,
                startPoint: .top,
                endPoint: .bottom
            ))
        }
    }
}

struct ThemePathStyle {
    let color: Color?
    let lineWidth: CGFloat
    let lineCap: CGLineCap
    let glowRadius: CGFloat
    let dashPattern: [CGFloat]

    var effectiveColor: Color {
        color ?? SettingsManager.shared.accentColor.color
    }
}

struct ThemeNodeStyle {
    let backgroundColor: ThemeColor
    let textColor: ThemeColor
    let borderColor: ThemeColor?
    let borderWidth: CGFloat
    let shadowRadius: CGFloat
}

enum ThemeColor {
    case primary
    case background
    case clear
    case cyan
    case magenta
    case brown
    case gray
    case white
    case black
    case blue
    case yellow
    case red

    var color: Color {
        switch self {
        case .primary: return Color.primary
        case .background: return Color(UIColor.systemBackground)
        case .clear: return Color.clear
        case .cyan: return Color.cyan
        case .magenta: return Color(red: 1.0, green: 0.0, blue: 0.6)
        case .brown: return Color.brown
        case .gray: return Color.gray
        case .white: return Color.white
        case .black: return Color.black
        case .blue: return Color.blue
        case .yellow: return Color.yellow
        case .red: return Color.red
        }
    }
}

extension VisualTheme {
    func isUnlocked(totalStars: Int) -> Bool {
        totalStars >= requiredStars
    }
}
