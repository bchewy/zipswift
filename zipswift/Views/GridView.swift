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
    var hintCells: [GridPoint] = []

    @State private var invalidMovePoint: GridPoint?
    @State private var lastVisitedDuringDrag: GridPoint?
    @State private var dragStartPoint: GridPoint?
    @State private var hasMoved: Bool = false
    @State private var recentlyVisitedCell: GridPoint?
    @State private var recentlyReachedNode: Int?

    private var gridSize: Int { gameState.level.size }
    private let gridPadding: CGFloat = 8

    private var theme: VisualTheme {
        SettingsManager.shared.visualTheme
    }

    var body: some View {
        GeometryReader { geometry in
            let availableSize = min(geometry.size.width, geometry.size.height)
            let cellSize = (availableSize - gridPadding * 2) / CGFloat(gridSize)
            let gridOrigin = CGPoint(x: gridPadding, y: gridPadding)

            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.gridBackground.asBackground())

                // Grid lines
                GridLinesView(
                    gridSize: gridSize,
                    cellSize: cellSize,
                    origin: gridOrigin,
                    lineColor: theme.gridLineColor
                )

                // Path overlay
                PathOverlayView(
                    path: gameState.path,
                    cellSize: cellSize,
                    gridOrigin: gridOrigin,
                    isWinning: gameState.isComplete
                )

                // Cell visit bounce indicator
                if let visitedCell = recentlyVisitedCell {
                    CellVisitIndicator(
                        point: visitedCell,
                        cellSize: cellSize,
                        gridOrigin: gridOrigin
                    )
                }

                // Hint indicators
                ForEach(Array(hintCells.enumerated()), id: \.offset) { index, hintPoint in
                    HintIndicator(
                        point: hintPoint,
                        cellSize: cellSize,
                        gridOrigin: gridOrigin,
                        order: index
                    )
                }

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
                        let wasJustReached = recentlyReachedNode == number
                        NumberNodeView(
                            number: number,
                            isActive: isActive,
                            cellSize: cellSize,
                            wasJustReached: wasJustReached
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
            let previousTarget = gameState.currentTarget
            gameState.visit(point)
            lastVisitedDuringDrag = point
            triggerCellVisitAnimation(at: point)

            if gameState.currentTarget > previousTarget {
                triggerNodeReachedAnimation(node: previousTarget)
            }
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if self.invalidMovePoint == point {
                self.invalidMovePoint = nil
            }
        }
    }

    private func triggerCellVisitAnimation(at point: GridPoint) {
        recentlyVisitedCell = point

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if self.recentlyVisitedCell == point {
                self.recentlyVisitedCell = nil
            }
        }
    }

    private func triggerNodeReachedAnimation(node: Int) {
        recentlyReachedNode = node

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.recentlyReachedNode == node {
                self.recentlyReachedNode = nil
            }
        }
    }
}

// MARK: - Grid Lines View

struct GridLinesView: View {
    let gridSize: Int
    let cellSize: CGFloat
    let origin: CGPoint
    var lineColor: Color = Color.gray.opacity(0.3)

    var body: some View {
        Canvas { context, _ in

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

// MARK: - Cell Visit Indicator

struct CellVisitIndicator: View {
    let point: GridPoint
    let cellSize: CGFloat
    let gridOrigin: CGPoint

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.8

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    private var reduceMotion: Bool {
        SettingsManager.shared.reduceMotion
    }

    var body: some View {
        Circle()
            .fill(accentColor.opacity(opacity * 0.3))
            .frame(width: cellSize * 0.5, height: cellSize * 0.5)
            .scaleEffect(scale)
            .position(
                x: gridOrigin.x + CGFloat(point.col) * cellSize + cellSize / 2,
                y: gridOrigin.y + CGFloat(point.row) * cellSize + cellSize / 2
            )
            .onAppear {
                if !reduceMotion {
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                        scale = 1.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeOut(duration: 0.15)) {
                            scale = 1.0
                            opacity = 0.0
                        }
                    }
                }
            }
    }
}

// MARK: - Hint Indicator

struct HintIndicator: View {
    let point: GridPoint
    let cellSize: CGFloat
    let gridOrigin: CGPoint
    let order: Int

    @State private var isPulsing = false

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        Circle()
            .fill(accentColor.opacity(0.3))
            .frame(width: cellSize * 0.6, height: cellSize * 0.6)
            .overlay(
                Circle()
                    .stroke(accentColor, lineWidth: 2)
            )
            .overlay(
                Text("\(order + 1)")
                    .font(.system(size: cellSize * 0.25, weight: .bold))
                    .foregroundColor(accentColor)
            )
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .position(
                x: gridOrigin.x + CGFloat(point.col) * cellSize + cellSize / 2,
                y: gridOrigin.y + CGFloat(point.row) * cellSize + cellSize / 2
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
                    .delay(Double(order) * 0.2)
                ) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Invalid Move Indicator

struct InvalidMoveIndicator: View {
    let point: GridPoint
    let cellSize: CGFloat
    let gridOrigin: CGPoint

    @State private var shakeOffset: CGFloat = 0

    private var reduceMotion: Bool {
        SettingsManager.shared.reduceMotion
    }

    var body: some View {
        Rectangle()
            .fill(Color.red.opacity(0.5))
            .frame(width: cellSize - 4, height: cellSize - 4)
            .offset(x: shakeOffset)
            .position(
                x: gridOrigin.x + CGFloat(point.col) * cellSize + cellSize / 2,
                y: gridOrigin.y + CGFloat(point.row) * cellSize + cellSize / 2
            )
            .onAppear {
                if !reduceMotion {
                    animateShake()
                }
            }
    }

    private func animateShake() {
        withAnimation(.linear(duration: 0.05)) {
            shakeOffset = 6
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.linear(duration: 0.05)) {
                shakeOffset = -6
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.linear(duration: 0.05)) {
                shakeOffset = 4
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.linear(duration: 0.05)) {
                shakeOffset = 0
            }
        }
    }
}

#Preview {
    let state = GameState(level: Levels.level1)
    GridView(gameState: state, onInvalidMove: {})
        .padding()
}
