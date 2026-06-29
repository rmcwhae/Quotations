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
}
