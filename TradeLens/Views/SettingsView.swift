//
//  SettingsView.swift
//  TradeLens
//
//  Settings and data import view.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("Import") {
                    Button {
                        Task {
                            await viewModel.importTrades()
                        }
                    } label: {
                        HStack {
                            Text("Import Trades")
                            Spacer()
                            if viewModel.isImporting {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel.isImporting)

                    if let status = viewModel.importStatusMessage {
                        Text(status)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if !viewModel.importDetails.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Details")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(viewModel.importDetails, id: \.self) { detail in
                                Text(detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Section("Coming soon") {
                    Text("Fidelity import will appear here once APIs are connected.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
