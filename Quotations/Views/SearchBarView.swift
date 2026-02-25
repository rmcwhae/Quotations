//
//  SearchBarView.swift
//  Quotations
//

import SwiftUI

struct SearchBarView: View {
    @Binding var query: String
    var isSearching: Bool
    var isSearchFocused: FocusState<Bool>.Binding
    var isFocused: Bool
    var actions: () -> AnyView

    @Environment(\.colorScheme) private var colorScheme

    private let cornerRadius: CGFloat = 6

    private var searchBackground: Color {
        switch colorScheme {
        case .dark:
            return Color(white: 0.22)
        default:
            return Color(white: 0.92)
        }
    }

    /// Thicker light blue border when focused, like Finder.
    private let searchFocusBorder = Color(red: 0.35, green: 0.55, blue: 0.92)

    var body: some View {
        HStack(spacing: 12) {
            actions()

            Spacer(minLength: 0)

            if isSearching {
                ProgressView()
                    .scaleEffect(0.75)
                    .accessibilityLabel("Searching")
            }

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("Search", text: $query)
                    .textFieldStyle(.plain)
                    .focused(isSearchFocused)
                    .accessibilityLabel("Search quotations, authors, and sources")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: 280)
            .background(searchBackground, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isFocused ? searchFocusBorder : Color.clear,
                        lineWidth: isFocused ? 3 : 0
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}
