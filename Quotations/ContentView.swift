//
//  ContentView.swift
//  Quotations
//

import SwiftUI
import SwiftData
import Combine

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query(filter: #Predicate<Source> { $0.deletedAt == nil },
           sort: [SortDescriptor(\.createdAt, order: .reverse)])
    private var sources: [Source]

    @State private var searchState = SearchState()
    @State private var showSourceForm = false
    @State private var showAuthorList = false
    @State private var showBackups = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var selectedSourceId: PersistentIdentifier?
    @State private var sourceToEdit: Source?
    @State private var sourceToDelete: Source?
    @State private var showDeleteSourceConfirmation = false
    @State private var isInspectorShown = true
    @State private var selectedQuotationId: PersistentIdentifier?
    @State private var newQuotationId: PersistentIdentifier?

    private var isSearchActive: Bool {
        !searchState.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var filteredSources: [Source] {
        guard let sets = searchState.matchSetsForQuery() else { return sources }
        return sources.filter { sets.sourceIds.contains($0.id) }
    }

    private var selectedSource: Source? {
        sources.first { $0.id == selectedSourceId }
            ?? filteredSources.first { $0.id == selectedSourceId }
    }

    private var selectedQuotation: Quotation? {
        guard let id = selectedQuotationId else { return nil }
        return modelContext.model(for: id) as? Quotation
    }

    /// Centered placeholder text; the detail container supplies the parchment background.
    private func emptyDetail(_ message: String) -> some View {
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

    /// Adds a new empty quotation to the selected source and selects it so it
    /// opens inline in edit mode, looking exactly like an existing quotation.
    private func addQuotation() {
        guard let source = selectedSource else { return }
        cleanupNewQuotationIfEmpty()
        let quotation = Quotation(content: "", source: source)
        modelContext.insert(quotation)
        try? modelContext.save()
        newQuotationId = quotation.id
        selectedQuotationId = quotation.id
    }

    /// Removes a freshly added quotation that was left empty (abandoned).
    private func cleanupNewQuotationIfEmpty() {
        defer { newQuotationId = nil }
        guard let id = newQuotationId,
              let quotation = modelContext.model(for: id) as? Quotation else { return }
        if quotation.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try? SoftDelete.quotation(quotation, in: modelContext)
            if selectedQuotationId == id {
                selectedQuotationId = nil
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            sourceSidebar
        } detail: {
            detailPane
        }
        .onKeyPress(.escape) {
            guard selectedQuotationId != nil else { return .ignored }
            selectedQuotationId = nil
            return .handled
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
        .onChange(of: selectedSourceId) { _, _ in
            cleanupNewQuotationIfEmpty()
            selectedQuotationId = nil
        }
        .onChange(of: selectedQuotationId) { _, newValue in
            if let newId = newQuotationId, newValue != newId {
                cleanupNewQuotationIfEmpty()
            }
        }
        .navigationTitle("")
        .modifier(ContentViewSheetsModifier(
            showError: $showError,
            errorMessage: errorMessage,
            showAuthorList: $showAuthorList,
            showBackups: $showBackups,
            sourceToEdit: $sourceToEdit,
            showDeleteSourceConfirmation: $showDeleteSourceConfirmation,
            sourceToDelete: $sourceToDelete,
            selectedSourceId: $selectedSourceId,
            selectedQuotationId: $selectedQuotationId,
            modelContext: modelContext,
            onEditError: { message in
                errorMessage = message
                showError = true
            }
        ))
    }
}

private extension ContentView {
    var sourceSidebar: some View {
        List {
            if showSourceForm {
                SourceFormView(
                    onSuccess: {
                        showSourceForm = false
                    },
                    onCancel: {
                        showSourceForm = false
                    },
                    onError: { message in
                        errorMessage = message
                        showError = true
                    }
                )
                .listRowSeparator(.hidden)
            }

            ForEach(filteredSources) { source in
                SourceListRowView(
                    source: source,
                    searchQuery: searchState.query,
                    isSelected: source.id == selectedSourceId
                )
                .tag(source.id)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(source.id == selectedSourceId ? AppColors.selectionBackground : Color.clear)
                        .padding(.horizontal, 4)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSourceId = source.id
                }
                .contextMenu {
                    Button("Edit…") {
                        sourceToEdit = source
                    }
                    Button("Delete", role: .destructive) {
                        sourceToDelete = source
                        showDeleteSourceConfirmation = true
                    }
                }
            }
        }
        .overlay {
            if sources.isEmpty && !showSourceForm
                && searchState.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("No sources yet.")
                    .foregroundStyle(.secondary)
            }
        }
        .overlay(alignment: .top) {
            if !searchState.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !searchState.isSearching,
               searchState.searchResults.isEmpty {
                Text("No results for \"\(searchState.query.trimmingCharacters(in: .whitespacesAndNewlines))\".")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 300, max: 500)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSourceForm = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create source")
                .help("Add source")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showBackups = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .accessibilityLabel("Manage backups")
                .help("Manage backups")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAuthorList = true
                } label: {
                    Image(systemName: "person.2")
                }
                .accessibilityLabel("Manage authors")
                .help("Manage authors")
            }
        }
    }

    var detailPane: some View {
        Group {
            if isSearchActive {
                UnifiedSearchResultsView(
                    sources: filteredSources,
                    searchQuery: searchState.query,
                    quotationsBySourceId: searchState.quotationsBySourceId,
                    selectedQuotationId: $selectedQuotationId,
                    newQuotationId: newQuotationId,
                    statusMessage: filteredSources.isEmpty
                        ? (searchState.isSearching ? "Searching…" : "No results")
                        : nil
                )
            } else if let source = selectedSource {
                SourceDetailView(
                    source: source,
                    searchQuery: searchState.query,
                    quotationIdsFilter: searchState.matchSetsForQuery()?.quotationIds,
                    selectedQuotationId: $selectedQuotationId,
                    newQuotationId: newQuotationId
                )
            } else {
                emptyDetail("Select a source")
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
                Button {
                    addQuotation()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add quotation")
                .help("Add quotation")
                .disabled(selectedSource == nil || isSearchActive)
                .opacity(selectedSource == nil || isSearchActive ? 0 : 1)
                .accessibilityHidden(selectedSource == nil || isSearchActive)
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
                selectedQuotationId: $selectedQuotationId
            )
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .inspectorColumnWidth(min: 220, ideal: 300, max: 420)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Author.self, Source.self, Quotation.self], inMemory: true)
}
