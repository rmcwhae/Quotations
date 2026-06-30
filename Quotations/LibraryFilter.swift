//
//  LibraryFilter.swift
//  Quotations
//

import Foundation
import SwiftData

/// High-level library filters shown in column 1. Low cardinality only — no per-source rows.
enum LibraryFilter: Hashable, Identifiable {
    case allQuotes
    case quotationsBySource
    case recentlyAdded
    case format(SourceFormat)
    case searchResults

    var id: String {
        switch self {
        case .allQuotes: "allQuotes"
        case .quotationsBySource: "quotationsBySource"
        case .recentlyAdded: "recentlyAdded"
        case .format(let format): "format-\(format.rawValue)"
        case .searchResults: "searchResults"
        }
    }

    var title: String {
        switch self {
        case .allQuotes: "All Quotes"
        case .quotationsBySource: "Quotations by Source"
        case .recentlyAdded: "Recently Added"
        case .format(let format): format.rawValue
        case .searchResults: "Search Results"
        }
    }

    var systemImage: String {
        switch self {
        case .allQuotes: "quote.bubble"
        case .quotationsBySource: "book.closed"
        case .recentlyAdded: "clock"
        case .format: "books.vertical"
        case .searchResults: "magnifyingglass"
        }
    }

    /// Filters that render quotation rows in column 2.
    var showsQuotations: Bool {
        switch self {
        case .allQuotes, .recentlyAdded, .searchResults: true
        case .quotationsBySource, .format: false
        }
    }

    /// Primary sidebar filters (excludes implicit search context).
    static var primaryFilters: [LibraryFilter] {
        [.quotationsBySource, .allQuotes, .recentlyAdded]
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
