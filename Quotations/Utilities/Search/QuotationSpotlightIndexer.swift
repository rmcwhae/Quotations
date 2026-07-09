//
//  QuotationSpotlightIndexer.swift
//  Quotations
//

import CoreSpotlight
import Foundation
import UniformTypeIdentifiers
import SwiftData

enum QuotationSpotlightIndexer {
    static let domainIdentifier = "com.russellmcwhae.Quotations.quotations"

    static func searchableItem(for quotation: Quotation) -> CSSearchableItem? {
        guard let encodedID = QuotationDeepLink.encode(quotation.persistentModelID),
              let body = QuotationSearchText.searchableBody(for: quotation) else {
            return nil
        }

        let attributeSet = CSSearchableItemAttributeSet(itemContentType: UTType.text.identifier)
        attributeSet.title = QuotationSearchText.displayTitle(for: quotation)
        attributeSet.contentDescription = QuotationSearchText.plainContent(from: quotation.content)
        attributeSet.textContent = body
        if let author = QuotationSearchText.authorName(for: quotation) {
            attributeSet.keywords = [author]
        }
        if let location = quotation.location, !location.isEmpty {
            attributeSet.keywords = (attributeSet.keywords ?? []) + [location]
        }
        attributeSet.relatedUniqueIdentifier = encodedID

        let item = CSSearchableItem(
            uniqueIdentifier: encodedID,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
        return item
    }

    static func index(quotations: [Quotation]) async throws {
        let items = quotations.compactMap { searchableItem(for: $0) }
        guard !items.isEmpty else { return }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            CSSearchableIndex.default().indexSearchableItems(items) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    static func remove(encodedIDs: [String]) async throws {
        guard !encodedIDs.isEmpty else { return }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: encodedIDs) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    static func deleteAll() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            CSSearchableIndex.default().deleteSearchableItems(
                withDomainIdentifiers: [domainIdentifier]
            ) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
