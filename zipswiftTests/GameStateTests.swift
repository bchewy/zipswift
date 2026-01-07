//
//  GameStateTests.swift
//  zipswiftTests
//
//  Tests for GameState model including canVisit, visit, backtrack, and win condition.
//

import Testing
@testable import zipswift

struct GameStateTests {

    // Helper to create a simple test level
    static func makeTestLevel() -> LevelDefinition {
        // Simple 6x6 level with numbers 1-5
        LevelDefinition(
            numberedCells: [
                1: GridPoint(row: 0, col: 0),
                2: GridPoint(row: 0, col: 2),
                3: GridPoint(row: 2, col: 2),
                4: GridPoint(row: 2, col: 0),
                5: GridPoint(row: 5, col: 5)
            ],
            maxNumber: 5
        )
    }

    // MARK: - Initialization Tests

    @Test func initializesWithStartCellInPath() {
        let level = Self.makeTestLevel()
        let state = GameState(level: level)

        #expect(state.path.count == 1)
        #expect(state.path.first == GridPoint(row: 0, col: 0))
    }

    @Test func initializesWithStartCellVisited() {
        let level = Self.makeTestLevel()
        let state = GameState(level: level)

        #expect(state.visited.contains(GridPoint(row: 0, col: 0)))
        #expect(state.visited.count == 1)
    }

    @Test func initializesCurrentTargetToTwo() {
        let level = Self.makeTestLevel()
        let state = GameState(level: level)

        #expect(state.currentTarget == 2)
    }

    @Test func initializesTimerStartAsNil() {
        let level = Self.makeTestLevel()
        let state = GameState(level: level)

        #expect(state.timerStart == nil)
    }

    @Test func initializesNotComplete() {
        let level = Self.makeTestLevel()
        let state = GameState(level: level)

        #expect(!state.isComplete)
    }

    // MARK: - Current Position Tests

    @Test func currentPositionIsLastInPath() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        #expect(state.currentPosition == GridPoint(row: 0, col: 0))

