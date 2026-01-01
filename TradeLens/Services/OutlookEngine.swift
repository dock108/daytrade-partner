//
//  OutlookEngine.swift
//  TradeLens
//
//  Central service that synthesizes data and produces structured outlooks.
//  Returns descriptive metrics only — no predictions or financial advice.
//

import Foundation

// MARK: - Outlook Model

/// Structured outlook for a ticker over a given timeframe
struct Outlook: Identifiable {
    let id = UUID()
    let ticker: String
    let timeframeDays: Int
    let sentimentSummary: SentimentSummary
    let keyDrivers: [String]
    let volatilityBand: Double          // Expected swing as percentage (e.g., 0.08 = 8%)
    let historicalHitRate: Double       // % times ticker was up over similar windows
    let personalContext: String?        // Tailored note from user history
    let volatilityWarning: String?      // Warning if above user's tolerance
    let timeframeNote: String?          // Note if timeframe differs from user's style
    let generatedAt: Date
    
    /// Sentiment categories — descriptive, not predictive
    enum SentimentSummary: String, Codable {
        case positive = "Positive"
        case mixed = "Mixed"
        case cautious = "Cautious"
        
        var description: String {
            switch self {
            case .positive:
                return "Recent trends and sector momentum look constructive, helping explain what traders may be reacting to."
            case .mixed:
                return "Signals are mixed — supportive indicators sit alongside uncertainty."
            case .cautious:
                return "Recent data points show more uncertainty or headwinds, which can make moves feel less clear."
            }
        }
        
        /// Simplified description for users preferring simple mode
        var simpleDescription: String {
            switch self {
            case .positive:
                return "Recent trends look constructive, which can make the picture feel clearer."
            case .mixed:
                return "It's a mixed picture — some good signs, some uncertainty."
            case .cautious:
                return "There's more uncertainty than usual right now."
            }
        }
        
        var icon: String {
            switch self {
            case .positive: return "arrow.up.right.circle.fill"
            case .mixed: return "arrow.left.arrow.right.circle.fill"
            case .cautious: return "exclamationmark.triangle.fill"
            }
        }
    }
}

// MARK: - Outlook Engine

/// Engine that synthesizes market data into structured outlooks
@MainActor
final class OutlookEngine {
    
    // MARK: - Dependencies
    
    private let tradeService: MockTradeDataService
    private let preferencesManager: UserPreferencesManager
    
    // MARK: - Mock Data Sources
    
    /// Sector trends (mock data)
    private let sectorTrends: [String: SectorTrend] = [
        "Technology": SectorTrend(momentum: .positive, strength: 0.72),
        "Healthcare": SectorTrend(momentum: .mixed, strength: 0.48),
        "Energy": SectorTrend(momentum: .cautious, strength: 0.35),
        "Financials": SectorTrend(momentum: .positive, strength: 0.61),
        "Consumer Discretionary": SectorTrend(momentum: .mixed, strength: 0.52),
        "Consumer Staples": SectorTrend(momentum: .positive, strength: 0.58),
        "Industrials": SectorTrend(momentum: .mixed, strength: 0.49),
        "Materials": SectorTrend(momentum: .cautious, strength: 0.41),
        "Utilities": SectorTrend(momentum: .positive, strength: 0.55),
        "Real Estate": SectorTrend(momentum: .cautious, strength: 0.38),
        "Communication Services": SectorTrend(momentum: .mixed, strength: 0.53)
    ]
    
