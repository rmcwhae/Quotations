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
            return Color(red: 0.995, green: 0.99, blue: 0.97)
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
        HStack(spacing: 0) {
            // Left sidebar: full height from top of window, source list
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 28)
                    .allowsHitTesting(false)
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
            .frame(width: 280)
            .foregroundStyle(inkColor)
            .background(
                SidebarMaterialView()
                    .ignoresSafeArea()
            )
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(SeparatorShapeStyle())
                    .frame(width: 1)
                    .ignoresSafeArea(edges: .vertical)
            }

            // Right side: top bar + detail pane
            VStack(spacing: 0) {
                SearchBarView(
                    query: $searchState.query,
                    isSearching: searchState.isSearching,
                    isSearchFocused: $isSearchFocused,
                    isFocused: isSearchFocused
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
                .foregroundStyle(inkColor)
                .padding(.top, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    SidebarMaterialView()
                        .ignoresSafeArea(edges: .top)
                )

                Group {
                    if let source = selectedSource {
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
                .background(parchmentColor.ignoresSafeArea())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
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
        .defaultFocus($isSearchFocused, false)
        .onAppear {
            DispatchQueue.main.async {
                isSearchFocused = false
            }
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
