//
//  Trade.swift
//  TradeLens
//
//  Core trade model representing an entry/exit transaction.
//

import Foundation

/// Represents a single trade transaction
struct Trade: Identifiable, Codable {
    enum Category: String, Codable {
        case core
        case speculative
    }

    let id: UUID
    let ticker: String
    let entryDate: Date
    let exitDate: Date?
    let qty: Double
    let entryPrice: Double
    let exitPrice: Double?
    let realizedPnL: Double?
    let category: Category

    var isClosed: Bool {
        exitDate != nil
    }

    var holdingDays: Int? {
        guard let exitDate else {
            return nil
        }
        let components = Calendar.current.dateComponents([.day], from: entryDate, to: exitDate)
        return components.day
    }

    var computedRealizedPnL: Double? {
        if let realizedPnL {
            return realizedPnL
        }
        guard let exitPrice else {
            return nil
        }
        return (exitPrice - entryPrice) * qty
    }

    init(
        id: UUID = UUID(),
        ticker: String,
        entryDate: Date,
        exitDate: Date? = nil,
        qty: Double,
        entryPrice: Double,
        exitPrice: Double? = nil,
        realizedPnL: Double? = nil,
        category: Category = .core
    ) {
        self.id = id
        self.ticker = ticker
        self.entryDate = entryDate
        self.exitDate = exitDate
        self.qty = qty
        self.entryPrice = entryPrice
        self.exitPrice = exitPrice
        self.realizedPnL = realizedPnL
        self.category = category
    }
}
