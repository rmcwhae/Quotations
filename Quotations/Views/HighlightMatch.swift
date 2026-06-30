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

    @State private var cachedAttributed = AttributedString()
    @State private var cacheKey = ""

    var body: some View {
        Group {
            if useMarkdown {
                Text(cachedAttributed)
                    .font(MarkdownCodec.quotationFont)
                    .lineSpacing(MarkdownCodec.quotationLineSpacing)
            } else {
                Text(cachedAttributed)
            }
        }
        .onAppear { rebuildCacheIfNeeded() }
        .onChange(of: text) { _, _ in rebuildCacheIfNeeded() }
        .onChange(of: query) { _, _ in rebuildCacheIfNeeded() }
        .onChange(of: useMarkdown) { _, _ in rebuildCacheIfNeeded() }
    }

    private func rebuildCacheIfNeeded() {
        let key = "\(text)\u{1F}|\(query)\u{1F}|\(useMarkdown)"
        guard key != cacheKey else { return }
        cacheKey = key
        cachedAttributed = buildAttributedString()
    }

    private func buildAttributedString() -> AttributedString {
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
