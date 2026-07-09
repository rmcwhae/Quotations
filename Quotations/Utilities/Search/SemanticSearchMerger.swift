//
//  SemanticSearchMerger.swift
//  Quotations
//

import Foundation
import SwiftData

enum SemanticSearchMerger {
    static func shouldRunSemanticSearch(query: String, keywordResult: SearchMatcher.MatchResult) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let wordCount = trimmed.split { $0.isWhitespace || $0.isNewline }.count
        if wordCount >= 2 { return true }
        return keywordResult.results.isEmpty
    }

    static func merge(
        keywordResult: SearchMatcher.MatchResult,
        encodedQuotationIDs: [String],
        quotations: [Quotation]
    ) -> SearchMatcher.MatchResult {
        guard !encodedQuotationIDs.isEmpty else { return keywordResult }

        var results = keywordResult.results
        var authorIds = keywordResult.matchSets.authorIds
        var sourceIds = keywordResult.matchSets.sourceIds
        var quotationIds = keywordResult.matchSets.quotationIds
        var quotationsBySourceId = keywordResult.quotationsBySourceId
        var seenQuotationIds = Set(quotationIds)
        var semanticQuotationIds = keywordResult.semanticQuotationIds

        let quotationByEncodedID: [String: Quotation] = Dictionary(
            uniqueKeysWithValues: quotations.compactMap { quotation in
                guard let encoded = QuotationDeepLink.encode(quotation.persistentModelID) else { return nil }
                return (encoded, quotation)
            }
        )

        for encodedID in encodedQuotationIDs {
            guard let quotation = quotationByEncodedID[encodedID],
                  let source = quotation.source,
                  source.deletedAt == nil else {
                continue
            }

            let quotationID = quotation.persistentModelID
            guard seenQuotationIds.insert(quotationID).inserted else { continue }

            let sourceID = source.persistentModelID
            results.append(SearchResultItem(quotationId: quotationID, sourceId: sourceID))
            if let author = source.author, author.deletedAt == nil {
                authorIds.insert(author.persistentModelID)
            }
            sourceIds.insert(sourceID)
            quotationIds.insert(quotationID)
            semanticQuotationIds.insert(quotationID)
            quotationsBySourceId[sourceID, default: []].append(quotationID)
        }

        return SearchMatcher.MatchResult(
            results: results,
            matchSets: MatchSets(authorIds: authorIds, sourceIds: sourceIds, quotationIds: quotationIds),
            quotationsBySourceId: quotationsBySourceId,
            semanticQuotationIds: semanticQuotationIds
        )
    }
}
