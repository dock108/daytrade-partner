//
//  DataSyncBannerView.swift
//  TradeLens
//
//  Small shared banner for data sync status.
//

import SwiftUI

struct DataSyncBannerView: View {
    let textProvider: (Date) -> String?

    private enum Constants {
        static let refreshInterval: TimeInterval = 60
        static let iconName = "clock.arrow.circlepath"
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: Constants.refreshInterval)) { context in
            if let text = textProvider(context.date) {
                HStack(spacing: 8) {
                    Image(systemName: Constants.iconName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.colors.accentBlue.opacity(0.8))

                    Text(text)
                        .font(Theme.typography.caption)
                        .foregroundStyle(Theme.colors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Theme.colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius.md)
                        .stroke(Theme.colors.cardBorder, lineWidth: 1)
                )
            }
        }
    }
}

#Preview {
    DataSyncBannerView { _ in
        "Data from 6 minutes ago — Data synced 2:09 PM — outlook updates periodically"
    }
    .padding()
    .background(Theme.colors.backgroundGradient)
}
