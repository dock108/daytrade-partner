//
//  OutlookInsightModels.swift
//  TradeLens
//
//  UI-focused models for outlook insight cards.
//

import Foundation

struct CatalystInsight: Identifiable {
    let id = UUID()
    let date: Date
    let category: String
    let summary: String
    let whyItMatters: String
}
