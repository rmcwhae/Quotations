//
//  QuotationFormView.swift
//  Quotations
//

import SwiftData
import SwiftUI

private let quotationFont = Font.system(size: 16, design: .serif)
private let quotationLineSpacing: CGFloat = 6
/// Blue border when focused (matches QuotationRowView).
private let editFocusBorder = Color(red: 0.35, green: 0.55, blue: 0.92)

private enum FormField { case content, startPage, endPage }

struct QuotationFormView: View {
    let source: Source
    var onSuccess: () -> Void
    var onCancel: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @State private var content = ""
    @State private var startPage = ""
    @State private var endPage = ""
    @FocusState private var focusedField: FormField?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Add quotation…", text: $content, axis: .vertical)
                .font(quotationFont)
                .lineSpacing(quotationLineSpacing)
                .lineLimit(1...8)
                .textFieldStyle(.plain)
                .fixedSize(horizontal: false, vertical: true)
                .focused($focusedField, equals: .content)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            focusedField != nil ? editFocusBorder : Color.clear,
                            lineWidth: focusedField != nil ? 3 : 0
                        )
                }
                .onSubmit {
                    commitIfNonEmpty()
                }

            HStack(spacing: 12) {
                Label("Start", systemImage: "")
                    .labelStyle(.titleOnly)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("", text: $startPage)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 48)
                    .focused($focusedField, equals: .startPage)
                    .onSubmit { commitIfNonEmpty() }
                Text("End")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("", text: $endPage)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 48)
                    .focused($focusedField, equals: .endPage)
                    .onSubmit { commitIfNonEmpty() }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
        .onChange(of: focusedField) { _, newField in
            if newField == nil {
                if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    onCancel?()
                } else {
                    commitIfNonEmpty()
                }
            }
        }
        .onAppear { focusedField = .content }
    }

    private func commitIfNonEmpty() {
        let c = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !c.isEmpty else { return }
        let start = Int(startPage.trimmingCharacters(in: .whitespaces)).flatMap { $0 > 0 ? $0 : nil }
        let end = Int(endPage.trimmingCharacters(in: .whitespaces)).flatMap { $0 > 0 ? $0 : nil }
        let quotation = Quotation(content: c, source: source, startPage: start, endPage: end)
        modelContext.insert(quotation)
        try? modelContext.save()
        content = ""
        startPage = ""
        endPage = ""
        onSuccess()
    }
}
