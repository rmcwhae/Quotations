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
    var onSelect: (() -> Void)? = nil
    var onEdit: (Quotation) -> Void
    var onDelete: (PersistentIdentifier) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var editedContent: String
    @State private var showDeleteConfirmation = false
    @State private var textContainerWidth: CGFloat = quotationTextMaxWidth
    @State private var isHovering = false
    @State private var pendingClickLocation: CGPoint?
    @State private var selectAllOnFocus = false
    @State private var pendingSelectTask: Task<Void, Never>?

    init(quotation: Quotation, searchQuery: String, isSelected: Bool = false, beginEditing: Bool = false, onSelect: (() -> Void)? = nil, onEdit: @escaping (Quotation) -> Void, onDelete: @escaping (PersistentIdentifier) -> Void) {
        self.quotation = quotation
        self.searchQuery = searchQuery
        self.isSelected = isSelected
        self.beginEditing = beginEditing
        self.onSelect = onSelect
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
            .overlay {
                QuotationClickView(isEditing: isTextFocused, onClick: handleClick)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.leading, 28)
        .padding(.trailing, 16)
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
                selectAllOnFocus = false
                pendingClickLocation = nil
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
        ZStack(alignment: .topLeading) {
            QuotationRichTextEditor(
                markdown: $editedContent,
                maxWidth: textFieldWidth,
                isFocused: isTextFocused,
                clickLocation: pendingClickLocation,
                selectAllOnFocus: selectAllOnFocus,
                clickInset: textContainerPadding,
                onFocusChange: { isTextFocused = $0 }
            )
            .opacity(isTextFocused ? 1 : 0)
            .allowsHitTesting(isTextFocused)
            .frame(maxWidth: textFieldWidth, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)

            if !isTextFocused {
                if showsHighlightedText {
                    HighlightMatch(text: editedContent, query: searchQuery, useMarkdown: true)
                        .frame(maxWidth: textFieldWidth, alignment: .leading)
                } else {
                    FormattedQuotationText(text: editedContent)
                        .frame(maxWidth: textFieldWidth, alignment: .leading)
                }
            }
        }
    }

    /// Uses `NSEvent.clickCount` so double-clicks stay intact across the re-render from
    /// selecting a previously unselected quotation. Single-click select is deferred so the
    /// first click of a double-click does not enter a transient selected state.
    private func handleClick(localPoint: CGPoint, clickCount: Int) {
        switch clickCount {
        case 1:
            pendingSelectTask?.cancel()
            pendingSelectTask = Task {
                let delay = Duration.milliseconds(Int(NSEvent.doubleClickInterval * 1000))
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    if !isSelected, !isTextFocused {
                        onSelect?()
                    }
                }
            }
        case 2:
            pendingSelectTask?.cancel()
            if !isSelected { onSelect?() }
            pendingClickLocation = localPoint
            selectAllOnFocus = false
            isTextFocused = true
        default:
            pendingSelectTask?.cancel()
            if !isSelected { onSelect?() }
            pendingClickLocation = nil
            selectAllOnFocus = true
            isTextFocused = true
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
