//
//  OnboardingView.swift
//  zipswift
//
//  Onboarding flow shown on first launch with animated tutorials.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var showTutorialGame = false

    private let totalPages = 4
    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        ZStack {
            TabView(selection: $currentPage) {
                WelcomePage()
                    .tag(0)

                PathDrawingDemoPage()
                    .tag(1)

                NumberedNodesPage()
                    .tag(2)

                TipsPage()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            VStack {
                HStack {
                    Spacer()

                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                }

                Spacer()

                VStack(spacing: 20) {
                    PageIndicator(currentPage: currentPage, totalPages: totalPages)

                    Button(action: handleNext) {
                        Text(currentPage == totalPages - 1 ? "Start Playing" : "Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(accentColor)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showTutorialGame) {
            TutorialGameView {
                SettingsManager.shared.hasCompletedOnboarding = true
                dismiss()
            }
        }
    }

    private func handleNext() {
        if currentPage < totalPages - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            showTutorialGame = true
        }
    }

    private func completeOnboarding() {
        SettingsManager.shared.hasCompletedOnboarding = true
        dismiss()
    }
}

// MARK: - Welcome Page

struct WelcomePage: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 80))
                    .foregroundColor(accentColor)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text("ZipSwift")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.primary)

                Text("Path your way to victory")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Path Drawing Demo Page

struct PathDrawingDemoPage: View {
    @State private var animationProgress: Int = 0
    @State private var isAnimating = false

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    private let demoPath: [GridPoint] = [
        GridPoint(row: 0, col: 0),
        GridPoint(row: 0, col: 1),
        GridPoint(row: 0, col: 2),
        GridPoint(row: 1, col: 2),
        GridPoint(row: 1, col: 1),
        GridPoint(row: 1, col: 0),
        GridPoint(row: 2, col: 0),
        GridPoint(row: 2, col: 1),
        GridPoint(row: 2, col: 2)
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Draw a Path")
                .font(.title.bold())
                .foregroundColor(.primary)

            Text("Drag your finger to connect cells")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            DemoGridView(
                gridSize: 3,
                path: Array(demoPath.prefix(animationProgress)),
                numberedCells: [1: demoPath[0], 2: demoPath[8]]
            )
            .frame(width: 180, height: 180)
            .onAppear {
                startAnimation()
            }
            .onDisappear {
                isAnimating = false
            }

            Text("Fill every cell exactly once")
                .font(.callout)
                .foregroundColor(.secondary)

            Spacer()
            Spacer()
        }
        .padding()
    }

    private func startAnimation() {
        isAnimating = true
        animateStep()
    }

    private func animateStep() {
        guard isAnimating else { return }

        if animationProgress < demoPath.count {
            withAnimation(.easeOut(duration: 0.3)) {
                animationProgress += 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                animateStep()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                guard isAnimating else { return }
                withAnimation {
                    animationProgress = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    animateStep()
                }
            }
        }
    }
}

// MARK: - Numbered Nodes Page

struct NumberedNodesPage: View {
    @State private var highlightedNode: Int? = nil

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Visit Numbers in Order")
                .font(.title.bold())
                .foregroundColor(.primary)

            Text("Your path must pass through\nnumbered cells in sequence")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 24) {
                ForEach(1...4, id: \.self) { number in
                    NodeExample(
                        number: number,
                        isHighlighted: highlightedNode == number
                    )
                }
            }
            .onAppear {
                animateNodes()
            }

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 12, height: 12)
                    Text("Start at 1")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    Image(systemName: "arrow.right")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Text("Then 2, 3, 4...")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
            Spacer()
        }
        .padding()
    }

    private func animateNodes() {
        var delay = 0.0
        for i in 1...4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    highlightedNode = i
                }
            }
            delay += 0.6
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.5) {
            highlightedNode = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateNodes()
            }
        }
    }
}

struct NodeExample: View {
    let number: Int
    let isHighlighted: Bool

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        ZStack {
            Circle()
                .fill(isHighlighted ? accentColor : Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)

            if isHighlighted {
                Circle()
                    .stroke(accentColor, lineWidth: 3)
                    .frame(width: 60, height: 60)
                    .scaleEffect(isHighlighted ? 1.2 : 1.0)
                    .opacity(isHighlighted ? 0 : 1)
                    .animation(.easeOut(duration: 0.5), value: isHighlighted)
            }

            Text("\(number)")
                .font(.title2.bold())
                .foregroundColor(isHighlighted ? .white : .primary)
        }
        .scaleEffect(isHighlighted ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHighlighted)
    }
}

