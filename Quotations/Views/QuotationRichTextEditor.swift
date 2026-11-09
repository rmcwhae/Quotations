//
//  QuotationRichTextEditor.swift
//  Quotations
//

import AppKit
import SwiftUI

/// Inline WYSIWYG editor backed by NSTextView. Reads and writes markdown via `MarkdownCodec`.
struct QuotationRichTextEditor: NSViewRepresentable {
    @Binding var markdown: String
    var maxWidth: CGFloat
    var isFocused: Bool
    /// Where to place the caret when focus is gained (in window coordinates). Nil = leave default.
    var clickWindowLocation: CGPoint? = nil
    /// Select all text when focus is gained.
    var selectAllOnFocus: Bool = false
    /// Identifies a distinct selection request. The editor applies the requested
    /// caret/selection once per id, so a new click re-applies even while focused.
    var selectionRequestID: Int = 0
    var onFocusChange: (Bool) -> Void
    var onEscape: (() -> Void)? = nil
    var onCommit: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> QuotationTextView {
        let textView = QuotationTextView()
        textView.isRichText = true
        textView.importsGraphics = false
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.isEditable = true
        textView.isSelectable = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: maxWidth, height: .greatestFiniteMagnitude)
        textView.maxSize = NSSize(width: maxWidth, height: .greatestFiniteMagnitude)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.allowsUndo = true
        textView.focusRingType = .none
        textView.font = MarkdownCodec.quotationBaseFont
        textView.textColor = .textColor
        textView.defaultParagraphStyle = MarkdownCodec.quotationParagraphStyle
        textView.typingAttributes = MarkdownCodec.editorTypingAttributes
        textView.delegate = context.coordinator

        context.coordinator.load(markdown: markdown, into: textView)

        return textView
    }

    func updateNSView(_ textView: QuotationTextView, context: Context) {
        context.coordinator.parent = self
        textView.onEscape = onEscape
        textView.onCommit = onCommit

        if textView.frame.width != maxWidth {
            textView.frame.size.width = maxWidth
            textView.textContainer?.containerSize = NSSize(width: maxWidth, height: .greatestFiniteMagnitude)
            textView.invalidateIntrinsicContentSize()
        }

        if !context.coordinator.isUpdatingFromView {
            context.coordinator.syncMarkdownIfNeeded(into: textView)
        }

        if isFocused {
            // Apply each selection request exactly once (keyed by id), never on every
            // keystroke (which would re-run "select all" and reduce typing to one letter).
            // Keying on the id lets a triple-click re-apply select-all even though the
            // preceding double-click already focused the view.
            var pendingSelection: (() -> Void)?
            let needsSelection = selectAllOnFocus || clickWindowLocation != nil
            if needsSelection, context.coordinator.lastAppliedSelectionID != selectionRequestID {
                context.coordinator.lastAppliedSelectionID = selectionRequestID
                let windowPoint = clickWindowLocation
                let selectAll = selectAllOnFocus
                pendingSelection = { [weak textView] in
                    guard let textView else { return }
                    Coordinator.applySelection(
                        in: textView,
                        clickWindowLocation: windowPoint,
                        selectAllOnFocus: selectAll
                    )
                }
            }

            guard let window = textView.window else {
                // A freshly created editor isn't in a window yet. Without this retry the focus
                // request is dropped, keys go to the window, and Delete opens "Remove quotation?".
                textView.focusWhenAttached = true
                if let pendingSelection { textView.selectionWhenAttached = pendingSelection }
                return
            }
            if window.firstResponder !== textView {
                window.makeFirstResponder(textView)
            }
            if let pendingSelection {
                DispatchQueue.main.async(execute: pendingSelection)
            }
        } else {
            context.coordinator.lastAppliedSelectionID = selectionRequestID
            if let window = textView.window, window.firstResponder === textView {
                // Hand focus back to the SwiftUI content (not nil): with no first responder,
                // SwiftUI can't focus the selected row, so Delete and arrow keys stop working.
                window.makeFirstResponder(window.contentView)
            }
            // Collapse any lingering selection (e.g. a previous select-all) so it
            // doesn't briefly flash highlighted when this editor regains focus.
            if textView.selectedRange().length > 0 {
                textView.setSelectedRange(NSRange(location: 0, length: 0))
            }
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: QuotationRichTextEditor
        var lastMarkdown: String = ""
        var isUpdatingFromView = false
        var lastAppliedSelectionID = 0
        /// Owned by the editor so Cmd-Z keeps working inside SwiftUI hosting.
        let textUndoManager = UndoManager()

        init(parent: QuotationRichTextEditor) {
            self.parent = parent
            self.lastMarkdown = parent.markdown
        }

        func undoManager(for view: NSTextView) -> UndoManager? {
            textUndoManager
        }

        func load(markdown: String, into textView: NSTextView) {
            isUpdatingFromView = true
            let selectedRanges = textView.selectedRanges
            textView.textStorage?.setAttributedString(MarkdownCodec.editorAttributedString(from: markdown))
            textView.typingAttributes = MarkdownCodec.editorTypingAttributes
            textView.selectedRanges = selectedRanges
            lastMarkdown = markdown
            // Programmatic replacement is not an undoable user edit.
            textUndoManager.removeAllActions()
            isUpdatingFromView = false
            textView.invalidateIntrinsicContentSize()
        }

        func syncMarkdownIfNeeded(into textView: NSTextView) {
            guard parent.markdown != lastMarkdown else { return }
            // Reloading attributed text clears the undo stack — never do it mid-edit.
            if textView.window?.firstResponder === textView {
                return
            }
            load(markdown: parent.markdown, into: textView)
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            guard !isUpdatingFromView else { return }

            isUpdatingFromView = true
            let serialized = MarkdownCodec.markdown(from: textView.attributedString())
            if serialized != lastMarkdown {
                lastMarkdown = serialized
                parent.markdown = serialized
            }
            isUpdatingFromView = false
            textView.invalidateIntrinsicContentSize()
        }

        func textDidBeginEditing(_ notification: Notification) {
            parent.onFocusChange(true)
        }

        func textDidEndEditing(_ notification: Notification) {
            parent.onFocusChange(false)
        }

        static func applySelection(
            in textView: NSTextView,
            clickWindowLocation: CGPoint?,
            selectAllOnFocus: Bool
        ) {
            guard selectAllOnFocus || clickWindowLocation != nil else { return }
            if let textContainer = textView.textContainer {
                textView.layoutManager?.ensureLayout(for: textContainer)
            }
            if selectAllOnFocus {
                let length = (textView.string as NSString).length
                textView.setSelectedRange(NSRange(location: 0, length: length))
            } else if let windowPoint = clickWindowLocation {
                // Convert through the text view's own (flipped) coordinate space so the
                // caret lands on the correct line and character without manual flip math.
                let local = textView.convert(windowPoint, from: nil)
                let index = textView.characterIndexForInsertion(at: local)
                textView.setSelectedRange(NSRange(location: index, length: 0))
            }
        }
    }
}

