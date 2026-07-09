//
//  SourceDetailView.swift
//  Quotations
//
//  Right-hand pane: opaque background, list of quotations for the selected source.
//

import SwiftUI
import SwiftData

struct SourceDetailView: View {
    let source: Source
    let searchQuery: String
    var quotationIdsFilter: Set<PersistentIdentifier>?
    @Binding var selectedQuotationId: PersistentIdentifier?
    var newQuotationId: PersistentIdentifier?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                SourceSectionView(
                    source: source,
                    searchQuery: searchQuery,
                    selectedQuotationId: $selectedQuotationId,
                    showsBackground: false
                ) {
                    QuotationListView(
                        source: source,
                        searchQuery: searchQuery,
                        quotationIdsFilter: quotationIdsFilter,
                        selectedQuotationId: $selectedQuotationId,
                        newQuotationId: newQuotationId
                    )
                    .padding(.top, LayoutMetrics.quotationListTopPadding)
                    .padding(.bottom, LayoutMetrics.quotationListBottomPadding)
                }
            }
            .onChange(of: selectedQuotationId) { _, newID in
                guard let newID else { return }
                withAnimation {
                    proxy.scrollTo(newID, anchor: .center)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .deselectQuotationOnBackgroundTap($selectedQuotationId)
    }
}
