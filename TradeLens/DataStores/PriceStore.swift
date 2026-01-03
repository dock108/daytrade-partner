//
//  PriceStore.swift
//  TradeLens
//
//  Centralized store for ticker price/snapshot data.
//  All views subscribe here — no direct API calls from views.
//

import Foundation
import Combine
import os

@MainActor
final class PriceStore: ObservableObject {
    static let shared = PriceStore()
    
    // MARK: - Published State
    
    @Published private(set) var snapshots: [String: BackendModels.TickerSnapshot] = [:]
    @Published private(set) var lastUpdated: [String: Date] = [:]
    @Published private(set) var isLoading: [String: Bool] = [:]
    @Published private(set) var errors: [String: String] = [:]
    
    // MARK: - Configuration
    
    /// How long before cached data is considered stale (seconds)
    private let cacheWindow: TimeInterval = 60
    
    /// Maximum acceptable staleness before warning (seconds)
    private let staleWarningThreshold: TimeInterval = 120
    
    private let apiClient: APIClient
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TradeLens", category: "PriceStore")
    
    // MARK: - Init
    
    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }
    
    // MARK: - Public API
    
    /// Get snapshot for a symbol, fetching if needed
    func snapshot(for symbol: String) -> BackendModels.TickerSnapshot? {
        let normalized = symbol.uppercased()
        
        // Trigger fetch if not cached or stale
        if shouldRefresh(symbol: normalized) {
            Task { await fetch(symbol: normalized) }
        }
        
        return snapshots[normalized]
    }
    
    /// Force refresh a symbol
    func refresh(symbol: String) async {
        await fetch(symbol: symbol.uppercased())
    }
    
    /// Get last update time for a symbol
    func lastUpdateTime(for symbol: String) -> Date? {
        lastUpdated[symbol.uppercased()]
    }
    
    /// Check if data is stale (for debug warnings)
    func isStale(symbol: String) -> Bool {
        guard let updated = lastUpdated[symbol.uppercased()] else { return true }
        return Date().timeIntervalSince(updated) > staleWarningThreshold
    }
    
    // MARK: - Private
    
    private func shouldRefresh(symbol: String) -> Bool {
        guard let updated = lastUpdated[symbol] else { return true }
        return Date().timeIntervalSince(updated) > cacheWindow
    }
    
    private func fetch(symbol: String) async {
        guard isLoading[symbol] != true else { return }
        
        isLoading[symbol] = true
        errors[symbol] = nil
        
        do {
            let snapshot = try await apiClient.fetchSnapshot(symbol: symbol)
            snapshots[symbol] = snapshot
            lastUpdated[symbol] = Date()
            logger.info("Fetched snapshot for \(symbol)")
            
            #if DEBUG
            validateConsistency(symbol: symbol, newPrice: snapshot.price)
            #endif
        } catch {
            let appError = AppError(error)
            errors[symbol] = appError.userMessage
            logger.error("Failed to fetch snapshot for \(symbol): \(appError.userMessage)")
        }
        
        isLoading[symbol] = false
    }
    
    #if DEBUG
    /// Debug: Validate price consistency across stores
    private func validateConsistency(symbol: String, newPrice: Double) {
        // Check against HistoryStore's latest price
        if let historyPoints = HistoryStore.shared.points(for: symbol),
           let latestHistoryPrice = historyPoints.last?.close {
            let priceDiff = abs(newPrice - latestHistoryPrice) / latestHistoryPrice
            if priceDiff > 0.001 { // 0.1% threshold
                logger.warning("⚠️ Price inconsistency for \(symbol): snapshot=\(newPrice), history=\(latestHistoryPrice), diff=\(String(format: "%.2f%%", priceDiff * 100))")
            }
        }
    }
    #endif
}


