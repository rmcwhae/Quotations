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
    var newQuotationId: PersistentIdentifier?

    @Environment(\.colorScheme) private var colorScheme

    private let horizontalPadding: CGFloat = 16

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Divider()

                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(sources) { source in
                        SingleSourceSearchSection(
                            source: source,
                            searchQuery: searchQuery,
                            quotationIdsFilter: quotationIdsFilter,
                            selectedQuotationId: $selectedQuotationId,
                            newQuotationId: newQuotationId,
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
        .background(
            AppColors.mainBackground(colorScheme: colorScheme)
                .ignoresSafeArea(.container, edges: .top)
        )
    }
}

private struct SingleSourceSearchSection: View {
    let source: Source
    let searchQuery: String
    var quotationIdsFilter: Set<PersistentIdentifier>?
    @Binding var selectedQuotationId: PersistentIdentifier?
    var newQuotationId: PersistentIdentifier?
    var horizontalPadding: CGFloat

    var body: some View {
        SourceSectionView(
            source: source,
            searchQuery: searchQuery,
            quotationIdsFilter: quotationIdsFilter,
            selectedQuotationId: $selectedQuotationId
        ) {
            QuotationListView(
                source: source,
                searchQuery: searchQuery,
                quotationIdsFilter: quotationIdsFilter,
                selectedQuotationId: $selectedQuotationId,
                newQuotationId: newQuotationId
            )
            .padding(.top, 8)
        }
    }
}
