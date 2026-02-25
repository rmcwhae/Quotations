//
//  QuotationListView.swift
//  Quotations
//

import SwiftUI
import SwiftData

private struct DiamondDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    /// Parchment-tinted color for the divider: warm tan (light) / warm dark brown (dark).
    private var parchmentColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.35, green: 0.30, blue: 0.26)
        default:
            return Color(red: 0.72, green: 0.67, blue: 0.60)
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(parchmentColor)
                .frame(height: 1)
                .frame(maxWidth: .infinity)
            Image(systemName: "diamond.fill")
                .font(.system(size: 6))
                .foregroundStyle(parchmentColor)
            Rectangle()
                .fill(parchmentColor)
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
        .opacity(0.5)
    }
}

struct QuotationListView: View {
    let source: Source
    let searchQuery: String
    var quotationIdsFilter: Set<PersistentIdentifier>?

    @Query private var quotations: [Quotation]
    @Environment(\.modelContext) private var modelContext

    init(source: Source, searchQuery: String, quotationIdsFilter: Set<PersistentIdentifier>? = nil) {
        self.source = source
        self.searchQuery = searchQuery
        self.quotationIdsFilter = quotationIdsFilter
        let sourceId = source.id
        _quotations = Query(
            filter: #Predicate<Quotation> { q in
                q.deletedAt == nil && q.source?.id == sourceId
            },
            sort: [SortDescriptor(\.startPage)]
        )
    }

    private var displayedQuotations: [Quotation] {
        guard let filter = quotationIdsFilter else { return quotations }
        return quotations.filter { filter.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(displayedQuotations.enumerated()), id: \.element.id) { index, quotation in
                QuotationRowView(
                    quotation: quotation,
                    searchQuery: searchQuery,
                    onEdit: saveQuotation,
                    onDelete: deleteQuotation
                )
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
