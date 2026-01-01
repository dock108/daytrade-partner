//
//  TickerInfo.swift
//  TradeLens
//
//  Ticker knowledge panel data model.
//

import Foundation
import SwiftUI

/// Snapshot information about a ticker
struct TickerInfo: Identifiable {
    let id = UUID()
    let ticker: String
    let companyName: String
    let sector: String
    let marketCap: String
    let volatility: VolatilityLevel
    let summary: String
    
    enum VolatilityLevel: String {
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        
        var color: Color {
            switch self {
            case .low: return Color(red: 0.3, green: 0.7, blue: 0.5)
            case .moderate: return Color(red: 0.9, green: 0.7, blue: 0.2)
            case .high: return Color(red: 0.95, green: 0.4, blue: 0.4)
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "waveform.path"
            case .moderate: return "waveform.path.ecg"
            case .high: return "waveform.path.badge.exclamationmark"
            }
        }
    }
}



