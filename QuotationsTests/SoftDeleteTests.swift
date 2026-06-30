//
//  SoftDeleteTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

final class SoftDeleteTests: XCTestCase {
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

    func testQuotationSoftDeleteSetsTimestamps() throws {
        let author = Author(name: "Marcus Aurelius")
        let source = Source(title: "Meditations", author: author)
        let quotation = Quotation(content: "The obstacle is the way", source: source)
        context.insert(author)
        context.insert(source)
        context.insert(quotation)

        try SoftDelete.quotation(quotation, in: context)

        XCTAssertNotNil(quotation.deletedAt)
        XCTAssertNotNil(quotation.updatedAt)
    }

    func testSourceDeleteCascadesToQuotations() throws {
        let author = Author(name: "Cicero")
        let source = Source(title: "On Duties", author: author)
        let first = Quotation(content: "First", source: source)
        let second = Quotation(content: "Second", source: source)
        context.insert(author)
        context.insert(source)
        context.insert(first)
        context.insert(second)

        try SoftDelete.source(source, in: context)

        XCTAssertNotNil(source.deletedAt)
        XCTAssertNotNil(first.deletedAt)
        XCTAssertNotNil(second.deletedAt)
    }

    func testAuthorDeleteCascadesToSourcesAndQuotations() throws {
        let author = Author(name: "Lucretius")
        let source = Source(title: "On the Nature of Things", author: author)
        let quotation = Quotation(content: "Nothing from nothing", source: source)
        context.insert(author)
        context.insert(source)
        context.insert(quotation)

        try SoftDelete.author(author, in: context)

        XCTAssertNotNil(author.deletedAt)
        XCTAssertNotNil(source.deletedAt)
        XCTAssertNotNil(quotation.deletedAt)
    }
}
