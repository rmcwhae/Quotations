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
    /// Quotation IDs found by semantic search but not by keyword matching.
    var semanticQuotationIds: Set<PersistentIdentifier> = []
    /// Optional Apple Intelligence summary for the latest semantic search.
    var semanticSummary: String?

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
        semanticQuotationIds = []
        semanticSummary = nil

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

                let keywordMatch = SearchMatcher.match(quotations: allQuotations, query: trimmed)
                applyMatch(keywordMatch)

                if SemanticSearchMerger.shouldRunSemanticSearch(query: trimmed, keywordResult: keywordMatch) {
                    let semanticResponse = await SemanticSearchService.search(
                        query: trimmed,
                        keywordResult: keywordMatch,
                        quotations: allQuotations
                    )
                    guard !Task.isCancelled else { return }

                    let mergedMatch = SemanticSearchMerger.merge(
                        keywordResult: keywordMatch,
                        encodedQuotationIDs: semanticResponse.encodedQuotationIDs,
                        quotations: allQuotations
                    )
                    applyMatch(mergedMatch)
                    semanticSummary = semanticResponse.summary
                }

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

    func isSemanticMatch(_ quotationId: PersistentIdentifier) -> Bool {
        semanticQuotationIds.contains(quotationId)
    }

    private func applyMatch(_ match: SearchMatcher.MatchResult) {
        searchResults = match.results
        matchSets = match.matchSets
        quotationsBySourceId = match.quotationsBySourceId
        semanticQuotationIds = match.semanticQuotationIds
    }

    private func clearResults() {
        searchResults = []
        isSearching = false
        matchSets = nil
        quotationsBySourceId = [:]
        semanticQuotationIds = []
        semanticSummary = nil
    }
}
