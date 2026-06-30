//
//  UnifiedSearchResultsView.swift
//  Quotations
//
//  Right-hand pane when searching: all matching sources shown in one scrollable view.
//

import SwiftData
import SwiftUI

struct UnifiedSearchResultsView: View {
    let sources: [Source]
    let searchQuery: String
    var quotationsBySourceId: [PersistentIdentifier: [PersistentIdentifier]]
    @Binding var selectedQuotationId: PersistentIdentifier?
    var newQuotationId: PersistentIdentifier?
    /// Centered placeholder shown when there are no matching sources (searching / no results).
    var statusMessage: String?

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let statusMessage {
                    Text(statusMessage)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 80)
                } else {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(sources) { source in
                            SingleSourceSearchSection(
                                source: source,
                                searchQuery: searchQuery,
                                quotationIds: quotationsBySourceId[source.persistentModelID] ?? [],
                                selectedQuotationId: $selectedQuotationId,
                                newQuotationId: newQuotationId
                            )
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .deselectQuotationOnBackgroundTap($selectedQuotationId)
    }
}

private struct SingleSourceSearchSection: View {
    let source: Source
    let searchQuery: String
    let quotationIds: [PersistentIdentifier]
    @Binding var selectedQuotationId: PersistentIdentifier?
    var newQuotationId: PersistentIdentifier?

    @Environment(\.modelContext) private var modelContext

    private var resolvedQuotations: [Quotation] {
        quotationIds.compactMap { modelContext.model(for: $0) as? Quotation }
            .filter { $0.deletedAt == nil }
    }

    var body: some View {
        SourceSectionView(
            source: source,
            searchQuery: searchQuery,
            selectedQuotationId: $selectedQuotationId,
            showsBackground: false
        ) {
            if resolvedQuotations.isEmpty {
                Text("No matching quotations.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                QuotationRowsContent(
                    quotations: resolvedQuotations,
                    searchQuery: searchQuery,
                    newQuotationId: newQuotationId,
                    selectedQuotationIdBinding: $selectedQuotationId,
                    onEdit: saveQuotation,
                    onDelete: deleteQuotation
                )
                .padding(.top, LayoutMetrics.quotationListTopPadding)
                .padding(.bottom, LayoutMetrics.quotationListBottomPadding)
            }
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
