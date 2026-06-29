//
//  MarkdownCodecTests.swift
//  QuotationsTests
//

import AppKit
import XCTest
@testable import Quotations

final class MarkdownCodecTests: XCTestCase {
    func testRoundTripBold() {
        let markdown = "This is **bold** text."
        let attributed = MarkdownCodec.editorAttributedString(from: markdown)
        let serialized = MarkdownCodec.markdown(from: attributed)
        XCTAssertEqual(serialized, markdown)
    }

    func testEscapesLiteralAsterisksInPlainText() {
        let source = NSMutableAttributedString(string: "2 * 3 = 6")
        source.addAttributes(MarkdownCodec.editorTypingAttributes, range: NSRange(location: 0, length: source.length))
        let serialized = MarkdownCodec.markdown(from: source)
        XCTAssertEqual(serialized, "2 \\* 3 = 6")
    }

    func testAttributedStringFromMarkdownPreservesBold() {
        let result = MarkdownCodec.attributedString(from: "**hello**")
        XCTAssertTrue(String(result.characters).contains("hello"))
    }
}
