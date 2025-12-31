//
//  TradeLensApp.swift
//  TradeLens
//
//  Main application entry point for TradeLens
//

import SwiftUI

/// Main application structure that defines the app lifecycle
@main
struct TradeLensApp: App {
    @StateObject private var preferencesManager = UserPreferencesManager.shared
    @State private var showOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Check if onboarding is needed
                    if preferencesManager.needsOnboarding {
                        showOnboarding = true
                    }
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView(isPresented: $showOnboarding)
                }
        }
    }
}
