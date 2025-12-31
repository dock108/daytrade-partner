//
//  InfoCardView.swift
//  TradeLens
//
//  Standardized card component for consistent styling across the app.
//  Use this for all card-style containers to maintain visual cohesion.
//

import SwiftUI

/// A standardized card container with consistent styling
/// Use for all card-style sections throughout the app
struct InfoCardView<Content: View>: View {
    let title: String?
    let subtitle: String?
    let icon: String?
    let iconColor: Color
    let accent: Color?
    let elevated: Bool
    let content: Content
    
    init(
        title: String? = nil,
        subtitle: String? = nil,
        icon: String? = nil,
        iconColor: Color = Theme.colors.accentBlue,
        accent: Color? = nil,
        elevated: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.accent = accent
        self.elevated = elevated
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (if title provided)
            if title != nil || subtitle != nil {
                cardHeader
                    .padding(.bottom, 14)
            }
            
            // Content
            content
        }
        .padding(Theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(cardBorder)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private var cardHeader: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(iconColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                if let title = title {
                    Text(title)
                        .font(Theme.typography.cardTitle)
                        .foregroundStyle(Theme.colors.textPrimary)
                }
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Theme.typography.cardSubtitle)
                        .foregroundStyle(Theme.colors.textTertiary)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Styling
    
    private var cardBackground: some View {
        Group {
            if let accent = accent {
                LinearGradient(
                    colors: [
                        accent.opacity(0.08),
                        Theme.colors.cardBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else if elevated {
                Theme.colors.cardBackgroundElevated
            } else {
                Theme.colors.cardBackground
            }
        }
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(borderColor, lineWidth: 1)
    }
    
    private var borderColor: Color {
        if let accent = accent {
            return accent.opacity(0.2)
        }
        return Theme.colors.cardBorder
    }
    
    private var shadowColor: Color {
        Theme.colors.shadow
    }
    
    private var shadowRadius: CGFloat {
        elevated ? 12 : 6
    }
    
    private var shadowY: CGFloat {
        elevated ? 6 : 3
    }
}

// MARK: - Convenience Initializers

extension InfoCardView {
    /// Simple card with just content
    init(
        accent: Color? = nil,
        elevated: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = nil
        self.subtitle = nil
        self.icon = nil
        self.iconColor = Theme.colors.accentBlue
        self.accent = accent
        self.elevated = elevated
        self.content = content()
    }
}

// MARK: - Stat Info Card

/// Specialized card for displaying statistics
struct StatInfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection?
    let footer: String?
    
    enum TrendDirection {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "arrow.right"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return Theme.colors.accentGreen
            case .down: return Theme.colors.accentRed
            case .neutral: return Theme.colors.textTertiary
            }
        }
    }
    
    init(
        title: String,
        value: String,
        icon: String,
        color: Color = Theme.colors.accentBlue,
        trend: TrendDirection? = nil,
        footer: String? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.trend = trend
        self.footer = footer
    }
    
    var body: some View {
        InfoCardView {
            VStack(alignment: .leading, spacing: 12) {
                // Icon row
                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(color)
                    }
                    
                    Spacer()
                    
                    if let trend = trend {
                        Image(systemName: trend.icon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(trend.color)
                    }
                }
                
                // Value
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(Theme.typography.statLarge)
                        .foregroundStyle(Theme.colors.textPrimary)
                    
                    Text(title)
                        .font(Theme.typography.statLabel)
                        .foregroundStyle(Theme.colors.textTertiary)
                    
                    if let footer = footer {
                        Text(footer)
                            .font(Theme.typography.tiny)
                            .foregroundStyle(Theme.colors.textQuaternary)
                            .padding(.top, 2)
                    }
                }
            }
        }
    }
}

// MARK: - List Info Card

/// Card containing a list of rows
struct ListInfoCard<Content: View>: View {
    let title: String?
    let icon: String?
    let iconColor: Color
    let content: Content
    
    init(
        title: String? = nil,
        icon: String? = nil,
        iconColor: Color = Theme.colors.accentBlue,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        InfoCardView(
            title: title,
            icon: icon,
            iconColor: iconColor
        ) {
            content
        }
    }
}

// MARK: - Info Card Row

/// A row item for use inside ListInfoCard
struct InfoCardRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let value: String?
    let valueColor: Color?
    let showChevron: Bool
    let action: (() -> Void)?
    
    init(
        icon: String,
        iconColor: Color = Theme.colors.accentBlue,
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        valueColor: Color? = nil,
        showChevron: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.valueColor = valueColor
        self.showChevron = showChevron || action != nil
        self.action = action
    }
    
    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(iconColor)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Theme.typography.rowTitle)
                        .foregroundStyle(Theme.colors.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Theme.typography.rowSubtitle)
                            .foregroundStyle(Theme.colors.textTertiary)
                    }
                }
                
                Spacer()
                
                // Value or chevron
                if let value = value {
                    Text(value)
                        .font(Theme.typography.statSmall)
                        .foregroundStyle(valueColor ?? Theme.colors.textSecondary)
                }
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.colors.textQuaternary)
                }
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(InfoCardRowButtonStyle())
        .disabled(action == nil)
    }
}

