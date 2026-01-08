# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Open in Xcode
open zipswift.xcodeproj

# Build from command line
xcodebuild -scheme zipswift -destination 'generic/platform=iOS'

# Run tests
xcodebuild test -scheme zipswift -destination 'platform=iOS Simulator,name=iPhone 15'
```

Requirements: iOS 17.0+, Xcode 15.0+, Swift 5.9+

## Architecture

ZipSwift is a SwiftUI iOS puzzle game (LinkedIn Zip clone) where players draw paths through a 6x6 grid, visiting numbered nodes in ascending order while filling every cell exactly once.

### Core Components

**Models (`zipswift/Models/`)**
- `GameState` - Core game logic (@Observable). Manages path, visited cells, current target, timer. Key methods: `canVisit()`, `visit()`, `undo()`, `undoTo()`, `reset()`
- `GridPoint` - Grid coordinate (row 0-5, col 0-5) with `isAdjacent(to:)` for orthogonal adjacency
- `LevelDefinition` - Puzzle structure with `numberedCells` mapping and `solutionPath`
- `LevelGenerator` - Procedural Hamiltonian path generation with difficulty-based node counts (Easy: 12, Medium: 8, Hard: 5)
- `GameHistoryManager` / `SettingsManager` - Singletons using UserDefaults for persistence

**Views (`zipswift/Views/`)**
- `GameView` - Main screen container with timer, grid, and undo button
- `GridView` - 6x6 grid rendering with drag/tap gesture handling
- `PathOverlayView` - Canvas-based path visualization

**Audio (`zipswift/Audio/`)**
- `AudioManager` - Programmatic tone synthesis using AVAudioEngine with sine waves and envelope shaping

### State Management

Uses Swift's `@Observable` macro (iOS 17+) for reactive state. Three singletons: `GameHistoryManager.shared`, `AudioManager.shared`, `SettingsManager.shared`.

### Key Game Rules

- Start at node 1 (pre-filled), visit numbered nodes in ascending order
- Move orthogonally only, fill every cell exactly once
- Win: all 36 cells visited AND final numbered node reached
- Timer starts on first move, pauses on app background

## Testing

Tests use Swift Testing framework (not XCTest). Located in `zipswiftTests/`:
- `GameStateTests` - Move validation, backtracking, win conditions
- `GridPointTests` - Adjacency logic
- `LevelGeneratorTests` - Hamiltonian path generation

Run single test file:
```bash
xcodebuild test -scheme zipswift -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:zipswiftTests/GameStateTests
```

## Ralph Autonomous Loop

Ralph is an autonomous AI coding loop that implements features iteratively.

### Files
- `tasks.json` - User stories with acceptance criteria (prd.json equivalent)
- `scripts/ralph/ralph.sh` - Main loop script
- `scripts/ralph/prompt.md` - Agent instructions
- `scripts/ralph/progress.txt` - Learnings that persist across iterations

### Running Ralph
```bash
# Run with default 20 iterations
./scripts/ralph/ralph.sh

# Run with custom iteration limit
./scripts/ralph/ralph.sh 30
```

### How It Works
1. Ralph reads `tasks.json` and finds the next `passes: false` story
2. Implements the story following acceptance criteria
3. Runs build and tests to verify
4. Commits changes with story ID
5. Marks story as `passes: true`
6. Appends learnings to `progress.txt`
7. Loops until all stories pass or max iterations reached

### Monitoring Progress
```bash
# Check story status
cat tasks.json | jq '.userStories[] | {id, title, passes}'

# View learnings
cat scripts/ralph/progress.txt

# Recent commits
git log --oneline -10
```
