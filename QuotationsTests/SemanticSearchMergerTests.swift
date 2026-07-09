//
//  SemanticSearchMergerTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

final class SemanticSearchMergerTests: XCTestCase {
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

    func testShouldRunSemanticSearchForMultiWordQuery() {
        let empty = SearchMatcher.match(quotations: [], query: "mountaineering")
        XCTAssertTrue(
            SemanticSearchMerger.shouldRunSemanticSearch(
                query: "mountaineering quotes",
                keywordResult: empty
            )
        )
    }

    func testShouldRunSemanticSearchWhenKeywordSearchMisses() {
        let author = Author(name: "Muir")
        let source = Source(title: "Mountains", author: author)
        let quotation = Quotation(content: "The mountains are calling", source: source)
        context.insert(author)
        context.insert(source)
        context.insert(quotation)

        let keyword = SearchMatcher.match(quotations: [quotation], query: "alpine")
        XCTAssertTrue(
            SemanticSearchMerger.shouldRunSemanticSearch(query: "alpine", keywordResult: keyword)
        )
    }

    func testMergeAddsSemanticMatchesWithoutDuplicatingKeywordHits() {
        let author = Author(name: "Hillary")
        let source = Source(title: "Everest", author: author)
        let first = Quotation(content: "Summit day", source: source)
        let second = Quotation(content: "Base camp life", source: source)
        context.insert(author)
        context.insert(source)
        context.insert(first)
        context.insert(second)

        let keyword = SearchMatcher.match(quotations: [first, second], query: "summit")
        guard let firstEncoded = QuotationDeepLink.encode(first.persistentModelID),
              let secondEncoded = QuotationDeepLink.encode(second.persistentModelID) else {
            XCTFail("Expected encoded IDs")
            return
        }

        let merged = SemanticSearchMerger.merge(
            keywordResult: keyword,
            encodedQuotationIDs: [firstEncoded, secondEncoded],
            quotations: [first, second]
        )

        XCTAssertEqual(merged.results.count, 2)
        XCTAssertEqual(merged.quotationsBySourceId[source.persistentModelID]?.count, 2)
        XCTAssertFalse(merged.semanticQuotationIds.contains(first.persistentModelID))
        XCTAssertTrue(merged.semanticQuotationIds.contains(second.persistentModelID))
    }
}
