//
//  QuotationDeepLinkResolver.swift
//  Quotations
//

import Foundation
import SwiftData

enum QuotationDeepLinkResolver {
    static func quotation(encodedID: String, in context: ModelContext) -> Quotation? {
        let descriptor = FetchDescriptor<Quotation>(
            predicate: #Predicate { $0.deletedAt == nil }
        )
        guard let quotations = try? context.fetch(descriptor) else { return nil }
        return quotations.first {
            QuotationDeepLink.persistentIdentifiersMatch(
                encodedToken: encodedID,
                modelID: $0.persistentModelID
            )
        }
    }

    static func quotation(for id: PersistentIdentifier, in context: ModelContext) -> Quotation? {
        if let quotation = context.model(for: id) as? Quotation,
           quotation.deletedAt == nil {
            return quotation
        }

        guard let encodedID = QuotationDeepLink.encode(id) else { return nil }
        return quotation(encodedID: encodedID, in: context)
    }

    static func sourceID(
        encodedID: String?,
        for quotation: Quotation,
        in context: ModelContext
    ) -> PersistentIdentifier? {
        if let encodedID,
           let source = source(encodedID: encodedID, in: context) {
            return source.persistentModelID
        }
        return quotation.source?.persistentModelID
    }

    static func sourceID(
        _ sourceID: PersistentIdentifier?,
        for quotation: Quotation,
        in context: ModelContext
    ) -> PersistentIdentifier? {
        if let sourceID {
            if let source = context.model(for: sourceID) as? Source,
               source.deletedAt == nil {
                return source.persistentModelID
            }
            if let encodedSourceID = QuotationDeepLink.encode(sourceID),
               let resolved = source(encodedID: encodedSourceID, in: context) {
                return resolved.persistentModelID
            }
        }
        return quotation.source?.persistentModelID
    }

    private static func source(encodedID: String, in context: ModelContext) -> Source? {
        let descriptor = FetchDescriptor<Source>(
            predicate: #Predicate { $0.deletedAt == nil }
        )
        guard let sources = try? context.fetch(descriptor) else { return nil }
        return sources.first {
            QuotationDeepLink.persistentIdentifiersMatch(
                encodedToken: encodedID,
                modelID: $0.persistentModelID
            )
        }
    }
}
