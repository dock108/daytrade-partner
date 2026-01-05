# Data Store Architecture

> Single Source of Truth for all market data in TradeLens

## Overview

TradeLens uses a centralized data store architecture to ensure consistent data display across all screens. No view or ViewModel makes direct HTTP calls — all data flows through shared observable stores.

### Production vs. Experimental

| Store | Status | Notes |
|-------|--------|-------|
| PriceStore | ✅ Production | Fetches from backend |
| HistoryStore | ✅ Production | Fetches from backend |
| OutlookStore | ✅ Production | Fetches from backend |
| AIResponseStore | ✅ Production | Fetches from backend |
| NewsStore | 🧪 Experimental | Returns sample data (backend not implemented) |

The `MockPriceService` provides fallback data when the backend is unavailable — it's not the primary data source.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Views                                │
│  HomeView  │  DashboardView  │  InsightsView  │  etc.      │
└──────────────────────┬──────────────────────────────────────┘
                       │ Subscribe to @Published
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                   ViewModels                                │
│              HomeViewModel, etc.                            │
│         (use stores, don't call API directly)               │
└──────────────────────┬──────────────────────────────────────┘
                       │ Use stores
                       ▼
┌─────────────────────────────────────────────────────────────┐
│               DataStoreManager                              │
│        Coordinates all stores, provides sync status         │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┼──────────────┬──────────────┐
        ▼              ▼              ▼              ▼              ▼
┌────────────┐  ┌────────────┐  ┌──────────────┐  ┌────────────┐  ┌────────────┐
│ PriceStore │  │HistoryStore│  │AIResponseStore│ │OutlookStore│  │ NewsStore  │
│            │  │            │  │              │  │            │  │            │
│ Snapshots  │  │ Price      │  │ AI           │  │ Outlook    │  │ News       │
│ Last Price │  │ History    │  │ Responses    │  │ Data       │  │ Items      │
└──────┬─────┘  └──────┬─────┘  └──────┬───────┘  └──────┬─────┘  └──────┬─────┘
       │               │               │               │               │
       └───────────────┴───────────────┴───────────────┴───────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                     APIClient                               │
│              (HTTP calls to backend)                        │
└─────────────────────────────────────────────────────────────┘
```

## Data Stores

### PriceStore

**Purpose:** Ticker snapshots (current price, change %, 52-week range)

**Location:** `TradeLens/DataStores/PriceStore.swift`

**Key Features:**
- Caches snapshots with 60-second refresh window
- Auto-fetches when data is stale
- Validates price consistency with HistoryStore (DEBUG)

**Usage:**
```swift
// Get snapshot (triggers fetch if needed)
let snapshot = PriceStore.shared.snapshot(for: "AAPL")

// Force refresh
await PriceStore.shared.refresh(symbol: "AAPL")

// Check staleness
if PriceStore.shared.isStale(symbol: "AAPL") {
    // Data needs refresh
}
```

### HistoryStore

**Purpose:** Historical price data for charts

**Location:** `TradeLens/DataStores/HistoryStore.swift`

**Key Features:**
- Caches by symbol + range (e.g., "AAPL:1M")
- 5-minute refresh window
- Supports ranges: 1D, 1M, 6M, 1Y

**Usage:**
```swift
// Get price points
let points = HistoryStore.shared.points(for: "AAPL", range: "1M")

// Force refresh
await HistoryStore.shared.refresh(symbol: "AAPL", range: "1M")
```

### AIResponseStore

**Purpose:** AI-generated explanations and analysis

**Location:** `TradeLens/DataStores/OutlookStore.swift`

**Key Features:**
- Caches responses by question
- 5-minute cache window
- Returns nil on error (check `errors` dictionary)

**Usage:**
```swift
// Ask AI (returns cached if fresh)
let response = await AIResponseStore.shared.ask(
    question: "What's happening with AAPL?",
    symbol: "AAPL",
    timeframeDays: 30,
    simpleMode: true
)
```

### OutlookStore

**Purpose:** Market outlook data fetched from the backend

**Location:** `TradeLens/DataStores/OutlookStore.swift`

**Key Features:**
- Fetches from `/outlook/{ticker}` only
- 5-minute cache window
- Publishes loading + fallback state for stale cache reuse

**Usage:**
```swift
let outlook = await OutlookStore.shared.fetchOutlook(
    symbol: "AAPL",
    timeframeDays: 30
)
```

### NewsStore (🧪 Experimental)

**Purpose:** Market news and articles

**Location:** `TradeLens/DataStores/NewsStore.swift`

**Status:** Experimental — returns sample data only

**Key Features:**
- 10-minute refresh window
- Currently returns sample data (backend news endpoint not implemented)
- Ready for future API integration when backend supports it

### DataStoreManager

**Purpose:** Coordinates all stores, provides sync status

**Location:** `TradeLens/DataStores/DataStoreManager.swift`

**Key Features:**
- `refreshAll(for:)` - Refresh all data for a symbol
- `syncTimeString(for:)` - Formatted sync time for UI
- `hasStaleData(for:)` - Check if any data is stale
- `validatePriceConsistency(for:)` - DEBUG: Check price consistency

## Debug Guardrails

In DEBUG builds, the following checks are active:

### Price Consistency
If PriceStore and HistoryStore prices differ by >0.1%, a warning is logged:
```
⚠️ Price mismatch for AAPL: snapshot=185.0, history=184.5
```

### Stale Data Warnings
If data exceeds the acceptable staleness threshold:
```
⚠️ Price data for AAPL is stale
⚠️ History data for AAPL is stale
```

### Sync Timestamp (Dev-Visible)
In DEBUG builds, a subtle footer shows sync time:
```
↻ Data synced at 1:37 PM
```

## Rules for Contributors

1. **Never call APIClient directly from Views or ViewModels**
   - Use the appropriate store instead
   - Stores handle caching, deduplication, and consistency

2. **Use DataStoreManager for coordinated operations**
   - `refreshAll(for:)` when you need both price and history

3. **Check staleness before displaying critical data**
   - Use `isStale(symbol:)` methods

4. **Add tests for new store functionality**
   - Test cache behavior
   - Test refresh logic
   - Test error handling

## File Structure

```
TradeLens/
├── DataStores/
│   ├── DataStoreManager.swift   # Central coordinator
│   ├── PriceStore.swift         # Ticker snapshots
│   ├── HistoryStore.swift       # Price history
│   ├── OutlookStore.swift       # AI responses + outlook data
│   └── NewsStore.swift          # News items
├── Services/
│   └── APIClient.swift          # HTTP calls (only stores use this)
└── ViewModels/
    └── HomeViewModel.swift      # Uses stores, not APIClient
```

## Cache Windows

| Store | Cache Window | Stale Threshold |
|-------|--------------|-----------------|
| PriceStore | 60 seconds | 120 seconds |
| HistoryStore | 5 minutes | 10 minutes |
| AIResponseStore | 5 minutes | 10 minutes |
| OutlookStore | 5 minutes | 10 minutes |
| NewsStore | 10 minutes | 30 minutes |

## Future Improvements

- [ ] Add WebSocket support for real-time price updates
- [ ] Implement news API when backend supports it
- [ ] Add offline caching with persistence
- [ ] Implement data prefetching for common symbols
- [ ] Replace mock trade data with real brokerage import
