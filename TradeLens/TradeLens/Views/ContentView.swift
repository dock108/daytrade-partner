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
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar")
                }

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "sparkles")
                }

            AskView()
                .tabItem {
                    Label("Ask", systemImage: "bubble.left.and.bubble.right")
                }
        }
    }
}

/// Preview provider for ContentView
#Preview {
    ContentView()
}
