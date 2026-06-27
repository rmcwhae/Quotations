//
//  FormattedQuotationText.swift
//  Quotations
//

import SwiftUI

private let quotationFont = Font.system(size: 16, design: .serif)
private let quotationLineSpacing: CGFloat = 6

/// Read-only quotation text with basic markdown formatting applied.
struct FormattedQuotationText: View {
    let text: String

    var body: some View {
        Text(MarkdownCodec.attributedString(from: text))
            .font(quotationFont)
            .lineSpacing(quotationLineSpacing)
    }
}

#Preview {
    FormattedQuotationText(text: "This is **bold** and *italic* text.")
        .padding()
}
