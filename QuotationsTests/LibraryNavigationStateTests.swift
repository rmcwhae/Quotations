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

    func testEffectiveFilterUsesSearchResultsWhenSearchActive() {
        let navigation = LibraryNavigationState()
        navigation.selectedFilter = .recentReads
        XCTAssertEqual(navigation.effectiveFilter(isSearchActive: true), .searchResults)
        XCTAssertEqual(navigation.effectiveFilter(isSearchActive: false), .recentReads)
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
}
