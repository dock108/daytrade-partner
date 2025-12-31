# TradeLens Project Guide

## Project Structure

The project follows a clean MVVM architecture with clear separation of concerns:

```
TradeLens/
├── TradeLens.xcodeproj/        # Xcode project configuration
└── TradeLens/                  # Main application directory
    ├── TradeLensApp.swift      # Application entry point
    ├── Info.plist              # App configuration
    │
    ├── Models/                 # Data models and business entities
    │   ├── Trade.swift         # Trade entity & MockTrade
    │   ├── AIResponse.swift    # Structured AI response model
    │   ├── ConversationHistory.swift # Chat history persistence
    │   ├── PriceData.swift     # Price chart data structures
    │   ├── TickerInfo.swift    # Ticker knowledge panel data
    │   ├── UserSummary.swift   # Trading summary analytics
    │   └── UserPreferences.swift # User settings model
    │
    ├── Services/               # Business logic and data management
    │   ├── AIServiceStub.swift # AI response generation (mock)
    │   ├── AIContentProvider.swift # Topic content for AI responses
    │   ├── OutlookEngine.swift # Market outlook synthesis
    │   ├── MockTradeDataService.swift # Mock trade generation
    │   ├── TradeAnalyticsService.swift # Trade analytics calculations
    │   ├── InsightsService.swift # Behavioral insights
    │   ├── MockPriceService.swift # Mock price data
    │   ├── TickerInfoService.swift # Ticker metadata
    │   ├── SpeechRecognitionService.swift # Voice input
    │   ├── UserSettings.swift  # Settings persistence
    │   ├── TradeService.swift  # Trade data operations
    │   └── ImportService.swift # Data import handling
    │
    ├── Views/                  # SwiftUI view components
    │   ├── ContentView.swift   # Tab navigation container
    │   ├── HomeView.swift      # AI-first home screen
    │   ├── DashboardView.swift # Trading summary dashboard
    │   ├── InsightsView.swift  # Patterns & insights
    │   ├── SettingsView.swift  # App settings
    │   ├── OutlookCardView.swift # Market outlook card
    │   ├── TickerChartView.swift # Price chart component
    │   ├── TickerSnapshotCard.swift # Ticker info panel
    │   ├── HistoricalRangeView.swift # Bell curve visualization
    │   ├── InfoCardView.swift  # Reusable card components
    │   ├── ScreenContainerView.swift # Screen layout wrapper
    │   ├── TradeDetailView.swift # Individual trade view
    │   ├── TradeRowView.swift  # Trade list row
    │   └── OnboardingView.swift # First-run experience
    │
    ├── ViewModels/             # View state and presentation logic
    │   ├── HomeViewModel.swift # Home screen state
    │   ├── DashboardViewModel.swift # Dashboard state
    │   ├── InsightsViewModel.swift # Insights state
    │   ├── SettingsViewModel.swift # Settings state
    │   ├── TradeDetailViewModel.swift # Trade detail state
    │   └── TradeListViewModel.swift # Trade list state
    │   (Note: AskView/AskViewModel removed — replaced by HomeView/HomeViewModel)
    │
    ├── Utilities/              # Helper functions and extensions
    │   ├── Theme.swift         # Colors, typography, spacing, button styles
    │   ├── CurrencyFormatter.swift # Currency/percentage formatting
    │   └── AppError.swift      # Error handling
    │
    ├── Assets.xcassets/        # Image and color assets
    ├── Resources/              # Static data files
    │   └── MockTrades.csv      # Sample trade data
    └── Preview Content/        # SwiftUI preview resources
```

## Architecture Overview

### Models
Data structures and business entities. Models should be:
- **Codable** for JSON serialization
- **Identifiable** when used in SwiftUI lists
- **Immutable** when possible (use `let` instead of `var`)

### Services
Business logic, API clients, and data management. Services should:
- Use `@MainActor` for UI-related state
- Leverage Swift Concurrency (`async/await`)
- Be singleton or dependency-injected

### Views
SwiftUI view components. Views should be:
- Small and focused (target ≤300 LOC, max ~500 LOC)
- Use `ScreenContainerView` for consistent layout
- Use `InfoCardView` components for cards
- Include `#Preview` for development

### ViewModels
Presentation logic and view state. ViewModels should:
- Use `@MainActor` annotation
- Conform to `ObservableObject`
- Expose `@Published` properties

### Utilities
- **Theme.swift**: Centralized design system (colors, typography, spacing, button styles)
- **CurrencyFormatter.swift**: Number formatting utilities

## Key Features

### AI-First Experience
The app centers around an AI home screen (`HomeView`) that:
- Provides a "Google for stocks" search experience
- Returns structured article-style responses
- Shows price charts and ticker knowledge cards
- Supports voice input via `SpeechRecognitionService`
- Maintains conversation history locally

### Outlook Engine
`OutlookEngine.swift` synthesizes market outlooks:
- Generates structured `Outlook` objects
- Combines ticker data, volatility, sector trends
- Adds personalized context from trade history
- No financial advice — descriptive metrics only

### Theming System
`Theme.swift` provides:
- **Colors**: Semantic color palette with dark mode support
- **Typography**: Consistent text styles across the app
- **Spacing**: Standard spacing values
- **Button Styles**: Interactive feedback styles

## Development Guidelines

### Code Style
- Use clear, descriptive names
- Keep files under 500 LOC when possible
- Use `Theme.typography` for fonts, `Theme.colors` for colors
- Follow existing patterns before introducing new ones

### File Organization
When a file exceeds ~500 LOC:
1. Extract reusable subviews into separate files
2. Move button styles to `Theme.swift`
3. Split content data into separate modules

### Best Practices
1. **Separation of Concerns**: Keep logic in ViewModels, UI in Views
2. **Consistent Styling**: Use `InfoCardView`, `ScreenContainerView`
3. **Interactive States**: Use button styles from Theme for press feedback
4. **Comments**: Explain *why*, not *what*

## Requirements

- **iOS**: 26.0+
- **Xcode**: 16.0+ (Beta)
- **Swift**: 6.0+

## Building the Project

```bash
# Build for simulator
xcodebuild -project TradeLens.xcodeproj \
  -scheme TradeLens \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath build \
  build

# Install and launch
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/TradeLens.app
xcrun simctl launch booted com.tradelens.TradeLens
```

## Contributing

When adding new features:
1. Place files in the appropriate folder based on responsibility
2. Follow existing naming patterns
3. Use Theme system for styling
4. Keep files focused and under 500 LOC
5. Add `#Preview` for new views
