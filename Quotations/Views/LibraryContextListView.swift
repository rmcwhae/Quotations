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

    @AppStorage("sourceListSortOption") private var sourceSortOption: SourceSortOption = .dateRead
    @FocusState private var isSearchFieldFocused: Bool

    private var isExplorePage: Bool {
        filter == .explore
    }

    private var isAskPage: Bool {
        filter == .ask
    }

    private var isSearchPage: Bool {
        filter == .searchResults
    }

    private var trimmedSearchQuery: String {
        searchState.query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var listHighlightQuery: String {
        if filter == .searchResults {
            let find = findQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            return find.isEmpty ? searchState.query : findQuery
        }
        return findQuery
    }

    private struct ResolvedListContent {
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
            sources = LibraryFilterResolver.sources(for: filter, from: self.sources, sortOption: sourceSortOption)
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
        .navigationTitle(filter.title)
        .scrollUnderTitleFade()
        .onAppear {
            if isSearchPage {
                isSearchFieldFocused = true
            }
            if isExplorePage {
                exploreState.refresh(quotations: quotations)
            }
        }
        .onChange(of: filter) { _, newFilter in
            if newFilter == .searchResults {
                isSearchFieldFocused = true
            }
            if newFilter == .explore {
                exploreState.refresh(quotations: quotations)
            }
        }
    }

    @ViewBuilder
    private func listBody(resolved: ResolvedListContent) -> some View {
        List {
            if filter.showsQuotations {
                quotationRows(resolved.quotations)
            } else {
                sourceRows(resolved.sources)
            }
        }
        .overlay { emptyOverlay(sources: resolved.sources, quotations: resolved.quotations) }
        .safeAreaInset(edge: .bottom) {
            LibraryStatsFooterView(stats: resolved.stats)
        }
        .navigationSplitViewColumnWidth(min: 220, ideal: 300)
        .toolbar {
            if !isSearchPage && !isExplorePage && !isAskPage {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: onManageAuthors) {
                        Image(systemName: "person.2")
                    }
                    .accessibilityLabel("Manage authors")
                    .help("Manage authors")
                }
            }
            if !filter.showsQuotations {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Sort by", selection: $sourceSortOption) {
                            ForEach(SourceSortOption.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .pickerStyle(.inline)
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .accessibilityLabel("Sort sources")
                    .help("Sort by \(sourceSortOption.title)")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: onAddSource) {
                        Image(systemName: "book.badge.plus")
                    }
                    .accessibilityLabel("Create source")
                    .help("Add source")
                }
            }
        }
    }

    @ViewBuilder
    private func sourceRows(_ resolvedSources: [Source]) -> some View {
        ForEach(resolvedSources) { source in
            SourceListRowView(
                source: source,
                searchQuery: listHighlightQuery,
                isSelected: source.id == selectedSourceId,
                showsQuotationCount: filter == .quotationsBySource
            )
            .tag(source.id)
            .listRowBackground(selectionBackground(isSelected: source.id == selectedSourceId))
            .contentShape(Rectangle())
            .onTapGesture {
                selectedSourceId = source.id
                selectedQuotationId = nil
            }
            .contextMenu {
                Button("Edit…") { onSourceEdit(source) }
                Button("Delete", role: .destructive) { onSourceDelete(source) }
            }
        }
    }

    @ViewBuilder
    private func quotationRows(_ resolvedQuotations: [Quotation]) -> some View {
        ForEach(resolvedQuotations) { quotation in
            QuotationListRowView(
                quotation: quotation,
                searchQuery: listHighlightQuery,
                isSelected: quotation.id == selectedQuotationId,
                isSemanticMatch: searchState.isSemanticMatch(quotation.id)
            )
            .tag(quotation.id)
            .listRowBackground(selectionBackground(isSelected: quotation.id == selectedQuotationId))
            .contentShape(Rectangle())
            .onTapGesture {
                selectedQuotationId = quotation.id
                if let sourceId = quotation.source?.id {
                    selectedSourceId = sourceId
                }
            }
        }
    }

    @ViewBuilder
    private func emptyOverlay(sources: [Source], quotations: [Quotation]) -> some View {
        if filter == .searchResults {
            if searchState.isSearching {
                Text("Searching…")
                    .foregroundStyle(.secondary)
            } else if let summary = searchState.semanticSummary, !summary.isEmpty {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else if !trimmedSearchQuery.isEmpty,
                      quotations.isEmpty,
                      sources.isEmpty {
                Text("No results for \"\(trimmedSearchQuery)\".")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        } else if filter.showsQuotations {
            if quotations.isEmpty {
                Text("No quotations yet.")
                    .foregroundStyle(.secondary)
            }
        } else if sources.isEmpty {
            Text(emptySourcesMessage)
                .foregroundStyle(.secondary)
        }
    }

    private var emptySourcesMessage: String {
        switch filter {
        case .format: "No sources in this format."
        default: "No sources yet."
        }
    }

    private func selectionBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(isSelected ? AppColors.selectionBackground : Color.clear)
            .padding(.horizontal, 4)
    }
}

/// Context-aware counts for whatever filter/search is currently active in column 2.
private struct LibraryStatsFooterView: View {
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