// MARK: - Tips Page

struct TipsPage: View {
    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Tips for Success")
                .font(.title.bold())
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 20) {
                TipRow(
                    icon: "lightbulb.fill",
                    title: "Plan Ahead",
                    description: "Look at all numbered cells before starting"
                )

                TipRow(
                    icon: "arrow.uturn.backward",
                    title: "Use Undo",
                    description: "Made a wrong move? Just tap undo"
                )

                TipRow(
                    icon: "hand.tap.fill",
                    title: "Tap to Backtrack",
                    description: "Tap on any numbered node to return there"
                )

                TipRow(
                    icon: "star.fill",
                    title: "Earn Stars",
                    description: "Complete puzzles faster for more stars"
                )
            }
            .padding(.horizontal, 20)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

struct TipRow: View {
    let icon: String
    let title: String
    let description: String

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Page Indicator

struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? accentColor : Color.gray.opacity(0.3))
                    .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}

// MARK: - Demo Grid View (for onboarding)

struct DemoGridView: View {
    let gridSize: Int
    let path: [GridPoint]
    let numberedCells: [Int: GridPoint]

    private let cellPadding: CGFloat = 4

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let cellSize = (size - cellPadding * 2) / CGFloat(gridSize)
            let origin = CGPoint(x: cellPadding, y: cellPadding)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))

                Canvas { context, _ in
                    for i in 0...gridSize {
                        let x = origin.x + CGFloat(i) * cellSize
                        var vPath = Path()
                        vPath.move(to: CGPoint(x: x, y: origin.y))
                        vPath.addLine(to: CGPoint(x: x, y: origin.y + CGFloat(gridSize) * cellSize))
                        context.stroke(vPath, with: .color(Color.gray.opacity(0.3)), lineWidth: 1)

                        let y = origin.y + CGFloat(i) * cellSize
                        var hPath = Path()
                        hPath.move(to: CGPoint(x: origin.x, y: y))
                        hPath.addLine(to: CGPoint(x: origin.x + CGFloat(gridSize) * cellSize, y: y))
                        context.stroke(hPath, with: .color(Color.gray.opacity(0.3)), lineWidth: 1)
                    }
                }

                if !path.isEmpty {
                    Canvas { context, _ in
                        var swiftUIPath = Path()
                        let firstCenter = centerFor(path[0], cellSize: cellSize, origin: origin)
                        swiftUIPath.move(to: firstCenter)

                        for i in 1..<path.count {
                            let center = centerFor(path[i], cellSize: cellSize, origin: origin)
                            swiftUIPath.addLine(to: center)
                        }

                        context.stroke(
                            swiftUIPath,
                            with: .color(accentColor),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                        )
                    }
                }

                ForEach(Array(numberedCells.keys.sorted()), id: \.self) { number in
                    if let point = numberedCells[number] {
                        let isVisited = path.contains(point)

                        ZStack {
                            Circle()
                                .fill(isVisited ? accentColor : Color.white)
                                .frame(width: cellSize * 0.7, height: cellSize * 0.7)

                            Circle()
                                .stroke(Color.black, lineWidth: 2)
                                .frame(width: cellSize * 0.7, height: cellSize * 0.7)

                            Text("\(number)")
                                .font(.system(size: cellSize * 0.35, weight: .bold))
                                .foregroundColor(isVisited ? .white : .black)
                        }
                        .position(centerFor(point, cellSize: cellSize, origin: origin))
                    }
                }
            }
        }
    }

    private func centerFor(_ point: GridPoint, cellSize: CGFloat, origin: CGPoint) -> CGPoint {
        CGPoint(
            x: origin.x + CGFloat(point.col) * cellSize + cellSize / 2,
            y: origin.y + CGFloat(point.row) * cellSize + cellSize / 2
        )
    }
}

// MARK: - Tutorial Game View

struct TutorialGameView: View {
    let onComplete: () -> Void

