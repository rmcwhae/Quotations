//
//  BackupManagerTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

final class BackupManagerTests: XCTestCase {
    private var tempDirectory: URL!
    private var storeURL: URL!
    private var backupsDirectory: URL!
    private var container: ModelContainer!
    private var context: ModelContext!
    private var manager: BackupManager!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        storeURL = tempDirectory.appendingPathComponent("default.store")
        backupsDirectory = tempDirectory.appendingPathComponent("Backups", isDirectory: true)

        let configuration = ModelConfiguration(url: storeURL)
        container = try ModelContainer(
            for: Author.self, Source.self, Quotation.self,
            configurations: configuration
        )
        context = ModelContext(container)

        let author = Author(name: "Seneca")
        let source = Source(title: "Letters", author: author)
        let quotation = Quotation(content: "Luck is what happens when preparation meets opportunity.", source: source)
        context.insert(author)
        context.insert(source)
        context.insert(quotation)
        try context.save()

        manager = BackupManager(storeURL: storeURL, backupsDirectory: backupsDirectory)
    }

    override func tearDownWithError() throws {
        manager = nil
        context = nil
        container = nil
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil
        storeURL = nil
        backupsDirectory = nil
        UserDefaults.standard.removeObject(forKey: BackupManager.pendingRestoreBackupIDKey)
    }

    func testCreateBackupCopiesStoreFiles() throws {
        let backup = try manager.createBackup()

        XCTAssertTrue(FileManager.default.fileExists(atPath: backup.directoryURL.path))
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: backup.directoryURL.appendingPathComponent("default.store").path
        ))
        XCTAssertEqual(backup.authorCount, 1)
        XCTAssertEqual(backup.sourceCount, 1)
        XCTAssertEqual(backup.quotationCount, 1)
        XCTAssertFalse(backup.isSafetyBackup)
        XCTAssertEqual(manager.backups.count, 1)
    }

    func testListBackupsOrdersNewestFirst() throws {
        _ = try manager.createBackup()
        Thread.sleep(forTimeInterval: 0.01)
        _ = try manager.createBackup()

        let listed = BackupManager.listBackups(in: backupsDirectory)
        XCTAssertEqual(listed.count, 2)
        XCTAssertGreaterThanOrEqual(listed[0].createdAt, listed[1].createdAt)
    }

    func testDeleteBackupRemovesDirectory() throws {
        let backup = try manager.createBackup()
        try manager.deleteBackup(backup)

        XCTAssertFalse(FileManager.default.fileExists(atPath: backup.directoryURL.path))
        XCTAssertTrue(manager.backups.isEmpty)
    }

    func testApplyPendingRestoreOverwritesStore() throws {
        let backup = try manager.createBackup()

        let replacementAuthor = Author(name: "Epictetus")
        let replacementSource = Source(title: "Discourses", author: replacementAuthor)
        context.insert(replacementAuthor)
        context.insert(replacementSource)
        try context.save()

        UserDefaults.standard.set(backup.id, forKey: BackupManager.pendingRestoreBackupIDKey)
        BackupManager.applyPendingRestoreIfNeeded(
            storeURL: storeURL,
            backupsDirectory: backupsDirectory
        )

        XCTAssertNil(UserDefaults.standard.string(forKey: BackupManager.pendingRestoreBackupIDKey))

        let restoredContainer = try ModelContainer(
            for: Author.self, Source.self, Quotation.self,
            configurations: ModelConfiguration(url: storeURL)
        )
        let restoredContext = ModelContext(restoredContainer)

        let authors = try restoredContext.fetch(FetchDescriptor<Author>(
            predicate: #Predicate<Author> { $0.deletedAt == nil }
        ))
        let sources = try restoredContext.fetch(FetchDescriptor<Source>(
            predicate: #Predicate<Source> { $0.deletedAt == nil }
        ))
        let quotations = try restoredContext.fetch(FetchDescriptor<Quotation>(
            predicate: #Predicate<Quotation> { $0.deletedAt == nil }
        ))

        XCTAssertEqual(authors.count, 1)
        XCTAssertEqual(authors.first?.name, "Seneca")
        XCTAssertEqual(sources.count, 1)
        XCTAssertEqual(sources.first?.title, "Letters")
        XCTAssertEqual(quotations.count, 1)
    }

    func testSafetyBackupFlagIsStoredInMetadata() throws {
        let backup = try manager.createBackup(isSafetyBackup: true)
        let reloaded = BackupManager.listBackups(in: backupsDirectory).first { $0.id == backup.id }

        XCTAssertEqual(reloaded?.isSafetyBackup, true)
    }

    func testCreateBackupWithoutStoreThrows() throws {
        let missingStoreURL = tempDirectory.appendingPathComponent("missing.store")
        let emptyManager = BackupManager(storeURL: missingStoreURL, backupsDirectory: backupsDirectory)

        XCTAssertThrowsError(try emptyManager.createBackup()) { error in
            XCTAssertEqual(error as? BackupError, .storeFileMissing)
        }
    }
}
