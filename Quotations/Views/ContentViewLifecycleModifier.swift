//
//  ContentViewLifecycleModifier.swift
//  Quotations
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ContentViewLifecycleModifier: ViewModifier {
    let modelContext: ModelContext
    @Binding var showCSVImporter: Bool
    @Binding var showBackups: Bool
    @Binding var showError: Bool
    @Binding var errorMessage: String?
    @Binding var selectedSourceId: PersistentIdentifier?
    @Binding var selectedQuotationId: PersistentIdentifier?
    let newQuotationId: PersistentIdentifier?
    let deepLinkRouter: DeepLinkRouter
    let sourcesCount: Int
    let quotationsCount: Int
    let searchState: SearchState
    let onImportCSV: (URL) -> Void
    let onBeginCSVImport: () -> Void
    let onImportFromAppleBooks: () -> Void
    let onAddQuotation: () -> Void
    let onOpenAdvancedSearch: () -> Void
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
            .onReceive(NotificationCenter.default.publisher(for: .showBackupsPanel)) { _ in
                showBackups = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .focusFindInPage)) { _ in
                ToolbarFindFocus.activate()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openAdvancedSearch)) { _ in
                onOpenAdvancedSearch()
            }
            .onReceive(NotificationCenter.default.publisher(for: .importFromAppleBooks)) { _ in
                onImportFromAppleBooks()
            }
            .onReceive(NotificationCenter.default.publisher(for: .importQuotationsFromCSV)) { _ in
                onBeginCSVImport()
            }
            .onReceive(NotificationCenter.default.publisher(for: .addQuotation)) { _ in
                onAddQuotation()
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
            .fileImporter(
                isPresented: $showCSVImporter,
                allowedContentTypes: [.commaSeparatedText, .plainText, .text],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    onImportCSV(url)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            .onChange(of: selectedSourceId) { _, _ in
                onCleanupNewQuotation()
            }
            .onChange(of: selectedQuotationId) { _, newValue in
                if let newQuotationId, newValue != newQuotationId {
                    onCleanupNewQuotation()
                }
            }
            .navigationTitle("")
    }
}
