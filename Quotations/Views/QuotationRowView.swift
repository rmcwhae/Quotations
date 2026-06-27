//
//  QuotationRowView.swift
//  Quotations
//

import AppKit
import SwiftData
import SwiftUI

/// Max width for quotation text and its edit/selection outline.
private let quotationTextMaxWidth: CGFloat = 520
private let debounceInterval: Duration = .milliseconds(500)
private let singleTapDelay: Duration = .milliseconds(250)
private let textContainerPadding = CGSize(width: 8, height: 6)

struct QuotationRowView: View {
    let quotation: Quotation
    let searchQuery: String
    var isSelected: Bool = false
    var onSelect: (() -> Void)? = nil
    var onEdit: (Quotation) -> Void
    var onDelete: (PersistentIdentifier) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var editedContent: String
    @State private var showDeleteConfirmation = false
    @State private var textContainerWidth: CGFloat = quotationTextMaxWidth
    @State private var isHovering = false
    @State private var pendingClickLocation: CGPoint?

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
    @State private var isTextFocused = false

    private var textFieldWidth: CGFloat {
        min(textContainerWidth, quotationTextMaxWidth)
    }

    private var isSearchActive: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var showsHighlightedText: Bool {
        isSearchActive && !isTextFocused
    }

    private var borderColor: Color {
        if isTextFocused { return AppColors.highlightColor }
        if isSelected { return AppColors.highlightColor.opacity(0.55) }
        if isHovering { return AppColors.highlightColor.opacity(0.55) }
        return .clear
    }

    private var borderWidth: CGFloat {
        if isTextFocused { return 3 }
        if isSelected { return 3 }
        if isHovering { return 2 }
        return 0
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("\u{201C}")
                .font(.system(size: 44, design: .serif))
                .foregroundStyle(.quaternary)
                .frame(width: 36, alignment: .leading)
                .offset(y: -2)
            VStack(alignment: .leading, spacing: 4) {
                textEditor
            }
            .frame(maxWidth: quotationTextMaxWidth, alignment: .leading)
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: geometry.size.width, initial: true) { _, newWidth in
                            textContainerWidth = newWidth
                        }
                }
            }
            .padding(.horizontal, textContainerPadding.width)
            .padding(.vertical, textContainerPadding.height)
            .background(
                isTextFocused
                    ? AppColors.editingBackground(colorScheme: colorScheme)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            }
            .contentShape(Rectangle())
            .onHover { isHovering = $0 }
            .gesture(
                SpatialTapGesture(count: 2).onEnded { value in
                    pendingSelectTask?.cancel()
                    pendingSelectTask = nil
                    pendingClickLocation = value.location
                    isTextFocused = true
                }
            )
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
            Button("Copy") {
                copyQuotation()
            }
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

    @ViewBuilder
    private var textEditor: some View {
        if isTextFocused {
            QuotationRichTextEditor(
                markdown: $editedContent,
                maxWidth: textFieldWidth,
                isFocused: isTextFocused,
                clickLocation: $pendingClickLocation,
                clickInset: textContainerPadding,
                onFocusChange: { isTextFocused = $0 }
            )
            .frame(maxWidth: textFieldWidth, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        } else if showsHighlightedText {
            HighlightMatch(text: editedContent, query: searchQuery, useMarkdown: true)
                .frame(maxWidth: textFieldWidth, alignment: .leading)
        } else {
            FormattedQuotationText(text: editedContent)
                .frame(maxWidth: textFieldWidth, alignment: .leading)
        }
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

    private func copyQuotation() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(quotation.content, forType: .string)
    }
}
