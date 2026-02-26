//
//  QuotationListView.swift
//  Quotations
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private struct DiamondDivider: View {
    private var dividerColor: Color {
        #if os(macOS)
        Color(nsColor: .tertiaryLabelColor)
        #else
        Color(uiColor: .tertiaryLabel)
        #endif
    }

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(dividerColor)
                .frame(height: 1)
                .frame(maxWidth: .infinity)
            Image(systemName: "diamond.fill")
                .font(.system(size: 6))
                .foregroundStyle(dividerColor)
            Rectangle()
                .fill(dividerColor)
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
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
