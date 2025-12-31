//
//  TradeDetailViewModel.swift
//  TradeLens
//
//  ViewModel for the trade detail screen.
//

import SwiftUI

@MainActor
final class TradeDetailViewModel: ObservableObject {
    let trade: MockTrade

    private let analyticsService: TradeAnalyticsService

    init(trade: MockTrade, analyticsService: TradeAnalyticsService = TradeAnalyticsService()) {
        self.trade = trade
        self.analyticsService = analyticsService
    }

    var ticker: String {
        trade.ticker
    }

    var entryDateText: String {
        format(date: trade.entryDate)
    }

    var exitDateText: String {
        format(date: trade.exitDate)
    }

    var holdDaysText: String {
        let days = analyticsService.holdingDays(for: trade)
        return "\(days)" + (days == 1 ? " day" : " days")
    }

    var pnlText: String {
        CurrencyFormatter.formatUSD(trade.realizedPnL)
    }

    var pnlColor: Color {
        if trade.realizedPnL > 0 { return .green }
        if trade.realizedPnL < 0 { return .red }
        return .secondary
    }

    var categoryText: String {
        trade.category == .core ? "Core" : "Speculative"
    }

    var summaryText: String {
        analyticsService.tradeSummary(for: trade)
    }

    private func format(date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().year())
    }
}
