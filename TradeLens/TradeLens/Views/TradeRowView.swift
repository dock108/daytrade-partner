//
//  TradeRowView.swift
//  TradeLens
//
//  Row view for a single trade summary.
//

import SwiftUI

struct TradeRowView: View {
    let trade: MockTrade

    private let analyticsService = TradeAnalyticsService()

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(trade.ticker)
                    .font(.headline)
                Text(categoryLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyFormatter.formatUSD(trade.realizedPnL))
                    .fontWeight(.semibold)
                    .foregroundStyle(pnlColor)
                Text("Held \(analyticsService.holdingDays(for: trade))d")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var categoryLabel: String {
        trade.category == .core ? "Core" : "Speculative"
    }

    private var pnlColor: Color {
        if trade.realizedPnL > 0 {
            return .green
        }
        if trade.realizedPnL < 0 {
            return .red
        }
        return .secondary
    }
}

#Preview {
    TradeRowView(
        trade: MockTrade(
            id: UUID(),
            ticker: "AAPL",
            entryDate: Date().addingTimeInterval(-7 * 86_400),
            exitDate: Date(),
            qty: 25,
            entryPrice: 180,
            exitPrice: 192,
            realizedPnL: 300,
            category: .core
        )
    )
    .padding()
}
