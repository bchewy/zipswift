//
//  ThemePreviewView.swift
//  zipswift
//
//  Mini grid preview showing how a theme looks.
//

import SwiftUI

struct ThemePreviewView: View {
    let theme: VisualTheme
    let size: CGFloat

    private let miniGridSize = 3
    private let samplePath = [
        GridPoint(row: 0, col: 0),
        GridPoint(row: 0, col: 1),
        GridPoint(row: 0, col: 2),
        GridPoint(row: 1, col: 2),
        GridPoint(row: 1, col: 1)
    ]

    var body: some View {
        let cellSize = (size - 8) / CGFloat(miniGridSize)
        let gridOrigin = CGPoint(x: 4, y: 4)

        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.gridBackground.asBackground())

            Canvas { context, _ in
                let lineColor = theme.gridLineColor

                for i in 0...miniGridSize {
                    let x = gridOrigin.x + CGFloat(i) * cellSize
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: gridOrigin.y))
                    path.addLine(to: CGPoint(x: x, y: gridOrigin.y + CGFloat(miniGridSize) * cellSize))
                    context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                }

                for i in 0...miniGridSize {
                    let y = gridOrigin.y + CGFloat(i) * cellSize
                    var path = Path()
                    path.move(to: CGPoint(x: gridOrigin.x, y: y))
                    path.addLine(to: CGPoint(x: gridOrigin.x + CGFloat(miniGridSize) * cellSize, y: y))
                    context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                }
            }

            MiniPathView(
                path: samplePath,
                cellSize: cellSize,
                gridOrigin: gridOrigin,
                theme: theme
            )

            MiniNodeView(
                point: GridPoint(row: 0, col: 0),
                number: 1,
                isActive: false,
                cellSize: cellSize,
                gridOrigin: gridOrigin,
                theme: theme
            )

            MiniNodeView(
                point: GridPoint(row: 1, col: 1),
                number: 2,
                isActive: true,
                cellSize: cellSize,
                gridOrigin: gridOrigin,
                theme: theme
            )
        }
        .frame(width: size, height: size)
    }
}

struct MiniPathView: View {
    let path: [GridPoint]
    let cellSize: CGFloat
    let gridOrigin: CGPoint
    let theme: VisualTheme

    var body: some View {
        let pathStyle = theme.pathStyle

        ZStack {
            if pathStyle.glowRadius > 0 {
                pathShape
                    .stroke(
                        pathStyle.effectiveColor.opacity(0.5),
                        style: StrokeStyle(
                            lineWidth: pathStyle.lineWidth + pathStyle.glowRadius,
                            lineCap: pathStyle.lineCap,
                            lineJoin: .round,
                            dash: pathStyle.dashPattern
                        )
                    )
                    .blur(radius: pathStyle.glowRadius / 2)
            }

            pathShape
                .stroke(
                    pathStyle.effectiveColor,
                    style: StrokeStyle(
                        lineWidth: pathStyle.lineWidth / 2,
                        lineCap: pathStyle.lineCap,
                        lineJoin: .round,
                        dash: pathStyle.dashPattern.map { $0 / 2 }
                    )
                )
        }
    }

    private var pathShape: Path {
        Path { pathDraw in
            guard path.count > 1 else { return }

            for (index, point) in path.enumerated() {
                let center = centerForCell(point)
                if index == 0 {
                    pathDraw.move(to: center)
                } else {
                    pathDraw.addLine(to: center)
                }
            }
        }
    }

    private func centerForCell(_ point: GridPoint) -> CGPoint {
        CGPoint(
            x: gridOrigin.x + CGFloat(point.col) * cellSize + cellSize / 2,
            y: gridOrigin.y + CGFloat(point.row) * cellSize + cellSize / 2
        )
    }
}

struct MiniNodeView: View {
    let point: GridPoint
    let number: Int
    let isActive: Bool
    let cellSize: CGFloat
    let gridOrigin: CGPoint
    let theme: VisualTheme

    var body: some View {
        let nodeStyle = theme.nodeStyle
        let nodeSize = cellSize * 0.6
        let position = CGPoint(
            x: gridOrigin.x + CGFloat(point.col) * cellSize + cellSize / 2,
            y: gridOrigin.y + CGFloat(point.row) * cellSize + cellSize / 2
        )

        Circle()
            .fill(isActive ? theme.activeNodeColor : nodeStyle.backgroundColor.color)
            .frame(width: nodeSize, height: nodeSize)
            .overlay(
                Group {
                    if let borderColor = nodeStyle.borderColor {
                        Circle()
                            .stroke(isActive ? theme.activeNodeColor : borderColor.color, lineWidth: nodeStyle.borderWidth / 2)
                    }
                }
            )
            .overlay(
                Text("\(number)")
                    .font(.system(size: cellSize * 0.25, weight: .bold))
                    .foregroundColor(isActive ? (nodeStyle.backgroundColor == .clear ? theme.activeNodeColor : .white) : nodeStyle.textColor.color)
            )
            .shadow(radius: nodeStyle.shadowRadius / 2)
            .position(position)
    }
}

struct ThemeSelectionRow: View {
    let theme: VisualTheme
    let isSelected: Bool
    let isLocked: Bool
    let requiredStars: Int
    let onSelect: () -> Void

    var body: some View {
        Button(action: {
            if !isLocked {
                onSelect()
            }
        }) {
            HStack(spacing: 12) {
                ThemePreviewView(theme: theme, size: 60)
                    .opacity(isLocked ? 0.5 : 1.0)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(theme.displayName)
                            .font(.headline)
                            .foregroundColor(isLocked ? .secondary : .primary)

                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text(theme.description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if isLocked {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text("\(requiredStars) stars to unlock")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                if isSelected && !isLocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }
}

#Preview {
    VStack(spacing: 20) {
        ForEach(VisualTheme.allCases) { theme in
            HStack {
                ThemePreviewView(theme: theme, size: 80)
                Text(theme.displayName)
            }
        }
    }
    .padding()
}
