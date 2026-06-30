//
//  LibraryFilterSidebarView.swift
//  Quotations
//
//  Column 1: high-level library filters only.
//

import SwiftUI

struct LibraryFilterSidebarView: View {
    @Bindable var navigation: LibraryNavigationState
    let isSearchActive: Bool
    var onSelectFilter: (LibraryFilter) -> Void

    var body: some View {
        List {
            Section {
                ForEach(LibraryFilter.primaryFilters) { filter in
                    filterRow(filter)
                }
            }

            Section("Formats") {
                ForEach(LibraryFilter.formatFilters) { filter in
                    filterRow(filter)
                }
            }

            if isSearchActive {
                Section {
                    filterRow(.searchResults, isImplicit: true)
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 260)
    }

    @ViewBuilder
    private func filterRow(_ filter: LibraryFilter, isImplicit: Bool = false) -> some View {
        let isSelected = isSearchActive
            ? filter == .searchResults
            : navigation.selectedFilter == filter

        Label(filter.title, systemImage: filter.systemImage)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? AppColors.selectionBackground : Color.clear)
                    .padding(.horizontal, 4)
            )
            .foregroundStyle(isImplicit && !isSelected ? .secondary : .primary)
            .contentShape(Rectangle())
            .onTapGesture {
                onSelectFilter(filter)
            }
    }
}
