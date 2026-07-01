//
//  QuotationCSVRealFileTests.swift
//  QuotationsTests
//

import XCTest
@testable import Quotations

final class QuotationCSVRealFileTests: XCTestCase {
  func testParseImportQuotationsCSV() throws {
    let url = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("import/quotations.csv")
    guard FileManager.default.fileExists(atPath: url.path) else {
      throw XCTSkip("import/quotations.csv not present")
    }
    let data = try Data(contentsOf: url)
    let recordCount = try QuotationCSVParser.debugRecordCount(data: data)
    let rows = try QuotationCSVParser.parse(data: data)
    let nonempty = rows.filter { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    XCTAssertGreaterThan(nonempty.count, 30, "records=\(recordCount) rows=\(rows.count)")
  }
}
