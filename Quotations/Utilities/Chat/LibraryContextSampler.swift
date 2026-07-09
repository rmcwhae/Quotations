//
//  LibraryContextSampler.swift
//  Quotations
//

import Foundation
import SwiftData

enum LibraryContextSampler {
    private static let topWordCount = 15
    private static let representativesPerCluster = 2
    private static let topAuthorCount = 8

    static func sample(
        quotations: [Quotation],
        entries: [EmbeddingIndexEntry]
    ) -> LibraryContextSample {
        let active = quotations.filter { $0.deletedAt == nil }
        let overviewHeader = makeOverviewHeader(for: active, entries: entries)
        let representativeIDs = representativeQuotationIDs(
            quotations: active,
            entries: entries,
            perCluster: representativesPerCluster
        )

        return LibraryContextSample(
            overviewHeader: overviewHeader,
            quotations: representativeIDs
        )
    }

    static func representativeQuotationIDs(
        quotations: [Quotation],
        entries: [EmbeddingIndexEntry],
        perCluster: Int
    ) -> [PersistentIdentifier] {
        let active = quotations.filter { $0.deletedAt == nil }
        guard !active.isEmpty else { return [] }

        let entryMap = Dictionary(uniqueKeysWithValues: entries.map { ($0.encodedQuotationID, $0) })
        var items: [(quotation: Quotation, vector: [Double])] = []

        for quotation in active {
            guard let encoded = QuotationDeepLink.encode(quotation.persistentModelID),
                  let entry = entryMap[encoded] else {
                continue
            }
            items.append((quotation, entry.vector))
        }

        guard items.count >= 2,
              let clusters = SemanticClusterAnalyzer.analyze(quotations: active, entries: entries) else {
            return active.prefix(min(12, active.count)).map(\.persistentModelID)
        }

        var quotationsByCluster: [Int: [(quotation: Quotation, vector: [Double])]] = [:]
        let quotationByID = Dictionary(uniqueKeysWithValues: items.map { ($0.quotation.persistentModelID, $0) })

        for point in clusters.points {
            guard let item = quotationByID[point.quotationId] else { continue }
            quotationsByCluster[point.clusterIndex, default: []].append(item)
        }

        var selected: [PersistentIdentifier] = []
        var seen = Set<PersistentIdentifier>()

        for clusterIndex in quotationsByCluster.keys.sorted() {
            guard let members = quotationsByCluster[clusterIndex], !members.isEmpty else { continue }
            let centroid = meanVector(members.map(\.vector))
            let ranked = members.sorted { lhs, rhs in
                let left = EmbeddingVectorMath.cosineSimilarity(lhs.vector, centroid)
                let right = EmbeddingVectorMath.cosineSimilarity(rhs.vector, centroid)
                return left > right
            }

            for member in ranked.prefix(perCluster) where seen.insert(member.quotation.persistentModelID).inserted {
                selected.append(member.quotation.persistentModelID)
            }
        }

        if selected.isEmpty {
            return active.prefix(min(12, active.count)).map(\.persistentModelID)
        }

        return selected
    }

    static func makeOverviewHeader(
        for quotations: [Quotation],
        entries: [EmbeddingIndexEntry] = []
    ) -> String {
        let active = quotations.filter { $0.deletedAt == nil }
        let sourceIds = Set(active.compactMap { $0.source?.id })
        let authorIds = Set(active.compactMap { $0.source?.author?.id })

        var lines = [
            "Library overview:",
            "- \(active.count) quotations",
            "- \(sourceIds.count) sources",
            "- \(authorIds.count) authors"
        ]

        let topWords = WordFrequencyAnalyzer.analyze(
            quotations: active,
            minimumLength: 3,
            maximumEntries: topWordCount
        )
        if !topWords.isEmpty {
            let words = topWords.map(\.word).joined(separator: ", ")
            lines.append("- Frequent words: \(words)")
        }

        let authorCounts = authorQuotationCounts(in: active)
        if !authorCounts.isEmpty {
            let authors = authorCounts
                .prefix(topAuthorCount)
                .map { "\($0.name) (\($0.count))" }
                .joined(separator: ", ")
            lines.append("- Authors by quotation count: \(authors)")
        }

        if let clusters = SemanticClusterAnalyzer.analyze(quotations: active, entries: entries),
           !clusters.points.isEmpty {
            let labels = Dictionary(grouping: clusters.points, by: \.clusterIndex)
                .sorted { $0.key < $1.key }
                .compactMap { _, points in points.first?.clusterLabel }
            if !labels.isEmpty {
                lines.append("- Semantic themes: \(labels.joined(separator: "; "))")
            }
        }

        return lines.joined(separator: "\n")
    }

    static func authorQuotationCounts(in quotations: [Quotation]) -> [(name: String, count: Int)] {
        var counts: [String: Int] = [:]

        for quotation in quotations {
            guard quotation.deletedAt == nil,
                  let author = quotation.source?.author,
                  author.deletedAt == nil else {
                continue
            }
            counts[author.name, default: 0] += 1
        }

        return counts
            .map { (name: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count { return lhs.name < rhs.name }
                return lhs.count > rhs.count
            }
    }

    private static func meanVector(_ vectors: [[Double]]) -> [Double] {
        guard let first = vectors.first, !first.isEmpty else { return [] }
        var sums = Array(repeating: 0.0, count: first.count)

        for vector in vectors where vector.count == first.count {
            for index in vector.indices {
                sums[index] += vector[index]
            }
        }

        let divisor = Double(vectors.count)
        return sums.map { $0 / divisor }
    }
}
