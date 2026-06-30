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
    /// Stable ID from an external import source (e.g. Apple Books annotation UUID).
    var externalIdentifier: String?
    /// Legacy page fields — retained for one-time migration to `location`.
    var startPage: Int?
    var endPage: Int?
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?

    var source: Source?

    init(
        content: String,
        source: Source? = nil,
        location: String? = nil,
        externalIdentifier: String? = nil
    ) {
        self.content = content
        self.source = source
        self.location = location
        self.externalIdentifier = externalIdentifier
        self.startPage = nil
        self.endPage = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
    }
}
