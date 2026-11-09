//
//  AppleBooksImportService.swift
//  Quotations
//

import Foundation
import SwiftData

enum AppleBooksImportService {
    private static let sourceIDPrefix = "apple-books:asset:"
    private static let quotationIDPrefix = "apple-books:annotation:"

    @MainActor
    static func importFromAppleBooks(
        modelContext: ModelContext,
        backupManager: BackupManager
    ) throws -> AppleBooksImportResult {
        let paths = try AppleBooksDatabaseLocator.locateOrPrompt()
        let rows = try AppleBooksSQLiteReader.readHighlights(
            annotationDatabase: paths.annotationDatabase,
            libraryDatabase: paths.libraryDatabase
        )
        return try importRows(rows, into: modelContext, backupManager: backupManager)
    }

    static func importRows(
        _ rows: [AppleBooksHighlightRow],
        into modelContext: ModelContext,
        backupManager: BackupManager
    ) throws -> AppleBooksImportResult {
        try modelContext.save()
        _ = try backupManager.createBackup(isSafetyBackup: true)

        let importer = try Importer(modelContext: modelContext)
        for row in rows {
            importer.process(row)
        }

        try modelContext.saveAndNotify()
        return importer.result
    }

    static func sourceExternalIdentifier(for assetID: String) -> String {
        sourceIDPrefix + assetID
    }

    static func quotationExternalIdentifier(for annotationUUID: String) -> String {
        quotationIDPrefix + annotationUUID
    }
}

private extension AppleBooksImportService {
    /// Tracks running counts while importing a batch of rows.
    final class Importer {
        private let lookup: ImportLookup

        private var importedQuotations = 0
        private var skippedDuplicates = 0
        private var skippedEmpty = 0

        init(modelContext: ModelContext) throws {
            self.lookup = try ImportLookup(modelContext: modelContext)
        }

        var result: AppleBooksImportResult {
            AppleBooksImportResult(
                importedAuthors: lookup.importedAuthors,
                importedSources: lookup.importedSources,
                importedQuotations: importedQuotations,
                skippedDuplicates: skippedDuplicates,
                skippedEmpty: skippedEmpty
            )
        }

        func process(_ row: AppleBooksHighlightRow) {
            let trimmed = row.quotationContent.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                skippedEmpty += 1
                return
            }

            let quotationExternalID = quotationExternalIdentifier(for: row.annotationUUID)
            guard !lookup.containsQuotation(externalID: quotationExternalID) else {
                skippedDuplicates += 1
                return
            }

            let source = lookup.resolveSource(
                externalID: sourceExternalIdentifier(for: row.assetID),
                title: row.bookTitle,
                authorName: row.authorName ?? "Unknown Author",
                format: .appleBooks
            )
            applyDateReadIfMissing(row.dateReadComponents, to: source)

            guard lookup.insertQuotation(
                content: trimmed,
                source: source,
                location: row.location,
                externalID: quotationExternalID
            ) else {
                skippedDuplicates += 1
                return
            }
            importedQuotations += 1
        }

        private func applyDateReadIfMissing(_ dateRead: (month: Int, year: Int)?, to source: Source) {
            guard source.dateReadMonth == nil, source.dateReadYear == nil, let dateRead else { return }
            source.dateReadMonth = dateRead.month
            source.dateReadYear = dateRead.year
            source.updatedAt = Date()
        }
    }
}

extension Notification.Name {
    static let importFromAppleBooks = Notification.Name("importFromAppleBooks")
}
