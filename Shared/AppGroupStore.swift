//
//  AppGroupStore.swift
//  Quotations
//

import Foundation
import SwiftData

enum AppGroupStore {
    static let identifier = "group.com.russellmcwhae.Quotations"
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

    /// Copies the legacy store into the App Group container when the shared store is missing or empty.
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
        }

        try consolidateSiblingStoresIfNeeded(around: sharedURL)
    }

    /// When both `default.store` and the named store exist in the App Group, keep the one with data.
    static func consolidateSiblingStoresIfNeeded(around canonicalURL: URL) throws {
        let directory = canonicalURL.deletingLastPathComponent()
        guard let storeFiles = StoreSnapshot.primaryStoreFiles(in: directory), storeFiles.count > 1 else {
            return
        }

        guard let preferred = StoreSnapshot.preferredStoreFile(in: directory),
              preferred != canonicalURL else {
            return
        }

        if shouldPreferStore(at: preferred, over: canonicalURL) {
            try StoreSnapshot.replaceStore(at: canonicalURL, withSnapshotFrom: preferred)
        }
    }

    private static func shouldPreferStore(at candidateURL: URL, over incumbentURL: URL) -> Bool {
        let candidateCount = (try? StoreSnapshot.liveQuotationCount(forStoreAt: candidateURL)) ?? 0
        let incumbentCount = (try? StoreSnapshot.liveQuotationCount(forStoreAt: incumbentURL)) ?? 0
        return candidateCount > incumbentCount
    }

    static func copyStoreFiles(from sourceStoreURL: URL, toDirectory destinationDirectory: URL) throws {
        try StoreSnapshot.copyStoreFiles(from: sourceStoreURL, toDirectory: destinationDirectory)
    }
}
