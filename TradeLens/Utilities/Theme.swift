//
//  Theme.swift
//  TradeLens
//
//  Centralized theme system for consistent styling across the app.
//  Update colors here to change the entire app appearance.
//

import SwiftUI

// MARK: - App Theme

/// Central theme configuration for TradeLens
/// All color references should use Theme.colors instead of direct Color literals
struct Theme {
    
    // MARK: - Singleton Access
    
    static let colors = ThemeColors()
    static let spacing = ThemeSpacing()
    static let cornerRadius = ThemeCornerRadius()
    static let typography = ThemeTypography()
    
    // MARK: - Theme Colors
    
    struct ThemeColors {
        
        // MARK: - Backgrounds
        
        /// Primary app background - slightly lighter than before for better readability
        var backgroundPrimary: Color {
            Color(red: 0.08, green: 0.10, blue: 0.16)
        }
        
        /// Secondary background for depth layering
        var backgroundSecondary: Color {
            Color(red: 0.06, green: 0.08, blue: 0.14)
        }
        
        /// Tertiary/deepest background
        var backgroundTertiary: Color {
            Color(red: 0.05, green: 0.07, blue: 0.12)
        }
        
        /// Gradient for main background
        var backgroundGradient: LinearGradient {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.11, blue: 0.18),
                    Color(red: 0.10, green: 0.13, blue: 0.22),
                    Color(red: 0.07, green: 0.09, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        // MARK: - Cards
        
        /// Card background fill
        var cardBackground: Color {
            Color.white.opacity(0.05)
        }
        
        /// Card background for elevated/featured cards
        var cardBackgroundElevated: Color {
            Color.white.opacity(0.08)
        }
        
        /// Card border color
        var cardBorder: Color {
            Color.white.opacity(0.08)
        }
        
        /// Card border for elevated cards
        var cardBorderElevated: Color {
            Color.white.opacity(0.12)
        }
        
        /// Shadow color for cards
        var shadow: Color {
            Color.black.opacity(0.25)
        }
        
        /// Gradient for premium/featured card backgrounds
        func cardGradient(accent: Color) -> LinearGradient {
            LinearGradient(
                colors: [
                    accent.opacity(0.08),
                    accent.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        // MARK: - Accent Colors
        
        /// Primary accent - used for interactive elements, links, highlights
        var accentBlue: Color {
            Color(red: 0.40, green: 0.70, blue: 1.00)
        }
        
        /// Secondary blue - slightly darker for contrast
        var accentBlueDark: Color {
            Color(red: 0.30, green: 0.50, blue: 0.90)
        }
        
        /// Success/positive accent
        var accentGreen: Color {
            Color(red: 0.40, green: 0.80, blue: 0.50)
        }
        
        /// Muted green for less emphasis
        var accentGreenMuted: Color {
            Color(red: 0.50, green: 0.85, blue: 0.60)
        }
        
        /// Warning/attention accent
        var accentOrange: Color {
            Color(red: 1.00, green: 0.70, blue: 0.30)
        }
        
        /// Warm/gold accent for special highlights
        var accentGold: Color {
            Color(red: 0.95, green: 0.85, blue: 0.55)
        }
        
        /// Caution/alert accent
        var accentRed: Color {
            Color(red: 1.00, green: 0.50, blue: 0.40)
        }
        
        /// Purple accent for insights/personal
        var accentPurple: Color {
            Color(red: 0.70, green: 0.50, blue: 0.90)
        }
        
        /// Soft purple for personal notes
        var accentPurpleSoft: Color {
            Color(red: 0.85, green: 0.75, blue: 0.95)
        }
        
        /// Teal accent for recap/summary
        var accentTeal: Color {
            Color(red: 0.30, green: 0.80, blue: 0.70)
        }
        
        // MARK: - Text Colors
        
        /// Primary text - white with high opacity
        var textPrimary: Color {
            Color.white
        }
        
        /// Secondary text - slightly dimmed
        var textSecondary: Color {
            Color.white.opacity(0.85)
        }
        
        /// Tertiary text - labels, captions
        var textTertiary: Color {
            Color.white.opacity(0.60)
        }
        
        /// Quaternary text - hints, placeholders
        var textQuaternary: Color {
            Color.white.opacity(0.40)
        }
        
        /// Muted text - subtle info
        var textMuted: Color {
            Color.white.opacity(0.25)
        }
        
        // MARK: - Interactive States
        
        /// Divider/separator color
        var divider: Color {
            Color.white.opacity(0.08)
        }
        
        /// Grid/pattern overlay
        var gridPattern: Color {
            Color.white.opacity(0.03)
        }
        
        // MARK: - Semantic Colors
        
        /// Positive/up trend
        var positive: Color { accentGreen }
        
        /// Negative/down trend
        var negative: Color { accentRed }
        
        /// Neutral/mixed
        var neutral: Color { accentOrange }
        
        /// Cautious/warning
        var cautious: Color { accentOrange }
        
        // MARK: - Section Accent Colors
        
        var sectionCurrentSituation: Color { accentBlue }
        var sectionKeyDrivers: Color { Color(red: 0.6, green: 0.8, blue: 0.4) }
        var sectionRiskOpportunity: Color { accentOrange }
        var sectionHistorical: Color { accentPurple }
        var sectionRecap: Color { accentTeal }
        var sectionPersonal: Color { accentPurpleSoft }
        var sectionDigest: Color { accentGold }
    }
    
    // MARK: - Spacing
    
    struct ThemeSpacing {
        let xxs: CGFloat = 4
        let xs: CGFloat = 8
        let sm: CGFloat = 12
        let md: CGFloat = 16
        let lg: CGFloat = 20
        let xl: CGFloat = 24
        let xxl: CGFloat = 32
        let xxxl: CGFloat = 40
    }
    
    // MARK: - Corner Radius
    
    struct ThemeCornerRadius {
        let sm: CGFloat = 8
        let md: CGFloat = 12
        let lg: CGFloat = 16
        let xl: CGFloat = 20
        let pill: CGFloat = 100
    }
    
    // MARK: - Typography
    
    struct ThemeTypography {
        
        // MARK: - Screen Titles
        
        /// Large screen title (28pt bold, rounded)
        var screenTitle: Font {
            .system(size: 28, weight: .bold, design: .rounded)
        }
        
        /// Screen subtitle (15pt regular)
        var screenSubtitle: Font {
            .system(size: 15, weight: .regular)
        }
        
        // MARK: - Section Headers
        
        /// Section header - uppercase label style (11pt medium, tracked)
        var sectionHeader: Font {
            .system(size: 11, weight: .medium)
        }
        
        /// Card title inside cards (15pt semibold)
        var cardTitle: Font {
            .system(size: 15, weight: .semibold)
        }
        
        /// Card subtitle (12pt regular)
        var cardSubtitle: Font {
            .system(size: 12, weight: .regular)
        }
        
        // MARK: - Body Text
        
        /// Primary body text (14pt regular, with line spacing)
        var body: Font {
            .system(size: 14, weight: .regular)
        }
        
        /// Secondary body text (13pt regular)
        var bodySmall: Font {
            .system(size: 13, weight: .regular)
        }
        
        /// Emphasized body text (14pt medium)
        var bodyEmphasis: Font {
            .system(size: 14, weight: .medium)
        }
        
        // MARK: - Data Display
        
        /// Large stat value (22pt bold, rounded)
        var statLarge: Font {
            .system(size: 22, weight: .bold, design: .rounded)
        }
        
        /// Medium stat value (20pt bold, rounded)
        var statMedium: Font {
            .system(size: 20, weight: .bold, design: .rounded)
        }
        
        /// Small stat value (15pt semibold)
        var statSmall: Font {
            .system(size: 15, weight: .semibold)
        }
        
        /// Stat label (12pt regular)
        var statLabel: Font {
            .system(size: 12, weight: .regular)
        }
        
        // MARK: - Interactive Elements
        
        /// Row title (15pt medium)
        var rowTitle: Font {
            .system(size: 15, weight: .medium)
        }
        
        /// Row subtitle (12pt regular)
        var rowSubtitle: Font {
            .system(size: 12, weight: .regular)
        }
        
        /// Button text (14pt semibold)
        var button: Font {
            .system(size: 14, weight: .semibold)
        }
        
        /// Small button/chip text (13pt medium)
        var buttonSmall: Font {
            .system(size: 13, weight: .medium)
        }
        
        // MARK: - Captions & Labels
        
        /// Caption text (11pt regular)
        var caption: Font {
            .system(size: 11, weight: .regular)
        }
        
        /// Tiny label (10pt regular)
        var tiny: Font {
            .system(size: 10, weight: .regular)
        }
        
        /// Disclaimer/footer text (12pt regular)
        var disclaimer: Font {
            .system(size: 12, weight: .regular)
        }
        
        // MARK: - Special
        
        /// Ticker symbol (15pt semibold)
        var ticker: Font {
            .system(size: 15, weight: .semibold)
        }
        
        /// Quote/insight text (14pt regular, italic available via modifier)
        var quote: Font {
            .system(size: 14, weight: .regular)
        }
    }
}

// MARK: - App Grid Background View

/// Reusable background view with gradient and subtle grid pattern
/// Use this as the base background for all screens
struct AppGridBackgroundView: View {
    var showGrid: Bool = true
    var gridOpacity: Double = 0.03
    
    var body: some View {
        ZStack {
            // Gradient background
            Theme.colors.backgroundGradient
                .ignoresSafeArea()
            
            // Subtle grid pattern
            if showGrid {
                GridPatternView()
                    .opacity(gridOpacity)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Grid Pattern View

/// Canvas-based grid pattern for subtle texture
struct GridPatternView: View {
    var gridSize: CGFloat = 40
    var lineWidth: CGFloat = 0.5
    var color: Color = .white
    
    var body: some View {
        Canvas { context, size in
            let path = Path { path in
                // Vertical lines
                for x in stride(from: 0, through: size.width, by: gridSize) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                // Horizontal lines
                for y in stride(from: 0, through: size.height, by: gridSize) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
            }
            context.stroke(path, with: .color(color), lineWidth: lineWidth)
        }
    }
}

// MARK: - Themed Card Modifier

/// Apply consistent card styling
struct ThemedCardModifier: ViewModifier {
    var elevated: Bool = false
    var accentColor: Color? = nil
    var cornerRadius: CGFloat = Theme.cornerRadius.lg
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        accentColor != nil
                            ? Theme.colors.cardGradient(accent: accentColor!)
                            : LinearGradient(colors: [elevated ? Theme.colors.cardBackgroundElevated : Theme.colors.cardBackground], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                accentColor != nil
                                    ? accentColor!.opacity(0.2)
                                    : (elevated ? Theme.colors.cardBorderElevated : Theme.colors.cardBorder),
                                lineWidth: 1
                            )
                    )
            )
    }
}

// MARK: - View Extension

extension View {
    /// Apply themed card styling
    func themedCard(elevated: Bool = false, accent: Color? = nil, cornerRadius: CGFloat = Theme.cornerRadius.lg) -> some View {
        modifier(ThemedCardModifier(elevated: elevated, accentColor: accent, cornerRadius: cornerRadius))
    }
    
    /// Apply interactive press effect to any view
    func pressable(isPressed: Bool) -> some View {
        self
            .opacity(isPressed ? 0.85 : 1.0)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isPressed)
    }
    
    /// Apply subtle highlight effect
    func highlightable(isHighlighted: Bool) -> some View {
        self
            .brightness(isHighlighted ? 0.05 : 0)
            .animation(.easeOut(duration: 0.1), value: isHighlighted)
    }
}

// MARK: - Interactive Button Styles

/// Premium button style with subtle press animation
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.98
    var opacity: CGFloat = 0.85
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? opacity : 1.0)
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Card button style with background highlight
struct CardButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 20
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(configuration.isPressed ? Color.white.opacity(0.03) : Color.clear)
            )
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Row button style with subtle highlight
struct RowButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 12
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(configuration.isPressed ? Theme.colors.cardBackgroundElevated : Color.clear)
            )
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Chip/pill button style
struct ChipButtonStyle: ButtonStyle {
    var activeColor: Color = Theme.colors.accentBlue
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Icon button style (for mic, clear, etc)
struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Tab/segment style
struct SegmentButtonStyle: ButtonStyle {
    var isSelected: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Suggestion row button style
struct SuggestionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Microphone button style with circular shape
struct MicButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Conversation history card button style
struct ConversationCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .brightness(configuration.isPressed ? 0.03 : 0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Flow Layout

/// Layout that wraps elements to the next line when they exceed container width
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

// MARK: - Preview

#Preview("Theme Colors") {
    ScrollView {
        VStack(spacing: 20) {
            // Accent colors showcase
            VStack(alignment: .leading, spacing: 12) {
                Text("Accent Colors")
                    .font(.headline)
                    .foregroundStyle(Theme.colors.textPrimary)
                
                HStack(spacing: 12) {
                    colorSwatch("Blue", Theme.colors.accentBlue)
                    colorSwatch("Green", Theme.colors.accentGreen)
                    colorSwatch("Orange", Theme.colors.accentOrange)
                    colorSwatch("Gold", Theme.colors.accentGold)
                }
                
                HStack(spacing: 12) {
                    colorSwatch("Red", Theme.colors.accentRed)
                    colorSwatch("Purple", Theme.colors.accentPurple)
                    colorSwatch("Teal", Theme.colors.accentTeal)
                }
            }
            .padding()
            .themedCard(elevated: true)
            
            // Card examples
            VStack(alignment: .leading, spacing: 12) {
                Text("Card Styles")
                    .font(.headline)
                    .foregroundStyle(Theme.colors.textPrimary)
                
                Text("Standard card")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .themedCard()
                
                Text("Elevated card")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .themedCard(elevated: true)
                
                Text("Accent card")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .themedCard(accent: Theme.colors.accentBlue)
            }
            .padding()
        }
        .padding()
    }
    .background(AppGridBackgroundView())
}

@ViewBuilder
private func colorSwatch(_ name: String, _ color: Color) -> some View {
    VStack(spacing: 4) {
        Circle()
            .fill(color)
            .frame(width: 40, height: 40)
        Text(name)
            .font(.caption2)
            .foregroundStyle(Theme.colors.textTertiary)
    }
}

