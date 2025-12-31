//
//  UserSummary.swift
//  TradeLens
//
//  Aggregated summary of trading performance.
//

import Foundation

struct UserSummary: Codable, Equatable {
    let totalTrades: Int
    let winRate: Double
    let avgHoldDays: Double
    let bestTicker: String?
    let worstTicker: String?
    let speculativePercent: Double
    let realizedPnLTotal: Double

    init(
        totalTrades: Int,
        winRate: Double,
        avgHoldDays: Double,
        bestTicker: String? = nil,
        worstTicker: String? = nil,
        speculativePercent: Double,
        realizedPnLTotal: Double
    ) {
        self.totalTrades = totalTrades
        self.winRate = winRate
        self.avgHoldDays = avgHoldDays
        self.bestTicker = bestTicker
        self.worstTicker = worstTicker
        self.speculativePercent = speculativePercent
        self.realizedPnLTotal = realizedPnLTotal
    }
}
