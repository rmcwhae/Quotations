//
//  ContentViewLifecycleModifier.swift
//  Quotations
//

import SwiftData
import SwiftUI

struct ContentViewLifecycleModifier: ViewModifier {
    let modelContext: ModelContext
    @Binding var selectedSourceId: PersistentIdentifier?
    @Binding var selectedQuotationId: PersistentIdentifier?
    let newQuotationId: PersistentIdentifier?
    let deepLinkRouter: DeepLinkRouter
    let sourcesCount: Int
    let quotationsCount: Int
    let searchState: SearchState
    let onAppear: () -> Void
    let onPendingURLChange: () -> Void
    let onRetryDeepLink: () -> Void
    let onDeepLinkReceived: () -> Void
    let onCleanupNewQuotation: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: searchState.query) { _, _ in
                searchState.runSearchIfNeeded(modelContext: modelContext)
            }
            .onReceive(NotificationCenter.default.publisher(for: .quotationsDataDidChange)) { _ in
                searchState.runSearchIfNeeded(modelContext: modelContext)
                QuotationSearchIndexManager.scheduleSync(modelContext: modelContext)
            }
            .onAppear(perform: onAppear)
            .onOpenURL { url in
                deepLinkRouter.enqueue(url)
            }
            .onChange(of: deepLinkRouter.pendingURL) { _, _ in
                onPendingURLChange()
            }
            .onChange(of: sourcesCount) { _, _ in
                onRetryDeepLink()
            }
            .onChange(of: quotationsCount) { _, _ in
                onRetryDeepLink()
            }
            .onReceive(NotificationCenter.default.publisher(for: .quotationDeepLinkReceived)) { _ in
                onDeepLinkReceived()
            }
            .onChange(of: selectedSourceId) { _, _ in
                onCleanupNewQuotation()
            }
            .onChange(of: selectedQuotationId) { _, newValue in
                if let newQuotationId, newValue != newQuotationId {
                    onCleanupNewQuotation()
                }
            }
    }
}
