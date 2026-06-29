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

    @Query private var quotations: [Quotation]

    init(source: Source, searchQuery: String, quotationIdsFilter: Set<PersistentIdentifier>? = nil, selectedQuotationId: Binding<PersistentIdentifier?>, newQuotationId: PersistentIdentifier? = nil) {
        self.source = source
        self.searchQuery = searchQuery
        self.quotationIdsFilter = quotationIdsFilter
        _selectedQuotationId = selectedQuotationId
        self.newQuotationId = newQuotationId
        let sourceId = source.persistentModelID
        _quotations = Query(filter: #Predicate<Quotation> { q in
            q.deletedAt == nil && q.source?.persistentModelID == sourceId
        })
    }

    var body: some View {
        SourceSectionView(
            source: source,
            searchQuery: searchQuery,
            quotationIdsFilter: quotationIdsFilter,
            showsAddButton: false,
            selectedQuotationId: $selectedQuotationId
        ) { _ in
            if quotationIdsFilter == nil && quotations.isEmpty {
                VStack {
                    Spacer()
                    Text("No quotations yet.")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .deselectQuotationOnBackgroundTap($selectedQuotationId)
            } else {
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

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .deselectQuotationOnBackgroundTap($selectedQuotationId)
                }
                .scrollContentBackground(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
