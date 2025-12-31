//
//  OutlookCardView.swift
//  TradeLens
//
//  Outlook card layout styled like Apple Health insights.
//  Friendly, calm, informational — no financial advice.
//

import SwiftUI

struct OutlookCardView: View {
    let outlook: Outlook
    @State private var expandedInfo: InfoType? = nil
    
    enum InfoType: String, Identifiable {
        case sentiment = "Sentiment Summary"
        case volatility = "Expected Swings"
        case hitRate = "Historical Behavior"
        
        var id: String { rawValue }
        
        var explanation: String {
            switch self {
            case .sentiment:
                return "This reflects the overall tone of current market conditions and sector trends — not a prediction of future performance."
            case .volatility:
                return "This shows the typical range of price movement based on historical volatility. Actual results may vary significantly."
            case .hitRate:
                return "This is how often the ticker has finished higher over similar past time windows. Past performance does not indicate future results."
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Content sections
            VStack(alignment: .leading, spacing: 20) {
                bigPictureSection
                
                // Timeframe note if applicable
                if let timeframeNote = outlook.timeframeNote {
                    preferenceNoteCard(
                        message: timeframeNote,
                        icon: "clock.badge.exclamationmark",
                        color: Color(red: 0.4, green: 0.7, blue: 1.0)
                    )
                }
                
                keyDriversSection
                
                expectedSwingsSection
                
                // Volatility warning if applicable
                if let volatilityWarning = outlook.volatilityWarning {
                    preferenceNoteCard(
                        message: volatilityWarning,
                        icon: "exclamationmark.triangle",
                        color: .orange
                    )
                }
                
                historicalSection
                
                // Visual distribution chart - "Typical 30-day range based on past moves"
                HistoricalRangeView(
                    ticker: outlook.ticker,
                    timeframeDays: outlook.timeframeDays,
                    volatilityBand: outlook.volatilityBand,
                    historicalHitRate: outlook.historicalHitRate
                )
                
                if let personalContext = outlook.personalContext {
                    personalNoteSection(personalContext)
                }
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.13, blue: 0.20),
                            Color(red: 0.08, green: 0.10, blue: 0.16)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .sheet(item: $expandedInfo) { info in
            InfoExplanationSheet(info: info)
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(spacing: 14) {
            // Ticker badge
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(sentimentColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                
                Text(outlook.ticker)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(sentimentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(outlook.timeframeDays)-Day Outlook")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                
                HStack(spacing: 6) {
                    Image(systemName: outlook.sentimentSummary.icon)
                        .font(.system(size: 11, weight: .semibold))
                    
                    Text(outlook.sentimentSummary.rawValue)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(sentimentColor)
            }
            
            Spacer()
            
            // Info button
            Button {
                expandedInfo = .sentiment
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
        }
        .padding(20)
    }
    
    // MARK: - Big Picture
    
    private var bigPictureSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Big Picture", icon: "globe.americas.fill", color: .blue)
            
            Text(outlook.sentimentSummary.description)
                .font(.system(size: 15))
                .foregroundStyle(Color.white.opacity(0.8))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Key Drivers
    
    private var keyDriversSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "What could move it", icon: "bolt.fill", color: .yellow)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(outlook.keyDrivers, id: \.self) { driver in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.yellow.opacity(0.6))
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        
                        Text(driver)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .lineSpacing(2)
                    }
                }
            }
        }
    }
    
    // MARK: - Expected Swings
    
