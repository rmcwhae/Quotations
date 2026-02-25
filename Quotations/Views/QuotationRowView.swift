//
//  QuotationRowView.swift
//  Quotations
//

import SwiftData
import SwiftUI

/// System serif for quotation text (larger for readability).
private let quotationFont = Font.system(size: 16, design: .serif)
/// Line spacing ~1.4 (extra points between lines).
private let quotationLineSpacing: CGFloat = 6

struct QuotationRowView: View {
    let quotation: Quotation
    let searchQuery: String
    var onEdit: (Quotation) -> Void
    var onDelete: (PersistentIdentifier) -> Void

    @State private var isEditing = false
    @State private var editedContent = ""
    @State private var showDeleteConfirmation = false

    private var pageText: String {
        if let start = quotation.startPage, let end = quotation.endPage {
            return "(\(start)–\(end))"
        }
        if let start = quotation.startPage {
            return "(\(start))"
        }
        return ""
    }

    /// Fixed width for the action column so text doesn't shift when toggling edit.
    private let actionsColumnWidth: CGFloat = 88

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                if isEditing {
                    TextEditor(text: $editedContent)
                        .font(quotationFont)
                        .lineSpacing(quotationLineSpacing)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, -4)
                        .padding(.vertical, -4)
                        .frame(minHeight: 60)
                        .onSubmit { commitEdit() }
                } else {
                    if pageText.isEmpty {
                        Button {
                            editedContent = quotation.content
                            isEditing = true
                        } label: {
                            HighlightMatch(text: quotation.content, query: searchQuery)
                                .font(quotationFont)
                                .lineSpacing(quotationLineSpacing)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            HighlightMatch(text: quotation.content, query: searchQuery)
                                .font(quotationFont)
                                .lineSpacing(quotationLineSpacing)
                            Text(pageText)
                                .font(quotationFont)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                if isEditing {
                    Button("Save") {
                        commitEdit()
                    }
                    .buttonStyle(.borderless)
                }
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Delete quotation")
            }
            .frame(width: actionsColumnWidth, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .confirmationDialog("Delete this quotation?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                onDelete(quotation.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func commitEdit() {
        let trimmed = editedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            quotation.content = trimmed
            quotation.updatedAt = Date()
            onEdit(quotation)
        }
        isEditing = false
    }
}
