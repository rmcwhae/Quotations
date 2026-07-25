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

    func refresh(quotations: [Quotation], stopwords: Set<String>) {
        analysisTask?.cancel()
        isAnalyzing = true
        statusMessage = nil

        let active = quotations.filter { $0.deletedAt == nil }
        let minimumWordLength = minimumWordLength

        analysisTask = Task { @MainActor in
            defer { isAnalyzing = false }

            guard !Task.isCancelled else { return }

            if active.isEmpty {
                clearResults()
                statusMessage = "No quotations in your library."
                return
            }

            wordFrequencies = WordFrequencyAnalyzer.analyze(
                quotations: active,
                minimumLength: minimumWordLength,
                maximumEntries: 40,
                stopwords: stopwords
            )

            if wordFrequencies.isEmpty {
                statusMessage = "Not enough distinct words to visualize."
            }

            let entries = await EmbeddingSearchIndex.shared.allEntries()
            guard !Task.isCancelled else { return }

            var indexEntries = entries
            if matchingEntryCount(in: entries, for: active) < 2 {
                await EmbeddingSearchIndex.shared.sync(
                    quotations: active,
                    persist: !LibraryModeController.isDemoModeActive
                )
                guard !Task.isCancelled else { return }
                indexEntries = await EmbeddingSearchIndex.shared.allEntries()
            }

            if active.count >= 2 {
                semanticClusters = SemanticClusterAnalyzer.analyze(
                    quotations: active,
                    entries: indexEntries,
                    stopwords: stopwords
                )
            } else {
                semanticClusters = nil
                if active.count == 1 {
                    statusMessage = "Add more quotations for the semantic map."
                }
            }
        }
    }

    func invalidate() {
        analysisTask?.cancel()
        clearResults()
        isAnalyzing = false
        statusMessage = nil
    }

    private func matchingEntryCount(in entries: [EmbeddingIndexEntry], for quotations: [Quotation]) -> Int {
        let ids = Set(entries.map(\.encodedQuotationID))
        return quotations.reduce(0) { count, quotation in
            guard let encoded = QuotationDeepLink.encode(quotation.persistentModelID),
                  ids.contains(encoded) else {
                return count
            }
            return count + 1
        }
    }

    private func clearResults() {
        wordFrequencies = []
        semanticClusters = nil
    }
}
