//
//  AIContentProvider.swift
//  TradeLens
//
//  Provides topic-specific content for AI responses.
//  Extracted from AIServiceStub to reduce file size and separate concerns.
//

import Foundation

/// Content structure for topic-based AI responses
struct TopicContent {
    let current: String
    let driversIntro: String
    let drivers: [String]
    let riskOpportunity: String
    let historical: String
    let recap: String
}

/// Provides content for AI responses based on topic detection
struct AIContentProvider {
    
    // MARK: - Standard Content
    
    static func getContent(for normalized: String) -> TopicContent {
        if normalized.contains("nvda") || normalized.contains("nvidia") {
            return nvidiaContent
        }
        if normalized.contains("oil") {
            return oilContent
        }
        if normalized.contains("gold") {
            return goldContent
        }
        if normalized.contains("qqq") {
            return qqqContent
        }
        if normalized.contains("spy") {
            return spyContent
        }
        if normalized.contains("inflation") {
            return inflationContent
        }
        if normalized.contains("earnings") || normalized.contains("tech earnings") {
            return earningsContent
        }
        return defaultContent
    }
    
    // MARK: - Simple Mode Content
    
    static func getSimpleContent(for normalized: String) -> TopicContent {
        if normalized.contains("nvda") || normalized.contains("nvidia") {
            return nvidiaSimple
        }
        if normalized.contains("oil") {
            return oilSimple
        }
        if normalized.contains("gold") {
            return goldSimple
        }
        if normalized.contains("qqq") {
            return qqqSimple
        }
        if normalized.contains("spy") {
            return spySimple
        }
        if normalized.contains("inflation") {
            return inflationSimple
        }
        if normalized.contains("earnings") || normalized.contains("tech earnings") {
            return earningsSimple
        }
        return defaultSimple
    }
    
    // MARK: - Standard Topic Content
    
    private static let nvidiaContent = TopicContent(
        current: "NVIDIA sits at the center of AI infrastructure spending. Recent price action has reflected ongoing demand for data center GPUs, with some consolidation after its extended run.",
        driversIntro: "Several factors are influencing NVDA right now:",
        drivers: [
            "AI capex spending from hyperscalers (Microsoft, Google, Amazon)",
            "Next-generation chip launches and production ramp",
            "Competition from AMD and custom silicon",
            "China export restrictions and regulatory landscape"
        ],
        riskOpportunity: "A constructive read comes from sustained AI infrastructure buildout, while valuation sensitivity can show up if growth expectations cool or competition intensifies.",
        historical: "NVIDIA has often traded at premium multiples during product cycle peaks. The current AI wave echoes the 2017–2018 crypto mining surge, but with broader enterprise adoption in the mix.",
        recap: "NVDA is a key AI infrastructure name, and expectations are high. Earnings guidance and data center revenue mix often shape how the story is interpreted."
    )
    
    private static let oilContent = TopicContent(
        current: "Oil markets are balancing between supply constraints and demand uncertainty. OPEC+ production decisions remain the dominant near-term driver, while China's economic trajectory shapes the demand outlook.",
        driversIntro: "Key factors moving oil prices:",
        drivers: [
            "OPEC+ production quotas and compliance",
            "U.S. shale output and rig count trends",
            "China demand recovery (or slowdown)",
            "Strategic petroleum reserve levels",
            "Geopolitical tensions in producing regions"
        ],
        riskOpportunity: "Prices can react quickly to supply disruptions, demand surprises, or compliance shifts, so sentiment can swing in either direction.",
        historical: "Oil has cycled between $40–$120 over the past decade, with spikes often tied to geopolitical events. Current prices sit in the middle of that historical range.",
        recap: "Oil remains macro-sensitive. Weekly inventory data and OPEC+ meeting outcomes often explain near-term moves."
    )
    
