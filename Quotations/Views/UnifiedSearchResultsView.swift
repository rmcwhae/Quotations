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
    @Binding var selectedQuotationId: PersistentIdentifier?

    private let horizontalPadding: CGFloat = 16

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(sources.enumerated()), id: \.element.id) { _, source in
                        SingleSourceSearchSection(
                            source: source,
                            searchQuery: searchQuery,
                            quotationIdsFilter: quotationIdsFilter,
                            selectedQuotationId: $selectedQuotationId,
                            horizontalPadding: horizontalPadding
                        )
                    }
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .deselectQuotationOnBackgroundTap($selectedQuotationId)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct SingleSourceSearchSection: View {
    let source: Source
    let searchQuery: String
    var quotationIdsFilter: Set<PersistentIdentifier>?
    @Binding var selectedQuotationId: PersistentIdentifier?
    var horizontalPadding: CGFloat

    var body: some View {
        SourceSectionView(
            source: source,
            searchQuery: searchQuery,
            quotationIdsFilter: quotationIdsFilter,
            showsAddButton: false,
            selectedQuotationId: $selectedQuotationId
        ) { _ in
            QuotationListView(
                source: source,
                searchQuery: searchQuery,
                quotationIdsFilter: quotationIdsFilter,
                selectedQuotationId: $selectedQuotationId
            )
            .padding(.top, 8)
        }
    }
}
