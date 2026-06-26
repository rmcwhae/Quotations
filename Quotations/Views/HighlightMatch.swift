//
//  HighlightMatch.swift
//  Quotations
//

import SwiftUI

/// Renders text with any substring matching the query (case-insensitive) highlighted.
struct HighlightMatch: View {
    let text: String
    let query: String

    private var attributedString: AttributedString {
        var result = AttributedString()
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty {
            result = AttributedString(text)
            return result
        }
        var remaining = text
        while let range = remaining.range(of: q, options: .caseInsensitive) {
            let before = String(remaining[..<range.lowerBound])
            let match = String(remaining[range])
            if !before.isEmpty {
                result += AttributedString(before)
            }
            var highlighted = AttributedString(match)
            highlighted.backgroundColor = AppColors.searchHighlight
            result += highlighted
            remaining = String(remaining[range.upperBound...])
        }
        if !remaining.isEmpty {
            result += AttributedString(remaining)
        }
        return result
    }

    var body: some View {
        Text(attributedString)
    }
}

#Preview {
    HighlightMatch(text: "The quick brown fox", query: "quick")
        .padding()
}
