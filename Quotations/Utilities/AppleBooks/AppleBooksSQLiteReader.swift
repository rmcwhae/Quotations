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

        let database = try openAnnotationDatabase(at: annotationDatabase)
        defer { sqlite3_close(database) }

        try attachLibrary(libraryDatabase, to: database)

        var queryStmt: OpaquePointer?
        guard sqlite3_prepare_v2(database, highlightsQuery, -1, &queryStmt, nil) == SQLITE_OK,
              let queryStmt else {
            throw AppleBooksImportError.annotationDatabaseUnreadable
        }
        defer { sqlite3_finalize(queryStmt) }

        var rows: [AppleBooksHighlightRow] = []
        while sqlite3_step(queryStmt) == SQLITE_ROW {
            if let row = makeRow(from: queryStmt) {
                rows.append(row)
            }
        }
        return rows
    }

    private static func openAnnotationDatabase(at url: URL) throws -> OpaquePointer {
        var database: OpaquePointer?
        // `immutable=1` reads the file without touching the -wal/-shm sidecar files,
        // which the sandbox does not grant access to when only the .sqlite is chosen.
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_URI
        guard sqlite3_open_v2(immutableURI(for: url), &database, flags, nil) == SQLITE_OK,
              let database else {
            throw AppleBooksImportError.annotationDatabaseUnreadable
        }
        return database
    }

    private static func attachLibrary(_ libraryDatabase: URL, to database: OpaquePointer) throws {
        var attachStmt: OpaquePointer?
        guard sqlite3_prepare_v2(database, "ATTACH DATABASE ? AS lib", -1, &attachStmt, nil) == SQLITE_OK,
              let attachStmt else {
            throw AppleBooksImportError.annotationDatabaseUnreadable
        }
        defer { sqlite3_finalize(attachStmt) }

        sqlite3_bind_text(attachStmt, 1, immutableURI(for: libraryDatabase), -1, transientDestructor)
        guard sqlite3_step(attachStmt) == SQLITE_DONE else {
            throw AppleBooksImportError.libraryDatabaseUnreadable
        }
    }

    /// Builds a SQLite `file:` URI with `immutable=1`, percent-encoding the path.
    private static func immutableURI(for url: URL) -> String {
        var components = URLComponents()
        components.scheme = "file"
        components.path = url.path
        components.queryItems = [URLQueryItem(name: "immutable", value: "1")]
        return components.string ?? "file:\(url.path)?immutable=1"
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
