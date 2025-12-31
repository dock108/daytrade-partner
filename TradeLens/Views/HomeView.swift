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

                            if !viewModel.recentSearches.isEmpty {
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

            if !viewModel.question.isEmpty {
                Button {
                    viewModel.question = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isSearchFocused
                                ? Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.5)
                                : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
        .animation(.easeInOut(duration: 0.15), value: viewModel.question.isEmpty)
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
        }
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

#Preview {
    HomeView()
}
