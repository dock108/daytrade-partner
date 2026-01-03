//
//  BackendConfig.swift
//  TradeLens
//
//  Backend configuration for API access.
//

import Foundation

struct BackendConfig {
    let baseURL: String

    static let localhost = BackendConfig(baseURL: "http://localhost:8080")
    // TODO: Replace with production API base URL when available.
    static let production = BackendConfig(baseURL: "https://api.daytrade-partner.com")

    static var current: BackendConfig {
        #if DEBUG
        return .localhost
        #else
        return .production
        #endif
    }
}
