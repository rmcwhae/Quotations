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

    private var filteredSources: [Source] {
        guard let sets = searchState.matchSetsForQuery() else { return sources }
        return sources.filter { sets.sourceIds.contains($0.id) }
    }

    private var selectedSource: Source? {
        sources.first { $0.id == selectedSourceId }
            ?? filteredSources.first { $0.id == selectedSourceId }
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
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 280, max: 400)
            .foregroundStyle(inkColor)
            .background(
                SidebarMaterialView()
                    .ignoresSafeArea()
            )
        } detail: {
            // Detail: content
            Group {
                    if !searchState.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                       let matchSets = searchState.matchSetsForQuery(),
                       !filteredSources.isEmpty {
                        UnifiedSearchResultsView(
                            sources: filteredSources,
                            searchQuery: searchState.query,
                            quotationIdsFilter: matchSets.quotationIds
                        )
                    } else if let source = selectedSource {
                        SourceDetailView(
                            source: source,
                            searchQuery: searchState.query,
                            quotationIdsFilter: searchState.matchSetsForQuery()?.quotationIds
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
            .background((colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .navigationSplitViewStyle(.balanced)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        #if os(macOS)
        .modifier(TransparentWindowModifier())
        #endif
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Author.self, Source.self, Quotation.self], inMemory: true)
}
