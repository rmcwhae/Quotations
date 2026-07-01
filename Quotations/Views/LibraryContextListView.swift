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
    @Binding var selectedSourceId: PersistentIdentifier?
    @Binding var selectedQuotationId: PersistentIdentifier?
    var onManageAuthors: () -> Void
    var onAddSource: () -> Void
    var onSourceEdit: (Source) -> Void
    var onSourceDelete: (Source) -> Void

    @AppStorage("sourceListSortOption") private var sourceSortOption: SourceSortOption = .dateRead

    private var trimmedSearchQuery: String {
        searchState.query.trimmingCharacters(in: .whitespacesAndNewlines)
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
        let stats = LibraryFilterResolver.stats(for: filter, resolvedSources: sources, resolvedQuotations: quotations)
        return ResolvedListContent(sources: sources, quotations: quotations, stats: stats)
    }

    var body: some View {
        let resolved = listContent

        List {
            if filter.showsQuotations {
                quotationRows(resolved.quotations)
            } else {
                sourceRows(resolved.sources)
            }
        }
        .navigationTitle(filter.title)
        .scrollUnderTitleFade()
        .overlay { emptyOverlay(sources: resolved.sources, quotations: resolved.quotations) }
        .safeAreaInset(edge: .bottom) {
            LibraryStatsFooterView(stats: resolved.stats)
        }
        .navigationSplitViewColumnWidth(min: 220, ideal: 300, max: 420)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: onManageAuthors) {
                    Image(systemName: "person.2")
                }
                .accessibilityLabel("Manage authors")
                .help("Manage authors")
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
                searchQuery: searchState.query,
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
                searchQuery: searchState.query,
                isSelected: quotation.id == selectedQuotationId
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
