//
//  LibraryContextListView+ListBody.swift
//  Quotations
//

import SwiftData
import SwiftUI

extension LibraryContextListView {
    @ViewBuilder
    func listBody(resolved: ResolvedListContent) -> some View {
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
                        Picker("Sort by", selection: $sourceListSortOption) {
                            ForEach(SourceSortOption.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .pickerStyle(.inline)
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .accessibilityLabel("Sort sources")
                    .help("Sort by \(sourceListSortOption.title)")
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
    func sourceRows(_ resolvedSources: [Source]) -> some View {
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
    func quotationRows(_ resolvedQuotations: [Quotation]) -> some View {
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
    func emptyOverlay(sources: [Source], quotations: [Quotation]) -> some View {
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

    var emptySourcesMessage: String {
        switch filter {
        case .format: "No sources in this format."
        default: "No sources yet."
        }
    }

    func selectionBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(isSelected ? AppColors.selectionBackground : Color.clear)
            .padding(.horizontal, 4)
    }
}
