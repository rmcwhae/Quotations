//
//  KMeansClustering.swift
//  Quotations
//

import CoreGraphics
import Foundation

enum KMeansClustering {
    static func cluster(points: [CGPoint], k: Int, maxIterations: Int = 50) -> [Int] {
        guard !points.isEmpty else { return [] }
        let clusterCount = min(max(1, k), points.count)
        if clusterCount == 1 {
            return Array(repeating: 0, count: points.count)
        }

        var centroids = seededCentroids(from: points, k: clusterCount)
        var assignments = Array(repeating: 0, count: points.count)

        for _ in 0..<maxIterations {
            var changed = false
            for index in points.indices {
                let nearest = nearestCentroid(to: points[index], centroids: centroids)
                if assignments[index] != nearest {
                    assignments[index] = nearest
                    changed = true
                }
            }
            centroids = recomputeCentroids(points: points, assignments: assignments, k: clusterCount)
            if !changed { break }
        }

        return assignments
    }

    static func recommendedClusterCount(for pointCount: Int) -> Int {
        guard pointCount > 1 else { return 1 }
        return min(8, max(2, Int(Double(pointCount).squareRoot().rounded())))
    }

    private static func seededCentroids(from points: [CGPoint], k: Int) -> [CGPoint] {
        guard let first = points.first else { return [] }
        var centroids = [first]
        while centroids.count < k {
            let distances = points.map { point in
                centroids.map { distance(point, $0) }.min() ?? 0
            }
            guard let nextIndex = distances.enumerated().max(by: { $0.element < $1.element })?.offset else {
                break
            }
            centroids.append(points[nextIndex])
        }
        return centroids
    }

    private static func recomputeCentroids(points: [CGPoint], assignments: [Int], k: Int) -> [CGPoint] {
        var sums = Array(repeating: CGPoint.zero, count: k)
        var counts = Array(repeating: 0, count: k)

        for (point, cluster) in zip(points, assignments) {
            sums[cluster].x += point.x
            sums[cluster].y += point.y
            counts[cluster] += 1
        }

        return (0..<k).map { index in
            guard counts[index] > 0 else { return .zero }
            return CGPoint(
                x: sums[index].x / CGFloat(counts[index]),
                y: sums[index].y / CGFloat(counts[index])
            )
        }
    }

    private static func nearestCentroid(to point: CGPoint, centroids: [CGPoint]) -> Int {
        var bestIndex = 0
        var bestDistance = distance(point, centroids[0])
        for index in 1..<centroids.count {
            let candidate = distance(point, centroids[index])
            if candidate < bestDistance {
                bestDistance = candidate
                bestIndex = index
            }
        }
        return bestIndex
    }

    private static func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return dx * dx + dy * dy
    }
}
