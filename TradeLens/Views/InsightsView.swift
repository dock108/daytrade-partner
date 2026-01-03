//
//  InsightsView.swift
//  TradeLens
//
//  Patterns & Insights screen — uses InfoCardView for consistent styling.
//  Shows sample insights until user trade history is connected.
//

import SwiftUI

struct InsightsView: View {
    // Sample insights for preview mode (no real trades connected yet)
    private struct SampleInsight: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let detail: String
    }
    
    private let sampleInsights: [SampleInsight] = [
        SampleInsight(
            title: "Win Rate Pattern",
            subtitle: "Sample observation",
            detail: "Traders who maintain a win rate above 55% typically see consistent growth over time. This metric will reflect your actual trades once connected."
        ),
        SampleInsight(
            title: "Hold Time Matters",
            subtitle: "Sample observation",
            detail: "Studies show that average holding periods between 2-5 days often balance risk and opportunity for day traders."
        ),
        SampleInsight(
            title: "Risk Management",
            subtitle: "Sample observation",
            detail: "Keeping speculative trades under 30% of your portfolio is a common strategy to manage downside risk while maintaining growth potential."
        )
    ]

    var body: some View {
        ScreenContainerView(
            title: "Insights",
            subtitle: "Patterns from your trading activity"
        ) {
            VStack(alignment: .leading, spacing: 24) {
                sampleDataBanner
                sampleInsightCards
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
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.colors.accentPurple)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sample Insights Preview")
                        .font(Theme.typography.cardTitle)
                        .foregroundStyle(Theme.colors.textPrimary)
                    
                    Text("These are example patterns. Personalized insights will appear once trade history is connected.")
                        .font(Theme.typography.bodySmall)
                        .foregroundStyle(Theme.colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Sample Insight Cards

    private var sampleInsightCards: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScreenSectionHeader("Example Observations", icon: "lightbulb.fill")
            
            ForEach(sampleInsights) { insight in
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

    // MARK: - Coming Soon Section
    
    private var comingSoonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScreenSectionHeader("Personal Analysis", icon: "person.crop.circle.badge.checkmark")
            
            InfoCardView(accent: Theme.colors.accentBlue) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.colors.accentBlue.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.colors.accentBlue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Patterns Coming Soon")
                            .font(Theme.typography.cardTitle)
                            .foregroundStyle(Theme.colors.textPrimary)
                        
                        Text("This section will analyze your unique trading behavior once brokerage connections are available.")
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
    InsightsView()
}
