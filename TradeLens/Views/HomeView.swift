//
//  HomeView.swift
//  TradeLens
//
//  AI-first home screen — Google for stocks.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
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
                        if viewModel.response == nil {
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
                            // Response state — search at top
                            compactSearchHeader
                                .padding(.top, 16)

                            responseSection
                                .padding(.top, 24)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))

                            Spacer(minLength: 100)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.response != nil)
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

    // MARK: - Suggested Chips

    private var suggestedChips: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Try asking")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.white.opacity(0.4))
                .textCase(.uppercase)
                .tracking(0.5)

            FlowLayout(spacing: 10) {
                ForEach(viewModel.suggestedQuestions, id: \.self) { suggestion in
                    Button {
                        viewModel.selectSuggestion(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: - Response Section

    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let response = viewModel.response {
                // Query echo
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.2))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0))
                        )

                    Text(viewModel.lastQuery)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.9))
                }
                .padding(.bottom, 8)

                // AI Response
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
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
                                .frame(width: 28, height: 28)

                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white)
                        }

                        Text("TradeLens")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }

                    Text(response)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .lineSpacing(6)
                        .padding(.leading, 38)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
            }
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

#Preview {
    HomeView()
}

