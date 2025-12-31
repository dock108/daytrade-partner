//
//  SettingsView.swift
//  TradeLens
//
//  Settings and data import view — uses InfoCardView for consistent styling.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject private var userSettings = UserSettings.shared
    @ObservedObject private var historyService = ConversationHistoryService.shared
    @State private var showClearHistoryAlert = false

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
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Theme.colors.textPrimary)
                        
                        Text("Plain English, no jargon, helpful analogies")
                            .font(.system(size: 12))
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
                .font(.system(size: 12))
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
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Theme.colors.textPrimary)
                            
                            Text("\(historyService.count) questions saved")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.colors.textTertiary)
                        }
                        
                        Spacer()
                        
                        if historyService.count > 0 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.colors.textQuaternary)
                        }
                    }
                }
                .buttonStyle(InfoCardRowButtonStyle())
                .disabled(historyService.count == 0)
                .opacity(historyService.count == 0 ? 0.5 : 1.0)
            }
            
            Text("Your questions and answers are stored locally on this device. No account needed.")
                .font(.system(size: 12))
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
            ScreenSectionHeader("Data Import", icon: "square.and.arrow.down.fill")
            
            InfoCardView {
                VStack(spacing: 0) {
                    Button {
                        Task {
                            await viewModel.importTrades()
                        }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Theme.colors.accentBlue.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                if viewModel.isImporting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.colors.accentBlue))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "doc.badge.plus")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(Theme.colors.accentBlue)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Import Mock Trades")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Theme.colors.textPrimary)
                                
                                Text("Load sample data for testing")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.colors.textTertiary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.colors.textQuaternary)
                        }
                    }
                    .buttonStyle(InfoCardRowButtonStyle())
                    .disabled(viewModel.isImporting)
                    
                    // Import status
                    if let status = viewModel.importStatusMessage {
                        Divider()
                            .background(Theme.colors.divider)
                            .padding(.leading, 54)
                        
                        HStack(spacing: 10) {
                            Image(systemName: status.contains("Error") ? "xmark.circle.fill" : "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(status.contains("Error") ? Theme.colors.accentRed : Theme.colors.accentGreen)
                            
                            Text(status)
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.colors.textSecondary)
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 4)
                    }
                    
                    // Import details
                    if !viewModel.importDetails.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(viewModel.importDetails, id: \.self) { detail in
                                Text("• \(detail)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.colors.textTertiary)
                            }
                        }
                        .padding(.leading, 54)
                        .padding(.top, 8)
                    }
                }
            }
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
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Theme.colors.textPrimary)
                        
                        Text("Fidelity, Schwab, and more coming soon")
                            .font(.system(size: 12))
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
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.colors.textPrimary)
                        
                        Spacer()
                        
                        Text("Version 1.0")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.colors.textTertiary)
                    }
                    
                    Text("Your personal trading companion. Explains markets, tracks patterns, and helps you learn — without giving financial advice.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.colors.textSecondary)
                        .lineSpacing(3)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
