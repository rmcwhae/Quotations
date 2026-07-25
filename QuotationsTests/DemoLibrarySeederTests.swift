//
//  DemoLibrarySeederTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

final class DemoLibrarySeederTests: XCTestCase {
    func testCatalogHasExpectedShape() {
        XCTAssertEqual(DemoCatalog.sources.count, 10)
        XCTAssertEqual(DemoCatalog.quotationCount, 100)
        XCTAssertFalse(DemoCatalog.authorNames.isEmpty)
        for source in DemoCatalog.sources {
            XCTAssertEqual(source.quotations.count, 10, "\(source.title) should have 10 quotations")
            XCTAssertFalse(source.authorName.isEmpty)
            XCTAssertFalse(source.title.isEmpty)
        }
    }

    func testSeederCreatesIsolatedInMemoryLibrary() throws {
        let personalURL = AppGroupStore.sharedStoreURL
        let personalCountBefore = try? StoreSnapshot.liveQuotationCount(forStoreAt: personalURL)

        let container = try DemoLibrarySeeder.makeContainer()
        let context = ModelContext(container)

        let sources = try context.fetch(FetchDescriptor<Source>(
            predicate: #Predicate { $0.deletedAt == nil }
        ))
        let quotations = try context.fetch(FetchDescriptor<Quotation>(
            predicate: #Predicate { $0.deletedAt == nil }
        ))
        let authors = try context.fetch(FetchDescriptor<Author>(
            predicate: #Predicate { $0.deletedAt == nil }
        ))

        XCTAssertEqual(sources.count, DemoCatalog.sources.count)
        XCTAssertEqual(quotations.count, DemoCatalog.quotationCount)
        XCTAssertEqual(authors.count, DemoCatalog.authorNames.count)

        let personalCountAfter = try? StoreSnapshot.liveQuotationCount(forStoreAt: personalURL)
        XCTAssertEqual(personalCountBefore, personalCountAfter)
    }

    @MainActor
    func testLibraryModeControllerSwapsContainersWithoutTouchingPersonalStore() throws {
        let schema = Schema([Author.self, Source.self, Quotation.self])
        let personalConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let personalContainer = try ModelContainer(for: schema, configurations: [personalConfiguration])
        let personalContext = ModelContext(personalContainer)
        personalContext.insert(Author(name: "Personal Author"))
        try personalContext.save()

        let defaults = UserDefaults(suiteName: "DemoModeControllerTests-\(UUID().uuidString)")!
        defaults.removeObject(forKey: LibraryModeController.userDefaultsKey)

        let controller = LibraryModeController(
            personalContainer: personalContainer,
            userDefaults: defaults,
            schema: schema
        )
        XCTAssertFalse(controller.isDemoMode)
        XCTAssertTrue(controller.activeContainer === personalContainer)

        controller.setDemoMode(true)
        XCTAssertTrue(controller.isDemoMode)
        XCTAssertTrue(LibraryModeController.isDemoModeActive)
        XCTAssertFalse(controller.activeContainer === personalContainer)
        XCTAssertTrue(defaults.bool(forKey: LibraryModeController.userDefaultsKey))

        let demoContext = ModelContext(controller.activeContainer)
        let demoQuotations = try demoContext.fetchCount(FetchDescriptor<Quotation>(
            predicate: #Predicate { $0.deletedAt == nil }
        ))
        XCTAssertEqual(demoQuotations, DemoCatalog.quotationCount)

        let personalAuthors = try personalContext.fetchCount(FetchDescriptor<Author>(
            predicate: #Predicate { $0.deletedAt == nil }
        ))
        XCTAssertEqual(personalAuthors, 1)

        controller.setDemoMode(false)
        XCTAssertFalse(controller.isDemoMode)
        XCTAssertFalse(LibraryModeController.isDemoModeActive)
        XCTAssertTrue(controller.activeContainer === personalContainer)
        XCTAssertFalse(defaults.bool(forKey: LibraryModeController.userDefaultsKey))
    }
}
