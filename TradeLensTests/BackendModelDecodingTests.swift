//
//  BackendModelDecodingTests.swift
//  TradeLensTests
//

import XCTest
@testable import TradeLens

final class BackendModelDecodingTests: XCTestCase {
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func testDecodesTickerSnapshot() throws {
        let json = """
        {
          "symbol": "AAPL",
          "name": "Apple Inc.",
          "price": 189.12,
          "changePercent": 1.23,
          "high52w": 199.62,
          "low52w": 124.17,
          "currency": "USD"
        }
        """

        let data = try XCTUnwrap(json.data(using: .utf8))
        let snapshot = try decoder.decode(BackendModels.TickerSnapshot.self, from: data)

        XCTAssertEqual(snapshot.symbol, "AAPL")
        XCTAssertEqual(snapshot.name, "Apple Inc.")
        XCTAssertEqual(snapshot.price, 189.12, accuracy: 0.001)
        XCTAssertEqual(snapshot.changePercent, 1.23, accuracy: 0.001)
        XCTAssertEqual(snapshot.high52w, 199.62, accuracy: 0.001)
        XCTAssertEqual(snapshot.low52w, 124.17, accuracy: 0.001)
        XCTAssertEqual(snapshot.currency, "USD")
    }

    func testDecodesPricePoint() throws {
        let json = """
        {
          "date": "2024-06-14T00:00:00Z",
          "close": 189.12
        }
        """

        let data = try XCTUnwrap(json.data(using: .utf8))
        let point = try decoder.decode(BackendModels.PricePoint.self, from: data)
        let formatter = ISO8601DateFormatter()
        let expectedDate = try XCTUnwrap(formatter.date(from: "2024-06-14T00:00:00Z"))

        XCTAssertEqual(point.date, expectedDate)
        XCTAssertEqual(point.close, 189.12, accuracy: 0.001)
    }

    func testDecodesOutlook() throws {
        let json = """
        {
          "symbol": "NVDA",
          "timeframeDays": 30,
          "sentimentSummary": "positive",
          "historicalHitRate": 0.62,
          "typicalRangePercent": 12.5,
          "volatilityLabel": "moderate",
          "keyDrivers": [
            "AI infrastructure demand",
            "Semiconductor supply trends"
          ]
        }
        """

        let data = try XCTUnwrap(json.data(using: .utf8))
        let outlook = try decoder.decode(BackendModels.Outlook.self, from: data)

        XCTAssertEqual(outlook.symbol, "NVDA")
        XCTAssertEqual(outlook.timeframeDays, 30)
        XCTAssertEqual(outlook.sentimentSummary, "positive")
        XCTAssertEqual(outlook.historicalHitRate, 0.62, accuracy: 0.001)
        XCTAssertEqual(outlook.typicalRangePercent, 12.5, accuracy: 0.001)
        XCTAssertEqual(outlook.volatilityLabel, "moderate")
        XCTAssertEqual(outlook.keyDrivers, ["AI infrastructure demand", "Semiconductor supply trends"])
    }

    func testDecodesAIResponse() throws {
        let json = """
        {
          "whatsHappeningNow": "Shares are up after earnings.",
          "keyDrivers": [
            "Revenue beat",
            "Guidance raise"
          ],
          "riskVsOpportunity": "Momentum is strong but volatility remains elevated.",
          "historicalBehavior": "Typically consolidates after large gaps.",
          "simpleRecap": "Positive momentum with some near-term risk."
        }
        """

        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try decoder.decode(BackendModels.AIResponse.self, from: data)

        XCTAssertEqual(response.whatsHappeningNow, "Shares are up after earnings.")
        XCTAssertEqual(response.keyDrivers, ["Revenue beat", "Guidance raise"])
        XCTAssertEqual(response.riskVsOpportunity, "Momentum is strong but volatility remains elevated.")
        XCTAssertEqual(response.historicalBehavior, "Typically consolidates after large gaps.")
        XCTAssertEqual(response.simpleRecap, "Positive momentum with some near-term risk.")
    }

    func testDecodesOutlookModel() throws {
        let json = """
        {
          "symbol": "TSLA",
          "timeframeDays": 14,
          "catalysts": [
            {
              "title": "Delivery report",
              "impact": "positive",
              "timeframeDays": 7
            }
          ],
          "news": [
            {
              "headline": "Tesla demand holds steady",
              "source": "MarketWatch",
              "publishedAt": "2024-06-14T00:00:00Z",
              "url": "https://example.com/tesla-demand"
            }
          ],
          "expectedRange": {
            "low": 168.5,
            "high": 192.3,
            "percentMove": 12.4
          },
          "historicalStats": {
            "winRate": 0.58,
            "averageMovePercent": 8.2,
            "medianMovePercent": 7.5,
            "sampleSize": 42
          }
        }
        """

        let data = try XCTUnwrap(json.data(using: .utf8))
        let outlook = try decoder.decode(BackendModels.OutlookModel.self, from: data)

        XCTAssertEqual(outlook.symbol, "TSLA")
        XCTAssertEqual(outlook.timeframeDays, 14)
        XCTAssertEqual(outlook.catalysts.count, 1)
        XCTAssertEqual(outlook.catalysts.first?.title, "Delivery report")
        XCTAssertEqual(outlook.catalysts.first?.impact, "positive")
        XCTAssertEqual(outlook.catalysts.first?.timeframeDays, 7)
        XCTAssertEqual(outlook.news.count, 1)
        XCTAssertEqual(outlook.news.first?.headline, "Tesla demand holds steady")
        XCTAssertEqual(outlook.news.first?.source, "MarketWatch")
        XCTAssertEqual(outlook.news.first?.url.absoluteString, "https://example.com/tesla-demand")
        XCTAssertEqual(outlook.expectedRange.low, 168.5, accuracy: 0.001)
        XCTAssertEqual(outlook.expectedRange.high, 192.3, accuracy: 0.001)
        XCTAssertEqual(outlook.expectedRange.percentMove, 12.4, accuracy: 0.001)
        XCTAssertEqual(outlook.historicalStats.winRate, 0.58, accuracy: 0.001)
        XCTAssertEqual(outlook.historicalStats.averageMovePercent, 8.2, accuracy: 0.001)
        XCTAssertEqual(outlook.historicalStats.medianMovePercent, 7.5, accuracy: 0.001)
        XCTAssertEqual(outlook.historicalStats.sampleSize, 42)
    }
}
