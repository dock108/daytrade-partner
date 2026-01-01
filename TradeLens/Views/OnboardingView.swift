//
//  OnboardingView.swift
//  TradeLens
//
//  Lightweight, skippable onboarding to capture user preferences.
//  Each answer takes one tap.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var preferencesManager = UserPreferencesManager.shared
    @Binding var isPresented: Bool
    
    @State private var currentStep = 0
    @State private var selectedTickers: Set<String> = []
    
    private let suggestedTickers = ["AAPL", "NVDA", "TSLA", "SPY", "QQQ", "AMZN", "GOOGL", "MSFT", "META", "AMD"]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.09, blue: 0.16),
                    Color(red: 0.08, green: 0.12, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button {
                        skipOnboarding()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.top, 8)
                .padding(.trailing, 8)
                
                Spacer()
                
                // Content
                TabView(selection: $currentStep) {
                    tradingStyleStep
                        .tag(0)
                    
                    riskToleranceStep
                        .tag(1)
                    
                    watchedTickersStep
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: currentStep)
                
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index == currentStep ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentStep)
                    }
                }
                .padding(.bottom, 20)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Step 1: Trading Style
    
    private var tradingStyleStep: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "clock.arrow.2.circlepath")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0))
                
                Text("How do you trade?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("This helps us show relevant timeframes")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .padding(.top, 40)
            
            // Options
            VStack(spacing: 12) {
                ForEach(UserPreferences.TradingStyle.allCases) { style in
                    optionButton(
                        title: style.rawValue,
                        subtitle: style.description,
                        icon: style.icon,
                        color: style.color,
                        isSelected: preferencesManager.preferences.tradingStyle == style
                    ) {
                        preferencesManager.updateTradingStyle(style)
                        advanceStep()
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    // MARK: - Step 2: Risk Tolerance
    
    private var riskToleranceStep: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.orange)
                
                Text("Price swings")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("How comfortable are you with volatility?")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .padding(.top, 40)
            
            // Options
            VStack(spacing: 12) {
                ForEach(UserPreferences.RiskTolerance.allCases) { tolerance in
                    optionButton(
                        title: tolerance.rawValue,
                        subtitle: tolerance.description,
                        icon: tolerance.icon,
                        color: tolerance.color,
                        isSelected: preferencesManager.preferences.riskTolerance == tolerance
                    ) {
                        preferencesManager.updateRiskTolerance(tolerance)
                        advanceStep()
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    // MARK: - Step 3: Watched Tickers
    
    private var watchedTickersStep: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(red: 0.95, green: 0.75, blue: 0.3))
                
                Text("What do you watch?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Tap any tickers you follow")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .padding(.top, 40)
            
            // Ticker chips
            FlowLayout(spacing: 10) {
                ForEach(suggestedTickers, id: \.self) { ticker in
                    tickerChip(ticker)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Done button
            Button {
                completeOnboarding()
            } label: {
                HStack(spacing: 8) {
                    Text(selectedTickers.isEmpty ? "Skip for now" : "Get Started")
                        .font(.system(size: 17, weight: .semibold))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.7, blue: 1.0),
                                    Color(red: 0.3, green: 0.5, blue: 0.9)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Components
    
    private func optionButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(color)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.1 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? color.opacity(0.5) : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(OnboardingButtonStyle())
    }
    
    private func tickerChip(_ ticker: String) -> some View {
        let isSelected = selectedTickers.contains(ticker)
        
        return Button {
            if isSelected {
                selectedTickers.remove(ticker)
            } else {
                selectedTickers.insert(ticker)
            }
        } label: {
            Text(ticker)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundStyle(isSelected ? .white : Color.white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected 
                              ? Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.3)
                              : Color.white.opacity(0.08))
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    isSelected 
                                        ? Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.5)
                                        : Color.white.opacity(0.15),
                                    lineWidth: 1
                                )
                        )
                )
        }
        .buttonStyle(OnboardingButtonStyle())
    }
    
    // MARK: - Actions
    
    private func advanceStep() {
        withAnimation {
            if currentStep < 2 {
                currentStep += 1
            }
        }
    }
    
    private func skipOnboarding() {
        preferencesManager.skipOnboarding()
        isPresented = false
    }
    
    private func completeOnboarding() {
        preferencesManager.updateWatchedTickers(Array(selectedTickers))
        preferencesManager.completeOnboarding()
        isPresented = false
    }
}

// MARK: - Button Style

struct OnboardingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(isPresented: .constant(true))
}


