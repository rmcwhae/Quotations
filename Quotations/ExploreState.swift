//
//  ExploreState.swift
//  Quotations
//

import Foundation
import Observation
import SwiftData

@Observable
final class ExploreState {
    var visualizationMode: ExploreVisualizationMode = .wordBubbles
    var minimumWordLength: Int = 3

    var wordFrequencies: [WordFrequencyEntry] = []
    var semanticClusters: SemanticClusterResult?
    var isAnalyzing = false
    var statusMessage: String?

    private var analysisTask: Task<Void, Never>?

    deinit {
        analysisTask?.cancel()
    }

    var hasResults: Bool {
        !wordFrequencies.isEmpty || semanticClusters != nil
    }

    /// Re-runs analysis. Existing results stay visible until new ones are ready;
    /// the heavy tokenizing / PCA / k-means work runs off the main actor.
    func refresh(quotations: [Quotation], stopwords: Set<String>) {
        analysisTask?.cancel()
        isAnalyzing = true
        statusMessage = nil

        let active = quotations.filter { $0.deletedAt == nil }
        let minimumWordLength = minimumWordLength
        // Snapshot SwiftData models into Sendable values on the main actor.
        let texts = WordFrequencyAnalyzer.plainTexts(for: active)
        let clusterInputs = SemanticClusterAnalyzer.inputs(for: active)

        analysisTask = Task { @MainActor in
            // A cancelled task must not clear the flag owned by its replacement.
            defer { if !Task.isCancelled { isAnalyzing = false } }
            guard !Task.isCancelled else { return }

            if active.isEmpty {
                clearResults()
                statusMessage = "No quotations in your library."
                return
            }

            let frequencies = await Self.computeWordFrequencies(
                texts: texts,
                minimumLength: minimumWordLength,
                stopwords: stopwords
            )
            guard !Task.isCancelled else { return }
            wordFrequencies = frequencies

            if frequencies.isEmpty {
                statusMessage = "Not enough distinct words to visualize."
            }

            let entries = await EmbeddingSearchIndex.shared.allEntries()
            guard !Task.isCancelled else { return }

            var indexEntries = entries
            if matchingEntryCount(in: entries, for: clusterInputs) < 2 {
                await EmbeddingSearchIndex.shared.sync(
                    quotations: active,
                    persist: !LibraryModeController.isDemoModeActive
                )
                guard !Task.isCancelled else { return }
                indexEntries = await EmbeddingSearchIndex.shared.allEntries()
                guard !Task.isCancelled else { return }
            }

            if clusterInputs.count >= 2 {
                let clusters = await Self.computeSemanticClusters(
                    inputs: clusterInputs,
                    vectorsByEncodedID: SemanticClusterAnalyzer.vectorsByEncodedID(indexEntries),
                    stopwords: stopwords
                )
                guard !Task.isCancelled else { return }
                semanticClusters = clusters
            } else {
                semanticClusters = nil
                if active.count == 1 {
                    statusMessage = "Add more quotations for the semantic map."
                }
            }
        }
    }

    @concurrent
    private nonisolated static func computeWordFrequencies(
        texts: [String],
        minimumLength: Int,
        stopwords: Set<String>
    ) async -> [WordFrequencyEntry] {
        WordFrequencyAnalyzer.analyze(
            texts: texts,
            minimumLength: minimumLength,
            maximumEntries: 40,
            stopwords: stopwords
        )
    }

    @concurrent
    private nonisolated static func computeSemanticClusters(
        inputs: [SemanticClusterInput],
        vectorsByEncodedID: [String: [Double]],
        stopwords: Set<String>
    ) async -> SemanticClusterResult? {
        SemanticClusterAnalyzer.analyze(
            inputs: inputs,
            vectorsByEncodedID: vectorsByEncodedID,
            stopwords: stopwords
        )
    }

    func invalidate() {
        analysisTask?.cancel()
        clearResults()
        isAnalyzing = false
        statusMessage = nil
    }

    private func matchingEntryCount(in entries: [EmbeddingIndexEntry], for inputs: [SemanticClusterInput]) -> Int {
        let ids = Set(entries.map(\.encodedQuotationID))
        return inputs.reduce(0) { count, input in
            ids.contains(input.encodedQuotationID) ? count + 1 : count
        }
    }

    private func clearResults() {
        wordFrequencies = []
        semanticClusters = nil
    }
}
