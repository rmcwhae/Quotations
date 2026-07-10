//
//  LibraryContextListView.swift
//  Quotations
//
//  Column 2: context-driven source or quotation list for the active filter.
//

import SwiftData
import SwiftUI

struct LibraryContextListView: View {
    let filter: LibraryFilter
    let sources: [Source]
    let quotations: [Quotation]
    let searchState: SearchState
    let findQuery: String
    @Bindable var exploreState: ExploreState
    @Bindable var chatState: ChatState
    var onExploreWordSelected: (String) -> Void
    var onChatCitationSelected: (PersistentIdentifier, PersistentIdentifier?) -> Void
    @Binding var selectedSourceId: PersistentIdentifier?
    @Binding var selectedQuotationId: PersistentIdentifier?
    var onManageAuthors: () -> Void
    var onAddSource: () -> Void
    var onSourceEdit: (Source) -> Void
    var onSourceDelete: (Source) -> Void

    @AppStorage("sourceListSortOption") var sourceListSortOption: SourceSortOption = .dateRead
    @Environment(StopWordsStore.self) private var stopWordsStore
    @FocusState private var isSearchFieldFocused: Bool

    var isExplorePage: Bool {
        filter == .explore
    }

    var isAskPage: Bool {
        filter == .ask
    }

    var isSearchPage: Bool {
        filter == .searchResults
    }

    var trimmedSearchQuery: String {
        searchState.query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var listHighlightQuery: String {
        if filter == .searchResults {
            let find = findQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            return find.isEmpty ? searchState.query : findQuery
        }
        return findQuery
    }

    struct ResolvedListContent {
        let sources: [Source]
        let quotations: [Quotation]
        let stats: LibraryStats
    }

    private var listContent: ResolvedListContent {
        let matchSets = searchState.matchSetsForQuery()
        let sources: [Source]
        if filter == .searchResults {
            sources = LibraryFilterResolver.searchResultSources(from: self.sources, matchSets: matchSets)
        } else {
            sources = LibraryFilterResolver.sources(for: filter, from: self.sources, sortOption: sourceListSortOption)
        }
        let quotations = LibraryFilterResolver.quotations(
            for: filter,
            from: self.quotations,
            matchSets: matchSets,
            searchResultIds: LibraryFilterResolver.searchResultQuotationIds(from: searchState)
        )
        let stats: LibraryStats
        if filter == .explore || filter == .ask {
            let active = self.quotations.filter { $0.deletedAt == nil }
            let sourceIds = Set(active.compactMap { $0.source?.id })
            let authorIds = Set(active.compactMap { $0.source?.author?.id })
            stats = LibraryStats(
                quotationCount: active.count,
                sourceCount: sourceIds.count,
                authorCount: authorIds.count
            )
        } else {
            stats = LibraryFilterResolver.stats(for: filter, resolvedSources: sources, resolvedQuotations: quotations)
        }
        return ResolvedListContent(sources: sources, quotations: quotations, stats: stats)
    }

    var body: some View {
        let resolved = listContent

        Group {
            if isExplorePage {
                VStack(spacing: 0) {
                    LibraryExploreView(
                        quotations: quotations,
                        exploreState: exploreState,
                        selectedQuotationId: $selectedQuotationId,
                        selectedSourceIdBinding: $selectedSourceId,
                        onWordSelected: onExploreWordSelected
                    )
                    LibraryStatsFooterView(stats: resolved.stats)
                }
            } else if isAskPage {
                VStack(spacing: 0) {
                    LibraryChatView(
                        quotations: quotations,
                        chatState: chatState,
                        onSelectCitation: onChatCitationSelected
                    )
                    LibraryStatsFooterView(stats: resolved.stats)
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            chatState.clear()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel("Clear conversation")
                        .help("Clear conversation")
                        .disabled(chatState.isGenerating || !chatState.hasContent)
                    }
                }
            } else if isSearchPage {
                VStack(spacing: 0) {
                    SearchPageHeaderView(
                        query: Binding(
                            get: { searchState.query },
                            set: { searchState.query = $0 }
                        ),
                        isFocused: $isSearchFieldFocused
                    )

                    listBody(resolved: resolved)
                }
            } else {
                listBody(resolved: resolved)
            }
        }
        .padding(.leading, LayoutMetrics.contentColumnLeadingPadding)
        .navigationTitle(filter.title)
        .scrollUnderTitleFade()
        .onAppear {
            if isSearchPage {
                isSearchFieldFocused = true
            }
            if isExplorePage {
                exploreState.refresh(quotations: quotations, stopwords: stopWordsStore.wordSet)
            }
        }
        .onChange(of: filter) { _, newFilter in
            if newFilter == .searchResults {
                isSearchFieldFocused = true
            }
            if newFilter == .explore {
                exploreState.refresh(quotations: quotations, stopwords: stopWordsStore.wordSet)
            }
        }
    }
}

/// Context-aware counts for whatever filter/search is currently active in column 2.
struct LibraryStatsFooterView: View {
    let stats: LibraryStats

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            Text(summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.bar)
    }

    private var summary: String {
        [
            pluralize(stats.quotationCount, "quotation"),
            pluralize(stats.sourceCount, "source"),
            pluralize(stats.authorCount, "author")
        ].joined(separator: " · ")
    }

    private func pluralize(_ count: Int, _ noun: String) -> String {
        count == 1 ? "1 \(noun)" : "\(count) \(noun)s"
    }
}
