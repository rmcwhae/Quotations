//
//  QuotationSearchText.swift
//  Quotations
//

import Foundation
import SwiftData

enum QuotationSearchText {
    static func plainContent(from markdown: String) -> String {
        QuotationWidgetFilter.plainText(from: markdown)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func searchableBody(for quotation: Quotation) -> String? {
        guard quotation.deletedAt == nil,
              let source = quotation.source,
              source.deletedAt == nil else {
            return nil
        }

        let content = plainContent(from: quotation.content)
        guard !content.isEmpty else { return nil }

        var parts = [content]
        parts.append(source.title)
        if let author = source.author, author.deletedAt == nil {
            parts.append(author.name)
        }
        if let location = quotation.location, !location.isEmpty {
            parts.append(location)
        }
        return parts.joined(separator: "\n")
    }

    static func displayTitle(for quotation: Quotation) -> String {
        quotation.source?.title ?? "Quotation"
    }

    static func authorName(for quotation: Quotation) -> String? {
        guard let author = quotation.source?.author, author.deletedAt == nil else { return nil }
        return author.name
    }
}
