//
//  ConsistencyCheckerView.swift
//  TradeLens
//
//  Debug-only consistency checker surfaced via developer mode.
//

import SwiftUI

struct ConsistencyCheckerView: View {
    let snapshot: HomeViewModel.ConsistencyDebugSnapshot?

    private enum Constants {
        static let title = "Consistency Checker"
        static let subtitle = "Data store diagnostics"
        static let emptyState = "Run a query with a ticker to see diagnostics."
        static let unavailable = "Unavailable"
        static let none = "None"
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }()

    var body: some View {
        InfoCardView(accent: Theme.colors.accentPurple) {
            VStack(alignment: .leading, spacing: 12) {
                header

                if let snapshot {
                    DebugInfoRow(label: "Symbol", value: snapshot.symbol)
                    DebugInfoRow(label: "Last price source", value: snapshot.lastPriceSource)
                    DebugInfoRow(label: "Outlook data timestamp", value: formattedTimestamp(snapshot.outlookTimestamp))
                    DebugInfoRow(label: "Chart timestamp", value: formattedTimestamp(snapshot.chartTimestamp))
                    mismatchSection(warnings: snapshot.mismatchWarnings)
                } else {
                    Text(Constants.emptyState)
                        .font(Theme.typography.bodySmall)
                        .foregroundStyle(Theme.colors.textTertiary)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.colors.accentPurple.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.colors.accentPurple)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(Constants.title)
                    .font(Theme.typography.rowTitle)
                    .foregroundStyle(Theme.colors.textPrimary)

                Text(Constants.subtitle)
                    .font(Theme.typography.caption)
                    .foregroundStyle(Theme.colors.textTertiary)
            }
        }
    }

    private func formattedTimestamp(_ date: Date?) -> String {
        guard let date else { return Constants.unavailable }
        return Self.timestampFormatter.string(from: date)
    }

    private func mismatchSection(warnings: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Mismatch warnings")
                .font(Theme.typography.rowSubtitle)
                .foregroundStyle(Theme.colors.textSecondary)

            if warnings.isEmpty {
                Text(Constants.none)
                    .font(Theme.typography.bodySmall)
                    .foregroundStyle(Theme.colors.textTertiary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(warnings, id: \.self) { warning in
                        Text("• \(warning)")
                            .font(Theme.typography.bodySmall)
                            .foregroundStyle(Theme.colors.accentRed)
                    }
                }
            }
        }
    }
}

private struct DebugInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(Theme.typography.rowSubtitle)
                .foregroundStyle(Theme.colors.textSecondary)

            Spacer()

            Text(value)
                .font(Theme.typography.bodySmall)
                .foregroundStyle(Theme.colors.textPrimary)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ConsistencyCheckerView(
            snapshot: HomeViewModel.ConsistencyDebugSnapshot(
                symbol: "AAPL",
                lastPriceSource: "API",
                outlookTimestamp: Date(),
                chartTimestamp: Date().addingTimeInterval(-120),
                mismatchWarnings: ["Price mismatch for AAPL: snapshot=198.02, history=198.40"]
            )
        )

        ConsistencyCheckerView(snapshot: nil)
    }
    .padding()
    .background(Theme.colors.background)
}
