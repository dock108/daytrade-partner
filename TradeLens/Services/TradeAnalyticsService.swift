//
//  TradeAnalyticsService.swift
//  TradeLens
//
//  Shared calculations for trade analytics.
//

import Foundation

struct TradeAnalyticsService {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func holdingDays(for trade: MockTrade) -> Int {
        let components = calendar.dateComponents([.day], from: trade.entryDate, to: trade.exitDate)
        return max(1, components.day ?? 1)
    }

    func averageHoldingDays(for trades: [MockTrade]) -> Double {
        let totalDays = trades.reduce(0) { $0 + holdingDays(for: $1) }
        return trades.isEmpty ? 0 : Double(totalDays) / Double(trades.count)
    }

    func speculativeShare(for trades: [MockTrade]) -> Double {
        guard !trades.isEmpty else { return 0 }
        let speculativeCount = trades.filter { $0.category == .speculative }.count
        return Double(speculativeCount) / Double(trades.count)
    }

    func tickerExtremes(for trades: [MockTrade]) -> (String?, String?) {
        guard !trades.isEmpty else { return (nil, nil) }
        let totals = trades.reduce(into: [String: Double]()) { result, trade in
            result[trade.ticker, default: 0] += trade.realizedPnL
        }
        let sortedTotals = totals.sorted { $0.value < $1.value }
        return (sortedTotals.last?.key, sortedTotals.first?.key)
    }

    func tradeSummary(for trade: MockTrade) -> String {
        let categoryLabel = trade.category == .core ? "core" : "speculative"
        let days = holdingDays(for: trade)
        let dayLabel = days == 1 ? "day" : "days"
        let exitLabel = exitDescriptor(for: trade)
        return "This was a \(categoryLabel) position held \(days) \(dayLabel). You exited \(exitLabel)."
    }

    private func exitDescriptor(for trade: MockTrade) -> String {
        let change = (trade.exitPrice - trade.entryPrice) / trade.entryPrice
        if change < -0.03 {
            return "during a pullback"
        }
        if change > 0.03 {
            return "into strength"
        }
        return "near your entry"
    }
}
