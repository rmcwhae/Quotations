//
//  WordFrequencyAnalyzer.swift
//  Quotations
//

import Foundation
import NaturalLanguage

nonisolated struct WordFrequencyEntry: Identifiable, Hashable, Sendable {
    let word: String
    let count: Int

    var id: String { word }
}

nonisolated enum WordFrequencyAnalyzer {
    /// Main-actor convenience: extracts plain text from live models, then analyzes.
    @MainActor
    static func analyze(
        quotations: [Quotation],
        minimumLength: Int = 3,
        maximumEntries: Int = 40,
        stopwords: Set<String>
    ) -> [WordFrequencyEntry] {
        analyze(
            texts: plainTexts(for: quotations),
            minimumLength: minimumLength,
            maximumEntries: maximumEntries,
            stopwords: stopwords
        )
    }

    /// Plain (markdown-stripped) content of each non-deleted quotation.
    @MainActor
    static func plainTexts(for quotations: [Quotation]) -> [String] {
        quotations
            .filter { $0.deletedAt == nil }
            .map { QuotationSearchText.plainContent(from: $0.content) }
    }

    /// Pure analysis over plain text; safe to run off the main actor.
    static func analyze(
        texts: [String],
        minimumLength: Int = 3,
        maximumEntries: Int = 40,
        stopwords: Set<String>
    ) -> [WordFrequencyEntry] {
        var counts: [String: Int] = [:]

        for text in texts {
            guard !text.isEmpty else { continue }

            let tokenizer = NLTokenizer(unit: .word)
            tokenizer.string = text
            tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
                let token = String(text[range]).lowercased()
                guard token.count >= minimumLength,
                      token.allSatisfy({ $0.isLetter || $0 == "'" }),
                      !EnglishStopwords.isStopword(token, in: stopwords) else {
                    return true
                }
                counts[token, default: 0] += 1
                return true
            }
        }

        return counts
            .map { WordFrequencyEntry(word: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count { return lhs.word < rhs.word }
                return lhs.count > rhs.count
            }
            .prefix(maximumEntries)
            .map { $0 }
    }

    @MainActor
    static func topWords(in quotations: [Quotation], limit: Int = 3, stopwords: Set<String>) -> [String] {
        topWords(in: plainTexts(for: quotations), limit: limit, stopwords: stopwords)
    }

    static func topWords(in texts: [String], limit: Int = 3, stopwords: Set<String>) -> [String] {
        analyze(texts: texts, minimumLength: 3, maximumEntries: limit, stopwords: stopwords).map(\.word)
    }
}
