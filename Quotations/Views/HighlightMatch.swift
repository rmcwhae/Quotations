//
//  HighlightMatch.swift
//  Quotations
//

import SwiftUI

private let quotationFont = Font.system(size: 16, design: .serif)
private let quotationLineSpacing: CGFloat = 6

/// Renders text with any substring matching the query (case-insensitive) highlighted.
struct HighlightMatch: View {
    let text: String
    let query: String
    /// When true, parses quotation markdown before highlighting (bold/italic markers are not shown).
    var useMarkdown: Bool = false

    private var attributedString: AttributedString {
        var result = useMarkdown ? MarkdownCodec.attributedString(from: text) : AttributedString(text)
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return result }

        let plainText = String(result.characters)
        var searchStart = plainText.startIndex

        while searchStart < plainText.endIndex,
              let range = plainText.range(of: q, options: .caseInsensitive, range: searchStart..<plainText.endIndex) {
            let lowerOffset = plainText.distance(from: plainText.startIndex, to: range.lowerBound)
            let upperOffset = plainText.distance(from: plainText.startIndex, to: range.upperBound)
            let attrStart = result.index(result.startIndex, offsetByCharacters: lowerOffset)
            let attrEnd = result.index(result.startIndex, offsetByCharacters: upperOffset)
            result[attrStart..<attrEnd].backgroundColor = AppColors.searchHighlight
            searchStart = range.upperBound
        }

        return result
    }

    var body: some View {
        Group {
            if useMarkdown {
                Text(attributedString)
                    .font(quotationFont)
                    .lineSpacing(quotationLineSpacing)
            } else {
                Text(attributedString)
            }
        }
    }
}

#Preview {
    HighlightMatch(text: "The **quick** brown fox", query: "quick", useMarkdown: true)
        .padding()
}
