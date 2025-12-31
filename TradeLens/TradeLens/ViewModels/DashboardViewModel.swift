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
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let tradeService: MockTradeDataService
    private let analyticsService: TradeAnalyticsService

    init(
        tradeService: MockTradeDataService = MockTradeDataService(),
        analyticsService: TradeAnalyticsService = TradeAnalyticsService()
    ) {
        self.tradeService = tradeService
        self.analyticsService = analyticsService
        Task {
            await loadDashboard()
        }
    }

    func loadDashboard() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        summary = nil
        riskMessage = ""

        do {
            let trades = try await tradeService.fetchMockTrades()
            self.trades = trades
            let summary = buildSummary(from: trades)
            self.summary = summary
            riskMessage = message(for: summary.speculativePercent)
        } catch is CancellationError {
            return
        } catch {
            let appError = AppError(error)
            errorMessage = appError.userMessage
            trades = []
        }
    }

    private func buildSummary(from trades: [MockTrade]) -> UserSummary {
        let totalTrades = trades.count
        let wins = trades.filter { $0.realizedPnL > 0 }.count
        let winRate = totalTrades > 0 ? Double(wins) / Double(totalTrades) : 0
        let realizedPnLTotal = trades.reduce(0) { $0 + $1.realizedPnL }
        let avgHoldDays = analyticsService.averageHoldingDays(for: trades)
        let speculativePercent = analyticsService.speculativeShare(for: trades)
        let (bestTicker, worstTicker) = analyticsService.tickerExtremes(for: trades)

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
