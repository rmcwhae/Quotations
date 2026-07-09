//
//  LibraryFilterSidebarView.swift
//  Quotations
//
//  Column 1: high-level library filters only.
//

import SwiftUI

struct LibraryFilterSidebarView: View, Equatable {
    let selectedFilter: LibraryFilter
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
        }
        .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 300)
    }

    @ViewBuilder
    private func filterRow(_ filter: LibraryFilter) -> some View {
        let isSelected = selectedFilter == filter

        Label(filter.title, systemImage: filter.systemImage)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? AppColors.selectionBackground : Color.clear)
                    .padding(.horizontal, 4)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                guard filter != selectedFilter else { return }
                onSelectFilter(filter)
            }
    }

    static func == (lhs: LibraryFilterSidebarView, rhs: LibraryFilterSidebarView) -> Bool {
        lhs.selectedFilter == rhs.selectedFilter
    }
}
