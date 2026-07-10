//
//  ExploreSettingsPane.swift
//  Quotations
//

import SwiftUI

struct ExploreSettingsPane: View {
    @Environment(StopWordsStore.self) private var stopWordsStore

    @State private var searchText = ""
    @State private var newWord = ""

    private var filteredWords: [String] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return stopWordsStore.words }
        return stopWordsStore.words.filter { $0.localizedStandardContains(query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stop Words")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Words in this list are excluded from Explore word clouds and semantic cluster labels.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                TextField("Search stop words", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                Button("Restore Defaults") {
                    stopWordsStore.resetToDefaults()
                }
            }

            List {
                ForEach(filteredWords, id: \.self) { word in
                    HStack {
                        Text(word)
                        Spacer()
                        Button(role: .destructive) {
                            stopWordsStore.removeWord(word)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                        }
                        .buttonStyle(.borderless)
                        .help("Remove stop word")
                    }
                }
            }
            .listStyle(.inset)

            HStack(spacing: 8) {
                TextField("Add stop word", text: $newWord)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addWord)

                Button("Add") {
                    addWord()
                }
                .disabled(newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
    }

    private func addWord() {
        let trimmed = newWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        stopWordsStore.addWord(trimmed)
        newWord = ""
    }
}

#Preview {
    ExploreSettingsPane()
        .environment(StopWordsStore(userDefaults: UserDefaults(suiteName: "ExploreSettingsPreview")!))
        .frame(width: 420, height: 480)
}
