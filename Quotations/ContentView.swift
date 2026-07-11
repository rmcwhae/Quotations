//
//  ContentView.swift
//  Quotations
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Environment(BackupManager.self) var backupManager
    @Environment(DeepLinkRouter.self) var deepLinkRouter

    @Query(filter: #Predicate<Source> { $0.deletedAt == nil })
    var sources: [Source]

    @Query(filter: #Predicate<Quotation> { $0.deletedAt == nil })
    var quotations: [Quotation]

    @State var navigation = LibraryNavigationState()
    @State var searchState = SearchState()
    @State var findInPage = FindInPageState()
    @State var exploreState = ExploreState()
    @State var chatState = ChatState()
    @State var newSourceSession: NewSourceSheetSession?
    @State var showAuthorList = false
    @State var showBackups = false
    @State var isImporting = false
    @State var showCSVImporter = false
    @State var csvImportSourceId: PersistentIdentifier?
    @State var showImportSuccess = false
    @State var importSuccessMessage: String?
    @State var errorMessage: String?
    @State var showError = false
    @State var sourceToEdit: Source?
    @State var sourceToDelete: Source?
    @State var showDeleteSourceConfirmation = false
    @State var showDeleteQuotationConfirmation = false
    @State var isInspectorShown = false
    @State var newQuotationId: PersistentIdentifier?
    @State var unresolvedDeepLinkURL: URL?

    var isOnSearchPage: Bool {
        navigation.selectedFilter == .searchResults
    }

    var selectedSource: Source? {
        guard let id = navigation.selectedSourceId else { return nil }
        // Prefer @Query results. Avoid `model(for:)` — it returns a stub for stale/
        // temporary IDs, and reading any property (e.g. deletedAt) traps.
        return sources.first { $0.persistentModelID == id }
    }

    var selectedQuotation: Quotation? {
        guard let id = navigation.selectedQuotationId else { return nil }
        return quotations.first { $0.persistentModelID == id }
    }

    var body: some View {
        @Bindable var navigation = navigation
        @Bindable var findInPage = findInPage
        @Bindable var exploreState = exploreState
        @Bindable var chatState = chatState

        splitView(
            shell: ContentViewShellState(
                navigation: navigation,
                findInPage: findInPage,
                exploreState: exploreState,
                chatState: chatState,
                selectedSourceId: $navigation.selectedSourceId,
                selectedQuotationId: $navigation.selectedQuotationId,
                findQuery: $findInPage.query
            )
        )
        .onDeleteCommand {
            guard navigation.selectedQuotationId != nil else { return }
            showDeleteQuotationConfirmation = true
        }
        .modifier(ContentViewLifecycleModifier(
            modelContext: modelContext,
            selectedSourceId: $navigation.selectedSourceId,
            selectedQuotationId: $navigation.selectedQuotationId,
            newQuotationId: newQuotationId,
            deepLinkRouter: deepLinkRouter,
            sourcesCount: sources.count,
            quotationsCount: quotations.count,
            searchState: searchState,
            onAppear: consumePendingDeepLinkIfNeeded,
            onPendingURLChange: consumePendingDeepLinkIfNeeded,
            onRetryDeepLink: retryUnresolvedDeepLinkIfNeeded,
            onDeepLinkReceived: consumePendingDeepLinkIfNeeded,
            onCleanupNewQuotation: cleanupNewQuotationIfEmpty
        ))
        .modifier(ContentViewImportLifecycleModifier(
            showCSVImporter: $showCSVImporter,
            showBackups: $showBackups,
            showError: $showError,
            errorMessage: $errorMessage,
            onImportCSV: importCSV,
            onBeginCSVImport: beginCSVImport,
            onImportFromAppleBooks: importFromAppleBooks,
            onAddQuotation: addQuotation,
            onOpenAdvancedSearch: { selectFilter(.searchResults) }
        ))
        .modifier(ContentViewSheetsModifier(
                showError: $showError,
                errorMessage: errorMessage,
                showImportSuccess: $showImportSuccess,
                importSuccessMessage: importSuccessMessage,
                showAuthorList: $showAuthorList,
                showBackups: $showBackups,
                newSourceSession: $newSourceSession,
                sourceToEdit: $sourceToEdit,
                showDeleteSourceConfirmation: $showDeleteSourceConfirmation,
                sourceToDelete: $sourceToDelete,
                showDeleteQuotationConfirmation: $showDeleteQuotationConfirmation,
                selectedSourceId: $navigation.selectedSourceId,
                selectedQuotationId: $navigation.selectedQuotationId,
                modelContext: modelContext,
                onEditError: { message in
                    errorMessage = message
                    showError = true
                },
                onSourceCreated: handleSourceCreated
            ))
    }

    @ViewBuilder
    private func splitView(shell: ContentViewShellState) -> some View {
        Group {
            if shouldShowDetailColumn {
                NavigationSplitView {
                    filterSidebar
                } content: {
                    contextList(shell: shell)
                } detail: {
                    detailPane
                }
            } else {
                NavigationSplitView {
                    filterSidebar
                } detail: {
                    contextList(shell: shell)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .searchable(
            text: shell.findQuery,
            placement: .toolbar,
            prompt: "Find"
        )
        .onKeyPress(.escape) {
            if !shell.findInPage.trimmedQuery.isEmpty {
                shell.findInPage.query = ""
                return .handled
            }
            guard shell.navigation.selectedQuotationId != nil else { return .ignored }
            shell.navigation.clearQuotationSelection()
            return .handled
        }
        .onChange(of: shouldShowDetailColumn) { _, showDetail in
            if !showDetail {
                isInspectorShown = false
            }
        }
    }

    private var filterSidebar: some View {
        LibraryFilterSidebarView(
            selectedFilter: navigation.selectedFilter,
            onSelectFilter: selectFilter
        )
        .equatable()
    }

    private func contextList(shell: ContentViewShellState) -> some View {
        LibraryContextListView(
            filter: shell.navigation.selectedFilter,
            sources: sources,
            quotations: quotations,
            searchState: searchState,
            findQuery: shell.findInPage.query,
            exploreState: shell.exploreState,
            chatState: shell.chatState,
            onExploreWordSelected: { openAdvancedSearch(for: $0) },
            onChatCitationSelected: { quotationId, sourceId in
                shell.navigation.selectQuotation(quotationId, sourceId: sourceId)
            },
            selectedSourceId: shell.selectedSourceId,
            selectedQuotationId: shell.selectedQuotationId,
            onManageAuthors: { showAuthorList = true },
            onAddSource: { newSourceSession = NewSourceSheetSession() },
            onSourceEdit: { sourceToEdit = $0 },
            onSourceDelete: { source in
                sourceToDelete = source
                showDeleteSourceConfirmation = true
            }
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Author.self, Source.self, Quotation.self], inMemory: true)
        .environment(BackupManager(storeURL: URL(fileURLWithPath: "/tmp/default.store")))
        .environment(DeepLinkRouter())
        .environment(StopWordsStore(userDefaults: UserDefaults(suiteName: "ContentViewPreview")!))
}
