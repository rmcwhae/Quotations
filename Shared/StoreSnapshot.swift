//
//  StoreSnapshot.swift
//  Quotations
//

import Foundation
import SwiftData

enum StoreSnapshot {
    static func primaryStoreFiles(in directory: URL) -> [URL]? {
        let fileManager = FileManager.default
        guard let entries = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        let storeFiles = entries.filter(isPrimaryStoreFile)
        return storeFiles.isEmpty ? nil : storeFiles
    }

    static func primaryStoreFile(in directory: URL) -> URL? {
        preferredStoreFile(in: directory)
    }

    static func preferredStoreFile(in directory: URL) -> URL? {
        guard let storeFiles = primaryStoreFiles(in: directory) else { return nil }
        return storeFiles.max { lhs, rhs in
            let lhsCount = (try? liveQuotationCount(forStoreAt: lhs)) ?? 0
            let rhsCount = (try? liveQuotationCount(forStoreAt: rhs)) ?? 0
            if lhsCount != rhsCount {
                return lhsCount < rhsCount
            }
            let lhsSize = (try? lhs.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            let rhsSize = (try? rhs.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return lhsSize < rhsSize
        }
    }

    static func liveQuotationCount(forStoreAt storeURL: URL) throws -> Int {
        let schema = Schema([Author.self, Source.self, Quotation.self])
        let configuration = ModelConfiguration(url: storeURL)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        return try context.fetchCount(FetchDescriptor<Quotation>(
            predicate: #Predicate<Quotation> { $0.deletedAt == nil }
        ))
    }

    static func storeSidecarURLs(for storeURL: URL) -> [URL] {
        var urls = [storeURL]
        let wal = URL(fileURLWithPath: storeURL.path + "-wal")
        let shm = URL(fileURLWithPath: storeURL.path + "-shm")
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: wal.path) {
            urls.append(wal)
        }
        if fileManager.fileExists(atPath: shm.path) {
            urls.append(shm)
        }
        return urls
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

    static func replaceStore(at destinationStoreURL: URL, withSnapshotFrom sourceStoreURL: URL) throws {
        let fileManager = FileManager.default
        let destinationDirectory = destinationStoreURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)

        for url in storeSidecarURLs(for: destinationStoreURL) where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }

        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: sourceStoreURL.path + suffix)
            guard fileManager.fileExists(atPath: source.path) else { continue }
            let destination = URL(fileURLWithPath: destinationStoreURL.path + suffix)
            try fileManager.copyItem(at: source, to: destination)
        }
    }

    private static func isPrimaryStoreFile(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        return name.hasSuffix(".store") && !name.contains(".store-")
    }
}
