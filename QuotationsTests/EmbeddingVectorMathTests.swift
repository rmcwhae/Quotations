//
//  EmbeddingVectorMathTests.swift
//  QuotationsTests
//

import XCTest
@testable import Quotations

final class EmbeddingVectorMathTests: XCTestCase {
    func testCosineSimilarityForIdenticalVectors() {
        let vector = [1.0, 0.0, 0.5]
        XCTAssertEqual(EmbeddingVectorMath.cosineSimilarity(vector, vector), 1.0, accuracy: 0.0001)
    }

    func testCosineSimilarityForOrthogonalVectors() {
        XCTAssertEqual(
            EmbeddingVectorMath.cosineSimilarity([1.0, 0.0], [0.0, 1.0]),
            0.0,
            accuracy: 0.0001
        )
    }
}
