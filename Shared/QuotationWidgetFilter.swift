//
//  QuotationWidgetFilter.swift
//  Quotations
//

import Foundation

enum QuotationWidgetFilter {
    static let minimumWordCount = 5

    static func isEligibleForWidget(_ markdownContent: String) -> Bool {
        let plain = plainText(from: markdownContent)
        guard wordCount(in: plain) >= minimumWordCount else { return false }
        guard nonEmptyParagraphCount(in: plain) <= 1 else { return false }
        return true
    }

    static func plainText(from markdown: String) -> String {
        markdown
            .replacingOccurrences(of: "***", with: "")
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "\\", with: "")
    }

    static func wordCount(in text: String) -> Int {
        text
            .split { $0.isWhitespace || $0.isNewline }
            .count
    }

    static func nonEmptyParagraphCount(in text: String) -> Int {
        text
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .count
    }
}
