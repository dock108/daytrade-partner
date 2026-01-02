//
//  TickerSnapshotCard.swift
//  TradeLens
//
//  Knowledge panel card for ticker information.
//

import SwiftUI

struct TickerSnapshotCard: View {
    let info: TickerInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            header
            
            // Info grid
            infoGrid
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
            
            // Summary
            summarySection
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "building.2.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Ticker Snapshot")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(info.companyName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Info Grid
    
    private var infoGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                infoItem(label: "Sector", value: info.sector, icon: "square.grid.2x2")
                Spacer()
            }
            
            HStack(spacing: 16) {
                infoItem(label: "Market Cap", value: info.marketCap, icon: "chart.pie")
                
                Spacer()
                
                volatilityBadge
            }
        }
    }
    
    private func infoItem(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.3))
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .textCase(.uppercase)
                
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineLimit(1)
            }
        }
    }
    
    private var volatilityBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: info.volatility.icon)
                .font(.system(size: 11, weight: .semibold))
            
            Text(info.volatility.rawValue)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(info.volatility.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(info.volatility.color.opacity(0.15))
        )
    }
    
    // MARK: - Summary
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "doc.text")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))
                
                Text("About")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .textCase(.uppercase)
                    .tracking(0.3)
            }
            
            Text(info.summary)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.75))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.06, green: 0.09, blue: 0.16)
            .ignoresSafeArea()
        
        TickerSnapshotCard(
            info: TickerInfoService.info(for: "NVDA")!
        )
        .padding()
    }
}




