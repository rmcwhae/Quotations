//
//  ExploreAnalysisTests.swift
//  QuotationsTests
//

import CoreGraphics
import XCTest
@testable import Quotations

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
        let assignments = KMeansClustering.cluster(points: points, k: 2)
        XCTAssertEqual(assignments.count, 4)
        XCTAssertNotEqual(assignments[0], assignments[2])
    }
}
