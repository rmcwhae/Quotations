//
//  ImportLookup.swift
//  Quotations
//

import Foundation
import SwiftData

/// Shared lookup tables for the Kobo, Apple Books, and CSV importers.
///
/// Authors and sources match against live records only. Quotation dedupe keys include
/// soft-deleted rows, so re-importing never resurrects a highlight the user deleted.
final class ImportLookup {
    private let modelContext: ModelContext

    private var sourceByExternalID: [String: Source] = [:]
    private var sourceByTitleAuthor: [String: Source] = [:]
    private var authorByName: [String: Author] = [:]
    private var quotationExternalIDs: Set<String> = []
    private var contentKeysBySource: [ObjectIdentifier: Set<String>] = [:]

    private(set) var importedAuthors = 0
    private(set) var importedSources = 0

    init(modelContext: ModelContext) throws {
        self.modelContext = modelContext

        let sources = try modelContext.fetch(FetchDescriptor<Source>(
            predicate: #Predicate<Source> { $0.deletedAt == nil }
        ))
        for source in sources {
            if let id = source.externalIdentifier {
                sourceByExternalID[id] = source
            }
            sourceByTitleAuthor[Self.sourceMatchKey(title: source.title, author: source.author?.name)] = source
        }

        let authors = try modelContext.fetch(FetchDescriptor<Author>(
            predicate: #Predicate<Author> { $0.deletedAt == nil }
        ))
        for author in authors {
            authorByName[Self.normalized(author.name)] = author
        }

        // Deliberately includes soft-deleted quotations.
        for quotation in try modelContext.fetch(FetchDescriptor<Quotation>()) {
            if let id = quotation.externalIdentifier {
                quotationExternalIDs.insert(id)
            }
            if let source = quotation.source {
                contentKeysBySource[ObjectIdentifier(source), default: []]
                    .insert(Self.contentKey(markdown: quotation.content))
            }
        }
    }

    func containsQuotation(externalID: String) -> Bool {
        quotationExternalIDs.contains(externalID)
    }

    /// Inserts `content` (plain text, escaped to markdown here) unless the source already
    /// has a quotation with the same text. Returns `false` when skipped as a duplicate.
    func insertQuotation(content: String, source: Source, location: String?, externalID: String? = nil) -> Bool {
        let markdown = MarkdownCodec.escapeMarkdown(content)
        let key = Self.contentKey(markdown: markdown)
        let sourceKey = ObjectIdentifier(source)
        guard contentKeysBySource[sourceKey]?.contains(key) != true else { return false }

        modelContext.insert(Quotation(
            content: markdown,
            source: source,
            location: location,
            externalIdentifier: externalID
        ))
        contentKeysBySource[sourceKey, default: []].insert(key)
        if let externalID {
            quotationExternalIDs.insert(externalID)
        }
        return true
    }

    /// Finds a live source by external ID, then by title + author (adopting the external ID
    /// and format if unset), otherwise creates one.
    func resolveSource(externalID: String, title: String, authorName: String, format: SourceFormat) -> Source {
        if let existing = sourceByExternalID[externalID] {
            return existing
        }

        let matchKey = Self.sourceMatchKey(title: title, author: authorName)
        if let existing = sourceByTitleAuthor[matchKey] {
            if existing.externalIdentifier == nil {
                existing.externalIdentifier = externalID
                existing.updatedAt = Date()
            }
            if existing.format == nil {
                existing.format = format.rawValue
                existing.updatedAt = Date()
            }
            sourceByExternalID[externalID] = existing
            return existing
        }

        let source = Source(
            title: title,
            author: resolveAuthor(named: authorName),
            format: format.rawValue,
            externalIdentifier: externalID
        )
        modelContext.insert(source)
        sourceByExternalID[externalID] = source
        sourceByTitleAuthor[matchKey] = source
        importedSources += 1
        return source
    }

    private func resolveAuthor(named name: String) -> Author {
        let key = Self.normalized(name)
        if let existing = authorByName[key] {
            return existing
        }
        let author = Author(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        modelContext.insert(author)
        authorByName[key] = author
        importedAuthors += 1
        return author
    }

    /// Compares quotations by visible text, so stored markdown and escaped imports match.
    static func contentKey(markdown: String) -> String {
        normalized(MarkdownCodec.plainText(from: markdown))
    }

    static func normalized(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func sourceMatchKey(title: String, author: String?) -> String {
        "\(normalized(author ?? ""))\u{1F}|\(normalized(title))"
    }
}
