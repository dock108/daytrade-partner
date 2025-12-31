//
//  TradeListViewModel.swift
//  TradeLens
//
//  ViewModel for managing trade list state and logic
//

import Foundation
import SwiftUI

/// ViewModel for the trade list view
/// Manages the state and business logic for displaying trades
@MainActor
class TradeListViewModel: ObservableObject {
    @Published var trades: [Trade] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let tradeService: TradeService
    
    /// Initialize with a trade service
    init(tradeService: TradeService = TradeService()) {
        self.tradeService = tradeService
    }
    
    /// Load trades from the service
    func loadTrades() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await tradeService.fetchTrades()
            trades = tradeService.trades
        } catch {
            errorMessage = "Failed to load trades: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Add a new trade
    func addTrade(ticker: String, qty: Double, entryPrice: Double, category: Trade.Category) async {
        let trade = Trade(
            ticker: ticker,
            entryDate: Date(),
            qty: qty,
            entryPrice: entryPrice,
            category: category
        )
        await tradeService.addTrade(trade)
        trades = tradeService.trades
    }
}
