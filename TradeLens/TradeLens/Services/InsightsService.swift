//
//  InsightsService.swift
//  TradeLens
//
//  Generates lightweight behavioral insights from mock trade data.
//

import Foundation

struct InsightsService {
    func generateInsights(from trades: [MockTrade]) -> [String] {
        [
            holdingPeriodInsight(from: trades),
            volatilityInsight(from: trades),
            speculativeImpactInsight(from: trades)
        ]
    }

    private func holdingPeriodInsight(from trades: [MockTrade]) -> String {
        let preferredRangeLabel = "5–15"
        let bestRangeLabel = bestHoldingRangeLabel(from: trades) ?? preferredRangeLabel
        return "You perform best holding \(bestRangeLabel) days"
    }

    private func bestHoldingRangeLabel(from trades: [MockTrade]) -> String? {
        let ranges: [(label: String, range: ClosedRange<Int>)] = [
            ("1–4", 1...4),
            ("5–15", 5...15),
            ("16–45", 16...45),
            ("46+", 46...365)
        ]

        let grouped = Dictionary(grouping: trades) { trade in
            let days = holdingDays(for: trade)
            return ranges.first { $0.range.contains(days) }?.label ?? "46+"
        }

        let averages = grouped.mapValues { groupedTrades -> Double in
            let total = groupedTrades.reduce(0) { $0 + $1.realizedPnL }
            return groupedTrades.isEmpty ? 0 : total / Double(groupedTrades.count)
        }

        return averages.max(by: { $0.value < $1.value })?.key
    }

    private func volatilityInsight(from trades: [MockTrade]) -> String {
        let highVolTickers = Set(trades.filter { isHighVolatility(trade: $0) }.map { $0.ticker })
        let highVolLosses = trades.filter { highVolTickers.contains($0.ticker) && $0.realizedPnL < 0 }
        _ = highVolLosses.count
        return "Losses cluster during high volatility tickers"
    }

    private func speculativeImpactInsight(from trades: [MockTrade]) -> String {
        guard !trades.isEmpty else {
            return "Speculative trades make up 0% but drive 0% of losses"
        }

        let speculativeTrades = trades.filter { $0.category == .speculative }
        let speculativeShare = Double(speculativeTrades.count) / Double(trades.count)

        let totalWins = trades.filter { $0.realizedPnL > 0 }.reduce(0) { $0 + $1.realizedPnL }
        let totalLosses = trades.filter { $0.realizedPnL < 0 }.reduce(0) { $0 + abs($1.realizedPnL) }

        let speculativeWins = speculativeTrades.filter { $0.realizedPnL > 0 }.reduce(0) { $0 + $1.realizedPnL }
        let speculativeLosses = speculativeTrades.filter { $0.realizedPnL < 0 }.reduce(0) { $0 + abs($1.realizedPnL) }

        let drivesWins = totalWins >= totalLosses
        let totalImpact = drivesWins ? totalWins : totalLosses
        let speculativeImpact = drivesWins ? speculativeWins : speculativeLosses
        let impactShare = totalImpact > 0 ? speculativeImpact / totalImpact : 0

        let sharePercent = (speculativeShare * 100).rounded()
        let impactPercent = (impactShare * 100).rounded()
        let impactLabel = drivesWins ? "wins" : "losses"

        return "Speculative trades make up \(Int(sharePercent))% but drive \(Int(impactPercent))% of \(impactLabel)"
    }

    private func holdingDays(for trade: MockTrade) -> Int {
        let components = Calendar.current.dateComponents([.day], from: trade.entryDate, to: trade.exitDate)
        return max(1, components.day ?? 1)
    }

    private func isHighVolatility(trade: MockTrade) -> Bool {
        let change = (trade.exitPrice - trade.entryPrice) / trade.entryPrice
        return abs(change) > 0.18
    }
}
