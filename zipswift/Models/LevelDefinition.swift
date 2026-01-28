//
//  LevelDefinition.swift
//  zipswift
//
//  Defines the structure of a game level.
//

import Foundation

struct LevelDefinition: Sendable {
    nonisolated let size: Int
    nonisolated let numberedCells: [Int: GridPoint]
    nonisolated private let numberedCellsByPosition: [GridPoint: Int]
    nonisolated let maxNumber: Int
    nonisolated let solutionPath: [GridPoint]?
    nonisolated let walls: Set<Wall>

    nonisolated init(size: Int = 6, numberedCells: [Int: GridPoint], maxNumber: Int, solutionPath: [GridPoint]? = nil, walls: Set<Wall> = []) {
        self.size = size
        self.numberedCells = numberedCells
        self.numberedCellsByPosition = Dictionary(
            uniqueKeysWithValues: numberedCells.map { ($0.value, $0.key) }
        )
        self.maxNumber = maxNumber
        self.solutionPath = solutionPath
        self.walls = walls
    }

    nonisolated func hasWall(between a: GridPoint, and b: GridPoint) -> Bool {
        walls.contains(Wall(a, b))
    }

    nonisolated var startPosition: GridPoint {
        numberedCells[1]!
    }

    nonisolated func numberAt(_ point: GridPoint) -> Int? {
        numberedCellsByPosition[point]
    }

    nonisolated func isNumberedCell(_ point: GridPoint) -> Bool {
        numberAt(point) != nil
    }
}
