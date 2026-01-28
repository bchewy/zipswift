//
//  LevelGenerator.swift
//  zipswift
//
//  Generates random but always solvable puzzle levels using Hamiltonian paths.
//

import Foundation

enum GridSize: Int, CaseIterable, Codable, Sendable {
    case quick = 5
    case classic = 6
    case extended = 7
    case marathon = 8

    nonisolated var size: Int { rawValue }

    nonisolated var displayName: String {
        switch self {
        case .quick: return "5×5 Quick"
        case .classic: return "6×6 Classic"
        case .extended: return "7×7 Extended"
        case .marathon: return "8×8 Marathon"
        }
    }

    nonisolated var shortName: String {
        "\(size)×\(size)"
    }
}

enum Difficulty: String, CaseIterable, Codable, Sendable {
    case easy
    case medium
    case hard

    nonisolated func nodeCount(for gridSize: GridSize) -> Int {
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

    nonisolated var nodeCount: Int {
        nodeCount(for: .classic)
    }

    nonisolated func wallCount(for gridSize: GridSize) -> Int {
        switch (self, gridSize) {
        case (.easy, .quick): return 2
        case (.medium, .quick): return 3
        case (.hard, .quick): return 5

        case (.easy, .classic): return 3
        case (.medium, .classic): return 5
        case (.hard, .classic): return 8

        case (.easy, .extended): return 4
        case (.medium, .extended): return 7
        case (.hard, .extended): return 10

        case (.easy, .marathon): return 5
        case (.medium, .marathon): return 9
        case (.hard, .marathon): return 13
        }
    }

    nonisolated var iconName: String {
        switch self {
        case .easy: return "DifficultyEasy"
        case .medium: return "DifficultyMedium"
        case .hard: return "DifficultyHard"
        }
    }
}

struct LevelGenerator {

    /// Generates a random Hamiltonian path (visits every cell exactly once)
    /// Uses Warnsdorff-style heuristic with randomized tie-breaks
    nonisolated static func generateHamiltonianPath(size: Int) -> [GridPoint] {
        let totalCells = size * size
        var path: [GridPoint] = []
        var visited: Set<GridPoint> = []
        var steps = 0
        var aborted = false
        let startTime = ProcessInfo.processInfo.systemUptime
        let timeLimit: TimeInterval = size >= 7 ? 0.2 : 0.12

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

        func onwardDegree(_ point: GridPoint) -> Int {
            getNeighbors(point)
                .filter { !visited.contains($0) }
                .count
        }

        func orderedNeighbors(_ point: GridPoint) -> [GridPoint] {
            let candidates = getNeighbors(point)
                .filter { !visited.contains($0) }
                .shuffled()

            return candidates.sorted { lhs, rhs in
                let lhsDegree = onwardDegree(lhs)
                let rhsDegree = onwardDegree(rhs)
                return lhsDegree < rhsDegree
            }
        }

        func findPath(current: GridPoint) -> Bool {
            if aborted {
                return false
            }
            steps += 1
            if steps % 512 == 0 {
                let elapsed = ProcessInfo.processInfo.systemUptime - startTime
                if elapsed > timeLimit {
                    aborted = true
                    return false
                }
            }
            path.append(current)
            visited.insert(current)

            if path.count == totalCells {
                return true // Found complete path
            }

            let neighbors = orderedNeighbors(current)

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

        if findPath(current: start) {
            return path
        }

        return generateSnakePath(size: size, useRows: Bool.random())
    }

    private nonisolated static func generateSnakePath(size: Int, useRows: Bool) -> [GridPoint] {
        var path: [GridPoint] = []
        path.reserveCapacity(size * size)

        if useRows {
            for row in 0..<size {
                if row.isMultiple(of: 2) {
                    for col in 0..<size {
                        path.append(GridPoint(row: row, col: col))
                    }
                } else {
                    for col in stride(from: size - 1, through: 0, by: -1) {
                        path.append(GridPoint(row: row, col: col))
                    }
                }
            }
        } else {
            for col in 0..<size {
                if col.isMultiple(of: 2) {
                    for row in 0..<size {
                        path.append(GridPoint(row: row, col: col))
                    }
                } else {
                    for row in stride(from: size - 1, through: 0, by: -1) {
                        path.append(GridPoint(row: row, col: col))
                    }
                }
            }
        }

        return path
    }

    private nonisolated static func generateWalls(path: [GridPoint], size: Int, count: Int) -> Set<Wall> {
        guard count > 0 else { return [] }

        var pathEdges = Set<Wall>()
        for i in 0..<(path.count - 1) {
            pathEdges.insert(Wall(path[i], path[i + 1]))
        }

        var candidates: [Wall] = []
        for row in 0..<size {
            for col in 0..<size {
                let cell = GridPoint(row: row, col: col)
                if col + 1 < size {
                    let right = GridPoint(row: row, col: col + 1)
                    let wall = Wall(cell, right)
                    if !pathEdges.contains(wall) {
                        candidates.append(wall)
                    }
                }
                if row + 1 < size {
                    let below = GridPoint(row: row + 1, col: col)
                    let wall = Wall(cell, below)
                    if !pathEdges.contains(wall) {
                        candidates.append(wall)
                    }
                }
            }
        }

        candidates.shuffle()
        return Set(candidates.prefix(count))
    }

    /// Generates a complete level with numbered nodes placed along a valid path
    nonisolated static func generateLevel(size: Int = 6, numberOfNodes: Int, wallCount: Int = 0) -> LevelDefinition {
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

        let walls = generateWalls(path: path, size: size, count: wallCount)

        return LevelDefinition(
            size: size,
            numberedCells: numberedCells,
            maxNumber: numberOfNodes,
            solutionPath: path,
            walls: walls
        )
    }

    /// Generates a level with difficulty-based node count
    nonisolated static func generateLevel(difficulty: Difficulty, size: Int = 6) -> LevelDefinition {
        return generateLevel(size: size, numberOfNodes: difficulty.nodeCount)
    }

    /// Generates a level with difficulty and grid size
    nonisolated static func generateLevel(difficulty: Difficulty, gridSize: GridSize) -> LevelDefinition {
        let nodeCount = difficulty.nodeCount(for: gridSize)
        let walls = difficulty.wallCount(for: gridSize)
        return generateLevel(size: gridSize.size, numberOfNodes: nodeCount, wallCount: walls)
    }
}
