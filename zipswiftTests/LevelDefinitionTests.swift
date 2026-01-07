//
//  LevelDefinitionTests.swift
//  zipswiftTests
//
//  Tests for LevelDefinition model
//

import Testing
@testable import zipswift

struct LevelDefinitionTests {

    // MARK: - Initialization Tests

    @Test func initializesWithCorrectProperties() {
        let numberedCells: [Int: GridPoint] = [
            1: GridPoint(row: 0, col: 0),
            2: GridPoint(row: 2, col: 3),
            3: GridPoint(row: 5, col: 5)
        ]
        let level = LevelDefinition(
            size: 6,
            numberedCells: numberedCells,
            maxNumber: 3
        )

        #expect(level.size == 6)
        #expect(level.maxNumber == 3)
        #expect(level.numberedCells.count == 3)
    }

    @Test func defaultSizeIsSix() {
        let level = LevelDefinition(
            numberedCells: [1: GridPoint(row: 0, col: 0)],
            maxNumber: 1
        )
        #expect(level.size == 6)
    }

    @Test func accessNumberedCellPosition() {
        let numberedCells: [Int: GridPoint] = [
            1: GridPoint(row: 0, col: 0),
            2: GridPoint(row: 3, col: 4)
        ]
        let level = LevelDefinition(
            numberedCells: numberedCells,
            maxNumber: 2
        )

        #expect(level.numberedCells[1] == GridPoint(row: 0, col: 0))
        #expect(level.numberedCells[2] == GridPoint(row: 3, col: 4))
        #expect(level.numberedCells[3] == nil)
    }

    @Test func startPositionIsNumberOne() {
        let level = LevelDefinition(
            numberedCells: [
                1: GridPoint(row: 2, col: 3),
                2: GridPoint(row: 5, col: 5)
            ],
            maxNumber: 2
        )

        #expect(level.startPosition == GridPoint(row: 2, col: 3))
    }

    // MARK: - numberAt Tests

    @Test func numberAtReturnsCorrectNumber() {
        let level = LevelDefinition(
            numberedCells: [
                1: GridPoint(row: 0, col: 0),
                2: GridPoint(row: 2, col: 3),
                3: GridPoint(row: 4, col: 1)
            ],
            maxNumber: 3
        )

        #expect(level.numberAt(GridPoint(row: 0, col: 0)) == 1)
        #expect(level.numberAt(GridPoint(row: 2, col: 3)) == 2)
        #expect(level.numberAt(GridPoint(row: 4, col: 1)) == 3)
    }

    @Test func numberAtReturnsNilForEmptyCell() {
        let level = LevelDefinition(
            numberedCells: [
                1: GridPoint(row: 0, col: 0)
            ],
            maxNumber: 1
        )

        #expect(level.numberAt(GridPoint(row: 1, col: 1)) == nil)
        #expect(level.numberAt(GridPoint(row: 5, col: 5)) == nil)
    }

    // MARK: - isNumberedCell Tests

    @Test func isNumberedCellReturnsTrueForNumberedCells() {
        let level = LevelDefinition(
            numberedCells: [
                1: GridPoint(row: 0, col: 0),
                2: GridPoint(row: 3, col: 3)
            ],
            maxNumber: 2
        )

        #expect(level.isNumberedCell(GridPoint(row: 0, col: 0)))
        #expect(level.isNumberedCell(GridPoint(row: 3, col: 3)))
    }

    @Test func isNumberedCellReturnsFalseForEmptyCells() {
        let level = LevelDefinition(
            numberedCells: [
                1: GridPoint(row: 0, col: 0)
            ],
            maxNumber: 1
        )

        #expect(!level.isNumberedCell(GridPoint(row: 1, col: 1)))
        #expect(!level.isNumberedCell(GridPoint(row: 5, col: 5)))
    }
}
