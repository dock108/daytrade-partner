//
//  DashboardView.swift
//  TradeLens
//
//  Dashboard summary view — uses InfoCardView for consistent styling.
//  Shows sample data until user trade history is connected.
//

import SwiftUI

struct DashboardView: View {
    // Sample data for preview mode (no real trades connected yet)
    private let sampleSummary = UserSummary(
        totalTrades: 47,
        winRate: 0.62,
        avgHoldDays: 3.8,
        bestTicker: "NVDA",
        worstTicker: "COIN",
        speculativePercent: 0.35,
        realizedPnLTotal: 2847.50
    )
    
    var body: some View {
        ScreenContainerView(
            title: "Dashboard",
            subtitle: "Your trading summary at a glance"
        ) {
            VStack(alignment: .leading, spacing: 24) {
                sampleDataBanner
                statsGrid(summary: sampleSummary)
                insightSection(summary: sampleSummary)
                tickerSection(summary: sampleSummary)
                comingSoonSection
                dataFootnote
            }
        }
    }
    
    // MARK: - Sample Data Banner
    
    private var sampleDataBanner: some View {
        InfoCardView(accent: Theme.colors.accentPurple) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.colors.accentPurple.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.colors.accentPurple)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sample Data Preview")
                        .font(Theme.typography.cardTitle)
                        .foregroundStyle(Theme.colors.textPrimary)
                    
                    Text("This dashboard shows example stats. Personal tracking will be available once trade history is connected.")
                        .font(Theme.typography.bodySmall)
                        .foregroundStyle(Theme.colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
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
                            
                            Text(riskMessage(for: summary.speculativePercent))
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
    
    private func riskMessage(for speculativePercent: Double) -> String {
        switch speculativePercent {
        case ..<0.3:
            return "Leans risk-averse"
        case 0.3..<0.6:
            return "Balances core and speculative"
        default:
            return "Leans risk-on"
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

    // MARK: - Coming Soon Section
    
    private var comingSoonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScreenSectionHeader("Trade Tracking", icon: "clock.arrow.circlepath")
            
            InfoCardView(accent: Theme.colors.accentBlue) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.colors.accentBlue.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.colors.accentBlue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Personal Stats Coming Soon")
                            .font(Theme.typography.cardTitle)
                            .foregroundStyle(Theme.colors.textPrimary)
                        
                        Text("This section will show your real trade history once brokerage connections are available.")
                            .font(Theme.typography.bodySmall)
                            .foregroundStyle(Theme.colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
    
    // MARK: - Data Footnote
    
    private var dataFootnote: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundStyle(Theme.colors.textMuted)
            
            Text("Current version uses only public market data and AI explanations.")
                .font(Theme.typography.disclaimer)
                .foregroundStyle(Theme.colors.textMuted)
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }
}

#Preview {
    DashboardView()
}
