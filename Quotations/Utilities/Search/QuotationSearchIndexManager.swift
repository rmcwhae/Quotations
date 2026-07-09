//
//  QuotationSearchIndexManager.swift
//  Quotations
//

import Foundation
import SwiftData

enum QuotationSearchIndexManager {
    private static var syncTask: Task<Void, Never>?
    private static var lastIndexedFingerprint: String?

    @MainActor
    static func scheduleSync(modelContext: ModelContext) {
        syncTask?.cancel()
        syncTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await sync(modelContext: modelContext)
        }
    }

    @MainActor
    static func reindexIfNeeded(modelContext: ModelContext) async {
        let quotations = fetchLiveQuotations(modelContext: modelContext)
        let fingerprint = fingerprint(for: quotations)
        guard fingerprint != lastIndexedFingerprint else { return }
        await sync(modelContext: modelContext)
    }

    @MainActor
    private static func sync(modelContext: ModelContext) async {
        let quotations = fetchLiveQuotations(modelContext: modelContext)
        let fingerprint = fingerprint(for: quotations)

        do {
            try await QuotationSpotlightIndexer.index(quotations: quotations)
        } catch {
            // Spotlight indexing is best-effort; embedding sync still runs.
        }

        await EmbeddingSearchIndex.shared.sync(quotations: quotations)
        lastIndexedFingerprint = fingerprint
    }

    @MainActor
    private static func fetchLiveQuotations(modelContext: ModelContext) -> [Quotation] {
        let descriptor = FetchDescriptor<Quotation>(
            predicate: #Predicate<Quotation> { $0.deletedAt == nil }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private static func fingerprint(for quotations: [Quotation]) -> String {
        quotations
            .map {
                let updated = ($0.updatedAt ?? $0.createdAt ?? .distantPast).timeIntervalSince1970
                let encoded = QuotationDeepLink.encode($0.persistentModelID) ?? "missing"
                return "\(encoded):\(updated)"
            }
            .sorted()
            .joined(separator: "|")
    }
}
