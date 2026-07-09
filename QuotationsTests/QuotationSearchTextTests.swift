//
//  QuotationSearchTextTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

final class QuotationSearchTextTests: XCTestCase {
    func testSearchableBodyIncludesSourceAndAuthor() throws {
        let container = try ModelContainer(
            for: Author.self, Source.self, Quotation.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let author = Author(name: "Annapurna")
        let source = Source(title: "Climbing Memoir", author: author)
        let quotation = Quotation(content: "The summit was close", source: source, location: "p. 12")
        context.insert(author)
        context.insert(source)
        context.insert(quotation)

        let body = QuotationSearchText.searchableBody(for: quotation)
        XCTAssertNotNil(body)
        XCTAssertTrue(body?.contains("The summit was close") == true)
        XCTAssertTrue(body?.contains("Climbing Memoir") == true)
        XCTAssertTrue(body?.contains("Annapurna") == true)
        XCTAssertTrue(body?.contains("p. 12") == true)
    }
}
