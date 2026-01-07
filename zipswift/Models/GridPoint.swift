//
//  GridPoint.swift
//  zipswift
//
//  Represents a position on the 6x6 game grid.
//

import Foundation

struct GridPoint: Hashable, Equatable {
    let row: Int
    let col: Int

    func isAdjacent(to other: GridPoint) -> Bool {
        let rowDiff = abs(row - other.row)
        let colDiff = abs(col - other.col)
        // Manhattan distance must be exactly 1 (orthogonal adjacency)
        return (rowDiff + colDiff) == 1
    }
}
