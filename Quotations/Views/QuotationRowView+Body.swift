//
//  QuotationRowView+Body.swift
//  Quotations
//

import SwiftData
import SwiftUI

extension QuotationRowView {
    private var isFindActive: Bool {
        !findQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var showsHighlightedText: Bool {
        isFindActive && !isTextFocused
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

    private var accessibilitySummary: String {
        let contentSummary: String
        if quotation.content.isEmpty {
            contentSummary = "New quotation"
        } else {
            let trimmed = quotation.content.trimmingCharacters(in: .whitespacesAndNewlines)
            contentSummary = trimmed.count <= 120 ? trimmed : String(trimmed.prefix(120)) + "…"
        }
        let location = quotation.location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !location.isEmpty else { return contentSummary }
        return "\(contentSummary), location \(location)"
    }

    var quotationRowBody: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("\u{201C}")
                .font(.system(size: 44, design: .serif))
                .foregroundStyle(AppColors.quoteGlyph)
                .frame(width: 36, alignment: .leading)
                .offset(y: -2)
                .accessibilityHidden(true)
                .contentShape(Rectangle())
                .onTapGesture { onDeselect?() }
            VStack(alignment: .leading, spacing: 2) {
                textEditor
                    .frame(maxWidth: QuotationRowLayout.textMaxWidth, alignment: .leading)
                    .background {
                        GeometryReader { geometry in
                            Color.clear
                                .onChange(of: geometry.size.width, initial: true) { _, newWidth in
                                    textContainerWidth = newWidth
                                }
                        }
                    }
                    .padding(.horizontal, QuotationRowLayout.textContainerPadding.width)
                    .padding(.vertical, QuotationRowLayout.textContainerPadding.height)
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
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(accessibilitySummary)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                    .accessibilityHint(
                        isTextFocused
                            ? "Return to save, Shift-Return for new line"
                            : "Double-click to edit"
                    )

                QuotationLocationField(
                    text: $editedLocation,
                    isSelected: isSelected,
                    textFieldWidth: textFieldWidth,
                    horizontalInset: QuotationRowLayout.textContainerPadding.width - 6,
                    isFocused: $isLocationFocused
                )
            }
            Spacer(minLength: 0)
                .contentShape(Rectangle())
                .onTapGesture { onDeselect?() }
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
            handleTextFocusChange(focused)
        }
        .onChange(of: isLocationFocused) { _, focused in
            handleLocationFocusChange(focused)
        }
        .onDisappear {
            saveTask?.cancel()
            locationSaveTask?.cancel()
            commitEdit()
            commitLocation()
        }
        .onChange(of: isSelected) { _, selected in
            handleSelectionChange(selected)
        }
        .onChange(of: quotation.content) { _, newValue in
            if !isTextFocused {
                editedContent = newValue
            }
        }
        .onChange(of: quotation.location) { _, newValue in
            if !isLocationFocused {
                editedLocation = newValue ?? ""
            }
        }
        .onChange(of: editedContent) { _, _ in
            scheduleDebouncedSave()
        }
        .onChange(of: editedLocation) { _, _ in
            scheduleLocationSave()
        }
        .focusable(isSelected && !isEditing)
        .focused($isRowFocused)
        .focusEffectDisabled()
        .onKeyPress(.escape) {
            handleEscapeKey()
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
    var textEditor: some View {
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
                },
                onCommit: {
                    saveTask?.cancel()
                    commitEdit()
                    isTextFocused = false
                }
            )
            .frame(maxWidth: textFieldWidth, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        } else {
            Group {
                if showsHighlightedText {
                    HighlightMatch(text: editedContent, query: findQuery, useMarkdown: true)
                } else {
                    FormattedQuotationText(text: editedContent)
                }
            }
            .frame(maxWidth: textFieldWidth, alignment: .leading)
        }
    }
}