    private static let goldContent = TopicContent(
        current: "Gold has been supported by central bank buying and safe-haven flows, though higher real yields create headwinds. The metal often moves inversely to the U.S. dollar and Treasury yields.",
        driversIntro: "What's driving gold prices:",
        drivers: [
            "Real interest rates (nominal rates minus inflation)",
            "U.S. dollar strength or weakness",
            "Central bank gold purchases (especially emerging markets)",
            "Geopolitical uncertainty and risk-off flows",
            "ETF inflows and outflows"
        ],
        riskOpportunity: "Gold can respond to inflation surprises or policy shifts, while higher real yields tend to be a headwind for non-yielding assets.",
        historical: "Gold tends to perform well during periods of negative real yields and currency debasement concerns. It struggled during 2022 as rates rose sharply, then recovered as peak-rate expectations built.",
        recap: "Gold is often treated as a macro hedge. Its moves are usually tied to rates, the dollar, and risk sentiment."
    )
    
    private static let qqqContent = TopicContent(
        current: "QQQ tracks the Nasdaq-100, heavily weighted toward mega-cap tech. Recent performance reflects optimism around AI tailwinds, though concentration risk remains elevated with the top 10 holdings dominating returns.",
        driversIntro: "Factors shaping QQQ performance:",
        drivers: [
            "Mega-cap tech earnings (Apple, Microsoft, NVIDIA, etc.)",
            "Interest rate expectations and duration sensitivity",
            "AI adoption narratives and capex spending",
            "Consumer spending trends for discretionary tech",
            "Sector rotation between growth and value"
        ],
        riskOpportunity: "QQQ tends to react to AI narratives and rate expectations, and concentration can amplify moves in either direction.",
        historical: "QQQ tends to outperform during rate-cutting cycles and underperform during tightening. The 2022 drawdown showed how sensitive growth stocks are to discount rate changes.",
        recap: "QQQ reflects mega-cap tech leadership. Concentration can help or hurt depending on how those leaders are trading."
    )
    
    private static let spyContent = TopicContent(
        current: "SPY represents the broad S&P 500, offering diversified exposure across 11 sectors. Current market tone reflects soft-landing optimism, though breadth has been uneven with mega-caps driving much of the gains.",
        driversIntro: "Key drivers for SPY:",
        drivers: [
            "Corporate earnings growth and margin trends",
            "Federal Reserve policy and rate path",
            "Economic data (jobs, inflation, GDP)",
            "Sector rotation and market breadth",
            "Buyback activity and fund flows"
        ],
        riskOpportunity: "Sentiment often improves when earnings strength broadens beyond mega-caps. Risks include recession, sticky inflation, or geopolitical shocks that can reset expectations.",
        historical: "Historically, the S&P 500 has averaged roughly 10% annual returns over long periods, with 20%+ drawdowns appearing from time to time.",
        recap: "SPY is a broad equity barometer. Breadth indicators can help explain whether rallies feel durable."
    )
    
    private static let inflationContent = TopicContent(
        current: "Inflation has moderated from 2022 peaks but remains above the Fed's 2% target. Shelter costs and services inflation are proving stickier than goods prices, which have normalized.",
        driversIntro: "Components driving inflation:",
        drivers: [
            "Shelter/rent costs (lagging but significant)",
            "Wage growth and labor market tightness",
            "Energy prices and gas costs",
            "Supply chain normalization",
            "Services vs goods price dynamics"
        ],
        riskOpportunity: "Inflation can cool faster if shelter costs roll over, while sticky services inflation can keep policy restrictive for longer.",
        historical: "The current inflation cycle is the first since the 1980s where the Fed has had to aggressively hike rates. Historical precedent suggests disinflation can take longer than markets expect.",
        recap: "Core PCE and shelter components often explain the 'last mile' story as inflation trends toward 2%."
    )
    
