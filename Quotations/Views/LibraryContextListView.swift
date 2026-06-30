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
    @Binding var showSourceForm: Bool
    var onManageAuthors: () -> Void
    var onSourceEdit: (Source) -> Void
    var onSourceDelete: (Source) -> Void
    var onError: (String) -> Void

    private var trimmedSearchQuery: String {
        searchState.query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var listContent: (sources: [Source], quotations: [Quotation]) {
        let matchSets = searchState.matchSetsForQuery()
        let sources: [Source]
        if filter == .searchResults {
            sources = LibraryFilterResolver.searchResultSources(from: self.sources, matchSets: matchSets)
        } else {
            sources = LibraryFilterResolver.sources(for: filter, from: self.sources)
        }
        let quotations = LibraryFilterResolver.quotations(
            for: filter,
            from: self.quotations,
            matchSets: matchSets,
            searchResultIds: LibraryFilterResolver.searchResultQuotationIds(from: searchState)
        )
        return (sources, quotations)
    }

    var body: some View {
        let resolved = listContent

        List {
            if showSourceForm {
                SourceFormView(
                    onSuccess: { showSourceForm = false },
                    onCancel: { showSourceForm = false },
                    onError: onError
                )
                .listRowSeparator(.hidden)
            }

            if filter.showsQuotations {
                quotationRows(resolved.quotations)
            } else {
                sourceRows(resolved.sources)
            }
        }
        .navigationTitle(filter.title)
        .overlay { emptyOverlay(sources: resolved.sources, quotations: resolved.quotations) }
        .navigationSplitViewColumnWidth(min: 220, ideal: 300, max: 420)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: onManageAuthors) {
                    Image(systemName: "person.2")
                }
                .accessibilityLabel("Manage authors")
                .help("Manage authors")
            }
            ToolbarItem(placement: .primaryAction) {
                Button { showSourceForm = true } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create source")
                .help("Add source")
            }
        }
    }

    @ViewBuilder
    private func sourceRows(_ resolvedSources: [Source]) -> some View {
        ForEach(resolvedSources) { source in
            SourceListRowView(
                source: source,
                searchQuery: searchState.query,
                isSelected: source.id == selectedSourceId
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
            if quotations.isEmpty && !showSourceForm {
                Text("No quotations yet.")
                    .foregroundStyle(.secondary)
            }
        } else if sources.isEmpty && !showSourceForm {
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
