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
        List(selection: selection) {
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
    }

    /// Native List selection: arrow keys, full-row hit targets and the system highlight.
    private var selection: Binding<LibraryFilter?> {
        Binding(
            get: { selectedFilter },
            set: { newValue in
                guard let newValue, newValue != selectedFilter else { return }
                onSelectFilter(newValue)
            }
        )
    }

    private func filterRow(_ filter: LibraryFilter) -> some View {
        Label(filter.title, systemImage: filter.systemImage)
            .tag(filter)
    }

    static func == (lhs: LibraryFilterSidebarView, rhs: LibraryFilterSidebarView) -> Bool {
        lhs.selectedFilter == rhs.selectedFilter
    }
}
