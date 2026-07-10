//
//  LibraryFilter.swift
//  Quotations
//

import Foundation
import SwiftData

/// High-level library filters shown in column 1. Low cardinality only — no per-source rows.
enum LibraryFilter: Hashable, Identifiable {
    case quotationsBySource
    case recentlyAdded
    case format(SourceFormat)
    case searchResults
    case explore
    case ask

    var id: String {
        switch self {
        case .quotationsBySource: "quotationsBySource"
        case .recentlyAdded: "recentlyAdded"
        case .format(let format): "format-\(format.rawValue)"
        case .searchResults: "searchResults"
        case .explore: "explore"
        case .ask: "ask"
        }
    }

    var title: String {
        switch self {
        case .quotationsBySource: "Quotations by Source"
        case .recentlyAdded: "Recently Added"
        case .format(let format): format.rawValue
        case .searchResults: "Advanced Search"
        case .explore: "Explore"
        case .ask: "Ask"
        }
    }

    var systemImage: String {
        switch self {
        case .quotationsBySource: "book.closed"
        case .recentlyAdded: "clock"
        case .format: "books.vertical"
        case .searchResults: "magnifyingglass"
        case .explore: "chart.dots.scatter"
        case .ask: "sparkles"
        }
    }

    /// Filters that render quotation rows in column 2.
    var showsQuotations: Bool {
        switch self {
        case .recentlyAdded, .searchResults: true
        case .quotationsBySource, .format, .explore, .ask: false
        }
    }

    /// Primary sidebar filters (excludes implicit search context).
    /// `.recentlyAdded` is hidden for now — not yet exposed in the sidebar.
    static var primaryFilters: [LibraryFilter] {
        [.quotationsBySource, .explore, .ask, .searchResults]
    }

    static var formatFilters: [LibraryFilter] {
        SourceFormat.allCases.map { .format($0) }
    }
}

/// Selection emitted by column 2.
enum LibraryListSelection: Hashable {
    case source(PersistentIdentifier)
    case quotation(PersistentIdentifier, sourceId: PersistentIdentifier?)
}
