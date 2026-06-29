//
//  QuotationClickView.swift
//  Quotations
//

import AppKit
import SwiftUI

/// Reports mouse-up to SwiftUI with the click location (in window coordinates) and
/// `NSEvent.clickCount`. When `isEditing` is true, clicks pass through to the text view.
struct QuotationClickView: NSViewRepresentable {
    var isEditing: Bool
    var onClick: (_ windowPoint: CGPoint, _ clickCount: Int) -> Void

    func makeNSView(context: Context) -> QuotationClickNSView {
        let view = QuotationClickNSView()
        configure(view)
        return view
    }

    func updateNSView(_ nsView: QuotationClickNSView, context: Context) {
        configure(nsView)
    }

    private func configure(_ view: QuotationClickNSView) {
        view.isEditing = isEditing
        view.onClick = onClick
    }
}

final class QuotationClickNSView: NSView {
    var isEditing = false
    var onClick: ((CGPoint, Int) -> Void)?

    override var acceptsFirstResponder: Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // While editing, let clicks reach the text view beneath.
        if isEditing { return nil }
        return super.hitTest(point)
    }

    override func mouseUp(with event: NSEvent) {
        // Report the raw window location; the text view converts it into its own
        // (flipped) coordinate space, which avoids manual inset/flip math.
        onClick?(event.locationInWindow, event.clickCount)
    }
}
