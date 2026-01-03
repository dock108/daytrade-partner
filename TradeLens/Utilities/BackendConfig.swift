//
//  BackendConfig.swift
//  TradeLens
//
//  Backend configuration for API access.
//

import Foundation

struct BackendConfig {
    let baseURL: String

    /// Local development backend (Python FastAPI server)
    static let localhost = BackendConfig(baseURL: "http://127.0.0.1:8000")
    
    /// Production API (when deployed)
    static let production = BackendConfig(baseURL: "https://api.daytrade-partner.com")

    /// Current active configuration
    static var current: BackendConfig {
        #if DEBUG
        return .localhost
        #else
        return .production
        #endif
    }
}
