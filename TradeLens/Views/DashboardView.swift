//
//  DashboardView.swift
//  TradeLens
//
//  Dashboard summary view — uses InfoCardView for consistent styling.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        ScreenContainerView(
            title: "Dashboard",
            subtitle: "Your trading summary at a glance"
        ) {
            VStack(alignment: .leading, spacing: 24) {
                if let errorMessage = viewModel.errorMessage {
                    errorStateView(message: errorMessage) {
                        Task {
                            await viewModel.loadDashboard()
                        }
                    }
                } else if viewModel.isLoading {
                    loadingState
                } else if let summary = viewModel.summary {
                    statsGrid(summary: summary)
                    insightSection(summary: summary)
                    tickerSection(summary: summary)
                    tradesSection
                } else {
                    emptyState
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
    }
    
    // MARK: - Loading State
    
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.colors.accentBlue))
                .scaleEffect(1.2)
            
            Text("Loading summary...")
                .font(Theme.typography.bodySmall)
                .foregroundStyle(Theme.colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        EmptyStateCard(
            icon: "chart.bar.xaxis",
            title: "No data yet",
            message: "Import trades to see your dashboard"
        )
    }

    // MARK: - Stats Grid

    private func statsGrid(summary: UserSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ScreenSectionHeader("Key Metrics", icon: "chart.bar.fill")
            
            // Top row - 2 stats
            HStack(spacing: 12) {
                StatInfoCard(
                    title: "Win Rate",
                    value: CurrencyFormatter.formatPercentage(summary.winRate),
                    icon: "target",
                    color: summary.winRate >= 0.5 ? Theme.colors.accentGreen : Theme.colors.accentOrange,
                    trend: summary.winRate >= 0.55 ? .up : (summary.winRate >= 0.45 ? .neutral : .down)
                )
                
                StatInfoCard(
                    title: "Total Trades",
                    value: "\(summary.totalTrades)",
                    icon: "rectangle.stack.fill",
                    color: Theme.colors.accentBlue
                )
            }
            
            // Bottom row - 2 stats
            HStack(spacing: 12) {
                StatInfoCard(
                    title: "Avg Hold",
                    value: String(format: "%.1f days", summary.avgHoldDays),
                    icon: "clock.fill",
                    color: Theme.colors.accentPurple
                )
                
                StatInfoCard(
                    title: "Total P/L",
                    value: CurrencyFormatter.formatUSD(summary.realizedPnLTotal),
                    icon: summary.realizedPnLTotal >= 0 ? "arrow.up.right" : "arrow.down.right",
                    color: summary.realizedPnLTotal >= 0 ? Theme.colors.accentGreen : Theme.colors.accentRed,
                    trend: summary.realizedPnLTotal >= 0 ? .up : .down
                )
            }
        }
    }

    // MARK: - Insight Section

    private func insightSection(summary: UserSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ScreenSectionHeader("Risk Profile", icon: "shield.fill")
            
            InfoCardView(accent: riskColor(for: summary.speculativePercent)) {
                VStack(alignment: .leading, spacing: 14) {
                    // Risk meter
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(riskColor(for: summary.speculativePercent).opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: riskIcon(for: summary.speculativePercent))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(riskColor(for: summary.speculativePercent))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(riskLabel(for: summary.speculativePercent))
                                .font(Theme.typography.cardTitle)
                                .foregroundStyle(Theme.colors.textPrimary)
                            
                            Text(viewModel.riskMessage)
                                .font(Theme.typography.bodySmall)
                                .foregroundStyle(Theme.colors.textSecondary)
                        }
                    }
                    
                    // Speculative bar
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Speculative trades")
                                .font(Theme.typography.statLabel)
                                .foregroundStyle(Theme.colors.textTertiary)
                            
                            Spacer()
                            
                            Text(CurrencyFormatter.formatPercentage(summary.speculativePercent))
                                .font(Theme.typography.statLabel)
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.colors.textSecondary)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.colors.cardBackgroundElevated)
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(riskColor(for: summary.speculativePercent))
                                    .frame(width: geo.size.width * min(1, summary.speculativePercent), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
    }
    
    private func riskColor(for speculativePercent: Double) -> Color {
        if speculativePercent < 0.3 {
            return Theme.colors.accentGreen
        } else if speculativePercent < 0.6 {
            return Theme.colors.accentOrange
        } else {
            return Theme.colors.accentRed
        }
    }
    
    private func riskLabel(for speculativePercent: Double) -> String {
        if speculativePercent < 0.3 {
            return "Conservative"
        } else if speculativePercent < 0.6 {
            return "Balanced"
        } else {
            return "Aggressive"
        }
    }
    
    private func riskIcon(for speculativePercent: Double) -> String {
        if speculativePercent < 0.3 {
            return "shield.checkmark.fill"
        } else if speculativePercent < 0.6 {
            return "scale.3d"
        } else {
            return "flame.fill"
        }
    }

    // MARK: - Ticker Section

    private func tickerSection(summary: UserSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ScreenSectionHeader("Top & Bottom Performers", icon: "medal.fill")
            
            HStack(spacing: 12) {
                // Best ticker
                InfoCardView(accent: Theme.colors.accentGreen) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(Theme.typography.caption)
                                .foregroundStyle(Theme.colors.accentGreen)
                            
                            Text("Best")
                                .font(Theme.typography.sectionHeader)
                                .foregroundStyle(Theme.colors.textTertiary)
                                .textCase(.uppercase)
                        }
                        
                        Text(summary.bestTicker ?? "—")
                            .font(Theme.typography.statLarge)
                            .foregroundStyle(Theme.colors.textPrimary)
                    }
                }
                
                // Worst ticker
                InfoCardView(accent: Theme.colors.accentRed) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(Theme.typography.caption)
                                .foregroundStyle(Theme.colors.accentRed)
                            
                            Text("Weakest")
                                .font(Theme.typography.sectionHeader)
                                .foregroundStyle(Theme.colors.textTertiary)
                                .textCase(.uppercase)
                        }
                        
                        Text(summary.worstTicker ?? "—")
                            .font(Theme.typography.statLarge)
                            .foregroundStyle(Theme.colors.textPrimary)
                    }
                }
            }
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
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(RowButtonStyle())
                            
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
                    .font(Theme.typography.body)
                    .fontWeight(.semibold)
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
                .font(Theme.typography.caption)
                .fontWeight(.semibold)
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
    DashboardView()
}
