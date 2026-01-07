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
    let maxNumber: Int
    let solutionPath: [GridPoint]?

    init(size: Int = 6, numberedCells: [Int: GridPoint], maxNumber: Int, solutionPath: [GridPoint]? = nil) {
        self.size = size
        self.numberedCells = numberedCells
        self.maxNumber = maxNumber
        self.solutionPath = solutionPath
    }

    var startPosition: GridPoint {
        numberedCells[1]!
    }

    func numberAt(_ point: GridPoint) -> Int? {
        for (number, position) in numberedCells {
            if position == point {
                return number
            }
        }
        return nil
    }

    func isNumberedCell(_ point: GridPoint) -> Bool {
        numberAt(point) != nil
    }
}
