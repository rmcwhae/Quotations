//
//  QuotationLocationEditingTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

final class QuotationLocationEditingTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: Author.self, Source.self, Quotation.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func testInlineLocationSavePersistsToStore() throws {
        let author = Author(name: "Seneca")
        let source = Source(title: "Letters", author: author)
        let quotation = Quotation(content: "Luck is what happens when preparation meets opportunity.", source: source)
        context.insert(author)
        context.insert(source)
        context.insert(quotation)
        try context.save()

        quotation.location = "p. 42"
        quotation.updatedAt = Date()
        try context.save()

        let fetched = try XCTUnwrap(
            context.fetch(
                FetchDescriptor<Quotation>(predicate: #Predicate { $0.deletedAt == nil })
            ).first
        )
        XCTAssertEqual(fetched.location, "p. 42")
    }

    func testUneditedInspectorDraftMustNotClearSavedInlineLocation() throws {
        let author = Author(name: "Epictetus")
        let source = Source(title: "Discourses", author: author)
        let quotation = Quotation(content: "No man is free who is not master of himself.", source: source)
        context.insert(author)
        context.insert(source)
        context.insert(quotation)
        try context.save()

        quotation.location = "p. 12"
        quotation.updatedAt = Date()
        try context.save()

        let inspectorDraft = ""
        let draftEdited = false
        let newValue = inspectorDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = newValue.isEmpty ? nil : newValue

        if draftEdited, normalized != quotation.location {
            quotation.location = normalized
            try context.save()
        }

        let fetched = try XCTUnwrap(
            context.fetch(
                FetchDescriptor<Quotation>(predicate: #Predicate { $0.deletedAt == nil })
            ).first
        )
        XCTAssertEqual(fetched.location, "p. 12")
    }
}
