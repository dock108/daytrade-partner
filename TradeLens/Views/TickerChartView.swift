//
//  TickerChartView.swift
//  TradeLens
//
//  Inline sparkline chart for ticker searches.
//

import SwiftUI
import Charts

struct TickerChartView: View {
    let priceHistory: PriceHistory
    @State private var selectedRange: ChartTimeRange = .oneMonth
    @State private var animateChart: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with ticker info
            tickerHeader
            
            // Chart
            chartArea
                .padding(.top, 12)
            
            // Time range selector
            rangeSelector
                .padding(.top, 16)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    chartColor.opacity(0.3),
                                    chartColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateChart = true
            }
        }
    }
    
    // MARK: - Ticker Header
    
    private var tickerHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(priceHistory.ticker)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(formattedPrice)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: priceHistory.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .bold))
                    
                    Text(formattedChange)
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(chartColor)
                
                Text(formattedChangePercent)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(chartColor.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(chartColor.opacity(0.15))
            )
        }
    }
    
    // MARK: - Chart Area
    
    private var chartArea: some View {
        Chart {
            ForEach(Array(priceHistory.points.enumerated()), id: \.element.id) { index, point in
                let animatedClose = animateChart ? point.close : priceHistory.points.first?.close ?? point.close
                
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Price", animatedClose)
                )
                .foregroundStyle(chartGradient)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Time", point.date),
                    yStart: .value("Min", priceHistory.minPrice * 0.998),
                    yEnd: .value("Price", animatedClose)
                )
                .foregroundStyle(areaGradient)
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: (priceHistory.minPrice * 0.995)...(priceHistory.maxPrice * 1.005))
        .frame(height: 120)
    }
    
    // MARK: - Range Selector
    
    private var rangeSelector: some View {
        HStack(spacing: 0) {
            ForEach(ChartTimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedRange = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 13, weight: selectedRange == range ? .semibold : .medium))
                        .foregroundStyle(selectedRange == range ? .white : Color.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedRange == range ? chartColor.opacity(0.25) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Helpers
    
    private var chartColor: Color {
        priceHistory.isPositive ? Color(red: 0.3, green: 0.85, blue: 0.5) : Color(red: 1.0, green: 0.4, blue: 0.4)
    }
    
    private var chartGradient: LinearGradient {
        LinearGradient(
            colors: [chartColor, chartColor.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [chartColor.opacity(0.3), chartColor.opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var formattedPrice: String {
        "$\(String(format: "%.2f", priceHistory.currentPrice))"
    }
    
    private var formattedChange: String {
        let sign = priceHistory.change >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", abs(priceHistory.change)))"
    }
    
    private var formattedChangePercent: String {
        let sign = priceHistory.changePercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", priceHistory.changePercent))%"
    }
}

#Preview {
    ZStack {
        Color(red: 0.06, green: 0.09, blue: 0.16)
            .ignoresSafeArea()
        
        TickerChartView(
            priceHistory: MockPriceService.priceHistory(for: "NVDA")!
        )
        .padding()
    }
}

