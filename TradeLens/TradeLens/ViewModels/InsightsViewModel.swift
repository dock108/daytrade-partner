//
//  InsightsViewModel.swift
//  TradeLens
//
//  ViewModel for rendering behavioral insights.
//

import Foundation

@MainActor
final class InsightsViewModel: ObservableObject {
    struct Insight: Identifiable {
        let id = UUID()
        let text: String
    }

    @Published var insights: [Insight] = []

    private let tradeService: MockTradeDataService
    private let insightsService: InsightsService

    init(
        tradeService: MockTradeDataService = MockTradeDataService(),
        insightsService: InsightsService = InsightsService()
    ) {
        self.tradeService = tradeService
        self.insightsService = insightsService
        loadInsights()
    }

    func loadInsights() {
        let trades = tradeService.fetchMockTrades()
        let strings = insightsService.generateInsights(from: trades)
        insights = strings.map { Insight(text: $0) }
    }
}
