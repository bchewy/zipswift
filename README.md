# ZipSwift

A SwiftUI iOS puzzle game inspired by LinkedIn's Zip. Draw a path through a 6x6 grid, visiting numbered nodes in order while filling every cell.


## Gameplay
https://github.com/user-attachments/assets/274d2de8-2c54-46bd-9051-4e395fa29775

- **Objective:** Draw a single continuous path through all 36 cells
- **Rules:**
  - Start from node 1 (pre-filled)
  - Visit numbered nodes in ascending order (1 → 2 → 3 → ...)
  - Move orthogonally (up, down, left, right)
  - Fill every cell exactly once
  - Win when all cells are visited and the final number is reached

## Features

- Drag-to-draw path input with live preview
- Tap-to-step for precise moves
- Undo and backtracking support



- Timer (starts on first move, pauses when backgrounded)
- Haptic feedback for invalid moves
- Confetti celebration on completion
- Multiple difficulty levels (Easy, Medium, Hard)
- Game history tracking

## Requirements

- iOS 17.0+
- Xcode 15.0+

## Installation

1. Clone the repository
2. Open `zipswift.xcodeproj` in Xcode
3. Build and run on simulator or device

## Architecture

```
zipswift/
├── Models/
│   ├── GameState.swift       # Core game logic
│   ├── GridPoint.swift       # Grid coordinate model
│   ├── LevelDefinition.swift # Puzzle structure
│   ├── LevelGenerator.swift  # Procedural level generation
│   └── GameHistoryManager.swift
├── Views/
│   ├── GameView.swift        # Main game screen
│   ├── GridView.swift        # 6x6 grid with touch handling
│   ├── PathOverlayView.swift # Path rendering
│   └── WinOverlayView.swift  # Victory screen
└── Audio/
    └── AudioManager.swift    # Sound effects
```

## License

MIT
