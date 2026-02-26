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
    @FocusState private var isAuthorFieldFocused: Bool
    @State private var hasPrefilled = false

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
            VStack(alignment: .leading, spacing: 4) {
                TextField("Author", text: $authorText)
                    .textContentType(.name)
                    .focused($isAuthorFieldFocused)
                    .onChange(of: authorText) { _, newValue in
                        if let sel = selectedAuthor, sel.name != newValue {
                            selectedAuthorId = nil
                        }
                    }
                    .onChange(of: selectedAuthorId) { _, newValue in
                        if let id = newValue, let a = authors.first(where: { $0.id == id }) {
                            authorText = a.name
                        }
                    }

                if isAuthorFieldFocused, !authorSuggestions.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(authorSuggestions) { author in
                                Button {
                                    selectedAuthorId = author.id
                                    authorText = author.name
                                    isAuthorFieldFocused = false
                                } label: {
                                    Text(author.name)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 8)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 180)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
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
