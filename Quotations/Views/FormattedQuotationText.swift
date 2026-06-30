//
//  FormattedQuotationText.swift
//  Quotations
//

import SwiftUI

/// Read-only quotation text with basic markdown formatting applied.
struct FormattedQuotationText: View {
    let text: String

    @State private var cachedAttributed = AttributedString()
    @State private var cacheKey = ""

    var body: some View {
        Text(cachedAttributed)
            .font(MarkdownCodec.quotationFont)
            .lineSpacing(MarkdownCodec.quotationLineSpacing)
            .onAppear { rebuildCacheIfNeeded() }
            .onChange(of: text) { _, _ in rebuildCacheIfNeeded() }
    }

    private func rebuildCacheIfNeeded() {
        guard text != cacheKey else { return }
        cacheKey = text
        cachedAttributed = MarkdownCodec.attributedString(from: text)
    }
}

#Preview {
    FormattedQuotationText(text: "This is **bold** and *italic* text.")
        .padding()
}
