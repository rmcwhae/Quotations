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
    /// Live quotation count to show, or nil to hide it. Passed in (counted once by the
    /// parent) so each row doesn't fault its `quotations` relationship on every render.
    var quotationCount: Int?

    private var accessibilitySummary: String {
        var summary: String
        if let author = source.author {
            let year = source.publicationYear.map { " (\($0))" } ?? ""
            summary = "\(source.title), \(author.name)\(year)"
        } else {
            summary = source.title
        }
        if let quotationCount {
            summary += ", \(quotationCountLabel(quotationCount))"
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

                    if let quotationCount {
                        Text(quotationCountLabel(quotationCount))
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
