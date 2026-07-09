//
//  AppGroupStore.swift
//  Quotations
//

import Foundation
import SwiftData

enum AppGroupStore {
    static let identifier = "group.com.russellmcwhae.Quotations"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static func modelConfiguration(schema: Schema) -> ModelConfiguration {
        ModelConfiguration(schema: schema, groupContainer: .identifier(identifier))
    }

    /// Default Application Support store URL (pre–App Group migration).
    static func legacyStoreURL(schema: Schema) -> URL {
        ModelConfiguration(schema: schema, isStoredInMemoryOnly: false).url
    }

    /// Copies the legacy store into the App Group container when the shared store is missing.
    static func migrateLegacyStoreIfNeeded(schema: Schema) throws {
        let fileManager = FileManager.default
        let legacyURL = legacyStoreURL(schema: schema)
        let sharedURL = modelConfiguration(schema: schema).url

        guard fileManager.fileExists(atPath: legacyURL.path) else { return }
        guard !fileManager.fileExists(atPath: sharedURL.path) else { return }

        let destinationDirectory = sharedURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        try copyStoreFiles(from: legacyURL, toDirectory: destinationDirectory)
    }

    static func copyStoreFiles(from sourceStoreURL: URL, toDirectory destinationDirectory: URL) throws {
        let fileManager = FileManager.default
        let storeFileName = sourceStoreURL.lastPathComponent

        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: sourceStoreURL.path + suffix)
            guard fileManager.fileExists(atPath: source.path) else { continue }
            let destination = destinationDirectory.appendingPathComponent(storeFileName + suffix)
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: source, to: destination)
        }
    }
}