/// NSTextView that reports its laid-out height for inline SwiftUI sizing.
final class QuotationTextView: NSTextView {
    var onEscape: (() -> Void)?
    var onCommit: (() -> Void)?
    /// Set when SwiftUI asked for focus (and a caret position) before the view had a window.
    var focusWhenAttached = false
    var selectionWhenAttached: (() -> Void)?

    /// While editing, watches for clicks anywhere else in the window and ends editing
    /// exactly like Escape. The click still goes through (e.g. selecting another row).
    private var outsideClickMonitor: Any?

    override func becomeFirstResponder() -> Bool {
        let accepted = super.becomeFirstResponder()
        if accepted { installOutsideClickMonitor() }
        return accepted
    }

    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        if resigned { removeOutsideClickMonitor() }
        return resigned
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        if newWindow == nil { removeOutsideClickMonitor() }
    }

    private func installOutsideClickMonitor() {
        guard outsideClickMonitor == nil else { return }
        outsideClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, event.window === self.window else { return event }
            // Count the padded editing box around the text as "inside".
            let point = self.convert(event.locationInWindow, from: nil)
            if !self.bounds.insetBy(dx: -12, dy: -10).contains(point) {
                DispatchQueue.main.async { [weak self] in self?.onEscape?() }
            }
            return event
        }
    }

    private func removeOutsideClickMonitor() {
        if let outsideClickMonitor { NSEvent.removeMonitor(outsideClickMonitor) }
        outsideClickMonitor = nil
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard focusWhenAttached, let window else { return }
        focusWhenAttached = false
        window.makeFirstResponder(self)
        if let selection = selectionWhenAttached {
            selectionWhenAttached = nil
            DispatchQueue.main.async(execute: selection)
        }
    }

    override func cancelOperation(_ sender: Any?) {
        if let onEscape {
            onEscape()
        } else {
            super.cancelOperation(sender)
        }
    }

    override var intrinsicContentSize: NSSize {
        guard let layoutManager, let textContainer else {
            return super.intrinsicContentSize
        }
        layoutManager.ensureLayout(for: textContainer)
        let used = layoutManager.usedRect(for: textContainer)
        return NSSize(width: NSView.noIntrinsicMetric, height: used.height + textContainerInset.height * 2)
    }

    override func didChangeText() {
        super.didChangeText()
        invalidateIntrinsicContentSize()
    }

    override func mouseUp(with event: NSEvent) {
        if event.clickCount == 3, isEditable {
            let length = (string as NSString).length
            setSelectedRange(NSRange(location: 0, length: length))
            return
        }
        super.mouseUp(with: event)
    }

    /// Pastes content normalized to the quotation serif font, preserving bold/italic only.
    override func paste(_ sender: Any?) {
        let pasteboard = NSPasteboard.general
        let normalized: NSAttributedString

        if let rtf = pasteboard.data(forType: .rtf),
           let attributed = NSAttributedString(rtf: rtf, documentAttributes: nil) {
            normalized = MarkdownCodec.normalizedForEditor(attributed)
        } else if let plain = pasteboard.string(forType: .string) {
            normalized = NSAttributedString(string: plain, attributes: MarkdownCodec.editorTypingAttributes)
        } else {
            super.paste(sender)
            return
        }

        let range = selectedRange()
        guard shouldChangeText(in: range, replacementString: normalized.string) else { return }
        textStorage?.replaceCharacters(in: range, with: normalized)
        typingAttributes = MarkdownCodec.editorTypingAttributes
        didChangeText()
    }

    override func keyDown(with event: NSEvent) {
        // Escape ends editing here (NSTextView would otherwise run completion, and the key
        // falls through to the window, which clears the quotation selection).
        if event.keyCode == 53, !hasMarkedText(), let onEscape {
            onEscape()
            return
        }
        // Let Return confirm an input-method composition (e.g. Japanese, Chinese) first.
        if isEditable,
           window?.firstResponder === self,
           !hasMarkedText(),
           event.keyCode == 36 || event.keyCode == 76 {
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags.contains(.shift) {
                super.keyDown(with: event)
            } else if let onCommit {
                onCommit()
            } else {
                super.keyDown(with: event)
            }
            return
        }
        super.keyDown(with: event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard isEditable, window?.firstResponder === self,
              let characters = event.charactersIgnoringModifiers?.lowercased() else {
            return super.performKeyEquivalent(with: event)
        }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        switch characters {
        case "z" where flags == .command:
            if let undoManager, undoManager.canUndo {
                undoManager.undo()
                return true
            }
        case "z" where flags == [.command, .shift]:
            if let undoManager, undoManager.canRedo {
                undoManager.redo()
                return true
            }
        case "b" where flags == .command:
            toggleFontTrait(.boldFontMask)
            return true
        case "i" where flags == .command:
            toggleFontTrait(.italicFontMask)
            return true
        default:
            break
        }
        return super.performKeyEquivalent(with: event)
    }

    /// Toggles bold or italic on the current selection (or future typing if nothing is selected).
    private func toggleFontTrait(_ trait: NSFontTraitMask) {
        let manager = NSFontManager.shared
        let symbolic: NSFontDescriptor.SymbolicTraits = trait == .boldFontMask ? .bold : .italic
        let range = selectedRange()

        func adjusted(_ font: NSFont, removing: Bool) -> NSFont {
            removing
                ? manager.convert(font, toNotHaveTrait: trait)
                : manager.convert(font, toHaveTrait: trait)
        }

        if range.length == 0 {
            let current = (typingAttributes[.font] as? NSFont) ?? MarkdownCodec.quotationBaseFont
            let removing = current.fontDescriptor.symbolicTraits.contains(symbolic)
            var attributes = typingAttributes
            attributes[.font] = adjusted(current, removing: removing)
            typingAttributes = attributes
            return
        }

        guard let textStorage, shouldChangeText(in: range, replacementString: nil) else { return }

        let startFont = (textStorage.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont)
            ?? MarkdownCodec.quotationBaseFont
        let removing = startFont.fontDescriptor.symbolicTraits.contains(symbolic)

        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
            let current = (value as? NSFont) ?? MarkdownCodec.quotationBaseFont
            textStorage.addAttribute(.font, value: adjusted(current, removing: removing), range: subRange)
        }
        textStorage.endEditing()
        didChangeText()
    }
}
