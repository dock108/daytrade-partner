//
//  AIServiceStub.swift
//  TradeLens
//
//  Stub AI service for the Ask Anything screen.
//

import Foundation

struct AIServiceStub {
    func response(for question: String) -> String {
        let normalized = question.lowercased()

        if normalized.contains("oil") {
            return "Oil prices often react to supply headlines, OPEC+ production plans, and inventory data. Short-term moves can be choppy, while longer trends track global demand growth and refinery capacity. It helps to watch energy sector guidance for how companies are managing costs and output."
        }

        if normalized.contains("gold") {
            return "Gold is sensitive to real yields, the U.S. dollar, and risk sentiment. When inflation expectations rise faster than rates, gold can look more attractive, but it also fades when yields climb. Central bank demand and ETF flows add another layer to the trend."
        }

        if normalized.contains("qqq") {
            return "QQQ is concentrated in large-cap growth and tech, so it tends to track rate expectations and earnings from mega-cap leaders. When growth forecasts improve, it can outperform, while higher rates often pressure valuations. Keeping an eye on sector breadth helps gauge how durable a move is."
        }

        if normalized.contains("spy") {
            return "SPY reflects the broad S&P 500, so its tone is shaped by overall earnings, macro data, and risk sentiment. Leadership shifts between cyclicals and defensives can hint at market conviction. It’s useful to watch how many sectors are contributing to moves."
        }

        if normalized.contains("inflation") {
            return "Inflation trends are influenced by wage growth, shelter costs, and energy prices. Markets tend to focus on the direction of change rather than the absolute level. Softer inflation often eases pressure on rates, while sticky components can keep volatility elevated."
        }

        if normalized.contains("earnings") {
            return "Earnings seasons are all about guidance, margins, and how companies talk about demand. Even strong headline beats can be tempered by cautious outlooks. Pay attention to revisions and commentary on costs, because that often drives follow-through."
        }

        return "I can share market context on a ticker, sector, or macro theme. Try asking about oil, gold, QQQ, SPY, inflation, or earnings to see a sample response."
    }
}
