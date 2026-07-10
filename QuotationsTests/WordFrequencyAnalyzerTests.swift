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
            maximumEntries: 10,
            stopwords: EnglishStopwords.defaultWords
        )

        XCTAssertTrue(results.contains(where: { $0.word == "mountains" && $0.count == 2 }))
        XCTAssertFalse(results.contains(where: { $0.word == "the" }))
        XCTAssertFalse(results.contains(where: { $0.word == "and" }))
    }

    func testCustomStopwordsExcludeAdditionalWords() {
        let quotation = Quotation(content: "Freedom echoes through the mountains")
        var stopwords = EnglishStopwords.defaultWords
        stopwords.insert("freedom")

        let results = WordFrequencyAnalyzer.analyze(
            quotations: [quotation],
            minimumLength: 3,
            maximumEntries: 10,
            stopwords: stopwords
        )

        XCTAssertFalse(results.contains(where: { $0.word == "freedom" }))
        XCTAssertTrue(results.contains(where: { $0.word == "mountains" }))
    }
}
