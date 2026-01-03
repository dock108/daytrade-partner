//
//  OutlookStore.swift
//  TradeLens
//
//  Centralized store for AI outlook/explanation data.
//  All views subscribe here — no direct API calls from views.
//

import Foundation
import Combine
import os

@MainActor
final class OutlookStore: ObservableObject {
    static let shared = OutlookStore()
    
    // MARK: - Cache Key
    
    private struct CacheKey: Hashable {
        let symbol: String
        let timeframeDays: Int
        let simpleMode: Bool
    }
    
    // MARK: - Published State
    
    @Published private(set) var responses: [String: BackendModels.AIResponse] = [:] // keyed by question
    @Published private(set) var lastUpdated: [String: Date] = [:]
    @Published private(set) var isLoading: [String: Bool] = [:]
    @Published private(set) var errors: [String: String] = [:]
    
    // MARK: - Configuration
    
    /// How long before cached data is considered stale (seconds)
    private let cacheWindow: TimeInterval = 300 // 5 minutes
    
    /// Maximum acceptable staleness before warning (seconds)
    private let staleWarningThreshold: TimeInterval = 600
    
    private let apiClient: APIClient
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TradeLens", category: "OutlookStore")
    
    // MARK: - Init
    
    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }
    
    // MARK: - Public API
    
    /// Ask the AI and cache the response
    func ask(
        question: String,
        symbol: String?,
        timeframeDays: Int?,
        simpleMode: Bool
    ) async -> BackendModels.AIResponse? {
        let cacheKey = question.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Return cached if fresh
        if let cached = responses[cacheKey], !shouldRefresh(key: cacheKey) {
            logger.info("Returning cached response for: \(cacheKey.prefix(30))...")
            return cached
        }
        
        // Fetch new
        return await fetch(
            question: question,
            symbol: symbol,
            timeframeDays: timeframeDays,
            simpleMode: simpleMode,
            cacheKey: cacheKey
        )
    }
    
    /// Get cached response without fetching
    func cachedResponse(for question: String) -> BackendModels.AIResponse? {
        let key = question.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return responses[key]
    }
    
    /// Get last update time
    func lastUpdateTime(for question: String) -> Date? {
        let key = question.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return lastUpdated[key]
    }
    
    /// Check if currently loading
    func isCurrentlyLoading(for question: String) -> Bool {
        let key = question.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return isLoading[key] ?? false
    }
    
    /// Clear cache
    func clearCache() {
        responses.removeAll()
        lastUpdated.removeAll()
        errors.removeAll()
    }
    
    // MARK: - Private
    
    private func shouldRefresh(key: String) -> Bool {
        guard let updated = lastUpdated[key] else { return true }
        return Date().timeIntervalSince(updated) > cacheWindow
    }
    
    private func fetch(
        question: String,
        symbol: String?,
        timeframeDays: Int?,
        simpleMode: Bool,
        cacheKey: String
    ) async -> BackendModels.AIResponse? {
        guard isLoading[cacheKey] != true else { return responses[cacheKey] }
        
        isLoading[cacheKey] = true
        errors[cacheKey] = nil
        
        do {
            let response = try await apiClient.askAI(
                question: question,
                symbol: symbol,
                timeframeDays: timeframeDays,
                simpleMode: simpleMode
            )
            responses[cacheKey] = response
            lastUpdated[cacheKey] = Date()
            logger.info("Fetched AI response for: \(cacheKey.prefix(30))...")
            
            isLoading[cacheKey] = false
            return response
        } catch {
            let appError = AppError(error)
            errors[cacheKey] = appError.userMessage
            logger.error("Failed to fetch AI response: \(appError.userMessage)")
            
            isLoading[cacheKey] = false
            return nil
        }
    }
}

