//
//  AuthorFormView.swift
//  Quotations
//

import SwiftUI
import SwiftData

struct AuthorFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Author> { $0.deletedAt == nil }, sort: \Author.name)
    private var authors: [Author]

    var existingAuthor: Author?
    var onSuccess: () -> Void
    var onCancel: () -> Void
    var onError: (String) -> Void

    @State private var name = ""
    @State private var hasPrefilled = false

    private var isEditing: Bool { existingAuthor != nil }

    var body: some View {
        Form {
            TextField("Author name", text: $name)
        }
        .formStyle(.grouped)
        .frame(minWidth: 280, minHeight: 120)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { onCancel() }
                    .accessibilityLabel("Cancel")
                    .help("Cancel")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") { submit() }
                    .accessibilityLabel(isEditing ? "Save author" : "Add author")
                    .help(isEditing ? "Save changes" : "Add author")
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            guard let author = existingAuthor, !hasPrefilled else { return }
            name = author.name
            hasPrefilled = true
        }
    }

    private func submit() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            onError("Name is required.")
            return
        }
        if existingAuthor == nil,
           authors.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            onError("An author with this name already exists.")
            return
        }
        do {
            if let existing = existingAuthor {
                existing.name = trimmedName
                existing.updatedAt = Date()
            } else {
                let author = Author(name: trimmedName)
                modelContext.insert(author)
            }
            try modelContext.saveAndNotify()
            onSuccess()
        } catch {
            onError(error.localizedDescription)
        }
    }
}
