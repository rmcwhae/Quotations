//
//  ChatMarkdownTests.swift
//  QuotationsTests
//

import XCTest
@testable import Quotations

final class ChatMarkdownTests: XCTestCase {
    func testBoldMarkdownRendersWithoutAsterisks() {
        let attributed = ChatMarkdown.attributedString(from: "You quote **Timothy Keller** often.")
        let rendered = String(attributed.characters)
        XCTAssertEqual(rendered, "You quote Timothy Keller often.")
        XCTAssertFalse(rendered.contains("*"))
    }
}
