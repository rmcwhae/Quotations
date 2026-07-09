//
//  SourceDetailView.swift
//  Quotations
//
//  Right-hand pane: opaque background, list of quotations for the selected source.
//

import SwiftUI
import SwiftData

struct SourceDetailView: View {
    let source: Source
    let searchQuery: String
    var quotationIdsFilter: Set<PersistentIdentifier>?
    var semanticQuotationIds: Set<PersistentIdentifier> = []
    @Binding var selectedQuotationId: PersistentIdentifier?
    var newQuotationId: PersistentIdentifier?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                SourceSectionView(
                    source: source,
                    searchQuery: searchQuery,
                    selectedQuotationId: $selectedQuotationId,
                    showsBackground: false
                ) {
                    QuotationListView(
                        source: source,
                        searchQuery: searchQuery,
                        quotationIdsFilter: quotationIdsFilter,
                        semanticQuotationIds: semanticQuotationIds,
                        selectedQuotationId: $selectedQuotationId,
                        newQuotationId: newQuotationId
                    )
                    .padding(.top, LayoutMetrics.quotationListTopPadding)
                    .padding(.bottom, LayoutMetrics.quotationListBottomPadding)
                }
            }
            .onAppear {
                scrollToSelectedQuotation(using: proxy)
            }
            .onChange(of: selectedQuotationId) { _, _ in
                scrollToSelectedQuotation(using: proxy)
            }
        }
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .deselectQuotationOnBackgroundTap($selectedQuotationId)
    }

    private func scrollToSelectedQuotation(using proxy: ScrollViewProxy) {
        guard let id = selectedQuotationId else { return }
        Task { @MainActor in
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(100))
            withAnimation {
                proxy.scrollTo(id, anchor: .center)
            }
        }
    }
}
