//
//  AppColors.swift
//  Quotations
//

import AppKit
import SwiftUI

enum AppColors {
    /// Warm amber/brown for selection, edit focus, and input highlights.
    /// Shifts more yellow in dark mode so the tan reads well on dark surfaces.
    static let highlightColor = Color(nsColor: NSColor(name: nil) { appearance in
        let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        return isDark
            ? NSColor(red: 0.85, green: 0.68, blue: 0.28, alpha: 1)
            : NSColor(red: 0.72, green: 0.53, blue: 0.20, alpha: 1)
    })

    /// Warm tan fill behind a selected sidebar row.
    static let selectionBackground = highlightColor.opacity(0.25)

    /// Soft tan for the decorative opening-quote glyph.
    static let quoteGlyph = highlightColor.opacity(0.5)

    /// Yellow background for search term matches.
    static let searchHighlight = Color.yellow.opacity(0.4)

    /// Main content column background (lighter tint in light mode).
    static func mainBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.10, blue: 0.07)
            : Color(red: 0.995, green: 0.99, blue: 0.985)
    }

    /// Solid fill behind a quotation while it is being edited.
    static func editingBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .black : .white
    }
}
