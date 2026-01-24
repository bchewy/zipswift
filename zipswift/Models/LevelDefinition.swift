//
//  LevelDefinition.swift
//  zipswift
//
//  Defines the structure of a game level.
//

import Foundation

struct LevelDefinition {
    let size: Int
    let numberedCells: [Int: GridPoint]
    private let numberedCellsByPosition: [GridPoint: Int]
    let maxNumber: Int
    let solutionPath: [GridPoint]?

    init(size: Int = 6, numberedCells: [Int: GridPoint], maxNumber: Int, solutionPath: [GridPoint]? = nil) {
        self.size = size
        self.numberedCells = numberedCells
        self.numberedCellsByPosition = Dictionary(
            uniqueKeysWithValues: numberedCells.map { ($0.value, $0.key) }
        )
        self.maxNumber = maxNumber
        self.solutionPath = solutionPath
    }

    var startPosition: GridPoint {
        numberedCells[1]!
    }

    func numberAt(_ point: GridPoint) -> Int? {
        numberedCellsByPosition[point]
    }

    func isNumberedCell(_ point: GridPoint) -> Bool {
        numberAt(point) != nil
    }
}
