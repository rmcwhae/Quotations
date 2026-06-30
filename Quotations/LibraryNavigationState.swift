//
//  LibraryNavigationState.swift
//  Quotations
//

import Foundation
import Observation
import SwiftData

@Observable
final class LibraryNavigationState {
    var selectedFilter: LibraryFilter = .quotationsBySource
    var selectedSourceId: PersistentIdentifier?
    var selectedQuotationId: PersistentIdentifier?

    /// When search is active, column 2 uses the search-results context.
    func effectiveFilter(isSearchActive: Bool) -> LibraryFilter {
        isSearchActive ? .searchResults : selectedFilter
    }

    func selectFilter(_ filter: LibraryFilter) {
        guard filter != .searchResults else { return }
        selectedFilter = filter
        clearListSelection()
    }

    func selectSource(_ id: PersistentIdentifier) {
        selectedSourceId = id
        selectedQuotationId = nil
    }

    func selectQuotation(_ id: PersistentIdentifier, sourceId: PersistentIdentifier?) {
        selectedQuotationId = id
        if let sourceId {
            selectedSourceId = sourceId
        }
    }

    func clearListSelection() {
        selectedSourceId = nil
        selectedQuotationId = nil
    }

    func clearQuotationSelection() {
        selectedQuotationId = nil
    }
}
