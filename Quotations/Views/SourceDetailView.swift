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
    var newQuotationId: PersistentIdentifier?

    var body: some View {
        SourceSectionView(
            source: source,
            searchQuery: searchQuery,
            quotationIdsFilter: quotationIdsFilter,
            showsAddButton: false
        ) { _ in
            ScrollView {
                VStack(spacing: 0) {
                    QuotationListView(
                        source: source,
                        searchQuery: searchQuery,
                        quotationIdsFilter: quotationIdsFilter,
                        selectedQuotationId: $selectedQuotationId,
                        newQuotationId: newQuotationId
                    )
                    .padding(.vertical, 16)

                    Color.clear
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedQuotationId = nil }
                }
            }
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
