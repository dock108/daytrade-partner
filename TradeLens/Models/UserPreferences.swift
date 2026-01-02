//
//  UserPreferences.swift
//  TradeLens
//
//  Lightweight user preferences captured during onboarding.
//  Informs OutlookEngine output tone and thresholds.
//

import Foundation
import SwiftUI

/// User's trading style preferences
struct UserPreferences: Codable {
    var tradingStyle: TradingStyle
    var riskTolerance: RiskTolerance
    var watchedTickers: [String]
    var hasCompletedOnboarding: Bool
    
    /// Trading timeframe preference
    enum TradingStyle: String, Codable, CaseIterable, Identifiable {
        case shortTerm = "Short-term"
        case mixed = "Mix of both"
        case longTerm = "Long-term"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .shortTerm:
                return "Days to weeks"
            case .mixed:
                return "Varies"
            case .longTerm:
                return "Months to years"
            }
        }
        
        var icon: String {
            switch self {
            case .shortTerm: return "hare.fill"
            case .mixed: return "arrow.left.arrow.right"
            case .longTerm: return "tortoise.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .shortTerm: return Color(red: 0.4, green: 0.7, blue: 1.0)
            case .mixed: return Color(red: 0.95, green: 0.75, blue: 0.3)
            case .longTerm: return Color(red: 0.5, green: 0.85, blue: 0.6)
            }
        }
        
        /// Default outlook timeframe based on style
        var defaultTimeframeDays: Int {
            switch self {
            case .shortTerm: return 7
            case .mixed: return 30
            case .longTerm: return 90
            }
        }
    }
    
    /// Risk/volatility comfort level
    enum RiskTolerance: String, Codable, CaseIterable, Identifiable {
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .low:
                return "I prefer stability"
            case .moderate:
                return "Some ups and downs are fine"
            case .high:
                return "Big swings don't bother me"
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "waveform.path.badge.minus"
            case .moderate: return "waveform.path"
            case .high: return "waveform.path.badge.plus"
            }
        }
        
        var color: Color {
            switch self {
            case .low: return .green
            case .moderate: return .orange
            case .high: return .red
            }
        }
        
        /// Volatility threshold for warnings
        var volatilityWarningThreshold: Double {
            switch self {
            case .low: return 0.06      // Warn above 6%
            case .moderate: return 0.12 // Warn above 12%
            case .high: return 0.20     // Warn above 20%
            }
        }
    }
    
    /// Default preferences
    static var `default`: UserPreferences {
        UserPreferences(
            tradingStyle: .mixed,
            riskTolerance: .moderate,
            watchedTickers: [],
            hasCompletedOnboarding: false
        )
    }
}

// MARK: - Preferences Manager

final class UserPreferencesManager: ObservableObject {
    static let shared = UserPreferencesManager()
    
    @Published var preferences: UserPreferences {
        didSet {
            save()
        }
    }
    
    private let storageKey = "TradeLens.UserPreferences"
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.preferences = decoded
        } else {
            self.preferences = .default
        }
    }
    
    // MARK: - Public API
    
    var needsOnboarding: Bool {
        !preferences.hasCompletedOnboarding
    }
    
    func updateTradingStyle(_ style: UserPreferences.TradingStyle) {
        preferences.tradingStyle = style
    }
    
    func updateRiskTolerance(_ tolerance: UserPreferences.RiskTolerance) {
        preferences.riskTolerance = tolerance
    }
    
    func updateWatchedTickers(_ tickers: [String]) {
        preferences.watchedTickers = tickers
    }
    
    func addWatchedTicker(_ ticker: String) {
        let normalized = ticker.uppercased()
        if !preferences.watchedTickers.contains(normalized) {
            preferences.watchedTickers.append(normalized)
        }
    }
    
    func removeWatchedTicker(_ ticker: String) {
        preferences.watchedTickers.removeAll { $0 == ticker.uppercased() }
    }
    
    func completeOnboarding() {
        preferences.hasCompletedOnboarding = true
    }
    
    func skipOnboarding() {
        preferences.hasCompletedOnboarding = true
    }
    
    func resetOnboarding() {
        preferences = .default
    }
    
    // MARK: - Persistence
    
    private func save() {
        if let data = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}




