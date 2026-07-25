//
//  EmbeddingSearchIndex.swift
//  Quotations
//

import Foundation
import NaturalLanguage
import SwiftData

struct EmbeddingIndexEntry: Codable, Equatable {
    let encodedQuotationID: String
    let sourceEncodedID: String?
    let vector: [Double]
    let updatedAt: TimeInterval
}

struct EmbeddingIndexSnapshot: Codable, Equatable {
    var version: Int
    var entries: [String: EmbeddingIndexEntry]
}

actor EmbeddingSearchIndex {
    static let shared = EmbeddingSearchIndex()

    private let minimumSimilarity = 0.28
    private let maxResults = 50
    private var snapshot = EmbeddingIndexSnapshot(version: 1, entries: [:])
    private var isLoaded = false
    private var modelsLoaded = false
    private var contextualEmbedding: NLContextualEmbedding?
    private var sentenceEmbedding: NLEmbedding?

    private var indexURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("Quotations", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("embedding-index.json")
    }

    func search(query: String, limit: Int? = nil) async -> [String] {
        await ensureLoaded()
        guard let queryVector = await embed(text: query), !queryVector.isEmpty else { return [] }

        let resultLimit = limit ?? maxResults
        let ranked = snapshot.entries.values
            .map { entry in
                (entry.encodedQuotationID, EmbeddingVectorMath.cosineSimilarity(queryVector, entry.vector))
            }
            .filter { $0.1 >= minimumSimilarity }
            .sorted { $0.1 > $1.1 }
            .prefix(resultLimit)
            .map(\.0)

        return Array(ranked)
    }

    func sync(quotations: [Quotation], persist: Bool = true) async {
        await ensureLoaded()

        // Demo mode rebuilds an ephemeral in-memory index so personal entries are not mixed in.
        var nextEntries = persist ? snapshot.entries : [:]
        var liveEncodedIDs = Set<String>()

        for quotation in quotations {
            guard let encodedID = QuotationDeepLink.encode(quotation.persistentModelID),
                  let body = QuotationSearchText.searchableBody(for: quotation) else {
                continue
            }

            liveEncodedIDs.insert(encodedID)
            let updatedAt = (quotation.updatedAt ?? quotation.createdAt ?? .distantPast).timeIntervalSince1970

            if let existing = nextEntries[encodedID],
               abs(existing.updatedAt - updatedAt) < 0.001 {
                continue
            }

            guard let vector = await embed(text: body), !vector.isEmpty else { continue }

            let sourceEncodedID = quotation.source.flatMap {
                QuotationDeepLink.encode($0.persistentModelID)
            }

            nextEntries[encodedID] = EmbeddingIndexEntry(
                encodedQuotationID: encodedID,
                sourceEncodedID: sourceEncodedID,
                vector: vector,
                updatedAt: updatedAt
            )
        }

        let staleIDs = Set(nextEntries.keys).subtracting(liveEncodedIDs)
        staleIDs.forEach { nextEntries.removeValue(forKey: $0) }

        snapshot = EmbeddingIndexSnapshot(version: 1, entries: nextEntries)
        if persist {
            persistSnapshot()
        }
    }

    func removeAll() async {
        snapshot = EmbeddingIndexSnapshot(version: 1, entries: [:])
        persistSnapshot()
    }

    /// Restores the on-disk personal index into memory (e.g. after leaving demo mode).
    func reloadPersistedSnapshot() async {
        loadModelsIfNeeded()
        if let data = try? Data(contentsOf: indexURL),
           let decoded = try? JSONDecoder().decode(EmbeddingIndexSnapshot.self, from: data) {
            snapshot = decoded
        } else {
            snapshot = EmbeddingIndexSnapshot(version: 1, entries: [:])
        }
        isLoaded = true
    }

    func allEntries() async -> [EmbeddingIndexEntry] {
        await ensureLoaded()
        return Array(snapshot.entries.values)
    }

    private func ensureLoaded() async {
        guard !isLoaded else {
            loadModelsIfNeeded()
            return
        }
        defer { isLoaded = true }

        if let data = try? Data(contentsOf: indexURL),
           let decoded = try? JSONDecoder().decode(EmbeddingIndexSnapshot.self, from: data) {
            snapshot = decoded
        }

        loadModelsIfNeeded()
    }

    private func loadModelsIfNeeded() {
        guard !modelsLoaded else { return }
        modelsLoaded = true

        contextualEmbedding = NLContextualEmbedding(language: .english)
        if contextualEmbedding?.hasAvailableAssets == true {
            try? contextualEmbedding?.load()
        } else {
            contextualEmbedding = nil
        }
        sentenceEmbedding = NLEmbedding.sentenceEmbedding(for: .english)
    }

    private func embed(text: String) async -> [Double]? {
        if let contextualEmbedding {
            do {
                let result = try contextualEmbedding.embeddingResult(for: text, language: .english)
                return averageTokenVectors(from: result)
            } catch {
                // Fall through to sentence embedding.
            }
        }

        guard let sentenceEmbedding else { return nil }
        guard let vector = sentenceEmbedding.vector(for: text) else { return nil }
        return vector.map { Double($0) }
    }

    private func averageTokenVectors(from result: NLContextualEmbeddingResult) -> [Double] {
        var sum: [Double] = []
        var count = 0

        result.enumerateTokenVectors(in: result.string.startIndex..<result.string.endIndex) { vector, _ in
            if sum.isEmpty {
                sum = vector
            } else {
                for index in vector.indices where index < sum.count {
                    sum[index] += vector[index]
                }
            }
            count += 1
            return true
        }

        guard count > 0 else { return [] }
        return sum.map { $0 / Double(count) }
    }

    private func persistSnapshot() {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
}
