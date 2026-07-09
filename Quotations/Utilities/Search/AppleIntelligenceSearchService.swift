//
//  AppleIntelligenceSearchService.swift
//  Quotations
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum AppleIntelligenceSearchService {
    @available(macOS 26.0, *)
    static func search(query: String) async -> SemanticSearchResponse? {
        #if canImport(FoundationModels)
        guard SystemLanguageModel.default.availability == .available else { return nil }

        let session = LanguageModelSession(
            instructions: """
            You extract search terms for a personal quotation library. Given a natural-language \
            request, respond with a short comma-separated list of concrete search terms only. \
            Do not include any other text.
            """
        )

        do {
            let response = try await session.respond(
                to: "Extract search terms for this quotation request: \(query)"
            )
            let terms = response.content
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !terms.isEmpty else { return nil }

            async let spotlightIDs = SpotlightQuotationSearcher.search(query: terms)
            async let embeddingIDs = EmbeddingSearchIndex.shared.search(query: terms)
            let spotlight = await spotlightIDs
            let embedding = await embeddingIDs

            var merged: [String] = []
            var seen = Set<String>()
            for id in spotlight + embedding where seen.insert(id).inserted {
                merged.append(id)
            }

            guard !merged.isEmpty else { return nil }
            return SemanticSearchResponse(encodedQuotationIDs: merged, summary: nil)
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }
}
