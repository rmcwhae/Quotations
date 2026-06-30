//
//  LibraryFilterResolverTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

@MainActor
final class LibraryFilterResolverTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var author: Author!
    private var koboSource: Source!
    private var printSource: Source!
    private var oldQuotation: Quotation!
    private var newQuotation: Quotation!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: Author.self, Source.self, Quotation.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)

        author = Author(name: "Seneca")
        koboSource = Source(
            title: "Letters",
            author: author,
            format: SourceFormat.kobo.rawValue,
            dateReadMonth: 6,
            dateReadYear: 2024
        )
        printSource = Source(
            title: "Essays",
            author: author,
            format: SourceFormat.printBook.rawValue,
            dateReadMonth: 3,
            dateReadYear: 2023
        )
        oldQuotation = Quotation(content: "Older quote", source: printSource)
        oldQuotation.createdAt = Date(timeIntervalSince1970: 1_000)
        newQuotation = Quotation(content: "Newer quote", source: koboSource)
        newQuotation.createdAt = Date(timeIntervalSince1970: 2_000)

        context.insert(author)
        context.insert(koboSource)
        context.insert(printSource)
        context.insert(oldQuotation)
        context.insert(newQuotation)
        try context.save()
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func testRecentReadsSortsByDateReadDescending() {
        let sources = [printSource!, koboSource!]
        let result = LibraryFilterResolver.sources(for: .recentReads, from: sources)
        XCTAssertEqual(result.map(\.title), ["Letters", "Essays"])
    }

    func testFormatFilterReturnsMatchingSources() {
        let sources = [printSource!, koboSource!]
        let result = LibraryFilterResolver.sources(for: .format(.kobo), from: sources)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Letters")
    }

    func testAllQuotesReturnsNewestFirst() {
        let quotations = [oldQuotation!, newQuotation!]
        let result = LibraryFilterResolver.quotations(for: .allQuotes, from: quotations)
        XCTAssertEqual(result.map(\.content), ["Newer quote", "Older quote"])
    }

    func testSearchResultsFilterUsesMatchSets() {
        let quotations = [oldQuotation!, newQuotation!]
        let matchSets = MatchSets(
            authorIds: [],
            sourceIds: [printSource!.id],
            quotationIds: [oldQuotation!.id]
        )
        let result = LibraryFilterResolver.quotations(
            for: .searchResults,
            from: quotations,
            matchSets: matchSets
        )
        XCTAssertEqual(result.map(\.content), ["Older quote"])
    }

    func testSearchResultSourcesFiltersAndSorts() {
        let sources = [printSource!, koboSource!]
        let matchSets = MatchSets(
            authorIds: [],
            sourceIds: Set(sources.map(\.id)),
            quotationIds: []
        )
        let result = LibraryFilterResolver.searchResultSources(from: sources, matchSets: matchSets)
        XCTAssertEqual(result.map(\.title), ["Letters", "Essays"])
    }
}
