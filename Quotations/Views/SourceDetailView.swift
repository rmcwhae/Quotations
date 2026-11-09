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
    let findQuery: String
    var quotationIdsFilter: Set<PersistentIdentifier>?
    @Binding var selectedQuotationId: PersistentIdentifier?
    var newQuotationId: PersistentIdentifier?

    @State private var isScrolledPastTop = false
    /// Quotation rows at least half on screen; a selection among these is not scrolled to.
    @State private var visibleQuotationIds: Set<PersistentIdentifier> = []

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                SourceHeaderView(
                    source: source,
                    findQuery: findQuery,
                    selectedQuotationId: $selectedQuotationId,
                    showsScrolledChrome: isScrolledPastTop
                )

                ScrollView {
                    QuotationListView(
                        source: source,
                        findQuery: findQuery,
                        quotationIdsFilter: quotationIdsFilter,
                        selectedQuotationId: $selectedQuotationId,
                        newQuotationId: newQuotationId
                    )
                    .padding(.top, LayoutMetrics.quotationListTopPadding)
                    .padding(.bottom, LayoutMetrics.quotationListBottomPadding)
                }
                .scrollContentBackground(.hidden)
                .onScrollTargetVisibilityChange(idType: PersistentIdentifier.self, threshold: 0.5) { ids in
                    visibleQuotationIds = Set(ids)
                }
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    geometry.contentOffset.y > geometry.contentInsets.top + 4
                } action: { _, isScrolled in
                    isScrolledPastTop = isScrolled
                }
                .onAppear {
                    scrollToSelectedQuotation(using: proxy)
                }
                .onChange(of: selectedQuotationId) { _, _ in
                    scrollToSelectedQuotation(using: proxy)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .deselectQuotationOnBackgroundTap($selectedQuotationId)
    }

    /// Scrolls only when the selection is off screen (deep link, list column, chat, map) —
    /// never when the user just clicked a row they can see, which would move it under the mouse.
    private func scrollToSelectedQuotation(using proxy: ScrollViewProxy) {
        guard let id = selectedQuotationId, !visibleQuotationIds.contains(id) else { return }
        Task { @MainActor in
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(100))
            withAnimation {
                proxy.scrollTo(id, anchor: .center)
            }
        }
    }
}
