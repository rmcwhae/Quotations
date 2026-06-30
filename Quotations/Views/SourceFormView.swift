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
    @State private var format: SourceFormat?
    @State private var dateReadMonth: Int?
    @State private var dateReadYear: Int?
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

    private let monthSymbols = Calendar.current.monthSymbols
    /// Reading years limited to the last 15 years (most recent first).
    private var yearRange: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(((currentYear - 15)...currentYear).reversed())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FormFieldRow(label: "Author") {
                TextField("", text: $authorText)
                    .textFieldStyle(.plain)
                    .textContentType(.name)
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
                        if let author = authors.first(where: { $0.name.lowercased() == trimmed.lowercased() }) {
                            selectedAuthorId = author.id
                            isAuthorFieldFocused = false
                        }
                    }
                    .onChange(of: selectedAuthorId) { _, newValue in
                        if let id = newValue, let a = authors.first(where: { $0.id == id }) {
                            authorText = a.name
                        }
                    }
                    .formInputStyle(isFocused: $isAuthorFieldFocused)
            }

            FormFieldRow(label: "Title") {
                TextField("", text: $title)
                    .textFieldStyle(.plain)
                    .formInputStyle()
            }

            FormFieldRow(label: "URL") {
                TextField("", text: $url)
                    .textFieldStyle(.plain)
                    .textContentType(.URL)
                    .formInputStyle()
            }

            FormFieldRow(label: "Publication year") {
                TextField("", text: $publicationYear)
                    .textFieldStyle(.plain)
                    .formInputStyle(maxWidth: 80)
            }

            FormFieldRow(label: "Format") {
                Picker("", selection: $format) {
                    Text("—").tag(Optional<SourceFormat>.none)
                    ForEach(SourceFormat.allCases) { option in
                        Text(option.rawValue).tag(Optional(option))
                    }
                }
                .labelsHidden()
                .accessibilityLabel("Format")
                .frame(maxWidth: 160, alignment: .trailing)
            }

            FormFieldRow(label: "Year read") {
                Picker("", selection: $dateReadYear) {
                    Text("—").tag(Optional<Int>.none)
                    ForEach(yearRange, id: \.self) { year in
                        Text(String(year)).tag(Optional(year))
                    }
                }
                .labelsHidden()
                .accessibilityLabel("Year read")
                .frame(maxWidth: 120, alignment: .trailing)
            }

            FormFieldRow(label: "Month read") {
                Picker("", selection: $dateReadMonth) {
                    Text("—").tag(Optional<Int>.none)
                    ForEach(1...12, id: \.self) { month in
                        Text(monthSymbols[month - 1]).tag(Optional(month))
                    }
                }
                .labelsHidden()
                .accessibilityLabel("Month read")
                .frame(maxWidth: 140, alignment: .trailing)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Cancel")
                .help("Cancel")
                Button(isEditing ? "Save" : "Add") {
                    submit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!authorNameIsValid || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel(isEditing ? "Save source" : "Add source")
                .help(isEditing ? "Save changes" : "Add source")
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
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
        let normalizedAuthorName = authorName.lowercased()
        if let existing = selectedAuthor, existing.name.lowercased() == normalizedAuthorName {
            author = existing
        } else if let existing = authors.first(where: { $0.name.lowercased() == normalizedAuthorName }) {
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
            existing.format = format?.rawValue
            existing.dateReadMonth = dateReadMonth
            existing.dateReadYear = dateReadYear
            existing.updatedAt = Date()
        } else {
            let source = Source(
                title: t,
                author: author,
                url: u.isEmpty ? nil : u,
                publicationYear: year,
                format: format?.rawValue,
                dateReadMonth: dateReadMonth,
                dateReadYear: dateReadYear
            )
            modelContext.insert(source)
        }

        do {
            try modelContext.saveAndNotify()
            title = ""
            publicationYear = ""
            url = ""
            format = nil
            dateReadMonth = nil
            dateReadYear = nil
            authorText = ""
            selectedAuthorId = nil
            onSuccess()
        } catch {
            onError(error.localizedDescription)
        }
    }
}
