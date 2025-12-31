//
//  InsightsView.swift
//  TradeLens
//
//  Patterns & Insights screen.
//

import SwiftUI

struct InsightsView: View {
    @StateObject private var viewModel = InsightsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    insightCards
                }
                .padding()
            }
            .navigationTitle("Insights")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Patterns & insights")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Personalized observations from your recent activity.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var insightCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.insights) { insight in
                Text(insight.text)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

#Preview {
    InsightsView()
}
