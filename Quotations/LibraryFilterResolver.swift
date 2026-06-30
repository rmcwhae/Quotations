//
//  LibraryFilterResolver.swift
//  Quotations
//

import Foundation
import SwiftData

/// Pure filter/sort logic for library navigation. Testable without SwiftUI.
enum LibraryFilterResolver {
    static func sources(
        for filter: LibraryFilter,
        from sources: [Source]
    ) -> [Source] {
        let active = sources.filter { $0.deletedAt == nil }
        switch filter {
        case .recentReads:
            return active.sorted(by: Source.compareByDateReadDescending)
        case .format(let format):
            return active
                .filter { $0.sourceFormat == format }
                .sorted(by: Source.compareByDateReadDescending)
        case .allQuotes, .recentlyAdded, .searchResults:
            return []
        }
    }

    static func quotations(
        for filter: LibraryFilter,
        from quotations: [Quotation],
        matchSets: MatchSets? = nil,
        searchResultIds: [PersistentIdentifier]? = nil
    ) -> [Quotation] {
        let active = quotations.filter { $0.deletedAt == nil }
        switch filter {
        case .allQuotes:
            return active.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        case .recentlyAdded:
            return active.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        case .searchResults:
            if let ids = searchResultIds {
                let idSet = Set(ids)
                return active
                    .filter { idSet.contains($0.id) }
                    .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
            }
            if let sets = matchSets {
                return active
                    .filter { sets.quotationIds.contains($0.id) }
                    .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
            }
            return []
        case .recentReads, .format:
            return []
        }
    }

    static func searchResultQuotationIds(from searchState: SearchState) -> [PersistentIdentifier] {
        searchState.searchResults.map(\.quotationId)
    }

    static func searchResultSources(
        from sources: [Source],
        matchSets: MatchSets?
    ) -> [Source] {
        guard let sets = matchSets else { return [] }
        return sources
            .filter { sets.sourceIds.contains($0.id) }
            .sorted(by: Source.compareByDateReadDescending)
    }
}
