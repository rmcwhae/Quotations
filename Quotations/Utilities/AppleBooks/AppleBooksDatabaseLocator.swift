//
//  AppleBooksDatabaseLocator.swift
//  Quotations
//

import AppKit
import Foundation
import UniformTypeIdentifiers

struct AppleBooksDatabasePaths: Equatable {
    let annotationDatabase: URL
    let libraryDatabase: URL
}

enum AppleBooksDatabaseLocator {
    private static let containerRelativePath =
        "Library/Containers/com.apple.iBooksX/Data/Documents"

    static func defaultPaths() -> AppleBooksDatabasePaths? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let documents = home.appendingPathComponent(containerRelativePath, isDirectory: true)
        guard let annotation = newestSQLite(
            in: documents.appendingPathComponent("AEAnnotation", isDirectory: true),
            matching: "AEAnnotation"
        ),
        let library = newestSQLite(
            in: documents.appendingPathComponent("BKLibrary", isDirectory: true),
            matching: "BKLibrary"
        ) else {
            return nil
        }
        return AppleBooksDatabasePaths(annotationDatabase: annotation, libraryDatabase: library)
    }

    @MainActor
    static func locateOrPrompt() throws -> AppleBooksDatabasePaths {
        if let paths = defaultPaths(),
           FileManager.default.isReadableFile(atPath: paths.annotationDatabase.path),
           FileManager.default.isReadableFile(atPath: paths.libraryDatabase.path) {
            return paths
        }

        guard let annotationURL = promptForAnnotationDatabase() else {
            throw AppleBooksImportError.userCancelled
        }

        if let libraryURL = inferLibraryDatabase(near: annotationURL),
           FileManager.default.isReadableFile(atPath: libraryURL.path) {
            return AppleBooksDatabasePaths(
                annotationDatabase: annotationURL,
                libraryDatabase: libraryURL
            )
        }

        guard let libraryURL = promptForLibraryDatabase() else {
            throw AppleBooksImportError.userCancelled
        }

        return AppleBooksDatabasePaths(
            annotationDatabase: annotationURL,
            libraryDatabase: libraryURL
        )
    }

    static func inferLibraryDatabase(near annotationURL: URL) -> URL? {
        let documents = annotationURL.deletingLastPathComponent().deletingLastPathComponent()
        return newestSQLite(
            in: documents.appendingPathComponent("BKLibrary", isDirectory: true),
            matching: "BKLibrary"
        )
    }

    private static func newestSQLite(in directory: URL, matching prefix: String) -> URL? {
        let fileManager = FileManager.default
        guard let entries = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        return entries
            .filter { url in
                url.pathExtension == "sqlite" && url.lastPathComponent.hasPrefix(prefix)
            }
            .max { modificationDate(of: $0) < modificationDate(of: $1) }
    }

    private static func modificationDate(of url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
    }

    /// `.sqlite` files do not reliably conform to `UTType.database`, which greys them out
    /// in the open panel. Match by extension and fall back to generic data/item types.
    private static var sqliteContentTypes: [UTType] {
        var types: [UTType] = []
        if let sqlite = UTType(filenameExtension: "sqlite") {
            types.append(sqlite)
        }
        types.append(contentsOf: [.database, .data, .item])
        return types
    }

    @MainActor
    private static func promptForAnnotationDatabase() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose Apple Books Annotation Database"
        panel.message = "Select the AEAnnotation_*.sqlite file from Apple Books."
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = sqliteContentTypes
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(containerRelativePath, isDirectory: true)
            .appendingPathComponent("AEAnnotation", isDirectory: true)

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return url
    }

    @MainActor
    private static func promptForLibraryDatabase() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose Apple Books Library Database"
        panel.message = "Select the BKLibrary-*.sqlite file from Apple Books."
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = sqliteContentTypes

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return url
    }
}
