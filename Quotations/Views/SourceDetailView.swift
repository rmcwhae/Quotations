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
    @Binding var showQuotationForm: Bool

    var body: some View {
        SourceSectionView(
            source: source,
            searchQuery: searchQuery,
            quotationIdsFilter: quotationIdsFilter,
            showQuotationForm: $showQuotationForm
        ) { showForm in
            ScrollView {
                QuotationListView(
                    source: source,
                    searchQuery: searchQuery,
                    quotationIdsFilter: quotationIdsFilter,
                    selectedQuotationId: $selectedQuotationId,
                    showQuotationForm: showForm
                )
                .padding(.vertical, 16)
            }
            .scrollContentBackground(.hidden)
            .simultaneousGesture(
                TapGesture().onEnded { selectedQuotationId = nil }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