    private static let earningsContent = TopicContent(
        current: "Earnings season provides quarterly insight into corporate health. Recent quarters have shown resilient margins despite cost pressures, with guidance proving more important than headline beats.",
        driversIntro: "Common focus areas during earnings:",
        drivers: [
            "Revenue growth vs estimates",
            "Margin trends and cost commentary",
            "Forward guidance and revisions",
            "Management tone on demand outlook",
            "Capex and hiring plans"
        ],
        riskOpportunity: "Stocks often react more to revisions and guidance than the headline beat. 'Beat and lower' quarters can still pressure sentiment.",
        historical: "Historically, stocks move more on guidance than on reported numbers. The market tends to look 6–12 months ahead, so forward commentary drives price action.",
        recap: "The quality of the beat and the tone of guidance often explain the reaction."
    )
    
    private static let defaultContent = TopicContent(
        current: "Market conditions are shaped by the interplay of earnings, economic data, and Fed policy. Current sentiment reflects uncertainty about the growth trajectory and rate path.",
        driversIntro: "General market drivers in view:",
        drivers: [
            "Federal Reserve policy and rate expectations",
            "Corporate earnings and guidance trends",
            "Economic indicators (employment, inflation, GDP)",
            "Geopolitical developments",
            "Technical levels and investor positioning"
        ],
        riskOpportunity: "Sentiment can overshoot in either direction. Unexpected policy changes, earnings surprises, or macro shocks often reset expectations.",
        historical: "Markets have historically recovered from corrections, though timing varies and the path is rarely smooth.",
        recap: "Ask about specific topics like NVDA, oil, gold, QQQ, SPY, inflation, or earnings for more detailed context."
    )
    
    // MARK: - Simple Mode Content
    
    private static let nvidiaSimple = TopicContent(
        current: "NVIDIA makes the computer chips that power AI. Think of them as selling the pickaxes during a gold rush — everyone building AI needs their products. The stock price has moved a lot as this story has grown.",
        driversIntro: "Here's what affects the stock price:",
        drivers: [
            "Big tech companies buying their AI chips",
            "New, faster chips coming out",
            "Other companies trying to compete",
            "Rules about selling to China"
        ],
        riskOpportunity: "AI spending is a big driver, and valuation is a key sensitivity. When growth expectations cool, prices can react quickly.",
        historical: "NVIDIA has had big price swings before. During the crypto craze, it shot up and then fell. This AI boom feels bigger, but large swings are still part of the story.",
        recap: "NVIDIA is a key AI chip company. The story is exciting, and expectations are already high."
    )
    
    private static let oilSimple = TopicContent(
        current: "Oil prices go up and down based on supply (how much is being pumped) and demand (how much people are using). Right now, it's a tug of war between countries limiting production and worries about the economy.",
        driversIntro: "What moves oil prices:",
        drivers: [
            "OPEC countries deciding to pump more or less",
            "How much oil the U.S. is producing",
            "Whether China's economy is growing",
            "World events and conflicts"
        ],
        riskOpportunity: "Prices can jump on supply problems or stronger demand, and slide when recession worries pick up. It's like any product — price depends on supply and demand.",
        historical: "Oil has bounced between $40 and $120 per barrel over the past 10 years. It moves around a lot based on world events.",
        recap: "Oil prices often move on global events, not just company performance."
    )
    
    private static let goldSimple = TopicContent(
        current: "Gold is often called a 'safe haven' — people buy it when they're nervous about the economy. It's like keeping cash under the mattress, but shinier. Right now, some countries are buying gold as a backup.",
        driversIntro: "What affects gold prices:",
        drivers: [
            "Interest rates — when rates are high, gold is less attractive",
            "The value of the U.S. dollar",
            "Countries buying gold as a reserve",
            "General nervousness in markets"
        ],
        riskOpportunity: "Gold can move higher when inflation surprises or fear spikes, and soften when real rates stay high. It doesn't pay dividends, so price movement is the main driver.",
        historical: "Gold tends to do well when people are scared and less when everything seems calm. It often acts like a safety asset in portfolios.",
        recap: "Gold is often treated as financial insurance. Its moves usually track rates, the dollar, and risk sentiment."
    )
    
