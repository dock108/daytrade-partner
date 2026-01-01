# AGENTS.md — TradeLens (Day Trading Partner)

> This file provides context for AI agents (Codex, Cursor, Copilot) working on this codebase.

## Quick Context

**What is this?** iOS app for day trading analysis and tracking.

**Tech Stack:** Swift, SwiftUI, MVVM architecture

**Key Directories:**
- `TradeLens/Models/` — Data structures
- `TradeLens/Views/` — SwiftUI views
- `TradeLens/ViewModels/` — State and business logic
- `TradeLens/Services/` — Calculations and data services

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

## Testing

- Add tests for new calculation logic
- Tests should be deterministic
- Run: `xcodebuild test -scheme TradeLens`

## Getting Help

If something is unclear, leave a `// TODO:` comment rather than guessing.

