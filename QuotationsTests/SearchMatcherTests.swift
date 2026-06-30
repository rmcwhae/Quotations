//
//  SearchMatcherTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

final class SearchMatcherTests: XCTestCase {
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

    func testEmptyQueryReturnsNoMatches() {
        let author = Author(name: "Plato")
        let source = Source(title: "Republic", author: author)
        let quotation = Quotation(content: "Justice is virtue", source: source)
        context.insert(author)
        context.insert(source)
        context.insert(quotation)

        let result = SearchMatcher.match(quotations: [quotation], query: "   ")
        XCTAssertTrue(result.results.isEmpty)
        XCTAssertTrue(result.matchSets.quotationIds.isEmpty)
        XCTAssertTrue(result.quotationsBySourceId.isEmpty)
    }

    func testMatchesContentTitleAuthorAndLocation() {
        let author = Author(name: "Aristotle")
        let source = Source(title: "Nicomachean Ethics", author: author)
        let quotation = Quotation(content: "Virtue is a mean", source: source, location: "p. 42")
        context.insert(author)
        context.insert(source)
        context.insert(quotation)

        XCTAssertEqual(SearchMatcher.match(quotations: [quotation], query: "virtue").results.count, 1)
        XCTAssertEqual(SearchMatcher.match(quotations: [quotation], query: "ethics").results.count, 1)
        XCTAssertEqual(SearchMatcher.match(quotations: [quotation], query: "aristotle").results.count, 1)
        XCTAssertEqual(SearchMatcher.match(quotations: [quotation], query: "42").results.count, 1)
    }

    func testSkipsDeletedOrOrphanedQuotations() {
        let author = Author(name: "Seneca")
        let source = Source(title: "Letters", author: author)
        let deletedSource = Source(title: "Hidden", author: author)
        deletedSource.deletedAt = Date()

        let live = Quotation(content: "Visible", source: source)
        let orphaned = Quotation(content: "Orphan", source: nil)
        let onDeletedSource = Quotation(content: "Hidden quote", source: deletedSource)

        context.insert(author)
        context.insert(source)
        context.insert(deletedSource)
        context.insert(live)
        context.insert(orphaned)
        context.insert(onDeletedSource)

        let result = SearchMatcher.match(
            quotations: [live, orphaned, onDeletedSource],
            query: "quote"
        )
        XCTAssertTrue(result.results.isEmpty)
    }

    func testGroupsQuotationsBySource() {
        let author = Author(name: "Montaigne")
        let source = Source(title: "Essays", author: author)
        let first = Quotation(content: "To philosophize", source: source)
        let second = Quotation(content: "To philosophize again", source: source)
        context.insert(author)
        context.insert(source)
        context.insert(first)
        context.insert(second)

        let result = SearchMatcher.match(quotations: [first, second], query: "philosophize")
        XCTAssertEqual(result.results.count, 2)
        XCTAssertEqual(result.quotationsBySourceId[source.persistentModelID]?.count, 2)
    }
}
