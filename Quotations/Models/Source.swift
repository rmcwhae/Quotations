//
//  Source.swift
//  Quotations
//

import Foundation
import SwiftData

@Model
final class Source {
    var title: String
    var url: String?
    var publicationYear: Int?
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?

    var author: Author?

    init(title: String, author: Author? = nil, url: String? = nil, publicationYear: Int? = nil) {
        self.title = title
        self.author = author
        self.url = url
        self.publicationYear = publicationYear
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
    }
}
