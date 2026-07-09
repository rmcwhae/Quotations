//
//  AppGroupStoreTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

final class AppGroupStoreTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil
    }

    func testConsolidatesSiblingStoreWithMoreQuotations() throws {
        let schema = Schema([Author.self, Source.self, Quotation.self])
        let canonicalURL = tempDirectory.appendingPathComponent("Quotations.store")
        let legacySiblingURL = tempDirectory.appendingPathComponent("default.store")

        let emptyContainer = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(url: canonicalURL)
        )
        try ModelContext(emptyContainer).save()

        let populatedContainer = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(url: legacySiblingURL)
        )
        let populatedContext = ModelContext(populatedContainer)
        let author = Author(name: "Seneca")
        let source = Source(title: "Letters", author: author)
        let quotation = Quotation(content: "Luck is what happens when preparation meets opportunity.", source: source)
        populatedContext.insert(author)
        populatedContext.insert(source)
        populatedContext.insert(quotation)
        try populatedContext.save()

        try AppGroupStore.consolidateSiblingStoresIfNeeded(around: canonicalURL)

        XCTAssertEqual(try BackupManager.liveQuotationCount(forStoreAt: canonicalURL), 1)
    }
}
