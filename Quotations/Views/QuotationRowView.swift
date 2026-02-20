//
//  QuotationRowView.swift
//  Quotations
//

import SwiftUI
import SwiftData

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

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                if isEditing {
                    TextEditor(text: $editedContent)
                        .frame(minHeight: 60)
                        .onSubmit { commitEdit() }
                } else {
                    if pageText.isEmpty {
                        Button {
                            editedContent = quotation.content
                            isEditing = true
                        } label: {
                            HighlightMatch(text: quotation.content, query: searchQuery)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            HighlightMatch(text: quotation.content, query: searchQuery)
                            Text(pageText)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !pageText.isEmpty || isEditing {
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
            } else {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Delete quotation")
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
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
