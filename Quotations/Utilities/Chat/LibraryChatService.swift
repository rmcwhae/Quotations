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
        quotations: [Quotation]
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

        let responseText = try await generateAnswer(
            userMessage: trimmed,
            retrievedContext: buildResult.context,
            intent: intent
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

    private static func generateAnswer(
        userMessage: String,
        retrievedContext: String,
        intent: ChatQueryIntent
    ) async throws -> String {
        guard #available(macOS 26.0, *) else {
            throw LibraryChatError.unavailable
        }
        #if canImport(FoundationModels)
        guard SystemLanguageModel.default.availability == .available else {
            throw LibraryChatError.unavailable
        }

        let session = LanguageModelSession(instructions: instructions(for: intent))
        let prompt = """
        Answer only the user's current question using only the retrieved quotations below. \
        Do not continue, repeat, or assume context from any earlier conversation.

        Retrieved quotations from the user's library:

        \(retrievedContext)

        Current question:
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

    private static func instructions(for intent: ChatQueryIntent) -> String {
        switch intent {
        case .libraryProfile:
            return """
            You analyze a personal quotation library using only the overview data and retrieved \
            quotations provided in each message. Describe tone, recurring themes, syntax, and subject \
            matter when asked for stylistic profiles. Cite author and source names when referencing \
            specific quotations. If the retrieved material is insufficient, say so clearly instead of \
            inventing quotations or authors. Treat each message as a standalone request.
            """
        case .questionSpecific:
            return """
            You answer specific questions about a personal quotation library using only the retrieved \
            quotations provided in each message. Focus on the current question and the evidence in front \
            of you. Cite author and source names when referencing quotations. If the retrieved material \
            does not address the question, say so clearly instead of inventing quotations, repeating an \
            earlier analysis, or summarizing unrelated themes. Treat each message as a standalone request.
            """
        }
    }
}
