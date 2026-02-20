//
//  SearchBarView.swift
//  Quotations
//

import SwiftUI

struct SearchBarView: View {
    @Binding var query: String
    var isSearching: Bool
    var isSearchFocused: FocusState<Bool>.Binding
    var actions: () -> AnyView

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search by quotation, author, or source…", text: $query)
                    .textFieldStyle(.plain)
                    .focused(isSearchFocused)
                    .accessibilityLabel("Search quotations, authors, and sources")
            }
            .padding(8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))

            if isSearching {
                ProgressView()
                    .scaleEffect(0.8)
                    .accessibilityLabel("Searching")
            }

            actions()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
