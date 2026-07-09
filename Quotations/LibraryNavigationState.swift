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

    func selectFilter(_ filter: LibraryFilter) {
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

    func openQuotationFromDeepLink(
        _ quotationId: PersistentIdentifier,
        sourceId: PersistentIdentifier
    ) {
        selectedFilter = .quotationsBySource
        selectedSourceId = sourceId
        selectedQuotationId = quotationId
    }
}
