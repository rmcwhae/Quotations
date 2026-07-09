//
//  SemanticSearchService.swift
//  Quotations
//

import Foundation
import SwiftData

struct SemanticSearchResponse: Equatable {
    let encodedQuotationIDs: [String]
    let summary: String?
}

enum SemanticSearchService {
    static func search(
        query: String,
        keywordResult: SearchMatcher.MatchResult,
        quotations _: [Quotation]
    ) async -> SemanticSearchResponse {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              SemanticSearchMerger.shouldRunSemanticSearch(query: trimmed, keywordResult: keywordResult) else {
            return SemanticSearchResponse(encodedQuotationIDs: [], summary: nil)
        }

        if #available(macOS 26.0, *) {
            if let aiResponse = await AppleIntelligenceSearchService.search(query: trimmed),
               !aiResponse.encodedQuotationIDs.isEmpty {
                return aiResponse
            }
        }

        async let spotlightIDs = SpotlightQuotationSearcher.search(query: trimmed)
        async let embeddingIDs = EmbeddingSearchIndex.shared.search(query: trimmed)
        let mergedIDs = mergeEncodedIDs(spotlightIDs: await spotlightIDs, embeddingIDs: await embeddingIDs)

        return SemanticSearchResponse(encodedQuotationIDs: mergedIDs, summary: nil)
    }

    private static func mergeEncodedIDs(spotlightIDs: [String], embeddingIDs: [String]) -> [String] {
        var merged: [String] = []
        var seen = Set<String>()
        for id in spotlightIDs + embeddingIDs where seen.insert(id).inserted {
            merged.append(id)
        }
        return merged
    }
}
