//
//  AIServiceStub.swift
//  TradeLens
//
//  Stub AI service that returns structured article-style responses.
//  Uses AIContentProvider for topic content and builds personalized sections.
//

import Foundation

@MainActor
final class AIServiceStub {
    private let tradeService: MockTradeDataService
    private let analyticsService: TradeAnalyticsService
    private let insightsService: InsightsService

    private var summary: UserSummary?
    private var insights: [InsightsService.InsightItem] = []
    private var isLoading = false

    init(
        tradeService: MockTradeDataService = MockTradeDataService(),
        analyticsService: TradeAnalyticsService = TradeAnalyticsService(),
        insightsService: InsightsService = InsightsService()
    ) {
        self.tradeService = tradeService
        self.analyticsService = analyticsService
        self.insightsService = insightsService

        Task {
            await loadContext()
        }
    }

    // MARK: - Public API
    
    func structuredResponse(for question: String) -> AIResponse {
        let normalized = question.lowercased()
        let isSimpleMode = UserSettings.shared.isSimpleModeEnabled
        var sections: [AIResponse.Section] = []
        
        // Get topic-specific content from provider
        let topicContent = isSimpleMode 
            ? AIContentProvider.getSimpleContent(for: normalized)
            : AIContentProvider.getContent(for: normalized)
        
        // Build sections from topic content
        sections.append(AIResponse.Section(
            type: .currentSituation,
            content: topicContent.current
        ))
        
        sections.append(AIResponse.Section(
            type: .keyDrivers,
            content: topicContent.driversIntro,
            bulletPoints: topicContent.drivers
        ))
        
        sections.append(AIResponse.Section(
            type: .riskOpportunity,
            content: topicContent.riskOpportunity
        ))
        
        sections.append(AIResponse.Section(
            type: .historical,
            content: topicContent.historical
        ))
        
        sections.append(AIResponse.Section(
            type: .recap,
            content: topicContent.recap
        ))
        
        // Add digest section
        let digestContent = buildDigestSection(for: normalized, simple: isSimpleMode)
        sections.append(AIResponse.Section(
            type: .digest,
            content: digestContent
        ))
        
        // Add personalized context if available
        if let personalSection = buildPersonalizedSection(for: normalized, simple: isSimpleMode) {
            sections.append(personalSection)
        }
        
        // Add subtle personal note when relevant
        if let personalNote = buildPersonalNote(for: normalized, simple: isSimpleMode) {
            sections.append(personalNote)
        }
        
        // Generate sources for this topic
        let sources = buildSources(for: normalized)
        
        return AIResponse(
            query: question,
            sections: sections,
            sources: sources,
            timestamp: Date()
        )
    }

    /// Legacy support - returns plain text response
    func response(for question: String) -> String {
        let structured = structuredResponse(for: question)
        return structured.sections.map { $0.content }.joined(separator: "\n\n")
    }

    // MARK: - Context Loading