    private var expectedSwingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: "Expected swings", icon: "waveform.path", color: .orange)
                
                Spacer()
                
                Button {
                    expandedInfo = .volatility
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
            }
            
            // Volatility visualization
            HStack(spacing: 16) {
                // Volatility band display
                VStack(alignment: .leading, spacing: 6) {
                    Text("Typical Range")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("±")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.orange.opacity(0.7))
                        
                        Text(formatPercentage(outlook.volatilityBand))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.orange)
                    }
                }
                
                Spacer()
                
                // Volatility bar
                volatilityBar
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.08))
            )
            
            Text("Based on historical volatility over similar periods")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.35))
                .italic()
        }
    }
    
    private var volatilityBar: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(volatilityLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(volatilityLabelColor)
            
            // Visual bar
            HStack(spacing: 2) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < volatilityLevel ? volatilityLabelColor : Color.white.opacity(0.1))
                        .frame(width: 8, height: 16)
                }
            }
        }
    }
    
    private var volatilityLevel: Int {
        switch outlook.volatilityBand {
        case ..<0.05: return 1
        case 0.05..<0.08: return 2
        case 0.08..<0.12: return 3
        case 0.12..<0.18: return 4
        default: return 5
        }
    }
    
    private var volatilityLabel: String {
        switch volatilityLevel {
        case 1: return "Low"
        case 2: return "Moderate"
        case 3: return "Medium"
        case 4: return "High"
        default: return "Very High"
        }
    }
    
    private var volatilityLabelColor: Color {
        switch volatilityLevel {
        case 1: return .green
        case 2: return Color(red: 0.6, green: 0.8, blue: 0.4)
        case 3: return .orange
        case 4: return Color(red: 1.0, green: 0.5, blue: 0.3)
        default: return .red
        }
    }
    
    // MARK: - Historical Section
    
    private var historicalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: "How this behaved historically", icon: "clock.arrow.circlepath", color: .purple)
                
                Spacer()
                
                Button {
                    expandedInfo = .hitRate
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
            }
            
            HStack(spacing: 20) {
                // Hit rate circle
                ZStack {
                    Circle()
                        .stroke(Color.purple.opacity(0.2), lineWidth: 6)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: outlook.historicalHitRate)
                        .stroke(
                            Color.purple,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(outlook.historicalHitRate * 100))%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("of similar \(outlook.timeframeDays)-day windows")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                    
                    Text("finished higher historically")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.08))
            )
            
            Text("Past performance does not indicate future results")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.35))
                .italic()
        }
    }
    
    // MARK: - Personal Note
    
    private func personalNoteSection(_ context: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Personal note", icon: "heart.text.square", color: Color(red: 0.85, green: 0.75, blue: 0.95))
            
            Text(context)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.7))
                .italic()
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.85, green: 0.75, blue: 0.95).opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(red: 0.85, green: 0.75, blue: 0.95).opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Preference Note Card
    
    private func preferenceNoteCard(message: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .padding(.top, 2)
            
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.75))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(color.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
            
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }
    
    private var sentimentColor: Color {
        switch outlook.sentimentSummary {
        case .positive: return Color(red: 0.4, green: 0.8, blue: 0.5)
        case .mixed: return Color(red: 0.95, green: 0.75, blue: 0.3)
        case .cautious: return Color(red: 1.0, green: 0.5, blue: 0.4)
        }
    }
    
    private func formatPercentage(_ value: Double) -> String {
        let percent = value * 100
        return String(format: "%.1f%%", percent)
    }
}

// MARK: - Info Explanation Sheet

struct InfoExplanationSheet: View {
    let info: OutlookCardView.InfoType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
            
            VStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0))
                
                Text(info.rawValue)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text(info.explanation)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.10, green: 0.12, blue: 0.18))
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        OutlookCardView(outlook: Outlook(
            ticker: "NVDA",
            timeframeDays: 30,
            sentimentSummary: .positive,
            keyDrivers: [
                "AI infrastructure spending trends",
                "Next-generation chip launches",
                "Data center demand signals",
                "Momentum indicators showing strength"
            ],
            volatilityBand: 0.12,
            historicalHitRate: 0.68,
            personalContext: "You've traded NVDA 5 times with a 80% win rate — historically one of your stronger names.",
            volatilityWarning: "This ticker typically swings more than you've indicated you're comfortable with.",
            timeframeNote: nil,
            generatedAt: Date()
        ))
        .padding(20)
    }
    .background(Color(red: 0.06, green: 0.08, blue: 0.12))
}

