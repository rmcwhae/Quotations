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

    private let cornerRadius: CGFloat = 10

    var body: some View {
        HStack(spacing: 12) {
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
            .background(.quaternary, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                }
            }

            if isSearching {
                ProgressView()
                    .scaleEffect(0.75)
                    .accessibilityLabel("Searching")
            }

            actions()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
