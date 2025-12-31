//
//  TradeModelsTests.swift
//  TradeLensTests
//

import XCTest
@testable import TradeLens

final class TradeModelsTests: XCTestCase {
    func testHoldingDaysReturnsNilForOpenTrade() {
        let trade = Trade(
            ticker: "AAPL",
            entryDate: Date(),
            qty: 10,
            entryPrice: 150,
            category: .core
        )

        XCTAssertNil(trade.holdingDays)
    }

    func testHoldingDaysCalculatesDayDifference() {
        let calendar = Calendar.current
        let entryDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1)) ?? Date()
        let exitDate = calendar.date(byAdding: .day, value: 10, to: entryDate) ?? entryDate

        let trade = Trade(
            ticker: "NVDA",
            entryDate: entryDate,
            exitDate: exitDate,
            qty: 5,
            entryPrice: 300,
            exitPrice: 330,
            category: .speculative
        )

        XCTAssertEqual(trade.holdingDays, 10)
    }

    func testComputedRealizedPnLPrefersExplicitValue() {
        let trade = Trade(
            ticker: "TSLA",
            entryDate: Date(),
            exitDate: Date(),
            qty: 2,
            entryPrice: 100,
            exitPrice: 120,
            realizedPnL: 55,
            category: .speculative
        )

        XCTAssertEqual(trade.computedRealizedPnL, 55)
    }
}
