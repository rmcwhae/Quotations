//
//  ContentView.swift
//  Quotations
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    /// Light mode: very light parchment. Dark mode: warm dark.
    private var parchmentColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.14, green: 0.12, blue: 0.10)
        default:
            return Color(red: 0.98, green: 0.96, blue: 0.91)
        }
    }

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
    @FocusState private var isSearchFocused: Bool
    @State private var showSourceForm = false
    @State private var showAuthorForm = false
    @State private var errorMessage: String?
    @State private var showError = false

    private var filteredSources: [Source] {
        guard let sets = searchState.matchSetsForQuery() else { return sources }
        return sources.filter { sets.sourceIds.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchBarView(
                query: $searchState.query,
                isSearching: searchState.isSearching,
                isSearchFocused: $isSearchFocused
            ) {
                AnyView(
                    HStack(spacing: 8) {
                        Button {
                            showAuthorForm = true
                        } label: {
                            Label("Add Author", systemImage: "person.badge.plus")
                        }
                        Button {
                            showSourceForm.toggle()
                        } label: {
                            Label(showSourceForm ? "Cancel" : "Add Source", systemImage: "plus.circle.fill")
                        }
                    }
                )
            }
            .onChange(of: searchState.query) { _, _ in
                searchState.runSearchIfNeeded(modelContext: modelContext)
            }

            if !searchState.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !searchState.isSearching,
               searchState.searchResults.isEmpty {
                Text("No results for \"\(searchState.query.trimmingCharacters(in: .whitespacesAndNewlines))\".")
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
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
                    }

                    ForEach(filteredSources) { source in
                        SourceRowView(
                            source: source,
                            searchQuery: searchState.query,
                            quotationIdsFilter: searchState.matchSetsForQuery()?.quotationIds
                        )
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(inkColor)
        .background(parchmentColor)
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
        .onKeyPress(.init("f"), phases: .down) { press in
            if press.modifiers.contains(EventModifiers.command) {
                isSearchFocused = true
                return .handled
            }
            return .ignored
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Author.self, Source.self, Quotation.self], inMemory: true)
}
