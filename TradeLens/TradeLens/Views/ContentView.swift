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
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .font(.system(size: 60))
                
                Text("TradeLens")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your Trading Partner")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

/// Preview provider for ContentView
#Preview {
    ContentView()
}