struct InfoCardRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(configuration.isPressed ? Theme.colors.cardBackgroundElevated : Color.clear)
            )
    }
}

// MARK: - Insight Info Card

/// Specialized card for displaying insights/observations
struct InsightInfoCard: View {
    let title: String
    let subtitle: String
    let detail: String
    let icon: String
    let color: Color
    
    init(
        title: String,
        subtitle: String,
        detail: String,
        icon: String = "lightbulb.fill",
        color: Color = Theme.colors.accentPurple
    ) {
        self.title = title
        self.subtitle = subtitle
        self.detail = detail
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        InfoCardView(accent: color) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(color)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(Theme.typography.cardTitle)
                            .foregroundStyle(Theme.colors.textPrimary)
                        
                        Text(subtitle)
                            .font(Theme.typography.caption)
                            .foregroundStyle(Theme.colors.textTertiary)
                    }
                }
                
                // Detail
                Text(detail)
                    .font(Theme.typography.body)
                    .foregroundStyle(Theme.colors.textSecondary)
                    .lineSpacing(4)
            }
        }
    }
}

// MARK: - Empty State Card

/// Card for displaying empty states
struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionLabel: String?
    
    init(
        icon: String,
        title: String,
        message: String,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
        self.actionLabel = actionLabel
    }
    
    var body: some View {
        InfoCardView {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Theme.colors.textQuaternary.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.colors.textQuaternary)
                }
                
                VStack(spacing: 6) {
                    Text(title)
                        .font(Theme.typography.cardTitle)
                        .foregroundStyle(Theme.colors.textSecondary)
                    
                    Text(message)
                        .font(Theme.typography.bodySmall)
                        .foregroundStyle(Theme.colors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                
                if let action = action, let label = actionLabel {
                    Button(action: action) {
                        Text(label)
                            .font(Theme.typography.button)
                            .foregroundStyle(Theme.colors.accentBlue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Theme.colors.accentBlue.opacity(0.15))
                            )
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Preview

#Preview("Info Cards") {
    ZStack {
        AppGridBackgroundView()
        
        ScrollView {
            VStack(spacing: 20) {
                // Simple card
                InfoCardView {
                    Text("Simple content card")
                        .foregroundStyle(Theme.colors.textSecondary)
                }
                
                // Card with header
                InfoCardView(
                    title: "With Header",
                    subtitle: "And a subtitle",
                    icon: "star.fill",
                    iconColor: Theme.colors.accentGold
                ) {
                    Text("Content goes here")
                        .foregroundStyle(Theme.colors.textSecondary)
                }
                
                // Stat cards
                HStack(spacing: 12) {
                    StatInfoCard(
                        title: "Win Rate",
                        value: "68%",
                        icon: "target",
                        color: Theme.colors.accentGreen,
                        trend: .up
                    )
                    
                    StatInfoCard(
                        title: "Avg Hold",
                        value: "4.2 days",
                        icon: "clock.fill",
                        color: Theme.colors.accentBlue
                    )
                }
                
                // Insight card
                InsightInfoCard(
                    title: "Pattern Detected",
                    subtitle: "Based on your trades",
                    detail: "You tend to hold winners longer than losers, which is a positive sign.",
                    icon: "lightbulb.fill",
                    color: Theme.colors.accentGreen
                )
                
                // List card
                ListInfoCard(title: "Recent Activity", icon: "clock.arrow.circlepath") {
                    VStack(spacing: 0) {
                        InfoCardRow(
                            icon: "arrow.up.right",
                            iconColor: Theme.colors.accentGreen,
                            title: "NVDA",
                            subtitle: "3 days",
                            value: "+$245",
                            valueColor: Theme.colors.accentGreen
                        )
                        
                        Divider()
                            .background(Theme.colors.divider)
                            .padding(.leading, 54)
                        
                        InfoCardRow(
                            icon: "arrow.down.right",
                            iconColor: Theme.colors.accentRed,
                            title: "AAPL",
                            subtitle: "5 days",
                            value: "-$82",
                            valueColor: Theme.colors.accentRed
                        )
                    }
                }
                
                // Empty state
                EmptyStateCard(
                    icon: "sparkles",
                    title: "No insights yet",
                    message: "Add more trades to see patterns",
                    action: {},
                    actionLabel: "Import Trades"
                )
            }
            .padding()
        }
    }
}

