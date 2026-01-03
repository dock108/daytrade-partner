//
//  AppError.swift
//  TradeLens
//
//  Shared error definitions for async services.
//

import Foundation

/// A unified error type for app-level failures.
enum AppError: Error, Equatable {
    case invalidRequest(message: String)
    case networkFailure(message: String)
    case server(message: String)
    case decoding
    case emptyData
    case invalidResponse
    case unknown

    init(_ error: Error) {
        if let appError = error as? AppError {
            self = appError
            return
        }

        if error is DecodingError {
            self = .decoding
            return
        }

        if error is URLError {
            self = .networkFailure(message: "We couldn't reach the server. Please try again.")
            return
        }

        self = .unknown
    }

    /// A user-friendly message for display in the UI.
    var userMessage: String {
        switch self {
        case .invalidRequest(let message):
            return message
        case .networkFailure(let message):
            return message
        case .server(let message):
            return message
        case .decoding:
            return "We couldn't read the latest data. Please try again."
        case .emptyData:
            return "No data is available yet. Please try again soon."
        case .invalidResponse:
            return "We received an unexpected response. Please try again."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}
