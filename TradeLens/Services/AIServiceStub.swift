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
        let isSimpleMode = UserSettings.shared.isSimpleModeEnabled
        var sections: [AIResponse.Section] = []
        
        // Get topic-specific content (simple or standard)
        let topicContent = isSimpleMode 
            ? getSimpleTopicContent(for: normalized)
            : getTopicContent(for: normalized)
        
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
        
        // Add "Here's the story in simple terms" digest section
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
    
    // MARK: - Simple Mode Content
    
    private func getSimpleTopicContent(for normalized: String) -> TopicContent {
        if normalized.contains("nvda") || normalized.contains("nvidia") {
            return TopicContent(
                current: "NVIDIA makes the computer chips that power AI. Think of them as selling the pickaxes during a gold rush — everyone building AI needs their products. The stock price has been going up a lot because of this.",
                driversIntro: "Here's what affects the stock price:",
                drivers: [
                    "Big tech companies buying their AI chips",
                    "New, faster chips coming out",
                    "Other companies trying to compete",
                    "Rules about selling to China"
                ],
                riskOpportunity: "The good news: AI is growing fast and NVIDIA is the leader. The risk: The stock is already expensive. If growth slows down, the price could drop. It's like buying a house at the top of the market.",
                historical: "NVIDIA has had big price swings before. During the crypto craze, it shot up and then fell. This AI boom feels bigger, but nothing goes up forever.",
                recap: "NVIDIA is the main company powering AI. Great business, but the price already reflects a lot of good news."
            )
        }
        
        if normalized.contains("oil") {
            return TopicContent(
                current: "Oil prices go up and down based on supply (how much is being pumped) and demand (how much people are using). Right now, it's a tug of war between countries limiting production and worries about the economy.",
                driversIntro: "What moves oil prices:",
                drivers: [
                    "OPEC countries deciding to pump more or less",
                    "How much oil the U.S. is producing",
                    "Whether China's economy is growing",
                    "World events and conflicts"
                ],
                riskOpportunity: "Prices could go up if there's a supply problem or if China starts using more oil. Prices could fall if people worry about a recession. Think of it like any product — price depends on supply and demand.",
                historical: "Oil has bounced between $40 and $120 per barrel over the past 10 years. It moves around a lot based on world events.",
                recap: "Oil prices are hard to predict. They depend on global events, not just company performance."
            )
        }
        
        if normalized.contains("gold") {
            return TopicContent(
                current: "Gold is often called a 'safe haven' — people buy it when they're nervous about the economy. It's like keeping cash under the mattress, but shinier. Right now, some countries are buying gold as a backup.",
                driversIntro: "What affects gold prices:",
                drivers: [
                    "Interest rates — when rates are high, gold is less attractive",
                    "The value of the U.S. dollar",
                    "Countries buying gold as a reserve",
                    "General nervousness in markets"
                ],
                riskOpportunity: "Gold could go up if inflation stays high or if there's a crisis. It might stay flat or drop if interest rates stay high, since bonds then pay better returns. Gold doesn't pay dividends — you only make money if the price goes up.",
                historical: "Gold tends to do well when people are scared and poorly when everything seems fine. It's insurance for your portfolio, not a way to get rich.",
                recap: "Think of gold as financial insurance. It protects against bad times but won't grow like stocks in good times."
            )
        }
        
        if normalized.contains("qqq") {
            return TopicContent(
                current: "QQQ is like buying a basket of the 100 biggest tech companies at once. Apple, Microsoft, NVIDIA, and others are all in there. When tech does well, QQQ does well. When tech struggles, so does QQQ.",
                driversIntro: "What moves QQQ:",
                drivers: [
                    "How the big tech companies are doing",
                    "Interest rates (higher rates hurt tech stocks more)",
                    "Excitement about AI",
                    "Whether people are spending on tech products"
                ],
                riskOpportunity: "QQQ can grow faster than the overall market when tech is hot. But it can also fall harder. It's like betting on the star players — great when they're winning, rough when they're not.",
                historical: "In 2022, QQQ dropped about 30% when interest rates went up. Then it bounced back strongly. It's more of a rollercoaster than the broader market.",
                recap: "QQQ is a way to invest in big tech companies all at once. Higher potential reward, but also more ups and downs."
            )
        }
        
        if normalized.contains("spy") {
            return TopicContent(
                current: "SPY is like buying a tiny piece of 500 of America's biggest companies at once. It's one of the most popular ways to invest in the stock market. When you hear 'the market is up,' they usually mean something like SPY.",
                driversIntro: "What moves SPY:",
                drivers: [
                    "How well companies are doing overall",
                    "What the Federal Reserve does with interest rates",
                    "Jobs and economic news",
                    "General mood of investors"
                ],
                riskOpportunity: "SPY tends to go up over time — historically about 10% per year on average. But it can drop 20% or more during bad times. It's like the tide — it goes in and out, but the long-term trend is up.",
                historical: "SPY has recovered from every downturn in history, though sometimes it takes a few years. The 2022 drop was about 20%, and it's since recovered.",
                recap: "SPY is a simple way to invest in the overall U.S. stock market. Steady and reliable over the long term."
            )
        }
        
        if normalized.contains("inflation") {
            return TopicContent(
                current: "Inflation means prices are going up — your groceries, rent, gas cost more. It went crazy in 2022-2023 but has been calming down. The Fed is trying to get it back to 'normal' (about 2% per year).",
                driversIntro: "What causes inflation:",
                drivers: [
                    "Rent and housing costs (a big chunk)",
                    "Wages going up",
                    "Gas and energy prices",
                    "Supply chain issues getting better or worse"
                ],
                riskOpportunity: "If inflation drops, the Fed might lower interest rates, which is usually good for stocks. If inflation stays stubborn, rates stay high, which can slow the economy. It's like a thermostat — too hot or too cold causes problems.",
                historical: "This is the worst inflation since the 1980s. Back then, it took a painful recession to fix it. This time, we're hoping for a 'soft landing' where inflation falls without a big recession.",
                recap: "Inflation is cooling down but not gone yet. Keep an eye on rent and service prices — they're the sticky parts."
            )
        }
        
        if normalized.contains("earnings") || normalized.contains("tech earnings") {
            return TopicContent(
                current: "Earnings season is when companies report their grades — how much money they made. It happens every 3 months. What companies say about the future often matters more than the numbers themselves.",
                driversIntro: "What to listen for:",
                drivers: [
                    "Did they make more money than expected?",
                    "Are profit margins (how much they keep) growing?",
                    "What do they say about next quarter?",
                    "Are they hiring or cutting costs?"
                ],
                riskOpportunity: "Good earnings + positive outlook = stock usually goes up. Good earnings + worried outlook = stock might still fall. It's like report cards — straight A's matter less if the teacher says you're struggling.",
                historical: "Stock prices often move more on the outlook than the actual numbers. Companies that 'beat and raise' (good results + better forecast) usually do best.",
                recap: "Focus on what companies say about the future, not just their past results."
            )
        }
        
        // Default/generic simple response
        return TopicContent(
            current: "The stock market moves based on how companies are doing, the economy, and what people think will happen next. Right now, there's some uncertainty about where things are headed.",
            driversIntro: "Things that move the market:",
            drivers: [
                "What the Federal Reserve does with interest rates",
                "How well companies are doing",
                "Jobs and economic numbers",
                "Big world events"
            ],
            riskOpportunity: "Markets go up and down. Over the long term, they've always gone up, but there can be rough patches. Staying invested usually beats trying to time the market. It's like weather — storms come and go.",
            historical: "The stock market has recovered from every crash in history. Sometimes it takes months, sometimes years, but patience has been rewarded.",
            recap: "Try asking about specific things like NVDA, oil, gold, QQQ, SPY, or inflation for more helpful answers."
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
            points.append("You make money on about \(winRate) of your trades")
            points.append("You typically hold for \(avgHoldDays) days")
            points.append("Your total profit/loss: \(pnl)")
        } else {
            points.append("You have \(summary.totalTrades) closed trades with a \(winRate) win rate")
            points.append("Average hold period: \(avgHoldDays) days")
            points.append("Total realized P/L: \(pnl)")
        }
        
        if let bestTicker = summary.bestTicker {
            points.append(simple ? "Your best stock: \(bestTicker)" : "Strongest performer: \(bestTicker)")
        }
        
        if let worstTicker = summary.worstTicker {
            points.append(simple ? "Your toughest stock: \(worstTicker)" : "Weakest performer: \(worstTicker)")
        }
        
        // Add relevant insight
        let holdingInsight = insights.first { $0.title == "Holding Range" }
        if let holdingInsight {
            points.append(holdingInsight.detail)
        }
        
        let intro = simple 
            ? "Here's a quick look at your trading:"
            : "Based on your trading history, here's how this topic relates to your activity:"
        
        return AIResponse.Section(
            type: .yourContext,
            content: intro,
            bulletPoints: points
        )
    }
    
    // MARK: - Personal Note (Subtle, Contextual)
    
    /// Generates a subtle personal observation when relevant to the topic.
    /// Returns nil if no relevant insight is available — notes are optional.
    private func buildPersonalNote(for normalized: String, simple: Bool = false) -> AIResponse.Section? {
        guard let summary else { return nil }
        
        // Analyze trading patterns
        let trades = (try? tradeService.getCachedTrades()) ?? []
        guard trades.count >= 5 else { return nil } // Need enough data
        
        // Determine asset type patterns
        let etfTickers = Set(["QQQ", "SPY", "IWM", "DIA", "ARKK", "VTI", "VOO", "XLE", "XLF", "GLD", "SLV", "USO"])
        let etfTrades = trades.filter { etfTickers.contains($0.ticker.uppercased()) }
        let stockTrades = trades.filter { !etfTickers.contains($0.ticker.uppercased()) }
        
        let etfWins = etfTrades.filter { $0.realizedPnL > 0 }.count
        let stockWins = stockTrades.filter { $0.realizedPnL > 0 }.count
        
        let etfWinRate = etfTrades.isEmpty ? 0 : Double(etfWins) / Double(etfTrades.count)
        let stockWinRate = stockTrades.isEmpty ? 0 : Double(stockWins) / Double(stockTrades.count)
        
        // Calculate volatility behavior
        let volatileTrades = trades.filter { abs($0.returnPct) > 0.10 } // 10%+ swings
        let volatileWins = volatileTrades.filter { $0.realizedPnL > 0 }.count
        let volatileWinRate = volatileTrades.isEmpty ? 0 : Double(volatileWins) / Double(volatileTrades.count)
        
        // Holding period patterns
        let quickExits = trades.filter { $0.holdingDays <= 3 }
        let quickExitWins = quickExits.filter { $0.realizedPnL > 0 }.count
        let quickExitWinRate = quickExits.isEmpty ? 0 : Double(quickExitWins) / Double(quickExits.count)
        
        let longerHolds = trades.filter { $0.holdingDays > 7 }
        let longerHoldWins = longerHolds.filter { $0.realizedPnL > 0 }.count
        let longerHoldWinRate = longerHolds.isEmpty ? 0 : Double(longerHoldWins) / Double(longerHolds.count)
        
        // Generate contextual note based on topic
        var note: String? = nil
        
        // ETF topics (QQQ, SPY, etc.)
        if normalized.contains("qqq") || normalized.contains("spy") || normalized.contains("etf") {
            if etfTrades.count >= 3 && etfWinRate > stockWinRate + 0.15 {
                note = simple
                    ? "You've done better with ETFs than single stocks — about \(Int(etfWinRate * 100))% wins vs \(Int(stockWinRate * 100))%."
                    : "Historically, you've shown stronger results with ETFs (\(Int(etfWinRate * 100))% win rate) than individual stocks (\(Int(stockWinRate * 100))%)."
            } else if etfTrades.count >= 3 && stockWinRate > etfWinRate + 0.10 {
                note = simple
                    ? "You've actually done better picking individual stocks than trading ETFs."
                    : "Your track record shows stronger performance with individual stocks vs broad ETFs — something to consider."
            }
        }
        
        // Volatility-related topics (NVDA, oil, etc.)
        if normalized.contains("nvda") || normalized.contains("nvidia") || normalized.contains("oil") || normalized.contains("volatile") {
            if volatileTrades.count >= 3 {
                if volatileWinRate < summary.winRate - 0.15 {
                    note = simple
                        ? "Quick observation: volatile swings haven't been your best trades — maybe size down on these."
                        : "Worth noting: your win rate on high-volatility moves (\(Int(volatileWinRate * 100))%) is below your overall average — something to watch."
                } else if volatileWinRate > summary.winRate + 0.10 {
                    note = simple
                        ? "Interestingly, you've handled volatile moves better than average."
                        : "You've historically navigated volatility well, with a \(Int(volatileWinRate * 100))% win rate on higher-swing trades."
                }
            }
        }
        
        // Holding period patterns
        if normalized.contains("hold") || normalized.contains("timing") || normalized.contains("exit") || normalized.contains("sell") {
            if quickExits.count >= 3 && longerHolds.count >= 3 {
                if longerHoldWinRate > quickExitWinRate + 0.15 {
                    note = simple
                        ? "Patience has paid off for you — longer holds tend to work better than quick exits."
                        : "Your data suggests patience pays: trades held 7+ days have a \(Int(longerHoldWinRate * 100))% win rate vs \(Int(quickExitWinRate * 100))% for quick exits."
                } else if quickExitWinRate > longerHoldWinRate + 0.10 {
                    note = simple
                        ? "Quick trades have actually worked well for you — maybe you read momentum well."
                        : "Interestingly, your shorter-duration trades have performed better — possibly a sign of good momentum reads."
                }
            }
        }
        
        // Tech/growth topics
        if normalized.contains("tech") || normalized.contains("growth") || normalized.contains("ai") {
            let techTickers = Set(["NVDA", "AAPL", "MSFT", "GOOGL", "GOOG", "AMZN", "META", "TSLA", "AMD", "INTC", "CRM", "ADBE"])
            let techTrades = trades.filter { techTickers.contains($0.ticker.uppercased()) }
            let techWins = techTrades.filter { $0.realizedPnL > 0 }.count
            let techWinRate = techTrades.isEmpty ? 0 : Double(techWins) / Double(techTrades.count)
            
            if techTrades.count >= 3 {
                let otherTrades = trades.filter { !techTickers.contains($0.ticker.uppercased()) }
                let otherWins = otherTrades.filter { $0.realizedPnL > 0 }.count
                let otherWinRate = otherTrades.isEmpty ? 0 : Double(otherWins) / Double(otherTrades.count)
                
                if techWinRate > otherWinRate + 0.12 {
                    note = simple
                        ? "Good news: tech has been one of your stronger areas."
                        : "Tech names have been a relative strength in your portfolio — \(Int(techWinRate * 100))% win rate."
                } else if otherWinRate > techWinRate + 0.12 {
                    note = simple
                        ? "Just a thought: non-tech trades have worked better for you historically."
                        : "Worth considering: your non-tech trades have outperformed tech names historically."
                }
            }
        }
        
        // Early exit pattern (general)
        if note == nil && quickExits.count >= 5 {
            let avgQuickGain = quickExits.reduce(0.0) { $0 + $1.realizedPnL } / Double(quickExits.count)
            let avgLongerGain = longerHolds.isEmpty ? 0 : longerHolds.reduce(0.0) { $0 + $1.realizedPnL } / Double(longerHolds.count)
            
            if avgLongerGain > avgQuickGain * 1.5 && longerHolds.count >= 3 {
                note = simple
                    ? "You tend to exit early during volatile swings — holding longer has worked better for you."
                    : "Pattern: your quick exits during volatility tend to underperform your longer holds — something to watch."
            }
        }
        
        // Only return if we have a relevant note
        guard let personalNote = note else { return nil }
        
        return AIResponse.Section(
            type: .personalNote,
            content: personalNote
        )
    }
    
    // MARK: - Digest Section (Human-Readable Summary)
    
    private func buildDigestSection(for normalized: String, simple: Bool) -> String {
        // Create a cohesive narrative that reads like a human explanation
        // This synthesizes the news + drivers without just listing headlines
        
        if normalized.contains("nvda") || normalized.contains("nvidia") {
            if simple {
                return "Here's what's going on: NVIDIA is the company making the brains behind AI. Every time you hear about ChatGPT or AI assistants getting smarter, NVIDIA's chips are usually powering it. Big tech companies are spending billions to buy their products. The stock has gone way up because of this — but that also means a lot of good news is already baked into the price. It's like buying a house in a hot neighborhood: great location, but you're paying top dollar."
            } else {
                return "The AI infrastructure buildout has positioned NVIDIA as the de facto supplier of compute power for the industry's largest players. Microsoft, Google, Amazon, and Meta are all racing to scale their AI capabilities, and NVIDIA's H100/H200 chips are the currency of that race. Recent earnings have consistently beaten expectations, driven by data center revenue that now dwarfs gaming. However, the market has priced in substantial future growth — current multiples assume sustained hypergrowth that leaves little room for disappointment. Competition from AMD and custom silicon (Google's TPUs, Amazon's Trainium) represents a longer-term variable."
            }
        }
        
        if normalized.contains("oil") {
            if simple {
                return "Oil prices are like a tug of war right now. On one side, countries that produce oil (OPEC) are trying to limit supply to keep prices up. On the other side, people are worried about the economy slowing down, which would mean less demand for oil. China's economy is a big question mark — if they use more oil, prices go up; if their economy stays sluggish, prices stay flat or drop. It's not really about any one company, it's about global supply and demand."
            } else {
                return "Crude oil markets are navigating a complex supply-demand dynamic. OPEC+ continues to manage production cuts aimed at supporting prices, while U.S. shale production has proven more resilient than expected. The demand side hinges heavily on China's economic trajectory — a meaningful recovery would tighten balances, while continued weakness keeps a lid on prices. Geopolitical risk premiums can spike suddenly (Middle East tensions, Russian supply disruptions), but have tended to fade unless actual supply is affected. The macro backdrop — recession risks vs. soft landing — will likely determine direction more than any single catalyst."
            }
        }
        
        if normalized.contains("gold") {
            if simple {
                return "Gold is behaving like it usually does — it's the thing people buy when they're nervous. Central banks around the world, especially in Asia, have been stockpiling gold as a hedge against uncertainty. But here's the catch: when interest rates are high, bonds and savings accounts pay you a return, while gold just sits there. So gold has been range-bound — up when fears spike, flat when rates dominate the conversation."
            } else {
                return "The gold market is responding to competing forces: safe-haven demand from central banks (particularly China and emerging markets diversifying away from dollar reserves) versus the headwind of elevated real yields. Gold pays no interest, so when Treasury yields are attractive, the opportunity cost of holding gold rises. Recent price action suggests the market is weighing inflation uncertainty against a higher-for-longer rate environment. Gold tends to shine brightest during periods of negative real yields or acute crisis — neither of which is dominant right now, keeping prices in a consolidation range."
            }
        }
        
        if normalized.contains("qqq") {
            if simple {
                return "QQQ is basically a way to own the 100 biggest tech companies at once. When you hear about the 'Magnificent Seven' (Apple, Microsoft, NVIDIA, Amazon, Google, Meta, Tesla) — they're all in there and they dominate the returns. When AI excitement picks up, QQQ rallies. When interest rates go up or growth stocks fall out of favor, QQQ drops. It's more concentrated than most people realize — a few stocks are doing most of the work."
            } else {
                return "QQQ's performance reflects the bifurcated nature of the current market. Mega-cap tech — particularly AI beneficiaries — has driven the lion's share of returns, while the average Nasdaq stock has lagged. This concentration is a double-edged sword: leadership by the strongest companies is bullish, but it also means QQQ is less diversified than it appears. Duration sensitivity remains a factor — as a growth-heavy index, QQQ is more impacted by changes in rate expectations than the broader market. The AI narrative has provided cover for valuations, but earnings delivery will need to validate multiples."
            }
        }
        
        if normalized.contains("spy") {
            if simple {
                return "SPY tracks the S&P 500 — that's 500 of America's biggest companies across all industries. When people talk about 'the market,' this is usually what they mean. Right now, the mood is cautiously optimistic. Inflation is cooling, the economy hasn't crashed, and companies are still making money. But there's worry about whether rates will stay high for longer and what that might mean for the economy. It's not wildly expensive, but it's not cheap either."
            } else {
                return "The S&P 500 is navigating a 'soft landing' narrative — where inflation moderates without triggering recession. So far, the economic data has cooperated: employment remains robust, consumer spending is resilient, and corporate earnings have exceeded lowered expectations. However, market breadth tells a more nuanced story — much of the index-level strength has been concentrated in a handful of mega-caps. The bull case rests on earnings growth broadening out as the Fed eventually eases. The bear case worries about 'higher for longer' rates eventually breaking something in the economy. Valuations are above historical averages but not extreme."
            }
        }
        
        if normalized.contains("inflation") {
            if simple {
                return "Inflation is cooling down, but it's not gone yet. The easy part — bringing down goods prices like TVs and furniture — has happened. The hard part is services and rent, which are still elevated. The Fed wants to see inflation at 2%, and we're not there yet. That's why they're keeping interest rates high. Think of it like a fever that's come down from 103° to 99° — better, but you're not fully healthy yet."
            } else {
                return "Headline inflation has decelerated meaningfully from 2022 peaks, but the 'last mile' to the Fed's 2% target is proving elusive. Core services inflation — particularly shelter/rent — remains sticky, though leading indicators suggest it should moderate with a lag. The goods disinflation phase is largely complete as supply chains normalized. The Fed's challenge is calibrating policy: easing too early risks reigniting inflation, while staying too tight risks unnecessary economic damage. Market expectations for rate cuts have repeatedly been pushed back as inflation data has come in hotter than hoped."
            }
        }
        
        // Default digest
        if simple {
            return "Markets are in a wait-and-see mode. People are trying to figure out whether inflation will keep falling, whether the economy will stay strong, and what the Fed will do with interest rates. There's optimism that we'll get a 'soft landing' — where things cool down without crashing — but nothing is certain. The best approach is to stay informed and not make big bets on predictions."
        } else {
            return "Market conditions reflect an ongoing recalibration of expectations. The prevailing narrative favors a soft landing, but conviction is low given the cross-currents: sticky services inflation, resilient employment, and elevated but normalizing rates. Earnings have been the bright spot, providing fundamental support for prices even as valuation multiples have expanded. The key variables to monitor are the pace of disinflation, the health of the consumer, and any signs of credit stress. For specific insights, try asking about individual topics like NVDA, oil, gold, SPY, QQQ, or inflation."
        }
    }
    
    // MARK: - Sources (Placeholder Content)
    
    private func buildSources(for normalized: String) -> [AIResponse.SourceReference] {
        var sources: [AIResponse.SourceReference] = []
        
        if normalized.contains("nvda") || normalized.contains("nvidia") {
            sources = [
                AIResponse.SourceReference(
                    title: "Data Center Revenue Drives Record Quarter",
                    source: "Earnings Release, Nov 2024",
                    type: .filings,
                    summary: "Q3 revenue beat estimates by 12%, with data center up 279% YoY"
                ),
                AIResponse.SourceReference(
                    title: "AI Capex Spending Outlook",
                    source: "Industry Analysis",
                    type: .research,
                    summary: "Hyperscaler capex expected to grow 25-30% in 2025"
                ),
                AIResponse.SourceReference(
                    title: "New Chip Architecture Ahead of Schedule",
                    source: "Tech News",
                    type: .news,
                    summary: "Blackwell GPU production ramping faster than expected"
                ),
                AIResponse.SourceReference(
                    title: "Competition Landscape: AMD and Custom Silicon",
                    source: "Market Analysis",
                    type: .analysis,
                    summary: "Alternatives emerging but NVIDIA maintains 80%+ market share"
                )
            ]
        } else if normalized.contains("oil") {
            sources = [
                AIResponse.SourceReference(
                    title: "OPEC+ Extends Production Cuts",
                    source: "Energy News",
                    type: .news,
                    summary: "Supply cuts extended through Q2 2025 to support prices"
                ),
                AIResponse.SourceReference(
                    title: "Weekly Inventory Report",
                    source: "EIA Data",
                    type: .filings,
                    summary: "U.S. crude inventories drew down more than expected"
                ),
                AIResponse.SourceReference(
                    title: "China Demand Signals Mixed",
                    source: "Asia Economics",
                    type: .research,
                    summary: "Refinery runs up but end-user demand remains subdued"
                )
            ]
        } else if normalized.contains("gold") {
            sources = [
                AIResponse.SourceReference(
                    title: "Central Bank Buying Hits Record",
                    source: "World Gold Council",
                    type: .research,
                    summary: "EM central banks added 800+ tonnes in 2024"
                ),
                AIResponse.SourceReference(
                    title: "Real Yields and Gold Correlation",
                    source: "Macro Analysis",
                    type: .analysis,
                    summary: "Historical relationship suggests upside if Fed pivots"
                ),
                AIResponse.SourceReference(
                    title: "ETF Flows Turn Positive",
                    source: "Fund Flows Data",
                    type: .filings,
                    summary: "First net inflows to gold ETFs in 18 months"
                )
            ]
        } else if normalized.contains("qqq") {
            sources = [
                AIResponse.SourceReference(
                    title: "Mega-Cap Tech Dominates Returns",
                    source: "Index Analysis",
                    type: .analysis,
                    summary: "Top 7 holdings account for 45% of QQQ weight"
                ),
                AIResponse.SourceReference(
                    title: "AI Revenue Monetization Tracking",
                    source: "Tech Research",
                    type: .research,
                    summary: "Cloud AI services growing 40%+ at major providers"
                ),
                AIResponse.SourceReference(
                    title: "Rate Sensitivity Analysis",
                    source: "Quant Research",
                    type: .analysis,
                    summary: "QQQ duration ~3x higher than value indices"
                )
            ]
        } else if normalized.contains("spy") {
            sources = [
                AIResponse.SourceReference(
                    title: "Earnings Season Recap",
                    source: "Market Summary",
                    type: .analysis,
                    summary: "78% of S&P 500 beat estimates, but guidance mixed"
                ),
                AIResponse.SourceReference(
                    title: "Breadth Indicators Improve",
                    source: "Technical Analysis",
                    type: .research,
                    summary: "Advance-decline line turning up after narrow rally"
                ),
                AIResponse.SourceReference(
                    title: "Buyback Activity Elevated",
                    source: "Corporate Actions",
                    type: .filings,
                    summary: "Q4 buybacks on pace for $250B+ record"
                )
            ]
        } else if normalized.contains("inflation") {
            sources = [
                AIResponse.SourceReference(
                    title: "Core PCE Comes in Hot",
                    source: "Economic Data",
                    type: .filings,
                    summary: "November reading at 0.3% MoM, above 0.2% consensus"
                ),
                AIResponse.SourceReference(
                    title: "Shelter Inflation Decomposition",
                    source: "Economic Research",
                    type: .research,
                    summary: "Rent and OER expected to moderate with 6-12 month lag"
                ),
                AIResponse.SourceReference(
                    title: "Fed Minutes: Higher for Longer",
                    source: "Policy Documents",
                    type: .filings,
                    summary: "Committee sees no rush to cut while inflation persists"
                )
            ]
        } else {
            // Generic sources
            sources = [
                AIResponse.SourceReference(
                    title: "Market Overview: December 2024",
                    source: "Weekly Summary",
                    type: .analysis,
                    summary: "S&P 500 consolidating near highs ahead of Fed"
                ),
                AIResponse.SourceReference(
                    title: "Economic Calendar Highlights",
                    source: "Data Preview",
                    type: .research,
                    summary: "Jobs report and CPI on deck for next week"
                ),
                AIResponse.SourceReference(
                    title: "Fund Flow Trends",
                    source: "Flow Data",
                    type: .filings,
                    summary: "Equity funds seeing consistent inflows, bonds mixed"
                )
            ]
        }
        
        return sources
    }
}
