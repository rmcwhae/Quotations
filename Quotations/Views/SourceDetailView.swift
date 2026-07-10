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
