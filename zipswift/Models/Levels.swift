//
//  Levels.swift
//  zipswift
//
//  Static level definitions for the game.
//

import Foundation

struct Levels {

    // All levels in order of difficulty
    static let all: [LevelDefinition] = [level1, level2, level3, level4, level5]

    // MARK: - Level 1: Horizontal Snake (Easy)
    // Path: Row 0 L->R, Row 1 R->L, Row 2 L->R, Row 3 R->L, Row 4 L->R, Row 5 R->L
    static let level1 = LevelDefinition(
        size: 6,
        numberedCells: [
            1: GridPoint(row: 0, col: 0),
            2: GridPoint(row: 0, col: 4),
            3: GridPoint(row: 1, col: 3),
            4: GridPoint(row: 2, col: 1),
            5: GridPoint(row: 3, col: 4),
            6: GridPoint(row: 4, col: 2),
            7: GridPoint(row: 5, col: 4),
            8: GridPoint(row: 5, col: 0)
        ],
        maxNumber: 8
    )

    // MARK: - Level 2: Clockwise Spiral (Medium)
    // Path: Outer edge clockwise, then spiral inward
    // (0,0)→(0,5)→(5,5)→(5,0)→(1,0)→(1,1)→(1,4)→(4,4)→(4,1)→(2,1)→inner
    static let level2 = LevelDefinition(
        size: 6,
        numberedCells: [
            1: GridPoint(row: 0, col: 0),
            2: GridPoint(row: 0, col: 3),
            3: GridPoint(row: 1, col: 5),
            4: GridPoint(row: 4, col: 5),
            5: GridPoint(row: 5, col: 4),
            6: GridPoint(row: 5, col: 0),
            7: GridPoint(row: 2, col: 1),
            8: GridPoint(row: 2, col: 3),
            9: GridPoint(row: 4, col: 3),
            10: GridPoint(row: 3, col: 2)
        ],
        maxNumber: 10
    )

    // MARK: - Level 3: Vertical Snake (Medium)
    // Path: Col 0 down, Col 1 up, Col 2 down, Col 3 up, Col 4 down, Col 5 up
    static let level3 = LevelDefinition(
        size: 6,
        numberedCells: [
            1: GridPoint(row: 0, col: 0),
            2: GridPoint(row: 3, col: 0),
            3: GridPoint(row: 2, col: 1),
            4: GridPoint(row: 5, col: 2),
            5: GridPoint(row: 2, col: 3),
            6: GridPoint(row: 0, col: 4),
            7: GridPoint(row: 5, col: 5),
            8: GridPoint(row: 0, col: 5)
        ],
        maxNumber: 8
    )

    // MARK: - Level 4: Double-Back Pattern (Medium-Hard)
    // Path: 3-column sections with turns
    static let level4 = LevelDefinition(
        size: 6,
        numberedCells: [
            1: GridPoint(row: 0, col: 0),
            2: GridPoint(row: 0, col: 2),
            3: GridPoint(row: 1, col: 0),
            4: GridPoint(row: 2, col: 3),
            5: GridPoint(row: 0, col: 4),
            6: GridPoint(row: 2, col: 5),
            7: GridPoint(row: 3, col: 3),
            8: GridPoint(row: 3, col: 0),
            9: GridPoint(row: 4, col: 4),
            10: GridPoint(row: 5, col: 0)
        ],
        maxNumber: 10
    )

    // MARK: - Level 5: Counter-Clockwise Spiral (Hard)
    // Path: Go down first, spiral inward counter-clockwise
    static let level5 = LevelDefinition(
        size: 6,
        numberedCells: [
            1: GridPoint(row: 0, col: 0),
            2: GridPoint(row: 2, col: 0),
            3: GridPoint(row: 5, col: 0),
            4: GridPoint(row: 5, col: 3),
            5: GridPoint(row: 4, col: 5),
            6: GridPoint(row: 1, col: 5),
            7: GridPoint(row: 0, col: 2),
            8: GridPoint(row: 3, col: 1),
            9: GridPoint(row: 4, col: 3),
            10: GridPoint(row: 2, col: 4),
            11: GridPoint(row: 1, col: 2),
            12: GridPoint(row: 2, col: 3)
        ],
        maxNumber: 12
    )
}
