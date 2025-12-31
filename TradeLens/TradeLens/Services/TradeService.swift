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
        let calendar = Calendar.current
        let now = Date()
        let aaplEntry = calendar.date(byAdding: .day, value: -12, to: now) ?? now
        let aaplExit = calendar.date(byAdding: .day, value: -3, to: now)
        let googlEntry = calendar.date(byAdding: .day, value: -6, to: now) ?? now

        trades = [
            Trade(
                ticker: "AAPL",
                entryDate: aaplEntry,
                exitDate: aaplExit,
                qty: 10,
                entryPrice: 150.25,
                exitPrice: 163.40,
                category: .core
            ),
            Trade(
                ticker: "GOOGL",
                entryDate: googlEntry,
                qty: 5,
                entryPrice: 2800.50,
                category: .speculative
            )
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
