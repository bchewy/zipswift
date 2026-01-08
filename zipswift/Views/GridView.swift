//
//  GridView.swift
//  zipswift
//
//  Renders the 6x6 grid with numbered cells and handles touch input.
//

import SwiftUI

struct GridView: View {
    @Bindable var gameState: GameState
    let onInvalidMove: () -> Void

    @State private var invalidMovePoint: GridPoint?
    @State private var lastVisitedDuringDrag: GridPoint?
    @State private var dragStartPoint: GridPoint?
    @State private var hasMoved: Bool = false

    private var gridSize: Int { gameState.level.size }
    private let gridPadding: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            let availableSize = min(geometry.size.width, geometry.size.height)
            let cellSize = (availableSize - gridPadding * 2) / CGFloat(gridSize)
            let gridOrigin = CGPoint(x: gridPadding, y: gridPadding)

            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))

                // Grid lines
                GridLinesView(
                    gridSize: gridSize,
                    cellSize: cellSize,
                    origin: gridOrigin
                )

                // Path overlay
                PathOverlayView(
                    path: gameState.path,
                    cellSize: cellSize,
                    gridOrigin: gridOrigin
                )

                // Invalid move indicator
                if let invalidPoint = invalidMovePoint {
                    InvalidMoveIndicator(
                        point: invalidPoint,
                        cellSize: cellSize,
                        gridOrigin: gridOrigin
                    )
                }

                // Numbered cells
                ForEach(Array(gameState.level.numberedCells.keys), id: \.self) { number in
                    if let point = gameState.level.numberedCells[number] {
                        let isActive = number == gameState.currentTarget
                        NumberNodeView(
                            number: number,
                            isActive: isActive,
                            cellSize: cellSize
                        )
                        .position(centerForCell(point, cellSize: cellSize, origin: gridOrigin))
                    }
                }
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        handleDragChanged(value: value, cellSize: cellSize, origin: gridOrigin)
                    }
                    .onEnded { value in
                        handleDragEnded(value: value, cellSize: cellSize, origin: gridOrigin)
                    }
            )
            .onTapGesture { location in
                if let point = gridPointForLocation(location, cellSize: cellSize, origin: gridOrigin) {
                    handleTap(at: point)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func handleDragChanged(value: DragGesture.Value, cellSize: CGFloat, origin: CGPoint) {
        guard let point = gridPointForLocation(value.location, cellSize: cellSize, origin: origin) else {
            return
        }

        // Track the starting point for tap detection
        if dragStartPoint == nil {
            dragStartPoint = point
        }

        // Don't re-process the same cell during a continuous drag
        if point == lastVisitedDuringDrag {
            return
        }

        // If we've moved to a different cell, mark as having moved (not a tap)
        if point != dragStartPoint {
            hasMoved = true
        }

        // Check if this is a valid move (for drawing path)
        if gameState.canVisit(point) {
            gameState.visit(point)
            lastVisitedDuringDrag = point
        } else if point.isAdjacent(to: gameState.currentPosition) && !gameState.visited.contains(point) {
            // Invalid move attempt (e.g., wrong numbered cell)
            showInvalidMove(at: point)
        } else if point.isAdjacent(to: gameState.currentPosition) && gameState.visited.contains(point) {
            // Trying to visit already visited cell that's not backtracking
            showInvalidMove(at: point)
        }
    }

    private func handleDragEnded(value: DragGesture.Value, cellSize: CGFloat, origin: CGPoint) {
        // Reset drag state
        lastVisitedDuringDrag = nil
        dragStartPoint = nil
        hasMoved = false
    }

    private func handleTap(at point: GridPoint) {
        // Don't do anything if at current position or no path to undo
        guard point != gameState.currentPosition && gameState.path.count > 1 else {
            return
        }

        // If tapping on a numbered node that's in the path, undo to that specific node
        if gameState.level.isNumberedCell(point) && gameState.isInPath(point) {
            gameState.undoTo(point)
        } else {
            // Tapping anywhere else undoes back to the previous numbered node
            gameState.undoToPreviousNode()
        }
    }

    private func gridPointForLocation(_ location: CGPoint, cellSize: CGFloat, origin: CGPoint) -> GridPoint? {
        let adjustedX = location.x - origin.x
        let adjustedY = location.y - origin.y

        let col = Int(adjustedX / cellSize)
        let row = Int(adjustedY / cellSize)

        guard row >= 0 && row < gridSize && col >= 0 && col < gridSize else {
            return nil
        }

        return GridPoint(row: row, col: col)
    }

    private func centerForCell(_ point: GridPoint, cellSize: CGFloat, origin: CGPoint) -> CGPoint {
        let x = origin.x + CGFloat(point.col) * cellSize + cellSize / 2
        let y = origin.y + CGFloat(point.row) * cellSize + cellSize / 2
        return CGPoint(x: x, y: y)
    }

    private func showInvalidMove(at point: GridPoint) {
        onInvalidMove()
        invalidMovePoint = point

        // Remove the indicator after 150ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if self.invalidMovePoint == point {
                self.invalidMovePoint = nil
            }
        }
    }
}

// MARK: - Grid Lines View

struct GridLinesView: View {
    let gridSize: Int
    let cellSize: CGFloat
    let origin: CGPoint

    var body: some View {
        Canvas { context, size in
            let lineColor = Color.gray.opacity(0.3)

            // Vertical lines
            for i in 0...gridSize {
                let x = origin.x + CGFloat(i) * cellSize
                var path = Path()
                path.move(to: CGPoint(x: x, y: origin.y))
                path.addLine(to: CGPoint(x: x, y: origin.y + CGFloat(gridSize) * cellSize))
                context.stroke(path, with: .color(lineColor), lineWidth: 1)
            }

            // Horizontal lines
            for i in 0...gridSize {
                let y = origin.y + CGFloat(i) * cellSize
                var path = Path()
                path.move(to: CGPoint(x: origin.x, y: y))
                path.addLine(to: CGPoint(x: origin.x + CGFloat(gridSize) * cellSize, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: 1)
            }
        }
    }
}

// MARK: - Invalid Move Indicator

struct InvalidMoveIndicator: View {
    let point: GridPoint
    let cellSize: CGFloat
    let gridOrigin: CGPoint

    var body: some View {
        Rectangle()
            .fill(Color.red.opacity(0.5))
            .frame(width: cellSize - 4, height: cellSize - 4)
            .position(
                x: gridOrigin.x + CGFloat(point.col) * cellSize + cellSize / 2,
                y: gridOrigin.y + CGFloat(point.row) * cellSize + cellSize / 2
            )
    }
}

#Preview {
    let state = GameState(level: Levels.level1)
    GridView(gameState: state, onInvalidMove: {})
        .padding()
}