    /// Ticker metadata (mock)
    private let tickerMetadata: [String: TickerMetadata] = [
        "NVDA": TickerMetadata(sector: "Technology", baseVolatility: 0.12, historicalUpRate: 0.68),
        "AAPL": TickerMetadata(sector: "Technology", baseVolatility: 0.06, historicalUpRate: 0.62),
        "MSFT": TickerMetadata(sector: "Technology", baseVolatility: 0.05, historicalUpRate: 0.64),
        "GOOGL": TickerMetadata(sector: "Communication Services", baseVolatility: 0.07, historicalUpRate: 0.58),
        "AMZN": TickerMetadata(sector: "Consumer Discretionary", baseVolatility: 0.08, historicalUpRate: 0.60),
        "META": TickerMetadata(sector: "Communication Services", baseVolatility: 0.10, historicalUpRate: 0.55),
        "TSLA": TickerMetadata(sector: "Consumer Discretionary", baseVolatility: 0.18, historicalUpRate: 0.52),
        "SPY": TickerMetadata(sector: "Broad Market", baseVolatility: 0.04, historicalUpRate: 0.65),
        "QQQ": TickerMetadata(sector: "Technology", baseVolatility: 0.06, historicalUpRate: 0.63),
        "AMD": TickerMetadata(sector: "Technology", baseVolatility: 0.14, historicalUpRate: 0.56),
        "COIN": TickerMetadata(sector: "Financials", baseVolatility: 0.22, historicalUpRate: 0.48),
        "UNH": TickerMetadata(sector: "Healthcare", baseVolatility: 0.05, historicalUpRate: 0.61),
        "BND": TickerMetadata(sector: "Fixed Income", baseVolatility: 0.02, historicalUpRate: 0.54),
        "MRNA": TickerMetadata(sector: "Healthcare", baseVolatility: 0.16, historicalUpRate: 0.45),
        "XLE": TickerMetadata(sector: "Energy", baseVolatility: 0.09, historicalUpRate: 0.51),
        "GLD": TickerMetadata(sector: "Commodities", baseVolatility: 0.04, historicalUpRate: 0.56),
        "USO": TickerMetadata(sector: "Energy", baseVolatility: 0.11, historicalUpRate: 0.49)
    ]
    
    /// Key drivers by sector and condition (mock)
    private let sectorDrivers: [String: [String]] = [
        "Technology": [
            "AI infrastructure spending trends",
            "Enterprise software demand",
            "Semiconductor supply dynamics",
            "Consumer tech refresh cycles",
            "Cloud computing growth rates"
        ],
        "Healthcare": [
            "Drug pipeline developments",
            "Medicare/Medicaid policy changes",
            "Biotech funding environment",
            "Hospital admission trends",
            "Insurance coverage dynamics"
        ],
        "Energy": [
            "OPEC+ production decisions",
            "U.S. shale output levels",
            "Global demand signals",
            "Geopolitical risk premium",
            "Energy transition policies"
        ],
        "Financials": [
            "Interest rate trajectory",
            "Credit quality trends",
            "M&A activity levels",
            "Regulatory environment",
            "Consumer lending demand"
        ],
        "Consumer Discretionary": [
            "Consumer confidence levels",
            "Employment trends",
            "Wage growth dynamics",
            "E-commerce penetration",
            "Discretionary spending patterns"
        ],
        "Broad Market": [
            "Federal Reserve policy stance",
            "Corporate earnings trajectory",
            "Economic growth indicators",
            "Inflation trends",
            "Market breadth signals"
        ],
        "Commodities": [
            "Dollar strength/weakness",
            "Real interest rates",
            "Central bank buying activity",
            "Inflation expectations",
            "Safe-haven demand"
        ],
        "Fixed Income": [
            "Interest rate expectations",
            "Credit spread movements",
            "Duration positioning",
            "Inflation breakevens",
            "Fed policy signals"
        ],
        "Communication Services": [
            "Digital advertising spend",
            "Streaming subscriber trends",
            "Social media engagement",
            "Content investment cycles",
            "Regulatory scrutiny levels"
        ]
    ]
    
    // MARK: - Initialization
    
    init(
        tradeService: MockTradeDataService = MockTradeDataService(),
        preferencesManager: UserPreferencesManager = .shared
    ) {
        self.tradeService = tradeService
        self.preferencesManager = preferencesManager
    }
    
    // MARK: - Public API
    
