//
//  FormattedQuotationText.swift
//  Quotations
//

import SwiftUI

/// Read-only quotation text with basic markdown formatting applied.
struct FormattedQuotationText: View {
    let text: String

    // No cache: SwiftUI only re-runs `body` when `text` changes, and building here means
    // the first frame already has the real text and height.
    var body: some View {
        Text(MarkdownCodec.attributedString(from: text))
            .font(MarkdownCodec.quotationFont)
            .lineSpacing(MarkdownCodec.quotationLineSpacing)
    }
}

#Preview {
    FormattedQuotationText(text: "This is **bold** and *italic* text.")
        .padding()
}
