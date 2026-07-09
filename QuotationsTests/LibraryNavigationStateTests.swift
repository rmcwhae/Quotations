//
//  LibraryNavigationStateTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

@MainActor
final class LibraryNavigationStateTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var source: Source!
    private var quotation: Quotation!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: Author.self, Source.self, Quotation.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        let author = Author(name: "Plato")
        source = Source(title: "Republic", author: author)
        quotation = Quotation(content: "Know thyself", source: source)
        context.insert(author)
        context.insert(source)
        context.insert(quotation)
        try context.save()
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func testSelectFilterSearchResultsWorks() {
        let navigation = LibraryNavigationState()
        navigation.selectedFilter = .quotationsBySource

        navigation.selectFilter(.searchResults)

        XCTAssertEqual(navigation.selectedFilter, .searchResults)
        XCTAssertNil(navigation.selectedSourceId)
        XCTAssertNil(navigation.selectedQuotationId)
    }

    func testPrimaryFiltersIncludesSearch() {
        XCTAssertTrue(LibraryFilter.primaryFilters.contains(.searchResults))
        XCTAssertTrue(LibraryFilter.primaryFilters.contains(.explore))
        XCTAssertEqual(LibraryFilter.primaryFilters.first, .searchResults)
        XCTAssertEqual(LibraryFilter.primaryFilters[1], .explore)
    }

    func testSelectFilterClearsListSelection() {
        let navigation = LibraryNavigationState()
        navigation.selectedSourceId = source.id
        navigation.selectedQuotationId = quotation.id

        navigation.selectFilter(.allQuotes)

        XCTAssertEqual(navigation.selectedFilter, .allQuotes)
        XCTAssertNil(navigation.selectedSourceId)
        XCTAssertNil(navigation.selectedQuotationId)
    }

    func testSelectQuotationSetsSourceWhenProvided() {
        let navigation = LibraryNavigationState()

        navigation.selectQuotation(quotation.id, sourceId: source.id)

        XCTAssertEqual(navigation.selectedQuotationId, quotation.id)
        XCTAssertEqual(navigation.selectedSourceId, source.id)
    }

    func testOpenQuotationFromDeepLinkSelectsSourceView() {
        let navigation = LibraryNavigationState()
        navigation.selectedFilter = .allQuotes

        navigation.openQuotationFromDeepLink(quotation.id, sourceId: source.id)

        XCTAssertEqual(navigation.selectedFilter, .quotationsBySource)
        XCTAssertEqual(navigation.selectedQuotationId, quotation.id)
        XCTAssertEqual(navigation.selectedSourceId, source.id)
    }
}
