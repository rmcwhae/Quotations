//
//  QuotationRowView+Editing.swift
//  Quotations
//

import AppKit
import SwiftData
import SwiftUI

private let quotationEditDebounceInterval: Duration = .milliseconds(500)

extension QuotationRowView {
    /// Uses `NSEvent.clickCount` so double-clicks stay intact across the re-render from
    /// selecting a previously unselected quotation. Single-click select is immediate.
    func handleClick(windowPoint: CGPoint, clickCount: Int) {
        switch clickCount {
        case 1:
            // Always select on single click.
            if !isSelected {
                onSelect?()
            }
        case 2:
            // Begin editing with the caret at the click point.
            beginTextEditing(windowPoint: windowPoint, selectAll: false)
        default:
            // Begin editing with all text selected (triple+ click).
            beginTextEditing(windowPoint: nil, selectAll: true)
        }
    }

    func beginTextEditing(windowPoint: CGPoint?, selectAll: Bool) {
        if !isSelected {
            onSelect?()
        }
        pendingClickWindowLocation = windowPoint
        selectAllOnFocus = selectAll
        selectionRequestID &+= 1
        isTextFocused = true
    }

    func scheduleDebouncedSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: quotationEditDebounceInterval)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                commitEdit(isFinal: false)
            }
        }
    }

    func scheduleLocationSave() {
        locationSaveTask?.cancel()
        locationSaveTask = Task {
            try? await Task.sleep(for: quotationEditDebounceInterval)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                commitLocationAfterFieldFlush()
            }
        }
    }

    /// Resigns the location field when needed, then commits after SwiftUI flushes the binding.
    func persistLocationField() {
        locationSaveTask?.cancel()
        if isLocationFocused {
            isLocationFocused = false
        } else {
            commitLocationAfterFieldFlush()
        }
    }

    func commitLocationAfterFieldFlush() {
        DispatchQueue.main.async {
            commitLocation()
        }
    }

    func handleTextFocusChange(_ focused: Bool) {
        if focused, !isSelected {
            onSelect?()
        }
        if focused, isLocationFocused {
            // Text edit stole focus — resign location; focus handler commits after flush.
            isLocationFocused = false
        }
        if !focused {
            saveTask?.cancel()
            commitEdit()
            selectAllOnFocus = false
            pendingClickWindowLocation = nil
            focusRowIfSelected()
        }
    }

    func handleLocationFocusChange(_ focused: Bool) {
        if focused {
            if !isSelected { onSelect?() }
            isTextFocused = false
        } else {
            commitLocationAfterFieldFlush()
            if !isTextFocused {
                focusRowIfSelected()
            }
        }
    }

    /// Gives keyboard focus back to the selected row after editing ends, so Delete and the
    /// arrow keys keep working. Deferred one turn: the row only becomes `.focusable` once
    /// `isEditing` is false, and a focus request in the same update is dropped.
    func focusRowIfSelected() {
        DispatchQueue.main.async {
            if isSelected, !isEditing {
                isRowFocused = true
            }
        }
    }

    func handleSelectionChange(_ selected: Bool) {
        if selected {
            if !isEditing {
                isRowFocused = true
            }
        } else {
            persistLocationField()
            isTextFocused = false
            isRowFocused = false
        }
    }

    func handleEscapeKey() -> KeyPress.Result {
        if isTextFocused {
            isTextFocused = false
            return .handled
        }
        if isLocationFocused {
            isLocationFocused = false
            return .handled
        }
        if isSelected {
            onDeselect?()
            return .handled
        }
        return .ignored
    }

    /// Writes the edited text to the model. Intermediate (debounced) commits only save the
    /// store; the final commit when editing ends also notifies widget and search indexing.
    func commitEdit(isFinal: Bool = true) {
        let trimmed = editedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            guard isFinal else { return }
            if isNewDraft {
                onDelete(quotation.id)
                return
            }
            // Emptying the text never wipes a quotation; use Delete to remove it.
            editedContent = quotation.content
        } else if trimmed != quotation.content {
            quotation.content = trimmed
            quotation.updatedAt = Date()
            hasUnpublishedEdit = true
        }
        guard hasUnpublishedEdit else { return }
        if isFinal {
            hasUnpublishedEdit = false
            onEdit(quotation)
        } else {
            // Crash safety only; a failure here is reported by the final commit.
            try? quotation.modelContext?.save()
        }
    }

    func commitLocation() {
        guard quotation.applyLocationInput(editedLocation) else { return }
        onEdit(quotation)
    }

    func copyQuotation() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(quotation.content, forType: .string)
    }
}
