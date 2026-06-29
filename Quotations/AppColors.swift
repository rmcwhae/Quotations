//
//  AppColors.swift
//  Quotations
//

import SwiftUI

enum AppColors {
    /// Warm amber/brown for selection, edit focus, and input highlights.
    static let highlightColor = Color(red: 0.72, green: 0.53, blue: 0.20)

    /// Warm tan fill behind a selected sidebar row.
    static let selectionBackground = highlightColor.opacity(0.25)

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
