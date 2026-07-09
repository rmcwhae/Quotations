//
//  PrincipalComponentAnalysis.swift
//  Quotations
//

import CoreGraphics
import Foundation

enum PrincipalComponentAnalysis {
    /// Projects high-dimensional vectors to 2D using power iteration for the top two principal components.
    static func project2D(vectors: [[Double]]) -> [CGPoint] {
        guard !vectors.isEmpty, !vectors[0].isEmpty else { return [] }
        let dimension = vectors[0].count
        guard vectors.allSatisfy({ $0.count == dimension }) else { return [] }

        let count = vectors.count
        if count == 1 {
            return [.zero]
        }

        var means = Array(repeating: 0.0, count: dimension)
        for vector in vectors {
            for index in vectors[0].indices {
                means[index] += vector[index]
            }
        }
        means = means.map { $0 / Double(count) }

        var centered: [[Double]] = vectors.map { vector in
            zip(vector, means).map { $0 - $1 }
        }

        func powerComponent(deflateAgainst: [Double]?) -> [Double] {
            var component = (0..<dimension).map { _ in Double.random(in: -1...1) }
            normalize(&component)

            if let deflateAgainst {
                orthogonalize(&component, against: deflateAgainst)
                normalize(&component)
            }

            for _ in 0..<32 {
                var next = Array(repeating: 0.0, count: dimension)
                for row in centered {
                    let projection = dot(row, component)
                    for index in next.indices {
                        next[index] += projection * row[index]
                    }
                }
                component = next
                if let deflateAgainst {
                    orthogonalize(&component, against: deflateAgainst)
                }
                normalize(&component)
            }
            return component
        }

        let first = powerComponent(deflateAgainst: nil)
        let second = powerComponent(deflateAgainst: first)

        return centered.map { row in
            CGPoint(x: dot(row, first), y: dot(row, second))
        }
    }

    private static func dot(_ lhs: [Double], _ rhs: [Double]) -> Double {
        zip(lhs, rhs).reduce(0) { $0 + $1.0 * $1.1 }
    }

    private static func normalize(_ vector: inout [Double]) {
        let magnitude = vector.reduce(0) { $0 + $1 * $1 }.squareRoot()
        guard magnitude > 0 else { return }
        vector = vector.map { $0 / magnitude }
    }

    private static func orthogonalize(_ vector: inout [Double], against reference: [Double]) {
        let projection = dot(vector, reference)
        for index in vector.indices {
            vector[index] -= projection * reference[index]
        }
    }
}
