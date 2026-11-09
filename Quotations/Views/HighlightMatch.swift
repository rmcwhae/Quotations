//
//  HighlightMatch.swift
//  Quotations
//

import SwiftUI

/// Renders text with any substring matching the query (case-insensitive) highlighted.
struct HighlightMatch: View {
    let text: String
    let query: String
    /// When true, parses quotation markdown before highlighting (bold/italic markers are not shown).
    var useMarkdown: Bool = false

    // No cache: every input is a plain value, so SwiftUI only re-runs `body` when one
    // changes, and building here means the first frame already has the real text and height.
    var body: some View {
        let attributed = Self.build(text: text, query: query, useMarkdown: useMarkdown)
        if useMarkdown {
            Text(attributed)
                .font(MarkdownCodec.quotationFont)
                .lineSpacing(MarkdownCodec.quotationLineSpacing)
        } else {
            Text(attributed)
        }
    }

    private static func build(text: String, query: String, useMarkdown: Bool) -> AttributedString {
        var result = useMarkdown ? MarkdownCodec.attributedString(from: text) : AttributedString(text)
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return result }

        let plainText = String(result.characters)
        var searchStart = plainText.startIndex

        while searchStart < plainText.endIndex,
              let range = plainText.range(
                of: trimmedQuery,
                options: .caseInsensitive,
                range: searchStart..<plainText.endIndex
              ) {
            let lowerOffset = plainText.distance(from: plainText.startIndex, to: range.lowerBound)
            let upperOffset = plainText.distance(from: plainText.startIndex, to: range.upperBound)
            let attrStart = result.index(result.startIndex, offsetByCharacters: lowerOffset)
            let attrEnd = result.index(result.startIndex, offsetByCharacters: upperOffset)
            result[attrStart..<attrEnd].backgroundColor = AppColors.searchHighlight
            searchStart = range.upperBound
        }

        return result
    }
}

#Preview {
    HighlightMatch(text: "The **quick** brown fox", query: "quick", useMarkdown: true)
        .padding()
}
