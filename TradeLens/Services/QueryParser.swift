//
//  QueryParser.swift
//  TradeLens
//
//  Utilities for extracting symbols and timeframe hints from user questions.
//

import Foundation

struct QueryParser {
    private static let explicitTickers: Set<String> = [
        "AAPL", "SPY", "QQQ", "NVDA", "TSLA", "MSFT", "AMZN", "META", "GOOGL"
    ]
    private static let defaultTimeframeDays = 30
    private static let daysPerWeek = 7
    private static let daysPerMonth = 30
    private static let daysPerYear = 365
    private static let tickerLengthRange = 1...5

    static func detectTicker(in query: String) -> String? {
        let tokens = query.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        for token in tokens {
            let uppercased = token.uppercased()
            if explicitTickers.contains(uppercased) {
                return uppercased
            }

            if token == uppercased, tickerLengthRange.contains(token.count) {
                return uppercased
            }
        }

        return nil
    }

    static func extractTimeframeDays(from query: String) -> Int {
        let lowercased = query.lowercased()

        if lowercased.contains("next month") {
            return daysPerMonth
        }

        if lowercased.contains("next week") {
            return daysPerWeek
        }

        if lowercased.contains("next year") {
            return daysPerYear
        }

        if let value = extractNumberedTimeframe(from: lowercased) {
            return value
        }

        return defaultTimeframeDays
    }

    private static func extractNumberedTimeframe(from query: String) -> Int? {
        let pattern = #"(\d+)\s*(day|days|week|weeks|month|months|year|years)"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let range = NSRange(query.startIndex..<query.endIndex, in: query)
        guard let match = regex.firstMatch(in: query, options: [], range: range),
              match.numberOfRanges >= 3,
              let numberRange = Range(match.range(at: 1), in: query),
              let unitRange = Range(match.range(at: 2), in: query),
              let value = Int(query[numberRange]) else {
            return nil
        }

        let unit = String(query[unitRange])
        switch unit {
        case "day", "days":
            return value
        case "week", "weeks":
            return value * daysPerWeek
        case "month", "months":
            return value * daysPerMonth
        case "year", "years":
            return value * daysPerYear
        default:
            return nil
        }
    }
}
