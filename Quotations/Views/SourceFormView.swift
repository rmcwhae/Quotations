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

    @State private var selectedAuthorId: PersistentIdentifier?
    @State private var title = ""
    @State private var publicationYear = ""
    @State private var url = ""

    var onSuccess: () -> Void
    var onCancel: () -> Void
    var onError: (String) -> Void

    private var selectedAuthor: Author? {
        authors.first { $0.id == selectedAuthorId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Author", selection: $selectedAuthorId) {
                Text("Select author").tag(nil as PersistentIdentifier?)
                ForEach(authors) { author in
                    Text(author.name).tag(author.id as PersistentIdentifier?)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)

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
                Button("Add") {
                    submit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedAuthor == nil || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func submit() {
        guard let author = selectedAuthor else {
            onError("Please select an author.")
            return
        }
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else {
            onError("Title is required.")
            return
        }
        let year = Int(publicationYear.trimmingCharacters(in: .whitespacesAndNewlines))
        let u = url.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = Source(title: t, author: author, url: u.isEmpty ? nil : u, publicationYear: year)
        modelContext.insert(source)
        do {
            try modelContext.save()
            title = ""
            publicationYear = ""
            url = ""
            selectedAuthorId = nil
            onSuccess()
        } catch {
            onError(error.localizedDescription)
        }
    }
}
