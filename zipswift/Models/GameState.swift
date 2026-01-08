//
//  GameState.swift
//  zipswift
//
//  Manages the state of a game session.
//

import Foundation

@Observable
class GameState {
    let level: LevelDefinition
    private(set) var path: [GridPoint]
    private(set) var visited: Set<GridPoint>
    private(set) var currentTarget: Int
    private(set) var timerStart: Date?
    private(set) var isComplete: Bool

    init(level: LevelDefinition) {
        self.level = level
        let startPos = level.startPosition
        self.path = [startPos]
        self.visited = [startPos]
        self.currentTarget = 2
        self.timerStart = nil
        self.isComplete = false
    }

    var currentPosition: GridPoint {
        path.last!
    }

    var totalCells: Int {
        level.size * level.size
    }

    func canVisit(_ point: GridPoint) -> Bool {
        let current = currentPosition

        // Must be adjacent
        guard current.isAdjacent(to: point) else { return false }

        // Check if it's the previous cell (backtracking)
        if path.count >= 2 && path[path.count - 2] == point {
            return true
        }

        // If already visited, cannot visit again (unless backtracking handled above)
        if visited.contains(point) {
            return false
        }

        // If it's a numbered cell, must be the current target
        if let number = level.numberAt(point) {
            return number == currentTarget
        }

        // Empty cell, can visit
        return true
    }

    @discardableResult
    func visit(_ point: GridPoint) -> Bool {
        guard canVisit(point) else { return false }

        // Start timer on first move
        if timerStart == nil {
            timerStart = Date()
        }

        // Check if backtracking
        if path.count >= 2 && path[path.count - 2] == point {
            backtrack()
            return true
        }

        // Normal forward move
        path.append(point)
        visited.insert(point)

        // If numbered cell reached, increment target
        if let number = level.numberAt(point), number == currentTarget {
            currentTarget += 1
        }

        // Check win condition
        checkWinCondition()

        return true
    }

    func undo() {
        guard path.count > 1 else { return }
        backtrack()
    }

    func undoTo(_ point: GridPoint) {
        // Find the index of the point in the path
        guard let targetIndex = path.firstIndex(of: point) else { return }

        // If it's the current position, do nothing
        if targetIndex == path.count - 1 { return }

        // Remove all cells after the target point
        while path.count > targetIndex + 1 {
            backtrack()
        }
    }

    func isInPath(_ point: GridPoint) -> Bool {
        path.contains(point)
    }

    func undoToPreviousNode() {
        // If only at start, do nothing
        guard path.count > 1 else { return }

        // Find the last numbered node in path (excluding current position if it's numbered)
        // We want to undo TO that node, so search from second-to-last backwards
        var targetIndex = 0 // Default to start (node 1)

        for i in stride(from: path.count - 2, through: 0, by: -1) {
            let point = path[i]
            if level.isNumberedCell(point) {
                targetIndex = i
                break
            }
        }

        // Undo back to the target
        while path.count > targetIndex + 1 {
            backtrack()
        }
    }

    private func backtrack() {
        guard path.count > 1 else { return }

        let removed = path.removeLast()
        visited.remove(removed)

        // If removed cell was a numbered cell, decrement target
        if let number = level.numberAt(removed) {
            if number == currentTarget - 1 {
                currentTarget -= 1
            }
        }
    }

    private func checkWinCondition() {
        // Win requires:
        // 1. All cells visited (36 cells for 6x6 grid)
        // 2. All numbered nodes reached in correct order

        let allCellsVisited = visited.count == totalCells
        let allNumbersReached = currentTarget > level.maxNumber

        // Additional verification: ensure all numbered nodes are in the path in correct order
        let nodesInCorrectOrder = verifyNodesInOrder()

        isComplete = allCellsVisited && allNumbersReached && nodesInCorrectOrder
    }

    private func verifyNodesInOrder() -> Bool {
        // Find the index of each numbered node in the path
        var lastIndex = -1

        for number in 1...level.maxNumber {
            guard let nodePosition = level.numberedCells[number],
                  let pathIndex = path.firstIndex(of: nodePosition) else {
                // Node not found in path
                return false
            }

            // Ensure this node appears after the previous node in the path
            if pathIndex <= lastIndex {
                return false
            }
            lastIndex = pathIndex
        }

        return true
    }

    func reset() {
        let startPos = level.startPosition
        path = [startPos]
        visited = [startPos]
        currentTarget = 2
        timerStart = nil
        isComplete = false
    }

    func getHintCells(count: Int = 3) -> [GridPoint] {
        guard let solutionPath = level.solutionPath else { return [] }

        guard let currentIndex = solutionPath.firstIndex(of: currentPosition) else {
            return []
        }

        var hintCells: [GridPoint] = []
        var nextIndex = currentIndex + 1

        while hintCells.count < count && nextIndex < solutionPath.count {
            let cell = solutionPath[nextIndex]
            if !visited.contains(cell) {
                hintCells.append(cell)
            }
            nextIndex += 1
        }

        return hintCells
    }
}
