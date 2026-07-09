//
//  ChatIntentRouter.swift
//  Quotations
//

import Foundation

enum ChatQueryIntent: Equatable {
    case libraryProfile
    case questionSpecific
}

enum ChatIntentRouter {
    private static let libraryProfilePhrases = [
        "stylistic profile",
        "style profile",
        "writing style",
        "recurring theme",
        "recurring themes",
        "themes in my library",
        "what do i collect",
        "authors i quote",
        "authors do i quote",
        "quote most",
        "my library overall",
        "library-wide",
        "library wide",
        "corpus",
        "overall tone",
        "subject matter"
    ]

    static func intent(for query: String) -> ChatQueryIntent {
        let normalized = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalized.isEmpty else { return .questionSpecific }

        if libraryProfilePhrases.contains(where: { normalized.contains($0) }) {
            return .libraryProfile
        }

        return .questionSpecific
    }
}
