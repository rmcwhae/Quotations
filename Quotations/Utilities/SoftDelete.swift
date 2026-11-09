//
//  SoftDelete.swift
//  Quotations
//

import AppKit
import Foundation
import SwiftData

/// Centralized soft-delete policies for Authors, Sources, and Quotations.
enum SoftDelete {
    /// Soft-deletes a source and all of its non-deleted quotations.
    /// With an `undoManager`, Edit > Undo restores exactly the records this call deleted.
    static func source(_ source: Source, in context: ModelContext, undoManager: UndoManager? = nil) throws {
        try setDeleted(
            Date(),
            sources: [source],
            quotations: source.quotations.filter { $0.deletedAt == nil },
            in: context,
            undoManager: undoManager,
            actionName: "Delete Source"
        )
    }

    /// Soft-deletes an author and cascades to all of their sources and quotations.
    static func author(_ author: Author, in context: ModelContext, undoManager: UndoManager? = nil) throws {
        let sources = author.sources.filter { $0.deletedAt == nil }
        try setDeleted(
            Date(),
            authors: [author],
            sources: sources,
            quotations: sources.flatMap { $0.quotations.filter { $0.deletedAt == nil } },
            in: context,
            undoManager: undoManager,
            actionName: "Delete Author"
        )
    }

    /// Soft-deletes a single quotation.
    static func quotation(_ quotation: Quotation, in context: ModelContext, undoManager: UndoManager? = nil) throws {
        try setDeleted(
            Date(),
            quotations: [quotation],
            in: context,
            undoManager: undoManager,
            actionName: "Delete Quotation"
        )
    }

    /// Sets (or clears, for undo) `deletedAt` on exactly these records, saves, and registers
    /// the inverse so undo and redo alternate.
    private static func setDeleted(
        _ date: Date?,
        authors: [Author] = [],
        sources: [Source] = [],
        quotations: [Quotation] = [],
        in context: ModelContext,
        undoManager: UndoManager?,
        actionName: String
    ) throws {
        let now = Date()
        for author in authors {
            author.deletedAt = date
            author.updatedAt = now
        }
        for source in sources {
            source.deletedAt = date
            source.updatedAt = now
        }
        for quotation in quotations {
            quotation.deletedAt = date
            quotation.updatedAt = now
        }
        try context.saveAndNotify()

        guard let undoManager else { return }
        undoManager.registerUndo(withTarget: context) { [weak undoManager] context in
            // Undo runs outside any view; a failed save here leaves the change in memory
            // and it is written by the next successful save.
            try? setDeleted(
                date == nil ? Date() : nil,
                authors: authors,
                sources: sources,
                quotations: quotations,
                in: context,
                undoManager: undoManager,
                actionName: actionName
            )
        }
        undoManager.setActionName(actionName)
        // DEBUG-UNDO-TITLE (temporary)
        NSLog("UNDO-DEBUG title=%@ sameAsKeyWindow=%d groupingLevel=%d", undoManager.undoMenuItemTitle, (undoManager === NSApp.mainWindow?.undoManager) ? 1 : 0, undoManager.groupingLevel)
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
}

extension Notification.Name {
    static let quotationsDataDidChange = Notification.Name("quotationsDataDidChange")
    static let addQuotation = Notification.Name("addQuotation")
    static let addSource = Notification.Name("addSource")
    static let focusFindInPage = Notification.Name("focusFindInPage")
    static let openAdvancedSearch = Notification.Name("openAdvancedSearch")
}
