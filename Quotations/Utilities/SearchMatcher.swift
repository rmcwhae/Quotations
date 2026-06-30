//
//  SearchMatcher.swift
//  Quotations
//

import Foundation
import SwiftData

enum SearchMatcher {
    struct MatchResult {
        let results: [SearchResultItem]
        let matchSets: MatchSets
        let quotationsBySourceId: [PersistentIdentifier: [PersistentIdentifier]]
    }

    static func match(quotations: [Quotation], query: String) -> MatchResult {
        let lower = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !lower.isEmpty else {
            return MatchResult(results: [], matchSets: emptyMatchSets, quotationsBySourceId: [:])
        }

        var results: [SearchResultItem] = []
        var authorIds = Set<PersistentIdentifier>()
        var sourceIds = Set<PersistentIdentifier>()
        var quotationIds = Set<PersistentIdentifier>()
        var quotationsBySourceId: [PersistentIdentifier: [PersistentIdentifier]] = [:]

        for quotation in quotations {
            guard let source = quotation.source, source.deletedAt == nil else { continue }
            let author = source.author.flatMap { $0.deletedAt == nil ? $0 : nil }

            let contentMatch = quotation.content.lowercased().contains(lower)
            let titleMatch = source.title.lowercased().contains(lower)
            let authorMatch = author?.name.lowercased().contains(lower) ?? false
            let locationMatch = quotation.location?.lowercased().contains(lower) ?? false

            if contentMatch || titleMatch || authorMatch || locationMatch {
                let quotationId = quotation.persistentModelID
                let sourceId = source.persistentModelID
                results.append(SearchResultItem(quotationId: quotationId, sourceId: sourceId))
                if let author { authorIds.insert(author.persistentModelID) }
                sourceIds.insert(sourceId)
                quotationIds.insert(quotationId)
                quotationsBySourceId[sourceId, default: []].append(quotationId)
            }
        }

        return MatchResult(
            results: results,
            matchSets: MatchSets(authorIds: authorIds, sourceIds: sourceIds, quotationIds: quotationIds),
            quotationsBySourceId: quotationsBySourceId
        )
    }

    private static var emptyMatchSets: MatchSets {
        MatchSets(authorIds: [], sourceIds: [], quotationIds: [])
    }
}
