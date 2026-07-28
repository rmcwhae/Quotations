//
//  KoboAnnotationsImportTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

final class KoboAnnotationsImportTests: XCTestCase {
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

    func testParserReadsSampleExport() throws {
        let text = try sampleExportText()
        let parsed = try KoboAnnotationsParser.parse(text: text)

        XCTAssertEqual(parsed.title, "Spirit-Controlled Temperament")
        XCTAssertEqual(parsed.author, "Tim LaHaye")
        XCTAssertEqual(parsed.expectedHighlightCount, 25)
        XCTAssertEqual(parsed.highlights.count, 25)
        XCTAssertEqual(parsed.highlights.first?.location, "Chapter 1")
        XCTAssertEqual(
            parsed.highlights.first?.content,
            "Some authorities suggest that we may get more genes from our grandparents than our parents"
        )

        let chapter4 = parsed.highlights.first { $0.location == "Chapter 4" }
        XCTAssertNotNil(chapter4)
        XCTAssertTrue(
            chapter4?.content.contains("strong-willed determination") == true
        )
    }

    func testParserRejectsEmptyAndInvalidFiles() {
        XCTAssertThrowsError(try KoboAnnotationsParser.parse(text: "   \n\n")) { error in
            XCTAssertEqual(error as? KoboAnnotationsImportError, .emptyFile)
        }

        XCTAssertThrowsError(
            try KoboAnnotationsParser.parse(text: "Only A Title\n\n")
        ) { error in
            XCTAssertEqual(
                error as? KoboAnnotationsImportError,
                .invalidFormat("Kobo export is missing an author name.")
            )
        }

        XCTAssertThrowsError(
            try KoboAnnotationsParser.parse(
                text: "A Book\n\nAn Author\n\n0 Highlights | Exported July 28, 2026\n"
            )
        ) { error in
            XCTAssertEqual(
                error as? KoboAnnotationsImportError,
                .invalidFormat("Kobo export does not contain any highlights.")
            )
        }
    }

    func testParserSupportsMultilineHighlightBodies() throws {
        let text = """
        Sample Title

        Sample Author

        1 Highlights | Exported July 28, 2026

        Chapter 2: Example

        Highlight (blue)
        First line
        Second line
        """

        let parsed = try KoboAnnotationsParser.parse(text: text)
        XCTAssertEqual(parsed.highlights.count, 1)
        XCTAssertEqual(parsed.highlights[0].location, "Chapter 2")
        XCTAssertEqual(parsed.highlights[0].content, "First line\nSecond line")
        XCTAssertEqual(parsed.highlights[0].highlightColor, "blue")
    }

    func testImportCreatesAuthorSourceAndQuotations() throws {
        let parsed = try KoboAnnotationsParser.parse(text: try sampleExportText())
        let result = try KoboAnnotationsImportService.importParsed(
            parsed,
            into: context,
            backupManager: backupManager
        )

        XCTAssertEqual(result.importedAuthors, 1)
        XCTAssertEqual(result.importedSources, 1)
        XCTAssertEqual(result.importedQuotations, 25)
        XCTAssertEqual(result.skippedDuplicates, 0)

        let authors = try context.fetch(FetchDescriptor<Author>(
            predicate: #Predicate<Author> { $0.deletedAt == nil }
        ))
        let sources = try context.fetch(FetchDescriptor<Source>(
            predicate: #Predicate<Source> { $0.deletedAt == nil }
        ))
        let quotations = try context.fetch(FetchDescriptor<Quotation>(
            predicate: #Predicate<Quotation> { $0.deletedAt == nil }
        ))

        XCTAssertEqual(authors.count, 1)
        XCTAssertEqual(authors[0].name, "Tim LaHaye")
        XCTAssertEqual(sources.count, 1)
        XCTAssertEqual(sources[0].title, "Spirit-Controlled Temperament")
        XCTAssertEqual(sources[0].format, SourceFormat.kobo.rawValue)
        XCTAssertNotNil(sources[0].externalIdentifier)
        XCTAssertEqual(quotations.count, 25)
        XCTAssertEqual(quotations.filter { $0.location == "Chapter 1" }.count, 1)
        XCTAssertFalse(quotations.filter { $0.location == "Chapter 4" }.isEmpty)
        XCTAssertTrue(quotations.allSatisfy { $0.externalIdentifier != nil })
    }

    func testReimportSkipsDuplicates() throws {
        let parsed = try KoboAnnotationsParser.parse(text: try sampleExportText())
        _ = try KoboAnnotationsImportService.importParsed(
            parsed,
            into: context,
            backupManager: backupManager
        )
        let second = try KoboAnnotationsImportService.importParsed(
            parsed,
            into: context,
            backupManager: backupManager
        )

        XCTAssertEqual(second.importedAuthors, 0)
        XCTAssertEqual(second.importedSources, 0)
        XCTAssertEqual(second.importedQuotations, 0)
        XCTAssertEqual(second.skippedDuplicates, 25)

        let quotations = try context.fetch(FetchDescriptor<Quotation>(
            predicate: #Predicate<Quotation> { $0.deletedAt == nil }
        ))
        XCTAssertEqual(quotations.count, 25)
    }

    func testImportFileFromURL() throws {
        let url = try sampleExportURL()
        let result = try KoboAnnotationsImportService.importFile(
            url: url,
            into: context,
            backupManager: backupManager
        )
        XCTAssertEqual(result.importedQuotations, 25)
        XCTAssertEqual(result.importedSources, 1)
    }

    private func sampleExportText() throws -> String {
        try String(contentsOf: sampleExportURL(), encoding: .utf8)
    }

    private func sampleExportURL() throws -> URL {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let url = testsDirectory
            .deletingLastPathComponent()
            .appendingPathComponent("import")
            .appendingPathComponent("annotations-export-20260728142456.txt")
        guard FileManager.default.fileExists(atPath: url.path) else {
            XCTFail("Missing sample export at \(url.path)")
            throw KoboAnnotationsImportError.readFailed("Sample export missing")
        }
        return url
    }
}
