//
//  LevelGenerator.swift
//  zipswift
//
//  Generates random but always solvable puzzle levels using Hamiltonian paths.
//

import Foundation

enum GridSize: Int, CaseIterable, Codable {
    case quick = 5
    case classic = 6
    case extended = 7
    case marathon = 8

    var size: Int { rawValue }

    var displayName: String {
        switch self {
        case .quick: return "5×5 Quick"
        case .classic: return "6×6 Classic"
        case .extended: return "7×7 Extended"
        case .marathon: return "8×8 Marathon"
        }
    }

    var shortName: String {
        "\(size)×\(size)"
    }
}

enum Difficulty: String, CaseIterable, Codable {
    case easy
    case medium
    case hard

    func nodeCount(for gridSize: GridSize) -> Int {
        switch (self, gridSize) {
        case (.easy, .quick): return 8
        case (.medium, .quick): return 5
        case (.hard, .quick): return 3

        case (.easy, .classic): return 12
        case (.medium, .classic): return 8
        case (.hard, .classic): return 5

        case (.easy, .extended): return 16
        case (.medium, .extended): return 11
        case (.hard, .extended): return 7

        case (.easy, .marathon): return 20
        case (.medium, .marathon): return 14
        case (.hard, .marathon): return 9
        }
    }

    var nodeCount: Int {
        nodeCount(for: .classic)
    }

    var iconName: String {
        switch self {
        case .easy: return "DifficultyEasy"
        case .medium: return "DifficultyMedium"
        case .hard: return "DifficultyHard"
        }
    }
}

struct LevelGenerator {

    /// Generates a random Hamiltonian path (visits every cell exactly once)
    /// Uses backtracking with random neighbor selection
    static func generateHamiltonianPath(size: Int) -> [GridPoint] {
        let totalCells = size * size
        var path: [GridPoint] = []
        var visited: Set<GridPoint> = []

        // Always start at (0,0) for consistency
        let start = GridPoint(row: 0, col: 0)

        func getNeighbors(_ point: GridPoint) -> [GridPoint] {
            let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]
            return directions.compactMap { dr, dc in
                let newRow = point.row + dr
                let newCol = point.col + dc
                guard newRow >= 0 && newRow < size && newCol >= 0 && newCol < size else {
                    return nil
                }
                return GridPoint(row: newRow, col: newCol)
            }
        }

        func findPath(current: GridPoint) -> Bool {
            path.append(current)
            visited.insert(current)

            if path.count == totalCells {
                return true // Found complete path
            }

            // Get unvisited neighbors in random order
            let neighbors = getNeighbors(current)
                .filter { !visited.contains($0) }
                .shuffled()

            for neighbor in neighbors {
                if findPath(current: neighbor) {
                    return true
                }
            }

            // Backtrack
            path.removeLast()
            visited.remove(current)
            return false
        }

        _ = findPath(current: start)
        return path
    }

    /// Generates a complete level with numbered nodes placed along a valid path
    static func generateLevel(size: Int = 6, numberOfNodes: Int) -> LevelDefinition {
        let path = generateHamiltonianPath(size: size)

        var numberedCells: [Int: GridPoint] = [:]

        // Always place node 1 at start
        numberedCells[1] = path[0]

        // Always place last node at end
        numberedCells[numberOfNodes] = path[path.count - 1]

        // Distribute remaining nodes evenly along the path
        if numberOfNodes > 2 {
            let remaining = numberOfNodes - 2
            // Calculate spacing to distribute nodes evenly
            let usableRange = path.count - 2 // Exclude first and last
            let spacing = Double(usableRange) / Double(remaining + 1)

            for i in 1...remaining {
                let index = Int(Double(i) * spacing)
                numberedCells[i + 1] = path[index]
            }
        }

        return LevelDefinition(
            size: size,
            numberedCells: numberedCells,
            maxNumber: numberOfNodes,
            solutionPath: path
        )
    }

    /// Generates a level with difficulty-based node count
    static func generateLevel(difficulty: Difficulty, size: Int = 6) -> LevelDefinition {
        return generateLevel(size: size, numberOfNodes: difficulty.nodeCount)
    }

    /// Generates a level with difficulty and grid size
    static func generateLevel(difficulty: Difficulty, gridSize: GridSize) -> LevelDefinition {
        let nodeCount = difficulty.nodeCount(for: gridSize)
        return generateLevel(size: gridSize.size, numberOfNodes: nodeCount)
    }
}
