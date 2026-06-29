//
//  ContentView.swift
//  Quotations
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<Source> { $0.deletedAt == nil },
           sort: [SortDescriptor(\.createdAt, order: .reverse)])
    private var sources: [Source]

    @State private var searchState = SearchState()
    @State private var showSourceForm = false
    @State private var showAuthorList = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var selectedSourceId: PersistentIdentifier?
    @State private var sourceToEdit: Source?
    @State private var sourceToDelete: Source?
    @State private var showDeleteSourceConfirmation = false
    @State private var isInspectorShown = true
    @State private var selectedQuotationId: PersistentIdentifier?
    @State private var newQuotationId: PersistentIdentifier?

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
            modelContext.delete(quotation)
            try? modelContext.save()
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSourceId) {
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
                        searchQuery: searchState.query
                    )
                    .tag(source.id)
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
            .deselectQuotationOnBackgroundTap($selectedQuotationId)
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
                        showAuthorList = true
                    } label: {
                        Image(systemName: "person.2")
                    }
                    .accessibilityLabel("Manage authors")
                    .help("Manage authors")
                }
            }
        } detail: {
            Group {
                if !searchState.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   let matchSets = searchState.matchSetsForQuery(),
                   !filteredSources.isEmpty {
                    UnifiedSearchResultsView(
                        sources: filteredSources,
                        searchQuery: searchState.query,
                        quotationIdsFilter: matchSets.quotationIds,
                        selectedQuotationId: $selectedQuotationId
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
                    VStack {
                        Spacer()
                        Text("Select a source")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                if selectedSource != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            addQuotation()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add quotation")
                        .help("Add quotation")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isInspectorShown.toggle() }) {
                        Label("Toggle Inspector", systemImage: "sidebar.trailing")
                    }
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
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showAuthorList) {
            AuthorListView(onDismiss: { showAuthorList = false })
        }
        .sheet(item: $sourceToEdit) { source in
            SourceFormView(
                existingSource: source,
                onSuccess: {
                    sourceToEdit = nil
                },
                onCancel: {
                    sourceToEdit = nil
                },
                onError: { message in
                    errorMessage = message
                    showError = true
                }
            )
            .padding()
            .frame(minWidth: 320, minHeight: 380)
        }
        .confirmationDialog("Delete Source?", isPresented: $showDeleteSourceConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let source = sourceToDelete {
                    let sourceId = source.persistentModelID
                    source.deletedAt = Date()
                    let descriptor = FetchDescriptor<Quotation>(
                        predicate: #Predicate { q in q.source?.persistentModelID == sourceId && q.deletedAt == nil }
                    )
                    if let quotations = try? modelContext.fetch(descriptor) {
                        for q in quotations { q.deletedAt = Date() }
                    }
                    try? modelContext.save()
                }
                sourceToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                sourceToDelete = nil
            }
        } message: {
            if let source = sourceToDelete {
                Text("\"\(source.title)\" and all its quotations will be removed.")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Author.self, Source.self, Quotation.self], inMemory: true)
}