    private func loadContext() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let trades = try await tradeService.fetchMockTrades()
            summary = buildSummary(from: trades)
            insights = insightsService.generateInsights(from: trades)
        } catch {
            summary = nil
            insights = []
        }
    }

    private func buildSummary(from trades: [MockTrade]) -> UserSummary {
        let totalTrades = trades.count
        let wins = trades.filter { $0.realizedPnL > 0 }.count
        let winRate = totalTrades > 0 ? Double(wins) / Double(totalTrades) : 0
        let realizedPnLTotal = trades.reduce(0) { $0 + $1.realizedPnL }
        let avgHoldDays = analyticsService.averageHoldingDays(for: trades)
        let speculativePercent = analyticsService.speculativeShare(for: trades)
        let (bestTicker, worstTicker) = analyticsService.tickerExtremes(for: trades)

        return UserSummary(
            totalTrades: totalTrades,
            winRate: winRate,
            avgHoldDays: avgHoldDays,
            bestTicker: bestTicker,
            worstTicker: worstTicker,
            speculativePercent: speculativePercent,
            realizedPnLTotal: realizedPnLTotal
        )
    }
    
    // MARK: - Personalized Section
    
    private func buildPersonalizedSection(for normalized: String, simple: Bool = false) -> AIResponse.Section? {
        guard let summary else { return nil }
        
        var points: [String] = []
        
        let winRate = CurrencyFormatter.formatPercentage(summary.winRate)
        let avgHoldDays = Int(summary.avgHoldDays.rounded())
        let pnl = CurrencyFormatter.formatUSD(summary.realizedPnLTotal)
        
        if simple {
            points.append("You've made \(summary.totalTrades) trades total")
            points.append("About \(winRate) of your trades have closed positive")
            points.append("You typically hold for \(avgHoldDays) days")
            points.append("Total realized P/L so far: \(pnl)")
        } else {
            points.append("You have \(summary.totalTrades) closed trades; about \(winRate) finished positive")
            points.append("Average hold period: \(avgHoldDays) days")
            points.append("Total realized P/L: \(pnl)")
        }
        
        if let bestTicker = summary.bestTicker {
            points.append(simple ? "Top P/L ticker: \(bestTicker)" : "Highest P/L ticker: \(bestTicker)")
        }
        
        if let worstTicker = summary.worstTicker {
            points.append(simple ? "Lowest P/L ticker: \(worstTicker)" : "Lowest P/L ticker: \(worstTicker)")
        }
        
        // Add relevant insight
        let holdingInsight = insights.first { $0.title == "Holding Range" }
        if let holdingInsight {
            points.append(holdingInsight.detail)
        }
        
        let intro = simple 
            ? "Here's a quick look at your trading:"
            : "Based on your trading history, here's some context that may relate to this topic:"
        
        return AIResponse.Section(
            type: .yourContext,
            content: intro,
            bulletPoints: points
        )
    }
    
    // MARK: - Personal Note
    
    /// Generates a subtle personal observation when relevant to the topic.
    /// Returns nil if no relevant insight is available.
    private func buildPersonalNote(for normalized: String, simple: Bool = false) -> AIResponse.Section? {
        guard let summary else { return nil }
        
        let trades = (try? tradeService.getCachedTrades()) ?? []
        guard trades.count >= 5 else { return nil }
        
        // Calculate trading patterns
        let patterns = TradingPatternAnalyzer.analyze(trades: trades, summary: summary)
        
        // Generate note based on topic
        var note: String? = nil
        
        if normalized.contains("qqq") || normalized.contains("spy") || normalized.contains("etf") {
            note = patterns.etfNote(simple: simple)
        }
        
        if note == nil && (normalized.contains("nvda") || normalized.contains("nvidia") || 
           normalized.contains("oil") || normalized.contains("volatile")) {
            note = patterns.volatilityNote(simple: simple)
        }
        
        if note == nil && (normalized.contains("hold") || normalized.contains("timing") || 
           normalized.contains("exit") || normalized.contains("sell")) {
            note = patterns.holdingPeriodNote(simple: simple)
        }
        
        if note == nil && (normalized.contains("tech") || normalized.contains("growth") || 
           normalized.contains("ai")) {
            note = patterns.techNote(simple: simple)
        }
        
        if note == nil {
            note = patterns.earlyExitNote(simple: simple)
        }
        
        guard let personalNote = note else { return nil }
        
        return AIResponse.Section(
            type: .personalNote,
            content: personalNote
        )
    }
    
    // MARK: - Digest Section
    
    private func buildDigestSection(for normalized: String, simple: Bool) -> String {
        DigestBuilder.build(for: normalized, simple: simple)
    }
    
    // MARK: - Sources
    
    private func buildSources(for normalized: String) -> [AIResponse.SourceReference] {
        SourcesBuilder.build(for: normalized)
    }
}

// MARK: - Trading Pattern Analyzer

/// Analyzes trading patterns for personalized insights
private struct TradingPatternAnalyzer {
    let etfWinRate: Double
    let stockWinRate: Double
    let volatileWinRate: Double
    let overallWinRate: Double
    let quickExitWinRate: Double
    let longerHoldWinRate: Double
    let techWinRate: Double
    let nonTechWinRate: Double
    let hasEnoughETFData: Bool
    let hasEnoughVolatileData: Bool
    let hasEnoughHoldingData: Bool
    let hasEnoughTechData: Bool
    let avgQuickGain: Double
    let avgLongerGain: Double
    let hasQuickExitPattern: Bool
    