    private static let qqqSimple = TopicContent(
        current: "QQQ is like buying a basket of the 100 biggest tech companies at once. Apple, Microsoft, NVIDIA, and others are all in there. When tech leads, QQQ often leads too — and when tech struggles, QQQ can feel it.",
        driversIntro: "What moves QQQ:",
        drivers: [
            "How the big tech companies are doing",
            "Interest rates (higher rates hurt tech stocks more)",
            "Excitement about AI",
            "Whether people are spending on tech products"
        ],
        riskOpportunity: "QQQ can move more than the overall market because a few big stocks carry a lot of weight. That can amplify swings in either direction.",
        historical: "In 2022, QQQ dropped about 30% when interest rates went up. Then it bounced back strongly. It's more of a rollercoaster than the broader market.",
        recap: "QQQ bundles big tech. The ups and downs can feel larger than the broader market."
    )
    
    private static let spySimple = TopicContent(
        current: "SPY is like holding a tiny piece of 500 of America's biggest companies at once. It's one of the most popular ways to track the stock market. When you hear 'the market is up,' they usually mean something like SPY.",
        driversIntro: "What moves SPY:",
        drivers: [
            "How well companies are doing overall",
            "What the Federal Reserve does with interest rates",
            "Jobs and economic news",
            "General mood of investors"
        ],
        riskOpportunity: "Historically, the market has trended higher over long periods, but it can drop 20% or more during rough stretches.",
        historical: "SPY has recovered from downturns over time, though sometimes it takes a few years. The 2022 drop was about 20%, and it later recovered.",
        recap: "SPY is a broad market barometer for the overall U.S. stock market."
    )
    
    private static let inflationSimple = TopicContent(
        current: "Inflation means prices are going up — your groceries, rent, gas cost more. It went crazy in 2022-2023 but has been calming down. The Fed is trying to get it back to 'normal' (about 2% per year).",
        driversIntro: "What causes inflation:",
        drivers: [
            "Rent and housing costs (a big chunk)",
            "Wages going up",
            "Gas and energy prices",
            "Supply chain issues getting better or worse"
        ],
        riskOpportunity: "If inflation drops, the Fed might lower interest rates. If inflation stays stubborn, rates may stay high. It's like a thermostat — too hot or too cold causes problems.",
        historical: "This is the worst inflation since the 1980s. Back then, it took a painful recession to fix it. This time, we're hoping for a 'soft landing' where inflation falls without a big recession.",
        recap: "Inflation is cooling down but not gone yet. Rent and service prices are the sticky parts."
    )
    
    private static let earningsSimple = TopicContent(
        current: "Earnings season is when companies report their grades — how much money they made. It happens every 3 months. What companies say about the future often matters more than the numbers themselves.",
        driversIntro: "Common focus areas:",
        drivers: [
            "Did they make more money than expected?",
            "Are profit margins (how much they keep) growing?",
            "What do they say about next quarter?",
            "Are they hiring or cutting costs?"
        ],
        riskOpportunity: "Good earnings plus a positive outlook often gets a better reaction, while good earnings plus cautious guidance can still weigh on sentiment.",
        historical: "Stock prices often move more on the outlook than the actual numbers. Companies that 'beat and raise' (good results + better forecast) usually do best.",
        recap: "What companies say about the future often shapes the reaction more than past results."
    )
    
    private static let defaultSimple = TopicContent(
        current: "The stock market moves based on how companies are doing, the economy, and what people think will happen next. Right now, there's some uncertainty about where things are headed.",
        driversIntro: "Things that move the market:",
        drivers: [
            "What the Federal Reserve does with interest rates",
            "How well companies are doing",
            "Jobs and economic numbers",
            "Big world events"
        ],
        riskOpportunity: "Markets go up and down. Historically, over long stretches they have trended higher, but the path includes rough patches.",
        historical: "The stock market has recovered from major drawdowns over time. Sometimes it takes months, sometimes years, and the path can be uneven.",
        recap: "Ask about specific things like NVDA, oil, gold, QQQ, SPY, or inflation for more helpful answers."
    )
}





