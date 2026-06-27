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
    /// Where to place the caret when focus is gained (view-local, top-left origin). Nil = leave default.
    var clickLocation: CGPoint? = nil
    /// Select all text when focus is gained.
    var selectAllOnFocus: Bool = false
    var clickInset: CGSize = CGSize(width: 8, height: 6)
    var onFocusChange: (Bool) -> Void

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

        if textView.frame.width != maxWidth {
            textView.frame.size.width = maxWidth
            textView.textContainer?.containerSize = NSSize(width: maxWidth, height: .greatestFiniteMagnitude)
            textView.invalidateIntrinsicContentSize()
        }

        if !context.coordinator.isUpdatingFromView {
            context.coordinator.syncMarkdownIfNeeded(into: textView)
        }

        if isFocused {
            guard let window = textView.window else { return }
            if window.firstResponder !== textView {
                window.makeFirstResponder(textView)
            }
            // Apply the initial selection exactly once per focus session, never on every
            // keystroke (which would re-run "select all" and reduce typing to one letter).
            let needsInitialSelection = selectAllOnFocus || clickLocation != nil
            if needsInitialSelection, !context.coordinator.didApplyInitialSelection {
                context.coordinator.didApplyInitialSelection = true
                let location = clickLocation
                let selectAll = selectAllOnFocus
                let inset = clickInset
                DispatchQueue.main.async { [weak textView] in
                    guard let textView else { return }
                    Coordinator.applySelection(in: textView, clickLocation: location, selectAllOnFocus: selectAll, clickInset: inset)
                }
            }
        } else {
            context.coordinator.didApplyInitialSelection = false
            if textView.window?.firstResponder === textView {
                textView.window?.makeFirstResponder(nil)
            }
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: QuotationRichTextEditor
        var lastMarkdown: String = ""
        var isUpdatingFromView = false
        var didApplyInitialSelection = false

        init(parent: QuotationRichTextEditor) {
            self.parent = parent
            self.lastMarkdown = parent.markdown
        }

        func load(markdown: String, into textView: NSTextView) {
            isUpdatingFromView = true
            let selectedRanges = textView.selectedRanges
            textView.textStorage?.setAttributedString(MarkdownCodec.editorAttributedString(from: markdown))
            textView.typingAttributes = MarkdownCodec.editorTypingAttributes
            textView.selectedRanges = selectedRanges
            lastMarkdown = markdown
            isUpdatingFromView = false
            textView.invalidateIntrinsicContentSize()
        }

        func syncMarkdownIfNeeded(into textView: NSTextView) {
            guard parent.markdown != lastMarkdown else { return }
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
            clickLocation: CGPoint?,
            selectAllOnFocus: Bool,
            clickInset: CGSize
        ) {
            guard selectAllOnFocus || clickLocation != nil else { return }
            if let textContainer = textView.textContainer {
                textView.layoutManager?.ensureLayout(for: textContainer)
            }
            if selectAllOnFocus {
                let length = (textView.string as NSString).length
                textView.setSelectedRange(NSRange(location: 0, length: length))
            } else if let point = clickLocation {
                let x = point.x - clickInset.width
                // SwiftUI uses a top-left origin; NSTextView uses bottom-left.
                let y = textView.bounds.height - (point.y - clickInset.height)
                let index = textView.characterIndexForInsertion(at: NSPoint(x: x, y: y))
                textView.setSelectedRange(NSRange(location: index, length: 0))
            }
        }
    }
}

/// NSTextView that reports its laid-out height for inline SwiftUI sizing.
final class QuotationTextView: NSTextView {
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

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if isEditable, window?.firstResponder === self,
           event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
           let characters = event.charactersIgnoringModifiers?.lowercased() {
            switch characters {
            case "b":
                toggleFontTrait(.boldFontMask)
                return true
            case "i":
                toggleFontTrait(.italicFontMask)
                return true
            default:
                break
            }
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
