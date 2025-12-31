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
    @Published var guidedSuggestions: [GuidedSuggestion] = []
    @Published var conversationHistory: [ConversationEntry] = []
    
    // Voice input state
    @Published var isListening: Bool = false
    @Published var speechError: String?

    private let service: AIServiceStub
    private let tradeService: MockTradeDataService
    private let speechService: SpeechRecognitionService
    private let historyService: ConversationHistoryService
    private let maxRecentSearches = 5
    private let recentSearchesKey = "TradeLens.RecentSearches"
    
    /// A guided suggestion with icon and query
    struct GuidedSuggestion: Identifiable, Equatable {
        let id = UUID()
        let icon: String
        let text: String
        let query: String
        let category: Category
        
        enum Category {
            case ticker
            case market
            case learning
        }
    }

    init(
        service: AIServiceStub = AIServiceStub(),
        tradeService: MockTradeDataService = MockTradeDataService(),
        speechService: SpeechRecognitionService = SpeechRecognitionService(),
        historyService: ConversationHistoryService = .shared
    ) {
        self.service = service
        self.tradeService = tradeService
        self.speechService = speechService
        self.historyService = historyService
        self.conversationHistory = historyService.recentEntries(limit: 10)
        loadRecentSearches()
        loadGuidedSuggestions()
    }
    
    // MARK: - Voice Input
    
    func toggleVoiceInput() {
        if isListening {
            stopVoiceInput()
        } else {
            startVoiceInput()
        }
    }
    
    func startVoiceInput() {
        speechError = nil
        isListening = true
        
        speechService.startListening(
            onResult: { [weak self] partialText in
                Task { @MainActor in
                    self?.question = partialText
                }
            },
            onComplete: { [weak self] finalText in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.isListening = false
                    
                    if let text = finalText, !text.isEmpty {
                        self.question = text
                        // Auto-submit after successful voice input
                        self.submit()
                    } else if self.speechService.error != nil {
                        self.speechError = self.speechService.error?.localizedDescription
                        // Clear error after 3 seconds
                        Task {
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            await MainActor.run {
                                self.speechError = nil
                            }
                        }
                    }
                }
            }
        )
    }
    
    func stopVoiceInput() {
        speechService.stopListening()
        isListening = false
    }
    
    var canUseMicrophone: Bool {
        speechService.canRequestMicrophone
    }

    func submit() {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            response = nil
            priceHistory = nil
            tickerInfo = nil
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
            let aiResponse = service.structuredResponse(for: trimmed)
            response = aiResponse
            isLoading = false
            
            // Save to conversation history
            historyService.save(
                question: trimmed,
                response: aiResponse,
                detectedTicker: detectedTicker
            )
            refreshConversationHistory()
        }
        
        addToRecentSearches(trimmed)
    }
    
    /// Load a past conversation from history
    func loadConversation(_ entry: ConversationEntry) {
        question = entry.question
        lastQuery = entry.question
        response = entry.toAIResponse()
        detectedTicker = entry.detectedTicker
        
        // Reload price data and ticker info if applicable
        if let ticker = entry.detectedTicker {
            priceHistory = MockPriceService.priceHistory(for: ticker, range: .oneMonth)
            tickerInfo = TickerInfoService.info(for: ticker)
        } else {
            priceHistory = nil
            tickerInfo = nil
        }
    }
    
    /// Refresh the conversation history list
    func refreshConversationHistory() {
        conversationHistory = historyService.recentEntries(limit: 10)
    }
    
    /// Delete a conversation entry
    func deleteConversation(_ entry: ConversationEntry) {
        historyService.delete(entry)
        refreshConversationHistory()
    }

    func selectSuggestion(_ suggestion: GuidedSuggestion) {
        question = suggestion.query
        submit()
    }
    
    func selectSuggestionText(_ text: String) {
        question = text
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
    
    func refreshSuggestions() {
        loadGuidedSuggestions()
    }

    // MARK: - Guided Suggestions
    
    private func loadGuidedSuggestions() {
        Task {
            let userTickers = await fetchUserTickers()
            await MainActor.run {
                guidedSuggestions = buildGuidedSuggestions(userTickers: userTickers)
            }
        }
    }
    
    private func fetchUserTickers() async -> [String] {
        do {
            let trades = try await tradeService.fetchMockTrades()
            // Get unique tickers sorted by frequency
            let tickerCounts = trades.reduce(into: [String: Int]()) { counts, trade in
                counts[trade.ticker, default: 0] += 1
            }
            return tickerCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
        } catch {
            return ["AAPL", "SPY", "QQQ"] // Fallback defaults
        }
    }
    
    private func buildGuidedSuggestions(userTickers: [String]) -> [GuidedSuggestion] {
        var suggestions: [GuidedSuggestion] = []
        
        // Ticker-specific suggestions using user's tickers
        if let topTicker = userTickers.first {
            suggestions.append(GuidedSuggestion(
                icon: "chart.line.uptrend.xyaxis",
                text: "What's the outlook on \(topTicker)?",
                query: "What's the outlook on \(topTicker)?",
                category: .ticker
            ))
        }
        
        if userTickers.count >= 2 {
            let ticker = userTickers[1]
            suggestions.append(GuidedSuggestion(
                icon: "arrow.up.arrow.down",
                text: "Why is \(ticker) moving?",
                query: "Why is \(ticker) moving?",
                category: .ticker
            ))
        }
        
        // Comparison suggestion
        if userTickers.count >= 2 {
            let t1 = userTickers[0]
            let t2 = userTickers[1]
            suggestions.append(GuidedSuggestion(
                icon: "arrow.left.arrow.right",
                text: "Compare \(t1) vs \(t2)",
                query: "Compare \(t1) vs \(t2)",
                category: .ticker
            ))
        } else {
            suggestions.append(GuidedSuggestion(
                icon: "arrow.left.arrow.right",
                text: "Compare SPY vs QQQ",
                query: "Compare SPY vs QQQ",
                category: .ticker
            ))
        }
        
        // Market-wide suggestions
        suggestions.append(GuidedSuggestion(
            icon: "waveform.path.ecg",
            text: "Is the market nervous or calm?",
            query: "Is the market nervous or calm right now?",
            category: .market
        ))
        
        suggestions.append(GuidedSuggestion(
            icon: "sun.max",
            text: "Explain today simply",
            query: "Explain what's happening in the market today in simple terms",
            category: .learning
        ))
        
        // Add one more ticker-specific if we have enough tickers
        if userTickers.count >= 3 {
            let ticker = userTickers[2]
            suggestions.append(GuidedSuggestion(
                icon: "questionmark.circle",
                text: "Should I watch \(ticker)?",
                query: "What should I know about \(ticker) right now?",
                category: .ticker
            ))
        }
        
        return suggestions
    }

    // MARK: - Recent Searches
    
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
