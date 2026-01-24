//
//  PathOverlayView.swift
//  zipswift
//
//  Draws the active path using SwiftUI Canvas with animation support.
//

import SwiftUI

struct PathOverlayView: View {
    let path: [GridPoint]
    let cellSize: CGFloat
    let gridOrigin: CGPoint
    var isWinning: Bool = false

    @State private var pathProgress: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0
    @State private var cachedPath: Path = Path()

    private var theme: VisualTheme {
        SettingsManager.shared.visualTheme
    }

    private var pathStyle: ThemePathStyle {
        theme.pathStyle
    }

    private var pathColor: Color {
        pathStyle.effectiveColor
    }

    private var reduceMotion: Bool {
        SettingsManager.shared.reduceMotion
    }

    var body: some View {
        ZStack {
            if pathStyle.glowRadius > 0 && path.count >= 1 {
                Canvas { context, _ in
                    context.stroke(
                        cachedPath,
                        with: .color(pathColor.opacity(0.4)),
                        style: StrokeStyle(
                            lineWidth: pathStyle.lineWidth + pathStyle.glowRadius,
                            lineCap: pathStyle.lineCap,
                            lineJoin: .round
                        )
                    )
                }
                .blur(radius: pathStyle.glowRadius / 2)
            }

            Canvas { context, _ in
                guard path.count >= 1 else { return }

                if isWinning && !reduceMotion {
                    context.stroke(
                        cachedPath,
                        with: .color(pathColor.opacity(glowOpacity * 0.5)),
                        style: StrokeStyle(
                            lineWidth: pathStyle.lineWidth + 8,
                            lineCap: pathStyle.lineCap,
                            lineJoin: .round
                        )
                    )
                }

                context.stroke(
                    cachedPath.trimmedPath(from: 0, to: pathProgress),
                    with: .color(pathColor),
                    style: StrokeStyle(
                        lineWidth: pathStyle.lineWidth,
                        lineCap: pathStyle.lineCap,
                        lineJoin: .round,
                        dash: pathStyle.dashPattern
                    )
                )
            }
        }
        .onAppear {
            rebuildCachedPath()
        }
        .onChange(of: path) { _, _ in
            rebuildCachedPath()
        }
        .onChange(of: cellSize) { _, _ in
            rebuildCachedPath()
        }
        .onChange(of: gridOrigin) { _, _ in
            rebuildCachedPath()
        }
        .onChange(of: path.count) { oldCount, newCount in
            guard !reduceMotion else { return }
            if newCount > oldCount {
                withAnimation(.easeOut(duration: 0.15)) {
                    pathProgress = 1.0
                }
            }
        }
        .onChange(of: isWinning) { _, winning in
            if winning && !reduceMotion {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    glowOpacity = 1.0
                }
            } else {
                glowOpacity = 0.0
            }
        }
    }

    private func centerForCell(_ gridPoint: GridPoint) -> CGPoint {
        let x = gridOrigin.x + CGFloat(gridPoint.col) * cellSize + cellSize / 2
        let y = gridOrigin.y + CGFloat(gridPoint.row) * cellSize + cellSize / 2
        return CGPoint(x: x, y: y)
    }

    private func rebuildCachedPath() {
        guard !path.isEmpty else {
            cachedPath = Path()
            return
        }

        var newPath = Path()
        newPath.move(to: centerForCell(path[0]))
        for i in 1..<path.count {
            newPath.addLine(to: centerForCell(path[i]))
        }
        cachedPath = newPath
    }
}

#Preview {
    let samplePath = [
        GridPoint(row: 0, col: 0),
        GridPoint(row: 0, col: 1),
        GridPoint(row: 0, col: 2),
        GridPoint(row: 1, col: 2),
        GridPoint(row: 2, col: 2)
    ]

    PathOverlayView(
        path: samplePath,
        cellSize: 50,
        gridOrigin: .zero
    )
    .frame(width: 300, height: 300)
    .background(Color.gray.opacity(0.2))
}
