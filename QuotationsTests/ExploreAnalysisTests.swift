//
//  ExploreAnalysisTests.swift
//  QuotationsTests
//

import CoreGraphics
import SwiftData
import XCTest
@testable import Quotations

@MainActor
final class ExploreAnalysisTests: XCTestCase {
    func testPCAProducesOnePointPerVector() {
        let vectors = [
            [1.0, 0.0, 0.0],
            [0.0, 1.0, 0.0],
            [0.8, 0.2, 0.0]
        ]
        let points = PrincipalComponentAnalysis.project2D(vectors: vectors)
        XCTAssertEqual(points.count, 3)
    }

    func testKMeansAssignsEveryPoint() {
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 0.1, y: 0.1),
            CGPoint(x: 10, y: 10),
            CGPoint(x: 10.2, y: 9.8)
        ]
        let assignments = KMeansClustering.cluster(points: points, clusterCount: 2)
        XCTAssertEqual(assignments.count, 4)
        XCTAssertNotEqual(assignments[0], assignments[2])
    }

    func testSemanticClusterAnalyzerUsesPlainInputs() throws {
        let container = try ModelContainer(
            for: Author.self, Source.self, Quotation.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let quotations = [
            Quotation(content: "Mountains rise above valleys"),
            Quotation(content: "Mountains echo over valleys"),
            Quotation(content: "Oceans swallow the shoreline"),
            Quotation(content: "Oceans crash upon the shoreline")
        ]
        quotations.forEach(context.insert)
        try context.save()

        let inputs = SemanticClusterAnalyzer.inputs(for: quotations)
        XCTAssertEqual(inputs.count, 4)

        let vectors: [[Double]] = [[1, 0, 0], [0.9, 0.1, 0], [0, 0, 1], [0, 0.1, 0.9]]
        var vectorsByID: [String: [Double]] = [:]
        for (input, vector) in zip(inputs, vectors) {
            vectorsByID[input.encodedQuotationID] = vector
        }

        let result = try XCTUnwrap(SemanticClusterAnalyzer.analyze(
            inputs: inputs,
            vectorsByEncodedID: vectorsByID,
            stopwords: EnglishStopwords.defaultWords
        ))
        XCTAssertEqual(result.points.count, 4)
        XCTAssertEqual(Set(result.points.map(\.quotationId)), Set(quotations.map(\.persistentModelID)))
    }

    func testSemanticClusterAnalyzerNeedsTwoIndexedInputs() {
        XCTAssertNil(SemanticClusterAnalyzer.analyze(
            inputs: [],
            vectorsByEncodedID: [:],
            stopwords: []
        ))
    }
}
