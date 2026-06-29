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

    private let debounceInterval: TimeInterval = 0.2
    private var searchTask: Task<Void, Never>?

    deinit {
        searchTask?.cancel()
    }

    func runSearchIfNeeded(modelContext: ModelContext) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty {
            searchResults = []
            isSearching = false
            matchSets = nil
            return
        }

        searchTask?.cancel()
        isSearching = true

        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(debounceInterval * 1_000_000_000))
            guard !Task.isCancelled else { return }

            let descriptor = FetchDescriptor<Quotation>(
                predicate: #Predicate<Quotation> { q in q.deletedAt == nil },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            guard let allQuotations = try? modelContext.fetch(descriptor) else {
                isSearching = false
                return
            }

            let lower = q.lowercased()
            var results: [SearchResultItem] = []
            var authorIds = Set<PersistentIdentifier>()
            var sourceIds = Set<PersistentIdentifier>()
            var quotationIds = Set<PersistentIdentifier>()
            for quotation in allQuotations {
                guard let source = quotation.source, source.deletedAt == nil,
                      let author = source.author, author.deletedAt == nil else { continue }
                let contentMatch = quotation.content.lowercased().contains(lower)
                let titleMatch = source.title.lowercased().contains(lower)
                let authorMatch = author.name.lowercased().contains(lower)
                if contentMatch || titleMatch || authorMatch {
                    results.append(SearchResultItem(
                        quotationId: quotation.persistentModelID,
                        sourceId: source.persistentModelID
                    ))
                    authorIds.insert(author.persistentModelID)
                    sourceIds.insert(source.persistentModelID)
                    quotationIds.insert(quotation.persistentModelID)
                }
            }

            guard !Task.isCancelled else { return }
            searchResults = results
            isSearching = false
            matchSets = MatchSets(authorIds: authorIds, sourceIds: sourceIds, quotationIds: quotationIds)
        }
    }

    func matchSetsForQuery() -> MatchSets? {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return matchSets
    }
}
