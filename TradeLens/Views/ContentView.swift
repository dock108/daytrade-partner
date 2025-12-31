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
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "sparkles")
                }

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "lightbulb")
                }

            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(Color(red: 0.4, green: 0.7, blue: 1.0))
    }
}

#Preview {
    ContentView()
}
