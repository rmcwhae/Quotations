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

        for quotation in source.quotations where quotation.deletedAt == nil {
            quotation.deletedAt = now
            quotation.updatedAt = now
        }

        try context.saveAndNotify()
    }

    /// Soft-deletes an author and cascades to all of their sources and quotations.
    static func author(_ author: Author, in context: ModelContext) throws {
        let now = Date()
        author.deletedAt = now
        author.updatedAt = now

        for source in author.sources where source.deletedAt == nil {
            source.deletedAt = now
            source.updatedAt = now
            for quotation in source.quotations where quotation.deletedAt == nil {
                quotation.deletedAt = now
                quotation.updatedAt = now
            }
        }

        try context.saveAndNotify()
    }

    /// Soft-deletes live quotations whose text is empty or whitespace, e.g. a new draft
    /// left open when the app quit. Returns how many were removed.
    @discardableResult
    static func blankQuotations(in context: ModelContext) throws -> Int {
        let live = try context.fetch(FetchDescriptor<Quotation>(
            predicate: #Predicate<Quotation> { $0.deletedAt == nil }
        ))
        let blank = live.filter { $0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !blank.isEmpty else { return 0 }
        let now = Date()
        for quotation in blank {
            quotation.deletedAt = now
            quotation.updatedAt = now
        }
        try context.save()
        return blank.count
    }

    /// Soft-deletes a single quotation.
    static func quotation(_ quotation: Quotation, in context: ModelContext) throws {
        let now = Date()
        quotation.deletedAt = now
        quotation.updatedAt = now
        try context.saveAndNotify()
    }
}

extension Notification.Name {
    static let quotationsDataDidChange = Notification.Name("quotationsDataDidChange")
    static let addQuotation = Notification.Name("addQuotation")
    static let focusFindInPage = Notification.Name("focusFindInPage")
    static let openAdvancedSearch = Notification.Name("openAdvancedSearch")
}
