//
//  AppGroupStore.swift
//  Quotations
//

import Foundation
import SwiftData

enum AppGroupStore {
    static let identifier = "group.com.russellmcwhae.Quotations.personal"
    static let configurationName = "Quotations"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static func modelConfiguration(schema: Schema) -> ModelConfiguration {
        ModelConfiguration(configurationName, schema: schema, groupContainer: .identifier(identifier))
    }

    static var sharedStoreURL: URL {
        let schema = Schema([Author.self, Source.self, Quotation.self])
        return modelConfiguration(schema: schema).url
    }

    static var sharedStoreExists: Bool {
        FileManager.default.fileExists(atPath: sharedStoreURL.path)
    }

    /// Default Application Support store URL (pre–App Group migration).
    static func legacyStoreURL(schema: Schema) -> URL {
        ModelConfiguration(schema: schema, isStoredInMemoryOnly: false).url
    }

    /// Copies the legacy store into the App Group container once, then retires it so a
    /// stale copy can never overwrite the live store on a later launch.
    static func migrateLegacyStoreIfNeeded(schema: Schema) throws {
        let fileManager = FileManager.default
        let legacyURL = legacyStoreURL(schema: schema)
        let sharedURL = modelConfiguration(schema: schema).url

        if fileManager.fileExists(atPath: legacyURL.path) {
            if !fileManager.fileExists(atPath: sharedURL.path) {
                let destinationDirectory = sharedURL.deletingLastPathComponent()
                try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
                try copyStoreFiles(from: legacyURL, toDirectory: destinationDirectory)
            } else if shouldPreferStore(at: legacyURL, over: sharedURL) {
                try StoreSnapshot.replaceStore(at: sharedURL, withSnapshotFrom: legacyURL)
            }
            try retireStore(at: legacyURL)
        }

        try consolidateSiblingStoresIfNeeded(around: sharedURL)
    }

    /// When other primary stores sit next to the canonical one, adopt the fullest one once,
    /// then retire every sibling so the comparison never runs again.
    static func consolidateSiblingStoresIfNeeded(around canonicalURL: URL) throws {
        let directory = canonicalURL.deletingLastPathComponent()
        guard let storeFiles = StoreSnapshot.primaryStoreFiles(in: directory), storeFiles.count > 1 else {
            return
        }

        if let preferred = StoreSnapshot.preferredStoreFile(in: directory),
           preferred != canonicalURL,
           shouldPreferStore(at: preferred, over: canonicalURL) {
            try StoreSnapshot.replaceStore(at: canonicalURL, withSnapshotFrom: preferred)
        }

        for sibling in storeFiles where sibling.standardizedFileURL != canonicalURL.standardizedFileURL {
            try retireStore(at: sibling)
        }
    }

    /// Never replaces a store whose count can't be read: a failed open is not "empty".
    private static func shouldPreferStore(at candidateURL: URL, over incumbentURL: URL) -> Bool {
        guard let candidateCount = try? StoreSnapshot.liveQuotationCount(forStoreAt: candidateURL),
              let incumbentCount = try? StoreSnapshot.liveQuotationCount(forStoreAt: incumbentURL) else {
            return false
        }
        return candidateCount > incumbentCount
    }

    /// Renames a store and its sidecars to `*.migrated` so they are kept but no longer read.
    private static func retireStore(at storeURL: URL) throws {
        let fileManager = FileManager.default
        for url in StoreSnapshot.storeSidecarURLs(for: storeURL) {
            let retired = URL(fileURLWithPath: url.path + ".migrated")
            if fileManager.fileExists(atPath: retired.path) {
                try fileManager.removeItem(at: retired)
            }
            try fileManager.moveItem(at: url, to: retired)
        }
    }

    static func copyStoreFiles(from sourceStoreURL: URL, toDirectory destinationDirectory: URL) throws {
        try StoreSnapshot.copyStoreFiles(from: sourceStoreURL, toDirectory: destinationDirectory)
    }
}
