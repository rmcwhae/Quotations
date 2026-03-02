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
            .padding(horizontalPadding)
        }
        .simultaneousGesture(
            TapGesture().onEnded { selectedQuotationId = nil }
        )
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
            headerOutset: horizontalPadding
        ) { showForm in
            QuotationListView(
                source: source,
                searchQuery: searchQuery,
                quotationIdsFilter: quotationIdsFilter,
                selectedQuotationId: $selectedQuotationId,
                showQuotationForm: showForm
            )
            .padding(.top, 8)
        }
    }
}
