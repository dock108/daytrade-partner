//
//  TradeService.swift
//  TradeLens
//
//  Service for managing trade data
//

import Foundation

/// Service responsible for managing trade operations
/// Uses Swift Concurrency for async operations
@MainActor
class TradeService: ObservableObject {
    @Published private(set) var trades: [Trade] = []
    @Published private(set) var isLoading = false
    
    /// Fetch trades from data source
    func fetchTrades() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Example trades
        trades = [
            Trade(symbol: "AAPL", quantity: 10, price: 150.25, type: .buy),
            Trade(symbol: "GOOGL", quantity: 5, price: 2800.50, type: .buy)
        ]
    }
    
    /// Add a new trade
    func addTrade(_ trade: Trade) async {
        trades.append(trade)
    }
    
    /// Delete a trade
    func deleteTrade(_ trade: Trade) async {
        trades.removeAll { $0.id == trade.id }
    }
}
