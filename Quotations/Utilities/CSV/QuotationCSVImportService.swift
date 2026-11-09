//
//  QuotationCSVImportService.swift
//  Quotations
//

import Foundation
import SwiftData

enum QuotationCSVImportService {
    static func importCSV(
        url: URL,
        into source: Source,
        modelContext: ModelContext,
        backupManager: BackupManager
    ) throws -> QuotationCSVImportResult {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw QuotationCSVImportError.readFailed(error.localizedDescription)
        }
        let rows = try QuotationCSVParser.parse(data: data)
        return try importRows(rows, into: source, modelContext: modelContext, backupManager: backupManager)
    }

    static func importRows(
        _ rows: [QuotationCSVRow],
        into source: Source,
        modelContext: ModelContext,
        backupManager: BackupManager
    ) throws -> QuotationCSVImportResult {
        guard source.deletedAt == nil else {
            throw QuotationCSVImportError.sourceDeleted
        }

        try modelContext.save()
        _ = try backupManager.createBackup(isSafetyBackup: true)

        let importer = try Importer(source: source, modelContext: modelContext)
        for row in rows {
            importer.process(row)
        }

        try modelContext.saveAndNotify()
        return importer.result
    }
}

private extension QuotationCSVImportService {
    final class Importer {
        private let source: Source
        private let lookup: ImportLookup

        private var importedQuotations = 0
        private var skippedDuplicates = 0
        private var skippedEmpty = 0

        init(source: Source, modelContext: ModelContext) throws {
            self.source = source
            self.lookup = try ImportLookup(modelContext: modelContext)
        }

        var result: QuotationCSVImportResult {
            QuotationCSVImportResult(
                importedQuotations: importedQuotations,
                skippedDuplicates: skippedDuplicates,
                skippedEmpty: skippedEmpty
            )
        }

        func process(_ row: QuotationCSVRow) {
            let trimmed = row.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                skippedEmpty += 1
                return
            }

            guard lookup.insertQuotation(content: trimmed, source: source, location: row.location) else {
                skippedDuplicates += 1
                return
            }
            importedQuotations += 1
        }
    }
}

extension Notification.Name {
    static let importQuotationsFromCSV = Notification.Name("importQuotationsFromCSV")
}
