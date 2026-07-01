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
    @State private var title = ""
    @State private var publicationYear = ""
    @State private var url = ""
    @State private var format: SourceFormat?
    @State private var dateReadMonth: Int?
    @State private var dateReadYear: Int?
    @State private var hasPrefilled = false
    /// Only true after the user has changed the author text while the field is focused
    /// (not on initial focus or prefill).
    @State private var authorInputChangedSinceFocus = false
    @State private var isAuthorFieldFocused = false

    var onSuccess: (PersistentIdentifier?) -> Void
    var onCancel: () -> Void
    var onError: (String) -> Void

    private var isEditing: Bool { existingSource != nil }

    private var authorSuggestions: [Author] {
        let query = authorText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return [] }
        return authors.filter { $0.name.lowercased().contains(query) }
    }

    private var showsAuthorSuggestions: Bool {
        isAuthorFieldFocused
            && authorInputChangedSinceFocus
            && !authorSuggestions.isEmpty
    }

    private var authorNameIsValid: Bool {
        !authorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private let monthSymbols = Calendar.current.monthSymbols
    /// Reading years limited to the last 15 years (most recent first).
    private var yearRange: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(((currentYear - 15)...currentYear).reversed())
    }

    var body: some View {
        Form {
            LabeledContent("Author") {
                MacFormTextField(placeholder: "", text: $authorText) { focused in
                    isAuthorFieldFocused = focused
                    if focused { authorInputChangedSinceFocus = false }
                }
                .onChange(of: authorText) { _, _ in
                    if isAuthorFieldFocused { authorInputChangedSinceFocus = true }
                }
            }

            if showsAuthorSuggestions {
                Section {
                    ForEach(authorSuggestions.prefix(6)) { author in
                        Button {
                            authorText = author.name
                            authorInputChangedSinceFocus = false
                        } label: {
                            Text(author.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            LabeledContent("Title") {
                MacFormTextField(placeholder: "", text: $title)
            }

            LabeledContent("URL") {
                MacFormTextField(placeholder: "", text: $url)
            }

            TextField("Publication year", text: $publicationYear)

            Picker("Format", selection: $format) {
                Text("—").tag(Optional<SourceFormat>.none)
                ForEach(SourceFormat.allCases) { option in
                    Text(option.rawValue).tag(Optional(option))
                }
            }

            Picker("Year read", selection: $dateReadYear) {
                Text("—").tag(Optional<Int>.none)
                ForEach(yearRange, id: \.self) { year in
                    Text(String(year)).tag(Optional(year))
                }
            }

            Picker("Month read", selection: $dateReadMonth) {
                Text("—").tag(Optional<Int>.none)
                ForEach(1...12, id: \.self) { month in
                    Text(monthSymbols[month - 1]).tag(Optional(month))
                }
            }
        }
        .formStyle(.grouped)
        .contentMargins(.bottom, 0, for: .scrollContent)
        .fixedSize(horizontal: false, vertical: true)
        .frame(minWidth: 360)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { onCancel() }
                    .accessibilityLabel("Cancel")
                    .help("Cancel")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") { submit() }
                    .accessibilityLabel(isEditing ? "Save source" : "Add source")
                    .help(isEditing ? "Save changes" : "Add source")
                    .disabled(!authorNameIsValid || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            guard let source = existingSource, !hasPrefilled else { return }
            title = source.title
            url = source.url ?? ""
            publicationYear = source.publicationYear.map { String($0) } ?? ""
            format = source.sourceFormat
            dateReadMonth = source.dateReadMonth
            dateReadYear = source.dateReadYear
            if let author = source.author {
                authorText = author.name
            }
            hasPrefilled = true
            authorInputChangedSinceFocus = false
        }
    }

    private func resolveAuthor(named authorName: String) -> Author {
        let normalizedAuthorName = authorName.lowercased()
        if let existing = authors.first(where: { $0.name.lowercased() == normalizedAuthorName }) {
            return existing
        }
        let author = Author(name: authorName)
        modelContext.insert(author)
        return author
    }

    private func submit() {
        let authorName = authorText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !authorName.isEmpty else {
            onError("Author is required.")
            return
        }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            onError("Title is required.")
            return
        }

        let author = resolveAuthor(named: authorName)
        let year = Int(publicationYear.trimmingCharacters(in: .whitespacesAndNewlines))
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)

        let savedSourceId: PersistentIdentifier
        if let existing = existingSource {
            existing.title = trimmedTitle
            existing.author = author
            existing.url = trimmedURL.isEmpty ? nil : trimmedURL
            existing.publicationYear = year
            existing.format = format?.rawValue
            existing.dateReadMonth = dateReadMonth
            existing.dateReadYear = dateReadYear
            existing.updatedAt = Date()
            savedSourceId = existing.id
        } else {
            let source = Source(
                title: trimmedTitle,
                author: author,
                url: trimmedURL.isEmpty ? nil : trimmedURL,
                publicationYear: year,
                format: format?.rawValue,
                dateReadMonth: dateReadMonth,
                dateReadYear: dateReadYear
            )
            modelContext.insert(source)
            savedSourceId = source.id
        }

        do {
            try modelContext.saveAndNotify()
            onSuccess(savedSourceId)
        } catch {
            onError(error.localizedDescription)
        }
    }
}