    @State private var gameState: GameState
    @State private var tutorialStep = 0
    @State private var showHighlight = true
    @State private var showCompletionOverlay = false

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    private static let tutorialLevel: LevelDefinition = {
        let path: [GridPoint] = [
            GridPoint(row: 0, col: 0),
            GridPoint(row: 0, col: 1),
            GridPoint(row: 0, col: 2),
            GridPoint(row: 0, col: 3),
            GridPoint(row: 0, col: 4),
            GridPoint(row: 1, col: 4),
            GridPoint(row: 1, col: 3),
            GridPoint(row: 1, col: 2),
            GridPoint(row: 1, col: 1),
            GridPoint(row: 1, col: 0),
            GridPoint(row: 2, col: 0),
            GridPoint(row: 2, col: 1),
            GridPoint(row: 2, col: 2),
            GridPoint(row: 2, col: 3),
            GridPoint(row: 2, col: 4),
            GridPoint(row: 3, col: 4),
            GridPoint(row: 3, col: 3),
            GridPoint(row: 3, col: 2),
            GridPoint(row: 3, col: 1),
            GridPoint(row: 3, col: 0),
            GridPoint(row: 4, col: 0),
            GridPoint(row: 4, col: 1),
            GridPoint(row: 4, col: 2),
            GridPoint(row: 4, col: 3),
            GridPoint(row: 4, col: 4)
        ]

        return LevelDefinition(
            size: 5,
            numberedCells: [
                1: path[0],
                2: path[6],
                3: path[12],
                4: path[18],
                5: path[24]
            ],
            maxNumber: 5,
            solutionPath: path
        )
    }()

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        self._gameState = State(initialValue: GameState(level: TutorialGameView.tutorialLevel))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                HStack {
                    Button(action: onComplete) {
                        Text("Skip Tutorial")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                Text("Your First Puzzle")
                    .font(.title2.bold())

                Text(tutorialInstructionText)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .animation(.easeInOut, value: tutorialStep)

                Spacer()

                ZStack {
                    TutorialGridView(
                        gameState: gameState,
                        highlightPoints: highlightPoints,
                        showHighlight: showHighlight
                    )
                    .padding(.horizontal, 32)
                }

                Spacer()

                if gameState.path.count > 1 {
                    Button(action: { gameState.undo() }) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Undo")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(accentColor)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.vertical, 16)

            if showCompletionOverlay {
                TutorialCompletionOverlay(onContinue: onComplete)
            }
        }
        .onChange(of: gameState.isComplete) { _, isComplete in
            if isComplete {
                withAnimation {
                    showCompletionOverlay = true
                }
            }
        }
        .onChange(of: gameState.path.count) { _, _ in
            updateTutorialStep()
        }
    }

    private var tutorialInstructionText: String {
        switch tutorialStep {
        case 0:
            return "You start at node 1. Drag to draw a path to the right."
        case 1:
            return "Great! Keep going - reach node 2."
        case 2:
            return "Now head to node 3. Fill every cell!"
        case 3:
            return "Almost there! Find your way to node 4."
        case 4:
            return "Final stretch! Complete the path to node 5."
        default:
            return "Keep going!"
        }
    }

    private var highlightPoints: [GridPoint] {
        guard let solution = gameState.level.solutionPath else { return [] }
        let currentIndex = gameState.path.count - 1
        guard currentIndex < solution.count - 1 else { return [] }

        let nextIndices = (1...3).compactMap { offset -> Int? in
            let idx = currentIndex + offset
            return idx < solution.count ? idx : nil
        }

        return nextIndices.map { solution[$0] }
    }

    private func updateTutorialStep() {
        let target = gameState.currentTarget
        if target > tutorialStep + 1 {
            tutorialStep = target - 1
        }
    }
}

// MARK: - Tutorial Grid View

struct TutorialGridView: View {
    @Bindable var gameState: GameState
    var highlightPoints: [GridPoint]
    var showHighlight: Bool

    @State private var lastVisited: GridPoint?

    private var gridSize: Int { gameState.level.size }
    private let gridPadding: CGFloat = 8

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        GeometryReader { geometry in
            let availableSize = min(geometry.size.width, geometry.size.height)
            let cellSize = (availableSize - gridPadding * 2) / CGFloat(gridSize)
            let gridOrigin = CGPoint(x: gridPadding, y: gridPadding)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))

