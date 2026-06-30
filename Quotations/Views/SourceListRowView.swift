//
//  SourceListRowView.swift
//  Quotations
//
//  Compact row for the sidebar: title on first line, author (date) on second.
//

import SwiftData
import SwiftUI

struct SourceListRowView: View {
    let source: Source
    let searchQuery: String
    var isSelected: Bool = false
    var showsQuotationCount: Bool = false

    private var activeQuotationCount: Int {
        source.quotations.filter { $0.deletedAt == nil }.count
    }

    private var accessibilitySummary: String {
        var summary: String
        if let author = source.author {
            let year = source.publicationYear.map { " (\($0))" } ?? ""
            summary = "\(source.title), \(author.name)\(year)"
        } else {
            summary = source.title
        }
        if showsQuotationCount {
            let count = activeQuotationCount
            summary += ", \(count == 1 ? "1 quotation" : "\(count) quotations")"
        }
        return summary
    }

    private func quotationCountLabel(_ count: Int) -> String {
        count == 1 ? "1 quotation" : "\(count) quotations"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HighlightMatch(text: source.title, query: searchQuery)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)

            if let author = source.author {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    HighlightMatch(
                        text: author.name + (source.publicationYear.map { " (\($0))" } ?? ""),
                        query: searchQuery
                    )
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if showsQuotationCount {
                        Text(quotationCountLabel(activeQuotationCount))
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                            .fixedSize()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
