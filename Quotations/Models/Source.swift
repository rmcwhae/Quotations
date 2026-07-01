//
//  Source.swift
//  Quotations
//

import Foundation
import SwiftData

enum SourceFormat: String, CaseIterable, Identifiable {
    case kobo = "Kobo"
    case libby = "Libby"
    case appleBooks = "Apple Books"
    case printBook = "Print Book"

    var id: String { rawValue }
}

@Model
final class Source {
    var title: String
    var url: String?
    var publicationYear: Int?
    var format: String?
    var dateReadMonth: Int?
    var dateReadYear: Int?
    /// Stable ID from an external import source (e.g. Apple Books asset ID).
    var externalIdentifier: String?
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?

    var author: Author?

    @Relationship(deleteRule: .nullify, inverse: \Quotation.source)
    var quotations: [Quotation] = []

    init(
        title: String,
        author: Author? = nil,
        url: String? = nil,
        publicationYear: Int? = nil,
        format: String? = nil,
        dateReadMonth: Int? = nil,
        dateReadYear: Int? = nil,
        externalIdentifier: String? = nil
    ) {
        self.title = title
        self.author = author
        self.url = url
        self.publicationYear = publicationYear
        self.format = format
        self.dateReadMonth = dateReadMonth
        self.dateReadYear = dateReadYear
        self.externalIdentifier = externalIdentifier
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
    }

    var sourceFormat: SourceFormat? {
        get { format.flatMap { SourceFormat(rawValue: $0) } }
        set { format = newValue?.rawValue }
    }

    var formattedDateRead: String? {
        let monthSymbols = Calendar.current.monthSymbols
        switch (dateReadMonth, dateReadYear) {
        case let (month?, year?) where (1...12).contains(month):
            return "\(monthSymbols[month - 1]) \(year)"
        case let (month?, nil) where (1...12).contains(month):
            return monthSymbols[month - 1]
        case let (nil, year?):
            return String(year)
        default:
            return nil
        }
    }

    /// Higher values sort earlier when ordering by date read (reverse chronological).
    var dateReadSortKey: Int {
        switch (dateReadYear, dateReadMonth) {
        case let (year?, month?) where (1...12).contains(month):
            return year * 100 + month
        case let (year?, nil):
            return year * 100
        case let (nil, month?) where (1...12).contains(month):
            return month
        default:
            return Int.min
        }
    }

    static func compareByDateReadDescending(_ lhs: Source, _ rhs: Source) -> Bool {
        if lhs.dateReadSortKey != rhs.dateReadSortKey {
            return lhs.dateReadSortKey > rhs.dateReadSortKey
        }
        return (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
    }

    static func compareByDateAddedDescending(_ lhs: Source, _ rhs: Source) -> Bool {
        let lhsDate = lhs.createdAt ?? .distantPast
        let rhsDate = rhs.createdAt ?? .distantPast
        if lhsDate != rhsDate {
            return lhsDate > rhsDate
        }
        return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
    }

    /// Sources with no author sort before any named author (nil treated as an empty name).
    static func compareByAuthorNameAscending(_ lhs: Source, _ rhs: Source) -> Bool {
        let lhsName = lhs.author?.name ?? ""
        let rhsName = rhs.author?.name ?? ""
        let comparison = lhsName.localizedStandardCompare(rhsName)
        if comparison != .orderedSame {
            return comparison == .orderedAscending
        }
        return (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
    }

    static func compareByTitleAscending(_ lhs: Source, _ rhs: Source) -> Bool {
        let comparison = lhs.title.localizedStandardCompare(rhs.title)
        if comparison != .orderedSame {
            return comparison == .orderedAscending
        }
        return (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
    }

    static func comparator(for sortOption: SourceSortOption) -> (Source, Source) -> Bool {
        switch sortOption {
        case .dateRead: compareByDateReadDescending
        case .dateAdded: compareByDateAddedDescending
        case .authorName: compareByAuthorNameAscending
        case .title: compareByTitleAscending
        }
    }
}
