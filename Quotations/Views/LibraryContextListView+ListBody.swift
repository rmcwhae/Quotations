//
//  LibraryContextListView+ListBody.swift
//  Quotations
//

import SwiftData
import SwiftUI

extension LibraryContextListView {
    @ViewBuilder
    func listBody(resolved: ResolvedListContent) -> some View {
        // Native List selection gives arrow-key navigation, type-select, full-row hit
        // targets and the system selection highlight.
        Group {
            if filter.showsQuotations {
                List(selection: quotationSelection(in: resolved.quotations)) {
                    quotationRows(resolved.quotations)
                }
            } else {
                List(selection: sourceSelection) {
                    sourceRows(resolved.sources, counts: resolved.quotationCountsBySourceId)
                }
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
    func sourceRows(_ resolvedSources: [Source], counts: [PersistentIdentifier: Int]) -> some View {
        ForEach(resolvedSources) { source in
            SourceListRowView(
                source: source,
                searchQuery: listHighlightQuery,
                isSelected: source.id == selectedSourceId,
                quotationCount: filter == .quotationsBySource ? counts[source.id] ?? 0 : nil
            )
            .tag(source.id)
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
        }
    }

    /// Choosing a source clears any quotation selected in the previous source.
    var sourceSelection: Binding<PersistentIdentifier?> {
        Binding(
            get: { selectedSourceId },
            set: { newValue in
                guard newValue != selectedSourceId else { return }
                selectedSourceId = newValue
                selectedQuotationId = nil
            }
        )
    }

    /// Choosing a quotation also selects its source so the detail pane can show it.
    func quotationSelection(in quotations: [Quotation]) -> Binding<PersistentIdentifier?> {
        Binding(
            get: { selectedQuotationId },
            set: { newValue in
                selectedQuotationId = newValue
                if let newValue,
                   let sourceId = quotations.first(where: { $0.id == newValue })?.source?.id {
                    selectedSourceId = sourceId
                }
            }
        )
    }

    @ViewBuilder
    func emptyOverlay(sources: [Source], quotations: [Quotation]) -> some View {
        if filter == .searchResults {
            // Previous results stay visible while a new search runs; only show the
            // placeholder when there is nothing on screen yet.
            if searchState.isSearching, quotations.isEmpty, sources.isEmpty {
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
}
