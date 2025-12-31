//
//  ImportService.swift
//  TradeLens
//
//  Service for importing trades from CSV sources.
//

import Foundation

/// Summary of a CSV import attempt.
struct TradeImportSummary {
    let totalRows: Int
    let importedRows: Int
    let skippedRows: Int
    let details: [String]

    var statusMessage: String {
        "Imported \(importedRows) trade(s) from \(totalRows) row(s). Skipped \(skippedRows) invalid row(s)."
    }
}

/// Service responsible for importing trades.
@MainActor
class ImportService {
    private let tradeService: TradeService
    private let dateFormatter: DateFormatter

    init(tradeService: TradeService = TradeService()) {
        self.tradeService = tradeService
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateFormatter = formatter
    }

    func importTrades(fromCSVNamed name: String) async -> TradeImportSummary {
        guard let url = Bundle.main.url(forResource: name, withExtension: "csv") else {
            return TradeImportSummary(
                totalRows: 0,
                importedRows: 0,
                skippedRows: 0,
                details: ["Import file was not found in the app bundle."]
            )
        }

        guard let csvString = try? String(contentsOf: url) else {
            return TradeImportSummary(
                totalRows: 0,
                importedRows: 0,
                skippedRows: 0,
                details: ["Import file could not be read."]
            )
        }

        let rows = csvString
            .split(whereSeparator: \.isNewline)
            .map { String($0) }
        guard rows.count > 1 else {
            return TradeImportSummary(
                totalRows: 0,
                importedRows: 0,
                skippedRows: 0,
                details: ["Import file had no data rows."]
            )
        }

        var importedTrades: [Trade] = []
        var details: [String] = []
        var skippedRows = 0

        for (index, row) in rows.dropFirst().enumerated() {
            let lineNumber = index + 2
            let columns = row.split(separator: ",", omittingEmptySubsequences: false).map { String($0) }

            guard let trade = parseTrade(from: columns) else {
                skippedRows += 1
                details.append("Row \(lineNumber): Skipped due to invalid or missing fields.")
                continue
            }

            importedTrades.append(trade)
        }

        if !importedTrades.isEmpty {
            await tradeService.addTrades(importedTrades)
        }

        return TradeImportSummary(
            totalRows: rows.count - 1,
            importedRows: importedTrades.count,
            skippedRows: skippedRows,
            details: details
        )
    }

    private func parseTrade(from columns: [String]) -> Trade? {
        guard columns.count >= 7 else {
            return nil
        }

        let ticker = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ticker.isEmpty else {
            return nil
        }

        let entryDateValue = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
        guard let entryDate = dateFormatter.date(from: entryDateValue) else {
            return nil
        }

        let exitDateValue = columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
        let exitDate = exitDateValue.isEmpty ? nil : dateFormatter.date(from: exitDateValue)
        if !exitDateValue.isEmpty, exitDate == nil {
            return nil
        }

        let qtyValue = columns[3].trimmingCharacters(in: .whitespacesAndNewlines)
        guard let qty = Double(qtyValue), qty > 0 else {
            return nil
        }

        let entryPriceValue = columns[4].trimmingCharacters(in: .whitespacesAndNewlines)
        guard let entryPrice = Double(entryPriceValue), entryPrice > 0 else {
            return nil
        }

        let exitPriceValue = columns[5].trimmingCharacters(in: .whitespacesAndNewlines)
        let exitPrice = exitPriceValue.isEmpty ? nil : Double(exitPriceValue)
        if !exitPriceValue.isEmpty, exitPrice == nil {
            return nil
        }

        let categoryRaw = columns[6].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let category = Trade.Category(rawValue: categoryRaw) else {
            return nil
        }

        return Trade(
            ticker: ticker,
            entryDate: entryDate,
            exitDate: exitDate,
            qty: qty,
            entryPrice: entryPrice,
            exitPrice: exitPrice,
            category: category
        )
    }
}
