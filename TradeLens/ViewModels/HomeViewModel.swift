//
//  HomeViewModel.swift
//  TradeLens
//
//  ViewModel for the AI-first home screen.
//

import Foundation
import SwiftUI
import os

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var question: String = ""
    @Published var response: AIResponse?
    @Published var priceHistory: PriceHistory?
    @Published var historyPoints: [PricePoint]?
    @Published var tickerSnapshot: BackendModels.TickerSnapshot?
    @Published var detectedTicker: String?
    @Published var lastQuery: String = ""
    @Published var recentSearches: [String] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var guidedSuggestions: [GuidedSuggestion] = []
    @Published var conversationHistory: [ConversationEntry] = []
    @Published var outlook: BackendModels.Outlook?
    
    // Voice input state
    @Published var isListening: Bool = false
    @Published var speechError: String?

    // MARK: - Shared Data Stores (Single Source of Truth)
    private let dataStoreManager: DataStoreManager
    private let priceStore: PriceStore
    private let historyStore: HistoryStore
    private let aiResponseStore: AIResponseStore
    private let outlookStore: OutlookStore
    
    private let tradeService: MockTradeDataService
    private let speechService: SpeechRecognitionService
    private let historyService: ConversationHistoryService
    private let userSettings: UserSettings
    private let maxRecentSearches = 5
    private let recentSearchesKey = "TradeLens.RecentSearches"
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TradeLens", category: "HomeViewModel")
    private enum Constants {
        static let historyRange = "1M"
    }
    
    /// Sync timestamp for UI display (dev-visible)
    var syncTimeString: String? {
        guard let ticker = detectedTicker else { return nil }
        return dataStoreManager.syncTimeString(for: ticker)
    }
    
    /// Keywords that trigger outlook generation
    private let outlookKeywords = ["buy", "up", "down", "outlook", "expect", "will", "should", "30 days", "next month", "forecast", "prediction"]
    
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
        dataStoreManager: DataStoreManager = .shared,
        tradeService: MockTradeDataService = MockTradeDataService(),
        speechService: SpeechRecognitionService = SpeechRecognitionService(),
        historyService: ConversationHistoryService = .shared,
        userSettings: UserSettings = .shared
    ) {
        self.dataStoreManager = dataStoreManager
        self.priceStore = dataStoreManager.priceStore
        self.historyStore = dataStoreManager.historyStore
        self.aiResponseStore = dataStoreManager.aiResponseStore
        self.outlookStore = dataStoreManager.outlookStore
        self.tradeService = tradeService
        self.speechService = speechService
        self.historyService = historyService
        self.userSettings = userSettings
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
            historyPoints = nil
            tickerSnapshot = nil
            detectedTicker = nil
            outlook = nil
            errorMessage = nil
            return
        }

        isLoading = true
        errorMessage = nil
        lastQuery = trimmed
        response = nil
        
        // Detect ticker (data will be loaded from backend stores)
        detectedTicker = QueryParser.detectTicker(in: trimmed)
        priceHistory = nil
        historyPoints = nil
        tickerSnapshot = nil
        
        // Check if this is an outlook-type query
        let shouldShowOutlook = shouldGenerateOutlook(for: trimmed)
        let timeframeDays = QueryParser.extractTimeframeDays(from: trimmed)
        let simpleMode = userSettings.isSimpleModeEnabled
        
        Task {
            defer { isLoading = false }
            
            // Use shared AIResponseStore for AI responses
            guard let backendResponse = await aiResponseStore.ask(
                question: trimmed,
                symbol: detectedTicker,
                timeframeDays: timeframeDays,
                simpleMode: simpleMode
            ) else {
                // Check for error from store
                let cacheKey = trimmed.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if let storeError = aiResponseStore.errors[cacheKey] {
                    errorMessage = storeError
                } else {
                    errorMessage = "Unable to get response. Please try again."
                }
                response = nil
                tickerSnapshot = nil
                outlook = nil
                historyPoints = nil
                return
            }
            
            let aiResponse = buildAIResponse(from: backendResponse, query: trimmed)
            response = aiResponse
            
            // Use shared stores for price data (no direct API calls)
            if let ticker = detectedTicker {
                // Refresh all data through stores
                await dataStoreManager.refreshAll(for: ticker)
                
                // Get snapshot from store
                tickerSnapshot = priceStore.snapshot(for: ticker)
                
                // Get history from store and build PriceHistory for the chart
                if let storePoints = historyStore.points(for: ticker, range: Constants.historyRange) {
                    // Map backend points to local PricePoint model
                    let localPoints = storePoints.map { backendPoint in
                        PricePoint(
                            date: backendPoint.date,
                            close: backendPoint.close,
                            high: backendPoint.close * 1.01, // Estimate high ~1% above close
                            low: backendPoint.close * 0.99   // Estimate low ~1% below close
                        )
                    }
                    historyPoints = localPoints
                    
                    // Build PriceHistory from backend data (single source of truth)
                    if let snapshot = tickerSnapshot, !localPoints.isEmpty {
                        let firstClose = localPoints.first?.close ?? snapshot.price
                        let change = snapshot.price - firstClose
                        
                        priceHistory = PriceHistory(
                            ticker: ticker,
                            points: localPoints,
                            currentPrice: snapshot.price,
                            change: change,
                            changePercent: snapshot.changePercent
                        )
                    }
                }
                
                #if DEBUG
                // Validate price consistency in debug builds
                let warnings = dataStoreManager.validatePriceConsistency(for: ticker)
                for warning in warnings {
                    logger.warning("⚠️ \(warning)")
                }
                #endif
            }
            
            // Generate outlook if applicable
            if shouldShowOutlook, let ticker = detectedTicker {
                outlook = await outlookStore.fetchOutlook(symbol: ticker, timeframeDays: timeframeDays)
            } else {
                outlook = nil
            }
            
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
    
    /// Check if query should trigger outlook generation
    private func shouldGenerateOutlook(for query: String) -> Bool {
        let lowercased = query.lowercased()
        
        // Must have a ticker to show outlook
        guard QueryParser.detectTicker(in: query) != nil else {
            return false
        }
        
        // Check for outlook keywords
        return outlookKeywords.contains { lowercased.contains($0) }
    }
    
    /// Load a past conversation from history
    func loadConversation(_ entry: ConversationEntry) {
        question = entry.question
        lastQuery = entry.question
        response = entry.toAIResponse()
        detectedTicker = entry.detectedTicker
        errorMessage = nil
        tickerSnapshot = nil
        historyPoints = nil
        priceHistory = nil
        
        // Reload price data using shared stores
        if let ticker = entry.detectedTicker {
            Task {
                // Refresh all data through stores
                await dataStoreManager.refreshAll(for: ticker)
                
                // Get data from stores
                tickerSnapshot = priceStore.snapshot(for: ticker)
                
                // Build PriceHistory from backend data
                if let storePoints = historyStore.points(for: ticker, range: Constants.historyRange) {
                    let localPoints = storePoints.map { backendPoint in
                        PricePoint(
                            date: backendPoint.date,
                            close: backendPoint.close,
                            high: backendPoint.close * 1.01,
                            low: backendPoint.close * 0.99
                        )
                    }
                    historyPoints = localPoints
                    
                    if let snapshot = tickerSnapshot, !localPoints.isEmpty {
                        let firstClose = localPoints.first?.close ?? snapshot.price
                        let change = snapshot.price - firstClose
                        
                        priceHistory = PriceHistory(
                            ticker: ticker,
                            points: localPoints,
                            currentPrice: snapshot.price,
                            change: change,
                            changePercent: snapshot.changePercent
                        )
                    }
                }
            }
            
            // Regenerate outlook if applicable
            if shouldGenerateOutlook(for: entry.question) {
                Task {
                    outlook = await outlookStore.fetchOutlook(
                        symbol: ticker,
                        timeframeDays: QueryParser.extractTimeframeDays(from: entry.question)
                    )
                }
            } else {
                outlook = nil
            }
        } else {
            priceHistory = nil
            tickerSnapshot = nil
            outlook = nil
            historyPoints = nil
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
        tickerSnapshot = nil
        detectedTicker = nil
        outlook = nil
        lastQuery = ""
        errorMessage = nil
        isLoading = false
        historyPoints = nil
    }
    
    func updateChartRange(_ range: ChartTimeRange) {
        guard let ticker = detectedTicker else { return }
        
        // Map chart range to backend range format
        let backendRange: String
        switch range {
        case .oneDay: backendRange = "1D"
        case .oneMonth: backendRange = "1M"
        case .sixMonths: backendRange = "6M"
        case .oneYear: backendRange = "1Y"
        }
        
        Task {
            // Refresh history for the new range
            await historyStore.refresh(symbol: ticker, range: backendRange)
            
            // Get updated points and rebuild PriceHistory
            if let storePoints = historyStore.points(for: ticker, range: backendRange) {
                let localPoints = storePoints.map { backendPoint in
                    PricePoint(
                        date: backendPoint.date,
                        close: backendPoint.close,
                        high: backendPoint.close * 1.01,
                        low: backendPoint.close * 0.99
                    )
                }
                historyPoints = localPoints
                
                if let snapshot = tickerSnapshot, !localPoints.isEmpty {
                    let firstClose = localPoints.first?.close ?? snapshot.price
                    let change = snapshot.price - firstClose
                    
                    priceHistory = PriceHistory(
                        ticker: ticker,
                        points: localPoints,
                        currentPrice: snapshot.price,
                        change: change,
                        changePercent: snapshot.changePercent
                    )
                }
            }
        }
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

    private func buildAIResponse(from response: BackendModels.AIResponse, query: String) -> AIResponse {
        let sections = [
            AIResponse.Section(type: .currentSituation, content: response.whatsHappeningNow),
            AIResponse.Section(type: .keyDrivers, content: "", bulletPoints: response.keyDrivers),
            AIResponse.Section(type: .riskOpportunity, content: response.riskVsOpportunity),
            AIResponse.Section(type: .historical, content: response.historicalBehavior),
            AIResponse.Section(type: .recap, content: response.simpleRecap)
        ]

        return AIResponse(query: query, sections: sections)
    }

    // NOTE: Direct API calls removed — all data fetching now goes through shared stores
    // (PriceStore, HistoryStore, AIResponseStore, OutlookStore) to ensure single source of truth
}
