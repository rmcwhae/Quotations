//
//  QuotationClickView.swift
//  Quotations
//

import AppKit
import SwiftUI

/// A single mouse-up reported to SwiftUI with the click location (view-local, top-left origin)
/// and window-local location plus timestamp. Multi-click detection is done in durable SwiftUI
/// state by the consumer, so it survives view re-renders. When `isEditing` is true, clicks pass
/// through to the underlying text view.
struct QuotationClickView: NSViewRepresentable {
    var isEditing: Bool
    var onClick: (_ localPoint: CGPoint, _ windowPoint: CGPoint, _ timestamp: TimeInterval) -> Void

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
    var onClick: ((CGPoint, CGPoint, TimeInterval) -> Void)?

    /// Flipped so converted points use a top-left origin, matching SwiftUI coordinates.
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // While editing, let clicks reach the text view beneath.
        if isEditing { return nil }
        return super.hitTest(point)
    }

    override func mouseUp(with event: NSEvent) {
        let windowLocation = event.locationInWindow
        let local = convert(windowLocation, from: nil)
        onClick?(local, windowLocation, event.timestamp)
    }
}
