//
//  SemanticClusterAnalyzer.swift
//  Quotations
//

import CoreGraphics
import Foundation
import SwiftData

struct SemanticClusterPoint: Identifiable, Hashable {
    let quotationId: PersistentIdentifier
    let sourceId: PersistentIdentifier?
    let position: CGPoint
    let clusterIndex: Int
    let clusterLabel: String

    var id: PersistentIdentifier { quotationId }
}

struct SemanticClusterResult: Equatable {
    let points: [SemanticClusterPoint]
    let clusterCount: Int
}

enum SemanticClusterAnalyzer {
    static func analyze(
        quotations: [Quotation],
        entries: [EmbeddingIndexEntry]
    ) -> SemanticClusterResult? {
        let active = quotations.filter { $0.deletedAt == nil }
        guard active.count >= 2 else { return nil }

        let entryMap = Dictionary(uniqueKeysWithValues: entries.map { ($0.encodedQuotationID, $0) })
        var items: [(quotation: Quotation, vector: [Double])] = []

        for quotation in active {
            guard let encoded = QuotationDeepLink.encode(quotation.persistentModelID),
                  let entry = entryMap[encoded] else {
                continue
            }
            items.append((quotation, entry.vector))
        }

        guard items.count >= 2 else { return nil }

        let vectors = items.map(\.vector)
        let positions = PrincipalComponentAnalysis.project2D(vectors: vectors)
        let clusterCount = KMeansClustering.recommendedClusterCount(for: positions.count)
        let assignments = KMeansClustering.cluster(points: positions, k: clusterCount)

        var quotationsByCluster: [Int: [Quotation]] = [:]
        for (index, assignment) in assignments.enumerated() {
            quotationsByCluster[assignment, default: []].append(items[index].quotation)
        }

        var labels: [Int: String] = [:]
        for (cluster, clusterQuotations) in quotationsByCluster {
            let words = WordFrequencyAnalyzer.topWords(in: clusterQuotations, limit: 3)
            labels[cluster] = words.isEmpty ? "Theme \(cluster + 1)" : words.joined(separator: ", ")
        }

        let points = zip(zip(positions, assignments), items).map { pair, item in
            let (position, clusterIndex) = pair
            return SemanticClusterPoint(
                quotationId: item.quotation.persistentModelID,
                sourceId: item.quotation.source?.persistentModelID,
                position: position,
                clusterIndex: clusterIndex,
                clusterLabel: labels[clusterIndex] ?? "Theme \(clusterIndex + 1)"
            )
        }

        return SemanticClusterResult(points: points, clusterCount: clusterCount)
    }
}
