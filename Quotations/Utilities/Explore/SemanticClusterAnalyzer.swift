//
//  SemanticClusterAnalyzer.swift
//  Quotations
//

import CoreGraphics
import Foundation
import SwiftData

nonisolated struct SemanticClusterPoint: Identifiable, Hashable, Sendable {
    let quotationId: PersistentIdentifier
    let sourceId: PersistentIdentifier?
    let position: CGPoint
    let clusterIndex: Int
    let clusterLabel: String

    var id: PersistentIdentifier { quotationId }
}

nonisolated struct SemanticClusterResult: Equatable, Sendable {
    let points: [SemanticClusterPoint]
    let clusterCount: Int
}

/// Plain-value snapshot of a quotation for off-main-actor clustering.
nonisolated struct SemanticClusterInput: Sendable {
    let encodedQuotationID: String
    let quotationId: PersistentIdentifier
    let sourceId: PersistentIdentifier?
    let plainText: String
}

nonisolated enum SemanticClusterAnalyzer {
    /// Main-actor convenience: snapshots live models, then analyzes.
    @MainActor
    static func analyze(
        quotations: [Quotation],
        entries: [EmbeddingIndexEntry],
        stopwords: Set<String>
    ) -> SemanticClusterResult? {
        analyze(
            inputs: inputs(for: quotations),
            vectorsByEncodedID: vectorsByEncodedID(entries),
            stopwords: stopwords
        )
    }

    /// Snapshots non-deleted quotations that have an encodable ID.
    @MainActor
    static func inputs(for quotations: [Quotation]) -> [SemanticClusterInput] {
        quotations.compactMap { quotation in
            guard quotation.deletedAt == nil,
                  let encoded = QuotationDeepLink.encode(quotation.persistentModelID) else {
                return nil
            }
            return SemanticClusterInput(
                encodedQuotationID: encoded,
                quotationId: quotation.persistentModelID,
                sourceId: quotation.source?.persistentModelID,
                plainText: QuotationSearchText.plainContent(from: quotation.content)
            )
        }
    }

    @MainActor
    static func vectorsByEncodedID(_ entries: [EmbeddingIndexEntry]) -> [String: [Double]] {
        Dictionary(uniqueKeysWithValues: entries.map { ($0.encodedQuotationID, $0.vector) })
    }

    /// Pure PCA + k-means analysis; safe to run off the main actor.
    static func analyze(
        inputs: [SemanticClusterInput],
        vectorsByEncodedID: [String: [Double]],
        stopwords: Set<String>
    ) -> SemanticClusterResult? {
        guard inputs.count >= 2 else { return nil }

        var items: [(input: SemanticClusterInput, vector: [Double])] = []
        for input in inputs {
            guard let vector = vectorsByEncodedID[input.encodedQuotationID] else { continue }
            items.append((input, vector))
        }

        guard items.count >= 2 else { return nil }

        let vectors = items.map(\.vector)
        let positions = PrincipalComponentAnalysis.project2D(vectors: vectors)
        let clusterCount = KMeansClustering.recommendedClusterCount(for: positions.count)
        let assignments = KMeansClustering.cluster(points: positions, clusterCount: clusterCount)

        var textsByCluster: [Int: [String]] = [:]
        for (index, assignment) in assignments.enumerated() {
            textsByCluster[assignment, default: []].append(items[index].input.plainText)
        }

        var labels: [Int: String] = [:]
        for (cluster, clusterTexts) in textsByCluster {
            let words = WordFrequencyAnalyzer.topWords(in: clusterTexts, limit: 3, stopwords: stopwords)
            labels[cluster] = words.isEmpty ? "Theme \(cluster + 1)" : words.joined(separator: ", ")
        }

        let points = zip(zip(positions, assignments), items).map { pair, item in
            let (position, clusterIndex) = pair
            return SemanticClusterPoint(
                quotationId: item.input.quotationId,
                sourceId: item.input.sourceId,
                position: position,
                clusterIndex: clusterIndex,
                clusterLabel: labels[clusterIndex] ?? "Theme \(clusterIndex + 1)"
            )
        }

        return SemanticClusterResult(points: points, clusterCount: clusterCount)
    }
}
