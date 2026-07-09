//
//  ContentView.swift
//  Quotations
//

import AppKit
import os
import SwiftUI
import SwiftData
import Combine
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(BackupManager.self) private var backupManager
    @Environment(DeepLinkRouter.self) private var deepLinkRouter

    @Query(filter: #Predicate<Source> { $0.deletedAt == nil })
    private var sources: [Source]

    @Query(filter: #Predicate<Quotation> { $0.deletedAt == nil })
    private var quotations: [Quotation]

    @State private var navigation = LibraryNavigationState()
    @State private var searchState = SearchState()
    @State private var findInPage = FindInPageState()
    @State private var exploreState = ExploreState()
    @State private var chatState = ChatState()
    @State private var newSourceSession: NewSourceSheetSession?
    @State private var showAuthorList = false
    @State private var showBackups = false
    @State private var isImporting = false
    @State private var showCSVImporter = false
    @State private var csvImportSourceId: PersistentIdentifier?
    @State private var showImportSuccess = false
    @State private var importSuccessMessage: String?
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var sourceToEdit: Source?
    @State private var sourceToDelete: Source?
    @State private var showDeleteSourceConfirmation = false
    @State private var showDeleteQuotationConfirmation = false
    @State private var isInspectorShown = false
    @State private var newQuotationId: PersistentIdentifier?
    @State private var unresolvedDeepLinkURL: URL?

    private var isOnSearchPage: Bool {
        navigation.selectedFilter == .searchResults
    }

    private var selectedSource: Source? {
        guard let id = navigation.selectedSourceId else { return nil }
        if let source = modelContext.model(for: id) as? Source,
           source.deletedAt == nil {
            return source
        }
        return sources.first { $0.id == id }
    }

    private var selectedQuotation: Quotation? {
        guard let id = navigation.selectedQuotationId else { return nil }
        return modelContext.model(for: id) as? Quotation
    }

    var body: some View {
        @Bindable var navigation = navigation
        @Bindable var findInPage = findInPage
        @Bindable var exploreState = exploreState
        @Bindable var chatState = chatState

        splitView(
            navigation: navigation,
            findInPage: findInPage,
            exploreState: exploreState,
            chatState: chatState,
            selectedSourceId: $navigation.selectedSourceId,
            selectedQuotationId: $navigation.selectedQuotationId,
            findQuery: $findInPage.query
        )
        .onDeleteCommand {
            guard navigation.selectedQuotationId != nil else { return }
            showDeleteQuotationConfirmation = true
        }
        .modifier(ContentViewLifecycleModifier(
            modelContext: modelContext,
            showCSVImporter: $showCSVImporter,
            showBackups: $showBackups,
            showError: $showError,
            errorMessage: $errorMessage,
            selectedSourceId: $navigation.selectedSourceId,
            selectedQuotationId: $navigation.selectedQuotationId,
            newQuotationId: newQuotationId,
            deepLinkRouter: deepLinkRouter,
            sourcesCount: sources.count,
            quotationsCount: quotations.count,
            searchState: searchState,
            onImportCSV: importCSV,
            onBeginCSVImport: beginCSVImport,
            onImportFromAppleBooks: importFromAppleBooks,
            onAddQuotation: addQuotation,
            onOpenAdvancedSearch: { selectFilter(.searchResults) },
            onAppear: consumePendingDeepLinkIfNeeded,
            onPendingURLChange: consumePendingDeepLinkIfNeeded,
            onRetryDeepLink: retryUnresolvedDeepLinkIfNeeded,
            onDeepLinkReceived: consumePendingDeepLinkIfNeeded,
            onCleanupNewQuotation: cleanupNewQuotationIfEmpty
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
    private func splitView(
        navigation: LibraryNavigationState,
        findInPage: FindInPageState,
        exploreState: ExploreState,
        chatState: ChatState,
        selectedSourceId: Binding<PersistentIdentifier?>,
        selectedQuotationId: Binding<PersistentIdentifier?>,
        findQuery: Binding<String>
    ) -> some View {
        NavigationSplitView {
            LibraryFilterSidebarView(
                selectedFilter: navigation.selectedFilter,
                onSelectFilter: selectFilter
            )
            .equatable()
        } content: {
            LibraryContextListView(
                filter: navigation.selectedFilter,
                sources: sources,
                quotations: quotations,
                searchState: searchState,
                findQuery: findInPage.query,
                exploreState: exploreState,
                chatState: chatState,
                onExploreWordSelected: { openAdvancedSearch(for: $0) },
                onChatCitationSelected: { quotationId, sourceId in
                    navigation.selectQuotation(quotationId, sourceId: sourceId)
                },
                selectedSourceId: selectedSourceId,
                selectedQuotationId: selectedQuotationId,
                onManageAuthors: { showAuthorList = true },
                onAddSource: { newSourceSession = NewSourceSheetSession() },
                onSourceEdit: { sourceToEdit = $0 },
                onSourceDelete: { source in
                    sourceToDelete = source
                    showDeleteSourceConfirmation = true
                }
            )
        } detail: {
            detailPane
        }
        .navigationSplitViewStyle(.balanced)
        .searchable(
            text: findQuery,
            placement: .toolbar,
            prompt: "Find"
        )
        .onKeyPress(.escape) {
            if !findInPage.trimmedQuery.isEmpty {
                findInPage.query = ""
                return .handled
            }
            guard navigation.selectedQuotationId != nil else { return .ignored }
            navigation.clearQuotationSelection()
            return .handled
        }
    }
}

private extension ContentView {
    func emptyDetail(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text("Quotations")
                .font(.system(size: 56, weight: .regular, design: .serif).italic())
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func addQuotation() {
        guard let source = selectedSource else { return }
        cleanupNewQuotationIfEmpty()
        let quotation = Quotation(content: "", source: source)
        modelContext.insert(quotation)
        try? modelContext.save()
        newQuotationId = quotation.id
        navigation.selectedQuotationId = quotation.id
    }

    func cleanupNewQuotationIfEmpty() {
        defer { newQuotationId = nil }
        guard let id = newQuotationId,
              let quotation = modelContext.model(for: id) as? Quotation else { return }
        if quotation.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try? SoftDelete.quotation(quotation, in: modelContext)
            if navigation.selectedQuotationId == id {
                navigation.selectedQuotationId = nil
            }
        }
    }

    func openAdvancedSearch(for word: String) {
        searchState.query = word
        selectFilter(.searchResults)
        searchState.runSearchIfNeeded(modelContext: modelContext)
    }

    func selectFilter(_ filter: LibraryFilter) {
        guard filter != navigation.selectedFilter else { return }
        if filter != .searchResults {
            searchState.query = ""
        }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            navigation.selectFilter(filter)
        }
    }

    func handleSourceCreated(_ sourceId: PersistentIdentifier) {
        navigation.selectedSourceId = sourceId
        navigation.selectedQuotationId = nil
        if navigation.selectedFilter.showsQuotations {
            navigation.selectedFilter = .quotationsBySource
        }
    }

    static let deepLinkLog = Logger(subsystem: "com.russellmcwhae.Quotations", category: "DeepLink")

    func handleDeepLink(_ url: URL, retryCount: Int = 0) {
        guard let parameters = QuotationDeepLink.parseURLParameters(url) else {
            Self.deepLinkLog.debug("Ignoring deep link without quotation id: \(url.absoluteString, privacy: .public)")
            return
        }

        guard let quotation = QuotationDeepLinkResolver.quotation(
            encodedID: parameters.encodedQuotationID,
            in: modelContext
        ) else {
            guard retryCount < 10 else {
                Self.deepLinkLog.error(
                    "Failed to resolve quotation deep link after retries. url=\(url.absoluteString, privacy: .public) sharedStoreExists=\(AppGroupStore.sharedStoreExists, privacy: .public)"
                )
                return
            }
            unresolvedDeepLinkURL = url
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                handleDeepLink(url, retryCount: retryCount + 1)
            }
            return
        }

        guard let resolvedSourceID = QuotationDeepLinkResolver.sourceID(
            encodedID: parameters.encodedSourceID,
            for: quotation,
            in: modelContext
        ) else {
            unresolvedDeepLinkURL = url
            Self.deepLinkLog.error(
                "Resolved quotation but not source for deep link. url=\(url.absoluteString, privacy: .public)"
            )
            return
        }

        NSApp.activate(ignoringOtherApps: true)
        searchState.query = ""
        findInPage.query = ""
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            navigation.openQuotationFromDeepLink(
                quotation.persistentModelID,
                sourceId: resolvedSourceID
            )
        }
        isInspectorShown = true
        unresolvedDeepLinkURL = url

        Task { @MainActor in
            await Task.yield()
            verifyDeepLinkNavigation(for: url)
        }
    }

    func verifyDeepLinkNavigation(for url: URL) {
        guard unresolvedDeepLinkURL == url else { return }
        if let quotationId = navigation.selectedQuotationId,
           let sourceId = navigation.selectedSourceId,
           modelContext.model(for: quotationId) as? Quotation != nil,
           modelContext.model(for: sourceId) as? Source != nil {
            unresolvedDeepLinkURL = nil
            return
        }
        retryUnresolvedDeepLinkIfNeeded()
    }

    func consumePendingDeepLinkIfNeeded() {
        DeepLinkLaunchQueue.flush(into: deepLinkRouter)
        guard let url = deepLinkRouter.consumePendingURL() else { return }
        Task { @MainActor in
            await Task.yield()
            handleDeepLink(url)
        }
    }

    func retryUnresolvedDeepLinkIfNeeded() {
        guard let url = unresolvedDeepLinkURL else { return }
        handleDeepLink(url)
    }

    func beginCSVImport() {
        guard let source = selectedSource else {
            errorMessage = "Select a source before importing quotations from CSV."
            showError = true
            return
        }
        csvImportSourceId = source.persistentModelID
        showCSVImporter = true
    }

    func importCSV(from url: URL) {
        guard !isImporting else { return }
        guard let sourceId = csvImportSourceId,
              let source = modelContext.model(for: sourceId) as? Source else {
            errorMessage = "Select a source before importing quotations from CSV."
            showError = true
            return
        }
        isImporting = true
        defer {
            isImporting = false
            csvImportSourceId = nil
        }

        let accessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let result = try QuotationCSVImportService.importCSV(
                url: url,
                into: source,
                modelContext: modelContext,
                backupManager: backupManager
            )
            importSuccessMessage = result.summaryMessage
            showImportSuccess = true
            searchState.runSearchIfNeeded(modelContext: modelContext)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func importFromAppleBooks() {
        guard !isImporting else { return }
        isImporting = true
        defer { isImporting = false }

        do {
            let result = try AppleBooksImportService.importFromAppleBooks(
                modelContext: modelContext,
                backupManager: backupManager
            )
            importSuccessMessage = result.summaryMessage
            showImportSuccess = true
            searchState.runSearchIfNeeded(modelContext: modelContext)
        } catch let error as AppleBooksImportError where error == .userCancelled {
            // User dismissed the file picker; no alert needed.
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    var detailPane: some View {
        Group {
            if let source = selectedSource {
                SourceDetailView(
                    source: source,
                    findQuery: findInPage.query,
                    quotationIdsFilter: isOnSearchPage
                        ? searchState.matchSetsForQuery()?.quotationIds
                        : nil,
                    selectedQuotationId: $navigation.selectedQuotationId,
                    newQuotationId: newQuotationId
                )
            } else {
                emptyDetail(detailPlaceholderMessage)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            AppColors.mainBackground(colorScheme: colorScheme)
                .ignoresSafeArea(.container, edges: .top)
        )
        .toolbarBackground(.hidden, for: .windowToolbar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: addQuotation) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add quotation")
                .help("Add quotation (⌘⇧N)")
                .keyboardShortcut("n", modifiers: [.command, .shift])
                .disabled(selectedSource == nil)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(
                    action: { isInspectorShown.toggle() },
                    label: {
                        Label("Toggle Inspector", systemImage: "sidebar.trailing")
                    }
                )
                .accessibilityLabel(isInspectorShown ? "Hide inspector" : "Show inspector")
                .help(isInspectorShown ? "Hide Inspector" : "Show Inspector")
            }
        }
        .inspector(isPresented: $isInspectorShown) {
            QuotationInspectorView(
                quotation: selectedQuotation,
                selectedQuotationId: $navigation.selectedQuotationId,
                showDeleteConfirmation: $showDeleteQuotationConfirmation
            )
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .inspectorColumnWidth(min: 220, ideal: 300, max: 420)
        }
    }

    var detailPlaceholderMessage: String {
        if navigation.selectedFilter == .explore {
            return "Select a quotation from Explore"
        }
        if navigation.selectedFilter == .ask {
            return "Select a citation from Ask"
        }
        if navigation.selectedFilter.showsQuotations {
            return "Select a quotation"
        }
        return "Select a source"
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Author.self, Source.self, Quotation.self], inMemory: true)
        .environment(BackupManager(storeURL: URL(fileURLWithPath: "/tmp/default.store")))
        .environment(DeepLinkRouter())
}
