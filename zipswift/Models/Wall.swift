import Foundation

struct Wall: Hashable, Sendable {
    let cell1: GridPoint
    let cell2: GridPoint

    init(_ a: GridPoint, _ b: GridPoint) {
        if a.row < b.row || (a.row == b.row && a.col < b.col) {
            cell1 = a
            cell2 = b
        } else {
            cell1 = b
            cell2 = a
        }
    }

    var isHorizontalNeighbors: Bool { cell1.row == cell2.row }
}
