//
//  QuotationListView.swift
//  Quotations
//

import SwiftUI
import SwiftData

/// Renders quotation rows for a fixed list of models (search results; no live `@Query`).
struct QuotationRowsContent: View {
    let quotations: [Quotation]
    let searchQuery: String
    var newQuotationId: PersistentIdentifier?
    @Binding var selectedQuotationIdBinding: PersistentIdentifier?
    var onEdit: (Quotation) -> Void
    var onDelete: (PersistentIdentifier) -> Void

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(quotations) { quotation in
                QuotationRowView(
                    quotation: quotation,
                    searchQuery: searchQuery,
                    isSelected: quotation.id == selectedQuotationIdBinding,
                    beginEditing: quotation.id == newQuotationId,
                    newQuotationId: newQuotationId,
                    onSelect: { selectedQuotationIdBinding = quotation.id },
                    onDeselect: { selectedQuotationIdBinding = nil },
                    onEdit: onEdit,
                    onDelete: onDelete
                )
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: LayoutMetrics.quotationColumnMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity)
    }
}

struct QuotationListView: View {
    let source: Source
    let searchQuery: String
    var quotationIdsFilter: Set<PersistentIdentifier>?
    @Binding var selectedQuotationId: PersistentIdentifier?
    var newQuotationId: PersistentIdentifier?

    @Query private var quotations: [Quotation]
    @Environment(\.modelContext) private var modelContext

    init(source: Source, searchQuery: String, quotationIdsFilter: Set<PersistentIdentifier>? = nil, selectedQuotationId: Binding<PersistentIdentifier?>, newQuotationId: PersistentIdentifier? = nil) {
        self.source = source
        self.searchQuery = searchQuery
        self.quotationIdsFilter = quotationIdsFilter
        _selectedQuotationId = selectedQuotationId
        self.newQuotationId = newQuotationId
        let sourceId = source.persistentModelID
        _quotations = Query(
            filter: #Predicate<Quotation> { q in
                q.deletedAt == nil && q.source?.persistentModelID == sourceId
            },
            sort: [SortDescriptor(\.createdAt, order: .reverse)]
        )
    }

    private var displayedQuotations: [Quotation] {
        guard let filter = quotationIdsFilter else { return quotations }
        return quotations.filter { filter.contains($0.id) }
    }

    var body: some View {
        if quotationIdsFilter == nil && quotations.isEmpty {
            VStack {
                Spacer()
                Text("No quotations yet.")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        } else if quotationIdsFilter != nil && displayedQuotations.isEmpty {
            Text("No matching quotations.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 16)
        } else {
            QuotationRowsContent(
                quotations: displayedQuotations,
                searchQuery: searchQuery,
                newQuotationId: newQuotationId,
                selectedQuotationIdBinding: $selectedQuotationId,
                onEdit: saveQuotation,
                onDelete: deleteQuotation
            )
        }
    }

    private func saveQuotation(_ quotation: Quotation) {
        quotation.updatedAt = Date()
        try? modelContext.saveAndNotify()
    }

    private func deleteQuotation(id: PersistentIdentifier) {
        guard let quotation = modelContext.model(for: id) as? Quotation,
              quotation.deletedAt == nil else { return }
        try? SoftDelete.quotation(quotation, in: modelContext)
        if selectedQuotationId == id {
            selectedQuotationId = nil
        }
    }
}
