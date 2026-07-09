//
//  LibraryChatService.swift
//  Quotations
//

import Foundation
import SwiftData

#if canImport(FoundationModels)
import FoundationModels
#endif

enum AppleIntelligenceAvailability {
    static var isChatAvailable: Bool {
        guard #available(macOS 26.0, *) else { return false }
        #if canImport(FoundationModels)
        return SystemLanguageModel.default.availability == .available
        #else
        return false
        #endif
    }

    static var unavailabilityMessage: String {
        LibraryChatError.unavailable.errorDescription ?? "Ask is unavailable."
    }
}

enum LibraryChatService {
    private static let questionSpecificLimit = 20
    private static let libraryProfileMinimumQuotations = 5

    static func generateResponse(
        userMessage: String,
        quotations: [Quotation],
        sessionBox: LibraryChatSessionBox
    ) async throws -> ChatMessage {
        guard AppleIntelligenceAvailability.isChatAvailable else {
            throw LibraryChatError.unavailable
        }

        let trimmed = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw LibraryChatError.noRetrievedContext
        }

        let active = quotations.filter { $0.deletedAt == nil }
        let intent = ChatIntentRouter.intent(for: trimmed)

        if intent == .libraryProfile, active.count < libraryProfileMinimumQuotations {
            throw LibraryChatError.insufficientLibrary(minimum: libraryProfileMinimumQuotations)
        }

        guard !active.isEmpty else {
            throw LibraryChatError.insufficientLibrary(minimum: 1)
        }

        let buildResult = try await buildContext(
            userMessage: trimmed,
            intent: intent,
            quotations: active
        )

        guard !buildResult.context.isEmpty else {
            throw LibraryChatError.noRetrievedContext
        }

        let responseText = try await sessionBox.respond(
            userMessage: trimmed,
            retrievedContext: buildResult.context
        )

        return ChatMessage(
            role: .assistant,
            text: responseText,
            citations: buildResult.citations
        )
    }

    private static func buildContext(
        userMessage: String,
        intent: ChatQueryIntent,
        quotations: [Quotation]
    ) async throws -> QuotationContextBuildResult {
        switch intent {
        case .libraryProfile:
            let entries = await EmbeddingSearchIndex.shared.allEntries()
            let sample = LibraryContextSampler.sample(quotations: quotations, entries: entries)
            let resolved = QuotationContextBuilder.resolveQuotations(ids: sample.quotations, from: quotations)
            return QuotationContextBuilder.build(
                quotations: resolved,
                overviewHeader: sample.overviewHeader
            )

        case .questionSpecific:
            let encodedIDs = await EmbeddingSearchIndex.shared.search(
                query: userMessage,
                limit: questionSpecificLimit
            )
            let resolved = QuotationContextBuilder.resolveQuotations(
                encodedIDs: encodedIDs,
                from: quotations
            )
            guard !resolved.isEmpty else {
                throw LibraryChatError.noRetrievedContext
            }
            return QuotationContextBuilder.build(quotations: resolved)
        }
    }
}

final class LibraryChatSessionBox {
    private var backing: Any?

    func respond(userMessage: String, retrievedContext: String) async throws -> String {
        guard #available(macOS 26.0, *) else {
            throw LibraryChatError.unavailable
        }
        #if canImport(FoundationModels)
        guard SystemLanguageModel.default.availability == .available else {
            throw LibraryChatError.unavailable
        }

        let session: LanguageModelSession
        if let existing = backing as? LanguageModelSession {
            session = existing
        } else {
            let created = LanguageModelSession(instructions: Self.systemInstructions)
            backing = created
            session = created
        }

        let prompt = """
        Retrieved quotations from the user's library:

        \(retrievedContext)

        User question:
        \(userMessage)
        """

        do {
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else {
                throw LibraryChatError.generationFailed
            }
            return text
        } catch let error as LibraryChatError {
            throw error
        } catch {
            throw LibraryChatError.generationFailed
        }
        #else
        throw LibraryChatError.unavailable
        #endif
    }

    func reset() {
        backing = nil
    }

    private static let systemInstructions = """
    You answer questions about a personal quotation library using only the retrieved quotations \
    and overview data provided in each message. Describe tone, recurring themes, syntax, and \
    subject matter when asked for stylistic profiles. Cite author and source names when \
    referencing specific quotations. If the retrieved material is insufficient, say so clearly \
    instead of inventing quotations or authors.
    """
}
