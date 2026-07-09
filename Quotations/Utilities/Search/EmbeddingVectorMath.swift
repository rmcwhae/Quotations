//
//  EmbeddingVectorMath.swift
//  Quotations
//

import Foundation

enum EmbeddingVectorMath {
    static func cosineSimilarity(_ lhs: [Double], _ rhs: [Double]) -> Double {
        guard lhs.count == rhs.count, !lhs.isEmpty else { return 0 }
        var dot = 0.0
        var lhsNorm = 0.0
        var rhsNorm = 0.0
        for index in lhs.indices {
            dot += lhs[index] * rhs[index]
            lhsNorm += lhs[index] * lhs[index]
            rhsNorm += rhs[index] * rhs[index]
        }
        let denominator = (lhsNorm.squareRoot() * rhsNorm.squareRoot())
        guard denominator > 0 else { return 0 }
        return dot / denominator
    }
}
