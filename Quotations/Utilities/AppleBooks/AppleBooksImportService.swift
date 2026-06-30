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
    /// Tracks lookup tables and running counts while importing a batch of rows.
    final class Importer {
        private let modelContext: ModelContext

        private var sourceByExternalID: [String: Source] = [:]
        private var sourceByTitleAuthor: [String: Source] = [:]
        private var quotationByExternalID: [String: Quotation] = [:]
        private var authorByName: [String: Author] = [:]

        private var importedAuthors = 0
        private var importedSources = 0
        private var importedQuotations = 0
        private var skippedDuplicates = 0
        private var skippedEmpty = 0

        init(modelContext: ModelContext) throws {
            self.modelContext = modelContext

            let sources = try modelContext.fetch(FetchDescriptor<Source>(
                predicate: #Predicate<Source> { $0.deletedAt == nil }
            ))
            for source in sources {
                if let id = source.externalIdentifier {
                    sourceByExternalID[id] = source
                }
                sourceByTitleAuthor[sourceMatchKey(title: source.title, author: source.author?.name)] = source
            }

            let quotations = try modelContext.fetch(FetchDescriptor<Quotation>(
                predicate: #Predicate<Quotation> { $0.deletedAt == nil }
            ))
            for quotation in quotations {
                if let id = quotation.externalIdentifier {
                    quotationByExternalID[id] = quotation
                }
            }

            let authors = try modelContext.fetch(FetchDescriptor<Author>(
                predicate: #Predicate<Author> { $0.deletedAt == nil }
            ))
            for author in authors {
                authorByName[author.name.lowercased()] = author
            }
        }

        var result: AppleBooksImportResult {
            AppleBooksImportResult(
                importedAuthors: importedAuthors,
                importedSources: importedSources,
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
            guard quotationByExternalID[quotationExternalID] == nil else {
                skippedDuplicates += 1
                return
            }

            let source = resolveSource(for: row)
            applyDateReadIfMissing(row.dateReadComponents, to: source)

            let quotation = Quotation(
                content: trimmed,
                source: source,
                location: row.location,
                externalIdentifier: quotationExternalID
            )
            modelContext.insert(quotation)
            quotationByExternalID[quotationExternalID] = quotation
            importedQuotations += 1
        }

        private func resolveSource(for row: AppleBooksHighlightRow) -> Source {
            let sourceExternalID = sourceExternalIdentifier(for: row.assetID)
            if let existing = sourceByExternalID[sourceExternalID] {
                return existing
            }

            let matchKey = sourceMatchKey(title: row.bookTitle, author: row.authorName)
            if let existing = sourceByTitleAuthor[matchKey] {
                if existing.externalIdentifier == nil {
                    existing.externalIdentifier = sourceExternalID
                }
                sourceByExternalID[sourceExternalID] = existing
                return existing
            }

            let dateRead = row.dateReadComponents
            let source = Source(
                title: row.bookTitle,
                author: resolveAuthor(named: row.authorName ?? "Unknown Author"),
                format: SourceFormat.appleBooks.rawValue,
                dateReadMonth: dateRead?.month,
                dateReadYear: dateRead?.year,
                externalIdentifier: sourceExternalID
            )
            modelContext.insert(source)
            sourceByExternalID[sourceExternalID] = source
            sourceByTitleAuthor[matchKey] = source
            importedSources += 1
            return source
        }

        private func applyDateReadIfMissing(_ dateRead: (month: Int, year: Int)?, to source: Source) {
            guard source.dateReadMonth == nil, source.dateReadYear == nil, let dateRead else { return }
            source.dateReadMonth = dateRead.month
            source.dateReadYear = dateRead.year
            source.updatedAt = Date()
        }

        private func resolveAuthor(named name: String) -> Author {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = trimmed.lowercased()
            if let existing = authorByName[key] {
                return existing
            }
            let author = Author(name: trimmed)
            modelContext.insert(author)
            authorByName[key] = author
            importedAuthors += 1
            return author
        }

        private func sourceMatchKey(title: String, author: String?) -> String {
            let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let normalizedAuthor = (author ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return "\(normalizedAuthor)\u{1F}|\(normalizedTitle)"
        }
    }
}

extension Notification.Name {
    static let importFromAppleBooks = Notification.Name("importFromAppleBooks")
}
