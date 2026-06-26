//
//  QuotationListView.swift
//  Quotations
//

import SwiftUI
import SwiftData

private struct DiamondDivider: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 6))
                .foregroundStyle(AppColors.dividerColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

struct QuotationListView: View {
    let source: Source
    let searchQuery: String
    var quotationIdsFilter: Set<PersistentIdentifier>?
    @Binding var selectedQuotationId: PersistentIdentifier?
    @Binding var showQuotationForm: Bool

    @Query private var quotations: [Quotation]
    @Environment(\.modelContext) private var modelContext

    init(source: Source, searchQuery: String, quotationIdsFilter: Set<PersistentIdentifier>? = nil, selectedQuotationId: Binding<PersistentIdentifier?>, showQuotationForm: Binding<Bool>) {
        self.source = source
        self.searchQuery = searchQuery
        self.quotationIdsFilter = quotationIdsFilter
        _selectedQuotationId = selectedQuotationId
        _showQuotationForm = showQuotationForm
        let sourceId = source.id
        _quotations = Query(
            filter: #Predicate<Quotation> { q in
                q.deletedAt == nil && q.source?.id == sourceId
            },
            sort: [SortDescriptor(\.createdAt, order: .reverse)]
        )
    }

    private var displayedQuotations: [Quotation] {
        guard let filter = quotationIdsFilter else { return quotations }
        return quotations.filter { filter.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showQuotationForm {
                QuotationFormView(
                    source: source,
                    onSuccess: { showQuotationForm = false },
                    onCancel: { showQuotationForm = false }
                )
                .padding(.vertical, 6)
                DiamondDivider()
            }

            ForEach(Array(displayedQuotations.enumerated()), id: \.element.id) { index, quotation in
                QuotationRowView(
                    quotation: quotation,
                    searchQuery: searchQuery,
                    isSelected: quotation.id == selectedQuotationId,
                    onSelect: { selectedQuotationId = quotation.id },
                    onEdit: saveQuotation,
                    onDelete: deleteQuotation
                )
                .padding(.vertical, 6)
                if index < displayedQuotations.count - 1 {
                    DiamondDivider()
                }
            }
        }
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
