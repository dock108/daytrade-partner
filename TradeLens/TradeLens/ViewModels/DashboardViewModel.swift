//
//  DashboardViewModel.swift
//  TradeLens
//
//  ViewModel for the dashboard summary view.
//

import Foundation
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var trades: [MockTrade] = []
    @Published var summary: UserSummary?
    @Published var riskMessage = ""

    private let tradeService: MockTradeDataService

    init(tradeService: MockTradeDataService = MockTradeDataService()) {
        self.tradeService = tradeService
        loadDashboard()
    }

    func loadDashboard() {
        let trades = tradeService.fetchMockTrades()
        self.trades = trades
        let summary = buildSummary(from: trades)
        self.summary = summary
        riskMessage = message(for: summary.speculativePercent)
    }

    private func buildSummary(from trades: [MockTrade]) -> UserSummary {
        let totalTrades = trades.count
        let wins = trades.filter { $0.realizedPnL > 0 }.count
        let winRate = totalTrades > 0 ? Double(wins) / Double(totalTrades) : 0
        let realizedPnLTotal = trades.reduce(0) { $0 + $1.realizedPnL }
        let avgHoldDays = averageHoldDays(for: trades)
        let speculativePercent = speculativeShare(for: trades)
        let (bestTicker, worstTicker) = tickerExtremes(for: trades)

        return UserSummary(
            totalTrades: totalTrades,
            winRate: winRate,
            avgHoldDays: avgHoldDays,
            bestTicker: bestTicker,
            worstTicker: worstTicker,
            speculativePercent: speculativePercent,
            realizedPnLTotal: realizedPnLTotal
        )
    }

    private func averageHoldDays(for trades: [MockTrade]) -> Double {
        guard !trades.isEmpty else { return 0 }
        let totalDays = trades.reduce(0) { partial, trade in
            let days = Calendar.current.dateComponents([.day], from: trade.entryDate, to: trade.exitDate).day ?? 0
            return partial + days
        }
        return Double(totalDays) / Double(trades.count)
    }

    private func speculativeShare(for trades: [MockTrade]) -> Double {
        guard !trades.isEmpty else { return 0 }
        let speculativeCount = trades.filter { $0.category == .speculative }.count
        return Double(speculativeCount) / Double(trades.count)
    }

    private func tickerExtremes(for trades: [MockTrade]) -> (String?, String?) {
        guard !trades.isEmpty else { return (nil, nil) }
        let totals = trades.reduce(into: [String: Double]()) { result, trade in
            result[trade.ticker, default: 0] += trade.realizedPnL
        }
        let sortedTotals = totals.sorted { $0.value < $1.value }
        return (sortedTotals.last?.key, sortedTotals.first?.key)
    }

    private func message(for speculativePercent: Double) -> String {
        switch speculativePercent {
        case ..<0.3:
            return "You lean risk-averse"
        case 0.3..<0.6:
            return "You balance core and speculative"
        default:
            return "You lean risk-on"
        }
    }
}
