//
//  LevelGeneratorTests.swift
//  zipswiftTests
//
//  Tests for random level generation that guarantees solvable puzzles.
//

import Testing
@testable import zipswift

struct LevelGeneratorTests {

    // MARK: - Path Generation Tests

    @Test func generatesPathCoveringAllCells() {
        let path = LevelGenerator.generateHamiltonianPath(size: 6)

        #expect(path.count == 36)
    }

    @Test func generatedPathHasNoDuplicates() {
        let path = LevelGenerator.generateHamiltonianPath(size: 6)
        let uniqueCells = Set(path)

        #expect(uniqueCells.count == 36)
    }

    @Test func generatedPathIsContiguous() {
        let path = LevelGenerator.generateHamiltonianPath(size: 6)

        // Each consecutive pair should be adjacent
        for i in 0..<(path.count - 1) {
            #expect(path[i].isAdjacent(to: path[i + 1]),
                   "Path step \(i) to \(i+1) is not adjacent: \(path[i]) -> \(path[i+1])")
        }
    }

    @Test func generatedPathStartsAtOrigin() {
        let path = LevelGenerator.generateHamiltonianPath(size: 6)

        #expect(path.first == GridPoint(row: 0, col: 0))
    }

    @Test func generatesValidPathForSmallerGrid() {
        let path = LevelGenerator.generateHamiltonianPath(size: 4)

        #expect(path.count == 16)
        #expect(Set(path).count == 16)

        for i in 0..<(path.count - 1) {
            #expect(path[i].isAdjacent(to: path[i + 1]))
        }
    }

    // MARK: - Level Generation Tests

    @Test func generatesLevelWithCorrectSize() {
        let level = LevelGenerator.generateLevel(size: 6, numberOfNodes: 8)

        #expect(level.size == 6)
    }

    @Test func generatesLevelWithCorrectNumberOfNodes() {
        let level = LevelGenerator.generateLevel(size: 6, numberOfNodes: 8)

        #expect(level.numberedCells.count == 8)
        #expect(level.maxNumber == 8)
    }

    @Test func generatesLevelWithNode1AtStart() {
        let level = LevelGenerator.generateLevel(size: 6, numberOfNodes: 8)

        #expect(level.startPosition == GridPoint(row: 0, col: 0))
        #expect(level.numberedCells[1] == GridPoint(row: 0, col: 0))
    }

    @Test func generatesLevelWithAllNodesNumberedCorrectly() {
        let level = LevelGenerator.generateLevel(size: 6, numberOfNodes: 10)

        for i in 1...10 {
            #expect(level.numberedCells[i] != nil, "Missing numbered cell \(i)")
        }
    }

    @Test func generatedLevelIsSolvable() {
        // Generate a level and verify it can be solved by following the solution path
        let level = LevelGenerator.generateLevel(size: 6, numberOfNodes: 8)
        var state = GameState(level: level)

        // Get the solution path
        guard let solutionPath = level.solutionPath else {
            Issue.record("Level should have a solution path")
            return
        }

        // Follow the solution path (skip first cell as it's already visited)
        for i in 1..<solutionPath.count {
            let canVisit = state.canVisit(solutionPath[i])
            #expect(canVisit, "Cannot visit cell \(i): \(solutionPath[i])")
            if canVisit {
                state.visit(solutionPath[i])
            }
        }

        #expect(state.isComplete, "Level should be completable via solution path")
    }

    @Test func generatedLevelSolutionPathIsValid() {
        let level = LevelGenerator.generateLevel(size: 6, numberOfNodes: 8)

        guard let path = level.solutionPath else {
            Issue.record("Level should have solution path")
            return
        }

        // Path should cover all cells
        #expect(path.count == 36)

        // Path should be contiguous
        for i in 0..<(path.count - 1) {
            #expect(path[i].isAdjacent(to: path[i + 1]))
        }

        // Numbered cells should appear in order along the path
        var lastIndex = -1
        for number in 1...level.maxNumber {
            guard let cell = level.numberedCells[number],
                  let index = path.firstIndex(of: cell) else {
                Issue.record("Numbered cell \(number) not in path")
                continue
            }
            #expect(index > lastIndex, "Numbered cell \(number) appears before previous cell in path")
            lastIndex = index
        }
    }

    // MARK: - Randomness Tests

    @Test func generatesDifferentPathsOnMultipleCalls() {
        // Generate multiple paths and verify they're not all identical
        var paths: [[GridPoint]] = []
        for _ in 0..<5 {
            paths.append(LevelGenerator.generateHamiltonianPath(size: 6))
        }

        // At least some paths should be different (not all identical)
        let uniquePaths = Set(paths.map { $0.map { "\($0.row),\($0.col)" }.joined(separator: "|") })
        #expect(uniquePaths.count > 1, "Expected different random paths")
    }

    // MARK: - Difficulty Scaling Tests

    @Test func generatesEasyLevel() {
        let level = LevelGenerator.generateLevel(difficulty: .easy)

        // Easy levels have more numbered nodes (more guidance)
        #expect(level.maxNumber >= 10)
    }

    @Test func generatesMediumLevel() {
        let level = LevelGenerator.generateLevel(difficulty: .medium)

        #expect(level.maxNumber >= 7 && level.maxNumber <= 10)
    }

    @Test func generatesHardLevel() {
        let level = LevelGenerator.generateLevel(difficulty: .hard)

        // Hard levels have fewer numbered nodes (less guidance)
        #expect(level.maxNumber <= 7)
    }
}
