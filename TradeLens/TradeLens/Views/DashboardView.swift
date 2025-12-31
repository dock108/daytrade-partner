//
//  DashboardView.swift
//  TradeLens
//
//  Dashboard summary view.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    if let errorMessage = viewModel.errorMessage {
                        errorStateView(message: errorMessage) {
                            Task {
                                await viewModel.loadDashboard()
                            }
                        }
                    } else if viewModel.isLoading {
                        Text("Loading summary...")
                            .foregroundStyle(.secondary)
                    } else if let summary = viewModel.summary {
                        statsSection(summary: summary)
                        insightSection(summary: summary)
                        tickerSection(summary: summary)
                        tradesSection
                    } else {
                        Text("No summary available.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your trading story")
                .font(.title2)
                .fontWeight(.semibold)
            Text("A quick look at how you trade.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statsSection(summary: UserSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key stats")
                .font(.headline)

            statRow(title: "Total trades", value: "\(summary.totalTrades)")
            statRow(title: "Win rate", value: summary.winRate.formatted(.percent.precision(.fractionLength(0))))
            statRow(title: "Realized P/L", value: summary.realizedPnLTotal.formatted(.currency(code: "USD")))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func insightSection(summary: UserSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Risk profile")
                .font(.headline)
            Text(viewModel.riskMessage)
                .font(.body)
            Text("Speculative trades: \(summary.speculativePercent.formatted(.percent.precision(.fractionLength(0))))")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func tickerSection(summary: UserSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Best vs worst ticker")
                .font(.headline)

            statRow(title: "Best", value: summary.bestTicker ?? "—")
            statRow(title: "Worst", value: summary.worstTicker ?? "—")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var tradesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent trades")
                .font(.headline)

            if viewModel.trades.isEmpty {
                Text("No trades yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.trades.prefix(5)) { trade in
                    NavigationLink {
                        TradeDetailView(trade: trade)
                    } label: {
                        TradeRowView(trade: trade)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
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
    DashboardView()
}
