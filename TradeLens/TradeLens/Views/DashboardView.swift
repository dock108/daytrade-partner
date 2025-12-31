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
                        .transition(.opacity)
                    } else if viewModel.isLoading {
                        Text("Loading summary...")
                            .foregroundStyle(.secondary)
                            .transition(.opacity)
                    } else if let summary = viewModel.summary {
                        statsSection(summary: summary)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        insightSection(summary: summary)
                            .transition(.opacity)
                        tickerSection(summary: summary)
                            .transition(.opacity)
                        tradesSection
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        Text("No summary available.")
                            .foregroundStyle(.secondary)
                            .transition(.opacity)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
            .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
            .animation(.easeInOut(duration: 0.2), value: viewModel.summary != nil)
            .animation(.easeInOut(duration: 0.2), value: viewModel.trades.count)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your trading story")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Text("A quick look at how you trade.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statsSection(summary: UserSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key stats")
                .font(.headline)
                .foregroundStyle(.primary)

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
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 12)
                Text(value)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(.secondary)
                Text(value)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(value))
        .padding(.vertical, 4)
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