    static func analyze(trades: [MockTrade], summary: UserSummary) -> TradingPatternAnalyzer {
        let etfTickers = Set(["QQQ", "SPY", "IWM", "DIA", "ARKK", "VTI", "VOO", "XLE", "XLF", "GLD", "SLV", "USO"])
        let techTickers = Set(["NVDA", "AAPL", "MSFT", "GOOGL", "GOOG", "AMZN", "META", "TSLA", "AMD", "INTC", "CRM", "ADBE"])
        
        let etfTrades = trades.filter { etfTickers.contains($0.ticker.uppercased()) }
        let stockTrades = trades.filter { !etfTickers.contains($0.ticker.uppercased()) }
        let volatileTrades = trades.filter { abs($0.returnPct) > 0.10 }
        let quickExits = trades.filter { $0.holdingDays <= 3 }
        let longerHolds = trades.filter { $0.holdingDays > 7 }
        let techTrades = trades.filter { techTickers.contains($0.ticker.uppercased()) }
        let nonTechTrades = trades.filter { !techTickers.contains($0.ticker.uppercased()) }
        
        func winRate(_ trades: [MockTrade]) -> Double {
            trades.isEmpty ? 0 : Double(trades.filter { $0.realizedPnL > 0 }.count) / Double(trades.count)
        }
        
        func avgGain(_ trades: [MockTrade]) -> Double {
            trades.isEmpty ? 0 : trades.reduce(0.0) { $0 + $1.realizedPnL } / Double(trades.count)
        }
        
        return TradingPatternAnalyzer(
            etfWinRate: winRate(etfTrades),
            stockWinRate: winRate(stockTrades),
            volatileWinRate: winRate(volatileTrades),
            overallWinRate: summary.winRate,
            quickExitWinRate: winRate(quickExits),
            longerHoldWinRate: winRate(longerHolds),
            techWinRate: winRate(techTrades),
            nonTechWinRate: winRate(nonTechTrades),
            hasEnoughETFData: etfTrades.count >= 3,
            hasEnoughVolatileData: volatileTrades.count >= 3,
            hasEnoughHoldingData: quickExits.count >= 3 && longerHolds.count >= 3,
            hasEnoughTechData: techTrades.count >= 3,
            avgQuickGain: avgGain(quickExits),
            avgLongerGain: avgGain(longerHolds),
            hasQuickExitPattern: quickExits.count >= 5
        )
    }
    
    func etfNote(simple: Bool) -> String? {
        guard hasEnoughETFData else { return nil }
        
        if etfWinRate > stockWinRate + 0.15 {
            return simple
                ? "Your ETF trades have leaned stronger than single stocks — about \(Int(etfWinRate * 100))% vs \(Int(stockWinRate * 100))%."
                : "Historically, your ETF trades have leaned stronger (\(Int(etfWinRate * 100))% win rate) than individual stocks (\(Int(stockWinRate * 100))%)."
        } else if stockWinRate > etfWinRate + 0.10 {
            return simple
                ? "Your individual-stock trades have leaned stronger than ETFs."
                : "Your history leans stronger in individual stocks than broad ETFs."
        }
        return nil
    }
    
    func volatilityNote(simple: Bool) -> String? {
        guard hasEnoughVolatileData else { return nil }
        
        if volatileWinRate < overallWinRate - 0.15 {
            return simple
                ? "Quick observation: volatile swings have been tougher in your history, which can add context."
                : "Worth noting: your win rate on high-volatility moves (\(Int(volatileWinRate * 100))%) is below your overall average — helpful context when similar moves show up."
        } else if volatileWinRate > overallWinRate + 0.10 {
            return simple
                ? "Interestingly, your volatile-move results have leaned better than average."
                : "Your history in higher-swing trades has leaned positive, with a \(Int(volatileWinRate * 100))% win rate."
        }
        return nil
    }
    
