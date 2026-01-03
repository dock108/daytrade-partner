//
//  OutlookInsightCards.swift
//  TradeLens
//
//  Specialized cards for upcoming catalysts, recent news, expected range, and pattern insights.
//

import SwiftUI

struct UpcomingCatalystsCard: View {
    let catalysts: [CatalystInsight]

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            ForEach(catalysts) { catalyst in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Text(Self.dateFormatter.string(from: catalyst.date))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.colors.accentBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Theme.colors.accentBlue.opacity(0.15))
                            )

                        Text(catalyst.category)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .textCase(.uppercase)
                            .tracking(0.6)

                        Spacer()
                    }

                    Text(catalyst.summary)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.85))

                    Text(catalyst.whyItMatters)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .lineSpacing(3)
                }

                if catalyst.id != catalysts.last?.id {
                    Divider()
                        .background(Color.white.opacity(0.08))
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.colors.accentBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Upcoming Catalysts")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.9))

                Text("Next scheduled signals")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.45))
            }

            Spacer()
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

struct RecentNewsCard: View {
    let newsItems: [NewsStore.NewsItem]

    @State private var selectedLink: NewsLinkDestination? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if newsItems.isEmpty {
                emptyState
            } else {
                ForEach(newsItems.prefix(3)) { item in
                    Button {
                        if let urlString = item.url, let url = URL(string: urlString) {
                            selectedLink = NewsLinkDestination(url: url)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .multilineTextAlignment(.leading)

                            HStack(spacing: 8) {
                                Text(item.source)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.white.opacity(0.5))

                                Text("•")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.white.opacity(0.35))

                                Text(relativeTime(from: item.publishedAt))
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.white.opacity(0.5))

                                Spacer()

                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.white.opacity(0.35))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .disabled(item.url == nil)

                    if item.id != newsItems.prefix(3).last?.id {
                        Divider()
                            .background(Color.white.opacity(0.08))
                    }
                }
            }
        }
        .padding(16)
        .background(cardBackground)
        .sheet(item: $selectedLink) { link in
            SafariView(url: link.url)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "newspaper.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.colors.accentGreen)

            VStack(alignment: .leading, spacing: 2) {
                Text("Recent News")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.9))

                Text(newsItems.isEmpty ? "No meaningful news — movement is macro." : "Past 7 days")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.45))
            }

            Spacer()
        }
    }

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "globe")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.4))

            Text("No single headline is driving the move right now.")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.55))
        }
        .padding(.vertical, 8)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ExpectedRangeCard: View {
    let expectedSwingPercent: Double
    let volatilityLabel: String

    private let maxRange: Double = 0.3

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("± Expected 30-day swing")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(0.6)

                    Text(formattedPercent)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.colors.accentOrange)
                }

                Spacer()

                volatilityMeter
            }

            rangeBar

            Text("based on historical analogs, not predictions")
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .padding(16)
        .background(cardBackground)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.colors.accentOrange)

            Text("Expected Range")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.9))

            Spacer()
        }
    }

    private var rangeBar: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let normalized = min(normalizedPercent / maxRange, 1)
            let rangeWidth = width * normalized

            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 12)

                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.colors.accentOrange.opacity(0.35))
                    .frame(width: rangeWidth, height: 12)

                Rectangle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 2, height: 16)
            }
        }
        .frame(height: 16)
    }

    private var volatilityMeter: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(volatilityLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(volatilityColor)

            HStack(spacing: 3) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < volatilityLevel ? volatilityColor : Color.white.opacity(0.1))
                        .frame(width: 8, height: 16)
                }
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private var normalizedPercent: Double {
        expectedSwingPercent > 1 ? expectedSwingPercent / 100 : expectedSwingPercent
    }

    private var formattedPercent: String {
        String(format: "±%.1f%%", normalizedPercent * 100)
    }

    private var volatilityLevel: Int {
        switch normalizedPercent {
        case ..<0.05: return 1
        case 0.05..<0.08: return 2
        case 0.08..<0.12: return 3
        case 0.12..<0.18: return 4
        default: return 5
        }
    }

    private var volatilityColor: Color {
        switch volatilityLevel {
        case 1: return Theme.colors.accentGreen
        case 2: return Color(red: 0.6, green: 0.8, blue: 0.4)
        case 3: return Theme.colors.accentOrange
        case 4: return Color(red: 1.0, green: 0.6, blue: 0.3)
        default: return Theme.colors.accentRed
        }
    }
}

struct PatternInsightCard: View {
    let insightText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            Text(insightText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.85))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Theme.colors.accentPurple.opacity(0.15))
                )
        }
        .padding(16)
        .background(cardBackground)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.colors.accentPurple)

            Text("Pattern Insight")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.9))

            Spacer()
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

private struct NewsLinkDestination: Identifiable {
    let id = UUID()
    let url: URL
}

#Preview("Outlook Insight Cards") {
    let sampleCatalysts = [
        CatalystInsight(
            date: Date().addingTimeInterval(86400 * 3),
            category: "Earnings",
            summary: "Guidance update on margins and demand",
            whyItMatters: "Expectations could reset if commentary shifts on the next call."
        ),
        CatalystInsight(
            date: Date().addingTimeInterval(86400 * 8),
            category: "Macro",
            summary: "CPI print and rate commentary",
            whyItMatters: "Rate-sensitive multiples may expand or compress around the release."
        )
    ]

    let sampleNews = [
        NewsStore.NewsItem(
            id: "sample-1",
            title: "Chipmakers see renewed demand as AI budgets climb",
            summary: "Market sentiment remains constructive ahead of earnings season.",
            source: "Reuters",
            publishedAt: Date().addingTimeInterval(-7200),
            url: "https://example.com",
            relatedTickers: ["NVDA"]
        ),
        NewsStore.NewsItem(
            id: "sample-2",
            title: "Macro data keeps traders cautious into month-end",
            summary: "Volume is lighter with traders awaiting new data releases.",
            source: "Bloomberg",
            publishedAt: Date().addingTimeInterval(-21600),
            url: "https://example.com",
            relatedTickers: ["NVDA"]
        )
    ]

    return ScrollView {
        VStack(spacing: 16) {
            UpcomingCatalystsCard(catalysts: sampleCatalysts)
            RecentNewsCard(newsItems: sampleNews)
            ExpectedRangeCard(expectedSwingPercent: 0.12, volatilityLabel: "High")
            PatternInsightCard(insightText: "Similar setups have tended to drift sideways into earnings")
        }
        .padding(20)
    }
    .background(Color(red: 0.06, green: 0.08, blue: 0.12))
}
