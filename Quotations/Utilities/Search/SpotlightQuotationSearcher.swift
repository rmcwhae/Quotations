//
//  SpotlightQuotationSearcher.swift
//  Quotations
//

import CoreSpotlight
import Foundation

enum SpotlightQuotationSearcher {
    private static let domainAttribute = "kMDItemDomainIdentifier"
    private static let textContentAttribute = "kMDItemTextContent"
    private static let descriptionAttribute = "kMDItemContentDescription"

    static func search(query: String, limit: Int = 50) async -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return await searchWithQueryString(trimmed, limit: limit)
    }

    private static func searchWithQueryString(_ query: String, limit: Int) async -> [String] {
        let escaped = query.replacingOccurrences(of: "\"", with: "\\\"")
        let queryString =
            "(\(textContentAttribute) == \"*\(escaped)*\"c || \(descriptionAttribute) == \"*\(escaped)*\"c) && \(domainAttribute) == '\(QuotationSpotlightIndexer.domainIdentifier)'"

        let context = CSSearchQueryContext()
        let searchQuery = CSSearchQuery(queryString: queryString, queryContext: context)
        return await collectEncodedIDs(from: searchQuery, limit: limit)
    }

    private static func collectEncodedIDs(from query: CSSearchQuery, limit: Int) async -> [String] {
        await withCheckedContinuation { continuation in
            var encodedIDs: [String] = []
            var seen = Set<String>()

            query.foundItemsHandler = { items in
                for item in items {
                    guard seen.insert(item.uniqueIdentifier).inserted else { continue }
                    encodedIDs.append(item.uniqueIdentifier)
                    if encodedIDs.count >= limit { break }
                }
            }

            query.completionHandler = { _ in
                continuation.resume(returning: Array(encodedIDs.prefix(limit)))
            }

            query.start()
        }
    }
}
