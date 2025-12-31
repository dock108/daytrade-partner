//
//  HistoricalRangeView.swift
//  TradeLens
//
//  Visual representation of typical price ranges based on historical behavior.
//  Educational, not predictive — uses plain language and avoids forecasting.
//

import SwiftUI

struct HistoricalRangeView: View {
    let ticker: String
    let timeframeDays: Int
    let volatilityBand: Double      // e.g., 0.12 for ±12%
    let historicalHitRate: Double   // e.g., 0.65 for 65% finished higher
    
    @State private var showTooltip: TooltipType? = nil
    @State private var animationProgress: CGFloat = 0
    
    enum TooltipType: String, Identifiable {
        case range = "Typical Range"
        case distribution = "Historical Distribution"
        
        var id: String { rawValue }
        
        var explanation: String {
            switch self {
            case .range:
                return "This shows the typical range of price movement based on how this ticker has behaved in similar past periods. Actual results may be very different."
            case .distribution:
                return "The shaded area shows where outcomes have historically clustered. The darker the shade, the more often results landed there. This is backward-looking only."
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(red: 0.6, green: 0.75, blue: 0.95))
                    
                    Text("Typical \(timeframeDays)-day range")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(red: 0.6, green: 0.75, blue: 0.95))
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                
                Spacer()
                
                Button {
                    showTooltip = .range
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
            }
            
