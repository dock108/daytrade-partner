//
//  AIServiceStub.swift
//  TradeLens
//
//  Stub AI service that returns structured article-style responses.
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

    func structuredResponse(for question: String) -> AIResponse {
        let normalized = question.lowercased()
        var sections: [AIResponse.Section] = []
        
        // Get topic-specific content
        let topicContent = getTopicContent(for: normalized)
        
        // Build sections
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
        
        // Add personalized context if available
        if let personalSection = buildPersonalizedSection(for: normalized) {
            sections.append(personalSection)
        }
        
        return AIResponse(
            query: question,
            sections: sections,
            timestamp: Date()
        )
    }

    // MARK: - Legacy support
    func response(for question: String) -> String {
        let structured = structuredResponse(for: question)
        return structured.sections.map { $0.content }.joined(separator: "\n\n")
    }

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

    // MARK: - Topic Content
    
    private struct TopicContent {
        let current: String
        let driversIntro: String
        let drivers: [String]
        let riskOpportunity: String
        let historical: String
        let recap: String
    }
    
    private func getTopicContent(for normalized: String) -> TopicContent {
        if normalized.contains("nvda") || normalized.contains("nvidia") {
            return TopicContent(
                current: "NVIDIA continues to be at the center of AI infrastructure spending. Recent price action reflects ongoing demand for data center GPUs, though the stock has shown some consolidation after its extended run.",
                driversIntro: "Several factors are influencing NVDA right now:",
                drivers: [
                    "AI capex spending from hyperscalers (Microsoft, Google, Amazon)",
                    "Next-generation chip launches and production ramp",
                    "Competition from AMD and custom silicon",
                    "China export restrictions and regulatory landscape"
                ],
                riskOpportunity: "The opportunity lies in sustained AI infrastructure buildout — if enterprise adoption accelerates, demand could exceed current estimates. The risk is valuation compression if growth decelerates or if competition intensifies faster than expected.",
                historical: "NVIDIA has historically traded at premium multiples during product cycle peaks. The current AI wave resembles the crypto mining surge of 2017–2018, though with broader enterprise adoption this time.",
                recap: "NVDA remains the picks-and-shovels play for AI, but expectations are high. Watch earnings guidance and data center revenue mix for signals."
            )
        }
        
        if normalized.contains("oil") {
            return TopicContent(
                current: "Oil markets are balancing between supply constraints and demand uncertainty. OPEC+ production decisions remain the dominant near-term driver, while China's economic trajectory shapes the demand outlook.",
                driversIntro: "Key factors moving oil prices:",
                drivers: [
                    "OPEC+ production quotas and compliance",
                    "U.S. shale output and rig count trends",
                    "China demand recovery (or slowdown)",
                    "Strategic petroleum reserve levels",
                    "Geopolitical tensions in producing regions"
                ],
                riskOpportunity: "Upside risk includes supply disruptions or stronger-than-expected China demand. Downside risk centers on recession fears dampening global consumption or OPEC+ compliance breaking down.",
                historical: "Oil has cycled between $40–$120 over the past decade, with spikes often tied to geopolitical events. Current prices sit in the middle of that historical range.",
                recap: "Oil remains a macro-sensitive trade. Watch weekly inventory data and OPEC+ meeting outcomes for directional cues."
            )
        }
        
        if normalized.contains("gold") {
            return TopicContent(
                current: "Gold has been supported by central bank buying and safe-haven flows, though higher real yields create headwinds. The metal often moves inversely to the U.S. dollar and Treasury yields.",
                driversIntro: "What's driving gold prices:",
                drivers: [
                    "Real interest rates (nominal rates minus inflation)",
                    "U.S. dollar strength or weakness",
                    "Central bank gold purchases (especially emerging markets)",
                    "Geopolitical uncertainty and risk-off flows",
                    "ETF inflows and outflows"
                ],
                riskOpportunity: "Gold could rally if inflation proves stickier than expected or if the Fed pivots dovish. The risk is that higher-for-longer rates make yield-bearing assets more attractive than non-yielding gold.",
                historical: "Gold tends to perform well during periods of negative real yields and currency debasement concerns. It struggled during 2022 as rates rose sharply, then recovered as peak-rate expectations built.",
                recap: "Gold is a macro hedge, not a momentum trade. Position sizing should reflect its role as portfolio insurance rather than a return driver."
            )
        }
        
        if normalized.contains("qqq") {
            return TopicContent(
                current: "QQQ tracks the Nasdaq-100, heavily weighted toward mega-cap tech. Recent performance reflects optimism around AI tailwinds, though concentration risk remains elevated with the top 10 holdings dominating returns.",
                driversIntro: "Factors shaping QQQ performance:",
                drivers: [
                    "Mega-cap tech earnings (Apple, Microsoft, NVIDIA, etc.)",
                    "Interest rate expectations and duration sensitivity",
                    "AI adoption narratives and capex spending",
                    "Consumer spending trends for discretionary tech",
                    "Sector rotation between growth and value"
                ],
                riskOpportunity: "Upside comes from continued AI monetization and earnings beats. Downside risk includes multiple compression if rates stay elevated or if growth stocks lose momentum leadership.",
                historical: "QQQ tends to outperform during rate-cutting cycles and underperform during tightening. The 2022 drawdown showed how sensitive growth stocks are to discount rate changes.",
                recap: "QQQ is a bet on mega-cap tech leadership. The concentration is a feature when leaders are winning, but amplifies drawdowns when they stumble."
            )
        }
        
        if normalized.contains("spy") {
            return TopicContent(
                current: "SPY represents the broad S&P 500, offering diversified exposure across 11 sectors. Current market tone reflects soft-landing optimism, though breadth has been uneven with mega-caps driving much of the gains.",
                driversIntro: "Key drivers for SPY:",
                drivers: [
                    "Corporate earnings growth and margin trends",
                    "Federal Reserve policy and rate path",
                    "Economic data (jobs, inflation, GDP)",
                    "Sector rotation and market breadth",
                    "Buyback activity and fund flows"
                ],
                riskOpportunity: "Opportunity exists if earnings growth broadens beyond mega-caps. Risk comes from recession, sticky inflation forcing more Fed hikes, or geopolitical shocks.",
                historical: "SPY has returned roughly 10% annually over the long term, with drawdowns of 20%+ occurring roughly once per decade. The index recovered from 2022's bear market faster than average.",
                recap: "SPY is core equity exposure. Watch breadth indicators — when more stocks participate, rallies tend to be more durable."
            )
        }
        
        if normalized.contains("inflation") {
            return TopicContent(
                current: "Inflation has moderated from 2022 peaks but remains above the Fed's 2% target. Shelter costs and services inflation are proving stickier than goods prices, which have normalized.",
                driversIntro: "Components driving inflation:",
                drivers: [
                    "Shelter/rent costs (lagging but significant)",
                    "Wage growth and labor market tightness",
                    "Energy prices and gas costs",
                    "Supply chain normalization",
                    "Services vs goods price dynamics"
                ],
                riskOpportunity: "Disinflation could accelerate if shelter costs finally roll over, creating room for rate cuts. The risk is that services inflation stays sticky, keeping the Fed restrictive longer.",
                historical: "The current inflation cycle is the first since the 1980s where the Fed has had to aggressively hike rates. Historical precedent suggests disinflation can take longer than markets expect.",
                recap: "Watch core PCE (the Fed's preferred measure) and shelter components. The path to 2% matters more than the current level."
            )
        }
        
        if normalized.contains("earnings") || normalized.contains("tech earnings") {
            return TopicContent(
                current: "Earnings season provides quarterly insight into corporate health. Recent quarters have shown resilient margins despite cost pressures, with guidance proving more important than headline beats.",
                driversIntro: "What to watch during earnings:",
                drivers: [
                    "Revenue growth vs estimates",
                    "Margin trends and cost commentary",
                    "Forward guidance and revisions",
                    "Management tone on demand outlook",
                    "Capex and hiring plans"
                ],
                riskOpportunity: "Opportunity arises from estimate beats paired with positive revisions. Risk comes from 'beat and lower' scenarios where companies guide down despite strong quarters.",
                historical: "Historically, stocks move more on guidance than on reported numbers. The market tends to look 6–12 months ahead, so forward commentary drives price action.",
                recap: "Focus on the quality of the beat, not just the magnitude. Sustainable outperformance requires positive revision cycles."
            )
        }
        
        // Default/generic response
        return TopicContent(
            current: "Market conditions are shaped by the interplay of earnings, economic data, and Fed policy. Current sentiment reflects uncertainty about the growth trajectory and rate path.",
            driversIntro: "General market drivers to consider:",
            drivers: [
                "Federal Reserve policy and rate expectations",
                "Corporate earnings and guidance trends",
                "Economic indicators (employment, inflation, GDP)",
                "Geopolitical developments",
                "Technical levels and investor positioning"
            ],
            riskOpportunity: "Opportunities emerge when sentiment overshoots in either direction. Risks include unexpected policy changes, earnings disappointments, or macro shocks.",
            historical: "Markets have historically recovered from corrections, though timing varies. Patience and diversification tend to be rewarded over full cycles.",
            recap: "Try asking about specific topics like NVDA, oil, gold, QQQ, SPY, inflation, or earnings for more detailed context."
        )
    }
    
    // MARK: - Personalized Section
    
    private func buildPersonalizedSection(for normalized: String) -> AIResponse.Section? {
        guard let summary else { return nil }
        
        var points: [String] = []
        
        let winRate = CurrencyFormatter.formatPercentage(summary.winRate)
        let avgHoldDays = Int(summary.avgHoldDays.rounded())
        let pnl = CurrencyFormatter.formatUSD(summary.realizedPnLTotal)
        
        points.append("You have \(summary.totalTrades) closed trades with a \(winRate) win rate")
        points.append("Average hold period: \(avgHoldDays) days")
        points.append("Total realized P/L: \(pnl)")
        
        if let bestTicker = summary.bestTicker {
            points.append("Strongest performer: \(bestTicker)")
        }
        
        if let worstTicker = summary.worstTicker {
            points.append("Weakest performer: \(worstTicker)")
        }
        
        // Add relevant insight
        let holdingInsight = insights.first { $0.title == "Holding Range" }
        if let holdingInsight {
            points.append(holdingInsight.detail)
        }
        
        return AIResponse.Section(
            type: .yourContext,
            content: "Based on your trading history, here's how this topic relates to your activity:",
            bulletPoints: points
        )
    }
}