    func holdingPeriodNote(simple: Bool) -> String? {
        guard hasEnoughHoldingData else { return nil }
        
        if longerHoldWinRate > quickExitWinRate + 0.15 {
            return simple
                ? "Longer holds have lined up with stronger results than quick exits."
                : "In your data, trades held 7+ days have a \(Int(longerHoldWinRate * 100))% win rate vs \(Int(quickExitWinRate * 100))% for quick exits."
        } else if quickExitWinRate > longerHoldWinRate + 0.10 {
            return simple
                ? "Quick trades have leaned stronger for you, which can be useful context."
                : "Your shorter-duration trades have performed better, which can help frame how momentum has shown up for you."
        }
        return nil
    }
    
    func techNote(simple: Bool) -> String? {
        guard hasEnoughTechData else { return nil }
        
        if techWinRate > nonTechWinRate + 0.12 {
            return simple
                ? "Tech has been one of your stronger areas historically."
                : "Tech names have been a relative strength in your history — \(Int(techWinRate * 100))% win rate."
        } else if nonTechWinRate > techWinRate + 0.12 {
            return simple
                ? "Non-tech trades have leaned stronger for you historically."
                : "Your non-tech trades have leaned stronger than tech names historically."
        }
        return nil
    }
    
    func earlyExitNote(simple: Bool) -> String? {
        guard hasQuickExitPattern else { return nil }
        
        if avgLongerGain > avgQuickGain * 1.5 && hasEnoughHoldingData {
            return simple
                ? "During volatile swings, quick exits have landed below longer holds in your history."
                : "Pattern: during volatility, your quick exits have landed below your longer holds in your history."
        }
        return nil
    }
}

// MARK: - Digest Builder

/// Builds human-readable digest summaries
private struct DigestBuilder {
    static func build(for normalized: String, simple: Bool) -> String {
        if normalized.contains("nvda") || normalized.contains("nvidia") {
            return simple ? nvidiaSimple : nvidiaStandard
        }
        if normalized.contains("oil") {
            return simple ? oilSimple : oilStandard
        }
        if normalized.contains("gold") {
            return simple ? goldSimple : goldStandard
        }
        if normalized.contains("qqq") {
            return simple ? qqqSimple : qqqStandard
        }
        if normalized.contains("spy") {
            return simple ? spySimple : spyStandard
        }
        if normalized.contains("inflation") {
            return simple ? inflationSimple : inflationStandard
        }
        return simple ? defaultSimple : defaultStandard
    }
    
    private static let nvidiaSimple = "Here's what's going on: NVIDIA is the company making the brains behind AI. Every time you hear about ChatGPT or AI assistants getting smarter, NVIDIA's chips are usually powering it. Big tech companies are spending billions to buy their products. The stock has moved a lot as expectations rose, which means a lot of good news is already baked into the price."
    
    private static let nvidiaStandard = "The AI infrastructure buildout has positioned NVIDIA as a central supplier of compute power for the industry's largest players. Microsoft, Google, Amazon, and Meta are all racing to scale their AI capabilities, and NVIDIA's H100/H200 chips are a key part of that spend. Recent earnings have been strong, driven by data center revenue that now exceeds gaming. However, the market has priced in substantial future growth — current multiples assume sustained hypergrowth that leaves little room for disappointment. Competition from AMD and custom silicon (Google's TPUs, Amazon's Trainium) represents a longer-term variable."
    
    private static let oilSimple = "Oil prices are like a tug of war right now. On one side, countries that produce oil (OPEC) are trying to limit supply to keep prices up. On the other side, people are worried about the economy slowing down, which would mean less demand for oil. China's economy is a big question mark — if they use more oil, prices go up; if their economy stays sluggish, prices stay flat or drop. It's not really about any one company, it's about global supply and demand."
    
    private static let oilStandard = "Crude oil markets are navigating a complex supply-demand dynamic. OPEC+ continues to manage production cuts aimed at supporting prices, while U.S. shale production has proven more resilient than expected. The demand side hinges heavily on China's economic trajectory — a meaningful recovery would tighten balances, while continued weakness keeps a lid on prices. Geopolitical risk premiums can spike suddenly (Middle East tensions, Russian supply disruptions), but have tended to fade unless actual supply is affected. The macro backdrop — recession risks vs. soft landing — often explains direction more than any single catalyst."
    
