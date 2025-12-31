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

// MARK: - Preview

#Preview {
    ScreenContainerView(
        title: "Preview",
        subtitle: "Testing the container view"
    ) {
        VStack(spacing: 20) {
            ScreenSectionHeader("Key Metrics", icon: "chart.bar.fill")
            
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
            
            ScreenSectionHeader("Recent Activity", icon: "clock.arrow.circlepath")
            
            ListInfoCard {
                VStack(spacing: 0) {
                    InfoCardRow(
                        icon: "arrow.up.right",
                        iconColor: Theme.colors.accentGreen,
                        title: "NVDA Trade",
                        subtitle: "Closed 2 days ago",
                        value: "+$245",
                        valueColor: Theme.colors.accentGreen
                    )
                    
                    Divider()
                        .background(Theme.colors.divider)
                        .padding(.leading, 54)
                    
                    InfoCardRow(
                        icon: "arrow.down.right",
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
