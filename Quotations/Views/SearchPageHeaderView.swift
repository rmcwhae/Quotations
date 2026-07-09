//
//  SearchPageHeaderView.swift
//  Quotations
//

import SwiftUI

struct SearchPageHeaderView: View {
    @Binding var query: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField("Search for keywords or meaning", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17))
                    .focused(isFocused)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.quaternary.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.quaternary, lineWidth: 1)
            )

            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Search your library by exact words or by concept.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}