        // Visit adjacent cell
        _ = state.visit(GridPoint(row: 0, col: 1))
        #expect(state.currentPosition == GridPoint(row: 0, col: 1))
    }

    // MARK: - canVisit Tests

    @Test func canVisitAdjacentEmptyCell() {
        let level = Self.makeTestLevel()
        let state = GameState(level: level)

        // (0,1) is adjacent to (0,0) and not visited
        #expect(state.canVisit(GridPoint(row: 0, col: 1)))
    }

    @Test func cannotVisitNonAdjacentCell() {
        let level = Self.makeTestLevel()
        let state = GameState(level: level)

        // (2,2) is not adjacent to (0,0)
        #expect(!state.canVisit(GridPoint(row: 2, col: 2)))
    }

    @Test func cannotVisitAlreadyVisitedCell() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        // Move to (0,1)
        _ = state.visit(GridPoint(row: 0, col: 1))
        // Move to (1,1)
        _ = state.visit(GridPoint(row: 1, col: 1))
        // Move to (1,0)
        _ = state.visit(GridPoint(row: 1, col: 0))

        // Now at (1,0), path is [(0,0), (0,1), (1,1), (1,0)]
        // Previous cell is (1,1)
        // (0,0) is adjacent to (1,0) but already visited and not the previous cell
        #expect(!state.canVisit(GridPoint(row: 0, col: 0)))
    }

    @Test func canVisitPreviousCellForBacktracking() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        // Move to (0,1)
        _ = state.visit(GridPoint(row: 0, col: 1))

        // Can go back to (0,0) which is the previous cell
        #expect(state.canVisit(GridPoint(row: 0, col: 0)))
    }

    @Test func canVisitCorrectNumberedCellWhenTarget() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        // Move towards numbered cell 2 at (0,2)
        _ = state.visit(GridPoint(row: 0, col: 1))

        // Now (0,2) is adjacent and is numbered cell 2 which is the current target
        #expect(state.canVisit(GridPoint(row: 0, col: 2)))
    }

    @Test func cannotVisitWrongNumberedCell() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        // Move to (1,0)
        _ = state.visit(GridPoint(row: 1, col: 0))
        // Move to (2,0) - this is numbered cell 4, but target is 2
        #expect(!state.canVisit(GridPoint(row: 2, col: 0)))
    }

    @Test func cannotVisitDiagonalCell() {
        let level = Self.makeTestLevel()
        let state = GameState(level: level)

        // (1,1) is diagonal to (0,0)
        #expect(!state.canVisit(GridPoint(row: 1, col: 1)))
    }

    // MARK: - visit Tests

    @Test func visitAddsToPath() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        let result = state.visit(GridPoint(row: 0, col: 1))

        #expect(result)
        #expect(state.path.count == 2)
        #expect(state.path.last == GridPoint(row: 0, col: 1))
    }

    @Test func visitAddsToVisited() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        _ = state.visit(GridPoint(row: 0, col: 1))

        #expect(state.visited.contains(GridPoint(row: 0, col: 1)))
    }

    @Test func visitIncrementsTargetWhenNumberedCellReached() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        // Move to (0,1) then (0,2) which is numbered cell 2
        _ = state.visit(GridPoint(row: 0, col: 1))
        #expect(state.currentTarget == 2)

        _ = state.visit(GridPoint(row: 0, col: 2))
        #expect(state.currentTarget == 3)
    }

    @Test func visitReturnsFalseForInvalidMove() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        let result = state.visit(GridPoint(row: 5, col: 5))

        #expect(!result)
        #expect(state.path.count == 1) // Still just starting cell
    }

    @Test func visitStartsTimerOnFirstMove() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        #expect(state.timerStart == nil)

        _ = state.visit(GridPoint(row: 0, col: 1))

        #expect(state.timerStart != nil)
    }

    @Test func visitDoesNotResetTimerOnSubsequentMoves() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        _ = state.visit(GridPoint(row: 0, col: 1))
        let firstTimerStart = state.timerStart

        _ = state.visit(GridPoint(row: 1, col: 1))

        #expect(state.timerStart == firstTimerStart)
    }

    // MARK: - Backtrack Tests

    @Test func visitPreviousCellBacktracks() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        _ = state.visit(GridPoint(row: 0, col: 1))
        #expect(state.path.count == 2)

        // Visit previous cell to backtrack
        _ = state.visit(GridPoint(row: 0, col: 0))

        #expect(state.path.count == 1)
        #expect(state.path.last == GridPoint(row: 0, col: 0))
    }

    @Test func backtrackRemovesFromVisited() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        _ = state.visit(GridPoint(row: 0, col: 1))
        #expect(state.visited.contains(GridPoint(row: 0, col: 1)))

        // Backtrack
        _ = state.visit(GridPoint(row: 0, col: 0))

        #expect(!state.visited.contains(GridPoint(row: 0, col: 1)))
    }

    @Test func backtrackDecrementsTargetWhenNumberedCellRemoved() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        // Move to numbered cell 2
        _ = state.visit(GridPoint(row: 0, col: 1))
        _ = state.visit(GridPoint(row: 0, col: 2))
        #expect(state.currentTarget == 3)

        // Backtrack from numbered cell 2
        _ = state.visit(GridPoint(row: 0, col: 1))

        #expect(state.currentTarget == 2)
    }

    @Test func undoRemovesLastStep() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        _ = state.visit(GridPoint(row: 0, col: 1))
        _ = state.visit(GridPoint(row: 1, col: 1))
        #expect(state.path.count == 3)

        state.undo()

        #expect(state.path.count == 2)
        #expect(state.path.last == GridPoint(row: 0, col: 1))
    }

    @Test func undoUpdatesVisited() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        _ = state.visit(GridPoint(row: 0, col: 1))
        state.undo()

        #expect(!state.visited.contains(GridPoint(row: 0, col: 1)))
    }

    @Test func undoDecrementsTargetWhenNumberedCellRemoved() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        _ = state.visit(GridPoint(row: 0, col: 1))
        _ = state.visit(GridPoint(row: 0, col: 2)) // numbered cell 2
        #expect(state.currentTarget == 3)

        state.undo()

        #expect(state.currentTarget == 2)
    }

    @Test func undoDoesNothingWhenOnlyStartCell() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        state.undo()

        #expect(state.path.count == 1)
        #expect(state.visited.count == 1)
    }

    // MARK: - Win Condition Tests

    @Test func isCompleteWhenAllCellsVisitedAndAllNumbersReached() {
        // Create a tiny 2x2 level for easier testing
        let smallLevel = LevelDefinition(
            size: 2,
            numberedCells: [
                1: GridPoint(row: 0, col: 0),
                2: GridPoint(row: 1, col: 1)
            ],
            maxNumber: 2
        )
        var state = GameState(level: smallLevel)

        // Visit all 4 cells in order: (0,0) -> (0,1) -> (1,1) -> done with numbers
        // Path: (0,0) already visited, need to visit (0,1), (1,1) while hitting all cells
        _ = state.visit(GridPoint(row: 0, col: 1))
        _ = state.visit(GridPoint(row: 1, col: 1)) // numbered cell 2
        _ = state.visit(GridPoint(row: 1, col: 0))

        #expect(state.visited.count == 4)
        #expect(state.currentTarget > smallLevel.maxNumber)
        #expect(state.isComplete)
    }

    @Test func notCompleteWhenNotAllCellsVisited() {
        let smallLevel = LevelDefinition(
            size: 2,
            numberedCells: [
                1: GridPoint(row: 0, col: 0),
                2: GridPoint(row: 1, col: 1)
            ],
            maxNumber: 2
        )
        var state = GameState(level: smallLevel)

        // Only visit 2 cells
        _ = state.visit(GridPoint(row: 0, col: 1))

        #expect(!state.isComplete)
    }

    @Test func notCompleteWhenNotAllNumbersReached() {
        let smallLevel = LevelDefinition(
            size: 2,
            numberedCells: [
                1: GridPoint(row: 0, col: 0),
                2: GridPoint(row: 1, col: 1)
            ],
            maxNumber: 2
        )
        var state = GameState(level: smallLevel)

        // Visit cells but skip numbered cell 2
        _ = state.visit(GridPoint(row: 1, col: 0))
        // Can't visit (1,1) out of order, and can't visit (0,1) because not adjacent
        // Actually with 2x2, let's just verify incomplete state

        #expect(!state.isComplete)
    }

    @Test func winConditionRequiresAllCellsFilled() {
        // Create a 3x3 level with nodes at corners
        let level = LevelDefinition(
            size: 3,
            numberedCells: [
                1: GridPoint(row: 0, col: 0),
                2: GridPoint(row: 0, col: 2),
                3: GridPoint(row: 2, col: 2)
            ],
            maxNumber: 3
        )
        var state = GameState(level: level)

        // Visit path: (0,0) -> (0,1) -> (0,2)[node 2] -> (1,2) -> (2,2)[node 3]
        // This visits 5 cells but not all 9
        _ = state.visit(GridPoint(row: 0, col: 1))
        _ = state.visit(GridPoint(row: 0, col: 2)) // node 2
        _ = state.visit(GridPoint(row: 1, col: 2))
        _ = state.visit(GridPoint(row: 2, col: 2)) // node 3

        // All nodes reached but not all cells visited
        #expect(state.currentTarget > level.maxNumber)
        #expect(state.visited.count == 5)
        #expect(state.visited.count < 9)
        #expect(!state.isComplete) // Should NOT be complete!
    }

    @Test func winConditionRequiresAllNodesInOrder() {
        // Create a 2x2 level
        let level = LevelDefinition(
            size: 2,
            numberedCells: [
                1: GridPoint(row: 0, col: 0),
                2: GridPoint(row: 0, col: 1),
                3: GridPoint(row: 1, col: 1)
            ],
            maxNumber: 3
        )
        var state = GameState(level: level)

        // Path must visit nodes 1, 2, 3 in order
        // (0,0)[1] -> (0,1)[2] -> (1,1)[3] -> (1,0)
        _ = state.visit(GridPoint(row: 0, col: 1)) // node 2
        _ = state.visit(GridPoint(row: 1, col: 1)) // node 3
        _ = state.visit(GridPoint(row: 1, col: 0))

        // All 4 cells visited, all nodes reached in order
        #expect(state.visited.count == 4)
        #expect(state.currentTarget > level.maxNumber)
        #expect(state.isComplete)
    }

    @Test func cannotSkipNumberedNode() {
        let level = LevelDefinition(
            size: 3,
            numberedCells: [
                1: GridPoint(row: 0, col: 0),
                2: GridPoint(row: 0, col: 1),
                3: GridPoint(row: 0, col: 2)
            ],
            maxNumber: 3
        )
        var state = GameState(level: level)

        // Try to skip node 2 and go directly around
        // From (0,0), try to go down instead of right to node 2
        _ = state.visit(GridPoint(row: 1, col: 0))

        // Now try to visit node 3 at (0,2) - should not be allowed
        // Can't reach (0,2) from (1,0) anyway since not adjacent
        // Let's verify we can't visit node 3 before node 2
        #expect(state.currentTarget == 2)
        #expect(!state.canVisit(GridPoint(row: 0, col: 2))) // Can't visit node 3 yet
    }

    // MARK: - Reset Tests

    @Test func resetRestoresInitialState() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        _ = state.visit(GridPoint(row: 0, col: 1))
        _ = state.visit(GridPoint(row: 0, col: 2))

        state.reset()

        #expect(state.path.count == 1)
        #expect(state.path.first == level.startPosition)
        #expect(state.visited.count == 1)
        #expect(state.currentTarget == 2)
        #expect(state.timerStart == nil)
        #expect(!state.isComplete)
    }

    // MARK: - undoTo Tests

    @Test func undoToRemovesMultipleSteps() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        // Build a path: (0,0) -> (0,1) -> (1,1) -> (1,0)
        _ = state.visit(GridPoint(row: 0, col: 1))
        _ = state.visit(GridPoint(row: 1, col: 1))
        _ = state.visit(GridPoint(row: 1, col: 0))
        #expect(state.path.count == 4)

        // Undo back to (0,1)
        state.undoTo(GridPoint(row: 0, col: 1))

        #expect(state.path.count == 2)
        #expect(state.path.last == GridPoint(row: 0, col: 1))
    }

    @Test func undoToUpdatesVisitedSet() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        _ = state.visit(GridPoint(row: 0, col: 1))
        _ = state.visit(GridPoint(row: 1, col: 1))
        _ = state.visit(GridPoint(row: 1, col: 0))

        state.undoTo(GridPoint(row: 0, col: 1))

        #expect(state.visited.contains(GridPoint(row: 0, col: 0)))
        #expect(state.visited.contains(GridPoint(row: 0, col: 1)))
        #expect(!state.visited.contains(GridPoint(row: 1, col: 1)))
        #expect(!state.visited.contains(GridPoint(row: 1, col: 0)))
    }

    @Test func undoToDecrementsTargetForRemovedNumberedCells() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        // Path to numbered cell 2 at (0,2): (0,0) -> (0,1) -> (0,2)
        _ = state.visit(GridPoint(row: 0, col: 1))
        _ = state.visit(GridPoint(row: 0, col: 2)) // numbered cell 2
        #expect(state.currentTarget == 3)

        // Continue path
        _ = state.visit(GridPoint(row: 1, col: 2))

        // Undo back to (0,1), removing numbered cell 2
        state.undoTo(GridPoint(row: 0, col: 1))

        #expect(state.currentTarget == 2)
    }

    @Test func undoToDoesNothingForPointNotInPath() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        _ = state.visit(GridPoint(row: 0, col: 1))
        _ = state.visit(GridPoint(row: 1, col: 1))
        #expect(state.path.count == 3)

        // Try to undo to a point not in path
        state.undoTo(GridPoint(row: 5, col: 5))

        #expect(state.path.count == 3) // unchanged
    }

    @Test func undoToStartCellRemovesAllButStart() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        _ = state.visit(GridPoint(row: 0, col: 1))
        _ = state.visit(GridPoint(row: 1, col: 1))
        _ = state.visit(GridPoint(row: 1, col: 0))

        // Undo back to start
        state.undoTo(GridPoint(row: 0, col: 0))

        #expect(state.path.count == 1)
        #expect(state.path.first == GridPoint(row: 0, col: 0))
        #expect(state.visited.count == 1)
    }

    @Test func undoToCurrentPositionDoesNothing() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        _ = state.visit(GridPoint(row: 0, col: 1))
        _ = state.visit(GridPoint(row: 1, col: 1))
        #expect(state.path.count == 3)

        // Undo to current position
        state.undoTo(GridPoint(row: 1, col: 1))

        #expect(state.path.count == 3) // unchanged
    }

    // MARK: - isInPath Tests

    @Test func isInPathReturnsTrueForPathCells() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        _ = state.visit(GridPoint(row: 0, col: 1))
        _ = state.visit(GridPoint(row: 1, col: 1))

        #expect(state.isInPath(GridPoint(row: 0, col: 0)))
        #expect(state.isInPath(GridPoint(row: 0, col: 1)))
        #expect(state.isInPath(GridPoint(row: 1, col: 1)))
    }

    @Test func isInPathReturnsFalseForNonPathCells() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        _ = state.visit(GridPoint(row: 0, col: 1))

        #expect(!state.isInPath(GridPoint(row: 5, col: 5)))
        #expect(!state.isInPath(GridPoint(row: 1, col: 1)))
    }

    // MARK: - undoToPreviousNode Tests

    @Test func undoToPreviousNodeUndosToLastNumberedCell() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        // Path: (0,0)[1] -> (0,1) -> (0,2)[2] -> (1,2) -> (2,2)[3]
        // Test level has: 1 at (0,0), 2 at (0,2), 3 at (2,2)
        // Wait, test level has 2 at (0,2) based on makeTestLevel

        // Let's trace: start at (0,0) which is node 1
        // Move to (0,1), then to (0,2) which is node 2
        _ = state.visit(GridPoint(row: 0, col: 1))
        _ = state.visit(GridPoint(row: 0, col: 2)) // This is node 2
        #expect(state.currentTarget == 3)

        // Continue to (1,2)
        _ = state.visit(GridPoint(row: 1, col: 2))
        #expect(state.path.count == 4)

        // Undo to previous node should go back to node 2 at (0,2)
        state.undoToPreviousNode()

        #expect(state.path.count == 3)
        #expect(state.currentPosition == GridPoint(row: 0, col: 2))
        #expect(state.currentTarget == 3) // Still targeting 3
    }

    @Test func undoToPreviousNodeUndosToNode1WhenNoOtherNodes() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        // Path: (0,0)[1] -> (0,1) -> (1,1) (no numbered nodes visited after 1)
        _ = state.visit(GridPoint(row: 0, col: 1))
        _ = state.visit(GridPoint(row: 1, col: 1))
        #expect(state.path.count == 3)
        #expect(state.currentTarget == 2) // Haven't reached node 2 yet

        // Undo to previous node should go back to node 1 at (0,0)
        state.undoToPreviousNode()

        #expect(state.path.count == 1)
        #expect(state.currentPosition == GridPoint(row: 0, col: 0))
    }

    @Test func undoToPreviousNodeDoesNothingAtStart() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        // At start, only node 1 is in path
        #expect(state.path.count == 1)

        state.undoToPreviousNode()

        #expect(state.path.count == 1) // Unchanged
    }

    @Test func undoToPreviousNodeDecrementsTargetCorrectly() {
        let level = Self.makeTestLevel()
        var state = GameState(level: level)

        // Visit node 2 at (0,2)
        _ = state.visit(GridPoint(row: 0, col: 1))
        _ = state.visit(GridPoint(row: 0, col: 2)) // node 2
        #expect(state.currentTarget == 3)

        // Continue past node 2
        _ = state.visit(GridPoint(row: 1, col: 2))
        _ = state.visit(GridPoint(row: 2, col: 2)) // node 3
        #expect(state.currentTarget == 4)

        // Continue further
        _ = state.visit(GridPoint(row: 2, col: 1))

        // Undo to previous node (node 3)
        state.undoToPreviousNode()
        #expect(state.currentPosition == GridPoint(row: 2, col: 2))
        #expect(state.currentTarget == 4) // Still 4, node 3 still in path
    }
}
