//
//  QuotationWidgetFilterTests.swift
//  QuotationsTests
//

import XCTest
@testable import Quotations

final class QuotationWidgetFilterTests: XCTestCase {
    func testRejectsFewerThanFiveWords() {
        XCTAssertFalse(QuotationWidgetFilter.isEligibleForWidget("one two three four"))
    }

    func testAcceptsExactlyFiveWords() {
        XCTAssertTrue(QuotationWidgetFilter.isEligibleForWidget("one two three four five"))
    }

    func testAcceptsMoreThanFiveWords() {
        XCTAssertTrue(QuotationWidgetFilter.isEligibleForWidget("this is a longer quotation"))
    }

    func testRejectsMultipleParagraphsSeparatedByBlankLine() {
        let content = "First paragraph here with enough words.\n\nSecond paragraph here."
        XCTAssertFalse(QuotationWidgetFilter.isEligibleForWidget(content))
    }

    func testAcceptsSingleLineBreakWithinParagraph() {
        let content = "Line one with enough words here\nLine two continues the thought"
        XCTAssertTrue(QuotationWidgetFilter.isEligibleForWidget(content))
    }

    func testMarkdownBoldDoesNotInflateWordCount() {
        XCTAssertTrue(QuotationWidgetFilter.isEligibleForWidget("**one two three four five**"))
        XCTAssertFalse(QuotationWidgetFilter.isEligibleForWidget("**one two three four**"))
    }

    func testPlainTextStripsMarkdownMarkers() {
        XCTAssertEqual(
            QuotationWidgetFilter.plainText(from: "**bold** and *italic*"),
            "bold and italic"
        )
    }

    func testNonEmptyParagraphCount() {
        XCTAssertEqual(QuotationWidgetFilter.nonEmptyParagraphCount(in: "One paragraph only"), 1)
        XCTAssertEqual(
            QuotationWidgetFilter.nonEmptyParagraphCount(in: "Para one\n\nPara two"),
            2
        )
    }
}
