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
    let generatedAt: Date
    
    /// Sentiment categories — descriptive, not predictive
    enum SentimentSummary: String, Codable {
        case positive = "Positive"
        case mixed = "Mixed"
        case cautious = "Cautious"
        
        var description: String {
            switch self {
            case .positive:
                return "Current conditions appear favorable based on recent trends and sector momentum."
            case .mixed:
                return "Signals are mixed — some positive indicators balanced by areas of uncertainty."
            case .cautious:
                return "Conditions suggest elevated uncertainty or headwinds in the near term."
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
    
    init(tradeService: MockTradeDataService = MockTradeDataService()) {
        self.tradeService = tradeService
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
        
        return Outlook(
            ticker: normalizedTicker,
            timeframeDays: timeframeDays,
            sentimentSummary: sentiment,
            keyDrivers: drivers,
            volatilityBand: volatilityBand,
            historicalHitRate: adjustedHitRate,
            personalContext: personalContext,
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
        
        return Outlook(
            ticker: normalizedTicker,
            timeframeDays: timeframeDays,
            sentimentSummary: sentiment,
            keyDrivers: drivers,
            volatilityBand: volatilityBand,
            historicalHitRate: adjustedHitRate,
            personalContext: nil,
            generatedAt: Date()
        )
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
            selectedDrivers.append("Momentum indicators showing strength")
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
        guard let trades = try? tradeService.getCachedTrades() else {
            return nil
        }
        
        // Find trades for this ticker
        let tickerTrades = trades.filter { $0.ticker.uppercased() == ticker }
        
        guard !tickerTrades.isEmpty else {
            // Check for sector-related trades
            let sectorTickers = tickerMetadata.filter { $0.value.sector == metadata.sector }.map { $0.key }
            let sectorTrades = trades.filter { sectorTickers.contains($0.ticker.uppercased()) }
            
            if sectorTrades.count >= 3 {
                let wins = sectorTrades.filter { $0.realizedPnL > 0 }.count
                let winRate = Double(wins) / Double(sectorTrades.count)
                
                if winRate > 0.6 {
                    return "You've had good results in the \(metadata.sector) sector — \(Int(winRate * 100))% win rate across \(sectorTrades.count) trades."
                } else if winRate < 0.4 {
                    return "The \(metadata.sector) sector has been challenging for you — something to factor in."
                }
            }
            return nil
        }
        
        // Analyze ticker-specific history
        let wins = tickerTrades.filter { $0.realizedPnL > 0 }.count
        let winRate = Double(wins) / Double(tickerTrades.count)
        let avgHoldDays = tickerTrades.reduce(0) { $0 + $1.holdingDays } / tickerTrades.count
        let totalPnL = tickerTrades.reduce(0.0) { $0 + $1.realizedPnL }
        
        if tickerTrades.count >= 3 {
            if winRate > 0.65 {
                return "You've traded \(ticker) \(tickerTrades.count) times with a \(Int(winRate * 100))% win rate — historically one of your stronger names."
            } else if winRate < 0.40 {
                return "\(ticker) has been tricky for you — \(Int(winRate * 100))% win rate over \(tickerTrades.count) trades. Past results don't predict the future, but worth noting."
            } else if avgHoldDays < 5 {
                return "You tend to trade \(ticker) quickly (avg \(avgHoldDays) days). Your current lookback window is longer."
            }
        } else if tickerTrades.count >= 1 {
            let recentTrade = tickerTrades.first!
            let outcome = recentTrade.realizedPnL > 0 ? "profit" : "loss"
            return "You last traded \(ticker) for a \(outcome). One data point, but recent memory."
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

