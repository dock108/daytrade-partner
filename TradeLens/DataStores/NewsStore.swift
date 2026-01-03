//
//  NewsStore.swift
//  TradeLens
//
//  Centralized store for news/market data.
//  Placeholder for future news API integration.
//

import Foundation
import Combine
import os

@MainActor
final class NewsStore: ObservableObject {
    static let shared = NewsStore()
    
    // MARK: - News Item Model
    
    struct NewsItem: Identifiable, Codable {
        let id: String
        let title: String
        let summary: String
        let source: String
        let publishedAt: Date
        let url: String?
        let relatedTickers: [String]
    }
    
    // MARK: - Published State
    
    @Published private(set) var news: [String: [NewsItem]] = [:] // keyed by ticker
    @Published private(set) var generalNews: [NewsItem] = []
    @Published private(set) var lastUpdated: [String: Date] = [:]
    @Published private(set) var isLoading: [String: Bool] = [:]
    @Published private(set) var errors: [String: String] = [:]
    
    // MARK: - Configuration
    
    /// How long before cached data is considered stale (seconds)
    private let cacheWindow: TimeInterval = 600 // 10 minutes for news
    
    /// Maximum acceptable staleness before warning (seconds)
    private let staleWarningThreshold: TimeInterval = 1800 // 30 minutes
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TradeLens", category: "NewsStore")
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Public API
    
    /// Get news for a ticker (placeholder — returns sample data)
    func newsItems(for symbol: String) -> [NewsItem] {
        let normalized = symbol.uppercased()
        
        // Return cached if available
        if let cached = news[normalized], !shouldRefresh(key: normalized) {
            return cached
        }
        
        // For now, return sample news (backend news endpoint not yet implemented)
        let sampleNews = generateSampleNews(for: normalized)
        news[normalized] = sampleNews
        lastUpdated[normalized] = Date()
        
        return sampleNews
    }
    
    /// Get last update time
    func lastUpdateTime(for symbol: String) -> Date? {
        lastUpdated[symbol.uppercased()]
    }
    
    /// Check if data is stale
    func isStale(symbol: String) -> Bool {
        guard let updated = lastUpdated[symbol.uppercased()] else { return true }
        return Date().timeIntervalSince(updated) > staleWarningThreshold
    }
    
    // MARK: - Private
    
    private func shouldRefresh(key: String) -> Bool {
        guard let updated = lastUpdated[key] else { return true }
        return Date().timeIntervalSince(updated) > cacheWindow
    }
    
    /// Generate sample news (placeholder until backend supports news)
    private func generateSampleNews(for symbol: String) -> [NewsItem] {
        [
            NewsItem(
                id: "\(symbol)-1",
                title: "\(symbol) Shows Strong Trading Volume",
                summary: "Trading activity has increased for \(symbol) amid broader market movements.",
                source: "Market Watch",
                publishedAt: Date().addingTimeInterval(-3600),
                url: nil,
                relatedTickers: [symbol]
            ),
            NewsItem(
                id: "\(symbol)-2",
                title: "Analyst Updates \(symbol) Outlook",
                summary: "Several analysts have reviewed their positions on \(symbol) following recent earnings.",
                source: "Financial Times",
                publishedAt: Date().addingTimeInterval(-7200),
                url: nil,
                relatedTickers: [symbol]
            )
        ]
    }
}


