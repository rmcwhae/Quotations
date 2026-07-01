//
//  QuotationCSVImportTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

final class QuotationCSVImportTests: XCTestCase {
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

  func testParserReadsQuotedFieldsAndEmbeddedNewlines() throws {
    let csv = """
    content,location,source_image
    "Line one
    continues",p. 12,IMG_0001.PNG
    Plain text,,
    """

    let rows = try QuotationCSVParser.parse(data: Data(csv.utf8))
    XCTAssertEqual(rows.count, 2)
    XCTAssertEqual(rows[0].content, "Line one\ncontinues")
    XCTAssertEqual(rows[0].location, "p. 12")
    XCTAssertEqual(rows[0].sourceImage, "IMG_0001.PNG")
    XCTAssertEqual(rows[1].content, "Plain text")
    XCTAssertNil(rows[1].location)
  }

  func testParserRequiresContentHeader() {
    let csv = "location,source_image\n,p. 1,IMG.PNG\n"
    XCTAssertThrowsError(try QuotationCSVParser.parse(data: Data(csv.utf8))) { error in
      XCTAssertEqual(error as? QuotationCSVImportError, .invalidFormat("CSV must include a content column."))
    }
  }

  func testImportCreatesQuotationsOnTargetSourceOnly() throws {
    let author = Author(name: "Test Author")
    let target = Source(title: "Target Book", author: author)
    let other = Source(title: "Other Book", author: author)
    context.insert(author)
    context.insert(target)
    context.insert(other)
    try context.save()

    let csvURL = tempDirectory.appendingPathComponent("import.csv")
    let csv = """
    content,location
    First quotation,p. 1
    Second quotation,
    """
    try csv.write(to: csvURL, atomically: true, encoding: .utf8)

    let result = try QuotationCSVImportService.importCSV(
      url: csvURL,
      into: target,
      modelContext: context,
      backupManager: backupManager
    )

    XCTAssertEqual(result.importedQuotations, 2)
    XCTAssertEqual(result.skippedDuplicates, 0)
    XCTAssertEqual(result.skippedEmpty, 0)

    let quotations = try context.fetch(FetchDescriptor<Quotation>(
      predicate: #Predicate<Quotation> { $0.deletedAt == nil }
    ))
    XCTAssertEqual(quotations.count, 2)
    XCTAssertTrue(quotations.allSatisfy { $0.source?.persistentModelID == target.persistentModelID })
    XCTAssertEqual(
      quotations.first { $0.content == "First quotation" }?.location,
      "p. 1"
    )
  }

  func testParserReadsImportFixture() throws {
    let csv = """
    content,location
    Already here,
    New quotation,p. 2
    "   ",
    """
    let rows = try QuotationCSVParser.parse(data: Data(csv.utf8))
    XCTAssertEqual(rows.count, 2)
    XCTAssertEqual(rows[0].content, "Already here")
    XCTAssertEqual(rows[1].content, "New quotation")
    XCTAssertEqual(rows[1].location, "p. 2")
  }

  func testImportSkipsDuplicateAndEmptyRows() throws {
    let author = Author(name: "Test Author")
    let source = Source(title: "Target Book", author: author)
    context.insert(author)
    context.insert(source)
    let existing = Quotation(content: "Already here", source: source)
    context.insert(existing)
    try context.save()

    let csv = """
    content,location
    Already here,
    New quotation,p. 2
    "   ",
    """
    let rows = try QuotationCSVParser.parse(data: Data(csv.utf8))
    XCTAssertEqual(rows.count, 2)

    let existingQuotations = try context.fetch(FetchDescriptor<Quotation>(
      predicate: #Predicate<Quotation> { $0.deletedAt == nil }
    ))
    XCTAssertEqual(existingQuotations.count, 1)

    let result = try QuotationCSVImportService.importRows(
      rows,
      into: source,
      modelContext: context,
      backupManager: backupManager
    )

    XCTAssertEqual(result.importedQuotations, 1)
    XCTAssertEqual(result.skippedDuplicates, 1)
    XCTAssertEqual(result.skippedEmpty, 0)

    let quotations = try context.fetch(FetchDescriptor<Quotation>(
      predicate: #Predicate<Quotation> { $0.deletedAt == nil }
    ))
    XCTAssertEqual(quotations.count, 2)
    XCTAssertTrue(quotations.contains { $0.content == "New quotation" })
  }

  func testImportCSVReadsFile() throws {
    let author = Author(name: "Test Author")
    let source = Source(title: "Target Book", author: author)
    context.insert(author)
    context.insert(source)
    try context.save()

    let csvURL = tempDirectory.appendingPathComponent("import.csv")
    let csv = """
    content,location
    "Quoted from file",p. 9
    """
    try csv.write(to: csvURL, atomically: true, encoding: .utf8)

    let result = try QuotationCSVImportService.importCSV(
      url: csvURL,
      into: source,
      modelContext: context,
      backupManager: backupManager
    )

    XCTAssertEqual(result.importedQuotations, 1)
    let quotations = try context.fetch(FetchDescriptor<Quotation>(
      predicate: #Predicate<Quotation> { $0.deletedAt == nil }
    ))
    XCTAssertEqual(quotations.first?.content, "Quoted from file")
    XCTAssertEqual(quotations.first?.location, "p. 9")
  }
}
