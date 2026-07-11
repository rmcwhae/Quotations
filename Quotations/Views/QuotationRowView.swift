//
//  QuotationRowView.swift
//  Quotations
//

import AppKit
import SwiftData
import SwiftUI

enum QuotationRowLayout {
    static let textMaxWidth: CGFloat = 520
    static let textContainerPadding = CGSize(width: 8, height: 6)
}

struct QuotationRowView: View {
    let quotation: Quotation
    let findQuery: String
    var isSelected: Bool = false
    /// When true, the row enters edit mode on appear (used for a freshly added quotation).
    var beginEditing: Bool = false
    var newQuotationId: PersistentIdentifier? = nil
    var onSelect: (() -> Void)? = nil
    var onDeselect: (() -> Void)? = nil
    var onEdit: (Quotation) -> Void
    var onDelete: (PersistentIdentifier) -> Void

    @Environment(\.colorScheme) var colorScheme
    @State var editedContent: String
    @State var editedLocation: String
    @State var showDeleteConfirmation = false
    @State var textContainerWidth: CGFloat = QuotationRowLayout.textMaxWidth
    @State var isHovering = false
    @State var pendingClickWindowLocation: CGPoint?
    @State var selectAllOnFocus = false
    /// Bumped on each click that begins editing so the editor re-applies the
    /// requested caret/selection even when focus is already active (e.g. a
    /// triple-click arriving right after the double-click that started editing).
    @State var selectionRequestID = 0
    @State var saveTask: Task<Void, Never>?
    @State var locationSaveTask: Task<Void, Never>?
    @State var isTextFocused = false
    @FocusState var isLocationFocused: Bool
    @FocusState var isRowFocused: Bool
    @State var didBeginEditing = false

    init(
        quotation: Quotation,
        findQuery: String,
        isSelected: Bool = false,
        beginEditing: Bool = false,
        newQuotationId: PersistentIdentifier? = nil,
        onSelect: (() -> Void)? = nil,
        onDeselect: (() -> Void)? = nil,
        onEdit: @escaping (Quotation) -> Void,
        onDelete: @escaping (PersistentIdentifier) -> Void
    ) {
        self.quotation = quotation
        self.findQuery = findQuery
        self.isSelected = isSelected
        self.beginEditing = beginEditing
        self.newQuotationId = newQuotationId
        self.onSelect = onSelect
        self.onDeselect = onDeselect
        self.onEdit = onEdit
        self.onDelete = onDelete
        _editedContent = State(initialValue: quotation.content)
        _editedLocation = State(initialValue: quotation.location ?? "")
    }

    var isEditing: Bool {
        isTextFocused || isLocationFocused
    }

    var textFieldWidth: CGFloat {
        min(textContainerWidth, QuotationRowLayout.textMaxWidth)
    }

    var isNewDraft: Bool {
        newQuotationId == quotation.id
    }

    var body: some View {
        quotationRowBody
    }
}
