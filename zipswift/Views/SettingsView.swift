//
//  SettingsView.swift
//  zipswift
//
//  Settings screen with sound, haptics, accent color, and app info.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    @State private var settings = SettingsManager.shared
    @State private var showResetConfirmation = false
    @State private var showClearHistoryConfirmation = false

    private let historyManager = GameHistoryManager.shared

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Sound & Haptics
                Section {
                    Toggle(isOn: $settings.soundEnabled) {
                        Label("Sound Effects", systemImage: "speaker.wave.2")
                    }

                    if settings.soundEnabled {
                        NavigationLink {
                            SoundThemePicker(selectedTheme: $settings.audioTheme)
                        } label: {
                            HStack {
                                Label("Sound Theme", systemImage: settings.audioTheme.icon)
                                Spacer()
                                Text(settings.audioTheme.displayName)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Toggle(isOn: $settings.hapticsEnabled) {
                        Label("Haptic Feedback", systemImage: "hand.tap")
                    }
                } header: {
                    Text("Audio & Feedback")
                }

                // MARK: - Appearance
                Section {
                    NavigationLink {
                        AccentColorPicker(selectedColor: $settings.accentColor)
                    } label: {
                        HStack {
                            Label("Accent Color", systemImage: "paintpalette")
                            Spacer()
                            Circle()
                                .fill(settings.accentColor.color)
                                .frame(width: 24, height: 24)
                        }
                    }
                } header: {
                    Text("Appearance")
                }

                // MARK: - Gameplay
                Section {
                    Toggle(isOn: $settings.showBestTime) {
                        Label("Show Best Time", systemImage: "trophy")
                    }

                    Picker(selection: $settings.defaultDifficulty) {
                        Text("Easy").tag(Difficulty.easy)
                        Text("Medium").tag(Difficulty.medium)
                        Text("Hard").tag(Difficulty.hard)
                    } label: {
                        Label("Default Difficulty", systemImage: "slider.horizontal.3")
                    }
                } header: {
                    Text("Gameplay")
                }

                // MARK: - Data
                Section {
                    Button(role: .destructive) {
                        showClearHistoryConfirmation = true
                    } label: {
                        Label("Clear Game History", systemImage: "trash")
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("This will permanently delete all your game records and statistics.")
                }

                // MARK: - About
                Section {
                    Button {
                        requestReview()
                    } label: {
                        Label("Rate ZipSwift", systemImage: "star")
                    }

                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    Link(destination: URL(string: "https://example.com/support")!) {
                        Label("Support", systemImage: "questionmark.circle")
                    }
                } header: {
                    Text("About")
                }

                // MARK: - App Info
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(AppInfo.fullVersion)
                            .foregroundColor(.secondary)
                    }

                    Button {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset All Settings", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.primary)
                    }
                } footer: {
                    Text("Made with love for puzzle enthusiasts")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Reset All Settings?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    settings.resetToDefaults()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will restore all settings to their default values.")
            }
            .confirmationDialog(
                "Clear Game History?",
                isPresented: $showClearHistoryConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear All", role: .destructive) {
                    historyManager.clearAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. All your game records will be permanently deleted.")
            }
            .tint(settings.accentColor.color)
        }
    }
}

// MARK: - Accent Color Picker

struct AccentColorPicker: View {
    @Binding var selectedColor: AccentColorOption
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 70))
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(AccentColorOption.allCases, id: \.self) { option in
                    ColorOption(
                        color: option,
                        isSelected: selectedColor == option
                    ) {
                        selectedColor = option
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Accent Color")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ColorOption: View {
    let color: AccentColorOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.color)
                        .frame(width: 50, height: 50)

                    if isSelected {
                        Circle()
                            .strokeBorder(.white, lineWidth: 3)
                            .frame(width: 50, height: 50)

                        Image(systemName: "checkmark")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .shadow(color: color.color.opacity(0.4), radius: isSelected ? 8 : 4)

                Text(color.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? color.color : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sound Theme Picker

struct SoundThemePicker: View {
    @Binding var selectedTheme: AudioTheme

    private let audioManager = AudioManager.shared
    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        List {
            ForEach(AudioTheme.allCases, id: \.self) { theme in
                SoundThemeRow(
                    theme: theme,
                    isSelected: selectedTheme == theme,
                    onSelect: {
                        selectedTheme = theme
                    },
                    onPreview: {
                        audioManager.previewTheme(theme)
                    }
                )
            }
        }
        .navigationTitle("Sound Theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SoundThemeRow: View {
    let theme: AudioTheme
    let isSelected: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void

    private var accentColor: Color { SettingsManager.shared.accentColor.color }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: theme.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? accentColor : .secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text(theme.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onPreview) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(accentColor)
                }
                .buttonStyle(.plain)

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(accentColor)
                        .font(.body.weight(.semibold))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
}
