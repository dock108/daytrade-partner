//
//  MockTradeDataService.swift
//  TradeLens
//
//  Generates realistic mock trade history for UI previews
//

import Foundation

/// Category describing the risk profile of a trade
enum MockTradeCategory: String, Codable {
    case core
    case speculative
}

/// Represents a closed trade with realized profit/loss
struct MockTrade: Identifiable, Codable {
    let id: UUID
    let ticker: String
    let entryDate: Date
    let exitDate: Date
    let qty: Double
    let entryPrice: Double
    let exitPrice: Double
    let realizedPnL: Double
    let category: MockTradeCategory
}

/// Service responsible for generating mock trades
struct MockTradeDataService {
    private let calendar = Calendar.current

    private let coreHoldings = ["QQQ", "SPY", "AAPL", "UNH", "BND"]
    private let speculativePlays = ["TSLA", "COIN", "NVDA", "MRNA", "VRTX", "BIIB", "SRPT", "EXEL", "CRSP", "EDIT", "NTLA"]

    private let basePrices: [String: Double] = [
        "QQQ": 450,
        "SPY": 520,
        "AAPL": 190,
        "UNH": 520,
        "BND": 72,
        "TSLA": 230,
        "COIN": 210,
        "NVDA": 880,
        "MRNA": 110,
        "VRTX": 410,
        "BIIB": 220,
        "SRPT": 125,
        "EXEL": 23,
        "CRSP": 55,
        "EDIT": 7,
        "NTLA": 30
    ]

    /// Generate a realistic set of closed trades for UI display.
    func fetchMockTrades() async throws -> [MockTrade] {
        do {
            try await Task.sleep(nanoseconds: 250_000_000)
        } catch {
            throw AppError(error)
        }

        let tradeCount = Int.random(in: 50...120)
        var trades: [MockTrade] = []
        trades.reserveCapacity(tradeCount)

        for _ in 0..<tradeCount {
            let category = randomCategory()
            let ticker = randomTicker(for: category)
            let entryDate = randomEntryDate()
            let holdingDays = randomHoldingDays(since: entryDate)
            let exitDate = calendar.date(byAdding: .day, value: holdingDays, to: entryDate) ?? entryDate
            let entryPrice = randomEntryPrice(for: ticker, category: category)
            let returnPct = randomReturnPct(for: category)
            let exitPrice = max(0.5, entryPrice * (1 + returnPct))
            let qty = randomQuantity(for: ticker, category: category)
            let realizedPnL = (exitPrice - entryPrice) * qty

            let trade = MockTrade(
                id: UUID(),
                ticker: ticker,
                entryDate: entryDate,
                exitDate: exitDate,
                qty: qty,
                entryPrice: entryPrice.rounded(toPlaces: 2),
                exitPrice: exitPrice.rounded(toPlaces: 2),
                realizedPnL: realizedPnL.rounded(toPlaces: 2),
                category: category
            )
            trades.append(trade)
        }

        let sortedTrades = trades.sorted { $0.exitDate > $1.exitDate }
        guard !sortedTrades.isEmpty else {
            throw AppError.emptyData
        }
        return sortedTrades
    }

    private func randomCategory() -> MockTradeCategory {
        Double.random(in: 0...1) < 0.7 ? .core : .speculative
    }

    private func randomTicker(for category: MockTradeCategory) -> String {
        switch category {
        case .core:
            return coreHoldings.randomElement() ?? "QQQ"
        case .speculative:
            return speculativePlays.randomElement() ?? "TSLA"
        }
    }

    private func randomEntryDate() -> Date {
        let daysBack = Int.random(in: 5...330)
        return calendar.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
    }

    private func randomHoldingDays(since entryDate: Date) -> Int {
        let daysSinceEntry = calendar.dateComponents([.day], from: entryDate, to: Date()).day ?? 0
        let cappedMax = min(180, max(1, daysSinceEntry))
        return Int.random(in: 1...cappedMax)
    }

    private func randomEntryPrice(for ticker: String, category: MockTradeCategory) -> Double {
        let base = basePrices[ticker] ?? 100
        let variance: ClosedRange<Double> = category == .core ? -0.06...0.06 : -0.12...0.12
        return base * (1 + Double.random(in: variance))
    }

    private func randomReturnPct(for category: MockTradeCategory) -> Double {
        switch category {
        case .core:
            let roll = Double.random(in: 0...1)
            if roll < 0.1 {
                return Double.random(in: 0.10...0.25)
            }
            if roll < 0.2 {
                return Double.random(in: -0.15...-0.05)
            }
            return Double.random(in: -0.06...0.08)
        case .speculative:
            let roll = Double.random(in: 0...1)
            if roll < 0.15 {
                return Double.random(in: 0.30...0.90)
            }
            if roll < 0.3 {
                return Double.random(in: -0.60...-0.25)
            }
            return Double.random(in: -0.15...0.20)
        }
    }

    private func randomQuantity(for ticker: String, category: MockTradeCategory) -> Double {
        let coreRange: ClosedRange<Double>
        switch ticker {
        case "QQQ", "SPY":
            coreRange = 25...160
        case "AAPL":
            coreRange = 50...320
        case "UNH":
            coreRange = 12...90
        case "BND":
            coreRange = 80...300
        default:
            coreRange = 20...120
        }

        let quantity = Double.random(in: coreRange)
        return category == .core ? quantity : max(1, quantity / 15)
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
