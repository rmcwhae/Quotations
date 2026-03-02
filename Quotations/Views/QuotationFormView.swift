//
//  QuotationFormView.swift
//  Quotations
//

import SwiftData
import SwiftUI

private let quotationFont = Font.system(size: 16, design: .serif)
private let quotationLineSpacing: CGFloat = 6

struct QuotationFormView: View {
    let source: Source
    var onSuccess: () -> Void
    var onCancel: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @State private var content = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("Add quotation…", text: $content, axis: .vertical)
            .font(quotationFont)
            .lineSpacing(quotationLineSpacing)
            .lineLimit(1...8)
            .textFieldStyle(.roundedBorder)
            .focused($isFocused)
            .onSubmit {
                commitIfNonEmpty()
            }
            .onChange(of: isFocused) { _, focused in
                if !focused {
                    if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onCancel?()
                    } else {
                        commitIfNonEmpty()
                    }
                }
            }
    }

    private func commitIfNonEmpty() {
        let c = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !c.isEmpty else { return }
        let quotation = Quotation(content: c, source: source, startPage: nil, endPage: nil)
        modelContext.insert(quotation)
        try? modelContext.save()
        content = ""
        onSuccess()
    }
}
