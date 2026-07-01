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

    func testCompareByDateAddedDescending() {
        let older = Source(title: "Older")
        older.createdAt = Date(timeIntervalSince1970: 1_000)
        let newer = Source(title: "Newer")
        newer.createdAt = Date(timeIntervalSince1970: 2_000)

        XCTAssertTrue(Source.compareByDateAddedDescending(newer, older))
        XCTAssertFalse(Source.compareByDateAddedDescending(older, newer))
    }

    func testCompareByDateAddedDescendingTieBreaksByTitle() {
        let same = Date(timeIntervalSince1970: 1_000)
        let apple = Source(title: "Apple")
        apple.createdAt = same
        let banana = Source(title: "Banana")
        banana.createdAt = same

        XCTAssertTrue(Source.compareByDateAddedDescending(apple, banana))
        XCTAssertFalse(Source.compareByDateAddedDescending(banana, apple))
    }

    func testCompareByAuthorNameAscendingOrdersAlphabetically() {
        let seneca = Source(title: "Letters", author: Author(name: "Seneca"))
        let aurelius = Source(title: "Meditations", author: Author(name: "Marcus Aurelius"))

        XCTAssertTrue(Source.compareByAuthorNameAscending(aurelius, seneca))
        XCTAssertFalse(Source.compareByAuthorNameAscending(seneca, aurelius))
    }

    func testCompareByAuthorNameAscendingTreatsNilAuthorAsEmpty() {
        let noAuthor = Source(title: "Anonymous Work")
        let withAuthor = Source(title: "Named Work", author: Author(name: "Zora"))

        XCTAssertTrue(Source.compareByAuthorNameAscending(noAuthor, withAuthor))
        XCTAssertFalse(Source.compareByAuthorNameAscending(withAuthor, noAuthor))
    }

    func testCompareByTitleAscendingIsLocaleAware() {
        let cabin = Source(title: "Cabin")
        let cafe = Source(title: "Café")

        XCTAssertTrue(Source.compareByTitleAscending(cabin, cafe))
        XCTAssertFalse(Source.compareByTitleAscending(cafe, cabin))
    }

    func testCompareByTitleAscendingTieBreaksByDateAddedDescending() {
        let first = Source(title: "Same Title")
        first.createdAt = Date(timeIntervalSince1970: 1_000)
        let second = Source(title: "Same Title")
        second.createdAt = Date(timeIntervalSince1970: 2_000)

        XCTAssertTrue(Source.compareByTitleAscending(second, first))
        XCTAssertFalse(Source.compareByTitleAscending(first, second))
    }

    func testComparatorDispatchesToMatchingSortOption() {
        let sourceA = Source(title: "A", author: Author(name: "Zeta"))
        let sourceB = Source(title: "B", author: Author(name: "Alpha"))

        XCTAssertTrue(Source.comparator(for: .title)(sourceA, sourceB))
        XCTAssertTrue(Source.comparator(for: .authorName)(sourceB, sourceA))
    }
}
