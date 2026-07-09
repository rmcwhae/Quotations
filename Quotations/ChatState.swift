//
//  ChatState.swift
//  Quotations
//

import Foundation
import Observation
import SwiftData

@Observable
final class ChatState {
    var messages: [ChatMessage] = []
    var isGenerating = false
    var errorMessage: String?

    private var generationTask: Task<Void, Never>?

    deinit {
        generationTask?.cancel()
    }

    var isAvailable: Bool {
        AppleIntelligenceAvailability.isChatAvailable
    }

    var hasContent: Bool {
        !messages.isEmpty || errorMessage != nil
    }

    func send(_ text: String, quotations: [Quotation]) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isGenerating else { return }

        errorMessage = nil
        messages.append(ChatMessage(role: .user, text: trimmed))
        generateResponse(for: trimmed, quotations: quotations)
    }

    func runSuggestedPrompt(_ prompt: ChatSuggestedPrompt, quotations: [Quotation]) {
        send(prompt.message, quotations: quotations)
    }

    func clear() {
        generationTask?.cancel()
        generationTask = nil
        messages = []
        errorMessage = nil
        isGenerating = false
    }

    private func generateResponse(for userMessage: String, quotations: [Quotation]) {
        generationTask?.cancel()
        isGenerating = true

        generationTask = Task { @MainActor in
            defer {
                isGenerating = false
                generationTask = nil
            }

            guard !Task.isCancelled else { return }

            do {
                let response = try await LibraryChatService.generateResponse(
                    userMessage: userMessage,
                    quotations: quotations
                )
                guard !Task.isCancelled else { return }
                messages.append(response)
                errorMessage = nil
            } catch let error as LibraryChatError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = LibraryChatError.generationFailed.errorDescription
            }
        }
    }
}
