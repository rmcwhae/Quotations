//
//  SourcePersistentIdentifierTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

final class SourcePersistentIdentifierTests: XCTestCase {
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

    /// Reproduces the selection crash path: temporary IDs captured before save must not
    /// be used for navigation. After save, lookup by `persistentModelID` succeeds.
    func testPostSaveIdentifierResolvesSourceCreatedWithNewAuthor() throws {
        let author = Author(name: "Brand New Author")
        context.insert(author)
        let source = Source(title: "New Book", author: author)
        context.insert(source)

        let idBeforeSave = source.persistentModelID
        try context.save()
        let idAfterSave = source.persistentModelID

        let activeSources = try context.fetch(
            FetchDescriptor<Source>(predicate: #Predicate { $0.deletedAt == nil })
        )

        XCTAssertTrue(
            activeSources.contains { $0.persistentModelID == idAfterSave },
            "Selection must use the post-save persistent identifier"
        )
        XCTAssertNil(source.deletedAt)

        if idBeforeSave != idAfterSave {
            XCTAssertFalse(
                activeSources.contains { $0.persistentModelID == idBeforeSave },
                "Pre-save temporary identifiers must not be used for selection"
            )
        }
    }
}
