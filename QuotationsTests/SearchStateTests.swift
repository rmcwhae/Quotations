//
//  SearchStateTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

@MainActor
final class SearchStateTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: Author.self, Source.self, Quotation.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)

        let author = Author(name: "Epictetus")
        let source = Source(title: "Discourses", author: author)
        let quotation = Quotation(content: "Control what you can", source: source)
        context.insert(author)
        context.insert(source)
        context.insert(quotation)
        try context.save()
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func testEmptyQueryClearsResultsImmediately() async {
        let state = SearchState()
        state.query = "control"
        state.runSearchIfNeeded(modelContext: context)

        try? await Task.sleep(for: .milliseconds(300))
        XCTAssertFalse(state.searchResults.isEmpty)

        state.query = ""
        state.runSearchIfNeeded(modelContext: context)

        XCTAssertTrue(state.searchResults.isEmpty)
        XCTAssertNil(state.matchSets)
        XCTAssertTrue(state.quotationsBySourceId.isEmpty)
        XCTAssertFalse(state.isSearching)
    }

    func testNewSearchClearsStaleMatchSetsWhileSearching() {
        let state = SearchState()
        state.matchSets = MatchSets(authorIds: [], sourceIds: [], quotationIds: [])
        state.quotationsBySourceId = [:]

        state.query = "control"
        state.runSearchIfNeeded(modelContext: context)

        XCTAssertTrue(state.isSearching)
        XCTAssertNil(state.matchSets)
        XCTAssertTrue(state.quotationsBySourceId.isEmpty)
        XCTAssertTrue(state.searchResults.isEmpty)
    }

    func testSearchPopulatesMatchSets() async {
        let state = SearchState()
        state.query = "control"
        state.runSearchIfNeeded(modelContext: context)

        try? await Task.sleep(for: .milliseconds(300))

        XCTAssertFalse(state.isSearching)
        XCTAssertEqual(state.searchResults.count, 1)
        XCTAssertEqual(state.matchSets?.quotationIds.count, 1)
        XCTAssertEqual(state.quotationsBySourceId.values.first?.count, 1)
    }
}
