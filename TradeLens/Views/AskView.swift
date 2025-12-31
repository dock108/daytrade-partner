//
//  AskView.swift
//  TradeLens
//
//  Ask Anything screen.
//

import SwiftUI

struct AskView: View {
    @StateObject private var viewModel = AskViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    inputSection

                    if let response = viewModel.response {
                        responseBubble(response)
                    }
                }
                .padding()
            }
            .navigationTitle("Ask")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Ask anything")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Get quick, neutral context on tickers and themes.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Ask about a ticker, sector, or outlook…", text: $viewModel.question)
                .textFieldStyle(.roundedBorder)

            Button {
                viewModel.submit()
            } label: {
                Text("Submit")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func responseBubble(_ response: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TradeLens")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(response)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    AskView()
}
