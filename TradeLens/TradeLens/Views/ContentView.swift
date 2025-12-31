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

            AskView()
                .tabItem {
                    Label("Ask", systemImage: "questionmark.circle")
                }

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "lightbulb")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
}
