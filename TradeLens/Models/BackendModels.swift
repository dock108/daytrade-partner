//
//  BackendModels.swift
//  TradeLens
//
//  Data API models matching API_CONTRACT.md.
//

import Foundation

enum BackendModels {}

extension BackendModels {
    struct TickerSnapshot: Codable {
        let symbol: String
        let name: String
        let price: Double
        let changePercent: Double
        let high52w: Double
        let low52w: Double
        let currency: String
    }

    struct PricePoint: Codable {
        let date: Date
        let close: Double
    }

    struct Outlook: Codable {
        let symbol: String
        let timeframeDays: Int
        let sentimentSummary: String
        let historicalHitRate: Double
        let typicalRangePercent: Double
        let volatilityLabel: String
        let keyDrivers: [String]
    }

    struct AIResponse: Codable {
        let whatsHappeningNow: String
        let keyDrivers: [String]
        let riskVsOpportunity: String
        let historicalBehavior: String
        let simpleRecap: String
    }

    struct OutlookModel: Codable {
        let symbol: String
        let timeframeDays: Int
        let catalysts: [Catalyst]
        let news: [NewsItem]
        let expectedRange: ExpectedRange
        let historicalStats: HistoricalStats
    }

    struct Catalyst: Codable {
        let title: String
        let impact: String
        let timeframeDays: Int
    }

    struct NewsItem: Codable {
        let headline: String
        let source: String
        let publishedAt: Date
        let url: URL
    }

    struct ExpectedRange: Codable {
        let low: Double
        let high: Double
        let percentMove: Double
    }

    struct HistoricalStats: Codable {
        let winRate: Double
        let averageMovePercent: Double
        let medianMovePercent: Double
        let sampleSize: Int
    }

    struct APIErrorResponse: Codable {
        let message: String
    }
}
