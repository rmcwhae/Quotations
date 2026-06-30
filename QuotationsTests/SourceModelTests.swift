//
//  SourceModelTests.swift
//  QuotationsTests
//

import XCTest
@testable import Quotations

final class SourceModelTests: XCTestCase {
    func testFormattedDateReadValidMonth() {
        let source = Source(title: "Test", dateReadMonth: 3, dateReadYear: 2024)
        XCTAssertEqual(source.formattedDateRead, "March 2024")
    }

    func testFormattedDateReadInvalidMonthReturnsNil() {
        let source = Source(title: "Test", dateReadMonth: 13, dateReadYear: 2024)
        XCTAssertNil(source.formattedDateRead)
    }

    func testSourceFormatAccessor() {
        let source = Source(title: "Test")
        source.sourceFormat = .kobo
        XCTAssertEqual(source.format, SourceFormat.kobo.rawValue)
        XCTAssertEqual(source.sourceFormat, .kobo)
    }

    func testDateReadSortKey() {
        let full = Source(title: "A", dateReadMonth: 3, dateReadYear: 2024)
        XCTAssertEqual(full.dateReadSortKey, 202_403)

        let yearOnly = Source(title: "B", dateReadYear: 2024)
        XCTAssertEqual(yearOnly.dateReadSortKey, 202_400)

        let none = Source(title: "C")
        XCTAssertEqual(none.dateReadSortKey, Int.min)
    }

    func testCompareByDateReadDescending() {
        let recent = Source(title: "Recent", dateReadMonth: 12, dateReadYear: 2025)
        let older = Source(title: "Older", dateReadMonth: 1, dateReadYear: 2024)
        let undated = Source(title: "Undated")

        XCTAssertTrue(Source.compareByDateReadDescending(recent, older))
        XCTAssertTrue(Source.compareByDateReadDescending(older, undated))
        XCTAssertFalse(Source.compareByDateReadDescending(undated, recent))
    }
}
