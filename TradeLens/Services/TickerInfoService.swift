//
//  TickerInfoService.swift
//  TradeLens
//
//  Provides mock ticker knowledge data.
//

import Foundation

struct TickerInfoService {
    
    /// Get ticker info if available
    static func info(for ticker: String) -> TickerInfo? {
        return tickerDatabase[ticker.uppercased()]
    }
    
    /// Database of ticker information
    private static let tickerDatabase: [String: TickerInfo] = [
        "NVDA": TickerInfo(
            ticker: "NVDA",
            companyName: "NVIDIA Corporation",
            sector: "Technology · Semiconductors",
            marketCap: "$2.1T",
            volatility: .high,
            summary: "NVIDIA designs graphics processors and AI chips. They're the leading supplier of GPUs used in gaming, data centers, and artificial intelligence training."
        ),
        "AAPL": TickerInfo(
            ticker: "AAPL",
            companyName: "Apple Inc.",
            sector: "Technology · Consumer Electronics",
            marketCap: "$3.0T",
            volatility: .low,
            summary: "Apple makes iPhones, Macs, iPads, and wearables. They also run services like the App Store, Apple Music, and iCloud that generate recurring revenue."
        ),
        "TSLA": TickerInfo(
            ticker: "TSLA",
            companyName: "Tesla, Inc.",
            sector: "Automotive · Electric Vehicles",
            marketCap: "$780B",
            volatility: .high,
            summary: "Tesla builds electric vehicles and energy storage systems. They're known for their Model 3 and Model Y cars, plus their Supercharger network."
        ),
        "MSFT": TickerInfo(
            ticker: "MSFT",
            companyName: "Microsoft Corporation",
            sector: "Technology · Software",
            marketCap: "$2.9T",
            volatility: .low,
            summary: "Microsoft makes Windows, Office, and Azure cloud services. They also own LinkedIn, GitHub, and Xbox gaming. Azure is their fastest-growing business."
        ),
        "GOOGL": TickerInfo(
            ticker: "GOOGL",
            companyName: "Alphabet Inc.",
            sector: "Technology · Internet Services",
            marketCap: "$2.1T",
            volatility: .moderate,
            summary: "Alphabet is Google's parent company. Most revenue comes from search advertising, with YouTube and Google Cloud as major growth drivers."
        ),
        "AMZN": TickerInfo(
            ticker: "AMZN",
            companyName: "Amazon.com, Inc.",
            sector: "Consumer · E-Commerce & Cloud",
            marketCap: "$1.9T",
            volatility: .moderate,
            summary: "Amazon runs the world's largest online store and AWS cloud platform. AWS generates most of their profit, while retail drives most of their revenue."
        ),
        "META": TickerInfo(
            ticker: "META",
            companyName: "Meta Platforms, Inc.",
            sector: "Technology · Social Media",
            marketCap: "$1.3T",
            volatility: .high,
            summary: "Meta owns Facebook, Instagram, and WhatsApp. They make money from digital advertising and are investing heavily in virtual reality and the metaverse."
        ),
        "AMD": TickerInfo(
            ticker: "AMD",
            companyName: "Advanced Micro Devices",
            sector: "Technology · Semiconductors",
            marketCap: "$250B",
            volatility: .high,
            summary: "AMD makes computer processors and graphics chips. They compete with Intel in CPUs and NVIDIA in GPUs, with growing presence in data centers."
        ),
        "SPY": TickerInfo(
            ticker: "SPY",
            companyName: "SPDR S&P 500 ETF Trust",
            sector: "ETF · Large Cap Blend",
            marketCap: "$500B AUM",
            volatility: .moderate,
            summary: "SPY tracks the S&P 500 index, giving you exposure to 500 of the largest U.S. companies in a single trade. It's the most actively traded ETF in the world."
        ),
        "QQQ": TickerInfo(
            ticker: "QQQ",
            companyName: "Invesco QQQ Trust",
            sector: "ETF · Large Cap Growth",
            marketCap: "$250B AUM",
            volatility: .moderate,
            summary: "QQQ tracks the Nasdaq-100, which is heavy on tech giants like Apple, Microsoft, and NVIDIA. It's more growth-focused and volatile than SPY."
        ),
        "COIN": TickerInfo(
            ticker: "COIN",
            companyName: "Coinbase Global, Inc.",
            sector: "Financials · Crypto Exchange",
            marketCap: "$45B",
            volatility: .high,
            summary: "Coinbase is the largest U.S. cryptocurrency exchange. Their revenue swings with crypto trading volumes and Bitcoin's price movements."
        ),
        "GLD": TickerInfo(
            ticker: "GLD",
            companyName: "SPDR Gold Shares",
            sector: "ETF · Commodities",
            marketCap: "$60B AUM",
            volatility: .low,
            summary: "GLD holds physical gold bars in vaults. It's a popular way to invest in gold without storing it yourself. Often used as a hedge against inflation."
        ),
        "USO": TickerInfo(
            ticker: "USO",
            companyName: "United States Oil Fund",
            sector: "ETF · Commodities",
            marketCap: "$1.5B AUM",
            volatility: .high,
            summary: "USO tracks crude oil prices using futures contracts. It's a way to trade oil without handling actual barrels, but can behave differently than spot oil."
        ),
        "XLE": TickerInfo(
            ticker: "XLE",
            companyName: "Energy Select Sector SPDR",
            sector: "ETF · Energy",
            marketCap: "$35B AUM",
            volatility: .moderate,
            summary: "XLE holds major energy companies like ExxonMobil and Chevron. It moves with oil prices and is often used to get broad exposure to the energy sector."
        ),
        "XLF": TickerInfo(
            ticker: "XLF",
            companyName: "Financial Select Sector SPDR",
            sector: "ETF · Financials",
            marketCap: "$40B AUM",
            volatility: .moderate,
            summary: "XLF holds big banks and financial firms like JPMorgan, Bank of America, and Berkshire Hathaway. It tends to do well when interest rates are rising."
        ),
        "VIX": TickerInfo(
            ticker: "VIX",
            companyName: "CBOE Volatility Index",
            sector: "Index · Volatility",
            marketCap: "N/A",
            volatility: .high,
            summary: "The VIX measures expected market volatility over the next 30 days. It's called the 'fear index' because it spikes when investors are nervous."
        ),
    ]
}