                Canvas { context, _ in
                    for i in 0...gridSize {
                        let x = gridOrigin.x + CGFloat(i) * cellSize
                        var vPath = Path()
                        vPath.move(to: CGPoint(x: x, y: gridOrigin.y))
                        vPath.addLine(to: CGPoint(x: x, y: gridOrigin.y + CGFloat(gridSize) * cellSize))
                        context.stroke(vPath, with: .color(Color.gray.opacity(0.3)), lineWidth: 1)

                        let y = gridOrigin.y + CGFloat(i) * cellSize
                        var hPath = Path()
                        hPath.move(to: CGPoint(x: gridOrigin.x, y: y))
                        hPath.addLine(to: CGPoint(x: gridOrigin.x + CGFloat(gridSize) * cellSize, y: y))
                        context.stroke(hPath, with: .color(Color.gray.opacity(0.3)), lineWidth: 1)
                    }
                }

                if !gameState.path.isEmpty {
                    Canvas { context, _ in
                        var path = Path()
                        let firstCenter = centerFor(gameState.path[0], cellSize: cellSize, origin: gridOrigin)
                        path.move(to: firstCenter)

                        for i in 1..<gameState.path.count {
                            let center = centerFor(gameState.path[i], cellSize: cellSize, origin: gridOrigin)
                            path.addLine(to: center)
                        }

                        context.stroke(
                            path,
                            with: .color(accentColor),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                        )
                    }
                }

                if showHighlight {
                    ForEach(Array(highlightPoints.enumerated()), id: \.offset) { index, point in
                        TutorialHighlight(
                            point: point,
                            cellSize: cellSize,
                            gridOrigin: gridOrigin,
                            delay: Double(index) * 0.15
                        )
                    }
                }

                ForEach(Array(gameState.level.numberedCells.keys.sorted()), id: \.self) { number in
                    if let point = gameState.level.numberedCells[number] {
                        let isVisited = gameState.visited.contains(point)
                        let isActive = number == gameState.currentTarget

                        ZStack {
                            Circle()
                                .fill(isVisited ? accentColor : Color.white)
                                .frame(width: cellSize * 0.7, height: cellSize * 0.7)

                            Circle()
                                .stroke(isActive ? accentColor : Color.black, lineWidth: isActive ? 3 : 2)
                                .frame(width: cellSize * 0.7, height: cellSize * 0.7)

                            Text("\(number)")
                                .font(.system(size: cellSize * 0.35, weight: .bold))
                                .foregroundColor(isVisited ? .white : .black)
                        }
                        .scaleEffect(isActive && !isVisited ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
                        .position(centerFor(point, cellSize: cellSize, origin: gridOrigin))
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        handleDrag(location: value.location, cellSize: cellSize, origin: gridOrigin)
                    }
                    .onEnded { _ in
                        lastVisited = nil
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func handleDrag(location: CGPoint, cellSize: CGFloat, origin: CGPoint) {
        let adjustedX = location.x - origin.x
        let adjustedY = location.y - origin.y

        let col = Int(adjustedX / cellSize)
        let row = Int(adjustedY / cellSize)

        guard row >= 0 && row < gridSize && col >= 0 && col < gridSize else { return }

        let point = GridPoint(row: row, col: col)

        if point == lastVisited { return }

        if gameState.canVisit(point) {
            gameState.visit(point)
            lastVisited = point
        }
    }

    private func centerFor(_ point: GridPoint, cellSize: CGFloat, origin: CGPoint) -> CGPoint {
        CGPoint(
            x: origin.x + CGFloat(point.col) * cellSize + cellSize / 2,
            y: origin.y + CGFloat(point.row) * cellSize + cellSize / 2
        )
    }
}

// MARK: - Tutorial Highlight

struct TutorialHighlight: View {
    let point: GridPoint
    let cellSize: CGFloat
    let gridOrigin: CGPoint
    let delay: Double

    @State private var isPulsing = false

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        Circle()
            .fill(accentColor.opacity(0.2))
            .frame(width: cellSize * 0.5, height: cellSize * 0.5)
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0.3 : 0.6)
            .position(
                x: gridOrigin.x + CGFloat(point.col) * cellSize + cellSize / 2,
                y: gridOrigin.y + CGFloat(point.row) * cellSize + cellSize / 2
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Tutorial Completion Overlay

struct TutorialCompletionOverlay: View {
    let onContinue: () -> Void

    @State private var showContent = false

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("Well Done!")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text("You've mastered the basics.\nNow try the real puzzles!")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                Button(action: onContinue) {
                    Text("Start Playing")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(accentColor)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            .scaleEffect(showContent ? 1.0 : 0.8)
            .opacity(showContent ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }
        }
    }
}

#Preview {
    OnboardingView()
}
