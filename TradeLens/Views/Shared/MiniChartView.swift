//
//  MiniChartView.swift
//  TradeLens
//
//  Simple sparkline chart for price history.
//

import SwiftUI

struct MiniChartView: View {
    let points: [PricePoint]

    var body: some View {
        GeometryReader { geometry in
            let chartPoints = chartPoints(in: geometry.size)

            Path { path in
                guard let firstPoint = chartPoints.first else { return }
                path.move(to: firstPoint)

                for point in chartPoints.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(
                Theme.colors.accentBlue,
                style: StrokeStyle(
                    lineWidth: Constants.lineWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        }
        .frame(height: Constants.height)
        .padding(.vertical, Constants.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .fill(Theme.colors.cardBackground)
        )
    }

    private func chartPoints(in size: CGSize) -> [CGPoint] {
        guard points.count > 1 else { return [] }

        let sortedPoints = points.sorted { $0.date < $1.date }
        let closes = sortedPoints.map(\.close)

        guard let minClose = closes.min(), let maxClose = closes.max() else {
            return []
        }

        let range = maxClose - minClose
        let adjustedRange = range == 0 ? Constants.flatLineRange : range

        return sortedPoints.enumerated().map { index, point in
            let xPosition = size.width * CGFloat(index) / CGFloat(sortedPoints.count - 1)
            let normalizedY = (point.close - minClose) / adjustedRange
            let yPosition = size.height * (1 - normalizedY)
            return CGPoint(x: xPosition, y: yPosition)
        }
    }

    private enum Constants {
        static let height: CGFloat = 64
        static let lineWidth: CGFloat = 2
        static let cornerRadius: CGFloat = 12
        static let verticalPadding: CGFloat = 6
        static let flatLineRange: Double = 1
    }
}

#Preview {
    enum PreviewConstants {
        static let dayInterval: TimeInterval = 86_400
    }

    let samplePoints = [
        PricePoint(date: Date().addingTimeInterval(-PreviewConstants.dayInterval * 4), close: 172, high: 174, low: 171),
        PricePoint(date: Date().addingTimeInterval(-PreviewConstants.dayInterval * 3), close: 175, high: 176, low: 173),
        PricePoint(date: Date().addingTimeInterval(-PreviewConstants.dayInterval * 2), close: 170, high: 172, low: 169),
        PricePoint(date: Date().addingTimeInterval(-PreviewConstants.dayInterval), close: 178, high: 179, low: 177),
        PricePoint(date: Date(), close: 176, high: 177, low: 175)
    ]

    return MiniChartView(points: samplePoints)
        .padding()
        .background(Theme.colors.backgroundPrimary)
        .preferredColorScheme(.dark)
}
