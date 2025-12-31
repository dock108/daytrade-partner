//
//  SettingsViewModel.swift
//  TradeLens
//
//  ViewModel for settings actions.
//

import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var importStatusMessage: String?
    @Published var importDetails: [String] = []
    @Published var isImporting = false
    
    let userSettings = UserSettings.shared

    private let importService: ImportService

    init(importService: ImportService = ImportService()) {
        self.importService = importService
    }

    func importTrades() async {
        isImporting = true
        importStatusMessage = nil
        importDetails = []

        let summary = await importService.importTrades(fromCSVNamed: "MockTrades")
        importStatusMessage = summary.statusMessage
        importDetails = summary.details
        isImporting = false
    }
}
