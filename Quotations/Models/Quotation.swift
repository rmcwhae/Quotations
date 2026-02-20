//
//  Quotation.swift
//  Quotations
//

import Foundation
import SwiftData

@Model
final class Quotation {
    var content: String
    var startPage: Int?
    var endPage: Int?
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?

    var source: Source?

    init(content: String, source: Source? = nil, startPage: Int? = nil, endPage: Int? = nil) {
        self.content = content
        self.source = source
        self.startPage = startPage
        self.endPage = endPage
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
    }
}