    /// Generate an outlook for a given ticker
    /// - Parameters:
    ///   - ticker: The stock/ETF ticker symbol
    ///   - timeframeDays: Outlook window in days (default 30)
    ///   - includePersonalContext: Whether to include user trade history context
    /// - Returns: Structured Outlook
    func generateOutlook(
        for ticker: String,
        timeframeDays: Int = 30,
        includePersonalContext: Bool = true
    ) async -> Outlook {
        let normalizedTicker = ticker.uppercased()
        
        // Get ticker metadata (or use defaults)
        let metadata = tickerMetadata[normalizedTicker] ?? TickerMetadata(
            sector: "Broad Market",
            baseVolatility: 0.08,
            historicalUpRate: 0.55
        )
        
        // Get sector trend
        let sectorTrend = sectorTrends[metadata.sector] ?? SectorTrend(momentum: .mixed, strength: 0.50)
        
        // Calculate sentiment
        let sentiment = calculateSentiment(metadata: metadata, sectorTrend: sectorTrend)
        
        // Get key drivers
        let drivers = selectKeyDrivers(for: metadata.sector, sentiment: sentiment)
        
        // Calculate volatility band (adjusted for timeframe)
        let volatilityBand = calculateVolatilityBand(
            baseVolatility: metadata.baseVolatility,
            timeframeDays: timeframeDays,
            sectorStrength: sectorTrend.strength
        )
        
        // Adjust historical hit rate for current conditions
        let adjustedHitRate = adjustHistoricalRate(
            baseRate: metadata.historicalUpRate,
            sentiment: sentiment,
            sectorStrength: sectorTrend.strength
        )
        
        // Generate personal context if requested
        var personalContext: String? = nil
        if includePersonalContext {
            personalContext = await generatePersonalContext(
                ticker: normalizedTicker,
                metadata: metadata
            )
        }
        
        // Generate preference-aware notes
        let volatilityWarning = generateVolatilityWarning(volatilityBand: volatilityBand)
        let timeframeNote = generateTimeframeNote(timeframeDays: timeframeDays)
        
        return Outlook(
            ticker: normalizedTicker,
            timeframeDays: timeframeDays,
            sentimentSummary: sentiment,
            keyDrivers: drivers,
            volatilityBand: volatilityBand,
            historicalHitRate: adjustedHitRate,
            personalContext: personalContext,
            volatilityWarning: volatilityWarning,
            timeframeNote: timeframeNote,
            generatedAt: Date()
        )
    }
    
    /// Quick outlook for display (synchronous, no personal context)
    func quickOutlook(for ticker: String, timeframeDays: Int = 30) -> Outlook {
        let normalizedTicker = ticker.uppercased()
        
        let metadata = tickerMetadata[normalizedTicker] ?? TickerMetadata(
            sector: "Broad Market",
            baseVolatility: 0.08,
            historicalUpRate: 0.55
        )
        
        let sectorTrend = sectorTrends[metadata.sector] ?? SectorTrend(momentum: .mixed, strength: 0.50)
        let sentiment = calculateSentiment(metadata: metadata, sectorTrend: sectorTrend)
        let drivers = selectKeyDrivers(for: metadata.sector, sentiment: sentiment)
        
        let volatilityBand = calculateVolatilityBand(
            baseVolatility: metadata.baseVolatility,
            timeframeDays: timeframeDays,
            sectorStrength: sectorTrend.strength
        )
        
        let adjustedHitRate = adjustHistoricalRate(
            baseRate: metadata.historicalUpRate,
            sentiment: sentiment,
            sectorStrength: sectorTrend.strength
        )
        
        let volatilityWarning = generateVolatilityWarning(volatilityBand: volatilityBand)
        let timeframeNote = generateTimeframeNote(timeframeDays: timeframeDays)
        
        return Outlook(
            ticker: normalizedTicker,
            timeframeDays: timeframeDays,
            sentimentSummary: sentiment,
            keyDrivers: drivers,
            volatilityBand: volatilityBand,
            historicalHitRate: adjustedHitRate,
            personalContext: nil,
            volatilityWarning: volatilityWarning,
            timeframeNote: timeframeNote,
            generatedAt: Date()
        )
    }
    
    /// Get user's preferred default timeframe
    func preferredTimeframe() -> Int {
        preferencesManager.preferences.tradingStyle.defaultTimeframeDays
    }
    
    /// Check if ticker is in user's watch list
    func isWatchedTicker(_ ticker: String) -> Bool {
        preferencesManager.preferences.watchedTickers.contains(ticker.uppercased())
    }
    
    // MARK: - Private Calculations
    
