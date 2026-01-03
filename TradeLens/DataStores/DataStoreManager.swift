//
//  DataStoreManager.swift
//  TradeLens
//
//  Central coordinator for all data stores.
//  Provides unified access, sync timestamps, and debug guardrails.
//

import Foundation
import Combine
import os

@MainActor
final class DataStoreManager: ObservableObject {
    static let shared = DataStoreManager()
    
    // MARK: - Stores
    
    let priceStore: PriceStore
    let historyStore: HistoryStore
    let aiResponseStore: AIResponseStore
    let outlookStore: OutlookStore
    let newsStore: NewsStore
    
    // MARK: - Published State
    
    @Published private(set) var lastGlobalSync: Date?
    @Published private(set) var isMockMode: Bool = false
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TradeLens", category: "DataStoreManager")
    private enum Constants {
        static let bannerSuffix = "outlook updates periodically"
        static let bannerSyncedPrefix = "Data synced"
        static let bannerFromPrefix = "Data from"
        static let justNowText = "just now"
        static let minutesUnit = "minute"
        static let minutesUnitPlural = "minutes"
    }
    
    // MARK: - Init
    
    init(
        priceStore: PriceStore = .shared,
        historyStore: HistoryStore = .shared,
        aiResponseStore: AIResponseStore = .shared,
        outlookStore: OutlookStore = .shared,
        newsStore: NewsStore = .shared
    ) {
        self.priceStore = priceStore
        self.historyStore = historyStore
        self.aiResponseStore = aiResponseStore
        self.outlookStore = outlookStore
        self.newsStore = newsStore
    }
    
    // MARK: - Public API
    
    /// Refresh all data for a symbol
    func refreshAll(for symbol: String) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.priceStore.refresh(symbol: symbol) }
            group.addTask { await self.historyStore.refresh(symbol: symbol) }
        }
        lastGlobalSync = Date()
    }
    
    /// Get the most recent sync time across all stores for a symbol
    func mostRecentSync(for symbol: String) -> Date? {
        let dates = [
            priceStore.lastUpdateTime(for: symbol),
            historyStore.lastUpdateTime(for: symbol)
        ].compactMap { $0 }
        
        return dates.max()
    }
    
    /// Formatted sync time string for UI
    func syncTimeString(for symbol: String) -> String? {
        guard let date = mostRecentSync(for: symbol) else { return nil }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Data synced at \(formatter.string(from: date))"
    }

    /// Banner text for sync status with relative age
    func dataSyncBannerText(for symbol: String, referenceDate: Date = Date()) -> String? {
        guard let date = mostRecentSync(for: symbol) else { return nil }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let minutesAgo = max(0, Int(referenceDate.timeIntervalSince(date) / 60))
        let relativeSegment = relativeAgeSegment(minutesAgo: minutesAgo)
        let syncSegment = "\(Constants.bannerSyncedPrefix) \(formatter.string(from: date))"
        return "\(relativeSegment) — \(syncSegment) — \(Constants.bannerSuffix)"
    }

    private func relativeAgeSegment(minutesAgo: Int) -> String {
        if minutesAgo < 1 {
            return "\(Constants.bannerFromPrefix) \(Constants.justNowText)"
        }

        let unit = minutesAgo == 1 ? Constants.minutesUnit : Constants.minutesUnitPlural
        return "\(Constants.bannerFromPrefix) \(minutesAgo) \(unit) ago"
    }
    
    /// Check if any data is stale for a symbol
    func hasStaleData(for symbol: String) -> Bool {
        priceStore.isStale(symbol: symbol) || historyStore.isStale(symbol: symbol)
    }
    
    #if DEBUG
    /// Validate price consistency across all stores for a symbol
    func validatePriceConsistency(for symbol: String) -> [String] {
        var warnings: [String] = []
        
        guard let snapshot = priceStore.snapshot(for: symbol) else { return warnings }
        
        // Check against history
        if let historyPoints = historyStore.points(for: symbol),
           let latestHistoryPrice = historyPoints.last?.close {
            let priceDiff = abs(snapshot.price - latestHistoryPrice) / latestHistoryPrice
            if priceDiff > 0.001 { // 0.1% threshold
                let warning = "Price mismatch for \(symbol): snapshot=\(snapshot.price), history=\(latestHistoryPrice)"
                warnings.append(warning)
                logger.warning("⚠️ \(warning)")
            }
        }
        
        // Check staleness
        if priceStore.isStale(symbol: symbol) {
            let warning = "Price data for \(symbol) is stale"
            warnings.append(warning)
            logger.warning("⚠️ \(warning)")
        }
        
        if historyStore.isStale(symbol: symbol) {
            let warning = "History data for \(symbol) is stale"
            warnings.append(warning)
            logger.warning("⚠️ \(warning)")
        }
        
        return warnings
    }
    #endif
}

// MARK: - Debug View Helpers

#if DEBUG
extension DataStoreManager {
    /// Debug info for a symbol
    func debugInfo(for symbol: String) -> String {
        var lines: [String] = []
        
        if let snapshot = priceStore.snapshot(for: symbol) {
            lines.append("Price: \(snapshot.price)")
        }
        
        if let points = historyStore.points(for: symbol) {
            lines.append("History: \(points.count) points")
            if let last = points.last {
                lines.append("Last close: \(last.close)")
            }
        }
        
        if let syncTime = syncTimeString(for: symbol) {
            lines.append(syncTime)
        }
        
        if hasStaleData(for: symbol) {
            lines.append("⚠️ STALE DATA")
        }
        
        return lines.joined(separator: "\n")
    }
}
#endif
