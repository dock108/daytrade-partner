# AGENTS.md — Daytrade Partner (TradeLens)

> This file provides context for AI agents (Codex, Cursor, Copilot) working on this codebase.

## Quick Context

**What is this?** Personal iOS app for analyzing and simulating partner-style trading strategies — built for experimentation and insights, not signals.

**Tech Stack:** Swift, SwiftUI, MVVM architecture

**Backend:** Connects to `daytrade-partner-data` (Python FastAPI) for market data and AI outlooks.

**Key Directories:**
- `TradeLens/Models/` — Data structures
- `TradeLens/Views/` — SwiftUI views
- `TradeLens/ViewModels/` — State and business logic
- `TradeLens/Services/` — Calculations and data services
- `TradeLens/DataStores/` — Centralized data management

## What's Production vs. Experimental

| Component | Status |
|-----------|--------|
| AI Home Screen | ✅ Production |
| Outlook data from backend | ✅ Production |
| Price/history charts | ✅ Production |
| Dashboard/Insights tabs | 🧪 Experimental (mock data) |
| `MockTradeDataService` | 🧪 Experimental (UI preview) |
| `MockPriceService` | 🧪 Experimental (fallback) |
| `OutlookEngine` | 🧪 Experimental (legacy local synthesis) |
| `NewsStore` | 🧪 Experimental (sample data only) |

## Coding Standards

See `.cursorrules` for complete coding standards. Key points:

1. **MVVM Architecture** — Views don't contain business logic
2. **Swift Conventions** — Follow Swift API Design Guidelines
3. **SwiftUI** — Every view needs a `#Preview`, support dark mode
4. **No Force Unwrapping** — Use guard statements
5. **Incremental Changes** — Don't rewrite, improve incrementally

## Do NOT

- Manually edit `TradeLens.xcodeproj/project.pbxproj`
- Add dependencies without justification
- Put business logic in Views
- Use `print()` in production code
- Refactor unrelated code while fixing bugs
- Treat experimental/mock data as production-ready

## Testing

- Add tests for new calculation logic
- Tests should be deterministic
- Run: `xcodebuild test -scheme TradeLens`

## Getting Help

If something is unclear, leave a `// TODO:` comment rather than guessing.
