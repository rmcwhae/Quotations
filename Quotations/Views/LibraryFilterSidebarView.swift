//
//  LibraryFilterSidebarView.swift
//  Quotations
//
//  Column 1: high-level library filters only.
//

import SwiftUI

struct LibraryFilterSidebarView: View, Equatable {
    let selectedFilter: LibraryFilter
    let isSearchActive: Bool
    var onSelectFilter: (LibraryFilter) -> Void

    private var displayedSelection: LibraryFilter {
        isSearchActive ? .searchResults : selectedFilter
    }

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
        let isSelected = displayedSelection == filter

        Label(filter.title, systemImage: filter.systemImage)
            .foregroundStyle(isImplicit && !isSelected ? .secondary : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? AppColors.selectionBackground : Color.clear)
                    .padding(.horizontal, 4)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                guard filter != .searchResults, filter != selectedFilter else { return }
                onSelectFilter(filter)
            }
    }

    static func == (lhs: LibraryFilterSidebarView, rhs: LibraryFilterSidebarView) -> Bool {
        lhs.selectedFilter == rhs.selectedFilter && lhs.isSearchActive == rhs.isSearchActive
    }
}
