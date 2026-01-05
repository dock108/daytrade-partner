# TradeLens Project Guide

> **Note:** This project is a personal experimentation tool for analyzing trading patterns and strategies. Many components are experimental — see status labels below.

## Project Structure

The project follows a clean MVVM architecture with centralized data stores for single-source-of-truth data management.

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
    │   ├── BackendModels.swift # Backend API response models
    │   ├── ConversationHistory.swift # Chat history persistence
    │   ├── PriceData.swift     # Price chart data structures
    │   ├── TickerInfo.swift    # Ticker knowledge panel data
    │   ├── UserSummary.swift   # Trading summary analytics
    │   └── UserPreferences.swift # User settings model
    │
    ├── DataStores/             # Centralized data management (single source of truth)
    │   ├── DataStoreManager.swift # Central coordinator
    │   ├── PriceStore.swift    # Ticker snapshots
    │   ├── HistoryStore.swift  # Price history
    │   ├── OutlookStore.swift  # AI responses + outlook data
    │   └── NewsStore.swift     # News items (placeholder)
    │
    ├── Services/               # Business logic and API clients
    │   ├── APIClient.swift     # Backend HTTP client
    │   ├── QueryParser.swift   # Query parsing (ticker detection, timeframe)
    │   ├── OutlookEngine.swift # 🧪 EXPERIMENTAL: Legacy local outlook synthesis
    │   ├── MockTradeDataService.swift # 🧪 EXPERIMENTAL: Mock trade generation for UI
    │   ├── MockPriceService.swift # 🧪 EXPERIMENTAL: Fallback price data
    │   ├── SpeechRecognitionService.swift # Voice input
    │   └── UserSettings.swift  # Settings persistence
    │
    ├── Views/                  # SwiftUI view components
    │   ├── ContentView.swift   # Tab navigation container
    │   ├── HomeView.swift      # AI-first home screen
    │   ├── HomeArticleComponents.swift # Article display components
    │   ├── DashboardView.swift # Trading summary dashboard
    │   ├── InsightsView.swift  # Patterns & insights
    │   ├── SettingsView.swift  # App settings
    │   ├── OutlookCardView.swift # Market outlook card
    │   ├── TickerChartView.swift # Price chart component
    │   ├── HistoricalRangeView.swift # Bell curve visualization
    │   ├── InfoCardView.swift  # Reusable card components
    │   ├── ScreenContainerView.swift # Screen layout wrapper
    │   ├── OnboardingView.swift # First-run experience
    │   └── Shared/             # Shared view components
    │       └── MiniChartView.swift # Compact chart
    │
    ├── ViewModels/             # View state and presentation logic
    │   └── HomeViewModel.swift # Home screen state (uses DataStores)
    │
    ├── Utilities/              # Helper functions and extensions
    │   ├── Theme.swift         # Colors, typography, spacing, button styles
    │   ├── BackendConfig.swift # Backend URL configuration
    │   ├── CurrencyFormatter.swift # Currency/percentage formatting
    │   └── AppError.swift      # Error handling
    │
    ├── Assets.xcassets/        # Image and color assets
    ├── Resources/              # Static data files
    │   └── MockTrades.csv      # Sample trade data
    └── Preview Content/        # SwiftUI preview resources
```

## Architecture Overview

### Data Flow

```
Views → ViewModels → DataStores → APIClient → Backend
                ↓
         @Published updates propagate back to Views
```

**Key principle:** No view or ViewModel makes direct HTTP calls. All data flows through shared DataStores for cache management and consistency.

### Models
Data structures and business entities. Models should be:
- **Codable** for JSON serialization
- **Identifiable** when used in SwiftUI lists
- **Immutable** when possible (use `let` instead of `var`)

### DataStores
Centralized observable stores that own all market data:
- **PriceStore**: Ticker snapshots (60s cache)
- **HistoryStore**: Price history (5min cache)
- **AIResponseStore**: AI responses (5min cache)
- **OutlookStore**: Backend outlook data (5min cache)
- **NewsStore**: News items (placeholder for future API)
- **DataStoreManager**: Coordinates stores, provides sync status

See [`DataStoreArchitecture.md`](DataStoreArchitecture.md) for detailed documentation.

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
- **Use DataStores** for all data fetching (not APIClient directly)

### Utilities
- **Theme.swift**: Centralized design system (colors, typography, spacing, button styles, FlowLayout)
- **BackendConfig.swift**: Backend URL configuration (localhost/production)
- **CurrencyFormatter.swift**: Number formatting utilities
- **AppError.swift**: Unified error handling

## Key Features

### AI-First Experience
The app centers around an AI home screen (`HomeView`) that:
- Provides a "Google for stocks" search experience
- Returns structured article-style responses
- Shows price charts and ticker knowledge cards
- Supports voice input via `SpeechRecognitionService`
- Maintains conversation history locally

### 🧪 Sample Data Mode (Experimental)
Dashboard and Insights tabs currently show sample/preview data:
- Clearly labeled as "Sample Data Preview" in the UI
- Uses `MockTradeDataService` to generate realistic fake trades
- Demonstrates what personal tracking would look like with real data
- **Not production data** — exists for UI development and experimentation
- Trade import via brokerage connections is a planned future feature

### Outlook Data
Market outlooks are fetched from the backend via `OutlookStore`:
- Uses `/outlook/{ticker}` only
- Cached for up to 5 minutes
- UI renders backend text directly (no local synthesis)

> **Note:** The legacy `OutlookEngine.swift` exists for offline/fallback scenarios but is considered experimental. Production outlook data comes from the `daytrade-partner-data` backend.

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
