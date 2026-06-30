//
//  AppleBooksImportTests.swift
//  QuotationsTests
//

import SQLite3
import SwiftData
import XCTest
@testable import Quotations

final class AppleBooksImportTests: XCTestCase {
    private var tempDirectory: URL!
    private var storeURL: URL!
    private var backupsDirectory: URL!
    private var container: ModelContainer!
    private var context: ModelContext!
    private var backupManager: BackupManager!

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
        backupManager = BackupManager(storeURL: storeURL, backupsDirectory: backupsDirectory)
    }

    override func tearDownWithError() throws {
        backupManager = nil
        context = nil
        container = nil
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil
        storeURL = nil
        backupsDirectory = nil
    }

    func testImportRowsCreatesModelsWithDateRead() throws {
        let finishedDate = Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 15))!
        let rows = [
            AppleBooksHighlightRow(
                annotationUUID: "ann-1",
                assetID: "asset-1",
                selectedText: "A memorable passage.",
                note: nil,
                location: "epubcfi(/6/2!/4/10,:0,:12)",
                bookTitle: "Test Book",
                authorName: "Test Author",
                dateFinishedSeconds: finishedDate.timeIntervalSinceReferenceDate
            )
        ]

        let result = try AppleBooksImportService.importRows(
            rows,
            into: context,
            backupManager: backupManager
        )

        XCTAssertEqual(result.importedAuthors, 1)
        XCTAssertEqual(result.importedSources, 1)
        XCTAssertEqual(result.importedQuotations, 1)
        XCTAssertEqual(result.skippedDuplicates, 0)

        let sources = try context.fetch(FetchDescriptor<Source>(
            predicate: #Predicate<Source> { $0.deletedAt == nil }
        ))
        XCTAssertEqual(sources.count, 1)
        XCTAssertEqual(sources.first?.title, "Test Book")
        XCTAssertEqual(sources.first?.sourceFormat, .appleBooks)
        XCTAssertEqual(sources.first?.dateReadMonth, 3)
        XCTAssertEqual(sources.first?.dateReadYear, 2024)
        XCTAssertEqual(
            sources.first?.externalIdentifier,
            AppleBooksImportService.sourceExternalIdentifier(for: "asset-1")
        )

        let quotations = try context.fetch(FetchDescriptor<Quotation>(
            predicate: #Predicate<Quotation> { $0.deletedAt == nil }
        ))
        XCTAssertEqual(quotations.count, 1)
        XCTAssertEqual(quotations.first?.content, "A memorable passage.")
        XCTAssertEqual(quotations.first?.location, "epubcfi(/6/2!/4/10,:0,:12)")
        XCTAssertEqual(
            quotations.first?.externalIdentifier,
            AppleBooksImportService.quotationExternalIdentifier(for: "ann-1")
        )
    }

    func testImportRowsSkipsDuplicateQuotations() throws {
        let row = AppleBooksHighlightRow(
            annotationUUID: "ann-dup",
            assetID: "asset-dup",
            selectedText: "Repeated highlight.",
            note: nil,
            location: nil,
            bookTitle: "Duplicate Book",
            authorName: "Same Author",
            dateFinishedSeconds: nil
        )

        _ = try AppleBooksImportService.importRows([row], into: context, backupManager: backupManager)
        let second = try AppleBooksImportService.importRows([row], into: context, backupManager: backupManager)

        XCTAssertEqual(second.importedQuotations, 0)
        XCTAssertEqual(second.skippedDuplicates, 1)

        let quotations = try context.fetch(FetchDescriptor<Quotation>(
            predicate: #Predicate<Quotation> { $0.deletedAt == nil }
        ))
        XCTAssertEqual(quotations.count, 1)
    }

    func testImportRowsAppendsNoteToContent() throws {
        let row = AppleBooksHighlightRow(
            annotationUUID: "ann-note",
            assetID: "asset-note",
            selectedText: "Highlighted text.",
            note: "My note",
            location: nil,
            bookTitle: "Notes Book",
            authorName: "Note Author",
            dateFinishedSeconds: nil
        )

        _ = try AppleBooksImportService.importRows([row], into: context, backupManager: backupManager)

        let quotations = try context.fetch(FetchDescriptor<Quotation>(
            predicate: #Predicate<Quotation> { $0.deletedAt == nil }
        ))
        XCTAssertEqual(quotations.first?.content, "Highlighted text.\n\n— My note")
    }

    func testSQLiteReaderReadsFixtureDatabases() throws {
        let fixtureDirectory = tempDirectory.appendingPathComponent("AppleBooksFixture", isDirectory: true)
        try FileManager.default.createDirectory(at: fixtureDirectory, withIntermediateDirectories: true)

        let annotationURL = fixtureDirectory.appendingPathComponent("AEAnnotation_test.sqlite")
        let libraryURL = fixtureDirectory.appendingPathComponent("BKLibrary_test.sqlite")
        try AppleBooksTestFixtures.write(annotationDatabase: annotationURL, libraryDatabase: libraryURL)

        let rows = try AppleBooksSQLiteReader.readHighlights(
            annotationDatabase: annotationURL,
            libraryDatabase: libraryURL
        )

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.bookTitle, "Fixture Book")
        XCTAssertEqual(rows.first?.selectedText, "Fixture highlight.")
        XCTAssertEqual(rows.first?.authorName, "Fixture Author")
    }
}

