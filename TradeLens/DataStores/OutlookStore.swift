//
//  OutlookStore.swift
//  TradeLens
//
//  Centralized stores for AI responses and market outlook data.
//  All views subscribe here — no direct API calls from views.
//

import Foundation
import Combine
import os

@MainActor
final class AIResponseStore: ObservableObject {
    static let shared = AIResponseStore()

    // MARK: - Published State

    @Published private(set) var responses: [String: BackendModels.AIResponse] = [:] // keyed by question
    @Published private(set) var lastUpdated: [String: Date] = [:]
    @Published private(set) var isLoading: [String: Bool] = [:]
    @Published private(set) var errors: [String: String] = [:]

    // MARK: - Configuration

    /// How long before cached data is considered stale (seconds)
    private let cacheWindow: TimeInterval = 300 // 5 minutes
    private let apiClient: APIClient
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TradeLens", category: "AIResponseStore")

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
        isLoading.removeAll()
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

@MainActor
final class OutlookStore: ObservableObject {
    static let shared = OutlookStore()

    // MARK: - Cache Key

    struct CacheKey: Hashable {
        let symbol: String
        let timeframeDays: Int?
    }

    // MARK: - Published State

    @Published private(set) var outlook: [CacheKey: BackendModels.Outlook] = [:]
    @Published private(set) var lastUpdated: [CacheKey: Date] = [:]
    @Published private(set) var isLoading: [CacheKey: Bool] = [:]
    @Published private(set) var isFallback: [CacheKey: Bool] = [:]
    @Published private(set) var errors: [CacheKey: String] = [:]

    // MARK: - Configuration

    /// How long before cached data is considered stale (seconds)
    private let cacheWindow: TimeInterval = 300 // 5 minutes
    private let apiClient: APIClient
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TradeLens", category: "OutlookStore")

    // MARK: - Init

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    // MARK: - Public API

    func fetchOutlook(symbol: String, timeframeDays: Int?, forceRefresh: Bool = false) async -> BackendModels.Outlook? {
        let normalizedSymbol = symbol.uppercased()
        let cacheKey = CacheKey(symbol: normalizedSymbol, timeframeDays: timeframeDays)

        if !forceRefresh, let cached = outlook[cacheKey], !shouldRefresh(key: cacheKey) {
            isFallback[cacheKey] = false
            return cached
        }

        return await fetch(symbol: normalizedSymbol, timeframeDays: timeframeDays, cacheKey: cacheKey)
    }

    func outlook(for symbol: String, timeframeDays: Int?) -> BackendModels.Outlook? {
        let cacheKey = CacheKey(symbol: symbol.uppercased(), timeframeDays: timeframeDays)
        return outlook[cacheKey]
    }

    func lastUpdateTime(for symbol: String, timeframeDays: Int?) -> Date? {
        let cacheKey = CacheKey(symbol: symbol.uppercased(), timeframeDays: timeframeDays)
        return lastUpdated[cacheKey]
    }

    func isCurrentlyLoading(for symbol: String, timeframeDays: Int?) -> Bool {
        let cacheKey = CacheKey(symbol: symbol.uppercased(), timeframeDays: timeframeDays)
        return isLoading[cacheKey] ?? false
    }

    func isUsingFallback(for symbol: String, timeframeDays: Int?) -> Bool {
        let cacheKey = CacheKey(symbol: symbol.uppercased(), timeframeDays: timeframeDays)
        return isFallback[cacheKey] ?? false
    }

    func clearCache() {
        outlook.removeAll()
        lastUpdated.removeAll()
        errors.removeAll()
        isLoading.removeAll()
        isFallback.removeAll()
    }

    // MARK: - Private

    private func shouldRefresh(key: CacheKey) -> Bool {
        guard let updated = lastUpdated[key] else { return true }
        return Date().timeIntervalSince(updated) > cacheWindow
    }

    private func fetch(
        symbol: String,
        timeframeDays: Int?,
        cacheKey: CacheKey
    ) async -> BackendModels.Outlook? {
        guard isLoading[cacheKey] != true else { return outlook[cacheKey] }

        isLoading[cacheKey] = true
        errors[cacheKey] = nil
        isFallback[cacheKey] = false

        do {
            let response = try await apiClient.requestOutlook(symbol: symbol, timeframeDays: timeframeDays)
            outlook[cacheKey] = response
            lastUpdated[cacheKey] = Date()
            logger.info("Fetched outlook for: \(symbol)")

            isLoading[cacheKey] = false
            return response
        } catch {
            let appError = AppError(error)
            errors[cacheKey] = appError.userMessage
            logger.error("Failed to fetch outlook: \(appError.userMessage)")

            isLoading[cacheKey] = false

            if let cached = outlook[cacheKey] {
                isFallback[cacheKey] = true
                return cached
            }

            return nil
        }
    }
}
