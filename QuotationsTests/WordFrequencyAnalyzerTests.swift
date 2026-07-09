//
//  WordFrequencyAnalyzerTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

final class WordFrequencyAnalyzerTests: XCTestCase {
    func testCountsDistinctWordsAndIgnoresStopwords() {
        let quotation = Quotation(content: "The mountains are calling and the mountains echo freedom")
        let results = WordFrequencyAnalyzer.analyze(
            quotations: [quotation],
            minimumLength: 3,
            maximumEntries: 10
        )

        XCTAssertTrue(results.contains(where: { $0.word == "mountains" && $0.count == 2 }))
        XCTAssertFalse(results.contains(where: { $0.word == "the" }))
        XCTAssertFalse(results.contains(where: { $0.word == "and" }))
    }
}
