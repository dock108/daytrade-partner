//
//  APIClientTests.swift
//  TradeLensTests
//

import XCTest
@testable import TradeLens

final class APIClientTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testFetchSnapshotSuccess() async throws {
        let session = makeSession()
        let client = APIClient(session: session, baseURL: "https://example.com")
        let json = """
        {
          "symbol": "AAPL",
          "name": "Apple Inc.",
          "price": 189.12,
          "changePercent": 1.23,
          "high52w": 199.62,
          "low52w": 124.17,
          "currency": "USD"
        }
        """

        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let symbol = components?.queryItems?.first(where: { $0.name == "symbol" })?.value

            XCTAssertEqual(url.path, "/snapshot")
            XCTAssertEqual(symbol, "AAPL")

            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )
            return (try XCTUnwrap(response), Data(json.utf8))
        }

        let snapshot = try await client.fetchSnapshot(symbol: "AAPL")

        XCTAssertEqual(snapshot.symbol, "AAPL")
        XCTAssertEqual(snapshot.name, "Apple Inc.")
        XCTAssertEqual(snapshot.currency, "USD")
    }

    func testFetchSnapshotServerError() async {
        let session = makeSession()
        let client = APIClient(session: session, baseURL: "https://example.com")
        let json = """
        {
          "message": "Invalid symbol provided."
        }
        """

        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = HTTPURLResponse(
                url: url,
                statusCode: 400,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )
            return (try XCTUnwrap(response), Data(json.utf8))
        }

        do {
            _ = try await client.fetchSnapshot(symbol: "???")
            XCTFail("Expected fetchSnapshot to throw a server error.")
        } catch {
            XCTAssertEqual(error as? AppError, .server(message: "Invalid symbol provided."))
        }
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
