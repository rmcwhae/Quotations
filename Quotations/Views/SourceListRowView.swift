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

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HighlightMatch(text: source.title, query: searchQuery)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)

            if let author = source.author {
                HighlightMatch(
                    text: author.name + (source.publicationYear.map { " (\($0))" } ?? ""),
                    query: searchQuery
                )
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
