//
//  AIServiceStub.swift
//  TradeLens
//
//  Stub AI service for the Ask Anything screen.
//

import Foundation

@MainActor
final class AIServiceStub {
    private let tradeService: MockTradeDataService
    private let analyticsService: TradeAnalyticsService
    private let insightsService: InsightsService

    private var summary: UserSummary?
    private var insights: [InsightsService.InsightItem] = []
    private var isLoading = false

    init(
        tradeService: MockTradeDataService = MockTradeDataService(),
        analyticsService: TradeAnalyticsService = TradeAnalyticsService(),
        insightsService: InsightsService = InsightsService()
    ) {
        self.tradeService = tradeService
        self.analyticsService = analyticsService
        self.insightsService = insightsService

        Task {
            await loadContext()
        }
    }

    func response(for question: String) -> String {
        let normalized = question.lowercased()
        let base = baseResponse(for: normalized)
        let personalized = personalizedAddendum(for: normalized)

        guard !personalized.isEmpty else {
            return base
        }

        return "\(base)\n\n\(personalized)"
    }

    private func loadContext() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let trades = try await tradeService.fetchMockTrades()
            summary = buildSummary(from: trades)
            insights = insightsService.generateInsights(from: trades)
        } catch {
            summary = nil
            insights = []
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

    private func baseResponse(for normalized: String) -> String {
        if normalized.contains("oil") {
            return "Oil prices often react to supply headlines, OPEC+ production plans, and inventory data. Short-term moves can be choppy, while longer trends track global demand growth and refinery capacity. It helps to watch energy sector guidance for how companies are managing costs and output."
        }

        if normalized.contains("gold") {
            return "Gold is sensitive to real yields, the U.S. dollar, and risk sentiment. When inflation expectations rise faster than rates, gold can look more attractive, but it also fades when yields climb. Central bank demand and ETF flows add another layer to the trend."
        }

        if normalized.contains("qqq") {
            return "QQQ is concentrated in large-cap growth and tech, so it tends to track rate expectations and earnings from mega-cap leaders. When growth forecasts improve, it can outperform, while higher rates often pressure valuations. Keeping an eye on sector breadth helps gauge how durable a move is."
        }

        if normalized.contains("spy") {
            return "SPY reflects the broad S&P 500, so its tone is shaped by overall earnings, macro data, and risk sentiment. Leadership shifts between cyclicals and defensives can hint at market conviction. It’s useful to watch how many sectors are contributing to moves."
        }

        if normalized.contains("inflation") {
            return "Inflation trends are influenced by wage growth, shelter costs, and energy prices. Markets tend to focus on the direction of change rather than the absolute level. Softer inflation often eases pressure on rates, while sticky components can keep volatility elevated."
        }

        if normalized.contains("earnings") {
            return "Earnings seasons are all about guidance, margins, and how companies talk about demand. Even strong headline beats can be tempered by cautious outlooks. Pay attention to revisions and commentary on costs, because that often drives follow-through."
        }

        return "I can share market context on a ticker, sector, or macro theme. Try asking about oil, gold, QQQ, SPY, inflation, or earnings to see a sample response."
    }

    private func personalizedAddendum(for normalized: String) -> String {
        guard let summary else {
            return ""
        }

        var sentences: [String] = []
        let winRate = CurrencyFormatter.formatPercentage(summary.winRate)
        let avgHoldDays = Int(summary.avgHoldDays.rounded())
        let pnl = CurrencyFormatter.formatUSD(summary.realizedPnLTotal)
        sentences.append(
            "From your dashboard summary, you have \(summary.totalTrades) closed trades with a \(winRate) win rate and an average hold of \(avgHoldDays) days (\(pnl) total PnL)."
        )

        if let bestTicker = summary.bestTicker {
            sentences.append("Your strongest ticker recently has been \(bestTicker).")
        }

        if let worstTicker = summary.worstTicker {
            sentences.append("The weakest stretch has been in \(worstTicker).")
        }

        let holdingInsight = insights.first { $0.title == "Holding Range" }
        let speculativeInsight = insights.first { $0.title == "Speculative Impact" }

        if let holdingInsight, let rangeLabel = holdingRangeLabel(from: holdingInsight.detail) {
            if normalized.contains("qqq") || normalized.contains("spy") {
                sentences.append("Historically, your trades in large-cap ETFs do well when held \(rangeLabel) days.")
            } else {
                sentences.append("\(holdingInsight.detail).")
            }
        }

        if let speculativeInsight {
            sentences.append("\(speculativeInsight.detail).")
        }

        return sentences.joined(separator: " ")
    }

    private func holdingRangeLabel(from detail: String) -> String? {
        let marker = "holding "
        guard let rangeStart = detail.range(of: marker) else { return nil }
        let remainder = detail[rangeStart.upperBound...]
        return remainder.replacingOccurrences(of: " days", with: "")
    }
}
