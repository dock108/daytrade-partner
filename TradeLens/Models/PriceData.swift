//
//  PriceData.swift
//  TradeLens
//
//  Price data models for chart display.
//

import Foundation

/// A single price point for charting
struct PricePoint: Identifiable {
    let id = UUID()
    let date: Date
    let close: Double
    let high: Double
    let low: Double
}

/// Price history for a ticker
struct PriceHistory: Identifiable {
    let id = UUID()
    let ticker: String
    let points: [PricePoint]
    let currentPrice: Double
    let change: Double
    let changePercent: Double
    
    var isPositive: Bool {
        change >= 0
    }
    
    var minPrice: Double {
        points.map(\.low).min() ?? 0
    }
    
    var maxPrice: Double {
        points.map(\.high).max() ?? 0
    }
}

/// Time range options for the chart
enum ChartTimeRange: String, CaseIterable {
    case oneDay = "1D"
    case oneMonth = "1M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    
    var days: Int {
        switch self {
        case .oneDay: return 1
        case .oneMonth: return 30
        case .sixMonths: return 180
        case .oneYear: return 365
        }
    }
}


