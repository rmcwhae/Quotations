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
private let textContainerPadding = CGSize(width: 8, height: 6)

struct QuotationRowView: View {
    let quotation: Quotation
    let searchQuery: String
    var isSelected: Bool = false
    /// When true, the row enters edit mode on appear (used for a freshly added quotation).
    var beginEditing: Bool = false
    var newQuotationId: PersistentIdentifier? = nil
    var onSelect: (() -> Void)? = nil
    var onDeselect: (() -> Void)? = nil
    var onEdit: (Quotation) -> Void
    var onDelete: (PersistentIdentifier) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var editedContent: String
    @State private var showDeleteConfirmation = false
    @State private var textContainerWidth: CGFloat = quotationTextMaxWidth
    @State private var isHovering = false
    @State private var pendingClickWindowLocation: CGPoint?
    @State private var selectAllOnFocus = false
    /// Bumped on each click that begins editing so the editor re-applies the
    /// requested caret/selection even when focus is already active (e.g. a
    /// triple-click arriving right after the double-click that started editing).
    @State private var selectionRequestID = 0

    init(quotation: Quotation, searchQuery: String, isSelected: Bool = false, beginEditing: Bool = false, newQuotationId: PersistentIdentifier? = nil, onSelect: (() -> Void)? = nil, onDeselect: (() -> Void)? = nil, onEdit: @escaping (Quotation) -> Void, onDelete: @escaping (PersistentIdentifier) -> Void) {
        self.quotation = quotation
        self.searchQuery = searchQuery
        self.isSelected = isSelected
        self.beginEditing = beginEditing
        self.newQuotationId = newQuotationId
        self.onSelect = onSelect
        self.onDeselect = onDeselect
        self.onEdit = onEdit
        self.onDelete = onDelete
        _editedContent = State(initialValue: quotation.content)
    }
    @State private var saveTask: Task<Void, Never>?
    @State private var isTextFocused = false
    @State private var didBeginEditing = false

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

    private var isNewDraft: Bool {
        newQuotationId == quotation.id
    }

    private var accessibilitySummary: String {
        if quotation.content.isEmpty { return "New quotation" }
        let trimmed = quotation.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 120 { return trimmed }
        return String(trimmed.prefix(120)) + "…"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("\u{201C}")
                .font(.system(size: 44, design: .serif))
                .foregroundStyle(AppColors.quoteGlyph)
                .frame(width: 36, alignment: .leading)
                .offset(y: -2)
                .accessibilityHidden(true)
                .contentShape(Rectangle())
                .onTapGesture { onDeselect?() }
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
            .overlay {
                QuotationClickView(isEditing: isTextFocused, onClick: handleClick)
            }
            Spacer(minLength: 0)
                .contentShape(Rectangle())
                .onTapGesture { onDeselect?() }
        }
        .padding(.vertical, 10)
        .padding(.leading, 28)
        .padding(.trailing, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isTextFocused ? "Editing quotation" : "Double-click to edit")
        .onAppear {
            if beginEditing, !didBeginEditing {
                didBeginEditing = true
                isTextFocused = true
            }
        }
        .onChange(of: isTextFocused) { _, focused in
            if focused, !isSelected {
                onSelect?()
            }
            if !focused {
                saveTask?.cancel()
                commitEdit()
                selectAllOnFocus = false
                pendingClickWindowLocation = nil
            }
        }
        .onDisappear {
            saveTask?.cancel()
            commitEdit()
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
        .confirmationDialog("Remove quotation?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                onDelete(quotation.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This quotation will be removed from your library.")
        }
    }

    @ViewBuilder
    private var textEditor: some View {
        if isTextFocused {
            QuotationRichTextEditor(
                markdown: $editedContent,
                maxWidth: textFieldWidth,
                isFocused: isTextFocused,
                clickWindowLocation: pendingClickWindowLocation,
                selectAllOnFocus: selectAllOnFocus,
                selectionRequestID: selectionRequestID,
                onFocusChange: { isTextFocused = $0 },
                onEscape: {
                    isTextFocused = false
                }
            )
            .frame(maxWidth: textFieldWidth, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        } else {
            Group {
                if showsHighlightedText {
                    HighlightMatch(text: editedContent, query: searchQuery, useMarkdown: true)
                } else {
                    FormattedQuotationText(text: editedContent)
                }
            }
            .frame(maxWidth: textFieldWidth, alignment: .leading)
        }
    }

    /// Uses `NSEvent.clickCount` so double-clicks stay intact across the re-render from
    /// selecting a previously unselected quotation. Single-click select is immediate.
    private func handleClick(windowPoint: CGPoint, clickCount: Int) {
        switch clickCount {
        case 1:
            // Always select on single click.
            if !isSelected {
                onSelect?()
            }
        case 2:
            // Begin editing with the caret at the click point.
            beginEditing(windowPoint: windowPoint, selectAll: false)
        default:
            // Begin editing with all text selected (triple+ click).
            beginEditing(windowPoint: nil, selectAll: true)
        }
    }

    private func beginEditing(windowPoint: CGPoint?, selectAll: Bool) {
        if !isSelected {
            onSelect?()
        }
        pendingClickWindowLocation = windowPoint
        selectAllOnFocus = selectAll
        selectionRequestID &+= 1
        isTextFocused = true
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
        if trimmed.isEmpty {
            if isNewDraft {
                onDelete(quotation.id)
            } else {
                quotation.content = ""
                quotation.updatedAt = Date()
                onEdit(quotation)
            }
        } else {
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
