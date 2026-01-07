//
//  PathOverlayView.swift
//  zipswift
//
//  Draws the active path using SwiftUI Canvas.
//

import SwiftUI

struct PathOverlayView: View {
    let path: [GridPoint]
    let cellSize: CGFloat
    let gridOrigin: CGPoint

    private var pathColor: Color {
        SettingsManager.shared.accentColor.color
    }

    var body: some View {
        Canvas { context, size in
            guard path.count >= 1 else { return }

            var swiftUIPath = Path()

            let firstPoint = centerForCell(path[0])
            swiftUIPath.move(to: firstPoint)

            for i in 1..<path.count {
                let point = centerForCell(path[i])
                swiftUIPath.addLine(to: point)
            }

            context.stroke(
                swiftUIPath,
                with: .color(pathColor),
                style: StrokeStyle(
                    lineWidth: 10,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        }
    }

    private func centerForCell(_ gridPoint: GridPoint) -> CGPoint {
        let x = gridOrigin.x + CGFloat(gridPoint.col) * cellSize + cellSize / 2
        let y = gridOrigin.y + CGFloat(gridPoint.row) * cellSize + cellSize / 2
        return CGPoint(x: x, y: y)
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
