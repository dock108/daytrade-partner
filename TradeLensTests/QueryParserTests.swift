//
//  QueryParserTests.swift
//  TradeLensTests
//

import XCTest
@testable import TradeLens

final class QueryParserTests: XCTestCase {
    func testDetectTickerFindsExplicitTickerCaseInsensitive() {
        let ticker = QueryParser.detectTicker(in: "what's the outlook on spy")
        XCTAssertEqual(ticker, "SPY")
    }

    func testDetectTickerFindsUppercaseToken() {
        let ticker = QueryParser.detectTicker(in: "Any news on AMD this week?")
        XCTAssertEqual(ticker, "AMD")
    }

    func testDetectTickerReturnsNilWithoutCandidate() {
        let ticker = QueryParser.detectTicker(in: "how are markets behaving today")
        XCTAssertNil(ticker)
    }

    func testExtractTimeframeDaysParsesNumberedMonths() {
        let days = QueryParser.extractTimeframeDays(from: "what happens in 3 months")
        XCTAssertEqual(days, 90)
    }

    func testExtractTimeframeDaysParsesNextMonth() {
        let days = QueryParser.extractTimeframeDays(from: "give me the next month outlook")
        XCTAssertEqual(days, 30)
    }

    func testExtractTimeframeDaysParsesWeeks() {
        let days = QueryParser.extractTimeframeDays(from: "look back 2 weeks")
        XCTAssertEqual(days, 14)
    }

    func testExtractTimeframeDaysDefaultsToThirty() {
        let days = QueryParser.extractTimeframeDays(from: "how is the market right now")
        XCTAssertEqual(days, 30)
    }
}
