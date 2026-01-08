//
//  WinOverlayView.swift
//  zipswift
//
//  Displays confetti animation, completion message, time, and New Game button.
//

import SwiftUI
import UIKit

struct WinOverlayView: View {
    let elapsedTime: TimeInterval
    let difficulty: Difficulty
    let onPlayAgain: () -> Void
    var isDaily: Bool = false
    var dailyStreak: Int = 0

    @State private var showContent = false
    @State private var showStars = false
    @State private var confettiTrigger = false
    @State private var showShareSheet = false

    private var settings: SettingsManager { SettingsManager.shared }

    private var accentColor: Color {
        settings.accentColor.color
    }

    private var starCount: Int {
        StarRating.stars(for: elapsedTime, difficulty: difficulty)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                ConfettiView(
                    trigger: confettiTrigger,
                    screenSize: geometry.size
                )
                .ignoresSafeArea()

                if showContent {
                    VStack(spacing: 24) {
                        Text("Puzzle Complete!")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text(formattedTime)
                            .font(.system(size: 48, weight: .semibold, design: .monospaced))
                            .foregroundColor(accentColor)

                        if showStars {
                            StarRatingView(stars: starCount, animated: true, size: 36)
                        }

                        HStack(spacing: 12) {
                            Button(action: shareResult) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
                                }
                                .font(.headline)
                                .foregroundColor(accentColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(accentColor, lineWidth: 2)
                                )
                            }

                            Button(action: onPlayAgain) {
                                Text("New Game")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(accentColor)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 20)
                    )
                    .padding(.horizontal, 40)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear {
            confettiTrigger = true
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showStars = true
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
    }

    private var formattedTime: String {
        if elapsedTime < 60 {
            return String(format: "%.1fs", elapsedTime)
        } else {
            let minutes = Int(elapsedTime) / 60
            let seconds = Int(elapsedTime) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private var shareItems: [Any] {
        var items: [Any] = []

        let text = ShareHelper.generateShareText(
            elapsedTime: elapsedTime,
            difficulty: difficulty,
            stars: starCount,
            isDaily: isDaily,
            dailyStreak: dailyStreak
        )
        items.append(text)

        if let image = ShareHelper.generateShareImage(
            elapsedTime: elapsedTime,
            difficulty: difficulty,
            stars: starCount,
            isDaily: isDaily,
            dailyStreak: dailyStreak
        ) {
            items.append(image)
        }

        return items
    }

    private func shareResult() {
        triggerHaptic()
        showShareSheet = true
    }

    private func triggerHaptic() {
        guard settings.hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Confetti View

struct ConfettiView: View {
    let trigger: Bool
    let screenSize: CGSize

    private let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
    private let particleCount = 50

    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                ConfettiPiece(
                    index: index,
                    screenSize: screenSize,
                    color: colors[index % colors.count],
                    trigger: trigger
                )
            }
        }
    }
}

// MARK: - Confetti Piece

struct ConfettiPiece: View {
    let index: Int
    let screenSize: CGSize
    let color: Color
    let trigger: Bool

    @State private var offsetY: CGFloat = -20
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    private var initialX: CGFloat {
        // Deterministic but varied x position based on index
        let segment = screenSize.width / 50
        return segment * CGFloat(index) + CGFloat.random(in: -10...10)
    }

    private var initialRotation: Double {
        Double(index * 37 % 360)
    }

    private var scale: CGFloat {
        CGFloat(0.5 + Double(index % 5) * 0.1)
    }

    private var delay: Double {
        Double(index) * 0.02
    }

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 10 * scale, height: 14 * scale)
            .rotationEffect(.degrees(rotation))
            .position(x: initialX, y: offsetY)
            .opacity(opacity)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    startAnimation()
                }
            }
            .onAppear {
                if trigger {
                    startAnimation()
                }
            }
    }

    private func startAnimation() {
        withAnimation(
            .easeIn(duration: 2.5)
            .delay(delay)
        ) {
            offsetY = screenSize.height + 100
            rotation = initialRotation + Double.random(in: 180...540)
        }
        withAnimation(
            .easeIn(duration: 1.5)
            .delay(delay + 1.5)
        ) {
            opacity = 0
        }
    }
}

#Preview {
    WinOverlayView(elapsedTime: 45.3, difficulty: .easy, onPlayAgain: {})
}
