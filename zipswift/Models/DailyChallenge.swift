//
//  DailyChallenge.swift
//  zipswift
//
//  Generates deterministic daily puzzles using date as seed.
//

import Foundation

struct DailyChallenge {
    let date: Date
    let level: LevelDefinition
    let dateString: String

    init(date: Date = Date()) {
        self.date = Calendar.current.startOfDay(for: date)
        self.dateString = Self.dateStringFor(date)
        self.level = Self.generateDailyLevel(for: self.date)
    }

    static func dateStringFor(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func generateDailyLevel(for date: Date) -> LevelDefinition {
        let seed = seedFrom(date: date)
        return generateSeededLevel(seed: seed)
    }

    private static func seedFrom(date: Date) -> UInt64 {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = UInt64(components.year ?? 2024)
        let month = UInt64(components.month ?? 1)
        let day = UInt64(components.day ?? 1)
        return year * 10000 + month * 100 + day
    }

    private static func generateSeededLevel(seed: UInt64) -> LevelDefinition {
        var rng = SeededRandomNumberGenerator(seed: seed)
        let path = generateHamiltonianPath(size: 6, using: &rng)
        let numberOfNodes = 8

        var numberedCells: [Int: GridPoint] = [:]
        numberedCells[1] = path[0]
        numberedCells[numberOfNodes] = path[path.count - 1]

        if numberOfNodes > 2 {
            let remaining = numberOfNodes - 2
            let usableRange = path.count - 2
            let spacing = Double(usableRange) / Double(remaining + 1)

            for i in 1...remaining {
                let index = Int(Double(i) * spacing)
                numberedCells[i + 1] = path[index]
            }
        }

        return LevelDefinition(
            size: 6,
            numberedCells: numberedCells,
            maxNumber: numberOfNodes,
            solutionPath: path
        )
    }

    private static func generateHamiltonianPath(size: Int, using rng: inout SeededRandomNumberGenerator) -> [GridPoint] {
        let totalCells = size * size
        var path: [GridPoint] = []
        var visited: Set<GridPoint> = []
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
                return true
            }

            var neighbors = getNeighbors(current).filter { !visited.contains($0) }
            neighbors.shuffle(using: &rng)

            for neighbor in neighbors {
                if findPath(current: neighbor) {
                    return true
                }
            }

            path.removeLast()
            visited.remove(current)
            return false
        }

        _ = findPath(current: start)
        return path
    }

    var timeUntilNextDaily: TimeInterval {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) else {
            return 0
        }
        return tomorrow.timeIntervalSince(Date())
    }

    var formattedCountdown: String {
        let remaining = timeUntilNextDaily
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    static func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
