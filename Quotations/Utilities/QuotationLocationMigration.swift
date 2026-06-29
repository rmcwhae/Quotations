//
//  QuotationLocationMigration.swift
//  Quotations
//

import Foundation
import SwiftData

enum QuotationLocationMigration {
    private static let didMigrateKey = "didMigrateQuotationLocation"

    static func migrateIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: didMigrateKey) else { return }

        let descriptor = FetchDescriptor<Quotation>()
        guard let quotations = try? context.fetch(descriptor) else { return }

        var didChange = false
        for quotation in quotations {
            guard quotation.location == nil || quotation.location?.isEmpty == true else { continue }
            guard let migrated = migratedLocation(startPage: quotation.startPage, endPage: quotation.endPage) else {
                continue
            }
            quotation.location = migrated
            quotation.startPage = nil
            quotation.endPage = nil
            quotation.updatedAt = Date()
            didChange = true
        }

        if didChange {
            do {
                try context.save()
            } catch {
                print("QuotationLocationMigration save failed: \(error)")
                return
            }
        }
        UserDefaults.standard.set(true, forKey: didMigrateKey)
    }

    static func migratedLocation(startPage: Int?, endPage: Int?) -> String? {
        switch (startPage, endPage) {
        case let (start?, end?) where start != end:
            return "\(start)\u{2013}\(end)"
        case let (start?, _):
            return "\(start)"
        case let (nil, end?):
            return "\(end)"
        default:
            return nil
        }
    }
}
