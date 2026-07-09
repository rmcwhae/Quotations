//
//  WordFrequencyAnalyzer.swift
//  Quotations
//

import Foundation
import NaturalLanguage

struct WordFrequencyEntry: Identifiable, Hashable {
    let word: String
    let count: Int

    var id: String { word }
}

enum WordFrequencyAnalyzer {
    static func analyze(
        quotations: [Quotation],
        minimumLength: Int = 3,
        maximumEntries: Int = 40,
        extraStopwords: Set<String> = []
    ) -> [WordFrequencyEntry] {
        var counts: [String: Int] = [:]

        for quotation in quotations {
            guard quotation.deletedAt == nil else { continue }
            let text = QuotationSearchText.plainContent(from: quotation.content)
            guard !text.isEmpty else { continue }

            let tokenizer = NLTokenizer(unit: .word)
            tokenizer.string = text
            tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
                let token = String(text[range]).lowercased()
                guard token.count >= minimumLength,
                      token.allSatisfy({ $0.isLetter || $0 == "'" }),
                      !EnglishStopwords.isStopword(token, extra: extraStopwords) else {
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

    static func topWords(in quotations: [Quotation], limit: Int = 3) -> [String] {
        analyze(quotations: quotations, minimumLength: 3, maximumEntries: limit).map(\.word)
    }
}
