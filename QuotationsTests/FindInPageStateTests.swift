//
//  FindInPageStateTests.swift
//  QuotationsTests
//

import XCTest
@testable import Quotations

final class FindInPageStateTests: XCTestCase {
    func testTrimmedQueryStripsWhitespace() {
        let find = FindInPageState()
        find.query = "  hello  "
        XCTAssertEqual(find.trimmedQuery, "hello")
    }

    func testTrimmedQueryEmptyForBlankInput() {
        let find = FindInPageState()
        find.query = "   "
        XCTAssertTrue(find.trimmedQuery.isEmpty)
    }
}
