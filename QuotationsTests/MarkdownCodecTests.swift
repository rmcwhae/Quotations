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

    func testBoldRunWithTrailingSpaceKeepsWhitespaceOutsideMarkers() {
        let source = NSMutableAttributedString()
        source.append(run("hello ", bold: true))
        source.append(run("world", bold: false))

        let serialized = MarkdownCodec.markdown(from: source)
        XCTAssertEqual(serialized, "**hello** world")

        let reloaded = MarkdownCodec.editorAttributedString(from: serialized)
        XCTAssertEqual(reloaded.string, "hello world")
        XCTAssertEqual(MarkdownCodec.markdown(from: reloaded), serialized)
    }

    func testAdjacentSameTraitRunsAreMerged() {
        let source = NSMutableAttributedString()
        source.append(run("a", bold: true))
        let second = run("b", bold: true).mutableCopy() as! NSMutableAttributedString
        second.addAttribute(.foregroundColor, value: NSColor.red, range: NSRange(location: 0, length: 1))
        source.append(second)

        XCTAssertEqual(MarkdownCodec.markdown(from: source), "**ab**")
    }

    func testEscapesInlineSyntaxSoTextRoundTrips() {
        let text = "Use `code`, [link](http://x), ~~strike~~, <b>tag</b>, &copy; and a_b*c\\d"
        let serialized = MarkdownCodec.markdown(from: run(text, bold: false))
        XCTAssertEqual(String(MarkdownCodec.attributedString(from: serialized).characters), text)
        XCTAssertEqual(MarkdownCodec.plainText(from: MarkdownCodec.escapeMarkdown(text)), text)
    }

    private func run(_ text: String, bold: Bool) -> NSAttributedString {
        var attributes = MarkdownCodec.editorTypingAttributes
        attributes[.font] = MarkdownCodec.font(bold: bold, italic: false)
        return NSAttributedString(string: text, attributes: attributes)
    }
}
