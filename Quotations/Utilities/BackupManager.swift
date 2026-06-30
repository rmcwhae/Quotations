//
//  BackupManager.swift
//  Quotations
//

import AppKit
import Foundation
import Observation
import SwiftData

struct Backup: Identifiable, Equatable {
    let id: String
    let createdAt: Date
    let authorCount: Int
    let sourceCount: Int
    let quotationCount: Int
    let isSafetyBackup: Bool
    let directoryURL: URL

    var summary: String {
        "\(authorCount) authors, \(sourceCount) sources, \(quotationCount) quotations"
    }
}

enum BackupError: LocalizedError, Equatable {
    case storeFileMissing
    case backupDirectoryMissing
    case metadataWriteFailed
    case relaunchFailed

    var errorDescription: String? {
        switch self {
        case .storeFileMissing:
            return "The library store file could not be found."
        case .backupDirectoryMissing:
            return "The selected backup could not be found."
        case .metadataWriteFailed:
            return "Could not write backup metadata."
        case .relaunchFailed:
            return "The app could not relaunch automatically. " +
                "Please quit and reopen Quotations to complete the restore."
        }
    }
}

@Observable
final class BackupManager {
    static let pendingRestoreBackupIDKey = "pendingRestoreBackupID"

    let storeURL: URL
    let backupsDirectory: URL

    private(set) var backups: [Backup] = []

    init(storeURL: URL, backupsDirectory: URL? = nil) {
        self.storeURL = storeURL
        if let backupsDirectory {
            self.backupsDirectory = backupsDirectory
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            self.backupsDirectory = appSupport.appendingPathComponent("Backups", isDirectory: true)
        }
        refreshBackups()
    }

    func refreshBackups() {
        backups = Self.listBackups(in: backupsDirectory)
    }

    @discardableResult
    func createBackup(isSafetyBackup: Bool = false) throws -> Backup {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: storeURL.path) else {
            throw BackupError.storeFileMissing
        }

