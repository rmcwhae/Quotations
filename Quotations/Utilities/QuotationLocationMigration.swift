//
//  QuotationLocationMigration.swift
//  Quotations
//

import Foundation
import SwiftData

enum QuotationLocationMigration {
    private static let didMigrateKeyPrefix = "didMigrateQuotationLocation."

    static func migrateIfNeeded(context: ModelContext, storeURL: URL? = nil) {
        let migrationKey = didMigrateKey(for: storeURL)
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let descriptor = FetchDescriptor<Quotation>(
            predicate: #Predicate<Quotation> { $0.deletedAt == nil }
        )

        let quotations: [Quotation]
        do {
            quotations = try context.fetch(descriptor)
        } catch {
            print("QuotationLocationMigration fetch failed: \(error)")
            return
        }

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
        UserDefaults.standard.set(true, forKey: migrationKey)
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

    private static func didMigrateKey(for storeURL: URL?) -> String {
        let identity = storeURL?.absoluteString ?? "inMemory"
        return didMigrateKeyPrefix + identity
    }
}
