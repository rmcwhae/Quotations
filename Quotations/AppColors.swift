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
}
