//
//  SearchState.swift
//  Quotations
//

import Foundation
import SwiftData
import Observation

struct SearchResultItem: Hashable {
    let quotationId: PersistentIdentifier
    let sourceId: PersistentIdentifier
}

struct MatchSets {
    let authorIds: Set<PersistentIdentifier>
    let sourceIds: Set<PersistentIdentifier>
    let quotationIds: Set<PersistentIdentifier>
}

@Observable
final class SearchState {
    var query: String = ""
    var searchResults: [SearchResultItem] = []
    var isSearching: Bool = false
    var matchSets: MatchSets?
    /// Quotation IDs grouped by source, for search results rendering without per-section `@Query`.
    var quotationsBySourceId: [PersistentIdentifier: [PersistentIdentifier]] = [:]

    private let debounceInterval: Duration = .milliseconds(200)
    private var searchTask: Task<Void, Never>?

    deinit {
        searchTask?.cancel()
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func runSearchIfNeeded(modelContext: ModelContext) {
        let trimmed = trimmedQuery
        if trimmed.isEmpty {
            searchTask?.cancel()
            searchTask = nil
            clearResults()
            return
        }

        searchTask?.cancel()
        isSearching = true
        searchResults = []
        matchSets = nil
        quotationsBySourceId = [:]

        searchTask = Task { @MainActor in
            try? await Task.sleep(for: debounceInterval)
            guard !Task.isCancelled else { return }

            let descriptor = FetchDescriptor<Quotation>(
                predicate: #Predicate<Quotation> { quotation in quotation.deletedAt == nil },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )

            do {
                let allQuotations = try modelContext.fetch(descriptor)
                guard !Task.isCancelled else { return }

                let match = SearchMatcher.match(quotations: allQuotations, query: trimmed)
                searchResults = match.results
                matchSets = match.matchSets
                quotationsBySourceId = match.quotationsBySourceId
                isSearching = false
            } catch {
                guard !Task.isCancelled else { return }
                clearResults()
            }
        }
    }

    func matchSetsForQuery() -> MatchSets? {
        guard !trimmedQuery.isEmpty else { return nil }
        return matchSets
    }

    private func clearResults() {
        searchResults = []
        isSearching = false
        matchSets = nil
        quotationsBySourceId = [:]
    }
}