private enum AppleBooksTestFixtures {
    static func write(annotationDatabase: URL, libraryDatabase: URL) throws {
        try writeLibraryDatabase(at: libraryDatabase)
        try writeAnnotationDatabase(at: annotationDatabase)
    }

    private static func writeLibraryDatabase(at url: URL) throws {
        var database: OpaquePointer?
        guard sqlite3_open(url.path, &database) == SQLITE_OK, let database else {
            throw NSError(domain: "AppleBooksTestFixtures", code: 1)
        }
        defer { sqlite3_close(database) }

        try execute(database, sql: """
        CREATE TABLE ZBKLIBRARYASSET (
            ZASSETID TEXT,
            ZTITLE TEXT,
            ZAUTHOR TEXT,
            ZDATEFINISHED REAL
        );
        INSERT INTO ZBKLIBRARYASSET VALUES (
            'fixture-asset',
            'Fixture Book',
            'Fixture Author',
            700000000
        );
        """)
    }

    private static func writeAnnotationDatabase(at url: URL) throws {
        var database: OpaquePointer?
        guard sqlite3_open(url.path, &database) == SQLITE_OK, let database else {
            throw NSError(domain: "AppleBooksTestFixtures", code: 2)
        }
        defer { sqlite3_close(database) }

        try execute(database, sql: """
        CREATE TABLE ZAEANNOTATION (
            ZANNOTATIONUUID TEXT,
            ZANNOTATIONASSETID TEXT,
            ZANNOTATIONSELECTEDTEXT TEXT,
            ZANNOTATIONNOTE TEXT,
            ZANNOTATIONLOCATION TEXT,
            ZANNOTATIONDELETED INTEGER,
            ZANNOTATIONCREATIONDATE REAL
        );
        INSERT INTO ZAEANNOTATION VALUES (
            'fixture-annotation',
            'fixture-asset',
            'Fixture highlight.',
            NULL,
            'epubcfi(/6/1)',
            0,
            0
        );
        """)
    }

    private static func execute(_ database: OpaquePointer, sql: String) throws {
        if sqlite3_exec(database, sql, nil, nil, nil) != SQLITE_OK {
            let message = String(cString: sqlite3_errmsg(database))
            throw NSError(domain: "AppleBooksTestFixtures", code: 3, userInfo: [
                NSLocalizedDescriptionKey: message
            ])
        }
    }
}
