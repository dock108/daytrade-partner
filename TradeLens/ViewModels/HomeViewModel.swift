//
//  HomeViewModel.swift
//  TradeLens
//
//  ViewModel for the AI-first home screen.
//

import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var question: String = ""
    @Published var response: AIResponse?
    @Published var priceHistory: PriceHistory?
    @Published var tickerInfo: TickerInfo?
    @Published var detectedTicker: String?
    @Published var lastQuery: String = ""
    @Published var recentSearches: [String] = []
    @Published var isLoading: Bool = false

    let suggestedQuestions: [String] = [
        "What's moving NVDA?",
        "Oil outlook",
        "SPY vs QQQ",
        "Inflation impact",
        "Tech earnings"
    ]

    private let service: AIServiceStub
    private let maxRecentSearches = 5
    private let recentSearchesKey = "TradeLens.RecentSearches"

    init(service: AIServiceStub = AIServiceStub()) {
        self.service = service
        loadRecentSearches()
    }

    func submit() {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            response = nil
            priceHistory = nil
            detectedTicker = nil
            return
        }

        isLoading = true
        lastQuery = trimmed
        
        // Detect ticker and load price data + info immediately (non-blocking)
        detectedTicker = MockPriceService.detectTicker(in: trimmed)
        if let ticker = detectedTicker {
            priceHistory = MockPriceService.priceHistory(for: ticker, range: .oneMonth)
            tickerInfo = TickerInfoService.info(for: ticker)
        } else {
            priceHistory = nil
            tickerInfo = nil
        }
        
        // Simulate brief loading for AI response
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            response = service.structuredResponse(for: trimmed)
            isLoading = false
        }
        
        addToRecentSearches(trimmed)
    }

    func selectSuggestion(_ suggestion: String) {
        question = suggestion
        submit()
    }

    func selectRecentSearch(_ search: String) {
        question = search
        submit()
    }

    func clearAndReset() {
        question = ""
        response = nil
        priceHistory = nil
        tickerInfo = nil
        detectedTicker = nil
        lastQuery = ""
        isLoading = false
    }
    
    func updateChartRange(_ range: ChartTimeRange) {
        guard let ticker = detectedTicker else { return }
        priceHistory = MockPriceService.priceHistory(for: ticker, range: range)
    }

    func clearRecentSearches() {
        recentSearches = []
        saveRecentSearches()
    }

    private func addToRecentSearches(_ query: String) {
        // Remove if already exists to avoid duplicates
        recentSearches.removeAll { $0.lowercased() == query.lowercased() }

        // Insert at beginning
        recentSearches.insert(query, at: 0)

        // Limit to max
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }

        saveRecentSearches()
    }

    private func loadRecentSearches() {
        if let saved = UserDefaults.standard.stringArray(forKey: recentSearchesKey) {
            recentSearches = saved
        }
    }

    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: recentSearchesKey)
    }
}