        try fileManager.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)

        let createdAt = Date()
        let backupID = Self.makeBackupID(from: createdAt)
        let backupDirectory = backupsDirectory.appendingPathComponent(backupID, isDirectory: true)
        try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)

        try Self.copyStoreFiles(from: storeURL, toDirectory: backupDirectory)

        let snapshotStoreURL = backupDirectory.appendingPathComponent(storeURL.lastPathComponent)
        let counts = try Self.recordCounts(forStoreAt: snapshotStoreURL)
        let backup = Backup(
            id: backupID,
            createdAt: createdAt,
            authorCount: counts.authors,
            sourceCount: counts.sources,
            quotationCount: counts.quotations,
            isSafetyBackup: isSafetyBackup,
            directoryURL: backupDirectory
        )
        try Self.writeMetadata(for: backup, to: backupDirectory)
        refreshBackups()
        return backup
    }

    func deleteBackup(_ backup: Backup) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: backup.directoryURL.path) else {
            throw BackupError.backupDirectoryMissing
        }
        try fileManager.removeItem(at: backup.directoryURL)
        refreshBackups()
    }

    func requestRestore(_ backup: Backup) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: backup.directoryURL.path) else {
            throw BackupError.backupDirectoryMissing
        }

        _ = try createBackup(isSafetyBackup: true)
        UserDefaults.standard.set(backup.id, forKey: Self.pendingRestoreBackupIDKey)

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true

        let semaphore = DispatchSemaphore(value: 0)
        var relaunchError: Error?

        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration) { _, error in
            relaunchError = error
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 5)

        if relaunchError != nil {
            UserDefaults.standard.removeObject(forKey: Self.pendingRestoreBackupIDKey)
            throw BackupError.relaunchFailed
        }

        NSApp.terminate(nil)
    }

    static func applyPendingRestoreIfNeeded(storeURL: URL, backupsDirectory: URL? = nil) {
        guard let backupID = UserDefaults.standard.string(forKey: pendingRestoreBackupIDKey) else {
            return
        }

        defer {
            UserDefaults.standard.removeObject(forKey: pendingRestoreBackupIDKey)
        }

        let directory = backupsDirectory ?? defaultBackupsDirectory()
        let backupDirectory = directory.appendingPathComponent(backupID, isDirectory: true)
        guard FileManager.default.fileExists(atPath: backupDirectory.path) else {
            return
        }

        do {
            try replaceStore(
                at: storeURL,
                withSnapshotFrom: backupDirectory.appendingPathComponent(storeURL.lastPathComponent)
            )
        } catch {
            print("BackupManager restore failed: \(error)")
        }
    }

    static func listBackups(in backupsDirectory: URL) -> [Backup] {
        let fileManager = FileManager.default
        guard let entries = try? fileManager.contentsOfDirectory(
            at: backupsDirectory,
            includingPropertiesForKeys: [.creationDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return entries
            .filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            }
            .compactMap { loadBackup(from: $0) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - File operations

    static func defaultBackupsDirectory() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent("Backups", isDirectory: true)
    }

    static func makeBackupID(from date: Date = Date()) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
            .replacingOccurrences(of: ":", with: "-")
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

        try copyStoreFiles(
            from: sourceStoreURL,
            toDirectory: destinationDirectory
        )
    }

    // MARK: - Metadata

    private struct BackupMetadata: Codable {
        let createdAt: Date
        let authorCount: Int
        let sourceCount: Int
        let quotationCount: Int
        let isSafetyBackup: Bool
    }

    private struct RecordCounts {
        let authors: Int
        let sources: Int
        let quotations: Int
    }

    private static func metadataURL(in backupDirectory: URL) -> URL {
        backupDirectory.appendingPathComponent("metadata.json")
    }

    private static func writeMetadata(for backup: Backup, to backupDirectory: URL) throws {
        let metadata = BackupMetadata(
            createdAt: backup.createdAt,
            authorCount: backup.authorCount,
            sourceCount: backup.sourceCount,
            quotationCount: backup.quotationCount,
            isSafetyBackup: backup.isSafetyBackup
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(metadata)
        do {
            try data.write(to: metadataURL(in: backupDirectory), options: .atomic)
        } catch {
            throw BackupError.metadataWriteFailed
        }
    }

    private static func loadBackup(from directoryURL: URL) -> Backup? {
        let storeFileName = "default.store"
        let storeURL = directoryURL.appendingPathComponent(storeFileName)
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return nil
        }

        if let metadata = loadMetadata(from: directoryURL) {
            return Backup(
                id: directoryURL.lastPathComponent,
                createdAt: metadata.createdAt,
                authorCount: metadata.authorCount,
                sourceCount: metadata.sourceCount,
                quotationCount: metadata.quotationCount,
                isSafetyBackup: metadata.isSafetyBackup,
                directoryURL: directoryURL
            )
        }

        let createdAt = (try? directoryURL.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
        let counts = (try? recordCounts(forStoreAt: storeURL)) ?? RecordCounts(authors: 0, sources: 0, quotations: 0)
        return Backup(
            id: directoryURL.lastPathComponent,
            createdAt: createdAt,
            authorCount: counts.authors,
            sourceCount: counts.sources,
            quotationCount: counts.quotations,
            isSafetyBackup: false,
            directoryURL: directoryURL
        )
    }

    private static func loadMetadata(from backupDirectory: URL) -> BackupMetadata? {
        let url = metadataURL(in: backupDirectory)
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(BackupMetadata.self, from: data)
    }

    private static func recordCounts(forStoreAt storeURL: URL) throws -> RecordCounts {
        let schema = Schema([Author.self, Source.self, Quotation.self])
        let configuration = ModelConfiguration(url: storeURL)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        let authors = try context.fetchCount(FetchDescriptor<Author>(
            predicate: #Predicate<Author> { $0.deletedAt == nil }
        ))
        let sources = try context.fetchCount(FetchDescriptor<Source>(
            predicate: #Predicate<Source> { $0.deletedAt == nil }
        ))
        let quotations = try context.fetchCount(FetchDescriptor<Quotation>(
            predicate: #Predicate<Quotation> { $0.deletedAt == nil }
        ))

        return RecordCounts(authors: authors, sources: sources, quotations: quotations)
    }
}

extension Notification.Name {
    static let showBackupsPanel = Notification.Name("showBackupsPanel")
}
