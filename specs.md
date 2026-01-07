# Zip (iOS) - Game Spec

## Overview
Zip is a visual logic puzzle where the player draws a single path through a 6x6 grid, visiting numbered nodes in order and filling every cell exactly once (except when backtracking).

This spec defines the MVP for a SwiftUI iOS implementation inspired by LinkedIn's Zip game.

**Target:** iOS 17+

## Goals
- Deliver a clean, responsive 6x6 puzzle grid with numbered nodes and a path-drawing interaction.
- Enforce Zip rules with immediate feedback and clear win conditions.
- Provide a minimal UI: timer, undo, and a collapsible "How to play" panel.

## Non-goals (for MVP)
- Hints, solver, or auto-play.
- Level editor or level selection.
- Analytics, accounts, or cloud sync.
- Accessibility beyond standard system defaults.

## Core Rules
- Grid is fixed at 6x6 (36 cells total).
- Numbered nodes are labeled 1 through N, where N is the highest number in the level. Numbers are always contiguous (1, 2, 3, ..., N).
- The path is pre-initialized with the "1" cell. The player extends from there.
- Moves are orthogonal only (up, down, left, right).
- Numbered nodes must be visited in strict ascending order.
- Non-numbered cells can be visited at any time if the move is valid.
- A cell cannot be visited twice unless the player is backtracking (see Backtracking below).
- Win condition: all 36 cells are visited AND the final numbered node (N) has been reached.

## User Experience
- Single-screen layout:
  - Top: timer (starts on first move, stops on win).
  - Middle: rounded grid container with 6x6 cells.
  - Bottom: Undo button.
  - Bottom panel: collapsible "How to play" with simple visuals/text.
- Numbered nodes are black circles with white text. The active node can be highlighted (blue ring or fill).
- Path is drawn as a continuous line between cell centers.
- Invalid moves trigger a system haptic vibration AND a brief red flash (150ms) on the attempted segment.

## Interaction Model
- **Drag-to-draw:** User drags from the current path endpoint to adjacent cells. Path updates in real-time as the user drags (live preview).
- **Tap-to-step:** User can tap an adjacent cell to extend the path by one cell.
- **Backtracking:**
  - Dragging back over the previous cell removes the last step (one cell per gesture—multi-cell backtracking in a single drag is not supported).
  - Undo button removes the last step.
  - After backtracking, forward movement follows normal rules.
  - If the removed cell was a numbered node, `currentTarget` decrements accordingly.
- **Start:**
  - Path is pre-initialized with "1" already visited. User extends from "1".
  - Timer begins on the first move away from "1".

## UI Components
- `GameView`: hosts the screen layout and game state.
- `GridView`: renders grid cells, numbers, and handles touch input.
- `PathOverlayView`: draws the active path with SwiftUI `Canvas` or `Path`.
- `NumberNodeView`: renders numbered cells (circle + number).
- `BottomPanelView`: accordion for "How to play".
- `WinOverlayView`: displays confetti, completion message, time, and "Play Again" button.

## Data Model
- `GridPoint`:
  - `row: Int` (0-5)
  - `col: Int` (0-5)
- `LevelDefinition`:
  - `size: Int = 6`
  - `numberedCells: [Int: GridPoint]` — mapping from number (1...N) to grid position
  - `maxNumber: Int` — the highest numbered node (N)
- `GameState`:
  - `path: [GridPoint]` — ordered list of visited cells; initialized with the "1" cell
  - `visited: Set<GridPoint>` — set of all visited cells; initialized with the "1" cell
  - `currentTarget: Int` — next required numbered node; initialized to 2
  - `timerStart: Date?` — nil until first move
  - `elapsed: TimeInterval` — computed from `timerStart` and current time (pauses on background)
  - `isComplete: Bool`

## State and Rule Checks
- `isAdjacent(a, b)` → true if orthogonally adjacent (Manhattan distance == 1).
- `canVisit(point)`:
  - Must be adjacent to current path endpoint.
  - If the cell is numbered, it must equal `currentTarget`.
  - If already visited, only allow if it equals the previous path point (backtracking).
- **On visit:**
  - Append to `path`.
  - Add to `visited`.
  - If the cell is numbered and equals `currentTarget`, increment `currentTarget`.
- **On backtrack:**
  - Remove last element from `path`.
  - Remove from `visited`.
  - If the removed cell was numbered, decrement `currentTarget`.
- **Win check:**
  - `visited.count == 36` AND `currentTarget > maxNumber` (i.e., all numbered nodes have been reached).

## Level Data
- Start with a single 6x6 level mirroring the screenshot layout.
- Store level data in a local Swift file (e.g., `Levels.swift`) as static constants.

**Example format:**
```swift
struct Levels {
    static let level1 = LevelDefinition(
        size: 6,
        numberedCells: [
            1: GridPoint(row: 0, col: 0),
            2: GridPoint(row: 2, col: 3),
            3: GridPoint(row: 4, col: 1),
            // ...
        ],
        maxNumber: 5
    )
}
```

## Visual Design Notes
- Soft gray background for the grid area.
- Thin grid lines with rounded outer container.
- Path stroke width 8-12pt, rounded caps.
- Use subtle shadows for numbered nodes.

## Error Feedback
- Reject invalid moves with:
  - System haptic vibration (`UIImpactFeedbackGenerator` with `.medium` style).
  - AND a 150ms red flash on the attempted segment.
- Both feedback mechanisms fire simultaneously.

## Win State
- On win:
  - Timer stops immediately.
  - Confetti animation plays over the grid.
  - Modal or overlay displays:
    - "Puzzle Complete!" heading.
    - Final elapsed time (formatted as mm:ss or ss.s for times under 1 minute).
    - "Play Again" button to restart the same level.
  - Success haptic feedback (`UINotificationFeedbackGenerator` with `.success`).

## Timer Behavior
- Timer is displayed at the top of the screen in mm:ss format.
- Timer starts on the first move away from "1".
- Timer pauses when the app enters background (`scenePhase == .background`).
- Timer resumes when the app returns to foreground (`scenePhase == .active`).
- Timer stops on win.

## Testing
- Unit tests for:
  - Adjacency checks (`isAdjacent`).
  - Numbered node order enforcement.
  - Backtracking behavior (path and `currentTarget` updates).
  - Win condition detection.
  - Initial state (path and visited contain "1", currentTarget == 2).
- UI sanity:
  - Drag gesture updates path correctly with live preview.
  - Tap gesture extends path by one cell.
  - Invalid moves trigger haptic and red flash.
  - Win overlay appears on completion.

## Acceptance Criteria
- Path starts pre-initialized with "1" visited.
- Player can complete a level by drawing a valid path through all 36 cells.
- Numbered nodes must be visited strictly in ascending order.
- Undo removes steps correctly, including numbered nodes (decrementing `currentTarget` as needed).
- Invalid moves produce haptic feedback and a red flash.
- No hints are present in the UI.
- Timer starts on first move away from "1" and stops on win.
- Timer pauses when app backgrounds and resumes on foreground.
- On win, confetti animation plays and completion overlay shows final time with "Play Again" option.
