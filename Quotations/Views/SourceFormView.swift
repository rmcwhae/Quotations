//
//  SourceFormView.swift
//  Quotations
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private struct AuthorFieldFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

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
    @State private var hoveredAuthorId: PersistentIdentifier?
    @State private var authorFieldFrame: CGRect = .zero

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

    private var authorSuggestionsMenuBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }

    private var authorSuggestionsMenuHoverColor: Color {
        #if os(macOS)
        Color(nsColor: .selectedContentBackgroundColor)
        #else
        Color(uiColor: .systemBlue).opacity(0.25)
        #endif
    }

    @ViewBuilder
    private func authorSuggestionsMenu(limited: [Author]) -> some View {
        List(limited, id: \.id) { author in
            Button {
                selectedAuthorId = author.id
                authorText = author.name
                isAuthorFieldFocused = false
            } label: {
                Text(author.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .listRowBackground(hoveredAuthorId == author.id ? authorSuggestionsMenuHoverColor : authorSuggestionsMenuBackground)
            .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
            .onHover { hovering in
                if hovering {
                    hoveredAuthorId = author.id
                } else if hoveredAuthorId == author.id {
                    hoveredAuthorId = nil
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(
            width: max(200, authorFieldFrame.width),
            height: min(CGFloat(limited.count) * 32, 220)
        )
        .background(authorSuggestionsMenuBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
            }
            .background(
                GeometryReader { g in
                    Color.clear.preference(key: AuthorFieldFrameKey.self, value: g.frame(in: .named("sourceForm")))
                }
            )

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
        .coordinateSpace(name: "sourceForm")
        .onPreferenceChange(AuthorFieldFrameKey.self) { authorFieldFrame = $0 }
        .overlay(alignment: .topLeading) {
            if isAuthorFieldFocused, !authorSuggestions.isEmpty {
                let limited = Array(authorSuggestions.prefix(10))
                // Overlay origin is the padded view; author frame is in inner VStack space, so add padding.
                let padding: CGFloat = 16
                authorSuggestionsMenu(limited: limited)
                    .offset(x: padding + authorFieldFrame.minX, y: padding + authorFieldFrame.maxY + 26)
            }
        }
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
