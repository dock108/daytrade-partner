//
//  ContentView.swift
//  TradeLens
//
//  Main content view for the application
//

import SwiftUI

/// Main view of the application
struct ContentView: View {
    var body: some View {
        TabView {
            // Dashboard summary tab.
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar")
                }

            // Ask tab for quick questions.
            AskView()
                .tabItem {
                    Label("Ask", systemImage: "questionmark.circle")
                }

            // Insights tab for pattern summaries.
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "lightbulb")
                }
        }
    }
}

/// Preview provider for ContentView
#Preview {
    ContentView()
}
