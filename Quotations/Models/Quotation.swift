//
//  Quotation.swift
//  Quotations
//

import Foundation
import SwiftData

@Model
final class Quotation {
    var content: String
    var location: String?
    /// Legacy page fields — retained for one-time migration to `location`.
    var startPage: Int?
    var endPage: Int?
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?

    var source: Source?

    init(content: String, source: Source? = nil, location: String? = nil) {
        self.content = content
        self.source = source
        self.location = location
        self.startPage = nil
        self.endPage = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
    }
}
