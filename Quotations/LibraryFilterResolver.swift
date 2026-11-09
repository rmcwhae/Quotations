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
        from sources: [Source],
        sortOption: SourceSortOption
    ) -> [Source] {
        let active = sources.filter { $0.deletedAt == nil }
        let comparator = Source.comparator(for: sortOption)
        switch filter {
        case .quotationsBySource:
            return active.sorted(by: comparator)
        case .format(let format):
            return active
                .filter { $0.sourceFormat == format }
                .sorted(by: comparator)
        case .recentlyAdded, .searchResults, .explore, .ask:
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
        case .quotationsBySource, .format, .explore, .ask:
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

    /// Live quotation counts keyed by source, from quotations already in memory. Avoids
    /// faulting each `source.quotations` relationship (one store fetch per source).
    static func quotationCountsBySourceId(_ quotations: [Quotation]) -> [PersistentIdentifier: Int] {
        var counts: [PersistentIdentifier: Int] = [:]
        for quotation in quotations where quotation.deletedAt == nil {
            guard let sourceId = quotation.source?.persistentModelID else { continue }
            counts[sourceId, default: 0] += 1
        }
        return counts
    }

    static func stats(
        for filter: LibraryFilter,
        resolvedSources: [Source],
        resolvedQuotations: [Quotation],
        quotationCountsBySourceId: [PersistentIdentifier: Int]
    ) -> LibraryStats {
        if filter.showsQuotations {
            let sourceIds = Set(resolvedQuotations.compactMap { $0.source?.id })
            let authorIds = Set(resolvedQuotations.compactMap { $0.source?.author?.id })
            return LibraryStats(
                quotationCount: resolvedQuotations.count,
                sourceCount: sourceIds.count,
                authorCount: authorIds.count
            )
        } else {
            let quotationCount = resolvedSources.reduce(0) {
                $0 + (quotationCountsBySourceId[$1.persistentModelID] ?? 0)
            }
            let authorIds = Set(resolvedSources.compactMap { $0.author?.id })
            return LibraryStats(
                quotationCount: quotationCount,
                sourceCount: resolvedSources.count,
                authorCount: authorIds.count
            )
        }
    }
}

struct LibraryStats: Equatable {
    let quotationCount: Int
    let sourceCount: Int
    let authorCount: Int
}
