//
//  SettingsView.swift
//  TradeLens
//
//  Settings and data import view — uses InfoCardView for consistent styling.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var userSettings = UserSettings.shared
    @ObservedObject private var historyService = ConversationHistoryService.shared
    @State private var showClearHistoryAlert = false
    @State private var devModeTapCount = 0
    @State private var isDevModeToggleUnlocked = false

    var body: some View {
        ScreenContainerView(
            title: "Settings",
            subtitle: "Preferences and data management"
        ) {
            VStack(alignment: .leading, spacing: 24) {
                aiResponsesSection
                historySection
                importSection
                comingSoonSection
                appInfoSection
                if isDevModeToggleVisible {
                    developerSection
                }
            }
        }
    }
    
    // MARK: - AI Responses Section
    
    private var aiResponsesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScreenSectionHeader("AI Responses", icon: "brain")
            
            InfoCardView {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.colors.accentGreenMuted.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.colors.accentGreenMuted)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Simple Explanations")
                            .font(Theme.typography.rowTitle)
                            .foregroundStyle(Theme.colors.textPrimary)
                        
                        Text("Plain English, no jargon, helpful analogies")
                            .font(Theme.typography.rowSubtitle)
                            .foregroundStyle(Theme.colors.textTertiary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $userSettings.isSimpleModeEnabled)
                        .tint(Theme.colors.accentGreenMuted)
                        .labelsHidden()
                }
            }
            
            // Footer text
            Text("When enabled, TradeLens explains things in a way anyone can understand.")
                .font(Theme.typography.disclaimer)
                .foregroundStyle(Theme.colors.textMuted)
                .padding(.horizontal, 4)
        }
    }
    
    // MARK: - History Section
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScreenSectionHeader("Conversation History", icon: "bubble.left.and.bubble.right.fill")
            
            InfoCardView {
                Button {
                    showClearHistoryAlert = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Theme.colors.accentRed.opacity(0.15))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "trash.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Theme.colors.accentRed)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Clear History")
                                .font(Theme.typography.rowTitle)
                                .foregroundStyle(Theme.colors.textPrimary)
                            
                            Text("\(historyService.count) questions saved")
                                .font(Theme.typography.rowSubtitle)
                                .foregroundStyle(Theme.colors.textTertiary)
                        }
                        
                        Spacer()
                        
                        if historyService.count > 0 {
                            Image(systemName: "chevron.right")
                                .font(Theme.typography.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.colors.textQuaternary)
                        }
                    }
                }
                .buttonStyle(RowButtonStyle())
                .disabled(historyService.count == 0)
                .opacity(historyService.count == 0 ? 0.5 : 1.0)
            }
            
            Text("Your questions and answers are stored locally on this device. No account needed.")
                .font(Theme.typography.disclaimer)
                .foregroundStyle(Theme.colors.textMuted)
                .padding(.horizontal, 4)
        }
        .alert("Clear Conversation History?", isPresented: $showClearHistoryAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                historyService.clearHistory()
            }
        } message: {
            Text("This will remove all \(historyService.count) saved questions and answers. This cannot be undone.")
        }
    }
    
    // MARK: - Import Section
    
    private var importSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScreenSectionHeader("Import Trades", icon: "square.and.arrow.down.fill")
            
            InfoCardView(accent: Theme.colors.textQuaternary) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.colors.textQuaternary.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.colors.textQuaternary)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text("Import Trade History")
                                .font(Theme.typography.rowTitle)
                                .foregroundStyle(Theme.colors.textSecondary)
                            
                            Text("Planned")
                                .font(Theme.typography.tiny)
                                .fontWeight(.medium)
                                .foregroundStyle(Theme.colors.accentPurple)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Theme.colors.accentPurple.opacity(0.15))
                                )
                        }
                        
                        Text("Brokerage connections are not available in this version")
                            .font(Theme.typography.rowSubtitle)
                            .foregroundStyle(Theme.colors.textTertiary)
                    }
                    
                    Spacer()
                }
            }
            
            Text("Future updates will support importing trades from Fidelity, Schwab, and other brokerages.")
                .font(Theme.typography.disclaimer)
                .foregroundStyle(Theme.colors.textMuted)
                .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Coming Soon Section
    
    private var comingSoonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScreenSectionHeader("Coming Soon", icon: "sparkles")
            
            InfoCardView(accent: Theme.colors.accentPurple) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Theme.colors.accentPurple.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Theme.colors.accentPurple)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Brokerage Integration")
                            .font(Theme.typography.rowTitle)
                            .foregroundStyle(Theme.colors.textPrimary)
                        
                        Text("Fidelity, Schwab, and more coming soon")
                            .font(Theme.typography.rowSubtitle)
                            .foregroundStyle(Theme.colors.textTertiary)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScreenSectionHeader("About", icon: "info.circle.fill")
            
            InfoCardView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("TradeLens")
                            .font(Theme.typography.cardTitle)
                            .foregroundStyle(Theme.colors.textPrimary)
                        
                        Spacer()
                        
                        Text("Version 1.0")
                            .font(Theme.typography.bodySmall)
                            .foregroundStyle(Theme.colors.textTertiary)
                            .onTapGesture {
                                handleDevModeTap()
                            }
                    }
                    
                    Text("Your personal trading companion. Explains markets, tracks patterns, and helps you learn — without giving financial advice.")
                        .font(Theme.typography.bodySmall)
                        .foregroundStyle(Theme.colors.textSecondary)
                        .lineSpacing(3)
                }
            }
            
            // Data footnote
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.colors.textMuted)
                
                Text("Current version uses only public market data and AI explanations.")
                    .font(Theme.typography.disclaimer)
                    .foregroundStyle(Theme.colors.textMuted)
            }
            .padding(.horizontal, 4)
        }
    }

    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScreenSectionHeader("Developer", icon: "wrench.and.screwdriver.fill")

            InfoCardView {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.colors.accentPurple.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: "ladybug.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.colors.accentPurple)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Developer Mode")
                            .font(Theme.typography.rowTitle)
                            .foregroundStyle(Theme.colors.textPrimary)

                        Text("Show consistency diagnostics on the home screen")
                            .font(Theme.typography.rowSubtitle)
                            .foregroundStyle(Theme.colors.textTertiary)
                    }

                    Spacer()

                    Toggle("", isOn: $userSettings.isDevModeEnabled)
                        .tint(Theme.colors.accentPurple)
                        .labelsHidden()
                }
            }
        }
    }

    private var isDevModeToggleVisible: Bool {
        isDevModeToggleUnlocked || userSettings.isDevModeEnabled
    }

    private func handleDevModeTap() {
        guard !isDevModeToggleUnlocked else { return }
        devModeTapCount += 1
        if devModeTapCount >= 5 {
            isDevModeToggleUnlocked = true
        }
    }
}

#Preview {
    SettingsView()
}
