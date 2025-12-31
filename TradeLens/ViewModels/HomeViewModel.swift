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
            return
        }

        isLoading = true
        lastQuery = trimmed
        
        // Simulate brief loading for feel
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
        lastQuery = ""
        isLoading = false
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
