//
//  OutlookCardView.swift
//  TradeLens
//
//  Outlook card layout styled like Apple Health insights.
//  Friendly, calm, informational — no financial advice.
//

import SwiftUI

struct OutlookCardView: View {
    let outlook: BackendModels.Outlook
    @ObservedObject private var preferencesManager = UserPreferencesManager.shared
    @State private var expandedInfo: InfoType? = nil
    @State private var isWatchEnabled = false
    @State private var showWatchConfirmation = false
    
    enum InfoType: String, Identifiable {
        case sentiment = "Sentiment Summary"
        case volatility = "Expected Swings"
        case hitRate = "Historical Behavior"
        
        var id: String { rawValue }
        
        var explanation: String {
            switch self {
            case .sentiment:
                return "This reflects the current tone of market conditions and sector trends — context for what traders may be reacting to, not a prediction."
            case .volatility:
                return "This summarizes how jumpy the price has been in similar windows, helping you see the size of recent swings."
            case .hitRate:
                return "This shows how often similar windows finished higher in the past — a way to see the range of outcomes, not a forecast."
            }
        }
    }

    private enum SentimentTone {
        case positive
        case mixed
        case cautious
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
                
                keyDriversSection
                
                expectedSwingsSection
                
                historicalSection
                
                // Visual distribution chart - "Typical 30-day range based on past moves"
                HistoricalRangeView(
                    ticker: outlook.symbol,
                    timeframeDays: outlook.timeframeDays,
                    typicalRangePercent: normalizedTypicalRangePercent,
                    historicalHitRate: normalizedHitRate
                )
                
                // Watch This For Me - Future Hook
                watchThisButton
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
                
                Text(outlook.symbol)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(sentimentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
            Text("\(outlook.timeframeDays)-Day Outlook")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                
                HStack(spacing: 6) {
                    Image(systemName: sentimentIcon)
                        .font(.system(size: 11, weight: .semibold))
                    
                    Text(outlook.sentimentSummary)
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
                    .contentShape(Circle())
            }
            .buttonStyle(IconButtonStyle())
        }
        .padding(20)
    }
    
    // MARK: - Big Picture
    
    private var bigPictureSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Big Picture", icon: "globe.americas.fill", color: .blue)
            
