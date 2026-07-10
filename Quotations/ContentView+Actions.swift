//
//  ContentView+Actions.swift
//  Quotations
//

import SwiftData
import SwiftUI

extension ContentView {
    func emptyDetail(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text("Quotations")
                .font(.system(size: 44, weight: .regular, design: .serif).italic())
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            Text(message)
                .font(.title2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .fixedSize(horizontal: true, vertical: false)
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

    /// Explore is a full-width visualization; hide the empty detail column until a quotation is selected.
    var shouldShowDetailColumn: Bool {
        if navigation.selectedFilter == .explore {
            return selectedSource != nil
        }
        return true
    }

    @ViewBuilder
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
        .navigationSplitViewColumnWidth(
            min: LayoutMetrics.detailColumnMinWidth,
            ideal: 400
        )
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
        if navigation.selectedFilter == .ask {
            return "Select a citation from Ask"
        }
        if navigation.selectedFilter.showsQuotations {
            return "Select a quotation"
        }
        return "Select a source"
    }
}
