//
//  InsightsView.swift
//  TradeLens
//
//  Patterns & Insights screen — uses InfoCardView for consistent styling.
//

import SwiftUI

struct InsightsView: View {
    @StateObject private var viewModel = InsightsViewModel()

    var body: some View {
        ScreenContainerView(
            title: "Insights",
            subtitle: "Patterns from your trading activity"
        ) {
            VStack(alignment: .leading, spacing: 24) {
                if let errorMessage = viewModel.errorMessage {
                    errorStateView(message: errorMessage) {
                        Task {
                            await viewModel.loadInsights()
                        }
                    }
                } else if viewModel.isLoading {
                    loadingState
                } else {
                    insightCards
                    tradesSection
                }
            }
        }
    }
    
    // MARK: - Loading State
    
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.colors.accentBlue))
                .scaleEffect(1.2)
            
            Text("Analyzing patterns...")
                .font(Theme.typography.bodySmall)
                .foregroundStyle(Theme.colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Insight Cards

    private var insightCards: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScreenSectionHeader("Key Observations", icon: "lightbulb.fill")
            
            if viewModel.insights.isEmpty {
                EmptyStateCard(
                    icon: "sparkles",
                    title: "No insights yet",
                    message: "Add more trades to see personalized patterns"
                )
            } else {
                ForEach(viewModel.insights) { insight in
                    InsightInfoCard(
                        title: insight.title,
                        subtitle: insight.subtitle,
                        detail: insight.detail,
                        icon: icon(for: insight.title),
                        color: accentColor(for: insight.title)
                    )
                }
            }
        }
    }
    
    private func accentColor(for title: String) -> Color {
        switch title.lowercased() {
        case let t where t.contains("win"):
            return Theme.colors.accentGreen
        case let t where t.contains("hold") || t.contains("time"):
            return Theme.colors.accentBlue
        case let t where t.contains("risk") || t.contains("loss"):
            return Theme.colors.accentOrange
        case let t where t.contains("best") || t.contains("strong"):
            return Theme.colors.accentGreen
        default:
            return Theme.colors.accentPurple
        }
    }
    
    private func icon(for title: String) -> String {
        switch title.lowercased() {
        case let t where t.contains("win"):
            return "trophy.fill"
        case let t where t.contains("hold") || t.contains("time"):
            return "clock.fill"
        case let t where t.contains("risk"):
            return "exclamationmark.triangle.fill"
        case let t where t.contains("best"):
            return "star.fill"
        default:
            return "lightbulb.fill"
        }
    }

    // MARK: - Trades Section

    private var tradesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScreenSectionHeader("Recent Trades", icon: "clock.arrow.circlepath")
            
            if viewModel.trades.isEmpty {
                InfoCardView {
                    Text("No trades yet")
                        .font(Theme.typography.body)
                        .foregroundStyle(Theme.colors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ListInfoCard {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.trades.prefix(5).enumerated()), id: \.element.id) { index, trade in
                            NavigationLink {
                                TradeDetailView(trade: trade)
                            } label: {
                                tradeRow(trade)
                            }
                            .buttonStyle(.plain)
                            
                            if index < min(4, viewModel.trades.count - 1) {
                                Divider()
                                    .background(Theme.colors.divider)
                                    .padding(.leading, 54)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func tradeRow(_ trade: MockTrade) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(trade.realizedPnL >= 0 ? Theme.colors.accentGreen.opacity(0.15) : Theme.colors.accentRed.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: trade.realizedPnL >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(trade.realizedPnL >= 0 ? Theme.colors.accentGreen : Theme.colors.accentRed)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(trade.ticker)
                    .font(Theme.typography.ticker)
                    .foregroundStyle(Theme.colors.textPrimary)
                
                Text("\(trade.holdingDays) days")
                    .font(Theme.typography.rowSubtitle)
                    .foregroundStyle(Theme.colors.textTertiary)
            }
            
            Spacer()
            
            Text(CurrencyFormatter.formatUSD(trade.realizedPnL))
                .font(Theme.typography.statSmall)
                .foregroundStyle(trade.realizedPnL >= 0 ? Theme.colors.accentGreen : Theme.colors.accentRed)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.colors.textQuaternary)
        }
        .padding(.vertical, 10)
    }

    // MARK: - Error State

    private func errorStateView(message: String, retry: @escaping () -> Void) -> some View {
        InfoCardView(accent: Theme.colors.accentOrange) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.colors.accentOrange)
                    
                    Text("Something went wrong")
                        .font(Theme.typography.cardTitle)
                        .foregroundStyle(Theme.colors.textPrimary)
                }
                
                Text(message)
                    .font(Theme.typography.bodySmall)
                    .foregroundStyle(Theme.colors.textTertiary)
                
                Button(action: retry) {
                    Text("Try Again")
                        .font(Theme.typography.button)
                        .foregroundStyle(Theme.colors.accentBlue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Theme.colors.accentBlue.opacity(0.15))
                        )
                }
            }
        }
    }
}

#Preview {
    InsightsView()
}
