//
//  StopWordsStore.swift
//  Quotations
//

import Foundation
import Observation

@Observable
final class StopWordsStore {
    static let userDefaultsKey = "exploreStopWords"

    private(set) var words: [String] = []

    var wordSet: Set<String> {
        Set(words)
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let stored = userDefaults.stringArray(forKey: Self.userDefaultsKey) {
            words = Self.sortedUnique(stored)
        } else {
            words = Self.sortedUnique(Array(EnglishStopwords.defaultWords))
            persist()
        }
    }

    func addWord(_ raw: String) {
        let normalized = Self.normalize(raw)
        guard !normalized.isEmpty, !words.contains(normalized) else { return }
        words.append(normalized)
        words.sort()
        persist()
    }

    func removeWord(_ word: String) {
        let normalized = Self.normalize(word)
        guard let index = words.firstIndex(of: normalized) else { return }
        words.remove(at: index)
        persist()
    }

    func resetToDefaults() {
        words = Self.sortedUnique(Array(EnglishStopwords.defaultWords))
        persist()
    }

    private func persist() {
        userDefaults.set(words, forKey: Self.userDefaultsKey)
    }

    private static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func sortedUnique(_ values: [String]) -> [String] {
        Array(Set(values.map(normalize).filter { !$0.isEmpty })).sorted()
    }
}
