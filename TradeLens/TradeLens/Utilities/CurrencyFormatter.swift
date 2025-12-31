//
//  CurrencyFormatter.swift
//  TradeLens
//
//  Utility for formatting currency values
//

import Foundation

/// Utility for formatting currency values
enum CurrencyFormatter {
    /// Format a double value as USD currency
    static func formatUSD(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    /// Format a double value with percentage
    static func formatPercentage(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "0.00%"
    }
}
