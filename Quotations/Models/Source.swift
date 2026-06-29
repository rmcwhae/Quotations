//
//  Source.swift
//  Quotations
//

import Foundation
import SwiftData

enum SourceFormat: String, CaseIterable, Identifiable {
    case kobo = "Kobo"
    case appleBooks = "Apple Books"
    case audiobook = "Audiobook"
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
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?

    var author: Author?

    init(
        title: String,
        author: Author? = nil,
        url: String? = nil,
        publicationYear: Int? = nil,
        format: String? = nil,
        dateReadMonth: Int? = nil,
        dateReadYear: Int? = nil
    ) {
        self.title = title
        self.author = author
        self.url = url
        self.publicationYear = publicationYear
        self.format = format
        self.dateReadMonth = dateReadMonth
        self.dateReadYear = dateReadYear
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
    }

    var formattedDateRead: String? {
        let monthSymbols = Calendar.current.monthSymbols
        switch (dateReadMonth, dateReadYear) {
        case let (month?, year?):
            return "\(monthSymbols[month - 1]) \(year)"
        case let (month?, nil):
            return monthSymbols[month - 1]
        case let (nil, year?):
            return String(year)
        default:
            return nil
        }
    }
}
