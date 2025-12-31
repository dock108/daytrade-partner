//
//  InsightsService.swift
//  TradeLens
//
//  Generates lightweight behavioral insights from mock trade data.
//

import Foundation

struct InsightsService {
    struct InsightItem {
        let title: String
        let subtitle: String
        let detail: String
    }

    func generateInsights(from trades: [MockTrade]) -> [InsightItem] {
        [
            holdingPeriodInsight(from: trades),
            volatilityInsight(from: trades),
            speculativeImpactInsight(from: trades),
            holdingDisciplineInsight(from: trades),
            overConcentrationInsight(from: trades),
            speculativeDragInsight(from: trades)
        ]
    }

    private func holdingPeriodInsight(from trades: [MockTrade]) -> InsightItem {
        let preferredRangeLabel = "5–15"
        let bestRangeLabel = bestHoldingRangeLabel(from: trades) ?? preferredRangeLabel
        return InsightItem(
            title: "Holding Range",
            subtitle: "Where your strongest PnL appears",
            detail: "You perform best holding \(bestRangeLabel) days"
        )
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

    private func volatilityInsight(from trades: [MockTrade]) -> InsightItem {
        let highVolTickers = Set(trades.filter { isHighVolatility(trade: $0) }.map { $0.ticker })
        let highVolLosses = trades.filter { highVolTickers.contains($0.ticker) && $0.realizedPnL < 0 }
        let detail: String
        if highVolLosses.isEmpty {
            detail = "High volatility names have been less of a drag recently"
        } else {
            detail = "High volatility names drove \(highVolLosses.count) losing trades"
        }
        return InsightItem(
            title: "Volatility Impact",
            subtitle: "Losses tied to faster movers",
            detail: detail
        )
    }

    private func speculativeImpactInsight(from trades: [MockTrade]) -> InsightItem {
        guard !trades.isEmpty else {
            return InsightItem(
                title: "Speculative Impact",
                subtitle: "Share of wins or losses",
                detail: "Speculative trades make up 0% but drive 0% of losses"
            )
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

        return InsightItem(
            title: "Speculative Impact",
            subtitle: "Share of wins or losses",
            detail: "Speculative trades make up \(Int(sharePercent))% but drive \(Int(impactPercent))% of \(impactLabel)"
        )
    }

    private func holdingDisciplineInsight(from trades: [MockTrade]) -> InsightItem {
        let winningTrades = trades.filter { $0.realizedPnL > 0 }
        let losingTrades = trades.filter { $0.realizedPnL < 0 }
        guard !winningTrades.isEmpty, !losingTrades.isEmpty else {
            return InsightItem(
                title: "Holding Discipline",
                subtitle: "Winner vs loser exit timing",
                detail: "Not enough winning and losing trades to compare exits"
            )
        }

        let winningAverage = averageHoldingDays(for: winningTrades)
        let losingAverage = averageHoldingDays(for: losingTrades)
        let detail: String
        if winningAverage < losingAverage {
            detail = "You tend to cut winners faster than losers — this increases drawdowns."
        } else if winningAverage > losingAverage {
            detail = "Winners are held longer than losers — exit timing looks balanced."
        } else {
            detail = "Winners and losers are held for similar stretches."
        }

        return InsightItem(
            title: "Holding Discipline",
            subtitle: "Winner vs loser exit timing",
            detail: detail
        )
    }

    private func overConcentrationInsight(from trades: [MockTrade]) -> InsightItem {
        guard !trades.isEmpty else {
            return InsightItem(
                title: "Over-Concentration Risk",
                subtitle: "Largest ticker share of capital at risk",
                detail: "No capital at risk tracked yet"
            )
        }

        let riskByTicker = Dictionary(grouping: trades, by: { $0.ticker }).mapValues { tickerTrades in
            tickerTrades.reduce(0) { $0 + abs($1.entryPrice * $1.qty) }
        }

        let totalRisk = riskByTicker.values.reduce(0, +)
        guard totalRisk > 0, let topTicker = riskByTicker.max(by: { $0.value < $1.value }) else {
            return InsightItem(
                title: "Over-Concentration Risk",
                subtitle: "Largest ticker share of capital at risk",
                detail: "No capital at risk tracked yet"
            )
        }

        let share = topTicker.value / totalRisk
        let percent = Int((share * 100).rounded())
        let detail: String
        if share > 0.25 {
            detail = "\(topTicker.key) represents \(percent)% of capital at risk."
        } else {
            detail = "No ticker is above 25% of capital at risk."
        }

        return InsightItem(
            title: "Over-Concentration Risk",
            subtitle: "Largest ticker share of capital at risk",
            detail: detail
        )
    }

    private func speculativeDragInsight(from trades: [MockTrade]) -> InsightItem {
        guard !trades.isEmpty else {
            return InsightItem(
                title: "Speculative Drag",
                subtitle: "Speculative vs core PnL contribution",
                detail: "Speculative and core PnL are evenly balanced."
            )
        }

        let speculativePnL = trades.filter { $0.category == .speculative }.reduce(0) { $0 + $1.realizedPnL }
        let corePnL = trades.filter { $0.category == .core }.reduce(0) { $0 + $1.realizedPnL }

        let detail: String
        if speculativePnL == 0 && corePnL == 0 {
            detail = "Speculative and core PnL are flat overall."
        } else if speculativePnL == corePnL {
            detail = "Speculative and core PnL are aligned."
        } else if speculativePnL < corePnL {
            let gap = CurrencyFormatter.formatUSD(abs(corePnL - speculativePnL))
            detail = "Speculative PnL trails core by \(gap)."
        } else {
            let gap = CurrencyFormatter.formatUSD(abs(speculativePnL - corePnL))
            detail = "Speculative PnL leads core by \(gap)."
        }

        return InsightItem(
            title: "Speculative Drag",
            subtitle: "Speculative vs core PnL contribution",
            detail: detail
        )
    }

    private func averageHoldingDays(for trades: [MockTrade]) -> Double {
        let totalDays = trades.reduce(0) { $0 + holdingDays(for: $1) }
        return trades.isEmpty ? 0 : Double(totalDays) / Double(trades.count)
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
