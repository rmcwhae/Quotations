//
//  ContentView.swift
//  Quotations
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    /// Light mode: warm dark ink. Dark mode: light cream.
    private var inkColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.94, green: 0.92, blue: 0.87)
        default:
            return Color(red: 0.15, green: 0.13, blue: 0.12)
        }
    }

    @Query(filter: #Predicate<Source> { $0.deletedAt == nil },
           sort: [SortDescriptor(\.createdAt, order: .reverse)])
    private var sources: [Source]

    @State private var searchState = SearchState()
    @State private var showSourceForm = false
    @State private var showAuthorForm = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var selectedSourceId: PersistentIdentifier?
    @State private var sourceToEdit: Source?
    @State private var sourceToDelete: Source?
    @State private var showDeleteSourceConfirmation = false
    @State private var isInspectorShown = true
    @State private var selectedQuotationId: PersistentIdentifier?
    @State private var showQuotationForm = false
    @State private var inspectorStartPage = ""
    @State private var inspectorEndPage = ""

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

    @ViewBuilder
    private var inspectorContent: some View {
        if let quotation = selectedQuotation {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quotation")
                    .font(.headline)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Start page")
                        .font(.subheadline)
                        .frame(width: 70, alignment: .leading)
                    TextField("—", text: $inspectorStartPage)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .onChange(of: inspectorStartPage) { _, _ in
                            applyInspectorPages(to: quotation)
                        }
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("End page")
                        .font(.subheadline)
                        .frame(width: 70, alignment: .leading)
                    TextField("—", text: $inspectorEndPage)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .onChange(of: inspectorEndPage) { _, _ in
                            applyInspectorPages(to: quotation)
                        }
                }
                if let updated = quotation.updatedAt {
                    Text("Last updated: \(updated, style: .date)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .onAppear {
                syncInspectorFromQuotation(quotation)
            }
            .onChange(of: selectedQuotationId) { _, _ in
                if let q = selectedQuotation {
                    syncInspectorFromQuotation(q)
                }
            }
        } else {
            Text("Select a quotation to view details.")
                .foregroundStyle(.secondary)
        }
    }

    private func syncInspectorFromQuotation(_ quotation: Quotation) {
        inspectorStartPage = quotation.startPage.map(String.init) ?? ""
        inspectorEndPage = quotation.endPage.map(String.init) ?? ""
    }

    private func applyInspectorPages(to quotation: Quotation) {
        quotation.startPage = Int(inspectorStartPage.trimmingCharacters(in: .whitespaces)).flatMap { $0 > 0 ? $0 : nil }
        quotation.endPage = Int(inspectorEndPage.trimmingCharacters(in: .whitespaces)).flatMap { $0 > 0 ? $0 : nil }
        quotation.updatedAt = Date()
        try? modelContext.save()
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar: source list
            VStack(spacing: 0) {
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
                    .padding()
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredSources) { source in
                            Button {
                                selectedSourceId = source.id
                            } label: {
                                SourceListRowView(
                                    source: source,
                                    searchQuery: searchState.query,
                                    isSelected: source.id == selectedSourceId
                                )
                            }
                            .buttonStyle(.plain)
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
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
            }
            .foregroundStyle(inkColor)
         
        } detail: {
            // Main content area
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
                        showQuotationForm: $showQuotationForm
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
            .foregroundStyle(inkColor)
            .background((colorScheme == .dark ? Color(white: 0.12) : Color.white).ignoresSafeArea())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                if selectedSource != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showQuotationForm = true
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
                inspectorContent
                    .padding()
                    .frame(minWidth: 150)
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
            selectedQuotationId = nil
            showQuotationForm = false
        }
        .navigationTitle("")
        .navigationSplitViewStyle(.balanced)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showAuthorForm) {
            AuthorFormView()
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
            .frame(minWidth: 320, minHeight: 280)
        }
        .confirmationDialog("Delete Source?", isPresented: $showDeleteSourceConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let source = sourceToDelete {
                    source.deletedAt = Date()
                    try? modelContext.save()
                }
                sourceToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                sourceToDelete = nil
            }
        } message: {
            if let source = sourceToDelete {
                Text("“\(source.title)” will be removed. Quotations from this source will remain but the source will no longer appear in the list.")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Author.self, Source.self, Quotation.self], inMemory: true)
}
