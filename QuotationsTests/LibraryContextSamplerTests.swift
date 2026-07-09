//
//  LibraryContextSamplerTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

@MainActor
final class LibraryContextSamplerTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var authorA: Author!
    private var authorB: Author!
    private var sourceA: Source!
    private var sourceB: Source!
    private var quotations: [Quotation] = []

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: Author.self, Source.self, Quotation.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)

        authorA = Author(name: "Author A")
        authorB = Author(name: "Author B")
        sourceA = Source(title: "Book A", author: authorA)
        sourceB = Source(title: "Book B", author: authorB)

        quotations = [
            Quotation(content: "Freedom and mountains echo across the valley", source: sourceA),
            Quotation(content: "Another freedom quote about mountains", source: sourceA),
            Quotation(content: "Justice requires patience and careful thought", source: sourceB)
        ]

        context.insert(authorA)
        context.insert(authorB)
        context.insert(sourceA)
        context.insert(sourceB)
        quotations.forEach { context.insert($0) }
        try context.save()
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func testAuthorQuotationCountsSortsDescending() {
        let counts = LibraryContextSampler.authorQuotationCounts(in: quotations)

        XCTAssertEqual(counts.first?.name, "Author A")
        XCTAssertEqual(counts.first?.count, 2)
        XCTAssertEqual(counts.last?.name, "Author B")
        XCTAssertEqual(counts.last?.count, 1)
    }

    func testOverviewHeaderIncludesLibraryStats() {
        let header = LibraryContextSampler.makeOverviewHeader(for: quotations)

        XCTAssertTrue(header.contains("3 quotations"))
        XCTAssertTrue(header.contains("2 sources"))
        XCTAssertTrue(header.contains("2 authors"))
        XCTAssertTrue(header.contains("Author A (2)"))
    }

    func testRepresentativeSelectionFallsBackWithoutEmbeddings() {
        let ids = LibraryContextSampler.representativeQuotationIDs(
            quotations: quotations,
            entries: [],
            perCluster: 2
        )

        XCTAssertFalse(ids.isEmpty)
        XCTAssertLessThanOrEqual(ids.count, quotations.count)
    }

    func testSampleReturnsOverviewAndQuotationIDs() {
        let sample = LibraryContextSampler.sample(quotations: quotations, entries: [])

        XCTAssertTrue(sample.overviewHeader.contains("3 quotations"))
        XCTAssertFalse(sample.quotations.isEmpty)
    }
}
