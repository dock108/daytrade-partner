//
//  MockPriceService.swift
//  TradeLens
//
//  Generates realistic mock price data for chart display.
//

import Foundation

struct MockPriceService {
    
    /// Known tickers with base prices and characteristics
    private static let tickerProfiles: [String: TickerProfile] = [
        "NVDA": TickerProfile(basePrice: 875, volatility: 0.035, trend: 0.002),
        "AAPL": TickerProfile(basePrice: 192, volatility: 0.015, trend: 0.0005),
        "TSLA": TickerProfile(basePrice: 245, volatility: 0.04, trend: -0.001),
        "MSFT": TickerProfile(basePrice: 415, volatility: 0.018, trend: 0.001),
        "GOOGL": TickerProfile(basePrice: 175, volatility: 0.02, trend: 0.0008),
        "AMZN": TickerProfile(basePrice: 185, volatility: 0.022, trend: 0.001),
        "META": TickerProfile(basePrice: 505, volatility: 0.025, trend: 0.0015),
        "AMD": TickerProfile(basePrice: 155, volatility: 0.038, trend: 0.001),
        "SPY": TickerProfile(basePrice: 520, volatility: 0.012, trend: 0.0004),
        "QQQ": TickerProfile(basePrice: 450, volatility: 0.015, trend: 0.0005),
        "COIN": TickerProfile(basePrice: 215, volatility: 0.05, trend: 0.0),
        "GLD": TickerProfile(basePrice: 215, volatility: 0.008, trend: 0.0003),
        "USO": TickerProfile(basePrice: 78, volatility: 0.025, trend: -0.0005),
        "XLE": TickerProfile(basePrice: 92, volatility: 0.02, trend: 0.0002),
        "XLF": TickerProfile(basePrice: 42, volatility: 0.015, trend: 0.0003),
        "VIX": TickerProfile(basePrice: 14, volatility: 0.08, trend: 0.0),
    ]
    
    private struct TickerProfile {
        let basePrice: Double
        let volatility: Double  // Daily volatility
        let trend: Double       // Daily drift
    }
    
    /// Detect ticker from a search query
    static func detectTicker(in query: String) -> String? {
        let normalized = query.uppercased()
        
        // Direct ticker match
        for ticker in tickerProfiles.keys {
            if normalized.contains(ticker) {
                return ticker
            }
        }
        
        // Common name mappings
        let nameMap: [String: String] = [
            "NVIDIA": "NVDA",
            "APPLE": "AAPL",
            "TESLA": "TSLA",
            "MICROSOFT": "MSFT",
            "GOOGLE": "GOOGL",
            "ALPHABET": "GOOGL",
            "AMAZON": "AMZN",
            "FACEBOOK": "META",
            "OIL": "USO",
            "GOLD": "GLD",
            "ENERGY": "XLE",
            "FINANCIALS": "XLF",
            "BANKS": "XLF",
        ]
        
        for (name, ticker) in nameMap {
            if normalized.contains(name) {
                return ticker
            }
        }
        
        return nil
    }
    
    /// Generate mock price history for a ticker
    static func priceHistory(for ticker: String, range: ChartTimeRange = .oneMonth) -> PriceHistory? {
        guard let profile = tickerProfiles[ticker.uppercased()] else {
            return nil
        }
        
        let days = range.days
        let pointsPerDay = range == .oneDay ? 78 : 1  // 5-min intervals for 1D, daily otherwise
        let totalPoints = days * pointsPerDay
        
        var points: [PricePoint] = []
        var currentPrice = profile.basePrice
        
        let calendar = Calendar.current
        let now = Date()
        
        // Generate price path using random walk with drift
        for i in 0..<totalPoints {
            let timeOffset: TimeInterval
            if range == .oneDay {
                // 5-minute intervals going back from now
                timeOffset = Double(totalPoints - 1 - i) * 5 * 60
            } else {
                // Daily intervals
                timeOffset = Double(totalPoints - 1 - i) * 24 * 60 * 60
            }
            
            let date = now.addingTimeInterval(-timeOffset)
            
            // Skip weekends for daily data
            if range != .oneDay {
                let weekday = calendar.component(.weekday, from: date)
                if weekday == 1 || weekday == 7 {
                    continue
                }
            }
            
            // Random walk with drift
            let dailyReturn = profile.trend + profile.volatility * randomGaussian()
            let intradayVolatility = range == .oneDay ? profile.volatility / 4 : profile.volatility
            
            currentPrice *= (1 + dailyReturn * (range == .oneDay ? 0.1 : 1.0))
            currentPrice = max(currentPrice, profile.basePrice * 0.5) // Floor at 50% of base
            
            // Generate high/low based on volatility
            let spread = currentPrice * intradayVolatility * 0.5
            let high = currentPrice + abs(randomGaussian()) * spread
            let low = currentPrice - abs(randomGaussian()) * spread
            
            points.append(PricePoint(
                date: date,
                close: currentPrice.rounded(toPlaces: 2),
                high: high.rounded(toPlaces: 2),
                low: low.rounded(toPlaces: 2)
            ))
        }
        
        // Calculate change from first to last
        guard let firstPoint = points.first, let lastPoint = points.last else {
            return nil
        }
        
        let change = lastPoint.close - firstPoint.close
        let changePercent = (change / firstPoint.close) * 100
        
        return PriceHistory(
            ticker: ticker.uppercased(),
            points: points,
            currentPrice: lastPoint.close,
            change: change.rounded(toPlaces: 2),
            changePercent: changePercent.rounded(toPlaces: 2)
        )
    }
    
    /// Generate a normally distributed random number (Box-Muller transform)
    private static func randomGaussian() -> Double {
        let u1 = Double.random(in: 0.0001...0.9999)
        let u2 = Double.random(in: 0.0001...0.9999)
        return sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}




