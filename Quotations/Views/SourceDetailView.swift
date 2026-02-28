//
//  SourceDetailView.swift
//  Quotations
//
//  Right-hand pane: opaque background, list of quotations for the selected source.
//

import SwiftData
import SwiftUI

struct SourceDetailView: View {
    let source: Source
    let searchQuery: String
    var quotationIdsFilter: Set<PersistentIdentifier>?
    @Binding var selectedQuotationId: PersistentIdentifier?

    var body: some View {
        SourceSectionView(
            source: source,
            searchQuery: searchQuery,
            quotationIdsFilter: quotationIdsFilter
        ) {
            ScrollView {
                QuotationListView(
                    source: source,
                    searchQuery: searchQuery,
                    quotationIdsFilter: quotationIdsFilter,
                    selectedQuotationId: $selectedQuotationId
                )
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
