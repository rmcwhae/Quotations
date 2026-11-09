//
//  KoboAnnotationsImportService.swift
//  Quotations
//

import CryptoKit
import Foundation
import SwiftData

enum KoboAnnotationsImportService {
    private static let sourceIDPrefix = "kobo:book:"
    private static let quotationIDPrefix = "kobo:annotation:"

    static func importFile(
        url: URL,
        into modelContext: ModelContext,
        backupManager: BackupManager
    ) throws -> KoboAnnotationsImportResult {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw KoboAnnotationsImportError.readFailed(error.localizedDescription)
        }
        let parsed = try KoboAnnotationsParser.parse(data: data)
        return try importParsed(parsed, into: modelContext, backupManager: backupManager)
    }

    static func importParsed(
        _ export: KoboAnnotationsExport,
        into modelContext: ModelContext,
        backupManager: BackupManager
    ) throws -> KoboAnnotationsImportResult {
        try modelContext.save()
        _ = try backupManager.createBackup(isSafetyBackup: true)

        let importer = try Importer(
            modelContext: modelContext,
            bookTitle: export.title,
            authorName: export.author
        )
        for highlight in export.highlights {
            importer.process(highlight)
        }

        try modelContext.saveAndNotify()
        return importer.result
    }

    static func sourceExternalIdentifier(title: String, author: String) -> String {
        sourceIDPrefix + stableHash(
            title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                + "\u{1F}|"
                + author.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        )
    }

    static func quotationExternalIdentifier(
        title: String,
        author: String,
        location: String?,
        content: String
    ) -> String {
        let payload = [
            title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            author.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            (location ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            content.trimmingCharacters(in: .whitespacesAndNewlines)
        ].joined(separator: "\u{1F}|")
        return quotationIDPrefix + stableHash(payload)
    }
}

private extension KoboAnnotationsImportService {
    static func stableHash(_ string: String) -> String {
        let digest = SHA256.hash(data: Data(string.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    final class Importer {
        private let lookup: ImportLookup
        private let bookTitle: String
        private let authorName: String

        private var importedQuotations = 0
        private var skippedDuplicates = 0
        private var skippedEmpty = 0

        private lazy var resolvedSource: Source = lookup.resolveSource(
            externalID: sourceExternalIdentifier(title: bookTitle, author: authorName),
            title: bookTitle,
            authorName: authorName,
            format: .kobo
        )

        init(modelContext: ModelContext, bookTitle: String, authorName: String) throws {
            self.lookup = try ImportLookup(modelContext: modelContext)
            self.bookTitle = bookTitle
            self.authorName = authorName
        }

        var result: KoboAnnotationsImportResult {
            KoboAnnotationsImportResult(
                importedAuthors: lookup.importedAuthors,
                importedSources: lookup.importedSources,
                importedQuotations: importedQuotations,
                skippedDuplicates: skippedDuplicates,
                skippedEmpty: skippedEmpty
            )
        }

        func process(_ highlight: KoboAnnotationHighlight) {
            let trimmed = highlight.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                skippedEmpty += 1
                return
            }

            let quotationExternalID = quotationExternalIdentifier(
                title: bookTitle,
                author: authorName,
                location: highlight.location,
                content: trimmed
            )
            guard !lookup.containsQuotation(externalID: quotationExternalID),
                  lookup.insertQuotation(
                      content: trimmed,
                      source: resolvedSource,
                      location: highlight.location,
                      externalID: quotationExternalID
                  ) else {
                skippedDuplicates += 1
                return
            }
            importedQuotations += 1
        }
    }
}

extension Notification.Name {
    static let importFromKoboAnnotations = Notification.Name("importFromKoboAnnotations")
}
