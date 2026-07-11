//
//  QuotationLocationField.swift
//  Quotations
//

import SwiftUI

/// Compact right-aligned location input shown under a quotation row.
struct QuotationLocationField: View {
    @Binding var text: String
    var isSelected: Bool
    var textFieldWidth: CGFloat
    var horizontalInset: CGFloat
    var isFocused: FocusState<Bool>.Binding

    @Environment(\.colorScheme) private var colorScheme

    private var hasLocationText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Visible when there is a value, or when selected/focused for editing.
    private var isVisible: Bool {
        hasLocationText || isSelected || isFocused.wrappedValue
    }

    private var showsEditChrome: Bool {
        isSelected || isFocused.wrappedValue
    }

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 8)
            TextField(
                "",
                text: $text,
                prompt: Text("Location")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            )
            .font(.caption)
            .foregroundStyle(hasLocationText ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tertiary))
            .textFieldStyle(.plain)
            .multilineTextAlignment(.trailing)
            .focused(isFocused)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .frame(width: 88, alignment: .trailing)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        showsEditChrome
                            ? AppColors.editingBackground(colorScheme: colorScheme)
                            : Color.clear
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(
                        showsEditChrome
                            ? Color.secondary.opacity(0.45)
                            : Color.clear,
                        lineWidth: showsEditChrome ? 1 : 0
                    )
            }
            .padding(.horizontal, horizontalInset)
            .padding(.top, 1)
            .opacity(isVisible ? 1 : 0)
            .allowsHitTesting(isVisible)
            .accessibilityHidden(!isVisible)
            .accessibilityLabel("Location")
            .accessibilityHint("Page number or percentage")
            .onSubmit {
                isFocused.wrappedValue = false
            }
        }
        .frame(maxWidth: textFieldWidth + horizontalInset * 2 + 12)
    }
}
