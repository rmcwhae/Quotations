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
        XCTAssertFalse(state.isSearching)
    }

    func testNewSearchKeepsPreviousResultsUntilNewOnesArrive() async {
        let state = SearchState()
        state.query = "control"
        state.runSearchIfNeeded(modelContext: context)
        try? await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(state.searchResults.count, 1)

        state.query = "what"
        state.runSearchIfNeeded(modelContext: context)

        // While the next search is pending, the old results stay on screen (no flash).
        XCTAssertTrue(state.isSearching)
        XCTAssertEqual(state.searchResults.count, 1)
        XCTAssertNotNil(state.matchSets)

        try? await Task.sleep(for: .milliseconds(300))
        XCTAssertFalse(state.isSearching)
    }

    func testSearchPopulatesMatchSets() async {
        let state = SearchState()
        state.query = "control"
        state.runSearchIfNeeded(modelContext: context)

        try? await Task.sleep(for: .milliseconds(300))

        XCTAssertFalse(state.isSearching)
        XCTAssertEqual(state.searchResults.count, 1)
        XCTAssertEqual(state.matchSets?.quotationIds.count, 1)
    }
}
