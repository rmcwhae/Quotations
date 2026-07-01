//
//  MacFormTextField.swift
//  Quotations
//

import AppKit
import SwiftUI

/// NSViewRepresentable wrapping NSTextField to work around a macOS SwiftUI bug
/// where space characters are invisible inside Form { }.formStyle(.grouped).
struct MacFormTextField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var onFocusChange: ((Bool) -> Void)?

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.placeholderString = placeholder
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.delegate = context.coordinator
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        guard nsView.stringValue != text else { return }
        if let editor = nsView.currentEditor() as? NSTextView {
            editor.string = text
        } else {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: MacFormTextField

        init(_ parent: MacFormTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            parent.onFocusChange?(true)
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            parent.onFocusChange?(false)
        }
    }
}
