//
//  HistoryStore.swift
//  TradeLens
//
//  Centralized store for price history data.
//  All views subscribe here — no direct API calls from views.
//

import Foundation
import Combine
import os

@MainActor
final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()
    
    // MARK: - Published State
    // Keys are "{SYMBOL}:{RANGE}" format (e.g., "AAPL:1M")
    
    @Published private(set) var history: [String: [BackendModels.PricePoint]] = [:]
    @Published private(set) var lastUpdated: [String: Date] = [:]
    @Published private(set) var isLoading: [String: Bool] = [:]
    @Published private(set) var errors: [String: String] = [:]
    
    /// Create a cache key from symbol and range
    private func cacheKey(symbol: String, range: String) -> String {
        "\(symbol.uppercased()):\(range.uppercased())"
    }
    
    // MARK: - Configuration
    
    /// How long before cached data is considered stale (seconds)
    private let cacheWindow: TimeInterval = 300 // 5 minutes for history
    
    /// Maximum acceptable staleness before warning (seconds)
    private let staleWarningThreshold: TimeInterval = 600
    
    private let apiClient: APIClient
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TradeLens", category: "HistoryStore")
    
    // MARK: - Init
    
    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }
    
    // MARK: - Public API
    
    /// Get price history for a symbol/range, fetching if needed
    func points(for symbol: String, range: String = "1M") -> [BackendModels.PricePoint]? {
        let key = cacheKey(symbol: symbol, range: range)
        
        // Trigger fetch if not cached or stale
        if shouldRefresh(key: key) {
            Task { await fetch(symbol: symbol.uppercased(), range: range.uppercased(), key: key) }
        }
        
        return history[key]
    }
    
    /// Convenience: get points for symbol with default range
    func points(for symbol: String) -> [BackendModels.PricePoint]? {
        points(for: symbol, range: "1M")
    }
    
    /// Force refresh
    func refresh(symbol: String, range: String = "1M") async {
        let key = cacheKey(symbol: symbol, range: range)
        await fetch(symbol: symbol.uppercased(), range: range.uppercased(), key: key)
    }
    
    /// Get last update time
    func lastUpdateTime(for symbol: String, range: String = "1M") -> Date? {
        let key = cacheKey(symbol: symbol, range: range)
        return lastUpdated[key]
    }
    
    /// Check if data is stale
    func isStale(symbol: String, range: String = "1M") -> Bool {
        let key = cacheKey(symbol: symbol, range: range)
        guard let updated = lastUpdated[key] else { return true }
        return Date().timeIntervalSince(updated) > staleWarningThreshold
    }
    
    // MARK: - Private
    
    private func shouldRefresh(key: String) -> Bool {
        guard let updated = lastUpdated[key] else { return true }
        return Date().timeIntervalSince(updated) > cacheWindow
    }
    
    private func fetch(symbol: String, range: String, key: String) async {
        guard isLoading[key] != true else { return }
        
        isLoading[key] = true
        errors[key] = nil
        
        do {
            let points = try await apiClient.fetchHistory(symbol: symbol, range: range)
            history[key] = points
            lastUpdated[key] = Date()
            logger.info("Fetched history for \(symbol) (\(range)): \(points.count) points")
        } catch {
            let appError = AppError(error)
            errors[key] = appError.userMessage
            logger.error("Failed to fetch history for \(symbol): \(appError.userMessage)")
        }
        
        isLoading[key] = false
    }
}