    private func calculateSentiment(
        metadata: TickerMetadata,
        sectorTrend: SectorTrend
    ) -> Outlook.SentimentSummary {
        // Combine sector momentum with historical performance
        let combinedScore = (sectorTrend.strength + metadata.historicalUpRate) / 2
        
        switch sectorTrend.momentum {
        case .positive where combinedScore > 0.55:
            return .positive
        case .cautious where combinedScore < 0.50:
            return .cautious
        default:
            return .mixed
        }
    }
    
    private func selectKeyDrivers(
        for sector: String,
        sentiment: Outlook.SentimentSummary
    ) -> [String] {
        let allDrivers = sectorDrivers[sector] ?? sectorDrivers["Broad Market"]!
        
        // Select 3 drivers, prioritizing based on sentiment
        var selectedDrivers = Array(allDrivers.shuffled().prefix(3))
        
        // Add a sentiment-appropriate driver
        switch sentiment {
        case .positive:
            selectedDrivers.append("Momentum indicators showing recent strength")
        case .cautious:
            selectedDrivers.append("Risk metrics elevated relative to recent history")
        case .mixed:
            selectedDrivers.append("Technical signals showing consolidation patterns")
        }
        
        return selectedDrivers
    }
    
    private func calculateVolatilityBand(
        baseVolatility: Double,
        timeframeDays: Int,
        sectorStrength: Double
    ) -> Double {
        // Volatility scales with square root of time
        let timeAdjustment = sqrt(Double(timeframeDays) / 30.0)
        
        // Sector weakness increases expected volatility
        let sectorAdjustment = 1.0 + (0.5 - sectorStrength) * 0.3
        
        // Add some randomness for realism
        let noise = Double.random(in: 0.95...1.05)
        
        return (baseVolatility * timeAdjustment * sectorAdjustment * noise).rounded(toPlaces: 3)
    }
    
    private func adjustHistoricalRate(
        baseRate: Double,
        sentiment: Outlook.SentimentSummary,
        sectorStrength: Double
    ) -> Double {
        var adjusted = baseRate
        
        // Adjust based on current sentiment
        switch sentiment {
        case .positive:
            adjusted += 0.05
        case .cautious:
            adjusted -= 0.05
        case .mixed:
            break
        }
        
        // Factor in sector strength
        adjusted += (sectorStrength - 0.5) * 0.1
        
        // Clamp to realistic range
        return min(0.80, max(0.35, adjusted)).rounded(toPlaces: 2)
    }
    
    private func generatePersonalContext(
        ticker: String,
        metadata: TickerMetadata
    ) async -> String? {
        // Try to get user's trade history
        guard let trades = try? tradeService.getCachedTrades(), trades.count >= 5 else {
            return nil
        }
        
        // Analyze behavioral patterns based on volatility and sentiment
        // Focus on how user behaves in similar setups, not just this ticker
        
        let observation = generateBehavioralObservation(
            ticker: ticker,
            metadata: metadata,
            allTrades: trades
        )
        
        return observation
    }
    
    /// Generates a gentle, behavior-focused observation based on similar setups.
    /// Returns nil when no relevant pattern is found — not always shown.
    private func generateBehavioralObservation(
        ticker: String,
        metadata: TickerMetadata,
        allTrades: [MockTrade]
    ) -> String? {
        // Categorize trades by volatility similarity
        let highVolTickers = Set(tickerMetadata.filter { $0.value.baseVolatility >= 0.10 }.map { $0.key })
        let moderateVolTickers = Set(tickerMetadata.filter { $0.value.baseVolatility >= 0.05 && $0.value.baseVolatility < 0.10 }.map { $0.key })
        let lowVolTickers = Set(tickerMetadata.filter { $0.value.baseVolatility < 0.05 }.map { $0.key })
        
        // Determine current ticker's volatility category
        let isHighVol = metadata.baseVolatility >= 0.10
        let isModerateVol = metadata.baseVolatility >= 0.05 && metadata.baseVolatility < 0.10
        
        // Get trades in similar volatility category
        let similarVolTrades: [MockTrade]
        if isHighVol {
            similarVolTrades = allTrades.filter { highVolTickers.contains($0.ticker.uppercased()) }
        } else if isModerateVol {
            similarVolTrades = allTrades.filter { moderateVolTickers.contains($0.ticker.uppercased()) }
        } else {
            similarVolTrades = allTrades.filter { lowVolTickers.contains($0.ticker.uppercased()) }
        }
        
        // Need enough data for a meaningful pattern
        guard similarVolTrades.count >= 3 else {
            return generateTickerSpecificObservation(ticker: ticker, allTrades: allTrades, metadata: metadata)
        }
        
        // Analyze behavioral patterns in similar setups
        let observations = analyzeBehavioralPatterns(trades: similarVolTrades, allTrades: allTrades, isHighVol: isHighVol)
        
        // Return first relevant observation, or nil
        return observations.randomElement()
    }
    
