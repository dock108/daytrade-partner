# Daytrade Partner (TradeLens)

A personal iOS app for analyzing and simulating partner-style trading strategies — built for experimentation and insight, not signals.

---

## What Problem Does This Solve?

Day trading involves many moving parts: tracking positions, understanding volatility, recognizing behavioral patterns, and maintaining clarity about what strategies actually performed well vs. what felt good in the moment.

**Daytrade Partner** aims to bring clarity to these questions:

- **How have similar setups performed historically?** — Pattern recognition across volatility profiles
- **What does the current market context look like?** — AI-synthesized outlook summaries
- **Where do my own behavioral tendencies show up?** — Personal trade history analysis
- **How would a trade structure look at different timeframes?** — Simulation and exploration

This is a sandbox for exploring partner-style trade structures — not a system for generating trade signals or recommendations.

---

## Who Is This For?

- **Primary user:** You (personal experimentation and learning)
- **Test users:** Friends who want to explore trading analysis concepts
- **Future direction:** Educational tooling for understanding trading behavior

This is not intended as a commercial product or financial advice system.

---

## How It Connects to daytrade-partner-data

The iOS app fetches market data and AI-generated outlooks from a backend service:

| Component | Purpose |
|-----------|---------|
| **daytrade-partner** (this repo) | iOS app — UI, local state, simulations |
| **daytrade-partner-data** | Python backend — market data APIs, AI synthesis, outlook generation |

The app connects to the backend via:
- `/outlook/{ticker}` — AI-generated market context
- Price and history endpoints — Chart data and snapshots

In DEBUG mode, the app points to `localhost:8000`. Production points to a deployed API.

---

## Current Capabilities

| Feature | Status | Notes |
|---------|--------|-------|
| AI Home Screen | ✅ Active | Search-style interface with structured responses |
| Market Outlooks | ✅ Active | Fetched from backend, cached 5 min |
| Price Charts | ✅ Active | Intraday + historical ranges |
| Sample Trade Dashboard | 🧪 Experimental | Mock data for UI preview — not real trades |
| Insights Tab | 🧪 Experimental | Pattern analysis on sample data |
| Voice Input | ✅ Active | Speech-to-text for queries |
| Trade Import | 📋 Planned | Brokerage connection for real trade history |

---

## Experimental vs. Production

Much of the app is built for **exploration and UI development**, not production use:

- `MockTradeDataService` — Generates realistic fake trades for testing
- `MockPriceService` — Fallback price data when backend is unavailable
- `OutlookEngine` — Legacy local outlook synthesis (now replaced by backend)
- Dashboard/Insights tabs — Clearly labeled as "Sample Data Preview"

These exist to enable rapid iteration and UI development without requiring live market connections.

---

## Local Setup

1. Open `TradeLens.xcodeproj` in Xcode
2. Select your target device or simulator
3. Press `Cmd + R` to build and run

For full functionality, run the `daytrade-partner-data` backend locally on port 8000.

---

## Documentation

| Doc | Purpose |
|-----|---------|
| [`docs/PROJECT_GUIDE.md`](docs/PROJECT_GUIDE.md) | Architecture, file structure, development guidelines |
| [`docs/DataStoreArchitecture.md`](docs/DataStoreArchitecture.md) | Data flow and caching patterns |
| [`AGENTS.md`](AGENTS.md) | Context for AI coding assistants |

---

## Philosophy

- **Insights, not signals** — Help understand patterns, don't tell you what to trade
- **Experimentation first** — Mock services enable rapid iteration
- **Personal tool** — Built for learning, not scale
- **Transparency** — Sample data is clearly labeled, no fake accuracy claims

---