            Text(outlook.sentimentSummary)
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
                        .contentShape(Circle())
                }
                .buttonStyle(IconButtonStyle())
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
                        
                        Text(formatPercentage(normalizedTypicalRangePercent))
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
            
            Text(expectedSwingsHelperText)
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
        switch normalizedTypicalRangePercent {
        case ..<0.05: return 1
        case 0.05..<0.08: return 2
        case 0.08..<0.12: return 3
        case 0.12..<0.18: return 4
        default: return 5
        }
    }
    
    private var volatilityLabel: String {
        outlook.volatilityLabel
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
                        .contentShape(Circle())
                }
                .buttonStyle(IconButtonStyle())
            }
            
            HStack(spacing: 20) {
                // Hit rate circle
                ZStack {
                    Circle()
                        .stroke(Color.purple.opacity(0.2), lineWidth: 6)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: normalizedHitRate)
                        .stroke(
                            Color.purple,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(normalizedHitRate * 100))%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("of similar \(outlook.timeframeDays)-day windows")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                    
                    Text("closed higher in the past")
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
            
            Text(historicalHelperText)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.35))
                .italic()
        }
    }
    
    // MARK: - Personal Note (Behavioral Observation)
    
    private func personalNoteSection(_ context: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with full label
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.85, green: 0.75, blue: 0.95),
                                    Color(red: 0.70, green: 0.55, blue: 0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "person.fill.viewfinder")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Personal note")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(red: 0.85, green: 0.75, blue: 0.95))
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Text("Based on your past trades")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
                
                Spacer()
            }
            
            // Divider
            Rectangle()
                .fill(Color(red: 0.85, green: 0.75, blue: 0.95).opacity(0.15))
                .frame(height: 1)
            
            // Content — reflective tone, not directive
            HStack(alignment: .top, spacing: 10) {
                // Subtle quote mark
                Image(systemName: "quote.opening")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(Color(red: 0.85, green: 0.75, blue: 0.95).opacity(0.4))
                    .padding(.top, 2)
                
                Text(context)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Supportive footer — not judgmental
            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .font(.system(size: 9))
                
                Text("Reflection, not advice — you decide what's relevant")
                    .font(.system(size: 10))
            }
            .foregroundStyle(Color.white.opacity(0.3))
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.75, blue: 0.95).opacity(0.08),
                            Color(red: 0.70, green: 0.55, blue: 0.85).opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.85, green: 0.75, blue: 0.95).opacity(0.2),
                                    Color(red: 0.70, green: 0.55, blue: 0.85).opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Watch This Button (Future Hook)
    
    private var watchThisButton: some View {
        VStack(spacing: 12) {
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
                .padding(.vertical, 8)
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isWatchEnabled.toggle()
                    if isWatchEnabled {
                        showWatchConfirmation = true
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    // Icon with animation
                    ZStack {
                        Circle()
                            .fill(
                                isWatchEnabled
                                    ? Color(red: 0.4, green: 0.7, blue: 1.0)
                                    : Color.white.opacity(0.08)
                            )
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: isWatchEnabled ? "bell.fill" : "bell")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(isWatchEnabled ? .white : Color.white.opacity(0.5))
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(isWatchEnabled ? "Watching \(outlook.symbol)" : "Watch this for me")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isWatchEnabled ? Color(red: 0.4, green: 0.7, blue: 1.0) : .white)
                        
                        Text(isWatchEnabled ? "We'll let you know if something changes" : "Get a heads-up when something important changes")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }
                    
                    Spacer()
                    
                    // Toggle indicator
                    if isWatchEnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0))
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.3))
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            isWatchEnabled
                                ? Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.12)
                                : Color.white.opacity(0.04)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(
                                    isWatchEnabled
                                        ? Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.3)
                                        : Color.white.opacity(0.08),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(WatchButtonStyle())
            
            // Explanation text (subtle)
            if !isWatchEnabled {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                    
                    Text("Coming soon: heads-ups for major moves, earnings, or sentiment shifts")
                        .font(.system(size: 11))
                }
                .foregroundStyle(Color.white.opacity(0.3))
                .frame(maxWidth: .infinity)
            }
        }
        .alert("Watching \(outlook.symbol)", isPresented: $showWatchConfirmation) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("This feature is coming soon! When it's ready, you'll get a gentle heads-up if:\n\n• A major price move happens\n• Earnings are approaching\n• Market sentiment shifts\n\nNo spam — just the important stuff.")
        }
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
        switch sentimentTone {
        case .positive: return Color(red: 0.4, green: 0.8, blue: 0.5)
        case .mixed: return Color(red: 0.95, green: 0.75, blue: 0.3)
        case .cautious: return Color(red: 1.0, green: 0.5, blue: 0.4)
        }
    }

    private var sentimentIcon: String {
        switch sentimentTone {
        case .positive: return "arrow.up.right.circle.fill"
        case .mixed: return "arrow.left.arrow.right.circle.fill"
        case .cautious: return "exclamationmark.triangle.fill"
        }
    }

    private var sentimentTone: SentimentTone {
        let value = outlook.sentimentSummary.lowercased()
        if value.contains("positive") || value.contains("bull") || value.contains("constructive") {
            return .positive
        }
        if value.contains("cautious") || value.contains("negative") || value.contains("bear") {
            return .cautious
        }
        return .mixed
    }

    private var normalizedTypicalRangePercent: Double {
        normalizePercent(outlook.typicalRangePercent)
    }

    private var normalizedHitRate: Double {
        normalizePercent(outlook.historicalHitRate)
    }
    
    private func formatPercentage(_ value: Double) -> String {
        let percent = value * 100
        return String(format: "%.1f%%", percent)
    }

    private func normalizePercent(_ value: Double) -> Double {
        if value > 1 {
            return value / 100
        }
        return value
    }

    private var isRiskAverse: Bool {
        preferencesManager.preferences.riskTolerance == .low
    }

    private var expectedSwingsHelperText: String {
        isRiskAverse
            ? "Based on past ranges to keep the context gentle."
            : "Based on how swingy the price has been in similar periods"
    }

    private var historicalHelperText: String {
        isRiskAverse
            ? "Past outcomes are just context, not a forecast"
            : "Past outcomes are context, not a forecast"
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

// MARK: - Watch Button Style

struct WatchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .brightness(configuration.isPressed ? 0.05 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        OutlookCardView(outlook: BackendModels.Outlook(
            symbol: "NVDA",
            timeframeDays: 30,
            historicalHitRate: 0.68,
            typicalRangePercent: 0.12,
            volatilityLabel: "High",
            keyDrivers: [
                "AI infrastructure spending trends",
                "Next-generation chip launches",
                "Data center demand signals",
                "Momentum indicators showing recent strength"
            ]
        ))
        .padding(20)
    }
    .background(Color(red: 0.06, green: 0.08, blue: 0.12))
}
