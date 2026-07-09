//
//  QuotationContextBuilderTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

@MainActor
final class QuotationContextBuilderTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var quotation: Quotation!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: Author.self, Source.self, Quotation.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)

        let author = Author(name: "Montaigne")
        let source = Source(title: "Essays", author: author)
        quotation = Quotation(content: "We reach the same end by discrepant means.", source: source, location: "Book I")
        context.insert(author)
        context.insert(source)
        context.insert(quotation)
        try context.save()
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func testBuildIncludesAttributionAndCitation() {
        let result = QuotationContextBuilder.build(quotations: [quotation])

        XCTAssertTrue(result.context.contains("Montaigne"))
        XCTAssertTrue(result.context.contains("Essays"))
        XCTAssertTrue(result.context.contains("Book I"))
        XCTAssertEqual(result.citations.count, 1)
        XCTAssertEqual(result.citations.first?.quotationId, quotation.persistentModelID)
    }

    func testBuildRespectsCharacterBudget() {
        let longContent = String(repeating: "word ", count: 500)
        quotation.content = longContent

        let result = QuotationContextBuilder.build(
            quotations: [quotation],
            characterBudget: 120
        )

        XCTAssertLessThanOrEqual(result.context.count, 120)
        XCTAssertEqual(result.citations.count, 1)
    }

    func testResolveQuotationsPreservesOrderAndSkipsMissing() {
        let encoded = QuotationDeepLink.encode(quotation.persistentModelID)!
        let resolved = QuotationContextBuilder.resolveQuotations(
            encodedIDs: [encoded, "missing-id"],
            from: [quotation]
        )

        XCTAssertEqual(resolved.count, 1)
        XCTAssertEqual(resolved.first?.persistentModelID, quotation.persistentModelID)
    }
}
