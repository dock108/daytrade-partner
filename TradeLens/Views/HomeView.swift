//
//  HomeView.swift
//  TradeLens
//
//  AI-first home screen — Google for stocks.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var userSettings = UserSettings.shared
    @FocusState private var isSearchFocused: Bool
    @Namespace private var animation

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.09, blue: 0.16),
                        Color(red: 0.08, green: 0.12, blue: 0.22),
                        Color(red: 0.05, green: 0.08, blue: 0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Subtle grid pattern overlay
                gridPattern
                    .opacity(0.03)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        if viewModel.response == nil && !viewModel.isLoading {
                            // Landing state — centered search
                            Spacer()
                                .frame(height: geometry.size.height * 0.18)

                            heroSection
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))

                            searchSection
                                .padding(.top, 32)

                            suggestedChips
                                .padding(.top, 28)

                            if !viewModel.conversationHistory.isEmpty {
                                conversationHistorySection
                                    .padding(.top, 32)
                            }
                            
                            if !viewModel.recentSearches.isEmpty && viewModel.conversationHistory.isEmpty {
                                recentSearchesSection
                                    .padding(.top, 40)
                            }

                            Spacer(minLength: 100)
                        } else {
                            // Response state — search at top, article below
                            compactSearchHeader
                                .padding(.top, 16)

                            if viewModel.isLoading {
                                loadingState
                                    .padding(.top, 40)
                            } else if let response = viewModel.response {
                                articleView(response: response)
                                    .padding(.top, 24)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }

                            Spacer(minLength: 100)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.response != nil)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 12) {
            // App icon/logo area
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.7, blue: 1.0),
                                Color(red: 0.3, green: 0.5, blue: 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.4), radius: 20, y: 8)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 8)

            Text("Ask about any stock\nor market theme")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .lineSpacing(4)

            Text("Get instant context on tickers, sectors, and trends")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Search Section

    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))

                TextField("", text: $viewModel.question, prompt: Text("Search stocks, themes, or ask a question...")
                    .foregroundStyle(Color.white.opacity(0.35)))
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .tint(Color(red: 0.4, green: 0.7, blue: 1.0))
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        viewModel.submit()
                    }
                    .disabled(viewModel.isListening)

                if !viewModel.question.isEmpty && !viewModel.isListening {
                    Button {
                        viewModel.question = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.white.opacity(0.3))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Microphone button
                microphoneButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(viewModel.isListening 
                          ? Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.12) 
                          : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                viewModel.isListening
                                    ? Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.5)
                                    : (isSearchFocused
                                        ? Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.5)
                                        : Color.white.opacity(0.1)),
                                lineWidth: 1
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isListening)
            .animation(.easeInOut(duration: 0.15), value: viewModel.question.isEmpty)
            
            // Listening indicator
            if viewModel.isListening {
                listeningIndicator
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Speech error message
            if let error = viewModel.speechError {
                speechErrorBanner(error)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isListening)
    }
    
    // MARK: - Microphone Button
    
    private var microphoneButton: some View {
        Button {
            viewModel.toggleVoiceInput()
        } label: {
            ZStack {
                if viewModel.isListening {
                    // Animated recording indicator
                    Circle()
                        .fill(Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.3))
                        .frame(width: 44, height: 44)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.5 : 1.0)
                }
                
                Circle()
                    .fill(viewModel.isListening 
                          ? Color(red: 1.0, green: 0.35, blue: 0.35)
                          : Color.white.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: viewModel.isListening ? "stop.fill" : "mic.fill")
                    .font(.system(size: viewModel.isListening ? 12 : 16, weight: .medium))
                    .foregroundStyle(viewModel.isListening ? .white : Color.white.opacity(0.5))
            }
        }
        .buttonStyle(MicButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
    
    @State private var pulseAnimation = false
    
    // MARK: - Listening Indicator
    
    private var listeningIndicator: some View {
        HStack(spacing: 8) {
            // Animated waveform
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(Color(red: 1.0, green: 0.4, blue: 0.4))
                    .frame(width: 3, height: waveHeight(for: index))
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.15),
                        value: pulseAnimation
                    )
            }
            
            Text("Listening...")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(red: 1.0, green: 0.5, blue: 0.5))
            
            Spacer()
            
            Text("Tap stop when done")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.08))
        )
    }
    
    private func waveHeight(for index: Int) -> CGFloat {
        let base: CGFloat = 12
        let variation: CGFloat = pulseAnimation ? 8 : 0
        return base + (index == 1 ? variation : variation * 0.6)
    }
    
    // MARK: - Speech Error Banner
    
    private func speechErrorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.orange)
            
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.7))
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Compact Search Header (for response state)

    private var compactSearchHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.4))

            TextField("", text: $viewModel.question, prompt: Text("Search...")
                .foregroundStyle(Color.white.opacity(0.35)))
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .tint(Color(red: 0.4, green: 0.7, blue: 1.0))
                .submitLabel(.search)
                .onSubmit {
                    viewModel.submit()
                }

            if !viewModel.question.isEmpty {
                Button {
                    viewModel.clearAndReset()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.4, green: 0.7, blue: 1.0)))
                .scaleEffect(1.2)
            
            Text("Analyzing...")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Article View

    private func articleView(response: AIResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Query header
            queryHeader(response.query)
            
            // Price chart if ticker detected
            if let priceHistory = viewModel.priceHistory {
                TickerChartView(priceHistory: priceHistory)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Ticker snapshot card if info available
            if let tickerInfo = viewModel.tickerInfo {
                TickerSnapshotCard(info: tickerInfo)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Outlook card if applicable
            if let outlook = viewModel.outlook {
                OutlookCardView(outlook: outlook)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .padding(.top, 8)
            }
            
            // Section cards
            ForEach(Array(response.sections.enumerated()), id: \.element.id) { index, section in
                sectionCard(section: section)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
            }
            
            // Timestamp
            HStack {
                Spacer()
                Text(response.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .padding(.top, 8)
            
            // Disclaimer footer
            disclaimerFooter
        }
    }
    
    // MARK: - Disclaimer Footer
    
    private var disclaimerFooter: some View {
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

    private func queryHeader(_ query: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.7, blue: 1.0),
                                Color(red: 0.3, green: 0.5, blue: 0.9)
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
                    
                    if userSettings.isSimpleModeEnabled {
                        simpleModeIndicator
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
    
    private var simpleModeIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 9, weight: .bold))
            Text("Simple")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(Color(red: 0.5, green: 0.85, blue: 0.6))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color(red: 0.5, green: 0.85, blue: 0.6).opacity(0.15))
        )
    }

    private func sectionCard(section: AIResponse.Section) -> some View {
        Group {
            if section.type == .personalNote {
                // Personal note has a softer, more subtle appearance
                personalNoteCard(section: section)
            } else {
                // Standard section card
                standardSectionCard(section: section)
            }
        }
    }
    
    private func personalNoteCard(section: AIResponse.Section) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Subtle icon
            Image(systemName: section.type.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(section.type.accentColor.opacity(0.7))
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(section.type.rawValue)
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
    
    private func standardSectionCard(section: AIResponse.Section) -> some View {
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
                
                Text(section.type.rawValue)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(section.type.accentColor)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            // Content
            Text(section.content)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.85))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
            
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

    // MARK: - Guided Suggestions

    private var suggestedChips: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Try asking")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.white.opacity(0.4))
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(spacing: 10) {
                ForEach(viewModel.guidedSuggestions) { suggestion in
                    Button {
                        viewModel.selectSuggestion(suggestion)
                    } label: {
                        HStack(spacing: 12) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(iconColor(for: suggestion.category).opacity(0.15))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: suggestion.icon)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(iconColor(for: suggestion.category))
                            }
                            
                            // Text
                            Text(suggestion.text)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .lineLimit(1)
                            
                            Spacer()
                            
                            // Arrow
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.25))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(SuggestionButtonStyle())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func iconColor(for category: HomeViewModel.GuidedSuggestion.Category) -> Color {
        switch category {
        case .ticker:
            return Color(red: 0.4, green: 0.7, blue: 1.0)
        case .market:
            return Color(red: 0.9, green: 0.7, blue: 0.3)
        case .learning:
            return Color(red: 0.5, green: 0.85, blue: 0.6)
        }
    }

    // MARK: - Conversation History
    
    private var conversationHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.7))
                    
                    Text("Recent Questions")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                
                Spacer()
            }
            
            VStack(spacing: 10) {
                ForEach(viewModel.conversationHistory.prefix(5)) { entry in
                    conversationEntryCard(entry)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func conversationEntryCard(_ entry: ConversationEntry) -> some View {
        Button {
            viewModel.loadConversation(entry)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Question
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.6))
                        .padding(.top, 2)
                    
                    Text(entry.question)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                
                // Metadata row
                HStack(spacing: 12) {
                    // Ticker badge if detected
                    if let ticker = entry.detectedTicker {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 9))
                            Text(ticker)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(Color(red: 0.5, green: 0.85, blue: 0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.5, green: 0.85, blue: 0.6).opacity(0.12))
                        )
                    }
                    
                    Spacer()
                    
                    // Timestamp
                    Text(relativeTimeString(entry.timestamp))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.35))
                    
                    // Arrow
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.25))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ConversationCardButtonStyle())
    }
    
    private func relativeTimeString(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }

    // MARK: - Recent Searches

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.white.opacity(0.4))
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                Button {
                    viewModel.clearRecentSearches()
                } label: {
                    Text("Clear")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.3))
                }
            }

            VStack(spacing: 0) {
                ForEach(viewModel.recentSearches, id: \.self) { search in
                    Button {
                        viewModel.selectRecentSearch(search)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.white.opacity(0.3))

                            Text(search)
                                .font(.system(size: 15))
                                .foregroundStyle(Color.white.opacity(0.7))
                                .lineLimit(1)

                            Spacer()

                            Image(systemName: "arrow.up.left")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.2))
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)

                    if search != viewModel.recentSearches.last {
                        Divider()
                            .background(Color.white.opacity(0.06))
                            .padding(.leading, 44)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }

    // MARK: - Grid Pattern

    private var gridPattern: some View {
        Canvas { context, size in
            let gridSize: CGFloat = 40
            let path = Path { path in
                for x in stride(from: 0, through: size.width, by: gridSize) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                for y in stride(from: 0, through: size.height, by: gridSize) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
            }
            context.stroke(path, with: .color(.white), lineWidth: 0.5)
        }
    }
}

// MARK: - Flow Layout for Chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return CGSize(width: containerWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
    }
}

// MARK: - Button Styles

struct SuggestionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct MicButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct ConversationCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    HomeView()
}
