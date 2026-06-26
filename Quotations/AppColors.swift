//
//  AppColors.swift
//  Quotations
//

import SwiftUI

enum AppColors {
    /// Warm amber/brown for selection, edit focus, and input highlights.
    static let highlightColor = Color(red: 0.72, green: 0.53, blue: 0.20)

    /// Subtle background tint for selected list rows.
    static let selectionBackground = highlightColor.opacity(0.2)

    /// Yellow background for search term matches.
    static let searchHighlight = Color.yellow.opacity(0.4)

    /// Brown/tan for diamond dividers between quotations.
    static let dividerColor = highlightColor.opacity(0.7)

    /// Sidebar and inspector column background.
    static func sideColumnBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.10, green: 0.09, blue: 0.06)
            : Color(red: 0.97, green: 0.96, blue: 0.94)
    }

    /// Main content column background (lighter tint in light mode).
    static func mainBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.10, blue: 0.07)
            : Color(red: 0.995, green: 0.99, blue: 0.985)
    }
}
