//
//  ContentView.swift
//  zipswift
//
//  Created by brianchew on 7/1/26.
//

import SwiftUI

struct ContentView: View {
    @State private var showOnboarding = false

    private var settings: SettingsManager { SettingsManager.shared }

    var body: some View {
        GameView()
            .onAppear {
                if !settings.hasCompletedOnboarding {
                    showOnboarding = true
                }
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView()
            }
    }
}

#Preview {
    ContentView()
}