    /// Analyzes behavioral patterns and returns supportive observations
    private func analyzeBehavioralPatterns(
        trades: [MockTrade],
        allTrades: [MockTrade],
        isHighVol: Bool
    ) -> [String] {
        var observations: [String] = []
        
        // Pattern 1: Early exit tendency in volatile situations
        let earlyExits = trades.filter { $0.holdingDays <= 3 }
        let longerHolds = trades.filter { $0.holdingDays > 7 }
        
        if earlyExits.count >= 3 && longerHolds.count >= 2 {
            let earlyWinRate = Double(earlyExits.filter { $0.realizedPnL > 0 }.count) / Double(earlyExits.count)
            let longerWinRate = Double(longerHolds.filter { $0.realizedPnL > 0 }.count) / Double(longerHolds.count)
            
            if earlyWinRate < longerWinRate - 0.15 && isHighVol {
                observations.append("In similar volatile setups, your exits have skewed earlier; longer holds have lined up with stronger results in this category.")
            } else if earlyWinRate > longerWinRate + 0.15 {
                observations.append("In similar situations, your short-term moves have lined up with stronger outcomes.")
            }
        }
        
        // Pattern 2: Performance during volatile swings
        let volatileOutcomes = trades.filter { abs($0.returnPct) > 0.08 }
        if volatileOutcomes.count >= 3 {
            let bigWins = volatileOutcomes.filter { $0.returnPct > 0.08 }.count
            let bigLosses = volatileOutcomes.filter { $0.returnPct < -0.08 }.count
            
            if bigWins > bigLosses * 2 {
                observations.append("Big swings have leaned positive for you in the past — useful context for how this volatility can feel.")
            } else if bigLosses > bigWins && isHighVol {
                observations.append("When swings have been large in this category, outcomes have been mixed in your history.")
            }
        }
        
        // Pattern 3: Recovery from dips
        let lossingTrades = allTrades.filter { $0.realizedPnL < 0 }
        let subsequentTrades = allTrades.enumerated().compactMap { index, trade -> MockTrade? in
            guard trade.realizedPnL < 0, index + 1 < allTrades.count else { return nil }
            return allTrades[index + 1]
        }
        
        if subsequentTrades.count >= 3 {
            let recoveredWell = subsequentTrades.filter { $0.realizedPnL > 0 }.count
            let recoveryRate = Double(recoveredWell) / Double(subsequentTrades.count)
            
            if recoveryRate > 0.65 {
                observations.append("After setbacks, your next trade has more often been positive — a pattern to note in your history.")
            }
        }
        
        // Pattern 4: Sector comfort
        let techTickers = Set(["NVDA", "AAPL", "MSFT", "AMD", "GOOGL", "META", "AMZN"])
        let techTrades = allTrades.filter { techTickers.contains($0.ticker.uppercased()) }
        let otherTrades = allTrades.filter { !techTickers.contains($0.ticker.uppercased()) }
        
        if techTrades.count >= 3 && otherTrades.count >= 3 {
            let techWinRate = Double(techTrades.filter { $0.realizedPnL > 0 }.count) / Double(techTrades.count)
            let otherWinRate = Double(otherTrades.filter { $0.realizedPnL > 0 }.count) / Double(otherTrades.count)
            
            if techWinRate > otherWinRate + 0.12 && techTickers.contains(trades.first?.ticker.uppercased() ?? "") {
                observations.append("Tech names have lined up with stronger results in your history.")
            }
        }
        
        // Pattern 5: Position sizing intuition (based on P&L magnitude)
        let avgWin = trades.filter { $0.realizedPnL > 0 }.reduce(0.0) { $0 + $1.realizedPnL } / max(1.0, Double(trades.filter { $0.realizedPnL > 0 }.count))
        let avgLoss = abs(trades.filter { $0.realizedPnL < 0 }.reduce(0.0) { $0 + $1.realizedPnL } / max(1.0, Double(trades.filter { $0.realizedPnL < 0 }.count)))
        
        if avgWin > avgLoss * 1.5 && trades.count >= 5 {
            observations.append("In this category, average wins have been larger than average losses in your history.")
        }
        
        return observations
    }
    
