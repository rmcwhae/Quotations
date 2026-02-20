//
//  QuotationFormView.swift
//  Quotations
//

import SwiftData
import SwiftUI

private let quotationFont = Font.system(.body, design: .serif)

struct QuotationFormView: View {
    let source: Source
    var onSuccess: () -> Void
    var onCancel: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @State private var content = ""
    @State private var startPage = ""
    @State private var endPage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Quotation text", text: $content, axis: .vertical)
                .font(quotationFont)
                .lineLimit(3...8)
                .textFieldStyle(.roundedBorder)

            HStack {
                TextField("Start page", text: $startPage)
                    .frame(width: 80)
                TextField("End page", text: $endPage)
                    .frame(width: 80)
            }
            .textFieldStyle(.roundedBorder)

            HStack {
                if let onCancel {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                Spacer()
                Button("Add") {
                    submit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }

    private func submit() {
        let c = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !c.isEmpty else { return }
        let start = Int(startPage.trimmingCharacters(in: .whitespacesAndNewlines))
        let end = Int(endPage.trimmingCharacters(in: .whitespacesAndNewlines))
        let quotation = Quotation(content: c, source: source, startPage: start, endPage: end)
        modelContext.insert(quotation)
        try? modelContext.save()
        content = ""
        startPage = ""
        endPage = ""
        onSuccess()
    }
}
