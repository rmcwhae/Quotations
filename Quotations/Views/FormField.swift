//
//  FormField.swift
//  Quotations
//

import SwiftUI

/// Standardized form row: left-aligned label, right-aligned input.
struct FormFieldRow<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            content()
        }
    }
}

/// Right-aligned, borderless input that reads as blank when idle and shows a
/// paper-colored background on hover (white in light mode, near-black in dark).
private struct FormInputStyle: ViewModifier {
    var maxWidth: CGFloat
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .multilineTextAlignment(.trailing)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .frame(maxWidth: maxWidth, alignment: .trailing)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? AppColors.editingBackground(colorScheme: colorScheme) : Color.clear)
            )
            .onHover { isHovering = $0 }
    }
}

extension View {
    /// Apply to a plain `TextField` to get the standardized blank/hover input look.
    func formInputStyle(maxWidth: CGFloat = 200) -> some View {
        modifier(FormInputStyle(maxWidth: maxWidth))
    }
}
