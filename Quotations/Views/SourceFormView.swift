//
//  SourceFormView.swift
//  Quotations
//

import SwiftUI
import SwiftData

struct SourceFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Author> { $0.deletedAt == nil }, sort: \Author.name)
    private var authors: [Author]

    var existingSource: Source?

    @State private var authorText = ""
    @State private var selectedAuthorId: PersistentIdentifier?
    @State private var title = ""
    @State private var publicationYear = ""
    @State private var url = ""
    @State private var hasPrefilled = false
    /// Only true after the user has changed the author text while the field is focused (not on initial focus or prefill).
    @State private var authorInputChangedSinceFocus = false
    @FocusState private var isAuthorFieldFocused: Bool

    var onSuccess: () -> Void
    var onCancel: () -> Void
    var onError: (String) -> Void

    private var isEditing: Bool { existingSource != nil }

    private var selectedAuthor: Author? {
        authors.first { $0.id == selectedAuthorId }
    }

    private var authorSuggestions: [Author] {
        let query = authorText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return [] }
        return authors.filter { $0.name.lowercased().contains(query) }
    }

    private var authorNameIsValid: Bool {
        !authorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Author", text: $authorText)
                .textContentType(.name)
                .focused($isAuthorFieldFocused)
                .textInputSuggestions {
                    if authorInputChangedSinceFocus {
                        ForEach(authorSuggestions, id: \.id) { author in
                            Text(author.name)
                                .textInputCompletion(author.name)
                        }
                    }
                }
                .onChange(of: isAuthorFieldFocused) { _, newValue in
                    if newValue { authorInputChangedSinceFocus = false }
                }
                .onChange(of: authorText) { _, newValue in
                    if isAuthorFieldFocused { authorInputChangedSinceFocus = true }
                    if let sel = selectedAuthor, sel.name != newValue {
                        selectedAuthorId = nil
                    }
                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let author = authors.first(where: { $0.name == trimmed }) {
                        selectedAuthorId = author.id
                        isAuthorFieldFocused = false
                    }
                }
                .onChange(of: selectedAuthorId) { _, newValue in
                    if let id = newValue, let a = authors.first(where: { $0.id == id }) {
                        authorText = a.name
                    }
                }

            TextField("Title", text: $title)

            TextField("Year", text: $publicationYear)
                .frame(width: 80)

            TextField("URL (optional)", text: $url)
                .textContentType(.URL)

            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                Button(isEditing ? "Save" : "Add") {
                    submit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!authorNameIsValid || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            guard let source = existingSource, !hasPrefilled else { return }
            title = source.title
            url = source.url ?? ""
            publicationYear = source.publicationYear.map { String($0) } ?? ""
            if let author = source.author {
                authorText = author.name
                selectedAuthorId = author.id
            }
            hasPrefilled = true
            authorInputChangedSinceFocus = false
        }
    }

    private func submit() {
        let authorName = authorText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !authorName.isEmpty else {
            onError("Author is required.")
            return
        }
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else {
            onError("Title is required.")
            return
        }

        let author: Author
        if let existing = selectedAuthor, existing.name == authorName {
            author = existing
        } else if let existing = authors.first(where: { $0.name == authorName }) {
            author = existing
        } else {
            author = Author(name: authorName)
            modelContext.insert(author)
        }

        let year = Int(publicationYear.trimmingCharacters(in: .whitespacesAndNewlines))
        let u = url.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = existingSource {
            existing.title = t
            existing.author = author
            existing.url = u.isEmpty ? nil : u
            existing.publicationYear = year
            existing.updatedAt = Date()
        } else {
            let source = Source(title: t, author: author, url: u.isEmpty ? nil : u, publicationYear: year)
            modelContext.insert(source)
        }

        do {
            try modelContext.save()
            title = ""
            publicationYear = ""
            url = ""
            authorText = ""
            selectedAuthorId = nil
            onSuccess()
        } catch {
            onError(error.localizedDescription)
        }
    }
}
