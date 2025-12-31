//
//  TradeDetailView.swift
//  TradeLens
//
//  Detailed trade view.
//

import SwiftUI

struct TradeDetailView: View {
    @StateObject private var viewModel: TradeDetailViewModel

    init(trade: MockTrade) {
        _viewModel = StateObject(wrappedValue: TradeDetailViewModel(trade: trade))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                timingSection
                summarySection
            }
            .padding()
        }
        .navigationTitle(viewModel.ticker)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.ticker)
                .font(.largeTitle)
                .fontWeight(.bold)

            HStack(spacing: 12) {
                Text(viewModel.categoryText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())

                Spacer()

                Text(viewModel.pnlText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.pnlColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trade timing")
                .font(.headline)

            detailRow(title: "Entry date", value: viewModel.entryDateText)
            detailRow(title: "Exit date", value: viewModel.exitDateText)
            detailRow(title: "Hold days", value: viewModel.holdDaysText)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Summary")
                .font(.headline)
            Text(viewModel.summaryText)
                .font(.body)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    NavigationStack {
        TradeDetailView(
            trade: MockTrade(
                id: UUID(),
                ticker: "NVDA",
                entryDate: Date().addingTimeInterval(-9 * 86_400),
                exitDate: Date(),
                qty: 12,
                entryPrice: 820,
                exitPrice: 900,
                realizedPnL: 960,
                category: .speculative
            )
        )
    }
}
