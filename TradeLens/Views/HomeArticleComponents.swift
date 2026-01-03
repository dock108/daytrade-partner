//
//  HomeArticleComponents.swift
//  TradeLens
//
//  Extracted article display components from HomeView for better organization.
//  These components render AI response sections, sources, and related content.
//

import SwiftUI

// MARK: - Query Header

/// Header displaying the search query and TradeLens branding
struct ArticleQueryHeader: View {
    let query: String
    let isSimpleModeEnabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.colors.accentBlue,
                                Theme.colors.accentBlueDark
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("TradeLens")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.6))
                    
                    if isSimpleModeEnabled {
                        SimpleModeIndicator()
                    }
                }
                
                Text(query)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Spacer()
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Simple Mode Indicator

struct SimpleModeIndicator: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 9, weight: .bold))
            Text("Simple")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(Theme.colors.accentGreenMuted)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Theme.colors.accentGreenMuted.opacity(0.15))
        )
    }
}

// MARK: - Ticker Snapshot Header

struct TickerSnapshotHeader: View {
    let snapshot: BackendModels.TickerSnapshot
    
    var body: some View {
        HStack(spacing: 10) {
            Text(snapshot.symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )

            Text(snapshot.price, format: .number.precision(.fractionLength(2)))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            Text(changePercentText)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(changePercentColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var changePercentText: String {
        let sign = snapshot.changePercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", snapshot.changePercent))%"
    }
    
    private var changePercentColor: Color {
        snapshot.changePercent >= 0 ? Theme.colors.accentGreen : Theme.colors.accentRed
    }
}

// MARK: - Digest Card

/// Special card for the main story/digest section with gold styling
struct DigestCard: View {
    let section: AIResponse.Section
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with special emphasis
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.colors.accentGold,
                                    Color(red: 0.85, green: 0.65, blue: 0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("The Story")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.colors.accentGold.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Text("Here's what's really going on")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.colors.accentGold)
                }
                
                Spacer()
            }
            
            // Content with larger, more readable text
            Text(section.content)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.9))
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.colors.accentGold.opacity(0.08),
                            Color(red: 0.85, green: 0.65, blue: 0.35).opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Theme.colors.accentGold.opacity(0.25),
                                    Color(red: 0.85, green: 0.65, blue: 0.35).opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Standard Section Card

/// Standard section card for AI response sections
struct StandardSectionCard: View {
    let section: AIResponse.Section
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(section.type.accentColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: section.type.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(section.type.accentColor)
                }
                
                Text(section.type.displayTitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(section.type.accentColor)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            // Content
            if !section.content.isEmpty {
                Text(section.content)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Bullet points if present
            if let bullets = section.bulletPoints, !bullets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(section.type.accentColor.opacity(0.6))
                                .frame(width: 5, height: 5)
                                .padding(.top, 7)
                            
                            Text(bullet)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.white.opacity(0.75))
                                .lineSpacing(3)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    section.type.accentColor.opacity(0.2),
                                    section.type.accentColor.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Personal Note Card

/// Subtle card for personal notes/insights
struct PersonalNoteCard: View {
    let section: AIResponse.Section
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Subtle icon
            Image(systemName: section.type.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(section.type.accentColor.opacity(0.7))
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(section.type.displayTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(section.type.accentColor.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(0.3)
                
                Text(section.content)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .lineSpacing(4)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(section.type.accentColor.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            section.type.accentColor.opacity(0.12),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Sources Section

/// Expandable sources and references section
struct SourcesSection: View {
    let sources: [AIResponse.SourceReference]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Expandable header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.5))
                        
                        Text("Sources & deeper reading")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Text("\(sources.count) sources")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.4))
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            
            // Expanded content
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.08))
                
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(sources) { source in
                        SourceRow(source: source)
                        
                        if source.id != sources.last?.id {
                            Divider()
                                .background(Color.white.opacity(0.05))
                                .padding(.leading, 44)
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Source Row

struct SourceRow: View {
    let source: AIResponse.SourceReference
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Type icon
            ZStack {
                Circle()
                    .fill(source.type.color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: source.type.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(source.type.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(source.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineLimit(2)
                
                // Source + type badge
                HStack(spacing: 8) {
                    Text(source.source)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.4))
                    
                    Text(source.type.rawValue)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(source.type.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(source.type.color.opacity(0.12))
                        )
                }
                
                // Summary
                Text(source.summary)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Disclaimer Footer

struct DisclaimerFooter: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .font(.system(size: 10))
            
            Text("This app explains markets — it does not recommend trades.")
                .font(.system(size: 11))
        }
        .foregroundStyle(Color.white.opacity(0.25))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.02))
        )
        .padding(.top, 16)
    }
}

// MARK: - Preview

#Preview("Article Components") {
    ZStack {
        AppGridBackgroundView()
        
        ScrollView {
            VStack(spacing: 20) {
                ArticleQueryHeader(query: "Tell me about AAPL", isSimpleModeEnabled: true)
                
                DigestCard(section: AIResponse.Section(
                    type: .digest,
                    content: "Apple is navigating a complex landscape with strong services growth offsetting hardware headwinds."
                ))
                
                DisclaimerFooter()
            }
            .padding()
        }
    }
}

