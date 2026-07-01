//
//  ContentView.swift
//  Quotations
//

import SwiftUI
import SwiftData
import Combine
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(BackupManager.self) private var backupManager

    @Query(filter: #Predicate<Source> { $0.deletedAt == nil })
    private var sources: [Source]

    @Query(filter: #Predicate<Quotation> { $0.deletedAt == nil })
    private var quotations: [Quotation]

    @State private var navigation = LibraryNavigationState()
    @State private var searchState = SearchState()
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

    private var isSearchActive: Bool {
        !searchState.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var effectiveFilter: LibraryFilter {
        navigation.effectiveFilter(isSearchActive: isSearchActive)
    }

    private var selectedSource: Source? {
        guard let id = navigation.selectedSourceId else { return nil }
        return sources.first { $0.id == id }
    }

    private var selectedQuotation: Quotation? {
        guard let id = navigation.selectedQuotationId else { return nil }
        return modelContext.model(for: id) as? Quotation
    }

    var body: some View {
        NavigationSplitView {
            LibraryFilterSidebarView(
                selectedFilter: navigation.selectedFilter,
                isSearchActive: isSearchActive,
                onSelectFilter: selectFilter
            )
            .equatable()
        } content: {
            LibraryContextListView(
                filter: effectiveFilter,
                sources: sources,
                quotations: quotations,
                searchState: searchState,
                selectedSourceId: $navigation.selectedSourceId,
                selectedQuotationId: $navigation.selectedQuotationId,
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
        .onKeyPress(.escape) {
            guard navigation.selectedQuotationId != nil else { return .ignored }
            navigation.clearQuotationSelection()
            return .handled
        }
        .onDeleteCommand {
            guard navigation.selectedQuotationId != nil else { return }
            showDeleteQuotationConfirmation = true
        }
        .searchable(
            text: Binding(
                get: { searchState.query },
                set: { searchState.query = $0 }
            ),
            placement: .toolbar
        )
        .onChange(of: searchState.query) { _, _ in
            searchState.runSearchIfNeeded(modelContext: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: .quotationsDataDidChange)) { _ in
            searchState.runSearchIfNeeded(modelContext: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showBackupsPanel)) { _ in
            showBackups = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .importFromAppleBooks)) { _ in
            importFromAppleBooks()
        }
        .onReceive(NotificationCenter.default.publisher(for: .importQuotationsFromCSV)) { _ in
            beginCSVImport()
        }
        .onReceive(NotificationCenter.default.publisher(for: .addQuotation)) { _ in
            addQuotation()
        }
        .fileImporter(
            isPresented: $showCSVImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText, .text],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importCSV(from: url)
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        .onChange(of: navigation.selectedSourceId) { _, _ in
            cleanupNewQuotationIfEmpty()
        }
        .onChange(of: navigation.selectedQuotationId) { _, newValue in
            if let newId = newQuotationId, newValue != newId {
                cleanupNewQuotationIfEmpty()
            }
        }
        .navigationTitle("")
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

    func selectFilter(_ filter: LibraryFilter) {
        guard filter != navigation.selectedFilter || isSearchActive else { return }
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
                    searchQuery: searchState.query,
                    quotationIdsFilter: isSearchActive
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
        if effectiveFilter.showsQuotations {
            return "Select a quotation"
        }
        return "Select a source"
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Author.self, Source.self, Quotation.self], inMemory: true)
        .environment(BackupManager(storeURL: URL(fileURLWithPath: "/tmp/default.store")))
}
