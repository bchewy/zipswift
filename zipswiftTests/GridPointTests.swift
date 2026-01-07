//
//  GridPointTests.swift
//  zipswiftTests
//
//  Tests for GridPoint model
//

import Testing
@testable import zipswift

struct GridPointTests {

    // MARK: - Initialization Tests

    @Test func initializesWithValidCoordinates() {
        let point = GridPoint(row: 3, col: 4)
        #expect(point.row == 3)
        #expect(point.col == 4)
    }

    @Test func initializesWithZeroCoordinates() {
        let point = GridPoint(row: 0, col: 0)
        #expect(point.row == 0)
        #expect(point.col == 0)
    }

    @Test func initializesWithMaxCoordinates() {
        let point = GridPoint(row: 5, col: 5)
        #expect(point.row == 5)
        #expect(point.col == 5)
    }

    // MARK: - Equality Tests

    @Test func equalPointsAreEqual() {
        let point1 = GridPoint(row: 2, col: 3)
        let point2 = GridPoint(row: 2, col: 3)
        #expect(point1 == point2)
    }

    @Test func differentRowsAreNotEqual() {
        let point1 = GridPoint(row: 2, col: 3)
        let point2 = GridPoint(row: 3, col: 3)
        #expect(point1 != point2)
    }

    @Test func differentColsAreNotEqual() {
        let point1 = GridPoint(row: 2, col: 3)
        let point2 = GridPoint(row: 2, col: 4)
        #expect(point1 != point2)
    }

    // MARK: - Hashable Tests

    @Test func canBeUsedInSet() {
        var pointSet: Set<GridPoint> = []
        let point1 = GridPoint(row: 1, col: 2)
        let point2 = GridPoint(row: 1, col: 2)
        let point3 = GridPoint(row: 3, col: 4)

        pointSet.insert(point1)
        pointSet.insert(point2) // duplicate
        pointSet.insert(point3)

        #expect(pointSet.count == 2)
        #expect(pointSet.contains(point1))
        #expect(pointSet.contains(point3))
    }

    // MARK: - Adjacency Tests

    @Test func isAdjacentToPointAbove() {
        let point = GridPoint(row: 2, col: 3)
        let above = GridPoint(row: 1, col: 3)
        #expect(point.isAdjacent(to: above))
    }

    @Test func isAdjacentToPointBelow() {
        let point = GridPoint(row: 2, col: 3)
        let below = GridPoint(row: 3, col: 3)
        #expect(point.isAdjacent(to: below))
    }

    @Test func isAdjacentToPointLeft() {
        let point = GridPoint(row: 2, col: 3)
        let left = GridPoint(row: 2, col: 2)
        #expect(point.isAdjacent(to: left))
    }

    @Test func isAdjacentToPointRight() {
        let point = GridPoint(row: 2, col: 3)
        let right = GridPoint(row: 2, col: 4)
        #expect(point.isAdjacent(to: right))
    }

    @Test func isNotAdjacentToDiagonalPoint() {
        let point = GridPoint(row: 2, col: 3)
        let diagonal = GridPoint(row: 3, col: 4)
        #expect(!point.isAdjacent(to: diagonal))
    }

    @Test func isNotAdjacentToSamePoint() {
        let point = GridPoint(row: 2, col: 3)
        #expect(!point.isAdjacent(to: point))
    }

    @Test func isNotAdjacentToDistantPoint() {
        let point = GridPoint(row: 0, col: 0)
        let distant = GridPoint(row: 5, col: 5)
        #expect(!point.isAdjacent(to: distant))
    }

    @Test func isNotAdjacentTwoStepsAway() {
        let point = GridPoint(row: 2, col: 2)
        let twoAway = GridPoint(row: 2, col: 4)
        #expect(!point.isAdjacent(to: twoAway))
    }
}
