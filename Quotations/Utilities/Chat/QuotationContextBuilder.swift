//
//  QuotationContextBuilder.swift
//  Quotations
//

import Foundation
import SwiftData

enum QuotationContextBuilder {
    static let defaultCharacterBudget = 14_000
    private static let truncationSuffix = "…"

    static func build(
        quotations: [Quotation],
        overviewHeader: String? = nil,
        characterBudget: Int = defaultCharacterBudget
    ) -> QuotationContextBuildResult {
        var remaining = max(characterBudget, 0)
        var sections: [String] = []
        var citations: [ChatCitation] = []

        if let overviewHeader, !overviewHeader.isEmpty {
            let header = clip(overviewHeader, to: min(remaining, 2_000))
            if !header.isEmpty {
                sections.append(header)
                remaining -= header.count
            }
        }

        for quotation in quotations {
            guard remaining > 0 else { break }
            guard quotation.deletedAt == nil,
                  let source = quotation.source,
                  source.deletedAt == nil else {
                continue
            }

            let block = formatBlock(for: quotation)
            guard !block.isEmpty else { continue }

            let clipped = clip(block, to: remaining)
            guard !clipped.isEmpty else { continue }

            sections.append(clipped)
            remaining -= clipped.count

            citations.append(
                ChatCitation(
                    quotationId: quotation.persistentModelID,
                    sourceId: source.persistentModelID,
                    label: citationLabel(for: quotation)
                )
            )
        }

        return QuotationContextBuildResult(
            context: sections.joined(separator: "\n\n"),
            citations: citations
        )
    }

    static func resolveQuotations(
        encodedIDs: [String],
        from quotations: [Quotation]
    ) -> [Quotation] {
        let quotationByEncodedID = Dictionary(
            uniqueKeysWithValues: quotations.compactMap { quotation -> (String, Quotation)? in
                guard let encoded = QuotationDeepLink.encode(quotation.persistentModelID) else { return nil }
                return (encoded, quotation)
            }
        )

        var seen = Set<PersistentIdentifier>()
        var resolved: [Quotation] = []

        for encodedID in encodedIDs {
            guard let quotation = quotationByEncodedID[encodedID],
                  quotation.deletedAt == nil,
                  quotation.source?.deletedAt == nil,
                  seen.insert(quotation.persistentModelID).inserted else {
                continue
            }
            resolved.append(quotation)
        }

        return resolved
    }

    static func resolveQuotations(
        ids: [PersistentIdentifier],
        from quotations: [Quotation]
    ) -> [Quotation] {
        let quotationByID = Dictionary(uniqueKeysWithValues: quotations.map { ($0.persistentModelID, $0) })
        var seen = Set<PersistentIdentifier>()
        var resolved: [Quotation] = []

        for id in ids {
            guard let quotation = quotationByID[id],
                  quotation.deletedAt == nil,
                  quotation.source?.deletedAt == nil,
                  seen.insert(id).inserted else {
                continue
            }
            resolved.append(quotation)
        }

        return resolved
    }

    private static func formatBlock(for quotation: Quotation) -> String {
        guard let source = quotation.source else { return "" }

        let content = QuotationSearchText.plainContent(from: quotation.content)
        guard !content.isEmpty else { return "" }

        var lines = ["---"]
        if let author = QuotationSearchText.authorName(for: quotation) {
            lines.append("Author: \(author)")
        }
        lines.append("Source: \(source.title)")
        if let location = quotation.location, !location.isEmpty {
            lines.append("Location: \(location)")
        }
        lines.append("Quotation: \"\(content)\"")
        return lines.joined(separator: "\n")
    }

    private static func citationLabel(for quotation: Quotation) -> String {
        let content = QuotationSearchText.plainContent(from: quotation.content)
        let title = QuotationSearchText.displayTitle(for: quotation)
        let snippet = clip(content, to: 72)
        if snippet.isEmpty {
            return title
        }
        if let author = QuotationSearchText.authorName(for: quotation) {
            return "\(author) — \(snippet)"
        }
        return snippet
    }

    private static func clip(_ text: String, to limit: Int) -> String {
        guard limit > 0 else { return "" }
        guard text.count > limit else { return text }
        guard limit > truncationSuffix.count else {
            return String(text.prefix(limit))
        }
        return String(text.prefix(limit - truncationSuffix.count)) + truncationSuffix
    }
}
