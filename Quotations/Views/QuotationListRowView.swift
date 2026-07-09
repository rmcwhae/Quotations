//
//  QuotationListRowView.swift
//  Quotations
//
//  Compact row for column 2 quotation lists: excerpt, source title, author.
//

import SwiftData
import SwiftUI

struct QuotationListRowView: View {
    let quotation: Quotation
    let searchQuery: String
    var isSelected: Bool = false
    var isSemanticMatch: Bool = false

    private var excerpt: String {
        let trimmed = quotation.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 120 { return trimmed }
        return String(trimmed.prefix(117)) + "…"
    }

    private var accessibilitySummary: String {
        let sourceTitle = quotation.source?.title ?? "Unknown source"
        let author = quotation.source?.author?.name
        let matchKind = isSemanticMatch ? "Concept match. " : ""
        if let author {
            return "\(matchKind)\(excerpt), from \(sourceTitle) by \(author)"
        }
        return "\(matchKind)\(excerpt), from \(sourceTitle)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HighlightMatch(text: excerpt, query: searchQuery)
                .font(.system(size: 13, design: .serif))
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            HStack(spacing: 8) {
                if let source = quotation.source {
                    HStack(spacing: 4) {
                        HighlightMatch(text: source.title, query: searchQuery)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                        if let author = source.author {
                            Text("·")
                                .foregroundStyle(.tertiary)
                            HighlightMatch(text: author.name, query: searchQuery)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer(minLength: 0)

                if isSemanticMatch {
                    SemanticMatchBadge()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
