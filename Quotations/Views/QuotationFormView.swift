//
//  QuotationFormView.swift
//  Quotations
//

import SwiftData
import SwiftUI

private let quotationTextMaxWidth: CGFloat = 520

private enum FormField { case content, startPage, endPage }

struct QuotationFormView: View {
    let source: Source
    var onSuccess: () -> Void
    var onCancel: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @State private var content = ""
    @State private var startPage = ""
    @State private var endPage = ""
    @State private var isContentFocused = false
    @State private var blurCheckTask: Task<Void, Never>?
    @FocusState private var focusedField: FormField?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            QuotationRichTextEditor(
                markdown: $content,
                maxWidth: quotationTextMaxWidth,
                isFocused: isContentFocused,
                onFocusChange: { isContentFocused = $0 }
            )
            .frame(maxWidth: quotationTextMaxWidth, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        isContentFocused ? AppColors.highlightColor : Color.clear,
                        lineWidth: isContentFocused ? 3 : 0
                    )
            }

            HStack(spacing: 12) {
                Label("Start", systemImage: "")
                    .labelStyle(.titleOnly)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("", text: $startPage)
                    .textFieldStyle(.roundedBorder)
                    .tint(AppColors.highlightColor)
                    .frame(width: 48)
                    .focused($focusedField, equals: .startPage)
                    .onSubmit { commitIfNonEmpty() }
                Text("End")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("", text: $endPage)
                    .textFieldStyle(.roundedBorder)
                    .tint(AppColors.highlightColor)
                    .frame(width: 48)
                    .focused($focusedField, equals: .endPage)
                    .onSubmit { commitIfNonEmpty() }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
        .onChange(of: focusedField) { _, newField in
            if newField != nil { isContentFocused = false }
            scheduleBlurCheck()
        }
        .onChange(of: isContentFocused) { _, focused in
            if focused { focusedField = nil }
            scheduleBlurCheck()
        }
        .onAppear { isContentFocused = true }
    }

    /// Commit (or cancel) only once focus has fully left the form, so moving
    /// between the content editor and page fields does not prematurely commit.
    private func scheduleBlurCheck() {
        blurCheckTask?.cancel()
        blurCheckTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled else { return }
            guard !isContentFocused, focusedField == nil else { return }
            if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                onCancel?()
            } else {
                commitIfNonEmpty()
            }
        }
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
