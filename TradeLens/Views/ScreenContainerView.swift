//
//  ScreenContainerView.swift
//  TradeLens
//
//  Reusable container view that provides consistent layout across all screens.
//  Includes themed background, safe area handling, and standard padding.
//

import SwiftUI

/// Container view that wraps screen content with consistent styling
/// Use this to ensure all tabs have the same visual structure as Home
struct ScreenContainerView<Content: View>: View {
    let title: String
    let subtitle: String?
    let showsBackButton: Bool
    let content: Content
    
    @Environment(\.dismiss) private var dismiss
    
    init(
        title: String,
        subtitle: String? = nil,
        showsBackButton: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showsBackButton = showsBackButton
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Themed background with grid
            AppGridBackgroundView()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header section
                    headerSection
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    
                    // Main content
                    content
                }
                .padding(.horizontal, Theme.spacing.lg)
                .padding(.bottom, 100) // Safe area for tab bar
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showsBackButton {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(Theme.colors.accentBlue)
                }
                .padding(.bottom, 12)
            }
            
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.colors.textPrimary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Section Header

/// Reusable section header for consistent styling
struct ScreenSectionHeader: View {
    let title: String
    let icon: String?
    let action: (() -> Void)?
    let actionLabel: String?
    
    init(
        _ title: String,
        icon: String? = nil,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.actionLabel = actionLabel
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.colors.accentBlue.opacity(0.7))
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.colors.textQuaternary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            Spacer()
            
            if let action = action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(Theme.colors.textQuaternary)
                }
            }
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Screen Card

/// Reusable card wrapper for consistent card styling
struct ScreenCard<Content: View>: View {
    let accent: Color?
    let elevated: Bool
    let content: Content
    
    init(
        accent: Color? = nil,
        elevated: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.accent = accent
        self.elevated = elevated
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(Theme.spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .themedCard(elevated: elevated, accent: accent)
    }
}

// MARK: - Screen Row

/// Reusable row for list-style content
struct ScreenRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let value: String?
    let valueColor: Color?
    let action: (() -> Void)?
    
    init(
        icon: String,
        iconColor: Color = Theme.colors.accentBlue,
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        valueColor: Color? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.valueColor = valueColor
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
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(iconColor)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.colors.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.colors.textTertiary)
                    }
                }
                
                Spacer()
                
                // Value or chevron
                if let value = value {
                    Text(value)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(valueColor ?? Theme.colors.textSecondary)
                } else if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.colors.textQuaternary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
        }
        .buttonStyle(ScreenRowButtonStyle())
        .disabled(action == nil)
    }
}

struct ScreenRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius.md)
                    .fill(configuration.isPressed ? Theme.colors.cardBackgroundElevated : Color.clear)
            )
    }
}

// MARK: - Stat Card

/// Compact stat display card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection?
    
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
        trend: TrendDirection? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.trend = trend
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(color)
                }
                
                Spacer()
                
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(trend.color)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.colors.textPrimary)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.colors.textTertiary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard()
    }
}

// MARK: - Preview

#Preview {
    ScreenContainerView(
        title: "Insights",
        subtitle: "Your trading patterns and behavior"
    ) {
        VStack(spacing: 20) {
            ScreenSectionHeader("Key Metrics", icon: "chart.bar.fill")
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Win Rate",
                    value: "68%",
                    icon: "target",
                    color: Theme.colors.accentGreen,
                    trend: .up
                )
                
                StatCard(
                    title: "Avg Hold",
                    value: "4.2 days",
                    icon: "clock.fill",
                    color: Theme.colors.accentBlue
                )
            }
            
            ScreenSectionHeader("Recent Activity", icon: "clock.arrow.circlepath")
            
            ScreenCard {
                VStack(spacing: 0) {
                    ScreenRow(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: Theme.colors.accentGreen,
                        title: "NVDA Trade",
                        subtitle: "Closed 2 days ago",
                        value: "+$245",
                        valueColor: Theme.colors.accentGreen
                    )
                    
                    Divider()
                        .background(Theme.colors.divider)
                    
                    ScreenRow(
                        icon: "chart.line.downtrend.xyaxis",
                        iconColor: Theme.colors.accentRed,
                        title: "AAPL Trade",
                        subtitle: "Closed 5 days ago",
                        value: "-$82",
                        valueColor: Theme.colors.accentRed
                    )
                }
            }
        }
    }
}

