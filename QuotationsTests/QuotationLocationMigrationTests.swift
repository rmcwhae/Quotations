//
//  QuotationLocationMigrationTests.swift
//  QuotationsTests
//

import XCTest
@testable import Quotations

final class QuotationLocationMigrationTests: XCTestCase {
    func testMigratedLocationRange() {
        XCTAssertEqual(QuotationLocationMigration.migratedLocation(startPage: 35, endPage: 36), "35\u{2013}36")
    }

    func testMigratedLocationSinglePage() {
        XCTAssertEqual(QuotationLocationMigration.migratedLocation(startPage: 12, endPage: 12), "12")
        XCTAssertEqual(QuotationLocationMigration.migratedLocation(startPage: 12, endPage: nil), "12")
    }

    func testMigratedLocationEndOnly() {
        XCTAssertEqual(QuotationLocationMigration.migratedLocation(startPage: nil, endPage: 8), "8")
    }

    func testMigratedLocationNil() {
        XCTAssertNil(QuotationLocationMigration.migratedLocation(startPage: nil, endPage: nil))
    }
}
