//
//  ToolbarFindFocus.swift
//  Quotations
//

import AppKit

enum ToolbarFindFocus {
    private static let searchItemIdentifier = "com.apple.SwiftUI.search"

    /// Focuses the SwiftUI toolbar search field created by `.searchable(placement: .toolbar)`.
    @MainActor
    static func activate() {
        guard let toolbar = NSApp.keyWindow?.toolbar else { return }
        guard let searchItem = toolbar.items.first(where: { $0.itemIdentifier.rawValue == searchItemIdentifier }),
              let searchToolbarItem = searchItem as? NSSearchToolbarItem else {
            return
        }
        searchToolbarItem.beginSearchInteraction()
    }
}