    private static let goldSimple = "Gold is behaving like it usually does — it's the thing people buy when they're nervous. Central banks around the world, especially in Asia, have been stockpiling gold as a hedge against uncertainty. But here's the catch: when interest rates are high, bonds and savings accounts pay you a return, while gold just sits there. So gold has been range-bound — up when fears spike, flat when rates dominate the conversation."
    
    private static let goldStandard = "The gold market is responding to competing forces: safe-haven demand from central banks (particularly China and emerging markets diversifying away from dollar reserves) versus the headwind of elevated real yields. Gold pays no interest, so when Treasury yields are attractive, the opportunity cost of holding gold rises. Recent price action suggests the market is weighing inflation uncertainty against a higher-for-longer rate environment. Gold tends to shine brightest during periods of negative real yields or acute crisis — neither of which is dominant right now, keeping prices in a consolidation range."
    
    private static let qqqSimple = "QQQ is basically a way to own the 100 biggest tech companies at once. When you hear about the 'Magnificent Seven' (Apple, Microsoft, NVIDIA, Amazon, Google, Meta, Tesla) — they're all in there and they dominate the returns. When AI excitement picks up, QQQ rallies. When interest rates go up or growth stocks fall out of favor, QQQ drops. It's more concentrated than most people realize — a few stocks are doing most of the work."
    
    private static let qqqStandard = "QQQ's performance reflects the bifurcated nature of the current market. Mega-cap tech — particularly AI beneficiaries — has driven the lion's share of returns, while the average Nasdaq stock has lagged. This concentration is a double-edged sword: it can boost results when leaders are strong, but it also means QQQ is less diversified than it appears. Duration sensitivity remains a factor — as a growth-heavy index, QQQ is more impacted by changes in rate expectations than the broader market. The AI narrative has supported valuations, and earnings delivery still shapes how that narrative is interpreted."
    
    private static let spySimple = "SPY tracks the S&P 500 — that's 500 of America's biggest companies across all industries. When people talk about 'the market,' this is usually what they mean. Right now, the mood is mixed: inflation has cooled, the economy has held up, and companies are still making money, but there are questions about how long rates stay high and what that means for growth."
    
    private static let spyStandard = "The S&P 500 is navigating a 'soft landing' narrative — where inflation moderates without triggering recession. So far, the economic data has cooperated: employment remains robust, consumer spending is resilient, and corporate earnings have exceeded lowered expectations. However, market breadth tells a more nuanced story — much of the index-level strength has been concentrated in a handful of mega-caps. One path forward is earnings growth broadening out as the Fed eventually eases, while another path focuses on 'higher for longer' rates tightening financial conditions. Valuations are above historical averages but not extreme."
    
    private static let inflationSimple = "Inflation is cooling down, but it's not gone yet. The easy part — bringing down goods prices like TVs and furniture — has happened. The hard part is services and rent, which are still elevated. The Fed wants to see inflation at 2%, and we're not there yet. That's why they're keeping interest rates high. Think of it like a fever that's come down from 103° to 99° — better, but you're not fully healthy yet."
    
    private static let inflationStandard = "Headline inflation has decelerated meaningfully from 2022 peaks, but the 'last mile' to the Fed's 2% target is proving elusive. Core services inflation — particularly shelter/rent — remains sticky, though leading indicators suggest it tends to moderate with a lag. The goods disinflation phase is largely complete as supply chains normalized. The Fed's challenge is calibrating policy: easing too early risks reigniting inflation, while staying too tight risks unnecessary economic damage. Market expectations for rate cuts have repeatedly been pushed back as inflation data has come in hotter than hoped."
    
    private static let defaultSimple = "Markets are in a wait-and-see mode. People are trying to figure out whether inflation will keep falling, whether the economy will stay strong, and what the Fed will do with interest rates. There's optimism about a 'soft landing' — where things cool down without crashing — but nothing is certain. Seeing how the pieces line up can make the picture feel clearer."
    
    private static let defaultStandard = "Current market dynamics reflect a tug-of-war between soft landing optimism and higher-for-longer rate concerns. Economic data has been resilient enough to support risk assets, but not so hot as to force the Fed into further tightening. Earnings have been adequate, with guidance generally holding up. The key variables remain inflation trajectory, Fed policy, and whether employment holds. Markets are priced for a relatively benign outcome — any deviation from that base case could drive volatility."
}

