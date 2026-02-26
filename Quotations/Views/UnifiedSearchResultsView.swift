//
//  UnifiedSearchResultsView.swift
//  Quotations
//
//  Right-hand pane when searching: all matching sources shown in one scrollable view.
//

import SwiftData
import SwiftUI

struct UnifiedSearchResultsView: View {
    let sources: [Source]
    let searchQuery: String
    var quotationIdsFilter: Set<PersistentIdentifier>?

    private let horizontalPadding: CGFloat = 16

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(sources.enumerated()), id: \.element.id) { index, source in
                    SingleSourceSearchSection(
                        source: source,
                        searchQuery: searchQuery,
                        quotationIdsFilter: quotationIdsFilter,
                        horizontalPadding: horizontalPadding
                    )
                    if index < sources.count - 1 {
                        Divider()
                            .padding(.vertical, 16)
                    }
                }
            }
            .padding(horizontalPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct SingleSourceSearchSection: View {
    let source: Source
    let searchQuery: String
    var quotationIdsFilter: Set<PersistentIdentifier>?
    var horizontalPadding: CGFloat

    var body: some View {
        SourceSectionView(
            source: source,
            searchQuery: searchQuery,
            quotationIdsFilter: quotationIdsFilter,
            headerOutset: horizontalPadding
        ) {
            QuotationListView(
                source: source,
                searchQuery: searchQuery,
                quotationIdsFilter: quotationIdsFilter
            )
            .padding(.top, 8)
        }
    }
}
