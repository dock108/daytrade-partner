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
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let tradeService: MockTradeDataService
    private let insightsService: InsightsService

    init(
        tradeService: MockTradeDataService = MockTradeDataService(),
        insightsService: InsightsService = InsightsService()
    ) {
        self.tradeService = tradeService
        self.insightsService = insightsService
        Task {
            await loadInsights()
        }
    }

    func loadInsights() async {
        isLoading = true
        errorMessage = nil
        insights = []

        do {
            let trades = try await tradeService.fetchMockTrades()
            let strings = insightsService.generateInsights(from: trades)
            insights = strings.map { Insight(text: $0) }
        } catch {
            let appError = AppError(error)
            errorMessage = appError.userMessage
        }

        isLoading = false
    }
}
