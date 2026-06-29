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
    fileprivate let columnMaxWidth: CGFloat = 616

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
        }
    }

    private func saveQuotation(_ quotation: Quotation) {
        quotation.updatedAt = Date()
        try? modelContext.save()
        NotificationCenter.default.post(name: .quotationsDataDidChange, object: nil)
    }

    private func deleteQuotation(id: PersistentIdentifier) {
        guard let quotation = modelContext.model(for: id) as? Quotation else { return }
        quotation.deletedAt = Date()
        quotation.updatedAt = Date()
        try? modelContext.save()
        NotificationCenter.default.post(name: .quotationsDataDidChange, object: nil)
    }
}