            Text("Based on how \(ticker) has moved in similar past periods")
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.5))
            
            // Distribution visualization
            distributionChart
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8)) {
                        animationProgress = 1.0
                    }
                }
            
            // Range labels
            rangeLabels
            
            // Legend / explanation
            legendSection
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.6, green: 0.75, blue: 0.95).opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color(red: 0.6, green: 0.75, blue: 0.95).opacity(0.12), lineWidth: 1)
                )
        )
        .sheet(item: $showTooltip) { tooltip in
            TooltipSheet(tooltip: tooltip)
                .presentationDetents([.height(220)])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Distribution Chart
    
    private var distributionChart: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height: CGFloat = 80
            let centerX = width / 2
            
            ZStack {
                // Background gradient bands (bell curve approximation)
                bellCurveShape(width: width, height: height)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.6, green: 0.75, blue: 0.95).opacity(0.05),
                                Color(red: 0.6, green: 0.75, blue: 0.95).opacity(0.25),
                                Color(red: 0.6, green: 0.75, blue: 0.95).opacity(0.05)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(x: animationProgress, y: 1.0, anchor: .center)
                
                // Center line (current price / starting point)
                Rectangle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 2, height: height)
                    .position(x: centerX, y: height / 2)
                
                // Range markers
                // -1 sigma
                dashedLine(at: centerX - width * 0.2, height: height)
                // +1 sigma
                dashedLine(at: centerX + width * 0.2, height: height)
                
                // Typical outcome zone (based on hit rate)
                if historicalHitRate > 0.55 {
                    // Skew slightly positive
                    highlightZone(
                        startX: centerX - width * 0.05,
                        endX: centerX + width * 0.25,
                        height: height,
                        color: Color(red: 0.4, green: 0.8, blue: 0.5)
                    )
                } else if historicalHitRate < 0.45 {
                    // Skew slightly negative
                    highlightZone(
                        startX: centerX - width * 0.25,
                        endX: centerX + width * 0.05,
                        height: height,
                        color: Color(red: 1.0, green: 0.6, blue: 0.4)
                    )
                } else {
                    // Balanced
                    highlightZone(
                        startX: centerX - width * 0.15,
                        endX: centerX + width * 0.15,
                        height: height,
                        color: Color(red: 0.95, green: 0.75, blue: 0.3)
                    )
                }
                
                // "Most likely" marker
                mostLikelyMarker(centerX: centerX, width: width, height: height)
            }
        }
        .frame(height: 80)
    }
    
    private func bellCurveShape(width: CGFloat, height: CGFloat) -> Path {
        Path { path in
            let centerX = width / 2
            
            // Create a smooth bell curve approximation
            path.move(to: CGPoint(x: 0, y: height))
            
            // Left side curve
            path.addQuadCurve(
                to: CGPoint(x: centerX * 0.3, y: height * 0.7),
                control: CGPoint(x: centerX * 0.15, y: height)
            )
            path.addQuadCurve(
                to: CGPoint(x: centerX * 0.6, y: height * 0.3),
                control: CGPoint(x: centerX * 0.45, y: height * 0.5)
            )
            path.addQuadCurve(
                to: CGPoint(x: centerX, y: height * 0.1),
                control: CGPoint(x: centerX * 0.8, y: height * 0.15)
            )
            
            // Right side curve (mirror)
            path.addQuadCurve(
                to: CGPoint(x: centerX * 1.4, y: height * 0.3),
                control: CGPoint(x: centerX * 1.2, y: height * 0.15)
            )
            path.addQuadCurve(
                to: CGPoint(x: centerX * 1.7, y: height * 0.7),
                control: CGPoint(x: centerX * 1.55, y: height * 0.5)
            )
            path.addQuadCurve(
                to: CGPoint(x: width, y: height),
                control: CGPoint(x: centerX * 1.85, y: height)
            )
            
            path.closeSubpath()
        }
    }
    
    private func dashedLine(at x: CGFloat, height: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: height))
        }
        .stroke(
            Color.white.opacity(0.2),
            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
        )
        .frame(width: 1, height: height)
        .position(x: x, y: height / 2)
    }
    
    private func highlightZone(startX: CGFloat, endX: CGFloat, height: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color.opacity(0.2 * animationProgress))
            .frame(width: max(0, (endX - startX) * animationProgress), height: height * 0.6)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(color.opacity(0.4), lineWidth: 1)
            )
            .position(x: (startX + endX) / 2, y: height / 2)
    }
    
    private func mostLikelyMarker(centerX: CGFloat, width: CGFloat, height: CGFloat) -> some View {
        let offsetX: CGFloat = {
            if historicalHitRate > 0.55 {
                return width * 0.08 * (historicalHitRate - 0.5) * 2
            } else if historicalHitRate < 0.45 {
                return -width * 0.08 * (0.5 - historicalHitRate) * 2
            }
            return 0
        }()
        
        return VStack(spacing: 2) {
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 8))
                .foregroundStyle(Color.white.opacity(0.6))
            
            Text("Typical")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .position(x: centerX + offsetX, y: -5)
        .opacity(Double(animationProgress))
    }
    
    // MARK: - Range Labels
    
    private var rangeLabels: some View {
        HStack {
            // Left (downside)
            VStack(alignment: .leading, spacing: 2) {
                Text("-\(formatPercent(volatilityBand))")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(red: 1.0, green: 0.6, blue: 0.5))
                
                Text("Downside")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            
            Spacer()
            
            // Center (starting point)
            VStack(spacing: 2) {
                Text("0%")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.6))
                
                Text("Start")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            
            Spacer()
            
            // Right (upside)
            VStack(alignment: .trailing, spacing: 2) {
                Text("+\(formatPercent(volatilityBand))")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 0.5))
                
                Text("Upside")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        }
    }
    
    // MARK: - Legend Section
    
    private var legendSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            Button {
                showTooltip = .distribution
            } label: {
                HStack(spacing: 8) {
                    // Shaded area legend
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 0.6, green: 0.75, blue: 0.95).opacity(0.3))
                        .frame(width: 16, height: 12)
                    
                    Text("Shaded area = where most outcomes landed")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.5))
                    
                    Spacer()
                    
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
            }
            
            // Disclaimer
            Text("This reflects past behavior only — not a forecast of future results")
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.35))
                .italic()
        }
    }
    
    // MARK: - Helpers
    
    private func formatPercent(_ value: Double) -> String {
        return String(format: "%.0f%%", value * 100)
    }
}

// MARK: - Tooltip Sheet

struct TooltipSheet: View {
    let tooltip: HistoricalRangeView.TooltipType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
            
            VStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(red: 0.95, green: 0.75, blue: 0.3))
                
                Text(tooltip.rawValue)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text(tooltip.explanation)
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
        VStack(spacing: 20) {
            HistoricalRangeView(
                ticker: "NVDA",
                timeframeDays: 30,
                volatilityBand: 0.12,
                historicalHitRate: 0.68
            )
            
            HistoricalRangeView(
                ticker: "SPY",
                timeframeDays: 30,
                volatilityBand: 0.05,
                historicalHitRate: 0.52
            )
            
            HistoricalRangeView(
                ticker: "COIN",
                timeframeDays: 30,
                volatilityBand: 0.22,
                historicalHitRate: 0.42
            )
        }
        .padding(20)
    }
    .background(Color(red: 0.06, green: 0.08, blue: 0.12))
}

