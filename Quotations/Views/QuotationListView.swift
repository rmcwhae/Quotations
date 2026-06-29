//
//  QuotationListView.swift
//  Quotations
//

import SwiftUI
import SwiftData

struct QuotationListView: View {
    let source: Source
    let searchQuery: String
    var quotationIdsFilter: Set<PersistentIdentifier>?
    @Binding var selectedQuotationId: PersistentIdentifier?
    /// The id of a freshly added quotation that should open in edit mode.
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

    /// Natural width of a quotation row: leading 28 + quote mark 36 + text
    /// padding 16 + text 520 + trailing 16. Constraining to this and centering
    /// gives the column a `margin: 0 auto` layout within the window.
    private let columnMaxWidth: CGFloat = 616

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(displayedQuotations) { quotation in
                QuotationRowView(
                    quotation: quotation,
                    searchQuery: searchQuery,
                    isSelected: quotation.id == selectedQuotationId,
                    beginEditing: quotation.id == newQuotationId,
                    onSelect: { selectedQuotationId = quotation.id },
                    onDeselect: { selectedQuotationId = nil },
                    onEdit: saveQuotation,
                    onDelete: deleteQuotation
                )
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: columnMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity)
        .deselectQuotationOnBackgroundTap($selectedQuotationId)
    }

    private func saveQuotation(_ quotation: Quotation) {
        quotation.updatedAt = Date()
        try? modelContext.save()
    }

    private func deleteQuotation(id: PersistentIdentifier) {
        guard let quotation = quotations.first(where: { $0.id == id }) else { return }
        quotation.deletedAt = Date()
        quotation.updatedAt = Date()
        try? modelContext.save()
    }
}

extension View {
    /// Clears quotation selection when the user clicks empty space or presses Escape.
    func deselectQuotationOnBackgroundTap(_ selectedQuotationId: Binding<PersistentIdentifier?>) -> some View {
        background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedQuotationId.wrappedValue = nil
                }
        }
        .onKeyPress(.escape) {
            guard selectedQuotationId.wrappedValue != nil else { return .ignored }
            selectedQuotationId.wrappedValue = nil
            return .handled
        }
    }
}