// MARK: - Sources Builder

/// Builds mock source references
private struct SourcesBuilder {
    typealias Source = AIResponse.SourceReference
    typealias SourceType = AIResponse.SourceReference.SourceType
    
    static func build(for normalized: String) -> [Source] {
        if normalized.contains("nvda") || normalized.contains("nvidia") {
            return [
                Source(title: "Q4 earnings beat expectations on data center strength", source: "NVIDIA Investor Relations", type: .filings, summary: "Data center revenue up 400% YoY"),
                Source(title: "AI chip demand continues to outpace supply", source: "Reuters", type: .news, summary: "Major cloud providers increase orders for H100/H200 GPUs"),
                Source(title: "Semiconductor sector analysis: AI infrastructure buildout", source: "Morgan Stanley Research", type: .research, summary: "Upgraded price targets across AI chip makers"),
                Source(title: "Competition heating up in AI accelerators", source: "The Information", type: .analysis, summary: "AMD, Google, Amazon developing alternatives")
            ]
        } else if normalized.contains("oil") {
            return [
                Source(title: "OPEC+ extends production cuts through Q2", source: "Reuters", type: .news, summary: "Saudi Arabia leads efforts to stabilize prices"),
                Source(title: "U.S. crude inventories decline for third week", source: "EIA Weekly Report", type: .filings, summary: "Draws exceed expectations amid refinery maintenance"),
                Source(title: "China oil demand recovery slower than expected", source: "IEA Monthly Report", type: .research, summary: "Property sector weakness weighing on consumption")
            ]
        } else if normalized.contains("gold") {
            return [
                Source(title: "Central bank gold buying hits record levels", source: "World Gold Council", type: .research, summary: "China, Poland, Turkey lead reserve diversification"),
                Source(title: "Real yields and gold: the inverse relationship", source: "Bloomberg", type: .analysis, summary: "Higher Treasury yields create headwinds for non-yielding assets"),
                Source(title: "Gold ETF flows turn positive", source: "State Street", type: .filings, summary: "First monthly inflow in six months")
            ]
        } else if normalized.contains("qqq") {
            return [
                Source(title: "Magnificent Seven drive 80% of YTD returns", source: "Goldman Sachs", type: .research, summary: "Market concentration at multi-decade highs"),
                Source(title: "Tech earnings preview: AI tailwinds in focus", source: "Barron's", type: .analysis, summary: "Investors watching for capex guidance on AI investments"),
                Source(title: "Nasdaq 100 rebalancing reduces concentration", source: "Nasdaq", type: .filings, summary: "Special rebalance to address weight limits")
            ]
        } else if normalized.contains("spy") {
            return [
                Source(title: "S&P 500 earnings growth turns positive", source: "FactSet Earnings Insight", type: .research, summary: "First YoY growth in four quarters"),
                Source(title: "Market breadth improving as rally broadens", source: "Ned Davis Research", type: .analysis, summary: "More stocks participating in advance"),
                Source(title: "Corporate buyback announcements accelerate", source: "S&P Global", type: .filings, summary: "Q1 authorizations exceed $200B")
            ]
        } else if normalized.contains("inflation") {
            return [
                Source(title: "CPI report shows continued disinflation", source: "Bureau of Labor Statistics", type: .filings, summary: "Headline inflation at 3.2%, core at 3.8%"),
                Source(title: "Fed officials signal patience on rate cuts", source: "Federal Reserve", type: .filings, summary: "Need more confidence inflation heading to 2%"),
                Source(title: "Shelter inflation expected to moderate", source: "Zillow Research", type: .research, summary: "Rent growth slowing, but CPI lags")
            ]
        } else {
            return [
                Source(title: "Economic outlook: soft landing still base case", source: "Federal Reserve", type: .research, summary: "Latest economic projections show gradual normalization"),
                Source(title: "Markets Weekly: What to watch", source: "Wall Street Journal", type: .news, summary: "Key data releases and earnings on deck"),
                Source(title: "Asset allocation quarterly update", source: "BlackRock", type: .analysis, summary: "Balanced approach recommended in uncertain environment")
            ]
        }
    }
}
