//
//  APIClient.swift
//  TradeLens
//
//  Centralized API client for backend requests.
//

import Foundation

protocol APIClientProtocol {
    func fetchSnapshot(symbol: String) async throws -> BackendModels.TickerSnapshot
    func fetchHistory(symbol: String, range: String) async throws -> [BackendModels.PricePoint]
    func askAI(
        question: String,
        symbol: String?,
        timeframeDays: Int?,
        simpleMode: Bool
    ) async throws -> BackendModels.AIResponse
}

final class APIClient {
    typealias TickerSnapshot = BackendModels.TickerSnapshot
    typealias PricePoint = BackendModels.PricePoint
    typealias Outlook = BackendModels.Outlook
    typealias AIResponse = BackendModels.AIResponse

    private enum Endpoint {
        static func snapshot(symbol: String) -> String { "/ticker/\(symbol)/snapshot" }
        static func history(symbol: String) -> String { "/ticker/\(symbol)/history" }
        static let outlook = "/outlook"
        static let ask = "/explain"
    }

    private enum HeaderValue {
        static let json = "application/json"
    }

    private enum ErrorMessage {
        static let invalidBaseURL = "The backend URL is invalid. Please check your settings."
    }

    private struct AskAIRequest: Encodable {
        let question: String
        let symbol: String?
        let timeframeDays: Int?
        let simpleMode: Bool
    }

    // Raw backend response types for mapping to app models
    private struct RawSnapshotResponse: Decodable {
        let ticker: String
        let company_name: String
        let current_price: Double
        let change_percent: Double
        let week_52_high: Double
        let week_52_low: Double
    }

    private struct RawHistoryResponse: Decodable {
        let points: [RawPricePoint]
    }

    private struct RawPricePoint: Decodable {
        let date: Date
        let close: Double
    }

    private let session: URLSession
    private let baseURLString: String
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        session: URLSession = .shared,
        baseURL: String = BackendConfig.current.baseURL
    ) {
        self.session = session
        self.baseURLString = baseURL
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder = JSONEncoder()
    }

    func fetchSnapshot(symbol: String) async throws -> TickerSnapshot {
        // Backend returns different field names, so we decode raw and map
        let request = try makeRequest(path: Endpoint.snapshot(symbol: symbol))
        let raw: RawSnapshotResponse = try await performRequest(request)
        return TickerSnapshot(
            symbol: raw.ticker,
            name: raw.company_name,
            price: raw.current_price,
            changePercent: raw.change_percent,
            high52w: raw.week_52_high,
            low52w: raw.week_52_low,
            currency: "USD"
        )
    }

    func fetchHistory(symbol: String, range: String) async throws -> [PricePoint] {
        // Map iOS range format to backend format
        let backendRange = mapRangeToBackend(range)
        let request = try makeRequest(
            path: Endpoint.history(symbol: symbol),
            queryItems: [URLQueryItem(name: "range", value: backendRange)]
        )
        let raw: RawHistoryResponse = try await performRequest(request)
        return raw.points.map { PricePoint(date: $0.date, close: $0.close) }
    }

    private func mapRangeToBackend(_ range: String) -> String {
        // Map common formats to backend's expected format
        switch range.lowercased() {
        case "1d", "1day": return "1D"
        case "1mo", "1m", "1month": return "1M"
        case "6mo", "6m": return "6M"
        case "1y", "1yr", "1year": return "1Y"
        default: return "1M"
        }
    }

    func requestOutlook(symbol: String, timeframeDays: Int?) async throws -> Outlook {
        var queryItems = [URLQueryItem(name: "symbol", value: symbol)]
        if let timeframeDays {
            queryItems.append(URLQueryItem(name: "timeframeDays", value: String(timeframeDays)))
        }

        let request = try makeRequest(path: Endpoint.outlook, queryItems: queryItems)
        return try await performRequest(request)
    }

    func askAI(
        question: String,
        symbol: String?,
        timeframeDays: Int?,
        simpleMode: Bool
    ) async throws -> AIResponse {
        let body = AskAIRequest(
            question: question,
            symbol: symbol,
            timeframeDays: timeframeDays,
            simpleMode: simpleMode
        )
        let request = try makeRequest(
            path: Endpoint.ask,
            method: "POST",
            body: encoder.encode(body)
        )
        return try await performRequest(request)
    }

    private func makeRequest(
        path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: Data? = nil
    ) throws -> URLRequest {
        guard var components = URLComponents(string: baseURLString) else {
            throw AppError.invalidRequest(message: ErrorMessage.invalidBaseURL)
        }

        let basePath = components.path
        components.path = joinedPath(basePath: basePath, endpoint: path)
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw AppError.invalidRequest(message: ErrorMessage.invalidBaseURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(HeaderValue.json, forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = body
            request.setValue(HeaderValue.json, forHTTPHeaderField: "Content-Type")
        }

        return request
    }

    private func joinedPath(basePath: String, endpoint: String) -> String {
        let trimmedBase = basePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let trimmedEndpoint = endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if trimmedBase.isEmpty {
            return "/\(trimmedEndpoint)"
        }

        return "/\(trimmedBase)/\(trimmedEndpoint)"
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = decodeErrorMessage(from: data)
                    ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                throw AppError.server(message: message)
            }

            guard !data.isEmpty else {
                throw AppError.emptyData
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw AppError(error)
            }
        } catch {
            throw AppError(error)
        }
    }

    private func decodeErrorMessage(from data: Data) -> String? {
        guard !data.isEmpty else {
            return nil
        }

        return try? decoder.decode(BackendModels.APIErrorResponse.self, from: data).message
    }
}

extension APIClient: APIClientProtocol {}
