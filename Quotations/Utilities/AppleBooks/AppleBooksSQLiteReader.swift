//
//  AppleBooksSQLiteReader.swift
//  Quotations
//

import Foundation
import SQLite3

enum AppleBooksSQLiteReader {
    private static let transientDestructor = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    private static let highlightsQuery = """
    SELECT
        a.ZANNOTATIONUUID,
        a.ZANNOTATIONASSETID,
        a.ZANNOTATIONSELECTEDTEXT,
        a.ZANNOTATIONNOTE,
        a.ZANNOTATIONLOCATION,
        b.ZTITLE,
        b.ZAUTHOR,
        b.ZDATEFINISHED
    FROM ZAEANNOTATION a
    JOIN lib.ZBKLIBRARYASSET b ON a.ZANNOTATIONASSETID = b.ZASSETID
    WHERE a.ZANNOTATIONDELETED = 0
      AND a.ZANNOTATIONSELECTEDTEXT IS NOT NULL
      AND length(a.ZANNOTATIONSELECTEDTEXT) > 0
    ORDER BY b.ZTITLE, a.ZANNOTATIONCREATIONDATE
    """

    static func readHighlights(
        annotationDatabase: URL,
        libraryDatabase: URL
    ) throws -> [AppleBooksHighlightRow] {
        // Files chosen via the open panel are sandbox security-scoped; opening them
        // (and reading the attached library) requires holding the scope.
        let annotationScoped = annotationDatabase.startAccessingSecurityScopedResource()
        defer { if annotationScoped { annotationDatabase.stopAccessingSecurityScopedResource() } }
        let libraryScoped = libraryDatabase.startAccessingSecurityScopedResource()
        defer { if libraryScoped { libraryDatabase.stopAccessingSecurityScopedResource() } }

        // Apple Books keeps recent highlights in the -wal file. Copy each database with its
        // sidecars so SQLite can read them without `immutable=1` (which ignores the WAL)
        // and without touching the live files.
        let workDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppleBooksImport-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: workDirectory) }
        let annotationCopy = try copyDatabase(
            annotationDatabase,
            into: workDirectory.appendingPathComponent("annotation", isDirectory: true),
            failure: .annotationDatabaseUnreadable
        )
        let libraryCopy = try copyDatabase(
            libraryDatabase,
            into: workDirectory.appendingPathComponent("library", isDirectory: true),
            failure: .libraryDatabaseUnreadable
        )

        var database: OpaquePointer?
        guard sqlite3_open_v2(annotationCopy.path, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
              let database else {
            sqlite3_close(database)
            throw AppleBooksImportError.annotationDatabaseUnreadable
        }
        defer { sqlite3_close(database) }

        try attachLibrary(libraryCopy, to: database)

        var queryStmt: OpaquePointer?
        guard sqlite3_prepare_v2(database, highlightsQuery, -1, &queryStmt, nil) == SQLITE_OK,
              let queryStmt else {
            throw AppleBooksImportError.annotationDatabaseUnreadable
        }
        defer { sqlite3_finalize(queryStmt) }

        var rows: [AppleBooksHighlightRow] = []
        var rc = sqlite3_step(queryStmt)
        while rc == SQLITE_ROW {
            if let row = makeRow(from: queryStmt) {
                rows.append(row)
            }
            rc = sqlite3_step(queryStmt)
        }
        guard rc == SQLITE_DONE else {
            throw AppleBooksImportError.importFailed(String(cString: sqlite3_errmsg(database)))
        }
        return rows
    }

    /// Copies `url` and any `-wal`/`-shm` sidecars into `directory`. Sidecars are copied only
    /// as a pair (the sandbox may not grant access to them); without them the main file is
    /// still a consistent, if possibly older, snapshot.
    private static func copyDatabase(
        _ url: URL,
        into directory: URL,
        failure: AppleBooksImportError
    ) throws -> URL {
        let fileManager = FileManager.default
        let destination = directory.appendingPathComponent(url.lastPathComponent)
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try fileManager.copyItem(at: url, to: destination)
        } catch {
            throw failure
        }

        let sidecars = ["-wal", "-shm"].map { suffix in
            (URL(fileURLWithPath: url.path + suffix), URL(fileURLWithPath: destination.path + suffix))
        }
        do {
            for (source, target) in sidecars where fileManager.fileExists(atPath: source.path) {
                try fileManager.copyItem(at: source, to: target)
            }
        } catch {
            for (_, target) in sidecars {
                try? fileManager.removeItem(at: target)
            }
        }
        return destination
    }

    private static func attachLibrary(_ libraryDatabase: URL, to database: OpaquePointer) throws {
        var attachStmt: OpaquePointer?
        guard sqlite3_prepare_v2(database, "ATTACH DATABASE ? AS lib", -1, &attachStmt, nil) == SQLITE_OK,
              let attachStmt else {
            throw AppleBooksImportError.annotationDatabaseUnreadable
        }
        defer { sqlite3_finalize(attachStmt) }

        sqlite3_bind_text(attachStmt, 1, libraryDatabase.path, -1, transientDestructor)
        guard sqlite3_step(attachStmt) == SQLITE_DONE else {
            throw AppleBooksImportError.libraryDatabaseUnreadable
        }
    }

    private static func makeRow(from statement: OpaquePointer) -> AppleBooksHighlightRow? {
        guard let uuid = columnText(statement, index: 0),
              let assetID = columnText(statement, index: 1),
              let selectedText = columnText(statement, index: 2) else {
            return nil
        }
        let trimmed = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let title = columnText(statement, index: 5)?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let title, !title.isEmpty else { return nil }

        return AppleBooksHighlightRow(
            annotationUUID: uuid,
            assetID: assetID,
            selectedText: trimmed,
            note: columnText(statement, index: 3)?.trimmingCharacters(in: .whitespacesAndNewlines),
            location: columnText(statement, index: 4),
            bookTitle: title,
            authorName: columnText(statement, index: 6)?.trimmingCharacters(in: .whitespacesAndNewlines),
            dateFinishedSeconds: columnDouble(statement, index: 7)
        )
    }

    private static func columnText(_ statement: OpaquePointer, index: Int32) -> String? {
        guard let cString = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: cString)
    }

    private static func columnDouble(_ statement: OpaquePointer, index: Int32) -> Double? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else { return nil }
        return sqlite3_column_double(statement, index)
    }
}