    /// Fallback: ticker-specific observation when no behavioral pattern is found
    private func generateTickerSpecificObservation(
        ticker: String,
        allTrades: [MockTrade],
        metadata: TickerMetadata
    ) -> String? {
        // Find trades for this specific ticker
        let tickerTrades = allTrades.filter { $0.ticker.uppercased() == ticker }
        
        guard !tickerTrades.isEmpty else {
            // Check for sector-related trades
            let sectorTickers = tickerMetadata.filter { $0.value.sector == metadata.sector }.map { $0.key }
            let sectorTrades = allTrades.filter { sectorTickers.contains($0.ticker.uppercased()) }
            
            if sectorTrades.count >= 3 {
                let wins = sectorTrades.filter { $0.realizedPnL > 0 }.count
                let winRate = Double(wins) / Double(sectorTrades.count)
                
                if winRate > 0.60 {
                    return "Your \(metadata.sector) trades have leaned positive overall — \(Int(winRate * 100))% have been winners."
                }
            }
            return nil
        }
        
        // Ticker-specific history with supportive framing
        let wins = tickerTrades.filter { $0.realizedPnL > 0 }.count
        let winRate = Double(wins) / Double(tickerTrades.count)
        let avgHoldDays = tickerTrades.reduce(0) { $0 + $1.holdingDays } / tickerTrades.count
        
        if tickerTrades.count >= 3 {
            if winRate > 0.60 {
                return "You've traded \(ticker) \(tickerTrades.count) times — the results have leaned positive in your history."
            } else if avgHoldDays < 5 {
                return "You've typically traded \(ticker) on shorter timeframes — averaging \(avgHoldDays) days. This outlook looks further out."
            }
        } else if tickerTrades.count >= 1 {
            return "You have some history with \(ticker) — that context can help frame how it fits your approach."
        }
        
        return nil
    }
    
    // MARK: - Preference-Aware Notes
    
    private func generateVolatilityWarning(volatilityBand: Double) -> String? {
        let userTolerance = preferencesManager.preferences.riskTolerance
        let threshold = userTolerance.volatilityWarningThreshold
        
        guard volatilityBand > threshold else { return nil }
        
        let percentAbove = Int((volatilityBand - threshold) / threshold * 100)
        
        switch userTolerance {
        case .low:
            return "The recent swing range here sits about \(percentAbove)% above your comfort setting, which can make moves feel jumpier."
        case .moderate:
            return "Heads up: recent volatility has been higher than your comfort setting."
        case .high:
            // High tolerance users rarely see warnings
            return "Even for someone comfortable with swings, this has been on the volatile side lately."
        }
    }
    
    private func generateTimeframeNote(timeframeDays: Int) -> String? {
        let userStyle = preferencesManager.preferences.tradingStyle
        let preferredDays = userStyle.defaultTimeframeDays
        
        // Only note if significantly different
        let ratio = Double(timeframeDays) / Double(preferredDays)
        
        if ratio > 3.0 {
            switch userStyle {
            case .shortTerm:
                return "This is a longer timeframe than you typically trade. The context can feel different at this horizon."
            case .mixed:
                return nil
            case .longTerm:
                return nil
            }
        } else if ratio < 0.3 {
            switch userStyle {
            case .longTerm:
                return "This is a shorter window than your usual holding period. Short-term noise may be higher."
            case .mixed:
                return nil
            case .shortTerm:
                return nil
            }
        }
        
        return nil
    }
}

// MARK: - Supporting Types

private struct TickerMetadata {
    let sector: String
    let baseVolatility: Double
    let historicalUpRate: Double
}

private struct SectorTrend {
    let momentum: Outlook.SentimentSummary
    let strength: Double  // 0.0 to 1.0
}

// MARK: - Extensions

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
