//
//  Author.swift
//  Quotations
//

import Foundation
import SwiftData

@Model
final class Author {
    var name: String
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?

    init(name: String) {
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
    }
}
