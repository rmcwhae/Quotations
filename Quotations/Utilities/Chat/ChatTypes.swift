//
//  ChatTypes.swift
//  Quotations
//

import Foundation
import SwiftData

enum ChatRole: Equatable {
    case user
    case assistant
}

struct ChatCitation: Identifiable, Hashable {
    let quotationId: PersistentIdentifier
    let sourceId: PersistentIdentifier?
    let label: String

    var id: PersistentIdentifier { quotationId }
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: ChatRole
    let text: String
    let citations: [ChatCitation]

    init(id: UUID = UUID(), role: ChatRole, text: String, citations: [ChatCitation] = []) {
        self.id = id
        self.role = role
        self.text = text
        self.citations = citations
    }
}

enum ChatSuggestedPrompt: String, CaseIterable, Identifiable {
    case stylisticProfile
    case recurringThemes
    case topAuthors

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stylisticProfile: "Stylistic Profile"
        case .recurringThemes: "Recurring themes"
        case .topAuthors: "Authors I quote most"
        }
    }

    var message: String {
        switch self {
        case .stylisticProfile:
            "Generate a stylistic profile of the quotations in my library."
        case .recurringThemes:
            "What recurring themes appear across my quotation library?"
        case .topAuthors:
            "Which authors do I quote most often, and what patterns do you see in those quotations?"
        }
    }
}

struct QuotationContextBuildResult: Equatable {
    let context: String
    let citations: [ChatCitation]
}

struct LibraryContextSample: Equatable {
    let overviewHeader: String
    let quotations: [PersistentIdentifier]
}

enum LibraryChatError: LocalizedError, Equatable {
    case unavailable
    case insufficientLibrary(minimum: Int)
    case noRetrievedContext
    case generationFailed

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "Ask requires macOS 26 and Apple Intelligence."
        case .insufficientLibrary(let minimum):
            "Add at least \(minimum) quotations to use Ask."
        case .noRetrievedContext:
            "No relevant quotations were found for that question."
        case .generationFailed:
            "Apple Intelligence could not generate a response. Try again."
        }
    }
}
