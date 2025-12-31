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
                    if let errorMessage = viewModel.errorMessage {
                        errorStateView(message: errorMessage) {
                            Task {
                                await viewModel.loadInsights()
                            }
                        }
                    } else if viewModel.isLoading {
                        Text("Loading insights...")
                            .foregroundStyle(.secondary)
                    } else {
                        insightCards
                    }
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
            if viewModel.insights.isEmpty {
                Text("No insights yet.")
                    .foregroundStyle(.secondary)
            }
            ForEach(viewModel.insights) { insight in
                VStack(alignment: .leading, spacing: 6) {
                    Text(insight.title)
                        .font(.headline)
                    Text(insight.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(insight.detail)
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func errorStateView(message: String, retry: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(message)
                .foregroundStyle(.secondary)
            Button("Retry", action: retry)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    InsightsView()
}
