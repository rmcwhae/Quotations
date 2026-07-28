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
        private let modelContext: ModelContext
        private let bookTitle: String
        private let authorName: String
        private let sourceExternalID: String

        private var sourceByExternalID: [String: Source] = [:]
        private var sourceByTitleAuthor: [String: Source] = [:]
        private var quotationByExternalID: [String: Quotation] = [:]
        private var authorByName: [String: Author] = [:]

        private var importedAuthors = 0
        private var importedSources = 0
        private var importedQuotations = 0
        private var skippedDuplicates = 0
        private var skippedEmpty = 0

        private lazy var resolvedSource: Source = resolveSource()

        init(modelContext: ModelContext, bookTitle: String, authorName: String) throws {
            self.modelContext = modelContext
            self.bookTitle = bookTitle
            self.authorName = authorName
            self.sourceExternalID = sourceExternalIdentifier(title: bookTitle, author: authorName)

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

        var result: KoboAnnotationsImportResult {
            KoboAnnotationsImportResult(
                importedAuthors: importedAuthors,
                importedSources: importedSources,
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
            guard quotationByExternalID[quotationExternalID] == nil else {
                skippedDuplicates += 1
                return
            }

            let quotation = Quotation(
                content: trimmed,
                source: resolvedSource,
                location: highlight.location,
                externalIdentifier: quotationExternalID
            )
            modelContext.insert(quotation)
            quotationByExternalID[quotationExternalID] = quotation
            importedQuotations += 1
        }

        private func resolveSource() -> Source {
            if let existing = sourceByExternalID[sourceExternalID] {
                return existing
            }

            let matchKey = sourceMatchKey(title: bookTitle, author: authorName)
            if let existing = sourceByTitleAuthor[matchKey] {
                if existing.externalIdentifier == nil {
                    existing.externalIdentifier = sourceExternalID
                }
                if existing.format == nil {
                    existing.format = SourceFormat.kobo.rawValue
                    existing.updatedAt = Date()
                }
                sourceByExternalID[sourceExternalID] = existing
                return existing
            }

            let source = Source(
                title: bookTitle,
                author: resolveAuthor(named: authorName),
                format: SourceFormat.kobo.rawValue,
                externalIdentifier: sourceExternalID
            )
            modelContext.insert(source)
            sourceByExternalID[sourceExternalID] = source
            sourceByTitleAuthor[matchKey] = source
            importedSources += 1
            return source
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
    static let importFromKoboAnnotations = Notification.Name("importFromKoboAnnotations")
}
