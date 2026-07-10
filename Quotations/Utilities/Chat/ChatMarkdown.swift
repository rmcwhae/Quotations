//
//  ChatMarkdown.swift
//  Quotations
//

import Foundation
import SwiftUI

enum ChatMarkdown {
    static func attributedString(from text: String) -> AttributedString {
        if let attributed = try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ), !String(attributed.characters).isEmpty {
            return attributed
        }
        return AttributedString(text)
    }
}
