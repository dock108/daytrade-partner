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
        let title: String
        let subtitle: String
        let detail: String
    }

    @Published var insights: [Insight] = []
    @Published var trades: [MockTrade] = []
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
        defer { isLoading = false }
        errorMessage = nil
        insights = []
        trades = []

        do {
            let trades = try await tradeService.fetchMockTrades()
            self.trades = trades
            let items = insightsService.generateInsights(from: trades)
            insights = items.map { Insight(title: $0.title, subtitle: $0.subtitle, detail: $0.detail) }
        } catch is CancellationError {
            return
        } catch {
            let appError = AppError(error)
            errorMessage = appError.userMessage
        }
    }
}
