//
//  Trade.swift
//  TradeLens
//
//  Example model representing a trade
//

import Foundation

/// Represents a single trade transaction
struct Trade: Identifiable, Codable {
    let id: UUID
    let symbol: String
    let quantity: Double
    let price: Double
    let timestamp: Date
    let type: TradeType
    
    /// The type of trade (buy or sell)
    enum TradeType: String, Codable {
        case buy
        case sell
    }
    
    /// Computed property for the total value of the trade
    var totalValue: Double {
        quantity * price
    }
    
    /// Initialize a new trade
    init(id: UUID = UUID(), symbol: String, quantity: Double, price: Double, timestamp: Date = Date(), type: TradeType) {
        self.id = id
        self.symbol = symbol
        self.quantity = quantity
        self.price = price
        self.timestamp = timestamp
        self.type = type
    }
}
