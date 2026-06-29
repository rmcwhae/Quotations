//
//  SoftDelete.swift
//  Quotations
//

import Foundation
import SwiftData

/// Centralized soft-delete policies for Authors, Sources, and Quotations.
enum SoftDelete {
    /// Soft-deletes a source and all of its non-deleted quotations.
    static func source(_ source: Source, in context: ModelContext) throws {
        let now = Date()
        source.deletedAt = now
        source.updatedAt = now
        let sourceId = source.persistentModelID
        let descriptor = FetchDescriptor<Quotation>(
            predicate: #Predicate { q in q.source?.persistentModelID == sourceId && q.deletedAt == nil }
        )
        let quotations = try context.fetch(descriptor)
        for quotation in quotations {
            quotation.deletedAt = now
            quotation.updatedAt = now
        }
        try context.save()
    }

    /// Soft-deletes an author and cascades to all of their sources and quotations.
    static func author(_ author: Author, in context: ModelContext) throws {
        let now = Date()
        author.deletedAt = now
        author.updatedAt = now
        let authorId = author.persistentModelID
        let sourceDescriptor = FetchDescriptor<Source>(
            predicate: #Predicate { s in s.author?.persistentModelID == authorId && s.deletedAt == nil }
        )
        let sources = try context.fetch(sourceDescriptor)
        for source in sources {
            source.deletedAt = now
            source.updatedAt = now
            let sourceId = source.persistentModelID
            let quotationDescriptor = FetchDescriptor<Quotation>(
                predicate: #Predicate { q in q.source?.persistentModelID == sourceId && q.deletedAt == nil }
            )
            let quotations = try context.fetch(quotationDescriptor)
            for quotation in quotations {
                quotation.deletedAt = now
                quotation.updatedAt = now
            }
        }
        try context.save()
    }

    /// Soft-deletes a single quotation.
    static func quotation(_ quotation: Quotation, in context: ModelContext) throws {
        let now = Date()
        quotation.deletedAt = now
        quotation.updatedAt = now
        try context.save()
    }
}

extension Notification.Name {
    static let quotationsDataDidChange = Notification.Name("quotationsDataDidChange")
}
