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
/// Max width for quotation text and its edit/selection outline.
private let quotationTextMaxWidth: CGFloat = 520
private let debounceInterval: Duration = .milliseconds(500)
private let singleTapDelay: Duration = .milliseconds(250)

struct QuotationRowView: View {
    let quotation: Quotation
    let searchQuery: String
    var isSelected: Bool = false
    var onSelect: (() -> Void)? = nil
    var onEdit: (Quotation) -> Void
    var onDelete: (PersistentIdentifier) -> Void

    @State private var editedContent: String
    @State private var showDeleteConfirmation = false

    init(quotation: Quotation, searchQuery: String, isSelected: Bool = false, onSelect: (() -> Void)? = nil, onEdit: @escaping (Quotation) -> Void, onDelete: @escaping (PersistentIdentifier) -> Void) {
        self.quotation = quotation
        self.searchQuery = searchQuery
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onEdit = onEdit
        self.onDelete = onDelete
        _editedContent = State(initialValue: quotation.content)
    }
    @State private var saveTask: Task<Void, Never>?
    @State private var pendingSelectTask: Task<Void, Never>?
    @FocusState private var isTextFocused: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("\u{201C}")
                .font(.system(size: 36, design: .serif))
                .foregroundStyle(.quaternary)
                .frame(width: 32, alignment: .leading)
                .offset(y: -8)
            VStack(alignment: .leading, spacing: 4) {
                textEditor
            }
            .frame(maxWidth: quotationTextMaxWidth, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.clear, in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        isTextFocused
                            ? AppColors.highlightColor
                            : (isSelected && !isTextFocused ? AppColors.highlightColor.opacity(0.55) : Color.clear),
                        lineWidth: (isTextFocused || (isSelected && !isTextFocused)) ? 3 : 0
                    )
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                pendingSelectTask?.cancel()
                pendingSelectTask = nil
                isTextFocused = true
            }
            .onTapGesture {
                if isTextFocused {
                    isTextFocused = false
                } else {
                    pendingSelectTask?.cancel()
                    pendingSelectTask = Task {
                        try? await Task.sleep(for: singleTapDelay)
                        guard !Task.isCancelled else { return }
                        await MainActor.run { onSelect?() }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.leading, 16)
        .padding(.trailing, 16)
        .onChange(of: isTextFocused) { _, focused in
            if focused {
                onSelect?()
            }
        }
        .onChange(of: isSelected) { _, selected in
            if !selected {
                isTextFocused = false
            }
        }
        .onChange(of: quotation.content) { _, newValue in
            if !isTextFocused {
                editedContent = newValue
            }
        }
        .onChange(of: editedContent) { _, newValue in
            scheduleDebouncedSave()
        }
        .onKeyPress(.escape) {
            if isTextFocused {
                isTextFocused = false
                return .handled
            }
            return .ignored
        }
        .contextMenu {
            Button("Delete", role: .destructive) {
                showDeleteConfirmation = true
            }
        }
        .confirmationDialog("Delete this quotation?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                onDelete(quotation.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private var textEditor: some View {
        TextField("Quotation", text: $editedContent, axis: .vertical)
            .textFieldStyle(.plain)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: quotationTextMaxWidth)
            .font(quotationFont)
            .lineSpacing(quotationLineSpacing)
            .focused($isTextFocused)
    }

    private func scheduleDebouncedSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: debounceInterval)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                commitEdit()
            }
        }
    }

    private func commitEdit() {
        let trimmed = editedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            quotation.content = trimmed
            quotation.updatedAt = Date()
            onEdit(quotation)
        }
    }
}
